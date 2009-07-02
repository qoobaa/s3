module S3
  class Connection
    attr_accessor :access_key_id, :secret_access_key, :use_ssl, :timeout, :debug
    alias :use_ssl? :use_ssl

    def initialize(options = {})
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
      @use_ssl = options[:use_ssl] || false
      @debug = options[:debug]
      @timeout = options[:timeout]
    end

    def request(method, options)
      host = options[:host] || HOST
      path = options[:path] or raise ArgumentError.new("no path given")
      body = options[:body]
      params = options[:params]
      headers = options[:headers]

      if params
        params = params.is_a?(String) ? params : self.class.parse_params(params)
        path << "?#{params}"
      end

      path = URI.escape(path)
      request = request_class(method).new(path)

      headers = self.class.parse_headers(headers)
      headers.each do |key, value|
        request[key] = value
      end

      request.body = body

      send_request(host, request)
    end

    def self.parse_params(params)
      interesting_keys = [:max_keys, :prefix, :marker, :delimiter, :location]

      result = []
      params.each do |key, value|
        if interesting_keys.include?(key)
          parsed_key = key.to_s.gsub("_", "-")
          case value
          when nil
            result << parsed_key
          else
            result << "#{parsed_key}=#{value}"
          end
        end
      end
      result.join("&")
    end

    def self.parse_headers(headers)
      interesting_keys = [:content_type, :x_amz_acl, :range,
                          :if_modified_since, :if_unmodified_since,
                          :if_match, :if_none_match,
                          :content_disposition, :content_encoding]
      parsed_headers = {}
      if headers
        headers.each do |key, value|
          if interesting_keys.include?(key)
            parsed_key = key.to_s.gsub("_", "-")
            parsed_value = value
            case value
            when Range
              parsed_value = "bytes=#{value.first}-#{value.last}"
            end
            parsed_headers[parsed_key] = parsed_value
          end
        end
      end
      parsed_headers
    end

    private

    def request_class(method)
      case method
      when :get
        request_class = Net::HTTP::Get
      when :put
        request_class = Net::HTTP::Put
      when :delete
        request_class = Net::HTTP::Delete
      end
    end

    def port
      use_ssl? ? 443 : 80
    end

    def http(host)
      http = Net::HTTP.new(host, port)
      http.set_debug_output(STDOUT) if @debug
      http.use_ssl = @use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @use_ssl
      http.read_timeout = @timeout if @timeout
      http
    end

    def send_request(host, request)
      response = http(host).start do |http|
        host = http.address

        request['Date'] ||= Time.now.httpdate

        if request.body
          request["Content-Type"] ||= "application/octet-stream"
          request["Content-MD5"] = Base64.encode64(Digest::MD5.digest(request.body)).chomp
        end

        request["Authorization"] = S3::Signature.generate(:host => host,
                                                          :request => request,
                                                          :access_key_id => access_key_id,
                                                          :secret_access_key => secret_access_key)
        http.request(request)
      end

      handle_response(response)
    end

    def handle_response(response)
      case response.code.to_i
      when 200...300
        response
      when 300...600
        if response.body.nil?
          raise S3::Error::ResponseError.new(nil, response)
        else
          xml = XmlSimple.xml_in(response.body)
          message = xml["Message"].first
          code = xml["Code"].first
          raise S3::Error::ResponseError.exception(code).new(message, response)
        end
      else
        raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
      end
      response
    end

  end
end
