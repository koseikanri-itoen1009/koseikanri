CREATE OR REPLACE PACKAGE XXCMM005A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A04C(spec)
 * Description      : 所属マスタIF出力（自販機管理）
 * MD.050           : 所属マスタIF出力（自販機管理） MD050_CMM_005_A04
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
 *  2009/02/12    1.0   Masayuki.Sano    新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2,        --   エラーコード     #固定#
    iv_update_from        IN     VARCHAR2,        --   1.最終更新日(FROM)
    iv_update_to          IN     VARCHAR2         --   2.最終更新日(TO)
  );
END XXCMM005A04C;
/
