
pragma Style_Checks (Off);
package body parasail_lex is

  --  Indicates whether outdenting should expect a perfect col-count match
  Col_Match_Expected : Boolean := True;

  Max_Depth : constant := 100;
  Indent_Stack : array(Positive range 1 .. Max_Depth) of Natural :=
    (others => 0);
  Bracketing_Token_Stack : array(Positive range 1 .. Max_Depth) of Token :=
    (others => Error);

  procedure ECHO_L(YYT : String := yytext) is
  --
  -- Local version of the  define string.
  -- 
  begin
     Echo_Token (YYT);
     --  We normally expect an exact match
     Col_Match_Expected := True;
  end ECHO_L;

  function Create_Token(Text : String := yytext) return YYSType is
     Src_Pos : Source_Position := Cur_Source_Pos;
  begin
     --  Point to beginning of token
     Src_Pos.Col := Column_Number'Max (1, Src_Pos.Col - Text'Length + 1);
     --  TBD: "gcc" prefers column count rather than character count

     if Debug_Indent and then Expecting_Indent then
        Text_IO.Put (" [CT: indent off] ");
     end if;
     Expecting_Indent := False;

     --  Create a token for the parser.
     return (One_Token, Src_Pos, String_Lookup(Text));
  end Create_Token;
     
function YYLex return Token is
subtype short is integer range -32768..32767;
    yy_act : integer;
    yy_c : short;

-- returned upon end-of-file
YY_END_TOK : constant integer := 0;
YY_END_OF_BUFFER : constant := 158;
subtype yy_state_type is integer;
yy_current_state : yy_state_type;
INITIAL : constant := 0;
TICK : constant := 1;
CHARLIT : constant := 2;
AFTER_IMPLEMENTS : constant := 3;
OUTDENTING : constant := 4;
RESCANNING : constant := 5;
yy_accept : constant array(0..542) of short :=
    (   0,
        0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
        0,    0,  158,  156,  146,  155,  156,  156,  156,  112,
      113,  122,  123,  124,  125,  126,  127,  136,  136,  129,
      130,  116,  133,  117,  132,  134,  114,  115,  134,  134,
      134,  134,  134,  134,  134,  134,  134,  134,  134,  134,
      134,  134,  134,  134,  134,  134,  134,  134,  134,  118,
      131,  120,    6,  134,  134,  134,  134,  134,  134,  134,
      134,  134,  131,  111,  156,    6,  152,  157,  152,  152,
      152,  152,  152,  157,  157,  157,  157,  157,  157,  157,
      157,  157,  157,  146,  155,    0,    0,    0,   80,    0,

      143,    0,  144,  135,   84,  100,  110,   98,  145,   99,
       94,  110,   88,  101,    0,    0,  136,    0,    0,    0,
        0,    0,  128,    0,  110,    0,   92,   85,    0,   83,
       82,    0,  121,   79,   93,   78,   81,    0,  134,  134,
      134,  134,  134,  134,  134,  134,  134,  134,  134,  134,
      134,  134,  134,  134,  134,   44,  134,   47,   49,  134,
      134,  134,  134,  134,  134,   58,   59,   62,  134,  134,
      134,  134,  134,  134,  134,  134,  134,  134,  134,  119,
      103,   97,    6,    0,    0,    0,    0,    0,    0,  134,
      134,  134,  134,  134,  134,  134,  134,   47,  134,    6,

      134,   97,    0,    0,    6,    0,  151,    0,    0,    0,
      150,    0,    0,    0,    0,    0,    0,    0,    0,    0,
        0,   15,    0,   96,  144,  135,  102,  145,   91,    0,
      137,  141,    0,  136,  140,    0,   90,  108,   86,   87,
      104,   95,  109,   16,   18,   19,  134,  134,  134,  134,
      134,   42,  134,  134,  134,   34,  134,  134,  134,   39,
      134,  134,  134,  134,  134,  134,  134,   53,   55,   56,
      134,   60,  106,  134,  134,   65,   66,  134,  134,  134,
      134,  134,  134,   74,  134,  134,   77,    4,    0,    0,
        0,    0,    0,   16,  134,  134,    6,    6,  134,  134,

      134,  134,   55,  134,    3,  142,    0,    0,    0,    0,
        0,    0,    0,   12,   10,    0,    0,    0,    0,   54,
        0,  138,    0,    0,    0,  137,    0,    0,  141,    0,
      136,    0,  140,    0,    0,   89,  134,  105,  134,  134,
       22,  134,  134,  134,  134,   27,   30,   28,  134,  134,
       35,  134,  134,  134,   41,  134,  134,  134,  134,  134,
      134,   52,   57,  134,  134,  134,  134,  134,   69,   71,
       72,  134,  134,   76,  107,    0,    1,    0,  134,  134,
      134,  134,    6,  134,  134,   71,    0,    0,  149,    0,
        0,    0,    0,    0,   11,    0,    0,   70,    0,    0,

        0,  137,  134,   20,   21,   23,  134,   25,  134,    0,
      134,   32,   33,  134,  134,  134,  134,  134,  134,  134,
      134,  134,  134,  134,  134,  134,  134,   73,   75,    0,
      134,    6,  134,  134,  134,  134,    5,    0,  147,    0,
        8,    0,    0,    0,    0,    0,  138,  139,    0,    0,
      137,    0,  134,  134,  134,    0,   29,  134,  134,  134,
       43,  134,   46,  134,   50,   51,  134,  134,   64,   67,
      134,    0,  134,  134,  134,    6,  134,    0,    0,    0,
        0,   13,    0,  138,    0,    0,  134,  134,  134,   31,
       37,   38,   40,  134,  134,  134,   63,   68,    0,  134,

      134,   37,  134,    0,    0,    0,   36,    0,    0,  139,
       17,  134,   26,  134,  134,   61,    0,    6,  134,    2,
      134,    0,    7,    0,    0,  139,    0,  134,  134,   48,
      134,    6,    0,    0,   14,   24,   45,    6,    0,    9,
      148,    0
    ) ;

yy_ec : constant array(ASCII.NUL..Character'Last) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    2,    3,
        1,    2,    2,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    4,    5,    6,    7,    1,    1,    1,    8,    9,
       10,   11,   12,   13,   14,   15,   16,   17,   18,   18,
       18,   18,   18,   18,   18,   18,   18,   19,   20,   21,
       22,   23,   24,    1,   25,   26,   25,   25,   27,   25,
       28,   28,   28,   28,   28,   28,   28,   28,   28,   28,
       28,   28,   28,   28,   28,   28,   28,   29,   28,   28,
       30,   31,   32,    1,   33,    1,   34,   35,   36,   37,

       38,   39,   40,   41,   42,   28,   43,   44,   45,   46,
       47,   48,   49,   50,   51,   52,   53,   54,   55,   56,
       57,   28,   58,   59,   60,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,

        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1
    ) ;

yy_meta : constant array(0..60) of short :=
    (   0,
        1,    2,    3,    2,    1,    1,    4,    5,    1,    1,
        6,    1,    1,    1,    7,    1,    8,    8,    1,    1,
        1,    6,    1,    1,    9,    9,    9,   10,   10,    1,
        1,    1,   11,    9,    9,    9,    9,    9,    9,   10,
       10,   10,   10,   10,   10,   10,   10,   10,   10,   10,
       10,   10,   10,   10,   10,   10,   10,    1,    1,    1
    ) ;

