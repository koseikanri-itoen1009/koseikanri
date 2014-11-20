CREATE OR REPLACE PACKAGE BODY APPS.XXCOS_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcos_common2_pkg(spec)
 * Description            :
 * MD.070                 : MD070_IPO_COS_共通関数
 * Version                : 1.9
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  get_unit_price                  F  NUMBER   単価取得関数
 *  conv_ebs_cust_code              P           顧客コード変換（EDI→EBS)
 *  conv_edi_cust_code              P           顧客コード変換（EBS→EDI)
 *  conv_ebs_item_code              P           品目コード変換（EDI→EBS)
 *  conv_edi_item_code              P           品目コード変換（EBS→EDI)
 *  get_layout_info                 P           レイアウト定義情報取得
 *  makeup_data_record              P           データレコード編集
 *  convert_quantity                P           EDI帳票向け数量換算関数
 *  get_deliv_slip_flag             F           納品書発行フラグ取得関数
 *  get_deliv_slip_flag_area        F           納品書発行フラグ全体取得関数
 *  get_salesrep_id                 P           担当営業員取得関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/11/27    1.0  SCS              新規作成
 *  2009/02/24    1.1  H.Fujimoto       結合不具合No.129
 *  2009/03/11    1.2  K.Kumamoto       I_E_048(百貨店送り状)単体テスト障害対応 (SPEC修正)
 *  2009/03/31    1.3  T.Kitajima       [T1_0113]makeup_data_recordのNUMBER,DATE編集変更
 *  2009/04/16    1.4  T.Kitajima       [T1_0543]conv_edi_item_code ケースJAN、JANコードNULL対応
 *  2009/06/23    1.5  K.Kiriu          [T1_1359]EDI帳票向け数量換算関数の追加
 *  2009/10/02    1.6  M.Sano           [0001156]顧客品目抽出条件追加
 *                                      [0001344]顧客品目検索エラー,JANコード検索エラーのパラメータ追加
 *  2010/04/15    1.7  Y.Goto           [E_本稼動_01719]担当営業員取得関数追加
 *  2010/05/26    1.8  K.Kiriu          [E_本稼動_02853]convert_quantity 出荷数量null時の不具合対応
 *  2010/07/14    1.9  S.Niki           [E_本稼動_02637]顧客品目コード重複登録対応
 *
 *****************************************************************************************/
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
  -- ===============================
  -- グローバル変数
  -- ===============================
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  gv_msg_part VARCHAR2(100) := ' : ';
  gv_msg_cont CONSTANT VARCHAR2(3) := '.';
--
  gv_cnst_period         CONSTANT VARCHAR2(1)   := '.';                 -- ピリオド
  gv_cnst_err_msg_space  CONSTANT VARCHAR2(6)   := '      ';            -- スペース
  gv_pkg_name                                 CONSTANT VARCHAR2(100) := 'XXCOS_COMMON_PKG';  -- パッケージ名
  gv_cust_code_no10                           CONSTANT VARCHAR2(100) := '10'; --顧客区分（顧客）
  gv_cust_code_no18                           CONSTANT VARCHAR2(100) := '18'; --顧客区分（チェーン店）
  gv_edi_district_code_no1                    CONSTANT VARCHAR2(100) := '1';  --EDI連携品目（顧客商品コード）
  gv_edi_district_code_no2                    CONSTANT VARCHAR2(100) := '2';  --EDI連携品目（JANコード）
  --
  gv_param_err                                CONSTANT VARCHAR2(2) := '01';   --入力パラメータエラー
  gv_no_data_found_err                        CONSTANT VARCHAR2(2) := '02';   --対象データなしエラー
  --
/* 2010/04/15 Ver1.7 Add Start */
  gv_char_y                                   CONSTANT VARCHAR2(1) := 'Y';
/* 2010/04/15 Ver1.7 Add End   */
  gv_char_n                                   CONSTANT VARCHAR2(1) := 'N';
  gv_char_double_cort                         CONSTANT VARCHAR2(1) := chr( 34 ); --ダブルコーテーション
  gv_char_comma                               CONSTANT VARCHAR2(1) := chr( 44 ); --カンマ
  gv_char_period                              CONSTANT VARCHAR2(1) := chr( 46 ); --ピリオド
  gv_char_space                               CONSTANT VARCHAR2(1) := ' ';       --空白
  gv_retcode_ok                               CONSTANT VARCHAR2(1) := ' ';    --戻り値正常
  gv_retcode_ng                               CONSTANT VARCHAR2(1) := 'E';    --戻り値異常
  --
  cv_number_null                              CONSTANT VARCHAR2(1) := '0';       --数値NULL
  cv_date_null                                CONSTANT VARCHAR2(8) := '00000000';--時間NULL
/* 2010/07/14 Ver1.9 Add Start */
  cv_flag_0                                   CONSTANT VARCHAR2(1) := '0';       --0:初期値
  cv_flag_1                                   CONSTANT VARCHAR2(1) := '1';       --1:未登録
  cv_flag_2                                   CONSTANT VARCHAR2(1) := '2';       --2:複数件登録
/* 2010/07/14 Ver1.9 Add End */
--
  --レコード識別子
  gv_record_kb_d                              CONSTANT VARCHAR2(1) := 'D';    --データ
--
  --アプリケーション短縮名
  ct_xxcos_appl_short_name                    CONSTANT  fnd_application.application_short_name%TYPE
                                              := 'XXCOS';                         -- 販物短縮アプリ名
  --エラーメッセージ出力エリア
  gv_application                              CONSTANT VARCHAR2(5)  := 'XXCOS';  --アプリケーション名
  gv_app_xxcos1_00019                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00019';
  gv_app_xxcos1_00040                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00040';
  gv_app_xxcos1_00071                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00071';
  gv_app_xxcos1_00072                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00072';
  gv_app_xxcos1_00073                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00073';
  gv_app_xxcos1_00102                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00102';
  gv_app_xxcos1_00103                         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00103';
  --
  ct_msg_customer_id                          CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13583';              -- 顧客マスタ検索エラー
  ct_msg_cust_item_code                       CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13585';              -- 顧客品目検索エラー
  ct_msg_jan_code                             CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13586';              -- JANコード検索エラー
  ct_msg_in_uom_code                          CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13587';              -- 入力パラメータ単位コード不正
--****************************** 2009/04/16 1.4 T.Kitajima ADD START ******************************--
  ct_msg_jan_null_err                         CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13590';              -- JANコードNULLエラー
  ct_msg_case_jan_null_err                    CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13591';              -- ケースJANコードNULLエラー
--****************************** 2009/04/16 1.4 T.Kitajima ADD  ENd  ******************************--
/* 2009/06/15 Ver1.5 Add Start */
  ct_msg_bad_calculation_err                  CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13592';              -- 出荷数量、欠品数量、計算不可エラー
/* 2009/06/15 Ver1.5 Add End   */
/* 2010/04/15 Ver1.7 Add Start */
  ct_msg_parameter_err                        CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-00006';              -- 必須入力パラメータ未設定エラーメッセージ
  ct_msg_no_data_found                        CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-00064';              -- 取得エラー
  ct_msg_account_number                       CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-00053';              -- メッセージ用文字列:顧客コード
  ct_msg_target_date                          CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13558';              -- メッセージ用文字列:基準日
  ct_msg_org_id                               CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-00047';              -- メッセージ用文字列:MO:営業単位
  ct_msg_base_code                            CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-00055';              -- メッセージ用文字列:拠点コード
  ct_msg_set_employee                         CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13594';              -- 担当営業員拠点最上位者設定メッセージ
  ct_msg_unset_employee                       CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13595';              -- 担当営業員拠点最上位者取得エラー
/* 2010/07/14 Ver1.9 Add Start */
  ct_msg_c_item_code_too_many                 CONSTANT  fnd_new_messages.message_name%TYPE
                                                        := 'APP-XXCOS1-13596';              -- 顧客品目TOO_MANYエラー
/* 2010/07/14 Ver1.9 Add End */
 -- トークン
  gv_token_name_layout                        CONSTANT VARCHAR2(6)  := 'LAYOUT';
  gv_token_name_in_param                      CONSTANT VARCHAR2(8)  := 'IN_PARAM';
  --
  cv_tkn_edi_chain_code                       CONSTANT  VARCHAR2(100) := 'EDI_CHAIN_CODE';      -- EDIチェーン店コード
  cv_tkn_edi_item_code_div                    CONSTANT  VARCHAR2(100) := 'EDI_ITEM_CODE_DIV';   -- EDI連携品目コード区分
  cv_tkn_uom_code                             CONSTANT  VARCHAR2(100) := 'UOM_CODE';            -- 単位コード
  cv_tkn_jan_code                             CONSTANT  VARCHAR2(100) := 'JAN_CODE';            -- JANコード
--****************************** 2009/04/16 1.4 T.Kitajima ADD START ******************************--
  cv_tkn_item_code                            CONSTANT  VARCHAR2(100) := 'ITEM_CODE';           -- 品目コード
--****************************** 2009/04/16 1.4 T.Kitajima ADD  ENd  ******************************--
/* 2010/04/15 Ver1.7 Add Start */
  cv_tkn_data                                 CONSTANT  VARCHAR2(100) := 'DATA';                -- DATA
  cv_tkn_base                                 CONSTANT  VARCHAR2(100) := 'BASE';                -- 拠点コード
  cv_tkn_cust                                 CONSTANT  VARCHAR2(100) := 'CUST';                -- 顧客コード
  cv_tkn_sdate                                CONSTANT  VARCHAR2(100) := 'SDATE';               -- 基準日
  cv_tkn_emp                                  CONSTANT  VARCHAR2(100) := 'EMP';                 -- 最上位者従業員番号
