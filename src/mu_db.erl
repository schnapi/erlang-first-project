-module(mu_db).

-export([connect/0]).
-export([get_all_users/0,get_answers/0,get_questionnaires/0,get_questions/0]).
-export([insert_update_questionnaire/2]).
-export([remove_questionnaire/1, remove_answer/1]).
-export([insert_new_session/1, delete_session_record/1]).
-export([check_schema/0, upgrade_schema/0]).

-compile(export_all).
-include("../include/mu.hrl").

connect() ->
  mu_db_schema:setup(), % we initialize the myapp_db_schema as module for managing the schema
  PoolInfo = [{size, 10}, {max_overflow, 5}],
  DataConnection = {data_connection, PoolInfo, [ [{hostname, "localhost"}, {port, 33306}, {username, "root"}, {password, "mocenum"}] ]},
  actordb_client:start([ DataConnection ]).

config() -> actordb_client:config(data_connection, infinity, binary).

% insert_node() ->
%   case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
%     <<"INSERT OR REPLACE INTO nodes VALUES(?1,?2);">>, [create], [[Id, Name]]) of
%     {ok,{_,NewId,_}} -> lager:debug("insert_node: NewId:~p",[NewId]);
%     {error,Error} -> lager:error("~p",[Error]), error
%   end.

get_all_users() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"user">>,
   <<"SELECT * FROM data;">>, [create]).

get_all_users_id_role() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"user">>,
  <<"SELECT email as username, role FROM data;">>, [create]).

get_answers() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM answers;">>, [create]).
get_answer(QuestionnaireId, QuestionId,AnswerId) ->
 case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
  <<"SELECT * FROM answers WHERE questionnaire_id=?1 AND question_id=?2 AND id=?3 ;">>, [create], [[QuestionnaireId, QuestionId,AnswerId]]) of
  {ok, {false, []}} -> [];
  {ok, {false, [H|_]}} -> H;
  {error,Error} -> lager:debug("~p",[Error]), error
end.

get_questionnaires() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM questionnaires;">>, [create]).

get_questionnaire(Id) ->
  actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
    <<"SELECT * FROM questionnaires AS q WHERE q.id=?1;">>, [create], [[Id]]).

get_questions() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM questions;">>, [create]).

get_questions(QuestionnaireId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
    <<"SELECT * FROM questions WHERE questionnaire_id=?1;">>, [create], [[QuestionnaireId]]) of
    {ok, {false, Res}} -> Res;
    {error,Error} -> lager:debug("~p",[Error]), error
  end.

get_questionnaire_questions(QuestionnaireId) ->
  Res = actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
  %  <<"SELECT q1.name,q2.*, GROUP_CONCAT(an.weight) weights,GROUP_CONCAT(an.answer) answers FROM questionnaires AS q1, questions AS q2, answers AS an
  %   WHERE q2.questionnaire_id=?1 AND q1.id=q2.questionnaire_id AND an.question_id = q2.id GROUP BY an.question_id;">>, [create], [[QuestionnaireId]]).
  %  <<"SELECT id,answers_type,image,name,question, '[' || group_concat(answers) || ']' AS answers FROM
  %  (SELECT q1.name,q2.*, '[\"' || an.answer || '\",\"' || an.weight || '\"]' AS answers FROM questionnaires AS q1, questions AS q2, answers AS an
  %   WHERE q2.questionnaire_id=?1 AND q1.id=q2.questionnaire_id AND an.question_id = q2.id);">>, [create], [[QuestionnaireId]]).
   <<"SELECT id,answers_type,image,question, '[' || group_concat(answers) || ']' AS answers FROM (SELECT q2.*,
    '{\"value\":' || '\"' || an.answer || '\",\"weight\":' || '\"' || an.weight || '\",\"id\":' || '\"' || an.id || '\",\"defaultNextQuestion\":' || '\"' || an.default_next_question || '\",
    \"conditions\":' || an.conditions || '}' AS answers
    FROM questionnaires AS q1 INNER JOIN questions AS q2 on q1.id=q2.questionnaire_id
    LEFT JOIN (SELECT an.*,  '[' || ifnull(group_concat('{ \"nextQuestion\":' || lc.next_question || ',\"condition\":' || lc.condition || '}'),'') || ']' as conditions FROM answers AS an
     LEFT JOIN logic_conditions AS lc on an.questionnaire_id = lc.questionnaire_id AND an.question_id=lc.question_id AND an.id=lc.answer_id
     WHERE an.questionnaire_id=?1 GROUP BY an.question_id, an.id ) AS an
    ON an.question_id = q2.id WHERE q2.questionnaire_id=?1) GROUP BY id;">>, [create], [[QuestionnaireId]]).

