require "singleton"
require "s3"

# S3 Backend for attachment-fu plugin. After installing attachment-fu
# plugin, copy the file to:
# +vendor/plugins/attachment-fu/lib/technoweenie/attachment_fu/backends+
#
# To configure S3Backend create initializer file in your Rails
# application, e.g. +config/initializers/s3_backend.rb+.
#
#   Technoweenie::AttachmentFu::Backends::S3Backend.configuration do |config|
#     config.access_key_id = "..." # your access key id
#     config.secret_access_key = "..." # your secret access key
#     config.bucket_name = "..." # default bucket name to store attachments
#     config.use_ssl = false # pass true if you want to communicate via SSL
#   end

module Technoweenie
  module AttachmentFu
    module Backends
      module S3Backend

        # S3Backend configuration class
        class Configuration
          include Singleton

          ATTRIBUTES = [:access_key_id, :secret_access_key, :use_ssl, :bucket_name]

          attr_accessor *ATTRIBUTES
        end

        # Method used to configure S3Backend, see the example above
        def self.configuration
          if block_given?
            yield Configuration.instance
          end
          Configuration.instance
        end

        # :nodoc:
        def self.included(base)
          include S3

          service = Service.new(:access_key_id => configuration.access_key_id,
                                :secret_access_key => configuration.secret_access_key,
                                :use_ssl => configuration.use_ssl)

          bucket_name = base.attachment_options[:bucket_name] || configuration.bucket_name

          base.cattr_accessor :bucket
          base.bucket = service.buckets.build(bucket_name) # don't connect

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

        # Name of the bucket used to store attachments
        def bucket_name
          self.class.bucket.name
        end

        # :nodoc:
        def create_temp_file
          write_to_temp_file current_data
        end

        # :nodoc:
        def current_data
          # Object.value full_filename, bucket_name
          object = self.class.bucket.objects.find(full_filename)
          object.content
        end

        # Returns http:// or https:// depending on use_ssl setting
        def s3_protocol
          attachment_options[:use_ssl] ?  "https://" : "http://"
        end

        # Returns hostname of the bucket
        # e.g. +bucketname.com.s3.amazonaws.com+. Additionally you can
        # pass :cname => true option in has_attachment method to
        # return CNAME only, e.g. +bucketname.com+
        def s3_hostname
          attachment_options[:cname] ? self.class.bucket.name : self.class.bucket.host
        end

        protected

        # Frees the space in S3 bucket, used by after_destroy callback
        def destroy_file
          object = self.class.bucket.objects.find(full_filename)
          object.destroy
        end

        # Renames file if filename has been changed - copy the file to
        # new key and delete old one
        def rename_file
          return unless filename_changed?

          old_full_filename = [base_path, filename_was].join("/")

          object = self.class.bucket.objects.find(old_full_filename)
          new_object = object.copy(:key => full_filename, :acl => attachment_options[:acl])
          object.destroy
          true
        end

        # Saves the file to storage
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
