CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A02C (body)
 * Description      : INVへの販売実績データ連携
 * MD.050           : INVへの販売実績データ連携 MD050_COS_013_A02
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               販売実績情報取得(A-2)
 *  get_disposition_id     勘定科目別名ID取得(A-3_01)
 *  get_ccid               勘定科目ID取得(A-3_02)
 *  make_mtl_tran_data     資材取引データ生成(A-3)
 *  insert_mtl_tran_oif    資材取引OIF出力(A-4)
 *  update_inv_fsh_flag    処理済ステータス更新(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/22    1.0   H.Ri             新規作成
 *  2009/02/13    1.1   H.Ri             [COS_076]資材取引OIFの設定項目を変更
 *  2009/02/17    1.2   H.Ri             get_msgのパッケージ名修正
 *  2009/02/20    1.3   H.Ri             パラメータのログファイル出力対応
 *  2009/04/28    1.4   N.Maeda          資材取引OIFデータの集約条件に部門コードを追加
 *  2009/05/13    1.5   K.Kiriu          [T1_0984]製品、商品判定の追加
 *  2009/06/17    1.6   K.Kiriu          [T1_1472]取引数量0のデータ対応
 *  2009/07/16    1.7   K.Kiriu          [0000701]PT対応
 *  2009/07/29    1.8   N.Maeda          [0000863]PT対応
 *  2009/08/06    1.8   N.Maeda          [0000942]PT対応
 *  2009/08/24    1.9   N.Maeda          [0001141]納品日考慮対応
 *  2009/08/25    1.10  N.Maeda          [0001164]PT対応(警告データのフラグ更新処理追加[W])
 *                                                処理対象外データのフラグ更新処理追加[S]
 *  2009/09/14    1.11  S.Miyakoshi      [0001360]BULKへの対応
 *  2009/10/08    1.12  M.Sano           [0001520]PT対応
 *  2010/11/01    1.13  K.Kiriu          [E_本稼動_05350]日中化対応に伴う対象外データ更新判定追加
 *
 *****************************************************************************************/
--
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
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** データ登録例外 ***
  global_data_insert_expt           EXCEPTION;
  --*** 対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
  --*** データ抽出例外 ***
  global_data_select_expt           EXCEPTION;
  --*** 対象データ更新例外 ***
  global_data_update_expt           EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS013A02C';         --パッケージ名
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS013A02C';         --コンカレント名
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                --販物領域短縮アプリ名
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                --共通領域短縮アプリ名
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                --在庫領域短縮アプリ名
  --メッセージ
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00010';     --データ登録エラーメッセージ
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00001';     --ロック取得エラーメッセージ
  cv_msg_update_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00011';     --データ更新エラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';     --業務日付取得エラーメッセージ
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';     --プロファイル取得エラーメッセージ
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00005';     --在庫組織コード取得エラーメッセージ
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00006';     --在庫組織ID取得エラーメッセージ
  cv_msg_com_cd_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00007';     --会社コード取得エラーメッセージ
  cv_msg_select_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00013';     --データ抽出エラーメッセージ
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00003';     --対象データ無しエラーメッセージ
  cv_msg_type_jor_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12805';     --取引タイプ／仕訳パターン取得エラー
  cv_msg_src_type_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12802';     --取引ソースタイプID取得エラー
  cv_msg_type_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12803';     --取引タイプID取得エラーメッセージ
  cv_msg_cok_prof_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     --プロファイル取得エラー(個別領域)
  cv_msg_dispt_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12811';     --勘定科目別名ID取得エラーメッセージ
  cv_msg_ccid_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12812';     --勘定科目ID(CCID)取得エラーメッセージ
/* 2009/07/16 Ver1.6 Add Start */
  cv_msg_category_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12817';     --カテゴリセットID取得エラーメッセージ
/* 2009/07/16 Ver1.6 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  cv_msg_category_id        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12818';     --カテゴリID取得エラーメッセージ
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
-- ************************ 2009/08/25 1.10 N.Maeda ADD START *************************** --
  cv_msg_sales_exp_nomal    CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12819'; -- 販売実績明細(正常終了データ)
  cv_msg_sales_exp_warn     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12820'; -- 販売実績明細(警告終了データ)
  cv_msg_sales_exp_exclu    CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12821'; -- 販売実績明細(処理対象外データ)
-- ************************ 2009/08/25 1.10 N.Maeda ADD  END  *************************** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
  cv_msg_prf_bulk_cnt       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12822'; -- XXCOS:結果セット取得件数（バルク）
  cv_msg_sales_exp_target   CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12823'; -- 販売実績明細(処理対象データ)
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
  --トークン名
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) := 'TABLE_NAME';           --テーブル名称
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) := 'TABLE';                --テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) := 'KEY_DATA';             --キーデータ
  cv_tkn_nm_profile_s       CONSTANT  VARCHAR2(100) := 'PROFILE';              --プロファイル名(販売領域)
  cv_tkn_nm_profile_i       CONSTANT  VARCHAR2(100) := 'PRO_TOK';              --プロファイル名(在庫領域)
  cv_tkn_nm_profile_k       CONSTANT  VARCHAR2(100) := 'PROFILE';              --プロファイル名(個別領域)
  cv_tkn_nm_org_cd          CONSTANT  VARCHAR2(100) := 'ORG_CODE_TOK';         --在庫組織コード
  cv_tkn_nm_red_blk         CONSTANT  VARCHAR2(100) := 'RED_BLK';              --赤黒フラグ
  cv_tkn_nm_dlv_inv         CONSTANT  VARCHAR2(100) := 'DLV_INV';              --納品伝票区分
  cv_tkn_nm_dlv_ptn         CONSTANT  VARCHAR2(100) := 'DLV_PTN';              --納品形態区分
  cv_tkn_nm_sale_cls        CONSTANT  VARCHAR2(100) := 'SALE_CLS';             --売上区分
  cv_tkn_nm_item_cls        CONSTANT  VARCHAR2(100) := 'ITEM_CLS';             --商品製品区分
  cv_tkn_nm_src_type        CONSTANT  VARCHAR2(100) := 'SOURCE_TYPE';          --取引ソースタイプ名
  cv_tkn_nm_type            CONSTANT  VARCHAR2(100) := 'TYPE';                 --取引タイプ名
  cv_tkn_nm_line_id         CONSTANT  VARCHAR2(100) := 'LINE_ID';              --販売実績明細ID
  cv_tkn_nm_org_id          CONSTANT  VARCHAR2(100) := 'ORG_ID';               --在庫組織ID
  cv_tkn_nm_dept_cd         CONSTANT  VARCHAR2(100) := 'DEPT_CODE';            --部門コード
  cv_tkn_nm_inv_acc         CONSTANT  VARCHAR2(100) := 'INV_ACC';              --入出庫勘定区分
  cv_tkn_nm_com_cd          CONSTANT  VARCHAR2(100) := 'COM_CODE';             --会社コード
  cv_tkn_nm_acc_cd          CONSTANT  VARCHAR2(100) := 'ACC_CODE';             --勘定科目コード
  cv_tkn_nm_ass_cd          CONSTANT  VARCHAR2(100) := 'ASS_CODE';             --補助科目コード
  cv_tkn_nm_cust_cd         CONSTANT  VARCHAR2(100) := 'CUST_CODE';            --顧客コード
  cv_tkn_nm_ent_cd          CONSTANT  VARCHAR2(100) := 'ENT_CODE';             --企業コード
  cv_tkn_nm_res1_cd         CONSTANT  VARCHAR2(100) := 'RES1_CODE';            --予備１コード
  cv_tkn_nm_res2_cd         CONSTANT  VARCHAR2(100) := 'RES2_CODE';            --予備２コード
  --トークン値
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00088';     --要求ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00120';     --MIN日付
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00056';     --MAX日付
  cv_msg_vl_table_name1     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12806';     --販売実績明細テーブル名
  cv_msg_vl_table_name2     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12807';     --資材取引OIFテーブル名
  cv_msg_vl_table_name3     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12808';     --取引ソースタイプテーブル
  cv_msg_vl_table_name4     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12809';     --取引タイプテーブル
  cv_msg_vl_table_name5     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12801';--クイックコード(取引タイプ/仕訳パターン特定)
  cv_msg_vl_table_name6     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12804';--クイックコード(納品形態区分特定)
  cv_msg_vl_table_name7     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12810';--クイックコード(取引ソースタイプ特定)
  cv_msg_vl_dummy_cust      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12813';     --XXCOK:顧客コード_ダミー値
  cv_msg_vl_dummy_ent       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12814';     --XXCOK:企業コード_ダミー値
  cv_msg_vl_dummy_res1      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12815';     --XXCOK:予備１_ダミー値
  cv_msg_vl_dummy_res2      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12816';     --XXCOK:予備２_ダミー値
  --日付フォーマット
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) := 'YYYYMMDD';             --YYYYMMDD型
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD';           --YYYY/MM/DD型
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) := 'YYYY/MM';              --YYYY/MM型
  --クイックコード参照用
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y';       --使用可能フラグ
  cv_lang                   CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );               --言語
  cv_dlv_slp_cls_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_DLV_SLP_CLS_MST_013_A02';--納品伝票区分のクイックタイプ
  cv_dlv_slp_cls_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --納品伝票区分のクイックコード
  cv_dlv_ptn_cls_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_DLV_PTN_MST_013_A02';    --納品形態区分のクイックタイプ
  cv_dlv_ptn_cls_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --納品形態区分のクイックコード
  cv_dlv_ptn_dir_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02_02';              --工場直送のクイックコード
  cv_sale_cls_type          CONSTANT  VARCHAR2(100) := 'XXCOS1_SALE_CLASS_MST_013_A02'; --売上区分のクイックタイプ
  cv_sale_cls_code          CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --売上区分のクイックコード
  cv_no_inv_item_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';       --非在庫品目のクイックタイプ
  cv_txn_src_type           CONSTANT  VARCHAR2(100) := 'XXCOS1_TXN_SRC_MST_013_A02';--取引ソースタイプのクイックタイプ
  cv_txn_src_code           CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';            --取引ソースタイプのクイックコード
  cv_another_nm_code        CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02_02';          --勘定科目別名のクイックコード
  cv_txn_type_type          CONSTANT  VARCHAR2(100) := 'XXCOS1_TXN_TYPE_MST_013_A02';   --取引タイプのクイックタイプ
  cv_txn_type_code          CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --取引タイプのクイックコード
  cv_txn_jor_type           CONSTANT  VARCHAR2(100) := 'XXCOS1_INV_TXN_JOR_CLS_013_A02';--取引タイプ・仕訳パターン
  cv_red_black_type         CONSTANT  VARCHAR2(100) := 'XXCOS1_RED_BLACK_FLAG';         --赤黒フラグのクイックタイプ
  cv_goods_prod_type        CONSTANT  VARCHAR2(100) := 'XXCOS1_GOOD_PROD_CLS_013_A02';  --商品製品区分のクイックタイプ
  cv_goods_prod_code        CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --商品製品区分のクイックコード
  --プロファイル関連
  cv_prof_min_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MIN_DATE';      --プロファイル名(MIN日付)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MAX_DATE';      --プロファイル名(MAX日付)
  cv_prof_org               CONSTANT  VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';--プロファイル名(在庫組織コード)
  cv_prof_com_code          CONSTANT  VARCHAR2(100) := 'XXCOI1_COMPANY_CODE';     --プロファイル名(会社コード)
  cv_prof_cust_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';    -- 顧客コード_ダミー値
  cv_prof_ent_dummy         CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF6_COMPANY_DUMMY';     -- 企業コード_ダミー値
  cv_prof_res1_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';-- 予備1_ダミー値
  cv_prof_res2_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';-- 予備2_ダミー値
/* 2009/07/16 Ver1.7 Add Start */
  cv_prof_g_prd_class       CONSTANT  VARCHAR2(100) := 'XXCOI1_GOODS_PRODUCT_CLASS';    --商品製品区分カテゴリセット名
  --商品製品区分日付判定用
  cd_sysdate                CONSTANT  DATE          := SYSDATE;
/* 2009/07/16 Ver1.7 Add Start */
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
  cv_prof_bulk_count        CONSTANT  VARCHAR2(100) := 'XXCOS1_BULK_COLLECT_COUNT';     --結果セット取得件数（バルク）
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
  --カテゴリ／ステータス
  cv_inv_flg_n              CONSTANT  VARCHAR2(100) := 'N';                    --在庫未連携
  cv_inv_flg_y              CONSTANT  VARCHAR2(100) := 'Y';                    --在庫連携済
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
  cv_wan_data_flg           CONSTANT  VARCHAR2(1)   := 'W';                    --INV連携警告データ
  cv_excluded_flg           CONSTANT  VARCHAR2(1)   := 'S';                    --INV連携対象外
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
/* 2009/05/13 Ver1.5 Add Start */
  --商品製品区分
  cv_goods_prod_sei         CONSTANT  VARCHAR2(1)   := '2';  -- 品目区分：製品= 2
/* 2009/05/13 Ver1.5 Add End   */
--
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  cv_goods_prod_item        CONSTANT  VARCHAR2(1)   := '1';  -- 商品
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --販売実績データレコード型
  TYPE g_rec_sales_exp_rtype IS RECORD (
    line_id                     xxcos_sales_exp_lines.sales_exp_line_id%TYPE,            --販売実績明細ID
    dlv_date                    xxcos_sales_exp_headers.delivery_date%TYPE,              --納品日
    dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE,          --納品伝票区分
    sales_base_code             xxcos_sales_exp_headers.sales_base_code%TYPE,            --売上拠点コード
    dlv_pattern_class           xxcos_sales_exp_lines.delivery_pattern_class%TYPE,       --納品形態区分
    sales_class                 xxcos_sales_exp_lines.sales_class%TYPE,                  --売上区分
    red_black_flag              xxcos_sales_exp_lines.red_black_flag%TYPE,               --赤黒フラグ
    standard_uom_code           xxcos_sales_exp_lines.standard_uom_code%TYPE,            --基準単位
    standard_qty                xxcos_sales_exp_lines.standard_qty%TYPE,                 --基準数量
    shipment_from_code          xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE,  --出荷元保管場所
    inventory_item_id           xxcos_good_prod_class_v.inventory_item_id%TYPE,          --品目ID
    goods_prod_class            xxcos_good_prod_class_v.goods_prod_class_code%TYPE       --商品製品区分
  );
  --販売実績データコレクション型
  TYPE g_sales_exp_ttype IS TABLE OF g_rec_sales_exp_rtype INDEX BY BINARY_INTEGER;
  --取引ソースタイプレコード型
  TYPE g_rec_txn_src_type_rtype IS RECORD (
    txn_src_type_id             mtl_txn_source_types.transaction_source_type_id%TYPE,    --取引ソースタイプID
    txn_src_type_nm             mtl_txn_source_types.transaction_source_type_name%TYPE   --取引ソースタイプ名
  );
  --取引ソースタイプコレクション型
  TYPE g_txn_src_type_ttype IS TABLE OF g_rec_txn_src_type_rtype INDEX BY BINARY_INTEGER;
  --取引タイプレコード型
  TYPE g_rec_txn_type_rtype IS RECORD (
    txn_type_id                 mtl_transaction_types.transaction_type_id%TYPE,          --取引タイプID
    txn_type_nm                 mtl_transaction_types.transaction_type_name%TYPE         --取引タイプ名
  );
  --取引タイプコレクション型
  TYPE g_txn_type_ttype IS TABLE OF g_rec_txn_type_rtype INDEX BY BINARY_INTEGER;
  --取引タイプ／仕訳パターンマッピング表レコード型
  TYPE g_rec_jor_map_rtype IS RECORD (
    --入力部
    red_black_flg               xxcos_sales_exp_lines.red_black_flag%TYPE,               --赤黒フラグ
    dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE,          --納品伝票区分
    dlv_pattern_class           xxcos_sales_exp_lines.delivery_pattern_class%TYPE,       --納品形態区分
    sales_class                 xxcos_sales_exp_lines.sales_class%TYPE,                  --売上区分
    goods_prod_class            xxcos_good_prod_class_v.goods_prod_class_code%TYPE,      --商品製品区分
    --出力部
    txn_src_type                mtl_txn_source_types.transaction_source_type_name%TYPE,  --取引ソースタイプ
    txn_type                    mtl_transaction_types.transaction_type_name%TYPE,        --取引タイプ
    in_out_cls                  VARCHAR2(1),                                             --入出庫区分
    dept_code                   VARCHAR2(20),                                            --部門コード
    acc_item                    VARCHAR2(20),                                            --勘定科目コード
    ass_item                    VARCHAR2(20)                                             --補助科目コード
  );
  --取引タイプ／仕訳パターンマッピング表コレクション型
  TYPE g_jor_map_ttype IS TABLE OF g_rec_jor_map_rtype INDEX BY BINARY_INTEGER;
  --資材取引OIFレコード型
  TYPE g_rec_mtl_txn_oif_rtype IS RECORD (
    source_code                 mtl_transactions_interface.source_code%TYPE,             --ソースコード
    source_line_id              mtl_transactions_interface.source_line_id%TYPE,          --ソース明細ID
    source_header_id            mtl_transactions_interface.source_header_id%TYPE,        --ソースヘッダーID
    process_flag                mtl_transactions_interface.process_flag%TYPE,            --処理フラグ
    validation_required         mtl_transactions_interface.validation_required%TYPE,     --検証要
    transaction_mode            mtl_transactions_interface.transaction_mode%TYPE,        --取引モード
    inventory_item_id           mtl_transactions_interface.inventory_item_id%TYPE,       --取引品目ID
    organization_id             mtl_transactions_interface.organization_id%TYPE,         --取引元の組織ID
    transaction_quantity        mtl_transactions_interface.transaction_quantity%TYPE,    --取引数量
    transaction_uom             mtl_transactions_interface.transaction_uom%TYPE,         --取引単位
    transaction_date            mtl_transactions_interface.transaction_date%TYPE,        --取引発生日
    subinventory_code           mtl_transactions_interface.subinventory_code%TYPE,       --取引元の保管場所名
    transaction_source_id       mtl_transactions_interface.transaction_source_id%TYPE,   --取引ソースID
    transaction_source_type_id  mtl_transactions_interface.transaction_source_type_id%TYPE, --取引ソースタイプID
    transaction_type_id         mtl_transactions_interface.transaction_type_id%TYPE,     --取引タイプID
    scheduled_flag              mtl_transactions_interface.scheduled_flag%TYPE,          --計画フラグ
    flow_schedule               mtl_transactions_interface.flow_schedule%TYPE,           --計画フロー
    created_by                  mtl_transactions_interface.created_by%TYPE,              --作成者ID
    creation_date               mtl_transactions_interface.creation_date%TYPE,           --作成日
    last_updated_by             mtl_transactions_interface.last_updated_by%TYPE,         --最終更新者ID
    last_update_date            mtl_transactions_interface.last_update_date%TYPE,        --最終更新日
    last_update_login           mtl_transactions_interface.last_update_login%TYPE,       --最終ログインID
    request_id                  mtl_transactions_interface.request_id%TYPE,              --要求ID
    program_application_id      mtl_transactions_interface.program_application_id%TYPE,  --プログラムアプリケーションID
    program_id                  mtl_transactions_interface.program_id%TYPE,              --プログラムID
    program_update_date         mtl_transactions_interface.program_update_date%TYPE,     --プログラム更新日
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    sales_exp_line_id           xxcos_sales_exp_lines.sales_exp_line_id%TYPE,            --販売実績明細ID
    dept_code                   VARCHAR2(20)                                             --部門コード
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  );
  --資材取引OIFコレクション型
  TYPE g_mtl_txn_oif_ttype IS TABLE OF g_rec_mtl_txn_oif_rtype INDEX BY BINARY_INTEGER;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
  TYPE g_mtl_txn_oif_ttype_var IS TABLE OF g_rec_mtl_txn_oif_rtype INDEX BY VARCHAR(1000);
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  --勘定科目別名レコード型
  TYPE g_rec_disposition_rtype IS RECORD (
    org_id                  mtl_generic_dispositions.organization_id%TYPE,               --在庫組織ID
    dept_code               mtl_generic_dispositions.segment1%TYPE,                      --部門コード
    inv_acc_cls             mtl_generic_dispositions.segment2%TYPE,                      --入出庫勘定区分
    disposition_id          mtl_generic_dispositions.disposition_id%TYPE                 --勘定科目別名ID
  );
  --勘定科目別名コレクション型
  TYPE g_disposition_ttype IS TABLE OF g_rec_disposition_rtype INDEX BY BINARY_INTEGER;
  --勘定科目ID(CCID)レコード型
  TYPE g_rec_ccid_rtype IS RECORD (
    com_code                gl_code_combinations.segment1%TYPE,                          --会社コード
    dept_code               gl_code_combinations.segment2%TYPE,                          --部門コード
    acc_code                gl_code_combinations.segment3%TYPE,                          --勘定科目コード
    ass_code                gl_code_combinations.segment4%TYPE,                          --補助科目コード
    cust_code               gl_code_combinations.segment5%TYPE,                          --顧客コード
    ent_code                gl_code_combinations.segment6%TYPE,                          --企業コード
    res_code1               gl_code_combinations.segment7%TYPE,                          --予備１コード
    res_code2               gl_code_combinations.segment8%TYPE,                          --予備２コード
    ccid                    gl_code_combinations.code_combination_id%TYPE                --勘定科目ID(CCID)
  );
  --勘定科目ID(CCID)コレクション型
  TYPE g_ccid_ttype IS TABLE OF g_rec_ccid_rtype INDEX BY BINARY_INTEGER;
--************************************* 2009/08/25 N.Maeda Var1.10 ADD START *********************************************
  TYPE g_tab_sales_exp_line_id   IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;
  gt_sales_exp_line_id       g_tab_sales_exp_line_id;      -- 販売実績明細ID
--************************************* 2009/08/25 N.Maeda Var1.10 ADD  END  *********************************************
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_sales_exp_tab           g_sales_exp_ttype;                                  --販売実績データコレクション
  gd_proc_date              DATE;                                               --業務日付
  gd_min_date               DATE;                                               --MIN日付
  gd_max_date               DATE;                                               --MAX日付
  gt_org_id                 mtl_parameters.organization_id%TYPE;                --在庫組織ID
  gv_com_code               VARCHAR2(100);                                      --会社コード
  gv_cust_dummy             VARCHAR2(100);                                      --顧客コード(ダミー値)
  gv_ent_dummy              VARCHAR2(100);                                      --企業コード(ダミー値)
  gv_res1_dummy             VARCHAR2(100);                                      --予備１コード(ダミー値)
  gv_res2_dummy             VARCHAR2(100);                                      --予備２コード(ダミー値)
/* 2009/07/16 Ver1.7 Add Start */
  gt_category_set_id        mtl_category_sets_tl.category_set_id%TYPE;          --カテゴリセットID
/* 2009/07/16 Ver1.7 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  gt_category_id            mtl_categories_b.category_id%TYPE;  -- カテゴリID
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
  g_mtl_txn_oif_tab         g_mtl_txn_oif_ttype;                                --資材取引OIFコレクション
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
  g_mtl_txn_oif_tab_spare   g_mtl_txn_oif_ttype_var;
  g_mtl_txn_oif_ins_tab     g_mtl_txn_oif_ttype;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  g_disposition_tab         g_disposition_ttype;                                --勘定科目別名コレクション
  g_ccid_tab                g_ccid_ttype;                                       --勘定科目ID(CCID)コレクション
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD START ****************************************
  gn_bulk_size              NUMBER;                                             --最大フェッチ数
  gv_lock_retcode           VARCHAR2(1);                                        -- ロック処理リターン・コード
  -- 前回フェッチ最終のデータ
  gt_last_source_code                mtl_transactions_interface.source_code%TYPE;                --ソースコード
  gt_last_source_line_id             mtl_transactions_interface.source_line_id%TYPE;             --ソース明細ID
  gt_last_source_header_id           mtl_transactions_interface.source_header_id%TYPE;           --ソースヘッダーID
  gt_last_process_flag               mtl_transactions_interface.process_flag%TYPE;               --処理フラグ
  gt_last_validation_required        mtl_transactions_interface.validation_required%TYPE;        --検証要
  gt_last_transaction_mode           mtl_transactions_interface.transaction_mode%TYPE;           --取引モード
  gt_last_inventory_item_id          mtl_transactions_interface.inventory_item_id%TYPE;          --取引品目ID
  gt_last_organization_id            mtl_transactions_interface.organization_id%TYPE;            --取引元の組織ID
  gt_last_transaction_quantity       mtl_transactions_interface.transaction_quantity%TYPE;       --取引数量
  gt_last_transaction_uom            mtl_transactions_interface.transaction_uom%TYPE;            --取引単位
  gt_last_transaction_date           mtl_transactions_interface.transaction_date%TYPE;           --取引発生日
  gt_last_subinventory_code          mtl_transactions_interface.subinventory_code%TYPE;          --取引元の保管場所名
  gt_last_transaction_source_id      mtl_transactions_interface.transaction_source_id%TYPE;      --取引ソースID
  gt_last_tran_source_type_id        mtl_transactions_interface.transaction_source_type_id%TYPE; --取引ソースタイプID
  gt_last_transaction_type_id        mtl_transactions_interface.transaction_type_id%TYPE;        --取引タイプID
  gt_last_scheduled_flag             mtl_transactions_interface.scheduled_flag%TYPE;             --計画フラグ
  gt_last_flow_schedule              mtl_transactions_interface.flow_schedule%TYPE;              --計画フロー
  gt_last_created_by                 mtl_transactions_interface.created_by%TYPE;                 --作成者ID
  gt_last_creation_date              mtl_transactions_interface.creation_date%TYPE;              --作成日
  gt_last_last_updated_by            mtl_transactions_interface.last_updated_by%TYPE;            --最終更新者ID
  gt_last_last_update_date           mtl_transactions_interface.last_update_date%TYPE;           --最終更新日
  gt_last_last_update_login          mtl_transactions_interface.last_update_login%TYPE;          --最終ログインID
  gt_last_request_id                 mtl_transactions_interface.request_id%TYPE;                 --要求ID
  gt_last_program_application_id     mtl_transactions_interface.program_application_id%TYPE;     --プログラムアプリケーションID
  gt_last_program_id                 mtl_transactions_interface.program_id%TYPE;                 --プログラムID
  gt_last_program_update_date        mtl_transactions_interface.program_update_date%TYPE;        --プログラム更新日
  gt_last_dept_code                  VARCHAR2(20);                                               --部門コード
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ****************************************
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD START *********** --
    -- 対象データ取得
    CURSOR get_main_cur
    IS
    SELECT /*+
           INDEX(sel xxcos_sales_exp_lines_n03)
           INDEX(seh xxcos_sales_exp_headers_pk)
           INDEX(mcb mtl_categories_b_u1)
           LEADING(sel seh msib mic mcb)
           USE_NL(sel seh msib mic mcb)
           */
           sel.sales_exp_line_id line_id,         --販売実績明細ID
           seh.delivery_date,                     --納品日
           seh.dlv_invoice_class,                 --納品伝票区分
           seh.sales_base_code,                   --売上拠点コード
           sel.delivery_pattern_class,            --納品形態区分
           sel.sales_class,                       --売上区分
           sel.red_black_flag,                    --赤黒フラグ
           sel.standard_uom_code,                 --基準単位
           sel.standard_qty,                      --基準数量
           sel.ship_from_subinventory_code,       --出荷元保管場所
           msib.inventory_item_id,                --品目ID
           CASE
             WHEN 
               ( NOT EXISTS ( SELECT 1
                              FROM mtl_category_accounts mca
                              WHERE mca.category_id     = gt_category_id
                              AND mca.organization_id   = gt_org_id
                              AND mca.subinventory_code = sel.ship_from_subinventory_code
                              AND ROWNUM = 1 ) ) THEN  --専門店以外
               cv_goods_prod_sei  --製品固定
             ELSE
               mcb.segment1
           END
    FROM   xxcos_sales_exp_headers  seh,          --販売実績ヘッダテーブル
           xxcos_sales_exp_lines    sel,          --販売実績明細テーブル
           mtl_system_items_b     msib,  --品目マスタ
           mtl_item_categories    mic,   --品目カテゴリマスタ
           mtl_categories_b       mcb    --カテゴリマスタ
           --販売実績ヘッダ.ヘッダID=販売実績明細.ヘッダID
    WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id
           --納品日<=業務日付
    AND    seh.delivery_date       <= gd_proc_date
           --納品伝票区分 IN(納品,返品,納品訂正,返品訂正)
    AND    EXISTS(
             SELECT  /*+ USE_NL(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_dlv_slp_cls_type
             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
             AND     look_val.meaning            = seh.dlv_invoice_class
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
           --納品形態区分 IN(営業車,工場直送,メイン倉庫, 他倉庫,他拠点倉庫売上)
    AND    EXISTS(
             SELECT  /*+ USE_NL(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
             AND     look_val.meaning            = sel.delivery_pattern_class
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
           --非在庫品目を取除く
    AND    NOT EXISTS(
             SELECT  /*+ USE_NL(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_no_inv_item_type
             AND     look_val.lookup_code        = sel.item_code
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
           --INVインタフェース済フラグ(未連携orINV連携処理警告データ)
    AND    ( ( sel.inv_interface_flag = cv_inv_flg_n )
             OR ( sel.inv_interface_flag = cv_wan_data_flg ) )
    AND    msib.organization_id     = gt_org_id             -- 在庫組織ID
    AND    msib.segment1            = sel.item_code
    AND    msib.enabled_flag        = ct_enabled_flg_y      -- 品目マスタ有効フラグ
    AND    gd_proc_date
             BETWEEN NVL(msib.start_date_active, gd_proc_date)
             AND NVL(msib.end_date_active, gd_proc_date)
    AND    mic.organization_id      = msib.organization_id
    AND    mic.inventory_item_id    = msib.inventory_item_id
    AND    mic.category_set_id      = gt_category_set_id
    AND    mic.category_id          = mcb.category_id
    AND    ( mcb.disable_date IS NULL
           OR mcb.disable_date > gd_proc_date
           )
    AND    mcb.enabled_flag        = 'Y'      -- カテゴリ有効フラグ
    AND    gd_proc_date
             BETWEEN NVL(mcb.start_date_active, gd_proc_date)
             AND NVL(mcb.end_date_active, gd_proc_date)
    ORDER BY
           sel.ship_from_subinventory_code,     --出荷元保管場所
           msib.inventory_item_id,
           seh.delivery_date,                   --納品日
           seh.sales_base_code                  --売上拠点コード
    ;
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD  END  *********** --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
/* 2010/11/01 Ver1.13 Add Start */
    iv_night_mode       IN  VARCHAR2,     --   夜間起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
/* 2010/11/01 Ver1.13 Mod Start */
--    cv_msg_no_para  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- パラメータ無しメッセージ名
    cv_msg_param    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-12824';     -- パラメータ出力メッセージ
    cv_tkn_param1   CONSTANT VARCHAR2(6)   := 'PARAM1';               -- パラメータトークン1
/* 2010/11/01 Ver1.13 Mod End   */
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
--
    -- *** ローカル変数 ***
    lv_no_para_msg  VARCHAR2(5000);                         -- パラメータ無しメッセージ
    lv_date_item    VARCHAR2(100);                          -- MIN日付/MAX日付
    lv_dummy_item   VARCHAR2(100);                          -- CCID取得用ダミー項目
    lt_org_cd       mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    lv_msg_tkn      VARCHAR2(5000);                         -- メッセージ用トークン
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.パラメータ無しメッセージ出力処理
    --========================================
    lv_no_para_msg            :=  xxccp_common_pkg.get_msg(
/* 2010/11/01 Ver1.13 Mod Start */
--        iv_application        =>  cv_xxccp_short_name,
--        iv_name               =>  cv_msg_no_para
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_param,
        iv_token_name1        =>  cv_tkn_param1,
        iv_token_value1       =>  iv_night_mode
/* 2010/11/01 Ver1.13 Mod End   */
      );
    --メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_no_para_msg
    );
    --空行挿入(出力)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --空行挿入(ログ)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_no_para_msg
    );
    --空行挿入(ログ)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.MIN日付取得処理
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.MAX日付取得処理
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.在庫組織コード取得処理
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile_i,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.在庫組織ID取得処理
    --========================================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_cd );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_id_err,
        iv_token_name1        =>  cv_tkn_nm_org_cd,
        iv_token_value1       =>  lt_org_cd
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 7.会社コード取得処理
    --========================================
    gv_com_code := FND_PROFILE.VALUE( cv_prof_com_code );
    IF ( gv_com_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_com_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile_i,
        iv_token_value1       =>  cv_prof_com_code
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 8.顧客コード(ダミー値)取得処理
    --========================================
    gv_cust_dummy := FND_PROFILE.VALUE( cv_prof_cust_dummy );
    IF ( gv_cust_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_cust
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 9.企業コード(ダミー値)取得処理
    --========================================
    gv_ent_dummy := FND_PROFILE.VALUE( cv_prof_ent_dummy );
    IF ( gv_ent_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_ent
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 10.予備１コード(ダミー値)取得処理
    --========================================
    gv_res1_dummy := FND_PROFILE.VALUE( cv_prof_res1_dummy );
    IF ( gv_res1_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_res1
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 11.予備２コード(ダミー値)取得処理
    --========================================
    gv_res2_dummy := FND_PROFILE.VALUE( cv_prof_res2_dummy );
    IF ( gv_res2_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_res2
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2009/07/16 Ver1.7 Add Start */
    --========================================
    -- 12.カテゴリセットID取得処理
    --========================================
    BEGIN
      SELECT mcst.category_set_id
      INTO   gt_category_set_id
      FROM   mtl_category_sets_tl mcst
      WHERE  mcst.category_set_name = FND_PROFILE.VALUE( cv_prof_g_prd_class )
      AND    mcst.language          = cv_lang;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg               :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_category_err
        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2009/07/16 Ver1.7 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
--
    -- =======================================
    -- 13.カテゴリID取得
    -- =======================================
    BEGIN
      SELECT  mcb.category_id       category_id  -- カテゴリID
      INTO    gt_category_id
      FROM    mtl_category_sets_b   mcsb  -- カテゴリセットマスタ
              ,mtl_categories_b     mcb   -- カテゴリマスタ
      WHERE   mcsb.category_set_id = gt_category_set_id
      AND     mcsb.structure_id    = mcb.structure_id
      AND     mcb.segment1         = cv_goods_prod_item
      AND    (
              mcb.disable_date IS NULL
             OR
              mcb.disable_date > cd_sysdate
             )
      AND    mcb.enabled_flag        = ct_enabled_flg_y
      AND    cd_sysdate              BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
                                     AND     NVL( mcb.end_date_active, cd_sysdate );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg      :=  xxccp_common_pkg.get_msg(
                                   iv_application   =>  cv_xxcos_short_name,
                                   iv_name          =>  cv_msg_category_id
                                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    --========================================
    --14.結果セット取得件数（バルク）取得処理
    --========================================
    gn_bulk_size := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bulk_count ) );
    IF ( gn_bulk_size IS NULL ) THEN
      lv_msg_tkn              :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prf_bulk_cnt
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_msg_tkn
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_tkn_vl_table_name      VARCHAR2(100);      --エラー対象であるテーブル名
    lv_warnmsg                VARCHAR2(5000);     --ユーザー・警告・メッセージ
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    lt_line_id                xxcos_sales_exp_lines.sales_exp_line_id%TYPE;   --販売実績明細ID
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
   --対象データロック
   FOR i IN g_sales_exp_tab.FIRST .. g_sales_exp_tab.LAST LOOP
     --エラー時のキー情報出力のため、変数へ格納
     lt_line_id := g_sales_exp_tab(i).line_id;
     --ロック処理
     SELECT sel.sales_exp_line_id
     INTO   lt_line_id
     FROM   xxcos_sales_exp_lines    sel          --販売実績明細テーブル
     WHERE  sel.sales_exp_line_id = g_sales_exp_tab(i).line_id
     FOR UPDATE NOWAIT
     ;
   END LOOP;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ************************ 2009/08/06 1.18 N.Maeda MOD START *************************** --
----
--    --対象データ取得
--    SELECT /*+
--           index(sel XXCOS_SALES_EXP_LINES_N03)
--           index(seh XXCOS_SALES_EXP_HEADERS_PK)
--           index(mcb MTL_CATEGORIES_B_U1)
--           leading(sel seh msib mic mcb)
--           use_nl(sel seh msib mic mcb)
--           */
--           sel.sales_exp_line_id line_id,         --販売実績明細ID
--           seh.delivery_date,                     --納品日
--           seh.dlv_invoice_class,                 --納品伝票区分
--           seh.sales_base_code,                   --売上拠点コード
--           sel.delivery_pattern_class,            --納品形態区分
--           sel.sales_class,                       --売上区分
--           sel.red_black_flag,                    --赤黒フラグ
--           sel.standard_uom_code,                 --基準単位
--           sel.standard_qty,                      --基準数量
--           sel.ship_from_subinventory_code,       --出荷元保管場所
--           msib.inventory_item_id,                --品目ID
--           CASE
--             WHEN 
--               ( NOT EXISTS ( SELECT 1
--                              FROM mtl_category_accounts mca
--                              WHERE mca.category_id     = gt_category_id
--                              AND mca.organization_id   = gt_org_id
--                              AND mca.subinventory_code = sel.ship_from_subinventory_code
--                              AND ROWNUM = 1 ) ) THEN  --専門店以外
--               cv_goods_prod_sei  --製品固定
--             ELSE
--               mcb.segment1
--           END
--    BULK COLLECT INTO
--           g_sales_exp_tab
--    FROM   xxcos_sales_exp_headers  seh,          --販売実績ヘッダテーブル
--           xxcos_sales_exp_lines    sel,          --販売実績明細テーブル
--           mtl_system_items_b     msib,  --品目マスタ
--           mtl_item_categories    mic,   --品目カテゴリマスタ
--           mtl_categories_b       mcb    --カテゴリマスタ
--           --販売実績ヘッダ.ヘッダID=販売実績明細.ヘッダID
--    WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id
--           --納品日<=業務日付
--    AND    seh.delivery_date       <= gd_proc_date
--           --納品伝票区分 IN(納品,返品,納品訂正,返品訂正)
--    AND    EXISTS(
--             SELECT  /*+ use_nl(look_val) */
--                     'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_slp_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
--             AND     look_val.meaning            = seh.dlv_invoice_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--           --納品形態区分 IN(営業車,工場直送,メイン倉庫, 他倉庫,他拠点倉庫売上)
--    AND    EXISTS(
--             SELECT  /*+ use_nl(look_val) */
--                     'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
--             AND     look_val.meaning            = sel.delivery_pattern_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--           --非在庫品目を取除く
--    AND    NOT EXISTS(
--             SELECT  /*+ use_nl(look_val) */
--                     'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_no_inv_item_type
--             AND     look_val.lookup_code        = sel.item_code
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
---- ********** 2009/08/25 N.Maeda Var1.10 MOD START *********** --
--           --INVインタフェース済フラグ(未連携orINV連携処理警告データ)
--    AND    ( ( sel.inv_interface_flag = cv_inv_flg_n )
--             OR ( sel.inv_interface_flag = cv_wan_data_flg ) )
----           --INVインタフェース済フラグ(未連携)
----    AND    sel.inv_interface_flag       = cv_inv_flg_n
---- ********** 2009/08/25 N.Maeda Var1.10 MOD  END  *********** --
--    AND    msib.organization_id     = gt_org_id             -- 在庫組織ID
--    AND    msib.segment1            = sel.item_code
--    AND    msib.enabled_flag        = ct_enabled_flg_y      -- 品目マスタ有効フラグ
--    AND    gd_proc_date
--             BETWEEN NVL(msib.start_date_active, gd_proc_date)
--             AND NVL(msib.end_date_active, gd_proc_date)
--    AND    mic.organization_id      = msib.organization_id
--    AND    mic.inventory_item_id    = msib.inventory_item_id
--    AND    mic.category_set_id      = gt_category_set_id
--    AND    mic.category_id          = mcb.category_id
--    AND    ( mcb.disable_date IS NULL
--           OR mcb.disable_date > gd_proc_date
--           )
--    AND    mcb.enabled_flag        = 'Y'      -- カテゴリ有効フラグ
--    AND    gd_proc_date
--             BETWEEN NVL(mcb.start_date_active, gd_proc_date)
--             AND NVL(mcb.end_date_active, gd_proc_date)
--    ORDER BY
--           sel.ship_from_subinventory_code,     --出荷元保管場所
--           msib.inventory_item_id,
--           seh.delivery_date,                   --納品日
--           seh.sales_base_code                  --売上拠点コード
--    FOR UPDATE OF sel.sales_exp_line_id NOWAIT
--    ;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
--
--    --対象データ取得
--    SELECT sel.sales_exp_line_id line_id,         --販売実績明細ID
--           seh.delivery_date,                     --納品日
--           seh.dlv_invoice_class,                 --納品伝票区分
--           seh.sales_base_code,                   --売上拠点コード
--           sel.delivery_pattern_class,            --納品形態区分
--           sel.sales_class,                       --売上区分
--           sel.red_black_flag,                    --赤黒フラグ
--           sel.standard_uom_code,                 --基準単位
--           sel.standard_qty,                      --基準数量
--           sel.ship_from_subinventory_code,       --出荷元保管場所
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           msib.inventory_item_id,                --品目ID
--           CASE
--             WHEN 
--               ( ( SELECT COUNT('X') 
--                   FROM mtl_category_accounts mca
--                   WHERE mca.category_id     = gt_category_id
--                   AND mca.organization_id   = gt_org_id
--                   AND mca.subinventory_code = sel.ship_from_subinventory_code
--                   AND ROWNUM = 1
--                  ) = 0 ) THEN  --専門店以外
--               cv_goods_prod_sei  --製品固定
--             ELSE
--               mcb.segment1
--           END
----           gpcv.inventory_item_id,                --品目ID
----/* 2009/05/13 Ver1.5 Mod Start */
------           gpcv.goods_prod_class_code             --商品製品区分
----           CASE
----             WHEN mcavd.subinventory_code IS NULL THEN  --専門店以外
----               cv_goods_prod_sei  --製品固定
----             ELSE
----               gpcv.goods_prod_class_code
----           END
--/* 2009/05/13 Ver1.5 Mod End   */
--    BULK COLLECT INTO
--           g_sales_exp_tab
--    FROM   xxcos_sales_exp_headers  seh,          --販売実績ヘッダテーブル
--           xxcos_sales_exp_lines    sel,          --販売実績明細テーブル
--/* 2009/05/13 Ver1.5 Mod Start */
----           xxcos_good_prod_class_v  gpcv          --商品製品区分ビュー
--/* 2009/07/16 Ver1.7 Add Start */
----           xxcos_good_prod_class_v  gpcv,         --商品製品区分ビュー
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           mtl_system_items_b     msib,  --品目マスタ
--           mtl_item_categories    mic,   --品目カテゴリマスタ
--           mtl_categories_b       mcb    --カテゴリマスタ
----
----           ( SELECT msib.inventory_item_id inventory_item_id,
----                    msib.segment1          segment1,
----                    mcb.segment1           goods_prod_class_code
----             FROM   mtl_system_items_b     msib,  --品目マスタ
----                    mtl_item_categories    mic,   --品目カテゴリマスタ
----                    mtl_categories_b       mcb    --カテゴリマスタ
----             WHERE  msib.organization_id    = gt_org_id
----             AND    msib.enabled_flag       = ct_enabled_flg_y
----             AND    cd_sysdate              BETWEEN NVL( msib.start_date_active, cd_sysdate )
----                                            AND     NVL( msib.end_date_active, cd_sysdate)
----             AND    msib.organization_id    = mic.organization_id
----             AND    msib.inventory_item_id  = mic.inventory_item_id
----             AND    mic.category_set_id     = gt_category_set_id
----             AND    mic.category_id         = mcb.category_id
----             AND    (
----                      mcb.disable_date IS NULL
----                    OR
----                      mcb.disable_date > cd_sysdate
----                    )
----             AND    mcb.enabled_flag        = ct_enabled_flg_y
----             AND    cd_sysdate              BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
----                                            AND     NVL( mcb.end_date_active, cd_sysdate )
----           ) gpcv,                                --商品製品区分
---- ************ 2009/07/29 N.Maeda 1.8 MOD  END  *********************** --
--/* 2009/07/16 Ver1.7 Add End   */
--/* 2009/05/13 Ver1.5 Mod End   */
--/* 2009/05/13 Ver1.5 Add Start */
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----           ( SELECT DISTINCT
----/* 2009/07/16 Ver1.7 Add Start */
----                    mcav.organization_id     organization_id,
----/* 2009/07/16 Ver1.7 Add End   */
----                    mcav.subinventory_code   subinventory_code
----             FROM   mtl_category_accounts_v  mcav  -- 専門店View
----           )                        mcavd
----/* 2009/05/13 Ver1.5 Add End   */
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
--           --販売実績ヘッダ.ヘッダID=販売実績明細.ヘッダID
--    WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id
--           --納品日<=業務日付
--    AND    seh.delivery_date       <= gd_proc_date
--/* 2009/07/16 Ver1.7 Mod Start */
----           --納品伝票区分 IN(納品,返品,納品訂正,返品訂正)
----    AND    EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----             AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_dlv_slp_cls_type
----             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
----             AND     look_val.meaning            = seh.dlv_invoice_class
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
----           --納品形態区分 IN(営業車,工場直送,メイン倉庫, 他倉庫,他拠点倉庫売上)
----    AND    EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----             AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_dlv_ptn_cls_type
----             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
----             AND     look_val.meaning            = sel.delivery_pattern_class
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
----           --商品製品区分
----    AND    sel.item_code       = gpcv.segment1
----           --非在庫品目を取除く
----    AND    NOT EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----            AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_no_inv_item_type
----             AND     look_val.lookup_code        = sel.item_code
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
--           --納品伝票区分 IN(納品,返品,納品訂正,返品訂正)
--    AND    EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_slp_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
--             AND     look_val.meaning            = seh.dlv_invoice_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--           --納品形態区分 IN(営業車,工場直送,メイン倉庫, 他倉庫,他拠点倉庫売上)
--    AND    EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
--             AND     look_val.meaning            = sel.delivery_pattern_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----           --商品製品区分
----    AND    sel.item_code       = gpcv.segment1
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
--           --非在庫品目を取除く
--    AND    NOT EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_no_inv_item_type
--             AND     look_val.lookup_code        = sel.item_code
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--/* 2009/07/16 Ver1.7 Mod End   */
--           --INVインタフェース済フラグ(未連携)
--    AND    sel.inv_interface_flag       = cv_inv_flg_n
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----/* 2009/05/13 Ver1.5 Add Start */
----    AND    sel.ship_from_subinventory_code = mcavd.subinventory_code(+)
----/* 2009/05/13 Ver1.5 Add End   */
----/* 2009/07/16 Ver1.7 Add Start */
----    AND    gt_org_id                       = mcavd.organization_id(+)
----/* 2009/07/16 Ver1.7 Add End   */
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
---- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
--    AND    msib.organization_id     = gt_org_id             -- 在庫組織ID
--    AND    msib.segment1            = sel.item_code
--    AND    msib.enabled_flag        = ct_enabled_flg_y      -- 品目マスタ有効フラグ
--    AND    gd_proc_date
--             BETWEEN NVL(msib.start_date_active, gd_proc_date)
--             AND NVL(msib.end_date_active, gd_proc_date)
--    AND    mic.organization_id      = msib.organization_id
--    AND    mic.inventory_item_id    = msib.inventory_item_id
--    AND    mic.category_set_id      = gt_category_set_id
--    AND    mic.category_id          = mcb.category_id
--    AND    ( mcb.disable_date IS NULL
--           OR mcb.disable_date > gd_proc_date
--           )
--    AND    mcb.enabled_flag        = 'Y'      -- カテゴリ有効フラグ
--    AND    gd_proc_date
--             BETWEEN NVL(mcb.start_date_active, gd_proc_date)
--             AND NVL(mcb.end_date_active, gd_proc_date)
----
---- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
--    ORDER BY
--           sel.ship_from_subinventory_code,     --出荷元保管場所
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           msib.inventory_item_id,
----           gpcv.inventory_item_id,              --品目ID
---- ************ 2009/07/29 N.Maeda 1.8 MOD  END  *********************** --
--           seh.delivery_date,                   --納品日
----************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
--           seh.sales_base_code                  --売上拠点コード
----************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--    FOR UPDATE OF sel.sales_exp_line_id NOWAIT
--    ;
-- ************************ 2009/08/06 1.18 N.Maeda MOD  END  *************************** --
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
--    --処理件数カウント
--    gn_target_cnt := g_sales_exp_tab.COUNT;
----
--    --抽出データ件数0件、警告メッセージ出力
--    IF ( gn_target_cnt = 0 ) THEN
--      lv_warnmsg              :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_no_data_err
--      );
--      FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT
--       ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
--      );
--      --空行挿入
--      FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT
--       ,buff   => ''
--      );
--    END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
--      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_vl_table_name1
        iv_name               =>  cv_msg_sales_exp_target,
        iv_token_name1        =>  cv_tkn_nm_line_id,
        iv_token_value1       =>  TO_CHAR( lt_line_id )
      );
--      ov_errmsg               :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_lock_err,
--        iv_token_name1        =>  cv_tkn_nm_table_lock,
--        iv_token_value1       =>  lv_tkn_vl_table_name
--      );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Function Name    : get_disposition_id
   * Description      : 勘定科目別名ID取得(A-3_01)
   ***********************************************************************************/
  FUNCTION get_disposition_id(
    in_org_id           IN NUMBER,        --   在庫組織ID
    iv_dept_code        IN VARCHAR2,      --   部門コード
    iv_inv_acc_cls      IN VARCHAR2       --   入出庫勘定区分
    ) RETURN NUMBER                       --   勘定科目別名ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_disposition_id     mtl_generic_dispositions.disposition_id%TYPE;     --勘定科目別名ID
    ln_current_inx        NUMBER;                                           --カレントIndex
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    --該当勘定科目別名IDは既に取得されている場合、グローバルコレクションの検索へ
    IF ( g_disposition_tab.COUNT > 0 ) THEN
      <<ext_chk_loop>>
      FOR i IN g_disposition_tab.FIRST .. g_disposition_tab.LAST LOOP
        IF ( in_org_id      = g_disposition_tab(i).org_id      AND
             iv_dept_code   = g_disposition_tab(i).dept_code   AND
             iv_inv_acc_cls = g_disposition_tab(i).inv_acc_cls ) THEN
          RETURN g_disposition_tab(i).disposition_id;
        END IF;
      END LOOP ext_chk_loop;
    END IF;
    --該当勘定科目別名IDは取得されていない場合、DBの検索へ
    BEGIN
      SELECT  mgd.disposition_id     disposition_id                                   -- 勘定科目別名ID
      INTO    lt_disposition_id
      FROM    mtl_generic_dispositions mgd                                            -- 勘定科目別名テーブル
      WHERE   mgd.organization_id = in_org_id                                         -- 在庫組織ID
      AND     mgd.segment1        = iv_dept_code                                      -- 部門コード
      AND     mgd.segment2        = iv_inv_acc_cls                                    -- 入出庫勘定区分
      AND     gd_proc_date        >= NVL( mgd.effective_date, gd_min_date )
      AND     gd_proc_date        <= NVL( mgd.disable_date, gd_max_date )             -- 有効日無効日判定
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_disposition_id := NULL;
    END;
    ln_current_inx := g_disposition_tab.COUNT + 1;
    --DBから取得した勘定科目別名IDをグローバルコレクションに保持します。
    g_disposition_tab(ln_current_inx).org_id          := in_org_id;
    g_disposition_tab(ln_current_inx).dept_code       := iv_dept_code;
    g_disposition_tab(ln_current_inx).inv_acc_cls     := iv_inv_acc_cls;
    g_disposition_tab(ln_current_inx).disposition_id  := lt_disposition_id;
    RETURN lt_disposition_id;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  固定部 END   ##########################################
--
  END get_disposition_id;
--
  /**********************************************************************************
   * Function Name    : get_ccid
   * Description      : 勘定科目ID取得(A-3_02)
   ***********************************************************************************/
  FUNCTION get_ccid(
    iv_segment1           IN VARCHAR2,      --  会社コード
    iv_segment2           IN VARCHAR2,      --  部門コード
    iv_segment3           IN VARCHAR2,      --  勘定科目コード
    iv_segment4           IN VARCHAR2,      --  補助科目コード
    iv_segment5           IN VARCHAR2,      --  顧客コード
    iv_segment6           IN VARCHAR2,      --  企業コード
    iv_segment7           IN VARCHAR2,      --  予備１コード
    iv_segment8           IN VARCHAR2,      --  予備２コード
-- ********* 2009/08/24 1.9 N.Maeda ADD START ********* --
    id_dlv_date           IN DATE
-- ********* 2009/08/24 1.9 N.Maeda ADD  END  ********* --
    ) RETURN NUMBER                         --  勘定科目ID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ccid'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_ccid               mtl_generic_dispositions.disposition_id%TYPE;     --勘定科目ID(CCID)
    ln_current_inx        NUMBER;                                           --カレントIndex
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--
--###########################  固定部 END   ############################
--
    --該当勘定科目ID(CCID)は既に取得されている場合、グローバルコレクションの検索へ
    IF ( g_ccid_tab.COUNT > 0 ) THEN
      <<ext_chk_loop>>
      FOR i IN g_ccid_tab.FIRST .. g_ccid_tab.LAST LOOP
        IF ( iv_segment1 = g_ccid_tab(i).com_code     AND
             iv_segment2 = g_ccid_tab(i).dept_code    AND
             iv_segment3 = g_ccid_tab(i).acc_code     AND
             iv_segment4 = g_ccid_tab(i).ass_code     AND
             iv_segment5 = g_ccid_tab(i).cust_code    AND
             iv_segment6 = g_ccid_tab(i).ent_code     AND
             iv_segment7 = g_ccid_tab(i).res_code1    AND
             iv_segment8 = g_ccid_tab(i).res_code2 ) THEN
          RETURN g_ccid_tab(i).ccid;
        END IF;
      END LOOP ext_chk_loop;
    END IF;
    --該当勘定科目ID(CCID)は取得されていない場合、共通関数より取得。
    lt_ccid := xxcok_common_pkg.get_code_combination_id_f(
-- ********* 2009/08/24 1.9 N.Maeda MOD START ********* --
                                              id_dlv_date,    --納品日
--                                              gd_proc_date,   --処理日
-- ********* 2009/08/24 1.9 N.Maeda MOD  END  ********* --
                                              iv_segment1,    --会社コード
                                              iv_segment2,    --部門コード
                                              iv_segment3,    --勘定科目コード
                                              iv_segment4,    --補助科目コード
                                              iv_segment5,    --顧客コード
                                              iv_segment6,    --企業コード
                                              iv_segment7,    --予備１コード
                                              iv_segment8     --予備２コード
    );
    ln_current_inx := g_ccid_tab.COUNT + 1;
    --共通関数より取得した勘定科目IDをグローバルコレクションに保持します。
    g_ccid_tab(ln_current_inx).com_code       := iv_segment1;
    g_ccid_tab(ln_current_inx).dept_code      := iv_segment2;
    g_ccid_tab(ln_current_inx).acc_code       := iv_segment3;
    g_ccid_tab(ln_current_inx).ass_code       := iv_segment4;
    g_ccid_tab(ln_current_inx).cust_code      := iv_segment5;
    g_ccid_tab(ln_current_inx).ent_code       := iv_segment6;
    g_ccid_tab(ln_current_inx).res_code1      := iv_segment7;
    g_ccid_tab(ln_current_inx).res_code2      := iv_segment8;
    g_ccid_tab(ln_current_inx).ccid           := lt_ccid;
    RETURN lt_ccid;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  固定部 END   ##########################################
--
  END get_ccid;
--
  /**********************************************************************************
   * Procedure Name   : make_mtl_tran_data
   * Description      : 資材取引データ生成(A-3)
   ***********************************************************************************/
  PROCEDURE make_mtl_tran_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_mtl_tran_data'; -- プログラム名
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
    cv_in                        CONSTANT VARCHAR2(1)   := '0';                 --入庫区分
    cv_out                       CONSTANT VARCHAR2(1)   := '1';                 --出庫区分
    cv_null                      CONSTANT VARCHAR2(5)   := 'NULL';              --部門コード未設定
    cv_source_code               CONSTANT VARCHAR2(20)  := 'XXCOS013A02C';      --ソースコード
    cn_source_line_id            CONSTANT NUMBER        := 1;                   --ソース明細ID
    cn_source_header_id          CONSTANT NUMBER        := 1;                   --ソースヘッダーID
    cn_process_flag              CONSTANT NUMBER        := 1;                   --処理フラグ
    cn_valid_required            CONSTANT NUMBER        := 1;                   --検証要
    cn_transaction_mode          CONSTANT NUMBER        := 3;                   --取引モード
    cn_scheduled_flag            CONSTANT NUMBER        := 2;                   --計画フラグ
    cv_flow_schedule             CONSTANT VARCHAR2(1)   := 'Y';                 --計画フロー
    cn_make_rec_max              CONSTANT NUMBER        := 2;   --1件の販売実績ごとに生成される最大データ件数
    cv_inv_acc_dir               CONSTANT VARCHAR2(20)  := '03';                --入出庫勘定区分(工場直送入庫)
--
    -- *** ローカル変数 ***
    lv_tkn_vl_table_name         VARCHAR2(100);             --エラー対象であるテーブル名
    l_txn_src_type_tab           g_txn_src_type_ttype;      --取引ソースタイプコレクション
    l_txn_type_tab               g_txn_type_ttype;          --取引タイプコレクション
    l_jor_map_tab                g_jor_map_ttype;           --取引タイプ／仕訳パターンマッピング表コレクション(入出力)
    l_jor_out_tab                g_jor_map_ttype;           --取引タイプ／仕訳パターンマッピング表コレクション(出力)
    ln_jor_out_inx               NUMBER;                    --上記コレクションのIndex
    ln_mtl_txn_inx               NUMBER;                    --資材取引OIFコレクションのIndex
    ln_sign                      NUMBER;                    --符号
    lt_dept_code                 xxcos_sales_exp_headers.sales_base_code%TYPE;        --部門コード
    lt_dlv_ptn_dir               xxcos_sales_exp_lines.delivery_pattern_class%TYPE;   --納品形態区分(工場直送)
    lt_src_type_id               mtl_transactions_interface.transaction_source_type_id%TYPE;  --取引ソースタイプID
    lt_type_id                   mtl_transactions_interface.transaction_type_id%TYPE;         --取引タイプID
    lv_another_nm                VARCHAR2(100);                                         --勘定科目別名
    lt_disposition_id            mtl_generic_dispositions.disposition_id%TYPE;          --勘定科目別名ID
    lt_ccid                      mtl_generic_dispositions.disposition_id%TYPE;          --勘定科目ID(CCID)
    lv_warnmsg                   VARCHAR2(5000);                                        --ユーザー・警告・メッセージ
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    lv_idx_key                   VARCHAR2(1000);                                        -- PL/SQL表ソート用インデックス文字列
    ln_now_index                 VARCHAR2(1000);
    ln_smb_idx                   NUMBER DEFAULT 0;           -- 生成したインデックス
    ln_first_index               VARCHAR2(300);
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    ln_warn_cnt                  NUMBER DEFAULT 1;           --警告件数
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --資材取引OIFコレクションのIndexの初期化
    ln_mtl_txn_inx := 0;
    --取引ソースタイプマスタ情報取得処理
    SELECT mtst.transaction_source_type_id txn_src_type_id,     --取引ソースタイプID
           mtst.transaction_source_type_name txn_src_type_nm    --取引ソースタイプ名
    BULK COLLECT INTO
           l_txn_src_type_tab
    FROM   mtl_txn_source_types  mtst                           --取引ソースタイプテーブル
    WHERE  EXISTS(
/* 2009/07/16 Ver1.7 Mod Start */
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val,
--                     fnd_lookup_types_tl         types_tl,
--                     fnd_lookup_types            types,
--                     fnd_application_tl          appl,
--                     fnd_application             app
--             WHERE   appl.application_id         = types.application_id
--             AND     app.application_id          = appl.application_id
--             AND     types_tl.lookup_type        = look_val.lookup_type
--             AND     types.lookup_type           = types_tl.lookup_type
--             AND     types.security_group_id     = types_tl.security_group_id
--             AND     types.view_application_id   = types_tl.view_application_id
--             AND     types_tl.language           = cv_lang
--             AND     look_val.language           = cv_lang
--             AND     appl.language               = cv_lang
--             AND     app.application_short_name  = cv_xxcos_short_name
--             AND     look_val.lookup_type        = cv_txn_src_type
--             AND     look_val.lookup_code        LIKE cv_txn_src_code
--             AND     look_val.meaning            = mtst.transaction_source_type_name
--             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
             SELECT  'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_txn_src_type
             AND     look_val.lookup_code        LIKE cv_txn_src_code
             AND     look_val.meaning            = mtst.transaction_source_type_name
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
/* 2009/07/16 Ver1.7 Mod End   */
            )
            ;
    --取引ソースタイプマスタ情報取得失敗
    IF ( l_txn_src_type_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name3
      );
      RAISE global_data_select_expt;
    END IF;
--
    --取引タイプマスタ情報取得処理
    SELECT mtt.transaction_type_id txn_type_id,                 --取引タイプID
           mtt.transaction_type_name txn_type_nm                --取引タイプ名
    BULK COLLECT INTO
           l_txn_type_tab
    FROM   mtl_transaction_types  mtt                           --取引タイプテーブル
    WHERE  EXISTS(
/* 2009/07/16 Ver1.7 Mod Start */
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val,
--                     fnd_lookup_types_tl         types_tl,
--                     fnd_lookup_types            types,
--                     fnd_application_tl          appl,
--                     fnd_application             app
--             WHERE   appl.application_id         = types.application_id
--             AND     app.application_id          = appl.application_id
--             AND     types_tl.lookup_type        = look_val.lookup_type
--             AND     types.lookup_type           = types_tl.lookup_type
--             AND     types.security_group_id     = types_tl.security_group_id
--             AND     types.view_application_id   = types_tl.view_application_id
--             AND     types_tl.language           = cv_lang
--             AND     look_val.language           = cv_lang
--             AND     appl.language               = cv_lang
--             AND     app.application_short_name  = cv_xxcos_short_name
--             AND     look_val.lookup_type        = cv_txn_type_type
--             AND     look_val.lookup_code        LIKE cv_txn_type_code
--             AND     look_val.meaning            = mtt.transaction_type_name
--             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
             SELECT  'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_txn_type_type
             AND     look_val.lookup_code        LIKE cv_txn_type_code
             AND     look_val.language           = cv_lang
             AND     look_val.meaning            = mtt.transaction_type_name
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
/* 2009/07/16 Ver1.7 Mod End   */
            )
            ;
    --取引タイプマスタ情報取得失敗
    IF ( l_txn_type_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name4
      );
      RAISE global_data_select_expt;
    END IF;
--
    --取引タイプ／仕訳パターンマッピング表情報取得処理
    SELECT  look_val1.lookup_code        red_black_flg,      --赤黒フラグ
            look_val2.meaning            dlv_invoice_class,  --納品伝票区分
            look_val3.meaning            dlv_pattern_class,  --納品形態区分
            look_val4.meaning            sales_class,        --売上区分
            look_val5.meaning            goods_prod_class,   --商品製品区分
            look_val.attribute6          txn_src_type,       --取引ソースタイプ
            look_val.attribute7          txn_type,           --取引タイプ
            look_val.attribute11         in_out_cls,         --入出庫区分
            look_val.attribute8          dept_code,          --部門コード
            look_val.attribute9          acc_item,           --勘定科目コード
            look_val.attribute10         ass_item            --補助科目コード
    BULK COLLECT INTO
            l_jor_map_tab
/* 2009/07/16 Ver1.7 Mod Start */
--            --取引タイプ・仕訳パターン特定区分
--    FROM    fnd_lookup_values            look_val,
--            fnd_lookup_types_tl          types_tl,
--            fnd_lookup_types             types,
--            fnd_application_tl           appl,
--            fnd_application              app,
--            --赤黒フラグ
--            fnd_lookup_values            look_val1,
--            fnd_lookup_types_tl          types_tl1,
--            fnd_lookup_types             types1,
--            fnd_application_tl           appl1,
--            fnd_application              app1,
--            --納品伝票区分特定マスタ
--            fnd_lookup_values            look_val2,
--            fnd_lookup_types_tl          types_tl2,
--            fnd_lookup_types             types2,
--            fnd_application_tl           appl2,
--            fnd_application              app2,
--            --納品形態区分特定マスタ
--            fnd_lookup_values            look_val3,
--            fnd_lookup_types_tl          types_tl3,
--            fnd_lookup_types             types3,
--            fnd_application_tl           appl3,
--            fnd_application              app3,
--            --売上区分特定マスタ
--            fnd_lookup_values            look_val4,
--            fnd_lookup_types_tl          types_tl4,
--            fnd_lookup_types             types4,
--            fnd_application_tl           appl4,
--            fnd_application              app4,
--            --商品製品区分特定マスタ
--            fnd_lookup_values            look_val5,
--            fnd_lookup_types_tl          types_tl5,
--            fnd_lookup_types             types5,
--            fnd_application_tl           appl5,
--            fnd_application              app5
--    WHERE   appl.application_id          = types.application_id
--    AND     app.application_id           = appl.application_id
--    AND     types_tl.lookup_type         = look_val.lookup_type
--    AND     types.lookup_type            = types_tl.lookup_type
--    AND     types.security_group_id      = types_tl.security_group_id
--    AND     types.view_application_id    = types_tl.view_application_id
--    AND     types_tl.language            = cv_lang
--    AND     look_val.language            = cv_lang
--    AND     appl.language                = cv_lang
--    AND     app.application_short_name   = cv_xxcos_short_name
--    AND     look_val.lookup_type         = cv_txn_jor_type
--    AND     gd_proc_date                 >= NVL( look_val.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val.end_date_active, gd_max_date )
--    AND     look_val.enabled_flag        = ct_enabled_flg_y
--            --赤黒フラグ特定
--    AND     appl1.application_id         = types1.application_id
--    AND     app1.application_id          = appl1.application_id
--    AND     types_tl1.lookup_type        = look_val1.lookup_type
--    AND     types1.lookup_type           = types_tl1.lookup_type
--    AND     types1.security_group_id     = types_tl1.security_group_id
--    AND     types1.view_application_id   = types_tl1.view_application_id
--    AND     types_tl1.language           = cv_lang
--    AND     look_val1.language           = cv_lang
--    AND     appl1.language               = cv_lang
--    AND     app1.application_short_name  = cv_xxcos_short_name
--    AND     look_val1.lookup_type        = cv_red_black_type
--    AND     gd_proc_date                 >= NVL( look_val1.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val1.end_date_active, gd_max_date )
--    AND     look_val1.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute1          = look_val1.attribute1
--            --納品伝票区分特定
--    AND     appl2.application_id         = types2.application_id
--    AND     app2.application_id          = appl2.application_id
--    AND     types_tl2.lookup_type        = look_val2.lookup_type
--    AND     types2.lookup_type           = types_tl2.lookup_type
--    AND     types2.security_group_id     = types_tl2.security_group_id
--    AND     types2.view_application_id   = types_tl2.view_application_id
--    AND     types_tl2.language           = cv_lang
--    AND     look_val2.language           = cv_lang
--    AND     appl2.language               = cv_lang
--    AND     app2.application_short_name  = cv_xxcos_short_name
--    AND     look_val2.lookup_type        = cv_dlv_slp_cls_type
--    AND     look_val2.lookup_code        LIKE cv_dlv_slp_cls_code
--    AND     gd_proc_date                 >= NVL( look_val2.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val2.end_date_active, gd_max_date )
--    AND     look_val2.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute2          = look_val2.attribute1
--            --納品形態区分特定
--    AND     appl3.application_id         = types3.application_id
--    AND     app3.application_id          = appl3.application_id
--    AND     types_tl3.lookup_type        = look_val3.lookup_type
--    AND     types3.lookup_type           = types_tl3.lookup_type
--    AND     types3.security_group_id     = types_tl3.security_group_id
--    AND     types3.view_application_id   = types_tl3.view_application_id
--    AND     types_tl3.language           = cv_lang
--    AND     look_val3.language           = cv_lang
--    AND     appl3.language               = cv_lang
--    AND     app3.application_short_name  = cv_xxcos_short_name
--    AND     look_val3.lookup_type        = cv_dlv_ptn_cls_type
--    AND     look_val3.lookup_code        LIKE cv_dlv_ptn_cls_code
--    AND     gd_proc_date                 >= NVL( look_val3.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val3.end_date_active, gd_max_date )
--    AND     look_val3.enabled_flag       = ct_enabled_flg_y      
--    AND     look_val.attribute3          = look_val3.attribute1
--            --売上区分特定
--    AND     appl4.application_id         = types4.application_id
--    AND     app4.application_id          = appl4.application_id
--    AND     types_tl4.lookup_type        = look_val4.lookup_type
--    AND     types4.lookup_type           = types_tl4.lookup_type
--    AND     types4.security_group_id     = types_tl4.security_group_id
--    AND     types4.view_application_id   = types_tl4.view_application_id
--    AND     types_tl4.language           = cv_lang
--    AND     look_val4.language           = cv_lang
--    AND     appl4.language               = cv_lang
--    AND     app4.application_short_name  = cv_xxcos_short_name
--    AND     look_val4.lookup_type        = cv_sale_cls_type
--    AND     look_val4.lookup_code        LIKE cv_sale_cls_code
--    AND     gd_proc_date                 >= NVL( look_val4.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val4.end_date_active, gd_max_date )
--    AND     look_val4.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute4          = look_val4.attribute1
--            --商品製品区分特定
--    AND     appl5.application_id         = types5.application_id
--    AND     app5.application_id          = appl5.application_id
--    AND     types_tl5.lookup_type        = look_val5.lookup_type
--    AND     types5.lookup_type           = types_tl5.lookup_type
--    AND     types5.security_group_id     = types_tl5.security_group_id
--    AND     types5.view_application_id   = types_tl5.view_application_id
--    AND     types_tl5.language           = cv_lang
--    AND     look_val5.language           = cv_lang
--    AND     appl5.language               = cv_lang
--    AND     app5.application_short_name  = cv_xxcos_short_name
--    AND     look_val5.lookup_type        = cv_goods_prod_type
--    AND     look_val5.lookup_code        LIKE cv_goods_prod_code
--    AND     gd_proc_date                 >= NVL( look_val5.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val5.end_date_active, gd_max_date )
--    AND     look_val5.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute5          = look_val5.attribute1
            --取引タイプ・仕訳パターン特定区分
    FROM    fnd_lookup_values            look_val,
            --赤黒フラグ
            fnd_lookup_values            look_val1,
            --納品伝票区分特定マスタ
            fnd_lookup_values            look_val2,
            --納品形態区分特定マスタ
            fnd_lookup_values            look_val3,
            --売上区分特定マスタ
            fnd_lookup_values            look_val4,
            --商品製品区分特定マスタ
            fnd_lookup_values            look_val5
    WHERE   look_val.lookup_type         = cv_txn_jor_type
    AND     look_val.language            = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                         AND     NVL( look_val.end_date_active, gd_max_date )
    AND     look_val.enabled_flag        = ct_enabled_flg_y
            --赤黒フラグ特定
    AND     look_val1.lookup_type        = cv_red_black_type
    AND     look_val1.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val1.start_date_active, gd_min_date )
                                         AND     NVL( look_val1.end_date_active, gd_max_date )
    AND     look_val1.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute1          = look_val1.attribute1
            --納品伝票区分特定
    AND     look_val2.lookup_type        = cv_dlv_slp_cls_type
    AND     look_val2.lookup_code        LIKE cv_dlv_slp_cls_code
    AND     look_val2.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val2.start_date_active, gd_min_date )
                                         AND     NVL( look_val2.end_date_active, gd_max_date )
    AND     look_val2.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute2          = look_val2.attribute1
            --納品形態区分特定
    AND     look_val3.lookup_type        = cv_dlv_ptn_cls_type
    AND     look_val3.lookup_code        LIKE cv_dlv_ptn_cls_code
    AND     look_val3.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val3.start_date_active, gd_min_date )
                                         AND     NVL( look_val3.end_date_active, gd_max_date )
    AND     look_val3.enabled_flag       = ct_enabled_flg_y      
    AND     look_val.attribute3          = look_val3.attribute1
            --売上区分特定
    AND     look_val4.lookup_type        = cv_sale_cls_type
    AND     look_val4.lookup_code        LIKE cv_sale_cls_code
    AND     look_val4.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val4.start_date_active, gd_min_date )
                                         AND     NVL( look_val4.end_date_active, gd_max_date )
    AND     look_val4.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute4          = look_val4.attribute1
            --商品製品区分特定
    AND     look_val5.lookup_type        = cv_goods_prod_type
    AND     look_val5.lookup_code        LIKE cv_goods_prod_code
    AND     look_val5.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val5.start_date_active, gd_min_date )
                                         AND     NVL( look_val5.end_date_active, gd_max_date )
    AND     look_val5.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute5          = look_val5.attribute1
