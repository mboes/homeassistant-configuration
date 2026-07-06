let knx = import "../../knx.yaml.ncl" in
let lib = import "../../lib.ncl" in
let locks =
  knx.switch
  |> std.array.filter (fun r => std.string.is_match "/Lock$" r.name)
  |> std.array.map (fun r =>
    {
      name = r.name,
      state = "{{ 'locked' if is_state('switch.front_door_lock_switch', 'on') else 'unlocked' }}",
      lock = [
        {
          action = "switch.turn_on",
          target = { entity_id = lib.entity_id "switch" r.name }
        }
      ],
      unlock = [
        {
          action = "switch.turn_off",
          target = { entity_id = lib.entity_id "switch" r.name }
        }
      ],
    }
  )
in
{
  template = [{ lock = locks }],
}
