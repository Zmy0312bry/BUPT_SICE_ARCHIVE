SCRIPT   = ./scripts/process_pi.sh
TEXFILE  = pi_book.tex
BUILDDIR = ./build
XELATEX  = xelatex -interaction=nonstopmode -output-directory=$(BUILDDIR)

.PHONY: all data pdf clean

all: pdf

data:
	@bash $(SCRIPT)

pdf: data
	@echo "=== XeLaTeX pass 1 ==="
	$(XELATEX) $(TEXFILE)
	@echo "=== XeLaTeX pass 2 ==="
	$(XELATEX) $(TEXFILE)
	@echo ""
	@echo "PDF generated: $(BUILDDIR)/pi_book.pdf"

clean:
	rm -rf $(BUILDDIR)
