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

#ifndef _KEYS_H_
#define _KEYS_H_

#include <inttypes.h>

#ifdef NOKEYS

inline void keys_init(void) {};
inline void keys_finish(void) {};
inline uint8_t keys_shift(void) { return 0; };
inline uint8_t keys_get(void) { return 0; };

#else

void keys_init(void);
void keys_finish(void);
uint8_t keys_shift(void);
uint8_t keys_get(void);

#endif

#endif
