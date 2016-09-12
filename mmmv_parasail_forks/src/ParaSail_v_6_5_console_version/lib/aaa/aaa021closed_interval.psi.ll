declare i1 @_psc_is_null_value(i64, i64*)
declare void @"_psc_ordering_to_bool"(i64*, i64*, i64*)
declare i64* @_psc_get_type_desc_or_op_map(i64*, i16, i16)
declare void @_psc_reconstruct_strings(i16, i8**, i64*)
declare void @_psc_reconstruct_type_descriptors(i16, i8**, i64*, i64**)
declare void @"_psc_runtime_message"(i64*, i64*, i64*)
declare void @_psc_register_compiled_operations(i16, i16*, void(i64*, i64*, i64*)**, i8*, i64*, i32, i16*, i32(i64*, i64*, i64*)**)
declare void @_psc_execute_compiled_indirect_call_op(i64*, i64*, i64*, i16, i16, i16, i16, i64, void(i64*, i64*, i64*)*, i8)

@$Module_Op_Indices = internal constant [4 x i16] [
i16 1, i16 4, i16 1, i16 2]

@$Local_Funcs = internal constant [2 x void(i64*, i64*, i64*)*] [
void(i64*, i64*, i64*)* @"PSL.Core.Closed_Interval.$=?$"
, void(i64*, i64*, i64*)* @"PSL.Core.Closed_Interval.$in$"]

@$Local_Funcs_Use_Queuing = internal constant [2 x i8] [
i8 0, i8 0]

@$Internal_Precond_Indices = internal constant [0 x i16] [
]

@$Internal_Precond_Blocks = internal constant [0 x i32(i64*, i64*, i64*)*] [
]

@"PSL.Core.Ordering" = internal constant [432 x i8] 

[i8 0, i8 173, i8 77, i8 254, i8 90, i8 173, i8 77, i8 254, i8 90, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 20, i8 0
, i8 247, i8 255, i8 255, i8 255, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 128, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 20, i8 0, i8 9, i8 0, i8 246, i8 255, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 1, i8 0, i8 0, i8 1, i8 192, i8 9, i8 0, i8 245, i8 255
, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 2, i8 0, i8 0, i8 1, i8 1, i8 9, i8 0
, i8 244, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 3, i8 0, i8 0, i8 1
, i8 1, i8 9, i8 0, i8 252, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 4
, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 9, i8 0, i8 243, i8 255, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 5, i8 0, i8 0, i8 1, i8 1, i8 9, i8 0, i8 14, i8 0
, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 6, i8 0, i8 0, i8 1, i8 1, i8 9, i8 0
, i8 15, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 7, i8 0, i8 0, i8 1
, i8 192, i8 9, i8 0, i8 240, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 8
, i8 0, i8 0, i8 2, i8 192, i8 1, i8 9, i8 0, i8 240, i8 255, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 9, i8 0, i8 0, i8 2, i8 192, i8 1, i8 9, i8 0, i8 239
, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 10, i8 0, i8 0, i8 2, i8 192
, i8 1, i8 9, i8 0, i8 239, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 11
, i8 0, i8 0, i8 2, i8 192, i8 1, i8 9, i8 0, i8 238, i8 255, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 12, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 9, i8 0
, i8 237, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 13, i8 0, i8 0, i8 3
, i8 192, i8 1, i8 2, i8 9, i8 0, i8 20, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 14, i8 0, i8 0, i8 1, i8 192, i8 9, i8 0, i8 21, i8 0, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 15, i8 0, i8 0, i8 1, i8 192, i8 9, i8 0, i8 22
, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 16, i8 0, i8 0, i8 2, i8 1
, i8 2, i8 9, i8 0, i8 23, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 17
, i8 0, i8 0, i8 2, i8 1, i8 2, i8 9, i8 0, i8 24, i8 0, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 18, i8 0, i8 0, i8 2, i8 1, i8 2, i8 9, i8 0, i8 25
, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 19, i8 0, i8 0, i8 2, i8 1
, i8 2, i8 9, i8 0, i8 26, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 20
, i8 0, i8 0, i8 2, i8 1, i8 2]

@"PSL.Core.Boolean" = internal constant [531 x i8] 

