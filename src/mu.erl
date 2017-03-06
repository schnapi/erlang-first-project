-module(mu).
-include("../include/mu.hrl").

-export([start/0]).

start() ->
  application:ensure_all_started(mu),
ok.
