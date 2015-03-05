CREATE OR REPLACE PACKAGE APPS.XXCOS012A05R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A05R(Spec)
 * Description      : ロット別ピックリスト（チェーン・製品別トータル）
 * MD.050           : MD050_COS_012_A05_ロット別ピックリスト（チェーン・製品別トータル）
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/07    1.0   S.Itou           新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2     -- エラーメッセージ #固定#
   ,retcode                   OUT     VARCHAR2     -- エラーコード     #固定#
   ,iv_login_base_code        IN      VARCHAR2     -- 1.拠点
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.チェーン店
   ,iv_request_date_from      IN      VARCHAR2     -- 3.着日（From）
   ,iv_request_date_to        IN      VARCHAR2     -- 4.着日（To）
   ,iv_bargain_class          IN      VARCHAR2     -- 5.定番特売区分
   ,iv_edi_received_date      IN      VARCHAR2     -- 6.EDI受信日
   ,iv_shipping_status        IN      VARCHAR2     -- 7.ステータス
   ,iv_order_number           IN      VARCHAR2     -- 8.受注番号
  );
END XXCOS012A05R;
/
