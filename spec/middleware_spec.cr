require "./spec_helper"

class ContextStub
  getter request : HTTP::Request

  getter halt_string : String? = nil

  getter halt_code : Int32? = nil

  def initialize(headers : HTTP::Headers, body : String? = nil)
    @request = HTTP::Request.new(
      "POST",
      "resource",
      headers,
      body
    )
  end

  def halt_plain(string : String, code : Int32)
    @halt_string = string
    @halt_code = code
  end
end

def it_halts_with(mw, headers, body, message, code)
  it "halts with #{message} (#{code})" do
    ctx = ContextStub.new(headers, body)
    mw.call(ctx, ->{ true }).should be_falsey

    ctx.halt_string.should eq message
    ctx.halt_code.should eq code
  end
end

module App::Middleware
  describe VerifyWebhook do
    mw = VerifyWebhook.new("topic", "source", "secret", "resource")

    full_headers = HTTP::Headers{
      "X-WC-Webhook-Topic"     => "topic",
      "X-WC-Webhook-Source"    => "source",
      "X-WC-Webhook-Signature" => "",
      "X-WC-Webhook-Resource"  => "resource",
    }

    context "with missing header values" do
      VerifyWebhook::REQUIRED_HEADERS.each do |header|
        headers = full_headers.dup
        headers.delete(header)
        it_halts_with(mw, headers, nil, "Missing header: #{header}", 400)
      end
    end

    context "with mismatching header values" do
      headers = full_headers.dup
      headers["X-WC-Webhook-Source"] = "foo"
      it_halts_with(mw, headers, nil, "Unauthorized source", 401)

      headers = full_headers.dup
      headers["X-WC-Webhook-Topic"] = "foo"
      it_halts_with(mw, headers, nil, "Invalid webhook topic for this route", 400)

      headers = full_headers.dup
      headers["X-WC-Webhook-Resource"] = "foo"
      it_halts_with(mw, headers, nil, "Invalid resource type for this route", 400)
    end

    context "with an empty body" do
      it_halts_with(mw, full_headers, nil, "Empty body", 400)
    end

    context "with an unauthentic payload" do
      it_halts_with(mw, full_headers, "", "Corrupt webhook payload", 400)
    end

    context "with an authentic payload" do
      it "passes" do
        headers = full_headers.dup
        headers["X-WC-Webhook-Signature"] = Base64.urlsafe_encode(
          OpenSSL::HMAC.digest(:sha256, "secret", "body"))
        ctx = ContextStub.new(headers, "body")
        mw.call(ctx, ->{ true }).should be_true
      end
    end
  end
end
