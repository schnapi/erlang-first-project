-module(mu_api_generic).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_login_api(Req0, State);
    _ ->
      respond_login_error(Req0, State, 0)
  end.

handle_login_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  Cookies = cowboy_req:parse_cookies(Req0),
  % check if username and password are sent
  case check_args(Args) of
    false -> respond_login_error(Req0, State, 1);
    % before creating new session check if there already exists one
    true -> respond_login_success(Req0, State, Args)
  end.

check_args(Args) ->
  % get username and password
  Username = proplists:get_value(<<"username">>, Args),
  Password = proplists:get_value(<<"password">>, Args),
  case {Username, Password} of
    {undefined, _} -> false;
    {_, undefined} -> false;
    _ -> true
  end.

respond_login_success(Req0, State, Args) ->
  ValidateSession = mu_sessions:check_session_validation(Req0),
  case ValidateSession of
    % če ni veljavne seje jo ustvarim
    {false} ->
      lager:debug("ni veljavne seje"),
      #{peer := {Ip, _}} = Req0,
      Username = proplists:get_value(<<"username">>, Args),
      {SessionId, Pid} = mu_sessions:create_new_session(Ip, Username),
      {ok, Req2} = mu_sessions:set_sessionid(Req0, SessionId),
      Reply = jsx:encode(#{<<"result">> => <<"true">>}),
      Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req2),
      {ok, Req, State};
    % če je veljavna seja vrnem true, redirect na pageu
    {ok} ->
      lager:debug("je veljavna seja"),
      Reply = jsx:encode(#{<<"result">> => <<"true">>}),
      Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
      {ok, Req, State}
  end.

respond_login_error(Req0, State, ErrCode) ->
  % sending error response
  case ErrCode of
    1 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Missing username or/and password">>});
    0 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Wrong request method">>})
  end,
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply, Req0),
  {ok, Req, State}.
