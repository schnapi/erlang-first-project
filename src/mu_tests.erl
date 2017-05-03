-module(mu_tests).

-compile(export_all).

-include("../include/mu.hrl").

insert_questionnaire() ->
  Id=1, Name = "test1",
  mu_db:insert_update_questionnaire(Id, Name),
  QuestionMap= [#{<<"answers">> => [#{<<"id">> => 1,<<"value">> => <<"Odgovoril z da ker bi rad dasdasdsadasd d ad asd asdasdas">>,<<"weight">> => <<"1">>},#{<<"id">> => 2,<<"value">> => <<"Ne">>,<<"weight">> => <<"2">>}],<<"answers_type">> => <<"selectOne">>,<<"id">> => 1,<<"image">> => <<>>,<<"question">> => <<"VpraÅ¡anje 1">>},#{<<"answers">> => [#{<<"id">> => 1,<<"value">> => <<"Test">>,<<"weight">> => <<"3">>},#{<<"id">> => 2,<<"value">> => <<"Ne">>,<<"weight">> => <<"2">>}],<<"answers_type">> => <<"selectOne">>,<<"id">> => 2,<<"image">> => <<>>,<<"question">> => <<"VpraÅ¡anje 2">>},#{<<"answers">> => [#{<<"id">> => 1,<<"value">> => <<"Test123">>,<<"weight">> => <<"1">>},#{<<"id">> => 2,<<"value">> => <<"Ne">>,<<"weight">> => <<"1">>}],<<"answers_type">> => <<"selectOne">>,<<"id">> => 3,<<"image">> => <<>>,<<"question">> => <<"VpraÅ¡anje 3">>},#{<<"answers">> => [#{<<"id">> => 1,<<"value">> => <<"Da">>,<<"weight">> => <<"1">>},#{<<"id">> => 2,<<"value">> => <<"Ne">>,<<"weight">> => <<"4">>}],<<"answers_type">> => <<"selectOne">>,<<"id">> => 4,<<"image">> => <<>>,<<"question">> => <<"vpraÅ¡anje 4">>}],
  [mu_db:insert_update_question_answers(Id,X,"Logic") || X <- QuestionMap ],
  ok.
insert_logic() ->
  Logic = #{<<"conditions">> => [#{<<"nextQuestion">> => 4,<<"questionsAnswers">> => [#{<<"answer">> => 1,<<"id">> => 1},#{<<"op">> => <<"and">>},#{<<"answer">> => 1,<<"id">> => 2},#{<<"op">> => <<>>}]}],<<"defaultNextQuestion">> => 3},
  mu_db:insert_update_logic(1,2,2,Logic),
  ok.

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
