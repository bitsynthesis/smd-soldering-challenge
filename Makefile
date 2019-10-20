.PHONY: all clean flash loc size

BUILD_DIR=./build
ELF_FILE=$(BUILD_DIR)/smd-challenge.elf
HEX_FILE=$(BUILD_DIR)/smd-challenge.hex

all: clean
	make $(HEX_FILE)

clean:
	rm $(BUILD_DIR)/* main.s main.o || true

$(BUILD_DIR):
	mkdir $@

$(ELF_FILE): $(BUILD_DIR)
	avr-gcc -save-temps -mmcu=attiny10 src/main.S -o $@

$(HEX_FILE): $(ELF_FILE)
	avr-objcopy -j .text -j .data -O ihex $< $@

flash: $(HEX_FILE)
	sudo avrdude -v -c usbtiny -p attiny10 -U flash:w:$<

size: $(ELF_FILE)
	avr-size -Cx --mcu attiny10 $(ELF_FILE)
