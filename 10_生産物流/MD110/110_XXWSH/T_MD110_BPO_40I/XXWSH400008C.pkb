create or replace PACKAGE BODY xxwsh400008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400008c(body)
 * Description      : 生産物流（出荷）
 * MD.050           : 出荷依頼 T_MD050_BPO_401
 * MD.070           : 出荷調整表 T_MD070_BPO_40I
 * Version          : 1.13
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                   FUNCTION   : ＸＭＬタグに変換する。
 *  prc_out_xml_data               PROCEDURE  : ＸＭＬ出力処理
 *  prc_create_zeroken_xml_data    PROCEDURE  : ＸＭＬデータ作成処理（０件）
 *  prc_create_xml_data            PROCEDURE  : ＸＭＬデータ作成処理
 *  prc_get_chosei_data            PROCEDURE  : 出荷調整表情報取得処理
 *  prc_plan_confirm_marge_data    PROCEDURE  : 計画数・予実数マージ処理
 *  prc_get_drink_subtotal_data    PROCEDURE  : ドリンク累計数算出処理
 *  prc_get_drink_confirm_data     PROCEDURE  : ドリンク予実数取得処理
 *  prc_get_drink_plan_data        PROCEDURE  : ドリンク計画数取得処理
 *  prc_get_bucket_data            PROCEDURE  : バケット日付取得処理
 *  prc_get_drink_info             PROCEDURE  : ドリンク情報取得処理
 *  prc_get_leaf_zensha_data       PROCEDURE  : リーフ全社数取得処理
 *  prc_get_leaf_total_mon_data    PROCEDURE  : リーフ累計数・月間数算出処理
 *  prc_get_leaf_confirm_data      PROCEDURE  : リーフ予実数取得処理
 *  prc_get_leaf_plan_data         PROCEDURE  : リーフ計画数取得処理
 *  prc_get_leaf_info              PROCEDURE  : リーフ情報取得処理
 *  prc_get_shipped_locat          PROCEDURE  : 出庫元情報取得処理
 *  prc_get_profile                PROCEDURE  : 抽出対象ステータス取得処理
 *  prc_check_input_data           PROCEDURE  : 入力パラメータチェック処理
 *  submain                        PROCEDURE  : メイン処理プロシージャ
 *  main                           PROCEDURE  : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/04/10    1.0   Masakazu Yamashita    新規作成
 *  2008/06/19    1.1   Yasuhisa Yamamoto     システムテスト障害対応
 *  2008/06/26    1.2   ToshikazuIshiwata     システムテスト障害対応(#309)
 *  2008/07/02    1.3   Naoki Fukuda          ST不具合対応(#373)
 *  2008/07/02    1.4   Satoshi Yunba         禁則文字対応
 *  2008/07/23    1.5   Naoki Fukuda          ST不具合対応(#475)
 *  2008/08/20    1.6   Takao Ohashi          変更#183,T_S_612対応
 *  2008/09/01    1.7   Hitomi Itou           PT 2-1_10対応
 *  2008/11/14    1.8   Tsuyoki Yoshimoto     内部変更#168対応
 *  2008/12/09    1.9   Akiyoshi Shiina       本番#607対応
 *  2008/12/22    1.10  Takao Ohashi          本番#640対応
 *  2008/12/24    1.11  Masayoshi Uehara      本番#640対応
 *  2008/12/25    1.12  Masayoshi Uehara      本番#640対応取消(ver1.11は残し、ver1.9をver1.12に更新)
 *  2009/01/15    1.13  Yasuhisa Yamamoto     本番#1021対応
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
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  -- パッケージ名
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWSH400008C' ;
  -- 帳票ID
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWSH400008T' ;
--
  -- 処理区分
  gv_syori_kbn_leaf             CONSTANT VARCHAR2(1) := '1';                    -- リーフ
  gv_syori_kbn_drink            CONSTANT VARCHAR2(1) := '2';                    -- ドリンク
  -- ステータス（出荷実績計上済）
  gv_req_status                 CONSTANT VARCHAR2(10) := '04';
  -- クイックコード（出荷調整抽出対象ステータス種別）
  gv_lookup_type1               CONSTANT VARCHAR2(100) := 'XXWSH_401J_EXTRACT_STATUS';
  -- 計画商品フラグ
  gv_plan_syohin_flg            CONSTANT VARCHAR2(1) := '1';                    -- 計画商品対象
  -- フォーキャスト分類（計画商品引取計画）
  gv_forecast_kbn_ksyohin       CONSTANT VARCHAR2(10) := '09';
  -- フォーキャスト分類（引取計画）
  gv_forecast_kbn_hkeikaku      CONSTANT VARCHAR2(10) := '01';
  -- 抽出対象ステータス（拠点パターン）
  --gv_select_status_kyoten       CONSTANT VARCHAR2(10) := '1';   --2008/07/02 ST不具合対応(#373)
    gv_select_status_kyoten       CONSTANT VARCHAR2(10) := '2';     --2008/07/02 ST不具合対応(#373)
--
  -- エラーメッセージ関連
  gc_application_cmn            CONSTANT VARCHAR2(10) := 'XXCMN' ;
  gv_msg_xxcmn10002             CONSTANT VARCHAR2(50) := 'APP-XXCMN-10002';
  gv_msg_xxcmn10122             CONSTANT VARCHAR2(50) := 'APP-XXCMN-10122';
--
  gc_application_wsh            CONSTANT VARCHAR2(10) := 'XXWSH';
  gv_msg_xxwsh11402             CONSTANT VARCHAR2(50) := 'APP-XXWSH-11402';
  gv_msg_tkn_pram               CONSTANT VARCHAR2(10) := 'PARAMETER';
  gv_msg_contents               CONSTANT VARCHAR2(10) := '着日';
  gv_msg_xxwsh11403             CONSTANT VARCHAR2(50) := 'APP-XXWSH-11403';
--
  -- トークン：プロファイル名
  gv_tkn_profile                CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  -- プロファイルID
  gv_profile_id                 CONSTANT VARCHAR2(50) := 'XXWSH_EXTRACT_PATTERN_401J';
  -- プロファイル名称
  gv_profile_name               CONSTANT VARCHAR2(50) := 'XXWSH:出荷調整表抽出パターン';
--
  -- 日付フォーマット
  gv_date_format1               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD HH24:MI';  -- 年月日時分
  gv_date_format2               CONSTANT VARCHAR2(18) := 'YYYY/MM/DD';          -- 年月日
--
-- 2008/12/09 v1.9 ADD START
  gv_n                          CONSTANT VARCHAR2(1) := 'N';
-- 2008/12/09 v1.9 ADD END
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- リーフ計画数データ格納用レコード変数
  TYPE type_leaf_plan_data_rec IS RECORD (
        -- 拠点コード
        head_sales_branch           mrp_forecast_designators.attribute3%TYPE
        -- 品目コード
       ,item_code                   xxcmn_item_mst_v.item_no%TYPE
        -- 品目名
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- 着日
       ,arrival_date                mrp_forecast_dates.forecast_date%TYPE
       -- 計画数
       ,plan_quantity               NUMBER
    ) ;
  TYPE type_leaf_plan_data_tbl IS TABLE OF type_leaf_plan_data_rec INDEX BY PLS_INTEGER ;
--
  -- リーフ予実数データ格納用レコード変数
  TYPE type_leaf_confirm_data_rec IS RECORD (
        -- 拠点コード
        head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
        -- 品目コード
       ,item_code                   xxwsh_order_lines_all.request_item_code%TYPE
        -- 品目名
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- 着日
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
        -- 計画数
       ,confirm_quantity            NUMBER
    ) ;
  TYPE type_leaf_confirm_data_tbl IS TABLE OF type_leaf_confirm_data_rec INDEX BY PLS_INTEGER ;
--
  -- リーフ累計数・月間数格納用レコード変数
  TYPE type_leaf_total_mon_rec IS RECORD 
    (
        -- 拠点コード
        head_sales_branch           xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
        -- 品目コード
       ,item_code                   xxwsh_ship_adjust_days_tmp.item_code%TYPE
        -- 品目名
       ,item_name                   xxwsh_ship_adjust_days_tmp.item_name%TYPE
       -- 着日
       ,arrival_date                xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
        -- 計画数（着日）
       ,plan_quantity               xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- 予実数（着日）
       ,confirm_quantity            xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- 計画数（累計）
       ,plan_subtotal_quantity      xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- 予実数（累計）
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- 計画数（月間）
       ,plan_monthly_quantity       xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- 予実数（月間）
       ,confirm_monthly_quantity    xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_leaf_total_mon_tbl IS TABLE OF type_leaf_total_mon_rec INDEX BY BINARY_INTEGER ;
--
  -- リーフ全社数格納用レコード変数
  TYPE type_leaf_zensha_data_rec IS RECORD 
    (
        -- 品目コード
        item_code                   xxwsh_ship_adjust_all_tmp.item_code%TYPE
        -- 計画数
       ,plan_quantity               xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
        -- 予実数
       ,confirm_quantity            xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_leaf_zensha_data_tbl IS TABLE OF type_leaf_zensha_data_rec INDEX BY BINARY_INTEGER ;
--
  -- ドリンク計画数データ格納用レコード変数
  TYPE type_drink_plan_data_rec IS RECORD (
        -- 拠点コード
        head_sales_branch           xxcmn_sourcing_rules.base_code%TYPE
        -- 品目コード
       ,item_code                   xxcmn_sourcing_rules.item_code%TYPE
        -- 品目名
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- 着日
       ,arrival_date                mrp_forecast_dates.forecast_date%TYPE
        -- 計画数
       ,plan_quantity               NUMBER
    ) ;
  TYPE type_drink_plan_data_tbl IS TABLE OF type_drink_plan_data_rec INDEX BY PLS_INTEGER ;
--
  -- ドリンク予実数データ格納用レコード変数
  TYPE type_drink_confirm_data_rec IS RECORD (
        -- 拠点コード
        head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE
        -- 品目コード
       ,item_code                   xxwsh_order_lines_all.request_item_code%TYPE
        -- 品目名
       ,item_name                   xxcmn_item_mst_v.item_short_name%TYPE
        -- 着日
       ,arrival_date                xxwsh_order_headers_all.schedule_arrival_date%TYPE
        -- 予実数
       ,confirm_quantity            NUMBER
    ) ;
  TYPE type_drink_confirm_data_tbl IS TABLE OF type_drink_confirm_data_rec INDEX BY PLS_INTEGER ;
--
  -- ドリンク累計数格納用レコード変数
  TYPE type_drink_total_mon_rec IS RECORD 
    (
        -- 拠点コード
        head_sales_branch           xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
        -- 品目コード
       ,item_code                   xxwsh_ship_adjust_days_tmp.item_code%TYPE
        -- 品目名
       ,item_name                   xxwsh_ship_adjust_days_tmp.item_name%TYPE
        -- 着日
       ,arrival_date                xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
        -- 計画数（着日）
       ,plan_quantity               xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- 予実数（着日）
       ,confirm_quantity            xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- 計画数（累計）
       ,plan_subtotal_quantity      xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
        -- 予実数（累計）
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
        -- 計画数（月間）
       ,plan_monthly_quantity       NUMBER
        -- 予実数（月間）
       ,confirm_monthly_quantity    NUMBER
    ) ;
  TYPE type_drink_total_mon_tbl IS TABLE OF type_drink_total_mon_rec INDEX BY BINARY_INTEGER ;
--
  -- 出荷調整表データレコード変数
  TYPE type_chosei_data_rec IS RECORD 
    (
        -- 拠点コード
        head_sales_branch           xxwsh_ship_adjust_total_tmp.head_sales_branch%TYPE
        -- 拠点名
       ,kyoten_nm                   xxcmn_cust_accounts2_v.party_short_name%TYPE
        -- 品目コード
       ,item_code                   xxwsh_ship_adjust_total_tmp.item_code%TYPE
        -- 品目名
       ,item_name                   xxwsh_ship_adjust_total_tmp.item_name%TYPE
        -- 着日
       ,arrival_date                xxwsh_ship_adjust_total_tmp.arrival_date%TYPE
        -- 計画数（着日）
       ,plan_quantity               xxwsh_ship_adjust_total_tmp.plan_quantity%TYPE
        -- 予実数（着日）
       ,confirm_quantity            xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
        -- 計画数（累計）
       ,plan_subtotal_quantity      xxwsh_ship_adjust_total_tmp.plan_subtotal_quantity%TYPE
        -- 予実数（累計）
       ,confirm_subtotal_quantity   xxwsh_ship_adjust_total_tmp.confirm_subtotal_quantity%TYPE
        -- 計画数（月間）
       ,monthly_plan_quantity       xxwsh_ship_adjust_total_tmp.monthly_plan_quantity%TYPE
        -- 予実数（月間）
       ,monthly_confirm_quantity    xxwsh_ship_adjust_total_tmp.monthly_confirm_quantity%TYPE
        -- 計画数（全社）
       ,zensha_plan_quantity        xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
        -- 予実数（全社）
       ,zensha_confirm_quantity     xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    ) ;
  TYPE type_chosei_data_tbl IS TABLE OF type_chosei_data_rec INDEX BY BINARY_INTEGER ;
--
  -- 出荷調整表日別中間テーブル情報(FORALLでのINSERT用)
  TYPE day_head_sales_branch                                             -- 拠点コード
    IS TABLE OF xxwsh_ship_adjust_days_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_item_code                                                     -- 品目コード
    IS TABLE OF xxwsh_ship_adjust_days_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_item_name                                                     -- 品目名
    IS TABLE OF xxwsh_ship_adjust_days_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_arrival_date                                                  -- 着日
    IS TABLE OF xxwsh_ship_adjust_days_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_plan_quantity                                                 -- 計画数
    IS TABLE OF xxwsh_ship_adjust_days_tmp.plan_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE day_confirm_quantity                                              -- 予実数
    IS TABLE OF xxwsh_ship_adjust_days_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- 出荷調整表全社中間テーブル情報(FORALLでのINSERT用)
  TYPE all_item_code                                                     -- 品目コード
    IS TABLE OF xxwsh_ship_adjust_all_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE all_plan_quantity                                                 -- 計画数
    IS TABLE OF xxwsh_ship_adjust_all_tmp.plan_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE all_confirm_quantity                                              -- 予実数
    IS TABLE OF xxwsh_ship_adjust_all_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- 出荷調整表予実中間テーブル
  TYPE plan_head_sales_branch                                            -- 拠点コード
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_item_code                                                    -- 品目コード
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_item_name                                                    -- 品目名
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_arrival_date                                                 -- 着日
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE plan_confirm_quantity                                             -- 予実数
    IS TABLE OF xxwsh_shippng_adj_plan_act_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  -- 出荷調整表集計中間テーブル
  TYPE i_head_sales_branch                                               -- 拠点コード
    IS TABLE OF xxwsh_ship_adjust_total_tmp.head_sales_branch%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                                                       -- 品目コード
    IS TABLE OF xxwsh_ship_adjust_total_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_name                                                       -- 品目名
    IS TABLE OF xxwsh_ship_adjust_total_tmp.item_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_arrival_date                                                    -- 着日
    IS TABLE OF xxwsh_ship_adjust_total_tmp.arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_quantity                                                   -- 計画数（着日）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_quantity                                                -- 予実数（着日）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_subtotal_quantity                                          -- 計画数（累計）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_subtotal_quantity                                       -- 予実数（累計）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_plan_monthly_quantity                                           -- 計画数（月間）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_confirm_monthly_quantity                                        -- 予実数（月間）
    IS TABLE OF xxwsh_ship_adjust_total_tmp.confirm_quantity%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 出荷調整表バケット中間テーブル
  TYPE i_bucket_date
    IS TABLE OF xxwsh_shippng_adj_bucket_tmp.bucket_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 出荷調整表日別中間テーブル(FORALLでのINSERT用)
  gt_day_head_sales_branch              day_head_sales_branch;           -- 拠点コード
  gt_day_item_code                      day_item_code;                   -- 品目コード
  gt_day_item_name                      day_item_name;                   -- 品目名
  gt_day_arrival_date                   day_arrival_date;                -- 着日
  gt_day_plan_quantity                  day_plan_quantity;               -- 計画数（着日）
  gt_day_confirm_quantity               day_confirm_quantity;            -- 予実数（着日）
  -- 出荷調整表全社中間テーブル(FORALLでのINSERT用)
  gt_all_item_code                      all_item_code;                   -- 品目コード
  gt_all_plan_quantity                  all_plan_quantity;               -- 計画数
  gt_all_confirm_quantity               all_confirm_quantity;            -- 予実数
  -- 出荷調整表予実中間テーブル(FORALLでのINSERT用)
  gt_plan_head_sales_branch             plan_head_sales_branch;          -- 拠点コード
  gt_plan_item_code                     plan_item_code;                  -- 品目コード
  gt_plan_item_name                     plan_item_name;                  -- 品目名
  gt_plan_arrival_date                  plan_arrival_date;                  -- 着日
  gt_plan_confirm_quantity              plan_confirm_quantity;           -- 予実数（着日）
  -- 出荷調整表集計中間テーブル(FORALLでのINSERT用)
  gt_i_head_sales_branch            i_head_sales_branch;                 -- 拠点コード
  gt_i_item_code                    i_item_code;                         -- 品目コード
  gt_i_item_name                    i_item_name;                         -- 品目名
  gt_i_arrival_date                 i_arrival_date;                      -- 着日
  gt_i_plan_quantity                i_plan_quantity;                     -- 計画数（着日）
  gt_i_confirm_quantity             i_confirm_quantity;                  -- 予実数（着日）
  gt_i_plan_subtotal_quantity       i_plan_subtotal_quantity;            -- 計画数（累計）
  gt_i_confirm_subtotal_quantity    i_confirm_subtotal_quantity;         -- 予実数（累計）
  gt_i_plan_monthly_quantity        i_plan_monthly_quantity;             -- 計画数（月間）
  gt_i_confirm_monthly_quantity     i_confirm_monthly_quantity;          -- 予実数（月間）
  -- 出荷調整表バケット中間テーブル(FORALLでのINSERT用)
  gt_i_bucket_data                      i_bucket_date;                   -- バケット日付
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_syukkomoto_cd         xxcmn_item_locations_v.segment1%TYPE;
  gv_syukkomoto_nm         xxcmn_item_locations_v.description%TYPE;
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
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
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- プログラム名
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
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml_data
   * Description      : ＸＭＬ出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT NOCOPY VARCHAR2             --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT NOCOPY VARCHAR2             --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT NOCOPY VARCHAR2             --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================================
    -- ＸＭＬ出力処理
    -- ==================================================
    -- 開始タグ出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_chosei_info>' ) ;
--
    <<xml_data_table>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := fnc_conv_xml
                        (
                          iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                         ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                         ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- 終了タグ出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_chosei_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_out_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : 取得件数０件時ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 帳票タイトル
    lv_chohyo_title           VARCHAR2(10) DEFAULT NULL;
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 調整Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chosei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- メッセージ出力タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'msg';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,gv_msg_xxcmn10122 ) ;
--
    -- -----------------------------------------------------
    -- 明細LG開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 明細G開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 明細G終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 明細LG終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- 調整Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chosei' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_zeroken_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成処理
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iv_syori_kbn      IN  VARCHAR2                 -- 処理区分
     ,it_chosei_data    IN  type_chosei_data_tbl     -- 出荷調整表情報
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 拠点コードブレイク用変数
    lv_head_sales_branch_break      VARCHAR2(10) DEFAULT '*';
    -- 初回レコード
    ln_break_init                   NUMBER DEFAULT 1;
    -- 拠点計計画数（着日）サマリ用変数
    ln_plan_arrive_total            NUMBER DEFAULT 0;
    -- 拠点計予実数（着日）サマリ用変数
    ln_confirm_arrive_total         NUMBER DEFAULT 0;
    -- 拠点計計画数（累計）サマリ用変数
    ln_plan_subtotal_total          NUMBER DEFAULT 0;
    -- 拠点計予実数（累計）サマリ用変数
    ln_confirm_subtotal_total       NUMBER DEFAULT 0;
    -- 拠点計計画数（月間）サマリ用変数
    ln_plan_monthly_total           NUMBER DEFAULT 0;
    -- 拠点計予実数（月間）サマリ用変数
    ln_confirm_monthly_total        NUMBER DEFAULT 0;
    -- 実行日付
    ld_now_date                     DATE DEFAULT SYSDATE;
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 出荷調整表ループ
    -- -----------------------------------------------------
    <<chosei_data_loop>>
    FOR l_cnt IN 1..it_chosei_data.COUNT + 1 LOOP
--
      -- 終了タグ出力判定
      -- ブレイク判定
      IF (   l_cnt > it_chosei_data.COUNT
          OR lv_head_sales_branch_break <> it_chosei_data(l_cnt).head_sales_branch) THEN
--
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( l_cnt <> ln_break_init ) THEN
          ------------------------------
          -- 明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 明細合計LG開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 明細合計G開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 集計値出力
          ------------------------------
          -- リーフの場合出力
          IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
            -- 拠点計計画数（着日）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_arrive_total ;
            -- 拠点計予実数（着日）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_arrive_total ;
            -- 拠点計差異数（着日）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_arrive_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_arrive_total
                                                                  - ln_confirm_arrive_total ;
          END IF;
          -- 拠点計計画数（累計）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_subtotal_total ;
          -- 拠点計予実数（累計）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_subtotal_total ;
          -- 拠点計差異数（累計）
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_subtotal_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_subtotal_total
                                                                  - ln_confirm_subtotal_total ;
          -- リーフの場合出力
          IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
            -- 拠点計計画数（月間）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_monthly_total ;
            -- 拠点計予実数（月間）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_confirm_monthly_total ;
            -- 拠点計差異数（月間）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_monthly_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_plan_monthly_total
                                                                  - ln_confirm_monthly_total ;
-- 2008/06/19 Y.Yamamoto V1.1 Update Start
-- 0除算対応
            -- 拠点計達成率（月間）
          IF (ln_plan_monthly_total <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'tassei_ritu_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := TRUNC(ln_confirm_monthly_total /
                                                                  ln_plan_monthly_total * 100, 2) ;
          END IF;
-- 2008/06/19 Y.Yamamoto V1.1 Update End
          END IF;
          -- -----------------------------------------------------
          -- 集計値クリア処理
          -- -----------------------------------------------------
          -- 拠点計計画数（着日）サマリ用変数
          ln_plan_arrive_total           := 0;
          -- 拠点計予実数（着日）サマリ用変数
          ln_confirm_arrive_total        := 0;
          -- 拠点計計画数（累計）サマリ用変数
          ln_plan_subtotal_total         := 0;
          -- 拠点計予実数（累計）サマリ用変数
          ln_confirm_subtotal_total      := 0;
          -- 拠点計計画数（月間）サマリ用変数
          ln_plan_monthly_total          := 0;
          -- 拠点計予実数（月間）サマリ用変数
          ln_confirm_monthly_total       := 0;
--
          ------------------------------
          -- 明細合計G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 明細合計LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_total_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- -----------------------------------------------------
          -- 出荷調整Ｇ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_chosei' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF;
--
        -- 出力処理終了
        EXIT WHEN (l_cnt > it_chosei_data.COUNT);
--
        -- -----------------------------------------------------
        -- 出荷調整Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_chosei' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- 【データ】帳票ID
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
        -- 【データ】発行日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(ld_now_date, gv_date_format1);
--
        -- 【データ】拠点コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kyoten_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).head_sales_branch;
--
        -- 【データ】拠点名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'kyoten_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).kyoten_nm;
--
        -- 【データ】着日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( it_chosei_data(l_cnt).arrival_date
                                                           ,gv_date_format2);
--
        -- 【データ】出庫元コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syukkomoto_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_syukkomoto_cd;
--
        -- 【データ】出庫元名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'syukkomoto_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_syukkomoto_nm;
--
        -- 【データ】担当部署
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_busho';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
--
        -- 【データ】担当名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tanto_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID);
--
        -- -----------------------------------------------------
        -- 明細情報Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- ブレイクキー更新
        lv_head_sales_branch_break := it_chosei_data(l_cnt).head_sales_branch;
--
      END IF ;
--
--=========================================================================
      -- -----------------------------------------------------
      -- 明細データ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- 【データ】品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).item_code ;
--
      -- 【データ】品目名
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).item_name ;
--
      -- リーフの場合出力
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- 【データ】計画数（着日）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_quantity ;
--
        -- 【データ】予実数（着日）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).confirm_quantity ;
--
        -- 【データ】差異数（着日）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_arrive';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_quantity
                                                     - it_chosei_data(l_cnt).confirm_quantity;
      END IF;
--
      -- 【データ】計画数（累計）
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_subtotal_quantity ;
--
      -- 【データ】予実数（累計）
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).confirm_subtotal_quantity ;
--
      -- 【データ】差異数（累計）
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_subtotal';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).plan_subtotal_quantity 
                                                  - it_chosei_data(l_cnt).confirm_subtotal_quantity;
--
      -- リーフの場合出力
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
      -- 【データ】計画数（月間）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_plan_quantity ;
--
        -- 【データ】予実数（月間）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_confirm_quantity ;
--
        -- 【データ】差異数（月間）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_monthly';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).monthly_plan_quantity
                                                   - it_chosei_data(l_cnt).monthly_confirm_quantity;
--
        -- 【データ】達成率（月間）
        IF (it_chosei_data(l_cnt).monthly_plan_quantity <> 0) THEN
--
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tassei_ritu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                   := TRUNC(it_chosei_data(l_cnt).monthly_confirm_quantity
                                           / it_chosei_data(l_cnt).monthly_plan_quantity * 100, 2);
        END IF;
--
        -- 【データ】計画数（全社）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'plan_zensha';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).zensha_plan_quantity ;
