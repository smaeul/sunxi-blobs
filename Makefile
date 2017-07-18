#
# Copyright © 2017 Samuel Holland <samuel@sholland.org>
# See LICENSE in the project directory for license terms.
#

BOARD		 = h5/normal
CROSS_COMPILE	 = arm-linux-musleabihf-

M := @printf '  %-7s %s\n'
Q := @
ifneq ($(V),)
M := @\#
Q :=
endif

all: $(BOARD)/brom.bin $(BOARD)/brom.elf $(BOARD)/brom.s
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
	$(M) CLEAN $(BOARD)/brom
	$(Q) rm -f $(BOARD)/brom.bin $(BOARD)/brom.elf $(BOARD)/brom.s

$(BOARD)/brom.bin: $(BOARD)/brom.hex
	$(M) XXD $@
	$(Q) xxd -r $^ $@

$(BOARD)/brom.elf: $(BOARD)/brom.bin $(BOARD)/sections $(BOARD)/symbols
	$(M) BIN2ELF $@
	$(Q) scripts/bin2elf $^ $@

$(BOARD)/brom.s: $(BOARD)/brom.elf
	$(M) OBJDUMP $@
	$(Q) $(CROSS_COMPILE)objdump -D $^ > $@
