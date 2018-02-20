require "openssl/hmac"
require "http/request"
require "base64"
require "json"

module App::Marketing
  # Module for common webhook logic, namely asserting webhook payload
  # authenticity via HMAC SHA256 hash.
  module Webhook
    TIME_FORMAT = Time::Format.new("%FT%X")

    # Verifies that an `HTTP::Request` is authentic by hashing the response body
    # (HMAC-SHA256) with the given `key` and checking it against the received
    # `X-WC-Webhook-Signature` header. Raises `BadWebhookSignature` if it fails.
    def self.verify(body : String, signature : String, secret : String)
      hash = OpenSSL::HMAC.digest(:sha256, secret, body)
      signature = Base64.decode(signature)

      hash == signature || raise BadWebhookSignature.new(
        "Bad webhook payload or signature")
    end
  end

  # Exception raised when a request with a mismatching signature is handled
  class BadWebhookSignature < Exception
  end

  # Struct for parsing payloads from `order.created` webhooks
  struct OrderCreatedPayload
    # ID of this resource
    getter id

    # When this order was created
    getter created_at

    # The product IDs that were ordered
    getter product_ids

    # Customer email
    getter email

    def self.from_json(string_or_io : String | IO)
      parser = JSON::PullParser.new(string_or_io)
      new(parser)
    end

    def initialize(parser : JSON::PullParser)
      id, created_at, email = nil, nil, nil
      product_ids = [] of Int64

      parser.read_object do |key|
        case key
        when "id"
          id = parser.read_int
        when "date_created"
          created_at = Webhook::TIME_FORMAT.parse(parser.read_string)
        when "line_items"
          parser.read_array do
            parser.on_key("product_id") { product_ids << parser.read_int }
          end
        when "billing"
          parser.on_key("email") do
            email = parser.read_string
          end
        else
          parser.skip
        end
      end

      @id = id.as(Int64)
      @created_at = created_at.as(Time)
      @product_ids = product_ids.as(Array(Int64))
      @email = email.as(String)
    end
  end
end
