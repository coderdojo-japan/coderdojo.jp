# 道場の再アクティブ化手順

一度非アクティブになった道場が活動を再開する場合の手順をまとめています。

## TL;DR（忙しい人向け）

1. 再開のアナウンス（SNS投稿など）を確認し、非活動期間の終了日を特定する
2. `db/dojos.yml` で該当する道場を見つける
3. `inactivated_at` フィールドを削除する
4. `note` フィールドに非活動期間を記録する（推奨）
5. `bundle exec rails dojos:update_db_by_yaml` を実行してDBに反映
6. アクティブな道場数を確認して、正常に再アクティブ化されたことを確認
7. Pull Request を送る

[&raquo; 再アクティブ化の対応例を見る](https://github.com/coderdojo-japan/coderdojo.jp/pull/1794)

<br>

## 詳細な手順

### 1. 現在のアクティブな道場数を確認

再アクティブ化前のベースラインとして、現在のアクティブな道場数を記録します。

```bash
$ rails runner "puts \"アクティブな道場数: #{Dojo.active.sum(:counter)}\""
```

### 2. db/dojos.yml を編集

該当する道場のエントリを見つけて、以下のように編集します。

**編集前:**
```yaml
- id: 16
  order: '131156'
  created_at: '2016-09-09'
  inactivated_at: '2022-03-16'
  name: すぎなみ
  prefecture_id: 13
  url: https://coderdojo-suginami.github.io/
  logo: "/img/dojos/suginami.webp"
  description: 杉並区で毎月開催
  tags:
  - Scratch
  - Ruby
```

**編集後:**
```yaml
- id: 16
  order: '131156'
  created_at: '2016-09-09'
  note: "非活動期間: 2022-03-16〜2026-01-10"
  name: すぎなみ
  prefecture_id: 13
  url: https://coderdojo-suginami.github.io/
  logo: "/img/dojos/suginami.webp"
  description: 杉並区で毎月開催
  tags:
  - Scratch
  - Ruby
```

**変更のポイント:**
- `inactivated_at` 行を削除する
- `note` フィールドに非活動期間（開始日〜終了日）を記録する
  - 終了日は再開アナウンスの前日が適切です
  - 例：2026年1月11日に再開アナウンスがあった場合、終了日は 2026-01-10

### 3. データベースに反映

YAML ファイルの変更をデータベースに反映させます。

```bash
$ bundle exec rails dojos:update_db_by_yaml
```

### 4. 再アクティブ化を確認

道場が正常に再アクティブ化されたことを確認します。

```bash
$ rails runner "puts \"アクティブな道場数: #{Dojo.active.sum(:counter)}\"; dojo = Dojo.find(16); puts \"active?: #{dojo.active?}\"; puts \"inactivated_at: #{dojo.inactivated_at.inspect}\""
```

期待される結果:
- アクティブな道場数が1増加している
- `active?: true`
- `inactivated_at: nil`

### 5. Pull Request を作成

ブランチを作成してコミットし、Pull Request を送ります。

```bash
$ git checkout -b reactivate-coderdojo-xxx
$ git add db/dojos.yml
$ git commit -m "CoderDojo XXXを再アクティブ化"
$ git push origin reactivate-coderdojo-xxx
$ gh pr create --title "CoderDojo XXXを再アクティブ化" --body "..."
```

**コミットメッセージとPR説明の例:**

```
CoderDojo すぎなみを再アクティブ化

2026年1月11日のアナウンス (https://x.com/kdmsnr/status/2010287029649895753) に基づき、
CoderDojo すぎなみを再アクティブ化しました。

変更内容:
- inactivated_at フィールドを削除
- note フィールドに非活動期間 (2022-03-16〜2026-01-10) を記録

結果:
- アクティブな道場数: 202 → 203
```

<br>

## 注意事項

- **YAMLファイルがマスターデータ**: データベースを直接編集しても、`rails dojos:update_db_by_yaml` 実行時に YAML の内容で上書きされます
- **非活動期間の記録**: `note` フィールドに履歴を残すことで、将来の分析や参照に役立ちます
- **counter パラメータ**: ページに表示される道場数は `counter` の合計値です。`counter` が設定されていない道場はデフォルト値の1が使われます

<br>

## 本番環境への反映方法

dojos.yml の更新を GitHub に push すると、次の手順で本番環境に反映されます。

1. GitHub の更新を [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) が検知します
1. [GitHub Actions](https://github.com/coderdojo-japan/coderdojo.jp/actions) で各種テストが実行されます
   - １つ以上のテストが失敗すると本番環境には反映されません
1. すべてのテストが成功すると、本番環境へのデプロイが始まります

したがって、Pull Request 時点で CI がパスしていれば、基本的にはマージ後に本番環境 (coderdojo.jp) に反映されます。
