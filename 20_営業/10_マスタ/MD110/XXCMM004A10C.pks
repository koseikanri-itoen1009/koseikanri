CREATE OR REPLACE PACKAGE XXCMM004A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A10C(spec)
 * Description      : 品目一覧作成
 * MD.050           : 品目一覧作成 MD050_CMM_004_A10
 * Version          : Draft2C
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
 *  2008/12/11    1.0   N.Nishimura      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,    -- エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,    -- エラーコード     #固定#
    iv_output_div        IN     VARCHAR2,    -- 出力対象設定値
    iv_item_status       IN     VARCHAR2,    -- 品目ステータス
    iv_date_from         IN     VARCHAR2,    -- 対象期間開始
    iv_date_to           IN     VARCHAR2,    -- 対象期間終了
    iv_item_code_from    IN     VARCHAR2,    -- 品名コード開始
    iv_item_code_to      IN     VARCHAR2     -- 品名コード終了
  );
END XXCMM004A10C;
/
