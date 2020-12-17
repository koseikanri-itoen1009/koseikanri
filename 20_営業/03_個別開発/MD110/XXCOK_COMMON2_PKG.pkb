-- 2020/10/15 Ver1.1 ADD Start
-- 2020/10/15 Ver1.1 ADD End

CREATE OR REPLACE PACKAGE BODY xxcok_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : xxcok_common2_pkg(body)
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
  -- ==============================
  -- グローバル定数
  -- ==============================
  --ステータス・コード
  gv_status_normal  CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn    CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error   CONSTANT  VARCHAR2(01)  :=  xxccp_common_pkg.set_status_error;  --異常:2
  --パッケージ名
  cv_pkg_name       CONSTANT  VARCHAR2(30)  :=  'xxcok_common2_pkg';
  --セパレータ
  cv_sepa_period    CONSTANT  VARCHAR2(01)  :=  '.';  -- ピリオド
  cv_sepa_colon     CONSTANT  VARCHAR2(01)  :=  ':';  -- コロン
--

  /**********************************************************************************
   * Procedure Name   : calculate_deduction_amount_p
   * Description      : 控除額算出
   ***********************************************************************************/
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
  )
  IS
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name                 CONSTANT  VARCHAR2(30)  :=  'calculate_deduction_amount_p';         -- プログラム名
    cv_xxcok                    CONSTANT  VARCHAR2(10)  :=  'XXCOK';                                -- アプリケーション短縮名
    cv_no_item_input_msg1       CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10672';                     -- 販売実績項目未設定エラー【販売実績に ITEM が設定されていません。】
    cv_no_item_input_msg2       CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10673';                     -- 控除条件マスタ項目未設定エラー【控除条件に ITEM が設定されていません。】
    cv_invalid_item_msg         CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10674';                     -- 控除条件マスタ設定不備エラー【控除条件の ITEM の値が不正です。】
    cv_conversion_error_msg     CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10675';                     -- 単位換算エラー【単位換算エラーが発生しました。品目と単位の設定を確認してください。】
    cv_message_string_01        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10641';                     -- メッセージ用文字列【品目コード】
    cv_message_string_02        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10653';                     -- メッセージ用文字列【販売単位】
    cv_message_string_03        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10654';                     -- メッセージ用文字列【販売数量】
    cv_message_string_04        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10655';                     -- メッセージ用文字列【売上本体金額】
    cv_message_string_05        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10656';                     -- メッセージ用文字列【税率】
    cv_message_string_06        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10657';                     -- メッセージ用文字列【控除タイプ】
    cv_message_string_07        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10658';                     -- メッセージ用文字列【単位(条件)】
    cv_message_string_08        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10659';                     -- メッセージ用文字列【対象区分】
    cv_message_string_09        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10660';                     -- メッセージ用文字列【店納(％)】
    cv_message_string_10        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10661';                     -- メッセージ用文字列【料率(％)】
    cv_message_string_11        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10662';                     -- メッセージ用文字列【条件単価２(円)】
    cv_message_string_12        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10663';                     -- メッセージ用文字列【未収計３(円)】
    cv_message_string_13        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10664';                     -- メッセージ用文字列【未収計４(円)】
    cv_message_string_14        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10665';                     -- メッセージ用文字列【条件単価５(円)】
    cv_message_string_15        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10666';                     -- メッセージ用文字列【控除単価(円)】
    cv_message_string_16        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10707';                     -- メッセージ用文字列【税コード】
-- 2020/12/04 Ver1.1 ADD Start
    cv_message_string_17        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10772';                     -- メッセージ用文字列【補填(円)】
    cv_message_string_18        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10773';                     -- メッセージ用文字列【問屋マージン(円)】
    cv_message_string_19        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10774';                     -- メッセージ用文字列【今回条件(円)】
    cv_message_string_20        CONSTANT  VARCHAR2(20)  :=  'APP-XXCOK1-10775';                     -- メッセージ用文字列【問屋マージン修正(円)】
