#
# Copyright © 2017 Samuel Holland <samuel@sholland.org>
# See LICENSE in the project directory for license terms.
#

CROSS_aarch64	 = aarch64-linux-musl-
CROSS_arm	 = arm-linux-musleabi-
CROSS_or1k	 = or1k-linux-musl-

BLOB		?= */*
BLOBS		 = $(sort $(wildcard $(BLOB)/blob.hex))
CHECKS		 = $(addsuffix .checked,$(DIRS))
COMMENTS	 = $(addsuffix comments,$(DIRS))
DIRS		 = $(dir $(BLOBS))
OUTPUT		 = $(foreach d,$(DIRS),$(d)annotated.s $(d)blob.s $(d)callgraph.svg)
SECTIONS	 = $(addsuffix sections,$(DIRS))
SYMBOLS		 = $(addsuffix symbols,$(DIRS))

arch		 = $(if $(findstring arisc,$(lastword $(1:/= ))),or1k,arm)
cross_compile	 = $(CROSS_$(call arch,$(1)))
env		 = env ARCH=$(call arch,$(1)) CROSS_COMPILE=$(call cross_compile,$(1))

M := @printf '  %-7s %s\n'
Q := @
ifneq ($(V),)
M := @\#
Q :=
endif

all: $(OUTPUT)

check: $(CHECKS)

clean:
	$(M) CLEAN "$(BLOB)"
	$(Q) rm -f $(BLOB)/.checked $(BLOB)/annotated.s $(BLOB)/blob.bin $(BLOB)/blob.elf $(BLOB)/blob.s
	$(Q) rm -f $(BLOB)/callgraph.dot $(BLOB)/callgraph.svg

save: $(COMMENTS)

%/.checked: %/sections %/symbols
	$(M) CHECK $*
	$(Q) sort -cu $*/sections
	$(Q) test -z "$$(uniq -df1 $*/sections)" || \
		(echo "error: Consecutive sections of the same type!"; false)
	$(Q) sort -cu $*/symbols
	$(Q) test -z "$$(sort -k2 $*/symbols | grep -Fv '$$' | uniq -df1)" || \
		(echo "error: Duplicate symbol name!"; false)

%/annotated.s: %/blob.s %/comments
	$(M) PASTE $@
	$(Q) paste $^ > $@.tmp && expand -t88,90 $@.tmp > $@
	$(Q) rm -f $@.tmp

%/blob.bin: %/blob.hex
	$(M) XXD $@
	$(Q) xxd -r $^ $@

%/blob.elf: %/blob.bin %/sections %/symbols
	$(M) BIN2ELF $@
	$(Q) $(call env,$*) scripts/bin2elf $^ $@

%/blob.s: %/blob.elf
	$(M) OBJDUMP $@
	$(Q) $(call cross_compile,$*)objdump -d $^ | expand -t11,12 > $@.tmp \
		&& cut -c-86 $@.tmp > $@
	$(Q) rm -f $@.tmp

%/callgraph.dot: %/blob.s
	$(M) CGRAPH $@
	$(Q) $(call env,$*) scripts/callgraph $^ $@

%/callgraph.svg: %/callgraph.dot
	$(M) DOT $@
	$(Q) dot -T svg $^ > $@

%/comments: %
	$(M) SAVE $@
	$(Q) { test $*/annotated.s -nt $@ && cut -c89- $*/annotated.s > $@; } || touch $@

.PHONY: all check clean save
.SECONDARY:
.SUFFIXES:
