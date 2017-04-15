-module(mu_sessions).

-export([check_session_validation/1,
         create_new_session/2,
         set_sessionid/2, generate_sessionid/2]).

-include("../include/mu.hrl").

-define(SUPERVISIOR, mu_sup).
-define(GENSERVER, mu_session).
-define(CHILDSPEC, #{id => erlang:now(),
             start => { ?GENSERVER, start_link, []},
             restart => temporary,
             shutdown => 2000, % Shutdown=after 2000 seconds if no response from child
             modules => [?GENSERVER]}).

% validate session
check_session_validation(Req) ->
  case get_sessionid(Req) of
    {false} ->
      {false};
    {ok, SessionId} ->
      case get_session_pid(SessionId) of
        % ni shranjenega pida
        {false} ->
          {false};
        % je shranjen Pid, preverim če ta gen_server še teče -> veljavnost seje
        {ok, Pid} ->
          case process_info(Pid) of
            undefined ->
              {false};
            _ ->
              mu_session:update_session_expiry_time(Pid),
              {ok}
          end
      end
  end.

% get sessioinid from cookie
get_sessionid(Req0) ->
  Cookies = cowboy_req:parse_cookies(Req0),
  case lists:keyfind(<<"sessionId">>, 1, Cookies) of
    {_, SessionId} ->
      {ok, SessionId};
    _ ->
      % cookie has no sessionid, false
      {false}
  end.

% set sessionid in cookie
set_sessionid(Req0, SessionId) ->
  Req = cowboy_req:set_resp_cookie(<<"sessionId">>, SessionId, Req0, #{domain=>"localhost", path=>"/"}),
  {ok, Req}.

% vrne ok in pid če je, drugače false
% primer klica: get_session_pid("asdasd123asdfsdf")
get_session_pid(SessionId) ->
  case ets:lookup(mu_sessions, SessionId) of
    [] ->
      % no pid saved
      {false};
    % return only pid
    [{SessionId,Pid}] ->
      {ok, Pid}
  end.

% start new session for user
create_new_session(Ip, Username) ->
  case supervisor:start_child(?SUPERVISIOR, ?CHILDSPEC) of
    {ok, Pid} ->
      {SessionId} = generate_sessionid(Ip, Username),
      ets:insert(mu_sessions, {SessionId, Pid}),
      {SessionId, Pid}
  end.

% generate token for sessionid
generate_sessionid(Ip, Username) ->
  {_, TimeStamp, _} = erlang:timestamp(),
  SessionData = tuple_to_list(Ip) ++ binary_to_list(Username) ++ ":" ++ erlang:integer_to_list(TimeStamp, 16),
  Hash = butil:dec2hex(crypto:hash(sha256, SessionData)),
  RandBytes = butil:dec2hex(crypto:hash(sha256, crypto:strong_rand_bytes(32))),
  SessionId = list_to_binary(binary_to_list(Hash) ++ binary_to_list(RandBytes)),
  {SessionId}.
