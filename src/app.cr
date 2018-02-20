require "raze"
require "kilt/slang"
require "discordcr"
require "./mediaitc/*"

module App
  # Global app configuration
  class_getter config = Config.from_file("config.yml")

  # Database connection wrapper
  class_getter db = DB.new(config.database_url)
  at_exit { @@db.close }

  # Discord client
  class_getter discord = Discord::Client.new(config.bot_token)

  # Exception to raise on a database miss
  class CustomerNotFound < Exception
  end

  # Obfuscates a value with a configured secret
  def self.obfuscate(value : String)
    Base64.urlsafe_encode(OpenSSL::HMAC.digest(:sha256, App.config.database_secret, value))
  end

  def self.handle_order_create(payload : Marketing::OrderCreatedPayload)
    obfuscated_email = App.obfuscate(payload.email)

    # Store request in the database
    db.create_customer(
      obfuscated_email,
      payload.created_at)
  end

  def self.handle_discord_user_authorized(token : String, user : Discord::User)
    obfuscated_email = App.obfuscate(user.email.not_nil!)
    obfuscated_token = App.obfuscate(token)

    result = db.update_customer(
      obfuscated_email,
      Time.now,
      obfuscated_token,
      user.id)

    raise CustomerNotFound.new("Customer not found") if result.rows_affected.zero?
  end
end