get_test() -> QuestionnaireId=1,
  {ok,{false,Res}}= actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT an.*, '[' || ifnull(lc.condition, '') || ']' as conditions FROM answers AS an
    LEFT JOIN logic_conditions AS lc on an.questionnaire_id = lc.questionnaire_id AND an.question_id=lc.question_id AND an.id=lc.answer_id
    WHERE an.questionnaire_id=?1 GROUP BY an.question_id, an.id">>, [create], [[QuestionnaireId]]),
    lager:debug("~p",[Res]).
    get_test1() -> QuestionnaireId=1,
      {ok,{false,Res}}= actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
       <<"SELECT an.*, ifnull(lc.condition, '[]') as conditions FROM answers AS an
        LEFT JOIN logic_conditions AS lc on an.question_id=lc.question_id AND an.id=lc.answer_id
        WHERE an.question_id=1 AND an.questionnaire_id=?1">>, [create], [[QuestionnaireId]]),
        lager:debug("~p",[Res]).

get_questionnaire_question(QuestionnaireId, QuestionId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT id,answers_type,image,question,'[' || group_concat(answers) || ']' AS answers FROM
   (SELECT q2.*,default_next_question, '{\"value\":' || '\"' || an.answer || '\",\"weight\":' || '\"' || an.weight || '\"}' AS answers FROM questions AS q2
    LEFT JOIN answers AS an ON an.questionnaire_id = q2.questionnaire_id AND an.question_id = q2.id
    WHERE q2.questionnaire_id=?1 AND q2.id=?2) GROUP BY id;">>, [create], [[QuestionnaireId, QuestionId]]) of
    {ok,{false,[]}} -> [];
    {ok, {false, [H | _]}} -> H; % just one row
    {error,Error} -> lager:debug("~p",[Error]), error
  end.
get_questionnaire_question(QuestionnaireId, QuestionId, AnswerId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT ifnull(default_next_question, -1) as default_next_question,id,answers_type,image,question,'[' || group_concat(answers) || ']' AS answers FROM
   (SELECT q2.*,default_next_question, '{\"value\":' || '\"' || an.answer || '\",\"weight\":' || '\"' || an.weight || '\"}' AS answers FROM questions AS q2
    LEFT JOIN answers AS an ON an.questionnaire_id = q2.questionnaire_id AND an.question_id = q2.id
    WHERE q2.questionnaire_id=?1 AND q2.id=?2 AND an.id=?3) GROUP BY id;">>, [create], [[QuestionnaireId, QuestionId,AnswerId]]) of
    {ok,{false,[]}} -> [];
    {ok, {false, [H | _]}} -> H; % just one row
    {error,Error} -> lager:debug("~p",[Error]), error
  end.

get_user(Email) ->
  lager:debug("~p",[Email]),
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"user">>,
    <<"SELECT * FROM data WHERE email=?1;">>, [create], [[Email]]) of
    {ok, {false, [Res]}} -> Res;
    {error,Error} -> lager:debug("~p",[Error]), error
  end.

check_user_password(Email, Password) ->
  case get_user(Email) of
    {error,Error} -> lager:debug("~p",[Error]), error;
    Map -> #{ <<"salt">> := Salt, <<"role">> := Role, <<"passwordHash">> := PasswordHash} = Map,
      case butil:dec2hex(crypto:hash(sha256, binary_to_list(Password) ++ binary_to_list(Salt))) of
        PasswordHash -> ok;
        _ -> lager:debug("Wrong password!",[Password]), error
      end
  end.

-spec delete_user(binary()) -> any().
delete_user(Email) ->
  actordb_client:exec_single_param(config(), <<"mocenum">>, <<"user">>,
   <<"DELETE FROM data WHERE email=?1;">>, [], [[Email]]).
% out {ok,{changes,_,0}} or {error,Error}

-spec insert_user(binary(), binary(), binary(), tuple()) -> any().
insert_user(Email, Role, Password, Ip) ->
  {Salt} = mu_sessions:generate_sessionid(Ip, Email), %generate salt with ip and email and...
  PasswordHash = butil:dec2hex(crypto:hash(sha256, binary_to_list(Password)++Salt)),
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"user">>,
   <<"INSERT INTO data VALUES(?1,?2,?3,?4,?5);">>, [create], [["", Email, Role, PasswordHash, Salt ]]) of
    {ok,{_,NewId,_}} -> lager:debug("user has been inserted: id:~p name:~p",[Email, Password]);
    {error,Error} -> lager:error("~p",[Error]), error
  end.