yy_base : constant array(0..560) of short :=
    (   0,
        0,   59,  833,  832,  831,  830,  829,   60,   62,   67,
        0,   93,  836,  842,   72,  842,  813,   63,   78,  842,
      842,   61,   62,  842,   77,   75,   94,  146,  129,  184,
      842,  133,  100,   80,  842,    0,  842,  842,  114,   90,
       73,  796,  134,   90,  789,  120,   78,  785,  104,  135,
      781,  777,  791,  781,  141,  781,  792,  128,  778,  801,
      154,  842,  212,  164,  160,  785,  178,  142,  186,  180,
      190,  160,  183,  842,  791,  207,  842,  842,    0,  776,
      782,  778,  759,  782,   45,  778,  174,  762,  190,  776,
      765,  771,  752,  241,  842,  245,  796,  793,  842,  250,

      842,  805,    0,    0,  785,  842,  842,  842,    0,  842,
      842,  791,  784,  842,    0,  242,  255,  248,  262,    0,
      250,  282,  842,  288,  785,  787,  842,  842,  787,  779,
      255,  778,  842,  776,  842,  842,  842,  776,    0,  746,
      752,  758,  754,  746,  741,  757,  744,  750,  752,   99,
      750,  249,  736,  739,  737,    0,  735,  730,    0,  736,
      247,  743,  724,  726,  733,    0,  724,  753,  732,  735,
      257,  727,  733,  722,  717,  718,  725,  714,  715,  842,
      842,  842,    0,    0,  708,  712,  724,  720,  701,  708,
      724,  711,  717,  718,  258,  708,  705,  700,  696,  698,

      711,  301,  740,  130,    0,  700,  842,  698,  690,  706,
      842,  692,  708,  695,  701,  702,  690,  691,  688,  683,
      679,  842,  695,  842,    0,    0,  842,    0,  842,  254,
      290,  296,  298,  301,  699,  728,  709,  842,  842,  842,
      842,  842,  842,  677,    0,  706,  685,  690,  687,  673,
      284,    0,  682,  683,   29,  679,  668,  672,  680,  662,
      680,  680,  277,  676,  678,  669,  663,    0,    0,    0,
      666,  667,  842,  654,  654,    0,    0,  653,  667,  666,
      657,  664,  659,    0,  656,  658,  676,  842,  649,  323,
      641,  657,  328,  642,  642,  286,    0,  650,  644,  654,

      295,  651,  341,  642,  842,  842,  637,  642,  344,  639,
      632,  632,  646,  842,  842,  634,  644,  632,  640,  842,
      631,  313,    0,  326,  342,  335,  346,  337,  348,  352,
      354,  359,  643,  642,  671,  842,  623,  842,  626,  628,
        0,  619,  616,  616,  625,    0,    0,  308,  627,  626,
        0,  614,  617,  628,    0,  627,  622,  609,  608,  620,
      618,    0,    0,  608,  620,  615,  602,  601,    0,    0,
        0,  606,  611,    0,  842,  601,  842,  601,  596,  594,
      591,  593,    0,  592,  591,  376,  380,  602,  842,  386,
      589,  587,  584,  586,  842,  585,  584,  842,  379,  367,

      368,  377,  599,    0,    0,    0,  582,    0,  585,  588,
      590,    0,    0,  576,  590,  576,  581,  579,  571,  583,
      587,  583,  573,  566,  580,  570,  564,    0,    0,  564,
      579,    0,  562,  559,  558,  570,  842,  563,  842,  573,
      842,  556,  553,  552,  564,  381,  384,  329,  385,  396,
      387,  389,  566,  551,  547,  560,    0,  547,  546,  559,
        0,  556,    0,  557,    0,    0,  556,  551,    0,    0,
      535,  517,  529,  514,  506,    0,  505,  486,  480,  454,
      442,  842,  458,  391,  394,  409,  439,  452,  450,  842,
        0,    0,    0,  406,  415,  406,    0,    0,  398,  395,

      408,  411,  409,  398,  376,  387,  842,  386,  413,  415,
        0,  373,    0,  364,  323,    0,  432,    0,  253,  842,
      237,  211,  842,  205,  203,  420,  422,  187,  170,    0,
      145,    0,  126,   63,  842,    0,    0,    0,  439,  842,
      842,  842,  453,  464,  475,  485,  488,  499,  510,  521,
      525,  536,  540,  542,  551,  559,  563,  574,  578,  584
    ) ;

yy_def : constant array(0..560) of short :=
    (   0,
      542,    1,    1,    2,    1,    2,    1,    2,  543,  543,
      544,  544,  542,  542,  542,  542,  542,  545,  546,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  547,  542,  542,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  542,
      542,  542,  542,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  542,  542,  548,   63,  542,  542,  549,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  545,

      542,  545,  550,  551,  542,  542,  542,  542,  552,  542,
      542,  542,  542,  542,  553,  542,  542,  542,  542,  554,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  542,
      542,  542,   63,  555,  542,  542,  542,  542,  542,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,

      547,  542,  542,  548,   76,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  550,  551,  542,  552,  542,  556,
      542,  542,  542,  542,  557,  558,  542,  542,  542,  542,
      542,  542,  542,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  542,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  542,  542,  542,
      542,  542,  542,  547,  547,  547,  547,  547,  547,  547,

      547,  547,  547,  547,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  559,  556,  556,  542,  542,  542,  542,  542,
      542,  542,  557,  557,  558,  542,  547,  542,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  542,  542,  542,  542,  547,  547,
      547,  547,  547,  547,  547,  547,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  560,

      542,  542,  547,  547,  547,  547,  547,  547,  547,  542,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  542,
      547,  547,  547,  547,  547,  547,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  560,  560,
      542,  542,  547,  547,  547,  542,  547,  547,  547,  547,
      547,  547,  547,  547,  547,  547,  547,  547,  547,  547,
      547,  542,  547,  547,  547,  547,  547,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  547,  547,  547,  542,
      547,  547,  547,  547,  547,  547,  547,  547,  542,  547,

      547,  547,  547,  542,  542,  542,  542,  542,  542,  542,
      547,  547,  547,  547,  547,  547,  542,  547,  547,  542,
      547,  542,  542,  542,  542,  542,  542,  547,  547,  547,
      547,  547,  542,  542,  542,  547,  547,  547,  542,  542,
      542,    0,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542
    ) ;

