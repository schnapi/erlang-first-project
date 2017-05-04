-module(mu).

-export([start/0]).

-include("../include/mu.hrl").

start() ->
  application:ensure_all_started(mu),
  mu_db:connect(),
  % mu_db:check_schema(),
  mu_db:upgrade_schema(),
  mu_db:insert_user(<<"mocenum">>, <<"admin">>, <<"mocenum">>, {127,0,0,1}),
  case mu_db:get_questionnaires() of
    {ok,{false,[]}} -> mu_tests:insert_questionnaire1(),
      mu_tests:insert_questionnaire2();
    _ -> ok
  end,
ok.
