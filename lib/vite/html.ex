defmodule Vite.HTML do
  @moduledoc """
  HTML components for vite .
  """

  use Phoenix.Component

  @doc type: :components
  attr(:src, :string, required: true, doc: "source file")
  attr(:manifest, :string, required: true, doc: "manifest file location")
  attr(:react, :boolean, default: false, doc: "include react refresh snippet")

  attr(:dev_server_addr, :string,
    default: "http://localhost:5173",
    doc: "vite dev server address"
  )

  def vite_head(assigns) do
    if Application.get_env(:vite, :env) == :dev do
      ~H"""
      <%= if @react do %>
        <script type="module">
          import RefreshRuntime from '<%= Path.join(@dev_server_addr, "@react-refresh") %>'
          RefreshRuntime.injectIntoGlobalHook(window)
          window.$RefreshReg$ = () => {}
          window.$RefreshSig$ = () => (type) => type
          window.__vite_plugin_react_preamble_installed__ = true
        </script>
      <% end %>
      <script type="module" src={Path.join(@dev_server_addr, "@vite/client")}>
      </script>
      <script
        defer
        type="module"
        phx-track-static
        type="text/javascript"
        src={Path.join(@dev_server_addr, @src)}
      >
      </script>
      """
    else
      manifest = read_manifest(assigns.manifest)

      assigns =
        assign(assigns,
          mainjs: get_in(manifest, [assigns.src, "file"]),
          css: get_in(manifest, [assigns.src, "css"])
        )

      ~H"""
      <script defer type="module" phx-track-static type="text/javascript" src={"/#{@mainjs}"}>
      </script>
      <%= for css <- @css do %>
        <link phx-track-static rel="stylesheet" href={"/#{css}"} />
      <% end %>
      """
    end
  end

  defmodule ManifestNotFoundError do
    defexception [:manifest_file]

    @impl true
    def message(e) do
      """
      Could not find static manifest at #{inspect(e.manifest_file)}.
        Run "mix phx.digest" after building your static files
        or remove the configuration from "config/prod.exs".
      """
    end
  end

  defp read_manifest(path) do
    case Vite.Cache.get(:manifest) do
      nil ->
        if File.exists?(path) do
          manifest = File.read!(path) |> Jason.decode!()

          Vite.Cache.put(:manifest, manifest)
        else
          raise ManifestNotFoundError, manifest_file: path
        end

      manifest ->
        manifest
    end
  end
end
