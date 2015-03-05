CREATE OR REPLACE PACKAGE XXCOI016A11R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A11R(spec)
 * Description      : ロット別受払残高表（倉庫）
 * MD.050           : MD050_COI_016_A11_ロット別受払残高表（倉庫）.doc
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
 *  2014/11/06    1.0   Y.Nagasue        main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT VARCHAR2 -- エラーメッセージ 
   ,retcode              OUT VARCHAR2 -- エラーコード     
   ,iv_exe_type          IN  VARCHAR2 -- 実行区分
   ,iv_target_date       IN  VARCHAR2 -- 対象日
   ,iv_target_month      IN  VARCHAR2 -- 対象月
   ,iv_login_base_code   IN  VARCHAR2 -- 拠点
   ,iv_subinventory_code IN  VARCHAR2 -- 保管場所
  );
END XXCOI016A11R;
/
