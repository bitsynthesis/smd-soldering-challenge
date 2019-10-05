#include <avr/interrupt.h>
#include <avr/io.h>

typedef enum {
  PATTERN_ALL_ON,
  PATTERN_ALL_BLINK,
  PATTERN_CHASER,
  PATTERN_GROW,
  PATTERN_END
} Pattern;

typedef enum {
  DIRECTION_DOWN,
  DIRECTION_UP
} Direction;

volatile Pattern PATTERN = 0;
volatile int PATTERN_COUNT = 0;
const int PATTERN_REPS = 1;
volatile int PATTERN_STATE = 0;
volatile int DIRECTION = DIRECTION_UP;

void pattern_step(Pattern pattern) {
  int output = (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2);
  switch(pattern) {
  case PATTERN_ALL_ON:
    PORTB = 0;
    break;
  case PATTERN_ALL_BLINK:
    PORTB ^= output;
    break;
  case PATTERN_CHASER:
    if(2 < PATTERN_STATE) PATTERN_STATE = 0;
    PORTB = output & ~(1 << PATTERN_STATE);
    PATTERN_STATE++;
    break;
  case PATTERN_GROW:
    if(3 < PATTERN_STATE) PATTERN_STATE = 0;
    if(PATTERN_STATE == 0) {
      PORTB = output;
    } else {
      PORTB &= ~(1 << (PATTERN_STATE - 1));
    }
    PATTERN_STATE++;
    break;
  default:
    break;
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
  pattern_step(PATTERN);

  if(DIRECTION) {
    if(OCR0A < 4096) {
      OCR0A += 128;
    } else {
      DIRECTION = 0;
    }
  } else {
    if(256 < OCR0A) {
      OCR0A -= 128;
    } else {
      DIRECTION = 1;
      PATTERN_COUNT++;
    }
  }

  if((PATTERN_REPS - 1) < PATTERN_COUNT) {
    PATTERN++;
    if(PATTERN == PATTERN_END) PATTERN = 1;
    PATTERN_COUNT = 0;
  }
}
