let cfg = import "knx-model.yaml" in
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

  sort_by_floor = fun entities =>
    let floor_index = {
      "Basement" = -1,
      "Ground floor" = 0,
      "1st floor" = 1,
      "2nd floor" = 2,
    }
    in
    let location_to_floor =
      cfg.locations
      |> std.array.map (fun r => { field = r.name, value = r.location })
      |> std.record.from_array
    in
    let location_to_floor_index =
      location_to_floor
      |> std.record.map_values (fun r => std.record.get_or (std.to_string r) 99 floor_index)
    in
    let compare_locations = fun e1 e2 =>
      std.string.compare e1.function.location e2.function.location
    in
    let compare_floors = fun e1 e2 =>
      std.number.compare
        location_to_floor_index."%{e1.function.location}"
        location_to_floor_index."%{e2.function.location}"
    in
    entities
    |> std.array.map (fun e => e & { function.floor = location_to_floor."%{e.function.location}" })
    |> std.array.sort compare_locations
    |> std.array.sort compare_floors
}
