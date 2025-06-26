import gleam/io
import gleam/string

const sep = "{}"

fn strformat_aux(parts1: List(String), parts2: List(String)) -> String {
	case parts1, parts2 {
		[], [] -> ""
		[s], [] -> s
		[s1, s2, ..s_rest], [j1, ..j_rest] -> strformat_aux([s1 <> j1 <> s2, ..s_rest], j_rest)
		_, _ -> panic as "wrong number of joiners"
	}
}

pub fn strformat(template: String, fmts: List(String)) -> String {
	strformat_aux(
		string.split(template, sep),
		fmts
	)
}


pub fn printformat(template: String, fmts: List(String)) {
	strformat(template, fmts)
	|> io.println
}


pub fn push_back(l: List(value), x: value) -> List(value) {
	case l {
		[] -> [x]
		[h, ..t] -> [h, ..push_back(t, x)]
	}
}
