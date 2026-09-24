let knx = import "../knx.yaml.ncl" in
let lib = import "../lib.ncl" in
{
  automation =
    knx.binary_sensor
    |> std.array.filter (fun e => std.record.has_field "device_class" e && e.device_class == "motion")
    |> std.array.filter (fun e => std.string.is_match "Basement corridor" e.function.location)
    |> std.array.group (fun e => e.function.location)
    |> std.record.map (fun location sensors =>
      {
        alias = "Turn on %{location} lights on motion",
        mode = "restart",
        triggers =
          sensors
          |> std.array.map (fun s =>
            {
              trigger = "state",
              entity_id = lib.entity_id "binary_sensor" s.name,
              to = "on",
            }
          ),
        actions = [
          {
            action = "light.turn_on",
            target.entity_id = lib.entity_id "light" "//%{location}/Lights",
          },
          {
            delay.minutes = 10
          },
          {
            action = "light.turn_off",
            target.entity_id = lib.entity_id "light" "//%{location}/Lights",
          },
        ],
      }
    )
    |> std.record.values,
}
