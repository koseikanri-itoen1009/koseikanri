CREATE OR REPLACE PACKAGE APPS.XXCOI016A99C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A99C(spec)
 * Description      : ロット別出荷情報作成_移行用
 * MD.050           : -
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/05/12    1.0   S.Yamashita       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                    OUT VARCHAR2 -- エラーメッセージ #固定#
    , retcode                   OUT VARCHAR2 -- エラーコード     #固定#
    , iv_login_base_code        IN  VARCHAR2 -- 拠点
    , iv_delivery_date_from     IN  VARCHAR2 -- 着日From
    , iv_delivery_date_to       IN  VARCHAR2 -- 着日To
    , iv_login_chain_store_code IN  VARCHAR2 -- チェーン店
    , iv_login_customer_code    IN  VARCHAR2 -- 顧客
    , iv_customer_po_number     IN  VARCHAR2 -- 顧客発注番号
    , iv_subinventory_code      IN  VARCHAR2 -- 保管場所
    , iv_priority_flag          IN  VARCHAR2 -- 優先ロケーション使用
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ロット逆転可否
    , iv_kbn                    IN  VARCHAR2 -- 判定区分
  );
END XXCOI016A99C;
/
