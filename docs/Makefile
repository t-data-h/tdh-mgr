# Makefile
#
ifeq (, $(shell which pandoc))
 $(error "Error, 'pandoc' not found in PATH.")
endif

sources:=$(wildcard *.md)
objects:=$(patsubst %.md,%.pdf,$(sources))

%.pdf: %.md
	pandoc -s -V geometry:margin=1in \
		-f markdown-implicit_figures $< -o $@
		#--table-of-contents

all: pdf

docs: pdf 
pdf: $(objects)

clean:
	( rm -rf *.pdf )
