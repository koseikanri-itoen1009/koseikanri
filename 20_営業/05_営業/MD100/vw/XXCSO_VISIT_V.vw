/*************************************************************************
 * 
 * VIEW Name       : xxcso_visit_v
 * Description     : 共通用：訪問実績ビュー
 * MD.070          : 
 * Version         : 1.3
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/04    1.1  K.Boku        有効訪問区分判定に登録区分を追加
 *  2009/04/14    1.2  K.Satomura    システムテスト障害対応(T1_0479,T1_0480)
 *  2009/04/24    1.3  K.Satomura    システムテスト障害対応(T1_0734)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_visit_v
(
 party_id
,task_id
,owner_id
,actual_end_date
,attribute1
,attribute2
,attribute3
,attribute4
,attribute5
,attribute6
,attribute7
,attribute8
,attribute9
,attribute10
,eff_visit_flag
,register_div
/* 2009.04.14 K.Satomura T1_0734対応 START */
--,order_no_hht
,attribute13
/* 2009.04.14 K.Satomura T1_0734対応 END */
,customer_status
,visit_num_a
,visit_num_b
,visit_num_c
,visit_num_d
,visit_num_e
,visit_num_f
,visit_num_g
,visit_num_h
,visit_num_i
,visit_num_j
,visit_num_k
,visit_num_l
,visit_num_m
,visit_num_n
,visit_num_o
,visit_num_p
,visit_num_q
,visit_num_r
,visit_num_s
,visit_num_t
,visit_num_u
,visit_num_v
,visit_num_w
,visit_num_x
,visit_num_y
,visit_num_z
)
AS
SELECT  jtb.source_object_id
       ,jtb.task_id
       ,jtb.owner_id
       ,jtb.actual_end_date
       ,jtb.attribute1
       ,jtb.attribute2
       ,jtb.attribute3
       ,jtb.attribute4
       ,jtb.attribute5
       ,jtb.attribute6
       ,jtb.attribute7
       ,jtb.attribute8
       ,jtb.attribute9
       ,jtb.attribute10
       ,DECODE(
          (NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' '))
         ,'1-3', '1'
         ,'1-5', '1'
         ,'0'
        )
       ,jtb.attribute12
       ,jtb.attribute13
       ,jtb.attribute14
       ,DECODE(NVL(flv1.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'A', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'A', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'B', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'B', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'C', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'C', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'D', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'D', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'E', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'E', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'F', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'F', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'G', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'G', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'H', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'H', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'I', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'I', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'J', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'J', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'K', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'K', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'L', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'L', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'M', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'M', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'N', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'N', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'O', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'O', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'P', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'P', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'Q', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'Q', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'R', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'R', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'S', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'S', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'T', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'T', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'U', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'U', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'V', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'V', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'W', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'W', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'X', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'X', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'Y', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'Y', 1, 0)
       ,DECODE(NVL(flv1.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv2.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv3.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv4.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv5.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv6.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv7.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv8.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv9.attribute1, ' '), 'Z', 1, 0) + 
        DECODE(NVL(flv10.attribute1, ' '), 'Z', 1, 0)
FROM    jtf_tasks_b  jtb
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv1
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv2
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv3
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv4
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv5
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv6
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv7
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv8
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv9
       ,(
         SELECT
           flvv.lookup_code
          ,flvv.attribute1
         FROM
           fnd_lookup_values_vl flvv
         WHERE
           flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND
           flvv.enabled_flag = 'Y'
         AND
           NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND
           NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
        )  flv10
WHERE  jtb.source_object_type_code = 'PARTY'
AND  jtb.task_status_id =  FND_PROFILE.VALUE('XXCSO1_TASK_STATUS_CLOSED_ID')
AND  jtb.owner_type_code = 'RS_EMPLOYEE'
AND  jtb.deleted_flag = 'N'
AND  jtb.attribute1 = flv1.lookup_code(+)
AND  jtb.attribute2 = flv2.lookup_code(+)
AND  jtb.attribute3 = flv3.lookup_code(+)
AND  jtb.attribute4 = flv4.lookup_code(+)
AND  jtb.attribute5 = flv5.lookup_code(+)
AND  jtb.attribute6 = flv6.lookup_code(+)
AND  jtb.attribute7 = flv7.lookup_code(+)
AND  jtb.attribute8 = flv8.lookup_code(+)
AND  jtb.attribute9 = flv9.lookup_code(+)
AND  jtb.attribute10 = flv10.lookup_code(+)
/* 2009.04.14 K.Satomura T1_0734対応 START */
AND  jtb.actual_end_date IS NOT NULL
/* 2009.04.14 K.Satomura T1_0734対応 END */
/* 2009.04.14 K.Satomura T1_0479,T1_0480対応 START */
AND  jtb.task_type_id = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
UNION ALL
/* 2009.04.14 K.Satomura T1_0734対応 START */
--SELECT jtb.source_object_id
SELECT ala.customer_id
/* 2009.04.14 K.Satomura T1_0734対応 END */
      ,jtb.task_id
      ,jtb.owner_id
      ,jtb.actual_end_date
      ,jtb.attribute1
      ,jtb.attribute2
      ,jtb.attribute3
      ,jtb.attribute4
      ,jtb.attribute5
      ,jtb.attribute6
      ,jtb.attribute7
      ,jtb.attribute8
      ,jtb.attribute9
      ,jtb.attribute10
      ,DECODE(
         (NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' '))
        ,'1-3', '1'
        ,'1-5', '1'
        ,'0'
       )
      ,jtb.attribute12
      ,jtb.attribute13
      ,jtb.attribute14
      ,DECODE(NVL(flv1.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'A', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'A', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'B', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'B', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'C', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'C', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'D', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'D', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'E', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'E', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'F', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'F', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'G', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'G', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'H', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'H', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'I', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'I', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'J', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'J', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'K', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'K', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'L', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'L', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'M', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'M', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'N', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'N', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'O', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'O', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'P', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'P', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'Q', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'Q', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'R', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'R', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'S', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'S', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'T', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'T', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'U', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'U', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'V', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'V', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'W', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'W', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'X', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'X', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'Y', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'Y', 1, 0)
      ,DECODE(NVL(flv1.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv2.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv3.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv4.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv5.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv6.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv7.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv8.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv9.attribute1, ' '), 'Z', 1, 0) + 
       DECODE(NVL(flv10.attribute1, ' '), 'Z', 1, 0)
FROM   jtf_tasks_b  jtb
      ,as_leads_all ala
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv1
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv2
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv3
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv4
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv5
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type = 'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag = 'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active,   TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
       ) flv6
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv7
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv8
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv9
      ,(
         SELECT flvv.lookup_code
               ,flvv.attribute1
         FROM   fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type                            =  'XXCSO_ASN_HOUMON_KUBUN'
         AND    flvv.enabled_flag                           =  'Y'
         AND    NVL(flvv.start_date_active, TRUNC(SYSDATE)) <= TRUNC(SYSDATE)
         AND    NVL(flvv.end_date_active, TRUNC(SYSDATE))   >= TRUNC(SYSDATE)
       ) flv10
