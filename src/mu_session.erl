-module(mu_session).
-behaviour(gen_server).

-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
	       terminate/2,
         code_change/3,
         stop/0]).

-export([start_link/0,
         ping/1]).

-include("../include/mu.hrl").

start_link() -> gen_server:start_link(?MODULE, [], []).

stop() -> gen_server:call(?MODULE, stop).

ping(Pid) ->
	lager:debug("test: ~p",[Pid]),
	gen_server:call(Pid, {ping}).

init([]) ->
	{ok, state}.

handle_call({ping}, _From, Tab) ->
    Reply = "test",
    lager:debug("here i am ~p", [Reply]),
		{reply, Reply, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
