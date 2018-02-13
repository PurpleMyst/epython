defmodule EPython.BytecodeFileTest do
  use ExUnit.Case

  setup_all do
    {output, exit_code} =
      System.cmd "python3", ["-m", "compileall", "test/data/codeobject_test.py"]

    case exit_code do
      0 -> :ok
      _ -> {output, exit_code}
    end
  end

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
    [{:code, co}] = bf.code_obj

    assert elem(co[:argcount], 1)       == 0
    assert elem(co[:cellvars], 1)       == []
    assert elem(co[:code], 1)           == "d\x00Z\x00d\x01Z\x01d\x02Z\x02e\x03e\x00e\x01\x14\x00e\x02\x17\x00\x83\x01\x01\x00d\x03S\x00"
    assert elem(co[:consts], 1)         == [{:integer, 3}, {:integer, 7}, {:integer, 9}, :none]
    assert elem(co[:filename], 1)       == "test/data/codeobject_test.py"
    assert elem(co[:firstlineno], 1)    == 3
    assert elem(co[:flags], 1)          == 64
    assert elem(co[:freevars], 1)       == []
    assert elem(co[:kwonlyargcount], 1) == 0
    assert elem(co[:lnotab], 1)         == "\x04\x01\x04\x01\x04\x02"
    assert elem(co[:name], 1)           == "<module>"
    assert elem(co[:names], 1)          == [{:string, "a"}, {:string, "b"}, {:string, "c"}, {:string, "print"}]
    assert elem(co[:nlocals], 1)        == 0
    assert elem(co[:stacksize], 1)      == 3
    assert elem(co[:varnames], 1)       == []

  end
end
