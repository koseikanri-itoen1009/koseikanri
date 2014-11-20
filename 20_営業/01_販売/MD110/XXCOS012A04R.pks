CREATE OR REPLACE PACKAGE APPS.XXCOS012A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS012A04R (spec)
 * Description      : ピックリスト（出荷元保管場所・商品別）
 * MD.050           : ピックリスト（出荷元保管場所・商品別） MD050_COS_012_A04
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
 * 2013/07/02    1.0   K.Kiriu          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2,         --   エラーメッセージ #固定#
    retcode                   OUT     VARCHAR2,         --   エラーコード     #固定#
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_subinventory           IN      VARCHAR2,         -- 2.出荷元保管場所
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2,         -- 4.着日（To）
    iv_bargain_class          IN      VARCHAR2,         -- 5.定番特売区分
    iv_sales_output_type      IN      VARCHAR2,         -- 6.売上対象区分
    iv_edi_received_date      IN      VARCHAR2)         -- 7.EDI受信日
 ;
END XXCOS012A04R;
/
