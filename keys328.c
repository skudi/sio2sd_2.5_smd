/*
 * SIO2SD
 *
 * Copyright (C) 2005-2010 Jakub Kruszona-Zawadzki
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
           |  /|      ______     |
           | / |                 |
PB0   -----|<  |------o    o-----+
           | \ |                 |
           |  \|                 |
                                 |
           |  /|      ______     |
           | / |                 |
PB1   -----|<  |------o    o-----+
           | \ |                 |
           |  \|                 |
                                 |
           |  /|      ______     |
           | / |                 |
PB2   -----|<  |------o    o-----+
           | \ |                 |
           |  \|                 |
                                 |
           |  /|      ______     |
           | / |                 |
PB3   -----|<  |------o    o-----+
           | \ |                 |
           |  \|                 |
                                 |
           |  /|      ______     |
           | / |                 |
PB4   -----|<  |------o    o-----+
           | \ |                 |
           |  \|       SHIFT     |
                                 |
                                 |
             ^                   |
             |                   |
             /                   |
             \                   |
             /                   |
             \                   |
             |                   |
PB5   -------+-------------------+


                                  
                                  
                                  
                                  



*/
#include "keys.h"
#include <avr/io.h>
#include <inttypes.h>
#include "delay.h"
#include "cbisbi.h" 
#include <util/delay.h>
#include "lcd.h"

#define KEYS_PORT PORTB
#define KEYS_DDR DDRB
#define KEYS_PIN PINB

#define KEYS_STROBES_PORT PORTB
#define KEYS_STROBES_DDR DDRB
#define KEYS_STROBES_PIN PINB
#define KEYS_STROBES_MASK 0x1f

#define KEYS_INPUT_PORT PORTB
#define KEYS_INPUT_DDR DDRB
#define KEYS_INPUT_PIN PINB
#define KEYS_INPUT_LINE 5



void keys_init(void) {
	// Unlike normal SIO2SD, the 5 buttons are strobed via the output lines used by the LCD bus (plus one more data line)

	KEYS_STROBES_PORT |= KEYS_STROBES_MASK;
	KEYS_STROBES_DDR |= KEYS_STROBES_MASK;

	// Set the single input line with no pullup
	KEYS_INPUT_PORT &= ~(1<<KEYS_INPUT_LINE);
	KEYS_INPUT_DDR &= ~(1<<KEYS_INPUT_LINE);

}

void keys_finish(void) {
	// back to inputs
	KEYS_STROBES_DDR &= ~(KEYS_STROBES_MASK);
}	

uint8_t keys_shift(void) {
	if (keys_get() == 5) {
		return 1;
	}
	return 0;
}

// for debugging
void led_flash(void) {
	PORTD &= 0x3f;
	_delay_ms(500);
	PORTD |= 0xc0;
	_delay_ms(500);
}

uint8_t keys_get(void) {
	uint8_t c,i;

	keys_init();

	// Check if any key pressed. If nothing is pressed then
	// quickly return, as the key scanning routing consumes time
	KEYS_STROBES_PORT &= ~(KEYS_STROBES_MASK);
	// It is so VITAL that we wait a few us after sending the strobe LOW.
	// Amazingly it will not work if you remove this delay
	DELAY(US_TO_TICKS(10));
	c = KEYS_INPUT_PIN & (1<<KEYS_INPUT_LINE);
	if (c!=0x00) {
		keys_finish();
		return 0;
	}

	KEYS_STROBES_PORT |= KEYS_STROBES_MASK;
	for (i=0;i<5;i++) {
		KEYS_STROBES_PORT &= ~(1<<i);
		// See earlier note about this delay after we send the strobe low
		DELAY(US_TO_TICKS(10));
		c = KEYS_INPUT_PIN & (1<<KEYS_INPUT_LINE);
		if (c==0x00) {
			// wait much longer
			DELAY(US_TO_TICKS(1000));
			c = KEYS_INPUT_PIN & (1<<KEYS_INPUT_LINE);
			// If its still pressed then register the key
			if (c==0x00) {
				keys_finish();
				return 1+i;
			}
		}
		KEYS_STROBES_PORT |= KEYS_STROBES_MASK;
	}
	keys_finish();
	return 0;
}
