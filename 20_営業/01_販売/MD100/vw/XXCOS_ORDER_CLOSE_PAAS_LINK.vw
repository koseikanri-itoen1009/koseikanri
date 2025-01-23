/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * View Name       : xxcos_order_close_paas_link
 * Description     : アドオン受注クローズビュー
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2024/01/17    1.0   S.Kato         ST不具合No.0066対応。新規作成
 *  2024/01/22    1.1   T.Nishikawa    ST不具合No.0043対応
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_close_paas_link
AS
  SELECT
      xoc.order_line_id
    , ooha.global_attribute6        AS order_number
    , oola.global_attribute8        AS order_line_number
    , xoc.created_by
    , xoc.creation_date
    , xoc.last_updated_by
    , xoc.last_update_date
    , xoc.last_update_login
    , xoc.request_id
    , xoc.program_application_id
    , xoc.program_id
    , xoc.program_update_date
  FROM
      xxcos_order_close                                    xoc     -- 受注クローズ対象情報
    , oe_order_lines_all                                   oola    -- 受注明細
    , oe_order_headers_all                                 ooha    -- 受注ヘッダ
    , oicuser.xxccd_if_process_mng@ebs_paas3.itoen.master  xipm    -- 連携処理管理テーブル（ebs受注番号のpaas取込）
  WHERE 
        oola.line_id      =  xoc.order_line_id
  AND   ooha.header_id    =  oola.header_id
  AND   xipm.function_id  =  'XXCOS005A21C'
-- Ver1.1 Mod Start
--  AND   xoc.creation_date >= xipm.pre_process_date
  AND   xoc.creation_date >= xipm.pre_process_date - 2/24
-- Ver1.1 Mod End
  ;
