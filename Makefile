VPATH = src
DEPDIR := .deps

# Common source files
ASM_SRCS =
C_SRCS = main.c

MODEL = --code-model=large --data-model=small
TARGET = --target=a2560k --core=68040
LINKER_RULES = a2560k.scm

#TARGET = --target=a2560u --core=68000
#LINKER_RULES = a2560u+.scm

# Object files
OBJS = $(ASM_SRCS:%.s=obj/%.o) $(C_SRCS:%.c=obj/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=obj/%-debug.o) $(C_SRCS:%.c=obj/%-debug.o)

obj/%.o: %.s
	as68k --core=68000 $(MODEL) $(TARGET) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%.o: %.c $(DEPDIR)/%.d | $(DEPDIR)
	@cc68k $(MODEL) $(TARGET) --debug --dependencies -MQ$@ >$(DEPDIR)/$*.d $<
	cc68k $(MODEL) $(TARGET) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.s
	as68k --core=68000 $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

obj/%-debug.o: %.c $(DEPDIR)/%-debug.d | $(DEPDIR)
	@cc68k $(TARGET) $(MODEL) --debug --dependencies -MQ$@ >$(DEPDIR)/$*-debug.d $<
	cc68k $(TARGET) $(MODEL) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

hello.elf: $(OBJS_DEBUG)
	ln68k --debug -o $@ $^ $(TARGET) $(LINKER_RULES)  --list-file=hello-debug.lst --cross-reference  --semi-hosted --cstartup=Foenix_user --rtattr stubs=foenix --stack-size=2000 --sstack-size=800

hello.pgz:  $(OBJS)
	ln68k -o $@ $^ $(TARGET) $(LINKER_RULES) --output-format=pgz --list-file=hello-Foenix.lst --cross-reference --cstartup=Foenix_user

hello.hex:  $(OBJS)
	ln68k -o $@ $^ $(TARGET) $(LINKER_RULES) --output-format=intel-hex --list-file=hello-Foenix.lst --cross-reference --cstartup=Foenix_morfe --stack-size=2000

clean:
	-rm $(DEPFILES)
	-rm $(OBJS) $(OBJS:%.o=%.lst) $(OBJS_DEBUG) $(OBJS_DEBUG:%.o=%.lst)
	-rm hello.elf hello.pgz hello-debug.lst hello-Foenix.lst

$(DEPDIR): ; @mkdir -p $@

DEPFILES := $(C_SRCS:%.c=$(DEPDIR)/%.d) $(C_SRCS:%.c=$(DEPDIR)/%-debug.d)
$(DEPFILES):

include $(wildcard $(DEPFILES))
