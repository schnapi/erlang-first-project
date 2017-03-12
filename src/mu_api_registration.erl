-module(mu_api_registration).

-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_registration_api(Req0, State);
    _ ->
      respond_registration_error(Req0, State, 0)
  end.

handle_registration_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if username and password are sent
  case check_args(Args) of
    false -> respond_registration_error(Req0, State, 1);
    % todo: implement gen_server for sessions, call it at this point
    true -> respond_registration_success(Req0, State)
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

respond_registration_success(Req0, State) ->
  % sending json response
  Reply = jsx:encode(#{<<"result">> => <<"true">>}),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_registration_error(Req0, State, ErrCode) ->
  % sending error response
  case ErrCode of
    1 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Missing username or/and password">>});
    0 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Wrong request method">>})
  end,
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply, Req0),
  {ok, Req, State}.