[i8 0, i8 173, i8 77, i8 254, i8 90, i8 173, i8 77, i8 254, i8 90, i8 1, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 26, i8 0
, i8 229, i8 255, i8 255, i8 255, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 128, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 26, i8 0, i8 27, i8 0, i8 228, i8 255, i8 1, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 1, i8 0, i8 0, i8 1, i8 192, i8 27, i8 0, i8 227, i8 255
, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 2, i8 0, i8 0, i8 1, i8 1, i8 27, i8 0
, i8 252, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 3, i8 0, i8 0, i8 2
, i8 1, i8 2, i8 27, i8 0, i8 226, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 4, i8 0, i8 0, i8 2, i8 192, i8 1, i8 27, i8 0, i8 225, i8 255, i8 1, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 5, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 27
, i8 0, i8 224, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 6, i8 0, i8 0
, i8 3, i8 192, i8 1, i8 2, i8 27, i8 0, i8 223, i8 255, i8 1, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 7, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 27, i8 0, i8 34
, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 8, i8 0, i8 0, i8 2, i8 96, i8 1
, i8 27, i8 0, i8 35, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 9, i8 0
, i8 0, i8 2, i8 96, i8 1, i8 27, i8 0, i8 36, i8 0, i8 1, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 10, i8 0, i8 0, i8 2, i8 96, i8 1, i8 27, i8 0, i8 243, i8 255
, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 11, i8 0, i8 0, i8 1, i8 1, i8 27
, i8 0, i8 14, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 12, i8 0, i8 0
, i8 1, i8 1, i8 27, i8 0, i8 15, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 13, i8 0, i8 0, i8 1, i8 192, i8 27, i8 0, i8 240, i8 255, i8 1, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 14, i8 0, i8 0, i8 2, i8 192, i8 1, i8 27, i8 0
, i8 240, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 15, i8 0, i8 0, i8 2
, i8 192, i8 1, i8 27, i8 0, i8 239, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 16, i8 0, i8 0, i8 2, i8 192, i8 1, i8 27, i8 0, i8 239, i8 255, i8 1
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 17, i8 0, i8 0, i8 2, i8 192, i8 1, i8 27
, i8 0, i8 238, i8 255, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 18, i8 0, i8 0
, i8 3, i8 192, i8 1, i8 2, i8 27, i8 0, i8 237, i8 255, i8 1, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 19, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 27, i8 0, i8 20
, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 20, i8 0, i8 0, i8 1, i8 192
, i8 27, i8 0, i8 21, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 21, i8 0
, i8 0, i8 1, i8 192, i8 27, i8 0, i8 22, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 22, i8 0, i8 0, i8 2, i8 1, i8 2, i8 27, i8 0, i8 23, i8 0, i8 1
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 23, i8 0, i8 0, i8 2, i8 1, i8 2, i8 27
, i8 0, i8 24, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 24, i8 0, i8 0
, i8 2, i8 1, i8 2, i8 27, i8 0, i8 25, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 25, i8 0, i8 0, i8 2, i8 1, i8 2, i8 27, i8 0, i8 26, i8 0, i8 1
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 26, i8 0, i8 0, i8 2, i8 1, i8 2]

@$Type_Desc_Streams = internal constant [2 x i8*] [
 i8* getelementptr ([432 x i8]* @"PSL.Core.Ordering", i64 0, i64 0), 
 i8* getelementptr ([531 x i8]* @"PSL.Core.Boolean", i64 0, i64 0)]
