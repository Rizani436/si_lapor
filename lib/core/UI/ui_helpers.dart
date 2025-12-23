import 'package:flutter/material.dart';

import '../navigation/messenger_key.dart';
import '../navigation/navigator_key.dart';

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

String buildPhone(String dialCode, String phone) => digitsOnly('$dialCode$phone');
