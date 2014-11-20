CREATE OR REPLACE PACKAGE XXCOS017A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS017A01C(spec)
 * Description      : 補填・実卸単価チェック情報集計
 * MD.050           : 補填・実卸単価チェック情報集計 MD050_COS_017_A01
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
 *  2009/03/17    1.0   T.Nakabayashi    新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                        OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode                       OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_years_for_total            IN      VARCHAR2,         --  1.集計対象年月
    iv_processing_class           IN      VARCHAR2,         --  2.処理区分
    iv_item_code                  IN      VARCHAR2,         --  3.品目コード
    iv_real_wholesale_unit_price  IN      VARCHAR2          --  4.実卸単価
  );
END XXCOS017A01C;
/