@$Type_Descriptors = internal global [2 x i64*]
[i64* null, i64* null]
@$Types = internal constant i64** bitcast ([2 x i64*]* @$Type_Descriptors to i64**)
@"$Anon_Const_1" = internal constant i64 0; "from_univ"(#less)
@"$Anon_Const_2" = internal constant i64 2; "from_univ"(#greater)
@"$Anon_Const_3" = internal constant i64 1; "from_univ"(#equal)
@"$Anon_Const_4" = internal constant i64 3; "from_univ"(#unordered)
@$str_stream1 = internal constant [30 x i8] 

[i8 26, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 114, i8 101, i8 58, i8 58, i8 67, i8 108, i8 111, i8 115, i8 101, i8 100
, i8 95, i8 73, i8 110, i8 116, i8 101, i8 114, i8 118, i8 97, i8 108]

@$str_stream2 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 105, i8 110, i8 34]

@$str_stream3 = internal constant [104 x i8] 

[i8 100, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 50, i8 49, i8 99, i8 108, i8 111
, i8 115, i8 101, i8 100, i8 95, i8 105, i8 110, i8 116, i8 101, i8 114, i8 118
, i8 97, i8 108, i8 46, i8 112, i8 115, i8 105, i8 58, i8 49, i8 52, i8 58
, i8 57, i8 58, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58, i8 32
, i8 78, i8 117, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117, i8 101
, i8 32, i8 110, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109, i8 105
, i8 116, i8 116, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101, i8 58
, i8 32, i8 10]

@$str_stream4 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 61, i8 63, i8 34]

@$str_stream5 = internal constant [105 x i8] 

[i8 101, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 50, i8 49, i8 99, i8 108, i8 111
, i8 115, i8 101, i8 100, i8 95, i8 105, i8 110, i8 116, i8 101, i8 114, i8 118
, i8 97, i8 108, i8 46, i8 112, i8 115, i8 105, i8 58, i8 50, i8 51, i8 58
, i8 49, i8 51, i8 58, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58
, i8 32, i8 78, i8 117, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117
, i8 101, i8 32, i8 110, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109
, i8 105, i8 116, i8 116, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101
, i8 58, i8 32, i8 10]

@$str_stream6 = internal constant [105 x i8] 

[i8 101, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 50, i8 49, i8 99, i8 108, i8 111
, i8 115, i8 101, i8 100, i8 95, i8 105, i8 110, i8 116, i8 101, i8 114, i8 118
, i8 97, i8 108, i8 46, i8 112, i8 115, i8 105, i8 58, i8 50, i8 53, i8 58
, i8 49, i8 51, i8 58, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58
, i8 32, i8 78, i8 117, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117
, i8 101, i8 32, i8 110, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109
, i8 105, i8 116, i8 116, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101
, i8 58, i8 32, i8 10]

@$str_stream7 = internal constant [105 x i8] 

[i8 101, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 50, i8 49, i8 99, i8 108, i8 111
, i8 115, i8 101, i8 100, i8 95, i8 105, i8 110, i8 116, i8 101, i8 114, i8 118
, i8 97, i8 108, i8 46, i8 112, i8 115, i8 105, i8 58, i8 50, i8 56, i8 58
, i8 49, i8 51, i8 58, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58
, i8 32, i8 78, i8 117, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117
, i8 101, i8 32, i8 110, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109
, i8 105, i8 116, i8 116, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101
, i8 58, i8 32, i8 10]

@$str_stream8 = internal constant [105 x i8] 

[i8 101, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 50, i8 49, i8 99, i8 108, i8 111
, i8 115, i8 101, i8 100, i8 95, i8 105, i8 110, i8 116, i8 101, i8 114, i8 118
, i8 97, i8 108, i8 46, i8 112, i8 115, i8 105, i8 58, i8 51, i8 48, i8 58
, i8 49, i8 51, i8 58, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58
, i8 32, i8 78, i8 117, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117
, i8 101, i8 32, i8 110, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109
, i8 105, i8 116, i8 116, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101
, i8 58, i8 32, i8 10]

@$str_stream9 = internal constant [23 x i8] 

[i8 19, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 114, i8 101, i8 58, i8 58, i8 79, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103]

@$str_stream10 = internal constant [23 x i8] 

[i8 19, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 102, i8 114, i8 111, i8 109, i8 95, i8 117, i8 110
, i8 105, i8 118]

@$str_stream11 = internal constant [21 x i8] 

[i8 17, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 116, i8 111, i8 95, i8 117, i8 110, i8 105, i8 118]

@$str_stream12 = internal constant [21 x i8] 

[i8 17, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 116, i8 111, i8 95, i8 98, i8 111, i8 111, i8 108]

@$str_stream13 = internal constant [13 x i8] 

[i8 9, i8 0, i8 0, i8 0, i8 35, i8 105, i8 100, i8 101, i8 110, i8 116, i8 105
, i8 116, i8 121]

@$str_stream14 = internal constant [13 x i8] 

[i8 9, i8 0, i8 0, i8 0, i8 84, i8 111, i8 95, i8 83, i8 116, i8 114, i8 105
, i8 110, i8 103]

@$str_stream15 = internal constant [15 x i8] 

[i8 11, i8 0, i8 0, i8 0, i8 70, i8 114, i8 111, i8 109, i8 95, i8 83, i8 116
, i8 114, i8 105, i8 110, i8 103]

@$str_stream16 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 43, i8 34]

@$str_stream17 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 45, i8 34]

@$str_stream18 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 35, i8 109, i8 105, i8 110]

@$str_stream19 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 35, i8 109, i8 97, i8 120]

@$str_stream20 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 70, i8 105, i8 114, i8 115, i8 116]

@$str_stream21 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 76, i8 97, i8 115, i8 116]

@$str_stream22 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 46, i8 46, i8 34]

@$str_stream23 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 60, i8 46, i8 46, i8 34]

@$str_stream24 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 46, i8 46, i8 60, i8 34]

@$str_stream25 = internal constant [10 x i8] 

[i8 6, i8 0, i8 0, i8 0, i8 34, i8 60, i8 46, i8 46, i8 60, i8 34]

@$str_stream26 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 124, i8 34]

@$str_stream27 = internal constant [22 x i8] 

[i8 18, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 114, i8 101, i8 58, i8 58, i8 66, i8 111, i8 111, i8 108, i8 101, i8 97
, i8 110]

@$str_stream28 = internal constant [19 x i8] 

[i8 15, i8 0, i8 0, i8 0, i8 35, i8 98, i8 111, i8 111, i8 108, i8 95, i8 102
, i8 114, i8 111, i8 109, i8 95, i8 117, i8 110, i8 105, i8 118]

@$str_stream29 = internal constant [17 x i8] 

