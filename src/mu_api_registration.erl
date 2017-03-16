-module(mu_api_registration).

-export([init/2]).

-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_registration_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(nonempty_list()) -> boolean().

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_registration_api(Req0, State);
    _ -> http_request_util:cowboy_out(mu_json_error_handler,1, Req0, State)
  end.

handle_registration_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if username and password are sent
  case check_args(Args) of
    false -> http_request_util:cowboy_out(mu_json_error_handler,1, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    true -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
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
