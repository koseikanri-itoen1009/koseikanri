CREATE OR REPLACE PACKAGE APPS.XXCOS009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A10C(spec)
 * Description      : 受注一覧＆受注エラーリスト発行
 * MD.050           : MD050_COS_009_A10_受注一覧＆受注エラーリスト発行
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
 *  2012/12/20    1.0   K.Nakamura       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                      OUT VARCHAR2 -- エラーメッセージ #固定#
    , retcode                     OUT VARCHAR2 -- エラーコード     #固定#
    , iv_order_source             IN  VARCHAR2 -- 受注ソース
    , iv_delivery_base_code       IN  VARCHAR2 -- 納品拠点コード
    , iv_output_type              IN  VARCHAR2 -- 出力区分
    , iv_output_quantity_type     IN  VARCHAR2 -- 出力数量区分
    , iv_request_type             IN  VARCHAR2 -- 再発行区分
    , iv_edi_received_date_from   IN  VARCHAR2 -- エラーリスト用EDI受信日(FROM)
    , iv_edi_received_date_to     IN  VARCHAR2 -- エラーリスト用EDI受信日(TO)
  );
END XXCOS009A10C;
/
