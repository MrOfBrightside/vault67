.PHONY: test test-vault67 test-farm33

test:
	@bash tests/run_tests.sh

test-vault67:
	@bats tests/vault67/

test-farm33:
	@bats tests/farm33/
