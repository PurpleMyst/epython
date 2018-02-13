defmodule EPython.CodeObjectTest do
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
    rv = EPython.CodeObject.from_file("unknown")
    assert rv == {:error, :enoent}
  end

  test "returns a code object on known file" do
    rv = EPython.CodeObject.from_file("test/data/__pycache__/codeobject_test.cpython-36.pyc")
    assert elem(rv, 0) == :ok
  end
end
