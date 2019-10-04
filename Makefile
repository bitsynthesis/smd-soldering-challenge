.PHONY: analyzer asm clean flash flash-asm loc size term

TEST_CC ?= avr-gcc

BUILD_DIR=./build

SMDC_ELF=$(BUILD_DIR)/smdc.elf
SMDC_HEX=$(SMDC_ELF:%.elf=%.hex)

SMDC_FLAGS=-std=c11 -g -Os -mmcu=attiny10 -Ilib -Wall -Wpedantic -Wdouble-promotion -Wshadow -Wlogical-op -fno-strict-aliasing -fno-strict-overflow -fno-strict-aliasing -fno-strict-overflow

SMDC_SOURCE_FILES=src/main.c

all:
	make clean
	make $(SMDC_HEX)

flash: $(SMDC_HEX)
	sudo avrdude -v -c usbtiny -p attiny10 $(SMDC_AVR_FUSES) -U flash:w:$(SMDC_HEX)

$(SMDC_HEX): $(SMDC_ELF)
	avr-objcopy -j .text -j .data -O ihex $< $@

$(SMDC_ELF):
	avr-gcc $(SMDC_FLAGS) -o $@ $(SMDC_SOURCE_FILES)

clean:
	rm $(BUILD_DIR)/* || true

size:
	avr-size -Cx --mcu attiny10 $(SMDC_ELF)

loc:
	cloc test
	cloc lib src

asm:
	avr-gcc -save-temps -mmcu=attiny10 src/main.S -o ./build/asm.elf
	avr-objcopy -j .text -j .data -O ihex ./build/asm.elf ./build/asm.hex

flash-asm: asm
	sudo avrdude -v -c usbtiny -p attiny10 -U flash:w:./build/asm.hex
