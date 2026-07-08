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
            (fun { chunks, current_chunk, current_key } x =>
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
  sort_by_floor =
    let cfg = import "knx-model.yaml" in
    let floor_index = {
      "Basement" = -1,
      "Ground floor" = 0,
      "1st floor" = 1,
      "2nd floor" = 2,
    }
    in
    let location_floors =
      cfg.locations
      |> std.array.map (fun r =>
        {
          field = r.name,
          value = std.record.get_or (std.string.from r.location) 99 floor_index
        }
      )
      |> std.record.from_array
    in

    let compare_locations = fun e1 e2 =>
      std.string.compare e1.function.location e2.function.location
    in
    let compare_floors = fun e1 e2 =>
      std.number.compare
        location_floors."%{e1.function.location}"
        location_floors."%{e2.function.location}"
    in
    std.function.compose
      (std.array.sort compare_floors)
      (std.array.sort compare_locations)
}
