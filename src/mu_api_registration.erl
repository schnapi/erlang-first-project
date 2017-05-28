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

% return first match
checkKeys([], Req0, State) -> http_request_util:cowboy_out(mu_json_error_handler,6, Req0, State);
checkKeys([KeyValue|T], Req0, State) ->
   UserId = getUserIdFromReq(Req0),
   case KeyValue of
      {<<"get">>, <<"user">>} -> Data = mu_db:get_user_registration(UserId),
       http_request_util:cowboy_out(mu_json_success_handler,Data, Req0, State);
      {<<"get">>, <<"users">>} -> {ok, {false, Users}} = mu_db:get_users_registration(),
        http_request_util:cowboy_out(mu_json_success_handler,Users, Req0, State);
      {<<"deleteUser">>, Id} ->  case mu_db:delete_user(Id) of
         {ok,_} -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State);
          Error -> lager:error("123: ~p",[Error]), http_request_util:cowboy_out(mu_json_error_handler,5, Req0, State)
        end;
      {<<"registration">>,[{<<"username">>,Id},{<<"password">>,Password},{<<"role">>,Role},{<<"sex">>,Sex}]} ->
        #{peer := {Ip, _}} = Req0,
        case mu_db:insert_user(Id, Role, Password, Ip, Sex,"") of
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
