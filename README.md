# AgroBill Admin Control Center

AgroBill platformasini boshqarish paneli — Flutter Web.
Texnik topshiriq: [`../../agrobill/docs/ADMIN_TTZ.md`](../../agrobill/docs/ADMIN_TTZ.md) (TTZ v3.0).

**Sayt:** https://farkhodcoder.github.io/AgroBillAdmin/
`main` ga har push avtomatik joylashtiriladi —
[`deploy.yml`](.github/workflows/deploy.yml).

> **Kirish faqat parol bilan.** 2FA loyiha egasining qarori bilan olib
> tashlangan (`0019`). Panel ochiq internetda turgani uchun super admin
> paroli — platformaning butun ma'lumotiga yagona to'siq. Batafsil:
> [Xavfsizlik — asosiy qoida](#xavfsizlik--asosiy-qoida).

## Joriy holat

| Bosqich | Holat |
|---|---|
| 0 — skelet, umumiy kod | ✅ |
| 1 — migratsiyalar `0008`–`0019` | ✅ jonli bazaga qo'llangan |
| 2 — Auth + AppShell + PermissionGuard | ✅ |
| 3 — Dashboard KPI · Foydalanuvchilar · Xo'jaliklar | ✅ |
| 4 — Bozor moderatsiyasi · Buyurtmalar | ✅ |
| 5 — AI monitoringi · Kasallik bazasi · Audit | ✅ |
| 6 — Xodimlar · Sozlamalar · Kontent | ✅ |
| 7 — Ob-havo · Tahlil · Kampaniyalar · Edge Functions | ✅ deploy qilingan |
| Qolgani — Support | ⬜ |

**14 modul ishlaydi.** Yagona qolgani — **Support** (§6.12): jadvallar
bazada tayyor (`support_tickets`, 0012), lekin mobil ilovada «Yordam»
ekrani yo'q, ya'ni ticket yaratadigan hech kim yo'q. Admin tomonini avval
qurish bo'sh ro'yxat bilan tugardi.

**Edge Functions (TTZ §5.9) — beshtasi ham deploy qilingan.** Har biri
ruxsatni foydalanuvchi tokeni bilan tekshiradi va yetmasa
`PERMISSION_DENIED` qaytaradi:
[`../../agrobill/supabase/functions/README.md`](../../agrobill/supabase/functions/README.md).

**Dashboard** — `admin_dashboard_kpi()` (bugungi sonlar) + `admin_metrics_range()`
(7/30/90 kunlik grafiklar, `admin_daily_metrics` matview ustidan).

**Foydalanuvchilar** — qidiruv (ism/email/ID), 4 filtr, sahifalash, tafsilot
paneli, bloklash/blokdan chiqarish/xodim roli. Har bir amal RPC orqali:
sabab majburiy, audit bir tranzaksiyada.

**Xo'jaliklar** — qidiruv, viloyat/sug'orish filtri, tafsilotda dalalar,
ekinlar va salomatlik holati.

**Bozor moderatsiyasi** — navbat (`pending`, eskisidan boshlab), rasmlar
signed URL bilan, moderatsiya tarixi. Qarorlar: tasdiqlash · o'zgartirish
so'rash · rad etish · to'xtatib turish · o'chirish. Har biri
`admin_moderate_listing()` orqali — holat, tarix, sotuvchiga bildirishnoma
va audit **bitta tranzaksiyada**.

**Buyurtmalar** — holat filtri, «muddati o'tganlar» tugmasi (nizolar shu
yerdan boshlanadi), tafsilotda tomonlar, holat tarixi va baholar. Admin
faqat nizoli holatda bekor qila oladi.

> **To'lov holati yo'q.** `orders` da to'lovga oid ustun umuman yo'q va
> to'lov tizimi ulanmagan — TTZ §6.5 buni ataylab qamrovdan chiqargan.

**AI monitoringi** — ikkita ko'rinish: kunlik foydalanish (kim qancha
so'ramoqda) va skanlar (nima aniqlandi, qaysi model, qancha vaqtda). Tepada
model taqsimoti: zanjirda kvota tugaganda ilova keyingi modelga tushadi,
shuning uchun taqsimotning o'zgarishi kvota muammosining birinchi belgisi.

> **Token va xarajat hisobi yo'q.** `ai_messages` da tegishli ustunlar
> mavjud emas; ularni qo'shish mobil ilovada ham o'zgarish talab qiladi
> (TTZ §6.6, P1). Hozircha `model_version` va `latency_ms` kuzatiladi.

