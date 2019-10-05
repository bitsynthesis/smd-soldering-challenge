#define __SFR_OFFSET 0

#include <avr/io.h>

#define TMP r16
#define ALL_OFF r17
#define ALL_ON r18
#define STATE_A r20

wait:
    rjmp wait


; create patterns

#define PATTERN_ALL_ON r
#define PATTERN_ALL_BLINK r21
#define PATTERN_CHASER 2
#define PATTERN_GROW 3
#define PATTERN_END 4

.global TIM0_COMPA_vect
TIM0_COMPA_vect:
    cpi STATE_A, 0
    brne state_a_on

    out PORTB, ALL_OFF
    ldi STATE_A, 1
    reti

state_a_on:
    out PORTB, ALL_ON
    ldi STATE_A, 0
    reti

.global main
main:
    ldi ALL_OFF, 0b00000111
    ldi ALL_ON, 0
    ldi STATE_A, 0

    ; enable output pins
    out PORTB, ALL_OFF
    out DDRB, ALL_OFF

    ; configure timer
    ldi TMP, 0b00001011
    out TCCR0B, TMP
    ldi TMP, 0
    out TCNT0, TMP
    ldi TMP, $4
    out OCR0AH, TMP
    ldi TMP, 0
    out OCR0AL, TMP
    ldi TMP, 0b00000011
    out TIMSK0, TMP

    sei

    rjmp wait
