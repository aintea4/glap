// import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/bool
import gleam/result
import gleam/option.{type Option, None, Some}

import argv

import glap/arguments
import glap/cliargs
import glap/utils.{printformat, strformat}
import glap/error.{type ParsingError}

pub type Parser {
	Parser(description: String, arguments: List(arguments.Argument))
}

pub fn parser_print(parser: Parser) {
	let Parser(description, args) = parser

	io.println("Parser { ")
	io.print("\tdescription: ")
	io.print(description)
	io.println(", ")
	io.println("\tcommands:")
	io.print("\t\t")

	args
	|> list.map(arguments.argument_to_string)
	|> string.join("\n\t\t")
	|> io.println

	io.println(" }")
}


pub fn parse(parser: Parser, args: List(String)) -> Result(cliargs.CLIArgs, ParsingError) {
	let subcommands = list.filter(parser.arguments, arguments.is_command)
	let subflags = list.filter(parser.arguments, arguments.is_flag)
	let subunnamedarguments = list.filter(parser.arguments, arguments.is_unnamed_argument)

	parse_aux(args, subcommands, subflags, subunnamedarguments)
}


fn parse_aux(
	args: List(String),
	commands: List(arguments.Argument),
	flags: List(arguments.Argument),
	unnamed_arguments: List(arguments.Argument),
) -> Result(cliargs.CLIArgs, ParsingError) {
	let required_flags = list.filter(flags, fn(flag) {
		let assert arguments.Flag(_, _, _, required, _) = flag
		required
	})

	let required_commands = list.filter(commands, fn(command) {
		let assert arguments.Command(_, _, required, _) = command
		required
	})

	let required_commands_str = 
		list.map(required_commands, fn(command) {
			let assert arguments.Command(name, _, _, _) = command
			name
		})
		|> string.join(" | ")

	use <- bool.guard(when: args == [] && required_commands != [], return: Error(error.MissingCommand(utils.strformat("missing required command: {}", [required_commands_str]))))
	use <- bool.guard(when: args == [] && unnamed_arguments != [], return: Error(error.MissingUnnamedArgument("missing unnamed arguments")))
	use <- bool.guard(when: args == [], return: Ok([]))

	let assert [h_args, ..rest_args] = args

	let should_be_flag = string.starts_with(h_args, "-")

	// printformat("[DEBUG.parse_aux] flag={} {}, {}, {}", [
	// 	bool.to_string(should_be_flag),
	// 	list.length(commands) |> int.to_string,
	// 	list.length(flags) |> int.to_string,
	// 	list.length(unnamed_arguments) |> int.to_string
	// ])

	case commands, flags, unnamed_arguments {
		// NOTE: flag case
		_, [arguments.Flag(short, long, _, _, holds_value), ..rest_flag], _ if should_be_flag -> {
			// use <- bool.lazy_guard(when: h_args != short && h_args != long, return: fn() {
			use <- bool.lazy_guard(when: !string.starts_with(h_args, short) && !string.starts_with(h_args, long), return: fn() {
				let assert [h_flag, h2_flag, ..rest_flag] = flags

				// WARN: might be the cause of infinite loop recursion finding correct flag
				// parse_aux(args, commands, [h2_flag, ..rest_flag], unnamed_arguments)
				parse_aux(args, commands, [h2_flag, ..utils.push_back(rest_flag, h_flag)], unnamed_arguments)
			})

			let #(content, rest_args2): #(Option(String), List(String)) = case holds_value {
				True -> {
					case string.split_once(h_args, "=") {
						Ok(#(_, value)) -> {
							#(Some(string.trim(value)), rest_args)
						}
						Error(Nil) -> {
							let assert [flag_content, ..rest] = rest_args

							#(Some(flag_content), rest)
						}
					}

				}
				False -> #(None, rest_args)
			}

			let flag_cliarg = cliargs.Flag(short, long, content)
			let rest_result_r = parse_aux(rest_args2, commands, rest_flag, unnamed_arguments)

			use <- bool.guard(when: result.is_error(rest_result_r), return: rest_result_r)

			let assert Ok(rest_result) = rest_result_r

			Ok([flag_cliarg, ..rest_result])
		}

		// NOTE: something else than a flag, therefore an unnamed argument
		_, _, [arguments.UnnamedArgument(name, _description), ..rest_unnamed_argument] -> {
			let unnamed_argument_cliarg = cliargs.UnnamedArgument(name, h_args)
			let rest_result_r = parse_aux(rest_args, commands, flags, rest_unnamed_argument)

			use <- bool.guard(when: result.is_error(rest_result_r), return: rest_result_r)

			let assert Ok(rest_result) = rest_result_r
			Ok([unnamed_argument_cliarg, ..rest_result])
		}

		// NOTE: unless only commands are left in which case we take this command

		[_h_command, .._rest_command], _, _ if required_flags != [] ->
			strformat("missing required flags: ", [
				list.map(required_flags, fn(cliarg) {
					let assert arguments.Flag(short, long, _, _, _) = cliarg

					"[" <> short <> "|" <> long <> "]"
				})
				|> string.join(", ")
			])
			|> error.MissingRequiredFlag
			|> Error

		[_h_command, .._rest_command], _, _ if unnamed_arguments != [] ->
			// panic as "missing unnamed arguments"
			strformat("missing required flags: ", [
				list.map(unnamed_arguments, fn(cliarg) {
					let assert arguments.UnnamedArgument(name, _) = cliarg

					name
				})
				|> string.join(", ")
			])
			|> error.MissingRequiredFlag
			|> Error

		[arguments.Command(name, _description, _required, subs), ..rest_command], _, _ -> {
			// NOTE: if current name not matching, try next command
			use <- bool.lazy_guard(when: h_args != name, return: fn() { parse_aux(args, rest_command, flags, unnamed_arguments) })

			let subcommands = list.filter(subs, arguments.is_command)
			let subflags = list.filter(subs, arguments.is_flag)
			let subunnamedarguments = list.filter(subs, arguments.is_unnamed_argument)

			let result_rest_r = parse_aux(rest_args, subcommands, subflags, subunnamedarguments)

			use <- bool.guard(when: result.is_error(result_rest_r), return: result_rest_r)

			let assert Ok(rest_result) = result_rest_r
			let command_cliarg = cliargs.Command(name, True, rest_result)

			Ok([command_cliarg])
		}

		_, _, _ ->
			strformat("argument '{}' unknown", [h_args])
			|> error.UnknownArgument
			|> Error
	}
}

pub fn parse_argv(parser: Parser) -> Result(cliargs.CLIArgs, ParsingError) {
	parse(parser, argv.load().arguments)
}