/* 2009/07/16 Ver1.7 Mod END   */
    ORDER BY
            look_val1.lookup_code        DESC,
            look_val2.meaning            ASC,
            look_val3.meaning            ASC,
            look_val4.meaning            ASC,
            look_val5.meaning            ASC
    ;
    --取引タイプ／仕訳パターンマッピング表情報取得失敗
    IF ( l_jor_map_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name5
      );
      RAISE global_data_select_expt;
    END IF;
--
    --納品形態区分(工場直送)の取得
    BEGIN
      SELECT  look_val.meaning            dlv_ptn_cls
      INTO    lt_dlv_ptn_dir
/* 2009/07/16 Ver1.7 Mod Start */
--      FROM    fnd_lookup_values           look_val,
--              fnd_lookup_types_tl         types_tl,
--              fnd_lookup_types            types,
--              fnd_application_tl          appl,
--              fnd_application             app
--      WHERE   appl.application_id         = types.application_id
--      AND     app.application_id          = appl.application_id
--      AND     types_tl.lookup_type        = look_val.lookup_type
--      AND     types.lookup_type           = types_tl.lookup_type
--      AND     types.security_group_id     = types_tl.security_group_id
--      AND     types.view_application_id   = types_tl.view_application_id
--      AND     types_tl.language           = cv_lang
--      AND     look_val.language           = cv_lang
--      AND     appl.language               = cv_lang
--      AND     app.application_short_name  = cv_xxcos_short_name
--      AND     look_val.lookup_type        = cv_dlv_ptn_cls_type
--      AND     look_val.lookup_code        = cv_dlv_ptn_dir_code
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
      AND     look_val.lookup_code        = cv_dlv_ptn_dir_code
      AND     look_val.language           = cv_lang
      AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                          AND     NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
