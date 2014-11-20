CREATE OR REPLACE PACKAGE XXCSM004A05C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A05C(spec)
 * Description      : 資格ポイント・新規獲得ポイント情報系システムI/F
 * MD.050           : 資格ポイント・新規獲得ポイント情報系システムI/F MD050_CSM_004_A05
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  main                【コンカレント実行ファイル登録プロシージャ】
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.son        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT    NOCOPY VARCHAR2,         --   エラーメッセージ
    retcode                OUT    NOCOPY VARCHAR2          --   エラーコード
  );
END XXCSM004A05C;
/
