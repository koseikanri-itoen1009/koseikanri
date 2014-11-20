CREATE OR REPLACE PACKAGE APPS.XXCOP004A10R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A10R(spec)
 * Description      : 引取計画実績対比表
 * MD.050           : MD050_COP_004_A10_引取計画実績対比表
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
 *  2013/11/18    1.0   S.Niki            main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf    OUT VARCHAR2  -- エラーメッセージ #固定#
    , retcode   OUT VARCHAR2  -- エラーコード     #固定#
    , iv_target_month      IN  VARCHAR2         -- 1.対象年月
    , iv_forecast_type     IN  VARCHAR2         -- 2.計画区分
    , iv_prod_class_code   IN  VARCHAR2         -- 3.商品区分
    , iv_base_code         IN  VARCHAR2         -- 4.拠点
    , iv_crowd_class_code  IN  VARCHAR2         -- 5.政策群コード
    , iv_item_code         IN  VARCHAR2         -- 6.品目コード
  );
END XXCOP004A10R;
/
