CREATE OR REPLACE PACKAGE XXCFR009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR009A01C(spec)
 * Description      : 営業員別払日別入金予定表
 * MD.050           : MD050_CFR_009_A01_営業員別払日別入金予定表
 * MD.070           : MD050_CFR_009_A01_営業員別払日別入金予定表
 * Version          : 1.00
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
 *  2008/11/17    1.00 SCS 中村 博      初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         --    エラーメッセージ #固定#
    retcode                OUT     VARCHAR2,         --    エラーコード     #固定#
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_receive_base_code   IN      VARCHAR2,         --    入金拠点
    iv_sales_rep           IN      VARCHAR2,         --    営業担当者
    iv_due_date_from       IN      VARCHAR2,         --    支払期日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払期日(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    入金区分１
    iv_receipt_class2      IN      VARCHAR2,         --    入金区分２
    iv_receipt_class3      IN      VARCHAR2,         --    入金区分３
    iv_receipt_class4      IN      VARCHAR2,         --    入金区分４
    iv_receipt_class5      IN      VARCHAR2          --    入金区分５
  );
END XXCFR009A01C;--(変更)
/
