import 'package:flutter/material.dart';

import '../navigation/messenger_key.dart';
import '../navigation/navigator_key.dart';

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/utils/phone_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/providers/profile_action_provider.dart';

void toast(String msg) {
  messengerKey.currentState?.hideCurrentSnackBar();
  messengerKey.currentState?.showSnackBar(SnackBar(content: Text(msg)));
}

Future<T?> showRootDialog<T>(Widget dialog) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return Future.value(null);

  return showDialog<T>(
    context: ctx,
    useRootNavigator: true,
    builder: (_) => dialog,
  );
}

void popRoot<T extends Object?>([T? result]) {
  navigatorKey.currentState?.pop<T>(result);
}

void pushNamedRoot(String route) {
  navigatorKey.currentState?.pushNamed(route);
}

void pushNamedAndRemoveUntilRoot(String route) {
  navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
}

Future<void> safeClosePage(BuildContext rootContext) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future.delayed(const Duration(milliseconds: 30));

  if (!rootContext.mounted) return;
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

String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

String buildPhone(String dialCode, String phone) =>
    digitsOnly('$dialCode$phone');

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
              final digitsOnly = (dialCode + controller.text.trim()).replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );

              Navigator.pop(ctx, digitsOnly);
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

Future<Uint8List> pickAndUploadAvatar(WidgetRef ref) async {
  final picker = ImagePicker();

  final x = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 100,
    maxWidth: 2048,
    maxHeight: 2048,
  );
  if (x == null) return Uint8List(0);

  final Uint8List originalBytes = await x.readAsBytes();
  final Uint8List resized = await FlutterImageCompress.compressWithList(
    originalBytes,
    minWidth: 512,
    minHeight: 512,
    quality: 80,
    format: CompressFormat.jpeg,
  );

  return resized;
}

Future<bool?> showInputUbahPassword({
  required BuildContext context,
  required String title,
  required WidgetRef ref,
}) {
  return showDialog<bool?>(
    context: context,
    builder: (ctx) {
      final oldC = TextEditingController();
      final newC = TextEditingController();

      bool saving = false;
      bool obscureOld = true;
      bool obscureNew = true;

      String? oldErrorText;
      String? newErrorText;

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
                  errorText: oldErrorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setLocal(() => obscureOld = !obscureOld),
                  ),
                ),
                onChanged: (_) {
                  if (oldErrorText != null) {
                    setLocal(() => oldErrorText = null);
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
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setLocal(() => obscureNew = !obscureNew),
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
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final oldPass = oldC.text.trim();
                      final newPass = newC.text.trim();

                      setLocal(() {
                        oldErrorText = null;
                        newErrorText = null;
                      });

                      if (oldPass.isEmpty) {
                        setLocal(
                          () => oldErrorText = 'Password lama wajib diisi',
                        );
                        return;
                      }
                      if (newPass.isEmpty) {
                        setLocal(
                          () => newErrorText = 'Password baru wajib diisi',
                        );
                        return;
                      }
                      if (newPass.length < 8) {
                        setLocal(() => newErrorText = 'Minimal 8 karakter');
                        return;
                      }

                      setLocal(() => saving = true);
                      try {
                        final success = await ref
                            .read(profileActionProvider.notifier)
                            .changePasswordWithVerify(
                              oldPassword: oldPass,
                              newPassword: newPass,
                            );

                        if (!ctx.mounted) return;

                        if (!success) {
                          setLocal(() => oldErrorText = 'Password lama salah');
                          return;
                        }

                        Navigator.pop(ctx, true);
                      } catch (e) {
                        if (!ctx.mounted) return;

                        final msg = e.toString().toLowerCase();

                        if (msg.contains('password lama salah')) {
                          setLocal(() => oldErrorText = 'Password lama salah');
                        } else {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      } finally {
                        if (ctx.mounted) setLocal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      );
    },
  );
}

enum AvatarAction { change, remove }

Future<AvatarAction?> showAvatarActionDialog(BuildContext context) {
  return showDialog<AvatarAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Foto Profile'),
      content: const Text('Pilih aksi:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, AvatarAction.remove),
          child: const Text('Hapus Foto'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, AvatarAction.change),
          child: const Text('Ganti Foto'),
        ),
      ],
    ),
  );
}
