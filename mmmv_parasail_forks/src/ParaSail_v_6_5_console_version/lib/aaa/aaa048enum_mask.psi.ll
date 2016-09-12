declare i32 @_psc_execute_wait_for_parallel_op(i64*, i64*)
declare void @_psc_finalize_stg_rgn(i64*, i64*)
declare void @_psc_register_compiled_operations(i16, i16*, void(i64*, i64*, i64*)**, i8*, i64*, i32, i16*, i32(i64*, i64*, i64*)**)
declare i64 @_psc_local_null(i64*, i64*)
declare void @_psc_execute_compiled_indirect_call_op(i64*, i64*, i64*, i16, i16, i16, i16, i64, void(i64*, i64*, i64*)*, i8)
declare void @_psc_execute_compiled_indirect_parallel_call_op(i64*, i64*, i64*, i16, i16, i64* , i16, i16, i1, i1, i8)
declare void @_psc_initialize_stg_rgn(i64*, i64*)
declare void @"_psc_runtime_message"(i64*, i64*, i64*)
declare void @_psc_reconstruct_strings(i16, i8**, i64*)
declare void @_psc_execute_compiled_parallel_op(i64*, i64*, i64*, i32(i64*, i64*, i64*)*, i64* , i1, i1, i1)
declare i64* @_psc_get_type_desc_or_op_map(i64*, i16, i16)
declare i64 @_psc_null_of_same_stg_rgn(i64*, i64)
declare i1 @_psc_is_null_value(i64, i64*)

@$Module_Op_Indices = internal constant [2 x i16] [
i16 1, i16 2]

@$Local_Funcs = internal constant [1 x void(i64*, i64*, i64*)*] [
void(i64*, i64*, i64*)* @"PSL.Core.Enum_Mask.$|$"]

@$Local_Funcs_Use_Queuing = internal constant [1 x i8] [
i8 0]

@$Internal_Precond_Indices = internal constant [0 x i16] [
]

@$Internal_Precond_Blocks = internal constant [0 x i32(i64*, i64*, i64*)*] [
]

@$str_stream1 = internal constant [24 x i8] 

[i8 20, i8 0, i8 0, i8 0, i8 80, i8 83, i8 76, i8 58, i8 58, i8 67, i8 111
, i8 114, i8 101, i8 58, i8 58, i8 69, i8 110, i8 117, i8 109, i8 95, i8 77
, i8 97, i8 115, i8 107]

@$str_stream2 = internal constant [7 x i8] 

[i8 3, i8 0, i8 0, i8 0, i8 34, i8 124, i8 34]

@$str_stream3 = internal constant [98 x i8] 

[i8 94, i8 0, i8 0, i8 0, i8 47, i8 85, i8 115, i8 101, i8 114, i8 115, i8 47
, i8 115, i8 116, i8 116, i8 47, i8 95, i8 112, i8 97, i8 114, i8 97, i8 115
, i8 97, i8 105, i8 108, i8 47, i8 108, i8 105, i8 98, i8 47, i8 97, i8 97
, i8 97, i8 47, i8 97, i8 97, i8 97, i8 48, i8 52, i8 56, i8 101, i8 110
, i8 117, i8 109, i8 95, i8 109, i8 97, i8 115, i8 107, i8 46, i8 112, i8 115
, i8 105, i8 58, i8 56, i8 58, i8 49, i8 49, i8 58, i8 32, i8 69, i8 114
, i8 114, i8 111, i8 114, i8 58, i8 32, i8 78, i8 117, i8 108, i8 108, i8 32
, i8 118, i8 97, i8 108, i8 117, i8 101, i8 32, i8 110, i8 111, i8 116, i8 32
, i8 112, i8 101, i8 114, i8 109, i8 105, i8 116, i8 116, i8 101, i8 100, i8 32
, i8 104, i8 101, i8 114, i8 101, i8 58, i8 32, i8 10]