/* 2010/04/15 Ver1.7 Add End   */
  --
  --プロファイルID
  ct_prof_case_uom_code                       CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                                         := 'XXCOS1_CASE_UOM_CODE';          -- ケース単位コード

--
  -- ===============================
  -- 共通例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--
  /************************************************************************
   * Function Name   : get_unit_price
   * Description     : 単価取得関数
   ************************************************************************/
  FUNCTION get_unit_price(
     in_inventory_item_id      IN           NUMBER                           -- Disc品目ID
    ,in_price_list_header_id   IN           NUMBER                           -- 価格表ヘッダID
    ,iv_uom_code               IN           VARCHAR2                         -- 単位コード
  ) RETURN  NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_price'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 価格表固定値
    cv_y                      CONSTANT   VARCHAR2(1)    :=  'Y';
    cv_pll                    CONSTANT   VARCHAR2(3)    :=  'PLL';
    cv_prl                    CONSTANT   VARCHAR2(3)    :=  'PRL';
    cv_line                   CONSTANT   VARCHAR2(4)    :=  'LINE';
    cv_c                      CONSTANT   VARCHAR2(1)    :=  'C';
    cv_unit_price             CONSTANT   VARCHAR2(10)   :=  'UNIT_PRICE';
    cv_item                   CONSTANT   VARCHAR2(4)    :=  'ITEM';
    cv_modlist                CONSTANT   VARCHAR2(7)    :=  'MODLIST';
    cv_order                  CONSTANT   VARCHAR2(5)    :=  'ORDER';
    -- 製品属性
    cv_product_attribute1     CONSTANT   VARCHAR2(18)   :=  'PRICING_ATTRIBUTE1';  -- 品目番号
    cv_product_attribute3     CONSTANT   VARCHAR2(18)   :=  'PRICING_ATTRIBUTE3';  -- AllItems
    -- QUALIFIER_ATTRIBUTE
    cv_qf_attribute4          CONSTANT   VARCHAR2(21)   :=  'QUALIFIER_ATTRIBUTE4';
    cv_qf_attribute11         CONSTANT   VARCHAR2(22)   :=  'QUALIFIER_ATTRIBUTE11';
    -- 業務日付
    cd_process_date           CONSTANT   DATE           :=  xxccp_common_pkg2.get_process_date;
--
    -- *** ローカル変数 ***
    ln_list_header_id                    qp_list_headers_b.list_header_id%TYPE;        -- 価格表ヘッダID
    ln_unit_price                        qp_list_lines.operand%TYPE;                   -- 単価
    ln_product_attribute                 qp_pricing_attributes.product_attribute%TYPE; -- 製品属性
    ln_inventory_item_id                 mtl_system_items_b.inventory_item_id%TYPE;    -- Disc品目ID
    lv_uom_code                          mtl_system_items_b.primary_uom_code%TYPE;     -- 単位コード
    --
    ln_price_list_cnt                    NUMBER DEFAULT 0;                             -- 第二価格表件数
    --
    ln_check_flg                         VARCHAR2(1);                                  -- 内部フラグ
--
    -- *** ローカル・カーソル ***
    -- 第二価格表
    CURSOR sec_price_list_cur( ln_arg_inventory_item_id NUMBER
                              ,ln_arg_list_header_id    NUMBER
                              ,lv_arg_uom_code          VARCHAR2)
    IS
        SELECT
           qll.operand           unit_price     -- 単価
        FROM
           qp_list_headers_b     qphb           -- 価格表ヘッダ
          ,qp_qualifiers         qpqr           -- クオリファイア
          ,qp_list_lines         qll            -- 価格表明細
          ,qp_pricing_attributes qpa            -- 価格表詳細
        WHERE
               qpqr.qualifier_attr_value      =  TO_CHAR( ln_arg_list_header_id )
          AND  TO_CHAR( qphb.list_header_id ) <> qpqr.qualifier_attr_value
          AND  qphb.list_header_id            =  qpqr.list_header_id
          AND  ((( qphb.start_date_active     IS NOT NULL )
            AND  ( qphb.start_date_active     <= cd_process_date  ))
              OR ( qphb.start_date_active     IS NULL     ))
          AND  ((( qphb.end_date_active       IS NOT NULL )
            AND  ( qphb.end_date_active       >= cd_process_date  ))
              OR ( qphb.end_date_active       IS NULL     ))
          AND  qphb.list_header_id            =  qll.list_header_id
          AND  ((( qll.start_date_active      IS NOT NULL )
            AND  ( qll.start_date_active      <= cd_process_date  ))
              OR ( qll.start_date_active      IS NULL     ))
          AND  ((( qll.end_date_active        IS NOT NULL )
            AND  ( qll.end_date_active        >= cd_process_date  ))
              OR ( qll.end_date_active        IS NULL     ))
          AND  qll.list_line_id               =  qpa.list_line_id
          AND  qll.list_line_type_code        =  cv_pll
          AND  qll.modifier_level_code        =  cv_line
          AND  qpa.product_attribute_datatype =  cv_c
          AND  qll.arithmetic_operator        =  cv_unit_price
          AND  qpa.product_attribute_context  =  cv_item
          AND  qpa.product_uom_code           =  lv_arg_uom_code
          AND  qpa.product_attr_value         =  decode ( qpa.product_attribute
                                                         ,cv_product_attribute1
                                                         ,to_char( ln_arg_inventory_item_id )
                                                         ,qpa.product_attr_value )
          AND  qphb.list_type_code            =  cv_prl
          AND  qpqr.qualifier_rule_id         IS NULL
          AND ( ( qpqr.qualifier_context      =  cv_modlist
              AND qpqr.qualifier_attribute    =  cv_qf_attribute4)
            OR ( qpqr.qualifier_context       =  cv_order
              AND qpqr.qualifier_attribute    =  cv_qf_attribute11) )
        ORDER BY
           qpqr.qualifier_precedence
          ,qll.product_precedence
        ;
--
    -- *** ローカル・レコード ***
--
    -- ================
    -- ユーザー定義例外
    -- ================
    price_list_err_expt                       EXCEPTION;                 --引数エラー
--
  BEGIN
  --
    --入力パラメータチェック
    IF (( in_inventory_item_id    IS NULL )
      OR
        ( in_price_list_header_id IS NULL )
      OR
        ( iv_uom_code             IS NULL ))
    THEN
      RETURN -1;
    ELSE
      ln_inventory_item_id  := in_inventory_item_id;
      ln_list_header_id     := in_price_list_header_id;
      lv_uom_code           := iv_uom_code;
    END IF;
    --
    --価格表の検索（第一価格表） 優先度の一番高いもの１つだけ
    BEGIN
      SELECT  up.unit_price           unit_price     -- 単価
      INTO    ln_unit_price
      FROM (
        SELECT  qll.operand           unit_price     -- 単価

        FROM    qp_list_headers_b     qlhb           -- 価格表ヘッダ
               ,qp_list_lines         qll            -- 価格表明細
               ,qp_pricing_attributes qpa            -- 価格表詳細
        WHERE   qlhb.list_header_id            = ln_list_header_id
          AND   qlhb.active_flag               = cv_y
          AND  ((( qlhb.start_date_active     IS NOT NULL )
            AND  ( qlhb.start_date_active     <= cd_process_date  ))
              OR ( qlhb.start_date_active     IS NULL     ))
          AND  ((( qlhb.end_date_active       IS NOT NULL )
            AND  ( qlhb.end_date_active       >= cd_process_date  ))
              OR ( qlhb.end_date_active       IS NULL     ))
          AND   qll.list_header_id             = qlhb.list_header_id
          AND  ((( qll.start_date_active      IS NOT NULL )
            AND  ( qll.start_date_active      <= cd_process_date  ))
              OR ( qll.start_date_active      IS NULL     ))
          AND  ((( qll.end_date_active        IS NOT NULL )
            AND  ( qll.end_date_active        >= cd_process_date  ))
              OR ( qll.end_date_active        IS NULL     ))
          AND   qll.list_line_id               = qpa.list_line_id
          AND   qll.list_line_type_code        = cv_pll
          AND   qll.modifier_level_code        = cv_line
          AND   qpa.product_attribute_datatype = cv_c
          AND   qll.arithmetic_operator        = cv_unit_price
          AND   qpa.product_attribute_context  = cv_item
          AND   qpa.product_attribute          IN ( cv_product_attribute1 ,cv_product_attribute3 )
          AND   qpa.product_uom_code           = lv_uom_code
          AND   qpa.product_attr_value         =  decode ( qpa.product_attribute
                                                          ,cv_product_attribute1
                                                          ,to_char( ln_inventory_item_id )
                                                          ,qpa.product_attr_value )
        ORDER BY
          qll.product_precedence
        ) up
      WHERE  ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_check_flg := 'Y';
      WHEN OTHERS THEN
        RETURN -2;
    END;
    -- DEBUG
--
    -- 見つからなかった場合は、
    IF ( ln_check_flg = 'Y' ) THEN
      -- DEBUG
