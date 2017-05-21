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
  Header = maps:get(headers,Req0),
  UserId = getUserIdFromHeader(Header),
  lager:debug("UserId ~p",[UserId]),
  case maps:get(<<"content-type">>,Header) of
    <<"application/json; charset=UTF-8">> -> {ok, Body, _} = cowboy_req:read_body(Req0), lager:debug("json: ~p",[Body]),Args = bjson:decode(Body);
    _ -> {ok, Args, _} = cowboy_req:read_urlencoded_body(Req0) % check on form submit
  end,
    % lager:error("Args: ~p",[Args]),
  case check_args(Args) of
    false -> http_request_util:cowboy_out(mu_json_error_handler,2, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    {child,QuestionnaireId} ->
      case ets:lookup(mu_questionnaire_user, UserId) of
        [{_,{Pid,Qid}}|T] ->
            lager:error("lookup Res: ~p",[Pid]),
            NumOfQ = mu_db:get_numOfQuestions(Qid),
            http_request_util:cowboy_out(mu_json_success_handler,NumOfQ#{<<"pid">>=>list_to_binary(pid_to_list(Pid))}, Req0, State);
        _ ->  case supervisor:start_child(?SUPERVISIOR, ?CHILDSPEC) of
            {_, undefined} -> http_request_util:cowboy_out(mu_json_error_handler,3, Req0, State);
            {ok, Pid} ->
            NumOfQ = mu_db:get_numOfQuestions(QuestionnaireId),mu_questionnaire:start(Pid,UserId,QuestionnaireId),
            http_request_util:cowboy_out(mu_json_success_handler,NumOfQ#{<<"pid">>=>list_to_binary(pid_to_list(Pid))}, Req0, State);
            {_,_} -> http_request_util:cowboy_out(mu_json_error_handler,3, Req0, State)
          end
      end;
    {next, Pid, Response} ->
      NewQuestion=mu_questionnaire:getNewQuestion(Pid,erlang:insert_element(1, Response, UserId)),
      case maps:get(question,NewQuestion) of
        [] -> mu_questionnaire:removeUserFromEtsTable(UserId), supervisor:terminate_child(?SUPERVISIOR, Pid);
        _ -> ok
      end,
      http_request_util:cowboy_out(mu_json_success_handler,NewQuestion, Req0, State);
    {start,{QuestionnaireId, Scoring,MaxScore}} ->
        % lager:error("Req0: ~p",[Req0]),
        http_request_util:cowboy_out(mu_path_handler,<<"/questionnaire">>, Req0, State, [{questionnaireId, QuestionnaireId},{scoring, Scoring},{max_score, MaxScore}])
  end.

check_args(Args) ->
  case proplists:get_value(<<"child">>, Args) of
    undefined ->
      Pid = proplists:get_value(<<"pid">>, Args), %convert binary string to Pid
      case proplists:get_value(<<"question">>, Args) of
        <<"next">> -> {next,list_to_pid(binary_to_list(Pid)),{proplists:get_value(<<"questionnaireId">>, Args),
         proplists:get_value(<<"questionId">>, Args, 1), proplists:get_value(<<"answerId">>, Args)}};
        <<"previous">> -> {previous,Pid};
        undefined -> {start,{proplists:get_value(<<"questionnaireId">>, Args), proplists:get_value(<<"scoring">>, Args), proplists:get_value(<<"max_score">>, Args)}}
      end;
    QuestionnaireId -> {child,QuestionnaireId}
  end.
