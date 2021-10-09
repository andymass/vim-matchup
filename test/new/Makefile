RANDOM := $(shell bash -c 'echo $$RANDOM')
COVER = covimerage -q run --append --no-report \
       --data-file $(CURDIR)/cov.tmp/_$(RANDOM)_coverage_covimerage_$@ \
       --source $(CURDIR)/../../autoload \
       --source $(CURDIR)/../../plugin
MYVIM ?= nvim --headless
MAKEFLAGS += --no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS): env
	@. env/bin/activate
	mkdir -p cov.tmp
	MYVIM="$(COVER) $(MYVIM)" $(MAKE) -C $@

coverage: coverage.xml

cov.tmp/coverage_covimerage: $(wildcard cov.tmp/_*)
	coverage combine $^

coverage.xml: env cov.tmp/coverage_covimerage
	. env/bin/activate
	coverage report -m
	coverage html
	coverage xml

env: env/pyvenv.cfg

env/pyvenv.cfg:
	python3 -m venv env
	. env/bin/activate
	pip install -r requirements.txt

ifndef MAKECMDGOALS
test: sysinfo
$(TESTS): sysinfo
endif
