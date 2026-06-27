FORTUNE_DIR ?= /opt/homebrew/Cellar/fortune/9708/share/games/fortunes/
BUILD_DIR   := build
GENERATE_ARGS ?= '-a'


.PHONY: all clean link help

all: $(BUILD_DIR)
	./generate.sh $(GENERATE_ARGS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

link:
	@for f in $(BUILD_DIR)/*; do \
		if [ -f "$$f" ]; then \
			base=$$(basename "$$f"); \
			target="$(FORTUNE_DIR)$$base"; \
			ln -sf "$(CURDIR)/$$f" "$$target"; \
			echo "  LINK    $$base"; \
		fi; \
	done

help:
	@echo "Available targets:"
	@echo "  all     Generate fortune data (default)"
	@echo "  clean   Remove build directory"
	@echo "  link    Symlink build files to fortune data directory"
	@echo "  help    Show this help message"
