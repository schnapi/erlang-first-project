-module(mu_json_error_handler).

-export([out/1,out/2]).

-include("../include/mu.hrl").

 -spec out(binary() | pid() | string() | integer() | map()) -> map().

out(Message,Context) -> out(Message).

out(Message) when is_list(Message) -> generateResponse(Message);
out(Code) when is_integer(Code) ->
  case Code of
    0 -> generateResponse("Wrong request method");
    1 -> generateResponse("Missing username or/and password");
    2 -> generateResponse("Question is empty!");
    3 -> generateResponse("Couldn't start new worker!");
    4 -> generateResponse("Vnos uporabnika ni uspel! Vzrok je lahko, da ta uporabnik že obstaja!");
    5 -> generateResponse("Napaka na spletnem strežniku!");
    6 -> generateResponse("Nobeden od post parametrov se ne ujema!");
    7 -> generateResponse("Neujemanje emaila in gesla.");
    8 -> generateResponse("Uporabnik ni prijavljen.");
    % redirect on login page
    302 -> #{ status => 302, headers=>#{<<"Location">> => <<"login">>}}
  end.

generateResponse(Message) ->
  #{ type => json, data => #{<<"result">> => <<"false">>, <<"error">> => tryUnicode(Message)}}.
