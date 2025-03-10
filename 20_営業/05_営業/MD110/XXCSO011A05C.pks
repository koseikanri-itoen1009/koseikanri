CREATE OR REPLACE PACKAGE APPS.XXCSO011A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A05C (spec)
 * Description      : 通信モデム設置可／不可変更処理
 * MD.050           : 通信モデム設置可／不可変更処理 (MD050_CSO_011A05)
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
 *  2015/06/22    1.0   S.Yamashita      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode         OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_cust_code    IN     VARCHAR2      -- 1.顧客コード
   ,iv_install_code IN     VARCHAR2      -- 2.引揚物件コード
   ,iv_kbn          IN     VARCHAR2      -- 3.判定区分
  );
END XXCSO011A05C;
/
