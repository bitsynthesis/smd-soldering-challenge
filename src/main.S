#define __SFR_OFFSET 0

#include <avr/io.h>

#define MEM_ADDR r16
#define MEM_ADDR_END r17
#define SPEED_DIRECTION r18
#define PATTERN_DIRECTION r19
#define TMP r21
#define TMP2 r22
#define TMP3 r23
#define TMP4 r24
#define TMP5 r25

#define MEM_ADDR_START 0x40

.macro BLINK4
    ldi TMP, 0b00000000
    st X+, TMP
    ldi TMP, 0b00000111
    st X+, TMP
    ldi TMP, 0b00000000
    st X+, TMP
    ldi TMP, 0b00000111
    st X+, TMP
    ldi TMP, 0b00000000
    st X+, TMP
    ldi TMP, 0b00000111
    st X+, TMP
    ldi TMP, 0b00000000
    st X+, TMP
.endm

.global main
main:
    ldi PATTERN_DIRECTION, 1
    ldi SPEED_DIRECTION, 1

    ; enable output pins
    ldi TMP, 0b00000111
    out PORTB, TMP
    out DDRB, TMP

    ; configure timer
    ldi TMP, 0b00001011
    out TCCR0B, TMP
    ldi TMP, 0
    out TCNT0, TMP
    ldi TMP, 0x0F
    ; ldi TMP, 0x06
    out OCR0AH, TMP
    ldi TMP, 0x80
    out OCR0AL, TMP
    ldi TMP, 0b00000011
    out TIMSK0, TMP

    ; load patterns into memory
    clr XH
    ldi XL, MEM_ADDR_START

    BLINK4

    ldi TMP, 0b00000111
    st X+, TMP
    ldi TMP, 0b00000110
    st X+, TMP
    ldi TMP, 0b00000100
    st X+, TMP
    ldi TMP, 0b00000000
    st X+, TMP
    ldi TMP, 0b00000001
    st X+, TMP
    ldi TMP, 0b00000011
    st X+, TMP
    ldi TMP, 0b00000111
    st X+, TMP

    BLINK4

    ldi TMP, 0b00000110
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000011
    st X+, TMP
    ldi TMP, 0b00000111
    st X+, TMP
    ldi TMP, 0b00000011
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000110
    st X+, TMP

    mov MEM_ADDR_END, XL
    ldi XL, MEM_ADDR_START

    ; enable interrupts
    sei

wait:
    rjmp wait

.global TIM0_COMPA_vect
TIM0_COMPA_vect:
    cpi PATTERN_DIRECTION, 1
    brne tim0_compa_vect_pattern_down

tim0_compa_vect_pattern_up:
    ld TMP, X+
    out PORTB, TMP

    cp XL, MEM_ADDR_END
    brne tim0_compa_vect_end

    dec XL
    ldi PATTERN_DIRECTION, 0

    rjmp tim0_compa_vect_speed

tim0_compa_vect_pattern_down:
    ld TMP, -X
    out PORTB, TMP

    cpi XL, MEM_ADDR_START
    brne tim0_compa_vect_speed

    inc XL
    ldi PATTERN_DIRECTION, 1

tim0_compa_vect_speed:
    in TMP, OCR0AL
    in TMP2, OCR0AH

    ldi TMP3, 0x20
    ldi TMP4, 0x00

    cpi SPEED_DIRECTION, 1
    brne tim0_compa_vect_speed_down

tim0_compa_vect_speed_up:
    ldi SPEED_DIRECTION, 1

    ldi TMP5, 0x01
    cp TMP2, TMP5
    brlo tim0_compa_vect_speed_down

    sub TMP, TMP3
    sbc TMP2, TMP4

    rjmp tim0_compa_vect_end

tim0_compa_vect_speed_down:
    ldi SPEED_DIRECTION, 0

    ldi TMP5, 0x0F
    cp TMP5, TMP2
    brlo tim0_compa_vect_speed_up

    add TMP, TMP3
    adc TMP2, TMP4

tim0_compa_vect_end:
    out OCR0AH, TMP2
    out OCR0AL, TMP

    reti

; To compare 16bit numbers...
;
;   cp A_LOW, B_LOW
;   cpc A_HIGH, B_HIGH
