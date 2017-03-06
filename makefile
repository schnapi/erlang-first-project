#
# Makefile for ...
#
APPCFG = ./rel/files/linux/app.config
VMARGS = ./rel/files/common/vm.args

all:
	./rebar3 get-deps
	./rebar3 compile

shell:
	./rebar3 compile && ./start.sh

release:
	relx --sys_config $(APPCFG) --vm_args $(VMARGS)
