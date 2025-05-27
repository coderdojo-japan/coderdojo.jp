module EventService
  class Client
    class_attribute :debug
    self.debug = false

    def initialize(endpoint, proxy: nil, &block)
      @conn = connection_for(endpoint, proxy, &block)
    end

    def get(path, params)
      @conn.get(path, params).body
    end

    private

    def connection_for(endpoint, proxy)
      Faraday.new(endpoint, proxy: proxy) do |f|
        f.response :logger if self.class.debug
        
        # faraday標準のJSONパーサーを使用
        f.response :json, parser_options: { symbolize_names: true }
        
        # faraday標準のエラーハンドリングを使用
        f.response :raise_error, include_request: true

        yield f if block_given?

        f.adapter  Faraday.default_adapter
      end
    end
  end
end
