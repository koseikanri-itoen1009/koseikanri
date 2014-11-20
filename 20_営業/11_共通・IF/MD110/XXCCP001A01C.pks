CREATE OR REPLACE PACKAGE APPS.XXCCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP001A01C(spec)
 * Description      : 業務日付照会更新
 * MD.050           : MD050_CCP_001_A01_業務日付更新照会
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  con_get_process_date   業務日付照会処理(A-2)
 *  update_process_date    業務日付更新処理(A-3)
 *  insert_process_date    業務日付登録処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(後処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.00  渡辺直樹         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,         --   エラーコード     #固定#
    iv_handle_area   IN    VARCHAR2,         --   処理区分
    iv_process_date  IN    VARCHAR2          --   業務日付
  );
END XXCCP001A01C;
/
