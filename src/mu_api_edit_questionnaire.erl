-module(mu_api_edit_questionnaire).

-export([init/2]).
-compile(export_all).
-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_questionnaires_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(nonempty_list()) -> boolean().

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  % lager:debug("REQ: ~p",[Req0]),
  case Method of
    <<"POST">> ->
      handle_questionnaires_api(Req0, State);
    _ ->
      http_request_util:cowboy_out(mu_json_error_handler,0, Req0, State)
  end.

handle_questionnaires_api(Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  Args = jsx:decode(Body,[{labels, atom}, return_maps]),

  case check_args(Args) of
    error -> http_request_util:cowboy_out(mu_json_error_handler,2, Req0, State);
    ok -> http_request_util:cowboy_out(mu_json_success_handler,  true, Req0, State);
    Id when is_integer(Id) -> http_request_util:cowboy_out(mu_json_success_handler,  Id, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    Map ->
      http_request_util:cowboy_out(mu_json_success_handler, Map , Req0, State)
  end.


createListOfNumbers(List,Min,Max) ->
  case Min =< Max of
    true -> createListOfNumbers(List ++ [Min], Min+1, Max);
    false -> List
  end.
createListOfNumbers(Min, Max) ->
  createListOfNumbers([],Min,Max).

check_args(Args) ->
  case Args of
    #{ remove := Id } -> mu_db:remove_questionnaire(Id);
    #{ questionnaire := Questionnaire } ->
      #{ name := Name, id := QuestionnaireId } = Questionnaire,
      case mu_db:insert_update_questionnaire(QuestionnaireId, Name) of
        error -> error;
        NewQuestionnaireId ->
          QuestionMap = maps:get(questions,Args),
          LenOld = length(mu_db:get_questions(NewQuestionnaireId)),
          LenNew = length(QuestionMap),
          case LenOld > LenNew of
            true -> IdList = createListOfNumbers(LenNew+1,LenOld),
              [mu_db:remove_question(NewQuestionnaireId, QuestionId) || QuestionId <- IdList ];
            _ -> false
          end,
          [mu_db:insert_update_question_answers(NewQuestionnaireId,X) || X <- QuestionMap ],
          lager:debug("NewId: ~p",[NewQuestionnaireId]), NewQuestionnaireId
      end;
    #{ get := Id } ->
      {ok, {false, Questionnaire_questions}} = mu_db:get_questionnaire_questions(Id),
      Questionnaire_questions;
    _ -> error
  end.
