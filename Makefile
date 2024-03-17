# This is a makefile for building a simple program using Calypsi, targeting the Foenix
# It's commented so to be educative.
# The makefile builds a PGZ, HEX and ELF. If you need only one of them, just do e.g.
# make hello.pgz

# This means we can find source files in this folder
VPATH = src
# Folder where we'll store auto-generated dependencies
DEPDIR := .deps
# Folder where object files will be stored before linking
OBJDIR = obj
# That's how the "list" files will be named
LIST_FILE_NAME= hello-Foenix-$@.lst

# Common source files, list your files here
ASM_SRCS=
C_SRCS= main.c

# Calypsi preferences. Change or leave blank according to your preferences
MODEL= --code-model=large --data-model=small
LINKER_FILE= a2560u+.scm
LIST_FILE=--list-file=$(LIST_FILE_NAME)
DEBUG= --debug
CORE=--core=68000
TARGET=--target=Foenix
STACK_SIZE=--stack-size=2000

# These variables are typically defined in makefiles to indicate the name of the
# assembler, compiler, linker, and their options, so we use the same pattern here
AS = as68k
CC = cc68k
LD = ln68k
ASFLAGS = $(CORE) $(MODEL) $(TARGET) $(DEBUG)
CFLAGS  = $(CORE) $(MODEL) $(TARGET) $(DEBUG)
LDFLAGS = --cross-reference $(LIST_FILE)

# Create list of object files, from list of C/asm source file names
OBJS = $(ASM_SRCS:%.s=$(OBJDIR)/%.o) $(C_SRCS:%.c=$(OBJDIR)/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=$(OBJDIR)/%-debug.o) $(C_SRCS:%.c=$(OBJDIR)/%-debug.o)

# .PHONEY indicates there are not real build artifacts
.PHONEY: $(OBJDIR) clean

# Rules for building objects files from their source
$(OBJDIR)/%.o: %.s $(OBJDIR)
	$(AS) $(ASFLAGS)--list-file=$(@:%.o=%.lst) -o $@ $<

$(OBJDIR)/%.o: %.c $(OBJDIR) $(DEPDIR)/%.d | $(DEPDIR)
	@$(CC) $(CFLAGS) --dependencies -MQ$@ >$(DEPDIR)/$*.d $<
	$(CC) $(CFLAGS) --list-file=$(@:%.o=%.lst) -o $@ $<

$(OBJDIR)/%-debug.o: %.s
	$(AS) $(ASFLAGS) --list-file=$(@:%.o=%.lst) -o $@ $<

$(OBJDIR)/%-debug.o: %.c $(DEPDIR)/%-debug.d | $(DEPDIR)
	@$(CC) $(CFLAGS) --dependencies -MQ$@ >$(DEPDIR)/$*-debug.d $<
	$(CC) $(CFLAGS) --list-file=$(@:%.o=%.lst) -o $@ $<

# End results
ALL_TARGETS= hello.pgz hello.hex hello.elf

# This target is first so is you just invoke "make", it will build everything
all: $(ALL_TARGETS)

# PGZ, e.g. for upload using the FoenixMgr python scripts
hello.pgz: $(OBJS)
	$(LD) -o $@ $^ $(LINKER_FILE) --output-format=pgz $(LDFLAGS) --rtattr cstartup=Foenix_user

hello.hex: $(OBJS)
	$(LD) -o $@ $^ $(LINKER_FILE) --output-format=intel-hex $(LDFLAGS) --rtattr cstartup=Foenix_morfe $(STACK_SIZE)

hello.elf: $(OBJS_DEBUG)
	$(LD) -o $@ $^ $(LINKER_FILE) $(LDFLAGS) --debug --semi-hosted $(TARGET) --rtattr cstartup=Foenix_user --rtattr stubs=foenix $(STACK_SIZE) --sstack-size=800


# Utility targets
clean:
	$(RM) $(DEPFILES)
	$(RM) $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	$(RM) $(ALL_TARGETS) *.lst

$(DEPDIR): ; @mkdir -p $@

$(OBJDIR): ; @mkdir -p $@

# Dependencies targets: uses Calypsi's ability to detect what a C/asm source file depends on
# (because if it's #include) and generate dependencies so any change in a dependency
# causes the source file to be rebuild.
DEPFILES := $(C_SRCS:%.c=$(DEPDIR)/%.d) $(C_SRCS:%.c=$(DEPDIR)/%-debug.d)
$(DEPFILES):
include $(wildcard $(DEPFILES))
