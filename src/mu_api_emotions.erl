-module(mu_api_emotions).

-export([init/2]).

-include("../include/mu.hrl").

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      save_emotion(Req0, State);
    <<"GET">> ->
      handle_request(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler, 0, Req0, State)
  end.

% handle get method
handle_request(Req, State) ->
  Path = cowboy_req:path_info(Req),
  case Path of
    [] ->
      get_emotions(Req, State);
    _ ->
      case lists:nth(1, Path) of
        <<"users">> ->
          get_all_users_emotions(Req, State);
        <<"user">> ->
          get_user_emotions(Req, State, lists:nth(2, Path));
        _ ->
          http_request_util:cowboy_out(mu_json_error_handler, 0, Req, State)
      end
  end.

% save emotion for specific user
save_emotion(Req0, State) ->
  % get userid from session
  {ok, SessionId} = mu_sessions:get_sessionid(Req0),
  {UserID} = mu_sessions:get_userid_from_session(SessionId),
  % convert body from json
  {ok, Body, _} = cowboy_req:read_body(Req0),
  Args = bjson:decode(Body),
  % get data from request
  EmotionType = proplists:get_value(<<"emotion_type">>, Args),
  EmotionIntensity = proplists:get_value(<<"emotion_intensity">>, Args),
  % generate datetime as string
  {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:now_to_datetime(erlang:now()),
  StrTime = butil:datetime_to_string({{Day, Month, Year}, {Hour, Minute, Second}}),
  {Today,Time} = erlang:universaltime(),
  NowSecs = calendar:datetime_to_gregorian_seconds({Today, Time}),
  mu_db:insert_emotion(UserID, EmotionType, EmotionIntensity, NowSecs, StrTime),
  http_request_util:cowboy_out(mu_json_success_handler, true, Req0, State).

% get all possible emotions and describtions
get_emotions(Req0, State) ->
  Emotions = [{item, [value1, value2]}],
  http_request_util:cowboy_out(mu_json_success_handler, Emotions, Req0, State).

% get all stored emotions for current user
get_user_emotions(Req0, State, ReviewType) ->
  {ok, SessionId} = mu_sessions:get_sessionid(Req0),
  {UserID} = mu_sessions:get_userid_from_session(SessionId),
  case ReviewType of
    <<"daily">> ->
      {Today,Time} = erlang:universaltime(),
      NowSecs = calendar:datetime_to_gregorian_seconds({Today, {0,0,0}}),
      MaxTimeSecs = NowSecs + 24 * 60 * 60,
      UserEmotions = mu_db:get_user_emotions(UserID, NowSecs, MaxTimeSecs),
      http_request_util:cowboy_out(mu_json_success_handler, UserEmotions, Req0, State);
    <<"weekly">> ->
      {Today,Time} = erlang:universaltime(),
      DayOfWeek = calendar:day_of_the_week(Today),
      NowSecs = calendar:datetime_to_gregorian_seconds({Today, Time}),
      Twenty_Four_Hours_From_Now = 24 * 60 * 60,
      NewMinTimeSecs = NowSecs - Twenty_Four_Hours_From_Now*(DayOfWeek-1),
      NewMaxTimeSecs = NowSecs + Twenty_Four_Hours_From_Now*(8-DayOfWeek),
      UserEmotions = mu_db:get_user_emotions(UserID, NewMinTimeSecs, NewMaxTimeSecs),
      http_request_util:cowboy_out(mu_json_success_handler, UserEmotions, Req0, State);
    <<"monthly">> ->
      {{Year, Month, _}, _} = calendar:now_to_datetime(erlang:now()),
      LastDay = calendar:last_day_of_the_month(Year, Month),
      MinSeconds = calendar:datetime_to_gregorian_seconds({{Year, Month, 1},{0,0,0}}),
      TmpSec = calendar:datetime_to_gregorian_seconds({{Year, Month, LastDay},{0,0,0}}),
      SecLastDay = TmpSec + (24 * 60 * 60),
      UserEmotions = mu_db:get_user_emotions(UserID, MinSeconds, TmpSec),
      http_request_util:cowboy_out(mu_json_success_handler, UserEmotions, Req0, State);
    _ ->
      lager:debug("something is wrong with emotionreviewtype", []),
      http_request_util:cowboy_out(mu_json_error_handler, 0, Req0, State)
  end.

% get emotions for all users (?)
get_all_users_emotions(Req0, State) ->
  lager:debug("all users", []),
  http_request_util:cowboy_out(mu_json_success_handler, true, Req0, State).
