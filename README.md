# AltDetectorX

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

## Güvenli mi? Kendin denetlet

Bu script'i çalıştırmadan önce emin olmak istiyorsan, aşağıdaki promptu herhangi bir yapay zekaya (ChatGPT, Claude, Gemini vb.) yapıştır:

```text
Şu PowerShell script'ini incele: https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.ps1
İnternete veri gönderiyor, dosya siliyor/değiştiriyor ya da şifre/token gibi
hassas veri çalıyor mu? Çalıştırmak güvenli mi? Sade bir dille açıkla.
```

## Hızlı başlatma (tek satır)

CMD'ye ya da PowerShell'e yapıştırıp çalıştırın (ikisinde de çalışır). Komut, script'i geçici klasöre (`%TEMP%`) indirip `AltDetectorX.bat` ile çalıştırır:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd ([IO.Path]::GetTempPath()); iwr https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.ps1 -UseBasicParsing -OutFile AltDetectorX.ps1; iwr https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.bat -UseBasicParsing -OutFile AltDetectorX.bat; start .\AltDetectorX.bat"
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
