/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_BASE_INFO_V
 * Description     : 拠点情報ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-05    1.0   SCS M.Yoshioka   新規作成
 *  2009/04/30    1.1   T.Nakamura       [障害T1_0877] セミコロンを追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_BASE_INFO_V
  (base_code                                                          -- 拠点コード
  ,base_short_name                                                    -- 拠点略称
  ,focus_base_code                                                    -- 絞込み拠点
  )
AS
SELECT hca.account_number                                             -- 拠点コード
      ,SUBSTRB(hca.account_name,1,8)                                  -- 拠点略称
      ,xca.management_base_code                                       -- 絞込み拠点
FROM hz_cust_accounts hca                                             -- 顧客マスタ
    ,xxcmm_cust_accounts xca                                          -- 顧客追加情報
WHERE hca.customer_class_code = '1'
    AND hca.status = 'A'
    AND hca.cust_account_id = xca.customer_id
    AND hca.account_number <> NVL(xca.management_base_code,'99999')
    AND xca.management_base_code IS NOT NULL
UNION ALL
SELECT hca.account_number                                             -- 拠点コード
      ,SUBSTRB(hca.account_name,1,8)                                  -- 拠点略称
      ,hca.account_number                                             -- 絞込み拠点
FROM hz_cust_accounts hca                                             -- 顧客マスタ
    ,xxcmm_cust_accounts xca                                          -- 顧客追加情報
WHERE hca.customer_class_code = '1'
    AND hca.status = 'A'
    AND hca.cust_account_id = xca.customer_id
    AND hca.account_number <> NVL(xca.management_base_code,'99999');
/
COMMENT ON TABLE xxcoi_base_info_v IS '拠点情報ビュー';
/
COMMENT ON COLUMN xxcoi_base_info_v.base_code IS '拠点コード';
/
COMMENT ON COLUMN xxcoi_base_info_v.base_short_name IS '拠点略称';
/
COMMENT ON COLUMN xxcoi_base_info_v.focus_base_code IS '絞込み拠点';
/
