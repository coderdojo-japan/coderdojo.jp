module EventService
  class Client
    class_attribute :debug
    self.debug = false

    def initialize(endpoint, &block)
      @conn = connection_for(endpoint, &block)
    end

    def get(path, params)
      @conn.get(path, params).body
    end

    private

    def connection_for(endpoint)
      Faraday.new(endpoint) do |f|
        f.response :logger if self.class.debug
        f.response :json, :content_type => /\bjson$/
        f.response :raise_error

        yield f if block_given?

        f.adapter  Faraday.default_adapter
      end
      # TODO: According to the report by users, the following code fails to aggregate data for  /events page.
      # connpass は https://connpass.com/robots.txt を守らない場合は、アクセス制限を施すので、下記の sleep を入れるようにした https://connpass.com/about/api/
      #sleep 5 if endpoint.include?(EventService::Providers::Connpass::ENDPOINT)
    end
  end
end