insert_update_questionnaire(Id, Name) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
    <<"INSERT OR REPLACE INTO questionnaires VALUES(?1,?2);">>, [create], [[Id, Name]]) of
    {ok,{_,NewId,_}} -> lager:debug("insert_update_questionnaire: id:~p name:~p NewId:~p",[Id, Name, NewId]), NewId;
    {error,Error} -> lager:error("~p",[Error]), error
  end.

insert_update_question_answers(QuestionnaireId, QuestionMap) ->
  #{ <<"id">> := QuestionId, <<"answers">> := Answers, <<"answers_type">> := Answers_type, <<"image">> := Image, <<"question">> := Question} = QuestionMap,
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT OR REPLACE INTO questions VALUES(?1, ?2, ?3, ?4, ?5);">>, [create],
    [[QuestionId,QuestionnaireId,Question,Image,Answers_type]]) of
   {ok,Va} -> lager:debug("~p",[Va]), ok;
   {error,Error} -> lager:error("~p ~p ~p ~p ~p",[QuestionId,QuestionnaireId,Question,Image,Answers_type]), error
  end,
  % % be careful, same QuestionId and answerId because it not include QuestionnaireId
  [mu_db:insert_update_answer(AnswerMap,QuestionId, QuestionnaireId) || AnswerMap <- Answers ],
  ok.

insert_question(QuestionnaireId, Id, Question, Image, Answers_type) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT INTO questions VALUES(?1, ?2, ?3, ?4, ?5);">>, [create],
    [[Id,QuestionnaireId,Question,Image,Answers_type]]) of
   {ok,_} -> ok;
   {error,Error} -> lager:debug("~p",[Error]), error
  end.
update_question(Id, Question, Image, Answers_type) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
     <<"UPDATE questions SET question=?2, Image=?3, Answers_type=?4 WHERE id=?1;">>, [create], [[Id, Question, Image, Answers_type]]) of
    {ok,_} -> lager:debug("update_question ~p:  ~p",[Id , Question]), ok;
    {_,Error} -> lager:debug("~p",[Error]), error
  end.

insert_update_answer(AnswerMap, QuestionId, QuestionnaireId) ->lager:debug("~p",[AnswerMap]),
  lager:error("AnswerMap ~p",[AnswerMap]),
  lager:error("QuestionId ~p",[QuestionId]),
  case AnswerMap of
    #{ <<"id">> := AnswerId, <<"value">> := Answer, <<"weight">> := Weight} ->
      case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
        <<"INSERT OR REPLACE INTO answers VALUES(?1,?2,?3,?4,?5,?6);">>, [create], [[AnswerId, QuestionId,QuestionnaireId,Answer,Weight,maps:get(<<"defaultNextQuestion">>, AnswerMap, QuestionId+1)]]) of
        {ok,Va} -> lager:debug("Inserting updating answer ~p",[Va]),
        mu_db:insert_update_logic(maps:get(<<"conditions">>, AnswerMap, []),QuestionnaireId, QuestionId, AnswerId, 1), ok;
        {error,Error} -> lager:error("~p",[Error]), error
      end;
    _ -> lager:error("Pattern matching Answer or Weight"), error
  end.

