-module(mu_json_error_handler).

-export([out/1]).

-include("../include/mu.hrl").

 -spec out(binary() | pid() | string() | integer() | map()) -> map().

out(Message) when is_list(Message) -> generateResponse(Message);
out(Code) when is_integer(Code) ->
  case Code of
    0 -> generateResponse("Wrong request method");
    1 -> generateResponse("Missing username or/and password");
    2 -> generateResponse("Question is empty!");
    3 -> generateResponse("Couldn't start new worker!");
    % redirect on login page
    302 -> #{ status => 302, headers=>#{<<"Location">> => <<"login">>}}
  end.

generateResponse(Message) -> #{ type => json, data => #{<<"result">> => <<"false">>, <<"error">> => list_to_binary(Message)}}.
