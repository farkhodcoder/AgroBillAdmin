// Yuklanish ekrani uchun ikkita kichik skript.
//
// NEGA ALOHIDA FAYL: `index.html` dagi CSP `script-src` da `'unsafe-inline'`
// YO'Q — sahifaga qandaydir yo'l bilan tushib qolgan begona `<script>`
// ishlamasin. Ichki (inline) skriptlar ham shu qoidaga tushadi, shuning uchun
// ular shu faylga ko'chirilgan. `<head>` da `async`siz ulanadi, ya'ni
// bo'yashdan OLDIN bajariladi.

// 1. Tema. ThemeController saqlagan tanlovni o'qib <html> ga qo'yadi. Usiz
//    Flutter yuklanguncha yuklanish ekrani OS temasida turib, keyin tanlangan
//    temaga sakrardi.
//
//    Kalit lib/core/theme/theme_storage_web.dart dagi `_key` bilan bir xil
//    bo'lishi SHART — ikkalasi ayni bitta qiymatni o'qiydi.
(function () {
  try {
    var t = window.localStorage.getItem('agrobill.admin.theme');
    if (t === 'light' || t === 'dark') {
      document.documentElement.setAttribute('data-theme', t);
    }
  } catch (e) {
    // Saqlash o'chirilgan brauzer — OS temasida qolamiz.
  }
})();

// 2. Flutter birinchi kadrni chizganda yuklanish ekrani olib tashlanadi.
//    `setTimeout` — o'tish animatsiyasi tugashini kutadi, aks holda element
//    birdan yo'qolib, sakrash sezilardi.
window.addEventListener('flutter-first-frame', function () {
  var boot = document.getElementById('boot');
  if (!boot) return;
  boot.classList.add('done');
  setTimeout(function () { boot.remove(); }, 300);
});
