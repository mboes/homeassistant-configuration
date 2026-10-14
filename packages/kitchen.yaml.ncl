let lib = import "../lib.ncl" in

let alarm_entities = [
  "//Main kitchen/Freezer/Freezer door alarm",
  "//Main kitchen/Freezer/Freezer temperature alarm",
  "//Main kitchen/Refrigerator/Refrigerator door alarm",
  "//Main kitchen pantry/Fridge freezer/Freezer door alarm",
  "//Main kitchen pantry/Fridge freezer/Freezer temperature alarm",
  "//Main kitchen pantry/Fridge freezer/Refrigerator door alarm",
]
in

{
  automation =
    alarm_entities
    |> std.array.map (fun alarm =>
      let tag = "fridge-door" in
      {
        alias = "Notify owners of %{alarm}",
        description = "Critical alert while the %{alarm} is active",
        mode = "single",
        triggers = [
          { trigger = "state", entity_id = lib.entity_id "binary_sensor" alarm, to = "on", id = "alarm_on" },
          { trigger = "state", entity_id = lib.entity_id "binary_sensor" alarm, to = "off", id = "alarm_off" },
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
                        push = {
                          sound = { name = "default", critical = 1, volume = 1.0 },
                        },
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
