CREATE OR REPLACE PACKAGE APPS.XXCOS009A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A08C (spec)
 * Description      : 汎用エラーリスト
 * MD.050           : 汎用エラーリスト MD050_COS_009_A08
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
 *  2010/09/02    1.0   T.Ishiwata       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_base_code                    IN     VARCHAR2,         --   拠点コード
    iv_process_date                 IN     VARCHAR2,         --   処理日付
    iv_conc_name                    IN     VARCHAR2          --   機能名
  );
END XXCOS009A08C;
/
