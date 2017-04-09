-module(mu_tests).

-compile(export_all).

-include("../include/mu.hrl").

check_password() ->
  mu_db:insert_user(<<"check_password@gmail.com">>, <<"admin">>, <<"test">>, {"127.0.0.1"}),
  Email = <<"check_password@gmail.com">>,
  Password = <<"test">>,
  case mu_db:check_user_password(Email,Password) of
    ok -> lager:debug("Test check_user_password passed!"),
      case mu_db:delete_user(Email) of
        {ok,_} -> lager:debug("User is succesfuly removed: ~p",[Email]);
        {error,Error} -> lager:error("Test delete_user failed: ~p",[Error])
      end;
    _ -> lager:error("Test check_user_password failed: ~p")
  end.
