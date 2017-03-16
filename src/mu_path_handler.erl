-module(mu_path_handler).

-export([out/1]).

-include("../include/mu.hrl").

-spec out(string()) -> map().

out(Path) ->
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Path of
    <<"/">> ->
      #{ status => 302, headers=>#{<<"Location">> => <<"index">>}};
    <<"/index">> ->
      Context = [{pagetitle, "Home"},
        {navMenu, [{"Login","login"}, {"Registration", "registration"},{"Questionnaire", "questionnaire"}, {"Admin questionnaires","questionnaires"}]},
        {posts, [#{"name" => "PostName1", "content" => "Content1"},
        #{"name" => "PostName2", "content" => "Content2"}]}],
      #{ view => mu_view_index, data => Context };
    <<"/login">> ->
      #{ view => mu_view_login } ;
    <<"/registration">> ->
      #{ view => mu_view_registration } ;
    <<"/questionnaire">> ->
      Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
      #{ view => mu_view_questionnaire, data => Context };
    <<"/questionnaires">> ->
      Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
      % {ok, Html} = mu_view_questionnaires:render(Context),
      % #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => render_page(mu_view_questionnaires, Context)};
      #{ view => mu_view_questionnaires, data => Context };
    <<"/jsontest">> ->
      % #{ status => 200, headers=>#{<<"content-type">> => <<"application/json">>}, body => Html};
      % A = 1,
      % A = 2,
      #{ type => json, data => #{ <<"status">> => <<"it's ok">> }  };
    _ ->
      #{ status => 404, headers=>#{<<"content-type">> => <<"text/plain">>}, body => <<"404, not found.">>}
  end.
