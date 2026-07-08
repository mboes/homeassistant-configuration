let knx = import "../knx.yaml.ncl" in
let lib = import "../lib.ncl" in
{
  light =
    knx.light
    |> std.array.filter (fun e => !std.string.is_match "^All lights" e.function.name)
    |> lib.sort_by_floor
    |> lib.chunk (fun e => e.function.location)
    |> std.array.map (fun lights =>
      let location = (std.array.first lights).function.location in
      {
        platform = "group",
        name = "//%{location}/Lights",
        entities =
          lights
          |> std.array.map (fun light => lib.entity_id "light" light.name)
      }
    ),
  template = {
    sensor =
      knx.light
      |> std.array.sort_dedup (fun e1 e2 => std.string.compare e1.function.location e2.function.location)
      |> std.array.map (fun e =>
        let location = e.function.location in
        let group_id = "//%{location}/Lights" in
        {
          name = "%{group_id}/Summary",
          state = m%"
            {{ state_attr('%{lib.entity_id "light" group_id}', 'entity_id')  | default([], true) | select('is_state','on') | list | count }}
          "%,
          attributes = {
            total = m%"
	      {{ state_attr('%{lib.entity_id "light" group_id}', 'entity_id') | default([], true) | count }}
	    "%,
          },
        }
      ),
  },
}
