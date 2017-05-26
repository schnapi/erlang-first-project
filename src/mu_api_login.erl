-module(mu_api_login).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_login_api(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler, 0, Req0, State)
  end.

handle_login_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if username and password are sent,
  case check_args(Args) of
    % error respond
    {false, ErrCode} -> http_request_util:cowboy_out(mu_json_error_handler,ErrCode, Req0, State);
    % handle session stuff and respond success
    true -> handle_session(Req0, State, Args)
  end.

check_args(Args) ->
  % get username and password
  Email = proplists:get_value(<<"email">>, Args),
  Password = proplists:get_value(<<"password">>, Args),
  case {Email, Password} of
    {undefined, _} -> {false, 1};
    {_, undefined} -> {false, 1};
    _ ->
      % preveri ujemanje maila in gesla
      case mu_db:check_user_password(Email, Password) of
        ok ->
          true;
        error ->
          {false, 7}
      end
  end.

% preveri se vejavnost seje, če je ni jo ustvarim, json respond
handle_session(Req0, State, Args) ->
  ValidateSession = mu_sessions:check_session_validation(Req0),
  case ValidateSession of
    % če ni veljavne seje jo ustvarim
    {false} ->
      #{peer := {Ip, _}} = Req0,
      Email = proplists:get_value(<<"email">>, Args),
      mu_sessions:destroy_sessions_for_specific_user(Email),
      {SessionId, _} = mu_sessions:create_new_session(Ip, Email),
      {ok, Req2} = mu_sessions:set_sessionid(Req0, SessionId),
      http_request_util:cowboy_out(mu_json_success_handler,true, Req2, State);
    % če je veljavna seja vrnem true, redirect na pageu
    {ok} ->
      http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
  end.
