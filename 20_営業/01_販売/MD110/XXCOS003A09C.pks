CREATE OR REPLACE PACKAGE APPS.XXCOS003A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A09C (spec)
 * Description      : 特売価格表データダウンロード
 * MD.050           : 特売価格表データダウンロード <MD050_COS_003_A09>
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
 *  2016/04/05    1.0   S.Niki           新規作成[E_本稼働_14024対応]
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode                OUT    VARCHAR2         --   エラーコード     #固定#
   ,iv_base_code           IN     VARCHAR2         --   拠点コード
   ,iv_customer_code       IN     VARCHAR2         --   顧客コード
   ,iv_item_code           IN     VARCHAR2         --   品目コード
   ,iv_date_from           IN     VARCHAR2         --   期間(FROM)
   ,iv_date_to             IN     VARCHAR2         --   期間(TO)
  );
END XXCOS003A09C;
/
