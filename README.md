# glap

[![Package Version](https://img.shields.io/hexpm/v/glap)](https://hex.pm/packages/glap)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glap/)

```sh
gleam add glap
```

```gleam
import glap/parser.{Parser, parse_argv}
import glap/arguments.{Command, Flag, UnnamedArgument}
import glap/cliargs.{get_command, get_subargument}
import glap/parser_settings.{default_parser_settings}

pub fn main() {
  let parser = [
    // NOTE: Flag(short, long, description, required, holds_value)
    Flag("-h", "--help", "shows help message", False, False),

    // NOTE: Command(name, description, required, subcommands)
    Command("add", "", True, [
      Flag("-k", "--alias", "second name you can reference the task with", False, True),

      // NOTE: UnnamedArgument(name, description)
      UnnamedArgument("name", "name of the task to add"),
      UnnamedArgument("description", "description of the task to add")
    ]),

    Command("remove", "", True, [
      UnnamedArgument("name", "name of the task to remove")
    ]),

    Command("list", "lists tasks", True, [
      Command("all", "lists all tasks, even the hidden ones", False, [])
    ])
  ] |> Parser(
		"simple todo list CLI app",
		Some(parser_settings.default_parser_settings()),
		Some(help_settings.default_help_settings())
	)


  case parse_argv(parser) {
    Ok(cliargs) -> {
      use <- bool.lazy_guard(when: cliargs.get_cliarg(cliargs, "--help") |> result.is_ok, return: show_help)

      // NOTE: this is ok because `default_parser_settings` forces all required arguments to be parsed
      // otherwise `parse_argv(parser)` would have returned an `Error`
      let assert Ok(command) = get_command(cliargs)

      case command {
        cliargs.Command("add", _, _) -> {
          let alias_name = get_subargument(command, "-k")
          |> get_content_opt_or("<default alias here>")

          add_task(command, alias_name)
        }
        cliargs.Command("remove", _, _) -> remove_task(command)
        cliargs.Command("list", _, _) -> list_tasks(command)
        _ -> panic
       }
    }

    Error(e) -> io.println_error(e.error)
  }
```

Further documentation can be found at <https://hexdocs.pm/glap>.

## Development

```sh
gleam test  # Run the tests
```
