pub type ParsingError {
	MissingUnnamedArgument(error: String)
	MissingRequiredFlag(error: String)
	MissingCommand(error: String)
	MissingFlagValue(error: String)
	UnknownArgument(error: String)
}
