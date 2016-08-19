= S3

{<img src="https://travis-ci.org/qoobaa/s3.svg?branch=master" alt="Build Status" />}[https://travis-ci.org/qoobaa/s3]

S3 library provides access to {Amazon's Simple Storage Service}[http://aws.amazon.com/s3/].

It supports *all* S3 regions through the {REST API}[http://docs.amazonwebservices.com/AmazonS3/latest/API/APIRest.html].

== Installation

    gem install s3

== Usage

=== Initialize the service

    require "s3"
    service = S3::Service.new(:access_key_id => "...",
                              :secret_access_key => "...")
    #=> #<S3::Service:...>

=== List buckets

    service.buckets
    #=> [#<S3::Bucket:first-bucket>,
    #    #<S3::Bucket:second-bucket>]

=== Find bucket

    first_bucket = service.buckets.find("first-bucket")
    #=> #<S3::Bucket:first-bucket>

or

    first_bucket = service.bucket("first-bucket")
    #=> #<S3::Bucket:first-bucket>

<tt>service.bucket("first-bucket")</tt> does not check whether a bucket with the name <tt>"first-bucket"</tt> exists, but it also does not issue any HTTP requests. Thus, the second example is much faster than <tt>buckets.find</tt>. You can use <tt>first_bucket.exists?</tt> to check whether the bucket exists after calling <tt>service.bucket</tt>.

=== Create bucket

    new_bucket = service.buckets.build("newbucketname")
    new_bucket.save(:location => :eu)

Remember that bucket name for EU can't include "_" (underscore).

Please refer to: http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html for more information about bucket name restrictions.

=== List objects in a bucket

    first_bucket.objects
    #=> [#<S3::Object:/first-bucket/lenna.png>,
    #    #<S3::Object:/first-bucket/lenna_mini.png>]

=== Find object in a bucket

    object = first_bucket.objects.find("lenna.png")
    #=> #<S3::Object:/first-bucket/lenna.png>

=== Access object metadata (cached from find)

    object.content_type
    #=> "image/png"

=== Access object content (downloads the object)

    object.content
    #=> "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00..."

=== Delete an object

    object.destroy
    #=> true

=== Create an object

    new_object = bucket.objects.build("bender.png")
    #=> #<S3::Object:/synergy-staging/bender.png>

    new_object.content = open("bender.png")

    new_object.acl = :public_read

    new_object.save
    #=> true

Please note that new objects are created with "private" ACL by
default.

=== Request access to a private object

Returns a temporary url to the object that expires on the timestamp given. Defaults to one hour expire time.

    new_object.temporary_url(Time.now + 1800)

=== Fetch ACL

   object = bucket.objects.find('lenna.png')
   object.request_acl # or bucket.request_acl

This will return hash with all users/groups and theirs permissions

=== Modify ACL

   object = bucket.objects.find("lenna.png")
   object.copy(:key => "lenna.png", :bucket => bucket, :acl => :public_read)

=== Upload file direct to amazon

==== Rails 3

Check the {example in this gist}[https://gist.github.com/3169039], which describes how to use
a simple form element to upload files directly to S3.

== See also

* rubygems[http://rubygems.org/gems/s3]
* repository[http://github.com/qoobaa/s3]
* {issue tracker}[http://github.com/qoobaa/s3/issues]
* documentation[http://rubydoc.info/github/qoobaa/s3/master/frames]

== Copyright

Copyright (c) 2009 Jakub Kuźma, Mirosław Boruta. See LICENSE[http://github.com/qoobaa/s3/raw/master/LICENSE] for details.
