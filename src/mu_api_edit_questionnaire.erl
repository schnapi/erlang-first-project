-module(mu_api_edit_questionnaire).

-export([init/2]).
-compile(export_all).
-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_questionnaires_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(integer(), nonempty_list()) -> any().

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
  % Args = jsx:decode(Body,[{labels, atom}, return_maps]),
  Args = jsx:decode(Body,[return_maps]),

  case check_args(getUserIdFromReq(Req0), Args) of
    {error,Message} -> http_request_util:cowboy_out(mu_json_error_handler,Message, Req0, State);
    error -> http_request_util:cowboy_out(mu_json_error_handler,2, Req0, State);
    ok -> http_request_util:cowboy_out(mu_json_success_handler,  true, Req0, State);
    {ok,Message} -> http_request_util:cowboy_out(mu_json_success_handler, Message, Req0, State, decodeOff);
    Id when is_integer(Id) -> http_request_util:cowboy_out(mu_json_success_handler,  Id, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    Map ->
      lager:error("Map: ~p",[Map]),http_request_util:cowboy_out(mu_json_success_handler, Map , Req0, State)
  end.


createListOfNumbers(List,Min,Max) ->
  case Min =< Max of
    true -> createListOfNumbers(List ++ [Min], Min+1, Max);
    false -> List
  end.
createListOfNumbers(Min, Max) ->
  createListOfNumbers([],Min,Max).

writeFile(Path,Image) ->
  case Image of
    [FileHead|[Img]] ->
      file:write_file(Path, base64:decode(Img));
    _ -> lager:error("writeFile, no match: ~p",[Image]), error
  end.

check_args(UserId, #{ <<"get">> := <<"all">> }) ->
  {ok, {false, Questionnaires}} = mu_db:get_questionnaire_and_score(UserId),
  case ets:lookup(mu_questionnaire_user, UserId) of
    [{_,{_,Qid}}|_] -> ok;
    _ -> Qid = -1
  end,
  #{<<"questionnaires">> => Questionnaires,<<"questionnaireInProgressId">> => Qid};
check_args(UserId, Args) ->
  case Args of
    #{ <<"remove">> := Id } -> mu_db:remove_questionnaire(Id);
    #{ <<"questionnaire">> := Questionnaire} ->
      #{ <<"name">> := Name, <<"id">> := QuestionnaireId, <<"scoring">> := Scoring, <<"max_score">> := MaxScore} = Questionnaire,
      case mu_db:insert_update_questionnaire(QuestionnaireId, Name, Scoring, MaxScore) of
        error -> error;
        NewQuestionnaireId ->
          QuestionMap = maps:get(<<"questions">>,Args),
          LenOld = length(mu_db:get_questions(NewQuestionnaireId)),
          LenNew = length(QuestionMap),
          case LenOld > LenNew of % if user send us 3 question and 7 are in db then we remove questions above 3
            true -> IdList = createListOfNumbers(LenNew+1,LenOld),
              [mu_db:remove_question(NewQuestionnaireId, QuestionId) || QuestionId <- IdList ];
            _ -> false
          end,
          [mu_db:insert_update_question_answers(NewQuestionnaireId,Question) || Question <- QuestionMap ],
          NewQuestionnaireId
      end;
    #{ <<"get">> := Id } ->
      {ok, {false, Questions}} = mu_db:get_questionnaire_questions(Id),
      Questions;
    #{ <<"fileExist">> := FileName } ->
      case file:read_file_info(binary_to_list(FileName)) of
        {ok, FileInfo} -> {error,"eexist"};
        {error, Reason} -> ok
      end;
    #{ <<"writeFile">> := FileName, <<"file">> := File  } -> writeFile(binary_to_list(FileName),binary:split(File,<<",">>));
    #{ <<"removeFiles">> := FileNames } -> Test = [file:delete(binary_to_list(FileName)) || FileName <- FileNames];
    #{ <<"getConflicts">> := FileName, <<"folder">> := Folder } -> mu_db:get_questions_same_image(binary_to_list(Folder), binary_to_list(FileName));
    #{ <<"getAllFiles">> := _ } -> Path = getConfigPathImage(),
      case file:list_dir_all(Path) of
        {ok, Res} -> #{<<"folder">> => list_to_binary(Path), <<"files">> => [list_to_binary(X) || X <- Res]};
        Error -> Error
      end;
  _ -> error
  end.
