-module(mu_questionnaire).

-behaviour(gen_server).


% Callback functions which should be exported
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, stop/0]).

% user-defined interface functions
-export([start_link/0, getNewQuestion/2]).

-compile(export_all).

-include("../include/mu.hrl").


start_link() -> gen_server:start_link(?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
		% lager:error("ch1 has started (~w)~n   - ~p", [self(), ?MODULE]),
		{ok, #{tab => [],processingSpeed => 0, brainCapacity => 0, brainWeight => 0, userId => ""}}. %1 - start with first question
		% {ok, ets:new(?MODULE,[])}. % local pid storage

checkConditionQA(#{<<"id">> := Qid, <<"answer">> := AnswerId},Tab) ->
	atom_to_list(lists:any(fun(X) -> case X of {{Qid, AnswerId},_,_} -> true; _ -> false end end, Tab));
checkConditionQA(#{<<"op">> := Op},Tab) -> binary_to_list(Op);
checkConditionQA(#{<<"p1">> := Op},Tab) -> binary_to_list(Op);
checkConditionQA(#{<<"p2">> := Op},Tab) -> binary_to_list(Op).

createLogicTokens([],Tab, BooleanList) -> BooleanList;
createLogicTokens([H|T],Tab, BooleanList) -> createLogicTokens(T,Tab, BooleanList ++ [checkConditionQA(H,Tab)]).


getNextQuestion([Condition|T],DefaultNextQuestion,Tab) ->
	lager:error("getNextQuestion: ~p",[Condition]),
	#{<<"next_question">> := NextQuestion, <<"condition">> := QuestionsAnswers} = Condition,
	InfixLogic = createLogicTokens(jsx:decode(QuestionsAnswers,[return_maps]),Tab, []),
	PostFix = logic:infixToPostfix(InfixLogic),
	case logic:rpn(PostFix) of
		"false" -> getNextQuestion(T,DefaultNextQuestion,Tab);
	%!!!!! problem with multiple conditions
		_ -> NextQuestion
	end;
getNextQuestion([], DefaultNextQuestion,_) -> DefaultNextQuestion.

nextQuestion(QuestionnaireId, QuestionId, AnswerId, Tab) ->
	#{<<"default_next_question">> := DefaultNextQuestion,<<"answerImage">>:=AnswerImage, <<"processingSpeed">> := W1, <<"brainCapacity">> := W2, <<"brainWeight">> := W3} = mu_db:get_answer(QuestionnaireId, QuestionId,AnswerId),
		lager:error("DefaultNextQuestion: ~p",[DefaultNextQuestion]),
	NextQuestion = getNextQuestion( mu_db:get_logic(QuestionnaireId, QuestionId, AnswerId),DefaultNextQuestion,Tab),
		lager:error("NextQuestion: ~p",[NextQuestion]),
	%we add current state to Tab - where we have been {Question, Answer}, and get next question from database
	{Tab ++ [{{QuestionId, AnswerId},{W1,W2,W3},NextQuestion}], {W1,W2,W3}, mu_db:get_questionnaire_question(QuestionnaireId, NextQuestion)}.

%gen_server:call = remote procedure call to the server.
-spec getNewQuestion(pid(), {integer(),any()}) -> term().
getNewQuestion(Pid,Response) ->
		gen_server:call(Pid, {next, Response}).

-spec start(pid(), binary(),integer()) -> term().
start(Pid,UserId,QuestionnaireId) ->
	gen_server:call(Pid, {start, UserId,QuestionnaireId}).

handle_call({start, UserId, QuestionnaireId}, _From, Tab) ->
	ets:insert(mu_questionnaire_user, {UserId, {self(),QuestionnaireId}}),
	{reply, [], Tab#{userId => UserId, questionnaireId=>QuestionnaireId }};
handle_call({next, {UserId1, QuestionnaireId1,Qid, AnswerId}}, _From, #{tab := Tab,
	processingSpeed := PS, brainCapacity := BC, brainWeight := BW, userId := UserId, questionnaireId := QuestionnaireId}) ->
	lager:error("UserId: ~p",[UserId]),
	lager:error("State: ~p",[Tab]),
	case Tab of
		[] -> QuestionId=1; % get last saved state
		_ -> {_,_,QuestionId} = lists:last(Tab)
	end,
		lager:error("QuestionId: ~p",[QuestionId]),
		lager:error("AnswerId: ~p",[AnswerId]),
	case AnswerId of
		0 -> lager:error("L 0: ~p",[Tab]),{Tab1, W1,W2,W3,Question} = {Tab,0,0,0, mu_db:get_questionnaire_question(QuestionnaireId, QuestionId)}; % if no answer send same question
		_ when AnswerId<0 orelse is_binary(AnswerId) -> {Tab1, W1,W2,W3, Question} = {Tab ++ [{{QuestionId, AnswerId},{0,0,0},QuestionId+1}],0,0,0, mu_db:get_questionnaire_question(QuestionnaireId, QuestionId+1)};
		_ -> lager:error("all: ~p",[Tab]),{Tab1, {W1,W2,W3}, Question} = nextQuestion(QuestionnaireId,QuestionId, AnswerId, Tab)
	end,
			lager:error("Current user questionnaire state: ~p",[Tab1]),
		S1 = PS + W1,S2 = BC + W2,S3 = BW + W3,
		case Question of
			[] -> lager:error("End of questions: state: ~p",[Tab1]),
				%scoring to percent
				#{<<"max_brainCapacity">> := Max_brainCapacity, <<"max_brainWeight">> := Max_brainWeight,
	              <<"max_processingSpeed">> := Max_processingSpeed, <<"scoring">> := Scoring} = mu_db:get_questionnaire_max_scores(QuestionnaireId),
				case Scoring of
					1 ->	mu_db:insert_result(QuestionnaireId,UserId,valueToPercent(S1,Max_processingSpeed),valueToPercent(S2,Max_brainCapacity),valueToPercent(S3,Max_brainWeight),jsx:encode(getQA(Tab1,[]))); %end of questions, check scoring
					_ -> mu_db:insert_result(QuestionnaireId,UserId,-1,-1,-1,jsx:encode(getQA(Tab1,[]))) %end of questions, check scoring
				end;
			_ -> ok
		end,
		% reply, response, state
		{reply, #{processingSpeed => S1, brainCapacity => S2, brainWeight => S3, question => Question},
		#{tab => Tab1,processingSpeed => S1, brainCapacity => S2, brainWeight => S3,userId => UserId, questionnaireId => QuestionnaireId}};
handle_call(stop, _From, Tab) ->
lager:error("stop: ~p",[Tab]),{stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}. %it’s called a cast to distinguish it from a remote procedure call)
handle_info(_Info, State) -> {noreply, State}.

valueToPercent(Val, MaxVal) -> case MaxVal of
		0 -> 0;
		_ -> Val*100/MaxVal
	end.
getQA([{{Q,A},_,_}|T],QAList) -> getQA(T,QAList ++ [Q,A]);
getQA([],QAList) -> QAList.

removeUserFromEtsTable(UserId) ->
	case UserId of
		-1 -> lager:error("User do not exist in ETS table: ~p",[UserId]),error;
		_ -> lager:error("UserId successfully removed from ets table: ~p",[UserId]), ets:delete(mu_questionnaire_user, UserId),ok
	end.
terminate(_Reason, _State) -> removeUserFromEtsTable(maps:get(userId, _State,-1)),
	ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

% handle_cast(calc, State) ->
%      io:format("result 2+2=4~n"),
%      {noreply, State};
% handle_cast(calcbad, State) ->
%      io:format("result 1/0~n"),
%      1 / 0,
%      {noreply, State}.


testCheckCondition() ->
	Tab = [{{1,1},1}, {{3,2},2}, {{2,2},3}],%state question,answer,score
	QA1 = [#{<<"answer">> => 1,<<"id">> => 1},#{<<"op">> => <<"and">>},
	#{<<"p1">> => <<"(">>},#{<<"answer">> => 2,<<"id">> => 3},#{<<"op">> => <<"or">>},
	#{<<"answer">> => 1,<<"id">> => 2},#{<<"p2">> => <<")">>}],
	["true","and","(","true","or","false",")"]  = createLogicTokens(QA1,Tab, []),

	QA2 = [#{<<"answer">> => 1,<<"id">> => 1},#{<<"op">> => <<"and">>},
	#{<<"answer">> => 2,<<"id">> => 3},#{<<"op">> => <<"or">>},
	#{<<"answer">> => 1,<<"id">> => 2}],
	["true","and","true","or","false"]  = createLogicTokens(QA2,Tab, []),
	ok.
