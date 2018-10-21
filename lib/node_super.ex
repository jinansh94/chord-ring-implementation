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
    spec = %{id: id, start: {ChordNode, :start_link, [id, n, parent]}}
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

  def send_messages(n, max) do
    list = DynamicSupervisor.which_children(:i_am_super)

    list
    |> Enum.each(fn item ->
      {_, pid, _, _} = item
      ChordNode.start_sending(pid, n, max)
    end)
  end

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
end
