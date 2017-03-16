-module(mu_json_handler).

-export([out/1]).

-include("../include/mu.hrl").

 -spec out(binary() | pid() | string() | integer() | map()) -> map().

out(Pid) when is_pid(Pid) -> #{ type => json, data => #{<<"result">> => list_to_binary(pid_to_list(Pid))}};
out(String) when is_list(String) -> #{ type => json, data => #{<<"result">> => list_to_binary(String)}};
out(Code) when is_integer(Code) ->
  % #pgr{ status = (http koda), headers = [ headerji ], body = <<binarni body>> }
  case Code of
    0 -> generateResponse("Wrong request method");
    1 -> generateResponse("Missing username or/and password");
    2 -> generateResponse("Question is empty!");
    3 -> generateResponse("Couldn't start new worker!")
  end;
out(Map) when is_map(Map) ->
  Reply1 = case Map of
    #{} when map_size(Map) == 0 -> #{<<"result">> => <<"true">>};
    _ -> Map
  end,
  #{ type => json, data => Reply1}.

generateResponse(Message) -> #{ type => json, data => #{<<"result">> => <<"false">>, <<"error">> => list_to_binary(Message)}}.
