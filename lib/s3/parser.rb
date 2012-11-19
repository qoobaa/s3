module S3
  module Parser
    include REXML

    def rexml_document(xml)
      xml.force_encoding(::Encoding::UTF_8) if xml.respond_to? :force_encoding
      Document.new(xml)
    end

    def parse_list_all_my_buckets_result(xml)
      names = []
      rexml_document(xml).elements.each("ListAllMyBucketsResult/Buckets/Bucket/Name") { |e| names << e.text }
      names
    end

    def parse_location_constraint(xml)
      rexml_document(xml).elements["LocationConstraint"].text
    end

    def parse_list_bucket_result(xml)
      objects_attributes = []
      rexml_document(xml).elements.each("ListBucketResult/Contents") do |e|
        object_attributes = {}
        object_attributes[:key] = e.elements["Key"].text
        object_attributes[:etag] = e.elements["ETag"].text
        object_attributes[:last_modified] = e.elements["LastModified"].text
        object_attributes[:size] = e.elements["Size"].text
        objects_attributes << object_attributes
      end
      objects_attributes
    end

    def parse_copy_object_result(xml)
      object_attributes = {}
      document = rexml_document(xml)
      object_attributes[:etag] = document.elements["CopyObjectResult/ETag"].text
      object_attributes[:last_modified] = document.elements["CopyObjectResult/LastModified"].text
      object_attributes
    end

    def parse_error(xml)
      document = rexml_document(xml)
      code = document.elements["Error/Code"].text
      message = document.elements["Error/Message"].text
      [code, message]
    end

    def parse_is_truncated xml
      rexml_document(xml).elements["ListBucketResult/IsTruncated"].text =='true'
    end


    # Parse acl response and return hash with grantee and their permissions
    def parse_acl(xml)
      grants = {}
      rexml_document(xml).elements.each("AccessControlPolicy/AccessControlList/Grant") do |grant|
        grants.merge!(extract_grantee(grant))
      end
      grants
    end

    private

     def convert_uri_to_group_name(uri)
        case uri
        when "http://acs.amazonaws.com/groups/global/AllUsers"
          return "Everyone"
        when "http://acs.amazonaws.com/groups/global/AuthenticatedUsers"
          return "Authenticated Users"
        when "http://acs.amazonaws.com/groups/s3/LogDelivery"
          return "Log Delivery"
        else
          return uri
        end
      end

     def extract_grantee(grant)
        grants  = {}
        grant.each_element_with_attribute("xsi:type", "Group") do |grantee|
          group_name = convert_uri_to_group_name(grantee.get_text("URI").value)
          grants[group_name] = grant.get_text("Permission").value
        end
        grant.each_element_with_attribute("xsi:type", "CanonicalUser") do |grantee|
          user_name = grantee.get_text("DisplayName").value
          grants[user_name] = grant.get_text("Permission").value
        end
        grants
     end
  end
end
