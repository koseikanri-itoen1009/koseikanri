CREATE OR REPLACE PACKAGE APPS.XXCSO019A14R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A14R(spec)
 * Description      :  顧客総合管理表
 * MD.050           : MD050_CSO_019_A14_顧客総合管理表
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
 *  2018/05/31    1.0   K.Kiriu          新規作成(E_本稼動_14971)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT NOCOPY VARCHAR2  --   エラーメッセージ #固定#
   ,retcode            OUT NOCOPY VARCHAR2  --   エラーコード     #固定#
   ,iv_base_code       IN  VARCHAR2         --   拠点コード
   ,iv_target_yyyymm   IN  VARCHAR2         --   対象年月
   ,iv_employee_number IN  VARCHAR2         --   従業員コード
  );
END XXCSO019A14R;
/
