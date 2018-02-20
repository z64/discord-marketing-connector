require "./mediaitc"

# Render internal server error
error 500 do |ctx, ex|
  render("views/error.slang")
end

# Create order webhook handler
post("/webhook/create_order",
  App::Middleware::VerifyWebhook.new(
    "order.created",
    App.config.webhook_source,
    App.config.webhook_secret,
    "order")) do |ctx|
  # Cast body from middleware guarentee
  body = ctx.state["payload"].as(String)

  # Parse the payload, and send it off to be handled
  payload = App::Marketing::OrderCreatedPayload.from_json(body)
  App.handle_order_create(payload)

  # Response
  ctx.status_code = 200
  "OK"
end

get("/discord") do |ctx|
  params = HTTP::Params.build do |form|
    form.add "client_id", App.config.client_id.to_s
    form.add "redirect_uri", App.config.host + "/oauth2/discord"
    form.add "scope", "identify email guilds.join"
    form.add "response_type", "code"
  end

  authorize_url = "https://discordapp.com/oauth2/authorize?#{params}"
  render("views/index.slang")
end

get("/oauth2/discord",
  App::Middleware::DiscordOAuth2.new(
    App.config.client_id,
    App.config.client_secret,
    App.config.host + "/oauth2/discord")) do |ctx|
  token = ctx.state["token"].as(String)

  # Resolve the user from Discord
  response = HTTP::Client.get(
    "#{Discord::REST::API_BASE}/users/@me",
    HTTP::Headers{
      "User-Agent"    => "App",
      "Authorization" => "Bearer #{token}",
    })
  user = Discord::User.from_json(response.body)

  begin
    if user.email
      # Update database logs
      App.handle_discord_user_authorized(token, user)

      # Join the user to the Discord guild
      App.discord.add_guild_member(
        App.config.guild_id,
        user.id,
        token)

      "Welcome!"
    else
      message = <<-MESSAGE
        You don't have an email address listed on your Discord account.
        Please verify your account on Discord.
        MESSAGE

      render("views/customer_not_found.slang")
    end
  rescue ex : App::CustomerNotFound
    message = <<-MESSAGE
      Looks like you currently are not a App customer, or we don't have your email on file yet.
      MESSAGE

    render("views/customer_not_found.slang")
  end
end

Raze.config.port = 9292
Raze.config.host = "0.0.0.0"

Raze.run
