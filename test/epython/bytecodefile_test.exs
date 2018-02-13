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
    {:ok, co} = EPython.BytecodeFile.from_file("test/data/__pycache__/codeobject_test.cpython-36.pyc")
    assert binary_part(co.magic, 2, 2) == "\r\n"
  end
end
