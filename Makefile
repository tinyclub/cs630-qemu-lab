AS        = as -g --32
CC        = gcc -g -m32
LD        = ld -melf_i386
OBJCOPY   = objcopy
ENTRY     = __start
SEG_PROG1 = 0x07C0
SEG_PROG2 = 0x1000
TOP_DIR   = $(CURDIR)
LDFILE    = $(TOP_DIR)/src/bootloader_x86.ld
QUICKLOAD = $(TOP_DIR)/src/quickload_floppy.s
DEF_SRC   = $(TOP_DIR)/src/rtc.s
CONFIGURE = $(TOP_DIR)/configure
CS630     = http://www.cs.usfca.edu/~cruse/cs630f06/
IMAGE    ?= $(TOP_DIR)/boot.img

all: clean boot.img

boot.img: boot.bin quickload.bin
	@dd if=quickload.bin of=$(IMAGE) bs=512 count=1
	@dd if=boot.bin of=$(IMAGE) seek=1 bs=512 count=2879

config: $(DEF_SRC) $(SRC)
	@if [ ! -f $(TOP_DIR)/boot.S ]; then $(CONFIGURE) $(DEF_SRC); fi
	@$(if $(SRC), $(CONFIGURE) $(SRC))

boot.bin: config
	@sed -i -e "s%$(SEG_PROG1)%$(SEG_PROG2)%g" boot.S
	@$(AS) -o boot.o boot.S
	@$(LD) boot.o -o boot.elf -T$(LDFILE) #-e $(ENTRY)
	@$(OBJCOPY) -R .pdr -R .comment -R.note -S -O binary boot.elf boot.bin

quickload.bin:
	@$(AS) $(QUICKLOAD) -o quickload.o
	@$(LD) quickload.o -o quickload.elf -T$(LDFILE) #-e $(ENTRY)
	@$(OBJCOPY) -R .pdr -R .comment -R.note -S -O binary quickload.elf quickload.bin

update:
	@wget -c -m -nH -np --cut-dirs=2 -P res/ $(CS630)

# Debugging support
ELF_SYM ?= $(TOP_DIR)/boot.elf
GDB_CMD ?= gdb --quiet $(ELF_SYM)
XTERM_CMD ?= lxterminal --working-directory=$(TOP_DIR) -t "$(GDB_CMD)" -e "$(GDB_CMD)"

gdbinit:
	@echo "add-auto-load-safe-path $(TOP_DIR)/.gdbinit" > $(HOME)/.gdbinit

debug: gdbinit
	@$(XTERM_CMD) &
	@make -s boot D=1

DEBUG = $(if $D, -s -S)
ifeq ($G,0)
   CURSES=-curses
endif

MEM ?= 129M

boot: clean boot.img
	qemu-system-i386 -M pc -m $(MEM) -fda $(IMAGE) -boot a $(CURSES) $(DEBUG)

pmboot: boot

clean:
	@rm -rf *.bin *.elf *.o $(IMAGE)

distclean: clean
	@rm -rf boot.S


note:
	@cat NOTE.md

help:
	@echo "--------------------Assembly Course (CS630) Lab---------------------"
	@echo ""
	@echo "    :: Download ::"
	@echo ""
	@echo "    make update                  -- download the latest resources for the course"
	@echo ""
	@echo "    :: Configuration ::"
	@echo ""
	@echo "    ./configure src/helloworld.s -- configure the source want to compile"
	@echo "    ./configure src/rtc.s        -- configure the sources with real mode"
	@echo "    ./configure src/pmrtc.s      -- configure the sources with protected mode"
	@echo ""
	@echo "    :: Compile and Boot ::"
	@echo ""
	@echo "    make boot                    -- Compile and boot"
	@echo "    make boot G=0                -- Curses based output, for ssh like console"
	@echo "    make boot D=1                -- For debugging with gdb"
	@echo ""
	@echo "    :: Configure, Compile and Boot ::"
	@echo ""
	@echo "    make boot SRC=src/rtc.s      -- Specify the source directly with SRC"
	@echo "    make boot SRC=src/pmrtc.s    -- Specify the source directly with SRC"
	@echo ""
	@echo "    :: Notes ::"
	@echo ""
	@echo "    make note"
	@echo ""
	@echo "--------------------------------------------------------------------"
