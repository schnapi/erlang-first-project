-module(mu_path_handler).

-export([out/1, out/2]).

-include("../include/mu.hrl").

-spec out(string(),any()) -> map().

out(Path) -> out(Path, []).
out(Path, Context1) ->
  Context = [],

  %lager:error("DefaultOut: ~p",[DefaultOut]),
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Path of
    <<"/">> ->
      #{ status => 302, headers=>#{<<"Location">> => <<"index">>}};
    <<"/index">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Domov">>}] ++ Context1},
      DefaultOut#{ view => mu_view_index };
    <<"/login">> ->
      % {ok, JS} = file:read_file("./www/js/login.js"),
      #{ view => mu_view_login, data => [{ javascript_file, {file, "./www/js/login.js"}}] } ;
    <<"/admin_registration">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Pregled uporabnikov">>}] ++ Context1},
      DefaultOut#{ view => mu_view_admin_registration };
    <<"/edit_avatar">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Urejanje avatarjev">>}] ++ Context1},
      DefaultOut#{ view => mu_view_edit_avatar };
    <<"/questionnaire">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Vprašalnik"/utf8>>}] ++ Context1},
      DefaultOut#{ view => mu_view_questionnaire };
    <<"/questionnaires">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Vprašalniki"/utf8>>}] ++ Context1},
      DefaultOut#{ view => mu_view_questionnaires };
    <<"/edit_questionnaires">> ->lager:error("Test: ~p",[Context1]),
      {ok, {false, Questionnaires}} = mu_db:get_questionnaires(),
      #{ view => mu_view_edit_questionnaires, data => Context ++ [{pagetitle, <<"Admin vprašalniki"/utf8>>}, {questionnaires, Questionnaires}] ++ Context1 };
    <<"/edit_questionnaire">> ->
      % {ok, Html} = mu_view_edit_questionnaire:render(Context),
      % #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => render_page(mu_view_edit_questionnaire, Context)};
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Home">>}] ++ Context1},
      DefaultOut#{ view => mu_view_edit_questionnaire };
    <<"/thoughts">> ->
      DefaultOut = #{ data => Context ++ [{pagetitle, <<"Dnevnik misli">>}] ++ Context1},
      DefaultOut#{ view => mu_view_thoughts };
    <<"/jsontest">> ->
      % #{ status => 200, headers=>#{<<"content-type">> => <<"application/json">>}, body => Html};
      % A = 1,
      % A = 2,
      #{ type => json, data => #{ <<"status">> => <<"it's ok">> }  };
    _ ->
      #{ status => 404, headers=>#{<<"content-type">> => <<"text/plain">>}, body => <<"404, not found.">>}
  end.
