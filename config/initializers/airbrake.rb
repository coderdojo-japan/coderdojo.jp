# Airbrake is an online tool that provides robust exception tracking in your
# Rails applications. In doing so, it allows you to easily review errors, tie an
# error to an individual piece of code, and trace the cause back to recent
# changes. Airbrake enables for easy categorization, searching, and
# prioritization of exceptions so that when errors occur, your team can quickly
# determine the root cause.
#
# Configuration details:
# https://github.com/airbrake/airbrake-ruby#configuration
if (project_id =  ENV['AIRBRAKE_PROJECT_ID']) &&
   project_key = (ENV['AIRBRAKE_PROJECT_KEY'] || ENV['AIRBRAKE_API_KEY'])
  Airbrake.configure do |c|
    # You must set both project_id & project_key. To find your project_id and
    # project_key navigate to your project's General Settings and copy the
    # values from the right sidebar.
    # https://github.com/airbrake/airbrake-ruby#project_id--project_key
    c.project_id  = project_id
    c.project_key = project_key

    # Configures the root directory of your project. Expects a String or a
    # Pathname, which represents the path to your project. Providing this option
    # helps us to filter out repetitive data from backtrace frames and link to
    # GitHub files from our dashboard.
    # https://github.com/airbrake/airbrake-ruby#root_directory
    c.root_directory = Rails.root

    # By default, Airbrake Ruby outputs to STDOUT. In Rails apps it makes sense
    # to use the Rails' logger.
    # https://github.com/airbrake/airbrake-ruby#logger
    c.logger = Airbrake::Rails.logger

    # Configures the environment the application is running in. Helps the
    # Airbrake dashboard to distinguish between exceptions occurring in
    # different environments.
    # NOTE: This option must be set in order to make the 'ignore_environments'
    # option work.
    # https://github.com/airbrake/airbrake-ruby#environment
    c.environment = Rails.env

    # Setting this option allows Airbrake to filter exceptions occurring in
    # unwanted environments such as :test.  NOTE: This option *does not* work if
    # you don't set the 'environment' option.
    # https://github.com/airbrake/airbrake-ruby#ignore_environments
    #
    # 手元で RAILS_ENV=production を実行したときも production 扱いになるため、
    # この一覧だけでは本番の通知に混ざる。Rails のアップグレード検証などで
    # production のブートを確認するのは定石なので、気をつけるのではなく
    # Heroku 上かどうかで機械的に切り分ける。DYNO は dyno 内でのみ設定される。
    # cf. https://devcenter.heroku.com/articles/dyno-metadata
    c.ignore_environments = %w[test staging development]
    c.ignore_environments << Rails.env if ENV['DYNO'].nil?

    # A list of parameters that should be filtered out of what is sent to
    # Airbrake. By default, all "password" attributes will have their contents
    # replaced.
    # https://github.com/airbrake/airbrake-ruby#blocklist_keys
    c.blocklist_keys = [/password/i, /authorization/i]

    # Alternatively, you can integrate with Rails' filter_parameters.
    # Read more: https://goo.gl/gqQ1xS
    # c.blocklist_keys = Rails.application.config.filter_parameters
  end

  # A filter that collects request body information. Enable it if you are sure you
  # don't send sensitive information to Airbrake in your body (such as passwords).
  # https://github.com/airbrake/airbrake#requestbodyfilter
  # Airbrake.add_filter(Airbrake::Rack::RequestBodyFilter.new)

  # Attaches thread & fiber local variables along with general thread information.
  # Airbrake.add_filter(Airbrake::Filters::ThreadFilter.new)

  # Attaches loaded dependencies to the notice object
  # (under context/versions/dependencies).
  # Airbrake.add_filter(Airbrake::Filters::DependencyFilter.new)

  # NOTE: SIGTERM is a standard signal sent by the hosting environment (e.g., Heroku)
  # when it needs to stop an existing Puma process, typically during a new deployment/restart.
  # Puma traps this signal, which surfaces as SignalException: SIGTERM in the stack trace from launcher.rb.
  # It does not necessarily indicate a bug in the application.
  # 例外は notice.stash[:exception] から取り出す。Airbrake::Notice に exception
  # メソッドは無く、呼ぶと通知のたびに NoMethodError になる。
  # cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1884
  Airbrake.add_filter do |notice|
    exception = notice.stash[:exception]
    if exception.is_a?(SignalException) && exception.message == 'SIGTERM'
      notice.ignore!
    end
  end

  # NOTE: 対応していない形式でのアクセスは、アプリの異常ではなくクライアント側の
  # 誤りなので通知しない。406 を返すのが正しい挙動であり、通知すると本物のエラーが
  # 埋もれる。実例は PHP の脆弱性スキャンによる /news.php へのアクセス。
  #
  # 同じ理由で無視してよい 4xx の例外は他にもあるが（RoutingError,
  # InvalidAuthenticityToken など）、まとめて無視すると本当に知りたい事象まで
  # 落としかねない。実際に通知が来たものから 1 つずつ足す。
  Airbrake.add_filter do |notice|
    notice.ignore! if notice.stash[:exception].is_a?(ActionController::UnknownFormat)
  end

  # If you want to convert your log messages to Airbrake errors, we offer an
  # integration with the Logger class from stdlib.
  # https://github.com/airbrake/airbrake#logger
  # Rails.logger = Airbrake::AirbrakeLogger.new(Rails.logger)
else
  Rails.logger.warn(
    "#{__FILE__}: Airbrake project id or project key is not set. " \
    "Skipping Airbrake configuration"
  )
end
