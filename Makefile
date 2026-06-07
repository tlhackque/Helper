# Copyright (c) 2025-2026 Timothe LItt

module := Helper.pm
PERLDOC :=    /usr/bin/perldoc
PODCHECKER   := /usr/bin/podchecker
POD2PDF      :=    /usr/bin/pod2pdf
POD2HTML     :=    /usr/bin/pod2html
POD2MARKDOWN := /usr/bin/pod2markdown
POD2TEXT     :=   /usr/bin/pod2text

SED   := /usr/bin/sed
SHELL := /bin/bash
TIDY  := perltidy -b

.PHONY : all

all : README.md LICENSE

README.md : $(module) Makefile
	$(POD2MARKDOWN) $< | $(SED) -e '/^# COPYRIGHT and LICENSE/,$$d' >$@

LICENSE : $(module) Makefile
	$(PERLDOC) -F $< | $(SED) -ne '/^COPYRIGHT and LICENSE/,$$p' > $@

docs: 	Makefile \
	$(addprefix docs/,$(addsuffix .pdf,$(basename $(module)))) \
	$(addprefix docs/,$(addsuffix .txt,$(basename $(module)))) \
	$(addprefix docs/,$(addsuffix .html,$(basename $(module))))

docs/%.pdf : %.pm
	mkdir -pv docs
	$(PODCHECKER) $<
	$(POD2PDF) $< --timestamp --header --output=$@

docs/%.txt : %.pm
	mkdir -pv docs
	$(PODCHECKER) $<
	$(POD2TEXT) $< $@

docs/%.html : %.pm
	mkdir -pv docs
	$(PODCHECKER) $<
	$(eval t = $<.title) $(POD2HTML) $< --backlink --header --title="$(file < $(t))" --outfile=$@
	@rm -f pod2htmd.tmp || true

.PHONY : tidy

tidy :
	$(TIDY) $(module)