/* 2009/07/16 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_table_name6
        );
        RAISE global_data_select_expt;
    END;
--
    --取引ソースタイプ(勘定科目別名)の取得
    BEGIN
      SELECT  look_val.meaning            another_name
      INTO    lv_another_nm
/* 2009/07/16 Ver1.7 Mod Start */
--      FROM    fnd_lookup_values           look_val,
--              fnd_lookup_types_tl         types_tl,
--              fnd_lookup_types            types,
--              fnd_application_tl          appl,
--              fnd_application             app
--      WHERE   appl.application_id         = types.application_id
--      AND     app.application_id          = appl.application_id
--      AND     types_tl.lookup_type        = look_val.lookup_type
--      AND     types.lookup_type           = types_tl.lookup_type
--      AND     types.security_group_id     = types_tl.security_group_id
--      AND     types.view_application_id   = types_tl.view_application_id
--      AND     types_tl.language           = cv_lang
--      AND     look_val.language           = cv_lang
--      AND     appl.language               = cv_lang
--      AND     app.application_short_name  = cv_xxcos_short_name
--      AND     look_val.lookup_type        = cv_txn_src_type
--      AND     look_val.lookup_code        = cv_another_nm_code
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.lookup_type        = cv_txn_src_type
      AND     look_val.lookup_code        = cv_another_nm_code
      AND     look_val.language           = cv_lang
      AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                          AND     NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
