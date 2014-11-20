create or replace PACKAGE XXCOI002A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI002A04R(spec)
 * Description      : 製品廃却伝票
 * MD.050           : 製品廃却伝票 MD050_COI_002_A04
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
 *  2012/09/05    1.0   K.Furuyama       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode              OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_year_month        IN     VARCHAR2,         --   1.年月
    iv_day               IN     VARCHAR2,         --   2.日
    iv_kyoten            IN     VARCHAR2,         --   3.拠点
    iv_output_dpt        IN     VARCHAR2          --   4.帳票出力場所
  );
END XXCOI002A04R;
/
