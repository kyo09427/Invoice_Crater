# Invoice Creator (精算書作成アプリ)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Flutterで作成された精算書作成・管理アプリケーションです。日々の支払い情報を入力し、A4サイズのPDF精算書を簡単に生成・共有することができます。

## 📋 目次

- [機能](#-機能)
- [スクリーンショット](#-スクリーンショット)
- [技術スタック](#-技術スタック)
- [プロジェクト構造](#-プロジェクト構造)
- [セットアップ](#-セットアップ)
- [使い方](#-使い方)
- [トラブルシューティング](#-トラブルシューティング)
- [開発ガイド](#-開発ガイド)
- [今後の拡張予定](#-今後の拡張予定)
- [ライセンス](#-ライセンス)
- [作者](#-作者)

## ✨ 機能

### コア機能

- **精算書管理**
  - 複数の精算書を作成、保存、編集、削除
  - 精算書一覧表示（作成日順にソート）
  - 各精算書のタイトル、作成日、合計金額の表示

- **明細入力**
  - 支払日、支払い先、用途、決済手段、金額を詳細に入力
  - 明細の追加、編集、削除（スワイプ削除対応）
  - リアルタイムで合計金額を自動計算

- **PDF生成**
  - A4縦フォーマットの精算書PDFを生成
  - 日本語フォント（Noto Sans JP）を使用
  - プレビュー機能付き
  - 共有・印刷機能

- **設定管理**
  - デフォルトの申請者名設定
  - よく使う決済手段の登録・管理
  - カスタム決済手段の追加・削除

- **データ永続化**
  - Hiveを使用したローカルデータベース
  - アプリ再起動後もデータを保持
  - 高速なデータアクセス

## 📱 スクリーンショット

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  精算書一覧      │  │  精算書編集      │  │  PDFプレビュー   │
│                 │  │                 │  │                 │
│  📄 11月度精算書 │  │  タイトル: ____  │  │                 │
│     2024/11/15  │  │  申請者: ______  │  │   精 算 書      │
│     ¥12,500     │  │  作成日: ______  │  │                 │
│                 │  │                 │  │  申請者: 山田太郎 │
│  📄 10月度精算書 │  │  ───────────────  │  │  作成日:2024/11 │
│     2024/10/20  │  │  11/01 〇〇商店  │  │                 │
│     ¥8,300      │  │        文房具     │  │  [明細テーブル]  │
│                 │  │        ¥1,200    │  │                 │
│  [+] 新規作成    │  │                 │  │  合計: ¥12,500  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 🛠 技術スタック

### フレームワーク・言語
- **Flutter**: 3.10+ (Stable channel)
- **Dart**: 3.10+

### 主要パッケージ

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| `flutter_riverpod` | ^2.6.1 | 状態管理 |
| `hive` | ^2.2.3 | ローカルデータベース |
| `hive_flutter` | ^1.1.0 | Hive Flutter統合 |
| `pdf` | ^3.11.3 | PDF生成 |
| `printing` | ^5.14.2 | PDFプレビュー・共有 |
| `intl` | ^0.19.0 | 日付・数値フォーマット |
| `uuid` | ^4.5.2 | ユニークID生成 |
| `path_provider` | ^2.1.5 | ファイルパス取得 |

### 開発ツール

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| `build_runner` | ^2.4.13 | コード生成 |
| `hive_generator` | ^2.0.1 | Hiveアダプター生成 |
| `flutter_lints` | ^5.0.0 | Lintルール |

## 📁 プロジェクト構造

```
lib/
├── main.dart                           # アプリエントリーポイント
├── application/                        # アプリケーション層
│   └── providers/                      # Riverpod プロバイダー
│       ├── core_providers.dart         # コアプロバイダー（Box等）
│       ├── app_settings_provider.dart  # 設定管理
│       ├── expense_sheet_list_provider.dart  # 精算書一覧
│       └── expense_sheet_provider.dart       # 個別精算書
├── data/                               # データ層
│   ├── models/                         # データモデル
│   │   ├── expense_sheet.dart          # 精算書モデル
│   │   ├── expense_sheet.g.dart        # Hiveアダプター（自動生成）
│   │   ├── expense_item.dart           # 明細モデル
│   │   ├── expense_item.g.dart         # Hiveアダプター（自動生成）
│   │   ├── app_settings.dart           # 設定モデル
│   │   └── app_settings.g.dart         # Hiveアダプター（自動生成）
│   └── datasources/                    # データソース
│       ├── hive_expense_sheet_datasource.dart  # 精算書CRUD
│       └── hive_app_settings_datasource.dart   # 設定CRUD
├── presentation/                       # プレゼンテーション層
│   ├── screens/                        # 画面
│   │   ├── expense_sheet_list_screen.dart      # 一覧画面
│   │   ├── expense_sheet_edit_screen.dart      # 編集画面
│   │   ├── expense_pdf_preview_screen.dart     # PDFプレビュー
│   │   └── settings_screen.dart                # 設定画面
│   └── widgets/                        # ウィジェット
│       └── expense_item_edit_bottom_sheet.dart # 明細入力UI
├── pdf/                                # PDF生成
│   └── expense_sheet_pdf_builder.dart  # PDF生成ロジック
└── core/                               # コア機能
    └── utils/
        └── formatting_utils.dart       # フォーマットユーティリティ
```

### アーキテクチャの特徴

- **レイヤー分離**: UI・ビジネスロジック・データアクセスを明確に分離
- **依存性の方向**: プレゼンテーション層 → アプリケーション層 → データ層
- **拡張性**: 新機能追加時に既存コードへの影響を最小限に
- **保守性**: 各層の責務が明確で、バグ修正が容易

## 🚀 セットアップ

### 前提条件

- Flutter SDK 3.10以上がインストールされていること
- Android Studio または VS Code（Flutter拡張機能付き）
- Android SDK（Android開発の場合）
- Xcode（iOS開発の場合、macOSのみ）

### インストール手順

1. **リポジトリをクローン**

   ```bash
   git clone https://github.com/kyo09427/Invoice_Crater.git
   cd Invoice_Crater
   ```

2. **依存パッケージをインストール**

   ```bash
   flutter pub get
   ```

3. **コード生成を実行**

   Hiveのアダプターを生成します：

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

   > **注意**: `*.g.dart` ファイルが自動生成されます。これらのファイルは編集しないでください。

4. **アプリを実行**

   ```bash
   # デバッグモードで実行
   flutter run

   # リリースモードで実行
   flutter run --release
   ```

### プラットフォーム別の追加設定

#### Android

- 最小SDK: Android 9 (API Level 28)
- `android/app/build.gradle` で設定済み

#### iOS

- 最小バージョン: iOS 13.0
- `ios/Podfile` で設定済み

#### Web / Desktop

- 現在は主にAndroid/iOSを想定していますが、基本的な動作は可能です

## 📖 使い方

### 1. 新規精算書の作成

1. ホーム画面（精算書一覧）で右下の「+」ボタンをタップ
2. 精算書編集画面が開きます
3. タイトルと申請者名を入力

### 2. 明細の追加

1. 編集画面下部の「明細を追加」ボタンをタップ
2. ボトムシートが表示されるので、以下を入力：
   - 支払日（日付ピッカーで選択）
   - 支払い先
   - 目的・用途
   - 決済手段（ドロップダウンから選択）
   - 金額
   - 備考（任意）
3. 「保存」をタップ

### 3. 明細の編集・削除

- **編集**: 明細行をタップ
- **削除**: 明細行を左にスワイプ

### 4. PDFの生成と共有

1. 編集画面右上のPDFアイコンをタップ
2. PDFプレビュー画面が表示されます
3. 共有ボタンで他のアプリに送信、または印刷

### 5. 設定のカスタマイズ

1. 一覧画面右上の歯車アイコンをタップ
2. 設定画面で以下を変更可能：
   - デフォルト申請者名
   - 決済手段の追加・削除

## 🔧 トラブルシューティング

### ビルドエラーが発生する場合

#### 1. 「*.g.dart ファイルが見つからない」エラー

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. PDF生成時のフォントエラー

**症状**: PDF生成時に「Font not found」エラー

**原因**: Noto Sans フォントのダウンロードに失敗

**解決方法**:
- インターネット接続を確認
- アプリを再起動
- 以下のコマンドでキャッシュをクリア：

```bash
flutter clean
rm -rf ~/.pub-cache
flutter pub get
```

#### 3. Hive関連のエラー

**症状**: `HiveError: Box is already open`

**解決方法**:
```bash
# アプリをアンインストール
# または
flutter clean
```

### よくある質問

**Q: データはどこに保存されますか？**

A: ローカルデバイスのアプリ専用ストレージに保存されます。アプリをアンインストールするとデータも削除されます。

**Q: データのバックアップはできますか？**

A: v1.0では未実装です。今後のバージョンで追加予定です。

**Q: PDFが文字化けします**

A: 日本語フォント（Noto Sans JP）が正しくロードされていない可能性があります。インターネット接続を確認してください。

**Q: 決済手段を追加できません**

A: 設定画面で「決済手段を追加」をタップし、名前を入力してください。空白のままでは追加できません。

## 👨‍💻 開発ガイド

### コードの規約

- **命名規則**: Dart公式ガイドラインに従う
- **ファイル名**: `snake_case` を使用
- **クラス名**: `PascalCase` を使用
- **変数名**: `camelCase` を使用

### 新機能の追加方法

#### 例: 新しいフィールドの追加

1. **モデルの更新**

   `lib/data/models/expense_item.dart` にフィールドを追加：

   ```dart
   @HiveField(7)
   final String? receiptImagePath;
   ```

2. **コード再生成**

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **UI更新**

   `lib/presentation/widgets/expense_item_edit_bottom_sheet.dart` に入力フィールドを追加

4. **テスト**

   動作確認を実施

### デバッグのヒント

- **Riverpod DevTools**: 状態管理のデバッグに使用
- **Hive Inspector**: データベースの内容確認に使用

```bash
# DevToolsを開く
flutter run --observatory-port=8888
```

### テストの実行

```bash
# 全テストを実行
flutter test

# 特定のテストを実行
flutter test test/widget_test.dart
```

## 🔮 今後の拡張予定

### v1.1（計画中）

- [ ] データのエクスポート/インポート機能
- [ ] CSVエクスポート
- [ ] ダークモード対応
- [ ] 多言語対応（英語）

### v1.2（計画中）

- [ ] レシート画像の添付機能
- [ ] プロジェクト/カテゴリー分類
- [ ] 月次レポート生成
- [ ] グラフ表示機能

### v2.0（構想）

- [ ] クラウド同期
- [ ] 複数デバイス対応
- [ ] チーム共有機能
- [ ] 承認ワークフロー

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 👤 作者

**shoul (kyo09427)**

- GitHub: [@kyo09427](https://github.com/kyo09427)
- Repository: [Invoice_Crater](https://github.com/kyo09427/Invoice_Crater)

## 🙏 謝辞

このプロジェクトは以下のオープンソースライブラリを使用しています：

- [Flutter](https://flutter.dev) - Googleによるクロスプラットフォームフレームワーク
- [Riverpod](https://riverpod.dev) - Remi Rousseletによる状態管理ライブラリ
- [Hive](https://docs.hivedb.dev) - 高速なローカルデータベース
- [pdf](https://pub.dev/packages/pdf) - PDF生成ライブラリ
- [printing](https://pub.dev/packages/printing) - PDF印刷・共有ライブラリ

---

## 📞 サポート

問題が発生した場合や機能リクエストがある場合は、[GitHubのIssues](https://github.com/kyo09427/Invoice_Crater/issues)でご報告ください。

## 🌟 貢献

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容を議論してください。

### 貢献の手順

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

---

**Built with ❤️ using Flutter**