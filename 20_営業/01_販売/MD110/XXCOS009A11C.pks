CREATE OR REPLACE PACKAGE APPS.XXCOS009A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A11C (spec)
 * Description      : 受注一覧ファイル出力（EDI用）（本部確認用）
 * MD.050           : 受注一覧ファイル出力 <MD050_COS_009_A11>
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
 * 2012/12/26    1.0   K.Onotsuka      新規作成[E_本稼働_08657対応]
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_chain_code                   IN     VARCHAR2,         --   チェーン店コード
    iv_delivery_base_code           IN     VARCHAR2,         --   納品拠点コード
    iv_order_creation_date_from     IN     VARCHAR2,         --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   納品日(ヘッダ)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   納品日(ヘッダ)(TO)
    iv_order_source                 IN     VARCHAR2          --   受注ソース
  );
END XXCOS009A11C;
/
