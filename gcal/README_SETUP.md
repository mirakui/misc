# Google Calendar API セットアップ手順

## 1. Google Cloud Console でのセットアップ

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. 新しいプロジェクトを作成（または既存のプロジェクトを選択）
3. 「APIとサービス」→「ライブラリ」から「Google Calendar API」を検索して有効化
4. 「APIとサービス」→「認証情報」→「認証情報を作成」→「OAuth クライアント ID」
5. アプリケーションの種類は「デスクトップ」を選択
6. 作成された認証情報をダウンロードし、`credentials.json` として保存

## 2. 依存関係のインストール

```bash
pip install -r requirements.txt
```

## 3. テスト実行

```bash
python tmp/test_gcal_auth.py
```

初回実行時はブラウザが開き、Googleアカウントでの認証が求められます。
認証後、`token.json` が作成され、以降は自動的に認証されます。