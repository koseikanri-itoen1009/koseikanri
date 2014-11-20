CREATE OR REPLACE PACKAGE XXCFO019A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A11C(spec)
 * Description      : 電子帳簿資産管理の情報系システム連携
 * MD.050           : 電子帳簿資産管理の情報系システム連携<MD050_CFO_019_A11>
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
 *  2012-09-20    1.0   N.Sugiura      新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                  OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_ins_upd_kbn           IN     VARCHAR2,         -- 1.追加更新区分
    iv_file_name             IN     VARCHAR2,         -- 2.ファイル名
    iv_period_name           IN     VARCHAR2,         -- 3.会計期間
    iv_exec_kbn              IN     VARCHAR2          -- 4.定期手動区分
  );
END XXCFO019A11C;
/
