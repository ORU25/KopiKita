# Paket desain KopiKita untuk Claude Code

Ekstrak isi zip ini ke **root repo Flutter** sehingga ada folder `design/`:

```
design/
  DESIGN.md        ← spesifikasi lengkap (token warna, tipografi, komponen, tiap layar, saran Flutter)
  screens/         ← tangkapan layar tiap layar (PNG 2x, 780×1688)
  source/          ← file HTML asli dari desain (nilai CSS persis)
  assets/          ← banner Beranda + ikon Ambil Sendiri / Makan di Tempat
  fonts/           ← Plus Jakarta Sans (variabel) + lisensi OFL
CLAUDE.md.snippet  ← tempel isinya ke CLAUDE.md di root repo
```

Lalu tambahkan isi `CLAUDE.md.snippet` ke `CLAUDE.md` di root repo (buat file itu jika belum ada). Setelah itu cukup minta Claude Code, misalnya:

> Buat layar Beranda sesuai design/DESIGN.md bagian 3.2 dan design/screens/Beranda.png.

Catatan: `source/*.dc.html` adalah format kanvas desain (bukan HTML biasa yang bisa langsung dibuka di browser) — gunakan sebagai referensi nilai, bukan untuk dijalankan.
