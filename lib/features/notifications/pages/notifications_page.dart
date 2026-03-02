import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifikasi_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    String two(int v) => v.toString().padLeft(2, '0');

    if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus notifikasi?'),
        content: const Text('Notifikasi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return res == true;
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var item in items) {
          _selectedIds.add(item.idNotifikasi);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    final ok = await _confirmDelete(context);
    if (!ok) return;

    final svc = ref.read(notifikasiServiceProvider);

    for (final id in _selectedIds) {
      await svc.deleteNotifikasi(id);
    }

    ref.invalidate(notifikasiListProvider);
    ref.invalidate(notifikasiUnreadCountProvider);

    setState(() {
      _selectedIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi terpilih dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(notifikasiListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _selectedIds.clear());
                },
              )
            : null,
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} dipilih' : 'Notifikasi',
        ),
        actions: _isSelectionMode
            ? [
                Builder(
                  builder: (context) {
                    final asyncList = ref.watch(notifikasiListProvider);
                    return asyncList.when(
                      data: (items) => IconButton(
                        tooltip: _selectedIds.length == items.length
                            ? 'Batal pilih semua'
                            : 'Pilih semua',
                        icon: Icon(
                          _selectedIds.length == items.length
                              ? Icons.select_all
                              : Icons.checklist,
                        ),
                        onPressed: () => _selectAll(items),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Hapus terpilih',
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(notifikasiListProvider),
                ),
                IconButton(
                  tooltip: 'Tandai semua dibaca',
                  icon: const Icon(Icons.done_all),
                  onPressed: () async {
                    final svc = ref.read(notifikasiServiceProvider);
                    await svc.markAllRead();
                    ref.invalidate(notifikasiListProvider);
                    ref.invalidate(notifikasiUnreadCountProvider);
                  },
                ),
              ],
      ),
      body: asyncList.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = items[i];
              final isRead = n.isRead == 1;
              final isSelected = _selectedIds.contains(n.idNotifikasi);

              return Dismissible(
                key: ValueKey('notif-${n.idNotifikasi}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) async {
                  final svc = ref.read(notifikasiServiceProvider);
                  await svc.deleteNotifikasi(n.idNotifikasi);

                  ref.invalidate(notifikasiListProvider);
                  ref.invalidate(notifikasiUnreadCountProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifikasi dihapus')),
                    );
                  }
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onLongPress: () {
                    _toggleSelection(n.idNotifikasi);
                  },
                  onTap: () async {
                    if (_isSelectionMode) {
                      _toggleSelection(n.idNotifikasi);
                      return;
                    }

                    if (!isRead) {
                      final svc = ref.read(notifikasiServiceProvider);
                      await svc.markRead(n.idNotifikasi);

                      ref.invalidate(notifikasiListProvider);
                      ref.invalidate(notifikasiUnreadCountProvider);
                    }

                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(n.createdAt),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final ok = await _confirmDelete(
                                          context,
                                        );
                                        if (!ok) return;

                                        final svc = ref.read(
                                          notifikasiServiceProvider,
                                        );
                                        await svc.deleteNotifikasi(
                                          n.idNotifikasi,
                                        );

                                        ref.invalidate(notifikasiListProvider);
                                        ref.invalidate(
                                          notifikasiUnreadCountProvider,
                                        );

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Notifikasi dihapus',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Hapus'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Tutup'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.red
                            : (isRead
                                  ? Colors.black12
                                  : Colors.red.withOpacity(0.35)),
                      ),
                      color: isSelected
                          ? Colors.red.withOpacity(0.08)
                          : Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: Colors.red,
                            ),
                          ),
                        Stack(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isRead
                                    ? Colors.grey.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.12),
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: isRead ? Colors.grey : Colors.red,
                              ),
                            ),
                            if (!isRead)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(n.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final ok = await _confirmDelete(context);
                                    if (!ok) return;

                                    final svc = ref.read(
                                      notifikasiServiceProvider,
                                    );
                                    await svc.deleteNotifikasi(n.idNotifikasi);

                                    ref.invalidate(notifikasiListProvider);
                                    ref.invalidate(
                                      notifikasiUnreadCountProvider,
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Notifikasi dihapus'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Hapus'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