insert_update_logic([Condition|T],QuestionnaireId, QuestionId, AnswerId, Id) ->
  #{<<"nextQuestion">> := NextQuestion, <<"condition">> := QuestionsAnswers} = Condition,
  lager:error("Condition: ~p",[Condition]),
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT OR REPLACE INTO logic_conditions VALUES(?1,?2,?3,?4,?5,?6);">>, [create], [[Id, AnswerId, QuestionId,QuestionnaireId,NextQuestion, jsx:encode(QuestionsAnswers)]]) of
   {ok,Va} -> lager:debug("Inserting updating logic ~p",[Va]), ok;
   {error,Error} -> lager:error("~p",[Error]), error
  end,
  insert_update_logic(T,QuestionnaireId, QuestionId, AnswerId, Id+1);
insert_update_logic([],QuestionnaireId, QuestionId, AnswerId, Id) -> ok.

get_logic_column_names() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"PRAGMA table_info(logic_conditions);">>, [create]).

get_logic() ->
  actordb_client:exec_single(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM logic_conditions;">>, [create]).
get_logic(QuestionnaireId) ->
 case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM logic WHERE questionnaire_id=?1;">>, [create], [[QuestionnaireId]]) of
   {ok,{false,Res}} -> Res;
   Error -> lager:error("~p",[Error]), error
 end.
get_logic(QuestionnaireId, QuestionId, AnswerId) ->
 case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"SELECT * FROM logic_conditions WHERE questionnaire_id=?1 AND question_id=?2 AND answer_id=?3;">>, [create], [[QuestionnaireId, QuestionId, AnswerId]]) of
   {ok, {false, Res}} -> Res;
   {ok,{false,[]}} -> [];
   Error -> lager:error("~p",[Error]), error
 end.

insert_answer(AnswerId, QuestionId) ->
  actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"INSERT INTO answers VALUES(?1,?2,?3,?4);">>, [create], [[AnswerId, QuestionId,"answer1",1]]).
remove_answer(AnswerId) ->
  actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE * FROM answers WHERE id=?1;">>, [], [[AnswerId]]).

remove_questionnaire(Id) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questionnaires WHERE id=?1;">>, [], [[Id]]) of
   {ok,_} -> ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.

remove_question(NewQuestionnaireId, Id) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questions WHERE questionnaire_id=?1 AND id=?2;">>, [], [[NewQuestionnaireId, Id]]) of
   {ok,_} -> lager:error("Removing NewQuestionnaireId:~p, id:~p",[NewQuestionnaireId, Id]), ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.
remove_questions(NewQuestionnaireId, MinId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"questionnaire">>,
   <<"DELETE FROM questions WHERE questionnaire_id=?1 AND id>?2;">>, [], [[NewQuestionnaireId, MinId]]) of
   {ok,_} -> lager:error("Removing NewQuestionnaireId:~p, from id upwards:~p",[NewQuestionnaireId, MinId]), ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.

% insert record for new session, 1st param -> sessionid, 2nd param -> json object with
insert_new_session(SessionId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"user">>,
   <<"INSERT INTO session VALUES(?1,?2);">>, [create], [[SessionId, ""]]) of
    {ok,{_,NewId,_}} -> lager:debug("session has been inserted: sessionid:~p newID:~p",[SessionId, NewId]);
    {error,Error} -> lager:error("~p",[Error]), error
  end.

% delete record for session
delete_session_record(SessionId) ->
  case actordb_client:exec_single_param(config(), <<"mocenum">>, <<"user">>,
   <<"DELETE FROM session WHERE id=?1;">>, [], [[SessionId]]) of
   {ok,_} -> lager:error("Session record successfully deleted",[]), ok;
   {error,Error} -> lager:debug("~p",Error), error
  end.

check_schema() ->
  % prints out the schema upgrade statements
  mu_db_schema:check().

upgrade_schema() ->
  % upgrades the schema
  mu_db_schema:upgrade().