[i8 13, i8 0, i8 0, i8 0, i8 35, i8 98, i8 111, i8 111, i8 108, i8 95, i8 116
, i8 111, i8 95, i8 117, i8 110, i8 105, i8 118]

@$str_stream30 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 110, i8 111, i8 116, i8 34]

@$str_stream31 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 97, i8 110, i8 100, i8 34]

@$str_stream32 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 111, i8 114, i8 34]

@$str_stream33 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 120, i8 111, i8 114, i8 34]

@$str_stream34 = internal constant [10 x i8] 

[i8 6, i8 0, i8 0, i8 0, i8 34, i8 97, i8 110, i8 100, i8 61, i8 34]

@$str_stream35 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 111, i8 114, i8 61, i8 34]

@$str_stream36 = internal constant [10 x i8] 

[i8 6, i8 0, i8 0, i8 0, i8 34, i8 120, i8 111, i8 114, i8 61, i8 34]

@$Str_Streams = internal constant [36 x i8*] [
i8* getelementptr ([30 x i8]* @$str_stream1, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream2, i64 0, i64 0), 
i8* getelementptr ([104 x i8]* @$str_stream3, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream4, i64 0, i64 0), 
i8* getelementptr ([105 x i8]* @$str_stream5, i64 0, i64 0), 
i8* getelementptr ([105 x i8]* @$str_stream6, i64 0, i64 0), 
i8* getelementptr ([105 x i8]* @$str_stream7, i64 0, i64 0), 
i8* getelementptr ([105 x i8]* @$str_stream8, i64 0, i64 0), 
i8* getelementptr ([23 x i8]* @$str_stream9, i64 0, i64 0), 
i8* getelementptr ([23 x i8]* @$str_stream10, i64 0, i64 0), 
i8* getelementptr ([21 x i8]* @$str_stream11, i64 0, i64 0), 
i8* getelementptr ([21 x i8]* @$str_stream12, i64 0, i64 0), 
i8* getelementptr ([13 x i8]* @$str_stream13, i64 0, i64 0), 
i8* getelementptr ([13 x i8]* @$str_stream14, i64 0, i64 0), 
i8* getelementptr ([15 x i8]* @$str_stream15, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream16, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream17, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream18, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream19, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream20, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream21, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream22, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream23, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream24, i64 0, i64 0), 
i8* getelementptr ([10 x i8]* @$str_stream25, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream26, i64 0, i64 0), 
i8* getelementptr ([22 x i8]* @$str_stream27, i64 0, i64 0), 
i8* getelementptr ([19 x i8]* @$str_stream28, i64 0, i64 0), 
i8* getelementptr ([17 x i8]* @$str_stream29, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream30, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream31, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream32, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream33, i64 0, i64 0), 
i8* getelementptr ([10 x i8]* @$str_stream34, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream35, i64 0, i64 0), 
i8* getelementptr ([10 x i8]* @$str_stream36, i64 0, i64 0)]
@$String_Table = internal global [36 x i64] 
[i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0]
@$Strings = internal constant i64* bitcast ([36 x i64]* @$String_Table to i64*)
@_psc_global_to_do = external global {i64*, void()*}*
define internal void @$initialize_streams() {
   %_Str_Tab = load i64** @$Strings
   call void @_psc_reconstruct_strings(i16 36, i8** getelementptr ([36 x i8*]* @$Str_Streams, i64 0, i64 0), i64* %_Str_Tab)
   %_desc = load i64*** @$Types
   call void @_psc_reconstruct_type_descriptors(i16 2, i8** getelementptr ([2 x i8*]* @$Type_Desc_Streams, i64 0, i64 0), i64* %_Str_Tab, i64** %_desc)
   call void @_psc_register_compiled_operations(i16 2, i16* getelementptr ([4 x i16]* @$Module_Op_Indices, i64 0, i64 0), void(i64*, i64*, i64*)** getelementptr ([2 x void(i64*, i64*, i64*)*]* @$Local_Funcs, i64 0, i64 0), i8* getelementptr ([2 x i8]* @$Local_Funcs_Use_Queuing, i64 0, i64 0), i64* %_Str_Tab, i32 0, i16* getelementptr ([0 x i16]* @$Internal_Precond_Indices, i64 0, i64 0), i32(i64*, i64*, i64*)** getelementptr ([0 x i32(i64*, i64*, i64*)*]* @$Internal_Precond_Blocks, i64 0 , i64 0))
   ret void
}
@"_node_/Users/stt/_parasail/lib/aaa/aaa021closed_interval.psi" = global {i64*, void()*} {i64* null, void()* @$initialize_streams}
define internal void @$add_to_todo() {
   %_next = load {i64*, void()*}** @_psc_global_to_do
   %_nextc = bitcast {i64*, void()*}* %_next to i64*
   %_node.next_ptr = getelementptr {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa021closed_interval.psi", i32 0, i32 0
   store i64* %_nextc, i64** %_node.next_ptr
   store {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa021closed_interval.psi", {i64*, void()*}** @_psc_global_to_do
   ret void
}
@llvm.global_ctors = appending global [1 x {i32, void ()*}] [{i32, void()*} {i32 65535, void ()* @$add_to_todo}]

define void @"PSL.Core.Closed_Interval.$in$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 7
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Copy_Word_Op at 14:16
   %_source1 = getelementptr i64* %_Param_Area, i64 1
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val1, i64* %_dest1

   ; #Copy_Word_Op at 14:24
   %_source2 = getelementptr i64* %_Param_Area, i64 2
   %_source_val2 = load i64* %_source2
   %_dest2 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val2, i64* %_dest2

   ; #Copy_Word_Op at 14:30
   %_reg_ptr31_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr31 = bitcast i64* %_reg_ptr31_Orig to i64**
   %_reg31 = load i64** %_reg_ptr31
   %_source3 = getelementptr i64* %_reg31, i64 1
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val3, i64* %_dest3

   ; #Call_Op at 14:21
   %_call4_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call4_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call4_Param_Area, i64* %_call4_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 14:21
   %_dest5 = getelementptr i64* %_Local_Area, i64 5
   store i64 6, i64* %_dest5

   ; #Call_Op at 14:21
   %_desc_ptr_ptr60 = load i64*** @$Types
   %_desc_ptr60 = getelementptr i64** %_desc_ptr_ptr60, i64 0
   %_call6_Static_Link = load i64** %_desc_ptr60
   %_call6_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call6_Param_Area, i64* %_call6_Static_Link)

   ; #If_Op at 14:34
   %_if_source_ptr7 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val7 = load i64* %_if_source_ptr7
   %_shifted7 = shl i64 1, %_if_source_val7
   %_and7 = and i64 %_shifted7, 2
   %_if_source_trunc7 = icmp ne i64 %_and7, 0
   br i1 %_if_source_trunc7, label %_lbl8, label %_lbl15

_lbl8:
   ; #Copy_Word_Op at 14:43
   %_source8 = getelementptr i64* %_Param_Area, i64 1
   %_source_val8 = load i64* %_source8
   %_dest8 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val8, i64* %_dest8

   ; #Copy_Word_Op at 14:51
   %_source9 = getelementptr i64* %_Param_Area, i64 2
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val9, i64* %_dest9

   ; #Copy_Word_Op at 14:57
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_source10 = getelementptr i64* %_reg101, i64 2
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val10, i64* %_dest10

   ; #Call_Op at 14:48
   %_call11_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call11_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call11_Param_Area, i64* %_call11_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 14:48
   %_dest12 = getelementptr i64* %_Local_Area, i64 5
   store i64 3, i64* %_dest12

   ; #Call_Op at 14:48
   %_desc_ptr_ptr130 = load i64*** @$Types
   %_desc_ptr130 = getelementptr i64** %_desc_ptr_ptr130, i64 0
   %_call13_Static_Link = load i64** %_desc_ptr130
   %_call13_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call13_Param_Area, i64* %_call13_Static_Link)

   ; #Skip_Op at 14:34
   br label %_lbl16

