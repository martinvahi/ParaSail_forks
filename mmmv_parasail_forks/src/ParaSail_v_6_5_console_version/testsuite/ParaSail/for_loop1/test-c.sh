# The locale specified by the environment affects sort order.
export Set LC_ALL=C
COMPILE="../../support/compile.sh"
 
$COMPILE for_loop1.psl
./psl.exe | sort
