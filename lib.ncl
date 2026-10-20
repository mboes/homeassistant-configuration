let cfg = import "knx-model.yaml" in

let floor_index = {
  "Basement" = -1,
  "Ground floor" = 0,
  "1st floor" = 1,
  "2nd floor" = 2,
}
in

{
  slug = fun name =>
    name
    |> std.string.replace_regex "[^a-zA-Z0-9]" " "
    |> std.string.replace_regex "\\s+" "_"
    |> std.string.replace_regex "^_" ""
    |> std.string.replace_regex "_$" ""
    |> std.string.lowercase,

  entity_id = fun domain name => "%{domain}.%{slug name}",

  compare_floors = fun f1 f2 =>
    std.number.compare
      (std.record.get_or (std.to_string f1) 99 floor_index)
      (std.record.get_or (std.to_string f2) 99 floor_index),

  sort_by_floor = fun entities =>
    let location_to_floor =
      cfg.locations
      |> std.array.map (fun r => { field = r.name, value = r.location })
      |> std.record.from_array
    in
    let compare_function_locations = fun e1 e2 =>
      std.string.compare e1.function.location e2.function.location
    in
    let compare_function_floors = fun e1 e2 =>
      compare_floors e1.function.floor e2.function.floor
    in
    entities
    |> std.array.map (fun e => e & { function.floor = location_to_floor."%{e.function.location}" })
    |> std.array.sort compare_function_locations
    |> std.array.sort compare_function_floors
}
