defmodule PlugSessionMnesia.IntegrationTest do
  use PlugSessionMnesia.TestCase
  use Plug.Test

  @opts [
    key: "_test_key",
    store: PlugSessionMnesia.Store,
    table: :session_test
  ]

  setup [:reset_mnesia_table]

  test "session creation works" do
    conn =
      build_conn()
      |> init_and_fetch_session()
      |> endpoint()

    assert conn.assigns[:session] == %{}
  end

  test "it is possible to fetch an existing session" do
    session_fixture()

    conn =
      build_conn()
      |> put_resp_cookie("_test_key", @sid)
      |> init_and_fetch_session()
      |> endpoint()

    assert conn.assigns[:session] == @data
  end

  test "it is possible to update a session" do
    session_fixture()

    conn =
      build_conn()
      |> put_resp_cookie("_test_key", @sid)
      |> init_and_fetch_session()
      |> put_session(:test, 123)
      |> endpoint()

    assert %{"test" => 123} = conn.assigns[:session]
    assert [{_, _, %{"test" => 123}, _}] = lookup_session()
  end

  test "it is possible do delete a session" do
    session_fixture()

    build_conn()
    |> put_resp_cookie("_test_key", @sid)
    |> init_and_fetch_session()
    |> configure_session(drop: true)
    |> endpoint()

    assert lookup_session() == []
  end

  ## Helpers

  defp build_conn do
    conn(:get, "/")
  end

  defp init_and_fetch_session(conn) do
    conn
    |> Plug.Session.call(Plug.Session.init(@opts))
    |> fetch_session()
  end

  defp endpoint(conn) do
    conn
    |> assign(:session, conn.private.plug_session)
    |> resp(200, "OK")
    |> send_resp()
  end
end
