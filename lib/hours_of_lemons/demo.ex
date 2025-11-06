defmodule HoursOfLemons.Demo do
  alias HoursOfLemons.VirtualAssistant

  def run_demo1(query) do
    {:ok, pid} = VirtualAssistant.start_link()
    :ok = VirtualAssistant.query(pid, query)
  end
end
