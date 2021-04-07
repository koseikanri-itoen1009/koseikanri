CREATE OR REPLACE PACKAGE BODY XXCOK024A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A03C_pkg(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：販売実績・販売控除データの作成 MD050_COK_024_A03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_sales_exp_p        販売実績データ抽出(A-2)
 *  calc_deduction_p       販売控除データ算出(A-3)
 *  ins_deduction_p        販売控除データ登録(A-4)
 *  upd_control_p          販売控除管理情報更新(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/01/15    1.0   Y.Koh            新規作成
 *  2020/12/03    1.1   SCSK Y.Koh       [E_本稼動_16026]
 *  2021/04/06    1.2   SCSK Y.Koh       [E_本稼動_16026]
 *
 *****************************************************************************************/
--
  -- ==============================
  -- グローバル定数
  -- ==============================
  -- ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A03C';                      -- パッケージ名
  -- プロファイル
  cv_sales_deduction_max      CONSTANT VARCHAR2(30)         := 'XXCOK1_SALES_DEDUCTION_MAX';        -- 販売控除最大処理件数
  -- アプリケーション短縮名
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- アプリケーション短縮名
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- アプリケーション短縮名
  -- メッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- 対象件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- 成功件数メッセージ
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- スキップ件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- エラー件数メッセージ
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- 対象なしメッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- 警告終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- エラー終了全ロールバックメッセージ
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- プロファイル取得エラー
  cv_msg_cok_10592            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10592';                  -- 前回処理ID取得エラー
  cv_msg_cok_10593            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10593';                  -- 控除額算出エラー
  -- トークン名
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- 件数のトークン名
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- プロファイル名のトークン名
  cv_tkn_source_line_id       CONSTANT VARCHAR2(15)         := 'SOURCE_LINE_ID';                    -- 販売実績明細IDのトークン名
  cv_tkn_item_code            CONSTANT VARCHAR2(15)         := 'ITEM_CODE';                         -- 品目コードのトークン名
  cv_tkn_sales_uom_code       CONSTANT VARCHAR2(15)         := 'SALES_UOM_CODE';                    -- 販売単位のトークン名
  cv_tkn_condition_no         CONSTANT VARCHAR2(15)         := 'CONDITION_NO';                      -- 控除番号のトークン名
  cv_tkn_base_code            CONSTANT VARCHAR2(15)         := 'BASE_CODE';                         -- 担当拠点のトークン名
  cv_tkn_errmsg               CONSTANT VARCHAR2(15)         := 'ERRMSG';                            -- エラーメッセージのトークン名
  -- 参照タイプ
  cv_lookup_CHAIN_CODE        CONSTANT VARCHAR2(50)         := 'XXCMM_CHAIN_CODE';                  -- チェーン店コード
  cv_lookup_DATA_TYPE         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- 控除データ種類
  -- フラグ
  cv_flag_s                   CONSTANT VARCHAR2(1)          := 'S';                                 -- 作成元区分 S
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- 連携フラグ N
  -- 記号
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  -- ==============================
  -- グローバル変数
  -- ==============================
  gn_target_cnt               NUMBER    DEFAULT 0;                                                  -- 対象件数
  gn_normal_cnt               NUMBER    DEFAULT 0;                                                  -- 正常件数
  gn_skip_cnt                 NUMBER    DEFAULT 0;                                                  -- スキップ件数
  gn_error_cnt                NUMBER    DEFAULT 0;                                                  -- エラー件数
--
  gn_target_header_id_st      NUMBER;                                                               -- 販売実績明細ID (自)
  gn_target_header_id_ed      NUMBER;                                                               -- 販売実績明細ID (至)
--
  gv_deduction_uom_code       VARCHAR2(3);                                                          -- 控除単位
  gn_deduction_unit_price     NUMBER;                                                               -- 控除単価
  gn_deduction_quantity       NUMBER;                                                               -- 控除数量
  gn_deduction_amount         NUMBER;                                                               -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                                               -- 補填
  gn_margin                   NUMBER;                                                               -- 問屋マージン
  gn_sales_promotion_expenses NUMBER;                                                               -- 拡売
  gn_margin_reduction         NUMBER;                                                               -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount     NUMBER;                                                               -- 控除税額
  gn_tax_code                 VARCHAR2(4);                                                          -- 税コード
  gn_tax_rate                 NUMBER;                                                               -- 税率
--
  -- ==============================
  -- グローバルカーソル
  -- ==============================
  CURSOR g_sales_exp_cur
  IS
    WITH 
     FLVC1 AS
      (SELECT /*+ MATERIALIZED */ LOOKUP_CODE
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCOK1_DEDUCTION_TYPE'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE1    = 'Y'
      )
    ,FLVC2 AS
      (SELECT /*+ MATERIALIZED */ MEANING
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCOS1_MK_ORG_CLS_MST_013_A01'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE4    = 'Y'
      )
    ,FLVC3 AS
      (SELECT /*+ MATERIALIZED */ LOOKUP_CODE
      FROM FND_LOOKUP_VALUES FLVC
      WHERE FLVC.LOOKUP_TYPE = 'XXCMM_CUST_GYOTAI_SHO'
      AND FLVC.LANGUAGE      = 'JA'
      AND FLVC.ENABLED_FLAG  = 'Y'
      AND FLVC.ATTRIBUTE2    = 'Y'
      )
    --①
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE(+)          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE(+)          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE(+)             = 'JA'
    AND CHCD.ENABLED_FLAG(+)         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND XSEH.SHIP_TO_CUSTOMER_CODE = XCH.CUSTOMER_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE
    UNION ALL
    --②
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE(+)          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE(+)          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE(+)             = 'JA'
    AND CHCD.ENABLED_FLAG(+)         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND XCA.INTRO_CHAIN_CODE2         = XCH.DEDUCTION_CHAIN_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE
    UNION ALL
    --③
    SELECT 
      /*+ leading(XSEH)
          USE_NL(XCA) USE_NL(XCH) USE_NL(XCL) USE_NL(XSEL) USE_NL(CHCD) USE_NL(DTYP)
       */
      XSEH.SALES_BASE_CODE ,
      XSEH.SHIP_TO_CUSTOMER_CODE ,
      XSEH.DELIVERY_DATE ,
      XSEL.SALES_EXP_LINE_ID ,
      XSEL.ITEM_CODE DIV_ITEM_CODE ,
      XSEL.DLV_UOM_CODE ,
      XSEL.DLV_UNIT_PRICE ,
      XSEL.DLV_QTY ,
      XSEL.PURE_AMOUNT ,
      XSEL.TAX_AMOUNT ,
      XSEL.TAX_CODE TAX_CODE_TRN ,
      XSEL.TAX_RATE TAX_RATE_TRN ,
      XCH.CONDITION_ID ,
      XCH.CONDITION_NO ,
      XCH.CORP_CODE ,
      XCH.DEDUCTION_CHAIN_CODE ,
      XCH.CUSTOMER_CODE ,
      XCH.DATA_TYPE ,
      XCH.TAX_CODE TAX_CODE_MST ,
      XCH.TAX_RATE TAX_RATE_MST ,
      CHCD.ATTRIBUTE3 CHAIN_BASE ,
      XCA.SALE_BASE_CODE CUST_BASE ,
      XCL.CONDITION_LINE_ID ,
      XCL.PRODUCT_CLASS ,
      XCL.ITEM_CODE ,
      XCL.UOM_CODE ,
      XCL.TARGET_CATEGORY ,
      XCL.SHOP_PAY_1 ,
      XCL.MATERIAL_RATE_1 ,
      XCL.CONDITION_UNIT_PRICE_EN_2 ,
      XCL.ACCRUED_EN_3 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.COMPENSATION_EN_3 ,
      XCL.WHOLESALE_MARGIN_EN_3 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.ACCRUED_EN_4 ,
-- 2020/12/03 Ver1.1 ADD Start
      XCL.JUST_CONDITION_EN_4 ,
      XCL.WHOLESALE_ADJ_MARGIN_EN_4 ,
-- 2020/12/03 Ver1.1 ADD End
      XCL.CONDITION_UNIT_PRICE_EN_5 ,
      XCL.DEDUCTION_UNIT_PRICE_EN_6 ,
      DTYP.ATTRIBUTE2
    FROM FND_LOOKUP_VALUES DTYP,
      XXCOK_CONDITION_LINES XCL ,
      XXCOK_CONDITION_HEADER XCH ,
      FND_LOOKUP_VALUES CHCD,
      XXCMM_CUST_ACCOUNTS XCA ,
      xxcok_sales_exp_h XSEH,
      xxcok_sales_exp_l XSEL,
      FLVC1 D_TYP,
      FLVC2 MK_CLS,
      FLVC3 GYOTAI_SHO
    WHERE 1=1
    AND XSEH.SALES_EXP_HEADER_ID BETWEEN gn_target_header_id_st  AND gn_target_header_id_ed
    AND XSEH.SALES_EXP_HEADER_ID = XSEL.SALES_EXP_HEADER_ID
    AND XSEH.CREATE_CLASS = MK_CLS.MEANING
    AND XCA.CUSTOMER_CODE          = XSEH.SHIP_TO_CUSTOMER_CODE
    AND XCA.BUSINESS_LOW_TYPE = GYOTAI_SHO.LOOKUP_CODE
    AND CHCD.LOOKUP_TYPE          = 'XXCMM_CHAIN_CODE'
    AND CHCD.LOOKUP_CODE          = XCA.INTRO_CHAIN_CODE2
    AND CHCD.LANGUAGE             = 'JA'
    AND CHCD.ENABLED_FLAG         = 'Y'
    AND XCH.ENABLED_FLAG_H           = 'Y'
    AND DTYP.LOOKUP_TYPE             = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND DTYP.LOOKUP_CODE             = XCH.DATA_TYPE
    AND DTYP.LANGUAGE                = 'JA'
    AND DTYP.ENABLED_FLAG            = 'Y'
    AND CHCD.ATTRIBUTE1               = XCH.CORP_CODE
    AND XSEH.DELIVERY_DATE BETWEEN XCH.START_DATE_ACTIVE AND XCH.END_DATE_ACTIVE
    AND XCL.CONDITION_ID   = XCH.CONDITION_ID
    AND XCL.ENABLED_FLAG_L = 'Y'
-- 2021/04/06 Ver1.2 MOD Start
    AND ( XCL.ITEM_CODE IN (XSEL.ITEM_CODE, XSEL.VESSEL_GROUP_ITEM_CODE)
--    AND ( XSEL.ITEM_CODE   = XCL.ITEM_CODE
-- 2021/04/06 Ver1.2 MOD End
    OR    XSEL.PRODUCT_CLASS  = XCL.PRODUCT_CLASS )
    AND DTYP.ATTRIBUTE2  = D_TYP.LOOKUP_CODE;
--
  g_sales_exp_rec             g_sales_exp_cur%ROWTYPE;
--
  -- ==============================
  -- グローバル例外
  -- ==============================
  -- *** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 処理対象範囲の販売実績ヘッダーIDの取得
    -- ============================================================
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_header_id_st
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_s;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xseh.sales_exp_header_id)
    INTO    gn_target_header_id_ed
    FROM    xxcok_sales_exp_h xseh
    WHERE   xseh.sales_exp_header_id >= gn_target_header_id_st;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : calc_deduction_p
   * Description      : 販売控除データ算出(A-3)
   ***********************************************************************************/
  PROCEDURE calc_deduction_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'calc_deduction_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_base_code    VARCHAR2(4);                            -- 担当拠点
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 共通関数 控除額算出
    -- ============================================================
    xxcok_common2_pkg.calculate_deduction_amount_p(
      ov_errbuf                     =>  lv_errbuf                                 , -- エラーバッファ
      ov_retcode                    =>  lv_retcode                                , -- リターンコード
      ov_errmsg                     =>  lv_errmsg                                 , -- エラーメッセージ
      iv_item_code                  =>  g_sales_exp_rec.div_item_code             , -- 品目コード
      iv_sales_uom_code             =>  g_sales_exp_rec.dlv_uom_code              , -- 販売単位
      in_sales_quantity             =>  g_sales_exp_rec.dlv_qty                   , -- 販売数量
      in_sale_pure_amount           =>  g_sales_exp_rec.pure_amount               , -- 売上本体金額
      iv_tax_code_trn               =>  g_sales_exp_rec.tax_code_trn              , -- 税コード(TRN)
      in_tax_rate_trn               =>  g_sales_exp_rec.tax_rate_trn              , -- 税率(TRN)
      iv_deduction_type             =>  g_sales_exp_rec.attribute2                , -- 控除タイプ
      iv_uom_code                   =>  g_sales_exp_rec.uom_code                  , -- 単位(条件)
      iv_target_category            =>  g_sales_exp_rec.target_category           , -- 対象区分
      in_shop_pay_1                 =>  g_sales_exp_rec.shop_pay_1                , -- 店納(％)
      in_material_rate_1            =>  g_sales_exp_rec.material_rate_1           , -- 料率(％)
      in_condition_unit_price_en_2  =>  g_sales_exp_rec.condition_unit_price_en_2 , -- 条件単価２(円)
      in_accrued_en_3               =>  g_sales_exp_rec.accrued_en_3              , -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
      in_compensation_en_3          =>  g_sales_exp_rec.compensation_en_3         , -- 補填(円)
      in_wholesale_margin_en_3      =>  g_sales_exp_rec.wholesale_margin_en_3     , -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
      in_accrued_en_4               =>  g_sales_exp_rec.accrued_en_4              , -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
      in_just_condition_en_4        =>  g_sales_exp_rec.just_condition_en_4       , -- 今回条件(円)
      in_wholesale_adj_margin_en_4  =>  g_sales_exp_rec.wholesale_adj_margin_en_4 , -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
      in_condition_unit_price_en_5  =>  g_sales_exp_rec.condition_unit_price_en_5 , -- 条件単価５(円)
      in_deduction_unit_price_en_6  =>  g_sales_exp_rec.deduction_unit_price_en_6 , -- 控除単価(円)
      iv_tax_code_mst               =>  g_sales_exp_rec.tax_code_mst              , -- 税コード(MST)
      in_tax_rate_mst               =>  g_sales_exp_rec.tax_rate_mst              , -- 税率(MST)
      ov_deduction_uom_code         =>  gv_deduction_uom_code                     , -- 控除単位
      on_deduction_unit_price       =>  gn_deduction_unit_price                   , -- 控除単価
      on_deduction_quantity         =>  gn_deduction_quantity                     , -- 控除数量
      on_deduction_amount           =>  gn_deduction_amount                       , -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
      on_compensation               =>  gn_compensation                           , -- 補填
      on_margin                     =>  gn_margin                                 , -- 問屋マージン
      on_sales_promotion_expenses   =>  gn_sales_promotion_expenses               , -- 拡売
      on_margin_reduction           =>  gn_margin_reduction                       , -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
      on_deduction_tax_amount       =>  gn_deduction_tax_amount                   , -- 控除税額
      ov_tax_code                   =>  gn_tax_code                               , -- 税コード
      on_tax_rate                   =>  gn_tax_rate                                 -- 税率
    );
--
    IF  lv_retcode  !=  cv_status_normal  THEN
      IF  g_sales_exp_rec.corp_code IS  NOT NULL  THEN
        SELECT  MAX(ffv.attribute2)
        INTO    lv_base_code
        FROM    fnd_flex_values     ffv ,
                fnd_flex_value_sets ffvs
        WHERE   ffvs.flex_value_set_name  = 'XX03_BUSINESS_TYPE'
        AND     ffv.flex_value_set_id     = ffvs.flex_value_set_id
        AND     ffv.flex_value            = g_sales_exp_rec.corp_code;
      ELSIF g_sales_exp_rec.deduction_chain_code  IS  NOT NULL  THEN
        lv_base_code  :=  g_sales_exp_rec.chain_base;
      ELSIF g_sales_exp_rec.customer_code IS  NOT NULL  THEN
        lv_base_code  :=  g_sales_exp_rec.cust_base;
      END IF;

      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_10593
                    , cv_tkn_source_line_id
                    , g_sales_exp_rec.sales_exp_line_id
                    , cv_tkn_item_code
                    , g_sales_exp_rec.div_item_code
                    , cv_tkn_sales_uom_code
                    , g_sales_exp_rec.dlv_uom_code
                    , cv_tkn_condition_no
                    , g_sales_exp_rec.condition_no
                    , cv_tkn_base_code
                    , lv_base_code
                    , cv_tkn_errmsg
                    , lv_errmsg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 1                  -- 改行
                    );
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END calc_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_deduction_p
   * Description      : 販売控除データ登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_deduction_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_deduction_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除データ登録
    -- ============================================================
    INSERT  INTO  xxcok_sales_deduction(
      sales_deduction_id                          , -- 販売控除ID
      base_code_from                              , -- 振替元拠点
      base_code_to                                , -- 振替先拠点
      customer_code_from                          , -- 振替元顧客コード
      customer_code_to                            , -- 振替先顧客コード
      deduction_chain_code                        , -- 控除用チェーンコード
      corp_code                                   , -- 企業コード
      record_date                                 , -- 計上日
      source_category                             , -- 作成元区分
      source_line_id                              , -- 作成元明細ID
      condition_id                                , -- 控除条件ID
      condition_no                                , -- 控除番号
      condition_line_id                           , -- 控除詳細ID
      data_type                                   , -- データ種類
      status                                      , -- ステータス
      item_code                                   , -- 品目コード
      sales_uom_code                              , -- 販売単位
      sales_unit_price                            , -- 販売単価
      sales_quantity                              , -- 販売数量
      sale_pure_amount                            , -- 売上本体金額
      sale_tax_amount                             , -- 売上消費税額
      deduction_uom_code                          , -- 控除単位
      deduction_unit_price                        , -- 控除単価
      deduction_quantity                          , -- 控除数量
      deduction_amount                            , -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
      compensation                                , -- 補填
      margin                                      , -- 問屋マージン
      sales_promotion_expenses                    , -- 拡売
      margin_reduction                            , -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
      tax_code                                    , -- 税コード
      tax_rate                                    , -- 税率
      recon_tax_code                              , -- 消込時税コード
      recon_tax_rate                              , -- 消込時税率
      deduction_tax_amount                        , -- 控除税額
      remarks                                     , -- 備考
      application_no                              , -- 申請書No.
      gl_if_flag                                  , -- GL連携フラグ
      gl_base_code                                , -- GL計上拠点
      gl_date                                     , -- GL記帳日
-- 2020/12/03 Ver1.1 MOD Start
      recovery_date                               , -- リカバリデータ追加時日付
      recovery_add_request_id                     , -- リカバリデータ追加時要求ID
      recovery_del_date                           , -- リカバリデータ削除時日付
      recovery_del_request_id                     , -- リカバリデータ削除時要求ID
--      recovery_date                               , -- リカバリー日付
-- 2020/12/03 Ver1.1 MOD End
      cancel_flag                                 , -- 取消フラグ
      cancel_base_code                            , -- 取消時計上拠点
      cancel_gl_date                              , -- 取消GL記帳日
      cancel_user                                 , -- 取消実施ユーザ
      recon_base_code                             , -- 消込時計上拠点
      recon_slip_num                              , -- 支払伝票番号
      carry_payment_slip_num                      , -- 繰越時支払伝票番号
      report_decision_flag                        , -- 速報確定フラグ
      gl_interface_id                             , -- GL連携ID
      cancel_gl_interface_id                      , -- 取消GL連携ID
      created_by                                  , -- 作成者
      creation_date                               , -- 作成日
      last_updated_by                             , -- 最終更新者
      last_update_date                            , -- 最終更新日
      last_update_login                           , -- 最終更新ログイン
      request_id                                  , -- 要求ID
      program_application_id                      , -- コンカレント・プログラム・アプリケーションID
      program_id                                  , -- コンカレント・プログラムID
      program_update_date                         ) -- プログラム更新日
    values(
      xxcok_sales_deduction_s01.NEXTVAL           , -- 販売控除ID
      g_sales_exp_rec.sales_base_code             , -- 振替元拠点
      g_sales_exp_rec.sales_base_code             , -- 振替先拠点
      g_sales_exp_rec.ship_to_customer_code       , -- 振替元顧客コード
      g_sales_exp_rec.ship_to_customer_code       , -- 振替先顧客コード
      NULL                                        , -- 控除用チェーンコード
      NULL                                        , -- 企業コード
      g_sales_exp_rec.delivery_date               , -- 計上日
      cv_flag_s                                   , -- 作成元区分
      g_sales_exp_rec.sales_exp_line_id           , -- 作成元明細ID
      g_sales_exp_rec.condition_id                , -- 控除条件ID
      g_sales_exp_rec.condition_no                , -- 控除番号
      g_sales_exp_rec.condition_line_id           , -- 控除詳細ID
      g_sales_exp_rec.data_type                   , -- データ種類
      cv_flag_n                                   , -- ステータス
      g_sales_exp_rec.div_item_code               , -- 品目コード
      g_sales_exp_rec.dlv_uom_code                , -- 販売単位
      g_sales_exp_rec.dlv_unit_price              , -- 販売単価
      g_sales_exp_rec.dlv_qty                     , -- 販売数量
      g_sales_exp_rec.pure_amount                 , -- 売上本体金額
      g_sales_exp_rec.tax_amount                  , -- 売上消費税額
      gv_deduction_uom_code                       , -- 控除単位
      gn_deduction_unit_price                     , -- 控除単価
      gn_deduction_quantity                       , -- 控除数量
      gn_deduction_amount                         , -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
      gn_compensation                             , -- 補填
      gn_margin                                   , -- 問屋マージン
      gn_sales_promotion_expenses                 , -- 拡売
      gn_margin_reduction                         , -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
      gn_tax_code                                 , -- 税コード
      gn_tax_rate                                 , -- 税率
      NULL                                        , -- 消込時税コード
      NULL                                        , -- 消込時税率
      gn_deduction_tax_amount                     , -- 控除税額
      NULL                                        , -- 備考
      NULL                                        , -- 申請書No.
      cv_flag_n                                   , -- GL連携フラグ
      NULL                                        , -- GL計上拠点
      NULL                                        , -- GL記帳日
-- 2020/12/03 Ver1.1 MOD Start
      NULL                                        , -- リカバリデータ追加時日付
      NULL                                        , -- リカバリデータ追加時要求ID
      NULL                                        , -- リカバリデータ削除時日付
      NULL                                        , -- リカバリデータ削除時要求ID
--      NULL                                        , -- リカバリー日付
-- 2020/12/03 Ver1.1 MOD End
      cv_flag_n                                   , -- 取消フラグ
      NULL                                        , -- 取消時計上拠点
      NULL                                        , -- 取消GL記帳日
      NULL                                        , -- 取消実施ユーザ
      NULL                                        , -- 消込時計上拠点
      NULL                                        , -- 支払伝票番号
      NULL                                        , -- 繰越時支払伝票番号
      NULL                                        , -- 速報確定フラグ
      NULL                                        , -- GL連携ID
      NULL                                        , -- 取消GL連携ID
      cn_user_id                                  , -- 作成者
      SYSDATE                                     , -- 作成日
      cn_user_id                                  , -- 最終更新者
      SYSDATE                                     , -- 最終更新日
      cn_login_id                                 , -- 最終更新ログイン
      cn_conc_request_id                          , -- 要求ID
      cn_prog_appl_id                             , -- コンカレント・プログラム・アプリケーションID
      cn_conc_program_id                          , -- コンカレント・プログラムID
      SYSDATE                                     );-- プログラム更新日
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END ins_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_p
   * Description      : 販売実績データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_sales_exp_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売実績データ抽出
    -- ============================================================
    OPEN  g_sales_exp_cur;
    FETCH g_sales_exp_cur INTO  g_sales_exp_rec;
--
    -- 1件目が存在しない場合は、対象なしメッセージを出力
    IF  g_sales_exp_cur%NOTFOUND  THEN
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_msg_cok_00001
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 1                  -- 改行
                    );
      RETURN;
    END IF;
