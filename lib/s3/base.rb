module S3
  class Base
    HOST = "s3.amazonaws.com"

    attr_accessor :access_key_id, :secret_access_key, :host, :use_ssl
    alias :use_ssl? :use_ssl

    def initialize(options)
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
      @use_ssl = options[:use_ssl] || false
      @host = options[:host] || HOST
    end

    def port
      use_ssl? ? 443 : 80
    end

    def send_request(request)
      http = Net::HTTP.new(host, port)
      http.set_debug_output(STDOUT)
      http.use_ssl = use_ssl?
      response = http.start do |http|
        host = http.address
        request['Date'] ||= Time.now.httpdate
        request["Authorization"] = S3::Signature.generate(:host => host,
                                                          :request => request,
                                                          :access_key_id => access_key_id,
                                                          :secret_access_key => secret_access_key)
        http.request(request)
      end

      # TODO: handle 40x responses

      response
    end
  end
end
