%%%-------------------------------------------------------------------
%% @doc mu top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(mu_sup).
-include("../include/mu.hrl").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
  % if child has terminated more than 10 times in last 60 seconds -> supervisior terminates itself...
   
  %  {ok, {RestartStrategy, [Children]}}.
   {ok, { {one_for_one, 10, 60}, []} }.

%%====================================================================
%% Internal functions
%%====================================================================
