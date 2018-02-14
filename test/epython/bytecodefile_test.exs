defmodule EPython.BytecodeFileTest do
  use ExUnit.Case

  test "returns {:error, :enoent} on unknown file" do
    rv = EPython.BytecodeFile.from_file("unknown")
    assert rv == {:error, :enoent}
  end

  test "returns a code object on known file" do
    rv = EPython.BytecodeFile.from_file("test/data/__pycache__/codeobject_test.cpython-36.pyc")
    assert elem(rv, 0) == :ok
  end

  test "magic number is correct" do
    {:ok, bf} = EPython.BytecodeFile.from_file("test/data/__pycache__/codeobject_test.cpython-36.pyc")
    assert binary_part(bf.magic, 0, 4) == "\x33\x0d\r\n"
  end

  test "all the parts of the code object are correct" do
    {:ok, bf} = EPython.BytecodeFile.from_file("test/data/__pycache__/codeobject_test.cpython-36.pyc")
    co = bf.code_obj

    assert co[:argcount]       == 0
    assert co[:cellvars]       == {}
    assert co[:code]           == "d\x00Z\x00d\x01Z\x01d\x02Z\x02e\x03e\x00e\x01\x14\x00e\x02\x17\x00\x83\x01\x01\x00d\x03S\x00"
    assert co[:consts]         == {3, 7, 9, :none}
    assert co[:filename]       == "test/data/codeobject_test.py"
    assert co[:firstlineno]    == 3
    assert co[:flags]          == 64
    assert co[:freevars]       == {}
    assert co[:kwonlyargcount] == 0
    assert co[:lnotab]         == "\x04\x01\x04\x01\x04\x02"
    assert co[:name]           == "<module>"
    assert co[:names]          == {"a", "b", "c", "print"}
    assert co[:nlocals]        == 0
    assert co[:stacksize]      == 3
    assert co[:varnames]       == {}
  end
end
