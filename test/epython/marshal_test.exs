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

  defp test_sequence(type_atom, type_char) do
    <<_, data :: binary>> = File.read! "test/data/large_tuple.marshal"
    data = <<type_char, data :: binary>>

    result = EPython.Marshal.unmarshal(data)

    assert [{^type_atom, _}] = result
    [{^type_atom, contents}] = result

    Enum.reduce(contents, fn {:integer, current}, {:integer, last} ->
      assert last + 1 == current
      {:integer, current}
    end)
  end

  test "can unmarshal large tuples" do
    test_sequence(:tuple, ?()
  end

  test "can unmarshal lists" do
    test_sequence(:list, ?[)
  end

  test "can unmarshal frozensets" do
    test_sequence(:frozenset, ?>)
  end

  test "can handle empty sequences" do
    assert EPython.Marshal.unmarshal("\xa9\x00") == [{:tuple, []}]
    assert EPython.Marshal.unmarshal("\xdb\x00\x00\x00\x00") == [{:list, []}]
  end

  test "can unmarshal dicts" do
    data = "\xfb\xe9\x01\x00\x00\x00\xe9\x02\x00\x00\x00\xe9\x03\x00\x00\x00\xe9\x04\x00\x00\x000"
    assert EPython.Marshal.unmarshal(data) == [{:dict, [{{:integer, 1}, {:integer, 2}}, {{:integer, 3}, {:integer, 4}}]}]
  end

  test "can unmarshal basic references" do
    data = "\xdb\x02\x00\x00\x00\xdb\x00\x00\x00\x00r\x01\x00\x00\x00"
    assert EPython.Marshal.unmarshal(data) == [{:list, [{:list, []}, {:reference, 1}]}]
  end
end
