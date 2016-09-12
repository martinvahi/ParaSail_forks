declare void @"PSL.Containers.Set.$[]$"(i64*, i64*, i64*)
declare void @_psc_assign_word(i64*, i64*, i64*, i64)
declare void @"PSL.Containers.Map.$var_indexing$"(i64*, i64*, i64*)
declare void @"_psc_ordering_to_bool"(i64*, i64*, i64*)
declare i32 @_psc_execute_wait_for_parallel_op(i64*, i64*)
declare void @_psc_register_compiled_operations(i16, i16*, void(i64*, i64*, i64*)**, i8*, i64*, i32, i16*, i32(i64*, i64*, i64*)**)
declare void @_psc_initialize_stg_rgn(i64*, i64*)
declare void @"_psc_runtime_message"(i64*, i64*, i64*)
declare void @"PSL.Containers.Map.$<|=$"(i64*, i64*, i64*)
declare void @_psc_execute_compiled_parallel_call_op(i64*, i64*, i64*, void(i64*, i64*, i64*)*, i64* , i32(i64*, i64*, i64*)*, i1, i1, i8)
declare void @"PSL.Containers.Map.$in$"(i64*, i64*, i64*)
declare void @_psc_move_object(i64*, i64*, i64*, i64*)
declare i64 @_psc_new_object(i64*, i64*, i64)
declare i1 @_psc_is_null_value(i64, i64*)
declare void @"PSL.Containers.Set.$|=$.2"(i64*, i64*, i64*)
declare void @_psc_reconstruct_type_descriptors(i16, i8**, i64*, i64**)
declare void @"PSL.Containers.Set.Is_Empty"(i64*, i64*, i64*)
declare void @"PSL.Containers.Map.$[]$"(i64*, i64*, i64*)
declare i64 @_psc_copy_object(i64*, i64*, i64, i64)
declare i64 @_psc_local_null(i64*, i64*)
declare void @_psc_execute_compiled_indirect_call_op(i64*, i64*, i64*, i16, i16, i16, i16, i64, void(i64*, i64*, i64*)*, i8)
declare void @"PSL.Containers.Map.$|=$"(i64*, i64*, i64*)
declare void @"PSL.Containers.Map.$indexing$"(i64*, i64*, i64*)
declare void @"PSL.Containers.Map.$-=$"(i64*, i64*, i64*)
declare void @"PSL.Containers.Key_Value.$var_indexing$"(i64*, i64*, i64*)
declare i64* @_psc_get_type_desc_or_op_map(i64*, i16, i16)
declare i64 @_psc_null_of_same_stg_rgn(i64*, i64)
declare void @_psc_reconstruct_strings(i16, i8**, i64*)
declare void @"PSL.Containers.Set.Remove_Any"(i64*, i64*, i64*)
declare void @"PSL.Containers.Key_Value.$[]$"(i64*, i64*, i64*)
declare void @_psc_finalize_stg_rgn(i64*, i64*)

@$Module_Op_Indices = internal constant [20 x i16] [
i16 1, i16 2, i16 1, i16 6, i16 1, i16 10, i16 1, i16 11, i16 1, i16 12
, i16 1, i16 5, i16 1, i16 8, i16 1, i16 9, i16 1, i16 3, i16 1, i16 13]

@$Local_Funcs = internal constant [10 x void(i64*, i64*, i64*)*] [
void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.Add_Unreversed"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$|$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$-=$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$var_indexing$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.Key_Of"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$|=$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$<|=$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$<|=$.2"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.$[]$"
, void(i64*, i64*, i64*)* @"PSL.Containers.Two_Way_Map.Rev_Map"]

@$Local_Funcs_Use_Queuing = internal constant [10 x i8] [
i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0]

@$Internal_Precond_Indices = internal constant [0 x i16] [
]

@$Internal_Precond_Blocks = internal constant [0 x i32(i64*, i64*, i64*)*] [
]

@"PSL.Core.Ordering" = internal constant [432 x i8] 

[i8 0, i8 173, i8 77, i8 254, i8 90, i8 173, i8 77, i8 254, i8 90, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 20, i8 0
, i8 241, i8 255, i8 255, i8 255, i8 0, i8 1, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 128, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 20, i8 0, i8 15, i8 0, i8 240, i8 255, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 1, i8 0, i8 0, i8 1, i8 192, i8 15, i8 0, i8 239, i8 255
, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 2, i8 0, i8 0, i8 1, i8 1, i8 15
, i8 0, i8 238, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 3, i8 0, i8 0
, i8 1, i8 1, i8 15, i8 0, i8 237, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 4, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 15, i8 0, i8 236, i8 255
, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 5, i8 0, i8 0, i8 1, i8 1, i8 15
, i8 0, i8 21, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 6, i8 0, i8 0
, i8 1, i8 1, i8 15, i8 0, i8 22, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 7, i8 0, i8 0, i8 1, i8 192, i8 15, i8 0, i8 233, i8 255, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 8, i8 0, i8 0, i8 2, i8 192, i8 1, i8 15, i8 0
, i8 233, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 9, i8 0, i8 0, i8 2
, i8 192, i8 1, i8 15, i8 0, i8 232, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0
, i8 0, i8 10, i8 0, i8 0, i8 2, i8 192, i8 1, i8 15, i8 0, i8 232, i8 255
, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 11, i8 0, i8 0, i8 2, i8 192, i8 1
, i8 15, i8 0, i8 231, i8 255, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 12, i8 0
, i8 0, i8 3, i8 192, i8 1, i8 2, i8 15, i8 0, i8 230, i8 255, i8 27, i8 0
, i8 0, i8 0, i8 0, i8 0, i8 13, i8 0, i8 0, i8 3, i8 192, i8 1, i8 2, i8 15
, i8 0, i8 27, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 14, i8 0, i8 0
, i8 1, i8 192, i8 15, i8 0, i8 28, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0
, i8 15, i8 0, i8 0, i8 1, i8 192, i8 15, i8 0, i8 29, i8 0, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 16, i8 0, i8 0, i8 2, i8 1, i8 2, i8 15, i8 0, i8 30
, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 17, i8 0, i8 0, i8 2, i8 1
, i8 2, i8 15, i8 0, i8 31, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 18
, i8 0, i8 0, i8 2, i8 1, i8 2, i8 15, i8 0, i8 32, i8 0, i8 27, i8 0, i8 0
, i8 0, i8 0, i8 0, i8 19, i8 0, i8 0, i8 2, i8 1, i8 2, i8 15, i8 0, i8 6
, i8 0, i8 27, i8 0, i8 0, i8 0, i8 0, i8 0, i8 20, i8 0, i8 0, i8 2, i8 1
, i8 2]

@$Type_Desc_Streams = internal constant [1 x i8*] [
 i8* getelementptr ([432 x i8]* @"PSL.Core.Ordering", i64 0, i64 0)]
@$Type_Descriptors = internal global [1 x i64*]
[i64* null]
@$Types = internal constant i64** bitcast ([1 x i64*]* @$Type_Descriptors to i64**)
@$str_stream1 = internal constant [32 x i8] 

[i8 28, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 110, i8 116, i8 97, i8 105, i8 110, i8 101, i8 114, i8 115, i8 58, i8 58
, i8 84, i8 119, i8 111, i8 95, i8 87, i8 97, i8 121, i8 95, i8 77, i8 97
, i8 112]

@$str_stream2 = internal constant [18 x i8] 

[i8 14, i8 0, i8 0, i8 0, i8 65, i8 100, i8 100, i8 95, i8 85, i8 110, i8 114
, i8 101, i8 118, i8 101, i8 114, i8 115, i8 101, i8 100]

@$str_stream3 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 91, i8 93, i8 34]

@$str_stream4 = internal constant [100 x i8] 

[i8 96, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 51, i8 54, i8 116, i8 119
, i8 111, i8 95, i8 119, i8 97, i8 121, i8 95, i8 109, i8 97, i8 112, i8 46
, i8 112, i8 115, i8 105, i8 58, i8 53, i8 51, i8 58, i8 57, i8 58, i8 32
, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58, i8 32, i8 78, i8 117, i8 108
, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117, i8 101, i8 32, i8 110, i8 111
, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109, i8 105, i8 116, i8 116, i8 101
, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101, i8 58, i8 32, i8 10]

@$str_stream5 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 124, i8 61, i8 34]

@$str_stream6 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 124, i8 34]

@$str_stream7 = internal constant [100 x i8] 

[i8 96, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 51, i8 54, i8 116, i8 119
, i8 111, i8 95, i8 119, i8 97, i8 121, i8 95, i8 109, i8 97, i8 112, i8 46
, i8 112, i8 115, i8 105, i8 58, i8 55, i8 48, i8 58, i8 53, i8 58, i8 32
, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58, i8 32, i8 78, i8 117, i8 108
, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117, i8 101, i8 32, i8 110, i8 111
, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109, i8 105, i8 116, i8 116, i8 101
, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101, i8 58, i8 32, i8 10]

@$str_stream8 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 60, i8 124, i8 61, i8 34]

@$str_stream9 = internal constant [11 x i8] 

[i8 7, i8 0, i8 0, i8 0, i8 34, i8 60, i8 124, i8 61, i8 34, i8 35, i8 50]

@$str_stream10 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 45, i8 61, i8 34]

@$str_stream11 = internal constant [18 x i8] 

[i8 14, i8 0, i8 0, i8 0, i8 34, i8 118, i8 97, i8 114, i8 95, i8 105, i8 110
, i8 100, i8 101, i8 120, i8 105, i8 110, i8 103, i8 34]

@$str_stream12 = internal constant [10 x i8] 

[i8 6, i8 0, i8 0, i8 0, i8 75, i8 101, i8 121, i8 95, i8 79, i8 102]

@$str_stream13 = internal constant [11 x i8] 

