pragma Style_Checks(Off);
-- Copyright (c) 1990 Regents of the University of California.
-- All rights reserved.
--
--    The primary authors of ayacc were David Taback and Deepak Tolani.
--    Enhancements were made by Ronald J. Schmalz.
--
--    Send requests for ayacc information to ayacc-info@ics.uci.edu
--    Send bug reports for ayacc to ayacc-bugs@ics.uci.edu
--
-- Redistribution and use in source and binary forms are permitted
-- provided that the above copyright notice and this paragraph are
-- duplicated in all such forms and that any documentation,
-- advertising materials, and other materials related to such
-- distribution and use acknowledge that the software was developed
-- by the University of California, Irvine.  The name of the
-- University may not be used to endorse or promote products derived
-- from this software without specific prior written permission.
-- THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
-- IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

-- Module       : stack.ada
-- Component of : ayacc
-- Version      : 1.2
-- Date         : 11/21/86  12:36:24
-- SCCS File    : disk21~/rschm/hasee/sccs/ayacc/sccs/sxstack.ada

-- $Header: /Users/stt/_parasail/_aflex_ayacc/_adamagic/ayacc/RCS/stack.adb,v 1.1 2011/03/02 22:15:02 stt Exp stt $ 
-- $Log: stack.adb,v $
-- Revision 1.1  2011/03/02 22:15:02  stt
-- Initial revision
--
-- Revision 0.1  86/04/01  15:12:46  ada
--  This version fixes some minor bugs with empty grammars 
--  and $$ expansion. It also uses vads5.1b enhancements 
--  such as pragma inline. 
-- 
-- 
-- Revision 0.0  86/02/19  18:42:12  ada
-- 
-- These files comprise the initial version of Ayacc
-- designed and implemented by David Taback and Deepak Tolani.
-- Ayacc has been compiled and tested under the Verdix Ada compiler
-- version 4.06 on a vax 11/750 running Unix 4.2BSD.
--  


--                                                                      --
--  Authors   : David Taback , Deepak Tolani                            --
--  Copyright : 1987, University of California Irvine                   --
--                                                                      -- 
--  If you    -- 
--  modify the source code or if you have any suggestions or questions  -- 
--  regarding ayacc, we would like to hear from you. Our mailing        -- 
--  addresses are :                                                     -- 
--      taback@icsc.uci.edu                                             -- 
--      tolani@icsc.uci.edu                                             --   
--                                                                      --  

generic 
    type Element is private; 

package Stack_Pack is 

    type Stack is limited private; 

    Stack_Underflow : exception; 

    function Top_Value (S: in Stack) return Element; 

    function Depth_of_Stack (S: in Stack) return Natural; 

    procedure Make_Stack(S: out Stack); 

    procedure Push(S: in out Stack; Value: in Element); 

    procedure Pop (S: in out Stack; Value: out Element); 

    procedure Free_Stack(S: in out Stack); 

private 

    type Node; 

    type Link is access Node; 
    pragma Controlled(Link); 

    type Stack is 
        record 
            Tos    : Natural; 
            Top    : Link; 
            Extras : Link; 
        end record; 
 
end Stack_Pack; 
