-compile({parse_transform,lager_transform}).

-export([render_page/2]).

render_page(Module, Context) ->
  case Module:render(Context) of
    {ok, Out} -> Out
  end.
render_page(Module) ->
  case Module:render() of
    {ok, Out} -> Out
  end.
