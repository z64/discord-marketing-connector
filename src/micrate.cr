require "micrate"
require "pg"

require "./mediaitc/config"

# Configure micrate environment
config = App::Config.from_file("config.yml")
Micrate::DB.connection_url = config.database_url

# Micrate v0.3.0 hardocdes the migrations path.
# The methods here are redfined to use the top-level "db" folder.
def Micrate.migrations_dir
  "db"
end

def Micrate.migrations_by_version
  Dir.entries(migrations_dir)
     .select { |name| File.file? File.join("db", name) }
     .select { |name| /^\d+_.+\.sql$/ =~ name }
     .map { |name| Migration.from_file(name) }
     .index_by { |migration| migration.version }
end

# Enable CLI
Micrate::Cli.run
