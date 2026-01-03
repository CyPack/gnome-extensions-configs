# Dotfiles

Kişisel config dosyalarım.

## İçerik

- `gnome-extensions/` - GNOME Shell extensions ve ayarları
- `starship.toml` - Starship prompt config

## Kurulum

### GNOME Extensions
```bash
# Extensions'ları kopyala
cp -r gnome-extensions/extensions/* ~/.local/share/gnome-shell/extensions/

# Ayarları yükle
dconf load /org/gnome/shell/extensions/ < gnome-extensions/extensions-settings.dconf

# Logout/login yap, sonra:
while read -r ext; do
    gnome-extensions enable "$ext"
done < gnome-extensions/enabled-extensions.txt
```

### Starship
```bash
cp starship.toml ~/.config/starship.toml
```
