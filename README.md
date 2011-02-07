# S3

S3 library provides access to [Amazon's Simple Storage Service](http://aws.amazon.com/s3/).

It supports both: European and US buckets through the [REST API](http://docs.amazonwebservices.com/AmazonS3/latest/API/APIRest.html).

<a href="http://pledgie.com/campaigns/14173"><img alt="Click here to lend your support to: S3 and make a donation at www.pledgie.com!" src="http://pledgie.com/campaigns/14173.png?skin_name=chrome" border="0" /></a>

## Installation

    gem install s3

## Usage

    require "s3"
    service = S3::Service.new(:access_key_id => "...",
                              :secret_access_key => "...")
    #=> #<S3::Service:...>

    service.buckets
    #=> [#<S3::Bucket:first-bucket>,
    #    #<S3::Bucket:second-bucket>]

    first_bucket = service.buckets.find("first-bucket")
    #=> #<S3::Bucket:first-bucket>

    first_bucket.objects
    #=> [#<S3::Object:/first-bucket/lenna.png>,
    #    #<S3::Object:/first-bucket/lenna_mini.png>]

    object = first_bucket.objects.find("lenna.png")
    #=> #<S3::Object:/first-bucket/lenna.png>

    object.content_type
    #=> "image/png"

    object.content
    #=> "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00..."

    object.destroy
    #=> true

    new_object = bucket.objects.build("bender.png")
    #=> #<S3::Object:/synergy-staging/bender.png>

    new_object.content = open("bender.png")

    new_object.save
    #=> true

## See also

* [gemcutter](http://gemcutter.org/gems/s3)
* [repository](http://github.com/qoobaa/s3)
* [issue tracker](http://github.com/qoobaa/s3/issues)
* [documentation](http://qoobaa.github.com/s3)

## Copyright

Copyright (c) 2009 Jakub Kuźma, Mirosław Boruta. See [LICENSE](http://github.com/qoobaa/s3/raw/master/LICENSE) for details.
