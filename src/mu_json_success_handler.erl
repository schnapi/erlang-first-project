-module(mu_json_success_handler).

-export([out/1]).

-include("../include/mu.hrl").

-spec out(binary() | pid() | string() | integer() | map() | atom()) -> map().

out(Pid) when is_pid(Pid) -> #{ type => json, data => list_to_binary(pid_to_list(Pid))};
out(Message) when is_list(Message) -> generateResponse(Message);
out(Message) when is_map(Message) -> generateResponse(Message);
out(Message) when is_integer(Message) -> generateResponse(Message);
out(true) -> generateResponse("true").

% generateResponse(Message) -> #{ type => json, data => #{<<"result">> => list_to_binary(Message)}}.
generateResponse(Message) -> #{ type => json, data => Message}.
