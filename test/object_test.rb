# encoding: utf-8
require "test_helper"

class ObjectTest < Test::Unit::TestCase
  def setup
    @service = S3::Service.new(
      :access_key_id => "1234",
      :secret_access_key => "1337"
    )
    @bucket_images = S3::Bucket.send(:new, @service, "images")
    @object_lena = S3::Object.send(:new, @bucket_images, :key => "Lena.png")
    @object_lena.content = "test"
    @object_carmen = S3::Object.send(:new, @bucket_images, :key => "Carmen.png")
    @object_mac = S3::Object.send(:new, @bucket_images, :key => "Mac.png", :cache_control => "max-age=315360000")
    @object_mac.content = "test2"

    @response_binary = Net::HTTPOK.new("1.1", "200", "OK")
    @response_binary.stubs(:body).returns("test".respond_to?(:force_encoding) ? "test".force_encoding(Encoding::BINARY) : "test")
    @response_binary["etag"] = ""
    @response_binary["content-type"] = "image/png"
    @response_binary["content-disposition"] = "inline"
    @response_binary["content-encoding"] = nil
    @response_binary["last-modified"] = Time.now.httpdate
    @response_binary["content-length"] = 20
    @response_binary["x-amz-meta-test"] = "metadata"

    @xml_body = <<-EOXML
    <?xml version="1.0" encoding="UTF-8"?>
    <CopyObjectResult> <LastModified>#{Time.now.httpdate}</LastModified> <ETag>"etag"</ETag> </CopyObjectResult>
    EOXML
    @response_xml = Net::HTTPOK.new("1.1", "200", "OK")
    @response_xml.stubs(:body).returns(@xml_body)
  end

  test "initializing" do
    assert_raise ArgumentError do S3::Object.send(:new, nil, :key => "") end # should not allow empty key
    assert_raise ArgumentError do S3::Object.send(:new, nil, :key => "//") end # should not allow key with double slash

    assert_nothing_raised do
      S3::Object.send(:new, nil, :key => "Lena.png")
      S3::Object.send(:new, nil, :key => "Lena playboy.png")
      S3::Object.send(:new, nil, :key => "Lena Söderberg.png")
      S3::Object.send(:new, nil, :key => "/images/pictures/test images/Lena not full.png")
    end
  end

  test "==" do
    expected = false
    actual = @object_lena == nil
    assert_equal(expected, actual)
  end

  test "full key" do
    expected = "images/Lena.png"
    actual = @object_lena.full_key
    assert_equal expected, actual
  end

  test "url" do
    bucket1 = S3::Bucket.send(:new, @service, "images")

    object11 = S3::Object.send(:new, bucket1, :key => "Lena.png")
    expected = "http://images.s3.amazonaws.com/Lena.png"
    actual = object11.url
    assert_equal expected, actual

    object12 = S3::Object.send(:new, bucket1, :key => "Lena Söderberg.png")
    expected = "http://images.s3.amazonaws.com/Lena%20S%C3%B6derberg.png"
    actual = object12.url
    assert_equal expected, actual
    
    object13 = S3::Object.send(:new, bucket1, :key => "Lena Söderberg [1].png")
    expected = "http://images.s3.amazonaws.com/Lena%20S%C3%B6derberg%20%5B1%5D.png"
    actual = object13.url
    assert_equal expected, actual

    bucket2 = S3::Bucket.send(:new, @service, "images_new")

    object21 = S3::Object.send(:new, bucket2, :key => "Lena.png")
    expected = "http://s3.amazonaws.com/images_new/Lena.png"
    actual = object21.url
    assert_equal expected, actual
  end

  test "cname url" do
    bucket1 = S3::Bucket.send(:new, @service, "images.example.com")

    object11 = S3::Object.send(:new, bucket1, :key => "Lena.png")
    expected = "http://images.example.com/Lena.png"
    actual = object11.cname_url
    assert_equal expected, actual

    object12 = S3::Object.send(:new, bucket1, :key => "Lena Söderberg.png")
    expected = "http://images.example.com/Lena%20S%C3%B6derberg.png"
    actual = object12.cname_url
    assert_equal expected, actual

    bucket2 = S3::Bucket.send(:new, @service, "images_new")

    object21 = S3::Object.send(:new, bucket2, :key => "Lena.png")
    expected = nil
    actual = object21.cname_url
    assert_equal expected, actual
  end

  test "destroy" do
    @object_lena.expects(:object_request).with(:delete)
    assert @object_lena.destroy
  end

  test "save" do
    @object_lena.expects(:object_request).with(:put, :body=>"test", :headers=>{ :x_amz_acl=>"public-read", :x_amz_storage_class=>"STANDARD", :content_type=>"application/octet-stream" }).returns(@response_binary)
    assert @object_lena.save
  end

  test "save with cache control headers" do
    assert_equal "max-age=315360000", @object_mac.cache_control
    @object_mac.expects(:object_request).with(:put, :body=>"test2", :headers=>{ :x_amz_acl=>"public-read", :x_amz_storage_class=>"STANDARD", :content_type=>"application/octet-stream", :cache_control=>"max-age=315360000" }).returns(@response_binary)
    assert @object_mac.save
  end

  test "content and parse headers" do
    @object_lena.expects(:object_request).with(:get, {}).returns(@response_binary)

    expected = /test/n
    actual = @object_lena.content(true)
    assert_match expected, actual
    assert_equal "image/png", @object_lena.content_type

    assert @object_lena.content

    @object_lena.expects(:object_request).with(:get, {}).returns(@response_binary)
    assert @object_lena.content(true)
  end

  test "retrieve" do
    @object_lena.expects(:object_request).with(:head, {}).returns(@response_binary)
    assert @object_lena.retrieve
  end

  test "retrieve headers" do
    @object_lena.expects(:object_request).twice.with(:head, {}).returns(@response_binary)
    assert @object_lena.retrieve

    meta = {"x-amz-meta-test" => ["metadata"]}
    assert_equal meta, @object_lena.retrieve.metadata
  end

  test "exists" do
    @object_lena.expects(:retrieve).returns(true)
    assert @object_lena.exists?

    @object_carmen.expects(:retrieve).raises(S3::Error::NoSuchKey.new(nil, nil))
    assert ! @object_carmen.exists?
  end

  test "ACL writer" do
    expected = nil
    actual = @object_lena.acl
    assert_equal expected, actual

    assert @object_lena.acl = :public_read

    expected = "public-read"
    actual = @object_lena.acl
    assert_equal expected, actual

    assert @object_lena.acl = :private

    expected = "private"
    actual = @object_lena.acl
    assert_equal expected, actual
  end

  test "storage-class writer" do
    expected = nil
    actual = @object_lena.storage_class
    assert_equal expected, actual

    assert @object_lena.storage_class = :standard

    expected = "STANDARD"
    actual = @object_lena.storage_class
    assert_equal expected, actual

    assert @object_lena.storage_class = :reduced_redundancy

    expected = "REDUCED_REDUNDANCY"
    actual = @object_lena.storage_class
    assert_equal expected, actual
  end

  test "replace" do
    @bucket_images.expects(:bucket_request).with(:put, :path => "Lena-copy.png", :headers => { :x_amz_acl => "public-read", :content_type => "application/octet-stream", :x_amz_copy_source => "images/Lena.png", :x_amz_metadata_directive => "REPLACE" }).returns(@response_xml)

    new_object = @object_lena.copy(:key => "Lena-copy.png")

    assert_equal "Lena-copy.png", new_object.key
    assert_equal "Lena.png", @object_lena.key
  end

  test "copy" do
    @bucket_images.expects(:bucket_request).with(:put, :path => "Lena-copy.png", :headers => { :x_amz_acl => "public-read", :content_type => "application/octet-stream", :x_amz_copy_source => "images/Lena.png", :x_amz_metadata_directive => "COPY" }).returns(@response_xml)

    new_object = @object_lena.copy(:key => "Lena-copy.png", :replace => false)

    assert_equal "Lena-copy.png", new_object.key
    assert_equal "Lena.png", @object_lena.key
  end
end