[i8 7, i8 0, i8 0, i8 0, i8 82, i8 101, i8 118, i8 95, i8 77, i8 97, i8 112]

@$str_stream14 = internal constant [101 x i8] 

[i8 97, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 51, i8 54, i8 116, i8 119
, i8 111, i8 95, i8 119, i8 97, i8 121, i8 95, i8 109, i8 97, i8 112, i8 46
, i8 112, i8 115, i8 105, i8 58, i8 49, i8 51, i8 54, i8 58, i8 53, i8 58
, i8 32, i8 69, i8 114, i8 114, i8 111, i8 114, i8 58, i8 32, i8 78, i8 117
, i8 108, i8 108, i8 32, i8 118, i8 97, i8 108, i8 117, i8 101, i8 32, i8 110
, i8 111, i8 116, i8 32, i8 112, i8 101, i8 114, i8 109, i8 105, i8 116, i8 116
, i8 101, i8 100, i8 32, i8 104, i8 101, i8 114, i8 101, i8 58, i8 32, i8 10]

@$str_stream15 = internal constant [23 x i8] 

[i8 19, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 114, i8 101, i8 58, i8 58, i8 79, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103]

@$str_stream16 = internal constant [23 x i8] 

[i8 19, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 102, i8 114, i8 111, i8 109, i8 95, i8 117, i8 110
, i8 105, i8 118]

@$str_stream17 = internal constant [21 x i8] 

[i8 17, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 116, i8 111, i8 95, i8 117, i8 110, i8 105, i8 118]

@$str_stream18 = internal constant [21 x i8] 

[i8 17, i8 0, i8 0, i8 0, i8 35, i8 111, i8 114, i8 100, i8 101, i8 114, i8 105
, i8 110, i8 103, i8 95, i8 116, i8 111, i8 95, i8 98, i8 111, i8 111, i8 108]

@$str_stream19 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 61, i8 63, i8 34]

@$str_stream20 = internal constant [13 x i8] 

[i8 9, i8 0, i8 0, i8 0, i8 35, i8 105, i8 100, i8 101, i8 110, i8 116, i8 105
, i8 116, i8 121]

@$str_stream21 = internal constant [13 x i8] 

[i8 9, i8 0, i8 0, i8 0, i8 84, i8 111, i8 95, i8 83, i8 116, i8 114, i8 105
, i8 110, i8 103]

@$str_stream22 = internal constant [15 x i8] 

[i8 11, i8 0, i8 0, i8 0, i8 70, i8 114, i8 111, i8 109, i8 95, i8 83, i8 116
, i8 114, i8 105, i8 110, i8 103]

@$str_stream23 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 43, i8 34]

@$str_stream24 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 45, i8 34]

@$str_stream25 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 35, i8 109, i8 105, i8 110]

@$str_stream26 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 35, i8 109, i8 97, i8 120]

@$str_stream27 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 70, i8 105, i8 114, i8 115, i8 116]

@$str_stream28 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 76, i8 97, i8 115, i8 116]

@$str_stream29 = internal constant [8 x i8] 

[i8 4, i8 0, i8 0, i8 0, i8 34, i8 46, i8 46, i8 34]

@$str_stream30 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 60, i8 46, i8 46, i8 34]

@$str_stream31 = internal constant [9 x i8] 

[i8 5, i8 0, i8 0, i8 0, i8 34, i8 46, i8 46, i8 60, i8 34]

@$str_stream32 = internal constant [10 x i8] 

[i8 6, i8 0, i8 0, i8 0, i8 34, i8 60, i8 46, i8 46, i8 60, i8 34]

@$Str_Streams = internal constant [32 x i8*] [
i8* getelementptr ([32 x i8]* @$str_stream1, i64 0, i64 0), 
i8* getelementptr ([18 x i8]* @$str_stream2, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream3, i64 0, i64 0), 
i8* getelementptr ([100 x i8]* @$str_stream4, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream5, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream6, i64 0, i64 0), 
i8* getelementptr ([100 x i8]* @$str_stream7, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream8, i64 0, i64 0), 
i8* getelementptr ([11 x i8]* @$str_stream9, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream10, i64 0, i64 0), 
i8* getelementptr ([18 x i8]* @$str_stream11, i64 0, i64 0), 
i8* getelementptr ([10 x i8]* @$str_stream12, i64 0, i64 0), 
i8* getelementptr ([11 x i8]* @$str_stream13, i64 0, i64 0), 
i8* getelementptr ([101 x i8]* @$str_stream14, i64 0, i64 0), 
i8* getelementptr ([23 x i8]* @$str_stream15, i64 0, i64 0), 
i8* getelementptr ([23 x i8]* @$str_stream16, i64 0, i64 0), 
i8* getelementptr ([21 x i8]* @$str_stream17, i64 0, i64 0), 
i8* getelementptr ([21 x i8]* @$str_stream18, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream19, i64 0, i64 0), 
i8* getelementptr ([13 x i8]* @$str_stream20, i64 0, i64 0), 
i8* getelementptr ([13 x i8]* @$str_stream21, i64 0, i64 0), 
i8* getelementptr ([15 x i8]* @$str_stream22, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream23, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream24, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream25, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream26, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream27, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream28, i64 0, i64 0), 
i8* getelementptr ([8 x i8]* @$str_stream29, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream30, i64 0, i64 0), 
i8* getelementptr ([9 x i8]* @$str_stream31, i64 0, i64 0), 
i8* getelementptr ([10 x i8]* @$str_stream32, i64 0, i64 0)]
@$String_Table = internal global [32 x i64] 
[i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, i64 0, 
 i64 0, i64 0, i64 0]
