# Home Assistant configuration

Content of my [Home Assistant][ha] `/config/` folder.
Notable features:

- **Scrap your YAML boilerplate:** I use the [Nickel][] configuration
  language to generate most of the YAML for the integrations and
  dashboards. I don't write repetitive YAML by hand and...
- **Your home is your private space:** ...I don't hand over the floor
  plans and electrical plans of my home to agents for them to hammer
  out the boilerplate. I define abstractions in Nickel and instantiate
  them many times. Agents can do so as well, again with no knowledge
  of your house.
- **Keep things modular:** related templates and automations are
  defined using the [packages][ha-packages] pattern of Home Assistant.
- **Code, don't click:** configure as much as possible using YAML or
  Nickel code in this repository, not by clicking through wizards in
  the UI, lest the state of Home Assistant become an unshareable black
  box. Code can be versioned, rolled back, and copy/pasted anywhere.
  This means eschewing UI-only features like [areas][ha-areas] in
  favour of naming conventions for entities.

## Showcased integrations

- **[KNX][ha-knx]:** I have dozens of devices on a KNX bus.
- **[Modbus][ha-modbus]:** for the ventilation unit.

## Usage

Generate YAML files to be copied to `/config/` in Home Assistant:

```
$ direnv allow    # Optionally, to pull in all required dependencies
$ make

```

For convenience deploying to Home Assistant, which doesn't have
a Nickel interpreter installed, the YAML is typically checked in
together with the code that generated it.

## Notable files

- **`configuration.yaml`:** The top-level Home Assistant configuration
  file.
- **`0.xml`:** For the KNX integration. Found inside unzipped
  [ETS6][knx-ets] `.knxproj` exports.
- **`knx-model.yaml`:** For the KNX integration. Distillation of
  `0.xml` in YAML form.
- **`knx.yaml`:** The configuration for the KNX integration of Home
  Assistant, derived from the KNX model.

`*.yaml.*` files are scripts that generate the corresponding `*.yaml`
file, usually in [Nickel][nickel] or in [Python][python].

[ha]: https://www.home-assistant.io/
[ha-areas]: https://www.home-assistant.io/getting-started/concepts-terminology/#areas
[ha-packages]: https://www.home-assistant.io/docs/configuration/packages/
[knx-ets]: https://www.knx.org/what-is-ets
[nickel]: https://nickel-lang.org/
[python]: https://www.python.org/