_lbl15:
   ; #Store_Int_Lit_Op at 14:34
   %_dest15 = getelementptr i64* %_Local_Area, i64 3
   store i64 0, i64* %_dest15

   br label %_lbl16

_lbl16:
   ; #Copy_Word_Op at 14:9
   %_source16 = getelementptr i64* %_Local_Area, i64 3
   %_source_val16 = load i64* %_source16
   %_dest16 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val16, i64* %_dest16

   ; #Check_Not_Null_Op at 14:9
   %_arg_ptr17 = getelementptr i64* %_Param_Area, i64 0
   %_arg17 = load i64* %_arg_ptr17
   %_desc_ptr_ptr170 = load i64*** @$Types
   %_desc_ptr170 = getelementptr i64** %_desc_ptr_ptr170, i64 1
   %_desc17 = load i64** %_desc_ptr170
   %_result17 = call i1 @_psc_is_null_value(i64 %_arg17, i64* %_desc17)
   br i1 %_result17, label %_fail17, label %_lbl18
   _fail17:
   %_str_ptr_ptr17 = load i64** @$Strings
   %_str_ptr17 = getelementptr i64* %_str_ptr_ptr17, i64 2
   %_assert_str17 = load i64* %_str_ptr17
   %_print_param17 = alloca i64
   store i64 %_assert_str17, i64* %_print_param17
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param17, i64* null)

   br label %_lbl18

_lbl18:
   ; #Return_Op at 14:9
   ret void

}

