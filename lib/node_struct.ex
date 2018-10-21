defmodule NodeStruct do
  @doc """
  The basic struct for the node GenServer.
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
