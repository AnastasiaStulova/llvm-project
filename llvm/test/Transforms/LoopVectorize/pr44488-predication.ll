; RUN: opt < %s -force-vector-width=2 -force-vector-interleave=1 -loop-vectorize -S | FileCheck %s

; Test case for PR44488. Checks that the correct predicates are created for
; branches where true and false successors are equal. See the checks involving
; CMP1 and CMP2.

@v_38 = global i16 12061, align 1
@v_39 = global i16 11333, align 1

define i16 @test_true_and_false_branch_equal() {
; CHECK-LABEL: @test_true_and_false_branch_equal(
; CHECK-LABEL: vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, %vector.ph ], [ [[INDEX_NEXT:%.*]], [[PRED_SREM_CONTINUE2:%.*]] ]
; CHECK-NEXT:    [[TMP0:%.*]] = trunc i32 [[INDEX]] to i16
; CHECK-NEXT:    [[OFFSET_IDX:%.*]] = add i16 99, [[TMP0]]
; CHECK-NEXT:    [[BROADCAST_SPLATINSERT:%.*]] = insertelement <2 x i16> undef, i16 [[OFFSET_IDX]], i32 0
; CHECK-NEXT:    [[BROADCAST_SPLAT:%.*]] = shufflevector <2 x i16> [[BROADCAST_SPLATINSERT]], <2 x i16> undef, <2 x i32> zeroinitializer
; CHECK-NEXT:    [[INDUCTION:%.*]] = add <2 x i16> [[BROADCAST_SPLAT]], <i16 0, i16 1>
; CHECK-NEXT:    [[TMP1:%.*]] = add i16 [[OFFSET_IDX]], 0
; CHECK-NEXT:    [[TMP2:%.*]] = load i16, i16* @v_38, align 1
; CHECK-NEXT:    [[TMP3:%.*]] = load i16, i16* @v_38, align 1
; CHECK-NEXT:    [[TMP4:%.*]] = insertelement <2 x i16> undef, i16 [[TMP2]], i32 0
; CHECK-NEXT:    [[TMP5:%.*]] = insertelement <2 x i16> [[TMP4]], i16 [[TMP3]], i32 1
; CHECK-NEXT:    [[CMP1:%.*]] = icmp eq <2 x i16> [[TMP5]], <i16 32767, i16 32767>
; CHECK-NEXT:    [[CMP2:%.*]] = icmp eq <2 x i16> [[TMP5]], zeroinitializer
; CHECK-NEXT:    [[NOT_CMP2:%.*]] = xor <2 x i1> [[CMP2]], <i1 true, i1 true>
; CHECK-NEXT:    [[PRED1:%.*]] = extractelement <2 x i1> [[NOT_CMP2]], i32 0
; CHECK-NEXT:    br i1 [[PRED1]], label [[PRED_SREM_IF:%.*]], label [[PRED_SREM_CONTINUE:%.*]]
; CHECK:       pred.srem.if:
; CHECK-NEXT:    [[TMP14:%.*]] = srem i16 5786, [[TMP2]]
; CHECK-NEXT:    [[TMP15:%.*]] = insertelement <2 x i16> undef, i16 [[TMP14]], i32 0
; CHECK-NEXT:    br label [[PRED_SREM_CONTINUE]]
; CHECK:       pred.srem.continue:
; CHECK-NEXT:    [[TMP16:%.*]] = phi <2 x i16> [ undef, %vector.body ], [ [[TMP15]], [[PRED_SREM_IF]] ]
; CHECK-NEXT:    [[PRED2:%.*]] = extractelement <2 x i1> [[NOT_CMP2]], i32 1
; CHECK-NEXT:    br i1 [[PRED2]], label [[PRED_SREM_IF1:%.*]], label [[PRED_SREM_CONTINUE2]]
; CHECK:       pred.srem.if1:
; CHECK-NEXT:    [[TMP18:%.*]] = srem i16 5786, [[TMP3]]
; CHECK-NEXT:    [[TMP19:%.*]] = insertelement <2 x i16> [[TMP16]], i16 [[TMP18]], i32 1
; CHECK-NEXT:    br label [[PRED_SREM_CONTINUE2]]
; CHECK:       pred.srem.continue2:
; CHECK-NEXT:    [[TMP20:%.*]] = phi <2 x i16> [ [[TMP16]], [[PRED_SREM_CONTINUE]] ], [ [[TMP19]], [[PRED_SREM_IF1]] ]
; CHECK-NEXT:    [[PREDPHI:%.*]] = select <2 x i1> [[CMP2]], <2 x i16> <i16 5786, i16 5786>, <2 x i16> [[TMP20]]
; CHECK-NEXT:    [[TMP22:%.*]] = extractelement <2 x i16> [[PREDPHI]], i32 0
; CHECK-NEXT:    store i16 [[TMP22]], i16* @v_39, align 1
; CHECK-NEXT:    [[TMP23:%.*]] = extractelement <2 x i16> [[PREDPHI]], i32 1
; CHECK-NEXT:    store i16 [[TMP23]], i16* @v_39, align 1
; CHECK-NEXT:    [[INDEX_NEXT]] = add i32 [[INDEX]], 2
; CHECK-NEXT:    [[TMP24:%.*]] = icmp eq i32 [[INDEX_NEXT]], 12
; CHECK-NEXT:    br i1 [[TMP24]], label %middle.block, label %vector.body, !llvm.loop !0
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.latch
  %i.07 = phi i16 [ 99, %entry ], [ %inc7, %for.latch ]
  %lv = load i16, i16* @v_38, align 1
  %cmp1 = icmp eq i16 %lv, 32767
  br i1 %cmp1, label %cond.end, label %cond.end

cond.end:                                         ; preds = %for.body, %for.body
  %cmp2 = icmp eq i16 %lv, 0
  br i1 %cmp2, label %for.latch, label %cond.false4

cond.false4:                                      ; preds = %cond.end
  %rem = srem i16 5786, %lv
  br label %for.latch

for.latch:                                        ; preds = %cond.end, %cond.false4
  %cond6 = phi i16 [ %rem, %cond.false4 ], [ 5786, %cond.end ]
  store i16 %cond6, i16* @v_39, align 1
  %inc7 = add nsw i16 %i.07, 1
  %cmp = icmp slt i16 %inc7, 111
  br i1 %cmp, label %for.body, label %exit

exit:                                 ; preds = %for.latch
  %rv = load i16, i16* @v_39, align 1
  ret i16 %rv
}
