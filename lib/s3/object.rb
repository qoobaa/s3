module S3
  class Object
    extend Forwardable

    attr_accessor :content_type, :key, :content_disposition, :content_encoding
    attr_reader :last_modified, :etag, :size, :bucket
    attr_writer :content

    def_instance_delegators :bucket, :name, :service, :bucket_request, :vhost?, :host, :path_prefix
    def_instance_delegators :service, :protocol, :port

    def ==(other)
      self.name == other.name and self.bucket == other.bucket
    end

    def acl=(acl)
      @acl = acl.to_s.gsub("_", "-")
    end

    def retrieve
      response = object_request(:get, :headers => { :range => 0..0 })
      parse_headers(response)
      self
    end

    def exists?
      retrieve
      true
    rescue Error::NoSuchKey
      false
    end

    def content(reload = false)
      if reload or @content.nil?
        response = object_request(:get)
        parse_headers(response)
        self.content = response.body
      end
      @content
    end

    def save
      body = content.is_a?(IO) ? content.read : content
      response = object_request(:put, :body => body, :headers => dump_headers)
      parse_headers(response)
      true
    end

    def destroy
      object_request(:delete)
      true
    end

    def url
      "#{protocol}#{host}/#{path_prefix}#{key}"
    end

    def cname_url
      "#{protocol}#{name}/#{key}" if bucket.vhost?
    end

    def inspect
      "#<#{self.class}:/#{name}/#{key}>"
    end

    protected

    def object_request(method, options = {})
      bucket_request(method, options.merge(:path => key))
    end

    private

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
      raise ArgumentError.new("Given key is not valid key name: #{@key}") unless key_valid?
      self.last_modified = options[:last_modified]
      self.etag = options[:etag]
      self.size = options[:size]
    end

    def parse_headers(response)
      self.etag = response["etag"]
      self.content_type = response["content-type"]
      self.content_disposition = response["content-disposition"]
      self.content_encoding = response["content-encoding"]
      self.last_modified = response["last-modified"]
      self.size = response["content-length"]
      if response["content-range"]
        self.size = response["content-range"].sub(/[^\/]+\//, "").to_i
      end
    end

    def dump_headers
      headers = {}
      headers[:x_amz_acl] = @acl || "public-read"
      headers[:content_type] = @content_type || "application/octet-stream"
      headers[:content_encoding] = @content_encoding if @content_encoding
      headers[:content_disposition] = @content_disposition if @content_disposition
      headers
    end

    def key_valid?
      @key !~ /\/\//
    end
  end
end
