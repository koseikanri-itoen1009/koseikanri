CREATE OR REPLACE PACKAGE XXCOI010A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A03C(spec)
 * Description      : VDコラムマスタHHT連携
 * MD.050           : VDコラムマスタHHT連携 MD050_COI_010_A03
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
 *  2008/12/02    1.0   T.Nakamura       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf              OUT    VARCHAR2          --   エラーメッセージ #固定#
    , retcode             OUT    VARCHAR2          --   エラーコード     #固定#
    , iv_night_exec_flag  IN     VARCHAR2          --   夜間実行フラグ
  );
END XXCOI010A03C;
/
