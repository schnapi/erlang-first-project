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

%gen_server:call = remote procedure call to the server.
-spec getNewQuestion(pid(), {integer(),any()}) -> term().
getNewQuestion(Pid,Response) ->
		gen_server:call(Pid, {next, Response}).
% getAnswers(State)  -> gen_server:call(?MODULE, {new, State}).
% withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).

init([]) ->
		% lager:error("ch1 has started (~w)~n   - ~p", [self(), ?MODULE]),
		{ok, #{tab => [],score => 0}}. %1 - start with first question
		% {ok, ets:new(?MODULE,[])}. % local pid storage

checkConditionQA(#{<<"id">> := Qid, <<"answer">> := AnswerId},Tab) ->
	atom_to_list(lists:any(fun(X) -> case X of {{Qid, AnswerId},_} -> true; _ -> false end end, Tab));
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
	#{<<"default_next_question">> := DefaultNextQuestion, <<"weight">> := Weight} = mu_db:get_answer(QuestionnaireId, QuestionId,AnswerId),
		lager:error("DefaultNextQuestion: ~p",[DefaultNextQuestion]),
	NextQuestion = getNextQuestion( mu_db:get_logic(QuestionnaireId, QuestionId, AnswerId),DefaultNextQuestion,Tab),
		lager:error("NextQuestion: ~p",[NextQuestion]),
	%we add current state to Tab - where we have been {Question, Answer}, and get next question from database
	{Tab ++ [{{QuestionId, AnswerId},Weight}], Weight, mu_db:get_questionnaire_question(QuestionnaireId, NextQuestion)}.

handle_call({next, {QuestionnaireId, QuestionId, AnswerId}}, _From, #{tab := Tab, score := Score}) ->
lager:error("QuestionId: ~p",[QuestionId]),
lager:error("AnswerId: ~p",[AnswerId]),
lager:error("Tab: ~p",[Tab]),
	case AnswerId of
		0 -> lager:error("L 0: ~p",[Tab]),{Tab1, Weight,Question} = {Tab,0, mu_db:get_questionnaire_question(QuestionnaireId, QuestionId)}; % if no answer send same question
		_ when AnswerId<0 -> {Tab1, Weight, Question} = {Tab, 0, mu_db:get_questionnaire_question(QuestionnaireId, QuestionId+1)};
		_ -> lager:error("all: ~p",[Tab]),{Tab1, Weight, Question} = nextQuestion(QuestionnaireId,QuestionId, AnswerId, Tab)
	end,
			lager:error("Current user questionnaire state: ~p",[Tab1]),
		% lager:error("req: ~p -- ~p",[Tab, ets:lookup(Tab, who)]),
		% ets:insert(Tab, {who,QuestionnaireId}),
		% lager:error("req: ~p -- ~p",[Tab, ets:lookup(Tab, who)]),
		% ets:insert(mu_questionnaire_state, {self(), QuestionnaireId}),
		%  Reply = case ets:lookup(Tab, Who) of
		% 		[]  -> ets:insert(Tab, {Who,0}), % if is empty then insert
		% 		       {welcome, Who}; %return
		% 		[_] -> {Who, you_already_are_a_customer}
		%  end,
		Score1 = Score + Weight,
		case Question of
			[] -> mu_db:insert_result(QuestionnaireId,1,Score1); %end of questions, check scoring
			_ -> ok
		end,
		% reply, response, state
		{reply, #{score => Score1, question => Question}, #{tab => Tab1,score => Score1}};

%function is called from terminate(...)
%{stop, Reason, NewState}
handle_call(stop, _From, Tab) -> {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}. %it’s called a cast to distinguish it from a remote procedure call)
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
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
