# Annicter

Annict APIを使用して、視聴中のアニメリストを取得・表示するRubyスクリプト

## 機能

- 今期視聴中のアニメを一覧表示
- 特定のシーズンを指定して視聴中アニメを表示
- アニメタイトル、放送情報、エピソード進捗などを表示

## インストール

```bash
bundle install
```

## 設定

Annictのアクセストークンが必要です。

1. [Annictの設定ページ](https://annict.com/settings/apps)でアクセストークンを取得
2. `.env`ファイルを作成して、トークンを設定:

```bash
cp .env.example .env
# .envファイルを編集して、ANNICT_ACCESS_TOKENを設定
```

または、環境変数として直接設定:

```bash
export ANNICT_ACCESS_TOKEN="your_token_here"
```

## 使い方

### 今期の視聴中アニメを表示

```bash
./bin/annicter
```

### 特定のシーズンの視聴中アニメを表示

```bash
./bin/annicter --season 2025-summer
```

シーズンは `YYYY-SEASON` の形式で指定します:
- `2025-winter` (冬期: 1-3月)
- `2025-spring` (春期: 4-6月)
- `2025-summer` (夏期: 7-9月)
- `2025-autumn` (秋期: 10-12月)

### ヘルプを表示

```bash
./bin/annicter --help
```

## オプション

```
Usage: annicter [options]

Options:
    -s, --season SEASON              Specify season in YYYY-SEASON format (e.g., 2025-summer, 2024-winter)
    -h, --help                       Show this help message
```

## 使用例

```bash
# 今期（2025年10月）の視聴中アニメを表示
$ ./bin/annicter
今期（2025-autumn）の視聴中アニメ:
==================================================

1. 葬送のフリーレン
   エピソード: 12話視聴済み / 28話
   放送: 金曜 23:00

2. 薬屋のひとりごと
   エピソード: 8話視聴済み / 24話
   放送: 土曜 25:00

合計: 2作品

# 2025年夏期の視聴中アニメを表示
$ ./bin/annicter --season 2025-summer
指定期（2025-summer）の視聴中アニメ:
==================================================

1. 無職転生II
   エピソード: 24話視聴済み / 24話
   放送: 日曜 24:00

合計: 1作品
```

## テスト

```bash
bundle exec rspec
```

## 開発

### テスト駆動開発（TDD）

このプロジェクトではTDDを採用しています:

1. 新機能の実装前に、まず失敗するテストを書く
2. テストを通すための最小限の実装を追加
3. コードをリファクタリング

### テストの実行

```bash
# すべてのテストを実行
bundle exec rspec

# 特定のファイルのテストを実行
bundle exec rspec spec/annicter/season_spec.rb

# カバレッジレポートを生成（自動で生成されます）
# coverage/index.html を開いて確認
```

## ライセンス

MIT License
