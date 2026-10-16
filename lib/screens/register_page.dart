import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';

// RegisterPage: layar Daftar (DESIGN.md 3.1a)
// Kerangka sama dengan Masuk; form berisi nama, email, kata sandi
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();

  bool _sembunyikan = true;
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.daftar(
        nama: _nama.text,
        email: _email.text,
        password: _sandi.text,
      );

      if (!mounted) return;
      context.read<UserProvider>().refresh();
      if (!mounted) return;
      masukAplikasi(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AuthService.pesanError(e))),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Daftar',
      subjudul: 'Buat akun untuk mulai memesan.',
      ajakan: 'Sudah punya akun?',
      aksi: 'Masuk',
      onAksi: () => Navigator.pop(context),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelField('Nama'),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                style: ts(14, 500),
                decoration: const InputDecoration(
                  hintText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 22),
                ),
                validator: (v) {
                  final teks = v?.trim() ?? '';
                  if (teks.isEmpty) return 'Nama wajib diisi.';
                  if (teks.length < 2) return 'Nama terlalu pendek.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              labelField('Email'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: ts(14, 500),
                decoration: const InputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 22),
                ),
                validator: (v) {
                  final teks = v?.trim() ?? '';
                  if (teks.isEmpty) return 'Email wajib diisi.';
                  if (!teks.contains('@') || !teks.contains('.')) {
                    return 'Format email tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              labelField('Kata sandi'),
              TextFormField(
                controller: _sandi,
                obscureText: _sembunyikan,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) {
                  if (!_loading) _daftar();
                },
                style: ts(14, 500),
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    tooltip: _sembunyikan
                        ? 'Tampilkan sandi'
                        : 'Sembunyikan sandi',
                    onPressed: () =>
                        setState(() => _sembunyikan = !_sembunyikan),
                    icon: Icon(
                      _sembunyikan
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Kata sandi wajib diisi.';
                  if ((v ?? '').length < 6) {
                    return 'Kata sandi minimal 6 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _loading ? 'Memproses...' : 'Daftar',
                onPressed: _loading ? null : _daftar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
