VPATH = src

FOENIX = module/Calypsi-m68k-Foenix

# Common source files
ASM_SRCS =
C_SRCS = main.c

MODEL = --code-model=large --data-model=small
LIB_MODEL = lc-sd

FOENIX_LIB = $(FOENIX)/foenix-$(LIB_MODEL).a
A2560U_RULES = $(FOENIX)/linker-files/a2560u-simplified.scm
A2560K_RULES = $(FOENIX)/linker-files/a2560k-simplified.scm

# Object files
OBJS = $(ASM_SRCS:%.s=obj/%.o) $(C_SRCS:%.c=obj/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=obj/%-debug.o) $(C_SRCS:%.c=obj/%-debug.o)

obj/%.o: %.s
	as68k --core=68000 $(MODEL) --target=Foenix --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%.o: %.c
	cc68k --core=68000 $(MODEL) --target=Foenix --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.s
	as68k --core=68000 $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.c
	cc68k --core=68000 $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

hello.elf: $(OBJS_DEBUG)
	ln68k --debug -o $@ $^ $(A2560U_RULES) clib-68000-$(LIB_MODEL).a --list-file=hello-debug.lst --cross-reference --rtattr printf=reduced --semi-hosted --target=Foenix --stack-size=2000 --sstack-size=800

hello.pgz:  $(OBJS) $(FOENIX_LIB)
	ln68k -o $@ $^ $(A2560U_RULES) clib-68000-$(LIB_MODEL)-Foenix.a --output-format=pgz --list-file=hello-Foenix.lst --cross-reference --rtattr printf=reduced --rtattr cstartup=Foenix_user

hello.hex:  $(OBJS) $(FOENIX_LIB)
	ln68k -o $@ $^ $(A2560K_RULES) clib-68000-$(LIB_MODEL)-Foenix.a --output-format=intel-hex --list-file=hello-Foenix.lst --cross-reference --rtattr printf=reduced --rtattr cstartup=Foenix_morfe --stack-size=2000

$(FOENIX_LIB):
	(cd $(FOENIX) ; make all)

clean:
	-rm $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst) $(FOENIX_LIB)
	-rm hello.elf hello.pgz hello-debug.lst hello-Foenix.lst
	-(cd $(FOENIX) ; make clean)
