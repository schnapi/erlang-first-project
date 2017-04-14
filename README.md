mocenum
=====

1) make  
2) ./start.sh  
or make shell
Server is running on: http://localhost:8080/  

autocompiler:
include this in every file  
-include("../include/mu.hrl").

dialyzer:
first time: make dialyzer_plt
everytime you want to use dialyzer: make dialyzer

mu_db:check_schema() or upgrade_schema() ->sometimes doesn't work:
./resetDatabase.sh
5) mu_db:upgrade_schema().


https://github.com/logaretm/vee-validate

nodejs update ubuntu...
https://github.com/nodesource/distributions/tree/master/deb