--
      -- 価格表の検索（第二価格表）優先度の一番高いもの１つだけ
      --
      <<main_loop>>
      FOR sec_price_list_rec IN sec_price_list_cur( ln_inventory_item_id
                                                   ,ln_list_header_id
                                                   ,lv_uom_code         )
      LOOP
        ln_unit_price:=sec_price_list_rec.unit_price;
        ln_price_list_cnt := sec_price_list_cur%ROWCOUNT;
        --
        IF ( ln_price_list_cnt = 1 ) THEN
          EXIT main_loop;
        END IF;
      END LOOP main_loop;
      --
      IF ( ln_price_list_cnt = 0 ) THEN
        RETURN -3;
      ELSE
        RETURN ln_unit_price;
      END IF;
    ELSE
      RETURN ln_unit_price;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   ##########################################
--
  END get_unit_price;
--
--
--
  /**********************************************************************************
   * Procedure Name   : conv_ebs_cust_code
   * Description      : 顧客コード変換（EDI→EBS)
   ***********************************************************************************/
  PROCEDURE conv_ebs_cust_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDIチェーン店コード
              ,iv_store_code                       IN  VARCHAR2 DEFAULT NULL  --店コード
              ,ov_account_number                   OUT NOCOPY VARCHAR2        --顧客コード
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラーメッセージ              #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターンコード                #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ  #固定#
              )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
                                                                              --プログラム
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'conv_ebs_cust_code';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --メッセージエリア
   -- ================
    -- ユーザー定義例外
    -- ================
    iv_param_expt                                      EXCEPTION;             --引数エラー
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
    --プログラム名設定
    --出力引数初期化
    ov_retcode  := xxccp_common_pkg.set_status_normal;
    --入力引数チェック<EDIチェーン店コード:店コード>
    IF   ( iv_edi_chain_code IS NULL )
      OR ( iv_store_code     IS NULL )
    THEN
      lv_message1 := gv_param_err;
      RAISE iv_param_expt;
    END IF;
    --
    -- EDIチェーン店コードと店舗コードから顧客コードを検索
    BEGIN
      SELECT
        hca.account_number                                                      --顧客コード
      INTO
        ov_account_number
      FROM
        HZ_CUST_ACCOUNTS hca,                                                   --顧客マスタ
        XXCMM_CUST_ACCOUNTS xca                                                 --顧客追加情報
      WHERE hca.cust_account_id     = xca.customer_id                           --顧客顧客ID
        AND hca.customer_class_code = gv_cust_code_no10                         --顧客区分
        AND xca.chain_store_code    = iv_edi_chain_code                         --EDIチェーン店コード
        AND xca.store_code          = iv_store_code                             --店舗コード
      ;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        lv_message1 := gv_no_data_found_err;
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
      WHEN NO_DATA_FOUND THEN
        lv_message1 := gv_no_data_found_err;
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- *** 引数エラー ***
    WHEN iv_param_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END conv_ebs_cust_code;
--
--
  /**********************************************************************************
   * Procedure Name   : conv_edi_item_code
   * Description      : 品目コード変換（EBS→EDI)
   ***********************************************************************************/
  --品目コード変換（EBS→EDI)
  PROCEDURE conv_edi_item_code(
               iv_edi_chain_code                   IN  VARCHAR2 DEFAULT NULL  --EDIチェーン店コード
              ,iv_item_code                        IN  VARCHAR2 DEFAULT NULL  --品目コード
              ,iv_organization_id                  IN  VARCHAR2 DEFAULT NULL  --在庫組織ID
              ,iv_uom_code                         IN  VARCHAR2 DEFAULT NULL  --単位コード
              ,ov_product_code2                    OUT NOCOPY VARCHAR2        --商品コード２
              ,ov_jan_code                         OUT NOCOPY VARCHAR2        --JANコード
              ,ov_case_jan_code                    OUT NOCOPY VARCHAR2        --ケースJANコード
/* 2010/07/14 Ver1.9 Add Start */
              ,ov_err_flag                         OUT NOCOPY VARCHAR2        --エラー種別
/* 2010/07/14 Ver1.9 Add End */
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラーメッセージ              #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターンコード                #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ  #固定#
              )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'conv_edi_item_code';  --プログラム
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --メッセージエリア
                                                                              --判定用EDI連携品目コード区分
    ln_customer_id                                     xxcmm_cust_accounts.customer_id%TYPE;
                                                                              --判定用顧客ID
    lv_edi_item_code_div                               xxcmm_cust_accounts.edi_item_code_div%TYPE;
    --
    lv_case_uom_code                                   mtl_units_of_measure_tl.uom_code%TYPE; -- ケース単位コード
    --
    lv_uom_code                                        mtl_units_of_measure_tl.uom_code%TYPE; -- 単位コード
/* 2010/07/14 Ver1.9 Add Start */
    lv_account_number                                  hz_cust_accounts.account_number%TYPE;  -- 顧客コード
/* 2010/07/14 Ver1.9 Add End */
    -- ================
    -- ユーザー定義例外
    -- ================
    lv_err_expt                                        EXCEPTION;             --マスタデータ無し
/* 2010/07/14 Ver1.9 Add Start */
    lv_err_no_data_found_expt                          EXCEPTION;             --NO_DATA_FOUNDエラー
    lv_err_too_many_expt                               EXCEPTION;             --TOO_MANY_ROWSエラー
/* 2010/07/14 Ver1.9 Add End */
    iv_param_expt                                      EXCEPTION;             --引数エラー
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
    --出力引数初期化
    ov_retcode  := xxccp_common_pkg.set_status_normal;
/* 2010/07/14 Ver1.9 Add Start */
    ov_err_flag := cv_flag_0;
/* 2010/07/14 Ver1.9 Add End */
--
    --入力引数チェック<EDIチェーン店コード:商品コード２:在庫組織ID>
    IF  (( iv_edi_chain_code   IS NULL )
      OR ( iv_item_code        IS NULL )
      OR ( iv_organization_id  IS NULL ))
    THEN
      lv_message1 := gv_param_err;
      RAISE iv_param_expt;
    END IF;
    --
    -- EDI連携品目コード区分の取得
    BEGIN
      SELECT
        xca.edi_item_code_div,                                                --EDI連携品目コード区分
/* 2010/07/14 Ver1.9 Mod Start */
--        xca.customer_id                                                       --顧客ID
        xca.customer_id,                                                       --顧客ID
        hca.account_number                                                     --顧客コード
/* 2010/07/14 Ver1.9 Mod End */
      INTO
        lv_edi_item_code_div,
/* 2010/07/14 Ver1.9 Mod Start */
--        ln_customer_id
        ln_customer_id,
        lv_account_number
/* 2010/07/14 Ver1.9 Mod End */
      FROM
        hz_cust_accounts hca,                                                 --顧客マスタ
        xxcmm_cust_accounts xca                                               --顧客追加情報
      WHERE hca.cust_account_id     = xca.customer_id                         --顧客顧客ID
        AND hca.customer_class_code = gv_cust_code_no18                       --顧客区分
        AND xca.edi_chain_code      = iv_edi_chain_code                       --EDIチェーン店コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 対象データなしエラー(顧客)
        lv_message1 := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_customer_id,
                         iv_token_name1        => cv_tkn_edi_chain_code,
                         iv_token_value1       => iv_edi_chain_code
                       );
        RAISE lv_err_expt;
    END;
    --
    -- 顧客品目の場合
    CASE lv_edi_item_code_div
      WHEN gv_edi_district_code_no1 THEN
        BEGIN
          SELECT
            mci.customer_item_number                                            --顧客品目コード
          INTO
            ov_product_code2
          FROM
            mtl_customer_items       mci,                                       --顧客品目
            mtl_customer_item_xrefs  mcix,                                      --顧客品目相互参照
            mtl_system_items_b       msib                                       --DISC品目
          WHERE mci.customer_id          = ln_customer_id                       --顧客ID
            AND mci.attribute1           = NVL(iv_uom_code, mci.attribute1 )    --単位コード(発注単位)
/* 2009/10/02 Ver1.6 Add Start */
            AND mci.inactive_flag        = gv_char_n                            --有効フラグ
/* 2009/10/02 Ver1.6 Add  End  */
            AND mci.customer_item_id     = mcix.customer_item_id                --顧客品目ID
/* 2009/10/02 Ver1.6 Add Start */
            AND mcix.inactive_flag       = gv_char_n                            --有効フラグ
            AND mcix.preference_number   = (
                  SELECT MIN(mcix_ck.preference_number) min_preference_number
                  FROM   mtl_customer_item_xrefs        mcix_ck
                        ,mtl_customer_items             mci_ck
                  WHERE  mcix_ck.inventory_item_id = mcix.inventory_item_id
                  AND    mcix_ck.inactive_flag     = gv_char_n
                  AND    mci_ck.customer_item_id   = mcix_ck.customer_item_id
                  AND    mci_ck.customer_id        = mci.customer_id
                  AND    mci_ck.attribute1         = mci.attribute1
                  AND    mci_ck.inactive_flag      = gv_char_n
                )                                                               --ランク
/* 2009/10/02 Ver1.6 Add  End  */
            AND msib.inventory_item_id   = mcix.inventory_item_id               --品目ID
            AND msib.organization_id     = iv_organization_id                   --組織ID
            AND msib.segment1            = iv_item_code                         --品目コード
