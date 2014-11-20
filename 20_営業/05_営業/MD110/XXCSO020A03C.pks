CREATE OR REPLACE PACKAGE APPS.XXCSO020A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A03C(spec)
 * Description      : フルベンダー用ＳＰ専決・登録画面によって登録された新規顧客情報を顧客
 *                    マスタ、契約先マスタに登録します。また、フルベンダー用ＳＰ専決・登録
 *                    画面にて変更された既存顧客情報を顧客マスタに反映します。
 * MD.050           : MD050_CSO_020_A03_各種マスタ反映処理機能
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuo.Satomura   新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
  --
  --実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2                                             -- エラーメッセージ #固定#
   ,retcode                  OUT NOCOPY VARCHAR2                                             -- エラーコード     #固定#
   ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- ＳＰ専決ヘッダＩＤ
   ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- 顧客ＩＤ
   ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- 契約先ＩＤ
  );
  --
END XXCSO020A03C;
/
