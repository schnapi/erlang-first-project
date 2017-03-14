-module(mu_api_questionnaires).

-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      handle_questionnaires_api(Req0, State);
    _ ->
      mu_respond:respond_error(Req0, State,0)
  end.

handle_questionnaires_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % check if question is send

  case check_args(Args) of
    false -> mu_respond:respond_error(Req0, State, "Question is empty!");
    % todo: implement gen_server for sessions, call it at this point
    true -> mu_respond:respond_success(Req0, State)
  end.

check_args(Args) ->
  % get username and password
  Question = proplists:get_value(<<"question">>, Args),
  case Question of
    <<>> -> false;
    _ -> true
  end.
