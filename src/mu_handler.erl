-module(mu_handler).

-export([init/2]).

-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.

init(Req0, State) ->
  Path = cowboy_req:path(Req0),
  lager:debug("path accessed: ~p",[Path]),
  % routing and validating session
  case Path of
    <<"/registration">> ->
      {ok, _, _} = http_request_util:cowboy_out(mu_path_handler,Path, Req0, State);
    _ ->
      case mu_sessions:check_session_validation(Req0) of
        {ok} ->
          case Path of
            <<"/login">> ->
              {ok, _, _} = http_request_util:cowboy_out(mu_path_handler, <<"/">>, Req0, State);
            _ ->
              {ok, _, _} = http_request_util:cowboy_out(mu_path_handler,Path, Req0, State)
          end;
        {false} ->
          case Path of
            <<"/login">> ->
              {ok, _, _} = http_request_util:cowboy_out(mu_path_handler,Path, Req0, State);
            _ ->
              {ok, _, _} = http_request_util:cowboy_out(mu_json_error_handler, 302, Req0, State)
          end
      end
  end.
  % Version = cowboy_req:version(Req).
  % URI = cowboy_req:uri(Req) %https://ninenines.eu/docs/en/cowboy/2.0/guide/req/
  % URL for bindings, Query parameters parsing,header,peer address and port number
  % HostInfo = cowboy_req:host_info(Req).
  %{ok, Req, State} = http_request_util:cowboy_out(mu_path_handler,Path, Req0, State).