-- 2020/12/04 Ver1.1 ADD End
    cv_token_name               CONSTANT  VARCHAR2(20)  :=  'ITEM';                                 -- トークン名【ITEM】
    cv_deduction_type_010       CONSTANT  VARCHAR2(20)  :=  '010';                                  -- 控除タイプ【請求額×料率(％)】
    cv_deduction_type_020       CONSTANT  VARCHAR2(20)  :=  '020';                                  -- 控除タイプ【販売数量×金額】
    cv_deduction_type_030       CONSTANT  VARCHAR2(20)  :=  '030';                                  -- 控除タイプ【問屋未収(定額)】
    cv_deduction_type_040       CONSTANT  VARCHAR2(20)  :=  '040';                                  -- 控除タイプ【問屋未収(追加)】
    cv_deduction_type_050       CONSTANT  VARCHAR2(20)  :=  '050';                                  -- 控除タイプ【定額協賛金】
    cv_deduction_type_060       CONSTANT  VARCHAR2(20)  :=  '060';                                  -- 控除タイプ【対象数量予測協賛金】
    cv_target_category_P        CONSTANT  VARCHAR2(20)  :=  'P';                                    -- 対象区分【P】
    cv_target_category_D        CONSTANT  VARCHAR2(20)  :=  'D';                                    -- 対象区分【D】
    cv_uom_hon                  CONSTANT  VARCHAR2(20)  :=  FND_PROFILE.VALUE('XXCOS1_HON_UOM_CODE'); -- 単位【本】

    -- ==============================
    --  ローカル変数
    -- ==============================
    lv_message_string                   VARCHAR2(20);
    lv_parameter_name                   VARCHAR2(100);
    lv_item_code                        VARCHAR2(1000);
    lv_organization_code                VARCHAR2(1000);
    ln_inventory_item_id                NUMBER;
    ln_organization_id                  NUMBER;
    ln_content                          NUMBER;
    lv_errbuf                           VARCHAR2(5000);     -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1);        -- リターン・コード
    lv_errmsg                           VARCHAR2(5000);     -- ユーザー・エラー・メッセージ

    -- ==============================
    -- ローカル例外
    -- ==============================
    no_item_input_expt1                 EXCEPTION;          -- パラメータ未入力
    no_item_input_expt2                 EXCEPTION;          -- パラメータ未入力
    invalid_item_expt                   EXCEPTION;          -- パラメータ不正
    conversion_error_expt               EXCEPTION;          -- 単位換算エラー
--
  BEGIN
    --=======================================
    -- 出力パラメータセット
    --=======================================
    ov_errbuf         := NULL;
    ov_retcode        := gv_status_normal;
    ov_errmsg         := NULL;

    --=======================================
    -- パラメータコードチェック
    --=======================================
    -- 控除タイプ
    IF  iv_deduction_type IN  (cv_deduction_type_010, cv_deduction_type_020, cv_deduction_type_030, cv_deduction_type_040, cv_deduction_type_050, cv_deduction_type_060)  THEN
      NULL;
    ELSE
      lv_message_string :=  cv_message_string_06;
      IF  iv_deduction_type IS  NULL  THEN
        RAISE no_item_input_expt2;
      ELSE
        RAISE invalid_item_expt;
      END IF;
    END IF;

    -- 対象区分
    IF  iv_deduction_type = cv_deduction_type_010 THEN
      IF  iv_target_category  IN  (cv_target_category_P, cv_target_category_D)  THEN
        NULL;
      ELSE
        lv_message_string :=  cv_message_string_08;
        IF  iv_target_category  IS  NULL  THEN
          RAISE no_item_input_expt2;
        ELSE
          RAISE invalid_item_expt;
        END IF;
      END IF;
    END IF;

    --=======================================
    -- パラメータ必須チェック
    --=======================================
    -- 【共通】
    -- 品目コード
    IF  iv_item_code  IS  NULL  THEN
      lv_message_string :=  cv_message_string_01;
      RAISE no_item_input_expt1;
    END IF;

    -- 販売単位
    IF  iv_sales_uom_code IS  NULL  THEN
      lv_message_string :=  cv_message_string_02;
      RAISE no_item_input_expt1;
    END IF;

    -- 販売数量
    IF  in_sales_quantity IS  NULL  THEN
      lv_message_string :=  cv_message_string_03;
      RAISE no_item_input_expt1;
    END IF;

    -- 税コード
    IF  iv_tax_code_trn IS  NULL  THEN
      lv_message_string :=  cv_message_string_16;
      RAISE no_item_input_expt1;
    END IF;

    -- 税率
    IF  in_tax_rate_trn IS  NULL  THEN
      lv_message_string :=  cv_message_string_05;
      RAISE no_item_input_expt1;
    END IF;

    -- 【請求額×料率(％)】
    IF  iv_deduction_type = cv_deduction_type_010 THEN
      -- 売上本体金額
      IF  in_sale_pure_amount IS  NULL  THEN
        lv_message_string :=  cv_message_string_04;
        RAISE no_item_input_expt1;
      END IF;

      -- 店納(％)
      IF  iv_target_category  = cv_target_category_D  THEN
        IF  in_shop_pay_1 IS  NULL  THEN
          lv_message_string :=  cv_message_string_09;
          RAISE no_item_input_expt2;
        END IF;
      END IF;

      -- 料率(％)
      IF  in_material_rate_1  IS  NULL  THEN
        lv_message_string :=  cv_message_string_10;
        RAISE no_item_input_expt2;
      END IF;

    END IF;

    -- 【販売数量×金額】
    IF  iv_deduction_type = cv_deduction_type_020 THEN
      -- 条件単価２(円)
      IF  in_condition_unit_price_en_2  IS  NULL  THEN
        lv_message_string :=  cv_message_string_11;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    -- 【問屋未収(定額)】
    IF  iv_deduction_type = cv_deduction_type_030 THEN
      -- 単位(条件)
      IF  iv_uom_code IS  NULL  THEN
        lv_message_string :=  cv_message_string_07;
        RAISE no_item_input_expt2;
      END IF;

      -- 未収計３(円)
      IF  in_accrued_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_12;
        RAISE no_item_input_expt2;
      END IF;