/* 2009/07/16 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_table_name7
        );
        RAISE global_data_select_expt;
    END;
--
    --資材取引データ生成処理
    <<make_data_main_loop>>
    FOR i IN g_sales_exp_tab.FIRST .. g_sales_exp_tab.LAST LOOP
      --取引タイプ／仕訳パターン出力用Indexのクリア
      ln_jor_out_inx := 0;
      --該当販売実績の取引タイプ／仕訳パターンの取得
      <<get_type_loop>>
      FOR j IN l_jor_map_tab.FIRST .. l_jor_map_tab.LAST LOOP
        IF ( g_sales_exp_tab(i).red_black_flag    = l_jor_map_tab(j).red_black_flg     AND  --赤黒フラグ
             g_sales_exp_tab(i).dlv_invoice_class = l_jor_map_tab(j).dlv_invoice_class AND  --納品伝票区分
             g_sales_exp_tab(i).dlv_pattern_class = l_jor_map_tab(j).dlv_pattern_class AND  --納品形態区分
             g_sales_exp_tab(i).sales_class       = l_jor_map_tab(j).sales_class       AND  --売上区分
             g_sales_exp_tab(i).goods_prod_class  = l_jor_map_tab(j).goods_prod_class       --商品製品区分
           ) THEN
          ln_jor_out_inx := ln_jor_out_inx + 1;
          l_jor_out_tab(ln_jor_out_inx).txn_src_type  := l_jor_map_tab(j).txn_src_type;     --取引ソースタイプ
          l_jor_out_tab(ln_jor_out_inx).txn_type      := l_jor_map_tab(j).txn_type;         --取引タイプ
          l_jor_out_tab(ln_jor_out_inx).in_out_cls    := l_jor_map_tab(j).in_out_cls;       --入出庫区分
          l_jor_out_tab(ln_jor_out_inx).dept_code     := l_jor_map_tab(j).dept_code;        --部門コード
          l_jor_out_tab(ln_jor_out_inx).acc_item      := l_jor_map_tab(j).acc_item;         --勘定科目コード
          l_jor_out_tab(ln_jor_out_inx).ass_item      := l_jor_map_tab(j).ass_item;         --補助科目コード
          --非工場直送1件または工場直送2件までループを抜け出す
          EXIT WHEN( g_sales_exp_tab(i).dlv_pattern_class <> lt_dlv_ptn_dir OR ln_jor_out_inx = cn_make_rec_max );
        END IF;
      END LOOP get_type_loop;
      --該当販売実績の取引タイプ／仕訳パターンが取得できない場合
      IF ( l_jor_out_tab.COUNT = 0 ) THEN
        --警告件数を計上します。
        gn_warn_cnt := gn_warn_cnt + 1;
        --警告メッセージを出力します。
        lv_warnmsg              :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_type_jor_err,
          iv_token_name1        =>  cv_tkn_nm_line_id,
          iv_token_value1       =>  g_sales_exp_tab(i).line_id,
          iv_token_name2        =>  cv_tkn_nm_red_blk,
          iv_token_value2       =>  g_sales_exp_tab(i).red_black_flag,
          iv_token_name3        =>  cv_tkn_nm_dlv_inv,
          iv_token_value3       =>  g_sales_exp_tab(i).dlv_invoice_class,
          iv_token_name4        =>  cv_tkn_nm_dlv_ptn,
          iv_token_value4       =>  g_sales_exp_tab(i).dlv_pattern_class,
          iv_token_name5        =>  cv_tkn_nm_sale_cls,
          iv_token_value5       =>  g_sales_exp_tab(i).sales_class,
          iv_token_name6        =>  cv_tkn_nm_item_cls,
          iv_token_value6       =>  g_sales_exp_tab(i).goods_prod_class
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
        );
        --空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
        );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
        gt_sales_exp_line_id( ln_warn_cnt ) := g_sales_exp_tab(i).line_id;
        ln_warn_cnt:=ln_warn_cnt+1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
        --該当販売実績データを処理しないので、コレクションから削除します。
        g_sales_exp_tab.DELETE( i );
      ELSE
        --資材取引データ生成
        <<make_data_sub_loop>>
        FOR k IN l_jor_out_tab.FIRST .. l_jor_out_tab.LAST LOOP
          ln_mtl_txn_inx := ln_mtl_txn_inx + 1;
          --ソースコード
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_code           := cv_source_code;
          --ソース明細ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_line_id        := cn_source_line_id;
          --ソースヘッダーID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_header_id      := cn_source_header_id;
          --処理フラグ
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).process_flag          := cn_process_flag;
          --検証要
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).validation_required   := cn_valid_required;
          --取引モード
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_mode      := cn_transaction_mode;
          --取引品目ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).inventory_item_id     := g_sales_exp_tab(i).inventory_item_id;
          --取引元の組織ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).organization_id       := gt_org_id;
          --取引数量(符号：入庫→＋ 出庫→－)
          IF ( l_jor_out_tab(k).in_out_cls = cv_in ) THEN
            ln_sign := 1;
          ELSE
            ln_sign := -1;
          END IF;
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_quantity  := ABS( g_sales_exp_tab(i).standard_qty ) * ln_sign;
          --取引単位
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_uom       := g_sales_exp_tab(i).standard_uom_code;
          --取引発生日
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_date      := g_sales_exp_tab(i).dlv_date;
          --取引元の保管場所名
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).subinventory_code     := g_sales_exp_tab(i).shipment_from_code;
          --部門コード取得
          IF ( l_jor_out_tab(k).dept_code = cv_null ) THEN
            lt_dept_code := g_sales_exp_tab(i).sales_base_code;
          ELSE
            lt_dept_code := l_jor_out_tab(k).dept_code;
          END IF;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).sales_exp_line_id     := g_sales_exp_tab(i).line_id;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
          --勘定科目情報取得
          IF ( l_jor_out_tab(k).txn_src_type = lv_another_nm ) THEN
            --勘定科目別名ID取得
            lt_disposition_id := get_disposition_id( gt_org_id, lt_dept_code, cv_inv_acc_dir );
            IF ( lt_disposition_id IS NULL ) THEN
              --処理済のデータをリカバリします。
              <<rec1_loop>>
              FOR n IN l_jor_out_tab.FIRST .. k LOOP
                g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
                ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
              END LOOP rec1_loop;
              --警告件数を計上します。
              gn_warn_cnt := gn_warn_cnt + 1;
              --警告メッセージを出力します。
              lv_warnmsg              :=  xxccp_common_pkg.get_msg(
                iv_application        =>  cv_xxcos_short_name,
                iv_name               =>  cv_msg_dispt_err,
                iv_token_name1        =>  cv_tkn_nm_line_id,
                iv_token_value1       =>  g_sales_exp_tab(i).line_id,
                iv_token_name2        =>  cv_tkn_nm_org_id,
                iv_token_value2       =>  gt_org_id,
                iv_token_name3        =>  cv_tkn_nm_dept_cd,
                iv_token_value3       =>  lt_dept_code,
                iv_token_name4        =>  cv_tkn_nm_inv_acc,
                iv_token_value4       =>  cv_inv_acc_dir
              );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
              );
              --空行挿入
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => ''
              );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
        gt_sales_exp_line_id( ln_warn_cnt ) := g_sales_exp_tab(i).line_id;
        ln_warn_cnt:=ln_warn_cnt+1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
              --該当販売実績データを処理しないので、コレクションから削除します。
              g_sales_exp_tab.DELETE( i );
              --当ループ中止
              EXIT;
            END IF;
            --取引ソースID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_id := lt_disposition_id;
          ELSE
            --勘定科目ID(CCID)取得
            lt_ccid := get_ccid( gv_com_code,
                                 lt_dept_code,
                                 l_jor_out_tab(k).acc_item,
                                 l_jor_out_tab(k).ass_item,
                                 gv_cust_dummy,
                                 gv_ent_dummy,
                                 gv_res1_dummy,
                                 gv_res2_dummy,
-- ********* 2009/08/24 1.9 N.Maeda ADD START ********* --
                                 g_sales_exp_tab(i).dlv_date
-- ********* 2009/08/24 1.9 N.Maeda ADD  END  ********* --
                                 );
            IF ( lt_ccid IS NULL ) THEN
              --処理済のデータをリカバリします。
              <<rec2_loop>>
              FOR n IN l_jor_out_tab.FIRST .. k LOOP
                g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
                ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
              END LOOP rec2_loop;
              --警告件数を計上します。
              gn_warn_cnt := gn_warn_cnt + 1;
              --警告メッセージを出力します。
              lv_warnmsg              :=  xxccp_common_pkg.get_msg(
                iv_application        =>  cv_xxcos_short_name,
                iv_name               =>  cv_msg_ccid_err,
                iv_token_name1        =>  cv_tkn_nm_line_id,
                iv_token_value1       =>  g_sales_exp_tab(i).line_id,
                iv_token_name2        =>  cv_tkn_nm_com_cd,
                iv_token_value2       =>  gv_com_code,
                iv_token_name3        =>  cv_tkn_nm_dept_cd,
                iv_token_value3       =>  lt_dept_code,
                iv_token_name4        =>  cv_tkn_nm_acc_cd,
                iv_token_value4       =>  l_jor_out_tab(k).acc_item,
                iv_token_name5        =>  cv_tkn_nm_ass_cd,
                iv_token_value5       =>  l_jor_out_tab(k).ass_item,
                iv_token_name6        =>  cv_tkn_nm_cust_cd,
                iv_token_value6       =>  gv_cust_dummy,
                iv_token_name7        =>  cv_tkn_nm_ent_cd,
                iv_token_value7       =>  gv_ent_dummy,
                iv_token_name8        =>  cv_tkn_nm_res1_cd,
                iv_token_value8       =>  gv_res1_dummy,
                iv_token_name9        =>  cv_tkn_nm_res2_cd,
                iv_token_value9       =>  gv_res2_dummy
              );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
              );
              --空行挿入
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => ''
              );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
        gt_sales_exp_line_id( ln_warn_cnt ) := g_sales_exp_tab(i).line_id;
        ln_warn_cnt:=ln_warn_cnt+1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
              --該当販売実績データを処理しないので、コレクションから削除します。
              g_sales_exp_tab.DELETE( i );
              --当ループ中止
              EXIT;
            END IF;
            --取引ソースID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_id := lt_ccid;
          END IF;
          --取引ソースタイプIDの取得
          lt_src_type_id := NULL;
          <<sch_src_type_loop>>
          FOR l IN l_txn_src_type_tab.FIRST .. l_txn_src_type_tab.LAST LOOP
            IF ( l_jor_out_tab(k).txn_src_type = l_txn_src_type_tab(l).txn_src_type_nm ) THEN
              lt_src_type_id := l_txn_src_type_tab(l).txn_src_type_id;
              EXIT;
            END IF;
          END LOOP sch_src_type_loop;
          IF ( lt_src_type_id IS NULL ) THEN
            --処理済のデータをリカバリします。
            <<rec3_loop>>
            FOR n IN l_jor_out_tab.FIRST .. k LOOP
              g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
              ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
            END LOOP rec3_loop;
            --警告件数を計上します。
            gn_warn_cnt := gn_warn_cnt + 1;
            --警告メッセージを出力します。
            lv_warnmsg              :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_src_type_err,
              iv_token_name1        =>  cv_tkn_nm_line_id,
              iv_token_value1       =>  g_sales_exp_tab(i).line_id,
              iv_token_name2        =>  cv_tkn_nm_src_type,
              iv_token_value2       =>  l_jor_out_tab(k).txn_src_type
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
            );
            --空行挿入
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
        gt_sales_exp_line_id( ln_warn_cnt ) := g_sales_exp_tab(i).line_id;
        ln_warn_cnt:=ln_warn_cnt+1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
            --該当販売実績データを処理しないので、コレクションから削除します。
            g_sales_exp_tab.DELETE( i );
            --当ループ中止
            EXIT;
          END IF;
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_type_id  := lt_src_type_id;
          --取引タイプIDの取得
          lt_type_id := NULL;
          <<sch_type_loop>>
          FOR m IN l_txn_type_tab.FIRST .. l_txn_type_tab.LAST LOOP
            IF ( l_jor_out_tab(k).txn_type = l_txn_type_tab(m).txn_type_nm ) THEN
              lt_type_id := l_txn_type_tab(m).txn_type_id;
              EXIT;
            END IF;
          END LOOP sch_type_loop;
          IF ( lt_type_id IS NULL ) THEN
            --処理済のデータをリカバリします。
            <<rec4_loop>>
            FOR n IN l_jor_out_tab.FIRST .. k LOOP
              g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
              ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
            END LOOP rec4_loop;
            --警告件数を計上します。
            gn_warn_cnt := gn_warn_cnt + 1;
            --警告メッセージを出力します。
            lv_warnmsg              :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_type_err,
              iv_token_name1        =>  cv_tkn_nm_line_id,
              iv_token_value1       =>  g_sales_exp_tab(i).line_id,
              iv_token_name2        =>  cv_tkn_nm_type,
              iv_token_value2       =>  l_jor_out_tab(k).txn_type
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
            );
            --空行挿入
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
            --該当販売実績データを処理しないので、コレクションから削除します。
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
        gt_sales_exp_line_id( ln_warn_cnt ) := g_sales_exp_tab(i).line_id;
        ln_warn_cnt:=ln_warn_cnt+1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
            g_sales_exp_tab.DELETE( i );
            --当ループ中止
            EXIT;
          END IF;
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_type_id     := lt_type_id;
            --計画フラグ
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).scheduled_flag          := cn_scheduled_flag;
            --計画フロー
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).flow_schedule           := cv_flow_schedule;
            --作成者ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).created_by              := cn_created_by;
            --作成日
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).creation_date           := cd_creation_date;
            --最終更新者ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_updated_by         := cn_last_updated_by;
            --最終更新日
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_update_date        := cd_last_update_date;
            --最終ログインID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_update_login       := cn_last_update_login;
            --要求ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).request_id              := cn_request_id;
            --プログラムアプリケーションID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_application_id  := cn_program_application_id;
            --プログラムID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_id              := cn_program_id;
            --プログラム更新日
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_update_date     := cd_program_update_date;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
            --部門コード
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).dept_code               := lt_dept_code;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
        END LOOP make_data_sub_loop;
        --該当販売実績の取引タイプ／仕訳パターン情報のクリア
        l_jor_out_tab.DELETE;
      END IF;
    END LOOP make_data_main_loop;
--
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    --テーブルソート
    <<loop_make_sort_data>>
    FOR s IN 1..g_mtl_txn_oif_tab.COUNT LOOP
      --ソートキーは保管場所、品目ID、取引日、部門コード、販売実績明細ID
      lv_idx_key := g_mtl_txn_oif_tab(s).subinventory_code
                    || g_mtl_txn_oif_tab(s).inventory_item_id
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
--                    || g_mtl_txn_oif_tab(s).transaction_date
                    || TO_CHAR( g_mtl_txn_oif_tab(s).transaction_date, 'yyyymmdd' )
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
                    || g_mtl_txn_oif_tab(s).dept_code
                    || g_mtl_txn_oif_tab(s).sales_exp_line_id;
      g_mtl_txn_oif_tab_spare(lv_idx_key) := g_mtl_txn_oif_tab(s);
    END LOOP loop_make_sort_data;
--
    IF g_mtl_txn_oif_tab_spare.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_mtl_txn_oif_tab_spare.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      ln_smb_idx := ln_smb_idx + 1;
      g_mtl_txn_oif_ins_tab(ln_smb_idx) := g_mtl_txn_oif_tab_spare(ln_now_index);
      -- 次のインデックスを取得する
      ln_now_index := g_mtl_txn_oif_tab_spare.next(ln_now_index);
--
    END LOOP;--ソート完了--
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--
  EXCEPTION
    --*** データ抽出例外ハンドラ ***
    WHEN global_data_select_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_select_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_mtl_tran_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_mtl_tran_oif
   * Description      : 資材取引OIF出力(A-4)
   ***********************************************************************************/
  PROCEDURE insert_mtl_tran_oif(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_mtl_tran_oif'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lt_subinventory              mtl_transactions_interface.subinventory_code%TYPE;   --取引元の保管場所(ブレークキー)
    lt_item_id                   mtl_transactions_interface.inventory_item_id%TYPE;   --取引品目ID(ブレークキー)
    lt_txn_date                  mtl_transactions_interface.transaction_date%TYPE;    --取引発生日(ブレークキー)
    lt_type_id                   mtl_transactions_interface.transaction_type_id%TYPE; --取引タイプID
    ln_break_start               NUMBER;                                              --集約ブレーク開始
    ln_break_end                 NUMBER;                                              --集約ブレーク終了
    lv_tkn_vl_table_name         VARCHAR2(100);                                       --エラー対象であるテーブル名
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    lt_dept_code                 VARCHAR2(20);                                        --部門コード
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD START ****************************************
    ln_last_data                 NUMBER;                                              --最終集計データの索引番号
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ****************************************
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --ブレークキー初期化
--************************************* 2009/09/14 S.Miyakoshi Var1.11 MOD START ****************************************
    lt_subinventory := g_mtl_txn_oif_ins_tab(1).subinventory_code;
    lt_item_id      := g_mtl_txn_oif_ins_tab(1).inventory_item_id;
    lt_txn_date     := g_mtl_txn_oif_ins_tab(1).transaction_date;
    lt_dept_code    := g_mtl_txn_oif_ins_tab(1).dept_code;
--    lt_subinventory := g_mtl_txn_oif_tab(1).subinventory_code;
--    lt_item_id      := g_mtl_txn_oif_tab(1).inventory_item_id;
--    lt_txn_date     := g_mtl_txn_oif_tab(1).transaction_date;
----************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
--    lt_dept_code    := g_mtl_txn_oif_tab(1).dept_code;
----************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--************************************* 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ****************************************
    ln_break_start  := 1;
    ln_break_end    := 1;
--
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD START ****************************************
    --前回フェッチ最終データの集約
    IF ( lt_subinventory = gt_last_subinventory_code AND
         lt_item_id      = gt_last_inventory_item_id AND
         lt_txn_date     = gt_last_transaction_date  AND
         lt_dept_code    = gt_last_dept_code         AND
         g_mtl_txn_oif_ins_tab(1).transaction_type_id = gt_last_transaction_type_id ) THEN
      --取引数量の集約
      g_mtl_txn_oif_ins_tab(1).transaction_quantity := g_mtl_txn_oif_ins_tab(1).transaction_quantity + gt_last_transaction_quantity;
      --前回データの初期化
      gt_last_dept_code := NULL;
    END IF;
--************************************* 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ****************************************
--
    --資材取引OIFデータの集約処理
    <<sum_main_loop>>
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--    FOR i IN 1 .. g_mtl_txn_oif_tab.LAST LOOP
--      --取引元の保管場所、取引品目ID、取引発生日でブレーク
--      IF ( lt_subinventory = g_mtl_txn_oif_tab(i).subinventory_code AND
--           lt_item_id      = g_mtl_txn_oif_tab(i).inventory_item_id AND
--           lt_txn_date     = g_mtl_txn_oif_tab(i).transaction_date ) THEN
    FOR i IN g_mtl_txn_oif_ins_tab.FIRST .. g_mtl_txn_oif_ins_tab.LAST LOOP
      --取引元の保管場所、取引品目ID、取引発生日、部門コードでブレーク
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
      IF ( ( lt_subinventory = g_mtl_txn_oif_ins_tab(i).subinventory_code AND
             lt_item_id      = g_mtl_txn_oif_ins_tab(i).inventory_item_id AND
             lt_txn_date     = g_mtl_txn_oif_ins_tab(i).transaction_date  AND
             lt_dept_code    = g_mtl_txn_oif_ins_tab(i).dept_code )
           OR
           ( i = g_mtl_txn_oif_ins_tab.LAST ) ) THEN
--      IF ( lt_subinventory = g_mtl_txn_oif_ins_tab(i).subinventory_code AND
--           lt_item_id      = g_mtl_txn_oif_ins_tab(i).inventory_item_id AND
--           lt_txn_date     = g_mtl_txn_oif_ins_tab(i).transaction_date  AND
--           lt_dept_code    = g_mtl_txn_oif_ins_tab(i).dept_code ) THEN
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
--
--        --ブレーク終了まで、Indexを保持
--        ln_break_end := i;
--        --最後のブレーク
--        IF ( i = g_mtl_txn_oif_tab.LAST ) THEN
--          <<last_same_break_loop>>
--          FOR j IN ln_break_start .. ln_break_end LOOP
--            --当レコードが削除されていなければ、集計される対象となります。
--            IF ( g_mtl_txn_oif_tab.EXISTS( j ) ) THEN
--              --ブレーク内で同じ取引タイプIDの取引数量を計上します。
--              <<last_sum_sub_loop>>
--              FOR k IN ( j + 1 ) .. ln_break_end LOOP
--                IF ( g_mtl_txn_oif_tab.EXISTS( k ) AND 
--                     g_mtl_txn_oif_tab(k).transaction_type_id = g_mtl_txn_oif_tab(j).transaction_type_id ) THEN
--                  g_mtl_txn_oif_tab(j).transaction_quantity := g_mtl_txn_oif_tab(j).transaction_quantity +
--                                                               g_mtl_txn_oif_tab(k).transaction_quantity;
--                  --計上されたため、削除します。
--                  g_mtl_txn_oif_tab.DELETE( k );
--                END IF;
--              END LOOP last_sum_sub_loop;
--            END IF;
--          END LOOP last_same_break_loop;
--        END IF;
--      ELSE
--        --今回のブレーク内で集計
--        <<same_break_loop>>
--        FOR j IN ln_break_start .. ln_break_end LOOP
--          --当レコードが削除されていなければ、集計される対象となります。
--          IF ( g_mtl_txn_oif_tab.EXISTS( j ) ) THEN
--            --ブレーク内で同じ取引タイプIDの取引数量を計上します。
--            <<sum_sub_loop>>
--            FOR k IN ( j + 1 ) .. ln_break_end LOOP
--              IF ( g_mtl_txn_oif_tab.EXISTS( k ) AND 
--                   g_mtl_txn_oif_tab(k).transaction_type_id = g_mtl_txn_oif_tab(j).transaction_type_id ) THEN
--                g_mtl_txn_oif_tab(j).transaction_quantity := g_mtl_txn_oif_tab(j).transaction_quantity +
--                                                             g_mtl_txn_oif_tab(k).transaction_quantity;
--                --計上されたため、削除します。
--                g_mtl_txn_oif_tab.DELETE( k );
--              END IF;
--            END LOOP sum_sub_loop;
--          END IF;
--        END LOOP same_break_loop;
--        --次のブレークキーを設定します。
--        lt_subinventory := g_mtl_txn_oif_tab(i).subinventory_code;
--        lt_item_id      := g_mtl_txn_oif_tab(i).inventory_item_id;
--        lt_txn_date     := g_mtl_txn_oif_tab(i).transaction_date;
        --ブレーク終了まで、Indexを保持
        ln_break_end := i;
        --最後のブレーク
        IF ( i = g_mtl_txn_oif_ins_tab.LAST ) THEN
--************************************* 2009/09/14 S.Miyakoshi Var1.11 MOD START ****************************************
          --前回フェッチ最終分の登録データ作成
          IF ( gt_last_dept_code IS NOT NULL ) THEN
            g_mtl_txn_oif_ins_tab(i+1).source_code                := gt_last_source_code;                  --ソースコード
            g_mtl_txn_oif_ins_tab(i+1).source_line_id             := gt_last_source_line_id;               --ソース明細ID
            g_mtl_txn_oif_ins_tab(i+1).source_header_id           := gt_last_source_header_id;             --ソースヘッダーID
            g_mtl_txn_oif_ins_tab(i+1).process_flag               := gt_last_process_flag;                 --処理フラグ
            g_mtl_txn_oif_ins_tab(i+1).validation_required        := gt_last_validation_required;          --検証要
            g_mtl_txn_oif_ins_tab(i+1).transaction_mode           := gt_last_transaction_mode;             --取引モード
            g_mtl_txn_oif_ins_tab(i+1).inventory_item_id          := gt_last_inventory_item_id;            --取引品目ID
            g_mtl_txn_oif_ins_tab(i+1).organization_id            := gt_last_organization_id;              --取引元の組織ID
            g_mtl_txn_oif_ins_tab(i+1).transaction_quantity       := gt_last_transaction_quantity;         --取引数量
            g_mtl_txn_oif_ins_tab(i+1).transaction_uom            := gt_last_transaction_uom;              --取引単位
            g_mtl_txn_oif_ins_tab(i+1).transaction_date           := gt_last_transaction_date;             --取引発生日
            g_mtl_txn_oif_ins_tab(i+1).subinventory_code          := gt_last_subinventory_code;            --取引元の保管場所名
            g_mtl_txn_oif_ins_tab(i+1).transaction_source_id      := gt_last_transaction_source_id;        --取引ソースID
            g_mtl_txn_oif_ins_tab(i+1).transaction_source_type_id := gt_last_tran_source_type_id;          --取引ソースタイプID
            g_mtl_txn_oif_ins_tab(i+1).transaction_type_id        := gt_last_transaction_type_id;          --取引タイプID
            g_mtl_txn_oif_ins_tab(i+1).scheduled_flag             := gt_last_scheduled_flag;               --計画フラグ
            g_mtl_txn_oif_ins_tab(i+1).flow_schedule              := gt_last_flow_schedule;                --計画フロー
            g_mtl_txn_oif_ins_tab(i+1).created_by                 := gt_last_created_by;                   --作成者ID
            g_mtl_txn_oif_ins_tab(i+1).creation_date              := gt_last_creation_date;                --作成日
            g_mtl_txn_oif_ins_tab(i+1).last_updated_by            := gt_last_last_updated_by;              --最終更新者ID
            g_mtl_txn_oif_ins_tab(i+1).last_update_date           := gt_last_last_update_date;             --最終更新日
            g_mtl_txn_oif_ins_tab(i+1).last_update_login          := gt_last_last_update_login;            --最終ログインID
            g_mtl_txn_oif_ins_tab(i+1).request_id                 := gt_last_request_id;                   --要求ID
            g_mtl_txn_oif_ins_tab(i+1).program_application_id     := gt_last_program_application_id;       --プログラムアプリケーションID
            g_mtl_txn_oif_ins_tab(i+1).program_id                 := gt_last_program_id;                   --プログラムID
            g_mtl_txn_oif_ins_tab(i+1).program_update_date        := gt_last_program_update_date;          --プログラム更新日
          END IF;
--
          IF ( lt_subinventory = g_mtl_txn_oif_ins_tab(i).subinventory_code AND
               lt_item_id      = g_mtl_txn_oif_ins_tab(i).inventory_item_id AND
               lt_txn_date     = g_mtl_txn_oif_ins_tab(i).transaction_date  AND
               lt_dept_code    = g_mtl_txn_oif_ins_tab(i).dept_code         AND
               lt_type_id      = g_mtl_txn_oif_ins_tab(i).transaction_type_id ) THEN
            <<last_same_break_loop>>
            FOR j IN ln_break_start .. ln_break_end LOOP
              --当レコードが削除されていなければ、集計される対象となります。
              IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
                --ブレーク内で同じ取引タイプIDの取引数量を計上します。
                <<last_sum_sub_loop>>
                FOR k IN ( j + 1 ) .. ln_break_end LOOP
                  IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
                       g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
                    g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
                                                                 g_mtl_txn_oif_ins_tab(k).transaction_quantity;
                    --計上されたため、削除します。
                    g_mtl_txn_oif_ins_tab.DELETE( k );
                    --最終データの索引番号の取得
                    ln_last_data := j;
                  END IF;
                END LOOP last_sum_sub_loop;
              END IF;
            END LOOP last_same_break_loop;
--
            --最終集計データを変数に格納します。
            IF ( g_mtl_txn_oif_ins_tab.EXISTS( ln_last_data ) ) THEN
              gt_last_source_code            := g_mtl_txn_oif_ins_tab( ln_last_data ).source_code;                 --ソースコード
              gt_last_source_line_id         := g_mtl_txn_oif_ins_tab( ln_last_data ).source_line_id;              --ソース明細ID
              gt_last_source_header_id       := g_mtl_txn_oif_ins_tab( ln_last_data ).source_header_id;            --ソースヘッダーID
              gt_last_process_flag           := g_mtl_txn_oif_ins_tab( ln_last_data ).process_flag;                --処理フラグ
              gt_last_validation_required    := g_mtl_txn_oif_ins_tab( ln_last_data ).validation_required;         --検証要
              gt_last_transaction_mode       := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_mode;            --取引モード
              gt_last_inventory_item_id      := g_mtl_txn_oif_ins_tab( ln_last_data ).inventory_item_id;           --取引品目ID
              gt_last_organization_id        := g_mtl_txn_oif_ins_tab( ln_last_data ).organization_id;             --取引元の組織ID
              gt_last_transaction_quantity   := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_quantity;        --取引数量
              gt_last_transaction_uom        := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_uom;             --取引単位
              gt_last_transaction_date       := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_date;            --取引発生日
              gt_last_subinventory_code      := g_mtl_txn_oif_ins_tab( ln_last_data ).subinventory_code;           --取引元の保管場所名
              gt_last_transaction_source_id  := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_source_id;       --取引ソースID
              gt_last_tran_source_type_id    := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_source_type_id;  --取引ソースタイプID
              gt_last_transaction_type_id    := g_mtl_txn_oif_ins_tab( ln_last_data ).transaction_type_id;         --取引タイプID
              gt_last_scheduled_flag         := g_mtl_txn_oif_ins_tab( ln_last_data ).scheduled_flag;              --計画フラグ
              gt_last_flow_schedule          := g_mtl_txn_oif_ins_tab( ln_last_data ).flow_schedule;               --計画フロー
              gt_last_created_by             := g_mtl_txn_oif_ins_tab( ln_last_data ).created_by;                  --作成者ID
              gt_last_creation_date          := g_mtl_txn_oif_ins_tab( ln_last_data ).creation_date;               --作成日
              gt_last_last_updated_by        := g_mtl_txn_oif_ins_tab( ln_last_data ).last_updated_by;             --最終更新者ID
              gt_last_last_update_date       := g_mtl_txn_oif_ins_tab( ln_last_data ).last_update_date;            --最終更新日
              gt_last_last_update_login      := g_mtl_txn_oif_ins_tab( ln_last_data ).last_update_login;           --最終ログインID
              gt_last_request_id             := g_mtl_txn_oif_ins_tab( ln_last_data ).request_id;                  --要求ID
              gt_last_program_application_id := g_mtl_txn_oif_ins_tab( ln_last_data ).program_application_id;      --プログラムアプリケーションID
              gt_last_program_id             := g_mtl_txn_oif_ins_tab( ln_last_data ).program_id;                  --プログラムID
              gt_last_program_update_date    := g_mtl_txn_oif_ins_tab( ln_last_data ).program_update_date;         --プログラム更新日
              gt_last_dept_code              := g_mtl_txn_oif_ins_tab( ln_last_data ).dept_code;                   --部門コード
              --変数に格納したため、削除します。
              g_mtl_txn_oif_ins_tab.DELETE( ln_last_data );
            END IF;
          ELSE
            <<last_same_break_loop>>
            FOR j IN ln_break_start .. ( ln_break_end - 1 ) LOOP
              --当レコードが削除されていなければ、集計される対象となります。
              IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
                --ブレーク内で同じ取引タイプIDの取引数量を計上します。
                <<last_sum_sub_loop>>
                FOR k IN ( j + 1 ) .. ( ln_break_end - 1 ) LOOP
                  IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
                       g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
                    g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
                                                                 g_mtl_txn_oif_ins_tab(k).transaction_quantity;
                    --計上されたため、削除します。
                    g_mtl_txn_oif_ins_tab.DELETE( k );
                  END IF;
                END LOOP last_sum_sub_loop;
              END IF;
            END LOOP last_same_break_loop;
--
            --最終データを変数に格納
            gt_last_source_code            := g_mtl_txn_oif_ins_tab( i ).source_code;                 --ソースコード
            gt_last_source_line_id         := g_mtl_txn_oif_ins_tab( i ).source_line_id;              --ソース明細ID
            gt_last_source_header_id       := g_mtl_txn_oif_ins_tab( i ).source_header_id;            --ソースヘッダーID
            gt_last_process_flag           := g_mtl_txn_oif_ins_tab( i ).process_flag;                --処理フラグ
            gt_last_validation_required    := g_mtl_txn_oif_ins_tab( i ).validation_required;         --検証要
            gt_last_transaction_mode       := g_mtl_txn_oif_ins_tab( i ).transaction_mode;            --取引モード
            gt_last_inventory_item_id      := g_mtl_txn_oif_ins_tab( i ).inventory_item_id;           --取引品目ID
            gt_last_organization_id        := g_mtl_txn_oif_ins_tab( i ).organization_id;             --取引元の組織ID
            gt_last_transaction_quantity   := g_mtl_txn_oif_ins_tab( i ).transaction_quantity;        --取引数量
            gt_last_transaction_uom        := g_mtl_txn_oif_ins_tab( i ).transaction_uom;             --取引単位
            gt_last_transaction_date       := g_mtl_txn_oif_ins_tab( i ).transaction_date;            --取引発生日
            gt_last_subinventory_code      := g_mtl_txn_oif_ins_tab( i ).subinventory_code;           --取引元の保管場所名
            gt_last_transaction_source_id  := g_mtl_txn_oif_ins_tab( i ).transaction_source_id;       --取引ソースID
            gt_last_tran_source_type_id    := g_mtl_txn_oif_ins_tab( i ).transaction_source_type_id;  --取引ソースタイプID
            gt_last_transaction_type_id    := g_mtl_txn_oif_ins_tab( i ).transaction_type_id;         --取引タイプID
            gt_last_scheduled_flag         := g_mtl_txn_oif_ins_tab( i ).scheduled_flag;              --計画フラグ
            gt_last_flow_schedule          := g_mtl_txn_oif_ins_tab( i ).flow_schedule;               --計画フロー
            gt_last_created_by             := g_mtl_txn_oif_ins_tab( i ).created_by;                  --作成者ID
            gt_last_creation_date          := g_mtl_txn_oif_ins_tab( i ).creation_date;               --作成日
            gt_last_last_updated_by        := g_mtl_txn_oif_ins_tab( i ).last_updated_by;             --最終更新者ID
            gt_last_last_update_date       := g_mtl_txn_oif_ins_tab( i ).last_update_date;            --最終更新日
            gt_last_last_update_login      := g_mtl_txn_oif_ins_tab( i ).last_update_login;           --最終ログインID
            gt_last_request_id             := g_mtl_txn_oif_ins_tab( i ).request_id;                  --要求ID
            gt_last_program_application_id := g_mtl_txn_oif_ins_tab( i ).program_application_id;      --プログラムアプリケーションID
            gt_last_program_id             := g_mtl_txn_oif_ins_tab( i ).program_id;                  --プログラムID
            gt_last_program_update_date    := g_mtl_txn_oif_ins_tab( i ).program_update_date;         --プログラム更新日
            gt_last_dept_code              := g_mtl_txn_oif_ins_tab( i ).dept_code;                   --部門コード
            --変数に格納したため、削除します。
            g_mtl_txn_oif_ins_tab.DELETE( i );
          END IF;
--************************************* 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ****************************************
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
--          <<last_same_break_loop>>
--          FOR j IN ln_break_start .. ln_break_end LOOP
--            --当レコードが削除されていなければ、集計される対象となります。
--            IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
--              --ブレーク内で同じ取引タイプIDの取引数量を計上します。
--              <<last_sum_sub_loop>>
--              FOR k IN ( j + 1 ) .. ln_break_end LOOP
--                IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
--                     g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
--                  g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
--                                                               g_mtl_txn_oif_ins_tab(k).transaction_quantity;
--                  --計上されたため、削除します。
--                  g_mtl_txn_oif_ins_tab.DELETE( k );
--                END IF;
--              END LOOP last_sum_sub_loop;
--            END IF;
--          END LOOP last_same_break_loop;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
        END IF;
      ELSE
        --今回のブレーク内で集計
        <<same_break_loop>>
        FOR j IN ln_break_start .. ln_break_end LOOP
          --当レコードが削除されていなければ、集計される対象となります。
          IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
            --ブレーク内で同じ取引タイプIDの取引数量を計上します。
            <<sum_sub_loop>>
            FOR k IN ( j + 1 ) .. ln_break_end LOOP
              IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
                   g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
                g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
                                                             g_mtl_txn_oif_ins_tab(k).transaction_quantity;
                --計上されたため、削除します。
                g_mtl_txn_oif_ins_tab.DELETE( k );
              END IF;
            END LOOP sum_sub_loop;
          END IF;
        END LOOP same_break_loop;
        --次のブレークキーを設定します。
        lt_subinventory := g_mtl_txn_oif_ins_tab(i).subinventory_code;
        lt_item_id      := g_mtl_txn_oif_ins_tab(i).inventory_item_id;
        lt_txn_date     := g_mtl_txn_oif_ins_tab(i).transaction_date;
        lt_dept_code    := g_mtl_txn_oif_ins_tab(i).dept_code;
        lt_type_id      := g_mtl_txn_oif_ins_tab(i).transaction_type_id;
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
        --次のブレーク開始Indexを設定します。
        ln_break_start := i;
      END IF;
    END LOOP sum_main_loop;
--
    --資材取引テーブル登録処理
    BEGIN
      <<insert_loop>>
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
      IF ( g_mtl_txn_oif_ins_tab.COUNT > 0 ) THEN
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--      FOR l IN g_mtl_txn_oif_tab.FIRST .. g_mtl_txn_oif_tab.LAST LOOP
--        IF ( g_mtl_txn_oif_tab.EXISTS( l ) ) THEN
      FOR l IN g_mtl_txn_oif_ins_tab.FIRST .. g_mtl_txn_oif_ins_tab.LAST LOOP
        IF ( g_mtl_txn_oif_ins_tab.EXISTS( l ) ) THEN
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
/* 2009/06/17 Ver1.6 Add Start */
          --取引数量が0以外の場合作成する
          IF ( g_mtl_txn_oif_ins_tab(l).transaction_quantity <> 0 ) THEN
/* 2009/06/17 Ver1.6 Add End   */
          INSERT INTO 
            mtl_transactions_interface(
              source_code,                   --ソースコード
              source_line_id,                --ソース明細ID
              source_header_id,              --ソースヘッダーID
              process_flag,                  --処理フラグ
              validation_required,           --検証要
              transaction_mode,              --取引モード
              inventory_item_id,             --取引品目ID
              organization_id,               --取引元の組織ID
              transaction_quantity,          --取引数量
              transaction_uom,               --取引単位
              transaction_date,              --取引発生日
              subinventory_code,             --取引元の保管場所名
              transaction_source_id,         --取引ソースID
              transaction_source_type_id,    --取引ソースタイプID
              transaction_type_id,           --取引タイプID
              scheduled_flag,                --計画フラグ
              flow_schedule,                 --計画フロー
              created_by,                    --作成者ID
              creation_date,                 --作成日
              last_updated_by,               --最終更新者ID
              last_update_date,              --最終更新日
              last_update_login,             --最終ログインID
              request_id,                    --要求ID
              program_application_id,        --プログラムアプリケーションID
              program_id,                    --プログラムID
              program_update_date            --プログラム更新日
            )
          VALUES(
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--            g_mtl_txn_oif_tab(l).source_code,
--            g_mtl_txn_oif_tab(l).source_line_id,
--            g_mtl_txn_oif_tab(l).source_header_id,
--            g_mtl_txn_oif_tab(l).process_flag,
--            g_mtl_txn_oif_tab(l).validation_required,
--            g_mtl_txn_oif_tab(l).transaction_mode,
--            g_mtl_txn_oif_tab(l).inventory_item_id,
--            g_mtl_txn_oif_tab(l).organization_id,
--            g_mtl_txn_oif_tab(l).transaction_quantity,
--            g_mtl_txn_oif_tab(l).transaction_uom,
--            g_mtl_txn_oif_tab(l).transaction_date,
--            g_mtl_txn_oif_tab(l).subinventory_code,
--            g_mtl_txn_oif_tab(l).transaction_source_id,
--            g_mtl_txn_oif_tab(l).transaction_source_type_id,
--            g_mtl_txn_oif_tab(l).transaction_type_id,
--            g_mtl_txn_oif_tab(l).scheduled_flag,
--            g_mtl_txn_oif_tab(l).flow_schedule,
--            g_mtl_txn_oif_tab(l).created_by,
--            g_mtl_txn_oif_tab(l).creation_date,
--            g_mtl_txn_oif_tab(l).last_updated_by,
--            g_mtl_txn_oif_tab(l).last_update_date,
--            g_mtl_txn_oif_tab(l).last_update_login,
--            g_mtl_txn_oif_tab(l).request_id,
--            g_mtl_txn_oif_tab(l).program_application_id,
--            g_mtl_txn_oif_tab(l).program_id,
--            g_mtl_txn_oif_tab(l).program_update_date
            g_mtl_txn_oif_ins_tab(l).source_code,
            g_mtl_txn_oif_ins_tab(l).source_line_id,
            g_mtl_txn_oif_ins_tab(l).source_header_id,
            g_mtl_txn_oif_ins_tab(l).process_flag,
            g_mtl_txn_oif_ins_tab(l).validation_required,
            g_mtl_txn_oif_ins_tab(l).transaction_mode,
            g_mtl_txn_oif_ins_tab(l).inventory_item_id,
            g_mtl_txn_oif_ins_tab(l).organization_id,
            g_mtl_txn_oif_ins_tab(l).transaction_quantity,
            g_mtl_txn_oif_ins_tab(l).transaction_uom,
            g_mtl_txn_oif_ins_tab(l).transaction_date,
            g_mtl_txn_oif_ins_tab(l).subinventory_code,
            g_mtl_txn_oif_ins_tab(l).transaction_source_id,
            g_mtl_txn_oif_ins_tab(l).transaction_source_type_id,
            g_mtl_txn_oif_ins_tab(l).transaction_type_id,
            g_mtl_txn_oif_ins_tab(l).scheduled_flag,
            g_mtl_txn_oif_ins_tab(l).flow_schedule,
            g_mtl_txn_oif_ins_tab(l).created_by,
            g_mtl_txn_oif_ins_tab(l).creation_date,
            g_mtl_txn_oif_ins_tab(l).last_updated_by,
            g_mtl_txn_oif_ins_tab(l).last_update_date,
            g_mtl_txn_oif_ins_tab(l).last_update_login,
            g_mtl_txn_oif_ins_tab(l).request_id,
            g_mtl_txn_oif_ins_tab(l).program_application_id,
            g_mtl_txn_oif_ins_tab(l).program_id,
            g_mtl_txn_oif_ins_tab(l).program_update_date
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
          )
          ;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
          --正常件数のカウント
          gn_normal_cnt := gn_normal_cnt + 1;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
/* 2009/06/17 Ver1.6 Add Start */
          END IF;
/* 2009/06/17 Ver1.6 Add End   */
        END IF;
      END LOOP insert_loop;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
      END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
  EXCEPTION
    --*** データ登録例外 ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name2
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_insert_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mtl_tran_oif;
--
--
  /**********************************************************************************
   * Procedure Name   : update_inv_fsh_flag
   * Description      : 処理済ステータス更新(A-5)
   ***********************************************************************************/
  PROCEDURE update_inv_fsh_flag(
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    iv_update_flag IN  VARCHAR2,     --   対象データ更新フラグ
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
/* 2010/11/01 Ver1.13 Add Start */
    iv_night_mode  IN  VARCHAR2,     --   起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_fsh_flag'; -- プログラム名
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
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    lv_update        CONSTANT VARCHAR2(1) := 'Y'; -- 対象データ更新
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
/* 2010/11/01 Ver1.13 Add Start */
    cv_night_mode    CONSTANT VARCHAR2(1) := 'Y'; -- 夜間起動モード
/* 2010/11/01 Ver1.13 Add End   */
--
    -- *** ローカル変数 ***
    lv_tkn_vl_table_name      VARCHAR2(100);      --エラー対象であるテーブル名
-- ************************ 2009/08/06 1.18 N.Maeda ADD START *************************** --
    ln_up_count               NUMBER;
-- ************************ 2009/08/06 1.18 N.Maeda ADD  END  *************************** --
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    ln_excluded_num           NUMBER;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
-- ************************ 2009/08/06 1.8 N.Maeda ADD START *************************** --
    TYPE line_id_tab_type IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE INDEX BY BINARY_INTEGER;
    line_id_tab  line_id_tab_type;
-- ************************ 2009/08/06 1.8 N.Maeda ADD  END  *************************** --
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    TYPE row_id_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    l_row_id  row_id_type;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    IF ( iv_update_flag = lv_update ) THEN
      IF ( g_sales_exp_tab.COUNT > 0 ) THEN
        ln_up_count := 0;
        -- UPDATE用変数へコピー
        <<up_co_loop>>
        FOR c IN g_sales_exp_tab.FIRST..g_sales_exp_tab.LAST LOOP
          IF ( g_sales_exp_tab.EXISTS( c ) ) THEN
            ln_up_count := ln_up_count + 1;
            line_id_tab(ln_up_count) := g_sales_exp_tab(c).line_id;
          END IF;
        END LOOP up_co_loop;
--
        --販売実績の処理済ステータスの更新処理
        BEGIN
          FORALL i IN 1..line_id_tab.COUNT
--
              UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
              SET    sel.inv_interface_flag       = cv_inv_flg_y,                --INVインタフェース済フラグ
                     sel.last_updated_by          = cn_last_updated_by,          --最終更新者
                     sel.last_update_date         = cd_last_update_date,         --最終更新日
                     sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
                     sel.request_id               = cn_request_id,               --要求ID
                     sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                     sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                     sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
              WHERE  sel.sales_exp_line_id        = line_id_tab(i)               --明細ID
              ;
--
        EXCEPTION
          --対象データ更新失敗
          WHEN OTHERS THEN
            lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_sales_exp_nomal
            );
            RAISE global_data_update_expt;
        END;
      END IF;
--
      IF ( gt_sales_exp_line_id.COUNT > 0 ) THEN
        -- 警告データ更新
        BEGIN
          FORALL w IN 1..gt_sales_exp_line_id.COUNT
              UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
              SET    sel.inv_interface_flag       = cv_wan_data_flg,             --INVインタフェース警告終了フラグ
                     sel.last_updated_by          = cn_last_updated_by,          --最終更新者
                     sel.last_update_date         = cd_last_update_date,         --最終更新日
                     sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
                     sel.request_id               = cn_request_id,               --要求ID
                     sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                     sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                     sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
              WHERE  sel.sales_exp_line_id        = gt_sales_exp_line_id(w)       --明細ID
              ;
        EXCEPTION
          --対象データ更新失敗
          WHEN OTHERS THEN
            lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_sales_exp_warn
            );
            RAISE global_data_update_expt;
        END;
      END IF;
