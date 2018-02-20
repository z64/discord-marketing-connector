require "yaml"

module App
  # YAML-mapped class for runtime configuration
  class Config
    YAML.mapping(
      host: String,
      webhook_source: String,
      webhook_secret: String,
      guild_id: UInt64,
      bot_token: String,
      client_id: String,
      client_secret: String,
      database_url: String,
      database_secret: String,
      roles: Array(UInt64)?
    )

    def self.from_file(filename : String)
      Config.from_yaml(File.read(filename))
    end
  end
end
