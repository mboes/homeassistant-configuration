fun cfg =>
  let default_name = fun f => { name | default = "%{f.location} - %{f.name}" } in
  let select = fun pred mk =>
    cfg.functions
    |> std.array.filter pred
    |> std.array.map (fun f => mk f & default_name f)
    |> std.array.map (std.record.filter (fun _ v => v != null))
  in
  let select_flatten = fun pred mk =>
    cfg.functions
    |> std.array.filter pred
    |> std.array.map (fun f => mk f |> std.array.map (fun r => r & default_name f))
    |> std.array.flatten
    |> std.array.map (std.record.filter (fun _ v => v != null))
  in
  let type_is = fun type f => f.type == type in
  let name_is = fun name f => f.name == name in
  let location_is = fun location f => f.location == location in
  let and = fun p1 p2 f => p1 f && p2 f in
  let name_matches = fun pat =>
    # Share compilation of regex.
    let find = std.string.find (std.string.lowercase pat) in
    fun f =>
      f.name
      |> std.string.lowercase
      |> find
      |> (fun m => 0 <= m.index)
  in
  let name_matches_word = fun word => name_matches "\\b%{word}s?\\b" in
  let knx_merge =
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
  in
  knx_merge [
    # Lights
    {
      light =
        std.array.flatten [
          select
            (type_is "dimmable light")
            (fun f =>
              {
                address = f.group_addresses.Switching,
                state_address = std.record.get_or "Status" null f.group_addresses,
                brightness_address = f.group_addresses."dimming value",
                brightness_state_address = std.record.get_or "Value" null f.group_addresses,
              }
            ),
          select
            (type_is "switchable light")
            (fun f =>
              {
                address = f.group_addresses.Switching,
                state_address = std.record.get_or "Status" null f.group_addresses,
              }
            ),
        ],
    },

    # Rollers
    {
      cover =
        select
          (and (type_is "sun protection") (name_matches_word "roller"))
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
          (and (type_is "sun protection") (name_matches_word "blind"))
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
          (name_matches_word "net")
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
          (name_is "Climate control mode")
          (fun f =>
            [
              {
                name = "Climate control",
                address = f.group_addresses.Switching,
              },
              {
                name = "Domestic hot water",
                address = f.group_addresses."Domestic hot water",
              },
            ]
          ),
      select =
        select_flatten
          (name_is "Climate control mode")
          (fun f =>
            [
              {
                name = "Climate control mode",
                address = f.group_addresses.Heating,
                payload_length = 0,
                options = [
                  { option = "Heat", payload = 0 },
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
          (name_is "floor heating")
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

    # Air conditioning
    {
      climate =
        select
          (name_matches_word "air conditioning")
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

    # Sliding window locks
    {
      switch =
        select
          (name_matches_word "lock")
          (fun f =>
            {
              address = f.group_addresses.Switching,
              state_address = std.record.get_or "Status" null f.group_addresses,
            }
          ),
    },

    # Towel heaters
    {
      switch =
        select
          (name_matches_word "towel heater")
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
          (name_is "Alarm")
          (fun f =>
            [
              {
                name = "Intrusion alarm - Arm",
                address = f.group_addresses.Arm,
                state_address = f.group_addresses."Arm status",
              },
              {
                name = "Intrusion alarm - Partial arm",
                address = f.group_addresses."Partial arm",
                state_address = f.group_addresses."Partial arm status",
              },
              {
                name = "Intrusion alarm - Disarm",
                address = f.group_addresses.Disarm,
                state_address = f.group_addresses."Disarm status",
              },
            ]
          ),
      binary_sensor =
        select_flatten
          (name_is "Alarm")
          (fun f =>
            [
              {
                name = "Intrusion alarm",
                state_address = f.group_addresses."Intrusion alarm status",
              },
              {
                name = "Fire alarm",
                state_address = f.group_addresses."Fire alarm status",
              },
              {
                name = "Panic alarm",
                state_address = f.group_addresses."Panic alarm status",
              },
            ]
          ),
    },

    # UPS
    {
      binary_sensor =
        select_flatten
          (name_is "UPS")
          (fun f =>
            [
              {
                name = "UPS battery",
                state_address = f.group_addresses."UPS battery status",
              },
              {
                name = "UPS alarm",
                state_address = f.group_addresses."UPS alarm status",
              },
            ]
          ),
    },

    # Motion detection
    {
      binary_sensor =
        select
          (name_matches_word "motion detection")
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
          (name_matches_word "water leak detection")
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
          (name_matches_word "Ventilation")
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
          (and (location_is "Garage") (name_is "Door"))
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
          (and (location_is "Garage") (name_is "Gate"))
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
          (name_is "Weather")
          (fun f =>
            {
              name = "Weather station",
              address_temperature = f.group_addresses.Temp,
              address_wind_speed = f.group_addresses.Wind,
              address_rain_alarm = f.group_addresses.Rain,
            }
          ),
    },
  ]
