module S3
  class Object
    extend Forwardable

    attr_accessor :content_type, :acl, :key
    attr_reader :last_modified, :etag, :size, :bucket
    attr_writer :content

    def inspect
      "#<#{self.class}:/#{name}/#{key}>"
    end

    def content(reload = false)
      if reload or not defined?(@content)
        response = connection.request(:get, :path => "/#{key}")
        @content = response.body
      else
        @content
      end
    end

    def save
      acl = @acl || "public-read"
      content_type = @content_type || "application/octet-stream"
      body = content.is_a?(IO) ? content.read : content
      response = connection.request(:put,
                                    :path => "/#{key}",
                                    :body => body,
                                    :headers => { :x_amz_acl => acl, :content_type => content_type })
    end

    def destroy
      response = connection.request(:delete, :path => "/#{key}")
    end

    protected

    def_instance_delegators :@bucket, :connection, :name, :service

    attr_writer :key, :last_modified, :etag, :size

    def last_modified=(last_modified)
      @last_modified = Time.parse(last_modified)
    end

    def etag=(etag)
      @etag = etag[1..-2]
    end

    def initialize(bucket, key, options = {})
      @bucket = bucket
      self.key = key
      self.last_modified = options[:last_modified]
      self.etag = options[:etag]
      self.size = options[:size]
    end
  end
end
