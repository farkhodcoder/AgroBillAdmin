const zlib = require('zlib');

// --- Minimal PNG kodlovchi (RGBA, 8 bit) -------------------------------
// Tashqi kutubxona yo'q: `sharp`/ImageMagick o'rnatilmagan, `zlib` esa
// Node bilan birga keladi va PNG uchun kerak bo'lgan yagona narsa shu.
const CRC = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return (buf) => {
    let c = -1;
    for (const b of buf) c = t[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ -1) >>> 0;
  };
})();

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(CRC(body));
  return Buffer.concat([len, body, crc]);
}

function encodePng(w, h, rgba) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;   // bit depth
  ihdr[9] = 6;   // RGBA
  // Har qatordan oldin filtr bayti (0 = None) turishi SHART.
  const raw = Buffer.alloc(h * (w * 4 + 1));
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  }
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// --- Shakl ------------------------------------------------------------
const BG   = [0x17, 0x3b, 0x22]; // green900 - brend chuqur yashili
const LEAF = [0x7c, 0xb3, 0x42]; // green400 - yangi o'sim yashili

const hypot = Math.hypot;

// Ikki doira kesishmasi = klassik barg shakli. Markazlar (-a,a) va (a,-a)
// bo'lgani uchun bargning uzun o'qi pastdan-chapdan yuqoriga-o'ngga ketadi.
function leaf(x, y) {
  // a kichrayganda doiralar ko'proq kesishadi -> barg yo'g'onlashadi.
  // a=0.48 da uzunlik/eni nisbati ~2.3 - tabiiy barg proporsiyasi.
  const a = 0.48, r = 1.0, s = 1.3; // s: bargni ramkaga moslashtiradi
  const px = x / s, py = y / s;
  return hypot(px + a, py + a) <= r && hypot(px - a, py - a) <= r;
}

// Barg o'rtasidagi tomir: uzun o'q (y = x) chizig'igacha bo'lgan masofa.
function midrib(x, y) {
  const d = Math.abs(y + x) / Math.SQRT2;
  return d < 0.05;
}

function roundedSquare(x, y, radius) {
  const ax = Math.abs(x), ay = Math.abs(y);
  const k = 1 - radius;
  if (ax <= k || ay <= k) return ax <= 1 && ay <= 1;
  return hypot(ax - k, ay - k) <= radius;
}

/**
 * @param size    piksel
 * @param maskable maskali variant: burchak yumaloqlanmaydi (tizim o'zi
 *                 qirqadi) va barg xavfsiz zonaga sig'adi
 */
function render(size, maskable) {
  const buf = Buffer.alloc(size * size * 4);
  const SS = 4; // har piksel uchun 4x4 namuna - qirralarni silliqlaydi
  const leafScale = maskable ? 0.62 : 0.80;
  const corner = maskable ? 0 : 0.22;

  for (let py = 0; py < size; py++) {
    for (let px = 0; px < size; px++) {
      let inBg = 0, inLeaf = 0, inRib = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const x = ((px + (sx + 0.5) / SS) / size) * 2 - 1;
          const y = ((py + (sy + 0.5) / SS) / size) * 2 - 1;
          if (maskable ? true : roundedSquare(x, y, corner)) inBg++;
          const lx = x / leafScale, ly = y / leafScale;
          if (leaf(lx, ly)) {
            inLeaf++;
            if (midrib(lx, ly)) inRib++;
          }
        }
      }
      const n = SS * SS;
      const i = (py * size + px) * 4;
      const bgA = inBg / n;
      if (bgA === 0) continue;

      const leafA = inLeaf / n;
      const ribA = inRib / n;
      // Barg fonning ustiga, tomir esa bargning ustiga aralashtiriladi.
      let col = BG.slice();
      col = col.map((c, k) => c * (1 - leafA) + LEAF[k] * leafA);
      col = col.map((c, k) => c * (1 - ribA * 0.55) + BG[k] * ribA * 0.55);
      buf[i] = Math.round(col[0]);
      buf[i + 1] = Math.round(col[1]);
      buf[i + 2] = Math.round(col[2]);
      buf[i + 3] = Math.round(bgA * 255);
    }
  }
  return encodePng(size, size, buf);
}

module.exports = { render };

if (require.main === module && process.argv[2] === 'preview') {
  // Fayl yozishdan oldin shaklni ko'rish uchun.
  const N = 34;
  for (let y = 0; y < N; y++) {
    let row = '';
    for (let x = 0; x < N; x++) {
      const nx = ((x + 0.5) / N) * 2 - 1, ny = ((y + 0.5) / N) * 2 - 1;
      const s = 0.80;
      row += !roundedSquare(nx, ny, 0.22) ? ' '
           : midrib(nx / s, ny / s) && leaf(nx / s, ny / s) ? '.'
           : leaf(nx / s, ny / s) ? '#' : ':';
    }
    console.log(row);
  }
}

// --- Fayllarni yozish -------------------------------------------------
if (require.main === module && process.argv[2] === 'write') {
  const fs = require('fs');
  const out = [
    ['web/favicon.png', 32, false],
    ['web/icons/Icon-192.png', 192, false],
    ['web/icons/Icon-512.png', 512, false],
    ['web/icons/Icon-maskable-192.png', 192, true],
    ['web/icons/Icon-maskable-512.png', 512, true],
  ];
  for (const [path, size, maskable] of out) {
    const png = render(size, maskable);
    fs.writeFileSync(path, png);
    console.log(`${path.padEnd(34)} ${size}px  ${(png.length / 1024).toFixed(1)} KB`);
  }
}
