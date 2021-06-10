defmodule Tmate.RequestLogger do
  require Logger

  @behaviour Plug
  def init(_opts), do: _opts

  def call(%{path_info: []} = conn, _opts) do
    start_time = System.monotonic_time()
    Plug.Conn.register_before_send(conn, fn(conn) ->
      # We don't want passwords etc. being logged
      params = inspect(Phoenix.Logger.filter_values(conn.params))

      # Log any important session data eg. logged-in user
      user = conn.assigns[:current_user]
      user_string = if user, do: "#{user.id} (#{user.name})", else: "(none)"

      # Note redirect, if any
      redirect = Plug.Conn.get_resp_header(conn, "location")
      redirect_string = if redirect != [], do: " redirected_to=#{redirect}", else: ""

      # Calculate time taken (in ms for consistency)
      stop_time = System.monotonic_time()
      time_us = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
      time_ms = div(time_us, 100) / 10
      Logger.log(:debug,
        "■ remote_ip=#{conn.remote_ip |> Tuple.to_list |> Enum.join(".") } method=#{conn.method} host_header=#{conn.host} path=#{conn.request_path}?#{conn.query_string} params=#{params} "<>
        "user=#{user_string} status=#{conn.status}#{redirect_string} duration=#{time_ms}ms"
      )
      conn
    end)
  end

  def call(conn, _opts) do
    start_time = System.monotonic_time()
    Plug.Conn.register_before_send(conn, fn(conn) ->
      # We don't want passwords etc. being logged
      params = inspect(Phoenix.Logger.filter_values(conn.params))

      # Log any important session data eg. logged-in user
      user = conn.assigns[:current_user]
      user_string = if user, do: "#{user.id} (#{user.name})", else: "(none)"

      # Note redirect, if any
      redirect = Plug.Conn.get_resp_header(conn, "location")
      redirect_string = if redirect != [], do: " redirected_to=#{redirect}", else: ""

      # Calculate time taken (in ms for consistency)
      stop_time = System.monotonic_time()
      time_us = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
      time_ms = div(time_us, 100) / 10
      Logger.log(:info,
        "■ remote_ip=#{conn.remote_ip |> Tuple.to_list |> Enum.join(".") } method=#{conn.method} host_header=#{conn.host} path=#{conn.request_path}?#{conn.query_string} params=#{params} "<>
        "user=#{user_string} status=#{conn.status}#{redirect_string} duration=#{time_ms}ms"
      )
      conn
    end)
  end
end

defmodule TmateWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :tmate

  socket "/socket", TmateWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :tmate,
    gzip: true,
    only: ~w(css fonts img js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Tmate.Util.PlugRemoteIp
#  plug Plug.RequestId
#  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
#  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.

  plug Tmate.RequestLogger
  plug Plug.Session,
    store: :cookie,
    key: "_tmate_key",
    signing_salt: "PlqZqmWt",
    encryption_salt: "vIeLihup"

  plug TmateWeb.Router
end
