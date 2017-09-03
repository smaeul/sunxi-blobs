#
# Copyright © 2017 Samuel Holland <samuel@sholland.org>
# See LICENSE in the project directory for license terms.
#

BOARD		 = sun50iw1p1
CROSS_COMPILE	 = or1k-linux-musl-

M := @printf '  %-7s %s\n'
Q := @
ifneq ($(V),)
M := @\#
Q :=
endif

all: $(BOARD)/arisc.elf $(BOARD)/arisc.s $(BOARD)/callgraph.svg
	$(M) DONE

check:
	$(M) CHECK "$(BOARD)/sections (addresses)"
	$(Q) sort -cu $(BOARD)/sections
	$(M) CHECK "$(BOARD)/sections (types)"
	$(Q) test -z "$$(uniq -df1 $(BOARD)/sections)" || \
		(echo "error: Consecutive sections of the same type!"; false)
	$(M) CHECK "$(BOARD)/symbols (addresses)"
	$(Q) sort -cu $(BOARD)/symbols
	$(M) CHECK "$(BOARD)/symbols (names)"
	$(Q) test -z "$$(sort -k2 $(BOARD)/symbols | uniq -df1)" || \
		(echo "error: Duplicate symbol name!"; false)

clean:
	$(M) CLEAN $(BOARD)
	$(Q) rm -f $(BOARD)/arisc.bin $(BOARD)/arisc.elf $(BOARD)/arisc.s
	$(Q) rm -f $(BOARD)/callgraph.gv $(BOARD)/callgraph.svg

$(BOARD)/arisc.bin: $(BOARD)/arisc.hex
	$(M) XXD $@
	$(Q) xxd -r $^ $@

$(BOARD)/arisc.elf: $(BOARD)/arisc.bin $(BOARD)/sections $(BOARD)/symbols
	$(M) BIN2ELF $@
	$(Q) scripts/bin2elf $^ $@

$(BOARD)/arisc.s: $(BOARD)/arisc.elf
	$(M) OBJDUMP $@
	$(Q) $(CROSS_COMPILE)objdump -d $^ > $@

$(BOARD)/callgraph.gv: $(BOARD)/arisc.s
	$(M) CGRAPH $@
	$(Q) scripts/callgraph $^ $@

$(BOARD)/callgraph.svg: $(BOARD)/callgraph.gv
	$(M) DOT $@
	$(Q) dot -T svg $^ > $@
