-compile({parse_transform,lager_transform}).

-export([render_page/1, render_page/2]).

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
