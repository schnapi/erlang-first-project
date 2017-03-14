-module(bcs_mod).
-include("../include/mu.hrl").

-export([out/2]).

out(Path, Req0) ->
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Path of
    <<"/">> ->
      #{ status => 302, headers=>#{<<"Location">> => <<"index">>}, body => <<"">>};
    <<"/index">> ->
      Context = [{pagetitle, "Home"},
        {navMenu, [{"Login","login"}, {"Registration", "registration"},{"Questionnaire", "questionnaire"}, {"Admin questionnaires","questionnaires"}]},
        {posts, [#{"name" => "PostName1", "content" => "Content1"},
        #{"name" => "PostName2", "content" => "Content2"}]}],
      {ok, Html} = mu_view_index:render(Context),
      #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => Html};
    <<"/login">> ->
      {ok, Html} = mu_view_login:render(),
      #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => Html};
    <<"/registration">> ->
      {ok, Html} = mu_view_registration:render(),
      #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => Html};
    <<"/questionnaire">> ->
      Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
      {ok, Html} = mu_view_questionnaire:render(Context),
      #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => Html};
    <<"/questionnaires">> ->
      Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
      {ok, Html} = mu_view_questionnaires:render(Context),
      #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => Html};
    _ ->
      #{ status => 404, headers=>#{<<"content-type">> => <<"text/plain">>}, body => <<"404, not found.">>}
  end.