**Kasallik bazasi** — `disease_reference` ro'yxati, nashr holati
(`draft/review/published/archived`) va tarjima to'liqligi belgisi.
Holat `admin_publish_disease()` orqali o'zgaradi.

**Audit** — `scope='admin'` yozuvlari, amal va obyekt turi bo'yicha filtr.
Filtr ro'yxati **jurnalning o'zidan** olinadi, qat'iy ro'yxat emas: yangi RPC
qo'shilganda filtr eskirib qolmasin. Tafsilotda `old_value`/`new_value`
farqi ko'rsatiladi. Faqat o'qish — yozuv 0010 dagi triggerlar bilan
o'zgarmas.

**Xodimlar** — ro'yxat, rol berish/olib tashlash, kirish jurnali va
**rol × ruxsat matritsasi**. Matritsa bazadan o'qiladi, kodda qat'iy
yozilmagan: `admin_role_permissions` qo'lda o'zgartirilsa admin shuni
ko'rishi kerak, hujjatga qarab noto'g'ri xulosa chiqarmasin.

**Sozlamalar** — `app_settings` tahriri, sabab majburiy, audit kafolatlangan.

> **Mobil ilovaga ta'siri yo'q.** Ilova bu jadvalni hozircha **o'qimaydi** —
> qiymatlar `supabase_config.dart` da compile-time const (TTZ §6.15, P1).
> Ekranda bu ochiq aytilgan, aks holda sozlama «ishlayotgandek» ko'rinardi.

**Kontent** — ro'yxat, tur/holat filtri, tarjima to'liqligi, nashr/arxiv.
To'liq muharrir (uch tilda tahrirlash, rasm yuklash) — alohida ish.

**Ob-havo** — viloyat darajasidagi ogohlantirishlar. Xo'jalikka bog'langan
ogohlantirishlarni mobil ilovaning o'zi qo'yadi; admin ularga tegmaydi va
o'chirish tugmasi ular uchun ko'rsatilmaydi.

**Tahlil** — 30/90/365 kunlik metrikalar jadvali va CSV eksport
(`admin-export` orqali, natija buferga nusxalanadi).

**Kampaniyalar** — auditoriya tanlash, yuborishdan oldin **necha kishiga
ketishi** ko'rsatiladi, keyin `admin-send-campaign`.

> **Push yuborilmaydi.** Mobil ilovada FCM ulanmagan (`firebase_messaging`
> bog'liqligi yo'q), shuning uchun `device_tokens` bo'sh. Kampaniya **ilova
> ichidagi** bildirishnoma sifatida yetadi — bu bugun ishlaydi. Ekranda bu
> ochiq aytilgan, aks holda admin «push yubordim» deb o'ylardi.

Kirish oqimi to'liq ishlaydi (TTZ §8):

```
/login        email + parol
/no-access    admin_users da yo'q yoki is_active emas
/dashboard    AppShell + Sidebar + TopBar
```

Yo'naltirish mantig'i bitta joyda — [lib/app/router.dart](lib/app/router.dart)
dagi `redirect`. Bosqichni `AdminAuthRepository.resolveStage()` hal qiladi.

## Kunduzgi / tungi rejim

Tugma ikki joyda: kirish ekranida va panel yuqori qatorida. Halqa —
**tizim → yorug' → qorong'i → tizim**. «Tizim» halqada qoldirilgan, chunki
brauzer temasi kun davomida avtomatik o'zgaradigan sozlamada shu variant kerak.

Tanlov `localStorage` da saqlanadi
([lib/core/theme/theme_controller.dart](lib/core/theme/theme_controller.dart)),
`admin_users` da EMAS. Ikkita sabab:

* Tema — **qurilma** sozlamasi, hisob sozlamasi emas. Bir admin ofis
  kompyuterida yorug', uy noutbukida qorong'i rejimni xohlashi tabiiy.
  Til esa aksincha — u `admin_users.language_code` da, chunki odamning tili
  qurilmadan qurilmaga o'zgarmaydi.
* Bazaga yangi ustun qo'shish shart emas — mavjud sxemaga tegilmaydi.

`shared_preferences` **ishlatilmadi**: u asinxron ochiladi, ya'ni birinchi
kadr sukut bo'yicha temada chizilib, saqlangani keyin qo'llanardi —
foydalanuvchi qorong'i rejim tanlagan bo'lsa ham sahifa oq «chaqnab» ochilardi.
`localStorage` sinxron.

