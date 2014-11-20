CREATE OR REPLACE PACKAGE XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(spec)
 * Description      : 運送費予算及び運送費実績を拠点別品目別（単品別）月別にCSVデータ形式で要求出力します。
 * MD.050           : 運送費予算一覧表出力 MD050_COK_023_A03
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
 *  2008/11/10    1.0   SCS T.Taniguchi  main新規作成
 *  2009/03/02    1.1   SCS T.Taniguchi  [障害COK_069] 入力パラメータにより、拠点の取得範囲を制御
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT  VARCHAR2,   --   エラーメッセージ #固定#
    retcode        OUT  VARCHAR2,   --   エラーコード     #固定#
    iv_base_code   IN   VARCHAR2,   -- 1.拠点コード
    iv_budget_year IN   VARCHAR2,   -- 2.予算年度
    iv_resp_type   IN   VARCHAR2    -- 3.職責タイプ
  );
END XXCOK023A03C;
/