WHERE  jtb.source_object_type_code = 'OPPORTUNITY'
AND    jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
AND    jtb.owner_type_code         = 'RS_EMPLOYEE'
AND    jtb.deleted_flag            = 'N'
AND    jtb.attribute1              = flv1.lookup_code(+)
AND    jtb.attribute2              = flv2.lookup_code(+)
AND    jtb.attribute3              = flv3.lookup_code(+)
AND    jtb.attribute4              = flv4.lookup_code(+)
AND    jtb.attribute5              = flv5.lookup_code(+)
AND    jtb.attribute6              = flv6.lookup_code(+)
AND    jtb.attribute7              = flv7.lookup_code(+)
AND    jtb.attribute8              = flv8.lookup_code(+)
AND    jtb.attribute9              = flv9.lookup_code(+)
AND    jtb.attribute10             = flv10.lookup_code(+)
/* 2009.04.14 K.Satomura T1_0734対応 START */
--AND    ala.customer_id             = jtb.source_object_id
AND    ala.lead_id                 = jtb.source_object_id
AND    jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
AND    jtb.actual_end_date IS NOT NULL
/* 2009.04.14 K.Satomura T1_0734対応 END */
/* 2009.04.14 K.Satomura T1_0479,T1_0480対応 END */
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_VISIT_V IS '共通用：訪問実績ビュー';
