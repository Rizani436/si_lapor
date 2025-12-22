import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/session_provider.dart';
import '../../../core/ui_helpers.dart'; // ✅
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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

  Future<void> _pickAndUploadAvatar(WidgetRef ref) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    final Uint8List bytes = await x.readAsBytes();
    await ref.read(myProfileProvider.notifier).uploadAvatar(bytes, x.name);

    toast('Foto profile diperbarui');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profileAsync = ref.watch(myProfileProvider);

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
          final foto = p?.fotoProfile ?? session.fotoProfile;
          final nama = p?.namaLengkap ?? session.namaLengkap ?? '';
          final email = p?.email ?? session.email ?? '';
          final noHp = p?.noHp ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: InkWell(
                  onTap: () => _pickAndUploadAvatar(ref),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: (foto != null && foto.isNotEmpty)
                        ? NetworkImage(foto)
                        : null,
                    child: (foto == null || foto.isEmpty)
                        ? const Icon(Icons.person, size: 44)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => _pickAndUploadAvatar(ref),
                  icon: const Icon(Icons.edit),
                  label: const Text('Ubah Foto Profile'),
                ),
              ),
              const Divider(height: 32),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email.isEmpty ? '-' : email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await showInputDialog(
                    context: context,
                    title: 'Ubah Email',
                    initialValue: email,
                    hint: 'Masukkan email',
                  );
                  if (result == null || result.isEmpty) return;

                  await ref.read(myProfileProvider.notifier).updateEmail(result);
                  toast('Email diperbarui');
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
                  final v = await _promptText(
                    title: 'Ubah No HP',
                    initial: noHp,
                    keyboardType: TextInputType.phone,
                  );
                  if (v == null) return;

                  await ref.read(myProfileProvider.notifier).updateNoHp(v);
                  toast('No HP diperbarui');
                },
              ),

              const Divider(height: 32),

              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Ubah Password'),
                subtitle: const Text('Klik untuk mengganti password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result 

                  await ref
                      .read(myProfileProvider.notifier)
                      .changePassword(pass);
                  toast('Password berhasil diubah');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
