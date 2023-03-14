defmodule OpenURL do
  def get(url) do
    read(url)
  end

  def put(url, data) do
    write(url, data)
  end

  def open(url) when is_binary(url) do
    url |> URI.new!() |> open()
  end

  def open(%URI{scheme: scheme} = url) when scheme in [nil, "file"] do
    case Path.extname(url.path) do
      ".zip" ->
        OpenURLZip.open(url)

      ".tar" ->
        OpenURLTar.open(url)

      ".tgz" ->
        %{OpenURLTar.open(url) | compressed: true}

      ".gz" ->
        if String.ends_with?(url.path, ".tar.gz") do
          %{OpenURLTar.open(url) | compressed: true}
        else
          OpenURLFile.open(url)
        end

      ".html" ->
        OpenURLHTML.open(url)

      ".md" ->
        OpenURLMarkdown.open(url)

      _ ->
        OpenURLFile.open(url)
    end
  end

  def open(%URI{scheme: "phoenix"} = url) do
    OpenURLPhoenix.open(url)
  end

  def open(%URI{scheme: scheme} = url) when scheme in ["http", "https"] do
    OpenURLHTTP.open(url)
  end

  def open(%URI{scheme: "erts"} = url) do
    OpenURLERTS.open(url)
  end

  def open(%URI{scheme: "elixir"} = url) do
    OpenURLElixir.open(url)
  end

  def open(%URI{scheme: "erlang"} = url) do
    OpenURLErlang.open(url)
  end

  def open(%URI{scheme: "zip"} = url) do
    OpenURLZip.open(url)
  end

  def open(%URI{scheme: "tar"} = url) do
    OpenURLTar.open(url)
  end

  def open(%URI{scheme: "tgz"} = url) do
    %{OpenURLTar.open(url) | compressed: true}
  end

  def open(%URI{scheme: "postgres"} = url) do
    OpenURLPostgres.open(url)
  end

  def open(%URI{scheme: "mysql"} = url) do
    OpenURLMySQL.open(url)
  end

  def read(url) when is_binary(url) do
    url |> URI.new!() |> read()
  end

  def read(%URI{} = url) do
    url |> open() |> read()
  end

  def read(%_{} = struct) do
    struct.__struct__.read(struct)
  end

  def write(url, data) when is_binary(url) do
    url |> URI.new!() |> write(data)
  end

  def write(%URI{} = url, data) do
    url |> open() |> write(data)
  end

  def write(%_{} = struct, data) do
    struct.__struct__.write(struct, data)
  end
end

defmodule OpenURLFile do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    File.read!(struct.url.path)
  end

  def write(struct, data) do
    File.write!(struct.url.path, data)
  end
end

defmodule OpenURLPhoenix do
  defstruct [:channel, :topic]

  def open(url) do
    ["", channel, topic] = String.split(url.path, "/")
    ws_url = "ws://#{url.host}:#{url.port}/socket/websocket"
    {:ok, socket} = PhoenixClient.Socket.start_link(url: ws_url)
    Process.sleep(100)
    {:ok, _response, channel} = PhoenixClient.Channel.join(socket, channel)
    %__MODULE__{channel: channel, topic: topic}
  end

  def write(struct, message) do
    PhoenixClient.Channel.push(struct.channel, struct.topic, message)
  end
end

defmodule OpenURLHTTP do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    Req.new()
    |> ReqEasyHTML.attach()
    |> OpenURL.ReqEasyRSS.attach()
    |> Req.get!(url: struct.url)
    |> Map.fetch!(:body)
  end
end

defmodule OpenURLPostgres do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def write(struct, sql) do
    options = [
      database:
        if path = struct.url.path do
          String.trim_leading(path, "/")
        else
          System.fetch_env!("USER")
        end
    ]

    {:ok, pid} = Postgrex.start_link(options)
    Postgrex.query!(pid, sql, [])
  end
end

defmodule OpenURLMySQL do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def write(struct, sql) do
    options = [
      database:
        if path = struct.url.path do
          String.trim_leading(path, "/")
        else
          System.fetch_env!("USER")
        end
    ]

    {:ok, pid} = MyXQL.start_link(options)
    MyXQL.query!(pid, sql, [])
  end
end

defmodule OpenURLERTS do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(%{url: %{path: "processes"}}) do
    Process.list()
  end

  def read(%{url: %{path: "processes/" <> pid}}) do
    pid = :erlang.list_to_pid(~c"<#{pid}>")
    Process.info(pid)
  end
end

defmodule OpenURLElixir do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) when struct.url.path == "runtime_info" do
    [
      elixir_version: System.version(),
      otp_release: System.otp_release(),
      erts_version: List.to_string(:erlang.system_info(:version)),
      schedulers: System.schedulers(),
      schedulers_online: System.schedulers_online()
    ]
  end

  def write(%{url: %{path: "eval"}}, code) do
    Code.eval_string(code)
  end
end

defmodule OpenURLErlang do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def write(%{url: %{path: "eval"}}, code) do
    {:ok, tokens, _} = :erl_scan.string(String.to_charlist(code))
    {:ok, exprs} = :erl_parse.parse_exprs(tokens)
    {:value, result, bindings} = :erl_eval.exprs(exprs, %{})
    {result, bindings}
  end
end

defmodule OpenURLZip do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    {:ok, files} = :zip.extract(String.to_charlist(struct.url.path), [:memory])

    for {path, data} <- files do
      {List.to_string(path), data}
    end
  end

  def write(struct, files) do
    {:ok, _path} =
      :zip.create(
        String.to_charlist(struct.url.path),
        for {path, data} <- files do
          {String.to_charlist(path), data}
        end
      )
  end
end

defmodule OpenURLTar do
  defstruct [:url, compressed: false]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    {:ok, files} =
      :erl_tar.extract(
        String.to_charlist(struct.url.path),
        :proplists.compact(
          memory: true,
          compressed: struct.compressed
        )
      )

    for {path, data} <- files do
      {List.to_string(path), data}
    end
  end

  def write(struct, files) do
    :ok =
      :erl_tar.create(
        String.to_charlist(struct.url.path),
        for {path, data} <- files do
          {String.to_charlist(path), data}
        end
      )
  end
end

defmodule OpenURLHTML do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    File.read!(struct.url.path)
    |> EasyHTML.parse!()
  end

  def write(struct, %EasyHTML{} = data) do
    write(struct, to_string(data))
  end

  def write(struct, data) do
    File.write!(struct.url.path, data)
  end
end

defmodule OpenURLMarkdown do
  defstruct [:url]

  def open(url) do
    %__MODULE__{url: url}
  end

  def read(struct) do
    markdown = File.read!(struct.url.path)
    {:ok, ast, []} = EarmarkParser.as_ast(markdown)
    ast
  end

  def write(struct, data) do
    File.write!(struct.url.path, data)
  end
end

defmodule OpenURL.ReqEasyRSS do
  @moduledoc false
  def attach(request) do
    Req.Request.append_response_steps(request, req_easyrss_decode: &decode/1)
  end

  defp decode({request, response}) do
    case Req.Response.get_header(response, "content-type") do
      ["application/atom+xml" <> _] ->
        response = update_in(response.body, &EasyRSS.parse!/1)
        {request, response}

      _other ->
        {request, response}
    end
  end
end
