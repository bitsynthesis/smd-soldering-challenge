#define __SFR_OFFSET 0

#include <avr/io.h>

#define MEM_ADDR          r16
#define MEM_ADDR_END      r17
#define SPEED_DIRECTION   r18
#define PATTERN_DIRECTION r19
#define TMP               r20
#define SPEED_CMP_L       r21
#define SPEED_CMP_H       r22
#define SPEED_INC_L       r23
#define SPEED_INC_H       r24
#define SPEED_LIMIT       r25

#define DEC               0
#define INC               1
#define REV               0
#define FWD               1

#define MEM_ADDR_START    0x40

.global main
main:
    ldi PATTERN_DIRECTION, 1    		; start from the beginning of the pattern
    ldi SPEED_DIRECTION, 1      		; start slow and speed up

    ldi SPEED_INC_L, 0x08       		; set speed increment low byte
    ldi SPEED_INC_H, 0x00       		; set speed increment high byte

    ldi TMP, 0b00000111         		; load output pin mask into TMP
    out PORTB, TMP              		; enable output pins
    out DDRB, TMP               		; set all output pins high to start (LEDs off)

    ldi TMP, 0b00001011         		; load timer configuration into TMP register
    out TCCR0B, TMP             		; configure timer for CTC mode and 1/64 prescaler
    ldi TMP, 0                  		; load starting counter value into TMP
    out TCNT0, TMP              		; set starting counter value
    ldi TMP, 0x0F               		; load starting counter compare high byte into TMP
    out OCR0AH, TMP             		; set starting counter compare high byte
    ldi TMP, 0x00               		; load starting counter compare low byte into TMP
    out OCR0AL, TMP             		; set starting counter compare value
    ldi TMP, 0b00000010         		; load timer interrupt mask into TMP
    out TIMSK0, TMP             		; enable output compare A interrupt

    clr XH                      		; clear X high byte
    ldi XL, MEM_ADDR_START      		; load first pattern address into X

    ldi TMP, 0b00000000         		; load blink pattern into memory
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

    ldi TMP, 0b00000111         		; load flyover pattern into memory
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

    ldi TMP, 0b00000010         		; load in / out pattern into memory
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

    ldi TMP, 0b00000110         		; load chaser pattern into memory
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

    mov MEM_ADDR_END, XL        		; save the end of pattern memory address
    ldi XL, MEM_ADDR_START      		; reset X to the beginning of the pattern

    sei                         		; enable interrupts

wait:
    rjmp wait                   		; do nothing, wait for timer interrupt

.global TIM0_COMPA_vect         		; define timer interrupt
TIM0_COMPA_vect:
    cpi PATTERN_DIRECTION, FWD  		; check the pattern direction
    brne tim0_compa_vect_pattern_dn	; if not 1, pattern is in reverse

tim0_compa_vect_pattern_up:
    ld TMP, X+                  		; load the pattern step at X into TMP, increment X
    out PORTB, TMP              		; output the current pattern step

    cp XL, MEM_ADDR_END         		; check if at the end of pattern
    brne tim0_compa_vect_speed  		; if not at the end, change speed

    dec XL                      		; if at the end of pattern, decrement X...
    ldi PATTERN_DIRECTION, REV  		; ...and change direction to reverse

    rjmp tim0_compa_vect_speed  		; then change speed

tim0_compa_vect_pattern_dn:
    ld TMP, -X                  		; load the pattern step at X into TMP, decrement X
    out PORTB, TMP              		; output the current pattern step

    cpi XL, MEM_ADDR_START      		; check if at the start of pattern
    brne tim0_compa_vect_speed  		; if not at the start, change speed

    inc XL                      		; if at the start of pattern, increment X...
    ldi PATTERN_DIRECTION, FWD  		; ...and change direction to forward

tim0_compa_vect_speed:
    in SPEED_CMP_H, OCR0AH          ; load current speed high byte
    in SPEED_CMP_L, OCR0AL          ; load current speed low byte

    cpi SPEED_DIRECTION, INC        ; check if speed increasing
    brne tim0_compa_vect_speed_dn   ; if speed is not increasing, it's decreasing

tim0_compa_vect_speed_up:
    ldi SPEED_DIRECTION, INC        ; set direction to increasing

    ldi SPEED_LIMIT, 0x01           ; set speed limit to the smallest cycle time
    cp SPEED_CMP_H, SPEED_LIMIT     ; compare current cycle time with limit
    brlo tim0_compa_vect_speed_dn   ; if current cycle time less than limit, switch direction

    sub SPEED_CMP_L, SPEED_INC_L    ; subtract increment from current low byte
    sbc SPEED_CMP_H, SPEED_INC_H    ; subtract increment from current high byte

    rjmp tim0_compa_vect_end        ; finish pattern step

tim0_compa_vect_speed_dn:
    ldi SPEED_DIRECTION, DEC        ; set direction to decreasing

    ldi SPEED_LIMIT, 0x0F           ; set speed limit to largest cycle time
    cp SPEED_LIMIT, SPEED_CMP_H     ; compare current cycle time with limit
    brlo tim0_compa_vect_speed_up   ; if limit less than current cycle time, switch direction

    add SPEED_CMP_L, SPEED_INC_L    ; add increment to current low byte
    adc SPEED_CMP_H, SPEED_INC_H    ; add increment to current high byte

tim0_compa_vect_end:
    out OCR0AH, SPEED_CMP_H         ; set timer compare high byte for modified speed
    out OCR0AL, SPEED_CMP_L         ; set timer compare low byte for modified speed

    reti                            ; return from interrupt
