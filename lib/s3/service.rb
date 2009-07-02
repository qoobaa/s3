module S3
  class Service
    extend Roxy::Moxie

    attr_reader :access_key_id, :secret_access_key, :use_ssl

    def initialize(options)
      @access_key_id = options[:access_key_id] or raise ArgumentError.new("no access key id given")
      @secret_access_key = options[:secret_access_key] or raise ArgumentError.new("no secret access key given")
      @use_ssl = options[:use_ssl]
      @timeout = options[:timeout]
      @debug = options[:debug]
    end

    def buckets(reload = false)
      if reload or not defined?(@buckets)
        response = connection.request(:get, :path => "/")
        @buckets = parse_buckets(response.body)
      else
        @buckets
      end
    end

    proxy :buckets do
      def build(name)
        Bucket.new(proxy_owner, name)
      end

      def find_first(name)
        Bucket.new(proxy_owner, name)
      end
      alias :find :find_first

      def find_all
        proxy_target
      end

      def reload
        proxy_owner.buckets(true)
      end
    end

    def inspect
      "#<#{self.class}:#@access_key_id>"
    end

    protected

    def connection
      unless defined?(@connection)
        @connection = Connection.new
        @connection.access_key_id = @access_key_id
        @connection.secret_access_key = @secret_access_key
        @connection.use_ssl = @use_ssl
        @connection.timeout = @timeout
        @connection.debug = @debug
      end
      @connection
    end

    private

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
