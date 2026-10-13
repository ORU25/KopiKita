## Desain UI (aplikasi pelanggan)

- Semua UI aplikasi pelanggan WAJIB mengikuti `kopikita-design/design/DESIGN.md` (sumber kebenaran untuk warna, tipografi, radius, jarak, komponen, dan perilaku layar).
- Sebelum membuat atau mengubah sebuah layar, buka gambar acuannya di `kopikita-design/design/screens/` (mis. `kopikita-design/design/screens/Menu.png`) dan bagian layar terkait di `DESIGN.md`.
- Jika ada nilai yang tidak jelas, cek nilai persisnya di `kopikita-design/design/source/<Layar>.dc.html` (inline CSS).
- Gunakan token di `lib/theme/` (AppColors, tipografi) — jangan menulis warna hex langsung di widget.
- Aturan penting: teks minimal 12, target sentuh minimal 44×44, thumbnail produk radius 10, daftar panjang memakai baris datar (bukan card), keranjang tampil sebagai strip di atas navbar (bukan tab), hanya metode Ambil Sendiri & Makan di Tempat, tidak ada fitur poin.
- **Setiap perubahan UI yang diminta/diajukan user (warna, komponen, perilaku layar, dll.) WAJIB juga diperbarui di `kopikita-design/design/DESIGN.md` dalam pekerjaan yang sama** — token, bagian komponen/layar terkait, dan contoh kode Flutter di dalamnya — agar `DESIGN.md` tetap jadi sumber kebenaran. Cantumkan pembaruan `DESIGN.md` di setiap rencana (plan) perubahan UI.
- Aset gambar ada di `kopikita-design/design/assets/`; salin ke `assets/` proyek dan daftarkan di `pubspec.yaml`.