@$Strings = internal constant i64* bitcast ([32 x i64]* @$String_Table to i64*)
@_psc_global_to_do = external global {i64*, void()*}*
define internal void @$initialize_streams() {
   %_Str_Tab = load i64** @$Strings
   call void @_psc_reconstruct_strings(i16 32, i8** getelementptr ([32 x i8*]* @$Str_Streams, i64 0, i64 0), i64* %_Str_Tab)
   %_desc = load i64*** @$Types
   call void @_psc_reconstruct_type_descriptors(i16 1, i8** getelementptr ([1 x i8*]* @$Type_Desc_Streams, i64 0, i64 0), i64* %_Str_Tab, i64** %_desc)
   call void @_psc_register_compiled_operations(i16 10, i16* getelementptr ([20 x i16]* @$Module_Op_Indices, i64 0, i64 0), void(i64*, i64*, i64*)** getelementptr ([10 x void(i64*, i64*, i64*)*]* @$Local_Funcs, i64 0, i64 0), i8* getelementptr ([10 x i8]* @$Local_Funcs_Use_Queuing, i64 0, i64 0), i64* %_Str_Tab, i32 0, i16* getelementptr ([0 x i16]* @$Internal_Precond_Indices, i64 0, i64 0), i32(i64*, i64*, i64*)** getelementptr ([0 x i32(i64*, i64*, i64*)*]* @$Internal_Precond_Blocks, i64 0 , i64 0))
   ret void
}
@"_node_/Users/stt/_parasail/lib/aaa/aaa036two_way_map.psi" = global {i64*, void()*} {i64* null, void()* @$initialize_streams}
define internal void @$add_to_todo() {
   %_next = load {i64*, void()*}** @_psc_global_to_do
   %_nextc = bitcast {i64*, void()*}* %_next to i64*
   %_node.next_ptr = getelementptr {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa036two_way_map.psi", i32 0, i32 0
   store i64* %_nextc, i64** %_node.next_ptr
   store {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa036two_way_map.psi", {i64*, void()*}** @_psc_global_to_do
   ret void
}
@llvm.global_ctors = appending global [1 x {i32, void ()*}] [{i32, void()*} {i32 65535, void ()* @$add_to_todo}]

define internal void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 12
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   br label %_lbl1

_lbl1:
   ; #Copy_Word_Op at 44:29
   %_source1 = getelementptr i64* %_Param_Area, i64 0
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val1, i64* %_dest1

   ; #Copy_Word_Op at 44:29
   %_reg_ptr21_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr21 = bitcast i64* %_reg_ptr21_Orig to i64**
   %_reg21 = load i64** %_reg_ptr21
   %_source2 = getelementptr i64* %_reg21, i64 0
   %_source_val2 = load i64* %_source2
   %_dest2 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val2, i64* %_dest2

   ; #Copy_Word_Op at 44:31
   %_reg_ptr31_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr31 = bitcast i64* %_reg_ptr31_Orig to i64**
   %_reg31 = load i64** %_reg_ptr31
   %_source3 = getelementptr i64* %_reg31, i64 3
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val3, i64* %_dest3

   ; #Call_Op at 44:19
   %_call4_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_call4_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Set.Is_Empty"(i64* %_Context, i64* %_call4_Param_Area, i64* %_call4_Static_Link)

   ; #Call_Op at 44:19
   %_n_ptr5 = getelementptr i64* %_Local_Area, i64 4
   %_n5 = load i64* %_n_ptr5
   %_result5 = xor i64 1, %_n5
   %_result_ptr5 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_result5, i64* %_result_ptr5

   ; #If_Op at 44:19
   %_if_source_ptr6 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val6 = load i64* %_if_source_ptr6
   %_shifted6 = shl i64 1, %_if_source_val6
   %_and6 = and i64 %_shifted6, 2
   %_if_source_trunc6 = icmp ne i64 %_and6, 0
   br i1 %_if_source_trunc6, label %_lbl7, label %_lbl29

_lbl7:
   ; #Store_Local_Null_Op at 45:17
   %_desc7 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_null7 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc7)
   %_dest_ptr7 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_null7, i64* %_dest_ptr7

   ; #Copy_Word_Op at 45:35
   %_source8 = getelementptr i64* %_Param_Area, i64 0
   %_source_val8 = load i64* %_source8
   %_dest8 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val8, i64* %_dest8

   ; #Copy_Word_Op at 45:35
   %_reg_ptr91_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr91 = bitcast i64* %_reg_ptr91_Orig to i64**
   %_reg91 = load i64** %_reg_ptr91
   %_source9 = getelementptr i64* %_reg91, i64 0
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val9, i64* %_dest9

   ; #Store_Address_Op at 45:24
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_addr10 = getelementptr i64* %_reg101, i64 3
   %_addr_as_int10 = ptrtoint i64* %_addr10 to i64
   %_dest_ptr10 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int10, i64* %_dest_ptr10

   ; #Call_Op at 45:24
   %_call11_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_call11_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Set.Remove_Any"(i64* %_Context, i64* %_call11_Param_Area, i64* %_call11_Static_Link)

   ; #Copy_Word_Op at 46:13
   %_source12 = getelementptr i64* %_Param_Area, i64 0
   %_source_val12 = load i64* %_source12
   %_dest12 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val12, i64* %_dest12

   ; #Copy_Word_Op at 46:13
   %_reg_ptr131_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr131 = bitcast i64* %_reg_ptr131_Orig to i64**
   %_reg131 = load i64** %_reg_ptr131
   %_source13 = getelementptr i64* %_reg131, i64 0
   %_source_val13 = load i64* %_source13
   %_dest13 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val13, i64* %_dest13

   ; #Store_Address_Op at 46:15
   %_reg_ptr141_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr141 = bitcast i64* %_reg_ptr141_Orig to i64**
   %_reg141 = load i64** %_reg_ptr141
   %_addr14 = getelementptr i64* %_reg141, i64 2
   %_addr_as_int14 = ptrtoint i64* %_addr14 to i64
   %_dest_ptr14 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int14, i64* %_dest_ptr14

   ; #Store_Local_Null_Op at 46:26
   %_desc15 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_null15 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc15)
   %_dest_ptr15 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_null15, i64* %_dest_ptr15

   ; #Call_Op at 46:26
   %_call16_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call16_Param_Area = getelementptr i64* %_Local_Area, i64 6
   call void @"PSL.Containers.Key_Value.$[]$"(i64* %_Context, i64* %_call16_Param_Area, i64* %_call16_Static_Link)

   ; #Store_Address_Op at 46:29
   %_addr17 = getelementptr i64* %_Local_Area, i64 6
   %_addr_as_int17 = ptrtoint i64* %_addr17 to i64
   %_dest_ptr17 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_addr_as_int17, i64* %_dest_ptr17

   ; #Copy_Word_Op at 46:27
   %_source18 = getelementptr i64* %_Param_Area, i64 0
   %_source_val18 = load i64* %_source18
   %_dest18 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_source_val18, i64* %_dest18

   ; #Copy_Word_Op at 46:27
   %_reg_ptr191_Orig = getelementptr i64* %_Local_Area, i64 10
   %_reg_ptr191 = bitcast i64* %_reg_ptr191_Orig to i64**
   %_reg191 = load i64** %_reg_ptr191
   %_source19 = getelementptr i64* %_reg191, i64 0
   %_source_val19 = load i64* %_source19
   %_dest19 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_source_val19, i64* %_dest19

   ; #Store_Address_Op at 46:29
   %_reg_ptr201_Orig = getelementptr i64* %_Local_Area, i64 10
   %_reg_ptr201 = bitcast i64* %_reg_ptr201_Orig to i64**
   %_reg201 = load i64** %_reg_ptr201
   %_addr20 = getelementptr i64* %_reg201, i64 1
   %_addr_as_int20 = ptrtoint i64* %_addr20 to i64
   %_dest_ptr20 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_addr_as_int20, i64* %_dest_ptr20

   ; #Copy_Word_Op at 46:37
   %_source21 = getelementptr i64* %_Local_Area, i64 4
   %_source_val21 = load i64* %_source21
   %_dest21 = getelementptr i64* %_Local_Area, i64 11
   store i64 %_source_val21, i64* %_dest21

   ; #Call_Op at 46:29
   %_call22_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call22_Param_Area = getelementptr i64* %_Local_Area, i64 9
   call void @"PSL.Containers.Map.$indexing$"(i64* %_Context, i64* %_call22_Param_Area, i64* %_call22_Static_Link)

   ; #Copy_Word_Op at 46:29
   %_reg_ptr231_Orig = getelementptr i64* %_Local_Area, i64 9
   %_reg_ptr231 = bitcast i64* %_reg_ptr231_Orig to i64**
   %_reg231 = load i64** %_reg_ptr231
   %_source23 = getelementptr i64* %_reg231, i64 0
   %_source_val23 = load i64* %_source23
   %_dest23 = getelementptr i64* %_Local_Area, i64 9
   store i64 %_source_val23, i64* %_dest23

   ; #Call_Op at 46:29
   %_call24_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call24_Param_Area = getelementptr i64* %_Local_Area, i64 7
   call void @"PSL.Containers.Key_Value.$var_indexing$"(i64* %_Context, i64* %_call24_Param_Area, i64* %_call24_Static_Link)

   ; #Make_Copy_In_Stg_Rgn_Op at 46:45
   %_desc25 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr25 = getelementptr i64* %_Local_Area, i64 4
   %_source25 = load i64* %_source_ptr25
   %_existing_ptr25 = getelementptr i64* %_Local_Area, i64 6
   %_existing_obj25 = load i64* %_existing_ptr25
   %_result25 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc25, i64 %_source25, i64 %_existing_obj25)
   %_dest_ptr25 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_result25, i64* %_dest_ptr25

   ; #Assign_Word_Op at 46:29
   %_desc26 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr26 = getelementptr i64* %_Local_Area, i64 10
   %_source26 = load i64* %_source_ptr26
   %_reg_ptr262_Orig = getelementptr i64* %_Local_Area, i64 7
   %_reg_ptr262 = bitcast i64* %_reg_ptr262_Orig to i64**
   %_reg262 = load i64** %_reg_ptr262
   %_dest_ptr26 = getelementptr i64* %_reg262, i64 0
   call void @_psc_assign_word(i64* %_Context, i64* %_desc26, i64* %_dest_ptr26, i64 %_source26)

   ; #Call_Op at 46:15
   %_call27_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call27_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Map.$|=$"(i64* %_Context, i64* %_call27_Param_Area, i64* %_call27_Static_Link)

   ; #Skip_Op at 44:9
   br label %_lbl1

_lbl29:
   ; #Return_Op at 48:5
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$[]$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 32
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 53:43
   %_desc1 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_source_ptr1 = getelementptr i64* %_Param_Area, i64 0
   %_source1 = load i64* %_source_ptr1
   %_null1 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc1, i64 %_source1)
   %_dest_ptr1 = getelementptr i64* %_Local_Area, i64 16
   store i64 %_null1, i64* %_dest_ptr1

   ; #Start_Parallel_Call_Op at 53:43
   %_master2 = getelementptr i64* %_Local_Area, i64 3
   %_static_Link2 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_control2 = getelementptr i64* %_Local_Area, i64 6
   call void @_psc_execute_compiled_parallel_call_op(i64* %_Context, i64* %_master2, i64* %_control2, void(i64*, i64*, i64*)* @"PSL.Containers.Map.$[]$", i64* %_static_Link2, i32(i64*, i64*, i64*)* null, i1 1, i1 1, i8 0)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 53:61
   %_desc3 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_source_ptr3 = getelementptr i64* %_Param_Area, i64 0
   %_source3 = load i64* %_source_ptr3
   %_null3 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc3, i64 %_source3)
   %_dest_ptr3 = getelementptr i64* %_Local_Area, i64 27
   store i64 %_null3, i64* %_dest_ptr3

   ; #Add_Parallel_Call_Op at 53:61
   %_master4 = getelementptr i64* %_Local_Area, i64 3
   %_static_Link4 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_control4 = getelementptr i64* %_Local_Area, i64 17
   call void @_psc_execute_compiled_parallel_call_op(i64* %_Context, i64* %_master4, i64* %_control4, void(i64*, i64*, i64*)* @"PSL.Containers.Set.$[]$", i64* %_static_Link4, i32(i64*, i64*, i64*)* null, i1 1, i1 0, i8 0)

   ; #Create_Obj_Op at 53:16
   %_desc5 = getelementptr i64* %_Static_Link, i64 0
   %_src_addr5 = getelementptr i64* %_Param_Area, i64 0
   %_src5 = load i64* %_src_addr5
   %_dest5 = call i64 @_psc_new_object(i64* %_Context, i64* %_desc5, i64 %_src5)
   %_dest_addr5 = getelementptr i64* %_Local_Area, i64 28
   store i64 %_dest5, i64* %_dest_addr5

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 53:28
   %_desc6 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_source_ptr6 = getelementptr i64* %_Local_Area, i64 28
   %_source6 = load i64* %_source_ptr6
   %_null6 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc6, i64 %_source6)
   %_dest_ptr6 = getelementptr i64* %_Local_Area, i64 29
   store i64 %_null6, i64* %_dest_ptr6

   ; #Call_Op at 53:28
   %_call7_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 29
   call void @"PSL.Containers.Map.$[]$"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #Copy_Word_Op at 53:28
   %_source8 = getelementptr i64* %_Local_Area, i64 29
   %_source_val8 = load i64* %_source8
   %_reg_ptr82_Orig = getelementptr i64* %_Local_Area, i64 28
   %_reg_ptr82 = bitcast i64* %_reg_ptr82_Orig to i64**
   %_reg82 = load i64** %_reg_ptr82
   %_dest8 = getelementptr i64* %_reg82, i64 1
   store i64 %_source_val8, i64* %_dest8

   ; #Wait_For_Parallel_Op at 53:43
   %_master9 = getelementptr i64* %_Local_Area, i64 3
   %_level_skip9 = call i32 @_psc_execute_wait_for_parallel_op(i64* %_Context, i64* %_master9)
   %_level_diff32_9 = ashr i32 %_level_skip9, 16
   %_level_diff9 = trunc i32 %_level_diff32_9 to i16
   %_skip_count9 = trunc i32 %_level_skip9 to i16
   %_level_diff_nz9 = icmp ne i16 %_level_diff9, 0
   br i1 %_level_diff_nz9, label %_exit9, label %_switch9
   _exit9:
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void
   _switch9:
   br label %_lbl10

