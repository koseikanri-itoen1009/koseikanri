CREATE OR REPLACE PACKAGE APPS.XXCCP007A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP007A08C(spec)
 * Description      : 経費精算発生事由データ出力
 * MD.070           : 経費精算発生事由データ出力 (MD070_IPO_CCP_007_A08)
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
 *  2015/11/09     1.0  Y.Shoji         [E_本稼動_13393]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode               OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_gl_date_from       IN     VARCHAR2      --    1.GL記帳日 FROM
   ,iv_gl_date_to         IN     VARCHAR2      --    2.GL記帳日 TO
   ,iv_department_code    IN     VARCHAR2      --    3.部門コード
   ,iv_segment3_code1     IN     VARCHAR2      --    4.経費科目コード１
   ,iv_segment3_code2     IN     VARCHAR2      --    5.経費科目コード２
   ,iv_segment3_code3     IN     VARCHAR2      --    6.経費科目コード３
   ,iv_segment3_code4     IN     VARCHAR2      --    7.経費科目コード４
   ,iv_segment3_code5     IN     VARCHAR2      --    8.経費科目コード５
   ,iv_segment3_code6     IN     VARCHAR2      --    9.経費科目コード６
   ,iv_segment3_code7     IN     VARCHAR2      --   10.経費科目コード７
   ,iv_segment3_code8     IN     VARCHAR2      --   11.経費科目コード８
   ,iv_segment3_code9     IN     VARCHAR2      --   12.経費科目コード９
   ,iv_segment3_code10    IN     VARCHAR2      --   13.経費科目コード１０
  );
END XXCCP007A08C;
/