module S3
  module Error

    # All responses with a code between 300 and 599 that contain an
    # <Error></Error> body are wrapped in an ErrorResponse which
    # contains an Error object. This Error class generates a custom
    # exception with the name of the xml Error and its message. All
    # such runtime generated exception classes descend from
    # ResponseError and contain the ErrorResponse object so that all
    # code that makes a request can rescue ResponseError and get
    # access to the ErrorResponse.
    class ResponseError < StandardError
      attr_reader :response

      # Creates new S3::ResponseError.
      #
      # ==== Parameters
      # * <tt>message</tt> - what went wrong
      # * <tt>response</tt> - Net::HTTPResponse object or nil
      def initialize(message, response)
        @response = response
        super(message)
      end

      # Factory for all other Exception classes in module, each for
      # every error response available from AmazonAWS
      #
      # ==== Parameters
      # * <tt>code</tt> - Code name of exception
      #
      # ==== Returns
      # Descendant of ResponseError suitable for that exception code
      # or ResponseError class if no class found
      def self.exception(code)
        S3::Error.const_get(code)
      rescue NameError
        ResponseError
      end
    end

    #:stopdoc:

    class AccessDenied < ResponseError; end
    class AccountProblem < ResponseError; end
    class AmbiguousGrantByEmailAddress < ResponseError; end
    class BadDigest < ResponseError; end
    class BucketAlreadyExists < ResponseError; end
    class BucketAlreadyOwnedByYou < ResponseError; end
    class BucketNotEmpty < ResponseError; end
    class CredentialsNotSupported < ResponseError; end
    class CrossLocationLoggingProhibited < ResponseError; end
    class EntityTooSmall < ResponseError; end
    class EntityTooLarge < ResponseError; end
    class ExpiredToken < ResponseError; end
    class ForbiddenBucket < ResponseError; end
    class IncompleteBody < ResponseError; end
    class IncorrectNumberOfFilesInPostRequestPOST < ResponseError; end
    class InlineDataTooLarge < ResponseError; end
    class InternalError < ResponseError; end
    class InvalidAccessKeyId < ResponseError; end
    class InvalidAddressingHeader < ResponseError; end
    class InvalidArgument < ResponseError; end
    class InvalidBucketName < ResponseError; end
    class InvalidDigest < ResponseError; end
    class InvalidLocationConstraint < ResponseError; end
    class InvalidPayer < ResponseError; end
    class InvalidPolicyDocument < ResponseError; end
    class InvalidRange < ResponseError; end
    class InvalidSecurity < ResponseError; end
    class InvalidSOAPRequest < ResponseError; end
    class InvalidStorageClass < ResponseError; end
    class InvalidTargetBucketForLogging < ResponseError; end
    class InvalidToken < ResponseError; end
    class InvalidURI < ResponseError; end
    class KeyTooLong < ResponseError; end
    class MalformedACLError < ResponseError; end
    class MalformedACLError < ResponseError; end
    class MalformedPOSTRequest < ResponseError; end
    class MalformedXML < ResponseError; end
    class MaxMessageLengthExceeded < ResponseError; end
    class MaxPostPreDataLengthExceededErrorYour < ResponseError; end
    class MetadataTooLarge < ResponseError; end
    class MethodNotAllowed < ResponseError; end
    class MissingAttachment < ResponseError; end
    class MissingContentLength < ResponseError; end
    class MissingRequestBodyError < ResponseError; end
    class MissingSecurityElement < ResponseError; end
    class MissingSecurityHeader < ResponseError; end
    class NoLoggingStatusForKey < ResponseError; end
    class NoSuchBucket < ResponseError; end
    class NoSuchKey < ResponseError; end
    class NotImplemented < ResponseError; end
    class NotSignedUp < ResponseError; end
    class OperationAborted < ResponseError; end
    class PermanentRedirect < ResponseError; end
    class PreconditionFailed < ResponseError; end
    class Redirect < ResponseError; end
    class RequestIsNotMultiPartContent < ResponseError; end
    class RequestTimeout < ResponseError; end
    class RequestTimeTooSkewed < ResponseError; end
    class RequestTorrentOfBucketError < ResponseError; end
    class SignatureDoesNotMatch < ResponseError; end
    class SlowDown < ResponseError; end
    class TemporaryRedirect < ResponseError; end
    class TokenRefreshRequired < ResponseError; end
    class TooManyBuckets < ResponseError; end
    class UnexpectedContent < ResponseError; end
    class UnresolvableGrantByEmailAddress < ResponseError; end
    class UserKeyMustBeSpecified < ResponseError; end
  end
end
