import gleam/int
import gleam/bool
import gleam/string
import gleam/list
import glap/utils.{strformat}
import glap/arguments.{type Argument, Flag, Command, UnnamedArgument}

const default_print_to_stderr = False
const default_tabstring = "  "
const default_recursive_showhelp = True
const default_recursive_max_depth = 1

// NOTE: ... <tabstring_after> <description>

@internal
pub const required_flag_format = "({}|{}){}{}"

@internal
pub const not_required_flag_format = "[{}|{}]{}{}"

@internal
pub const required_holds_value_format = "({}|{}) [VALUE...]{}{}"

@internal
pub const not_required_holds_value_format = "[{}|{}] [VALUE...]{}{}"

@internal
pub const required_command_format = "{}{}{}"

@internal
pub const not_required_command_format = "{}{}{}"

@internal
pub const unnamed_argument_format = "[{}...]{}{}"

pub type HelpSettings {
	HelpSettings(
		print_to_stderr: Bool,
		tabstring: String,
		recursive_showhelp: Bool,
		recursive_max_depth: Int
	)
}

pub fn default_help_settings() -> HelpSettings {
	HelpSettings(
		default_print_to_stderr,
		default_tabstring,
		default_recursive_showhelp,
		default_recursive_max_depth
	)
}


@internal
pub fn format_argument_without_desc(argument: Argument) -> String {
	case argument {
		Flag(short, long, _, False, False) -> strformat(not_required_flag_format, [short, long, "", ""])
		Flag(short, long, _, False, True) -> strformat(not_required_holds_value_format, [short, long, "", ""])
		Flag(short, long, _, True, False) -> strformat(required_flag_format, [short, long, "", ""])
		Flag(short, long, _, True, True) -> strformat(required_holds_value_format, [short, long, "", ""])
		Command(name, _, True, _) -> strformat(required_command_format, [name, "", ""])
		Command(name, _, False, _) -> strformat(not_required_command_format, [name, "", ""])
		UnnamedArgument(name, _) -> strformat(unnamed_argument_format, [name, "", ""])
	}
}

@internal
pub fn get_tabdesc_string_length(args: List(Argument)) -> Int {
	use <- bool.guard(when: args == [], return: 0)

	let assert Ok(result) = args
	|> list.map(fn(argument) -> Int {
		case argument {
			Command(_, _, _, subcommands) -> {
				int.max(
					format_argument_without_desc(argument) |> string.length,
					get_tabdesc_string_length(subcommands)
				)
			}
			Flag(_, _, _, _, _) -> format_argument_without_desc(argument) |> string.length
			UnnamedArgument(_, _) -> format_argument_without_desc(argument) |> string.length
		}
	})
	|> list.max(int.compare)

	result
}
