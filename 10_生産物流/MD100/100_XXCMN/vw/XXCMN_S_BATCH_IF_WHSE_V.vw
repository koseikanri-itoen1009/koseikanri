/************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * View Name       : XXCMN_S_BATCH_IF_WHSE_V
 * Description     : 値セット用VIEW（XXCMN_S_BATCH_IF_WHSE）
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2016/06/24    1.0   S.Yamashita      新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcmn_s_batch_if_whse_v
(
  whse_code
 ,whse_name
)
AS
  SELECT DISTINCT
    iwm.whse_code   AS whse_code -- 倉庫コード
   ,iwm.whse_name   AS whse_name -- 倉庫名称
  FROM
    gmd_routings_b  grb -- 工順マスタ
   ,ic_whse_mst     iwm -- OPM倉庫マスタ
  WHERE
        grb.attribute22 = 'Y'  -- 生産バッチ情報IF対象フラグ
  AND   grb.attribute21 = iwm.whse_code -- 倉庫コード
;
--
COMMENT ON COLUMN xxcmn_s_batch_if_whse_v.whse_code IS '倉庫コード';
COMMENT ON COLUMN xxcmn_s_batch_if_whse_v.whse_name IS '倉庫名称';
--
COMMENT ON TABLE  xxcmn_s_batch_if_whse_v IS '値セット用VIEW（XXCMN_S_BATCH_IF_WHSE）';
