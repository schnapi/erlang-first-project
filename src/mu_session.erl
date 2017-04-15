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
         ping/1,
         update_session_expiry_time/1]).

-include("../include/mu.hrl").

-record(state, {timer_reference}).

% 7200000 milisecunds -> 2hours
-define(EXPIRYDATE, 72000000).

start_link() -> gen_server:start_link(?MODULE, [], []).

stop() -> gen_server:call(?MODULE, stop).

% ================ FUNCTIONS FOR WORKING WITH SESSION ================
ping(Pid) ->
	gen_server:call(Pid, {ping}).

update_session_expiry_time(Pid) ->
  gen_server:call(Pid, {restart_timer}).

% ====================================================================

init([]) ->
  State = create_timer(),
  lager:debug("session created.~nsession expiry date set. ~n", []),
	{ok, State}.

handle_call({ping}, _From, State) ->
  Reply = "test",
  lager:debug("here i am ~p", [Reply]),
	{reply, Reply, State};

handle_call({restart_timer}, _From, State) ->
  NewState = restart_timer(State),
  lager:debug("session expiry date updated.~n", []),
	{reply, session_expiry_date_updated, NewState};

handle_call(stop, _From, State) ->
  {stop, normal, stopped, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  case _Info of
    {stop, session_timeout} ->
      terminate(expired_session, State)
  end,
  {noreply, State}.

terminate(_Reason, _State) ->
  lager:debug("TERMINATE SESSION'S PROCESS BECAUSE OF:~p", [_Reason]),
  exit(self(), shutdown),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

% ================ PRIVATE FUNCTIONS ================
create_timer() ->
  NewTref = erlang:send_after(?EXPIRYDATE, self(), {stop, session_timeout}),
  #state{timer_reference=NewTref}.

restart_timer(Tab) ->
  erlang:cancel_timer(Tab#state.timer_reference),
  NewTRef = erlang:send_after(?EXPIRYDATE, self(), {stop, session_timeout}),
  #state{timer_reference=NewTRef}.

% ===================================================
