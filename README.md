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
