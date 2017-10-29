SecureHeaders::Configuration.default do |config|
  src = %w(* 'unsafe-inline' 'unsafe-eval' data:
           *.google-analytics.com *.googleapis.com *.google.com *.gstatic.com
           *.facebook.net *.facebook.com *.twitter.com
           *.hatena.ne.jp *.st-hatena.com
           *.slidesharecdn.com *.slideshare.net)
  config.csp = {
    report_only: Rails.env.production?, # default: false
    preserve_schemes: true,             # default: false.

    default_src: src,
    script_src:  src,
    report_uri: ["/csp_report?report_only=#{Rails.env.production?}"]
  }
end
