module S3
  module ObjectsExtension
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
    #
    # ==== Options
    # * <tt>:prefix</tt> - Limits the response to keys which begin
    #   with the indicated prefix
    # * <tt>:marker</tt> - Indicates where in the bucket to begin
    #   listing
    # * <tt>:max_keys</tt> - The maximum number of keys you'd like
    #   to see
    # * <tt>:delimiter</tt> - Causes keys that contain the same
    #   string between the prefix and the first occurrence of the
    #   delimiter to be rolled up into a single result element
    def find_all(options = {})
      proxy_owner.send(:list_bucket, options)
    end

    # Destroys all keys in the bucket
    def destroy_all
      proxy_target.each { |object| object.destroy }
    end
  end
end
