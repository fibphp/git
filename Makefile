all::

# Define V=1 to have a more verbose compile.
#
# Define NO_MSGFMT if you do not have msgfmt from the GNU gettext
# package and want to use our rough pure Tcl po->msg translator.
# TCL_PATH must be vaild for this to work.
#

GIT-VERSION-FILE: .FORCE-GIT-VERSION-FILE
	@$(SHELL_PATH) ./GIT-VERSION-GEN
-include GIT-VERSION-FILE

uname_O := $(shell sh -c 'uname -o 2>/dev/null || echo not')

SCRIPT_SH = git-gui.sh
GITGUI_BUILT_INS = git-citool
ALL_PROGRAMS = $(GITGUI_BUILT_INS) $(patsubst %.sh,%,$(SCRIPT_SH))
ALL_LIBFILES = $(wildcard lib/*.tcl)
PRELOAD_FILES = lib/class.tcl

ifndef SHELL_PATH
	SHELL_PATH = /bin/sh
endif

ifndef gitexecdir
	gitexecdir := $(shell git --exec-path)
endif

ifndef sharedir
	sharedir := $(dir $(gitexecdir))share
endif

ifndef INSTALL
	INSTALL = install
endif

RM_F      ?= rm -f
RMDIR     ?= rmdir

INSTALL_D0 = $(INSTALL) -d -m755 # space is required here
INSTALL_D1 =
INSTALL_R0 = $(INSTALL) -m644 # space is required here
INSTALL_R1 =
INSTALL_X0 = $(INSTALL) -m755 # space is required here
INSTALL_X1 =
INSTALL_L0 = rm -f # space is required here
INSTALL_L1 = && ln # space is required here
INSTALL_L2 =
INSTALL_L3 =

REMOVE_D0  = $(RMDIR) # space is required here
REMOVE_D1  = || true
REMOVE_F0  = $(RM_F) # space is required here
REMOVE_F1  =
CLEAN_DST  = true

ifndef V
	QUIET          = @
	QUIET_GEN      = $(QUIET)echo '   ' GEN $@ &&
	QUIET_BUILT_IN = $(QUIET)echo '   ' BUILTIN $@ &&
	QUIET_INDEX    = $(QUIET)echo '   ' INDEX $(dir $@) &&
	QUIET_MSGFMT0  = $(QUIET)printf '    MSGFMT %12s ' $@ && v=`
	QUIET_MSGFMT1  = 2>&1` && echo "$$v" | sed -e 's/fuzzy translations/fuzzy/' | sed -e 's/ messages//g'
	QUIET_2DEVNULL = 2>/dev/null

	INSTALL_D0 = dir=
	INSTALL_D1 = && echo ' ' DEST $$dir && $(INSTALL) -d -m755 "$$dir"
	INSTALL_R0 = src=
	INSTALL_R1 = && echo '   ' INSTALL 644 `basename $$src` && $(INSTALL) -m644 $$src
	INSTALL_X0 = src=
	INSTALL_X1 = && echo '   ' INSTALL 755 `basename $$src` && $(INSTALL) -m755 $$src

	INSTALL_L0 = dst=
	INSTALL_L1 = && src=
	INSTALL_L2 = && dst=
	INSTALL_L3 = && echo '   ' 'LINK       ' `basename "$$dst"` '->' `basename "$$src"` && rm -f "$$dst" && ln "$$src" "$$dst"

	CLEAN_DST = echo ' ' UNINSTALL
	REMOVE_D0 = dir=
	REMOVE_D1 = && echo ' ' REMOVE $$dir && test -d "$$dir" && $(RMDIR) "$$dir" || true
	REMOVE_F0 = dst=
	REMOVE_F1 = && echo '   ' REMOVE `basename "$$dst"` && $(RM_F) "$$dst"
endif

TCL_PATH   ?= tclsh
TCLTK_PATH ?= wish

ifeq ($(findstring $(MAKEFLAGS),s),s)
QUIET_GEN =
QUIET_BUILT_IN =
endif

DESTDIR_SQ = $(subst ','\'',$(DESTDIR))
gitexecdir_SQ = $(subst ','\'',$(gitexecdir))
SHELL_PATH_SQ = $(subst ','\'',$(SHELL_PATH))
TCL_PATH_SQ = $(subst ','\'',$(TCL_PATH))
TCLTK_PATH_SQ = $(subst ','\'',$(TCLTK_PATH))
TCLTK_PATH_SED = $(subst ','\'',$(subst \,\\,$(TCLTK_PATH)))

gg_libdir ?= $(sharedir)/git-gui/lib
libdir_SQ  = $(subst ','\'',$(gg_libdir))
libdir_SED = $(subst ','\'',$(subst \,\\,$(gg_libdir)))
exedir     = $(dir $(gitexecdir))share/git-gui/lib

GITGUI_SCRIPT   := $$0
GITGUI_RELATIVE :=

ifeq ($(exedir),$(gg_libdir))
	GITGUI_RELATIVE := 1
endif

ifeq ($(uname_O),Cygwin)
	GITGUI_SCRIPT := `cygpath --windows --absolute "$(GITGUI_SCRIPT)"`
	ifeq ($(GITGUI_RELATIVE),)
		gg_libdir := $(shell cygpath --windows --absolute "$(gg_libdir)")
	endif
endif

$(patsubst %.sh,%,$(SCRIPT_SH)) : % : %.sh
	$(QUIET_GEN)rm -f $@ $@+ && \
	sed -e '1s|#!.*/sh|#!$(SHELL_PATH_SQ)|' \
		-e '1,30s|^ argv0=$$0| argv0=$(GITGUI_SCRIPT)|' \
		-e '1,30s|^ exec wish | exec '\''$(TCLTK_PATH_SED)'\'' |' \
		-e 's/@@GITGUI_VERSION@@/$(GITGUI_VERSION)/g' \
		-e 's|@@GITGUI_RELATIVE@@|$(GITGUI_RELATIVE)|' \
		-e '$(GITGUI_RELATIVE)s|@@GITGUI_LIBDIR@@|$(libdir_SED)|' \
		$@.sh >$@+ && \
	chmod +x $@+ && \
	mv $@+ $@

$(GITGUI_BUILT_INS): git-gui
	$(QUIET_BUILT_IN)rm -f $@ && ln git-gui $@

XGETTEXT   ?= xgettext
ifdef NO_MSGFMT
	MSGFMT ?= $(TCL_PATH) po/po2msg.sh
else
	MSGFMT ?= msgfmt
endif

msgsdir     = $(gg_libdir)/msgs
msgsdir_SQ  = $(subst ','\'',$(msgsdir))
PO_TEMPLATE = po/git-gui.pot
ALL_POFILES = $(wildcard po/*.po)
ALL_MSGFILES = $(subst .po,.msg,$(ALL_POFILES))

$(PO_TEMPLATE): $(SCRIPT_SH) $(ALL_LIBFILES)
	$(XGETTEXT) -kmc -LTcl -o $@ $(SCRIPT_SH) $(ALL_LIBFILES)
update-po:: $(PO_TEMPLATE)
	$(foreach p, $(ALL_POFILES), echo Updating $p ; msgmerge -U $p $(PO_TEMPLATE) ; )
$(ALL_MSGFILES): %.msg : %.po
	$(QUIET_MSGFMT0)$(MSGFMT) --statistics --tcl $< -l $(basename $(notdir $<)) -d $(dir $@) $(QUIET_MSGFMT1)

lib/tclIndex: $(ALL_LIBFILES)
	$(QUIET_INDEX)if echo \
	  $(foreach p,$(PRELOAD_FILES),source $p\;) \
	  auto_mkindex lib '*.tcl' \
	| $(TCL_PATH) $(QUIET_2DEVNULL); then : ok; \
	else \
	 echo 1>&2 "    * $(TCL_PATH) failed; using unoptimized loading"; \
	 rm -f $@ ; \
	 echo '# Autogenerated by git-gui Makefile' >$@ && \
	 echo >>$@ && \
	 $(foreach p,$(PRELOAD_FILES) $(ALL_LIBFILES),echo '$(subst lib/,,$p)' >>$@ &&) \
	 echo >>$@ ; \
	fi

# These can record GITGUI_VERSION
$(patsubst %.sh,%,$(SCRIPT_SH)): GIT-VERSION-FILE GIT-GUI-VARS
lib/tclIndex: GIT-GUI-VARS

TRACK_VARS = \
	$(subst ','\'',SHELL_PATH='$(SHELL_PATH_SQ)') \
	$(subst ','\'',TCL_PATH='$(TCL_PATH_SQ)') \
	$(subst ','\'',TCLTK_PATH='$(TCLTK_PATH_SQ)') \
	$(subst ','\'',gitexecdir='$(gitexecdir_SQ)') \
	$(subst ','\'',gg_libdir='$(libdir_SQ)') \
#end TRACK_VARS

GIT-GUI-VARS: .FORCE-GIT-GUI-VARS
	@VARS='$(TRACK_VARS)'; \
	if test x"$$VARS" != x"`cat $@ 2>/dev/null`" ; then \
		echo 1>&2 "    * new locations or Tcl/Tk interpreter"; \
		echo 1>$@ "$$VARS"; \
	fi

all:: $(ALL_PROGRAMS) lib/tclIndex $(ALL_MSGFILES)

install: all
	$(QUIET)$(INSTALL_D0)'$(DESTDIR_SQ)$(gitexecdir_SQ)' $(INSTALL_D1)
	$(QUIET)$(INSTALL_X0)git-gui $(INSTALL_X1) '$(DESTDIR_SQ)$(gitexecdir_SQ)'
	$(QUIET)$(foreach p,$(GITGUI_BUILT_INS), $(INSTALL_L0)'$(DESTDIR_SQ)$(gitexecdir_SQ)/$p' $(INSTALL_L1)'$(DESTDIR_SQ)$(gitexecdir_SQ)/git-gui' $(INSTALL_L2)'$(DESTDIR_SQ)$(gitexecdir_SQ)/$p' $(INSTALL_L3) &&) true
	$(QUIET)$(INSTALL_D0)'$(DESTDIR_SQ)$(libdir_SQ)' $(INSTALL_D1)
	$(QUIET)$(INSTALL_R0)lib/tclIndex $(INSTALL_R1) '$(DESTDIR_SQ)$(libdir_SQ)'
	$(QUIET)$(INSTALL_R0)lib/git-gui.ico $(INSTALL_R1) '$(DESTDIR_SQ)$(libdir_SQ)'
	$(QUIET)$(foreach p,$(ALL_LIBFILES), $(INSTALL_R0)$p $(INSTALL_R1) '$(DESTDIR_SQ)$(libdir_SQ)' &&) true
	$(QUIET)$(INSTALL_D0)'$(DESTDIR_SQ)$(msgsdir_SQ)' $(INSTALL_D1)
	$(QUIET)$(foreach p,$(ALL_MSGFILES), $(INSTALL_R0)$p $(INSTALL_R1) '$(DESTDIR_SQ)$(msgsdir_SQ)' &&) true

uninstall:
	$(QUIET)$(CLEAN_DST) '$(DESTDIR_SQ)$(gitexecdir_SQ)'
	$(QUIET)$(REMOVE_F0)'$(DESTDIR_SQ)$(gitexecdir_SQ)'/git-gui $(REMOVE_F1)
	$(QUIET)$(foreach p,$(GITGUI_BUILT_INS), $(REMOVE_F0)'$(DESTDIR_SQ)$(gitexecdir_SQ)'/$p $(REMOVE_F1) &&) true
	$(QUIET)$(CLEAN_DST) '$(DESTDIR_SQ)$(libdir_SQ)'
	$(QUIET)$(REMOVE_F0)'$(DESTDIR_SQ)$(libdir_SQ)'/tclIndex $(REMOVE_F1)
	$(QUIET)$(REMOVE_F0)'$(DESTDIR_SQ)$(libdir_SQ)'/git-gui.ico $(REMOVE_F1)
	$(QUIET)$(foreach p,$(ALL_LIBFILES), $(REMOVE_F0)'$(DESTDIR_SQ)$(libdir_SQ)'/$(notdir $p) $(REMOVE_F1) &&) true
	$(QUIET)$(CLEAN_DST) '$(DESTDIR_SQ)$(msgsdir_SQ)'
	$(QUIET)$(foreach p,$(ALL_MSGFILES), $(REMOVE_F0)'$(DESTDIR_SQ)$(msgsdir_SQ)'/$(notdir $p) $(REMOVE_F1) &&) true
	$(QUIET)$(REMOVE_D0)'$(DESTDIR_SQ)$(gitexecdir_SQ)' $(REMOVE_D1)
	$(QUIET)$(REMOVE_D0)'$(DESTDIR_SQ)$(msgsdir_SQ)' $(REMOVE_D1)
	$(QUIET)$(REMOVE_D0)'$(DESTDIR_SQ)$(libdir_SQ)' $(REMOVE_D1)
	$(QUIET)$(REMOVE_D0)`dirname '$(DESTDIR_SQ)$(libdir_SQ)'` $(REMOVE_D1)

dist-version:
	@mkdir -p $(TARDIR)
	@echo $(GITGUI_VERSION) > $(TARDIR)/version

clean::
	rm -f $(ALL_PROGRAMS) lib/tclIndex po/*.msg
	rm -f GIT-VERSION-FILE GIT-GUI-VARS

.PHONY: all install uninstall dist-version clean
.PHONY: .FORCE-GIT-VERSION-FILE
.PHONY: .FORCE-GIT-GUI-VARS
