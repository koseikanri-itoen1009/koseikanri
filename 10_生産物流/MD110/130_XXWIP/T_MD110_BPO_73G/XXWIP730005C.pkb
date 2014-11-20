CREATE OR REPLACE PACKAGE BODY xxwip730005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730005C(body)
 * Description      : 請求運賃チェックリスト
 * MD.050/070       : 運賃計算（トランザクション）  (T_MD050_BPO_734)
 *                    請求運賃チェックリスト        (T_MD070_BPO_73G)
 * Version          : 1.14
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_chk_param               PROCEDURE : パラメータチェック
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_sql              PROCEDURE : データ取得ＳＱＬ生成
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/30    1.0   Masayuki Ikeda   新規作成
 *  2008/05/23    1.1   Masayuki Ikeda   結合テスト障害対応
 *  2008/07/02    1.2   Satoshi Yunba    禁則文字「'」「"」「<」「>」「&」対応
 *  2008/07/15    1.3   Masayuki Nomura  ST障害対応#444
 *  2008/07/15    1.4   Masayuki Nomura  ST障害対応#444（記号対応）
 *  2008/07/17    1.5   Satoshi Takemoto ST障害対応#456
 *  2008/07/24    1.6   Satoshi Takemoto ST障害対応#477
 *  2008/07/25    1.7   Masayuki Nomura  ST障害対応#456
 *  2008/07/28    1.8   Masayuki Nomura  変更要求結合テスト障害対応
 *  2008/08/19    1.9   Takao Ohashi     T_TE080_BPO_730 指摘10対応
 *  2008/10/15    1.10  Yasuhisa Yamamoto 統合障害#300,331
 *  2008/10/24    1.11  Masayuki Nomura  統合#439対応
 *  2008/12/15    1.12  野村 正幸        本番#40対応
 *  2009/01/29    1.13  野村 正幸        本番#431対応
 *  2009/07/01    1.14  野村 正幸        本番#1551対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ===============================================================================================
  -- ユーザー宣言部
  -- ===============================================================================================
  -- ==================================================
  -- グローバル定数
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXWIP730005C' ;      -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWIP730005T' ;      -- 帳票ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_application_wip      CONSTANT VARCHAR2(5)  := 'XXWIP' ;            -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- データ０件メッセージ
--
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 品目カテゴリ名
  gc_cat_set_name_prod      CONSTANT VARCHAR2(10) := '商品区分' ;
  -- 代表タイプ
  gc_order_type_s           CONSTANT VARCHAR2(1) := '1' ;   -- 出荷
  gc_order_type_m           CONSTANT VARCHAR2(1) := '2' ;   -- 移動
  gc_order_type_p           CONSTANT VARCHAR2(1) := '3' ;   -- 支給
  gc_order_type_js          CONSTANT VARCHAR2(2) := '出' ;
  gc_order_type_jm          CONSTANT VARCHAR2(2) := '移' ;
  gc_order_type_jp          CONSTANT VARCHAR2(2) := '支' ;
  -- 重量容積区分
  gc_wc_class_w             CONSTANT VARCHAR2(1) := '1' ;   -- 重量
  gc_wc_class_c             CONSTANT VARCHAR2(1) := '2' ;   -- 容積
  gc_wc_class_jw            CONSTANT VARCHAR2(2) := '重' ;
  gc_wc_class_jc            CONSTANT VARCHAR2(2) := '容' ;
  -- 契約外区分
  gc_outside_contract_y     CONSTANT VARCHAR2(1) := '1' ;   -- 有
  gc_outside_contract_n     CONSTANT VARCHAR2(1) := '0' ;   -- 無
  gc_outside_contract_jy    CONSTANT VARCHAR2(2) := '有' ;  -- 有
  gc_outside_contract_jn    CONSTANT VARCHAR2(2) := '無' ;  -- 無
  -- 支払確定戻
  gc_return_flag_y          CONSTANT VARCHAR2(1) := 'Y' ;
  gc_return_flag_n          CONSTANT VARCHAR2(1) := 'N' ;
  gc_return_flag_jy         CONSTANT VARCHAR2(2) := '有' ;
  gc_return_flag_jn         CONSTANT VARCHAR2(2) := '無' ;
  -- 配送先区分コード
  gc_code_division_s        CONSTANT VARCHAR2(1) := '1' ;
  gc_code_division_p        CONSTANT VARCHAR2(1) := '2' ;
  gc_code_division_m        CONSTANT VARCHAR2(1) := '3' ;
  -- 支払請求区分
  gc_code_p_b_classe_p      CONSTANT VARCHAR2(1) := '1' ;   -- 支払運賃
  gc_code_p_b_classe_b      CONSTANT VARCHAR2(1) := '2' ;   -- 請求運賃
--
  ------------------------------
  -- その他
  ------------------------------
  -- 品目区分
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- 原料
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- 資材
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- 半製品
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- 製品
  gc_min_date_char        CONSTANT VARCHAR2(10) := '1900/01/01' ;
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    gc_carrier_code_min   CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
    gc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
    gc_whs_code_min       CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
    gc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
    gc_delivery_no_min    CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    gc_delivery_no_max    CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
    gc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    gc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
  -- ===============================================================================================
  -- レコード型宣言
  -- ===============================================================================================
  --------------------------------------------------
  -- 入力パラメータ格納用
  --------------------------------------------------
  TYPE rec_param_data  IS RECORD
    (
      prod_div            VARCHAR2(1)         -- 01 : 商品区分
     ,carrier_code_from   VARCHAR2(4)         -- 02 : 運送業者From
     ,carrier_code_to     VARCHAR2(4)         -- 03 : 運送業者To
     ,whs_code_from       VARCHAR2(4)         -- 04 : 出庫元倉庫From
     ,whs_code_to         VARCHAR2(4)         -- 05 : 出庫元倉庫To
     ,ship_date_from      DATE                -- 06 : 出庫日From
     ,ship_date_to        DATE                -- 07 : 出庫日To
     ,arrival_date_from   DATE                -- 08 : 着日From
     ,arrival_date_to     DATE                -- 09 : 着日To
     ,judge_date_from     DATE                -- 10 : 決済日From
     ,judge_date_to       DATE                -- 11 : 決済日To
     ,report_date_from    DATE                -- 12 : 報告日From
     ,report_date_to      DATE                -- 13 : 報告日To
     ,delivery_no_from    VARCHAR2(12)        -- 14 : 配送NoFrom
     ,delivery_no_to      VARCHAR2(12)        -- 15 : 配送NoTo
     ,request_no_from     VARCHAR2(12)        -- 16 : 依頼NoFrom
     ,request_no_to       VARCHAR2(12)        -- 17 : 依頼NoTo
     ,invoice_no_from     VARCHAR2(20)        -- 18 : 送り状NoFrom
     ,invoice_no_to       VARCHAR2(20)        -- 19 : 送り状NoTo
     ,order_type          VARCHAR2(1)         -- 20 : 受注タイプ
     ,wc_class            VARCHAR2(1)         -- 21 : 重量容積区分
     ,outside_contract    VARCHAR2(1)         -- 22 : 契約外
     ,return_flag         VARCHAR2(1)         -- 23 : 確定後変更
     ,output_flag         VARCHAR2(1)         -- 24 : 差異
    ) ;
  gr_param              rec_param_data ;      -- パラメータ
