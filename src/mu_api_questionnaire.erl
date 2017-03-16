-module(mu_api_questionnaire).

-export([init/2]).

-include("../include/mu.hrl").

-define(SUPERVISIOR, mu_sup).
-define(GENSERVER, mu_questionnaire).
-define(CHILDSPEC, #{id => erlang:now(), % mandatory
             start => { ?GENSERVER, start_link, []}, % mandatory
             restart => permanent, % permanent child process is always restarted
             shutdown => 2000, % Shutdown=after 2000 seconds if no response from child
             type => worker, % optional
             modules => [?GENSERVER]}). %list with one element

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_questions_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(nonempty_list()) -> property().

% http://erlang.org/doc/design_principles/sup_princ.html
init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    <<"POST">> ->
      handle_questions_api(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler,0, Req0, State)
  end.

handle_questions_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % {Ok, Id} = supervisor:start_child(mu_sup, ChildSpec),
  case check_args(Args) of
    false -> http_request_util:cowboy_out(mu_json_error_handler,2, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    child -> case supervisor:start_child(?SUPERVISIOR, ?CHILDSPEC) of
        {_, undefined} -> http_request_util:cowboy_out(mu_json_error_handler,3, Req0, State);
        {ok, Pid} -> http_request_util:cowboy_out(mu_json_success_handler,Pid, Req0, State);
        {_,_} -> http_request_util:cowboy_out(mu_json_error_handler,3, Req0, State)
      end;
    {next, Pid} -> NewQuestion=mu_questionnaire:getNewQuestion(Pid),
      http_request_util:cowboy_out(mu_json_success_handler,NewQuestion, Req0, State);
    {previous, Pid} -> PreviousQuestion=mu_questionnaire:getNewQuestion(Pid),
      http_request_util:cowboy_out(mu_json_success_handler,PreviousQuestion, Req0, State)
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
