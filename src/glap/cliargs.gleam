import gleam/result
import gleam/bool
import gleam/string
import gleam/list
import gleam/option.{type Option, Some, None}

import glap/utils.{strformat}

const indent_string = "  "

pub type CLIArgs = List(CLIArg)

pub type CLIArg {
	UnnamedArgument(name: String, content: String)
	Flag(short: String, long: String, content: Option(String))
	Command(name: String, registered: Bool, subarguments: CLIArgs)
}

fn stringoption_to_string(o: Option(String)) -> String {
	case o {
		Some(s) -> strformat("Some(\"{}\")", [s])
		None -> "None"
	}
}

fn cliarg_to_string_aux(cliarg: CLIArg, indent_level: Int) -> String {
	case cliarg {
		UnnamedArgument(name, content) -> strformat("UnnamedArgument(\"{}\", \"{}\")", [name, content])
		Flag(short, long, content) -> strformat("Flag(\"{}\", \"{}\", {})", [short, long, stringoption_to_string(content)])
		Command(name, registered, subarguments) -> strformat("Command(\"{}\", {}){}", [name, bool.to_string(registered), cliargs_to_string_aux(subarguments, indent_level+1)])
	}
}

pub fn cliarg_to_string(cliarg: CLIArg) -> String {
	cliarg_to_string_aux(cliarg, 0)
}


fn cliargs_to_string_aux(cliargs: CLIArgs, indent_level: Int) -> String {
	cliargs
	|> list.map(fn(cliarg) { cliarg_to_string_aux(cliarg, indent_level+1) })
	|> list.map(fn(s) { "\n" <> string.repeat(indent_string, indent_level) <> s })
	|> string.join("")
}


pub fn cliargs_to_string(cliargs: CLIArgs) -> String {
	cliargs_to_string_aux(cliargs, 0)
}


pub fn get_cliarg(cliargs: CLIArgs, cliarg_name: String) -> Result(CLIArg, Nil) {
	use <- bool.guard(when: cliargs == [], return: Error(Nil))

	let assert [cliarg, ..cliargs_rest] = cliargs

	case cliarg {
		Flag(short, long, _) if cliarg_name == short || cliarg_name == long -> Ok(cliarg)
		UnnamedArgument(name, _) if cliarg_name == name -> Ok(cliarg)
		Command(name, _, _) if cliarg_name == name -> Ok(cliarg)
		_ -> get_cliarg(cliargs_rest, cliarg_name)
	}
}

pub fn get_content(cliarg: CLIArg) -> Result(String, Nil) {
	case cliarg {
		Flag(_, _, Some(content)) -> Ok(content)
		UnnamedArgument(_, content) -> Ok(content)
		_ -> Error(Nil)
	}
}

pub fn get_content_opt(cliarg: Result(CLIArg, Nil)) -> Result(String, Nil) {
	case cliarg {
		Ok(Flag(_, _, Some(content))) -> Ok(content)
		Ok(UnnamedArgument(_, content)) -> Ok(content)
		_ -> Error(Nil)
	}
}

pub fn get_content_opt_or(cliarg: Result(CLIArg, Nil), default: String) -> String {
	case cliarg {
		Ok(UnnamedArgument(_, content)) -> content
		Ok(Flag(_, _, Some(content))) -> content
		_ -> default
	}
}

pub fn is_argument_registered(cliargs: CLIArgs, cliarg_name: String) -> Bool {
	get_cliarg(cliargs, cliarg_name)
	|> result.is_ok
}


pub fn get_subargument(command: CLIArg, subargument_name: String) -> Result(CLIArg, Nil) {
	case command {
		Command(_, _, subcommands) -> {
			list.filter(subcommands, fn (cliarg) {
				case cliarg {
					Flag(short, long, _) if subargument_name == short || subargument_name == long -> True
					Command(name, _, _) if subargument_name == name -> True
					UnnamedArgument(name, _) if subargument_name == name -> True
					_ -> False
				}
			})
			|> list.first
		}
		_ -> Error(Nil)
	}
}


pub fn then_get_subargument(cliarg_o: Result(CLIArg, Nil), subargument_name: String) -> Result(CLIArg, Nil) {
	case cliarg_o {
		Ok(cliarg) -> get_subargument(cliarg, subargument_name)
		Error(_) -> Error(Nil)
	}
}

pub fn get_command(cliargs: CLIArgs) -> Result(CLIArg, Nil) {
	use <- bool.guard(when: cliargs == [], return: Error(Nil))

	let assert [cliargs_h, ..cliargs_rest] = cliargs

	case cliargs_h {
		Command(_, _, _) -> Ok(cliargs_h)
		_ -> get_command(cliargs_rest)
	}
}
