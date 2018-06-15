CREATE OR REPLACE PACKAGE XXCOS_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOS_COMMON3_PKG(spec)
 * Description      : 共通関数パッケージ3(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.1
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  process_order               P                 oe_order_pub.process_orderのパッケージ関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/04/18    1.0   H.Sasaki         新規作成
 *  2018/06/12    1.1   H.Sasaki         単価の自動更新制御[E_本稼動_14886]
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : process_order
   * Description      : oe_order_pub.process_orderのパッケージ関数
   ***********************************************************************************/
  PROCEDURE process_order(
      iv_upd_status_booked    IN  VARCHAR2                                              --  ステータス更新フラグ（記帳）
    , iv_upd_request_date     IN  VARCHAR2                                              --  着日更新フラグ
--  2018/06/12 V1.1 Added START
    , iv_upd_item_code        IN  VARCHAR2                                              --  品目更新フラグ
--  2018/06/12 V1.1 Added END
    , it_header_id            IN  oe_order_headers_all.header_id%TYPE                   --  ヘッダID
    , it_line_id              IN  oe_order_lines_all.line_id%TYPE                       --  明細ID
    , it_inventory_item_id    IN  oe_order_lines_all.inventory_item_id%TYPE             --  品目ID
    , it_ordered_quantity     IN  oe_order_lines_all.ordered_quantity%TYPE              --  受注数量
    , it_reason_code          IN  oe_reasons.reason_code%TYPE                           --  事由コード
    , it_request_date         IN  oe_order_lines_all.request_date%TYPE                  --  納品予定日
    , it_subinv_code          IN  oe_order_lines_all.subinventory%TYPE                  --  保管場所
    , ov_errbuf               OUT NOCOPY VARCHAR2                                       --  エラー・メッセージエラー       #固定#
    , ov_retcode              OUT NOCOPY VARCHAR2                                       --  リターン・コード               #固定#
    , ov_errmsg               OUT NOCOPY VARCHAR2                                       --  ユーザー・エラー・メッセージ   #固定#
  );
--
END XXCOS_COMMON3_PKG;
/
