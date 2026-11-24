# AltDetectorX

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

## Hızlı başlatma (tek satır)

İndirmeden, doğrudan CMD'ye (ya da Win+R penceresine) yapıştırıp çalıştırın:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.ps1 -TimeoutSec 30 | iex"
```

Script en son sürümü GitHub'dan indirip bellekte çalıştırır, kalıcı dosya bırakmaz. Yönetici izni ister, sonra menüyü açar; tarama türü ve seçenekler menüden seçilir.

- GitHub'a bağlantı takılırsa komut 30 saniye sonra hata verip kapanır (sonsuza kadar donmaz). Bu durumda komutu tekrar çalıştırın.
- Parametreyle (`-Mode`, `-Export` vb.) çalıştırmak için `AltDetectorX.ps1`'i indirip aşağıdaki gibi çalıştırın.

> Bu komut yalnızca repo herkese açıkken (public) çalışır.

## Çalıştırma

`AltDetectorX.bat` dosyasına çift tıklayın. Script yönetici izni ister, sonra menüyü açar.

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
