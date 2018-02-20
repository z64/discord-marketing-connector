-- +micrate Up
CREATE EXTENSION pgcrypto;

CREATE TABLE customers(
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  joined_at TIMESTAMPTZ,
  token TEXT,
  discord_id NUMERIC(20, 0) UNIQUE
);

-- +micrate Down
DROP TABLE customers;
DROP EXTENSION pgcrypto;
