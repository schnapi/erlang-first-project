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
        {navMenu, [{"Login","login"}, {"Registration", "registration"},{"Questionnaire", "questionnaire"}, {"Admin questionnaires","edit_questionnaires"}]},
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
    <<"/edit_questionnaires">> ->
      {ok, {false, Questionnaires}} = mu_db:get_questionnaires(),
      Context = [{questionnaires, Questionnaires}],
      #{ view => mu_view_edit_questionnaires, data => Context };
    <<"/edit_questionnaire">> ->
      % {ok, Html} = mu_view_edit_questionnaire:render(Context),
      % #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => render_page(mu_view_edit_questionnaire, Context)};
      #{ view => mu_view_edit_questionnaire };
    <<"/jsontest">> ->
      % #{ status => 200, headers=>#{<<"content-type">> => <<"application/json">>}, body => Html};
      % A = 1,
      % A = 2,
      #{ type => json, data => #{ <<"status">> => <<"it's ok">> }  };
    _ ->
      #{ status => 404, headers=>#{<<"content-type">> => <<"text/plain">>}, body => <<"404, not found.">>}
  end.
