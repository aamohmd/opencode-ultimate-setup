.PHONY: install uninstall help

help:
	@echo "Available commands:"
	@echo "  make install    - Run the setup script to install the opencode Ultimate Stack"
	@echo "  make uninstall  - Run the teardown script to remove the stack"

install:
	@chmod +x setup.sh
	@./setup.sh

uninstall:
	@chmod +x uninstall.sh
	@./uninstall.sh
