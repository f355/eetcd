-module(eetcd_kv).
-include("eetcd.hrl").

-export([put/1, put/3]).
-export([get/1, get/2]).
-export([delete/1, delete/2]).
-export([compact/1, compact/2]).
-export([txn/4]).

%%% @doc Put puts a key-value pair into etcd.
%%% <dl>
%%% <dt> 1. base </dt>
%%% <dd> `eetcd_kv:put(ConnName, Key, Value).' </dd>
%%% <dt> 2. with lease id </dt>
%%% <dd> `eetcd_kv:put(Key, Value, eetcd:with_lease(eetcd:new(ConnName), LeaseID)).' </dd>
%%% <dt> 3. elixir </dt>
%%% <dd>
%%% ```
%%% :eetcd.new(connName)
%%% |> :eetcd.with_key(key)
%%% |> :eetcd.with_value(value)
%%% |> :eetcd.with_lease(leaseId)
%%% |> :eetcd.with_ignore_value()
%%% |> :eetcd.with_ignore_lease()
%%% |> :eetcd.with_timeout(6000)
%%% |> :eetcd_kv.put()
%%% '''
%%% </dd> </dl>
%%% {@link eetcd:with_key/2}, {@link eetcd:with_value/2}, {@link eetcd:with_lease/2},
%%% {@link eetcd:with_ignore_value/2}, {@link eetcd:with_ignore_lease/2}, {@link eetcd:with_timeout/2}
%%% @end
-spec put(router_pb:'Etcd.PutRequest'()) ->
    {ok, router_pb:'Etcd.PutResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
put(Context) -> eetcd_kv_gen:put(Context).

%%% @doc Put puts a key-value pair into etcd with options {@link put/1}
-spec put(eetcd_conn:name(), key(), value()) ->
    {ok, router_pb:'Etcd.PutResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
put(Context, Key, Value) when is_map(Context) ->
    Context0 = eetcd:with_key(Context, Key),
    Context1 = eetcd:with_value(Context0, Value),
    eetcd_kv_gen:put(Context1);
put(ConnName, Key, Value) -> put(eetcd:new(ConnName), Key, Value).

%%% @doc Get retrieves keys.
%%% By default, Get will return the value for Key, if any.
%%% When passed {@link eetcd:with_range_end/2}, Get will return the keys in the range `[Key, End)'.
%%% When passed {@link eetcd:with_from_key/1}, Get returns keys greater than or equal to key.
%%% When passed {@link eetcd:with_revision/2} with Rev > 0, Get retrieves keys at the given revision;
%%% if the required revision is compacted, the request will fail with ErrCompacted.
%%% When passed {@link eetcd:with_limit/1}, the number of returned keys is bounded by Limit.
%%% When passed {@link eetcd:with_sort/2}, the keys will be sorted.
%%% <dl>
%%% <dt> 1.base </dt>
%%% <dd> `eetcd_kv:get(ConnName,Key).'</dd>
%%% <dt> 2.with range end </dt>
%%% <dd> `eetcd_kv:get(eetcd:with_range_end(eetcd:with_key(eetcd:new(ConnName),Key),End)).' </dd>
%%% <dt> 3.Elixir </dt>
%%% <dd>
%%% ```
%%% :eetcd.new(connName)
%%% |> :eetcd.with_key(key)
%%% |> :eetcd.with_range_end(rangeEnd)
%%% |> :eetcd.with_limit(limit)
%%% |> :eetcd.with_revision(rev)
%%% |> :eetcd.with_sort_order(:'ASCEND')  %% 'NONE' | 'ASCEND' | 'DESCEND' enum Etcd.RangeRequest.SortOrder
%%% |> :eetcd.with_sort_target(:'KEY')    %% 'KEY' | 'VERSION' | 'CREATE' | 'MOD' | 'VALUE' enum Etcd.RangeRequest.SortTarget
%%% |> :eetcd.with_serializable()
%%% |> :eetcd.with_keys_only()
%%% |> :eetcd.with_count_only()
%%% |> :eetcd.with_min_mod_revision(minModRev)
%%% |> :eetcd.with_max_mod_revision(maxModRev)
%%% |> :eetcd.with_min_create_revision(minCreateRev)
%%% |> :eetcd.with_max_create_revision(maxCreateRev)
%%% |> :eetcd_kv:get()
%%% '''
%%% </dd>
%%% </dl>
%%% {@link eetcd:with_key/2} {@link eetcd:with_range_end/2} {@link eetcd:with_limit/2}
%%% {@link eetcd:with_revision/2} {@link eetcd:with_sort_order/2}
%%% {@link eetcd:with_sort_target/2} {@link eetcd:with_serializable/1} {@link eetcd:with_keys_only/1}
%%% {@link eetcd:with_count_only/1} {@link eetcd:with_min_mod_revision/2}
%%% {@link eetcd:with_max_mod_revision/2} {@link eetcd:with_min_create_revision/2} {@link eetcd:with_max_create_revision/2}
%%% @end
-spec get(router_pb:'Etcd.RangeRequest'()) ->
    {ok, router_pb:'Etcd.RangeResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
get(Context) when is_map(Context) -> eetcd_kv_gen:range(Context).
%%% @doc Get retrieves keys with options.
-spec get(context()|eetcd_conn:name(), key()) ->
    {ok, router_pb:'Etcd.RangeResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
get(Context, Key) when is_map(Context) -> eetcd_kv_gen:range(eetcd:with_key(Context, Key));
get(ConnName, Key) -> eetcd_kv_gen:range(eetcd:with_key(eetcd:new(ConnName), Key)).

%%% @doc Delete deletes a key, or optionally using eetcd:with_range(End), [Key, End).
%%% <dl>
%%% <dt> 1.base </dt>
%%% <dd> `eetcd_kv:delete(ConnName,Key).' </dd>
%%% <dt> 2.with range end </dt>
%%% <dd> `eetcd_kv:delete(eetcd:with_range_end(eetcd:with_key(eetcd:new(ConnName),Key), End)).'</dd>
%%% <dt> 3.elixir </dt>
%%% <dd>
%%% ```
%%% :eetcd.new(ConnName)
%%% |> :eetcd.with_key(key)
%%% |> :eetcd.with_range_end(rangeEnd)
%%% |> :eetcd.with_prev_kv()
%%% |> :eetcd_kv.delete()
%%% '''
%%% </dd> </dl>
%%% {@link eetcd:with_key/2} {@link eetcd:with_range_end/2} {@link eetcd:with_prev_kv/1}
%%% @end
-spec delete(key() | router_pb:'Etcd.DeleteRangeRequest'()) ->
    {ok, router_pb:'Etcd.DeleteRangeResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
delete(Context) when is_map(Context) -> eetcd_kv_gen:delete_range(Context).
%%% @doc Delete deletes a key with options
-spec delete(key()|context(), key()) ->
    {ok, router_pb:'Etcd.DeleteRangeResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
delete(Context, Key) when is_map(Context) -> eetcd_kv_gen:delete_range(eetcd:with_key(Context, Key));
delete(ConnName, Key) -> eetcd_kv_gen:delete_range(eetcd:with_key(eetcd:new(ConnName), Key)).

%% @doc Compact compacts etcd KV history before the given revision.
%%% <dl>
%%% <dt> 1.base </dt>
%%% <dd> `eetcd_kv:compact(ConnName,Revision).'</dd>
%%% <dt> 2.with physical</dt>
%%% <dd> `eetcd_kv:compact(eetcd:with_physical(eetcd:with_revision(eetcd:new(ConnName), Revision))).'</dd>
%%% <dt> 3.Elixir </dt>
%%% <dd>
%%% ```
%%% :eetcd.new(ConnName)
%%% |> :eetcd.with_revision(revision)
%%% |> :eetcd.with_physical()
%%% |> :eetcd_kv.compact()
%%% '''
%%% </dd> </dl>
%%% {@link eetcd:with_revision/2} {@link eetcd:with_physical/1}
%%% @end
-spec compact(integer() | router_pb:'Etcd.CompactionRequest'()) ->
    {ok, router_pb:'Etcd.CompactionResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
compact(Context) when is_map(Context) -> eetcd_kv_gen:compact(Context).
%% @doc Compact compacts etcd KV history before the given revision with options
-spec compact(eetcd_conn:name()|context(), integer()) ->
    {ok, router_pb:'Etcd.CompactionResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
compact(Context, Revision) when is_map(Context) -> eetcd_kv_gen:compact(eetcd:with_rev(Context, Revision));
compact(ConnName, Revision) -> eetcd_kv_gen:compact(eetcd:with_rev(eetcd:new(ConnName), Revision)).

%%% @doc Txn creates a transaction.
%% <dd>If takes a list of comparison. If all comparisons passed in succeed,</dd>
%% <dd>the operations passed into Then() will be executed.</dd>
%% <dd>Or the operations passed into Else() will be executed.</dd>
%% <dd>Then takes a list of operations. The Ops list will be executed, if the comparisons passed in If() succeed.</dd>
%% <dd> Else takes a list of operations. The Ops list will be executed, if the comparisons passed in If() fail.</dd>
%% Cmp = eetcd:with_key(#{}, Key),
%% If = eetcd_compare:value(Cmp, ">", Value),
%% Then = eetcd_op:put(eetcd:with_value(eetcd:with_key(eetcd:new(), Key), "NewValue")),
%% Else = eetcd_op:delete_range(eetcd:with_key(eetcd:new(), Key))
%%% @end
-spec txn(name()|context(), [router_pb:'Etcd.Compare'()], [router_pb:'Etcd.RequestOp'()], [router_pb:'Etcd.RequestOp'()]) ->
    {ok, router_pb:'Etcd.TxnResponse'()} | {error, {'grpc_error', non_neg_integer(), binary()}} | {error, term()}.
txn(Context, If, Then, Else) when is_map(Context) ->
    Txn = maps:merge(#{compare => If, success => Then, failure => Else}, Context),
    eetcd_kv_gen:txn(Txn);
txn(ConnName, If, Then, Else) ->
    txn(eetcd:new(ConnName), If, Then, Else).
