CREATE OR REPLACE PACKAGE APPS.XXCOS009A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A09C (spec)
 * Description      : 受注一覧発行状況CSV出力
 * MD.050           : 受注一覧発行状況CSV出力 MD050_COS_009_A09
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
 *  2012/09/12    1.0   M.Takasaki       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_base_code                    IN     VARCHAR2,         --   拠点コード
    iv_order_list_date_from         IN     VARCHAR2,         --   出力日(FROM)
    iv_order_list_date_to           IN     VARCHAR2          --   出力日(TO)
  );
END XXCOS009A09C;
/
