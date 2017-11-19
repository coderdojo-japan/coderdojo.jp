Rails.application.config.middleware.use Rack::Attack

Rack::Attack.blocklist('fail2ban pentesters') do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", :maxretry => 1, :findtime => 1.hour, :bantime => 24.hours) do
    req.path.include?('wp-login') ||
      req.params.values.include?('wp-login')
  end
end