/* 2009/02/20 Ver1.1 Del Start */
--          AND msib.primary_uom_code    = NVL(iv_uom_code, mci.attribute1 )    --単位コード(第1単位)
/* 2009/02/20 Ver1.1 Del  End  */
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_cust_item_code,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
/* 2009/10/02 Ver1.6 Mod Start */
--                             iv_token_name2        => cv_tkn_uom_code,
--                             iv_token_value2       => iv_uom_code
/* 2010/07/14 Ver1.9 Mod Start */
--                             iv_token_name2        => cv_tkn_item_code,
--                             iv_token_value2       => iv_item_code,
--                             iv_token_name3        => cv_tkn_uom_code,
--                             iv_token_value3       => iv_uom_code
                             iv_token_name2        => cv_tkn_cust,
                             iv_token_value2       => lv_account_number,
                             iv_token_name3        => cv_tkn_item_code,
                             iv_token_value3       => iv_item_code,
                             iv_token_name4        => cv_tkn_uom_code,
                             iv_token_value4       => iv_uom_code
/* 2010/07/14 Ver1.9 Mod End */
/* 2009/10/02 Ver1.6 Mod  End  */
                           );
/* 2010/07/14 Ver1.9 Mod Start */
--            RAISE lv_err_expt;
            ov_err_flag := cv_flag_1;
            RAISE lv_err_no_data_found_expt;
/* 2010/07/14 Ver1.9 Mod End */
/* 2010/07/14 Ver1.9 Add Start */
          WHEN TOO_MANY_ROWS THEN
            -- 複数レコード取得時エラー
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_c_item_code_too_many,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_cust,
                             iv_token_value2       => lv_account_number,
                             iv_token_name3        => cv_tkn_item_code,
                             iv_token_value3       => iv_item_code,
                             iv_token_name4        => cv_tkn_uom_code,
                             iv_token_value4       => iv_uom_code
                           );
            ov_err_flag := cv_flag_2;
            RAISE lv_err_too_many_expt;
/* 2010/07/14 Ver1.9 Add End */
        END;
      -- JANコードの場合
      WHEN gv_edi_district_code_no2 THEN
        -- CS単位コードの取得
        lv_case_uom_code := FND_PROFILE.VALUE( ct_prof_case_uom_code );
        --
        -- JANコードの取得
        BEGIN
          SELECT
            iimb.attribute21,                                                     --JANコード
            xsib.case_jan_code,                                                   --ケースJANコード
            iimb.item_um
          INTO
            ov_jan_code,
            ov_case_jan_code,
            lv_uom_code
          FROM
            ic_item_mst_b iimb,                                                   --OPM品目
            xxcmm_system_items_b xsib                                             --DISC品目アドオン
          WHERE iimb.item_no          = iv_item_code                              --品目コード
            AND iimb.item_id          = xsib.item_id                              --品目ID
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_jan_code,
                             iv_token_name1        => cv_tkn_edi_chain_code,
/* 2009/10/02 Ver1.6 Mod Start */
--                             iv_token_value1       => iv_edi_chain_code
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_item_code,
                             iv_token_value2       => iv_item_code
/* 2009/10/02 Ver1.6 Mod  End  */
                           );
            RAISE lv_err_expt;
        END;
        --
--****************************** 2009/04/16 1.4 T.Kitajima MOD START ******************************--
--        -- 入力パラメータ「単位コード」により、商品コード２にセットする値を変えます
--        IF ( iv_uom_code = lv_case_uom_code ) THEN
--          -- 単位「CS」の場合
--          ov_product_code2 := ov_case_jan_code;
--        ELSIF ( lv_uom_code = lv_uom_code ) THEN
--          -- 単位が品目マスタの単位と同じ場合
--          ov_product_code2 := ov_jan_code;
--        ELSE
--          -- 上記以外の場合->エラー
--          lv_message1 := xxccp_common_pkg.get_msg(
--                           iv_application        => ct_xxcos_appl_short_name,
--                           iv_name               => ct_msg_in_uom_code,
--                           iv_token_name1        => cv_tkn_edi_chain_code,
--                           iv_token_value1       => iv_edi_chain_code,
--                           iv_token_name2        => cv_tkn_jan_code,
--                           iv_token_value2       => ov_jan_code,
--                           iv_token_name3        => cv_tkn_uom_code,
--                           iv_token_value3       => iv_uom_code
--                         );
--          RAISE lv_err_expt;
--        END IF;
--
        -- 入力パラメータ「単位コード」により、商品コード２にセットする値を変えます
        IF ( iv_uom_code = lv_case_uom_code ) THEN
          -- 単位「CS」の場合
          --ケースJANコードがNULLの場合エラー
          IF ( ov_case_jan_code IS NULL ) THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_case_jan_null_err,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_item_code,
                             iv_token_value2       => iv_item_code
                           );
            RAISE lv_err_expt;
          END IF;
          ov_product_code2 := ov_case_jan_code;
        ELSE 
          -- 単位が品目マスタの単位と同じ場合
          IF ( ov_jan_code IS NULL ) THEN
            lv_message1 := xxccp_common_pkg.get_msg(
                             iv_application        => ct_xxcos_appl_short_name,
                             iv_name               => ct_msg_jan_null_err,
                             iv_token_name1        => cv_tkn_edi_chain_code,
                             iv_token_value1       => iv_edi_chain_code,
                             iv_token_name2        => cv_tkn_item_code,
                             iv_token_value2       => iv_item_code
                           );
            RAISE lv_err_expt;
          END IF;
          ov_product_code2 := ov_jan_code;
        END IF;
--****************************** 2009/04/16 1.4 T.Kitajima MOD  END  ******************************--
      ELSE
        -- EDI連携品目コード区分の不正
        lv_message1 := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_customer_id,
                         iv_token_name1        => cv_tkn_edi_chain_code,
                         iv_token_value1       => iv_edi_chain_code,
                         iv_token_name2        => cv_tkn_edi_item_code_div,
                         iv_token_value2       => lv_edi_item_code_div
                       );
        RAISE lv_err_expt;
    END CASE;
--
  EXCEPTION
--
    -- *** 引数エラー ***
    WHEN iv_param_expt  THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 商品コード変換エラー ***
    WHEN lv_err_expt    THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
/* 2010/07/14 Ver1.9 Add Start */
    -- *** NO_DATA_FOUNDエラー ***
    WHEN lv_err_no_data_found_expt    THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_message1,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_warn;
    -- *** TOO_MANY_ROWSエラー ***
    WHEN lv_err_too_many_expt    THEN
      ov_errmsg  := lv_message1;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_message1,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_warn;
/* 2010/07/14 Ver1.9 Add End */
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END conv_edi_item_code;
--
--
  /**********************************************************************************
   * Procedure Name   : get_layout_info
   * Description      : レイアウト定義情報取得
   ***********************************************************************************/
  --レイアウト定義情報取得
  PROCEDURE get_layout_info(
               iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --ファイル形式
              ,iv_layout_class                     IN  VARCHAR2 DEFAULT NULL  --レイアウト区分
              ,ov_data_type_table                  OUT NOCOPY g_record_layout_ttype  --データ型表
              ,ov_csv_header                       OUT NOCOPY VARCHAR2        --CSVヘッダ
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラーメッセージ              #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターンコード                #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ  #固定#
              )
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
                                                                              --プログラム
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_layout_info';
    --レイアウト区分対応表定義
    cv_layout_type_order                      CONSTANT VARCHAR2(100) := 'XXCOS1_OM_TAB_COLUMNS';
                                                                              --受注系
    cv_layout_type_stock                      CONSTANT VARCHAR2(100) := 'XXCOS1_INV_TAB_COLUMNS';
                                                                              --在庫
    --
    cv_token_file_type                        CONSTANT VARCHAR2(12) := 'iv_file_type';
    cv_token_layout_class                     CONSTANT VARCHAR2(15) := 'iv_layout_class';
    --
    cv_apl_name                               CONSTANT VARCHAR2(100) := 'XXCOS'; --アプリケーション名
    ct_rec_type                               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00159';        --メッセージ用文字列.レコード識別子
--add start 1/21
    ct_prf_if_data                            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';--XXCCP:データレコード識別子
--add end 1/21
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --メッセージエリア
    lv_prg_name                                        VARCHAR2(100);         --メッセージ用プログラム名設定エリア
    lv_csv_header                                      VARCHAR2(32767);       --ヘッダ編集エリア
    lv_token                                           VARCHAR2(100);         --トークン文字列
    i                                                  NUMBER;                --添字
                                                                              --型定義
    lv_look_up                                         fnd_lookup_values.lookup_type%type;
    lv_layout                                          VARCHAR2(100);         --メッセージ編集エリア
    lt_rec_type                       fnd_new_messages.message_text%TYPE;     --メッセージ出力エリア：レコード識別子
    -- PL/SQL表型
    l_data_ttype g_record_layout_ttype;
--
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    CURSOR
      cur_xlvv
    IS
    SELECT
      xlvv.lookup_code,                                                       --コード
      xlvv.meaning,                                                           --内容
      xlvv.description,                                                       --摘要
      xlvv.attribute1,                                                        --DEF1
      xlvv.attribute2                                                         --DEF2
    FROM
      xxcos_lookup_values_v xlvv                                                  --クイックコード
    WHERE lv_look_up    = xlvv.lookup_type                                    --情報区分
    ORDER BY xlvv.lookup_code                                                 --ソート順/コード
    ;
    -- ================
    -- ユーザー定義例外
    -- ================
    iv_param_expt                                      EXCEPTION;             --引数エラー
--
  BEGIN