--
--
    ELSE
/* 2010/11/01 Ver1.13 Add Start */
      --夜間起動のみ対象外データ更新をする
      IF ( iv_night_mode = cv_night_mode ) THEN
/* 2010/11/01 Ver1.13 Add End   */
        -- 対象外データロック、対象外データ取得
        BEGIN
-- ************************ 2009/10/09 M.Sano Var1.12 ADD START ************************ --
--        SELECT xsel.ROWID row_id
--        BULK COLLECT INTO l_row_id
--        FROM   xxcos_sales_exp_headers xseh
--               ,xxcos_sales_exp_lines   xsel
--        WHERE  xseh.sales_exp_header_id = xsel.sales_exp_header_id
--        AND    xsel.inv_interface_flag = cv_inv_flg_n
--        AND    xseh.delivery_date     <= gd_proc_date
          SELECT /*+
                    LEADING(xsel)
                    INDEX(xsel xxcos_sales_exp_lines_n03)
                  */
                 xsel.ROWID row_id
          BULK COLLECT INTO l_row_id
          FROM   xxcos_sales_exp_lines   xsel
          WHERE  xsel.inv_interface_flag = cv_inv_flg_n
          AND    EXISTS (
                   SELECT /*+
                             USE_NL(xseh)
                          */
                          'Y'    ext_flg
                   FROM   xxcos_sales_exp_headers xseh
                   WHERE  xseh.sales_exp_header_id = xsel.sales_exp_header_id
                   AND    xseh.delivery_date     <= gd_proc_date
                 )
