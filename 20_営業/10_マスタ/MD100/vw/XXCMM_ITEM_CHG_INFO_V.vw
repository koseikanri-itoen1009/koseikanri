/*************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 * 
 * View Name       : XXCMM_ITEM_CHG_INFO_V
 * Description     : 変更予約情報ビュー
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2017/06/22    1.0   S.Niki       E_本稼動_14300 初回作成
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW apps.xxcmm_item_chg_info_v(
   item_code            -- 品目コード
  ,apply_date           -- 適用日
  ,item_status          -- 品目ステータス
  ,fixed_price          -- 定価
  ,discrete_cost        -- 営業原価
  ,policy_group         -- 政策群
 )
 AS
   SELECT xsibh.item_code        AS item_code
         ,xsibh.apply_date       AS apply_date
         ,xsibh.item_status      AS item_status
         ,xsibh.fixed_price      AS fixed_price
         ,xsibh.discrete_cost    AS discrete_cost
         ,xsibh.policy_group     AS policy_group
     FROM xxcmm_system_items_b_hst xsibh
    WHERE xsibh.apply_flag   = 'N'  -- 未適用
      AND NOT EXISTS (SELECT 'X'
                        FROM xxcmm_tmp_item_chg_upload wk
                       WHERE wk.item_code   = xsibh.item_code
                         AND wk.apply_date  = xsibh.apply_date
                         AND wk.status      = 'D'     -- 削除
          )
   UNION
   SELECT xticu.item_code        AS item_code
         ,xticu.apply_date       AS apply_date
         ,xticu.new_item_status  AS item_status
         ,NULL                   AS fixed_price
         ,xticu.discrete_cost    AS discrete_cost
         ,xticu.policy_group     AS policy_group
     FROM xxcmm_tmp_item_chg_upload xticu
    WHERE xticu.status       <> 'D'         -- 削除以外
      AND xticu.apply_date   >= xxccp_common_pkg2.get_process_date
/
COMMENT ON TABLE apps.xxcmm_item_chg_info_v IS '変更予約情報ビュー'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.item_code         IS '品目コード'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.apply_date        IS '適用日'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.item_status       IS '品目ステータス'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.fixed_price       IS '定価'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.discrete_cost     IS '営業原価'
/
COMMENT ON COLUMN apps.xxcmm_item_chg_info_v.policy_group      IS '政策群'
/
