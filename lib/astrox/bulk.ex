defmodule Astrox.Bulk do
  @moduledoc """
  HTTP communication with Salesforce's Bulk API
  """

  use HTTPoison.Base

  @user_agent [{"User-agent", "astrox"}]
  @accept [{"Accept", "application/json"}]
  @accept_encoding [{"Accept-Encoding", "gzip"}]
  @content_type [{"Content-Type", "application/json"}]
  #  @pk_chunking [{"Sforce-Enable-PKChunking", "chunkSize=50000"}]

  @type id :: binary
  @type job :: map
  @type batch :: map
  @type url_path :: binary
  @type client :: Astrox.Client.t()

  @impl HTTPoison.Base
  def process_request_headers(headers),
    do: headers ++ @user_agent ++ @accept ++ @accept_encoding ++ @content_type

  @impl HTTPoison.Base
  def process_headers(headers), do: Map.new(headers)

  @impl HTTPoison.Base
  def process_response(response) do
    response
    |> maybe_gunzip()
    |> maybe_json_decode()
    |> unpack_body()
  end

  @doc """
  Make a request with a JSON-encoded body
  """
  @spec json_request(HTTPoison.Request.method(), url(), map | list, headers(), options()) ::
          response()
  def json_request(method, url, body, headers, options) do
    raw_request(method, url, JSX.encode!(body), headers, options)
  end

  @doc """
  Make a raw request
  """
  @spec raw_request(HTTPoison.Request.method(), url(), binary(), headers(), options()) ::
          response()
  def raw_request(method, url, body, headers, options) do
    start = System.monotonic_time()

    resp = request!(method, url, body, headers, extra_options() ++ options) |> process_response

    duration = System.monotonic_time() - start
    metadata = %{method: method, url: url, options: options}
    :telemetry.execute([:astrox, :bulk, :request], %{duration: duration}, metadata)

    resp
  end

  @spec authed_get(url_path, client, headers, options) :: response
  def authed_get(path, client, headers \\ [], options \\ []),
    do:
      raw_request(
        :get,
        async_url(path, client),
        "",
        headers ++ authorization_header(client),
        options
      )

  @spec authed_post(url_path, body, client, headers, options) :: HTTPoison.Response.t()
  def authed_post(path, body, client, headers \\ [], options \\ []),
    do:
      json_request(
        :post,
        async_url(path, client),
        body,
        headers ++ authorization_header(client),
        options
      )

  @doc """
  Create a query job
  """

  @spec create_query_job(binary, client) :: job
  def create_query_job(sobject, client) do
    payload = %{
      "operation" => "query",
      "object" => sobject,
      "concurrencyMode" => "Parallel",
      "contentType" => "JSON"
    }

    authed_post("/job", payload, client)
  end

  @doc """
  Cancel a job
  """

  @spec close_job(job | id, client) :: job
  def close_job(job, client) when is_map(job) do
    close_job(job.id, client)
  end

  def close_job(id, client) when is_binary(id) do
    authed_post("/job/#{id}", %{"state" => "Closed"}, client)
  end

  @doc """
  Fetch the status of a job
  """

  @spec fetch_job_status(job | id, client) :: job
  def fetch_job_status(job, client) when is_map(job), do: fetch_job_status(job.id, client)

  def fetch_job_status(id, client) when is_binary(id) do
    authed_get("/job/#{id}", client)
  end

  @doc """
  Create a batch of queries
  """

  @spec create_query_batch(String.t(), job | id, client) :: job
  def create_query_batch(soql, job, client) when is_map(job),
    do: create_query_batch(soql, job.id, client)

  def create_query_batch(soql, job_id, client) when is_binary(soql) and is_binary(job_id) do
    url = "https://#{client.host}/services/async/#{client.api_version}" <> "/job/#{job_id}/batch"
    raw_request(:post, url, soql, authorization_header(client), [])
  end

  @doc """
  Fetch the statis of a batch job
  """

  @spec fetch_batch_status(batch, client) :: batch
  def fetch_batch_status(batch, client) when is_map(batch) do
    fetch_batch_status(batch.id, batch.jobId, client)
  end

  @spec fetch_batch_status(id, job | id, client) :: batch
  def fetch_batch_status(id, job, client) when is_binary(id) and is_map(job) do
    fetch_batch_status(id, job.id, client)
  end

  def fetch_batch_status(id, job_id, client) when is_binary(id) and is_binary(job_id) do
    authed_get("/job/#{job_id}/batch/#{id}", client)
  end

  @doc """
  Fetch the result statuses of a batch job
  """
  @spec fetch_batch_result_status(batch, client) :: response()
  def fetch_batch_result_status(%{id: batch_id, jobId: job_id}, client)
      when is_binary(batch_id) and is_binary(job_id) do
    authed_get("/job/#{job_id}/batch/#{batch_id}/result", client)
  end

  @doc """
  Fetch the results of a batch job
  """
  @spec fetch_results(id, batch, client) :: response()
  def fetch_results(id, %{id: batch_id, jobId: job_id}, client)
      when is_binary(id) and is_binary(batch_id) and is_binary(job_id) do
    authed_get("/job/#{job_id}/batch/#{batch_id}/result/#{id}", client)
  end

  #####################
  # private functions #
  #####################

  defp maybe_gunzip(
         %HTTPoison.Response{body: body, headers: %{"Content-Encoding" => "gzip"} = headers} =
           resp
       ) do
    %{resp | body: :zlib.gunzip(body), headers: Map.drop(headers, ["Content-Encoding"])}
  end

  defp maybe_gunzip(resp), do: resp

  defp maybe_json_decode(
         %HTTPoison.Response{
           body: body,
           headers: %{"Content-Type" => "application/json" <> _} = headers
         } = resp
       ) do
    %{
      resp
      | body: Poison.decode!(body, keys: :atoms),
        headers: Map.drop(headers, ["Content-Type"])
    }
  end

  defp maybe_json_decode(resp), do: resp

  defp unpack_body(%HTTPoison.Response{body: body, status_code: status})
       when status < 300 and status >= 200,
       do: body

  defp unpack_body(%HTTPoison.Response{body: body, status_code: status}), do: {status, body}

  defp extra_options(), do: Application.get_env(:astrox, :request_options, [])

  defp authorization_header(%{session_id: nil}), do: []

  defp authorization_header(%{session_id: session}), do: [{"X-SFDC-Session", session}]

  defp async_url(path, client),
    do: "https://#{client.host}/services/async/#{client.api_version}" <> path
end
