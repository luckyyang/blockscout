defmodule BlockScoutWeb.AddressTokenBalanceController do
  use BlockScoutWeb, :controller

  alias Explorer.{Chain, Market}

  def index(conn, %{"address_id" => address_hash_string}) do
    with true <- ajax?(conn),
         {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string) do
      token_balances =
        address_hash
        |> Chain.fetch_last_token_balances()
        |> Market.add_price()

      conn
      |> put_status(200)
      |> put_layout(false)
      |> render("_token_balances.html", token_balances: token_balances)
    else
      _ ->
        not_found(conn)
    end
  end
end
