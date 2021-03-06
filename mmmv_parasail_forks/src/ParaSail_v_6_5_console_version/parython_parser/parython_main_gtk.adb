------------------------------------------------------------------------------
--                              P A R Y T H O N                             --
--                                                                          --
--                     Copyright (C) 2012-2013, AdaCore                     --
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
------------------------------------------------------------------------------

pragma Style_Checks (Off);

with Parython_Main;
--with PSC.Interpreter.GTK; --  Pull in GTK builtins
--with PSC.Interpreter.Cairo;  --  Pull in Cairo builtins
procedure Parython_Main_GTK is
--  Version of Parython which includes builtins for GTK graphics
begin
   Parython_Main;
end Parython_Main_GTK;
