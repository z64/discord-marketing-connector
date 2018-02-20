require "./spec_helper"

module App::Marketing
  describe Webhook do
    describe ".verify" do
      body = "json"

      signature = Base64.urlsafe_encode(
        String.new(OpenSSL::HMAC.digest(:sha256, "key", body))
      )

      it "verifies a good payload" do
        response = HTTP::Request.new(
          "POST",
          "foo",
          HTTP::Headers{"X-WC-Webhook-Signature" => signature},
          body)

        Webhook.verify(response, "key").should be_true
      end

      it "raises on a bad payload" do
        tampered_body = "tampered"

        response = HTTP::Request.new(
          "POST",
          "foo",
          HTTP::Headers{"X-WC-Webhook-Signature" => signature},
          tampered_body)

        expect_raises(BadWebhookSignature) do
          Webhook.verify(response, "key")
        end
      end
    end
  end

  describe OrderCreatedPayload do
    describe "#initialize" do
      it "initializes via .from_json" do
        webhook = OrderCreatedPayload.from_json <<-JSON
          {
            "id": 0,
            "date_created": "2017-03-22T16:28:02",
            "line_items": [
              {"product_id": 1},
              {"product_id": 2},
              {"product_id": 3}
            ],
            "billing": {
              "email": "foo@bar.com"
            }
          }
          JSON

        webhook.id.should eq 0_i64
        webhook.created_at.should eq Webhook::TIME_FORMAT.parse("2017-03-22T16:28:02")
        webhook.product_ids.should eq [1_i64, 2_i64, 3_i64]
        webhook.email.should eq "foo@bar.com"
      end
    end
  end
end
