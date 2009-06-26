module S3
  class Base
    HOST = "s3.amazonaws.com"

    attr_accessor :access_key_id, :secret_access_key, :host, :use_ssl, :path_prefix
    alias :use_ssl? :use_ssl

    protected

    def initialize(options)
      @access_key_id = options[:access_key_id]
      @secret_access_key = options[:secret_access_key]
      @use_ssl = options[:use_ssl] || false
      @host = options[:host] || HOST
      @path_prefix = options[:path_prefix] || ""
    end

    def port
      use_ssl? ? 443 : 80
    end

    def get(path, params = {})
      request = prepare_request(:get, path, nil, params)
      send_request(request)
    end

    def head(path)
      request = prepare_request(:get, path)
      send_request(request)
    end

    def put(path, body, headers = {})
      request = prepare_request(:put, path, body, {}, headers)
      send_request(request)
    end

    def delete(path)
      request = prepare_request(:delete, path)
      send_request(request)
    end

    def self.parse_params(params)
      interesting_keys = [:max_keys, :prefix, :marker, :delimiter,
                          :location]

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
                          :if_match, :if_none_match]
      parsed_headers = {}
      headers.each do |key, value|
        if interesting_keys.include?(key)
          parsed_key = key.to_s.gsub("_", "-")
          parsed_value = value
          case value
          when Range
            parsed_value = "#{value.first}-#{value.last}"
          end
          parsed_headers[parsed_key] = parsed_value
        end
      end
      parsed_headers
    end

    def prepare_request(verb, path, body = nil, params = {}, headers = {})
      full_path = path_prefix
      full_path << path
      parsed_params = self.class.parse_params(params)
      full_path << "?#{parsed_params}" unless parsed_params.empty?

      case verb
      when :get
        request_class = Net::HTTP::Get
      when :head
        request_class = Net::HTTP::Head
      when :put
        request_class = Net::HTTP::Put
      when :delete
        request_class = Net::HTTP::Delete
      end

      request = request_class.new(full_path)

      parsed_headers = self.class.parse_headers(headers)
      parsed_headers.each do |key, value|
        request[key] = value
      end

      request.body = body

      request
    end

    def send_request(request)
      http = Net::HTTP.new(host, port)
      http.set_debug_output(STDOUT)
      http.use_ssl = use_ssl?
      response = http.start do |http|
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

      if (300..599).include?(response.code.to_i)
        xml = XmlSimple.xml_in(response.body)
        case xml["Code"].first
        when "NoSuchBucket"
          raise NoSuchBucket.new(xml["Message"].first, response)
        end
      end

      response
    end
  end
end
