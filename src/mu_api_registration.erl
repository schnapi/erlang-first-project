-module(mu_api_registration).

-export([init/2]).

-include("../include/mu.hrl").

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
  mu_db:get_question_answer(QId,SQL).

generateSQLString([Q,-1|T],[]) -> generateSQLString(T," questions.id="++integer_to_list(Q));
generateSQLString([Q,-1|T],List) -> generateSQLString(T,List ++ " or questions.id="++integer_to_list(Q));
generateSQLString([Q,A|T],[]) -> generateSQLString(T," questions.id="++integer_to_list(Q)++" and answers.id="++integer_to_list(A));
generateSQLString([Q,A|T],List) -> generateSQLString(T,List ++ " or questions.id="++integer_to_list(Q)++" and answers.id="++integer_to_list(A));
generateSQLString([],List) -> List.

writeFile1(File, Answer,Image,Question) ->
  csv_gen:row(File, ["Slika", Image]),
  csv_gen:row(File, ["Vprašanje", Question]),
  csv_gen:row(File, ["Odgovor", Answer]).
writeFile(File, QId, Epoch,ProcessingSpeed, BrainCapacity,BraintWeight,State) ->
  csv_gen:row(File,[]),
  csv_gen:row(File, ["Vprašalnik", "Čas in datum","Hitrost procesiranja", "Možganska kapaciteta","Teža možganov"]),
  csv_gen:row(File, [QId, Epoch,ProcessingSpeed, BrainCapacity,BraintWeight]),
  [writeFile1(File, Answer,Image,Question) || #{<<"answer">> := Answer, <<"image">> := Image,<<"question">> := Question} <- getResult(QId,State)].
% return first match
checkKeys([], Req0, State) -> http_request_util:cowboy_out(mu_json_error_handler,6, Req0, State);
checkKeys([KeyValue|T], Req0, State) ->
   UserId = getUserIdFromReq(Req0),
   case KeyValue of
      {<<"get">>, <<"user">>} -> Data = mu_db:get_user(UserId),
       http_request_util:cowboy_out(mu_json_success_handler,Data, Req0, State);
      {<<"get">>, <<"users">>} -> {ok, {false, Users}} = mu_db:get_users_registration(),
        http_request_util:cowboy_out(mu_json_success_handler,Users, Req0, State);
        {<<"get">>, <<"results">>} -> {ok, {false, Res}} = mu_db:get_results(UserId),
        FilePath=getConfigPathCsv()++binary_to_list(getUserIdFromReq(Req0))++".csv",
        {ok, File} = file:open(FilePath, [write]),
        [writeFile(File, QId, Epoch,ProcessingSpeed, BrainCapacity,BraintWeight,State)
         || #{<<"questionnaire_id">> := QId, <<"state">> := State,<<"epoch">> := Epoch,
         <<"processingSpeed">> := ProcessingSpeed,<<"brainCapacity">> :=BrainCapacity,
         <<"braintWeight">> := BraintWeight} <- Res],

          file:close(File),
          http_request_util:cowboy_out(mu_json_success_handler,tryUnicode(FilePath), Req0, State);
        % http_request_util:cowboy_out(mu_file_handler,getConfigPathCsv()++binary_to_list(getUserIdFromReq(Req0))++".csv", Req0, State);
      {<<"deleteUser">>, Id} ->  case mu_db:delete_user(Id) of
         {ok,_} -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State);
          Error -> lager:error("123: ~p",[Error]), http_request_util:cowboy_out(mu_json_error_handler,5, Req0, State)
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
