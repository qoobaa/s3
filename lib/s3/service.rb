module S3
  class Service
    extend Roxy::Moxie

    attr_reader :access_key_id, :secret_access_key, :use_ssl

    # Compares service to other, by access_key_id and secret_access_key
    def ==(other)
      self.access_key_id == other.access_key_id and self.secret_access_key == other.secret_access_key
    end

    # ==== Parameters:
    # +options+:: a hash of options described below
    #
    # ==== Options:
    # +:access_key_id+:: Amazon access key id, required
    # +:secret_access_key+:: Amazon secret access key, required
    # +:use_ssl+:: true if use ssl in connection, otherwise false
    # +:timeout+:: parameter for Net::HTTP module
    # +:debug+:: if debuging informations are needed
    def initialize(options)
      @access_key_id = options[:access_key_id] or raise ArgumentError.new("No access key id given")
      @secret_access_key = options[:secret_access_key] or raise ArgumentError.new("No secret access key given")
      @use_ssl = options[:use_ssl]
      @timeout = options[:timeout]
      @debug = options[:debug]
    end

    def buckets(reload = false)
      if reload or @buckets.nil?
        response = service_request(:get)
        @buckets = parse_buckets(response.body)
      else
        @buckets
      end
    end

    # Returns "http://" or "https://", depends on use_ssl value from initializer
    def protocol
      use_ssl ? "https://" : "http://"
    end

    # Return 443 or 80, depends on use_ssl value from initializer
    def port
      use_ssl ? 443 : 80
    end

    proxy :buckets do
      def build(name)
        Bucket.new(proxy_owner, name)
      end

      def find_first(name)
        bucket = build(name)
        bucket.retrieve
      end
      alias :find :find_first

      def find_all
        proxy_target
      end

      def reload
        proxy_owner.buckets(true)
      end

      def destroy_all(force = false)
        proxy_target.each do |bucket|
          bucket.destroy(force)
        end
      end
    end

    def inspect
      "#<#{self.class}:#@access_key_id>"
    end

    private

    def service_request(method, options = {})
      connection.request(method, options.merge(:path => "/#{options[:path]}"))
    end

    def connection
      if @connection.nil?
        @connection = Connection.new
        @connection.access_key_id = @access_key_id
        @connection.secret_access_key = @secret_access_key
        @connection.use_ssl = @use_ssl
        @connection.timeout = @timeout
        @connection.debug = @debug
      end
      @connection
    end

    def parse_buckets(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      buckets = xml["Buckets"].first["Bucket"]
      if buckets
        buckets_names = buckets.map { |bucket| bucket["Name"].first }
        buckets_names.map do |bucket_name|
          Bucket.new(self, bucket_name)
        end
      else
        []
      end
    end
  end
end
