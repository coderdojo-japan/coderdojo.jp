# Dumper (http://dumper.io) is an online tool that provides
# robust database backup in your Rails applications.
#
# For debug logging:
#
# Dumper::Agent.start(app_key: 'YOUR_APP_KEY', debug: true)
#
# For conditional start:
#
Dumper::Agent.start_if(:app_key => ENV['DUMPER_APP_KEY']) do
  Rails.env.production? # && dumper_enabled_host?
end
