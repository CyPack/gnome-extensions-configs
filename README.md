# Dotfiles

Fedora odakli, paylasima uygun kisisel desktop config paketi.

![GNOME Extensions mevcut durum](assets/extensions-manager-screenshot.png)

## Icerik

- `gnome-extensions/enabled-extensions.txt`: Aktif edilmesi istenen GNOME extension UUID listesi
- `gnome-extensions/extensions-settings.dconf`: GNOME extension ayarlari (local path satirlari sanitize edildi)
- `gnome-extensions/extensions/`: Export edilen extension dosyalari
- `starship.toml`: Starship prompt config
- `scripts/install-gnome.sh`: Agent-friendly, idempotent kurulum scripti

## Dependency (GNOME yolu)

Gerekli komutlar:

- `gnome-extensions`
- `dconf`
- `gsettings`
- `rsync`
- `starship` (opsiyonel, prompt istiyorsan)

Fedora icin ornek:

```bash
sudo dnf install -y gnome-extensions-app dconf rsync starship
```

## Agent-Friendly Kurulum

Repo klasorunde:

```bash
bash scripts/install-gnome.sh
```

Ne yapar:

1. Dependency kontrolu yapar
2. Extension dosyalarini `~/.local/share/gnome-shell/extensions/` altina senkronlar
3. `extensions-settings.dconf` dosyasini yukler
4. `enabled-extensions.txt` listesindeki extensionlari enable etmeye calisir
5. `starship.toml` dosyasini `~/.config/starship.toml` altina kopyalar

Not:

- GNOME Shell restart/islem yenilemesini kendin yap: Wayland'de logout/login, X11'de `Alt+F2` sonra `r`.
- `blur-my-shell` bu repoda bilerek kapali tutuluyor (enabled listede yok).
- Neden: `blur-my-shell` ozellikle pencere/background blur efektlerinde sistemi ciddi sekilde yorabiliyor; CPU/GPU yukunu arttirip takilma ve animasyon gecikmesi yaratabiliyor.
- Acmak istersen: `gnome-extensions enable blur-my-shell@aunetx`

## Manuel Kurulum

```bash
mkdir -p ~/.local/share/gnome-shell/extensions ~/.config
rsync -a --delete gnome-extensions/extensions/ ~/.local/share/gnome-shell/extensions/
dconf load /org/gnome/shell/extensions/ < gnome-extensions/extensions-settings.dconf
while read -r ext; do
  [ -n "$ext" ] && gnome-extensions enable "$ext" || true
done < gnome-extensions/enabled-extensions.txt
cp starship.toml ~/.config/starship.toml
```

## Theme Snapshot (Guncel)

- Icon theme: `WhiteSur`
- GTK theme: `Tahoe-Dark`
- Cursor theme: `MacTahoe-cursors`

## Icon Theme Degistirme

GNOME:

```bash
# Mevcut icon theme
gsettings get org.gnome.desktop.interface icon-theme

# Icon theme degistir
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'
```

KDE/Plasma:

```bash
# Paket arama ornegi (Fedora)
dnf search icon-theme | head

# Uygulama yolu:
# System Settings -> Appearance -> Icons
```

Tavsiye:

1. Icon paketini `~/.icons` veya `~/.local/share/icons` altina kur.
2. GNOME'da `gsettings` veya `gnome-tweaks` ile sec.
3. KDE'de System Settings uzerinden secip oturum yenile.
4. Paylasimda lisansi acik olan icon paketlerini tercih et.

## KDE Kullananlar Icin Alternatif Yol

Bu repo GNOME tabanli. KDE/Plasma kullaniyorsan birebir calismaz. Arastirma icin tavsiye edilen eslestirme:

1. Dock/Panel: GNOME `dash-to-dock` yerine Plasma panel + Icons-only Task Manager
2. Blur/Glass etkisi: GNOME `blur-my-shell` yerine KWin blur/desktop effects + tema motoru (Kvantum)
3. Media kontrolleri: GNOME `mediacontrols` yerine Plasma widgetlar (Media Controller)
4. Workspace/tiling: GNOME `tilingshell/forge` yerine KWin scripts (tiling)
5. Top bar gorunumu: GNOME `openbar` yerine Plasma panel temasi + renk ayarlari

Arastirma baslangic komutlari:

```bash
# Kurulu Plasma paketleri
dnf list installed | rg -i 'plasma|kwin|kde'

# KWin scriptleri / plasmoid paketleri (sistemine gore biri bulunur)
command -v kpackagetool6 && kpackagetool6 --list --type KWin/Script
command -v kpackagetool5 && kpackagetool5 --list --type KWin/Script
```

Arastirma anahtar kelimeleri:

- `plasma panel transparency blur`
- `kwin tiling script fedora`
- `plasma media controller widget`
- `kvantum fedora setup`
