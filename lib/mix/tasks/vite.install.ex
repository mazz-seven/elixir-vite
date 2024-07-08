defmodule Mix.Tasks.Vite.Install do
  @moduledoc """
  Installs Vite.

    $ mix vite.install 
    $ mix vite.install --using bun

  By default, it installs #{Vite.latest_version()} but you
  can configure it in your config files, such as:

      config :vite, :version, "#{Vite.latest_version()}"

  ## Options

      * `--using` - change the package management

      * `--no-config` - does not install vite config


   ## Assets

    Whenever Vite is installed, a default vite configuration
    will be placed in a new `assets/vite.config.js` file. See
    the [vite documentation](https://vitejs.dev/config)
    on configuration options.
  """

  @shortdoc "Installs vite"
  @compile {:no_warn_undefined, Mix}

  use Mix.Task

  @impl true
  def run(args) do
    valid_options = [
      config: :boolean,
      using: :string
    ]

    opts =
      case OptionParser.parse_head!(args, strict: valid_options) do
        {opts, []} ->
          opts

        {_, _} ->
          Mix.raise("""
          Invalid arguments to vite.install, expected one of:

              mix vite.install
              mix vite.install --using bun
          """)
      end

    if Keyword.get(opts, :config, true) do
      vite_config_path = Path.expand("assets/vite.config.mjs")

      config_exists? =
        Enum.any?(["mjs", "cjs", "js", "ts"], fn ext ->
          path = Path.expand("assets/vite.config.#{ext}")
          File.exists?(path)
        end)

      prepare_package_json()

      unless config_exists? do
        File.write!(vite_config_path, """
        // See the Vite configuration guide for advanced usage
        // https://vitejs.dev/config

        import { defineConfig } from "vite";

        export default defineConfig(({ command }) => {
          const isDev = command !== "build";
          if (isDev) {
            // Terminate the watcher when Phoenix quits
            process.stdin.on("close", () => {
              process.exit(0);
            });

            process.stdin.resume();
          }

          return {
            resolve: {
              preserveSymlinks: true,
            },
            plugins: [],
            publicDir: "../priv/public",
            build: {
              target: "esnext", // build for recent browsers
              outDir: "../priv/static", // emit assets to priv/static
              emptyOutDir: true,
              sourcemap: isDev, // enable source map in dev build
              manifest: true,
              rollupOptions: {
                input: "./js/app.js",
              },
            },
          };
        });
        """)
      end
    end

    if function_exported?(Mix, :ensure_application!, 1) do
      Mix.ensure_application!(:inets)
      Mix.ensure_application!(:ssl)
    end

    Mix.Task.run("loadpaths")
    Vite.install(Keyword.get(opts, :using, "npm"))
  end

  def prepare_package_json() do
    case File.read("assets/pacakge.json") do
      {:ok, pkg} ->
        File.write!(
          "assets/pacakge.json",
          Jason.decode!(pkg)
          |> Map.update("type", "module", fn val -> val end)
          |> Map.update("workspaces", %{}, fn val -> ["../deps/*" | val] end)
        )

      {:error, _} ->
        :ok
    end
  end
end
