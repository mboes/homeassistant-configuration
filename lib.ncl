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
    "%{domain}.%{slug}",
  group
    : forall a. (a -> String) -> Array a -> { _ : Array a }
    = fun f =>
      std.array.fold_left
        (fun acc x =>
          let key = f x in
          std.record.update key (std.record.get_or key [] acc |> std.array.append x) acc
        )
        {},
}
