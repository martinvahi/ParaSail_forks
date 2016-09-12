------------------------------------------------------------------------------
--                              P A R A S A I L                             --
--                                                                          --
--                     Copyright (C) 2012-2015, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
--                                                                          --
-- The ParaSail language and implementation were originally developed by    --
-- S. Tucker Taft.                                                          --
------------------------------------------------------------------------------

with Ada.Exceptions;
with Ada.Tags;
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Text_IO.Text_Streams;

with PSC.Hash_Tables;
with PSC.Interpretations;
with PSC.Interpreter;
with PSC.Interpreter.Builtins;
with PSC.Languages;
with PSC.Messages;
with PSC.Object_Access;
with PSC.Strings;                     use type PSC.Strings.U_String;
with PSC.String_Streams;
with PSC.Stream_Output;
with PSC.Symbols;                     use PSC.Symbols;

with PSC.Trees.Lists;
with PSC.Trees.Semantics.Debug;
with PSC.Trees.Semantics.Dynamic;
with PSC.Trees.Visitor;

with PSC.Trees.Annotation;
with PSC.Trees.Assign_Stmt;
pragma Elaborate (PSC.Trees.Assign_Stmt);
with PSC.Trees.Binary;
with PSC.Trees.Block_Stmt;
with PSC.Trees.Case_Construct;
with PSC.Trees.Control_Stmt;
with PSC.Trees.Conditional;
with PSC.Trees.For_Loop_Construct;
with PSC.Trees.Identifier;
with PSC.Trees.Implements_Element;
with PSC.Trees.Invocation;
with PSC.Trees.Iterator;
with PSC.Trees.Module;
with PSC.Trees.Operation;
with PSC.Trees.Obj_Decl;
with PSC.Trees.Param_Decl;
with PSC.Trees.Qualifier;
with PSC.Trees.Qualified_Name;
with PSC.Trees.Reference;
with PSC.Trees.Selection;
with PSC.Trees.Type_Decl;
with PSC.Trees.Unary;
with PSC.Trees.While_Stmt;

with PSC.Vectors;

pragma Elaborate (Ada.Text_IO);
pragma Elaborate (PSC.Strings);
pragma Elaborate (PSC.Trees.Binary);

package body PSC.Trees.Semantics.Static is

   --  Static Semantics

   use Semantics.Debug;
   use type Languages.Language_Enum;

   ------------------------------------

   Current_Module : Module_Sem_Ptr := null;
   --  Used as a fall back for Find_Enclosing_Module in 2nd pass

   Last_Import_Clauses : Lists.List := Lists.Empty_List;
   --  Import clauses on prior module/operation

   Any_Str : Strings.U_String;
   Any_Type : Type_Sem_Ptr := null;

   Assignable_Str : Strings.U_String;
   Assignable_Type : Type_Sem_Ptr := null;

   Boolean_Str : Strings.U_String;
   Boolean_Type : Type_Sem_Ptr := null;

   Ordering_Str : Strings.U_String;
   Ordering_Type : Type_Sem_Ptr := null;

   Univ_Integer_Str : Strings.U_String;

   Univ_Real_Str : Strings.U_String;

   Univ_Character_Str : Strings.U_String;

   Univ_String_Str : Strings.U_String;

   Univ_Enumeration_Str : Strings.U_String;

   Optional_Str : Strings.U_String;

   Null_Str : Strings.U_String;

   Integer_Str : Strings.U_String;
   Integer_Current_Instance : Type_Sem_Ptr;

   Float_Str : Strings.U_String;
   Float_Current_Instance : Type_Sem_Ptr;

   Basic_Array_Str : Strings.U_String;
   Basic_Array_Current_Instance : Type_Sem_Ptr;

   From_Univ_Str : Strings.U_String;
   --  Operator for converting from a universal type

   To_Univ_Str : Strings.U_String;
   --  Operator for converting to a universal type

   Plus_Op_Str : constant Strings.U_String :=
     Binary.Binary_Operator_Designator (Binary.Plus_Op);
   --  "+" operator

   Minus_Op_Str : constant Strings.U_String :=
     Binary.Binary_Operator_Designator (Binary.Minus_Op);
   --  "-" operator

   Star_Str : constant Strings.U_String :=
     Strings.String_Lookup ("*");
   --  "*" as used in import clause

   Univ_Container_Op_Str : constant Strings.U_String :=
     Strings.String_Lookup ("""[..]""");
   --  "[..]" operator

   Univ_Map_Set_Op_Str : constant Strings.U_String :=
     Strings.String_Lookup ("""{..}""");
   --  "{..}" operator

   Univ_Op_Strs : constant array
     (Invocation.Container_Aggregate .. Invocation.Map_Set_Aggregate)
       of Strings.U_String :=
         (Invocation.Container_Aggregate => Univ_Container_Op_Str,
          Invocation.Map_Set_Aggregate   => Univ_Map_Set_Op_Str);

   To_Bool_String : constant String := """to_bool""";

   To_Bool_Str : constant Strings.U_String :=
     Strings.String_Lookup (To_Bool_String);
   --  Operator for converting Ordering to Boolean

   Cond_Mask_Str : constant array (Binary.Relational_Ops) of Strings.U_String
      :=
     (Binary.Less_Op => Strings.String_Lookup ("2#0001#"),
      Binary.LEQ_Op => Strings.String_Lookup ("2#0011#"),
      Binary.Equal_Op => Strings.String_Lookup ("2#0010#"),
      Binary.NEQ_Op => Strings.String_Lookup ("2#1101#"),
      Binary.GEQ_Op => Strings.String_Lookup ("2#0110#"),
      Binary.Greater_Op => Strings.String_Lookup ("2#0100#"));
   --  Masks to use for various relational operators

   Remove_First_Str : Strings.U_String;
   --  Operation for "forward" iteration through a set

   Remove_Last_Str : Strings.U_String;
   --  Operation for "reverse" iteration through a set

   Remove_Any_Str : Strings.U_String;
   --  Operation for "unordered" and "concurrent" iteration through a set

   Remove_Func_Strs : array (Interpreter.Direction) of Strings.U_String;
   --  U_String for name of operation used to
   --  remove elements from set in desired order,
   --  based on "direction" of iteration (forward/reverse/etc.)

   Direction_Names : constant
     array (Interpreter.Direction) of Strings.U_String :=
     (Interpreter.Unordered_Dir => Strings.Null_U_String,
      Interpreter.Forward_Dir => Strings.String_Lookup ("forward"),
      Interpreter.Reverse_Dir => Strings.String_Lookup ("reverse"),
      Interpreter.Concurrent_Dir => Strings.String_Lookup ("concurrent"));
   --  These are the names used for the different directions
   --  of iteration.

   type Interp_Comparison_Enum is
     (Prefer_Prior, Prefer_New, Interps_Are_Equiv, Interps_Are_Ambig);
   --  Enumeration of result of Compare_Interps when there might be multiple
   --  interpretations for the same construct.

   ---------------- Local subprograms --------------

   function Generate_Unique_Label
     (Pos : Source_Positions.Source_Position;
      Preceding : String;
      Include_File : Boolean := False) return Strings.U_String is
      --  This image includes a leading space
      Line_Image_Space : constant String :=
         Source_Positions.Line_Number'Image (Pos.Line);
      --  Remove the space
      Line_Image : String renames Line_Image_Space
         (Line_Image_Space'First + 1 .. Line_Image_Space'Last);
      --  Same with Column
      Col_Image_Space : constant String :=
         Source_Positions.Column_Number'Image (Pos.Col);
      Col_Image : String renames Col_Image_Space
         (Col_Image_Space'First + 1 .. Col_Image_Space'Last);
   begin
      if not Include_File then
         return Strings.String_Lookup
                  (Preceding & Line_Image & '_' & Col_Image);
      else
         declare
            File_Image_Space : constant String :=
              Strings.U_String_Index'Image (Pos.File);
            File_Image : String renames File_Image_Space
              (File_Image_Space'First + 1 .. File_Image_Space'Last);
         begin
            return Strings.String_Lookup
              (Preceding & File_Image & '_' & Line_Image & '_' & Col_Image);
         end;
      end if;
   end Generate_Unique_Label;

   procedure Finish_Type_Sem_Info
     (Type_Sem : Type_Sem_Ptr;
      Decl_Region : Region_Ptr := null);
      --  Fill in U_Base_Type and U_Type, and then add type to
      --  Nested_Type list, or Actual_Of_Formals list, as appropriate

   function Qualify_Type (Original_Type : Type_Sem_Ptr;
     Decl_Region : Symbols.Region_Ptr;
     Definition : Optional_Tree := Null_Optional_Tree;
     Is_Optional : Boolean := False;
     Is_Concurrent : Boolean := False;
     Is_Polymorphic : Boolean := False) return Type_Sem_Ptr;
   --  Create a new type with the specified qualifiers added in

   function Type_Implements_Type
     (Actual_Type : Type_Sem_Ptr;
      Formal_Type : Type_Sem_Ptr;
      Check_Parameterless_Modules : Boolean := False;
      Allow_Abstract : Boolean := False;
      No_Implementing_Ops : Boolean := False)
      return Boolean;
   --  Return True if Actual_Type is acceptable as a parameter
   --  for the given Formal_Type.
   --  If Formal_Type is from a parameterless module, then
   --  check to be sure Actual_Type has all of the necessary
   --  operations only if Check_Parameterless_Modules is True
   --  If No_Implementing_Ops is True, then ignore operations from
   --  the "implements for" section.

   function Param_Map_Of
     (Param_Sem : Sem_Ptr;
      Map : Param_Mapping_Ptr)
      return Sem_Ptr
   is
      --  Return mapping of Param_Sem implied by Map.
      --  Return Param_Sem itself if not found in the Map.
      M : Param_Mapping_Ptr := Map;
   begin
      if Param_Sem = null then
         return null;
      end if;
      while M /= null and then M.From /= null loop
         if M.From = Param_Sem then
            --  Found it
            return M.To;
         end if;
         if M.From.all in Type_Semantic_Info
           and then Param_Sem.all in Type_Semantic_Info
         then
            --  See whether Param_Sem matches some ancestor of M.From.
            declare
               Param_Type : constant Type_Sem_Ptr := Type_Sem_Ptr (Param_Sem);
               From_Ancestor : Type_Sem_Ptr := Type_Sem_Ptr (M.From);
               To_Ancestor : Type_Sem_Ptr := Type_Sem_Ptr (M.To);
            begin
               while From_Ancestor /= null and then To_Ancestor /= null loop
                  if Param_Type.U_Base_Type = From_Ancestor.U_Base_Type
                    and then Param_Type.Is_Polymorphic =
                               From_Ancestor.Is_Polymorphic
                  then
                     --  Found a match
                     return Sem_Ptr (Qualify_Type (To_Ancestor,
                       Decl_Region => null,
                       Is_Optional => Param_Type.Value_Is_Optional,
                       Is_Concurrent => Param_Type.Obj_Is_Concurrent));
                  end if;
                  From_Ancestor := From_Ancestor.Parent_Type;
                  To_Ancestor := To_Ancestor.Parent_Type;
               end loop;
            end;
         end if;
         M := M.Next;
      end loop;
      --  Not in the map
      return Param_Sem;
   end Param_Map_Of;

   function Is_In_Param_Map
     (Param_Sem : Sem_Ptr;
      Map : Param_Mapping_Ptr)
      return Boolean
   is
   --  Return True if Param_Sem matches the "From"
   --  sem of some mapping in the map.
   begin
      return Param_Map_Of (Param_Sem, Map) /= Param_Sem;
   end Is_In_Param_Map;

   function Type_Map_Of
     (Param_Type : Type_Sem_Ptr;
      Map : Param_Mapping_Ptr)
      return Type_Sem_Ptr
   is
      --  Return mapping of Param_Type implied by Map.
      --  Return Param_Type itself if not found in the Map.
      M : Param_Mapping_Ptr := Map;
   begin
      while M /= null loop
         if M.From = Sem_Ptr (Param_Type.U_Base_Type) then
            --  Found it
            declare
               To_Type : constant Type_Sem_Ptr := Type_Sem_Ptr (M.To);
            begin
               --  Return base type if filled in.
               if To_Type.U_Base_Type /= null then
                  return To_Type.U_Base_Type;
               else
                  return To_Type;
               end if;
            end;
         end if;
         M := M.Next;
      end loop;
      --  Not in the map
      return Param_Type;
   end Type_Map_Of;

   function Reordered_Param_Map
     (Result_Param_Map : Param_Mapping_Ptr;
      Orig_Param_Map : Param_Mapping_Ptr)
      return Param_Mapping_Ptr
   is
   --  Return Result_Param_Map, but move newly added
   --  elements to end, because output params actually come
   --  first in the symbol list, and this list is supposed to
   --  be in reverse order of the symbol order.
   begin
      if Orig_Param_Map = null
        or else Result_Param_Map = Orig_Param_Map
      then
         --  Nothing to do since orig map was empty or nothing was added
         return Result_Param_Map;
      else
         --  Append part of Result_Param_Map that is new
         --  onto copy of Orig_Param_Map
         declare
            M : Param_Mapping_Ptr := Orig_Param_Map;
            R : Param_Mapping_Ptr := Result_Param_Map;
            New_R : constant Param_Mapping_Ptr := new Param_Mapping'(M.all);
            Next_New_R : Param_Mapping_Ptr := New_R;
         begin
            --  Copy original list
            while M.Next /= null loop
               Next_New_R.Next := new Param_Mapping'(M.Next.all);
               M := M.Next;
               Next_New_R := Next_New_R.Next;
            end loop;
            --  Find end of new items
            while R.Next /= Orig_Param_Map loop
               R := R.Next;
            end loop;

            --  Terminate new list of items and
            --  append to copy of orig list.
            R.Next := null;
            Next_New_R.Next := Result_Param_Map;

            --  Return copy of original list with new part appended
            if Debug_Second_Pass then
               Put_Line
                 (" Reordered param map, original = " &
                  Param_Map_Image (Orig_Param_Map) &
                  " + " &
                  Param_Map_Image (Result_Param_Map) &
                  " ==> " &
                  Param_Map_Image (New_R));
            end if;
            return New_R;
         end;
      end if;
   end Reordered_Param_Map;

   function Interface_Part
     (Module_Sem : Module_Sem_Ptr)
      return Module_Sem_Ptr
   is
   --  Return Interface part, if any of given module.
   begin
      if Module_Sem = null
        or else Module_Sem.Is_Interface
        or else Module_Sem.Other_Part = null
      then
         --  Already have interface, if there is one
         return Module_Sem;
      else
         --  Return interface
         return Module_Sem.Other_Part;
      end if;
   end Interface_Part;

   function Num_Module_Parameters (Mod_Sem : Module_Sem_Ptr) return Natural is
   --  Return number of formals, including any inherited ones.
   begin
      if Mod_Sem.Num_Module_Parameters < 0 then
         --  Hasn't been computed yet
         declare
            Module_Tree : Module.Tree renames Module.Tree (Tree_Ptr_Of
                                                              (Mod_Sem.
              Definition).all);
         begin
            if Module_Tree.Is_Interface
              or else Mod_Sem.Other_Part = null
            then
               Mod_Sem.Num_Module_Parameters :=
                 Lists.Length (Module_Tree.Module_Formals) +
                 Lists.Length (Mod_Sem.Ancestor_Module_Formals);
            else
               Mod_Sem.Num_Module_Parameters :=
                  Num_Module_Parameters (Mod_Sem.Other_Part);
            end if;
         end;
      end if;
      return Mod_Sem.Num_Module_Parameters;
   end Num_Module_Parameters;

   function Nth_Module_Parameter
     (Mod_Sem : Module_Sem_Ptr;
      N : Positive)
      return Optional_Tree
   is
      --  Return Nth module parameter, including ancestor module formals
      --  if any
      Num_Inherited_Params : constant Natural :=
        Lists.Length (Mod_Sem.Ancestor_Module_Formals);
   begin
      if N <= Num_Inherited_Params then
         return Lists.Nth_Element (Mod_Sem.Ancestor_Module_Formals, N);
      else
         return Lists.Nth_Element
                  (Module.Tree (Tree_Ptr_Of (Mod_Sem.Definition).all).
           Module_Formals,
                   N - Num_Inherited_Params);
      end if;
   end Nth_Module_Parameter;

   function Corresponding_Ancestor_Type
     (Descendant_Type : Type_Sem_Ptr;
      Ancestor_Module : Module_Sem_Ptr)
      return Type_Sem_Ptr
   is
      --  Follow the Parent_Type chain up from Descendant_Type
      --  until finding a type associated with the given Ancestor_Module
      Anc_Type : Type_Sem_Ptr := Descendant_Type;
   begin
      while Anc_Type /= null loop
         if Anc_Type.Associated_Module = Ancestor_Module then
            --  Found it
            return Anc_Type;
         end if;
         Anc_Type := Anc_Type.Parent_Type;
      end loop;
      --  Should have found the ancestor
      pragma Assert (False);
      return null;
   end Corresponding_Ancestor_Type;

   function Is_Proper_Ancestor
     (Ancestor, Descendant : Module_Sem_Ptr)
      return Boolean
   is
      --  Return True if Ancestor is an ancestor of Descendant,
      --  and not equal to Descendant.
      Mod_Sem : Module_Sem_Ptr := Interface_Part (Descendant);
      Ancest_If : constant Module_Sem_Ptr := Interface_Part (Ancestor);
   begin
      while Mod_Sem /= null loop
         Mod_Sem := Mod_Sem.Parent_Module;
         if Mod_Sem = Ancest_If then
            --  Ancestor is a proper ancestor of Descendant
            return True;
         end if;
      end loop;
      --  Not a proper ancestor
      return False;
   end Is_Proper_Ancestor;

   function Is_Ancestor
     (Ancestor, Descendant : Module_Sem_Ptr)
      return Boolean
   is
      --  Return True if Ancestor is an ancestor of Descendant,
      --  or equal to Descendant.
      Ancest_If : constant Module_Sem_Ptr := Interface_Part (Ancestor);
      Desc_If : constant Module_Sem_Ptr := Interface_Part (Descendant);
   begin
      return Ancest_If = Desc_If
            or else Is_Proper_Ancestor
                       (Ancestor => Ancest_If,
                        Descendant => Desc_If);
   end Is_Ancestor;

   function Is_Orig_Type_For_Ancestor
      (Ancestor, Descendant : Type_Sem_Ptr)
        return Boolean is
   --  Return True if Ancestor is the "original" type for
   --  some ancestor of Descendant, where "original" means
   --  a "current-instance" type, or a "new" type that matches
   --  the Sem_Info of its associated symbol.
   --  TBD: This currently only applies to ancestors connected through
   --       a chain of non-extending "new"s; should allow "wrapper" children.
   --  The Descendant type inherits operations from such an ancestor
   --  after systematically replacing the ancestor with the descendant type.
   begin
      if Ancestor = null or else Descendant = null
        or else Ancestor.Associated_Module = null
        or else Ancestor.Associated_Module /= Descendant.Associated_Module
      then
         --  TBD: We ignore ancestors based on a different module.
         --       (i.e. not talking about extensions here)
         return False;
      elsif Types_Match
        (Ancestor, Ancestor.Associated_Module.Cur_Inst_Sem)
      then
         --  If Ancestor is a current-instance type,
         --  then Descendant inherits from it.
         return True;
      elsif Types_Match
        (Ancestor, Type_Sem_Ptr (Ancestor.Associated_Symbol.Sem_Info))
      then
         --  Ancestor is an "original" type (not result of an instantiation).
         --  See if ancestor's New_Type_Counter is on chain of parents.
         declare
            Some_Anc : Type_Sem_Ptr := Descendant;
         begin
            while Some_Anc /= null
              and then Some_Anc.New_Type_Counter > Ancestor.New_Type_Counter
            loop
               --  Not reached it yet, keep following the chain.
               Some_Anc := Some_Anc.Parent_Type;
            end loop;
            --  Check for exact match of "new" type counter.
            return Some_Anc.New_Type_Counter = Ancestor.New_Type_Counter;
         end;
      else
         --  We don't inherit from this type
         return False;
      end if;
   end Is_Orig_Type_For_Ancestor;

   function Inherit_Decl
     (Decl : Optional_Tree;
      Parent_Module, New_Module : Module_Sem_Ptr := null)
      return Optional_Tree;
   --  Copy a declaration, as part of inheritance.
   --  If Parent_Module and New_Module are specified, then
   --  substitute appearances of the parent module in the
   --  declaration with the new module, as appropriate to the
   --  kind of declaration.

   function Inherit_Decl_List
     (Decl_List : Lists.List;
      Parent_Module, New_Module : Module_Sem_Ptr := null)
      return Lists.List;
   --  Copy list of declarations, as part of inheritance.
   --  If Parent_Module and New_Module are specified, then
   --  substitute appearances of the parent module in the
   --  declarations with the new module, as appropriate to the
   --  kind of declaration.
   --  Suppress declarations that are not inherited, such
   --  as operations with no current-inst parameters.
   --  TBD: Include polymorphic operations after substituting only for
   --      first polymorphic input.

   procedure Builtin_Type_Init
     (New_Mod_Sem : Module_Sem_Ptr;
      Builtin_Str : Strings.U_String;
      Builtin_Type : in out Type_Sem_Ptr) is
      --  Initialize a builtin type based on name
      use type Strings.U_String;
   begin
      if New_Mod_Sem.Associated_Symbol.Str = Builtin_Str then
         declare
            Name : constant String := Strings.To_String (Builtin_Str);
         begin
            if Languages.Is_Univ_Module_Name (Name) then
               --  Should be marked as a "universal" type
               --   (and known-to-be-small)
               New_Mod_Sem.Cur_Inst_Sem.Is_Universal := True;
               New_Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small :=
                 Name /= Languages.Univ_String_Module_Name;
                   --  Univ_String might use the "large" representation.
                   --  TBD: Univ_Integer might as well some day.
               New_Mod_Sem.Cur_Inst_Sem.Known_To_Be_Assignable := True;
               New_Mod_Sem.Cur_Inst_Sem.All_Parameters_Known := True;
               New_Mod_Sem.Cur_Inst_Sem.Is_Formal_Type := False;
            end if;

            if Builtin_Type = null then
               --  Remember definition for later use
               Builtin_Type := New_Mod_Sem.Cur_Inst_Sem;

               if Builtin_Str /= Any_Str
                 and then
                  --  not New_Mod_Sem.Is_Concurrent and then
                  Num_Module_Parameters (New_Mod_Sem) = 0
               then
                  --  All of the parameter-less non-concurrent builtin
                  --  types are assignable, except "Any"
                  New_Mod_Sem.Cur_Inst_Sem.Known_To_Be_Assignable := True;
               end if;

               if Debug_First_Pass then
                  Ada.Text_IO.Put_Line
                    (" This module defines the " & Name & " type");
               end if;
            end if;
         end;
      end if;
   end Builtin_Type_Init;

   function Param_Is_Passed_By_Ref
     (Param_Sem : Param_Sem_Ptr;
      Kind : Param_Decl.Param_Kind;
      Locking : Param_Decl.Param_Locking)
      return Boolean
   is
      --  Whether parameter is passed by reference.
      --  NOTE: We don't allow whole-object assignment to concurrent objects
      --       because that would require a lock, but be that as it may,
      --       we will pass by reference to avoid problems when a module
      --       might have either a concurrent or non-concurrent parameter.
      --  TBD:  This doesn't really make sense.  No reason not to
      --       allow whole-object assignment when the object is locked.
      --       There might be a bit of an issue of preserving the lock
      --       and the queued calls, so the assignment would have to
      --       preserve these two things.  But at the user level we should
      --       allow it.  But I suppose that could be accomplished
      --       without having to pass by reference, by doing a block
      --       assignment.  Probably need a new instruction for that,
      --       Even if we *do* pass by reference, we might not want to
      --       take advantage of it to avoid the full
      --       deallocation/reallocation, and in case the preexisting
      --       object is a concurrent object, even if the module is not.
      use Param_Decl;
   begin
      if Param_Sem.Is_By_Ref_Choice_Param then
         return True;
      elsif Kind = Default_Param then
         return False;
      elsif Kind = Var_Param
        and then Param_Sem.Resolved_Type.Is_Polymorphic
        and then not Param_Sem.Resolved_Type.Value_Is_Optional
      then
         --  Non-optional polymorphic var params are *not* passed by reference
         --  since they might be a wrapper
         return False;
      else
         return Param_Sem.Resolved_Type.Known_To_Be_Assignable;
         --  TBD: What if this parameter is passed to a caller
         --      provided operation which has a assignability mismatch?
         --      It seems we will have to check that when passing
         --      an operation formal, and perhaps create a wrapper
         --      or disallow it if the assignability doesn't match.
         --      ==> This would argue for only passing by-ref if
         --      the formal is of an optional type, since only then
         --      do we need to worry about pointing to a completely
         --      different object.  Hmmm... Small var parameters clearly
         --      need to be passed by reference, though I guess by-copy
         --      in-out is another possibility, but that would require
         --      by-copy in-out in all cases -- actually,
         --      that *could* work, and generalizes to cross-address
         --      space more naturally.  Also, we already copy back
         --      the output parameters, so copying back the "var"
         --      parameters would be easy enough.
         --
         --      "ref"s really do need to be by-ref, though we have
         --      seen a desire to handle packing and persistence by
         --      returning something which is in fact a copy, and
         --      if updated, is stored back.  So maybe going away
         --      from by-ref completely is worth considering, or
         --      making an actual simple "ref T" always be a
         --      polymorphic object of type Ref<T>+, while "var" is
         --      always copy in/out.  Since you never assign to
         --      a "ref" (only to the thing it designates), we can
         --      allocate refs on the local area stack if we want.
      end if;
   end Param_Is_Passed_By_Ref;

   function Sym_Is_Declared_Ref (Id_Sym : Symbols.Sym_Ptr) return Boolean is
      --  Return True if sym is declared as a "ref" whether or not it
      --  is represented as a "ref."
      use type Param_Decl.Param_Kind;
      use Symbols;
   begin
      case Id_Sym.Kind is
         when Param_Sym_Kind =>
            declare
               Param_Tree : Param_Decl.Tree
                 renames Param_Decl.Tree (Tree_Ptr_Of (Id_Sym.Definition).all);
            begin
               --  Return True if parameter refers to a particular preexisting
               --  object (perhaps via a component), and a ref to that object
               --  can be returned (perhaps bundled in a larger object).
               --  This does not mean it is actually passed by ref, but rather
               --  that it refers to a particular preexisting object, rather
               --  than to potentially a copy of the object.
               return Param_Tree.Kind in Param_Decl.Ref_Param_Kinds
                 or else Id_Sym.Enclosing_Region.Kind = Case_Stmt_Region_Kind;
                  --  Case statement choice parameters are always treated
                  --  as "ref"s to the case expression.
            end;
         when Loop_Param_Sym_Kind =>
            return Iterator.Tree (Tree_Ptr_Of (Id_Sym.Definition).all).Is_Ref;
         when Loop_Key_Param_Sym_Kind =>
            --  The Key of [Key => Value] is always passed by value.
            return False;
         when Module_Ancestor_Sym_Kind =>
            --  Parent part is always considered a value, not a ref.
            return False;
         when Component_Sym_Kind | Object_Sym_Kind =>
            return Obj_Decl.Tree (Tree_Ptr_Of (Id_Sym.Definition).all).Is_Ref;
         when No_Sym_Kind        |
              Module_Sym_Kind    |
              Type_Sym_Kind      |
              Operation_Sym_Kind |
              Literal_Sym_Kind   |
              Statement_Sym_Kind =>
            return False;
      end case;
   end Sym_Is_Declared_Ref;

   function Sym_Is_By_Ref (Id_Sym : Symbols.Sym_Ptr) return Boolean is
      --  Return True if sym is represented as a "ref" rather than a value.
      --  NOTE: Even if object is declared using "ref", it is represented
      --       as a value instead if the object contains a ref component,
      --       or the object is concurrent.
      --  TBD: At some point we might use by-copy-in-out for almost everything.
      --       Of course for a large object, this is just copying the pointer
      --       (rather than passing a pointer to the pointer).
      --       Concurrent objects might be an issue, but only if we allow
      --       them to be assigned a completely new object, which would be
      --       weird, except when the object is locked, in which case we
      --       are effectively back in the no-aliasing world.
      use type Param_Decl.Param_Kind;
      use Symbols;
   begin
      case Id_Sym.Kind is
         when Param_Sym_Kind =>
            declare
               Param_Tree : Param_Decl.Tree
                 renames Param_Decl.Tree (Tree_Ptr_Of (Id_Sym.Definition).all);
            begin
               --  Depends on both kind of param and on whether it is locked.
               return Param_Is_Passed_By_Ref
                        (Param_Sem_Ptr (Id_Sym.Sem_Info),
                         Param_Tree.Kind,
                         Param_Tree.Locking);
            end;
         when Loop_Param_Sym_Kind =>
            return Iterator.Tree (Tree_Ptr_Of (Id_Sym.Definition).all).Is_Ref
               and then
                   Iterator_Sem_Ptr (Id_Sym.Sem_Info).Loop_Param_Is_By_Ref;
         when Loop_Key_Param_Sym_Kind =>
            --  The Key of [Key => Value] is always passed by value.
            return False;
         when Module_Ancestor_Sym_Kind =>
            --  Parent part is always represented as a value.
            return False;
         when Component_Sym_Kind | Object_Sym_Kind =>
            return Obj_Decl.Tree (Tree_Ptr_Of (Id_Sym.Definition).all).Is_Ref
                  and then (Object_Sem_Ptr (Id_Sym.Sem_Info).Resolved_Type =
                            null
                           or else
                            Object_Sem_Ptr (Id_Sym.Sem_Info).Resolved_Type.
              Known_To_Be_Assignable);
         --  If not assignable type, then we never represent as a "ref"
         when No_Sym_Kind        |
              Module_Sym_Kind    |
              Type_Sym_Kind      |
              Operation_Sym_Kind |
              Literal_Sym_Kind   |
              Statement_Sym_Kind =>
            return False;
      end case;
   end Sym_Is_By_Ref;

   function Sem_Info_Is_For_Variable (Obj_Sem : Sem_Ptr) return Boolean is
   --  Return True if Obj_Sem identifies an entity that is a variable,
   --  i.e. can be used on LHS of assignment or passed as a "var" parameter.
   begin
      if Obj_Sem.all in Sym_Reference_Info'Class then
         --  Go to underlying Sem info
         return Sem_Info_Is_For_Variable
                  (Sym_Reference_Info (Obj_Sem.all).Underlying_Sem_Info);
      elsif Obj_Sem.all in Selection_Semantic_Info'Class then
         --  Based on component and prefix being a variable
         return Sym_Is_Variable
                   (Selection_Sem_Ptr (Obj_Sem).Comp_Decl.Associated_Symbol,
                    Treat_Ref_As_Variable => True)
               and then Sem_Info_Is_For_Variable
                           (Underlying_Sem_Info
                               (Resolved_Tree
                                   (Selection.Tree (Tree_Ptr_Of
                                      (Obj_Sem.Definition).all).Prefix)));
      elsif Obj_Sem.all in Object_Semantic_Info'Class then
         --  We have an object-like thing, which will determine variability
         return Sym_Is_Variable (Obj_Sem.Associated_Symbol);
      elsif Obj_Sem.all in Call_Semantic_Info'Class
        and then Call_Sem_Ptr (Obj_Sem).Op_Sem /= null
      then
         --  We have a call.  Look at first (and only) output
         declare
            Call_Sem : constant Call_Sem_Ptr := Call_Sem_Ptr (Obj_Sem);
            Op_Tree : Operation.Tree renames Operation.Tree (Tree_Ptr_Of
              (Call_Sem.Op_Sem.Definition).all);
         begin
            if Lists.Length (Op_Tree.Operation_Outputs) /= 1 then
               --  Cannot be a variable if more than one output
               return False;
            else
               declare
                  use Param_Decl;
                  Kind : constant Param_Kind := Param_Decl.Tree (Tree_Ptr_Of
                            (Lists.Nth_Element
                                (Op_Tree.Operation_Outputs, 1)).all).Kind;
               begin
                  case Kind is
                  when Ref_Var_Param =>
                     return True;
                  when Default_Param | Ref_Const_Param =>
                     return False;
                  when Var_Param | Global_Param | Global_Var_Param =>
                     --  Shouldn't happen
                     return False;
                  when Ref_Param =>
                     --  Determined by variable-ness of "ref" operands
                     declare
                        Call_Tree : Invocation.Tree renames Invocation.Tree
                          (Tree_Ptr_Of (Call_Sem.Definition).all);
                     begin
                        for I in 1 .. Lists.Length
                          (Op_Tree.Operation_Inputs) loop
                           if Param_Decl.Tree (Tree_Ptr_Of (Lists.Nth_Element
                             (Op_Tree.Operation_Inputs, I)).all).Kind =
                                Ref_Param
                           then
                              if not Sem_Info_Is_For_Variable
                                (Underlying_Sem_Info (Lists.Nth_Element
                                  (Call_Tree.Operands, I)))
                              then
                                 --  At least one "ref" param is not
                                 --  a variable, so this is not a variable
                                 return False;
                              end if;
                           end if;
                        end loop;
                        --  No "ref" params are constants, so treat
                        --  this "ref" result as a variable.
                        return True;
                     end;
                  end case;
               end;
            end if;
         end;
      else
         --  We don't have an object-like thing, so not a variable.
         return False;
      end if;
   end Sem_Info_Is_For_Variable;

   function Sym_Is_Variable (Id_Sym : Symbols.Sym_Ptr;
     Treat_Ref_As_Variable : Boolean := False) return Boolean is
      --  Return True if sym may appear on LHS of assignment
      --  or be passed as a "var" or "ref var" parameter.
      --  If it is simply a "ref" then return True iff Treat_Ref_As_Variable
      --  is True.
      use type Param_Decl.Param_Kind;
      use Symbols;
   begin
      if Id_Sym = null then
         return False;
      end if;
      case Id_Sym.Kind is
         when Param_Sym_Kind =>
            declare
               Param_Tree : Param_Decl.Tree
                 renames Param_Decl.Tree (Tree_Ptr_Of (Id_Sym.Definition).all);
               Param_Sem : constant Param_Sem_Ptr :=
                 Param_Sem_Ptr (Param_Tree.Sem_Info);
            begin
               if Param_Sem = null then
                  --  Some earlier problem
                  return False;
               elsif Param_Sem.Is_Operation_Output then
                  --  Outputs are by default variables,
                  --  unless they are return-by-ref, in which case the
                  --  designated
                  --  object may only be specified via a return statement.
                  return not Sym_Is_Declared_Ref (Id_Sym);
               elsif Param_Sem.Is_Var_Choice_Param then
                  --  Choice parameters inherit variability of
                  --  case selector expression.
                  return True;
               else
                  --  Inputs are by default read-only.
                  --  Use table in Param_Decl indexed by Param_Kind.
                  return Param_Decl.Param_Is_Var (Param_Tree.Kind);
               end if;
            end;
         when Loop_Param_Sym_Kind =>
            declare
               Iter_Tree : Iterator.Tree renames Iterator.Tree (Tree_Ptr_Of
                                                                   (Id_Sym.
                 Definition).all);
            begin
               return Iter_Tree.Is_Ref
                     and then Sem_Info_Is_For_Variable
                                 (Underlying_Sem_Info
                                     (Resolved_Tree (Iter_Tree.Obj_Value)));
            end;
         when Loop_Key_Param_Sym_Kind =>
            --  The Key of [Key => Value] is always a constant
            return False;
         when Module_Ancestor_Sym_Kind =>
            --  TBD: We should not allow updates when outside the module.
            return True;
         when Component_Sym_Kind | Object_Sym_Kind =>
            --  This is a variable if declared with "var" or
            --  declared with only "ref" and initial value is
            --  a variable.
            declare
               Obj_Tree : Obj_Decl.Tree renames Obj_Decl.Tree (Tree_Ptr_Of
                                                                  (Id_Sym.
                 Definition).all);
            begin
               if Obj_Tree.Is_Var then
                  return True;
               elsif Obj_Tree.Is_Const then
                  return False;
               elsif Treat_Ref_As_Variable then
                  --  The enclosing object is a variable, and this is
                  --  simply "ref" so treat this as a variable.
                  return Obj_Tree.Is_Ref;
               else
                  return Obj_Tree.Is_Ref
                        and then Not_Null (Obj_Tree.Obj_Value)
                        and then Sem_Info_Is_For_Variable
                                    (Underlying_Sem_Info
                                        (Resolved_Tree (Obj_Tree.Obj_Value)));
               end if;
            end;
         when No_Sym_Kind        |
              Module_Sym_Kind    |
              Type_Sym_Kind      |
              Operation_Sym_Kind |
              Literal_Sym_Kind   |
              Statement_Sym_Kind =>
            return False;
      end case;
   end Sym_Is_Variable;

   function Obj_Decl_Is_For_Component
     (Obj : Obj_Decl.Tree;
      Usable_In_Aggregate : Boolean := False)
      return Boolean
   is
   --  Return True if decl immediately within a module is for a component
   --  of the module
   begin
      --  Return True if we have a variable or an uninitialized constant
      --  TBD: What about an initialized "ref"?
      --      I guess that is essentially treated as a global constant?
      --      or could it be a default value for the ref?
      if not Obj.Is_Var and then Not_Null (Obj.Obj_Value) then
         --  Not a component
         return False;
      elsif not Usable_In_Aggregate then
         --  Is a component, and we don't care whether is
         --  usable in aggregate.
         return True;
      else
         --  Check whether component can be used in aggregate.
         --  A component inherited from an ancestor is not usable
         --  unless the component-extension levels match.
         declare
            Comp_Sem : constant Object_Sem_Ptr :=
              Object_Sem_Ptr (Obj.Sem_Info);
            Mod_Sem : constant Module_Sem_Ptr :=
              Module_Sem_Ptr (
              Comp_Sem.Associated_Symbol.Enclosing_Region.Associated_Symbol.
              Sem_Info);
         begin
            return Comp_Sem.Context not in Ancestor_Item_Contexts
                  or else Mod_Sem.Ancestor_Module_With_Constructor = null
                  or else Comp_Sem.Originating_Module.
              Component_Extension_Level =
                          Mod_Sem.Component_Extension_Level;
         end;
      end if;
   end Obj_Decl_Is_For_Component;

   function Decl_Is_For_Component
     (Decl : Optional_Tree;
      Usable_In_Aggregate : Boolean := False)
      return Boolean
   is
      --  Return True if decl immediately within a module is for a component
      --  of the module
      Decl_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Decl).all;
   begin
      if Decl_Tree in Param_Decl.Tree then
         declare
            Param_Sem : constant Param_Sem_Ptr :=
              Param_Sem_Ptr (Decl_Tree.Sem_Info);
         begin
            if Param_Sem /= null
              and then Param_Sem.Associated_Symbol /= null
              and then Param_Sem.Associated_Symbol.Kind =
                       Module_Ancestor_Sym_Kind
            then
               --  Sym represents an ancestor part, but is only usable in
               --  an aggregate if it has been assigned a component index.
               return not Usable_In_Aggregate
                     or else Param_Sem.Component_Index > 0;
            else
               --  Not an ancestor-part component
               return False;
            end if;
         end;
      elsif Decl_Tree not in Obj_Decl.Tree then
         --  Definitely not a component
         return False;
      else
         return Obj_Decl_Is_For_Component
                  (Obj_Decl.Tree (Decl_Tree),
                   Usable_In_Aggregate);
      end if;
   end Decl_Is_For_Component;

   function Sym_Is_Component
     (Sym : Symbols.Sym_Ptr;
      Usable_In_Aggregate : Boolean := False)
      return Boolean
   is
      --  Return True if sym refers to a component of a module
      use Symbols;
   begin
      return Sym.Enclosing_Region.Associated_Symbol /= null
            and then Sym.Enclosing_Region.Associated_Symbol.Kind =
                     Module_Sym_Kind
            and then Decl_Is_For_Component
                        (Sym.Definition,
                         Usable_In_Aggregate);
   end Sym_Is_Component;

   function Operation_Is_Constructor
     (Op_Tree : Operation.Tree;
      Enc_Module : Module_Sem_Ptr;
      With_No_Cur_Inst_Inputs : Boolean := False)
      return Boolean
   is
   --  Return True if Op_Tree is for an operation
   --  that has an output of the current-inst type of the
   --  given module.

   --  If "With_No_Cur_Inst_Inputs" is True, then
   --  only consider it a "constructor" if it has no
   --  cur-inst inputs (i.e. it creates a value of out "thin air").

      function Is_Cur_Inst_Type (Param_Type : Optional_Tree) return Boolean is
      --  Return True if type tree sym matches enclosing module sym
      --  Skip over qualifiers.
      --  TBD: This is purely syntactic at the moment.
      --      It would be nice if we could rely on semantic
      --      information instead.
         Param_Type_Tree : Trees.Tree'Class renames
           Tree_Ptr_Of (Param_Type).all;
      begin
         if Param_Type_Tree in Identifier.Tree
           and then Identifier.Tree (Param_Type_Tree).Str =
                    Enc_Module.Associated_Symbol.Str
         then
            return True;
         elsif Param_Type_Tree in Qualifier.Tree then
            --  Skip over qualifiers unless polymorphic
            return not Qualifier.Tree
                (Param_Type_Tree).Qualifiers (Qualifier.Is_Polymorphic)
              and then
                Is_Cur_Inst_Type (Qualifier.Tree (Param_Type_Tree).Operand);
         elsif Param_Type_Tree in Invocation.Tree then
            declare
               Type_Invoc_Tree : Invocation.Tree renames
                 Invocation.Tree (Param_Type_Tree);
            begin
               return Lists.Length (Type_Invoc_Tree.Operands) = 0
                 and then
                   Not_Null (Type_Invoc_Tree.Prefix)
                 and then
                   Is_Cur_Inst_Type (Type_Invoc_Tree.Prefix);
            end;
         else
            --  Not matching equivalent types
            return False;
         end if;
      end Is_Cur_Inst_Type;

      function Has_Cur_Inst_Operand (Operand_List : Lists.List) return Boolean
      is
      --  Return True if some operand on Operand_List
      --  is of the current-inst type.
      begin
         for J in 1 .. Lists.Length (Operand_List) loop
            declare
               Param_Decl_Tree : Param_Decl.Tree
                 renames Param_Decl.Tree
                   (Tree_Ptr_Of (Lists.Nth_Element
                     (Operand_List, J)).all);
               Param_Type_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                             (Param_Decl_Tree.
                 Param_Type).all;
            begin
               if Is_Cur_Inst_Type (Param_Decl_Tree.Param_Type) then
                  --  Operand's type matches enclosing module
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Cur_Inst_Operand;

   begin  --  Operation_Is_Constructor

      if not Has_Cur_Inst_Operand (Op_Tree.Operation_Outputs) then
         --  No cur-inst outputs
         return False;
      elsif With_No_Cur_Inst_Inputs then
         --  Check if has any cur-inst inputs
         return not Has_Cur_Inst_Operand (Op_Tree.Operation_inputs);
      else
         --  Has an output, and we don't care about inputs
         return True;
      end if;
   end Operation_Is_Constructor;

   function Num_Components (Mod_Sem : Module_Sem_Ptr) return Natural is
      --  Return count of components of given module usable in a class
      --  aggregate.
      --  If the module is an extension of a parent module,
      --  then the nearest ancestor with a constructor is considered the
      --  first component, and then components of proper descendants
      --  of that ancestor form the remaining components.

      Contains_Ref : Boolean := False;

      function Count_Components (L : Lists.List) return Natural is
         --  Return count of number of component declarations on list
         --  Set global Contains_Ref if any component is a ref.
         Num : Natural := 0;
      begin
         for I in 1 .. Lists.Length (L) loop
            declare
               Decl_Node : constant Optional_Tree :=
                 Lists.Nth_Element (L, I);
            begin
               if Not_Null (Decl_Node)
                 and then Tree_Ptr_Of (Decl_Node).all in Obj_Decl.Tree
               then
                  declare
                     Obj_Decl_Tree : Obj_Decl.Tree renames
                       Obj_Decl.Tree (Tree_Ptr_Of (Decl_Node).all);
                  begin
                     if Obj_Decl_Is_For_Component (Obj_Decl_Tree) then
                        --  We have a component
                        Num := Num + 1;
                        if Obj_Decl_Tree.Is_Ref then
                           Contains_Ref := True;
                        end if;
                     end if;
                  end;
               end if;
            end;
         end loop;
         return Num;
      end Count_Components;

      function Count_Constructors (L : Lists.List) return Natural is
         --  Return count of number of non-abstract constructors on list;
         --  only include those with no Mod_Sem cur-inst inputs, since we
         --  are only interested in constructors that create objects out
         --  of "thin air."
         --  Also, ignore those that are defined in terms of other constructors
         --  or are defined with an expression, as these don't imply there
         --  can be private components.
         Num : Natural := 0;
      begin
         --  Scan the list for non-abstract operations with an output of the
         --  same type as the current instance, but with no such inputs.
         --  TBD: This is purely syntactic at the moment.
         --      It would be nice if we could rely on semantic
         --      information instead.
         for I in 1 .. Lists.Length (L) loop
            declare
               Decl_Node : constant Optional_Tree :=
                 Lists.Nth_Element (L, I);
            begin
               if Not_Null (Decl_Node)
                 and then Tree_Ptr_Of (Decl_Node).all in Operation.Tree
               then
                  declare
                     Operation_Tree : Operation.Tree renames
                       Operation.Tree (Tree_Ptr_Of (Decl_Node).all);
                  begin
                     if not Operation_Tree.Is_Abstract
                       and then (not Operation_Tree.Is_Def
                                   or Operation_Tree.Is_Import)
                       and then Operation_Is_Constructor
                                   (Operation_Tree,
                                    Mod_Sem,
                                    With_No_Cur_Inst_Inputs => True)
                     then
                        --  We have a non-abstract constructor with
                        --  no inputs of cur-inst type, which has a
                        --  body that is in the "class" (or is imported).
                        Num := Num + 1;
                     end if;
                  end;
               end if;
            end;
         end loop;
         return Num;
      end Count_Constructors;

      Vis_Count : Integer := Mod_Sem.Num_Visible_Components;
      Result : Natural := 0;

   begin  --  Num_Components;

      if Mod_Sem.Other_Part /= null then
         --  Make sure two parts now agree
         pragma Assert
           (Mod_Sem.Other_Part.Num_Visible_Components = Vis_Count);
         --  Make sure it wasn't computed for other part before
         --  this part showed up
         null;
      end if;

      if Vis_Count < 0 then
         --  Component counts not already computed.
         --  Compute them now.
         declare
            Interface_Mod_Sem : constant Module_Sem_Ptr :=
              Interface_Part (Mod_Sem);
            Interface_Module_Tree : Module.Tree
              renames Module.Tree
                (Tree_Ptr_Of (Interface_Mod_Sem.Definition).all);
            Parent_Module : constant Module_Sem_Ptr :=
              Interface_Mod_Sem.Parent_Module;
         begin
            Interface_Mod_Sem.Num_Visible_Components :=
              Count_Components (Interface_Module_Tree.Module_Exports) +
              Count_Components (Interface_Module_Tree.Module_New_Exports) +
              Count_Components (Interface_Module_Tree.Module_Implements);

            if Interface_Mod_Sem.Other_Part /= null then
               --  Now look at the "class" definition for the module
               declare
                  Class_Module_Tree : Module.Tree
                    renames Module.Tree
                      (Tree_Ptr_Of
                        (Interface_Mod_Sem.Other_Part.Definition).all);
               begin
                  --  Count the number of private components
                  Interface_Mod_Sem.Num_Private_Components :=
                     Count_Components (Class_Module_Tree.Class_Locals);
               end;
            end if;

            --  Count non-abstract constructors
            if Interface_Mod_Sem.Is_Abstract then
               Interface_Mod_Sem.Num_Constructors := 0;
            else
               Interface_Mod_Sem.Num_Constructors :=
                 Count_Constructors
                   (Interface_Module_Tree.Module_Exports) +
                 Count_Constructors
                   (Interface_Module_Tree.Module_New_Exports) +
                 Count_Constructors
                   (Interface_Module_Tree.Module_Implements);
            end if;

            if Interface_Module_Tree.Treat_As_Type
              and then Mod_Sem.Nested_Region /= null
              and then Mod_Sem.Nested_Region.Enclosing_Region /= null
              and then Mod_Sem.Nested_Region.Enclosing_Region.
                Associated_Symbol /= null
              and then Not_Null (Mod_Sem.Nested_Region.Enclosing_Region.
                Associated_Symbol.Definition)
            then
               --  Include constructors from the enclosing module
               --  since this type's operations are declared outside
               --  the type itself.
               declare
                  Enc_Tree : Trees.Tree'Class renames
                    Tree_Ptr_Of (Mod_Sem.Nested_Region.
                       Enclosing_Region.Associated_Symbol.Definition).all;
               begin
                  if Enc_Tree in Module.Tree
                    and then not Module.Tree (Enc_Tree).Is_Abstract
                  then
                     declare
                        Enc_Mod_Tree : Module.Tree
                          renames Module.Tree (Enc_Tree);
                     begin
                        Interface_Mod_Sem.Num_Constructors :=
                          Interface_Mod_Sem.Num_Constructors +
                            Count_Constructors (Enc_Mod_Tree.Module_Exports) +
                            Count_Constructors
                              (Enc_Mod_Tree.Module_New_Exports) +
                            Count_Constructors
                              (Enc_Mod_Tree.Module_Implements);
                     end;
                  end if;
               end;
            end if;
            if Parent_Module /= null then
               --  Include ancestors in whether contains a ref.
               Contains_Ref := Contains_Ref
                              or else Parent_Module.Contains_Ref_Component;

            end if;

            Interface_Mod_Sem.Contains_Ref_Component := Contains_Ref;

            if Debug_First_Pass then
               Put_Line
                 (" Component counts for " &
                  Sym_Name (Mod_Sem.Associated_Symbol) &
                  ": Vis =>" &
                  Integer'Image (Interface_Mod_Sem.Num_Visible_Components) &
                  ", Priv =>" &
                  Integer'Image (Interface_Mod_Sem.Num_Private_Components) &
                  ": Inh_Vis =>" &
                  Integer'Image
                     (Interface_Mod_Sem.Num_Visible_Ancestor_Components) &
                  ", Inh_Priv =>" &
                  Integer'Image
                     (Interface_Mod_Sem.Num_Private_Ancestor_Components) &
                  ", Constructors =>" &
                  Integer'Image (Interface_Mod_Sem.Num_Constructors));
               if Contains_Ref then
                  Put_Line ("  [Contains a ref]");
               end if;
               if Interface_Mod_Sem.Ancestor_Module_With_Constructor /=
                  null
               then
                  Put_Line
                    ("  [Must use name of ancestor " &
                     Sym_Name
                        (Interface_Mod_Sem.Ancestor_Module_With_Constructor.
                    Associated_Symbol) &
                     " in agg]");
               end if;
            end if;

            if Contains_Ref then
               --  Not assignable if contains a "ref" component.
               pragma Assert
                 (not Interface_Mod_Sem.Cur_Inst_Sem.Known_To_Be_Assignable);
               null;
            end if;

            if Interface_Mod_Sem.Other_Part /= null then
               --  Copy counts over to other part if there is one

               Interface_Mod_Sem.Other_Part.Num_Visible_Components :=
                 Interface_Mod_Sem.Num_Visible_Components;
               Interface_Mod_Sem.Other_Part.Num_Private_Components :=
                 Interface_Mod_Sem.Num_Private_Components;
               Interface_Mod_Sem.Other_Part.Num_Constructors :=
                 Interface_Mod_Sem.Num_Constructors;

               Interface_Mod_Sem.Other_Part.Contains_Ref_Component :=
                 Contains_Ref;
            end if;

         end;
      end if;

      if Mod_Sem.Ancestor_Module_With_Constructor /= null then
         --  We (might) have some ancestor private components
         --  TBD: Need to count inherited visible components
         --      from modules that are proper descendants of
         --      ancestor with constructors.
         declare
            Anc : Module_Sem_Ptr := Mod_Sem.Parent_Module;
            Components_Since_Ancestor : Natural :=
              Mod_Sem.Num_Visible_Components +
              Mod_Sem.Num_Private_Components;
         begin
            while Anc /= Mod_Sem.Ancestor_Module_With_Constructor loop
               --  Found a proper descendant of ancestor-with-constructor.
               --  Include its visible components (and it shouldn't have
               --  any private components).
               Components_Since_Ancestor := Components_Since_Ancestor +
                                            Anc.Num_Visible_Components;
               pragma Assert (Anc.Num_Private_Components = 0);

               --  Check next ancestor
               Anc := Anc.Parent_Module;
               pragma Assert (Anc /= null);  --  There should be one
            end loop;
            --  Return count of components usable in an aggregate.
            Result := Components_Since_Ancestor + 1;
         end;
      else
         --  Not expecting any ancestor private components

         if Mod_Sem.Num_Private_Ancestor_Components > 0 then
            --  TBD: Perhaps we somehow have visibility on the ancestor's
            --       private components.
            if Debug_Second_Pass then
               Put_Line ("Num_Components: Found" & Integer'Image
                 (Mod_Sem.Num_Private_Ancestor_Components) &
                  " private ancestor components in " &
                  Sym_Name (Mod_Sem.Associated_Symbol) &
                  " when its ancestors have no constructors");
            end if;
         end if;

         Result := Mod_Sem.Num_Visible_Components +
                   Mod_Sem.Num_Private_Components +
                   Mod_Sem.Num_Visible_Ancestor_Components +
                   Mod_Sem.Num_Private_Ancestor_Components;
      end if;

      if Debug_Second_Pass then
         --  Check for mismatch between num_components and ongoing count.
         --  This can happen if type is referenced before it is fully
         --  analyzed.
         if Interface_Part (Mod_Sem).Num_Components_For_Aggregate /=
            Result
         then
            Put_Line
              (" Num_Components on " &
               Sym_Name (Mod_Sem.Associated_Symbol) &
               " returning" &
               Natural'Image (Result) &
               ", ongoing count =" &
               Natural'Image
                  (Interface_Part (Mod_Sem).Num_Components_For_Aggregate));
         end if;
      end if;

      return Result;
   end Num_Components;

   function Nth_Component
     (Mod_Sem : Module_Sem_Ptr;
      N : Positive)
      return Optional_Tree
   is
      --  Return nth component of given module; will be an Obj_Decl.Tree
      Num_Comp : constant Natural := Num_Components (Mod_Sem);
      --  Call num_components to initialize Num_Components field
      pragma Assert (N <= Num_Comp);
      Module_Syms : constant Symbols.Symbol_List :=
        Mod_Sem.Nested_Region.Syms.Local_Symbols;
   begin
      --  Iterate over all of the symbols of the module
      for I in 1 .. Symbols.Num_Symbols (Module_Syms) loop
         declare
            Sym_In_Module : constant Symbols.Sym_Ptr :=
              Symbols.Nth_Symbol (Module_Syms, I);
            Decl_Tree : Trees.Tree'Class
              renames Tree_Ptr_Of (Sym_In_Module.Definition).all;
         begin
            if Decl_Is_For_Component
                 (Sym_In_Module.Definition,
                  Usable_In_Aggregate => True)
            then
               declare
                  Comp_Sem : constant Object_Sem_Ptr :=
                    Object_Sem_Ptr (Sym_In_Module.Sem_Info);
               begin
                  if Comp_Sem.Component_Index = N
                    and then (Comp_Sem.Associated_Symbol.Kind =
                              Module_Ancestor_Sym_Kind
                             or else Mod_Sem.Component_Extension_Level =
                                     Comp_Sem.Originating_Module.
                       Component_Extension_Level)
                  then
                     --  Found the one we want
                     return Sym_In_Module.Definition;
                  end if;
               end;
            end if;
         end;
      end loop;

      --  Oops, N components not found
      pragma Assert (False);
      return Null_Optional_Tree;
   end Nth_Component;

   function Module_Is_Wrapper (Mod_Sem : Module_Sem_Ptr) return Boolean is
   --  Return True if non-concurrent module has only one component
   --  which is *not* a "ref"
   --  TBD: Eventually we should be able to handle wrappers around
   --      a "ref" component.  These should be equivalent to a simple
   --      "ref".
   begin
      if Mod_Sem.Is_Concurrent or else Num_Components (Mod_Sem) /= 1 then
         --  Definitely not a wrapper if concurrent, abstract, or has
         --  multiple (or zero) components.
         --  TBD: It would seem OK to allow a partially-abstract type
         --      to be a wrapper, but it seems to cause trouble,
         --      so as of 1/30/2012, we are not allowing them to be wrappers.
         return False;
      else
         --  Only one component; see whether is a "ref"
         declare
            Comp_Sem : constant Sem_Ptr :=
              Sem_Ptr (Sem_Info (Nth_Component (Mod_Sem, 1)));
            use type Symbols.Sym_Ptr;
         begin
            --  This is a wrapper unless component is a ref
            return Comp_Sem.Associated_Symbol = null
                  or else not Sym_Is_Declared_Ref
                                (Comp_Sem.Associated_Symbol);
         end;
      end if;
   end Module_Is_Wrapper;

   function Type_Is_Wrapper (Obj_Type : Type_Sem_Ptr) return Boolean is
   --  Return True if type is a wrapper.  Generally this
   --  simply passes the buck to "Module_Is_Wrapper," but
   --  if the type is polymorphic, then it is never considered
   --  a wrapper, even if the root type is a wrapper.
   begin
      if Obj_Type.Is_Polymorphic then
         return False;
      else
         return Module_Is_Wrapper (Obj_Type.Associated_Module);
      end if;
   end Type_Is_Wrapper;

   function Unwrapped_Type (Type_Sem : Type_Sem_Ptr) return Type_Sem_Ptr is
   --  Return underlying type which is not a wrapper type.
   begin
      if not Type_Is_Wrapper (Type_Sem) then
         return Type_Sem;
      else
         declare
            Comp_Sem : constant Object_Sem_Ptr :=
              Object_Sem_Ptr (Sem_Info (Nth_Component
                         (Type_Sem.Associated_Module, 1)));
         begin
            return Unwrapped_Type (Comp_Sem.Resolved_Type);
         end;
      end if;
   end Unwrapped_Type;

   function Type_Wraps_Optional_Component (Obj_Type : Type_Sem_Ptr)
     return Boolean is
   --  Return True if type is a wrapper and only component is optional,
   --  directly or indirectly.
   --  TBD: Set Value_Is_Optional on type if this is true.
   begin
      if not Type_Is_Wrapper (Obj_Type) then
         return False;
      else
         declare
            Only_Comp : constant Optional_Tree :=
              Nth_Component (Obj_Type.Associated_Module, 1);
            Comp_Type : constant Type_Sem_Ptr :=
              Object_Sem_Ptr (Sem_Info (Only_Comp)).Resolved_Type;
         begin
            --  Recurse on component type
            if Comp_Type = null then
               return False;
            elsif Comp_Type.Value_Is_Optional
              or else Type_Wraps_Optional_Component (Comp_Type)
            then
               return True;
            elsif Obj_Type.All_Parameters_Known then
               --  Substitute actuals into component type
               declare
                  Substituted_Comp_Type : constant Type_Sem_Ptr :=
                    Substitute_Actuals (Comp_Type,
                      U_Base_Type_Region (Obj_Type));
               begin
                  return Substituted_Comp_Type.Value_Is_Optional
                    or else
                      Type_Wraps_Optional_Component (Substituted_Comp_Type);
               end;
            else
               return False;
            end if;
         end;
      end if;
   end Type_Wraps_Optional_Component;

   function Is_Boolean_Or_Ordering
     (Target_Type : Type_Sem_Ptr)
      return Boolean
   is
   --  Return True if Target_Type is Boolean<> or Ordering<>.
   begin
      if Target_Type = null then
         return False;
      else
         return (Boolean_Type /= null
                and then Target_Type.U_Base_Type = Boolean_Type.U_Base_Type)
               or else (Ordering_Type /= null
                       and then Target_Type.U_Base_Type =
                                Ordering_Type.U_Base_Type);
      end if;
   end Is_Boolean_Or_Ordering;

   function Known_To_Be_Small (Obj_Type : Type_Sem_Ptr) return Boolean is
   --  If it is known at compile-time that the given type
   --  will always be "small" (i.e. a single 64-bit word or less)
   --  then return True.  If the object might be "large" in
   --  certain instantiations of the module, then return False.
   begin
      if Obj_Type.Is_Polymorphic then
         --  Polymorphic types are always considered large
         Obj_Type.Known_To_Be_Small := False;
         Obj_Type.Known_To_Be_Large := True;
         return False;
      elsif Obj_Type.Known_To_Be_Small then
         return True;
      elsif Obj_Type.Known_To_Be_Large then
         return False;
      elsif Obj_Type.U_Base_Type = null then
         --  Don't know enough yet
         return False;
      elsif Obj_Type /= Obj_Type.U_Base_Type then
         --  Not a base type, recompute the base type
         Obj_Type.Known_To_Be_Small :=
            Known_To_Be_Small (Obj_Type.U_Base_Type);
         Obj_Type.Known_To_Be_Large := Obj_Type.U_Base_Type.Known_To_Be_Large;
      elsif Obj_Type.Is_Formal_Type then
         --  Formal types can always be large
         return False;
      elsif Num_Components (Obj_Type.Associated_Module) = 0 then
         --  No components, treat as small so long as
         --  not a parameterized module and not concurrent/abstract,
         --  and doesn't have an explicit class.
         Obj_Type.Known_To_Be_Small :=
             not Obj_Type.Associated_Module.Is_Concurrent
           and then not Type_Is_Parameterized (Obj_Type)
           and then (Obj_Type.Associated_Module.Other_Part = null
                or else Is_Boolean_Or_Ordering (Obj_Type));
         Obj_Type.Known_To_Be_Large := not Obj_Type.Known_To_Be_Small;
      elsif not Module_Is_Wrapper (Obj_Type.Associated_Module) then
         --  At this point, we know it is large
         Obj_Type.Known_To_Be_Large := True;
         return False;
      elsif Obj_Type.All_Parameters_Known then
         --  this is a base type, we know everything
         --  about it, and it has only one component,
         --  so try to determine whether
         --  this type might be known to be small.
         declare
            Only_Comp : constant Optional_Tree :=
              Nth_Component (Obj_Type.Associated_Module, 1);
            Comp_Type : constant Type_Sem_Ptr :=
              Substitute_Actuals
                 (Object_Sem_Ptr (Sem_Info (Only_Comp)).Resolved_Type,
                  U_Base_Type_Region (Obj_Type));
         begin
            if Comp_Type /= null then
               Obj_Type.Known_To_Be_Small := Known_To_Be_Small (Comp_Type);
               Obj_Type.Known_To_Be_Large := Comp_Type.Known_To_Be_Large;
            end if;
         end;
      end if;
      return Obj_Type.Known_To_Be_Small;
   end Known_To_Be_Small;

   function Component_Index
     (Mod_Sem : Module_Sem_Ptr;
      Comp_Decl : Optional_Tree;
      Usable_In_Aggregate : Boolean := True)
      return Natural
   is
   --  Return index of component if is a component of the module
   --  else return 0 if is an operation or some other non-component
   --  If Usable_In_Aggregate is False, then it will return component
   --  index but it might not match Compoennt_Extension_Level of Mod_Sem.
   begin
      if not Decl_Is_For_Component
               (Comp_Decl,
                Usable_In_Aggregate => Usable_In_Aggregate)
      then
         --  Not a component
         return 0;
      else
         --  Return stored component index.
         declare
            Decl_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Comp_Decl));
         begin
            if Decl_Sem.all in Object_Semantic_Info'Class then
               return Object_Sem_Ptr (Decl_Sem).Component_Index;
            else
               return 0;
            end if;
         end;
      end if;
   end Component_Index;

   function Is_Default_Indicator (OT : Optional_Tree) return Boolean is
   --  Return True if OT represents ".."
   --  which is represented by "null .. null" where "null"
   --  is a Null_Optional_Tree and ".." is the Closed_Interval_Op.
   begin
      if Not_Null (OT) and then Tree_Ptr_Of (OT).all in Binary.Tree then
         --
         declare
            Bin_Tree : Binary.Tree renames Binary.Tree (Tree_Ptr_Of (OT).all);
            use Binary;
         begin
            return Bin_Tree.Operator = Closed_Interval_Op
                  and then Is_Null (Bin_Tree.Left_Operand)
                  and then Is_Null (Bin_Tree.Right_Operand);
         end;
      else
         return False;
      end if;
   end Is_Default_Indicator;

   function Type_Def_Has_New_Module (Type_Def : Optional_Tree)
     return Boolean is
   --  Return True if Type_Def defines a type by an instance of a newly
   --  defined module (that is, the Prefix of the instantiation is itself
   --  a module definition).
   --  NOTE: This is currently only meaningful for Sparkel
      Type_Def_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Type_Def).all;
      use Invocation;
   begin
      if Type_Def_Tree in Invocation.Tree
         and then Invocation.Tree
           (Type_Def_Tree).Kind = Module_Instantiation
        and then Not_Null (Invocation.Tree (Type_Def_Tree).Prefix)
      then
         --  We have an invocation, see if prefix is a module
         declare
            Prefix_Tree : Trees.Tree'Class renames
              Tree_Ptr_Of (Invocation.Tree (Type_Def_Tree).Prefix).all;
         begin
            return Prefix_Tree in Module.Tree;
         end;
      end if;
      --  Not a type definition with a new module
      return False;
   end Type_Def_Has_New_Module;

   function Is_Private_Type_Decl (OT : Optional_Tree) return Boolean is
   --  Return True if OT is a type-decl for a private type
   --  NOTE: This is currently only meaningful for Sparkel
      Type_Tree : Trees.Tree'Class renames
        Tree_Ptr_Of (OT).all;
   begin
      if Type_Tree in Type_Decl.Tree then
         --  We have a type defined by a Type_Decl, see if is private
         declare
            Type_Def_Tree : Trees.Tree'Class renames
              Tree_Ptr_Of (Type_Decl.Tree (Type_Tree).Type_Definition).all;
            use Invocation;
         begin
            if Type_Def_Tree in Invocation.Tree
               and then Invocation.Tree
                 (Type_Def_Tree).Kind = Module_Instantiation
              and then Not_Null (Invocation.Tree (Type_Def_Tree).Prefix)
            then
               --  We have an invocation, see if prefix is a private module
               declare
                  Prefix_Tree : Trees.Tree'Class renames
                    Tree_Ptr_Of (Invocation.Tree (Type_Def_Tree).Prefix).all;
               begin
                  return Prefix_Tree in Module.Tree
                    and then Module.Tree (Prefix_Tree).Is_Private;
               end;
            end if;
         end;
      end if;
      --  Not a (Sparkel) private type declaration
      return False;
   end Is_Private_Type_Decl;

   procedure Check_For_Dups (Sym : Symbols.Sym_Ptr) is
      --  Make sure that if Sym has a homonym, that we allow that
      use Symbols;
      Hom : Symbols.Sym_Ptr := Next_Homonym_In_Region_Chain
        (Sym, Orig_Region => null);
      Sym_Is_Standalone_Unit : constant Boolean :=
        not Lists.Is_Empty (Sym.Import_Clauses);
   begin
      while Hom /= null loop
         --  OK, we have a homonym
         --  see whether it is allowed
         declare
            Hom_Is_Standalone_Unit : constant Boolean :=
              not Lists.Is_Empty (Hom.Import_Clauses);
            Hom_And_Sym_In_Same_Region : constant Boolean :=
              Hom.Enclosing_Region.Syms = Sym.Enclosing_Region.Syms;
            Illegal_Hiding : Boolean :=
              (Hom.Kind /= Component_Sym_Kind
              and then Hom.Kind /= Module_Ancestor_Sym_Kind
              and then (not Hom_Is_Standalone_Unit
                       or else Hom_And_Sym_In_Same_Region)
              and then (Hom.Kind /= Module_Sym_Kind
                       or else Hom_And_Sym_In_Same_Region))
              and then (Hom.Sem_Info /= Sym.Sem_Info
                or else Hom.Sem_Info = null);
         --  Hiding is illegal by default, unless homonym is
         --  a component or a standalone unit (and sym is not)
         --  or hom is a module in an enclosing scope.
         --  Since the cur-inst type has same name as module,
         --  it will catch any illegal hiding of the enclosing module
         --  name.
            use type Languages.Language_Enum;
         begin
            case Sym.Kind is
            when No_Sym_Kind =>
               pragma Assert (False);
               null;
            when Module_Sym_Kind =>
               --  This is allowed so long as one is an interface
               --  and one isn't, and they have the same enclosing region.
               --  TBD: Allow other kinds of things like private interfaces,
               --      interface extensions, etc.
               if Hom.Kind /= Module_Sym_Kind then
                  --  Illegal unless Hom is a component
                  --  or Sparkel and module is treated as a type
                  --  and homonym is the current instance of the
                  --  immediately enclosing module
                  if Languages.Language = Languages.Sparkel
                    and then Hom_And_Sym_In_Same_Region
                    and then Hom.Kind = Type_Sym_Kind
                    and then
                      Type_Sem_Ptr (Hom.Sem_Info).
                        Associated_Module.Cur_Inst_Sem =
                      Type_Sem_Ptr (Hom.Sem_Info)
                  then
                     --  TBD: and then Sym is treated as a type
                     Type_Sem_Ptr (Hom.Sem_Info).Associated_Module.
                        Primary_Nested_Type :=
                          Module_Sem_Ptr (Sym.Sem_Info).Cur_Inst_Sem;

                     return; --  Quit now, don't want to bump into package too
                  end if;

                  if Languages.Language = Languages.Sparkel
                    and then Hom_And_Sym_In_Same_Region
                    and then Hom.Kind = Type_Sym_Kind
                    and then Module.Tree
                      (Tree_Ptr_Of (Sym.Definition).all).Treat_As_Type
                    and then not Module.Tree
                      (Tree_Ptr_Of (Sym.Definition).all).Is_Private
                    and then Is_Private_Type_Decl (Hom.Definition)
                  then
                     --  This is presumably the module for the type
                     --  completing the private type.
                     return; --  Quit now, don't want to bump into package too
                  end if;
               else
                  declare
                     Hom_Mod_Tree : Module.Tree renames
                       Module.Tree (Tree_Ptr_Of (Hom.Definition).all);
                     Sym_Mod_Tree : Module.Tree renames
                       Module.Tree (Tree_Ptr_Of (Sym.Definition).all);
                  begin
                     if not Hom_And_Sym_In_Same_Region then
                        --  Not same region; see if this is Primary_Nested_Type
                        if Languages.Language = Languages.Sparkel
                          and then not Hom_Mod_Tree.Treat_As_Type
                          and then Sym_Mod_Tree.Treat_As_Type
                          and then Hom.Nested_Region = Sym.Enclosing_Region
                        then
                           Module_Sem_Ptr (Hom.Sem_Info).
                              Primary_Nested_Type :=
                                Module_Sem_Ptr (Sym.Sem_Info).Cur_Inst_Sem;
                           Illegal_Hiding := False;
                        end if;
                     elsif Hom_Mod_Tree.Is_Interface /=
                             Sym_Mod_Tree.Is_Interface
                       or else
                        (Hom_Mod_Tree.Treat_As_Type
                         and then Sym_Mod_Tree.Treat_As_Type
                         and then Hom_Mod_Tree.Is_Private
                         and then not Sym_Mod_Tree.Is_Private)
                     then
                        Illegal_Hiding := False;
                     else
                        Sem_Error
                          (Sym.Definition, "Duplicate module definition");
                        --  Quit now, don't want to bump into package too
                        return;
                     end if;
                  end;
               end if;
            when Type_Sym_Kind =>
               if Hom.Kind = Module_Sym_Kind
                 and then Hom.Nested_Region = Sym.Enclosing_Region
               then
                  --  OK for type name to be same as module
                  --  (this must be the current inst or primary nested type)
                  Illegal_Hiding := False;

                  if Languages.Language = Languages.Sparkel then
                     --  Make sure it is marked as the primary nested type
                     declare
                        Hom_Mod_Sem : constant Module_Sem_Ptr :=
                          Module_Sem_Ptr (Hom.Sem_Info);
                        Sym_Type_Sem : constant Type_Sem_Ptr :=
                          Type_Sem_Ptr (Sym.Sem_Info);
                     begin
                        if Hom_Mod_Sem.Cur_Inst_Sem /= Sym_Type_Sem
                          and then Hom_Mod_Sem.Is_Interface
                          and then
                            (Sym_Type_Sem.Associated_Module = null
                               or else
                             Sym_Type_Sem.Associated_Module.Is_Interface)
                        then
                           if Hom_Mod_Sem.Primary_Nested_Type = null then
                              --  Treat as primary nested type of package.
                              Hom_Mod_Sem.Primary_Nested_Type := Sym_Type_Sem;
                           elsif Hom_Mod_Sem.Primary_Nested_Type /=
                             Sym_Type_Sem
                           then
                              --  Illegal to have two primary nested types
                              Illegal_Hiding := True;
                           end if;
                        end if;
                     end;
                  end if;

               elsif Hom.Kind = Module_Sym_Kind
                 and then Hom_And_Sym_In_Same_Region
                 and then Module.Tree
                   (Tree_Ptr_Of (Hom.Definition).all).Treat_As_Type
               then
                  --  This must be module associated with type.
                  Illegal_Hiding := False;

               elsif Hom.Kind = Type_Sym_Kind
                 and then Hom_And_Sym_In_Same_Region
                 and then Languages.Language = Languages.Sparkel
                 and then Is_Private_Type_Decl (Hom.Definition)
                 and then not Is_Private_Type_Decl (Sym.Definition)
               then
                  --  This is allowed so long as first one is a private type
                  --  and second one isn't
                  --  Sym is "completing" the Hom private type
                  Illegal_Hiding := False;
               end if;
            when Param_Sym_Kind =>
               declare
                  Param_Tree : Param_Decl.Tree renames
                    Param_Decl.Tree (Tree_Ptr_Of (Sym.Definition).all);
               begin
                  if Is_Null (Param_Tree.Name) then
                     --  Hiding is permitted if parameter does not have an
                     --  explicit name.
                     Illegal_Hiding := False;
                  elsif Hom.Kind = Type_Sym_Kind
                    or else
                        Hom.Kind = Module_Sym_Kind
                    or else
                        Hom.Kind = Operation_Sym_Kind
                  then
                     --  Hiding is permitted if parameter matches a type,
                     --  module, or operation name
                     Illegal_Hiding := False;
                  elsif Hom.Kind = Param_Sym_Kind
                    and then
                        Is_Null (Param_Decl.Tree (Tree_Ptr_Of
                          (Hom.Definition).all).Name)
                  then
                     --  Hiding is permitted if homonym is a parameter
                     --  without an explicit name.
                     Illegal_Hiding := False;
                  end if;
               end;
            when Loop_Param_Sym_Kind | Loop_Key_Param_Sym_Kind =>
               null;  --  No hiding (but should be in its own local scope)
            when Object_Sym_Kind =>
               null;  --  No hiding (unless Hom is a component)
            --  TBD: Allow interface constant to have value defined in
            --      class?
            when Component_Sym_Kind | Module_Ancestor_Sym_Kind =>
               if Hom.Kind /= Component_Sym_Kind
                 and then Hom.Kind /= Module_Ancestor_Sym_Kind
               then
                  --  Allow components to have same name as other things
                  --  since they don't hide one another.
                  Illegal_Hiding := False;
               elsif Hom.Enclosing_Region = Sym.Enclosing_Region then
                  --  Don't allow two components of same name in same region.
                  Illegal_Hiding := True;
               end if;
            when Operation_Sym_Kind =>
               if Hom.Kind = Operation_Sym_Kind then
                  --  Allow operations to overload (TBD: unless they
                  --  have the same signature) unless both are top level.
                  Illegal_Hiding := Hom_Is_Standalone_Unit and
                                    Hom_And_Sym_In_Same_Region;
               end if;
            when Statement_Sym_Kind =>
               --  No hiding allowed
               null;
            when Literal_Sym_Kind =>
               pragma Assert (False);
               null;
            end case;

            if Illegal_Hiding then
               Sem_Error
                 (Sym.Definition,
                  "Hiding of " &
                  Sym_Name (Hom) &
                  " at line" &
                  Source_Positions.Line_Number'Image (Hom.Source_Pos.Line) &
                  " not permitted");
               if Debug_Second_Pass then
                  Put_Line ("Hom Sym_Kind = " &
                    Sym_Kind_Enum'Image (Hom.Kind));
                  Put_Line ("Hom_And_Sym_In_Same_Region = " &
                    Boolean'Image (Hom_And_Sym_In_Same_Region));
                  if Hom_And_Sym_In_Same_Region then
                     if Hom.Enclosing_Region = Symbols.Library_Region then
                        Put_Line (" both at library level");
                     else
                        Put_Line (" shared region = " &
                          Sym_Name (Hom.Enclosing_Region.Associated_Symbol));
                     end if;
                  end if;
                  Put_Line ("Hom_Is_Standalone_Unit = " &
                    Boolean'Image (Hom_Is_Standalone_Unit));
               end if;
               return;  -- No need to complain more than once. --
            else
               --  Check the next homonym
               Hom := Next_Homonym_In_Region_Chain (Hom, Orig_Region => null);
            end if;
         end;
      end loop;
   end Check_For_Dups;

   function U_String_Or_Null (OT : Optional_Tree) return Strings.U_String is
   --  Return corresponding U_String if OT is non null.
   --  If OT is Null_Optional_Tree, return Null_U_String.
   begin
      if Not_Null (OT) then
         return Strings.String_Lookup (Subtree_Image (OT));
      else
         return Strings.Null_U_String;
      end if;
   end U_String_Or_Null;

   function Num_Enclosing_Module_Parameters
     (Decl_Region : Symbols.Region_Ptr)
      return Natural
   is
      --  Return count of total number of parameters of enclosing modules,
      --  if any.  Return 0 if Decl_Region is Library_Region.
      Enclosing_Region : Symbols.Region_Ptr := Decl_Region;
      Count : Natural := 0;
      use Symbols;
   begin
      while Enclosing_Region /= null
        and then Enclosing_Region /= Symbols.Library_Region
      loop
         if Enclosing_Region.Associated_Symbol /= null
           and then Enclosing_Region.Associated_Symbol.Kind =
                    Module_Sym_Kind
         then
            --  Found an enclosing module, add in its parameter count
            Count := Count +
                     Num_Module_Parameters
                        (Module_Sem_Ptr (
              Enclosing_Region.Associated_Symbol.Sem_Info));
         end if;
         Enclosing_Region := Enclosing_Region.Enclosing_Region;
      end loop;
      return Count;
   end Num_Enclosing_Module_Parameters;

   function Enclosing_Module_Cur_Inst
     (Decl_Region : Symbols.Region_Ptr)
      return Type_Sem_Ptr
   is
      --  Return cur-inst type of enclosing module if this is a nested
      --  module.  If top-level module, return null.
      Enclosing_Region : Symbols.Region_Ptr := Decl_Region;
      use Symbols;
   begin
      while Enclosing_Region /= null
        and then Enclosing_Region /= Symbols.Library_Region
      loop
         if Enclosing_Region.Associated_Symbol /= null
           and then Enclosing_Region.Associated_Symbol.Kind =
                    Module_Sym_Kind
         then
            --  Found an enclosing module, return its cur-inst type
            declare
               Mod_Sem : constant Module_Sem_Ptr :=
                 Interface_Part (Module_Sem_Ptr
                   (Enclosing_Region.Associated_Symbol.Sem_Info));
            begin
               if Mod_Sem.Cur_Inst_Sem.Associated_Module = Mod_Sem then
                  --  Only return if this is "really" a cur-inst
                  return Mod_Sem.Cur_Inst_Sem;
               end if;
            end;
         end if;
         Enclosing_Region := Enclosing_Region.Enclosing_Region;
      end loop;

      --  Module not nested
      --  TBD: What if module nested in an operation?
      --      We hopefully don't allow that syntactically.
      return null;
   end Enclosing_Module_Cur_Inst;

   function Find_Enclosing_Module
     (Decl_Region : Symbols.Region_Ptr)
      return Module_Sem_Ptr
   is
      --  Return semantic info for enclosing module, or null if none.
      Encloser : Region_Ptr := Decl_Region;
   begin
      --  Loop to find nearest enclosing module
      while Encloser /= null loop
         if Encloser.Associated_Symbol /= null
           and then Encloser.Associated_Symbol.Sem_Info /= null
           and then Encloser.Associated_Symbol.Sem_Info.all in
              Module_Semantic_Info
         then
            --  Found it
            return Module_Sem_Ptr (Encloser.Associated_Symbol.Sem_Info);
         end if;
         Encloser := Encloser.Enclosing_Region;
      end loop;
      if Debug_Second_Pass then
         if Current_Module /= null then
            Put_Line
              (" Find_Enclosing_Module falling back on Current_Module = " &
               Sym_Name (Current_Module.Associated_Symbol));
         end if;
      end if;
      return Current_Module;
   end Find_Enclosing_Module;

   function Find_Enclosing_Module_Interface
     (Decl_Region : Symbols.Region_Ptr)
      return Module_Sem_Ptr
   is
   --  Return semantic info for interface of enclosing module,
   --  or null if none.
   begin
      return Interface_Part (Find_Enclosing_Module (Decl_Region));
   end Find_Enclosing_Module_Interface;

   function Immediately_Enclosing_Module_Interface
     (Decl_Region : Symbols.Region_Ptr)
      return Module_Sem_Ptr
   is
   --  Return semantic info for interface of immediately enclosing module,
   --  or null if not immediately enclosed in a module.
   begin
      if Decl_Region /= null
        and then Decl_Region.Associated_Symbol /= null
        and then Decl_Region.Associated_Symbol.Sem_Info /= null
        and then Decl_Region.Associated_Symbol.Sem_Info.all in
           Module_Semantic_Info
      then
         --  It is immediately enclosed in a module
         return Interface_Part
           (Module_Sem_Ptr (Decl_Region.Associated_Symbol.Sem_Info));
      else
         --  Not immediately enclosed in a module
         return null;
      end if;
   end Immediately_Enclosing_Module_Interface;

   function Find_Enclosing_Operation
     (Decl_Region : Symbols.Region_Ptr)
      return Operation_Sem_Ptr
   is
      --  Return semantic info for enclosing operation, or null if none.
      use Symbols;
      Encloser : Region_Ptr := Decl_Region;
   begin
      --  Loop to find nearest enclosing operation
      while Encloser /= null loop
         if Encloser.Associated_Symbol /= null
           and then Encloser.Associated_Symbol.Sem_Info /= null
           and then Encloser.Associated_Symbol.Sem_Info.all in
              Operation_Semantic_Info
         then
            --  Found it
            if Debug_Second_Pass then
               Put_Line
                 (" Find_Enclosing_Operation returns " &
                  Sym_Name (Encloser.Associated_Symbol));
            end if;
            return Operation_Sem_Ptr (Encloser.Associated_Symbol.Sem_Info);
         end if;
         Encloser := Encloser.Enclosing_Region;
      end loop;
      if Debug_Second_Pass then
         Put_Line (" Find_Enclosing_Operation returning null");
      end if;
      return null;
   end Find_Enclosing_Operation;

   function Find_Enclosing_Stmt
     (Decl_Region : Symbols.Region_Ptr;
      Applies_To : Control_Stmt.Exitable_Construct_Enum;
      Id : Optional_Tree)
      return Optional_Tree
   is
      --  Return tree for enclosing contruct of specified kind and id.
      --  Return Null_Optional_Tree if not found.
      use Symbols;
      use Control_Stmt;
      Encloser : Region_Ptr := Decl_Region;
      Id_Str : Strings.U_String := Strings.Null_U_String;
   begin
      if Not_Null (Id) then
         declare
            Id_Tree : Identifier.Tree renames Identifier.Tree (Tree_Ptr_Of
                                                                  (Id).all);
            Stmt_Sym : constant Symbols.Sym_Ptr :=
              Symbols.Lookup_In_Region_Chain (Decl_Region, Id_Tree.Str);
         begin
            if Stmt_Sym = null then
               return Null_Optional_Tree;
            end if;
            if Stmt_Sym.Nested_Region = null
              or else not Control_Stmt.Associated_Region_Kinds
                             (Applies_To)(Stmt_Sym.Nested_Region.Kind)
            then
               --  Wrong kind of construct
               Sem_Error (Id, "Kind of construct does not match");
               return Null_Optional_Tree;
            end if;
            --  OK, the Id identifies the right kind of construct,
            --  but we don't immediately use it because it might be
            --  in an enclosing operation.
            Id_Str := Id_Tree.Str;
         end;
      end if;

      --  Loop to find nearest enclosing statement matching criteria
      while Encloser /= null loop
         if Encloser.Kind not in Stmt_Region_Kind then
            --  Cannot cross an operation/module
            return Null_Optional_Tree;
         end if;

         if Control_Stmt.Associated_Region_Kinds (Applies_To) (Encloser.Kind)
           and then Encloser.Associated_Symbol /= null
         then
            --  We have the right kind of region
            if Is_Null (Id)
              or else Encloser.Associated_Symbol.Str = Id_Str
            then
               --  Found it
               return Encloser.Associated_Symbol.Definition;
            end if;
         end if;

         --  Keep looking
         Encloser := Encloser.Enclosing_Region;
      end loop;
      if Debug_Second_Pass then
         Put_Line (" Find_Enclosing_Stmt returning Null_Optional_Tree");
      end if;
      return Null_Optional_Tree;
   end Find_Enclosing_Stmt;

   function Inside_Abstract_Construct
     (Decl_Region : Symbols.Region_Ptr) return Boolean
   --  Return True if given region is inside an abstract construct,
   --  either an abstract operation, or a [partially] abstract module.
   is
      use Symbols;
      Encloser : Region_Ptr := Decl_Region;
   begin
      --  Loop to check for abstract construct
      while Encloser /= null loop
         case Encloser.Kind is
            when Library_Region_Kind =>
               --  Nothing abstract
               return False;

            when Module_Region_Kind =>
               if Encloser.Associated_Symbol.Sem_Info.all in
                  Module_Semantic_Info
                 and then (Module_Sem_Ptr
                   (Encloser.Associated_Symbol.Sem_Info).Is_Abstract
                  or else Module_Sem_Ptr
                   (Encloser.Associated_Symbol.Sem_Info).Is_Partially_Abstract)
               then
                  --  Inside an abstract or partially abstract module
                  return True;
               end if;

            when Operation_Param_Region_Kind
              | Operation_Body_Region_Kind =>

               --  See whether is abstract
               if Encloser.Associated_Symbol.Sem_Info.all in
                   Operation_Semantic_Info
                 and then Operation_Sem_Ptr
                   (Encloser.Associated_Symbol.Sem_Info).Is_Abstract
               then
                  --  Inside an abstract operation
                  return True;
               end if;

            when No_Region_Kind
              | Parallel_Stmt_Region_Kind
              | Loop_Body_Region_Kind
              | Loop_Param_Region_Kind
              | Block_Stmt_Region_Kind
              | If_Stmt_Region_Kind
              | Case_Stmt_Region_Kind
              | Type_Annotation_Region_Kind =>
               --  Check enclosing regions
               null;
         end case;

         --  Keep looking
         Encloser := Encloser.Enclosing_Region;
      end loop;

      --  Nothing abstract found
      return False;
   end Inside_Abstract_Construct;

   function Inside_Parallel_Construct
     (Decl_Region : Symbols.Region_Ptr;
      Up_Through : Composite_Stmt_Sem_Ptr := null;
      Up_To      : Composite_Stmt_Sem_Ptr := null)
     return Boolean
   --  Return True if given Decl_Region is for a parallel construct
   --  or is enclosed by one, up through/to specified statement, if any.
   is
      use Symbols;
      Encloser : Region_Ptr := Decl_Region;
   begin
      --  Loop to check for parallel construct
      while Encloser /= null
        and then (Up_To = null
          or else Encloser.Associated_Symbol = null
          or else Root_Sem_Ptr (Up_To) /=
             Encloser.Associated_Symbol.Sem_Info)
      loop
         case Encloser.Kind is
            when No_Region_Kind
              | Library_Region_Kind
              | Module_Region_Kind
              | Operation_Param_Region_Kind
              | Operation_Body_Region_Kind =>

               --  Nothing parallel
               return False;

            when Parallel_Stmt_Region_Kind =>
               --  Something parallel
               return True;

            when Loop_Body_Region_Kind =>
               if Encloser.Associated_Symbol /= null then
                  declare
                     Enclosing_Sem : constant Root_Sem_Ptr :=
                       Encloser.Associated_Symbol.Sem_Info;
                     use Interpreter;
                  begin
                     if Enclosing_Sem /= null and then
                       Enclosing_Sem.all in For_Loop_Construct_Semantic_Info
                     then
                        --  We are inside a "for" loop.
                        --  Decide whether it might have some parallelism
                        declare
                           For_Loop_Sem : constant For_Loop_Construct_Sem_Ptr
                             := For_Loop_Construct_Sem_Ptr (Enclosing_Sem);
                        begin
                           if For_Loop_Sem.Is_Potentially_Concurrent then
                              --  Inside a loop that is potentially concurrent
                              --  due to an explicit "concurrent," multiple
                              --  "next" values, or a continue from within
                              --  a parallel construct.
                              return True;
                           end if;
                        end;
                     end if;
                  end;
               end if;
               --  Keep looking

            when Loop_Param_Region_Kind
              | Block_Stmt_Region_Kind
              | If_Stmt_Region_Kind
              | Case_Stmt_Region_Kind
              | Type_Annotation_Region_Kind =>
               --  Check enclosing regions
               null;
         end case;

         exit when Up_Through /= null
           and then Encloser.Associated_Symbol /= null
           and then Root_Sem_Ptr (Up_Through) =
             Encloser.Associated_Symbol.Sem_Info;

         --  Keep looking
         Encloser := Encloser.Enclosing_Region;
      end loop;

      --  Nothing parallel found
      return False;
   end Inside_Parallel_Construct;

   function Lookup_Full_Module_Name
     (Decl_Region : Symbols.Region_Ptr;
      Mod_Name : Optional_Tree;
      Region_For_Imports : Region_Ptr := null)
      return Module_Sem_Ptr
   is
      --  Lookup full module name, possibly of the form "A::B::C"
      --  If Region_For_Imports is non-null, then imports associated
      --  with given region apply to lookup.
      Mod_Sym : constant Sym_Ptr := Lookup_Standalone_Item
        (Decl_Region, Mod_Name, Region_For_Imports);
   begin
      if Mod_Sym = null
        or else Mod_Sym.Sem_Info = null
        or else Mod_Sym.Sem_Info.all not in Module_Semantic_Info
      then
         --  Not a module
         return null;
      else
         --  Found a module, return its interface
         return Interface_Part (Module_Sem_Ptr (Mod_Sym.Sem_Info));
      end if;
   end Lookup_Full_Module_Name;

   function Get_Direction
     (T : Trees.Tree'Class;
      Direction_Str : Strings.U_String)
      return Interpreter.Direction
   is
   --  Determine direction of iteration, given "forward", "reverse", etc.
   begin
      for I in Direction_Names'Range loop
         if Direction_Str = Direction_Names (I) then
            --  Found a match
            return I;
         end if;
      end loop;

      --  Oops, no match found
      Sem_Error (T, "Unrecognized direction of iteration");
      return Interpreter.Unordered_Dir;
   end Get_Direction;

   function Make_Operand_Info
     (Operand : Optional_Tree;
      Position : Positive;
      Is_Output_Operand : Boolean := False)
      return Operand_Info
   is
      --  Create a filter for adding operation interps based
      --  on given information
      Operand_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Operand).all;
   begin
      if Operand_Tree in Reference.Tree'Class then
         --  We have a "named" operand
         declare
            Key_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                   (Reference.Tree (
              Operand_Tree).Key).all;
         begin
            if Key_Tree in Identifier.Tree'Class then
               return
                 (Is_Output_Operand => Is_Output_Operand,
                  Position => 0,
                  Name => Identifier.Tree (Key_Tree).Str);
            else
               Sem_Error (Operand, "Simple identifier must precede '=>'");
               return Any_Operation;
            end if;
         end;
      else
         --  We have a positional operand
         return
           (Is_Output_Operand => Is_Output_Operand,
            Position => Position,
            Name => Strings.Null_U_String);
      end if;
   end Make_Operand_Info;

   function Operand_Info_Image
     (Operation_Filter : Operand_Info)
      return String
   is
      --  Return printable image of operation filter
      function Input_Or_Output return String is
      begin
         if Operation_Filter.Is_Output_Operand then
            return "Output";
         else
            return "Input";
         end if;
      end Input_Or_Output;

   begin  --  Operand_Info_Image

      if Operation_Filter = Any_Operation then
         return "Any_Operation";
      elsif Operation_Filter = Constructors_Only then
         return "Constructors_Only";
      elsif Operation_Filter.Position > 0 then
         return Input_Or_Output &
                "#" &
                Natural'Image (Operation_Filter.Position);
      else
         return Input_Or_Output &
                " named " &
                Strings.To_String (Operation_Filter.Name);
      end if;
   end Operand_Info_Image;

   function Default_Import_Clauses
     (Prefix : Optional_Tree; Source_Pos : Source_Positions.Source_Position)
     return Lists.List is
   --  Return list representing "import <prefix>::*",
   --  or simply "import *" if Prefix is Null.
      Star : constant Optional_Tree := Identifier.Make
        (Str => Star_Str, Source_Pos => Source_Pos);
   begin
      if Not_Null (Prefix) then
         return Lists.Make ((1 =>
           Qualified_Name.Make
             (Prefix => Prefix, Id => Star)));
      else
         return Lists.Make ((1 => Star));
      end if;
   end Default_Import_Clauses;

   procedure Check_Import_Clauses (Import_Clauses : Lists.List) is
   --  Verify that Import_Clauses refer to existing units
      use type Lists.List;
   begin
      if Import_Clauses = Last_Import_Clauses then
         --  We already checked these
         return;
      end if;

      --  Remember the last checked import clauses
      Last_Import_Clauses := Import_Clauses;

      for I in 1 .. Lists.Length (Import_Clauses) loop
         declare
            Import_Clause : constant Optional_Tree :=
              Lists.Nth_Element (Import_Clauses, 1);
            Import_Strs : constant Symbols.Str_Array :=
              Name_Strings (Import_Clause);
            Tree_To_Check : Optional_Tree := Import_Clause;
         begin
            if Import_Strs (Import_Strs'Last) = Star_Str then
               if Import_Strs'Length = 1 then
                  --  Was simply "*"
                  Tree_To_Check := Null_Optional_Tree;
               else
                  --  Was X::Y::*
                  Tree_To_Check := Qualified_Name.Tree
                    (Tree_Ptr_Of (Import_Clause).all).Prefix;
               end if;
            end if;

            if Not_Null (Tree_To_Check) and then
              Lookup_Standalone_Item
                (Symbols.Library_Region, Tree_To_Check) = null
            then
               Sem_Error (Tree_To_Check, "Imported item not found");
            end if;
         end;
      end loop;
   end Check_Import_Clauses;

   ------------- First pass actions ------------

   type Sem_First_Pass_Visitor is new Visitor.RW_Tree_Visitor with record
      Decl_Region : Symbols.Region_Ptr;
      Visiting_Operation_Outputs : Boolean := False;
      Processing_Inherited_Decl  : Boolean := False;
   end record;

   procedure Pre_Visit
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Trees.Tree'Class);

   procedure Post_Visit
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Trees.Tree'Class);

   procedure Module_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Module.Tree);

   procedure Implements_Element_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Implements_Element.Tree);

   procedure Operation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Operation.Tree);

   procedure Obj_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Obj_Decl.Tree);

   procedure Param_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Param_Decl.Tree);

   procedure Type_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Type_Decl.Tree);

   procedure Binary_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Binary.Tree);

   procedure Unary_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Unary.Tree);

   procedure Annotation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Annotation.Tree);

   procedure Assign_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Assign_Stmt.Tree);

   procedure Block_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Block_Stmt.Tree);

   procedure Case_Construct_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Case_Construct.Tree);

   procedure Control_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Control_Stmt.Tree);

   procedure Conditional_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Conditional.Tree);

   procedure For_Loop_Construct_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out For_Loop_Construct.Tree);

   procedure Invocation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Invocation.Tree);

   procedure Iterator_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Iterator.Tree);

   procedure Reference_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Reference.Tree);

   procedure While_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out While_Stmt.Tree);

   --------

   procedure Make_Implicit_Module
     (Decl_Region : Symbols.Region_Ptr;
      Op_Sem : Operation_Sem_Ptr) is
      --  Create an implicit module for an operation

      Implicit_Name : constant Optional_Tree :=
        Identifier.Make
           (Str => Strings.Null_U_String, --  will fill in later
            Source_Pos => Find_Source_Pos (Op_Sem.Definition));

      Implicit_Module : Optional_Tree :=
        Module.Make
           (Name => Implicit_Name,
            Add_On_Label => Lists.Empty_List,
            Is_Interface => True,
            Is_Abstract => False,
            Is_Private => False,
            Is_Concurrent => False,
            Is_Limited => False,
            Has_Formals => True,
            Module_Formals => Lists.Empty_List,    --  Will have some
                                                   --  added
            Extends_Interface => Null_Optional_Tree,
            Implements_Interfaces => Lists.Empty_List,
            Class_Locals => Lists.Empty_List,
            Module_Exports => Lists.Empty_List,
      --  TBD: We might want to add enclosing operation here
      --      at some point, but we don't want it re-run
      --      through the first pass.
            Module_New_Exports => Lists.Empty_List,
            Module_Implements => Lists.Empty_List);
   begin
      if Decl_Region.Enclosing_Region.Kind /= Module_Region_Kind then
         Sem_Error (Op_Sem.Definition, "Generic operation " &
           Sym_Name (Op_Sem.Associated_Symbol) &
           " must be declared immediately within a module");
      end if;

      --  Process the module.  It doesn't have any module formals
      --  or exports yet so it won't do much.
      First_Pass (Decl_Region.Enclosing_Region, Implicit_Module);

      --  Now fill in the "real" name
      Identifier.Tree (Tree_Ptr_Of (Implicit_Name).all).Str :=
        Op_Sem.Associated_Symbol.Str;

      --  Fill in the sem info
      Op_Sem.Implicit_Enclosing_Module :=
        Module_Sem_Ptr (Sem_Info (Implicit_Module));

      --  Turn off All_Parameters_Known as this implicit
      --  module will definitely have some parameters.
      Op_Sem.Implicit_Enclosing_Module.Cur_Inst_Sem.All_Parameters_Known :=
        False;

      --  Reset module parameter count so it gets recomputed
      Op_Sem.Implicit_Enclosing_Module.Num_Module_Parameters := -1;

      --  Fill in the name on the symbol and cur-inst as well
      Op_Sem.Implicit_Enclosing_Module.Associated_Symbol.Str :=
        Op_Sem.Associated_Symbol.Str;

      Identifier.Tree (Tree_Ptr_Of (Invocation.Tree (Tree_Ptr_Of
        (Op_Sem.Implicit_Enclosing_Module.Cur_Inst_Sem.Definition).all).
           Prefix).all).Str := Op_Sem.Associated_Symbol.Str;

      --  Insert implicit module into region chain
      Decl_Region.Enclosing_Region :=
        Op_Sem.Implicit_Enclosing_Module.Nested_Region;

      if Op_Sem.Originating_Operation /= Op_Sem then
         --  We have an inherited generic operation.
         --  Fill in the parent type of the cur_inst_sem of the impl. module.
         Op_Sem.Implicit_Enclosing_Module.Cur_Inst_Sem.Parent_Type :=
           Op_Sem.Originating_Operation.Implicit_Enclosing_Module.Cur_Inst_Sem;
      end if;

   end Make_Implicit_Module;

   --------

   procedure Pre_Visit
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Trees.Tree'Class) is
   begin
      Visit (T.Pre_Annotation, Visitor);
   end Pre_Visit;

   procedure Post_Visit
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Trees.Tree'Class) is
   begin
      Visit (T.Post_Annotation, Visitor);
   end Post_Visit;

   procedure Module_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Module.Tree) is
      Mod_Sem : constant Module_Sem_Ptr := new Module_Semantic_Info;
      Mod_Region : Symbols.Region_Ptr :=
        new Symbols.Region (Module_Region_Kind);

      Name_Tree : Trees.Tree'Class renames Tree_Ptr_Of (T.Name).all;

      Module_Prefix : constant Optional_Tree :=
        Semantics.Prefix (T.Name);

      Enc_Region : Symbols.Region_Ptr := Visitor.Decl_Region;

      Is_Standalone_Module : constant Boolean :=
        Enc_Region = Symbols.Library_Region;

      Parent_Type : Type_Sem_Ptr := null;

      New_Mod : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Module_Sym_Kind,
         Str => Strings.String_Lookup
                  (Strings.Simple_Name (Subtree_Image (T.Name))),
         Full_Name => Strings.Null_U_String,
         Source_Pos => Module.Find_Source_Pos (T),
         Enclosing_Region => null,
         Nested_Region => null,
         Sem_Info => Root_Sem_Ptr (Mod_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);

      use type Strings.U_String;

   begin   --  Module_Action

      if Not_Null (Module_Prefix) then
         --  We have a module name of the form "A::B::C"

         if not Is_Standalone_Module then
            Sem_Error (Module_Prefix,
              "Module prefix only permitted on stand-alone module's");
         else
            --  Look up enclosing modules.
            declare
               Enc_Module : constant Module_Sem_Ptr :=
                 Lookup_Full_Module_Name
                    (Visitor.Decl_Region, Module_Prefix);
            begin
               if Enc_Module = null then
                  Sem_Error
                    (Module_Prefix,
                     "Enclosing module not found");
               else
                  --  Get region for sub-module
                  Enc_Region := Enc_Module.Nested_Region;
               end if;
            end;
         end if;
      end if;

      New_Mod.Enclosing_Region := Enc_Region;

      --  Add module to enclosing region.
      Add_To_Region (Enc_Region, New_Mod);
      Check_For_Dups (New_Mod);

      Mod_Region.Associated_Symbol := New_Mod;
      Mod_Region.Enclosing_Region := New_Mod.Enclosing_Region;

      Mod_Sem.Treat_As_Type := T.Treat_As_Type;
      Mod_Sem.Is_Interface := T.Is_Interface;
      Mod_Sem.Is_Abstract := T.Is_Abstract;
      Mod_Sem.Is_Concurrent := T.Is_Concurrent;
      Mod_Sem.Is_Standalone_Module := Is_Standalone_Module;
      if Is_Standalone_Module then
         Mod_Sem.Context := Standalone_Item_Context;
         if Lists.Is_Empty (T.Import_Clauses) then
            --  Create <prefix>::"*", or simply "*" if no prefix.
            New_Mod.Import_Clauses := Default_Import_Clauses
              (Module_Prefix, Source_Pos => Module.Find_Source_Pos (T));
         else
            New_Mod.Import_Clauses := T.Import_Clauses;
         end if;
      else
         --  Should not be any imports on a non-standalone module
         pragma Assert (Lists.Is_Empty (T.Import_Clauses));
         null;
      end if;

      Mod_Sem.Definition := New_Mod.Definition;
      Mod_Sem.Associated_Symbol := New_Mod;
      Set_Sem_Info (New_Mod.Definition, New_Mod.Sem_Info);

      if T.Is_Interface and then T.Treat_As_Type
        and then not T.Is_Private
      then
         --  See whether this is completing a private type
         declare
            Prior_Decl_Sym : constant Symbols.Sym_Ptr :=
              Next_Homonym_In_Region (New_Mod);
         begin
            if Prior_Decl_Sym /= null
              and then Prior_Decl_Sym.Kind = Type_Sym_Kind
              and then Is_Private_Type_Decl (Prior_Decl_Sym.Definition)
            then
               --  We are completing a private type.
               T.Is_Interface := False;
               Mod_Sem.Is_Interface := False;
               --  Component declarations are treated as
               --  locals instead of exports.
               T.Class_Locals := T.Module_Exports;
               T.Module_Exports := Lists.Empty_List;
               --  Find Associated_Module
               Mod_Sem.Other_Part := Type_Sem_Ptr
                 (Prior_Decl_Sym.Sem_Info).Associated_Module;
               if Debug_First_Pass then
                  Put_Line (" Type completes private type: " &
                    Subtree_Image (Prior_Decl_Sym.Definition));
               end if;
            end if;
         end;

      elsif not T.Is_Interface then
         --  Look up interface and link them together
         declare
            Mod_Interface : constant Symbols.Sym_Ptr :=
              Next_Homonym_In_Region (New_Mod);  --  NOTE: Include all imports
         begin
            if Mod_Interface /= null
              and then Mod_Interface.Kind = Module_Sym_Kind
              and then Module_Sem_Ptr (Mod_Interface.Sem_Info).Is_Interface
            then
               --  Set "Other_Part" to point to interface
               Mod_Sem.Other_Part := Module_Sem_Ptr (Mod_Interface.Sem_Info);

               --  Fill in the "Completion_Of" field of the symbol.
               New_Mod.Completion_Of := Mod_Interface;
            else
               Sem_Error (T, "Cannot find interface for module");
            end if;
         end;
      end if;

      if not T.Is_Interface and then Mod_Sem.Other_Part /= null then
         --  Copy information from interface
         if T.Is_Concurrent
           and then not Mod_Sem.Other_Part.Is_Concurrent
         then
            Sem_Error (T, "Interface should be concurrent if class is");
         end if;
         if Mod_Sem.Other_Part.Is_Standalone_Module
           and then not Mod_Sem.Is_Standalone_Module
         then
            --  If interface is standalone, then so must be the class
            --  (but OK for class to be standalone while i/f is nested).
            Sem_Error (T,
              "Class must not be nested if interface " &
              "is separately compiled");
         end if;
         Mod_Sem.Is_Concurrent := Mod_Sem.Other_Part.Is_Concurrent;
         Mod_Sem.Uses_Queuing := Mod_Sem.Other_Part.Uses_Queuing;
         Mod_Sem.Num_Module_Parameters :=
           Mod_Sem.Other_Part.Num_Module_Parameters;
         Mod_Sem.Primary_Nested_Type := Mod_Sem.Other_Part.Primary_Nested_Type;

         Mod_Sem.Other_Part.Other_Part := Mod_Sem;

         --  Share region symbol table between interface and class
         Mod_Region.Syms := Mod_Sem.Other_Part.Nested_Region.Syms;

         if Mod_Sem.Other_Part.Is_Abstract then
            Sem_Error
              (T,
               "Abstract module must not " &
               "have a class defining it");
            --  NOTE: We don't set a module abstract due to having
            --       an abstract operation within it.
            --       Such a module is considered "partially abstract"
            --       and we mark it that way in the second pass.
         end if;
      end if;

      if Mod_Region.Syms = null then
         --  We have an interface, or we couldn't find pre-existing interface
         Mod_Region.Syms := new Symbols.Region_Symbols;

         if Not_Null (T.Extends_Interface) then
            --  This module extends another.
            --  Parent info is represented as a Param_Decl for uniformity.
            declare
               Parent_Tree : Param_Decl.Tree
                 renames Param_Decl.Tree
                   (Tree_Ptr_Of (T.Extends_Interface).all);
               Parent_Type_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                              (Parent_Tree.
                 Param_Type).all;
               Module_Being_Extended_Name : Optional_Tree :=
                 Null_Optional_Tree;
            begin
               if Parent_Type_Tree in Invocation.Tree then
                  --  Parameters were specified for parent,
                  --  so a new set should be declared for new module
                  if not T.Has_Formals and then not T.Treat_As_Type then
                     Sem_Error
                       (T.Extends_Interface,
                        "Must declare new parameters for interface" &
                        " if parent parameters are specified");
                  end if;
                  Module_Being_Extended_Name :=
                    Invocation.Tree (Parent_Type_Tree).Prefix;
               elsif Parent_Type_Tree not in Identifier.Tree
                 and then Parent_Type_Tree not in Qualified_Name.Tree
               then
                  Sem_Error
                    (T.Extends_Interface,
                     "Must be an interface name or module instantiation");
               else
                  --  Parent specified without parameters.
                  --  New interface inherits module formals from parent
                  --  but may add more of its own.
                  Module_Being_Extended_Name := Parent_Tree.Param_Type;
               end if;

               if Not_Null (Module_Being_Extended_Name) then
                  Mod_Sem.Parent_Module :=
                     Lookup_Full_Module_Name
                       (Enc_Region,
                        Module_Being_Extended_Name,
                        Region_For_Imports => Mod_Region);

                  if Mod_Sem.Parent_Module /= null
                    and then Mod_Sem.Parent_Module.Primary_Nested_Type /= null
                  then
                     --  Use Primary_Nested_Type if defined
                     Mod_Sem.Parent_Module :=
                       Mod_Sem.Parent_Module.Primary_Nested_Type.
                         Associated_Module;
                  end if;

                  if Mod_Sem.Parent_Module = null then
                     Sem_Error
                       (T.Extends_Interface,
                        "Module " &
                        Subtree_Image (T.Extends_Interface) &
                        " not found");
                  else
                     declare
                        Parent_Module_Tree : Module.Tree
                          renames Module.Tree (Tree_Ptr_Of
                            (Mod_Sem.Parent_Module.Definition).all);
                     begin
                        Parent_Type := Mod_Sem.Parent_Module.Cur_Inst_Sem;
                        --  NOTE: This isn't correct if parent type
                        --       has parameters specified.
                        --       This will be updated in the second pass.

                        if Parent_Type_Tree not in Invocation.Tree then
                           --  Parent actuals not specified, so
                           --  copy the ancestor modules' list of formals
                           --  as these are being inherited by the new module

                           --  First copy those of the parent's ancestors
                           Mod_Sem.Ancestor_Module_Formals :=
                              Inherit_Decl_List
                                (Mod_Sem.Parent_Module.
                                  Ancestor_Module_Formals);
                           --  And then those of the parent itself
                           Lists.Append
                             (Mod_Sem.Ancestor_Module_Formals,
                              Inherit_Decl_List
                                 (Parent_Module_Tree.Module_Formals));
                        end if;
                     end;
                  end if;
               end if;
            end;
         end if;

         --  Compute count of total number of formals
         if Num_Module_Parameters (Mod_Sem) = 0 then
            pragma Assert
              (Lists.Is_Empty (T.Module_Formals)
              and then Lists.Is_Empty (Mod_Sem.Ancestor_Module_Formals));
            null;
         end if;
      end if;

      --  Fill in semantic information
      New_Mod.Nested_Region := Mod_Region;
      Mod_Sem.Nested_Region := Mod_Region;

      --  Create semantic information to use when interpreting
      --  the module as a type (e.g. inside it, or when implicitly(?)
      --  instantiating it with all defaults).

      if Mod_Sem.Other_Part /= null then
         --  Copy cur-inst sem from other part
         Mod_Sem.Cur_Inst_Sem := Mod_Sem.Other_Part.Cur_Inst_Sem;
         Mod_Sem.Parent_Module := Mod_Sem.Other_Part.Parent_Module;
         if Debug_First_Pass then
            Put_Line
              (" Reuse current instance from interface module for " &
                 Sym_Name (New_Mod));
         end if;
      else
         declare
            Cur_Inst_Sem : constant Type_Sem_Ptr :=
              new Type_Semantic_Info'
              (Root_Semantic_Info with
               Associated_Symbol => null,
               Nested_Region => null,     --  TBD: Or should it
                                          --  be module's region?
               Context => Interface_Item_Context,
               Type_Index => Next_Type_Index,
               New_Type_Counter => Anonymous_Type_Indicator,
               Associated_Module => Mod_Sem,
               Func_Type_Op_Sem => null,
               Enclosing_Type => Enclosing_Module_Cur_Inst
                                   (Visitor.Decl_Region),
               Parent_Type => Parent_Type,
               --  Potentially updated in second pass
               Ancestor_Type_With_Constructor => null,
               --  Potentially updated in second pass
               Constraint_Annotations => Lists.Empty_List,
               Value_Is_Optional => False,
               Obj_Is_Concurrent => False,
               Is_Polymorphic => False,
               Is_Universal => False,
               --  Default initialize to False, but may be updated in
               --  Builtin_Type_Init
               Known_To_Be_Assignable => False,
               --  Will be updated further based on components
               Known_To_Be_Small => False,
               Known_To_Be_Large => False,
               All_Parameters_Known => T.Has_Formals
                                      and then  --  tbd why?
                                       (Num_Module_Parameters (Mod_Sem) = 0
                                       and then
                                             Num_Enclosing_Module_Parameters
                                               (Visitor.Decl_Region) =
                                                0),
            --  All (actual) parameters are known if there are
            --  no formal parameters in this module, or any encloser
            --  or ancestor.
               Outermost_Module_Where_Used => Mod_Sem,
               Is_Formal_Type => False,
            --  NOTE: The Cur_Inst_Sem is not considered a formal type
            --       even when there are module parameters.
            --       Like a formal, it does need to be replaced wherever
            --       it appears (with the actual (base) type).
            --       But that is true of any type without all parameters
            --       known.
               Actual_Sem_Infos => null,
               Formal_Prefix => Null_Optional_Tree,
               Associated_Generic_Op => null,
               Actual_Of_Formal_Index => 0,
               Nested_Type_Index => 0,
               Op_Maps_Needed => Empty_Hash_Table,
               Type_Descriptor_Location => Interpreter.Null_Object_Locator,
               Full_View | External_View => null,
               U_Base_Type | U_Type | U_Base_Structure => null);

            Cur_Inst_Sym : constant Symbols.Sym_Ptr :=
              new Symbols.Symbol'
              (Kind => Type_Sym_Kind,
               Str => New_Mod.Str,
               Full_Name => Strings.Null_U_String,
               Source_Pos => New_Mod.Source_Pos,
               Enclosing_Region => Mod_Region,
               Nested_Region => null,
               Sem_Info => Root_Sem_Ptr (Cur_Inst_Sem),
               Definition => New_Mod.Definition,
               Completion_Of => null,
               Index => No_Sym_Index,
               Next_Homonym => No_Sym_Index,
               Import_Clauses => Lists.Empty_List);

         begin
            Cur_Inst_Sem.Associated_Symbol := Cur_Inst_Sym;

            --  Build up a parameterless instantiation to represent cur inst
            Cur_Inst_Sem.Definition :=
               Invocation.Make
                 (Kind => Invocation.Module_Instantiation,
                  Prefix =>
                     Identifier.Make
                       (Str => Cur_Inst_Sym.Str,
                        Source_Pos => Cur_Inst_Sym.Source_Pos),
                  Operands => Lists.Empty_List,
                  Source_Pos => Cur_Inst_Sym.Source_Pos);
            Set_Sem_Info
              (Cur_Inst_Sem.Definition,
               Root_Sem_Ptr (Cur_Inst_Sem));

            case Languages.Language is
               when Languages.ParaSail | Languages.Parython |
                    Languages.Javallel =>
                  --  Enter "current instance" type name into module region
                  --  unless this is Sparkel.
                  Add_To_Region (Mod_Region, Cur_Inst_Sym);
               when Languages.Sparkel =>
                  if T.Treat_As_Type then
                     --  We don't enter "current instance" of a type into
                     --  the region of its "module" in Sparkel.
                     --  Instead, we presume the type_decl will create the
                     --  interesting type and mark it as "new".
                     null;
                  else
                     --  We don't enter the "current instance" of a package
                     --  as it will just create confusion.
                     --  TBD: Perhaps we will at some point
                     null;
                  end if;
            end case;

            Mod_Sem.Cur_Inst_Sem := Cur_Inst_Sem;

            if Debug_First_Pass then
               Put_Line
                 (" Create current instance for module " &
                    Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem));
            end if;
         end;
      end if;

      if Debug_First_Pass then
         Put_Line
           ("Create symbol for module " &
            Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem) &
            "; sym_index =" &
            Sym_Index'Image (New_Mod.Index));
         Put_Line
           (" with current instance; cur-inst sym_index =" &
            Sym_Index'Image (Mod_Sem.Cur_Inst_Sem.Associated_Symbol.Index));
      end if;

      if T.Is_Interface then
         --  Walk the module formals, inherited and explicit

         --  Walk the inherited formals, if any.
         First_Pass_List (Mod_Region, Mod_Sem.Ancestor_Module_Formals);

         --  Walk the new ones, if any.
         First_Pass_List (Mod_Region, T.Module_Formals);
      end if;

      --  Now walk the locals and visible declarations,
      --  unless we have a parent module.  If there is a
      --  parent module, we postpone doing the first pass
      --  on the nested declarations until the parent
      --  has done its *second* pass.

      if Mod_Sem.Parent_Module = null then

         if not Lists.Is_Empty (T.Class_Locals) then
            if Debug_First_Pass then
               Put_Line ("  Locals for module " & Sym_Name (New_Mod) &
                 Treat_As_Type_Indicator (Mod_Sem) & ':');
            end if;
            First_Pass_List (Mod_Region, T.Class_Locals);
         end if;

         if not Lists.Is_Empty (T.Module_Exports)
           or else not Lists.Is_Empty (T.Module_New_Exports)
           or else not Lists.Is_Empty (T.Module_Implements)
         then
            if Debug_First_Pass then
               Put_Line ("  Exports for module " & Sym_Name (New_Mod) &
                 Treat_As_Type_Indicator (Mod_Sem) & ':');
            end if;
            First_Pass_List (Mod_Region, T.Module_Exports);
            First_Pass_List (Mod_Region, T.Module_New_Exports);
            First_Pass_List (Mod_Region, T.Module_Implements);
         end if;

         if not T.Is_Interface and then Mod_Sem.Other_Part /= null then
            --  Copy over the total number of components
            --  usable in an aggregate
            Mod_Sem.Num_Components_For_Aggregate :=
              Mod_Sem.Other_Part.Num_Components_For_Aggregate;
         end if;
      end if;

      if Debug_First_Pass then
         Put_Line ("End of module " & Sym_Name (New_Mod));
      end if;

      if T.Is_Interface
        and then
          (Languages.Language /= Languages.Sparkel or else T.Treat_As_Type)
      then
         --  See whether we are defining a builtin type/module.
         Builtin_Type_Init (Mod_Sem, Any_Str, Any_Type);
         Builtin_Type_Init (Mod_Sem, Assignable_Str, Assignable_Type);
         Builtin_Type_Init (Mod_Sem, Boolean_Str, Boolean_Type);
         Builtin_Type_Init (Mod_Sem, Ordering_Str, Ordering_Type);
         Builtin_Type_Init (Mod_Sem, Univ_Integer_Str, Univ_Integer_Type);
         Builtin_Type_Init (Mod_Sem, Univ_Real_Str, Univ_Real_Type);
         Builtin_Type_Init (Mod_Sem, Univ_Character_Str, Univ_Character_Type);
         Builtin_Type_Init (Mod_Sem, Univ_String_Str, Univ_String_Type);
         Builtin_Type_Init
           (Mod_Sem,
            Univ_Enumeration_Str,
            Univ_Enumeration_Type);
         Builtin_Type_Init (Mod_Sem, Optional_Str, Optional_Type);

         Builtin_Type_Init (Mod_Sem, Integer_Str, Integer_Current_Instance);
         if Integer_Module = null
           and then Integer_Current_Instance /= null
         then
            --  Initialize Integer_Module when
            --  Integer_Current_Instance initialized
            Integer_Module := Integer_Current_Instance.Associated_Module;
         end if;

         Builtin_Type_Init (Mod_Sem, Float_Str, Float_Current_Instance);
         if Float_Module = null
           and then Float_Current_Instance /= null
         then
            --  Initialize Float_Module when
            --  Float_Current_Instance initialized
            Float_Module := Float_Current_Instance.Associated_Module;
         end if;

         Builtin_Type_Init
           (Mod_Sem, Basic_Array_Str, Basic_Array_Current_Instance);
         if Basic_Array_Module = null
           and then Basic_Array_Current_Instance /= null
         then
            --  Initialize Basic_Array_Module when
            --  Basic_Array_Current_Instance initialized
            Basic_Array_Module :=
              Basic_Array_Current_Instance.Associated_Module;
         end if;
      end if;

   end Module_Action;

   procedure Implements_Element_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Implements_Element.Tree) is
   begin
      if not Lists.Is_Empty (T.Elements) then
         if Debug_First_Pass then
            if not Lists.Is_Empty (T.For_Interfaces) then
               Put ("  First pass for implements section for ");
               for I in 1 .. Lists.Length (T.For_Interfaces) loop
                  if I > 1 then
                     Put (", ");
                  end if;
                  Put
                    (Subtree_Image (Lists.Nth_Element (T.For_Interfaces, I)));
               end loop;
               New_Line;
            else
               Put_Line ("  First pass for implements-for-all section");
            end if;
         end if;
         --  TBD: Put these in separate sub-regions (at least those with
         --      a non-null For_Interfaces list).
         First_Pass_List (Visitor.Decl_Region, T.Elements);
      end if;
   end Implements_Element_Action;

   procedure Operation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Operation.Tree) is
      Op_Sem : constant Operation_Sem_Ptr := new Operation_Semantic_Info;
      Op_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (Operation_Param_Region_Kind);

      Enc_Region : Symbols.Region_Ptr := Visitor.Decl_Region;

      Is_Standalone_Operation : constant Boolean :=
        Enc_Region = Symbols.Library_Region;

      Op_Prefix : Optional_Tree := Null_Optional_Tree;

      New_Op : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Operation_Sym_Kind,
         Str => Strings.String_Lookup (Strings.Simple_Name
           (Subtree_Image (T.Name))),
         Full_Name => Strings.Null_U_String,
         Source_Pos => Operation.Find_Source_Pos (T),
         Enclosing_Region => null,  --  Will be filled in below
         Nested_Region => Op_Region,
         Sem_Info => Root_Sem_Ptr (Op_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);

      Enclosing_Mod_Sem : Module_Sem_Ptr := null;

      use type Operation.Operation_Kind_Enum;
   begin
      if Enc_Region.Associated_Symbol /= null
        and then Enc_Region.Associated_Symbol.Kind =
                 Module_Sym_Kind
      then
         --  Fill in Enclosing_Mod_Sem if immediately enclosed in a module.
         Enclosing_Mod_Sem :=
           Module_Sem_Ptr (Enc_Region.Associated_Symbol.Sem_Info);
      end if;

      if Lists.Length (T.Operation_Outputs) > 1 then
         --  TBD: We don't know how to handle multiple outputs yet
         Sem_Error
           (Lists.Nth_Element (T.Operation_Outputs, 2),
            "NYI: Multiple outputs not yet supported");
      end if;

      if Is_Null (T.Name) then
         New_Op.Enclosing_Region := Enc_Region;
         --  Generate a label from the source position
         New_Op.Str := Generate_Unique_Label (New_Op.Source_Pos, "$lambda_",
                                              Include_File => True);
      else
         --  Not a "lambda" or func type.
         Op_Prefix := Semantics.Prefix (T.Name);
         if Not_Null (Op_Prefix) then
            --  We have an operation name of the form "A::B::C" (or A.B.C)
            --  Look up enclosing modules if this is a stand-alone func.
            if not Is_Standalone_Operation then
               Sem_Error (Op_Prefix,
                 "Module prefix only permitted on stand-alone func's");
            else
               declare
                  Enc_Module : constant Module_Sem_Ptr :=
                    Lookup_Full_Module_Name
                       (Enc_Region, Op_Prefix);
               begin
                  if Enc_Module = null then
                     Sem_Error
                       (Op_Prefix, "Enclosing module not found");
                  else
                     --  Get region for sub-module
                     Enc_Region := Enc_Module.Nested_Region;
                  end if;
               end;
            end if;
         end if;

         New_Op.Enclosing_Region := Enc_Region;

         Add_To_Region (Enc_Region, New_Op);
         Check_For_Dups (New_Op);
      end if;

      --  Fill in semantic information

      Op_Sem.Operation_Kind    := T.Operation_Kind;
      Op_Sem.Definition        := New_Op.Definition;
      Op_Sem.Associated_Symbol := New_Op;
      Op_Sem.Nested_Region     := Op_Region;

      if Is_Standalone_Operation then
         --  This is a stand-alone operation; remember that in context.
         Op_Sem.Context := Standalone_Item_Context;

         if Lists.Is_Empty (T.Import_Clauses) then
            --  Create <prefix>::"*", or simply "*" if no prefix.
            New_Op.Import_Clauses := Default_Import_Clauses
              (Op_Prefix, Source_Pos => Operation.Find_Source_Pos (T));
         else
            New_Op.Import_Clauses := T.Import_Clauses;
         end if;
      end if;

      if T.Sem_Info /= null
        and then T.Sem_Info.all in Operation_Semantic_Info
      then
         --  Sem info already filled in.
         --  Retrieve from it some info we want inherited as well.
         declare
            Old_Op_Sem : constant Operation_Sem_Ptr :=
              Operation_Sem_Ptr (T.Sem_Info);
         begin
            Op_Sem.Originating_Module := Old_Op_Sem.Originating_Module;
            Op_Sem.Originating_Operation := Old_Op_Sem.Originating_Operation;
            Op_Sem.Overridden_By := Old_Op_Sem.Overridden_By;
            Op_Sem.Is_Abstract := Old_Op_Sem.Is_Abstract;
            --  Will be marked abstract in second pass
            --  if is an inherited constructor and there
            --  are new visible components in the current module.
            --  It is an error if there are private components and
            --  an inherited constructor is not overridden.

            --  Set the "Completion_Of" to point to original symbol
            --  so it won't be counted in current region
            Op_Sem.Associated_Symbol.Completion_Of :=
              Old_Op_Sem.Associated_Symbol;

            Op_Sem.Num_Cur_Inst_Inputs := Old_Op_Sem.Num_Cur_Inst_Inputs;
            Op_Sem.Num_Cur_Inst_Outputs := Old_Op_Sem.Num_Cur_Inst_Outputs;
            Op_Sem.First_Polymorphic_Input :=
              Old_Op_Sem.First_Polymorphic_Input;
            Op_Sem.Index := Old_Op_Sem.Index;
            if Debug_Second_Pass
              and then not T.Is_Abstract
              and then Op_Sem.Originating_Operation = null
            then
               Put_Line (" No originating op in inherited op:");
               Dump_Subtree (Op_Sem.Definition);
            end if;
         end;
      else
         --  Initialize Originating_Module from enclosing module
         --  and Originating_Operation from itself.
         Op_Sem.Originating_Module := Enclosing_Mod_Sem;
         Op_Sem.Originating_Operation := Op_Sem;
         Op_Sem.Is_Abstract := T.Is_Abstract
                              or else (not T.Is_Expression_Function
                                      and then Enclosing_Mod_Sem /= null
                                      and then Enclosing_Mod_Sem.Is_Abstract);
      end if;

      if Op_Sem.Operation_Kind in Operation.Operation_Type_Specifier then
         --  This is actually a func type.
         --  Create an appropriate Type_Semantic_Info
         declare
            Type_Sem : constant Type_Sem_Ptr :=
              new Type_Semantic_Info;
         begin
            Type_Sem.Associated_Module := Func_Type_Module;
            Type_Sem.Definition := Op_Sem.Definition;

            --  No copying needed
            --  TBD: unless we start capturing some context.
            Type_Sem.Known_To_Be_Small := True;

            --  Fill this in now, since normally filled in by Set_Type_Sem_Info
            Type_Sem.Outermost_Module_Where_Used :=
              Find_Enclosing_Module_Interface (Visitor.Decl_Region);

            --  This will be updated in Finish_Type_Sem_Info
            Type_Sem.All_Parameters_Known := False;

            --  Link the two Sem infos together
            Type_Sem.Func_Type_Op_Sem := Op_Sem;
            Op_Sem.Func_Type_Sem := Type_Sem;
         end;
      end if;

      --  Initialize the sem info in the Operation
      Set_Sem_Info (New_Op.Definition, New_Op.Sem_Info);

      Op_Region.Associated_Symbol := New_Op;
      Op_Region.Enclosing_Region := New_Op.Enclosing_Region;
      Op_Sem.Is_Def := T.Is_Def;
      Op_Sem.Is_Import := T.Is_Import;

      if Debug_First_Pass then
         Put_Line
           ("Create symbol for operation " &
            Sym_Name (New_Op) &
            "; sym_index =" &
            Sym_Index'Image (New_Op.Index));

         if not Lists.Is_Empty (T.Operation_Outputs) then
            Put_Line ("  Outputs:");
         end if;
      end if;
      First_Pass_List
        (Op_Region,
         T.Operation_Outputs,
         Visiting_Operation_Outputs => True,
         Processing_Inherited_Decl => Visitor.Processing_Inherited_Decl);

      if Debug_First_Pass
        and then not Lists.Is_Empty (T.Operation_Inputs)
      then
         Put_Line ("  Inputs:");
      end if;
      First_Pass_List (Op_Region, T.Operation_Inputs,
        Processing_Inherited_Decl => Visitor.Processing_Inherited_Decl);
      --  This sets Uses_Queuing to True if any param is a queued param.

      if Op_Sem.Uses_Queuing or else T.Is_Queued then
         --  Propagate this to enclosing module
         if Enclosing_Mod_Sem /= null
           and then Enclosing_Mod_Sem.Is_Concurrent
         then
            --  Mark concurrent module as using queuing
            Module_Sem_Ptr (Visitor.Decl_Region.Associated_Symbol.Sem_Info).
              Uses_Queuing := True;
         elsif Op_Sem.Uses_Queuing then
            --  Complain if immediately enclosing scope is not a
            --  concurrent module nor a module with a concurrent
            --  primary nested type.
            if Enclosing_Mod_Sem = null
              or else Enclosing_Mod_Sem.Primary_Nested_Type = null
              or else not Enclosing_Mod_Sem.
                Primary_Nested_Type.Associated_Module.Is_Concurrent
            then
               --  Immediately enclosing scope is not a concurrent module
               --  nor does it contain a concurrent primary nested type.
               --  Ok for operation to be marked "queued" even if
               --  not immediately enclosed by a concurrent module.
               --  That is *required* if an operation creates a concurrent
               --  object internally which has queuing, and then calls
               --  one of its queued operations.
               Sem_Error
                 (T,
                  "Operation with queued param must be associated with a " &
                  "concurrent module");
            end if;
         end if;

         --  Set Uses_Queuing if this function is explicitly
         --  marked as using queuing
         Op_Sem.Uses_Queuing := True;
      end if;

      if T.Is_Def and then not T.Is_Import then
         if Not_Null (T.Op_Location) then
            --  Specifies type from which to "borrow" operation
            First_Pass (Visitor.Decl_Region, T.Op_Location);

         elsif Not_Null (T.Op_Equiv) then
            --  This is a rename of an earlier operation
            --  Nothing to do at this stage
            null;

         else
            --  Regular body
            Op_Sem.Body_Region :=
              new Symbols.Region (Operation_Body_Region_Kind);
            Op_Sem.Body_Region.Enclosing_Region := Op_Region;
            Op_Sem.Body_Region.Associated_Symbol := New_Op;
            Lists.Append (Op_Sem.Body_Region.Stmt_List, T.Statements);
            First_Pass (Op_Sem.Body_Region, T.Statements);
         end if;
      end if;
   end Operation_Action;

   procedure Obj_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Obj_Decl.Tree) is
      Obj_Sem : constant Object_Sem_Ptr := new Object_Semantic_Info;

      New_Obj : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Object_Sym_Kind,
         Str => Strings.String_Lookup (Subtree_Image (T.Name)),
         Full_Name => Strings.Null_U_String,
         Source_Pos => Obj_Decl.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => null,
         Sem_Info => Root_Sem_Ptr (Obj_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
   begin
      Add_To_Region (Visitor.Decl_Region, New_Obj);

      --  Fill in semantic information
      Obj_Sem.Definition := New_Obj.Definition;
      Obj_Sem.Associated_Symbol := New_Obj;

      if Visitor.Decl_Region.Associated_Symbol /= null
        and then Visitor.Decl_Region.Associated_Symbol.Kind =
                 Module_Sym_Kind
        and then Decl_Is_For_Component (New_Obj.Definition)
      then
         --  This is actually a component, not a stand-alone object
         declare
            Enclosing_Mod_Sem : constant Module_Sem_Ptr :=
              Interface_Part
                 (Module_Sem_Ptr (
              Visitor.Decl_Region.Associated_Symbol.Sem_Info));
         begin
            New_Obj.Kind := Component_Sym_Kind;

            --  Fill in Originating_Module
            if T.Sem_Info /= null
              and then T.Sem_Info.all in Object_Semantic_Info
            then
               --  Sem info already filled in.
               --  Retrieve originating module and comp. index from it.
               Obj_Sem.Originating_Module :=
                 Object_Sem_Ptr (T.Sem_Info).Originating_Module;
               Obj_Sem.Component_Index :=
                 Object_Sem_Ptr (T.Sem_Info).Component_Index;
               if Enclosing_Mod_Sem.Ancestor_Module_With_Constructor = null
                 or else Obj_Sem.Originating_Module.Component_Extension_Level =
                         Enclosing_Mod_Sem.Component_Extension_Level
               then
                  --  This inherited component is usable in an aggregate
                  if Debug_First_Pass then
                     Put_Line
                       (" Inherited component of " &
                        Sym_Name (Enclosing_Mod_Sem.Associated_Symbol) &
                        " is usable in aggr: " &
                        Subtree_Image (T) &
                        ", index =" &
                        Natural'Image (Obj_Sem.Component_Index));
                  end if;
                  Enclosing_Mod_Sem.Num_Components_For_Aggregate :=
                    Enclosing_Mod_Sem.Num_Components_For_Aggregate + 1;
                  if Obj_Sem.Component_Index /=
                     Enclosing_Mod_Sem.Num_Components_For_Aggregate
                  then
                     Sem_Error
                       (T,
                        "Internal: Component index mismatch, " &
                        "inherited comp index =" &
                        Natural'Image (Obj_Sem.Component_Index) &
                        ", new index =" &
                        Natural'Image
                           (Enclosing_Mod_Sem.Num_Components_For_Aggregate));
                  end if;
               end if;
            else
               --  Initialize Originating_Module from enclosing module
               --  and bump count of components usable in aggregates.
               Obj_Sem.Originating_Module := Enclosing_Mod_Sem;
               Enclosing_Mod_Sem.Num_Components_For_Aggregate :=
                 Enclosing_Mod_Sem.Num_Components_For_Aggregate + 1;
               Obj_Sem.Component_Index :=
                 Enclosing_Mod_Sem.Num_Components_For_Aggregate;
               if Debug_First_Pass then
                  Put_Line
                    (" New component of " &
                     Sym_Name (Enclosing_Mod_Sem.Associated_Symbol) &
                     " is usable in aggr: " &
                     Subtree_Image (T) &
                     ", index =" &
                     Natural'Image (Obj_Sem.Component_Index));
               end if;
            end if;
         end;
      else
         --  Not a component.
         --  Assign it a unique object id.
         Obj_Sem.Object_Id := Object_Access.New_Object_Id (New_Obj);
      end if;

      Set_Sem_Info (New_Obj.Definition, New_Obj.Sem_Info);

      --  Now that we have decided whether it is a component, check for dups
      Check_For_Dups (New_Obj);

      if Debug_First_Pass then
         Put_Line
           ("Create symbol of kind " &
            Sym_Kind_Enum'Image (New_Obj.Kind) &
            " for " &
            Sym_Name (New_Obj) &
            "; sym_index =" &
            Sym_Index'Image (New_Obj.Index));
      end if;

      Visit (T.Obj_Value, Visitor);  --  In case value is aggregate
   end Obj_Decl_Action;

   procedure Param_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Param_Decl.Tree) is

      function Name_To_Use (T : Param_Decl.Tree) return String is
      --  If parameter is unnamed, then if this is an operation_output
      --  and there is exactly one, use name of enclosing "func";
      --  use type name as parameter name otherwise.
      begin
         if Not_Null (T.Name) then
            return Subtree_Image (T.Name);
         elsif Visitor.Visiting_Operation_Outputs then
            --  See whether we should use enclosing "func" name
            --  as parameter name.
            declare
               Enclosing_Operation_Tree : Operation.Tree
                 renames Operation.Tree (Tree_Ptr_Of
                   (Visitor.Decl_Region.Associated_Symbol.Definition).all);
               Enclosing_Operation_Name : String
                 renames Strings.Simple_Name
                   (Subtree_Image (Enclosing_Operation_Tree.Name));
                     --  Strip out everything but last part of name;
                     --  If "Mod::Func", then strip out "Mod".

               use Operation;
            begin
               if Enclosing_Operation_Tree.Operation_Kind in
                   Func_Proc_Specifier
                 and then Lists.Length
                             (Enclosing_Operation_Tree.Operation_Outputs) = 1
                 and then Enclosing_Operation_Name'Length > 0
                 and then Enclosing_Operation_Name
                   (Enclosing_Operation_Name'First) /= '"'
               then
                  --  OK, use the "func" name.
                  if Debug_First_Pass then
                     Put_Line
                       (" Using func " & Enclosing_Operation_Name &
                        " as param name");
                  end if;
                  return Enclosing_Operation_Name;
               end if;
            end;
         end if;

         --  Use the type name as param name.
         if Debug_First_Pass then
            Put_Line
              (" Using type " &
               Strings.Simple_Name (Subtree_Image (T.Param_Type)) &
               " as param name");
         end if;
         return Strings.Simple_Name (Subtree_Image (T.Param_Type));
         --  Strip out everything but last part of name;
         --  If "module<>", then strip out "<>"
      end Name_To_Use;

      use Param_Decl;
   begin
      if T.Is_Implicit_Module_Param
        and then Visitor.Decl_Region.Kind = Operation_Param_Region_Kind
      then
         --  If this is a parameter that is enclosed in <>
         --  and the immediately enclosing region is an
         --  Operation_Param_Region, then this is a "generic" operation,
         --  and we need to find/create an implicitly enclosing module
         --  to hold module parameter.
         --  TBD: Ideally, if we are in an operation "body"
         --      we would try to find the corresponding "spec"
         --      and use the hopefully pre-existing module.
         --      For now, we will have to wait until the second pass
         --      when we go and look for a corresponding spec.
         declare
            Op_Sem : constant Operation_Sem_Ptr :=
              Operation_Sem_Ptr (
              Visitor.Decl_Region.Associated_Symbol.Sem_Info);

            Param_Decl_Tree : constant Optional_Tree := Optional (T'Access);
         begin
            if Op_Sem.Implicit_Enclosing_Module = null then
               --  We need to create an implicit enclosing module
               --  and an associated region.
               Make_Implicit_Module (Visitor.Decl_Region, Op_Sem);
            end if;

            --  Add Param_Decl_Tree to list of module formals
            Lists.Append
              (Module.Tree (Tree_Ptr_Of
                (Op_Sem.Implicit_Enclosing_Module.Definition).all).
                  Module_Formals,
               Param_Decl_Tree);

            --  Now visit it with the proper enclosing region
            First_Pass
              (Op_Sem.Implicit_Enclosing_Module.Nested_Region,
               Param_Decl_Tree);

         end;
      else
         --  A "normal" object parameter
         declare
            Param_Sem : constant Param_Sem_Ptr := new Param_Semantic_Info;

            New_Param : constant Symbols.Sym_Ptr :=
              new Symbols.Symbol'
              (Kind => Param_Sym_Kind,
               Str => Strings.String_Lookup (Name_To_Use (T)),
               Full_Name => Strings.Null_U_String,
               Source_Pos => Param_Decl.Find_Source_Pos (T),
               Enclosing_Region => Visitor.Decl_Region,
               Nested_Region => null,
               Sem_Info => Root_Sem_Ptr (Param_Sem),
               Definition => Optional (T'Access),
               Completion_Of => null,
               Index => No_Sym_Index,
               Next_Homonym => No_Sym_Index,
               Import_Clauses => Lists.Empty_List);

         begin

            Add_To_Region (Visitor.Decl_Region, New_Param);
            if not Visitor.Processing_Inherited_Decl then
               --  Only worry about "dups" with a non-inherited declaration
               Check_For_Dups (New_Param);
            end if;

            --  Fill in semantic information
            Param_Sem.Definition := New_Param.Definition;
            Param_Sem.Associated_Symbol := New_Param;
            Param_Sem.Is_Implicit_Module_Param := T.Is_Implicit_Module_Param;
            Param_Sem.Object_Id := Object_Access.New_Object_Id (New_Param);

            if Visitor.Decl_Region.Kind = Module_Region_Kind then
               --  Fill in Originating_Module
               if T.Sem_Info /= null
                 and then T.Sem_Info.all in Param_Semantic_Info
               then
                  --  Sem info already filled in.
                  --  Retrieve originating module from it.
                  Param_Sem.Originating_Module :=
                    Param_Sem_Ptr (T.Sem_Info).Originating_Module;
               else
                  --  Initialize Originating_Module from enclosing module.
                  Param_Sem.Originating_Module :=
                    Module_Sem_Ptr (
                    Visitor.Decl_Region.Associated_Symbol.Sem_Info);
               end if;
            end if;
            Set_Sem_Info (New_Param.Definition, New_Param.Sem_Info);

            Visit (T.Param_Type, Visitor);  --  In case type is "generic"

            if T.Locking = Queued_Param then
               --  Mark enclosing operation as Uses_Queuing
               --  (presuming it is an operation rather than a module).
               if Visitor.Decl_Region.Associated_Symbol.Kind /=
                  Operation_Sym_Kind
               then
                  Sem_Error (T, "Queued param not allowed on module");
               else
                  Operation_Sem_Ptr (
                    Visitor.Decl_Region.Associated_Symbol.Sem_Info).
                    Uses_Queuing := True;
               end if;
            end if;

            if Debug_First_Pass then
               Put_Line
                 ("Create symbol for parameter " &
                  Sym_Name (New_Param) &
                  "; sym_index =" &
                  Sym_Index'Image (New_Param.Index));
            end if;

            Visit (T.Param_Default, Visitor);  --  In case value is aggregate
         end;
      end if;
   end Param_Decl_Action;

   procedure Type_Decl_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Type_Decl.Tree) is

      function Name_To_Use (T : Type_Decl.Tree) return String is
      --  If Type is unnamed, then use module name as Type name
      begin
         if Not_Null (T.Name) then
            return Subtree_Image (T.Name);
         else
            return Strings.Simple_Name (Subtree_Image (T.Type_Definition));
            --  Strip out everything but last part of name;
            --  If "module<>", then strip out "<>"
         end if;
      end Name_To_Use;

      Type_Decl_Tree : constant Optional_Tree := Optional (T'Access);

   begin
      if T.Sem_Info /= null and then T.Is_New_Type then
         --  Preserve semantic info for "new" types
         return;  --  Nothing to do
      end if;

      if Visitor.Decl_Region.Kind = Operation_Param_Region_Kind then
         --  If immediately enclosing region is an Operation_Param_Region,
         --  then this is a "generic" operation, and we need to
         --  find/create an implicitly enclosing module to hold this
         --  type parameter.
         --  TBD: Ideally, if we are in an operation "body"
         --      we would try to find the corresponding "spec"
         --      and use the hopefully pre-existing module.
         --      For now, we will have to wait until the second pass
         --      when we go and look for a corresponding spec.
         declare
            Enclosing_Op_Region : Region_Ptr := Visitor.Decl_Region;
         begin
            --  See whether we are in a formal operation; if so
            --  find the enclosing non-formal operation.
            --  TBD: Handle case where we are in a formal operation
            --       of a module, in which case this would become
            --       an extra implicit parameter of the (explicit) module,
            --       rather than a parameter of an implicit module.

            while Enclosing_Op_Region.Enclosing_Region /= null
              and then Enclosing_Op_Region.Enclosing_Region.Kind =
                Operation_Param_Region_Kind
            loop
               Enclosing_Op_Region := Enclosing_Op_Region.Enclosing_Region;
            end loop;

            declare
               Op_Sem : constant Operation_Sem_Ptr :=
                 Operation_Sem_Ptr (
                   Enclosing_Op_Region.Associated_Symbol.Sem_Info);
            begin
               if Op_Sem.Implicit_Enclosing_Module = null then
                  --  We need to create an implicit enclosing module
                  --  and an associated region.
                  Make_Implicit_Module (Enclosing_Op_Region, Op_Sem);
               end if;

               --  Add Type_Decl_Tree to list of module formals
               Lists.Append
                 (Module.Tree (Tree_Ptr_Of
                   (Op_Sem.Implicit_Enclosing_Module.Definition).all).
                     Module_Formals,
                  Type_Decl_Tree);

               --  Now visit it with the proper enclosing region
               First_Pass
                 (Op_Sem.Implicit_Enclosing_Module.Nested_Region,
                  Type_Decl_Tree);

            end;
         end;
      else
         --  Not a parameter of a "generic" operation, so declare the
         --  type

         declare
            Type_Sem : constant Type_Sem_Ptr := new Type_Semantic_Info;

            New_Type : constant Symbols.Sym_Ptr :=
              new Symbols.Symbol'
              (Kind => Type_Sym_Kind,
               Str => Strings.String_Lookup (Name_To_Use (T)),
               Full_Name => Strings.Null_U_String,
               Source_Pos => Type_Decl.Find_Source_Pos (T),
               Enclosing_Region => Visitor.Decl_Region,
               Nested_Region => null,
               Sem_Info => Root_Sem_Ptr (Type_Sem),
               Definition => Type_Decl_Tree,
               Completion_Of => null,
               Index => No_Sym_Index,
               Next_Homonym => No_Sym_Index,
               Import_Clauses => Lists.Empty_List);
         begin
            --  Fill in semantic information
            Type_Sem.Definition := New_Type.Definition;
            Type_Sem.Associated_Symbol := New_Type;
            Set_Sem_Info (New_Type.Definition, New_Type.Sem_Info);

            Visit (T.Type_Definition, Visitor);

            --  Add type to appropriate enclosing region (after module)
            Add_To_Region (New_Type.Enclosing_Region, New_Type);

            Check_For_Dups (New_Type);

            if Type_Def_Has_New_Module (T.Type_Definition) then
               --  Fill in Associated_Module, knowing that
               --  Prefix of type definition is a module definition.
               Type_Sem.Associated_Module :=
                 Module_Sem_Ptr (Sem_Info (Invocation.Tree
                   (Tree_Ptr_Of (T.Type_Definition).all).Prefix));
               pragma Assert (Type_Sem.Associated_Module /= null);
               pragma Assert (Type_Sem.Associated_Module.Cur_Inst_Sem /= null);
               if Debug_First_Pass then
                  Put_Line (" Setting Associated_Module for " &
                    Subtree_Image (T, Use_Short_Form => True) & " is " &
                    Subtree_Image (Type_Sem.Associated_Module.Definition) &
                    ", Type_Image = " &
                    Type_Image (Type_Sem));
               end if;

            end if;

            if Is_Private_Type_Decl (Type_Sem.Definition) then
               --  Is a private type, fill in External_View but leave
               --  Full_View null.
               Type_Sem.External_View := Type_Sem;
            else
               --  Not a private type, check for a prior type decl.
               declare
                  Prior_Decl_Sym : Symbols.Sym_Ptr :=
                    Next_Homonym_In_Region (New_Type);
               begin
                  if Prior_Decl_Sym /= null
                    and then Prior_Decl_Sym.Kind = Module_Sym_Kind
                  then
                     --  Skip past the module for this type, if any
                     Prior_Decl_Sym :=
                       Next_Homonym_In_Region (Prior_Decl_Sym);
                  end if;

                  if Prior_Decl_Sym /= null
                    and then Prior_Decl_Sym.Kind = Type_Sym_Kind
                    and then Is_Private_Type_Decl (Prior_Decl_Sym.Definition)
                  then
                     --  Found a private type.
                     --  External_View for this type is the private type.
                     --  Full_View for the private type is this type.
                     declare
                        External_View : constant Type_Sem_Ptr :=
                          Type_Sem_Ptr (Prior_Decl_Sym.Sem_Info);
                     begin
                        --  This type is a full view of a private type.
                        Type_Sem.Full_View := Type_Sem;
                        Type_Sem.External_View := External_View;
                        External_View.Full_View := Type_Sem;
                        if Debug_First_Pass then
                           Put_Line
                             (" Found a prior private type decl: " &
                                Subtree_Image (Prior_Decl_Sym.Definition));
                        end if;
                     end;
                  end if;
               end;
            end if;

            if Debug_First_Pass then
               Put_Line
                 ("Create symbol for Type " &
                  Sym_Name (New_Type) &
                  "; sym_index =" &
                  Sym_Index'Image (New_Type.Index));
            end if;
         end;
      end if;

   end Type_Decl_Action;

   procedure Binary_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Binary.Tree) is
      use Binary;
   begin
      if T.Operator = Parallel_Stmt_Op then
         --  Create new region for right side of "||",
         --  and optionally for left side as well.
         declare
            Comp_Sem : constant Computation_Sem_Ptr :=
              new Computation_Semantic_Info;
            Right_Operand_Region : constant Symbols.Region_Ptr :=
              new Symbols.Region (Parallel_Stmt_Region_Kind);

            --  Create symbol for use by Outermost_Master
            Parallel_Op_Sym : constant Symbols.Sym_Ptr :=
              new Symbols.Symbol'
              (Kind => Statement_Sym_Kind,
               Str => Strings.Null_U_String,
               Full_Name => Strings.Null_U_String,
               Source_Pos => Binary.Find_Source_Pos (T),
               Enclosing_Region => Visitor.Decl_Region,
               Nested_Region => Right_Operand_Region,
               Sem_Info => Root_Sem_Ptr (Comp_Sem),
               Definition => Optional (T'Access),
               Completion_Of => null,
               Index => No_Sym_Index,
               Next_Homonym => No_Sym_Index,
               Import_Clauses => Lists.Empty_List);
            Left_Operand_Region : Symbols.Region_Ptr := Visitor.Decl_Region;
         --  Use enclosing region by default
         begin
            T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
            Comp_Sem.Definition := Optional (T'Access);

            Right_Operand_Region.Associated_Symbol := Parallel_Op_Sym;

            Comp_Sem.Nested_Region := Right_Operand_Region;
            --  We use the Right_Operand_Region since we always create
            --  that one.  The "Next_Sibling_Region" is the left region
            --  if we have one.

            Right_Operand_Region.Enclosing_Region := Visitor.Decl_Region;
            if not Binary.Is_Parallel_Stmt_Op (T.Left_Operand) then
               --  Allocate a new region unless is itself "||" invocation
               Left_Operand_Region :=
                 new Symbols.Region (Parallel_Stmt_Region_Kind);
               Left_Operand_Region.Enclosing_Region := Visitor.Decl_Region;
               Left_Operand_Region.Associated_Symbol := Parallel_Op_Sym;
               Right_Operand_Region.Next_Sibling_Region :=
                 Left_Operand_Region;
            end if;

            --  Visit left operand with appropriate region
            Visitor.Decl_Region := Left_Operand_Region;
            Visit (T.Left_Operand, Visitor);

            --  Visit right operand with new region
            Visitor.Decl_Region := Right_Operand_Region;
            Visit (T.Right_Operand, Visitor);

            --  Restore region
            Visitor.Decl_Region := Right_Operand_Region.Enclosing_Region;

         end;
      else
         Visit (T.Left_Operand, Visitor);
         Visit (T.Right_Operand, Visitor);
      end if;
   end Binary_Action;

   procedure Unary_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Unary.Tree) is
   begin
      Visit (T.Operand, Visitor);
   end Unary_Action;

   procedure Annotation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Annotation.Tree) is
   begin
      First_Pass_List (Visitor.Decl_Region, T.Annotations,
        Processing_Inherited_Decl => Visitor.Processing_Inherited_Decl);
   end Annotation_Action;

   procedure Assign_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Assign_Stmt.Tree) is
   begin
      Visit (T.LHS, Visitor);
      Visit (T.RHS, Visitor);
      declare
         LHS_Tree : Trees.Tree'Class renames Tree_Ptr_Of (T.LHS).all;
         use Invocation;
      begin
         if LHS_Tree in Invocation.Tree
           and then Invocation.Tree (LHS_Tree).Kind = Class_Aggregate
         then
            Sem_Error
              (T.LHS,
               "NYI: Aggregate as LHS of assignment not yet supported");
         end if;
      end;
   end Assign_Stmt_Action;

   procedure Block_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Block_Stmt.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        new Composite_Stmt_Semantic_Info;
      Block_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (Block_Stmt_Region_Kind);
      Block_Label : constant Strings.U_String := U_String_Or_Null (T.Label);
      Block_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Statement_Sym_Kind,
         Str => Block_Label,
         Full_Name => Strings.Null_U_String,
         Source_Pos => Block_Stmt.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => Block_Region,
         Sem_Info => Root_Sem_Ptr (Comp_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
   begin
      if Block_Label = Strings.Null_U_String then
         Block_Sym.Str :=
            Generate_Unique_Label (Block_Sym.Source_Pos, "block_");
      end if;

      T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
      Block_Region.Enclosing_Region := Visitor.Decl_Region;
      Block_Region.Associated_Symbol := Block_Sym;
      Comp_Sem.Nested_Region := Block_Region;
      Comp_Sem.Definition := Block_Sym.Definition;

      --  Add label to region
      Add_To_Region (Visitor.Decl_Region, Block_Sym);
      Check_For_Dups (Block_Sym);

      --  Set region for nested block
      Visitor.Decl_Region := Block_Region;
      Visit (T.Block_Body, Visitor);
      Visit (T.End_With_Values, Visitor);

      --  Restore region
      Visitor.Decl_Region := Block_Region.Enclosing_Region;
   end Block_Stmt_Action;

   procedure Case_Construct_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Case_Construct.Tree) is
      Case_Sem : constant Case_Construct_Sem_Ptr :=
        new Case_Construct_Semantic_Info;
      Prev_Alt_Region : Region_Ptr := null;
      Case_Label : constant Strings.U_String := U_String_Or_Null (T.Label);
      Case_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Statement_Sym_Kind,
         Str => Case_Label,
         Full_Name => Strings.Null_U_String,
         Source_Pos => Case_Construct.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => null,
         Sem_Info => Root_Sem_Ptr (Case_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);

      --  Create new Sym_Ptr with altered name
      function Uniquify_Name (Sym : Symbols.Sym_Ptr; Index : Integer)
         return Symbols.Sym_Ptr is
         --  Turn Index into a string
         Image_Space : String := Integer'Image (Index);
         Image : String :=
            Image_Space (Image_Space'First + 1 .. Image_Space'Last);
         --  copy all but the name
         --  So each alternative can have a unique label
         Result : constant Symbols.Sym_Ptr :=
           new Symbols.Symbol'
           (Kind =>             Sym.Kind,
            Str => Strings.String_Lookup
               (Strings.To_String (Sym.Str) & "_" & Image),
            Full_Name => Strings.Null_U_String,
            Source_Pos =>       Sym.Source_Pos,
            Enclosing_Region => Sym.Enclosing_Region,
            Nested_Region =>    Sym.Nested_Region,
            Sem_Info =>         Sym.Sem_Info,
            Definition =>       Sym.Definition,
            Completion_Of =>    Sym.Completion_Of,
            Index =>            Sym.Index,
            Next_Homonym =>     Sym.Next_Homonym,
            Import_Clauses =>   Sym.Import_Clauses);
      begin
         return Result;
      end Uniquify_Name;

   begin  --  Case_Construct_Action
      if Case_Label = Strings.Null_U_String then
         Case_Sym.Str :=
            Generate_Unique_Label (Case_Sym.Source_Pos, "case_");
      end if;

      T.Sem_Info := Root_Sem_Ptr (Case_Sem);
      Case_Sem.Definition := Case_Sym.Definition;
      Case_Sem.Case_Selector := T.Case_Selector;

      --  Add label to region
      Add_To_Region (Visitor.Decl_Region, Case_Sym);
      Check_For_Dups (Case_Sym);

      Visit (T.Case_Selector, Visitor);

      --  Create separate regions for each case alternative
      for I in 1 .. Lists.Length (T.Case_Alt_List) loop
         declare
            Next_Alt_Region : Region_Ptr :=
              new Symbols.Region (Case_Stmt_Region_Kind);
         --  Region for next case alternative
         begin
            Next_Alt_Region.Enclosing_Region := Visitor.Decl_Region;
            if Prev_Alt_Region = null then
               --  First alternative
               Case_Sem.Nested_Region := Next_Alt_Region;
               Case_Sym.Nested_Region := Next_Alt_Region;
               Next_Alt_Region.Associated_Symbol := Case_Sym;
            else
               --  Link to prev alternative
               Prev_Alt_Region.Next_Sibling_Region := Next_Alt_Region;
               Next_Alt_Region.Associated_Symbol :=
                  Uniquify_Name (Case_Sym, I);
            end if;
            Prev_Alt_Region := Next_Alt_Region;    --  Remember for next
                                                   --  iteration

            --  Actually process the alternative
            First_Pass
              (Next_Alt_Region,
               Lists.Nth_Element (T.Case_Alt_List, I));
         exception
            when E : others =>
               Sem_Error
                 (Lists.Nth_Element (T.Case_Alt_List, I),
                  "Internal: " &
                  Ada.Exceptions.Exception_Name (E) &
                  " raised in");
         end;
      end loop;
      Visit (T.End_With_Values, Visitor);
   end Case_Construct_Action;

   procedure Control_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Control_Stmt.Tree) is
   begin
      Visit (T.Values, Visitor);
   end Control_Stmt_Action;

   procedure Conditional_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Conditional.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        new Composite_Stmt_Semantic_Info;
      Then_Part_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (If_Stmt_Region_Kind);
      --  Region for the Then part
      Else_Part_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (If_Stmt_Region_Kind);
      --  Region for the Else part
      Cond_Label : constant Strings.U_String := U_String_Or_Null (T.Label);
      Cond_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Statement_Sym_Kind,
         Str => Cond_Label,
         Full_Name => Strings.Null_U_String,
         Source_Pos => Conditional.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => Then_Part_Region,
         Sem_Info => Root_Sem_Ptr (Comp_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);

      --  Make copy except name, uniquify that
      Else_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind =>             Cond_Sym.Kind,
         Str => Strings.String_Lookup
            (Strings.To_String (Cond_Sym.Str) & "else"),
         Full_Name => Strings.Null_U_String,
         Source_Pos =>       Cond_Sym.Source_Pos,
         Enclosing_Region => Cond_Sym.Enclosing_Region,
         Nested_Region =>    Cond_Sym.Nested_Region,
         Sem_Info =>         Cond_Sym.Sem_Info,
         Definition =>       Cond_Sym.Definition,
         Completion_Of =>    Cond_Sym.Completion_Of,
         Index =>            Cond_Sym.Index,
         Next_Homonym =>     Cond_Sym.Next_Homonym,
         Import_Clauses =>   Cond_Sym.Import_Clauses);
   begin

      if Cond_Label = Strings.Null_U_String then
         Cond_Sym.Str := Generate_Unique_Label (Cond_Sym.Source_Pos, "then_");
         Else_Sym.Str := Generate_Unique_Label (Else_Sym.Source_Pos, "else_");
      end if;

      T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
      Comp_Sem.Nested_Region := Then_Part_Region;
      Then_Part_Region.Enclosing_Region := Visitor.Decl_Region;
      Else_Part_Region.Enclosing_Region := Visitor.Decl_Region;
      Then_Part_Region.Next_Sibling_Region := Else_Part_Region;

      Then_Part_Region.Associated_Symbol := Cond_Sym;
      Else_Part_Region.Associated_Symbol := Else_Sym;
      Comp_Sem.Definition := Cond_Sym.Definition;

      --  Add label to region
      Add_To_Region (Visitor.Decl_Region, Cond_Sym);
      Check_For_Dups (Cond_Sym);

      --  Visit the condition
      Visit (T.Cond, Visitor);

      --  Visit the "then" part with a new region
      Visitor.Decl_Region := Then_Part_Region;
      Visit (T.Then_Part, Visitor);

      --  Visit the "else" part with a new region
      Visitor.Decl_Region := Else_Part_Region;
      Visit (T.Else_Part, Visitor);

      --  Restore region
      Visitor.Decl_Region := Else_Part_Region.Enclosing_Region;

      Visit (T.End_With_Values, Visitor);
   end Conditional_Action;

   procedure For_Loop_Construct_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out For_Loop_Construct.Tree) is
      Loop_Param_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (Loop_Param_Region_Kind);
      --  Region for the loop parameters
      Loop_Body_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (Loop_Body_Region_Kind);
      --  Region for the loop body
      For_Loop_Sem : constant For_Loop_Construct_Sem_Ptr :=
        new For_Loop_Construct_Semantic_Info;
      Loop_Label : constant Strings.U_String := U_String_Or_Null (T.Label);
      Loop_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Statement_Sym_Kind,
         Str => Loop_Label,
         Full_Name => Strings.Null_U_String,
         Source_Pos => For_Loop_Construct.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => Loop_Body_Region,
         Sem_Info => Root_Sem_Ptr (For_Loop_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
      use type Strings.U_String;
      use type Interpreter.Direction;
      use type For_Loop_Construct.For_Loop_Kind_Enum;
   begin
      if T.Sem_Info /= null then
         --  Probably inside Evaluate_Tree
         return;
      end if;

      if Loop_Label = Strings.Null_U_String
        and then T.Kind = For_Loop_Construct.For_Loop_Statement
      then
         Loop_Sym.Str := Generate_Unique_Label (Loop_Sym.Source_Pos, "for_");
      end if;

      T.Sem_Info := Root_Sem_Ptr (For_Loop_Sem);

      --  Initialize For_Loop sem info
      For_Loop_Sem.Definition := Loop_Sym.Definition;
      For_Loop_Sem.Nested_Region := Loop_Body_Region;
      For_Loop_Sem.Loop_Param_Region := Loop_Param_Region;
      Loop_Body_Region.Associated_Symbol := Loop_Sym;

      if T.Kind = For_Loop_Construct.For_Loop_Statement then
         --  Add label to region
         Add_To_Region (Visitor.Decl_Region, Loop_Sym);
         Check_For_Dups (Loop_Sym);
      end if;

      --  Determine direction of iteration
      For_Loop_Sem.For_Loop_Direction := Get_Direction (T, T.Direction);

      if For_Loop_Sem.For_Loop_Direction = Interpreter.Concurrent_Dir then
         --  We have an explicitly concurrent loop
         For_Loop_Sem.Is_Potentially_Concurrent := True;
      end if;

      --  Link regions together
      Loop_Param_Region.Enclosing_Region := Visitor.Decl_Region;
      Loop_Body_Region.Enclosing_Region := Loop_Param_Region;

      --  Associate iterators with the loop-param region
      Loop_Param_Region.Stmt_List := T.Iterators;

      --  Associate loop body with its region
      Lists.Append (Loop_Body_Region.Stmt_List, T.Loop_Body);

      --  Process iterators and loop body
      First_Pass_List (Loop_Param_Region, T.Iterators);

      --  Link sem info between iterators and for-loop
      For_Loop_Sem.Iterator_Sems :=
        new Iterator_Sem_Array (1 .. Lists.Length (T.Iterators));
      for I in For_Loop_Sem.Iterator_Sems'Range loop
         declare
            Ith_Iterator : constant Iterator_Sem_Ptr :=
              Iterator_Sem_Ptr (Sem_Info
                                   (Lists.Nth_Element (T.Iterators, I)));
         begin
            For_Loop_Sem.Iterator_Sems (I) := Ith_Iterator;
            Ith_Iterator.Iterator_Index := I;
            Ith_Iterator.Enclosing_For_Loop := For_Loop_Sem;
            if Ith_Iterator.Num_Next_Values > 1 then
               --  We have concurrency due to multiple "next" values
               For_Loop_Sem.Is_Potentially_Concurrent := True;
            end if;
         end;
      end loop;

      First_Pass (Loop_Param_Region, T.Filter);

      First_Pass (Loop_Body_Region, T.Loop_Body);
      First_Pass (Loop_Param_Region, T.End_With_Values);
   end For_Loop_Construct_Action;

   procedure Invocation_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Invocation.Tree) is
   --  Walk contents of container aggregate in case this is a "case"
   --  and it introduces an identifier.
   begin
      if T.Sem_Info /= null then
         return;  --  Probably inside Evaluate_Tree
      end if;

      Visit (T.Prefix, Visitor);
      First_Pass_List (Visitor.Decl_Region, T.Operands);
      if Not_Null (T.Extends) then
         Sem_Error
           (T.Extends,
            "NYI: extension at point of instantiation not yet supported");
         Visit (T.Extends, Visitor);
      end if;
   end Invocation_Action;

   procedure Iterator_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Iterator.Tree) is
      Iterator_Sem : constant Iterator_Sem_Ptr := new Iterator_Semantic_Info;

      Iterator_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Loop_Param_Sym_Kind,
         Str => T.Name.Str,
         Full_Name => Strings.Null_U_String,
         Source_Pos => Iterator.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => null,
         Sem_Info => Root_Sem_Ptr (Iterator_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
   begin
      if T.Sem_Info /= null then
         --  Probably inside Evaluate_Tree
         return;
      end if;

      Add_To_Region (Visitor.Decl_Region, Iterator_Sym);
      Check_For_Dups (Iterator_Sym);

      --  Fill in semantic information
      Iterator_Sem.Definition := Iterator_Sym.Definition;
      Iterator_Sem.Associated_Symbol := Iterator_Sym;
      Iterator_Sem.Object_Id := Object_Access.New_Object_Id (Iterator_Sym);
      T.Sem_Info := Iterator_Sym.Sem_Info;

      Iterator_Sem.Iterator_Direction := Get_Direction (T, T.Direction);

      if Debug_First_Pass then
         Put_Line
           ("Create symbol for iterator " &
            Sym_Name (Iterator_Sym) &
            "; sym_index =" &
            Sym_Index'Image (Iterator_Sym.Index));
      end if;

      if T.Kind in Iterator.Container_Iterator then
         --  We have a for-each iterator, so there is a key/index
         --  for each element, either named or anonymous.
         declare
            Key_Sem : constant Param_Sem_Ptr := new Param_Semantic_Info;

            Key_Sym : constant Symbols.Sym_Ptr :=
              new Symbols.Symbol'
              (Kind => Loop_Key_Param_Sym_Kind,
               Str => Strings.Null_U_String,
               Full_Name => Strings.Null_U_String,
               Source_Pos => Iterator.Find_Source_Pos (T),
               Enclosing_Region => Visitor.Decl_Region,
               Nested_Region => null,
               Sem_Info => Root_Sem_Ptr (Key_Sem),
               Definition => T.Key_Name,
               Completion_Of => null,
               Index => No_Sym_Index,
               Next_Homonym => No_Sym_Index,
               Import_Clauses => Lists.Empty_List);
         begin
            --  Fill in information for key (whether named or anon)
            Key_Sem.Associated_Symbol := Key_Sym;
            Key_Sem.Definition := Key_Sym.Definition;
            Key_Sem.Object_Id := Object_Access.New_Object_Id (Key_Sym);
            Iterator_Sem.Key_Sem := Key_Sem;

            if Not_Null (T.Key_Name) then
               --  We have a "named" key
               Key_Sym.Str :=
                 Identifier.Tree (Tree_Ptr_Of (T.Key_Name).all).Str;
               Key_Sym.Source_Pos := Find_Source_Pos (T.Key_Name);
               Add_To_Region (Visitor.Decl_Region, Key_Sym);
               Set_Sem_Info (T.Key_Name, Root_Sem_Ptr (Key_Sem));
            end if;

         end;
      end if;

      Visit (T.Obj_Type, Visitor);
      Visit (T.Obj_Value, Visitor);
      First_Pass_List (Visitor.Decl_Region, T.Next_Values);
      --  Determine number of "next" values provided in iterator.
      if T.Kind in Iterator.Value_Iterator then
         Iterator_Sem.Num_Next_Values := Lists.Length (T.Next_Values);
      else
         Iterator_Sem.Num_Next_Values := 1;
      end if;
      Visit (T.While_Cond, Visitor);
   end Iterator_Action;

   procedure Reference_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out Reference.Tree) is
   begin
      Visit (T.Key, Visitor);
      Visit (T.Referent, Visitor);
   end Reference_Action;

   procedure While_Stmt_Action
     (Visitor : in out Sem_First_Pass_Visitor;
      T : in out While_Stmt.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        new Composite_Stmt_Semantic_Info;
      Loop_Body_Region : constant Symbols.Region_Ptr :=
        new Symbols.Region (Loop_Body_Region_Kind);
      --  Region for the loop body
      Loop_Label : constant Strings.U_String := U_String_Or_Null (T.Label);
      Loop_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Statement_Sym_Kind,
         Str => Loop_Label,
         Full_Name => Strings.Null_U_String,
         Source_Pos => While_Stmt.Find_Source_Pos (T),
         Enclosing_Region => Visitor.Decl_Region,
         Nested_Region => Loop_Body_Region,
         Sem_Info => Root_Sem_Ptr (Comp_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
   begin

      if Loop_Label = Strings.Null_U_String then
         Loop_Sym.Str := Generate_Unique_Label (Loop_Sym.Source_Pos, "while_");
      end if;

      T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
      Loop_Body_Region.Enclosing_Region := Visitor.Decl_Region;
      Comp_Sem.Nested_Region := Loop_Body_Region;
      Loop_Body_Region.Associated_Symbol := Loop_Sym;
      Comp_Sem.Definition := Loop_Sym.Definition;

      --  Add label to region
      Add_To_Region (Visitor.Decl_Region, Loop_Sym);
      Check_For_Dups (Loop_Sym);

      Visit (T.While_Cond, Visitor);
      Visitor.Decl_Region := Loop_Body_Region;
      Visit (T.Loop_Body, Visitor);
      Visitor.Decl_Region := Loop_Body_Region.Enclosing_Region;
      Visit (T.End_With_Values, Visitor);
   end While_Stmt_Action;

   ------------- Second pass actions ------------

   type Sem_Second_Pass_Visitor is new Visitor.RW_Tree_Visitor with record
      Decl_Region : Symbols.Region_Ptr;
      Context : Context_Enum := No_Context;
      Mode : Analysis_Mode := Decls_And_Exprs;
      May_Override : Overriding_State := Unspecified;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      --  This is only used for Module_Actual_Of_Formal_Context
      Decl_For_Annotations : Optional_Tree := Null_Optional_Tree;
      --  This is the "current" declaration which is relevant
      --  when processing type and object annotations.
   end record;

   procedure Pre_Visit
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Trees.Tree'Class);

   procedure Post_Visit
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Trees.Tree'Class);

   procedure Module_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Module.Tree);

   procedure Implements_Element_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Implements_Element.Tree);

   procedure Operation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Operation.Tree);

   procedure Obj_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Obj_Decl.Tree);

   procedure Param_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Param_Decl.Tree);

   procedure Type_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Type_Decl.Tree);

   procedure Qualifier_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Qualifier.Tree);

   procedure Unary_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Unary.Tree);

   procedure Binary_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Binary.Tree);

   procedure Annotation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Annotation.Tree);

   procedure Identifier_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Identifier.Tree);

   procedure Qualified_Name_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Qualified_Name.Tree);

   procedure Assign_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Assign_Stmt.Tree);

   procedure Invocation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Invocation.Tree);

   procedure Block_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Block_Stmt.Tree);

   procedure Case_Construct_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Case_Construct.Tree);

   procedure Control_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Control_Stmt.Tree);

   procedure Conditional_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Conditional.Tree);

   procedure For_Loop_Construct_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out For_Loop_Construct.Tree);

   procedure Iterator_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Iterator.Tree);

   procedure While_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out While_Stmt.Tree);

   procedure Selection_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Selection.Tree);

   procedure Reference_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Reference.Tree);

   -----------

   function Create_From_Univ_Call
     (Operand : Optional_Tree;
      To_Type : Type_Sem_Ptr)
      return Optional_Tree;
   --  Create call on "from_univ" from given Operand which
   --  is of a universal type, to the target To_Type.

   function Equiv_Decls (Left, Right : Sem_Ptr) return Boolean is
      --  Return True if Left and Right are "equivalent" entities.
      --  In particular, this treats spec and body parameters as
      --  equivalent.
      use type Ada.Tags.Tag;
   begin
      if Left = Right then
         return True;
      elsif Left'Tag /= Right'Tag then
         return False;
      elsif Left.Associated_Symbol = null
        or else Right.Associated_Symbol = null
        or else Left.Associated_Symbol.Str /= Right.Associated_Symbol.Str
      then
         return False;
      elsif Left.Associated_Symbol.Enclosing_Region =
            Right.Associated_Symbol.Enclosing_Region
      then
         return True;
      else
         declare
            Left_Region_Sym : constant Sym_Ptr :=
              Left.Associated_Symbol.Enclosing_Region.Associated_Symbol;
            Right_Region_Sym : constant Sym_Ptr :=
              Right.Associated_Symbol.Enclosing_Region.Associated_Symbol;
         begin
            if Left_Region_Sym /= null
              and then Left_Region_Sym.Sem_Info /= null
              and then Right_Region_Sym /= null
              and then Right_Region_Sym.Sem_Info /= null
              and then
                (Left_Region_Sym.Sem_Info.all in Operation_Semantic_Info
                   or else
                 Left_Region_Sym.Sem_Info.all in Module_Semantic_Info)
              and then Equiv_Decls
                (Sem_Ptr (Left_Region_Sym.Sem_Info),
                 Sem_Ptr (Right_Region_Sym.Sem_Info))
            then
               return True;
            elsif Left.all in Operation_Semantic_Info
              and then (Operation_Sem_Ptr (Left).Spec_Sem =
                        Operation_Sem_Ptr (Right)
                       or else Operation_Sem_Ptr (Right).Spec_Sem =
                               Operation_Sem_Ptr (Left))
            then
               return True;
            else
               return False;
            end if;
         end;
      end if;
   end Equiv_Decls;

   function Equiv_Tree (Left, Right : Optional_Tree) return Boolean is
      --  Return True if Left and Right are equivalent as far as use
      --  as parameters in a module instantiation.
      Left_Sem : constant Sem_Ptr :=
        Underlying_Sem_Info (Resolved_Tree (Left));
      Right_Sem : constant Sem_Ptr :=
        Underlying_Sem_Info (Resolved_Tree (Right));
      use type Ada.Tags.Tag;
      use type Strings.U_String;
   begin
      if Left_Sem = null or else Right_Sem = null then
         --  One or the other is null
         if Left_Sem /= Right_Sem then
            --  Not both null, can't be same
            if Debug_Second_Pass then
               Put_Line
                 (" Null sem info in Equiv_Tree comparing " &
                  Subtree_Image (Left) &
                  " vs. " &
                  Subtree_Image (Right));
               if Left_Sem = null then
                  Put_Line (" Left is null");
               else
                  Put_Line (" Right is null");
               end if;
            end if;
            return False;
         end if;

         if Is_Null (Left) or else Is_Null (Right) then
            --  Check to see if both trees are null
            return Is_Null (Left) and then Is_Null (Right);
         end if;

         --  Both sem-infos are null, but trees are non-null.
         --  Fall through to compare subtree images

      elsif Left_Sem = Right_Sem then
         --  Identical, non-null semantic info
         return True;
      elsif Left_Sem'Tag /= Right_Sem'Tag then
         --  Different kind of thing
         if Debug_Matching then
            Put_Line
              (" Equiv_Tree on different kinds of things: " &
               Subtree_Image (Left) &
               " has sem of type " &
               Ada.Tags.External_Tag (Left_Sem'Tag) &
               "; " &
               Subtree_Image (Right) &
               " has sem of type " &
               Ada.Tags.External_Tag (Right_Sem'Tag));
         end if;
         return False;
      elsif Left_Sem.all in Type_Semantic_Info then
         --  Both are types, compare uniquified equivalents
         if Debug_Matching then
            if Type_Sem_Ptr (Left_Sem).U_Type /=
               Type_Sem_Ptr (Right_Sem).U_Type
            then
               Put_Line
                 (Type_Image (Type_Sem_Ptr (Left_Sem)) &
                  " and " &
                  Type_Image (Type_Sem_Ptr (Right_Sem)) &
                  " have different U_Types: " &
                  Type_Image (Type_Sem_Ptr (Left_Sem).U_Type) &
                  " and " &
                  Type_Image (Type_Sem_Ptr (Right_Sem).U_Type));

            end if;
         end if;
         return Type_Sem_Ptr (Left_Sem).U_Type =
                Type_Sem_Ptr (Right_Sem).U_Type;

      elsif Left_Sem.all in Operand_Semantic_Info'Class
        and then Operand_Sem_Ptr (Left_Sem).Target_Polymorphic_Type /=
                   Operand_Sem_Ptr (Right_Sem).Target_Polymorphic_Type
      then
         --  Target_Polymorphic_Type info doesn't match
         return False;

      elsif Left_Sem.all in Literal_Semantic_Info then
         --  Both are literals, compare the U_Strings (TBD: Look at vals)
         return Literal_Sem_Ptr (Left_Sem).Associated_Symbol.Str =
                Literal_Sem_Ptr (Right_Sem).Associated_Symbol.Str;
      elsif Left_Sem.all in Object_Semantic_Info
        or else Left_Sem.all in Param_Semantic_Info
        or else Left_Sem.all in Operation_Semantic_Info
      then
         --  Both are objects or operations; must be the same or must be
         --  "equivalent" (e.g. spec vs. body).
         return Equiv_Decls (Sem_Ptr (Left_Sem), Sem_Ptr (Right_Sem));
      elsif Left_Sem.all in Operand_Semantic_Info'Class then
         --  Both are operands
         declare
            Left_Type : constant Type_Sem_Ptr :=
              Operand_Sem_Ptr (Left_Sem).Resolved_Type;
            Right_Type : constant Type_Sem_Ptr :=
              Operand_Sem_Ptr (Right_Sem).Resolved_Type;
         begin
            if Left_Type = null or else Right_Type = null then
               if Left_Type /= Right_Type then
                  --  Not both null
                  return False;
               end if;
            elsif Left_Type.U_Type /= Right_Type.U_Type then
               --  Not the same type.
               return False;
            elsif Left_Type.U_Type = null
              and then Left_Type /= Right_Type
            then
               --  Not the same type.
               return False;
            end if;

            --  TBD; Fall through to compare tree images

         end;
      elsif Left_Sem.all in Module_Semantic_Info then
         --  Both are modules, should be same or other part of same.
         return Left_Sem = Right_Sem
               or else Module_Sem_Ptr (Left_Sem).Other_Part =
                       Module_Sem_Ptr (Right_Sem)
               or else Module_Sem_Ptr (Left_Sem) =
                       Module_Sem_Ptr (Right_Sem).Other_Part;
      end if;

      --  Compare operands
      declare
         Left_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                 (Resolved_Tree (Left)).all;
         Right_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                  (Resolved_Tree (Right)).all;
         Num_Opnds : constant Natural := Num_Operands (Left_Tree);
      begin
         if Num_Operands (Right_Tree) /= Num_Opnds then
            --  Different number of operands
            return False;
         end if;

         for I in 1 .. Num_Opnds loop
            if not Equiv_Tree
                     (Nth_Operand (Left_Tree, I),
                      Nth_Operand (Right_Tree, I))
            then
               --  Operand mismatch
               return False;
            end if;
         end loop;

         --  Trees are equivalent
         return True;

      end;

   end Equiv_Tree;

   function Hash_Tree (OT : Optional_Tree) return Hash_Type is
      --  Return hash of tree, with hash being equal for two Equiv trees
      Tree_Sem : constant Sem_Ptr :=
        Underlying_Sem_Info (Resolved_Tree (OT));
      use type Hash_Type;
   begin
      if Tree_Sem = null then
         return 1;  --  Any fixed value
      elsif Tree_Sem.all in Type_Semantic_Info then
         --  Is a type, hash the "U_Type" if filled in
         declare
            Type_Sem : constant Type_Sem_Ptr := Type_Sem_Ptr (Tree_Sem);
         begin
            if Type_Sem.U_Type /= null then
               return Hash_Type (Type_Sem.U_Type.Type_Index);
            else
               return Hash_Type (Type_Sem.Type_Index);
            end if;
         end;
      elsif Tree_Sem.all in Operand_Semantic_Info'Class then
         --  Is an operand, see whether we already computed hash value
         if Operand_Sem_Ptr (Tree_Sem).Hash_Value = 0 then
            --  Not yet computed
            if Tree_Sem.all in Literal_Semantic_Info then
               --  Compute hash value based on literal string
               --  TBD: Base it on value of literal
               Operand_Sem_Ptr (Tree_Sem).Hash_Value :=
                  Strings.Hash
                    (Literal_Sem_Ptr (Tree_Sem).Associated_Symbol.Str);
            else
               --  Compute hash value based on subtree image
               Operand_Sem_Ptr (Tree_Sem).Hash_Value :=
                  Strings.Hash
                    (Strings.String_Lookup
                        (Subtree_Image (Tree_Sem.Definition)));
            end if;
         end if;
         return Operand_Sem_Ptr (Tree_Sem).Hash_Value;
      elsif Tree_Sem.all in Operation_Semantic_Info then
         --  Is an operation; hash the parameter types
         --  TBD: We should probably have a unique "signature" index
         --       which is essentially equivalent to the func-type unique index
         declare
            Op_Sem : constant Operation_Sem_Ptr :=
              Operation_Sem_Ptr (Tree_Sem);
            Op_Tree : Operation.Tree renames
              Operation.Tree (Tree_Ptr_Of (Op_Sem.Definition).all);
            Result : Hash_Type := 1;
            procedure Hash_Param_List (Param_List : Lists.List) is
               --  Hash operation input or output list
            begin
               for I in 1 .. Lists.Length (Param_List) loop
                  declare
                     Elem_Sem : Root_Sem_Ptr :=
                       Sem_Info (Lists.Nth_Element (Param_List, I));
                  begin
                     if Elem_Sem /= null
                       and then Elem_Sem.all in Param_Semantic_Info
                     then
                        declare
                           Param_Sem : constant Param_Sem_Ptr :=
                             Param_Sem_Ptr (Elem_Sem);
                        begin
                           if Param_Sem.Resolved_Type /= null
                             and then Param_Sem.Resolved_Type.U_Type /= null
                           then
                              Result := Result * 61 + Hash_Type
                                (Param_Sem.Resolved_Type.U_Type.Type_Index);
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end Hash_Param_List;
         begin
            Hash_Param_List (Op_Tree.Operation_Inputs);
            Hash_Param_List (Op_Tree.Operation_Outputs);
            return Result;
         end;
      elsif Tree_Sem.all in Module_Semantic_Info then
         --  Is a module, hash on name
         return Strings.Hash
                  (Module_Sem_Ptr (Tree_Sem).Associated_Symbol.Str);
      end if;

      --  Return 1 as a fall back
      return 1;
   end Hash_Tree;

   function Equiv_Interps (Interp1, Interp2 : Optional_Tree) return Boolean is
      --  Return True if Interp1 and Interp2 are equivalent as far
      --  as overload resolution.
      Sem1 : constant Sem_Ptr := Underlying_Sem_Info (Interp1);
      Sem2 : constant Sem_Ptr := Underlying_Sem_Info (Interp2);
   begin
      if Sem1 = Sem2 and then Sem1 /= null then
         if Debug_Matching then
            Put_Line
              (" Equiv_Interps returned True for " &
               Subtree_Image (Interp1) &
               " vs. " &
               Subtree_Image (Interp2));
         end if;
         return True;
      else
         return False;
      end if;
   end Equiv_Interps;

   procedure Set_Literal_Sem_Info
     (T : in out Identifier.Tree;
      Lit_Kind : Literal_Kind_Enum;
      Target_Type : Type_Sem_Ptr := null) is
      --  Fill in sem info for a literal of given kind

      Lit_Sem : constant Literal_Sem_Ptr :=
        new Literal_Semantic_Info'(Operand_Semantic_Info with Lit_Kind);
      Lit_Sym : constant Symbols.Sym_Ptr :=
        new Symbols.Symbol'
        (Kind => Literal_Sym_Kind,
         Str => T.Str,
         Full_Name => Strings.Null_U_String,
         Source_Pos => Identifier.Find_Source_Pos (T),
         Enclosing_Region => null,
         Nested_Region => null,
         Sem_Info => Root_Sem_Ptr (Lit_Sem),
         Definition => Optional (T'Access),
         Completion_Of => null,
         Index => No_Sym_Index,
         Next_Homonym => No_Sym_Index,
         Import_Clauses => Lists.Empty_List);
      Interp_Added : Boolean;
   begin
      --  Fill in semantic information
      Lit_Sem.Definition := Lit_Sym.Definition;
      Lit_Sem.Associated_Symbol := Lit_Sym;
      Set_Sem_Info (Lit_Sym.Definition, Lit_Sym.Sem_Info);

      if Target_Type /= null
        and then
          (Lit_Kind = Null_Literal or else Target_Type.Is_Universal)
      then
         --  A "null" with a specified target type,
         --  or a specified target type that is itself universal.
         Lit_Sem.Resolved_Type := Target_Type.U_Base_Type;

         --  Create initial interpretation tree with appropriate region
         Interpretations.Add_Interp
           (Lit_Sem.Interps,
            Associated_Type_Region => U_Base_Type_Region (Target_Type),
            Interp => Lit_Sem.Definition,
            Interp_Added => Interp_Added);

         if Lit_Kind /= Null_Literal
           and then Lit_Sem.Resolved_Type /= Univ_Types (Lit_Kind)
         then
            --  No inter-conversion between universal types
            Sem_Error (T, "Cannot be interpreted as a literal of type " &
              Type_Image (Target_Type));
         end if;
      else
         --  A non-null literal; initially mark as the corresponding univ type
         Lit_Sem.Resolved_Type := Univ_Types (Lit_Kind);

         if Lit_Sem.Resolved_Type /= null
           and then
             Lit_Sem.Resolved_Type.U_Base_Type /= Lit_Sem.Resolved_Type
         then
            if Debug_Second_Pass then
               Put_Line (" Univ_Type (" & Literal_Kind_Enum'Image (Lit_Kind) &
                 ") does not equal its base type -- fixing that!");
            end if;
            Lit_Sem.Resolved_Type := Lit_Sem.Resolved_Type.U_Base_Type;
            Univ_Types (Lit_Kind) := Lit_Sem.Resolved_Type;
         end if;

         --  Create initial interpretation tree with null region
         Interpretations.Add_Interp
           (Lit_Sem.Interps,
            Associated_Type_Region => null,
            Interp => Lit_Sem.Definition,
            Interp_Added => Interp_Added);

         --  Now handle prefix for non-null literals
         if Target_Type /= null then
            --  Insert a call on appropriate "from_univ" operator
            declare
               Copy_Of_Lit : constant Optional_Tree :=
                 Copy_Resolved_Tree (Lit_Sem.Definition);
               From_Univ_Call : constant Optional_Tree :=
                 Create_From_Univ_Call
                   (Copy_Of_Lit, Target_Type.U_Base_Type);
            begin
               if Is_Null (From_Univ_Call) then
                  Sem_Error (T, "Cannot be interpreted as a literal of type " &
                    Type_Image (Target_Type));
               else
                  --  Set the new target type
                  Lit_Sem.Resolved_Type := Target_Type.U_Base_Type;

                  --  Copy the interpretation tree from univ-call
                  Lit_Sem.Interps :=
                    Operand_Sem_Ptr (Sem_Info (From_Univ_Call)).Interps;
               end if;
            end;
         end if;
      end if;
   end Set_Literal_Sem_Info;

   function Is_Invocation (Expr : Optional_Tree) return Boolean is
      --  Return True if Expr can be interpreted as an invocation,
      --  and has a Call_Semantic_Info for its Sem info
      --  This includes unary and binary operators, operation calls,
      --  univ literals to be converted via "From_Univ", etc.
      --  TBD: We don't worry about literals for now; may be handled
      --      in some alternative way
      Expr_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Expr).all;
      Expr_Sem : constant Root_Sem_Ptr := Sem_Info (Expr);
   begin
      return Expr_Sem /= null
            and then Expr_Sem.all in Call_Semantic_Info'Class
            and then (Expr_Tree in Invocation.Tree
                     or else Expr_Tree in Binary.Tree
                     or else Expr_Tree in Unary.Tree);
   end Is_Invocation;

   function Name_Of_Operation (Expr : Optional_Tree) return String is
      --  Return name of operation in an invocation.
      --  Return "operation" if cannot determine name.
      Expr_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Expr).all;
      Expr_Sem : constant Root_Sem_Ptr := Sem_Info (Expr);
   begin
      if Expr_Tree in Invocation.Tree then
         declare
            Invoc_Tree : Invocation.Tree renames Invocation.Tree (Expr_Tree);
            use Invocation;
         begin
            case Invoc_Tree.Kind is
               when Operation_Call =>
                  return Subtree_Image (Invoc_Tree.Prefix);
               when Container_Indexing =>
                  return "op ""indexing""";
               when Class_Aggregate =>
                  if Is_Parenthesized_Expression (Invoc_Tree) then
                     return Name_Of_Operation
                              (Invocation.Remove_Parentheses (Expr));
                  else
                     return "class aggregate";
                  end if;
               when Container_Aggregate =>
                  if Lists.Is_Empty (Invoc_Tree.Operands) then
                     return "op ""[]""";
                  elsif Lists.Length (Invoc_Tree.Operands) = 1
                    and then Is_Default_Indicator
                                (Lists.Nth_Element (Invoc_Tree.Operands, 1))
                  then
                     return "op ""[..]""";
                  else
                     return "container aggregate";
                  end if;
               when Map_Set_Aggregate =>
                  if Lists.Is_Empty (Invoc_Tree.Operands) then
                     return "op ""{}""";
                  elsif Lists.Length (Invoc_Tree.Operands) = 1
                    and then Is_Default_Indicator
                                (Lists.Nth_Element (Invoc_Tree.Operands, 1))
                  then
                     return "op ""{..}""";
                  else
                     return "map/set aggregate";
                  end if;
               when Module_Instantiation =>
                  return "operation";  --  Should this happen?
               when Is_Function_Of =>
                  return "X is func (...)";
               when Tuple_Type_Definition =>
                  return "tuple type";
            end case;
         end;
      elsif Expr_Tree in Binary.Tree then
         return "op " &
                Strings.To_String
                   (Binary.Binary_Operator_Designator
                       (Binary.Tree (Expr_Tree).Operator));
      elsif Expr_Tree in Unary.Tree then
         return "op " &
                Strings.To_String
                   (Unary.Unary_Operator_Designator
                       (Unary.Tree (Expr_Tree).Operator));
      else
         return "operation";
      end if;
   end Name_Of_Operation;

   procedure Add_Operation_Interps
     (Interps : in out Interpretations.Interp_Tree;
      Type_Region : Interpretations.Type_Region_Ptr;
      Operation_Name : Strings.U_String;
      Source_Pos : Source_Positions.Source_Position :=
        Source_Positions.Null_Source_Position;
      Operation_Filter : Operand_Info := Any_Operation;
      Implementing_Module : Module_Sem_Ptr := null;
      Add_Call_Interps_To : Optional_Tree := Null_Optional_Tree);
   --  Add operation interpretations to Interps tree
   --  by looking up declarations of Operation_Name in specified region.
   --  If Operation_Filter is not Any_Operation, then include only
   --  operations with the specified operand being of the "current instance"
   --  type.
   --  If Implementing_Module is non-null, then include
   --  operations that are available for implementing
   --  the interface of the given module.
   --  If Add_Call_Interps_To is non-null, then
   --  for each operation interpretation added, also add corresponding Call
   --  interpretations to Add_Call_Interps_To

   function Operation_Filter_Matches
     (Operation_Filter : Operand_Info;
      Op_Tree : Operation.Tree;
      Cur_Inst_Type : Type_Sem_Ptr)
      return Boolean
   is
      --  Return True if operation with given Op_Tree satisfies
      --  the given Operation_Filter for the given cur-inst type.
      --  NOTE: For a "new" type, Cur_Inst_Type is the new (base) type, not
      --        a "current instance" type.

      function Check_Param_Type (Param : Param_Decl.Tree) return Boolean is
      --  Check Cur_Inst_Type against given Param
         Resolved_Param_Type : constant Type_Sem_Ptr :=
           Resolved_Type (Param.Param_Type);
      begin
         if Resolved_Param_Type.Is_Polymorphic then
            --  Include operation if parameter type is polymorphic
            --  and current inst type implements that type,
            --  implicitly or explicitly.
            return Type_Implements_Type
              (Actual_Type => Cur_Inst_Type,
               Formal_Type => Resolved_Param_Type,
               Check_Parameterless_Modules => True);
         else
            return Types_Match (Resolved_Param_Type, Cur_Inst_Type);
         end if;
      end Check_Param_Type;

      function Check_List (Operand_List : Lists.List) return Boolean is
      --  Check Operation_Filter against given list
      begin
         if Operation_Filter.Position > 0 then
            if Lists.Length (Operand_List) < Operation_Filter.Position then
               --  Not enough operands
               return False;
            else
               declare
                  Operand_Tree : Trees.Tree'Class
                    renames Tree_Ptr_Of (Lists.Nth_Element
                      (Operand_List, Operation_Filter.Position)).all;
               begin
                  if Operand_Tree not in Param_Decl.Tree then
                     --  Not an object parameter
                     --  TBD: Handle operation params someday
                     return False;
                  else
                     --  Check for type match
                     return Check_Param_Type (Param_Decl.Tree (Operand_Tree));
                  end if;
               end;
            end if;
         else
            --  Find given named operand
            for I in 1 .. Lists.Length (Operand_List) loop
               declare
                  Operand_Tree : Trees.Tree'Class renames
                    Tree_Ptr_Of (Lists.Nth_Element (Operand_List, I)).all;
               begin
                  if Operand_Tree in Param_Decl.Tree then
                     declare
                        Operand_Decl_Tree : Param_Decl.Tree renames
                          Param_Decl.Tree (Operand_Tree);
                     begin
                        if Not_Null (Operand_Decl_Tree.Name)
                          and then Tree_Ptr_Of (Operand_Decl_Tree.Name).all in
                             Identifier.Tree
                        then
                           --  See whether the name matches
                           if Operation_Filter.Name =
                              Identifier.Tree (Tree_Ptr_Of
                                (Operand_Decl_Tree.Name).all).Str
                           then
                              return Check_Param_Type (Operand_Decl_Tree);
                           end if;
                        end if;
                     end;
                  end if;
               end;
            end loop;
            --  Doesn't match any named parameter
            return False;
         end if;
      end Check_List;

   begin  --  Operation_Filter_Matches

      if Operation_Filter = Any_Operation then
         return True;
      elsif Operation_Filter.Is_Output_Operand then
         --  Check the corresponding output operand
         return Check_List (Op_Tree.Operation_Outputs);
      else
         --  Check the corresponding input operand
         return Check_List (Op_Tree.Operation_Inputs);
      end if;
   end Operation_Filter_Matches;

   function Return_True
     (Operand_Type : Type_Sem_Ptr;
      Input_Types : Type_Sem_Array;
      Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Default for Has_Desired_Signature function
   begin
      return True;
   end Return_True;

   function Find_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Op_Name : Strings.U_String := Default_Op_Name)
      return Operation_Sem_Ptr
   is
      --  Return Operation_Sem_Ptr for operation of given Op_Name
      --  for the given type, with the given number of
      --  inputs and outputs, and for which Has_Desired_Signature
      --  returns True.  Return null if none found.

      Result_Op_Sem : Operation_Sem_Ptr := null;
      Op_Interps : Interpretations.Interp_Tree := null;

      procedure Select_Desired_Op
        (Associated_Type_Region : Type_Region_Ptr;
         Interp : Trees.Optional_Tree) is
         --  Find op with proper signature
         Op_Sem : constant Operation_Sem_Ptr :=
           Operation_Sem_Ptr (Underlying_Op_Sem_Info (Interp));
         Op_Tree : Operation.Tree renames Operation.Tree (Tree_Ptr_Of
                                                             (Op_Sem.
           Definition).all);
      begin
         if Lists.Length (Op_Tree.Operation_Inputs) = Num_Inputs
           and then Lists.Length (Op_Tree.Operation_Outputs) = Num_Outputs
         then
            --  Right number of inputs and outputs.
            --  Call "Has_Desired_Signature" func to determine
            --  whether this is the one we want.
            declare
               Input_Types : Type_Sem_Array (1 .. Num_Inputs);
               Output_Types : Type_Sem_Array (1 .. Num_Outputs);
            begin
               for I in Input_Types'Range loop
                  declare
                     Param_Sem : constant Object_Sem_Ptr :=
                       Object_Sem_Ptr (Underlying_Sem_Info
                                          (Lists.Nth_Element
                                              (Op_Tree.Operation_Inputs,
                                               I)));
                  begin
                     if Param_Sem = null then
                        return;  --  Can't be the one we want
                     else
                        Input_Types (I) :=
                           Substitute_Actuals
                             (Param_Sem.Resolved_Type,
                              U_Base_Type_Region (Operand_Type));
                     end if;
                  end;
               end loop;

               for I in Output_Types'Range loop
                  declare
                     Param_Sem : constant Object_Sem_Ptr :=
                       Object_Sem_Ptr (Underlying_Sem_Info
                                          (Lists.Nth_Element
                                              (Op_Tree.Operation_Outputs,
                                               I)));
                  begin
                     if Param_Sem = null then
                        return;  --  Can't be the one we want
                     else
                        Output_Types (I) :=
                           Substitute_Actuals
                             (Param_Sem.Resolved_Type,
                              U_Base_Type_Region (Operand_Type));
                     end if;
                  end;
               end loop;

               if Has_Desired_Signature
                    (Operand_Type,
                     Input_Types => Input_Types,
                     Output_Types => Output_Types)
               then
                  if Result_Op_Sem /= null then
                     Sem_Error
                       (Operand_Type.Definition,
                        "Operation " &
                        Strings.To_String (Op_Name) &
                        " is ambiguous");
                  else
                     Result_Op_Sem := Op_Sem;
                  end if;
               end if;
            end;
         end if;
      end Select_Desired_Op;

      procedure Scan_Ops is new Interpretations.Iterate_Interps (
         Select_Desired_Op);

   begin   --  Find_Op_For

      --  Look up Op_Name in region associated with Operand_Type

      if Operand_Type = null
        or else Operand_Type.Associated_Module = null
      then
         --  Some prior error
         return null;
      end if;

      Add_Operation_Interps
        (Interps => Op_Interps,
         Type_Region => U_Base_Type_Region (Operand_Type),
         Operation_Name => Op_Name);

      --  Look for op of Operand_Type with given name and
      --  appropriate inputs and outputs.
      Scan_Ops (Op_Interps);

      return Result_Op_Sem;
   end Find_Op_For;

   function First_Input_Is_Operand_Type
     (Operand_Type : Type_Sem_Ptr;
      Input_Types : Type_Sem_Array;
      Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Binding for Has_Desired_Signature function
   --  which returns True if first input is of Operand type
   begin
      return Input_Types (1).Associated_Module =
             Operand_Type.Associated_Module;
   end First_Input_Is_Operand_Type;

   function First_Output_Is_Operand_Type
     (Operand_Type : Type_Sem_Ptr;
      Input_Types : Type_Sem_Array;
      Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Binding for Has_Desired_Signature function
   --  which returns True if first output is of Operand type
   begin
      return Output_Types (1).Associated_Module =
             Operand_Type.Associated_Module;
   end First_Output_Is_Operand_Type;

   function First_Input_Is_Operand_Type_And_Second_Is_Not
     (Operand_Type : Type_Sem_Ptr;
      Input_Types : Type_Sem_Array;
      Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Binding for Has_Desired_Signature function
   --  which returns True if first input is of Operand type
   begin
      return Input_Types (1).Associated_Module =
             Operand_Type.Associated_Module
            and then Input_Types (2).Associated_Module /=
                     Operand_Type.Associated_Module;
   end First_Input_Is_Operand_Type_And_Second_Is_Not;

   function Is_Compare_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Input_Types, Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Return True if given operation takes two inputs of Operand_Type
   --  and returns one output of Ordering type.
   begin
      return Input_Types (1).Associated_Module =
             Operand_Type.Associated_Module
            and then Input_Types (2).Associated_Module =
                     Operand_Type.Associated_Module
            and then Types_Match (Output_Types (1), Ordering_Type);
   end Is_Compare_Op_For;

   function Find_Compare_Op_For is new Find_Op_For (
      Compare_Op_Str,
      Num_Inputs => 2,
      Num_Outputs => 1,
      Has_Desired_Signature => Is_Compare_Op_For);
   --  Return Operation_Sem_Ptr for compare operation "=?" from
   --  the given type.  If none, return null.

   function Get_To_Univ_Op (From : Type_Sem_Ptr; To : Type_Sem_Ptr)
     return Operation_Sem_Ptr
   --  Return Operation_Sem_Ptr for to-univ operation from
   --  the given non-universal From type to the given univ To type
   --  Return null if no such operation exists in module defining "From" type.
   is
      function First_Input_Is_Operand_Type_And_Result_Is_Univ_Type
        (Operand_Type : Type_Sem_Ptr;
         Input_Types : Type_Sem_Array;
         Output_Types : Type_Sem_Array)
         return Boolean
      is
      --  Binding for Has_Desired_Signature function
      --  which returns True if first input is of Operand type
      --  and result is univ "To" type
      begin
         return Input_Types (1).Associated_Module =
                Operand_Type.Associated_Module
            and then
                Output_Types (1).Associated_Module =
                To.Associated_Module;
      end First_Input_Is_Operand_Type_And_Result_Is_Univ_Type;

      function Find_To_Univ_Op_For is new Find_Op_For (
        To_Univ_Str,
        Num_Inputs => 1,
        Num_Outputs => 1,
        Has_Desired_Signature =>
          First_Input_Is_Operand_Type_And_Result_Is_Univ_Type);

   begin  --  Get_To_Univ_Op

      return Find_To_Univ_Op_For (From);
   end Get_To_Univ_Op;

   function Get_From_Univ_Op (From : Type_Sem_Ptr; To : Type_Sem_Ptr)
     return Operation_Sem_Ptr
   --  Return Operation_Sem_Ptr for to-univ operation from
   --  the given univ From type to the given non-univ To type.
   --  Return null if no such operation exists in module defining "To" type
   is

      function First_Input_Is_Univ_And_Result_Is_Operand
        (Operand_Type : Type_Sem_Ptr;
         Input_Types : Type_Sem_Array;
         Output_Types : Type_Sem_Array)
         return Boolean
      is
      --  Binding for Has_Desired_Signature function
      --  which returns True if first input is of univ "From" type
      --  and result is of Operand_Type
      begin
         return Output_Types (1).Associated_Module =
                Operand_Type.Associated_Module
            and then
                Input_Types (1).Associated_Module =
                From.Associated_Module;
      end First_Input_Is_Univ_And_Result_Is_Operand;

      function Find_From_Univ_Op_For is new Find_Op_For (
        From_Univ_Str,
        Num_Inputs => 1,
        Num_Outputs => 1,
        Has_Desired_Signature =>
          First_Input_Is_Univ_And_Result_Is_Operand);

   begin  --  Get_From_Univ_Op

      return Find_From_Univ_Op_For (To);

   end Get_From_Univ_Op;

   function Implicitly_Converts (From, To : Type_Sem_Ptr) return Boolean is
   --  Return True if "From" can be implicitly converted to "To"
   --  using "from_univ" or "to_univ"
   begin
      if Types_Match (From, To) then
         return True;
      elsif From.Is_Universal then
         if not To.Is_Universal then
            --  Convert from universal to non-universal
            return To.U_Base_Structure = From.U_Base_Structure
              or else Get_From_Univ_Op (From => From, To => To) /= null;
         else
            --  Both are universal, so not convertible
            return False;
         end if;
      elsif To.Is_Universal then
         --  Convert from non-universal to universal
         return From.U_Base_Structure = To.U_Base_Structure
           or else Get_To_Univ_Op (From => From, To => To) /= null;
      else
         --  Neither is universal, so not implicitly convertible
         return False;
      end if;
   end Implicitly_Converts;

   function Is_Inc_Dec_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Input_Types, Output_Types : Type_Sem_Array)
      return Boolean
   is
   --  Return True if given operation takes one input of Operand_Type
   --  and one input of Univ_Integer type
   --  and returns one output of Operand type.
   --  This is presumably used for incrementing/decrementing a value
   --  so as to iterate through an interval.
   begin
      return Input_Types (1).Associated_Module =
             Operand_Type.Associated_Module
            and then Types_Match (Input_Types (2), Univ_Integer_Type)
            and then Output_Types (1).Associated_Module =
                     Operand_Type.Associated_Module;
   end Is_Inc_Dec_Op_For;

   function Is_Countable_Type (Operand_Type : Type_Sem_Ptr) return Boolean is
      --  Return True if Operand_Type has a "+"/"-" operator with
      --  Univ_Int used for advancing through an interval.

      function Find_Inc_Op_For is new Find_Op_For (
         Plus_Op_Str,
         Num_Inputs => 2,
         Num_Outputs => 1,
         Has_Desired_Signature => Is_Inc_Dec_Op_For);

      function Find_Dec_Op_For
        (Operand_Type : Type_Sem_Ptr;
         Op_Name : Strings.U_String := Minus_Op_Str)
         return Operation_Sem_Ptr renames Find_Inc_Op_For;
      --  Different op name, everything else the same

      Inc_Op : constant Operation_Sem_Ptr := Find_Inc_Op_For (Operand_Type);
      Dec_Op : constant Operation_Sem_Ptr := Find_Dec_Op_For (Operand_Type);
      Is_Countable : constant Boolean :=
        Inc_Op /= null and then Dec_Op /= null;
   --  Is considered "Countable" if has T +/- Univ -> T
   begin
      if Debug_Second_Pass then
         if Is_Countable then
            Put_Line (" " & Type_Image (Operand_Type) & " is countable");
         else
            Put_Line (" " & Type_Image (Operand_Type) & " is not countable");
            if Inc_Op = null then
               Put_Line ("  Inc_Op not found.");
            end if;
            if Dec_Op = null then
               Put_Line ("  Dec_Op not found.");
            end if;
         end if;
      end if;
      return Is_Countable;
   end Is_Countable_Type;

   function Find_Indexing_Op_Inst is new Find_Op_For (
      Indexing_Op_Str,
      Num_Inputs => 2,
      Num_Outputs => 1,
      Has_Desired_Signature => First_Input_Is_Operand_Type);
   --  Return Operation_Sem_Ptr for "indexing" for
   --  the given container type.  If none, return null.
   --  TBD: What to do if there is more than one?

   function Find_Indexing_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Op_Name : Strings.U_String := Indexing_Op_Str)
      return Operation_Sem_Ptr renames Find_Indexing_Op_Inst;
   --  Return Operation_Sem_Ptr for "indexing" for
   --  the given container type.  If none, return null.
   --  TBD: What to do if there is more than one?

   function Find_Var_Indexing_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Op_Name : Strings.U_String := Var_Indexing_Op_Str)
      return Operation_Sem_Ptr renames Find_Indexing_Op_For;
   --  Same as Find_Indexing_Op_For, but with different
   --  name.

   function Find_One_In_One_Out_Op_Inst is new Find_Op_For (
      Default_Op_Name => Strings.Null_U_String,
      Num_Inputs => 1,
      Num_Outputs => 1,
      Has_Desired_Signature => First_Input_Is_Operand_Type);

   function Find_One_In_One_Out_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Op_Name : Strings.U_String := Strings.Null_U_String)
      return Operation_Sem_Ptr renames Find_One_In_One_Out_Op_Inst;
   --  Find operation with one input of given type, and one output

   function Get_Remove_Func
     (Set_Type : Type_Sem_Ptr;
      Iterator_Dir : Interpreter.Direction := Interpreter.Unordered_Dir)
      return Operation_Sem_Ptr
   is
   --  Return appropriate Remove_* func to use for
   --  given iterator direction.
   --  Return null if no func found.
   begin
      return Find_One_In_One_Out_Op_For
               (Set_Type,
                Op_Name => Remove_Func_Strs (Iterator_Dir));
   end Get_Remove_Func;

   function Get_Func_Output_Type
     (Op_Sem : Operation_Sem_Ptr;
      Type_Region : Type_Region_Ptr) return Type_Sem_Ptr is
   --  Return output type given Op_Sem for function.
   --  Return null if Op_Sem is null.
   begin
      if Op_Sem /= null then
         --  Get the output type
         return Substitute_Actuals
                  (Resolved_Type
                      (Lists.Nth_Element
                          (Operation.Tree (Tree_Ptr_Of
                             (Op_Sem.Definition).all).Operation_Outputs,
                           1)),
                   Type_Region);
      else
         return null;
      end if;
   end Get_Func_Output_Type;

   function Get_Remove_Func_Output_Type
     (Set_Type : Type_Sem_Ptr;
      Iterator_Dir : Interpreter.Direction := Interpreter.Unordered_Dir)
      return Type_Sem_Ptr
   is
      --  Return output type of specified Remove_* func
      --  Return null if corresponding Remove_* func not found.
      Remove_Func : constant Operation_Sem_Ptr :=
        Get_Remove_Func (Set_Type, Iterator_Dir);
   begin
      return Get_Func_Output_Type (Remove_Func, U_Base_Type_Region (Set_Type));
   end Get_Remove_Func_Output_Type;

   function Get_Ref_Func_Output_Type
     (Ref_Obj_Type : Type_Sem_Ptr)
     return Type_Sem_Ptr
   is
      --  Return output type of "ref" operation on given ref-obj type
      --  Return null if no "ref" operation found

      Ref_Op : constant Operation_Sem_Ptr :=
        Find_One_In_One_Out_Op_For (Ref_Obj_Type,
          Op_Name => Ref_Op_Str);
   begin
      if Ref_Op /= null then
         --  Get result type
         return Get_Func_Output_Type
           (Ref_Op, U_Base_Type_Region (Ref_Obj_Type));
      else
         return null;
      end if;
   end Get_Ref_Func_Output_Type;

   function Find_Combine_Move_Op_Inst is new Find_Op_For (
      Combine_Move_Op_Str,
      Num_Inputs => 2,
      Num_Outputs => 0,
      Has_Desired_Signature => First_Input_Is_Operand_Type_And_Second_Is_Not);
   --  Find "<|=" operation for elements, not whole containers

   function Find_Combine_Move_Op_For
     (Operand_Type : Type_Sem_Ptr;
      Op_Name : Strings.U_String := Combine_Move_Op_Str)
      return Operation_Sem_Ptr renames Find_Combine_Move_Op_Inst;
   --  Find "<|=" operation for elements, not whole containers

   procedure Set_Type_Sem_Info
     (T : in out Invocation.Tree;
      Module_Sem : Module_Sem_Ptr;
      Decl_Region : Symbols.Region_Ptr;
      Is_Formal_Type : Boolean;
      Enclosing_Type : Type_Sem_Ptr;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      Associated_Generic_Op : Sym_Ptr := null;
      Actual_Sem_Infos : Sem_Info_Array_Ptr := null;
      Use_Primary_Nested_Type : Boolean := False);
   --  Fill in sem info for type defined by module instantiation
   --  If Use_Primary_Nested_Type is True then this will return
   --  the Primary_Nested_Type of the Module_Sem if it has one.

   function Instantiate_Module
     (Mod_Sem : Module_Sem_Ptr;
      Actual_Params : Sem_Info_Array;
      Decl_Region : Symbols.Region_Ptr := null;
      Enclosing_Type : Type_Sem_Ptr := null;
      Is_Formal_Type : Boolean := False;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      Associated_Generic_Op : Symbols.Sym_Ptr := null;
      Source_Pos : Source_Positions.Source_Position :=
        Source_Positions.Null_Source_Position)
      return Type_Sem_Ptr
   is
      --  Instantiate module with given actual parameters
      Instantiation_Operands : Lists.List;
      New_Instantiation : Optional_Tree;
      Result_Type : Type_Sem_Ptr := null;
   begin
      if not Some_Nulls (Actual_Params) then
         --  Create list of operands corresponding to sem-infos
         --  unless there are nulls in the sem-infos.
         --  TBD: Perhaps should bypass this if all of the actual params
         --       are merely actuals-of-formals.
         for I in Actual_Params'Range loop
            Lists.Append
              (Instantiation_Operands, Actual_Params (I).Definition);
         end loop;
      end if;

      New_Instantiation :=
         Invocation.Make
           (Invocation.Module_Instantiation,
            Invocation.Tree (Tree_Ptr_Of
              (Mod_Sem.Cur_Inst_Sem.Definition).all).Prefix,
            Instantiation_Operands,
            Source_Pos => Source_Pos);

      Set_Type_Sem_Info
        (T => Invocation.Tree (Tree_Ptr_Of (New_Instantiation).all),
         Module_Sem => Mod_Sem,
         Decl_Region => Decl_Region,
         Is_Formal_Type => Is_Formal_Type,
         Enclosing_Type => Enclosing_Type,
         Formal_Prefix => Formal_Prefix,
         Associated_Generic_Op => Associated_Generic_Op,
         Actual_Sem_Infos => new Sem_Info_Array'(Actual_Params));

      Result_Type := Type_Sem_Ptr (Sem_Info (New_Instantiation));

      if Debug_Second_Pass then
         Put_Line
           (" Instantiate_Module produces " & Type_Image (Result_Type));
      end if;
      return Result_Type;
   end Instantiate_Module;

   procedure Create_Call_Interps
     (Call_Ot : Optional_Tree;
      Only_For_Operation_Interp : Optional_Tree := Null_Optional_Tree;
      Operation_Type_Region : Type_Region_Ptr := null;
      Diagnose : Boolean := False);
   --  Create interps for Call, presuming have already created
   --  interps for prefix of Call.
   --  If Only_For_Operation_Interp is non-null, then only create call
   --  interps for given operation; Operation_Type_Region must be provided.
   --  If Diagnose is True, then produce messages indicating why a call
   --  does *not* match a possible operation.

   procedure Add_Operation_Interps
     (Interps : in out Interpretations.Interp_Tree;
      Type_Region : Interpretations.Type_Region_Ptr;
      Operation_Name : Strings.U_String;
      Source_Pos : Source_Positions.Source_Position :=
        Source_Positions.Null_Source_Position;
      Operation_Filter : Operand_Info := Any_Operation;
      Implementing_Module : Module_Sem_Ptr := null;
      Add_Call_Interps_To : Optional_Tree := Null_Optional_Tree) is
      --  Add operation interpretations to Interps tree
      --  by looking up declarations of Operation_Name in specified region.
      --  If Operation_Filter is not Any_Operation, then include only
      --  operations with the specified operand being of the "current instance"
      --  type.
      --  If Implementing_Module is non-null, then include
      --  operations that are available for implementing
      --  the interface of the given module.
      --  If Add_Call_Interps_To is non-null, then
      --  for each operation interpretation added, also add corresponding Call
      --  interpretations to Add_Call_Interps_To

      procedure Add_Operations_From_Region
        (Originating_Region : Region_Ptr;
         Operation_Param_Type : Type_Sem_Ptr) is
      --  Add operations that satisfy the Operation_Filter
      --  that have the specified Operation_Param_Type as a parameter/result.
         Id_Sym : Sym_Ptr :=
           Symbols.Lookup_In_Region (Originating_Region, Operation_Name);
      begin

         if Debug_Second_Pass then
            Put (" Looking for declarations of " &
              Strings.To_String (Operation_Name) &
              " for type " &
              Type_Image (Operation_Param_Type) &
              " in region of Kind " &
              Symbols.Region_Kind_Enum'Image (Originating_Region.Kind) &
              " associated with " &
              Sym_Name (Originating_Region.Associated_Symbol));
            if Originating_Region.Associated_Symbol /= null
              and then Originating_Region.Associated_Symbol.Sem_Info /= null
              and then Originating_Region.Associated_Symbol.Sem_Info.all in
                Module_Semantic_Info
            then
               Put_Line (Treat_As_Type_Indicator (Module_Sem_Ptr
                 (Originating_Region.Associated_Symbol.Sem_Info)));
            else
               New_Line;
            end if;
         end if;

         --  Add in all visible Operation_Sym_Kind interpretations
         while Id_Sym /= null loop
            declare
               Id_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                     (Id_Sym.Definition).all;
               Use_Interp : Boolean := False;
               Next_Homonym : constant Sym_Ptr :=
                 Next_Homonym_In_Region (Id_Sym);
            --  Check now whether there is another homonym
            begin
               if Id_Sym.Kind = Operation_Sym_Kind
                 and then Id_Tree in Operation.Tree'Class
               then
                  declare
                     Op_Tree : Operation.Tree renames Operation.Tree (Id_Tree);
                     Op_Sem : constant Operation_Sem_Ptr :=
                       Operation_Sem_Ptr (Op_Tree.Sem_Info);
                     Is_Vis_Op : Boolean := True;
                  begin
                     if Op_Sem = null
                       or else Op_Sem.Overridden_By /= null
                       or else Op_Sem.Context not in
                         Any_Interface_Item_Contexts
                       or else (Implementing_Module = null
                               and then Op_Sem.Context not in
                          Visible_Interface_Item_Contexts)
                     then
                        --  Not a visible declaration from an interface
                        --  NOTE: Although ops in the "implements" section
                        --       are in some sense visible, they can only
                        --       be referenced indirectly through some other
                        --       module's interface for which they are in the
                        --       "main" section of the interface.
                        --       Here we allow them only if Implementing
                        --       another module.
                        --  TBD:  Require that Implementing_Module
                        --       be among those in "For_Interfaces" list.
                        Is_Vis_Op := False;
                     elsif Operation_Filter = Any_Operation then
                        --  Use all interps that are operation definitions
                        Use_Interp := True;
                     elsif Operation_Filter_Matches
                              (Operation_Filter,
                               Op_Tree,
                               Operation_Param_Type)
                     then
                        --  It satisfies the filter
                        Use_Interp := True;
                     end if;  --  Whether has only one output

                     if not Use_Interp then
                        if Debug_Second_Pass and then Is_Vis_Op then
                           if Operation_Filter /= Any_Operation then
                              Put_Line
                                (" NOT using operation " &
                                 Subtree_Image (Id_Tree,
                                   Use_Short_Form => True) &
                                 " for type " &
                                 Type_Image (Operation_Param_Type) &
                                 " with filter " &
                                 Operand_Info_Image (Operation_Filter));
                           else
                              Put_Line
                                (" NOT using operation " &
                                 Subtree_Image (Id_Tree,
                                   Use_Short_Form => True) &
                                 " from region of type " &
                                 Type_Image (Operation_Param_Type));
                           end if;
                        end if;
                     else
                        --  Create new interpretation to represent possible
                        --  overloaded operation interpretation
                        declare
                           Id_Interp : constant Optional_Tree :=
                             Identifier.Make
                                (Id_Sym.Str,
                                 Source_Pos => Source_Pos);
                           Interp_Added : Boolean := False;
                        begin
                           if Type_Region = null
                             and then Op_Sem.Originating_Module /= null
                           then
                              Sem_Error (Id_Interp, "Internal: " &
                                "Null Type_Region in " &
                                "Add_Operations_From_Region");
                           end if;

                           Set_Sem_Info
                             (Id_Interp,
                              new Sym_Reference_Info'
                                (Root_Semantic_Info with
                                 Associated_Symbol => Id_Sym,
                                 Nested_Region => null,
                                 Context => No_Context,
                                 Interps => null,
                                 Resolved_Type => null,
                                 Resolved_Interp => Null_Optional_Tree,
                                 Hash_Value => 0,
                                 Target_Polymorphic_Type => null,
                                 Reported_As_Undefined => False,
                                 Prefix_Type_Region => null,
                                 Underlying_Sem_Info =>
                                   Sem_Ptr (Id_Sym.Sem_Info)));

                           Interpretations.Add_Interp
                             (Interps,
                              Associated_Type_Region => Type_Region,
                              Interp => Id_Interp,
                              Interp_Added => Interp_Added);

                           if Interp_Added
                             and then Add_Call_Interps_To /= Null_Optional_Tree
                           then
                              --  Create call interps for this new operation
                              --  interp
                              Create_Call_Interps
                                (Add_Call_Interps_To,
                                 Only_For_Operation_Interp => Id_Interp,
                                 Operation_Type_Region => Type_Region);
                           end if;

                           if Debug_Second_Pass then
                              if not Interp_Added then
                                 Put (" Did NOT");
                              end if;
                              if Operation_Filter /= Any_Operation then
                                 Put_Line
                                   (" Add particular op interp for " &
                                    Subtree_Image (Id_Tree) &
                                    " for type " &
                                    Type_Image (Operation_Param_Type) &
                                    " with filter " &
                                    Operand_Info_Image (Operation_Filter));
                              else
                                 Put_Line
                                   (" Add Operation Interp for " &
                                    Sym_Name (Id_Sym) &
                                    " from region of type " &
                                    Type_Image (Operation_Param_Type));
                              end if;
                           end if;
                        end;
                     end if;
                  end;
               else
                  if Debug_Second_Pass then
                     Put_Line
                       (" Skip non-operation Decl for " &
                        Sym_Name (Id_Sym) &
                        " from region of type " &
                        Type_Image (Operation_Param_Type));
                  end if;
               end if;
               Id_Sym := Next_Homonym;
            end;
         end loop;
      end Add_Operations_From_Region;

      Originating_Type : Type_Sem_Ptr := Type_Sem_Ptr (Type_Region);

   begin  --  Add_Operation_Interps

      --  Add operations from set of regions where operations might be found.
      --  For a "new" type this includes where the new type is defined.
      --  For a "regular" type, this is the region of the associated module.
      while Originating_Type.New_Type_Counter /= Anonymous_Type_Indicator loop
         --  Add ops from where "new" type is declared

         Add_Operations_From_Region
           (Originating_Type.U_Base_Type.Associated_Symbol.Enclosing_Region,
            Type_Sem_Ptr
              (Originating_Type.U_Base_Type.
               Associated_Symbol.Sem_Info));

         --  Move on to parent type
         pragma Assert (Originating_Type.Parent_Type /= null);

         Originating_Type := Originating_Type.Parent_Type;
      end loop;

      --  Now include the region of the associated module.
      Add_Operations_From_Region
        (Originating_Type.Associated_Module.Nested_Region,
         Originating_Type.Associated_Module.Cur_Inst_Sem);

      if Originating_Type.Associated_Module.Contains_Ref_Component
        and then Operation_Name /= Ref_Op_Str
      then
         --  Look for "ref" operation
         --  TBD: Also look for "var_ref" operation?
         declare
            Result_Of_Ref : constant Type_Sem_Ptr :=
              Get_Ref_Func_Output_Type (Originating_Type);
         begin
            if Result_Of_Ref /= null then
               --  Add operations for result-of-ref type as well
               Add_Operation_Interps
                 (Interps,
                  U_Base_Type_Region (Result_Of_Ref),
                  Operation_Name,
                  Source_Pos,
                  Operation_Filter,
                  Implementing_Module,
                  Add_Call_Interps_To);
            end if;
         end;
      end if;

   end Add_Operation_Interps;

   procedure Add_Type_Region_For_Operation_Name
     (Operation_Designator : Optional_Tree;
      Type_Region : Type_Sem_Ptr;
      Operation_Filter : Operand_Info := Any_Operation) is
      --  Add region for interpretations of name of operation.
      --  If region not already in interpretation tree, do a lookup
      --  in this region, and find all interpretations that are
      --  externally visible.
      --  NOTE: This is called on the operation of an invocation, with
      --       the regions of the types of the inputs and outputs
      --       of the invocation.  "Invocation" includes a use of a
      --       unary or binary operator.  It is also called when
      --       a parameter of an invocation is an operation, with
      --       the regions of the types of all of the inputs and outputs.

      Op_Sem : constant Root_Sem_Ptr := Sem_Info (Operation_Designator);
      Op_Desig_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                  (Operation_Designator).all;
   begin
      if Op_Sem /= null
        and then Op_Sem.all in Operand_Semantic_Info'Class
        and then U_Base_Type_Region (Type_Region) /= null
        and then Op_Desig_Tree in Identifier.Tree
        and then (Operation_Filter /= Any_Operation
                 or else not Interpretations.Has_Type_Region
                               (Operand_Sem_Ptr (Op_Sem).Interps,
                                U_Base_Type_Region (Type_Region)))
      then
         --  This is a new region for this designator
         Add_Operation_Interps
           (Operand_Sem_Ptr (Op_Sem).Interps,
            U_Base_Type_Region (Type_Region),
            Identifier.Tree (Op_Desig_Tree).Str,
            Identifier.Tree (Op_Desig_Tree).Source_Pos,
            Operation_Filter => Operation_Filter);
      end if;
   end Add_Type_Region_For_Operation_Name;

   procedure Add_Param_Regions_For_Operation_Name
     (Operation_Designator : Optional_Tree;
      Parameters : Lists.List;
      Assoc_Type_Region : Type_Region_Ptr := null) is
      --  Add regions for interpretations of name of operation,
      --  given list of parameters.
      --  If region not already in interpretation tree, do a lookup
      --  in this region, and find all interpretations that are
      --  externally visible.
      --  NOTE: This is called when a parameter of an invocation
      --        is an operation, or when an operation is declared as
      --        a renaming of another, with the inputs and outputs of
      --        the "formal" or renamed operation.

   begin
      --  Include regions associated with parameter types,
      --  in case we are renaming an operation from another module.
      for I in 1 .. Lists.Length (Parameters) loop
         declare
            Param_Sem : constant Param_Sem_Ptr :=
              Param_Sem_Ptr (Sem_Info
                                (Lists.Nth_Element
                                    (Parameters, I)));
         begin
            Add_Type_Region_For_Operation_Name
              (Operation_Designator,
                (Substitute_Actuals
                  (Param_Sem.Resolved_Type, Assoc_Type_Region)));
         end;
      end loop;
   end Add_Param_Regions_For_Operation_Name;

   procedure Update_Outermost_Module_Where_Used
     (Type_Sem : Type_Sem_Ptr;
      New_Module_Where_Used : Module_Sem_Ptr);
   --  Update Outermost_Module_Where_Used of Type_Sem if
   --  New_Module_Where_Used is different and enclosing.

   function Qualify_Type (Original_Type : Type_Sem_Ptr;
     Decl_Region : Symbols.Region_Ptr;
     Definition : Optional_Tree := Null_Optional_Tree;
     Is_Optional : Boolean := False;
     Is_Concurrent : Boolean := False;
     Is_Polymorphic : Boolean := False) return Type_Sem_Ptr is
   --  Create a new type with the specified qualifiers added in

      Qualified_Type : Type_Sem_Ptr;
   begin
      if Original_Type /= null then
         if Original_Type.U_Base_Type = null then
            --  Finish original type before copying it
            Finish_Type_Sem_Info (Original_Type, Decl_Region);
         end if;
         Qualified_Type := new Type_Semantic_Info'(Original_Type.all);
         if Not_Null (Definition) then
            Qualified_Type.Definition := Definition;
         else
            Qualified_Type.Definition := Qualifier.Qualify
              ((Qualifier.Is_Optional => Is_Optional,
                Qualifier.Is_Concurrent => Is_Concurrent,
                Qualifier.Is_Polymorphic => Is_Polymorphic,
                others => False),
               Original_Type.Definition);
         end if;
      else
         --  Some error already reported
         Qualified_Type := new Type_Semantic_Info;
         --  Try to fill in associated module to prevent cascading errs
         if Any_Type /= null then
            Qualified_Type.Associated_Module :=
              Any_Type.Associated_Module;
            Qualified_Type.U_Base_Type := Any_Type;
         end if;
         Qualified_Type.Definition := Definition;
      end if;

      Set_Sem_Info (Qualified_Type.Definition,
        Root_Sem_Ptr (Qualified_Type));

      if Is_Optional then
         Qualified_Type.Value_Is_Optional := True;
      end if;
      if Is_Concurrent then
         Qualified_Type.Obj_Is_Concurrent := True;
      end if;
      if Is_Polymorphic then
         Qualified_Type.Is_Polymorphic := True;
         Qualified_Type.Known_To_Be_Small := False;
         Qualified_Type.Known_To_Be_Large := True;
      end if;

      if Debug_Second_Pass then
         Put_Line
           (" Creating qualified type " &
            Type_Image (Qualified_Type) &
            " from " &
            Type_Image (Original_Type));
      end if;

      --  See if this is a unique type
      Qualified_Type.U_Type := Find_U_Type (Qualified_Type);

      if Debug_Second_Pass
        and then Qualified_Type.U_Type = Qualified_Type
      then
         Put_Line
           (" Qualified type " &
            Type_Image (Qualified_Type) &
            " is new.");
         if not Qualified_Type.All_Parameters_Known then
            Put_Line ("  (All_Parameters_Known = FALSE)");
         end if;
      end if;

      pragma Assert (Qualified_Type.All_Parameters_Known =
        Qualified_Type.U_Base_Type.All_Parameters_Known);

      return Qualified_Type;
   end Qualify_Type;

   function Get_Type
     (Region : Symbols.Region_Ptr;
      Type_Spec : Optional_Tree;
      Context : Context_Enum := Type_Context;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      Value_Is_Optional : Boolean := False;
      Complain_If_Not_A_Type : Boolean := True)
      return Type_Sem_Ptr
   is
      --  Determine type given optional type specifier
      --  Complain_If_Not_A_Type defaults to True, meaning a semantic error
      --  is generated if Type_Spec cannot be interpreted as a type.
      --  Independent of this flag, "null" is returned when Type_Spec
      --  does not define a type.

      Sem : constant Sem_Ptr := Underlying_Sem_Info (Type_Spec);
      Result : Type_Sem_Ptr := null;
   begin
      if Debug_Second_Pass then
         Put_Line (" Get_Type on " & Subtree_Image (Type_Spec) &
           " with context " & Context_Enum'Image (Context));
      end if;
      if Sem = null then
         if Debug_Second_Pass then
            Put_Line (" Sem info is null");
         end if;
      else
         if Sem.all in Type_Semantic_Info then
            --  We have a type defined by instantiation
            Result := Type_Sem_Ptr (Sem);
         elsif Sem.all in Operation_Semantic_Info
           and then Operation_Sem_Ptr (Sem).Func_Type_Sem /= null
         then
            --  We have a func type
            Result := Operation_Sem_Ptr (Sem).Func_Type_Sem;
         elsif Sem_Info (Type_Spec).all in Annotation_Semantic_Info then
            Result := Get_Type
                     (Region,
                      Annotation_Sem_Ptr (Sem_Info (Type_Spec)).
                        Underlying_Sem_Info.Definition,
                      Complain_If_Not_A_Type => False);
         elsif Sem_Info (Type_Spec).all in Sym_Reference_Info then
            --  We have a symbol, see what kind of thing it is
            declare
               Type_Sym_Ref : constant Sym_Ref_Ptr :=
                 Sym_Ref_Ptr (Sem_Info (Type_Spec));
               Type_Sym : Sym_Ptr := Type_Sym_Ref.Associated_Symbol;
               Next_Region : Region_Ptr := Region;
               Type_Spec_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                            (Type_Spec).all;
            begin
               if Type_Sym_Ref.Underlying_Sem_Info /= null
                 and then Type_Sym_Ref.Underlying_Sem_Info.all in
                   Type_Semantic_Info
               then
                  --  Our work is already done for us
                  Result := Type_Sem_Ptr (Type_Sym_Ref.Underlying_Sem_Info);
               end if;
               while Result = null
                 and then Type_Sym /= null
                 and then Type_Sym.Sem_Info /= null loop

                  if Type_Sym.Sem_Info.all in Type_Semantic_Info then
                     --  We have a type name
                     Type_Sym_Ref.Underlying_Sem_Info :=
                       Sem_Ptr (Type_Sym.Sem_Info);
                     Result := Type_Sem_Ptr (Type_Sym.Sem_Info);
                     exit;  --  Exit the loop  --

                  elsif Type_Sym.Sem_Info.all in Operation_Semantic_info
                    and then
                      Operation_Sem_Ptr (Type_Sym.Sem_Info).Func_Type_Sem /=
                        null
                  then
                     --  We have the name of a func type
                     Type_Sym_Ref.Underlying_Sem_Info := Sem_Ptr
                       (Operation_Sem_Ptr (Type_Sym.Sem_Info).Func_Type_Sem);
                     Result := Type_Sem_Ptr (Type_Sym_Ref.Underlying_Sem_Info);
                     exit;  --  Exit the loop  --

                  elsif Type_Sym.Sem_Info.all in Module_Semantic_Info then
                     --  A module name can be used when wanting a type,
                     --  presuming we can meaningfully implicitly
                     --  instantiate it
                     if Context = Module_Extends_Interface_Context
                       or else
                         (Num_Module_Parameters
                           (Module_Sem_Ptr (Type_Sym.Sem_Info)) = 0
                         and then Context /= Module_Actual_Of_Formal_Context)
                     then
                        --  Extending an interface, or no module parameters,
                        --  so can use current instance or Primary_Nested_Type
                        declare
                           Mod_Sem : constant Module_Sem_Ptr := Interface_Part
                             (Module_Sem_Ptr (Type_Sym.Sem_Info));
                           Type_For_Module : Type_Sem_Ptr :=
                             Mod_Sem.Cur_Inst_Sem;
                        begin
                           if Mod_Sem.Primary_Nested_Type /= null then
                              --  Use Primary_Nested_Type when non-null
                              Type_For_Module := Mod_Sem.Primary_Nested_Type;
                           end if;

                           if Type_Sym_Ref.Prefix_Type_Region /= null
                             and then Type_For_Module /= null
                           then
                              --  Use Prefix
                              Type_For_Module :=
                                Substitute_Actuals (Type_For_Module,
                                  Type_Sym_Ref.Prefix_Type_Region);
                              pragma Assert (Type_For_Module /= null);
                           end if;
                           if Debug_Second_Pass then
                              Put_Line
                                (" Found module " &
                                 Sym_Name (Type_Sym) &
                                 ", Associated type = " &
                                 Type_Image (Type_For_Module));
                           end if;
                           Update_Outermost_Module_Where_Used
                             (Type_For_Module,
                              Find_Enclosing_Module_Interface (Region));

                           Type_Sym_Ref.Underlying_Sem_Info :=
                             Sem_Ptr (Type_For_Module);
                           Result := Type_For_Module;
                           exit;  --  Exit the loop  --
                        end;
                     else
                        --  Try to instantiate with all defaults
                        declare
                           Default_Inst : constant Optional_Tree :=
                             Invocation.Make
                                (Kind => Invocation.Module_Instantiation,
                                 Prefix => Type_Spec,
                                    --  TBD: Might be a qualified name
                                    --      so we have to make a full copy
                                    --      or use the original.
                                 Operands => Lists.Empty_List,
                                 Source_Pos => Find_Source_Pos (Type_Spec));
                        begin
                           Second_Pass
                             (Region,
                              Default_Inst,
                              Context => Context,
                              Formal_Prefix => Formal_Prefix);

                           --  TBD: We need to check for Primary_Nested_Type

                           --  Recurse on default instantiation
                           declare
                              Default_Inst_Type : constant Type_Sem_Ptr :=
                                Get_Type (Region, Default_Inst,
                                  Context => Context,
                                  Formal_Prefix => Formal_Prefix,
                                  Complain_If_Not_A_Type => False);
                           begin
                              Type_Sym_Ref.Underlying_Sem_Info :=
                                Sem_Ptr (Default_Inst_Type);
                              Result := Default_Inst_Type;
                              exit;  --  Exit the loop  --
                           end;
                        end;
                     end if;
                  end if;

                  --  A parameter named by default by its type might be hiding
                  --  the type, or the name might denote a module (perhaps
                  --  the enclosing module), in which case we go ahead
                  --  and interpret it as a type.

                  if Type_Spec_Tree in Identifier.Tree then
                     --  Keep looking up the chain.
                     Type_Sym := Next_Homonym_In_Region_Chain
                       (Type_Sym, Orig_Region => Region);
                  else
                     --  Don't go beyond the current region
                     Type_Sym := Next_Homonym_In_Region (Type_Sym,
                        Orig_Region => Region);
                  end if;
               end loop;
            end;
         end if;
      end if;

      if Result = null then
         --  No result available
         if Complain_If_Not_A_Type then
            Sem_Error
              (Type_Spec,
               Subtree_Image (Type_Spec) &
                " has no interpretation as a module or a type");
         end if;
         return null;

      end if;

      if Result.Associated_Module /= null
        and then Result.Associated_Module.Primary_Nested_Type /= null
      then
         --  Use Primary_Nested_Type if available, properly qualified
         Result := Qualify_Type
           (Substitute_Actuals
             (Result.Associated_Module.Primary_Nested_Type,
              U_Base_Type_Region (Result)),
            Region,
            Is_Optional => Result.Value_Is_Optional or Value_Is_Optional,
            Is_Polymorphic => Result.Is_Polymorphic);
      end if;

      if Result.External_View /= null
        and then Result.U_Base_Type /= Result.External_View.U_Base_Type
      then
         --  Always return the External_View if provided.
         if (not Result.External_View.Value_Is_Optional
             and then (Result.Value_Is_Optional or Value_Is_Optional))
           or else Result.External_View.Is_Polymorphic /=
             Result.Is_Polymorphic
         then
            --  Add Optional/Polymorphic to External_View
            Result := Qualify_Type
              (Result.External_View, Region, Is_Optional => True,
                Is_Polymorphic => Result.Is_Polymorphic);
         else
            --  External view as-is is fine
            Result := Result.External_View;
         end if;

      elsif Value_Is_Optional and then not Result.Value_Is_Optional then
         --  Need to add "Value_Is_Optional" to type
         Result := Qualify_Type (Result, Region, Is_Optional => True);

      --  else we have the right result
      end if;

      --  If this has a resolved type, copy back into its underlying_sem_info
      if Result /= null
        and then Sem_Info (Type_Spec).all in Operand_Semantic_Info'Class
      then
         --  Copy back as underlying-sem info
         if Debug_Second_Pass then
            if Underlying_Sem_Info (Type_Spec) /= Sem_Ptr (Result)
              or else Resolved_Type (Type_Spec) /= Result
            then
               Put_Line (" Get_Type copying result type " &
                 Type_Image (Result) &
                 " onto Operand " & Subtree_Image (Type_Spec));
            end if;
         end if;
         Operand_Sem_Ptr (Sem_Info (Type_Spec)).Resolved_Type := Result;

         if Sem_Info (Type_Spec).all in Sym_Reference_Info then
            Sym_Ref_Ptr (Sem_Info (Type_Spec)).Underlying_Sem_Info :=
              Sem_Ptr (Result);
         end if;
      end if;

      return Result;

   end Get_Type;

   procedure Dump_Type (Expr_Type : Type_Sem_Ptr);
   pragma Export (Ada, Dump_Type, "dump_type");

   procedure Dump_Type (Expr_Type : Type_Sem_Ptr) is
   --  For debugging -- dump image of type
   begin
      Put_Line (Type_Image (Expr_Type, Use_Short_Form => False));
   end Dump_Type;

   procedure Dump_Resolved_Tree (OT : Optional_Tree; Indent : Natural := 0);
   pragma Export (Ada, Dump_Resolved_Tree, "dump_rt");

   procedure Dump_Resolved_Tree (OT : Optional_Tree; Indent : Natural := 0) is
      --  For debugging -- dump tree with type information
      Indent_Str : constant String (1 .. 1000) := (others => ' ');
   begin
      if Is_Null (OT) then
         Put_Line (Indent_Str (1 .. Indent) & "null");
      else
         declare
            Resolved_Ot : constant Optional_Tree := Resolved_Tree (OT);
            Resolved_T : Trees.Tree'Class renames Tree_Ptr_Of
                                                     (Resolved_Tree (OT)).all;
         begin
            if Resolved_T.Sem_Info = null then
               null;  --  Fall back to default
            elsif Resolved_T in Invocation.Tree then
               --  Handle invocations specially
               declare
                  Invoc_Tree : Invocation.Tree renames Invocation.Tree (
                    Resolved_T);
                  Ending_Char : Character;
                  Assoc_Type_Region : Type_Region_Ptr := null;
                  Resolved_Type : constant Type_Sem_Ptr :=
                    Operand_Sem_Ptr (Invoc_Tree.Sem_Info).Resolved_Type;
                  Generic_Param_Map : Param_Mapping_Ptr := null;
                  use Invocation;
               begin
                  Put (Indent_Str (1 .. Indent));
                  case Invoc_Tree.Kind is
                     when Operation_Call =>
                        --  Display operation name and type
                        Put (Subtree_Image (Invoc_Tree.Prefix) & "(");
                        Ending_Char := ')';
                        Assoc_Type_Region :=
                          Call_Sem_Ptr (Invoc_Tree.Sem_Info).Assoc_Type_Region;
                        Generic_Param_Map :=
                          Call_Sem_Ptr (Invoc_Tree.Sem_Info).Generic_Param_Map;
                     when Container_Indexing =>
                        Put (Subtree_Image (Invoc_Tree.Prefix) & "[");
                        Ending_Char := ']';
                     when Class_Aggregate =>
                        if Not_Null (Invoc_Tree.Prefix) then
                           Put (Subtree_Image (Invoc_Tree.Prefix) & "::(");
                        else
                           Put ("(");
                        end if;
                        Ending_Char := ')';
                     when Container_Aggregate =>
                        if Not_Null (Invoc_Tree.Prefix) then
                           Put (Subtree_Image (Invoc_Tree.Prefix) & "::[");
                        else
                           Put ("[");
                        end if;
                        Ending_Char := ']';
                     when Map_Set_Aggregate =>
                        if Not_Null (Invoc_Tree.Prefix) then
                           Put (Subtree_Image (Invoc_Tree.Prefix) & "::[");
                        else
                           Put ("{");
                        end if;
                        Ending_Char := '}';
                     when Module_Instantiation =>
                        Put (Subtree_Image (Invoc_Tree.Prefix) & "<");
                        Ending_Char := '>';
                     when Is_Function_Of =>
                        Put (Subtree_Image (Invoc_Tree.Prefix) & " is func(");
                        Ending_Char := ')';
                     when Tuple_Type_Definition =>
                        Put ("(");
                        Ending_Char := ')';
                  end case;
                  Put_Line (" // {" & Type_Image (Resolved_Type) & '}');
                  if Assoc_Type_Region /= null
                    and then (Resolved_Type = null
                             or else Type_Sem_Ptr (Assoc_Type_Region).
                       U_Base_Type /=
                                     Resolved_Type.U_Base_Type)
                  then
                     Put_Line
                       (Indent_Str (1 .. Indent + 3) &
                        "// Assoc_TR => " &
                        Type_Image (Type_Sem_Ptr (Assoc_Type_Region)));
                  end if;
                  if Generic_Param_Map /= null then
                     Put_Line
                       (Indent_Str (1 .. Indent + 3) &
                        "// GP_Map => " &
                        Param_Map_Image (Generic_Param_Map));
                  end if;

                  for I in 1 .. Lists.Length (Invoc_Tree.Operands) loop
                     Dump_Resolved_Tree
                       (Lists.Nth_Element (Invoc_Tree.Operands, I),
                        Indent => Indent + 1);
                  end loop;
                  Put_Line (Indent_Str (1 .. Indent) & Ending_Char);

                  return;  --  All done  --
               end;
            elsif Resolved_T in Conditional.Tree then
               --  Handle conditional specially
               declare
                  Cond_Tree : Conditional.Tree renames
                    Conditional.Tree (Resolved_T);
               begin
                  Put_Line (Indent_Str (1 .. Indent) & "if:");
                  Dump_Resolved_Tree (Cond_Tree.Cond, Indent + 1);
                  Put_Line (Indent_Str (1 .. Indent) & "then:");
                  Dump_Resolved_Tree (Cond_Tree.Then_Part, Indent + 1);
                  if Not_Null (Cond_Tree.Else_Part) then
                     Put_Line (Indent_Str (1 .. Indent) & "else:");
                     Dump_Resolved_Tree (Cond_Tree.Else_Part, Indent + 1);
                  end if;
                  return; --  All done  --
               end;
            elsif Resolved_T in For_Loop_Construct.Tree then
               --  Handle for-loop specially
               declare
                  For_Loop_Tree : For_Loop_Construct.Tree renames
                    For_Loop_Construct.Tree (Resolved_T);
               begin
                  Put_Line (Indent_Str (1 .. Indent) & "for-loop iterators:");
                  for I in 1 .. Lists.Length (For_Loop_Tree.Iterators) loop
                     Dump_Resolved_Tree
                       (Lists.Nth_Element
                          (For_Loop_Tree.Iterators, I), Indent + 1);
                  end loop;
                  Put_Line (Indent_Str (1 .. Indent) & "for-loop body:");
                  Dump_Resolved_Tree (For_Loop_Tree.Loop_Body, Indent + 1);
                  return; --  All done  --
               end;
            end if;

            --  Fall back to a simple dump of subtree
            Display_Subtree
              (Resolved_Ot,
               On =>
                  Ada.Text_IO.Text_Streams.Stream
                    (Ada.Text_IO.Current_Output),
               Indent => Indent);
            New_Line;
         end;
      end if;
   end Dump_Resolved_Tree;

   function Substitute_In_Tree
     (OT : Optional_Tree;
      Assoc_Type_Region : Type_Region_Ptr;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null;
      Always_Copy_One_Level : Boolean := False;
      Always_Copy_Tree : Boolean := False)
      return Optional_Tree;
   --  Walk the tree and replace parameters, etc.
   --  based on actual type.
   --  If Always_Copy_One_Level is True, then force a one-level
   --  copy of the tree, even if no substitutions are made.
   --  If Always_Copy_Tree is True, then force a complete
   --  copy of the tree, even if no substitutions are made.

   function Substitute_In_List
     (Orig_List : Lists.List;
      Assoc_Type_Region : Type_Region_Ptr)
      return Lists.List
   is
   --  Return copy of list using Substitute_In_Tree
      Result : Lists.List;
   begin
      for I in 1 .. Lists.Length (Orig_List) loop
         Lists.Append (Result, Substitute_In_Tree
           (Lists.Nth_Element (Orig_List, I),
            Assoc_Type_Region => Assoc_Type_Region,
            Always_Copy_Tree => True));
      end loop;
      return Result;
   end Substitute_In_List;

   function Create_To_Univ_Call
     (Operand : Optional_Tree;
      To_Univ_Type : Type_Sem_Ptr)
      return Optional_Tree;
      --  Create call on "to_univ" from given Operand which
      --  is not of a universal type, to the target To_Univ_Type.

   function Create_Ref_Call (Operand : Optional_Tree) return Optional_Tree;
      --  Create call on "ref" from given Operand which
      --  is of a ref-obj type

   procedure Add_Targeted_Interps
     (Operand : Optional_Tree;
      Target_Type : Type_Sem_Ptr;
      Associated_Operation : Sym_Ptr := null);
      --  Add interps that are declared in given type's region
      --  and return the given type.
      --  Return immediately if Target_Type has non-null Associated_Generic_Op
      --  which matches Associated_Operation.

   procedure Find_Interp_Of_Type
     (Assoc_Type_Region : Type_Region_Ptr;
      Opnd : Optional_Tree;
      Param_Type : Type_Sem_Ptr;
      Generic_Param_Map : in out Param_Mapping_Ptr;
      Chosen_Interp : out Optional_Tree;
      Ambiguity : out Ambiguity_List;
      Associated_Operation : Sym_Ptr := null;
      Formal_Is_Var : Boolean := False;
      Diagnose : Boolean := False);
      --  Walk interp tree of Opnd and find one that
      --  matches given Param_Type.  If Param_Type is null,
      --  then return first Interp.
      --  Update Generic_Param_Map with additional mappings if
      --  Param type is a "generic" type.
      --  If Associated_Operation is non-null, then use that
      --  for the matching of generic parameters.
      --  Set Chosen_Interp to Null_Optional_Tree if no matching interp.
      --  Set Ambiguity if multiple interps.
      --  If Formal_Is_Var is true, then prefer var_indexing to indexing.
      --  If Diagnose is True, then produce messages indicating why
      --  expression does not resolve.

   procedure Find_Interp_Of_Signature
     (Op_Name : Optional_Tree;
      Signature : Operation_Sem_Ptr;
      Chosen_Interp : out Optional_Tree;
      Chosen_Assoc_Type_Region : out Type_Region_Ptr;
      Ambiguity : out Ambiguity_List;
      Signature_Type_Region : Type_Region_Ptr := null;
      Require_Exact_Type_Match : Boolean := False);
      --  Walk interp tree of Op_Name and find one that
      --  matches given Signature.  If Signature is null,
      --  then return first Interp.
      --  Set Chosen_Interp to Null_Optional_Tree if no matching interp.
      --  Set Chosen_Assoc_Type_Region to type where operation originates.
      --  Set Ambiguity if multiple interps.
      --  If Signature_Type_Region is non-null, then use that
      --  with Substitute_Actuals on Signature.
      --  If Require_Exact_Type_Match is True, then use same mod_sem for
      --  both signature and interp, since we don't want types to match
      --  just because both are current instances.

   procedure Create_Class_Agg_Interp
     (Agg_Sem : Class_Agg_Sem_Ptr;
      Target_Type : Type_Sem_Ptr;
      Diagnose : Boolean := False);
   --  Create interp for class aggregate of given Target_Type,
   --  presuming have already created interps for components.
   --  If Diagnose is True, then produce messages indicating why
   --  aggregate does *not* match.

   procedure Create_Container_Agg_Interp
     (Agg_Sem : Container_Agg_Sem_Ptr;
      Target_Type : Type_Sem_Ptr;
      Diagnose : Boolean := False);
   --  Create interp for container aggregate of given Target_Type,
   --  presuming have already created interps for components.
   --  If Diagnose is True, then indicate why aggregate does *not* match type.

   function Combine_Ambiguity (Left, Right : Ambiguity_List)
     return Ambiguity_List is
   --  Return combined ambiguity list
   begin
      if Left = null then
         return Right;
      elsif Right = null then
         return Left;
      else
         --  Need to combine
         return new Ambiguity_List_Node'
           (This_Interp => Left.This_Interp,
            Ambiguous_Operands =>  --  Recurse on Ambiguous_Operands list
              Combine_Ambiguity (Left.Ambiguous_Operands, Right),
            Next_Ambig_Interp => Left.Next_Ambig_Interp);
      end if;
   end Combine_Ambiguity;

   procedure Create_Null_Value_Interp
     (Lit_Sem : Literal_Sem_Ptr;
      Target_Type : Type_Sem_Ptr) is
      --  Create interp for null value of given target type.
      Interp_Added : Boolean;
   begin
      if Debug_Second_Pass then
         Put_Line
           (" Create_Null_Value_Interp: target-type = " &
            Type_Image (Target_Type));
      end if;
      if not Interpretations.Has_Type_Region
               (Lit_Sem.Interps,
                U_Base_Type_Region (Target_Type))
      then
         --  Create a "null" with the appropriate type
         declare
            Old_Null : Identifier.Tree renames Identifier.Tree (Tree_Ptr_Of
                                                                   (Lit_Sem.
              Definition).all);
            New_Null : constant Optional_Tree :=
              Identifier.Make
                 (Null_Str,
                  Identifier.Find_Source_Pos (Old_Null));
         begin
            Set_Literal_Sem_Info
              (Identifier.Tree (Tree_Ptr_Of (New_Null).all),
               Null_Literal,
               Target_Type => Target_Type);

            --  Add new interpretation of null to original tree.
            Interpretations.Add_Interp
              (Lit_Sem.Interps,
               U_Base_Type_Region (Target_Type),
               New_Null,
               Interp_Added => Interp_Added);

         end;
      else
         if Debug_Second_Pass then
            Put_Line
              (" Create_Null_Value_Interp: Lit_Sem already " &
               "has interp for target " &
               Type_Image (Target_Type));
         end if;
      end if;
   end Create_Null_Value_Interp;

   procedure Create_Conditional_Expr_Interps
     (T : in out Conditional.Tree;
      Target_Type : Type_Sem_Ptr := null) is
   --  Create interps of conditional expression if expr, elsif expr, "?:"
   --  If Target_Type /= null, only create interps of given type
      pragma Assert (T.Kind not in Conditional.Stmt_Parts);

      Cond_Sem : constant Composite_Stmt_Sem_Ptr :=
        Composite_Stmt_Sem_Ptr (T.Sem_Info);

      Then_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (T.Then_Part));

      Else_Part : Optional_Tree := T.Else_Part;
      Else_Sem : Sem_Ptr := Sem_Ptr (Sem_Info (Else_Part));

      Targeted_Then_Ambiguity : Ambiguity_List := null;

      procedure Build_Cond_Expr_Interp
        (Then_Interp : Optional_Tree;
         Else_Interp : Optional_Tree;
         Overall_Type : Type_Sem_Ptr;
         Ambiguity : Ambiguity_List) is
      --  Create a condional-expr interp
         Overall_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Overall_Type);
         Interp_Added : Boolean;
      begin

         if Is_Null (Then_Interp)
           or else Is_Null (Else_Interp)
         then
            --  Remember that we have created interps for this type
            Interpretations.Add_Interp
              (Cond_Sem.Interps,
               Associated_Type_Region => Overall_Type_Region,
               Interp => Null_Optional_Tree,
               Interp_Added => Interp_Added);

         else
            --  Build a new "cond-expr" interp
            declare
               Cond_Interp : constant Optional_Tree :=
                 Conditional.Make
                   (Source_Pos => T.Source_Pos,
                    Kind => T.Kind,
                    Cond => T.Cond,
                    Then_Part => Then_Interp,
                    Else_Part => Else_Interp);

               --  Make copy of sem info
               Interp_Sem : constant Composite_Stmt_Sem_Ptr :=
                 new Composite_Stmt_Semantic_Info'Class'(Cond_Sem.all);
            begin
               Set_Source_Pos (Cond_Interp, T.Source_Pos);

               --  Adjust copy of sem info
               Interp_Sem.Interps := null;
               Interp_Sem.Resolved_Type := Overall_Type.U_Base_Type;
               Interp_Sem.Ambiguity := Ambiguity;

               Set_Sem_Info (Cond_Interp, Root_Sem_Ptr (Interp_Sem));

               --  Now add the interpretation to the tree
               Interpretations.Add_Interp
                 (Cond_Sem.Interps,
                  Associated_Type_Region => Overall_Type_Region,
                  Interp => Cond_Interp,
                  Interp_Added => Interp_Added);
            end;
         end if;
      end Build_Cond_Expr_Interp;

      procedure Handle_Then_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Then_Interp : Optional_Tree) is
      --  For each interp of Then, build cond interp for each matching Else
         Then_Type : constant Type_Sem_Ptr := Resolved_Type (Then_Interp);
         Then_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Then_Type);

      begin  --  Handle_Then_Interp

         if Then_Type = null then
            --  Nothing to do
            return;
         end if;

         declare
            Resolved_Else_Interp : Optional_Tree := Null_Optional_Tree;
            Generic_Param_Map : Param_Mapping_Ptr := null;
            Else_Ambiguity : Ambiguity_List := null;
         begin
            --  Look for "else" part matching "then" part
            Find_Interp_Of_Type
              (U_Base_Type_Region (Then_Type),
               Else_Part,
               Then_Type,
               Generic_Param_Map,
               Resolved_Else_Interp,
               Else_Ambiguity);

            --  No "generic" type matches allowed here
            pragma Assert (Generic_Param_Map = null);

            --  Add this combination to overall set of interps
            Build_Cond_Expr_Interp
              (Then_Interp => Then_Interp,
               Else_Interp => Resolved_Else_Interp,
               Overall_Type => Then_Type,
               Ambiguity =>
                 Combine_Ambiguity (Else_Ambiguity, Targeted_Then_Ambiguity));
         end;

      end Handle_Then_Interp;

      procedure Handle_Else_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Else_Interp : Optional_Tree) is
      --  For each type of interp of Else, try to find a matching "Then"

         Else_Type : constant Type_Sem_Ptr := Resolved_Type (Else_Interp);
         Else_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Else_Type);
      begin
         if Else_Type = null
           or else Interpretations.Has_Type_Region
             (Cond_Sem.Interps, Else_Type_Region)
           or else Interpretations.Has_Type_Region
             (Operand_Sem_Ptr (Then_Sem).Interps, Else_Type_Region)
         then
            --  Already handled by "then" part
            return;
         end if;

         --  Look for an interpretation of the then part matching the
         --  "else" part type
         declare
            Resolved_Then_Interp : Optional_Tree := Null_Optional_Tree;
            Generic_Param_Map : Param_Mapping_Ptr := null;
            Then_Ambiguity : Ambiguity_List := null;
         begin

            --  Look for "then" part matching "else" type
            Find_Interp_Of_Type
              (U_Base_Type_Region (Else_Type),
               T.Then_Part,
               Else_Type,
               Generic_Param_Map,
               Resolved_Then_Interp,
               Then_Ambiguity);

            --  No "generic" type matches allowed here
            pragma Assert (Generic_Param_Map = null);

            --  Add this combination to overall set of interps
            Build_Cond_Expr_Interp
              (Then_Interp => Resolved_Then_Interp,
               Else_Interp => Else_Interp,
               Overall_Type => Else_Type,
               Ambiguity => Then_Ambiguity);
         end;
      end Handle_Else_Interp;

      procedure Build_Then_Interps is new Interpretations.Iterate_Interps (
         Handle_Then_Interp);

      procedure Build_Else_Interps is new Interpretations.Iterate_Interps (
         Handle_Else_Interp);

   begin  --  Create_Conditional_Expr_Interps

      --  For each interp of Then part, add targeted interps to
      --  Else part based on its resolved type, and vice-versa.
      --  Then build an interp for each resolved type appearing in both.

      if Is_Null (Else_Part)
        and then (Target_Type /= null
          or else (Then_Sem /= null
            and then Then_Sem.all in Operand_Semantic_Info'Class
            and then Interpretations.Has_Interp
              (Operand_Sem_Ptr (Then_Sem).Interps)))
      then

         --  Absence of an else part is equivalent to "else null"
         --  but we only add "else null" if we have a target type for it.
         Else_Part :=
           Identifier.Make
              (Null_Str,
               Conditional.Find_Source_Pos (T));

         --  Fill in semantic info
         Set_Literal_Sem_Info
           (Identifier.Tree (Tree_Ptr_Of (Else_Part).all),
            Null_Literal,
            Target_Type => Target_Type);

         Else_Sem := Sem_Ptr (Sem_Info (Else_Part));
      end if;

      if Cond_Sem = null
        or else Then_Sem = null
        or else Then_Sem.all not in Operand_Semantic_Info'Class
        or else Else_Sem = null
        or else Else_Sem.all not in Operand_Semantic_Info'Class
      then
         --  Nothing to do
         if Debug_Second_Pass then
            Put_Line (" Create_Conditional_Expr_Interps: Nothing to do for " &
              Subtree_Image (T));
         end if;
         return;
      end if;

      if Debug_Second_Pass then
         Put_Line (" Create_Conditional_Expr_Interps:");
         if Target_Type /= null then
            Put_Line ("  of type " & Type_Image (Target_Type));
         end if;
         Put_Line ("  initial then-part interps:");
         Interpretations.Dump_Interp_Tree (Operand_Sem_Ptr (Then_Sem).Interps);
         Put_Line ("  initial else-part interps:");
         Interpretations.Dump_Interp_Tree (Operand_Sem_Ptr (Else_Sem).Interps);
         Put_Line ("  initial overall interps:");
         Interpretations.Dump_Interp_Tree (Cond_Sem.Interps);
      end if;

      if Target_Type = null then
         --  Do bottom-up propagation

         --  Build cond interps based on then-part interps
         Build_Then_Interps (Operand_Sem_Ptr (Then_Sem).Interps);

         --  Build those based on else-part interps
         Build_Else_Interps (Operand_Sem_Ptr (Else_Sem).Interps);

      elsif not Interpretations.Has_Type_Region
             (Cond_Sem.Interps, U_Base_Type_Region (Target_Type))
      then
         --  See if can build interpretation for specified target type
         declare
            Resolved_Then_Interp : Optional_Tree := Null_Optional_Tree;
            Generic_Param_Map : Param_Mapping_Ptr := null;
            Empty_Interp_Added : Boolean;
         begin
            --  Look for "then" part matching Target_Type
            Find_Interp_Of_Type
              (U_Base_Type_Region (Target_Type),
               T.Then_Part,
               Target_Type,
               Generic_Param_Map,
               Resolved_Then_Interp,
               Targeted_Then_Ambiguity);

            --  No "generic" type matches allowed here
            pragma Assert (Generic_Param_Map = null);

            if Not_Null (Resolved_Then_Interp) then
               --  See whether there is a matching else
               Handle_Then_Interp (U_Base_Type_Region (Target_Type),
                 Resolved_Then_Interp);
            else
               --  Remember that we have handled this type
               Interpretations.Add_Interp
                 (Cond_Sem.Interps,
                  Associated_Type_Region => U_Base_Type_Region (Target_Type),
                  Interp => Null_Optional_Tree,
                  Interp_Added => Empty_Interp_Added);
            end if;
         end;
      end if;

      if Debug_Second_Pass then
         Put_Line (" Create_Conditional_Expr_Interps:");
         Put_Line ("  final then-part interps:");
         Interpretations.Dump_Interp_Tree (Operand_Sem_Ptr (Then_Sem).Interps);
         Put_Line ("  final else-part interps:");
         Interpretations.Dump_Interp_Tree (Operand_Sem_Ptr (Else_Sem).Interps);
         Put_Line ("  final overall interps:");
         Interpretations.Dump_Interp_Tree (Cond_Sem.Interps);
      end if;

   end Create_Conditional_Expr_Interps;

   procedure Create_Case_Expr_Interps
     (T : in out Case_Construct.Tree;
      Target_Type : Type_Sem_Ptr := null) is
   --  Create interps of case expression.
   --  If Target_Type /= null, only create interps of given type.
      pragma Assert (T.Is_Case_Expr);

      Case_Sem : constant Case_Construct_Sem_Ptr :=
        Case_Construct_Sem_Ptr (T.Sem_Info);

      Num_Case_Alts : constant Natural := Lists.Length (T.Case_Alt_List);

      procedure Build_Case_Expr_Interp
        (Overall_Type : Type_Sem_Ptr) is
      --  Create a case-expr interp of the given type, if possible,
      --  and add to Case_Sem.Interps.  Set Ambiguity flag when appropriate.

         Overall_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Overall_Type);
         Interp_Added : Boolean;

         New_Case_Alt_List : Lists.List;
         Overall_Ambig : Ambiguity_List := null;

      begin  --  Build_Case_Expr_Interp

         if Interpretations.Has_Type_Region
           (Case_Sem.Interps, Overall_Type_Region)
         then
            --  Already handled this one
            return;
         end if;

         --  See whether given type can match each alternative
         for I in 1 .. Num_Case_Alts loop
            declare
               Case_Alt : Reference.Tree renames
                 Reference.Tree (Tree_Ptr_Of
                   (Lists.Nth_Element (T.Case_Alt_List, I)).all);
               Generic_Param_Map : Param_Mapping_Ptr := null;
               Resolved_Alt_Interp : Optional_Tree;
               Alt_Ambiguity : Ambiguity_List := null;
            begin
               Find_Interp_Of_Type
                 (Overall_Type_Region,
                  Case_Alt.Referent,
                  Overall_Type,
                  Generic_Param_Map,
                  Resolved_Alt_Interp,
                  Alt_Ambiguity);

               if Is_Null (Resolved_Alt_Interp) then
                  --  Remember we have tried to create an interp for this type
                  Interpretations.Add_Interp
                    (Case_Sem.Interps,
                     Associated_Type_Region => Overall_Type_Region,
                     Interp => Null_Optional_Tree,
                     Interp_Added => Interp_Added);

                  return;   --  Give up now  --

               end if;

               if Alt_Ambiguity /= null then
                  --  This type produces ambiguity
                  Overall_Ambig :=
                    Combine_Ambiguity (Overall_Ambig, Alt_Ambiguity);
               end if;

               --  Add to list of new "case-alt" interpretations
               Lists.Append (New_Case_Alt_List,
                 Reference.Make
                   (Key => Case_Alt.Key, Referent => Resolved_Alt_Interp));
            end;
         end loop;

         --  Now build a new "case-expr" interp using new list of case-alt's
         declare
            Case_Interp : constant Optional_Tree :=
              Case_Construct.Make
                (Source_Pos => T.Source_Pos,
                 Case_Selector => T.Case_Selector,
                 Case_Alt_List => New_Case_Alt_List,
                 Is_Case_Expr => True);

            --  Make copy of sem info
            Interp_Sem : constant Case_Construct_Sem_Ptr :=
              new Case_Construct_Semantic_Info'Class'(Case_Sem.all);
         begin
            Set_Source_Pos (Case_Interp, T.Source_Pos);

            --  Adjust copy of sem info
            Interp_Sem.Interps := null;
            Interp_Sem.Resolved_Type := Overall_Type.U_Base_Type;
            Interp_Sem.Ambiguity := Overall_Ambig;

            Set_Sem_Info (Case_Interp, Root_Sem_Ptr (Interp_Sem));

            --  Now add the interpretation to the tree
            Interpretations.Add_Interp
              (Case_Sem.Interps,
               Associated_Type_Region => Overall_Type_Region,
               Interp => Case_Interp,
               Interp_Added => Interp_Added);
         end;
      end Build_Case_Expr_Interp;

      procedure Try_Overall_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Case_Interp : Optional_Tree) is
      --  For each interp of first case alt,
      --  see whether its type can be overall type.

         Overall_Type : constant Type_Sem_Ptr :=
           Operand_Sem_Ptr (Sem_Info (Case_Interp)).Resolved_Type;
      begin
         if Overall_Type /= null then
            Build_Case_Expr_Interp (Overall_Type);
         end if;
      end Try_Overall_Interp;

      procedure Try_Overall_Interps is
        new Interpretations.Iterate_Interps (Try_Overall_Interp);

   begin  --  Create_Case_Expr_Interps

      if Debug_Second_Pass then
         Put_Line (" Create_Case_Expr_Interps:");
         if Target_Type /= null then
            Put_Line ("  of type " & Type_Image (Target_Type));
         end if;
         Put_Line ("  initial overall interps:");
         Interpretations.Dump_Interp_Tree (Case_Sem.Interps);
      end if;

      if Target_Type /= null then
         --  We already have target type to use
         Build_Case_Expr_Interp (Target_Type);

      else
         --  Iterate through interps of each case alt, and
         --  add its type as a target for all other case-alt's
         for I in 1 .. Num_Case_Alts loop
            declare
               Case_Alt : Reference.Tree renames
                 Reference.Tree (Tree_Ptr_Of
                   (Lists.Nth_Element (T.Case_Alt_List, I)).all);
               Case_Alt_Sem : constant Operand_Sem_Ptr :=
                 Operand_Sem_Ptr (Sem_Info (Case_Alt.Referent));

               procedure Handle_Case_Interp
                 (Assoc_Type_Region : Type_Region_Ptr;
                  Case_Interp : Optional_Tree) is
               --  For each interp of case alt,
               --  add its type as target to others

                  Case_Type : constant Type_Sem_Ptr :=
                    Resolved_Type (Case_Interp);
                  Case_Type_Region : constant Type_Region_Ptr :=
                    U_Base_Type_Region (Case_Type);

               begin  --  Handle_Case_Interp

                  if Case_Type = null then
                     --  Nothing to do
                     return;
                  end if;

                  --  Add type as target for interps of other alts
                  for J in 1 .. Num_Case_Alts loop
                     if J /= I then  --  Skip over original case-alt
                        declare
                           Other_Case_Alt : Reference.Tree renames
                             Reference.Tree (Tree_Ptr_Of
                               (Lists.Nth_Element (T.Case_Alt_List, J)).all);
                        begin
                           --  Add targeted interps
                           Add_Targeted_Interps
                             (Other_Case_Alt.Referent, Case_Type);
                        end;
                     end if;
                  end loop;

               end Handle_Case_Interp;

               procedure Add_Target_Type_To_Case_Alts is
                 new Interpretations.Iterate_Interps (Handle_Case_Interp);

            begin

               if Case_Alt_Sem /= null then
                  --  Add each type of this alternative
                  --  as a target for the others
                  Add_Target_Type_To_Case_Alts (Case_Alt_Sem.Interps);
               end if;

            end;
         end loop;

         if Num_Case_Alts > 0 then
            --  Iterate interps of first case-alt and try to apply to
            --  all others.
            declare
               First_Case_Alt : Reference.Tree renames
                 Reference.Tree (Tree_Ptr_Of
                   (Lists.Nth_Element (T.Case_Alt_List, 1)).all);
            begin
               Try_Overall_Interps (Operand_Sem_Ptr
                 (Sem_Info (First_Case_Alt.Referent)).Interps);
            end;
         end if;

      end if;

      if Debug_Second_Pass then
         Put_Line (" Create_Case_Expr_Interps:");
         Put_Line ("  final overall interps:");
         Interpretations.Dump_Interp_Tree (Case_Sem.Interps);
      end if;
   end Create_Case_Expr_Interps;

   procedure Create_Map_Reduce_Expr_Interps
     (T : For_Loop_Construct.Tree;
      Target_Type : Type_Sem_Ptr := null) is
      --  Create interps for map-reduce expr;
      --  Create interps only of Target_Type if not null.

      use type For_Loop_Construct.For_Loop_Kind_Enum;
      pragma Assert (T.Kind = For_Loop_Construct.Map_Reduce_Expr);

      Map_Reduce_Sem : constant For_Loop_Construct_Sem_Ptr :=
        For_Loop_Construct_Sem_Ptr (T.Sem_Info);

      Interp_Added : Boolean;

      procedure Build_Map_Reduce_Expr_Interp
        (Target_Type : Type_Sem_Ptr;
         Ambiguity : Ambiguity_List := null) is
         --  Create one interp of map-reduce expr of given type
         Target_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Target_Type);
      begin
         if Target_Type /= null
           and then not Interpretations.Has_Type_Region
               (Map_Reduce_Sem.Interps, Target_Type_Region)
         then
            --  This type hasn't been seen yet
            declare
               Generic_Param_Map : Param_Mapping_Ptr := null;
               Resolved_Body_Interp : Optional_Tree;
               Body_Ambiguity : Ambiguity_List;
            begin
               Find_Interp_Of_Type
                 (Target_Type_Region,
                  T.Loop_Body,
                  Target_Type,
                  Generic_Param_Map,
                  Resolved_Body_Interp,
                  Body_Ambiguity);

               if Is_Null (Resolved_Body_Interp) then
                  --  Remember we have tried to create an interp for this type
                  Interpretations.Add_Interp
                    (Map_Reduce_Sem.Interps,
                     Associated_Type_Region => Target_Type_Region,
                     Interp => Null_Optional_Tree,
                     Interp_Added => Interp_Added);

                  return;   --  Give up now  --

               else
                  --  We have an interp for body that matches target
                  --  Create an interp for map-reduce with that body
                  declare
                     New_MR_Interp : constant Optional_Tree :=
                       For_Loop_Construct.Replace_Body
                         (T, Resolved_Body_Interp);
                     --  Copy old sem info
                     New_MR_Sem : constant For_Loop_Construct_Sem_Ptr :=
                       new For_Loop_Construct_Semantic_Info'Class'(
                         Map_Reduce_Sem.all);
                  begin
                     --  Set new interp to have new sem info
                     Set_Sem_Info (New_MR_Interp, Root_Sem_Ptr (New_MR_Sem));
                     New_MR_Sem.Interps := null;
                     New_MR_Sem.Resolved_Type := Target_Type;
                     New_MR_Sem.Resolved_Interp := New_MR_Interp;
                     New_MR_Sem.Ambiguity :=
                       Combine_Ambiguity (Ambiguity, Body_Ambiguity);

                     --  Add to list of interps
                     Interpretations.Add_Interp
                       (Map_Reduce_Sem.Interps,
                        Associated_Type_Region => Target_Type_Region,
                        Interp => New_MR_Interp,
                        Interp_Added => Interp_Added);

                     if Types_Match (Boolean_Type, Target_Type)
                       and then
                         not Contains_Initial_Value_Operand
                           (Resolved_Body_Interp)
                     then
                        Sem_Error (New_MR_Interp,
                          "Quantified expression must start" &
                          " ""for some ..."" or ""for all ...""");
                     end if;

                  end;
               end if;
            end;
         end if;
      end Build_Map_Reduce_Expr_Interp;

      procedure Handle_Body_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Body_Interp : Optional_Tree) is
      --  For each interp of Body, build map-reduce interp
         Body_Type : constant Type_Sem_Ptr := Resolved_Type (Body_Interp);

      begin  --  Handle_Body_Interp

         if Body_Type = null then
            --  Nothing to do
            return;
         end if;

         Build_Map_Reduce_Expr_Interp (Body_Type,
           Ambiguity => Sem_Info (Body_Interp).Ambiguity);

      end Handle_Body_Interp;

      procedure Build_MR_Interps is new Interpretations.Iterate_Interps (
         Handle_Body_Interp);

   begin  --  Create_Map_Reduce_Expr_Interps

      if Debug_Second_Pass then
         Put_Line
           (" Create_Map_Reduce_Expr_Interps: target-type = " &
            Type_Image (Target_Type));
      end if;

      if Target_Type /= null then
         --  Already have target type to use
         Build_Map_Reduce_Expr_Interp (Target_Type);
      else
         Build_MR_Interps
           (Operand_Sem_Ptr (Sem_Info (T.Loop_Body)).Interps);
      end if;
   end Create_Map_Reduce_Expr_Interps;

   procedure Create_Initial_Value_Operand_Interps
     (T : Unary.Tree;
      Target_Type : Type_Sem_Ptr := null) is
      --  Create interps for initial-value operand <...>
      --  Create interps only of Target_Type if not null.

      use type Unary.Unary_Operator_Enum;
      pragma Assert (T.Operator = Unary.Initial_Value_Op);

      Initial_Val_Sem : constant Computation_Sem_Ptr :=
        Computation_Sem_Ptr (T.Sem_Info);

      Interp_Added : Boolean;

      procedure Build_Initial_Value_Interp
        (Target_Type : Type_Sem_Ptr;
         Ambiguity : Ambiguity_List := null) is
         --  Create one interp of initial-value operand of given type
         Target_Type_Region : constant Type_Region_Ptr :=
           U_Base_Type_Region (Target_Type);
      begin
         if Target_Type /= null
           and then not Interpretations.Has_Type_Region
               (Initial_Val_Sem.Interps, Target_Type_Region)
         then
            --  This type hasn't been seen yet
            declare
               Generic_Param_Map : Param_Mapping_Ptr := null;
               Resolved_Opnd_Interp : Optional_Tree;
               Opnd_Ambiguity : Ambiguity_List;
            begin
               Find_Interp_Of_Type
                 (Target_Type_Region,
                  T.Operand,
                  Target_Type,
                  Generic_Param_Map,
                  Resolved_Opnd_Interp,
                  Opnd_Ambiguity);

               if Is_Null (Resolved_Opnd_Interp) then
                  --  Remember we have tried to create an interp for this type
                  Interpretations.Add_Interp
                    (Initial_Val_Sem.Interps,
                     Associated_Type_Region => Target_Type_Region,
                     Interp => Null_Optional_Tree,
                     Interp_Added => Interp_Added);

                  return;   --  Give up now  --

               else
                  --  We have an interp for operand that matches target
                  --  Create an interp for initial-value with that operand
                  declare
                     New_IV_Interp : constant Optional_Tree :=
                       Unary.Make
                         (Unary.Initial_Value_Op, Resolved_Opnd_Interp);
                     --  Copy old sem info
                     New_IV_Sem : constant Computation_Sem_Ptr :=
                       new Computation_Semantic_Info'Class'(
                         Initial_Val_Sem.all);
                  begin
                     --  Set new interp to have new sem info
                     Set_Sem_Info (New_IV_Interp, Root_Sem_Ptr (New_IV_Sem));
                     New_IV_Sem.Interps := null;
                     New_IV_Sem.Resolved_Type := Target_Type;
                     New_IV_Sem.Resolved_Interp := New_IV_Interp;
                     New_IV_Sem.Ambiguity := Combine_Ambiguity (Ambiguity,
                       Opnd_Ambiguity);

                     --  Add to list of interps
                     Interpretations.Add_Interp
                       (Initial_Val_Sem.Interps,
                        Associated_Type_Region => Target_Type_Region,
                        Interp => New_IV_Interp,
                        Interp_Added => Interp_Added);
                  end;
               end if;
            end;
         end if;
      end Build_Initial_Value_Interp;

      procedure Handle_Opnd_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree) is
      --  For each interp of operand, build initial-value interp
         Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Opnd_Interp);

      begin  --  Handle_Opnd_Interp

         if Opnd_Type = null then
            --  Nothing to do
            return;
         end if;

         Build_Initial_Value_Interp (Opnd_Type,
           Ambiguity => Sem_Info (Opnd_Interp).Ambiguity);

      end Handle_Opnd_Interp;

      procedure Build_IV_Interps is new Interpretations.Iterate_Interps (
         Handle_Opnd_Interp);

   begin  --  Create_Initial_Value_Operand_Interps

      if Debug_Second_Pass then
         Put_Line
           (" Create_Initial_Value_Operand_Interps: target-type = " &
            Type_Image (Target_Type));
      end if;

      if Target_Type /= null then
         --  Already have target type to use
         Build_Initial_Value_Interp (Target_Type);
      else
         Build_IV_Interps
           (Operand_Sem_Ptr (Sem_Info (T.Operand)).Interps);
      end if;
   end Create_Initial_Value_Operand_Interps;

   procedure Create_Composite_Expr_Interp
     (Composite_Sem : Composite_Stmt_Sem_Ptr;
      Target_Type : Type_Sem_Ptr) is
   --  We have a conditional or quantified expression.
   --  Pass the target type through to the constituents as appropriate.
      Operand_Tree : Trees.Tree'Class renames
        Tree_Ptr_Of (Composite_Sem.Definition).all;
   begin
      if Target_Type = null
        or else Interpretations.Has_Type_Region
                       (Composite_Sem.Interps,
                        U_Base_Type_Region (Target_Type))
      then
         --  Nothing to do
         if Debug_Second_Pass then
            Put_Line (" Create_Composite_Expr_Interp: Nothing to do for " &
              Type_Image (Target_Type) & " on tree " &
              Subtree_Image (Operand_Tree));
         end if;
      elsif Operand_Tree in Conditional.Tree then
         --  "if" expression
         declare
            Cond_Tree : Conditional.Tree renames
              Conditional.Tree (Operand_Tree);
         begin
            --  Add targeted interps to then and else part
            if Debug_Second_Pass then
               Put_Line (" Create_Composite_Expr_Interp: " &
                 "adding then/else target type " &
                 Type_Image (Target_Type) & " on tree " &
                 Subtree_Image (Operand_Tree));
            end if;
            Create_Conditional_Expr_Interps (Cond_Tree, Target_Type);
         end;
      elsif Operand_Tree in Case_Construct.Tree then
         --  "case" expression
         declare
            Case_Tree : Case_Construct.Tree renames
              Case_Construct.Tree (Operand_Tree);
         begin
            Create_Case_Expr_Interps (Case_Tree, Target_Type);
         end;
      elsif Operand_Tree in For_Loop_Construct.Tree then
         --  quantified expression or map-reduce expression
         --  Nothing to do for quantified expr since always return Boolean;
         --  For map-reduce expression, we just pass type through
         declare
            Expr_Tree : For_Loop_Construct.Tree renames
              For_Loop_Construct.Tree (Operand_Tree);
            use type For_Loop_Construct.For_Loop_Kind_Enum;
         begin
            if Expr_Tree.Kind = For_Loop_Construct.Map_Reduce_Expr then
               --  Add targeted interps for map-reduce expression
               if Debug_Second_Pass then
                  Put_Line (" Create_Composite_Expr_Interp: " &
                    "adding type " &
                    Type_Image (Target_Type) & " on map-reduce tree " &
                    Subtree_Image (Operand_Tree));
               end if;
               Create_Map_Reduce_Expr_Interps (Expr_Tree, Target_Type);
            end if;
         end;
      else
         Sem_Error (Composite_Sem.Definition,
           "Internal: Unexpected Kind of Expression Tree: " &
           Ada.Tags.Expanded_Name (Operand_Tree'Tag));
      end if;
   end Create_Composite_Expr_Interp;

   procedure Insert_Return_And_Analyze
     (T : Operation.Tree) is
   --  Transform "is (X)" into "is return X" and then analyze new body.
   --  Presumes that length of T.Operation_Outputs is non-zero.
      pragma Assert (not Lists.Is_Empty (T.Operation_Outputs));

      Op_Sem : constant Operation_Sem_Ptr :=
        Operation_Sem_Ptr (Underlying_Op_Sem_Info (Sem_Ptr (T.Sem_Info)));
      Body_Copy : constant Optional_Tree :=
        Copy_Resolved_Tree (T.Statements);
      use Control_Stmt;
      New_Body : constant Optional_Tree :=
        Control_Stmt.Make
          (Kind => Return_Stmt,
           Applies_To => Control_Stmt.Operation_Body,
           Id => Null_Optional_Tree,
           Values => Body_Copy,
           Source_Pos => Find_Source_Pos (T.Statements));
      Body_Sem : constant Computation_Sem_Ptr :=
        new Computation_Semantic_Info;
   begin
      Body_Sem.Definition := T.Statements;
      --  Walk constructed "return" statement
      Second_Pass (Op_Sem.Body_Region, New_Body, Context => Statement_Context);
      Set_Sem_Info (T.Statements, Root_Sem_Ptr (Body_Sem));
      --  Set it as the interpretation of the new body
      Body_Sem.Resolved_Interp := New_Body;
   end Insert_Return_And_Analyze;

   procedure Create_Lambda_Expression_Interp
     (Resolved_Op_Sem : Resolved_Op_Ptr;
      Target_Func_Sem : Operation_Sem_Ptr;
      Diagnose : Boolean := False) is
   --  We have a lambda expression
   --  Use the target type's Op_Sem to give types to the parameters
   --  and then to resolve the result.
   --  TBD: If Diagnose is True, explain why it doesn't resolve.
      Lambda_Tree : Operation.Tree renames Operation.Tree
        (Tree_Ptr_Of (Resolved_Op_Sem.Definition).all);
      Target_Func_Tree : Operation.Tree renames Operation.Tree
        (Tree_Ptr_Of (Target_Func_Sem.Definition).all);
      Num_Inputs : constant Natural :=
        Lists.Length (Lambda_Tree.Operation_Inputs);
      Target_Type : constant Type_Sem_Ptr := Target_Func_Sem.Func_Type_Sem;
   begin
      if Debug_Second_Pass then
         Put_Line ("Create_Lambda_Expression_Interp: Lambda = " &
           Subtree_Image (Resolved_Op_Sem.Definition) & ", target type = " &
           Type_Image (Target_Type));
      end if;

      if Target_Type = null
        or else (not Diagnose
          and then Interpretations.Has_Type_Region
            (Resolved_Op_Sem.Interps,
             U_Base_Type_Region (Target_Type)))
      then
         return;
      end if;

      if Lists.Length (Target_Func_Tree.Operation_Inputs) /=
        Num_Inputs
      then
         if Debug_Second_Pass then
            Put_Line ("Create_Lambda_Expression_Interp: " &
              "Mismatch in param count");
         end if;
         return;  --  Not a match  --
      end if;

      --  Create a copy of the original lambda expression
      declare
         Lambda_Copy_OT : constant Optional_Tree :=
           Substitute_In_Tree
             (Resolved_Op_Sem.Definition,
              Assoc_Type_Region => null,
              Always_Copy_Tree => True);
         Lambda_Copy : Operation.Tree renames Operation.Tree
           (Tree_Ptr_Of (Lambda_Copy_OT).all);
         Lambda_Op_Sem : Operation_Sem_Ptr :=
           Resolved_Op_Ptr (Lambda_Copy.Sem_Info).Op_Sem;
         Interp_Added : Boolean := False;
         Enclosing_Region : constant Region_Ptr :=
           Lambda_Op_Sem.Nested_Region.Enclosing_Region;
      begin

         --  Add types to operation inputs
         for I in 1 .. Num_Inputs loop
            declare
               Nth_Lambda_Param : Param_Decl.Tree renames Param_Decl.Tree
                 (Tree_Ptr_Of (Lists.Nth_Element
                   (Lambda_Copy.Operation_Inputs, I)).all);
               Param_Sem : constant Param_Sem_Ptr :=
                 Param_Sem_Ptr (Nth_Lambda_Param.Sem_Info);
               Nth_Func_Type_Param : Param_Decl.Tree renames Param_Decl.Tree
                 (Tree_Ptr_Of (Lists.Nth_Element
                    (Target_Func_Tree.Operation_Inputs, I)).all);
            begin
               Nth_Lambda_Param.Param_Type :=
                 Nth_Func_Type_Param.Param_Type;
               Param_Sem.Resolved_Type :=
                 Resolved_Type (Nth_Lambda_Param.Param_Type);
            end;
         end loop;

         --  Copy operation outputs
         Lambda_Copy.Operation_Outputs :=
           Substitute_In_List
             (Target_Func_Tree.Operation_Outputs,
              Assoc_Type_Region => null);  --  Already substituted

         --  Rerun first pass on lambda_copy after nulling out sem info
         Lambda_Copy.Sem_Info := null;
         First_Pass (Enclosing_Region, Lambda_Copy_OT);

         --  Get new op-sem
         Lambda_Op_Sem := Operation_Sem_Ptr (Lambda_Copy.Sem_Info);

         --  Resolve inputs in new region for lambda
         Second_Pass_List
           (Operation_Sem_Ptr (Lambda_Copy.Sem_Info).Nested_Region,
            Lambda_Copy.Operation_Inputs,
            Context => Operation_Input_Context,
            Mode => Decls_And_Exprs);

         --  Resolve outputs and create a resolved_op_sem for Lambda_Copy
         Second_Pass (Enclosing_Region,
           Lambda_Copy_OT, Context => Operand_Context);

         if Lists.Is_Empty (Lambda_Copy.Operation_Outputs) then
            --  Need to walk statements inside body region
            --  since this is not done for a lambda_operation
            --  inside Operation_Action if operation_outputs is empty.
            Second_Pass
              (Lambda_Op_Sem.Body_Region,
               Lambda_Copy.Statements,
               Context => Statement_Context);
         end if;

         --  Remember resolved type of lambda
         Operand_Sem_Ptr (Sem_Info (Lambda_Copy_OT)).Resolved_Type :=
           Target_Type;

         --  Add lambda-copy to interp tree
         Interpretations.Add_Interp
           (Resolved_Op_Sem.Interps,
            Associated_Type_Region =>
              U_Base_Type_Region (Target_Type),
            Interp => Lambda_Copy_OT,
            Interp_Added => Interp_Added);

         if Debug_Second_Pass then
            Put_Line ("Create_Lambda_Expression_Interp: Resolved_Lambda: " &
              Subtree_Image (Lambda_Copy_OT));
         end if;
      end;

   end Create_Lambda_Expression_Interp;

   function Create_Func_Type_Interp
     (Opnd : Optional_Tree; Target_Func_Sem : Operation_Sem_Ptr)
     return Optional_Tree is
   --  Create interpretation for operand given Target Type's Op_Sem
      Opnd_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Opnd));
      Op_Tree : Operation.Tree renames
        Operation.Tree (Tree_Ptr_Of (Target_Func_Sem.Definition).all);
      Assoc_Type_Region : constant Type_Region_Ptr :=
        U_Base_Type_Region (Target_Func_Sem.Func_Type_Sem);
      Chosen_Assoc_Type_Region : Type_Region_Ptr;
      Ambiguity : Ambiguity_List := null;
      Chosen_Interp : Optional_Tree := Null_Optional_Tree;
   begin
      --  Add regions where to look for operation.
      Add_Param_Regions_For_Operation_Name
        (Opnd, Op_Tree.Operation_Inputs, Assoc_Type_Region);
      Add_Param_Regions_For_Operation_Name
        (Opnd, Op_Tree.Operation_Outputs, Assoc_Type_Region);

      --  Now see whether we have a match
      Find_Interp_Of_Signature
        (Opnd,
         Target_Func_Sem,
         Chosen_Interp,
         Chosen_Assoc_Type_Region,
         Ambiguity,
         Signature_Type_Region => Assoc_Type_Region,
         Require_Exact_Type_Match => True);

      if Not_Null (Chosen_Interp) then
         --  Change Sem_Info to be Resolved_Operation_Info
         declare
            Resolved_Op_Sem : constant Resolved_Op_Ptr :=
              new Resolved_Operation_Info;
            use type Operation.Operation_Kind_Enum;
         begin
            Resolved_Op_Sem.Definition := Chosen_Interp;
            Resolved_Op_Sem.Associated_Symbol :=
              Sem_Ptr (Sem_Info (Chosen_Interp)).Associated_Symbol;
            Resolved_Op_Sem.Resolved_Interp := Chosen_Interp;
            Resolved_Op_Sem.Ambiguity := Ambiguity;
            Resolved_Op_Sem.Op_Sem := Operation_Sem_Ptr
              (Underlying_Op_Sem_Info (Chosen_Interp));
            Resolved_Op_Sem.Assoc_Type_Region :=
              Chosen_Assoc_Type_Region;

            --  NOTE: Don't want to overwrite operation's own Sem_Info
            --        unless is lambda expression.
            pragma Assert (Tree_Ptr_Of (Chosen_Interp).all not in
              Operation.Tree or else
              Operation.Tree (Tree_Ptr_Of (Chosen_Interp).all).
                Operation_Kind = Operation.Lambda_Operation);

            if Debug_Second_Pass then
               Put_Line (" Creating Resolved_Operation_Info: " &
                Subtree_Image (Chosen_Interp) & ", type_region = " &
                Type_Image (Type_Sem_Ptr (Chosen_Assoc_Type_Region)));
            end if;

            Set_Sem_Info (Chosen_Interp, Root_Sem_Ptr (Resolved_Op_Sem));
         end;
      elsif Lists.Is_Empty (Op_Tree.Operation_Inputs)
        and then Lists.Length (Op_Tree.Operation_Outputs) = 1
      then
         --  We have a parameterless func type with one Output, so it might
         --  be an "implicit" lambda expression
         --  TBD
         if Debug_Second_Pass then
            Put_Line (" NYI: Implicit lambda expressions, type = " &
              Subtree_Image (Lists.Nth_Element (Op_Tree.Operation_Outputs, 1))
              & ", lambda body = " & Subtree_Image (Opnd));
         end if;
      end if;
      return Chosen_Interp;
   end Create_Func_Type_Interp;

   procedure Add_Targeted_Interps
     (Operand : Optional_Tree;
      Target_Type : Type_Sem_Ptr;
      Associated_Operation : Sym_Ptr := null) is
      --  Add interps that are declared in given type's region
      --  and return the given type.
      --  Return immediately if Target_Type has non-null Associated_Generic_Op
      --  which matches Associated_Operation.
      --  NOTE: At this stage there is no need to include
      --       operations that do not return the given type,
      --       and in fact such operations might create spurious
      --       or order-sensitive resolutions.
      Opnd_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Operand));
      Interp_Added : Boolean := False;

      use type Operation.Operation_Kind_Enum;
   begin
      if Debug_Second_Pass then
         Put_Line
           (" Adding targeted interps of type " &
            Type_Image (Target_Type));
      end if;
      if Opnd_Sem = null then
         --  Nothing we can do
         null;
      elsif Opnd_Sem.all in Call_Semantic_Info'Class
        and then not Is_Boolean_Or_Ordering (Target_Type)
        and then
          (Target_Type.Associated_Generic_Op = null
           or else Target_Type.Associated_Generic_Op /= Associated_Operation)
      then
         --  We have a call, add more interpretations if region not
         --  currently included.
         --  We explicitly exclude "Boolean" and "Ordering" as these
         --  have some operations that could be very ambiguous
         --  with any other enumeration type, and especially
         --  Univ_Enumeration.
         --  We also exclude generic types, as they are designed
         --  for bottom-up resolution only.
         declare
            Type_Region : constant Type_Region_Ptr :=
              U_Base_Type_Region (Target_Type);

            Operation_Designator : constant Optional_Tree :=
              Invocation.Tree (Tree_Ptr_Of
                (Call_Sem_Ptr (Opnd_Sem).Equiv_Invocation).all).Prefix;
            Op_Sem : constant Root_Sem_Ptr := Sem_Info (Operation_Designator);
            Op_Desig_Tree : Trees.Tree'Class
              renames Tree_Ptr_Of (Operation_Designator).all;
         begin
            if Op_Sem /= null
              and then Op_Sem.all in Operand_Semantic_Info'Class
              and then Op_Desig_Tree in Identifier.Tree
              and then Type_Region /= null
            then
               --  Add constructors for specified type-region

               Add_Operation_Interps
                 (Operand_Sem_Ptr (Op_Sem).Interps,
                  Type_Region,
                  Identifier.Tree (Op_Desig_Tree).Str,
                  Identifier.Tree (Op_Desig_Tree).Source_Pos,
                  Operation_Filter => Constructors_Only,
                  Add_Call_Interps_To =>
                    Call_Sem_Ptr (Opnd_Sem).Equiv_Invocation);
               --  Add call interps for each new operation interp

            end if;
         end;
      elsif Opnd_Sem.all in Class_Aggregate_Semantic_Info then
         --  We have a class aggregate, see whether this target type
         --  works.
         Create_Class_Agg_Interp (Class_Agg_Sem_Ptr (Opnd_Sem), Target_Type);
      elsif Opnd_Sem.all in Container_Aggregate_Semantic_Info then
         --  We have a container aggregate, see whether this target type
         --  works.
         Create_Container_Agg_Interp
           (Container_Agg_Sem_Ptr (Opnd_Sem), Target_Type);
      elsif Opnd_Sem.all in Literal_Semantic_Info
        and then Literal_Sem_Ptr (Opnd_Sem).Lit_Kind = Null_Literal
      then
         --  We have a "null" which can be any type
         Create_Null_Value_Interp (Literal_Sem_Ptr (Opnd_Sem), Target_Type);
      elsif Opnd_Sem.all in Composite_Stmt_Semantic_Info'Class then
         --  We must have a conditional or quantified expression.
         --  Pass the target type through to the constituents as appropriate.
         Create_Composite_Expr_Interp
           (Composite_Stmt_Sem_Ptr (Opnd_Sem), Target_Type);
      elsif Target_Type.Func_Type_Op_Sem /= null then
         --  Target type is a func type
         if Opnd_Sem.all in Resolved_Operation_Info
           and then Resolved_Op_Ptr
             (Opnd_Sem).Op_Sem.Operation_Kind = Operation.Lambda_Operation
         then
            --  We have a lambda expression
            Create_Lambda_Expression_Interp
              (Resolved_Op_Ptr (Opnd_Sem), Target_Type.Func_Type_Op_Sem);
         elsif Opnd_Sem.all in Operand_Semantic_Info'Class then
            --  Some other sort of expression, might
            --  be an operation designator, or an "implicit" lambda
            --  if the func-type is parameterless.
            declare
               Func_Interp : constant Optional_Tree :=
                 Create_Func_Type_Interp
                   (Operand, Target_Type.Func_Type_Op_Sem);
            begin
               Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp := Func_Interp;
               if Not_Null (Func_Interp) then
                  --  Set target type on Opnd_Sem and Func_Interp's sem-info
                  Operand_Sem_Ptr (Opnd_Sem).Resolved_Type := Target_Type;
                  Operand_Sem_Ptr (Sem_Info (Func_Interp)).Resolved_Type :=
                    Target_Type;
                  --  Null out other interps
                  Operand_Sem_Ptr (Opnd_Sem).Interps := null;
               end if;
            end;
         end if;
      elsif Opnd_Sem.all in Computation_Semantic_Info'Class
        and then Tree_Ptr_Of (Opnd_Sem.Definition).all in Unary.Tree
      then
         --  A unary operator; might be Initial_Value_Op
         declare
            Unary_Tree : Unary.Tree renames Unary.Tree
              (Tree_Ptr_Of (Opnd_Sem.Definition).all);
            use type Unary.Unary_Operator_Enum;
         begin
            if Unary_Tree.Operator = Unary.Initial_Value_Op then
               --  Pass through the target type
               Create_Initial_Value_Operand_Interps (Unary_Tree, Target_Type);
            end if;
         end;
      end if;
   end Add_Targeted_Interps;

   function Interps_Equivalent
     (Interp1, Interp2 : Optional_Tree)
      return Boolean
   is
      --  Return True if two interps are equivalent because
      --  one is defined in terms of the other, or both are
      --  defined in terms of the same operation, using "is X"
      --  or "is in T".
      Sem1 : constant Sem_Ptr := Underlying_Sem_Info (Interp1);
      Sem2 : constant Sem_Ptr := Underlying_Sem_Info (Interp2);
   begin
      if Interp1 = Interp2 or else Sem1 = Sem2 then
         --  Same interpretation or same semantic info
         return True;
      elsif Sem1 = null or else Sem2 = null then
         return False;
      elsif Sem1.all in Operation_Semantic_Info
        and then Sem2.all in Operation_Semantic_Info
      then
         --  Check for equivalence of operation names
         --  TBD: Do we need to check Assoc_Type_Region vs. Equiv_From_Type?
         declare
            Op_Sem1 : Operation_Sem_Ptr := Operation_Sem_Ptr (Sem1);
            Op_Sem2 : Operation_Sem_Ptr := Operation_Sem_Ptr (Sem2);
            Result : Boolean;
         begin
            while Op_Sem1.Equiv_To /= null loop
               Op_Sem1 := Op_Sem1.Equiv_To;
            end loop;
            while Op_Sem2.Equiv_To /= null loop
               Op_Sem2 := Op_Sem2.Equiv_To;
            end loop;
            Result := (Op_Sem1 = Op_Sem2);
            if not Result then
               if Debug_Second_Pass then
                  Put_Line (" Operations are not renames of one another:");
                  Put_Line ("   " & Subtree_Image (Op_Sem1.Definition,
                    Use_Short_Form => True));
                  Put_Line ("   " & Subtree_Image (Op_Sem2.Definition,
                    Use_Short_Form => True));
               end if;
            end if;
            return Result;
         end;
      elsif Sem1.all in Selection_Semantic_Info
        and then Sem2.all in Selection_Semantic_Info
        and then Tree_Ptr_Of (Sem1.Definition).all in Selection.Tree
        and then Tree_Ptr_Of (Sem2.Definition).all in Selection.Tree
      then
         --  Check for equivalence of selections
         declare
            Sel_Sem1 : constant Selection_Sem_Ptr := Selection_Sem_Ptr (Sem1);
            Sel_Sem2 : constant Selection_Sem_Ptr := Selection_Sem_Ptr (Sem2);
            Prefix1 : constant Optional_Tree := Selection.Tree
              (Tree_Ptr_Of (Sem1.Definition).all).Prefix;
            Prefix2 : constant Optional_Tree := Selection.Tree
              (Tree_Ptr_Of (Sem2.Definition).all).Prefix;
            Result : Boolean;
         begin
            Result := Sel_Sem1.Comp_Decl = Sel_Sem2.Comp_Decl
             and then
               Interps_Equivalent (Prefix1, Prefix2);

            if Debug_Second_Pass and then not Result then
               Put_Line (" Selections not equivalent:");
               Put_Line ("   " & Subtree_Image (Sel_Sem1.Definition,
                 Use_Short_Form => True));
               Put_Line ("   " & Subtree_Image (Sel_Sem2.Definition,
                 Use_Short_Form => True));
            end if;
            return Result;
         end;
      elsif Sem1.all not in Call_Semantic_Info
        or else Sem2.all not in Call_Semantic_Info
        or else Tree_Ptr_Of (Sem1.Definition).all not in Invocation.Tree
        or else Tree_Ptr_Of (Sem2.Definition).all not in Invocation.Tree
      then
         --  We only do this for calls, operation names, and selections
         if Debug_Second_Pass then
            Put_Line (" Interps not a call, name, or sel --> not equivalent:");
            Put_Line ("  " & Subtree_Image (Interp1, Use_Short_Form => True));
            Put_Line ("  " & Subtree_Image (Interp2, Use_Short_Form => True));
         end if;
         return False;
      else
         declare
            Call_Sem1 : constant Call_Sem_Ptr := Call_Sem_Ptr (Sem1);
            Call_Sem2 : constant Call_Sem_Ptr := Call_Sem_Ptr (Sem2);
            Invoc_Tree1 : Invocation.Tree
              renames Invocation.Tree (Tree_Ptr_Of (Call_Sem1.Definition).all);
            Invoc_Tree2 : Invocation.Tree
              renames Invocation.Tree (Tree_Ptr_Of (Call_Sem2.Definition).all);
         begin
            if Call_Sem1.Resolved_Type = null
              or else Call_Sem2.Resolved_Type = null
            then
               if Call_Sem1.Resolved_Type /= Call_Sem2.Resolved_Type then
                  --  Both must be null if either is
                  return False;
               end if;
            elsif Call_Sem1.Resolved_Type.U_Base_Type /=
                  Call_Sem2.Resolved_Type.U_Base_Type
            then
               if Debug_Second_Pass then
                  Put_Line (" Calls not equivalent due to type mismatch:");
                  Put_Line ("  " &
                    Type_Image (Call_Sem1.Resolved_Type.U_Base_Type) & " /= " &
                    Type_Image (Call_Sem2.Resolved_Type.U_Base_Type));
               end if;
               return False;
            end if;

            --  Recurse on operations
            return Interps_Equivalent
                     (Invoc_Tree1.Prefix,
                      Invoc_Tree2.Prefix);
         end;
      end if;
   end Interps_Equivalent;

   function Op_Map_Type_Desc_Index
      (Obj_Type : Type_Sem_Ptr;
       Formal_Type : Type_Sem_Ptr;
       Source_Pos : Source_Positions.Source_Position)
      return Type_Sem_Vectors.Elem_Index
   --  Return index for Op-Map for Obj_Type viewed as Formal_Type
   is
      Existing_Op_Map_Ref : Type_Sem_Index_Tables.Element_Ref :=
        Find_Element (Obj_Type.U_Base_Type.Op_Maps_Needed,
          Formal_Type.Associated_Module.Cur_Inst_Sem);
      Result_Index : Type_Sem_Vectors.Elem_Index := 0;
      use type Type_Sem_Index_Tables.Element_Ref;
   begin
      if Existing_Op_Map_Ref /= null then
         --  Already assigned an index
         return Existing_Op_Map_Ref.all;
      elsif Obj_Type.All_Parameters_Known then
         --  Need to build the op map.
         declare
            Op_Map_Type_Desc : constant Interpreter.Type_Descriptor_Ptr :=
              Dynamic.Build_Type_Op_Map (Obj_Type, Formal_Type, Source_Pos);

            use Interpreter;
         begin
            if Op_Map_Type_Desc /= null then
               --  New op-map built
               Result_Index := Type_Sem_Vectors.Elem_Index
                 (Op_Map_Type_Desc.Index);
            else
               --  No op-map needed, just reuse "normal" type-desc index of
               --  Obj_Type (should be "absolute").
               pragma Assert
                 (Obj_Type.U_Base_Type.Type_Descriptor_Location.Base =
                  Zero_Base);
               Result_Index := Type_Sem_Vectors.Elem_Index
                 (Obj_Type.U_Base_Type.Type_Descriptor_Location.Offset);
            end if;
         end;
      else
         --  Need to assign a new nested-type index and
         --  fill in the target type for the new addition to the nested-type
         --  table.
         declare
            Defining_Module : constant Module_Sem_Ptr :=
              Obj_Type.Outermost_Module_Where_Used;
            Existing_Target_Type_Ref : Type_Sem_Target_Tables.Element_Ref;
            use type Type_Sem_Target_Tables.Element_Ref;
         begin
            Add_Element (Defining_Module.Nested_Types,
              Obj_Type.U_Base_Type, Result_Index);

            Enter_Element (Defining_Module.Nested_Type_Op_Map_Target,
              Result_Index, Formal_Type.U_Base_Type, Existing_Target_Type_Ref);

            --  Should not already be there
            pragma Assert (Existing_Target_Type_Ref = null);
         end;
      end if;

      --  Now enter assigned index into obj-type's table
      Enter_Element (Obj_Type.U_Base_Type.Op_Maps_Needed,
        Formal_Type.Associated_Module.Cur_Inst_Sem,
        Result_Index, Existing_Op_Map_Ref);

      --  Should not already be there
      pragma Assert (Existing_Op_Map_Ref = null);

      return Result_Index;
   end Op_Map_Type_Desc_Index;

   function Type_Implements_Type
     (Actual_Type : Type_Sem_Ptr;
      Formal_Type : Type_Sem_Ptr;
      Check_Parameterless_Modules : Boolean := False;
      Allow_Abstract : Boolean := False;
      No_Implementing_Ops : Boolean := False)
      return Boolean
   is
   --  Return True if Actual_Type is acceptable as a parameter
   --  for the given Formal_Type.
   --  If Formal_Type is from a parameterless module, then
   --  check to be sure Actual_Type has all of the necessary
   --  operations only if Check_Parameterless_Modules is True
   --  If No_Implementing_Ops is True, then ignore operations from
   --  the "implements for" section.

      --  Actual type is "OK" if we allow abstract types,
      --  or type is a "current instance" (which are never abstract)
      --  or type is not abstract/partially-abstract.

      Abstract_Ops_OK : constant Boolean :=
        Allow_Abstract
          or else Actual_Type.Is_Formal_Type
          or else Actual_Type.Is_Polymorphic;

      Actual_Type_OK : constant Boolean :=
         Abstract_Ops_OK
           or else (Actual_Type.Associated_Module /= null
             and then not Actual_Type.Associated_Module.Is_Abstract
             and then not Actual_Type.Associated_Module.Is_Partially_Abstract);
   begin
      if Debug_Second_Pass then
         Put_Line ("Checking whether " & Type_Image (Actual_Type) &
           " implements " & Type_Image (Formal_Type));
      end if;

      if Actual_Type = Formal_Type
        or else (Actual_Type.U_Base_Type = Formal_Type.U_Base_Type
                and then Actual_Type.U_Base_Type /= null)
      then
         --  Exact match
         return True;
      elsif Actual_Type.Associated_Module = null
        or else Formal_Type.Associated_Module = null
      then
         --  Actual or Formal doesn't have module filled in;
         --  Assume it does implement the type for now.
         --  TBD: Is this a good idea?
         if Debug_Second_Pass then
            Put_Line (" Actual or formal has null module??");
         end if;
         return True;
      elsif Actual_Type.Associated_Module =
            Formal_Type.Associated_Module
      then
         --  Correct module; OK so long as not [partially] abstract.
         --  TBD: Check if there are further requirements buried in
         --      actuals of formal type
         if Debug_Second_Pass then
            Put_Line (" Actual and formal have same module," &
              " TBD: check formals");
         end if;
         return Actual_Type_OK;
      elsif Actual_Type.Parent_Type /= null
        and then Type_Implements_Type
                    (Actual_Type => Actual_Type.Parent_Type,
                     Formal_Type => Formal_Type,
                     Check_Parameterless_Modules =>
                       Check_Parameterless_Modules,
                     Allow_Abstract => True)
      then
         --  Parent implements the Formal_Type
         --  TBD: Partially abstract is OK so long as needed operations
         --       are not abstract.
         if Debug_Second_Pass then
            Put_Line (" Type_Implements_Type: parent " &
              Type_Image (Actual_Type.Parent_Type) &
              " implements formal");
         end if;
         return Actual_Type_OK;
      else
         --  See whether module appears in tree of implemented interfaces
         declare
            Actual_Module_Tree : Module.Tree
              renames Module.Tree (Tree_Ptr_Of
                (Actual_Type.Associated_Module.Definition).all);
            Implemented_Interfaces : Lists.List renames
              Actual_Module_Tree.Implements_Interfaces;
         begin
            for I in 1 .. Lists.Length (Implemented_Interfaces) loop
               declare
                  Implemented_Type : constant Type_Sem_Ptr :=
                    Get_Type
                      (Actual_Type.Associated_Module.
                         Nested_Region.Enclosing_Region,
                       (Lists.Nth_Element (Implemented_Interfaces, I)));
               --  TBD: Substitute into the Implemented_Type
               begin
                  --  Recurse to check whether implemented type meets the needs
                  if Type_Implements_Type
                       (Actual_Type => Implemented_Type,
                        Formal_Type => Formal_Type,
                        Check_Parameterless_Modules =>
                          Check_Parameterless_Modules,
                        Allow_Abstract => True)
                  then
                     --  Found a type that meets the needs
                     --  TBD: If Formal_Type has actuals, check those too
                     --  TBD: Partially abstract is OK so long as needed
                     --       operations are not abstract.
                     if Debug_Second_Pass then
                        Put_Line (" Type_Implements_Type: progenitor " &
                          Type_Image (Implemented_Type) &
                          " implements formal");
                     end if;
                     return Actual_Type_OK;
                  end if;
               end;
            end loop;

            --  Doesn't explicitly implement the type
            if Num_Module_Parameters
              (Formal_Type.Associated_Module) > 0
            then
               if Debug_Second_Pass then
                  Put_Line (" Formal is parameterized and actual " &
                    "does NOT explicitly implement it");
               end if;
               return False;
            end if;

            --  We allow "ad hoc" matching for parameterless interfaces
            if Check_Parameterless_Modules then
               --  But we should check it now
               declare
                  Formal_Type_Region : constant Region_Ptr :=
                    Formal_Type.Associated_Module.Nested_Region;
                  Actual_Type_Region : constant Region_Ptr :=
                    Actual_Type.Associated_Module.Nested_Region;
                  Num_Ops_In_Formal : Natural := 0;
               begin
                  if Debug_Second_Pass then
                     Put_Line (" Checking for needed ops in " &
                       Type_Image (Actual_Type));
                  end if;
                  --  Go through module region and see if has needed ops
                  for I in 1 ..
                    Symbols.Num_Symbols (Formal_Type_Region.Syms.Local_Symbols)
                  loop
                     declare
                        Formal_Op_Sym : constant Symbols.Sym_Ptr :=
                          Symbols.Nth_Symbol
                             (Formal_Type_Region.Syms.Local_Symbols,
                              I);
                     begin
                        if Formal_Op_Sym.Sem_Info /= null
                          and then Formal_Op_Sym.Sem_Info.all in
                             Operation_Semantic_Info
                        then
                           --  We have an operation, see whether it is
                           --  declaring a visible operation
                           declare
                              Formal_Op_Sem : constant Operation_Sem_Ptr :=
                                Operation_Sem_Ptr (Formal_Op_Sym.Sem_Info);
                              use type Interpreter.Operation_Index;
                           begin
                              if Formal_Op_Sem.Index > 0
                                and then Formal_Op_Sem.Context in
                                   Any_Interface_Item_Contexts
                                and then Formal_Op_Sem.Overridden_By = null
                                and then (Formal_Op_Sem.Equiv_To = null
                                  or else
                                    Formal_Op_Sem.Equiv_To.Is_Abstract)
                              then
                                 --  We have an interface operation
                                 --  Look for corresponding operation in actual
                                 --  type
                                 declare
                                    Actual_Op : Symbols.Sym_Ptr :=
                                      Symbols.Lookup_In_Region
                                         (Actual_Type_Region,
                                          Formal_Op_Sym.Str);
                                 begin
                                    Num_Ops_In_Formal := Num_Ops_In_Formal + 1;
                                    while Actual_Op /= null
                                      and then (Actual_Op.Sem_Info.all not in
                                         Operation_Semantic_Info
                                               or else
                                         Operation_Sem_Ptr
                                           (Actual_Op.Sem_Info).Context
                                             not in Any_Interface_Item_Contexts
                                               or else Operation_Sem_Ptr (
                                         Actual_Op.Sem_Info).Overridden_By /=
                                                       null
                                               or else not
                                                   Signatures_And_Modes_Match
                                                     (Operation_Sem_Ptr (
                                                        Actual_Op.Sem_Info),
                                                      Formal_Op_Sem,
                                                      Extra_Subst1 =>
                                                        Actual_Type.
                                                          U_Base_Type,
                                                      Extra_Subst2 =>
                                                        Formal_Type.
                                                          U_Base_Type,
                                                      Substitute_Using1 =>
                                                         U_Base_Type_Region
                                                           (Actual_Type),
                                                      Substitute_Using2 =>
                                                         U_Base_Type_Region
                                                           (Formal_Type)))
                                    loop
                                       --  Keep looking for op that matches

                                       Actual_Op :=
                                          Symbols.Next_Homonym_In_Region
                                            (Actual_Op);
                                    end loop;

                                    if Actual_Op = null then
                                       if Debug_Second_Pass then
                                          Put_Line ("No op found matching " &
                                            Subtree_Image
                                              (Formal_Op_Sem.Definition,
                                               Use_Short_Form => True));
                                       end if;
                                       return False;
                                    end if;
                                    --  Found it!
                                    if not Abstract_Ops_OK then
                                       --  Check whether is abstract
                                       if Operation_Sem_Ptr
                                         (Actual_Op.Sem_Info).Is_Abstract
                                       then
                                          if Debug_Second_Pass then
                                             Put_Line ("Op matching " &
                                               Subtree_Image
                                                 (Formal_Op_Sem.Definition,
                                                  Use_Short_Form => True) &
                                               " is abstract");
                                          end if;
                                          return False;
                                       end if;
                                    end if;

                                    if No_Implementing_Ops then
                                       --  Check that the operation is not in
                                       --  the "implements for" section
                                       if Operation_Sem_Ptr
                                         (Actual_Op.Sem_Info).Context =
                                           Ancestor_Implements_Item_Context
                                         or else
                                           Operation_Sem_Ptr
                                            (Actual_Op.Sem_Info).Context =
                                              Interface_Implements_Item_Context
                                       then
                                          if Debug_Second_Pass then
                                             Put_Line ("Op matching " &
                                               Subtree_Image
                                                 (Formal_Op_Sem.Definition,
                                                  Use_Short_Form => True) &
                                               " from ""implements for"" " &
                                               "section");
                                          end if;
                                          return False;
                                       end if;
                                    end if;

                                    if Debug_Second_Pass then
                                       Put_Line ("Found op matching " &
                                         Subtree_Image
                                           (Formal_Op_Sem.Definition,
                                            Use_Short_Form => True));
                                    end if;
                                    --  Now look for next formal operation.
                                 end;
                              end if;  --  Formal_Op_Sym is an interface
                                       --  operation
                           end;
                        end if; --  Formal_Op_Sym is an operation
                     end;
                  end loop;

                  if Num_Ops_In_Formal = 0
                    and then (Any_Type = null
                              or else Formal_Type.Associated_Module /=
                                Any_Type.Associated_Module)
                    and then (Assignable_Type = null
                              or else Formal_Type.Associated_Module /=
                                Assignable_Type.Associated_Module)
                  then
                     --  A type cannot be implicitly "implemented" unless
                     --  it has at least one operation.
                     --  "Any<>" and "Assignable<>" are exceptions to this.
                     if Debug_Second_Pass then
                        Put_Line (" Formal type " & Type_Image (Formal_Type) &
                          " has no operations, so requires an explicit" &
                          " implements clause, which is NOT provided by " &
                          Type_Image (Actual_Type));
                     end if;
                     return False;
                  end if;

                  --  Has all the needed operations to implement the formal
                  --  type
                  if Debug_Second_Pass then
                     Put_Line (" Formal type " & Type_Image (Formal_Type) &
                       " has" & Natural'Image (Num_Ops_In_Formal) &
                       " ops all of which were provided by " &
                       Type_Image (Actual_Type));
                  end if;
               end;
            end if;
            if Debug_Second_Pass then
               Put_Line ("Type_Implements_Type: " & Type_Image (Actual_Type) &
                 " does implement " & Type_Image (Formal_Type));
               if not Check_Parameterless_Modules then
                  Put_Line (" (without checking for all needed operations)");
               end if;
            end if;
            return True;
         end;
      end if;
   end Type_Implements_Type;

   function Generic_Param_Matches
     (Generic_Param_Type : Type_Sem_Ptr;
      Opnd_Type : Type_Sem_Ptr;
      Generic_Param_Map : access Param_Mapping_Ptr;
      Associated_Operation : Sym_Ptr)
      return Boolean
   is
      --  Return True if Opnd_Type matches Generic_Param_Type.
      --  Update Generic_Param_Map with the binding for the
      --  "generic" type.
      pragma Assert
        (Generic_Param_Type.Associated_Generic_Op = Associated_Operation);
      Param_Type_Tree : Trees.Tree'Class renames
        Tree_Ptr_Of (Generic_Param_Type.Definition).all;
      Opnd_Type_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                   (Opnd_Type.Definition).all;
      Result : Boolean;
      Involves_Generic_Match : Boolean := False;

      No_Implementing_Ops : constant Boolean :=
          Generic_Param_Type.Associated_Module /= Opnd_Type.Associated_Module
        and then
          Associated_Operation.Enclosing_Region =
            Opnd_Type.Associated_Module.Nested_Region;
      --  Don't allow a type to match its own operations via generic matching,
      --  unless the generic type is based on the same module (e.g. matrix
      --  can match a generic matrix<...> type), but Univ_String can't
      --  match Imageable for Univ_String's own operations such as "|".

      function Opnd_Type_To_Use return Type_Sem_Ptr is
      --  Return Opnd_Type but with Is_Formal_Type removed
      --  and optionally substituted with Generic_Param_Type actuals.
      --  TBD: Not clear we need this routine
      begin
         if not Opnd_Type.Is_Formal_Type then
            --  Opnd type should be usable as is
            return Opnd_Type;
         elsif All_Nulls (Opnd_Type.Actual_Sem_Infos)
           and then not All_Nulls (Generic_Param_Type.Actual_Sem_Infos)
         then
            --  Opnd_Type is a formal type, and Generic_Param_Type
            --  has more actual-param info, so use that,
            --  after turning off Is_Formal_Type and Associated_Generic_Op
            declare
               Gen_Copy : constant Optional_Tree :=
                 Copy_Resolved_Tree (Generic_Param_Type.Definition);
            begin
               Set_Type_Sem_Info
                 (T => Invocation.Tree (Tree_Ptr_Of (Gen_Copy).all),
                  Module_Sem => Generic_Param_Type.Associated_Module,
                  Decl_Region => null,
                  Is_Formal_Type => False,  --  TBD: Is this right?
                  Enclosing_Type => Generic_Param_Type.Enclosing_Type,
                  Formal_Prefix => Null_Optional_Tree,
                  Associated_Generic_Op => null,
                  Actual_Sem_Infos => Generic_Param_Type.Actual_Sem_Infos);
               return Type_Sem_Ptr (Sem_Info (Gen_Copy));
            end;
         else
            --  Use (formal) Opnd_Type as is
            return Opnd_Type;
         end if;
      end Opnd_Type_To_Use;

   begin  --  Generic_Param_Matches

      if Debug_Second_Pass then
         Put
           ("Generic_Param_Matches: Generic_Param_Type = " &
            Type_Image (Generic_Param_Type) &
            ", Opnd_Type = " &
            Type_Image (Opnd_Type));
         if Generic_Param_Map.all /= null then
            Put (", Param_Map = " & Param_Map_Image (Generic_Param_Map.all));
         end if;
         if Associated_Operation /= null then
            Put (", Assoc_Op = " & Sym_Name (Associated_Operation));
         end if;
         New_Line;
      end if;

      if Param_Type_Tree in Type_Decl.Tree
        or else Generic_Param_Type.Is_Formal_Type
        or else Not_Null (Generic_Param_Type.Formal_Prefix)
      then
         --  We have found the "generic" part
         if Type_Implements_Type
              (Actual_Type => Opnd_Type,
               Formal_Type => Generic_Param_Type,
               Check_Parameterless_Modules => True,
               No_Implementing_Ops => No_Implementing_Ops)
         then
            --  Opnd_Type is acceptable
            --  Add it to the generic-param map
            Involves_Generic_Match := True;
            Result := True;
         else
            --  Not acceptable
            Result := False;
         end if;
      elsif Generic_Param_Type.Associated_Module /=
            Opnd_Type.Associated_Module
      then
         --  Modules don't match
         Result := False;
      else
         --  Modules match, check the module parameters
         declare
            Opnd_Type_Actuals : constant Sem_Info_Array_Ptr :=
              Opnd_Type.Actual_Sem_Infos;
            Param_Type_Actuals : constant Sem_Info_Array_Ptr :=
              Generic_Param_Type.Actual_Sem_Infos;
         begin
            if Opnd_Type_Actuals = null
              or else Param_Type_Actuals = null
              or else Opnd_Type_Actuals'Length /= Param_Type_Actuals'Length
            then
               --  Actuals not same length.
               --  TBD: This should probably be an internal error.
               Result := False;
            else
               --  Presume we have a match unless proven otherwise
               Result := True;
               for I in Opnd_Type_Actuals'Range loop
                  declare
                     Param_Actual : constant Sem_Ptr :=
                       Param_Type_Actuals (I);
                     Opnd_Actual : constant Sem_Ptr := Opnd_Type_Actuals (I);
                     use type Ada.Tags.Tag;
                  begin
                     if Param_Actual = null or else Opnd_Actual = null then
                        Result := False;
                        exit; ------ quit the loop ------
                     elsif Param_Actual'Tag /= Opnd_Actual'Tag then
                        --  Not even same kind of thing
                        if Debug_Second_Pass then
                           Put_Line
                             ("Generic_Param_Matches: " &
                              "Tag mismatch in type parameters: " &
                              Ada.Tags.Expanded_Name (Param_Actual'Tag) &
                              " /= " &
                              Ada.Tags.Expanded_Name (Opnd_Actual'Tag));
                        end if;
                        if Param_Actual.all in Call_Semantic_Info'Class
                          and then Opnd_Actual.all in Operand_Semantic_Info'
                             Class
                        then
                           --  One is a call, and the other is an object.
                           --  Presume they might match, and keep checking.
                           --  TBD: We need to check the match somewhere!
                           Involves_Generic_Match :=
                             Generic_Param_Type.Formal_Prefix /=
                             Null_Optional_Tree;
                        --  Check the next operand
                        else
                           Result := False;
                           exit; ------ quit the loop ------
                        end if;
                     elsif Param_Actual.all in Type_Semantic_Info then
                        --  We have a type parameter
                        if Types_Match
                             (Type_Sem_Ptr (Param_Actual),
                              Type_Sem_Ptr (Opnd_Actual))
                        then
                           --  This actual matches
                           null;
                        elsif Type_Sem_Ptr (Param_Actual).
                             Associated_Generic_Op /=
                              Associated_Operation
                        then
                           --  Not a generic type
                           Result := False;
                           exit; ------ quit the loop ------
                        elsif not Generic_Param_Matches
                                    (Generic_Param_Type =>
                                       Type_Sem_Ptr (Param_Actual),
                                     Opnd_Type => Type_Sem_Ptr (Opnd_Actual),
                                     Generic_Param_Map => Generic_Param_Map,
                                     Associated_Operation =>
                                       Associated_Operation)
                        then
                           --  Generic type mismatch
                           Result := False;
                           exit; ------ quit the loop ------
                        end if;
                     --  This one matches; check the next operand
                     elsif not Equiv_Tree
                                 (Param_Actual.Definition,
                                  Opnd_Actual.Definition)
                     then
                        --  Some other kind of parameter, and they don't match
                        Result := False;
                        exit; ------ quit the loop ------
                     end if;
                  end;
               end loop;
            end if;
         end;
      end if;

      if Result = True and then Involves_Generic_Match then
         Generic_Param_Map.all :=
           new Param_Mapping'
           (From => Sem_Ptr (Generic_Param_Type.U_Base_Type),
            To => Sem_Ptr (Opnd_Type_To_Use),
            Next => Generic_Param_Map.all);
      end if;

      if Debug_Second_Pass then
         Put_Line
           ("Generic_Param_Matches: returns " & Boolean'Image (Result));
      end if;

      return Result;
   end Generic_Param_Matches;

   function Copy_Resolved_Tree
     (Orig_Tree : Optional_Tree)
      return Optional_Tree
   is
   --  Make a one-level copy of given tree, along with
   --  a copy of sem info, so can be updated
   begin
      --  Just pass the buck to Substitute_In_Tree
      return Substitute_In_Tree
               (Orig_Tree,
                Assoc_Type_Region => null,
                Always_Copy_One_Level => True);
   end Copy_Resolved_Tree;

   procedure Report_Ambiguity
     (Opnd_Interp : Optional_Tree) is
   --  Report ambiguous interpretation
      Opnd_Sem : constant Sem_Ptr := Underlying_Sem_Info (Opnd_Interp);
      function Type_Of_Interp return String is
      --  return " of type ..." if Opnd_Sem has a resolved type
      begin
         if Opnd_Sem.all in Operand_Semantic_Info'Class
           and then Operand_Sem_Ptr (Opnd_Sem).Resolved_Type /= null
         then
            return " of type " &
              Type_Image (Operand_Sem_Ptr (Opnd_Sem).Resolved_Type);
         else
            return "";
         end if;
      end Type_Of_Interp;
   begin
      if Opnd_Sem.all in Call_Semantic_Info then
         declare
            Op_Sem : constant Operation_Sem_Ptr :=
              Call_Sem_Ptr (Opnd_Sem).Op_Sem;
         begin
            Messages.Put_Message
              ("ambiguous call, one target at " &
               Source_Positions.Image (Find_Source_Pos (Op_Sem.Definition)) &
               " is " &
               Subtree_Image (Op_Sem.Definition, Use_Short_Form => True,
                 Max_Chars => 100),
               Src_Pos => Find_Source_Pos (Opnd_Interp),
               Message_Kind => "Info");
         end;
      else
         --  Produce fall-back message
         Messages.Put_Message
           ("ambiguous construct" & Type_Of_Interp & ": " &
            Subtree_Image (Opnd_Interp,
              Use_Short_Form => True, Max_Chars => 100),
            Src_Pos => Find_Source_Pos (Opnd_Interp),
            Message_Kind => "Info");
      end if;
      if Debug_Second_Pass then
         Put_Line ("  Tree of ambiguous construct:");
         Dump_Resolved_Tree (Opnd_Interp, Indent => 4);
      end if;
   end Report_Ambiguity;

   function Is_Var_Indexing_Interp (Interp : Optional_Tree) return Boolean is
   --  Return True if Interp represents a call on "var_indexing"
      Interp_Sem : constant Sem_Ptr := Sem_Ptr (Underlying_Sem_Info (Interp));
   begin
      if Interp_Sem = null
        or else Interp_Sem.all not in Call_Semantic_Info'Class
      then
         --  Cannot be a "var_indexing" call
         return False;
      else
         declare
            Op_Sem : constant Operation_Sem_Ptr :=
              Call_Sem_Ptr (Interp_Sem).Op_Sem;
         begin
            if Op_Sem = null or else Op_Sem.Associated_Symbol = null then
               return False;
            else
               --  Check if operator symbol matches "var_indexing" or "ref"
               return Op_Sem.Associated_Symbol.Str = Var_Indexing_Op_Str
                 or else Op_Sem.Associated_Symbol.Str = Ref_Op_Str;
            end if;
         end;
      end if;
   end Is_Var_Indexing_Interp;

   function Compare_Interps
     (Prior_Interp : Optional_Tree;
      Prior_Is_Call_On_Generic : Boolean;
      New_Interp : Optional_Tree;
      New_Is_Call_On_Generic : Boolean;
      Formal_Is_Var : Boolean)
     return Interp_Comparison_Enum is
   --  Return indication of whether to prefer the prior or new interp,
   --  or whether the two interps are exactly equivalent,
   --  or whether they are to be treated as ambiguous.
   begin
      if Is_Null (Prior_Interp) then
         --  There was no prior interpretation
         return Prefer_New;
      elsif Is_Null (New_Interp) then
         --  This new interpretation is not of interest
         return Prefer_Prior;
      elsif Prior_Is_Call_On_Generic /= New_Is_Call_On_Generic then
         --  Prefer a non-generic match over a generic match
         if Prior_Is_Call_On_Generic then
            return Prefer_New;
         else
            return Prefer_Prior;
         end if;
      elsif Interps_Equivalent (Prior_Interp, New_Interp) then
         return Interps_Are_Equiv;
      elsif Is_Var_Indexing_Interp (Prior_Interp) /=
        Is_Var_Indexing_Interp (New_Interp)
      then
         if Debug_Second_Pass then
            Put_Line (" Compare_Interps, Prior: " &
              Subtree_Image (Prior_Interp) & ", New: " &
              Subtree_Image (New_Interp));
         end if;
         --  Prefer "var_indexing" to "indexing" based on Formal_Is_Var
         if Is_Var_Indexing_Interp (Prior_Interp) = Formal_Is_Var then
            if Debug_Second_Pass then
               Put_Line ("  Prefer prior");
            end if;
            return Prefer_Prior;
         else
            if Debug_Second_Pass then
               Put_Line ("  Prefer new");
            end if;
            return Prefer_New;
         end if;
      else
         --  TBD: Might apply other preference rules here
         return Interps_Are_Ambig;
      end if;
   end Compare_Interps;

   procedure Find_Interp_Of_Type
     (Assoc_Type_Region : Type_Region_Ptr;
      Opnd : Optional_Tree;
      Param_Type : Type_Sem_Ptr;
      Generic_Param_Map : in out Param_Mapping_Ptr;
      Chosen_Interp : out Optional_Tree;
      Ambiguity : out Ambiguity_List;
      Associated_Operation : Sym_Ptr := null;
      Formal_Is_Var : Boolean := False;
      Diagnose : Boolean := False) is
      --  Walk interp tree of Opnd and find one that
      --  matches given Param_Type.  If Param_Type is null,
      --  then return first Interp.
      --  Update Generic_Param_Map with additional mappings if
      --  Param type is a "generic" type.
      --  If Associated_Operation is non-null, then use that
      --  for the matching of generic parameters.
      --  Set Chosen_Interp to Null_Optional_Tree if no matching interp.
      --  Set Ambiguity if multiple interps.
      --  If Formal_Is_Var is true, then prefer var_indexing to indexing.
      --  If Diagnose is True, then produce messages indicating why
      --  expression does not resolve.

      Result : Optional_Tree := Null_Optional_Tree;
      Ambiguity_Reported : Boolean := False;

      procedure Add_Ambiguity (Opnd_Interp : Optional_Tree);
      --  Add Opnd_Interp to list of ambiguities.
      --  Init Ambiguity to "Result" if currently null.

      --  Indicates whether current result is a call on a generic operation.
      --  If so, we ignore it if we find other interpretations which
      --  are *not* a call on a generic.
      Result_Is_Call_On_Generic : Boolean := False;

      Found_Univ_Interp : Boolean := False;
      Try_Conv_To_Univ : Boolean := False;
      Found_Place_To_Call_Ref : Boolean := False;

      Opnd_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Opnd));

      procedure Add_Ambiguity (Opnd_Interp : Optional_Tree) is
      --  Add Opnd_Interp to list of ambiguities.
      --  Init Ambiguity to "Result" if currently null.
      begin
         if Ambiguity = null then
            --  First initialize the list, from Result itself in case it is
            --  ambiguous.
            Ambiguity := Sem_Info (Result).Ambiguity;

            if Ambiguity = null then
               --  Result wasn't ambiguous, so we need to
               --  create a new list.
               Ambiguity := new Ambiguity_List_Node'
                 (This_Interp => Result,
                  Ambiguous_Operands => null,
                  Next_Ambig_Interp => null);
            end if;
         end if;

         --  Now insert new ambiguity at head of list unless already there
         --  NOTE: Sometimes we get the same interp twice because
         --        we go top-down after doing a bottom-up resolution.
         if Opnd_Interp /= Ambiguity.This_Interp then
            Ambiguity :=
              new Ambiguity_List_Node'
                (This_Interp => Opnd_Interp,
                 Ambiguous_Operands => null,
                 Next_Ambig_Interp => Ambiguity);
         end if;

      end Add_Ambiguity;

      procedure Diagnose_One
        (Opnd_Interp : Optional_Tree;
         Param_Type : Type_Sem_Ptr);
      --  Produce diagnostics for tree with no interpretations

      procedure Check_One
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree);
      --  Check whether operand-interp matches Param_Type

      procedure Check_All_Interps is new Interpretations.Iterate_Interps (
         Check_One);

      procedure Check_One
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree) is
         --  Check whether operand-interp matches Param_Type
         Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Opnd_Interp);
         Param_Map : aliased Param_Mapping_Ptr := Generic_Param_Map;
         Opnd_Sem : constant Sem_Ptr := Underlying_Sem_Info (Opnd_Interp);

         --  Indicates whether operand is a call on a generic operation.
         --  If so, we ignore it if there are other interpretations which
         --  are *not* a call on a generic.
         Opnd_Is_Call_On_Generic : Boolean := False;
         Result_Param_Map : aliased Param_Mapping_Ptr := null;
         Orig_Opnd_Param_Map : Param_Mapping_Ptr;

         Opnd_Call_Sem : Call_Sem_Ptr;
         Opnd_Type_Is_Generic : Boolean := False;
         Is_First_Match : Boolean := False;

         procedure Update_Result_Param_Map is
         --  Update Result_Param_Map if Opnd_Type is generic
         begin
            if Opnd_Type_Is_Generic then
               --  Need to fill in the Result_Param_Map
               --  Operand is a call on a "generic" operation.
               if Debug_Second_Pass then
                  if Param_Type /= null then
                     Put_Line (" Generic param passed a generic result");
                     Put_Line ("  Param_Type is " & Type_Image (Param_Type));
                  else
                     Put_Line (" Generic result used as associated type");
                  end if;
                  Put_Line ("  Opnd_Type is " & Type_Image (Opnd_Type));
                  if Result_Param_Map /= null then
                     Put_Line
                       ("  Prior param-map = " &
                        Param_Map_Image (Result_Param_Map));
                  end if;
                  if Opnd_Type.U_Base_Type = null then
                     Put_Line ("  Opnd_Type.U_Base_Type = null");
                  end if;
               end if;

               --  Need to fill in the Result_Param_Map
               --  NOTE: This is kind of an "identity" mapping
               --       but we presume Opnd_Type has already
               --       been substituted.
               Result_Param_Map :=
                 new Param_Mapping'
                 (From => Sem_Ptr (Opnd_Type.U_Base_Type),
                  To =>
                    Sem_Ptr (Substitute_Actuals
                               (Opnd_Type,
                                Assoc_Type_Region,
                                Extra_Subst => Result_Param_Map)),
               --  Apply earlier mappings if any;
               --  otherwise no change
                  Next => Result_Param_Map);
            end if;
         end Update_Result_Param_Map;

      begin  --  Check_One

         if Debug_Second_Pass then
            Put_Line
              ("  Checking for match between " &
               Subtree_Image (Opnd_Interp) &
               " and type " &
               Type_Image (Param_Type));
            if Formal_Is_Var then
               Put ("   Formal_Is_Var = True,");
            end if;
            Put_Line ("   opnd_sem'tag = " &
              Ada.Tags.Expanded_Name (Opnd_Sem.all'Tag));
         end if;

         if Opnd_Sem.all not in Operand_Semantic_Info'Class
           and then
            Opnd_Sem.all not in Operation_Semantic_Info'Class
         then
            --  Not a possible operand
            if Debug_Second_Pass then
               Put_Line ("  Not an operand: " & Subtree_Image (Opnd_Interp));
            end if;
            if Diagnose then
               Messages.Put_Message ("not a legal operand: " &
                   Subtree_Image (Opnd_Interp,
                     Use_Short_Form => True, Max_Chars => 100),
                 Src_Pos => Find_Source_Pos (Opnd_Interp),
                 Message_Kind => "Info");
            end if;

            return;
         end if;

         if Opnd_Sem.all in Call_Semantic_Info'Class then
            Opnd_Call_Sem := Call_Sem_Ptr (Opnd_Sem);
            --  Initialize Result_Param_Map to existing mapping
            Orig_Opnd_Param_Map := Opnd_Call_Sem.Generic_Param_Map;
            Result_Param_Map := Orig_Opnd_Param_Map;

            --  Remember whether interp is call on a generic op
            Opnd_Is_Call_On_Generic := Opnd_Call_Sem.Op_Sem /= null
              and then Opnd_Call_Sem.Op_Sem.Implicit_Enclosing_Module /= null;

            if Opnd_Type /= null then
               --  Initialize flag indicating that operand is generic

               Opnd_Type_Is_Generic :=
                 Opnd_Type.Associated_Generic_Op /= null
                and then Opnd_Call_Sem.Op_Sem /= null
                and then Opnd_Type.Associated_Generic_Op =
                         Opnd_Call_Sem.Op_Sem.Associated_Symbol;
            end if;
         end if;

         if Param_Type = null then
            --  No specified result type, so any result type is acceptable
            case Compare_Interps
                   (Result, Result_Is_Call_On_Generic,
                    Opnd_Interp, Opnd_Is_Call_On_Generic,
                    Formal_Is_Var) is

            when Prefer_Prior =>
                  if Debug_Second_Pass and then Opnd_Is_Call_On_Generic then
                     Put_Line
                       ("  Find_Interp_Of_Type " &
                        "ignoring generic-op match to null type");
                  end if;

            when Prefer_New =>
               --  First acceptable interp, or preferred interp
               --  because prior interp was generic.
               Result := Opnd_Interp;
               Result_Is_Call_On_Generic := Opnd_Is_Call_On_Generic;
               Is_First_Match := True;
               Ambiguity := null;
               if Debug_Second_Pass then
                  Put_Line ("  Found an interp");
               end if;
               --  Update Result_Param_Map if Opnd_Type is generic
               Update_Result_Param_Map;

               if Diagnose then
                  --  This must not be a useful interpretation
                  Diagnose_One (Opnd_Interp, Param_Type);
               end if;

            when Interps_Are_Equiv =>
               if Debug_Second_Pass then
                  Put_Line
                    ("  Find_Interp_Of_Type " &
                     "found more than one equivalent " &
                     "matches given a null type");
               end if;

            when Interps_Are_Ambig =>
               --  Add on to list of ambiguities
               Add_Ambiguity (Opnd_Interp);

               if Debug_Second_Pass then
                  Put_Line
                    ("  Find_Interp_Of_Type: ambiguous, " &
                     "found more than one interp given a null type");
               end if;
            end case;

         else
            declare
               Something_Matches : Boolean := False;
            begin
               if Opnd_Type = null then
                  --  Check if we have an operation
                  --  and the Param_Type is a func-type
                  if Opnd_Sem.all in Operation_Semantic_Info
                    and then Param_Type.Func_Type_Op_Sem /= null
                  then
                     Something_Matches := Signatures_And_Modes_Match
                       (Param_Type.Func_Type_Op_Sem,
                        Operation_Sem_Ptr (Opnd_Sem));

                     if Diagnose and then not Something_Matches then
                        Messages.Put_Message ("operation " &
                          Subtree_Image (Opnd_Sem.Definition) &
                          " does not match expected func type " &
                          Type_Image (Param_Type, Use_Short_Form => True,
                            Max_Chars => 100),
                          Src_Pos => Find_Source_Pos (Opnd_Interp),
                          Message_Kind => "Info");
                     end if;
                  else
                     if Diagnose then
                        Diagnose_One (Opnd_Interp, Param_Type);
                     end if;
                  end if;
               elsif Types_Match (Param_Type, Opnd_Type) then
                  --  Exact match
                  Something_Matches := True;
                  if Is_Null (Result)
                       or else
                    (Result_Is_Call_On_Generic
                     and then not Opnd_Is_Call_On_Generic)
                  then
                     if Debug_Second_Pass then
                        Put_Line ("  Match because same base types");
                     end if;
                     --  Update Result_Param_Map if Opnd_Type is generic
                     Update_Result_Param_Map;
                  end if;
               else
                  declare
                     Param_Type_Is_Generic : constant Boolean :=
                       Param_Type.Associated_Generic_Op /= null
                      and then Param_Type.Associated_Generic_Op =
                               Associated_Operation;
                  begin
                     if Param_Type_Is_Generic
                       and then Generic_Param_Matches
                                   (Generic_Param_Type => Param_Type,
                                    Opnd_Type => Opnd_Type,
                                    Generic_Param_Map => Param_Map'Access,
                                    Associated_Operation =>
                                      Associated_Operation)
                     then
                        --  Generic param type match

                        Something_Matches := True;
                        if Is_Null (Result)
                          and then Generic_Param_Map /= Param_Map
                        then
                           --  We matched because of a generic param type
                           if Debug_Second_Pass then
                              Put_Line
                                ("  Match because generic type " &
                                 "match, new mapping " &
                                 Subtree_Image (Param_Map.From.Definition) &
                                 " => " &
                                 Subtree_Image (Param_Map.To.Definition));
                           end if;
                           --  Copy back Generic_Param_Map
                           Generic_Param_Map := Param_Map;

                           --  Update Result_Param_Map if Opnd_Type is generic
                           Update_Result_Param_Map;
                        end if;
                     elsif Opnd_Type_Is_Generic
                       and then Generic_Param_Matches
                                   (Generic_Param_Type => Opnd_Type,
                                    Opnd_Type => Param_Type,
                                    Generic_Param_Map =>
                                      Result_Param_Map'Access,
                                    Associated_Operation =>
                                      Opnd_Call_Sem.Op_Sem.Associated_Symbol)
                     then
                        --  Generic result type match

                        Something_Matches := True;

                        if Is_Null (Result) then
                           if Result_Param_Map /= Orig_Opnd_Param_Map then
                              --  This is the first match
                              --  We matched due to a generic result type
                              if Debug_Second_Pass then
                                 Put_Line
                                   ("  Match because generic type match" &
                                    " on result of call, new mapping " &
                                    Subtree_Image
                                       (Result_Param_Map.From.Definition) &
                                    " => " &
                                    Subtree_Image
                                       (Result_Param_Map.To.Definition));
                              end if;
                           else
                              --  No change in param map?
                              Sem_Error
                                (Opnd_Call_Sem.Definition,
                                 "Internal: Result-type not added to mapping");
                           end if;
                        end if;
                     elsif Param_Type.Is_Polymorphic then
                        --  Allow for a match by any type that implements
                        --  the polymorphic type, explicitly or implicitly
                        if Type_Implements_Type
                             (Actual_Type => Opnd_Type,
                              Formal_Type => Param_Type,
                              Check_Parameterless_Modules => True)
                        then
                           if Debug_Second_Pass then
                              Put_Line
                                ("  Match because " &
                                 Type_Image (Opnd_Type) &
                                 " matches polymorphic type " &
                                 Type_Image (Param_Type));
                           end if;
                           Something_Matches := True;
                        end if;
                     end if;

                     if Diagnose and then not Something_Matches then
                        --  Report on this mismatch
                        if Param_Type.Is_Polymorphic
                          and then Type_Implements_Type
                             (Actual_Type => Opnd_Type,
                              Formal_Type => Param_Type,
                              Check_Parameterless_Modules => True,
                              Allow_Abstract => True)
                        then
                           --  Did not match because partially abstract
                           Messages.Put_Message
                             (Type_Image (Opnd_Type, Use_Short_Form => True,
                                Max_Chars => 100) &
                              " has abstract operation so does not" &
                              " match polymorphic type " &
                              Type_Image (Param_Type, Use_Short_Form => True,
                                Max_Chars => 100),
                              Src_Pos => Find_Source_Pos (Opnd_Interp),
                              Message_Kind => "Info");
                        else
                           --  Did not match for the "usual" reasons
                           Messages.Put_Message
                             ("operand's type " &
                              Type_Image (Opnd_Type, Use_Short_Form => True,
                                Max_Chars => 100) &
                              " does not match param type " &
                              Type_Image (Param_Type, Use_Short_Form => True,
                                Max_Chars => 100),
                              Src_Pos => Find_Source_Pos (Opnd_Interp),
                              Message_Kind => "Info");
                        end if;
                     end if;
                  end;
               end if;

               if Something_Matches then
                  --  Types match, exactly or due to a generic type match
                  case Compare_Interps
                         (Result, Result_Is_Call_On_Generic,
                          Opnd_Interp, Opnd_Is_Call_On_Generic,
                          Formal_Is_Var) is

                  when Prefer_Prior =>
                     if Debug_Second_Pass
                       and then Result_Is_Call_On_Generic
                     then
                        Put_Line
                          ("  Find_Interp_Of_Type " &
                           "ignoring generic-op match");
                     end if;

                  when Prefer_New =>
                     --  This is the first match, or is preferred
                     --  because earlier match was generic.
                     Result := Opnd_Interp;
                     Result_Is_Call_On_Generic := Opnd_Is_Call_On_Generic;
                     Is_First_Match := True;
                     Ambiguity := null;

                  when Interps_Are_Equiv =>
                     --  Ignore equivalent matches
                     if Debug_Second_Pass then
                        Put_Line
                          ("  Find_Interp_Of_Type " &
                           "found more than one equivalent matches");
                     end if;

                  when Interps_Are_Ambig =>
                     --  We have a true ambiguity
                     if Debug_Second_Pass then
                        Put_Line
                          ("  Find_Interp_Of_Type: ambiguous, " &
                           "found more than one match");
                     end if;
                     --  Add on to list of ambiguities
                     Add_Ambiguity (Opnd_Interp);

                  end case;

               elsif Opnd_Type = null then
                  --  Nothing more to do
                  null;
               elsif Opnd_Type.Is_Universal
                 and then not Param_Type.Is_Universal
               then
                  --  We will try inserting "from_univ" call, unless there
                  --  is some other interp already of given type.
                  Found_Univ_Interp := True;
               elsif Opnd_Type.Associated_Module /= null
                 and then Opnd_Type.Associated_Module.Contains_Ref_Component
               then
                  --  We will try inserting "ref" call
                  Found_Place_To_Call_Ref := True;
               elsif Param_Type.Is_Universal
                 and then not Opnd_Type.Is_Universal
                 and then (Opnd_Call_Sem = null
                   or else Orig_Opnd_Param_Map = null)
                 and then U_Base_Type_Region (Param_Type) /=
                   Find_Interp_Of_Type.Assoc_Type_Region  --  Avoid ambiguity
                 and then U_Base_Type_Region (Opnd_Type) /=
                   Find_Interp_Of_Type.Assoc_Type_Region  --  Avoid ambiguity
               then
                  --  We will try inserting "to_univ" call, unless there
                  --  is some other interp already of the univ type.
                  Try_Conv_To_Univ := True;
               end if;
            end;
         end if;  --  Whether Param_Type is null

         if not Is_First_Match or else Opnd_Type = null then
            --  Not the first match or no operand type, so don't worry
            --  about generic/polymorphic matches
            null;
         elsif Opnd_Type_Is_Generic
           and then Result_Param_Map /= Orig_Opnd_Param_Map
         then
            --  Copy back Result_Param_Map after reordering
            --  so output params come at end, to correspond
            --  to fact that output params come first in the
            --  symbol list.

            --  But first, make a copy of operand so we don't destroy it
            Result := Copy_Resolved_Tree (Result);
            pragma Assert
              (Call_Sem_Ptr (Underlying_Sem_Info (Result)) /=
               Opnd_Call_Sem);

            Opnd_Call_Sem := Call_Sem_Ptr (Underlying_Sem_Info (Result));

            Opnd_Call_Sem.Generic_Param_Map :=
               Reordered_Param_Map
                 (Result_Param_Map,
                  Orig_Param_Map => Orig_Opnd_Param_Map);
            --  Do the substitution in the result type
            Opnd_Call_Sem.Resolved_Type :=
               Substitute_Actuals
                 (Opnd_Type,
                  Opnd_Call_Sem.Assoc_Type_Region,
                  Extra_Subst => Result_Param_Map);
            if Debug_Second_Pass then
               Put_Line
                 (" Find_Interp_Of_Type: Just set Resolved_Type for " &
                  Subtree_Image (Resolved_Tree (Opnd_Interp)) &
                  " to " &
                  Type_Image (Opnd_Call_Sem.Resolved_Type));
            end if;
         elsif Param_Type /= null
           and then Opnd_Sem.all in Operand_Semantic_Info'Class
           and then Param_Type.Is_Polymorphic
           and then not Opnd_Type.Is_Polymorphic
         then
            --  Indicate we have a conversion to a polymorphic type.
            --  But first, make a copy of operand so we don't destroy it.
            --  TBD: What to do about polymorphic formal param matched
            --      by generic result?
            Result := Copy_Resolved_Tree (Result);
            pragma Assert (Underlying_Sem_Info (Result) /= Opnd_Sem);

            Operand_Sem_Ptr (Underlying_Sem_Info (Result)).
              Target_Polymorphic_Type := Param_Type;

            if not Opnd_Type.All_Parameters_Known then
               --  We need to add this combination of types
               --  as needing an op-map.
               declare
                  Enc_Module : constant Module_Sem_Ptr :=
                    Find_Enclosing_Module_Interface (Decl_Region => null);
               begin
                  if Enc_Module = null then
                     if Debug_Second_Pass then
                        Put_Line (" Need op map for " &
                          Type_Image (Opnd_Type) & " viewed as " &
                          Type_Image (Param_Type) &
                          " but no enclosing module");
                     end if;
                  else
                     if Debug_Second_Pass then
                        Put_Line (" Need op map for " &
                          Type_Image (Opnd_Type) & " viewed as " &
                          Type_Image (Param_Type) &
                          " in module " &
                          Sym_Name (Enc_Module.Associated_Symbol));
                     end if;
                     if not Opnd_Type.All_Parameters_Known then
                        --  Add combination to module
                        --  and record mapping in opnd_type
                        --  from target to nested type index.
                        --  Same mapping can be used for types with all
                        --  parameters known.
                        declare
                           Op_Map_Index : constant
                             Type_Sem_Vectors.Elem_Index :=
                               Op_Map_Type_Desc_Index (Opnd_Type, Param_Type,
                                                       Find_Source_Pos (Opnd));
                        begin
                           if Debug_Second_Pass then
                              Put_Line ("  Op map assigned index" &
                                Type_Sem_Vectors.Elem_Index'Image
                                  (Op_Map_Index));
                           end if;
                        end;
                     end if;
                  end if;
               end;
            end if;

            if Debug_Second_Pass then
               Put_Line
                 (" Find_Interp_Of_Type: Set Target_Polymorphic_Type for " &
                  Subtree_Image (Resolved_Tree (Opnd_Interp)) &
                  " to " &
                  Type_Image (Param_Type));
            end if;

         end if;
      end Check_One;

      procedure Check_One_Univ_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree) is
         --  Check whether given Interp is of a universal type,
         --  with a "from_univ" operation to Param_Type.
         Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Opnd_Interp);
      begin
         if not Opnd_Type.Is_Universal then
            --  Ignore this one
            null;
         elsif Param_Type.U_Base_Structure = Opnd_Type.U_Base_Structure then
            --  We allow implicit conversions between univ-type and a
            --  "new" univ type.
            if Is_Null (Result) then
               Result := Opnd_Interp;  --  TBD: This should be converted
               --  into an explicit conversion, and should check for ambiguity
            end if;
         else
            --  Try inserting "from_univ" call
            declare
               From_Univ_Call : constant Optional_Tree :=
                 Create_From_Univ_Call
                    (Operand => Opnd_Interp,
                     To_Type => Param_Type);
            begin
               if Not_Null (From_Univ_Call) then
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Create_From_Univ_Call for " &
                        Subtree_Image (Opnd_Interp) &
                        " returned non-null result of type " &
                        Type_Image (Param_Type));
                  end if;
                  Check_All_Interps
                    (  --  Recurse to try these
                     Operand_Sem_Ptr (Sem_Info (From_Univ_Call)).Interps);
               else
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Operand " &
                        Subtree_Image (Opnd_Interp) &
                        " is of univ type *not* convertible to " &
                        Type_Image (Param_Type));
                  end if;
                  if Diagnose then
                     Messages.Put_Message
                       ("operand " &
                        Subtree_Image (Opnd_Interp,
                          Use_Short_Form => True, Max_Chars => 100) &
                        " is of univ type *not* convertible to " &
                        Type_Image (Param_Type,
                          Use_Short_Form => True, Max_Chars => 100),
                        Src_Pos => Find_Source_Pos (Opnd_Interp),
                        Message_Kind => "Info");
                  end if;
               end if;  --  Whether "from_univ" operator defined
            end;
         end if;
      end Check_One_Univ_Interp;

      procedure Check_Univ_Interps is new Interpretations.Iterate_Interps (
         Check_One_Univ_Interp);

      procedure Check_One_Conv_To_Univ
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree) is
         --  Check whether given Interp has a "to_univ" operation
         --  that converts to Param_Type.
         Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Opnd_Interp);
         pragma Assert (Param_Type.Is_Universal);
      begin
         if Opnd_Type.Is_Universal then
            --  Ignore this one
            null;
         elsif Opnd_Type.U_Base_Structure = Param_Type.U_Base_Structure then
            --  Allow implicit conversion from "new" univ type to univ
            --  TBD: Also allow conversion from descendant of univ type.
            if Is_Null (Result) then
               Result := Opnd_Interp;  --  TBD: Should create explicit conv,
               --  check for ambig, etc.
            end if;
         else
            --  Try inserting "to_univ" call
            declare
               To_Univ_Call : constant Optional_Tree :=
                 Create_To_Univ_Call
                    (Operand => Opnd_Interp,
                     To_Univ_Type => Param_Type);
            begin
               if Not_Null (To_Univ_Call) then
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Create_To_Univ_Call for " &
                        Subtree_Image (Opnd_Interp) &
                        " returned non-null result for type " &
                        Type_Image (Opnd_Type));
                  end if;
                  Check_All_Interps
                    (  --  Recurse to try these
                     Operand_Sem_Ptr (Sem_Info (To_Univ_Call)).Interps);
               else
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Operand " &
                        Subtree_Image (Opnd_Interp) &
                        " is of type *not* convertible to " &
                        Type_Image (Param_Type));
                  end if;
                  if Diagnose then
                     Messages.Put_Message
                       ("operand " &
                        Subtree_Image (Opnd_Interp) &
                        " is of type *not* convertible to " &
                        Type_Image (Param_Type, Use_Short_Form => True,
                          Max_Chars => 100),
                        Src_Pos => Find_Source_Pos (Opnd_Interp),
                        Message_Kind => "Info");
                  end if;
               end if;  --  Whether "to_univ" operator defined
            end;
         end if;
      end Check_One_Conv_To_Univ;

      procedure Check_Conv_To_Univ is new Interpretations.Iterate_Interps (
         Check_One_Conv_To_Univ);

      procedure Check_One_Ref_Call
        (Assoc_Type_Region : Type_Region_Ptr;
         Opnd_Interp : Optional_Tree) is
         --  Check whether given Interp is of a ref-object type
         --  with a "ref" operation to Param_Type or convertible to Param_Type
         Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Opnd_Interp);
      begin
         if Opnd_Type.Associated_Module = null
           or else not Opnd_Type.Associated_Module.Contains_Ref_Component
         then
            --  Ignore this one
            null;
         else
            --  Try inserting "ref" call
            declare
               Ref_Call : constant Optional_Tree :=
                 Create_Ref_Call (Operand => Opnd_Interp);
            begin
               if Not_Null (Ref_Call) then
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Create_Ref_Call for " &
                        Subtree_Image (Opnd_Interp));
                  end if;
                  Check_All_Interps  --  Recurse to try these
                    (Operand_Sem_Ptr (Sem_Info (Ref_Call)).Interps);
                  if Found_Univ_Interp and then Not_Null (Result) then
                     --  Try inserting a conversion by "from_univ"
                     Check_Univ_Interps
                       (Operand_Sem_Ptr (Sem_Info (Ref_Call)).Interps);
                  end if;
                  if Try_Conv_To_Univ and then Is_Null (Result) then
                     --  Try inserting a conversion by "to_univ"
                     Check_Conv_To_Univ
                        (Operand_Sem_Ptr (Sem_Info (Ref_Call)).Interps);
                  end if;
               else
                  if Debug_Second_Pass then
                     Put_Line
                       ("  Operand " &
                        Subtree_Image (Opnd_Interp) &
                        " is of ref-object type w/o ""ref"" op for " &
                        Type_Image (Param_Type));
                  end if;
                  if Diagnose then
                     Messages.Put_Message
                       ("operand " &
                        Subtree_Image (Opnd_Interp,
                          Use_Short_Form => True, Max_Chars => 100) &
                        " is of ref-object type w/o ""ref"" op for " &
                        Type_Image (Param_Type,
                          Use_Short_Form => True, Max_Chars => 100),
                        Src_Pos => Find_Source_Pos (Opnd_Interp),
                        Message_Kind => "Info");
                  end if;
               end if;  --  Whether "ref" operator defined
            end;
         end if;
      end Check_One_Ref_Call;

      procedure Check_Ref_Calls is new Interpretations.Iterate_Interps (
         Check_One_Ref_Call);

      procedure Diagnose_One
        (Opnd_Interp : Optional_Tree;
         Param_Type : Type_Sem_Ptr) is
      --  Produce diagnostics for tree with no interpretations
         Opnd_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Opnd_Interp).all;
      begin
         if Opnd_Tree in Identifier.Tree then
            Messages.Put_Message
              ("identifier " &
               Subtree_Image (Opnd_Interp,
                 Use_Short_Form => True, Max_Chars => 100) &
               " is not defined",
               Src_Pos => Find_Source_Pos (Opnd_Interp),
               Message_Kind => "Info");
            return;
         elsif Opnd_Tree in Invocation.Tree then
            declare
               Opnd_Invoc_Tree : Invocation.Tree renames
                 Invocation.Tree (Opnd_Tree);
               use Invocation;
            begin
               case Opnd_Invoc_Tree.Kind is
                  when Operation_Call      =>
                     --  Re-analyze with Diagnose True
                     Create_Call_Interps (Opnd_Interp, Diagnose => True);
                     return;

                  when Class_Aggregate     =>
                     if Is_Parenthesized_Expression (Opnd_Interp) then
                        --  Skip over the parens
                        Diagnose_One
                          (Remove_Parentheses (Opnd_Interp), Param_Type);
                     else
                        --  Re-analyze with Diagnose True
                        Create_Class_Agg_Interp
                          (Class_Agg_Sem_Ptr (Sem_Info (Opnd_Interp)),
                           Param_Type,
                           Diagnose => True);
                     end if;
                     return;

                  when Container_Aggregate | Map_Set_Aggregate =>
                     --  Re-analyze with Diagnose True
                     if Sem_Info (Opnd_Interp).all in Call_Semantic_Info then
                        Create_Call_Interps (Opnd_Interp, Diagnose => True);
                        return;
                     elsif Sem_Info (Opnd_Interp).all in
                       Container_Aggregate_Semantic_Info
                     then
                        Create_Container_Agg_Interp
                          (Container_Agg_Sem_Ptr (Sem_Info (Opnd_Interp)),
                           Param_Type,
                           Diagnose => True);
                        return;
                     end if;

                  when Container_Indexing
                    | Module_Instantiation
                    | Is_Function_Of
                    | Tuple_Type_Definition =>
                     null;  --  Fall through to produce fall-back message
               end case;
            end;
         end if;

         --  Produce fall-back message
         Messages.Put_Message
           ("no interpretations for: " &
            Subtree_Image (Opnd_Interp, Use_Short_Form => True,
              Max_Chars => 100),
            Src_Pos => Find_Source_Pos (Opnd_Interp),
            Message_Kind => "Info");
      end Diagnose_One;

      use type Interpretations.Interp_Tree;

   begin  --  Find_Interp_Of_Type

      if Debug_Second_Pass then
         Put_Line
           ("  Checking for match between interps of " &
            Subtree_Image (Opnd) &
            " and type " &
            Type_Image (Param_Type));
         if Opnd_Sem /= null then
            Put_Line ("   opnd_sem'tag = " &
              Ada.Tags.Expanded_Name (Opnd_Sem.all'Tag));
         end if;
      end if;
      Ambiguity := null;
      if Opnd_Sem /= null
        and then Opnd_Sem.all in Operand_Semantic_Info'Class
      then
         --  We might have a match, so iterate over interpretations
         if Not_Null (Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp) then
            --  Already resolved to a single interp
            Check_One
              (Assoc_Type_Region => null,
               Opnd_Interp => Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp);
         else
            --  Still a tree of interps
            if Param_Type /= null then
               --  Add interpretations based on region of Param_Type.
               Add_Targeted_Interps (Opnd, Param_Type,
                 Associated_Operation);
            end if;

            if Not_Null (Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp) then
               --  Recheck if Add_Targeted_Interps chose a single interp
               Check_One
                 (Assoc_Type_Region => null,
                  Opnd_Interp => Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp);
            elsif Interpretations.Has_Interp
              (Operand_Sem_Ptr (Opnd_Sem).Interps)
            then
               --  We have a tree of interps; pick one that matches
               Check_All_Interps (Operand_Sem_Ptr (Opnd_Sem).Interps);
               if Found_Univ_Interp and then Is_Null (Result) then
                  --  Try inserting a conversion by "from_univ"
                  Check_Univ_Interps (Operand_Sem_Ptr (Opnd_Sem).Interps);
               end if;
               if Try_Conv_To_Univ and then Is_Null (Result) then
                  --  Try inserting a conversion by "to_univ"
                  Check_Conv_To_Univ (Operand_Sem_Ptr (Opnd_Sem).Interps);
               end if;
               if Found_Place_To_Call_Ref
                 and then (Is_Null (Result) or else Formal_Is_Var)
               then
                  --  Try inserting a call on "ref"
                  Check_Ref_Calls (Operand_Sem_Ptr (Opnd_Sem).Interps);
               end if;
            else
               --  Fall back to operand itself
               Check_One (Assoc_Type_Region => null, Opnd_Interp => Opnd);
            end if;
         end if;
      end if;
      Chosen_Interp := Result;
      if Not_Null (Result)
        and then Sem_Info (Result).Ambiguity /= null
      then
         --  Nested ambiguity; make sure Ambiguity is non-null
         if Ambiguity = null then
            Ambiguity := Sem_Info (Result).Ambiguity;
         end if;
      end if;
   end Find_Interp_Of_Type;

   function Is_Actual_Of_Formal (Type_Sem : Type_Sem_Ptr) return Boolean is
   --  Return True if Type_Sem represents an actual-of-formal
      use type Type_Sem_Vectors.Elem_Index;
   begin
      if Type_Sem.Is_Formal_Type
        and then Not_Null (Type_Sem.Formal_Prefix)
        and then Type_Sem.Actual_Of_Formal_Index /= 0
      then
         --  Is an actual-of-formal
         --  Check that the formal prefix is a qualified name.
         pragma Assert
           (Tree_Ptr_Of (Type_Sem.Formal_Prefix).all in Qualified_Name.Tree);

         return True;
      else
         return False;
      end if;
   end Is_Actual_Of_Formal;

   function Nth_Element_If_Present
     (L : Lists.List;
      Index : Positive)
      return Optional_Tree
   is
   --  Return Nth_Element of list, if Length(L) >= Index, else
   --  return Null_Optional_Tree
   begin
      if Lists.Length (L) >= Index then
         return Lists.Nth_Element (L, Index);
      else
         return Null_Optional_Tree;
      end if;
   end Nth_Element_If_Present;

   function Module_With_Formal_Type
     (Formal_Type : Type_Sem_Ptr)
      return Module_Sem_Ptr
   is
   --  Return Module that has the given formal type.
   --  Return null if not found.
   begin
      if Is_Actual_Of_Formal (Formal_Type) then
         --  Go to qualified name sym for index, assuming it is
         --  the name of a formal type.
         return Interface_Part
                  (Module_Sem_Ptr (
           Sym_Ref_Ptr (Sem_Info (Formal_Type.Formal_Prefix)).
           Associated_Symbol.Enclosing_Region.Associated_Symbol.Sem_Info));
      elsif Formal_Type.Associated_Symbol /= null then
         return Interface_Part
                  (Module_Sem_Ptr (
           Formal_Type.Associated_Symbol.Enclosing_Region.Associated_Symbol.
           Sem_Info));
      else
         return null;
      end if;
   end Module_With_Formal_Type;

   function Module_Formal_Index
     (Formal_Sym : Symbols.Sym_Ptr)
      return Natural
   is
   --  Return index for formal of module, based on its Symbol index
   begin
      if Formal_Sym /= null then
         --  Get index of formal, numbered 1 .. Num_Module_Parameters
         declare
            pragma Assert
              (Formal_Sym.Enclosing_Region.Kind = Module_Region_Kind);
            Mod_Sem : constant Module_Sem_Ptr :=
              Module_Sem_Ptr
                (Formal_Sym.Enclosing_Region.Associated_Symbol.Sem_Info);
            First_Mod_Param : constant Optional_Tree :=
              Nth_Module_Parameter (Mod_Sem, 1);
            First_Mod_Param_Sym : constant Sym_Ptr :=
              Sem_Ptr (Sem_Info (First_Mod_Param)).Associated_Symbol;
         begin
            --  Should be in range 1 .. Num_Module_Parameters
            return Positive'(Positive (Formal_Sym.Index) -
              Positive (First_Mod_Param_Sym.Index) + 1);
         end;
      else
         return 0;
      end if;
   end Module_Formal_Index;

   function Formal_Type_Index (Formal_Type : Type_Sem_Ptr) return Natural is
   --  Return index for formal type, or 0 if none
      Formal_Base : Type_Sem_Ptr := Formal_Type.U_Base_Type;
   begin
      if Formal_Base = null then
         Formal_Base := Formal_Type;
      end if;
      if Is_Actual_Of_Formal (Formal_Base) then
         --  Go to qualified name sym for index, assuming it is
         --  the name of a formal type.
         return Module_Formal_Index
                  (Sym_Ref_Ptr (Sem_Info (Formal_Base.Formal_Prefix)).
                    Associated_Symbol);
      elsif Formal_Base.Associated_Symbol /= null then
         return Module_Formal_Index (Formal_Base.Associated_Symbol);
      else
         return 0;
      end if;
   end Formal_Type_Index;

   function Substitute_Actuals_In_Nested_Type
     (Nested_Type : Type_Sem_Ptr;
      Assoc_Type_Region : Type_Region_Ptr;
      Is_Formal_Type : Boolean := False;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null)
      return Type_Sem_Ptr
   is
      --  Handle a nested module instantiation; needs something substituted in
      --  one of the actuals to the instantiation defining the type.
      --  Create a new instantiation of the same module
      --  with the actual substituted.
      --  If Is_Formal_Type is True, then do not complain if
      --  result has unknown parameters, and there is
      --  no enclosing module.
      use type Type_Sem_Vectors.Elem_Index;
      use type Invocation.Invocation_Kind_Enum;

      Nested_Type_Actuals : Sem_Info_Array_Ptr :=
        Nested_Type.Actual_Sem_Infos;

      function Create_New_Instance
        (Nested_Type : Type_Sem_Ptr;
         Substituted_Enclosing_Type : Type_Sem_Ptr;
         Is_Formal_Type : Boolean)
        return Type_Sem_Ptr is
      --  Create a new instance to replace Nested_Type
      --  after substituting into Nested_Type_Actuals.

         Nested_Type_Def : Invocation.Tree
           renames Invocation.Tree (Tree_Ptr_Of
             (Nested_Type.U_Base_Structure.Definition).all);

         Num_Formals : constant Natural := Nested_Type_Actuals'Length;
         Substituted_Nested_Type_Sem : Type_Sem_Ptr := null;
         Substituted_Actual_Sem_Infos : Sem_Info_Array (1 .. Num_Formals);
      begin
         for Formal_Index in 1 .. Num_Formals loop
            declare
               New_Operand : constant Optional_Tree :=
                 Substitute_Actuals_In_Operand
                    (Nested_Type_Actuals (Formal_Index).Definition,
                     Assoc_Type_Region,
                     Instantiation_Info => Instantiation_Info,
                     Extra_Subst => Extra_Subst);
            begin
               Substituted_Actual_Sem_Infos (Formal_Index) :=
                  Sem_Ptr (Sem_Info (New_Operand));

               --  We should not be putting a param-decl into actual sem info
               pragma Assert (Tree_Ptr_Of
                 (Substituted_Actual_Sem_Infos (Formal_Index).Definition).all
                    not in Param_Decl.Tree);

            end;
         end loop;

         Substituted_Nested_Type_Sem := Instantiate_Module
           (Mod_Sem => Nested_Type.Associated_Module,
            Actual_Params => Substituted_Actual_Sem_Infos,
            Enclosing_Type => Substituted_Enclosing_Type,
            Is_Formal_Type => Is_Formal_Type,
            Formal_Prefix => Nested_Type.Formal_Prefix,
            Associated_Generic_Op => Nested_Type.Associated_Generic_Op);

         Substituted_Nested_Type_Sem.Associated_Symbol :=
           Nested_Type.Associated_Symbol;

         if Debug_Second_Pass then
            Put_Line
              (" Substituting " &
               Type_Image (Substituted_Nested_Type_Sem) &
               " for nested type " &
               Type_Image (Nested_Type));
         end if;
         return Substituted_Nested_Type_Sem;

      end Create_New_Instance;

      Nested_Type_Def : Invocation.Tree
        renames Invocation.Tree (Tree_Ptr_Of
          (Nested_Type.U_Base_Structure.Definition).all);
      pragma Assert (Nested_Type_Def.Kind = Invocation.Module_Instantiation);
      Nested_Type_Module : constant Module_Sem_Ptr :=
        Nested_Type.Associated_Module;
      Num_Formals : constant Natural :=
        Num_Module_Parameters (Nested_Type_Module);
      pragma Assert
        (Nested_Type_Actuals = null
        or else Nested_Type_Actuals'Length = 0
        or else Nested_Type_Actuals'Length = Num_Formals
        or else Nested_Type_Module.Treat_As_Type);
      Nested_Type_Encloser : constant Type_Sem_Ptr :=
        Nested_Type.Enclosing_Type;

      Substituted_Enclosing_Type : Type_Sem_Ptr;
      Substituted_Nested_Type_Sem : Type_Sem_Ptr := null;

   begin  --  Substitute_Actuals_In_Nested_Type;

      if Nested_Type_Encloser /= null
        and then Nested_Type.Is_Formal_Type
        and then Nested_Type.Associated_Module.Treat_As_Type
        and then Num_Formals = 0
        and then Nested_Type_Actuals /= null
        and then Nested_Type_Actuals'Length > 0
        and then Num_Module_Parameters
          (Nested_Type_Encloser.Associated_Module) = Nested_Type_Actuals'Length
        and then Nested_Type_Encloser.U_Base_Type =
          Nested_Type_Encloser.Associated_Module.Cur_Inst_Sem
      then
         --  We have a formal type whose enclosing package is generic
         --  We need to create a new instance of encloser

         Substituted_Enclosing_Type := Create_New_Instance
           (Nested_Type_Encloser, Nested_Type_Encloser.Enclosing_Type,
            Is_Formal_Type => Is_Formal_Type);  --  TBD: Should be false?

         --  Now create new instance of Nested_Type with new encloser
         Substituted_Nested_Type_Sem := Instantiate_Module
           (Mod_Sem => Nested_Type.Associated_Module,
            Actual_Params => (Nested_Type_Actuals'Range => null),
            Enclosing_Type => Substituted_Enclosing_Type,
            Is_Formal_Type => Is_Formal_Type,
            Formal_Prefix => Nested_Type.Formal_Prefix,
            Associated_Generic_Op => Nested_Type.Associated_Generic_Op);

         Substituted_Nested_Type_Sem.Associated_Symbol :=
           Nested_Type.Associated_Symbol;

      else
         --  Substitute for enclosing type and then create new
         --  nested type

         Substituted_Enclosing_Type :=
           Substitute_Actuals
             (Nested_Type.Enclosing_Type,
              Assoc_Type_Region,
              Instantiation_Info => Instantiation_Info,
              Extra_Subst => Extra_Subst);

         if Debug_Second_Pass then
            Put
              ("  Substitute_Actuals_In_Nested_Type(" &
               Type_Image (Nested_Type) &
               ", Assoc_Type_Region => " &
               Type_Image (Type_Sem_Ptr (Assoc_Type_Region)));
            if Instantiation_Info /= null then
               Put (", Instantiation_Info => " &
                 Subtree_Image (Instantiation_Info.Instantiation));
            end if;
            if Extra_Subst /= null then
               Put (", Extra_Subst => " & Param_Map_Image (Extra_Subst));
            end if;
            Put_Line (")");
         end if;

         if (Some_Nulls (Nested_Type_Actuals) or else Num_Formals = 0)
           and then Nested_Type.Enclosing_Type = Substituted_Enclosing_Type
         then
            --  Not enough info to make a replacement
            return Nested_Type;
         end if;

         if Nested_Type_Actuals = null then
            --  Nested_Type_Actuals'Length is used for Num_Formals...
            Nested_Type_Actuals := new Sem_Info_Array (1 .. 0);
         end if;

         --  Create a new instance with actuals substituted in for formals
         Substituted_Nested_Type_Sem := Create_New_Instance
           (Nested_Type, Substituted_Enclosing_Type, Is_Formal_Type);
      end if;

      return Substituted_Nested_Type_Sem;

   end Substitute_Actuals_In_Nested_Type;

   function Substitute_Actuals_In_New_Type
     (Nested_Type : Type_Sem_Ptr;
      Assoc_Type_Region : Type_Region_Ptr;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null)
      return Type_Sem_Ptr is

   --  Handle a "new" type -- substitute into the parent type
   --  and then create a type-decl.

      pragma Assert (Nested_Type.New_Type_Counter /= Anonymous_Type_Indicator);

      --  Do substitution in parent type first,
      --  and then create a type_decl for the "new" type
      --  with the same New_Type_Counter value.

      --  Must have a parent type
      pragma Assert (Nested_Type.Parent_Type /= null);

      --  Recurse on parent type
      Substituted_Parent : constant Type_Sem_Ptr :=
        Substitute_Actuals
          (Nested_Type.Parent_Type, Assoc_Type_Region,
           Instantiation_Info, Extra_Subst);

      Substituted_Encloser : constant Type_Sem_Ptr :=
        Substitute_Actuals
          (Nested_Type.Enclosing_Type, Assoc_Type_Region,
           Instantiation_Info, Extra_Subst);

      function New_Type_Name return Optional_Tree is
      --  Create Identifier tree based on Nested_Type sym, if any.
      begin
         if Nested_Type.Associated_Symbol = null then
            return Null_Optional_Tree;
         else
            return Identifier.Make
              (Str => Nested_Type.Associated_Symbol.Str,
               Source_Pos => Nested_Type.Associated_Symbol.Source_Pos);
         end if;
      end New_Type_Name;

      New_Type_Decl : constant Optional_Tree := Type_Decl.Make
        (Name => New_Type_Name,
         Is_New_Type => True,
         Type_Definition => Substituted_Parent.Definition);
      New_Type_Sem : constant Type_Sem_Ptr :=
        new Type_Semantic_Info '(Substituted_Parent.all);

   begin

      if Debug_Second_Pass then
         Put
           (" Substitute_Actuals_In_New_Type(" &
            Type_Image (Nested_Type) &
            ", Assoc_Type_Region => " &
            Type_Image (Type_Sem_Ptr (Assoc_Type_Region)));
         if Instantiation_Info /= null then
            Put (", Instantiation_Info => " &
              Subtree_Image (Instantiation_Info.Instantiation));
         end if;
         if Extra_Subst /= null then
            Put (", Extra_Subst => " & Param_Map_Image (Extra_Subst));
         end if;
         Put_Line (")");
         Put_Line ("  New Enclosing_Type = " &
           Type_Image (Substituted_Encloser) & ", " &
           "New Parent_Type = " &
           Type_Image (Substituted_Parent));
      end if;

      --  Point to new type-decl, and set new-type counter to match.
      New_Type_Sem.Definition := New_Type_Decl;
      New_Type_Sem.Type_Index := Next_Type_Index;
      Set_Sem_Info (New_Type_Decl, Root_Sem_Ptr (New_Type_Sem));
      New_Type_Sem.New_Type_Counter := Nested_Type.New_Type_Counter;
      New_Type_Sem.Parent_Type := Substituted_Parent;
      New_Type_Sem.Enclosing_Type := Substituted_Encloser;
      New_Type_Sem.Is_Universal := False;

      --  Null out U_Base_Type and U_Type and recompute.
      New_Type_Sem.U_Base_Type := null;
      New_Type_Sem.U_Type := null;

      --  Also null out other info.
      --  TBD: should we do this in Finish_Type_Sem_Info?
      New_Type_Sem.Type_Descriptor_Location :=
        Interpreter.Null_Object_Locator;
      New_Type_Sem.Op_Maps_Needed := Empty_Hash_Table;
      New_Type_Sem.Associated_Symbol := Nested_Type.Associated_Symbol;

      Finish_Type_Sem_Info (New_Type_Sem, Decl_Region => null);
      --  TBD: Decl_Region?

      return New_Type_Sem;
   end Substitute_Actuals_In_New_Type;

   function Corresponding_Progenitor_Type
     (Starting_Type : Type_Sem_Ptr;
      Progenitor_Module : Module_Sem_Ptr)
      return Type_Sem_Ptr
   is
   --  If Associated_Module of Starting_Type does not match Progenitor_Module,
   --  search chain of ancestors and tree of implemented interfaces of
   --  Starting_Type to find an implementation of Progenitor_Module, and
   --  return corresponding type.
   --  Return null if no such progenitor found.
   begin
      if Progenitor_Module = Starting_Type.Associated_Module then
         --  We already have the right module
         return Starting_Type;

      elsif Starting_Type.Associated_Module.Treat_As_Type
        and then Starting_Type.Enclosing_Type /= null
        and then Progenitor_Module =
          Starting_Type.Enclosing_Type.Associated_Module
      then
         --  Enclosing package for type was the correct module
         return Starting_Type.Enclosing_Type;

      else
         --  Try one of the implemented interfaces
         --  TBD: Search tree, not just list of implemented interfaces
         declare
            Starting_Module_Tree : Module.Tree
              renames Module.Tree (Tree_Ptr_Of
                (Starting_Type.Associated_Module.Definition).all);
            Implemented_Interfaces : Lists.List renames
              Starting_Module_Tree.Implements_Interfaces;
         begin
            for I in 1 .. Lists.Length (Implemented_Interfaces) loop
               declare
                  Implemented_Type : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (Underlying_Sem_Info
                                     (Lists.Nth_Element
                                         (Implemented_Interfaces,
                                          I)));
               begin
                  if Implemented_Type.Associated_Module =
                     Progenitor_Module
                  then
                     --  Found a type from the desired module
                     return Substitute_Actuals
                              (Implemented_Type,
                               U_Base_Type_Region (Starting_Type));
                     --  TBD: If treat_as_type, check enclosing type too
                  end if;
               end;
            end loop;

            --  TBD: Search entire tree, not just top-level "implements" list.

            if Starting_Type.Parent_Type /= null then
               --  Recurse with parent
               return Corresponding_Progenitor_Type
                 (Starting_Type.Parent_Type, Progenitor_Module);
            else
               return null;
            end if;
         end;
      end if;
   end Corresponding_Progenitor_Type;

   function Substitute_Actuals_In_Func_Type
     (Func_Type : Type_Sem_Ptr;
      Assoc_Type_Region : Type_Region_Ptr;
      Extra_Subst : Param_Mapping_Ptr := null)
      return Type_Sem_Ptr
   is
      --  Handle a func type; needs something substituted in one
      --  of the formals or default expressions of the func type.
      --  Create a new func type with the actuals substituted.
      Old_Op_Sem : constant Operation_Sem_Ptr := Func_Type.Func_Type_Op_Sem;
      New_Func_Type : constant Optional_Tree := Substitute_In_Tree
        (Old_Op_Sem.Definition,
         Assoc_Type_Region,
         Extra_Subst => Extra_Subst,
         Always_Copy_Tree => True);  --  Prevent any sharing
      Enclosing_Region : constant Region_Ptr :=
        Old_Op_Sem.Nested_Region.Enclosing_Region;
      Result : Type_Sem_Ptr;
   begin
      First_Pass (Enclosing_Region, New_Func_Type);
      Second_Pass (Enclosing_Region, New_Func_Type, Context => Type_Context);
      Result := Operation_Sem_Ptr (Sem_Info (New_Func_Type)).Func_Type_Sem;

      if Debug_Second_Pass then
         Put_Line
           (" Substituting " &
            Type_Image (Result) &
            " for func type " &
            Type_Image (Func_Type));
      end if;

      return Result;
   end Substitute_Actuals_In_Func_Type;

   function Combine_Names
     (Prefix : Optional_Tree;
      Suffix : Optional_Tree)
      return Optional_Tree
   is
      --  Make a qualified_name which is the combination of the Prefix
      --  and the Suffix.  Either or both might already be a qualified_name.
      --  Prefix might be a Null_Optional_Tree.
      --  Carry over any sem info from Suffix.
      Result : Optional_Tree := Null_Optional_Tree;
   begin
      if Is_Null (Prefix) then
         --  Nothing to do
         return Suffix;
      elsif Tree_Ptr_Of (Suffix).all in Identifier.Tree then
         --  Identifier is the easy case
         Result := Qualified_Name.Make (Prefix => Prefix, Id => Suffix);
      elsif Tree_Ptr_Of (Suffix).all in Qualified_Name.Tree then
         --  Recurse if Suffix is a qualified name
         Result :=
            Qualified_Name.Make
              (Prefix =>
                  Combine_Names
                    (Prefix => Prefix,
                     Suffix =>
                       Qualified_Name.Tree (Tree_Ptr_Of (Suffix).all).Prefix),
               Id => Qualified_Name.Tree (Tree_Ptr_Of (Suffix).all).Id);
      else
         --  Suffix should be one or the other
         Sem_Error
           (Suffix,
            "Internal: Should be Identifier or Qualified_Name");
         return Suffix;
      end if;
      --  Preserve the sem info
      Set_Sem_Info (Result, Sem_Info (Suffix));
      return Result;
   end Combine_Names;

   function Region_Of_Module
     (Mod_Sem : Module_Sem_Ptr)
      return Symbols.Region_Ptr
   is
   --  Return Mod_Sem.Nested_Region, or Library_Region if Mod_Sem is null.
   begin
      if Mod_Sem = null then
         return Symbols.Library_Region;
      else
         return Mod_Sem.Nested_Region;
      end if;
   end Region_Of_Module;

   function Substitute_Actuals_From_Instantiation
     (Decl_Region : Symbols.Region_Ptr;
      Formal_Type : Type_Sem_Ptr;
      Instantiation_Module : Module_Sem_Ptr;
      Instantiation : Invocation.Tree;
      Enclosing_Type : Type_Sem_Ptr)
      return Type_Sem_Ptr;
   --  Return Formal_Type, possibly replace with actual type
   --  from Instantiation of given module with given Enclosing_Type.
   --  Requires: Formal_Type is a formal type

   function Substitute_Actuals
     (Param_Type : Type_Sem_Ptr;
      Assoc_Type_Region : Type_Region_Ptr;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null;
      Ancestor_From_Formal_Module : Boolean := False;
      Associated_Operation : Sym_Ptr := null)
      return Type_Sem_Ptr
   is
   --  If Param_Type is a formal type or depends on one,
   --  substitute in the actuals from the Assoc_Type_Region
   --  to produce the "actual" Param_Type.
   --  If Assoc_Type_Region and Param_Type are from the same Module,
   --  and Assoc_Type_Region is a formal type and Param_Type
   --  is a current instance, then substitute Assoc_Type_Region
   --  for Param_Type.
   --  If Extra_Subst is non-null, then it represents
   --  additional substitutions that are to be performed.
   --  If Ancestor_From_Formal_Module is True, then
   --  return the subtype which is the ancestor of the
   --  substituted type which is from the same module as the
   --  formal type.
   --  If Associated_Operation is non-null, then if its enclosing region
   --  does *not* match the enclosing region of Assoc_Type_Region but *does*
   --  match that of Param_Type, and both Param_Type and Assoc_Type_Region
   --  are "new" types and Param_Type is an ancestor of Assoc_Type_Region,
   --  then substitute Assoc_Type_Region for Param_Type.
   --  TBD: We should "or" in Optionality and Constraints.
      Originating_Type : constant Type_Sem_Ptr :=
        Type_Sem_Ptr (Assoc_Type_Region);
      use type Type_Sem_Vectors.Elem_Index;

      function Create_Actual_Of_Formal (Enclosing_Prefix : Optional_Tree;
        Formal_Type : Type_Sem_Ptr := Param_Type;
        Assoc_Type : Type_Sem_Ptr := Originating_Type;
        Decl_Region : Symbols.Region_Ptr :=
          Region_Of_Module (Originating_Type.Outermost_Module_Where_Used))
        return Type_Sem_Ptr is
      --  Create type to represent named actual of formal
         Actual_Type : constant Type_Sem_Ptr :=
           Instantiate_Module
              (Formal_Type.Associated_Module,
               Actual_Params => (1 .. 0 => null),
               Decl_Region => Decl_Region,
               Is_Formal_Type => True,
               Enclosing_Type =>
                  Substitute_Actuals
                    (Formal_Type.Enclosing_Type,
                     Type_Region_Ptr (Assoc_Type),
                     Extra_Subst => Extra_Subst),
               Formal_Prefix =>
                  Combine_Names
                    (Enclosing_Prefix,
                     Formal_Type.Formal_Prefix),
               Associated_Generic_Op =>
                 Formal_Type.Associated_Generic_Op,
               Source_Pos =>
                  Find_Source_Pos
                    (Assoc_Type.Definition));
      begin
         if Debug_Second_Pass then
            Put_Line
              (" Creating actual-of-formal and substituting " &
               Type_Image (Actual_Type) &
               " for " &
               Type_Image (Formal_Type));
         end if;
         return Actual_Type;
      end Create_Actual_Of_Formal;

      function Substitute_Actuals_In_Qualified_Formal
        (Qualified_Formal : Optional_Tree;
         Actual_Instance : Type_Sem_Ptr)
         return Type_Sem_Ptr
      --  Return actual-of-actual corresponding to Qualified_Formal.
      --  Return null if no useful substitution can be made.
      is
         pragma Assert (Not_Null (Qualified_Formal));
         Qualified_Formal_Tree : Trees.Tree'Class
           renames Tree_Ptr_Of (Qualified_Formal).all;
         Actual_Type_To_Use : Type_Sem_Ptr := Actual_Instance.U_Base_Type;
      begin
         if Qualified_Formal_Tree in Qualified_Name.Tree then
            --  Recurse to get type of prefix
            if Debug_Second_Pass then
               Put_Line
                 (" Recursing with prefix of qualified formal " &
                  Subtree_Image (Qualified_Formal) &
                  "; Actual_Instance = " &
                  Type_Image (Actual_Instance));
            end if;
            Actual_Type_To_Use :=
              Substitute_Actuals_In_Qualified_Formal
                 (Qualified_Name.Tree (Qualified_Formal_Tree).Prefix,
                  Actual_Instance);
            if Debug_Second_Pass then
               Put_Line
                 (" Result of recursion = " & Type_Image (Actual_Type_To_Use));
            end if;
            if Actual_Type_To_Use = null then
               return null;
            end if;

            Actual_Type_To_Use := Actual_Type_To_Use.U_Base_Type;
         end if;

         --  Return corresponding actual
         declare
            Corresponding_Formal_Type : constant Type_Sem_Ptr :=
              Type_Sem_Ptr (Underlying_Sem_Info (Qualified_Formal));
            Module_Of_Formal : constant Module_Sem_Ptr :=
              Module_Sem_Ptr (
              Corresponding_Formal_Type.Associated_Symbol.Enclosing_Region.
                Associated_Symbol.Sem_Info);
            Corresponding_Formal_Index : constant Natural :=
              Formal_Type_Index (Corresponding_Formal_Type);

         begin
            --  Make sure we are talking about the same module
            if Actual_Type_To_Use.Associated_Module /= Module_Of_Formal then
               --  NOTE: Check parents and implements_interfaces tree and
               --       and make substitutions on the way "out".
               if Debug_Second_Pass then
                  Put_Line (" Substitute_Actuals_In_Qualified_Formal: " &
                     " Cannot directly substitute " &
                     Type_Image (Actual_Type_To_Use) &
                     " for " &
                     Sym_Name (Module_Of_Formal.Associated_Symbol) &
                     "; qualified_formal is " &
                     Subtree_Image (Qualified_Formal));
                  Put_Line (" Will search tree of implemented interfaces.");
               end if;

               declare
                  Progenitor_Type : constant Type_Sem_Ptr :=
                    Corresponding_Progenitor_Type
                       (Actual_Type_To_Use, Module_Of_Formal);
               begin

                  if Progenitor_Type = null then
                     if Debug_Second_Pass then
                        Put_Line (" Substitute_Actuals_In_Qualified_Formal: " &
                          "Type " &
                          Type_Image (Actual_Type_To_Use) &
                          " is not a descendant of interface " &
                          Sym_Name (Module_Of_Formal.Associated_Symbol));

                     end if;
                     return null;
                  end if;

                  Actual_Type_To_Use := Progenitor_Type;
                  pragma Assert
                    (Actual_Type_To_Use.Associated_Module = Module_Of_Formal);
               end;
            end if;

            if Actual_Type_To_Use.Associated_Module = Module_Of_Formal
              and then Actual_Type_To_Use.Actual_Sem_Infos /= null
              and then Corresponding_Formal_Index in
                 Actual_Type_To_Use.Actual_Sem_Infos'Range
            then
               --  We now have the right module; get the corresponding
               --  actual.
               declare
                  Actual_Sem : constant Sem_Ptr :=
                    Underlying_Sem_Info
                       (Actual_Type_To_Use.Actual_Sem_Infos
                          (Corresponding_Formal_Index));
               begin
                  if Actual_Sem = null then
                     if Actual_Type_To_Use.Is_Formal_Type
                       and then
                        Qualified_Formal_Tree in Qualified_Name.Tree
                     then
                        --  Create/return a corresponding actual-of-formal
                        declare
                           Qualified_Name_Prefix : constant Optional_Tree :=
                              Qualified_Name.Tree
                                (Qualified_Formal_Tree).Prefix;
                           Actual_Of_Formal : constant Type_Sem_Ptr :=
                             Create_Actual_Of_Formal (Qualified_Name_Prefix,
                               Formal_Type => Corresponding_Formal_Type,
                               Assoc_Type => Actual_Type_To_Use);
                        begin
                           if Debug_Second_Pass then
                              Put_Line
                                (" Creating an actual-of-formal " &
                                 Type_Image (Actual_Of_Formal) & " in " &
                                 Type_Image
                                   (Type_Sem_Ptr (Actual_Type_To_Use)) &
                                 " for qualified formal " &
                                 Subtree_Image (Qualified_Formal));
                           end if;

                           --  Save actual-of-formal for later use
                           Actual_Type_To_Use.Actual_Sem_Infos
                             (Corresponding_Formal_Index) :=
                                Sem_Ptr (Actual_Of_Formal);
                           --  and return it.
                           return Actual_Of_Formal;
                        end;
                     end if;
                  elsif Actual_Sem.all in Type_Semantic_Info then
                     if Debug_Second_Pass then
                        Put_Line
                          (" Substituting " &
                           Type_Image (Type_Sem_Ptr (Actual_Sem)) &
                           " for qualified formal " &
                           Subtree_Image (Qualified_Formal));
                     end if;
                     return Type_Sem_Ptr (Actual_Sem);
                  end if;
               end;
            end if;

            if Debug_Second_Pass then
               Put_Line (" Substitute_Actuals_In_Qualified_Formal: " &
                 "Unable to substitute for " &
                 Subtree_Image (Qualified_Formal));
            end if;
            return null;
         end;

      end Substitute_Actuals_In_Qualified_Formal;

   begin  --  Substitute_Actuals

      if Assoc_Type_Region = null or else Param_Type = null
        or else Param_Type.Associated_Module = null
      then
         --  Nothing to be substituted
         return Param_Type;
      elsif Ancestor_From_Formal_Module then
         --  Result should be from same module as Param_Type
         declare
            Result : Type_Sem_Ptr :=
              Substitute_Actuals
                 (Param_Type,
                  Assoc_Type_Region,
                  Extra_Subst => Extra_Subst,
                  Ancestor_From_Formal_Module => False);
            Formal_Module : constant Module_Sem_Ptr :=
              Param_Type.Associated_Module;
         begin
            if Result.Associated_Module /= Formal_Module then
               --  Get ancestor of Result that is from same module
               --  as Param_Type
               if Is_Proper_Ancestor
                    (Ancestor => Formal_Module,
                     Descendant => Result.Associated_Module)
               then
                  --  Walk up the parent chain until the modules match
                  loop
                     Result := Result.Parent_Type;
                     exit when Result.Associated_Module = Formal_Module;
                  end loop;
               else
                  Sem_Error
                    (Originating_Type.Definition,
                     "Internal: Unable to find ancestor of " &
                     Type_Image (Result) &
                     " that is of module " &
                     Sym_Name (Formal_Module.Associated_Symbol));
               end if;
            end if;
            return Result;
         end;
      elsif Extra_Subst /= null
        and then not Param_Type.Is_Polymorphic
        and then Is_In_Param_Map
                    (Sem_Ptr (Param_Type.U_Base_Type),
                     Extra_Subst)
      then
         --  Apply the "extra" substitution
         if Debug_Second_Pass then
            Put_Line
              (" Substitute_Actuals(" &
               Type_Image (Param_Type) &
               ", Extra_Subst => " &
               Param_Map_Image (Extra_Subst) & ") returns " &
               Type_Image (Type_Map_Of (Param_Type.U_Base_Type, Extra_Subst)));
         end if;
         --  TBD: Preserve Associated_Generic_Op if substitution is
         --      to a formal type?
         return Type_Map_Of (Param_Type.U_Base_Type, Extra_Subst);
      elsif U_Base_Type_Region (Param_Type) = Assoc_Type_Region
        and then (Extra_Subst = null or else Param_Type.All_Parameters_Known)
      then
         --  Nothing to be substituted
         return Param_Type;
      end if;
      if Debug_Second_Pass then
         Put
           (" Substitute_Actuals(" &
            Type_Image (Param_Type) &
            ", Assoc_Type_Region => " &
            Type_Image (Originating_Type));
         if Instantiation_Info /= null then
            Put (", Instantiation_Info => " &
              Subtree_Image (Instantiation_Info.Instantiation));
         end if;
         if Extra_Subst /= null then
            Put (", Extra_Subst => " & Param_Map_Image (Extra_Subst));
         end if;
         Put_Line (")");
      end if;
      if Param_Type.Associated_Module.Cur_Inst_Sem =
         Param_Type.U_Base_Type
      then
         --  We have a current instance;
         --  see whether Originating_Type is of same module
         --  or of an enclosing module or enclosed module.
         if Originating_Type.Associated_Module =
            Param_Type.Associated_Module
         then
            --  Same module.
            --  Substitute in Originating Type.
            if Debug_Second_Pass then
               Put_Line
                 (" Substituting " &
                  Type_Image (Originating_Type) &
                  " for cur inst type " &
                  Type_Image (Param_Type));
            end if;
            if Extra_Subst /= null
              and then not Originating_Type.Is_Polymorphic
              and then Is_In_Param_Map
                          (Sem_Ptr (Originating_Type.U_Base_Type),
                           Extra_Subst)

            then
               --  Extra_Subst matches *after* substitution
               if Debug_Second_Pass then
                  Put_Line
                    (" Substitute_Actuals(" &
                     Type_Image (Param_Type) &
                     ", Extra_Subst => " &
                     Param_Map_Image (Extra_Subst) & ") returns " &
                     Type_Image (Type_Map_Of
                       (Originating_Type.U_Base_Type, Extra_Subst)));
               end if;

               return Type_Map_Of (Originating_Type.U_Base_Type, Extra_Subst);
            else
               --  Replace current instance with Originating_Type.
               return Originating_Type;
            end if;
         elsif Param_Type.All_Parameters_Known then
            --  Nothing more to be substituted
            return Param_Type;

         elsif Originating_Type.Enclosing_Type /= null
           and then Region_Encloses_Region
                  (Encloser => Param_Type.Associated_Module.Nested_Region,
                   Enclosed =>
                     Originating_Type.Enclosing_Type.
                        Associated_Module.Nested_Region)
         then
            --  We have the current instance of an enclosing module.
            --  Use the enclosing type of Originating_Type to try
            --  to do the substitution.
            return Substitute_Actuals
                     (Param_Type,
                      Assoc_Type_Region =>
                         U_Base_Type_Region (Originating_Type.Enclosing_Type),
                      Extra_Subst => Extra_Subst,
                      Ancestor_From_Formal_Module =>
                        Ancestor_From_Formal_Module);

         elsif Param_Type.Enclosing_Type /= null
           and then Num_Module_Parameters (Param_Type.Associated_Module) = 0
           and then
              (Num_Module_Parameters
                  (Param_Type.Enclosing_Type.Associated_Module) = 0
                or else Region_Encloses_Region
                  (Encloser =>
                     Param_Type.Enclosing_Type.Associated_Module.Nested_Region,
                   Enclosed =>
                     Originating_Type.Associated_Module.Nested_Region))
         then
            --  Param_Type's module is a nested module and has no parameters.
            if Originating_Type = Param_Type.Enclosing_Type then
               --  Nothing to be substituted
               return Param_Type;
            end if;
            --  Create new type with substituted Enclosing_Type
            declare
               Substituted_Enc_Type : constant Type_Sem_Ptr :=
                 Substitute_Actuals
                    (Param_Type.Enclosing_Type,
                     Assoc_Type_Region,
                     Extra_Subst => Extra_Subst);
            begin
               if Substituted_Enc_Type /= Param_Type.Enclosing_Type then
                  --  Instantiate a new param type
                  declare
                     Type_With_New_Enc : constant Type_Sem_Ptr :=
                       Instantiate_Module
                          (Param_Type.Associated_Module,
                           Actual_Params => (1 .. 0 => null),
                           Decl_Region =>
                              Region_Of_Module
                                (Originating_Type.Outermost_Module_Where_Used),
                           Enclosing_Type => Substituted_Enc_Type,
                           Associated_Generic_Op =>
                             Param_Type.Associated_Generic_Op,
                           Source_Pos =>
                              Find_Source_Pos (Assoc_Type_Region.Definition));
                  begin
                     if Debug_Second_Pass then
                        Put_Line
                          (" Substituting " &
                           Type_Image (Type_With_New_Enc) &
                           " with new encloser for " &
                           Type_Image (Param_Type));
                     end if;
                     return Type_With_New_Enc;
                  end;
               end if;
            end;
         end if;

         if Originating_Type.Parent_Type /= null then
            --  Try again, but use parent type instead
            declare
               Param_Subst_From_Parent : constant Type_Sem_Ptr :=
                 Substitute_Actuals
                     (Param_Type,
                      Assoc_Type_Region =>
                         U_Base_Type_Region (Originating_Type.Parent_Type),
                      Extra_Subst => Extra_Subst,
                      Ancestor_From_Formal_Module =>
                        Ancestor_From_Formal_Module);
            begin
               if Types_Match
                   (Param_Subst_From_Parent, Originating_Type.Parent_Type)
                 and then Param_Subst_From_Parent.Associated_Module =
                   Originating_Type.Associated_Module
               then
                  --  If the substitution gets us back to the parent type,
                  --  then replace with the Originating type.
                  --  TBD: Does this really ever happen?
                  if Debug_Second_Pass then
                     Put_Line ("  Substitution of " & Type_Image (Param_Type)
                       & " using parent " &
                       Type_Image (Originating_Type.Parent_Type) &
                       " gave parent itself, so falling back to " &
                       Type_Image (Originating_Type));
                  end if;
                  return Originating_Type;
               else
                  --  Return result of substition using parent type.
                  return Param_Subst_From_Parent;
               end if;
            end;
         end if;

         if Num_Module_Parameters (Param_Type.Associated_Module) > 0
           and then
             Is_Ancestor (Ancestor => Originating_Type.Associated_Module,
               Descendant => Param_Type.Associated_Module)
         then
            --  Originating type is an ancestor of the Param_Type

            --  No change.
            --  TBD: Or should we return Originating_Type or
            --       Originating_Type cur-inst type?

            if Debug_Second_Pass then
               Put_Line (" TBD: In Substitute_Actuals, returning " &
                 Type_Image (Param_Type) &
                 " because " & Type_Image (Originating_Type) &
                 " is its ancestor");
            end if;
            return Param_Type;
         end if;

         if Num_Module_Parameters (Param_Type.Associated_Module) > 0 then
            --  Complain -- we don't know what to do with this current-inst.
            Sem_Error
              (Param_Type.Definition,
               "Internal: Param_Type is cur-inst " &
               "but not enclosing or enclosed");
         end if;

         --  Return as is
         return Param_Type;

      elsif Associated_Operation /= null
        and then Originating_Type.New_Type_Counter /= Anonymous_Type_Indicator
        and then Param_Type.New_Type_Counter /= Anonymous_Type_Indicator
        and then
          Param_Type.Associated_Module = Originating_Type.Associated_Module
        and then
          Is_Orig_Type_For_Ancestor (Ancestor => Param_Type,
            Descendant => Originating_Type)
        and then Associated_Operation.Enclosing_Region =
          Param_Type.U_Base_Type.Associated_Symbol.Enclosing_Region
        and then Associated_Operation.Enclosing_Region /=
          Originating_Type.U_Base_Type.Associated_Symbol.Enclosing_Region
      then
         --  Param_Type is the original type for
         --  some Ancestor of Originating_Type,
         --  so we inherit operations declared in same region as
         --  Param_Type (and different from Originating_Type)
         --  after systematically substituting Originating_Type for
         --  that original Param_Type.
         if Debug_Second_Pass then
            Put_Line
              (" Substituting " &
               Type_Image (Originating_Type) &
               " for ancestor ""new"" type " &
               Type_Image (Param_Type));
         end if;
         return Originating_Type;

      elsif Param_Type.All_Parameters_Known
        and then Extra_Subst = null
        and then not Originating_Type.Is_Formal_Type
      then
         --  Nothing more to be substituted
         return Param_Type;

      elsif Originating_Type.U_Base_Structure = null
        or else Is_Null (Originating_Type.U_Base_Structure.Definition)
      then
         --  We can't get information from associated type definition
         Sem_Error
           (Param_Type.Definition,
            "Internal: Assoc_Type_Region has no definition");
         return Param_Type;

      elsif Originating_Type.Parent_Type = null
        and then Extra_Subst = null
        and then Instantiation_Info = null
        and then
         (Tree_Ptr_Of (Originating_Type.U_Base_Structure.Definition).all not in
           Invocation.Tree
                 or else Originating_Type =
                         Originating_Type.Associated_Module.Cur_Inst_Sem)
      then
         --  Nothing to be substituted
         --## AdaMagic Bug: Can't call Tree_Of as part of a
         --   short-circuit operation.
         return Param_Type;

      elsif Is_Actual_Of_Formal (Param_Type) then
         --  This must be an actual-of-formal.

         declare
            Result : constant Type_Sem_Ptr :=
              Substitute_Actuals_In_Qualified_Formal
                (Qualified_Formal => Param_Type.Formal_Prefix,
                 Actual_Instance => Originating_Type);
         begin
            if Result /= null then
               return Result;
            else
               --  No substitution possible
               return Param_Type;
            end if;
         end;

      elsif Param_Type.Is_Formal_Type
       and then Param_Type.U_Base_Type /= Originating_Type
      then
         --  Should be replaced completely with corresponding actual
         if Instantiation_Info /= null then
            --  Handle special case where we are in the middle
            --  of doing an instantiation.
            return Substitute_Actuals_From_Instantiation
              (Decl_Region => Instantiation_Info.Decl_Region,
               Formal_Type => Param_Type,
               Instantiation_Module => Instantiation_Info.Instantiation_Module,
               Instantiation => Invocation.Tree (Tree_Ptr_Of
                 (Instantiation_Info.Instantiation).all),
               Enclosing_Type => Originating_Type);
         end if;

         declare
            Formal_Index : constant Natural := Formal_Type_Index (Param_Type);
            Assoc_Module : constant Module_Sem_Ptr :=
              Module_With_Formal_Type (Param_Type);

            Assoc_Type : Type_Sem_Ptr := Originating_Type;
            Outermost_Formal_Type : Type_Sem_Ptr := null;
         begin
            while Assoc_Type.Associated_Module /= Assoc_Module loop
               if Assoc_Type.Is_Formal_Type
                 and then Assoc_Type.Associated_Module.Treat_As_Type
               then
                  --  Remember outermost formal type
                  Outermost_Formal_Type := Assoc_Type;
               end if;
               Assoc_Type := Assoc_Type.Enclosing_Type;
               if Assoc_Type = null then
                  if Param_Type.Associated_Generic_Op /= null then
                     if Debug_Second_Pass then
                        Put_Line
                          ("Cannot find enclosing type info for " &
                           Type_Image (Param_Type) &
                           ", Originating_Type = " &
                           Type_Image (Originating_Type) &
                           ", Assoc_Module = " &
                           Sym_Name (Assoc_Module.Associated_Symbol));
                     end if;
                     if not All_Nulls (Param_Type.Actual_Sem_Infos) then
                        ---  try substituting in invocation.
                        return Substitute_Actuals_In_Nested_Type
                                 (Nested_Type => Param_Type,
                                  Assoc_Type_Region => Assoc_Type_Region,
                                  Instantiation_Info => Instantiation_Info,
                                  Extra_Subst => Extra_Subst);
                     end if;
                  elsif Param_Type.Associated_Module =
                      Originating_Type.Associated_Module
                    and then not All_Nulls (Originating_Type.Actual_Sem_Infos)
                  then
                     --  Originating_Type itself is a possible actual
                     return Originating_Type;
                  elsif Originating_Type.Parent_Type /= null then
                     --  Try again, but use parent type instead
                     declare
                        Param_Subst_From_Parent : constant Type_Sem_Ptr :=
                          Substitute_Actuals
                              (Param_Type,
                               Assoc_Type_Region =>
                                  U_Base_Type_Region
                                    (Originating_Type.Parent_Type),
                               Extra_Subst => Extra_Subst,
                               Ancestor_From_Formal_Module =>
                                 Ancestor_From_Formal_Module);
                     begin
                        if Types_Match
                            (Param_Subst_From_Parent,
                             Originating_Type.Parent_Type)
                          and then Param_Subst_From_Parent.Associated_Module =
                            Originating_Type.Associated_Module
                        then
                           --  If the substitution gets us back
                           --  to the parent type, then replace with the
                           --  Originating type.
                           --  TBD: Does this really ever happen?
                           return Originating_Type;
                        else
                           --  Return result of substition using parent type.
                           return Param_Subst_From_Parent;
                        end if;
                     end;
                  else
                     if Debug_Second_Pass then
                        Put_Line
                          ("Possible error: " &
                           "Cannot find enclosing type information, " &
                           "Originating_Type = " &
                           Type_Image (Originating_Type) &
                           "Assoc_Module = " &
                           Sym_Name (Assoc_Module.Associated_Symbol));
                     end if;
                  end if;
                  return Param_Type;
               end if;
            end loop;

            if Assoc_Type.Actual_Sem_Infos = null
              and then Outermost_Formal_Type /= null
              and then Assoc_Type = Outermost_Formal_Type.Enclosing_Type
              and then Outermost_Formal_Type.Actual_Sem_Infos /= null
              and then Outermost_Formal_Type.Associated_Module.Treat_As_Type
              and then Formal_Index in
                Outermost_Formal_Type.Actual_Sem_Infos'Range
            then
               --  Use nested formal type rather than parameterized
               --  enclosing package cur-inst.
               Assoc_Type := Outermost_Formal_Type;
            end if;

            if Assoc_Type.Actual_Sem_Infos /= null
              and then Formal_Index in Assoc_Type.Actual_Sem_Infos'Range
            then
               --  We have a suitably large array of actuals
               declare
                  Actual_Sem : Sem_Ptr :=
                    Assoc_Type.Actual_Sem_Infos (Formal_Index);
               begin
                  if Actual_Sem /= null
                    and then Actual_Sem.all in Type_Semantic_Info
                  then
                     --  We have an actual type
                     if Debug_Second_Pass then
                        Put_Line
                          (" Substituting actual " &
                           Type_Image (Type_Sem_Ptr (Actual_Sem)) &
                           " for " &
                           Type_Image (Param_Type));
                     end if;
                     return Type_Sem_Ptr (Actual_Sem);
                  elsif Actual_Sem /= null then
                     if Debug_Second_Pass then
                        Put_Line
                          (" NOT Substituting non-type " &
                           Subtree_Image
                              (Actual_Sem.Definition,
                               Use_Short_Form => True) &
                           " with sem-kind " &
                           Ada.Tags.External_Tag (Actual_Sem'Tag) &
                           " for " &
                           Type_Image (Param_Type));
                     end if;
                     return Param_Type; --  TBD ***
                  elsif not Assoc_Type.Is_Formal_Type then
                     Sem_Error
                       (Assoc_Type.Definition,
                        "Internal: Expected to be a formal type");
                     return Param_Type;
                  else
                     --  Create type to represent named actual of formal
                     declare
                        Actual_Type : constant Type_Sem_Ptr :=
                          Create_Actual_Of_Formal (Assoc_Type.Formal_Prefix);
                     begin
                        --  Remember actual for future use
                        Assoc_Type.Actual_Sem_Infos (Formal_Index) :=
                          Sem_Ptr (Actual_Type);

                        if Debug_Second_Pass then
                           Put_Line
                             (" Storing new type in " &
                              Type_Image (Assoc_Type) &
                              ".Actual_Sem_Infos(" &
                              Natural'Image (Formal_Index) &
                              " ) which was " &
                              Type_Image (Type_Sem_Ptr (Actual_Sem)));
                        end if;
                        return Actual_Type;
                     end;
                  end if;
               end;
            else
               if Debug_Second_Pass or Debug_Substitution then
                  Put_Line (" Substitute_Actuals: Assoc Type has no actuals; "
                    & "cannot substitute for " & Type_Image (Param_Type));
               end if;
               return Param_Type;
            end if;
         end;

      elsif Param_Type.New_Type_Counter /= Anonymous_Type_Indicator then
         --  Substitute in "new" type
         return Substitute_Actuals_In_New_Type
            (Nested_Type => Param_Type,
             Assoc_Type_Region => Assoc_Type_Region,
             Instantiation_Info => Instantiation_Info,
             Extra_Subst => Extra_Subst);

      elsif Param_Type.Func_Type_Op_Sem /= null then
         --  We have a func type; substitute into parameter types
         return Substitute_Actuals_In_Func_Type
                  (Func_Type => Param_Type,
                   Assoc_Type_Region => Assoc_Type_Region,
                   Extra_Subst => Extra_Subst);

      elsif Param_Type.U_Base_Type = null then
         --  Nothing to substitute
         return Param_Type;
      else
         --  Must be a nested type; needs something substituted in one
         --  of the actuals to the instantiation defining the type.
         --  Create a new instantiation of the same module
         --  with the actual substituted.
         pragma Assert
           (Param_Type.U_Base_Type.Nested_Type_Index > 0
           or else Param_Type.Associated_Module.Is_Abstract
           or else Param_Type.Associated_Module.Is_Partially_Abstract
           or else Extra_Subst /= null
           or else Originating_Type.Is_Formal_Type);

         return Substitute_Actuals_In_Nested_Type
                  (Nested_Type => Param_Type,
                   Assoc_Type_Region => Assoc_Type_Region,
                   Instantiation_Info => Instantiation_Info,
                   Extra_Subst => Extra_Subst);
      end if;

   end Substitute_Actuals;

   function Substitute_In_Tree
     (OT : Optional_Tree;
      Assoc_Type_Region : Type_Region_Ptr;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null;
      Always_Copy_One_Level : Boolean := False;
      Always_Copy_Tree : Boolean := False)
      return Optional_Tree
   is
      --  Walk the tree and replace parameters, etc.
      --  based on actual type.
      --  If Always_Copy_One_Level is True, then force a one-level
      --  copy of the tree, even if no substitutions are made.
      --  If Always_Copy_Tree is True, then force a complete
      --  copy of the tree, even if no substitutions are made.
      Copy_This_Level : constant Boolean :=
        Always_Copy_One_Level or Always_Copy_Tree;
      Prefix_Type_Region : Type_Region_Ptr := Assoc_Type_Region;
   begin
      if Is_Null (OT)
        or else (Assoc_Type_Region = null
                and then Extra_Subst = null
                and then not Copy_This_Level)
      then
         return OT;
      else
         declare
            Resolved_Ot : constant Optional_Tree := Resolved_Tree (OT);
            Orig_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Resolved_Ot).all;
            N : constant Natural := Num_Operands (Orig_Tree);
            Result : Optional_Tree := Resolved_Ot;
            Orig_Sem : constant Sem_Ptr := Underlying_Sem_Info (Resolved_Ot);

            function Orig_Sem_Tag return String is
            --  Return Expanded_Name (Orig_Sem'Tag) if Orig_Sem /= null
            --  else return "null"
            begin
               if Orig_Sem /= null then
                  return Ada.Tags.Expanded_Name (Orig_Sem'Tag);
               else
                  return "null";
               end if;
            end Orig_Sem_Tag;
         begin
            if Debug_Substitution then
               Put_Line
                 (" -->Substitute_In_Tree(" &
                  Subtree_Image (OT) & " : " & Orig_Sem_Tag & ", " &
                  Type_Image (Type_Sem_Ptr (Assoc_Type_Region)) &
                  ")");
            end if;
            if Orig_Tree in Qualified_Name.Tree then
               --  Substitute in prefix and then use
               --  that to substitute in id.
               declare
                  Qn_Tree : Qualified_Name.Tree renames Qualified_Name.Tree (
                    Orig_Tree);
                  Prefix_Type : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (Underlying_Sem_Info (Qn_Tree.Prefix));
                  New_Prefix  : constant Optional_Tree :=
                     Substitute_In_Tree
                       (Qn_Tree.Prefix,
                        Assoc_Type_Region,
                        Extra_Subst => Extra_Subst,
                        Always_Copy_One_Level => Always_Copy_One_Level,
                        Always_Copy_Tree => Always_Copy_Tree);
                  New_Prefix_Type : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (Underlying_Sem_Info (New_Prefix));
               begin
                  if New_Prefix_Type /= null
                    and then U_Base_Type_Region (New_Prefix_Type) /=
                                Assoc_Type_Region
                  then
                     --  Build a new Id part
                     declare
                        Id_Tree : Identifier.Tree renames Identifier.Tree
                          (Tree_Ptr_Of (Qn_Tree.Id).all);
                        New_Id : constant Optional_Tree :=
                          Identifier.Substitute_Operands (Id_Tree,
                            (1 .. 0 => Null_Optional_Tree));
                     begin
                        --  Remember new prefix region
                        Prefix_Type_Region :=
                          U_Base_Type_Region (New_Prefix_Type);
                        Result := Substitute_Operands
                           (Orig_Tree, (New_Prefix, New_Id));
                        if Debug_Substitution then
                           Put_Line
                             (" <--Substitute_In_Tree: Qualified_Name Orig = "
                              & Subtree_Image (OT,
                                Use_Short_Form => True) & " (Resolved: " &
                              Subtree_Image (Resolved_Ot,
                                Use_Short_Form => True) &
                              "), Result = " &
                              Subtree_Image (Result, Use_Short_Form => True));
                        end if;
                     end;
                  end if;
               end;

            elsif N > 0 or else Copy_This_Level
              or else (Orig_Sem /= null
                 and then Orig_Sem.all in Operand_Semantic_Info'Class
                 and then Operand_Sem_Ptr (Orig_Sem).Resolved_Type /= null
                 and then not Operand_Sem_Ptr
                   (Orig_Sem).Resolved_Type.All_Parameters_Known)
            then
               --  Make replacements
               declare
                  New_Operands : Tree_Array (1 .. N);
                  Something_Changed : Boolean := False;
                  Extra_Subst_To_Use : Param_Mapping_Ptr := Extra_Subst;
               begin
                  if Extra_Subst /= null
                    and then Orig_Sem /= null
                    and then Orig_Sem.all in Type_Semantic_Info
                    and then Type_Sem_Ptr (Orig_Sem).Is_Polymorphic
                  then
                     --  We have a polymorphic type.
                     --  Prevent substitution of root type.
                     Extra_Subst_To_Use := null;
                  end if;

                  for I in 1 .. N loop
                     declare
                        Old_Operand : constant Optional_Tree :=
                          Nth_Operand (Orig_Tree, I);
                        New_Operand : constant Optional_Tree :=
                          Substitute_In_Tree  --  TBD: S_A_In_Operand
                             (Old_Operand,
                              Assoc_Type_Region,
                              Extra_Subst => Extra_Subst_To_Use,
                              Always_Copy_Tree => Always_Copy_Tree);
                     --  Recurse on each operand
                     begin
                        if New_Operand /= Old_Operand then
                           --  Something is different.  Update New_Tree.
                           Something_Changed := True;
                        end if;
                        New_Operands (I) := New_Operand;
                     end;
                  end loop;
                  if Something_Changed or Copy_This_Level or N = 0 then
                     --  At least one operand is different, or we always copy
                     --  Create a new optional tree with new operands
                     Result :=
                        Substitute_Operands (Orig_Tree, New_Operands);
                  end if;
               end;
            end if;

            if Result /= Resolved_Ot then
               --  Update the Sem info
               declare
                  New_Sem_Info : Root_Sem_Ptr := Sem_Info (Resolved_Ot);
                  Orig_Resolved_Type : Type_Sem_Ptr;
               begin
                  if New_Sem_Info = null then
                     --  No semantic info to worry about
                     null;
                  elsif New_Sem_Info.all in Type_Semantic_Info then
                     --  Wipe out semantic info if this is a new type
                     if Debug_Substitution then
                        Put_Line ("  Substitute_In_Tree: nulling out " &
                          "Sem_Info (Result)");
                     end if;
                     New_Sem_Info := null;
                  else
                     --  Make a copy of sem info so we can update the
                     --  Definition and Resolved_Type field
                     New_Sem_Info :=
                       new Root_Semantic_Info'Class'(New_Sem_Info.all);
                     New_Sem_Info.Definition := Result;

                     if New_Sem_Info.all in
                       Operand_Semantic_Info'Class
                     then
                        --  The tree can be an operand

                        if Operand_Sem_Ptr
                            (New_Sem_Info).Resolved_Interp = OT
                          or else
                            Operand_Sem_Ptr
                              (New_Sem_Info).Resolved_Interp =
                                Resolved_Ot
                        then
                           --  Set resolved-interp to point to new tree
                           Operand_Sem_Ptr
                             (New_Sem_Info).Resolved_Interp := Result;
                           if Debug_Substitution then
                              Put_Line ("  Substitute_In_Tree: " &
                                "Changing Resolved_Interp");
                           end if;
                        end if;

                        --  Substitute into the Resolved_Type
                        Orig_Resolved_Type :=
                          Operand_Sem_Ptr (New_Sem_Info).Resolved_Type;

                        Operand_Sem_Ptr (New_Sem_Info).Resolved_Type :=
                           Substitute_Actuals
                             (Operand_Sem_Ptr (New_Sem_Info).
                                Resolved_Type,
                              Assoc_Type_Region,
                              Instantiation_Info => Instantiation_Info,
                              Extra_Subst => Extra_Subst);
                        if Debug_Substitution then
                           if not Types_Match
                             (Resolved_Type (Resolved_Ot),
                              Operand_Sem_Ptr
                                (New_Sem_Info).Resolved_Type)
                           then
                              Put_Line ("  Substitute_In_Tree: " &
                                " Orig resolved type = " &
                                Type_Image (Orig_Resolved_Type) &
                                ", New resolved type = " &
                                Type_Image (Operand_Sem_Ptr
                                  (New_Sem_Info).Resolved_Type));
                           end if;
                        end if;

                        --  Substitute into Target_Polymorphic_Type
                        Operand_Sem_Ptr (New_Sem_Info).Target_Polymorphic_Type
                           :=
                           Substitute_Actuals
                             (Operand_Sem_Ptr (New_Sem_Info).
                                Target_Polymorphic_Type,
                              Assoc_Type_Region,
                              Instantiation_Info => Instantiation_Info,
                              Extra_Subst => Extra_Subst);

                        if New_Sem_Info.all in
                          Sym_Reference_Info'Class
                        then
                           --  Make a copy of the underlying sem info
                           --  also
                           declare
                              New_Ref_Info : constant Sym_Ref_Ptr :=
                                Sym_Ref_Ptr (New_Sem_Info);
                           begin
                              if New_Ref_Info.Underlying_Sem_Info =
                                 null
                              then
                                 --  No substitution to be made.
                                 null;
                              elsif New_Ref_Info.Underlying_Sem_Info.all
                                in Operand_Semantic_Info'Class
                              then
                                 New_Ref_Info.Underlying_Sem_Info :=
                                   new Semantic_Info'Class'(
                                   New_Ref_Info.Underlying_Sem_Info.all);
                                 --  Copy over updated resolved type
                                 Operand_Sem_Ptr (
                                   New_Ref_Info.Underlying_Sem_Info).
                                     Resolved_Type :=
                                   New_Ref_Info.Resolved_Type;
                                 if Debug_Substitution then
                                    Put_Line ("  Substitute_In_Tree: " &
                                      " Setting resolved_type in new " &
                                      "underlying_sem for operand to " &
                                      Type_Image
                                        (New_Ref_Info.Resolved_Type));
                                 end if;
                              elsif New_Ref_Info.Underlying_Sem_Info.all
                                   in Type_Semantic_Info'Class
                              --  tbd:stt and then
                              --       New_Ref_Info.Resolved_Type.
                              --                 All_Parameters_Known
                              then
                                 --  Copy over resolved type
                                 --  as new underlying sem info.
                                 --  TBD: Should we change Id too?
                                 New_Ref_Info.Underlying_Sem_Info :=
                                   Sem_Ptr (New_Ref_Info.Resolved_Type);
                                 if Debug_Substitution then
                                    Put_Line ("  Substitute_In_Tree: " &
                                      " Setting underlying_sem to " &
                                      "new resolved type " &
                                      Type_Image
                                        (New_Ref_Info.Resolved_Type));
                                 end if;
                              end if;
                           end;
                        elsif New_Sem_Info.all in
                          Resolved_Operation_Info'Class
                        then
                           --  Make a copy of the associated Op_Sem also
                           --  and substitute into the Assoc_Type_Region
                           declare
                              Resolved_Op_Sem : constant Resolved_Op_Ptr
                                := Resolved_Op_Ptr (New_Sem_Info);
                              Op_Sem_Copy : constant Operation_Sem_Ptr :=
                                new Operation_Semantic_Info'
                                  (Resolved_Op_Sem.Op_Sem.all);
                           begin
                              Resolved_Op_Sem.Op_Sem := Op_Sem_Copy;
                              if Resolved_Op_Sem.Assoc_Type_Region /=
                                null
                              then
                                 --  Update the Assoc_Type_Region
                                 Resolved_Op_Sem.Assoc_Type_Region :=
                                   Type_Region_Ptr (Substitute_Actuals
                                     (Type_Sem_Ptr (Resolved_Op_Sem.
                                        Assoc_Type_Region),
                                      Assoc_Type_Region,
                                      Instantiation_Info =>
                                        Instantiation_Info,
                                      Extra_Subst => Extra_Subst));
                              end if;
                           end;
                        elsif New_Sem_Info.all in
                          Iterator_Semantic_Info
                        then
                           --  We need to substitute into all of the various
                           --  types that are part of the
                           --  Iterator_Semantic_Info, and the Key_Sem.
                           Iterator_Sem_Ptr (New_Sem_Info).Iteration_Type :=
                              Substitute_Actuals
                                (Iterator_Sem_Ptr (New_Sem_Info).
                                   Iteration_Type,
                                 Assoc_Type_Region,
                                 Instantiation_Info => Instantiation_Info,
                                 Extra_Subst => Extra_Subst);
                           Iterator_Sem_Ptr (New_Sem_Info).Index_Set_Type :=
                              Substitute_Actuals
                                (Iterator_Sem_Ptr (New_Sem_Info).
                                   Index_Set_Type,
                                 Assoc_Type_Region,
                                 Instantiation_Info => Instantiation_Info,
                                 Extra_Subst => Extra_Subst);
                           if Iterator_Sem_Ptr (New_Sem_Info).Key_Sem /=
                             null
                           then
                              --  Need to update Key_Sem's type
                              declare
                                 Key_Sem_Info : Param_Sem_Ptr renames
                                   Iterator_Sem_Ptr (New_Sem_Info).Key_Sem;
                                 New_Resolved_Type : constant Type_Sem_Ptr :=
                                    Substitute_Actuals
                                      (Key_Sem_Info.Resolved_Type,
                                       Assoc_Type_Region,
                                       Instantiation_Info =>
                                         Instantiation_Info,
                                       Extra_Subst => Extra_Subst);
                              begin
                                 if New_Resolved_Type /=
                                   Key_Sem_Info.Resolved_Type
                                 then
                                    --  Type has changed, copy Key_Sem
                                    Key_Sem_Info :=
                                      new Param_Semantic_Info'Class'
                                        (Key_Sem_Info.all);
                                    Key_Sem_Info.Resolved_Type :=
                                      New_Resolved_Type;
                                    if Not_Null (Key_Sem_Info.Definition) then
                                       --  Update identifier if non-null
                                       Key_Sem_Info.Definition :=
                                         Identifier.Make
                                           (Str => Identifier.Tree (Tree_Ptr_Of
                                              (Key_Sem_Info.Definition).all).
                                                 Str,
                                         Source_Pos => Find_Source_Pos
                                           (Key_Sem_Info.Definition));
                                       Set_Sem_Info (Key_Sem_Info.Definition,
                                         Root_Sem_Ptr (Key_Sem_Info));
                                    end if;
                                 end if;
                              end;
                           end if;
                        elsif New_Sem_Info.all in
                          For_Loop_Construct_Semantic_Info
                        then
                           --  Update Iterator_Sems and Loop_Result_Type
                           declare
                              For_Loop : For_Loop_Construct.Tree renames
                                For_Loop_Construct.Tree
                                  (Tree_Ptr_Of (Result).all);
                              For_Loop_Sem : constant
                                For_Loop_Construct_Sem_Ptr :=
                                  For_Loop_Construct_Sem_Ptr (New_Sem_Info);
                           begin
                              For_Loop_Construct_Sem_Ptr (New_Sem_Info).
                                Loop_Result_Type :=
                                  Substitute_Actuals
                                    (For_Loop_Construct_Sem_Ptr (New_Sem_Info).
                                       Loop_Result_Type,
                                     Assoc_Type_Region,
                                     Instantiation_Info => Instantiation_Info,
                                     Extra_Subst => Extra_Subst);
                              For_Loop_Sem.Iterator_Sems :=
                                new Iterator_Sem_Array
                                  (1 .. Lists.Length (For_Loop.Iterators));
                              for I in For_Loop_Sem.Iterator_Sems'Range loop
                                 declare
                                    Ith_Iterator : constant Iterator_Sem_Ptr :=
                                      Iterator_Sem_Ptr
                                        (Sem_Info
                                          (Lists.Nth_Element
                                            (For_Loop.Iterators, I)));
                                 begin
                                    For_Loop_Sem.Iterator_Sems (I) :=
                                      Ith_Iterator;
                                    Ith_Iterator.Enclosing_For_Loop :=
                                      For_Loop_Sem;
                                 end;
                              end loop;
                           end;
                        end if;
                     end if;
                  end if;
                  --  Copy over sem info, with new Definition
                  Set_Sem_Info (Result, New_Sem_Info);
                  --  TBD: Should we re-analyze instead?

                  if Orig_Tree in Qualified_Name.Tree then
                     --  Copy sem info down onto "Id" tree as well
                     Set_Sem_Info (Qualified_Name.Tree
                                    (Tree_Ptr_Of (Result).all).Id,
                                   New_Sem_Info);
                  end if;
               end;
            end if;

            --  See whether we have a formal parameter of some sort
            declare
               Tree_Sem : constant Sem_Ptr := Underlying_Sem_Info (Result);
               --  TBD: We might be losing prefix information here
               Prefix_Type : constant Type_Sem_Ptr :=
                 Type_Sem_Ptr (Prefix_Type_Region);
               Check_Type : Boolean := True;
               use type Symbols.Region_Kind_Enum;
            begin
               if Tree_Sem /= null
                 and then Tree_Sem.all in Param_Semantic_Info
                 and then Orig_Tree not in Param_Decl.Tree --  ignore param def
                 and then Prefix_Type /= null
               then
                  --  We have a parameter of some kind
                  declare
                     Ancestor_Type : Type_Sem_Ptr := Prefix_Type;
                  begin
                     if Debug_Second_Pass
                       and then
                         Tree_Sem.Associated_Symbol.Enclosing_Region.Kind =
                           Symbols.Module_Region_Kind
                     then
                        --  Give some output when we hit a reference to a
                        --  module parameter.
                        Put
                          ("  Substitute_In_Tree(" &
                           Subtree_Image (Result, Use_Short_Form => True) &
                           ", " &
                           Type_Image (Prefix_Type));
                        if Instantiation_Info /= null then
                           Put (", Instantiation_Info => " &
                             Subtree_Image
                               (Instantiation_Info.Instantiation,
                                Use_Short_Form => True));
                        end if;
                        if Extra_Subst /= null then
                           Put
                             (", Extra_Subst => " &
                              Param_Map_Image (Extra_Subst));
                        end if;
                        Put_Line (");");
                     end if;

                     while Ancestor_Type /= null
                       and then Tree_Sem.Associated_Symbol.Enclosing_Region /=
                                Ancestor_Type.Associated_Module.Nested_Region
                     loop
                        Ancestor_Type := Ancestor_Type.Parent_Type;
                     end loop;

                     if Ancestor_Type /= null then
                        --  it is a module parameter of some ancestor.
                        --  Try to replace it.
                        declare
                           Formal_Index : constant Natural :=
                             Module_Formal_Index (Tree_Sem.Associated_Symbol);
                        begin
                           if Ancestor_Type.Actual_Sem_Infos /= null
                             and then Formal_Index in
                                Ancestor_Type.Actual_Sem_Infos'Range
                             and then Ancestor_Type.Actual_Sem_Infos (
                                Formal_Index) /=
                                      null
                           then
                              declare
                                 Actual_Param : constant Optional_Tree :=
                                   Ancestor_Type.Actual_Sem_Infos (
                                   Formal_Index).Definition;
                              begin
                                 if Not_Null (Actual_Param) then
                                    Result := Resolved_Tree (Actual_Param);
                                    if Debug_Substitution then
                                       Put_Line ("  Substitute_In_Tree: " &
                                         " Replaced formal " &
                                         Subtree_Image (Tree_Sem.Definition,
                                           Use_Short_Form => True)
                                         & " with actual " &
                                         Subtree_Image (Actual_Param,
                                           Use_Short_Form => True));
                                    end if;
                                 end if;
                              end;
                           end if;
                        end;

                     elsif Prefix_Type.Enclosing_Type /= null
                       and then
                         Tree_Sem.Associated_Symbol.Enclosing_Region.Kind =
                           Symbols.Module_Region_Kind
                     then
                        --  Is from a module's region, and Prefix_Type is
                        --  from a nested module, so try substituting using
                        --  the enclosing type.
                        Result :=
                           Substitute_In_Tree
                             (Result,
                              U_Base_Type_Region (Prefix_Type.Enclosing_Type),
                              Extra_Subst => Extra_Subst);
                     end if;  --  Whether is from a module's region

                  end;
               end if;  --  Whether is a ref to a parameter

               if Extra_Subst /= null then
                  --  Now check for extra substitution
                  declare
                     Result_Sem : Sem_Ptr :=
                       Underlying_Sem_Info (Result);
                  begin
                     if Result_Sem = null
                       and then Orig_Sem /= null
                       and then Orig_Sem.all in Type_Semantic_Info
                     then
                        --  Use the original sem if was a type
                        Result_Sem := Sem_Ptr (Type_Sem_Ptr (Orig_Sem).U_Type);
                     end if;

                     if Result_Sem /= null
                       and then Is_In_Param_Map (Result_Sem, Extra_Subst)
                     then
                        Result :=
                          Param_Map_Of (Result_Sem, Extra_Subst).Definition;
                        --  Don't try to substitute again
                        Check_Type := False;
                        if Debug_Substitution then
                           Put_Line
                             ("  Substitute_In_Tree: Using Extra_Subst" &
                              " to produce " & Subtree_Image (Result,
                              Use_Short_Form => True));
                        end if;
                     end if;
                  end;
               end if;

               if Check_Type
                 and then Tree_Sem /= null
                 and then Tree_Sem.all in Type_Semantic_Info
                 and then Orig_Tree in Identifier.Tree --  ref to type
                 and then Prefix_Type_Region /= null
               then
                  --  We have a reference to a type
                  if Debug_Substitution then
                     Put_Line ("  About to call Substitute_Actuals(" &
                        Type_Image (Type_Sem_Ptr (Tree_Sem)) & ", " &
                        Type_Image (Type_Sem_Ptr (Prefix_Type_Region)) & ")");
                     Put_Line ("   Is_Cur_Inst_Sem = " &
                       Boolean'Image
                         (Type_Sem_Ptr
                           (Tree_Sem).Associated_Module.Cur_Inst_Sem =
                          Type_Sem_Ptr (Tree_Sem).U_Base_Type));
                     Put_Line ("   All_Params_Known = " &
                       Boolean'Image
                         (Type_Sem_Ptr
                           (Tree_Sem).All_Parameters_Known));
                  end if;
                  declare
                     Orig_Type : constant Type_Sem_Ptr :=
                       Type_Sem_Ptr (Tree_Sem);
                     Subst_Type : constant Type_Sem_Ptr :=
                       Substitute_Actuals
                         (Orig_Type, Prefix_Type_Region,  --  No Extra_Subst
                          Instantiation_Info => Instantiation_Info);
                  begin
                     if Subst_Type.U_Base_Type /= Orig_Type.U_Base_Type then
                        --  Make the substitution
                        Set_Sem_Info (Result, Root_Sem_Ptr (Subst_Type));
                        if Debug_Substitution then
                           Put_Line ("  Substitute_In_Tree: Type changed to "
                             & Type_Image (Subst_Type) & " (was " &
                             Type_Image (Orig_Type) & ")");
                        end if;
                     end if;
                  end;
               end if;
            end;
            if Debug_Substitution then
               Put_Line
                 (" <--Substitute_In_Tree: Orig = " &
                  Subtree_Image (OT, Use_Short_Form => True) & " (Resolved: " &
                  Subtree_Image (Resolved_OT, Use_Short_Form => True) &
                  "), Result = " &
                  Subtree_Image (Result, Use_Short_Form => True));
               declare
                  New_Sem_Info : constant Sem_Ptr :=
                    Underlying_Sem_Info (Result);
               begin
                  if Orig_Sem /= null
                    and then Orig_Sem.all in Type_Semantic_Info
                    and then New_Sem_Info /= null
                    and then New_Sem_Info.all in Type_Semantic_Info
                    and then not Types_Match (Type_Sem_Ptr (Orig_Sem),
                      Type_Sem_Ptr (New_Sem_Info))
                  then
                     Put_Line ("   Orig_Type = " &
                       Type_Image (Type_Sem_Ptr (Orig_Sem)) &
                       ", Result_Type = " &
                       Type_Image (Type_Sem_Ptr (New_Sem_Info)));
                  end if;
               end;
            end if;
            return Result;
         end;
      end if;
   end Substitute_In_Tree;

   function Substitute_Actuals_In_Operand
     (Operand : Optional_Tree;
      Assoc_Type_Region : Type_Region_Ptr;
      Instantiation_Info : Instantiation_Info_Ptr := null;
      Extra_Subst : Param_Mapping_Ptr := null;
      Always_Copy_Tree : Boolean := False)
      return Optional_Tree
   is
      --  Replace any use of module formal parameters with actual parameters
      --  in the given operand.
      Operand_Sem : constant Sem_Ptr := Underlying_Sem_Info (Operand);
   begin
      if Operand_Sem = null then
         --  No substitution without semantic info
         return Operand;
      elsif Operand_Sem.all in Type_Semantic_Info then
         --  We have a type operand
         declare
            Substituted_Type : constant Type_Sem_Ptr :=
              Substitute_Actuals
                 (Type_Sem_Ptr (Operand_Sem),
                  Assoc_Type_Region,
                  Instantiation_Info => Instantiation_Info,
                  Extra_Subst => Extra_Subst);
            Def_Sem : constant Sem_Ptr :=
              Sem_Ptr (Sem_Info (Substituted_Type.Definition));
         begin
            if Def_Sem.all in Type_Semantic_Info then
               --  OK, we have a definition whose sem info is a type
               return Substituted_Type.Definition;
            else
               --  Trouble, sem-info on definition isn't a type
               --  TBD: Try to understand why!
               Sem_Error (Operand, "Internal: Unable to substitute for type");
               return Operand;
            end if;
         end;
      elsif Operand_Sem.all in Operand_Semantic_Info'Class then
         --  We have an expression of some sort.
         --  Walk the tree and replace parameters, etc.
         return Substitute_In_Tree
                  (Operand,
                   Assoc_Type_Region,
                   Extra_Subst => Extra_Subst,
                   Always_Copy_Tree => Always_Copy_Tree);
         --  TBD: Handle operation parameters
      end if;
      return Operand;
   end Substitute_Actuals_In_Operand;

   function Substitute_Actuals_From_Instantiation
     (Decl_Region : Symbols.Region_Ptr;
      Formal_Type : Type_Sem_Ptr;
      Instantiation_Module : Module_Sem_Ptr;
      Instantiation : Invocation.Tree;
      Enclosing_Type : Type_Sem_Ptr)
      return Type_Sem_Ptr
   is
      --  Return Formal_Type, possibly replace with actual type
      --  from Instantiation of given module with given Enclosing_Type.
      --  Requires: Formal_Type is a formal type
      use type Invocation.Invocation_Kind_Enum;
      pragma Assert (Formal_Type.Is_Formal_Type);
      pragma Assert (Instantiation.Kind = Invocation.Module_Instantiation);
      use type Symbols.Region_Ptr;
      use type Symbols.Sym_Ptr;
   begin
      if Formal_Type.Associated_Symbol = null then
         --  TBD: Not obvious how to improve this; would need
         --      to substitute inside of it.
         return Formal_Type;
      elsif Formal_Type.Associated_Symbol.Enclosing_Region =
            Instantiation_Module.Nested_Region
      then
         --  We are using a formal type from the module being
         --  instantiated.
         --  Scan the operands looking for the corresponding actual type.
         for I in 1 .. Lists.Length (Instantiation.Operands) loop
            declare
               Operand : constant Optional_Tree :=
                 Lists.Nth_Element (Instantiation.Operands, I);
               Operand_Tree : Trees.Tree'Class
                 renames Tree_Ptr_Of (Operand).all;
            begin
               if Operand_Tree in Reference.Tree then
                  --  We have a named operand
                  declare
                     Name_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                             (Reference.Tree (
                       Operand_Tree).Key).all;
                  begin
                     if Name_Tree in Identifier.Tree
                       and then Identifier.Tree (Name_Tree).Str =
                                Formal_Type.Associated_Symbol.Str
                     then
                        --  Found it
                        return Get_Type
                                 (Decl_Region,
                                  Reference.Tree (Operand_Tree).Referent);
                     end if;
                  end;
               else
                  --  We have a positional operand
                  declare
                     Nth_Formal : Trees.Tree'Class
                       renames Tree_Ptr_Of (Nth_Module_Parameter
                         (Instantiation_Module, I)).all;
                  begin
                     if Nth_Formal in Type_Decl.Tree
                       and then Type_Sem_Ptr (
                          Type_Decl.Tree (Nth_Formal).Sem_Info).
                            Associated_Symbol.Str =
                              Formal_Type.Associated_Symbol.Str
                     then
                        --  Found it; return type from actual operand
                        return Get_Type (Decl_Region, Operand);
                     end if;
                  end;
               end if;
            end;
         end loop;

         --  Not found??
         Sem_Error
           (Formal_Type.Definition,
            "Internal: Unable to find corresponding actual");

      elsif Enclosing_Type /= null
        and then Region_Encloses_Region
                    (Encloser =>
                       Formal_Type.Associated_Symbol.Enclosing_Region,
                     Enclosed => Instantiation_Module.Nested_Region)
      then
         --  We have a formal type from an enclosing module

         return Substitute_Actuals
                  (Formal_Type,
                   U_Base_Type_Region (Enclosing_Type));
      end if;

      --  TBD: From some intermediate module?
      --  TBD: If we inherit an object parameter from a parent type,
      --      and its type is also an inherited parameter, then
      --      its type might have the parent module as its enclosing region.
      return Formal_Type;
   end Substitute_Actuals_From_Instantiation;

   function Matching_Interp
     (Assoc_Type_Region : Type_Region_Ptr;
      Opnd : Optional_Tree;
      Param : Optional_Tree;
      Generic_Param_Map : access Param_Mapping_Ptr;
      Associated_Operation : Sym_Ptr := null;
      Diagnose : Boolean := False)
      return Optional_Tree
   is
      --  Walk interp tree of Opnd and find one that
      --  matches given Param.  Return Null_Optional_Tree if none.
      --  If Param is of a formal type or of a type that depends on one,
      --  need to substitute from Assoc_Type_Region's actual parameters.
      --  If we encounter a parameter of a "generic" type we will
      --  update the Generic_Param_Map with the appropriate mapping.
      --  If Diagnose is True, then produce messages indicating why operand
      --  does *not* match.
      Param_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Param));
      Is_Implicit_Module_Param : constant Boolean :=
        Param_Sem /= null
       and then Param_Sem.all in Param_Semantic_Info'Class
       and then Param_Sem_Ptr (Param_Sem).Is_Implicit_Module_Param;
      Param_Type : constant Type_Sem_Ptr := Resolved_Type (Param);
      Chosen_Interp : Optional_Tree := Null_Optional_Tree;
      Ambiguity : Ambiguity_List := null;

   begin  --  Matching_Interp

      if Debug_Second_Pass then
         Put_Line
           ("  Checking for match between interps of " &
            Subtree_Image (Opnd, Use_Short_Form => True) &
            " and param " &
            Subtree_Image (Param, Use_Short_Form => True));
         if Is_Implicit_Module_Param then
            Put_Line ("   (Is_Implicit_Module_Param)");
         end if;
         if Associated_Operation /= null then
            Put_Line ("   Associated_Operation = " &
              Subtree_Image (Associated_Operation.Definition,
                Use_Short_Form => True));
         end if;
      end if;
      if Param_Sem /= null
        and then Param_Sem.all in Operation_Semantic_Info'Class
      then
         --  We have an operation parameter.
         --  Create a possible interpretation.
         Chosen_Interp :=
           Create_Func_Type_Interp (Opnd, Operation_Sem_Ptr (Param_Sem));

      elsif Param_Type /= null
        and then Param_Type.Associated_Module /= null
      then
         --  We might have a match, so iterate over interpretations
         Find_Interp_Of_Type
           (Assoc_Type_Region,
            Opnd,
            Substitute_Actuals
               (Param_Type,
                Assoc_Type_Region,
                Extra_Subst => Generic_Param_Map.all,
                Associated_Operation => Associated_Operation),
            Generic_Param_Map.all,
            Chosen_Interp,
            Ambiguity,
            Associated_Operation,
            Formal_Is_Var => Static.Sem_Info_Is_For_Variable (Param_Sem));

         if Diagnose and then Is_Null (Chosen_Interp) then
            --  Try again, this time explaining why it doesn't match
            Find_Interp_Of_Type
              (Assoc_Type_Region,
               Opnd,
               Substitute_Actuals
                  (Param_Type,
                   Assoc_Type_Region,
                   Extra_Subst => Generic_Param_Map.all),
               Generic_Param_Map.all,
               Chosen_Interp,
               Ambiguity,
               Associated_Operation,
               Formal_Is_Var => Static.Sem_Info_Is_For_Variable (Param_Sem),
               Diagnose => True);
         end if;
      end if;
      if Ambiguity /= null then
         --  Remember there is an ambiguity within this interpretation
         Sem_Info (Chosen_Interp).Ambiguity := Ambiguity;
      end if;
      if Is_Implicit_Module_Param
        and then Not_Null (Chosen_Interp)
      then
         --  Add actual parameter to generic-param map
         Generic_Param_Map.all :=
           new Param_Mapping'
           (From => Param_Sem,
            To => Underlying_Sem_Info (Chosen_Interp),
            Next => Generic_Param_Map.all);
      end if;
      return Chosen_Interp;
   end Matching_Interp;

   procedure Find_Interp_Of_Signature
     (Op_Name : Optional_Tree;
      Signature : Operation_Sem_Ptr;
      Chosen_Interp : out Optional_Tree;
      Chosen_Assoc_Type_Region : out Type_Region_Ptr;
      Ambiguity : out Ambiguity_List;
      Signature_Type_Region : Type_Region_Ptr := null;
      Require_Exact_Type_Match : Boolean := False) is
      --  Walk interp tree of Op_Name and find one that
      --  matches given Signature.  If Signature is null,
      --  then return first Interp.
      --  Set Chosen_Interp to Null_Optional_Tree if no matching interp.
      --  Set Chosen_Assoc_Type_Region to type where operation originates.
      --  Set Ambiguity if multiple interps.
      --  If Signature_Type_Region is non-null, then use that
      --  with Substitute_Actuals on Signature.
      --  If Require_Exact_Type_Match is True, then use same mod_sem for
      --  both signature and interp, since we don't want types to match
      --  just because both are current instances.
      Extra_Sub_For_Signature : Type_Sem_Ptr;

      procedure Add_Ambiguity (Op_Interp : Optional_Tree) is
      --  Add Op_Interp to list of ambiguities.
      --  Init Ambiguity to "Chosen_Interp" if currently null.
      begin
         --  First initialize the list.
         if Ambiguity = null then
            --  Chosen_Interp itself wasn't ambiguous, so we need to
            --  create a new list.
            Ambiguity := new Ambiguity_List_Node'
              (This_Interp => Chosen_Interp,
               Ambiguous_Operands => null,
               Next_Ambig_Interp => null);
         end if;

         --  Now insert new ambiguity at head of list unless already there
         --  NOTE: Sometimes we get the same interp twice because
         --        we go top-down after doing a bottom-up resolution.
         if Op_Interp /= Ambiguity.This_Interp then
            Ambiguity :=
              new Ambiguity_List_Node'
                (This_Interp => Op_Interp,
                 Ambiguous_Operands => null,
                 Next_Ambig_Interp => Ambiguity);
         end if;

      end Add_Ambiguity;

      procedure Check_One_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Interp : Optional_Tree) is
         --  Check to see whether given Interp is for an operation
         --  and whether it has desired signature.  If so,
         --  set Chosen_Interp if null, or set Ambiguity non-null.
         Interp_Sem : constant Sem_Ptr := Underlying_Op_Sem_Info (Interp);
      begin
         if Interp_Sem /= null
           and then Interp_Sem.all in Operation_Semantic_Info
         then
            --  We have an operation.
            --  Compare signatures.
            --  TBD: If sem is in Operand_Semantic_Info'Class,
            --       and signature is parameterless,
            --       try interpreting operand as "trivial" lambda expression.
            --       This would be appropriate for implementing something
            --       like the "and then" operation, where right operand
            --       could be declared "func RHS()->Boolean".
            declare
               Extra_Sub_For_Interp : Type_Sem_Ptr := null;
               Extra_Sub_For_Sig_To_Use : Type_Sem_Ptr :=
                 Extra_Sub_For_Signature;
            begin
               if Assoc_Type_Region /= null then
                  --  Get Module for this interp
                  Extra_Sub_For_Interp := Type_Sem_Ptr (Assoc_Type_Region);
               end if;
               if Require_Exact_Type_Match then
                  Extra_Sub_For_Sig_To_Use := Extra_Sub_For_Interp;
               end if;
               if Signatures_And_Modes_Match
                    (Op_Sem1 => Operation_Sem_Ptr (Interp_Sem),
                     Op_Sem2 => Signature,
                     Extra_Subst1 => Extra_Sub_For_Interp,
                     Extra_Subst2 => Extra_Sub_For_Sig_To_Use,
                     Substitute_Using1 => Assoc_Type_Region,
                     Substitute_Using2 => Signature_Type_Region)
               then
                  --  Signatures match, see if ambiguous
                  if Is_Null (Chosen_Interp) then
                     --  First match, remember it,
                     --  and whether it is internally ambiguous (unlikely!)
                     Chosen_Interp := Interp;
                     Chosen_Assoc_Type_Region := Assoc_Type_Region;
                     Ambiguity := Sem_Info (Interp).Ambiguity;
                  elsif Interps_Equivalent (Chosen_Interp, Interp) then
                     --  Ignore this one as it is equivalent to an earlier one
                     if Debug_Second_Pass then
                        Put_Line
                          (" Find_Interp_Of_Signature: interps equivalent");
                     end if;
                  else
                     --  Not first match, this is ambiguous.
                     if Debug_Second_Pass then
                        Put_Line
                          (" Find_Interp_Of_Signature: ambiguous, " &
                           "found more than one match");
                     end if;
                     Add_Ambiguity (Interp);
                  end if;
               end if;
            end;
         end if;
      end Check_One_Interp;
      procedure Check_For_Matching_Signature is new
        Interpretations.Iterate_Interps (Check_One_Interp);

      Op_Name_Sem : constant Sem_Ptr :=
        Sem_Ptr (Sem_Info (Op_Name));
   begin
      Chosen_Interp := Null_Optional_Tree;
      Ambiguity := null;
      if Op_Name_Sem /= null then
         --  We have semantic info for Op_Name.
         --  Determine module associated with signature.
         if Signature_Type_Region /= null then
            Extra_Sub_For_Signature := Type_Sem_Ptr (Signature_Type_Region);
         elsif not Require_Exact_Type_Match then
            --  Get the current inst of the module enclosing the
            --  signature operation.
            declare
               Enclosing_Mod_Intf : constant Module_Sem_Ptr :=
                 Find_Enclosing_Module_Interface
                    (Signature.Associated_Symbol.Enclosing_Region);
            begin
               if Enclosing_Mod_Intf /= null then
                  Extra_Sub_For_Signature := Enclosing_Mod_Intf.Cur_Inst_Sem;
               end if;
            end;
         end if;
         if Op_Name_Sem.all in Operation_Semantic_Info then
            --  Must be a lambda expression
            Check_One_Interp (Assoc_Type_Region => null,
              Interp => Op_Name);
         else
            --  Should be a name of an operation
            pragma Assert (Op_Name_Sem.all in Operand_Semantic_Info'Class);

            --  Scan interps of Op_Name looking for matching signature.
            Check_For_Matching_Signature
              (Operand_Sem_Ptr (Op_Name_Sem).Interps);
         end if;
      end if;
   end Find_Interp_Of_Signature;

   procedure Display_Interps (Operand : Optional_Tree) is
      Opnd_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Operand));
      use type Interpretations.Interp_Tree;

      procedure Display_One_Interp
        (Assoc_Type_Region : Type_Region_Ptr;
         Interp : Optional_Tree) is
         --  Display one interp for operand
         Interp_Sem : constant Sem_Ptr := Underlying_Sem_Info (Interp);
      begin
         Put_Line
           ("   Image of interp: " &
            Subtree_Image (Interp, Use_Short_Form => True));
         if Interp_Sem = null
           or else Interp_Sem.all not in Operand_Semantic_Info'Class
         then
            Put_Line ("    Interp sem not an Operand_Semantic_Info");
         else
            Put_Line
              ("    Interp of type " & Type_Image (Resolved_Type (Interp)));
         end if;
      end Display_One_Interp;

      procedure Display_All_Interps is new Interpretations.Iterate_Interps (
         Display_One_Interp);

   begin --  Display_Interps

      if Opnd_Sem = null
        or else Opnd_Sem.all not in Operand_Semantic_Info'Class
        or else not Interpretations.Has_Interp
                      (Operand_Sem_Ptr (Opnd_Sem).Interps)
      then
         Put_Line
           (" No interps to display for " &
            Subtree_Image (Operand, Use_Short_Form => True));
      else
         Put_Line
           (" Interps for " &
            Subtree_Image (Operand, Use_Short_Form => True) &
            ":");
         Display_All_Interps (Operand_Sem_Ptr (Opnd_Sem).Interps);
      end if;
   end Display_Interps;

   generic
      with function Nth_Formal (N : Positive) return Optional_Tree;
      with function Nth_Default (N : Positive) return Optional_Tree;
      with function Lookup_Formal_Name
        (Name : Strings.U_String)
         return Natural;
   procedure Canonicalize_Operand_List
     (Num_Formals : Positive;
      Actual_Construct : Optional_Tree;
      Actual_Operands : Lists.List;
      Assoc_Type_Region : Type_Region_Ptr;
      Resolved_Operand_List : out Lists.List;
      Generic_Param_Map : out Param_Mapping_Ptr;
      Ambiguity : out Ambiguity_List;
      Associated_Operation : Sym_Ptr := null;
      Diagnose : Boolean := False);
   --  See below

   procedure Canonicalize_Operand_List
     (Num_Formals : Positive;
      Actual_Construct : Optional_Tree;
      Actual_Operands : Lists.List;
      Assoc_Type_Region : Type_Region_Ptr;
      Resolved_Operand_List : out Lists.List;
      Generic_Param_Map : out Param_Mapping_Ptr;
      Ambiguity : out Ambiguity_List;
      Associated_Operation : Sym_Ptr := null;
      Diagnose : Boolean := False) is
      --  Resolve operand list involving named and positional operands.
      --  Resolved_Operand_List is empty if the construct doesn't resolve;
      --  otherwise it is a list of operands in canonical order,
      --  with those involving a "<==" being assignment statements,
      --  with the others being just an operand value.
      --  If the operation is a generic op, then the Generic_Param_Map
      --  will be initialized with a list of mappings of "generic" type
      --  to actual type.
      --  If Diagnose is True, then indicate why a given operand does *not*
      --  match or why we have ambiguity.
      --  Requires: Num_Formals > 0.

      Resolved_Operands : Tree_Array (1 .. Num_Formals) :=
        (others => Null_Optional_Tree);
      Move_Target : Tree_Array (1 .. Num_Formals) :=
        (others => Null_Optional_Tree);

      Num_Actuals : constant Natural := Lists.Length (Actual_Operands);
      Seen_Named_Operand : Boolean := False;
      Last_Positional : Natural := 0;
      Param_Map : aliased Param_Mapping_Ptr := null;

      procedure Add_Operand_Ambiguity (Operand_Ambig : Ambiguity_List) is
      --  Create Ambiguity list if necessary,
      --  and add operand's ambiguity to list.
      begin
         if Ambiguity = null then
            Ambiguity := new Ambiguity_List_Node'
              (This_Interp => Null_Optional_Tree,
               Ambiguous_Operands => null,
               Next_Ambig_Interp => null);
         end if;

         --  Now add on to list of ambiguous operands
         Ambiguity.Ambiguous_Operands :=
           Combine_Ambiguity (Ambiguity.Ambiguous_Operands, Operand_Ambig);

      end Add_Operand_Ambiguity;

   begin  --  Canonicalize_Operand_List

      Resolved_Operand_List := Lists.Empty_List;
      Ambiguity := null;
      Generic_Param_Map := null;

      if Num_Actuals > Num_Formals then
         --  Cannot possibly match
         if Debug_Second_Pass then
            Put_Line
              (" Too many actual operands in " &
               Subtree_Image (Actual_Construct, Use_Short_Form => True));
         end if;
         if Diagnose then
            Messages.Put_Message
              ("too many actual operands; last formal is " &
               Subtree_Image (Nth_Formal (Num_Formals), Use_Short_Form => True,
                 Max_Chars => 100),
               Src_Pos => Find_Source_Pos (Actual_Construct),
               Message_Kind => "Info");
         end if;
         return;
      end if;

      for I in 1 .. Num_Actuals loop
         declare
            Operand : constant Optional_Tree :=
              Lists.Nth_Element (Actual_Operands, I);
            Operand_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Operand).all;
            Formal_Index : Natural := I;
         begin
            if Operand_Tree in Reference.Tree
              or else Operand_Tree in Assign_Stmt.Tree
            then
               --  We have Name => Value or
               --   Name <== Value
               declare
                  Operand_Name : constant Optional_Tree :=
                    Nth_Operand (Operand_Tree, 1);
                  Operand_Name_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                                  (
                    Operand_Name).all;
                  Operand_Value : constant Optional_Tree :=
                    Nth_Operand (Operand_Tree, 2);
               begin
                  --  Look up name
                  if Operand_Name_Tree not in Identifier.Tree then
                     Sem_Error
                       (Operand_Name,
                        "Name not valid in " & Subtree_Image (Operand_Tree,
                           Use_Short_Form => True));
                     return; --------- Doesn't match
                  else
                     declare
                        Operand_Name_Str : constant Strings.U_String :=
                          Identifier.Tree (Operand_Name_Tree).Str;
                     begin
                        Formal_Index := Lookup_Formal_Name (Operand_Name_Str);
                        if Formal_Index = 0 then
                           if Debug_Second_Pass then
                              Put_Line
                                (" operand name " &
                                 Strings.To_String (Operand_Name_Str) &
                                 " does not match anything.");
                           end if;
                           if Diagnose then
                              Messages.Put_Message
                                ("operand name " &
                                 Strings.To_String (Operand_Name_Str) &
                                 " does not match anything",
                                 Src_Pos => Find_Source_Pos (Operand_Name),
                                 Message_Kind => "Info");
                           end if;
                           return; --------- Doesn't match
                        end if;

                        if Resolved_Operands (Formal_Index) /=
                           Null_Optional_Tree
                        then
                           if Formal_Index > Last_Positional then
                              Sem_Error
                                (Operand,
                                 "Duplicate name in operand list");
                           else
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" operand name " &
                                    Strings.To_String (Operand_Name_Str) &
                                    " duplicates an earlier positional one.");
                              end if;
                              if Diagnose then
                                 Messages.Put_Message
                                   ("operand name " &
                                    Strings.To_String (Operand_Name_Str) &
                                    " duplicates an earlier positional one",
                                    Src_Pos => Find_Source_Pos (Operand_Name),
                                    Message_Kind => "Info");
                              end if;
                           end if;
                           return; --------- Doesn't match
                        end if;

                        Resolved_Operands (Formal_Index) :=
                           Matching_Interp
                             (Assoc_Type_Region,
                              Operand_Value,
                              Nth_Formal (Formal_Index),
                              Param_Map'Access,
                              Associated_Operation => Associated_Operation,
                              Diagnose => Diagnose);

                        if Operand_Tree in Assign_Stmt.Tree then
                           --  Remember is a move
                           Move_Target (Formal_Index) := Operand_Name;
                        end if;

                        Seen_Named_Operand := True;
                     end;
                  end if;
               end;
            else
               --  A positional component
               if Seen_Named_Operand then
                  Sem_Error
                    (Actual_Construct,
                     "Positional operands must precede " &
                     "all named operands in " &
                     Subtree_Image (Actual_Construct, Use_Short_Form => True));
                  return; --------- Doesn't match
               end if;

               Last_Positional := Formal_Index;

               Resolved_Operands (Formal_Index) :=
                  Matching_Interp
                    (Assoc_Type_Region,
                     Operand,
                     Nth_Formal (Formal_Index),
                     Param_Map'Access,
                     Associated_Operation => Associated_Operation,
                     Diagnose => Diagnose);

            end if;

            if Is_Null (Resolved_Operands (Formal_Index)) then
               if Debug_Second_Pass then
                  Put_Line
                    (" operand " &
                     Subtree_Image (Operand, Use_Short_Form => True) &
                     " does not match type of " &
                     Subtree_Image (Nth_Formal (Formal_Index)));
               end if;
               if Diagnose then
                  Messages.Put_Message
                    ("operand " &
                     Subtree_Image (Operand, Use_Short_Form => True,
                       Max_Chars => 100) &
                     " does not match " &
                     Subtree_Image (Nth_Formal (Formal_Index),
                       Use_Short_Form => True, Max_Chars => 100),
                     Src_Pos => Find_Source_Pos (Operand),
                     Message_Kind => "Info");
               end if;
               return; --------- Doesn't match
            end if;
         end;
      end loop;

      for I in 1 .. Num_Formals loop
         --  See if we have any missing, and check if they
         --  have a default.
         if Is_Null (Resolved_Operands (I)) then
            declare
               Default : constant Optional_Tree := Nth_Default (I);
            begin
               if Is_Null (Default) then
                  if Debug_Second_Pass then
                     Put_Line
                       (" No operand for " & Subtree_Image (Nth_Formal (I)));
                  end if;
                  if Diagnose then
                     Messages.Put_Message
                       ("missing operand in aggregate for " &
                        Subtree_Image (Nth_Formal (I), Use_Short_Form => True,
                          Max_Chars => 100),
                        Src_Pos => Find_Source_Pos (Actual_Construct),
                        Message_Kind => "Info");
                  end if;
                  return;   ----- does not match -------
               else
                  --  Use default
                  declare
                     Default_Copy : constant Optional_Tree :=
                       Substitute_Actuals_In_Operand
                          (Optional (Tree_Ptr_Of (Default).all),
                           Assoc_Type_Region,
                           Extra_Subst => Param_Map);
                  --  TBD: Is copying "Default" necessary?
                  begin
                     Resolved_Operands (I) :=
                        Matching_Interp
                          (Assoc_Type_Region,
                           Default_Copy,
                           Nth_Formal (I),
                           Param_Map'Access,
                           Associated_Operation => Associated_Operation);

                     if Is_Null (Resolved_Operands (I)) then
                        Sem_Error
                          (Actual_Construct,
                           "Default expression " &
                           Subtree_Image (Default) &
                           " for " &
                           Subtree_Image (Nth_Formal (I)) &
                           " does not resolve");
                        return;  ------- problem with default ---------
                     end if;
                  end;
               end if;
            end;
         end if;

         if Sem_Info (Resolved_Operands (I)).Ambiguity /= null then
            --  Resolution is ambiguous
            Add_Operand_Ambiguity (Sem_Info (Resolved_Operands (I)).Ambiguity);
         end if;
      end loop;

      --  OK, we now have an array of resolved operands.
      --  Build up the list of operands in component order.
      for I in 1 .. Num_Formals loop
         if Not_Null (Move_Target (I)) then
            --  Recreate "move" operation, even though it is
            --  not legal syntax.
            declare
               Move_Operation : constant Optional_Tree :=
                 Assign_Stmt.Make
                    (Assign_Stmt.Move_Op,
                     Move_Target (I),
                     Resolved_Operands (I));
               Actual_Sem : constant Sem_Ptr :=
                 Sem_Ptr (Sem_Info (Resolved_Operands (I)));
            begin
               if Actual_Sem /= null
                 and then Actual_Sem.all in Operand_Semantic_Info'Class
               then
                  --  Make sure Resolved_Interp is filled in
                  declare
                     Opnd_Sem : constant Operand_Sem_Ptr :=
                       Operand_Sem_Ptr (Actual_Sem);
                  begin
                     if Is_Null (Opnd_Sem.Resolved_Interp) then
                        --  Fill in Resolved_Interp to point to
                        --  the actual operand.
                        Opnd_Sem.Resolved_Interp := Resolved_Operands (I);
                     end if;
                  end;
               end if;
               --  Copy the sem info to move operation
               Set_Sem_Info (Move_Operation, Root_Sem_Ptr (Actual_Sem));

               Lists.Append (Resolved_Operand_List, Move_Operation);
            end;
         else
            Lists.Append (Resolved_Operand_List, Resolved_Operands (I));
         end if;
      end loop;

      --  Copy back the generic param map.
      Generic_Param_Map := Param_Map;

   end Canonicalize_Operand_List;

   function Make_Copy_Of_Operand
     (Orig_Operand : Optional_Tree)
      return Optional_Tree
   is
      --  Make a copy of the operand so it can have a separate "info"
      --  from the original Operand.

      Result : constant Optional_Tree :=
        Optional (Tree_Ptr_Of (Orig_Operand).all);

      Result_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Result).all;

   begin  --  Make_Copy_Of_Operand

      if Result_Tree.Sem_Info /= null then
         --  Set sem info
         Result_Tree.Sem_Info :=
           new Root_Semantic_Info'Class'(Result_Tree.Sem_Info.all);

         Result_Tree.Sem_Info.Definition := Result;

         --  Set resolved interp to point to self
         if Result_Tree.Sem_Info.all in Operand_Semantic_Info'Class then
            Operand_Sem_Ptr (Result_Tree.Sem_Info).Resolved_Interp :=
              Result;
         end if;
      end if;

      return Result;
   end Make_Copy_Of_Operand;

   function Type_Is_Concurrent
     (Type_Sem : Type_Sem_Ptr)
     return Boolean is
   --  Return True if type has explicit "concurrent" specified
   --  or is based on a concurrent module.
   begin
      return Type_Sem /= null
        and then Type_Sem.Associated_Module /= null
        and then (Type_Sem.Obj_Is_Concurrent
          or else Type_Sem.Associated_Module.Is_Concurrent);
   end Type_Is_Concurrent;

   function Is_Unlocked_Concurrent_Operand
     (Opnd_Sem : Operand_Sem_Ptr)
      return Boolean
   is
      --  Return True if operand is of a type that is marked
      --  "concurrent" or is based on a concurrent module.
      --  NOTE: We return False if operand is a locked formal, since
      --       we treat a locked concurrent object essentially like a
      --       non-concurrent object, in that we can presume there is
      --       only one thread using the object, and we don't allow
      --       parallel updates to it internal to the routine, since
      --       we can't "relock" it.
      --       Operation outputs are also considered non-concurrent,
      --       since until they are returned, they won't be assigned
      --       a lock object.
      --  TBD:  We don't look through "refs" at this point to check
      --       to see whether the object is considered concurrent.
      use type Param_Decl.Param_Locking;
      Result : Boolean := False;
   begin
      if Opnd_Sem = null
        or else Opnd_Sem.Resolved_Type = null
        or else (not Opnd_Sem.Resolved_Type.Obj_Is_Concurrent
                and then not Opnd_Sem.Resolved_Type.Associated_Module.
                  Is_Concurrent)
      then
         --  Definitely not concurrent
         Result := False;
      elsif Tree_Ptr_Of (Opnd_Sem.Definition).all in Param_Decl.Tree then
         --  Is a parameter, see whether is unlocked concurrent.
         --  Note that output parameters are never unlocked concurrent.
         Result := not Param_Sem_Ptr (Opnd_Sem).Is_Operation_Output
               and then Param_Decl.Tree
                 (Tree_Ptr_Of (Opnd_Sem.Definition).all).Locking =
                    Param_Decl.Not_Locked;
         if Debug_Code_Gen and then not Result then
            Put_Line (" Param is locked concurrent: " &
              Subtree_Image (Opnd_Sem.Definition));
         end if;
      else
         --  Is unlocked concurrent only if it is considered a variable.
         --  NOTE: "Real" constants (as opposed to read-only views of
         --  variables) don't need a lock, and in general the non-ref output
         --  of a call doesn't have a lock, until it gets stored in a
         --  variable.
         Result := Sem_Info_Is_For_Variable (Sem_Ptr (Opnd_Sem));
         if Debug_Code_Gen and then not Result then
            Put_Line (" Concurrent obj is a constant: " &
              Subtree_Image (Opnd_Sem.Definition));
         end if;
      end if;
      return Result;
   end Is_Unlocked_Concurrent_Operand;

   procedure Diagnose_Undefined_Operand
     (Operand : Optional_Tree;
      Assoc_Type_Region : Type_Region_Ptr) is
   --  If operand has no Interps, complain about it
      Operand_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Operand).all;
      Operand_Sem : constant Sem_Ptr := Sem_Ptr (Operand_Tree.Sem_Info);
   begin
      if Operand_Tree in Reference.Tree then
         --  Pass through to actual expression if Operand of form Name => Value
         Diagnose_Undefined_Operand
           (Reference.Tree (Operand_Tree).Referent, Assoc_Type_Region);

      elsif Operand_Sem /= null
        and then Operand_Sem.all in Operand_Semantic_Info'Class
        and then not Operand_Sem_Ptr (Operand_Sem).Reported_As_Undefined
        and then Is_Null (Operand_Sem_Ptr (Operand_Sem).Resolved_Interp)
        and then not Interpretations.Has_Interp
          (Operand_Sem_Ptr (Operand_Sem).Interps)
      then
         --  This operand has no interpretations.
         --  Remember that we reported it.
         Operand_Sem_Ptr (Operand_Sem).Reported_As_Undefined := True;

         if Operand_Sem.all in Call_Semantic_Info then
            --  It is a call, pass the buck to Create_Call_Interps
            --  to diagnose the problem.
            Create_Call_Interps
              (Operand_Sem.Definition,
               Operation_Type_Region => Assoc_Type_Region,
               Diagnose => True);
         else
            --  Just report the lack of an interpretation.
            Messages.Put_Message
              ("operand " & Subtree_Image (Operand) &
               " has no interpretation",
               Src_Pos => Find_Source_Pos (Operand),
               Message_Kind => "Info");
         end if;
      end if;
   end Diagnose_Undefined_Operand;

   procedure Diagnose_Undefined_Actuals
     (Actuals : Lists.List;
      Assoc_Type_Region : Type_Region_Ptr) is
   --  Find actuals with no interps, and identify them
   begin
      for I in 1 .. Lists.Length (Actuals) loop
         Diagnose_Undefined_Operand
           (Lists.Nth_Element (Actuals, I), Assoc_Type_Region);
      end loop;
   end Diagnose_Undefined_Actuals;

   procedure Create_Call_Interps
     (Call_Ot : Optional_Tree;
      Only_For_Operation_Interp : Optional_Tree := Null_Optional_Tree;
      Operation_Type_Region : Type_Region_Ptr := null;
      Diagnose : Boolean := False) is
   --  Create interps for Call, presuming have already created
   --  interps for prefix of Call.
   --  If Only_For_Operation_Interp is non-null, then only create call
   --  interps for given operation; Operation_Type_Region must be provided.
   --  If Diagnose is True, then produce messages indicating why a call
   --  does *not* match a possible operation.
      Call : Invocation.Tree
        renames Invocation.Tree (Tree_Ptr_Of (Call_Ot).all);
      Call_Sem : Call_Sem_Ptr := Call_Sem_Ptr (Call.Sem_Info);
      Prefix_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Call.Prefix));
      Num_Operands : constant Natural := Lists.Length (Call.Operands);

      procedure Create_Interps
        (Assoc_Type_Region : Type_Region_Ptr;
         Op_Interp : Optional_Tree) is
         --  Create interps associated with given interpretation
         --  of operation name
         Op_Sem : Sem_Ptr :=
           Sem_Ptr (Sem_Ptr (Sem_Info (Op_Interp)).Associated_Symbol.Sem_Info);
         Interp_Added : Boolean;
      begin
         --  Add region to interps even if Op_Interp doesn't match
         --  to indicate that given region was considered.
         Interpretations.Add_Interp
           (Operand_Sem_Ptr (Sem_Info (Call_Ot)).Interps,
            Associated_Type_Region => Assoc_Type_Region,
            Interp => Null_Optional_Tree,
            Interp_Added => Interp_Added);

         if Op_Sem.all in Operand_Semantic_Info'Class then
            --  Check whether we have an object of a func type
            if Operand_Sem_Ptr (Op_Sem).Resolved_Type /= null
              and then Operand_Sem_Ptr
                (Op_Sem).Resolved_Type.Func_Type_Op_Sem /= null
            then
               --  Interp refers to object of a func type
               --  Create a copy of func-type op_sem and fill in more info
               declare
                  New_Op_Sem : constant Operation_Sem_ptr :=
                    new Operation_Semantic_Info'
                      (Operand_Sem_Ptr
                        (Op_Sem).Resolved_Type.Func_Type_Op_Sem.all);
               begin
                  New_Op_Sem.Associated_Symbol := Op_Sem.Associated_Symbol;

                  --  Copy "level" from parameter or lambda expression
                  if Op_Sem.all in Object_Semantic_Info'Class then
                     New_Op_Sem.Level :=
                       Object_Sem_Ptr (Op_Sem).Info.Obj_Level;
                  elsif Op_Sem.all in Resolved_Operation_Info'Class then
                     New_Op_Sem.Level := Resolved_Op_Ptr (Op_Sem).Op_Sem.Level;
                  else
                     null;  --  TBD: What else could it be?
                  end if;

                  --  TBD: More changes needed to New_Op_Sem?
                  Op_Sem := Sem_Ptr (New_Op_Sem);
               end;
            else
               --  Not an object of a func type
               return;  --  Ignore this interp  --
            end if;
         end if;

         if Op_Sem.all in Type_Semantic_Info'Class then
            --  We have a type conversion.
            --  TBD: Add a "convert" operation on top.
            Sem_Error (Call_Ot, "NYI: Type_Conversion not yet supported");
         elsif Op_Sem.all in Operation_Semantic_Info'Class then
            --  We have an operation, see if it has right
            --  number of operands, etc.
            declare
               Op_Tree : Operation.Tree renames
                 Operation.Tree (Tree_Ptr_Of (Op_Sem.Definition).all);
               Num_Inputs : constant Natural :=
                 Lists.Length (Op_Tree.Operation_Inputs);
               Num_Outputs : constant Natural :=
                 Lists.Length (Op_Tree.Operation_Outputs);

               function Nth_Formal
                 (Formal_Index : Positive)
                  return Optional_Tree
               is
               --  Return Nth input formal for operation
               begin
                  return Lists.Nth_Element
                           (Op_Tree.Operation_Inputs,
                            Formal_Index);
               end Nth_Formal;

               function Nth_Default
                 (Formal_Index : Positive)
                  return Optional_Tree
               is
                  --  Return default for Nth input formal, or null if none.
                  Formal : Trees.Tree'Class renames
                    Tree_Ptr_Of (Lists.Nth_Element
                      (Op_Tree.Operation_Inputs, Formal_Index)).all;
               begin
                  if Formal in Param_Decl.Tree then
                     return Param_Decl.Tree (Formal).Param_Default;
                  elsif Formal in Operation.Tree then
                     return Operation.Tree (Formal).Statements;
                  else
                     Sem_Error
                       (Formal,
                        "Internal: Unrecognizable kind of operation input");
                     return Null_Optional_Tree;
                  end if;
               end Nth_Default;

               function Lookup_Formal_Name
                 (Param_Name : Strings.U_String)
                  return Natural
               is
                  --  Look up name of parameter and return its index
                  --  where 1 is the first operation input.
                  use type Symbols.Sym_Ptr;
                  Param_Sym : Symbols.Sym_Ptr :=
                    Symbols.Lookup_In_Region
                       (Op_Sem.Nested_Region,
                        Param_Name);
               begin
                  if Param_Sym = null or else Param_Sym.Sem_Info = null then
                     --  Not a formal of the operation
                     return 0;
                  else
                     --  Presumably either an input or an output
                     declare
                        Result : constant Integer :=
                          Positive (Param_Sym.Index) - Num_Outputs;
                     begin
                        if Result in 1 .. Num_Inputs then
                           return Result;
                        else
                           --  Must be an output
                           return 0;
                        end if;
                     end;
                  end if;
               end Lookup_Formal_Name;

               procedure Canonicalize_Actuals is new Canonicalize_Operand_List
                 (Nth_Formal => Nth_Formal,
                  Nth_Default => Nth_Default,
                  Lookup_Formal_Name => Lookup_Formal_Name);

            begin
               --  Check whether we have a match

               if Num_Operands <= Num_Inputs then
                  --  Not too many operands.
                  --  Now check for name/type matches.
                  declare
                     Ambiguity : Ambiguity_List := null;
                     Canonical_Operands : Lists.List;
                     Generic_Param_Map : Param_Mapping_Ptr;
                  begin
                     if Num_Inputs > 0 then
                        Canonicalize_Actuals
                          (Num_Formals => Num_Inputs,
                           Actual_Construct => Call_Ot,
                           Actual_Operands => Call.Operands,
                           Assoc_Type_Region => Assoc_Type_Region,
                           Resolved_Operand_List => Canonical_Operands,
                           Generic_Param_Map => Generic_Param_Map,
                           Ambiguity => Ambiguity,
                           Associated_Operation => Op_Sem.Associated_Symbol,
                           Diagnose => Diagnose);

                        if Lists.Is_Empty (Canonical_Operands) then
                           if Debug_Second_Pass then
                              Put_Line
                                (Subtree_Image (Call_Ot) &
                                 " does not match " &
                                 Subtree_Image
                                    (Op_Sem.Definition,
                                     Use_Short_Form => True));
                           end if;
                           return;  -- Not a match --
                        end if;
                     else
                        --  Operation has no inputs
                        Canonical_Operands := Lists.Empty_List;
                     end if;

                     --  OK, we have a name/type match, make an
                     --  invocation tree with an appropriate
                     --  Sem_Info and fill in Resolved_Type field.
                     declare
                        Invoc_Tree : constant Optional_Tree :=
                          Invocation.Make
                             (Kind => Invocation.Operation_Call,
                              Prefix => Op_Interp,
                              Operands => Canonical_Operands,
                              Source_Pos => Call.Source_Pos);
                        Interp_Sem : constant Call_Sem_Ptr :=
                          new Call_Semantic_Info'Class'(Call_Sem.all);
                     begin
                        --  Carry over annotations
                        Annotation.Add_Annotations (Invoc_Tree, From => Call);

                        Interp_Sem.Ambiguity := Ambiguity;
                        --  Remember whether ambiguous

                        Interp_Sem.Generic_Param_Map := Generic_Param_Map;

                        Interp_Sem.Definition := Invoc_Tree;
                        --  TBD: Is this necessary?
                        Interp_Sem.Interps := null;

                        if Lists.Length (Op_Tree.Operation_Outputs) = 1 then
                           --  TBD: Handle multiple outputs
                           declare
                              Result_Param : constant Object_Sem_Ptr :=
                                Object_Sem_Ptr
                                  (Sem_Info (Lists.Nth_Element
                                    (Op_Tree.Operation_Outputs, 1)));
                           begin
                              Interp_Sem.Resolved_Type :=
                                 Substitute_Actuals
                                   (Result_Param.Resolved_Type,
                                    Assoc_Type_Region,
                                    Extra_Subst => Generic_Param_Map,
                                    Associated_Operation =>
                                      Op_Sem.Associated_Symbol);
                           end;
                        end if;

                        Interp_Sem.Op_Sem := Operation_Sem_Ptr (Op_Sem);

                        --  NOTE: We postpone changing Assoc_Type_Region
                        --        because operation might be of a formal type.
                        Interp_Sem.Assoc_Type_Region := Assoc_Type_Region;

                        if Interp_Sem.Assoc_Type_Region = null
                          and then Interp_Sem.Op_Sem.Originating_Module /= null
                          and then Interp_Sem.Op_Sem.Func_Type_Sem = null
                        then
                           --  Missing Assoc_Type_Region on (direct) call
                           --  of operation declared directly in a module.
                           Sem_Error (Invoc_Tree,
                             "Internal: Missing Assoc_Type on call");
                        end if;

                        --  Decide whether call might involve queuing
                        for I in 1 .. Num_Inputs loop
                           declare
                              Nth_Formal : Trees.Tree'Class
                                renames Tree_Ptr_Of (Lists.Nth_Element
                                  (Op_Tree.Operation_Inputs, I)).all;
                              Formal_Sem : constant Sem_Ptr :=
                                Sem_Ptr (Nth_Formal.Sem_Info);
                              Nth_Actual : constant Optional_Tree :=
                                Lists.Nth_Element (Canonical_Operands, I);
                              Actual_Sem : constant Sem_Ptr :=
                                Underlying_Sem_Info
                                  (Resolved_Tree (Nth_Actual));
                              use Param_Decl;
                           begin
                              if Nth_Formal in Param_Decl.Tree
                                and then Actual_Sem.all in
                                  Operand_Semantic_Info'Class
                              then
                                 --  We have an object formal and an
                                 --  object actual.
                                 --  TBD: "operation" formal might involve
                                 --       queuing too.
                                 declare
                                    Opnd_Sem : constant Operand_Sem_Ptr :=
                                      Operand_Sem_Ptr (Actual_Sem);
                                    Opnd_Type : constant Type_Sem_Ptr :=
                                      Opnd_Sem.Resolved_Type;
                                    Param_Type : constant Type_Sem_Ptr :=
                                      Param_Sem_Ptr (Formal_Sem).Resolved_Type;
                                 begin
                                    --  Check for polymorphic operand and/or
                                    --  queued operand
                                    if Interp_Sem.Polymorphic_Param_Index = 0
                                      and then Opnd_Type /= null
                                      and then
                                        Opnd_Type.Is_Polymorphic
                                      and then not Param_Type.Is_Polymorphic
                                      and then
                                         (U_Base_Type_Region (Opnd_Type) =
                                            Assoc_Type_Region
                                        or else
                                         (Opnd_Type.Enclosing_Type /= null
                                          and then
                                            U_Base_Type_Region
                                              (Opnd_Type.Enclosing_Type) =
                                                Assoc_Type_Region))
                                    then
                                       --  We have the first polymorphic opnd
                                       Interp_Sem.Polymorphic_Param_Index :=
                                         Positive (
                                         Formal_Sem.Associated_Symbol.Index);
                                       if Sym_Is_By_Ref
                                         (Formal_Sem.Associated_Symbol)
                                       then
                                          --  Negate index to indicate is
                                          --  passed by reference.
                                          Interp_Sem.Polymorphic_Param_Index :=
                                            -Interp_Sem.
                                              Polymorphic_Param_Index;
                                       end if;
                                       if Debug_Second_Pass then
                                          Put_Line
                                            (" Param" &
                                             Integer'Image
                                                (Interp_Sem.
                                                   Polymorphic_Param_Index) &
                                             " is polymorphic in " &
                                             Subtree_Image (Invoc_Tree));
                                       end if;
                                    end if;

                                    if not Interp_Sem.Might_Be_Queued
                                      and then Param_Decl.Tree (Nth_Formal).
                                         Locking /= Locked_Param
                                      and then Is_Unlocked_Concurrent_Operand
                                                  (Opnd_Sem)
                                      and then
                                        not Is_Unlocked_Concurrent_Operand
                                          (Operand_Sem_Ptr (Formal_Sem))
                                    then
                                       --  Found a case where we need to lock
                                       --  a parameter, but the mode is not
                                       --"locked"
                                       --  (might be either normal or queued).
                                       --  TBD: Should check for presence
                                       --       of internal precondition.
                                       Interp_Sem.Might_Be_Queued := True;
                                    end if;
                                 end;
                              end if;
                           end;
                        end loop;

                        Set_Sem_Info (Invoc_Tree, Root_Sem_Ptr (Interp_Sem));

                        --  Add interp to invocation interps
                        Interpretations.Add_Interp
                          (Operand_Sem_Ptr (Sem_Info (Call_Ot)).Interps,
                           Associated_Type_Region => Assoc_Type_Region,
                           Interp => Invoc_Tree,
                           Interp_Added => Interp_Added);
                        if Debug_Second_Pass then
                           Put_Line
                             (" Add invocation interp for " &
                              Subtree_Image (Invoc_Tree) &
                              " of type " &
                              Type_Image (Interp_Sem.Resolved_Type) &
                              " with assoc-type of " &
                              Type_Image
                                (Type_Sem_Ptr (Interp_Sem.Assoc_Type_Region)));
                           if Interp_Sem.Assoc_Type_Region /=
                             Assoc_Type_Region
                           then
                              --  Indicate that assoc-type changed
                              Put_Line ("   (assoc-type originally " &
                                Type_Image (Type_Sem_Ptr (Assoc_Type_Region)) &
                                ")");
                           end if;
                        end if;
                     end;
                  end;
               end if;  --  Whether not too many operands
            end;
         end if;  --  Whether sem-info is of interest
      end Create_Interps;

      procedure Create_Invocation_Interps is new
        Interpretations.Iterate_Interps (Create_Interps);

   begin  --  Create_Call_Interps

      if Call_Sem = null then
         --  Need to create semantic info
         Call_Sem := new Call_Semantic_Info;
         Call_Sem.Definition := Call_Ot;
         Call_Sem.Equiv_Invocation := Call_Ot;
         Set_Sem_Info (Call_Ot, Root_Sem_Ptr (Call_Sem));
      end if;

      if Not_Null (Only_For_Operation_Interp) then
         --  Just one operation of interest
         Create_Interps
           (Assoc_Type_Region => Operation_Type_Region,
            Op_Interp => Only_For_Operation_Interp);
      elsif Prefix_Sem /= null
        and then Prefix_Sem.all in Operand_Semantic_Info'Class
        and then Interpretations.Has_Interp
          (Operand_Sem_Ptr (Prefix_Sem).Interps)
      then
         --  Walk tree of interpretations of operation name
         --  and create corresponding interpretations of invocation.
         Create_Invocation_Interps (Operand_Sem_Ptr (Prefix_Sem).Interps);
      else
         if Diagnose then
            if Call_Sem.Ambiguity /= null then
               --  Walk chosen interpretation to report ambiguities
               Create_Interps
                 (Assoc_Type_Region => Call_Sem.Assoc_Type_Region,
                  Op_Interp => Call_Sem.Op_Sem.Definition);
            else
               if Prefix_Sem /= null
                 and then Prefix_Sem.all in Operand_Semantic_Info'Class
               then
                  if Operand_Sem_Ptr (Prefix_Sem).Reported_As_Undefined then
                     --  Already reported the problem
                     return;  --  Quit early  --
                  else
                     --  Remember that we reported this
                     Operand_Sem_Ptr (Prefix_Sem).Reported_As_Undefined :=
                       True;
                  end if;
               end if;

               --  No interpretations for prefix
               declare
                  Prefix_Image : String renames Subtree_Image (Call.Prefix);
               begin
                  if Prefix_Image /= To_Bool_String then
                     --  Show message unless about "to_bool" because
                     --  that is almost always compiler-generated.
                     Messages.Put_Message
                       ("operation name " & Prefix_Image &
                        " has no interpretation",
                        Src_Pos => Find_Source_Pos (Call.Prefix),
                        Message_Kind => "Info");
                  end if;

                  --  Walk actuals and complain if no interps.
                  Diagnose_Undefined_Actuals (Call.Operands,
                    Operation_Type_Region);
               end;
            end if;
         end if;
      end if;
   end Create_Call_Interps;

   procedure Create_Class_Agg_Interp
     (Agg_Sem : Class_Agg_Sem_Ptr;
      Target_Type : Type_Sem_Ptr;
      Diagnose : Boolean := False) is
   --  Create interp for class aggregate of given Target_Type,
   --  presuming have already created interps for components.
   --  If Diagnose is True, then produce messages indicating why
   --  aggregate does *not* match.

      function Nth_Formal (Comp_Index : Positive) return Optional_Tree is
      --  Return Nth component
      begin
         return Nth_Component (Target_Type.Associated_Module, Comp_Index);
      end Nth_Formal;

      function Nth_Default (Comp_Index : Positive) return Optional_Tree is
         --  Return default for Nth component
         Comp_Tree : Trees.Tree'Class renames
           Tree_Ptr_Of (Nth_Component
             (Target_Type.Associated_Module, Comp_Index)).all;
      begin
         if Comp_Tree in Obj_Decl.Tree then
            return Obj_Decl.Tree (Comp_Tree).Obj_Value;
         else
            --  This must be the "ancestor" part
            pragma Assert (Comp_Tree in Param_Decl.Tree);
            return Null_Optional_Tree;
         end if;
      end Nth_Default;

      function Lookup_Formal_Name
        (Comp_Str : Strings.U_String)
         return Natural
      is
         --  Return component index of Name, or 0 if not a component
         Comp_Sym : Symbols.Sym_Ptr :=
           Symbols.Lookup_In_Region
              (Target_Type.Associated_Module.Nested_Region,
               Comp_Str);
         use type Symbols.Sym_Ptr;
      begin
         while Comp_Sym /= null
           and then not Decl_Is_For_Component (Comp_Sym.Definition)
         loop
            --  Skip over non-components
            Comp_Sym := Symbols.Next_Homonym_In_Region (Comp_Sym);
         end loop;

         if Comp_Sym = null
           or else Comp_Sym.Sem_Info = null
           or else Comp_Sym.Sem_Info.all not in Object_Semantic_Info'Class
         then
            if Debug_Second_Pass then
               Put_Line
                 (" class agg name " &
                  Strings.To_String (Comp_Str) &
                  " does not identify an object.");
            end if;
            return 0;  --  Not a name of a component
         end if;

         return Component_Index
                  (Target_Type.Associated_Module,
                   Comp_Sym.Definition);

      end Lookup_Formal_Name;

      procedure Canonicalize_Components is new Canonicalize_Operand_List (
         Nth_Formal => Nth_Formal,
         Nth_Default => Nth_Default,
         Lookup_Formal_Name => Lookup_Formal_Name);

   begin  --  Create_Class_Agg_Interp

      if Debug_Second_Pass then
         Put_Line
           ("Trying to create class agg interp of " &
            Subtree_Image (Agg_Sem.Definition) &
            " of type " &
            Type_Image (Target_Type));
      end if;

      if Target_Type /= null
        and then Target_Type.Is_Polymorphic
      then
         declare
            Agg_Tree : Invocation.Tree renames
              Invocation.Tree (Tree_Ptr_Of (Agg_Sem.Definition).all);
         begin
            if Not_Null (Agg_Tree.Prefix) then
               declare
                  Agg_Type : constant Type_Sem_Ptr :=
                    Resolved_Type (Agg_Tree.Prefix);
               begin
                  if Agg_Type /= null then
                     if Debug_Second_Pass then
                        Put_Line
                          ("  class agg has prefix, recursing with " &
                           Type_Image (Agg_Type));
                     end if;
                     Create_Class_Agg_Interp (Agg_Sem, Agg_Type, Diagnose);
                     return;
                  end if;
               end;
            end if;
            if Debug_Second_Pass then
               Put_Line
                 ("  returning immediately because " &
                  Type_Image (Target_Type) & " is polymorphic");
            end if;
            return;
         end;
      end if;

      if Target_Type /= null
        and then (Diagnose or else
                  not Interpretations.Has_Type_Region
                       (Agg_Sem.Interps,
                        U_Base_Type_Region (Target_Type)))
      then
         --  Don't already have an interp for this type
         --  See whether this type works.
         --  TBD: Make sure at least one component is visible.
         --      If any components are visible, then all non-visible
         --      components must have defaults (and hence be "var"s).
         declare
            Class_Agg : Invocation.Tree
              renames Invocation.Tree (Tree_Ptr_Of (Agg_Sem.Definition).all);
            Num_Comps : constant Natural :=
              Num_Components (Target_Type.Associated_Module);
            Num_Operands : constant Natural :=
              Lists.Length (Class_Agg.Operands);
            Canonical_Operands : Lists.List;
            Generic_Param_Map : Param_Mapping_Ptr;
            Ambiguity : Ambiguity_List := null;
            Interp_Added : Boolean;
         begin

            --  Add an empty interp so we know we have tried this one
            Interpretations.Add_Interp
              (Agg_Sem.Interps,
               Associated_Type_Region => U_Base_Type_Region (Target_Type),
               Interp => Null_Optional_Tree,
               Interp_Added => Interp_Added);

            if Num_Comps = 0 and then Num_Operands > 0 then
               --  Can't possibly match
               if Debug_Second_Pass then
                  Put_Line
                    (" class has no components " & Type_Image (Target_Type));
               end if;
               if Diagnose then
                  Messages.Put_Message
                    ("class " &
                     Type_Image (Target_Type, Use_Short_Form => True,
                       Max_Chars => 100) &
                     " has no components; aggregate should be simply ()",
                     Src_Pos => Find_Source_Pos (Agg_Sem.Definition),
                     Message_Kind => "Info");
               end if;
               return; --------- Doesn't match
            end if;

            if Num_Comps > 0 then
               Canonicalize_Components
                 (Num_Formals => Num_Comps,
                  Actual_Construct => Agg_Sem.Definition,
                  Actual_Operands => Class_Agg.Operands,
                  Assoc_Type_Region => U_Base_Type_Region (Target_Type),
                  Resolved_Operand_List => Canonical_Operands,
                  Generic_Param_Map => Generic_Param_Map,
                  Ambiguity => Ambiguity,
                  Diagnose => Diagnose);

               if Lists.Is_Empty (Canonical_Operands) then
                  return;   --  Doesn't resolve
               end if;

               --  We don't have the notion of "generic" components
               pragma Assert (Generic_Param_Map = null);

            else
               Canonical_Operands := Lists.Empty_List;
            end if;

            --  OK, we now have a list of resolved operands.
            --  Create an interpretation for that.
            declare
               Resolved_Agg : Optional_Tree;
               Resolved_Agg_Sem : constant Class_Agg_Sem_Ptr :=
                 new Class_Aggregate_Semantic_Info'Class'(Agg_Sem.all);
               use Invocation;
            begin

               Resolved_Agg :=
                  Invocation.Make
                    (Class_Aggregate,
                     Prefix => Class_Agg.Prefix,  --  Preserve prefix
                     Operands => Canonical_Operands,
                     Source_Pos => Find_Source_Pos (Agg_Sem.Definition));

               Resolved_Agg_Sem.Definition := Resolved_Agg;
               Resolved_Agg_Sem.Ambiguity := Ambiguity;
               Resolved_Agg_Sem.Interps := null;
               Resolved_Agg_Sem.Target_Type := Target_Type;
               Resolved_Agg_Sem.Resolved_Type := Target_Type;

               Set_Sem_Info (Resolved_Agg, Root_Sem_Ptr (Resolved_Agg_Sem));

               if Debug_Second_Pass then
                  Put_Line
                    (" Add class-agg interp for " &
                     Subtree_Image (Agg_Sem.Definition) &
                     " as " &
                     Subtree_Image (Resolved_Agg) &
                     " of type " &
                     Type_Image (Target_Type));
               end if;

               Interpretations.Add_Interp
                 (Agg_Sem.Interps,
                  Associated_Type_Region => U_Base_Type_Region (Target_Type),
                  Interp => Resolved_Agg,
                  Interp_Added => Interp_Added);
            end;

         end;
      end if;
   end Create_Class_Agg_Interp;

   procedure Create_Container_Agg_Interp
     (Agg_Sem : Container_Agg_Sem_Ptr;
      Target_Type : Type_Sem_Ptr;
      Diagnose : Boolean := False) is
   --  Create interp for container aggregate of given Target_Type,
   --  presuming have already created interps for components.
   --  If Diagnose is True, then indicate why aggregate does *not* match type.
   begin
      if Debug_Second_Pass then
         Put_Line
           ("Trying to create container agg interp of " &
            Subtree_Image (Agg_Sem.Definition) &
            " of type " &
            Type_Image (Target_Type));
      end if;

      if Target_Type /= null
        and then (Diagnose or else
                  not Interpretations.Has_Type_Region
                       (Agg_Sem.Interps,
                        U_Base_Type_Region (Target_Type)))
      then
         --  Don't already have an interp for this type
         --  See whether this type works.
         declare
            Container_Agg : Invocation.Tree
              renames Invocation.Tree (Tree_Ptr_Of (Agg_Sem.Definition).all);
            Num_Operands : constant Natural :=
              Lists.Length (Container_Agg.Operands);
            Resolved_Operands : array (1 .. Num_Operands) of Optional_Tree :=
              (others => Null_Optional_Tree);
            Resolved_Keys : array (1 .. Num_Operands) of Optional_Tree :=
              (others => Null_Optional_Tree);
            Iterating_Operands : array (1 .. Num_Operands) of Optional_Tree :=
              (others => Null_Optional_Tree);
            Seen_Named_Operand : Boolean := False;
            Seen_Positional_Operand : Boolean := False;
            Var_Indexing_Op : constant Operation_Sem_Ptr :=
              Find_Var_Indexing_Op_For (Target_Type);
            Combiner_Op : constant Operation_Sem_Ptr :=
              Find_Combine_Move_Op_For (Target_Type);
            Index_Type : Type_Sem_Ptr := null;
            Element_Type : Type_Sem_Ptr := null;
            Combiner_Element_Type : Type_Sem_Ptr := null;
            Interp_Added : Boolean;
            Ambiguity : Ambiguity_List := null;
         begin

            --  Add an empty interp so we know we have tried this one
            Interpretations.Add_Interp
              (Agg_Sem.Interps,
               Associated_Type_Region => U_Base_Type_Region (Target_Type),
               Interp => Null_Optional_Tree,
               Interp_Added => Interp_Added);

            if Var_Indexing_Op /= null then
               --  Get Index_Type and Element_Type from Indexing op
               Index_Type :=
                  Substitute_Actuals
                    (Resolved_Type
                        (Lists.Nth_Element
                            (Operation.Tree (Tree_Ptr_Of
                              (Var_Indexing_Op.Definition).all).
                                Operation_Inputs,
                             2)),
                     U_Base_Type_Region (Target_Type));
               Element_Type := Get_Func_Output_Type (Var_Indexing_Op,
                 U_Base_Type_Region (Target_Type));
               if Element_Type /= null
                 and then Element_Type.Associated_Module /= null
                 and then Element_Type.Associated_Module.Contains_Ref_Component
               then
                  --  "var_indexing" returns a "ref" object;
                  --  see what "ref" func returns
                  Element_Type := Get_Ref_Func_Output_Type (Element_Type);
               end if;
            end if;
            if Combiner_Op /= null then
               --  No Index_Type.  Just get Element_Type from combiner
               Combiner_Element_Type :=
                  Substitute_Actuals
                    (Resolved_Type
                        (Lists.Nth_Element
                            (Operation.Tree (Tree_Ptr_Of
                               (Combiner_Op.Definition).all).Operation_Inputs,
                             2)),
                     U_Base_Type_Region (Target_Type));
            end if;
            if Element_Type = null and then Combiner_Element_Type = null then
               if Debug_Second_Pass then
                  Put_Line ("  No ""var_indexing"" and no ""<|="" found");
               end if;
               if Diagnose then
                  Messages.Put_Message
                    (Type_Image (Target_Type, Use_Short_Form => True,
                       Max_Chars => 100) &
                     " has no ""var_indexing"" and no ""<|="" operations",
                     Src_Pos => Find_Source_Pos (Agg_Sem.Definition),
                     Message_Kind => "Info");
               end if;
               return; ---------  Doesn't match
            end if;

            if Element_Type /= null
              and then Combiner_Element_Type /= null
              and then not Types_Match (Element_Type, Combiner_Element_Type)
            then
               if Debug_Second_Pass then
                  Put_Line
                    ("  ""<|="" and ""var_indexing"" have " &
                       "different element types");
               end if;

            end if;

            for I in 1 .. Num_Operands loop
               declare
                  Operand : constant Optional_Tree :=
                    Lists.Nth_Element (Container_Agg.Operands, I);
                  Operand_Tree : Trees.Tree'Class
                    renames Tree_Ptr_Of (Operand).all;
                  Generic_Param_Map : Param_Mapping_Ptr := null;
                  Ambig1 : Ambiguity_List;
               begin
                  if Operand_Tree in For_Loop_Construct.Tree then
                     --  Iterator in aggregate
                     declare
                        For_Loop_Tree : For_Loop_Construct.Tree renames
                          For_Loop_Construct.Tree (Operand_Tree);
                        Loop_Body : constant Optional_Tree :=
                          For_Loop_Tree.Loop_Body;
                        Loop_Body_Tree : Trees.Tree'Class renames
                          Tree_Ptr_Of (Loop_Body).all;
                        Loop_Iterator : constant Optional_Tree :=
                          Lists.Nth_Element
                            (For_Loop_Tree.Iterators, 1);
                        Iterator_Sem : constant Iterator_Sem_Ptr :=
                          Iterator_Sem_Ptr (Sem_Info (Loop_Iterator));

                        Key : Optional_Tree := Null_Optional_Tree;
                        Value : Optional_Tree := Null_Optional_Tree;

                        use type Interpreter.Direction;
                     begin
                        if I > 1 or else I < Num_Operands then
                           --  We don't support an iterator combined
                           --  with other "regular" operands.
                           Sem_Error (Operand_Tree,
                             "NYI: No support for iterator in " &
                               "aggregate with multiple operands");
                        end if;

                        Iterating_Operands (I) := Operand;

                        if Loop_Body_Tree in Reference.Tree then
                           --  We have "for I in 1..X, Key => Value"
                           if Index_Type = null then
                              if Debug_Second_Pass then
                                 Put_Line
                                   ("  No ""var_indexing"" op found");
                              end if;
                              return; ---------  Doesn't match
                           end if;
                           Key := Reference.Tree (Loop_Body_Tree).Key;

                           Seen_Named_Operand := True;

                           Find_Interp_Of_Type
                             (U_Base_Type_Region (Target_Type),
                              Key,
                              Index_Type,
                              Generic_Param_Map,
                              Resolved_Keys (I),
                              Ambig1);

                           --  No "generic" type matches allowed here
                           pragma Assert (Generic_Param_Map = null);

                           Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);

                           if Is_Null (Resolved_Keys (I)) then
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" container agg key " &
                                    Subtree_Image (Key) & " does not " &
                                      "match container index type " &
                                    Type_Image (Index_Type));
                              end if;
                              if Diagnose then
                                 Messages.Put_Message
                                   ("key " &
                                    Subtree_Image (Key, Use_Short_Form => True,
                                      Max_Chars => 100) & " does not " &
                                      "match container index type " &
                                    Type_Image (Index_Type,
                                      Use_Short_Form => True,
                                      Max_Chars => 100),
                                    Src_Pos => Find_Source_Pos (Key),
                                    Message_Kind => "Info");
                              end if;
                              return; --------- Doesn't match
                           end if;

                           Value := Reference.Tree
                             (Loop_Body_Tree).Referent;
                        else
                           --  We have "for I in 1..X => Value"
                           --  Might be considered named or positional.
                           --  We will interpret as positional if
                           --  "reverse" or "forward" is specified, or if
                           --  a filter in {...} is specified, or if
                           --  there is no "var_indexing" operator, or
                           --  the "var_indexing" operator doesn't resolve.

                           Value := Loop_Body;
                        end if;

                        if Is_Null (Key)
                          and then (Index_Type = null
                            or else Iterator_Sem.Iterator_Direction /=
                              Interpreter.Unordered_Dir
                            or else Not_Null (For_Loop_Tree.Filter))
                        then
                           --  Use combiner op.
                           Element_Type := Combiner_Element_Type;
                           Index_Type := null;
                           Seen_Positional_Operand := True;
                        end if;

                        Find_Interp_Of_Type
                          (U_Base_Type_Region (Target_Type),
                           Value,
                           Element_Type,
                           Generic_Param_Map,
                           Resolved_Operands (I),
                           Ambig1);

                        --  No "generic" type matches allowed here
                        pragma Assert (Generic_Param_Map = null);

                        Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);

                        --  Use var-indexing op if key is null
                        --  only when there is no combiner op.

                        if Index_Type /= null and then Is_Null (Key) then
                           --  Index type of container must match either the
                           --  iterator parameter or the iterator key
                           if not Types_Match (Index_Type,
                               Iterator_Sem.Resolved_Type)
                             and then
                               (Iterator_Sem.Key_Sem = null
                                or else not Types_Match (Index_Type,
                                    Iterator_Sem.Key_Sem.Resolved_Type))
                           then
                              --  Not an exact match; see whether
                              --  implicit conversion to/from univ type
                              --  would work.
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" iterator key/value in container"
                                    & " agg do not exactly match "
                                    & "container index type " &
                                    Type_Image (Index_Type));
                              end if;
                              if not Implicitly_Converts
                                 (From => Iterator_Sem.Resolved_Type,
                                  To => Index_Type)
                                and then
                                 (Iterator_Sem.Key_Sem = null
                                  or else not Implicitly_Converts
                                    (From =>
                                      Iterator_Sem.Key_Sem.Resolved_Type,
                                     To => Index_Type))
                              then
                                 if Debug_Second_Pass then
                                    Put_Line
                                      (" iterator key/value in container"
                                       & " agg do not implicitly conv "
                                       & "to container index type " &
                                       Type_Image (Index_Type));
                                 end if;
                                 --  Doesn't match "var_indexing"
                                 Resolved_Operands (I) := Null_Optional_Tree;
                              end if;
                           end if;
                        end if;

                        if Is_Null (Resolved_Operands (I)) then
                           if Index_Type = null
                             or else Combiner_Element_Type /= null
                           then
                              if Diagnose then
                                 Messages.Put_Message
                                   (Subtree_Image (Operand,
                                      Use_Short_Form => True,
                                      Max_Chars => 100) & " does not " &
                                      "match operations on container type " &
                                    Type_Image (Target_Type,
                                      Use_Short_Form => True,
                                      Max_Chars => 100),
                                    Src_Pos => Find_Source_Pos (Operand),
                                    Message_Kind => "Info");
                              end if;
                              return;  ----  Doesn't match at all  ----
                           end if;

                           --  Try "<|="
                           Element_Type := Combiner_Element_Type;
                           Index_Type := null;
                           Seen_Positional_Operand := True;

                           Find_Interp_Of_Type
                             (U_Base_Type_Region (Target_Type),
                              Value,
                              Element_Type,
                              Generic_Param_Map,
                              Resolved_Operands (I),
                              Ambig1);

                           --  No "generic" type matches allowed here
                           pragma Assert (Generic_Param_Map = null);

                           Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);
                        end if;

                     end;
                  elsif Operand_Tree not in Reference.Tree then
                     --  We have a positional operand.
                     --  Use combiner's element type.
                     Element_Type := Combiner_Element_Type;
                     Index_Type := null;
                     Seen_Positional_Operand := True;

                     Find_Interp_Of_Type
                       (U_Base_Type_Region (Target_Type),
                        Operand,
                        Element_Type,
                        Generic_Param_Map,
                        Resolved_Operands (I),
                        Ambig1);
                     Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);

                     --  No "generic" type matches allowed here
                     pragma Assert (Generic_Param_Map = null);

                  elsif Index_Type = null then
                     if Debug_Second_Pass then
                        Put_Line ("  No ""var_indexing"" op found");
                     end if;
                     if Diagnose then
                        Messages.Put_Message
                          ("Named notation [... " &
                           Subtree_Image (Operand, Use_Short_Form => True,
                             Max_Chars => 100) &
                           " ...] not allowed because no ""var_indexing"" " &
                           "operation is available.",
                           Src_Pos => Find_Source_Pos (Operand),
                           Message_Kind => "Info");
                     end if;
                  else
                     --  We have Keys => Value and the container is
                     --  indexable
                     declare
                        Keys : constant Optional_Tree :=
                          Reference.Tree (Operand_Tree).Key;
                        Value : constant Optional_Tree :=
                          Reference.Tree (Operand_Tree).Referent;
                        Keys_Tree : Trees.Tree'Class
                          renames Tree_Ptr_Of (Keys).all;
                     begin
                        Find_Interp_Of_Type
                          (U_Base_Type_Region (Target_Type),
                           Value,
                           Element_Type,
                           Generic_Param_Map,
                           Resolved_Operands (I),
                           Ambig1);

                        --  No "generic" type matches allowed here
                        pragma Assert (Generic_Param_Map = null);

                        Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);

                        --  TBD: Support Keys being a set

                        Find_Interp_Of_Type
                          (U_Base_Type_Region (Target_Type),
                           Keys,
                           Index_Type,
                           Generic_Param_Map,
                           Resolved_Keys (I),
                           Ambig1);

                        --  No "generic" type matches allowed here
                        pragma Assert (Generic_Param_Map = null);

                        Ambiguity := Combine_Ambiguity (Ambiguity, Ambig1);

                        if Is_Null (Resolved_Keys (I)) then
                           if Debug_Second_Pass then
                              Put_Line
                                (" container agg, key of " &
                                 Subtree_Image (Operand) &
                                 " does not match container index type "
                                 &
                                 Type_Image (Index_Type));
                           end if;
                           if Diagnose then
                              Messages.Put_Message
                                ("key of " &
                                 Subtree_Image (Operand,
                                   Use_Short_Form => True,
                                   Max_Chars => 100) &
                                 " does not match container index type "
                                 &
                                 Type_Image (Index_Type,
                                   Use_Short_Form => True, Max_Chars => 100),
                                 Src_Pos => Find_Source_Pos (Operand),
                                 Message_Kind => "Info");
                           end if;
                           return; --------- Doesn't match
                        end if;

                        Seen_Named_Operand := True;
                     end;
                  end if;

                  if Seen_Named_Operand and Seen_Positional_Operand then
                     --  TBD: Allow ".." as last in positional aggregate.
                     Sem_Error
                       (Agg_Sem.Definition,
                        "Container aggregate elements must all be " &
                        "named if any are named");
                     return; --------- Doesn't match
                  end if;

                  if Is_Null (Resolved_Operands (I)) then
                     if Debug_Second_Pass then
                        Put_Line
                          (" container agg, operand " &
                           Subtree_Image (Operand) &
                           " does not match container component type " &
                           Type_Image (Element_Type));
                     end if;
                     if Diagnose and then Element_Type /= null then
                        Messages.Put_Message
                          ("operand " &
                           Subtree_Image (Operand, Use_Short_Form => True,
                             Max_Chars => 100) &
                           " does not match container component type " &
                           Type_Image (Element_Type, Use_Short_Form => True,
                             Max_Chars => 100),
                           Src_Pos => Find_Source_Pos (Operand),
                           Message_Kind => "Info");
                     end if;
                     return; --------- Doesn't match
                  end if;
               end;
            end loop;

            --  OK, we now have a list of resolved operands.
            --  Create an interpretation for that.
            declare
               Operand_List : Lists.List := Lists.Empty_List;
               Resolved_Agg : Optional_Tree;
               Resolved_Agg_Sem : constant Container_Agg_Sem_Ptr :=
                 new Container_Aggregate_Semantic_Info'Class'
                   (Agg_Sem.all);
               use Invocation;
            begin
               --  Build up the list of resolved operands
               for I in 1 .. Num_Operands loop
                  declare
                     Resolved_Element : Optional_Tree;
                  begin
                     if Not_Null (Resolved_Keys (I)) then
                        Resolved_Element := Reference.Make
                          (Key => Resolved_Keys (I),
                           Referent => Resolved_Operands (I));
                     else
                        Resolved_Element := Resolved_Operands (I);
                     end if;
                     if Not_Null (Iterating_Operands (I)) then
                        --  Build a resolved tree containing iterator
                        declare
                           Loop_Tree : For_Loop_Construct.Tree renames
                             For_Loop_Construct.Tree (Tree_Ptr_Of
                               (Iterating_Operands (I)).all);
                        begin
                           --  Fill in the enclosing container agg sem
                           For_Loop_Construct_Sem_Ptr
                             (Loop_Tree.Sem_Info).
                               Enclosing_Container_Agg_Sem :=
                                 Resolved_Agg_Sem;

                           --  Replace body with resolved body
                           Resolved_Element :=
                             For_Loop_Construct.Replace_Body
                               (Loop_Tree, Resolved_Element);

                           --  Carry forward the sem info.
                           Set_Sem_Info (Resolved_Element,
                             Loop_Tree.Sem_Info);
                        end;
                     end if;
                     Lists.Append (Operand_List, Resolved_Element);
                  end;
               end loop;

               Resolved_Agg :=
                  Invocation.Make
                    (Kind => Resolved_Agg_Sem.Aggregate_Kind,
                     Prefix => Container_Agg.Prefix,  --  Preserve prefix
                     Operands => Operand_List,
                     Source_Pos => Find_Source_Pos (Agg_Sem.Definition));

               Resolved_Agg_Sem.Ambiguity := Ambiguity;
               Resolved_Agg_Sem.Definition := Resolved_Agg;
               Resolved_Agg_Sem.Interps := null;
               Resolved_Agg_Sem.Target_Type := Target_Type;
               Resolved_Agg_Sem.Resolved_Type := Target_Type;
               Resolved_Agg_Sem.Index_Type := Index_Type;
               Resolved_Agg_Sem.Element_Type := Element_Type;

               Set_Sem_Info
                 (Resolved_Agg,
                  Root_Sem_Ptr (Resolved_Agg_Sem));

               if Debug_Second_Pass then
                  Put_Line
                    (" Add container-agg interp for " &
                     Subtree_Image (Agg_Sem.Definition) &
                     " as " &
                     Subtree_Image (Resolved_Agg) &
                     " of type " &
                     Type_Image (Target_Type));
               end if;

               Interpretations.Add_Interp
                 (Agg_Sem.Interps,
                  Associated_Type_Region =>
                     U_Base_Type_Region (Target_Type),
                  Interp => Resolved_Agg,
                  Interp_Added => Interp_Added);
            end;

         end;
      end if;
   end Create_Container_Agg_Interp;

   function Create_From_Univ_Call
     (Operand : Optional_Tree;
      To_Type : Type_Sem_Ptr)
      return Optional_Tree
   is
      --  Create call on "from_univ" from given Operand which
      --  is of a universal type, to the target To_Type.
      From_Univ_Interps : Interpretations.Interp_Tree := null;
      use type Interpretations.Interp_Tree;

   begin  --  Create_From_Univ_Call

      --  Check whether this is a variable/ref-param of a universal type.
      --  We don't allow declared variables or by-ref parameters
      --  to be implicitly converted.

      if Sem_Info (Operand) /= null then
         if Sem_Info_Is_For_Variable (Underlying_Sem_Info (Operand)) then
            --  We have a variable.
            return Null_Optional_Tree;
         elsif Sem_Info (Operand).all in Sym_Reference_Info then
            declare
               Opnd_Sym : constant Symbols.Sym_Ptr :=
                 Sym_Ref_Ptr (Sem_Info (Operand)).Associated_Symbol;
               use type Symbols.Sym_Ptr;
            begin
               if Opnd_Sym /= null
                 and then Sym_Is_Declared_Ref (Opnd_Sym)
               then
                  --  We have a "ref"
                  return Null_Optional_Tree;
               end if;
            end;
         end if;
      end if;

      Add_Operation_Interps
        (From_Univ_Interps,
         U_Base_Type_Region (To_Type),
         From_Univ_Str,
         Source_Pos => Find_Source_Pos (Operand));

      if not Interpretations.Has_Interp (From_Univ_Interps) then
         --  No "from_univ" in region of target type.
         return Null_Optional_Tree;
      else
         --  We have at least one interp for "from_univ"
         --  declared in target type's region.
         --  Create a call on it and see if it resolves.
         declare
            From_Univ_Op : constant Optional_Tree :=
              PSC.Trees.Identifier.Make
                 (From_Univ_Str,
                  Source_Pos => Find_Source_Pos (Operand));
            From_Univ_Sem : constant Operand_Sem_Ptr :=
              new Sym_Reference_Info;
            From_Univ_Call : constant Optional_Tree :=
              Invocation.Make
                 (Kind => Invocation.Operation_Call,
                  Prefix => From_Univ_Op,
                  Operands => Lists.Make
                    ((1 => Make_Copy_Of_Operand (Operand))));
         begin
            From_Univ_Sem.Interps := From_Univ_Interps;
            Set_Sem_Info (From_Univ_Op, Root_Sem_Ptr (From_Univ_Sem));
            if Debug_Second_Pass then
               Put_Line
                 ("  Operand " &
                  Subtree_Image (Operand) &
                  " is of univ type possibly convertible to " &
                  Type_Image (To_Type));
            end if;
            Create_Call_Interps (From_Univ_Call);

            return From_Univ_Call;
         end;
      end if;
   end Create_From_Univ_Call;

   function Create_To_Univ_Call
     (Operand : Optional_Tree;
      To_Univ_Type : Type_Sem_Ptr)
      return Optional_Tree
   is
      --  Create call on "to_univ" from given Operand which
      --  is of a non-universal type, to the target To_Univ_Type.
      Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Operand);
      pragma Assert (not Opnd_Type.Is_Universal);

      To_Univ_Interps : Interpretations.Interp_Tree := null;

      use type Interpretations.Interp_Tree;

   begin  --  Create_To_Univ_Call

      Add_Operation_Interps
        (To_Univ_Interps,
         U_Base_Type_Region (Opnd_Type),
         To_Univ_Str,
         Source_Pos => Find_Source_Pos (Operand));

      if not Interpretations.Has_Interp (To_Univ_Interps) then
         --  No "to_univ" in region of target type.
         return Null_Optional_Tree;
      else
         --  We have at least one interp for "to_univ"
         --  declared in target type's region.
         --  Create a call on it and see if it resolves.
         declare
            To_Univ_Op : constant Optional_Tree :=
              PSC.Trees.Identifier.Make
                 (To_Univ_Str,
                  Source_Pos => Find_Source_Pos (Operand));
            To_Univ_Sem : constant Operand_Sem_Ptr :=
              new Sym_Reference_Info;
            To_Univ_Call : constant Optional_Tree :=
              Invocation.Make
                 (Kind => Invocation.Operation_Call,
                  Prefix => To_Univ_Op,
                  Operands => Lists.Make
                    ((1 => Make_Copy_Of_Operand (Operand))));
         begin
            To_Univ_Sem.Interps := To_Univ_Interps;
            Set_Sem_Info (To_Univ_Op, Root_Sem_Ptr (To_Univ_Sem));
            if Debug_Second_Pass then
               Put_Line
                 ("  Operand " &
                  Subtree_Image (Operand) &
                  " is of type possibly convertible to univ type " &
                  Type_Image (To_Univ_Type));
            end if;
            Create_Call_Interps (To_Univ_Call);

            return To_Univ_Call;
         end;
      end if;
   end Create_To_Univ_Call;

   function Create_Ref_Call (Operand : Optional_Tree) return Optional_Tree is
      --  Create call on "ref" from given Operand which
      --  is of a ref-obj type
      Ref_Interps : Interpretations.Interp_Tree := null;
      use type Interpretations.Interp_Tree;
      Opnd_Type : constant Type_Sem_Ptr := Resolved_Type (Operand);

   begin  --  Create_Ref_Call

      if Opnd_Type = null
        or else Opnd_Type.Associated_Module = null
        or else not Opnd_Type.Associated_Module.Contains_Ref_Component
      then
         --  Not a "ref-obj" type, so don't even look for a "ref" operation
         return Null_Optional_Tree;
      end if;

      Add_Operation_Interps
        (Ref_Interps,
         U_Base_Type_Region (Opnd_Type),
         Ref_Op_Str,
         Source_Pos => Find_Source_Pos (Operand));

      if not Interpretations.Has_Interp (Ref_Interps) then
         --  No "ref" in region of operand type.
         return Null_Optional_Tree;
      else
         --  We have at least one interp for "ref"
         --  declared in operand type's region.
         --  Create a call on it and see if it resolves.
         declare
            Ref_Op : constant Optional_Tree :=
              PSC.Trees.Identifier.Make
                 (Ref_Op_Str,
                  Source_Pos => Find_Source_Pos (Operand));
            Ref_Sem : constant Operand_Sem_Ptr :=
              new Sym_Reference_Info;
            Ref_Call : constant Optional_Tree :=
              Invocation.Make
                 (Kind => Invocation.Operation_Call,
                  Prefix => Ref_Op,
                  Operands => Lists.Make
                    ((1 => Make_Copy_Of_Operand (Operand))));
         begin
            Ref_Sem.Interps := Ref_Interps;
            Set_Sem_Info (Ref_Op, Root_Sem_Ptr (Ref_Sem));
            if Debug_Second_Pass then
               Put_Line
                 ("  Operand " &
                  Subtree_Image (Operand) &
                  " is of ref-obj type");
            end if;
            Create_Call_Interps (Ref_Call);

            return Ref_Call;
         end;
      end if;
   end Create_Ref_Call;

   procedure Insert_Ref_Calls (Expr : Optional_Tree) is
   --  Insert calls on "ref" to each interpretation that is of a ref-obj type
      Opnd_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Expr));
   begin
      if Opnd_Sem /= null
        and then Opnd_Sem.all in Operand_Semantic_Info'Class
      then
         declare
            New_Interps : Interpretations.Interp_Tree := null;
            Inserted_A_Call : Boolean := False;

            procedure Try_One_Ref_Call
              (Associated_Type_Region : Type_Region_Ptr;
               Interp : Trees.Optional_Tree) is
               Ref_Call : constant Optional_Tree := Create_Ref_Call (Interp);
               Interp_Added : Boolean := False;
            begin
               if Not_Null (Ref_Call) then
                  --  Add "ref" call interpretations
                  Interpretations.Add_Interp_Tree (New_Interps,
                    From_Interps =>
                      Operand_Sem_Ptr (Sem_Info (Ref_Call)).Interps);
                  Inserted_A_Call := True;
               else
                  --  Add original interpretation back onto tree
                  Interpretations.Add_Interp (New_Interps,
                    Associated_Type_Region, Interp, Interp_Added);
               end if;
            end Try_One_Ref_Call;

            procedure Try_Ref_Calls is new
              Interpretations.Iterate_Interps (Try_One_Ref_Call);

         begin
            --  Try to insert "ref" calls
            Try_Ref_Calls (Operand_Sem_Ptr (Opnd_Sem).Interps);

            if Inserted_A_Call then
               --  Replace interps tree
               Operand_Sem_Ptr (Opnd_Sem).Interps := New_Interps;
               --  Wipe out resolved interp, if any
               Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp :=
                 Null_Optional_Tree;
            end if;
         end;
      end if;
   end Insert_Ref_Calls;

   procedure Update_Outermost_Module_Use_In_Tree
     (Resolved_Interp : Optional_Tree;
      Enc_Module : Module_Sem_Ptr;
      Only_If_Typed : Boolean := False) is
   --  Update outermost-module-where-used for each type appearing
   --  in resolved tree.
   --  Return immediately if resolved type is null and Only_If_Typed is true
   begin
      if Enc_Module /= null and then Not_Null (Resolved_Interp) then
         declare
            Resolved_Interp_Type : constant Type_Sem_Ptr :=
              Resolved_Type (Resolved_Interp);
            Resolved_Interp_Tree : Trees.Tree'Class
              renames Tree_Ptr_Of (Resolved_Interp).all;
            Resolved_Sem : constant Sem_Ptr :=
              Underlying_Sem_Info (Resolved_Interp);
         begin
            if Resolved_Interp_Type /= null then
               --  Make sure resolved type is lifted to current module
               Update_Outermost_Module_Where_Used
                 (Resolved_Interp_Type, Enc_Module);

            elsif Only_If_Typed then
               return;  --  Quit early

            end if;

            if Resolved_Sem /= null
              and then Resolved_Sem.all in Resolved_Operation_Info'Class
            then
               --  This is a call or a function pointer;
               --  "lift" the associated type if necessary.
               declare
                  Assoc_Type : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (Resolved_Op_Ptr (Resolved_Sem).
                      Assoc_Type_Region);
               begin
                  if Assoc_Type /= null then
                     --  Make sure assoc type is lifted to current module
                     Update_Outermost_Module_Where_Used
                       (Assoc_Type, Enc_Module);
                  end if;
               end;
            end if;
            for I in 1 .. Num_Operands (Resolved_Interp_Tree) loop
               declare
                  Resolved_Operand : constant Optional_Tree :=
                    Resolved_Tree (Nth_Operand (Resolved_Interp_Tree, I));
               begin
                  if Resolved_Operand /= Resolved_Interp then
                     --  Update operand unless this would recurse infinitely
                     Update_Outermost_Module_Use_In_Tree
                       (Resolved_Operand, Enc_Module, Only_If_Typed => True);
                  end if;
               end;
            end loop;
         end;
      end if;
   end Update_Outermost_Module_Use_In_Tree;

   procedure Diagnose_Unresolved_Expr
     (Expr : Optional_Tree;
      Resolved_Type : Type_Sem_Ptr;
      Expr_Opnd_Sem : Operand_Sem_Ptr) is
      --  Try to give more information about expression that does
      --  not resolve.

      Resolved_Interp : Optional_Tree := Null_Optional_Tree;
      Generic_Param_Map : Param_Mapping_Ptr := null;
      Ambiguity : Ambiguity_List := null;
   begin
      Find_Interp_Of_Type
        (null,
         Expr,
         Resolved_Type,
         Generic_Param_Map,
         Resolved_Interp,
         Ambiguity,
         Diagnose => True);
   end Diagnose_Unresolved_Expr;

   procedure Diagnose_Ambiguity
     (Ambiguity : Ambiguity_List) is
      --  Try to give more information about expression that is ambiguous
   begin
      if Ambiguity /= null then
         if Not_Null (Ambiguity.This_Interp) then
            --  Report list of ambiguous constructs
            Report_Ambiguity (Ambiguity.This_Interp);
            Diagnose_Ambiguity (Ambiguity.Next_Ambig_Interp);
         else
            --  Or report an individual ambiguous operand
            --  TBD: We don't display the whole tree, to avoid overloading
            --       the reader.
            Diagnose_Ambiguity (Ambiguity.Ambiguous_Operands);
         end if;
      end if;
   end Diagnose_Ambiguity;

   procedure Resolve_Expression
     (Visitor : in out Sem_Second_Pass_Visitor'Class;
      Expr : Optional_Tree;
      Resolved_Type : in out Type_Sem_Ptr;
      Call_Ref : Boolean := False) is
      --  Resolve type of expression
      --  If Resolved_Type is non-null coming in, it determines the type.
      --  In any case, upon return, Resolved_Type contains
      --  the final type after resolution.
      --  If Resolved_Type is null coming in, and Call_Ref is True, then
      --  insert a call on "ref" if result is a ref-object.
      Expr_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (Expr));
      use type Interpretations.Interp_Tree;

      function Unresolved_Operation (Expr : Optional_Tree) return String is
         --  Return name of operation in unresolved call/unary/binary op
         Expr_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Expr).all;
      begin
         if Expr_Tree in Unary.Tree then
            --  Skip over unary operator if operand also unresolved
            declare
               Operand : constant Optional_Tree :=
                 Unary.Tree (Expr_Tree).Operand;
               Operand_Sem : constant Sem_Ptr :=
                 Sem_Ptr (Sem_Info (Operand));
            begin
               if Operand_Sem.all in Call_Semantic_Info'Class
                 and then not Interpretations.Has_Interp
                                (Call_Sem_Ptr (Operand_Sem).Interps)
               then
                  --  Operand also unresolved
                  return Unresolved_Operation
                           (Invocation.Remove_Parentheses (Operand));
               end if;
            end;
         end if;

         --  Return name of operation/operator.
         return Name_Of_Operation (Invocation.Remove_Parentheses (Expr));
      end Unresolved_Operation;

   begin  --  Resolve_Expression

      if Expr_Sem /= null
        and then Expr_Sem.all in Operand_Semantic_Info'Class
      then
         declare
            Expr_Opnd_Sem : constant Operand_Sem_Ptr :=
              Operand_Sem_Ptr (Expr_Sem);
            use type Binary.Binary_Operator_Enum;
         begin
            if Debug_Second_Pass then
               Put_Line
                 ("Resolving " &
                  Subtree_Image (Expr, Use_Short_Form => True));
            end if;

            if Is_Null (Expr_Opnd_Sem.Resolved_Interp) then
               --  Not yet resolved to a single interp
               if Resolved_Type /= null then
                  --  Add interpretations based on target type;
                  Add_Targeted_Interps (Expr, Resolved_Type);
               elsif Call_Ref then
                  --  Insert "ref" calls
                  Insert_Ref_Calls (Expr);
               end if;

               if Not_Null (Expr_Opnd_Sem.Resolved_Interp) then
                  --  Nothing more to do
                  null;
               elsif Interpretations.Has_Interp (Expr_Opnd_Sem.Interps) then
                  --  Need to resolve multiple interpretations
                  declare
                     Resolved_Interp : Optional_Tree := Null_Optional_Tree;
                     Generic_Param_Map : Param_Mapping_Ptr := null;
                     Ambiguity : Ambiguity_List := null;
                  begin
                     if Debug_Second_Pass then
                        Put_Line ("  Has interp tree");
                     end if;

                     Find_Interp_Of_Type
                       (null,
                        Expr,
                        Resolved_Type,
                        Generic_Param_Map,
                        Resolved_Interp,
                        Ambiguity);

                     --  No "generic" type matches allowed here
                     pragma Assert (Generic_Param_Map = null);

                     Expr_Opnd_Sem.Resolved_Interp := Resolved_Interp;
                     Expr_Opnd_Sem.Ambiguity := Ambiguity;

                     if Not_Null (Resolved_Interp) then

                        Expr_Opnd_Sem.Resolved_Type :=
                           Info.Resolved_Type (Resolved_Interp);

                        if Resolved_Type = null then
                           Resolved_Type := Expr_Opnd_Sem.Resolved_Type;
                        elsif Expr_Opnd_Sem.Resolved_Type =
                              Optional_Type
                        then
                           --  Fill in resolved type for "null"
                           Expr_Opnd_Sem.Resolved_Type := Resolved_Type;
                        end if;

                        if Debug_Second_Pass then
                           Put_Line
                             ("  Chosen interp: " &
                              Subtree_Image
                                 (Resolved_Interp,
                                  Use_Short_Form => True) &
                              " of type " &
                              Type_Image (Expr_Opnd_Sem.Resolved_Type));
                           Put_Line (" Resolved Tree:");
                           Dump_Resolved_Tree (Resolved_Interp, Indent => 2);
                        end if;
                        if Ambiguity /= null then
                           Sem_Error (Expr, "construct is ambiguous");
                           Diagnose_Ambiguity (Ambiguity);
                        end if;

                     else
                        if Debug_Second_Pass then
                           Put_Line ("  Not resolved");
                        end if;
                        Sem_Error (Expr, "not resolved");
                        Diagnose_Unresolved_Expr
                          (Expr, Resolved_Type, Expr_Opnd_Sem);
                     end if;
                  end;
               else
                  --  Resolves to self
                  if Not_Null (Expr_Opnd_Sem.Definition) then
                     --  NOTE: We use Definition instead of Expr
                     --       because we sometimes "skip" over a node
                     --       by setting its Sem_Info to be that of
                     --       its only child node (e.g. Annotations).
                     Expr_Opnd_Sem.Resolved_Interp :=
                       Expr_Opnd_Sem.Definition;
                  else
                     Expr_Opnd_Sem.Resolved_Interp := Expr;
                  end if;

                  if Expr_Opnd_Sem.all in Call_Semantic_Info
                    and then Call_Sem_Ptr (Expr_Opnd_Sem).Op_Sem = null
                    and then Call_Sem_Ptr (Expr_Opnd_Sem).
                       Original_Binary_Operator /=
                             Binary.Parallel_Stmt_Op
                  then
                     Sem_Error
                       (Expr,
                        "use of " &
                        Unresolved_Operation (Expr) &
                        " not resolved");
                     Diagnose_Unresolved_Expr
                       (Expr, Resolved_Type, Expr_Opnd_Sem);
                  elsif Resolved_Type /= null
                    and then Expr_Opnd_Sem.all not in Call_Semantic_Info
                  then
                     Sem_Error
                       (Expr,
                        "does not resolve to " & Type_Image (Resolved_Type));
                     Diagnose_Unresolved_Expr
                       (Expr, Resolved_Type, Expr_Opnd_Sem);
                  end if;
               end if;

            elsif Resolved_Type /= null then
               if Expr_Opnd_Sem.Resolved_Type /= null then
                  if not Types_Match
                           (Resolved_Type,
                            Expr_Opnd_Sem.Resolved_Type)
                  then
                     Sem_Error (Expr,
                       "has type " & Type_Image (Expr_Opnd_Sem.Resolved_Type)
                       & " which does not match " &
                       Type_Image (Resolved_Type));

                     if Debug_Second_Pass then
                        Put_Line
                          ("  Type of " &
                           Subtree_Image (Expr) &
                           " (" &
                           Type_Image (Expr_Opnd_Sem.Resolved_Type) &
                           ") does not match " &
                           Type_Image (Resolved_Type));
                     end if;
                  else
                     if Debug_Second_Pass then
                        Put_Line
                          ("  Type of " &
                           Subtree_Image (Expr) &
                           " (" &
                           Type_Image (Expr_Opnd_Sem.Resolved_Type) &
                           ") matches " &
                           Type_Image (Resolved_Type));
                     end if;
                  end if;
               else
                  if Debug_Second_Pass then
                     Put_Line
                       (Subtree_Image (Expr, Use_Short_Form => True) &
                        " doesn't have a resolved type, expecting " &
                        Type_Image (Resolved_Type));
                  end if;
               end if;
               --  TBD: Is this correct to overwrite the resolved type of
               --      the expression with that of the target type?
               --      It certainly makes sense if the expr is "null" or
               --      something else that is a kind of "wildcard" which
               --      matches multiple target types.
               Expr_Opnd_Sem.Resolved_Type := Resolved_Type;
            else
               Resolved_Type := Expr_Opnd_Sem.Resolved_Type;
               if Debug_Second_Pass then
                  Put_Line
                    ("  Type of " &
                     Subtree_Image (Expr, Use_Short_Form => True) &
                     " is " &
                     Type_Image (Expr_Opnd_Sem.Resolved_Type) &
                     " (no expected type)");
               end if;
            end if;
            if Not_Null (Expr_Opnd_Sem.Resolved_Interp)
              and then Expr_Opnd_Sem.Ambiguity = null
            then
               --  We have a good resolution.
               --  Make sure that all of the types referenced are "lifted" to
               --  current module making the reference.
               Update_Outermost_Module_Use_In_Tree
                 (Expr_Opnd_Sem.Resolved_Interp,
                  Find_Enclosing_Module_Interface
                    (Decl_Region => Visitor.Decl_Region));
            end if;
         end;
      else
         --  Doesn't have sem info with a type
         if Debug_Second_Pass then
            Put_Line
              (Subtree_Image (Expr, Use_Short_Form => True) &
               " doesn't have type info.");
         end if;
      end if;
   end Resolve_Expression;

   procedure Resolve_Case_Alt_Key
     (Visitor : in out Sem_Second_Pass_Visitor'Class;
      Case_Sem : Case_Construct_Sem_Ptr;
      Case_Alt_Key : Optional_Tree;
      Uses_Compare : in out Boolean;
      Is_Outermost : Boolean := False) is
      --  Resolve type of case alt key recursing on "|" and "..".
      Case_Alt_Key_Tree : Trees.Tree'Class
        renames Tree_Ptr_Of (Case_Alt_Key).all;
      Resolved_Type : Type_Sem_Ptr := Case_Sem.Case_Selector_Type;
   begin
      if Case_Sem.Case_Selector_Type /= null
        and then Case_Sem.Case_Selector_Type.Is_Polymorphic
        and then Case_Alt_Key_Tree not in Param_Decl.Tree
      then
         --  TBD:
         --  Case selector type is polymorphic but no "id" provided
         --  in choice expression.
         --  If choice can resolve to a type, treat it like a param_decl
         --  with the type name as the id.
         if Debug_Second_Pass then
            Put_Line
              ("Polymorphic case statement -- TBD handle unlabeled type: " &
                Subtree_Image (Case_Alt_Key));
         end if;
      end if;

      if Case_Alt_Key_Tree in Param_Decl.Tree then
         declare
            Choice_Param_Decl_Tree : Param_Decl.Tree renames Param_Decl.Tree (
              Case_Alt_Key_Tree);
            Choice_Param_Sem : constant Param_Sem_Ptr :=
              Param_Sem_Ptr (Sem_Info (Case_Alt_Key));

            use Param_Decl;
         begin
            --  May not combine a named choice with '|' or '..'
            --  NOTE: Parser should prevent this already
            if not Is_Outermost then
               Sem_Error (Case_Alt_Key_Tree,
                 "Named choice may not be combined with '|' or '..'");
            end if;

            --  Case selector should be of polymorphic type
            if Case_Sem.Case_Selector_Type = null
              or else not Case_Sem.Case_Selector_Type.Is_Polymorphic
            then
               Sem_Error
                 (Case_Alt_Key_Tree,
                 "Named choice only allowed when " &
                   "case selector is polymorphic");
            end if;

            if not Choice_Param_Sem.Resolved_Type.Is_Polymorphic then
               --  Non-polymorphic choice params are by-ref
               Choice_Param_Sem.Is_By_Ref_Choice_Param := True;
            end if;

            --  Choice parameters inherit variability from case selector
            Choice_Param_Sem.Is_Var_Choice_Param :=
              Sem_Info_Is_For_Variable
                (Underlying_Sem_Info
                   (Resolved_Tree (Case_Sem.Case_Selector)));

            return;   ----  All done  ---
         end;
      end if;
      if Case_Alt_Key_Tree in Binary.Tree then
         declare
            Key_Binary_Tree : Binary.Tree renames Binary.Tree (
              Case_Alt_Key_Tree);
            use Binary;
         begin
            case Key_Binary_Tree.Operator is
               when Combine_Op | Interval_Ops =>
                  --  Recurse on operands
                  if Not_Null (Key_Binary_Tree.Left_Operand) then
                     Uses_Compare := True;
                     Resolve_Case_Alt_Key
                       (Visitor,
                        Case_Sem,
                        Key_Binary_Tree.Left_Operand,
                        Uses_Compare);
                  end if;
                  if Not_Null (Key_Binary_Tree.Right_Operand) then
                     Uses_Compare := True;
                     Resolve_Case_Alt_Key
                       (Visitor,
                        Case_Sem,
                        Key_Binary_Tree.Right_Operand,
                        Uses_Compare);
                  end if;

                  --  No need to resolve the set/interval
                  --  since the "|" and ".." are syntax in this case,
                  --  not invocations of actual operators.
                  return;   -------  all done  --------

               when others =>
                  null;    --  Fall through
            end case;
         end;
      end if;

      --  Resolve expression to type of case selector
      --  TBD: Handle case of polymorphic case selector with
      --       choice being a type without an "id : " in front of it.
      Uses_Compare := True;
      Resolved_Type := Case_Sem.Case_Selector_Type;
      Resolve_Expression (Visitor, Case_Alt_Key, Resolved_Type);
   end Resolve_Case_Alt_Key;

   procedure Resolve_Operation_Name
     (Op_Name : Optional_Tree;
      Signature : Operation_Sem_Ptr;
      Chosen_Assoc_Type_Region : out Type_Region_Ptr;
      Signature_Type_Region : Type_Region_Ptr := null;
      Require_Exact_Type_Match : Boolean := False) is
      --  Resolve binding for operation name, given Operation_Sem for
      --  operation with desired signature.
      --  If Signature_Type_Region is non-null, then use that
      --  with Substitute_Actuals on Signature.
      --  If Require_Exact_Type_Match is True, then don't allow an
      --  extra substitution of the cur-inst types,
      --  since we don't want types to match
      --  just because both are current instances.
      Op_Name_Sem : constant Operand_Sem_Ptr :=
        Operand_Sem_Ptr (Sem_Info (Op_Name));
      Ambiguity : Ambiguity_List := null;
   begin
      Find_Interp_Of_Signature
        (Op_Name,
         Signature,
         Op_Name_Sem.Resolved_Interp,
         Chosen_Assoc_Type_Region,
         Ambiguity,
         Signature_Type_Region,
         Require_Exact_Type_Match => Require_Exact_Type_Match);

      if Is_Null (Op_Name_Sem.Resolved_Interp) then
         Sem_Error
           (Op_Name,
            "Operation name " & Subtree_Image (Op_Name) & " not resolved");
      elsif Ambiguity /= null then
         Sem_Error
           (Op_Name,
            "Operation name " & Subtree_Image (Op_Name) & " is ambiguous");
      end if;
   end Resolve_Operation_Name;

   procedure Visit_And_Resolve_Expr
     (OT : in out Optional_Tree;
      Visitor : in out Sem_Second_Pass_Visitor'Class;
      Resolved_Type : Type_Sem_Ptr := null;
      Call_Ref : Boolean := False) is
   --  Do second-pass Visit on tree and then resolve,
   --  to specified type if non-null.
   --  If Resolved_Type is null, and Call_Ref is True,
   --  then insert a call on "ref" if result is a Ref_Obj
      Resolved_Type_Copy : Type_Sem_Ptr := Resolved_Type;
   begin
      Visit (OT, Visitor);
      Resolve_Expression (Visitor, OT, Resolved_Type_Copy, Call_Ref);
   end Visit_And_Resolve_Expr;

   procedure Visit_And_Resolve_Stmt
     (OT : in out Optional_Tree;
      Visitor : in out Sem_Second_Pass_Visitor'Class) is
   --  Do second-pass Visit on tree and then resolve -- complain if result
   --  has a type.
      Resolved_Type : Type_Sem_Ptr := null;
   begin
      Visit (OT, Visitor);
      Resolve_Expression (Visitor, OT, Resolved_Type);
      if Resolved_Type /= null
        and then (Underlying_Sem_Info (OT).all not in Literal_Semantic_Info
          or else Literal_Sem_Ptr (Underlying_Sem_Info (OT)).Lit_Kind /=
            Null_Literal)
      then
         Sem_Warning ("Result not used: " &
           Subtree_Image (OT) & " -> " & Canonical_Type_Name (Resolved_Type),
           Find_Source_Pos (OT));
      end if;
   end Visit_And_Resolve_Stmt;

   function Sym_Might_Be_Operation (Sym : Sym_Ptr)
     return Boolean is
      --  Return True if Sym_Kind is one that might be used in a call.
   begin
      case Sym.Kind is
         when Module_Sym_Kind | Type_Sym_Kind | Operation_Sym_Kind =>
            return True;
         when Param_Sym_Kind =>
            --  Might be a parameter of a func type
            return Sym.Sem_Info /= null
              and then Sym.Sem_Info.all in Operand_Semantic_Info'Class
              and then Operand_Sem_Ptr (Sym.Sem_Info).Resolved_Type /= null
              and then Operand_Sem_Ptr
                (Sym.Sem_Info).Resolved_Type.Func_Type_Op_Sem /= null;
         when No_Sym_Kind
           | Module_Ancestor_Sym_Kind
           | Loop_Param_Sym_Kind
           | Loop_Key_Param_Sym_Kind
           | Object_Sym_Kind
           | Component_Sym_Kind
           | Literal_Sym_Kind
           | Statement_Sym_Kind =>
            return False;
      end case;
   end Sym_Might_Be_Operation;

   procedure Set_Identifier_Sem_Info
     (Decl_Region : Region_Ptr;
      Context : Context_Enum;
      T : in out Identifier.Tree;
      Prefix : Optional_Tree;
      Prefix_Type : Type_Sem_Ptr;
      Use_Selection_Syntax : Boolean := False;
      Ignore_Error : Boolean := False) is
      --  Fill in Sem_Info on Identifier node.
      --  Prefix and Prefix_Type are non-null if the
      --  identifier is part of a qualified name.
      --  If Use_Selection_Syntax is True, then set this flag on any
      --  created Qualified_Name nodes.
      --  If Ignore_Error is True, then don't complain if there are no
      --  interpretations of the identifier.
      pragma Assert (T.Sem_Info = null);
      Id : String renames Sym_Name (T);
      Lit_Kind : Literal_Kind_Enum := Not_A_Literal;
      use type Languages.Language_Enum;
   begin
      if Debug_Second_Pass then
         Put_Line (" Set_Identifier_Sem_Info for Identifier " & Id &
                   ", context = " & Context_Enum'Image (Context));
      end if;
      case Id (Id'First) is
         when '-' | '0' .. '9' => --  Integer or Real literal
            Lit_Kind := Integer_Literal;
            for I in Id'Range loop
               if Id (I) = '.' then
                  --  Needs a decimal point to be a real literal
                  Lit_Kind := Real_Literal;
                  exit;
               end if;
            end loop;
         when '#' => --  Enumeration literal
            Lit_Kind := Enum_Literal;
         when '"' => --  String literal
            if Context = Op_Context or else Context = Formal_Op_Context then
               --  Treat as an operator designator.
               Lit_Kind := Not_A_Literal;
            else
               Lit_Kind := String_Literal;
            end if;
         when ''' => --  Character literal
            Lit_Kind := Char_Literal;

         when others =>  --  "Normal" identifier or "null"
            if T.Str = Null_Str then
               Lit_Kind := Null_Literal;
            else
               Lit_Kind := Not_A_Literal;
            end if;
      end case;

      if Lit_Kind /= Not_A_Literal then
         --  Handle a literal
         Set_Literal_Sem_Info (T, Lit_Kind, Target_Type => Prefix_Type);
      else
         --  Handle a simple designator
         declare
            Id_Sym : Symbols.Sym_Ptr;
            Interp : Optional_Tree := Null_Optional_Tree;
            Underlying_Sem_Info : Sem_Ptr;
            Prefix_Type_Region : Type_Region_Ptr :=
              U_Base_Type_Region (Prefix_Type);
            Sym_Ref : Sym_Ref_Ptr;
            Interp_Added : Boolean;
            New_Type_Sem : Type_Sem_Ptr := Prefix_Type;
         begin
            if Prefix_Type /= null then
               --  We have a prefix, lookup in associated module's region(s)

               while New_Type_Sem /= null
                 and then New_Type_Sem.New_Type_Counter /=
                   Anonymous_Type_Indicator
               loop
                  --  First look up where "new" type is defined
                  --  TBD: We should also look in other regions when
                  --       looking for an operation.
                  Id_Sym :=
                     Symbols.Lookup_In_Region
                       (New_Type_Sem.U_Base_Type.
                          Associated_Symbol.Enclosing_Region,
                        T.Str,
                        Orig_Region => Decl_Region);

                  exit when Id_Sym /= null;

                  --  Continue on to parent type
                  New_Type_Sem := New_Type_Sem.Parent_Type;
               end loop;

               if Id_Sym /= null then
                  --  Already found a binding
                  null;
               elsif Prefix_Type.Associated_Module /= null then
                  --  Look in associated module's region
                  Id_Sym :=
                     Symbols.Lookup_In_Region
                       (Prefix_Type.Associated_Module.Nested_Region,
                        T.Str,
                        Orig_Region => Decl_Region);
                  New_Type_Sem := Prefix_Type;

                  while Id_Sym = null
                    and then New_Type_Sem /= null
                    and then New_Type_Sem.New_Type_Counter =
                      Anonymous_Type_Indicator
                    and then New_Type_Sem.Associated_Module.Treat_As_Type
                    and then New_Type_Sem.Enclosing_Type /= null
                    and then
                      New_Type_Sem.Enclosing_Type.Associated_Module /= null
                  loop
                     --  This type is a "local" type; look in enclosing
                     --  module as well.
                     --  TBD: Perhaps should only do this if local type is
                     --       the primary nested type.
                     Id_Sym :=
                        Symbols.Lookup_In_Region
                          (New_Type_Sem.Enclosing_Type.Associated_Module.
                             Nested_Region,
                           T.Str,
                           Orig_Region => Decl_Region);

                     if Id_Sym /= null
                       and then Id_Sym.Kind = Operation_Sym_Kind
                     then
                        --  Remember the encloser we are actually using
                        Prefix_Type_Region :=
                          U_Base_Type_Region (New_Type_Sem.Enclosing_Type);
                     end if;

                     --  Continue with parent type, if any
                     New_Type_Sem := New_Type_Sem.Parent_Type;
                  end loop;

               else
                  Sem_Error
                    (Prefix_Type.Definition,
                     "Internal: Associated_Module for type not filled in");
                  Id_Sym := null;
               end if;

               if Id_Sym = null then
                  if not Ignore_Error then
                     Sem_Error
                       (T,
                        Subtree_Image (T) &
                        " is not defined in " &
                        Type_Image (Prefix_Type));
                  end if;
               else
                  --  Found "Id" in region of Prefix
                  if Debug_Second_Pass then
                     Put_Line
                       (" Qualified_Name " &
                        Type_Image (Prefix_Type) &
                        "::" &
                        Subtree_Image (T) &
                        " resolved to sym of kind = " &
                        Symbols.Sym_Kind_Enum'Image (Id_Sym.Kind));
                  end if;
                  Underlying_Sem_Info := Sem_Ptr (Id_Sym.Sem_Info);

                  if not Region_Encloses_Region
                      (Encloser =>
                         Prefix_Type.Associated_Module.Nested_Region,
                       Enclosed => Decl_Region)
                    and then Underlying_Sem_Info.Context
                      not in Visible_Interface_Item_Contexts
                    and then Underlying_Sem_Info.Context
                      not in Exported_Class_Item_Contexts
                    and then Underlying_Sem_Info.Context
                      not in Module_Parameter_And_Ancestry_Contexts
                    and then Underlying_Sem_Info.Context /=
                      Standalone_Item_Context
                    and then Underlying_Sem_Info.Context /=
                      No_Context  --  Not yet initialized
                  then
                     --  Not a visible declaration
                     Sem_Error (T, Subtree_Image (T) &
                       " is not declared in visible part of " &
                       Subtree_Image (Prefix));
                  end if;

                  if Underlying_Sem_Info.all in Type_Semantic_Info
                    and then Prefix_Type_Region /= null
                  then
                     --  Substitute actuals now
                     Underlying_Sem_Info :=
                       Sem_Ptr (Substitute_Actuals
                                   (Type_Sem_Ptr (Underlying_Sem_Info),
                                    Prefix_Type_Region));
                  else
                     --  Just create a copy of the sem info
                     --  so can be updated.
                     Underlying_Sem_Info :=
                       new Semantic_Info'Class'(Underlying_Sem_Info.all);
                  end if;
               end if;
            else
               --  No prefix, lookup in current region chain
               case Context is
                  when Statement_Contexts           |
                       Exit_With_Values_Context     |
                       Selector_Prefix_Context      | --  obj of obj.selector
                       Agg_Contexts                 |
                       Ancestor_Item_Contexts       |
                       Standalone_Item_Context      |
                       Interface_Item_Contexts      |
                       Local_Class_Item_Context     |
                       Mutable_Context              |
                       Operation_Input_Context      |
                       Operation_Output_Context     |
                       Exported_Class_Item_Contexts |
                       Case_Choice_Context          =>

                     Id_Sym :=
                        Symbols.Lookup_In_Region_Chain (Decl_Region, T.Str);

                     while Id_Sym /= null
                       and then Id_Sym.Sem_Info /= null
                       and then (Sem_Ptr (Id_Sym.Sem_Info).Context = No_Context
                         or else (Id_Sym.Kind = Param_Sym_Kind
                           and then Id_Sym.Sem_Info.all in
                             Object_Semantic_Info'Class
                           and then
                             Object_Sem_Ptr (Id_Sym.Sem_Info).Resolved_Type =
                               null))
                     loop
                        --  We have a decl that hasn't been processed yet
                        --  or we have a Param_Sym_Kind that hasn't had its
                        --  type filled in yet.
                        --  This can happen if a parameter that will be
                        --  processed later has the same name as a type.
                        Id_Sym := Next_Homonym_In_Region_Chain
                          (Id_Sym, Orig_Region => Decl_Region);
                     end loop;

                     if Id_Sym = null then
                        Sem_Error (T, Sym_Name (T) & " is not visible");
                     end if;

                  when Module_Context =>          --  module of instantiation
                     Id_Sym :=
                        Symbols.Lookup_In_Region_Chain (Decl_Region, T.Str);
                     while Id_Sym /= null
                       and then Id_Sym.Kind /= Module_Sym_Kind
                     loop
                        Id_Sym := Next_Homonym_In_Region_Chain
                          (Id_Sym, Orig_Region => Decl_Region);
                     end loop;
                     if Id_Sym = null then
                        Sem_Error
                          (T,
                           "Module " & Sym_Name (T) & " is not visible");
                     end if;

                  when Type_Context                         |  --  type for
                                                               --  object decl,
                                                               --  etc.
                       Module_Actual_Type_Context           |
                       --  actual type param for instantiation
                       Module_Implements_Interfaces_Context |
                       --  list of implemented interfaces
                       Module_Actual_Of_Formal_Context      |
                       Module_Extends_Interface_Context     |  --  parent type
                       Module_Formal_Type_Def_Context       =>    --  formal
                                                                  --  type of
                                                                  --  module

                     Id_Sym :=
                        Symbols.Lookup_In_Region_Chain (Decl_Region, T.Str);
                     while Id_Sym /= null loop
                        case Id_Sym.Kind is
                           when Module_Sym_Kind =>
                              --  Get_Type will convert to a type if possible
                              exit;
                           when Type_Sym_Kind =>
                              --  Found what we wanted
                              exit;
                           when others =>
                              --  Keep looking
                              null;
                        end case;
                        Id_Sym := Next_Homonym_In_Region_Chain
                          (Id_Sym, Orig_Region => Decl_Region);
                     end loop;
                     if Id_Sym = null then
                        Sem_Error
                          (T,
                           "Type " & Sym_Name (T) & " is not visible");
                     end if;

                  when Operand_Contexts      |        --  operand of call
                       Module_Formal_Context |        --  formal param of
                                                      --  module
                       Op_Context            |
                       Formal_Op_Context     =>  --  operation of call
                     --  These allow operations, so we postpone any error
                     --  message

                     Id_Sym :=
                        Symbols.Lookup_In_Region_Chain (Decl_Region, T.Str);

                     if Id_Sym /= null
                       and then Context in Operation_Name_Contexts
                       and then Id_Sym.Sem_Info /= null
                       and then
                          ((Id_Sym.Kind = Param_Sym_Kind
                            and then not Sym_Might_Be_Operation (Id_Sym))
                         or else
                           Sem_Ptr (Id_Sym.Sem_Info).Context = No_Context)
                     then
                        --  We are looking for an operation name
                        --  (or possibly a type name for a type conversion),
                        --  and we found a parameter (or an undefined symbol).
                        --  Try to skip over the uninteresting symbols
                        --  until we find something else.
                        declare
                           Next_Sym : Sym_Ptr := Next_Homonym_In_Region_Chain
                             (Id_Sym, Orig_Region => Decl_Region);
                        begin
                           while Next_Sym /= null
                             and then Next_Sym.Sem_Info /= null
                             and then (Sem_Ptr (Next_Sym.Sem_Info).Context =
                                          No_Context
                               or else
                                 (Next_Sym.Kind = Param_Sym_Kind
                                  and then
                                    not Sym_Might_Be_Operation (Next_Sym)))
                           loop
                              Next_Sym := Next_Homonym_In_Region_Chain
                                (Next_Sym, Orig_Region => Decl_Region);
                           end loop;
                           if Next_Sym /= null
                             and then Sym_Might_Be_Operation (Next_Sym)
                           then
                              --  OK, use this instead
                              Id_Sym := Next_Sym;
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" Skipping over params to find " &
                                    "operation (or type) of name " &
                                    Sym_Name (Id_Sym));
                              end if;
                           end if;
                        end;
                     end if;
               end case;

               if Id_Sym /= null then
                  --  Initial interpretation
                  if Context = Op_Context and then
                    (Id (Id'First) = '"'
                     or else not Sym_Might_Be_Operation (Id_Sym))
                  then
                     --  We don't include operators that are directly visible
                     --  because they can create ambiguity or infinite
                     --  recursion.
                     --  See for example "from_univ" implementation
                     --  for Enum<>.
                     --  So operators are only visible via the types of the
                     --  operands or the result, or if part of a qualified or
                     --  selected name.

                     --  NOTE: We also ignore directly visible names that can't
                     --        possibly be used in a call.
                     Id_Sym := null;
                  else
                     if Debug_Second_Pass then
                        Put_Line
                          (" found: " &
                           Sym_Name (Id_Sym) &
                           ", kind = " &
                           Sym_Kind_Enum'Image (Id_Sym.Kind));
                     end if;
                     Underlying_Sem_Info := Sem_Ptr (Id_Sym.Sem_Info);
                  end if;
               end if;
            end if;

            Sym_Ref :=
              new Sym_Reference_Info'
              (Root_Semantic_Info with
               Associated_Symbol => Id_Sym,
               Nested_Region => null,
               Context => Context,
               Interps => null,
               Resolved_Type => null,
               Resolved_Interp => Null_Optional_Tree,
               Hash_Value => 0,
               Target_Polymorphic_Type => null,
               Reported_As_Undefined => False,
               Prefix_Type_Region => Prefix_Type_Region,
               Underlying_Sem_Info => Underlying_Sem_Info);

            T.Sem_Info := Root_Sem_Ptr (Sym_Ref);

            Interp := Optional (T'Access);
            if Not_Null (Prefix) then
               Interp := Qualified_Name.Make (Prefix, Interp,
                 Use_Selection_Syntax);
               Set_Sem_Info (Interp, T.Sem_Info);
            end if;

            T.Sem_Info.Definition := Interp;

            if Id_Sym /= null
              and then (Id_Sym.Kind = Type_Sym_Kind
                        or else Id_Sym.Kind = Module_Sym_Kind)
              and then Context in Operand_Contexts
            then
               --  See whether Type::[..] is defined,
               --  and use that interpretation.
               declare
                  Type_For_Univ_Container : constant Type_Sem_Ptr :=
                    Get_Type (Decl_Region, Interp);

                  Op_Tree : constant Optional_Tree :=
                    Identifier.Make
                       (Univ_Container_Op_Str,
                        Identifier.Find_Source_Pos (T));

                  Equiv_Invocation : Optional_Tree :=
                    Invocation.Make
                       (Kind => Invocation.Operation_Call,
                        Prefix => Op_Tree,
                        Operands => Lists.Empty_List);
               begin
                  --  Recurse to set the interp for the [..] operator
                  Set_Identifier_Sem_Info
                    (Decl_Region,
                     Context => Op_Context,
                     T => Identifier.Tree (Tree_Ptr_Of (Op_Tree).all),
                     Prefix => Optional (T'Access),
                     Prefix_Type => Type_For_Univ_Container,
                     Ignore_Error => True);

                  --  Pass the buck to a visit of equiv invocation
                  Second_Pass
                    (Decl_Region,
                     Equiv_Invocation,
                     Context => Context);
                  T.Sem_Info := Sem_Info (Equiv_Invocation);

                  if Interpretations.Has_Interp
                    (Call_Sem_Ptr (T.Sem_Info).Interps)
                  then
                     --  Found some interpretation for the operator
                     return;  --  All done
                  end if;
               end;
            end if;

            if Id_Sym = null then
               --  No "initial" interpretation
               if Debug_Second_Pass then
                  Put_Line
                    (" no sym found for: " &
                     Sym_Name (T) &
                     " in context " &
                     Context_Enum'Image (Context));
               end if;
               if Context in Operand_Contexts and then Prefix_Type = null
                 and then not Ignore_Error
               then
                  --  TBD: We don't allow operation parameters at the
                  --      moment, so we can safely complain now.
                  --      Eventually, we will have to postpone these
                  --      complaints until we know there are no possible
                  --      interpretations as an operation.
                  Sem_Error (T, Sym_Name (T) & " is not visible");
               end if;
               return;
            end if;

            if Id_Sym.Kind /= Operation_Sym_Kind then
               --  Add in initial non-operation interpretation
               Interpretations.Add_Interp
                 (Operand_Sem_Ptr (T.Sem_Info).Interps,
                  Associated_Type_Region => Prefix_Type_Region,
                  Interp => Interp,
                  Interp_Added => Interp_Added);
            end if;

            case Id_Sym.Kind is
               when Operation_Sym_Kind =>
                  --  Add in all visible Operation_Sym_Kind interpretations;
                  --  if declared in interface of a module, then set associated
                  --  type region to current instance of module.
                  while Id_Sym /= null
                    and then Id_Sym.Kind = Operation_Sym_Kind
                    and then Id_Sym.Sem_Info /= null
                    and then Id_Sym.Sem_Info.all in Operation_Semantic_Info
                  loop
                     --  Create new interpretation to represent possible
                     --  overloaded operation interpretation,
                     --  but ignore non-imported operation declarations,
                     --  unless they are declared in interface of module.
                     declare
                        Op_Tree : Operation.Tree
                          renames Operation.Tree (Tree_Ptr_Of
                            (Id_Sym.Definition).all);
                        Op_Sem : constant Operation_Sem_Ptr :=
                          Operation_Sem_Ptr (Op_Tree.Sem_Info);
                        Is_In_Module : constant Boolean :=
                          Id_Sym.Enclosing_Region.Associated_Symbol /= null
                         and then
                           Id_Sym.Enclosing_Region.Associated_Symbol.Kind =
                             Module_Sym_Kind;
                        Is_Formal_Operation_Of_Operation : constant Boolean :=
                          Op_Sem.Context = Operation_Input_Context;
                        Is_Formal_Operation_Of_Module : constant Boolean :=
                          Op_Sem.Context = Module_Formal_Context;
                        pragma Assert
                          (Prefix_Type = null or else Is_In_Module);
                     --  Prefix_Type /= null ==> Is_In_Module
                     begin
                        if Op_Sem.Overridden_By /= null
                          or else Op_Sem.Context = No_Context
                        then
                           --  Ignore this one
                           null;
                        elsif (Prefix_Type = null
                              and then (not Is_In_Module
                                       or else Op_Sem.Context =
                                               Local_Class_Item_Context)
                              and then (Op_Tree.Is_Def
                                       or else Op_Tree.Is_Import))
                          or else (Is_In_Module
                                  and then Op_Sem.Context in
                             Visible_Interface_Item_Contexts)
                          or else Op_Sem.Body_Region = null
                              --  This is a spec with body not yet analyzed
                          or else Is_Formal_Operation_Of_Operation
                          or else Is_Formal_Operation_Of_Module
                        then
                           --  We have an interface item of a module, or
                           --  a definition/import that is *not* exported
                           --  by a module, or a formal operation of
                           --  an operation/module.
                           --  NOTE: We don't want bodies of interface items,
                           --        since that will create ambiguity.
                           declare
                              Id_Interp : Optional_Tree :=
                                Identifier.Make
                                   (Id_Sym.Str,
                                    Identifier.Find_Source_Pos (T));
                              New_Sem_Info : constant Root_Sem_Ptr :=
                                new Sym_Reference_Info'
                                (Root_Semantic_Info with
                                 Associated_Symbol => Id_Sym,
                                 Nested_Region => null,
                                 Context => Context,
                                 Interps => null,
                                 Resolved_Type => null,
                                 Resolved_Interp => Null_Optional_Tree,
                                 Hash_Value => 0,
                                 Target_Polymorphic_Type => null,
                                 Reported_As_Undefined => False,
                                 Prefix_Type_Region => Prefix_Type_Region,
                                 Underlying_Sem_Info =>
                                   Sem_Ptr (Id_Sym.Sem_Info));
                           begin
                              Set_Sem_Info (Id_Interp, New_Sem_Info);

                              if Is_In_Module
                                and then Prefix_Type = null
                              then
                                 --  We must have an operation of a module.
                                 --  Set Prefix_Type_Region to module's
                                 --  cur-inst-sem
                                 Prefix_Type_Region :=
                                   Type_Region_Ptr
                                     (Module_Sem_Ptr
                                       (Id_Sym.Enclosing_Region.
                                          Associated_Symbol.Sem_Info).
                                            Cur_Inst_Sem);
                              end if;

                              if Not_Null (Prefix) then
                                 --  Include prefix in interp
                                 Id_Interp :=
                                    Qualified_Name.Make (Prefix, Id_Interp,
                                      Use_Selection_Syntax);
                                 Set_Sem_Info (Id_Interp, New_Sem_Info);
                              end if;
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" adding op interp: " &
                                    Subtree_Image (Id_Interp) &
                                    ", denoting " &
                                    Subtree_Image (Op_Sem.Definition) &
                                    ", context = " &
                                    Context_Enum'Image (Op_Sem.Context) &
                                    ", assoc_type_region = " &
                                    Type_Image
                                       (Type_Sem_Ptr (Prefix_Type_Region)));
                              end if;
                              Interpretations.Add_Interp
                                (Operand_Sem_Ptr (T.Sem_Info).Interps,
                                 Associated_Type_Region => Prefix_Type_Region,
                                 Interp => Id_Interp,
                                 Interp_Added => Interp_Added);

                           end;
                        end if;
                        --  Get next directly visible definition
                        if Prefix_Type /= null then
                           Id_Sym := Next_Homonym_In_Region (Id_Sym,
                             Orig_Region => Decl_Region);
                        else
                           Id_Sym := Next_Homonym_In_Region_Chain
                             (Id_Sym, Orig_Region => Decl_Region);
                        end if;
                     end;
                  end loop;

               when Param_Sym_Kind           |
                    Loop_Param_Sym_Kind      |
                    Loop_Key_Param_Sym_Kind  |
                    Object_Sym_Kind          |
                    Component_Sym_Kind       |
                    Module_Ancestor_Sym_Kind =>
                  --  An object-ish thing, get its declared type
                  declare
                     Declared_Type : constant Type_Sem_Ptr :=
                       Object_Sem_Ptr (Id_Sym.Sem_Info).Resolved_Type;
                  begin
                     --  Substitute from prefix
                     Sym_Ref.Resolved_Type :=
                        Substitute_Actuals (Declared_Type, Prefix_Type_Region);

                     --  Copy resolved type into Underlying_Sem_Info
                     Object_Sem_Ptr (Underlying_Sem_Info).Resolved_Type :=
                       Sym_Ref.Resolved_Type;

                     if Debug_Second_Pass then
                        Put_Line
                          (" Type of " &
                           Subtree_Image (T) &
                           " is " &
                           Type_Image (Sym_Ref.Resolved_Type));
                     end if;
                     if Sym_Ref.Resolved_Type = null then
                        Sem_Error (T, "Type of object not defined");
                     end if;
                  end;

               when Module_Sym_Kind =>
                  --  Module might be used as a default object name,
                  --  so fill in Resolved_Type field from "current" instance
                  if Context /= Module_Context then
                     Sym_Ref.Resolved_Type :=
                       Module_Sem_Ptr (Id_Sym.Sem_Info).Cur_Inst_Sem;
                     if Prefix_Type /= null
                       and then Prefix_Type.U_Base_Type /= null
                       and then Prefix_Type.U_Base_Type /=
                         Prefix_Type.Associated_Module.Cur_Inst_Sem
                     then
                        --  Substitute in prefix unless is a cur-inst prefix
                        Sym_Ref.Resolved_Type := Substitute_Actuals
                          (Sym_Ref.Resolved_Type, Prefix_Type_Region);
                     else
                        --  Update outermost-module indicator
                        --  TBD: Should we do this for prefixed names too?
                        Update_Outermost_Module_Where_Used
                          (Sym_Ref.Resolved_Type,
                           Find_Enclosing_Module_Interface (Decl_Region));
                     end if;
                  end if;

                  if Context = Selector_Prefix_Context
                    and then not Languages.Language_Uses_Selection_For_Modules
                  then
                     Sem_Error (T,
                       Languages.Language_Name &
                       " uses ""::"" instead of ""."" when " &
                       "selecting from modules or types");
                  end if;

               when Type_Sym_Kind =>
                  --  Type might be used as a default object name,
                  --  so fill in Resolved_Type field
                  Sym_Ref.Resolved_Type := Type_Sem_Ptr (Underlying_Sem_Info);

                  if Context = Selector_Prefix_Context
                    and then not Languages.Language_Uses_Selection_For_Modules
                  then
                     Sem_Error (T,
                       Languages.Language_Name &
                       " uses ""::"" instead of ""."" when " &
                       "selecting from modules or types");
                  end if;

               when Literal_Sym_Kind =>
                  --  TBD: Shouldn't happen (literals handled above)
                  null;

               when No_Sym_Kind | Statement_Sym_Kind =>
                  --  Doesn't have a type
                  null;
            end case;

         end;
      end if;  --  Whether is literal
   end Set_Identifier_Sem_Info;

   function Is_Compile_Time_Known (Operand : Optional_Tree;
     Disallow_Concurrent_Types : Boolean := False;
     Diagnose : Boolean := False) return Boolean is
      --  Return True if given operand is compile-time known.
      --  If Disallow_Concurrent_Types is true, then disallow having
      --  any parameters of a concurrent type.
      --  If Diagnose is True, then indicate what causes Is_Compile_Time_Known
      --  to return False.
      --  TBD: This is relatively simple for now.
      --      Could get more sophisticated eventually.
      Operand_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                 (Resolved_Tree (Operand)).all;
      Sem : constant Sem_Ptr :=
        Underlying_Sem_Info (Sem_Ptr (Operand_Tree.Sem_Info));

      procedure Give_Reason (Reason : String) is
      --  Explain why not compile-time known
      begin
         Messages.Put_Message
           (Subtree_Image
              (Operand_Tree, Use_Short_Form => not Debug_Code_Gen) &
            " is not compile-time known because " & Reason,
            Src_Pos => Find_Source_Pos (Operand),
            Message_Kind => "Info");
      end Give_Reason;

      function Type_Is_Ok (Assoc_Type : Type_Sem_Ptr;
                           Prefix : String := "") return Boolean is
         --  Return True if Assoc_Type has all parameters known, and
         --  is not concurrent if concurrent types disallowed.
      begin
         if Assoc_Type = null then
            if Diagnose then
               if Prefix /= "" then
                  Give_Reason (Prefix & "is null");
               else
                  Give_Reason ("type is null");
               end if;
            end if;
            return False;
         end if;

         if Diagnose and then not Assoc_Type.All_Parameters_Known then
            Give_Reason (Prefix & Canonical_Type_Name (Assoc_Type) &
              "not All_Parameters_Known");
         end if;

         if Diagnose and then Disallow_Concurrent_Types
           and then Type_Is_Concurrent (Assoc_Type)
         then
            Give_Reason (Prefix & Canonical_Type_Name (Assoc_Type) &
              "is concurrent");
         end if;

         return Assoc_Type.All_Parameters_Known
           and then
            (not Disallow_Concurrent_Types
               or else
             not Type_Is_Concurrent (Assoc_Type));
      end Type_Is_Ok;

   begin  --  Is_Compile_Time_Known

      if Operand_Tree in Reference.Tree'Class then
         --  TBD: Ignore the key for this check
         return Is_Compile_Time_Known
                  (Reference.Tree (Operand_Tree).Referent,
                   Disallow_Concurrent_Types, Diagnose => Diagnose);
      elsif Sem = null then
         if Diagnose then
            Give_Reason ("Semantic info is null");
         end if;
         return False;
      elsif Sem.all in Type_Semantic_Info'Class then
         return Type_Is_Ok (Type_Sem_Ptr (Sem));
      elsif Sem.all in Literal_Semantic_Info'Class then
         if Literal_Sem_Ptr (Sem).Lit_Kind /= Null_Literal then
            --  Non-null literals are always compile-time known
            return True;
         end if;

         --  Null literals are compile-time known if type is known.
         declare
            Lit_Sem : constant Literal_Sem_Ptr := Literal_Sem_Ptr (Sem);
         begin
            return Type_Is_Ok (Lit_Sem.Resolved_Type);
         end;
      elsif Sem.all in Object_Semantic_Info
        and then Operand_Tree in Obj_Decl.Tree
      then
         declare
            Obj_Tree : Obj_Decl.Tree renames Obj_Decl.Tree (Operand_Tree);
            Obj_Sem : constant Object_Sem_Ptr := Object_Sem_Ptr (Sem);
         begin
            --  See whether is a compile-time-known constant
            if Diagnose then
               --  Explain why not compile-time known
               if not Type_Is_Ok (Obj_Sem.Resolved_Type) then
                  return False;
               elsif Is_Null (Obj_Tree.Obj_Value) then
                  Give_Reason ("Initial value tree is null");
               elsif not Obj_Tree.Is_Const then
                  Give_Reason ("Obj is not a const");
               elsif Obj_Tree.Is_Ref then
                  Give_Reason ("Obj is a ref");
               else
                  return Is_Compile_Time_Known (Obj_Tree.Obj_Value,
                           Disallow_Concurrent_Types, Diagnose => True);
               end if;
               --  Not compile-time known for some reason, given above
               return False;
            else
               return Type_Is_Ok (Obj_Sem.Resolved_Type)
                  and then Not_Null (Obj_Tree.Obj_Value)
                  and then Obj_Tree.Is_Const
                  and then not Obj_Tree.Is_Ref
                  and then Is_Compile_Time_Known (Obj_Tree.Obj_Value,
                                                  Disallow_Concurrent_Types);
            end if;
         end;
      elsif Operand_Tree in Invocation.Tree'Class then
         --  Handle invocation where operands are all compile-time
         --  known and operation is relative to a compile-time known type,
         --  or is itself compile-time known.
         declare
            Invoc : Invocation.Tree renames Invocation.Tree (Operand_Tree);
            use Invocation;
         begin
            if Invoc.Kind = Is_Function_Of then
               return True;
            end if;

            --  Check the result type
            if Sem.all in Operand_Semantic_Info'Class
              and then not Type_Is_Ok (Operand_Sem_Ptr (Sem).Resolved_Type)
            then
               return False;
            end if;

            --  Check the operands
            for I in 1 .. Lists.Length (Invoc.Operands) loop
               if not Is_Compile_Time_Known
                        (Lists.Nth_Element (Invoc.Operands, I),
                         Disallow_Concurrent_Types, Diagnose => Diagnose)
               then
                  return False;
               end if;
            end loop;

            --  Check the rest
            case Invoc.Kind is
               when Operation_Call =>
                  declare
                     Call_Sem : constant Call_Sem_Ptr := Call_Sem_Ptr (Sem);
                  begin
                     --  TBD: Need to verify not a call on a formal operation
                     if Disallow_Concurrent_Types
                       and then Call_Sem.Op_Sem /= null
                       and then Follow_Op_Equiv (Call_Sem.Op_Sem).Is_Import
                       and then Lists.Length (Invoc.Operands) = 0
                     then
                        --  Don't treat parameterless calls on imported funcs
                        --  as compile-time known if we are disallowing
                        --  concurrent types.  This prevents calls on things
                        --  like "Readln()" from being pre-computed.

                        if Diagnose then
                           Give_Reason ("parameterless call on import");
                        end if;
                        return False;
                     end if;

                     --  Check that associated type is fully known
                     return Type_Is_Ok
                       (Type_Sem_Ptr (Call_Sem.Assoc_Type_Region),
                        Prefix => "associated type of call ");
                  end;

               when Container_Indexing =>
                  --  NOTE: these should never appear as they are replaced
                  --        by calls on "indexing" or equivalent.
                  if Diagnose then
                     Give_Reason ("Container_Indexing never c-t-known");
                  end if;
                  return False;

               when Class_Aggregate =>
                  declare
                     Agg_Sem : constant Class_Agg_Sem_Ptr :=
                       Class_Agg_Sem_Ptr (Sem);
                  begin
                     --  TBD: Anything else to check?
                     return True;
                  end;

               when Container_Aggregate | Map_Set_Aggregate =>
                  --  Need these for declaring enum types
                  declare
                     Agg_Sem : constant Container_Agg_Sem_Ptr :=
                       Container_Agg_Sem_Ptr (Sem);
                  begin
                     --  TBD: Need to check "key" of Key => Value.
                     return True;
                  end;

               when Module_Instantiation =>
                  --  Already handled types above
                  if Diagnose then
                     Give_Reason ("Module_Instantiation is not a type");
                  end if;
                  return False;

               when Is_Function_Of =>
                  --  Already handled above
                  return True;

               when Tuple_Type_Definition =>
                  --  Nothing more than operands
                  return True;
            end case;
         end;
      elsif Sem.all in Operation_Semantic_Info then
         --  A value of "func" type.
         --  Must be stand-alone function or component of module.
         if Operation_Sem_Ptr (Sem).Level = 0 then
            return True;
         elsif Diagnose then
            Give_Reason ("Operation is nested");
         end if;
         return False;
      elsif Sem.all in Resolved_Operation_Info then
         --  Check that lambda expression is nesed directly inside a module.
         if Resolved_Op_Ptr (Sem).Level = 0 then
            return True;
         elsif Diagnose then
            Give_Reason ("Operation is nested");
         end if;
         return False;
      elsif Sem /= Sem_Ptr (Operand_Tree.Sem_Info) then
         --  Retry on the underlying definition
         return Is_Compile_Time_Known
                  (Sem.Definition,
                   Disallow_Concurrent_Types, Diagnose => Diagnose);
      else
         --  NOTE: Already handled literals above
         if Diagnose then
            Give_Reason ("Type of entity is never compile-time known");
         end if;
         return False; --  TBD  other cases?
      end if;
   end Is_Compile_Time_Known;

   procedure Diagnose_Unknown_Parameters
     (Type_Sem : Type_Sem_Ptr;
      Disallow_Concurrent_Types : Boolean := False;
      Indent : Natural := 0) is
      --  Provide more information on why Type_Sem.All_Parameters_Known
      --  is False.
      Indent_Str : constant String (1 .. Indent) := (others => ' ');
   begin
      if Debug_Code_Gen then
         Put_Line
           (Indent_Str &
            Type_Image (Type_Sem) &
            ": All_Parameters_Known = " &
            Boolean'Image (Type_Sem.All_Parameters_Known));
      end if;

      if Type_Sem.All_Parameters_Known then
         return;
      end if;

      if Type_Sem.Actual_Sem_Infos = null then
         if Debug_Code_Gen then
            Put_Line (Indent_Str & " Actual_Sem_Infos is null");
         end if;
      else
         if Debug_Code_Gen then
            Put_Line (Indent_Str & " Actual_Sem_Infos:");
         end if;
         for I in Type_Sem.Actual_Sem_Infos'Range loop
            declare
               Actual : constant Sem_Ptr := Type_Sem.Actual_Sem_Infos (I);
            begin
               if Actual = null then
                  if Debug_Code_Gen then
                     Put_Line (Indent_Str & "  null");
                  end if;
               elsif Actual.all in Type_Semantic_Info then
                  Diagnose_Unknown_Parameters
                    (Type_Sem_Ptr (Actual),
                     Indent => Indent + 2);
               else
                  declare
                     Actual_Is_CTK : constant Boolean :=
                       Is_Compile_Time_Known (Actual.Definition,
                         Disallow_Concurrent_Types);
                     Underlying_Sem : constant Sem_Ptr :=
                       Underlying_Sem_Info (Actual);
                  begin
                     if Debug_Code_Gen then
                        Put_Line
                          (Indent_Str &
                           "  " & Subtree_Image (Actual.Definition));
                     end if;
                     if Underlying_Sem /= null then
                        if Debug_Code_Gen then
                           if Underlying_Sem /= Actual then
                              Put_Line (Indent_Str & " Underlying is " &
                                Subtree_Image (Underlying_Sem.Definition));
                           end if;
                           Put_Line
                             (Indent_Str &
                              "   Is_Known: " &
                              Boolean'Image (Actual_Is_CTK));
                        end if;
                        if not Actual_Is_CTK and then
                          Is_Compile_Time_Known (Underlying_Sem.Definition,
                            Disallow_Concurrent_Types,
                            Diagnose => True)
                        then
                           if Debug_Code_Gen then
                              Put_Line (Indent_Str &
                                "    But the underlying sem is known??");
                              Put_Line (Indent_Str & "   Orig sem CTK = " &
                                Boolean'Image (Is_Compile_Time_Known
                                  (Actual.Definition,
                                   Disallow_Concurrent_Types,
                                   Diagnose => True)));
                           end if;
                        end if;
                     end if;
                  end;

               end if;
            end;
         end loop;
      end if;

      if Type_Sem.Enclosing_Type /= null then
         if Debug_Code_Gen then
            Put_Line (Indent_Str & " Enclosing:");
         end if;
         Diagnose_Unknown_Parameters
           (Type_Sem.Enclosing_Type,
            Indent => Indent + 2);
      end if;

      if Type_Sem.Parent_Type /= null then
         if Debug_Code_Gen then
            Put_Line (Indent_Str & " Parent:");
         end if;
         Diagnose_Unknown_Parameters
           (Type_Sem.Parent_Type,
            Indent => Indent + 2);
      end if;

   end Diagnose_Unknown_Parameters;

   function Param_Types_Are_All_Known
     (Param_List : Lists.List) return Boolean is
   --  Return True if all parameters on list have types with
   --  All_Parameters_Known = True
   begin
      for I in 1 .. Lists.Length (Param_List) loop
         declare
            Param_Sem : constant Root_Sem_Ptr :=
              Sem_Info (Lists.Nth_Element (Param_List, I));
         begin
            if Param_Sem = null
              or else Param_Sem.all not in Object_Semantic_Info'Class
              or else Object_Sem_Ptr (Param_Sem).Resolved_Type = null
            then
               return False;
            elsif not Object_Sem_Ptr
                 (Param_Sem).Resolved_Type.All_Parameters_Known
            then
               return False;
            end if;
         end;
      end loop;
      --  All param types are fully defined
      return True;
   end Param_Types_Are_All_Known;

   function Is_Limited_Type_Module (Mod_Sem : Module_Sem_Ptr) return Boolean is
   --  Return True if module of Mod_Sem has Is_Limited set
   begin
      return Mod_Sem /= null and then Not_Null (Mod_Sem.Definition)
        and then Module.Tree (Tree_Ptr_Of (Mod_Sem.Definition).all).Is_Limited;
   end Is_Limited_Type_Module;

   procedure Finish_Type_Sem_Info
     (Type_Sem : Type_Sem_Ptr;
      Decl_Region : Region_Ptr := null) is
      --  Fill in U_Base_Type and U_Type, and then add type to
      --  Nested_Type list, or Actual_Of_Formals list, as appropriate
      Module_Sem : constant Module_Sem_Ptr := Type_Sem.Associated_Module;
      Orig_Enclosing_Type : constant Type_Sem_Ptr := Type_Sem.Enclosing_Type;
      use type Type_Sem_Vectors.Elem_Index;

   begin  --  Finish_Type_Sem_Info

      if Type_Sem.Enclosing_Type /= null
        and then Module_Sem.Cur_Inst_Sem /= null
        and then Module_Sem.Cur_Inst_Sem.Enclosing_Type /= null
        and then Module_Sem.
                    Cur_Inst_Sem.Enclosing_Type.Associated_Module /=
          Type_Sem.Enclosing_Type.Associated_Module
      then
         --  Change enclosing type so it comes from enclosing module
         Type_Sem.Enclosing_Type := Substitute_Actuals
           (Type_Sem.Associated_Module.Cur_Inst_Sem.Enclosing_Type,
            U_Base_Type_Region (Type_Sem.Enclosing_Type));
         if Debug_Second_Pass then
            Put_Line (" Finish_Type_Sem_Info: fixed enclosing type; was: "
              & Type_Image (Orig_Enclosing_Type) & "; now: " &
              Type_Image (Type_Sem.Enclosing_Type));
         end if;
      end if;

      --  Fill in U_Base_Type and U_Type
      Type_Sem.U_Base_Type := Find_U_Base_Type (Type_Sem);
      Type_Sem.U_Type := Find_U_Type (Type_Sem);

      if Type_Sem /= Type_Sem.U_Base_Type
        and then Type_Sem.U_Base_Type /= null
      then
         --  Copy structural info from base type
         Type_Sem.U_Base_Structure := Type_Sem.U_Base_Type.U_Base_Structure;

         --  Copy various other info from base type
         Type_Sem.All_Parameters_Known :=
           Type_Sem.U_Base_Type.All_Parameters_Known;
         Type_Sem.Known_To_Be_Assignable :=
           Type_Sem.U_Base_Type.Known_To_Be_Assignable;
         Type_Sem.Known_To_Be_Small :=
           Type_Sem.U_Base_Type.Known_To_Be_Small;
         Type_Sem.Actual_Sem_Infos :=
           Type_Sem.U_Base_Type.Actual_Sem_Infos;

         Type_Sem.Full_View := Type_Sem.U_Base_Type.Full_View;
         Type_Sem.External_View := Type_Sem.U_Base_Type.External_View;

         Update_Outermost_Module_Where_Used
           (Type_Sem.U_Base_Type,
            Type_Sem.Outermost_Module_Where_Used);

         --  Copy the (possibly updated) information relating to
         --  where type is created and its indices into tables.
         Type_Sem.Outermost_Module_Where_Used :=
           Type_Sem.U_Base_Type.Outermost_Module_Where_Used;
         Type_Sem.Nested_Type_Index :=
           Type_Sem.U_Base_Type.Nested_Type_Index;
         Type_Sem.Actual_Of_Formal_Index :=
           Type_Sem.U_Base_Type.Actual_Of_Formal_Index;
         Type_Sem.Type_Descriptor_Location :=
           Type_Sem.U_Base_Type.Type_Descriptor_Location;
         Type_Sem.Parent_Type := Type_Sem.U_Base_Type.Parent_Type;

      else
         --  This is a new base type.
         declare
            Enc_Module : constant Module_Sem_Ptr :=
              Find_Enclosing_Module_Interface (Decl_Region);
         begin
            if Type_Sem.New_Type_Counter = Anonymous_Type_Indicator then
               --  This type defines the "base structure"
               if Type_Sem.U_Base_Structure = null
                 and then
                   Not_Null (Type_Sem.Definition)
                 and then
                   Tree_Ptr_Of (Type_Sem.Definition).all in Invocation.Tree
               then
                  Type_Sem.U_Base_Structure := Type_Sem;
               end if;
            else
               --  U_Base_Structure should already be filled in
               pragma Assert (Type_Sem.U_Base_Structure /= null);
               null;
            end if;

            --  Recompute All_Parameters_Known, Known_To_Be_Small,
            --  and Known_To_Be_Assignable.
            if Type_Sem.All_Parameters_Known then
               --  Nothing to do
               null;
            elsif Type_Sem.Func_Type_Op_Sem /= null then
               --  See whether all parameter types are known
               declare
                  T : Operation.Tree renames
                    Operation.Tree (Tree_Ptr_Of (Type_Sem.Definition).all);
               begin
                  Type_Sem.All_Parameters_Known :=
                      Param_Types_Are_All_Known (T.Operation_Inputs)
                    and then
                      Param_Types_Are_All_Known (T.Operation_Outputs);
               end;
            elsif Type_Sem.U_Base_Structure = null then
               if Debug_Second_Pass then
                  Put_Line ("For new base type defined by " &
                    Subtree_Image (Type_Sem.Definition) &
                    " U_Base_Structure is null.");
               end if;
            elsif Type_Sem.Is_Formal_Type then
               if Debug_Second_Pass then
                  Put_Line ("For new base type defined by " &
                    Subtree_Image (Type_Sem.Definition) &
                    " type is a formal type.");
               end if;
            elsif Type_Sem.Enclosing_Type /= null
              and then not Type_Sem.Enclosing_Type.All_Parameters_Known
            then
               if Debug_Second_Pass then
                  Put_Line ("For new base type defined by " &
                    Subtree_Image (Type_Sem.Definition) &
                    " Enclosing_Type is not compile-time known: " &
                    Type_Image (Type_Sem.Enclosing_Type));
               end if;
            else
               --  See whether all module actual parameters are known
               declare
                  T : Invocation.Tree renames
                    Invocation.Tree (Tree_Ptr_Of
                      (Type_Sem.U_Base_Structure.Definition).all);
                  Num_Formals : constant Natural :=
                    Num_Module_Parameters (Module_Sem);
               begin
                  if Num_Formals = 0 then
                     --  Trivially true
                     Type_Sem.All_Parameters_Known := True;
                  elsif Type_Sem.Actual_Sem_Infos /= null then
                     if Type_Sem.Actual_Sem_Infos'Length = Num_Formals then
                        --  Recompute "All_Parameters_Known"
                        Type_Sem.All_Parameters_Known := True;
                        --  Assume true initially
                        for I in 1 .. Lists.Length (T.Operands) loop
                           if Type_Sem.Actual_Sem_Infos (I) = null
                             or else
                               not Is_Compile_Time_Known
                                 (Type_Sem.Actual_Sem_Infos (I).Definition)
                           then
                              if Debug_Second_Pass then
                                 Put_Line ("For new base type defined by " &
                                   Subtree_Image (Type_Sem.Definition) &
                                   " -- actual #" & Integer'Image (I) &
                                   " not compile-time known.");
                                 if Type_Sem.Actual_Sem_Infos (I) = null then
                                    Put_Line (" Actual is null");
                                 else
                                    Put_Line (" Actual is " &
                                      Subtree_Image
                                        (Type_Sem.Actual_Sem_Infos (I).
                                           Definition));
                                 end if;
                              end if;
                              Type_Sem.All_Parameters_Known := False;
                              exit;
                           end if;
                        end loop;
                     else
                        --  Mismatch in number of parameters
                        Sem_Error
                          (Type_Sem.U_Base_Structure.Definition,
                           "Internal: Num_Formals =" &
                           Natural'Image (Num_Formals) &
                           ", Actuals'Length =" &
                           Natural'Image (Type_Sem.Actual_Sem_Infos'Length));
                     end if;
                  end if;
               end;
            end if;

            if Debug_Second_Pass then
               Put_Line
                 ("For new base type defined by " &
                  Subtree_Image (Type_Sem.Definition) &
                  " -- All_Parameters_Known = " &
                  Boolean'Image (Type_Sem.All_Parameters_Known));
            end if;

            if Module_Sem /= null
              and then Module_Sem.Num_Visible_Components < 0
            then
               --  Make sure we have counted the components first
               --  Since that is when we check whether contains a ref
               --  component.
               declare
                  Num_Comps : constant Natural := Num_Components (Module_Sem);
               begin
                  if Debug_First_Pass then
                     Put_Line
                       (" Num components of " &
                        Sym_Name (Module_Sem.Associated_Symbol) &
                        " is" &
                        Natural'Image (Num_Comps));
                  end if;
               end;
            end if;

            if not Type_Sem.Known_To_Be_Assignable
              and then Type_Sem.Func_Type_Op_Sem = null
              and then Module_Sem /= null
              and then not Module_Sem.Contains_Ref_Component
              and then
               Module_Sem.Associated_Symbol.Str /= Any_Str
              and then not Is_Limited_Type_Module (Module_Sem)
            then
               --  Non-concurrent, non-limited type (other than Any<>) without
               --  any "ref" components is known-to-be-assignable.
               --  NOTE: We used to disallow assignment to
               --       non-concurrent objects with concurrent components,
               --       but that doesn't seem necessary anymore, since
               --       exclusive access is required to do an assignment.
               --       Also, we now require use of "ref" for components
               --       of a type that contains a "ref" so that means
               --       the Contains_Ref_Component is adequate to
               --       determine whether there is a "real" ref anywhere
               --       inside.
               --  TBD:  We now allow even concurrent types to be assignable.
               --       The compiler will have to disallow assignment
               --       for unlocked concurrent objects when appropriate.
               --  TBD: We might allow assignment of func-types if we
               --       somehow know there are no up-level references.
               --       E.g., we might require "Global" somewhere in the
               --       param list to allow the actual func to have any
               --       up-level references, or allow named/"new" func-types to
               --       be assignable but anonymous ones not.
               Type_Sem.Known_To_Be_Assignable := True;
            end if;

            if Type_Sem.Parent_Type /= null
              and then Type_Sem.New_Type_Counter = Anonymous_Type_Indicator
              and then not Type_Sem.Parent_Type.All_Parameters_Known
            then
               --  Parent type is parameterized;
               --    substitute from Type_Sem params.
               declare
                  Parent_Module : constant Module_Sem_Ptr :=
                    Type_Sem.Parent_Type.Associated_Module;
                  Num_Parent_Formals : constant Natural :=
                    Num_Module_Parameters (Parent_Module);
               begin
                  if Type_Sem.Parent_Type /=
                     Type_Sem.Parent_Type.Associated_Module.Cur_Inst_Sem
                  then
                     --  Parent type has parameters and is not a "cur-inst"
                     --  type, so substitute in for its parameters now.
                     Type_Sem.Parent_Type :=
                        Substitute_Actuals
                          (Type_Sem.Parent_Type,
                           Type_Region_Ptr (Type_Sem));
                  elsif Type_Sem.Actual_Sem_Infos /= null
                     and then not Type_Sem.Associated_Module.Treat_As_Type
                     and then
                        (Num_Parent_Formals = 0 or else
                         not Some_Nulls (Type_Sem.Actual_Sem_Infos))
                  then
                     --  Child type inherited the parameters of the
                     --  parent type, so we can use some part of the
                     --  Actual_Sem_Infos of the child type to instantiate
                     --  the parent type.
                     Type_Sem.Parent_Type :=
                        Instantiate_Module
                          (Mod_Sem => Parent_Module,
                           Actual_Params =>
                             Type_Sem.Actual_Sem_Infos.all
                               (1 .. Num_Parent_Formals),
                           Decl_Region => Decl_Region,
                           Enclosing_Type =>
                              Substitute_Actuals
                                (Type_Sem.Parent_Type.Enclosing_Type,
                                 Type_Region_Ptr (Type_Sem.Enclosing_Type)),
                           Source_Pos =>
                              Find_Source_Pos (Type_Sem.Definition));
                  end if;
               end;
            end if;

            if Type_Sem.Is_Formal_Type then
               --  A formal type, or an actual-of-formal
               if Enc_Module /= null
                 and then Not_Null (Type_Sem.Formal_Prefix)
                 and then Tree_Ptr_Of (Type_Sem.Formal_Prefix).all in
                    Qualified_Name.Tree
                 and then (Type_Sem.Associated_Generic_Op = null
                          or else not Enc_Module.
                            Ancestor_Decls_Being_Inherited)
               then
                  --  This is an actual-of-formal.
                  --  Add it to list of actual-of-formal types.
                  Add_Element
                    (Enc_Module.Actuals_Of_Formals,
                     Type_Sem,
                     Type_Sem.Actual_Of_Formal_Index);

                  pragma Assert
                    (Enc_Module = Type_Sem.Outermost_Module_Where_Used);
               end if;

            elsif Type_Sem.Func_Type_Op_Sem /= null then
               --  Func type.  No further processing required
               --  NOTE: We don't need to create run-time type descriptors
               --        for func types, in general, so we don't need
               --        to create nested type slots for them.
               --  NOTE 2: We *do* need to create nested type slots
               --        for abstract types because we might
               --        need a run-time type descriptor for their polymorphic
               --        type, and that typically needs a type descriptor for
               --        the root type.
               null;
            elsif not Type_Sem.All_Parameters_Known then
               --  This nested non-abstract type isn't fully
               --  known, so we need to assign it a location
               --  in the type area, unless it is the current
               --  instance of a module with parameters,
               --  or we are in the middle of inheriting decls
               --  and this type is part of a generic operation.
               if (Type_Sem.Associated_Generic_Op = null
                  or else Enc_Module = null
                  or else not Enc_Module.Ancestor_Decls_Being_Inherited)
                 and then (Module_Sem = null
                          or else Type_Sem /= Module_Sem.Cur_Inst_Sem
                          or else Num_Module_Parameters (Module_Sem) = 0)
               then
                  --  current instance doesn't need further processing
                  --  unless it can be used from outside the module.
                  declare
                     use type Symbols.Region_Ptr;
                  begin
                     --  This is a nested type that depends somehow
                     --  on enclosing module parameters.
                     --  Add it to list of types needing "actuals" provided
                     --  at run-time, and then compute its location
                     --  in the type area.
                     if Enc_Module = null then
                        Sem_Error
                          (Type_Sem.Definition,
                           "Type parameters not compile-time known");
                        if Debug_Code_Gen then
                           Diagnose_Unknown_Parameters
                             (Type_Sem,
                              Indent => 2);
                        end if;
                        return;
                     end if;

                     Add_Element
                       (Enc_Module.Nested_Types,
                        Type_Sem,
                        Type_Sem.Nested_Type_Index);

                     if Module_Sem = null
                       and then Type_Sem.Outermost_Module_Where_Used = null
                     then
                        --  Prior error; fill in outermost module where used
                        Type_Sem.Outermost_Module_Where_Used := Enc_Module;
                     else
                        pragma Assert
                          (Enc_Module = Type_Sem.Outermost_Module_Where_Used);
                        null;
                     end if;

                     if Debug_Second_Pass then
                        Put_Line
                          ("Defining new nested type #" &
                           Type_Sem_Vectors.Elem_Index'Image
                              (Type_Sem.Nested_Type_Index) &
                           " of " &
                           Sym_Name (Enc_Module.Associated_Symbol) &
                           Treat_As_Type_Indicator (Enc_Module) &
                           ": " &
                           Type_Image (Type_Sem));
                     end if;
                  end;
               end if;
            elsif not Type_Sem.Known_To_Be_Small
              and then Module_Sem /= null
            then
               --  This is a new base type, and we know everything
               --  about it, recompute known-to-be-small.
               declare
                  Is_Small : constant Boolean := Known_To_Be_Small (Type_Sem);
               begin

                  if Debug_Second_Pass then
                     Put_Line
                       ("For new fully-defined base type defined by " &
                        Subtree_Image (Type_Sem.Definition) &
                        " -- Known_To_Be_Small = " &
                        Boolean'Image (Is_Small) &
                        ", Known_To_Be_Large = " &
                        Boolean'Image (Type_Sem.Known_To_Be_Large) &
                        ", Is_Wrapper = " &
                        Boolean'Image (Type_Is_Wrapper (Type_Sem)));
                  end if;

               end;
            end if;  --  whether all info about type is known

            if Module_Sem = null
              and then Any_Type /= null
            then
               --  Some prior error.
               --  Give this type a the module for type "Any."
               Type_Sem.Associated_Module := Any_Type.Associated_Module;
            end if;
         end;
      end if;  --  whether this is a new base type

      if Type_Sem.U_Base_Structure = null
        and then Any_Type /= null
      then
         --  Make sure that U_Base_Structure is always filled in
         Type_Sem.U_Base_Structure := Any_Type.U_Base_Structure;
      end if;

      if Type_Sem.Outermost_Module_Where_Used = null then
         pragma Assert (Type_Sem.Nested_Type_Index = 0);
         pragma Assert (Type_Sem.Actual_Of_Formal_Index = 0);
         null;
      end if;

      if Type_Sem.New_Type_Counter > 1
        or else (Type_Sem.New_Type_Counter = 1
          and then Languages.Language /= Languages.Sparkel)
      then
         --  Universal types must be 0 or 1, and only 1 if this is Sparkel
         pragma Assert (not Type_Sem.Is_Universal);
         null;
      end if;
   end Finish_Type_Sem_Info;

   procedure Update_Outermost_Module_Where_Used
     (Type_Sem : Type_Sem_Ptr;
      New_Module_Where_Used : Module_Sem_Ptr) is
   --  Update Outermost_Module_Where_Used of Type_Sem if
   --  New_Module_Where_Used is different and enclosing.
      Base_Type : Type_Sem_Ptr := Type_Sem.U_Base_Type;
      Original_Module : Module_Sem_Ptr;
   begin
      if Base_Type = null then
         Base_Type := Type_Sem;
      end if;
      Original_Module := Base_Type.Outermost_Module_Where_Used;

      if New_Module_Where_Used /= Original_Module
        and then Original_Module /= null
        and then not Base_Type.All_Parameters_Known
        and then New_Module_Where_Used /= null
        and then Region_Encloses_Region
                    (Encloser => New_Module_Where_Used.Nested_Region,
                     Enclosed =>
                       Original_Module.Nested_Region)
      then
         --  Oh dear, new type comes from an enclosing module,
         --  it is not fully defined, so update Outermost_Module_...
         --  and recompute the other info.
         if Debug_Second_Pass then
            Put_Line
              (" Changing Outermost_Module for " &
               Type_Image (Base_Type) &
               " from " &
               Subtree_Image
                  (Original_Module.Definition, Use_Short_Form => True) &
               " to " &
               Subtree_Image (New_Module_Where_Used.Definition,
                  Use_Short_Form => True));
         end if;
         Base_Type.Outermost_Module_Where_Used := New_Module_Where_Used;
         --  Set base type so that it uses the enclosing module

         --  Reinitialize the indices
         Base_Type.Actual_Of_Formal_Index := 0;
         Base_Type.Nested_Type_Index := 0;
         Base_Type.Type_Descriptor_Location :=
           Interpreter.Null_Object_Locator;

         --  Recompute the indices
         Finish_Type_Sem_Info
           (Base_Type,
            Decl_Region => New_Module_Where_Used.Nested_Region);

         if Num_Entries (Base_Type.Op_Maps_Needed) > 0 then
            --  Need to allocate indices in new module for
            --  op-map type descriptors, and update Op_Maps_Needed
            --  and Nested_Type_Op_Map_Target mappings.
            declare
               Old_Op_Maps_Needed : Type_Sem_Index_Table :=
                 Base_Type.Op_Maps_Needed; --  Save old op-maps-needed tbl

               procedure Assign_New_Op_Map_Index
                 (Viewed_As : Type_Sem_Ptr;
                  Old_Index : Type_Sem_Vectors.Elem_Index)
               --  Assign new index in new module for op-map;
               --  TBD: We could free up the spot in the original module
               --       but we share the op-map descriptors now, so no need.
               is
                  New_Index : constant Type_Sem_Vectors.Elem_Index :=
                    Op_Map_Type_Desc_Index
                      (Obj_Type => Base_Type,
                       Formal_Type => Viewed_As,
                       Source_Pos =>
                         Find_Source_Pos (Base_Type.Definition));
               begin
                  if Debug_Second_Pass then
                     Put_Line (" Update_Outermost_Module_Where_Used: " &
                       "index for " & Type_Image (Base_Type) &
                       " viewed as " &
                       Type_Image (Viewed_As) & " changed from" &
                       Type_Sem_Vectors.Elem_Index'Image (Old_Index) & " in " &
                       Sym_Name (Original_Module.Associated_Symbol) & " to" &
                       Type_Sem_Vectors.Elem_Index'Image (New_Index) & " in " &
                       Sym_Name (New_Module_Where_Used.Associated_Symbol));
                  end if;
               end Assign_New_Op_Map_Index;

               procedure Assign_New_Indices is
                 new Type_Sem_Index_Tables.Iterate_And_Remove
                   (Assign_New_Op_Map_Index);
            begin
               if Debug_Second_Pass then
                  Put_Line (" Update_Outermost_Module_Where_Used (" &
                    Type_Image (Base_Type) & "): " &
                    "Op_Maps_Needed nonempty");
               end if;

               --  Wipe out old hash table.
               Base_Type.Op_Maps_Needed := Empty_Hash_Table;

               --  Assign new indices for op maps in New_Module_Where_Used.
               Assign_New_Indices (Type_Sem_Index_Tables.Hash_Table
                 (Old_Op_Maps_Needed));
            end;
         end if;

      end if;
   end Update_Outermost_Module_Where_Used;

   procedure Set_Type_Sem_Info
     (T : in out Invocation.Tree;
      Module_Sem : Module_Sem_Ptr;
      Decl_Region : Symbols.Region_Ptr;
      Is_Formal_Type : Boolean;
      Enclosing_Type : Type_Sem_Ptr;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      Associated_Generic_Op : Sym_Ptr := null;
      Actual_Sem_Infos : Sem_Info_Array_Ptr := null;
      Use_Primary_Nested_Type : Boolean := False) is
      --  Fill in sem info for type defined by module instantiation
      --  If Use_Primary_Nested_Type is True then this will return
      --  the Primary_Nested_Type of the Module_Sem if it has one.

      use type Invocation.Invocation_Kind_Enum;
      pragma Assert (T.Kind = Invocation.Module_Instantiation);
      Type_Sem : constant Type_Sem_Ptr := new Type_Semantic_Info;
   begin
      if Use_Primary_Nested_Type
        and then Module_Sem /= null
        and then Module_Sem.Primary_Nested_Type /= null
      then
         --  We actually want to refer to the primary nested type
         --  within this instance.
         declare
            Actual_Sem_Infos_For_Nested_Type : Sem_Info_Array_Ptr := null;
         begin

            --  Recurse to create a (non-formal) encloser
            Set_Type_Sem_Info (T,
               Module_Sem => Module_Sem,
               Decl_Region => Decl_Region,
               Is_Formal_Type => False,
               Enclosing_Type => Enclosing_Type,
               Formal_Prefix => Null_Optional_Tree,
               Associated_Generic_Op => Associated_Generic_Op,
               Actual_Sem_Infos => Actual_Sem_Infos,
               Use_Primary_Nested_Type => False);

            --  Recurse again to create a (possibly-formal) primary-nested type
            --  using type created above as encloser for this one.

            if Is_Formal_Type then
               --  If this is a formal type, then copy the Actual_Sem_Infos
               --  created for the enclosing (package) type, in case
               --  this is a generic package, and we will need a place
               --  to save the actuals-of-formals.
               Actual_Sem_Infos_For_Nested_Type := Actual_Sem_Infos;
            end if;

            Set_Type_Sem_Info (T,
               Module_Sem => Module_Sem.Primary_Nested_Type.Associated_Module,
               Decl_Region => Decl_Region,
               Is_Formal_Type => Is_Formal_Type,
               Enclosing_Type => Type_Sem_Ptr (T.Sem_Info),
               Formal_Prefix => Formal_Prefix,
               Associated_Generic_Op => null,
               Actual_Sem_Infos => Actual_Sem_Infos_For_Nested_Type,
               Use_Primary_Nested_Type => False);

            return;  --  All done
         end;
      end if;

      Type_Sem.Definition := Optional (T'Access);
      Set_Sem_Info (Type_Sem.Definition, Root_Sem_Ptr (Type_Sem));

      Type_Sem.New_Type_Counter := Anonymous_Type_Indicator;
      Type_Sem.Value_Is_Optional := False;
      Type_Sem.Obj_Is_Concurrent := False;
      Type_Sem.Is_Polymorphic := False;
      Type_Sem.Outermost_Module_Where_Used :=
         Find_Enclosing_Module_Interface (Decl_Region);
      Type_Sem.Is_Formal_Type := Is_Formal_Type;
      Type_Sem.Enclosing_Type := Enclosing_Type;
      Type_Sem.Formal_Prefix := Formal_Prefix;
      Type_Sem.Associated_Generic_Op := Associated_Generic_Op;
      Type_Sem.Actual_Sem_Infos := Actual_Sem_Infos;

      if Module_Sem /= null then
         Type_Sem.Associated_Module := Module_Sem;

         if not Module_Sem.Is_Interface then
            Sem_Error
              (T.Prefix,
               " Cannot find interface for module " &
               Sym_Name (Module_Sem.Associated_Symbol) &
                 Treat_As_Type_Indicator (Module_Sem));
         end if;

         Type_Sem.Is_Universal :=
           Type_Sem.Associated_Module.Cur_Inst_Sem.Is_Universal;
         if Type_Sem.New_Type_Counter > 0 then
            --  Copy U_Base_Structure
            Type_Sem.U_Base_Structure :=
              Type_Sem.Associated_Module.Cur_Inst_Sem.U_Base_Structure;
         end if;
         Type_Sem.Known_To_Be_Small :=
             not Is_Formal_Type
           and then
             Type_Sem.Associated_Module.Cur_Inst_Sem.Known_To_Be_Small;
         Type_Sem.Known_To_Be_Assignable :=
           Type_Sem.Associated_Module.Cur_Inst_Sem.Known_To_Be_Assignable;
         Type_Sem.All_Parameters_Known :=
             not Is_Formal_Type
           and then
             Type_Sem.Associated_Module.Cur_Inst_Sem.All_Parameters_Known;

         Type_Sem.Parent_Type :=
           Type_Sem.Associated_Module.Cur_Inst_Sem.Parent_Type;
         --  NOTE: This isn't quite right.
         --       We will update in Finish_Type_Sem_Info

         if Debug_Second_Pass then
            if Not_Null (Formal_Prefix)
              and then Tree_Ptr_Of (Formal_Prefix).all not in Identifier.Tree
            then
               Put_Line
                 (" Formal prefix of " &
                  Type_Image (Type_Sem) &
                  " is " &
                  Subtree_Image (Formal_Prefix));
            end if;
            if Associated_Generic_Op /= null then
               Put_Line
                 (" Associated_Generic_Op of " &
                  Type_Image (Type_Sem) &
                  " is " &
                  Subtree_Image (Associated_Generic_Op.Definition));
            end if;
         end if;
      end if;

      if Type_Sem.Is_Universal
        and then Module_Sem /= null
        and then Module_Sem.Cur_Inst_Sem.U_Base_Type = null
      then
         --  Finish original universal cur-inst type now, so its gets to be
         --  the unique base type.
         Finish_Type_Sem_Info
           (Module_Sem.Cur_Inst_Sem, Module_Sem.Nested_Region);
      end if;

      Finish_Type_Sem_Info (Type_Sem, Decl_Region);

   end Set_Type_Sem_Info;

   function Generic_Types_Match
     (Generic_Type1, Generic_Type2 : Type_Sem_Ptr)
      return Boolean
   is
      --  Return True if types are equivalent "generic" types
      Actuals1 : constant Sem_Info_Array_Ptr :=
        Generic_Type1.Actual_Sem_Infos;
      Actuals2 : constant Sem_Info_Array_Ptr :=
        Generic_Type2.Actual_Sem_Infos;
   begin
      if Generic_Type1.U_Base_Type = Generic_Type2.U_Base_Type then
         --  Exact match
         return True;
      elsif Generic_Type1.Associated_Module /=
            Generic_Type2.Associated_Module
        and then (Generic_Type1.Associated_Module.Associated_Symbol.Str /=
                  Generic_Type2.Associated_Module.Associated_Symbol.Str
                 or else Generic_Type1.Associated_Module.Nested_Region.
                    Enclosing_Region /=
                      Generic_Type2.Associated_Module.Nested_Region.
                        Enclosing_Region)
      then
         --  Module mismatch
         return False;
      elsif All_Nulls (Actuals1) or else All_Nulls (Actuals2) then
         --  Modules match and at least one has no actuals
         --> they both should
         return All_Nulls (Actuals1) and then All_Nulls (Actuals2);
      elsif Actuals1'Length /= Actuals2'Length then
         --  Actual parameter count mismatch
         return False;
      else
         --  Module match is close enough, and same number of actuals.
         --  Check the actuals in more detail
         for I in Actuals1'Range loop
            --  Compare the Actuals
            if Actuals1 (I) = null or else Actuals2 (I) = null then
               if Actuals1 (I) /= Actuals2 (I) then
                  if Debug_Second_Pass then
                     Put_Line
                       (" Missing actual" &
                        Integer'Image (I) &
                        " in " &
                        Type_Image (Generic_Type1) &
                        " vs. " &
                        Type_Image (Generic_Type2));
                  end if;
                  return False;
               end if;
            elsif not Equiv_Tree
                        (Actuals1 (I).Definition,
                         Actuals2 (I).Definition)
              and then  --  Fall back on image equivalence as last resort
                Type_Image (Generic_Type1) /= Type_Image (Generic_Type2)
            then
               if Debug_Second_Pass then
                  Put_Line
                    (" Mismatched Actual " &
                     Subtree_Image (Actuals1 (I).Definition) &
                     " in " &
                     Type_Image (Generic_Type1) &
                     " vs. " &
                     Subtree_Image (Actuals2 (I).Definition) &
                     " in " &
                     Type_Image (Generic_Type2));
               end if;
               return False;
            end if;
         end loop;
         --  All actuals are equivalent
         return True;
      end if;

   end Generic_Types_Match;

   function Parameters_Match
     (Param1, Param2 : Trees.Tree'Class;
      Extra_Subst1, Extra_Subst2 : Type_Sem_Ptr := null;
      Substitute_Using1 : Type_Region_Ptr := null;
      Substitute_Using2 : Type_Region_Ptr := null;
      Complain_If_Different : Boolean := False;
      Allow_New_Type1 : Boolean := False;
      Allow_New_Type2 : Boolean := False;
      Diagnose : Boolean := False)
      return Boolean
   is
   --  Return True if corresponding parameters of two operations
   --  match.  Extra_Subst1/2 are corresponding types that are
   --  always considered to match (e.g. current insts of relevant modules).
   --  Before comparing, substitute the types of the first
   --  operation with the Substitute_Using1 type region, if non null,
   --  and the types of the second operation with the
   --  Substitute_Using2 type region, if non null.
   --  Also check that the modes of the parameters match.
   --  If "Complain_If_Different" is True, then verify that names, defaults,
   --  etc. match, and complain if not.
   --  If "Allow_New_Type1" is True, then allow type of param in first
   --  signature to be a "new" type relative to param in second.
   --  If "Allow_New_Type2" is True, then allow type of param in second
   --  signature to be a "new" type relative to param in first.
   --  If "Diagnose" is True, then provide "info" messages indicating
   --  how Param2 differs from Param1.
   begin
      if Param1.Sem_Info = null or else Param2.Sem_Info = null then
         if Debug_Second_Pass then
            Put ("Parameters_Match: ");
            if Param1.Sem_Info = null then
               Put ("Param1.Sem_Info = null ");
            end if;
            if Param2.Sem_Info = null then
               Put ("Param2.Sem_Info = null ");
            end if;
            New_Line;
         end if;
         return False;
      elsif Param1 in Operation.Tree and then Param2 in Operation.Tree then
         --  Both are operations, see whether they match
         return Param1.Sem_Info.all in Operation_Semantic_Info
               and then Param2.Sem_Info.all in Operation_Semantic_Info
               and then Signatures_And_Modes_Match
                           (Operation_Sem_Ptr (Param1.Sem_Info),
                            Operation_Sem_Ptr (Param2.Sem_Info),
                            Extra_Subst1,
                            Extra_Subst2,
                            Substitute_Using1,
                            Substitute_Using2,
                            Complain_If_Different => Complain_If_Different,
                            Allow_New_Type1 => Allow_New_Type1,
                            Allow_New_Type2 => Allow_New_Type2,
                            Diagnose => Diagnose);
      elsif Param1 in Param_Decl.Tree
        and then Param2 in Param_Decl.Tree
      then
         --  Both are parameters, see whether their types match
         --  or they match their respective current instance type.
         if Param1.Sem_Info.all not in Object_Semantic_Info'Class
           or else Param2.Sem_Info.all not in Object_Semantic_Info'Class
         then
            --  Semantic info types don't match
            if Debug_Second_Pass then
               Put_Line
                 (" Parameters not both objects; comparing " &
                  Subtree_Image (Param1) &
                  " vs. " &
                  Subtree_Image (Param2));
            end if;
            return False;
         else
            declare
               Param_Sem1 : constant Object_Sem_Ptr :=
                 Object_Sem_Ptr (Param1.Sem_Info);
               Param_Sem2 : constant Object_Sem_Ptr :=
                 Object_Sem_Ptr (Param2.Sem_Info);
               Param_Type1 : Type_Sem_Ptr := Param_Sem1.Resolved_Type;
               Param_Type2 : Type_Sem_Ptr := Param_Sem2.Resolved_Type;
               Param1_Is_Var : constant Boolean :=
                 Sym_Is_Variable (Param_Sem1.Associated_Symbol);
               Param2_Is_Var : constant Boolean :=
                 Sym_Is_Variable (Param_Sem2.Associated_Symbol);
               Param1_Is_By_Ref : constant Boolean :=
                 Sym_Is_By_Ref (Param_Sem1.Associated_Symbol);
               Param2_Is_By_Ref : constant Boolean :=
                 Sym_Is_By_Ref (Param_Sem2.Associated_Symbol);
               use type Param_Decl.Param_Locking;
            begin
               if Param_Type1 = null
                 or else Param_Type2 = null
               then
                  --  Some prior error
                  if Debug_Second_Pass then
                     Put ("Parameters_Match: ");
                     if Param_Type1 = null then
                        Put ("Param_Type1 = null ");
                     end if;
                     if Param_Type2 = null then
                        Put ("Param_Type2 = null ");
                     end if;
                     New_Line;
                  end if;
                  return False;
               end if;

               if Param1_Is_Var /= Param2_Is_Var
                 or else Param1_Is_By_Ref /= Param2_Is_By_Ref
               then
                  --  Different modes
                  if Diagnose then
                     declare
                        function Param1_Mode_Str return String is
                        begin
                           if Param1_Is_Var /= Param2_Is_Var then
                              if Param1_Is_Var then
                                 return "var";
                              else
                                 return "not var";
                              end if;
                           elsif Param1_Is_By_Ref then
                              return "by ref";
                           else
                              return "not by ref";
                           end if;
                        end Param1_Mode_Str;
                     begin
                        Messages.Put_Message
                          ("Param of original operation is " &
                           Param1_Mode_Str,
                           Src_Pos => Find_Source_Pos (Param2),
                           Message_Kind => "Info");
                     end;
                  end if;
                  return False;
               end if;

               if Param_Decl.Tree (Param1).Locking /=
                  Param_Decl.Tree (Param2).Locking
               then
                  --  Different locking
                  if Debug_Matching then
                     Put_Line
                       ("Parameters_Match: Param1.Locking = " &
                        Param_Decl.Param_Locking'Image
                           (Param_Decl.Tree (Param1).Locking) &
                        ", Param2.Locking + " &
                        Param_Decl.Param_Locking'Image
                           (Param_Decl.Tree (Param2).Locking));
                  end if;
                  if Diagnose then
                     Messages.Put_Message
                       ("Original operation has locking of " &
                        Param_Decl.Param_Locking'Image
                          (Param_Decl.Tree (Param1).Locking),
                        Src_Pos => Find_Source_Pos (Param2),
                        Message_Kind => "Info");
                  end if;
                  return False;
               end if;

               if Complain_If_Different then
                  if Not_Null (Param_Decl.Tree (Param1).Name)
                    and then Subtree_Image (Param_Decl.Tree (Param1).Name) /=
                             Subtree_Image (Param_Decl.Tree (Param2).Name)
                  then
                     --  If name given on Op1, then matching name must
                     --  be given on Op2.
                     Sem_Error
                       (Param2,
                        "Parameter name must be " &
                        Subtree_Image (Param_Decl.Tree (Param1).Name));
                  end if;
               end if;

               if Param_Type1.U_Base_Type = null
                 or else Param_Type2.U_Base_Type = null
               then
                  --  Uninitialized types
                  if Debug_Second_Pass then
                     Put_Line
                       (" Parameter types not initialized; comparing " &
                        Type_Image (Param_Type1) &
                        " vs. " &
                        Type_Image (Param_Type2));
                  end if;
                  return False;
               elsif Param_Type1.U_Base_Type = Extra_Subst1
                 and then Param_Type2.U_Base_Type =
                          Extra_Subst2
               then
                  --  These are considered to always match
                  return True;
               else
                  declare
                     Param1_Base_Type : constant Type_Sem_Ptr :=
                       Substitute_Actuals
                          (Param_Type1.U_Base_Type,
                           Substitute_Using1);

                     Map : aliased Param_Mapping;

                     function Extra_Map return Param_Mapping_Ptr is
                     begin
                        if Extra_Subst1 /= null
                          and then Extra_Subst2 /= null
                        then
                           --  Build a single-entry param map
                           Map :=
                             (From => Sem_Ptr (Extra_Subst2.U_Base_Type),
                              To => Sem_Ptr (Extra_Subst1),
                              Next => null);
                           return Map'Unchecked_Access;
                        else
                           --  No param map needed
                           return null;
                        end if;
                     end Extra_Map;

                     Param2_Base_Type : constant Type_Sem_Ptr :=
                       Substitute_Actuals
                          (Param_Type2.U_Base_Type,
                           Substitute_Using2,
                           Extra_Subst => Extra_Map);
                     Param1_Adjusted_Base : Type_Sem_Ptr :=
                       Param1_Base_Type.U_Base_Type;
                     Param2_Adjusted_Base : Type_Sem_Ptr :=
                       Param2_Base_Type.U_Base_Type;
                  begin
                     if Param1_Adjusted_Base.External_View /= null then
                        Param1_Adjusted_Base :=
                          Param1_Adjusted_Base.External_View;
                     end if;
                     if Allow_New_Type1 then
                        Param1_Adjusted_Base :=
                          Param1_Adjusted_Base.U_Base_Structure;
                     end if;

                     if Param2_Adjusted_Base.External_View /= null then
                        Param2_Adjusted_Base :=
                          Param2_Adjusted_Base.External_View;
                     end if;
                     if Allow_New_Type2 then
                        Param2_Adjusted_Base :=
                          Param2_Adjusted_Base.U_Base_Structure;
                     end if;

                     if Complain_If_Different
                       and then
                         Param1_Base_Type.Associated_Generic_Op = null
                       and then Param_Type1.U_Type /=
                         Param_Type2.U_Type
                     then
                        --  Non-exact match, and not generic
                        Sem_Error
                          (Param2,
                            " Parameter types don't match: " &
                             Type_Image (Param_Type1.U_Type) &
                             " not same as " &
                             Type_Image (Param_Type2.U_Type));
                        return False;
                     elsif Param1_Base_Type.U_Base_Type =
                        Param2_Base_Type.U_Base_Type
                     then
                        --  Base types match after substitution
                        return True;
                     elsif Param1_Adjusted_Base = Param2_Adjusted_Base then
                        --  "new" was allowed, and adjusted base types match.
                        return True;
                     elsif Param1_Base_Type.U_Base_Type = Extra_Subst1
                       and then Param2_Base_Type.U_Base_Type = Extra_Subst2
                     then
                        --  Types match extra substitution after substitution
                        return True;
                     elsif Param1_Base_Type.Associated_Generic_Op /= null
                       and then Param2_Base_Type.Associated_Generic_Op /=
                                null
                       and then Param1_Base_Type.Associated_Generic_Op.Str =
                                Param2_Base_Type.Associated_Generic_Op.Str
                     then
                        --  Both are associated with operation of same name
                        if Debug_Matching then
                           Put_Line
                             (" Checking for generic type match between " &
                              Type_Image (Param1_Base_Type) &
                              " and " &
                              Type_Image (Param2_Base_Type));
                        end if;
                        return Generic_Types_Match
                                 (Param1_Base_Type,
                                  Param2_Base_Type);
                     else
                        --  Mismatched types
                        if Debug_Matching then
                           Put_Line
                             (" Parameter types don't match; comparing " &
                              Type_Image (Param1_Base_Type.U_Type) &
                              " vs. " &
                              Type_Image (Param2_Base_Type.U_Type));
                        end if;
                        if Diagnose then
                           Messages.Put_Message
                             ("Param of original operation is of type " &
                              Canonical_Type_Name (Param1_Base_Type) &
                              ", not matched by " &
                              Canonical_Type_Name (Param2_Base_Type),
                              Src_Pos => Find_Source_Pos (Param2),
                              Message_Kind => "Info");
                        end if;
                        return False;
                     end if;
                  end;
               end if;
            end;
         end if;
      else
         --  Not both same kind of parameter
         if Debug_Matching then
            Put_Line
              ("Parameters_Match, Param1'Tag = " &
               Ada.Tags.Expanded_Name (Param1'Tag) &
               ", Param2'Tag = " &
               Ada.Tags.Expanded_Name (Param2'Tag));
         end if;
         return False;
      end if;
   end Parameters_Match;

   function Signatures_And_Modes_Match
     (Op_Sem1, Op_Sem2 : Operation_Sem_Ptr;
      Extra_Subst1, Extra_Subst2 : Type_Sem_Ptr := null;
      Substitute_Using1 : Type_Region_Ptr := null;
      Substitute_Using2 : Type_Region_Ptr := null;
      Complain_If_Different : Boolean := False;
      Allow_New_Type1 : Boolean := False;
      Allow_New_Type2 : Boolean := False;
      Diagnose : Boolean := False)
      return Boolean
   is
      --  Return True if two operations have same type
      --  for each parameter, or if a given parameter has
      --  Extra_Subst1/2 as corresponding types (these are
      --  always considered to match (e.g. current insts of
      --  relevant modules).  Also check modes for a match.
      --  Before comparing, substitute the types of the first
      --  operation with the Substitute_Using1 type region, if non null,
      --  and the types of the second operation with the
      --  Substitute_Using2 type region, if non null.
      --  If "Complain_If_Different" is True, then verify that names, defaults,
      --  etc. match, and complain if not, using source pos of Op_Sem2.
      --  If "Allow_New_Type1" is True, then allow type of param in first
      --  signature to be a "new" type relative to param in second.
      --  If "Allow_New_Type2" is True, then allow type of param in second
      --  signature to be a "new" type relative to param in first.
      --  If "Diagnose" is true, then produce "Info" messages to indicate
      --  how Op_Sem2 differs from Op_Sem1, presuming Op_Sem2 is supposed
      --  to override Op_Sem2.

      function Param_Lists_Match
        (Sig1_List : Lists.List;
         Sig2_List : Lists.List)
         return Boolean
      is
         --  Return True if parameter lists are same length and
         --  have same types and modes.
         Num_Params : constant Natural := Lists.Length (Sig1_List);
      begin
         if Lists.Length (Sig2_List) /= Num_Params then
            return False;
         else
            --  Same number of params.
            --  Walk them checking whether param types and modes match.
            for I in 1 .. Num_Params loop
               declare
                  Param1 : Trees.Tree'Class renames Tree_Ptr_Of
                                                       (Lists.Nth_Element
                                                           (Sig1_List,
                                                            I)).all;
                  Param2 : Trees.Tree'Class renames Tree_Ptr_Of
                                                       (Lists.Nth_Element
                                                           (Sig2_List,
                                                            I)).all;
               begin
                  if not Parameters_Match
                           (Param1,
                            Param2,
                            Extra_Subst1,
                            Extra_Subst2,
                            Substitute_Using1,
                            Substitute_Using2,
                            Complain_If_Different,
                            Allow_New_Type1, Allow_New_Type2,
                            Diagnose)
                  then
                     if Debug_Matching then
                        Put_Line
                          ("Param " &
                           Subtree_Image (Param1) &
                           " does not match " &
                           Subtree_Image (Param2));
                     end if;
                     return False;
                  end if;
               end;
            end loop;
            return True;
         end if;
      end Param_Lists_Match;

      Op_Tree1 : Operation.Tree
        renames Operation.Tree (Tree_Ptr_Of (Op_Sem1.Definition).all);
      Op_Tree2 : Operation.Tree
        renames Operation.Tree (Tree_Ptr_Of (Op_Sem2.Definition).all);

   begin  --  Signatures_And_Modes_Match

      if Complain_If_Different then
         if Op_Tree1.Is_Queued /= Op_Tree2.Is_Queued then
            Sem_Error
              (Op_Tree2,
               "Operation body must be marked ""queued"" " &
               "iff declaration is");
         end if;
         --  TBD: Other checks?
      end if;

      --  Check for match of both inputs and outputs
      return Param_Lists_Match
                (Op_Tree1.Operation_Inputs,
                 Op_Tree2.Operation_Inputs)
            and then Param_Lists_Match
                        (Op_Tree1.Operation_Outputs,
                         Op_Tree2.Operation_Outputs);
      --  Types and modes match

   end Signatures_And_Modes_Match;

   function Num_Initial_Value_Iterators
     (For_Loop_Sem : For_Loop_Construct_Sem_Ptr)
      return Natural
   is
      --  Number of iterators of for-loop that require "next" values
      --  because they don't have one specified.
      Count : Natural := 0;
      use type Iterator.Iterator_Kind_Enum;
   begin
      for I in For_Loop_Sem.Iterator_Sems'Range loop
         if Iterator.Tree (Tree_Ptr_Of
           (For_Loop_Sem.Iterator_Sems (I).Definition).all).Kind =
              Iterator.Initial_Value
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Num_Initial_Value_Iterators;

   procedure Count_Current_Instance_Operands
     (Op_Sem : Operation_Sem_Ptr;
      Cur_Inst_Type : Type_Sem_Ptr)
   is
      --  Count number of inputs and outputs that are
      --  of the current instance type.  If there are none,
      --  Determine whether this is a polymorphic operation,
      --  and identify the first polymorphic input.
      --  Results recorded in Op_Sem.Num_Cur_Inst_{Inputs,Outputs}
      --  and Op_Sem.First_Polymorphic_Input.

      Op_Tree : Operation.Tree renames
        Operation.Tree (Tree_Ptr_Of (Op_Sem.Definition).all);

      First_Polymorphic_Operand : Natural := 0;

      function Num_Cur_Inst_Type_In_List (L : Lists.List) return Natural is
         --  Count number of operands in list that are of cur-inst type.
         --  Update First_Polymorphic_Operand as a side-effect if was zero.
         Count : Natural := 0;
      begin
         for I in 1 .. Lists.Length (L) loop
            declare
               Operand_Sem : constant Sem_Ptr :=
                 Sem_Ptr (Sem_Info (Lists.Nth_Element (L, I)));
            begin
               if Operand_Sem /= null
                 and then Operand_Sem.all in Param_Semantic_Info
               then
                  --  We have an "object" parameter
                  declare
                     Resolved_Type : constant Type_Sem_Ptr :=
                       Param_Sem_Ptr (Operand_Sem).Resolved_Type;
                  begin
                     if Resolved_Type /= null
                       and then Types_Match (Resolved_Type, Cur_Inst_Type)
                     then
                        if Resolved_Type.Is_Polymorphic then
                           --  Remember index of first polymorphic operand
                           if First_Polymorphic_Operand = 0 then
                              First_Polymorphic_Operand := I;
                           end if;
                        else
                           --  We found an operand of
                           --  the non-polymorphic cur-inst-type.
                           Count := Count + 1;
                        end if;
                     end if;
                  end;
               end if;
            end;
         end loop;

         return Count;
      end Num_Cur_Inst_Type_In_List;

   begin  --  Count_Current_Instance_Operands

      Op_Sem.Num_Cur_Inst_Outputs :=
        Num_Cur_Inst_Type_In_List (Op_Tree.Operation_Outputs);

      First_Polymorphic_Operand := 0;  --  Initialize before call
      Op_Sem.Num_Cur_Inst_Inputs :=
        Num_Cur_Inst_Type_In_List (Op_Tree.Operation_Inputs);

      if Op_Sem.Num_Cur_Inst_Inputs + Op_Sem.Num_Cur_Inst_Outputs = 0 then
         --  Remember first polymorphic input
         Op_Sem.First_Polymorphic_Input := First_Polymorphic_Operand;
      end if;

   end Count_Current_Instance_Operands;

   function Has_Current_Instance_Operand
     (Op_Sem : Operation_Sem_Ptr;
      Cur_Inst_Type : Type_Sem_Ptr)
      return Boolean
   is
      --  Return True if operation T has at least one Input or Output
      --  that is of the Cur_Inst_Type (and *not* polymorphic).
   begin
      pragma Assert (Op_Sem.Num_Cur_Inst_Inputs >= 0);
      return Op_Sem.Num_Cur_Inst_Inputs + Op_Sem.Num_Cur_Inst_Outputs > 0;
   end Has_Current_Instance_Operand;

   function Inherit_Decl
     (Decl : Optional_Tree;
      Parent_Module, New_Module : Module_Sem_Ptr := null)
      return Optional_Tree
   is
      --  Copy a declaration, as part of inheritance.
      --  If Parent_Module and New_Module are specified, then
      --  substitute appearances of the parent module in the
      --  declaration with the new module, as appropriate to the
      --  kind of declaration.
      Extra_Subst : Param_Mapping_Ptr;
      Result : Optional_Tree;
      Parent_Type_Region : Type_Region_Ptr := null;
   begin
      if Parent_Module /= null and then New_Module /= null then
         --  Set up a mapping
         Parent_Type_Region :=
           U_Base_Type_Region (New_Module.Cur_Inst_Sem.Parent_Type);
         Extra_Subst :=
           new Param_Mapping'
           (From => Sem_Ptr (Parent_Module.Cur_Inst_Sem),
            To => Sem_Ptr (New_Module.Cur_Inst_Sem),
            Next => null);
      end if;

      --  Copy decl, with substitutions as appropriate
      Result :=
         Substitute_In_Tree
           (Decl,  --  TBD: This isn't quite right!
            Assoc_Type_Region => Parent_Type_Region,
            Extra_Subst => Extra_Subst,
            Always_Copy_Tree => True);

      if Debug_First_Pass then
         Put_Line (" Inheriting declaration:");
         Display_Subtree (Result, Indent => 3, Use_Short_Form => True);
         New_Line;
         if Debug_Substitution then
            --  Give more details on result of inheritance, for operations
            if Tree_Ptr_Of (Result).all in Operation.Tree then
               declare
                  Op_Tree : Operation.Tree renames Operation.Tree
                    (Tree_Ptr_Of (Result).all);
                  Op_Sem  : constant Operation_Sem_Ptr :=
                    Operation_Sem_Ptr (Op_Tree.Sem_Info);

                  procedure Give_Param_List_Details (L : Lists.List) is
                  --  Display more info on each parameter
                  begin
                     for I in 1 .. Lists.Length (L) loop
                        declare
                           Param : constant Optional_Tree :=
                             Lists.Nth_Element (L, I);
                           Param_Tree : Trees.Tree'Class renames
                             Tree_Ptr_Of (Param).all;
                           Param_Type : constant Type_Sem_Ptr :=
                             Resolved_Type (Param);
                        begin
                           Put_Line ("  " & Subtree_Image (Param));
                           if Param_Tree in Param_Decl.Tree
                             and then Param_Type /= null
                           then
                              --  Show type of param (two ways!)
                              declare
                                 Param_Decl_Tree : Param_Decl.Tree renames
                                   Param_Decl.Tree (Param_Tree);
                                 U_Sem : constant Sem_Ptr :=
                                   Underlying_Sem_Info
                                     (Param_Decl_Tree.Param_Type);
                              begin
                                 Put_Line ("   Resolved_Type: " &
                                   Type_Image (Param_Type));
                                 if U_Sem /= null
                                   and then
                                     U_Sem.all in Type_Semantic_Info
                                 then
                                    Put_Line ("   Underlying Type: " &
                                      Type_Image (Type_Sem_Ptr (U_Sem)));
                                 end if;
                              end;
                           end if;
                        end;
                     end loop;
                  end Give_Param_List_Details;
                  use type Interpreter.Operation_Index;
               begin
                  Put_Line ("  Input parameters:");
                  Give_Param_List_Details (Op_Tree.Operation_Inputs);
                  if Lists.Length (Op_Tree.Operation_Outputs) > 0 then
                     Put_Line ("  Output parameters:");
                     Give_Param_List_Details (Op_Tree.Operation_Outputs);
                  end if;
                  if Op_Sem /= null then
                     if Op_Sem.Index > 0 then
                        Put_Line ("  Index =" &
                          Interpreter.Operation_Index'Image (Op_Sem.Index));
                     end if;
                     if Op_Sem.Equiv_From_Type /= null then
                        Put_Line ("  Equiv_From_Type = " &
                          Type_Image (Op_Sem.Equiv_From_Type));
                     end if;
                     if Op_Sem.Originating_Module /= null then
                        Put_Line ("  Originating_Module = " &
                           Sym_Name
                             (Op_Sem.Originating_Module.Associated_Symbol));
                     end if;
                  end if;
               end;
            end if;
         end if;
      end if;

      return Result;
   end Inherit_Decl;

   function Decl_Should_Be_Inherited (Decl : Optional_Tree) return Boolean is
   --  Return True if Decl should be inherited when extending a type
      Decl_Tree : Trees.Tree'Class renames Tree_Ptr_Of (Decl).all;
   begin
      if Decl_Is_For_Component (Decl)
         or else Decl_Tree in Implements_Element.Tree
         or else Decl_Tree in Operation.Tree
      then
         --  All of these should be inherited because there might
         --  need to be some substitution of the new type for the
         --  parent type.
         return True;

      elsif Decl_Tree in Obj_Decl.Tree then
         --  TBD: Not clear that inheriting an Obj_Decl is necessary;
         --       couldn't we just use the one from the parent type,
         --       presuming that a qualified_name/selection would find it?
         return True;  --  TBD: for now

      elsif Decl_Tree in Type_Decl.Tree then
         --  We have a nested type declaration.  If this is
         --  defining a "new" type, we do not want to inherit the decl
         --  presuming that a qualified_name/selection will find it.
         declare
            Type_Decl_Tree : Type_Decl.Tree
              renames Type_Decl.Tree (Decl_Tree);
         begin
            return not Type_Decl_Tree.Is_New_Type
              and then not Type_Def_Has_New_Module
                (Type_Decl_Tree.Type_Definition);
         end;
      else
         --  Decl does not need to be inherited.
         return False;
      end if;
   end Decl_Should_Be_Inherited;

   function Inherit_Decl_List
     (Decl_List : Lists.List;
      Parent_Module, New_Module : Module_Sem_Ptr := null)
      return Lists.List
   is
      --  Copy list of declarations, as part of inheritance.
      --  If Parent_Module and New_Module are specified, then
      --  substitute appearances of the parent module in the
      --  declarations with the new module, as appropriate to the
      --  kind of declaration.
      --  Suppress declarations that are not inherited, such
      --  as nested interface declarations.
      --  TBD: Should nested interfaces be included as well?
      --       If the parent module is parameterized, it would
      --       be convenient to have access to the nested interface
      --       with appropriate substitutions made.
      Result : Lists.List := Lists.Empty_List;
      Saved_Inheritance_Flag : Boolean := False;
   --  Keeps track of whether we are already in the
   --  middle of inheriting declarations.
   begin
      if New_Module /= null then
         --  Remember old state and indicate now doing some inheritance.
         --  This suppresses adding certain types to the nested-type
         --  table.
         Saved_Inheritance_Flag := New_Module.Ancestor_Decls_Being_Inherited;
         New_Module.Ancestor_Decls_Being_Inherited := True;
      end if;

      if Debug_Second_Pass then
         if Lists.Length (Decl_List) > 0 then
            Put_Line ("  Inherit_Decl_List:" &
              Natural'Image (Lists.Length (Decl_List)) &
                " declarations to be (possibly) inherited.");
            if Parent_Module /= null then
               Put_Line ("   (from module " &
                 Sym_Name (Parent_Module.Associated_Symbol) & ")");
            end if;
         end if;
      end if;
      --  Copy each item in decl_list, with substitutions as appropriate
      for I in 1 .. Lists.Length (Decl_List) loop
         declare
            Decl : constant Optional_Tree := Lists.Nth_Element (Decl_List, I);
         begin
            if Parent_Module = null
              or else Decl_Should_Be_Inherited (Decl)
            then
               --  This declaration should be inherited

               --  NOTE: We copy everything but nested modules,
               --      but treat it somewhat like an instantiation of the
               --      parent type, where the parameters of the parent module
               --      are substituted with values specified in the module
               --      extension, and the parent module current instance is
               --      replaced with the new module current instance.
               declare
                  New_Decl : constant Optional_Tree :=
                    Inherit_Decl
                       (Decl,
                        Parent_Module => Parent_Module,
                        New_Module => New_Module);
               begin
                  Lists.Append (Result, New_Decl);
               end;
            else
               if Debug_First_Pass then
                  Put_Line (" NOT Inheriting declaration:");
                  Display_Subtree (Decl, Indent => 3, Use_Short_Form => True);
                  New_Line;
               end if;

            end if;
         end;
      end loop;

      if New_Module /= null then
         --  Restore old state.
         New_Module.Ancestor_Decls_Being_Inherited := Saved_Inheritance_Flag;
      end if;

      --  Return new list
      return Result;
   end Inherit_Decl_List;

   function Find_Prior_Matching_Operation
     (Op_Sem : Operation_Sem_Ptr;
      Orig_Region : Symbols.Region_Ptr;
      Complain_If_Different : Boolean := False)
     return Operation_Sem_Ptr
   --  Find operation with same signature as Op_Sem starting with
   --  Op_Sem.Associated_Symbol, with given Orig_Region
   --  If Complain_If_Different is True, then complain if prior operation
   --  does not have matching type qualifications and parameter names.
   is
      Interface_Op : Symbols.Sym_Ptr :=
        Next_Homonym_In_Region (Op_Sem.Associated_Symbol, Orig_Region);
   begin
      while Interface_Op /= null loop
         exit when Interface_Op.Sem_Info /= null
           and then Interface_Op.Sem_Info.all in Operation_Semantic_Info
           and then Signatures_And_Modes_Match
             (Operation_Sem_Ptr (Interface_Op.Sem_Info), Op_Sem);
         Interface_Op := Next_Homonym_In_Region (Interface_Op, Orig_Region);
      end loop;

      if Interface_Op /= null then
         if Complain_If_Different then
            if not Signatures_And_Modes_Match
               (Operation_Sem_Ptr (Interface_Op.Sem_Info),
                Op_Sem,
                Complain_If_Different => True)
            then
               Sem_Error
                 (Op_Sem.Definition,
                  "Does not match corresponding earlier specification: " &
                  Subtree_Image
                    (Interface_Op.Definition, Use_Short_Form => True));
            end if;
         end if;
         return Operation_Sem_Ptr (Interface_Op.Sem_Info);
      else
         --  No prior operation declaration
         return null;
      end if;
   end Find_Prior_Matching_Operation;

   function Overridden_Operation
     (Decl_Region : Symbols.Region_Ptr;
      Mod_Sem : Module_Sem_Ptr;
      Op_Sem : Operation_Sem_Ptr;
      Scan_Entire_Region : Boolean := False;
      Diagnose : Boolean := False)
    return Operation_Sem_Ptr is
      --  See whether operation overrides an earlier inherited operation.
      --  Return non-null operation-sem-ptr for earlier operation, if any.
      --  Complain if operation overrides an earlier non-inherited op.
      --  If Scan_Entire_Region is True, then start at last symbol of region;
      --  otherwise, start at Op_Sem.Associated_Symbol itself.
      --  If Diagnose is True, then report how operation differs from
      --  some abstract inherited operation.
      Hom : Symbols.Sym_Ptr := null;
   begin
      if Scan_Entire_Region then
         --  Scan entire region
         Hom := Lookup_In_Region
           (Decl_Region, Op_Sem.Associated_Symbol.Str);
      else
         --  Start from Op_Sem itself
         Hom := Next_Homonym_In_Region (Op_Sem.Associated_Symbol,
           Orig_Region => Decl_Region);
      end if;

      while Hom /= null loop
         declare
            Hom_Pos : constant Source_Positions.Source_Position :=
              Hom.Source_Pos;
            Hom_Line : constant Source_Positions.Line_Number :=
              Hom_Pos.Line;
         begin
            if Hom.Kind /= Operation_Sym_Kind then
               if not Decl_Is_For_Component (Hom.Definition) then
                  --  Not allowed to hide non-operation/non-components
                  Sem_Error
                    (Op_Sem.Definition,
                     "Illegal to override non-operation declared " &
                     "on line" &
                     Source_Positions.Line_Number'Image (Hom_Line));
                  return null;
               else
                  --  Ok to overload with a component
                  if Debug_Second_Pass then
                     Put_Line
                       (" Operation " &
                        Subtree_Image
                           (Op_Sem.Definition,
                            Use_Short_Form => True) &
                        " has same name as component of " &
                        Sym_Name (Mod_Sem.Associated_Symbol));
                  end if;
               end if;
            else
               --  We have an operation with the same name, see if
               --  it has the same signature.
               declare
                  Earlier_Op_Sem : constant Operation_Sem_Ptr :=
                    Operation_Sem_Ptr (Hom.Sem_Info);
               begin
                  if Earlier_Op_Sem /= null
                    and then Earlier_Op_Sem.Overridden_By = null
                    and then Signatures_And_Modes_Match
                                (Earlier_Op_Sem,
                                 Op_Sem, Diagnose => Diagnose)
                  then
                     --  We have a match
                     case Earlier_Op_Sem.Context is
                        when Interface_Item_Contexts =>
                           if Earlier_Op_Sem.Context =
                              Op_Sem.Context
                           then
                              Sem_Error
                                (Op_Sem.Definition,
                                 "Has same signature as " &
                                 "operation declared on line" &
                                 Source_Positions.Line_Number'Image
                                    (Hom_Line));

                              --  Go ahead and mark prior op as overridden
                              --  to prevent cascading ambiguity errors.
                              Earlier_Op_Sem.Overridden_By := Op_Sem;
                              return null;
                           else
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" Identical operation " &
                                    Subtree_Image
                                       (Op_Sem.Definition,
                                        Use_Short_Form => True) &
                                    " declared in both normal and " &
                                    " implements part of " &
                                    Sym_Name (Mod_Sem.Associated_Symbol));
                              end if;
                           end if;
                        when Ancestor_Item_Contexts =>
                           if Op_Sem.Context = Interface_Item_Context
                             and then Earlier_Op_Sem.Context =
                                      Ancestor_Item_Context
                           then
                              --  Overrides an earlier "normal" operation
                              return Earlier_Op_Sem;
                           elsif Op_Sem.Context =
                                 Interface_Implements_Item_Context
                             and then Earlier_Op_Sem.Context =
                                      Ancestor_Implements_Item_Context
                           then
                              --  Overrides an earlier "implements"
                              --  operation
                              return Earlier_Op_Sem;
                           elsif Op_Sem.Context = Local_Class_Item_Context then
                              --  Overrides the operation presuming
                              --  type itself is local
                              return Earlier_Op_Sem;
                           else
                              if Debug_Second_Pass then
                                 Put_Line
                                   (" " &
                                    Subtree_Image
                                       (Op_Sem.Definition,
                                        Use_Short_Form => True) &
                                    " Does not override because " &
                                    " one op is 'normal' and other is in " &
                                    " 'implements' part.");
                              end if;
                           end if;
                        when others =>
                           --  Strange, what could this be?
                           Sem_Error
                             (Earlier_Op_Sem.Definition,
                              "Internal: Unexpected context");
                     end case;
                  end if;
               end;
            end if;

            --  Check the next declaration with same name
            Hom := Next_Homonym_In_Region (Hom,
              Orig_Region => Decl_Region);
         end;
      end loop;

      --  No inherited operation was overridden.
      return null;
   end Overridden_Operation;

   function Add_Op_To_Local_Operand_Types
     (Op_Sem : Operation_Sem_Ptr;
      Cur_Inst_Type : Type_Sem_Ptr;
      Context : Context_Enum;
      May_Override : Overriding_State) return Natural
   is
   --  If Op_Sem has any operands of a locally declared type,
   --  copy it to the module of each such type, and then analyze it.
   --  Return count of local operand types found.
   --  If context is not in Any_Interface_Item_Contexts then only
   --  copy operation if it overrides something.
      Op_Tree : Operation.Tree renames
        Operation.Tree (Tree_Ptr_Of (Op_Sem.Definition).all);

      Max_Local_Types : constant Natural :=
        Lists.Length (Op_Tree.Operation_Inputs) +
        Lists.Length (Op_Tree.Operation_Outputs);
      Num_Local_Types_Seen : Natural := 0;
      Local_Types_Seen : array (1 .. Max_Local_Types) of Type_Sem_Ptr;

      function Already_Seen (Opnd_Type : Type_Sem_Ptr) return Boolean is
      --  Return True if Opnd_Type is in Local_Types_Seen.
      begin
         for I in 1 .. Num_Local_Types_Seen loop
            if Opnd_Type.U_Base_Type = Local_Types_Seen (I) then
               --  Already in table
               return True;
            end if;
         end loop;
         --  Not in table yet
         return False;
      end Already_Seen;

      procedure Add_To_Types_From_Param_list (L : Lists.List) is
         --  If type of operand corresponds to a locally-declared type,
         --  then add it to that type's module and analyze it.
      begin
         for I in 1 .. Lists.Length (L) loop
            declare
               Operand_Sem : constant Sem_Ptr :=
                 Sem_Ptr (Sem_Info (Lists.Nth_Element (L, I)));
            begin
               if Operand_Sem /= null
                 and then Operand_Sem.all in Param_Semantic_Info
               then
                  --  We have an "object" parameter
                  declare
                     Resolved_Type : constant Type_Sem_Ptr :=
                       Param_Sem_Ptr (Operand_Sem).Resolved_Type;
                  begin
                     if Resolved_Type /= null
                       and then Resolved_Type.Associated_Module /= null
                       and then Types_Match
                         (Resolved_Type.Enclosing_Type, Cur_Inst_Type)
                       and then Types_Match
                         (Resolved_Type,
                          Resolved_Type.Associated_Module.Cur_Inst_Sem)
                       and then Resolved_Type.Associated_Module.Treat_As_Type
                       and then not Already_Seen (Resolved_Type)
                       and then (Context in Any_Interface_Item_Contexts
                         or else Overridden_Operation
                           (Resolved_Type.Associated_Module.Nested_Region,
                            Resolved_Type.Associated_Module, Op_Sem,
                            Scan_Entire_Region => True) /= null)
                              --  Must override if operation private
                              --  TBD: Require Resolved_Type to be private too
                     then
                        --  A new local type; make copy of operation
                        if Context not in Any_Interface_Item_Contexts
                          and then Resolved_Type.Associated_Module.Context
                            in Any_Interface_Item_Contexts
                        then
                           Sem_Error (Op_Sem.Definition,
                             "Occurs too late to override operation of " &
                             Type_Image (Resolved_Type));
                        end if;

                        if Debug_Second_Pass then
                           Put_Line (" Copying op " &
                             Subtree_Image (Op_Sem.Definition,
                               Use_Short_Form => True) &
                             " into module for local type " &
                             Type_Image (Resolved_Type));
                        end if;
                        declare
                           Copy_Of_Op : constant Optional_Tree :=
                             Inherit_Decl (Op_Sem.Definition);
                           Op_Tree : Operation.Tree renames Operation.Tree
                             (Tree_Ptr_Of (Copy_Of_Op).all);
                           Local_Type_Module : constant Module_Sem_Ptr :=
                             Resolved_Type.Associated_Module;

                           Saved_Current_Module : constant Module_Sem_Ptr :=
                             Current_Module;
                           Local_Type_Module_Tree : Module.Tree renames
                             Module.Tree (Tree_Ptr_Of
                               (Local_Type_Module.Definition).all);
                           Context_To_Pass : Context_Enum := Context;
                        begin
                           if Op_Tree.Is_Def then
                              --  Turn off all of the "def" stuff
                              --  (we will be setting Equiv_To/Equiv_From_Type)
                              Op_Tree.Is_Def := False;
                              Op_Tree.Op_Location := Null_Optional_Tree;
                              Op_Tree.Op_Equiv := Null_Optional_Tree;
                              Op_Tree.Is_Import := False;
                              Op_Tree.Is_Expression_Function := False;
                              Op_Tree.Statements := Null_Optional_Tree;
                           end if;

                           --  Add type to table to avoid dups
                           Num_Local_Types_Seen := Num_Local_Types_Seen + 1;
                           Local_Types_Seen (Num_Local_Types_Seen) :=
                             Resolved_Type.U_Base_Type;

                           --  Add op to type's module and analyze

                           --  Set Current module temporarily
                           Current_Module := Local_Type_Module;

                           --  Add copy of op to proper list
                           case Context is
                              when Interface_Item_Context =>
                                 if May_Override = Must_Not_Override then
                                    --  Followed a "new"
                                    Lists.Append
                                      (Local_Type_Module_Tree.
                                         Module_New_Exports,
                                       Copy_Of_Op);
                                 else
                                    --  Did not follow a "new"
                                    Lists.Append
                                      (Local_Type_Module_Tree.Module_Exports,
                                       Copy_Of_Op);
                                 end if;
                              when Interface_Implements_Item_Context =>
                                 Lists.Append
                                   (Local_Type_Module_Tree.Module_Implements,
                                    Copy_Of_Op);
                              when others =>
                                 --  For a type declared in the body
                                 --  we only import operation if it overrides.
                                 Lists.Append
                                   (Local_Type_Module_Tree.Module_Exports,
                                    Copy_Of_Op);

                                 Context_To_Pass := Interface_Item_Context;
                           end case;

                           --  Analyze copy of operation
                           First_Pass
                             (Local_Type_Module.Nested_Region, Copy_Of_Op,
                              Processing_Inherited_Decl => True);

                           Second_Pass
                             (Local_Type_Module.Nested_Region, Copy_Of_Op,
                              Context => Context_To_Pass,
                              May_Override => May_Override,
                              Mode => Decls_Only);

                           declare
                              New_Op_Sem : constant Operation_Sem_Ptr :=
                                Operation_Sem_Ptr
                                  (Sem_Info (Copy_Of_Op));
                           begin
                              --  Set up equivalence
                              New_Op_Sem.Equiv_To := Op_Sem;
                              New_Op_Sem.Equiv_From_Type := Cur_Inst_Type;

                              --  Set originating_module to be "here"
                              --  since these aren't really "inherited"
                              New_Op_Sem.Originating_Module :=
                                Local_Type_Module;
                              New_Op_Sem.Originating_Operation := New_Op_Sem;
                           end;

                           --  Restore current module
                           Current_Module := Saved_Current_Module;
                        end;

                     end if;
                  end;
               end if;
            end;
         end loop;
      end Add_To_Types_From_Param_List;

   begin  --  Add_Op_To_Local_Operand_Types

      Add_To_Types_From_Param_List (Op_Tree.Operation_Outputs);
      Add_To_Types_From_Param_List (Op_Tree.Operation_Inputs);

      return Num_Local_Types_Seen;

   end Add_Op_To_Local_Operand_Types;

   procedure Analyze_Annotation (T : in out Annotation.Tree) is
      --  Analyze annotation, now that other semantic analysis has been
      --  performed
      Annotation_Sem : constant Annotation_Sem_Ptr :=
        Annotation_Sem_Ptr (T.Sem_Info);
   begin
      if Annotation_Sem /= null
        and then not Annotation_Sem.Annotation_Analyzed
      then
         --  Set the region for visiting the annotations
         declare
            Annotation_Visitor : Sem_Second_Pass_Visitor;
            Saved_Current_Module : constant Module_Sem_Ptr := Current_Module;
         begin
            if Debug_Second_Pass then
               Put_Line (" Resolving annotations: " &
                 Subtree_Image (T));
            end if;

            Annotation_Visitor.Decl_Region := Annotation_Sem.Nested_Region;
            Annotation_Visitor.Decl_For_Annotations :=
              Annotation_Sem.Decl_For_Annotations;

            Current_Module :=    --  Set fall back for Find_Enclosing_Module.
              Find_Enclosing_Module (Annotation_Sem.Nested_Region);

            --  Resolve all annotations to boolean
            --  TBD: Handle nested annotations and
            --      within-annotation declarations.
            for I in 1 .. Lists.Length (T.Annotations) loop
               declare
                  Annotation : Optional_Tree :=
                    Lists.Nth_Element (T.Annotations, I);
               begin
                  if Tree_Ptr_Of (Annotation).all in Trees.Annotation.Tree then
                     --  Nested annotation, doesn't have a type
                     Visit_And_Resolve_Expr
                       (Annotation,
                        Annotation_Visitor);
                  else
                     --  Resolve condition to boolean
                     --  TBD: Handle "ghost" declarations, etc.
                     Visit_And_Resolve_Expr
                       (Annotation,
                        Annotation_Visitor,
                        Resolved_Type => Boolean_Type);
                  end if;
               end;
            end loop;

            --  Remember that we have analyzed this annotation
            Annotation_Sem.Annotation_Analyzed := True;

            --  Restore Find_Enclosing_Module fallback
            Current_Module := Saved_Current_Module;
         end;
      end if;
   end Analyze_Annotation;

   procedure Analyze_Continue_With_Values
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : Control_Stmt.Tree;
      For_Loop_Sem : For_Loop_Construct_Sem_Ptr) is
      --  Analyze T.Values given on "continue loop" statement.

      Num_Values_Needed : constant Natural :=
        Num_Initial_Value_Iterators (For_Loop_Sem);
      --  Number of values that need to be specified
      --  after the "continue loop with "

      Needed_Value_Iter_Index : array (1 .. Num_Values_Needed) of Positive :=
        (others => Positive'Last);

      function Nth_Formal (Needed_Index : Positive) return Optional_Tree is
      --  Return Nth iterator needing a "next" value
      begin
         return For_Loop_Sem.Iterator_Sems
           (Needed_Value_Iter_Index (Needed_Index)).Definition;
      end Nth_Formal;

      function Nth_Default (Needed_Index : Positive) return Optional_Tree is
         --  Return default for Nth iterator
      begin
         --  No defaults in a continue-loop
         return Null_Optional_Tree;
      end Nth_Default;

      function Lookup_Formal_Name
        (Iter_Str : Strings.U_String)
         return Natural
      is
         --  Return "needed-value" index of Name,
         --  or 0 if not an iterator needing a value
         Iter_Sym : Symbols.Sym_Ptr :=
           Symbols.Lookup_In_Region
              (For_Loop_Sem.Loop_Param_Region, Iter_Str);
         use type Symbols.Sym_Ptr;
      begin
         if Iter_Sym = null
           or else Iter_Sym.Sem_Info = null
           or else Iter_Sym.Sem_Info.all not in Iterator_Semantic_Info'Class
         then
            if Debug_Second_Pass then
               Put_Line
                 (" name in continue-loop " &
                  Strings.To_String (Iter_Str) &
                  " does not identify an iterator parameter.");
            end if;
            return 0;  --  Not a name of an iterator parameter
         end if;

         for I in 1 .. Num_Values_Needed loop
            if Iter_Sym.Sem_Info =
              Root_Sem_Ptr (For_Loop_Sem.Iterator_Sems
                (Needed_Value_Iter_Index (I)))
            then
               --  Found needed value
               return I;
            end if;
         end loop;

         if Debug_Second_Pass then
            Put_Line
              (" iterator named in continue-loop " &
               Strings.To_String (Iter_Str) &
               " does not need a next value.");
         end if;

         return 0;  --  Iterator does not need a "next" value

      end Lookup_Formal_Name;

      procedure Canonicalize_Iterators is new Canonicalize_Operand_List (
         Nth_Formal => Nth_Formal,
         Nth_Default => Nth_Default,
         Lookup_Formal_Name => Lookup_Formal_Name);

   begin  --  Analyze_Continue_With_Values

      if Debug_Second_Pass then
         Put_Line
           ("Analyzing " & Subtree_Image (T));
      end if;

      if Is_Null (T.Values) then
         if Num_Values_Needed > 0 then
            Sem_Error
              (T,
               "Must specify ""with <next-value (s)>""");
         end if;
         return;

      elsif Num_Values_Needed = 0 then
         Sem_Error
           (T.Values,
            "No iterators of loop need a next value");
         return;

      end if;

      --  Build up mapping from needed-value index to iterator index
      declare
         Needed_Value_Index : Natural := 0;
      begin
         for I in For_Loop_Sem.Iterator_Sems'Range
         loop
            declare
               Iter_Sem : constant Iterator_Sem_Ptr :=
                 For_Loop_Sem.Iterator_Sems (I);
               Iter_Tree : Iterator.Tree renames
                 Iterator.Tree (Tree_Ptr_Of (Iter_Sem.Definition).all);
               use type Iterator.Iterator_Kind_Enum;
            begin
               if Iter_Tree.Kind = Iterator.Initial_Value then
                  --  This needs a "next" value; remember its iterator index
                  Needed_Value_Index := Needed_Value_Index + 1;
                  Needed_Value_Iter_Index (Needed_Value_Index) := I;
               end if;
            end;
         end loop;
      end;

      declare
         Values_Tree : Trees.Tree'Class renames Tree_Ptr_Of (T.Values).all;
         use Invocation;
         Values_Sem : constant Computation_Sem_Ptr :=
           new Computation_Semantic_Info;

         Ambiguity : Ambiguity_List := null;
         Canonical_Values : Lists.List;
         Resolved_Values : Optional_Tree;
         Resolved_Values_Sem : Computation_Sem_Ptr;
      begin
         Values_Sem.Definition := Optional (Values_Tree'Access);

         if Values_Tree in Invocation.Tree
           and then Invocation.Tree (Values_Tree).Kind = Class_Aggregate
           and then not Is_Parenthesized_Expression
             (Invocation.Tree (Values_Tree))
         then
            --  We have "class aggregate" syntax; analyze it.
            --  TBD: Handle case where single iterator has "class-agg" value.
            declare
               Generic_Param_Map : Param_Mapping_Ptr;
            begin
               --  Generate possible interpretations for values.
               Second_Pass (Visitor.Decl_Region, T.Values,
                 Context => Operand_Context);

               --  Now check against the iterators.
               Canonicalize_Iterators
                 (Num_Formals => Num_Values_Needed,
                  Actual_Construct => Values_Sem.Definition,
                  Actual_Operands => Invocation.Tree (Values_Tree).Operands,
                  Assoc_Type_Region => null,
                  Resolved_Operand_List => Canonical_Values,
                  Generic_Param_Map => Generic_Param_Map,
                  Ambiguity => Ambiguity);

               --  We don't have the notion of "generic" iterators
               pragma Assert (Generic_Param_Map = null);

            end;

         elsif Num_Values_Needed > 1 then
            Sem_Error (T.Values, "Next value must be specified for" &
              Integer'Image (Num_Values_Needed) & " iterators");
         else
            --  We have a single iterator that needs a next value.
            --  Handle "reference" syntax as well as a simple value.
            declare
               Iter_Sem : constant Iterator_Sem_Ptr :=
                 For_Loop_Sem.Iterator_Sems (Needed_Value_Iter_Index (1));
            begin
               if Values_Tree in Reference.Tree then
                  --  Uses "Iter => Next_Value" syntax
                  declare
                     Iter_Ref_Tree : Reference.Tree renames
                       Reference.Tree (Values_Tree);
                     Iter_Key_Tree : Trees.Tree'Class
                       renames Tree_Ptr_Of (Iter_Ref_Tree.Key).all;
                  begin
                     if Iter_Key_Tree not in Identifier.Tree
                       or else Identifier.Tree (Iter_Key_Tree).Str /=
                         Iter_Sem.Associated_Symbol.Str
                     then
                        Sem_Error (Iter_Key_Tree,
                          "Must refer to iterator " &
                            Sym_Name (Iter_Sem.Associated_Symbol));
                     else
                        Visit_And_Resolve_Expr (Iter_Ref_Tree.Referent,
                          Visitor, Iter_Sem.Resolved_Type);

                        --  Append value to list of canonical values
                        Lists.Append
                          (Canonical_Values, Iter_Ref_Tree.Referent);
                     end if;
                  end;
               else
                  --  Uses simply "Next_Value" syntax
                  declare
                     --  Make copy to avoid having value as a component
                     --  of its resolved interpretation.
                     Val_Copy : Optional_Tree :=
                       Copy_Resolved_Tree (T.Values);
                  begin
                     Visit_And_Resolve_Expr (Val_Copy,
                       Visitor, Iter_Sem.Resolved_Type);

                     --  Append to canonical value list
                     Lists.Append (Canonical_Values, Val_Copy);
                  end;
               end if;
            end;
         end if;

         if Lists.Is_Empty (Canonical_Values) then
            Sem_Error (T.Values,
              "Types of values do not match corresponding iterators");
            return;   --  Doesn't resolve
         end if;

         Resolved_Values :=
            Invocation.Make
              (Class_Aggregate,
               Prefix => Null_Optional_Tree,
               Operands => Canonical_Values,
               Source_Pos => Control_Stmt.Find_Source_Pos (T));

         Resolved_Values_Sem := new Computation_Semantic_Info;
         Resolved_Values_Sem.Definition := Resolved_Values;
         Resolved_Values_Sem.Ambiguity := Ambiguity;
         Resolved_Values_Sem.Interps := null;
         Resolved_Values_Sem.Resolved_Type := null;

         Set_Sem_Info (Resolved_Values, Root_Sem_Ptr (Resolved_Values_Sem));

         --  Fill in as resolved interp for values
         Values_Tree.Sem_Info := Root_Sem_Ptr (Values_Sem);
         Values_Sem.Resolved_Interp := Resolved_Values;
         if Debug_Second_Pass then
            Put_Line (" continue loop values resolves to: " &
              Subtree_Image (Resolved_Values));
         end if;
      end;
   end Analyze_Continue_With_Values;

   function Type_Has_Val_Params_Or_Consts (Type_Sem : Type_Sem_Ptr)
     return Boolean is
   --  Return True if (formal) type has value parameters or
   --  visible constants which are *not* compile-time known.
   begin
      if Type_Sem = null or else Type_Sem.Associated_Module = null
        or else Type_Sem.Associated_Module.Nested_Region = null
      then
         --  Must have been a prior error
         return False;
      else
         --  Walk params of associated module
         for I in 1 .. Num_Module_Parameters (Type_Sem.Associated_Module) loop
            declare
               Nth_Param : Trees.Tree'Class renames Tree_Ptr_Of
                 (Nth_Module_Parameter (Type_Sem.Associated_Module, I)).all;
            begin
               if Nth_Param in Param_Decl.Tree then
                  return True;
               end if;
            end;
         end loop;

         --  Check for visible object decls of associated module
         for I in 1 .. Num_Symbols_In_Region
                         (Type_Sem.Associated_Module.Nested_Region)
         loop
            declare
               Next_Sym : constant Sym_Ptr := Nth_Symbol_In_Region
                 (Type_Sem.Associated_Module.Nested_Region, I);
            begin
               if Next_Sym.Kind = Object_Sym_Kind
                 and then Next_Sym.Sem_Info /= null
                 and then Next_Sym.Sem_Info.all in Object_Semantic_Info'Class
               then
                  --  and then Object_Sem_Ptr (Next_Sym.Sem_Info).Context in
                  --    Visible_Interface_Item_Contexts  --  TBD
                  --  We have a visible object  --  TBD: visible
                  --  TBD: Ignore if has compile-time known initial value
                  return True;
               end if;
            end;
         end loop;

         --  No val params or visible constants found
         return False;
      end if;
   end Type_Has_Val_Params_Or_Consts;

   -----------

   procedure Pre_Visit
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Trees.Tree'Class) is
   begin
      Visit (T.Pre_Annotation, Visitor);
   end Pre_Visit;

   procedure Post_Visit
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Trees.Tree'Class) is
   begin
      if Is_Null (Visitor.Decl_For_Annotations)
        and then (T in Type_Decl.Tree
                 or else T in Param_Decl.Tree
                 or else T in Obj_Decl.Tree)
      then
         Visitor.Decl_For_Annotations := Optional (T'Access);
         Visit (T.Post_Annotation, Visitor);
         Visitor.Decl_For_Annotations := Null_Optional_Tree;
      else
         Visit (T.Post_Annotation, Visitor);
      end if;
   end Post_Visit;

   procedure Module_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Module.Tree) is
      Mod_Sem : constant Module_Sem_Ptr := Module_Sem_Ptr (T.Sem_Info);
      Mod_Region : constant Symbols.Region_Ptr := Mod_Sem.Nested_Region;
      Num_Formals : Natural := 0;

      New_Mod : constant Symbols.Sym_Ptr := Mod_Sem.Associated_Symbol;
      Saved_Current_Module : constant Module_Sem_Ptr := Current_Module;
      Parent_Module : constant Module_Sem_Ptr := Mod_Sem.Parent_Module;

      procedure Abstract_Ops_Must_Be_Overridden (Decl_List : Lists.List) is
      --  Make sure that all abstract operations on Decl_List are overridden
      begin
         for I in 1 .. Lists.Length (Decl_List) loop
            declare
               Decl_Tree : Trees.Tree'Class renames
                 Tree_Ptr_Of (Lists.Nth_Element (Decl_List, I)).all;
            begin
               if Decl_Tree in Operation.Tree then
                  declare
                     Op_Decl : Operation.Tree renames
                       Operation.Tree (Decl_Tree);
                     Op_Sem : constant Operation_Sem_Ptr :=
                       Operation_Sem_Ptr (Op_Decl.Sem_Info);
                  begin
                     if Op_Sem /= null and then Op_Sem.Is_Abstract
                       and then Op_Sem.Overridden_By = null
                       and then not Op_Decl.Is_Optional
                     then
                        --  We have a non-overridden abstract operation
                        --  which is not marked "optional."
                        Sem_Error (T.Extends_Interface,
                          "Must override inherited abstract operation " &
                          Subtree_Image (Op_Sem.Definition,
                            Use_Short_Form => True));
                     end if;
                  end;
               end if;
            end;
         end loop;
      end Abstract_Ops_Must_Be_Overridden;

   begin  --  Module_Action

      if Visitor.Mode = Decls_Only and then not T.Is_Interface
        and then not T.Treat_As_Type
      then
         --  "Decls_Only" means don't do module classes.
         return;
      end if;

      Current_Module := Mod_Sem;  --  Fall back for Find_Enclosing_Module.

      if Visitor.Context /= No_Context then
         Mod_Sem.Context := Visitor.Context;
         if not T.Is_Interface and then Mod_Sem.Other_Part /= null
           and then Mod_Sem.Associated_Symbol /= null
         then
            --  Make sure context of class and interface are compatible
            case Mod_Sem.Context is
               when Local_Class_Item_Context =>
                  if Mod_Sem.Other_Part.Context /=
                    Local_Class_Item_Context
                  then
                     Sem_Error (T, "Implementation of module " &
                       Sym_Name (Mod_Sem.Associated_Symbol) &
                       " must be exported if interface is visible");
                     --  Fix it to avoid further complaints
                     Mod_Sem.Context := Exported_Class_Item_Context;
                  end if;
               when Exported_Class_Item_Contexts =>
                  if Mod_Sem.Other_Part.Context not in
                    Visible_Interface_Item_Contexts
                  then
                     Sem_Error (T, "Interface of module " &
                       Sym_Name (Mod_Sem.Associated_Symbol) &
                       " must be visible if implementation is exported");
                  end if;
               when others =>
                  null;
            end case;
         end if;
      end if;

      if Debug_Second_Pass then
         Put_Line
           ("Second pass for module " &
            Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem) &
            "; sym_index =" &
            Sym_Index'Image (New_Mod.Index) &
            "; Mode = " &
            Analysis_Mode'Image (Visitor.Mode));
      end if;

      if Visitor.Mode in Analyze_Decls
        and then not Lists.Is_Empty (T.Import_Clauses)
      then
         --  Make sure import clauses are OK
         Check_Import_Clauses (T.Import_Clauses);
      end if;

      if Visitor.Mode in Analyze_Decls
        and then T.Is_Interface
        and then Parent_Module /= null
      then
         --  Copy (after substitution) Exports and Implements lists
         --  from parent module, as these are inherited.
         --  Also, propagate other information about components
         --  and constructors of ancestors.
         --  NOTE: We delay doing this until the second pass
         --       has been performed on the parent module,
         --       since before then identifiers haven't been resolved.
         --  Sum up inherited components
         Mod_Sem.Num_Visible_Ancestor_Components :=
           Parent_Module.Num_Visible_Components +
           Parent_Module.Num_Visible_Ancestor_Components;

         Mod_Sem.Num_Private_Ancestor_Components :=
           Parent_Module.Num_Private_Components +
           Parent_Module.Num_Private_Ancestor_Components;

         --  Determine new component-extension level
         Mod_Sem.Component_Extension_Level :=
           Parent_Module.Component_Extension_Level;

         if Parent_Module.Num_Constructors > 0
           or else Parent_Module.Num_Private_Components > 0
         then
            --  Components are at next extension level
            Mod_Sem.Component_Extension_Level :=
              Mod_Sem.Component_Extension_Level + 1;
         end if;

         --  If ancestor has a non-abstract constructor
         --  then we must presume it has private components.
         if Parent_Module.Ancestor_Module_With_Constructor /= null
           or else Parent_Module.Num_Constructors > 0
           or else Mod_Sem.Num_Private_Ancestor_Components > 0
         then
            --  New module needs to use parent name in aggregate
            --  since some ancestor might have private components.
            --  Remember nearest ancestor that has a constructor.
            --  TBD: We shouldn't consider something to be a "constructor"
            --       in this context if it has an *input* of the
            --       current instance type, since it might simply
            --       return its input.
            if Parent_Module.Num_Constructors > 0 then
               --  Parent had constructor so it is the new
               --  "ancestor-module with constructor."
               Mod_Sem.Ancestor_Module_With_Constructor := Parent_Module;
            else
               --  Inherit ancestor-module with constructor from parent
               Mod_Sem.Ancestor_Module_With_Constructor :=
                 Parent_Module.Ancestor_Module_With_Constructor;
            end if;

         end if;

         if Mod_Sem.Other_Part /= null then
            --  Propagate info to module class as well.
            --  TBD: Not sure why we bother.

            Mod_Sem.Other_Part.Num_Visible_Ancestor_Components :=
              Mod_Sem.Num_Visible_Ancestor_Components;
            Mod_Sem.Other_Part.Num_Private_Ancestor_Components :=
              Mod_Sem.Num_Private_Ancestor_Components;

            Mod_Sem.Other_Part.Ancestor_Module_With_Constructor :=
              Mod_Sem.Ancestor_Module_With_Constructor;
            Mod_Sem.Other_Part.Component_Extension_Level :=
              Mod_Sem.Component_Extension_Level;
         end if;

         --  Now copy the nested types from the parent
         --  in case any of the parameter types in the inherited
         --  operations are nested types.
         --  NOTE: Additional nested types might be added to the parent if
         --  the
         --       parent module's "class" hasn't been analyzed yet,
         --       but those types wouldn't appear in the inherited
         --       declarations.
         for I in 1 .. Num_Elements (Mod_Sem.Parent_Module.Nested_Types)
         loop
            declare
               J : Type_Sem_Vectors.Elem_Index;
               use type Type_Sem_Vectors.Elem_Index;
            begin
               Add_Element
                 (Mod_Sem.Nested_Types,
                  Nth_Element (Mod_Sem.Parent_Module.Nested_Types, I),
                  J);
               --  Indices should match up
               pragma Assert (J = I);
            end;
         end loop;

         Mod_Sem.Num_Inherited_Nested_Types :=
           Natural (Num_Elements (Mod_Sem.Nested_Types));
         --  Remember how many come from parent.

      end if;  --  If has a parent module

      --  Now walk the formals of the interface
      if T.Is_Interface then
         --  We only walk the formals of the interface.
         --  TBD: We should check for conformance of the formals on the body.
         Second_Pass_List
           (Mod_Region,
            Mod_Sem.Ancestor_Module_Formals,
            Context => Module_Formal_Context,
            Mode => Visitor.Mode);
         Second_Pass_List
           (Mod_Region,
            T.Module_Formals,
            Context => Module_Formal_Context,
            Mode => Visitor.Mode);

         --  Having processed the formals, we can
         --  now walk the list of implemented interfaces.
         --  TBD: We also inherit the "implements_interface" list
         --      from the parent module, if any.
         Second_Pass_List
           (Mod_Region,
            T.Implements_Interfaces,
            Context => Module_Implements_Interfaces_Context,
            Mode => Visitor.Mode);

      end if;

      --  Determine number of formals from Interface
      Num_Formals := Num_Module_Parameters (Mod_Sem);

      if Visitor.Mode in Analyze_Decls
        and then T.Is_Interface
        and then Parent_Module /= null
      then
         --  Need to do the first pass for nested declarations
         --  since we skipped it before, so the parent interface
         --  could complete both its first and second passes.
         declare
            Parent_Module_Tree : Module.Tree
              renames Module.Tree (Tree_Ptr_Of (Parent_Module.Definition).all);

            Ancestor_Parent_Specifier : Optional_Tree :=
              Null_Optional_Tree;
         begin
            --  Do a first pass on the param-decl used to specify
            --  the parent type.
            First_Pass (Mod_Region, T.Extends_Interface);
            Sem_Ptr (Sem_Info (T.Extends_Interface)).Associated_Symbol.Kind :=
              Module_Ancestor_Sym_Kind;
            --  Change the kind so it reflects reality.

            if Mod_Sem.Ancestor_Module_With_Constructor /= null then
               declare
                  Anc : Module_Sem_Ptr := Mod_Sem.Parent_Module;
               begin
                  --  Introduce names for all ancestors up to nearest ancestor
                  --  with a constructor.
                  --  TBD: These are in reverse order of what is probably
                  --      ideal, but hopefully we will complain if the
                  --      names collide.
                  Ancestor_Parent_Specifier := T.Extends_Interface;

                  while Anc /= Mod_Sem.Ancestor_Module_With_Constructor loop
                     pragma Assert
                       (Anc.Component_Extension_Level =
                        Mod_Sem.Component_Extension_Level);
                     --  Extension levels should match

                     Ancestor_Parent_Specifier :=
                        Inherit_Decl
                          (Module.Tree (Tree_Ptr_Of (Anc.Definition).all).
                       Extends_Interface);
                     First_Pass (Mod_Region, Ancestor_Parent_Specifier,
                       Processing_Inherited_Decl => True);
                     --  Change the sym kind
                     Sem_Ptr (Sem_Info (Ancestor_Parent_Specifier)).
                       Associated_Symbol.Kind := Module_Ancestor_Sym_Kind;
                     Anc := Anc.Parent_Module;
                  end loop;
                  --  We found the ancestor with a constructor, so
                  --  we need to mark that as the first aggregate component.
                  Param_Sem_Ptr (Sem_Info (Ancestor_Parent_Specifier)).
                    Component_Index := 1;
                  Mod_Sem.Num_Components_For_Aggregate := 1;
               end;
            end if;

            --  Now do a second pass on the parent type specification.
            Second_Pass
              (Mod_Region,
               T.Extends_Interface,
               Context => Module_Extends_Interface_Context,
               Mode => Visitor.Mode);

            --  Update the parent type
            Mod_Sem.Cur_Inst_Sem.Parent_Type :=
               Resolved_Type (T.Extends_Interface);

            --  Do a second pass on the ancestor with a constructor
            if Not_Null (Ancestor_Parent_Specifier)
              and then Ancestor_Parent_Specifier /= T.Extends_Interface
            then
               Second_Pass
                 (Mod_Region,
                  Ancestor_Parent_Specifier,
                  Context => Module_Extends_Interface_Context,
                  Mode => Visitor.Mode);
            end if;

            --  Fill in the U_Type and U_Base_Type temporarily
            --  (Finish_Type_Sem_Info will re-assign as appropriate).
            Mod_Sem.Cur_Inst_Sem.U_Type := Mod_Sem.Cur_Inst_Sem;
            Mod_Sem.Cur_Inst_Sem.U_Base_Type := Mod_Sem.Cur_Inst_Sem;

            if Num_Formals = 0
               and then
                  (Mod_Sem.Cur_Inst_Sem.Enclosing_Type = null
                 or else
                   Mod_Sem.Cur_Inst_Sem.Enclosing_Type.All_Parameters_Known)
               and then
                  (Mod_Sem.Cur_Inst_Sem.Parent_Type = null
                 or else
                   Mod_Sem.Cur_Inst_Sem.Parent_Type.All_Parameters_Known)
            then
               --  Initialize All_Parameters_Known now in case
               --  cur-inst type is used as a parameter in nested
               --  type instantiations.
               Mod_Sem.Cur_Inst_Sem.All_Parameters_Known := True;
            end if;

            --  Copy the declarations from the ancestors of the parent
            Mod_Sem.Ancestor_Module_Exports :=
               Inherit_Decl_List
                 (Parent_Module.Ancestor_Module_Exports,
                  Parent_Module => Parent_Module,
                  New_Module => Mod_Sem);

            --  Now copy those of the parent itself
            Lists.Append
              (Mod_Sem.Ancestor_Module_Exports,
               Inherit_Decl_List
                  (Parent_Module_Tree.Module_Exports,
                   Parent_Module => Parent_Module,
                   New_Module => Mod_Sem));

            Lists.Append
              (Mod_Sem.Ancestor_Module_Exports,
               Inherit_Decl_List
                  (Parent_Module_Tree.Module_New_Exports,
                   Parent_Module => Parent_Module,
                   New_Module => Mod_Sem));

            --  Now do the same for the "implements-operations" lists
            --  First copy those of the ancestors of the parent
            Mod_Sem.Ancestor_Module_Implements :=
               Inherit_Decl_List
                 (Parent_Module.Ancestor_Module_Implements,
                  Parent_Module => Parent_Module,
                  New_Module => Mod_Sem);

            --  Now copy those of the parent itself
            Lists.Append
              (Mod_Sem.Ancestor_Module_Implements,
               Inherit_Decl_List
                  (Parent_Module_Tree.Module_Implements,
                   Parent_Module => Parent_Module,
                   New_Module => Mod_Sem));

            --  Do the first pass on the inherited declarations
            --  NOTE: These can be overridden
            First_Pass_List (Mod_Region, Mod_Sem.Ancestor_Module_Exports,
              Processing_Inherited_Decl => True);
            First_Pass_List (Mod_Region, Mod_Sem.Ancestor_Module_Implements,
              Processing_Inherited_Decl => True);

            if not Lists.Is_Empty (T.Module_Exports)
              or else not Lists.Is_Empty (T.Module_New_Exports)
              or else not Lists.Is_Empty (T.Module_Implements)
            then
               if Debug_First_Pass then
                  Put_Line
                    ("  First pass for exports for module " &
                     Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem) &
                     ':');
               end if;
               First_Pass_List (Mod_Region, T.Module_Exports,
                 Processing_Inherited_Decl => True);
               First_Pass_List (Mod_Region, T.Module_New_Exports,
                 Processing_Inherited_Decl => True);
               First_Pass_List (Mod_Region, T.Module_Implements,
                 Processing_Inherited_Decl => True);
            end if;

            if Mod_Sem.Other_Part /= null then
               --  Now do the first pass on the module class as well
               declare
                  Module_Class : Module.Tree
                    renames Module.Tree (Tree_Ptr_Of
                      (Mod_Sem.Other_Part.Definition).all);
                  pragma Assert (not Module_Class.Is_Interface);
               begin
                  if not Lists.Is_Empty (Module_Class.Class_Locals) then
                     if Debug_First_Pass then
                        Put_Line
                          ("  First pass for locals for module class " &
                           Sym_Name (New_Mod) &
                           Treat_As_Type_Indicator (Mod_Sem) & ':');
                     end if;
                     First_Pass_List (Mod_Region, Module_Class.Class_Locals);
                  end if;

                  if not Lists.Is_Empty (Module_Class.Module_Exports)
                    or else not Lists.Is_Empty
                                  (Module_Class.Module_New_Exports)
                    or else not Lists.Is_Empty
                                  (Module_Class.Module_Implements)
                  then
                     if Debug_First_Pass then
                        Put_Line
                          ("  First pass for exports for module class " &
                           Sym_Name (New_Mod) &
                           Treat_As_Type_Indicator (Mod_Sem) & ':');
                     end if;
                     First_Pass_List
                       (Mod_Region,
                        Module_Class.Module_Exports);
                     First_Pass_List
                       (Mod_Region,
                        Module_Class.Module_New_Exports);
                     First_Pass_List
                       (Mod_Region,
                        Module_Class.Module_Implements);
                  end if;

                  --  Copy over the total number of components
                  --  usable in an aggregate
                  Mod_Sem.Other_Part.Num_Components_For_Aggregate :=
                    Mod_Sem.Num_Components_For_Aggregate;
               end;
            end if;
         end;
      end if;

      --  Call Num_Components() now to make sure all components counts
      --  are complete.
      if Num_Components (Mod_Sem) /=
         Mod_Sem.Num_Components_For_Aggregate
      then
         Sem_Error
           (T,
            "Internal: Inconsistency in number of components, " &
            "Num_Components () =" &
            Natural'Image (Num_Components (Mod_Sem)) &
            ", Num_Components_For_Aggregate =" &
            Natural'Image (Mod_Sem.Num_Components_For_Aggregate));
      end if;

      if Mod_Sem.Cur_Inst_Sem.U_Base_Type = null
        or else (Visitor.Mode in Analyze_Decls and then Mod_Sem.Is_Interface)
      then
         --  (Re)Initialize U_Base_Type and U_Type (should be Cur_Inst_Sem!)
         --  and assign Nested_Type_Index if appropriate.

         --  Make sure Cur_Inst_Sem properly initialized
         pragma Assert (Mod_Sem.Cur_Inst_Sem.Associated_Module = Mod_Sem);

         --  Now finish the cur-inst sem info
         Finish_Type_Sem_Info
              (Mod_Sem.Cur_Inst_Sem, Mod_Sem.Nested_Region);
      end if;

      if not Lists.Is_Empty (T.Class_Locals) then
         --  Analyze the items preceding the word "exports"

         if not T.Treat_As_Type then
            --  We made certain we were not in "Decls_Only" mode above.
            pragma Assert (Visitor.Mode /= Decls_Only);
            null;
         end if;

         if Debug_Second_Pass then
            Put_Line
              ("  Second pass for Locals for module " &
               Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem) & ':');
         end if;

         --  Allow forward references in Locals part by
         --  first analyzing Decls_Only, and then analyzing
         --  Exprs_Only.
         Second_Pass_List
           (Mod_Region,
            T.Class_Locals,
            Context => Local_Class_Item_Context,
            Mode => Decls_Only);

         if Visitor.Mode /= Decls_Only then
            Second_Pass_List
              (Mod_Region,
               T.Class_Locals,
               Context => Local_Class_Item_Context,
               Mode => Exprs_Only);
         end if;
      end if;

      if not Lists.Is_Empty (T.Module_Exports)
        or else not Lists.Is_Empty (T.Module_New_Exports)
        or else not Lists.Is_Empty (T.Module_Implements)
        or else (T.Is_Interface and then Parent_Module /= null)
      then
         declare
            May_Override : Overriding_State := Unspecified;
         begin
            if not Lists.Is_Empty (T.Module_New_Exports) then
               --  If there are any explicitly "new" operations
               --  then the others *must* override inherited operations.
               May_Override := Must_Override;
            end if;
            if Debug_Second_Pass then
               Put_Line
                 ("  Second pass for Exports for module " &
                  Sym_Name (New_Mod) & Treat_As_Type_Indicator (Mod_Sem) &
                  ", Mode = " &
                  Analysis_Mode'Image (Visitor.Mode) &
                  ':');
            end if;
            if T.Is_Interface then
               --  Walk with Interface*Item_Context,
               --  both the inherited and the explicit declarations
               Second_Pass_List
                 (Mod_Region,
                  Mod_Sem.Ancestor_Module_Exports,
                  Context => Ancestor_Item_Context,
                  Mode => Visitor.Mode);
               Second_Pass_List
                 (Mod_Region,
                  Mod_Sem.Ancestor_Module_Implements,
                  Context => Ancestor_Implements_Item_Context,
                  Mode => Visitor.Mode);

               Second_Pass_List
                 (Mod_Region,
                  T.Module_Exports,
                  Context => Interface_Item_Context,
                  May_Override => May_Override,
                  Mode => Visitor.Mode);
               Second_Pass_List
                 (Mod_Region,
                  T.Module_New_Exports,
                  Context => Interface_Item_Context,
                  May_Override => Must_Not_Override,
                  Mode => Visitor.Mode);
               Second_Pass_List
                 (Mod_Region,
                  T.Module_Implements,
                  Context => Interface_Implements_Item_Context,
                  Mode => Visitor.Mode);

               if Debug_Second_Pass then
                  Put_Line
                    (Interpreter.Operation_Index'Image
                        (Mod_Sem.Num_Interface_Operations) &
                     " interface operations in " &
                     Sym_Name (Mod_Sem.Associated_Symbol));
               end if;

               if Visitor.Mode in Analyze_Decls
                 and then not Mod_Sem.Is_Abstract
                 and then Not_Null (T.Extends_Interface)
                 and then not T.Treat_As_Type
               then
                  --  Now verify that all abstract inherited operations
                  --  have been overridden
                  Abstract_Ops_Must_Be_Overridden
                    (Mod_Sem.Ancestor_Module_Exports);
                  Abstract_Ops_Must_Be_Overridden
                    (Mod_Sem.Ancestor_Module_Implements);
               end if;
            else
               --  Walk the module "class"
               --  We made certain we were not in "Decls_Only" mode above.
               pragma Assert (Visitor.Mode /= Decls_Only);

               Second_Pass_List
                 (Mod_Region,
                  T.Module_Exports,
                  Context => Exported_Class_Item_Context,
                  May_Override => May_Override);
               Second_Pass_List
                 (Mod_Region,
                  T.Module_New_Exports,
                  Context => Exported_Class_Item_Context,
                  May_Override => Must_Not_Override);
               Second_Pass_List
                 (Mod_Region,
                  T.Module_Implements,
                  Context => Class_Implements_Item_Context);

               if Debug_Second_Pass then
                  Put_Line
                    (Interpreter.Operation_Index'Image
                        (Mod_Sem.Num_Interface_Operations) &
                     " interface operations in " &
                     Sym_Name (Mod_Sem.Associated_Symbol) &
                     " after class");
               end if;
            end if;
         end;
      end if;

      if Mod_Sem.Cur_Inst_Sem.Associated_Module = Mod_Sem
        and then not Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small
        and then not Mod_Sem.Cur_Inst_Sem.Known_To_Be_Large
      then
         --  Determine known-to-be-small for "current instance"
         if Mod_Sem.Cur_Inst_Sem /= Mod_Sem.Cur_Inst_Sem.U_Base_Type then
            --  Propagate flag from U_Base_Type
            Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small :=
              Mod_Sem.Cur_Inst_Sem.U_Base_Type.Known_To_Be_Small;
         else
            --  This is a new base type
            declare
               Num_Comps : constant Natural := Num_Components (Mod_Sem);
            begin
               if Num_Comps = 0 then
                  --  No components, treat as small so long as
                  --  not a parameterized module and not concurrent/abstract.
                  Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small :=
                    Known_To_Be_Small (Mod_Sem.Cur_Inst_Sem);
               elsif Num_Comps = 1 and then Module_Is_Wrapper (Mod_Sem) then
                  --  Copy from component type if it is "fully" known
                  --  TBD: This presumes component type has already
                  --      been processed.
                  declare
                     Only_Comp : constant Optional_Tree :=
                       Nth_Component (Mod_Sem, 1);
                     Comp_Type : constant Type_Sem_Ptr :=
                       Object_Sem_Ptr (Sem_Info (Only_Comp)).Resolved_Type;
                  begin
                     if Comp_Type /= null then
                        if Comp_Type.All_Parameters_Known
                          and then Comp_Type.Known_To_Be_Small
                        then
                           --  We know it is a wrapper of a small component
                           Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small := True;
                        end if;
                        if Comp_Type.Known_To_Be_Assignable then
                           --  We know it is a wrapper of a
                           --  known-to-be-assignable component.
                           Mod_Sem.Cur_Inst_Sem.Known_To_Be_Assignable :=
                             True;
                        end if;
                     end if;
                  end;
               end if;
               if Debug_Second_Pass
                 and then Mod_Sem.Cur_Inst_Sem.Known_To_Be_Small
               then
                  Put_Line
                    ("Cur inst type " &
                     Type_Image (Mod_Sem.Cur_Inst_Sem) &
                     " known to be small");
               end if;
            end;
         end if;
      end if;

      for I in 1 .. Lists.Length (T.Module_Formals) loop
         --  Assign Nested_Type_Index to formal types that have
         --  value parameters or nested constants.
         --  NOTE: Inherited parameters have already been handled.
         declare
            New_Param : Trees.Tree'Class renames Tree_Ptr_Of
              (Lists.Nth_Element (T.Module_Formals, I)).all;
         begin
            if New_Param in Type_Decl.Tree then
               --  We have a formal type; assign it a nested_type_index
               --  if it has any value params or constants.
               declare
                  Formal_Type_Sem : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (New_Param.Sem_Info);
               begin
                  if Type_Has_Val_Params_Or_Consts (Formal_Type_Sem) then
                     --  OK, we need a nested type index
                     Add_Element (Mod_Sem.Nested_Types,
                       Formal_Type_Sem.U_Base_Type,
                       Formal_Type_Sem.U_Base_Type.Nested_Type_Index);
                  end if;
               end;
            end if;
         end;
      end loop;

      if Debug_Second_Pass then
         Put_Line ("End of 2nd pass for module " & Sym_Name (New_Mod) &
           Treat_As_Type_Indicator (Mod_Sem));
      end if;

      Current_Module := Saved_Current_Module;
   end Module_Action;

   procedure Implements_Element_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Implements_Element.Tree) is
   begin
      if not Lists.Is_Empty (T.Elements) then
         if Debug_Second_Pass then
            if not Lists.Is_Empty (T.For_Interfaces) then
               Put ("  Second pass for implements section for ");
               for I in 1 .. Lists.Length (T.For_Interfaces) loop
                  if I > 1 then
                     Put (", ");
                  end if;
                  Put
                    (Subtree_Image (Lists.Nth_Element (T.For_Interfaces, I)));
               end loop;
               Put_Line ("; Mode = " & Analysis_Mode'Image (Visitor.Mode));
            else
               Put_Line
                 ("  Second pass for implements-for-all section" &
                  ", Mode = " &
                  Analysis_Mode'Image (Visitor.Mode));
            end if;
         end if;

         --  TBD: Put these in separate sub-regions (at least those with
         --      a non-null For_Interfaces list).
         Second_Pass_List
           (Visitor.Decl_Region,
            T.Elements,
            Context => Visitor.Context,
            Mode => Visitor.Mode);
      end if;
   end Implements_Element_Action;

   procedure Operation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Operation.Tree) is
      Op_Sem : constant Operation_Sem_Ptr := Operation_Sem_Ptr (T.Sem_Info);
      Op_Region : constant Symbols.Region_Ptr := Op_Sem.Nested_Region;

      New_Op : constant Symbols.Sym_Ptr := Op_Sem.Associated_Symbol;
      Mod_Sem : constant Module_Sem_Ptr :=
        Immediately_Enclosing_Module_Interface (Visitor.Decl_Region);
      use type Interpreter.Operation_Index;

      procedure Switch_Implicit_Enclosing_Module is
         --  Switch over to the interface's implicit enclosing
         --  module, while preserving locally declared names
         --  of body parameter list.
         Interface_Op_Sem : constant Operation_Sem_Ptr := Op_Sem.Spec_Sem;
         Interface_Op_Tree : Operation.Tree
           renames Operation.Tree (Tree_Ptr_Of
             (Interface_Op_Sem.Definition).all);

         procedure Fix_Param_List
           (Body_List : Lists.List;
            Spec_List : Lists.List) is
            --  Adjust body's list of parameters (inputs or outputs)
            --  so that references to types or operands hoisted to
            --  the implicit enclosing module refer to the ones visible
            --  to callers (i.e. those of the spec).
            Num_Params : constant Natural := Lists.Length (Body_List);
            pragma Assert (Lists.Length (Spec_List) = Num_Params);
         --  Spec and body should have same number of params
         begin
            for I in 1 .. Num_Params loop
               declare
                  Body_Param_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                                (
                                                            Lists.Nth_Element
                                                              (Body_List,
                                                               I)).all;
                  Spec_Param_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                                (
                                                            Lists.Nth_Element
                                                              (Spec_List,
                                                               I)).all;
               begin
                  if Body_Param_Tree in Param_Decl.Tree then
                     --  Adjust type, etc. to match spec
                     declare
                        pragma Assert (Spec_Param_Tree in Param_Decl.Tree);
                        Body_Param_Decl : Param_Decl.Tree renames
                          Param_Decl.Tree (Body_Param_Tree);
                        Spec_Param_Decl : Param_Decl.Tree renames
                          Param_Decl.Tree (Spec_Param_Tree);
                        Body_Param_Sem : constant Param_Sem_Ptr :=
                          Param_Sem_Ptr (Body_Param_Decl.Sem_Info);
                        Spec_Param_Sem : constant Param_Sem_Ptr :=
                          Param_Sem_Ptr (Spec_Param_Decl.Sem_Info);
                     begin
                        if Body_Param_Decl.Is_Implicit_Module_Param then
                           --  Parameter was enclosed in <> so it
                           --  has been hoisted to implicit enclosing module.
                           --  Change associated symbol to refer to
                           --  param from spec.
                           declare
                              Body_Param_Sym : constant Symbols.Sym_Ptr :=
                                Body_Param_Sem.Associated_Symbol;
                           begin
                              Body_Param_Sym.Sem_Info :=
                                Root_Sem_Ptr (Spec_Param_Sem);
                              Body_Param_Sym.Definition :=
                                Spec_Param_Sem.Definition;
                              Body_Param_Decl.Sem_Info :=
                                Spec_Param_Decl.Sem_Info;
                              --  TBD: Do we need to replace body list element
                              --      with that of spec?
                           end;
                        elsif Tree_Ptr_Of (Body_Param_Decl.Param_Type).all in
                             Type_Decl.Tree
                        then
                           --  Parameter defines its own type.
                           --  Use the one from the spec
                           Body_Param_Decl.Param_Type :=
                             Spec_Param_Decl.Param_Type;
                           Body_Param_Sem.Resolved_Type :=
                             Spec_Param_Sem.Resolved_Type;

                           --  Check if type needs a nested type index
                           if Type_Has_Val_Params_Or_Consts
                                (Spec_Param_Sem.Resolved_Type)
                           then
                              --  OK, we need a nested type index
                              Add_Element (Interface_Op_Sem.
                                  Implicit_Enclosing_Module.Nested_Types,
                                Spec_Param_Sem.Resolved_Type.U_Base_Type,
                                Spec_Param_Sem.Resolved_TYpe.U_Base_Type.
                                  Nested_Type_Index);
                           end if;
                        end if;
                     end;
                  elsif Body_Param_Tree in Operation.Tree then
                     --  TBD: Formal Operation
                     Sem_Error
                       (Body_Param_Tree,
                        "NYI: Formal Operations are not yet supported");
                  end if;
               end;
            end loop;
         end Fix_Param_List;

      begin  --  Switch_Implicit_Enclosing_Module

         --  TBD: Are all of these changes necessary/right?
         Op_Sem.Nested_Region.Enclosing_Region :=
           Interface_Op_Sem.Nested_Region.Enclosing_Region;
         Op_Sem.Implicit_Enclosing_Module.Is_Interface := False;
         Op_Sem.Implicit_Enclosing_Module.Other_Part :=
           Interface_Op_Sem.Implicit_Enclosing_Module;
         Interface_Op_Sem.Implicit_Enclosing_Module.Other_Part :=
           Op_Sem.Implicit_Enclosing_Module;

         --  Copy over implicit enclosing module
         Op_Sem.Implicit_Enclosing_Module :=
           Interface_Op_Sem.Implicit_Enclosing_Module;

         --  Adjust parameter lists to use types defined
         --  in spec's implicit enclosing module.
         Fix_Param_List
           (Body_List => T.Operation_Inputs,
            Spec_List => Interface_Op_Tree.Operation_Inputs);
         Fix_Param_List
           (Body_List => T.Operation_Outputs,
            Spec_List => Interface_Op_Tree.Operation_Outputs);

      end Switch_Implicit_Enclosing_Module;

      function Find_Spec (Expected_Context : Context_Enum)
        return Operation_Sem_Ptr is
      --  Return Operation_Sem for spec, if any.
      --  Check for matching parameter names, etc.

         Spec_Op_Sem : Operation_Sem_Ptr :=
           Find_Prior_Matching_Operation
             (Op_Sem,
              Orig_Region => Visitor.Decl_Region,
              Complain_If_Different => True);
      begin
         if Spec_Op_Sem /= null then
            --  This is the body for some earlier operation
            if Spec_Op_Sem.Context /= Expected_Context
              or else Spec_Op_Sem.Is_Def
              or else not Op_Sem.Is_Def
            then
               Sem_Error (T, "Conflicts with prior declaration: " &
                 Subtree_Image (Spec_Op_Sem.Definition,
                   Use_Short_Form => True));
               Spec_Op_Sem := null;
            else
               Spec_Op_Sem.Body_Region := Op_Sem.Body_Region;
               Op_Sem.Spec_Sem := Spec_Op_Sem;
            end if;
         end if;

         return Spec_Op_Sem;
      end Find_Spec;

      Saved_Current_Module : constant Module_Sem_Ptr := Current_Module;

      Chosen_Assoc_Type_Region : Type_Region_Ptr;

      use type Operation.Operation_Kind_Enum;

   begin  --  Operation_Action

      if Debug_Second_Pass then
         Put_Line
           ("Second pass for operation " &
            Sym_Name (New_Op) &
            "; sym_index =" &
            Sym_Index'Image (New_Op.Index) &
            ", Mode = " &
            Analysis_Mode'Image (Visitor.Mode));

         if Op_Sem.Implicit_Enclosing_Module /= null then
            Put_Line
              (" implicit_enclosing_module = " &
               Sym_Name (Op_Sem.Implicit_Enclosing_Module.Associated_Symbol));
         end if;

      end if;

      if Visitor.Mode in Analyze_Decls
        and then not Lists.Is_Empty (T.Import_Clauses)
      then
         --  Make sure import clauses are OK
         Check_Import_Clauses (T.Import_Clauses);
      end if;

      if Op_Sem.Implicit_Enclosing_Module /= null then
         --  Set Current_Module to reflect implicit enclosing module, if any
         Current_Module := Op_Sem.Implicit_Enclosing_Module;
      end if;

      if Debug_Second_Pass then
         if not Lists.Is_Empty (T.Operation_Inputs) then
            Put_Line ("  Inputs:");
         end if;
      end if;

      if T.Operation_Kind /= Operation.Lambda_Operation then
         --  NOTE: We do the inputs first on this pass, because we want
         --       any "generic" types to be processed before they
         --       are referenced.
         Second_Pass_List
           (Op_Region,
            T.Operation_Inputs,
            Context => Operation_Input_Context,
            Mode => Visitor.Mode);

      end if;

      if Debug_Second_Pass
        and then not Lists.Is_Empty (T.Operation_Outputs)
      then
         Put_Line ("  Outputs:");
      end if;

      --  Always process outputs; lambda operation won't have these
      --  until we have a target type during overload resolution.
      Second_Pass_List
        (Op_Region,
         T.Operation_Outputs,
         Context => Operation_Output_Context,
         Mode => Visitor.Mode);

      if Visitor.Mode not in Analyze_Decls then
         --  Don't worry about context
         null;
      elsif Op_Sem.Operation_Kind = Operation.Lambda_Operation then
         --  Further analysis postponed to Create_Lambda_Expression_Interp
         null;
      elsif Op_Sem.Func_Type_Sem /= null then
         if Visitor.Context = Operation_Input_Context then
            --  Remember context for formal operation of operation
            if Debug_Second_Pass then
               Put_Line
                 (" " & Context_Enum'Image (Visitor.Context) &
                  " for " &
                  Subtree_Image (T, Use_Short_Form => True));
            end if;
            Op_Sem.Context := Visitor.Context;
         else
            --  Fill in a default context
            Op_Sem.Context := Type_Context;
         end if;

         --  Finish the func type sem
         Finish_Type_Sem_Info (Op_Sem.Func_Type_Sem, Visitor.Decl_Region);

      elsif Mod_Sem /= null then
         --  Process an operation immediately declared within a module.
         Op_Sem.Context := Visitor.Context;  --  Remember context of operation
         case Visitor.Context is
            when Ancestor_Item_Contexts =>
               if Debug_Second_Pass then
                  Put_Line
                    (" " & Context_Enum'Image (Visitor.Context) &
                     " context for " &
                     Subtree_Image (T, Use_Short_Form => True));
                  Put_Line
                    ("  Originating_Module is " &
                     Sym_Name (Op_Sem.Originating_Module.Associated_Symbol));
               end if;

               if Op_Sem.Index /= 0 then
                  --  Make sure that Num_Interface_Operations is
                  --  no less than preexisting index.
                  if Op_Sem.Index > Mod_Sem.Num_Interface_Operations then
                     Mod_Sem.Num_Interface_Operations := Op_Sem.Index;
                  end if;

                  --  See whether this inherited op should become abstract
                  --  TBD: Error iff not overridden, unless module is
                  --      abstract or partially abstract due to explicit
                  --      declarations to that effect.
                  if not Op_Sem.Is_Abstract
                    and then (Mod_Sem.Num_Visible_Components +
                              Mod_Sem.Num_Private_Components) > 0
                    and then Op_Sem.Num_Cur_Inst_Outputs > 0
                  then
                     --  We are inheriting an operation with cur-inst outputs
                     --  and there are additional components,
                     --  so mark it as abstract.
                     if Debug_Second_Pass then
                        Put_Line (" Inherited constructor is abstract:");
                        Dump_Subtree (Op_Sem.Definition);
                     end if;
                     Op_Sem.Originating_Operation := null;
                     Op_Sem.Is_Abstract :=
                       (Mod_Sem.Num_Visible_Components > 0);
                     --  TBD: If there are only private components,
                     --      then we don't mark it abstract, but
                     --      will still complain later if it is not
                     --      overridden because we have null-ed out
                     --      the "Originating_Operation" field.
                     --      ** This is not ideal **
                     --      Should instead make a separate pass
                     --      and if it is not overridden, then that
                     --      should be an error, as opposed to simply
                     --      becoming abstract.
                  end if;
               end if;

            --  TBD: Abstract interface should inherit ops as abstract
            --      from "implemented" interfaces as well?
            when Interface_Item_Contexts =>
               --  See whether this operation has any current-instance ops
               declare
                  Overridden_Op : Operation_Sem_Ptr := null;

                  --  See whether operation has any operands of a locally
                  --  declared type, and if so, copy it to each such type's
                  --  module and analyze it.
                  Num_Local_Operand_Types : constant Natural :=
                     Add_Op_To_Local_Operand_Types
                       (Op_Sem, Mod_Sem.Cur_Inst_Sem, Visitor.Context,
                        Visitor.May_Override);
               begin
                  Count_Current_Instance_Operands
                    (Op_Sem, Mod_Sem.Cur_Inst_Sem);

                  if Num_Local_Operand_Types > 0
                    or else Has_Current_Instance_Operand
                              (Op_Sem, Mod_Sem.Cur_Inst_Sem)
                  then
                     --  Scan for preexisting operation with same signature
                     Overridden_Op := Overridden_Operation
                       (Visitor.Decl_Region, Mod_Sem, Op_Sem);

                     if Overridden_Op /= null then
                        --  We have an overriding.  Reuse index
                        --  and set the Overridden_By field.
                        pragma Assert (Overridden_Op.Index /= 0);
                        Op_Sem.Index := Overridden_Op.Index;
                        Overridden_Op.Overridden_By := Op_Sem;

                        if Visitor.May_Override = Must_Not_Override then
                           Sem_Error
                             (T,
                              """new"" operation " &
                              Subtree_Image (T, Use_Short_Form => True) &
                              " overrides operation #" &
                              Interpreter.Operation_Index'Image
                                 (Overridden_Op.Index) &
                              " inherited from module " &
                              Sym_Name
                                 (Overridden_Op.Originating_Module.
                             Associated_Symbol));
                        else
                           if Debug_Second_Pass then
                              Put_Line
                                (" " &
                                 Subtree_Image (T, Use_Short_Form => True) &
                                 " overrides " &
                                 "operation #" &
                                 Interpreter.Operation_Index'Image
                                    (Overridden_Op.Index) &
                                 " of module " &
                                 Sym_Name
                                    (Overridden_Op.Originating_Module.
                                Associated_Symbol));
                           end if;
                        end if;
                     else
                        Mod_Sem.Num_Interface_Operations :=
                          Mod_Sem.Num_Interface_Operations + 1;
                        Op_Sem.Index := Mod_Sem.Num_Interface_Operations;
                        --  Non-zero "Index" implies is an "operation" of the
                        --  module.
                        if Debug_Second_Pass then
                           Put_Line (" Operation " &
                             Subtree_Image (Op_Sem.Definition,
                               Use_Short_Form => True) & " assigned index #" &
                               Interpreter.Operation_Index'Image
                                 (Op_Sem.Index) & " of module " &
                                 Type_Image (Mod_Sem.Cur_Inst_Sem));
                        end if;
                     end if;
                  else
                     if Op_Sem.Is_Abstract then
                        Sem_Error
                          (T,
                           "Abstract operation must have an " &
                           "input or output of the current instance type");
                     end if;
                  end if;

                  if Visitor.May_Override = Must_Override
                    and then Overridden_Op = null
                    and then Num_Local_Operand_Types = 0
                  then
                     --  This operation was supposed to override something
                     Sem_Error
                       (T,
                        "Operation " &
                        Subtree_Image (T, Use_Short_Form => True) &
                        " must override an inherited operation or it should " &
                        "be grouped with the ""new"" operations");

                     --  Call Overridden_Operation again to try to diagnose
                     --  the problem, in case there is a subtle mismatch.
                     Overridden_Op := Overridden_Operation
                       (Visitor.Decl_Region, Mod_Sem, Op_Sem,
                        Diagnose => True);

                  end if;

                  if Op_Sem.Is_Abstract
                    and then not Mod_Sem.Is_Abstract
                    and then not Mod_Sem.Is_Partially_Abstract
                    and then not T.Is_Optional
                  then
                     --  Module was not explicitly abstract, but it is
                     --  partially abstract since it has an abstract
                     --  operation (explicitly) declared within it,
                     --  which is not marked "optional."

                     Mod_Sem.Is_Partially_Abstract := True;
                     if Mod_Sem.Other_Part /= null then
                        Mod_Sem.Other_Part.Is_Partially_Abstract := True;
                     end if;
                     if Debug_Second_Pass then
                        Put_Line
                          (" Module " &
                           Sym_Name (Mod_Sem.Associated_Symbol) &
                           " is partially abstract " &
                           "because has abstract operation");
                     end if;
                     --  NOTE: Partially abstract types can be small.
                     --  TBD: Fully abstract types cannot have instances,
                     --      so it doesn't really matter for them!
                  end if;

               end;
            when Exported_Class_Item_Contexts =>
               --  Check that it matches an item from the interface
               declare
                  Interface_Op_Sem : Operation_Sem_Ptr :=
                    Find_Prior_Matching_Operation
                      (Op_Sem,
                       Orig_Region => Visitor.Decl_Region,
                       Complain_If_Different => True);
               begin
                  if Interface_Op_Sem = null then
                     Sem_Error
                       (T,
                        "Exported item has no corresponding interface item");
                  else
                     --  Copy over index from interface,
                     --  and copy back body_region.
                     --  NOTE: Enclosing region of body_region is region of
                     --       body's parameters, with associated_sym = body
                     --       sym.
                     --       This is a backdoor way to get to the body given
                     --       the "spec" sem-info.  This currently only works
                     --       for operations declared in the interface
                     --       of a module.
                     Op_Sem.Index := Interface_Op_Sem.Index;
                     Interface_Op_Sem.Body_Region := Op_Sem.Body_Region;
                     Op_Sem.Spec_Sem := Interface_Op_Sem;

                     --  Fill in Completion_Of field to point to spec
                     Op_Sem.Associated_Symbol.Completion_Of :=
                       Interface_Op_Sem.Associated_Symbol;

                     if not Signatures_And_Modes_Match
                              (Interface_Op_Sem,
                               Op_Sem,
                               Complain_If_Different => True)
                     then
                        Sem_Error
                          (Op_Sem.Definition,
                           "Does not match corresponding interface item");
                     end if;

                     if Interface_Op_Sem.Is_Abstract then
                        Sem_Error
                          (Op_Sem.Definition,
                           "Corresponding interface item is abstract");
                     end if;

                     if Op_Sem.Implicit_Enclosing_Module /= null then
                        --  Switch over to the interface's implicit
                        --  enclosing
                        --  module.

                        Switch_Implicit_Enclosing_Module;
                     end if;
                  end if;
               end;

            when Local_Class_Item_Context =>
               declare
                  Interface_Op_Sem : Operation_Sem_Ptr :=
                    Find_Spec (Expected_Context => Local_Class_Item_Context);
               begin
                  if Interface_Op_Sem = null then
                     --  This is declaring a new operation;
                     --  handle overrides of ops of locally-declared types
                     declare
                        Num_Local_Operand_Types : constant Natural :=
                           Add_Op_To_Local_Operand_Types
                             (Op_Sem, Mod_Sem.Cur_Inst_Sem, Visitor.Context,
                              May_Override => Must_Override);
                     begin
                        if Debug_Second_Pass then
                           if Num_Local_Operand_Types > 0 then
                              Put_Line (" Operation " &
                                Subtree_Image (T, Use_Short_Form => True) &
                                " overrides operations of" &
                                Natural'Image (Num_Local_Operand_Types) &
                                " type (s)");
                           end if;
                        end if;
                     end;
                  end if;
               end;

            when Statement_Context =>
               --  Context already filled in above
               null;

            when others =>
               --  Context should be filled in
               pragma Assert (False);
               Op_Sem.Context := No_Context;
         end case;
      else
         --  Not inside a module; check for a prior spec
         --  and record the context.
         declare
            Spec_Op_Sem : constant Operation_Sem_Ptr :=
              Find_Spec (Expected_Context => Visitor.Context);
         begin
            if Debug_Second_Pass then
               if Spec_Op_Sem /= null then
                  Put_Line (" Operation " &
                    Subtree_Image (T, Use_Short_Form => True) &
                    " has a prior spec");
               end if;
            end if;
            Op_Sem.Context := Visitor.Context;
         end;
      end if;

      if Not_Null (T.Op_Location) then
         --  Walk location ==> Should be a type
         Second_Pass
           (New_Op.Enclosing_Region,
            T.Op_Location,
            Context => Type_Context);
      end if;

      if T.Operation_Kind = Operation.Lambda_Operation then
         --  Further analysis postponed to Create_Lambda_Expression_Interp
         --  but first change sem info to be a Resolved_Operation_Info
         declare
            Resolved_Op_Sem : constant Resolved_Op_Ptr :=
              new Resolved_Operation_Info;
         begin
            Resolved_Op_Sem.Definition := Op_Sem.Definition;
            Resolved_Op_Sem.Associated_Symbol := Op_Sem.Associated_Symbol;
            Resolved_Op_Sem.Nested_Region := Op_Sem.Nested_Region;
            Resolved_Op_Sem.Op_Sem := Op_Sem;

            Set_Sem_Info (Op_Sem.Definition, Root_Sem_Ptr (Resolved_Op_Sem));
            if Debug_Second_Pass then
               Put_Line ("Setting sem info for lambda expr: " &
                 Subtree_Image (Op_Sem.Definition) & " to resolved_op_info");
            end if;

            --  We only analyze body if operation_outputs is non-empty.
            --  If operation_outputs is empty, then *caller* is responsible
            --  for (eventually) analyzing body.
            if not Lists.Is_Empty (T.Operation_Outputs) then
               if T.Is_Expression_Function then
                  --  Transform "is (X)" into "is return X" if has outputs
                  Insert_Return_And_Analyze (T);
               else
                  --  Walk statements inside body region
                  Second_Pass (Op_Sem.Body_Region, T.Statements,
                    Context => Statement_Context);
               end if;
            end if;
         end;
      elsif Visitor.Mode in Analyze_Exprs
        and then T.Is_Def
        and then not T.Is_Import
      then
         if Not_Null (T.Op_Location) then
            --  User specified type in which to look up name
            --  Create identifier matching current operation,
            --  or Op_Equiv if specified,
            --  and then resolve that.

            --  TBD: We should postpone processing Op_Location until
            --      corresponding module has been processed,
            --      to reduce ordering requirements.
            --      (We can't postpone to after second pass, because
            --      Interps_Equivalent relies on "Equiv_To" information.)
            declare
               function Str_To_Use return  Strings.U_String is
               --  If "is blah in type" specified then return "blah"
               --  else if simply "is in type" then return same identifier
               --  as operation being declared.
               begin
                  if Not_Null (T.Op_Equiv) then
                     --  Get identifier specified
                     if Tree_Ptr_Of (T.Op_Equiv).all
                       not in Identifier.Tree
                     then
                        Sem_Error
                          (T.Op_Equiv,
                           "Must be a simple identifier or operator name");
                        return New_Op.Str;
                     else
                        return
                          Identifier.Tree (Tree_Ptr_Of (T.Op_Equiv).all).Str;
                     end if;
                  else
                     --  Use same identifier as operation being defined.
                     return New_Op.Str;
                  end if;
               end Str_To_Use;

               Equiv_Op : constant Optional_Tree :=
                 Identifier.Make
                    (Str => Str_To_Use,
                     Source_Pos => Find_Source_Pos (T.Op_Location));
               Op_Location_Type : Type_Sem_Ptr;
            begin

               --  Get location type
               Op_Location_Type :=
                  Get_Type (New_Op.Enclosing_Region, T.Op_Location);

               Set_Sem_Info (Equiv_Op, new Sym_Reference_Info);
               Sem_Info (Equiv_Op).Definition := Equiv_Op;

               Add_Type_Region_For_Operation_Name
                 (Equiv_Op,
                  Op_Location_Type);

               --  Now resolve the  operation name
               Resolve_Operation_Name
                 (Equiv_Op,
                  Op_Sem,
                  Chosen_Assoc_Type_Region,
                  Require_Exact_Type_Match => True);

               declare
                  Equiv_Op_Sem : constant Sem_Ptr :=
                    Underlying_Op_Sem_Info (Resolved_Tree (Equiv_Op));
               begin
                  if Equiv_Op_Sem /= null
                    and then Equiv_Op_Sem.all in Operation_Semantic_Info'Class
                  then
                     Op_Sem.Equiv_To := Operation_Sem_Ptr (Equiv_Op_Sem);
                     Op_Sem.Equiv_From_Type := Op_Location_Type;
                     --  TBD: Should this be Chosen_Assoc_Type_Region?
                  end if;
               end;
            end;
         elsif Not_Null (T.Op_Equiv) then
            --  Look up equivalence in enclosing region

            --  Make sure that sem-info starts out empty
            Set_Sem_Info (T.Op_Equiv, null);

            Second_Pass
              (New_Op.Enclosing_Region,
               T.Op_Equiv,
               Context => Op_Context);

            if Mod_Sem /= null then
               --  Include enclosing module's region
               Add_Type_Region_For_Operation_Name
                 (T.Op_Equiv,
                  Mod_Sem.Cur_Inst_Sem);
            end if;

            --  Include regions associated with parameter types,
            --  in case we are renaming an operation from another module.
            Add_Param_Regions_For_Operation_Name
              (T.Op_Equiv, T.Operation_Inputs);

            Add_Param_Regions_For_Operation_Name
              (T.Op_Equiv, T.Operation_Outputs);

            --  Now resolve the Op_Equiv operation name
            Resolve_Operation_Name (T.Op_Equiv, Op_Sem,
              Chosen_Assoc_Type_Region);

            declare
               Equiv_Op_Sem : constant Sem_Ptr :=
                 Underlying_Op_Sem_Info (Resolved_Tree (T.Op_Equiv));
            begin
               if Equiv_Op_Sem /= null
                 and then Equiv_Op_Sem.all in Operation_Semantic_Info'Class
               then
                  Op_Sem.Equiv_To := Operation_Sem_Ptr (Equiv_Op_Sem);
                  if Sem_Info (Resolved_Tree (T.Op_Equiv)).all in
                       Sym_Reference_Info
                    and then Sym_Ref_Ptr (Sem_Info
                                             (Resolved_Tree (T.Op_Equiv))).
                       Prefix_Type_Region /=
                             null
                  then
                     --  Qualified name, get type from prefix
                     Op_Sem.Equiv_From_Type :=
                       Type_Sem_Ptr (
                         Sym_Ref_Ptr (Sem_Info (Resolved_Tree (T.Op_Equiv))).
                           Prefix_Type_Region);
                     --  TBD: Should this be Chosen_Assoc_Type_Region?
                  end if;
               end if;
            end;

         else

            --  We have a "regular" body.
            --  Walk dequeue condition if any.
            if Not_Null (T.Dequeue_Condition) then
               --  Check that there is a queued parameter
               declare
                  Num_Queued_Params : Natural := 0;
               begin
                  for I in 1 .. Lists.Length (T.Operation_Inputs) loop
                     declare
                        Nth_Input : Trees.Tree'Class renames Tree_Ptr_Of
                                                                (
                                                            Lists.Nth_Element
                                                              (T.
                          Operation_Inputs,
                                                               I)).all;
                        use Param_Decl;
                     begin
                        if Nth_Input in Param_Decl.Tree then
                           case Param_Decl.Tree (Nth_Input).Locking is
                              when Not_Locked =>
                                 null;
                              when Locked_Param =>
                                 Sem_Error
                                   (Nth_Input,
                                    "Locked parameters not permitted " &
                                    "when there is a dequeue condition");
                              when Queued_Param =>
                                 Num_Queued_Params := Num_Queued_Params + 1;
                                 if Num_Queued_Params = 2 then
                                    Sem_Error
                                      (Nth_Input,
                                       "NYI: Multiple queued parameters not " &
                                       "yet supported");
                                 end if;
                           end case;
                        end if;
                     end;
                  end loop;
                  if Num_Queued_Params = 0 then
                     Sem_Error
                       (T.Dequeue_Condition,
                        "Dequeue condition requires a queued parameter");
                  end if;

                  declare
                     Dequeue_Visitor : Sem_Second_Pass_Visitor := Visitor;
                  begin
                     Dequeue_Visitor.Decl_Region := Op_Sem.Body_Region;
                     Visit_And_Resolve_Expr
                       (T.Dequeue_Condition, Dequeue_Visitor,
                        Resolved_Type => Boolean_Type);
                  end;
               end;
            end if;

            if T.Is_Expression_Function and then
              not Lists.Is_Empty (T.Operation_Outputs)
            then
               --  Transform "is (X)" into "is return X" if has outputs
               Insert_Return_And_Analyze (T);
            else
               --  Walk statements inside body region
               Second_Pass (Op_Sem.Body_Region, T.Statements,
                 Context => Statement_Context);
            end if;
         end if;
      end if;

      if Debug_Second_Pass then
         Put_Line
           ("End of 2nd pass for operation " &
            Sym_Name (New_Op) &
            "; op_sem.Context = " &
            Context_Enum'Image (Op_Sem.Context) &
            "; op_sem.Index =" &
            Interpreter.Operation_Index'Image (Op_Sem.Index) &
            ", Mode = " &
            Analysis_Mode'Image (Visitor.Mode));
      end if;

      --  Restore Current_Module global
      Current_Module := Saved_Current_Module;

   end Operation_Action;

   procedure Obj_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Obj_Decl.Tree) is
   begin
      if T.Sem_Info /= null then
         declare
            Obj_Sem : constant Object_Sem_Ptr := Object_Sem_Ptr (T.Sem_Info);

            New_Obj : constant Symbols.Sym_Ptr := Obj_Sem.Associated_Symbol;
            Context : constant Context_Enum := Visitor.Context;
         begin
            if Debug_Second_Pass then
               Put_Line
                 ("Second pass for object decl " &
                  Sym_Name (New_Obj) &
                  "; sym_index =" &
                  Sym_Index'Image (New_Obj.Index) &
                  ", Mode = " &
                  Analysis_Mode'Image (Visitor.Mode));
            end if;

            --  Remember context where the object or component was declared.
            Obj_Sem.Context := Context;

            if Obj_Sem.Originating_Module /= null then
               --  This is a component.
               --  Report the context of where the component is declared.
               if Debug_Second_Pass then
                  Put_Line
                    (" Context for component originating in " &
                     Sym_Name (Obj_Sem.Originating_Module.Associated_Symbol) &
                     " is " &
                     Context_Enum'Image (Obj_Sem.Context));
               end if;
            end if;

            Visitor.Decl_For_Annotations := Obj_Sem.Definition;

            if Visitor.Mode in Analyze_Decls then
               --  Analyze the type

               Visitor.Context := Type_Context;
               Visit (T.Obj_Type, Visitor);
               if Not_Null (T.Obj_Type) then
                  Obj_Sem.Resolved_Type :=
                     Get_Type (Visitor.Decl_Region, T.Obj_Type);
               end if;
               if Debug_Second_Pass
                 and then Obj_Sem.Resolved_Type /= null
                 and then Obj_Sem.Resolved_Type.Associated_Module /= null
               then
                  Put_Line
                    ("Second pass for object decl " &
                     Sym_Name (New_Obj) &
                     "; Resolved_Type = " &
                     Type_Image (Obj_Sem.Resolved_Type));
               end if;

            end if;

            if (Is_Null (T.Obj_Type) and then Visitor.Mode in Analyze_Decls)
              or else (Not_Null (T.Obj_Type)
                      and then Visitor.Mode in Analyze_Exprs)
            then
               --  Time to analyze the initial expression

               if Not_Null (T.In_Region) then
                  --  The "for Obj" clause specifies that we want to
                  --  allocate this variable in the same region as Obj.
                  declare
                     Region_Obj_Type : Type_Sem_Ptr;
                  begin
                     Visitor.Context := Operand_Context;
                     Visit (T.In_Region, Visitor);
                     Resolve_Expression
                       (Visitor,
                        T.In_Region,
                        Region_Obj_Type);
                  end;
               end if;

               Visitor.Context := Obj_Decl_Context_Map (T.Is_Ref);
               Visit (T.Obj_Value, Visitor);
               Resolve_Expression
                 (Visitor,
                  T.Obj_Value,
                  Obj_Sem.Resolved_Type);

               if Obj_Sem.Resolved_Type = null then
                  Sem_Error (T.Obj_Value, "Unable to resolve type");
               elsif Obj_Sem.Resolved_Type.Associated_Module /= null then
                  if not T.Is_Ref
                    and then
                       Obj_Sem.Resolved_Type.Associated_Module.
                       Contains_Ref_Component
                  then
                     --  Must be a "ref" if type contains a ref
                     Sem_Error
                       (T,
                        "Must be a ""ref"" because " &
                        Type_Image
                           (Obj_Sem.Resolved_Type,
                            Use_Short_Form => True) &
                        " contains a ref component");
                  end if;

                  if Debug_Second_Pass
                    and then Is_Unlocked_Concurrent_Operand
                                (Operand_Sem_Ptr (Obj_Sem))
                  then
                     Put_Line
                       (" Obj " & Sym_Name (New_Obj) & " is concurrent.");
                  end if;
               end if;
            end if;

            Visitor.Decl_For_Annotations := Null_Optional_Tree;

            --  Restore context
            Visitor.Context := Context;
         end;
      end if;
   end Obj_Decl_Action;

   procedure Param_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Param_Decl.Tree) is
      Param_Sem : Param_Semantic_Info
        renames Param_Semantic_Info (T.Sem_Info.all);

      New_Param : constant Symbols.Sym_Ptr := Param_Sem.Associated_Symbol;
      Context : constant Context_Enum := Visitor.Context;
   begin
      if Debug_Second_Pass then
         Put_Line
           ("Second pass for parameter " &
            Sym_Name (New_Param) &
            "; sym_index =" &
            Sym_Index'Image (New_Param.Index) &
            "; context = " &
            Context_Enum'Image (Context) &
            "; Mode = " &
            Analysis_Mode'Image (Visitor.Mode));
      end if;
      Visitor.Decl_For_Annotations := Param_Sem.Definition;

      --  Remember context where parameter was declared
      Param_Sem.Context := Context;

      --  Second pass for parameter
      if Visitor.Mode in Analyze_Decls then
         Visitor.Context := Type_Context;
         Visit (T.Param_Type, Visitor);

         Param_Sem.Resolved_Type :=
            Get_Type (Visitor.Decl_Region, T.Param_Type,
              Value_Is_Optional => T.Is_Optional,
              Context => Context);

         if Context = Operation_Output_Context then
            Param_Sem.Is_Operation_Output := True;
            if Param_Sem.Resolved_Type /= null
              and then not Param_Sem.Resolved_Type.Value_Is_Optional
            then
               --  Check to see whether enclosing operation is "optional"
               --  without being defined by an expression or a rename,
               --  because if so, all output types must similarly be "optional"
               declare
                  Enclosing_Operation : constant Operation_Sem_Ptr :=
                    Find_Enclosing_Operation (Visitor.Decl_Region);
               begin
                  --  Check whether operation is marked "optional."
                  if Not_Null (Enclosing_Operation.Definition)
                    and then Tree_Ptr_Of (Enclosing_Operation.Definition).all
                      in Operation.Tree
                    and then Operation.Tree
                      (Tree_Ptr_Of (Enclosing_Operation.Definition).all).
                        Is_Optional
                    and then not Operation.Tree
                      (Tree_Ptr_Of (Enclosing_Operation.Definition).all).
                        Is_Def
                  then
                     Sem_Error (T, "Output must be optional" &
                                   " because operation " &
                                   Sym_Name
                                     (Enclosing_Operation.Associated_Symbol) &
                                   " is optional.");
                  end if;
               end;
            end if;
         end if;

         if Debug_Second_Pass then
            if Param_Sem.Resolved_Type /= null
              and then Param_Sem.Resolved_Type.Associated_Module /= null
            then
               Put_Line
                 ("Second pass for parameter " &
                  Sym_Name (New_Param) &
                  "; Resolved_Type = " &
                  Type_Image (Param_Sem.Resolved_Type));
            else
               Put_Line
                 (" parameter type " &
                  Subtree_Image (T.Param_Type) &
                  " not resolved for " &
                  Sym_Name (New_Param));
            end if;
         end if;

         --  NOTE: We resolve the parameter default, if any, now as we
         --        are analyzing decls, rather than waiting until
         --        analyzing exprs, so enclosing operation declaration
         --        can be inherited if necessary, with appropriate
         --        substitutions.
         if Not_Null (T.Param_Default) then
            Visitor.Context := Operand_Context;
            Visit (T.Param_Default, Visitor);

            Resolve_Expression
              (Visitor,
               T.Param_Default,
               Param_Sem.Resolved_Type);
         end if;

      end if;

      Visitor.Decl_For_Annotations := Null_Optional_Tree;
      Visitor.Context := Context;

   end Param_Decl_Action;

   procedure Type_Decl_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Type_Decl.Tree) is
      Type_Sem : Type_Semantic_Info
        renames Type_Semantic_Info (T.Sem_Info.all);

      New_Type : constant Symbols.Sym_Ptr := Type_Sem.Associated_Symbol;
      Context : Context_Enum := Visitor.Context;
      Orig_Prefix : constant Optional_Tree := Visitor.Formal_Prefix;
      Orig_Decl_For_Annotations : constant Optional_Tree :=
        Visitor.Decl_For_Annotations;
      Associated_Generic_Op : Sym_Ptr := null;
   --  Enclosing operation, if this type-decl is nested within
   --  an operation parameter part.
   begin
      if Visitor.Mode = Exprs_Only then
         --  Nothing to do
         return;      ---------------
      end if;

      if T.Is_New_Type and then Type_Sem.Parent_Type /= null then
         --  Nothing to do, type already defined, this is probably a re-scan
         return;
      end if;

      if Debug_Second_Pass then
         Put_Line
           ("Second pass for Type decl " &
            Sym_Name (New_Type) &
            "; sym_index =" &
            Sym_Index'Image (New_Type.Index) &
            ", Mode = " &
            Analysis_Mode'Image (Visitor.Mode));
      end if;

      if Visitor.Decl_Region.Kind = Operation_Param_Region_Kind then
         --  This is an operation parameter of a "generic type"
         Context := Module_Formal_Context;
         Associated_Generic_Op := Visitor.Decl_Region.Associated_Symbol;
         if Debug_Second_Pass then
            Put_Line
              ("Type_Decl " &
               Subtree_Image (T) &
               " has associated generic op " &
               Subtree_Image
                  (Associated_Generic_Op.Definition,
                   Use_Short_Form => True));
         end if;
      end if;

      --  Remember context of declaration (may be overridden below)
      Type_Sem.Context := Context;

      Visitor.Decl_For_Annotations := Type_Sem.Definition;

      --  Analyze the invocation
      if Context = Module_Formal_Context then
         --  Indicate we are defining a formal type
         Visitor.Context := Module_Formal_Type_Def_Context;
         Visitor.Formal_Prefix :=
            Identifier.Make
              (Str => New_Type.Str,
               Source_Pos => New_Type.Source_Pos);

         --  Set up sym-reference info of formal prefix to refer to new type
         Set_Sem_Info
           (Visitor.Formal_Prefix,
            new Sym_Reference_Info'(Root_Semantic_Info with
                                    Associated_Symbol => New_Type,
                                    Nested_Region => null,
                                    Context => Context,
                                    Interps => null,
                                    Resolved_Type => null,
                                    Resolved_Interp => Null_Optional_Tree,
                                    Hash_Value => 0,
                                    Target_Polymorphic_Type => null,
                                    Reported_As_Undefined => False,
                                    Prefix_Type_Region => null,
                                    Underlying_Sem_Info =>
                                      Sem_Ptr (T.Sem_Info)));

      elsif Context = Module_Actual_Of_Formal_Context then
         --  no change in Visitor context
         null;
      else
         --  Indicate we are defining an "actual" type
         Visitor.Context := Type_Context;
      end if;

      if Visitor.Context /= Type_Context
        and then Tree_Ptr_Of (T.Type_Definition).all not in Invocation.Tree
      then
         --  Create an implicit invocation
         T.Type_Definition := Invocation.Make
           (Kind => Invocation.Module_Instantiation,
            Prefix => T.Type_Definition,
            Operands => Lists.Empty_List,
            Source_Pos => Find_Source_Pos (T.Type_Definition));
      end if;

      Visit (T.Type_Definition, Visitor);

      declare
         Def_Sem : constant Type_Sem_Ptr :=
           Get_Type (Visitor.Decl_Region, T.Type_Definition);
         use type Symbols.Sym_Ptr;
      begin
         if Def_Sem /= null then
            --  Include info from definition
            pragma Assert
              (Associated_Generic_Op = null
              or else Def_Sem.Associated_Generic_Op /= Associated_Generic_Op);
            --  We don't allow a generic type inside another one for
            --  the same operation.

            if not T.Is_New_Type
              or else Type_Sem.Parent_Type = null
              or else Type_Sem.Parent_Type.U_Base_Type /= Def_Sem.U_Base_Type
            then
               Type_Sem :=
                 (Root_Semantic_Info (Type_Sem) with
                  Associated_Symbol => Type_Sem.Associated_Symbol,
                  Nested_Region => Def_Sem.Nested_Region,
                  Context => Context,
                  Type_Index => Type_Sem.Type_Index,
                  New_Type_Counter => Def_Sem.New_Type_Counter,
                  Associated_Module => Def_Sem.Associated_Module,
                  Func_Type_Op_Sem => Def_Sem.Func_Type_Op_Sem,
                  Enclosing_Type => Def_Sem.Enclosing_Type,
                  Parent_Type => Def_Sem.Parent_Type,
                  Ancestor_Type_With_Constructor =>
                    Def_Sem.Ancestor_Type_With_Constructor,
                  Constraint_Annotations => Def_Sem.Constraint_Annotations,
                  Value_Is_Optional => Def_Sem.Value_Is_Optional or
                                       Type_Sem.Value_Is_Optional,
                  Obj_Is_Concurrent => Def_Sem.Obj_Is_Concurrent or
                                       Type_Sem.Obj_Is_Concurrent,
                  Is_Polymorphic => Def_Sem.Is_Polymorphic or
                                    Type_Sem.Is_Polymorphic,
                  Is_Universal => Def_Sem.Is_Universal,
                  Known_To_Be_Assignable => Def_Sem.Known_To_Be_Assignable,
                  Known_To_Be_Small => Def_Sem.Known_To_Be_Small
                    and then Context /= Module_Formal_Context,
               --  Formal types are never known to be small
                  Known_To_Be_Large => Def_Sem.Known_To_Be_Large,
                  All_Parameters_Known => Def_Sem.All_Parameters_Known
                                         and then Context /=
                                                  Module_Formal_Context,
                  Outermost_Module_Where_Used =>
                    Def_Sem.Outermost_Module_Where_Used,
                  Is_Formal_Type => Def_Sem.Is_Formal_Type
                    or else Context = Module_Formal_Context,  --  see below
                  Actual_Sem_Infos => Def_Sem.Actual_Sem_Infos,
                  Formal_Prefix => Def_Sem.Formal_Prefix,
                  Associated_Generic_Op => Associated_Generic_Op,
                  Actual_Of_Formal_Index => Def_Sem.Actual_Of_Formal_Index,
                  Nested_Type_Index => Def_Sem.Nested_Type_Index,
                  Op_Maps_Needed => Empty_Hash_Table,
                  Type_Descriptor_Location => Def_Sem.Type_Descriptor_Location,
                  Full_View => Type_Sem.Full_View,
                  External_View => Type_Sem.External_View,
                  U_Base_Type => Def_Sem.U_Base_Type,
                  U_Type => Def_Sem.U_Type,
                  U_Base_Structure => Def_Sem.U_Base_Structure);

               if T.Is_New_Type
                 and then not Type_Def_Has_New_Module (T.Type_Definition)
               then
                  --  Is a new type, so does *not* inherit Is_Formal_Type
                  --  indication.
                  Type_Sem.Is_Formal_Type := Context = Module_Formal_Context
                    or else Context = Module_Formal_Type_Def_Context
                    or else Context = Module_Actual_Of_Formal_Context;
                  --  TBD: Also set Actual_Of_Formal_Index to zero?

                  if Def_Sem.All_Parameters_Known then
                     --  Re-initialize outermost-module-where-used
                     --  since this is a "new" type and might have
                     --  additional operations dependent on the current
                     --  module.
                     Type_Sem.Outermost_Module_Where_Used :=
                       Find_Enclosing_Module_Interface (Visitor.Decl_Region);
                  end if;
               elsif Context /= Module_Formal_Context then
                  --  Not a new type, inherits full/external view
                  Type_Sem.Full_View := Def_Sem.Full_View;
                  Type_Sem.External_View := Def_Sem.External_View;
               end if;
            end if;

            if Type_Sem.U_Base_Type /= null
              and then Type_Sem.U_Base_Type.Is_Formal_Type
              and then Type_Sem.U_Base_Type.Associated_Symbol = null
            then
               --  Copy Associated symbol and
               --  associated generic op back onto underlying type
               Type_Sem.U_Base_Type.Associated_Symbol :=
                 Type_Sem.Associated_Symbol;
               Type_Sem.U_Base_Type.Associated_Generic_Op :=
                 Associated_Generic_Op;
            end if;

            if not T.Is_New_Type
              or else Type_Def_Has_New_Module (T.Type_Definition)
              or else Type_Sem.Is_Formal_Type
            then
               --  Everything comes from Def_Sem
               pragma Assert
                 (Type_Sem.Is_Formal_Type = Def_Sem.Is_Formal_Type);

               null;

            elsif Type_Sem.Associated_Module /= null
              and then
                  (Type_Sem.Parent_Type = null
                or else
                   Type_Sem.Parent_Type.U_Base_Type /= Def_Sem.U_Base_Type)
            then
               --  "new" was specified, and we haven't already got
               --  correct parent type.
               Type_Sem.Associated_Module.New_Type_Count :=
                 Type_Sem.Associated_Module.New_Type_Count + 1;
               Type_Sem.New_Type_Counter :=
                 Type_Sem.Associated_Module.New_Type_Count;

               --  Treat the underlying type definition as a "parent" type
               Type_Sem.Parent_Type := Def_Sem;

               --  Treat the cur-inst of enclosing module as the enclosing type
               Type_Sem.Enclosing_Type :=
                 Enclosing_Module_Cur_Inst (Visitor.Decl_Region);

               if Type_Sem.Enclosing_Type /= null
                 and then not Type_Sem.Enclosing_Type.All_Parameters_Known
               then
                  --  Not all known if enclosing type not all known.
                  Type_Sem.All_Parameters_Known := False;
               end if;

               if Type_Sem.New_Type_Counter > 1
                 or else Languages.Language /= Languages.Sparkel
               then
                  --  No longer consider the type a "universal" type
                  --  (unless it is the "first" new type and this is Sparkel).
                  Type_Sem.Is_Universal := False;
               end if;

               --  Recompute the U_Base_Type and U_Type
               --  (but preserve U_Base_Structure).
               Type_Sem.U_Base_Type := null;
               Type_Sem.U_Type := null;
               Finish_Type_Sem_Info
                 (Type_Sem_Ptr (T.Sem_Info), Visitor.Decl_Region);
            else
               --  Parent type not yet fully defined
               Sem_Error (T.Type_Definition, "Parent type of " &
                 Sym_Name (Type_Sem.Associated_Symbol) &
                 " must be declared first.");
            end if;
         end if;
      end;

      --  Restore visitor info
      Visitor.Context := Context;
      Visitor.Formal_Prefix := Orig_Prefix;
      Visitor.Decl_For_Annotations := Orig_Decl_For_Annotations;

   end Type_Decl_Action;

   procedure Qualifier_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Qualifier.Tree) is
      --  This is currently only used for Is_Polymorphic, Is_Optional,
      --  and Is_Concurrent.
      use Qualifier;
   begin
      Visit (T.Operand, Visitor);
      if T.Qualifiers (Is_Polymorphic) or
         T.Qualifiers (Is_Optional) or
         T.Qualifiers (Is_Concurrent)
      then
         --  Worth creating a new type.
         declare
            Original_Type : constant Type_Sem_Ptr :=
              Get_Type (Visitor.Decl_Region, T.Operand);
            Qualified_Type : constant Type_Sem_Ptr :=
              Qualify_Type (Original_Type, Visitor.Decl_Region,
                Definition => Optional (T'Access),
                Is_Optional => T.Qualifiers (Is_Optional),
                Is_Polymorphic => T.Qualifiers (Is_Polymorphic),
                Is_Concurrent => T.Qualifiers (Is_Concurrent));
         begin
            T.Sem_Info := Root_Sem_Ptr (Qualified_Type);
         end;
      else
         --  Just carry Sem info forward
         T.Sem_Info := Sem_Info (T.Operand);
      end if;
   end Qualifier_Action;

   procedure Unary_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Unary.Tree) is
      use Unary;
      Context : constant Context_Enum := Visitor.Context;
   begin
      case T.Operator is
         when Plus_Op | Minus_Op | Not_Op | Abs_Op |
           Meaning_Op | Magnitude_Op =>
            --  Create equivalent invocation and analyze that
            declare
               Op_Name : constant Strings.U_String :=
                 Unary_Operator_Designator (T.Operator);
               Op_Tree : constant Optional_Tree :=
                 Identifier.Make (Op_Name, Find_Source_Pos (T));
               Equiv_Invocation : Optional_Tree :=
                 Invocation.Make
                    (Kind => Invocation.Operation_Call,
                     Prefix => Op_Tree,
                     Operands => Lists.Make ((1 => T.Operand)),
                     Source_Pos => T.Source_Pos);
            begin
               --  Carry over annotations
               Annotation.Add_Annotations (Equiv_Invocation, From => T);

               --  Pass the buck to a visit of the equiv invocation
               Visit (Equiv_Invocation, Visitor);
               T.Sem_Info := Sem_Info (Equiv_Invocation);
            end;

         when Is_Null_Op | Not_Null_Op =>
            --  These are built in, resolve to Any -> Boolean
            declare
               Comp_Sem : constant Computation_Sem_Ptr :=
                 new Computation_Semantic_Info;
            begin
               Comp_Sem.Definition := Optional (T'Access);

               T.Sem_Info := Root_Sem_Ptr (Comp_Sem);

               --  Resolve to Any => Boolean.
               Visitor.Context := Operand_Context;
               Visit_And_Resolve_Expr (T.Operand, Visitor);

               Comp_Sem.Resolved_Type := Boolean_Type;
               Comp_Sem.Resolved_Interp := Comp_Sem.Definition;

            end;

         when Updated_Value_Op =>
            --  This is built in, resolve to Any -> same
            declare
               Comp_Sem : constant Computation_Sem_Ptr :=
                 new Computation_Semantic_Info;
            begin
               Comp_Sem.Definition := Optional (T'Access);

               T.Sem_Info := Root_Sem_Ptr (Comp_Sem);

               --  Resolve to Any => Any.
               Visitor.Context := Operand_Context;
               Visit_And_Resolve_Expr (T.Operand, Visitor);

               Comp_Sem.Resolved_Type := Resolved_Type (T.Operand);

               Comp_Sem.Resolved_Interp := Comp_Sem.Definition;

            end;

         when Initial_Value_Op =>
            --  This is built in <...> operator used for map-reduce exprs;
            --  if operand is universal, we need "to_univ" call *inside* <...>
            declare
               Comp_Sem : constant Computation_Sem_Ptr :=
                 new Computation_Semantic_Info;
            begin
               Comp_Sem.Definition := Optional (T'Access);

               T.Sem_Info := Root_Sem_Ptr (Comp_Sem);

               --  Visit the operand
               Visitor.Context := Operand_Context;
               Visit (T.Operand, Visitor);

               --  Create corresponding interps of initial-value op
               Create_Initial_Value_Operand_Interps (T);
            end;
      end case;

      --  Restore context
      Visitor.Context := Context;
   end Unary_Action;

   procedure Binary_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Binary.Tree) is
      use Binary;
      Context : constant Context_Enum := Visitor.Context;
      Op_Name : Strings.U_String := Binary_Operator_Designator (T.Operator);
   begin

      case T.Operator is

         when Stmt_Ops =>
            if T.Operator = Parallel_Stmt_Op then
               --  Use new regions for operands
               declare
                  Comp_Sem : constant Computation_Sem_Ptr :=
                    Computation_Sem_Ptr (T.Sem_Info);
                  use type Symbols.Region_Ptr;
               begin
                  Visitor.Context := Statement_Context;
                  if Comp_Sem.Nested_Region.Next_Sibling_Region /= null then
                     --  We have a new region for the Left operand
                     Visitor.Decl_Region :=
                       Comp_Sem.Nested_Region.Next_Sibling_Region;
                  end if;
                  Visit_And_Resolve_Stmt (T.Left_Operand, Visitor);

                  Visitor.Context := Statement_Context;
                  Visitor.Decl_Region := Comp_Sem.Nested_Region;
                  Visit_And_Resolve_Stmt (T.Right_Operand, Visitor);

                  --  Restore region
                  Visitor.Decl_Region :=
                    Comp_Sem.Nested_Region.Enclosing_Region;
               end;
            else
               --  Not in parallel
               T.Sem_Info := new Computation_Semantic_Info;
               Computation_Sem_Ptr (T.Sem_Info).Definition :=
                  Optional (T'Access);

               Visitor.Context := Statement_Context;
               Visit_And_Resolve_Stmt (T.Left_Operand, Visitor);

               Visitor.Context := Statement_Context;
               Visit_And_Resolve_Stmt (T.Right_Operand, Visitor);
            end if;

            --  Restore context
            Visitor.Context := Context;

            return; ---- all done ----

         when Relational_Ops =>
            --  Turn into call on "to_bool"("=?"(X, Y), Mask)
            Op_Name := Compare_Op_Str;

         when In_Op | Not_In_Op =>
            --  These are converted into uses of the "=?" operator
            --  if the RHS is either an interval
            --  or a use of the "|" operator.
            --  TBD, for now we just let it resolve...

            if T.Operator = Not_In_Op then
               --  Turn into call on "not"("in"(X, Y))
               Op_Name := Binary_Operator_Designator (In_Op);
            end if;

         when Short_Circuit_Ops =>
            --  These are built in.
            declare
               Comp_Sem : constant Computation_Sem_Ptr :=
                 new Computation_Semantic_Info;
            begin
               Comp_Sem.Definition := Optional (T'Access);

               T.Sem_Info := Root_Sem_Ptr (Comp_Sem);

               --  Resolve to Boolean,Boolean => Boolean.
               Visitor.Context := Operand_Context;
               Visit_And_Resolve_Expr
                 (T.Left_Operand,
                  Visitor,
                  Resolved_Type => Boolean_Type);

               Visitor.Context := Operand_Context;
               Visit_And_Resolve_Expr
                 (T.Right_Operand,
                  Visitor,
                  Resolved_Type => Boolean_Type);

               Comp_Sem.Resolved_Type := Boolean_Type;
               Comp_Sem.Resolved_Interp := Comp_Sem.Definition;

               --  Restore context
               Visitor.Context := Context;

               return; ---- all done ----
            end;

         when others =>
            --  Fall through
            null;
      end case;

      --  Restore context
      Visitor.Context := Context;

      --  Create equivalent invocation and analyze that
      declare
         Op_Tree : constant Optional_Tree :=
           Identifier.Make (Op_Name, Binary.Find_Source_Pos (T));
         Equiv_Invocation : Optional_Tree :=
           Invocation.Make
              (Kind => Invocation.Operation_Call,
               Prefix => Op_Tree,
               Operands => Lists.Make ((T.Left_Operand, T.Right_Operand)),
               Source_Pos => T.Source_Pos);
      begin
         --  Add additional call on top, if appropriate
         case T.Operator is
            when Relational_Ops =>
               --  Now add the "to_bool" part
               Equiv_Invocation :=
                  Invocation.Make
                    (Kind => Invocation.Operation_Call,
                     Prefix =>
                        Identifier.Make
                          (To_Bool_Str,
                           Binary.Find_Source_Pos (T)),
                     Operands =>
                        Lists.Make
                          ((Equiv_Invocation,
                            Identifier.Make
                               (Cond_Mask_Str (T.Operator),
                                Binary.Find_Source_Pos (T)))));

            when Not_In_Op =>
               --  Now add the "not"
               Equiv_Invocation :=
                  Invocation.Make
                    (Kind => Invocation.Operation_Call,
                     Prefix =>
                        Identifier.Make
                          (Unary.Unary_Operator_Designator (Unary.Not_Op),
                           Binary.Find_Source_Pos (T)),
                     Operands => Lists.Make ((1 => Equiv_Invocation)));

            when others =>
               --  Equiv_Invocation is all set
               null;
         end case;

         --  Carry over annotations
         Annotation.Add_Annotations (Equiv_Invocation, From => T);

         --  Pass the buck to a visit of the equiv invocation
         Visit (Equiv_Invocation, Visitor);
         T.Sem_Info := Sem_Info (Equiv_Invocation);

         --  Remember the original binary operator
         Call_Sem_Ptr (T.Sem_Info).Original_Binary_Operator := T.Operator;
      end;

   end Binary_Action;

   procedure Annotation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Annotation.Tree) is
   begin
      if Visitor.Mode in Analyze_Exprs then
         --  Only process annotations when analyzing expressions
         declare
            Annotation_Sem : constant Annotation_Sem_Ptr :=
              new Annotation_Semantic_Info;
            Enclosing_Decl : constant Optional_Tree :=
              Visitor.Decl_For_Annotations;
            Needs_Local_Region : constant Boolean :=
              Not_Null (Enclosing_Decl)
             and then Tree_Ptr_Of (Enclosing_Decl).all in Type_Decl.Tree'Class;
         --  We need to create a nested region if this is an annotation
         --  inside a type declaration, for the "current instance"
         begin
            if Debug_Second_Pass then
               Put_Line (" Creating annotation sem for: " &
                 Subtree_Image (T));
            end if;

            Annotation_Sem.Definition := Optional (T'Access);
            Annotation_Sem.Decl_For_Annotations :=
              Visitor.Decl_For_Annotations;
            T.Sem_Info := Root_Sem_Ptr (Annotation_Sem);

            --  Determine region for use when (later) visiting annotations
            if not Needs_Local_Region then
               --  Use enclosing region
               Annotation_Sem.Nested_Region := Visitor.Decl_Region;
            else
               --  Create nested region to hold
               --  current instance of type.
               declare
                  Enclosing_Decl_Sem : constant Type_Sem_Ptr :=
                    Type_Sem_Ptr (Sem_Info (Enclosing_Decl));
               begin
                  --  Add the list of annotations to the type
                  --  NOTE: We use Append in case we do this in more
                  --       than one place inside the type decl.
                  Lists.Append
                    (Enclosing_Decl_Sem.Constraint_Annotations,
                     T.Annotations);

                  if Enclosing_Decl_Sem.Nested_Region /= null then
                     --  Nested region already created for enclosing type.
                     Annotation_Sem.Nested_Region :=
                       Enclosing_Decl_Sem.Nested_Region;
                  else
                     --  Create a nested region with current object
                     declare
                        Region_For_Annotation : constant Symbols.Region_Ptr :=
                          new Symbols.Region (Type_Annotation_Region_Kind);
                        Current_Obj_Sem : constant Object_Sem_Ptr :=
                          new Object_Semantic_Info;
                        Current_Obj_Sym : constant Symbols.Sym_Ptr :=
                          new Symbols.Symbol'
                          (Kind => Object_Sym_Kind,
                           Str => Enclosing_Decl_Sem.Associated_Symbol.Str,
                           Full_Name => Strings.Null_U_String,
                           Source_Pos =>
                             Enclosing_Decl_Sem.Associated_Symbol.Source_Pos,
                           Enclosing_Region => Region_For_Annotation,
                           Nested_Region => null,
                           Sem_Info => Root_Sem_Ptr (Current_Obj_Sem),
                           Definition => Enclosing_Decl_Sem.Definition,
                           Completion_Of => null,
                           Index => No_Sym_Index,
                           Next_Homonym => No_Sym_Index,
                           Import_Clauses => Lists.Empty_List);
                     begin
                        Current_Obj_Sem.Definition :=
                          Current_Obj_Sym.Definition;
                        Current_Obj_Sem.Associated_Symbol := Current_Obj_Sym;
                        Current_Obj_Sem.Resolved_Type := Enclosing_Decl_Sem;

                        Region_For_Annotation.Enclosing_Region :=
                          Visitor.Decl_Region;
                        Region_For_Annotation.Associated_Symbol :=
                          Enclosing_Decl_Sem.Associated_Symbol;

                        Add_To_Region
                          (Region_For_Annotation,
                           Current_Obj_Sym);

                        Annotation_Sem.Nested_Region := Region_For_Annotation;

                        Enclosing_Decl_Sem.Nested_Region :=
                          Annotation_Sem.Nested_Region;
                     end;
                  end if;

               end;
            end if;

            --  Postpone analysis of annotations until after finishing entire
            --  interface second pass.  Do on Pre_CG pass.
         end;
      end if;

   end Annotation_Action;

   procedure Identifier_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Identifier.Tree) is
   begin
      if T.Sem_Info = null then
         --  Only analyze identifier if has no pre-existing Sem_Info.
         --  This means that after Inherit_Decl creates a copy of
         --  a declaration, we don't re-lookup identifiers.
         --  (Ditto for module_instantiations, by the way.)
         Set_Identifier_Sem_Info
           (Visitor.Decl_Region,
            Visitor.Context,
            T,
            Prefix => Null_Optional_Tree,
            Prefix_Type => null);
         T.Sem_Info.Definition := Optional (T'Access);
      end if;

   end Identifier_Action;

   procedure Qualified_Name_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Qualified_Name.Tree) is
      Context : constant Context_Enum := Visitor.Context;
   begin
      if T.Sem_Info = null then
         --  First time through
         --  Visit the prefix, and then pass the buck
         --  to a routine shared with Identifier_Action.
         Visitor.Context := Type_Context;
         Visit (T.Prefix, Visitor);
         declare
            Prefix_Type : constant Type_Sem_Ptr :=
              Get_Type (Visitor.Decl_Region, T.Prefix);
            Id_Tree : Identifier.Tree renames Identifier.Tree (Tree_Ptr_Of
                                                                  (T.Id).all);
         begin
            Set_Identifier_Sem_Info
              (Visitor.Decl_Region,
               Context,
               Id_Tree,
               Prefix => T.Prefix,
               Prefix_Type => Prefix_Type);

            T.Sem_Info := Id_Tree.Sem_Info;
            T.Sem_Info.Definition := Optional (T'Access);
         end;

         --  Restore context
         Visitor.Context := Context;
      end if;
   end Qualified_Name_Action;

   procedure Assign_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Assign_Stmt.Tree) is
      use Assign_Stmt;

      Context : constant Context_Enum := Visitor.Context;
   begin
      case T.Assign_Operator is
         when Plus_Assign_Op        |
              Minus_Assign_Op       |
              Times_Assign_Op       |
              Divide_Assign_Op      |
              Power_Assign_Op       |
              Combine_Assign_Op     |
              Ampersand_Assign_Op   |
              And_Assign_Op         |
              Or_Assign_Op          |
              Xor_Assign_Op         |
              Left_Shift_Assign_Op  |
              Right_Shift_Assign_Op |
              Combine_Move_Op       =>
            --  These can be user-defined
            declare
               Op_Name : constant Strings.U_String :=
                 Assign_Operator_Designator (T.Assign_Operator);
               Op_Tree : constant Optional_Tree :=
                 Identifier.Make (Op_Name, Assign_Stmt.Find_Source_Pos (T));
               Equiv_Invocation : Optional_Tree :=
                 Invocation.Make
                    (Kind => Invocation.Operation_Call,
                     Prefix => Op_Tree,
                     Operands => Lists.Make ((T.LHS, T.RHS)),
                     Source_Pos => T.Source_Pos);
            begin
               --  Carry over annotations
               Annotation.Add_Annotations (Equiv_Invocation, From => T);

               --  Pass the buck to a visit of the equiv invocation
               Visit (Equiv_Invocation, Visitor);
               T.Sem_Info := Sem_Info (Equiv_Invocation);
            end;

         when Assign_Op | Swap_Op | Move_Op =>
            --  These are built in
            --  TBD: Allow these to be user-defined for a "ref" type.
            declare
               Assign_Sem : constant Computation_Sem_Ptr :=
                 new Computation_Semantic_Info;
            begin
               T.Sem_Info := Root_Sem_Ptr (Assign_Sem);

               Assign_Sem.Definition := Optional (T'Access);

               if Context in Agg_Contexts
                 and then T.Assign_Operator = Move_Op
               then
                  --  Special case, where "<==" is used like a "=>",
                  --  in an aggregate.
                  Visit (T.RHS, Visitor);
               else
                  --  Normal case of a stand-alone statement
                  if T.Assign_Operator = Swap_Op then
                     --  Element must already exist
                     Visitor.Context := Ref_Operand_Context;
                  else
                     --  Element need not exist yet
                     Visitor.Context := Mutable_Context;
                  end if;

                  Visit_And_Resolve_Expr (T.LHS, Visitor, Call_Ref => True);

                  Visitor.Context := Operand_Context;
                  if Sem_Info (T.LHS) /= null then
                     --  Use LHS type to resolve RHS
                     Visit_And_Resolve_Expr
                       (T.RHS,
                        Visitor,
                        Resolved_Type (Resolved_Tree (T.LHS)));
                     if Operand_Sem_Ptr (Sem_Info (T.RHS)).Resolved_Type =
                        null
                     then
                        Sem_Error (T.RHS, "Cannot resolve type");
                     end if;
                  else
                     --  Some prior semantic error
                     Visit_And_Resolve_Expr (T.RHS, Visitor);
                  end if;
               end if;

            end;
      end case;

      --  Restore context
      Visitor.Context := Context;
   end Assign_Stmt_Action;

   procedure Invocation_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Invocation.Tree) is
      use Invocation;
      Context : constant Context_Enum := Visitor.Context;

      --  Context to use for class aggregate, depending on whether
      --  incoming context is "Exit_With_Values_Context"
      Class_Agg_Context_Map : constant array (Boolean) of Context_Enum :=
        (False => Class_Agg_Context, True => Exit_With_Values_Context);

      --  This is true if "." is used for selecting from modules/types as well
      Include_Type_Prefixes : constant Boolean :=
        Languages.Language_Uses_Selection_For_Modules;

      type Indexing_Or_Slicing_Enum is (Var_Indexing, Indexing, Slicing);
      --  Enumeration of three possible interpretations of A[E]

      Op_Names : constant
        array (Indexing_Or_Slicing_Enum) of Strings.U_String :=
        (Var_Indexing => Var_Indexing_Op_Str,
         Indexing     => Indexing_Op_Str,
         Slicing      => Slicing_Op_Str);

   begin
      if Debug_Second_Pass then
         Put_Line ("Second pass for invocation " & Subtree_Image (T));
      end if;
      if T.Sem_Info /= null then
         --  Already analyzed (probably inside Evaluate_Tree)
         if Debug_Second_Pass then
            Put_Line (" (already analyzed)");
         end if;
         return;
      end if;

      case T.Kind is
         when Operation_Call =>
            --  Lookup operation name
            declare
               Op_Tree : Trees.Tree'Class renames Tree_Ptr_Of (T.Prefix).all;
               Prefix_Sem : Root_Sem_Ptr := null;
            begin
               if Op_Tree in Selection.Tree then
                  --  See whether can treat as Obj.Op(...),
                  --  which is equivalent to Op(Obj, ...)
                  declare
                     Obj_Op : Selection.Tree renames
                       Selection.Tree (Op_Tree);
                     Equiv_Invocation : Optional_Tree :=
                       Invocation.Make
                          (Kind => Operation_Call,
                           Prefix => Substitute_In_Tree
                             (Obj_Op.Selector,
                              Assoc_Type_Region => null,
                              Always_Copy_Tree => True),
                           Operands =>
                              Lists.Prepend
                                (Element => Substitute_In_Tree
                                   (Obj_Op.Prefix,
                                    Assoc_Type_Region => null,
                                    Always_Copy_Tree => True),
                                 Tail => T.Operands),
                           Source_Pos => T.Source_Pos);
                  --  TBD: Operation name should be prefixed
                  --       with type of object.
                     Invocation_Sem : Call_Sem_Ptr;
                  begin
                     --  Carry over annotations
                     Annotation.Add_Annotations
                       (Equiv_Invocation, From => T);

                     --  Pass the buck to a visit of the equiv invocation
                     Visit (Equiv_Invocation, Visitor);

                     Invocation_Sem :=
                       Call_Sem_Ptr (Sem_Info (Equiv_Invocation));

                     if not Include_Type_Prefixes
                       or else (Invocation_Sem /= null
                         and then Interpretations.Has_Interp
                           (Invocation_Sem.Interps))
                     then
                        --  It is worth considering as Obj.Op(...)
                        T.Sem_Info := Root_Sem_Ptr (Invocation_Sem);
                     end if;
                  end;

               end if;

               if Op_Tree not in Selection.Tree
                 or else T.Sem_Info = null
               then
                  --  No interpretation as Obj.Op(...)

                  Visitor.Context := Op_Context;
                  Visit (T.Prefix, Visitor);
                  Prefix_Sem := Sem_Info (T.Prefix);

                  --  In many cases, we won't know where to look
                  --  until we know the types of the parameters
                  --  or the result type expected.

                  Second_Pass_List
                    (Visitor.Decl_Region,
                     T.Operands,
                     Context => Call_Operand_Context);

                  --  Iterate through the operands and do a lookup
                  --  in each of their associated type's regions.
                  for I in 1 .. Lists.Length (T.Operands) loop
                     declare
                        Operand : constant Optional_Tree :=
                          Lists.Nth_Element (T.Operands, I);
                        Opnd_Sem : Sem_Ptr := Sem_Ptr (Sem_Info (Operand));

                        procedure Add_One_Type_Region_From_Operand
                          (Assoc_Type_Region : Type_Region_Ptr;
                           Interp : Optional_Tree) is
                           --  Add region to interp-tree for operation
                           Interp_Type : constant Type_Sem_Ptr :=
                             Resolved_Type (Interp);
                        begin
                           if Interp_Type /= null
                             and then
                               (Context /= Mutable_Context
                                or else Sem_Info_Is_For_Variable
                                  (Underlying_Sem_Info (Interp)))
                           then
                              --  If Context = Mutable_Context, then
                              --  only take operation types from variables.
                              if Debug_Second_Pass then
                                 Put_Line
                                   ("  Possibly adding operation interp for " &
                                    Subtree_Image (T.Prefix) &
                                    " from " &
                                    Subtree_Image (Operand) &
                                    " of type " &
                                    Type_Image (Interp_Type));
                              end if;

                              Add_Type_Region_For_Operation_Name
                                (T.Prefix,
                                 Interp_Type,
                                 Operation_Filter =>
                                    Make_Operand_Info
                                      (Operand,
                                       I,
                                       Is_Output_Operand => False));
                           else
                              if Debug_Second_Pass then
                                 Put_Line
                                   ("Not adding operation interp for " &
                                    Subtree_Image (T.Prefix) &
                                    " from " &
                                    Subtree_Image (Operand));
                              end if;
                           end if;
                        end Add_One_Type_Region_From_Operand;

                        procedure Add_Type_Regions_From_Operand is new
                          Interpretations.Iterate_Interps (
                           Add_One_Type_Region_From_Operand);
                     begin
                        if Opnd_Sem /= null
                          and then Opnd_Sem.all in Operand_Semantic_Info'Class
                        then
                           if Not_Null
                                (Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp)
                           then
                              --  There is a single resolved interpretation
                              Add_One_Type_Region_From_Operand
                                (Assoc_Type_Region => null,
                                 Interp =>
                                   Operand_Sem_Ptr (Opnd_Sem).Resolved_Interp);
                           else
                              --  Walk tree of interps of operand and get types
                              Add_Type_Regions_From_Operand
                                (Operand_Sem_Ptr (Opnd_Sem).Interps);
                           end if;
                        end if;
                     end;
                  end loop;

                  --  Generate interpretation tree for invocation
                  Create_Call_Interps (Optional (T'Access));

               end if;
            end;

         when Container_Indexing =>
            --  Create equivalent invocation and analyze that
            if Lists.Length (T.Operands) = 1
              and then Is_Default_Indicator
                          (Lists.Nth_Element (T.Operands, 1))
            then
               --  We have X[..] which is considered equivalent
               --  to "slicing"(X)
               declare
                  Op_Tree : constant Optional_Tree :=
                    Identifier.Make
                       (Slicing_Op_Str,
                        Invocation.Find_Source_Pos (T));
                  Equiv_Invocation : Optional_Tree :=
                    Invocation.Make
                       (Kind => Invocation.Operation_Call,
                        Prefix => Op_Tree,
                        Operands => Lists.Make ((1 => T.Prefix)));
                  use type Interpretations.Interp_Tree;
               begin
                  --  Pass the buck to a visit of the equiv invocation
                  Visit (Equiv_Invocation, Visitor);
                  T.Sem_Info := Sem_Info (Equiv_Invocation);
               end;
            else
               for B in Indexing_Or_Slicing_Enum loop
                  --  Try "var_indexing", "indexing", and "slicing" if
                  --  Context in Var_Indexing_Contexts.  Otherwise try only
                  --  "indexing" and "slicing".
                  --  NOTE: We try "var_indexing" only if
                  --       Context in Var_Indexing_Contexts
                  if B /= Var_Indexing
                    or else Context in Var_Indexing_Contexts
                  then
                     declare
                        --  TBD: Should not use "var_indexing" if
                        --       inside a concurrent loop, and container is
                        --       declared outside the concurrent loop,
                        --       unless is (unlocked) concurrent container.
                        Op_Tree : constant Optional_Tree :=
                          Identifier.Make
                             (Op_Names (B),
                              Invocation.Find_Source_Pos (T));
                        --  TBD: Operation name should be prefixed with
                        --      type of prefix
                        Equiv_Invocation : Optional_Tree :=
                          Invocation.Make
                             (Kind => Invocation.Operation_Call,
                              Prefix => Op_Tree,
                              Operands =>
                                 Lists.Prepend
                                   (Element => T.Prefix,
                                    Tail => T.Operands));

                        Equiv_Invoc_Sem : Call_Sem_Ptr;

                        use type Interpretations.Interp_Tree;
                     begin
                        --  Pass the buck to a visit of the equiv invocation
                        if B = Var_Indexing then
                           --  If now processing "var_indexing"
                           --  set flag to fail if operand is not a variable
                           Visitor.Context := Mutable_Context;
                        end if;
                        Visit (Equiv_Invocation, Visitor);
                        Equiv_Invoc_Sem :=
                          Call_Sem_Ptr (Sem_Info (Equiv_Invocation));

                        if T.Sem_Info /= null then
                           --  We might already have interps; combine them
                           Interpretations.Add_Interp_Tree
                             (Call_Sem_Ptr (T.Sem_Info).Interps,
                              Equiv_Invoc_Sem.Interps);
                        else
                           T.Sem_Info := Root_Sem_Ptr (Equiv_Invoc_Sem);
                        end if;

                        --  Quit if at least one interpretation,
                        --  except for "Call" operands, try both
                        --  "var_indexing" and "indexing"
                        exit when Interpretations.Has_Interp
                                (Call_Sem_Ptr (T.Sem_Info).Interps)
                          and then (B /= Var_Indexing
                            or else Context /= Call_Operand_Context);

                        if B = Var_Indexing then
                           --  Now revert to "normal" context for processing
                           --  "indexing" operation
                           Visitor.Context := Operand_Context;
                        end if;
                     end;
                  end if;
               end loop;
            end if;

         when Class_Aggregate =>
            Visitor.Context := Type_Context;
            Visit (T.Prefix, Visitor);
            Second_Pass_List
              (Visitor.Decl_Region,
               T.Operands,
               Context => Class_Agg_Context_Map
                 (Context = Exit_With_Values_Context));

            if Is_Parenthesized_Expression (T) then
               declare
                  Expr : constant Optional_Tree :=
                    Lists.Nth_Element (T.Operands, 1);
               begin
                  if Not_Null (T.Prefix) then
                     --  Use prefix type to resolve parenthesized expression
                     declare
                        Expr_Type : Type_Sem_Ptr :=
                          Get_Type (Visitor.Decl_Region, T.Prefix);
                     begin
                        if Expr_Type /= null then
                           Resolve_Expression (Visitor, Expr, Expr_Type);
                        end if;
                     end;
                  end if;
                  T.Sem_Info := Sem_Info (Expr);
               end;
            else
               --  Not just simple parentheses
               --  Create class-agg semantics info
               declare
                  Agg_Sem : constant Class_Agg_Sem_Ptr :=
                    new Class_Aggregate_Semantic_Info;
               begin
                  if Debug_Second_Pass then
                     Put_Line (" Class aggregate bottom-up pass done");
                  end if;
                  Agg_Sem.Definition := Optional (T'Access);
                  T.Sem_Info := Root_Sem_Ptr (Agg_Sem);
                  if Not_Null (T.Prefix) then
                     declare
                        Agg_Type : constant Type_Sem_Ptr :=
                          Get_Type (Visitor.Decl_Region, T.Prefix);
                     begin
                        if Agg_Type /= null then
                           Create_Class_Agg_Interp (Agg_Sem, Agg_Type);
                        end if;
                     end;
                     --  else further resolution done by Add_Targeted_Interps
                  end if;
               end;
            end if;

         when Container_Aggregate | Map_Set_Aggregate =>
            if Lists.Is_Empty (T.Operands) then
               --  Simple "[]"
               declare
                  Op_Name : constant Strings.U_String :=
                    Empty_Op_Strs (T.Kind);
                  Op_Tree : constant Optional_Tree :=
                    Identifier.Make
                       (Op_Name,
                        Invocation.Find_Source_Pos (T));
                  Equiv_Invocation : Optional_Tree :=
                    Invocation.Make
                       (Kind => Invocation.Operation_Call,
                        Prefix => Combine_Names (T.Prefix, Op_Tree),
                        Operands => Lists.Empty_List);
               begin
                  --  Pass the buck to a visit of the equiv invocation
                  Visit (Equiv_Invocation, Visitor);
                  T.Sem_Info := Sem_Info (Equiv_Invocation);
               end;
            elsif Lists.Length (T.Operands) = 1
              and then Is_Default_Indicator
                          (Lists.Nth_Element (T.Operands, 1))
            then
               --  Simple "[..]" which represents a universal set/container
               declare
                  Op_Name : constant Strings.U_String :=
                    Univ_Op_Strs (T.Kind);
                  Op_Tree : constant Optional_Tree :=
                    Identifier.Make
                       (Op_Name,
                        Invocation.Find_Source_Pos (T));
                  Equiv_Invocation : Optional_Tree :=
                    Invocation.Make
                       (Kind => Invocation.Operation_Call,
                        Prefix => Combine_Names (T.Prefix, Op_Tree),
                        Operands => Lists.Empty_List);
               begin
                  --  Pass the buck to a visit of the equiv invocation
                  if Debug_Second_Pass then
                     Put_Line (" Invocation of " &
                       Strings.To_String (Op_Name) & " operator");
                  end if;
                  Visit (Equiv_Invocation, Visitor);
                  T.Sem_Info := Sem_Info (Equiv_Invocation);
               end;
            else
               --  Create a container aggregate sem info
               declare
                  Agg_Sem : constant Container_Agg_Sem_Ptr :=
                    new Container_Aggregate_Semantic_Info;
               begin
                  Agg_Sem.Definition := Optional (T'Access);
                  Agg_Sem.Aggregate_Kind := T.Kind;
                  T.Sem_Info := Root_Sem_Ptr (Agg_Sem);
                  --  Walk the prefix and operands
                  Visitor.Context := Type_Context;
                  Visit (T.Prefix, Visitor);
                  Second_Pass_List
                    (Visitor.Decl_Region,
                     T.Operands,
                     Context => Container_Agg_Context);
                  if Debug_Second_Pass then
                     Put_Line (" Container aggregate bottom-up pass done");
                  end if;

                  if Not_Null (T.Prefix) then
                     --  Use prefix to resolve container agg
                     declare
                        Agg_Type : constant Type_Sem_Ptr :=
                          Get_Type (Visitor.Decl_Region, T.Prefix);
                     begin
                        if Agg_Type /= null then
                           Create_Container_Agg_Interp
                             (Agg_Sem, Agg_Type);
                        end if;
                     end;
                     --  else further resolution handled by
                     --  Add_Targeted_Interps
                  end if;
               end;
            end if;

         when Module_Instantiation =>
            --  Lookup module name
            Visitor.Context := Module_Context;
            Visit (T.Prefix, Visitor);
            declare
               Prefix_Sem : constant Sem_Ptr :=
                 Sem_Ptr (Sem_Info (T.Prefix));
               Module_Sym : constant Sym_Ptr := Prefix_Sem.Associated_Symbol;
               Is_Formal_Type : constant Boolean :=
                 Context = Module_Formal_Context
                or else Context = Module_Formal_Type_Def_Context
                or else Context = Module_Actual_Of_Formal_Context;

               Associated_Generic_Op : Sym_Ptr := null;
            --  Indicates that this type is a "generic" type,
            --  because it contains a type-decl somewhere within it.

               Enclosing_Construct_Is_Abstract : constant Boolean :=
                 Inside_Abstract_Construct (Visitor.Decl_Region);

            begin

               if Not_Null (T.Extends) then
                  Sem_Error
                    (T.Extends,
                     "NYI: Specifying base for extension when instantiating");
                  Visitor.Context := Type_Context;
                  Visit (T.Extends, Visitor);
               end if;

               if Module_Sym = null then
                  --  TBD: Error already reported?
                  null;
               elsif Module_Sym.Kind /= Module_Sym_Kind then
                  --  TBD: Keep looking for a module name
                  Sem_Error
                    (T.Prefix,
                     Subtree_Image (T.Prefix) & " is not a module");
               else
                  --  Initialize type sem info
                  declare
                     Module_Sem : constant Module_Sem_Ptr :=
                       Interface_Part (Module_Sem_Ptr (Module_Sym.Sem_Info));
                     Module_Tree : Module.Tree
                       renames Module.Tree (Tree_Ptr_Of
                          (Module_Sem.Definition).all);
                     Num_Formals : constant Natural :=
                       Num_Module_Parameters (Module_Sem);
                     Actual_Sem_Infos : constant Sem_Info_Array_Ptr :=
                       new Sem_Info_Array'(1 .. Num_Formals => null);
                     Num_Actuals : constant Natural :=
                       Lists.Length (T.Operands);
                     Enclosing_Type : Type_Sem_Ptr := null;
                     Seen_Named : Boolean := False;

                     procedure Handle_Nth_Formal
                       (Formal_Index : Positive;
                        Actual : Optional_Tree;
                        Is_Default : Boolean := False) is
                        --  Determine sem info for Nth operand to instantiation

                        Actual_Copy : Optional_Tree := Actual;
                        Formal : constant Optional_Tree :=
                          Nth_Module_Parameter (Module_Sem, Formal_Index);
                        Formal_Tree : Trees.Tree'Class renames Tree_Ptr_Of
                                                                  (Formal).all;
                        Resolved_Type : Type_Sem_Ptr;
                        use type Type_Sem_Vectors.Elem_Index;
                     begin
                        if Formal_Tree in Param_Decl.Tree'Class then
                           Resolved_Type :=
                             Param_Sem_Ptr (Underlying_Sem_Info (Formal)).
                             Resolved_Type;
                           if Resolved_Type /= null
                             and then (Resolved_Type.Is_Formal_Type
                                or else Resolved_Type.Nested_Type_Index > 0)
                           then
                              --  We are dealing with a type which
                              --  might be defined by this instantiation
                              declare
                                 --  Bundle up info needed by
                                 --  Substitute_Actuals_From_Instantiation
                                 Instantiation_Info : aliased constant
                                   Instantiation_Info_Record :=
                                   (Decl_Region => Visitor.Decl_Region,
                                    Instantiation_Module => Module_Sem,
                                    Instantiation => Optional (T'Access));
                              begin
                                 --  Try to substitute in type
                                 if Enclosing_Type = null then
                                    --  No enclosing type, so use
                                    --  Substitute_Actuals_From_Instantiation
                                    --  directly.
                                    Resolved_Type :=
                                       Substitute_Actuals_From_Instantiation
                                         (Decl_Region =>
                                            Visitor.Decl_Region,
                                          Formal_Type => Resolved_Type,
                                          Instantiation_Module => Module_Sem,
                                          Instantiation => T,
                                          Enclosing_Type => Enclosing_Type);
                                 else
                                    --  Use more general Substitute_Actuals
                                    Resolved_Type := Substitute_Actuals
                                      (Resolved_Type,
                                       Assoc_Type_Region =>
                                         U_Base_Type_Region
                                           (Enclosing_Type),
                                       Instantiation_Info =>
                                         Instantiation_Info'Unchecked_Access);
                                 end if;
                              end;
                           end if;
                           Second_Pass
                             (Visitor.Decl_Region,
                              Actual,
                              Context => Operand_Context);
                           Resolve_Expression
                             (Visitor,
                              Actual,
                              Resolved_Type);

                           --  Record sem-info of actual
                           Actual_Sem_Infos (Formal_Index) :=
                             Sem_Ptr (Sem_Info (Actual));

                           pragma Assert (Tree_Ptr_Of
                             (Sem_Info (Actual).Definition).all not in
                                Param_Decl.Tree);

                        elsif Formal_Tree in Type_Decl.Tree'Class then
                           --  Expecting a type
                           declare
                              Actual_Type : Type_Sem_Ptr;
                              Context_For_Actual : Context_Enum;
                              Formal_Prefix_For_Actual : Optional_Tree;
                           begin
                              if Is_Formal_Type then
                                 --  Actual of formal is treated specially
                                 declare
                                    Actual_Of_Formal_Visitor :
                                      Sem_Second_Pass_Visitor;
                                    Formal_Id : constant Optional_Tree :=
                                      Identifier.Make
                                         (Str =>
                                            Sem_Ptr (Formal_Tree.Sem_Info).
                                              Associated_Symbol.Str,
                                          Source_Pos =>
                                             Find_Source_Pos (Formal_Tree));
                                    Prefix_Type_Region : Type_Region_Ptr;
                                 begin
                                    Context_For_Actual :=
                                      Module_Actual_Of_Formal_Context;

                                    Actual_Of_Formal_Visitor.Decl_Region :=
                                      Visitor.Decl_Region;
                                    Actual_Of_Formal_Visitor.Context :=
                                      Context_For_Actual;
                                    --  Set up formal prefix to identify
                                    --  actual of formal.
                                    if Not_Null (Visitor.Formal_Prefix) then
                                       Formal_Prefix_For_Actual :=
                                          Qualified_Name.Make
                                            (Prefix => Visitor.Formal_Prefix,
                                             Id => Formal_Id);
                                       Prefix_Type_Region :=
                                          U_Base_Type_Region (Type_Sem_Ptr
                                             (Underlying_Sem_Info
                                               (Visitor.Formal_Prefix)));
                                    else
                                       Formal_Prefix_For_Actual
                                          := Formal_Id;
                                    end if;
                                    Actual_Of_Formal_Visitor.Formal_Prefix :=
                                      Formal_Prefix_For_Actual;

                                    --  Set up sym-reference info of formal
                                    --  prefix to refer to corresponding formal
                                    Set_Sem_Info
                                      (Actual_Of_Formal_Visitor.Formal_Prefix,
                                       new Sym_Reference_Info'(
                                         Root_Semantic_Info with
                                           Associated_Symbol => Sem_Ptr
                                             (Formal_Tree.Sem_Info).
                                               Associated_Symbol,
                                           Nested_Region => null,
                                           Context => Context,
                                           Interps => null,
                                           Resolved_Type => null,
                                           Resolved_Interp =>
                                             Null_Optional_Tree,
                                           Hash_Value => 0,
                                           Target_Polymorphic_Type => null,
                                           Reported_As_Undefined => False,
                                           Prefix_Type_Region =>
                                             Prefix_Type_Region,
                                           Underlying_Sem_Info => Sem_Ptr
                                             (Formal_Tree.Sem_Info)));

                                    Visit
                                      (Actual_Copy,
                                       Actual_Of_Formal_Visitor);
                                 end;
                              else
                                 Context_For_Actual :=
                                   Module_Actual_Type_Context;

                                 Second_Pass
                                   (Visitor.Decl_Region,
                                    Actual,
                                    Context => Context_For_Actual);
                              end if;
                              --  Get type sem info
                              --  TBD: Check if type is acceptable at this
                              --  point
                              --      rather than waiting until code_gen phase?
                              Actual_Type :=
                                 Get_Type (Visitor.Decl_Region, Actual,
                                   Context => Context_For_Actual,
                                   Formal_Prefix => Formal_Prefix_For_Actual);

                              Actual_Sem_Infos (Formal_Index) :=
                                Sem_Ptr (Actual_Type);

                              if Actual_Type = null
                                or else not Type_Implements_Type
                                       (Actual_Type => Actual_Type,
                                        Formal_Type =>
                                          Type_Sem_Ptr (Underlying_Sem_Info
                                                           (Formal)),
                                        Allow_Abstract =>
                                          Enclosing_Construct_Is_Abstract)
                              then
                                 Sem_Error
                                   (Actual,
                                    "Type " &
                                    Type_Image (Actual_Type) &
                                    " is abstract or does not implement " &
                                    Type_Image (Type_Sem_Ptr
                                      (Underlying_Sem_Info (Formal)),
                                      Use_Short_Form => True));
                              end if;

                              if False and then Actual_Type.Is_Polymorphic then
                                 Sem_Error
                                   (Actual,
                                    "NYI: Polymorphic actual type (" &
                                    Type_Image (Actual_Type) &
                                    ") not supported in " &
                                    "module instantiation");
                              end if;

                              if Visitor.Decl_Region.Kind =
                                 Operation_Param_Region_Kind
                                and then Actual_Type /= null
                                and then Actual_Type.Associated_Generic_Op =
                                         Visitor.Decl_Region.Associated_Symbol
                              then
                                 --  If one of the actual parameters is
                                 --  a generic type, then this is a generic
                                 --  type.
                                 pragma Assert
                                   (Associated_Generic_Op = null
                                   or else Associated_Generic_Op =
                                           Actual_Type.Associated_Generic_Op);
                                 --  If already set, it should match

                                 Associated_Generic_Op :=
                                   Actual_Type.Associated_Generic_Op;
                              end if;
                           end;

                        elsif Formal_Tree in Operation.Tree'Class then
                           Second_Pass
                             (Visitor.Decl_Region,
                              Actual,
                              Context => Formal_Op_Context);
                           Sem_Error
                             (Formal,
                              "NYI: Formal operation not yet supported");

                           --  Record sem-info of actual
                           Actual_Sem_Infos (Formal_Index) :=
                              Underlying_Sem_Info (Actual);

                        else
                           Sem_Error
                             (Formal,
                              "Unrecognized kind of module formal");
                        end if;
                        if Actual_Sem_Infos (Formal_Index) = null then
                           if Is_Default then
                              Sem_Error
                                (T,
                                 "Default parameter " &
                                 Subtree_Image (Actual) &
                                 " for formal " &
                                 Subtree_Image (Formal) &
                                 " not resolved");
                           else
                              Sem_Error
                                (Actual,
                                 "Actual parameter not resolved");
                           end if;
                        end if;

                     end Handle_Nth_Formal;

                  begin

                     if Prefix_Sem.all in Sym_Reference_Info then
                        Enclosing_Type := Type_Sem_Ptr
                          (Sym_Ref_Ptr (Prefix_Sem).Prefix_Type_Region);
                     end if;

                     if Enclosing_Type = null
                       and then Module_Sym.Enclosing_Region /=
                                Symbols.Library_Region
                     then
                        --  We are instantiating a nested module, get
                        --  cur-inst type of enclosing module
                        Enclosing_Type :=
                           Enclosing_Module_Cur_Inst
                             (Module_Sym.Enclosing_Region);
                     end if;

                     if Enclosing_Type = null then
                        if Debug_Second_Pass then
                           Put_Line ("Type instantiation not " &
                             "directly within a module: " &
                             Subtree_Image (T));
                        end if;
                     end if;

                     if Num_Actuals = 0 and then Is_Formal_Type then
                        --  A formal type need not have any actuals specified
                        null;
                     elsif Num_Actuals > Num_Formals then
                        Sem_Error
                          (T,
                           "Too many parameters in module instantiation");
                     else
                        --  Visit actuals before calling Find_U_[Base_]Type
                        --  routines
                        for Actual_Index in 1 .. Num_Actuals loop
                           declare
                              Formal_Index : Positive := Actual_Index;
                              --  NOTE: This will be updated if named notation
                              --  used
                              Actual : Optional_Tree :=
                                Lists.Nth_Element (T.Operands, Actual_Index);
                              Actual_Tree : Trees.Tree'Class
                                renames Tree_Ptr_Of (Actual).all;
                           begin
                              if Actual_Tree in Reference.Tree then
                                 --  Named notation
                                 declare
                                    Formal_Sym : constant Symbols.Sym_Ptr :=
                                      Symbols.Lookup_In_Region
                                         (Module_Sem.Nested_Region,
                                          Identifier.Tree (Tree_Ptr_Of
                                                              (Reference.Tree (
                                      Actual_Tree).Key).all).Str);
                                    use type Symbols.Sym_Ptr;
                                 begin
                                    if Formal_Sym = null
                                      or else Module_Formal_Index
                                        (Formal_Sym) not in 1 .. Num_Formals
                                    then
                                       Sem_Error
                                         (Reference.Tree (Actual_Tree).Key,
                                          "Does not identify a module formal");
                                       return; --  Fatal error
                                    end if;
                                    Formal_Index :=
                                       Module_Formal_Index (Formal_Sym);
                                    Seen_Named := True;

                                    if Actual_Sem_Infos (Formal_Index) /=
                                       null
                                    then
                                       Sem_Error
                                         (Reference.Tree (Actual_Tree).Key,
                                          "Duplicate definition for formal " &
                                          Subtree_Image
                                             (Nth_Module_Parameter
                                                 (Module_Sem,
                                                  Formal_Index)));
                                    end if;

                                    Handle_Nth_Formal
                                      (Formal_Index,
                                       Reference.Tree (Actual_Tree).Referent);
                                 end;
                              else
                                 --  Positional notation
                                 if Seen_Named then
                                    Sem_Error
                                      (Actual,
                                       "Positional operands must precede " &
                                       "all named operands in " &
                                       Subtree_Image (T));
                                 end if;
                                 Handle_Nth_Formal (Formal_Index, Actual);
                              end if;
                           end;
                        end loop;

                        if Num_Actuals < Num_Formals then
                           --  Process defaults
                           for I in 1 .. Num_Formals loop
                              if Actual_Sem_Infos (I) = null then
                                 --  See whether formal has a default
                                 declare
                                    Formal_Tree : Trees.Tree'Class
                                      renames Tree_Ptr_Of
                                        (Nth_Module_Parameter
                                          (Module_Sem, I)).all;
                                 begin
                                    if Formal_Tree in Type_Decl.Tree then
                                       Sem_Error
                                         (T,
                                          "NYI: Defaults for formal types " &
                                          "not yet supported; " &
                                          "missing actual for " &
                                          Subtree_Image
                                             (Formal_Tree,
                                              Use_Short_Form => True));
                                    elsif Formal_Tree in Param_Decl.Tree
                                      and then Not_Null
                                                  (Param_Decl.Tree (
                                         Formal_Tree).Param_Default)
                                    then
                                       --  Substitute in the default
                                       declare
                                          Default : constant Optional_Tree :=
                                            Param_Decl.Tree (Formal_Tree).
                                            Param_Default;
                                       begin
                                          Handle_Nth_Formal
                                            (I,
                                             Substitute_Actuals_In_Operand
                                               (Optional
                                                 (Tree_Ptr_Of (Default).all),
                                                U_Base_Type_Region
                                                  (Enclosing_Type)),
                                             Is_Default => True);
                                       end;
                                    elsif Formal_Tree in Operation.Tree
                                      and then Not_Null
                                        (Operation.Tree (Formal_Tree).
                                          Statements)
                                    then
                                       Sem_Error
                                         (T,
                                          "NYI: Defaults for formal operations"
                                          & " not yet supported; " &
                                          "missing actual for " &
                                          Subtree_Image
                                             (Formal_Tree,
                                              Use_Short_Form => True));
                                    else
                                       Sem_Error
                                         (T,
                                          "Missing actual for " &
                                          Subtree_Image
                                             (Formal_Tree,
                                              Use_Short_Form => True));
                                    end if;
                                 end;
                              end if;
                           end loop;
                        end if;
                     end if;

                     Set_Type_Sem_Info
                       (T,
                        Module_Sem,
                        Visitor.Decl_Region,
                        Is_Formal_Type => Is_Formal_Type,
                        Enclosing_Type => Enclosing_Type,
                        Formal_Prefix => Visitor.Formal_Prefix,
                        Actual_Sem_Infos => Actual_Sem_Infos,
                        Associated_Generic_Op => Associated_Generic_Op,
                        Use_Primary_Nested_Type => True);
                  end;
               end if;

            end;

         when Is_Function_Of =>
            Sem_Error (T, "NYI: ""is func (...)"" specification");

         when Tuple_Type_Definition =>
            Sem_Error (T, "NYI: tuple type definition");
      end case;

      --  Restore context
      Visitor.Context := Context;
   end Invocation_Action;

   procedure Block_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Block_Stmt.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        Composite_Stmt_Sem_Ptr (T.Sem_Info);
      Context : constant Context_Enum := Visitor.Context;
   begin

      --  Set region for nested block
      Visitor.Decl_Region := Comp_Sem.Nested_Region;
      Visit_And_Resolve_Expr (T.Block_Body, Visitor);
      Visit_And_Resolve_Expr (T.End_With_Values, Visitor);

      --  Restore region
      Visitor.Decl_Region := Comp_Sem.Nested_Region.Enclosing_Region;
   end Block_Stmt_Action;

   procedure Control_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Control_Stmt.Tree) is
      Comp_Sem : constant Computation_Sem_Ptr :=
        new Computation_Semantic_Info;
      Context : constant Context_Enum := Visitor.Context;
      use Control_Stmt;
   begin
      T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
      Comp_Sem.Definition := Optional (T'Access);
      Visitor.Context := Operand_Context;

      case T.Kind is
         when Null_Stmt =>
            null;
         when Return_Stmt =>
            --  If this is a return statement, provide target type
            declare
               Enclosing_Operation : constant Operation_Sem_Ptr :=
                 Find_Enclosing_Operation (Visitor.Decl_Region);
            begin
               if Debug_Second_Pass then
                  Put_Line
                    (" Resolving return statement " & Subtree_Image (T));
               end if;
               if Enclosing_Operation = null then
                  Sem_Error (T, "Return statement must be inside operation");
                  if Debug_Second_Pass then
                     Put_Line
                       (" Enclosing_Operation is null for return stmt.");
                  end if;
               else
                  if Not_Null (T.Values) then
                     declare
                        Outputs : Lists.List renames
                          Operation.Tree (Tree_Ptr_Of
                            (Enclosing_Operation.Definition).all).
                              Operation_Outputs;
                     begin
                        case Lists.Length (Outputs) is
                           when 0 =>
                              Sem_Error
                                (T,
                                 "Enclosing operation has no outputs");

                           when 1 =>
                              --  We have exactly one output, use that as
                              --  target type
                              declare
                                 Result_Opnd : constant Optional_Tree :=
                                   Lists.Nth_Element (Outputs, 1);
                                 Result_Type : constant Type_Sem_Ptr :=
                                   Resolved_Type (Result_Opnd);
                                 Existing_Sem_Info : constant Sem_Ptr :=
                                   Underlying_Sem_Info (T.Values);
                              begin
                                 if Result_Type /= null
                                   and then Existing_Sem_Info /= null
                                   and then Existing_Sem_Info.all in
                                      Operand_Semantic_Info'Class
                                   and then Operand_Sem_Ptr
                                     (Existing_Sem_Info).Resolved_Type /=
                                        null
                                   and then Operand_Sem_Ptr
                                     (Existing_Sem_Info).Resolved_Type.
                                       U_Base_Type = Result_Type.U_Base_Type
                                 then
                                    --  Nothing to do -- already resolved
                                    --  properly
                                    --  NOTE: This can happen when we create
                                    --       a small pseudo-operation
                                    --  consisting
                                    --       of a single return statement.
                                    null;
                                 else
                                    declare
                                       Result_Tree : Trees.Tree'Class renames
                                         Tree_Ptr_Of (Result_Opnd).all;
                                    begin
                                       if Result_Tree in Param_Decl.Tree'Class
                                         and then
                                           Param_Decl.Tree (Result_Tree).Kind
                                             in Param_Decl.Ref_Param_Kinds
                                       then
                                          --  Indicate interested in
                                          --  "ref" result.
                                          Visitor.Context :=
                                            Ref_Operand_Context;
                                       end if;
                                       Visit_And_Resolve_Expr
                                         (T.Values, Visitor, Result_Type);
                                    end;
                                 end if;
                              end;

                           when others =>
                              --  TBD: Handle multiple outputs;
                              --      give error if no outputs
                              Sem_Error (T, "NYI: More than one output");
                              if Debug_Second_Pass then
                                 Put_Line
                                   ("   Number of operation outputs =" &
                                    Natural'Image (Lists.Length (Outputs)));
                              end if;
                        end case;
                     end;
                  else
                     --  No return value specified
                     null;  --  TBD: Make sure result object has
                     --      been assigned a value.

                  end if;  --  Whether return value specified

               end if;  --  Whether can find enclosing operation
            end;
         when Continue_Stmt =>
            declare
               Loop_To_Continue : constant Optional_Tree :=
                 Find_Enclosing_Stmt
                    (Visitor.Decl_Region,
                     Control_Stmt.Loop_Stmt,
                     T.Id);
               Innermost_Loop  : constant Optional_Tree :=
                 Find_Enclosing_Stmt
                    (Visitor.Decl_Region,
                     Control_Stmt.Loop_Stmt,
                     Id => Null_Optional_Tree);
            begin
               if Is_Null (Loop_To_Continue) then
                  Sem_Error (T, "Target of continue statement not found");
               else
                  declare
                     Target_Loop_Sem    : constant Composite_Stmt_Sem_Ptr :=
                       Composite_Stmt_Sem_Ptr (Sem_Info (Loop_To_Continue));
                     Innermost_Loop_Sem : constant Composite_Stmt_Sem_Ptr :=
                       Composite_Stmt_Sem_Ptr (Sem_Info (Innermost_Loop));
                     Is_Innermost_Loop : constant Boolean :=
                       Target_Loop_Sem = Innermost_Loop_Sem;
                     Loop_Tree : Trees.Tree'Class
                       renames Tree_Ptr_Of (Loop_To_Continue).all;
                     Is_Parallel_Continue : constant Boolean :=
                       Inside_Parallel_Construct
                         (Visitor.Decl_Region, Up_To => Target_Loop_Sem);
                  begin
                     --  Remember target of continue.
                     Comp_Sem.Target_Stmt := Target_Loop_Sem;

                     if not Is_Innermost_Loop and then Is_Parallel_Continue
                       and then Is_Null (T.Values)
                     then
                        --  We no longer permit a continue of an outer loop
                        --  from inside a parallel construct
                        --  unless new values are being provided, because
                        --  we now implement a parallel continue as adding a
                        --  parallel iteration to the target-loop's master,
                        --  and then a simple "continue" of the innermost loop.
                        --  This wouldn't make sense if we didn't provide
                        --  our own values for the new iteration.
                        Sem_Error
                          (T,
                           "Continue of outer loop from concurrent context " &
                           "only permitted if specifying next values");

                     elsif Loop_Tree in For_Loop_Construct.Tree then
                        --  We have a for loop, check whether has correct
                        --  number of values after the "with".
                        declare
                           For_Loop_Sem : constant For_Loop_Construct_Sem_Ptr
                              :=
                             For_Loop_Construct_Sem_Ptr (Target_Loop_Sem);
                        begin
                           For_Loop_Sem.Num_Continues :=
                             For_Loop_Sem.Num_Continues + 1;

                           if not Is_Innermost_Loop
                             and then Is_Parallel_Continue
                           then
                              --  We count this as a continue of the innermost
                              --  loop as well as the outer loop
                              --  for the purposes of "fixups."
                              Innermost_Loop_Sem.Num_Continues :=
                                Innermost_Loop_Sem.Num_Continues + 1;
                           end if;

                           if not For_Loop_Sem.Is_Potentially_Concurrent
                             and then Is_Parallel_Continue
                           then
                              --  This "continue" makes the loop potentially
                              --  concurrent, because it occurs inside
                              --  a potentially concurrent structure
                              For_Loop_Sem.Is_Potentially_Concurrent := True;

                              if Not_Null (T.Values) then
                                 --  All iterators must be Initial_Value
                                 --  iterators if we have a "continue" that
                                 --  supplies values from within a parallel
                                 --  context, because the more complex
                                 --  iterators don't support parallel
                                 --  generation of a next value.
                                 for I in For_Loop_Sem.Iterator_Sems'Range loop
                                    if For_Loop_Sem.Iterator_Sems (I).
                                      Num_Next_Values /= 0
                                    then
                                       Sem_Error (T,
                                         "Continue from concurrent construct" &
                                         " allowed only if all iterators" &
                                         " provide just an initial value");
                                    end if;
                                 end loop;
                              end if;
                           end if;

                           if not For_Loop_Sem.Is_Potentially_Concurrent
                             and then
                               not Semantics.Insert_Implicit_Parallel_Loops
                             and then Not_Null (T.Values)
                           then
                              --  This continue might produce an "exit" if this
                              --  loop doesn't use a nested block.
                              For_Loop_Sem.Num_Exits :=
                                For_Loop_Sem.Num_Exits + 1;
                           end if;

                           Analyze_Continue_With_Values
                             (Visitor, T, For_Loop_Sem);

                        end;
                     else
                        --  "with Values" not allowed for while/indefinite loop
                        if Not_Null (T.Values) then
                           Sem_Error
                             (T.Values,
                              "Only for-loop allows the " &
                              "specification of next values in a continue");
                        else
                           declare
                              Loop_Sem : constant Composite_Stmt_Sem_Ptr :=
                               Composite_Stmt_Sem_Ptr (Loop_Tree.Sem_Info);
                           begin
                              --  We don't allow continuing outer loops
                              --  without values from parallel contexts.
                              pragma Assert (Is_Innermost_Loop
                                or else not Is_Parallel_Continue);

                              Loop_Sem.Num_Continues :=
                                Loop_Sem.Num_Continues + 1;
                           end;
                        end if;
                     end if;
                  end;

               end if;
            end;

         when Exit_Stmt =>
            declare
               Stmt_To_Exit : constant Optional_Tree :=
                 Find_Enclosing_Stmt
                    (Visitor.Decl_Region,
                     T.Applies_To,
                     T.Id);
            begin
               if Is_Null (Stmt_To_Exit) then
                  Sem_Error (T, "Target of exit statement not found");
               else
                  declare
                     Exited_Stmt_Sem : constant Composite_Stmt_Sem_Ptr :=
                       Composite_Stmt_Sem_Ptr (Sem_Info (Stmt_To_Exit));
                  begin
                     --  Remember target of exit.
                     Comp_Sem.Target_Stmt := Exited_Stmt_Sem;

                     if Not_Null (T.Values) then
                        Visitor.Context := Exit_With_Values_Context;
                        Visit_And_Resolve_Expr (T.Values, Visitor);
                     end if;
                     --  Remember that construct is exited
                     Exited_Stmt_Sem.Num_Exits :=
                       Exited_Stmt_Sem.Num_Exits + 1;
                  end;
               end if;
            end;
      end case;

      --  Restore context
      Visitor.Context := Context;
   end Control_Stmt_Action;

   procedure Case_Construct_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Case_Construct.Tree) is
      Case_Sem : constant Case_Construct_Sem_Ptr :=
        Case_Construct_Sem_Ptr (T.Sem_Info);
      Next_Alt_Region : Region_Ptr := Case_Sem.Nested_Region;
      --  Region for first/next case alternative
      Context : constant Context_Enum := Visitor.Context;
      Enclosing_Region : constant Region_Ptr := Visitor.Decl_Region;
      Uses_Compare : Boolean := False;
   begin
      Visitor.Context := Operand_Context;
      Visit (T.Case_Selector, Visitor);
      Resolve_Expression
        (Visitor,
         T.Case_Selector,
         Resolved_Type => Case_Sem.Case_Selector_Type);

      if Case_Sem.Case_Selector_Type = null then
         Sem_Error (T.Case_Selector, "Cannot resolve type of selector");

         --  Restore context
         Visitor.Context := Context;

         return;
      end if;

      for I in 1 .. Lists.Length (T.Case_Alt_List) loop
         declare
            Case_Alt : Reference.Tree renames Reference.Tree
              (Tree_Ptr_Of (Lists.Nth_Element (T.Case_Alt_List, I)).all);
            Case_Alt_Key_Container : Invocation.Tree
              renames Invocation.Tree (Tree_Ptr_Of (Case_Alt.Key).all);
            Case_Alt_Key : Optional_Tree :=
              Lists.Nth_Element (Case_Alt_Key_Container.Operands, 1);
         begin
            --  Analyze and resolve case-alt key
            if Case_Sem.Case_Selector_Type.Is_Polymorphic then
               --  Don't want to force types to be converted to a set
               Visitor.Context := Case_Choice_Context;
            else
               Visitor.Context := Operand_Context;
            end if;
            Visitor.Decl_Region := Next_Alt_Region;
            Visit (Case_Alt_Key, Visitor);
            Resolve_Case_Alt_Key
              (Visitor,
               Case_Sem,
               Case_Alt_Key,
               Uses_Compare,
               Is_Outermost => True);
            --  TBD: If Case_Selector_Type is universal type,
            --      then should run the resolution the "other" way
            --      by seeing whether could convert case selector
            --      to case-alt key type.

            if T.Is_Case_Expr then
               --  Analyze but don't resolve expression
               Visitor.Context := Context;
               Visit (Case_Alt.Referent, Visitor);
            else
               --  Analyze and resolve case alternative statements
               Visitor.Context := Context;
               Visit_And_Resolve_Expr (Case_Alt.Referent, Visitor);
            end if;

            --  Move to region for next case alternative
            Next_Alt_Region := Next_Alt_Region.Next_Sibling_Region;
         end;
      end loop;

      if Uses_Compare then
         --  Lookup "=?"(T,T)->Ordering operator
         Case_Sem.Op_Sem := Find_Compare_Op_For (Case_Sem.Case_Selector_Type);
         if Case_Sem.Op_Sem = null then
            Sem_Error
              (T.Case_Selector,
               "Case selector not of a comparable type");
         end if;
      end if;

      if T.Is_Case_Expr then
         --  Create overall interps of case expression
         declare
            Resolved_Type : Type_Sem_Ptr := null;
         begin
            Create_Case_Expr_Interps (T);
            Resolve_Expression (Visitor, Case_Sem.Definition, Resolved_Type);
         end;
      end if;

      --  Restore region and context
      Visitor.Decl_Region := Enclosing_Region;
      Visitor.Context := Context;
      Visit_And_Resolve_Expr (T.End_With_Values, Visitor);
   end Case_Construct_Action;

   procedure Conditional_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Conditional.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        Composite_Stmt_Sem_Ptr (T.Sem_Info);
      Then_Part_Region : constant Symbols.Region_Ptr :=
        Comp_Sem.Nested_Region;
      --  Region for the Then part
      Else_Part_Region : constant Symbols.Region_Ptr :=
        Then_Part_Region.Next_Sibling_Region;
      --  Region for the Else part
      Context : constant Context_Enum := Visitor.Context;
      use Conditional;
   begin
      Visitor.Context := Operand_Context;
      Visit_And_Resolve_Expr (T.Cond, Visitor, Resolved_Type => Boolean_Type);

      Visitor.Context := Context;
      Visitor.Decl_Region := Then_Part_Region;
      case T.Kind is
         when Stmt_Parts =>
            Visit_And_Resolve_Expr (T.Then_Part, Visitor);
         when Expr_Parts | Quest_Colon =>
            Visit (T.Then_Part, Visitor);
      end case;

      Visitor.Context := Context;
      Visitor.Decl_Region := Else_Part_Region;
      case T.Kind is
         when Stmt_Parts =>
            Visit_And_Resolve_Expr (T.Else_Part, Visitor);
         when Expr_Parts | Quest_Colon =>
            Visit (T.Else_Part, Visitor);
      end case;

      Visitor.Decl_Region := Else_Part_Region.Enclosing_Region;
      if Not_Null (T.End_With_Values) then
         Visit_And_Resolve_Expr (T.End_With_Values, Visitor);
      end if;

      if T.Kind not in Stmt_Parts then
         --  Create interps based on then- and else-part interps
         Create_Conditional_Expr_Interps (T);
      end if;
   end Conditional_Action;

   procedure For_Loop_Construct_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out For_Loop_Construct.Tree) is
      For_Loop_Sem : constant For_Loop_Construct_Sem_Ptr :=
        For_Loop_Construct_Sem_Ptr (T.Sem_Info);
      Context : constant Context_Enum := Visitor.Context;
      Loop_Visitor : Sem_Second_Pass_Visitor := Visitor;
      Loop_Body_Region : constant Region_Ptr := For_Loop_Sem.Nested_Region;
      Loop_Param_Region : constant Region_Ptr :=
        For_Loop_Sem.Loop_Param_Region;
      use type For_Loop_Construct.For_Loop_Kind_Enum;
   begin
      if Debug_Second_Pass then
         Put_Line
           ("Second pass for for-loop construct; num loop params:" &
            Symbols.Sym_Index'Image
               (Symbols.Num_Symbols_In_Region (Loop_Param_Region)));
      end if;
      Second_Pass_List (Loop_Param_Region, T.Iterators,
        Context => Statement_Context);
      Second_Pass (Loop_Param_Region, T.Filter,
        Context => Statement_Context);

      Loop_Visitor.Decl_Region := Loop_Body_Region;
      case T.Kind is
         when For_Loop_Construct.Univ_Quantified_Expr |
           For_Loop_Construct.Existential_Quantified_Expr =>
            --  Quantified expression
            Visit_And_Resolve_Expr (T.Loop_Body, Loop_Visitor,
              Resolved_Type => Boolean_Type);
            For_Loop_Sem.Resolved_Type := Boolean_Type;
            For_Loop_Sem.Resolved_Interp := For_Loop_Sem.Definition;
            --  Quantified expressions are always exited as soon as possible
            For_Loop_Sem.Num_Exits := 1;

         when For_Loop_Construct.Map_Reduce_Expr =>
            --  Map/Reduce expression "(for I in 1..10 => <0> + I**2)"
            Loop_Visitor.Context := Operand_Context;
            Visit (T.Loop_Body, Loop_Visitor);
            Visit (T.Filter, Loop_Visitor);

            if not Contains_Initial_Value_Operand (T.Loop_Body) then
               Sem_Error (T, "Map-Reduce expression requires an initial value"
                 & " specified in <...>");
            end if;

            Create_Map_Reduce_Expr_Interps (T);

         when For_Loop_Construct.Container_Comprehension =>
            --  Iterator in container aggregate
            declare
               Loop_Body_Tree : Trees.Tree'Class renames
                 Tree_Ptr_Of (T.Loop_Body).all;
            begin
               Loop_Visitor.Context := Operand_Context;
               if Loop_Body_Tree in Reference.Tree then
                  --  "for I in 1..10, I*2 => F(I)"
                  Visit (Reference.Tree (Loop_Body_Tree).Key, Loop_Visitor);
                  Loop_Visitor.Context := Operand_Context;
                  Visit
                    (Reference.Tree (Loop_Body_Tree).Referent, Loop_Visitor);
               else
                  --  "for I in 1..10 => F(I)"
                  Visit (T.Loop_Body, Loop_Visitor);
               end if;
               Visit (T.Filter, Loop_Visitor);

            end;

         when For_Loop_Construct.For_Loop_Statement =>
            --  For loop statement
            Visit_And_Resolve_Expr (T.Loop_Body, Loop_Visitor);
            Visit (T.Filter, Loop_Visitor);
      end case;

      Loop_Visitor.Decl_Region := Loop_Param_Region;
      --  TBD: Is this right -- should end-with-values see loop variables?
      Visit_And_Resolve_Expr (T.End_With_Values, Loop_Visitor);

   end For_Loop_Construct_Action;

   procedure Iterator_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Iterator.Tree) is
      Iterator_Sem : constant Iterator_Sem_Ptr :=
        Iterator_Sem_Ptr (T.Sem_Info);
      Iterator_Sym : constant Symbols.Sym_Ptr :=
        Iterator_Sem.Associated_Symbol;
      Context : constant Context_Enum := Visitor.Context;
      use type Interpreter.Direction;
      use type Iterator.Iterator_Kind_Enum;

      function Resolve_As_Set_Iterator return Boolean is
         --  Try to interpret as a set iterator.  Return True if possible.
         --  Determine type of object from type of set;
         --  look for "Remove_Any" operation and use output type.
      begin
         if Iterator_Sem.Index_Set_Type /= null then
            --  Get element type
            declare
               Element_Type : constant Type_Sem_Ptr :=
                 Get_Remove_Func_Output_Type
                    (Iterator_Sem.Index_Set_Type,
                     Iterator_Sem.Iterator_Direction);
            begin
               if Element_Type = null then
                  Sem_Error
                    (T,
                     Type_Image (Iterator_Sem.Index_Set_Type) &
                     " does not support " &
                     Interpreter.Direction_Image
                        (Iterator_Sem.Iterator_Direction) &
                     " iteration");
                  return False;
               elsif Iterator_Sem.Resolved_Type /= null then
                  if Iterator_Sem.Resolved_Type.U_Base_Type /=
                     Element_Type.U_Base_Type
                  then
                     Sem_Error
                       (T,
                        "Loop variable does not match set element type");
                     return False;
                  end if;
               else
                  Iterator_Sem.Resolved_Type := Element_Type;
               end if;
               if Debug_Second_Pass then
                  Put_Line
                    (" Resolved type of set iterator " &
                     Subtree_Image (T) &
                     " is " &
                     Type_Image (Iterator_Sem.Resolved_Type));
                  Put_Line
                    (" Index-set type is " &
                     Type_Image (Iterator_Sem.Index_Set_Type));
               end if;
            end;
            return True;
         else
            Sem_Error (T, "Unable to resolve type of loop variable");
            return False;
         end if;
      end Resolve_As_Set_Iterator;

   begin  --  Iterator_Action
      if Debug_Second_Pass then
         Put_Line
           ("Second pass for iterator " &
            Sym_Name (Iterator_Sym) &
            "; sym_index =" &
            Sym_Index'Image (Iterator_Sym.Index));
      end if;
      Iterator_Sem.Context := Context;
      Visitor.Context := Type_Context;
      Visit (T.Obj_Type, Visitor);
      if Not_Null (T.Obj_Type) then
         Iterator_Sem.Resolved_Type :=
            Get_Type (Visitor.Decl_Region, T.Obj_Type);
      end if;
      if Debug_Second_Pass
        and then Iterator_Sem.Resolved_Type /= null
        and then Iterator_Sem.Resolved_Type.Associated_Module /= null
      then
         Put_Line
           ("Second pass for iterator " &
            Sym_Name (Iterator_Sym) &
            "; Resolved_Type = " &
            Type_Image (Iterator_Sem.Resolved_Type));
      end if;

      if Iterator_Sem.Enclosing_For_Loop /= null then
         if Iterator_Sem.Iterator_Direction = Interpreter.Unordered_Dir then
            Iterator_Sem.Iterator_Direction :=
              Iterator_Sem.Enclosing_For_Loop.For_Loop_Direction;
         elsif Iterator_Sem.Enclosing_For_Loop.For_Loop_Direction /=
               Interpreter.Unordered_Dir
         then
            --  Cannot specify both places
            Sem_Error (T, "May not specify direction of iteration twice");
         end if;
      end if;

      --  Initialize Loop_Param_Is_By_Ref to match syntactic "ref" notion.
      --  Will update if "indexing" passes by copy.
      Iterator_Sem.Loop_Param_Is_By_Ref := T.Is_Ref;

      if Is_Null (T.Obj_Value) then
         if T.Kind = Iterator.Set_Iterator then
            --  "(for all X : T => X == X)"
            Sem_Error (T, "NYI: Quantified expression without iterator");
         end if;
      else
         Visitor.Context := Operand_Context;
         Visit (T.Obj_Value, Visitor);
         case T.Kind is
            when Iterator.Set_Iterator =>
               --  Resolve expression without any context.
               Resolve_Expression
                 (Visitor,
                  T.Obj_Value,
                  Iterator_Sem.Index_Set_Type);

               --  Determine type of object from type of set;
               --  look for "Remove_Any" operation and use output type.
               if Resolve_As_Set_Iterator then
                  --  There is no separate container type
                  Iterator_Sem.Iteration_Type := Iterator_Sem.Index_Set_Type;
               end if;

            when Iterator.Container_Iterator =>
               --  "for each Value of Container" or
               --  "for each [Key => Value] of Container" or
               Resolve_Expression
                 (Visitor,
                  T.Obj_Value,
                  Iterator_Sem.Iteration_Type);

               if Iterator_Sem.Iteration_Type /= null then
                  --  "indexing" operator determines type of Key and Value.
                  --  "index_set" operator should return a Set<Index_Type>
                  declare
                     Indexing_Op : constant Operation_Sem_Ptr :=
                       Find_Indexing_Op_For (Iterator_Sem.Iteration_Type);
                     Index_Set_Op : constant Operation_Sem_Ptr :=
                       Find_Index_Set_Op_For (Iterator_Sem.Iteration_Type);
                  begin
                     if Indexing_Op /= null and then Index_Set_Op /= null then
                        declare
                           Indexing_Op_Tree : Operation.Tree renames
                              Operation.Tree (Tree_Ptr_Of
                                 (Indexing_Op.Definition).all);
                           Index_Type : constant Type_Sem_Ptr :=
                             Substitute_Actuals
                                (Resolved_Type
                                    (Lists.Nth_Element
                                      (Indexing_Op_Tree.Operation_Inputs, 2)),
                                 U_Base_Type_Region
                                    (Iterator_Sem.Iteration_Type));
                           Output_Param : constant Optional_Tree :=
                             (Lists.Nth_Element
                                (Indexing_Op_Tree.Operation_Outputs, 1));
                           Element_Type : constant Type_Sem_Ptr :=
                             Substitute_Actuals
                                (Resolved_Type (Output_Param),
                                 U_Base_Type_Region
                                    (Iterator_Sem.Iteration_Type));
                           Index_Set_Type : constant Type_Sem_Ptr :=
                             Get_Func_Output_Type (Index_Set_Op,
                               U_Base_Type_Region
                                  (Iterator_Sem.Iteration_Type));
                           Remove_Func : constant Operation_Sem_Ptr :=
                             Get_Remove_Func
                                (Index_Set_Type,
                                 Iterator_Sem.Iterator_Direction);
                        begin
                           if Iterator_Sem.Resolved_Type /= null then
                              if Iterator_Sem.Resolved_Type.U_Base_Type /=
                                 Element_Type.U_Base_Type
                              then
                                 Sem_Error
                                   (T,
                                    "Loop variable does not match " &
                                    "container element type");
                              end if;
                           else
                              Iterator_Sem.Resolved_Type := Element_Type;
                           end if;

                           --  Check whether output of indexing is by-ref.
                           Iterator_Sem.Loop_Param_Is_By_Ref :=
                             Sym_Is_By_Ref (Param_Sem_Ptr
                               (Sem_Info (Output_Param)).
                                  Associated_Symbol);

                           --  Check whether corresponding param
                           --  of indexing op is by-ref.
                           Iterator_Sem.Container_Is_By_Ref :=
                             Sym_Is_By_Ref (Param_Sem_Ptr
                               (Sem_Info
                                 (Lists.Nth_Element
                                   (Indexing_Op_Tree.Operation_Inputs, 1))).
                                      Associated_Symbol);

                           --  Key_Sem represents named or anonymous
                           --  key (aka index) value.
                           Iterator_Sem.Key_Sem.Resolved_Type := Index_Type;
                           Iterator_Sem.Key_Sem.Context := Context;

                           Iterator_Sem.Index_Set_Type := Index_Set_Type;
                           if Remove_Func = null then
                              Sem_Error
                                (T,
                                 "Container does not support " &
                                 Interpreter.Direction_Image
                                    (Iterator_Sem.Iterator_Direction) &
                                 " iteration");
                           end if;
                        end;

                        if Debug_Second_Pass then
                           Put_Line
                             (" Resolved type of element iterator " &
                              Subtree_Image (T) &
                              " is " &
                              Type_Image (Iterator_Sem.Resolved_Type));
                           Put_Line
                             (" Index-set type is " &
                              Type_Image (Iterator_Sem.Index_Set_Type));
                           Put_Line
                             (" Container type is " &
                              Type_Image (Iterator_Sem.Iteration_Type));
                        end if;

                     else
                        --  Interpret as equiv to "for I in Container ..."
                        Iterator_Sem.Index_Set_Type :=
                          Iterator_Sem.Iteration_Type;

                        if Not_Null (T.Key_Name)
                          or else not Resolve_As_Set_Iterator
                        then
                           --  Revert to a (failed) container iterator
                           Iterator_Sem.Index_Set_Type := null;

                           if Indexing_Op = null then
                              Sem_Error
                                (T,
                                 "No ""indexing"" op defined for container");
                           end if;

                           if Index_Set_Op = null then
                              Sem_Error
                                (T,
                                 "No ""index_set"" op defined for container");
                           end if;

                        else
                           --  Treat henceforth as a set iterator
                           T.Kind := Iterator.Set_Iterator;
                           Iterator_Sem.Loop_Param_Is_By_Ref := False;

                           --  There is no separate container type
                           Iterator_Sem.Iteration_Type :=
                             Iterator_Sem.Index_Set_Type;
                           Iterator_Sem.Key_Sem := null;
                        end if;
                     end if;

                  end;
               end if;

            when Iterator.Value_Iterator =>
               --  Initial value determines type of loop parameter
               Resolve_Expression
                 (Visitor,
                  T.Obj_Value,
                  Iterator_Sem.Resolved_Type);

               Iterator_Sem.Iteration_Type := Iterator_Sem.Resolved_Type;

               if T.Is_Ref and then Iterator_Sem.Iteration_Type /= null
                 and then
                   not Iterator_Sem.Iteration_Type.Known_To_Be_Assignable
               then
                  --  Not "truly" by ref since not assignable
                  Iterator_Sem.Loop_Param_Is_By_Ref := False;
               end if;

               --  There is no separate container/set type
               if Debug_Second_Pass then
                  Put_Line
                    (" Resolved type of value iterator " &
                     Subtree_Image (T) &
                     " is " &
                     Type_Image (Iterator_Sem.Resolved_Type));
               end if;
         end case;
      end if;

      Second_Pass_List (Visitor.Decl_Region, T.Next_Values,
        Context => Operand_Context);
      for I in 1 .. Lists.Length (T.Next_Values) loop
         --  Resolve type of "next" values to that of loop variable
         declare
            Next_Value_Type : Type_Sem_Ptr := Iterator_Sem.Resolved_Type;
         begin
            Visitor.Context := Operand_Context;
            Resolve_Expression
              (Visitor,
               Lists.Nth_Element (T.Next_Values, I),
               Next_Value_Type);
         end;
      end loop;

      if Not_Null (T.While_Cond) then
         Visitor.Context := Operand_Context;
         Visit_And_Resolve_Expr
           (T.While_Cond,
            Visitor,
            Resolved_Type => Boolean_Type);
      end if;

      --  Restore context
      Visitor.Context := Context;
   end Iterator_Action;

   procedure While_Stmt_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out While_Stmt.Tree) is
      Comp_Sem : constant Composite_Stmt_Sem_Ptr :=
        Composite_Stmt_Sem_Ptr (T.Sem_Info);
      Loop_Body_Region : constant Symbols.Region_Ptr :=
        Comp_Sem.Nested_Region;
      Context : constant Context_Enum := Visitor.Context;
   begin
      if Not_Null (T.While_Cond) then
         Visitor.Context := Operand_Context;
         Visit_And_Resolve_Expr
           (T.While_Cond,
            Visitor,
            Resolved_Type => Boolean_Type);
      end if;

      Visitor.Context := Context;
      Visitor.Decl_Region := Loop_Body_Region;
      Visit_And_Resolve_Expr (T.Loop_Body, Visitor);

      Visitor.Context := Context;
      Visitor.Decl_Region := Loop_Body_Region.Enclosing_Region;
      Visit_And_Resolve_Expr (T.End_With_Values, Visitor);
   end While_Stmt_Action;

   procedure Selection_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Selection.Tree) is
      Sel_Sem : Operand_Sem_Ptr;
      Context : constant Context_Enum := Visitor.Context;

      Id_Tree : Identifier.Tree renames
        Identifier.Tree (Tree_Ptr_Of (T.Selector).all);

      Selector_Str : constant Strings.U_String := Id_Tree.Str;

      --  This is true if "." is used for selecting from modules/types as well
      Include_Type_Prefixes : constant Boolean :=
        Languages.Language_Uses_Selection_For_Modules;

      Non_Component_Sym_Found : Sym_Ptr := null;
         --  Set to point to non-component symbol found

      function Make_Selection
        (Assoc_Type_Region : Type_Region_Ptr;
         Prefix_Interp : Optional_Tree)
         return Optional_Tree
      is
         --  Create Selection interp if selector found in region
         --  TBD: What about visibility of private components?
         Prefix_Interp_Sem : constant Sem_Ptr :=
           Sem_Ptr (Sem_Info (Prefix_Interp));
      begin
         if Prefix_Interp_Sem /= null
           and then Prefix_Interp_Sem.all in Operand_Semantic_Info'Class
         then
            declare
               Prefix_U_Sem : constant Sem_Ptr :=
                 Underlying_Sem_Info (Prefix_Interp_Sem);
               Prefix_Type : constant Type_Sem_Ptr :=
                 Operand_Sem_Ptr (Prefix_Interp_Sem).Resolved_Type;
               Prefix_Module : Module_Sem_Ptr := null;
            begin
               if Prefix_Type /= null then
                  Prefix_Module := Prefix_Type.Associated_Module;
               elsif Prefix_U_Sem.all in Module_Semantic_Info then
                  Prefix_Module := Module_Sem_Ptr (Prefix_U_Sem);
               elsif Prefix_U_Sem.all in Type_Semantic_Info then
                  Prefix_Module := Type_Sem_Ptr (Prefix_U_Sem).
                    Associated_Module;
               end if;

               if Prefix_Module = null
                 or else Prefix_Module.Nested_Region = null
               then
                  if Debug_Second_Pass then
                     Put_Line
                       (" Interp of Prefix " &
                        Subtree_Image (Prefix_Interp) &
                        " does not support selection " &
                        Subtree_Image (T));
                  end if;
               else
                  --  Look up selector in associated region
                  declare
                     Sel_Sym : Symbols.Sym_Ptr :=
                       Symbols.Lookup_In_Region
                          (Prefix_Module.Nested_Region,
                           Selector_Str,
                           Orig_Region => Visitor.Decl_Region);
                     use type Symbols.Sym_Ptr;
                  begin
                     while Sel_Sym /= null
                       and then not Decl_Is_For_Component
                          (Sel_Sym.Definition)
                     loop
                        --  Remember non-component sym encountered
                        Non_Component_Sym_Found := Sel_Sym;

                        --  Skip over non-component homonyms
                        Sel_Sym := Symbols.Next_Homonym_In_Region (Sel_Sym,
                          Orig_Region => Visitor.Decl_Region);
                     end loop;

                     if Sel_Sym /= null
                       and then Decl_Is_For_Component (Sel_Sym.Definition)
                     then
                        --  Selector identifies a component
                        declare
                           Result : constant Optional_Tree :=
                             Selection.Make (Prefix_Interp, T.Selector);
                           Result_Sem : constant Selection_Sem_Ptr :=
                             new Selection_Semantic_Info;
                        begin
                           --  Build up the sem info
                           Result_Sem.Definition := Result;
                           Result_Sem.Comp_Decl :=
                             Object_Sem_Ptr (Sel_Sym.Sem_Info);
                           Result_Sem.Resolved_Type :=
                              Substitute_Actuals
                                (Result_Sem.Comp_Decl.Resolved_Type,
                                 U_Base_Type_Region (Prefix_Type));
                           Set_Sem_Info (Result, Root_Sem_Ptr (Result_Sem));

                           if not Region_Encloses_Region
                               (Encloser =>
                                  Prefix_Module.Nested_Region,
                                Enclosed => Visitor.Decl_Region)
                             and then Result_Sem.Comp_Decl.Context not in
                                  Visible_Interface_Item_Contexts
                             and then Result_Sem.Comp_Decl.Context not in
                               Module_Parameter_And_Ancestry_Contexts
                             and then (not Prefix_Module.Treat_As_Type
                               or else
                                 not Region_Encloses_Region
                                  (Encloser =>
                                     Prefix_Module.Associated_Symbol.
                                       Enclosing_Region,
                                   Enclosed => Visitor.Decl_Region))
                           then
                              --  Referring to non-visible component of
                              --  non-enclosing module.
                              Sem_Error (T, Subtree_Image (Id_Tree) &
                                " is not a visible component of " &
                                Subtree_Image (T.Prefix));
                           end if;

                           if Debug_Second_Pass then
                              Put_Line
                                (" Making selection interp for " &
                                 Subtree_Image (T) &
                                 ": " &
                                 Subtree_Image (Result) &
                                 " of type " &
                                 Type_Image (Result_Sem.Resolved_Type));
                           end if;
                           return Result;   ---------- Selection interp

                        end;
                     else
                        if Debug_Second_Pass then
                           Put_Line
                             (" No element of Prefix interp " &
                              Subtree_Image (Prefix_Interp) &
                              " identified by " &
                              Subtree_Image (T));
                        end if;
                     end if;
                  end;
               end if;  --  Prefix has a region
            end;
         end if;  --  Prefix has appropriate interp
         --  No meaningful selection for this prefix
         return Null_Optional_Tree;
      end Make_Selection;

      function Make_Selection_Interps is new Interpretations.Propagate_Interps
        (Make_Selection);

   begin  --  Selection_Action

      if T.Sem_Info /= null then
         return;  --  Already did this
      end if;

      if Debug_Second_Pass then
         Put_Line (" Second pass for selection " & Subtree_Image (T));
      end if;

      Visitor.Context := Selector_Prefix_Context;
      Visit (T.Prefix, Visitor);

      declare
         Prefix_Sem : constant Sem_Ptr := Sem_Ptr (Sem_Info (T.Prefix));
         Interps : Interpretations.Interp_Tree;
      begin
         if Prefix_Sem /= null
           and then Prefix_Sem.all in Operand_Semantic_Info'Class
         then
            --  Do a lookup of selector in each interp of prefix
            Interps :=
               Make_Selection_Interps (Operand_Sem_Ptr (Prefix_Sem).Interps);
            --  Build selections based on prefix interps

            if Interpretations.Has_Interp (Interps) then
               --  Has interpretation as a selected component
               declare
                  First : constant Optional_Tree :=
                    Interpretations.First_Interp (Interps);
                  First_Sem : constant Operand_Sem_Ptr :=
                    Operand_Sem_Ptr (Sem_Info (First));
                  pragma Assert (First_Sem.all in Selection_Semantic_Info);
               begin
                  Sel_Sem := new Selection_Semantic_Info;
                  Sel_Sem.Interps := Interps;
                  if Debug_Second_Pass then
                     Put_Line
                       (" First_Interp of " &
                        Subtree_Image (T) &
                        " is " &
                        Subtree_Image (First) &
                        " of type " &
                        Type_Image (First_Sem.Resolved_Type));
                  end if;
                  --  Ignore non-component syms found
                  Non_Component_Sym_Found := null;
               end;
            elsif Include_Type_Prefixes then
               --  Might be element of a package
               declare
                  Pkg_Type : constant Type_Sem_Ptr :=
                    Get_Type (Visitor.Decl_Region, T.Prefix,
                      Complain_If_Not_A_Type => False);
               begin
                  if Pkg_Type = null then
                     --  No interpretation as "<pkg>.<element>"
                     Sel_Sem := null;
                  else
                     --  Create a sym_ref_info
                     Set_Identifier_Sem_Info
                       (Visitor.Decl_Region,
                        Context,
                        Id_Tree,
                        Prefix => T.Prefix,
                        Prefix_Type => Pkg_Type,
                        Use_Selection_Syntax => True);

                     Sel_Sem := Operand_Sem_Ptr (Id_Tree.Sem_Info);

                     --  Ignore non-component syms found
                     Non_Component_Sym_Found := null;
                  end if;

                  if Debug_Second_Pass then
                     if Sel_Sem /= null and then
                       Interpretations.Has_Interp (Sel_Sem.Interps)
                     then
                        Put_Line
                          (" Making package selection interp for " &
                           Subtree_Image (T) & ": " &
                           Subtree_Image
                             (Interpretations.First_Interp (Sel_Sem.Interps)));
                     end if;
                  end if;
               end;
            end if;

            if Sel_Sem = null then
               if not Include_Type_Prefixes or else Context /= Op_Context then
                  --  Give appropriate error message now
                  if Interpretations.Has_Interp
                    (Operand_Sem_Ptr (Prefix_Sem).Interps)
                  then
                     if Non_Component_Sym_Found /= null then
                        case Non_Component_Sym_Found.Kind is
                           when Operation_Sym_Kind =>
                              Sem_Error (T, "Call on operation " &
                                Sym_Name (Non_Component_Sym_Found) &
                                " requires () in " &
                                Languages.Language_Name);
                           when others =>
                              Sem_Error (T,
                                Sym_Name (Non_Component_Sym_Found) &
                                " should be prefixed with name of enclosing " &
                                " type, not with name of an object");
                        end case;
                     else
                        --  Selector not meaningful
                        Sem_Error (T, "Specified component not defined");
                     end if;
                  end if;
               end if;
               Sel_Sem := new Selection_Semantic_Info;
            end if;
         else
            Sem_Error
              (T,
               "Not a valid prefix " & Subtree_Image (T.Prefix));
            Sel_Sem := null;
         end if;

         if Sel_Sem /= null then
            Sel_Sem.Definition := Optional (T'Access);
         end if;
         T.Sem_Info := Root_Sem_Ptr (Sel_Sem);

      end;

      --  Restore context
      Visitor.Context := Context;
   end Selection_Action;

   procedure Reference_Action
     (Visitor : in out Sem_Second_Pass_Visitor;
      T : in out Reference.Tree) is
      Comp_Sem : constant Computation_Sem_Ptr :=
        new Computation_Semantic_Info;
      Context : constant Context_Enum := Visitor.Context;
   begin
      T.Sem_Info := Root_Sem_Ptr (Comp_Sem);
      Comp_Sem.Definition := Optional (T'Access);

      --  Decide whether to visit the "key" at this point.
      case Context is
         when Statement_Contexts | Container_Agg_Context =>
            --  Case statement; container aggregate; TBD: others?

            --  Visit the key
            Visitor.Context := Operand_Context;
            Visit (T.Key, Visitor);

         when Exit_With_Values_Context =>
            --  The key should be a visible object
            --  TBD: Mutable_Context should allow assigning to uninited const
            Visitor.Context := Mutable_Context;
            Visit (T.Key, Visitor);

         when Module_Actual_Type_Context           |  --  type parameter of
                                                      --  instantiation
              Module_Implements_Interfaces_Context |  --  list of implemented
                                                      --  interfaces
              Operand_Contexts                     |  --  operand of call
              Class_Agg_Context                    |  --  component of
                                                      --  class aggregate
              Mutable_Context                      |  --  LHS of assignment
                                                      --  or mutable param
              Op_Context                           |
              Formal_Op_Context                    =>  --  operation of call
            --  Don't visit the key at this point.
            --  TBD: Need more contexts to distinguish [...] from (...)
            --      since we want to visit the key in [key => ...]
            --      but not in (key => ...)
            null;

         when Selector_Prefix_Context          |  --  obj of obj.selector
              Module_Context                   |  --  module of instantiation
              Module_Formal_Context            |  --  formal param of module
              Module_Formal_Type_Def_Context   |  --  formal type of module
              Module_Actual_Of_Formal_Context  |  --  actual to formal type
              Module_Extends_Interface_Context |  --  parent type
              Type_Context                     |  --  type for obj decl, etc.
              Operation_Input_Context          |  --  context for input decls
              Operation_Output_Context         |  --  context for output decls
              Interface_Item_Contexts          |
              Standalone_Item_Context          |
              Ancestor_Item_Contexts           |
              Local_Class_Item_Context         |
              Exported_Class_Item_Contexts     |
              Case_Choice_Context              =>

            pragma Assert (False);  --  Shouldn't have a "=>" here
            null;

      end case;

      --  Pass through context
      Visitor.Context := Context;
      Visit (T.Referent, Visitor);

      --  Carry results up
      declare
         Referent_Sem : constant Root_Sem_Ptr := Sem_Info (T.Referent);
      begin
         if Referent_Sem /= null
           and then Referent_Sem.all in Operand_Semantic_Info'Class
         then
            --  Propagate the resolved type and/or interps
            declare
               function Make_Reference
                 (Assoc_Type_Region : Type_Region_Ptr;
                  OT : Optional_Tree)
                  return Optional_Tree
               is
                  --  Wrap each interp in a reference
                  Ot_Sem : constant Root_Sem_Ptr := Sem_Info (OT);
                  Result : constant Optional_Tree :=
                    Reference.Make (T.Key, OT);
                  Result_Sem : constant Computation_Sem_Ptr :=
                    new Computation_Semantic_Info;
               begin
                  Result_Sem.Definition := Result;

                  if Ot_Sem /= null
                    and then Ot_Sem.all in Operand_Semantic_Info'Class
                  then
                     Result_Sem.Resolved_Type :=
                       Operand_Sem_Ptr (Ot_Sem).Resolved_Type;
                  end if;
                  Set_Sem_Info (Result, Root_Sem_Ptr (Result_Sem));
                  return Result;
               end Make_Reference;

               function Make_Reference_Interps is new
                 Interpretations.Propagate_Interps (
                  Make_Reference);
            begin
               if Context = Exit_With_Values_Context then
                  --  Key determines type of value
                  declare
                     Key_Type : Type_Sem_Ptr := null;
                  begin
                     Resolve_Expression (Visitor, T.Key, Key_Type);
                     Comp_Sem.Resolved_Type := Key_Type;
                     Resolve_Expression
                       (Visitor, T.Referent, Comp_Sem.Resolved_Type);
                     Comp_Sem.Resolved_Interp := Make_Reference
                       (null, Operand_Sem_Ptr
                          (Sem_Info (T.Referent)).Resolved_Interp);
                  end;
               else
                  --  Referent determines type
                  Comp_Sem.Resolved_Type :=
                    Operand_Sem_Ptr (Referent_Sem).Resolved_Type;

                  --  Build references around each interp.
                  Comp_Sem.Interps :=
                     Make_Reference_Interps
                       (Operand_Sem_Ptr (Referent_Sem).Interps);
               end if;
            end;
         end if;
      end;

      --  Restore context
      Visitor.Context := Context;
   end Reference_Action;

   ------- Local Subprograms --------

   procedure First_Pass
     (R : Symbols.Region_Ptr;
      Decl : Optional_Tree;
      Visiting_Operation_Outputs : Boolean := False;
      Processing_Inherited_Decl : Boolean := False) is
      --  Apply first pass to Decl
      use Ada.Text_IO;
      use PSC.Strings;
      Decl_Copy : Optional_Tree := Decl;
   begin
      if Is_Null (Decl) then
         --  Ignore empty Decl
         null;
      else
         declare
            First_Pass_Visitor : Sem_First_Pass_Visitor;
         begin
            First_Pass_Visitor.Decl_Region := R;
            First_Pass_Visitor.Visiting_Operation_Outputs :=
              Visiting_Operation_Outputs;
            First_Pass_Visitor.Processing_Inherited_Decl :=
              Processing_Inherited_Decl;
            Visit (Decl_Copy, First_Pass_Visitor);
         end;
      end if;
   end First_Pass;

   procedure First_Pass_List
     (R : Symbols.Region_Ptr;
      Decl_List : Lists.List;
      Visiting_Operation_Outputs : Boolean := False;
      Processing_Inherited_Decl : Boolean := False) is
   --  Apply First_Pass to each element in Decl_List
   begin
      for I in 1 .. Lists.Length (Decl_List) loop
         begin
            First_Pass
              (R,
               Lists.Nth_Element (Decl_List, I),
               Visiting_Operation_Outputs => Visiting_Operation_Outputs,
               Processing_Inherited_Decl => Processing_Inherited_Decl);
         exception
            when E : others =>
               Sem_Error
                 (Lists.Nth_Element (Decl_List, I),
                  "Internal: " &
                  Ada.Exceptions.Exception_Name (E) &
                  " raised in");
         end;
      end loop;
   end First_Pass_List;

   procedure Second_Pass
     (R : Symbols.Region_Ptr;
      Decl : Optional_Tree;
      Context : Context_Enum := No_Context;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      May_Override : Overriding_State := Unspecified;
      Mode : Analysis_Mode := Decls_And_Exprs;
      Decl_For_Annotations : Optional_Tree := Null_Optional_Tree) is
      --  Second pass for Decl
      use Ada.Text_IO;
      use PSC.Strings;
      Decl_Copy : Optional_Tree := Decl;
   begin
      if Is_Null (Decl) then
         --  Ignore empty Decl
         null;
      else
         declare
            Second_Pass_Visitor : Sem_Second_Pass_Visitor;
         begin
            Second_Pass_Visitor.Decl_Region := R;
            Second_Pass_Visitor.Context := Context;
            Second_Pass_Visitor.Formal_Prefix := Formal_Prefix;
            Second_Pass_Visitor.Mode := Mode;
            Second_Pass_Visitor.May_Override := May_Override;
            Second_Pass_Visitor.Decl_For_Annotations := Decl_For_Annotations;
            if Context in Statement_Contexts then
               --  Complain if Resolved_Type is not null.
               Visit_And_Resolve_Stmt (Decl_Copy, Second_Pass_Visitor);
            else
               Visit (Decl_Copy, Second_Pass_Visitor);
            end if;
         end;
      end if;
   end Second_Pass;

   procedure Second_Pass_List
     (R : Symbols.Region_Ptr;
      Decl_List : Lists.List;
      Context : Context_Enum := No_Context;
      Formal_Prefix : Optional_Tree := Null_Optional_Tree;
      May_Override : Overriding_State := Unspecified;
      Mode : Analysis_Mode := Decls_And_Exprs;
      Decl_For_Annotations : Optional_Tree := Null_Optional_Tree) is
   --  Apply Second_Pass to each element in Decl_List
   begin
      for I in 1 .. Lists.Length (Decl_List) loop
         begin
            Second_Pass
              (R,
               Lists.Nth_Element (Decl_List, I),
               Context => Context,
               Formal_Prefix => Formal_Prefix,
               May_Override => May_Override,
               Mode => Mode,
               Decl_For_Annotations => Decl_For_Annotations);
         exception
            when E : others =>
               Sem_Error
                 (Lists.Nth_Element (Decl_List, I),
                  "Internal: " &
                  Ada.Exceptions.Exception_Name (E) &
                  " raised in");
         end;
      end loop;
   end Second_Pass_List;

   procedure Init_Language_Specific_Info is
   --  This is called once at the beginning of processing after establishing
   --  the language being parsed, within the ParaSail "family" of languages.
   begin
      Any_Str :=
        Strings.String_Lookup (Languages.Any_Module_Name);

      Assignable_Str :=
        Strings.String_Lookup (Languages.Assignable_Module_Name);

      Boolean_Str :=
        Strings.String_Lookup (Languages.Boolean_Module_Name);

      Ordering_Str :=
        Strings.String_Lookup (Languages.Ordering_Module_Name);

      Univ_Integer_Str :=
        Strings.String_Lookup (Languages.Univ_Integer_Module_Name);

      Univ_Real_Str :=
        Strings.String_Lookup (Languages.Univ_Real_Module_Name);

      Univ_Character_Str :=
        Strings.String_Lookup (Languages.Univ_Character_Module_Name);

      Univ_String_Str :=
        Strings.String_Lookup (Languages.Univ_String_Module_Name);

      Univ_Enumeration_Str :=
        Strings.String_Lookup (Languages.Univ_Enumeration_Module_Name);

      Optional_Str :=
        Strings.String_Lookup (Languages.Optional_Module_Name);

      Null_Str :=
        Strings.String_Lookup (Languages.Null_Literal_Spelling);

      Integer_Str :=
        Strings.String_Lookup (Languages.Default_Integer_Module_Name);

      Float_Str :=
        Strings.String_Lookup (Languages.Default_Float_Module_Name);

      Basic_Array_Str :=
        Strings.String_Lookup (Languages.Basic_Array_Module_Name);

      From_Univ_Str :=
        Strings.String_Lookup (Languages.From_Univ_Op_Name);
      --  Operator for converting from a universal type

      To_Univ_Str :=
        Strings.String_Lookup (Languages.To_Univ_Op_Name);
      --  Operator for converting to a universal type

      Remove_First_Str :=
        Strings.String_Lookup (Languages.Remove_First_Op_Name);
      --  Operation for "forward" iteration through a set

      Remove_Last_Str :=
        Strings.String_Lookup (Languages.Remove_Last_Op_Name);
      --  Operation for "reverse" iteration through a set

      Remove_Any_Str :=
        Strings.String_Lookup (Languages.Remove_Any_Op_Name);
      --  Operation for "unordered" and "concurrent" iteration through a set

      Remove_Func_Strs :=
        (Interpreter.Unordered_Dir => Remove_Any_Str,
         Interpreter.Forward_Dir => Remove_First_Str,
         Interpreter.Reverse_Dir => Remove_Last_Str,
         Interpreter.Concurrent_Dir => Remove_Any_Str);
      --  U_String for name of operation used to
      --  remove elements from set in desired order,
      --  based on "direction" of iteration (forward/reverse/etc.)

   end Init_Language_Specific_Info;

end PSC.Trees.Semantics.Static;
