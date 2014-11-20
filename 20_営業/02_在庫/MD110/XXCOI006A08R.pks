CREATE OR REPLACE PACKAGE XXCOI006A08R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A08R(spec)
 * Description      : 要求の発行画面から、品目毎の明細および棚卸数量を帳票に出力します。
 *                    帳票に出力した棚卸結果データには処理済フラグ"Y"を設定します。
 * MD.050           : 棚卸チェックリスト    MD050_COI_006_A08
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
 *  2008/11/10    1.0   Sai.u            main新規作成
 *  2009/04/30    1.1   T.Nakamura       [障害T1_0877] 最終行にバックスラッシュを追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- エラーメッセージ #固定#
    retcode            OUT VARCHAR2,     -- エラーコード     #固定#
    iv_inventory_kbn   IN  VARCHAR2,     -- 棚卸区分
    iv_practice_date   IN  VARCHAR2,     -- 年月日
    iv_practice_month  IN  VARCHAR2,     -- 年月
    iv_base_code       IN  VARCHAR2,     -- 拠点
    iv_inventory_place IN  VARCHAR2,     -- 棚卸場所
    iv_output_kbn      IN  VARCHAR2      -- 出力区分
  );
END XXCOI006A08R;
/
