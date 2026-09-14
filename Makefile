NCL_FILES := $(shell find . -name '*.yaml.ncl')
YAML_FILES := $(NCL_FILES:.yaml.ncl=.yaml)
DASHBOARD_YAML_FILES := $(filter ./dashboards/%.yaml,$(YAML_FILES))
PACKAGE_YAML_FILES := $(filter ./packages/%.yaml,$(YAML_FILES))

all: $(YAML_FILES)

%.yaml: %.yaml.ncl lib.ncl
	nickel export -fyaml -o $@ $<
	@# Workaround Norway problem. See https://github.com/nickel-lang/nickel/issues/2481
	@sed -i -E 's/: ([Oo]n|[Oo]ff)$$/: "\1"/g' $@

%.yaml: %.yaml.py
	python3 $< -o $@

knx-model.yaml: 0.xml

knx.yaml: knx-model.yaml

$(DASHBOARD_YAML_FILES): knx.yaml

$(PACKAGE_YAML_FILES): knx.yaml
