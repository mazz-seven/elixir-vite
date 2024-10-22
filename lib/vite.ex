defmodule Vite do
  # https://registry.npmjs.org/vite/latest
  @latest_version "5.3.1"
  @moduledoc """
  """

  use Application
  require Logger

  @doc false
  def start(_, _) do
    unless Application.get_env(:vite, :env) do
      Logger.error("""
      Vite env is not configured. Please set it in your config files:

      config :vite, :env, config_env()
      """)
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version, do: @latest_version

  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:vite, profile) ||
      raise ArgumentError, """
      unknown vite profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :vite,
            env: config_env(),
            version: "5.3.1",
            #{profile}: [
              args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
              cd: Path.expand("../assets", __DIR__),
              env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
            ]
      """
  end

  @spec run(binary, atom, [binary]) :: non_neg_integer
  def run(exec, profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = config[:args] || []

    if args == [] and extra_args == [] do
      raise "no arguments passed to vite"
    end

    opts = [
      cd: config[:cd] || File.cwd!(),
      env: config[:env] || %{},
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    System.cmd(exec, ["vite"] ++ args ++ extra_args, opts)
    |> elem(1)
  end

  @doc """
  Installs, if not available, and then runs `bun`.

  Returns the same as `run/2`.
  """
  def install_and_run(profile, args) do
    exec = System.find_executable("npx") || System.find_executable("bunx")

    if exec == nil do
      raise "no javascript runtime found. Please install 'node' or 'bun'."
    end

    run(exec, profile, args)
  end

  def install(using \\ "npm") do
    unless installed_version() != nil do
      exec = System.find_executable(using)

      if exec == nil do
        raise "no pacakge management #{using} found. Please install it before."
      end

      opts = [
        cd: Path.expand("./assets", File.cwd!()),
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      ]

      System.cmd(using, ["install", "vite", "-D"], opts)
      |> elem(1)
    end
  end

  def installed_version() do
    case File.read(Path.expand("assets/package.json", File.cwd!())) do
      {:ok, pkg} ->
        pkg = Jason.decode!(pkg)

        get_in(pkg, ["devDependencies", "vite"])

      {:error, _} ->
        nil
    end
  end
end
