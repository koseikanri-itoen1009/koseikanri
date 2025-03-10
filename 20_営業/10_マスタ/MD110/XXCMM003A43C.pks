CREATE OR REPLACE PACKAGE APPS.XXCMM003A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM003A43C(spec)
 * Description      : 店舗情報マスタ連携（eSM）
 * MD.050           : 店舗情報マスタ連携（eSM） MD050_CMM_003_A43
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
 *  2017/02/07    1.0   S.Yamashita      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode         OUT    VARCHAR2         --   エラーコード     #固定#
   ,iv_update_from  IN     VARCHAR2         --   1.最終更新日（開始）
   ,iv_update_to    IN     VARCHAR2         --   2.最終更新日（終了）
  );
END XXCMM003A43C;
/
