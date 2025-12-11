/// アプリ全体で使用する定数を集約
class AppConstants {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  AppConstants._();

  // ルーティング
  static const String routeHome = '/';
  static const String routeSettings = '/settings';
  static const String routeSheetEdit = '/sheet';
  static const String routePdfPreview = '/pdf_preview';

  // UI関連
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 24.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 40.0;

  // カラー
  static const int primaryColorValue = 0xFF137FEC;
  static const int backgroundLightValue = 0xFFFDFCFF;
  static const int backgroundDarkValue = 0xFF1A1C1E;
  
  // PDF設定
  static const double pdfMarginMm = 25.0;
  static const double pdfTitleFontSize = 24.0;
  static const double pdfBodyFontSize = 12.0;
  static const double pdfTotalFontSize = 18.0;

  // バリデーション
  static const int maxTitleLength = 100;
  static const int maxApplicantNameLength = 50;
  static const int maxPayeeLength = 100;
  static const int maxPurposeLength = 200;
  static const int maxNoteLength = 500;
  static const int minAmount = 1;
  static const int maxAmount = 999999999;

  // メッセージ
  static const String msgNoSheets = '精算書がありません。\n右下のボタンから作成してください。';
  static const String msgSheetNotFound = '精算書が見つかりません';
  static const String msgConfirmDelete = 'この明細を削除しますか？';
  static const String msgEmptyTitle = 'タイトルを入力してください';
  static const String msgEmptyApplicant = '申請者名を入力してください';
  static const String msgNoItemsForPdf = '明細が1件以上必要です';
  static const String msgPdfGenerationError = 'PDF生成中にエラーが発生しました';
  
  // デフォルト値
  static const String defaultSheetTitle = '未命名の精算書';
  static const List<String> defaultPaymentMethods = ['現金', 'Suica', 'd払い'];
}

/// UI色定義
class AppColors {
  AppColors._();

  static const int primaryColor = AppConstants.primaryColorValue;
  static const int backgroundLight = AppConstants.backgroundLightValue;
  static const int backgroundDark = AppConstants.backgroundDarkValue;
  static const int surfaceLight = 0xFFFDFCFF;
  static const int surfaceDark = 0xFF1A1C1E;
  static const int surfaceVariantLight = 0xFFE1E2EC;
  static const int surfaceVariantDark = 0xFF44474F;
  static const int outlineLight = 0xFF74777F;
  static const int outlineDark = 0xFF8E9099;
  static const int textPrimaryLight = 0xFF1A1C1E;
  static const int textPrimaryDark = 0xFFE2E2E6;
  static const int textSecondaryLight = 0xFF44474F;
  static const int textSecondaryDark = 0xFFC4C6D0;
}