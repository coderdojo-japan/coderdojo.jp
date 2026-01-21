# PostgreSQL アップグレードガイド

**対象読者**: 本番環境（Heroku）へのアクセス権限がある管理者向けのドキュメントです。

---

## TL;DR（急いでいる方向け）

```bash
# 1. バージョン確認（管理者のみ: 本番環境確認）
heroku pg:info --app <app-name> | grep "PG Version"  # 本番: 例 17.6
psql --version                                        # ローカル: 例 16.9

# 2. アップグレード（クリーンインストール）
brew services stop postgresql@<古いバージョン>
brew uninstall postgresql@<古いバージョン>
brew install postgresql@<新しいバージョン>
brew services start postgresql@<新しいバージョン>
export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"

# 3. バージョン確認
psql --version  # 新しいバージョンになっていることを確認
```

**Note**: `brew uninstall` はパッケージのみ削除し、データディレクトリ (`/opt/homebrew/var/postgresql@<バージョン>`) は残ります。

---

## 背景

`heroku pg:pull` などで本番環境のデータベースをローカルにプルする際、**本番環境とローカル環境の PostgreSQL メジャーバージョンが一致している必要があります**。

バージョンが異なると、以下のようなエラーが発生します：

```
pg_dump: エラー: サーバーバージョンの不一致のため処理を中断します
pg_dump: 詳細: サーバーバージョン: X.Y、pg_dump バージョン: X.Y (Homebrew)
```

**例**（2026年1月時点）：
- 本番環境: PostgreSQL 17.6
- ローカル環境: PostgreSQL 16.9
- 結果: バージョン不一致でエラー

## 本番環境のバージョンを確認（管理者のみ）

まず、本番環境（Heroku）の PostgreSQL バージョンを確認します：

```bash
heroku pg:info --app coderdojo-japan | grep "PG Version"
```

## 現在のローカルバージョンを確認

```bash
psql --version
```

本番環境と同じメジャーバージョン（例: 両方とも 17.x）であれば問題ありません。異なる場合はアップグレードが必要です。

## アップグレード方法

どちらのオプションを選ぶべきか：
- **他のプロジェクトのデータベースも保持したい** → **オプション1（pg_upgrade）を推奨**
- **すべてのデータベースを本番から再プルできる** → オプション2（クリーンインストール）が簡単

### オプション1: データを保持してアップグレード（pg_upgrade 使用）

既存のローカル DB データを保持したい場合、PostgreSQL の `pg_upgrade` ツールを使用します。

**このオプションの利点**:
- すべてのデータベース（複数プロジェクト）を一度に移行できる
- データ損失のリスクがない
- 移行後すぐに作業を再開できる

**このオプションの欠点**:
- 手順が複雑（10ステップ）
- 互換性チェックやデータディレクトリの準備が必要

```bash
# 1. 新しいバージョンをインストール
brew install postgresql@<新しいバージョン>

# 2. 古いバージョンを停止
brew services stop postgresql@<古いバージョン>

# 3. 互換性チェック（安全確認、データは変更されない）
/opt/homebrew/opt/postgresql@<新しいバージョン>/bin/pg_upgrade \
  --old-datadir /opt/homebrew/var/postgresql@<古いバージョン> \
  --new-datadir /opt/homebrew/var/postgresql@<新しいバージョン> \
  --old-bindir /opt/homebrew/opt/postgresql@<古いバージョン>/bin \
  --new-bindir /opt/homebrew/opt/postgresql@<新しいバージョン>/bin \
  --check

# 4. データディレクトリの準備（brew install で自動初期化されるため）
mv /opt/homebrew/var/postgresql@<新しいバージョン> \
   /opt/homebrew/var/postgresql@<新しいバージョン>.initial
mkdir -p /opt/homebrew/var/postgresql@<新しいバージョン>
/opt/homebrew/opt/postgresql@<新しいバージョン>/bin/initdb \
  -D /opt/homebrew/var/postgresql@<新しいバージョン> \
  --locale=en_US.UTF-8 -E UTF-8

# 5. 実際のアップグレード実行（--check フラグなし）
/opt/homebrew/opt/postgresql@<新しいバージョン>/bin/pg_upgrade \
  --old-datadir /opt/homebrew/var/postgresql@<古いバージョン> \
  --new-datadir /opt/homebrew/var/postgresql@<新しいバージョン> \
  --old-bindir /opt/homebrew/opt/postgresql@<古いバージョン>/bin \
  --new-bindir /opt/homebrew/opt/postgresql@<新しいバージョン>/bin

# 6. 新しいバージョンを起動
brew services start postgresql@<新しいバージョン>

# 7. PATH を更新（新しいターミナルで有効化）
echo 'export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"' >> ~/.zshrc

# 8. 現在のセッションで PATH を更新
export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"

# 9. オプティマイザ統計を更新（pg_upgrade 推奨）
/opt/homebrew/opt/postgresql@<新しいバージョン>/bin/vacuumdb --all --analyze-in-stages

# 10. バージョン確認
psql --version
```

