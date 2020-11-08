defmodule Sneakers23Web.ShoppingCartChannel do
  use Phoenix.Channel
  alias Sneakers23.Checkout
  import Sneakers23Web.CartView, only: [cart_to_map: 1]

  def join("cart:" <> id, params, socket) when byte_size(id) == 64 do
    cart = get_cart(params)
    socket = assign(socket, :cart, cart)
    send(self(), :send_cart)

    {:ok, socket}
  end

  def handle_in("add_item", %{"item_id" => id}, socket = %{assigns: %{cart: cart}}) do
    case Checkout.add_item_to_cart(cart, String.to_integer(id)) do
      {:ok, new_cart} ->
        socket = assign(socket, :cart, new_cart)
        {:reply, {:ok, cart_to_map(new_cart)}, socket}
      {:error, :duplicate_item} ->
        {:reply, {:error, %{error: "duplucate_item"}}, socket}
    end
  end

  def handle_info(:send_cart, socket = %{assigns: %{cart: cart}}) do
    push(socket, "cart", cart_to_map(cart))
    {:noreply, socket}
  end

  defp get_cart(params) do
    params
    |> Map.get("serialized", nil)
    |> Checkout.restore_cart()
  end
end
