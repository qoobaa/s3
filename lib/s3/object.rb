module S3

  # Class responsible for handling objects stored in S3 buckets

  class Object
    extend Forwardable

    attr_accessor :content_type, :content_disposition, :content_encoding
    attr_reader :last_modified, :etag, :size, :bucket, :key, :acl
    attr_writer :content

    def_instance_delegators :bucket, :name, :service, :bucket_request, :vhost?, :host, :path_prefix
    def_instance_delegators :service, :protocol, :port

    # Compares the object with +other+ object. Returns true if the key
    # of the objects are the same, and both have the same buckets (see
    # bucket equality)
    def ==(other)
      self.key == other.key and self.bucket == other.bucket
    end

    # Returns full key of the object: e.g. +bucket-name/object/key.ext+
    def full_key
      [name, key].join("/")
    end

    # Assigns a new +key+ to the object, raises ArgumentError if given
    # key is not valid key name
    def key=(key)
      raise ArgumentError.new("Invalid key name: #{key}") unless key_valid?(key)
      @key ||= key
    end

    # Assigns a new ACL to the object. Please note that ACL is not
    # retrieved from the server and set to "public-read" by default.
    # ==== Example
    #   object.acl = :public_read
    def acl=(acl)
      @acl = acl.to_s.gsub("_", "-") if acl
    end

    # Retrieves the object from the server. Method is used to download
    # object information only (content-type, size and so on). It does
    # NOT download the content of the object (use the content method
    # to do it).
    def retrieve
      response = object_request(:get, :headers => { :range => 0..0 })
      parse_headers(response)
      self
    end

    # Retrieves the object from the server, returns +true+ if the
    # object exists or +false+ otherwise. Uses +retrieve+ method, but
    # catches +NoSuchKey+ exception and returns false when it happens
    def exists?
      retrieve
      true
    rescue Error::NoSuchKey
      false
    end

    # Download the content of the object, and caches it. Pass +true+
    # to clear the cache and download the object again.
    def content(reload = false)
      if reload or @content.nil?
        response = object_request(:get)
        parse_headers(response)
        self.content = response.body
      end
      @content
    end

    # Saves the object, returns +true+ if successfull.
    def save
      body = content.is_a?(IO) ? content.read : content
      response = object_request(:put, :body => body, :headers => dump_headers)
      parse_headers(response)
      true
    end

    # Copies the file to another key and/or bucket.
    # ==== Options:
    # +:key+:: new key to store object in
    # +:bucket+:: new bucket to store object in (instance of S3::Bucket)
    # +:acl+:: acl of the copied object (default: +public-read+)
    # +:content_type+:: content type of the copied object (default: +application/octet-stream+)
    # TODO
    def copy(options = {})
      key = options[:key] || self.key
      bucket = options[:bucket] || self.bucket

      headers = {}
      headers[:x_amz_acl] = options[:acl] || acl || "public-read"
      headers[:content_type] = options[:content_type] || content_type || "application/octet-stream"
      headers[:content_encoding] = options[:content_encoding] if options[:content_encoding]
      headers[:content_disposition] = options[:content_disposition] if options[:content_disposition]
      headers[:x_amz_copy_source] = full_key
      headers[:x_amz_metadata_directive] = "REPLACE"
      headers[:x_amz_copy_source_if_match] = options[:if_match] if options[:if_match]
      headers[:x_amz_copy_source_if_none_match] = options[:if_none_match] if options[:if_none_match]
      headers[:x_amz_copy_source_if_unmodified_since] = options[:if_modified_since] if options[:if_modified_since]
      headers[:x_amz_copy_source_if_modified_since] = options[:if_unmodified_since] if options[:if_unmodified_since]

      response = bucket.send(:bucket_request, :put, :path => key, :headers => headers)
      self.class.parse_copied(:object => self, :bucket => bucket, :key => key, :body => response.body, :headers => headers)
    end

    def destroy
      object_request(:delete)
      true
    end

    def url
      URI.escape("#{protocol}#{host}/#{path_prefix}#{key}")
    end

    def cname_url
      URI.escape("#{protocol}#{name}/#{key}") if bucket.vhost?
    end

    def inspect
      "#<#{self.class}:/#{name}/#{key}>"
    end

    def initialize(bucket, key, options = {})
      self.bucket = bucket
      self.key = key
      self.last_modified = options[:last_modified]
      self.etag = options[:etag]
      self.size = options[:size]
    end

    private

    attr_writer :last_modified, :etag, :size, :original_key, :bucket

    def object_request(method, options = {})
      bucket_request(method, options.merge(:path => key))
    end

    def last_modified=(last_modified)
      @last_modified = Time.parse(last_modified) if last_modified
    end

    def etag=(etag)
      @etag = etag[1..-2] if etag
    end

    def dump_headers
      headers = {}
      headers[:x_amz_acl] = @acl || "public-read"
      headers[:content_type] = @content_type || "application/octet-stream"
      headers[:content_encoding] = @content_encoding if @content_encoding
      headers[:content_disposition] = @content_disposition if @content_disposition
      headers
    end

    def key_valid?(key)
      if (key.nil? or key.empty? or key =~ %r#//#)
        false
      else
        true
      end
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

    def self.parse_copied(options)
      xml = XmlSimple.xml_in(options[:body])
      etag = xml["ETag"].first
      last_modified = xml["LastModified"].first
      size = options[:object].size
      object = Object.new(options[:bucket], options[:key], :etag => etag, :last_modified => last_modified, :size => size)
      object.acl = options[:headers][:x_amz_acl]
      object.content_type = options[:headers][:content_type]
      object.content_encoding = options[:headers][:content_encoding]
      object.content_disposition = options[:headers][:content_disposition]
      object
    end
  end
end