-- 2020/12/04 Ver1.1 ADD Start
      -- 補填(円)
      IF  in_compensation_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_17;
        RAISE no_item_input_expt2;
      END IF;

      -- 問屋マージン(円)
      IF  in_wholesale_margin_en_3 IS  NULL  THEN
        lv_message_string :=  cv_message_string_18;
        RAISE no_item_input_expt2;
      END IF;
-- 2020/12/04 Ver1.1 ADD End
    END IF;

    -- 【問屋未収(追加)】
    IF  iv_deduction_type = cv_deduction_type_040 THEN
      -- 単位(条件)
      IF  iv_uom_code IS  NULL  THEN
        lv_message_string :=  cv_message_string_07;
        RAISE no_item_input_expt2;
      END IF;

      -- 未収計４(円)
      IF  in_accrued_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_13;
        RAISE no_item_input_expt2;
      END IF;

-- 2020/12/04 Ver1.1 ADD Start
      -- 今回条件(円)
      IF  in_just_condition_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_19;
        RAISE no_item_input_expt2;
      END IF;

      -- 問屋マージン修正(円)
      IF  in_wholesale_adj_margin_en_4 IS  NULL  THEN
        lv_message_string :=  cv_message_string_20;
        RAISE no_item_input_expt2;
      END IF;
-- 2020/12/04 Ver1.1 ADD End
    END IF;

    -- 【定額協賛金】
    IF  iv_deduction_type = cv_deduction_type_050 THEN
      -- 条件単価５(円)
      IF  in_condition_unit_price_en_5  IS  NULL  THEN
        lv_message_string :=  cv_message_string_14;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    -- 【対象数量予測協賛金】
    IF  iv_deduction_type = cv_deduction_type_060 THEN
      -- 控除単価(円)
      IF  in_deduction_unit_price_en_6  IS  NULL  THEN
        lv_message_string :=  cv_message_string_15;
        RAISE no_item_input_expt2;
      END IF;
    END IF;

    IF iv_tax_code_mst IS NOT NULL AND in_tax_rate_mst IS NOT NULL THEN
      ov_tax_code :=  iv_tax_code_mst;
      on_tax_rate :=  in_tax_rate_mst;
    ELSE
      ov_tax_code :=  iv_tax_code_trn;
      on_tax_rate :=  in_tax_rate_trn;
    END IF;

    --=======================================
    -- 単位換算
    --=======================================
    IF    iv_deduction_type IN  (cv_deduction_type_010, cv_deduction_type_020)  THEN
      ov_deduction_uom_code :=  NULL;
    ELSIF iv_deduction_type IN  (cv_deduction_type_030, cv_deduction_type_040)  THEN
      ov_deduction_uom_code :=  iv_uom_code;
    ELSIF iv_deduction_type IN  (cv_deduction_type_050, cv_deduction_type_060)  THEN
      ov_deduction_uom_code :=  cv_uom_hon;
    END IF;

    IF  iv_sales_uom_code = ov_deduction_uom_code THEN
      on_deduction_quantity :=  in_sales_quantity;
    ELSE
      lv_item_code          :=  iv_item_code;
      lv_organization_code  :=  NULL;
      ln_inventory_item_id  :=  NULL;
      ln_organization_id    :=  NULL;

      XXCOS_COMMON_PKG.get_uom_cnv(
        iv_before_uom_code    =>  iv_sales_uom_code     ,
        in_before_quantity    =>  in_sales_quantity     ,
        iov_item_code         =>  lv_item_code          ,
        iov_organization_code =>  lv_organization_code  ,
        ion_inventory_item_id =>  ln_inventory_item_id  ,
        ion_organization_id   =>  ln_organization_id    ,
        iov_after_uom_code    =>  ov_deduction_uom_code ,
        on_after_quantity     =>  on_deduction_quantity ,
        on_content            =>  ln_content            ,
        ov_errbuf             =>  lv_errbuf             ,
        ov_retcode            =>  lv_retcode            ,
        ov_errmsg             =>  lv_errmsg
      );

      IF  lv_retcode  = gv_status_normal  THEN
        NULL;
      ELSE
        RAISE conversion_error_expt;
      END IF;
    END IF;

    IF    iv_deduction_type = cv_deduction_type_010 THEN
      IF    iv_target_category  = cv_target_category_P  THEN
        on_deduction_amount     :=  in_sale_pure_amount * in_material_rate_1  / 100;
      ELSIF iv_target_category  = cv_target_category_D  THEN
        on_deduction_amount     :=  in_sale_pure_amount * in_shop_pay_1 * in_material_rate_1 / 10000;
      END IF;
      IF  on_deduction_quantity !=  0 THEN
        on_deduction_unit_price :=  ROUND(on_deduction_amount / on_deduction_quantity,2);
      ELSE
        on_deduction_unit_price :=  0;
      END IF;
    ELSIF iv_deduction_type = cv_deduction_type_020 THEN
      on_deduction_amount     :=  in_condition_unit_price_en_2  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_condition_unit_price_en_2,2);
    ELSIF iv_deduction_type = cv_deduction_type_030 THEN
      on_deduction_amount     :=  in_accrued_en_3 * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_accrued_en_3,2);
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_deduction_amount     :=  in_accrued_en_4 * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_accrued_en_4,2);
    ELSIF iv_deduction_type = cv_deduction_type_050 THEN
      on_deduction_amount     :=  in_condition_unit_price_en_5  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_condition_unit_price_en_5,2);
    ELSIF iv_deduction_type = cv_deduction_type_060 THEN
      on_deduction_amount     :=  in_deduction_unit_price_en_6  * on_deduction_quantity;
      on_deduction_unit_price :=  ROUND(in_deduction_unit_price_en_6,2);
    END IF;

    on_deduction_tax_amount :=  ROUND(on_deduction_amount * on_tax_rate / 100);

