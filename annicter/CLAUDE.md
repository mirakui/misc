# Annicter - 今期視聴中アニメリスト出力スクリプト設計書

## 概要
Annict APIを使用して、現在視聴中のアニメ（今期アニメ）のリストを取得・表示するRubyスクリプト

## 目的
- Annictに登録している今期の視聴中アニメを一覧表示
- コマンドラインから簡単に確認できるツールの提供

## 技術スタック
- **言語**: Ruby 3.x
- **HTTP通信**: Net::HTTP（標準ライブラリ）または Faraday gem
- **JSON処理**: JSON（標準ライブラリ）
- **環境変数管理**: dotenv gem（APIトークン管理用）

## API仕様
### 基本情報
- **ベースURL**: `https://api.annict.com/v1`
- **認証方式**: Bearer Token認証
- **レスポンス形式**: JSON

### 使用予定のエンドポイント
1. **GET /v1/me/statuses**
   - ユーザーの視聴ステータスを取得
   - パラメータ: `work_id`, `kind`（watching）

2. **GET /v1/works**
   - アニメ作品情報を取得
   - パラメータ: `filter_season`（今期指定）

3. **GET /v1/me/works**
   - 認証ユーザーが登録している作品を取得
   - パラメータ: `filter_status`（watching）, `filter_season`

## 機能要件
1. **認証機能**
   - Annictの個人用アクセストークンを使用
   - 環境変数からトークンを読み込み

2. **今期の判定**
   - 現在の年月から今期（冬・春・夏・秋）を自動判定
   - 例: 2024年1月 → 2024-winter

3. **視聴中アニメの取得**
   - ステータスが「視聴中」の作品のみをフィルタリング
   - 今期の作品のみを対象

4. **表示機能**
   - アニメタイトル（日本語）
   - 放送情報（曜日・時間）
   - エピソード進捗（視聴済み話数/総話数）
   - 評価情報（あれば）

## ディレクトリ構成
```
annicter/
├── .env.example        # 環境変数のサンプル
├── .gitignore         # Git除外設定
├── Gemfile            # 依存関係定義
├── Gemfile.lock       # 依存関係ロック
├── README.md          # プロジェクト説明
├── DESIGN.md          # 本設計書
├── bin/
│   └── annicter       # 実行可能スクリプト
└── lib/
    ├── annicter.rb    # メインライブラリ
    ├── annicter/
    │   ├── client.rb  # API クライアント
    │   ├── season.rb  # シーズン判定ロジック
    │   └── work.rb    # 作品データモデル
    └── annicter/version.rb
```

## クラス設計

### Annicter::Client
- Annict APIとの通信を担当
- 認証処理
- HTTPリクエストの送信とエラーハンドリング

### Annicter::Season
- 現在の日付から今期を判定
- シーズン文字列のフォーマット（例: "2024-winter"）

### Annicter::Work
- アニメ作品のデータモデル
- 表示用のフォーマット処理

## 実装フロー
1. 環境変数からAPIトークンを読み込み
2. 現在の日付から今期を判定
3. Annict APIから視聴中かつ今期のアニメリストを取得
4. 取得したデータを整形して表示

## エラーハンドリング
- APIトークンが設定されていない場合のエラー
- ネットワークエラー
- API制限エラー（429 Too Many Requests）
- 認証エラー（401 Unauthorized）

## 拡張性考慮
- 他の期のアニメも表示できるようなオプション追加
- 出力フォーマットの選択（JSON, CSV等）
- 視聴進捗の更新機能

## セキュリティ考慮
- APIトークンは環境変数で管理
- .envファイルは.gitignoreに追加
- トークンをログに出力しない

## 開発手法
### TDD（テスト駆動開発）の採用
本プロジェクトではTDDを採用し、以下の手順で開発を進めます：

1. **Red Phase**: 失敗するテストを先に書く
2. **Green Phase**: テストを通すための最小限の実装
3. **Refactor Phase**: コードの品質を改善

### 実装順序
1. Annicter::Season（シーズン判定ロジック）
2. Annicter::Work（作品データモデル）
3. Annicter::Client（APIクライアント）
4. メインスクリプト統合

各クラスごとに：
- 先に完全なテストスイートを作成
- テストが全て失敗することを確認
- 一つずつテストを通す実装を追加
- 全テスト通過後にリファクタリング

## テスト方針
- RSpecを使用した単体テスト
- VCRまたはWebMockを使用したAPI通信のモック
- 各クラスの責務に応じたテストケース作成
- カバレッジ100%を目標
- 境界値テストとエラーケースを重視

## 開発TODO

### コマンドライン引数でシーズン指定機能の追加
- [x] Write failing tests for command-line season option parsing
- [x] Implement OptionParser for --season argument in bin/annicter
- [x] Update main() to pass season argument to client
- [x] Add season validation using Season.valid?
- [x] Run RSpec tests to verify functionality
- [x] Update README.md with usage examples for --season option