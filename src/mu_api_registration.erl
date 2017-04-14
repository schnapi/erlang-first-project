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
   case KeyValue of
      {<<"get">>, <<"users">>} -> {ok, {false, Users}} = mu_db:get_all_users_id_role(),
        http_request_util:cowboy_out(mu_json_success_handler,Users, Req0, State);
      {<<"deleteUser">>, Id} ->  lager:error("~p",[Id]), case mu_db:delete_user(Id) of
         {ok,_} -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State);
          _ -> http_request_util:cowboy_out(mu_json_error_handler,5, Req0, State)
        end;
      {<<"registration">>,[{<<"username">>,Id},{<<"password">>,Password},{<<"role">>,Role}]} ->
        #{peer := {Ip, _}} = Req0,
        case mu_db:insert_user(Id, Role, Password, Ip) of
          error -> http_request_util:cowboy_out(mu_json_error_handler,4, Req0, State);
          _ -> http_request_util:cowboy_out(mu_json_success_handler,true, Req0, State)
        end;
      _ -> checkKeys(T, Req0, State)
   end.