define void @"PSL.Core.Closed_Interval.$=?$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 7
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Copy_Word_Op at 22:12
   %_source1 = getelementptr i64* %_Param_Area, i64 1
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val1, i64* %_dest1

   ; #Copy_Word_Op at 22:17
   %_reg_ptr21_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr21 = bitcast i64* %_reg_ptr21_Orig to i64**
   %_reg21 = load i64** %_reg_ptr21
   %_source2 = getelementptr i64* %_reg21, i64 2
   %_source_val2 = load i64* %_source2
   %_dest2 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val2, i64* %_dest2

   ; #Copy_Word_Op at 22:24
   %_source3 = getelementptr i64* %_Param_Area, i64 2
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val3, i64* %_dest3

   ; #Copy_Word_Op at 22:30
   %_reg_ptr41_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr41 = bitcast i64* %_reg_ptr41_Orig to i64**
   %_reg41 = load i64** %_reg_ptr41
   %_source4 = getelementptr i64* %_reg41, i64 1
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val4, i64* %_dest4

   ; #Call_Op at 22:22
   %_call5_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call5_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call5_Param_Area, i64* %_call5_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 22:22
   %_dest6 = getelementptr i64* %_Local_Area, i64 5
   store i64 1, i64* %_dest6

   ; #Call_Op at 22:22
   %_desc_ptr_ptr70 = load i64*** @$Types
   %_desc_ptr70 = getelementptr i64** %_desc_ptr_ptr70, i64 0
   %_call7_Static_Link = load i64** %_desc_ptr70
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #If_Op at 22:22
   %_if_source_ptr8 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val8 = load i64* %_if_source_ptr8
   %_shifted8 = shl i64 1, %_if_source_val8
   %_and8 = and i64 %_shifted8, 2
   %_if_source_trunc8 = icmp ne i64 %_and8, 0
   br i1 %_if_source_trunc8, label %_lbl9, label %_lbl13

_lbl9:
   ; #Copy_Word_Op at 23:20
   %_source9 = getelementptr i64* @$Anon_Const_1, i64 0
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val9, i64* %_dest9

   ; #Copy_Word_Op at 23:13
   %_source10 = getelementptr i64* %_Local_Area, i64 3
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val10, i64* %_dest10

   ; #Check_Not_Null_Op at 23:13
   %_arg_ptr11 = getelementptr i64* %_Param_Area, i64 0
   %_arg11 = load i64* %_arg_ptr11
   %_desc_ptr_ptr110 = load i64*** @$Types
   %_desc_ptr110 = getelementptr i64** %_desc_ptr_ptr110, i64 0
   %_desc11 = load i64** %_desc_ptr110
   %_result11 = call i1 @_psc_is_null_value(i64 %_arg11, i64* %_desc11)
   br i1 %_result11, label %_fail11, label %_lbl12
   _fail11:
   %_str_ptr_ptr11 = load i64** @$Strings
   %_str_ptr11 = getelementptr i64* %_str_ptr_ptr11, i64 4
   %_assert_str11 = load i64* %_str_ptr11
   %_print_param11 = alloca i64
   store i64 %_assert_str11, i64* %_print_param11
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param11, i64* null)

   br label %_lbl12

_lbl12:
   ; #Return_Op at 23:13
   ret void

_lbl13:
   ; #Copy_Word_Op at 24:15
   %_source13 = getelementptr i64* %_Param_Area, i64 1
   %_source_val13 = load i64* %_source13
   %_dest13 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val13, i64* %_dest13

   ; #Copy_Word_Op at 24:20
   %_reg_ptr141_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr141 = bitcast i64* %_reg_ptr141_Orig to i64**
   %_reg141 = load i64** %_reg_ptr141
   %_source14 = getelementptr i64* %_reg141, i64 1
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val14, i64* %_dest14

   ; #Copy_Word_Op at 24:26
   %_source15 = getelementptr i64* %_Param_Area, i64 2
   %_source_val15 = load i64* %_source15
   %_dest15 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val15, i64* %_dest15

   ; #Copy_Word_Op at 24:32
   %_reg_ptr161_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr161 = bitcast i64* %_reg_ptr161_Orig to i64**
   %_reg161 = load i64** %_reg_ptr161
   %_source16 = getelementptr i64* %_reg161, i64 2
   %_source_val16 = load i64* %_source16
   %_dest16 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val16, i64* %_dest16

   ; #Call_Op at 24:24
   %_call17_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call17_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call17_Param_Area, i64* %_call17_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 24:24
   %_dest18 = getelementptr i64* %_Local_Area, i64 5
   store i64 4, i64* %_dest18

   ; #Call_Op at 24:24
   %_desc_ptr_ptr190 = load i64*** @$Types
   %_desc_ptr190 = getelementptr i64** %_desc_ptr_ptr190, i64 0
   %_call19_Static_Link = load i64** %_desc_ptr190
   %_call19_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call19_Param_Area, i64* %_call19_Static_Link)

   ; #If_Op at 24:24
   %_if_source_ptr20 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val20 = load i64* %_if_source_ptr20
   %_shifted20 = shl i64 1, %_if_source_val20
   %_and20 = and i64 %_shifted20, 2
   %_if_source_trunc20 = icmp ne i64 %_and20, 0
   br i1 %_if_source_trunc20, label %_lbl21, label %_lbl25