yy_nxt : constant array(0..902) of short :=
    (   0,
       14,   15,   16,   15,   17,   18,   19,   14,   20,   21,
       22,   23,   24,   25,   26,   27,   28,   29,   30,   31,
       32,   33,   34,   35,   36,   36,   36,   36,   36,   37,
       14,   38,   14,   39,   40,   41,   42,   43,   44,   45,
       36,   46,   36,   47,   48,   49,   50,   51,   52,   53,
       54,   55,   56,   57,   58,   59,   36,   60,   61,   62,
       63,   76,   63,   76,   78,  101,  348,   75,  101,   78,
      349,  105,   79,   94,   95,   94,  107,   79,   96,  103,
      107,  103,  106,  108,  103,   97,  112,   98,  213,  113,
      109,  214,   64,  102,   65,   66,   67,   68,  110,  111,

       69,  137,  138,   80,   70,   71,  145,   81,   80,  103,
       72,  160,   81,   82,  540,  114,  146,   73,   82,  147,
       83,  134,  135,  136,  161,   83,   84,  143,   85,   86,
       87,   88,  542,  144,   89,  115,  153,  203,   90,   91,
      254,  163,  154,  116,   92,  117,  117,  129,  140,  255,
      164,   93,  115,  130,  131,  119,  165,  141,  156,  142,
      116,  121,  117,  117,  157,  158,  119,  149,  177,  178,
      159,  118,  119,  166,  120,  181,  539,  150,  121,  151,
      118,  173,  167,  119,  168,  122,  123,  122,  153,  152,
      124,  132,  133,  145,  196,  125,  538,  174,  190,  126,

      201,  120,  127,  191,  181,  128,  192,  141,  205,  142,
      205,  149,  182,  183,   95,  183,  174,  199,   96,  216,
      537,  150,  184,  194,  156,   97,  164,   98,  166,  217,
      197,  198,  165,  195,  219,  220,  159,  200,  536,  168,
      535,  202,   94,   95,   94,  206,  103,   96,  103,  185,
      534,  103,  101,  186,   97,  101,   98,  187,  231,  231,
      322,  115,  533,  188,  232,  232,  117,  117,  323,  116,
      189,  117,  117,  233,  532,  233,  239,  240,  234,  234,
      102,  119,  266,  122,  123,  122,  325,  121,  124,  236,
      257,  236,  119,  267,  236,  276,  258,  126,  531,  257,

      259,  277,  305,  305,  305,  299,  326,  326,  278,  259,
      279,  410,  329,  329,  234,  234,  327,  331,  331,  343,
      357,  381,  328,  358,  377,  377,  377,  327,  330,  305,
      305,  305,  322,  332,  344,  345,  344,  345,  357,  399,
      323,  384,  305,  305,  305,  389,  389,  389,  542,  411,
      399,  326,  326,  326,  326,  486,  542,  401,  325,  401,
      530,  327,  402,  402,  329,  329,  486,  328,  329,  329,
      331,  331,  327,  448,  542,  331,  331,  305,  305,  305,
      330,  437,  437,  437,  402,  402,  332,  439,  439,  439,
      446,  448,  446,  451,  451,  447,  447,  447,  447,  450,

      484,  484,  542,  451,  451,  451,  451,  484,  484,  452,
      484,  484,  520,  520,  520,  529,  485,  450,  528,  452,
      509,  525,  509,  485,  524,  510,  510,  523,  542,  510,
      510,  526,  526,  520,  520,  520,  526,  526,  526,  526,
      541,  541,  541,  522,  521,  519,  518,  527,  517,  516,
      515,  514,  527,   77,   77,   77,   77,   77,   77,   77,
       77,   77,   77,   77,   78,   78,   78,   78,   78,   78,
       78,   78,   78,   78,   78,  100,  100,  100,  100,  100,
      100,  100,  100,  100,  100,  100,  104,  513,  104,  512,
      511,  508,  507,  104,  104,  139,  139,  139,  139,  203,

      203,  203,  203,  506,  203,  203,  203,  203,  203,  203,
      207,  207,  207,  207,  207,  505,  207,  207,  207,  207,
      207,  225,  225,  504,  225,  225,  225,  225,  225,  225,
      225,  225,  226,  226,  226,  226,  228,  228,  503,  228,
      228,  228,  228,  228,  228,  228,  228,  230,  230,  235,
      235,  288,  288,  288,  288,  288,  502,  288,  288,  288,
      288,  288,  324,  501,  500,  324,  324,  324,  499,  324,
      333,  333,  498,  333,  335,  335,  335,  335,  335,  335,
      335,  335,  335,  335,  335,  400,  400,  449,  497,  496,
      495,  449,  449,  494,  449,  493,  492,  491,  490,  489,

      488,  487,  483,  482,  481,  480,  479,  478,  477,  476,
      475,  474,  473,  472,  471,  470,  469,  468,  467,  466,
      465,  464,  463,  462,  461,  460,  459,  458,  457,  456,
      455,  454,  453,  445,  444,  443,  442,  441,  440,  438,
      436,  435,  434,  433,  432,  431,  293,  430,  429,  428,
      427,  426,  425,  424,  423,  422,  421,  420,  419,  418,
      417,  416,  415,  414,  413,  412,  409,  408,  407,  406,
      405,  404,  403,  123,  542,  334,  398,  397,  396,  395,
      394,  393,  392,  391,  390,  388,  387,  386,  385,  383,
      382,  350,  380,  379,  378,  293,  376,  375,  374,  373,

      372,  371,  370,  369,  368,  367,  366,  365,  364,  363,
      362,  361,  360,  359,  356,  355,  354,  353,  352,  351,
      350,  347,  346,  342,  341,  340,  339,  338,  337,  336,
      123,  334,  321,  320,  319,  318,  317,  316,  315,  314,
      313,  312,  311,  310,  309,  308,  307,  306,  304,  272,
      303,  302,  301,  300,  298,  297,  296,  295,  294,  293,
      292,  291,  290,  289,  287,  286,  285,  284,  283,  282,
      281,  280,  275,  274,  273,  272,  271,  270,  269,  268,
      265,  264,  263,  262,  261,  260,  256,  253,  252,  251,
      250,  249,  248,  247,  246,  245,  244,  243,  242,  241,

      238,  237,  236,  107,  229,  107,  227,  542,  103,  109,
      224,  223,  222,  221,  218,  215,  212,  211,  210,  209,
      208,  204,  193,  180,  179,  176,  175,  172,  171,  170,
      169,  162,  155,  148,   99,  542,   75,   75,   75,   74,
       74,   13,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,

      542,  542
    ) ;

yy_chk : constant array(0..902) of short :=
    (   0,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
        2,    8,    2,    8,    9,   18,  255,    8,   18,   10,
      255,   22,    9,   15,   15,   15,   23,   10,   15,   19,
       23,   19,   22,   23,   19,   15,   26,   15,   85,   26,
       25,   85,    2,   18,    2,    2,    2,    2,   25,   25,

        2,   34,   34,    9,    2,    2,   41,    9,   10,   27,
        2,   47,   10,    9,  534,   27,   41,    2,   10,   41,
        9,   33,   33,   33,   47,   10,   12,   40,   12,   12,
       12,   12,  204,   40,   12,   29,   44,  204,   12,   12,
      150,   49,   44,   29,   12,   29,   29,   32,   39,  150,
       49,   12,   28,   32,   32,   29,   49,   39,   46,   39,
       28,   29,   28,   28,   46,   46,   29,   43,   58,   58,
       46,   28,   28,   50,   28,   61,  533,   43,   28,   43,
       28,   55,   50,   28,   50,   30,   30,   30,   68,   43,
       30,   32,   32,   65,   68,   30,  531,   55,   64,   30,

       72,   28,   30,   65,   73,   30,   65,   64,   76,   64,
       76,   67,   61,   63,   63,   63,   72,   70,   63,   87,
      529,   67,   63,   67,   69,   63,   70,   63,   71,   87,
       69,   69,   70,   67,   89,   89,   69,   71,  528,   71,
      525,   73,   94,   94,   94,   76,   96,   94,   96,   63,
      524,   96,  100,   63,   94,  100,   94,   63,  116,  116,
      230,  117,  522,   63,  118,  118,  121,  121,  230,  117,
       63,  117,  117,  119,  521,  119,  131,  131,  119,  119,
      100,  117,  161,  122,  122,  122,  230,  117,  122,  124,
      152,  124,  117,  161,  124,  171,  152,  122,  519,  195,

      152,  171,  202,  202,  202,  195,  231,  231,  171,  195,
      171,  348,  232,  232,  233,  233,  231,  234,  234,  251,
      263,  296,  231,  263,  290,  290,  290,  231,  232,  293,
      293,  293,  324,  234,  251,  251,  296,  296,  301,  322,
      324,  301,  303,  303,  303,  309,  309,  309,  325,  348,
      322,  326,  326,  328,  328,  448,  325,  327,  324,  327,
      515,  326,  327,  327,  329,  329,  448,  326,  330,  330,
      331,  331,  326,  400,  325,  332,  332,  386,  386,  386,
      329,  387,  387,  387,  401,  401,  331,  390,  390,  390,
      399,  449,  399,  402,  402,  399,  399,  446,  446,  400,

      447,  447,  450,  451,  451,  452,  452,  484,  484,  402,
      485,  485,  502,  502,  502,  514,  447,  449,  512,  451,
      486,  508,  486,  484,  506,  486,  486,  505,  450,  509,
      509,  510,  510,  517,  517,  517,  526,  526,  527,  527,
      539,  539,  539,  504,  503,  501,  500,  510,  499,  496,
      495,  494,  526,  543,  543,  543,  543,  543,  543,  543,
      543,  543,  543,  543,  544,  544,  544,  544,  544,  544,
      544,  544,  544,  544,  544,  545,  545,  545,  545,  545,
      545,  545,  545,  545,  545,  545,  546,  489,  546,  488,
      487,  483,  481,  546,  546,  547,  547,  547,  547,  548,

      548,  548,  548,  480,  548,  548,  548,  548,  548,  548,
      549,  549,  549,  549,  549,  479,  549,  549,  549,  549,
      549,  550,  550,  478,  550,  550,  550,  550,  550,  550,
      550,  550,  551,  551,  551,  551,  552,  552,  477,  552,
      552,  552,  552,  552,  552,  552,  552,  553,  553,  554,
      554,  555,  555,  555,  555,  555,  475,  555,  555,  555,
      555,  555,  556,  474,  473,  556,  556,  556,  472,  556,
      557,  557,  471,  557,  558,  558,  558,  558,  558,  558,
      558,  558,  558,  558,  558,  559,  559,  560,  468,  467,
      464,  560,  560,  462,  560,  460,  459,  458,  456,  455,

      454,  453,  445,  444,  443,  442,  440,  438,  436,  435,
      434,  433,  431,  430,  427,  426,  425,  424,  423,  422,
      421,  420,  419,  418,  417,  416,  415,  414,  411,  410,
      409,  407,  403,  397,  396,  394,  393,  392,  391,  388,
      385,  384,  382,  381,  380,  379,  378,  376,  373,  372,
      368,  367,  366,  365,  364,  361,  360,  359,  358,  357,
      356,  354,  353,  352,  350,  349,  345,  344,  343,  342,
      340,  339,  337,  335,  334,  333,  321,  319,  318,  317,
      316,  313,  312,  311,  310,  308,  307,  304,  302,  300,
      299,  298,  295,  294,  292,  291,  289,  287,  286,  285,

      283,  282,  281,  280,  279,  278,  275,  274,  272,  271,
      267,  266,  265,  264,  262,  261,  260,  259,  258,  257,
      256,  254,  253,  250,  249,  248,  247,  246,  244,  237,
      236,  235,  223,  221,  220,  219,  218,  217,  216,  215,
      214,  213,  212,  210,  209,  208,  206,  203,  201,  200,
      199,  198,  197,  196,  194,  193,  192,  191,  190,  189,
      188,  187,  186,  185,  179,  178,  177,  176,  175,  174,
      173,  172,  170,  169,  168,  167,  165,  164,  163,  162,
      160,  158,  157,  155,  154,  153,  151,  149,  148,  147,
      146,  145,  144,  143,  142,  141,  140,  138,  134,  132,

      130,  129,  126,  125,  113,  112,  105,  102,   98,   97,
       93,   92,   91,   90,   88,   86,   84,   83,   82,   81,
       80,   75,   66,   60,   59,   57,   56,   54,   53,   52,
       51,   48,   45,   42,   17,   13,    7,    6,    5,    4,
        3,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,
      542,  542,  542,  542,  542,  542,  542,  542,  542,  542,

      542,  542
    ) ;