@$Str_Streams = internal constant [3 x i8*] [
i8* getelementptr ([24 x i8]* @$str_stream1, i64 0, i64 0), 
i8* getelementptr ([7 x i8]* @$str_stream2, i64 0, i64 0), 
i8* getelementptr ([98 x i8]* @$str_stream3, i64 0, i64 0)]
@$String_Table = internal global [3 x i64] 
[i64 0, i64 0, i64 0]
@$Strings = internal constant i64* bitcast ([3 x i64]* @$String_Table to i64*)
@_psc_global_to_do = external global {i64*, void()*}*
define internal void @$initialize_streams() {
   %_Str_Tab = load i64** @$Strings
   call void @_psc_reconstruct_strings(i16 3, i8** getelementptr ([3 x i8*]* @$Str_Streams, i64 0, i64 0), i64* %_Str_Tab)
   call void @_psc_register_compiled_operations(i16 1, i16* getelementptr ([2 x i16]* @$Module_Op_Indices, i64 0, i64 0), void(i64*, i64*, i64*)** getelementptr ([1 x void(i64*, i64*, i64*)*]* @$Local_Funcs, i64 0, i64 0), i8* getelementptr ([1 x i8]* @$Local_Funcs_Use_Queuing, i64 0, i64 0), i64* %_Str_Tab, i32 0, i16* getelementptr ([0 x i16]* @$Internal_Precond_Indices, i64 0, i64 0), i32(i64*, i64*, i64*)** getelementptr ([0 x i32(i64*, i64*, i64*)*]* @$Internal_Precond_Blocks, i64 0 , i64 0))
   ret void
}
@"_node_/Users/stt/_parasail/lib/aaa/aaa048enum_mask.psi" = global {i64*, void()*} {i64* null, void()* @$initialize_streams}
define internal void @$add_to_todo() {
   %_next = load {i64*, void()*}** @_psc_global_to_do
   %_nextc = bitcast {i64*, void()*}* %_next to i64*
   %_node.next_ptr = getelementptr {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa048enum_mask.psi", i32 0, i32 0
   store i64* %_nextc, i64** %_node.next_ptr
   store {i64*, void()*}* @"_node_/Users/stt/_parasail/lib/aaa/aaa048enum_mask.psi", {i64*, void()*}** @_psc_global_to_do
   ret void
}
@llvm.global_ctors = appending global [1 x {i32, void ()*}] [{i32, void()*} {i32 65535, void ()* @$add_to_todo}]

define void @"PSL.Core.Enum_Mask.$|$"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 19
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Start_Parallel_Op at 8:34
   %_master1 = getelementptr i64* %_Local_Area, i64 3
   %_static_Link1 = getelementptr i64* %_Local_Area, i64 0
   %_control1 = getelementptr i64* %_Local_Area, i64 6
   call void @_psc_execute_compiled_parallel_op(i64* %_Context, i64* %_master1, i64* %_control1, i32(i64*, i64*, i64*)* @"PSL.Core.Enum_Mask.$|$.9block", i64* %_static_Link1, i1 0, i1 1, i1 1)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 8:12
   %_desc2 = getelementptr i64* %_Static_Link, i64 0
   %_source_ptr2 = getelementptr i64* %_Param_Area, i64 0
   %_source2 = load i64* %_source_ptr2
   %_null2 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc2, i64 %_source2)
   %_dest_ptr2 = getelementptr i64* %_Local_Area, i64 17
   store i64 %_null2, i64* %_dest_ptr2

   ; #Wait_For_Parallel_Op at 8:34
   %_master3 = getelementptr i64* %_Local_Area, i64 3
   %_level_skip3 = call i32 @_psc_execute_wait_for_parallel_op(i64* %_Context, i64* %_master3)
   %_level_diff32_3 = ashr i32 %_level_skip3, 16
   %_level_diff3 = trunc i32 %_level_diff32_3 to i16
   %_skip_count3 = trunc i32 %_level_skip3 to i16
   %_level_diff_nz3 = icmp ne i16 %_level_diff3, 0
   br i1 %_level_diff_nz3, label %_exit3, label %_switch3
   _exit3:
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void
   _switch3:
   br label %_lbl4

_lbl4:
   ; #Copy_Word_Op at 8:34
   %_source4 = getelementptr i64* %_Local_Area, i64 16
   %_source_val4 = load i64* %_source4
   %_dest4 = getelementptr i64* %_Local_Area, i64 18
   store i64 %_source_val4, i64* %_dest4

   ; #Call_Op at 8:12
   %_call5_Static_Link = getelementptr i64* %_Static_Link, i64 0
   %_call5_Param_Area = getelementptr i64* %_Local_Area, i64 17
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call5_Param_Area, i64* %_call5_Static_Link, i16 3, i16 0, i16 3, i16 10003, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Copy_Word_Op at 8:12
   %_source6 = getelementptr i64* %_Local_Area, i64 17
   %_source_val6 = load i64* %_source6
   %_dest6 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val6, i64* %_dest6

   ; #Copy_Word_Op at 8:11
   %_source7 = getelementptr i64* %_Local_Area, i64 6
   %_source_val7 = load i64* %_source7
   %_dest7 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val7, i64* %_dest7

   ; #Check_Not_Null_Op at 8:11
   %_arg_ptr8 = getelementptr i64* %_Param_Area, i64 0
   %_arg8 = load i64* %_arg_ptr8
   %_desc8 = getelementptr i64* %_Static_Link, i64 0
   %_result8 = call i1 @_psc_is_null_value(i64 %_arg8, i64* %_desc8)
   br i1 %_result8, label %_fail8, label %_lbl9
   _fail8:
   %_str_ptr_ptr8 = load i64** @$Strings
   %_str_ptr8 = getelementptr i64* %_str_ptr_ptr8, i64 2
   %_assert_str8 = load i64* %_str_ptr8
   %_print_param8 = alloca i64
   store i64 %_assert_str8, i64* %_print_param8
   call void @_psc_runtime_message(i64* %_Context, i64* %_print_param8, i64* null)

   br label %_lbl9