_lbl21:
   ; #Copy_Word_Op at 25:20
   %_source21 = getelementptr i64* @$Anon_Const_2, i64 0
   %_source_val21 = load i64* %_source21
   %_dest21 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val21, i64* %_dest21

   ; #Copy_Word_Op at 25:13
   %_source22 = getelementptr i64* %_Local_Area, i64 3
   %_source_val22 = load i64* %_source22
   %_dest22 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val22, i64* %_dest22

   ; #Check_Not_Null_Op at 25:13
   %_arg_ptr23 = getelementptr i64* %_Param_Area, i64 0
   %_arg23 = load i64* %_arg_ptr23
   %_desc_ptr_ptr230 = load i64*** @$Types
   %_desc_ptr230 = getelementptr i64** %_desc_ptr_ptr230, i64 0
   %_desc23 = load i64** %_desc_ptr230
   %_result23 = call i1 @_psc_is_null_value(i64 %_arg23, i64* %_desc23)
   br i1 %_result23, label %_fail23, label %_lbl24
   _fail23:
   %_str_ptr_ptr23 = load i64** @$Strings
   %_str_ptr23 = getelementptr i64* %_str_ptr_ptr23, i64 5
   %_assert_str23 = load i64* %_str_ptr23
   %_print_param23 = alloca i64
   store i64 %_assert_str23, i64* %_print_param23
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param23, i64* null)

   br label %_lbl24

_lbl24:
   ; #Return_Op at 25:13
   ret void

_lbl25:
   ; #Copy_Word_Op at 26:15
   %_source25 = getelementptr i64* %_Param_Area, i64 1
   %_source_val25 = load i64* %_source25
   %_dest25 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val25, i64* %_dest25

   ; #Copy_Word_Op at 26:20
   %_reg_ptr261_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr261 = bitcast i64* %_reg_ptr261_Orig to i64**
   %_reg261 = load i64** %_reg_ptr261
   %_source26 = getelementptr i64* %_reg261, i64 1
   %_source_val26 = load i64* %_source26
   %_dest26 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val26, i64* %_dest26

   ; #Copy_Word_Op at 26:27
   %_source27 = getelementptr i64* %_Param_Area, i64 2
   %_source_val27 = load i64* %_source27
   %_dest27 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val27, i64* %_dest27

   ; #Copy_Word_Op at 26:33
   %_reg_ptr281_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr281 = bitcast i64* %_reg_ptr281_Orig to i64**
   %_reg281 = load i64** %_reg_ptr281
   %_source28 = getelementptr i64* %_reg281, i64 1
   %_source_val28 = load i64* %_source28
   %_dest28 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val28, i64* %_dest28

   ; #Call_Op at 26:24
   %_call29_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call29_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call29_Param_Area, i64* %_call29_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 26:24
   %_dest30 = getelementptr i64* %_Local_Area, i64 5
   store i64 2, i64* %_dest30

   ; #Call_Op at 26:24
   %_desc_ptr_ptr310 = load i64*** @$Types
   %_desc_ptr310 = getelementptr i64** %_desc_ptr_ptr310, i64 0
   %_call31_Static_Link = load i64** %_desc_ptr310
   %_call31_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call31_Param_Area, i64* %_call31_Static_Link)

   ; #If_Op at 26:37
   %_if_source_ptr32 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val32 = load i64* %_if_source_ptr32
   %_shifted32 = shl i64 1, %_if_source_val32
   %_and32 = and i64 %_shifted32, 2
   %_if_source_trunc32 = icmp ne i64 %_and32, 0
   br i1 %_if_source_trunc32, label %_lbl33, label %_lbl41

