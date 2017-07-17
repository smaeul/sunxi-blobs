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
