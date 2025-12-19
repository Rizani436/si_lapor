import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_accounts_provider.dart';
import '../models/akun_model.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class KelolaAkunPage extends ConsumerStatefulWidget {
  const KelolaAkunPage({super.key});

  @override
  ConsumerState<KelolaAkunPage> createState() => _KelolaAkunPageState();
}

class _KelolaAkunPageState extends ConsumerState<KelolaAkunPage> {
  final searchC = TextEditingController();
  final _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollC.addListener(() {
      if (_scrollC.position.pixels >= _scrollC.position.maxScrollExtent - 250) {
        ref.read(adminAccountsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    searchC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminAccountsProvider);
    final ctrl = ref.read(adminAccountsProvider.notifier);

    if (searchC.text != st.search) {
      searchC.text = st.search;
      searchC.selection = TextSelection.fromPosition(
        TextPosition(offset: searchC.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.resetFilters();
              ctrl.applyFilters();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== Search =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // SEARCH
                Expanded(
                  child: TextField(
                    controller: searchC,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        ref.read(adminAccountsProvider.notifier).setSearch(v),
                    onSubmitted: (_) =>
                        ref.read(adminAccountsProvider.notifier).applySearch(),
                  ),
                ),
                const SizedBox(width: 10),

                // TAMBAH AKUN
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => openTambahAkunDialog(context, ref),
                ),
              ],
            ),
          ),

          // ===== Filters (Role & Status) =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: st.roleFilter,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Semua'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'guru',
                                child: Text('Guru'),
                              ),
                              DropdownMenuItem(
                                value: 'kepsek',
                                child: Text('Kepsek'),
                              ),
                              DropdownMenuItem(
                                value: 'parent',
                                child: Text('Orang Tua'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              ref
                                  .read(adminAccountsProvider.notifier)
                                  .setRoleFilter(v);
                              ref
                                  .read(adminAccountsProvider.notifier)
                                  .applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: st.statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Semua'),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Aktif'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Nonaktif'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              ref
                                  .read(adminAccountsProvider.notifier)
                                  .setStatusFilter(v);
                              ref
                                  .read(adminAccountsProvider.notifier)
                                  .applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Filter'),
                        onPressed: () {
                          ref
                              .read(adminAccountsProvider.notifier)
                              .resetFilters();
                          ref
                              .read(adminAccountsProvider.notifier)
                              .applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (st.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(st.error!, style: const TextStyle(color: Colors.red)),
            ),

          // ===== List =====
          Expanded(
            child: st.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctrl.refresh(),
                    child: ListView.separated(
                      controller: _scrollC,
                      itemCount: st.items.length + 1,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i < st.items.length) {
                          final p = st.items[i];
                          return _AccountTile(
                            p: p,
                            onTap: () => openActions(context, ref, p),
                          );
                        }

                        if (st.loadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!st.hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('Sudah semua')),
                          );
                        }

                        return const SizedBox(height: 60);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void openActions(BuildContext context, WidgetRef ref, AkunModel p) {
    final rootContext = context; // context halaman

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final isActive = p.isActive ?? true;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit akun
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Edit akun'),
                trailing: const Text('>'),
                onTap: () async {
                  Navigator.pop(ctx); // tutup bottomsheet
                  await openEditAkunDialog(rootContext, ref, akun: p);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Ubah role'),
                trailing: const Text('>'),
                onTap: () async {
                  Navigator.pop(ctx); // tutup bottomsheet
                  final newRole = await _pickRole(rootContext, p.role);
                  if (newRole == null || newRole == p.role) return;

                  await ref
                      .read(adminAccountsProvider.notifier)
                      .updateRole(userId: p.id, role: newRole);
                  // SnackBar aman (optional)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!rootContext.mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(content: Text('Role diubah menjadi $newRole')),
                    );
                  });
                },
              ),

              // Toggle active
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isActive ? 'Nonaktifkan akun' : 'Aktifkan akun'),
                trailing: const Text('>'),
                onTap: () async {
                  Navigator.pop(ctx); // ✅ wajib pakai ctx, bukan context
                  await ref
                      .read(adminAccountsProvider.notifier)
                      .setActive(userId: p.id, isActive: !isActive);

                  // SnackBar aman (optional)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!rootContext.mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isActive ? 'Akun diaktifkan' : 'Akun dinonaktifkan',
                        ),
                      ),
                    );
                  });
                },
              ),

              // Hapus permanen (kalau kamu sudah punya)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hapus Permanen'),
                trailing: const Text('>'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(
                    context: rootContext,
                    builder: (_) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text(
                        'Akun akan dihapus TOTAL. Lanjutkan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(rootContext, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(rootContext, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );

                  if (ok == true) {
                    try {
                      await ref
                          .read(adminAccountsProvider.notifier)
                          .hardDeleteUser(p.id);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!rootContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          const SnackBar(
                            content: Text('Akun berhasil dihapus permanen'),
                          ),
                        );
                      });
                    } catch (e) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!rootContext.mounted) return;
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(content: Text('Gagal hapus: $e')),
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> openEditAkunDialog(
    BuildContext context,
    WidgetRef ref, {
    required AkunModel akun,
  }) async {
    final rootContext = context;

    final emailC = TextEditingController(text: akun.email ?? '');
    final namaC = TextEditingController(text: akun.namaLengkap ?? '');
    final hpC = TextEditingController(text: akun.noHp ?? '');
    final passC = TextEditingController();

    bool obscure = true;
    bool saving = false;

    Future<void> safeCloseDialog(BuildContext dialogCtx) async {
      // 1) tutup keyboard
      FocusManager.instance.primaryFocus?.unfocus();

      // 2) kasih waktu 1 frame
      await Future.delayed(const Duration(milliseconds: 30));

      // 3) pop dialog route (yang benar) -> pakai dialogCtx
      if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
        Navigator.of(dialogCtx).pop();
        return;
      }

      // 4) fallback: coba pop root navigator (kalau ada navigator bersarang)
      if (rootContext.mounted) {
        Navigator.of(rootContext, rootNavigator: true).maybePop();
      }
    }

    await showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => PopScope(
          canPop: !saving,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            if (saving) return;
            await safeCloseDialog(dialogCtx);
          },
          child: AlertDialog(
            title: const Text('Edit Akun'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    enabled: !saving,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: namaC,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    enabled: !saving,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hpC,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No HP',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    enabled: !saving,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passC,
                    obscureText: obscure,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: 'Password (opsional)',
                      helperText:
                          'Kosongkan jika tidak ingin mengubah password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: saving
                            ? null
                            : () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        await safeCloseDialog(dialogCtx);
                      },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final email = emailC.text.trim();
                        final nama = namaC.text.trim();
                        final hp = hpC.text.trim();
                        final pass = passC.text;

                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('Email tidak valid')),
                          );
                          return;
                        }
                        if (nama.isEmpty) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nama lengkap wajib diisi'),
                            ),
                          );
                          return;
                        }
                        if (hp.isEmpty) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('No HP wajib diisi')),
                          );
                          return;
                        }
                        if (pass.isNotEmpty && pass.length < 8) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Password minimal 8 karakter'),
                            ),
                          );
                          return;
                        }

                        setState(() => saving = true);

                        try {
                          await ref
                              .read(adminAccountsProvider.notifier)
                              .updateUserFull(
                                userId: akun.id,
                                email: email,
                                namaLengkap: nama,
                                noHp: hp,
                                password: pass.isEmpty ? null : pass,
                              );

                          await safeCloseDialog(dialogCtx);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text('Akun berhasil diperbarui'),
                              ),
                            );
                          });
                        } catch (e) {
                          setState(() => saving = false);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(content: Text('Gagal update: $e')),
                            );
                          });
                        }
                      },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );

    emailC.dispose();
    namaC.dispose();
    hpC.dispose();
    passC.dispose();
  }

  Future<void> openTambahAkunDialog(BuildContext context, WidgetRef ref) async {
    final rootContext = context;

    final emailC = TextEditingController();
    final namaC = TextEditingController();
    final hpC = TextEditingController();
    final passC = TextEditingController();

    String role = 'parent';
    bool obscure = true;
    bool saving = false;

    Future<void> safeCloseDialog(BuildContext dialogCtx) async {
      // tutup keyboard & lepas fokus dulu
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 30));

      if (dialogCtx.mounted && Navigator.of(dialogCtx).canPop()) {
        Navigator.of(dialogCtx).pop();
        return;
      }
      if (rootContext.mounted) {
        Navigator.of(rootContext, rootNavigator: true).maybePop();
      }
    }

    await showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => PopScope(
          canPop: !saving,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            if (saving) return;
            await safeCloseDialog(dialogCtx);
          },
          child: AlertDialog(
            title: const Text('Tambah Akun'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: namaC,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntlPhoneField(
                    initialCountryCode: 'ID', // tetap default +62
                    showCountryFlag: false, // ✅ bendera di field HILANG
                    showDropdownIcon:
                        true, // dropdown tetap ada untuk pilih kode
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      hintText: '81234567890',
                    ),
                    onChanged: (phone) {
                      hpC.text = phone.completeNumber;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passC,
                    obscureText: obscure,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: saving
                            ? null
                            : () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'guru', child: Text('Guru')),
                      DropdownMenuItem(value: 'kepsek', child: Text('Kepsek')),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('Orang Tua'),
                      ),
                    ],
                    onChanged: saving ? null : (v) => role = v ?? 'parent',
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () async => safeCloseDialog(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final email = emailC.text.trim();
                        final nama = namaC.text.trim();
                        final hp = hpC.text.trim();
                        final pass = passC.text;

                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('Email tidak valid')),
                          );
                          return;
                        }
                        if (nama.isEmpty) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Nama lengkap wajib diisi'),
                            ),
                          );
                          return;
                        }
                        if (hp.isEmpty) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('No HP wajib diisi')),
                          );
                          return;
                        }
                        if (pass.length < 8) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Password minimal 8 karakter'),
                            ),
                          );
                          return;
                        }

                        setState(() => saving = true);

                        try {
                          // ✅ panggil method createUser di provider kamu
                          await ref
                              .read(adminAccountsProvider.notifier)
                              .createUser(
                                email: email,
                                namaLengkap: nama,
                                noHp: hp,
                                password: pass,
                                role: role,
                              );

                          await safeCloseDialog(dialogCtx);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text('Akun berhasil dibuat'),
                              ),
                            );
                          });
                        } catch (e) {
                          setState(() => saving = false);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!rootContext.mounted) return;
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              SnackBar(content: Text('Gagal tambah akun: $e')),
                            );
                          });
                        }
                      },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );

    emailC.dispose();
    namaC.dispose();
    hpC.dispose();
    passC.dispose();
  }

  Future<String?> _pickRole(BuildContext context, String? current) {
    const roles = ['admin', 'guru', 'kepsek', 'parent'];
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in roles)
              RadioListTile<String>(
                value: r,
                groupValue: current ?? 'parent',
                title: Text(r),
                onChanged: (v) => Navigator.pop(context, v),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AkunModel p;
  final VoidCallback onTap;

  const _AccountTile({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = p.isActive ?? true;
    final status = isActive ? 'Aktif' : 'Nonaktif';

    final hasPhoto = p.fotoProfile != null && p.fotoProfile!.trim().isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: hasPhoto ? NetworkImage(p.fotoProfile!) : null,
        child: hasPhoto
            ? null
            : Icon(Icons.person, color: Colors.grey.shade600),
        onBackgroundImageError: hasPhoto
            ? (_, __) {

              }
            : null,
      ),
      title: Text(
        p.namaLengkap?.isNotEmpty == true ? p.namaLengkap! : '(Tanpa nama)',
      ),
      subtitle: Text(
        '${p.email ?? ''}\nHP: ${p.noHp ?? '-'}\nRole: ${p.role ?? 'parent'} • $status',
      ),
      isThreeLine: true,
      trailing: const Text('>'),
      onTap: onTap,
    );
  }
}
