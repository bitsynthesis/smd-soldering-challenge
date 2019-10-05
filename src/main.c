#include <avr/interrupt.h>
#include <avr/io.h>


// What makes a pattern?
// - PatternLed   sequence of pin on / off combinations
// - PatternScrub sequence of indexes iterating over ^
// - PatternSpeed sequence of clock speeds


typedef enum {
  PATTERN_LED_ALL_ON,
  PATTERN_LED_ALL_BLINK,
  PATTERN_LED_CHASER,
  PATTERN_LED_GROW,
  PATTERN_LED_END
} PatternLed;

/* typedef enum { */
/*   PATTERN_SCRUB_UP, */
/*   PATTERN_SCRUB_UP_DOWN, */
/*   PATTERN_SCRUB_DOWN, */
/*   PATTERN_SCRUB_END */
/* } PatternScrub; */

typedef enum {
  PATTERN_SPEED_SLOW,
  PATTERN_SPEED_SLOW_FAST,
  PATTERN_SPEED_FAST,
  PATTERN_SPEED_FAST_SLOW,
  PATTERN_SPEED_SLOW_FAST_SLOW,
  PATTERN_SPEED_END
} PatternSpeed;

typedef enum {
  DIRECTION_DOWN,
  DIRECTION_UP
} Direction;

const int PATTERN_REPS = 1;

volatile PatternLed pattern_led = PATTERN_LED_ALL_ON;
/* volatile PatternScrub pattern_scrub = PATTERN_SCRUB_UP; */
volatile PatternSpeed pattern_speed = PATTERN_SPEED_SLOW;

volatile int pattern_count = 0;
volatile int pattern_led_state = 0;
volatile int pattern_speed_state = DIRECTION_UP;

void pattern_led_step(void) {
  int output = (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2);
  switch(pattern_led) {
  case PATTERN_LED_ALL_ON:
    PORTB = 0;
    break;
  case PATTERN_LED_ALL_BLINK:
    PORTB ^= output;
    break;
  case PATTERN_LED_CHASER:
    if(2 < pattern_led_state) pattern_led_state = 0;
    PORTB = output & ~(1 << pattern_led_state);
    pattern_led_state++;
    break;
  case PATTERN_LED_GROW:
    if(3 < pattern_led_state) pattern_led_state = 0;
    if(pattern_led_state == 0) {
      PORTB = output;
    } else {
      PORTB &= ~(1 << (pattern_led_state - 1));
    }
    pattern_led_state++;
    break;
  default:
    pattern_led = 0;
    break;
  }
}

void pattern_speed_step(void) {
  switch(pattern_speed) {
    case(PATTERN_SPEED_SLOW):
      OCR0A = 4096;
      pattern_speed_state++;
      if(15 < pattern_speed_state) {
        pattern_speed_state = 0;
        pattern_count++;
      }
      break;
    case(PATTERN_SPEED_SLOW_FAST):
      if(256 < OCR0A) {
        OCR0A -= 128;
      } else {
        OCR0A = 4096;
        pattern_count++;
      }
      break;
    case(PATTERN_SPEED_FAST):
      OCR0A = 256;
      pattern_speed_state++;
      if(254 < pattern_speed_state) {
        pattern_count++;
        pattern_speed_state = 0;
      }
      break;
    case(PATTERN_SPEED_FAST_SLOW):
      if(OCR0A < 4096) {
        OCR0A += 128;
      } else {
        OCR0A = 256;
        pattern_count++;
      }
      break;
    case(PATTERN_SPEED_SLOW_FAST_SLOW):
      if(pattern_speed_state == DIRECTION_UP) {
        if(OCR0A < 4096) {
          OCR0A += 128;
        } else {
          pattern_speed_state = DIRECTION_DOWN;
        }
      } else {
        if(256 < OCR0A) {
          OCR0A -= 128;
        } else {
          pattern_speed_state = DIRECTION_UP;
          pattern_count++;
        }
      }
    default:
      pattern_speed = 0;
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

ISR(TIM0_COMPA_vect) {
  pattern_led_step();
  pattern_speed_step();

  if((PATTERN_REPS - 1) < pattern_count) {
    pattern_led++;
    if(pattern_led == PATTERN_LED_END) pattern_led = 1;

    /* pattern_scrub++; */
    /* if(pattern_scrub == PATTERN_SCRUB_END) pattern_scrub = 0; */

    pattern_speed++;
    if(pattern_speed == PATTERN_SPEED_END) pattern_speed = 0;

    pattern_count = 0;
  }
}
