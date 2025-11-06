defmodule HoursOfLemons.VirtualAssistant do
  alias ElixirLS.LanguageServer.Providers.Completion.Reducers.Callbacks
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  def query(pid, text) do
    GenServer.call(pid, {:query, text}, 20000)
  end

  # NOTE: The idea of this function is to support updating different pieces about the assistant like dataset or model
  def update_state(pid, key, value) when is_atom(key) do
    GenServer.call(pid, {:update_state, key, value})
  end

  # Callbacks

  @impl true
  def init(initial_state) do
    dataset_path =
      Keyword.get(
        initial_state,
        :dataset_path,
        "/home/kgf/src/projects/hours_of_lemons/data/extracted/extracted_metadata.json"
      )

    # TODO: add picture support, probably need to hook up directory. 
    # Question: is this tied to other dataset content?

    {:ok, %{dataset_path: dataset_path, messages: []}}
  end

  @impl true
  def handle_call({:query, text}, _from, state) do
    system_prompt = build_system_prompt(state)
    {:ok, body} = HoursOfLemons.Llm.query(text, system_prompt: system_prompt)

    answer =
      body
      |> Map.get("output")
      |> Enum.at(1)
      |> Map.get("content")
      |> Enum.at(0)
      |> Map.get("text")

    IO.puts(answer)

    # Generate HTML output file
    html_path = generate_html_response(text, answer)
    IO.puts("\nHTML response saved to: #{html_path}")

    # Append to the list of messages to maintain conversation state
    messages = Map.fetch!(state, :messages)
    messages = [body | messages]

    new_state = %{state | messages: messages}

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:update_state, key, value}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, _} ->
        new_state = Map.put(state, key, value)
        {:reply, {:ok, new_state}, new_state}

      :error ->
        {
          :reply,
          {
            :error,
            "Attempted to add [#{inspect(key)}] to state. Can only adjust existing keys. The existing keys are #{Map.keys(state)}."
          },
          state
        }
    end
  end

  # Private Functions

  defp generate_html_response(question, answer) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    output_dir = Path.expand("./data/responses")
    File.mkdir_p!(output_dir)

    filename = "response_#{timestamp}.html"
    filepath = Path.join(output_dir, filename)

    # Convert file:// URLs to proper img tags
    answer_with_images = Regex.replace(
      ~r/file:\/\/([^\s]+\.(jpeg|jpg|png))/i,
      answer,
      "<br><img src=\"file://\\1\" style=\"max-width: 800px; margin: 10px 0;\"><br>"
    )

    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Virtual Inspector Response - #{timestamp}</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 900px;
          margin: 40px auto;
          padding: 20px;
          line-height: 1.6;
          background: #f5f5f5;
        }
        .container {
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .question {
          background: #e3f2fd;
          padding: 15px;
          border-left: 4px solid #2196f3;
          margin-bottom: 20px;
          border-radius: 4px;
        }
        .answer {
          white-space: pre-wrap;
        }
        .timestamp {
          color: #666;
          font-size: 0.9em;
          margin-bottom: 20px;
        }
        img {
          display: block;
          max-width: 100%;
          height: auto;
          border: 1px solid #ddd;
          border-radius: 4px;
          margin: 15px 0;
        }
        h1 {
          color: #333;
          border-bottom: 2px solid #2196f3;
          padding-bottom: 10px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🏁 24 Hours of Lemons Virtual Inspector</h1>
        <div class="timestamp">Generated: #{timestamp}</div>

        <h2>Question:</h2>
        <div class="question">#{question}</div>

        <h2>Answer:</h2>
        <div class="answer">#{answer_with_images}</div>
      </div>
    </body>
    </html>
    """

    File.write!(filepath, html)
    filepath
  end

  defp build_system_prompt(%{dataset_path: dataset_path}) do
    dataset_content =
      dataset_path
      |> File.read!()
      |> JSON.decode!()

    """
    You are the 24 Hours of Lemons Virtual Inspector, an AI assistant that helps racers prepare their vehicles for
    technical inspection.

    Your role is to answer questions about vehicle preparation and safety requirements based on the official "How to Not
    Fail Lemons Tech Inspection" guide.

    When answering questions:
    - Keep answers BRIEF and to the point - racers need quick, actionable information
    - ALWAYS cite the specific page number(s) from the guide that support your answer
    - Format citations like: "(Page 5)" or "(Pages 3-4)"
    - Reference specific requirements and safety standards when applicable
    - Include relevant images from the inspection guide to illustrate your points
    - When referencing images, use the full file path with file:// protocol (e.g., "file:///home/kgf/src/projects/hours_of_lemons/data/extracted/images/page_5_img_1.jpeg")
    - Format image references as clickable links when possible
    - Use a helpful but direct tone - you want racers to pass inspection
    - If something is a hard requirement vs. recommendation, make that clear
    - When in doubt about handwritten annotations in images, explain what they're pointing out

    Context: 24 Hours of Lemons is an endurance car racing series for $500 cars. Safety is paramount, but the spirit is
    grassroots and scrappy. Your goal is to help racers understand what's required to pass tech inspection and race
    safely.

    Here is the information you have on hand:
    <information_on_hand>
    #{inspect(dataset_content)}
    </information_on_hand>

    Remember: You're helping people prepare vehicles for wheel-to-wheel racing. When it comes to safety items (roll
    cages, harnesses, fire suppulsion, etc.), be thorough and err on the side of caution. Always cite page numbers.
    """
  end
end
