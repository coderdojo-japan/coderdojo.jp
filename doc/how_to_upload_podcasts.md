# DojoCast への Podcast 追加方法

DojoCast に新しい Podcast を追加する方法 (2020/07/26現在)

## 手順

1. **mp3 データを準備する**
   - :scroll: 収録方法: [:tv: StreamYard で同時ライブ配信をカンタンに (実例解説付き)](https://note.com/yasulab/n/n9bfdd69a6b01)
   - :cloud: Zoom の Cloud Recording でも代用可 ([自動で動画目次も生成](https://i.gyazo.com/59dfe69da2302566781575eaf56d0d01.jpg)されます)
2. **収録した音声ファイルを編集し、以下の Spotify for Creators にアップロードする**
   - :notes: アップロード先: [https://creators.spotify.com/pod/dashboard/home](https://creators.spotify.com/pod/dashboard/home)
3. **Rake タスクを実行し、Podcasts テーブルに Anchor.fm のトラックデータを取り込む**

   ```
   bundle exec rake podcasts:upsert
   ```

4. **Markdown で Podcast のページを作成する**
   - :memo: エピソードの概要を書き、`public/podcasts/#{episode.id}.md` に配置します
5. **[localhost:3000/podcasts](http://localhost:3000/podcasts) から結果を確認する**
   - :white_check_mark: 問題なければ GitHub に push し、CI を通してデプロイされるのを待ちます :relieved:
   - :rocket: デプロイ時に自動更新されるので `heroku run bundle exec rake podcasts:upsert` は **不要** です
6. **[coderdojo.jp/podcasts](https://coderdojo.jp/podcasts) にアクセスし、新規エピソードを確認する**
   - :radio: 一連の作業が完了すると本番環境から新規エピソードが公開されます ([coderdojo.jp/podcasts](https://coderdojo.jp/podcasts))
   - :apple: [coderdojo.jp/podcasts.rss](https://coderdojo.jp/podcasts) も合わせて更新されるため、[Apple Podcasts](https://podcasts.apple.com/jp/podcast/dojocast/id1458122473?uo=10) への **登録作業は不要** です :smile: :ok_hand:

