let knx = import "../integrations/knx.yaml.ncl" in
let lib = import "../lib.ncl" in
let cfg = import "../models/devices.ncl" in

let lock_button = fun device => "%{device} button bottom" in
let unlock_button = fun device => "%{device} button top" in

{
  automation =
    cfg.lock_buttons
    |> std.array.flat_map (fun { location, name } =>
      [
        {
          alias = "Unlock %{location} from %{name}",
          triggers = [
            {
              trigger = "event.received",
              target.entity_id = lib.entity_id "event" (unlock_button name),
              options.event_type = "initial_press",
            },
          ],
          actions = [
            {
              action = "lock.lock",
              target.entity_id = lib.entity_id "lock" "//%{location}/Sliding windows/Lock"
            },
            { delay.seconds = 1, },
            {
              action = "lock.unlock",
              target.entity_id = lib.entity_id "lock" "//%{location}/Sliding windows/Lock"
            },
          ],
        },
        {
          alias = "Lock %{location} from %{name}",
          triggers = [
            {
              trigger = "event.received",
              target.entity_id = lib.entity_id "event" (lock_button name),
              options.event_type = "initial_press",
            },
          ],
          actions = [
            {
              action = "lock.lock",
              target.entity_id = lib.entity_id "lock" "//%{location}/Sliding windows/Lock"
            },
          ],
        },
      ]
    ),
}
