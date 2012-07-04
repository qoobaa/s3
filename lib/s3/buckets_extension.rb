module S3
  module BucketsExtension
    # Builds new bucket with given name
    def build(name)
      Bucket.send(:new, proxy_owner, name)
    end

    # Finds the bucket with given name (only those which exist and You have access to it)
    # return nil in case Error::NoSuchBucket or Error::ForbiddenBucket
    def find_first(name)
      bucket = build(name)
      bucket.retrieve
    rescue Error::ForbiddenBucket, Error::NoSuchBucket
      nil
    end
    alias :find :find_first

    # Finds all buckets in the service
    def find_all
      proxy_target
    end

    # Destroys all buckets in the service. Doesn't destroy non-empty
    # buckets by default, pass true to force destroy (USE WITH CARE!).
    def destroy_all(force = false)
      proxy_target.each { |bucket| bucket.destroy(force) }
    end
  end
end
