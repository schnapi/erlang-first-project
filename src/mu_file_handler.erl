-module(mu_file_handler).

-export([out/1,out/2]).

-include("../include/mu.hrl").

-spec out(binary() | pid() | string() | integer() | map() | atom()) -> map().

out(Path,Context) -> out(Path).
out(Path) -> #{ type => file, data => {sendfile, 0, getFileSize(Path),Path}}.

getFileSize(Path) ->
  case file:read_file_info(Path) of
    {ok,{_,FileSize,_,_,_,_,_,_,_,_,_,_,_,_}} -> FileSize;
    {error, Reason} -> error
  end.
