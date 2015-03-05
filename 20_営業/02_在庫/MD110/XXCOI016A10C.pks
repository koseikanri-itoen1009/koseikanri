CREATE OR REPLACE PACKAGE XXCOI016A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A10C(spec)
 * Description      : ロット別受払データ作成(月次)
 * MD.050           : MD050_COI_016_A10_ロット別受払データ作成(月次).doc
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
 *  2014/10/27    1.0   Y.Nagasue        main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT VARCHAR2 -- エラーメッセージ #固定#
   ,retcode              OUT VARCHAR2 -- エラーコード     #固定#
   ,iv_login_base_code   IN  VARCHAR2 -- 拠点コード
   ,iv_subinventory_code IN  VARCHAR2 -- 保管場所コード
   ,iv_startup_flg       IN  VARCHAR2 -- 起動フラグ
  );
END XXCOI016A10C;
/
