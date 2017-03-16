
-module(mu_questionnaire).

-behaviour(gen_server).


% Callback functions which should be exported
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, stop/0]).

% user-defined interface functions
-export([start_link/0, getNewQuestion/1]).

-include("../include/mu.hrl").

-spec getNewQuestion(pid()) -> term().

start_link() -> gen_server:start_link(?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

%gen_server:call = remote procedure call to the server.
getNewQuestion(Pid) ->
		lager:debug("test: ~p",[Pid]),
		gen_server:call(Pid, {new, "How are you?"}).
% getAnswers(State)  -> gen_server:call(?MODULE, {new, State}).
% withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).

init([]) ->	% io:format("ch1 has started (~w)~n", [self()]),
		{ok, questionnaireState}. %State, never changes

handle_call({new,Reply}, _From, Tab) ->
		% lager:debug("req: ~p -- ~p",[Tab, Reply]),
		%  Reply = case ets:lookup(Tab, Who) of
		% 		[]  -> ets:insert(Tab, {Who,0}), % if is empty then insert
		% 		       {welcome, Who}; %return
		% 		[_] -> {Who, you_already_are_a_customer}
		%  end,
		{reply, Reply, Tab};

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
