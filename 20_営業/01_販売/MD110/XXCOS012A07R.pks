CREATE OR REPLACE PACKAGE APPS.XXCOS012A07R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A07R(Spec)
 * Description      : ロット別ピックリスト（出荷先・製品・販売先別）
 * MD.050           : MD050_COS_012_A07_ロット別ピックリスト（出荷先・製品・販売先別）
 * Version          : 1.1
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
 *  2014/10/06    1.0   S.Itou           新規作成
 *  2015/04/10    1.1   S.Yamashita     【E_本稼動_13004】対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2     -- エラーメッセージ #固定#
   ,retcode                   OUT     VARCHAR2     -- エラーコード     #固定#
   ,iv_login_base_code        IN      VARCHAR2     -- 1.拠点
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.チェーン店
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN      VARCHAR2     -- 3.顧客
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN      VARCHAR2     -- 4.着日（From）
   ,iv_request_date_to        IN      VARCHAR2     -- 5.着日（To）
   ,iv_bargain_class          IN      VARCHAR2     -- 6.定番特売区分
   ,iv_edi_received_date      IN      VARCHAR2     -- 7.EDI受信日
   ,iv_shipping_status        IN      VARCHAR2     -- 8.ステータス
   ,iv_order_number           IN      VARCHAR2     -- 9.受注番号
  );
END XXCOS012A07R;
/
