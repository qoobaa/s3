# S3 backend for paperclip plugin. Copy the file to:
# +config/initializers/+ directory
#
# Example configuration for CNAME bucket:
#
#   has_attached_file :image,
#                     :s3_host_alias => "bucket.domain.tld",
#                     :url => ":s3_alias_url",
#                     :styles => {
#                       :medium => "300x300>",
#                       :thumb => "100x100>"
#                     },
#                     :storage => :s3,
#                     :s3_credentials => {
#                       :access_key_id => "...",
#                       :secret_access_key => "..."
#                     },
#                     :bucket => "bucket.domain.tld",
#                     :path => ":attachment/:id/:style.:extension"
module Paperclip
  module Storage
    module S3
      def self.extended base
        begin
          require "s3"
        rescue LoadError => e
          e.message << " (You may need to install the s3 gem)"
          raise e
        end

        base.instance_eval do
          @s3_credentials   = parse_credentials(@options[:s3_credentials])
          @bucket_name      = @options[:bucket]           || @s3_credentials[:bucket]
          @bucket_name      = @bucket_name.call(self) if @bucket_name.is_a?(Proc)
          @s3_options       = @options[:s3_options]       || {}
          @s3_permissions   = @options[:s3_permissions]   || :public_read
          @s3_storage_class = @options[:s3_storage_class] || :standard
          @s3_protocol      = @options[:s3_protocol]      || (@s3_permissions == :public_read ? "http" : "https")
          @s3_headers       = @options[:s3_headers]       || {}
          @s3_host_alias    = @options[:s3_host_alias]
          @url              = ":s3_path_url" unless @url.to_s.match(/^:s3.*url$/)
          @service = ::S3::Service.new(@s3_options.merge(
            :access_key_id => @s3_credentials[:access_key_id],
            :secret_access_key => @s3_credentials[:secret_access_key],
            :use_ssl => @s3_protocol == "https"
          ))
          @bucket = @service.buckets.build(@bucket_name)
        end
        Paperclip.interpolates(:s3_alias_url) do |attachment, style|
          "#{attachment.s3_protocol}://#{attachment.s3_host_alias}/#{attachment.path(style).gsub(%r{^/}, "")}"
        end
        Paperclip.interpolates(:s3_path_url) do |attachment, style|
          "#{attachment.s3_protocol}://s3.amazonaws.com/#{attachment.bucket_name}/#{attachment.path(style).gsub(%r{^/}, "")}"
        end
        Paperclip.interpolates(:s3_domain_url) do |attachment, style|
          "#{attachment.s3_protocol}://#{attachment.bucket_name}.s3.amazonaws.com/#{attachment.path(style).gsub(%r{^/}, "")}"
        end
      end

      def expiring_url(style_name = default_style, time = 3600)
        bucket.objects.build(path(style_name)).temporary_url(Time.now + time)
      end

      def bucket_name
        @bucket_name
      end

      def bucket
        @bucket
      end

      def s3_host_alias
        @s3_host_alias
      end

      def parse_credentials creds
        creds = find_credentials(creds).stringify_keys
        (creds[RAILS_ENV] || creds).symbolize_keys
      end

      def exists?(style = default_style)
        if original_filename
          bucket.objects.build(path(style)).exists?
        else
          false
        end
      end

      def s3_protocol
        @s3_protocol
      end

      # Returns representation of the data of the file assigned to the given
      # style, in the format most representative of the current storage.
      def to_file style = default_style
        return @queued_for_write[style] if @queued_for_write[style]
        begin
          filename = path(style)
          extname = File.extname(filename)
          basename = File.basename(filename, extname)
          file = Tempfile.new([basename, extname])
          file.binmode if file.respond_to?(:binmode)
          file.write(bucket.objects.find(path(style)).content)
          file.rewind
        rescue ::S3::Error::NoSuchKey
          file.close if file.respond_to?(:close)
          file = nil
        end
        file
      end

      def flush_writes #:nodoc:
        @queued_for_write.each do |style, file|
          begin
            log("saving #{path(style)}")
            object = bucket.objects.build(path(style))
            file.rewind
            object.content = file.read
            object.acl = @s3_permissions
            object.storage_class = @s3_storage_class
            object.content_type = instance_read(:content_type)
            object.content_disposition = @s3_headers[:content_disposition]
            object.content_encoding = @s3_headers[:content_encoding]
            object.save
          rescue ::S3::Error::ResponseError => e
            raise
          end
        end
        @queued_for_write = {}
      end

      def flush_deletes #:nodoc:
        @queued_for_delete.each do |path|
          begin
            log("deleting #{path}")
            bucket.objects.find(path).destroy
          rescue ::S3::Error::ResponseError
            # Ignore this.
          end
        end
        @queued_for_delete = []
      end

      def find_credentials creds
        case creds
        when File
          YAML::load(ERB.new(File.read(creds.path)).result)
        when String
          YAML::load(ERB.new(File.read(creds)).result)
        when Hash
          creds
        else
          raise ArgumentError, "Credentials are not a path, file, or hash."
        end
      end
      private :find_credentials

    end
  end
end
