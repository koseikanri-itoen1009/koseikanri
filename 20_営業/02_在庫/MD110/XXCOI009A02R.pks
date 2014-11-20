create or replace PACKAGE XXCOI009A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A02R(spec)
 * Description      : 倉替出庫明細リスト
 * MD.050           : 倉替出庫明細リスト MD050_COI_009_A02
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
 *  2008/12/04    1.0  SCS.Tsuboi         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_transaction_type  IN     VARCHAR2,         --   1.取引タイプ
    iv_year_month        IN     VARCHAR2,         --   2.年月
    iv_day               IN     VARCHAR2,         --   3.日
    iv_out_kyoten        IN     VARCHAR2,         --   4.出庫拠点
    iv_output_dpt        IN     VARCHAR2          --   5.帳票出力場所
  );
END XXCOI009A02R;
/
