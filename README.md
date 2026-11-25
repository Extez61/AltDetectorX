# AltDetectorX

A PowerShell tool that finds Minecraft accounts (alts) used on a Windows PC and signs of trace removal. It is made for use during screenshare (SS) checks. It does not connect to the network for scanning; it only reads files and never changes anything.

[English](#english) | [Türkçe](#türkçe)

## English

### Is it safe? Check it yourself

If you want to be sure before running the script, paste the prompt below into any AI assistant (ChatGPT, Claude, Gemini, etc.):

```text
Review this PowerShell script: https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.ps1
Does it send data to the internet, delete or modify files, or steal sensitive
data such as passwords or tokens? Is it safe to run? Explain in plain language.
```

### Quick start (one line)

Paste it into CMD or PowerShell and run it (works in both):

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "curl.exe -fsSL -m 30 --retry 3 -o ([IO.Path]::GetTempPath()+'adx.ps1') https://raw.githubusercontent.com/Extez61/AltDetectorX/main/start.ps1; & ([IO.Path]::GetTempPath()+'adx.ps1')"
```

This command downloads and runs the small launcher in this repository ([start.ps1](start.ps1)). The launcher downloads `AltDetectorX.ps1`, `AltDetectorX.bat` and the English language file into `%TEMP%\AltDetectorX` and runs the `.bat` in the same terminal. The launcher is short; you can read it before running.

When the script starts, it asks for the language: **EN** (English) or **TR** (Turkish). Then it asks for administrator permission and opens the menu, where you choose the scan type and options. All menu options (show file paths, scan WSL distributions, save the report to the desktop) are enabled by default; turn off the ones you do not need with the Space key. The **Hide username** option is off by default; when turned on, the Windows user name in file paths is shown as `***` both on the scan screen and in the report (for example `C:\Users\***\AppData\...`). Minecraft account names are never hidden.

> Administrator permission: Windows cannot give administrator rights to an already open terminal, so when permission is requested the scan opens in a separate administrator window. To keep everything in the same window, open the terminal with **"Run as administrator"**, or on Windows 11 enable **Settings > System > For developers > Enable sudo** (inline mode).

- The latest version is always downloaded: the launcher first asks GitHub for the latest commit and downloads the files from that commit, so it is not affected by GitHub's 5-minute cache. (If GitHub cannot be reached, it downloads from the normal address.)
- If the connection is slow or stalls, each file waits at most 60 seconds and is retried 3 times; the command never hangs forever.
- If the download fails, a red warning is shown; just run the command again.
- It uses `curl.exe`, which is built into Windows 10 (1803 and later) and Windows 11.

Because the files are downloaded to disk, Windows Defender scans them normally; the tool is clean, so it is not blocked.

> Note: Commands that run a script **in memory without writing it to disk** (such as `irm ... | iex`) are blocked by Windows Defender (`Trojan:Win32/Commando.B!ml`). This is a behavioral detection of the download-and-run-in-memory pattern, not a verdict on the script's content. The command above downloads the file to disk, so it does not have this problem.

### Manual installation

1. Download the repository with the green **Code** button > **Download ZIP**.
2. Extract the ZIP into a folder.
3. Double-click `AltDetectorX.bat`.

To run it manually:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\AltDetectorX.ps1 -Lang EN
```

### Language support

Turkish text is built into the script. English text is kept in [lang/en.json](lang/en.json): the script looks for it next to itself, then in `%TEMP%\AltDetectorX\lang`, and if it cannot find it, downloads it from GitHub once and caches it. Turkish users download nothing extra. If the language file cannot be loaded, the script continues in Turkish.

### Parameters

| Parameter | Description |
|---|---|
| `-Lang EN\|TR` | Interface and report language (when given, the language question is skipped) |
| `-Mode Quick\|Normal\|Deep` | Quick, normal or full scan (default: `Normal`) |
| `-Paths` | Also shows file paths in the report |
| `-Export <file>` | Saves the report to a text file |
| `-Threads <n>` | Number of threads for reading logs (default: automatic) |
| `-NoWsl` | Does not scan WSL distributions |
| `-NoMenu` | Skips the menu and starts scanning immediately |
| `-NoElevate` | Runs in limited mode without asking for administrator permission |
| `-HideUser` | Hides the Windows user name in file paths on screen and in the report |

### What it checks

- **Logs:** account names in Minecraft and launcher logs (`Setting user:`, IAS account switches, `--username`)
- **Account files:** launcher account files and IAS account records. Supported launchers:
  - Official Minecraft Launcher (regular and Microsoft Store), TLauncher / Legacy Launcher, SKLauncher
  - Prism Launcher and its offline forks: PollyMC, Fjord Launcher, ElyPrism Launcher, Freesm Launcher
  - MultiMC, UltimMC, PolyMC, ATLauncher, GDLauncher, CurseForge, Modrinth App, FTB App, Technic
  - HMCL (Hello Minecraft! Launcher), X Minecraft Launcher (XMCL), LiquidLauncher
  - Lunar Client, Badlion Client, Feather Client, LabyMod, Salwyrr
- **In-game account (alt) managers:** saved accounts of Meteor Client and LiquidBounce are read. If the encrypted account files of Wurst Client or the Keychain mod are found, a warning is shown.
- **Deleted files:** Recycle Bin, shadow copies and the USN journal
- **Signs of trace removal:** cleaning tools in Prefetch, tricks with the logs folder (ACL/junction) and logging disabled through log4j
- **Other:** running Java processes, WSL distributions, dual-boot Linux partitions and virtual machine disks

Administrator rights are required for all of the deleted file checks.

### Inspiration

This project was inspired by the [Alt-Detector.ps1](https://github.com/Enr1c0o/Powershell-Scripts/blob/main/Alt-Detector.ps1) script in the [Enr1c0o/Powershell-Scripts](https://github.com/Enr1c0o/Powershell-Scripts) repository.

### Requirements

- Windows 10 / 11
- Windows PowerShell 5.1 or PowerShell 7

### License

Use is free; you may modify and share it, but the `made by ~extez610` signature cannot be removed and the software cannot be sold. See the [LICENSE](LICENSE) file (in Turkish) for details.

---

## Türkçe

Windows'ta kullanılmış Minecraft hesaplarını (altları) ve iz silme belirtilerini bulan PowerShell aracı. SS (ekran paylaşımlı kontrol) sırasında kullanılmak üzere yazıldı. Tarama için ağa bağlanmaz; dosyaları yalnızca okur, hiçbir şeyi değiştirmez.

### Güvenli mi? Kendin denetlet

Bu script'i çalıştırmadan önce emin olmak istiyorsan, aşağıdaki promptu herhangi bir yapay zekaya (ChatGPT, Claude, Gemini vb.) yapıştır:

```text
Şu PowerShell script'ini incele: https://raw.githubusercontent.com/Extez61/AltDetectorX/main/AltDetectorX.ps1
İnternete veri gönderiyor, dosya siliyor/değiştiriyor ya da şifre/token gibi
hassas veri çalıyor mu? Çalıştırmak güvenli mi? Sade bir dille açıkla.
```

### Hızlı başlatma (tek satır)

CMD'ye ya da PowerShell'e yapıştırıp çalıştırın (ikisinde de çalışır):

```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "curl.exe -fsSL -m 30 --retry 3 -o ([IO.Path]::GetTempPath()+'adx.ps1') https://raw.githubusercontent.com/Extez61/AltDetectorX/main/start.ps1; & ([IO.Path]::GetTempPath()+'adx.ps1')"
```

Bu komut repodaki küçük başlatıcıyı ([start.ps1](start.ps1)) indirip çalıştırır. Başlatıcı da `AltDetectorX.ps1`, `AltDetectorX.bat` ve İngilizce dil dosyasını `%TEMP%\AltDetectorX` klasörüne indirip `.bat`'ı aynı terminalde çalıştırır. Başlatıcının içeriği kısadır, çalıştırmadan önce okuyabilirsiniz.

Script açılınca dili sorar: **EN** (İngilizce) ya da **TR** (Türkçe). Ardından yönetici izni ister ve menüyü açar; tarama türü ve seçenekler menüden seçilir. Menüdeki seçeneklerin hepsi (dosya yollarını göster, WSL dağıtımlarını tara, raporu masaüstüne kaydet) varsayılan olarak açık gelir; istemediğinizi Boşluk tuşuyla kapatabilirsiniz. **Kullanıcı adını gizle** seçeneği ise varsayılan olarak kapalıdır; açılırsa dosya yollarındaki Windows kullanıcı adı hem tarama ekranında hem raporda `***` olarak gösterilir (ör. `C:\Users\***\AppData\...`). Minecraft hesap adları hiçbir zaman gizlenmez.

> Yönetici izni: Windows, normal bir terminale sonradan yönetici yetkisi veremez; bu yüzden izin istendiğinde tarama ayrı bir yönetici penceresinde açılır. Her şeyin aynı pencerede çalışması için terminali **"Yönetici olarak çalıştır"** ile açın ya da Windows 11'de **Ayarlar > Sistem > Geliştiriciler için > sudo'yu etkinleştir** (satır içi mod) seçeneğini açın.

- Her zaman en güncel sürüm iner: başlatıcı önce GitHub'dan son commit'i sorar ve dosyaları o commit'ten indirir, böylece GitHub'ın 5 dakikalık önbelleğine takılmaz. (GitHub'a ulaşılamazsa normal adresten indirir.)
- Bağlantı yavaşsa ya da takılırsa her dosya için en fazla 60 saniye beklenir ve 3 kez yeniden denenir; komut asla sonsuza kadar donmaz.
- İndirme başarısız olursa kırmızı bir uyarı gösterilir; komutu tekrar çalıştırmanız yeterli.
- Windows 10 (1803 ve sonrası) ile Windows 11'de yerleşik gelen `curl.exe` kullanılır.

Dosyalar diske indiği için Windows Defender onları normal şekilde tarar; araç temiz olduğundan engellenmez.

> Not: `irm ... | iex` gibi script'i **diske yazmadan bellekte çalıştıran** komutlar Defender tarafından engellenir (`Trojan:Win32/Commando.B!ml`). Bu, indir-ve-bellekte-çalıştır kalıbına verilen davranışsal bir uyarıdır, script'in içeriğiyle ilgili değildir. Yukarıdaki komut dosyayı diske indirdiği için bu sorunu yaşamaz.

### Elle kurulum

1. Yeşil **Code** düğmesi > **Download ZIP** ile repoyu indirin.
2. ZIP'i bir klasöre çıkarın.
3. `AltDetectorX.bat` dosyasına çift tıklayın.

Elle çalıştırmak için:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\AltDetectorX.ps1
```

### Dil desteği

Türkçe metinler script'in içindedir. İngilizce metinler [lang/en.json](lang/en.json) dosyasında durur: script bu dosyayı önce kendi yanında, sonra `%TEMP%\AltDetectorX\lang` klasöründe arar; bulamazsa GitHub'dan bir kez indirip saklar. Türkçe kullananlar ek bir şey indirmez. Dil dosyası yüklenemezse script Türkçe devam eder.

### Parametreler

| Parametre | Açıklama |
|---|---|
| `-Lang EN\|TR` | Arayüz ve rapor dili (verilirse dil sorusu sorulmaz) |
| `-Mode Quick\|Normal\|Deep` | Hızlı, normal ya da tam tarama (varsayılan: `Normal`) |
| `-Paths` | Raporda dosya yollarını da gösterir |
| `-Export <dosya>` | Raporu metin dosyasına kaydeder |
| `-Threads <n>` | Log okuma iş parçacığı sayısı (varsayılan: otomatik) |
| `-NoWsl` | WSL dağıtımlarını taramaz |
| `-NoMenu` | Menüyü atlayıp doğrudan taramaya başlar |
| `-NoElevate` | Yönetici izni istemeden, sınırlı modda çalışır |
| `-HideUser` | Dosya yollarındaki Windows kullanıcı adını ekranda ve raporda gizler |

### Neleri kontrol eder

- **Loglar:** Minecraft ve launcher loglarındaki hesap adları (`Setting user:`, IAS ile hesap geçişleri, `--username`)
- **Hesap dosyaları:** launcher hesap dosyaları ve IAS hesap kayıtları. Desteklenen launcher'lar:
  - Resmî Minecraft Launcher (normal ve Microsoft Store), TLauncher / Legacy Launcher, SKLauncher
  - Prism Launcher ve çevrimdışı çatalları: PollyMC, Fjord Launcher, ElyPrism Launcher, Freesm Launcher
  - MultiMC, UltimMC, PolyMC, ATLauncher, GDLauncher, CurseForge, Modrinth App, FTB App, Technic
  - HMCL (Hello Minecraft! Launcher), X Minecraft Launcher (XMCL), LiquidLauncher
  - Lunar Client, Badlion Client, Feather Client, LabyMod, Salwyrr
- **Oyun içi hesap (alt) yöneticileri:** Meteor Client ve LiquidBounce'un kayıtlı hesapları okunur. Wurst Client ve Keychain modunun şifreli hesap dosyaları bulunursa uyarı verilir.
- **Silinmiş dosyalar:** çöp kutusu, gölge kopyalar ve USN günlüğü
- **İz silme belirtileri:** Prefetch'te temizleme araçları, log klasörü ACL/junction oyunları ve log4j ile kapatılmış loglama
- **Diğer:** açık Java süreçleri, WSL dağıtımları, dual boot Linux bölümleri ve sanal makine diskleri

Silinmiş dosya kontrollerinin tamamı için yönetici yetkisi gerekir.

### Esinlenme

Bu proje, [Enr1c0o/Powershell-Scripts](https://github.com/Enr1c0o/Powershell-Scripts) reposundaki [Alt-Detector.ps1](https://github.com/Enr1c0o/Powershell-Scripts/blob/main/Alt-Detector.ps1) script'inden esinlenerek yapıldı.

### Gereksinimler

- Windows 10 / 11
- Windows PowerShell 5.1 ya da PowerShell 7

### Lisans

Kullanım ücretsizdir; değiştirip paylaşabilirsiniz, ancak `made by ~extez610` imzası kaldırılamaz ve yazılım satılamaz. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
