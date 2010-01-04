module S3
  class Bucket
    include Parser
    extend Roxy::Moxie
    extend Forwardable

    attr_reader :name, :service

    def_instance_delegators :service, :service_request
    private_class_method :new

    # Retrieves the bucket information from the server. Raises an
    # S3::Error exception if the bucket doesn't exist or you don't
    # have access to it, etc.
    def retrieve
      list_bucket(:max_keys => 0)
      self
    end

    # Returns location of the bucket, e.g. "EU"
    def location(reload = false)
      if reload or @location.nil?
        @location = location_constraint
      else
        @location
      end
    end

    # Compares the bucket with other bucket. Returns true if the key
    # of the objects are the same, and both have the same buckets (see
    # bucket equality)
    def ==(other)
      self.name == other.name and self.service == other.service
    end

    # Similar to retrieve, but catches NoSuchBucket exceptions and
    # returns false instead.
    def exists?
      retrieve
      true
    rescue Error::NoSuchBucket
      false
    end

    # Destroys given bucket. Raises an BucketNotEmpty exception if the
    # bucket is not empty. You can destroy non-empty bucket passing
    # true (to force destroy)
    def destroy(force = false)
      delete_bucket
      true
    rescue Error::BucketNotEmpty
      if force
        objects.destroy_all
        retry
      else
        raise
      end
    end

    # Saves the newly built bucket. Optionally you can pass location
    # of the bucket (:eu or :us)
    def save(location = nil)
      create_bucket_configuration(location)
      true
    end

    # Returns true if the name of the bucket can be used like VHOST
    # name. If the bucket contains characters like underscore it can't
    # be used as VHOST (e.g. bucket_name.s3.amazonaws.com)
    def vhost?
      "#@name.#{HOST}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
    end

    # Returns host name of the bucket according (see vhost?)
    def host
      vhost? ? "#@name.#{HOST}" : "#{HOST}"
    end

    # Returns path prefix for non VHOST bucket. Path prefix is used
    # instead of VHOST name,
    # e.g. "bucket_name/"
    def path_prefix
      vhost? ? "" : "#@name/"
    end

    # Returns the objects in the bucket and caches the result (see
    # reload).
    def objects(reload = false)
      if reload or @objects.nil?
        @objects = list_bucket
      else
        @objects
      end
    end

    proxy :objects do

      # Builds the object in the bucket with given key
      def build(key)
        Object.send(:new, proxy_owner, :key => key)
      end

      # Finds first object with given name or raises the exception if
      # not found
      def find_first(name)
        object = build(name)
        object.retrieve
      end
      alias :find :find_first

      # Finds the objects in the bucket.
      # ==== Options:
      # +prefix+:: Limits the response to keys which begin with the indicated prefix
      # +marker+:: Indicates where in the bucket to begin listing
      # +max_keys+:: The maximum number of keys you'd like to see
      # +delimiter+:: Causes keys that contain the same string between the prefix and the first occurrence of the delimiter to be rolled up into a single result element
      def find_all(options = {})
        proxy_owner.send(:list_bucket, options)
      end

      # Reloads the object list (clears the cache)
      def reload
        proxy_owner.objects(true)
      end

      # Destroys all keys in the bucket
      def destroy_all
        proxy_target.each do |object|
          object.destroy
        end
      end
    end

    def inspect #:nodoc:
      "#<#{self.class}:#{name}>"
    end

    private

    attr_writer :service

    def location_constraint
      response = bucket_request(:get, :params => { :location => nil })
      parse_location_constraint(response.body)
    end

    def list_bucket(options = {})
      response = bucket_request(:get, :params => options)
      objects_attributes = parse_list_bucket_result(response.body)
      objects_attributes.map { |object_attributes| Object.send(:new, self, object_attributes) }
    end

    def create_bucket_configuration(location = nil)
      location = location.to_s.upcase if location
      options = { :headers => {} }
      if location and location != "US"
        options[:body] = "<CreateBucketConfiguration><LocationConstraint>#{location}</LocationConstraint></CreateBucketConfiguration>"
        options[:headers][:content_type] = "application/xml"
      end
      bucket_request(:put, options)
    end

    def delete_bucket
      bucket_request(:delete)
    end

    def initialize(service, name) #:nodoc:
      self.service = service
      self.name = name
    end

    def name=(name)
      raise ArgumentError.new("Invalid bucket name: #{name}") unless name_valid?(name)
      @name = name
    end

    def bucket_request(method, options = {})
      path = "#{path_prefix}#{options[:path]}"
      service_request(method, options.merge(:host => host, :path => path))
    end

    def name_valid?(name)
      name =~ /\A[a-z0-9][a-z0-9\._-]{2,254}\Z/i and name !~ /\A#{URI::REGEXP::PATTERN::IPV4ADDR}\Z/
    end
  end
end
