CREATE OR REPLACE PACKAGE XXCCP009A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A06C(spec)
 * Description      : GL仕訳（ARカテゴリ別サマリー）取得
 * MD.070           : GL仕訳（ARカテゴリ別サマリー）取得 (MD070_IPO_CCP_009_A06)
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
 *  2014/12/16     1.0  SCSK K.Nakatsu   [E_本稼動_12777]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_period_name  IN     VARCHAR2          --   会計期間
  );
END XXCCP009A06C;
/
