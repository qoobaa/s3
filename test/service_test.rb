require 'test_helper'

class ServiceTest < Test::Unit::TestCase
  def setup
    @service_ok = S3::Service.new(
      :access_key_id =>  "12345678901234567890",
      :secret_access_key =>  "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDF"
    )
    @connection_ok = S3::Connection.new
    @response_ok = Net::HTTPOK.new("1.1", "200", "OK")
    stub(@service_ok).connection { @connection_ok }
    stub(@connection_ok).request { @response_ok } # redefine it if needed

    @buckets_empty_list = []
    @buckets_empty_list_body = <<-EOEmptyBuckets
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListAllMyBucketsResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
      <Owner>
        <ID>123u1odhkhfoadf</ID>
        <DisplayName>JohnDoe</DisplayName>
      </Owner>
      <Buckets>
      </Buckets>
    </ListAllMyBucketsResult>
    EOEmptyBuckets

    @buckets_list = [
      S3::Bucket.new(@service_ok, "data.example.com"),
      S3::Bucket.new(@service_ok, "images")
    ]
    @buckets_list_body = <<-EOBuckets
    <?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListAllMyBucketsResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
      <Owner>
        <ID>123u1odhkhfoadf</ID>
        <DisplayName>JohnDoe</DisplayName>
      </Owner>
      <Buckets>
        <Bucket>
          <Name>data.example.com</Name>
          <CreationDate>2009-07-02T11:56:58.000Z</CreationDate>
        </Bucket>
        <Bucket>
          <Name>images</Name>
          <CreationDate>2009-06-05T12:26:33.000Z</CreationDate>
        </Bucket>
      </Buckets>
    </ListAllMyBucketsResult>
    EOBuckets
  end

  def test_buckets_and_parse_buckets_empty
    stub(@response_ok).body { @buckets_empty_list_body }

    expected = @buckets_empty_list
    actual = @service_ok.buckets
    assert_equal expected.length, actual.length
    assert_equal expected, actual
  end

  def test_buckets_and_parse_buckets
    stub(@response_ok).body { @buckets_list_body }

    expected = @buckets_list
    # ugly hack
    actual = @service_ok.buckets(true).map { |obj| obj }
    assert_equal expected.length, actual.length
    # ugly hack
    expected.zip(actual).each do |a|
      assert_equal a[0].name, a[1].name
    end
  end

  def test_buckets_reload
    stub(@response_ok).body { @buckets_empty_list_body }

    expected = @buckets_empty_list
    assert @service_ok.buckets, "retrive buckets"
    actual = @service_ok.buckets
    assert_equal expected.length, actual.length, "deliver from cache"

    stub(@response_ok).body { @buckets_list_body }
    expected = @buckets_empty_list
    actual = @service_ok.buckets
    assert_equal expected.length, actual.length, "deliver from cache"

    expected = @buckets_list
    actual = @service_ok.buckets(true)
    assert_equal expected.length, actual.length
  end

  def test_buckets_build
    stub(@connection_ok).request { flunk "should not connect to server" }

    expected = "bucket_name"
    actual = @service_ok.buckets.build("bucket_name")
    assert_kind_of S3::Bucket, actual
    assert_equal expected, actual.name
  end

  def test_buckets_find_first
    stub(@response_ok).body { @buckets_list_body }

    assert_nothing_raised do
      actual = @service_ok.buckets.find_first("data.example.com")
      assert_equal "data.example.com", actual.name
    end
  end

  def test_buckets_find_first_fail
    stub(@response_ok).body { @buckets_list_body }

    assert_raises S3::Error::NoSuchBucket do
      @service_ok.buckets.find_first("data2.example.com")
    end
  end

  def test_buckets_find_all_on_empty_list
    stub(@response_ok).body { @buckets_empty_list_body }

    assert_nothing_raised do
      expected = @buckets_empty_list
      actual = @service_ok.buckets.find_all
      assert_equal expected, actual
    end
  end

  def test_buckets_find_all
    stub(@response_ok).body { @buckets_list_body }

    assert_nothing_raised do
      expected = @buckets_list
      actual = @service_ok.buckets.find_all
      assert_equal expected.length, actual.length
      expected.zip(actual).each do |a|
        assert_equal a[0].name, a[1].name
      end
    end
  end
end
