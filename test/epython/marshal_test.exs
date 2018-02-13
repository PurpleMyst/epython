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
end
