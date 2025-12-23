import 'package:intl_phone_field/countries.dart';

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
