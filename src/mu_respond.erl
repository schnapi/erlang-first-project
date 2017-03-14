-module(mu_respond).
-include("../include/mu.hrl").

-export([respond_302/3,respond_404/2, respond/4,respond/3,respond_success/2,respond_success/3,respond_error/3 ]).

respond_302(Req0, State, NewLocation) ->
  Req = cowboy_req:reply(302, #{<<"Location">> => list_to_binary(NewLocation)}, <<"">>, Req0),
  {ok, Req, State}.
respond_404(Req0, State) ->
    Req = cowboy_req:reply(404, #{<<"content-type">> => <<"text/plain">>}, <<"404, not found.">>, Req0),
    {ok, Req, State}.

respond(Req0, State, Module, Context) ->
  {ok, Html} = Module:render(Context),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.
respond(Req0, State, Module) ->
  {ok, Html} = Module:render(),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/html">>}, Html , Req0),
  {ok, Req, State}.

% respond(Req0, State, header, response_code, body) ->
%   {ok, Req0, State}.

respond_success(Req0, State, Reply) ->
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_success(Req0, State) ->
  % sending json response
  Reply = jsx:encode(#{<<"result">> => <<"true">>}),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State}.

respond_error(Req0, State, Message) when is_list(Message) ->
  Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => list_to_binary(Message)}),
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply , Req0),
  {ok, Req, State};
respond_error(Req0, State, ErrCode) when is_integer(ErrCode) ->
  % sending error response
  case ErrCode of
    1 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Missing username or/and password">>});
    0 ->
      Reply = jsx:encode(#{<<"result">> => <<"false">>, <<"error">> => <<"Wrong request method">>})
  end,
  Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Reply, Req0),
  {ok, Req, State}.
