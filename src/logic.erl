-module(logic).
-export([rpn/1, rpn_test/0]).
-export([infixToPostfix/1, infixToPostfix_test/0]).
-include("../include/mu.hrl").

%% rpn(List()) -> Int() | Float()
%% parses an RPN string and outputs the results.
rpn(Tokens) when is_list(Tokens) ->
    [Res] = lists:foldl(fun rpn/2, [], Tokens),
    Res.

%% rpn(Str(), List()) -> List()
%% Returns the new stack after an operation has been done.
rpn("and", [N1,N2|S]) -> [atom_to_list(list_to_atom(N2) and list_to_atom(N1))|S];
rpn("or", [N1,N2|S]) -> [atom_to_list(list_to_atom(N2) or list_to_atom(N1))|S];
rpn(X, Stack) -> [X|Stack].
% rpn(read(X), Stack) -> [X|Stack].

%% returns 'ok' if successful
rpn_test() ->
    "true" = rpn( string:tokens("true false or true and"," ")),
    "false" = rpn(string:tokens("false false true or true and or false and"," ")),
    "true" = rpn(string:tokens("false false true or true and or true and"," ")),
    ok.


whileNotEqualVal(TopToken, Val,PostfixList,OpStack) ->
  case TopToken of
    _ when TopToken =:= Val -> {PostfixList,OpStack};
    _ -> whileNotEqualVal(lists:last(OpStack),Val,PostfixList ++ [TopToken], lists:droplast(OpStack))
  end.

while([], _, _,PostfixList) -> {PostfixList,[]};
while(OpStack, Prec, Token,PostfixList) ->
  Last = lists:last(OpStack), LastNum = maps:get(Last, Prec), TokenNum=maps:get(Token, Prec),
  case Token of
    _ when LastNum >= TokenNum ->
      while(lists:droplast(OpStack),Prec,Token, PostfixList ++ [Last]);
    _ -> {PostfixList,OpStack}
  end.

forEachToken([], _, OpStack, PostfixList) -> {PostfixList, OpStack};
forEachToken([Token|Tail],Precedence, OpStack, PostfixList) ->
  case Token of
    _ when Token =:= "true"; Token =:= "false" -> PostfixList1 = PostfixList ++ [Token], OpStack1 = OpStack;
    "(" -> OpStack1 = OpStack ++ [Token], PostfixList1 = PostfixList;
    ")" -> {PostfixList1, OpStack1} = whileNotEqualVal(lists:last(OpStack),"(",PostfixList, lists:droplast(OpStack));
    _  when Token =:= "and"; Token =:= "or" -> {PostfixList1, OpStack2} = while(OpStack, Precedence, Token,PostfixList),
      OpStack1 = OpStack2 ++ [Token];
    _ -> PostfixList1 = PostfixList, OpStack1 = OpStack,
      lager:error("Unsupported token: ~p",[Token])
  end,
  forEachToken(Tail,Precedence, OpStack1, PostfixList1).

whileNotEmptyListAppend(PostfixList, []) -> PostfixList;
whileNotEmptyListAppend(PostfixList, OpStack) -> whileNotEmptyListAppend(PostfixList ++ [lists:last(OpStack)], lists:droplast(OpStack)).

infixToPostfix(Tokens) ->
      Precedence = #{"and" => 3, "or" => 2, "(" => 1},
      {PostfixList, OpStack} = forEachToken(Tokens, Precedence, [], []),
      whileNotEmptyListAppend(PostfixList,OpStack).

infixToPostfix_test() ->
  ["true","false","or","true","and"] = infixToPostfix(string:tokens("( true or false ) and true"," ")),
  ["false","false","true","or","true","and","or","true","and"] = infixToPostfix(string:tokens("( false or ( false or true ) and true ) and true"," ")),
  ["true","false","true","and","or"] = infixToPostfix(string:tokens("true or false and true"," ")),
  ok.
