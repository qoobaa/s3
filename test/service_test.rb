require 'test_helper'

class ServiceTest < Test::Unit::TestCase
  def setup
    @service_empty_buckets_list = Stree::Service.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @response_empty_buckets_list = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@service_empty_buckets_list).service_request { @response_empty_buckets_list }
    stub(@response_empty_buckets_list).body { @buckets_empty_list_body }

    @service_buckets_list = Stree::Service.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @response_buckets_list = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@service_buckets_list).service_request { @response_buckets_list }
    stub(@response_buckets_list).body { @buckets_list_body }

    @service_bucket_exists = Stree::Service.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @response_bucket_exists = Net::HTTPNotFound.new("1.1", "200", "OK")
    stub(@service_bucket_exists).service_request { @response_bucket_exists }
    stub(@response_bucket_exists).body { @bucket_exists }

    @service_bucket_not_exists = Stree::Service.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @response_bucket_not_exists = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    stub(@service_bucket_not_exists).service_request { raise Stree::Error::NoSuchBucket.new(404, @response_bucket_not_exists) }
    stub(@response_bucket_not_exists).body { @bucket_not_exists }

    @buckets_empty_list = []
    @buckets_empty_list_body = <<-EOEmptyBuckets
    <?xml version="1.0" encoding="UTF-8"?>\n<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> <Owner> <ID>123u1odhkhfoadf</ID> <DisplayName>JohnDoe</DisplayName> </Owner> <Buckets> </Buckets> </ListAllMyBucketsResult>
    EOEmptyBuckets

    @buckets_list = [
      Stree::Bucket.new(@service_buckets_list, "data.example.com"),
      Stree::Bucket.new(@service_buckets_list, "images")
    ]
    @buckets_list_body = <<-EOBuckets
    <?xml version="1.0" encoding="UTF-8"?>\n<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> <Owner> <ID>123u1odhkhfoadf</ID> <DisplayName>JohnDoe</DisplayName> </Owner> <Buckets> <Bucket> <Name>data.example.com</Name> <CreationDate>2009-07-02T11:56:58.000Z</CreationDate> </Bucket> <Bucket> <Name>images</Name> <CreationDate>2009-06-05T12:26:33.000Z</CreationDate> </Bucket> </Buckets> </ListAllMyBucketsResult>
    EOBuckets

    @bucket_not_exists = <<-EOBucketNoexists
    <?xml version="1.0" encoding="UTF-8"?>\n<Error> <Code>NoSuchBucket</Code> <Message>The specified bucket does not exists</Message> <BucketName>data2.example.com</BucketName> <RequestId>8D7519AAE74E9E99</RequestId> <HostId>DvKnnNSMnPHd1oXukyRaFNv8Lg/bpwhuUtY8Kj7eDLbaIrIT8JebSnHwi89AK1P+</HostId> </Error>
    EOBucketNoexists

    @bucket_exists = <<-EOBucketexists
    <?xml version="1.0" encoding="UTF-8"?>\n<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> <Name>data.synergypeople.net</Name> <Prefix></Prefix> <Marker></Marker> <MaxKeys>1000</MaxKeys> <IsTruncated>false</IsTruncated> </ListBucketResult>
    EOBucketexists
  end

  def test_buckets_and_parse_buckets_empty
    expected = @buckets_empty_list
    actual = @service_empty_buckets_list.buckets
    assert_equal expected.length, actual.length
    assert_equal expected, actual
  end

  def test_buckets_and_parse_buckets
    expected = @buckets_list
    # ugly hack
    actual = @service_buckets_list.buckets(true).map { |obj| obj }
    assert_equal expected, actual
  end

  def test_buckets_reload
    @service = @service_empty_buckets_list

    expected = @buckets_empty_list
    assert @service.buckets, "retrive buckets"
    actual = @service.buckets
    assert_equal expected.length, actual.length, "deliver from cache"

    stub(@service).service_request { @response_buckets_list }
    expected = @buckets_empty_list
    actual = @service.buckets
    assert_equal expected.length, actual.length, "deliver from cache"

    expected = @buckets_list
    actual = @service.buckets(true)
    assert_equal expected.length, actual.length
  end

  def test_buckets_build
    stub(@service_empty_buckets_list).service_request { flunk "should not connect to server" }

    expected = "bucket_name"
    actual = @service_empty_buckets_list.buckets.build("bucket_name")
    assert_kind_of Stree::Bucket, actual
    assert_equal expected, actual.name
  end

  def test_buckets_find_first
    assert_nothing_raised do
      actual = @service_buckets_list.buckets.find_first("data.example.com")
      assert_equal "data.example.com", actual.name
    end
  end

  def test_buckets_find_first_fail
    assert_raise Stree::Error::NoSuchBucket do
      @service_bucket_not_exists.buckets.find_first("data2.example.com")
    end
  end

  def test_buckets_find_all_on_empty_list
    assert_nothing_raised do
      expected = @buckets_empty_list
      actual = @service_empty_buckets_list.buckets.find_all
      assert_equal expected, actual
    end
  end

  def test_buckets_find_all
    assert_nothing_raised do
      expected = @buckets_list
      actual = @service_buckets_list.buckets.find_all
      assert_equal expected, actual
    end
  end
end