_lbl9:
   ; #Return_Op at 8:11
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret void

   ; #Begin_Nested_Block_Op at 8:34
}

define internal i32 @"PSL.Core.Enum_Mask.$|$.9block"(i64* %_Context, i64* %_Param_Area, i64* %_Static_Link) {
   %_Local_Area = alloca i64, i64 21
   %_sl = ptrtoint i64* %_Static_Link to i64
   %_pa = ptrtoint i64* %_Param_Area to i64
   store i64 %_sl, i64* %_Local_Area
   %_store_pa = getelementptr i64* %_Local_Area, i64 1
   store i64 %_pa, i64* %_store_pa
   call void @_psc_initialize_stg_rgn(i64* %_Context, i64* %_Local_Area)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 8:37
   %_ptr_val0_110 = load i64* %_Static_Link
   %_ptr0_110 = inttoptr i64 %_ptr_val0_110 to i64*
   %_desc11 = call i64* @_psc_get_type_desc_or_op_map(i64* %_ptr0_110, i16 3, i16 1)
   %_encl_param_ptr111 = getelementptr i64* %_Static_Link, i64 1
   %_encl_param111 = load i64* %_encl_param_ptr111
   %_encl_param_as_ptr111 = inttoptr i64 %_encl_param111 to i64*
   %_source_ptr11 = getelementptr i64* %_encl_param_as_ptr111, i64 0
   %_source11 = load i64* %_source_ptr11
   %_null11 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc11, i64 %_source11)
   %_dest_ptr11 = getelementptr i64* %_Local_Area, i64 16
   store i64 %_null11, i64* %_dest_ptr11

   ; #Copy_Word_Op at 8:44
   %_encl_param_ptr121 = getelementptr i64* %_Static_Link, i64 1
   %_encl_param121 = load i64* %_encl_param_ptr121
   %_encl_param_as_ptr121 = inttoptr i64 %_encl_param121 to i64*
   %_source12 = getelementptr i64* %_encl_param_as_ptr121, i64 2
   %_source_val12 = load i64* %_source12
   %_dest12 = getelementptr i64* %_Local_Area, i64 17
   store i64 %_source_val12, i64* %_dest12

   ; #Start_Parallel_Call_Op at 8:37
   %_master13 = getelementptr i64* %_Local_Area, i64 3
   %_ptr_val0_130 = load i64* %_Static_Link
   %_ptr0_130 = inttoptr i64 %_ptr_val0_130 to i64*
   %_static_Link13 = getelementptr i64* %_ptr0_130, i64 0
   %_control13 = getelementptr i64* %_Local_Area, i64 6
   call void @_psc_execute_compiled_indirect_parallel_call_op(i64* %_Context, i64* %_master13, i64* %_control13, i16 3, i16 10004, i64* %_static_Link13, i16 3, i16 0, i1 1, i1 1, i8 0)

   ; #Store_Null_Of_Same_Stg_Rgn_Op at 8:34
   %_ptr_val0_140 = load i64* %_Static_Link
   %_ptr0_140 = inttoptr i64 %_ptr_val0_140 to i64*
   %_desc14 = call i64* @_psc_get_type_desc_or_op_map(i64* %_ptr0_140, i16 3, i16 1)
   %_encl_param_ptr141 = getelementptr i64* %_Static_Link, i64 1
   %_encl_param141 = load i64* %_encl_param_ptr141
   %_encl_param_as_ptr141 = inttoptr i64 %_encl_param141 to i64*
   %_source_ptr14 = getelementptr i64* %_encl_param_as_ptr141, i64 0
   %_source14 = load i64* %_source_ptr14
   %_null14 = call i64 @_psc_null_of_same_stg_rgn(i64* %_desc14, i64 %_source14)
   %_dest_ptr14 = getelementptr i64* %_Local_Area, i64 18
   store i64 %_null14, i64* %_dest_ptr14

   ; #Store_Local_Null_Op at 8:21
   %_ptr_val0_150 = load i64* %_Static_Link
   %_ptr0_150 = inttoptr i64 %_ptr_val0_150 to i64*
   %_desc15 = call i64* @_psc_get_type_desc_or_op_map(i64* %_ptr0_150, i16 3, i16 1)
   %_null15 = call i64 @_psc_local_null(i64* %_Context, i64* %_desc15)
   %_dest_ptr15 = getelementptr i64* %_Local_Area, i64 19
   store i64 %_null15, i64* %_dest_ptr15

   ; #Copy_Word_Op at 8:28
   %_encl_param_ptr161 = getelementptr i64* %_Static_Link, i64 1
   %_encl_param161 = load i64* %_encl_param_ptr161
   %_encl_param_as_ptr161 = inttoptr i64 %_encl_param161 to i64*
   %_source16 = getelementptr i64* %_encl_param_as_ptr161, i64 1
   %_source_val16 = load i64* %_source16
   %_dest16 = getelementptr i64* %_Local_Area, i64 20
   store i64 %_source_val16, i64* %_dest16

   ; #Call_Op at 8:21
   %_ptr_val0_170 = load i64* %_Static_Link
   %_ptr0_170 = inttoptr i64 %_ptr_val0_170 to i64*
   %_call17_Static_Link = getelementptr i64* %_ptr0_170, i64 0
   %_call17_Param_Area = getelementptr i64* %_Local_Area, i64 19
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call17_Param_Area, i64* %_call17_Static_Link, i16 3, i16 0, i16 3, i16 10004, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Wait_For_Parallel_Op at 8:37
   %_master18 = getelementptr i64* %_Local_Area, i64 3
   %_level_skip18 = call i32 @_psc_execute_wait_for_parallel_op(i64* %_Context, i64* %_master18)
   %_level_diff32_18 = ashr i32 %_level_skip18, 16
   %_level_diff18 = trunc i32 %_level_diff32_18 to i16
   %_skip_count18 = trunc i32 %_level_skip18 to i16
   %_level_diff_nz18 = icmp ne i16 %_level_diff18, 0
   br i1 %_level_diff_nz18, label %_exit18, label %_switch18
   _exit18:
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   %_level_diff_minus_one18 = sub nsw i16 %_level_diff18, 1
   %_ld_zext18 = zext i16 %_level_diff_minus_one18 to i32
   %_ld_shifted18 = shl i32 %_ld_zext18, 16
   %_skip_zext18 = zext i16 %_skip_count18 to i32
   %_levelm1_skip18 = or i32 %_ld_shifted18, %_skip_zext18
   ret i32 %_levelm1_skip18
   _switch18:
   br label %_lbl19

