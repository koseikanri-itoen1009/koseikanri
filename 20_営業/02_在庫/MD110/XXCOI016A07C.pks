CREATE OR REPLACE PACKAGE XXCOI016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI016A07C(spec)
 * Description      : ロット別引当情報をいずれかのステータスにてCSV出力を行います。
 * MD.050           : ロット別出荷情報CSV出力<MD050_COI_016_A07>
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
 *  2014/10/28    1.0   Y.Koh            初版作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- エラー・メッセージ  --# 固定 #
   ,retcode                   OUT VARCHAR2        -- リターン・コード    --# 固定 #
   ,iv_login_base_code        IN  VARCHAR2        -- 1.拠点
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.チェーン店
   ,iv_request_date_from      IN  VARCHAR2        -- 3.着日（From）
   ,iv_request_date_to        IN  VARCHAR2        -- 4.着日（To）
   ,iv_bargain_class          IN  VARCHAR2        -- 5.定番特売区分
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI受信日
   ,iv_shipping_status        IN  VARCHAR2        -- 7.ステータス
   ,iv_order_number           IN  VARCHAR2        -- 8.受注番号
  );
END XXCOI016A07C;
/
