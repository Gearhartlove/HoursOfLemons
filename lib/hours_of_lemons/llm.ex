defmodule HoursOfLemons.Llm do
  @url "https://api.openai.com/v1/responses"

  def query(query, opts \\ []) do
    api_key = System.get_env("OPENAI_API_KEY")
    unless api_key, do: raise("MUST HAVE AN OPENAI_API_KEY")

    model = Keyword.get(opts, :model, "gpt-5-mini")
    tools = Keyword.get(opts, :tools, [])
    system_prompt = Keyword.get(opts, :system_prompt, nil)
    previous_response_id = Keyword.get(opts, :previous_response_id, nil)

    Req.post(
      @url,
      headers: [
        {"content-type", "application/json"},
        {"authorization", "Bearer #{api_key}"}
      ],
      json: create_payload(model, query, tools, previous_response_id, system_prompt),
      receive_timeout: 20_000,
      retry: :transient,
      retry_delay: 1000,
      max_retries: 3
    )
    |> handle_response()
  end

  defp create_payload(model, query, tools, previous_response_id, system_prompt)
       when is_binary(query) do
    %{
      model: model,
      input: query,
      tools: tools,
      reasoning: %{
        effort: "minimal"
      },
      previous_response_id: previous_response_id,
      instructions: system_prompt
    }
  end

  defp create_payload(model, query, tools, previous_response_id, _system_prompt)
       when is_list(query) do
    %{
      model: model,
      input: query,
      tools: tools,
      reasoning: %{
        effort: "minimal"
      },
      previous_response_id: previous_response_id
    }
  end

  defp create_payload(_model, query, _tools, _previous_response_id, _system_prompt)
       when is_list(query) do
    throw("Query is in wrong format: #{query}")
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, "API request failed with status #{status}: #{inspect(body)}"}
  end

  defp handle_response({:error, reason}) do
    {:error, "Request failed: #{inspect(reason)}"}
  end
end