--
  --------------------------------------------------
  -- 取得データ格納用
  --------------------------------------------------
  TYPE rec_main_data  IS RECORD
    (
      prod_div          VARCHAR2(1)       -- 商品区分
     ,prod_div_name     VARCHAR2(8)       -- 商品区分名称
     ,carrier_code      VARCHAR2(4)       -- 運送業者コード
     ,carrier_name      VARCHAR2(20)      -- 運送業者名称
     ,judge_date        DATE              -- 決済日
     ,judge_date_c      VARCHAR2(10)      -- 決済日（文字）
     ,whs_code          VARCHAR2(4)       -- 倉庫
     ,ship_date         VARCHAR2(5)       -- 発日
     ,arrival_date      VARCHAR2(5)       -- 着日
     ,delivery_no       VARCHAR2(12)      -- 配送No
     ,request_no        VARCHAR2(12)      -- 依頼No
     ,invoice_no        VARCHAR2(20)      -- 送り状No
     ,code_division     VARCHAR2(1)       -- 配送先コード区分
     ,ship_to_code      VARCHAR2(9)       -- 配送先
     ,ship_to_name      VARCHAR2(30)      -- 配送先名称
     ,distance_1        VARCHAR2(4)       -- 距離１
     ,distance_2        VARCHAR2(4)       -- 距離２
-- S 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- S --
--     ,qty               VARCHAR2(4)       -- 数量
     ,qty               VARCHAR2(9)       -- 数量
-- E 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- E --
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--     ,weight            VARCHAR2(5)       -- 重量
     ,weight            VARCHAR2(6)       -- 重量
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
     ,deliv_div         VARCHAR2(2)       -- 配送区分
     ,c_kei             NUMBER            -- 運送業者：契約運賃
     ,c_kon             NUMBER            -- 運送業者：混載割増
     ,c_pic             NUMBER            -- 運送業者：PIC
     ,c_oth             NUMBER            -- 運送業者：諸料金
     ,c_sum             NUMBER            -- 運送業者：支払合計
     ,c_tsu             NUMBER            -- 運送業者：通行料等
     ,i_kei             NUMBER            -- 伊藤園：契約運賃
     ,i_sei             NUMBER            -- 伊藤園：請求運賃
     ,i_kon             NUMBER            -- 伊藤園：混載割増
     ,i_pic             NUMBER            -- 伊藤園：PIC
     ,i_oth             NUMBER            -- 伊藤園：諸料金
     ,i_sum             NUMBER            -- 伊藤園：支払合計
     ,i_tsu             NUMBER            -- 伊藤園：通行料等
     ,balance           NUMBER            -- 差異
    ) ;
  TYPE tab_main_data IS TABLE OF rec_main_data INDEX BY BINARY_INTEGER ;
  gt_main_data  tab_main_data ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER DEFAULT 0 ;    -- ＸＭＬデータタグ表のインデックス
--
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ログインユーザーＩＤ
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : パラメータチェック
   ************************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    lc_carrier_code_min   CONSTANT VARCHAR2(4)  := gc_carrier_code_min;
    lc_carrier_code_max   CONSTANT VARCHAR2(4)  := gc_carrier_code_max;
    lc_whs_code_min       CONSTANT VARCHAR2(4)  := gc_whs_code_min    ;
    lc_whs_code_max       CONSTANT VARCHAR2(4)  := gc_whs_code_max    ;
    lc_delivery_no_min    CONSTANT VARCHAR2(12) := gc_delivery_no_min ;
    lc_delivery_no_max    CONSTANT VARCHAR2(12) := gc_delivery_no_max ;
    lc_request_no_min     CONSTANT VARCHAR2(12) := gc_request_no_min  ;
    lc_request_no_max     CONSTANT VARCHAR2(12) := gc_request_no_max  ;
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_msg_code_01              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10016' ;
    lc_msg_code_02              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10028' ;
    lv_tok_name_1               CONSTANT VARCHAR2(50) := 'PARAM1' ;
    lv_tok_name_2               CONSTANT VARCHAR2(50) := 'PARAM2' ;
    lc_p_name_carrier_code_from CONSTANT VARCHAR2(50) := '運送業者From' ;
    lc_p_name_carrier_code_to   CONSTANT VARCHAR2(50) := '運送業者To' ;
    lc_p_name_whs_code_from     CONSTANT VARCHAR2(50) := '出庫元倉庫From' ;
    lc_p_name_whs_code_to       CONSTANT VARCHAR2(50) := '出庫元倉庫To' ;
    lc_p_name_ship_date_from    CONSTANT VARCHAR2(50) := '出庫日From' ;
    lc_p_name_ship_date_to      CONSTANT VARCHAR2(50) := '出庫日To' ;
    lc_p_name_arrival_date_from CONSTANT VARCHAR2(50) := '着日From' ;
    lc_p_name_arrival_date_to   CONSTANT VARCHAR2(50) := '着日To' ;
    lc_p_name_judge_date_from   CONSTANT VARCHAR2(50) := '決済日From' ;
    lc_p_name_judge_date_to     CONSTANT VARCHAR2(50) := '決済日To' ;
    lc_p_name_report_date_from  CONSTANT VARCHAR2(50) := '報告日From' ;
    lc_p_name_report_date_to    CONSTANT VARCHAR2(50) := '報告日To' ;
    lc_p_name_delivery_no_from  CONSTANT VARCHAR2(50) := '配送NoFrom' ;
    lc_p_name_delivery_no_to    CONSTANT VARCHAR2(50) := '配送NoTo' ;
    lc_p_name_request_no_from   CONSTANT VARCHAR2(50) := '依頼NoFrom' ;
    lc_p_name_request_no_to     CONSTANT VARCHAR2(50) := '依頼NoTo' ;
    lc_p_name_invoice_no_from   CONSTANT VARCHAR2(50) := '送り状NoFrom' ;
    lc_p_name_invoice_no_to     CONSTANT VARCHAR2(50) := '送り状NoTo' ;
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    -- パラメータ未設定時のエラー
    lc_msg_code_03              CONSTANT VARCHAR2(50) := 'APP-XXWIP-10088' ;
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_msg_code       VARCHAR2(100) ;
    lv_tok_val_1      VARCHAR2(100) ;
    lv_tok_val_2      VARCHAR2(100) ;
