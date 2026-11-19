SecureHeaders::Configuration.default do |config|
  src = %w(* 'unsafe-inline' 'unsafe-eval' data:
           *.google-analytics.com *.googleapis.com *.google.com *.gstatic.com
           *.facebook.net *.facebook.com *.twitter.com *.mailchimp.com
           *.hatena.ne.jp *.st-hatena.com *.line-scdn.net *.jsdelivr.net
           *.youtube.com)
  # スクリプトは、このサイトの JS と、本番のページで読み込みを確かめた外部の JS だけを許す（インラインの JS は止める）。
  # 違反は CspReportsController がログに残す。強制の前に同じ方針を Report-Only で動かし、
  # 残った報告が jQuery 1.12.4 の機能判定（IE でだけ結果が変わる onfocusin 属性）だけなのを確かめた。
  # 1 ファイルだけ読む配信元はそのファイルだけを許す。jsDelivr は誰でもパッケージを置けるので、ホストごとには許さない。
  # Facebook・X・はてな・Google は、そこから別の JS も読むのでホストを許す。www.googletagmanager.com の gtag/js は、
  # このアプリからは直接読まないが、本番では analytics.js を読んだ後にどのページでも読まれている。
  # www.googletagmanager.com と apis.google.com はホストごと許すので、JSONP などで迂回に使われうる。絞るのは別の課題とする。
  # Wufoo の form.js は static.wufoo.com へ転送される（CSP は転送先のホストも照らす）。
  # 検索の docsearch.js v2 は eval を使うので、'unsafe-eval' は残す（外せるのは docsearch v3 に移した後）
  policy = {
    preserve_schemes: true,

    default_src: src,
    script_src:  %w('self' 'unsafe-eval' 'report-sample'
                    https://kit.fontawesome.com/82f32b9df5.js
                    https://cdn.jsdelivr.net/npm/@twemoji/api@17.0.3/dist/twemoji.min.js
                    https://cdn.jsdelivr.net/npm/docsearch.js@2/dist/cdn/docsearch.min.js
                    https://www.googletagmanager.com
                    https://www.google-analytics.com/analytics.js
                    https://connect.facebook.net
                    https://platform.twitter.com
                    https://b.st-hatena.com
                    https://apis.google.com
                    https://www.wufoo.com/scripts/embed/form.js
                    https://static.wufoo.com/scripts/embed/form.js
                    https://speakerdeck.com/assets/embed.js),
    object_src:  %w('none'),
    base_uri:    %w('self'),
    report_uri:  ['/csp_report']
  }

  # development は Rails のエラー画面と web-console がインラインの JS を使うので、止めずに報告だけにする
  # （secure_headers は csp に report_only を書くと起動時に例外を出すので、強制を外して csp_report_only に渡す）
  if Rails.env.development?
    config.csp             = SecureHeaders::OPT_OUT
    config.csp_report_only = policy
  else
    config.csp = policy
  end
end
