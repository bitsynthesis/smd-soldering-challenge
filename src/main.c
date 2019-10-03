#include <avr/interrupt.h>
#include <avr/io.h>

volatile int A = 0;
volatile int B = 0;

void toggle(void) {
  if(A) {
    PORTB = (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2);
    A = 0;
  } else {
    PORTB = 0;
    A = 1;
  }
}

int main() {
  // enable output pins
  PORTB = (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2);
  DDRB = (1 << DDB0) | (1 << DDB1) | (1 << DDB2);

  // configure timer
  TCCR0B = (1 << CS00) | (1 << CS01) | (1 << WGM02);
  TCNT0 = 0;
  OCR0A = 1024;
  TIMSK0 = (1 << OCIE0A) | (1 << TOIE0);;

  sei();

  while(1) {}

  return 0;
}

/* ISR(TIM0_OVF_vect) { */
/*   PORTB = 0; */
/* } */

ISR(TIM0_COMPA_vect) {
  toggle();
  if(B) {
    if(OCR0A < 4096) {
      OCR0A += 128;
    } else {
      B = 0;
    }
  } else {
    if(256 < OCR0A) {
      OCR0A -= 128;
    } else {
      B = 1;
    }
  }
}
