-module(mu_handler).

-export([init/2]).

-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.

init(Req0, State) ->
  Path = cowboy_req:path(Req0),
  lager:debug("path accessed: ~p",[Path]),
  % Version = cowboy_req:version(Req).
  % URI = cowboy_req:uri(Req) %https://ninenines.eu/docs/en/cowboy/2.0/guide/req/
  % URL for bindings, Query parameters parsing,header,peer address and port number
  % HostInfo = cowboy_req:host_info(Req).
  {ok, Req, State} = http_request_util:cowboy_out(mu_path_handler,Path, Req0, State).
