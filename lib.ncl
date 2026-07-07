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
  chunk
    : forall a k. (a -> k) -> Array a -> Array (Array a)
    = fun f xs =>
      xs
      |> match {
        [] => [],
        _ =>
          std.array.fold_left
            (fun {chunks, current_chunk, current_key} x =>
	      let x_key = f x in
              if x_key == current_key then
	        let current_chunk = std.array.append x current_chunk in
                { include [chunks, current_chunk, current_key] }
              else
	        let chunks = std.array.append current_chunk chunks in
		let current_chunk = [x] in
		let current_key = x_key in
                { include [chunks, current_chunk, current_key] }
            )
            { chunks = [], current_chunk = [], current_key = f (std.array.first xs) }
            xs
          |> match {
            { chunks, current_chunk, .. } => std.array.append current_chunk chunks,
          }
      },
}