--
        -- 【データ】予実数（全社）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'confirm_zensha';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_chosei_data(l_cnt).zensha_confirm_quantity ;
      END IF;
--
      -- -----------------------------------------------------
      -- 明細データ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- 合計値算出
      -- -----------------------------------------------------
      -- リーフの場合のみ計算
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- 拠点計計画数（着日）サマリ用変数
        ln_plan_arrive_total
                    := ln_plan_arrive_total + it_chosei_data(l_cnt).plan_quantity;
        -- 拠点計予実数（着日）サマリ用変数
        ln_confirm_arrive_total
                    := ln_confirm_arrive_total + it_chosei_data(l_cnt).confirm_quantity;
      END IF;
      -- 拠点計計画数（累計）サマリ用変数
      ln_plan_subtotal_total
                    := ln_plan_subtotal_total + it_chosei_data(l_cnt).plan_subtotal_quantity;
      -- 拠点計予実数（累計）サマリ用変数
      ln_confirm_subtotal_total
                    := ln_confirm_subtotal_total + it_chosei_data(l_cnt).confirm_subtotal_quantity;
      -- リーフの場合出力
      IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
        -- 拠点計計画数（月間）サマリ用変数
        ln_plan_monthly_total
                    := ln_plan_monthly_total + it_chosei_data(l_cnt).monthly_plan_quantity;
        -- 拠点計予実数（月間）サマリ用変数
        ln_confirm_monthly_total
                    := ln_confirm_monthly_total + it_chosei_data(l_cnt).monthly_confirm_quantity;
      END IF;
