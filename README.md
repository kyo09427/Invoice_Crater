# Invoice Creator (精算書作成アプリ)

Flutterで作成された精算書作成・管理アプリケーションです。
日々の支払い情報を入力し、A4サイズのPDF精算書を簡単に生成・共有することができます。

## 機能

*   **精算書管理**: 複数の精算書を作成、保存、編集、削除できます。
*   **明細入力**: 支払日、支払い先、用途、決済手段、金額を詳細に入力可能です。
*   **PDF生成**: 入力されたデータを元に、A4縦フォーマットの精算書PDFを生成します。
*   **設定管理**: デフォルトの申請者名や、よく使う決済手段（Suica, PayPayなど）を登録・管理できます。
*   **データ保存**: データはアプリ内に自動的に保存されます（Hive使用）。

## 開発環境

*   Flutter (Stable channel)
*   Dart

## 使用パッケージ

*   `flutter_riverpod`: 状態管理
*   `hive`, `hive_flutter`: ローカルデータベース
*   `pdf`, `printing`: PDF生成とプレビュー
*   `intl`: 日付・数値フォーマット
*   `uuid`: ID生成

## セットアップ手順

1.  このリポジトリをクローンします。
    ```bash
    git clone https://github.com/kyo09427/Invoice_Crater.git
    cd Invoice_Crater
    ```

2.  依存パッケージをインストールします。
    ```bash
    flutter pub get
    ```

3.  コード生成を実行します（Hiveのアダプター生成のため）。
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  アプリを実行します。
    ```bash
    flutter run
    ```

## 作者

shoul (kyo09427)
