-module(http_request_util).

-export([cowboy_out/4, cowboy_out/5]).

-include("../include/mu.hrl").

-define(HEADERHTML, #{<<"content-type">> => <<"text/html; charset=utf-8">>}).
-define(HEADERTEXT, #{<<"content-type">> => <<"text/plain; charset=utf-8">>}).
-define(HEADERJSON, #{<<"content-type">> => <<"application/json; charset=utf-8">>}).

-spec cowboy_out(atom(), binary() | integer() | map() | pid()| atom(),cowboy_req:req(), atom()) -> {ok,cowboy_req:req(),atom()}.

cowboy_out(Module,Path, Req0, State) -> cowboy_out(Module,Path, Req0, State,[]).
cowboy_out(Module,Path, Req0, State, Context1) ->
lager:debug("Path: ~p",[Path]),
lager:debug("Module: ~p",[Module]),
  % if some error comes from dtl page then catch an exception and print to
  case catch Module:out(Path,Context1) of
    {'EXIT', Error} ->
      lager:error("Check pattern matching in Module:out: error on path=~p exception=~p",[Path, Error]),
      Pgr = #{ type => json, data => #{ <<"status">> => <<"error">> }};
    Pgr ->
      ok
  end,
  UserId = getUserIdFromReq(Req0),
  #{<<"avatar">> := Avatar, <<"avatarFolder">> := AvatarFolder, <<"avatarName">> := AvatarName, <<"role">> := Role,
  <<"sex">> := Sex, <<"username">> := Username} = mu_db:get_user_registration(UserId),
  BasicMenu = [{<<"Domov">>, <<"index">>, <<"fa-home">>},{<<"Vprašalniki"/utf8>>, <<"questionnaires">>, <<"fa-question-circle">>}, {<<"Dnevnik misli"/utf8>>, <<"thoughts">>, <<"fa-cloud">>}],
  case Role of
    <<"admin">> -> AdminMenu = [{<<"Urejanje avatarjev">>, <<"edit_avatar">>, <<"fa-user">>}, {<<"Admin vprašalniki"/utf8>>,<<"edit_questionnaires">>, <<"fa-edit">>},
    {<<"Admin registracija"/utf8>>,<<"admin_registration">>, <<"fa-edit">>}];
    _ -> AdminMenu = []
  end,
  Menu = [{navMenu,BasicMenu++AdminMenu},{user,mu_db:get_user_registration(UserId)}],
  %default Reply
  DefReply = #{ status => 200, header => ?HEADERHTML, body => <<>>},
  Pgr1 = filter_data(Pgr),
  case Pgr1 of
    #{ type := json, data := ToSeralize} ->
      Reply = DefReply#{ header => ?HEADERJSON, body => jsx:encode(ToSeralize) };
    #{ type := text, data := Context} ->
      Reply = DefReply#{ header => ?HEADERTEXT, body => Context ++ Menu };
    #{ data := Context, view := View} -> % view is dtl file
      Reply = DefReply#{ body => render_page(View, Context ++ Menu) }; % render_page function is in mu.hrl
    #{ view := View } ->
      Reply = DefReply#{ body => render_page(View) };
    #{ status := Status, headers := Header, body := Body} ->
      Reply = DefReply#{ status => Status, header => Header, body => Body };%404
    #{ status := Status, headers := Header} ->
      Reply = DefReply#{ status => Status, header => Header }; %302
    #{ status := Status } ->
      Reply = DefReply#{ status => Status, header => #{} }; %At a minimum, you must provide a header with a status line and a date.
    #{ } ->  Reply = DefReply#{ header => #{} }
  end,

  Req = cowboy_req:reply(maps:get(status, Reply), maps:get(header, Reply), maps:get(body, Reply), Req0),
  % Req = cowboy_req:reply(maps:get(status, Pgr), masp:get(headers, Pgr), maps:get(body, Pgr) , Req0),
% Req = cowboy_req:reply(get(status, Pgr), #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

filter_data(#{ data := Data} = A) when is_list(Data) ->
  Data1 = lists:foldr(fun(A,X) ->
    case A of
      {K,{file, Path}} ->
        {ok, FileBin} = file:read_file(Path),
        [{K, FileBin}|X];
      Othr ->
        [Othr|X]
    end
  end, [], Data),
  A#{ data => Data1 };
filter_data(A) ->
  A.
