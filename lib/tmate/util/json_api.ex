defmodule Tmate.Util.JsonApi do
  defmacro __using__(opts) do
    quote do
      use HTTPoison.Base
      alias HTTPoison.Request
      alias HTTPoison.Response
      alias HTTPoison.Error
      require Logger

      @opts unquote(opts[:fn_opts])

      defp opts() do
        if is_function(@opts), do: @opts.(), else: @opts
      end

      def process_url(url) do
        base_url = opts()[:base_url]
        if base_url, do: base_url <> url, else: url
      end

      def process_request_headers(headers) do
        auth_token = opts()[:auth_token]
        auth_headers = if auth_token, do: [{"Authorization", "Bearer " <> auth_token}], else: []
        json_headers =  [{"Content-Type", "application/json"}, {"Accept", "application/json"}]
        headers ++ auth_headers ++ json_headers
      end

      def process_request_body(""), do: ""
      def process_request_body(body) do
        Jason.encode!(body)
      end

      def process_response(%Response{headers: headers, body: body} = response) do
        content_type_hdr = Enum.find(headers, fn {name, _} -> name == "content-type" end)
        body = case content_type_hdr do
          {_, "application/json" <> _} -> Jason.decode!(body)
          _ -> body
        end

        %{response | body: body}
      end

      defp simplify_response({:ok, %Response{status_code: 200, body: body}} = response, _) do
        {:ok, body}
      end

      defp simplify_response({:ok, %Response{status_code: status_code}} = response,
                              %Request{url: url, method: method}) do
        Logger.error("API error: #{method} #{url} [#{status_code}]")
        {:error, status_code}
      end

      defp simplify_response({:error, %Error{reason: reason}} = response,
                              %Request{url: url, method: method}) do
        Logger.error("API error: #{method} #{url} [#{reason}]")
        {:error, reason}
      end

      def request(request) do
        super(request)
        |> simplify_response(request)
      end

      def request!(method, url, body \\ "", headers \\ [], options \\ []) do
        case request(method, url, body, headers, options) do
          {:ok, body} -> body
          {:error, reason} -> raise Error, reason: reason
        end
      end
    end
  end
end
