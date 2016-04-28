CREATE OR REPLACE PACKAGE APPS.XXCOS009A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A12C (spec)
 * Description      : 納品確定データダウンロード
 * MD.050           : 納品確定データダウンロード <MD050_COS_009_A12>
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
 *  2016/03/14    1.0   S.Yamashita      新規作成[E_本稼働_13436対応]
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2         --   エラーコード     #固定#
   ,iv_chain_code                   IN     VARCHAR2         --   チェーン店コード
   ,iv_delivery_base_code           IN     VARCHAR2         --   納品拠点コード
   ,iv_received_date_from           IN     VARCHAR2         --   受信日(FROM)
   ,iv_received_date_to             IN     VARCHAR2         --   受信日(TO)
   ,iv_delivery_date_from           IN     VARCHAR2         --   納品日(ヘッダ)(FROM)
   ,iv_delivery_date_to             IN     VARCHAR2         --   納品日(ヘッダ)(TO)
  );
END XXCOS009A12C;
/
