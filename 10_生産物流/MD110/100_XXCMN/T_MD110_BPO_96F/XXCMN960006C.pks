CREATE OR REPLACE PACKAGE XXCMN960006C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMN960006C(spec)
 * Description      : 移動指示パージ
 * MD.050           : T_MD050_BPO_96F_移動指示パージ
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
 *  2012/11/09   1.00  Hiroshi.Ogawa     新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_proc_date  IN     VARCHAR2          --   1.処理日
  );
END XXCMN960006C;
/
