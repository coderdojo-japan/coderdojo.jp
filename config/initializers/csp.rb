SecureHeaders::Configuration.default do |config|
  config.csp = {
    report_only: Rails.env.production?, # default: false
    preserve_schemes: true,             # default: false.

    default_src: %w(* 'unsafe-inline' 'unsafe-eval'
*.dropboxusercontent.com
*.google-analytics.com *.googleapis.com *.google.com
*.facebook.net *.facebook.com
*.twitter.com
*.hatena.ne.jp *.st-hatena.com
*.slidesharecdn.com *.slideshare.net),
    report_uri: ["/csp_report?report_only=#{Rails.env.production?}"]
  }
end