--
    --プログラム名設定
    lv_prg_name := gv_pkg_name || cv_prg_name;
    --出力引数初期化
    ov_retcode  := xxccp_common_pkg.set_status_normal;
    --入力引数チェック<ファイル形式>
    IF  ( iv_file_type != gv_file_type_fix )                                   --固定長
    AND ( iv_file_type != gv_file_type_variable )                              --可変長
      THEN
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00019
                                               ,iv_token_name1     => gv_token_name_in_param
                                               ,iv_token_value1    => cv_token_file_type
                                               );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END IF;
    --入力引数チェック<レイアウト区分：カーソル抽出対象設定>
    CASE iv_layout_class
      WHEN gv_layout_class_order THEN                                         --受注系
        lv_look_up := cv_layout_type_order;
      WHEN gv_layout_class_stock THEN                                         --在庫
        lv_look_up := cv_layout_type_stock;
      ELSE
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00019
                                               ,iv_token_name1     => gv_token_name_in_param
                                               ,iv_token_value1    => cv_token_layout_class
                                               );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END CASE;
    --
    --
    BEGIN
--add start 1/21
      lt_rec_type := FND_PROFILE.VALUE(ct_prf_if_data);
--add end 1/21
      OPEN  cur_xlvv;                                                           --カーソルOPEN
      FETCH cur_xlvv BULK COLLECT INTO l_data_ttype;                            --カーソルFETCH
      CLOSE cur_xlvv;                                                           --カーソルCLOSE
      --
      FOR i in 1..l_data_ttype.count LOOP
      --出力情報編集
        ov_data_type_table(i).lookup_code   := l_data_ttype(i).lookup_code;
        ov_data_type_table(i).meaning       := l_data_ttype(i).meaning;
        ov_data_type_table(i).description   := l_data_ttype(i).description;
        ov_data_type_table(i).attribute1    := l_data_ttype(i).attribute1;
        ov_data_type_table(i).attribute2    := l_data_ttype(i).attribute2;
      --
      --ファイル形式可変時のみCSVヘッダ作成
        IF ( iv_file_type = gv_file_type_variable ) THEN
          IF ( i = 1 ) THEN
            --メッセージ文字列(レコード識別子)取得
--del start 1/21
--            lt_rec_type  := xxccp_common_pkg.get_msg(cv_apl_name, ct_rec_type);
--del end 1/21
            lv_csv_header                     := gv_char_double_cort
                                              || lt_rec_type 
                                              || gv_char_double_cort
                                              || gv_char_comma;
          END IF;
          lv_csv_header                       := lv_csv_header
                                              || gv_char_double_cort
                                              || l_data_ttype(i).description
                                              || gv_char_double_cort
                                              || gv_char_comma;
        END IF;
      --
      END LOOP;
      --
      IF ( iv_file_type = gv_file_type_variable ) THEN
        ov_csv_header := SUBSTRB( lv_csv_header
                                , 1
                                , LENGTHB( lv_csv_header ) - 1
                                );
      ---
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        --
        CASE iv_layout_class
          WHEN gv_layout_class_order THEN
            lv_token  := xxccp_common_pkg.get_msg( iv_application => gv_application
                                                   ,iv_name        => gv_app_xxcos1_00071
                                                  );
          WHEN gv_layout_class_stock THEN
            lv_token  := xxccp_common_pkg.get_msg( iv_application => gv_application
                                                   ,iv_name        => gv_app_xxcos1_00072
                                                  );
          --ELSE
        END CASE;
        lv_errmsg  := xxccp_common_pkg.get_msg( iv_application     => gv_application
                                               ,iv_name            => gv_app_xxcos1_00040
                                               ,iv_token_name1     => gv_token_name_layout
                                               ,iv_token_value1    => lv_token
                                               );
        lv_errbuf := lv_errmsg;
        RAISE  global_api_expt;
    END;
    --
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := xxccp_common_pkg.set_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_layout_info;
--
  /**********************************************************************************
   * Procedure Name   : makeup_data_record
   * Description      : データレコード編集
   ***********************************************************************************/
  --データレコード編集
  PROCEDURE makeup_data_record(
               iv_edit_data                        IN  g_layout_ttype         --出力データ
              ,iv_file_type                        IN  VARCHAR2 DEFAULT NULL  --ファイル形式
              ,iv_data_type_table                  IN  g_record_layout_ttype  --データ型表
              ,iv_record_type                      IN  VARCHAR2 DEFAULT NULL  --レコード識別子
              ,ov_data_record                      OUT NOCOPY VARCHAR2        --データレコード
              ,ov_errbuf                           OUT NOCOPY VARCHAR2        --エラーメッセージ              #固定#
              ,ov_retcode                          OUT NOCOPY VARCHAR2        --リターンコード                #固定#
              ,ov_errmsg                           OUT NOCOPY VARCHAR2        --ユーザー・エラー・メッセージ  #固定#
              )
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
                                                                              --プログラム
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'makeup_data_record';
    cv_character                              CONSTANT VARCHAR2(4) := 'CHAR';    --文字列型
    cv_date                                   CONSTANT VARCHAR2(4) := 'DATE';    --日付型
    cv_number                                 CONSTANT VARCHAR2(6) := 'NUMBER';  --数値型
    cv_varchar                                CONSTANT VARCHAR2(7) := 'VARCHAR'; --日本語型（全角）
    cv_fmt                                    CONSTANT VARCHAR2(2) := 'FM';      --可変長出力用フォーマット
    cv_nine                                   CONSTANT VARCHAR2(1) := '9';       --<フォーマット用９>
    cv_zero                                   CONSTANT VARCHAR2(1) := '0';       --<フォーマット用０>
    cv_comma                                  CONSTANT VARCHAR2(1) := '.';       --カンマ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_message1                                        VARCHAR2(1000);        --メッセージエリア
    lv_prg_name                                        VARCHAR2(100);         --メッセージ用プログラム名設定エリア
    lv_csv_header                                      VARCHAR2(1000);        --ヘッダ編集エリア
    lv_out_unit_data                                   VARCHAR2(1000);        --出力用エリア
    lv_edit_data                                       VARCHAR2(1000);        --編集用エリア
    lv_number_type                                     VARCHAR2(1000);        --編集数値エリア
    lv_minus_data                                      VARCHAR2(1000);        --変換用エリア
    lv_number_fmt                                      VARCHAR2(100);         --可変長用フォーマット
    ln_under_point                                     NUMBER;                --小数点以下数値
    ln_power_num                                       NUMBER;                --べき乗対象値
    ln_decimal_num                                     NUMBER;                --数値エリア<整数部>
    ln_under_num                                       NUMBER;                --数値エリア<小数部>
    i                                                  binary_integer := 0;   --添字
    -- PL/SQL表型
    l_outdata_ttype g_layout_ttype;
    l_data_ttype    g_record_layout_ttype;
  --
    -- ================
    -- ユーザー定義例外
    -- ================
  --
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
  --プログラム名設定
    lv_prg_name  := gv_pkg_name || cv_prg_name;
  --出力引数初期化
    ov_retcode   := xxccp_common_pkg.set_status_normal;
  --テーブル展開
    l_data_ttype    := iv_data_type_table;
    l_outdata_ttype := iv_edit_data;
  --レコード識別子設定
    IF ( iv_file_type =  gv_file_type_fix ) THEN
                                                                              --固定長
      ov_data_record := iv_record_type;
    ELSE                                                                      --可変長
      ov_data_record := gv_char_double_cort
                        ||  iv_record_type  ||
                        gv_char_double_cort
                        ||  gv_char_comma;
    END IF;
  --
    FOR i in 1..l_data_ttype.count LOOP
    --テーブル設定なしの対応
      BEGIN
        lv_out_unit_data := l_outdata_ttype( l_data_ttype(i).meaning );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_out_unit_data := NULL;
      END;
    --< NUMBER型の小数点以下の桁数算出 >
      ln_power_num := 0;
      IF ( l_data_ttype(i).attribute1 = cv_number ) THEN
       --属性の保持
        lv_number_type     := l_data_ttype(i).attribute2;
       --小数点有無の判定エリア
        ln_under_point     := INSTRB( lv_number_type
                                     ,cv_comma
                                     ,1
                                     ,1 );
       --小数点無
        IF ( ln_under_point = 0 ) THEN
          --小数部
          ln_under_num     := 0;
          --整数部
          ln_decimal_num   := TO_NUMBER( lv_number_type );
          --可変長出力用フォーマット
          lv_number_fmt    := RPAD( cv_fmt
                                   ,ln_decimal_num + LENGTHB( cv_fmt )
                                   ,cv_nine );
       --小数点有
       ELSE
          --小数部
          ln_under_num     := TO_NUMBER( SUBSTRB( lv_number_type
                                                 ,INSTRB( lv_number_type,cv_comma,1,1 ) +1
                                                 ) );
          --整数部
          ln_decimal_num   := TO_NUMBER( SUBSTRB( lv_number_type
                                                 ,1
                                                 ,INSTRB( lv_number_type,cv_comma,1,1 ) -1
                                                 ) );
          --可変長出力用フォーマット
          lv_number_fmt    := RPAD( cv_fmt
                                   ,ln_decimal_num - 1 + LENGTHB( cv_fmt )
                                   ,cv_nine )
                           || cv_zero
                           || RPAD( cv_comma
                                   ,ln_under_num   + LENGTHB( cv_comma )
                                   ,cv_zero );
        END IF;
        --小数点以下の数値を整数に戻す倍率の算出
        ln_power_num   := 10 ** ln_under_num;
        --固定長用総桁数算出
        lv_number_type := ln_under_num  + ln_decimal_num;
      END IF;
    --出力エリア編集
      IF ( iv_file_type = gv_file_type_fix )                                  --固定長
      THEN
      --入力データ(iv_edit_data)に対象がない場合の考慮
        IF ( lv_out_unit_data IS NULL ) THEN
          IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                              ,cv_varchar ) )
          THEN
            lv_out_unit_data := gv_char_space;
          ELSE
            lv_out_unit_data := 0;
          END IF;
        END IF;
      --
        IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                            ,cv_varchar ) )
        THEN
            ov_data_record := ov_data_record
                           || RPAD( lv_out_unit_data
                                   ,l_data_ttype(i).attribute2
                                   );
        ELSIF ( l_data_ttype(i).attribute1 = cv_number )
          THEN
       --小数点以下存在チェック
            IF ( ln_under_point != 0 ) THEN
       --整数値に変換
              lv_out_unit_data := ln_power_num * to_number(lv_out_unit_data);
            END IF;
       --ゼロ以下の編集方法
            IF ( TO_NUMBER( lv_out_unit_data ) < 0 ) THEN
              lv_out_unit_data := TO_NUMBER(lv_out_unit_data) * -1;
              lv_minus_data    := LPAD( lv_out_unit_data
                                       ,lv_number_type - 1
                                       ,0 );
              ov_data_record   := ov_data_record
                               || '-'
                               || lv_minus_data ;
            ELSE
              ov_data_record   := ov_data_record
                               || LPAD( lv_out_unit_data
                                       ,lv_number_type
                                       ,0 );
            END IF;
        ELSIF ( l_data_ttype(i).attribute1 = cv_date )
          THEN
            ov_data_record     := ov_data_record
                               || LPAD( lv_out_unit_data
                                       ,l_data_ttype(i).attribute2
                                       ,0 );
      --ELSE
        END IF;
      ELSE                                                                    --可変長
