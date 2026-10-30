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

  # 上の方針はどのスクリプトも通すので、XSS を止めない。スクリプトをこのサイトの JS だけに絞った時に
  # 何が止まるかを、止めずに報告だけして数える。報告は CspReportsController がログに残す
  config.csp_report_only = {
    report_only:      true,
    preserve_schemes: true,

    default_src: src,
    script_src:  %w('self' 'report-sample'),
    object_src:  %w('none'),
    base_uri:    %w('self'),
    report_uri:  ['/csp_report']
  }
end
