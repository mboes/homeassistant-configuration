let knx = import "../knx.yaml.ncl" in
let lib = import "../lib.ncl" in
let contacts_by_location =
  knx.binary_sensor
  |> std.array.filter (fun e => std.string.is_match "/Sliding window.*/Contact$" e.name)
  |> std.array.group (fun e => e.function.location)
in
let locks =
  knx.switch
  |> std.array.filter (fun e => std.string.is_match "/Lock$" e.name)
  |> std.array.map (fun e =>
    let switch_id = lib.entity_id "switch" e.name in
    {
      name = e.name,
      state = "{{ is_state('%{switch_id}', 'off') }}",
      lock = [
        {
          action = "switch.turn_off",
          target = { entity_id = switch_id }
        }
      ],
      unlock = [
        {
          action = "switch.turn_on",
          target = { entity_id = switch_id }
        }
      ],
      function | not_exported = e.function,
    }
  )
in
{
  template = [{ lock = locks }],
  automation =
    locks
    |> std.array.map (fun e =>
      {
        alias = "Unlock if open - %{e.name}",
        triggers = [
          {
            trigger = "state",
            entity_id =
              contacts_by_location."%{e.function.location}"
              |> std.array.map (fun e => lib.entity_id "binary_sensor" e.name),
            to = "on",
            for.minutes = 1,
          }
        ],
        conditions = [
          {
            condition = "state",
            entity_id = lib.entity_id "lock" e.name,
            state = "locked",
          },
        ],
        actions = [
          {
            action = "lock.unlock",
            target.entity_id = lib.entity_id "lock" e.name,
          },
        ]
      }
    )
}
