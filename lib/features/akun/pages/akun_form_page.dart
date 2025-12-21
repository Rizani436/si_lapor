import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';

import '../models/akun_model.dart';
import '../providers/akun_provider.dart';

class AkunFormPage extends ConsumerStatefulWidget {
  final AkunModel? existing;
  const AkunFormPage({super.key, this.existing});

  @override
  ConsumerState<AkunFormPage> createState() => _AkunFormPageState();
}

class _AkunFormPageState extends ConsumerState<AkunFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController namaLengkapC;
  late final TextEditingController emailC;
  late final TextEditingController passwordC;

  late final TextEditingController _phoneInputC;

  String role = 'parent';
  bool aktif = true;
  bool saving = false;
  bool obscure = true;

  String _dialCode = '+62'; 
  String _phoneNumberOnly = ''; 
  String _isoCode = 'ID'; 

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    namaLengkapC = TextEditingController(text: s?.namaLengkap ?? '');
    emailC = TextEditingController(text: s?.email ?? '');
    passwordC = TextEditingController(text: '');

    role = s?.role ?? 'parent';
    aktif = s?.isActive ?? true;

    final storedHp = (s?.noHp ?? '').trim();

    final dial = detectDialCode(storedHp);
    if (dial != null) {
      _dialCode = dial;
      _isoCode = detectIsoFromPhone(storedHp);
    }
    final prefNumber = removeDialCode(storedHp, _dialCode);
    _phoneInputC = TextEditingController(text: prefNumber);
  }

  @override
  void dispose() {
    namaLengkapC.dispose();
    emailC.dispose();
    passwordC.dispose();
    _phoneInputC.dispose();
    super.dispose();
  }

  Future<void> safeClosePage(BuildContext rootContext) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 30));

    if (!mounted) return;
    if (Navigator.of(rootContext).canPop()) {
      Navigator.of(rootContext).pop(true);
    }
  }

  void showSnackRoot(BuildContext rootContext, String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!rootContext.mounted) return;
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  String removeDialCode(String phone, String dial) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final dialDigits = dial.replaceAll('+', '');

    if (digits.startsWith(dialDigits)) {
      return digits.substring(dialDigits.length);
    }
    return digits; 
  }

  String detectIsoFromPhone(String phone) {
    final dial = detectDialCode(phone);
    if (dial == null) return 'ID';

    final clean = dial.replaceAll('+', '');
    try {
      return countries.firstWhere((c) => c.dialCode == clean).code;
    } catch (_) {
      return 'ID';
    }
  }

  String? detectDialCode(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    final dialCodes = countries.map((c) => c.dialCode).toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final dial in dialCodes) {
      if (digits.startsWith(dial)) {
        return '+$dial';
      }
    }
    return null; 
  }

  @override
  Widget build(BuildContext context) {
    final rootContext = context;
    final isEdit = widget.existing != null;

    return PopScope(
      canPop: !saving,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (saving) return;
        await safeClosePage(rootContext);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Akun' : 'Tambah Akun')),
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: emailC,
                  enabled: !saving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final x = (v ?? '').trim();
                    if (x.isEmpty) return 'Wajib diisi';
                    if (!x.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: namaLengkapC,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                IntlPhoneField(
                  controller: _phoneInputC,
                  enabled: !saving,
                  initialCountryCode: _isoCode,
                  showCountryFlag: false,
                  showDropdownIcon: true,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    border: OutlineInputBorder(),
                    hintText: '81234567890',
                  ),

                  onCountryChanged: (country) {
                    setState(() {
                      _dialCode = '+${country.dialCode}';
                      _phoneNumberOnly = _phoneInputC.text.trim();
                    });
                  },

                  onChanged: (phone) {
                    _phoneNumberOnly = phone.number;
                    _dialCode = phone.countryCode;

                    _isoCode = phone.countryISOCode;
                  },

                  validator: (phone) {
                    if (phone == null || phone.number.trim().isEmpty) {
                      return 'Wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: passwordC,
                  enabled: !saving,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: isEdit
                        ? 'Kosongkan jika tidak ingin mengganti password'
                        : 'Minimal 8 karakter',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: saving
                          ? null
                          : () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (v) {
                    final pass = (v ?? '').trim();
                    if (!isEdit) {
                      if (pass.isEmpty) return 'Wajib diisi';
                      if (pass.length < 8) return 'Minimal 8 karakter';
                    } else {
                      if (pass.isNotEmpty && pass.length < 8) {
                        return 'Minimal 8 karakter';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'guru', child: Text('Guru')),
                    DropdownMenuItem(value: 'kepsek', child: Text('Kepsek')),
                    DropdownMenuItem(value: 'parent', child: Text('Orang Tua')),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => setState(() => role = v ?? 'parent'),
                ),
                if (saving) ...[
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Menyimpan...'),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }

                            final email = emailC.text.trim();
                            final nama = namaLengkapC.text.trim();
                            final pass = passwordC.text; 
                            String _digitsOnly(String s) =>
                                s.replaceAll(RegExp(r'[^0-9]'), '');
                            final hpOnlyRaw = _phoneNumberOnly.trim().isNotEmpty
                                ? _phoneNumberOnly.trim()
                                : _phoneInputC.text
                                      .trim(); 

                            final hpOnly = _digitsOnly(hpOnlyRaw);


                            final hpFullNoPlus = _digitsOnly(
                              '$_dialCode$hpOnly',
                            ); 

                            setState(() => saving = true);

                            if (!isEdit) {

                              try {
                                final payload = AkunModel(
                                  id: '', 
                                  email: email,
                                  namaLengkap: nama,
                                  noHp: hpFullNoPlus, 
                                  role: role,
                                  isActive: aktif,
                                );

                                await ref
                                    .read(akunListProvider.notifier)
                                    .add(payload, pass);

                                await safeClosePage(rootContext);
                                showSnackRoot(
                                  rootContext,
                                  'Akun berhasil dibuat',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                setState(() => saving = false);
                                showSnackRoot(
                                  rootContext,
                                  'Gagal tambah akun: $e',
                                );
                              } finally {
                                if (mounted) setState(() => saving = false);
                              }
                            } else {

                              final akun = widget.existing!;
                              try {
                                final payload = akun.copyWith(
                                  email: email,
                                  namaLengkap: nama,
                                  noHp: hpFullNoPlus,
                                  role: role,
                                  isActive: aktif,
                                );

                                await ref
                                    .read(akunListProvider.notifier)
                                    .edit(akun.id, payload);
                                await safeClosePage(rootContext);
                                showSnackRoot(
                                  rootContext,
                                  'Akun berhasil diperbarui',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                setState(() => saving = false);
                                showSnackRoot(rootContext, 'Gagal update: $e');
                              } finally {
                                if (mounted) setState(() => saving = false);
                              }
                            }
                          },
                    child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
