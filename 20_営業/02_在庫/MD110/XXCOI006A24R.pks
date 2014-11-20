CREATE OR REPLACE PACKAGE XXCOI006A24R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI006A24R(spec)
 * Description      : 受払残高表（営業員別計）
 * MD.050           : 受払残高表（営業員別計） <MD050_COI_A24>
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
 *  2014/03/17    1.0   SCSK 中野        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- エラーメッセージ #固定#
    retcode            OUT VARCHAR2,     -- エラーコード     #固定#
    iv_inventory_kbn   IN  VARCHAR2,     -- 棚卸区分
    iv_inventory_date  IN  VARCHAR2,     -- 棚卸日
    iv_inventory_month IN  VARCHAR2,     -- 棚卸月
    iv_base_code       IN  VARCHAR2      -- 拠点
  );
END XXCOI006A24R;
/
