-module(mu_api_edit_files).

-export([init/2]).
-compile(export_all).
-include("../include/mu.hrl").

-spec init(cowboy_req:req(), atom()) -> {ok, cowboy_req:req(), atom()}.
-spec check_args(nonempty_list()) -> any().

init(Req0, State) -> handle_api(cowboy_req:method(Req0), Req0, State).

handle_api(<<"POST">>, Req0, State) ->
  {ok, Body, _} = cowboy_req:read_body(Req0),
  % convert body from json
  % Args = jsx:decode(Body,[{labels, atom}, return_maps]),
  Args = jsx:decode(Body,[return_maps]),

  case check_args(Args) of
    {error,Message} -> http_request_util:cowboy_out(mu_json_error_handler,Message, Req0, State);
    error -> http_request_util:cowboy_out(mu_json_error_handler,2, Req0, State);
    ok -> http_request_util:cowboy_out(mu_json_success_handler,  true, Req0, State);
    {ok,Message} -> http_request_util:cowboy_out(mu_json_success_handler, Message, Req0, State, decodeOff);
    Id when is_integer(Id) -> http_request_util:cowboy_out(mu_json_success_handler,  Id, Req0, State);
    % todo: implement gen_server for sessions, call it at this point
    Map -> http_request_util:cowboy_out(mu_json_success_handler, Map , Req0, State)
  end;
handle_api(_, Req0, State) ->
  http_request_util:cowboy_out(mu_json_error_handler,0, Req0, State).

writeFile(Path,Image) ->
  case Image of
    [FileHead|[Img]] ->
      file:write_file(Path, base64:decode(Img));
    _ -> lager:error("writeFile, no match: ~p",[Image]), error
  end.

check_args(Args) ->
  case Args of
    #{ <<"fileExist">> := FileName } ->
      case file:read_file_info(binary_to_list(FileName)) of
        {ok, FileInfo} -> {error,"eexist"};
        {error, Reason} -> ok
      end;
    #{ <<"writeFile">> := FileName, <<"file">> := File  } -> writeFile(binary_to_list(FileName),binary:split(File,<<",">>));
    #{ <<"removeFiles">> := FileNames } -> Test = [file:delete(binary_to_list(FileName)) || FileName <- FileNames];
    #{ <<"getConflicts">> := FileName, <<"folder">> := Folder } -> mu_db:get_questions_same_image(binary_to_list(Folder), binary_to_list(FileName));
    #{ <<"getAllFiles">> := From } -> Path = getConfigPathImage(list_to_atom(binary_to_list(From))), lager:debug("getAllFiles path: ~p",[Path]),
      case file:list_dir_all(Path) of
        {ok, Res} -> #{<<"folder">> => list_to_binary(Path), <<"files">> => [list_to_binary(X) || X <- Res]};
        Error -> Error
      end;
  _ -> error
  end.
