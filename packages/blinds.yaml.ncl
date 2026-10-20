let knx = import "../integrations/knx.yaml.ncl" in
let lib = import "../lib.ncl" in

# As measured.
let blind_slats_open_position = 66 in

{
  automation =
    knx.cover
    |> lib.sort_by_floor
    |> std.array.chunk (fun e => e.function.location)
    |> std.array.flat_map (fun covers =>
      let filter_by_word = fun word =>
        std.array.filter (fun e => std.string.is_match "\\b%{word}s?\\b" e.function.name)
      in
      let blinds = covers |> filter_by_word "[Bb]lind" in
      let rollers = covers |> filter_by_word "[Rr]oller" in
      let source_roller =
        # Prefer "All rollers" if it exists.
        rollers
        |> std.array.concat (rollers |> std.array.filter (fun e => e.function.name == "All rollers"))
        |> std.array.first
      in
      if blinds == [] || rollers == [] then
        []
      else
        [
          {
            alias = "Close blinds when %{source_roller.function.location} rollers are down",
            triggers = [
              {
                trigger = "cover.shade_closed",
                target.entity_id = lib.entity_id "cover" source_roller.name,
              },
            ],
            actions = [
              {
                action = "cover.close_cover_tilt",
                target.entity_id = blinds |> std.array.map (fun e => lib.entity_id "cover" e.name),
              },
            ],
          },
          {
            alias = "Open blinds when %{source_roller.function.location} rollers are partially up",
            triggers = [
              {
                trigger = "state",
                entity_id = lib.entity_id "cover" source_roller.name,
                to = "opening",
              },
            ],
            actions = [
              {
                action = "cover.set_cover_tilt_position",
                target.entity_id = blinds |> std.array.map (fun e => lib.entity_id "cover" e.name),
                data.tilt_position = blind_slats_open_position,
              },
            ],
          },
        ]
    )
}
