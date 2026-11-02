SecureHeaders::Configuration.default do |config|
  src = %w(* 'unsafe-inline' 'unsafe-eval' data:
           *.google-analytics.com *.googleapis.com *.google.com *.gstatic.com
           *.facebook.net *.facebook.com *.twitter.com *.mailchimp.com
           *.hatena.ne.jp *.st-hatena.com *.line-scdn.net *.jsdelivr.net
           *.youtube.com)
  config.csp = {
    report_only:      false,
    preserve_schemes: true, # default: false

    default_src: src,
    script_src:  src,
    report_uri: ['/csp_report']
  }

  # 上の方針はどのスクリプトも通すので、XSS を止めない。スクリプトをこのサイトの JS と、本番のページで
  # 読み込みを確かめた外部の JS だけに絞った時に、何が止まるかを、止めずに報告だけして数える。
  # 報告は CspReportsController がログに残す。
  # 1 ファイルだけ読む配信元はそのファイルだけを許す。jsDelivr は誰でもパッケージを置けるので、ホストごとには許さない。
  # Facebook・X・はてな・Google は、そこから別の JS も読むのでホストを許す。www.googletagmanager.com の gtag/js は、
  # このアプリからは直接読まないが、本番では analytics.js を読んだ後にどのページでも読まれている。
  # Wufoo の form.js は static.wufoo.com へ転送される（CSP は転送先のホストも照らす）。
  # www.googletagmanager.com と apis.google.com は、強制する時に許し方を見直す（JSONP などで迂回に使われうる）
  config.csp_report_only = {
    report_only:      true,
    preserve_schemes: true,

    default_src: src,
    script_src:  %w('self' 'report-sample'
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
end
