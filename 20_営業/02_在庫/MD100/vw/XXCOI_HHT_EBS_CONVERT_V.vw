/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name     : XXCOI_HHT_EBS_CONVERT_V
 * Description   : 入出庫ジャーナルコード変換ビュー
 * Version       : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date         Ver.  Editor     Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-11-17   1.0   SCS H.Nakajima   新規作成
 *  2009-01-21   1.1   SCS H.Nakajima   有効日、無効日の追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_hht_ebs_convert_v(
   lookup_type
  ,lookup_code
  ,lookup_meaning
  ,record_type
  ,invoice_type
  ,department_flag
  ,outside_subinv_code_conv_div
  ,inside_subinv_code_conv_div
  ,program_div
  ,consume_vd_flag
  ,stock_uncheck_list_div
  ,stock_balance_list_div
  ,item_convert_div
  ,start_date_active
  ,end_date_active
) AS SELECT 
   flv.lookup_type 
  ,flv.lookup_code 
  ,flv.meaning   
  ,flv.attribute1  
  ,flv.attribute2  
  ,flv.attribute3  
  ,flv.attribute4  
  ,flv.attribute5  
  ,flv.attribute6  
  ,flv.attribute7  
  ,flv.attribute8  
  ,flv.attribute9  
  ,flv.attribute10 
  ,flv.start_date_active
  ,flv.end_date_active
FROM fnd_lookup_values flv
WHERE flv.lookup_type  = 'XXCOI1_HHT_EBS_CONVERT_TABLE'
AND   flv.language     = USERENV( 'LANG' )
AND   flv.enabled_flag = 'Y'
/
COMMENT ON TABLE xxcoi_hht_ebs_convert_v IS '入出庫ジャーナルコード変換ビュー'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_type IS 'クイックコードタイプ'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_code IS 'クイックコード'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.lookup_meaning IS '意味'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.record_type IS 'レコード種別'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.invoice_type IS '伝票区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.department_flag IS '百貨店フラグ'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div IS '出庫側保管場所変換区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div IS '入庫側保管場所変換区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.program_div IS '入出庫ジャーナル処理区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.consume_vd_flag IS '消化VD対象フラグ'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.stock_uncheck_list_div IS '入庫未確認リスト対象区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.stock_balance_list_div IS '入庫差異確認リスト対象区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.item_convert_div IS '商品振替区分'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.start_date_active IS '開始日'
/
COMMENT ON COLUMN xxcoi_hht_ebs_convert_v.end_date_active IS '終了日'
/
