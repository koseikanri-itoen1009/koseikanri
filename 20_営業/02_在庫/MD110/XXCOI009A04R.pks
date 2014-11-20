create or replace PACKAGE XXCOI009A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A04R(spec)
 * Description      : 入出庫ジャーナルチェックリスト
 * MD.050           : 入出庫ジャーナルチェックリスト MD050_COI_009_A04
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
 *  2008/12/22    1.0  SCS.Tsuboi         main新規作成
 *  2009/12/15    1.1  H.Sasaki           [E_本稼動_00256]起動パラメータの年月日From-Toを設定
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_output_kbn        IN     VARCHAR2,         --   1.出力区分
    iv_invoice_kbn       IN     VARCHAR2,         --   2.伝票区分
    iv_target_date       IN     VARCHAR2,         --   3.年月日
-- == 2009/12/15 V1.1 Added START ===============================================================
    iv_target_date_to    IN     VARCHAR2,         --   年月日（TO）
-- == 2009/12/15 V1.1 Added END   ===============================================================
    iv_out_base_code     IN     VARCHAR2,         --   4.拠点
    iv_reverse_kbn       IN     VARCHAR2,         --   5.入出庫逆転データ出力区分
    iv_output_dpt        IN     VARCHAR2          --   6.帳票出力場所
  );
END XXCOI009A04R;
/
