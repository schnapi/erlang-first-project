-module(mu_handler).
-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  % lager:debug("req: ~p",[Req0]),
  Path = cowboy_req:path(Req0),
  lager:debug("path accessed: ~p",[Path]),
  % Version = cowboy_req:version(Req).
  % URI = cowboy_req:uri(Req) %https://ninenines.eu/docs/en/cowboy/2.0/guide/req/
  % URL for bindings, Query parameters parsing,header,peer address and port number
  % HostInfo = cowboy_req:host_info(Req).
  {ok, Req, State} = http_request_util:cowboy_out(bcs_mod,Path, Req0, State).
