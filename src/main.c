#include <avr/io.h>

#define F_CPU 1000000UL
#include <util/delay.h>

volatile int A = 0;

int main() {
  DDRB = (1 << DDB0) | (1 << DDB1) | (1 << DDB2);

  while(1) {
    if(A) {
      PORTB = (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2);
      A = 0;
    } else {
      PORTB = 0;
      A = 1;
    }
    _delay_ms(2000);
  }
}
