CREATE OR REPLACE PACKAGE XXCMM003A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A28C(spec)
 * Description      : 顧客一括更新用ＣＳＶダウンロード
 * MD.050           : MD050_CMM_003_A28_顧客一括更新用CSVダウンロード
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
 *  2009/01/07    1.0   中村 祐基        新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ（顧客一括更新用ＣＳＶダウンロード）
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --エラーメッセージ #固定#
    retcode                   OUT    VARCHAR2,     --エラーコード     #固定#
    iv_customer_class         IN     VARCHAR2,     --顧客区分
    iv_ar_invoice_grp_code    IN     VARCHAR2,     --売掛コード１（請求書）
    iv_ar_location_code       IN     VARCHAR2,     --売掛コード２（事業所）
    iv_ar_others_code         IN     VARCHAR2,     --売掛コード３（その他）
    iv_kigyou_code            IN     VARCHAR2,     --企業コード
    iv_sales_chain_code       IN     VARCHAR2,     --チェーン店コード（販売先）
    iv_delivery_chain_code    IN     VARCHAR2,     --チェーン店コード（納品先）
    iv_policy_chain_code      IN     VARCHAR2,     --チェーン店コード（政策用）
    iv_chain_store_edi        IN     VARCHAR2,     --チェーン店コード（ＥＤＩ）
    iv_gyotai_sho             IN     VARCHAR2,     --業態（小分類）
    iv_chiku_code             IN     VARCHAR2      --地区コード
  );
END XXCMM003A28C;
/
