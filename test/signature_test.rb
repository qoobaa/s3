require 'test_helper'

class SignatureTest < Test::Unit::TestCase
  # from http://docs.amazonwebservices.com/AmazonS3/latest/RESTAuthentication.html
  def test_signature_for_object_get
    request = Net::HTTP::Get.new("/photos/puppy.jpg")
    request["host"] = "johnsmith.s3.amazonaws.com"
    request["date"] = "Tue, 27 Mar 2007 19:36:42 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:xXjDGYUmKxnwqr5KXNPGldn5LbA="
    assert_equal expected, actual
  end

  def test_signature_for_object_put
    request = Net::HTTP::Put.new("/photos/puppy.jpg");
    request["content-type"] = "image/jpeg"
    request["content-length"] = "94328"
    request["host"] = "johnsmith.s3.amazonaws.com"
    request["date"] = "Tue, 27 Mar 2007 21:15:45 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:hcicpDDvL9SsO6AkvxqmIWkmOuQ="
    assert_equal expected, actual
  end

  def test_signature_for_list
    request = Net::HTTP::Get.new("/?prefix=photos&max-keys=50&marker=puppy");
    request["user-agent"] = "Mozilla/5.0"
    request["host"] = "johnsmith.s3.amazonaws.com"
    request["date"] = "Tue, 27 Mar 2007 19:42:41 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:jsRt/rhG+Vtp88HrYL706QhE4w4="
    assert_equal expected, actual
  end

  def test_signature_for_fetch
    request = Net::HTTP::Get.new("/?acl");
    request["host"] = "johnsmith.s3.amazonaws.com"
    request["date"] = "Tue, 27 Mar 2007 19:44:46 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:thdUi9VAkzhkniLj96JIrOPGi0g="
    assert_equal expected, actual
  end

  def test_signature_for_delete
    request = Net::HTTP::Delete.new("/johnsmith/photos/puppy.jpg");
    request["user-agent"] = "dotnet"
    request["host"] = "s3.amazonaws.com"
    request["date"] = "Tue, 27 Mar 2007 21:20:27 +0000"
    request["x-amz-date"] = "Tue, 27 Mar 2007 21:20:26 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:k3nL7gH3+PadhTEVn5Ip83xlYzk="
    assert_equal expected, actual
  end

  def test_signature_for_upload
    request = Net::HTTP::Put.new("/db-backup.dat.gz");
    request["user-agent"] = "curl/7.15.5"
    request["host"] = "static.johnsmith.net:8080"
    request["date"] = "Tue, 27 Mar 2007 21:06:08 +0000"
    request["x-amz-acl"] = "public-read"
    request["content-type"] = "application/x-download"
    request["content-MD5"] = "4gJE4saaMU4BqNR0kLY+lw=="
    # TODO:
    # was:
    #request["x-amz-meta-reviewedby"] = "joe@johnsmith.net"
    #request["x-amz-meta-reviewedby"] = "jane@johnsmith.net"
    request["x-amz-meta-reviewedby"] = "joe@johnsmith.net,jane@johnsmith.net"
    request["x-amz-meta-filechecksum"] = "0x02661779"
    request["x-amz-meta-checksumalgorithm"] = "crc32"
    request["content-disposition"] = "attachment; filename=database.dat"
    request["content-encoding"] = "gzip"
    request["content-length"] = "5913339"

    actual = S3::Signature.generate(
      :host => "static.johnsmith.net",
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:C0FlOtU8Ylb9KDTpZqYkZPX91iI="
    assert_equal expected, actual
  end

  def test_signature_for_list_all_my_buckets
    request = Net::HTTP::Get.new("/");
    request["host"] = "s3.amazonaws.com"
    request["date"] = "Wed, 28 Mar 2007 01:29:59 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:Db+gepJSUbZKwpx1FR0DLtEYoZA="
    assert_equal expected, actual
  end

  def test_signature_for_unicode_keys
    request = Net::HTTP::Get.new("/dictionary/fran%C3%A7ais/pr%c3%a9f%c3%a8re");
    request["host"] = "s3.amazonaws.com"
    request["date"] = "Wed, 28 Mar 2007 01:49:49 +0000"

    actual = S3::Signature.generate(
      :host => request["host"],
      :request => request,
      :access_key_id => "0PN5J17HBGZHT7JJ3X82",
      :secret_access_key => "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    )
    expected = "AWS 0PN5J17HBGZHT7JJ3X82:dxhSBHoI6eVSPcXJqEghlUzZMnY="
    assert_equal expected, actual
  end
end
