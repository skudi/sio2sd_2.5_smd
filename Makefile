# this Makefile is compatible with GNU make
VERSMAJOR=2
VERSMINOR=5

ifeq ($(BOARD), BOARD_ARDNANO)
NOLCD = 1
NOKEYS = 1
MCU = atmega328p
else
MCU = atmega32
endif

AVRDUDE = avrdude -c usbasp -p $(MCU)

AVRCC = avr-gcc
#AVRCC = avr-gcc-4.1.2
#AVRCC = avr-gcc-4.0.1
SHOWSIZE = avr-size
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
OBJS = conv.o fat.o interface.o led.o main.o mmc.o setup.o sio.o
ifndef NOLCD
OBJS += lcd.o
endif
AVRCFLAGS = -g
AVRCFLAGS += -mmcu=$(MCU)
AVRCFLAGS += -W -Wall -Wshadow -Wstrict-prototypes
AVRCFLAGS += -Os
AVRCFLAGS += -mcall-prologues
AVRCFLAGS += -finline-limit=1
AVRCFLAGS += -mno-interrupts
AVRCFLAGS += -ffunction-sections
#AVRCFLAGS += -Wa,-adhlns=$(<:%.c=%.lst)
AVRCFLAGS += -DVERSMAJ=$(VERSMAJOR) -DVERSMIN=$(VERSMINOR)
AVRCFLAGS += -DDYNAMIC_FATCACHE
AVRCFLAGS += -DUSE_PAJERO_CFG_TOOL

ifdef NOLCD
AVRCFLAGS += -DNOLCD
endif
ifeq ($(MCU), atmega328p)
AVRCFLAGS += -DATMEGA328
AVRCFLAGS += -DF_CPU=16000000ULL
FUSE = fuse_mega328
ifdef NOKEYS
AVRCFLAGS += -DNOKEYS 
else
OBJS += keys328.o
endif
else
AVRCFLAGS += -DF_CPU=14318180ULL
FUSE = fuse_mega32
ifdef NOKEYS
AVRCFLAGS += -DNOKEYS 
else
OBJS += keys.o
endif
endif
#AVRCFLAGS += -mint8
#-------------------
all: atari_conf_tool/sio2sd.xex sio2sd.hex sio2sd_all.bin sio2sd.bin sio2sd.dasm
	$(SHOWSIZE) sio2sd.out
#-------------------
install: $(FUSE) load
#-------------------
atari_conf_tool/sio2sd.xex.h atari_conf_tool/pajero_sio2sd.xex.h atari_conf_tool/sio2sd.xex: atari_conf_tool/sio2sd.asm tohex/tohex.c
	$(MAKE) -C tohex
	$(MAKE) -C atari_conf_tool
xex_loader/xex_loader.bin.h: xex_loader/xex_loader.asm tohex/tohex.c
	$(MAKE) -C tohex
	$(MAKE) -C xex_loader
firmware_updater/sdfirmware.bin: firmware_updater/main.c lcd.c lcd.h mmc.c mmc.h delay.h cbisbi.h
	$(MAKE) NOLCD=$(NOLCD) MCU=$(MCU) -C firmware_updater
sio2sd.dasm : sio2sd.out
	$(OBJDUMP) -D sio2sd.out > sio2sd.dasm
sio2sd.hex : sio2sd.out 
	$(OBJCOPY) -R .eeprom -O ihex sio2sd.out sio2sd.hex 
sio2sd.bin : sio2sd.out 
	$(OBJCOPY) -R .eeprom -O binary --gap-fill 0xFF --pad-to 0x7800 sio2sd.out sio2sd.bin
sio2sd_all.bin : sio2sd.bin firmware_updater/sdfirmware.bin
	cat sio2sd.bin firmware_updater/sdfirmware.bin > sio2sd_all.bin
sio2sd.out : $(OBJS)
	$(AVRCC) $(AVRCFLAGS) -o sio2sd.out -Wl,-Map,sio2sd.map -Wl,--gc-sections $(OBJS)
#-------------------
%.o: %.c %.h
	$(AVRCC) -c $(AVRCFLAGS) -o $@ $<
fat.o: fat.c interface.h sio.h mmc.h led.h lcd.h fat.h
	$(AVRCC) -c $(AVRCFLAGS) fat.c -o fat.o
interface.o: interface.c lcd.h keys.h conv.h fat.h setup.h
	$(AVRCC) -c $(AVRCFLAGS) interface.c -o interface.o
lcd.o: lcd.c delay.h cbisbi.h
	$(AVRCC) -c $(AVRCFLAGS) lcd.c -o lcd.o
led.o: led.c setup.h
	$(AVRCC) -c $(AVRCFLAGS) led.c -o led.o
main.o: main.c delay.h mmc.h led.h lcd.h keys.h interface.h fat.h sio.h setup.h
	$(AVRCC) -c $(AVRCFLAGS) main.c -o main.o
mmc.o: mmc.c mmc.h delay.h cbisbi.h
	$(AVRCC) -c $(AVRCFLAGS) mmc.c -o mmc.o
setup.o: setup.c interface.h
	$(AVRCC) -c $(AVRCFLAGS) setup.c -o setup.o
sio.o: sio.c delay.h keys.h lcd.h interface.h fat.h setup.h led.h cbisbi.h xex_loader/xex_loader.bin.h atari_conf_tool/sio2sd.xex.h atari_conf_tool/pajero_sio2sd.xex.h
	$(AVRCC) -c $(AVRCFLAGS) sio.c -o sio.o
#-------------------
load: sio2sd_all.bin
	$(AVRDUDE) -e -U flash:w:sio2sd_all.bin

save: sio2sd_all.bin
	$(AVRDUDE)  -U flash:r:test:i

load3: sio2sd_all_v3.1rc2.bin
	$(AVRDUDE) -e -U flash:w:sio2sd_all_v3.1rc2.bin

save3: sio2sd_all_v3.1rc2.bin
	$(AVRDUDE)  -U flash:r:test:i

status:
	$(AVRDUDE) -v

fuse_mega32:
# for 7.32 MHz version
#	$(AVRDUDE) -U hfuse:w:0xd1:m -U lfuse:w:0xff:m
# for 14.31 MHz version
	$(AVRDUDE) -U hfuse:w:0xc3:m -U lfuse:w:0x3f:m

fuse_mega328:
	$(AVRDUDE) -U hfuse:w:0xc3:m -U lfuse:w:0xff:m

#-------------------
clean:
	$(MAKE) -C tohex clean
	$(MAKE) -C atari_conf_tool clean
	$(MAKE) -C xex_loader clean
	$(MAKE) -C firmware_updater clean
	rm -f *.o *.map *.out
#-------------------
distclean: clean
	$(MAKE) -C tohex distclean
	$(MAKE) -C atari_conf_tool distclean
	$(MAKE) -C xex_loader distclean
	$(MAKE) -C firmware_updater distclean
	rm -f *.dasm *.hex *.bin