_lbl33:
   ; #Copy_Word_Op at 27:11
   %_source33 = getelementptr i64* %_Param_Area, i64 1
   %_source_val33 = load i64* %_source33
   %_dest33 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val33, i64* %_dest33

   ; #Copy_Word_Op at 27:16
   %_reg_ptr341_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr341 = bitcast i64* %_reg_ptr341_Orig to i64**
   %_reg341 = load i64** %_reg_ptr341
   %_source34 = getelementptr i64* %_reg341, i64 2
   %_source_val34 = load i64* %_source34
   %_dest34 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val34, i64* %_dest34

   ; #Copy_Word_Op at 27:24
   %_source35 = getelementptr i64* %_Param_Area, i64 2
   %_source_val35 = load i64* %_source35
   %_dest35 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val35, i64* %_dest35

   ; #Copy_Word_Op at 27:30
   %_reg_ptr361_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr361 = bitcast i64* %_reg_ptr361_Orig to i64**
   %_reg361 = load i64** %_reg_ptr361
   %_source36 = getelementptr i64* %_reg361, i64 2
   %_source_val36 = load i64* %_source36
   %_dest36 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val36, i64* %_dest36

   ; #Call_Op at 27:21
   %_call37_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_call37_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call37_Param_Area, i64* %_call37_Static_Link, i16 3, i16 1, i16 3, i16 10001, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 27:21
   %_dest38 = getelementptr i64* %_Local_Area, i64 5
   store i64 2, i64* %_dest38

   ; #Call_Op at 27:21
   %_desc_ptr_ptr390 = load i64*** @$Types
   %_desc_ptr390 = getelementptr i64** %_desc_ptr_ptr390, i64 0
   %_call39_Static_Link = load i64** %_desc_ptr390
   %_call39_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call39_Param_Area, i64* %_call39_Static_Link)

   ; #Skip_Op at 26:37
   br label %_lbl42

_lbl41:
   ; #Store_Int_Lit_Op at 26:37
   %_dest41 = getelementptr i64* %_Local_Area, i64 3
   store i64 0, i64* %_dest41

   br label %_lbl42

_lbl42:
   ; #If_Op at 26:37
   %_if_source_ptr42 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val42 = load i64* %_if_source_ptr42
   %_shifted42 = shl i64 1, %_if_source_val42
   %_and42 = and i64 %_shifted42, 2
   %_if_source_trunc42 = icmp ne i64 %_and42, 0
   br i1 %_if_source_trunc42, label %_lbl43, label %_lbl47

_lbl43:
   ; #Copy_Word_Op at 28:20
   %_source43 = getelementptr i64* @$Anon_Const_3, i64 0
   %_source_val43 = load i64* %_source43
   %_dest43 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val43, i64* %_dest43

   ; #Copy_Word_Op at 28:13
   %_source44 = getelementptr i64* %_Local_Area, i64 3
   %_source_val44 = load i64* %_source44
   %_dest44 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val44, i64* %_dest44

   ; #Check_Not_Null_Op at 28:13
   %_arg_ptr45 = getelementptr i64* %_Param_Area, i64 0
   %_arg45 = load i64* %_arg_ptr45
   %_desc_ptr_ptr450 = load i64*** @$Types
   %_desc_ptr450 = getelementptr i64** %_desc_ptr_ptr450, i64 0
   %_desc45 = load i64** %_desc_ptr450
   %_result45 = call i1 @_psc_is_null_value(i64 %_arg45, i64* %_desc45)
   br i1 %_result45, label %_fail45, label %_lbl46
   _fail45:
   %_str_ptr_ptr45 = load i64** @$Strings
   %_str_ptr45 = getelementptr i64* %_str_ptr_ptr45, i64 6
   %_assert_str45 = load i64* %_str_ptr45
   %_print_param45 = alloca i64
   store i64 %_assert_str45, i64* %_print_param45
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param45, i64* null)

   br label %_lbl46

_lbl46:
   ; #Return_Op at 28:13
   ret void

_lbl47:
   ; #Copy_Word_Op at 30:20
   %_source47 = getelementptr i64* @$Anon_Const_4, i64 0
   %_source_val47 = load i64* %_source47
   %_dest47 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val47, i64* %_dest47

   ; #Copy_Word_Op at 30:13
   %_source48 = getelementptr i64* %_Local_Area, i64 3
   %_source_val48 = load i64* %_source48
   %_dest48 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val48, i64* %_dest48

   ; #Check_Not_Null_Op at 30:13
   %_arg_ptr49 = getelementptr i64* %_Param_Area, i64 0
   %_arg49 = load i64* %_arg_ptr49
   %_desc_ptr_ptr490 = load i64*** @$Types
   %_desc_ptr490 = getelementptr i64** %_desc_ptr_ptr490, i64 0
   %_desc49 = load i64** %_desc_ptr490
   %_result49 = call i1 @_psc_is_null_value(i64 %_arg49, i64* %_desc49)
   br i1 %_result49, label %_fail49, label %_lbl50
   _fail49:
   %_str_ptr_ptr49 = load i64** @$Strings
   %_str_ptr49 = getelementptr i64* %_str_ptr_ptr49, i64 7
   %_assert_str49 = load i64* %_str_ptr49
   %_print_param49 = alloca i64
   store i64 %_assert_str49, i64* %_print_param49
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param49, i64* null)

   br label %_lbl50

_lbl50:
   ; #Return_Op at 30:13
   ret void

}

