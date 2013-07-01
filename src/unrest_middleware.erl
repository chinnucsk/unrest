%%%=============================================================================
%%% @doc Unrest middleware handles the control flow
%%%
%%% @author Dmitrii Dimandt <dmitrii@dmitriid.com>
%%% @copyright 2013 Klarna AB, API team
%%%=============================================================================
-module(unrest_middleware).

%%_* Exports ===================================================================
-export([ execute/2
        ]).

%%_* API =======================================================================

-spec execute(Req0, Env) ->
    {ok, Req, Env} | {error, 500, Req} | {halt, Req} when
    Req0 :: cowboy_req:req()
    ,Req :: cowboy_req:req()
    ,Env :: cowboy_middleware:env().
execute(Req, Env) ->
  io:format("Req ~p~n, Env ~p~n", [Req, Env]),
  {handler, Handler}        = lists:keyfind(handler, 1, Env),
  {handler_opts, Arguments} = lists:keyfind(handler_opts, 1, Env),
  io:format("Handler ~p~n, Args ~p~n", [Handler, Arguments]),
  handle_request(Arguments, Req, Env).


%%_* Internal ==================================================================

handle_request(Config, Req, Env) ->
  io:format("~n~nConfig ~p~nMethod~p~n~n~n", [Config, cowboy_req:method(Req)]),
  {Method, _} = cowboy_req:method(Req),
  run_flow(proplists:get_value(Method, Config), Req, Env).

run_flow(undefined, Req, _Env) ->
  {ok, Req2} = cowboy_req:reply(400, [], "Invalid request!", Req),
  {halt, Req2};
run_flow(Module, Req, Env0) when is_atom(Module) ->
  Env = lists:keyreplace(habdler, 1, Env0, {handler, Module}),
  {ok, Req, Env};
run_flow(Options, Req0, Env0) ->
  case proplists:get_value(<<"__flow__">>, Options) of
    Module when is_atom(Module) ->
      Env = lists:keyreplace(habdler, 1, Env0, {handler, Module}),
      {ok, Req0, Env};
    Flow when is_list(Flow) ->
      Data = [E || E = {K, _} <- Options, K /= <<"__flow__">>],
      Ctx = unrest_context:new([{data, Data}, {req, Req0}]),
      {ok, Req} = unrest_flow:run(Flow, Ctx),
      {halt, Req}
  end.

%%% Local Variables:
%%% erlang-indent-level: 2
%%% End: