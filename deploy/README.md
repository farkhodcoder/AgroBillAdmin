# Deploy — statik host sozlamalari

`flutter build web --release` → `build/web/` papkasini istalgan statik hostga
qo'yish mumkin. Lekin **bitta sozlama majburiy**, aks holda panel yarim
ishlaydi.

## SPA fallback — majburiy

Ilova `usePathUrlStrategy()` ishlatadi ([lib/main.dart](../lib/main.dart)),
ya'ni marshrutlar `#` siz: `/dashboard`, `/users`, `/marketplace`.

Bunday yo'llar uchun serverda **hech qanday fayl yo'q** — ular faqat
brauzerdagi router uchun mavjud. Shuning uchun server topilmagan yo'lda
`index.html` qaytarishi kerak.

Sozlanmasa nima bo'ladi (tekshirilgan):

| So'rov | Fallbacksiz | Fallback bilan |
|---|---|---|
| `/` | 200 | 200 |
| `/main.dart.js` | 200 | 200 |
| `/assets/assets/translations/uz.json` | 200 | 200 |
| `/dashboard` | **404** | 200 |
| `/users` | **404** | 200 |

Xavflisi shundaki, **bosh sahifadan navigatsiya baribir ishlaydi** — muammo
faqat sahifani yangilaganda yoki havolani to'g'ridan-to'g'ri ochganda
chiqadi. Shuning uchun sinovda oson e'tibordan qoladi.

### GitHub Pages — joriy joylashtirish

Sayt shu yerda turadi va [`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml)
orqali **avtomatik** yangilanadi: `main` ga har push da tahlil → testlar →
build → deploy. Testlar yiqilsa sayt yangilanmaydi.

Bir martalik sozlash (repozitoriyda):
**Settings → Pages → Source: GitHub Actions**.

GitHub Pages ning ikkita o'ziga xosligi bor va ikkalasi ham ish oqimida
hal qilingan:

| Xususiyat | Nima bo'lardi | Yechim |
|---|---|---|
| Sayt ildizda emas, `/AgroBillAdmin/` da | barcha resurs manzillari ildizga ishora qilib, sahifa bo'sh ochilardi | `--base-href /AgroBillAdmin/` |
| Qayta yozish qoidalari yo'q | `/users/<id>` ni to'g'ridan-to'g'ri ochish yoki F5 → 404 | `index.html` dan `404.html` nusxasi |

`404.html` nusxasi build **dan keyin** olinadi — shundagina `$FLUTTER_BASE_HREF`
o'rniga haqiqiy yo'l yozilgan bo'ladi. Nusxa `web/` ichida statik fayl sifatida
saqlansa, unda o'rin egallovchi matn qolib ketardi va sayt buzilardi.

Bundan tashqari `.nojekyll` fayli qo'yiladi: Jekyll `_` bilan boshlanadigan
fayllarni o'tkazib yuboradi, Flutter chiqishida esa bunday fayllar bor.

#### Tuzoq: `build_type` `legacy` bo'lib qolsa

Pages sayti ikki xil rejimda ishlaydi va noto'g'risi **jimgina** buzadi:

| `build_type` | Nima bo'ladi |
|---|---|
| `workflow` | faqat bizning ish oqimimiz joylashtiradi — kerakli holat |
| `legacy` | GitHub `main` shoxchasidan Jekyll bilan sayt quradi |

`legacy` da har push ikkita joylashtirishni ishga tushiradi: bizniki va
`pages build and deployment` nomli yashirin Jekyll ishi. Ikkinchisi
`README.md` dan HTML yasab, bizning artefaktimiz **ustiga yozadi**. Natija —
sayt ochiladi (HTTP 200), lekin ilova o'rniga README ko'rinadi va
`flutter_bootstrap.js` 404 qaytaradi.

Bu 2026-08-21 da haqiqatan sodir bo'ldi. Sayt bir marta to'g'ri ochilib,
keyingi push dan keyin README ga aylandi — chunki ikkalasi navbatma-navbat
yozgan va oxirgisi g'olib chiqqan.

Tekshirish va tuzatish:

```bash
# holat
curl -s -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/<user>/<repo>/pages | grep build_type

# tuzatish
curl -X PUT -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/<user>/<repo>/pages \
  -d '{"build_type":"workflow"}'
```

Interfeysdan: **Settings -> Pages -> Source: GitHub Actions**.

> Diqqat: `POST /pages` bilan sayt yaratganda `{"build_type":"workflow"}`
> yuborilgan bo'lsa ham natija `legacy` bo'lib qolishi mumkin — yaratgandan
> keyin `GET` bilan tasdiqlang.

### Netlify / Cloudflare Pages

`web/_redirects` fayli allaqachon qo'shilgan va build paytida `build/web/`
ga ko'chiriladi. Qo'shimcha sozlash kerak emas.

### Vercel

Loyiha ildizida `vercel.json`:

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

### Firebase Hosting

`firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

### Nginx

```nginx
location / {
  root /var/www/agrobill-admin;
  try_files $uri $uri/ /index.html;
}

# `main.dart.js` va assets nomida hash yo'q, shuning uchun uzoq kesh
# XAVFLI: yangi versiya chiqqach foydalanuvchida eskisi qolib ketardi.
location = /index.html {
  add_header Cache-Control "no-cache";
}
```

### Apache

`build/web/.htaccess`:

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

## Kalitlar

Kalitlar **build vaqtida** bundle ichiga kiradi, shuning uchun ular deploy
buyrug'ida beriladi:

```powershell
flutter build web --release `
  --dart-define=SUPABASE_URL=https://qcpbholuttgmfojmpoct.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

`publishable` kalit dizayni bo'yicha ochiq — ma'lumotni RLS himoya qiladi,
kalit emas. `service_role` kaliti **hech qachon** berilmaydi; buni
`tool/check_web_secrets.ps1` har build'dan keyin tekshiradi.

## Ildizdan boshqa yo'lda

Panel `https://example.com/admin/` da tursa:

```powershell
flutter build web --release --base-href /admin/
```

## Supabase CORS

Edge Function'lar `Access-Control-Allow-Origin: *` qaytaradi
(`supabase/functions/_shared/admin.ts`). Ishlab chiqarishda uni aniq domenga
toraytirish tavsiya etiladi — hozircha `*` chunki panel domeni hali
belgilanmagan.

Supabase Auth uchun **Redirect URLs** ro'yxatiga panel domeni qo'shilishi
kerak (Dashboard → Authentication → URL Configuration), aks holda parolni
tiklash havolalari ishlamaydi.

## Kesh

Flutter `main.dart.js` nomiga hash qo'ymaydi. Shuning uchun:

* `index.html` va `flutter_bootstrap.js` — **kesh yo'q** (`no-cache`)
* `main.dart.js`, `assets/**`, `canvaskit/**` — qisqa kesh yoki
  `must-revalidate`

Aks holda yangi versiya chiqqach foydalanuvchida eskisi qolib ketadi va
"nega o'zgarish ko'rinmayapti" degan savol tug'iladi.
