CREATE OR REPLACE PACKAGE XXCOP004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A03C(spec)
 * Description      : 引取計画集計
 * MD.050           : 引取計画集計 MD050_COP_004_A03
 * Version          : 1.2
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
 *  2008/11/03    1.0  SCS.Kikuchi       main新規作成
 *  2009/02/13    1.1  SCS.Kikuchi       結合テスト仕様変更（結合障害No.008,009）
 *  2009/04/07    1.2  SCS.Kikuchi       T1_0271対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                        OUT VARCHAR2         --   エラーメッセージ #固定#
    ,retcode                       OUT VARCHAR2         --   エラーコード     #固定#
    ,iv_base_code                  IN  VARCHAR2         -- 1.拠点
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.商品区分
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.実績収集期間（自）
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.実績収集期間（至）
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.計画収集期間（自）
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.計画収集期間（至）
   );

END XXCOP004A03C;
/