--
    LOOP
      EXIT  WHEN  g_sales_exp_cur%NOTFOUND;
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ============================================================
      -- 販売控除データ算出(A-3)の呼び出し
      -- ============================================================
      calc_deduction_p(
        ov_errbuf   =>  lv_errbuf                       -- エラー・メッセージ
      , ov_retcode  =>  lv_retcode                      -- リターン・コード
      , ov_errmsg   =>  lv_errmsg                       -- ユーザー・エラー・メッセージ
      );
--
      IF  lv_retcode  = cv_status_normal  THEN
--
        -- ============================================================
        -- 販売控除データ登録(A-4)の呼び出し
        -- ============================================================
        ins_deduction_p(
          ov_errbuf   =>  lv_errbuf                     -- エラー・メッセージ
        , ov_retcode  =>  lv_retcode                    -- リターン・コード
        , ov_errmsg   =>  lv_errmsg                     -- ユーザー・エラー・メッセージ
        );
--
        IF  lv_retcode  = cv_status_normal  THEN
          gn_normal_cnt :=  gn_normal_cnt + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
      ELSIF lv_retcode  = cv_status_warn  THEN
        ov_retcode := cv_status_warn;
        gn_skip_cnt   :=  gn_skip_cnt   + 1;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      FETCH g_sales_exp_cur INTO  g_sales_exp_rec;
    END LOOP;
    CLOSE g_sales_exp_cur;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_sales_exp_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : 販売控除管理情報更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除管理情報更新
    -- ============================================================
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_header_id_ed, last_processing_id) ,
            last_updated_by         = cn_user_id                                    ,
            last_update_date        = SYSDATE                                       ,
            last_update_login       = cn_login_id                                   ,
            request_id              = cn_conc_request_id                            ,
            program_application_id  = cn_prog_appl_id                               ,
            program_id              = cn_conc_program_id                            ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_s;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- グローバル変数の初期化
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- initの呼び出し
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 販売実績データ抽出の呼び出し
    -- ============================================================
    get_sales_exp_p(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_warn  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 販売控除管理情報更新の呼び出し
    -- ============================================================
    upd_control_p(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- エラー・メッセージ
  , retcode OUT VARCHAR2                                    -- リターン・コード
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ変数
--
  BEGIN
--
    -- ============================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
--
    -- ============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- エラー・メッセージ
    , ov_retcode => lv_retcode                              -- リターン・コード
    , ov_errmsg  => lv_errmsg                               -- ユーザー・エラー・メッセージ
    );
--
    -- ============================================================
    -- エラー出力
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- 出力区分
                      , lv_errmsg       -- メッセージ
                      , 1               -- 改行
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- 出力区分
                      , lv_errbuf       -- メッセージ
                      , 0               -- 改行
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- 対象件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- 成功件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- スキップ件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- エラー件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 1                 -- 改行
                    );
--
    -- ============================================================
    -- 終了メッセージ
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A03C;
/
