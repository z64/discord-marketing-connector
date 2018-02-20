require "oauth2"

module App::Middleware
  # Middleware for verifying HTTP request properties before passing off to the
  # final HTTP handler.
  class VerifyWebhook < Raze::Handler
    # Set of required headers for a successful payload parsing
    REQUIRED_HEADERS = {
      "X-WC-Webhook-Topic",
      "X-WC-Webhook-Source",
      "X-WC-Webhook-Signature",
      "X-WC-Webhook-Resource",
    }

    def initialize(@topic : String, @source : String, @secret : String,
                   @resource : String)
    end

    def call(ctx, done)
      request = ctx.request

      # Check all headers present
      REQUIRED_HEADERS.each do |header|
        unless value = request.headers[header]?
          ctx.halt_plain "Missing header: #{header}", 200
          return
        end
      end

      # Check webhook source
      unless request.headers["X-WC-Webhook-Source"] == @source
        ctx.halt_plain "Unauthorized source", 200
        return
      end

      # Check webhook topic
      unless request.headers["X-WC-Webhook-Topic"] == @topic
        ctx.halt_plain "Invalid webhook topic for this route", 200
        return
      end

      # Check webhook topic
      unless request.headers["X-WC-Webhook-Resource"] == @resource
        ctx.halt_plain "Invalid resource type for this route", 200
        return
      end

      # Check webhook body presence
      if body = request.body
        ctx.state["payload"] = body.gets_to_end
      else
        ctx.halt_plain "Empty body", 200
        return
      end

      # Validate body authenticity
      begin
        App::Marketing::Webhook.verify(
          ctx.state["payload"].as(String),
          request.headers["X-WC-Webhook-Signature"],
          @secret)
      rescue App::Marketing::BadWebhookSignature
        ctx.halt_plain "Corrupt webhook payload", 200
        return
      end

      done.call
    end
  end

  # Middleware for completing a Discord OAuth2 flow
  # TODO: Verify via state
  class DiscordOAuth2 < Raze::Handler
    def initialize(client_id : String, client_secret : String,
                   redirect_uri : String)
      @client = OAuth2::Client.new("discordapp.com/api/v6",
        client_id,
        client_secret,
        redirect_uri: redirect_uri)
    end

    def call(ctx, done)
      if code = ctx.request.query_params["code"]?
        response = @client.get_access_token_using_authorization_code(code)
        ctx.state["token"] = response.access_token
        done.call
      else
        ctx.halt_plain "Missing code", 400
      end
    end
  end
end
