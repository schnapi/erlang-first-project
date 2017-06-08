-module(mu_db_schema).

-include_lib("actordb_schemer/include/actordb_schemer.hrl").

-export([schema_ver/0, schema_def/0]).
-export([check/0, upgrade/0]).
-export([setup/0]).

setup() ->
  actordb_schemer:setup(?MODULE,[silent]).

schema_ver() ->
  0.

schema_def() ->
  [
    #adb_actor{ name = <<"system">>, tables = [
      #adb_table{ name = <<"user">>, opts = [without_rowid, {primary_key,[<<"id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"TEXT">> }
      ]},

      #adb_table{ name = <<"config">>, fields = [
        #adb_field{ name = <<"param">>, type = <<"TEXT">>, opts = [ primary_key ]},
        #adb_field{ name = <<"value">>, type = <<"BLOB">>}
      ] }
    ]},

    #adb_actor{ name = <<"session">>, opts = [kv], tables = [
      #adb_table{ name = <<"actors">>, opts = [without_rowid, {primary_key,[<<"id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"TEXT">> },
        #adb_field{ name = <<"hash">>, type = <<"INTEGER">> },
        #adb_field{ name = <<"user_id">>, type = <<"TEXT">> }
      ]}
    ]},

    #adb_actor{ name = <<"user">>, tables = [
      #adb_table{ name = <<"data">>, opts = [without_rowid, {primary_key,[<<"email">>]}], fields = [
        #adb_field{ name = <<"avatarName">>, type = <<"TEXT">> },
        #adb_field{ name = <<"email">>, type = <<"TEXT">> },
        #adb_field{ name = <<"role">>, type = <<"TEXT">> },
        #adb_field{ name = <<"passwordHash">>, type = <<"TEXT">> },
        #adb_field{ name = <<"salt">>, type = <<"TEXT">> },
        #adb_field{ name = <<"sex">>, type = <<"BOOLEAN">> },
        #adb_field{ name = <<"avatar">>, type = <<"TEXT">> , opts = [ {default,""} ]}
      ]},
      #adb_table{ name = <<"thoughts">>, fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">> , opts = [ primary_key, autoincrement]},
        #adb_field{ name = <<"email">>, type = <<"TEXT">> },
        #adb_field{ name = <<"thought">>, type = <<"TEXT">> },
        #adb_field{ name = <<"dateCreated">>, type = <<"TEXT">> }
      ]},
      #adb_table{ name = <<"session">>, opts = [without_rowid, {primary_key,[<<"id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"TEXT">>},
        #adb_field{ name = <<"value">>, type = <<"BLOB">>}
      ]},

      #adb_table{ name = <<"statestore">>, opts = [without_rowid], fields = [
        #adb_field{ name = <<"id">>, type = <<"TEXT">>, opts = [ primary_key ]},
        #adb_field{ name = <<"type">>, type = <<"TEXT">>},
        #adb_field{ name = <<"state">>, type = <<"BLOB">>}
      ]}
    ]},

    #adb_actor{ name = <<"questionnaire">>, tables = [

      #adb_table{ name = <<"questionnaires">>, fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">>, opts = [ primary_key, autoincrement ]},
        #adb_field{ name = <<"name">>, type = <<"TEXT">>},
        #adb_field{ name = <<"scoring">>, type = <<"BOOLEAN">>},
        #adb_field{ name = <<"max_processingSpeed">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"max_brainCapacity">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"max_brainWeight">>, type = <<"INTEGER">>}
      ]},

      #adb_table{ name = <<"users_score">>, opts = [without_rowid, {foreign_key,[{key,["questionnaire_id"]},
        {ref_table,"questionnaires"},{ref_id,["id"]},{opts,[on_delete_cascade]}]},
        {primary_key,[<<"user_id">>,<<"epoch">>,<<"questionnaire_id">>]}], fields = [
        #adb_field{ name = <<"questionnaire_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"user_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"processingSpeed">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"brainCapacity">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"brainWeight">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"state">>, type = <<"TEXT">>},
        #adb_field{ name = <<"epoch">>, type = <<"TIMESTAMP">>}
      ]},

      #adb_table{ name = <<"questions">>, opts = [without_rowid, {foreign_key,[{key,["questionnaire_id"]},
        {ref_table,"questionnaires"},{ref_id,["id"]},{opts,[on_delete_cascade]}]},
        {primary_key,[<<"id">>,<<"questionnaire_id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"questionnaire_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"question">>, type = <<"TEXT">>},
        #adb_field{ name = <<"image">>, type = <<"TEXT">>},
        #adb_field{ name = <<"folder">>, type = <<"TEXT">>},
        #adb_field{ name = <<"answers_type">>, type = <<"TEXT">>}
        % #adb_field{ name = <<"next_question">>, type = <<"INTEGER">>}
      ]},

      #adb_table{ name = <<"answers">>, opts = [without_rowid, {foreign_key,[{key,["question_id","questionnaire_id"]},
        {ref_table,"questions"},{ref_id,["id","questionnaire_id"]},{opts,[on_delete_cascade]}]},
        {primary_key,[<<"id">>,<<"question_id">>,<<"questionnaire_id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"question_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"questionnaire_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"answer">>, type = <<"TEXT">>},
        #adb_field{ name = <<"processingSpeed">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"brainCapacity">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"brainWeight">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"default_next_question">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"answerImage">>, type = <<"TEXT">>}
      ]},

      #adb_table{ name = <<"logic_conditions">>, opts = [without_rowid, {foreign_key,[{key,["answer_id","question_id","questionnaire_id"]},
        {ref_table,"answers"},{ref_id,["id","question_id","questionnaire_id"]},{opts,[on_delete_cascade]}]},
        {primary_key,[<<"id">>, <<"answer_id">>,<<"question_id">>,<<"questionnaire_id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"answer_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"question_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"questionnaire_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"next_question">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"condition">>, type = <<"TEXT">>}
      ]},

      #adb_table{ name = <<"brain_motivations">>, opts = [without_rowid, {foreign_key,[{key,["answer_id","question_id","questionnaire_id"]},
        {ref_table,"answers"},{ref_id,["id","question_id","questionnaire_id"]},{opts,[on_delete_cascade]}]},
        {primary_key,[<<"id">>, <<"answer_id">>,<<"question_id">>,<<"questionnaire_id">>]}], fields = [
        #adb_field{ name = <<"id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"answer_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"question_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"questionnaire_id">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"text">>, type = <<"TEXT">>},
        #adb_field{ name = <<"min_score">>, type = <<"INTEGER">>},
        #adb_field{ name = <<"special_id">>, type = <<"INTEGER">>}
      ]}
    ]}
  ].

  check() ->
      Cfg = actordb_client:config(data_connection, 60000, binary),
      actordb_schemer:check(Cfg).

  upgrade() ->
      Cfg = actordb_client:config(data_connection, 60000, binary),
      actordb_schemer:upgrade(Cfg).
