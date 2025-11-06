defmodule HoursOfLemons.Llm do
  @moduledoc """
  Client for interacting with OpenAI's API.

  This module provides functions to query language models using OpenAI's API,
  with support for system prompts, tools, and conversation continuity.
  """

  @url "https://api.openai.com/v1/responses"

  @doc """
  Queries the OpenAI API with a prompt.

  ## Parameters
    - `query` - The user's question or prompt (string or list of messages)
    - `opts` - Keyword list of options:
      - `:model` - Model to use (default: "gpt-5-mini")
      - `:tools` - List of tools available to the model (default: [])
      - `:system_prompt` - System instructions for the model (default: nil)
      - `:previous_response_id` - ID to continue a conversation (default: nil)

  ## Returns
    - `{:ok, body}` - Successful response with the API body
    - `{:error, reason}` - Error with description

  ## Examples

      iex> HoursOfLemons.Llm.query("What is the safety harness requirement?",
      ...>   system_prompt: "You are a tech inspector",
      ...>   model: "gpt-5-mini"
      ...> )
      {:ok, %{"output" => [...]}}

  """
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

  # Creates the request payload for a string query with system prompt
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

  # Creates the request payload for a list of messages
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

  # Error case for invalid query format
  defp create_payload(_model, query, _tools, _previous_response_id, _system_prompt)
       when is_list(query) do
    throw("Query is in wrong format: #{query}")
  end

  # Handles successful API response
  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    {:ok, body}
  end

  # Handles non-200 API responses
  defp handle_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, "API request failed with status #{status}: #{inspect(body)}"}
  end

  # Handles network errors or request failures
  defp handle_response({:error, reason}) do
    {:error, "Request failed: #{inspect(reason)}"}
  end
end