--*********************************** 2009/03/31 1.3 T.Kitajima MOD START *********************************************
--        IF ( l_data_ttype(i).attribute1 IN ( cv_character
--                                            ,cv_date
--                                            ,cv_varchar ) )
        IF ( l_data_ttype(i).attribute1 IN ( cv_character
                                            ,cv_varchar ) )
--*********************************** 2009/03/31 1.3 T.Kitajima MOD  END  *********************************************
        THEN
          ov_data_record   := ov_data_record
                           || gv_char_double_cort
                           || SUBSTRB( lv_out_unit_data
                                      ,1
                                      ,l_data_ttype(i).attribute2 )
                           || gv_char_double_cort;
--*********************************** 2009/03/31 1.3 T.Kitajima ADD START *********************************************
        ELSIF l_data_ttype(i).attribute1 = cv_date
          THEN
          ov_data_record   := ov_data_record
                           || gv_char_double_cort
                           || NVL( SUBSTRB( lv_out_unit_data
                                       ,1
                                       ,l_data_ttype(i).attribute2 ),
                                   cv_date_null )
                           || gv_char_double_cort;
--*********************************** 2009/03/31 1.3 T.Kitajima ADD  END  *********************************************
        ELSIF l_data_ttype(i).attribute1 = cv_number
          THEN
            ov_data_record := ov_data_record
--*********************************** 2009/03/31 1.3 T.Kitajima MOD START *********************************************
--                           || TO_CHAR( TO_NUMBER( lv_out_unit_data ), lv_number_fmt );
                           || NVL( TO_CHAR(  TO_NUMBER( lv_out_unit_data ), lv_number_fmt ), cv_number_null);
--*********************************** 2009/03/31 1.3 T.Kitajima MOD  END  *********************************************
      --ELSE
        END IF;
      --カンマ付き
        IF ( i <  l_data_ttype.count ) THEN
            ov_data_record := ov_data_record
                           || gv_char_comma;
        END IF;
      END IF;
  --
    END LOOP;
  --
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END makeup_data_record;
  --
