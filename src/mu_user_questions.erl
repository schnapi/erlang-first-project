-module(mu_user_questions).

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
      handle_questionsPost_api(Req0, State);
    <<"GET">> ->
      handle_questionsGet_api(Req0, State);
    _ ->
      respond_questions_error(Req0, State, 0)
  end.

handle_questionsPost_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = bjson:decode(Body),
  % {Ok, Id} = supervisor:start_child(mu_sup, ChildSpec),
  case check_args(Args) of
    false -> respond_questions_error(Req0, State, 1);
    % todo: implement gen_server for sessions, call it at this point
    child -> case supervisor:start_child(?SUPERVISIOR, ?CHILDSPEC) of
        {ok, Pid} -> PidS = list_to_binary(pid_to_list(Pid)),
          Reply = jsx:encode(#{<<"result">> => PidS}),
          respond_questions_success(Req0, State,Reply);
        {_,_} -> respond_questions_error(Req0, State, 2)
      end;
    {next, Pid} ->
      NewQuestion=mu_questionnaire:getNewQuestion(Pid),
        Reply = jsx:encode(#{<<"result">> => list_to_binary(NewQuestion)}),
        respond_questions_success(Req0, State, Reply);
    {previous, Pid} -> PreviousQuestion=mu_questionnaire:getNewQuestion(Pid),
      Reply = jsx:encode(#{<<"result">> => <<PreviousQuestion>>}),
      respond_questions_success(Req0, State, Reply)
  end.

handle_questionsGet_api(Req0, State) ->
  Context = [{questions, {["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]],["question1", [{"answer1", "0.5"}, {"answer2", "0.5"}]]}}],
  {ok, Html} = mu_view_user_questions:render(Context),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

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

respond_questions_success(Req0, State, Reply) ->
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_questions_success(Req0, State) ->
  % sending json response
  Reply = jsx:encode(#{<<"result">> => <<"true">>}),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_questions_error(Req0, State, ErrCode) ->
  % sending error response
  case ErrCode of
    2 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Couldn't start new worker!">>});
    1 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Question is empty!">>});
    0 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Wrong request method">>})
  end,
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply, Req0),
  {ok, Req, State}.
