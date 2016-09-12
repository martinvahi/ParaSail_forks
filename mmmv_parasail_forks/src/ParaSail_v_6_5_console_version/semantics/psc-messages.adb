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

with Generic_Lists;
pragma Elaborate (Generic_Lists);

with PSC.Hash_Tables;
pragma Elaborate (PSC.Hash_Tables);

with PSC.Strings;

with Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;
package body PSC.Messages is

   Error_File : Ada.Text_IO.File_Type;  --  errors written here
   Error_File_Name : constant String := "errors.err";
   --  This file name is special to "vim -q"
   Error_File_Failed : Boolean := False;
   --  If True, then we failed trying to create error file.

   package Message_Lists is new Generic_Lists (Strings.U_String);
   --  List of messages associated with a given source position

   use type Source_Positions.Source_Position;

   package Message_Tables is new Hash_Tables
     (Element_Type => Message_Lists.List,
      Key_Type => Source_Positions.Source_Position,
      Hash_Type => Strings.Hash_Type,
      Hash => Source_Positions.Hash);

   Message_Table : Message_Tables.Hash_Table;
   --  Hash table of messages, indexed by source position

   procedure Message_Helper
     (S : String;
      Src_Pos : Source_Positions.Source_Position :=
        Source_Positions.Null_Source_Position;
      Message_Kind : String := "Error") is
      --  Produce an error message on the current error output.
      --  NOTE: This is called from Put_Message twice, once to write out
      --       to Standard_Error, and once to the Error_File.
      use Ada.Text_IO;
      use Source_Positions;
   begin
      if Src_Pos /= Null_Source_Position then
         Put (Current_Error, Source_Positions.Image (Src_Pos) & ' ');
      end if;
      Put_Line (Current_Error, Message_Kind & ": " & S);
      Flush (Current_Error);
   end Message_Helper;

   ----------------  Visible Subprograms  -----------------

   procedure Put_Message
     (S : String;
      Src_Pos : Source_Positions.Source_Position;
      Message_Kind : String) is
      --  Produce a message on the standard error output.
      use Ada.Text_IO;
   begin
      if Src_Pos /= Source_Positions.Null_Source_Position then
         --  Check whether we have already put out this message

         declare
            use Message_Tables;
            Message_U_Str : Strings.U_String :=
              Strings.String_Lookup (Message_Kind & ": " & S);
            Existing_Elem : Element_Ref :=
              Find_Element (Message_Table, Src_Pos);
            New_Elem : Message_Lists.List;

            function Matches
              (Old_Result : Boolean; Next_Str : Strings.U_String)
              return Boolean is
               --  Return True if Old_Result already True,
               --  or Next_Str matches the new message
               use type Strings.U_String;
            begin
               return Old_Result or else
                 Next_Str = Message_U_Str;
            end Matches;

            function Is_Present is new Message_Lists.Apply_Function
              (Result_Type => Boolean,
               New_Result => Matches,
               Initial_Result => False,
               Quit_On_Result => True);
            --  Scan list and return True if Message_U_Str already there

         begin
            if Existing_Elem = null then
               --  First message at this Src_Pos
               Enter_Element (Message_Table,
                              Key => Src_Pos,
                              Elem => Message_Lists.Make
                                        ((1 => Message_U_Str)),
                              Existing_Elem => Existing_Elem);
            elsif Is_Present (Existing_Elem.all) then
               return;  --------  Message already present  --------
            else
               --  Add to end of list of messages for this Src_Pos
               --  Add message to end of list
               Message_Lists.Append (Existing_Elem.all, Message_U_Str);
            end if;
         end;
      end if;

      --  First put out to Standard_Error
      Set_Error (Standard_Error);
      Message_Helper (S, Src_Pos, Message_Kind);

      --  Now put out to error file
      if not Error_File_Failed then
         begin
            if not Is_Open (Error_File) then
               --  First error, create the file.
               Create (Error_File, Out_File, Error_File_Name);
            end if;

            --  Now write out the message
            Set_Error (Error_File);
            Message_Helper (S, Src_Pos, Message_Kind);
            Flush (Error_File);
            Set_Error (Standard_Error);
         exception
            when E : others =>
               Error_File_Failed := True;  --  Don't try again
               Set_Error (Standard_Error);
               Put_Line
                 (Current_Error,
                  "Cannot create message file '" &
                  Error_File_Name &
                  "', exception " &
                  Ada.Exceptions.Exception_Name (E) &
                  " raised.");
               Flush (Standard_Error);
         end;
      end if;
   end Put_Message;

   procedure Parser_Error (S : String := "syntax error";
     Src_Pos : Source_Positions.Source_Position :=
       Source_Positions.Null_Source_Position) is
      Error_Col : constant Ada.Text_IO.Positive_Count := Col;
   begin
      Number_Of_Errors := Number_Of_Errors + 1;
      Put ("<<< *** error: ");
      Put_Line (S);
      Put_Message (S, Src_Pos => Src_Pos, Message_Kind => "Error");
      Set_Col (Error_Col);  -- Return to same column
   end Parser_Error;

   procedure Parser_Warning (S : String;
     Src_Pos : Source_Positions.Source_Position :=
       Source_Positions.Null_Source_Position) is
      Error_Col : constant Ada.Text_IO.Positive_Count := Col;
   begin
      if Number_Of_Errors = 0 then  --  Only give warnings if no errors
         Put ("<<< warning: ");
         Put_Line (S);
         Put_Message (S, Src_Pos => Src_Pos, Message_Kind => "Warning");
         Set_Col (Error_Col);  -- Return to same column
      end if;
   end Parser_Warning;

end PSC.Messages;
