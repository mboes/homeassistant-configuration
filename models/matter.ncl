# Describe Matter devices
#
# The Matter integration doesn't support declarative configuration in
# YAML. The list below is hardcoded and must be kept in sync with
# the UI.
let schema = {
  lock_button_devices | Array { device | String, location | String },
}
in

let cfg = import "matter.yaml"
in

cfg & schema
