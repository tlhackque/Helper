# Copyright (c) 2025-2026 Timothe LItt

DOC := docs

module := Helper.pm

MKDIR := mkdir
CHMOD := chmod
CHOWN := chown
RM    := rm

PERLDOC      := /usr/bin/perldoc
PODCHECKER   := /usr/bin/podchecker
POD2PDF      := /usr/bin/pod2pdf
POD2HTML     := /usr/bin/pod2html
POD2MARKDOWN := /usr/bin/pod2markdown
POD2TEXT     := /usr/bin/pod2text

SED   := /usr/bin/sed
SHELL := /bin/bash
TIDY  := perltidy -b

owner    := litt:litt
rdperms  := u=r,g=r,o=
rwperms  := u=rw,g=r,o=
xctperms := u=rwx,g=rx,o=
dirperms := u=rwx,g=rwx,o=x

.PHONY : all

all : README.md LICENSE

README.md : $(module) Makefile
	$(PODCHECKER) $<
	$(POD2MARKDOWN) $< | $(SED) -e '/^# COPYRIGHT and LICENSE/,$$d' >$@ && \
	$(CHOWN) $(owner) $@ && $(CHMOD) $(rdperms) $@

LICENSE : $(module) Makefile
	$(PERLDOC) -F $< | $(SED) -ne '/^SEE ALSO/,$$d' \
	-e '/^COPYRIGHT and LICENSE/,$$p' >$@ && \
	$(CHOWN) $(owner) $@ && $(CHMOD) $(rdperms) $@

$(DOC): 	Makefile \
	$(addprefix $(DOC)/,$(addsuffix .pdf,$(basename $(module)))) \
	$(addprefix $(DOC)/,$(addsuffix .txt,$(basename $(module)))) \
	$(addprefix $(DOC)/,$(addsuffix .html,$(basename $(module))))

$(DOC)/%.pdf : %.pm
	$(PODCHECKER) $<
	$(MKDIR) -pv $(dir $@) && $(CHOWN) $(owner) $(dir $@) && \
	$(CHMOD) $(dirperms) $(dir $@)
	$(POD2PDF) $< --timestamp --header --output=$@ && \
	$(CHOWN) $(owner) $@ && $(CHMOD) $(rdperms) $@

$(DOC)/%.txt : %.pm
	$(PODCHECKER) $<
	$(MKDIR) -pv $(dir $@) && $(CHOWN) $(owner) $(dir $@) && \
	$(CHMOD) $(dirperms) $(dir $@)
	$(POD2TEXT) $< $@ && $(CHOWN) $(owner) $@ && $(CHMOD) $(rdperms) $@

$(DOC)/%.html : %.pm
	$(PODCHECKER) $<
	$(MKDIR) -pv $(dir $@) && $(CHOWN) $(owner) $(dir $@) && \
	$(CHMOD) $(dirperms) $(dir $@)
	$(eval t = $<.title) $(POD2HTML) $< --backlink --header \
	--title="$(file < $(t))" --outfile=$@ \
	 && $(CHOWN) $(owner) $@ && $(CHMOD) $(rdperms) $@
	@$(RM) -f pod2htmd.tmp || true

.PHONY : tidy

tidy :
	$(TIDY) $(module)
