{
  entity_id = fun domain name =>
    let slug =
      name
      |> std.string.replace_regex "[^a-zA-Z0-9]" " "
      |> std.string.replace_regex "\\s+" "_"
      |> std.string.replace_regex "^_" ""
      |> std.string.replace_regex "_$" ""
      |> std.string.lowercase
    in
    "%{domain}.%{slug}"
}
