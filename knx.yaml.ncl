let cfg = import "knx-model.yaml" in
let knx = {
  type_is = fun type f => f.type == type,
  name_is = fun name f => f.name == name,
  location_is = fun loc f => f.location == loc,
  location_type_is =
    let location_types =
      cfg.locations
      |> std.array.map (fun r => { field = r.name, value = r.type })
      |> std.record.from_array
    in
    fun type f => std.record.get f.location location_types == type,
  and = fun p1 p2 f => p1 f && p2 f,
  name_matches = fun pat =>
    # Share compilation of regex.
    let is_match = std.string.is_match (std.string.lowercase pat) in
    fun f => f.name |> std.string.lowercase |> is_match,
  name_contains = fun word => name_matches "\\b%{word}s?\\b",
  merge =
    let f = fun r1 r2 =>
      {
        binary_sensor = std.record.get_or "binary_sensor" [] r1 @ std.record.get_or "binary_sensor" [] r2,
        button = std.record.get_or "button" [] r1 @ std.record.get_or "button" [] r2,
        climate = std.record.get_or "climate" [] r1 @ std.record.get_or "climate" [] r2,
        cover = std.record.get_or "cover" [] r1 @ std.record.get_or "cover" [] r2,
        date = std.record.get_or "date" [] r1 @ std.record.get_or "date" [] r2,
        datetime = std.record.get_or "datetime" [] r1 @ std.record.get_or "datetime" [] r2,
        fan = std.record.get_or "fan" [] r1 @ std.record.get_or "fan" [] r2,
        light = std.record.get_or "light" [] r1 @ std.record.get_or "light" [] r2,
        notify = std.record.get_or "notify" [] r1 @ std.record.get_or "notify" [] r2,
        number = std.record.get_or "number" [] r1 @ std.record.get_or "number" [] r2,
        scene = std.record.get_or "scene" [] r1 @ std.record.get_or "scene" [] r2,
        select = std.record.get_or "select" [] r1 @ std.record.get_or "select" [] r2,
        sensor = std.record.get_or "sensor" [] r1 @ std.record.get_or "sensor" [] r2,
        switch = std.record.get_or "switch" [] r1 @ std.record.get_or "switch" [] r2,
        text = std.record.get_or "text" [] r1 @ std.record.get_or "text" [] r2,
        time = std.record.get_or "time" [] r1 @ std.record.get_or "time" [] r2,
        weather = std.record.get_or "weather" [] r1 @ std.record.get_or "weather" [] r2,
      }
      |> std.record.filter (fun k v => v != [])
    in std.array.reduce_left f
}
in
# The names of generated entities have a special form, to
# distinguish them from automatically or manually created entities.
let GeneratedEntityName = std.contract.from_predicate (std.string.is_match "^//") in
let base_entity = fun f =>
  {
    function | not_exported = f,
    name
      | GeneratedEntityName
      | default
      = "//%{f.location}/%{f.name}",
  }
in
let select_flatten = fun pred mk =>
  cfg.functions
  |> std.array.filter pred
  |> std.array.map (fun f => mk f |> std.array.map (fun r => r & base_entity f))
  |> std.array.flatten
  |> std.array.map (std.record.filter (fun _ v => v != null))
  # XXX Workaround https://github.com/nickel-lang/nickel/issues/2633
  |> std.array.map (fun r => r & base_entity r.function)
    | std.array.NonEmpty
