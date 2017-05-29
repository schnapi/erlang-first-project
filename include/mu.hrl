-compile({parse_transform,lager_transform}).

-export([render_page/1, render_page/2, isInteger/1]).

-type property() :: boolean() | atom() | tuple().

-spec render_page(module(), map()) -> {ok, iolist()} | {error, string()}.
-spec render_page(module()) -> {ok, iolist()} | {error, string()}.

render_page(Module, Context) ->
  case Module:render(Context) of
    {ok, Out} -> Out
  end.
render_page(Module) ->
  case Module:render() of
    {ok, Out} -> Out
  end.

getUserIdFromHeader(Header) ->
  case catch getUserIdFromHeader1(Header) of
    {'EXIT',Err} ->
      % lager:error("getUserIdFromHeader failed: ~p",[Err]),
      -1;
    Val ->
      Val
  end.

getUserIdFromHeader1(Header) ->
  Cookie = maps:get(<<"cookie">>,Header),
  [_ | SessionId] = binary:split(Cookie,<<"sessionId=">>),
  {UserId} = mu_sessions:get_userid_from_session(SessionId),
  UserId.

getUserIdFromReq(Req) ->
  Header = maps:get(headers,Req),
  getUserIdFromHeader(Header).

getConfigPathImage() -> getConfigPathImage(path_images).
getConfigPathImage(ConfigVal) ->
  lager:error("ConfigVal: ~p",[ConfigVal]),
  case application:get_env(mu,ConfigVal) of
    {ok, PathImage} -> case lists:last(PathImage) of "/" -> PathImage; "\\" -> PathImage; _ -> PathImage ++ "/" end;
    _ -> "/"
  end.

tryUnicode(Message) ->
  case io_lib:printable_unicode_list(Message) of
    true -> unicode:characters_to_binary(Message);
    false -> Message
  end.

isInteger(S) when is_binary(S) ->
try
    _ = list_to_integer(binary_to_list(S)),
    true
catch error:badarg ->
    false
end;
isInteger(S) when is_list(S) ->
  try
      _ = list_to_integer(S),
      true
  catch error:badarg ->
      false
  end.
