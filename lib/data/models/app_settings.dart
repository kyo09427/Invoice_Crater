import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings {
  @HiveField(0)
  final String defaultApplicantName;

  @HiveField(1)
  final List<String> paymentMethodCandidates;

  AppSettings({
    required this.defaultApplicantName,
    required this.paymentMethodCandidates,
  });

  AppSettings copyWith({
    String? defaultApplicantName,
    List<String>? paymentMethodCandidates,
  }) {
    return AppSettings(
      defaultApplicantName: defaultApplicantName ?? this.defaultApplicantName,
      paymentMethodCandidates:
          paymentMethodCandidates ?? this.paymentMethodCandidates,
    );
  }

  factory AppSettings.initial() {
    return AppSettings(
      defaultApplicantName: '',
      paymentMethodCandidates: ['現金', 'Suica', 'd払い'],
    );
  }
}