_lbl10:
   ; #Copy_Word_Op at 53:43
   %_source10 = getelementptr i64* %_Local_Area, i64 16
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 30
   store i64 %_source_val10, i64* %_dest10

   ; #Copy_Word_Op at 53:43
   %_source11 = getelementptr i64* %_Local_Area, i64 30
   %_source_val11 = load i64* %_source11
   %_reg_ptr112_Orig = getelementptr i64* %_Local_Area, i64 28
   %_reg_ptr112 = bitcast i64* %_reg_ptr112_Orig to i64**
   %_reg112 = load i64** %_reg_ptr112
   %_dest11 = getelementptr i64* %_reg112, i64 2
   store i64 %_source_val11, i64* %_dest11

   ; #Copy_Word_Op at 53:61
   %_source12 = getelementptr i64* %_Local_Area, i64 27
   %_source_val12 = load i64* %_source12
   %_dest12 = getelementptr i64* %_Local_Area, i64 31
   store i64 %_source_val12, i64* %_dest12

   ; #Copy_Word_Op at 53:61
   %_source13 = getelementptr i64* %_Local_Area, i64 31
   %_source_val13 = load i64* %_source13
   %_reg_ptr132_Orig = getelementptr i64* %_Local_Area, i64 28
   %_reg_ptr132 = bitcast i64* %_reg_ptr132_Orig to i64**
   %_reg132 = load i64** %_reg_ptr132
   %_dest13 = getelementptr i64* %_reg132, i64 3
   store i64 %_source_val13, i64* %_dest13

   ; #Copy_Word_Op at 53:16
   %_source14 = getelementptr i64* %_Local_Area, i64 28
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val14, i64* %_dest14

   ; #Copy_Word_Op at 53:9
   %_source15 = getelementptr i64* %_Local_Area, i64 6
   %_source_val15 = load i64* %_source15
   %_dest15 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val15, i64* %_dest15

   ; #Check_Not_Null_Op at 53:9
   %_arg_ptr16 = getelementptr i64* %_Param_Area, i64 0
   %_arg16 = load i64* %_arg_ptr16
   %_desc16 = getelementptr i64* %_Static_Link, i64 0
   %_result16 = call i1 @_psc_is_null_value(i64 %_arg16, i64* %_desc16)
   br i1 %_result16, label %_fail16, label %_lbl17
   _fail16:
   %_str_ptr_ptr16 = load i64** @$Strings
   %_str_ptr16 = getelementptr i64* %_str_ptr_ptr16, i64 3
   %_assert_str16 = load i64* %_str_ptr16
   %_print_param16 = alloca i64
   store i64 %_assert_str16, i64* %_print_param16
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param16, i64* null)

   br label %_lbl17

_lbl17:
   ; #Return_Op at 53:9
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$|=$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 9
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Copy_Word_Op at 59:25
   %_source1 = getelementptr i64* %_Param_Area, i64 0
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val1, i64* %_dest1

   ; #Call_Op at 59:9
   %_call2_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call2_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call2_Param_Area, i64* %_call2_Static_Link)

   ; #Copy_Word_Op at 60:9
   %_source3 = getelementptr i64* %_Param_Area, i64 0
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val3, i64* %_dest3

   ; #Copy_Word_Op at 60:9
   %_reg_ptr41_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr41 = bitcast i64* %_reg_ptr41_Orig to i64**
   %_reg41 = load i64** %_reg_ptr41
   %_source4 = getelementptr i64* %_reg41, i64 0
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val4, i64* %_dest4

   ; #Store_Address_Op at 60:14
   %_reg_ptr51_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr51 = bitcast i64* %_reg_ptr51_Orig to i64**
   %_reg51 = load i64** %_reg_ptr51
   %_addr5 = getelementptr i64* %_reg51, i64 1
   %_addr_as_int5 = ptrtoint i64* %_addr5 to i64
   %_dest_ptr5 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int5, i64* %_dest_ptr5

   ; #Copy_Word_Op at 60:25
   %_source6 = getelementptr i64* %_Param_Area, i64 1
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val6, i64* %_dest6

   ; #Call_Op at 60:14
   %_call7_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$|=$"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #Copy_Word_Op at 61:9
   %_source8 = getelementptr i64* %_Param_Area, i64 0
   %_source_val8 = load i64* %_source8
   %_dest8 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val8, i64* %_dest8

   ; #Copy_Word_Op at 61:9
   %_reg_ptr91_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr91 = bitcast i64* %_reg_ptr91_Orig to i64**
   %_reg91 = load i64** %_reg_ptr91
   %_source9 = getelementptr i64* %_reg91, i64 0
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val9, i64* %_dest9

   ; #Store_Address_Op at 61:14
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_addr10 = getelementptr i64* %_reg101, i64 2
   %_addr_as_int10 = ptrtoint i64* %_addr10 to i64
   %_dest_ptr10 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int10, i64* %_dest_ptr10

   ; #Store_Local_Null_Op at 61:25
   %_desc11 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_null11 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc11)
   %_dest_ptr11 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_null11, i64* %_dest_ptr11

   ; #Call_Op at 61:25
   %_call12_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call12_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Key_Value.$[]$"(i64* %_Context, i64* %_call12_Param_Area, i64* %_call12_Static_Link)

   ; #Store_Address_Op at 61:32
   %_addr13 = getelementptr i64* %_Local_Area, i64 4
   %_addr_as_int13 = ptrtoint i64* %_addr13 to i64
   %_dest_ptr13 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_addr_as_int13, i64* %_dest_ptr13

   ; #Copy_Word_Op at 61:26
   %_source14 = getelementptr i64* %_Param_Area, i64 1
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_source_val14, i64* %_dest14

   ; #Copy_Word_Op at 61:32
   %_reg_ptr151_Orig = getelementptr i64* %_Local_Area, i64 7
   %_reg_ptr151 = bitcast i64* %_reg_ptr151_Orig to i64**
   %_reg151 = load i64** %_reg_ptr151
   %_source15 = getelementptr i64* %_reg151, i64 2
   %_source_val15 = load i64* %_source15
   %_dest15 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_source_val15, i64* %_dest15

   ; #Call_Op at 61:32
   %_call16_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call16_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Key_Value.$var_indexing$"(i64* %_Context, i64* %_call16_Param_Area, i64* %_call16_Static_Link)

   ; #Copy_Word_Op at 61:41
   %_source17 = getelementptr i64* %_Param_Area, i64 1
   %_source_val17 = load i64* %_source17
   %_dest17 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_source_val17, i64* %_dest17

   ; #Make_Copy_In_Stg_Rgn_Op at 61:47
   %_desc18 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_reg_ptr182_Orig = getelementptr i64* %_Local_Area, i64 8
   %_reg_ptr182 = bitcast i64* %_reg_ptr182_Orig to i64**
   %_reg182 = load i64** %_reg_ptr182
   %_source_ptr18 = getelementptr i64* %_reg182, i64 1
   %_source18 = load i64* %_source_ptr18
   %_existing_ptr18 = getelementptr i64* %_Local_Area, i64 4
   %_existing_obj18 = load i64* %_existing_ptr18
   %_result18 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc18, i64 %_source18, i64 %_existing_obj18)
   %_dest_ptr18 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_result18, i64* %_dest_ptr18

   ; #Assign_Word_Op at 61:32
   %_desc19 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr19 = getelementptr i64* %_Local_Area, i64 8
   %_source19 = load i64* %_source_ptr19
   %_reg_ptr192_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr192 = bitcast i64* %_reg_ptr192_Orig to i64**
   %_reg192 = load i64** %_reg_ptr192
   %_dest_ptr19 = getelementptr i64* %_reg192, i64 0
   call void @_psc_assign_word(i64* %_Context, i64* %_desc19, i64* %_dest_ptr19, i64 %_source19)

   ; #Call_Op at 61:14
   %_call20_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call20_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$|=$"(i64* %_Context, i64* %_call20_Param_Area, i64* %_call20_Static_Link)

   ; #Return_Op at 62:5
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$|$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 7
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Make_Copy_In_Stg_Rgn_Op at 67:19
   %_desc1 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr1 = getelementptr i64* %_Param_Area, i64 1
   %_source1 = load i64* %_source_ptr1
   %_existing_ptr1 = getelementptr i64* %_Param_Area, i64 0
   %_existing_obj1 = load i64* %_existing_ptr1
   %_result1 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc1, i64 %_source1, i64 %_existing_obj1)
   %_dest_ptr1 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_result1, i64* %_dest_ptr1

   ; #Assign_Word_Op at 67:9
   %_desc2 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr2 = getelementptr i64* %_Local_Area, i64 4
   %_source2 = load i64* %_source_ptr2
   %_dest_ptr2 = getelementptr i64* %_Param_Area, i64 0
   call void @_psc_assign_word(i64* %_Context, i64* %_desc2, i64* %_dest_ptr2, i64 %_source2)

   ; #Store_Address_Op at 68:9
   %_addr3 = getelementptr i64* %_Param_Area, i64 0
   %_addr_as_int3 = ptrtoint i64* %_addr3 to i64
   %_dest_ptr3 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int3, i64* %_dest_ptr3

   ; #Call_Op at 68:9
   %_call4_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call4_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call4_Param_Area, i64* %_call4_Static_Link)

   ; #Store_Address_Op at 69:9
   %_addr5 = getelementptr i64* %_Param_Area, i64 0
   %_addr_as_int5 = ptrtoint i64* %_addr5 to i64
   %_dest_ptr5 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int5, i64* %_dest_ptr5

   ; #Copy_Word_Op at 69:19
   %_source6 = getelementptr i64* %_Param_Area, i64 2
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val6, i64* %_dest6

   ; #Call_Op at 69:9
   %_call7_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Two_Way_Map.$|=$"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #Check_Not_Null_Op at 70:5
   %_arg_ptr8 = getelementptr i64* %_Param_Area, i64 0
   %_arg8 = load i64* %_arg_ptr8
   %_desc8 = getelementptr i64* %_Static_Link, i64 0
   %_result8 = call i1 @_psc_is_null_value(i64 %_arg8, i64* %_desc8)
   br i1 %_result8, label %_fail8, label %_lbl9
   _fail8:
   %_str_ptr_ptr8 = load i64** @$Strings
   %_str_ptr8 = getelementptr i64* %_str_ptr_ptr8, i64 6
   %_assert_str8 = load i64* %_str_ptr8
   %_print_param8 = alloca i64
   store i64 %_assert_str8, i64* %_print_param8
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param8, i64* null)

   br label %_lbl9