-- ************************ 2009/10/09 M.Sano Var1.12 ADD  END  ************************ --
          FOR UPDATE OF xsel.inv_interface_flag NOWAIT;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- 処理対象外データが存在する場合
        IF ( l_row_id.COUNT > 0 ) THEN
--
          -- 対象外データ更新
          BEGIN
            FORALL n IN 1..l_row_id.COUNT
              UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
              SET    sel.inv_interface_flag       = cv_excluded_flg,             --INVインタフェース警告終了フラグ
                     sel.last_updated_by          = cn_last_updated_by,          --最終更新者
                     sel.last_update_date         = cd_last_update_date,         --最終更新日
                     sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
                     sel.request_id               = cn_request_id,               --要求ID
                     sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                     sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                     sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
              WHERE  sel.ROWID                    = l_row_id(n)                  --行ID
              ;
          EXCEPTION
            --対象データ更新失敗
            WHEN OTHERS THEN
              lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
                iv_application        =>  cv_xxcos_short_name,
                iv_name               =>  cv_msg_sales_exp_exclu
              );
            RAISE global_data_update_expt;
          END;
        END IF;
/* 2010/11/01 Ver1.13 Add Start */
      END IF;
/* 2010/11/01 Ver1.13 Add End   */
    END IF;
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
---- ************************ 2009/08/06 1.18 N.Maeda ADD START *************************** --
----
---- ************************ 2009/08/25 1.10 N.Maeda ADD START *************************** --
--    IF ( g_sales_exp_tab.COUNT > 0 ) THEN
---- ************************ 2009/08/25 1.10 N.Maeda ADD  END  *************************** --
--      ln_up_count := 0;
--      -- UPDATE用変数へコピー
--      <<up_co_loop>>
--      FOR c IN g_sales_exp_tab.FIRST..g_sales_exp_tab.LAST LOOP
--        IF ( g_sales_exp_tab.EXISTS( c ) ) THEN
--          ln_up_count := ln_up_count + 1;
--          line_id_tab(ln_up_count) := g_sales_exp_tab(c).line_id;
--        END IF;
--      END LOOP up_co_loop;
----
---- ************************ 2009/08/06 1.18 N.Maeda ADD  END  *************************** --
----
--      --販売実績の処理済ステータスの更新処理
--      BEGIN
---- ************************ 2009/08/06 1.8 N.Maeda MOD START *************************** --
----
----
--        FORALL i IN 1..line_id_tab.COUNT
----
--            UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
--            SET    sel.inv_interface_flag       = cv_inv_flg_y,                --INVインタフェース済フラグ
--                   sel.last_updated_by          = cn_last_updated_by,          --最終更新者
--                   sel.last_update_date         = cd_last_update_date,         --最終更新日
--                   sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
--                   sel.request_id               = cn_request_id,               --要求ID
--                   sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--                   sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--                   sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
--            WHERE  sel.sales_exp_line_id        = line_id_tab(i)               --明細ID
--            ;
----
----      <<update_loop>>
----      FOR i IN g_sales_exp_tab.FIRST .. g_sales_exp_tab.LAST LOOP
----        IF ( g_sales_exp_tab.EXISTS( i ) ) THEN
----        UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
----        SET    sel.inv_interface_flag       = cv_inv_flg_y,                --INVインタフェース済フラグ
----               sel.last_updated_by          = cn_last_updated_by,          --最終更新者
----               sel.last_update_date         = cd_last_update_date,         --最終更新日
----               sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
----               sel.request_id               = cn_request_id,               --要求ID
----               sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
----               sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
----               sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
----        WHERE  sel.sales_exp_line_id        = g_sales_exp_tab(i).line_id   --明細ID
----        ;
----        END IF;
----      END LOOP update_loop;
---- ************************ 2009/08/06 1.8 N.Maeda MOD  END  *************************** --
--      EXCEPTION
--        --対象データ更新失敗
--        WHEN OTHERS THEN
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
--            iv_application        =>  cv_xxcos_short_name,
--            iv_name               =>  cv_msg_sales_exp_nomal
--          );
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--          RAISE global_data_update_expt;
--      END;
---- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
--    END IF;
----
--    IF ( gt_sales_exp_line_id.COUNT > 0 ) THEN
--      -- 警告データ更新
--      BEGIN
--        FORALL w IN 1..gt_sales_exp_line_id.COUNT
--            UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
--            SET    sel.inv_interface_flag       = cv_wan_data_flg,             --INVインタフェース警告終了フラグ
--                   sel.last_updated_by          = cn_last_updated_by,          --最終更新者
--                   sel.last_update_date         = cd_last_update_date,         --最終更新日
--                   sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
--                   sel.request_id               = cn_request_id,               --要求ID
--                   sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--                   sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--                   sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
--            WHERE  sel.sales_exp_line_id        = gt_sales_exp_line_id(w)       --明細ID
--            ;
--      EXCEPTION
--        --対象データ更新失敗
--        WHEN OTHERS THEN
--          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
--            iv_application        =>  cv_xxcos_short_name,
--            iv_name               =>  cv_msg_sales_exp_warn
--          );
--          RAISE global_data_update_expt;
--      END;
--    END IF;
----
----
--    -- 対象外データロック、対象外データ取得
--    BEGIN
--      SELECT xsel.ROWID row_id
--      BULK COLLECT INTO l_row_id
--      FROM   xxcos_sales_exp_headers xseh
--             ,xxcos_sales_exp_lines   xsel
--      WHERE  xseh.sales_exp_header_id = xsel.sales_exp_header_id
--      AND    xsel.inv_interface_flag = cv_inv_flg_n
--      AND    xseh.delivery_date     <= gd_proc_date
--      FOR UPDATE OF xsel.inv_interface_flag NOWAIT;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--    END;
----
--    -- 処理対象外データが存在する場合
--    IF ( l_row_id.COUNT > 0 ) THEN
----
--      -- 対象外データ更新
--      BEGIN
--        FORALL n IN 1..l_row_id.COUNT
--          UPDATE xxcos_sales_exp_lines sel                                   --販売実績明細テーブル
--          SET    sel.inv_interface_flag       = cv_excluded_flg,             --INVインタフェース警告終了フラグ
--                 sel.last_updated_by          = cn_last_updated_by,          --最終更新者
--                 sel.last_update_date         = cd_last_update_date,         --最終更新日
--                 sel.last_update_login        = cn_last_update_login,        --最終更新ﾛｸﾞｲﾝ
--                 sel.request_id               = cn_request_id,               --要求ID
--                 sel.program_application_id   = cn_program_application_id,   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--                 sel.program_id               = cn_program_id,               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--                 sel.program_update_date      = cd_program_update_date       --ﾌﾟﾛｸﾞﾗﾑ更新日
--          WHERE  sel.ROWID                    = l_row_id(n)                  --行ID
--          ;
--      EXCEPTION
--        --対象データ更新失敗
--        WHEN OTHERS THEN
--          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
--            iv_application        =>  cv_xxcos_short_name,
--            iv_name               =>  cv_msg_sales_exp_exclu
--          );
--        RAISE global_data_update_expt;
--      END;
--    END IF;
----
---- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
--
  EXCEPTION
    --*** 対象データ更新例外ハンドラ ***
    WHEN global_data_update_expt THEN
