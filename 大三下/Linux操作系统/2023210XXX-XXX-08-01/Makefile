MAIN      = main
SRC       = $(MAIN).tex
PDF       = $(MAIN).pdf
LATEXMK   = latexmk
LATEXMKFLAGS = -xelatex -shell-escape -interaction=nonstopmode -auxdir=build

CHAPTERS  = chapters/gains.tex \
            chapters/reflections.tex \
            chapters/suggestions.tex

BUILD_DIR = build
HASH_TEX  = $(BUILD_DIR)/hash.tex
SOURCES   = $(SRC) $(CHAPTERS)

.PHONY: all clean distclean view

all: $(PDF)

$(HASH_TEX): $(SOURCES) Makefile
	@mkdir -p $(BUILD_DIR)
	@printf '\\newcommand{\\sourcehash}{%s}\n' $$(cat $(SOURCES) | shasum -a 256 | cut -d' ' -f1) > $(HASH_TEX)

$(PDF): $(SOURCES) $(HASH_TEX) Makefile
	TEXINPUTS=.:chapters:$$TEXINPUTS $(LATEXMK) $(LATEXMKFLAGS) $(SRC)

clean:
	@$(LATEXMK) -C -auxdir=$(BUILD_DIR) 2>/dev/null || true
	@rm -rf $(BUILD_DIR) _minted-$(MAIN)

distclean: clean
	@rm -f $(PDF)
