# AltDetectorX

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

## Güvenli mi? Kendin denetlet

Bu script'i çalıştırmadan önce güvenli olduğundan emin olmak istiyorsan, `AltDetectorX.ps1`'in içeriğini herhangi bir yapay zekaya (ChatGPT, Claude, Gemini vb.) verip aşağıdaki promptu kullanabilirsin:

```text
Sana bir PowerShell script'i vereceğim. Bunu satır satır incele ve şunları söyle:
1. Ne yapıyor? Kısaca özetle.
2. İnternete veri gönderiyor mu? Herhangi bir dosyayı internete yüklüyor,
   bir sunucuya bilgi yolluyor ya da uzaktan komut indirip çalıştırıyor mu?
3. Dosyaları siliyor, değiştiriyor ya da sistemde kalıcı değişiklik
   (kayıt defteri, görev zamanlayıcı, başlangıç, güvenlik ayarı) yapıyor mu?
4. Şifre, token, çerez, cüzdan gibi hassas verileri okuyup dışarı çıkarıyor mu?
5. Gizlenmiş/şifrelenmiş (obfuscated) ya da amacı belirsiz, şüpheli kod var mı?
6. Sonuç: Bu script'i çalıştırmak senin değerlendirmene göre güvenli mi?

Script'i olduğu gibi, hiçbir kısmını atlamadan değerlendir ve sade bir dille,
teknik olmayan birinin anlayacağı şekilde açıkla.
```

> İpucu: Yukarıdaki tek satırlık komut yerine, önce `AltDetectorX.ps1` dosyasını [doğrudan burada](AltDetectorX.ps1) açıp okuyabilir ya da yapay zekaya yapıştırabilirsin. Script açık kaynaktır; tüm kodu bu repoda görünür.

## Hızlı başlatma (tek satır)

CMD'ye (ya da Win+R penceresine) yapıştırıp çalıştırın. Komut, script'i geçici bir klasöre indirip `AltDetectorX.bat` ile çalıştırır:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=Join-Path $env:TEMP 'AltDetectorX';[void](mkdir $d -Force);'AltDetectorX.ps1','AltDetectorX.bat'|%{Invoke-WebRequest ('https://raw.githubusercontent.com/Extez61/AltDetectorX/main/'+$_) -UseBasicParsing -OutFile (Join-Path $d $_)};Start-Process (Join-Path $d 'AltDetectorX.bat')"
```

Dosyalar diske indiği için Windows Defender onları normal şekilde tarar; araç temiz olduğundan engellenmez. Script yönetici izni ister, sonra menüyü açar; tarama türü ve seçenekler menüden seçilir.

> Not: `irm ... | iex` gibi script'i **diske yazmadan bellekte çalıştıran** komutlar Defender tarafından engellenir (`Trojan:Win32/Commando.B!ml`). Bu, indir-ve-bellekte-çalıştır kalıbına verilen davranışsal bir uyarıdır, script'in içeriğiyle ilgili değildir. Yukarıdaki komut dosyayı diske indirdiği için bu sorunu yaşamaz.

## Elle kurulum

1. Yeşil **Code** düğmesi › **Download ZIP** ile repoyu indirin.
2. ZIP'i bir klasöre çıkarın.
3. `AltDetectorX.bat` dosyasına çift tıklayın.

Elle çalıştırmak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\AltDetectorX.ps1
```

### Parametreler

| Parametre | Açıklama |
|---|---|
| `-Mode Quick\|Normal\|Deep` | Hızlı, normal ya da tam tarama (varsayılan: `Normal`) |
| `-Paths` | Raporda dosya yollarını da gösterir |
| `-Export <dosya>` | Raporu metin dosyasına kaydeder |
| `-Threads <n>` | Log okuma iş parçacığı sayısı (varsayılan: otomatik) |
| `-NoWsl` | WSL dağıtımlarını taramaz |
| `-NoMenu` | Menüyü atlayıp doğrudan taramaya başlar |
| `-NoElevate` | Yönetici izni istemeden, sınırlı modda çalışır |

## Neleri kontrol eder

- **Loglar:** Minecraft ve launcher loglarındaki hesap adları (`Setting user:`, IAS ile hesap geçişleri, `--username`)
- **Hesap dosyaları:** launcher hesap dosyaları (Microsoft Launcher, TLauncher, Prism, MultiMC, Lunar, Feather, Modrinth ve diğerleri) ve IAS hesap kayıtları
- **Silinmiş dosyalar:** çöp kutusu, gölge kopyalar ve USN günlüğü
- **İz silme belirtileri:** Prefetch'te temizleme araçları, log klasörü ACL/junction oyunları ve log4j ile kapatılmış loglama
- **Diğer:** açık Java süreçleri, WSL dağıtımları, dual boot Linux bölümleri ve sanal makine diskleri

Silinmiş dosya kontrollerinin tamamı için yönetici yetkisi gerekir.

## Esinlenme

Bu proje, [Enr1c0o/Powershell-Scripts](https://github.com/Enr1c0o/Powershell-Scripts) reposundaki [Alt-Detector.ps1](https://github.com/Enr1c0o/Powershell-Scripts/blob/main/Alt-Detector.ps1) script'inden esinlenerek yapıldı.

## Gereksinimler

- Windows 10 / 11
- Windows PowerShell 5.1 ya da PowerShell 7