in
let select = fun pred mk => select_flatten pred (fun f => [mk f]) in
knx.merge [
  # Lights
  {
    light =
      std.array.flatten [
        select
          (knx.type_is "dimmable light")
          (fun f =>
            {
              address = f.group_addresses.Switching,
              state_address = std.record.get_or "Status" null f.group_addresses,
              brightness_address = f.group_addresses."dimming value",
              brightness_state_address = std.record.get_or "Value" null f.group_addresses,
            }
          ),
        select
          (knx.type_is "switchable light")
          (fun f =>
            {
              address = f.group_addresses.Switching,
              state_address = std.record.get_or "Status" null f.group_addresses,
            }
          ),
      ],

    # Central functions don't have a state address, so buttons are the
    # better abstraction than lights. They only turn off.
    button =
      std.array.flatten [
        select
          (knx.and (knx.type_is "dimmable light") (knx.name_matches "^All "))
          (fun f =>
            {
              address = f.group_addresses.Switching,
              payload = 0,
            }
          ),
        select
          (knx.and (knx.type_is "switchable light") (knx.name_matches "^All "))
          (fun f =>
            {
              address = f.group_addresses.Switching,
              payload = 0,
            }
          ),
      ],
  },

  # Rollers
  {
    cover =
      select
        (knx.and (knx.type_is "sun protection") (knx.name_contains "roller"))
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."blinds position",
          }
        ),
  },

  # Blinds
  {
    cover =
      select
        (knx.and (knx.type_is "sun protection") (knx.name_contains "blind"))
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."blinds position",
            angle_address = f.group_addresses."slat position",
          }
        ),
  },

  # Nets
  {
    cover =
      select
        (knx.name_contains "net")
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses.Position,
          }
        ),
  },

  # Climate control mode
  {
    switch =
      select_flatten
        (knx.name_is "Climate control mode")
        (fun f =>
          [
            {
              name = "//Climate control",
              address = f.group_addresses.Switching,
            },
            {
              name = "//Domestic hot water",
              address = f.group_addresses."Domestic hot water",
            },
          ]
        ),
    select =
      select_flatten
        (knx.name_is "Climate control mode")
        (fun f =>
          [
            {
              name = "//Climate control mode",
              address = f.group_addresses.Heating,
              payload_length = 0,
              options = [
                { option = "Heat", payload = 1 },
                { option = "Cool", payload = 0 },
              ],
            },
          ]
        ),
  },

  # Floor heating
  {
    climate =
      select
        (knx.name_is "Floor heating")
        (fun f =>
          {
            temperature_address = f.group_addresses."Current temperature",
            target_temperature_address = f.group_addresses."Setpoint temperature",
            target_temperature_state_address = f.group_addresses."Setpoint temperature status",
            on_off_address = f.group_addresses.Switching,
            on_off_state_address = f.group_addresses.Status,
          }
        ),
  },

  # Casement windows
  {
    binary_sensor =
      select
        (knx.name_contains "casement window")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Doors
  {
    binary_sensor =
      select
        (knx.name_matches "^door")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Motorized windows
  {
    binary_sensor =
      select
        (knx.name_contains "motorized window")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
          }
        ),
    cover =
      select
        (knx.name_contains "motorized window")
        (fun f =>
          {
            move_long_address = f.group_addresses.Movement,
            move_short_address = f.group_addresses."Step/Stop",
            position_address = f.group_addresses."Position",
          }
        ),
  },

  # Sliding windows
  {
    binary_sensor =
      select
        (knx.name_matches "^sliding windows")
        (fun f =>
          {
            name = "//%{f.location}/%{f.name}/Contact",
            state_address = f.group_addresses.Status,
          }
        ),
    switch =
      select
        (knx.and (knx.name_is "All sliding windows") (knx.location_type_is "room"))
        (fun f =>
          {
            name = "//%{f.location}/Sliding windows/Lock",
            address = f.group_addresses.Lock,
            state_address = std.record.get_or "Lock status" null f.group_addresses,
          }
        ),
  },

  # Air conditioning
  {
    climate =
      select
        (knx.name_contains "air conditioning")
        (fun f =>
          {
            temperature_address = f.group_addresses."Current temperature",
            target_temperature_address = f.group_addresses."Setpoint temperature",
            target_temperature_state_address = f.group_addresses."Setpoint temperature status",
            on_off_address = f.group_addresses.Switching,
            on_off_state_address = f.group_addresses.Status,
            fan_speed_address = f.group_addresses."Fan speed",
            fan_speed_state_address = f.group_addresses."Fan speed status",
          }
        ),
  },

  # Towel heaters
  {
    switch =
      select
        (knx.name_contains "towel heater")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = std.record.get_or "Status" null f.group_addresses,
          }
        ),
  },

  # Alarm
  {
    switch =
      select_flatten
        (knx.name_is "Alarm")
        (fun f =>
          [
            {
              name = "//Intrusion alarm/Arm",
              address = f.group_addresses.Arm,
              state_address = f.group_addresses."Arm status",
            },
            {
              name = "//Intrusion alarm/Partial arm",
              address = f.group_addresses."Partial arm",
              state_address = f.group_addresses."Partial arm status",
            },
            {
              name = "//Intrusion alarm/Disarm",
              address = f.group_addresses.Disarm,
              state_address = f.group_addresses."Disarm status",
            },
          ]
        ),
    binary_sensor =
      select_flatten
        (knx.name_is "Alarm")
        (fun f =>
          [
            {
              name = "//Intrusion alarm",
              state_address = f.group_addresses."Intrusion alarm status",
            },
            {
              name = "//Fire alarm",
              state_address = f.group_addresses."Fire alarm status",
            },
            {
              name = "//Panic alarm",
              state_address = f.group_addresses."Panic alarm status",
            },
          ]
        ),
  },

  # BMS
  {
    binary_sensor =
      select
        (knx.name_is "BMS")
        (fun f =>
          {
            name = "//BMS Alarm",
            state_address = f.group_addresses."Alarm status",
          }
        ),
  },

  # UPS
  {
    binary_sensor =
      select_flatten
        (knx.name_is "UPS")
        (fun f =>
          [
            {
              name = "//UPS battery",
              state_address = f.group_addresses."Battery status",
            },
            {
              name = "//UPS alarm",
              state_address = f.group_addresses."Alarm status",
            },
          ]
        ),
  },

  # Motion detection
  {
    binary_sensor =
      select
        (knx.name_contains "motion detection")
        (fun f =>
          {
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Water leak detection
  {
    binary_sensor =
      select
        (knx.name_contains "water leak detection")
        (fun f =>
          {
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Ventilation
  {
    switch =
      select
        (knx.name_is "Ventilation")
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Garage door
  {
    switch =
      select
        (knx.and (knx.location_is "Garage") (knx.name_is "Door"))
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Garage gate
  {
    switch =
      select
        (knx.and (knx.location_is "Garage") (knx.name_is "Gate"))
        (fun f =>
          {
            address = f.group_addresses.Switching,
            state_address = f.group_addresses.Status,
          }
        ),
  },

  # Weather station
  {
    weather =
      select
        (knx.name_is "Weather")
        (fun f =>
          {
            name = "//Weather station",
            address_temperature = f.group_addresses.Temp,
            address_wind_speed = f.group_addresses.Wind,
            address_rain_alarm = f.group_addresses.Rain,
          }
        ),
  },
]
