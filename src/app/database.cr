require "big"
require "pg"

module App
  class DB
    # Canned SQL queries
    # TODO: Crypto
    module Query
      CreateCustomer = <<-SQL
        INSERT INTO customers (email, created_at) VALUES ($1, $2) ON CONFLICT DO NOTHING;
        SQL

      UpdateCustomer = <<-SQL
        UPDATE customers SET
          joined_at  = $1,
          token      = $2,
          discord_id = $3
        WHERE
          email = $4;
        SQL

      GetCustomer = <<-SQL
        SELECT
          id,
          email,
          created_at,
          joined_at,
          token,
          discord_id
        FROM
          customers
        WHERE
          email = $1;
        SQL

      DeleteCustomer = <<-SQL
        DELETE FROM
          customers
        WHERE
          email = $1;
        SQL
    end

    struct Customer
      ::DB.mapping(
        id: Int32,
        email: String,
        created_at: Time,
        joined_at: Time?,
        token: String?,
        discord_id: PG::Numeric?
      )
    end

    # The active database connection pool
    getter db : ::DB::Database

    def initialize(url : String)
      @db = ::DB.open(url)
    end

    delegate close, to: @db

    # Inserts a new customer row with a given email
    def create_customer(email : String, created_at : Time)
      db.exec(Query::CreateCustomer, email, created_at)
    end

    # Updates a customer row with additional details, identified by email
    def update_customer(email : String, joined_at : Time, token : String,
                        discord_id : UInt64)
      db.exec(Query::UpdateCustomer, joined_at, token, discord_id, email)
    end

    # Fetches a customer row by email
    def get_customer(email : String)
      rs = db.query(Query::GetCustomer, email)
      Customer.from_rs(rs)
    end

    # Deletes a customer row by email
    def delete_customer(email : String)
      db.exec(Query::DeleteCustomer, email)
    end
  end
end
