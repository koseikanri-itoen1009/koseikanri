CREATE OR REPLACE PACKAGE XXCOK023A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A04C(spec)
 * Description      : 運送費実績情報と運送費予算情報を集計し、運送費管理表(速報)をCSV形式で作成します。
 * MD.050           : 運送費管理表出力 MD050_COK_023_A04
 * Version          : 1.1
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
 *  2008/12/03    1.0   SCS T.Taniguchi  main新規作成
 *  2009/03/02    1.1   SCS T.Taniguchi  [障害COK_070] 入力パラメータにより、拠点の取得範囲を制御
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT VARCHAR2,   -- エラーメッセージ #固定#
    retcode         OUT VARCHAR2,   -- エラーコード     #固定#
    iv_base_code    IN  VARCHAR2,   -- 1.拠点コード
    iv_budget_year  IN  VARCHAR2,   -- 2.年度
    iv_budget_month IN  VARCHAR2,   -- 3.月
    iv_resp_type    IN  VARCHAR2    -- 4.職責タイプ
  );
END XXCOK023A04C;
/
