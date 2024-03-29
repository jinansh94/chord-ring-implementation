defmodule NodeSuper do

 @moduledoc """
  Provides different methods for handling the Dynamic Supervisor for different GenServers in our code.
 """

  @doc """
    Starts the Dynamic Supervisor with startegy and a unique id for this supervisor
  """
  def start_link() do
    DynamicSupervisor.start_link(strategy: :one_for_one, name: :i_am_super)
  end

  # def init(strategy) do
  #    DynamicSupervisor.init(strategy)
  #  end
  def start_child(id, n, parent) do
    spec = %{id: id, restart: :temporary, start: {ChordNode, :start_link, [id, n, parent]}}
    #  IO.inspect(spec)
    {:ok, child} = DynamicSupervisor.start_child(:i_am_super, spec)
    child
  end

  @doc """
    This method is used in the ChordNode module to gent a random pid of a node 
  """
  def get_an_active_child_id() do
    list = DynamicSupervisor.which_children(:i_am_super)
    {_, pid, _, _} = list |> Enum.random()
    # IO.inspect({id, pid})
    pid
  end

  def stablize_all_children() do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      GenServer.cast(pid, :stablize)
      :timer.sleep(100)
    end)

    # stablize_all_children()
  end

  def check_all_children() do
    list = DynamicSupervisor.which_children(:i_am_super)
    #  IO.puts("OHHHHHHHHH YEAHHHHHHHHHHHHH")

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      :ok = ChordNode.print_keys(pid)
    end)
  end

  @doc """
    This method is used to start the sending of messages to find the key in the network
  """
  def send_messages(n, max) do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      ChordNode.start_sending(pid, n, max)
    end)
  end

  @doc """
    This method is used to populate the symbol table of all the nodes after the Chord Ring Netwrok is formed
  """
  def fix_all_fingers() do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {id, pid, _, _} = item
      #    IO.puts("Fixing fingers for #{id}")
      #    IO.inspect(id)
      GenServer.cast(pid, :fix_fingers)
      :timer.sleep(10)
      #    IO.puts("Fixed fingers for #{id}")
      end)
  end

  ##################################################################################################################################
  ## New Finger Table implementation Jinansh #######################################################################################
  ##################################################################################################################################

  def fix_all_fingers_new(max_search) do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {id, pid, _, _} = item
      #    IO.puts("Fixing fingers for #{id}")
      #    IO.inspect(id)
      GenServer.cast(pid, {:fix_fingers_new, max_search})
      :timer.sleep(5)
      #    IO.puts("Fixed fingers for #{id}")
    end)
  end

  
  def fix_supervisorList() do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {id, pid, _, _} = item
      GenServer.cast(pid, {:fix_superVisorList})
      :timer.sleep(1)
    end)
  end

  def repeatProcess(max_search) do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {id, pid, _, _} = item
      GenServer.cast(pid, :stablize)
      GenServer.cast(pid, {:fix_fingers_new, max_search})
      GenServer.cast(pid, {:fix_superVisorList})
      :timer.sleep(5)
    end)

    :timer.sleep(5000)
    repeatProcess(max_search)
  end

  def vol_die(max_search,no_die) do
    #IO.puts("vol_die is coming")
    list = DynamicSupervisor.which_children(:i_am_super)

    list  |> Enum.shuffle()
          |> Enum.take(no_die)
          |> Enum.each(fn item -> 
            {_, pid, _, _} = item
            IO.inspect(pid)
            GenServer.cast(pid,{:please_die,max_search})
            end)
  end

  def perm_die(max_search,no_die) do
    #IO.puts("perm_die is coming")
    list = DynamicSupervisor.which_children(:i_am_super)

    list  |> Enum.shuffle()
          |> Enum.take(no_die)
          |> Enum.each(fn item -> 
            {_, pid, _, _} = item
            IO.inspect(pid)
            DynamicSupervisor.terminate_child(:i_am_super,pid)
            end)
  end

end