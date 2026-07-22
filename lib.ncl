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
    | Dyn -> Dyn -> Array std.array.NonEmpty
    = fun f xs =>
      xs
      |> match {
        [] => [],
        _ =>
          let op = fun { chunks, current_key, start, end } x =>
            let x_key = f x in
            if x_key != current_key then
              let chunks = chunks |> std.array.append (%array/slice% start end xs) in
              let start = end in
              let end = end + 1 in
              let current_key = x_key in
              { include [chunks, current_key, start, end] }
            else
              let end = end + 1 in
              { include [chunks, current_key, start, end] }
          in
          let init = {
            chunks = [],
            current_key = f (std.array.first xs),
            start = 0,
            end = 1,
          }
          in
          std.array.fold_left op init (std.array.drop_first xs)
          |> match {
            { chunks, start, end, .. } =>
              chunks |> std.array.append (%array/slice% start end xs)
          }
      },

  group
    : forall a. (a -> String) -> Array a -> { _ : Array a }
    | Dyn -> Dyn -> { _ | std.array.NonEmpty }
    = fun f xs =>
      xs
      |> std.array.sort (fun x y => std.string.compare (f x) (f y))
      |> chunk f
      |> std.array.map (fun ys => { field = f (std.array.first ys), value = ys })
      |> std.record.from_array,

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
    std.array.reduce_right
      std.function.compose
      [
        std.array.sort compare_floors,
        std.array.sort compare_locations,
        std.array.map (fun e => e & { function.floor = location_floors."%{e.function.location}" }),
      ]
}
