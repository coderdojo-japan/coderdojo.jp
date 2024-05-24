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
        f.response :json, :content_type => /\bjson$/
        f.response :raise_error

        yield f if block_given?

        f.adapter  Faraday.default_adapter
      end
    end
  end
end
