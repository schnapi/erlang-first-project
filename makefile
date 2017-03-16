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

dialyzer_plt:
	dialyzer --output_plt my.plt --build_plt --apps erts kernel stdlib syntax_tools crypto ssl asn1 public_key compiler

dialyzer:
	@rm -rf _build/default/lib/mu/ebin/testdir/
	@mkdir _build/default/lib/mu/ebin/testdir
	@mv _build/default/lib/mu/ebin/*view* _build/default/lib/mu/ebin/testdir/
	./rebar3 dialyzer
	@mv _build/default/lib/mu/ebin/testdir/* _build/default/lib/mu/ebin/
	@rmdir _build/default/lib/mu/ebin/testdir/