Xuddi shu sabab bilan [web/index.html](web/index.html) da bo'yashdan oldin
ishlaydigan kichik skript bor: u ayni kalitni o'qib `<html>` ga
`data-theme` qo'yadi, shunda **yuklanish ekrani** ham to'g'ri temada chiqadi.
Skriptdagi kalit `theme_controller.dart` dagi `_storageKey` bilan bir xil
bo'lishi shart.

## Ishga tushirish

```powershell
flutter pub get
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://qcpbholuttgmfojmpoct.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Kalitlar berilmasa panel baribir ochiladi (`AdminConfig.isConfigured` false
bo'ladi) — dizayn tizimini kalitsiz ham ko'rish mumkin.

`service_role` kaliti **hech qachon** bu loyihaga qo'yilmaydi. Uni talab
qiladigan amallar Edge Function ichida bajariladi (TTZ §5.9).

## Tekshiruvlar

```powershell
dart format --set-exit-if-changed --output=none lib test
flutter analyze                    # 0 muammo
flutter test                       # tarjima + ruxsat parity
flutter build web --release
powershell -File tool\check_web_secrets.ps1
```

`check_web_secrets.ps1` — bundle ichida `service_role` kaliti, JWT yoki
baza paroli qolmaganini tekshiradi. Ayni tekshiruv CI da ham takrorlanadi,
ya'ni maxfiy kalit tushib qolgan build **deploy bo'lmaydi**.

#### RBAC parity — nega ikki qavat

[test/fixtures/rbac_seed.json](test/fixtures/rbac_seed.json) — `0016_seed_rbac.sql`
dagi 24 ruxsat va 6 rol kodining nusxasi. Test uni ikki tomonga solishtiradi:

| Solishtirish | Qachon ishlaydi |
|---|---|
| `permission.dart` == fixture | **har doim**, CI da ham |
| fixture == `0016_seed_rbac.sql` | SQL mavjud bo'lsa (mahalliy) |

Avval test to'g'ridan-to'g'ri SQL ga qarardi. Migratsiyalar mobil
repozitoriyda turgani va CI faqat admin repozitoriysini checkout qilgani
uchun fayl u yerda umuman yo'q edi — test o'zini **jimgina o'tkazib
yuborardi**. Ya'ni "frontend kodi baza bilan mos" degan kafolat aynan kerak
bo'lgan joyda, deploy oldidan, ishlamasdi. Buni CI jurnalidagi `(skipped)`
belgisi ko'rsatdi.

Fixture o'zgarganda uni SQL dan qayta yarating — ikkinchi test eskirganini
darhol aytadi.

### Xavfsizlik testi — jonli bazaga qarshi

`admin_has()`, RLS siyosatlari va funksiya huquqlari **birgalikda** ishlaydi —
uchtasining birortasini alohida o'qib tizim xavfsizligini tasdiqlab bo'lmaydi.
Shuning uchun test haqiqiy hisob bilan jonli bazaga so'rov yuboradi.

```powershell
powershell -File ..\..\agrobill\tool\apply_migrations.ps1 `
  -TestAuthEmail "admin@..." -TestAuthPassword "..."
```

**34 ta so'rov**, uch guruhda:

1. **8 ta huquq tekshiruvi** — admin huquqlari ochilganini VA ochilmasligi
   kerak bo'lganlar yopiqligini tasdiqlaydi.
2. **21 ta PostgREST select satri** — repozitoriylardagi embed sintaksisi.
3. **5 ta Edge Function** — deploy qilinganini va ruxsat qatlami
   ishlayotganini tasdiqlaydi.

#### Birinchi guruh nimani ushlaydi

2FA olib tashlangandan keyin (`0019`) parol bilan kirgan admin darhol to'liq
huquqqa ega bo'ladi. Lekin **hamma narsa ochilib ketmasligi** kerak — quyidagi
to'rttasi baribir yopiq qolishi shart va test ayni shuni tekshiradi:

| Tekshiruv | Nega yopiq qolishi shart | Qaysi migratsiya |
|---|---|---|
| `admin_audit` ni to'g'ridan-to'g'ri chaqirish | aks holda soxta audit yozuvi qo'shish mumkin, audit esa o'zgarmas | `0018` |
| `admin_daily_metrics` matview | RLS ni butunlay chetlab o'tadi | `0015` |
| `admin_users.role_code` ni UPDATE qilish | o'ziga o'zi imtiyoz berish | `0008` (ustun huquqi) |
| `admin_set_role` ni o'ziga qo'llash | ayni shu, RPC orqali | `0010` |

