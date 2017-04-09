-module(mu).

-export([start/0]).

-include("../include/mu.hrl").

start() ->
  application:ensure_all_started(mu),
  mu_db:connect(),
  mu_db:insert_user(<<"mocenum">>, <<"admin">>, <<"mocenum">>, {127,0,0,1}),
ok.
