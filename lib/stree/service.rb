module Stree
  class Service
    include Parser
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
    # +access_key_id+:: Amazon access key id, required
    # +secret_access_key+:: Amazon secret access key, required
    # +use_ssl+:: true if use ssl in connection, otherwise false
    # +timeout+:: parameter for Net::HTTP module
    # +debug+:: prints the raw requests to STDOUT
    def initialize(options)
      @access_key_id = options[:access_key_id] or raise ArgumentError, "No access key id given"
      @secret_access_key = options[:secret_access_key] or raise ArgumentError, "No secret access key given"
      @use_ssl = options[:use_ssl]
      @timeout = options[:timeout]
      @debug = options[:debug]
    end

    # Returns all buckets in the service and caches the result (see reload)
    def buckets(reload = false)
      if reload or @buckets.nil?
        @buckets = list_all_my_buckets
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
      # Builds new bucket with given name
      def build(name)
        Bucket.send(:new, proxy_owner, name)
      end

      # Finds the bucket with given name
      def find_first(name)
        bucket = build(name)
        bucket.retrieve
      end
      alias :find :find_first

      # Find all buckets in the service
      def find_all
        proxy_target
      end

      # Reloads the bucket list (clears the cache)
      def reload
        proxy_owner.buckets(true)
      end

      # Destroy all buckets in the service. Doesn't destroy non-empty
      # buckets by default, pass true to force destroy (USE WITH
      # CARE!).
      def destroy_all(force = false)
        proxy_target.each do |bucket|
          bucket.destroy(force)
        end
      end
    end

    def inspect #:nodoc:
      "#<#{self.class}:#@access_key_id>"
    end

    private

    def list_all_my_buckets
      response = service_request(:get)
      names = parse_list_all_my_buckets_result(response.body)
      names.map { |name| Bucket.send(:new, self, name) }
    end

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
  end
end
