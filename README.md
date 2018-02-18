# EPython

EPython is be a toy CPython bytecode interpreter written in Elixir.

## Compiliation

To utilize EPython, you will need the Erlang VM and `mix`. This README assumes
you're utilizing an unix-like operating system, such as Linux or OSX, due to
this being not tested on Windows at all.

You can install everything by following the instructions on [the official
Elixir website](https://elixir-lang.org/install.html).

Then, to compile, you can type this into your shell:

```bash
$ MIX_ENV=prod mix escript.build
```

This will generate an `epython` executable in the main project directory which
you can pass python files to (**actual python files**, not just bytecode files) as a command-line argument.

## Running tests

You can run a variety of tests for the interpreter itself by running `./run_tests.py`.
