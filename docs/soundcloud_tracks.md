# DojoCast への Podcast 追加方法

DojoCast に新しい Podcast を追加する方法 (2019/05/01現在)

## 手順

### (1) mp3 データを準備する

### (2) SoundCloud に (1) で準備した mp3 を Upload する

使用するアカウントは CoderDojo Japan

### (3) CoderDojo 側の soundcloud_tracks T に SoundCloud のトラックデータを取り込む

以下の rake タスクを実行し、SoundCloud に登録した CoderDojoJapan のトラックデータを CoderDojo の DB に取り込む。

```
rake soundcloud_tracks:upsert
```

実行結果として、追加した soundcloud_track レコードの ID を表示する。

### (4) soundcloud_tracks のレコードの ID を使って、`x.md` を作成して配置する

(3) で確認した新規 soundcloud_track レコードの ID を元に、
`public/podcasts/episode_template/index.md` のテンプレートを使用して `<ID>.md` を作成して
`public/podcasts/` に配置する。

### (5) https://coderdojo.jp/podcasts に追加した Podcast が表示される
