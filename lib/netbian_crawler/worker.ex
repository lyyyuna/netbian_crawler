defmodule NetbianCrawler.Worker do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def download_pic(pid, pic_page_link) do
    GenServer.call(pid, {:download_pic, pic_page_link})
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:download_pic, pic_page_link}, _from, state) do
    case Finch.build(:get, pic_page_link) |> Finch.request(Crawler) do
      {:ok, res} ->
        {:ok, document} = Floki.parse_document(res.body)
        pic_link = Floki.find(document, "#img img") |> Floki.attribute("src")

        hd(pic_link)
          |> get_link()
          |> download_file()

      {:error, e} ->
        Logger.info("fail to get response from #{pic_page_link}: #{inspect(e)}")
    end

    {:reply, 1, state}
  end

  defp file_name(link) do
    Path.basename(link)
  end

  defp download_file(link) do
    filename = file_name(link)
    path = Path.join(Application.get_env(:netbian_crawler, :save_folder), filename)
    request = Finch.build(:get, link)

    case File.open(path, [:write, :exclusive]) do
      {:ok, file} ->
        Finch.stream(request, Crawler, nil, fn
          {:status, _}, _acc -> nil

          {:headers, _}, _acc -> nil

          {:data, data}, _ ->
            IO.binwrite(file, data)
        end)

        File.close(file)

      {:error, e} -> Logger.info("fail to write to file #{filename}: #{inspect(e)}")
    end
  end

  defp get_link(relative) do
    Application.get_env(:netbian_crawler, :root_page) <> relative
  end
end
