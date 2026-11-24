# AltDetectorX

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

## Kurulum ve çalıştırma

1. Yeşil **Code** düğmesi › **Download ZIP** ile repoyu indirin (ya da `AltDetectorX.ps1` ve `AltDetectorX.bat` dosyalarını alın).
2. ZIP'i bir klasöre çıkarın.
3. `AltDetectorX.bat` dosyasına çift tıklayın. Script yönetici izni ister, sonra menüyü açar; tarama türü ve seçenekler menüden seçilir.

Elle çalıştırmak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\AltDetectorX.ps1
```

### Tek satırlık komut (indir-ve-çalıştır) hakkında

Script'i indirip doğrudan bellekte çalıştıran tek satırlık komutlar (`irm ... | iex` gibi) **Windows Defender tarafından engellenir** — bu kalıp, kaynağı ne olursa olsun kötü amaçlı yazılımlarda sık kullanıldığı için davranışsal olarak (`Trojan:Win32/Commando.B!ml`) işaretlenir. Bu, script'in içeriğiyle ilgili bir uyarı değildir; dosyanın kendisi Defender taramasından temiz geçer. Bu yüzden önerilen yöntem, yukarıdaki gibi dosyayı indirip çalıştırmaktır.

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
