import gleam/list
import gleeunit
import gtm_tool_directory.{Entry}

pub fn main() {
  gleeunit.main()
}

pub fn index_loaded_test() {
  assert list.length(gtm_tool_directory.all()) == 287
}

pub fn search_apollo_test() {
  let assert [Entry(name: _, kind: _, url: url, description: _), ..] =
    gtm_tool_directory.search("apollo", "", 5)
  assert url != ""
}

pub fn kind_filter_test() {
  let hits = gtm_tool_directory.search("clay", "comparison", 10)
  assert hits != []
  assert list.all(hits, fn(e) { e.kind == "Comparison" })
}

pub fn no_hit_test() {
  assert gtm_tool_directory.search("zzzznotatool", "", 5) == []
}
