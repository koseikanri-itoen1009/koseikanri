CREATE OR REPLACE PACKAGE APPS.XXCOK024A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A41C (spec)
 * Description      : 支払未連携控除データ出力
 * MD.050           : 支払未連携控除データ出力 MD050_COK_024_A41
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
 *  2022/09/07    1.0   M.Akachi         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_data_type                    IN     VARCHAR2          -- データ種類
   ,iv_record_date_from             IN     VARCHAR2          -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- 計上日(TO)
   ,iv_base_code                    IN     VARCHAR2          -- 本部担当拠点
   ,iv_sale_base_code               IN     VARCHAR2          -- 売上拠点
  );
END XXCOK024A41C;
/
