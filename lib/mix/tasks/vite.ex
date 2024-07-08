defmodule Mix.Tasks.Vite do
  @moduledoc """
  Invokes vite with the given args.

  Usage:

      $ mix vite VITE_OPTIONS PROFILE VITE_ARGS

  Example:

      $ mix vite default --config=vite.config.js 

  If vite is not installed, it is automatically installed.
  Note the arguments given to this task will be appended
  to any configured arguments.

  ## Options

  Note flags to control this Mix task must be given before the
  profile:

      $ mix vite --some-config default
  """

  @shortdoc "Invokes vite with the profile and args"
  @compile {:no_warn_undefined, Mix}

  use Mix.Task

  @impl true
  def run(args) do
    switches = []
    {_opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if function_exported?(Mix, :ensure_application!, 1) do
      Mix.ensure_application!(:inets)
      Mix.ensure_application!(:ssl)
    end

    Mix.Task.run("loadpaths")
    Application.ensure_all_started(:vite)

    Mix.Task.reenable("vite")
    install_and_run(remaining_args)
  end

  defp install_and_run([profile | args] = all) do
    case Vite.install_and_run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix vite #{Enum.join(all, " ")}` exited with #{status}")
    end
  end

  defp install_and_run([]) do
    Mix.raise("`mix vite` expects the profile as argument")
  end
end
