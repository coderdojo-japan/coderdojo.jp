# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application

require 'rack/rewrite'
use Rack::Rewrite do
  r301 %r{.*}, 'http://coderdojo.jp$&', :if => Proc.new {|rack_env|
    rack_env['SERVER_NAME'] == 'www.coderdojo.jp'
  }
end
