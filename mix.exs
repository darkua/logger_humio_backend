defmodule LoggerSplunkBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_splunk_backend,
      version: "0.0.1",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.3.0"}
    ]
  end

  defp description do
    """
    A Logger backend to support the Splunk service
    (splunk.com) TCP input log mechanism
    """
  end

  defp package do
    [
      files: ["config", "lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Andreas Kasprzok"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/akasprzok/logger_splunk_backend"}
    ]
  end
end
