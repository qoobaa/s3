module S3
  class Bucket
    extend Roxy::Moxie
    extend Forwardable

    attr_reader :name, :service

    def location
      response = connection.request(:get, :params => { :location => nil })
      parse_location(response.body)
    end

    def exists?
      connection.request(:get, :params => { :max_keys => 0 })
      true
    rescue Error::NoSuchBucket
      false
    end

    def destroy
      connection.request(:delete)
      true
    end

    def save(location = nil)
      options = { :path => "/", :headers => {} }
      if location and location != "US"
        options[:body] = "<CreateBucketConfiguration><LocationConstraint>#{location}</LocationConstraint></CreateBucketConfiguration>"
        options[:headers][:content_type] = "application/xml"
      end
      connection.request(:put, options)
      true
    end

    def host
      vhost? ? "#@name.#{HOST}" : "#{HOST}"
    end

    def path_prefix
      vhost? ? "" : "/#@name"
    end

    def objects(options = {})
      response = connection.request(:get, :params => options)
      parse_objects(response.body)
    end

    proxy :objects do
      def build(key)
        Object.new(proxy_owner, key)
      end

      def find(options = {})
        proxy_owner.objects(options)
      end
    end

    def inspect
      "#<#{self.class}:#{name}>"
    end

    protected

    def_instance_delegators :@service, :connection

    proxy :connection do
      def request(method, options = {})
        path = "#{proxy_owner.path_prefix}/#{options[:path]}"
        host = proxy_owner.host
        proxy_target.request(method, options.merge(:host => host, :path => path))
      end
    end

    def initialize(service, name)
      @service = service
      @name = name
    end

    private

    def vhost?
      "#@name.#{HOST}" =~ /\A#{URI::REGEXP::PATTERN::HOSTNAME}\Z/
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
