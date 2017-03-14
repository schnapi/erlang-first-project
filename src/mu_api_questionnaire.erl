-module(mu_api_questionnaire).

-include("../include/mu.hrl").

-export([init/2]).

-define(SUPERVISIOR, mu_sup).
-define(GENSERVER, mu_questionnaire).
-define(CHILDSPEC, #{id => erlang:now(), % mandatory
             start => { ?GENSERVER, start_link, []}, % mandatory
             restart => permanent, % permanent child process is always restarted
             shutdown => 2000, % Shutdown=after 2000 seconds if no response from child
             type => worker, % optional
             modules => [?GENSERVER]}). %list with one element

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      handle_questions_api(Req0, State);
    _ ->
      mu_respond:respond_error(Req0, State,0)
  end.

handle_questions_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % {Ok, Id} = supervisor:start_child(mu_sup, ChildSpec),
  case check_args(Args) of
    false -> mu_respond:respond_error(Req0, State,"Question is empty!");
    % todo: implement gen_server for sessions, call it at this point
    child -> case supervisor:start_child(?SUPERVISIOR, ?CHILDSPEC) of
        {ok, Pid} -> PidS = list_to_binary(pid_to_list(Pid)),
          Reply = jsx:encode(#{<<"result">> => PidS}),
          mu_respond:respond_success(Req0, State,Reply);
        {_,_} -> mu_respond:respond_error(Req0, State, "Couldn't start new worker!")
      end;
    {next, Pid} ->
      NewQuestion=mu_questionnaire:getNewQuestion(Pid),
        Reply = jsx:encode(#{<<"result">> => list_to_binary(NewQuestion)}),
        mu_respond:respond_success(Req0, State, Reply);
    {previous, Pid} -> PreviousQuestion=mu_questionnaire:getNewQuestion(Pid),
      Reply = jsx:encode(#{<<"result">> => <<PreviousQuestion>>}),
      mu_respond:respond_success(Req0, State, Reply)
  end.

check_args(Args) ->
  Child = proplists:get_value(<<"child">>, Args),
  Question = proplists:get_value(<<"question">>, Args),
  Pid = proplists:get_value(<<"Pid">>, Args), %convert binary string to Pid
  case Child of
    undefined -> case Question of
        <<"next">> -> {next,list_to_pid(binary_to_list(Pid))};
        <<"previous">> -> {previous,Pid};
        undefined -> false
      end;
    _ -> child
  end.
