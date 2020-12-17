CREATE OR REPLACE PACKAGE xxcok_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : xxcok_common2_pkg(spec)
 * Description      : 個別開発領域・共通関数
 * MD.070           : MD070_IPO_COK_共通関数
 * Version          : 1.1
 *
 * Program List
 * --------------------------   ------------------------------------------------------------
 *  Name                         Description
 * --------------------------   ------------------------------------------------------------
 *  calculate_deduction_amount_p 控除額算出
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/01/08    1.0   SCSK Y.Koh       [E_本稼動_16026] 収益認識 (新規作成)
 *  2020/12/04    1.1   SCSK Y.Koh       [E_本稼動_16026]
 *  
 *****************************************************************************************/
  -- ===============================
  -- グローバル型
  -- ===============================

  --共通関数プロシージャ・控除額算出
  PROCEDURE calculate_deduction_amount_p(
    ov_errbuf                           OUT VARCHAR2        -- エラーバッファ
  , ov_retcode                          OUT VARCHAR2        -- リターンコード
  , ov_errmsg                           OUT VARCHAR2        -- エラーメッセージ
  , iv_item_code                        IN  VARCHAR2        -- 品目コード
  , iv_sales_uom_code                   IN  VARCHAR2        -- 販売単位
  , in_sales_quantity                   IN  NUMBER          -- 販売数量
  , in_sale_pure_amount                 IN  NUMBER          -- 売上本体金額
  , iv_tax_code_trn                     IN  VARCHAR2        -- 税コード(TRN)
  , in_tax_rate_trn                     IN  NUMBER          -- 税率(TRN)
  , iv_deduction_type                   IN  VARCHAR2        -- 控除タイプ
  , iv_uom_code                         IN  VARCHAR2        -- 単位(条件)
  , iv_target_category                  IN  VARCHAR2        -- 対象区分
  , in_shop_pay_1                       IN  NUMBER          -- 店納(％)
  , in_material_rate_1                  IN  NUMBER          -- 料率(％)
  , in_condition_unit_price_en_2        IN  NUMBER          -- 条件単価２(円)
  , in_accrued_en_3                     IN  NUMBER          -- 未収計３(円)
-- 2020/12/04 Ver1.1 ADD Start
  , in_compensation_en_3                IN  NUMBER          -- 補填(円)
  , in_wholesale_margin_en_3            IN  NUMBER          -- 問屋マージン(円)
-- 2020/12/04 Ver1.1 ADD End
  , in_accrued_en_4                     IN  NUMBER          -- 未収計４(円)
-- 2020/12/04 Ver1.1 ADD Start
  , in_just_condition_en_4              IN  NUMBER          -- 今回条件(円)
  , in_wholesale_adj_margin_en_4        IN  NUMBER          -- 問屋マージン修正(円)
-- 2020/12/04 Ver1.1 ADD End
  , in_condition_unit_price_en_5        IN  NUMBER          -- 条件単価５(円)
  , in_deduction_unit_price_en_6        IN  NUMBER          -- 控除単価(円)
  , iv_tax_code_mst                     IN  VARCHAR2        -- 税コード(MST)
  , in_tax_rate_mst                     IN  NUMBER          -- 税率(MST)
  , ov_deduction_uom_code               OUT VARCHAR2        -- 控除単位
  , on_deduction_unit_price             OUT NUMBER          -- 控除単価
  , on_deduction_quantity               OUT NUMBER          -- 控除数量
  , on_deduction_amount                 OUT NUMBER          -- 控除額
  , on_deduction_tax_amount             OUT NUMBER          -- 控除税額
-- 2020/12/04 Ver1.1 ADD Start
  , on_compensation                     OUT NUMBER          -- 補填
  , on_margin                           OUT NUMBER          -- 問屋マージン
  , on_sales_promotion_expenses         OUT NUMBER          -- 拡売
  , on_margin_reduction                 OUT NUMBER          -- 問屋マージン減額
-- 2020/12/04 Ver1.1 ADD End
  , ov_tax_code                         OUT VARCHAR2        -- 税コード
  , on_tax_rate                         OUT NUMBER          -- 税率
  );

--
END xxcok_common2_pkg;
/
