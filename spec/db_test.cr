require "./src/mediaitc/database"

module App
  puts "Connecting..."
  db = DB.new("postgresql://user:pass@localhost")
  begin
    puts "Creating customer"
    pp db.create_customer("foo@bar.com")

    puts "Updating customer"
    pp db.update_customer("foo@bar.com", Time.now, "token", 1_u64)

    puts "Fetching customer"
    pp db.get_customer("foo@bar.com")

    puts "Deleting customer"
    pp db.delete_customer("foo@bar.com")
  ensure
    db.db.close
  end
end