#### Ikkinchi guruh nimani ushlaydi

| Xato | Belgi | Misol |
|---|---|---|
| Bog'lanish topilmadi | `PGRST200` | ustun nomi yoki jadval xato |
| Bir nechta yo'l bor | `PGRST201` / `HTTP 300` | `admin_users` da `id` va `created_by` — ikkalasi ham `profiles` ga |

Ikkinchisi 6-bosqichda haqiqatan chiqdi: `admin_users` select satri
`HTTP 300 Multiple Choices` bergan. Yechim — FK nomini aniq ko'rsatish:
`profiles!admin_users_id_fkey(...)`. Buni ekran ochilmasdan topish faqat
shu test tufayli mumkin bo'ldi.

#### Uchinchi guruh: shlyuzni funksiyadan ajratish

Edge Function tekshiruvi javob **tanasini** o'qiydi, faqat holat kodini emas.
`HTTP 404` ikki xil narsani bildirishi mumkin:

* `{"error":"NOT_FOUND"}` — **bizning** funksiyamiz ishladi, ruxsatdan o'tdi
  va berilgan UUID ni topmadi. Kutilgan natija.
* `{"code":"NOT_FOUND","message":"Requested function was not found"}` —
  funksiya umuman deploy qilinmagan. Himoyamiz ishga tushmagan.

Test ularni `fn:` va `gateway:` deb belgilab ajratadi va faqat birinchisini
qabul qiladi. Bu farq amalda kerak bo'ldi: bir bosqichda beshtasi ham shlyuz
404 ini qaytargan — ajratishsiz test «o'tdi» derdi.

2026-08-21 dagi natija — 34/34 o'tdi:

```
OK   admin_has(users.read) -> true            true
OK   admin_dashboard_kpi -> ma'lumot          {"scans_today": 3, "total_farms": 4, ...
OK   admin_permissions -> 24 kod              [{"code":"users.read"}, ...
OK   admin_block_user -> REASON_REQUIRED      HTTP 400 REASON_REQUIRED
OK   admin_audit -> huquq yoq (0018)          HTTP 403 permission denied for function
OK   admin_daily_metrics -> huquq yoq (0015)  HTTP 403
OK   role_code o'zgartirish -> rad etiladi    HTTP 403
OK   admin_set_role(o'zi) -> taqiqlangan      HTTP 403 CANNOT_CHANGE_OWN_ROLE

OK   profiles + regions/districts/subs        [{"id":"11111111-...
OK   farms + owner/region/fields(count)       [{"id":"22222222-...
OK   listings + seller/region/crop/images     [{"id":"92ef688e-...
OK   orders + buyer/seller FK korsatgichi     [{"id":"be8bb51f-...
OK   admin_users + profiles                   [{"id":"6f35140e-...
     ... (jami 21 ta)

OK   admin-export -> CSV                      day,total_users,new_users,...
OK   admin-system-health -> tekshiruvlar      {"all_ok":true,...
OK   admin-delete-user -> NOT_FOUND           HTTP 404 fn:NOT_FOUND
OK   admin-send-campaign -> NOT_FOUND         HTTP 404 fn:NOT_FOUND
OK   admin-force-logout -> NOT_FOUND          HTTP 404 fn:NOT_FOUND
```

Ikkinchi guruh endi hamma joyda qator qaytaradi — bu **kutilgan**: admin
huquqi ochiq. 2FA davrida ularning ko'pi `[]` edi.

**Yangi repozitoriy select satri yozilganda shu ro'yxatga qo'shing** —
`apply_migrations.ps1` ichidagi `PostgREST select satrlari` bo'limi.

## Tuzilish

