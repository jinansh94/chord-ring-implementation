defmodule ChordNode do
  use GenServer

  @doc """

  """

  def get_empty_values(id, mul, n) when id + mul > n do
    []
  end

  def get_empty_values(id, mul, n) do
    [{id + mul, nil} | get_empty_values(id, mul * 2, n)]
  end

  def start_link(id, max, parent) do
    finger = get_empty_values(id, 1, max)

    fingers =
      if(finger == []) do
        [{1, nil}]
      else
        finger
      end

    state = %NodeStruct{id: id, keys: [], finger_table: fingers, parent_pid: parent}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def print_keys(pid) do
    :ok = GenServer.call(pid, :print_keys)
  end

  def get_node(id) do
    pid = NodeSuper.get_an_active_child_id()

    new_pid =
      if(pid == id) do
        get_node(id)
      else
        pid
      end

    new_pid
  end

  def join(id, new_pid) do
    #  id = GenServer.call(new_pid, :get_id)
    # IO.puts("new node joined")
    # IO.inspect(new_pid)
    node = get_node(new_pid)
    # IO.puts("asking:")
    # IO.inspect(node)

    # RISKKKYYYYYYYY
    suc_pid = GenServer.call(node, {:get_successor, id})
    # IO.puts("got!!")
    # IO.inspect(suc_pid)
    # REALLYYYYYY????
    GenServer.call(new_pid, {:new_successor, suc_pid})
    # IO.puts("created successfully!!")
    # REALLYY REQUIREDDDD?
    #    GenServer.cast(new_pid, :stablize)
  end

  def create(new_pid, num_keys) do
    # id = GenServer.call(new_pid, :get_id)
    keys = Enum.to_list(1..num_keys)
    # IO.puts("Created!!")
    # IO.inspect(new_pid)
    # REQUIRED??
    :ok = GenServer.call(new_pid, {:initial_values, new_pid, new_pid, keys})
    # GenServer.cast(new_pid, :stablize)
  end

  def start_sending(pid, num, max) do
    GenServer.cast(pid, {:send_messages, num, max})
  end

  defp find_succ_after(_id, list, prev_pid) when list == [] do
    prev_pid
  end

  defp find_succ_after(id, list, prev_pid) do
    [{head_id, head_pid} | tail] = list

    cond do
      head_id == id -> head_pid
      head_id > id -> prev_pid
      true -> find_succ_after(id, tail, head_pid)
    end
  end

  def find_succ_before(_id, list, prev_pid) when list == [] do
    prev_pid
  end

  def find_succ_before(id, list, prev_pid) do
    [{head_id, head_pid} | tail] = list

    cond do
      head_id == id -> head_pid
      head_id < id -> prev_pid
      true -> find_succ_before(id, tail, head_pid)
    end
  end

  defp fix_fingers(list, _prev_pid, _key_list) when list == [] do
    []
  end

  defp fix_fingers(list, prev_pid, key_list) do
    [{head_id, head_pid} | tail] = list

    pid =
      if(head_pid == nil) do
        prev_pid
      else
        head_pid
      end

    succ =
      if(Enum.member?(key_list, head_id)) do
        nil
      else
        GenServer.call(prev_pid, {:get_successor, head_id})
      end

    [{head_id, succ} | fix_fingers(tail, pid, key_list)]
  end

  def handle_cast({:yo_im_ur_new_predecessor, pid, id}, state) do
    GenServer.cast(state.successor, {:delete_these_keys, state.keys})

    new_state =
      unless state.predecessor == nil do
        # REALLLYY? TRY storing the predecessor and successor ID in your state
        # pred_id = GenServer.call(state.predecessor, :get_id)
        pred_id = state.pred_id

        {new_pred, new_pred_id} =
          cond do
            pred_id < id and pred_id < state.id -> {pid, id}
            pred_id > id and pred_id > state.id -> {pid, id}
            pred_id == state.id -> {pid, id}
            true -> {state.predecessor, state.pred_id}
          end

        state
        |> Map.update!(:predecessor, fn _ -> new_pred end)
        |> Map.update!(:pred_id, fn _ -> new_pred_id end)
      else
        state
        |> Map.update!(:predecessor, fn _ -> pid end)
        |> Map.update!(:pred_id, fn _ -> id end)
      end

    {:noreply, new_state}
  end

  def handle_cast(:fix_fingers, state) do
    list = state.finger_table

    [{head_id, head_pid} | tail] = list

    pid =
      if(head_pid == nil) do
        state.successor
      else
        head_pid
      end

    list = [{head_id, pid} | fix_fingers(tail, pid, state.keys)]
    state = state |> Map.update!(:finger_table, fn _ -> list end)
    {:noreply, state}
  end

  def handle_cast(:stablize, state) do
    # IO.puts("stablizing #{state.id}")
    # IO.inspect(self())
    suc_pid = state.successor

    {pid, id} =
      unless suc_pid == self() do
        # RISKYYYYYYY!! But I guess, a call here makes sense
        GenServer.call(suc_pid, :yo_give_me_your_predecessor)
      else
        {state.predecessor, state.pred_id}
      end

    {succ_pid, new_id} =
      cond do
        pid == nil and suc_pid != self() ->
          GenServer.cast(suc_pid, {:yo_im_ur_new_predecessor, self(), state.id})
          {suc_pid, state.succ_id}

        pid != self() ->
          GenServer.cast(pid, {:yo_im_ur_new_predecessor, self(), state.id})
          {pid, id}

        true ->
          {suc_pid, state.succ_id}
      end

    # IO.puts("My new succ piD for #{state.id}")
    # IO.inspect(suc_pid)
    state =
      state
      |> Map.update!(:successor, fn _ -> succ_pid end)
      |> Map.update!(:succ_id, fn _ -> new_id end)

    # IO.puts("done stablizing #{state.id}")
    {:noreply, state}
  end

  """
    def handle_cast(:stablize_old, state) do
      # IO.inspect(self())
      suc_pid = state.successor

      new_state =
        unless suc_pid == self() do
          pid = GenServer.call(suc_pid, :yo_give_me_your_predecessor)
          # IO.inspect(suc_pid)

          suc_pid =
            cond do
              pid == nil ->
                GenServer.call(suc_pid, {:yo_im_ur_new_predecessor, self(), state.id})
                suc_pid

              pid != self() ->
                GenServer.call(pid, {:yo_im_ur_new_predecessor, self(), state.id})
                pid

              true ->
                suc_pid
            end

          state |> Map.update!(:successor, fn _ -> suc_pid end)
        else
          state
        end

      {:noreply, new_state}
    end
  """

  def handle_cast({:delete_these_keys, keys_to_remove}, state) do
    state_keys = state.keys

    # state_keys |> Enum.each(fn x ->  ifEnum.member(keys_to_remove,x))
    {_rem, new_keys} = state_keys |> Enum.split_with(fn x -> Enum.member?(keys_to_remove, x) end)
    state = state |> Map.update!(:keys, fn _x -> new_keys end)

    {:noreply, state}
  end

  def handle_cast({:new_predecessor, pred_pid, pred_id}, state) do
    pred = state.predecessor

    state =
      state
      |> Map.update!(:predecessor, fn _ -> pred_pid end)
      |> Map.update!(:pred_id, fn _ -> pred_id end)

    # IO.puts("Stablizing on")
    ## IO.inspect(pred)

    unless state.successor == self() do
      GenServer.cast(state.successor, {:delete_these_keys, state.keys})
    end

    GenServer.cast(pred, :stablize)

    {:noreply, state}
  end

  ###################################################################################

  def handle_cast({:forward_message, from, num, req_key, hop_count, forw_pid}, state) do
    new_state =
      if(Enum.member?(state.keys, req_key)) do
        # TODO: send the message back to the forwpid!!
        GenServer.cast(forw_pid, {:forward_reply, from, num, req_key, hop_count + 1})
        state
      else
        # succ_pid = state.successor
        succ_pid =
          if(state.id < req_key) do
            find_succ_after(req_key, state.finger_table, state.successor)
          else
            find_succ_before(req_key, state.finger_table, state.successor)
          end

        forward_table = state.forward_table

        table =
          if(forward_table == nil) do
            %{}
          else
            forward_table
          end

        table = table |> Map.put_new_lazy({from, num}, fn -> forw_pid end)

        if(hop_count < 1500) do
          GenServer.cast(succ_pid, {:forward_message, from, num, req_key, hop_count + 1, self()})
        else
          IO.puts("message from #{from}, number #{num} requesting for #{req_key}, failed")
        end

        state |> Map.update!(:forward_table, fn _ -> table end)
      end

    {:noreply, new_state}
  end

  def handle_cast({:forward_reply, from, num, key, hop_count}, state) do
    new_state =
      if(state.id == from) do
        #        IO.puts(
        #          "#{state.id} messages remaining #{state.number_of_messages - 1}, Hop count for #{key} is #{
        #            hop_count
        #          }"
        #        )
        send(state.parent_pid, {:hop_count, hop_count})

        state |> Map.update!(:number_of_messages, fn x -> x - 1 end)
      else
        table = state.forward_table
        {pid, table} = table |> Map.pop({from, num})

        unless pid == nil do
          GenServer.cast(pid, {:forward_reply, from, num, key, hop_count + 1})
        end

        state |> Map.update!(:forward_table, fn _ -> table end)
      end

    {:noreply, new_state}
  end

  def handle_cast({:send_messages, num_messages, max_count}, state) do
    state = state |> Map.update!(:number_of_messages, fn _ -> num_messages end)

    for i <- 1..num_messages do
      random_message = :rand.uniform(max_count)
      GenServer.cast(self(), {:forward_message, state.id, i, random_message, 0, self()})
    end

    {:noreply, state}
  end

  #####################################################################################
  """
    def handle_call({:new_predecessor_old, pred_pid}, _from, state) do
      pred = state.predecessor

      if pred == nil do
        # IO.puts("OMGOMGGMOGMOGMMGOGMOMGOGMGOMGMOGMGOGMOGMOGMOGMGO")
        #      #IO.inspect(self())
      end

      state = state |> Map.update!(:predecessor, fn _ -> pred_pid end)

      #    new_succ =
      #      if(state.successor == self()) do
      #        pred_pid
      #      else
      #        state.successor
      #      end
      #
      #    state = state |> Map.update!(:successor, fn _ -> new_succ end)

      #    unless pred == self() do
      # IO.puts("Stablizing on")
      # IO.inspect(pred)
      GenServer.cast(self(), :stablize)
      #    end

      {:reply, :ok, state}
    end
  """

  def handle_call({:new_successor, suc_pid}, _from, state) do
    state =
      state
      |> Map.update!(:successor, fn _ -> suc_pid end)

    GenServer.cast(suc_pid, {:new_predecessor, self(), state.id})
    # IO.puts("notified successor")
    # RISKY, but makes sense here too!
    {keys, succ_id} = GenServer.call(suc_pid, {:give_me_keys, state.id})
    # IO.puts("got the keys!!")
    # IO.inspect(keys)
    state =
      state
      |> Map.update!(:keys, fn _ -> keys end)
      |> Map.update!(:succ_id, fn _ -> succ_id end)

    {:reply, :ok, state}
  end

  def handle_call({:yo_im_ur_new_predecessor_old, pid, id}, _from, state) do
    GenServer.cast(state.successor, {:delete_these_keys, state.keys})

    new_state =
      unless state.predecessor == nil do
        pred_id = GenServer.call(state.predecessor, :get_id)

        new_pred =
          cond do
            pred_id < id and pred_id < state.id -> pid
            pred_id > id and pred_id > state.id -> pid
            pred_id == state.id -> pid
            true -> state.predecessor
          end

        state |> Map.update!(:predecessor, fn _ -> new_pred end)
      else
        state |> Map.update!(:predecessor, fn _ -> pid end)
      end

    {:reply, :ok, new_state}
  end

  def handle_call(:yo_give_me_your_predecessor, _from, state) do
    {:reply, {state.predecessor, state.pred_id}, state}
  end

  def handle_call({:give_me_keys, id}, _from, state) do
    keys = state.keys
    keys = Enum.sort(keys)
    {mine, not_mine} = Enum.split_while(keys, fn x -> x <= state.id end)

    {not_mine2, _mine2} =
      if(state.id > id) do
        {a, b} = Enum.split_while(mine, fn x -> x <= id end)
        {a ++ not_mine, b}
      else
        {a, b} = Enum.split_while(not_mine, fn x -> x <= id end)
        {a, b ++ mine}
      end

    # state = state |> Map.update!(:keys, fn _ -> mine2 end)

    {:reply, {not_mine2, state.id}, state}
  end

  def handle_call({:get_successor, id}, _from, state) do
    # IO.puts("want successor for #{id}")
    # IO.inspect(state.keys)

    if(Enum.member?(state.keys, id)) do
      {:reply, self(), state}
    else
      # succ = find_succ(id, State.finger_table, nil)
      succ = state.successor
      # IO.puts("asking")
      # IO.inspect(succ)
      # RISKIEST of ALL calls. This one causes deadlocks!!
      pid = GenServer.call(succ, {:get_successor, id})
      {:reply, pid, state}
    end
  end

  def handle_call(:get_id_old, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call({:initial_values, suc_pid, pred_pid, keys}, _from, state) do
    id = state.id

    state =
      state
      |> Map.update!(:successor, fn _x -> suc_pid end)
      |> Map.update!(:predecessor, fn _x -> pred_pid end)
      |> Map.update!(:keys, fn _x -> keys end)
      |> Map.update!(:pred_id, fn _x -> id end)
      |> Map.update!(:succ_id, fn _x -> id end)

    {:reply, :ok, state}
  end

  def handle_call(:print_keys, _from, state) do
    id = state.id
    IO.puts("Printing #{id}")
    IO.inspect(state.finger_table)
    {:reply, :ok, state}
  end
end