-- copy whatever the last rule matched to the standard output

procedure ECHO is
begin
   if (text_io.is_open(user_output_file)) then
     text_io.put( user_output_file, yytext );
   else
     text_io.put( yytext );
   end if;
end ECHO;

-- enter a start condition.
-- Using procedure requires a () after the ENTER, but makes everything
-- much neater.

procedure ENTER( state : integer ) is
begin
     yy_start := 1 + 2 * state;
end ENTER;

-- action number for EOF rule of a given start state
function YY_STATE_EOF(state : integer) return integer is
begin
     return YY_END_OF_BUFFER + state + 1;
end YY_STATE_EOF;

-- return all but the first 'n' matched characters back to the input stream
procedure yyless(n : integer) is
begin
        yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
        yy_cp := yy_bp + n;
        yy_c_buf_p := yy_cp;
        YY_DO_BEFORE_ACTION; -- set up yytext again
end yyless;

-- redefine this if you have something you want each time.
procedure YY_USER_ACTION is
begin
        null;
end;

-- yy_get_previous_state - get the state just before the EOB char was reached

function yy_get_previous_state return yy_state_type is
    yy_current_state : yy_state_type;
    yy_c : short;
    yy_bp : integer := yytext_ptr;
begin
    yy_current_state := yy_start;
    if ( yy_ch_buf(yy_bp-1) = ASCII.LF ) then
	yy_current_state := yy_current_state + 1;
    end if;

    for yy_cp in yytext_ptr..yy_c_buf_p - 1 loop
	yy_c := yy_ec(yy_ch_buf(yy_cp));
	if ( yy_accept(yy_current_state) /= 0 ) then
	    yy_last_accepting_state := yy_current_state;
	    yy_last_accepting_cpos := yy_cp;
	end if;
	while ( yy_chk(yy_base(yy_current_state) + yy_c) /= yy_current_state ) loop
	    yy_current_state := yy_def(yy_current_state);
	    if ( yy_current_state >= 543 ) then
		yy_c := yy_meta(yy_c);
	    end if;
	end loop;
	yy_current_state := yy_nxt(yy_base(yy_current_state) + yy_c);
    end loop;

    return yy_current_state;
end yy_get_previous_state;

procedure yyrestart( input_file : file_type ) is
begin
   open_input(text_io.name(input_file));
end yyrestart;

begin -- of YYLex
<<new_file>>
        -- this is where we enter upon encountering an end-of-file and
        -- yywrap() indicating that we should continue processing

    if ( yy_init ) then
        if ( yy_start = 0 ) then
            yy_start := 1;      -- first start state
        end if;

        -- we put in the '\n' and start reading from [1] so that an
        -- initial match-at-newline will be true.

        yy_ch_buf(0) := ASCII.LF;
        yy_n_chars := 1;

        -- we always need two end-of-buffer characters.  The first causes
        -- a transition to the end-of-buffer state.  The second causes
        -- a jam in that state.

        yy_ch_buf(yy_n_chars) := YY_END_OF_BUFFER_CHAR;
        yy_ch_buf(yy_n_chars + 1) := YY_END_OF_BUFFER_CHAR;

        yy_eof_has_been_seen := false;

        yytext_ptr := 1;
        yy_c_buf_p := yytext_ptr;
        yy_hold_char := yy_ch_buf(yy_c_buf_p);
        yy_init := false;
    end if; -- yy_init

    loop                -- loops until end-of-file is reached


        yy_cp := yy_c_buf_p;

        -- support of yytext
        yy_ch_buf(yy_cp) := yy_hold_char;

        -- yy_bp points to the position in yy_ch_buf of the start of the
        -- current run.
	yy_bp := yy_cp;
	yy_current_state := yy_start;
	if ( yy_ch_buf(yy_bp-1) = ASCII.LF ) then
	    yy_current_state := yy_current_state + 1;
	end if;
	loop
		yy_c := yy_ec(yy_ch_buf(yy_cp));
		if ( yy_accept(yy_current_state) /= 0 ) then
		    yy_last_accepting_state := yy_current_state;
		    yy_last_accepting_cpos := yy_cp;
		end if;
		while ( yy_chk(yy_base(yy_current_state) + yy_c) /= yy_current_state ) loop
		    yy_current_state := yy_def(yy_current_state);
		    if ( yy_current_state >= 543 ) then
			yy_c := yy_meta(yy_c);
		    end if;
		end loop;
		yy_current_state := yy_nxt(yy_base(yy_current_state) + yy_c);
	    yy_cp := yy_cp + 1;
if ( yy_current_state = 542 ) then
    exit;
end if;
	end loop;
	yy_cp := yy_last_accepting_cpos;
	yy_current_state := yy_last_accepting_state;

