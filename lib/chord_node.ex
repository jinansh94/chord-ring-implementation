defmodule ChordNode do
  use GenServer

 @moduledoc """
  Provides method for creating nodes, joining new nodes
 """

  @doc """
    Enables the finger table values for a new node with keys and corresponding nodes will be nil
  """
  def get_empty_values(id, mul, n) when id + mul > n do
    []
  end

  def get_empty_values(id, mul, n) do
    [{id + mul, nil} | get_empty_values(id, mul * 2, n)]
  end

  @doc """
    Starts the node with initial state that contains parent pid, id and finger table
  """
  def start_link(id, max, parent) do
    finger = get_empty_values(id, 1, max)

    fingers =
      if(finger == []) do
        [{1, nil}]
      else
        finger
      end

    ##################################################################################################################################
    ## New Finger Table implementation Jinansh #######################################################################################
    ##################################################################################################################################
    supervisorListIn = getemptySuperList(id,1,max) 
    fingerTablePopulate = %{}
    finger_new = get_empty_values_new(id, 1, max, fingerTablePopulate)

    fingerNew = 
      if(finger_new == %{}) do
        %{1 => nil }
      else
        finger_new
      end

    ##################################################################################################################################
    ## New Finger Table implementation Jinansh End ###################################################################################
    ##################################################################################################################################

    #state = %NodeStruct{id: id, keys: [], finger_table: fingers, parent_pid: parent}

    ##################################################################################################################################
    ## New Finger Table implementation Jinansh #######################################################################################
    ##################################################################################################################################

    state = %NodeStruct{id: id, keys: [], finger_table: fingers, parent_pid: parent, fingure_table_new: fingerNew, supervisorList: supervisorListIn}

    ##################################################################################################################################
    ## New Finger Table implementation Jinansh End ###################################################################################
    ##################################################################################################################################

    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def print_keys(pid) do
    :ok = GenServer.call(pid, :print_keys)
  end

  @doc """
    This method is used by the join method to return a pid of an exciting node in the netwrok
  """
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

  @doc """
    This is method is used to join any other new nodes that to our main network 
  """
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

  @doc """
    Creates the first node of the Chord Ring with all the keys assigned to that node and successor and predecessor is set to itself
  """
  def create(new_pid, num_keys) do
    # id = GenServer.call(new_pid, :get_id)
    keys = Enum.to_list(1..num_keys)
    # IO.puts("Created!!")
    # IO.inspect(new_pid)
    # REQUIRED??
    :ok = GenServer.call(new_pid, {:initial_values, new_pid, new_pid, keys})
    # GenServer.cast(new_pid, :stablize)
  end

  @doc """
    This method sends the message to each node to search for keys
  """ 
  def start_sending(pid, num, max) do
    GenServer.cast(pid, {:send_messages, num, max})
  end

  defp find_succ_after(_id, list, prev_pid) when list == [] do
    prev_pid
  end

  defp find_succ_after(id, list, prev_pid) do
    [{head_id, head_pid} | tail] = list

    cond do
      head_pid == nil -> prev_pid
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
      head_pid == nil -> prev_pid
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

  @doc """
    This handle_call method is used to update the predecessor of a node in most cases it will be the new node that has join the network.
  """
  def handle_cast({:yo_im_ur_new_predecessor, pid, id}, state) do
    GenServer.cast(state.successor, {:delete_these_keys, state.keys})

    new_state =
      unless state.predecessor == nil do
        
        
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

  @doc """
    This method is used to update the finger table for each node
  """
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

  @doc """
    This handle_cast method is the stablize method for the Chord Ring Netwrok.

    It basically checks whether it's adjusts it's successor to a right value if there is any new joined node in the network
    It also adjusts the predecessor of a new formed node
  """
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
        #Jinansh Understand this from Ashwin please...............................................
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

  @doc """
    This handle_cast method is used to remove the keys that it's predecessor have.
  """
  def handle_cast({:delete_these_keys, keys_to_remove}, state) do
    state_keys = state.keys

    # state_keys |> Enum.each(fn x ->  ifEnum.member(keys_to_remove,x))
    {_rem, new_keys} = state_keys |> Enum.split_with(fn x -> Enum.member?(keys_to_remove, x) end)
    state = state |> Map.update!(:keys, fn _x -> new_keys end)

    {:noreply, state}
  end

  @doc """
    This handle_cast method is used to inform a node to change it's predecessor pid and id.

    It also informs it's successor to remove keys it already possesses
    It also informs it's predecessor to stabilize i.e. change it's successor if any new node has joind the network
  """
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

  @doc """
    This handle_cast method is used to inform a node to find the messages from the Chord 
  """
  def handle_cast({:forward_message, from, num, req_key, hop_count, forw_pid}, state) do
    new_state =
      if(Enum.member?(state.keys, req_key)) do
        # TODO: send the message back to the forwpid!!
        GenServer.cast(forw_pid, {:forward_reply, from, num, req_key, hop_count + 1})
        state
      else
        # succ_pid = state.successor

        finger_table_for_find = Map.to_list(state.fingure_table_new)

        succ_pid =
          if(state.id < req_key) do
            find_succ_after(req_key, finger_table_for_find, state.successor)
          else
            find_succ_before(req_key, finger_table_for_find, state.successor)
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
                #IO.puts(
                #  "#{state.id} messages remaining #{state.number_of_messages - 1}, Hop count for #{key} is #{
                #    hop_count
                #  }"
                #)
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

  @doc """
    This handle_cast method is used to inform a node to find the messages from the Chord 
  """
  def handle_cast({:send_messages, num_messages, max_count}, state) do
    state = state |> Map.update!(:number_of_messages, fn _ -> num_messages end)

    for i <- 1..num_messages do
      random_message = :rand.uniform(max_count)
      GenServer.cast(self(), {:forward_message, state.id, i, random_message, 0, self()})
    end

    {:noreply, state}
  end

  #####################################################################################

  @doc """
    This handle_call method is used to join the new node in the network.

    It updtaes the successor of the new node from nil to actual successor 
    It also informs it's new successor to update it's predecessor to itself that call internally also handles the stabilization of already exciting network
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

  @doc """
    This handle_call method is used to get the predecessor for a particular node
  """
  def handle_call(:yo_give_me_your_predecessor, _from, state) do
    {:reply, {state.predecessor, state.pred_id}, state}
  end

  @doc """
    This handle_call method is used to get the predecessor for a particular node
  """
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

  @doc """
    This method is used in the when a new node is joined in the network
    
    It finds the pid(place) of the exciting node where the new node can join in the network
  """
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

  @doc """
    This is a Genserver call mathod for the first node that is being created as part of our Chord Ring Formation
  """

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

  def handle_call(:print_keys_unused, _from, state) do
    id = state.id
    IO.puts("Printing #{id}")
    IO.inspect(state.finger_table)
    {:reply, :ok, state}
  end

  ##################################################################################################################################
  ## New Finger Table implementation Jinansh #######################################################################################
  ##################################################################################################################################
  
  def handle_cast({:update_fingertable, id, key_pid}, state) do
    fingerTableOld = state.fingure_table_new
    fingerTableUpdate = Map.update!(fingerTableOld, id, fn _ -> key_pid end)

    new_state = state |> Map.update!(:fingure_table_new, fn _-> fingerTableUpdate end)

    #IO.inspect(new_state)

    {:noreply,new_state}
  end

  def handle_cast({:get_succ_for_fingertable, id, node_pid, max_search, count}, state) do
    if count >= max_search do
        GenServer.cast(node_pid,{:update_fingertable, id, nil})
    else 
      if (Enum.member?(state.keys,id)) do
        GenServer.cast(node_pid,{:update_fingertable, id, self()})
      else 
        succ = state.successor
        GenServer.cast(succ,{:get_succ_for_fingertable, id, node_pid, max_search, count+1})
      end 
    end  
    {:noreply,state}
  end 

  def handle_cast({:fix_fingers_new, max_search}, state) do
    list = Map.to_list(state.fingure_table_new)

    [{head_id, head_pid} | tail] = list
	
    pid =
      if(head_pid == nil) do
        state.successor
      else
        head_pid
      end

    fingerTableOld = state.fingure_table_new

    fingerTableUpdate = Map.update!(fingerTableOld, head_id, fn _ -> pid end)
  
    new_state = state |> Map.update!(:fingure_table_new, fn _-> fingerTableUpdate end)
    
    fix_fingers_new(tail, pid, state.keys, self(), max_search)
    {:noreply, new_state}
  end

  defp fix_fingers_new(list, _prev_pid, _key_list, _node_pid, _max_search) when list == [] do
  
  end

  defp fix_fingers_new(list, prev_pid, key_list, node_pid, max_search) do
    [{head_id, head_pid} | tail] = list

    pid =
      if(head_pid == nil) do
        prev_pid
      else
        head_pid
      end

    if(Enum.member?(key_list, head_id)) do
      GenServer.cast(node_pid,{:update_fingertable, head_id, nil})
    else
      GenServer.cast(prev_pid, {:get_succ_for_fingertable, head_id, node_pid, max_search, 0})
    end

    fix_fingers_new(tail, pid, key_list,node_pid,max_search)
  end

  def get_empty_values_new(id, mul, n, fingerTablePopulate) when id + mul > n do
    fingerTablePopulate
  end

  def get_empty_values_new(id, mul, n, fingerTablePopulate) do
    fingerTablePopulate = Map.put_new(fingerTablePopulate, id + mul, nil)
    get_empty_values_new(id, mul * 2, n, fingerTablePopulate)
  end

  ############################################################################################################################
  ############################################################################################################################
  ############################################################################################################################
  ############################################################################################################################

  def getemptySuperList(id,count,max) when count == 6 do
    []
  end

  def getemptySuperList(id,count,max) do
    if id == max do
      id = 0 
      [{id+1,nil} | getemptySuperList(id+1,count+1,max)]
    else
      [{id+1,nil} | getemptySuperList(id+1,count+1,max)]
    end
  end
  
  def middelManForpopulateSuperVisorList(supervisorList) do
    [info | tail ] = supervisorList
    {nextid, nextPid} = List.first(tail)
    populateSuperVisorList(nextid,nextPid,tail)
  end

  def populateSuperVisorList(succPid,supervisorList) when supervisorList == [] do
    # Ask ashwin how to handle this .....................................
    IO.puts("Chord Ring Network is broken")
    []
  end

  def populateSuperVisorList(succId, succPid, supervisorList) do
    succSuperVisorList =
      try do
        GenServer.call(succPid,{:getNextSuccSupervisorList})
        |> List.delete_at(4)
        |> List.insert_at(0,{succId,succPid})
      catch
        :exit,_ -> middelManForpopulateSuperVisorList(supervisorList)
      end
   succSuperVisorList
  end

  def handle_cast({:fix_superVisorList}, state) do
    succId = state.succ_id
    succPid = state.successor

    supervisorListUp = populateSuperVisorList(succId, succPid,state.supervisorList)

    if supervisorListUp == [] do
      {:stop, :normal, state}
    end

    {newSuccId,newSuccPid} = List.first(supervisorListUp)
    
    state = state 
      |> Map.update!(:supervisorList, fn _ -> supervisorListUp end)

    state = state 
      |> Map.update!(:successor, fn _ -> newSuccPid end)

    state = state 
      |> Map.update!(:succ_id, fn _ -> newSuccId end)


    #IO.inspect(state)

    {:noreply, state}
  end

  def handle_call({:getNextSuccSupervisorList},_from,state) do
    {:reply, state.supervisorList , state}
  end

  def handle_cast({:please_die,max_search}, state) do
    GenServer.cast(state.successor,{:vol_give,state.keys,state.predecessor,state.pred_id})
    GenServer.cast(state.predecessor,{:vol_give_pred,state.successor,state.succ_id,max_search})

    {:stop, :normal, state}
  end

  def handle_cast({:vol_give,key,pred_pid,pred_id}, state) do
    old_list = state.keys
    new_list = old_list ++ key
    state = state |> Map.update!(:predecessor, fn _x -> pred_pid end)
                  |> Map.update!(:keys, fn _x -> new_list end)
                  |> Map.update!(:pred_id, fn _x -> pred_id end)

    {:noreply, state}
  end

  def handle_cast({:vol_give_pred,succ_pid,succ_id,max_search}, state) do
   
    state = state |> Map.update!(:successor, fn _x -> pred_pid end)
                  |> Map.update!(:succ_id, fn _x -> succ_id end)

    GenServer.cast(pid, {:fix_fingers_new, max_search})
    GenServer.cast(pid, {:fix_superVisorList})

    {:noreply, state}
  end

end
