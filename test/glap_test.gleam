import gleeunit

import gleam/option.{type Option, Some, None}

import glap/arguments.{Command, Flag, UnnamedArgument}
import glap/parser.{Parser, parse}
import glap/cliargs.{is_argument_registered, get_content, get_cliarg, get_subcommand}


pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_test() {
	let args = ["-o=/path/to/output", "add", "task", "name_of_task", "description_here"]

	let parser = [
		Flag("-v", "--version", "shows program version", False, False),
		Flag("-h", "--help", "shows help message", False, False),
		Flag("-q", "--quiet", "does not print anything to the console", False, False),
		Flag("-o", "--output", "redirects output to a file", False, True),
		Command("add", "", True, [
			Command("task", "adds task", True, [
				UnnamedArgument("name", "name of the task to add"),
				UnnamedArgument("description", "name of the task to remove")
			]),
			Command("project", "adds project", True, [
				UnnamedArgument("name", "name of the project to add"),
				UnnamedArgument("file-structure", "file structure of the project to add")
			]),
		]),
		Command("remove", "", True, [
			Flag("-n", "--no-log", "does not log the deletion", True, False),
			Command("task", "removes task", True, [
				UnnamedArgument("name", "name of the task to remove"),
			]),
			Command("project", "remove project", True, [
				UnnamedArgument("name", "name of the project to remove")
			]),
		]),
		Command("list", "lists tasks and projects", True, [
			Command("all", "lists all tasks and projects, even the hidden ones", False, [])
		])
	]
	|> Parser("simple parser", _)

	let assert Ok(cliargs) = parse(parser, args)

	assert get_content(cliargs, "-o") == Some("/path/to/output")
	assert !is_argument_registered(cliargs, "-v")
	assert !is_argument_registered(cliargs, "--quiet")

	assert is_argument_registered(cliargs, "add")
	let assert Some(add_cliarg) = get_cliarg(cliargs, "add")

	assert add_cliarg
		|> get_subcommand("task")
		|> option.is_some
}