_lbl9:
   ; #Return_Op at 70:5
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$<|=$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 9
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Copy_Word_Op at 74:25
   %_source1 = getelementptr i64* %_Param_Area, i64 0
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val1, i64* %_dest1

   ; #Call_Op at 74:9
   %_call2_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call2_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call2_Param_Area, i64* %_call2_Static_Link)

   ; #Copy_Word_Op at 75:9
   %_source3 = getelementptr i64* %_Param_Area, i64 0
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val3, i64* %_dest3

   ; #Copy_Word_Op at 75:9
   %_reg_ptr41_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr41 = bitcast i64* %_reg_ptr41_Orig to i64**
   %_reg41 = load i64** %_reg_ptr41
   %_source4 = getelementptr i64* %_reg41, i64 0
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val4, i64* %_dest4

   ; #Store_Address_Op at 75:14
   %_reg_ptr51_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr51 = bitcast i64* %_reg_ptr51_Orig to i64**
   %_reg51 = load i64** %_reg_ptr51
   %_addr5 = getelementptr i64* %_reg51, i64 2
   %_addr_as_int5 = ptrtoint i64* %_addr5 to i64
   %_dest_ptr5 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int5, i64* %_dest_ptr5

   ; #Store_Local_Null_Op at 75:25
   %_desc6 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_null6 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc6)
   %_dest_ptr6 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_null6, i64* %_dest_ptr6

   ; #Call_Op at 75:25
   %_call7_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Key_Value.$[]$"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #Store_Address_Op at 75:32
   %_addr8 = getelementptr i64* %_Local_Area, i64 4
   %_addr_as_int8 = ptrtoint i64* %_addr8 to i64
   %_dest_ptr8 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_addr_as_int8, i64* %_dest_ptr8

   ; #Copy_Word_Op at 75:26
   %_source9 = getelementptr i64* %_Param_Area, i64 1
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_source_val9, i64* %_dest9

   ; #Copy_Word_Op at 75:26
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 7
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_source10 = getelementptr i64* %_reg101, i64 0
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_source_val10, i64* %_dest10

   ; #Copy_Word_Op at 75:32
   %_reg_ptr111_Orig = getelementptr i64* %_Local_Area, i64 7
   %_reg_ptr111 = bitcast i64* %_reg_ptr111_Orig to i64**
   %_reg111 = load i64** %_reg_ptr111
   %_source11 = getelementptr i64* %_reg111, i64 2
   %_source_val11 = load i64* %_source11
   %_dest11 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_source_val11, i64* %_dest11

   ; #Call_Op at 75:32
   %_call12_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2007)
   %_call12_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Key_Value.$var_indexing$"(i64* %_Context, i64* %_call12_Param_Area, i64* %_call12_Static_Link)

   ; #Copy_Word_Op at 75:41
   %_source13 = getelementptr i64* %_Param_Area, i64 1
   %_source_val13 = load i64* %_source13
   %_dest13 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_source_val13, i64* %_dest13

   ; #Copy_Word_Op at 75:41
   %_reg_ptr141_Orig = getelementptr i64* %_Local_Area, i64 8
   %_reg_ptr141 = bitcast i64* %_reg_ptr141_Orig to i64**
   %_reg141 = load i64** %_reg_ptr141
   %_source14 = getelementptr i64* %_reg141, i64 0
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_source_val14, i64* %_dest14

   ; #Make_Copy_In_Stg_Rgn_Op at 75:47
   %_desc15 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_reg_ptr152_Orig = getelementptr i64* %_Local_Area, i64 8
   %_reg_ptr152 = bitcast i64* %_reg_ptr152_Orig to i64**
   %_reg152 = load i64** %_reg_ptr152
   %_source_ptr15 = getelementptr i64* %_reg152, i64 1
   %_source15 = load i64* %_source_ptr15
   %_existing_ptr15 = getelementptr i64* %_Local_Area, i64 4
   %_existing_obj15 = load i64* %_existing_ptr15
   %_result15 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc15, i64 %_source15, i64 %_existing_obj15)
   %_dest_ptr15 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_result15, i64* %_dest_ptr15

   ; #Assign_Word_Op at 75:32
   %_desc16 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr16 = getelementptr i64* %_Local_Area, i64 8
   %_source16 = load i64* %_source_ptr16
   %_reg_ptr162_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr162 = bitcast i64* %_reg_ptr162_Orig to i64**
   %_reg162 = load i64** %_reg_ptr162
   %_dest_ptr16 = getelementptr i64* %_reg162, i64 0
   call void @_psc_assign_word(i64* %_Context, i64* %_desc16, i64* %_dest_ptr16, i64 %_source16)

   ; #Call_Op at 75:14
   %_call17_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call17_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$|=$"(i64* %_Context, i64* %_call17_Param_Area, i64* %_call17_Static_Link)

   ; #Copy_Word_Op at 76:9
   %_source18 = getelementptr i64* %_Param_Area, i64 0
   %_source_val18 = load i64* %_source18
   %_dest18 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val18, i64* %_dest18

   ; #Copy_Word_Op at 76:9
   %_reg_ptr191_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr191 = bitcast i64* %_reg_ptr191_Orig to i64**
   %_reg191 = load i64** %_reg_ptr191
   %_source19 = getelementptr i64* %_reg191, i64 0
   %_source_val19 = load i64* %_source19
   %_dest19 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val19, i64* %_dest19

   ; #Store_Address_Op at 76:14
   %_reg_ptr201_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr201 = bitcast i64* %_reg_ptr201_Orig to i64**
   %_reg201 = load i64** %_reg_ptr201
   %_addr20 = getelementptr i64* %_reg201, i64 1
   %_addr_as_int20 = ptrtoint i64* %_addr20 to i64
   %_dest_ptr20 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int20, i64* %_dest_ptr20

   ; #Copy_Word_Op at 76:26
   %_source21 = getelementptr i64* %_Param_Area, i64 1
   %_source_val21 = load i64* %_source21
   %_dest21 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val21, i64* %_dest21

   ; #Call_Op at 76:14
   %_call22_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call22_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$<|=$"(i64* %_Context, i64* %_call22_Param_Area, i64* %_call22_Static_Link)

   ; #Return_Op at 77:5
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$<|=$.2"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 6
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Copy_Word_Op at 82:25
   %_source1 = getelementptr i64* %_Param_Area, i64 0
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val1, i64* %_dest1

   ; #Call_Op at 82:9
   %_call2_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call2_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call2_Param_Area, i64* %_call2_Static_Link)

   br label %_lbl3

_lbl3:
   ; #Store_Local_Null_Op at 84:17
   %_desc3 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2004)
   %_null3 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc3)
   %_dest_ptr3 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_null3, i64* %_dest_ptr3

   ; #Copy_Word_Op at 84:34
   %_source4 = getelementptr i64* %_Param_Area, i64 1
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val4, i64* %_dest4

   ; #Call_Op at 84:23
   %_call5_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call5_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call5_Param_Area, i64* %_call5_Static_Link, i16 3, i16 0, i16 3, i16 10013, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Copy_Word_Op at 85:16
   %_source6 = getelementptr i64* %_Local_Area, i64 3
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val6, i64* %_dest6

   ; #Is_Null_Op at 85:16
   %_arg_ptr7 = getelementptr i64* %_Local_Area, i64 4
   %_arg7 = load i64* %_arg_ptr7
   %_desc7 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2004)
   %_result7 = call i1 @_psc_is_null_value(i64 %_arg7, i64* %_desc7)
   %_result_ext7 = zext i1 %_result7 to i64
   %_result_ptr7 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_result_ext7, i64* %_result_ptr7

   ; #If_Op at 85:16
   %_if_source_ptr8 = getelementptr i64* %_Local_Area, i64 4
   %_if_source_val8 = load i64* %_if_source_ptr8
   %_shifted8 = shl i64 1, %_if_source_val8
   %_and8 = and i64 %_shifted8, 2
   %_if_source_trunc8 = icmp ne i64 %_and8, 0
   br i1 %_if_source_trunc8, label %_lbl9, label %_lbl10

_lbl9:
   ; #Skip_Op at 86:17
   br label %_lbl14

_lbl10:
   ; #Copy_Word_Op at 88:13
   %_source10 = getelementptr i64* %_Param_Area, i64 0
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val10, i64* %_dest10

   ; #Store_Address_Op at 88:13
   %_addr11 = getelementptr i64* %_Local_Area, i64 3
   %_addr_as_int11 = ptrtoint i64* %_addr11 to i64
   %_dest_ptr11 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int11, i64* %_dest_ptr11

   ; #Call_Op at 88:13
   %_call12_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call12_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Two_Way_Map.$<|=$"(i64* %_Context, i64* %_call12_Param_Area, i64* %_call12_Static_Link)

   ; #Skip_Op at 83:9
   br label %_lbl3

