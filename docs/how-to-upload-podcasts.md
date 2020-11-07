# DojoCast への Podcast 追加方法

DojoCast に新しい Podcast を追加する方法 (2020/07/26現在)

## 手順

1. **mp3 データを準備する**
   - :scroll: 収録方法: [:tv: StreamYard で同時ライブ配信をカンタンに (実例解説付き)](https://note.com/yasulab/n/n9bfdd69a6b01)
2. ** `1.` で収録準備した mp3 をダウンロードし、SoundCloud にアップロードする**
   - :notes: アップロード先: [https://soundcloud.com/coderdojo-japan/](https://soundcloud.com/coderdojo-japan/):
3. **Rake タスクを実行し、Podcasts テーブルに SoundCloud のトラックデータを取り込む**

   ```
   $ bundle exec rake podcasts:upsert
   ```

4. **Markdown で Podcast のページを作成する**
   - :memo: エピソードの概要を書き、`public/podcasts/#{episode.id}.md` に配置します
5. **[localhost:3000/podcasts](http://localhost:3000/podcasts) から結果を確認する**
   - :white_check_mark: 問題なければ GitHub に push し、CI を通してデプロイされるのを待ちます :relieved:
   - :rocket: デプロイ時に自動更新されるので `heroku run bundle exec rake podcasts:upsert` は **不要** です
6. **[coderdojo.jp/podcasts](https://coderdojo.jp/podcasts) にアクセスし、新規エピソードを確認する**
   - :radio: 一連の作業が完了すると本番環境から新規エピソードが公開されます ([coderdojo.jp/podcasts](https://coderdojo.jp/podcasts))
   - :apple: [coderdojo.jp/podcasts.rss](https://coderdojo.jp/podcasts) も合わせて更新されるため、[Apple Podcasts](https://podcasts.apple.com/jp/podcast/dojocast/id1458122473?uo=10) への **登録作業は不要** です :smile: :ok_hand:

