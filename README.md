# Home Assistant configuration

Content of my [Home Assistant][ha] `/config/` folder.
Notable features:

- **Scrap your YAML boilerplate:** I use the [Nickel][] configuration
  language to generate most of the YAML for the integrations and
  dashboards. I don't write repetitive YAML by hand and...
- **Your home is your private space:** ...I don't hand over the floor
  plans and electrical plans of my home to agents for them to hammer
  out the boilerplate. I define abstractions in Nickel and instantiate
  them many times. Agents can do so as well, again without being given
  any knowledge of your house.
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

A convenient method to deploy to Home Assistant is to check in the
YAML generated artefacts together with the code in this repository,
and to use Git to pull any new changes to the configuration. The
content of `/config` in Home Assistant is then a checkout of this
repository.

## Project structure

*Models* are the ground truth describing the world, or distillations
thereof. As much of the Home Assistant configuration as possible is
derived from these models. Our biggest model is the KNX model, itself
derived from the `0.xml` extracted from [ETS6][knx-ets] `.knxproj`
exports.

*Integrations* define entities, using models as inputs.

*Packages* define templates, automations and other helpers atop the
entities defined by the integrations.

*Dashboards* present entities defined in integrations and packages.

Integrations in Nickel can provide ancillary entity metadata to
downstream consumers (packages and dashboards) that is not serialized
to YAML.

## The build system

Home Assistant only understands YAML files. There are `Makefile` rules
to generate these YAML files from their corresponding `*.yaml.ncl`
([Nickel][] expression) or `*.yaml.py` ([Python][] script), when they
exist.

[ha]: https://www.home-assistant.io/
[ha-areas]: https://www.home-assistant.io/getting-started/concepts-terminology/#areas
[ha-knx]: https://www.home-assistant.io/integrations/knx
[ha-modbus]: https://www.home-assistant.io/integrations/modbus
[knx-ets]: https://www.knx.org/what-is-ets
[nickel]: https://nickel-lang.org/
[python]: https://www.python.org/
