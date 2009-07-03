module S3
  class Bucket
    extend Roxy::Moxie
    extend Forwardable

    attr_reader :name, :service

    def_instance_delegators :service, :service_request

    def retrieve
      bucket_request(:get, :params => { :max_keys => 0 })
      self
    end

    def location(reload = false)
      if reload or @location.nil?
        response = bucket_request(:get, :params => { :location => nil })
        @location = parse_location(response.body)
      else
        @location
      end
    end

    def ==(other)
      self.name == other.name and self.service == other.service
    end

    def exists?
      retrieve
      true
    rescue Error::NoSuchBucket
      false
    end

    def destroy(force = false)
      bucket_request(:delete)
      true
    rescue Error::BucketNotEmpty
      if force
        objects.destroy_all
        retry
      else
        raise
      end
    end

    def save(location = nil)
      location = location.to_s.upcase if location
      options = { :headers => {} }
      if location and location != "US"
        options[:body] = "<CreateBucketConfiguration><LocationConstraint>#{location}</LocationConstraint></CreateBucketConfiguration>"
        options[:headers][:content_type] = "application/xml"
      end
      bucket_request(:put, options)
      true
    end

    def vhost?
      "#@name.#{HOST}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
    end

    def host
      vhost? ? "#@name.#{HOST}" : "#{HOST}"
    end

    def path_prefix
      vhost? ? "" : "#@name/"
    end

    def name_valid?(name)
      name =~ /\A[a-z0-9][a-z0-9\._-]{2,254}\Z/ and name !~ /\A#{URI::REGEXP::PATTERN::IPV4ADDR}\Z/
    end

    def objects(reload = false, options = {})
      if options.empty?
        if reload or @objects.nil?
          @objects = fetch_objects
        else
          @objects
        end
      else
        fetch_objects(options)
      end
    end

    proxy :objects do
      def build(key)
        Object.new(proxy_owner, key)
      end

      def find_first(name)
        object = build(name)
        object.retrieve
      end
      alias :find :find_first

      def find_all(options = {})
        proxy_owner.objects(true, options)
      end

      def reload
        proxy_owner.objects(true)
      end

      def destroy_all
        proxy_target.each do |object|
          object.destroy
        end
      end
    end

    def inspect
      "#<#{self.class}:#{name}>"
    end

    def initialize(service, name)
      self.service = service
      self.name = name
    end

    private

    attr_writer :service

    def name=(name)
      raise ArgumentError.new("Invalid bucket name: #{name}") unless name_valid?(name)
      @name = name
    end

    def bucket_request(method, options = {})
      path = "#{path_prefix}#{options[:path]}"
      service_request(method, options.merge(:host => host, :path => path))
    end

    def fetch_objects(options = {})
      response = bucket_request(:get, options)
      parse_objects(response.body)
    end

    def parse_objects(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      objects_attributes = xml["Contents"]
      if objects_attributes
        objects_attributes.map do |object_attributes|
          Object.new(self,
                     object_attributes["Key"].first,
                     :etag => object_attributes["ETag"].first,
                     :last_modified => object_attributes["LastModified"].first,
                     :size => object_attributes["Size"].first)
        end
      else
        []
      end
    end

    def parse_location(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      xml["content"]
    end

  end
end
