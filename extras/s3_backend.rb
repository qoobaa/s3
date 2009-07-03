require "singleton"
require "s3"

module Technoweenie
  module AttachmentFu
    module Backends
      module S3Backend
        class Configuration
          include Singleton

          ATTRIBUTES = [:access_key_id, :secret_access_key, :use_ssl, :bucket_name]

          attr_accessor *ATTRIBUTES
        end

        def self.configuration
          if block_given?
            yield Configuration.instance
          end
          Configuration.instance
        end

        def self.included(base)
          include S3

          service = Service.new(:access_key_id => configuration.access_key_id,
                                :secret_access_key => configuration.secret_access_key,
                                :use_ssl => configuration.use_ssl)

          bucket_name = base.attachment_options[:bucket_name] || configuration.bucket_name

          base.cattr_accessor :bucket
          base.bucket = service.buckets.find(bucket_name)

          base.before_update :rename_file
        end

        # The attachment ID used in the full path of a file
        def attachment_path_id
          ((respond_to?(:parent_id) && parent_id) || id).to_s
        end

        # The pseudo hierarchy containing the file relative to the bucket name
        # Example: <tt>:table_name/:id</tt>
        def base_path
          [attachment_options[:path_prefix], attachment_path_id].join("/")
        end

        # The full path to the file relative to the bucket name
        # Example: <tt>:table_name/:id/:filename</tt>
        def full_filename(thumbnail = nil)
          [base_path, thumbnail_name_for(thumbnail)].join("/")
        end

        # All public objects are accessible via a GET request to the S3 servers. You can generate a
        # url for an object using the s3_url method.
        #
        #   @photo.s3_url
        #
        # The resulting url is in the form: <tt>http(s)://:server/:bucket_name/:table_name/:id/:file</tt> where
        # the <tt>:server</tt> variable defaults to <tt>AWS::S3 URL::DEFAULT_HOST</tt> (s3.amazonaws.com) and can be
        # set using the configuration parameters in <tt>RAILS_ROOT/config/amazon_s3.yml</tt>.
        #
        # The optional thumbnail argument will output the thumbnail's filename (if any).
        def s3_url(thumbnail = nil)
          if attachment_options[:cname]
            ["#{s3_protocol}#{bucket.name}", full_filename(thumbnail)].join("/")
          else
            ["#{s3_protocol}#{s3_hostname}#{bucket.path_prefix}", full_filename(thumbnail)].join("/")
          end
        end
        alias :public_url :s3_url
        alias :public_filename :s3_url

        def bucket_name
          self.class.bucket.name
        end

        def create_temp_file
          write_to_temp_file current_data
        end

        def current_data
          S3Object.value full_filename, bucket_name
        end

        def s3_protocol
          attachment_options[:use_ssl] ?  "https://" : "http://"
        end

        def s3_hostname
          attachment_options[:cname] ? self.class.bucket.name : self.class.bucket.host
        end

        protected

        def destroy_file
          object = self.class.bucket.objects.find(full_filename)
          object.destroy
        end

        def rename_file
          return unless filename_changed?

          old_full_filename = [base_path, filename_was].join("/")

          object = self.class.bucket.objects.find(old_full_filename)
          new_object = object.copy(:key => full_filename, :acl => attachment_options[:acl])
          object.destroy
          true
        end

        def save_to_storage
          if save_attachment?
            object = self.class.bucket.objects.build(full_filename)

            object.content_type = content_type
            object.acl = attachment_options[:acl]
            object.content = temp_path ? File.open(temp_path) : temp_data
            object.save
          end
          true
        end
      end
    end
  end
end
