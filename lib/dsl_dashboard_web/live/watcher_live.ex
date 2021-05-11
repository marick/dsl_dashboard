defmodule DslDashboardWeb.WatcherLive do
  use Pile
  use DslDashboardWeb, :live_view

  def mount(params, session, socket) do
    ppp {params, session}
    ppp ExSync.Application.start(:normal, [])
    {:ok, assign(socket, state: %{a: 1})}
  end

end  
