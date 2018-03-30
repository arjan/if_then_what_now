defmodule IfThenWeb.AudioChannel do
  use IfThenWeb, :channel

  def join("audio", payload, socket) do
    Phoenix.PubSub.subscribe(IfThen.PubSub, "audio")
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("start", %{"id" => id}, socket) do
    IfThen.Renderer.start_link(id)
    {:reply, :ok, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: event, payload: payload}, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
