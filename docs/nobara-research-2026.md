# Nobara GNOME Research (2026-02-21)

Bu dokuman, Nobara icin GNOME extension/default/update davranisini 2026 odakli resmi kaynaklarla ozetler.

## Kapsam

- Arastirma tarihi: `2026-02-21`
- Kaynak tipi: sadece resmi Nobara wiki/site + Nobara resmi GitHub organizasyonu
- Hedef: bu repodaki GNOME configlerin Nobara'da guvenli uygulama stratejisi

## Bulgu Ozeti

1. Nobara indirme sayfasi `Nobara-43` icin 2026 tarihli ISO dosyalarini listeliyor (GNOME/KDE/Official/Steam).
2. Nobara Wiki FAQ, `Official` surumun KDE duzeni tabanli oldugunu; GNOME ve KDE'nin ayrica sunuldugunu belirtiyor.
3. Guncel GNOME kickstart dosyalarinda (N42/N43) acik gorunen extension paketi `gnome-shell-extension-gamemode`.
4. Nobara update politikasinda `Update System`/`nobara-sync` akisi oneriliyor; `dnf system-upgrade` akisi icin acik uyari var.

## Kanit Tablosu

### 1) 2026 Nobara ISO Durumu

Kaynak: `https://nobaraproject.org/download-nobara/`

- `Nobara-43-GNOME-2026-01-26.iso`
- `Nobara-43-GNOME-NV-2026-01-26.iso`
- `Nobara-43-KDE-2026-01-26.iso`
- `Nobara-43-KDE-NV-2026-01-26.iso`
- `Nobara-43-Official-2026-01-25.iso`
- `Nobara-43-Official-NV-2026-01-26.iso`
- `Nobara-43-Steam-HTPC-2026-01-27.iso`

### 2) GNOME Kickstart Extension Kaniti (N42/N43)

Kaynak repo: `https://github.com/Nobara-Project/nobara-images`

| Release | Dosya/Satir | Kanit |
|---|---|---|
| N43 | `ISO-ready-flattened-kickstarts/43/flat-nobara-live-gnome-43.ks#L430` | `gnome-shell-extension-gamemode` |
| N43 (NV) | `ISO-ready-flattened-kickstarts/43/nv-flat-nobara-live-gnome-43.ks#L441` | `gnome-shell-extension-gamemode` |
| N42 | `ISO-ready-flattened-kickstarts/42/flat-nobara-live-gnome-42.ks#L237` | `gnome-shell-extension-gamemode` |
| N42 (NV) | `ISO-ready-flattened-kickstarts/42/nv-flat-nobara-live-gnome-42.ks#L257` | `gnome-shell-extension-gamemode` |
| N42 | `ISO-ready-flattened-kickstarts/42/flat-nobara-live-gnome-42.ks#L405` | `-gnome-shell-extension-background-logo` (remove) |

Blame (ornek):

- N43 satiri commit tarihi: `2026-01-04`
- N42 satiri commit tarihi: `2025-09-08`

### 3) Update / Upgrade Politika Kaniti

| Konu | Kaynak | Dogrulama |
|---|---|---|
| `dnf update` tek basina yetersiz | `.../troubleshooting/update-system` | Sayfada Update System akisi oneriliyor |
| Nobara sync araci | `.../troubleshooting/update-system` | `nobara-sync` ve `nobara-sync cli` belirtiliyor |
| Fedora tarz `dnf system-upgrade` kullanma | `.../troubleshooting/upgrade-nobara` | Sayfada `DON'T USE THESE` uyarisi var |
| Sistem guncelleme akisi | `.../en/new-user-guide-general-guidelines` | Nobara System Update app tavsiyesi veriliyor |

## Pratik Sonuc (Bu Repo Icin)

1. Nobara GNOME'da once extension envanterini cikar (`gnome-extensions list --enabled`, `rpm -qa | rg '^gnome-shell-extension'`).
2. Bu repo configlerini uygulamadan once dconf backup al.
3. Update/upgrade icin Nobara'nin kendi updater akisini kullan (`Update System` / `nobara-sync cli`).
4. `blur-my-shell` kapali kalmali (performans nedeniyle).

## Kaynaklar

- `https://nobaraproject.org/download-nobara/`
- `https://wiki.nobaraproject.org/FAQ/FAQ`
- `https://wiki.nobaraproject.org/general-usage/troubleshooting/update-system`
- `https://wiki.nobaraproject.org/general-usage/troubleshooting/upgrade-nobara`
- `https://wiki.nobaraproject.org/en/new-user-guide-general-guidelines`
- `https://github.com/Nobara-Project/nobara-images`
