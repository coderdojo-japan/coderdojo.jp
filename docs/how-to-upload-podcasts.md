# DojoCast への Podcast 追加方法

DojoCast に新しい Podcast を追加する方法 (2019/05/01現在)

## 手順

1. **mp3 データを準備する**
   - _TODO: 音声の収録方法や必要な機材は別途記事としてまとめる_
2. **SoundCloud に `1.` で準備した mp3 をアップロードする**
   - アップロード先: [https://soundcloud.com/coderdojo-japan/](https://soundcloud.com/coderdojo-japan/)
3. **CoderDojo 側の `soundcloud_tracks T` に SoundCloud のトラックデータを取り込む**
   - 次の Rake タスクを実行し、SoundCloud に登録した CoderDojo Japan のトラックデータを CoderDojo の DB に取り込む。無事に取り込めると、追加した soundcloud_track レコード ID が表示されます

   ```
   $ bundle exec rake soundcloud_tracks:upsert
   ```

4. **`soundcloud_tracks` のレコード ID を使って、`x.md` を作成して配置する**
   - `3.` で確認した新規 soundcloud_track レコード ID を元に、 `public/podcasts/episode_template/index.md` のテンプレートを使って `<ID>.md` を作成し、 `public/podcasts/` に配置する。
5. **開発環境の [localhost:3000/podcasts](http://localhost:3000/podcasts) から結果を確認する**
   - 問題なければ GitHub に push し、CI を通してデプロイされるのを待つ
6. **デプロイされたら、本番環境で Rake タスクを実行する**
   - TODO: 現在はアクセス権限が必要。CI で毎回実行しても良さそう? 🤔💭
   - `$ heroku run bundle exec rake soundcloud_tracks:upsert`
7. **本番環境にアクセスして新規エピソードが表示されることを確認する**
   - 上記の一連の作業が無事完了すると、[https://coderdojo.jp/podcasts](https://coderdojo.jp/podcasts) から新規エピソードが公開されるようになります。