-- 2020/12/04 Ver1.1 ADD Start
    IF    iv_deduction_type = cv_deduction_type_030 THEN
      on_compensation             :=  ROUND(in_compensation_en_3    * on_deduction_quantity,2);
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_sales_promotion_expenses :=  ROUND(in_just_condition_en_4  * on_deduction_quantity,2);
    END IF;
-- 2020/12/04 Ver1.1 ADD End

    on_deduction_quantity :=  ROUND(on_deduction_quantity,2);
    on_deduction_amount   :=  ROUND(on_deduction_amount);

-- 2020/12/04 Ver1.1 ADD Start
    IF    iv_deduction_type = cv_deduction_type_030 THEN
      on_margin                   :=  on_deduction_amount     - on_compensation;
    ELSIF iv_deduction_type = cv_deduction_type_040 THEN
      on_margin_reduction         :=  on_deduction_amount     - on_sales_promotion_expenses;
    END IF;
-- 2020/12/04 Ver1.1 ADD End
--
  EXCEPTION
    WHEN no_item_input_expt1 THEN
      --メッセージ取得
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- アプリケーション短縮名
                             ,iv_name         => lv_message_string                -- メッセージコード
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- アプリケーション短縮名
                     ,iv_name         => cv_no_item_input_msg1                    -- メッセージコード
                     ,iv_token_name1  => cv_token_name                            -- トークンコード1
                     ,iv_token_value1 => lv_parameter_name                        -- トークン値1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN no_item_input_expt2 THEN
      --メッセージ取得
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- アプリケーション短縮名
                             ,iv_name         => lv_message_string                -- メッセージコード
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- アプリケーション短縮名
                     ,iv_name         => cv_no_item_input_msg2                    -- メッセージコード
                     ,iv_token_name1  => cv_token_name                            -- トークンコード1
                     ,iv_token_value1 => lv_parameter_name                        -- トークン値1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN invalid_item_expt THEN
      --メッセージ取得
      lv_parameter_name :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcok                         -- アプリケーション短縮名
                             ,iv_name         => lv_message_string                -- メッセージコード
                            );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- アプリケーション短縮名
                     ,iv_name         => cv_invalid_item_msg                      -- メッセージコード
                     ,iv_token_name1  => cv_token_name                            -- トークンコード2
                     ,iv_token_value1 => lv_parameter_name                        -- トークン値1
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN conversion_error_expt THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok                                 -- アプリケーション短縮名
                     ,iv_name         => cv_conversion_error_msg                  -- メッセージコード
                    );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_sepa_period||cv_prg_name||cv_sepa_colon||lv_errmsg,1,5000);
      ov_retcode  :=  gv_status_error;
      ov_errmsg   :=  lv_errmsg;

    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(
        -20000, cv_pkg_name || cv_sepa_period || cv_prg_name || cv_sepa_colon || SQLERRM
      );
  END calculate_deduction_amount_p;
--
END xxcok_common2_pkg;
/
