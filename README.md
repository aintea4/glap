# glap

[![Package Version](https://img.shields.io/hexpm/v/glap)](https://hex.pm/packages/glap)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glap/)

```sh
gleam add glap
```

```gleam
import gleam/io
import gleam/option.{Some}

import glap/arguments.{Command, Flag, UnnamedArgument}
import glap/parser.{Parser, parse}
import glap/cliargs.{then_get_subargument, get_content_opt, get_content_opt_or, get_cliarg}


pub fn main() {
  let parser = [
    // Flag(short, long, description, required, holds_value)
    Flag("-n", "--name", "name of author", True, True),
    Flag("-o", "--output", "redirects output to file", False, True),

    // Command(name, description, required, subcommands)
    Command("add", "", True, [
      Flag("-k", "--hidden", "adds as hidden", False, False),
      Command("task", "adds task", True, [

        // UnnamedArgument(name, description)
        UnnamedArgument("name", "name of the task to add"),
        UnnamedArgument("description", "description of the task to add")
      ]),

      Command("project", "adds project", True, [

        UnnamedArgument("name", "name of the project to add"),
        UnnamedArgument("description", "description of the project to add")
      ]),
    ]),

    Command("remove", "", True, [
      Flag("-q", "--quiet", "does not log the deletion", False, False),

      Command("project", "removes a project", True, [
        UnnamedArgument("name", "name of the project to remove")
      ]),

      Command("task", "removes a task", True, [
        UnnamedArgument("name", "name of the task to remove")
      ])
    ]),

    Command("list", "lists tasks", True, [
      Command("all", "lists all tasks, even the hidden ones", False, [])
    ])
  ] |> Parser("simple todo list CLI app", _)

  let assert Ok(cliargs) = parse(parser, args)
  // let assert Ok(cliargs) = parse(parser, ["your", "cli", arguments", "here"])


  // NOTE: let's assume `./glap --name=me add task name_here description_here` was given

  let assert Some(author) = get_cliarg(cliargs, "-n") |> get_content_opt
  let output = get_cliarg(cliargs, "--output") |> get_content_opt_or("/path/to/default")

  // let assert Some(add_cliarg) = get_cliarg(cliargs, "add")
  // let assert Some(task_cliarg) = get_subargument(add_cliarg, "task")

  let assert Some(task_name) = get_cliarg(cliargs, "add")
  |> then_get_subargument("task")
  |> then_get_subargument("name")
	|> get_content_opt

  let assert Some(task_description) = get_cliarg(cliargs, "add")
  |> then_get_subargument("task")
  |> then_get_subargument("description")
	|> get_content_opt

  io.print("Author: ")
  io.println(author)
  
  io.print("Output: ")
  io.println(output)
  
  io.print("Task name: ")
  io.println(task_name)
  
  io.print("Task description: ")
  io.println(task_description)
}

```

Further documentation can be found at <https://hexdocs.pm/glap>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