--
    -- ==================================================
    -- 例外宣言
    -- ==================================================
    ex_param_error    EXCEPTION ;
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    no_param_error    EXCEPTION ;
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    -- ====================================================
    -- パラメータ指定チェック
    -- ====================================================
    -- パラメータ指定なしの場合、エラーとする
    -- ※ 確定後変更・差異以外のパラメータ
    --    main()関数内で設定している値と比較
    IF ((gr_param.prod_div           IS NULL )                   -- 商品区分
    AND (gr_param.carrier_code_from  = lc_carrier_code_min )     -- 運送業者From
    AND (gr_param.carrier_code_to    = lc_carrier_code_max )     -- 運送業者To
    AND (gr_param.whs_code_from      = lc_whs_code_min)          -- 出庫元倉庫From
    AND (gr_param.whs_code_to        = lc_whs_code_max )         -- 出庫元倉庫To
    AND (gr_param.ship_date_from     = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- 出庫日From
    AND (gr_param.ship_date_to       = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- 出庫日To
    AND (gr_param.arrival_date_from  = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- 着日From
    AND (gr_param.arrival_date_to    = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- 着日To
    AND (gr_param.judge_date_from    = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- 決済日From
    AND (gr_param.judge_date_to      = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- 決済日To
    AND (gr_param.report_date_from   = FND_DATE.CANONICAL_TO_DATE(gc_min_date_char)) -- 報告日From
    AND (gr_param.report_date_to     = FND_DATE.CANONICAL_TO_DATE(gc_max_date_char)) -- 報告日To
    AND (gr_param.delivery_no_from   = lc_delivery_no_min )      -- 配送NoFrom
    AND (gr_param.delivery_no_to     = lc_delivery_no_max )      -- 配送NoTo
    AND (gr_param.request_no_from    = lc_request_no_min )       -- 依頼NoFrom
    AND (gr_param.request_no_to      = lc_request_no_max )       -- 依頼NoTo
    AND (gr_param.invoice_no_from    IS NULL )                   -- 送り状NoFrom
    AND (gr_param.invoice_no_to      IS NULL )                   -- 送り状NoTo
    AND (gr_param.order_type         IS NULL )                   -- 受注タイプ
    AND (gr_param.wc_class           IS NULL )                   -- 重量容積区分
    AND (gr_param.outside_contract   IS NULL )) THEN             -- 契約外
      lv_msg_code  := lc_msg_code_03 ;
      RAISE no_param_error ;
    END IF;
--
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
    -- ====================================================
    -- 逆転チェック
    -- ====================================================
    -- ----------------------------------------------------
    -- 運送業者
    -- ----------------------------------------------------
    IF( gr_param.carrier_code_from > gr_param.carrier_code_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_carrier_code_to ;
      lv_tok_val_2 := lc_p_name_carrier_code_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 出庫元倉庫
    -- ----------------------------------------------------
    IF( gr_param.whs_code_from > gr_param.whs_code_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_whs_code_to ;
      lv_tok_val_2 := lc_p_name_whs_code_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 出庫日
    -- ----------------------------------------------------
    IF( gr_param.ship_date_from > gr_param.ship_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_ship_date_from ;
      lv_tok_val_2 := lc_p_name_ship_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 着日
    -- ----------------------------------------------------
    IF( gr_param.arrival_date_from > gr_param.arrival_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_arrival_date_from ;
      lv_tok_val_2 := lc_p_name_arrival_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 決済日
    -- ----------------------------------------------------
    IF( gr_param.judge_date_from > gr_param.judge_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_judge_date_from ;
      lv_tok_val_2 := lc_p_name_judge_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 報告日
    -- ----------------------------------------------------
    IF( gr_param.report_date_from > gr_param.report_date_to ) THEN
      lv_msg_code  := lc_msg_code_01 ;
      lv_tok_val_1 := lc_p_name_report_date_from ;
      lv_tok_val_2 := lc_p_name_report_date_to ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 配送No
    -- ----------------------------------------------------
    IF( gr_param.delivery_no_from > gr_param.delivery_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_delivery_no_to ;
      lv_tok_val_2 := lc_p_name_delivery_no_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 依頼No
    -- ----------------------------------------------------
    IF( gr_param.request_no_from > gr_param.request_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_request_no_to ;
      lv_tok_val_2 := lc_p_name_request_no_from ;
      RAISE ex_param_error ;
    END IF ;
    -- ----------------------------------------------------
    -- 送り状No
    -- ----------------------------------------------------
    IF( gr_param.invoice_no_from > gr_param.invoice_no_to ) THEN
      lv_msg_code  := lc_msg_code_02 ;
      lv_tok_val_1 := lc_p_name_invoice_no_to ;
      lv_tok_val_2 := lc_p_name_invoice_no_from ;
      RAISE ex_param_error ;
    END IF ;
--
  EXCEPTION
    -- =============================================================================================
    -- パラメータエラー
    -- =============================================================================================
    WHEN ex_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_wip
                     ,iv_name           => lv_msg_code
                     ,iv_token_name1    => lv_tok_name_1
                     ,iv_token_name2    => lv_tok_name_2
                     ,iv_token_value1   => lv_tok_val_1
                     ,iv_token_value2   => lv_tok_val_2
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
-- *----------* 2009/07/01 本番#1551対応 start *----------*
    -- =============================================================================================
    -- パラメータ未設定エラー
    -- =============================================================================================
    WHEN no_param_error THEN
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_wip
                     ,iv_name           => lv_msg_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
--
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ユーザー情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_sql
   * Description      : データ取得ＳＱＬ生成
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
    lc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_main
    IS
      SELECT xcat.segment1                                  AS prod_div         -- 商品区分
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--            ,xcat.description                               AS prod_div_name    -- 商品区分名称
            ,SUBSTRB(xcat.description,1,8)                  AS prod_div_name    -- 商品区分名称
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
            ,xcar.party_number                              AS carrier_code     -- 運送業者コード
            ,xcar.party_short_name                          AS carrier_name     -- 運送業者名称
            ,xd1.judgement_date                             AS judge_date       -- 決済日
            ,TO_CHAR( xd1.judgement_date, 'YYYY/MM/DD' )    AS judge_date_c     -- 決済日（文字）
            ,NVL( xdl.whs_code, xd1.whs_code )              AS whs_code         -- 倉庫
            ,NVL( TO_CHAR( xdl.ship_date, 'MM/DD' )
                 ,TO_CHAR( xd1.ship_date, 'MM/DD' ) )       AS ship_date        -- 発日
            ,NVL( TO_CHAR( xdl.arrival_date, 'MM/DD' )
                 ,TO_CHAR( xd1.arrival_date, 'MM/DD' ) )    AS arrival_date     -- 着日
            ,xd1.delivery_no                                AS delivery_no      -- 配送No
            ,xdl.request_no                                 AS request_no       -- 依頼No
            ,NVL( xdl.invoice_no, xd1.invoice_no )          AS invoice_no       -- 送り状No
            ,NVL( xdl.code_division, xd1.code_division )    AS code_division    -- 配送先コード区分
            ,NVL( xdl.shipping_address_code
                 ,xd1.shipping_address_code )               AS ship_to_code     -- 配送先
            ,NULL                                           AS ship_to_name     -- 配送先名称
            ,NVL( xd1.distance          , 0 )               AS distance_1       -- 距離１
            ,NVL( xdl.distance          , 0 )               AS distance_2       -- 距離２
            ,NVL( xdl.qty               , 0 )               AS qty              -- 数量
            ,NVL( xdl.delivery_weight   , 0 )               AS weight           -- 重量
-- ##### 20080725 1.8 変更要求結合テスト障害対応 START #####
--            ,xdl.dellivary_classe                           AS deliv_div        -- 配送区分
            ,NVL(xdl.dellivary_classe ,xd1.delivery_classe) AS deliv_div        -- 配送区分
-- ##### 20080725 1.8 変更要求結合テスト障害対応 END   #####
-- ##### 20081024 Ver.1.11 統合#439対応 START #####
--           ,NVL( xd2.charged_amount    , 0 )               AS c_kei      -- 運送業者：契約運賃
           ,NVL( xd2.contract_rate      , 0 )               AS c_kei      -- 運送業者：契約運賃
-- ##### 20081024 Ver.1.11 統合#439対応 END   #####
            ,NVL( xd2.consolid_surcharge, 0 )               AS c_kon      -- 運送業者：混載割増
            ,NVL( xd2.picking_charge    , 0 )               AS c_pic      -- 運送業者：PIC
            ,NVL( xd2.many_rate         , 0 )               AS c_oth      -- 運送業者：諸料金
            ,NVL( xd2.total_amount      , 0 )               AS c_sum      -- 運送業者：支払合計
            ,NVL( xd2.congestion_charge , 0 )               AS c_tsu      -- 運送業者：通行料等
            ,NVL( xd1.contract_rate     , 0 )               AS i_kei      -- 伊藤園：契約運賃
            ,NVL( xd1.charged_amount    , 0 )               AS i_sei      -- 伊藤園：請求運賃
            ,NVL( xd1.consolid_surcharge, 0 )               AS i_kon      -- 伊藤園：混載割増
            ,NVL( xd1.picking_charge    , 0 )               AS i_pic      -- 伊藤園：PIC
            ,NVL( xd1.many_rate         , 0 )               AS i_oth      -- 伊藤園：諸料金
            ,NVL( xd1.total_amount      , 0 )               AS i_sum      -- 伊藤園：支払合計
            ,NVL( xd1.congestion_charge , 0 )               AS i_tsu      -- 伊藤園：通行料等
            ,NVL( xd1.balance           , 0 )               AS balance    -- 差異
      FROM xxwip_deliverys        xd1   -- 運賃ヘッダーアドオン（請求）
          ,xxwip_deliverys        xd2   -- 運賃ヘッダーアドオン（支払）
          ,xxwip_delivery_lines   xdl   -- 運賃明細アドオン
          ,xxcmn_carriers2_v      xcar  -- 運送業者情報View
          ,xxcmn_categories_v     xcat  -- 品目カテゴリ情報View
      WHERE
      ----------------------------------------------------------------------------------------------
      -- 品目カテゴリ情報View
      ----------------------------------------------------------------------------------------------
      -- 条件
            xcat.category_set_name = gc_cat_set_name_prod
      -- 結合条件
      AND   xd1.goods_classe       = xcat.segment1
      ----------------------------------------------------------------------------------------------
      -- 運送業者情報View
      ----------------------------------------------------------------------------------------------
      -- 条件
      AND   xd1.judgement_date         BETWEEN xcar.start_date_active
                                       AND     NVL( xcar.end_date_active, xd1.judgement_date )
      -- 結合条件
      AND   xd1.delivery_company_code  = xcar.party_number
      ----------------------------------------------------------------------------------------------
      -- 運賃明細アドオン
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件
-- S 2009/01/29 1.13 MOD BY M.Nomura ---------------------------------------------------------- S --
-- 依頼No指定の場合に、依頼Noに紐付く配送Noにてチェックリストを出力する
--      AND   xdl.request_no(+)     BETWEEN gr_param.request_no_from    -- 依頼No
--                                  AND     gr_param.request_no_to      --
--      AND   (  gr_param.request_no_from = lc_request_no_min
--            OR xdl.request_no          IS NOT NULL          )
--      AND   (  gr_param.request_no_to   = lc_request_no_max
--            OR xdl.request_no          IS NOT NULL          )
      -- 結合条件
--      AND   xd1.delivery_no             = xdl.delivery_no(+)
      AND ( EXISTS ( SELECT  1
                     FROM  xxwip_delivery_lines   xdl_reqno    -- 運賃明細アドオン
                     WHERE xdl_reqno.request_no    BETWEEN gr_param.request_no_from    -- 依頼No From
                                                   AND     gr_param.request_no_to      --        To
                     AND   (  gr_param.request_no_from    = lc_request_no_min
                           OR xdl_reqno.request_no        IS NOT NULL         )
                     AND   (  gr_param.request_no_to      = lc_request_no_max
                           OR xdl_reqno.request_no        IS NOT NULL         )
                     AND   xdl_reqno.delivery_no          = xdl.delivery_no    )       -- 配送No
            -- 指定なしの場合は、伝票なし配車も出力対象とする
            OR ( xdl.request_no IS NULL 
                AND gr_param.request_no_from = lc_request_no_min 
                AND gr_param.request_no_to   = lc_request_no_max ) )      -- 配送No
      AND   xd1.delivery_no             = xdl.delivery_no(+)
-- E 2009/01/29 1.13 MOD BY M.Nomura ---------------------------------------------------------- E --
      ----------------------------------------------------------------------------------------------
      -- 運賃ヘッダーアドオン（支払）
      ----------------------------------------------------------------------------------------------
      -- 条件
      AND   xd2.p_b_classe  = gc_code_p_b_classe_p
      -- パラメータ条件
-- S 2008/07/17 1.5 MOD BY S.Takemoto---------------------------------------------------------- S --
--      AND   xd2.return_flag = gr_param.return_flag -- 確定後変更
      AND  ( (xd2.return_flag            = gr_param.return_flag)             -- 確定後変更
          OR (gr_param.return_flag = gc_return_flag_n))     -- パラメータ.確定後変更:Nの場合はすべて
-- E 2008/07/17 1.5 MOD BY S.Takemoto---------------------------------------------------------- E --
      AND   xd2.output_flag = gr_param.output_flag -- 差異
      -- 結合条件
      AND   xd1.delivery_no = xd2.delivery_no
      ----------------------------------------------------------------------------------------------
      -- 運賃ヘッダーアドオン（請求）
      ----------------------------------------------------------------------------------------------
      -- 条件
      AND   xd1.p_b_classe            = gc_code_p_b_classe_b
      -- パラメータ条件
      AND   xd1.delivery_company_code BETWEEN gr_param.carrier_code_from  -- 運送業者
                                      AND     gr_param.carrier_code_to    --
      AND   xd1.whs_code              BETWEEN gr_param.whs_code_from      -- 出庫元倉庫
                                      AND     gr_param.whs_code_to        --
      AND   xd1.ship_date             BETWEEN gr_param.ship_date_from     -- 出庫日
                                      AND     gr_param.ship_date_to       --
      AND   xd1.arrival_date          BETWEEN gr_param.arrival_date_from  -- 着日
                                      AND     gr_param.arrival_date_to    --
      AND   xd1.judgement_date        BETWEEN gr_param.judge_date_from    -- 決済日
                                      AND     gr_param.judge_date_to      --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   xd1.report_date           BETWEEN gr_param.report_date_from   -- 報告日
--                                      AND     gr_param.report_date_to     --
      AND   NVL( xd1.report_date, gr_param.report_date_from )
                                      BETWEEN gr_param.report_date_from   -- 報告日
                                      AND     gr_param.report_date_to     --
-- E 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
      AND   xd1.delivery_no           BETWEEN gr_param.delivery_no_from   -- 配送No
                                      AND     gr_param.delivery_no_to     --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   xd1.invoice_no            BETWEEN gr_param.invoice_no_from    -- 送り状No
--                                      AND     gr_param.invoice_no_to      --
-- ##### 20080715 1.4 ST障害対応#444（記号対応） START #####
--      AND   NVL( xd1.invoice_no, gr_param.invoice_no_from )
--                                      BETWEEN gr_param.invoice_no_from    -- 送り状No
--                                      AND     gr_param.invoice_no_to      --
      AND   (
              -- 送り状No From To がNULLの場合
              (
                    (gr_param.invoice_no_from IS NULL)
                AND (gr_param.invoice_no_to   IS NULL)
              )
              OR
              -- 送り状No From To が両方 NOT NULL の場合
              (
                    (xd1.invoice_no             IS NOT NULL) 
                AND (gr_param.invoice_no_from   IS NOT NULL)
                AND (gr_param.invoice_no_to     IS NOT NULL)
                AND (xd1.invoice_no >= gr_param.invoice_no_from)
                AND (xd1.invoice_no <= gr_param.invoice_no_to)
              )
              OR
              -- 送り状No To がNOT NULLの場合
              (
                    (xd1.invoice_no             IS NOT NULL)
                AND (gr_param.invoice_no_from   IS NULL)
                AND (gr_param.invoice_no_to     IS NOT NULL)
                AND (xd1.invoice_no <= gr_param.invoice_no_to)
              )
              -- 送り状No From が NOT NULL の場合
              OR
              (
                    (xd1.invoice_no             IS NOT NULL) 
                AND (gr_param.invoice_no_from   IS NOT NULL)
                AND (gr_param.invoice_no_to     IS NULL)
                AND (xd1.invoice_no >= gr_param.invoice_no_from)
              )
            )
-- ##### 20080715 1.4 ST障害対応#444（記号対応） END   #####
-- E 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
-- S 2008/05/23 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--      AND   (  gr_param.prod_div          IS NULL
--            OR xd1.goods_classe            = gr_param.prod_div )          -- 商品区分
--      AND   (  gr_param.order_type        IS NULL
--            OR xd1.order_type              = gr_param.order_type )        -- 受注タイプ
--      AND   (  gr_param.wc_class          IS NULL
--            OR xd1.weight_capacity_class   = gr_param.wc_class )          -- 重量容積区分
--      AND   (  gr_param.outside_contract  IS NULL
--            OR xd1.outside_contract        = gr_param.outside_contract )  -- 契約外
      AND   xd1.goods_classe            = NVL( gr_param.prod_div        , xd1.goods_classe )
      AND   xd1.order_type              = NVL( gr_param.order_type      , xd1.order_type )
-- ##### 20080725 1.7 ST障害対応#456 START #####
--      AND   xd1.weight_capacity_class   = NVL( gr_param.wc_class        , xd1.weight_capacity_class  )
--      AND   xd1.outside_contract        = NVL( gr_param.outside_contract, xd1.outside_contract  )
      AND (
            ((gr_param.wc_class IS NOT NULL) AND (gr_param.wc_class = xd1.weight_capacity_class))
            OR
            ( gr_param.wc_class IS NULL)
          )
      AND (
            ((gr_param.outside_contract IS NOT NULL) AND (gr_param.outside_contract = xd1.outside_contract))
            OR
            ( gr_param.outside_contract IS NULL)
          )
-- ##### 20080725 1.7 ST障害対応#456 END   #####
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
      ORDER BY xcat.segment1
              ,xcar.party_number
              ,xd1.judgement_date
-- S 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- S --
              ,xd1.whs_code
              ,TO_NUMBER( xd1.delivery_no )
              ,NVL( xdl.whs_code, xd1.whs_code )
-- E 2008/10/15 1.10 MOD BY Y.Yamamoto -------------------------------------------------------- E --
              ,TO_NUMBER( xdl.request_no  )
    ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- メインデータ抽出
    -- ====================================================
    OPEN  cu_main ;
    FETCH cu_main BULK COLLECT INTO gt_main_data ;
    CLOSE cu_main ;
--
    -- ====================================================
    -- 配送先名称取得
    -- ====================================================
    <<loop_ship_to>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      BEGIN
        ------------------------------------------------------------
        -- 配送先コード区分が「1」の場合
        ------------------------------------------------------------
        IF ( gt_main_data(i).code_division = gc_code_division_s ) THEN
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--          SELECT xil.description
--          INTO   gt_main_data(i).ship_to_name
--          FROM xxcmn_item_locations_v   xil   -- OPM保管場所情報VIEW
--          WHERE xil.segment1 = gt_main_data(i).ship_to_code
--          ;
          SELECT SUBSTRB(xil.description ,1,30)
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_item_locations2_v   xil   -- OPM保管場所情報VIEW
          WHERE gt_main_data(i).judge_date
                  BETWEEN xil.date_from
                  AND     NVL( xil.date_to, gt_main_data(i).judge_date )
          AND xil.disable_date        IS NULL
          AND xil.segment1 = gt_main_data(i).ship_to_code
          ;
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
        ------------------------------------------------------------
        -- 配送先コード区分が「2」の場合
        ------------------------------------------------------------
        ELSIF ( gt_main_data(i).code_division = gc_code_division_p ) THEN
-- S 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- S --
--          SELECT xvs.vendor_site_name
--          INTO   gt_main_data(i).ship_to_name
--          FROM xxcmn_vendor_sites_v   xvs-- 仕入先サイト情報VIEW2
-- mod start ver 1.9
--          SELECT SUBSTRB(xvs.vendor_site_name ,1,30)
          SELECT xvs.vendor_site_short_name
-- mod end ver 1.9
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_vendor_sites2_v   xvs-- 仕入先サイト情報VIEW2
-- E 2008/07/24 1.6 MOD BY S.Takemoto---------------------------------------------------------- E --
          WHERE gt_main_data(i).judge_date
                  BETWEEN xvs.start_date_active
                  AND     NVL( xvs.end_date_active, gt_main_data(i).judge_date )
          AND   xvs.vendor_site_code = gt_main_data(i).ship_to_code
-- ##### 20081215 Ver.1.12 本番#40対応 START #####
          AND  xvs.inactive_date  IS NULL       -- 無効日
-- ##### 20081215 Ver.1.12 本番#40対応 END   #####
          ;
        ------------------------------------------------------------
        -- 配送先コード区分が「3」の場合
        ------------------------------------------------------------
        ELSIF ( gt_main_data(i).code_division = gc_code_division_m ) THEN
-- mod start ver 1.9
--          SELECT xps.party_site_short_name
          SELECT SUBSTRB(xps.party_site_full_name ,1,30)
-- mod end ver 1.9
          INTO   gt_main_data(i).ship_to_name
          FROM xxcmn_party_sites2_v   xps     -- パーティサイト情報VIEW2
          WHERE gt_main_data(i).judge_date
                  BETWEEN xps.start_date_active
                  AND     NVL( xps.end_date_active, gt_main_data(i).judge_date )
          AND   xps.party_site_number = gt_main_data(i).ship_to_code
-- ##### 20081215 Ver.1.12 本番#40対応 START #####
          AND xps.party_site_status     = 'A'         -- パーティサイトマスタ.ステータス
          AND xps.cust_acct_site_status = 'A'         -- 顧客サイトマスタ.ステータス
          AND xps.cust_site_uses_status = 'A'         -- 顧客使用目的マスタ.ステータス
-- ##### 20081215 Ver.1.12 本番#40対応 END   #####
          ;
        END IF ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_main_data(i).ship_to_name := NULL ;
-- ##### 20081215 Ver.1.12 本番#40対応 START #####
        WHEN TOO_MANY_ROWS THEN   -- *** データ取得エラー ***
          gt_main_data(i).ship_to_name := NULL ;
-- ##### 20081215 Ver.1.12 本番#40対応 END   #####
      END ;
    END LOOP loop_ship_to ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cu_main%ISOPEN THEN
        CLOSE cu_main ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_sql ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ編集
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    ld_judge_date_min       DATE DEFAULT  FND_DATE.CANONICAL_TO_DATE( gc_max_date_char ) ;
    ld_judge_date_max       DATE DEFAULT  FND_DATE.CANONICAL_TO_DATE( gc_min_date_char ) ;
--
    -- ブレイク判断用変数
    lv_prod_div             VARCHAR2(1)   DEFAULT lc_init ;
    lv_carrier              VARCHAR2(4)   DEFAULT lc_init ;
    lv_judge_date           VARCHAR2(10)  DEFAULT lc_init ;
    lv_delivery_no          VARCHAR2(12)  DEFAULT lc_init ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- リストグループ開始：データ情報
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ====================================================
    -- リストグループ開始：商品区分
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- ====================================================
      -- ブレイク判定：商品区分
      -- ====================================================
      IF ( lv_prod_div <> gt_main_data(i).prod_div ) THEN
        -- --------------------------------------------------
        -- 下層の終了タグ出力
        -- --------------------------------------------------
        -- 初回レコード以外の場合
        IF ( lv_prod_div <> lc_init ) THEN
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 判断日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 判断日リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 運送業者グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 運送業者リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始：商品区分
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 商品区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prod_div ;
        -- 商品区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prod_div_name ;
--
        -- ----------------------------------------------------
        -- リストグループ開始：運送業者
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_carrier' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_prod_div    := gt_main_data(i).prod_div ;
        lv_carrier     := lc_init ;
        lv_judge_date  := lc_init ;
        lv_delivery_no := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：運送業者
      -- ====================================================
      IF ( lv_carrier <> gt_main_data(i).carrier_code ) THEN
        -- --------------------------------------------------
        -- 下層の終了タグ出力
        -- --------------------------------------------------
        -- 初回レコード以外の場合
        IF ( lv_carrier <> lc_init ) THEN
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 判断日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 判断日リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 運送業者グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始：運送業者
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_carrier' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 運送業者コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'carrier_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).carrier_code ;
        -- 運送業者名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'carrier_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).carrier_name ;
--
        -- ----------------------------------------------------
        -- リストグループ開始：判断日
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_carrier     := gt_main_data(i).carrier_code ;
        lv_judge_date  := lc_init ;
        lv_delivery_no := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：判断日
      -- ====================================================
      IF ( lv_judge_date <> gt_main_data(i).judge_date_c ) THEN
        -- --------------------------------------------------
        -- 下層の終了タグ出力
        -- --------------------------------------------------
        -- 初回レコード以外の場合
        IF ( lv_judge_date <> lc_init ) THEN
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 判断日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始：判断日
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 判断日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).judge_date_c ;
--
        -- ----------------------------------------------------
        -- リストグループ開始：ヘッダ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_judge_date  := gt_main_data(i).judge_date_c ;
        lv_delivery_no := lc_init ;
--
        -- ----------------------------------------------------
        -- 最小値・最大値の退避
        -- ----------------------------------------------------
        -- 最小値
        IF ( ld_judge_date_min > gt_main_data(i).judge_date ) THEN
          ld_judge_date_min := gt_main_data(i).judge_date ;
        END IF ;
        -- 最大値
        IF ( ld_judge_date_max < gt_main_data(i).judge_date ) THEN
          ld_judge_date_max := gt_main_data(i).judge_date ;
        END IF ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：ヘッダ
      -- ====================================================
      IF ( lv_delivery_no <> gt_main_data(i).delivery_no ) THEN
        -- --------------------------------------------------
        -- 下層の終了タグ出力
        -- --------------------------------------------------
        -- 初回レコード以外の場合
        IF ( lv_delivery_no <> lc_init ) THEN
          -- 明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始：判断日
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 発日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_date ;
        -- 着日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).arrival_date ;
        -- 配送No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_no ;
        -- 距離１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'distance_1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).distance_1 ;
        -- 運送業者：契約運賃
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_kei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_kei ;
        -- 運送業者：混載割増
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_kon' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_kon ;
        -- 運送業者：PIC
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_pic' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_pic ;
        -- 運送業者：諸料金
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_oth' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_oth ;
        -- 運送業者：支払合計
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_sum' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_sum ;
        -- 運送業者：通行料等
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'c_tsu' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).c_tsu ;
        -- 伊藤園：契約運賃
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_kei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_kei ;
        -- 伊藤園：請求運賃
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_sei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_sei ;
        -- 伊藤園：混載割増
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_kon' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_kon ;
        -- 伊藤園：PIC
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_pic' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_pic ;
        -- 伊藤園：諸料金
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_oth' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_oth ;
        -- 伊藤園：請求合計
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_sum' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_sum ;
        -- 伊藤園：通行料等
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'i_tsu' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_tsu ;
        -- 差異
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'balance' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).balance ;
--
        -- ----------------------------------------------------
        -- リストグループ開始：明細
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_delivery_no := gt_main_data(i).delivery_no ;
--
      END IF ;
--
      -- ====================================================
      -- 明細グループ出力
      -- ====================================================
      -- ----------------------------------------------------
      -- グループ開始：明細
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- 出庫倉庫
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'whs_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).whs_code ;
      -- 依頼No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
      -- 送り状No
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'invoice_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).invoice_no ;
      -- 配送先
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_to_code ;
      -- 配送先名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_to_name ;
      -- 距離２
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'distance_2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).distance_2 ;
      -- 数量
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'qty' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).qty ;
      -- 重量
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'weight' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).weight ;
      -- 配送区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliv_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).deliv_div ;
--
      -- ----------------------------------------------------
      -- グループ終了：明細
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_loop ;
--
    -- ====================================================
    -- 終了タグ出力
    -- ====================================================
    -- 明細リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ヘッダグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- ヘッダリストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 判断日グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_judge_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 判断日リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_judge_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 運送業者グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_carrier' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 運送業者リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_carrier' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 商品区分グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 商品区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- 判断日出力
    -- --------------------------------------------------
    -- 判断日From
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date_min' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ld_judge_date_min, 'YYYY/MM/DD' ) ;
    -- 判断日To
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'judge_date_max' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ld_judge_date_max, 'YYYY/MM/DD' ) ;
--
    -- ====================================================
    -- リストグループ終了：データ情報
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --データの場合
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_prod_div           IN     VARCHAR2         -- 01 : 商品区分
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : 運送業者From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : 運送業者To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : 出庫元倉庫From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : 出庫元倉庫To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : 出庫日From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : 出庫日To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : 着日From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : 着日To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : 決済日From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : 決済日To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : 報告日From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : 報告日To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : 配送NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : 配送NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : 依頼NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : 依頼NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : 送り状NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : 送り状NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : 受注タイプ
     ,iv_wc_class           IN     VARCHAR2         -- 21 : 重量容積区分
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : 契約外
     ,iv_return_flag        IN     VARCHAR2         -- 23 : 確定後変更
     ,iv_output_flag        IN     VARCHAR2         -- 24 : 差異
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.prod_div            := iv_prod_div ;           -- 01 : 商品区分
    gr_param.carrier_code_from   := iv_carrier_code_from ;  -- 02 : 運送業者From
    gr_param.carrier_code_to     := iv_carrier_code_to ;    -- 03 : 運送業者To
    gr_param.whs_code_from       := iv_whs_code_from ;      -- 04 : 出庫元倉庫From
    gr_param.whs_code_to         := iv_whs_code_to ;        -- 05 : 出庫元倉庫To
    gr_param.ship_date_from      := FND_DATE.CANONICAL_TO_DATE( iv_ship_date_from    ) ;
    gr_param.ship_date_to        := FND_DATE.CANONICAL_TO_DATE( iv_ship_date_to      ) ;
    gr_param.arrival_date_from   := FND_DATE.CANONICAL_TO_DATE( iv_arrival_date_from ) ;
    gr_param.arrival_date_to     := FND_DATE.CANONICAL_TO_DATE( iv_arrival_date_to   ) ;
    gr_param.judge_date_from     := FND_DATE.CANONICAL_TO_DATE( iv_judge_date_from   ) ;
    gr_param.judge_date_to       := FND_DATE.CANONICAL_TO_DATE( iv_judge_date_to     ) ;
    gr_param.report_date_from    := FND_DATE.CANONICAL_TO_DATE( iv_report_date_from  ) ;
    gr_param.report_date_to      := FND_DATE.CANONICAL_TO_DATE( iv_report_date_to    ) ;
    gr_param.delivery_no_from    := iv_delivery_no_from ;   -- 14 : 配送NoFrom
    gr_param.delivery_no_to      := iv_delivery_no_to ;     -- 15 : 配送NoTo
    gr_param.request_no_from     := iv_request_no_from ;    -- 16 : 依頼NoFrom
    gr_param.request_no_to       := iv_request_no_to ;      -- 17 : 依頼NoTo
    gr_param.invoice_no_from     := iv_invoice_no_from ;    -- 18 : 送り状NoFrom
    gr_param.invoice_no_to       := iv_invoice_no_to ;      -- 19 : 送り状NoTo
    gr_param.order_type          := iv_order_type ;         -- 20 : 受注タイプ
    gr_param.wc_class            := iv_wc_class ;           -- 21 : 重量容積区分
    gr_param.outside_contract    := iv_outside_contract ;   -- 22 : 契約外
    gr_param.return_flag         := iv_return_flag ;        -- 23 : 確定後変更
    gr_param.output_flag         := iv_output_flag ;        -- 24 : 差異
--
    -- =====================================================
    -- パラメータチェック
    -- =====================================================
    prc_chk_param
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;

    -- =====================================================
    -- メインデータ取得
    -- =====================================================
    prc_create_sql
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    --------------------------------------------------------
    -- データがない場合
    --------------------------------------------------------
    IF ( gt_main_data.COUNT = 0 ) THEN
      -- --------------------------------------------------
      -- ０件メッセージの取得
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- メッセージの設定
      -- --------------------------------------------------
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis"?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_carrier>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    ELSE
      -- =====================================================
      -- ログインユーザー情報出力
      -- =====================================================
      prc_create_xml_data_user
        (
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ＸＭＬファイルデータ編集
      -- =====================================================
      prc_create_xml_data
        (
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- 帳票出力
      -- =====================================================
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- --------------------------------------------------
      -- データ部出力
      -- --------------------------------------------------
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_prod_div           IN     VARCHAR2         -- 01 : 商品区分
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : 運送業者From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : 運送業者To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : 出庫元倉庫From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : 出庫元倉庫To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : 出庫日From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : 出庫日To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : 着日From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : 着日To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : 決済日From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : 決済日To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : 報告日From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : 報告日To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : 配送NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : 配送NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : 依頼NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : 依頼NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : 送り状NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : 送り状NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : 受注タイプ
     ,iv_wc_class           IN     VARCHAR2         -- 21 : 重量容積区分
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : 契約外
     ,iv_return_flag        IN     VARCHAR2         -- 23 : 確定後変更
     ,iv_output_flag        IN     VARCHAR2         -- 24 : 差異
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- プログラム名
    -- ======================================================
    -- ローカル定数
    -- ======================================================
-- *----------* 2009/07/01 本番#1551対応 start *----------*
-- 既存のローカル定数の設定をコメントアウト
-- グローバル定数を代入するように修正
-- lc_invoice_no_minとlc_invoice_no_maxは使用していない
--
--    lc_carrier_code_min   CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
-- ##### 20080715 1.3 ST障害対応#444 START #####
--    lc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT '9999' ;
--    lc_carrier_code_max   CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
-- ##### 20080715 1.3 ST障害対応#444 END   #####
--    lc_whs_code_min       CONSTANT VARCHAR2(4)  DEFAULT '0000' ;
-- ##### 20080715 1.3 ST障害対応#444 START #####
--    lc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT '9999' ;
--    lc_whs_code_max       CONSTANT VARCHAR2(4)  DEFAULT 'ZZZZ' ;
-- ##### 20080715 1.3 ST障害対応#444 END   #####
--    lc_delivery_no_min    CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
--    lc_delivery_no_max    CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--    lc_request_no_min     CONSTANT VARCHAR2(12) DEFAULT '000000000000' ;
--    lc_request_no_max     CONSTANT VARCHAR2(12) DEFAULT '999999999999' ;
--    lc_invoice_no_min     CONSTANT VARCHAR2(20) DEFAULT '00000000000000000000' ;
-- ##### 20080715 1.3 ST障害対応#444 START #####
--    lc_invoice_no_max     CONSTANT VARCHAR2(20) DEFAULT '99999999999999999999' ;
--    lc_invoice_no_max     CONSTANT VARCHAR2(20) DEFAULT 'ZZZZZZZZZZZZZZZZZZZZ' ;
-- ##### 20080715 1.3 ST障害対応#444 END   #####
--
    lc_carrier_code_min   CONSTANT VARCHAR2(4)  := gc_carrier_code_min;
    lc_carrier_code_max   CONSTANT VARCHAR2(4)  := gc_carrier_code_max;
    lc_whs_code_min       CONSTANT VARCHAR2(4)  := gc_whs_code_min    ;
    lc_whs_code_max       CONSTANT VARCHAR2(4)  := gc_whs_code_max    ;
    lc_delivery_no_min    CONSTANT VARCHAR2(12) := gc_delivery_no_min ;
    lc_delivery_no_max    CONSTANT VARCHAR2(12) := gc_delivery_no_max ;
    lc_request_no_min     CONSTANT VARCHAR2(12) := gc_request_no_min  ;
    lc_request_no_max     CONSTANT VARCHAR2(12) := gc_request_no_max  ;
--
-- *----------* 2009/07/01 本番#1551対応 end   *----------*
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain
      (
        iv_prod_div           => iv_prod_div           -- 01 : 商品区分
       ,iv_carrier_code_from  => NVL( iv_carrier_code_from, lc_carrier_code_min )
       ,iv_carrier_code_to    => NVL( iv_carrier_code_to  , lc_carrier_code_max )
       ,iv_whs_code_from      => NVL( iv_whs_code_from    , lc_whs_code_min )
       ,iv_whs_code_to        => NVL( iv_whs_code_to      , lc_whs_code_max )
       ,iv_ship_date_from     => NVL( iv_ship_date_from   , gc_min_date_char )
       ,iv_ship_date_to       => NVL( iv_ship_date_to     , gc_max_date_char )
       ,iv_arrival_date_from  => NVL( iv_arrival_date_from, gc_min_date_char )
       ,iv_arrival_date_to    => NVL( iv_arrival_date_to  , gc_max_date_char )
       ,iv_judge_date_from    => NVL( iv_judge_date_from  , gc_min_date_char )
       ,iv_judge_date_to      => NVL( iv_judge_date_to    , gc_max_date_char )
       ,iv_report_date_from   => NVL( iv_report_date_from , gc_min_date_char )
       ,iv_report_date_to     => NVL( iv_report_date_to   , gc_max_date_char )
       ,iv_delivery_no_from   => NVL( iv_delivery_no_from , lc_delivery_no_min )
       ,iv_delivery_no_to     => NVL( iv_delivery_no_to   , lc_delivery_no_max )
       ,iv_request_no_from    => NVL( iv_request_no_from  , lc_request_no_min )
       ,iv_request_no_to      => NVL( iv_request_no_to    , lc_request_no_max )
-- ##### 20080715 1.4 ST障害対応#444（記号対応） START #####
--       ,iv_invoice_no_from    => NVL( iv_invoice_no_from  , lc_invoice_no_min )
--       ,iv_invoice_no_to      => NVL( iv_invoice_no_to    , lc_invoice_no_max )
       ,iv_invoice_no_from    => iv_invoice_no_from
       ,iv_invoice_no_to      => iv_invoice_no_to
-- ##### 20080715 1.4 ST障害対応#444（記号対応） END   #####
       ,iv_order_type         => iv_order_type         -- 20 : 受注タイプ
       ,iv_wc_class           => iv_wc_class           -- 21 : 重量容積区分
       ,iv_outside_contract   => iv_outside_contract   -- 22 : 契約外
       ,iv_return_flag        => iv_return_flag        -- 23 : 確定後変更
       ,iv_output_flag        => iv_output_flag        -- 24 : 差異
       ,ov_errbuf             => lv_errbuf            -- エラー・メッセージ
       ,ov_retcode            => lv_retcode           -- リターン・コード
       ,ov_errmsg             => lv_errmsg            -- ユーザー・エラー・メッセージ
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwip730005c ;
/
