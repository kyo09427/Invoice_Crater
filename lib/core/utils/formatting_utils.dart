import 'package:intl/intl.dart';

class FormattingUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');
  static final NumberFormat _currencyFormat = NumberFormat('#,###');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatCurrency(int amount) {
    return '${_currencyFormat.format(amount)} 円';
  }
}
