create or replace PACKAGE XXCOI006A14R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A14C(spec)
 * Description      : 受払残高表（営業員）
 * MD.050           : 受払残高表（営業員） <MD050_COI_A14>
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
 *  2008/12/24    1.0   N.Abe            新規作成
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
    iv_base_code       IN  VARCHAR2,     -- 拠点
    iv_business        IN  VARCHAR2      -- 営業員
  );
END XXCOI006A14R;
/
