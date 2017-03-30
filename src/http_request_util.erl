-module(http_request_util).

-export([cowboy_out/4]).

-include("../include/mu.hrl").

-define(HEADERHTML, #{<<"content-type">> => <<"text/html">>}).
-define(HEADERJSON, #{<<"content-type">> => <<"application/json">>}).

-spec cowboy_out(atom(), binary() | integer() | map() | pid()| atom(),cowboy_req:req(), atom()) -> {ok,cowboy_req:req(),atom()}.

cowboy_out(Module,Path, Req0, State) ->
  % if some error comes from dtl page then catch an exception and print to
  case catch Module:out(Path) of
    {'EXIT', Error} ->
      lager:error("error on path=~p exception=~p",[Path, Error]),
      Pgr = #{ type => json, data => #{ <<"status">> => <<"error">> }};
    Pgr ->
      ok
  end,

  lager:debug("dasdas: ~p",[Pgr]),
  %default Reply
DefReply = #{ status => 200, header => ?HEADERHTML, body => <<>>},
  case Pgr of
    #{ type := json, data := ToSeralize} ->
      lager:debug("ToSeralize: ~p",[ToSeralize]),
      JsonOut = jsx:encode(ToSeralize),
        lager:debug("JsonOut: ~p",[JsonOut]),
      Reply = DefReply#{ header => ?HEADERJSON, body => JsonOut };
    #{ data := Context, view := View} -> % view is dtl file
      Reply = DefReply#{ body => render_page(View, Context) }; % render_page function is in mu.hrl
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
