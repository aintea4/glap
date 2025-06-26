pub type ParsingError {
	MissingUnnamedArgument(String)
	MissingRequiredFlag(String)
	MissingCommand(String)
	MissingFlagValue(String)
	UnknownArgument(String)
}
