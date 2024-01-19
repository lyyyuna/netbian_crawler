defmodule NetbianCrawler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    starter_page = Application.get_env(:netbian_crawler, :starter)

    children = [
      {Finch, name: Crawler},
      :poolboy.child_spec(:worker, poolboy_config()),
      Supervisor.child_spec({Task, fn -> NetbianCrawler.Master.start(starter_page) end}, restart: :temporary)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NetbianCrawler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: NetbianCrawler.Worker,
      size: 3,
      max_overflow: 1
    ]
  end
end
