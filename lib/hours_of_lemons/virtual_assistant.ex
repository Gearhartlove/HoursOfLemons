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

    # Append to the list of messages to maintain conversation state
    messages = Map.fetch!(state, :messages)
    messages = [body | messages]

    new_state = %{state | messages: messages}

    {:reply, body, new_state}
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
  defp build_system_prompt(%{dataset_path: dataset_path}) do
    dataset_content = File.read!(dataset_path)

    """
    You are the 24 Hours of Lemons Virtual Inspector, an AI assistant that helps racers prepare their vehicles for
    technical inspection.

    Your role is to answer questions about vehicle preparation and safety requirements based on the official "How to Not
    Fail Lemons Tech Inspection" guide.

    When answering questions:
    - Provide clear, practical guidance based on the tech inspection rules
    - Reference specific requirements and safety standards when applicable
    - Include relevant images from the inspection guide to illustrate your points
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
    cages, harnesses, fire suppression, etc.), be thorough and err on the side of caution.
    """
  end
end
