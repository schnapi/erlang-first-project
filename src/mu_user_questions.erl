-module(mu_user_questions).

-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      handle_questions_api(Req0, State);
    <<"GET">> ->
      handle_questions_api(Req0, State);
    _ ->
      respond_questions_error(Req0, State, 0)
  end.

handle_questions_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  % Args = bjson:decode(Body),
  % check if question is send

  % case check_args(Args) of
    % false -> respond_questions_error(Req0, State, 1);
    % todo: implement gen_server for sessions, call it at this point
  respond_questions_success(Req0, State).
  % end.

check_args(Args) ->
  % get username and password
  Question = proplists:get_value(<<"question">>, Args),
  case Question of
    <<>> -> false;
    _ -> true
  end.

respond_questions_success(Req0, State) ->
  % sending json response
  Reply = jsx:encode(#{<<"result">> => <<"true">>}),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_questions_error(Req0, State, ErrCode) ->
  % sending error response
  case ErrCode of
    1 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Question is empty!">>});
    0 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Wrong request method">>})
  end,
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply, Req0),
  {ok, Req, State}.
