defmodule HoursOfLemons do
  def ask_virtual_assistant(query) do
    # Print answer to query to terminal
    inital_state = []
    {:ok, pid} = HoursOfLemons.VirtualAssistant.start_link(inital_state)
    {:ok, answer} = HoursOfLemons.VirtualAssistant.query(pid, query)
    IO.puts(answer)

    # Generate HTML output file, print filepath to terminal
    {:ok, html_path} = HoursOfLemons.VirtualAssistant.generate_html_response(query, answer)
    IO.puts("\nHTML response saved to: #{html_path}")
  end
end
