#! /bin/tcsh -fe

# analyze parasail files
# call with "-h" for help

# scope.csh must be in your path
set dir_called_from = $cwd
set script_loc = "$0"
set bin_dir = $script_loc:h

cd $bin_dir
set bin_dir = $cwd
cd $dir_called_from

set psl_dir = $bin_dir:h
if ("$psl_dir:t" == "install") then
   set psl_dir = $psl_dir:h
endif

# TODO: version
set version_string = "ParaScope static checker of programming errors v1.0"
alias print_help eval '\
echo "valid flags are"\
echo "  -i             Use the interpreter to execute parascope,"\
echo "                 even if bin/parascope.exe exists."\
echo "  -l             Linear: do not analyze files in parallel."\
echo "  -v             Print version information"\
echo "  -h             Print this help message"'

# Give help if no parameters
if ("$#" == 0) then
   echo $version_string
   print_help
   exit
endif

# a ':' following a letter means that letter takes an argument
set valid_flags = "ilvh"
set argv = `getopt $valid_flags $*`
# TODO: full word arguments with --.
# get opt puts all the options before a -- and all the operands after

# if getopt failed then $? would be nonzero
# if getopt failed then we should fail as well
if ("$?" != 0) then
   echo $version_string
   print_help
   exit "$?"
endif

# default values:

# ParaScope Flags
set scope_flags = ""

# interpret the compiler or use the compiled compiler
set use_interpreter = 0

# loop over all command line arguments
while ("$1" != "--")
   switch ($1)
      case "-i":
         # use the interpreted parascope
         # instead of the compiled parascope
         set use_interpreter = 1
         breaksw
      case "-l":
         # tell parascope to run loop forward instead of concurrent
         set scope_flags = ($scope_flags '"'"--forward"'"')
         breaksw
      # TODO: case "--version":
      case "-v":
         # print version info and quit
         echo $version_string
         exit
      # TODO: case "--help":
      case "-h":
         # print help info and quit
         echo $version_string
         print_help
         exit
   endsw
   shift
end
shift # ignore the -- that separates arguments and files
# now, $* only contains files, not arguments

set standard_library = "$psl_dir/lib/aaa.psi"
set scope_srcs = "$psl_dir/lib/reflection.ps? $psl_dir/lib/vn_il.ps? $psl_dir/lib/psvm_debugging.ps? $psl_dir/lib/parascope.ps?"

set scope_and_deps = "$standard_library $scope_srcs"

set to_be_analyzed = ($*)

if (! -e $psl_dir/bin/parascope.exe) then
   set use_interpreter = 1
endif

# run parascope
if ($use_interpreter == 1) then
   $psl_dir/build/bin/parasail_main $scope_and_deps $to_be_analyzed -command Analyze $scope_flags $to_be_analyzed
else
   $psl_dir/bin/parascope.exe $standard_library $to_be_analyzed $psl_dir/lib/compiled_main.psl -command Compiled_Main $psl_flags $to_be_analyzed
endif

if ("$?" != 0) then
   exit "$?"
endif