_lbl14:
   ; #Return_Op at 90:5
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$-=$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 7
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Copy_Word_Op at 94:25
   %_source1 = getelementptr i64* %_Param_Area, i64 0
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val1, i64* %_dest1

   ; #Call_Op at 94:9
   %_call2_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call2_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call2_Param_Area, i64* %_call2_Static_Link)

   ; #Copy_Word_Op at 95:12
   %_source3 = getelementptr i64* %_Param_Area, i64 1
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val3, i64* %_dest3

   ; #Copy_Word_Op at 95:19
   %_source4 = getelementptr i64* %_Param_Area, i64 0
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val4, i64* %_dest4

   ; #Copy_Word_Op at 95:19
   %_reg_ptr51_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr51 = bitcast i64* %_reg_ptr51_Orig to i64**
   %_reg51 = load i64** %_reg_ptr51
   %_source5 = getelementptr i64* %_reg51, i64 0
   %_source_val5 = load i64* %_source5
   %_dest5 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val5, i64* %_dest5

   ; #Copy_Word_Op at 95:21
   %_reg_ptr61_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr61 = bitcast i64* %_reg_ptr61_Orig to i64**
   %_reg61 = load i64** %_reg_ptr61
   %_source6 = getelementptr i64* %_reg61, i64 1
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val6, i64* %_dest6

   ; #Call_Op at 95:16
   %_call7_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call7_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$in$"(i64* %_Context, i64* %_call7_Param_Area, i64* %_call7_Static_Link)

   ; #If_Op at 95:16
   %_if_source_ptr8 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val8 = load i64* %_if_source_ptr8
   %_shifted8 = shl i64 1, %_if_source_val8
   %_and8 = and i64 %_shifted8, 2
   %_if_source_trunc8 = icmp ne i64 %_and8, 0
   br i1 %_if_source_trunc8, label %_lbl9, label %_lbl24

_lbl9:
   ; #Copy_Word_Op at 96:12
   %_source9 = getelementptr i64* %_Param_Area, i64 0
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val9, i64* %_dest9

   ; #Copy_Word_Op at 96:12
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_source10 = getelementptr i64* %_reg101, i64 0
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val10, i64* %_dest10

   ; #Store_Address_Op at 96:14
   %_reg_ptr111_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr111 = bitcast i64* %_reg_ptr111_Orig to i64**
   %_reg111 = load i64** %_reg_ptr111
   %_addr11 = getelementptr i64* %_reg111, i64 2
   %_addr_as_int11 = ptrtoint i64* %_addr11 to i64
   %_dest_ptr11 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int11, i64* %_dest_ptr11

   ; #Copy_Word_Op at 96:25
   %_source12 = getelementptr i64* %_Param_Area, i64 0
   %_source_val12 = load i64* %_source12
   %_dest12 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val12, i64* %_dest12

   ; #Copy_Word_Op at 96:25
   %_reg_ptr131_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr131 = bitcast i64* %_reg_ptr131_Orig to i64**
   %_reg131 = load i64** %_reg_ptr131
   %_source13 = getelementptr i64* %_reg131, i64 0
   %_source_val13 = load i64* %_source13
   %_dest13 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val13, i64* %_dest13

   ; #Store_Address_Op at 96:27
   %_reg_ptr141_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr141 = bitcast i64* %_reg_ptr141_Orig to i64**
   %_reg141 = load i64** %_reg_ptr141
   %_addr14 = getelementptr i64* %_reg141, i64 1
   %_addr_as_int14 = ptrtoint i64* %_addr14 to i64
   %_dest_ptr14 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_addr_as_int14, i64* %_dest_ptr14

   ; #Copy_Word_Op at 96:35
   %_source15 = getelementptr i64* %_Param_Area, i64 1
   %_source_val15 = load i64* %_source15
   %_dest15 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val15, i64* %_dest15

   ; #Call_Op at 96:27
   %_call16_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call16_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Map.$indexing$"(i64* %_Context, i64* %_call16_Param_Area, i64* %_call16_Static_Link)

   ; #Copy_Word_Op at 96:27
   %_reg_ptr171_Orig = getelementptr i64* %_Local_Area, i64 4
   %_reg_ptr171 = bitcast i64* %_reg_ptr171_Orig to i64**
   %_reg171 = load i64** %_reg_ptr171
   %_source17 = getelementptr i64* %_reg171, i64 0
   %_source_val17 = load i64* %_source17
   %_dest17 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val17, i64* %_dest17

   ; #Call_Op at 96:14
   %_call18_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call18_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$-=$"(i64* %_Context, i64* %_call18_Param_Area, i64* %_call18_Static_Link)

   ; #Copy_Word_Op at 97:12
   %_source19 = getelementptr i64* %_Param_Area, i64 0
   %_source_val19 = load i64* %_source19
   %_dest19 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val19, i64* %_dest19

   ; #Copy_Word_Op at 97:12
   %_reg_ptr201_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr201 = bitcast i64* %_reg_ptr201_Orig to i64**
   %_reg201 = load i64** %_reg_ptr201
   %_source20 = getelementptr i64* %_reg201, i64 0
   %_source_val20 = load i64* %_source20
   %_dest20 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val20, i64* %_dest20

   ; #Store_Address_Op at 97:14
   %_reg_ptr211_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr211 = bitcast i64* %_reg_ptr211_Orig to i64**
   %_reg211 = load i64** %_reg_ptr211
   %_addr21 = getelementptr i64* %_reg211, i64 1
   %_addr_as_int21 = ptrtoint i64* %_addr21 to i64
   %_dest_ptr21 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int21, i64* %_dest_ptr21

   ; #Copy_Word_Op at 97:25
   %_source22 = getelementptr i64* %_Param_Area, i64 1
   %_source_val22 = load i64* %_source22
   %_dest22 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val22, i64* %_dest22

   ; #Call_Op at 97:14
   %_call23_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call23_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$-=$"(i64* %_Context, i64* %_call23_Param_Area, i64* %_call23_Static_Link)

   br label %_lbl24

_lbl24:
   ; #Return_Op at 99:5
   ret void

}

define void @"PSL.Containers.Two_Way_Map.$var_indexing$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 7
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Copy_Word_Op at 104:25
   %_source1 = getelementptr i64* %_Param_Area, i64 1
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val1, i64* %_dest1

   ; #Call_Op at 104:9
   %_call2_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call2_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call2_Param_Area, i64* %_call2_Static_Link)

   ; #Copy_Word_Op at 105:12
   %_source3 = getelementptr i64* %_Param_Area, i64 2
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val3, i64* %_dest3

   ; #Copy_Word_Op at 105:23
   %_source4 = getelementptr i64* %_Param_Area, i64 1
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val4, i64* %_dest4

   ; #Copy_Word_Op at 105:23
   %_reg_ptr51_Orig = getelementptr i64* %_Local_Area, i64 6
   %_reg_ptr51 = bitcast i64* %_reg_ptr51_Orig to i64**
   %_reg51 = load i64** %_reg_ptr51
   %_source5 = getelementptr i64* %_reg51, i64 0
   %_source_val5 = load i64* %_source5
   %_dest5 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val5, i64* %_dest5

   ; #Call_Op at 105:16
   %_call6_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call6_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call6_Param_Area, i64* %_call6_Static_Link, i16 3, i16 0, i16 3, i16 10007, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Call_Op at 105:16
   %_n_ptr7 = getelementptr i64* %_Local_Area, i64 4
   %_n7 = load i64* %_n_ptr7
   %_result7 = xor i64 1, %_n7
   %_result_ptr7 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_result7, i64* %_result_ptr7

   ; #If_Op at 105:16
   %_if_source_ptr8 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val8 = load i64* %_if_source_ptr8
   %_shifted8 = shl i64 1, %_if_source_val8
   %_and8 = and i64 %_shifted8, 2
   %_if_source_trunc8 = icmp ne i64 %_and8, 0
   br i1 %_if_source_trunc8, label %_lbl9, label %_lbl14

_lbl9:
   ; #Copy_Word_Op at 107:13
   %_source9 = getelementptr i64* %_Param_Area, i64 1
   %_source_val9 = load i64* %_source9
   %_dest9 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val9, i64* %_dest9

   ; #Copy_Word_Op at 107:13
   %_reg_ptr101_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr101 = bitcast i64* %_reg_ptr101_Orig to i64**
   %_reg101 = load i64** %_reg_ptr101
   %_source10 = getelementptr i64* %_reg101, i64 0
   %_source_val10 = load i64* %_source10
   %_dest10 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val10, i64* %_dest10

   ; #Store_Address_Op at 107:15
   %_reg_ptr111_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr111 = bitcast i64* %_reg_ptr111_Orig to i64**
   %_reg111 = load i64** %_reg_ptr111
   %_addr11 = getelementptr i64* %_reg111, i64 3
   %_addr_as_int11 = ptrtoint i64* %_addr11 to i64
   %_dest_ptr11 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_addr_as_int11, i64* %_dest_ptr11

   ; #Copy_Word_Op at 107:29
   %_source12 = getelementptr i64* %_Param_Area, i64 2
   %_source_val12 = load i64* %_source12
   %_dest12 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val12, i64* %_dest12

   ; #Call_Op at 107:15
   %_call13_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_call13_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Set.$|=$.2"(i64* %_Context, i64* %_call13_Param_Area, i64* %_call13_Static_Link)

   br label %_lbl14

