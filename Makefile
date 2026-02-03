#!/usr/bin/make

.SUFFIXES:
.SUFFIXES: .html .md .pdf

PROJECT:= README
PANDOC := pandoc

default: $(PROJECT).html $(PROJECT).pdf

.md.html:
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--embed-resources --standalone --css files/article.css \
		--output public/$@ \
		$<
	@mv public/$@ public/index.html

.md.pdf:
	@mkdir -p public
	@$(PANDOC) \
		--include-in-header files/preamble.tex \
		--from=markdown --pdf-engine=xelatex \
		--css article.css \
		--toc \
		--output public/$@ \
		$<

.PHONY: update-date
update-date:
	sed -i "s/^date: .*/date: $(shell date +%Y-%m-%d)/" README.md

.PHONY: clean
clean:
	@$(RM) -rf public
