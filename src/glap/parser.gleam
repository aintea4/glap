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
import glap/parser_settings.{type ParserSettings}
import glap/help_settings.{type HelpSettings,default_help_settings}

const tabdesc_char = " "
const extra_description_space_length = 4

pub type Parser {
	Parser(
		arguments: List(arguments.Argument),
		description: String,
		settings: Option(ParserSettings),
		help_settings: Option(HelpSettings)
	)
}

pub fn parser_print(parser: Parser) {
	let Parser(args, description, _, _) = parser

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


fn show_help_aux(
	args: List(arguments.Argument),
	showhelp_settings: HelpSettings,
	printfun: fn(String) -> Nil,
	tabdesc_length: Int,
	indent_level: Int
) {
	use <- bool.guard(when: args == [], return: Nil)
	let assert [args_h, ..args_rest] = args

	let indentstr = string.repeat(showhelp_settings.tabstring, indent_level)

	case args_h {
		arguments.Flag(_, _, _, _, _) -> {
			help_settings.format_argument_without_desc(args_h)
			|> string.append(indentstr, _)
			|> string.pad_end(to: tabdesc_length, with: tabdesc_char)
			|> string.append(arguments.get_description(args_h) <> "\n")
			|> printfun
		}
		arguments.UnnamedArgument(_, _) -> {
			help_settings.format_argument_without_desc(args_h)
			|> string.append(indentstr, _)
			|> string.pad_end(to: tabdesc_length, with: tabdesc_char)
			|> string.append(arguments.get_description(args_h) <> "\n")
			|> printfun
		}
		arguments.Command(_, _, _, subcommands) -> {
			case indent_level < showhelp_settings.recursive_max_depth {
				True -> printfun("\n")
				False -> Nil
			}

			help_settings.format_argument_without_desc(args_h)
			|> string.append(indentstr, _)
			|> string.pad_end(to: tabdesc_length, with: tabdesc_char)
			|> string.append(arguments.get_description(args_h) <> "\n")
			|> printfun

			case showhelp_settings.recursive_showhelp {
				True if indent_level < showhelp_settings.recursive_max_depth -> {
					show_help_aux(subcommands, showhelp_settings, printfun, tabdesc_length, indent_level+1)
				}
				_ -> Nil
			}

		}
	}

	show_help_aux(args_rest, showhelp_settings, printfun, tabdesc_length, indent_level)
}

pub fn show_help(parser: Parser) {
	let settings = option.unwrap(parser.help_settings, default_help_settings())

	let printfun = case settings.print_to_stderr {
		True -> io.print_error
		False -> io.print
	}

	let tabdesc_length = help_settings.get_tabdesc_string_length(parser.arguments) + extra_description_space_length

	strformat("Usage: {} [OPTS...]\n{}\n\n", [argv.load().program, parser.description])
	|> printfun

	show_help_aux(parser.arguments, settings, printfun, tabdesc_length, 0)
}


fn run_on_parse_error(settings: parser_settings.ParserSettings) {
	case settings.on_parse_error {
		Some(f) -> f()
		None -> Nil
	}
}

pub fn parse(parser: Parser, args: List(String)) -> Result(cliargs.CLIArgs, ParsingError) {
	let settings = option.unwrap(parser.settings, parser_settings.default_parser_settings())

	let subcommands = list.filter(parser.arguments, arguments.is_command)
	let subflags = list.filter(parser.arguments, arguments.is_flag)
	let subunnamedarguments = list.filter(parser.arguments, arguments.is_unnamed_argument)

	case parse_aux(args, subcommands, subflags, subunnamedarguments, settings), settings.help_on_missing_argument {
		Ok(x), _ -> Ok(x)
		Error(#(e, args)), True -> {
			let showhelp_settings = option.unwrap(parser.help_settings, default_help_settings())

			let printfun = case showhelp_settings.print_to_stderr {
				True -> io.print_error
				False -> io.print
			}

			let tabdesc_length = help_settings.get_tabdesc_string_length(parser.arguments) + extra_description_space_length

			show_help_aux(args, showhelp_settings, printfun, tabdesc_length, 0)

			run_on_parse_error(settings)
			Error(e)
		}
		Error(#(e, _)), False -> {
			run_on_parse_error(settings)
			Error(e)
		}
	}
}


fn parse_aux(
	args: List(String),
	commands: List(arguments.Argument),
	flags: List(arguments.Argument),
	unnamed_arguments: List(arguments.Argument),
	parser_settings: ParserSettings
) -> Result(cliargs.CLIArgs, #(ParsingError, List(arguments.Argument))) {
	// NOTE: order is important
	let arguments = list.flatten([unnamed_arguments, flags, commands])

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


	use <- bool.guard(when: args == [] && required_commands != [] && parser_settings.enforce_required, return:
		Error(
			#(
				error.MissingCommand(utils.strformat("missing required command: {}", [required_commands_str])),
				arguments
			)
		)
	)

	use <- bool.guard(when: args == [] && unnamed_arguments != [] && parser_settings.enforce_required, return:
		strformat("missing required flags: {}", [
			list.map(unnamed_arguments, fn(cliarg) {
				let assert arguments.UnnamedArgument(name, _) = cliarg

				name
			})
			|> string.join(", ")
		])
		|> error.MissingRequiredFlag
		|> fn(e) { Error(#(e, arguments)) }
	)

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
			use <- bool.lazy_guard(when: !string.starts_with(h_args, short) && !string.starts_with(h_args, long), return: fn() {
				let assert [h_flag, h2_flag, ..rest_flag] = flags

				// WARN: might be the cause of infinite loop recursion finding correct flag
				// parse_aux(args, commands, [h2_flag, ..rest_flag], unnamed_arguments)
				parse_aux(args, commands, [h2_flag, ..utils.push_back(rest_flag, h_flag)], unnamed_arguments, parser_settings)
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
			let rest_result_r = parse_aux(rest_args2, commands, rest_flag, unnamed_arguments, parser_settings)

			use <- bool.guard(when: result.is_error(rest_result_r), return: rest_result_r)

			let assert Ok(rest_result) = rest_result_r

			Ok([flag_cliarg, ..rest_result])
		}

		// NOTE: something else than a flag, therefore an unnamed argument
		_, _, [arguments.UnnamedArgument(name, _description), ..rest_unnamed_argument] -> {
			let unnamed_argument_cliarg = cliargs.UnnamedArgument(name, h_args)
			let rest_result_r = parse_aux(rest_args, commands, flags, rest_unnamed_argument, parser_settings)

			use <- bool.guard(when: result.is_error(rest_result_r), return: rest_result_r)

			let assert Ok(rest_result) = rest_result_r
			Ok([unnamed_argument_cliarg, ..rest_result])
		}

		// NOTE: unless only commands are left in which case we take this command

		[_h_command, .._rest_command], _, _ if required_flags != [] && parser_settings.enforce_required ->
			strformat("missing required flags: {}", [
				list.map(required_flags, fn(cliarg) {
					let assert arguments.Flag(short, long, _, _, _) = cliarg

					"[" <> short <> "|" <> long <> "]"
				})
				|> string.join(", ")
			])
			|> error.MissingRequiredFlag
			|> fn(e) { Error(#(e, arguments)) }

		[_h_command, .._rest_command], _, _ if unnamed_arguments != [] && parser_settings.enforce_required ->
			// panic as "missing unnamed arguments"
			strformat("missing required flags: {}", [
				list.map(unnamed_arguments, fn(cliarg) {
					let assert arguments.UnnamedArgument(name, _) = cliarg

					name
				})
				|> string.join(", ")
			])
			|> error.MissingRequiredFlag
			|> fn(e) { Error(#(e, arguments)) }

		[arguments.Command(name, _description, _required, subs), ..rest_command], _, _ -> {
			// NOTE: if current name not matching, try next command
			use <- bool.lazy_guard(when: h_args != name, return: fn() { parse_aux(args, rest_command, flags, unnamed_arguments, parser_settings) })

			let subcommands = list.filter(subs, arguments.is_command)
			let subflags = list.filter(subs, arguments.is_flag)
			let subunnamedarguments = list.filter(subs, arguments.is_unnamed_argument)

			let result_rest_r = parse_aux(rest_args, subcommands, subflags, subunnamedarguments, parser_settings)

			use <- bool.guard(when: result.is_error(result_rest_r), return: result_rest_r)

			let assert Ok(rest_result) = result_rest_r
			let command_cliarg = cliargs.Command(name, True, rest_result)

			Ok([command_cliarg])
		}

		_, _, _ ->
			strformat("argument '{}' unknown", [h_args])
			|> error.UnknownArgument
			|> fn(e) { Error(#(e, arguments)) }
	}
}

pub fn parse_argv(parser: Parser) -> Result(cliargs.CLIArgs, ParsingError) {
	parse(parser, argv.load().arguments)
}
