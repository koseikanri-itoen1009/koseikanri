  CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_MOV_LOT_DETAILS_V" (
    mov_lot_dtl_id
   ,mov_line_id
   ,document_type_code
   ,record_type_code
   ,item_id
   ,item_code
   ,lot_id
   ,lot_no
   ,actual_date
   ,actual_quantity
   ,before_actual_quantity
   ,automanual_reserve_class
   ,actual_confirm_class
   ,created_by
   ,creation_date
   ,last_updated_by
   ,last_update_date
   ,last_update_login
   ,request_id
   ,program_application_id
   ,program_id
   ,program_update_date
 ) AS 
  SELECT xmld.mov_lot_dtl_id
        ,xmld.mov_line_id
        ,xmld.document_type_code
        ,xmld.record_type_code
        ,xmld.item_id
        ,xmld.item_code
        ,xmld.lot_id
        ,xmld.lot_no
        ,xmld.actual_date
        ,xmld.actual_quantity
        ,xmld.before_actual_quantity
        ,xmld.automanual_reserve_class
        ,xmld.created_by
        ,xmld.creation_date
        ,xmld.last_updated_by
        ,xmld.last_update_date
        ,xmld.last_update_login
        ,xmld.request_id
        ,xmld.program_application_id
        ,xmld.program_id
        ,xmld.program_update_date
        ,xmld.actual_confirm_class
   FROM xxinv_mov_lot_details xmld
  WHERE xmld.actual_confirm_class = 'N'
;
--
COMMENT ON COLUMN xxinv_mov_lot_details_v.mov_lot_dtl_id           IS 'ロット詳細ID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.mov_line_id              IS '明細ID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.document_type_code       IS '文書タイプ';
COMMENT ON COLUMN xxinv_mov_lot_details_v.record_type_code         IS 'レコードタイプ';
COMMENT ON COLUMN xxinv_mov_lot_details_v.item_id                  IS 'OPM品目ID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.item_code                IS '品目';
COMMENT ON COLUMN xxinv_mov_lot_details_v.lot_id                   IS 'ロットID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.lot_no                   IS 'ロットNo';
COMMENT ON COLUMN xxinv_mov_lot_details_v.actual_date              IS '実績日';
COMMENT ON COLUMN xxinv_mov_lot_details_v.actual_quantity          IS '実績数量';
COMMENT ON COLUMN xxinv_mov_lot_details_v.before_actual_quantity   IS '訂正前実績数量';
COMMENT ON COLUMN xxinv_mov_lot_details_v.automanual_reserve_class IS '自動手動引当区分';
COMMENT ON COLUMN xxinv_mov_lot_details_v.actual_confirm_class     IS '実績計上済区分';
COMMENT ON COLUMN xxinv_mov_lot_details_v.created_by               IS '作成者';
COMMENT ON COLUMN xxinv_mov_lot_details_v.creation_date            IS '作成日';
COMMENT ON COLUMN xxinv_mov_lot_details_v.last_updated_by          IS '最終更新者';
COMMENT ON COLUMN xxinv_mov_lot_details_v.last_update_date         IS '最終更新日';
COMMENT ON COLUMN xxinv_mov_lot_details_v.last_update_login        IS '最終更新ログイン';
COMMENT ON COLUMN xxinv_mov_lot_details_v.request_id               IS '要求ID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.program_application_id   IS 'コンカレント・プログラム・アプリケーションID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.program_id               IS 'コンカレント・プログラムID';
COMMENT ON COLUMN xxinv_mov_lot_details_v.program_update_date      IS 'プログラム更新日';
--
COMMENT ON TABLE  XXINV_MOV_LOT_DETAILS_V IS '移動ロット詳細実績未反映VIEW';
/
