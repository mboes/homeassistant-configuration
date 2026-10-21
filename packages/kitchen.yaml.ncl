let lib = import "../lib.ncl" in
let cfg = import "../models/home-connect.ncl" in

{
  automation =
    cfg.alarm_entities
    |> std.array.map (fun alarm =>
      let tag = "fridge-door" in
      {
        alias = "Notify owners of %{alarm}",
        description = "Critical alert while the %{alarm} is active",
        mode = "single",
        triggers = [
          { trigger = "state", entity_id = lib.entity_id "sensor" alarm, to = "present", id = "alarm_on" },
          { trigger = "state", entity_id = lib.entity_id "sensor" alarm, to = "off", id = "alarm_off" },
        ],
        actions = [
          {
            choose = [
              {
                conditions = [{ condition = "trigger", id = "alarm_on" }],
                sequence = [
                  {
                    action = "notify.owners",
                    data = {
                      message = alarm,
                      data = {
                        tag = lib.slug alarm,
                        push.interruption-level = "critical",
                      },
                    },
                  },
                ],
              },
              {
                conditions = [{ condition = "trigger", id = "alarm_off" }],
                sequence = [
                  {
                    action = "notify.owners",
                    data = {
                      message = "clear_notification",
                      data = { tag = lib.slug alarm },
                    },
                  },
                ],
              },
            ],
          },
        ],
      }
    )
}
