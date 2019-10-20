#define __SFR_OFFSET 0

#include <avr/io.h>

#define MEM_ADDR          r16
#define MEM_ADDR_END      r17
#define SPEED_DIRECTION   r18
#define PATTERN_DIRECTION r19
#define TMP               r20
#define TMP2              r21
#define SPEED_INC_L       r22
#define SPEED_INC_H       r23
#define TMP5              r24

#define REV               0
#define FWD               1

#define MEM_ADDR_START    0x40

.global main
main:
    ldi PATTERN_DIRECTION, 1    ; start from the beginning of the pattern
    ldi SPEED_DIRECTION, 1      ; start slow and speed up

    ldi SPEED_INC_L, 0x08       ; set speed increment low byte
    ldi SPEED_INC_H, 0x00       ; set speed increment high byte

    ldi TMP, 0b00000111         ; load output pin mask into TMP
    out PORTB, TMP              ; enable output pins
    out DDRB, TMP               ; set all output pins high to start (LEDs off)

    ldi TMP, 0b00001011         ; load timer configuration into TMP register
    out TCCR0B, TMP             ; configure timer for CTC mode and 1/64 prescaler
    ldi TMP, 0                  ; load starting counter value into TMP
    out TCNT0, TMP              ; set starting counter value
    ldi TMP, 0x0F               ; load starting counter compare high byte into TMP
    out OCR0AH, TMP             ; set starting counter compare high byte
    ldi TMP, 0x00               ; load starting counter compare low byte into TMP
    out OCR0AL, TMP             ; set starting counter compare value
    ldi TMP, 0b00000010         ; load timer interrupt mask into TMP
    out TIMSK0, TMP             ; enable output compare A interrupt

    clr XH                      ; clear X high byte
    ldi XL, MEM_ADDR_START      ; load first pattern address into X

    ldi TMP, 0b00000000         ; load blink pattern into memory
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

    ldi TMP, 0b00000111         ; load flyover pattern into memory
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

    ldi TMP, 0b00000010         ; load in / out pattern into memory
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000010
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000010
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000010
    st X+, TMP

    ldi TMP, 0b00000110         ; load chaser pattern into memory
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000011
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000110
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000011
    st X+, TMP
    ldi TMP, 0b00000101
    st X+, TMP
    ldi TMP, 0b00000110
    st X+, TMP

    mov MEM_ADDR_END, XL        ; save the end of pattern memory address
    ldi XL, MEM_ADDR_START      ; reset X to the beginning of the pattern

    sei                         ; enable interrupts

wait:
    rjmp wait                   ; do nothing, wait for timer interrupt

.global TIM0_COMPA_vect         ; define timer interrupt
TIM0_COMPA_vect:
    cpi PATTERN_DIRECTION, FWD  ; check the pattern direction
    brne tim0_compa_vect_pat_dn ; if not 1, pattern is in reverse

tim0_compa_vect_pat_up:
    ld TMP, X+                  ; load the pattern step at X into TMP, increment X
    out PORTB, TMP              ; output the current pattern step

    cp XL, MEM_ADDR_END         ; check if at the end of pattern
    brne tim0_compa_vect_speed  ; if not at the end, change speed

    dec XL                      ; if at the end of pattern, decrement X...
    ldi PATTERN_DIRECTION, REV  ; ...and change direction to reverse

    rjmp tim0_compa_vect_speed  ; then change speed

tim0_compa_vect_pat_dn:
    ld TMP, -X                  ; load the pattern step at X into TMP, decrement X
    out PORTB, TMP              ; output the current pattern step

    cpi XL, MEM_ADDR_START      ; check if at the start of pattern
    brne tim0_compa_vect_speed  ; if not at the start, change speed

    inc XL                      ; if at the start of pattern, increment X...
    ldi PATTERN_DIRECTION, FWD  ; ...and change direction to forward

tim0_compa_vect_speed:
    in TMP2, OCR0AH
    in TMP, OCR0AL

    cpi SPEED_DIRECTION, 1
    brne tim0_compa_vect_speed_down

tim0_compa_vect_speed_up:
    ldi SPEED_DIRECTION, 1

    ldi TMP5, 0x01
    cp TMP2, TMP5
    brlo tim0_compa_vect_speed_down

    sub TMP, SPEED_INC_L
    sbc TMP2, SPEED_INC_H

    rjmp tim0_compa_vect_end

tim0_compa_vect_speed_down:
    ldi SPEED_DIRECTION, 0

    ldi TMP5, 0x0F
    cp TMP5, TMP2
    brlo tim0_compa_vect_speed_up

    add TMP, SPEED_INC_L
    adc TMP2, SPEED_INC_H

tim0_compa_vect_end:
    out OCR0AH, TMP2
    out OCR0AL, TMP

    reti
