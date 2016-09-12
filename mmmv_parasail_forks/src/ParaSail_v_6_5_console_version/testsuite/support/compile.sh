#!/bin/bash

ALL_FILES=$*
ALL_INTERFACES=""
ALL_BODIES=""
SUPPORT_DIR="../../support"
ERROR=0

# Check availability of all the source files

for FILE in $ALL_FILES; do
   if ! test -f $FILE; then
      echo "error: file not found ($FILE)"
      exit -1
   fi

   filename=$(basename $FILE)
   extension="${filename##*.}"
   # filename="${filename%.*}"

   case $extension in
      "psi") ALL_INTERFACES="$ALL_INTERFACES $FILE"
             ;;
      "psl") ALL_BODIES="$ALL_BODIES $FILE"
             ;;
   esac
done

# Compile: stage 1

../../../build/bin/parasail_main ../tmp.rts/aaa*.ps? \
   ../tmp.rts/reflection.ps? \
   ../tmp.rts/vn_il*.ps? \
   ../tmp.rts/llvm_printer.ps? \
   ../tmp.rts/compiler.ps? \
   $ALL_FILES \
   -command Compile $ALL_BODIES

# Compile: stage 2

case $? in
   0) for FILE in $ALL_FILES; do
         if test -f $FILE.ll; then
            llc -asm-verbose -O0 $FILE.ll
            case $? in
               0) ;;
               *) ERROR=1;;
            esac

            if test -f $FILE.s; then
               clang -c -g $FILE.s
               case $? in
                  0) ;;
                  *) ERROR=1;;
               esac
            fi
         fi
      done

      case $ERROR in
         0) OBJS="../tmp.rts/*.o *.o"
            ADAFLAGS="-p -g -O0 -gnato -gnata -gnatE -gnat95"

            cp $SUPPORT_DIR/compiled_main.gpr .
            gnatmake -q $ADAFLAGS -P compiled_main.gpr \
              -o psl.exe -largs $OBJS -lm
            ;;
         *) ;;
      esac
      ;;

   *) ;;
esac
