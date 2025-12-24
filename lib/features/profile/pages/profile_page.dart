import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/UI/ui_helpers.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_action_provider.dart';
import '../../../core/navigation/routes.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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
                  onTap: isBusy
                      ? null
                      : () async {
                          final resized = await pickAndUploadAvatar(ref);
                          final tes = resized.toString();
                          print("resized" + tes);

                          if (tes != "[]") {
                            await ref
                                .read(myProfileProvider.notifier)
                                .uploadAvatar(resized, 'avatar.jpg');

                            ref
                                .read(sessionProvider.notifier)
                                .bumpAvatarVersion();

                            toast('Foto profile diperbarui');
                          }
                        },
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
                  onPressed: isBusy
                      ? null
                      : () async {
                          final resized = await pickAndUploadAvatar(ref);
                          final tes = resized.toString();
                          print("resized" + tes);

                          if (tes != "[]") {
                            await ref
                                .read(myProfileProvider.notifier)
                                .uploadAvatar(resized, 'avatar.jpg');

                            ref
                                .read(sessionProvider.notifier)
                                .bumpAvatarVersion();

                            toast('Foto profile diperbarui');
                          }
                        },
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
                  final ok = await showInputUbahPassword(
                    context: context,
                    title: 'Ubah Password',
                    ref: ref,
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
