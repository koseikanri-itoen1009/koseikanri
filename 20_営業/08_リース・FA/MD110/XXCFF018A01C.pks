CREATE OR REPLACE PACKAGE APPS.XXCFF018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF018A01C (spec)
 * Description      : 償却シミュレーション結果リスト
 * MD.050           : 償却シミュレーション結果リスト (MD050_CFF_018_A01)
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
 *  2014-12-18    1.0   K.Kanada         新規作成  E_本稼動_08122対応
 *  2024-02-09    1.1   Y.Sato           E_本稼動_19496対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2      -- エラーコード     #固定#
   ,iv_whatif_request_id            IN     VARCHAR2      -- 1.WHATIFリクエストID
   ,iv_period_date                  IN     VARCHAR2      -- 2.開始期間
   ,iv_num_periods                  IN     VARCHAR2      -- 3.期間数
-- Ver1.1 Add Start
   ,iv_owner_company                IN     VARCHAR2      -- 4.本社工場区分
-- Ver1.1 Add end
  );
END XXCFF018A01C;
/
