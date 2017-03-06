#!/bin/bash
# pot kjer je prevedena vaša aplikacija
RUN_DIR=./_build/default/lib
# naslov na katerem bo erlang poslušal za povezovanje v cluster
ERLHOST="127.0.0.1"
# poiščemo erlang na sistemu, lahko tudi napišete celotno pot do erl
ERL=`which erl`
# zagon erlang izvajalnega okolja, kjer so parametri
# cookie - deljena skrivnost znotraj clustra. samo node-i, ki poznajo skrivnost se med sabo lahko povežejo
# -smp vključeno simterično multiprocesiranje
# -pa imeniki kjer iščemo module
# -config konfiguracijska datoteka aplikacij
# -s modul, kateri ima med izvoženimi funkcijami funkcijo start(), ta bo pognala vse potrebne ostale aplikacije
# -name kako bo naš trenutni streženik viden v clustru z več erlang nodei
exec $ERL -setcookie myapp_secret -smp enable -pa $RUN_DIR/*/ebin \
     -config ./default.config -s mu -name mu-node@$ERLHOST