-- ********** 2009/08/25 N.Maeda Var1.10 DEL START *********** --
--      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_vl_table_name1
--      );
-- ********** 2009/08/25 N.Maeda Var1.10 DEL  END  *********** --
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_update_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    --*** 排他ロック取得エラーハンドラ ***
    WHEN global_data_lock_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_sales_exp_exclu
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_inv_fsh_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
/* 2010/11/01 Ver1.13 Add Start */
    iv_night_mode       IN  VARCHAR2,     --   起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************** --
    lv_update_flag      CONSTANT VARCHAR2(1) := 'Y';   -- 対象データ更新
    lv_no_update_flag   CONSTANT VARCHAR2(1) := 'N';   -- 対象外データ更新
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************** --
--
    -- *** ローカル変数 ***
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************** --
    ln_fetch_cnt              NUMBER;               -- フェッチ取得件数
    lv_warnmsg                VARCHAR2(5000);       --ユーザー・警告・メッセージ
-- ********** 2009/09/14 S.Miyakoshi Var1.11 ADD END **************************** --
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
/* 2010/11/01 Ver1.13 Add Start */
      iv_night_mode,      -- 起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  対象データ取得
    -- ===============================
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    -- カーソルOPEN
    OPEN  get_main_cur;
    LOOP
      -- バルクフェッチ
      FETCH get_main_cur BULK COLLECT INTO g_sales_exp_tab LIMIT gn_bulk_size;
      EXIT WHEN g_sales_exp_tab.COUNT = 0;
