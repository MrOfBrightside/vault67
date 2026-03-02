.PHONY: test test-vault67 test-farm33 lint lint-vault67 lint-farm33

test:
	@bash tests/run_tests.sh

test-vault67:
	@bats tests/vault67/

test-farm33:
	@bats tests/farm33/

lint:
	@echo "Linting vault67..."
	@shellcheck -s bash -S warning vault67/vault67/lib/helpers.bash
	@shellcheck -s bash -S warning -e SC2034,SC2001,SC1090,SC1091,SC2012,SC2016 vault67/vault67/vault67
	@echo "Linting farm33..."
	@shellcheck -s bash -S warning farm33/lib/helpers.bash
	@shellcheck -s bash -S warning -e SC2034,SC2001,SC1091 farm33/farm33
	@echo "Linting lib/common.bash..."
	@shellcheck -s bash -S warning lib/common.bash
	@echo "All lint checks passed."

lint-vault67:
	@shellcheck -s bash -S warning vault67/vault67/lib/helpers.bash
	@shellcheck -s bash -S warning -e SC2034,SC2001,SC1090,SC1091,SC2012,SC2016 vault67/vault67/vault67

lint-farm33:
	@shellcheck -s bash -S warning farm33/lib/helpers.bash
	@shellcheck -s bash -S warning -e SC2034,SC2001,SC1091 farm33/farm33
