if Rails.env.development? && ENV.key?('ENABLE_RACK_PROFILER')
  require 'rack-mini-profiler'
  require 'flamegraph'
  require 'stackprof'
  require 'memory_profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
