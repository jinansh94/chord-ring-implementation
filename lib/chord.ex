defmodule Chord do

  @moduledoc """
    Provides the main and other method to implement the Chord Ring Nerwork.
  """

  def receive_messages(total, count) do
    receive do
      {:hop_count, hop_count} -> receive_messages(total + 1, count + hop_count)
    after
      10_000 -> IO.puts("Average number of hops: #{count / total}")
      NodeSuper.check_all_children()
    end
  end

 @doc """
    This method is used to implement other nodes except the first node in our Chord Ring network  
  """
  def start_nodes(list, _n, _count) when list == [] do
    :ok
  end

  def start_nodes(list, n, count) do
    [head | tail] = list
    child = NodeSuper.start_child(head, n, self())
    ChordNode.join(head, child)

    cond do
      n/count >=10 -> :timer.sleep(50)
      n/count >=4 -> :timer.sleep(1)
      true -> nil
    end
    # NodeSuper.stablize_all_children()
    # IO.gets("")
    #  NodeSuper.check_all_children()
    # IO.gets("")
    #IO.puts(count)

    start_nodes(tail, n, count + 1)
  end

  @doc """
    This is the main method for our Chord Ring implementation. 
  """
  def main(n, mess) do
    NodeSuper.start_link()
    list = Enum.to_list(1..n |> Enum.shuffle())
    IO.puts("adding nodes in the order")
    IO.inspect(list)
    [head | tail] = list
    child = NodeSuper.start_child(head, n, self())
    ChordNode.create(child, n)
    # Node.spawn_link(Node.self(), NodeSuper.stablize_all_children())
    start_nodes(tail, n, 1)
    #IO.puts("started!!")
    #NodeSuper.fix_all_fingers()
    
    NodeSuper.fix_all_fingers_new(n)
    NodeSuper.fix_supervisorList()

    :timer.sleep(20)

    # To test the voluntary terminating a child please uncomment the code below
    #spawn_link(fn -> NodeSuper.vol_die(n,98) end)

    # To test the permanent terminating a child please uncomment the code below
    spawn_link(fn -> NodeSuper.perm_die(n,2) end)
    
    #IO.puts("fixed!!")
    
    #  NodeSuper.check_all_children()
    :timer.sleep(1000)
    NodeSuper.send_messages(mess, n)
    receive_messages(0, 0)

    # for runninge the stabilize, fix_fingers and fix_successorlist continuosly for live system or for fault tolerance 
    # uncomment the below line
    _temppid = spawn_link(fn -> NodeSuper.repeatProcess(n) end)
  end
end
