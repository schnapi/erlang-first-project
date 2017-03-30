-module(mu_json_success_handler).

-export([out/1]).

-include("../include/mu.hrl").

-spec out(binary() | pid() | string() | integer() | map() | atom()) -> map().

out(Pid) when is_pid(Pid) -> generateResponse(pid_to_list(Pid));
out(List) when is_list(List) -> #{ type => json, data => List};
out(Map) when is_map(Map) -> #{ type => json, data => Map};
out(Id) when is_integer(Id) -> #{ type => json, data => #{<<"result">> => Id}};
out(true) -> generateResponse("true").

generateResponse(Message) -> #{ type => json, data => #{<<"result">> => list_to_binary(Message)}}.
