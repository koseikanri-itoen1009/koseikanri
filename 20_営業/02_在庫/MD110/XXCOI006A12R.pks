CREATE OR REPLACE PACKAGE XXCOI006A12R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A12R(spec)
 * Description      : パラメータで入力された年月およびテナント（ＨＨＴ運用なしの保管場所）
 *                    を元に月次在庫受払表に存在する品目及び、手持ち数量に存在する品目の一
 *                    覧を作成します。
 * MD.050           : 商品実地棚卸票    MD050_COI_006_A12
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
 *  2008/12/15    1.0   Sai.u            main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT VARCHAR2,     -- エラーメッセージ #固定#
    retcode            OUT VARCHAR2,     -- エラーコード     #固定#
    iv_practice_month  IN  VARCHAR2,     -- 年月
    iv_tenant          IN  VARCHAR2      -- テナント
  );
END XXCOI006A12R;
/
