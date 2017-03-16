-module(mu_api_questionnaires).

-export([init/2]).

-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_questionnaires_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(nonempty_list()) -> boolean().

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      handle_questionnaires_api(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_handler,0, Req0, State)
  end.

handle_questionnaires_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if question is send

  case check_args(Args) of
    false -> http_request_util:cowboy_out(mu_json_handler,2, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    true -> http_request_util:cowboy_out(mu_json_handler,#{}, Req0, State)
  end.

check_args(Args) ->
  % get username and password
  Question = proplists:get_value(<<"question">>, Args),
  case Question of
    <<>> -> false;
    _ -> true
  end.
