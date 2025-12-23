import 'package:flutter/material.dart';
import 'messenger_key.dart';
import 'navigator_key.dart';

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
