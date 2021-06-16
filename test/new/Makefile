MYVIM ?= nvim --headless
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test $(TESTS)

test: $(TESTS)

sysinfo:
	@echo "**** SYSTEM INFORMATION ****"
	@-git log -1
	@-$(MYVIM) --version
	@echo "**** SYSTEM INFORMATION ****"

$(TESTS):
	$(MAKE) -C $@

coverage: htmlcov/index.html

htmlcov/index.html: env /tmp/vim-profile.txt
	. env/bin/activate
	covimerage write_coverage /tmp/vim-profile.txt --source ../../autoload --source ../../plugin
	coverage report -m
	coverage html

env: env/pyvenv.cfg

env/pyvenv.cfg:
	python3 -m venv env
	. env/bin/activate;
	pip install setuptools wheel
	pip install "click<8.0.0" covimerage
