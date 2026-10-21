let knx = import "../integrations/knx.yaml.ncl" in
let lib = import "../lib.ncl" in
let cfg = import "../models/matter.ncl" in

let lock_button = fun device => "%{device} button bottom" in
let unlock_button = fun device => "%{device} button top" in

{
  automation =
    cfg.lock_button_devices
    |> std.array.flat_map (fun { location, device } =>
      [
        {
          alias = "Unlock %{location} from %{device}",
          triggers = [
            {
              trigger = "event.received",
              target.entity_id = lib.entity_id "event" (unlock_button device),
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
          alias = "Lock %{location} from %{device}",
          triggers = [
            {
              trigger = "event.received",
              target.entity_id = lib.entity_id "event" (lock_button device),
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
