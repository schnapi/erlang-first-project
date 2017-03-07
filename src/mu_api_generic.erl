-module(mu_api_generic).

-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  Path = cowboy_req:path(Req0),
  case Path of
    <<"/login">> ->
      handle_login(Req0, State)
  end.

handle_login(Req0, State) ->
  % request's method(get -> visit login page, post -> after submiting login form)
  Method = cowboy_req:method(Req0),
  case Method of
    % get method -> just render login page
    <<"GET">> ->
      respond_login(Req0, State);
    % post method, check session, save session etc.
    <<"POST">> ->
      user_login(Req0, State)
  end.

user_login(Req0, State) ->
  % get request body
  {ok, KeyValues, _} = cowboy_req:read_urlencoded_body(Req0),
  Username = proplists:get_value(<<"username">>, KeyValues),
  Password = proplists:get_value(<<"password">>, KeyValues),
  % check required data
  case {Username, Password} of
    {<<>>, _} ->
      respond_login_error(Req0, State);
    {_, <<>>} ->
      respond_login_error(Req0, State);
    _ ->
  % todo: gen_server for sessions implementation
      {ok, Req0, State}
  end.

respond_login_error(Req0, State) ->
  Req = cowboy_req:reply(500, #{<<"content-type">> => <<"text/plain">>}, <<"undefined username or password.">>, Req0),
  {ok, Req, State}.

respond_login(Req0, State) ->
  {ok, Html} = mu_view_login:render(),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.
