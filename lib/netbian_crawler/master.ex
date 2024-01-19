defmodule NetbianCrawler.Master do
  require Logger

  def start(starter_page) do
    Logger.info("创建图片目录...")
    File.mkdir_p!(Application.get_env(:netbian_crawler, :save_folder))

    loop(starter_page)
  end

  defp loop(page_link) do
    case Finch.build(:get, page_link) |> Finch.request(Crawler) do
      {:ok, res} ->
        {:ok, document} = Floki.parse_document(res.body)

        tupian_list = Floki.find(document, "div.slist ul li a") |> Floki.attribute("href")

        Enum.map(tupian_list, &async_get_page(&1))
        |> Enum.each(&await_task(&1))

        res = Floki.find(document, "div.page a:nth-last-child(1)") |> Floki.attribute("href")
        case res do
          [next_page | _] ->
            next_page_link = get_link(next_page)
            Logger.info("下一页 #{inspect(next_page_link)}")
            Process.sleep(2000)
            loop(next_page_link)

          _ -> Logger.info("没有下一页了")
        end

      {:error, e} ->
        Logger.info("fail to get response from #{page_link}: #{inspect(e)}")
    end
  end

  @timeout 10000
  defp async_get_page(relative_pic_page_link) do
    pic_page_link = get_link(relative_pic_page_link)
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        &NetbianCrawler.Worker.download_pic(&1, pic_page_link),
        @timeout
      )
    end)
  end

  defp get_link(relative) do
    Application.get_env(:netbian_crawler, :root_page) <> relative
  end

  defp await_task(task), do: task |> Task.await(@timeout)

end