<<next_action>>
	    yy_act := yy_accept(yy_current_state);
            YY_DO_BEFORE_ACTION;
            YY_USER_ACTION;

        if aflex_debug then  -- output acceptance info. for (-d) debug mode
            text_io.put( Standard_Error, "--accepting rule #" );
            text_io.put( Standard_Error, INTEGER'IMAGE(yy_act) );
            text_io.put_line( Standard_Error, "(""" & yytext & """)");
        end if;


<<do_action>>   -- this label is used only to access EOF actions
            case yy_act is
		when 0 => -- must backtrack
		-- undo the effects of YY_DO_BEFORE_ACTION
		yy_ch_buf(yy_cp) := yy_hold_char;
		yy_cp := yy_last_accepting_cpos;
		yy_current_state := yy_last_accepting_state;
		goto next_action;



-- ^[ \r\t\f]+/"queued"[ \r\t\f\n] {
--         -- ignore "queued" at start of line as far as indenting
--         ECHO_L; 
--         if Debug_Indent and then Expecting_Indent then
--            Text_IO.Put(" [queued: indent off] ");
--         end if;
--         Expecting_Indent := False;  -- "then" will turn it back on
-- }
when 1 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
yy_cp := yy_cp - 3;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 53 "parasail_lex.l"

        -- ignore "is" at start of line as far as indenting
        ECHO_L; 


when 2 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
yy_cp := yy_cp - 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 58 "parasail_lex.l"

        -- this keyword when used at the beginning of a line
        -- is expected to be "outdented" relative to the preceding and
        -- following construct.  We want to treat it as though it
        -- it is the same indent as the prior construct that is just slightly
        -- more indented than this keyword.
        -- However, if we are expecting an *indent* then we don't look
        -- at the stack, and just return an INDENT, while preserving
        -- the "expecting indent" flag.
        -- If not expecting an indent, then we generate zero or more
        -- OUTDENTs and one NEWLINE if it is outdented relative to
        -- the top of the indent stack.  If not outdented relative to
        -- the top of the indent stack, we don't produce anything extra.

    declare
        YYT : constant String := yytext;
        Exports_Length : constant := 7; --  "exports"'Length
    begin
        pragma Assert (Col_Count = 0);

        --  Start of line, determine indent
        ECHO_L(YYT(YYT'First .. YYT'Last - Exports_Length)); 

        --  Put "exports" back
        for I in reverse YYT'Last - Exports_Length + 1 .. YYT'Last loop
           unput(YYT(I));
        end loop;

        if Col_Count = 0 then
           ENTER(RESCANNING);
        end if;

        --  At this point, Col_Count is indent level

        if Expecting_Indent then
           yylval := Create_Token(Text => "");
           if Debug_Indent then
              Text_IO.Put_Line(" [returning INDENT] ");
              Text_IO.Flush;
           end if;
           --  Preserve indent expectation
           Expecting_Indent := True;
           return INDENT;
        elsif Top = 0 then
           --  No indents on stack yet
           --  This shouldn't happen.
           yyerror("Source file cannot start with this token");
        elsif Col_Count >= Indent_Stack(Top) then
           --  Indenting relative to remembered stack
           --  Do nothing
           null;
        elsif Top = 1 then
           --  This is unexpected; should be at least two
           --  Do nothing
           null;
        elsif Col_Count >= Indent_Stack(Top-1) then
           --  See where we stand relative to the next indent level.
           --  We are not more outdented than next level, so return NEWLINE
           yylval := Create_Token(Text => "");
           if Debug_Indent then
              Text_IO.Put_Line(" [returning NEWLINE] ");
              Text_IO.Flush;
           end if;
           return NEWLINE;
        else
           --  Outdenting relative to remembered indent;
           --  we will set Col_Match_Expected to False so we
           --  won't complain about a col-count mismatch.
           pragma Assert (Col_Count < Indent_Stack (Top-1));

           Col_Match_Expected := False;

           if Debug_Indent then
              Text_IO.Put_Line(" [entering OUTDENTING; returning NEWLINE] ");
              Text_IO.Flush;
           end if;
           ENTER(OUTDENTING);
           return NEWLINE;
        end if;
        if Debug_Indent and then Expecting_Indent then
           Text_IO.Put(" [NL: indent off] ");
        end if;
        Expecting_Indent := False;
    end;


when 3 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
yy_cp := yy_cp - 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 144 "parasail_lex.l"

        -- ignore "new", "then", "||" at start of line as far as indenting
        -- but return a NEWLINE if not expecting an INDENT
    declare
        YYT : constant String := yytext;
    begin

        pragma Assert (Col_Count = 0);

        for I in reverse YYT'Range loop
           if YYT(I) <= ' ' then
              --  Echo the spaces at the front of the line
              ECHO_L(YYT(YYT'First .. I));
              exit;
           end if;
           --  Unput the non-space characters
           unput(YYT(I));
        end loop;

        if Col_Count = 0 then
           --  Next time, return the token
           ENTER(RESCANNING);
        end if;

        if not Expecting_Indent and then not Inside_For_Header then
           return NEWLINE;
        end if;
    end;


when 4 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
yy_cp := yy_cp - 2;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 174 "parasail_lex.l"

        -- Remember Expecting_Indent state, and return INDENT
        -- if expecting indent, but don't push new indent level on stack;
        -- return NEWLINE if not expecting an indent.
        Expecting_Indent_At_Label := Expecting_Indent;
        ECHO_L; 
        if Expecting_Indent then
            yylval := Create_Token(Text => "");
            if Debug_Indent then
               Text_IO.Put_Line(" [label: returning INDENT] "); Text_IO.Flush;
            end if;
            Expecting_Indent := True;
            return INDENT;
        else
            return NEWLINE;
        end if;


when 5 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
yy_cp := yy_cp - 4;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 192 "parasail_lex.l"

        -- ignore "for" after "implements" at start of line as far as indenting
        ECHO_L; 
        ENTER(CHARLIT);


when 6 => 
--# line 198 "parasail_lex.l"

    declare
        -- ignore spaces,Carriage returns,tabs,form feeds
        -- 
        -- determine indent (expanding tabs appropriately)
        -- compare to top of indent "stack"
        -- if less, emit OUTDENTs while popping from stack until find match
        --   (except ignore such a line if it starts with 
        --     "then"/"new"/"implements"/"exports"/"||"/"*XXX*")
        --   * complain if new level does not match one already on stack
        -- if same, emit NEWLINE; leave stack as is.
        -- if indent is more than top of stack:
        --   * if prior line ends with ":", push indent on stack and emit INDENT
        --   * if prior line does *not* end with ":" do not push indent on stack

        YYT : constant String := yytext;
    begin

        pragma Assert (Col_Count = 0);

        if YYT(YYT'First) in 'a'..'z' then
           --  Indent is zero; put back characters
           for I in reverse YYT'Range loop
              unput(YYT(I));
           end loop;
           --  Next time, return the token
           ENTER(RESCANNING);
        else
           --  Start of line, determine indent
           ECHO_L; 
        end if;

        --  At this point, Col_Count is indent level

        if Top = 0 then
           --  No indents on stack yet
           Top := Top + 1;
           Indent_Stack(Top) := Col_Count;
           Bracketing_Token_Stack(Top) := Error;
           if Debug_Indent then
              Text_IO.Put_Line(" [pushing" & Integer'Image(Col_Count) &
                " on Indent_Stack] ");
              Text_IO.Flush;
           end if;
        elsif Col_Count > Indent_Stack(Top) then
           --  Indenting relative to remembered stack
           if Expecting_Indent then
              --  Indenting is only significant if
              --  preceded by ':'/is/of/then/else/loop
              Top := Top + 1;
              Indent_Stack(Top) := Col_Count;
              Bracketing_Token_Stack(Top) := Bracketing_Token;
              if Debug_Indent then
                 Text_IO.Put_Line(" [pushing" & Integer'Image(Col_Count) &
                   " on Indent_Stack] "); Text_IO.Flush;
              end if;
              yylval := Create_Token(Text => "");
              if Debug_Indent then
                 Text_IO.Put_Line(" [returning INDENT] "); Text_IO.Flush;
              end if;
              return INDENT;
           end if;
        elsif Col_Count = Indent_Stack(Top) then
           --  Same indent, this is a "significant" newline
           yylval := Create_Token(Text => "");
           if Debug_Indent then
              Text_IO.Put_Line(" [returning NEWLINE] ");
              Text_IO.Flush;
           end if;
           return NEWLINE;
        else
           --  Outdenting relative to remembered indent;
           --  we will pop indent-stack until we get a match
           pragma Assert (Col_Count < Indent_Stack (Top));

           --  tbd: convert last OUTDENT into a NEWLINE: Top := Top - 1;
           if Debug_Indent then
              Text_IO.Put_Line(" [entering OUTDENTING; returning NEWLINE] ");
              Text_IO.Flush;
           end if;
           ENTER(OUTDENTING);
           return NEWLINE;
        end if;
        if Debug_Indent and then Expecting_Indent then
           Text_IO.Put(" [NL: indent off] ");
        end if;
        Expecting_Indent := False;
    end;


when 7 => 
--# line 288 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (ABSTRACT_kw);


when 8 => 
--# line 294 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CLASS_kw);


when 9 => 
--# line 300 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CONCURRENT_kw);


when 10 => 
--# line 306 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (END_kw);


when 11 => 
--# line 312 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FUNC_kw);


when 12 => 
--# line 318 "parasail_lex.l"
  --  "def" is used in Python, equiv to "func"
	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FUNC_kw);


when 13 => 
--# line 324 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (IMPORT_kw);


when 14 => 
--# line 330 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (INTERFACE_kw);


when 15 => 
--# line 336 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (OP_kw);


  -- ParaSail reserved words
when 16 => 
--# line 343 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (ABS_kw);


when 17 => 
--# line 348 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (ABSTRACT_kw);


when 18 => 
--# line 353 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (ALL_kw);


when 19 => 
--# line 358 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (AND_kw);


when 20 => 
--# line 363 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (BEGIN_kw);


when 21 => 
--# line 368 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := BLOCK_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (BLOCK_kw);


when 22 => 
--# line 378 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CASE_kw);


when 23 => 
--# line 383 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CLASS_kw);


when 24 => 
--# line 388 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CONCURRENT_kw);


when 25 => 
--# line 393 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CONST_kw);


when 26 => 
--# line 398 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (CONTINUE_kw);


when 27 => 
--# line 403 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (EACH_kw);


when 28 => 
--# line 408 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := ELSE_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (ELSE_kw);


when 29 => 
--# line 418 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
        yylval := Create_Token("elsif");
	yyerror("Use ""elsif"" rather than ""elseif""");
	return (ELSIF_kw);


when 30 => 
--# line 424 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
        yylval := Create_Token("elsif");
        --  Allow "elif" as an alias for "elsif" for Python-like syntax
	return (ELSIF_kw);


when 31 => 
--# line 430 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
        yylval := Create_Token("elsif");
	yyerror("Use ""elsif"" rather than ""else if""");
	return (ELSIF_kw);


when 32 => 
--# line 436 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (ELSIF_kw);


when 33 => 
--# line 441 "parasail_lex.l"

        unput('f'); unput('i');
	ECHO_L("end"); ENTER(CHARLIT); 
        yylval := Create_Token("end");
	yyerror("Use ""end if"" rather than ""endif""");
	return (END_kw);


when 34 => 
--# line 448 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (END_kw);


when 35 => 
--# line 453 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (EXIT_kw);


when 36 => 
--# line 458 "parasail_lex.l"

        declare
           Old_Indent : constant Boolean := Expecting_Indent;
        begin
	   ECHO_L; ENTER(CHARLIT); 
	   yylval := Create_Token;
           Expecting_Indent := Old_Indent;
           if Debug_Indent and then Expecting_Indent then
              Text_IO.Put(" [indent on] ");
           end if;
	   return (EXPORTS_kw);
        end;


when 37 => 
--# line 471 "parasail_lex.l"

        declare
           Old_Indent : constant Boolean := Expecting_Indent;
        begin
	   ECHO_L; ENTER(CHARLIT); 
	   yylval := Create_Token;
           Expecting_Indent := Old_Indent;
           if Debug_Indent and then Expecting_Indent then
              Text_IO.Put(" [indent on] ");
           end if;
	   return (EXPORTS_kw);
        end;


when 38 => 
--# line 484 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (EXTENDS_kw);


when 39 => 
--# line 489 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FOR_kw);


when 40 => 
--# line 494 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FORWARD_kw);


when 41 => 
--# line 499 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FUNC_kw);


when 42 => 
--# line 504 "parasail_lex.l"
  --  "def" is used in Python, equiv to "func"
	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (FUNC_kw);


when 43 => 
--# line 509 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (GLOBAL_kw);


when 44 => 
--# line 514 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (IF_kw);


when 45 => 
--# line 519 "parasail_lex.l"

	ECHO_L; ENTER(AFTER_IMPLEMENTS); 
        --  TBD: We might want to return a NEWLINE first.
	yylval := Create_Token;
	return (IMPLEMENTS_kw);


when 46 => 
--# line 525 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (IMPORT_kw);


when 47 => 
--# line 530 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (IN_kw);


when 48 => 
--# line 535 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (INTERFACE_kw);


when 49 => 
--# line 540 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := IS_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (IS_kw);


when 50 => 
--# line 550 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (LAMBDA_kw);


when 51 => 
--# line 555 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (LOCKED_kw);


when 52 => 
--# line 560 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := LOOP_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (LOOP_kw);


when 53 => 
--# line 570 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (MOD_kw);


when 54 => 
--# line 575 "parasail_lex.l"

        declare
           --  Preserve "Expecting_Indent" across "new"
           Old_Indent : constant Boolean := Expecting_Indent;
        begin
	   ECHO_L; ENTER(CHARLIT); 
	   yylval := Create_Token;
           Expecting_Indent := Old_Indent;
           if Debug_Indent and then Expecting_Indent then
              Text_IO.Put(" [indent on] ");
           end if;
	   return (NEW_kw);
        end;


when 55 => 
--# line 589 "parasail_lex.l"

        declare
           --  Preserve "Expecting_Indent" across "new"
           Old_Indent : constant Boolean := Expecting_Indent;
        begin
	   ECHO_L; ENTER(CHARLIT); 
	   yylval := Create_Token;
           Expecting_Indent := Old_Indent;
           if Debug_Indent and then Expecting_Indent then
              Text_IO.Put(" [indent on] ");
           end if;
	   return (NEW_kw);
        end;


when 56 => 
--# line 603 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (NOT_kw);


when 57 => 
--# line 608 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (NULL_kw);


when 58 => 
--# line 613 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := OF_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (OF_kw);


when 59 => 
--# line 623 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (OP_kw);


when 60 => 
--# line 628 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (OPT_kw);


when 61 => 
--# line 633 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (OPTIONAL_kw);


when 62 => 
--# line 638 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (OR_kw);


when 63 => 
--# line 643 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (PRIVATE_kw);


when 64 => 
--# line 648 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (QUEUED_kw);


when 65 => 
--# line 653 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (REF_kw);


when 66 => 
--# line 658 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (REM_kw);


when 67 => 
--# line 663 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (RETURN_kw);


when 68 => 
--# line 668 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (REVERSE_kw);


when 69 => 
--# line 673 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (SOME_kw);


when 70 => 
--# line 678 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := THEN_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (THEN_kw);


when 71 => 
--# line 688 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
        Bracketing_Token := THEN_kw;
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return (THEN_kw);


when 72 => 
--# line 698 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (TYPE_kw);


when 73 => 
--# line 703 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (UNTIL_kw);


when 74 => 
--# line 708 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (VAR_kw);


when 75 => 
--# line 713 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (WHILE_kw);


when 76 => 
--# line 718 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (WITH_kw);


when 77 => 
--# line 723 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return (XOR_kw);


  -- Match all the compound ParaSail delimiters. 
when 78 => 
--# line 730 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(COMPARE);


when 79 => 
--# line 735 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(EQ);


when 80 => 
--# line 740 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(NEQ);


when 81 => 
--# line 745 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(GEQ);


when 82 => 
--# line 750 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(LEQ);


when 83 => 
--# line 755 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(LSHIFT);


when 84 => 
--# line 760 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(POWER);


when 85 => 
--# line 765 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(ASSIGN);


when 86 => 
--# line 770 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(MOVE);


when 87 => 
--# line 775 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(SWAP);


when 88 => 
--# line 780 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(DOT_DOT);


when 89 => 
--# line 785 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(OPEN_INTERVAL);


when 90 => 
--# line 790 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(OPEN_CLOSED_INTERVAL);


when 91 => 
--# line 795 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(CLOSED_OPEN_INTERVAL);


when 92 => 
--# line 800 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(DOUBLE_COLON);


when 93 => 
--# line 805 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(REFERS_TO);


when 94 => 
--# line 810 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(GIVES);


when 95 => 
--# line 815 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(IMPLIES);


when 96 => 
--# line 820 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(PARALLEL);


when 97 => 
--# line 825 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(PARALLEL);


when 98 => 
--# line 830 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(PLUS_ASSIGN);


when 99 => 
--# line 835 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(MINUS_ASSIGN);


when 100 => 
--# line 840 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(TIMES_ASSIGN);


when 101 => 
--# line 845 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(DIVIDE_ASSIGN);


when 102 => 
--# line 850 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(POWER_ASSIGN);


when 103 => 
--# line 855 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(COMBINE_ASSIGN);


when 104 => 
--# line 860 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(COMBINE_MOVE);


when 105 => 
--# line 865 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(AND_ASSIGN);


when 106 => 
--# line 870 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(OR_ASSIGN);


when 107 => 
--# line 875 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(XOR_ASSIGN);


when 108 => 
--# line 880 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(LSHIFT_ASSIGN);


when 109 => 
--# line 885 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(RSHIFT_ASSIGN);


when 110 => 
--# line 890 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(PLUS_BASED_OP);


  -- Match all the ParaSail single-character delimiters.
when 111 => 
--# line 897 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return(PRIME);


when 112 => 
--# line 902 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('(');


when 113 => 
--# line 907 "parasail_lex.l"

	ECHO_L; ENTER(TICK); 
	yylval := Create_Token;
	return(')');


when 114 => 
--# line 912 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('[');


when 115 => 
--# line 917 "parasail_lex.l"

	ECHO_L; ENTER(TICK); 
	yylval := Create_Token;
	return(']');


when 116 => 
--# line 922 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('<');


when 117 => 
--# line 927 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('>');


when 118 => 
--# line 932 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);	  
	yylval := Create_Token;
	return(L_ASSERT);  --  or L_SET in PARython mode


when 119 => 
--# line 937 "parasail_lex.l"
  --  Allow > ... < so PARython can use  ...  for sets/maps
	ECHO_L; ENTER(CHARLIT);	  
	yylval := Create_Token;
	return(L_ASSERT);


when 120 => 
--# line 942 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);	  
	yylval := Create_Token;
	return(R_ASSERT);  --  or R_SET in PARython mode


when 121 => 
--# line 947 "parasail_lex.l"
  --  Allow > ... < so PARython can use  ...  for sets/maps
	ECHO_L; ENTER(CHARLIT);	  
	yylval := Create_Token;
	return(R_ASSERT);


when 122 => 
--# line 952 "parasail_lex.l"

        declare
           --  Remember Expecting_Indent
           Old_Indent : constant Boolean := Expecting_Indent;
        begin
	   ECHO_L; ENTER(CHARLIT); 
	   yylval := Create_Token;
           if Expecting_Indent_At_Label then
              if not Old_Indent then
                 --  Seen '*' twice; set Expecting_Indent back on
                 Expecting_Indent_At_Label := False;
                 Expecting_Indent := True;
                 if Debug_Indent then
                    Text_IO.Put(" [indent on] ");
                 end if;
              end if;
           end if;
	   return ('*');
        end;


when 123 => 
--# line 972 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('+');


when 124 => 
--# line 977 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return(',');


when 125 => 
--# line 982 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('-');


when 126 => 
--# line 987 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('.');


when 127 => 
--# line 992 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('/');


when 128 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 997 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
        Bracketing_Token := ':';
        Expecting_Indent := True;
        if Debug_Indent then
           Text_IO.Put(" [indent on] ");
        end if;
	return(EOL_COLON);


when 129 => 
--# line 1007 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return(':');


when 130 => 
--# line 1012 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return(';');


when 131 => 
--# line 1017 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('|');


when 132 => 
--# line 1022 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('?');


when 133 => 
--# line 1027 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT);     
	yylval := Create_Token;
	return('=');


  -- The following is used to match all valid ParaSail identifiers
  -- except reserved words. Note that leading digits and underscores
  -- are not allowed and that double underscores are not allowed.
when 134 => 
--# line 1037 "parasail_lex.l"

	ECHO_L; ENTER(TICK);
	yylval := Create_Token;
	return(Identifier);


  -- Enumeration literals
when 135 => 
--# line 1044 "parasail_lex.l"

	ECHO_L; ENTER(TICK);
	yylval := Create_Token;
	return(Enum_Literal);


  -- Decimal numeric literals
when 136 => 
--# line 1051 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(Integer_Literal);


when 137 => 
--# line 1057 "parasail_lex.l"

      ECHO_L; ENTER(CHARLIT);
      yylval := Create_Token;
      return(Real_Literal);


  -- Based numeric literals.
when 138 => 
--# line 1065 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(Integer_Literal);


when 139 => 
--# line 1071 "parasail_lex.l"

      ECHO_L; ENTER(CHARLIT);
      yylval := Create_Token;
      return(Real_Literal);


when 140 => 
--# line 1077 "parasail_lex.l"

      ECHO_L; ENTER(CHARLIT); 
      yylval := Create_Token;
      return(Integer_Literal);


when 141 => 
--# line 1083 "parasail_lex.l"

      ECHO_L; ENTER(CHARLIT); 
      yylval := Create_Token;
      return(Integer_Literal);


  -- Match all valid character literals.  See Ada LRM 2.6.
when 142 => 
--# line 1091 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
	yylval := Create_Token;
	return(Char_Literal);


  -- Match all valid string literals.  See Ada LRM 2.6.
when 143 => 
--# line 1099 "parasail_lex.l"

	ECHO_L; ENTER(CHARLIT); 
        declare
           Tok : constant String := yytext;
           Quote : constant String := """";
        begin
           yylval := Create_Token (Tok);
           if Tok (Tok'Last) /= Quote(1) then
              yyerror ("unterminated string", At_Token => yylval);
           end if;
           return(String_Literal);
        end;


  -- Handle white space --
when 144 => 
--# line 1115 "parasail_lex.l"
ECHO_L; -- ignore white space and comments to end-of-line

when 145 => 
--# line 1117 "parasail_lex.l"
ECHO_L; -- ignore white space and comments to end-of-line

when 146 => 
--# line 1119 "parasail_lex.l"

        --  Not start of line (or whole line); no need to keep track
        pragma Assert (Col_Count > 0);
        ECHO_L;


when 147 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 1126 "parasail_lex.l"

        --  Ignore outdent for these "divider" constructs
        unput(yytext(1));
        if Debug_Indent then
           Text_IO.Put_Line(" [exiting OUTDENTING] ");
           Text_IO.Flush;
        end if;
        ENTER(CHARLIT);


when 148 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 1136 "parasail_lex.l"

        --  Ignore outdent for these "divider" constructs
        unput(yytext(1));
        if Debug_Indent then
           Text_IO.Put_Line(" [exiting OUTDENTING] ");
           Text_IO.Flush;
        end if;
        ENTER(CHARLIT);


when 149 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 1146 "parasail_lex.l"

        --  Ignore outdent for these "divider" constructs
        unput(yytext(1));
        if Debug_Indent then
           Text_IO.Put_Line(" [exiting OUTDENTING] ");
           Text_IO.Flush;
        end if;
        ENTER(CHARLIT);


when 150 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 1156 "parasail_lex.l"

        --  Ignore outdent for these "divider" constructs
        unput(yytext(1));
        if Debug_Indent then
           Text_IO.Put_Line(" [exiting OUTDENTING] ");
           Text_IO.Flush;
        end if;
        ENTER(CHARLIT);


when 151 => 
yy_ch_buf(yy_cp) := yy_hold_char; -- undo effects of setting up yytext
 yy_cp := yy_bp + 1;
yy_c_buf_p := yy_cp;
YY_DO_BEFORE_ACTION; -- set up yytext again
--# line 1166 "parasail_lex.l"

        --  Ignore outdent for label
        unput(yytext(1));
        if Debug_Indent then
           Text_IO.Put_Line(" [exiting OUTDENTING] ");
           Text_IO.Flush;
        end if;
        ENTER(CHARLIT);


when 152 => 
--# line 1176 "parasail_lex.l"

        --  Return another OUTDENT
        declare
           Do_Match_Check : Boolean := True;
        begin
           unput(yytext(1));
           if Top > 1 and then Col_Count < Indent_Stack(Top)
             and then (Col_Match_Expected
               or else Col_Count < Indent_Stack(Top-1))
           then
              --  Not yet reached a matching indent;
              --  Pop the stack
              if Debug_Indent then
                 Text_IO.Put_Line(" [popping" &
                   Integer'Image(Indent_Stack(Top)) &
                   " from Indent_Stack] ");
                 Text_IO.Flush;
              end if;
              Top := Top - 1;
              if Col_Count >= Indent_Stack(Top)
                or else not Col_Match_Expected
                or else Bracketing_Token_Stack(Top + 1) = ':'
                or else Bracketing_Token_Stack(Top + 1) = REFERS_TO
              then
                 --  Don't check for indent match this time;
                 --  wait til next time since only one outdent occurring,
                 --  or ":" or "=>" used at end of line (which allows multiple
                 --  outdents at a time).
                 Do_Match_Check := False;
              end if;
           end if;

           if Do_Match_Check then
              --  Found (nearly) matching indent
              if Debug_Indent then
                 Text_IO.Put_Line(" [exiting OUTDENTING] ");
                 Text_IO.Flush;
              end if;
              if Col_Count = 0 then
                 --  Return the token at the beginning of the line
                 ENTER(RESCANNING);
              else
                 ENTER(CHARLIT);
              end if;
              if Col_Count /= Indent_Stack(Top)
                and then Col_Match_Expected
              then
                 --  Not quite matching
                 Parser_Warning("indent mismatch; expected indent of" &
                   Integer'Image(Indent_Stack(Top)) & ", found" &
                   Integer'Image(Col_Count));

                 --  Force a match
                 --  TBD: Not sure this is the right choice
                 if Top = 1 then
                    Top := Top + 1;
                    if Debug_Indent then
                       Text_IO.Put_Line(" [pushing" &
                         Integer'Image(Col_Count) &
                         " on Indent_Stack] ");
                       Text_IO.Flush;
                    end if;
                 else
                    if Debug_Indent then
                       Text_IO.Put_Line(" [setting top of Indent_Stack to" &
                         Integer'Image(Col_Count) & "] "); Text_IO.Flush;
                    end if;
                 end if;
                 Indent_Stack(Top) := Col_Count;
              end if;
           end if;
           yylval := Create_Token(Text => "");
           if Do_Match_Check then
              if Debug_Indent then
                 Text_IO.Put_Line(" [returning NEWLINE after OUTDENTs] ");
                 Text_IO.Flush;
              end if;
              return NEWLINE;
           else
              if Debug_Indent then
                 Text_IO.Put_Line(" [returning OUTDENT] ");
                 Text_IO.Flush;
              end if;
              return OUTDENT;
           end if;
        end;


when YY_END_OF_BUFFER +CHARLIT + 1 
 |
YY_END_OF_BUFFER +TICK + 1 
 |
YY_END_OF_BUFFER +AFTER_IMPLEMENTS + 1 
 |
YY_END_OF_BUFFER +INITIAL + 1 
 =>
--# line 1264 "parasail_lex.l"

        if Top = 0 then
           if Debug_Indent and then Expecting_Indent then
              Text_IO.Put(" [EOF: indent off] "); Text_IO.Flush;
           end if;
           Expecting_Indent := False;
           if Debug_Indent then
              Text_IO.Put(" [returning EOF] "); Text_IO.Flush;
           end if;
           return End_Of_Input;
        else
           unput(YY_END_OF_BUFFER_CHAR);
           Col_Count := Indent_Stack(1);
           if Debug_Indent then
              Text_IO.Put_Line(" [popping" & Integer'Image(Indent_Stack(Top)) &
                " from Indent_Stack] ");
              Text_IO.Flush;
           end if;
           Top := Top - 1;
           if Top > 0 then
              if Debug_Indent then
                 Text_IO.Put_Line(" [entering EOF OUTDENTING] ");
                 Text_IO.Flush;
              end if;
              ENTER(OUTDENTING);
           else
              --  This is a significant NEWLINE
              if Debug_Indent then
                 Text_IO.Put_Line(" [returning NEWLINE] ");
                 Text_IO.Flush;
              end if;
              yylval := Create_Token(Text => "");
              return NEWLINE;
           end if;
        end if;


when YY_END_OF_BUFFER +OUTDENTING + 1 
 =>
--# line 1301 "parasail_lex.l"

        --  Return another OUTDENT
        unput(YY_END_OF_BUFFER_CHAR);
        if Debug_Indent then
           Text_IO.Put_Line(" [popping" & Integer'Image(Indent_Stack(Top)) &
             " from Indent_Stack] ");
           Text_IO.Flush;
        end if;
        Top := Top - 1;
        if Top = 0 then
           --  All done
           if Debug_Indent then
              Text_IO.Put_Line(" [exiting EOF OUTDENTING] ");
              Text_IO.Flush;
           end if;
           ENTER(CHARLIT);
        end if;

        yylval := Create_Token(Text => "");
        if Debug_Indent then
           Text_IO.Put_Line(" [returning EOF OUTDENT] ");
           Text_IO.Flush;
        end if;
        return OUTDENT;


  -- The following matches all new lines (and the preceding white space).
when 155 => 
--# line 1330 "parasail_lex.l"

        --  TBD: Should we return NEWLINE if this line is entirely blank?
        if Echo_Input then
           text_io.new_line;
        end if;
        Display_Linenum;


  -- The following matches everything else and prints an error message
  -- indicating that something unexpected was found.
when 156 => 
--# line 1341 "parasail_lex.l"
ECHO_L; 
	    yyerror("lexical error: '" &
	      parasail_lex_dfa.yytext & "'");


when 157 => 
--# line 1346 "parasail_lex.l"
raise AFLEX_SCANNER_JAMMED;
when YY_END_OF_BUFFER + RESCANNING + 1 => 
    return End_Of_Input;
                when YY_END_OF_BUFFER =>
                    -- undo the effects of YY_DO_BEFORE_ACTION
                    yy_ch_buf(yy_cp) := yy_hold_char;

                    yytext_ptr := yy_bp;

                    case yy_get_next_buffer is
                        when EOB_ACT_END_OF_FILE =>
                            begin
                            if ( yywrap ) then
                                -- note: because we've taken care in
                                -- yy_get_next_buffer() to have set up yytext,
                                -- we can now set up yy_c_buf_p so that if some
                                -- total hoser (like aflex itself) wants
                                -- to call the scanner after we return the
                                -- End_Of_Input, it'll still work - another
                                -- End_Of_Input will get returned.

                                yy_c_buf_p := yytext_ptr;

                                yy_act := YY_STATE_EOF((yy_start - 1) / 2);

                                goto do_action;
                            else
                                --  start processing a new file
                                yy_init := true;
                                goto new_file;
                            end if;
                            end;
                        when EOB_ACT_RESTART_SCAN =>
                            yy_c_buf_p := yytext_ptr;
                            yy_hold_char := yy_ch_buf(yy_c_buf_p);
                        when EOB_ACT_LAST_MATCH =>
                            yy_c_buf_p := yy_n_chars;
                            yy_current_state := yy_get_previous_state;

                            yy_cp := yy_c_buf_p;
                            yy_bp := yytext_ptr;
                            goto next_action;
                        when others => null;
                        end case; -- case yy_get_next_buffer()
                when others =>
                    text_io.put( "action # " );
                    text_io.put( INTEGER'IMAGE(yy_act) );
                    text_io.new_line;
                    raise AFLEX_INTERNAL_ERROR;
            end case; -- case (yy_act)
        end loop; -- end of loop waiting for end of file
end YYLex;
--# line 1346 "parasail_lex.l"

end parasail_lex;


