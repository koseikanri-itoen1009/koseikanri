create or replace
PACKAGE XXCFF016A36C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A36C(spec)
 * Description      : リース契約明細メンテナンス
 * MD.050           : MD050_CFF_016_A36_リース契約明細メンテナンス.
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
 *  2012/10/12    1.0   SCSK 古山         新規作成
 *  2013/07/11    1.1   SCSK 中村         E_本稼動_10871 消費税対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT   VARCHAR2,   --   エラーメッセージ #固定#
    retcode                   OUT   VARCHAR2,   --   エラーコード     #固定#
    iv_object_code            IN    VARCHAR2,   --   1.物件コード
    iv_contract_number        IN    VARCHAR2,   --   2.契約番号
    iv_update_reason          IN    VARCHAR2,   --   3.更新事由
    iv_first_charge           IN    VARCHAR2,   --   4.初回リース料
    iv_second_charge          IN    VARCHAR2,   --   5.2回目以降のリース料
    iv_first_tax_charge       IN    VARCHAR2,   --   6.初回消費税
    iv_second_tax_charge      IN    VARCHAR2,   --   7.2回目以降の消費税
-- Mod 2013/07/11 Ver.1.1 Start
--    iv_estimated_cash_price   IN    VARCHAR2    --   8.見積現金購入価額
    iv_estimated_cash_price   IN    VARCHAR2,   --   8.見積現金購入価額
    iv_tax_code               IN    VARCHAR2    --   9.税金コード
-- Mod 2013/07/11 Ver.1.1 End
  );
END XXCFF016A36C;
/
