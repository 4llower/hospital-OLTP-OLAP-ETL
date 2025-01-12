CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER IF NOT EXISTS oltp_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'oltp_db', port '5432');

CREATE USER MAPPING IF NOT EXISTS FOR current_user
SERVER oltp_server
OPTIONS (
  user 'postgres',
  password 'postgres'
);

CREATE SCHEMA IF NOT EXISTS fdw_oltp;

IMPORT FOREIGN SCHEMA public
  FROM SERVER oltp_server
  INTO fdw_oltp;