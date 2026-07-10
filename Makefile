NCL_FILES := $(shell find . -name '*.yaml.ncl')
YAML_FILES := $(NCL_FILES:.yaml.ncl=.yaml)
DASHBOARD_YAML_FILES := $(filter ./dashboards/%.yaml,$(YAML_FILES))
PACKAGE_YAML_FILES := $(filter ./packages/%.yaml,$(YAML_FILES))

all: $(YAML_FILES)

%.yaml: %.yaml.ncl
	nickel export -fyaml -o $@ $<

%.yaml: %.yaml.py
	python3 $< -o $@

knx-model.yaml: 0.xml

# Sometimes JSON is a safer serialization format, to avoid the Norway
# problem of YAML.
knx.yaml: knx.yaml.ncl knx-model.yaml
	nickel export -fjson -o $@ $<

$(DASHBOARD_YAML_FILES): knx.yaml

$(PACKAGE_YAML_FILES): knx.yaml