_lbl14:
   ; #Copy_Word_Op at 109:31
   %_source14 = getelementptr i64* %_Param_Area, i64 1
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val14, i64* %_dest14

   ; #Copy_Word_Op at 109:31
   %_reg_ptr151_Orig = getelementptr i64* %_Local_Area, i64 4
   %_reg_ptr151 = bitcast i64* %_reg_ptr151_Orig to i64**
   %_reg151 = load i64** %_reg_ptr151
   %_source15 = getelementptr i64* %_reg151, i64 0
   %_source_val15 = load i64* %_source15
   %_dest15 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val15, i64* %_dest15

   ; #Store_Address_Op at 109:16
   %_reg_ptr161_Orig = getelementptr i64* %_Local_Area, i64 4
   %_reg_ptr161 = bitcast i64* %_reg_ptr161_Orig to i64**
   %_reg161 = load i64** %_reg_ptr161
   %_addr16 = getelementptr i64* %_reg161, i64 1
   %_addr_as_int16 = ptrtoint i64* %_addr16 to i64
   %_dest_ptr16 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_addr_as_int16, i64* %_dest_ptr16

   ; #Copy_Word_Op at 109:42
   %_source17 = getelementptr i64* %_Param_Area, i64 2
   %_source_val17 = load i64* %_source17
   %_dest17 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val17, i64* %_dest17

   ; #Call_Op at 109:16
   %_call18_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call18_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$var_indexing$"(i64* %_Context, i64* %_call18_Param_Area, i64* %_call18_Static_Link)

   ; #Store_Address_Op at 109:9
   %_reg_ptr191_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr191 = bitcast i64* %_reg_ptr191_Orig to i64**
   %_reg191 = load i64** %_reg_ptr191
   %_addr19 = getelementptr i64* %_reg191, i64 0
   %_addr_as_int19 = ptrtoint i64* %_addr19 to i64
   %_dest_ptr19 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_addr_as_int19, i64* %_dest_ptr19

   ; #Return_Op at 109:9
   ret void

}

define void @"PSL.Containers.Two_Way_Map.Key_Of"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 12
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Copy_Word_Op at 114:12
   %_source1 = getelementptr i64* %_Param_Area, i64 2
   %_source_val1 = load i64* %_source1
   %_dest1 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val1, i64* %_dest1

   ; #Copy_Word_Op at 114:21
   %_source2 = getelementptr i64* %_Param_Area, i64 1
   %_source_val2 = load i64* %_source2
   %_dest2 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val2, i64* %_dest2

   ; #Copy_Word_Op at 114:23
   %_reg_ptr31_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr31 = bitcast i64* %_reg_ptr31_Orig to i64**
   %_reg31 = load i64** %_reg_ptr31
   %_source3 = getelementptr i64* %_reg31, i64 2
   %_source_val3 = load i64* %_source3
   %_dest3 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val3, i64* %_dest3

   ; #Call_Op at 114:18
   %_call4_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call4_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$in$"(i64* %_Context, i64* %_call4_Param_Area, i64* %_call4_Static_Link)

   ; #If_Op at 114:18
   %_if_source_ptr5 = getelementptr i64* %_Local_Area, i64 3
   %_if_source_val5 = load i64* %_if_source_ptr5
   %_shifted5 = shl i64 1, %_if_source_val5
   %_and5 = and i64 %_shifted5, 2
   %_if_source_trunc5 = icmp ne i64 %_and5, 0
   br i1 %_if_source_trunc5, label %_lbl6, label %_lbl13

_lbl6:
   ; #Copy_Word_Op at 116:19
   %_source6 = getelementptr i64* %_Param_Area, i64 1
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_source_val6, i64* %_dest6

   ; #Store_Address_Op at 116:21
   %_reg_ptr71_Orig = getelementptr i64* %_Local_Area, i64 4
   %_reg_ptr71 = bitcast i64* %_reg_ptr71_Orig to i64**
   %_reg71 = load i64** %_reg_ptr71
   %_addr7 = getelementptr i64* %_reg71, i64 2
   %_addr_as_int7 = ptrtoint i64* %_addr7 to i64
   %_dest_ptr7 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_addr_as_int7, i64* %_dest_ptr7

   ; #Copy_Word_Op at 116:29
   %_source8 = getelementptr i64* %_Param_Area, i64 2
   %_source_val8 = load i64* %_source8
   %_dest8 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val8, i64* %_dest8

   ; #Call_Op at 116:21
   %_call9_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_call9_Param_Area = getelementptr i64* %_Local_Area, i64 3
   call void @"PSL.Containers.Map.$indexing$"(i64* %_Context, i64* %_call9_Param_Area, i64* %_call9_Static_Link)

   ; #Make_Copy_In_Stg_Rgn_Op at 116:21
   %_desc10 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_reg_ptr102_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr102 = bitcast i64* %_reg_ptr102_Orig to i64**
   %_reg102 = load i64** %_reg_ptr102
   %_source_ptr10 = getelementptr i64* %_reg102, i64 0
   %_source10 = load i64* %_source_ptr10
   %_existing_ptr10 = getelementptr i64* %_Param_Area, i64 0
   %_existing_obj10 = load i64* %_existing_ptr10
   %_result10 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc10, i64 %_source10, i64 %_existing_obj10)
   %_dest_ptr10 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_result10, i64* %_dest_ptr10

   ; #Copy_Word_Op at 116:12
   %_source11 = getelementptr i64* %_Local_Area, i64 3
   %_source_val11 = load i64* %_source11
   %_dest11 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val11, i64* %_dest11

   ; #Return_Op at 116:12
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

_lbl13:
   ; #Store_Local_Null_Op at 119:16
   %_desc13 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_null13 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc13)
   %_dest_ptr13 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_null13, i64* %_dest_ptr13

   ; #Copy_Word_Op at 119:21
   %_source14 = getelementptr i64* %_Param_Area, i64 1
   %_source_val14 = load i64* %_source14
   %_dest14 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_source_val14, i64* %_dest14

   ; #Make_Copy_In_Stg_Rgn_Op at 119:23
   %_desc15 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_reg_ptr152_Orig = getelementptr i64* %_Local_Area, i64 3
   %_reg_ptr152 = bitcast i64* %_reg_ptr152_Orig to i64**
   %_reg152 = load i64** %_reg_ptr152
   %_source_ptr15 = getelementptr i64* %_reg152, i64 3
   %_source15 = load i64* %_source_ptr15
   %_existing_ptr15 = getelementptr i64* %_Local_Area, i64 3
   %_existing_obj15 = load i64* %_existing_ptr15
   %_result15 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc15, i64 %_source15, i64 %_existing_obj15)
   %_dest_ptr15 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_result15, i64* %_dest_ptr15

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 119:16
   %_desc16 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr16 = getelementptr i64* %_Local_Area, i64 3
   %_source16 = load i64* %_source_ptr16
   %_null16 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc16, i64 %_source16)
   %_dest_ptr16 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_null16, i64* %_dest_ptr16

   ; #Store_Address_Op at 119:16
   %_addr17 = getelementptr i64* %_Local_Area, i64 3
   %_addr_as_int17 = ptrtoint i64* %_addr17 to i64
   %_dest_ptr17 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_addr_as_int17, i64* %_dest_ptr17

   ; #Call_Op at 119:16
   %_call18_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_call18_Param_Area = getelementptr i64* %_Local_Area, i64 5
   call void @"PSL.Containers.Set.Remove_Any"(i64* %_Context, i64* %_call18_Param_Area, i64* %_call18_Static_Link)

   ; #Not_Null_Op at 119:16
   %_arg_ptr19 = getelementptr i64* %_Local_Area, i64 5
   %_arg19 = load i64* %_arg_ptr19
   %_desc19 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_result19 = call i1 @_psc_is_null_value(i64 %_arg19, i64* %_desc19)
   %_cmplmt19 = icmp eq i1 %_result19, 0
   %_result_ext19 = zext i1 %_cmplmt19 to i64
   %_result_ptr19 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_result_ext19, i64* %_result_ptr19

   ; #If_Op at 119:16
   %_if_source_ptr20 = getelementptr i64* %_Local_Area, i64 6
   %_if_source_val20 = load i64* %_if_source_ptr20
   %_shifted20 = shl i64 1, %_if_source_val20
   %_and20 = and i64 %_shifted20, 2
   %_if_source_trunc20 = icmp ne i64 %_and20, 0
   br i1 %_if_source_trunc20, label %_lbl21, label %_lbl42

_lbl21:
   ; #Copy_Word_Op at 119:12
   %_source21 = getelementptr i64* %_Local_Area, i64 5
   %_source_val21 = load i64* %_source21
   %_dest21 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val21, i64* %_dest21

   br label %_lbl22

