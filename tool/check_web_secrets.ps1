# =============================================================================
# Web bundle ichida maxfiy kalit qolmaganini tekshiradi (TTZ §11.2).
#
# Ishlatish:
#   flutter build web --release
#   pwsh tool/check_web_secrets.ps1
#
# NEGA ODDIY `grep service_role` YETMAYDI:
# `supabase_flutter` ning o'zida kalit prefiksini tekshiruvchi kod bor —
# `startsWith("sb_secret_")`. Ya'ni matn bundle'da HAR DOIM uchraydi, lekin
# bu kalit emas, tekshiruv mantig'i. Oddiy qidiruv har build'da yolg'on
# ogohlantirish beradi va bir necha marta takrorlangach e'tibordan qoladi —
# aynan shunda haqiqiy kalit sezilmay o'tib ketadi.
#
# Shuning uchun bu yerda KALIT QIYMATI qidiriladi: prefiksdan keyin haqiqiy
# belgilar kelgan holat.
# =============================================================================

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'build\web'

if (-not (Test-Path $build)) {
    Write-Host "build/web topilmadi. Avval: flutter build web --release" -ForegroundColor Yellow
    exit 2
}

# Har biri: nom + haqiqiy kalitga mos naqsh.
$patterns = @(
    @{ Name = 'service_role kaliti (sb_secret_...)'; Pattern = 'sb_secret_[A-Za-z0-9_\-]{8,}' },
    # `"role":"service_role"` ning base64 ko'rinishi — JWT payload ichida
    # shunday chiqadi, chunki JWT o'rtasi base64url bilan kodlangan.
    @{ Name = 'service_role JWT'; Pattern = 'InNlcnZpY2Vfcm9sZSI' },
    # Supabase personal access token (`supabase login`).
    @{ Name = 'Supabase access token'; Pattern = 'sbp_[a-f0-9]{40}' },
    # Baza ulanish satri parol bilan.
    @{ Name = 'postgres ulanish satri'; Pattern = 'postgres(ql)?://[^:\s]+:[^@\s]+@' }
)

$found = @()

Get-ChildItem $build -Recurse -File -Include *.js, *.json, *.html, *.map | ForEach-Object {
    $file = $_
    $text = [IO.File]::ReadAllText($file.FullName)
    foreach ($p in $patterns) {
        $m = [regex]::Matches($text, $p.Pattern)
        if ($m.Count -gt 0) {
            $found += [pscustomobject]@{
                File  = $file.FullName.Replace($root, '').TrimStart('\')
                What  = $p.Name
                Count = $m.Count
                First = $m[0].Value.Substring(0, [Math]::Min(24, $m[0].Value.Length)) + '...'
            }
        }
    }
}

if ($found.Count -gt 0) {
    Write-Host "XAVF: bundle ichida maxfiy qiymat topildi" -ForegroundColor Red
    $found | Format-Table -AutoSize
    exit 1
}

Write-Host "toza - bundle ichida service_role, secret kalit yoki parol yo'q" -ForegroundColor Green
exit 0
