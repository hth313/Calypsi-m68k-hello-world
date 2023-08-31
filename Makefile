VPATH = src
DEPDIR := .deps

# Common source files
ASM_SRCS =
C_SRCS = main.c

MODEL = --code-model=large --data-model=small
LIB_MODEL = lc-sd

# Object files
OBJS = $(ASM_SRCS:%.s=obj/%.o) $(C_SRCS:%.c=obj/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=obj/%-debug.o) $(C_SRCS:%.c=obj/%-debug.o)

obj/%.o: %.s
	as68k --core=68000 $(MODEL) --target=Foenix --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%.o: %.c $(DEPDIR)/%.d | $(DEPDIR)
	@cc68k --core=68000 $(MODEL) --target=Foenix --debug --dependencies -MQ$@ >$(DEPDIR)/$*.d $<
	cc68k --core=68000 $(MODEL) --target=Foenix --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.s
	as68k --core=68000 $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.c $(DEPDIR)/%-debug.d | $(DEPDIR)
	@cc68k --target=Foenix -core=68000 $(MODEL) --debug --dependencies -MQ$@ >$(DEPDIR)/$*-debug.d $<
	cc68k --target=Foenix --core=68000 $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

hello.elf: $(OBJS_DEBUG)
	ln68k --debug -o $@ $^ a2560u+.scm  --list-file=hello-debug.lst --cross-reference  --semi-hosted --target=Foenix --rtattr cstartup=Foenix_user --rtattr stubs=foenix --stack-size=2000 --sstack-size=800

hello.pgz:  $(OBJS)
	ln68k -o $@ $^ a2560u+.scm --output-format=pgz --list-file=hello-Foenix.lst --cross-reference --rtattr cstartup=Foenix_user

hello.hex:  $(OBJS)
	ln68k -o $@ $^ a2560u+.scm --output-format=intel-hex --list-file=hello-Foenix.lst --cross-reference --rtattr cstartup=Foenix_morfe --stack-size=2000

clean:
	-rm $(DEPFILES)
	-rm $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	-rm hello.elf hello.pgz hello-debug.lst hello-Foenix.lst

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(C_SRCS:%.c=$(DEPDIR)/%.d) $(C_SRCS:%.c=$(DEPDIR)/%-debug.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
