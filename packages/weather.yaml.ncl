let knx = import "../knx.yaml.ncl" in
let lib = import "../lib.ncl" in
{
  template = {
    sensor = [
      {
        name = "//Outdoor temperature",
        state = "{{ state_attr('weather.weather_station', 'temperature') }}",
        availability = "{{ state_attr('weather.weather_station', 'temperature') is not none }}",
        unit_of_measurement = "°C",
        device_class = "temperature",
        state_class = "measurement",
      },
    ]
  }
}
