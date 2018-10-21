defmodule NodeStruct do

  @doc """
    This is the basic struct for the implementation of a state in node GenServer.
  """
  
  defstruct [
    :id,
    :successor,
    :predecessor,
    :keys,
    :finger_table,
    :pred_id,
    :succ_id,
    :forward_table,
    :number_of_messages,
    :parent_pid
  ]
end
