defmodule EPython.MarshalTest do
  use ExUnit.Case, async: true

  test "can unmarshal None" do
    assert EPython.Marshal.unmarshal(<<?N>>) == :none
  end

  test "can unmarshal False" do
    assert EPython.Marshal.unmarshal(<<?F>>) == :false
  end

  test "can unmarshal True" do
    assert EPython.Marshal.unmarshal(<<?T>>) == :true
  end

  test "can unmarshal StopIteration" do
    assert EPython.Marshal.unmarshal(<<?S>>) == :stopiteration
  end

  test "can unmarshal Ellipsis" do
    assert EPython.Marshal.unmarshal(<<?.>>) == :ellipsis
  end

  test "can unmarshal ints" do
    assert EPython.Marshal.unmarshal(<<?i, 1, 0, 0, 0>>) == {:integer, 1}
  end

  test "can unmarshal floats" do
    assert EPython.Marshal.unmarshal(<<?g, 119, 190, 159, 26, 47, 221, 94, 64>>) == {:float, 123.456}
  end
end
