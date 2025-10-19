-- Migration 0001 – create app_user table
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS app_user (
  id UUID PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  email TEXT UNIQUE,
  oidc_provider TEXT NOT NULL,
  oidc_sub TEXT NOT NULL,
  nickname TEXT,
  country CHAR(2),
  lang CHAR(2),
  status TEXT CHECK (status IN ('active','banned')) DEFAULT 'active'
);

CREATE UNIQUE INDEX IF NOT EXISTS app_user_oidc_provider_sub_idx
  ON app_user (oidc_provider, oidc_sub);

CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_timestamp ON app_user;
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON app_user
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
