import gleam/option.{type Option, None}

const default_enforce_required = True
const default_on_parse_error = None

pub type ParserSettings {
	ParserSettings(enforce_required: Bool, on_parse_error: Option(fn() -> Nil))
}

pub fn default_parser_settings() -> ParserSettings {
	ParserSettings(
		default_enforce_required,
		default_on_parse_error
	)
}
