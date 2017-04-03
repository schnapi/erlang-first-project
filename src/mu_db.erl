-module(mu_db).

-export([connect/0]).
-export([get_all_users/0,get_answers/0,get_questionnaires/0,get_questions/0]).
-export([insert_update_questionnaire/2]).
-export([remove_questionnaire/1, remove_answer/1]).
-export([check_schema/0, upgrade_schema/0]).

-compile(export_all).
-include("../include/mu.hrl").

connect() ->
  mu_db_schema:setup(), % we initialize the myapp_db_schema as module for managing the schema
  PoolInfo = [{size, 10}, {max_overflow, 5}],
  DataConnection = {data_connection, PoolInfo, [ [{hostname, "localhost"}, {port, 33306}, {username, "root"}, {password, "mocenum"}] ]},
  actordb_client:start([ DataConnection ]).

get_all_users() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single(Config, <<"mocenum">>, <<"system">>,
   <<"SELECT * FROM user;">>, [create]).

get_answers() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM answers;">>, [create]).

get_questionnaires() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM questionnaires;">>, [create]).

get_questionnaire(Id) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
    <<"SELECT * FROM questionnaires AS q WHERE q.id=?1;">>, [create], [[Id]]).

get_questions() ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM questions;">>, [create]).
get_questions(QuestionnaireId) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
    <<"SELECT * FROM questions WHERE questionnaires_id=?1;">>, [create], [[QuestionnaireId]]) of
    {ok, {false, Res}} -> Res;
    {error,Error} -> lager:debug("~p",[Error]), error
  end.

get_questionnaire_questions(QuestionnaireId) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  Res = actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
  %  <<"SELECT q1.name,q2.*, GROUP_CONCAT(an.weight) weights,GROUP_CONCAT(an.answer) answers FROM questionnaires AS q1, questions AS q2, answers AS an
  %   WHERE q2.questionnaires_id=?1 AND q1.id=q2.questionnaires_id AND an.question_id = q2.id GROUP BY an.question_id;">>, [create], [[QuestionnaireId]]).
  %  <<"SELECT id,answers_type,image,name,question, '[' || group_concat(answers) || ']' AS answers FROM
  %  (SELECT q1.name,q2.*, '[\"' || an.answer || '\",\"' || an.weight || '\"]' AS answers FROM questionnaires AS q1, questions AS q2, answers AS an
  %   WHERE q2.questionnaires_id=?1 AND q1.id=q2.questionnaires_id AND an.question_id = q2.id);">>, [create], [[QuestionnaireId]]).
   <<"SELECT id,answers_type,image,question,'[' || group_concat(answers) || ']' AS answers FROM (SELECT q2.*, '{\"value\":' || '\"' || an.answer || '\",\"weight\":' || '\"' || an.weight || '\"}' AS answers FROM questionnaires AS q1
    INNER JOIN questions AS q2 on q1.id=q2.questionnaires_id
    LEFT JOIN answers AS an ON an.question_id = q2.id WHERE q2.questionnaires_id=?1 AND an.questionnaires_id=?1) GROUP BY id;">>, [create], [[QuestionnaireId]]).


insert_user(Name) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single_param(Config, <<"mocenum">>, <<"user">>,
   <<"INSERT INTO user VALUES(?1);">>, [create], [[list_to_binary(Name)]]).
% see: actordb_client:exec_single_param(ConnectionCfg, ActorId, ActorType, Sql, Flags, Binds),

insert_update_questionnaire(Id, Name) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
    <<"INSERT OR REPLACE INTO questionnaires VALUES(?1,?2);">>, [create], [[Id, Name]]) of
    {ok,{_,NewId,_}} -> lager:debug("insert_update_questionnaire: id:~p name:~p NewId:~p",[Id, Name, NewId]), NewId;
    {error,Error} -> lager:error("~p",[Error]), error
  end.

insert_update_question_answers(QuestionnaireId, QuestionMap) ->
  lager:debug("REQ: ~p",[QuestionMap]),
  #{ id := QuestionId, answers := Answers, answers_type := Answers_type, image := Image, question := Question} = QuestionMap,
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT OR REPLACE INTO questions VALUES(?1, ?2, ?3, ?4, ?5);">>, [create],
    [[QuestionId,QuestionnaireId,Question,Image,Answers_type]]) of
   {ok,Va} -> lager:debug("~p",[Va]), ok;
   {error,Error} -> lager:error("~p ~p ~p ~p ~p",[QuestionId,QuestionnaireId,Question,Image,Answers_type]), error
  end,
  % be careful, same QuestionId and answerId because it's not include QuestionnaireId
  [mu_db:insert_update_answer(AnswerMap,QuestionId, QuestionnaireId) || AnswerMap <- Answers ].

insert_question(QuestionnaireId, Id, Question, Image, Answers_type) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT INTO questions VALUES(?1, ?2, ?3, ?4, ?5);">>, [create],
    [[Id,QuestionnaireId,Question,Image,Answers_type]]) of
   {ok,_} -> ok;
   {error,Error} -> lager:debug("~p",[Error]), error
  end.
update_question(Id, Question, Image, Answers_type) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
     <<"UPDATE questions SET question=?2, Image=?3, Answers_type=?4 WHERE id=?1;">>, [create], [[Id, Question, Image, Answers_type]]) of
    {ok,_} -> lager:debug("update_question ~p:  ~p",[Id , Question]), ok;
    {_,Error} -> lager:debug("~p",[Error]), error
  end.

insert_update_answer(AnswerMap, QuestionId, QuestionnaireId) ->
  #{ id := AnswerId, value := Answer, weight := Weight} = AnswerMap,
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT OR REPLACE INTO answers VALUES(?1,?2,?3,?4,?5);">>, [create], [[AnswerId, QuestionId,QuestionnaireId,Answer,Weight]]) of
   {ok,Va} -> lager:debug("Inserting updating answer ~p",[Va]), ok;
   {error,Error} -> lager:debug("~p",[Error]), error
 end.
insert_answer(AnswerId, QuestionId) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT INTO answers VALUES(?1,?2,?3,?4);">>, [create], [[AnswerId, QuestionId,"answer1",1]]).
remove_answer(AnswerId) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE * FROM answers WHERE id=?1;">>, [], [[AnswerId]]).

remove_questionnaire(Id) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questionnaires WHERE id=?1;">>, [], [[Id]]) of
   {ok,_} -> ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.

remove_question(NewQuestionnaireId, Id) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questions WHERE questionnaires_id=?1 AND id=?2;">>, [], [[NewQuestionnaireId, Id]]) of
   {ok,_} -> lager:error("Removing NewQuestionnaireId:~p, id:~p",[NewQuestionnaireId, Id]), ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.
remove_questions(NewQuestionnaireId, MinId) ->
  Config = actordb_client:config(data_connection, infinity, binary),
  case actordb_client:exec_single_param(Config, <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questions WHERE questionnaires_id=?1 AND id>?2;">>, [], [[NewQuestionnaireId, MinId]]) of
   {ok,_} -> lager:error("Removing NewQuestionnaireId:~p, from id upwards:~p",[NewQuestionnaireId, MinId]), ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.

check_schema() ->
  % prints out the schema upgrade statements
  mu_db_schema:check().

upgrade_schema() ->
  % upgrades the schema
  mu_db_schema:upgrade().
