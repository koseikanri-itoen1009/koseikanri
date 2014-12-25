CREATE OR REPLACE PACKAGE XXCCP009A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A03C(spec)
 * Description      : 請求書保留ステータス更新処理
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
 *  2014/10/02    1.0   K.Nakatsu       [E_本稼動_11000]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode             OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_exe_mode         IN     VARCHAR2,         --   実行モード
    iv_bill_cust_code   IN     VARCHAR2,         --   請求先顧客
    iv_target_date      IN     VARCHAR2,         --   締日
    iv_business_date    IN     VARCHAR2,         --   業務日付
    iv_request_id       IN     VARCHAR2,         --   要求ID
    iv_status_from      IN     VARCHAR2,         --   更新対象ステータス
    iv_status_to        IN     VARCHAR2          --   更新後ステータス
  );
END XXCCP009A03C;
/
