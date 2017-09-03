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

all: $(BOARD)/arisc.data $(BOARD)/arisc.elf $(BOARD)/arisc.S $(BOARD)/callgraph.svg
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
	$(Q) rm -f $(BOARD)/arisc.S $(BOARD)/arisc.bin $(BOARD)/arisc.data $(BOARD)/arisc.elf $(BOARD)/arisc.s
	$(Q) rm -f $(BOARD)/callgraph.gv $(BOARD)/callgraph.svg

save:
	$(M) SAVE $(BOARD)/comments.txt
	$(Q) test -f $(BOARD)/arisc.S && cut -c81- $(BOARD)/arisc.S > $(BOARD)/comments.txt

$(BOARD)/arisc.bin: $(BOARD)/arisc.hex
	$(M) XXD $@
	$(Q) xxd -r $^ $@

$(BOARD)/arisc.elf: $(BOARD)/arisc.bin $(BOARD)/sections $(BOARD)/symbols
	$(M) BIN2ELF $@
	$(Q) scripts/bin2elf $^ $@

$(BOARD)/arisc.data: $(BOARD)/arisc.elf
	$(M) OBJDUMP $@
	$(Q) $(CROSS_COMPILE)objdump -s -j .0x00010114 $^ > $@

$(BOARD)/arisc.s: $(BOARD)/arisc.elf
	$(M) OBJDUMP $@
	$(Q) $(CROSS_COMPILE)objdump -d $^ | expand > $@

$(BOARD)/arisc.S: $(BOARD)/arisc.s $(BOARD)/comments.txt
	$(M) PASTE $@
	$(Q) paste $^ | expand -t 80,88 > $@

$(BOARD)/callgraph.gv: $(BOARD)/arisc.s
	$(M) CGRAPH $@
	$(Q) scripts/callgraph $^ $@

$(BOARD)/callgraph.svg: $(BOARD)/callgraph.gv
	$(M) DOT $@
	$(Q) dot -T svg $^ > $@
