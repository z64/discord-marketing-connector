require "./spec_helper"

module App
  describe Config do
    it "parses from YAML" do
      yaml = <<-YAML
        ---
        host: host
        webhook_source: https://some_url.com
        webhook_secret: secret
        guild_id: 1
        bot_token: token
        client_id: '2'
        client_secret: foo
        database_url: some_url
        database_secret: secret
        roles:
          - 3
          - 4
          - 5
        YAML
      Config.from_yaml(yaml)
    end
  end
end
