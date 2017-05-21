-module(mu_path_handler).

-export([out/1, out/2]).

-include("../include/mu.hrl").

-spec out(string(),any()) -> map().

out(Path) -> out(Path, []).
out(Path, Context1) ->
  Context = [{pagetitle, <<"Home">>},
    {navMenu, [{<<"Registracija uporabnika">>, <<"registration">>}, {<<"Urejanje avatarjev">>, <<"edit_avatar">>},{<<"Vprašalniki"/utf8>>, <<"questionnaires">>}, {<<"Admin vprašalniki"/utf8>>,<<"edit_questionnaires">>}]}],
  DefaultOut = #{ data => Context ++ Context1},
  lager:error("DefaultOut: ~p",[DefaultOut]),
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Path of
    <<"/">> ->
      #{ status => 302, headers=>#{<<"Location">> => <<"index">>}};
    <<"/index">> ->
      DefaultOut#{ view => mu_view_index };
    <<"/login">> ->
      #{ view => mu_view_login } ;
    <<"/registration">> ->
      DefaultOut#{ view => mu_view_registration };
    <<"/edit_avatar">> ->
      DefaultOut#{ view => mu_view_edit_avatar };
    <<"/questionnaire">> ->
      DefaultOut#{ view => mu_view_questionnaire };
    <<"/questionnaires">> ->
      DefaultOut#{ view => mu_view_questionnaires };
    <<"/edit_questionnaires">> ->lager:error("Test: ~p",[Context1]),
      {ok, {false, Questionnaires}} = mu_db:get_questionnaires(),
      #{ view => mu_view_edit_questionnaires, data => Context ++ [{questionnaires, Questionnaires}] ++ Context1 };
    <<"/edit_questionnaire">> ->
      % {ok, Html} = mu_view_edit_questionnaire:render(Context),
      % #{ status => 200, headers=>#{<<"content-type">> => <<"text/html">>}, body => render_page(mu_view_edit_questionnaire, Context)};
      DefaultOut#{ view => mu_view_edit_questionnaire };
    <<"/jsontest">> ->
      % #{ status => 200, headers=>#{<<"content-type">> => <<"application/json">>}, body => Html};
      % A = 1,
      % A = 2,
      #{ type => json, data => #{ <<"status">> => <<"it's ok">> }  };
    _ ->
      #{ status => 404, headers=>#{<<"content-type">> => <<"text/plain">>}, body => <<"404, not found.">>}
  end.
