module S3
  class Service
    include Parser
    include Proxies

    attr_reader :access_key_id, :secret_access_key, :use_ssl, :proxy

    # Compares service to other, by <tt>access_key_id</tt> and
    # <tt>secret_access_key</tt>
    def ==(other)
      self.access_key_id == other.access_key_id and self.secret_access_key == other.secret_access_key
    end

    # Creates new service.
    #
    # ==== Options
    # * <tt>:access_key_id</tt> - Access key id (REQUIRED)
    # * <tt>:secret_access_key</tt> - Secret access key (REQUIRED)
    # * <tt>:use_ssl</tt> - Use https or http protocol (false by
    #   default)
    # * <tt>:debug</tt> - Display debug information on the STDOUT
    #   (false by default)
    # * <tt>:timeout</tt> - Timeout to use by the Net::HTTP object
    #   (60 by default)
    def initialize(options)
      @access_key_id = options.fetch(:access_key_id)
      @secret_access_key = options.fetch(:secret_access_key)
      @use_ssl = options.fetch(:use_ssl, false)
      @timeout = options.fetch(:timeout, 60)
      @debug = options.fetch(:debug, false)

      raise ArgumentError, "Missing proxy settings. Must specify at least :host." if options[:proxy] && !options[:proxy][:host]
      @proxy = options.fetch(:proxy, nil)
    end

    # Returns all buckets in the service and caches the result (see
    # +reload+)
    def buckets
      Proxy.new(lambda { list_all_my_buckets }, :owner => self, :extend => BucketsExtension)
    end

    # Returns the bucket with the given name. Does not check whether the
    # bucket exists. But also does not issue any HTTP requests, so it's
    # much faster than buckets.find
    def bucket(name)
      Bucket.send(:new, self, name)
    end

    # Returns "http://" or "https://", depends on <tt>:use_ssl</tt>
    # value from initializer
    def protocol
      use_ssl ? "https://" : "http://"
    end

    # Returns 443 or 80, depends on <tt>:use_ssl</tt> value from
    # initializer
    def port
      use_ssl ? 443 : 80
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
      return @connection if defined?(@connection)
      @connection = Connection.new(:access_key_id => @access_key_id,
                               :secret_access_key => @secret_access_key,
                               :use_ssl => @use_ssl,
                               :timeout => @timeout,
                               :debug => @debug,
                               :proxy => @proxy)
    end
  end
end
