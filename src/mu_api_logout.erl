-module(mu_api_logout).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_logout_api(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler, 0, Req0, State)
  end.

handle_logout_api(Req, State) ->
  case mu_sessions:check_session_validation(Req) of
    {ok} ->
      {ok, SessionId} = mu_sessions:get_sessionid(Req),
      {ok, Pid} = mu_sessions:get_session_pid(SessionId),
      % clear session's additional data
      ets:delete(mu_sessions, SessionId),
      mu_db:delete_session_record(SessionId),
      mu_session:logout(Pid),
      http_request_util:cowboy_out(mu_json_success_handler, true, Req, State);
    {false} ->
      http_request_util:cowboy_out(mu_json_error_handler, 8, Req, State)
  end.
