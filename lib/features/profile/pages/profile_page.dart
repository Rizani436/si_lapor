import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/UI/ui_helpers.dart'; // ✅
import '../providers/profile_provider.dart';
import '../providers/profile_action_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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

  Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String initialValue = '',
    String hint = '',
  }) {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, controller.text.trim());
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> showInputPhoneDialog({
    required BuildContext context,
    required String title,
    required String initialDigitsOnly,
    String hint = '',
  }) {
    String isoCode = 'ID';
    String dialCode = '+62';
    String phoneNumberOnly = '';

    final dial = detectDialCode(initialDigitsOnly);
    if (dial != null) {
      dialCode = dial;
      isoCode = detectIsoFromPhone(initialDigitsOnly);
    }

    phoneNumberOnly = initialDigitsOnly
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(dialCode.replaceAll('+', ''), '');

    final controller = TextEditingController(text: phoneNumberOnly);

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            child: IntlPhoneField(
              controller: controller,
              initialCountryCode: isoCode,
              showCountryFlag: false,
              showDropdownIcon: true,
              decoration: InputDecoration(hintText: hint),
              onCountryChanged: (country) {
                dialCode = '+${country.dialCode}';
                phoneNumberOnly = controller.text.trim();
                isoCode = country.code;
              },
              onChanged: (phone) {
                phoneNumberOnly = phone.number;
                dialCode = phone.countryCode;
                isoCode = phone.countryISOCode;
              },

              validator: (phone) {
                if (phone == null || phone.number.trim().isEmpty) {
                  return 'Wajib diisi';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final digitsOnly = (dialCode + controller.text.trim())
                    .replaceAll(RegExp(r'[^0-9]'), '');

                Navigator.pop(ctx, digitsOnly);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(WidgetRef ref) async {
    final picker = ImagePicker();

    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // ambil bagus dulu, kompres nanti
      // opsional: batasi ukuran awal biar tidak terlalu besar
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (x == null) return;

    final Uint8List originalBytes = await x.readAsBytes();

    // ✅ AUTO RESIZE + COMPRESS (target 512px, quality 80)
    final Uint8List resized = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 512,
      minHeight: 512,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    await ref
        .read(myProfileProvider.notifier)
        .uploadAvatar(resized, 'avatar.jpg');

    // ✅ supaya navbar/profile langsung ganti (kalau kamu sudah pakai avatarVersion)
    ref.read(sessionProvider.notifier).bumpAvatarVersion();

    toast('Foto profile diperbarui');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final action = ref.watch(profileActionProvider);

    final isUpdatingEmail = action.isLoading;

    if (!session.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Silakan login dulu.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(myProfileProvider.notifier).refresh(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) {
          final nama = p?.namaLengkap ?? session.namaLengkap ?? '';
          final email = p?.email ?? session.email ?? '';
          final noHp = p?.noHp ?? '';
          // ✅ kalau provider sedang loading (upload/refresh)
          final isBusy = profileAsync.isLoading;

          final foto = p?.fotoProfile ?? session.fotoProfile;
          final v = session.avatarVersion;

          final fotoUrl = (foto != null && foto.isNotEmpty)
              ? '$foto?v=$v'
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: InkWell(
                  onTap: isBusy ? null : () => _pickAndUploadAvatar(ref),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundImage: (fotoUrl != null)
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: (fotoUrl == null)
                            ? const Icon(Icons.person, size: 44)
                            : null,
                      ),
                      if (isBusy)
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: isBusy ? null : () => _pickAndUploadAvatar(ref),
                  icon: const Icon(Icons.edit),
                  label: Text(isBusy ? 'Mengunggah...' : 'Ubah Foto Profile'),
                ),
              ),
              const Divider(height: 8),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email.isEmpty ? '-' : email),
                trailing: isUpdatingEmail
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                enabled: !isUpdatingEmail,
                onTap: isUpdatingEmail
                    ? null
                    : () async {
                        final result = await showInputDialog(
                          context: context,
                          title: 'Ubah Email',
                          initialValue: email,
                          hint: 'Masukkan email',
                        );
                        if (result == null) return;

                        final clean = result.trim().toLowerCase().replaceAll(
                          RegExp(r'\s+'),
                          '',
                        );

                        if (clean.isEmpty || clean == email) return;

                        // ✅ validasi email sederhana
                        final ok = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(clean);
                        if (!ok) {
                          if (!context.mounted) return;
                          toast('Email tidak valid: $clean');
                          return;
                        }

                        try {
                          await ref
                              .read(profileActionProvider.notifier)
                              .updateEmail(ref, clean);
                          if (!context.mounted) return;
                          toast('Email diperbarui');
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
              ),

              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Nama Lengkap'),
                subtitle: Text(nama.isEmpty ? '-' : nama),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await showInputDialog(
                    context: context,
                    title: 'Ubah Nama Lengkap',
                    initialValue: nama,
                    hint: 'Masukkan nama lengkap',
                  );

                  if (result == null || result.isEmpty) return;

                  await ref.read(myProfileProvider.notifier).updateNama(result);
                  toast('Nama lengkap diperbarui');
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('No HP'),
                subtitle: Text(noHp.isEmpty ? '-' : noHp),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await showInputPhoneDialog(
                    context: context,
                    title: 'Ubah No HP',
                    initialDigitsOnly: noHp,
                    hint: 'Masukkan nomor HP',
                  );

                  if (result == null || result.isEmpty) return;

                  await ref.read(myProfileProvider.notifier).updateNoHP(result);
                  toast('No HP diperbarui');
                },
              ),

              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Ubah Password'),
                subtitle: const Text('Masukkan password lama untuk verifikasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final email = (ref.read(sessionProvider).email ?? '').trim();
                  if (email.isEmpty) {
                    toast('Email tidak ditemukan. Silakan login ulang.');
                    return;
                  }

                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final oldC = TextEditingController();
                      final newC = TextEditingController();

                      bool saving = false;
                      bool obscureOld = true;
                      bool obscureNew = true;

                      String? oldErrorText; // ✅ error khusus password lama
                      String? newErrorText; // ✅ error password baru (optional)

                      return StatefulBuilder(
                        builder: (ctx, setLocal) => AlertDialog(
                          title: const Text('Ubah Password'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: oldC,
                                obscureText: obscureOld,
                                decoration: InputDecoration(
                                  labelText: 'Password Lama',
                                  errorText:
                                      oldErrorText, // ✅ tampil merah di sini
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureOld
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setLocal(
                                      () => obscureOld = !obscureOld,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (oldErrorText != null) {
                                    setLocal(
                                      () => oldErrorText = null,
                                    ); // ✅ reset saat user mengetik
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: newC,
                                obscureText: obscureNew,
                                decoration: InputDecoration(
                                  labelText: 'Password Baru',
                                  hintText: 'Minimal 8 karakter',
                                  errorText: newErrorText,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureNew
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setLocal(
                                      () => obscureNew = !obscureNew,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (newErrorText != null) {
                                    setLocal(() => newErrorText = null);
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final oldPass = oldC.text.trim();
                                      final newPass = newC.text.trim();

                                      // reset error dulu
                                      setLocal(() {
                                        oldErrorText = null;
                                        newErrorText = null;
                                      });

                                      if (oldPass.isEmpty) {
                                        setLocal(
                                          () => oldErrorText =
                                              'Password lama wajib diisi',
                                        );
                                        return;
                                      }
                                      if (newPass.isEmpty) {
                                        setLocal(
                                          () => newErrorText =
                                              'Password baru wajib diisi',
                                        );
                                        return;
                                      }
                                      if (newPass.length < 8) {
                                        setLocal(
                                          () => newErrorText =
                                              'Minimal 8 karakter',
                                        );
                                        return;
                                      }

                                      setLocal(() => saving = true);
                                      try {
                                        final success = await ref
                                            .read(
                                              profileActionProvider.notifier,
                                            )
                                            .changePasswordWithVerify(
                                              oldPassword: oldPass,
                                              newPassword: newPass,
                                            );

                                        if (!ctx.mounted) return;

                                        if (!success) {
                                          setLocal(
                                            () => oldErrorText =
                                                'Password lama salah',
                                          );
                                          return;
                                        }

                                        Navigator.pop(
                                          ctx,
                                          true,
                                        ); // sukses -> tutup dialog
                                      } catch (e) {
                                        if (!ctx.mounted) return;

                                        final msg = e.toString().toLowerCase();

                                        // ✅ kalau password lama salah -> tampilkan di field, dialog tetap terbuka
                                        if (msg.contains(
                                          'password lama salah',
                                        )) {
                                          setLocal(
                                            () => oldErrorText =
                                                'Password lama salah',
                                          );
                                        } else {
                                          // error lain -> snack
                                          ScaffoldMessenger.of(
                                            ctx,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (ctx.mounted)
                                          setLocal(() => saving = false);
                                      }
                                    },
                              child: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (ok == true) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password berhasil diubah. Silakan login ulang.',
                        ),
                      ),
                    );

                    await ref.read(sessionProvider.notifier).logout();
                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
