CREATE OR REPLACE PACKAGE XXCOI006A15R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A15R(spec)
 * Description      : 倉庫毎に日次または月中、月末の受払残高情報を受払残高表に出力します。
 *                    預け先毎に月末の受払残高情報を受払残高表に出力します。
 * MD.050           : 受払残高表(倉庫・預け先)    MD050_COI_006_A15
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
 *  2008/12/18    1.0   Sai.u            main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- エラーメッセージ #固定#
    retcode            OUT VARCHAR2,     -- エラーコード     #固定#
    iv_output_kbn      IN  VARCHAR2,     -- 出力区分
    iv_inventory_kbn   IN  VARCHAR2,     -- 棚卸区分
    iv_inventory_date  IN  VARCHAR2,     -- 棚卸日
    iv_inventory_month IN  VARCHAR2,     -- 棚卸月
    iv_base_code       IN  VARCHAR2,     -- 拠点
    iv_warehouse       IN  VARCHAR2,     -- 倉庫
    iv_left_base       IN  VARCHAR2      -- 預け先
  );
END XXCOI006A15R;
/
