CREATE OR REPLACE PACKAGE APPS.XXCFO019A01C
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A01C(spec)
 * Description      : 電子帳簿残高の情報系システム連携
 * MD.050           : MD050_CFO_019_A01_電子帳簿残高の情報系システム連携
 *                    
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
 *  2012-09-26    1.0   K.Onotsuka      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode               OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,iv_ins_upd_kbn        IN         VARCHAR2          -- 追加更新区分
   ,iv_file_name          IN         VARCHAR2          -- ファイル名
   ,iv_period_name_from   IN         VARCHAR2          -- 会計期間(From)
   ,iv_period_name_to     IN         VARCHAR2          -- 会計期間(To)
   ,iv_exec_kbn           IN         VARCHAR2          -- 定期手動区分
  );
END XXCFO019A01C;
/
