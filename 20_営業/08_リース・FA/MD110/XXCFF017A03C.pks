CREATE OR REPLACE PACKAGE XXCFF017A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A03(spec)
 * Description      : 自販機情報FA連携処理リース(FA)
 * MD.050           : MD050_CFF_017_A03_自販機情報FA連携処理
 * Version          : 1.00
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
 *  2014/06/11    1.00  SCSK小路         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode        OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_period_name IN     VARCHAR2          -- 1.会計期間名
  );
END XXCFF017A03C;
/
