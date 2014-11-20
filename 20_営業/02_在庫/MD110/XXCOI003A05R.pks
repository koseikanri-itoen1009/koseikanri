create or replace PACKAGE XXCOI003A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A05R(spec)
 * Description      : 入庫差異確認リスト
 * MD.050           : 入庫差異確認リスト MD050_COI_003_A05
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
 *  2009/01/20    1.0  SCS.Tsuboi         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_target_date       IN     VARCHAR2,         --   1.対象年月
    iv_base_code         IN     VARCHAR2,         --   2.拠点
    iv_output_standard   IN     VARCHAR2,         --   3.出力基準
    iv_output_term       IN     VARCHAR2          --   4.出力条件
  );
END XXCOI003A05R;
/
