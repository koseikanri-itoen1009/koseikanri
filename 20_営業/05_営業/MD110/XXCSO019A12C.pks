CREATE OR REPLACE PACKAGE APPS.XXCSO019A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A12C(spec)
 * Description      : ルートNo／営業員CSV出力
 * MD.050           : ルートNo／営業員CSV出力 (MD050_CSO_019A12)
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
 *  2018/02/15    1.0   K.Kiriu          main新規作成（E_本稼動_14722）
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT    VARCHAR2    --   エラーメッセージ #固定#
   ,retcode            OUT    VARCHAR2    --   エラーコード     #固定#
   ,iv_base_code       IN     VARCHAR2    -- 1.拠点コード
   ,iv_employee_number IN     VARCHAR2    -- 2.営業員
   ,iv_route_no        IN     VARCHAR2    -- 3.ルートNo
  );
END XXCSO019A12C;
/
