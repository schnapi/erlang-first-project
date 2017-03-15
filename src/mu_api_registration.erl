-module(mu_api_registration).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_registration_api(Req0, State);
    _ ->
      mu_respond:respond_error(Req0, State,1)
  end.

handle_registration_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if username and password are sent
  case check_args(Args) of
    false -> mu_respond:respond_error(Req0, State, 1);
    % todo: implement gen_server for sessions, call it at this point
    true -> mu_respond:respond_success(Req0, State)
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
