import gleeunit

import gleam/option.{None}

import glap/arguments.{Command, Flag, UnnamedArgument}
import glap/parser.{Parser, parse}

pub fn showhelp_test() {
  let parser = [
    // Flag(short, long, description, required, holds_value)
    Flag("-n", "--name", "name of author", True, True),
    Flag("-o", "--output", "redirects output to file", False, True),

    // Command(name, description, required, subcommands)
    Command("add", "adds a task/project", True, [
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

    Command("remove", "removes a task/project", True, [
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
  // ] |> Parser("simple todo list CLI app", _, ParserSettings(True))
  ] |> Parser("simple todo list CLI app", _, None, None)

	let args = ["-n=me", "add", "task", "name_here", "description_here"]

	parser.show_help(parser)

  case parse(parser, args) {
		Ok(_cliargs) -> Nil
		Error(_) -> Nil
	}
}