--
    END LOOP chosei_data_loop;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_create_xml_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_chosei_data
   * Description      : 出荷調整表情報取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_chosei_data
    (
      id_arrival_date       IN  DATE
     ,ot_chosei_data        OUT NOCOPY type_chosei_data_tbl
     ,ov_errbuf             OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_chosei_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    SELECT xsatt.head_sales_branch            AS head_sales_branch          -- 拠点コード
          ,xcav.party_short_name              AS kyoten_name                -- 拠点名
          ,xsatt.item_code                    AS item_code                  -- 品目コード
          ,xsatt.item_name                    AS item_name                  -- 品目名
          ,xsatt.arrival_date                 AS arrival_date               -- 着日
          ,xsatt.plan_quantity                AS plan_quantity              -- 計画数（着日）
          ,xsatt.confirm_quantity             AS confirm_quantity           -- 予実数（着日）
          ,xsatt.plan_subtotal_quantity       AS plan_subtotal_quantity     -- 計画数（累計）
          ,xsatt.confirm_subtotal_quantity    AS confirm_subtotal_quantity  -- 予実数（累計）
          ,xsatt.monthly_plan_quantity        AS monthly_plan_quantity      -- 計画数（月間）
          ,xsatt.monthly_confirm_quantity     AS monthly_confirm_quantity   -- 予実数（月間）
          ,xsaat.plan_quantity                AS zensha_plan_quantity       -- 計画数（全社）
          ,xsaat.confirm_quantity             AS zensha_confirm_quantity    -- 予実数（全社）
--
    BULK COLLECT INTO ot_chosei_data
--
    FROM   xxwsh_ship_adjust_total_tmp   xsatt               -- 出荷調整表集計中間テーブル
          ,xxwsh_ship_adjust_all_tmp     xsaat               -- 出荷調整表全社中間テーブル
          ,xxcmn_cust_accounts2_v        xcav                -- 顧客情報VIEW2
--
    WHERE
    ------------------------------------------------------------------------
    -- 出荷調整表集計中間テーブル
        xsatt.arrival_date                        = id_arrival_date
    ------------------------------------------------------------------------
    -- 出荷調整表全社中間テーブル
    AND xsatt.item_code                           = xsaat.item_code(+)
    ------------------------------------------------------------------------
    -- 顧客情報VIEW2
    AND xsatt.head_sales_branch                    = xcav.party_number
    AND xcav.start_date_active                    <= id_arrival_date
    AND xcav.end_date_active                      >= id_arrival_date
    ------------------------------------------------------------------------
    ORDER BY xsatt.head_sales_branch
            ,xsatt.item_code
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_chosei_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_plan_confirm_marge_data
   * Description      : リーフ計画数・予実数マージ処理
   ***********************************************************************************/
  PROCEDURE prc_plan_confirm_marge_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_plan_confirm_marge_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
    -- =====================================================
    -- マージ処理
    -- =====================================================
    MERGE INTO xxwsh_ship_adjust_days_tmp         xsadt
    USING      xxwsh_shippng_adj_plan_act_tmp     xsaat
    ON  (    xsadt.head_sales_branch = xsaat.head_sales_branch
         AND xsadt.item_code         = xsaat.item_code
         AND xsadt.arrival_date      = xsaat.arrival_date)
--
    WHEN MATCHED THEN
    UPDATE SET xsadt.confirm_quantity = xsaat.confirm_quantity
    WHEN NOT MATCHED THEN
    INSERT (
        head_sales_branch
       ,item_code
       ,item_name
       ,arrival_date
       ,plan_quantity
       ,confirm_quantity
    ) VALUES (
        xsaat.head_sales_branch
       ,xsaat.item_code
       ,xsaat.item_name
       ,xsaat.arrival_date
       ,0
       ,xsaat.confirm_quantity
     );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_plan_confirm_marge_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_subtotal_data
   * Description      : ドリンク累計数算出処理
   ***********************************************************************************/
  PROCEDURE prc_get_drink_subtotal_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_drink_subtotal_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- 累計数・月間数算出データ
    lt_drink_total_mon_data           type_drink_total_mon_tbl;
    -- 取得データ数
    ln_cnt                            NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    SELECT xsadt.head_sales_branch         AS head_sales_branch                 -- 拠点コード
          ,xsadt.item_code                 AS item_code                         -- 品目コード
          ,xsadt.item_name                 AS item_name                         -- 品目名
          ,xsadt.arrival_date              AS arrival_date                      -- 着日
          ,xsadt.plan_quantity             AS plan_quantity                     -- 計画数（着日）
          ,xsadt.confirm_quantity          AS confirm_quantity                  -- 予実数（着日）
          ,xsadt.plan_quantity             AS plan_subtotal_quantity            -- 計画数（累計）
          ,SUM(xsadt.confirm_quantity)                                          -- 予実数（累計）
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
          ,0                               AS plan_monthly_quantity             -- 計画数（月間）
          ,0                               AS confirm_monthly_quantity          -- 予実数（月間）
--
    BULK COLLECT INTO lt_drink_total_mon_data
--
    FROM xxwsh_ship_adjust_days_tmp   xsadt                       -- 出荷調整表日別中間テーブル
    ;
--
    -- ====================================================
    -- データ登録
    -- ====================================================
    ln_cnt := lt_drink_total_mon_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_head_sales_branch(ln_move_cnt)                                    -- 拠点コード
        := lt_drink_total_mon_data(ln_move_cnt).head_sales_branch;
      gt_i_item_code(ln_move_cnt)                                            -- 品目コード
        := lt_drink_total_mon_data(ln_move_cnt).item_code;
      gt_i_item_name(ln_move_cnt)                                            -- 品目名
        := lt_drink_total_mon_data(ln_move_cnt).item_name;
      gt_i_arrival_date(ln_move_cnt)                                         -- 着日
        := lt_drink_total_mon_data(ln_move_cnt).arrival_date;
      gt_i_plan_quantity(ln_move_cnt)                                        -- 計画数（着日）
        := lt_drink_total_mon_data(ln_move_cnt).plan_quantity;
      gt_i_confirm_quantity(ln_move_cnt)                                     -- 予実数（着日）
        := lt_drink_total_mon_data(ln_move_cnt).confirm_quantity;
      gt_i_plan_subtotal_quantity(ln_move_cnt)                               -- 計画数（累計）
        := lt_drink_total_mon_data(ln_move_cnt).plan_subtotal_quantity;
      gt_i_confirm_subtotal_quantity(ln_move_cnt)                            -- 予実数（累計）
        := lt_drink_total_mon_data(ln_move_cnt).confirm_subtotal_quantity;
      gt_i_plan_monthly_quantity(ln_move_cnt)                                -- 計画数（月間）
        := lt_drink_total_mon_data(ln_move_cnt).plan_monthly_quantity;
      gt_i_confirm_monthly_quantity(ln_move_cnt)                             -- 予実数（月間）
        := lt_drink_total_mon_data(ln_move_cnt).confirm_monthly_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_total_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        plan_quantity,                             -- 計画数（着日）
        confirm_quantity,                          -- 予実数（着日）
        plan_subtotal_quantity,                    -- 計画数（累計）
        confirm_subtotal_quantity,                 -- 予実数（累計）
        monthly_plan_quantity,                     -- 計画数（月間）
        monthly_confirm_quantity                   -- 予実数（月間）
      )VALUES(
        gt_i_head_sales_branch(ln_move_cnt),
        gt_i_item_code(ln_move_cnt),
        gt_i_item_name(ln_move_cnt),
        gt_i_arrival_date(ln_move_cnt),
        gt_i_plan_quantity(ln_move_cnt),
        gt_i_confirm_quantity(ln_move_cnt),
        gt_i_plan_subtotal_quantity(ln_move_cnt),
        gt_i_confirm_subtotal_quantity(ln_move_cnt),
        gt_i_plan_monthly_quantity(ln_move_cnt),
        gt_i_confirm_monthly_quantity(ln_move_cnt)
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_drink_subtotal_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_confirm_data
   * Description      : ドリンク予実数取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_drink_confirm_data(
      iv_select_status         IN         VARCHAR2      -- プロファイル.抽出対象ステータス
     ,iv_kyoten_cd             IN         VARCHAR2      -- 拠点
     ,iv_shipped_locat         IN         VARCHAR2      -- 出庫元
     ,id_arrival_date          IN         DATE          -- 着日
     ,id_bucket_date_from      IN         DATE          -- バケット期間(FROM)
     ,id_bucket_date_to        IN         DATE          -- バケット期間(TO)
     ,on_confirm_cnt           OUT        NUMBER        -- 取得件数
     ,ov_errbuf                OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_confirm_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_select CONSTANT VARCHAR2(32000) := 
         '  SELECT xoha.head_sales_branch                    AS head_sales_branch                        ' -- 管轄拠点
      || '        ,xola.request_item_code                    AS item_code                                ' -- 出荷品目
      || '        ,MAX(ximv.item_short_name)                 AS item_name                                ' -- 略称
      || '        ,xoha.schedule_arrival_date                AS arrival_date                             ' -- 着荷予定日
      || '        ,SUM(CASE                                                                              '
                         -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
      || '               WHEN  (xoha.req_status = ''' || gv_req_status || ''') THEN                      '
      || '                 CASE WHEN (ximv.conv_unit IS NULL) THEN                                       '
      || '                   xola.shipped_quantity                                                       '
      || '                 ELSE                                                                          '
      || '                   TRUNC(xola.shipped_quantity / CASE                                          '
      || '                                                   WHEN ximv.num_of_cases IS NULL THEN ''1''   '
      || '                                                   WHEN ximv.num_of_cases = ''0''   THEN ''1'' '
      || '                                                   ELSE ximv.num_of_cases                      '
      || '                                                 END, 3)                                       '
      || '                 END                                                                           '
                         -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」以外の場合
      || '               ELSE                                                                            '
      || '                 CASE WHEN (ximv.conv_unit IS NULL) THEN                                       '
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
      --|| '                   xola.quantity                                                               '
      || '                   NVL(xola.quantity, 0)                                                       '
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
      || '                 ELSE                                                                          '
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
      --|| '                   TRUNC(xola.quantity / CASE                                                  '
      || '                   TRUNC(NVL(xola.quantity, 0) / CASE                                          '
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
      || '                                           WHEN ximv.num_of_cases IS NULL THEN ''1''           '
      || '                                           WHEN ximv.num_of_cases = ''0''   THEN ''1''         '
      || '                                           ELSE ximv.num_of_cases                              '
      || '                                         END, 3)                                               '
      || '                 END                                                                           '
      || '               END)                                 AS confirm_quantity                        ' -- 予実数
      ;
--
    cv_from CONSTANT VARCHAR2(32000) := 
         '  FROM   xxcmn_sourcing_rules      xsr    '           -- 物流構成アドオンマスタ
      || '        ,xxwsh_order_headers_all   xoha   '           -- 受注ヘッダアドオン
      || '        ,xxwsh_order_lines_all     xola   '           -- 受注明細アドオン
-- 2009/01/15 Y.Yamamoto #1021 add start
      || '        ,oe_transaction_types_all  otta   '           -- 受注タイプ
-- 2009/01/15 Y.Yamamoto #1021 add end
      || '        ,xxcmn_item_mst2_v         ximv   '           -- OPM品目情報VIEW2
      || '        ,xxcmn_item_categories5_v  xicv   '           -- OPM品目カテゴリ割当情報VIEW5
      || '        ,xxcmn_lookup_values2_v    xlvv1  '           -- クイックコード1
      || '        ,xxcmn_lookup_values2_v    xlvv2  '           -- クイックコード2
      ;
--
    cv_where CONSTANT VARCHAR2(32000) := 
          ' WHERE                                                                  '
            -- *** 結合条件 *** --
      || '         xoha.order_header_id        = xola.order_header_id              '  -- 結合条件 受注ヘッダアドオン AND 受注明細アドオン
-- 2009/01/15 Y.Yamamoto #1021 add start
      || '  AND    xoha.order_type_id          = otta.transaction_type_id          '  -- 結合条件 受注ヘッダアドオン AND 受注タイプ
      || '  AND    otta.attribute1             = ''1''                             '  -- 結合条件 受注タイプ AND 出荷依頼「1」
-- 2009/01/15 Y.Yamamoto #1021 add end
      || '  AND    xsr.base_code               = xoha.head_sales_branch            '  -- 結合条件 物流構成アドオンマスタ AND 受注ヘッダアドオン
      || '  AND    xsr.delivery_whse_code      = xoha.deliver_from                 '  -- 結合条件 物流構成アドオンマスタ AND 受注ヘッダアドオン
      || '  AND    xoha.req_status             = xlvv2.lookup_code                 '  -- 結合条件 受注ヘッダアドオン AND クイックコード2
      || '  AND    xlvv2.lookup_type           = xlvv1.meaning                     '  -- 結合条件 クイックコード2 AND クイックコード1
      || '  AND    xsr.item_code               = xola.request_item_code            '  -- 結合条件 物流構成アドオンマスタ AND 受注明細アドオン
      || '  AND    xola.request_item_code      = ximv.item_no                      '  -- 結合条件 受注明細アドオン AND OPM品目情報VIEW2
      || '  AND    ximv.item_id                = xicv.item_id                      '  -- 結合条件 OPM品目情報VIEW2 AND OPM品目カテゴリ割当情報VIEW5
            -- *** 抽出条件 *** --
      || '  AND    xsr.plan_item_flag          = ''' || gv_plan_syohin_flg || '''  '  -- 抽出条件 物流構成アドオンマスタ.計画商品フラグ：「1：計画商品対象」
      || '  AND    xlvv1.lookup_type           = ''' || gv_lookup_type1 || '''     '  -- 抽出条件 クイックコード1.タイプ：「出荷調整抽出対象ステータス種別」
      || '  AND    xlvv1.lookup_code           = :iv_select_status                 '  -- 抽出条件 クイックコード1.コード：プロファイルの抽出対象ステータス
      || '  AND    xsr.start_date_active      <= :id_arrival_date                  '  -- 抽出条件 物流構成アドオンマスタ.適用開始日「IN着日」
      || '  AND    xsr.end_date_active        >= :id_arrival_date                  '  -- 抽出条件 物流構成アドオンマスタ.適用終了日「IN着日」
      || '  AND    xoha.latest_external_flag   = ''Y''                             '  -- 抽出条件 受注ヘッダアドオン.最新フラグ「Y」
      || '  AND    xoha.schedule_arrival_date >= :id_bucket_date_from              '  -- 抽出条件 受注ヘッダアドオン.着荷予定日：「INバケット日付(FROM)」
      || '  AND    xoha.schedule_arrival_date <= :id_bucket_date_to                '  -- 抽出条件 受注ヘッダアドオン.着荷予定日：「INバケット日付(TO)」
      || '  AND    ximv.start_date_active     <= :id_arrival_date                  '  -- 抽出条件 OPM品目情報VIEW2.適用開始日：「IN着日」
      || '  AND    ximv.end_date_active       >= :id_arrival_date                  '  -- 抽出条件 OPM品目情報VIEW2.適用終了日：「IN着日」
      || '  AND    xicv.prod_class_code        = ''' || gv_syori_kbn_drink || '''  '  -- 抽出条件 OPM品目カテゴリ割当情報VIEW5.商品区分：「2：ドリンク」
-- 2008/12/09 v1.9 ADD START
      || '  AND    NVL(xola.delete_flag, :gv_n) = :gv_n                             '  -- 抽出条件 受注明細アドオン.削除フラグ：「N」
-- 2008/12/09 v1.9 ADD END
      ;
    cv_where_kyoten_cd    CONSTANT VARCHAR2(32000) := 
         '  AND    xsr.base_code               = ''' || iv_kyoten_cd || '''        '; -- 抽出条件 物流構成アドオンマスタ.拠点：「IN拠点」
    cv_where_deliver_from CONSTANT VARCHAR2(32000) := 
         '  AND    xsr.delivery_whse_code      = ''' || iv_shipped_locat || '''    '; -- 抽出条件 物流構成アドオンマスタ.出荷先：「IN出庫先」
    cv_group_by CONSTANT VARCHAR2(32000) := 
         '  GROUP BY xoha.head_sales_branch     '                   -- 受注ヘッダアドオン.管轄拠点
      || '          ,xola.request_item_code     '                   -- 受注ヘッダ明細.出荷品目
      || '          ,xoha.schedule_arrival_date '                   -- 受注ヘッダアドオン.着荷予定日
      ;
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 予実数データ
    lt_drink_confirm_data                  type_drink_confirm_data_tbl;
    -- 取得データ数
    ln_cnt                                 NUMBER DEFAULT 0;
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    lv_sql                       VARCHAR2(32767); -- 動的SQL用
    lv_where_kyoten_cd           VARCHAR2(32767); -- 抽出条件 拠点
    lv_where_deliver_from        VARCHAR2(32767); -- 抽出条件 出庫先
-- 2008/09/01 H.Itou Add End
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- カーソル宣言
    -- =====================================================
    TYPE ref_cursor        IS REF CURSOR ;
    cur_drink_confirm_data    ref_cursor ;  -- ドリンク予実数データ
-- 2008/09/01 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- SQL生成
    -- =====================================================
    -- INパラメータ.拠点に入力ありの場合、拠点を条件に追加
    IF (iv_kyoten_cd IS NOT NULL) THEN
      lv_where_kyoten_cd := cv_where_kyoten_cd;
    ELSE
      lv_where_kyoten_cd := ' ';
    END IF;
--
    -- INパラメータ.出庫元に入力ありの場合、出庫元を条件に追加
    IF (iv_shipped_locat IS NOT NULL) THEN
      lv_where_deliver_from := cv_where_deliver_from;
    ELSE
      lv_where_deliver_from := ' ';
    END IF;
--
    lv_sql := cv_select
           || cv_from
           || cv_where
           || lv_where_kyoten_cd
           || lv_where_deliver_from
           || cv_group_by;
--
-- 2008/09/01 H.Itou Add End
    -- ====================================================
    -- データ抽出
    -- ====================================================
-- 2008/09/01 H.Itou Mod Start PT 2-1_10対応
    -- カーソルオープン
    OPEN cur_drink_confirm_data FOR lv_sql
    USING
      iv_select_status      -- INパラメータ.抽出対象ステータス
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_bucket_date_from   -- INパラメータ.バケット日付(FROM)
     ,id_bucket_date_to     -- INパラメータ.バケット日付(TO)
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
-- 2008/12/09 ADD START
     ,gv_n                  -- INパラメータ.'N'
     ,gv_n                  -- INパラメータ.'N'
-- 2008/12/09 ADD END
    ;
    -- バルクフェッチ
    FETCH cur_drink_confirm_data BULK COLLECT INTO lt_drink_confirm_data;
    -- カーソルクローズ
    CLOSE cur_drink_confirm_data;
--
--    SELECT xoha.head_sales_branch                    AS head_sales_branch      -- 管轄拠点
--          ,xola.request_item_code                    AS item_code              -- 出荷品目
--          ,MAX(ximv.item_short_name)                 AS item_name              -- 略称
--          ,xoha.schedule_arrival_date                AS arrival_date           -- 着荷予定日
--          ,SUM(CASE
--                 -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
--                 WHEN  (xoha.req_status = gv_req_status) THEN
--                   CASE WHEN (ximv.conv_unit IS NULL) THEN
--                     xola.shipped_quantity
--                   ELSE
--                     TRUNC(xola.shipped_quantity / CASE
--                                                     WHEN ximv.num_of_cases IS NULL THEN '1'
--                                                     WHEN ximv.num_of_cases = '0'   THEN '1'
--                                                     ELSE ximv.num_of_cases
--                                                   END, 3)
--                   END
----
--                 ELSE
----
--                   -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」以外の場合
--                   CASE WHEN (ximv.conv_unit IS NULL) THEN
--                     xola.quantity
--                   ELSE
--                     TRUNC(xola.quantity / CASE
--                                             WHEN ximv.num_of_cases IS NULL THEN '1'
--                                             WHEN ximv.num_of_cases = '0'   THEN '1'
--                                             ELSE ximv.num_of_cases
--                                           END, 3)
--                   END
--                 END)                                 AS confirm_quantity     -- 予実数
----
--    BULK COLLECT INTO lt_drink_confirm_data
----
--    FROM  xxcmn_sourcing_rules      xsr               -- 物流構成アドオンマスタ
--         ,xxwsh_order_headers_all   xoha              -- 受注ヘッダアドオン
--         ,xxwsh_order_lines_all     xola              -- 受注明細アドオン
--         ,xxcmn_item_mst2_v         ximv              -- OPM品目情報VIEW
---- mod start ver1.6
----         ,xxcmn_item_categories4_v  xicv              -- OPM品目カテゴリ割当情報VIEW4
--         ,xxcmn_item_categories5_v  xicv              -- OPM品目カテゴリ割当情報VIEW5
---- mod end ver1.6
--         ,xxcmn_lookup_values2_v    xlvv1             -- クイックコード1
--         ,xxcmn_lookup_values2_v    xlvv2             -- クイックコード2
----
--    WHERE
--    ------------------------------------------------------------------------
--    -- クイックコード１
--        xlvv1.lookup_type                      = gv_lookup_type1
--    AND xlvv1.lookup_code                      = iv_select_status
--    ------------------------------------------------------------------------
--    -- クイックコード２
--    AND xlvv2.lookup_type                      = xlvv1.meaning
--    ------------------------------------------------------------------------
--    -- 物流構成アドオンマスタ
--    AND xsr.plan_item_flag                     = gv_plan_syohin_flg
--    AND xsr.base_code                          = NVL(iv_kyoten_cd, xsr.base_code)
--    AND xsr.delivery_whse_code                 = NVL(iv_shipped_locat, xsr.delivery_whse_code)
--    AND xsr.item_code                          = xola.request_item_code
--    AND xsr.base_code                          = xoha.head_sales_branch
--    AND xsr.delivery_whse_code                 = xoha.deliver_from
--    AND xsr.start_date_active                 <= id_arrival_date
--    AND xsr.end_date_active                   >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- 受注ヘッダアドオン
--    AND xoha.latest_external_flag              = 'Y'
--    AND xoha.schedule_arrival_date            >= id_bucket_date_from
--    AND xoha.schedule_arrival_date            <= id_bucket_date_to
--    AND xoha.req_status                        = xlvv2.lookup_code
--    ------------------------------------------------------------------------
--    -- 受注明細アドオン条件
--    AND xoha.order_header_id                   = xola.order_header_id
--    ------------------------------------------------------------------------
--    -- OPM品目情報view
--    AND xola.request_item_code                 = ximv.item_no
--    AND ximv.start_date_active                <= id_arrival_date
--    AND ximv.end_date_active                  >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- OPM品目カテゴリ割当情報VIEW4条件
--    AND ximv.item_id                           = xicv.item_id
--    AND xicv.prod_class_code                   = gv_syori_kbn_drink
--    ------------------------------------------------------------------------
--    GROUP BY xoha.head_sales_branch                        -- 受注ヘッダアドオン.管轄拠点
--            ,xola.request_item_code                        -- 受注ヘッダ明細.出荷品目
--            ,xoha.schedule_arrival_date                    -- 受注ヘッダアドオン.着荷予定日
--    ;
-- 2008/09/01 H.Itou Mod End
--
    -- ====================================================
    -- データ登録
    -- ====================================================
    ln_cnt := lt_drink_confirm_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_plan_head_sales_branch(ln_move_cnt)                           -- 拠点コード
        := lt_drink_confirm_data(ln_move_cnt).head_sales_branch;
      gt_plan_item_code(ln_move_cnt)                                   -- 品目コード
        := lt_drink_confirm_data(ln_move_cnt).item_code;
      gt_plan_item_name(ln_move_cnt)                                   -- 品目名
        := lt_drink_confirm_data(ln_move_cnt).item_name;
      gt_plan_arrival_date(ln_move_cnt)                                -- 着日
        := lt_drink_confirm_data(ln_move_cnt).arrival_date;
      gt_plan_confirm_quantity(ln_move_cnt)                            -- 予実数（着日）
        := lt_drink_confirm_data(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_plan_act_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        confirm_quantity                           -- 予実数（着日）
      )VALUES(
        gt_plan_head_sales_branch(ln_move_cnt),
        gt_plan_item_code(ln_move_cnt),
        gt_plan_item_name(ln_move_cnt),
        gt_plan_arrival_date(ln_move_cnt),
        gt_plan_confirm_quantity(ln_move_cnt)
      );
--
    on_confirm_cnt := ln_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_drink_confirm_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_plan_data
   * Description      : ドリンク計画数取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_drink_plan_data(
      iv_kyoten_cd             IN         VARCHAR2      -- 拠点
     ,iv_shipped_locat         IN         VARCHAR2      -- 出庫元
     ,id_arrival_date          IN         DATE          -- 着日
     ,id_bucket_from           IN         DATE          -- バケット日付(FROM)
     ,id_bucket_to             IN         DATE          -- バケット日付(TO)
     ,on_plan_cnt              OUT        NUMBER        -- 取得件数
     ,ov_errbuf                OUT NOCOPY VARCHAR2      -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2      -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_plan_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_main_select CONSTANT VARCHAR2(32000) := 
         '  SELECT xsr.base_code             AS base_code       ' -- 拠点
      || '        ,xsr.item_code             AS item_code       ' -- 品目コード
      || '        ,ximv.item_short_name      AS item_short_name ' -- 品目名
      || '        ,xsabt.bucket_date         AS bucket_date     ' -- 日付
      || '        ,NVL(sub.plan_quantity, 0) AS plan_quantity   ' -- 予定数
      ;
--
    cv_main_from CONSTANT VARCHAR2(32000) := 
         '  FROM   xxcmn_sourcing_rules             xsr   '                   -- 物流構成アドオンマスタ
      || '        ,xxwsh_shippng_adj_bucket_tmp     xsabt '                   -- 出荷調整表バケット中間テーブル
      || '        ,xxcmn_item_mst2_v                ximv  '                   -- OPM品目情報VIEW2
      || '        ,xxcmn_item_categories5_v         xicv  '                   -- OPM品目カテゴリ割当情報VIEW5
      || '        ,(                                      '                   -- フォーキャスト副問合せ
      ;
--
    cv_sub_select CONSTANT VARCHAR2(32000) := 
         '         SELECT mfde.attribute3          AS head_sales_branch                  '   -- フォーキャスト名.拠点
      || '               ,MAX(ximv.item_no)        AS item_code                          '   -- OPM品目情報VIEW.品目コード
      || '               ,SUM(CASE                                                       '
                                 -- OPM品目マスタ.入出庫換算単位が未設定の場合
      || '                       WHEN (ximv.conv_unit IS NULL) THEN                      '
      || '                         mfda.original_forecast_quantity                       '
      || '                       ELSE                                                    '
      || '                         TRUNC(mfda.original_forecast_quantity                 '
      || '                               / CASE                                          '
      || '                                   WHEN ximv.num_of_cases IS NULL THEN ''1''   '
      || '                                   WHEN ximv.num_of_cases = ''0''   THEN ''1'' '
      || '                                   ELSE ximv.num_of_cases                      '
      || '                                 END, 3)                                       '
      || '                       END)               AS plan_quantity                     '   -- 予定数
      ;
--
    cv_sub_from CONSTANT VARCHAR2(32000) := 
         '         FROM   mrp_forecast_designators  mfde '                                    -- フォーキャスト名
      || '               ,mrp_forecast_dates        mfda '                                    -- フォーキャスト日付
      || '               ,xxcmn_item_mst2_v         ximv '                                    -- OPM品目情報VIEW2
      || '               ,xxcmn_item_categories5_v  xicv '                                    -- OPM品目カテゴリ割当情報VIEW5
      ;
--
    cv_sub_where CONSTANT VARCHAR2(32000) := 
         '         WHERE                                                                    '
                   -- *** 結合条件 *** --
      || '                mfde.forecast_designator = mfda.forecast_designator               ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
      || '         AND    mfde.organization_id     = mfda.organization_id                   ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
      || '         AND    mfda.inventory_item_id   = ximv.inventory_item_id                 ' -- 結合条件 フォーキャスト日付 AND OPM品目情報VIEW2
      || '         AND    ximv.item_id             =  xicv.item_id                          ' -- 結合条件 OPM品目情報VIEW2 AND OPM品目カテゴリ情報VIEW5
                   -- *** 抽出条件 *** --
      || '         AND    mfde.attribute1          = ''' || gv_forecast_kbn_ksyohin || '''  ' -- 抽出条件 フォーキャスト名.フォーキャスト分類：「09：画商品引取計画」
      || '         AND    mfda.forecast_date      >= :id_bucket_from                        ' -- 抽出条件 フォーキャスト日付.開始日：INバケット日付(FROM)
      || '         AND    mfda.forecast_date      <= :id_bucket_to                          ' -- 抽出条件 フォーキャスト日付.開始日：INバケット日付(TO)
      || '         AND    ximv.start_date_active  <= :id_arrival_date                       ' -- 抽出条件 OPM品目情報VIEW2.適用開始日：IN着日
      || '         AND    ximv.end_date_active    >= :id_arrival_date                       ' -- 抽出条件 OPM品目情報VIEW2.適用終了日：IN着日
      || '         AND    xicv.prod_class_code     = ''' || gv_syori_kbn_drink || '''       ' -- 抽出条件 OPM品目カテゴリ情報VIEW5.商品区分：「2：ドリンク」
      ;
    cv_sub_where_kyoten_cd    CONSTANT VARCHAR2(32000) := 
         '         AND    mfde.attribute3          = ''' || iv_kyoten_cd || '''             '; -- 抽出条件 フォーキャスト名.拠点：IN拠点
    cv_sub_where_deliver_from CONSTANT VARCHAR2(32000) := 
         '         AND    mfde.attribute2          = ''' || iv_shipped_locat || '''         '; -- 抽出条件 フォーキャスト名.IN出荷元
    cv_sub_group_by CONSTANT VARCHAR2(32000) := 
         '         GROUP BY mfde.attribute3         ' -- フォーキャスト名.拠点
      || '                 ,mfda.inventory_item_id  ' -- フォーキャスト日付.品目ID
      ;
    cv_sub_sql_name CONSTANT VARCHAR2(32000) := 
                 ') sub';
--
    cv_main_where CONSTANT VARCHAR2(32000) := 
         '  WHERE                                                              '
            -- *** 結合条件 *** --
      || '         xsr.item_code           = ximv.item_no                      ' -- 結合条件 物流構成アドオンマスタ AND OPM品目情報VIEW2
      || '  AND    ximv.item_id            =  xicv.item_id                     ' -- 結合条件 OPM品目情報VIEW2 AND OPM品目カテゴリ割当情報VIEW5
      || '  AND    xsr.base_code           = sub.head_sales_branch(+)          ' -- 結合条件 物流構成アドオンマスタ AND フォーキャスト副問合せ
      || '  AND    xsr.item_code           = sub.item_code(+)                  ' -- 結合条件 物流構成アドオンマスタ AND フォーキャスト副問合せ
            -- *** 抽出条件 *** --
      || '  AND    xsr.plan_item_flag      = ''' || gv_plan_syohin_flg || '''  ' -- 抽出条件 物流構成アドオンマスタ.計画商品フラグ：「1：計画商品対象」
      || '  AND    xsr.start_date_active  <= :id_arrival_date                  ' -- 抽出条件 物流構成アドオンマスタ.適用開始日：IN着日
      || '  AND    xsr.end_date_active    >= :id_arrival_date                  ' -- 抽出条件 物流構成アドオンマスタ.適用終了日：IN着日
      || '  AND    ximv.start_date_active <= :id_arrival_date                  ' -- 抽出条件 OPM品目情報VIEW2.適用開始日：IN着日
      || '  AND    ximv.end_date_active   >= :id_arrival_date                  ' -- 抽出条件 OPM品目情報VIEW2.適用終了日：IN着日
      || '  AND    xicv.prod_class_code    = ''' || gv_syori_kbn_drink || '''  ' -- 抽出条件 OPM品目カテゴリ割当情報VIEW5.商品区分：「2：ドリンク」
      ;
    cv_main_where_kyoten_cd    CONSTANT VARCHAR2(32000) := 
         '  AND    xsr.base_code           = ''' || iv_kyoten_cd || '''       '; -- 抽出条件 物流構成アドオンマスタ.拠点：「IN拠点」
    cv_main_where_deliver_from CONSTANT VARCHAR2(32000) := 
         '  AND    xsr.delivery_whse_code  = ''' || iv_shipped_locat || '''   '; -- 抽出条件 物流構成アドオンマスタ.拠点：「IN出庫先」
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- インデックス
    ln_cnt                        NUMBER DEFAULT 1;
    -- ドリンク計画数データ
    lt_drink_plan_data            type_drink_plan_data_tbl;
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    lv_sql                        VARCHAR2(32767); -- 動的SQL用
    lv_sub_where_kyoten_cd        VARCHAR2(32767); -- WHERE句 フォーキャスト副問合せの拠点
    lv_sub_where_deliver_from     VARCHAR2(32767); -- WHERE句 フォーキャスト副問合せの出庫先
    lv_main_where_kyoten_cd       VARCHAR2(32767); -- WHERE句 メインSQLの拠点
    lv_main_where_deliver_from    VARCHAR2(32767); -- WHERE句 メインSQLの出庫先
-- 2008/09/01 H.Itou Add End
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- カーソル宣言
    -- =====================================================
    TYPE ref_cursor        IS REF CURSOR ;
    cur_drink_plan_data    ref_cursor ;  -- ドリンク計画数データ
-- 2008/09/01 H.Itou Add End
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- SQL生成
    -- =====================================================
    -- INパラメータ.拠点に入力ありの場合、拠点を条件に追加
    IF (iv_kyoten_cd IS NOT NULL) THEN
      lv_sub_where_kyoten_cd  := cv_sub_where_kyoten_cd;  -- SUBSQLの拠点条件
      lv_main_where_kyoten_cd := cv_main_where_kyoten_cd; -- MAINSQLの拠点条件
    ELSE
      lv_sub_where_kyoten_cd  := ' ';
      lv_main_where_kyoten_cd := ' ';
    END IF;
--
    -- INパラメータ.出庫元に入力ありの場合、出庫元を条件に追加
    IF (iv_shipped_locat IS NOT NULL) THEN
      lv_sub_where_deliver_from  := cv_sub_where_deliver_from;  -- SUBSQLの出庫元条件
      lv_main_where_deliver_from := cv_main_where_deliver_from; -- MAINSQLの出庫元条件
    ELSE
      lv_sub_where_deliver_from  := ' ';
      lv_main_where_deliver_from := ' ';
    END IF;
--
    lv_sql := cv_main_select
           || cv_main_from
           || cv_sub_select
           || cv_sub_from
           || cv_sub_where
           || lv_sub_where_kyoten_cd
           || lv_sub_where_deliver_from
           || cv_sub_group_by
           || cv_sub_sql_name
           || cv_main_where
           || lv_main_where_kyoten_cd
           || lv_main_where_deliver_from;
--
-- 2008/09/01 H.Itou Add End
    -- ====================================================
    -- データ抽出
    -- ====================================================
-- 2008/09/01 H.Itou Mod Start PT 2-1_10対応
    -- カーソルオープン
    OPEN cur_drink_plan_data FOR lv_sql
    USING
      id_bucket_from        -- INパラメータ.バケット日付(FROM)
     ,id_bucket_to          -- INパラメータ.バケット日付(TO)
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
    ;
    -- バルクフェッチ
    FETCH cur_drink_plan_data BULK COLLECT INTO lt_drink_plan_data;
    -- カーソルクローズ
    CLOSE cur_drink_plan_data;
--
--    SELECT  xsr.base_code
--           ,xsr.item_code
--           ,ximv.item_short_name
--           ,xsabt.bucket_date
--           ,NVL(sub.plan_quantity, 0)
----
--    BULK COLLECT INTO lt_drink_plan_data
----
--    FROM xxcmn_sourcing_rules             xsr                      -- 物流構成アドオンマスタ
--        ,xxwsh_shippng_adj_bucket_tmp     xsabt                    -- 出荷調整表バケット中間テーブル
--        ,xxcmn_item_mst2_v                ximv                     -- OPM品目情報VIEW
---- mod start ver1.6
----        ,xxcmn_item_categories4_v         xicv                     -- OPM品目カテゴリ割当情報VIEW4
--        ,xxcmn_item_categories5_v         xicv                     -- OPM品目カテゴリ割当情報VIEW5
---- mod end ver1.6
--        ,(SELECT mfde.attribute3          AS head_sales_branch     -- フォーキャスト名.拠点
--                ,MAX(ximv.item_no)        AS item_code             -- OPM品目情報VIEW.品目コード
--                ,SUM(CASE
--                       -- OPM品目マスタ.入出庫換算単位が未設定の場合
--                       WHEN (ximv.conv_unit IS NULL) THEN
--                         mfda.original_forecast_quantity
--                       ELSE
--                         TRUNC(mfda.original_forecast_quantity / 
--                                                           CASE
--                                                             WHEN ximv.num_of_cases IS NULL THEN '1'
--                                                             WHEN ximv.num_of_cases = '0'   THEN '1'
--                                                             ELSE ximv.num_of_cases
--                                                           END, 3)
--                       END)               AS plan_quantity
----
--          FROM  mrp_forecast_designators  mfde                     -- フォーキャスト名
--               ,mrp_forecast_dates        mfda                     -- フォーキャスト日付
--               ,xxcmn_item_mst2_v         ximv                     -- OPM品目情報VIEW
---- mod start ver1.6
----               ,xxcmn_item_categories4_v  xicv                     -- OPM品目カテゴリ割当情報VIEW4
--               ,xxcmn_item_categories5_v  xicv                     -- OPM品目カテゴリ割当情報VIEW5
---- mod end ver1.6
----
--          WHERE
--          ------------------------------------------------------------------------
--          -- フォーキャスト名
--              mfde.attribute1          = gv_forecast_kbn_ksyohin
--          AND mfde.attribute3          = NVL(iv_kyoten_cd, mfde.attribute3)
--          AND mfde.attribute2          = NVL(iv_shipped_locat, mfde.attribute2)
--          ------------------------------------------------------------------------
--          -- フォーキャスト日付
--          AND mfde.forecast_designator = mfda.forecast_designator
--          AND mfde.organization_id     = mfda.organization_id
--          AND mfda.forecast_date       >= id_bucket_from
--          AND mfda.forecast_date       <= id_bucket_to
--          ------------------------------------------------------------------------
--          -- OPM品目情報VIEW条件
--          AND mfda.inventory_item_id   = ximv.inventory_item_id
--          AND ximv.start_date_active   <= id_arrival_date
--          AND ximv.end_date_active     >= id_arrival_date
--          ------------------------------------------------------------------------
--          -- OPM品目カテゴリ割当情報VIEW4
--          AND ximv.item_id             =  xicv.item_id
--          AND xicv.prod_class_code     = gv_syori_kbn_drink
--          ------------------------------------------------------------------------
--          GROUP BY mfde.attribute3                                  -- フォーキャスト名.拠点
--                  ,mfda.inventory_item_id                           -- フォーキャスト日付.品目ID
--          ) sub
----
--    WHERE
--    ------------------------------------------------------------------------
--    -- 物流構成アドオンマスタ
--        xsr.plan_item_flag        = gv_plan_syohin_flg
--    AND xsr.base_code             = NVL(iv_kyoten_cd, xsr.base_code)
--    AND xsr.delivery_whse_code    = NVL(iv_shipped_locat, xsr.delivery_whse_code)
--    AND xsr.start_date_active     <= id_arrival_date
--    AND xsr.end_date_active       >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- OPM品目情報VIEW条件
--    AND xsr.item_code             = ximv.item_no
--    AND ximv.start_date_active   <= id_arrival_date
--    AND ximv.end_date_active     >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- OPM品目カテゴリ割当情報VIEW4
--    AND ximv.item_id             =  xicv.item_id
--    AND xicv.prod_class_code     = gv_syori_kbn_drink
--    ------------------------------------------------------------------------
--    -- 結果セット②
--    AND xsr.base_code             = sub.head_sales_branch(+)
--    AND xsr.item_code             = sub.item_code(+)
--    ;
-- 2008/09/01 H.Itou Add End
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    ln_cnt := lt_drink_plan_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_day_head_sales_branch(ln_move_cnt)                         -- 拠点コード
        := lt_drink_plan_data(ln_move_cnt).head_sales_branch;
      gt_day_item_code(ln_move_cnt)                                 -- 品目コード
        := lt_drink_plan_data(ln_move_cnt).item_code;
      gt_day_item_name(ln_move_cnt)                                 -- 品目名
        := lt_drink_plan_data(ln_move_cnt).item_name;
      gt_day_arrival_date(ln_move_cnt)                              -- 着日
        := lt_drink_plan_data(ln_move_cnt).arrival_date;
      gt_day_plan_quantity(ln_move_cnt)                             -- 計画数（着日）
        := lt_drink_plan_data(ln_move_cnt).plan_quantity;
      gt_day_confirm_quantity(ln_move_cnt)                          -- 予実数（着日）
        := 0;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_days_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        plan_quantity,                             -- 計画数（着日）
        confirm_quantity                           -- 予実数（着日）
      )VALUES(
        gt_day_head_sales_branch(ln_move_cnt),
        gt_day_item_code(ln_move_cnt),
        gt_day_item_name(ln_move_cnt),
        gt_day_arrival_date(ln_move_cnt),
        gt_day_plan_quantity(ln_move_cnt),
        gt_day_confirm_quantity(ln_move_cnt)
      );
--
    on_plan_cnt := ln_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_drink_plan_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_bucket_data
   * Description      : バケット日付取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_bucket_data(
      iv_kyoten_cd             IN  VARCHAR2            -- 拠点
     ,iv_shipped_locat         IN  VARCHAR2            -- 出庫元
     ,id_arrival_date          IN  DATE                -- 着日
     ,od_bucket_from           OUT DATE                -- バケット日付(FROM)
     ,od_bucket_to             OUT DATE                -- バケット日付(TO)
     ,ov_errbuf                OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_bucket_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_select CONSTANT VARCHAR2(32000) := 
         '  SELECT MIN(mfda.forecast_date)    AS start_date    ' -- フォーキャスト日付.開始日
      || '        ,MAX(mfda.rate_end_date)    AS end_date      ' -- フォーキャスト日付.終了日
      ;
--
    cv_from CONSTANT VARCHAR2(32000) := 
         '  FROM   mrp_forecast_designators    mfde  '           -- フォーキャスト名
      || '        ,mrp_forecast_dates          mfda  '           -- フォーキャスト日付
      ;
--
    cv_where CONSTANT VARCHAR2(32000) := 
         '  WHERE                                                                  '
            -- *** 結合条件 *** --
      || '         mfde.forecast_designator = mfda.forecast_designator              ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
      || '  AND    mfde.organization_id     = mfda.organization_id                  ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
            -- *** 抽出条件 *** --
      || '  AND    mfde.attribute1          = ''' || gv_forecast_kbn_ksyohin || ''' ' -- 抽出条件 フォーキャスト名.フォーキャスト分類：「09：計画商品引取計画」
      || '  AND    mfda.forecast_date      <= :id_arrival_date                      ' -- 抽出条件 フォーキャスト日付.開始日：IN着日
      || '  AND    mfda.rate_end_date      >= :id_arrival_date                      ' -- 抽出条件 フォーキャスト日付.終了日：IN着日
      ;
    cv_where_kyoten_cd    CONSTANT VARCHAR2(32000) := 
         '  AND    mfde.attribute3          = ''' || iv_kyoten_cd || '''           '; -- 抽出条件 フォーキャスト名.拠点：「IN拠点」
    cv_where_deliver_from CONSTANT VARCHAR2(32000) := 
         '  AND    mfde.attribute2          = ''' || iv_shipped_locat || '''       '; -- 抽出条件 フォーキャスト名.出荷先：「IN出庫先」
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- インデックス
    ln_cnt                  NUMBER DEFAULT 1;
    -- ワークバケット日付(FROM)
    ld_from                 DATE DEFAULT NULL;
    -- ワークバケット日付(TO)
    ld_to                   DATE DEFAULT NULL;
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    lv_sql                  VARCHAR2(32767); -- 動的SQL用
    lv_where_kyoten_cd      VARCHAR2(32767); -- 抽出条件 拠点
    lv_where_deliver_from   VARCHAR2(32767); -- 抽出条件 出庫先
-- 2008/09/01 H.Itou Add End
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- カーソル宣言
    -- =====================================================
    TYPE ref_cursor        IS REF CURSOR ;
    cur_bucket_data        ref_cursor ;  -- バケット日付カーソル
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- 例外宣言
    -- =====================================================
    -- ローカル・例外
    no_data_expt            EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- SQL生成
    -- =====================================================
    -- INパラメータ.拠点に入力ありの場合、拠点を条件に追加
    IF (iv_kyoten_cd IS NOT NULL) THEN
      lv_where_kyoten_cd := cv_where_kyoten_cd;
    ELSE
      lv_where_kyoten_cd := ' ';
    END IF;
--
    -- INパラメータ.出庫元に入力ありの場合、出庫元を条件に追加
    IF (iv_shipped_locat IS NOT NULL) THEN
      lv_where_deliver_from := cv_where_deliver_from;
    ELSE
      lv_where_deliver_from := ' ';
    END IF;
--
    lv_sql := cv_select
           || cv_from
           || cv_where
           || lv_where_kyoten_cd
           || lv_where_deliver_from;
--
-- 2008/09/01 H.Itou Add End
    -- ====================================================
    -- データ抽出
    -- ====================================================
-- 2008/09/01 H.Itou Mod Start PT 2-1_10対応
    -- カーソルオープン
    OPEN cur_bucket_data FOR lv_sql
    USING
      id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
    ;
    -- フェッチ
    FETCH cur_bucket_data INTO ld_from, ld_to;
    -- カーソルクローズ
    CLOSE cur_bucket_data;
--
--    SELECT MIN(mfda.forecast_date)    AS start_date      -- フォーキャスト日付.開始日
--          ,MAX(mfda.rate_end_date)    AS end_date        -- フォーキャスト日付.終了日
----
--    INTO ld_from, ld_to
----
--    FROM  mrp_forecast_designators    mfde                      -- フォーキャスト名
--         ,mrp_forecast_dates          mfda                      -- フォーキャスト日付
----
--    WHERE
--    ------------------------------------------------------------------------
--    -- フォーキャスト名
--        mfde.attribute1               = gv_forecast_kbn_ksyohin
--    AND mfde.attribute3               = NVL(iv_kyoten_cd, mfde.attribute3)
--    AND mfde.attribute2               = NVL(iv_shipped_locat, mfde.attribute2)
--    ------------------------------------------------------------------------
--    -- フォーキャスト日付
--    AND mfde.forecast_designator      = mfda.forecast_designator
--    AND mfde.organization_id          = mfda.organization_id
--    AND mfda.forecast_date            <= id_arrival_date
--    AND mfda.rate_end_date            >= id_arrival_date
--    ;
--
-- 2008/09/01 H.Itou Mod End
    IF (ld_from IS NULL OR ld_to IS NULL) THEN
      RAISE no_data_expt ;
    END IF;
--
    -- ====================================================
    -- 登録処理
    -- ====================================================
    -- FORALLで使用できるようにレコード変数を分割格納する
    -- バケット日付(FROM)格納
    od_bucket_from := ld_from;
    od_bucket_to := ld_to;
--
    LOOP
      gt_i_bucket_data(ln_cnt) := ld_from;
--
      EXIT WHEN (ld_from = od_bucket_to);
--
      ld_from := ld_from + 1;
      ln_cnt  := ln_cnt + 1;
--
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_bucket_tmp(
        bucket_date                                             -- バケット日付
      )VALUES(
        gt_i_bucket_data(ln_move_cnt)
      );
--
  EXCEPTION
--
    WHEN no_data_expt THEN
      ov_retcode := gv_status_error ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_wsh
                                             ,gv_msg_xxwsh11403  ) ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_bucket_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_drink_info
   * Description      : ドリンク情報取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_drink_info(
      iv_syori_kbn             IN         VARCHAR2
     ,iv_kyoten_cd             IN         VARCHAR2
     ,iv_shipped_locat         IN         VARCHAR2
     ,id_arrival_date          IN         DATE
     ,iv_select_status         IN         VARCHAR2
     ,ov_errbuf                OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_drink_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- バケット日付（FROM)
    ld_bucket_from           DATE DEFAULT NULL;
    -- バケット日付（TO)
    ld_bucket_to             DATE DEFAULT NULL;
    -- 出荷調整表データ
    lt_chosei_data           type_chosei_data_tbl;
    -- 計画数取得件数
    ln_plan_cnt              NUMBER DEFAULT 0;
    -- 予実数取得件数
    ln_confirm_cnt           NUMBER DEFAULT 0;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- バケット日付取得処理
    -- ====================================================
    prc_get_bucket_data(
        iv_kyoten_cd         =>     iv_kyoten_cd      -- 拠点
       ,iv_shipped_locat     =>     iv_shipped_locat  -- 出庫元
       ,id_arrival_date      =>     id_arrival_date   -- 着日
       ,od_bucket_from       =>     ld_bucket_from    -- バケット日付(FROM)
       ,od_bucket_to         =>     ld_bucket_to      -- バケット日付(TO)
       ,ov_errbuf            =>     lv_errbuf         -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode        -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg         -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ドリンク計画数取得処理
    -- ====================================================
    prc_get_drink_plan_data(
        iv_kyoten_cd         =>     iv_kyoten_cd         -- 拠点
       ,iv_shipped_locat     =>     iv_shipped_locat     -- 出庫元
       ,id_arrival_date      =>     id_arrival_date      -- 着日
       ,id_bucket_from       =>     ld_bucket_from       -- バケット日付(FROM)
       ,id_bucket_to         =>     ld_bucket_to         -- バケット日付(TO)
       ,on_plan_cnt          =>     ln_plan_cnt          -- 取得件数
       ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ドリンク予実数取得処理
    -- ====================================================
    prc_get_drink_confirm_data(
        iv_select_status     =>     iv_select_status     -- 抽出対象ステータス
       ,iv_kyoten_cd         =>     iv_kyoten_cd         -- 拠点
       ,iv_shipped_locat     =>     iv_shipped_locat     -- 出庫元
       ,id_arrival_date      =>     id_arrival_date      -- 着日
       ,id_bucket_date_from  =>     ld_bucket_from       -- バケット期間(FROM)
       ,id_bucket_date_to    =>     ld_bucket_to         -- バケット期間(TO)
       ,on_confirm_cnt       =>     ln_confirm_cnt       -- 取得件数
       ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (ln_plan_cnt <> 0 OR ln_confirm_cnt <> 0) THEN
      -- ====================================================
      -- ドリンク計画数・予実数マージ処理
      -- ====================================================
      prc_plan_confirm_marge_data(
          ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode           -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- ドリンク累計数算出処理
      -- ====================================================
      prc_get_drink_subtotal_data(
          ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode           -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- 出荷調整表情報取得処理
      -- ====================================================
      prc_get_chosei_data(
          id_arrival_date      =>     id_arrival_date      -- 着日
         ,ot_chosei_data       =>     lt_chosei_data       -- 取得レコード表（ドリンク情報）
         ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode           -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    IF (lt_chosei_data.COUNT <> 0) THEN
--
      -- ====================================================
      -- ＸＭＬデータ作成処理
      -- ====================================================
      prc_create_xml_data(
          iv_syori_kbn         =>     iv_syori_kbn       -- 処理区分
         ,it_chosei_data       =>     lt_chosei_data     -- 出荷調整表データ
         ,ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    ELSE
--
      -- ====================================================
      -- ＸＭＬデータ作成処理（０件）
      -- ====================================================
      prc_create_zeroken_xml_data(
          ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- ＸＭＬ出力処理
    -- ====================================================
    prc_out_xml_data(
        ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- データなし時、ワーニングセット
    -- ====================================================
    IF (lt_chosei_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
    END IF;
--
  EXCEPTION
      -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_drink_info;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_zensha_data
   * Description      : リーフ全社数取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_zensha_data
    (
      iv_select_status  IN         VARCHAR2          -- 抽出対象ステータス
     ,iv_kyoten_cd      IN         VARCHAR2          -- 拠点
     ,iv_shipped_locat  IN         VARCHAR2          -- 出庫元
     ,id_arrival_date   IN         DATE              -- 着日
     ,ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_leaf_zensha_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 全社数データ
    lt_leaf_zensha_data                     type_leaf_zensha_data_tbl;
    -- 取得レコード数
    ln_cnt                                  NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    SELECT 
          -- 2008/07/23 ST不具合対応#475 start
          -- sub3.request_item_code                 AS item_code           -- 品目コード
          --,sub2.plan_quantity                     AS plan_quantity       -- 計画数
          --,sub3.confirm_quantity                  AS confirm_quantity    -- 予実数
           ximv.item_no                           AS item_code           -- 品目コード
          ,NVL(sub2.plan_quantity,0)              AS plan_quantity       -- 計画数
          ,NVL(sub3.confirm_quantity,0)           AS confirm_quantity    -- 予実数
          -- 2008/07/23 ST不具合対応#475 End
--
    BULK COLLECT INTO lt_leaf_zensha_data
--
    FROM  ------------------------------------------------------------------------
          -- 出荷調整表集計中間テーブル
          ------------------------------------------------------------------------
          (SELECT DISTINCT(xsatt.item_code)  AS item_code
           FROM   xxwsh_ship_adjust_total_tmp   xsatt            -- 出荷調整表集計中間テーブル
          )                                     sub1
          ------------------------------------------------------------------------
          ------------------------------------------------------------------------
          -- フォーキャスト情報
          ------------------------------------------------------------------------
         ,(SELECT  mfda.inventory_item_id    AS inventory_item_id
                  ,SUM(CASE
                         -- OPM品目マスタ.入出庫換算単位が未設定の場合
                         WHEN (ximv.conv_unit IS NULL) THEN
                           mfda.original_forecast_quantity
                         ELSE
                           TRUNC(mfda.original_forecast_quantity /
                                                     CASE
                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
                                                       ELSE ximv.num_of_cases
                                                     END, 3)
                         END
                      )                                   AS plan_quantity    -- フォーキャスト日付.数量
           FROM   mrp_forecast_designators              mfde
                 ,mrp_forecast_dates                    mfda
                 ,xxcmn_item_mst2_v                     ximv             -- OPM品目情報VIEW
           WHERE
           ------------------------------------------------------------------------
           -- フォーキャスト名
               mfde.attribute1                     = gv_forecast_kbn_hkeikaku
           ------------------------------------------------------------------------
           -- フォーキャスト日付
           AND mfde.forecast_designator            = mfda.forecast_designator
           AND mfde.organization_id                = mfda.organization_id
-- mod start ver1.6
--           AND mfda.forecast_date                  = id_arrival_date
           AND mfda.forecast_date                  >=  TRUNC(id_arrival_date, 'MONTH')
           AND mfda.forecast_date                  <=  id_arrival_date
-- mod end ver1.6
           ------------------------------------------------------------------------
           -- OPM品目情報VIEW
           AND mfda.inventory_item_id              = ximv.inventory_item_id
           AND ximv.start_date_active             <= id_arrival_date
           AND ximv.end_date_active               >= id_arrival_date
           ------------------------------------------------------------------------
           GROUP BY mfda.inventory_item_id
          )                                       sub2
          ------------------------------------------------------------------------
          ------------------------------------------------------------------------
          -- 受注データ情報
          ------------------------------------------------------------------------
         ,(SELECT  xola.request_item_code      AS request_item_code
                  ,SUM(CASE
                         -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
                         WHEN  (xoha.req_status = gv_req_status) THEN
                           CASE
                             WHEN (ximv.conv_unit IS NULL) THEN
                               xola.shipped_quantity
                             ELSE
                               TRUNC(xola.shipped_quantity / CASE
                                                               WHEN ximv.num_of_cases IS NULL THEN '1'
                                                               WHEN ximv.num_of_cases = '0'   THEN '1'
                                                               ELSE ximv.num_of_cases
                                                             END, 3)
                             END
                         ELSE
                           -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」以外の場合
                           CASE
                             WHEN (ximv.conv_unit IS NULL) THEN
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
                               --xola.quantity
                               NVL(xola.quantity, 0)
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
                             ELSE
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
                               --TRUNC(xola.quantity / CASE
                               TRUNC(NVL(xola.quantity, 0) / CASE
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
                                                       ELSE ximv.num_of_cases
                                                     END, 3)
                             END
                         END
                       )                                   AS confirm_quantity -- 予実数
           FROM  xxwsh_order_headers_all               xoha             -- 受注ヘッダアドオン
                ,xxwsh_order_lines_all                 xola             -- 受注明細アドオン
-- 2009/01/15 Y.Yamamoto #1021 add start
                ,oe_transaction_types_all              otta             -- 受注タイプ
-- 2009/01/15 Y.Yamamoto #1021 add end
                ,xxcmn_lookup_values2_v                xlvv1            -- クイックコード1
                ,xxcmn_lookup_values2_v                xlvv2            -- クイックコード2
                ,xxcmn_item_mst2_v                     ximv             -- OPM品目情報VIEW
           WHERE
           ------------------------------------------------------------------------
           -- クイックコード１
               xlvv1.lookup_type                   = gv_lookup_type1
           AND xlvv1.lookup_code                   = iv_select_status
           ------------------------------------------------------------------------
           -- クイックコード２
           AND xlvv2.lookup_type                   = xlvv1.meaning
           ------------------------------------------------------------------------
           -- 受注ヘッダアドオン条件
           AND xoha.req_status                     = xlvv2.lookup_code
           AND xoha.latest_external_flag           = 'Y'
-- mod start ver1.6
--           AND xoha.schedule_arrival_date          = id_arrival_date
           AND xoha.schedule_arrival_date          >= TRUNC(id_arrival_date, 'MONTH')
           AND xoha.schedule_arrival_date          <= id_arrival_date
-- mod end ver1.6
           ------------------------------------------------------------------------
           -- 受注明細アドオン条件
           AND xoha.order_header_id                = xola.order_header_id
-- 2008/12/09 v1.9 ADD START
           AND NVL(xola.delete_flag, gv_n)         = gv_n
-- 2008/12/09 v1.9 ADD END
-- 2009/01/15 Y.Yamamoto #1021 add start
           AND xoha.order_type_id                  = otta.transaction_type_id
           AND otta.attribute1                     = '1'
-- 2009/01/15 Y.Yamamoto #1021 add end
           ------------------------------------------------------------------------
           -- OPM品目情報VIEW条件
           AND xola.request_item_code              = ximv.item_no
           AND ximv.start_date_active             <= id_arrival_date
           AND ximv.end_date_active               >= id_arrival_date
           ------------------------------------------------------------------------
           GROUP BY xola.request_item_code
          )                                sub3
         ,xxcmn_item_mst2_v                     ximv             -- OPM品目情報VIEW
         ------------------------------------------------------------------------
--
    WHERE
    ------------------------------------------------------------------------
    -- 出荷調整表集計中間テーブル
        sub1.item_code                       = ximv.item_no
    ------------------------------------------------------------------------
    -- フォーキャスト
    --AND sub2.inventory_item_id               = ximv.inventory_item_id  -- 2008/07/23 ST不具合対応#475
    AND sub2.inventory_item_id(+)              = ximv.inventory_item_id  -- 2008/07/23 ST不具合対応#475
    ------------------------------------------------------------------------
    -- 受注データ
    --AND sub3.request_item_code               = ximv.item_no  -- 2008/07/23 ST不具合対応#475
    AND sub3.request_item_code(+)            = ximv.item_no    -- 2008/07/23 ST不具合対応#475
    ------------------------------------------------------------------------
    -- OPM品目情報VIEW条件
    AND ximv.start_date_active             <= id_arrival_date
    AND ximv.end_date_active               >= id_arrival_date
    ------------------------------------------------------------------------
    ;
--
    -- ====================================================
    -- データ登録
    -- ====================================================
    ln_cnt := lt_leaf_zensha_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_all_item_code(ln_move_cnt)                              -- 拠点コード
        := lt_leaf_zensha_data(ln_move_cnt).item_code;
      gt_all_plan_quantity(ln_move_cnt)                          -- 品目コード
        := lt_leaf_zensha_data(ln_move_cnt).plan_quantity;
      gt_all_confirm_quantity(ln_move_cnt)                       -- 品目名
        := lt_leaf_zensha_data(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_all_tmp(
        item_code,                                               -- 品目コード
        plan_quantity,                                           -- 計画数
        confirm_quantity                                         -- 予実数
      )VALUES(
        gt_all_item_code(ln_move_cnt),
        gt_all_plan_quantity(ln_move_cnt),
        gt_all_confirm_quantity(ln_move_cnt)
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_leaf_zensha_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_subtotal_monthly_data
   * Description      : リーフ累計数・月間数算出処理
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_total_mon_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT NOCOPY VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_leaf_total_mon_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 累計数・月間数算出データ
    lt_leaf_subtotal_monthly_data        type_leaf_total_mon_tbl;
    -- 取得レコード数
    ln_cnt                               NUMBER DEFAULT 0;
--
  BEGIN
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    SELECT xsadt.head_sales_branch         AS head_sales_branch                 -- 拠点コード
          ,xsadt.item_code                 AS item_code                         -- 品目コード
          ,xsadt.item_name                 AS item_name                         -- 品目名
          ,xsadt.arrival_date              AS arrival_date                      -- 着日
          ,xsadt.plan_quantity             AS plan_quantity                     -- 計画数（着日）
          ,xsadt.confirm_quantity          AS confirm_quantity                  -- 予実数（着日）
          ,SUM(xsadt.plan_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch ,xsadt.item_code        -- 計画数（累計）
                   ORDER BY xsadt.arrival_date
                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                           AS plan_subtotal_quantity
          ,SUM(xsadt.confirm_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch ,xsadt.item_code        -- 予実数（累計）
                   ORDER BY xsadt.arrival_date
                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                           AS confirm_subtotal_quantity
          ,SUM(xsadt.plan_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
                                           AS plan_monthly_quantity             -- 計画数（月間）
          ,SUM(xsadt.confirm_quantity)
             OVER (PARTITION BY xsadt.head_sales_branch, xsadt.item_code)
                                           AS confirm_monthly_quantity          -- 予実数（月間）
--
    BULK COLLECT INTO lt_leaf_subtotal_monthly_data
--
    FROM   xxwsh_ship_adjust_days_tmp   xsadt               -- 出荷調整表日別中間テーブル
    ORDER BY xsadt.arrival_date                             -- 着日
    ;
--
    -- ====================================================
    -- データ登録
    -- ====================================================
    ln_cnt := lt_leaf_subtotal_monthly_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_head_sales_branch(ln_move_cnt)                                         -- 拠点コード
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).head_sales_branch;
      gt_i_item_code(ln_move_cnt)                                                 -- 品目コード
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).item_code;
      gt_i_item_name(ln_move_cnt)                                                 -- 品目名
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).item_name;
      gt_i_arrival_date(ln_move_cnt)                                              -- 着日
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).arrival_date;
      gt_i_plan_quantity(ln_move_cnt)                                             -- 計画数（着日）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_quantity;
      gt_i_confirm_quantity(ln_move_cnt)                                          -- 予実数（着日）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_quantity;
      gt_i_plan_subtotal_quantity(ln_move_cnt)                                    -- 計画数（累計）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_subtotal_quantity;
      gt_i_confirm_subtotal_quantity(ln_move_cnt)                                 -- 予実数（累計）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_subtotal_quantity;
      gt_i_plan_monthly_quantity(ln_move_cnt)                                     -- 計画数（月間）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).plan_monthly_quantity;
      gt_i_confirm_monthly_quantity(ln_move_cnt)                                  -- 予実数（月間）
        := lt_leaf_subtotal_monthly_data(ln_move_cnt).confirm_monthly_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_total_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        plan_quantity,                             -- 計画数（着日）
        confirm_quantity,                          -- 予実数（着日）
        plan_subtotal_quantity,                    -- 計画数（累計）
        confirm_subtotal_quantity,                 -- 予実数（累計）
        monthly_plan_quantity,                     -- 計画数（月間）
        monthly_confirm_quantity                   -- 予実数（月間）
      )VALUES(
        gt_i_head_sales_branch(ln_move_cnt),
        gt_i_item_code(ln_move_cnt),
        gt_i_item_name(ln_move_cnt),
        gt_i_arrival_date(ln_move_cnt),
        gt_i_plan_quantity(ln_move_cnt),
        gt_i_confirm_quantity(ln_move_cnt),
        gt_i_plan_subtotal_quantity(ln_move_cnt),
        gt_i_confirm_subtotal_quantity(ln_move_cnt),
        gt_i_plan_monthly_quantity(ln_move_cnt),
        gt_i_confirm_monthly_quantity(ln_move_cnt)
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_leaf_total_mon_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_confirm_data
   * Description      : リーフ予実数取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_confirm_data(
      iv_select_status      IN         VARCHAR2       -- プロファイル.抽出対象ステータス
     ,iv_kyoten_cd          IN         VARCHAR2       -- 拠点
     ,iv_shipped_locat      IN         VARCHAR2       -- 出庫元
     ,id_arrival_date       IN         DATE           -- 着日
     ,on_confirm_cnt        OUT        NUMBER         -- 取得件数
     ,ov_errbuf             OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_confirm_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_select CONSTANT VARCHAR2(32767) := 
         '  SELECT xoha.head_sales_branch                  AS head_sales_branch      ' -- 管轄拠点
      || '        ,xola.request_item_code                  AS item_code              ' -- 出荷品目
      || '        ,MAX(ximv.item_short_name)               AS item_name              ' -- 品目名称
      || '        ,xoha.schedule_arrival_date              AS arrival_date           ' -- 着荷予定日
      || '        ,SUM(CASE                                                          '
                      -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
      || '            WHEN  (xoha.req_status = ''' || gv_req_status || ''' ) THEN    '
      || '              CASE WHEN (ximv.conv_unit IS NULL) THEN                      '
      || '                     xola.shipped_quantity                                 '
      || '                   ELSE                                                    '
      || '                     TRUNC(xola.shipped_quantity                           '
      || '                           / CASE                                          '
      || '                               WHEN ximv.num_of_cases IS NULL   THEN ''1'' '
      || '                               WHEN ximv.num_of_cases = ''0''   THEN ''1'' '
      || '                               ELSE ximv.num_of_cases                      '
      || '                             END, 3)                                       '
      || '                   END                                                     '
                      -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
      || '            ELSE                                                           '
      || '              CASE WHEN (ximv.conv_unit IS NULL) THEN                      '
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
      --|| '                     xola.quantity                                         '
      || '                     NVL(xola.quantity, 0)                                 '
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
      || '                   ELSE                                                    '
-- 2008/11/14 v1.8 T.Yoshimoto Mod Start 内部変更#168
      --|| '                     TRUNC(xola.quantity                                   '
      || '                     TRUNC(NVL(xola.quantity, 0)                           '
-- 2008/11/14 v1.8 T.Yoshimoto Mod End 内部変更#168
      || '                           / CASE                                          '
      || '                               WHEN ximv.num_of_cases IS NULL   THEN ''1'' '
      || '                               WHEN ximv.num_of_cases = ''0''   THEN ''1'' '
      || '                               ELSE ximv.num_of_cases                      '
      || '                             END, 3)                                       '
      || '                   END                                                     '
      || '            END)                                  AS confirm_quantity      '  -- 予実数
      ;
--
    cv_from CONSTANT VARCHAR2(32767) := 
         '  FROM   xxwsh_order_headers_all    xoha  '                                   -- 受注ヘッダアドオン
      || '        ,xxwsh_order_lines_all      xola  '                                   -- 受注明細アドオン
-- 2009/01/15 Y.Yamamoto #1021 add start
      || '        ,oe_transaction_types_all   otta   '                                  -- 受注タイプ
-- 2009/01/15 Y.Yamamoto #1021 add end
      || '        ,xxcmn_item_mst2_v          ximv  '                                   -- OPM品目情報VIEW2
      || '        ,xxcmn_item_categories5_v   xicv  '                                   -- OPM品目カテゴリ割当情報VIEW5
      || '        ,xxcmn_lookup_values2_v     xlvv1 '                                   -- クイックコード1
      || '        ,xxcmn_lookup_values2_v     xlvv2 '                                   -- クイックコード2 
      ;
--
    cv_where CONSTANT VARCHAR2(32767) := 
         '  WHERE                                                                   '
            -- *** 結合条件 *** --
      || '         xoha.order_header_id        = xola.order_header_id               '  -- 結合条件 受注ヘッダアドオン AND 受注明細アドオン
-- 2009/01/15 Y.Yamamoto #1021 add start
      || '  AND    xoha.order_type_id          = otta.transaction_type_id           '  -- 結合条件 受注ヘッダアドオン AND 受注タイプ
      || '  AND    otta.attribute1             = ''1''                              '  -- 結合条件 受注タイプ AND 出荷依頼「1」
-- 2009/01/15 Y.Yamamoto #1021 add end
      || '  AND    xoha.req_status             = xlvv2.lookup_code                  '  -- 結合条件 受注ヘッダアドオン AND クイックコード２
      || '  AND    xlvv2.lookup_type           = xlvv1.meaning                      '  -- 結合条件 クイックコード１ AND クイックコード２
      || '  AND    xola.request_item_code      = ximv.item_no                       '  -- 結合条件 受注明細アドオン AND OPM品目情報VIEW2
      || '  AND    ximv.item_id                = xicv.item_id                       '  -- 結合条件 OPM品目情報VIEW2 AND OPM品目カテゴリ割当情報VIEW5条件
            -- *** 抽出条件 *** --
      || '  AND    xlvv1.lookup_type           = ''' || gv_lookup_type1 || '''      '  -- 抽出条件 クイックコード１.タイプ：出荷調整抽出対象ステータス種別
      || '  AND    xlvv1.lookup_code           = :iv_select_status                  '  -- 抽出条件 クイックコード１.コード：IN抽出対象ステータス
      || '  AND    xoha.latest_external_flag   = ''Y''                              '  -- 抽出条件 受注ヘッダアドドン.最新フラグ：「Y」
      || '  AND    xoha.schedule_arrival_date >= TRUNC(:id_arrival_date, ''MONTH'') '  -- 抽出条件 受注ヘッダアドドン.着荷予定日：IN着日
      || '  AND    xoha.schedule_arrival_date <= LAST_DAY(:id_arrival_date)         '  -- 抽出条件 受注ヘッダアドドン.着荷予定日：IN着日
      || '  AND    ximv.start_date_active     <= :id_arrival_date                   '  -- 抽出条件 OPM品目情報VIEW2.適用開始日：IN着日
      || '  AND    ximv.end_date_active       >= :id_arrival_date                   '  -- 抽出条件 OPM品目情報VIEW2.適用開始日：IN着日
      || '  AND    xicv.prod_class_code        = ''' || gv_syori_kbn_leaf || '''    '  -- 抽出条件 OPM品目カテゴリ割当情報VIEW5.商品区分：「1：リーフ」
-- 2008/12/09 v1.9 ADD START
      || '  AND    NVL(xola.delete_flag, :gv_n) = :gv_n                             '  -- 抽出条件 受注明細アドオン.削除フラグ：「N」
-- 2008/12/09 v1.9 ADD END
      ;
    cv_where_kyoten_cd    CONSTANT VARCHAR2(32767) := 
         '  AND    xoha.head_sales_branch      = ''' || iv_kyoten_cd || '''         '; -- 抽出条件 受注ヘッダアドドン.管轄拠点：IN拠点
    cv_where_deliver_from CONSTANT VARCHAR2(32767) := 
         '  AND    xoha.deliver_from           = ''' || iv_shipped_locat || '''     '; -- 抽出条件 受注ヘッダアドドン.管轄拠点：IN出庫元
--
    cv_group_by CONSTANT VARCHAR2(32767) := 
         '  GROUP BY xoha.head_sales_branch      ' -- 受注ヘッダアドオン.管轄拠点
      || '          ,xola.request_item_code      ' -- 受注ヘッダ明細.出荷品目
      || '          ,xoha.schedule_arrival_date  ' -- 受注ヘッダアドオン.着荷予定日
      ;
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 取得データ
    lt_leaf_confirm_data_tbl          type_leaf_confirm_data_tbl;
    -- 取得データ数
    ln_cnt                            NUMBER DEFAULT 0;
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    lv_sql                            VARCHAR2(32767); -- 動的SQL用
    lv_where_kyoten_cd                VARCHAR2(32767); -- WHERE句拠点
    lv_where_deliver_from             VARCHAR2(32767); -- WHERE句出庫元
-- 2008/09/01 H.Itou Add End
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- カーソル宣言
    -- =====================================================
    TYPE ref_cursor        IS REF CURSOR ;
    cur_leaf_confirm_data  ref_cursor ;  -- リーフ予実数データ
-- 2008/09/01 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- SQL生成
    -- =====================================================
    -- INパラメータ.拠点に入力ありの場合、管轄拠点を条件に追加
    IF (iv_kyoten_cd IS NOT NULL) THEN
      lv_where_kyoten_cd := cv_where_kyoten_cd;
    ELSE
      lv_where_kyoten_cd := ' ';
    END IF;
--
    -- INパラメータ.出庫元に入力ありの場合、出庫元を条件に追加
    IF (iv_shipped_locat IS NOT NULL) THEN
      lv_where_deliver_from := cv_where_deliver_from;
    ELSE
      lv_where_deliver_from := ' ';
    END IF;
--
    lv_sql := cv_select
           || cv_from
           || cv_where
           || lv_where_kyoten_cd
           || lv_where_deliver_from
           || cv_group_by;
-- 2008/09/01 H.Itou Add End
    -- ====================================================
    -- データ抽出
    -- ====================================================
-- 2008/09/01 H.Itou Mod Start PT 2-1_10対応
    -- カーソルオープン
    OPEN cur_leaf_confirm_data FOR lv_sql
    USING
      iv_select_status      -- INパラメータ.抽出対象ステータス
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
-- 2008/12/09 ADD START
     ,gv_n                  -- INパラメータ.'N'
     ,gv_n                  -- INパラメータ.'N'
-- 2008/12/09 ADD END
    ;
    -- バルクフェッチ
    FETCH cur_leaf_confirm_data BULK COLLECT INTO lt_leaf_confirm_data_tbl;
    -- カーソルクローズ
    CLOSE cur_leaf_confirm_data;
--
--    SELECT xoha.head_sales_branch                  AS head_sales_branch     -- 管轄拠点
--          ,xola.request_item_code                  AS item_code             -- 出荷品目
--          ,MAX(ximv.item_short_name)               AS item_name             -- 品目名称
--          ,xoha.schedule_arrival_date              AS arrival_date          -- 着荷予定日
--          ,SUM(CASE
--              -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
--              WHEN  (xoha.req_status = gv_req_status) THEN
--                CASE WHEN (ximv.conv_unit IS NULL) THEN
--                       xola.shipped_quantity
--                     ELSE
--                       TRUNC(xola.shipped_quantity / CASE
--                                                       WHEN ximv.num_of_cases IS NULL THEN '1'
--                                                       WHEN ximv.num_of_cases = '0'   THEN '1'
--                                                       ELSE ximv.num_of_cases
--                                                     END, 3)
--                     END
--              -- 受注ヘッダアドオン.ステータス=「出荷実績計上済」の場合
--              ELSE
--                CASE WHEN (ximv.conv_unit IS NULL) THEN
--                       xola.quantity
--                     ELSE
--                       TRUNC(xola.quantity
--                             / CASE
--                                 WHEN ximv.num_of_cases IS NULL THEN '1'
--                                 WHEN ximv.num_of_cases = '0'   THEN '1'
--                                 ELSE ximv.num_of_cases
--                               END, 3)
--                     END
--              END)                                  AS confirm_quantity     -- 予実数
----
--    BULK COLLECT INTO lt_leaf_confirm_data_tbl
----
--    FROM   xxwsh_order_headers_all    xoha        -- 受注ヘッダアドオン
--          ,xxwsh_order_lines_all      xola        -- 受注明細アドオン
--          ,xxcmn_item_mst2_v          ximv        -- OPM品目情報VIEW
---- mod start ver1.6
----          ,xxcmn_item_categories4_v   xicv        -- OPM品目カテゴリ割当情報VIEW4
--          ,xxcmn_item_categories5_v   xicv        -- OPM品目カテゴリ割当情報VIEW5
---- mod end ver1.6
--          ,xxcmn_lookup_values2_v     xlvv1       -- クイックコード1
--          ,xxcmn_lookup_values2_v     xlvv2       -- クイックコード2
--    WHERE
--    ------------------------------------------------------------------------
--    -- クイックコード１
--        xlvv1.lookup_type                      = gv_lookup_type1
--    AND xlvv1.lookup_code                      = iv_select_status
--    ------------------------------------------------------------------------
--    -- クイックコード２
--    AND xlvv2.lookup_type                      = xlvv1.meaning
--    ------------------------------------------------------------------------
--    -- 受注ヘッダアドオン条件
--    AND   xoha.req_status                     = xlvv2.lookup_code
--    AND   xoha.latest_external_flag           = 'Y'
--    AND   xoha.head_sales_branch              = NVL(iv_kyoten_cd, xoha.head_sales_branch)
--    AND   xoha.deliver_from                   = NVL(iv_shipped_locat, xoha.deliver_from)
--    AND   xoha.schedule_arrival_date          >= TRUNC(id_arrival_date, 'MONTH')
--    AND   xoha.schedule_arrival_date          <= LAST_DAY(id_arrival_date)
--    ------------------------------------------------------------------------
--    -- 受注明細アドオン条件
--    AND   xoha.order_header_id                = xola.order_header_id
--    ------------------------------------------------------------------------
--    -- OPM品目情報view
--    AND   xola.request_item_code             = ximv.item_no
--    AND   ximv.start_date_active              <= id_arrival_date
--    AND   ximv.end_date_active                >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- OPM品目カテゴリ割当情報VIEW4条件
--    AND   ximv.item_id = xicv.item_id
--    AND   xicv.prod_class_code                = gv_syori_kbn_leaf
--    ------------------------------------------------------------------------
--    GROUP BY xoha.head_sales_branch                        -- 受注ヘッダアドオン.管轄拠点
--            ,xola.request_item_code                       -- 受注ヘッダ明細.出荷品目
--            ,xoha.schedule_arrival_date                    -- 受注ヘッダアドオン.着荷予定日
--    ;
-- 2008/09/01 H.Itou Mod End
--
    -- ====================================================
    -- データ登録
    -- ====================================================
    ln_cnt := lt_leaf_confirm_data_tbl.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_plan_head_sales_branch(ln_move_cnt)                           -- 拠点コード
        := lt_leaf_confirm_data_tbl(ln_move_cnt).head_sales_branch;
      gt_plan_item_code(ln_move_cnt)                                   -- 品目コード
        := lt_leaf_confirm_data_tbl(ln_move_cnt).item_code;
      gt_plan_item_name(ln_move_cnt)                                   -- 品目名
        := lt_leaf_confirm_data_tbl(ln_move_cnt).item_name;
      gt_plan_arrival_date(ln_move_cnt)                                -- 着日
        := lt_leaf_confirm_data_tbl(ln_move_cnt).arrival_date;
      gt_plan_confirm_quantity(ln_move_cnt)                            -- 予実数（着日）
        := lt_leaf_confirm_data_tbl(ln_move_cnt).confirm_quantity;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_shippng_adj_plan_act_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        confirm_quantity                           -- 予実数（着日）
      )VALUES(
        gt_plan_head_sales_branch(ln_move_cnt),
        gt_plan_item_code(ln_move_cnt),
        gt_plan_item_name(ln_move_cnt),
        gt_plan_arrival_date(ln_move_cnt),
        gt_plan_confirm_quantity(ln_move_cnt)
      );
--
    on_confirm_cnt := ln_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_leaf_confirm_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_plan_data
   * Description      : リーフ計画数取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_plan_data(
      iv_kyoten_cd             IN         VARCHAR2       -- 拠点
     ,iv_shipped_locat         IN         VARCHAR2       -- 出庫元
     ,id_arrival_date          IN         DATE           -- 着日
     ,on_plan_cnt              OUT        NUMBER         -- 取得件数
     ,ov_errbuf                OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_plan_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_select CONSTANT VARCHAR2(32000) := 
         '  SELECT mfde.attribute3                AS head_sales_branch           '    -- フォーキャスト名.拠点
      || '        ,MAX(ximv.item_no)              AS item_code                   '    -- OPM品目情報VIEW2.品目コード
      || '        ,MAX(ximv.item_short_name)      AS item_name                   '    -- OPM品目情報VIEW2.品目名称
      || '        ,mfda.forecast_date             AS arrival_date                '    -- フォーキャスト日付.開始日
      || '        ,SUM(CASE                                                      '
                         -- OPM品目マスタ.入出庫換算単位が未設定の場合
      || '               WHEN (ximv.conv_unit IS NULL) THEN                      '
      || '                     mfda.original_forecast_quantity                   '
      || '               ELSE                                                    '
      || '                 TRUNC(mfda.original_forecast_quantity                 '
      || '                       / CASE                                          '
      || '                           WHEN ximv.num_of_cases IS NULL   THEN ''1'' '
      || '                           WHEN ximv.num_of_cases = ''0''   THEN ''1'' '
      || '                           ELSE ximv.num_of_cases                      '
      || '                         END, 3)                                       '
      || '               END                                                     '
      || '            )                           AS plan_quantity               '     -- フォーキャスト日付.数量
      ;
--
    cv_from CONSTANT VARCHAR2(32000) := 
         '  FROM   mrp_forecast_designators  mfde '                                    -- フォーキャスト名
      || '        ,mrp_forecast_dates        mfda '                                    -- フォーキャスト日付
      || '        ,xxcmn_item_mst2_v         ximv '                                    -- OPM品目情報VIEW2
      || '        ,xxcmn_item_categories5_v  xicv '                                    -- OPM品目カテゴリ割当情報VIEW5
      ;
--
    cv_where CONSTANT VARCHAR2(32000) := 
         '  WHERE                                                                        '
            -- *** 結合条件 *** --
      || '         mfde.forecast_designator = mfda.forecast_designator               ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
      || '  AND    mfde.organization_id     = mfda.organization_id                   ' -- 結合条件 フォーキャスト名 AND フォーキャスト日付
      || '  AND    mfda.inventory_item_id   = ximv.inventory_item_id                 ' -- 結合条件 フォーキャスト日付 AND OPM品目情報VIEW2
      || '  AND    ximv.item_id             = xicv.item_id                           ' -- 結合条件 OPM品目情報VIEW2 AND OPM品目カテゴリ割当情報VIEW5
            -- *** 抽出条件 *** --
      || '  AND    mfde.attribute1          = ''' || gv_forecast_kbn_hkeikaku || ''' ' -- 抽出条件 フォーキャスト名.フォーキャスト分類：「01：引取計画」
      || '  AND    mfda.forecast_date      >= TRUNC(:id_arrival_date, ''MONTH'')     ' -- 抽出条件 フォーキャスト日付.開始日：IN着荷日
      || '  AND    mfda.forecast_date      <= LAST_DAY(:id_arrival_date)             ' -- 抽出条件 フォーキャスト日付.開始日：IN着荷日
      || '  AND    ximv.start_date_active  <= :id_arrival_date                       ' -- 抽出条件 OPM品目情報VIEW2.開始日：IN着荷日
      || '  AND    ximv.end_date_active    >= :id_arrival_date                       ' -- 抽出条件 OPM品目情報VIEW2.終了日：IN着荷日
      || '  AND    xicv.prod_class_code     = ''' || gv_syori_kbn_leaf || '''        ' -- 抽出条件 OPM品目カテゴリ割当情報VIEW5.商品区分：「1：リーフ」
      ;
    cv_where_kyoten_cd    CONSTANT VARCHAR2(32000) := 
         '  AND    mfde.attribute3          = ''' || iv_kyoten_cd || '''            '; -- 抽出条件 フォーキャスト名.拠点：IN拠点
    cv_where_deliver_from CONSTANT VARCHAR2(32000) := 
         '  AND    mfde.attribute2          = ''' || iv_shipped_locat || '''        '; -- 抽出条件 フォーキャスト名.IN出荷元
    cv_group_by CONSTANT VARCHAR2(32000) := 
         '  GROUP BY mfde.attribute3         ' -- フォーキャスト名.拠点
      || '          ,mfda.inventory_item_id  ' -- フォーキャスト日付.品目ID
      || '          ,mfda.forecast_date      ' -- フォーキャスト日付.開始日
      ;
-- 2008/09/01 H.Itou Add End
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- 計画数データ
    lt_leaf_plan_data              type_leaf_plan_data_tbl;
    -- 取得データ数
    ln_cnt                         NUMBER DEFAULT 0;
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    lv_sql                         VARCHAR2(32767); -- 動的SQL用
    lv_where_kyoten_cd             VARCHAR2(32767); -- WHERE句拠点
    lv_where_deliver_from          VARCHAR2(32767); -- WHERE句出庫元
-- 2008/09/01 H.Itou Add End
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- カーソル宣言
    -- =====================================================
    TYPE ref_cursor        IS REF CURSOR ;
    cur_leaf_plan_data  ref_cursor ;  -- リーフ計画数データ
-- 2008/09/01 H.Itou Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/09/01 H.Itou Add Start PT 2-1_10対応
    -- =====================================================
    -- SQL生成
    -- =====================================================
    -- INパラメータ.拠点に入力ありの場合、管轄拠点を条件に追加
    IF (iv_kyoten_cd IS NOT NULL) THEN
      lv_where_kyoten_cd := cv_where_kyoten_cd;
--
    -- INパラメータ.拠点に入力なしの場合、管轄拠点を条件としない
    ELSE
      lv_where_kyoten_cd := ' ';
    END IF;
--
    -- INパラメータ.出庫元に入力ありの場合、出庫元を条件に追加
    IF (iv_shipped_locat IS NOT NULL) THEN
      lv_where_deliver_from := cv_where_deliver_from;
--
    -- INパラメータ.出庫元に入力なしの場合、出庫元を条件としない
    ELSE
      lv_where_deliver_from := ' ';
    END IF;
--
    lv_sql := cv_select
           || cv_from
           || cv_where
           || lv_where_kyoten_cd
           || lv_where_deliver_from
           || cv_group_by;
-- 2008/09/01 H.Itou Add End
    -- ====================================================
    -- データ抽出
    -- ====================================================
-- 2008/09/01 H.Itou Mod Start PT 2-1_10対応
    -- カーソルオープン
    OPEN cur_leaf_plan_data FOR lv_sql
    USING
      id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
     ,id_arrival_date       -- INパラメータ.着日
    ;
    -- バルクフェッチ
    FETCH cur_leaf_plan_data BULK COLLECT INTO lt_leaf_plan_data;
    -- カーソルクローズ
    CLOSE cur_leaf_plan_data;
--
--    SELECT mfde.attribute3                AS head_sales_branch    -- フォーキャスト名.拠点
--          ,MAX(ximv.item_no)              AS item_code            -- OPM品目情報VIEW.品目コード
--          ,MAX(ximv.item_short_name)      AS item_name            -- OPM品目情報VIEW.品目名称
--          ,mfda.forecast_date             AS arrival_date         -- フォーキャスト日付.開始日
--          ,SUM(CASE
--                 -- OPM品目マスタ.入出庫換算単位が未設定の場合
--                 WHEN (ximv.conv_unit IS NULL) THEN
--                   mfda.original_forecast_quantity
--                 ELSE
--                   TRUNC(mfda.original_forecast_quantity / CASE
--                                                             WHEN ximv.num_of_cases IS NULL THEN '1'
--                                                             WHEN ximv.num_of_cases = '0'   THEN '1'
--                                                             ELSE ximv.num_of_cases
--                                                           END, 3)
--                 END
--              )                           AS plan_quantity        -- フォーキャスト日付.数量
----
--    BULK COLLECT INTO lt_leaf_plan_data
----
--    FROM  mrp_forecast_designators  mfde                          -- フォーキャスト名
--         ,mrp_forecast_dates        mfda                          -- フォーキャスト日付
--         ,xxcmn_item_mst2_v         ximv                          -- OPM品目情報VIEW
---- mod start ver1.6
----         ,xxcmn_item_categories4_v  xicv                          -- OPM品目カテゴリ割当情報VIEW4
--         ,xxcmn_item_categories5_v  xicv                          -- OPM品目カテゴリ割当情報VIEW5
---- mod end ver1.6
----
--    WHERE
--    ------------------------------------------------------------------------
--    -- フォーキャスト名
--        mfde.attribute1               = gv_forecast_kbn_hkeikaku
--    AND mfde.attribute3               = NVL(iv_kyoten_cd, mfde.attribute3)
--    AND mfde.attribute2               = NVL(iv_shipped_locat, mfde.attribute2)
--    ------------------------------------------------------------------------
--    -- フォーキャスト日付
--    AND mfde.forecast_designator      = mfda.forecast_designator
--    AND mfde.organization_id          = mfda.organization_id
--    AND mfda.forecast_date            >= TRUNC(id_arrival_date, 'MONTH')
--    AND mfda.forecast_date            <= LAST_DAY(id_arrival_date)
--    ------------------------------------------------------------------------
--    -- OPM品目情報VIEW条件
--    AND mfda.inventory_item_id        = ximv.inventory_item_id
--    AND ximv.start_date_active        <= id_arrival_date
--    AND ximv.end_date_active          >= id_arrival_date
--    ------------------------------------------------------------------------
--    -- OPM品目カテゴリ割当情報VIEW4
--    AND ximv.item_id                  = xicv.item_id
--    AND xicv.prod_class_code          = gv_syori_kbn_leaf
--    ------------------------------------------------------------------------
--    GROUP BY mfde.attribute3                                      -- フォーキャスト名.拠点
--            ,mfda.inventory_item_id                               -- フォーキャスト日付.品目ID
--            ,mfda.forecast_date                                   -- フォーキャスト日付.開始日
--    ;
-- 2008/09/01 H.Itou Add End
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    ln_cnt := lt_leaf_plan_data.COUNT;
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_day_head_sales_branch(ln_move_cnt)                           -- 拠点コード
        := lt_leaf_plan_data(ln_move_cnt).head_sales_branch;
      gt_day_item_code(ln_move_cnt)                                   -- 品目コード
        := lt_leaf_plan_data(ln_move_cnt).item_code;
      gt_day_item_name(ln_move_cnt)                                   -- 品目名
        := lt_leaf_plan_data(ln_move_cnt).item_name;
      gt_day_arrival_date(ln_move_cnt)                                -- 着日
        := lt_leaf_plan_data(ln_move_cnt).arrival_date;
      gt_day_plan_quantity(ln_move_cnt)                               -- 計画数（着日）
        := lt_leaf_plan_data(ln_move_cnt).plan_quantity;
      gt_day_confirm_quantity(ln_move_cnt)                            -- 予実数（着日）
        := 0;
    END LOOP;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxwsh_ship_adjust_days_tmp(
        head_sales_branch,                         -- 拠点コード
        item_code,                                 -- 品目コード
        item_name,                                 -- 品目名
        arrival_date,                              -- 着日
        plan_quantity,                             -- 計画数（着日）
        confirm_quantity                           -- 予実数（着日）
      )VALUES(
        gt_day_head_sales_branch(ln_move_cnt),
        gt_day_item_code(ln_move_cnt),
        gt_day_item_name(ln_move_cnt),
        gt_day_arrival_date(ln_move_cnt),
        gt_day_plan_quantity(ln_move_cnt),
        gt_day_confirm_quantity(ln_move_cnt)
      );
--
    on_plan_cnt := ln_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_leaf_plan_data;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_leaf_info
   * Description      : リーフ情報取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_leaf_info(
      iv_syori_kbn             IN  VARCHAR2         -- 01 : 処理区分
     ,iv_kyoten_cd             IN  VARCHAR2         -- 02 : 拠点
     ,iv_shipped_locat         IN  VARCHAR2         -- 03 : 出庫元
     ,id_arrival_date          IN  DATE             -- 04 : 着日
     ,iv_select_status         IN  VARCHAR2         -- 05 : 抽出対象ステータス
     ,ov_errbuf                OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode               OUT VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg                OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_leaf_info'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- リーフ情報
    lt_chosei_data           type_chosei_data_tbl;
    -- 計画数取得件数
    ln_plan_cnt              NUMBER DEFAULT 0;
    -- 予実数取得件数
    ln_confirm_cnt           NUMBER DEFAULT 0;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- リーフ計画数取得処理
    -- ====================================================
    prc_get_leaf_plan_data(
        iv_kyoten_cd         =>     iv_kyoten_cd         -- 拠点
       ,iv_shipped_locat     =>     iv_shipped_locat     -- 出庫元
       ,id_arrival_date      =>     id_arrival_date      -- 着日
       ,on_plan_cnt          =>     ln_plan_cnt          -- 取得件数
       ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- リーフ予実数取得処理
    -- ====================================================
    prc_get_leaf_confirm_data(
        iv_select_status     =>     iv_select_status     -- 抽出対象ステータス
       ,iv_kyoten_cd         =>     iv_kyoten_cd         -- 拠点
       ,iv_shipped_locat     =>     iv_shipped_locat     -- 出庫元
       ,id_arrival_date      =>     id_arrival_date      -- 着日
       ,on_confirm_cnt       =>     ln_confirm_cnt       -- 取得件数
       ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (ln_plan_cnt <> 0 OR ln_confirm_cnt <> 0) THEN
--
      -- ====================================================
      -- リーフ計画数・予実数マージ処理
      -- ====================================================
      prc_plan_confirm_marge_data(
          ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode           -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ====================================================
      -- リーフ累計数・月間数算出処理
      -- ====================================================
      prc_get_leaf_total_mon_data(
          ov_errbuf          =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode         =>     lv_retcode           -- リターン・コード
         ,ov_errmsg          =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- 抽出対象ステータス<>「拠点パターン」の場合
      IF (iv_select_status <> gv_select_status_kyoten) THEN
--
        -- ====================================================
        -- リーフ全社数取得処理
        -- ====================================================
        prc_get_leaf_zensha_data(
            iv_select_status     =>     iv_select_status     -- プロファイル.抽出対象ステータス
           ,iv_kyoten_cd         =>     iv_kyoten_cd         -- 拠点
           ,iv_shipped_locat     =>     iv_shipped_locat     -- 出庫元
           ,id_arrival_date      =>     id_arrival_date      -- 着日
           ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
           ,ov_retcode           =>     lv_retcode           -- リターン・コード
           ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
        );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END IF;
--
      -- ====================================================
      -- 出荷調整表情報取得処理
      -- ====================================================
      prc_get_chosei_data(
          id_arrival_date      =>     id_arrival_date      -- 着日
         ,ot_chosei_data       =>     lt_chosei_data       -- 取得レコード表（リーフ情報）
         ,ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode           -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    IF (lt_chosei_data.COUNT <> 0) THEN
      -- ====================================================
      -- ＸＭＬデータ作成処理
      -- ====================================================
      prc_create_xml_data(
          iv_syori_kbn         =>     iv_syori_kbn       -- 処理区分
         ,it_chosei_data       =>     lt_chosei_data     -- 出荷調整表データ
         ,ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    ELSE
--
      -- ====================================================
      -- ＸＭＬデータ作成処理（０件）
      -- ====================================================
      prc_create_zeroken_xml_data(
          ov_errbuf            =>     lv_errbuf          -- エラー・メッセージ
         ,ov_retcode           =>     lv_retcode         -- リターン・コード
         ,ov_errmsg            =>     lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
      
    -- ====================================================
    -- ＸＭＬ出力処理
    -- ====================================================
    prc_out_xml_data(
        ov_errbuf            =>     lv_errbuf            -- エラー・メッセージ
       ,ov_retcode           =>     lv_retcode           -- リターン・コード
       ,ov_errmsg            =>     lv_errmsg            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- データなし時、ワーニングセット
    -- ====================================================
    IF (lt_chosei_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
    END IF;
--
  EXCEPTION
      -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_leaf_info;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_shipped_locat
   * Description      : 出庫元情報取得処理
   ***********************************************************************************/
  PROCEDURE prc_get_shipped_locat(
  
    iv_shipped_locat  IN         VARCHAR2,
    id_arrival_date   IN         DATE,
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_shipped_locat'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    SELECT xilv.segment1             AS syukkomoto_cd           -- 出庫元コード
          ,xilv.description          AS syukkomoto_nm           -- 出庫元名
--
    INTO gv_syukkomoto_cd, gv_syukkomoto_nm
--
    FROM   xxcmn_item_locations2_v        xilv                   -- OPM保管場所マスタ情報VIEW
--
    WHERE
    ------------------------------------------------------------------------
    -- OPM保管場所マスタ情報VIEW
        xilv.segment1       = iv_shipped_locat
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END prc_get_shipped_locat;
--
--
  /***********************************************************************************
   * Procedure Name   : prc_get_profile
   * Description      : プロファイルより職責レベルの抽出対象ステータスを取得します。
   ***********************************************************************************/
  PROCEDURE prc_get_profile(
    ov_select_status  OUT NOCOPY VARCHAR2,
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
--
    -- 抽出対象ステータス
    ov_select_status := FND_PROFILE.VALUE(gv_profile_id);
--
    -- プロファイルが取得できない場合はエラー
    IF (ov_select_status IS NULL) THEN
--
      lv_errbuf := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gc_application_cmn,        -- アプリケーション短縮名：XXCMN 共通
                            gv_msg_xxcmn10002,         -- メッセージ：プロファイル取得エラー
                            gv_tkn_profile,            -- トークン：NG_PROFILE
                            gv_profile_name            -- プロファイル名称
                          ),1,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END prc_get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_check_input_data
   * Description      : 入力パラメータチェック処理
   ***********************************************************************************/
  PROCEDURE prc_check_input_data
    (
      iv_arrival_date     IN         VARCHAR2       -- 着日（文字）
     ,od_arrival_date     OUT NOCOPY DATE           -- 着日（日付）
     ,ov_errbuf           OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_check_input_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -----------------------------------------------------
    -- 必須チェック
    -- -----------------------------------------------------
    IF (iv_arrival_date IS NOT NULL) THEN
--
      -- 日付変換
      od_arrival_date := FND_DATE.STRING_TO_DATE(iv_arrival_date
                                                ,gv_date_format2) ;
--
    ELSE
--
      -- エラーメッセージ出力
      ov_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gv_msg_xxwsh11402
                                            ,gv_msg_tkn_pram
                                            ,gv_msg_contents) ;
--
      ov_errbuf  := ov_errmsg ;
      ov_retcode := gv_status_error;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_check_input_data ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : 初期処理
   ***********************************************************************************/
  PROCEDURE prc_init
    (
      ov_errbuf           OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- -----------------------------------------------------
    -- 中間テーブル削除処理
    -- -----------------------------------------------------
    -- 出荷調整表バケット中間テーブル
    DELETE FROM xxwsh_shippng_adj_bucket_tmp;
--
    -- 出荷調整表全社中間テーブル
    DELETE FROM xxwsh_ship_adjust_all_tmp;
--
    -- 出荷調整表日別中間テーブル
    DELETE FROM xxwsh_ship_adjust_days_tmp;
--
    -- 出荷調整表予実中間テーブル
    DELETE FROM xxwsh_shippng_adj_plan_act_tmp;
--
    -- 出荷調整表集計中間テーブル
    DELETE FROM xxwsh_ship_adjust_total_tmp;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := ov_errmsg;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_init ;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_syori_kbn         IN      VARCHAR2         -- 01 : 処理種別
     ,iv_kyoten_cd         IN      VARCHAR2         -- 02 : 拠点
     ,iv_shipped_locat     IN      VARCHAR2         -- 03 : 出庫元
     ,iv_arrival_date      IN      VARCHAR2         -- 04 : 着日
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード            --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- 着日（日付）
    ld_arrival_date         DATE DEFAULT NULL;
    -- プロファイル.抽出対象ステータス
    lv_select_status        VARCHAR(10) DEFAULT NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 中間テーブルデータ削除処理
    -- ====================================================
    prc_init(
          ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ
         ,ov_retcode        =>   lv_retcode         -- リターン・コード
         ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- 入力パラメータチェック処理
    -- ====================================================
    prc_check_input_data(
        iv_arrival_date    => iv_arrival_date     -- 着日（文字）
       ,od_arrival_date    => ld_arrival_date     -- 着日（日付）
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- プロファイル取得処理
    -- ====================================================
    prc_get_profile(
        ov_select_status   => lv_select_status    -- プロファイル.抽出対象ステータス
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode         => lv_retcode          -- リターン・コード
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ====================================================
    -- 出庫元情報取得処理
    -- ====================================================
    IF (iv_shipped_locat IS NOT NULL) THEN
--
      prc_get_shipped_locat(
          iv_shipped_locat   => iv_shipped_locat    -- 出庫元
         ,id_arrival_date    => ld_arrival_date     -- 着日
         ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ
         ,ov_retcode         => lv_retcode          -- リターン・コード
         ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (iv_syori_kbn = gv_syori_kbn_leaf) THEN
--
    -- ====================================================
    -- リーフ情報取得処理
    -- ====================================================
      prc_get_leaf_info(
          iv_syori_kbn      =>   iv_syori_kbn       -- 01 : 処理区分
         ,iv_kyoten_cd      =>   iv_kyoten_cd       -- 02 : 拠点
         ,iv_shipped_locat  =>   iv_shipped_locat   -- 03 : 出庫元
         ,id_arrival_date   =>   ld_arrival_date    -- 04 : 着日
         ,iv_select_status  =>   lv_select_status   -- 05 : 抽出対象ステータス
         ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ
         ,ov_retcode        =>   lv_retcode         -- リターン・コード
         ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    ELSE
--
    -- ====================================================
    -- ドリンク情報取得処理
    -- ====================================================
      prc_get_drink_info(
          iv_syori_kbn      =>   iv_syori_kbn       -- 01 : 処理区分
         ,iv_kyoten_cd      =>   iv_kyoten_cd       -- 02 : 拠点
         ,iv_shipped_locat  =>   iv_shipped_locat   -- 03 : 出庫元
         ,id_arrival_date   =>   ld_arrival_date    -- 04 : 着日
         ,iv_select_status  =>   lv_select_status   -- 05 : 抽出対象ステータス
         ,ov_errbuf         =>   lv_errbuf          -- エラー・メッセージ
         ,ov_retcode        =>   lv_retcode         -- リターン・コード
         ,ov_errmsg         =>   lv_errmsg          -- ユーザー・エラー・メッセージ
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    ELSIF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF;
--
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
  END submain ;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_syori_kbn          IN     VARCHAR2         -- 01 : 処理種別
     ,iv_kyoten_cd          IN     VARCHAR2         -- 02 : 拠点
     ,iv_shipped_locat      IN     VARCHAR2         -- 03 : 出庫元
     ,iv_arrival_date       IN     VARCHAR2         -- 04 : 着日
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
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
    submain(
        iv_syori_kbn          => iv_syori_kbn         -- 01 : 処理種別
       ,iv_kyoten_cd          => iv_kyoten_cd         -- 02 : 拠点
       ,iv_shipped_locat      => iv_shipped_locat     -- 03 : 出庫元
       ,iv_arrival_date       => iv_arrival_date      -- 04 : 着日
       ,ov_errbuf             => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    ) ;
--
    -- ====================================================
    -- ロールバック処理
    -- ====================================================
    ROLLBACK;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwsh400008c ;
/
