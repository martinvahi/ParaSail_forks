# The locale specified by the environment affects sort order.
export Set LC_ALL=C
COMPILE="../../support/compile.sh"
 
$COMPILE div_con.psl
./psl.exe | sort