### オプション2: クリーンインストール（簡単）

**Note**: `brew uninstall` はパッケージのみ削除し、データディレクトリは残ります。データベースは保持されますが、新しいバージョンからはアクセスできません。

**手順**:

```bash
# 1. 古いバージョンを停止・アンインストール
brew services stop postgresql@<古いバージョン>
brew uninstall postgresql@<古いバージョン>

# 2. 新しいバージョンをインストール
brew install postgresql@<新しいバージョン>

# 3. 新しいバージョンを起動
brew services start postgresql@<新しいバージョン>

# 4. PATH を更新（新しいターミナルで有効化）
echo 'export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"' >> ~/.zshrc

# 5. 現在のセッションで PATH を更新
export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"

# 6. バージョン確認
psql --version
```

## アップグレード後の確認

```bash
# 1. PostgreSQL サービスの状態確認
brew services list | grep postgresql
# 期待される出力: postgresql@<新しいバージョン> started

# 2. 古いバージョンが動いていないか確認（重要）
# 複数バージョンが "started" の場合、古いバージョンに接続される可能性あり
# 古いバージョンが動いている場合: brew services stop postgresql@<古いバージョン>

# 3. psql のバージョン確認
psql --version

# 4. 実際に接続してサーバーバージョンを確認
psql -d postgres -c "SELECT version();"
# クライアント（psql）とサーバーのバージョンが一致しているか確認
```

## 本番データベースのプル（管理者のみ）

アップグレード後、本番環境（Heroku）のデータベースをローカルにプルできます：

```bash
# ローカル DB を削除してから本番データをプル
./drop_db_and_fetch_from_heroku.sh

# マイグレーションを実行（必要に応じて）
bundle exec rails db:migrate

# ローカルサーバーを起動して確認
bundle exec rails server
```

## トラブルシューティング

### 複数バージョンが起動していて接続先が間違う

**症状**: `psql --version` は新しいバージョンを表示するが、`SELECT version()` で古いバージョンに接続される

**原因**: 複数の PostgreSQL サービスが同時に起動している

**解決方法**:
```bash
# すべての PostgreSQL サービスの状態を確認
brew services list | grep postgresql

# 古いバージョンをすべて停止
brew services stop postgresql@<古いバージョン>

# 新しいバージョンを再起動
brew services restart postgresql@<新しいバージョン>

# 接続先を確認
psql -d postgres -c "SELECT version();"
```

### heroku pg:pull でバージョン不一致エラーが出る

**症状**: `psql --version` は正しいが、`heroku pg:pull` で「pg_dump バージョン: <古い>」エラー

**原因**: Heroku CLI が古い pg_dump を使用している（PATH を無視）

**解決方法**:
```bash
# 1. ターミナルを完全に再起動（PATH を完全にリロード）
# または
# 2. 新しいターミナルウィンドウを開く

# 3. それでもダメな場合、Heroku CLI を再インストール
brew reinstall heroku/brew/heroku
```

### PATH が正しく設定されていない

**症状**: `psql --version` が古いバージョンを表示

**解決方法**:
```bash
# 現在の psql のパスを確認
which psql
# 期待されるパス: /opt/homebrew/opt/postgresql@<新しいバージョン>/bin/psql

# 現在のセッションで PATH を更新
export PATH="/opt/homebrew/opt/postgresql@<新しいバージョン>/bin:$PATH"

# 新しいターミナルで確認
psql --version
```

### PostgreSQL サービスが起動しない

```bash
# サービスの状態を確認
brew services list | grep postgresql

# エラー状態の場合、ログを確認
tail -f /opt/homebrew/var/log/postgresql@<バージョン>.log

# サービスを再起動
brew services restart postgresql@<バージョン>

# データディレクトリの権限を確認
ls -la /opt/homebrew/var/postgresql@<バージョン>
```

## 古いバージョンのクリーンアップについて

**推奨**: 古いバージョンは残しておく。

**理由**:
- 他のプロジェクトで使用している可能性がある
- 誤って削除すると、データベースが完全に失われる
- ディスク容量は後で整理できる


## 参考情報

- Heroku の PostgreSQL バージョン: https://devcenter.heroku.com/articles/heroku-postgresql#version-support-and-legacy-infrastructure
- Homebrew PostgreSQL: https://formulae.brew.sh/formula/postgresql
- PostgreSQL バージョン一覧: https://www.postgresql.org/support/versioning/
- pg_upgrade 公式ドキュメント: https://www.postgresql.org/docs/current/pgupgrade.html

## 更新履歴

- 2026-01-21: 初版作成、pg_upgrade の正しい手順を追加、実際の経験に基づく改善
