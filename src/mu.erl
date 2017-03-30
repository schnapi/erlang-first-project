-module(mu).

-export([start/0]).

-include("../include/mu.hrl").

start() ->
  application:ensure_all_started(mu),
  mu_db:connect(),
ok.
