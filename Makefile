PLENARY ?= $(shell nvim --headless -u NONE -c "lua print(vim.fn.stdpath('data'))" -c q 2>&1 | tail -1)/lazy/plenary.nvim

.PHONY: test lint fmt

test:
	PLENARY_PATH="$(PLENARY)" nvim \
		--headless \
		--noplugin \
		-u tests/minimal_init.lua \
		-c "lua require('plenary.test_harness').test_directory('tests/spec', { minimal_init = 'tests/minimal_init.lua' })" \
		-c q

lint:
	luacheck lua/ tests/spec/ --globals vim describe it before_each assert

fmt:
	stylua lua/ tests/spec/
