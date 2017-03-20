-module(mu_db).

-export([connect/0]).
-export([get_all_users/0]).
-export([insert_user/0]).
-export([check_schema/0, upgrade_schema/0]).

connect() ->
  mu_db_schema:setup(), % we initialize the myapp_db_schema as module for managing the schema
  PoolInfo = [{size, 10}, {max_overflow, 5}],
  DataConnection = {data_connection, PoolInfo, [ [{hostname, "localhost"}, {port, 33306}, {username, "root"}, {password, "mocenum"}] ]},
  actordb_client:start([ DataConnection ]).

get_all_users() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single(Config, <<"mocenum">>, <<"system">>, <<"SELECT * FROM user;">>, [create]).

insert_user() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single_param(Config, <<"mocenum">>, <<"system">>, <<"INSERT INTO user VALUES(?1);">>, [create], [[<<"matic">>]]).

% see: actordb_client:exec_single_param(ConnectionCfg, ActorId, ActorType, Sql, Flags, Binds),

check_schema() ->
  % prints out the schema upgrade statements
  mu_db_schema:check().

upgrade_schema() ->
  % upgrades the schema
  mu_db_schema:upgrade().
