-module(mu_api_thoughts).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post thoughts
    <<"POST">> ->
      save_thought(Req0, State);
    <<"GET">> ->
      get_thoughts(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler, 0, Req0, State)
  end.

save_thought(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  Thought = proplists:get_value(<<"thought">>, bjson:decode(Body)),
  case Thought of
    undefined ->
      lager:debug("ni vnesene misli ", []);
    _ ->
      {ok, SessionId} = mu_sessions:get_sessionid(Req0),
      {UserID} = mu_sessions:get_userid_from_session(SessionId),
      {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:now_to_datetime(erlang:now()),
      StrTime = butil:datetime_to_string({{Day, Month, Year}, {Hour, Minute, Second}}),
      mu_db:insert_new_thought(UserID, Thought, StrTime),
      http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
  end.

get_thoughts(Req0, State) ->
  {ok, SessionId} = mu_sessions:get_sessionid(Req0),
  {UserID} = mu_sessions:get_userid_from_session(SessionId),
  Thoughts = mu_db:get_all_thoughts(UserID),
  http_request_util:cowboy_out(mu_json_success_handler, Thoughts , Req0, State).
