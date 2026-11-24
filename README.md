# AltDetectorX

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

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

## Gereksinimler

- Windows 10 / 11
- Windows PowerShell 5.1 ya da PowerShell 7
