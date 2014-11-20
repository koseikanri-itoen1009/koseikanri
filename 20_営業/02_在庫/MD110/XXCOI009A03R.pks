create or replace PACKAGE XXCOI009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A03R(spec)
 * Description      : 工場入庫明細リスト
 * MD.050           : 工場入庫明細リスト MD050_COI_009_A03
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
 *  2008/10/31    1.0  SCS.Tsuboi         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_year_month IN     VARCHAR2,         --   1.年月
    iv_in_kyoten  IN     VARCHAR2,         --   2.入庫拠点
    iv_item_ctgr  IN     VARCHAR2,         --   3.品目カテゴリ
    iv_output_dpt IN     VARCHAR2          --   4.帳票出力場所
  );
END XXCOI009A03R;
/
