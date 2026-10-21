let knx = import "../integrations/knx.yaml.ncl" in
let lib = import "../lib.ncl" in
let cfg = import "../models/floor_plan.ncl" in

{
  light =
    knx.light
    |> std.array.filter (fun e => !std.string.is_match "^All lights" e.function.name)
    |> lib.sort_by_floor
    |> std.array.chunk (fun e => e.function.location)
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
        let group_name = "//%{location}/Lights" in
        {
          name = "%{group_name}/Summary",
          state = m%"
              {% set on = state_attr('%{lib.entity_id "light" group_name}', 'entity_id')  | default([], true) | select('is_state','on') | list | count %}
              {% set total = state_attr('%{lib.entity_id "light" group_name}', 'entity_id')  | default([], true) | list | count %}
	      {{ on ~ '/' ~ total if on else 'OFF' }}
            "%,
        }
      ),
  },
  automation =
    cfg.ancillary_rooms
    |> std.record.to_array
    |> std.array.map (fun r =>
      let primary = r.field in
      let secondaries = r.value in
      let Singleton =
        std.contract.from_validator (match {
          [_] => 'Ok,
          _ => 'Error { message = "No or too many lights in %{primary}" },
        }
        )
      in
      {
        alias = "Turn off %{primary}'s ancillary rooms",
        triggers = [
          {
            trigger = "knx.telegram",
            destination =
              let lights =
                let all_lights =
                  knx.button
                  |> std.array.filter (fun e => std.string.contains "/All lights" e.name)
                  |> std.array.filter (fun e => e.function.location == primary)
                in
                let some_lights =
                  knx.light
                  |> std.array.filter (fun e => e.function.location == primary)
                in
                # Prefer group address of "/All lights" if it exists.
                if std.array.length all_lights == 1 then all_lights else some_lights | Singleton
              in
              lights
              |> std.array.first
              |> std.record.get "address",
            group_value_read = false,
            outgoing = false,
          }
        ],
        conditions = ["{{ trigger.payload == 0 }}"],
        actions = [
          {
            action = "light.turn_off",
            target.entity_id =
              secondaries
              |> std.array.map (fun room => lib.entity_id "light" "//%{room}/Lights"),
          },
        ],
      }
    )
}