--
      -- 対象データロック
      get_data(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        gv_lock_retcode,    -- ロック処理リターン・コード
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( gv_lock_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        EXIT WHEN gv_lock_retcode <> cv_status_normal;
      END IF;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + g_sales_exp_tab.COUNT;
--
      -- ===============================
      -- A-3  資材取引データ生成
      -- ===============================
      make_mtl_tran_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-4  資材取引OIF出力
      -- ===============================
      IF ( g_mtl_txn_oif_tab.COUNT > 0 ) THEN
        insert_mtl_tran_oif(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode = cv_status_normal ) THEN
          NULL;
        ELSE
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- ===============================
      -- A-5  処理済ステータス更新(対象、警告データの更新)
      -- ===============================
      update_inv_fsh_flag(
        lv_update_flag,    -- 対象データ更新フラグ＝'Y'
/* 2010/11/01 Ver1.13 Add Start */
        iv_night_mode,     -- 起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
--
      -- 変数の初期化
      g_sales_exp_tab.DELETE;
      gt_sales_exp_line_id.DELETE;
      g_mtl_txn_oif_tab.DELETE;
      g_mtl_txn_oif_tab_spare.DELETE;
      g_mtl_txn_oif_ins_tab.DELETE;
--
      -- コミット発行
      COMMIT;
--
    END LOOP;
    -- 最終データの登録
    IF ( gt_last_source_code IS NOT NULL ) THEN
      INSERT INTO 
        mtl_transactions_interface(
          source_code,                    --ソースコード
          source_line_id,                 --ソース明細ID
          source_header_id,               --ソースヘッダーID
          process_flag,                   --処理フラグ
          validation_required,            --検証要
          transaction_mode,               --取引モード
          inventory_item_id,              --取引品目ID
          organization_id,                --取引元の組織ID
          transaction_quantity,           --取引数量
          transaction_uom,                --取引単位
          transaction_date,               --取引発生日
          subinventory_code,              --取引元の保管場所名
          transaction_source_id,          --取引ソースID
          transaction_source_type_id,     --取引ソースタイプID
          transaction_type_id,            --取引タイプID
          scheduled_flag,                 --計画フラグ
          flow_schedule,                  --計画フロー
          created_by,                     --作成者ID
          creation_date,                  --作成日
          last_updated_by,                --最終更新者ID
          last_update_date,               --最終更新日
          last_update_login,              --最終ログインID
          request_id,                     --要求ID
          program_application_id,         --プログラムアプリケーションID
          program_id,                     --プログラムID
          program_update_date             --プログラム更新日
        )
      VALUES(
        gt_last_source_code,              --ソースコード
        gt_last_source_line_id,           --ソース明細ID
        gt_last_source_header_id,         --ソースヘッダーID
        gt_last_process_flag,             --処理フラグ
        gt_last_validation_required,      --検証要
        gt_last_transaction_mode,         --取引モード
        gt_last_inventory_item_id,        --取引品目ID
        gt_last_organization_id,          --取引元の組織ID
        gt_last_transaction_quantity,     --取引数量
        gt_last_transaction_uom,          --取引単位
        gt_last_transaction_date,         --取引発生日
        gt_last_subinventory_code,        --取引元の保管場所名
        gt_last_transaction_source_id,    --取引ソースID
        gt_last_tran_source_type_id,      --取引ソースタイプID
        gt_last_transaction_type_id,      --取引タイプID
        gt_last_scheduled_flag,           --計画フラグ
        gt_last_flow_schedule,            --計画フロー
        gt_last_created_by,               --作成者ID
        gt_last_creation_date,            --作成日
        gt_last_last_updated_by,          --最終更新者ID
        gt_last_last_update_date,         --最終更新日
        gt_last_last_update_login,        --最終ログインID
        gt_last_request_id,               --要求ID
        gt_last_program_application_id,   --プログラムアプリケーションID
        gt_last_program_id,               --プログラムID
        gt_last_program_update_date       --プログラム更新日
      )
      ;
      --正常件数のカウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- コミット発行
      COMMIT;
--
    END IF;
    -- カーソルCLOSE
    CLOSE get_main_cur;
--
    IF ( gv_lock_retcode <> cv_status_error ) THEN
      -- ===============================
      -- A-5  処理済ステータス更新(対象外データの更新)
      -- ===============================
      update_inv_fsh_flag(
        lv_no_update_flag, -- 対象データ更新フラグ
/* 2010/11/01 Ver1.13 Add Start */
        iv_night_mode,     -- 起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Add End   */
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL START ************************ --
----    get_data(
----      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
----      lv_retcode,         -- リターン・コード             --# 固定 #
----      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
----    IF ( lv_retcode = cv_status_normal ) THEN
----      NULL;
----    ELSE
----      RAISE global_process_expt;
----    END IF;
----
--    -- ===============================
--    -- A-3  資材取引データ生成
--    -- ===============================
--    IF ( gn_target_cnt > 0 ) THEN
--     make_mtl_tran_data(
--       lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--       lv_retcode,        -- リターン・コード             --# 固定 #
--       lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--     IF ( lv_retcode = cv_status_normal ) THEN
--       NULL;
--     ELSE
--       RAISE global_process_expt;
--     END IF;
--    END IF;
----
--    -- ===============================
--    -- A-4  資材取引OIF出力
--    -- ===============================
--    IF ( g_mtl_txn_oif_tab.COUNT > 0 ) THEN
--      insert_mtl_tran_oif(
--        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--        lv_retcode,        -- リターン・コード             --# 固定 #
--        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--      IF ( lv_retcode = cv_status_normal ) THEN
--        NULL;
--      ELSE
--        RAISE global_process_expt;
--      END IF;
--    END IF;
----
--    -- ===============================
--    -- A-5  処理済ステータス更新
--    -- ===============================
---- ************************ 2009/08/25 1.10 N.Maeda DEL START *************************** --
----    IF ( g_sales_exp_tab.COUNT > 0 ) THEN
---- ************************ 2009/08/25 1.10 N.Maeda DEL  END  *************************** --
--      update_inv_fsh_flag(
--        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--        lv_retcode,        -- リターン・コード             --# 固定 #
--        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--      IF ( lv_retcode = cv_status_normal ) THEN
--        NULL;
--      ELSE
--        RAISE global_process_expt;
--      END IF;
---- ************************ 2009/08/25 1.10 N.Maeda DEL START *************************** --
----    END IF;
---- ************************ 2009/08/25 1.10 N.Maeda DEL  END  *************************** --
----
----************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--    --正常件数取得
----    gn_normal_cnt := g_mtl_txn_oif_tab.COUNT;
--    --正常件数取得
--    gn_normal_cnt := g_mtl_txn_oif_ins_tab.COUNT;
----************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 DEL  END  ************************ --
--
    --ステータス制御処理
    IF ( gn_target_cnt = 0 OR gn_warn_cnt > 0 ) THEN
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
--      ov_retcode := cv_status_warn;
      IF ( gv_lock_retcode = cv_status_error ) THEN
        NULL;
      ELSE
        ov_retcode := cv_status_warn;
        --抽出データ件数0件、警告メッセージ出力
        IF ( gn_target_cnt = 0 ) THEN
        lv_warnmsg              :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_no_data_err
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_warnmsg --ユーザー・警告・メッセージ
        );
        --空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
        );
        END IF;
      END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
    END IF;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
      -- カーソルのクローズ
      IF ( get_main_cur%ISOPEN ) THEN
        CLOSE get_main_cur;
      END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
/* 2010/11/01 Ver1.13 Mod Start */
--    retcode             OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_night_mode       IN  VARCHAR2       --   起動モード（N:日中 or Y:夜間）
/* 2010/11/01 Ver1.13 Mod End   */
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    cv_error_part_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
/* 2010/11/01 Ver1.13 Mod Start */
--       lv_errbuf   -- エラー・メッセージ           --# 固定 #
       iv_night_mode -- 起動モード（N:日中 or Y:夜間）
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
/* 2010/11/01 Ver1.13 Mod end   */
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    IF ( gv_lock_retcode = cv_status_error ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxccp_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => '1'
                     );
    ELSE
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD START ************************ --
    END IF;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 ADD  END  ************************ --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
      IF ( gv_lock_retcode = cv_status_error ) THEN
        lv_message_code := cv_warn_msg;
      ELSE
        lv_message_code := cv_warn_msg;
      END IF;
--      lv_message_code := cv_warn_msg;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
    ELSIF( lv_retcode = cv_status_error ) THEN
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD START ************************ --
      IF ( gv_lock_retcode = cv_status_error ) THEN
        lv_message_code := cv_error_part_msg;
      ELSE
        lv_message_code := cv_error_msg;
      END IF;
--      lv_message_code := cv_error_msg;
-- ************************ 2009/09/14 S.Miyakoshi Var1.11 MOD  END  ************************ --
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS013A02C;
/
