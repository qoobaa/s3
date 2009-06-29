module S3
  class Exception < StandardError
  end

  # All responses with a code between 300 and 599 that contain an <Error></Error> body are wrapped in an
  # ErrorResponse which contains an Error object. This Error class generates a custom exception with the name
  # of the xml Error and its message. All such runtime generated exception classes descend from ResponseError
  # and contain the ErrorResponse object so that all code that makes a request can rescue ResponseError and get
  # access to the ErrorResponse.
  class ResponseError < Exception
    attr_reader :response
    def initialize(message, response)
      @response = response
      super(message)
    end
  end

  #:stopdoc:

  # Most ResponseError's are created just time on a need to have basis, but we explicitly define the
  # InternalError exception because we want to explicitly rescue InternalError in some cases.
  class InternalError < ResponseError
  end

  class NoSuchKey < ResponseError
  end

  class RequestTimeout < ResponseError
  end

  class NoSuchBucket < ResponseError
  end
end
