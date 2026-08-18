let knx = import "../knx.yaml.ncl" in
let lib = import "../lib.ncl" in
{
  template =
    std.array.range 1 53
    |> std.array.map (fun x =>
      let group_address = "1/5/%{x}" in
      {
        trigger = {
          trigger = "knx.telegram",
          destination = group_address,
          group_value_read = false,
          group_value_response = false,
        },
        binary_sensor = {
          name = "//Irrigation/%{x}",
          state = "{{ trigger.value }}",
        },
        sensor = {
          name = "//Irrigation/%{x}/source",
          state = "{{ trigger.source }}",
        },
      }
    ),
}
