CREATE OR REPLACE PACKAGE xxwip210001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip210001c(spec)
 * Description      : 生産バッチ一括クローズ処理
 * MD.050           : 生産クローズ T_MD050_BPO_210
 * MD.070           : 生産バッチ一括クローズ処理(21A) T_MD070_BPO_21A
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
 *  2007/11/12    1.0   H.Itou           main 新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode              OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_product_date_from IN  VARCHAR2,      -- 1.生産日（FROM）
    iv_product_date_to   IN  VARCHAR2,      -- 2.生産日（TO）
    iv_plant_code        IN  VARCHAR2       -- 3.プラントコード
  );
--
END xxwip210001c;
/
