-module(mu_api_registration).

-export([init/2]).

-include("../include/mu.hrl").

-compile(export_all).
-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec handle_registration_api(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.

init(Req0, State) ->
  Method = cowboy_req:method(Req0),
  case Method of
    % post method, check session, save session etc.
    <<"POST">> ->
      handle_registration_api(Req0, State);
    _ -> http_request_util:cowboy_out(mu_json_error_handler,1, Req0, State)
  end.

handle_registration_api(Req0, State) ->
 {ok, Body, _} = cowboy_req:read_body(Req0),

 % convert to map is also possible: Args = jsx:decode(Body,[{labels, atom}, return_maps])
 Args = bjson:decode(Body),
 checkKeys(Args, Req0,State).

getResult(QId,State) ->
  % generate sql statement from state
  SQL = generateSQLString(jsx:decode(State),[]),
  lager:error("SQL: ~p", [SQL]),
  lager:error("State: ~p", [State]),
  lager:error("QId: ~p", [QId]),
  mu_db:get_question_answer(QId,SQL).
%
% generateSQLString([Q,-1|T],[]) -> generateSQLString(T," questions.id="++integer_to_list(Q));
% generateSQLString([Q,-1|T],List) -> generateSQLString(T,List ++ " or questions.id="++integer_to_list(Q));
generateSQLString([Q,A|T],[]) -> generateSQLString(T," questions.id="++integer_to_list(Q)++" and answers.id="++integer_to_list(A));
generateSQLString([Q,A|T],List) -> generateSQLString(T,List ++ " or questions.id="++integer_to_list(Q)++" and answers.id="++integer_to_list(A));
generateSQLString([],List) -> List.

epochToLocalDate(Milliseconds) ->
  Timestamp = {Milliseconds div 1000000, Milliseconds rem 1000000, 0},
  calendar:now_to_local_time(Timestamp).
dateTimeToString({{YYYY,M,D},{HH,MM,SS}}) ->
  Time = io_lib:format('~2..0b:~2..0b:~2..0b', [HH, MM, SS]),
  Date = io_lib:format('~2..0b/~2..0b/~p', [D, M, YYYY]),
  {Date,Time}.

writeFile1(File, Answer,Image,Question,QuestionId)->lager:error("Answer: ~p", [Answer]),
  case Answer of
    -1 -> ok;
    _ ->
      csv_gen:row(File,[]),
      csv_gen:row(File, ["Vprašanje ID", QuestionId]),
      csv_gen:row(File, ["Vprašanje", Question]),
      case Image of <<"">> -> noImage; _ -> csv_gen:row(File, ["Vprašanje slika", Image]) end,
      % case Image of <<"">> -> noImage; _ -> csv_gen:row(File, ["Odgovor slika", Image]) end,
      csv_gen:row(File, ["Odgovor", Answer])
  end.


writeFile(File, Name, QId, Epoch,ProcessingSpeed, BrainCapacity,BrainWeight,State) ->
  csv_gen:row(File,[]),
  Row11 = ["Vprašalnik", "Datum", "Lokalni čas"],
  {Date,Time} = dateTimeToString(epochToLocalDate(Epoch)),
  Row21 = [Name, Date, Time],
  case BrainCapacity of
    -1 -> Row12 = [],Row22=[];
    _ -> Row12 = ["Hitrost procesiranja", "Možganska kapaciteta","Teža možganov"],
      Row22 = [ProcessingSpeed, BrainCapacity,BrainWeight]
  end,
  csv_gen:row(File, Row11 ++ Row12 ),
  csv_gen:row(File, Row21 ++ Row22 ),
  [writeFile1(File, Answer,Image,Question,QuestionId) || #{<<"answer">> := Answer, <<"image">> := Image,<<"question">> := Question, <<"id">> := QuestionId} <- getResult(QId,State)].

generateMapFromList([], Map) -> Map;
generateMapFromList([H|T],Map) ->
  #{<<"brainCapacity">> := BrainCapacity, <<"user_id">> := User_id,<<"brainWeight">> := BrainWeight,<<"processingSpeed">> := ProcessingSpeed} = H,
  case User_id of
    undefined -> generateMapFromList(T,Map);
    _ -> generateMapFromList(T,Map#{User_id => #{brainCapacity => round(BrainCapacity),brainWeight => round(BrainWeight),processingSpeed => round(ProcessingSpeed)}})
  end.
% return first match
checkKeys([], Req0, State) -> http_request_util:cowboy_out(mu_json_error_handler,6, Req0, State);
checkKeys([KeyValue|T], Req0, State) ->
   UserId = getUserIdFromReq(Req0),
   case KeyValue of
      {<<"get">>, <<"user">>} -> Data = mu_db:get_user(UserId),
       http_request_util:cowboy_out(mu_json_success_handler,Data, Req0, State);
      {<<"get">>, <<"users">>} -> {ok, {false, Users}} = mu_db:get_users_registration(),
        http_request_util:cowboy_out(mu_json_success_handler,Users, Req0, State);
      {<<"get">>, <<"usersLastAvgScoresLastEpoch">>} -> {ok, {false, Results}} = mu_db:get_usersLastAvgScoresLastEpoch(),
        Map = generateMapFromList(Results,#{}),
        {ok, {false, Users}} = mu_db:get_users_registration(),
        http_request_util:cowboy_out(mu_json_success_handler,#{users => Users, results => Map}, Req0, State);
      {<<"getCSV">>, UserID} -> {ok, {false, Res}} = mu_db:get_results(UserID),
        FilePath=getConfigPathCsv()++binary_to_list(UserID)++".csv",
        {ok, File} = file:open(FilePath, [write]),
        [writeFile(File, mu_db:get_questionnaire_name(QId),QId, Epoch,ProcessingSpeed, BrainCapacity,BrainWeight,State)
         || #{<<"questionnaire_id">> := QId, <<"state">> := State,<<"epoch">> := Epoch,
         <<"processingSpeed">> := ProcessingSpeed,<<"brainCapacity">> :=BrainCapacity,
         <<"brainWeight">> := BrainWeight} <- Res],
         file:close(File),
         http_request_util:cowboy_out(mu_json_success_handler,tryUnicode(FilePath), Req0, State);
        % http_request_util:cowboy_out(mu_file_handler,getConfigPathCsv()++binary_to_list(getUserIdFromReq(Req0))++".csv", Req0, State);
      {<<"deleteUser">>, Id} ->  case mu_db:delete_user(Id) of
         {ok,_} -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State);
          Error -> lager:error("delete user: ~p",[Error]), http_request_util:cowboy_out(mu_json_error_handler,5, Req0, State)
        end;
      {<<"registration">>,[{<<"username">>,Id},{<<"password">>,Password},{<<"role">>,Role},{<<"sex">>,Sex}]} ->
        #{peer := {Ip, _}} = Req0,
        case Sex of
          0 -> Avatar = <<"defaultMan.jpg">>;
          _ -> Avatar = <<"defaultWoman.jpg">>
        end,
        case mu_db:insert_user(Id, Role, Password, Ip, Sex,Avatar) of
          error -> http_request_util:cowboy_out(mu_json_error_handler,4, Req0, State);
          _ -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
        end;
    {<<"update">>, [{<<"avatar">>,Avatar},{<<"avatarName">>,AvatarName}]} ->
      case mu_db:update_user(UserId, Avatar, AvatarName) of
        error -> http_request_util:cowboy_out(mu_json_error_handler,4, Req0, State);
        _ -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
      end;
      _ -> checkKeys(T, Req0, State)
   end.
