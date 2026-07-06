let knx = import "../../knx.yaml.ncl" in
let lib = import "../../lib.ncl" in
let locks =
  knx.switch
  |> std.array.filter (fun r => std.string.is_match "/Lock$" r.name)
  |> std.array.map (fun r =>
    let switch_id = lib.entity_id "switch" r.name in
    {
      name = r.name,
      state = "{{ is_state('%{switch_id}', 'on') }}",
      lock = [
        {
          action = "switch.turn_on",
          target = { entity_id = switch_id }
        }
      ],
      unlock = [
        {
          action = "switch.turn_off",
          target = { entity_id = switch_id }
        }
      ],
    }
  )
in
{
  template = [{ lock = locks }],
}
