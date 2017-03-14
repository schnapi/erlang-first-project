-module(http_request_util).
-include("../include/mu.hrl").

-export([cowboy_out/4]).

cowboy_out(Module,Path, Req0, State) ->
  Pgr = Module:out(Path,Req0),
  % Pgr = #{ status => 404…, headers=> ,… body => … }
  % Pgr = #{ status => 404…, headers=> ,… json_body => [ #{ <<”data”>> => <<”super”>> } ] }

  % lager:debug("req: ~p",[maps:get(status, Pgr)]),
  % lager:debug("req: ~p",[maps:get(headers, Pgr)]),
  % lager:debug("req: ~p",[maps:get(body, Pgr)]),


  Req = cowboy_req:reply(maps:get(status, Pgr), maps:get(headers, Pgr), maps:get(body, Pgr) , Req0),
  lager:debug("test: ~p",[maps:get(body, Pgr)]),
  % Req = cowboy_req:reply(maps:get(status, Pgr), masp:get(headers, Pgr), maps:get(body, Pgr) , Req0),
% Req = cowboy_req:reply(get(status, Pgr), #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.
