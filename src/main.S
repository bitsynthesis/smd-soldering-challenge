#define __SFR_OFFSET 0

#include <avr/io.h>

#define MEM_ADDR r16
#define MEM_ADDR_END r17
#define ALL_OFF r18
#define ALL_ON r19
#define PATTERN_DIRECTION r20
#define TMP r21
#define TMP2 r22

#define MEM_ADDR_START 0x40

; create patterns

#define PATTERN_ALL_ON r
#define PATTERN_ALL_BLINK r21
#define PATTERN_CHASER 2
#define PATTERN_GROW 3
#define PATTERN_END 4

.global main
main:
    ldi ALL_OFF, 0b00000111
    ldi ALL_ON, 0
    ldi PATTERN_DIRECTION, 0

    ; enable output pins
    out PORTB, ALL_OFF
    out DDRB, ALL_OFF

    ; configure timer
    ldi TMP, 0b00001011
    out TCCR0B, TMP
    ldi TMP, 0
    out TCNT0, TMP
    ldi TMP, 0x08
    out OCR0AH, TMP
    ldi TMP, 0
    out OCR0AL, TMP
    ldi TMP, 0b00000011
    out TIMSK0, TMP

    ; record patterns
    clr XH
    ldi XL, MEM_ADDR_START

    ; load the LED patterns into memory
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

    ; ldi TMP, 0b00000100
    ; st X+, TMP
    ; ldi TMP, 0b00000110
    ; st X+, TMP
    ; ldi TMP, 0b00000111
    ; st X+, TMP
    ;
    ; ldi TMP, 0b00000110
    ; st X+, TMP
    ; ldi TMP, 0b00000100
    ; st X+, TMP
    ; ldi TMP, 0b00000000
    ; st X+, TMP
    ;
    ; ldi TMP, 0b00000000
    ; st X+, TMP
    ; ldi TMP, 0b00000000
    ; st X+, TMP
    ; ldi TMP, 0b00000111
    ; st X+, TMP
    ; ldi TMP, 0b00000111
    ; st X+, TMP
    ; ldi TMP, 0b00000000
    ; st X+, TMP
    ; ldi TMP, 0b00000111
    ; st X+, TMP
    ; ldi TMP, 0b00000111
    ; st X+, TMP

    mov MEM_ADDR_END, XL
    ldi XL, MEM_ADDR_START

    ; enable interrupts
    sei

wait:
    rjmp wait

.global TIM0_COMPA_vect
TIM0_COMPA_vect:
    ld TMP, X+
    out PORTB, TMP

    cp XL, MEM_ADDR_END
    brne tim0_compa_vect_end

    ldi XL, MEM_ADDR_START

tim0_compa_vect_end:
    reti
