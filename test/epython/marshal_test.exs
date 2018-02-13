defmodule EPython.MarshalTest do
  use ExUnit.Case, async: true

  test "can unmarshal None" do
    data = <<?N>>
    assert EPython.Marshal.unmarshal(data) == [:none]
  end

  test "can unmarshal False" do
    data = <<?F>>
    assert EPython.Marshal.unmarshal(data) == [:false]
  end

  test "can unmarshal True" do
    data = <<?T>>
    assert EPython.Marshal.unmarshal(data) == [:true]
  end

  test "can unmarshal StopIteration" do
    data = <<?S>>
    assert EPython.Marshal.unmarshal(data) == [:stopiteration]
  end

  test "can unmarshal Ellipsis" do
    data = <<?.>>
    assert EPython.Marshal.unmarshal(data) == [:ellipsis]
  end

  test "can unmarshal positive ints" do
    data = <<?i, 1, 0, 0, 0>>
    assert EPython.Marshal.unmarshal(data) == [{:integer, 1}]
  end

  test "can unmarshal negative ints" do
    data = <<?i, 255, 255, 255, 255>>
    assert EPython.Marshal.unmarshal(data) == [{:integer, -1}]
  end

  test "can unmarshal floats" do
    data = <<?g, 119, 190, 159, 26, 47, 221, 94, 64>>
    assert EPython.Marshal.unmarshal(data) == [{:float, 123.456}]
  end

  test "can unmarshal complex numbers" do
    data = <<?y, 0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 8, 64>>
    assert EPython.Marshal.unmarshal(data) == [{:complex, {1, 3}}]
  end

  test "can unmarshal small tuples" do
    data = <<?), 3, 233, 1, 0, 0, 0, 231, 102, 102, 102, 102, 102, 102, 2, 64, 121, 0, 0, 0, 0, 0, 0, 8, 64, 0, 0, 0, 0, 0, 0, 16, 64>>
    assert EPython.Marshal.unmarshal(data) == [{:tuple, [{:integer, 1}, {:float, 2.3}, {:complex, {3.0, 4.0}}]}]
  end

  test "can unmarshal large tuples" do
    data = File.read! "test/data/large_tuple.marshal"
    result = EPython.Marshal.unmarshal(data)

    assert [{:tuple, _}] = result
    [{:tuple, contents}] = result

    Enum.reduce(contents, fn {:integer, current}, {:integer, last} ->
      assert last + 1 == current
      {:integer, current}
    end)
  end
end
