import gleam/bool
import glap/utils.{strformat}

pub type Argument {
	UnnamedArgument(name: String, description: String)
	Flag(short: String, long: String, description: String, required: Bool, holds_value: Bool)
	Command(name: String, description: String, required: Bool, subcommands: List(Argument))
}

pub fn argument_to_string(argument: Argument) -> String {
	case argument {
		UnnamedArgument(name, description) -> strformat("UnnamedArgument(\"{}\", \"{}\")", [name, description])
		Flag(short, long, description, required, holds_value) -> strformat("Flag(\"{}\", \"{}\", \"{}\", \"{}\", \"{}\")", [short, long, description, bool.to_string(required), bool.to_string(holds_value)])
		Command(name, description, required, _subcommands) -> strformat("Command(\"{}\", \"{}\", \"{}\", \"{}\")", [name, description, bool.to_string(required), ""])
	}
}

pub fn is_unnamed_argument(argument: Argument) -> Bool {
	case argument {
		UnnamedArgument(_, _) -> True
		_ -> False
	}
}

pub fn is_flag(argument: Argument) -> Bool {
	case argument {
		Flag(_, _, _, _, _) -> True
		_ -> False
	}
}

pub fn is_command(argument: Argument) -> Bool {
	case argument {
		Command(_, _, _, _) -> True
		_ -> False
	}
}