_lbl22:
   ; #Copy_Word_Op at 120:19
   %_source22 = getelementptr i64* %_Param_Area, i64 1
   %_source_val22 = load i64* %_source22
   %_dest22 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_source_val22, i64* %_dest22

   ; #Store_Address_Op at 120:21
   %_reg_ptr231_Orig = getelementptr i64* %_Local_Area, i64 10
   %_reg_ptr231 = bitcast i64* %_reg_ptr231_Orig to i64**
   %_reg231 = load i64** %_reg_ptr231
   %_addr23 = getelementptr i64* %_reg231, i64 1
   %_addr_as_int23 = ptrtoint i64* %_addr23 to i64
   %_dest_ptr23 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_addr_as_int23, i64* %_dest_ptr23

   ; #Copy_Word_Op at 120:29
   %_source24 = getelementptr i64* %_Local_Area, i64 6
   %_source_val24 = load i64* %_source24
   %_dest24 = getelementptr i64* %_Local_Area, i64 11
   store i64 %_source_val24, i64* %_dest24

   ; #Call_Op at 120:21
   %_call25_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2003)
   %_call25_Param_Area = getelementptr i64* %_Local_Area, i64 9
   call void @"PSL.Containers.Map.$indexing$"(i64* %_Context, i64* %_call25_Param_Area, i64* %_call25_Static_Link)

   ; #Copy_Word_Op at 120:21
   %_reg_ptr261_Orig = getelementptr i64* %_Local_Area, i64 9
   %_reg_ptr261 = bitcast i64* %_reg_ptr261_Orig to i64**
   %_reg261 = load i64** %_reg_ptr261
   %_source26 = getelementptr i64* %_reg261, i64 0
   %_source_val26 = load i64* %_source26
   %_dest26 = getelementptr i64* %_Local_Area, i64 9
   store i64 %_source_val26, i64* %_dest26

   ; #Copy_Word_Op at 120:35
   %_source27 = getelementptr i64* %_Param_Area, i64 2
   %_source_val27 = load i64* %_source27
   %_dest27 = getelementptr i64* %_Local_Area, i64 10
   store i64 %_source_val27, i64* %_dest27

   ; #Call_Op at 120:32
   %_call28_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2)
   %_call28_Param_Area = getelementptr i64* %_Local_Area, i64 8
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call28_Param_Area, i64* %_call28_Static_Link, i16 3, i16 2, i16 3, i16 10003, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Store_Int_Lit_Op at 120:32
   %_dest29 = getelementptr i64* %_Local_Area, i64 9
   store i64 2, i64* %_dest29

   ; #Call_Op at 120:32
   %_desc_ptr_ptr300 = load i64*** @$Types
   %_desc_ptr300 = getelementptr i64** %_desc_ptr_ptr300, i64 0
   %_call30_Static_Link = load i64** %_desc_ptr300
   %_call30_Param_Area = getelementptr i64* %_Local_Area, i64 7
   call void @"_psc_ordering_to_bool"(i64* %_Context, i64* %_call30_Param_Area, i64* %_call30_Static_Link)

   ; #If_Op at 120:32
   %_if_source_ptr31 = getelementptr i64* %_Local_Area, i64 7
   %_if_source_val31 = load i64* %_if_source_ptr31
   %_shifted31 = shl i64 1, %_if_source_val31
   %_and31 = and i64 %_shifted31, 2
   %_if_source_trunc31 = icmp ne i64 %_and31, 0
   br i1 %_if_source_trunc31, label %_lbl32, label %_lbl35

_lbl32:
   ; #Make_Copy_In_Stg_Rgn_Op at 121:27
   %_desc32 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr32 = getelementptr i64* %_Local_Area, i64 6
   %_source32 = load i64* %_source_ptr32
   %_existing_ptr32 = getelementptr i64* %_Param_Area, i64 0
   %_existing_obj32 = load i64* %_existing_ptr32
   %_result32 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc32, i64 %_source32, i64 %_existing_obj32)
   %_dest_ptr32 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_result32, i64* %_dest_ptr32

   ; #Copy_Word_Op at 121:20
   %_source33 = getelementptr i64* %_Local_Area, i64 7
   %_source_val33 = load i64* %_source33
   %_dest33 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val33, i64* %_dest33

   ; #Return_Op at 121:20
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

_lbl35:
   ; #Store_Null_Of_Same_Stg_Rgn_Op at 119:16
   %_desc35 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr35 = getelementptr i64* %_Local_Area, i64 3
   %_source35 = load i64* %_source_ptr35
   %_null35 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc35, i64 %_source35)
   %_dest_ptr35 = getelementptr i64* %_Local_Area, i64 8
   store i64 %_null35, i64* %_dest_ptr35

   ; #Store_Address_Op at 119:16
   %_addr36 = getelementptr i64* %_Local_Area, i64 3
   %_addr_as_int36 = ptrtoint i64* %_addr36 to i64
   %_dest_ptr36 = getelementptr i64* %_Local_Area, i64 9
   store i64 %_addr_as_int36, i64* %_dest_ptr36

   ; #Call_Op at 119:16
   %_call37_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2005)
   %_call37_Param_Area = getelementptr i64* %_Local_Area, i64 8
   call void @"PSL.Containers.Set.Remove_Any"(i64* %_Context, i64* %_call37_Param_Area, i64* %_call37_Static_Link)

   ; #Not_Null_Op at 119:16
   %_arg_ptr38 = getelementptr i64* %_Local_Area, i64 8
   %_arg38 = load i64* %_arg_ptr38
   %_desc38 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_result38 = call i1 @_psc_is_null_value(i64 %_arg38, i64* %_desc38)
   %_cmplmt38 = icmp eq i1 %_result38, 0
   %_result_ext38 = zext i1 %_cmplmt38 to i64
   %_result_ptr38 = getelementptr i64* %_Local_Area, i64 9
   store i64 %_result_ext38, i64* %_result_ptr38

   ; #If_Op at 119:16
   %_if_source_ptr39 = getelementptr i64* %_Local_Area, i64 9
   %_if_source_val39 = load i64* %_if_source_ptr39
   %_shifted39 = shl i64 1, %_if_source_val39
   %_and39 = and i64 %_shifted39, 2
   %_if_source_trunc39 = icmp ne i64 %_and39, 0
   br i1 %_if_source_trunc39, label %_lbl40, label %_lbl42

_lbl40:
   ; #Copy_Word_Op at 119:16
   %_source40 = getelementptr i64* %_Local_Area, i64 8
   %_source_val40 = load i64* %_source40
   %_dest40 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val40, i64* %_dest40

   ; #Skip_Op at 119:12
   br label %_lbl22

_lbl42:
   ; #Store_Null_Of_Same_Stg_Rgn_Op at 125:19
   %_desc42 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 1)
   %_source_ptr42 = getelementptr i64* %_Param_Area, i64 0
   %_source42 = load i64* %_source_ptr42
   %_null42 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc42, i64 %_source42)
   %_dest_ptr42 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_null42, i64* %_dest_ptr42

   ; #Copy_Word_Op at 125:12
   %_source43 = getelementptr i64* %_Local_Area, i64 3
   %_source_val43 = load i64* %_source43
   %_dest43 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val43, i64* %_dest43

   ; #Return_Op at 125:12
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

}

define void @"PSL.Containers.Two_Way_Map.Rev_Map"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 8
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 131:22
   %_desc1 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr1 = getelementptr i64* %_Param_Area, i64 0
   %_source1 = load i64* %_source_ptr1
   %_null1 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc1, i64 %_source1)
   %_dest_ptr1 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_null1, i64* %_dest_ptr1

   ; #Make_Copy_In_Stg_Rgn_Op at 131:32
   %_desc2 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr2 = getelementptr i64* %_Param_Area, i64 1
   %_source2 = load i64* %_source_ptr2
   %_existing_ptr2 = getelementptr i64* %_Local_Area, i64 3
   %_existing_obj2 = load i64* %_existing_ptr2
   %_result2 = call i64 @_psc_copy_object(i64* %_Context, i64* %_desc2, i64 %_source2, i64 %_existing_obj2)
   %_dest_ptr2 = getelementptr i64* %_Local_Area, i64 3
   store i64 %_result2, i64* %_dest_ptr2

   ; #Store_Address_Op at 132:9
   %_addr3 = getelementptr i64* %_Local_Area, i64 3
   %_addr_as_int3 = ptrtoint i64* %_addr3 to i64
   %_dest_ptr3 = getelementptr i64* %_Local_Area, i64 4
   store i64 %_addr_as_int3, i64* %_dest_ptr3

   ; #Call_Op at 132:9
   %_call4_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call4_Param_Area = getelementptr i64* %_Local_Area, i64 4
   call void @"PSL.Containers.Two_Way_Map.Add_Unreversed"(i64* %_Context, i64* %_call4_Param_Area, i64* %_call4_Static_Link)

   ; #Copy_Word_Op at 134:20
   %_source5 = getelementptr i64* %_Local_Area, i64 3
   %_source_val5 = load i64* %_source5
   %_dest5 = getelementptr i64* %_Local_Area, i64 5
   store i64 %_source_val5, i64* %_dest5

   ; #Move_Obj_Op at 134:9
   %_reg_ptr61_Orig = getelementptr i64* %_Local_Area, i64 5
   %_reg_ptr61 = bitcast i64* %_reg_ptr61_Orig to i64**
   %_reg61 = load i64** %_reg_ptr61
   %_source_ptr6 = getelementptr i64* %_reg61, i64 2
   %_dest_ptr6 = getelementptr i64* %_Param_Area, i64 0
   %_desc6 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   call void @_psc_move_object(i64* %_Context, i64* %_desc6, i64* %_dest_ptr6, i64* %_source_ptr6)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 135:17
   %_desc7 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr7 = getelementptr i64* %_Local_Area, i64 3
   %_source7 = load i64* %_source_ptr7
   %_null7 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc7, i64 %_source7)
   %_dest_ptr7 = getelementptr i64* %_Local_Area, i64 7
   store i64 %_null7, i64* %_dest_ptr7

   ; #Assign_Word_Op at 135:9
   %_desc8 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr8 = getelementptr i64* %_Local_Area, i64 7
   %_source8 = load i64* %_source_ptr8
   %_dest_ptr8 = getelementptr i64* %_Local_Area, i64 3
   call void @_psc_assign_word(i64* %_Context, i64* %_desc8, i64* %_dest_ptr8, i64 %_source8)

   ; #Check_Not_Null_Op at 136:5
   %_arg_ptr9 = getelementptr i64* %_Param_Area, i64 0
   %_arg9 = load i64* %_arg_ptr9
   %_desc9 = call i64* @_psc_get_type_desc_or_op_map(i64* %_Static_Link, i16 3, i16 2006)
   %_result9 = call i1 @_psc_is_null_value(i64 %_arg9, i64* %_desc9)
   br i1 %_result9, label %_fail9, label %_lbl10
   _fail9:
   %_str_ptr_ptr9 = load i64** @$Strings
   %_str_ptr9 = getelementptr i64* %_str_ptr_ptr9, i64 13
   %_assert_str9 = load i64* %_str_ptr9
   %_print_param9 = alloca i64
   store i64 %_assert_str9, i64* %_print_param9
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param9, i64* null)

   br label %_lbl10

_lbl10:
   ; #Return_Op at 136:5
   ret void

}

