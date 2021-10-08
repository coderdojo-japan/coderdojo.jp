if Rails.env.development? && ENV.key?('ENABLE_RACK_PROFILER')
  require 'stackprof'
  require 'flamegraph'
  require 'memory_profiler'

  # Remove these comment if you like to profile performance.
  #require 'rack-mini-profiler'
  #Rack::MiniProfilerRails.initialize!(Rails.application)
end