_lbl19:
   ; #Copy_Word_Op at 8:37
   %_source19 = getelementptr i64* %_Local_Area, i64 16
   %_source_val19 = load i64* %_source19
   %_dest19 = getelementptr i64* %_Local_Area, i64 20
   store i64 %_source_val19, i64* %_dest19

   ; #Call_Op at 8:34
   %_ptr_val0_200 = load i64* %_Static_Link
   %_ptr0_200 = inttoptr i64 %_ptr_val0_200 to i64*
   %_call20_Static_Link = call i64* @_psc_get_type_desc_or_op_map(i64* %_ptr0_200, i16 3, i16 1)
   %_call20_Param_Area = getelementptr i64* %_Local_Area, i64 18
   call void @_psc_execute_compiled_indirect_call_op(i64* %_Context, i64* %_call20_Param_Area, i64* %_call20_Static_Link, i16 3, i16 1, i16 3, i16 10023, i64 0, void(i64*, i64*, i64*)* null, i8 0)

   ; #Copy_Word_Op at 8:34
   %_source21 = getelementptr i64* %_Local_Area, i64 18
   %_source_val21 = load i64* %_source21
   %_dest21 = getelementptr i64* %_Local_Area, i64 6
   store i64 %_source_val21, i64* %_dest21

   ; #Copy_Word_Op at 8:34
   %_source22 = getelementptr i64* %_Local_Area, i64 6
   %_source_val22 = load i64* %_source22
   %_dest22 = getelementptr i64* %_Param_Area, i64 0
   store i64 %_source_val22, i64* %_dest22

   ; #Exit_Op at 0:0
   call void @_psc_finalize_stg_rgn(i64* %_Context, i64* %_Local_Area)
   ret i32 0

}

