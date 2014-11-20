/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_ITEM_TRANS_OUT_V
 * Description     : 商品振替入力画面出庫用ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-1-14     1.0   SCS M.Yoshioka   新規作成
 *  2009/04/30    1.1   T.Nakamura       [障害T1_0877] セミコロンを追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_ITEM_TRANS_OUT_V
  (row_id
  ,transaction_id                                                     -- 入出庫一時表ID
  ,inventory_item_id                                                  -- 品目ID
  ,item_code                                                          -- 品目コード
  ,primary_uom_code                                                   -- 基準単位
  ,quantity                                                           -- 本数
  ,unit_price                                                         -- 単価
  ,last_update_date                                                   -- 最終更新日
  ,last_updated_by                                                    -- 最終更新者
  ,creation_date                                                      -- 作成日
  ,created_by                                                         -- 作成者
  ,last_update_login                                                  -- 最終更新ユーザ
  ,request_id                                                         -- 要求ID
  ,program_application_id                                             -- プログラムアプリケーションID
  ,program_id                                                         -- プログラムID
  ,program_update_date                                                -- プログラム更新日
  )
AS
SELECT xhiw.rowid                                                     -- rowid
      ,xhiw.transaction_id                                            -- 入出庫一時表ID
      ,xhiw.inventory_item_id                                         -- 品目ID
      ,xhiw.item_code                                                 -- 品目コード
      ,xhiw.primary_uom_code                                          -- 基準単位
      ,xhiw.quantity                                                  -- 本数
      ,xhiw.unit_price                                                -- 単価
      ,xhiw.last_update_date                                          -- 最終更新日
      ,xhiw.last_updated_by                                           -- 最終更新者
      ,xhiw.creation_date                                             -- 作成日
      ,xhiw.created_by                                                -- 作成者
      ,xhiw.last_update_login                                         -- 最終更新ユーザ
      ,xhiw.request_id                                                -- 要求ID
      ,xhiw.program_application_id                                    -- プログラムアプリケーションID
      ,xhiw.program_id                                                -- プログラムID
      ,xhiw.program_update_date                                       -- プログラム更新日
FROM   xxcoi_hht_inv_transactions   xhiw;                             -- HHT入出庫一時表
/
COMMENT ON TABLE xxcoi_item_trans_out_v IS '商品振替入力画面出庫用ビュー';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.transaction_id IS '入出庫一時表ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.inventory_item_id IS '品目ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.item_code IS '品目コード';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.primary_uom_code IS '基準単位';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.quantity IS '本数';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.unit_price IS '単価';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_update_date IS '最終更新日';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_updated_by IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.creation_date IS '作成日';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.created_by IS '作成者';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.last_update_login IS '最終更新ユーザ';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.request_id IS '要求ID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_application_id IS 'プログラムアプリケーションID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_id IS 'プログラムID';
/
COMMENT ON COLUMN xxcoi_item_trans_out_v.program_update_date IS 'プログラム更新日';
/
