OPENCM3DIR  = libopencm3
OPENCM3NAME = opencm3_stm32f4
OPENCM3FILE = $(OPENCM3DIR)/lib/lib$(OPENCM3NAME).a
LDSCRIPT    = stm32f405x6.ld

PREFIX     ?= arm-none-eabi
CC          = $(PREFIX)-gcc
LD          = $(PREFIX)-gcc
OBJCOPY     = $(PREFIX)-objcopy
OBJDUMP     = $(PREFIX)-objdump
GDB         = $(PREFIX)-gdb

ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES     = -DSTM32F4

CFLAGS     += -O3 \
              -Wall -Wextra -Wimplicit-function-declaration \
              -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
              -Wundef -Wshadow \
              -I$(OPENCM3DIR)/include \
              -fno-common $(ARCH_FLAGS) -MD $(DEFINES)
LDFLAGS    += --static -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group \
              -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections \
               $(ARCH_FLAGS) -L$(OPENCM3DIR)/lib

COMMONPATH=common

HEADERS = $(COMMONPATH)/fips202.h $(COMMONPATH)/randombytes.h
SOURCES= $(COMMONPATH)/stm32f4_wrapper.c $(COMMONPATH)/fips202.c $(COMMONPATH)/randombytes.c
OBJECTS = stm32f4_wrapper.o randombytes.o fips202.o keccakf1600.o sha2.o

SCHEMES = saber lightsaber firesaber

SABER_OBJECTS = $(addprefix SaberKEM/saber/m4/,cbd.o kem.o pack_unpack.o poly.o recon.o SABER_indcpa.o verify.o poly_mul.o)

LIGHTSABER_OBJECTS = $(addprefix SaberKEM/lightsaber/m4/,cbd.o kem.o pack_unpack.o poly.o recon.o SABER_indcpa.o verify.o poly_mul.o)

FIRESABER_OBJECTS = $(addprefix SaberKEM/firesaber/m4/,cbd.o kem.o pack_unpack.o poly.o recon.o SABER_indcpa.o verify.o poly_mul.o)

SABER_MULT=tmvp4_256_16.s

all: test-saber.bin benchmark-saber.bin stack-saber.bin \
test-lightsaber.bin benchmark-lightsaber.bin stack-lightsaber.bin \
test-firesaber.bin benchmark-firesaber.bin stack-firesaber.bin \
benchmark-tmvp4_256_16.bin stack-tmvp4_256_16.bin 

test-saber.elf: $(SABER_MULT) saber-test.o $(SABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< saber-test.o $(SABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

benchmark-saber.elf: $(SABER_MULT) saber-speed.o $(SABER_OBJECTS) $(SOURCES) $(OBJECTS)  $(LDSCRIPT)
	$(LD) -o $@ $< saber-speed.o $(SABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

stack-saber.elf: $(SABER_MULT) saber-stack.o $(SABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< saber-stack.o $(SABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)
	
test-lightsaber.elf: $(SABER_MULT) lightsaber-test.o $(LIGHTSABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< lightsaber-test.o $(LIGHTSABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

benchmark-lightsaber.elf: $(SABER_MULT) lightsaber-speed.o $(LIGHTSABER_OBJECTS) $(SOURCES) $(OBJECTS)  $(LDSCRIPT)
	$(LD) -o $@ $< lightsaber-speed.o $(LIGHTSABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

stack-lightsaber.elf: $(SABER_MULT) lightsaber-stack.o $(LIGHTSABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< lightsaber-stack.o $(LIGHTSABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)
	
test-firesaber.elf: $(SABER_MULT) firesaber-test.o $(FIRESABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< firesaber-test.o $(FIRESABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

benchmark-firesaber.elf: $(SABER_MULT) firesaber-speed.o $(FIRESABER_OBJECTS) $(SOURCES) $(OBJECTS)  $(LDSCRIPT)
	$(LD) -o $@ $< firesaber-speed.o $(FIRESABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

stack-firesaber.elf: $(SABER_MULT) firesaber-stack.o $(FIRESABER_OBJECTS) $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ $< firesaber-stack.o $(FIRESABER_OBJECTS) $(OBJECTS) $(LDFLAGS) -l$(OPENCM3NAME)

benchmark-tmvp4_256_16.elf: tmvp4_256_16.s benchmark-polymul_256_16.o $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ benchmark-polymul_256_16.o $(OBJECTS) $< $(LDFLAGS) -l$(OPENCM3NAME)	

stack-tmvp4_256_16.elf: $(SABER_MULT) stack-polymul_256_16.o $(SOURCES) $(OBJECTS) $(LDSCRIPT)
	$(LD) -o $@ stack-polymul_256_16.o $(OBJECTS) $< $(LDFLAGS) -l$(OPENCM3NAME)


# These targets are needed in particular because api.h varies per scheme
$(addsuffix -test.o,$(SCHEMES)): %-test.o: SaberKEM/test.c
	$(CC) -I$(COMMONPATH) -I"SaberKEM/$*/m4/" $(CFLAGS) -c -o $@ $<
$(addsuffix -speed.o,$(SCHEMES)): %-speed.o: SaberKEM/speed.c
	$(CC) -I$(COMMONPATH) -I"SaberKEM/$*/m4/" $(CFLAGS) -c -o $@ $<
$(addsuffix -stack.o,$(SCHEMES)): %-stack.o: SaberKEM/stack.c
	$(CC) -I$(COMMONPATH) -I"SaberKEM/$*/m4/" $(CFLAGS) -c -o $@ $<
	
benchmark-polymul_%.o: benchmark-polymul.c
	$(CC) -DDIMENSION=256 -DQ=8192 -I$(COMMONPATH) $(CFLAGS) -c -o $@ $<

stack-polymul_%.o: stack-polymul.c
	$(CC) -DDIMENSION=256 -DQ=8192 -I$(COMMONPATH) $(CFLAGS) -c -o $@ $<


%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.o: %.c $(HEADERS)
	$(CC) -I$(COMMONPATH) $(CFLAGS) -c -o $@ $<

%.o: %.S $(HEADERS)
	$(CC) -I$(COMMONPATH) $(CFLAGS) -c -o $@ $<
	

randombytes.o: $(COMMONPATH)/randombytes.c
	$(CC) $(CFLAGS) -o $@ -c $^

fips202.o: $(COMMONPATH)/fips202.c
	$(CC) $(CFLAGS) -o $@ -c $^

sha2.o: $(COMMONPATH)/sha2.c
	$(CC) $(CFLAGS) -o $@ -c $^

keccakf1600.o:  common/keccakf1600.S
	$(CC) $(CFLAGS) -o $@ -c $^

stm32f4_wrapper.o:  $(COMMONPATH)/stm32f4_wrapper.c
	$(CC) $(CFLAGS) -o $@ -c $^

.PHONY: clean
.PRECIOUS: $(OBJECTS) mult%.s

clean:
	-rm -f *.d
	-rm -f *.o
	-find SaberKEM -name '*.o' -delete
	-find SaberKEM -name '*.d' -delete
	-rm -f *.bin
	-rm -f *.elf
