CREATE OR REPLACE PACKAGE APPS.XXCFO020A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A06C (spec)
 * Description      : 相良会計仕訳科目マッピング共通機能
 * MD.050           : 相良会計仕訳科目マッピング共通機能 (MD050_CFO_020A06)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 相良会計仕訳科目マッピング共通機能
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/09/26    1.0   T.Kobori         新規作成
 *
 *****************************************************************************************/
--
  --相良会計仕訳科目マッピング共通機能
  PROCEDURE get_siwake_account_title(
    ov_retcode                OUT    VARCHAR2      -- リターンコード
   ,ov_errbuf                 OUT    VARCHAR2      -- エラーメッセージ
   ,ov_errmsg                 OUT    VARCHAR2      -- ユーザー・エラーメッセージ
   ,ov_company_code           OUT    VARCHAR2      -- 1.会社
   ,ov_department_code        OUT    VARCHAR2      -- 2.部門
   ,ov_account_title          OUT    VARCHAR2      -- 3.勘定科目
   ,ov_account_subsidiary     OUT    VARCHAR2      -- 4.補助科目
   ,ov_description            OUT    VARCHAR2      -- 5.摘要
   ,iv_report                 IN     VARCHAR2      -- 6.帳票
   ,iv_class_code             IN     VARCHAR2      -- 7.品目区分
   ,iv_prod_class             IN     VARCHAR2      -- 8.商品区分
   ,iv_reason_code            IN     VARCHAR2      -- 9.事由コード
   ,iv_ptn_siwake             IN     VARCHAR2      -- 10.仕訳パターン
   ,iv_line_no                IN     VARCHAR2      -- 11.行番号
   ,iv_gloif_dr_cr            IN     VARCHAR2      -- 12.借方・貸方
   ,iv_warehouse_code         IN     VARCHAR2      -- 13.倉庫コード
  );
END XXCFO020A06C;
/
