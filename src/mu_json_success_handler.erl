-module(mu_json_success_handler).

-export([out/1]).

-include("../include/mu.hrl").

-spec out(binary() | pid() | string() | integer() | map() | atom()) -> map().

out(Pid) when is_pid(Pid) -> generateResponse(pid_to_list(Pid));
out(Message) when is_list(Message) -> generateResponse(Message);
out(Map) when is_map(Map) -> #{ type => json, data => Map};
out(true) -> #{ type => json, data => #{<<"result">> => <<"true">>}}.

generateResponse(Message) -> #{ type => json, data => #{<<"result">> => list_to_binary(Message)}}.
