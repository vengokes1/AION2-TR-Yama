<#
 AION 2 Türkçe Yama - kurulum / geri alma / durum
 Yöntem: UE5 L10N geri-düşüş (fallback) mekanizması.
   1) Aion2\Content\L10N\Text\en-US\L10NString.dat  -> Türkçe veri tablosu (gevşek dosya)
   2) Paks\L10N\Text\en-US\<chunk>.pak              -> stub pak ile değiştirilir (.sig/.ucas/.utoc silinir)
 Oyun içi dil İngilizce kalmalıdır.
 Kullanım: -Install | -Restore | -Status   [-GamePath "D:\...\AION 2"] [-DryRun]
#>
param(
  [switch]$Install, [switch]$Restore, [switch]$Status, [switch]$DryRun,
  [string]$GamePath
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ===================== AYARLAR (oyun açılınca doğrula) =====================
$AppIds     = @('3393110','4972320')            # Steam: normal / playtest
$ChunkName  = 'pakchunk502000-Windows_0_P'      # stub'ın değiştireceği pak (Çince yamadan alındı; sürüme göre doğrula)
$Culture    = 'en-US'
$ProcNames  = @('Aion2','Aion2-Win64-Shipping') # çalışıyorsa kurulumu durdur
# ===========================================================================

$ToolDir   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$Payload   = Join-Path $ToolDir 'payload'
$SrcDat    = Join-Path $Payload 'L10NString.dat'
$SrcPak    = Join-Path $Payload "$ChunkName.pak"
$LogFile   = Join-Path $ToolDir 'yama.log'

function Log($m,$c='Gray'){ Write-Host $m -ForegroundColor $c; Add-Content -Path $LogFile -Value ("{0:s} {1}" -f (Get-Date),$m) -Encoding UTF8 }
function Hash($p){
  if(Test-Path $p){
    $stream = [System.IO.File]::OpenRead($p)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = [System.BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-'
    $stream.Close()
    $hash
  } else { $null }
}

function Get-SteamLibraries {
  $libs = @()
  $steam = $null
  foreach($k in 'HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'){
    try{ $v=Get-ItemProperty $k -ErrorAction Stop; $s=if($v.SteamPath){$v.SteamPath}elseif($v.InstallPath){$v.InstallPath}; if($s){$steam=$s;break} }catch{}
  }
  if($steam){
    $libs += (Join-Path $steam 'steamapps')
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if(Test-Path $vdf){
      foreach($m in [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"')){
        $libs += (Join-Path ($m.Groups[1].Value -replace '\\\\','\') 'steamapps')
      }
    }
  }
  foreach($d in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root })){
    foreach($c in 'SteamLibrary\steamapps','Steam\steamapps','Program Files (x86)\Steam\steamapps'){
      $libs += (Join-Path $d.Root $c)
    }
  }
  $libs | Where-Object { Test-Path $_ } | ForEach-Object { (Resolve-Path $_).Path } | Select-Object -Unique
}

function Find-GameRoots {
  $found = @()
  foreach($lib in Get-SteamLibraries){
    foreach($id in $AppIds){
      $acf = Join-Path $lib "appmanifest_$id.acf"
      if(Test-Path $acf){
        if((Get-Content $acf -Raw) -match '"installdir"\s+"([^"]+)"'){
          $root = Join-Path (Join-Path $lib 'common') $Matches[1]
          if(Test-Path (Join-Path $root "Aion2\Content\Paks")){ $found += $root }
        }
      }
    }
    $common = Join-Path $lib 'common'
    if(Test-Path $common){
      Get-ChildItem $common -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if(Test-Path (Join-Path $_.FullName "Aion2\Content\Paks")){ $found += $_.FullName }
      }
    }
  }
  $dict = @{}
  foreach($f in $found){
    if(Test-Path $f){
      $real = (Resolve-Path $f).Path
      $dict[$real.ToLower()] = $real
    }
  }
  $dict.Values
}

function Resolve-Target {
  if($GamePath){
    if(-not (Test-Path (Join-Path $GamePath "Aion2\Content\Paks"))){ throw "Geçersiz oyun klasörü (Aion2\Content\Paks yok): $GamePath" }
    return @($GamePath)
  }
  $r = @(Find-GameRoots)
  if($r.Count -eq 0){ throw "Oyun bulunamadı. -GamePath ile klasörü elle ver (içinde 'Aion2' klasörü olan yer)." }
  if($r.Count -gt 1){
    Write-Host "Birden fazla kurulum bulundu:" -ForegroundColor Cyan
    for($i=0;$i -lt $r.Count;$i++){ Write-Host "  [$($i+1)] $($r[$i])" }
    $s = Read-Host "Numara seç (hepsi için A)"
    if($s -match '^[Aa]$'){ return $r }
    return @($r[[int]$s-1])
  }
  return $r
}

function Test-GameRunning {
  $p = Get-Process -ErrorAction SilentlyContinue | Where-Object { $ProcNames -contains $_.ProcessName }
  if($p){ throw "Oyun çalışıyor ($($p[0].ProcessName)). Kapatıp tekrar dene." }
}

function Paths($root){
  $pakDir = Join-Path $root "Aion2\Content\Paks\L10N\Text\$Culture"
  [pscustomobject]@{
    Root=$root; PakDir=$pakDir
    Pak=(Join-Path $pakDir "$ChunkName.pak")
    LooseDir=(Join-Path $root "Aion2\Content\L10N\Text\$Culture")
    LooseDat=(Join-Path $root "Aion2\Content\L10N\Text\$Culture\L10NString.dat")
    Backup=(Join-Path $root 'Aion2_TR_Backup')
    State=(Join-Path $root 'Aion2_TR_Backup\state.json')
  }
}

function Do-Install($root){
  $p = Paths $root
  if(-not (Test-Path $SrcDat)){ throw "payload\L10NString.dat yok (henüz üretilmedi)." }
  if(-not (Test-Path $SrcPak)){ throw "payload\$ChunkName.pak (stub) yok." }
  if(-not (Test-Path $p.PakDir)){ throw "Pak klasörü yok: $($p.PakDir)" }

  $stubHash = Hash $SrcPak
  $curHash  = Hash $p.Pak
  $state = if(Test-Path $p.State){ Get-Content $p.State -Raw | ConvertFrom-Json } else { $null }

  # Yedek: sadece mevcut pak bizim stub DEĞİLSE (oyun güncellenmiş / ilk kurulum) yenile
  if($curHash -and $curHash -ne $stubHash){
    Log "Orijinal İngilizce dosyalar yedekleniyor -> $($p.Backup)" Cyan
    if(-not $DryRun){
      if(Test-Path $p.Backup){ Remove-Item "$($p.Backup)\*" -Recurse -Force }
      New-Item -ItemType Directory $p.Backup -Force | Out-Null
      Get-ChildItem $p.PakDir -Filter "$ChunkName.*" | Copy-Item -Destination $p.Backup -Force
      [pscustomobject]@{
        chunk=$ChunkName; origPakSha256=$curHash; stubSha256=$stubHash
        looseExistedBefore=(Test-Path $p.LooseDat); date=(Get-Date -Format s)
      } | ConvertTo-Json | Set-Content $p.State -Encoding UTF8
    }
  } elseif(-not $state){
    throw "Mevcut pak stub gibi görünüyor ama yedek/durum yok. Steam > Dosyaları doğrula yap, sonra tekrar çalıştır."
  } else { Log "Zaten kurulu; yedek korunuyor, dosyalar yenileniyor." Yellow }

  Log "Türkçe veri tablosu kopyalanıyor..." Cyan
  if(-not $DryRun){
    New-Item -ItemType Directory $p.LooseDir -Force | Out-Null
    Copy-Item $SrcDat $p.LooseDat -Force
    foreach($ext in 'sig','ucas','utoc'){ Remove-Item (Join-Path $p.PakDir "$ChunkName.$ext") -Force -ErrorAction SilentlyContinue }
    Copy-Item $SrcPak $p.Pak -Force
    if((Hash $p.LooseDat) -ne (Hash $SrcDat) -or (Hash $p.Pak) -ne $stubHash){ throw "Doğrulama başarısız (hash uyuşmuyor)." }
  }
  Log "Kuruldu: $root  (oyun içi dil İngilizce kalmalı)" Green
}

function Do-Restore($root){
  $p = Paths $root
  if(-not (Test-Path $p.State)){ Log "Yedek/durum yok: $root  -> Steam'de 'Dosyaların bütünlüğünü doğrula' kullan." Yellow; return }
  $state = Get-Content $p.State -Raw | ConvertFrom-Json
  Log "Geri alınıyor: $root" Cyan
  if(-not $DryRun){
    Get-ChildItem $p.Backup -Filter "$($state.chunk).*" | Copy-Item -Destination $p.PakDir -Force
    Remove-Item $p.LooseDat -Force -ErrorAction SilentlyContinue
    # sadece boşalan klasörleri temizle
    $d = $p.LooseDir
    while($d -and ($d -like "*\Content\L10N*") -and (Test-Path $d) -and -not (Get-ChildItem $d -Force)){ Remove-Item $d -Force; $d = Split-Path $d -Parent }
    if((Hash $p.Pak) -ne $state.origPakSha256){ Log "UYARI: pak hash'i yedekle eşleşmiyor; Steam'de dosyaları doğrula." Yellow }
  }
  Log "Orijinale dönüldü." Green
}

function Do-Status($root){
  $p = Paths $root
  $stub = Hash $SrcPak
  $cur  = Hash $p.Pak
  Write-Host "Klasör      : $root"
  Write-Host ("Türkçe .dat : " + $(if(Test-Path $p.LooseDat){'VAR'}else{'yok'}))
  Write-Host ("Pak durumu  : " + $(if(-not $cur){'pak yok'}elseif($stub -and $cur -eq $stub){'STUB (yama aktif)'}else{'orijinal'}))
  Write-Host ("Yedek       : " + $(if(Test-Path $p.State){'VAR'}else{'yok'}))
}

try{
  if(-not ($Install -or $Restore -or $Status)){ Write-Host "Kullanım: -Install | -Restore | -Status [-GamePath yol] [-DryRun]"; exit 0 }
  if($DryRun){ Log "[DRY-RUN] Hiçbir dosya değiştirilmeyecek." Yellow }
  $targets = Resolve-Target
  if($Install -or $Restore){ Test-GameRunning }
  foreach($t in $targets){
    if($Install){ Do-Install $t } elseif($Restore){ Do-Restore $t } else { Do-Status $t }
  }
  if($Install){ Log "Not: Steam güncellemesi/doğrulaması yamayı geri alabilir; Kur.bat'ı tekrar çalıştır." Gray }
} catch { Log "HATA: $($_.Exception.Message)" Red; exit 1 }
