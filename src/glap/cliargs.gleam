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


pub fn get_cliarg(cliargs: CLIArgs, cliarg_name: String) -> Option(CLIArg) {
	use <- bool.guard(when: cliargs == [], return: None)

	let assert [cliarg, ..cliargs_rest] = cliargs

	case cliarg {
		Flag(short, long, _) if cliarg_name == short || cliarg_name == long -> Some(cliarg)
		UnnamedArgument(name, _) if cliarg_name == name -> Some(cliarg)
		Command(name, _, _) if cliarg_name == name -> Some(cliarg)
		_ -> get_cliarg(cliargs_rest, cliarg_name)
	}
}

pub fn get_content(cliarg: CLIArg) -> Option(String) {
	case cliarg {
		Flag(_, _, content_o) -> content_o
		UnnamedArgument(_, content) -> Some(content)
		_ -> None
	}
}

pub fn get_content_opt(cliarg: Option(CLIArg)) -> Option(String) {
	case cliarg {
		Some(Flag(_, _, content_o)) -> content_o
		Some(UnnamedArgument(_, content)) -> Some(content)
		_ -> None
	}
}

pub fn get_content_opt_or(cliarg: Option(CLIArg), default: String) -> String {
	get_content_opt(cliarg)
	|> option.unwrap(default)
}

pub fn is_argument_registered(cliargs: CLIArgs, cliarg_name: String) -> Bool {
	get_cliarg(cliargs, cliarg_name)
	|> option.is_some
}


pub fn get_subargument(command: CLIArg, subargument_name: String) -> Option(CLIArg) {
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
			|> option.from_result
		}
		_ -> None
	}
}


pub fn then_get_subargument(cliarg_o: Option(CLIArg), subargument_name: String) -> Option(CLIArg) {
	case cliarg_o {
		Some(cliarg) -> get_subargument(cliarg, subargument_name)
		None -> None
	}
}
