//// Search the [OneGTMLab](https://www.onegtmlab.dev) GTM tool directory from Gleam
//// or the command line: API reviews for sales and marketing tools, head-to-head
//// comparisons and plain-English GTM glossary terms.
////
//// The index is compiled into the package, so it works offline and sends no data
//// anywhere. Every result links to its full page on
//// [onegtmlab.dev/tool-directory](https://www.onegtmlab.dev/tool-directory).

import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string
import gtm_tool_directory/data

/// One page of the directory.
pub type Entry {
  Entry(name: String, kind: String, url: String, description: String)
}

/// Every entry in the directory.
pub fn all() -> List(Entry) {
  list.map(data.rows(), fn(r) {
    let #(name, kind, url, description) = r
    Entry(name, kind, url, description)
  })
}

fn kind_order(kind: String) -> Int {
  case kind {
    "Tool" -> 0
    "Category" -> 1
    "Comparison" -> 2
    _ -> 3
  }
}

/// Entries whose name or description contains every word of `query`.
/// `kind` filters by Tool, Category, Comparison or Glossary (case-insensitive,
/// empty means all). `limit` caps the result count (0 or less means 20).
pub fn search(query: String, kind: String, limit: Int) -> List(Entry) {
  let limit = case limit <= 0 {
    True -> 20
    False -> limit
  }
  let words =
    query
    |> string.lowercase
    |> string.split(" ")
    |> list.filter(fn(w) { w != "" })
  let wanted = string.lowercase(kind)
  let first = case words {
    [w, ..] -> w
    [] -> ""
  }
  let rank = fn(e: Entry) {
    case first != "" && string.starts_with(string.lowercase(e.name), first) {
      True -> 0
      False -> 1
    }
  }
  all()
  |> list.filter(fn(e) {
    let kind_ok = wanted == "" || string.lowercase(e.kind) == wanted
    let text = string.lowercase(e.name <> " " <> e.description)
    kind_ok && list.all(words, fn(w) { string.contains(text, w) })
  })
  |> list.sort(fn(a, b) {
    case int.compare(rank(a), rank(b)) {
      order.Eq -> int.compare(kind_order(a.kind), kind_order(b.kind))
      other -> other
    }
  })
  |> list.take(limit)
}

/// Command line entry point: `gleam run -- [--kind Tool] [--limit 10] words...`
pub fn main() -> Nil {
  let #(kind, limit, words) = parse(argv.load().arguments, "", 0, [])
  case search(string.join(list.reverse(words), " "), kind, limit) {
    [] -> {
      io.println("No matches.")
      halt(1)
    }
    hits ->
      list.each(hits, fn(e) {
        io.println(e.kind <> ": " <> e.name <> "\n  " <> e.url)
      })
  }
}

fn parse(
  args: List(String),
  kind: String,
  limit: Int,
  words: List(String),
) -> #(String, Int, List(String)) {
  case args {
    ["--kind", k, ..rest] -> parse(rest, k, limit, words)
    ["--limit", n, ..rest] ->
      parse(rest, kind, result_or(int.parse(n), 0), words)
    [w, ..rest] -> parse(rest, kind, limit, [w, ..words])
    [] -> #(kind, limit, words)
  }
}

fn result_or(r: Result(Int, Nil), default: Int) -> Int {
  case r {
    Ok(v) -> v
    Error(_) -> default
  }
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil
