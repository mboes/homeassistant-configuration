#!/usr/bin/env python3
"""Build an idealized YAML model of the functions in an ETS project.

Input is the 0.xml extracted from a .knxproj archive. Output is a flat YAML
model with two lists:

  functions  - every ETS function: "name", "type" (a descriptive type name such
               as "switchable light" or "sun protection"), "location" (the name
               of the nearest enclosing space, or null), and its group-address
               {name: address} map.
  locations  - every room, floor, and building: "name", "type" (room/floor/
               building), and "location" (the name of its parent space, or null).

Room, floor, and building names are assumed disjoint, so a bare "location" name
unambiguously identifies one entry in the locations list.

Naming rules carried over: a space named exactly "000" (and everything under it)
is dropped; a leading single digit and space is stripped from space names
("0 Ground Floor" -> "Ground Floor"); functions named "All ..." are included by
default but can be dropped with --exclude-all.
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET

import yaml

IGNORED_SPACE_NAME = "000"
EXCLUDED_NAME_PREFIX = "All "

# ETS space Type -> location type recorded in the model. Only these space types
# become locations; others (BuildingPart, Corridor, ...) are passed through.
SPACE_TYPES = {"Building": "building", "Floor": "floor", "Room": "room"}

# ETS function type code -> descriptive type name. Extend as needed; unmapped
# codes pass through unchanged so they stay visible in the output.
FUNCTION_TYPE_NAMES = {
    "FT-0": "custom",
    "FT-1": "switchable light",
    "FT-6": "dimmable light",
    "FT-7": "sun protection",
    "FT-8": "heating (switching variable)",
    "FT-9": "heating (continuous variable)",
    "FT-10": "switchable socket",
}


def type_name(function_type: str) -> str:
    return FUNCTION_TYPE_NAMES.get(function_type, function_type)


def local(tag: str) -> str:
    """Strip the XML namespace from a tag, e.g. '{...}Function' -> 'Function'."""
    return tag.rsplit("}", 1)[-1]


def iter_elements(root: ET.Element, name: str):
    """Yield every element whose local tag name matches, at any depth."""
    for el in root.iter():
        if local(el.tag) == name:
            yield el


def format_address(raw: int) -> str:
    """Format a raw integer group address as three-level main/middle/sub."""
    return f"{raw >> 11}/{(raw >> 8) & 0x7}/{raw & 0xFF}"


def clean_name(name: str) -> str:
    """Strip a leading single digit followed by a space, e.g. "0 Hall" -> "Hall"."""
    return re.sub(r"^\d\s+", "", name)


def collect_group_addresses(root: ET.Element) -> dict[str, tuple[str, str]]:
    """Map each GroupAddress Id to its (name, formatted address)."""
    result: dict[str, tuple[str, str]] = {}
    for ga in iter_elements(root, "GroupAddress"):
        ga_id = ga.get("Id")
        raw = ga.get("Address")
        if ga_id is None or raw is None:
            continue
        result[ga_id] = (ga.get("Name", ""), format_address(int(raw)))
    return result


def function_item(function: ET.Element, gas: dict[str, tuple[str, str]],
                  location: str | None) -> dict:
    """Represent one ETS function: name, HA type, location, address map."""
    name = (function.get("Name") or "").strip()
    name = re.sub(r"\s*\(legacy\)$", "", name)
    addresses: dict[str, str] = {}
    for ref in iter_elements(function, "GroupAddressRef"):
        resolved = gas.get(ref.get("RefId", ""))
        if resolved is None:
            continue
        ga_name, address = resolved
        addresses[ga_name or ref.get("RefId", "(unnamed)")] = address
    return {
        "name": name,
        "type": type_name(function.get("Type", "")),
        "location": location,
        "group_addresses": addresses,
    }


def walk(space: ET.Element, gas: dict[str, tuple[str, str]], model: dict,
         location: str | None, exclude_all: bool) -> None:
    """Recurse the tree, recording locations and functions under their parent."""
    raw_name = (space.get("Name") or "").strip()
    if raw_name == IGNORED_SPACE_NAME:
        return  # drop this space and everything under it

    child_location = location
    space_type = SPACE_TYPES.get(space.get("Type"))
    if space_type is not None:
        name = clean_name(raw_name)
        model["locations"].append(
            {"name": name, "type": space_type, "location": location})
        child_location = name

    for child in space:
        tag = local(child.tag)
        if tag == "Space":
            walk(child, gas, model, child_location, exclude_all)
        elif tag == "Function":
            fname = (child.get("Name") or "").strip()
            if exclude_all and fname.startswith(EXCLUDED_NAME_PREFIX):
                continue
            model["functions"].append(function_item(child, gas, child_location))


def build_model(root: ET.Element, exclude_all: bool) -> dict:
    """Walk the building structure and return the {functions, locations} model."""
    gas = collect_group_addresses(root)
    model: dict = {"functions": [], "locations": []}  # key order = output order
    # The building tree lives under <Locations>; walk its top-level spaces.
    for locations in iter_elements(root, "Locations"):
        for space in locations:
            if local(space.tag) == "Space":
                walk(space, gas, model, None, exclude_all)
    return model


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="path to the ETS 0.xml file")
    parser.add_argument("-o", "--output", default="ets_model.yaml",
                        help="output YAML file (default: ets_model.yaml)")
    parser.add_argument("--exclude-all", action="store_true",
                        help='drop functions whose name starts with "All " '
                             "(included by default)")
    args = parser.parse_args()

    root = ET.parse(args.input).getroot()
    model = build_model(root, args.exclude_all)

    with open(args.output, "w", encoding="utf-8") as fh:
        yaml.dump(model, fh, sort_keys=False, allow_unicode=True,
                  default_flow_style=False, width=1000)

    print(f"Functions: {len(model['functions'])}  "
          f"Locations: {len(model['locations'])}  Output: {args.output}",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
