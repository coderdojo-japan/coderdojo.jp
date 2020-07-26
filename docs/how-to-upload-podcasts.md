# DojoCast への Podcast 追加方法

DojoCast に新しい Podcast を追加する方法 (2020/07/26現在)

## 手順

1. **mp3 データを準備する**
   - 収録方法: [:tv: StreamYard で同時ライブ配信をカンタンに (実例解説付き)](https://note.com/yasulab/n/n9bfdd69a6b01)
2. ** `1.` で収録準備した mp3 をダウンロードし、SoundCloud にアップロードする**
   - アップロード先: [https://soundcloud.com/coderdojo-japan/](https://soundcloud.com/coderdojo-japan/)
3. **Rake タスクを実行し、Podcasts テーブルに SoundCloud のトラックデータを取り込む**

   ```
   $ bundle exec rake podcasts:upsert
   ```

4. **Markdown で Podcast のページを作成する**
   - エピソードの概要を書き、`public/podcasts/#{episode.id}.md` に配置します
5. **[localhost:3000/podcasts](http://localhost:3000/podcasts) から結果を確認する**
   - 問題なければ GitHub に push し、CI を通してデプロイされるのを待ちます :relieve:
6. **[coderdojo.jp/podcasts](https://coderdojo.jp/podcasts) にアクセスし、新規エピソードを確認する**
   - 上記の一連の作業が無事完了すると本番環境から新規エピソードが公開されます
   - [coderdojo.jp/podcasts.rss](https://coderdojo.jp/podcasts) も合わせて更新されるので、[Apple Podcasts](https://podcasts.apple.com/jp/podcast/dojocast/id1458122473?uo=10) への登録作業は不要です :smile: :ok_hand:

