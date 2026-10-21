# Describe KNX functions and their locations
#
# Dashboards group entities by room and by floor using the metadata
# found in this KNX model.

let Nullable = fun Contract =>
  std.contract.custom (fun label value =>
    if value == null then
      'Ok value
    else
      std.contract.check Contract label value
  )
in
let LocationType = [| 'building, 'floor, 'room, 'stairway |] in
let Location = {
  name | String,
  type | std.enum.TagOrString | LocationType,
  location | Nullable String,
}
in
let FunctionType = [|
  '"custom",
  '"dimmable light",
  '"switchable light",
  '"sun protection",
  '"heating (switching variable)",
  '"heating (continuous variable)",
  '"switchable socket",
|]
in
let Function = {
  name | String,
  type | std.enum.TagOrString | FunctionType,
  location | String,
  group_addresses | { _ : String },
}
in

let schema = {
  functions | Array Function,
  locations | Array Location,
}
in

let cfg = import "knx.yaml"
in

cfg & schema
