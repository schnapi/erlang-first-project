-module(mu_path_handler).

-export([out/1, out/2]).

-include("../include/mu.hrl").

-spec out(string(),any()) -> map().

out(Path) -> out(Path, []).
out(Path, Context1) ->
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Path of
    <<"/">> ->
      #{ status => 302, headers=>#{<<"Location">> => <<"index">>}};
    <<"/index">> ->
      Context = [{pagetitle, "Home"},
        {navMenu, [{"Login","login"}, {"Registration", "registration"},{"Questionnaires", "questionnaires"}, {"Admin questionnaires","edit_questionnaires"}]}],
      #{ view => mu_view_index, data => Context };
    <<"/login">> ->
      #{ view => mu_view_login } ;
    <<"/registration">> ->
      #{ view => mu_view_registration } ;
    <<"/questionnaire">> ->
        lager:error("Args: ~p",[Context1]),
      #{ view => mu_view_questionnaire, data => Context1 };
    <<"/questionnaires">> ->
        % lager:error("Unsupported token: ~p",[Context]),
      #{ view => mu_view_questionnaires};
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