--
/* 2009/06/23 Ver1.5 Add Start */
  /**********************************************************************************
   * Procedure Name   : convert_quantity
   * Description      : EDI帳票向け数量換算関数
   ***********************************************************************************/
  PROCEDURE convert_quantity(
               iv_uom_code           IN  VARCHAR2  DEFAULT NULL  --単位コード
              ,in_case_qty           IN  NUMBER    DEFAULT NULL  --ケース入数
              ,in_ball_qty           IN  NUMBER    DEFAULT NULL  --ボール入数
              ,in_sum_indv_order_qty IN  NUMBER    DEFAULT NULL  --発注数量(合計・バラ)
              ,in_sum_shipping_qty   IN  NUMBER    DEFAULT NULL  --出荷数量(合計・バラ)
              ,on_indv_shipping_qty  OUT NOCOPY NUMBER           --出荷数量(バラ)
              ,on_case_shipping_qty  OUT NOCOPY NUMBER           --出荷数量(ケース)
              ,on_ball_shipping_qty  OUT NOCOPY NUMBER           --出荷数量(ボール)
              ,on_indv_stockout_qty  OUT NOCOPY NUMBER           --欠品数量(バラ)
              ,on_case_stockout_qty  OUT NOCOPY NUMBER           --欠品数量(ケース)
              ,on_ball_stockout_qty  OUT NOCOPY NUMBER           --欠品数量(ボール)
              ,on_sum_stockout_qty   OUT NOCOPY NUMBER           --欠品数量(合計・バラ)
              ,ov_errbuf             OUT NOCOPY VARCHAR2         --エラー・メッセージエラー       #固定#
              ,ov_retcode            OUT NOCOPY VARCHAR2         --リターン・コード               #固定#
              ,ov_errmsg             OUT NOCOPY VARCHAR2         --ユーザー・エラー・メッセージ   #固定#
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'convert_quantity';   --プログラム
    cn_zero                                   CONSTANT NUMBER(1)     := 0;                    --数値：0
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_case_uom_code                                   mtl_units_of_measure_tl.uom_code%TYPE; -- ケース単位コード
    --
/* 2010/05/26 Ver1.8 Add Start */
    ln_sum_indv_order_qty                              NUMBER;  -- 発注数量(合計・バラ)
    ln_sum_shipping_qty                                NUMBER;  -- 出荷数量(合計・バラ)
/* 2010/05/26 Ver1.8 Add End  */

--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
    --リターン・コード初期化
    ov_retcode := cv_status_normal;
--
    --単位コードチェック
    IF ( iv_uom_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                              ,iv_name         => ct_msg_bad_calculation_err
                                            );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2010/05/26 Ver1.8 Add Start */
    --発注数量(合計・バラ)、出荷数量(合計・バラ)がNULLの場合0とする
    ln_sum_indv_order_qty := NVL( in_sum_indv_order_qty, cn_zero );
    ln_sum_shipping_qty   := NVL( in_sum_shipping_qty, cn_zero );
/* 2010/05/26 Ver1.8 Add End */
    --ケース単位コード取得
    lv_case_uom_code := FND_PROFILE.VALUE( ct_prof_case_uom_code );
--
/* 2010/05/26 Ver1.8 Mod Start */
    --欠品数量(合計・バラ) = 発注数量(合計・バラ) - 出荷数量(合計・バラ)
--    on_sum_stockout_qty  := in_sum_indv_order_qty - in_sum_shipping_qty;
    on_sum_stockout_qty  := ln_sum_indv_order_qty - ln_sum_shipping_qty;
/* 2010/05/26 Ver1.8 Mod End   */
--
    --ケース以外の場合
    IF ( iv_uom_code <> lv_case_uom_code ) THEN
--
      --ケース入数あり、且つ、0以外
      IF ( in_case_qty IS NOT NULL )
        AND ( in_case_qty <> cn_zero )THEN
/* 2010/05/26 Ver1.8 Mod Start */
        --出荷数量(バラ)   = 出荷数量(合計・バラ) / ケース入数の余り
--        on_indv_shipping_qty := MOD( in_sum_shipping_qty, in_case_qty );
        on_indv_shipping_qty := MOD( ln_sum_shipping_qty, in_case_qty );
        --出荷数量(ケース) = 出荷数量(合計・バラ) / ケース入数の商
--        on_case_shipping_qty := TRUNC( in_sum_shipping_qty / in_case_qty );
        on_case_shipping_qty := TRUNC( ln_sum_shipping_qty / in_case_qty );
/* 2010/05/26 Ver1.8 Mod End   */
        --欠品数量(バラ)   = 欠品数量(合計・バラ) / ケース入数の余り
        on_indv_stockout_qty := MOD( on_sum_stockout_qty, in_case_qty );
        --欠品数量(ケース) = 欠品数量(合計・バラ) / ケース入数の商
        on_case_stockout_qty := TRUNC( on_sum_stockout_qty / in_case_qty );
      --ケース入数なし
      ELSE
        --出荷数量(バラ)   = 出荷数量(合計・バラ)
/* 2010/05/26 Ver1.8 Mod Start */
--        on_indv_shipping_qty := in_sum_shipping_qty;
        on_indv_shipping_qty := ln_sum_shipping_qty;
/* 2010/05/26 Ver1.8 Mod End   */
        --出荷数量(ケース) = 0
        on_case_shipping_qty := cn_zero;
        --欠品数量(バラ)   = 欠品数量(合計・バラ) 
        on_indv_stockout_qty := on_sum_stockout_qty;
        --欠品数量(ケース) = 0
        on_case_stockout_qty := cn_zero;
      END IF;
--
      --ボール入数あり、且つ、0以外
      IF ( in_ball_qty IS NOT NULL )
        AND ( in_ball_qty <> cn_zero )THEN
/* 2010/05/26 Ver1.8 Mod Start */
        --出荷数量(ボール) = 出荷数量(合計・バラ) / ボール入数の商
--        on_ball_shipping_qty := TRUNC( in_sum_shipping_qty / in_ball_qty );
        on_ball_shipping_qty := TRUNC( ln_sum_shipping_qty / in_ball_qty );
/* 2010/05/26 Ver1.8 Mod End   */
        --欠品数量(ボール) = 欠品数量(合計・バラ) / ボール入数の商
        on_ball_stockout_qty := TRUNC( on_sum_stockout_qty / in_ball_qty );
      --ボール入数なし
      ELSE
        --出荷数量(ボール) = 0
        on_ball_shipping_qty := cn_zero;
        --欠品数量(ボール) = 0
        on_ball_stockout_qty := cn_zero;
      END IF;
--
    --ケースの場合
    ELSE
--
/* 2010/05/26 Ver1.8 Mod Start */
      --出荷数量(バラ)   = 出荷数量(合計・バラ)
--      on_indv_shipping_qty := in_sum_shipping_qty;
      on_indv_shipping_qty := ln_sum_shipping_qty;
/* 2010/05/26 Ver1.8 Mod End   */
      --出荷数量(ケース) = 0
      on_case_shipping_qty := cn_zero;
      --出荷数量(ボール) = 0
      on_ball_shipping_qty := cn_zero;
      --欠品数量(バラ)   = 欠品数量(合計・バラ)
      on_indv_stockout_qty := on_sum_stockout_qty;
      --欠品数量(ケース) = 0
      on_case_stockout_qty := cn_zero;
      --欠品数量(ボール) = 0
      on_ball_stockout_qty := cn_zero;
--
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END convert_quantity;
  --
/* 2009/06/23 Ver1.5 Add End */
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_slip_flag
   * Description      : 納品書発行フラグ取得関数
   ***********************************************************************************/
  FUNCTION get_deliv_slip_flag(
               iv_publish_sequence                 IN  NUMBER   DEFAULT NULL  --納品書発行フラグ設定順番
              ,iv_publish_area                     IN  VARCHAR2 DEFAULT NULL  --納品書発行フラグエリア
              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
                                                                              --プログラム
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_deliv_slip_flag';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_start_possition                                 NUMBER(3);             --開始位置
    lv_publish_area                                    VARCHAR2(1);           --納品書発行フラグ
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
    --変数初期化
    ln_start_possition  := 0;
    lv_publish_area     := gv_char_n;
    --NULLチェック
    IF ( iv_publish_area IS NULL ) THEN
      RETURN gv_char_n;
    END IF;
    --位置チェック
    CASE iv_publish_sequence
    --入力発行順番０時【返却】
      WHEN 0 THEN
        RETURN gv_char_n;
    --入力発行順番１時【返却】
      WHEN 1 THEN
        lv_publish_area := SUBSTRB( iv_publish_area
                                   ,1
                                   ,1
                                   );
      ELSE
    --入力発行順番２以上時【返却】
        ln_start_possition := iv_publish_sequence * 2 - 1;
        lv_publish_area := SUBSTRB( iv_publish_area
                                   ,ln_start_possition
                                   ,1
                                   );
    END CASE;
    --納品書発行フラグ設定
    IF   ( lv_publish_area = gv_char_comma )
      OR ( lv_publish_area IS NULL )
    THEN
      RETURN gv_char_n;
    ELSE
      RETURN lv_publish_area;
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_deliv_slip_flag;
--
  /**********************************************************************************
   * Procedure Name   : get_deliv_slip_flag_area
   * Description      : 納品書発行フラグ全体取得関数
   ***********************************************************************************/
  FUNCTION get_deliv_slip_flag_area(
               iv_publish_sequence                  IN NUMBER   DEFAULT NULL  --納品書発行フラグ設定順番
              ,iv_publish_area                      IN VARCHAR2 DEFAULT NULL  --納品書発行フラグエリア
              ,iv_publish_flag                      IN VARCHAR2 DEFAULT NULL  --納品書発行フラグ
              )
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- ===============================
    -- ローカル定数
    -- ===============================
                                                                              --プログラム
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_deliv_slip_flag_area';
    cv_demiliter_flg_on                       CONSTANT VARCHAR2(2)   := 'ON';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_length                                          binary_integer := 0;   --入力引数レングス
    ln_publish_sequence                                binary_integer := 0;   --相対位置カウンタ
    ln_count                                           binary_integer := 0;   --デミリタ件数カウンタ
    ln_data_sequence                                   binary_integer := 0;   --出力引数レングス
    i                                                  binary_integer := 0;   --添え字①
    j                                                  binary_integer := 1;   --添え字②
    lv_publish_area                                    VARCHAR2(1000) DEFAULT NULL; --設定後納品書発行フラグエリア
    lv_byte_area                                       VARCHAR2(1000) DEFAULT NULL; --判定エリア
    lv_demiliter_flg                                   VARCHAR2(1000) DEFAULT NULL; --デミリタ判定フラグ
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
  --入力引数チェック
    IF   ( iv_publish_sequence IS NULL )
      OR ( iv_publish_flag     IS NULL )
    THEN
      RETURN iv_publish_area;
    END IF;
  --納品書発行フラグエリア     ：入力引数最終位置決定
    ln_length := LENGTHB( iv_publish_area );
    IF ( ln_length IS NULL ) THEN
      ln_length := 0;
    END IF;
  --デミリタ件数決定
    LOOP
      i := i + 1;
      IF ( i >= ln_length ) THEN
        EXIT;
      ELSE
        IF ( SUBSTRB( iv_publish_area,i,1 ) = gv_char_comma ) THEN
          ln_count := ln_count + 1;
        END IF;
      END IF;
    END LOOP;
  --納品書発行フラグ設定順番   ：相対位置決定
    IF ( iv_publish_sequence = 0 ) THEN
      ln_publish_sequence := iv_publish_sequence - 1;
    ELSE
      ln_publish_sequence := iv_publish_sequence * 2 - 1;
    END IF;  
  --出力納品書発行フラグエリア：相対位置決定
    IF ( ln_count != 0 ) THEN
      ln_data_sequence := ln_count * 2 + 1;
    END IF;      
    IF (ln_publish_sequence > ln_data_sequence ) THEN
      ln_data_sequence := ln_publish_sequence;
    END IF;
  --出力納品書発行フラグエリア設定
    FOR i IN 1..ln_data_sequence LOOP
      lv_byte_area := SUBSTRB( iv_publish_area,j,1 );
      IF ( lv_demiliter_flg = cv_demiliter_flg_on ) THEN
        lv_publish_area := lv_publish_area || gv_char_comma;
        lv_demiliter_flg := NULL;
        j := j + 1;
      ELSE
        IF ( lv_byte_area = gv_char_comma ) THEN
          IF ( i = ln_publish_sequence ) THEN
            lv_publish_area := lv_publish_area || iv_publish_flag;
          ELSE
            lv_publish_area := lv_publish_area || gv_char_n;
          END IF;
        ELSE
          IF ( i = ln_publish_sequence ) THEN
            lv_publish_area := lv_publish_area || iv_publish_flag;
          ELSE
            IF ( iv_publish_area IS NULL ) THEN
              lv_publish_area := lv_publish_area || gv_char_n;
            ELSE
--mod start 1/21
--              lv_publish_area := lv_publish_area || SUBSTRB( iv_publish_area,j,1 );
              lv_publish_area := lv_publish_area || NVL(SUBSTRB( iv_publish_area,j,1 ),gv_char_n);
--mod end 1/21
            END IF;
          END IF;
          j := j + 1;
        END IF;
        lv_demiliter_flg := cv_demiliter_flg_on;
      END IF;
    END LOOP;
----  
    RETURN lv_publish_area;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_deliv_slip_flag_area;
--
/* 2010/04/15 Ver1.7 Add Start */
  /**********************************************************************************
   * Procedure Name   : get_salesrep_id
   * Description      : 担当営業員取得関数
   ***********************************************************************************/
  PROCEDURE get_salesrep_id(
               iv_account_number     IN  VARCHAR2  DEFAULT NULL  --顧客コード
              ,id_target_date        IN  DATE      DEFAULT NULL  --基準日
              ,in_org_id             IN  NUMBER    DEFAULT NULL  --営業単位ID
              ,on_salesrep_id        OUT NOCOPY NUMBER           --担当営業員ID
              ,ov_employee_number    OUT NOCOPY VARCHAR2         --最上位者従業員番号
              ,ov_errbuf             OUT NOCOPY VARCHAR2         --エラー・メッセージエラー       #固定#
              ,ov_retcode            OUT NOCOPY VARCHAR2         --リターン・コード               #固定#
              ,ov_errmsg             OUT NOCOPY VARCHAR2         --ユーザー・エラー・メッセージ   #固定#
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name                               CONSTANT VARCHAR2(100) := 'get_salesrep_id';    --プログラム
    --業務日付
    cd_process_date                           CONSTANT   DATE        :=  xxccp_common_pkg2.get_process_date;
    cv_date_format                            CONSTANT VARCHAR2(10)  :=  'YYYY/MM/DD';
    cv_month_format                           CONSTANT VARCHAR2( 2)  :=  'MM';
    cv_category_employee                      CONSTANT VARCHAR2( 8)  :=  'EMPLOYEE';
    cv_resource_group_number                  CONSTANT VARCHAR2(15)  :=  'RS_GROUP_MEMBER';
    cv_person_type                            CONSTANT VARCHAR2( 3)  :=  'EMP';
    cd_last_day                               CONSTANT   DATE        :=  TO_DATE( '9999/12/31', cv_date_format );
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lt_msg_strings                                     fnd_new_messages.message_text%TYPE;      -- メッセージ用文字列
    lt_sale_base_code                                  xxcmm_cust_accounts.sale_base_code%TYPE; -- 拠点コード
    lt_salesrep_id                                     jtf_rs_salesreps.salesrep_id%TYPE;       -- 担当営業員ID
    lt_employee_number                                 per_all_people_f.employee_number%TYPE;   -- 従業員番号
    --
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --担当営業員取得
    CURSOR
      cur_salesrep_id
    IS
    SELECT jrs.salesrep_id               AS salesrep_id               --担当営業員ID
    FROM   hz_cust_accounts          hca                              --顧客マスタ
          ,hz_organization_profiles  hop                              --組織プロファイル
          ,ego_resource_agv          era                              --営業員リソース情報View
          ,jtf_rs_salesreps          jrs                              --営業担当
    WHERE  hca.account_number          = iv_account_number            --顧客コード
    AND    hop.party_id                = hca.party_id
    AND    era.organization_profile_id = hop.organization_profile_id
    AND    hop.effective_end_date      IS NULL
    AND    jrs.salesrep_number         = era.resource_no
    AND    jrs.org_id                  = in_org_id                    -- 営業単位ID
    AND    TRUNC( era.resource_s_date )   <= TRUNC( id_target_date )
    AND    TRUNC( NVL(era.resource_e_date, id_target_date ) )
                                          >= TRUNC( id_target_date )
    AND    TRUNC( jrs.start_date_active ) <= TRUNC( id_target_date )
    AND    TRUNC( NVL(jrs.end_date_active, id_target_date ) )
                                          >= TRUNC( id_target_date )
    ORDER BY
           era.resource_s_date DESC
    ;
    --拠点の最上位従業員を取得
    CURSOR
      cur_employee_number(
        lv_sale_base_code            VARCHAR2
      )
    IS
    SELECT jrs.salesrep_id               AS salesrep_id             --担当営業員ID
          ,papf_n.employee_number        AS employee_number         --従業員番号
    FROM   per_person_types          pept_n                         --従業員タイプ
          ,per_periods_of_service    ppos_n                         --従業員サービス
          ,per_all_assignments_f     paaf_n                         --アサイメント
          ,per_all_people_f          papf_n                         --従業員
          ,jtf_rs_resource_extns     jrrx_n                         --リソース
          ,jtf_rs_group_members      jrgm_n                         --グループメンバー
          ,jtf_rs_groups_b           jrgb_n                         --リソースグループ
          ,jtf_rs_role_relations     jrrr                           --役割
          ,jtf_rs_salesreps          jrs                            --営業担当
    WHERE jrgb_n.attribute1            = lv_sale_base_code          --拠点コード
    AND   jrgb_n.group_id              = jrgm_n.group_id
    AND   jrgm_n.delete_flag           = gv_char_n
    AND   jrgm_n.resource_id           = jrrx_n.resource_id
    AND   jrrx_n.category              = cv_category_employee
    AND   jrrr.role_resource_id        = jrgm_n.group_member_id
    AND   jrrr.role_resource_type      = cv_resource_group_number
    AND   jrrr.delete_flag             = gv_char_n
    AND   jrrr.start_date_active      <= id_target_date
    AND   NVL( jrrr.end_date_active, id_target_date ) >= id_target_date
    AND   jrrx_n.source_id             = papf_n.person_id
    AND   papf_n.person_id             = paaf_n.person_id
    AND   paaf_n.period_of_service_id  = ppos_n.period_of_service_id
    AND   ppos_n.actual_termination_date IS NULL
    AND   papf_n.person_type_id        = pept_n.person_type_id
    AND   id_target_date BETWEEN papf_n.effective_start_date
                             AND NVL( papf_n.effective_end_date, cd_last_day )
    AND   pept_n.system_person_type    = cv_person_type
    AND   pept_n.active_flag           = gv_char_y
    AND   jrrx_n.resource_id           = jrs.resource_id
    AND   jrs.org_id                   = in_org_id                    -- 営業単位ID
    AND    TRUNC( jrs.start_date_active ) <= TRUNC( id_target_date )
    AND    TRUNC( NVL( jrs.end_date_active, id_target_date ) )
                                          >= TRUNC( id_target_date )
    ORDER BY
          paaf_n.ass_attribute11                                    -- 職位順
         ,ppos_n.date_start                                         -- 入社日
         ,papf_n.employee_number                                    -- 従業員番号
    ;
    --
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
  --
--
  BEGIN
--
    --リターン・コード初期化
    ov_retcode := cv_status_normal;
--
    --顧客コードチェック
    IF ( iv_account_number IS NULL ) THEN
      lt_msg_strings := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_account_number
                                                );
      lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_parameter_err
                                                  ,iv_token_name1  => gv_token_name_in_param
                                                  ,iv_token_value1 => lt_msg_strings
                                                );
      lv_errbuf      := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --基準日チェック
    IF ( id_target_date IS NULL ) THEN
      lt_msg_strings := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_target_date
                                                );
      lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_parameter_err
                                                  ,iv_token_name1  => gv_token_name_in_param
                                                  ,iv_token_value1 => lt_msg_strings
                                                );
      lv_errbuf      := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --営業単位IDチェック
    IF ( in_org_id IS NULL ) THEN
      lt_msg_strings := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_org_id
                                                );
      lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                  ,iv_name         => ct_msg_parameter_err
                                                  ,iv_token_name1  => gv_token_name_in_param
                                                  ,iv_token_value1 => lt_msg_strings
                                                );
      lv_errbuf      := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --担当営業員取得
    OPEN cur_salesrep_id;
    FETCH cur_salesrep_id INTO lt_salesrep_id;
    CLOSE cur_salesrep_id;
    --担当営業員が取得できなかった場合
    IF ( lt_salesrep_id IS NULL ) THEN
      BEGIN
        --基準日の拠点コードを取得
        SELECT CASE WHEN TRUNC( id_target_date, cv_month_format ) <  TRUNC( cd_process_date, cv_month_format )
                      THEN xca.past_sale_base_code                        --前月売上拠点コード
                    WHEN TRUNC( id_target_date ) >= NVL( xca.rsv_sale_base_act_date, cd_last_day )
                      THEN xca.rsv_sale_base_code                         --予約売上拠点コード
                    WHEN TRUNC( id_target_date ) <  NVL( xca.rsv_sale_base_act_date, cd_last_day )
                      THEN xca.sale_base_code                             --売上拠点コード
                    ELSE
                      NULL
               END                           AS sale_base_code            --拠点コード
        INTO   lt_sale_base_code
        FROM   xxcmm_cust_accounts       xca                              --顧客追加情報
        WHERE  xca.customer_code           = iv_account_number            --顧客コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      --拠点コードが取得できなかった場合
      IF ( lt_sale_base_code IS NULL ) THEN
        lt_msg_strings := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                    ,iv_name         => ct_msg_base_code
                                                  );
        lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                    ,iv_name         => ct_msg_no_data_found
                                                    ,iv_token_name1  => cv_tkn_data
                                                    ,iv_token_value1 => lt_msg_strings
                                                  );
        lv_errbuf      := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --拠点の最上位従業員を取得
      OPEN cur_employee_number( lt_sale_base_code );
      FETCH cur_employee_number INTO lt_salesrep_id, lt_employee_number;
      IF cur_employee_number%NOTFOUND THEN
        --担当営業員拠点最上位者取得エラーをユーザー・エラー・メッセージに設定
        lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                    ,iv_name         => ct_msg_unset_employee
                                                    ,iv_token_name1  => cv_tkn_base
                                                    ,iv_token_value1 => lt_sale_base_code
                                                    ,iv_token_name2  => cv_tkn_cust
                                                    ,iv_token_value2 => iv_account_number
                                                    ,iv_token_name3  => cv_tkn_sdate
                                                    ,iv_token_value3 => TO_CHAR( id_target_date, cv_date_format )
                                                  );
        lv_errbuf      := lv_errmsg;
        --メッセージを出力項目に設定
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      ELSE
        --出力項目に設定
        on_salesrep_id     := lt_salesrep_id;
        ov_employee_number := lt_employee_number;
        --担当営業員拠点最上位者設定メッセージをユーザー・エラー・メッセージに設定
        lv_errmsg      := xxccp_common_pkg.get_msg(  iv_application  => gv_application
                                                    ,iv_name         => ct_msg_set_employee
                                                    ,iv_token_name1  => cv_tkn_base
                                                    ,iv_token_value1 => lt_sale_base_code
                                                    ,iv_token_name2  => cv_tkn_cust
                                                    ,iv_token_value2 => iv_account_number
                                                    ,iv_token_name3  => cv_tkn_sdate
                                                    ,iv_token_value3 => TO_CHAR( id_target_date, cv_date_format )
                                                    ,iv_token_name4  => cv_tkn_emp
                                                    ,iv_token_value4 => lt_employee_number
                                                  );
        lv_errbuf      := lv_errmsg;
        --メッセージを出力項目に設定
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      END IF;
      CLOSE cur_employee_number;
    ELSE
      --出力項目に設定
      on_salesrep_id := lt_salesrep_id;
    END IF;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xxccp_common_pkg.set_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_cnst_period||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_salesrep_id;
  --
/* 2010/04/15 Ver1.7 Add End */
--
END XXCOS_COMMON2_PKG;
/