```
lib/
├── app/            app · router (redirect) · routes · di
├── core/
│   ├── errors/     admin_error_codes.dart   backend kodi -> tarjima kaliti
│   ├── rbac/       permission.dart          24 ruxsat, 6 rol
│   │               permission_guard.dart    PermissionGuard, context.can()
│   ├── supabase/   admin_config.dart · db.dart (Db, guard, mapSupabaseError)
│   ├── theme/      mobil ilovadan ko'chirilgan brend palitrasi va tipografika
│   └── utils/      result.dart (Result<T> / AppFailure) · formatters.dart
├── data/
│   ├── models/        admin_metrics · admin_user · admin_farm ·
│   │                  admin_listing · admin_order · admin_ai
│   └── repositories/  auth · dashboard · user · farm · listing · order ·
│                      ai · audit
├── features/
│   ├── auth/       cubit · login · mfa_enroll · mfa_verify · code_input
│   ├── dashboard/  KPI kartalar + fl_chart grafiklari
│   ├── users/      ro'yxat · filtr · tafsilot paneli · amallar
│   ├── farms/      ro'yxat · filtr · dalalar paneli
│   ├── marketplace/ moderatsiya navbati · rasmlar · qarorlar · tarix
│   ├── orders/     ro'yxat · muddati o'tganlar · holat tarixi · baholar
│   ├── ai/         foydalanish · skanlar · model taqsimoti
│   ├── disease/    ma'lumotnoma · nashr holati
│   ├── audit/      jurnal · filtr · o'zgarishlar farqi
│   └── shell/      app_shell · sidebar · top_bar · nav_items · splash
└── ui/             admin_button · admin_field · admin_feedback ·
                    admin_table (jadval + sahifalash) ·
                    admin_bits (badge · qidiruv · select · sabab dialogi) ·
                    auth_scaffold
```

`AdminTable` Flutter'ning `DataTable` idan foydalanmaydi: u har qatorni
o'lchaydi va yuzlab qatorda sekinlashadi. O'rniga `ListView.builder` —
virtualizatsiya tekin keladi.

Mobil ilovadagi `lib/ui/` **ko'chirilmadi**: `AgButton` sensorli ekran uchun
(52 px balandlik, hover yo'q). Admin — zich desktop interfeys, shuning uchun
komponentlar qaytadan yozilgan, lekin bir xil rang va tipografika tokenlari
ustida.

### Mobil ilova bilan aloqa

Bu **mustaqil loyiha** — `agrobill_core` umumiy paketi yo'q. Quyidagi fayllar
mobil ilovadan **nusxalangan**, ya'ni ular o'sha yerda o'zgarsa bu yerga
qo'lda ko'chiriladi:

| Fayl | Manba |
|---|---|
| `core/utils/result.dart` | `agrobill/lib/core/utils/result.dart` |
| `core/theme/app_colors.dart` | `agrobill/lib/core/theme/app_colors.dart` |
| `core/theme/app_typography.dart` | `agrobill/lib/core/theme/app_typography.dart` |
| `core/theme/app_dimens.dart` | `agrobill/lib/core/theme/app_dimens.dart` |
| `core/theme/app_theme.dart` | `agrobill/lib/core/theme/app_theme.dart` |
| `assets/fonts/*` | `agrobill/assets/fonts/` |

`core/supabase/db.dart` — `agrobill/lib/core/supabase/supabase_client.dart`
ning admin uchun moslashtirilgan nusxasi (xato xaritalashga `AdminErrorCode`
qatlami qo'shilgan, Google/AI qismlari olib tashlangan).

`pubspec.yaml` dagi versiyalar mobil ilova bilan **aynan bir xil** — ajralib
ketsa nusxalangan fayllar bir kunda mos kelmay qoladi.

## Migratsiyalar

Baza migratsiyalari bu loyihada **emas**, mobil repozitoriyda:
`../../agrobill/supabase/migrations/`. Ikkala ilova bitta bazaga tayanadi,
shuning uchun migratsiya papkasi ham bitta.

Admin uchun qo'shilganlari — `0008`–`0019`. Batafsil:
[`../../agrobill/supabase/migrations/README_ADMIN.md`](../../agrobill/supabase/migrations/README_ADMIN.md).

## Xavfsizlik — asosiy qoida

Frontend'dagi `AdminPermissions.has(...)` faqat **UX** uchun: menyu bandini
yashiradi, tugmani o'chiradi.

Haqiqiy himoya bazada: `admin_has()` RLS siyosatlari va RPC lar ichida.
Panelni chetlab o'tib to'g'ridan-to'g'ri PostgREST ga so'rov yuborish foyda
bermaydi — javobni frontend emas, baza qaytaradi.

> **Diqqat — 2FA olib tashlangan (`0019`).** Loyiha egasining qarori bilan
> `admin_has()` dan `aal2` sharti chiqarildi. Endi panelni **faqat parol**
> himoya qiladi. Panel ochiq internetda turgani uchun bu shuni anglatadiki,
> super admin parolini bilgan har kim platformaning butun ma'lumotiga
> kiradi. Amaliy talab: uzun va noyob parol, va u hech qayerda takrorlanmasin.
>
> 2FA ni qaytarish uchun `0019_disable_mfa_requirement.sql` ichidagi `down`
> bloki tayyor turibdi — bitta migratsiya bilan tiklanadi.
