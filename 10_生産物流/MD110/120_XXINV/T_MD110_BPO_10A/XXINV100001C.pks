CREATE OR REPLACE PACKAGE XXINV100001C AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100001C(spec)
 * Description      : 生産物流(計画)
 * MD.050           : 計画・移動・在庫・販売計画/引取計画 T_MD050_BPO100
 * MD.070           : 計画・移動・在庫・販売計画/引取計画 T_MD070_BPO10A
 * Version          : 1.3
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
 *  2008/01/11   1.0   Oracle 土田 茂   初回作成
 *  2008/04/21   1.1  Oracle 土田 茂   内部変更要求 No27 対応
 *  2008/04/24   1.2  Oracle 土田 茂   内部変更要求 No27修正, No72 対応
 *  2008/05/01   1.3  Oracle 土田 茂   結合テスト時の不具合対応
 *  2008/05/26   1.4  Oracle 熊本 和郎 結合テスト障害対応(I/F削除後のコミット追加)
 *  2008/05/26   1.5  Oracle 熊本 和郎 結合テスト障害対応(エラー件数、スキップ件数の算出方法変更)
 *  2008/05/26   1.6  Oracle 熊本 和郎 規約違反(varchar使用)対応
 *  2008/05/29   1.7  Oracle 熊本 和郎 結合テスト障害対応(販売計画のMD050.機能フローとロジックの不一致修正)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT NOCOPY VARCHAR2,   -- エラーメッセージ #固定#
    retcode                OUT NOCOPY VARCHAR2,   -- エラーコード     #固定#
    iv_forecast_designator IN         VARCHAR2,   -- Forecast区分
    iv_forecast_yyyymm     IN         VARCHAR2,   -- 年月
    iv_forecast_year       IN         VARCHAR2,   -- 年度
    iv_forecast_version    IN         VARCHAR2,   -- 世代
    iv_forecast_date       IN         VARCHAR2,   -- 開始日付
    iv_forecast_end_date   IN         VARCHAR2,   -- 終了日付
    iv_item_no             IN         VARCHAR2,   -- 品目
    iv_location_code       IN         VARCHAR2,   -- 出庫倉庫
    iv_account_number      IN         VARCHAR2,   -- 拠点
    iv_dept_code           IN         VARCHAR2    -- 取込部署
  );
END XXINV100001C;
/
