module S3
  class Object
    extend Roxy::Moxie
    extend Forwardable

    attr_accessor :content_type, :acl, :key
    attr_reader :last_modified, :etag, :size, :bucket
    attr_writer :content

    def exists?
      response = connection.request(:get, :headers => { :range => 0..0 })
      parse_headers(response)
      true
    rescue Error::NoSuchKey
      false
    end

    def content(reload = false)
      if reload or @content.nil?
        response = connection.request(:get)
        parse_headers(response)
        self.content = response.body
      end
      @content
    end

    def save
      acl = @acl || "public-read"
      content_type = @content_type || "application/octet-stream"
      body = content.is_a?(IO) ? content.read : content
      response = connection.request(:put,
                                    :body => body,
                                    :headers => { :x_amz_acl => acl, :content_type => content_type })
    end

    def destroy
      response = connection.request(:delete)
    end

    def inspect
      "#<#{self.class}:/#{name}/#{key}>"
    end

    protected

    def_instance_delegators :@bucket, :connection, :name, :service

    proxy :connection do
      def request(method, options = {})
        path = "#{proxy_owner.key}"
        proxy_target.request(method, options.merge(:path => path))
      end
    end

    attr_writer :key, :last_modified, :etag, :size

    def last_modified=(last_modified)
      @last_modified = Time.parse(last_modified) if last_modified
    end

    def etag=(etag)
      @etag = etag[1..-2] if etag
    end

    def initialize(bucket, key, options = {})
      @bucket = bucket
      self.key = key
      self.last_modified = options[:last_modified]
      self.etag = options[:etag]
      self.size = options[:size]
    end

    def parse_headers(response)
      self.etag = response["etag"]
      self.content_type = response["content-type"]
      self.last_modified = response["last-modified"]
      self.size = response["content-length"]
      if response["content-range"]
        self.size = response["content-range"].sub(/[^\/]+\//, "").to_i
      end
    end
  end
end
