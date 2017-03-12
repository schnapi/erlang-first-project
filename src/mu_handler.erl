-module(mu_handler).
-include("../include/mu.hrl").

-export([init/2]).

init(Req0, State) ->
  % lager:debug("req: ~p",[Req0]),
  Path = cowboy_req:path(Req0),
  lager:debug("path accessed: ~p",[Path]),
  % Version = cowboy_req:version(Req).
  % URI = cowboy_req:uri(Req) %https://ninenines.eu/docs/en/cowboy/2.0/guide/req/
  % URL for bindings, Query parameters parsing,header,peer address and port number
  % HostInfo = cowboy_req:host_info(Req).
  case Path of
    <<"/">> ->
      respond_302(Req0, State);
    <<"/index">> ->
      respond_index(Req0, State);
    <<"/login">> ->
      respond_login(Req0, State);
    <<"/registration">> ->
      respond_registration(Req0, State);
    <<"/questionnaires">> ->
      respond_questionnaires(Req0, State);
    <<"/questions">> ->
      respond_user_questions(Req0, State);
    _ ->
      respond_404(Req0, State)
  end.


% npr preusmerimo na index stran
respond_302(Req0, State) ->
  Req = cowboy_req:reply(302, #{<<"location">> => <<"index">>}, <<"">>, Req0),
  {ok, Req, State}.

% izpišemo plain/text not found
respond_404(Req0, State) ->
    Req = cowboy_req:reply(404, #{<<"content-type">> => <<"text/plain">>}, <<"404, not found.">>, Req0),
    {ok, Req, State}.

% rendramo django template language myapp_index.dtl, datoteko ustvarimo v ./dtl/myapp_index.dtl, jo shranimo in ponovno prevedemo celotni projekt ter ga ponovno poženemo

respond_index(Req0, State) ->
  Context = [{pagetitle, "Home"},
    {navMenu, ["Home", "About","Contact"]},
    {posts, [#{"name" => "PostName1", "content" => "Content1"},
    #{"name" => "PostName2", "content" => "Content2"}]}],
  {ok, Html} = mu_view_index:render(Context),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

respond_login(Req0, State) ->
  {ok, Html} = mu_view_login:render(),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

respond_registration(Req0, State) ->
  {ok, Html} = mu_view_registration:render(),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

respond_questionnaires(Req0, State) ->
  Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
  {ok, Html} = mu_view_questionnaires:render(Context),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

respond_user_questions(Req0, State) ->
  Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
  {ok, Html} = mu_view_user_questions:render(Context),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.
