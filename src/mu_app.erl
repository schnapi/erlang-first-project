%%%-------------------------------------------------------------------
%% @doc mu public API
%% @end
%%%-------------------------------------------------------------------

-module(mu_app).
-include("../include/mu.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================


start(_, _) ->
  {ok, Port} = application:get_env(mu,port),
  Dispatch= cowboy_router:compile([
    {'_', [
      %% {HostMatch, list({PathMatch, Handler, InitialState})}
      {"/test/[...]", cowboy_static, {dir, "www"}},
      {"/[...]", mu_handler, []}
    ]}
  ]),
  %% Name, NbAcceptors, TransOpts, ProtoOpts
  {ok, _} = cowboy:start_clear(myapp_listener, 5,
    [{port, Port}], #{env => #{dispatch => Dispatch}}
  ),
  mu_sup:start_link().
  % for updating the dispatch list. First compile dispatch.
  % cowboy:set_env(my_http_listener, dispatch, cowboy_router:compile(Dispatch)).

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
