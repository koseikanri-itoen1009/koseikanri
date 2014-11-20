CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A02C 
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A02C (spec)
 * Description      : SQL-LOADERによってEDI在庫情報ワークテーブルに取込まれたEDI在庫情報データを
 *                     EDI在庫情報テーブルにそれぞれ登録します。
 * MD.050           : 在庫情報データ取込（MD050_COS_011_A02）
 * Version          : 1.8
 *
 * Program List
 * ----------------------------------- ----------------------------------------------------------
 *  Name                                Description
 * ----------------------------------- ----------------------------------------------------------
 *  init                               初期処理 (A-1)
 *  sel_in_edi_inventory_work          EDI在庫情報ワークテーブルデータ抽出 (A-2)
 *  xxcos_in_edi_inventory_edit        EDI在庫情報変数の編集(A-2)(1)
 *  data_check                         データ妥当性チェック (A-3)
 *  xxcos_in_invoice_num_add           伝票別合計変数への追加(A-4)(1)
 *  xxcos_in_invoice_num_req           伝票別合計変数への再編集(A-4)(2)
 *  xxcos_in_invoice_num_up            伝票別合計変数へ数量を加算(A-5)
 *  xxcos_in_edi_inventory_insert      EDI在庫情報テーブルへのデータ挿入(A-6)
 *  xxcos_in_edi_inv_wk_update         EDI在庫情報ワークテーブルへの更新(A-7)
 *  xxcos_in_edi_inventory_delete      EDI在庫情報テーブルデータ削除(A-8)
 *  xxcos_in_edi_inventory_lock        EDI在庫情報テーブルロック(A-8)(1)
 *  xxcos_in_edi_inv_work_delete       EDI在庫情報ワークテーブルデータ削除(A-9)
 *  submain                            メイン処理プロシージャ
 *  main                               コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/29    1.0   K.Watanabe      新規作成
 *  2009/02/17    1.1   K.Kiriu         [COS_062]JANコードエラー時のメッセージを修正
 *                                      [COS_080]伝票計の修正
 *                                      [COS_081]終了ステータスによる処理判定の修正
 *                                      [COS_088]エラー、警告混在時の終了設定の修正
 *                                      [COS_089]エラー時の正常件数設定の修正
 *                                      [COS_090]顧客品目の取得ロジック修正
 *  2009/05/19    1.2   T.Kitajima      [T1_0242]品目取得時、OPM品目マスタ.発売（製造）開始日条件追加
 *                                      [T1_0243]品目取得時、子品目対象外条件追加
 *  2009/05/28    1.3   T.Kitajima      [T1_0711]処理後件数対応
 *  2009/06/04    1.4   T.Kitajima      [T1_1289]処理後件数対応
 *  2009/06/26    1.5   N.Nishimura     [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]対応
 *  2009/09/16    1.6   M.Sano          [0001156]顧客品目・顧客品目相互参照の有効フラグの参照
 *                                      [0001289]顧客導出エラー、品目導出エラー時の取得項目修正
 *  2009/09/24    1.6   M.Sano          [0001289]レビュー指摘対応 (「顧客コード」の妥当性チェックエラー処理修正)
 *  2010/03/04    1.7   T.Nakano        [E_本稼動_01695]EDI受信日の追加
 *  2011/07/28    1.8   K.Kiriu         [E_本稼動_07906]流通BMS対応
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
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; -- 業務処理日
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_line               CONSTANT VARCHAR2(3) := '   ';
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** データ抽出エラー例外 ***
  global_data_sel_expt      EXCEPTION;
  --対象データなし例外
  global_nodata_expt        EXCEPTION;
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT   VARCHAR2(100) := 'XXCOS011A02';               -- パッケージ名
--
  cv_application            CONSTANT   VARCHAR2(5)   := 'XXCOS';                     -- アプリケーション名
  -- プロファイル
  cv_prf_edi_del_date       CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI情報削除期間
  cv_prf_case_code          CONSTANT   VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:ケース単位コード
  cv_prf_orga_code1         CONSTANT   VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_lookup_type            CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';  
  cv_lookup_type1           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';  
  cv_lookup_type2           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_STATUS';  
  cv_lookup_type3           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_DATA_TYPE_CODE';  
  cv_inv_num_err_flag       CONSTANT   VARCHAR2(1)   := '9';   -- 実行区分：「エラー」
  cv_creation_class         CONSTANT   VARCHAR2(10)  := '03';
  cv_customer_class_code10  CONSTANT   VARCHAR2(10)  := '10';  -- 顧客マスタ.顧客区分 = '10'(顧客) 
  cv_customer_class_code18  CONSTANT   VARCHAR2(10)  := '18';  -- 顧客マスタ.顧客区分 = '18'(EDIチェーン店) 
  cv_y                      CONSTANT   VARCHAR2(1)   := 'Y';
-- 2009/09/16 Ver1.6 M.Sano Add Start
  cv_inactive_flag_no       CONSTANT  VARCHAR2(1)    := 'N';    --顧客品目･相互参照.有効フラグ = 「有効」
-- 2009/09/16 Ver1.6 M.Sano Add End
  --cv_par                    CONSTANT   VARCHAR2(1)   := '%';
  cn_1                      CONSTANT   NUMBER        := 1;
  cn_2                      CONSTANT   NUMBER        := 2;
  cn_3                      CONSTANT   NUMBER        := 3;
  cv_0                      CONSTANT   VARCHAR2(1)   := '0';
  cv_1                      CONSTANT   VARCHAR2(1)   := '1';
  cv_2                      CONSTANT   VARCHAR2(1)   := '2';
  cv_run_class_name         CONSTANT   VARCHAR2(1)   := '1';      -- 「エラー」
  --* -------------------------------------------------------------------------------------------
  gv_msg_nodata_err         CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00003'; --対象データなしエラー
  gv_msg_in_param_none_err  CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00006'; --必須入力パラメータ未設定エラーメッセージ
  gv_msg_in_param_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00019'; --入力パラメータ不正エラーメッセージ
  gv_msg_in_none_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00015'; --必須項目未入力エラーメッセージ
  gv_msg_get_profile_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00004'; --プロファイル取得エラーメッセージ
  gv_msg_orga_id_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOI1-00006'; --在庫組織ID取得エラーメッセージ
  gv_msg_lock               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00001'; --ロックエラーメッセージ
  gv_msg_nodata             CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00013'; --データ抽出エラーメッセージ
  gv_msg_cust_num_chg_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00020'; --顧客コード変換エラーメッセージ
  gv_msg_item_code_err      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00023'; --EDI連携品目コード区分エラーメッセージ
  gv_msg_product_code_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00024'; --商品コード変換エラーメッセージ
  gv_msg_data_update_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00011'; --データ更新エラーメッセージ
  gv_msg_data_delete_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00012'; --データ削除エラーメッセージ 
  gv_msg_param_out_msg1     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12151'; --パラメータ出力メッセージ1
  gv_msg_param_out_msg2     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12152'; --パラメータ出力メッセージ2
  gv_msg_prod_cd_ng_rec_num CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00039'; --商品コードエラー件数メッセージ
  gv_msg_normal_msg         CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90004'; --正常終了メッセージ
  gv_msg_warning_msg        CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90005'; --警告終了メッセージ
  gv_msg_error_msg          CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
  cv_msg_call_api_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00017'; --API呼出エラー
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_msg_count              CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12201'; --処理件数メッセージ
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
  --* -------------------------------------------------------------------------------------------
  --トークン
  cv_msg_in_param           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12168';  -- 実行区分
  --トークン プロファイル
  cv_msg_edi_del_date       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12169';  -- EDI情報削除期間
  cv_msg_case_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12153';  -- ケース単位コード
  cv_msg_orga_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12154';  -- 在庫組織コード
  --トークン プロファイル
  cv_msg_in_file_name       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12171';  -- インターフェースファイル名
  --* -------------------------------------------------------------------------------------------
  cv_tkn_profile            CONSTANT   VARCHAR2(50) :=  'PROFILE';              --プロファイル
  cv_tkn_item               CONSTANT   VARCHAR2(50) :=  'ITEM';
  cv_tkn_org_code           CONSTANT   VARCHAR2(50) :=  'ORG_CODE_TOK';
  cv_tkn_in_param           CONSTANT   VARCHAR2(50) :=  'IN_PARAM';             --入力パラメータ
  cv_tkn_api_name           CONSTANT   VARCHAR2(50) :=  'API_NAME';             --API名
  cv_tkn_table_name         CONSTANT   VARCHAR2(50) :=  'TABLE';                --テーブル名
  cv_tkn_table_name1        CONSTANT   VARCHAR2(50) :=  'TABLE_NAME';           --テーブル名
  cv_tkn_key_data           CONSTANT   VARCHAR2(50) :=  'KEY_DATA';             --キーデータ
  cv_chain_shop_code        CONSTANT   VARCHAR2(50) :=  'CHAIN_SHOP_CODE';
  cv_shop_code              CONSTANT   VARCHAR2(50) :=  'SHOP_CODE';
  cv_prod_code              CONSTANT   VARCHAR2(50) :=  'PROD_CODE';
  cv_prod_type              CONSTANT   VARCHAR2(50) :=  'PROD_TYPE';
  cv_param1                 CONSTANT   VARCHAR2(50) :=  'PARAM1';
  cv_param2                 CONSTANT   VARCHAR2(50) :=  'PARAM2';
  cv_application1           CONSTANT   VARCHAR2(5)  :=  'XXCOI';                 -- アプリケーション名
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_tkn_cnt1               CONSTANT   VARCHAR2(50) :=  'COUNT1';            -- カウント1
  cv_tkn_cnt2               CONSTANT   VARCHAR2(50) :=  'COUNT2';            -- カウント2
  cv_tkn_cnt3               CONSTANT   VARCHAR2(50) :=  'COUNT3';            -- カウント3
  cv_tkn_cnt4               CONSTANT   VARCHAR2(50) :=  'COUNT4';            -- カウント4
  cv_tkn_cnt5               CONSTANT   VARCHAR2(50) :=  'COUNT5';            -- カウント5
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
-- 2009/09/16 Ver1.6 M.Sano Add Start
  cv_tkn_column_name        CONSTANT   VARCHAR2(50) :=  'COLMUN';            -- 列名
-- 2009/09/16 Ver1.6 M.Sano Add End
  --* -------------------------------------------------------------------------------------------
  --メッセージ用文字列
  cv_msg_str_profile_name   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12155';  -- プロファイル名
  cv_msg_edi_inv_work       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12173';  -- EDI在庫情報ワークテーブル
  cv_msg_edi_inventory      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12174';  -- EDI在庫情報テーブル
  cv_msg_mtl_cust_items     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12159';  -- 顧客品目
  cv_msg_shop_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12160';  -- 店コード
  cv_msg_class_name1        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12161';  -- 実行区分：「新規」
  cv_msg_class_name2        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12162';  -- 実行区分：「再実施」
  cv_msg_class_name3        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12163';  -- 実行区分：「エラー」
  cv_msg_data_type_code     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12175';  -- データ種コード：「在庫情報」
  cv_msg_jan_code           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12166';  -- JANコード
  cv_msg_none               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12167';  -- なし
-- 2009/09/16 Ver1.6 M.Sano Add Start
  cv_msg_mst_notfound       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- マスタチェックエラーメッセージ
  cv_msg_lookup_value       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- クイックコード
  cv_msg_item_err_type      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-11959';  -- EDI品目エラータイプ
-- 2009/09/16 Ver1.6 M.Sano Add End
  --トークン プロファイル
  cv_msg_in_file_name1      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12172';  -- インターフェースファイル名
  --* -------------------------------------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima ADD START ******************************--
  cv_format_yyyymmdd        CONSTANT   VARCHAR2(20)  := 'YYYY/MM/DD';        -- 日付フォーマット
--****************************** 2009/05/19 1.2 T.Kitajima ADD  END  ******************************--
-- 2009/09/16 Ver1.6 M.Sano Add Start
  cv_default_language       CONSTANT   VARCHAR2(10)  := USERENV('LANG');             -- 標準言語タイプ
-- 2009/09/16 Ver1.6 M.Sano Add End
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_status_work             VARCHAR2(1) DEFAULT NULL;  --警告:1
  --
  --トークン プロファイル
  gv_in_file_name            VARCHAR2(50) DEFAULT NULL;     -- インターフェースファイル名
  gv_in_param                VARCHAR2(50) DEFAULT NULL;     -- 実行区分
  gv_prf_edi_del_date0       VARCHAR2(50) DEFAULT NULL;     -- EDI情報削除期間
  gv_prf_case_code0          VARCHAR2(50) DEFAULT NULL;     -- ケース単位コード
  gv_prf_orga_code0          VARCHAR2(50) DEFAULT NULL;     -- 在庫組織コード
--
  -- テーブル定義名称
  gv_tkn_edi_inv_work        VARCHAR2(50);     -- EDI在庫情報ワークテーブル
  gv_tkn_edi_inventory       VARCHAR2(50);     -- EDI在庫情報テーブル
  gv_tkn_mtl_cust_items      VARCHAR2(50);     -- 顧客品目
  gv_tkn_shop_code           VARCHAR2(50);     -- 店コード
  gv_tkn_jan_code            VARCHAR2(10);     -- JANコード
  gv_none                    VARCHAR2(10);     -- なし
  gv_run_class_name1         VARCHAR2(50) DEFAULT '0';     -- 実行区分：「新規」
  gv_run_class_name2         VARCHAR2(50) DEFAULT '1';     -- 実行区分：「再実施」
  gv_run_data_type_code      VARCHAR2(50) DEFAULT NULL;     -- データ種コード：「返品確定」
  gn_normal_inventry_cnt     NUMBER DEFAULT 0;              -- 正常件数
  -- 伝票番号
  gv_invoice_number          VARCHAR2(12) DEFAULT NULL;
-- 2009/09/16 Ver1.6 M.Sano Add Start
  -- ダミー品目
  gt_dummy_item_number       mtl_system_items_b.segment1%TYPE;
  gt_dummy_unit_of_measure   mtl_system_items_b.primary_unit_of_measure%TYPE;
-- 2009/09/16 Ver1.6 M.Sano Add End
--
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  gn_msg_cnt       NUMBER;                                                   -- メッセージ件数
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- EDI在庫情報ワークテーブルデータ格納用変数(xxcos_edi_inventory_work)
  TYPE g_rec_ediinv_work_data IS RECORD(
                -- 在庫情報ワークID
    stk_info_work_id                 xxcos_edi_inventory_work.stk_info_work_id%TYPE,
                -- 媒体区分
    medium_class                     xxcos_edi_inventory_work.medium_class%TYPE,
                -- データ種コード
    data_type_code                   xxcos_edi_inventory_work.data_type_code%TYPE,
                -- ファイルＮｏ
    file_no                          xxcos_edi_inventory_work.file_no%TYPE,
                -- 情報区分
    info_class                       xxcos_edi_inventory_work.info_class%TYPE,
                -- 処理日
    process_date                     xxcos_edi_inventory_work.process_date%TYPE,
                -- 処理時刻
    process_time                     xxcos_edi_inventory_work.process_time%TYPE,
                -- 拠点（部門）コード
    base_code                        xxcos_edi_inventory_work.base_code%TYPE,
                -- 拠点名（正式名）
    base_name                        xxcos_edi_inventory_work.base_name%TYPE,
                -- 拠点名（カナ）
    base_name_alt                    xxcos_edi_inventory_work.base_name_alt%TYPE,
                -- ＥＤＩチェーン店コード
    edi_chain_code                   xxcos_edi_inventory_work.edi_chain_code%TYPE,
                -- ＥＤＩチェーン店名（漢字）
    edi_chain_name                   xxcos_edi_inventory_work.edi_chain_name%TYPE,
                -- ＥＤＩチェーン店名（カナ）
    edi_chain_name_alt               xxcos_edi_inventory_work.edi_chain_name_alt%TYPE,
                -- 帳票コード
    report_code                      xxcos_edi_inventory_work.report_code%TYPE,
                -- 帳票表示名
    report_show_name                 xxcos_edi_inventory_work.report_show_name%TYPE,
                -- 顧客コード
    customer_code                    xxcos_edi_inventory_work.customer_code%TYPE,
                -- 顧客名（漢字）
    customer_name                    xxcos_edi_inventory_work.customer_name%TYPE,
                -- 顧客名（カナ）
    customer_name_alt                xxcos_edi_inventory_work.customer_name_alt%TYPE,
                -- 社コード
    company_code                     xxcos_edi_inventory_work.company_code%TYPE,
                -- 社名（カナ）
    company_name_alt                 xxcos_edi_inventory_work.company_name_alt%TYPE,
                -- 店コード
    shop_code                        xxcos_edi_inventory_work.shop_code%TYPE, 
                -- 店名（カナ）
    shop_name_alt                    xxcos_edi_inventory_work.shop_name_alt%TYPE,
                -- 納入センターコード
    delivery_center_code             xxcos_edi_inventory_work.delivery_center_code%TYPE,
                -- 納入センター名（漢字）
    delivery_center_name             xxcos_edi_inventory_work.delivery_center_name%TYPE,
                -- 納入センター名（カナ）
    delivery_center_name_alt         xxcos_edi_inventory_work.delivery_center_name_alt%TYPE,
                --倉庫コード
    whse_code                        xxcos_edi_inventory_work.whse_code%TYPE,
                --倉庫名
    whse_name                        xxcos_edi_inventory_work.whse_name%TYPE,
                --検品担当者名（漢字）
    inspect_charge_name              xxcos_edi_inventory_work.inspect_charge_name%TYPE,
                --検品担当者名（カナ）
    inspect_charge_name_alt          xxcos_edi_inventory_work.inspect_charge_name_alt%TYPE,
                --返品担当者名（漢字）
    return_charge_name               xxcos_edi_inventory_work.return_charge_name%TYPE,
                --返品担当者名（カナ）
    return_charge_name_alt           xxcos_edi_inventory_work.return_charge_name_alt%TYPE,
                --受領担当者名（漢字）
    receive_charge_name              xxcos_edi_inventory_work.receive_charge_name%TYPE,
                --受領担当者名（カナ）
    receive_charge_name_alt          xxcos_edi_inventory_work.receive_charge_name_alt%TYPE,
                -- 発注日
    order_date                       xxcos_edi_inventory_work.order_date%TYPE,
                -- センター納品日
    center_delivery_date             xxcos_edi_inventory_work.center_delivery_date%TYPE,
                --センター実納品日
    center_result_delivery_date      xxcos_edi_inventory_work.center_result_delivery_date%TYPE,
                --センター出庫日
    center_shipping_date             xxcos_edi_inventory_work.center_shipping_date%TYPE,
                --センター実出庫日
    center_result_shipping_date      xxcos_edi_inventory_work.center_result_shipping_date%TYPE,
                -- データ作成日（ＥＤＩデータ中）
    data_creation_date_edi_data      xxcos_edi_inventory_work.data_creation_date_edi_data%TYPE,
                -- データ作成時刻（ＥＤＩデータ中）
    data_creation_time_edi_data      xxcos_edi_inventory_work.data_creation_time_edi_data%TYPE,
                --在庫日付
    stk_date                         xxcos_edi_inventory_work.stk_date%TYPE,
                --提供企業取引先コード区分
    offer_vendor_code_class          xxcos_edi_inventory_work.offer_vendor_code_class%TYPE,
                --倉庫取引先コード区分
    whse_vendor_code_class           xxcos_edi_inventory_work.whse_vendor_code_class%TYPE,
                --提供サイクル区分
    offer_cycle_class                xxcos_edi_inventory_work.offer_cycle_class%TYPE,
                --在庫種類
    stk_type                         xxcos_edi_inventory_work.stk_type%TYPE,
                --日本語区分
    japanese_class                   xxcos_edi_inventory_work.japanese_class%TYPE,
                --倉庫区分
    whse_class                       xxcos_edi_inventory_work.whse_class%TYPE,
                -- 取引先コード
    vendor_code                      xxcos_edi_inventory_work.vendor_code%TYPE,
                -- 取引先名（漢字）
    vendor_name                      xxcos_edi_inventory_work.vendor_name%TYPE,
                -- 取引先名（カナ）
    vendor_name_alt                  xxcos_edi_inventory_work.vendor_name_alt%TYPE,
                -- チェックデジット有無区分
    check_digit_class                xxcos_edi_inventory_work.check_digit_class%TYPE,
                -- 伝票番号
    invoice_number                   xxcos_edi_inventory_work.invoice_number%TYPE,
                -- チェックデジット
    check_digit                      xxcos_edi_inventory_work.check_digit%TYPE,
                -- チェーン店固有エリア（ヘッダー）
    chain_peculiar_area_header       xxcos_edi_inventory_work.chain_peculiar_area_header%TYPE,
                -- 商品コード（伊藤園）
    product_code_itouen              xxcos_edi_inventory_work.product_code_itouen%TYPE,
                -- 商品コード（先方）
    product_code_other_party         xxcos_edi_inventory_work.product_code_other_party%TYPE,
                -- ＪＡＮコード
    jan_code                         xxcos_edi_inventory_work.jan_code%TYPE,
                -- ＩＴＦコード
    itf_code                         xxcos_edi_inventory_work.itf_code%TYPE,
                -- 商品名（漢字）
    product_name                     xxcos_edi_inventory_work.product_name%TYPE,
                -- 商品名（カナ）
    product_name_alt                 xxcos_edi_inventory_work.product_name_alt%TYPE,
                -- 商品区分
    prod_class                       xxcos_edi_inventory_work.prod_class%TYPE,
                -- 適用品質区分
    active_quality_class             xxcos_edi_inventory_work.active_quality_class%TYPE,
                -- 入数
    qty_in_case                      xxcos_edi_inventory_work.qty_in_case%TYPE,
                -- 単位
    uom_code                         xxcos_edi_inventory_work.uom_code%TYPE,
                -- 一日平均出荷数量
    day_average_shipping_qty         xxcos_edi_inventory_work.day_average_shipping_qty%TYPE,
                -- 在庫種別コード
    stk_type_code                    xxcos_edi_inventory_work.stk_type_code%TYPE,
                -- 最終入荷日
    last_arrival_date                xxcos_edi_inventory_work.last_arrival_date%TYPE,
                -- 賞味期限
    use_by_date                      xxcos_edi_inventory_work.use_by_date%TYPE,
                -- 製造日
    product_date                     xxcos_edi_inventory_work.product_date%TYPE,
                -- 上限在庫（ケース）
    upper_limit_stk_case             xxcos_edi_inventory_work.upper_limit_stk_case%TYPE,
                -- 上限在庫（バラ）
    upper_limit_stk_indv             xxcos_edi_inventory_work.upper_limit_stk_indv%TYPE,
                -- 発注点（バラ） 
    indv_order_point                 xxcos_edi_inventory_work.indv_order_point%TYPE,
                -- 発注点（ケース）
    case_order_point                 xxcos_edi_inventory_work.case_order_point%TYPE,
                -- 前月末在庫数量（バラ）
    indv_prev_month_stk_qty          xxcos_edi_inventory_work.indv_prev_month_stk_qty%TYPE,
                -- 前月末在庫数量（ケース）
    case_prev_month_stk_qty          xxcos_edi_inventory_work.case_prev_month_stk_qty%TYPE,
                -- 前月在庫数量（合計） 
    sum_prev_month_stk_qty           xxcos_edi_inventory_work.sum_prev_month_stk_qty%TYPE,
                -- 発注数量（当日、バラ）
    day_indv_order_qty               xxcos_edi_inventory_work.day_indv_order_qty%TYPE,
                -- 発注数量（当日、ケース）
    day_case_order_qty               xxcos_edi_inventory_work.day_case_order_qty%TYPE,
                -- 発注数量（当日、合計）
    day_sum_order_qty                xxcos_edi_inventory_work.day_sum_order_qty%TYPE,
                -- 発注数量（当月、バラ）
    month_indv_order_qty             xxcos_edi_inventory_work.month_indv_order_qty%TYPE,
                -- 発注数量（当月、ケース）
    month_case_order_qty             xxcos_edi_inventory_work.month_case_order_qty%TYPE,
                -- 発注数量（当月、合計）
    month_sum_order_qty              xxcos_edi_inventory_work.month_sum_order_qty%TYPE,
                -- 入庫数量（当日、バラ）
    day_indv_arrival_qty             xxcos_edi_inventory_work.day_indv_arrival_qty%TYPE,
                -- 入庫数量（当日、ケース）
    day_case_arrival_qty             xxcos_edi_inventory_work.day_case_arrival_qty%TYPE,
                -- 入庫数量（当日、合計）
    day_sum_arrival_qty              xxcos_edi_inventory_work.day_sum_arrival_qty%TYPE,
                -- 当月入荷回数         
    month_arrival_count              xxcos_edi_inventory_work.month_arrival_count%TYPE,
                -- 入庫数量（当月、バラ）
    month_indv_arrival_qty           xxcos_edi_inventory_work.month_indv_arrival_qty%TYPE,
                -- 入庫数量（当月、ケース）
    month_case_arrival_qty           xxcos_edi_inventory_work.month_case_arrival_qty%TYPE,
                -- 入庫数量（当月、合計）
    month_sum_arrival_qty            xxcos_edi_inventory_work.month_sum_arrival_qty%TYPE,
                -- 出庫数量（当日、バラ）
    day_indv_shipping_qty            xxcos_edi_inventory_work.day_indv_shipping_qty%TYPE,
                -- 出庫数量（当日、ケース）
    day_case_shipping_qty            xxcos_edi_inventory_work.day_case_shipping_qty%TYPE,
                -- 出庫数量（当日、合計）
    day_sum_shipping_qty             xxcos_edi_inventory_work.day_sum_shipping_qty%TYPE,
                -- 出庫数量（当月、バラ）
    month_indv_shipping_qty          xxcos_edi_inventory_work.month_indv_shipping_qty%TYPE,
                -- 出庫数量（当月、ケース）
    month_case_shipping_qty          xxcos_edi_inventory_work.month_case_shipping_qty%TYPE,
                -- 出庫数量（当月、合計）
    month_sum_shipping_qty           xxcos_edi_inventory_work.month_sum_shipping_qty%TYPE,
                -- 破棄、ロス数量（当日、バラ）
    day_indv_destroy_loss_qty        xxcos_edi_inventory_work.day_indv_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当日、ケース）
    day_case_destroy_loss_qty        xxcos_edi_inventory_work.day_case_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当日、合計）
    day_sum_destroy_loss_qty         xxcos_edi_inventory_work.day_sum_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、バラ）
    month_indv_destroy_loss_qty      xxcos_edi_inventory_work.month_indv_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、ケース）
    month_case_destroy_loss_qty      xxcos_edi_inventory_work.month_case_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、合計）
    month_sum_destroy_loss_qty       xxcos_edi_inventory_work.month_sum_destroy_loss_qty%TYPE,
                -- 不良在庫数量（当日、バラ）
    day_indv_defect_stk_qty          xxcos_edi_inventory_work.day_indv_defect_stk_qty%TYPE,
                -- 不良在庫数量（当日、ケース）
    day_case_defect_stk_qty          xxcos_edi_inventory_work.day_case_defect_stk_qty%TYPE,
                -- 不良在庫数量（当日、合計）
    day_sum_defect_stk_qty           xxcos_edi_inventory_work.day_sum_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、バラ）
    month_indv_defect_stk_qty        xxcos_edi_inventory_work.month_indv_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、ケース）
    month_case_defect_stk_qty        xxcos_edi_inventory_work.month_case_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、合計）
    month_sum_defect_stk_qty         xxcos_edi_inventory_work.month_sum_defect_stk_qty%TYPE,
                -- 不良返品数量（当日、バラ）
    day_indv_defect_return_qty       xxcos_edi_inventory_work.day_indv_defect_return_qty%TYPE,
                -- 不良返品数量（当日、ケース）
    day_case_defect_return_qty       xxcos_edi_inventory_work.day_case_defect_return_qty%TYPE,
                -- 不良返品数量（当日、合計）
    day_sum_defect_return_qty        xxcos_edi_inventory_work.day_sum_defect_return_qty%TYPE,
                -- 不良返品数量（当月、バラ）
    month_indv_defect_return_qty     xxcos_edi_inventory_work.month_indv_defect_return_qty%TYPE,
                -- 不良返品数量（当月、ケース）
    month_case_defect_return_qty     xxcos_edi_inventory_work.month_case_defect_return_qty%TYPE,
                -- 不良返品数量（当月、合計）
    month_sum_defect_return_qty      xxcos_edi_inventory_work.month_sum_defect_return_qty%TYPE,
                -- 不良返品受入（当日、バラ）
    day_indv_defect_return_rcpt      xxcos_edi_inventory_work.day_indv_defect_return_rcpt%TYPE,
                -- 不良返品受入（当日、ケース）
    day_case_defect_return_rcpt      xxcos_edi_inventory_work.day_case_defect_return_rcpt%TYPE,
                -- 不良返品受入（当日、合計）
    day_sum_defect_return_rcpt       xxcos_edi_inventory_work.day_sum_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、バラ）
    month_indv_defect_return_rcpt      xxcos_edi_inventory_work.month_indv_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、ケース）
    month_case_defect_return_rcpt      xxcos_edi_inventory_work.month_case_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、合計）
    month_sum_defect_return_rcpt       xxcos_edi_inventory_work.month_sum_defect_return_rcpt%TYPE,
                -- 不良返品発送（当日、バラ）
    day_indv_defect_return_send        xxcos_edi_inventory_work.day_indv_defect_return_send%TYPE,
                -- 不良返品発送（当日、ケース）
    day_case_defect_return_send        xxcos_edi_inventory_work.day_case_defect_return_send%TYPE,
                -- 不良返品発送（当日、合計）
    day_sum_defect_return_send         xxcos_edi_inventory_work.day_sum_defect_return_send%TYPE,
                -- 不良返品発送（当月、バラ）
    month_indv_defect_return_send      xxcos_edi_inventory_work.month_indv_defect_return_send%TYPE,
                -- 不良返品発送（当月、ケース）
    month_case_defect_return_send      xxcos_edi_inventory_work.month_case_defect_return_send%TYPE,
                -- 不良返品発送（当月、合計）
    month_sum_defect_return_send       xxcos_edi_inventory_work.month_sum_defect_return_send%TYPE,
                -- 良品返品受入（当日、バラ）
    day_indv_quality_return_rcpt       xxcos_edi_inventory_work.day_indv_quality_return_rcpt%TYPE,
                -- 良品返品受入（当日、ケース）
    day_case_quality_return_rcpt       xxcos_edi_inventory_work.day_case_quality_return_rcpt%TYPE,
                -- 良品返品受入（当日、合計）
    day_sum_quality_return_rcpt        xxcos_edi_inventory_work.day_sum_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、バラ）
    month_indv_quality_return_rcpt     xxcos_edi_inventory_work.month_indv_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、ケース）
    month_case_quality_return_rcpt     xxcos_edi_inventory_work.month_case_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、合計）
    month_sum_quality_return_rcpt      xxcos_edi_inventory_work.month_sum_quality_return_rcpt%TYPE,
                -- 良品返品発送（当日、バラ）
    day_indv_quality_return_send       xxcos_edi_inventory_work.day_indv_quality_return_send%TYPE,
                -- 良品返品発送（当日、ケース）
    day_case_quality_return_send       xxcos_edi_inventory_work.day_case_quality_return_send%TYPE,
                -- 良品返品発送（当日、合計）
    day_sum_quality_return_send        xxcos_edi_inventory_work.day_sum_quality_return_send%TYPE,
                -- 良品返品発送（当月、バラ）
    month_indv_quality_return_send     xxcos_edi_inventory_work.month_indv_quality_return_send%TYPE,
                -- 良品返品発送（当月、ケース）
    month_case_quality_return_send     xxcos_edi_inventory_work.month_case_quality_return_send%TYPE,
                -- 良品返品発送（当月、合計）
    month_sum_quality_return_send      xxcos_edi_inventory_work.month_sum_quality_return_send%TYPE,
                -- 棚卸差異（当日、バラ）
    day_indv_invent_difference         xxcos_edi_inventory_work.day_indv_invent_difference%TYPE,
                -- 棚卸差異（当日、ケース）
    day_case_invent_difference         xxcos_edi_inventory_work.day_case_invent_difference%TYPE,
                -- 棚卸差異（当日、合計）
    day_sum_invent_difference          xxcos_edi_inventory_work.day_sum_invent_difference%TYPE,
                -- 棚卸差異（当月、バラ）
    month_indv_invent_difference       xxcos_edi_inventory_work.month_indv_invent_difference%TYPE,
                -- 棚卸差異（当月、ケース）
    month_case_invent_difference       xxcos_edi_inventory_work.month_case_invent_difference%TYPE,
                -- 棚卸差異（当月、合計） 
    month_sum_invent_difference        xxcos_edi_inventory_work.month_sum_invent_difference%TYPE,
                -- 在庫数量（当日、バラ） 
    day_indv_stk_qty                   xxcos_edi_inventory_work.day_indv_stk_qty%TYPE,
                -- 在庫数量（当日、ケース）
    day_case_stk_qty                   xxcos_edi_inventory_work.day_case_stk_qty%TYPE,
                -- 在庫数量（当日、合計） 
    day_sum_stk_qty                    xxcos_edi_inventory_work.day_sum_stk_qty%TYPE,
                -- 在庫数量（当月、バラ） 
    month_indv_stk_qty                 xxcos_edi_inventory_work.month_indv_stk_qty%TYPE,
                -- 在庫数量（当月、ケース）
    month_case_stk_qty                 xxcos_edi_inventory_work.month_case_stk_qty%TYPE,
                -- 在庫数量（当月、合計） 
    month_sum_stk_qty                  xxcos_edi_inventory_work.month_sum_stk_qty%TYPE,
                -- 保留在庫数（当日、バラ）
    day_indv_reserved_stk_qty          xxcos_edi_inventory_work.day_indv_reserved_stk_qty%TYPE,
                -- 保留在庫数（当日、ケース）
    day_case_reserved_stk_qty          xxcos_edi_inventory_work.day_case_reserved_stk_qty%TYPE,
                -- 保留在庫数（当日、合計） 
    day_sum_reserved_stk_qty           xxcos_edi_inventory_work.day_sum_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、バラ） 
    month_indv_reserved_stk_qty        xxcos_edi_inventory_work.month_indv_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、ケース）
    month_case_reserved_stk_qty        xxcos_edi_inventory_work.month_case_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、合計）
    month_sum_reserved_stk_qty         xxcos_edi_inventory_work.month_sum_reserved_stk_qty%TYPE,
                -- 商流在庫数量（当日、バラ）
    day_indv_cd_stk_qty                xxcos_edi_inventory_work.day_indv_cd_stk_qty%TYPE,
                -- 商流在庫数量（当日、ケース）
    day_case_cd_stk_qty                xxcos_edi_inventory_work.day_case_cd_stk_qty%TYPE,
                -- 商流在庫数量（当日、合計）
    day_sum_cd_stk_qty                 xxcos_edi_inventory_work.day_sum_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、バラ） 
    month_indv_cd_stk_qty              xxcos_edi_inventory_work.month_indv_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、ケース）
    month_case_cd_stk_qty              xxcos_edi_inventory_work.month_case_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、合計）
    month_sum_cd_stk_qty               xxcos_edi_inventory_work.month_sum_cd_stk_qty%TYPE,
                -- 積送在庫数量（当日、バラ） 
    day_indv_cargo_stk_qty             xxcos_edi_inventory_work.day_indv_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当日、ケース）
    day_case_cargo_stk_qty             xxcos_edi_inventory_work.day_case_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当日、合計）
    day_sum_cargo_stk_qty              xxcos_edi_inventory_work.day_sum_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、バラ） 
    month_indv_cargo_stk_qty           xxcos_edi_inventory_work.month_indv_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、ケース）
    month_case_cargo_stk_qty           xxcos_edi_inventory_work.month_case_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、合計） 
    month_sum_cargo_stk_qty            xxcos_edi_inventory_work.month_sum_cargo_stk_qty%TYPE,
                -- 調整在庫数量（当日、バラ） 
    day_indv_adjustment_stk_qty        xxcos_edi_inventory_work.day_indv_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当日、ケース）
    day_case_adjustment_stk_qty        xxcos_edi_inventory_work.day_case_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当日、合計） 
    day_sum_adjustment_stk_qty         xxcos_edi_inventory_work.day_sum_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、バラ） 
    month_indv_adjustment_stk_qty      xxcos_edi_inventory_work.month_indv_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、ケース）
    month_case_adjustment_stk_qty      xxcos_edi_inventory_work.month_case_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、合計） 
    month_sum_adjustment_stk_qty       xxcos_edi_inventory_work.month_sum_adjustment_stk_qty%TYPE,
                -- 未出荷数量（当日、バラ）  
    day_indv_still_shipping_qty        xxcos_edi_inventory_work.day_indv_still_shipping_qty%TYPE,
                -- 未出荷数量（当日、ケース）
    day_case_still_shipping_qty        xxcos_edi_inventory_work.day_case_still_shipping_qty%TYPE,
                -- 未出荷数量（当日、合計）  
    day_sum_still_shipping_qty         xxcos_edi_inventory_work.day_sum_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、バラ）   
    month_indv_still_shipping_qty      xxcos_edi_inventory_work.month_indv_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、ケース） 
    month_case_still_shipping_qty      xxcos_edi_inventory_work.month_case_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、合計） 
    month_sum_still_shipping_qty       xxcos_edi_inventory_work.month_sum_still_shipping_qty%TYPE,
                -- 総在庫数量（バラ）      
    indv_all_stk_qty                   xxcos_edi_inventory_work.indv_all_stk_qty%TYPE,
                -- 総在庫数量（ケース）
    case_all_stk_qty                   xxcos_edi_inventory_work.case_all_stk_qty%TYPE,
                -- 総在庫数量（合計）       
    sum_all_stk_qty                    xxcos_edi_inventory_work.sum_all_stk_qty%TYPE,
                -- 当月引当回数               
    month_draw_count                   xxcos_edi_inventory_work.month_draw_count%TYPE,
                -- 引当可能数量（当日、バラ） 
    day_indv_draw_possible_qty         xxcos_edi_inventory_work.day_indv_draw_possible_qty%TYPE,
                -- 引当可能数量（当日、ケース）
    day_case_draw_possible_qty         xxcos_edi_inventory_work.day_case_draw_possible_qty%TYPE,
                -- 引当可能数量（当日、合計）
    day_sum_draw_possible_qty          xxcos_edi_inventory_work.day_sum_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、バラ） 
    month_indv_draw_possible_qty       xxcos_edi_inventory_work.month_indv_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、ケース）
    month_case_draw_possible_qty       xxcos_edi_inventory_work.month_case_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、合計） 
    month_sum_draw_possible_qty        xxcos_edi_inventory_work.month_sum_draw_possible_qty%TYPE,
                -- 引当不能数（当日、バラ）  
    day_indv_draw_impossible_qty       xxcos_edi_inventory_work.day_indv_draw_impossible_qty%TYPE,
                -- 引当不能数（当日、ケース） 
    day_case_draw_impossible_qty       xxcos_edi_inventory_work.day_case_draw_impossible_qty%TYPE,
                -- 引当不能数（当日、合計） 
    day_sum_draw_impossible_qty        xxcos_edi_inventory_work.day_sum_draw_impossible_qty%TYPE,
                -- 在庫金額（当日）      
    day_stk_amt                        xxcos_edi_inventory_work.day_stk_amt%TYPE,
                -- 在庫金額（当月）       
    month_stk_amt                      xxcos_edi_inventory_work.month_stk_amt%TYPE,
                -- 備考                       
    remarks                            xxcos_edi_inventory_work.remarks%TYPE,
                -- チェーン店固有エリア（明細）
    chain_peculiar_area_line           xxcos_edi_inventory_work.chain_peculiar_area_line%TYPE,
                -- 伝票計）在庫数量合計（当日、バラ）  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory_work.invoice_day_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、ケース）
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory_work.invoice_day_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、合計）  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory_work.invoice_day_sum_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、バラ）  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory_work.invoice_month_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、ケース）
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory_work.invoice_month_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、合計）  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory_work.invoice_month_sum_sum_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、バラ） 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory_work.invoice_day_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、ケース）
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory_work.invoice_day_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、合計）  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory_work.invoice_day_sum_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、バラ）  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory_work.invoice_month_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、ケース）
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory_work.invoice_month_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、合計）  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory_work.invoice_month_sum_cd_stk_qty%TYPE,
                -- 伝票計）在庫金額（当日）            
    invoice_day_stk_amt                xxcos_edi_inventory_work.invoice_day_stk_amt%TYPE,
                -- 伝票計）在庫金額（当月）            
    invoice_month_stk_amt              xxcos_edi_inventory_work.invoice_month_stk_amt%TYPE,
                -- 正販金額合計                        
    regular_sell_amt_sum               xxcos_edi_inventory_work.regular_sell_amt_sum%TYPE,
                -- 割戻し金額合計                      
    rebate_amt_sum                     xxcos_edi_inventory_work.rebate_amt_sum%TYPE,
                -- 回収容器金額合計                   
    collect_bottle_amt_sum             xxcos_edi_inventory_work.collect_bottle_amt_sum%TYPE,
                -- チェーン店固有エリア（フッター）    
    chain_peculiar_area_footer         xxcos_edi_inventory_work.chain_peculiar_area_footer%TYPE,
                -- ステータス                          
    err_status                         xxcos_edi_inventory_work.err_status%TYPE,
/* 2011/07/28 Ver1.8 Mod Start */
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add Start
--                -- EDI受信日
--    creation_date                      xxcos_edi_inventory_work.creation_date%TYPE
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add End
                -- EDI受信日
    creation_date                      xxcos_edi_inventory_work.creation_date%TYPE,
/* 2011/07/28 Ver1.8 Mod End   */
/* 2011/07/28 Ver1.8 Add Start */
                -- 流通ＢＭＳヘッダデータ
    bms_header_data                    xxcos_edi_inventory_work.bms_header_data%TYPE,
                -- 流通ＢＭＳ明細データ
    bms_line_data                      xxcos_edi_inventory_work.bms_line_data%TYPE
/* 2011/07/28 Ver1.8 Add End   */
  );
  --
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_tab_ediinv_work_data IS TABLE OF g_rec_ediinv_work_data INDEX BY PLS_INTEGER;
  -- ===============================
  --  EDI在庫情報ワークテーブル
  -- ===============================
  gt_ediinv_work_data                 g_tab_ediinv_work_data;

  --
  -- ===============================
  -- 顧客データレコード型
  -- ===============================
  TYPE g_req_cust_acc_data_rtype IS RECORD(
    account_number    hz_cust_accounts.account_number%TYPE,       -- 顧客マスタ.顧客コード
    chain_store_code  xxcmm_cust_accounts.chain_store_code%TYPE,  -- チェーン店コード(EDI)
    store_code        xxcmm_cust_accounts.store_code%TYPE         -- 店舗コード
  );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 顧客データ テーブル型
  -- ===============================
  TYPE g_req_cust_acc_data_ttype IS TABLE OF g_req_cust_acc_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_cust_acc_data  g_req_cust_acc_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_prf_edi_del_date        VARCHAR2(50) DEFAULT NULL;  -- XXCOS:EDI情報削除期間
  gv_prf_case_code           VARCHAR2(50) DEFAULT NULL;  -- XXCOS:ケース単位コード
  gv_prf_orga_code           VARCHAR2(50) DEFAULT NULL;  -- XXCOI:在庫組織コード
  gv_prf_orga_id             VARCHAR2(50) DEFAULT NULL;  -- XXCOS:在庫組織ID
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod Start
--  gv_inv_invoice_number_key  VARCHAR2(12) DEFAULT NULL;  -- 伝票番号 
  gv_inv_invoice_number_key  VARCHAR2(20) DEFAULT NULL;  -- 伝票番号 
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
  gv_err_ediinv_work_flag    VARCHAR2(1)  DEFAULT NULL;  -- 在庫情報エラーフラグ 
  gv_dummy_item_code         mtl_system_items_b.segment1%TYPE  DEFAULT NULL;  -- ダミー品目設定有無
  --
  --* -------------------------------------------------------------------------------------------
  -- EDI在庫情報テーブルデータ集計用変数(xxcos_edi_inventory)
  TYPE g_sum_edi_inv_data_rtype IS RECORD(
                -- 伝票番号
    invoice_number                     xxcos_edi_inventory.invoice_number%TYPE,
                -- 伝票計）在庫数量合計（当日、バラ）  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory.invoice_day_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、ケース）
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory.invoice_day_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、合計）  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory.invoice_day_sum_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、バラ）  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory.invoice_month_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、ケース）
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory.invoice_month_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、合計）  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory.invoice_month_sum_sum_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、バラ） 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory.invoice_day_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、ケース）
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory.invoice_day_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、合計）  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory.invoice_day_sum_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、バラ）  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory.invoice_month_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、ケース）
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory.invoice_month_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、合計）  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory.invoice_month_sum_cd_stk_qty%TYPE,
                -- 伝票計）在庫金額（当日）            
    invoice_day_stk_amt                xxcos_edi_inventory.invoice_day_stk_amt%TYPE,
                -- 伝票計）在庫金額（当月）            
    invoice_month_stk_amt              xxcos_edi_inventory.invoice_month_stk_amt%TYPE
  );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- EDI在庫情報データ テーブル型
  TYPE g_sum_edi_inv_data_ttype IS TABLE OF g_sum_edi_inv_data_rtype INDEX BY BINARY_INTEGER;
  gt_sum_edi_inv_data  g_sum_edi_inv_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- EDI在庫情報テーブルデータ登録用変数(xxcos_edi_inventory)
  TYPE g_req_edi_inv_data_rtype IS RECORD(
                -- 在庫情報ID
    stk_info_id                      xxcos_edi_inventory.stk_info_id%TYPE,
                -- 媒体区分
    medium_class                     xxcos_edi_inventory.medium_class%TYPE,
                -- データ種コード
    data_type_code                   xxcos_edi_inventory.data_type_code%TYPE,
                -- ファイルＮｏ
    file_no                          xxcos_edi_inventory.file_no%TYPE,
                -- 情報区分
    info_class                       xxcos_edi_inventory.info_class%TYPE,
                -- 処理日
    process_date                     xxcos_edi_inventory.process_date%TYPE,
                -- 処理時刻
    process_time                     xxcos_edi_inventory.process_time%TYPE,
                -- 拠点（部門）コード
    base_code                        xxcos_edi_inventory.base_code%TYPE,
                -- 拠点名（正式名）
    base_name                        xxcos_edi_inventory.base_name%TYPE,
                -- 拠点名（カナ）
    base_name_alt                    xxcos_edi_inventory.base_name_alt%TYPE,
                -- ＥＤＩチェーン店コード
    edi_chain_code                   xxcos_edi_inventory.edi_chain_code%TYPE,
                -- ＥＤＩチェーン店名（漢字）
    edi_chain_name                   xxcos_edi_inventory.edi_chain_name%TYPE,
                -- ＥＤＩチェーン店名（カナ）
    edi_chain_name_alt               xxcos_edi_inventory.edi_chain_name_alt%TYPE,
                -- 帳票コード
    report_code                      xxcos_edi_inventory.report_code%TYPE,
                -- 帳票表示名
    report_show_name                 xxcos_edi_inventory.report_show_name%TYPE,
                -- 顧客コード1
    customer_code                    xxcos_edi_inventory.customer_code%TYPE,
                -- 顧客名（漢字）
    customer_name                    xxcos_edi_inventory.customer_name%TYPE,
                -- 顧客名（カナ）
    customer_name_alt                xxcos_edi_inventory.customer_name_alt%TYPE,
                -- 社コード
    company_code                     xxcos_edi_inventory.company_code%TYPE,
                -- 社名（カナ）
    company_name_alt                 xxcos_edi_inventory.company_name_alt%TYPE,
                -- 店コード
    shop_code                        xxcos_edi_inventory.shop_code%TYPE, 
                -- 店名（カナ）
    shop_name_alt                    xxcos_edi_inventory.shop_name_alt%TYPE,
                -- 納入センターコード
    delivery_center_code             xxcos_edi_inventory.delivery_center_code%TYPE,
                -- 納入センター名（漢字）
    delivery_center_name             xxcos_edi_inventory.delivery_center_name%TYPE,
                -- 納入センター名（カナ）
    delivery_center_name_alt         xxcos_edi_inventory.delivery_center_name_alt%TYPE,
                --倉庫コード
    whse_code                        xxcos_edi_inventory.whse_code%TYPE,
                --倉庫名
    whse_name                        xxcos_edi_inventory.whse_name%TYPE,
                --検品担当者名（漢字）
    inspect_charge_name              xxcos_edi_inventory.inspect_charge_name%TYPE,
                --検品担当者名（カナ）
    inspect_charge_name_alt          xxcos_edi_inventory.inspect_charge_name_alt%TYPE,
                --返品担当者名（漢字）
    return_charge_name               xxcos_edi_inventory.return_charge_name%TYPE,
                --返品担当者名（カナ）
    return_charge_name_alt           xxcos_edi_inventory.return_charge_name_alt%TYPE,
                --受領担当者名（漢字）
    receive_charge_name              xxcos_edi_inventory.receive_charge_name%TYPE,
                --受領担当者名（カナ）
    receive_charge_name_alt          xxcos_edi_inventory.receive_charge_name_alt%TYPE,
                -- 発注日
    order_date                       xxcos_edi_inventory.order_date%TYPE,
                -- センター納品日
    center_delivery_date             xxcos_edi_inventory.center_delivery_date%TYPE,
                --センター実納品日
    center_result_delivery_date      xxcos_edi_inventory.center_result_delivery_date%TYPE,
                --センター出庫日
    center_shipping_date             xxcos_edi_inventory.center_shipping_date%TYPE,
                --センター実出庫日
    center_result_shipping_date      xxcos_edi_inventory.center_result_shipping_date%TYPE,
                -- データ作成日（ＥＤＩデータ中）
    data_creation_date_edi_data      xxcos_edi_inventory.data_creation_date_edi_data%TYPE,
                -- データ作成時刻（ＥＤＩデータ中）
    data_creation_time_edi_data      xxcos_edi_inventory.data_creation_time_edi_data%TYPE,
                --在庫日付
    stk_date                         xxcos_edi_inventory.stk_date%TYPE,
                --提供企業取引先コード区分
    offer_vendor_code_class          xxcos_edi_inventory.offer_vendor_code_class%TYPE,
                --倉庫取引先コード区分
    whse_vendor_code_class           xxcos_edi_inventory.whse_vendor_code_class%TYPE,
                --提供サイクル区分
    offer_cycle_class                xxcos_edi_inventory.offer_cycle_class%TYPE,
                --在庫種類
    stk_type                         xxcos_edi_inventory.stk_type%TYPE,
                --日本語区分
    japanese_class                   xxcos_edi_inventory.japanese_class%TYPE,
                --倉庫区分
    whse_class                       xxcos_edi_inventory.whse_class%TYPE,
                -- 取引先コード
    vendor_code                      xxcos_edi_inventory.vendor_code%TYPE,
                -- 取引先名（漢字）
    vendor_name                      xxcos_edi_inventory.vendor_name%TYPE,
                -- 取引先名（カナ）
    vendor_name_alt                  xxcos_edi_inventory.vendor_name_alt%TYPE,
                -- チェックデジット有無区分
    check_digit_class                xxcos_edi_inventory.check_digit_class%TYPE,
                -- 伝票番号
    invoice_number                   xxcos_edi_inventory.invoice_number%TYPE,
                -- チェックデジット
    check_digit                      xxcos_edi_inventory.check_digit%TYPE,
                -- チェーン店固有エリア（ヘッダー）
    chain_peculiar_area_header       xxcos_edi_inventory.chain_peculiar_area_header%TYPE,
                -- 商品コード（伊藤園）
    product_code_itouen              xxcos_edi_inventory.product_code_itouen%TYPE,
                --商品コード（先方）
    product_code_other_party         xxcos_edi_inventory.product_code_other_party%TYPE,
                -- ＪＡＮコード
    jan_code                         xxcos_edi_inventory.jan_code%TYPE,
                -- ＩＴＦコード
    itf_code                         xxcos_edi_inventory.itf_code%TYPE,
                -- 商品名（漢字）
    product_name                     xxcos_edi_inventory.product_name%TYPE,
                -- 商品名（カナ）
    product_name_alt                 xxcos_edi_inventory.product_name_alt%TYPE,
                -- 商品区分
    prod_class                       xxcos_edi_inventory.prod_class%TYPE,
                -- 適用品質区分
    active_quality_class             xxcos_edi_inventory.active_quality_class%TYPE,
                -- 入数
    qty_in_case                      xxcos_edi_inventory.qty_in_case%TYPE,
                -- 単位
    uom_code                         xxcos_edi_inventory.uom_code%TYPE,
                -- 一日平均出荷数量
    day_average_shipping_qty         xxcos_edi_inventory.day_average_shipping_qty%TYPE,
                -- 在庫種別コード
    stk_type_code                    xxcos_edi_inventory.stk_type_code%TYPE,
                -- 最終入荷日
    last_arrival_date                xxcos_edi_inventory.last_arrival_date%TYPE,
                -- 賞味期限
    use_by_date                      xxcos_edi_inventory.use_by_date%TYPE,
                -- 製造日
    product_date                     xxcos_edi_inventory.product_date%TYPE,
                -- 上限在庫（ケース）
    upper_limit_stk_case             xxcos_edi_inventory.upper_limit_stk_case%TYPE,
                -- 上限在庫（バラ）
    upper_limit_stk_indv             xxcos_edi_inventory.upper_limit_stk_indv%TYPE,
                -- 発注点（バラ） 
    indv_order_point                 xxcos_edi_inventory.indv_order_point%TYPE,
                -- 発注点（ケース）
    case_order_point                 xxcos_edi_inventory.case_order_point%TYPE,
                -- 前月末在庫数量（バラ）
    indv_prev_month_stk_qty          xxcos_edi_inventory.indv_prev_month_stk_qty%TYPE,
                -- 前月末在庫数量（ケース）
    case_prev_month_stk_qty          xxcos_edi_inventory.case_prev_month_stk_qty%TYPE,
                -- 前月在庫数量（合計） 
    sum_prev_month_stk_qty           xxcos_edi_inventory.sum_prev_month_stk_qty%TYPE,
                -- 発注数量（当日、バラ）
    day_indv_order_qty               xxcos_edi_inventory.day_indv_order_qty%TYPE,
                -- 発注数量（当日、ケース）
    day_case_order_qty               xxcos_edi_inventory.day_case_order_qty%TYPE,
                -- 発注数量（当日、合計）
    day_sum_order_qty                xxcos_edi_inventory.day_sum_order_qty%TYPE,
                -- 発注数量（当月、バラ）
    month_indv_order_qty             xxcos_edi_inventory.month_indv_order_qty%TYPE,
                -- 発注数量（当月、ケース）
    month_case_order_qty             xxcos_edi_inventory.month_case_order_qty%TYPE,
                -- 発注数量（当月、合計）
    month_sum_order_qty              xxcos_edi_inventory.month_sum_order_qty%TYPE,
                -- 入庫数量（当日、バラ）
    day_indv_arrival_qty             xxcos_edi_inventory.day_indv_arrival_qty%TYPE,
                -- 入庫数量（当日、ケース）
    day_case_arrival_qty             xxcos_edi_inventory.day_case_arrival_qty%TYPE,
                -- 入庫数量（当日、合計）
    day_sum_arrival_qty              xxcos_edi_inventory.day_sum_arrival_qty%TYPE,
                -- 当月入荷回数         
    month_arrival_count              xxcos_edi_inventory.month_arrival_count%TYPE,
                -- 入庫数量（当月、バラ）
    month_indv_arrival_qty           xxcos_edi_inventory.month_indv_arrival_qty%TYPE,
                -- 入庫数量（当月、ケース）
    month_case_arrival_qty           xxcos_edi_inventory.month_case_arrival_qty%TYPE,
                -- 入庫数量（当月、合計）
    month_sum_arrival_qty            xxcos_edi_inventory.month_sum_arrival_qty%TYPE,
                -- 出庫数量（当日、バラ）
    day_indv_shipping_qty            xxcos_edi_inventory_work.day_indv_shipping_qty%TYPE,
                -- 出庫数量（当日、ケース）
    day_case_shipping_qty            xxcos_edi_inventory.day_case_shipping_qty%TYPE,
                -- 出庫数量（当日、合計）
    day_sum_shipping_qty             xxcos_edi_inventory.day_sum_shipping_qty%TYPE,
                -- 出庫数量（当月、バラ）
    month_indv_shipping_qty          xxcos_edi_inventory.month_indv_shipping_qty%TYPE,
                -- 出庫数量（当月、ケース）
    month_case_shipping_qty          xxcos_edi_inventory.month_case_shipping_qty%TYPE,
                -- 出庫数量（当月、合計）
    month_sum_shipping_qty           xxcos_edi_inventory.month_sum_shipping_qty%TYPE,
                -- 破棄、ロス数量（当日、バラ）
    day_indv_destroy_loss_qty        xxcos_edi_inventory.day_indv_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当日、ケース）
    day_case_destroy_loss_qty        xxcos_edi_inventory.day_case_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当日、合計）
    day_sum_destroy_loss_qty         xxcos_edi_inventory.day_sum_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、バラ）
    month_indv_destroy_loss_qty      xxcos_edi_inventory.month_indv_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、ケース）
    month_case_destroy_loss_qty      xxcos_edi_inventory.month_case_destroy_loss_qty%TYPE,
                -- 破棄、ロス数量（当月、合計）
    month_sum_destroy_loss_qty       xxcos_edi_inventory.month_sum_destroy_loss_qty%TYPE,
                -- 不良在庫数量（当日、バラ）
    day_indv_defect_stk_qty          xxcos_edi_inventory.day_indv_defect_stk_qty%TYPE,
                -- 不良在庫数量（当日、ケース）
    day_case_defect_stk_qty          xxcos_edi_inventory.day_case_defect_stk_qty%TYPE,
                -- 不良在庫数量（当日、合計）
    day_sum_defect_stk_qty           xxcos_edi_inventory.day_sum_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、バラ）
    month_indv_defect_stk_qty        xxcos_edi_inventory.month_indv_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、ケース）
    month_case_defect_stk_qty        xxcos_edi_inventory.month_case_defect_stk_qty%TYPE,
                -- 不良在庫数量（当月、合計）
    month_sum_defect_stk_qty         xxcos_edi_inventory.month_sum_defect_stk_qty%TYPE,
                -- 不良返品数量（当日、バラ）
    day_indv_defect_return_qty       xxcos_edi_inventory.day_indv_defect_return_qty%TYPE,
                -- 不良返品数量（当日、ケース）
    day_case_defect_return_qty       xxcos_edi_inventory.day_case_defect_return_qty%TYPE,
                -- 不良返品数量（当日、合計）
    day_sum_defect_return_qty        xxcos_edi_inventory.day_sum_defect_return_qty%TYPE,
                -- 不良返品数量（当月、バラ）
    month_indv_defect_return_qty     xxcos_edi_inventory.month_indv_defect_return_qty%TYPE,
                -- 不良返品数量（当月、ケース）
    month_case_defect_return_qty     xxcos_edi_inventory.month_case_defect_return_qty%TYPE,
                -- 不良返品数量（当月、合計）
    month_sum_defect_return_qty      xxcos_edi_inventory.month_sum_defect_return_qty%TYPE,
                -- 不良返品受入（当日、バラ）
    day_indv_defect_return_rcpt      xxcos_edi_inventory.day_indv_defect_return_rcpt%TYPE,
                -- 不良返品受入（当日、ケース）
    day_case_defect_return_rcpt      xxcos_edi_inventory.day_case_defect_return_rcpt%TYPE,
                -- 不良返品受入（当日、合計）
    day_sum_defect_return_rcpt       xxcos_edi_inventory.day_sum_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、バラ）
    month_indv_defect_return_rcpt      xxcos_edi_inventory.month_indv_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、ケース）
    month_case_defect_return_rcpt      xxcos_edi_inventory.month_case_defect_return_rcpt%TYPE,
                -- 不良返品受入（当月、合計）
    month_sum_defect_return_rcpt       xxcos_edi_inventory.month_sum_defect_return_rcpt%TYPE,
                -- 不良返品発送（当日、バラ）
    day_indv_defect_return_send        xxcos_edi_inventory.day_indv_defect_return_send%TYPE,
                -- 不良返品発送（当日、ケース）
    day_case_defect_return_send        xxcos_edi_inventory.day_case_defect_return_send%TYPE,
                -- 不良返品発送（当日、合計）
    day_sum_defect_return_send         xxcos_edi_inventory.day_sum_defect_return_send%TYPE,
                -- 不良返品発送（当月、バラ）
    month_indv_defect_return_send      xxcos_edi_inventory.month_indv_defect_return_send%TYPE,
                -- 不良返品発送（当月、ケース）
    month_case_defect_return_send      xxcos_edi_inventory.month_case_defect_return_send%TYPE,
                -- 不良返品発送（当月、合計）
    month_sum_defect_return_send       xxcos_edi_inventory.month_sum_defect_return_send%TYPE,
                -- 良品返品受入（当日、バラ）
    day_indv_quality_return_rcpt       xxcos_edi_inventory.day_indv_quality_return_rcpt%TYPE,
                -- 良品返品受入（当日、ケース）
    day_case_quality_return_rcpt       xxcos_edi_inventory.day_case_quality_return_rcpt%TYPE,
                -- 良品返品受入（当日、合計）
    day_sum_quality_return_rcpt        xxcos_edi_inventory.day_sum_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、バラ）
    month_indv_quality_return_rcpt     xxcos_edi_inventory.month_indv_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、ケース）
    month_case_quality_return_rcpt     xxcos_edi_inventory.month_case_quality_return_rcpt%TYPE,
                -- 良品返品受入（当月、合計）
    month_sum_quality_return_rcpt      xxcos_edi_inventory.month_sum_quality_return_rcpt%TYPE,
                -- 良品返品発送（当日、バラ）
    day_indv_quality_return_send       xxcos_edi_inventory.day_indv_quality_return_send%TYPE,
                -- 良品返品発送（当日、ケース）
    day_case_quality_return_send       xxcos_edi_inventory.day_case_quality_return_send%TYPE,
                -- 良品返品発送（当日、合計）
    day_sum_quality_return_send        xxcos_edi_inventory.day_sum_quality_return_send%TYPE,
                -- 良品返品発送（当月、バラ）
    month_indv_quality_return_send     xxcos_edi_inventory.month_indv_quality_return_send%TYPE,
                -- 良品返品発送（当月、ケース）
    month_case_quality_return_send     xxcos_edi_inventory.month_case_quality_return_send%TYPE,
                -- 良品返品発送（当月、合計）
    month_sum_quality_return_send      xxcos_edi_inventory.month_sum_quality_return_send%TYPE,
                -- 棚卸差異（当日、バラ）
    day_indv_invent_difference         xxcos_edi_inventory.day_indv_invent_difference%TYPE,
                -- 棚卸差異（当日、ケース）
    day_case_invent_difference         xxcos_edi_inventory.day_case_invent_difference%TYPE,
                -- 棚卸差異（当日、合計）
    day_sum_invent_difference          xxcos_edi_inventory.day_sum_invent_difference%TYPE,
                -- 棚卸差異（当月、バラ）
    month_indv_invent_difference       xxcos_edi_inventory.month_indv_invent_difference%TYPE,
                -- 棚卸差異（当月、ケース）
    month_case_invent_difference       xxcos_edi_inventory.month_case_invent_difference%TYPE,
                -- 棚卸差異（当月、合計） 
    month_sum_invent_difference        xxcos_edi_inventory.month_sum_invent_difference%TYPE,
                -- 在庫数量（当日、バラ） 
    day_indv_stk_qty                   xxcos_edi_inventory.day_indv_stk_qty%TYPE,
                -- 在庫数量（当日、ケース）
    day_case_stk_qty                   xxcos_edi_inventory.day_case_stk_qty%TYPE,
                -- 在庫数量（当日、合計） 
    day_sum_stk_qty                    xxcos_edi_inventory.day_sum_stk_qty%TYPE,
                -- 在庫数量（当月、バラ） 
    month_indv_stk_qty                 xxcos_edi_inventory.month_indv_stk_qty%TYPE,
                -- 在庫数量（当月、ケース）
    month_case_stk_qty                 xxcos_edi_inventory.month_case_stk_qty%TYPE,
                -- 在庫数量（当月、合計） 
    month_sum_stk_qty                  xxcos_edi_inventory.month_sum_stk_qty%TYPE,
                -- 保留在庫数（当日、バラ）
    day_indv_reserved_stk_qty          xxcos_edi_inventory.day_indv_reserved_stk_qty%TYPE,
                -- 保留在庫数（当日、ケース）
    day_case_reserved_stk_qty          xxcos_edi_inventory.day_case_reserved_stk_qty%TYPE,
                -- 保留在庫数（当日、合計） 
    day_sum_reserved_stk_qty           xxcos_edi_inventory.day_sum_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、バラ） 
    month_indv_reserved_stk_qty        xxcos_edi_inventory.month_indv_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、ケース）
    month_case_reserved_stk_qty        xxcos_edi_inventory.month_case_reserved_stk_qty%TYPE,
                -- 保留在庫数（当月、合計）
    month_sum_reserved_stk_qty         xxcos_edi_inventory.month_sum_reserved_stk_qty%TYPE,
                -- 商流在庫数量（当日、バラ）
    day_indv_cd_stk_qty                xxcos_edi_inventory.day_indv_cd_stk_qty%TYPE,
                -- 商流在庫数量（当日、ケース）
    day_case_cd_stk_qty                xxcos_edi_inventory.day_case_cd_stk_qty%TYPE,
                -- 商流在庫数量（当日、合計）
    day_sum_cd_stk_qty                 xxcos_edi_inventory.day_sum_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、バラ） 
    month_indv_cd_stk_qty              xxcos_edi_inventory.month_indv_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、ケース）
    month_case_cd_stk_qty              xxcos_edi_inventory.month_case_cd_stk_qty%TYPE,
                -- 商流在庫数量（当月、合計）
    month_sum_cd_stk_qty               xxcos_edi_inventory.month_sum_cd_stk_qty%TYPE,
                -- 積送在庫数量（当日、バラ） 
    day_indv_cargo_stk_qty             xxcos_edi_inventory.day_indv_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当日、ケース）
    day_case_cargo_stk_qty             xxcos_edi_inventory.day_case_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当日、合計）
    day_sum_cargo_stk_qty              xxcos_edi_inventory.day_sum_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、バラ） 
    month_indv_cargo_stk_qty           xxcos_edi_inventory.month_indv_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、ケース）
    month_case_cargo_stk_qty           xxcos_edi_inventory.month_case_cargo_stk_qty%TYPE,
                -- 積送在庫数量（当月、合計） 
    month_sum_cargo_stk_qty            xxcos_edi_inventory.month_sum_cargo_stk_qty%TYPE,
                -- 調整在庫数量（当日、バラ） 
    day_indv_adjustment_stk_qty        xxcos_edi_inventory.day_indv_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当日、ケース）
    day_case_adjustment_stk_qty        xxcos_edi_inventory.day_case_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当日、合計） 
    day_sum_adjustment_stk_qty         xxcos_edi_inventory.day_sum_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、バラ） 
    month_indv_adjustment_stk_qty      xxcos_edi_inventory.month_indv_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、ケース）
    month_case_adjustment_stk_qty      xxcos_edi_inventory.month_case_adjustment_stk_qty%TYPE,
                -- 調整在庫数量（当月、合計） 
    month_sum_adjustment_stk_qty       xxcos_edi_inventory.month_sum_adjustment_stk_qty%TYPE,
                -- 未出荷数量（当日、バラ）  
    day_indv_still_shipping_qty        xxcos_edi_inventory.day_indv_still_shipping_qty%TYPE,
                -- 未出荷数量（当日、ケース）
    day_case_still_shipping_qty        xxcos_edi_inventory.day_case_still_shipping_qty%TYPE,
                -- 未出荷数量（当日、合計）  
    day_sum_still_shipping_qty         xxcos_edi_inventory.day_sum_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、バラ）   
    month_indv_still_shipping_qty      xxcos_edi_inventory.month_indv_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、ケース） 
    month_case_still_shipping_qty      xxcos_edi_inventory.month_case_still_shipping_qty%TYPE,
                -- 未出荷数量（当月、合計） 
    month_sum_still_shipping_qty       xxcos_edi_inventory.month_sum_still_shipping_qty%TYPE,
                -- 総在庫数量（バラ）      
    indv_all_stk_qty                   xxcos_edi_inventory.indv_all_stk_qty%TYPE,
                -- 総在庫数量（ケース）
    case_all_stk_qty                   xxcos_edi_inventory.case_all_stk_qty%TYPE,
                -- 総在庫数量（合計）       
    sum_all_stk_qty                    xxcos_edi_inventory.sum_all_stk_qty%TYPE,
                -- 当月引当回数               
    month_draw_count                   xxcos_edi_inventory.month_draw_count%TYPE,
                -- 引当可能数量（当日、バラ） 
    day_indv_draw_possible_qty         xxcos_edi_inventory.day_indv_draw_possible_qty%TYPE,
                -- 引当可能数量（当日、ケース）
    day_case_draw_possible_qty         xxcos_edi_inventory.day_case_draw_possible_qty%TYPE,
                -- 引当可能数量（当日、合計）
    day_sum_draw_possible_qty          xxcos_edi_inventory.day_sum_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、バラ） 
    month_indv_draw_possible_qty       xxcos_edi_inventory.month_indv_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、ケース）
    month_case_draw_possible_qty       xxcos_edi_inventory.month_case_draw_possible_qty%TYPE,
                -- 引当可能数量（当月、合計） 
    month_sum_draw_possible_qty        xxcos_edi_inventory.month_sum_draw_possible_qty%TYPE,
                -- 引当不能数（当日、バラ）  
    day_indv_draw_impossible_qty       xxcos_edi_inventory.day_indv_draw_impossible_qty%TYPE,
                -- 引当不能数（当日、ケース） 
    day_case_draw_impossible_qty       xxcos_edi_inventory.day_case_draw_impossible_qty%TYPE,
                -- 引当不能数（当日、合計） 
    day_sum_draw_impossible_qty        xxcos_edi_inventory.day_sum_draw_impossible_qty%TYPE,
                -- 在庫金額（当日）      
    day_stk_amt                        xxcos_edi_inventory.day_stk_amt%TYPE,
                -- 在庫金額（当月）       
    month_stk_amt                      xxcos_edi_inventory.month_stk_amt%TYPE,
                -- 備考                       
    remarks                            xxcos_edi_inventory.remarks%TYPE,
                -- チェーン店固有エリア（明細）
    chain_peculiar_area_line           xxcos_edi_inventory.chain_peculiar_area_line%TYPE,
                -- 伝票計）在庫数量合計（当日、バラ）  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory.invoice_day_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、ケース）
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory.invoice_day_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当日、合計）  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory.invoice_day_sum_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、バラ）  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory.invoice_month_indv_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、ケース）
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory.invoice_month_case_sum_stk_qty%TYPE,
                -- 伝票計）在庫数量合計（当月、合計）  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory.invoice_month_sum_sum_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、バラ） 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory.invoice_day_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、ケース）
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory.invoice_day_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当日、合計）  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory.invoice_day_sum_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、バラ）  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory.invoice_month_indv_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、ケース）
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory.invoice_month_case_cd_stk_qty%TYPE,
                -- 伝票計）商流在庫数量（当月、合計）  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory.invoice_month_sum_cd_stk_qty%TYPE,
                -- 伝票計）在庫金額（当日）            
    invoice_day_stk_amt                xxcos_edi_inventory.invoice_day_stk_amt%TYPE,
                -- 伝票計）在庫金額（当月）            
    invoice_month_stk_amt              xxcos_edi_inventory.invoice_month_stk_amt%TYPE,
                -- 正販金額合計                        
    regular_sell_amt_sum               xxcos_edi_inventory.regular_sell_amt_sum%TYPE,
                -- 割戻し金額合計                      
    rebate_amt_sum                     xxcos_edi_inventory.rebate_amt_sum%TYPE,
                -- 回収容器金額合計                   
    collect_bottle_amt_sum             xxcos_edi_inventory.collect_bottle_amt_sum%TYPE,
                -- チェーン店固有エリア（フッター）    
    chain_peculiar_area_footer         xxcos_edi_inventory.chain_peculiar_area_footer%TYPE,
                -- 顧客コード(変換後顧客コード)
    conv_customer_code                 xxcos_edi_inventory.conv_customer_code%TYPE,
                -- 品目コード
    item_code                          xxcos_edi_inventory.item_code%TYPE,
                -- 単位コード（EBS）
    ebs_uom_code                       xxcos_edi_inventory.ebs_uom_code%TYPE,
/* 2011/07/28 Ver1.8 Mod Start */
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add Start
--                -- EDI受信日
--    edi_received_date                  xxcos_edi_inventory.edi_received_date%TYPE
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add End
                -- EDI受信日
    edi_received_date                  xxcos_edi_inventory.edi_received_date%TYPE,
/* 2011/07/28 Ver1.8 Mod End   */
/* 2011/07/28 Ver1.8 Add Start */
                -- 流通ＢＭＳヘッダデータ
    bms_header_data                    xxcos_edi_inventory.bms_header_data%TYPE,
                -- 流通ＢＭＳ明細データ
    bms_line_data                      xxcos_edi_inventory.bms_line_data%TYPE
/* 2011/07/28 Ver1.8 Add End   */
  );
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- EDI在庫情報データ テーブル型
  TYPE g_req_edi_inv_data_ttype IS TABLE OF g_req_edi_inv_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_inv_data  g_req_edi_inv_data_ttype;
  --* -------------------------------------------------------------------------------------------
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)(A-1)
   *                  :  入力パラメータ妥当性チェック
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
-- 2009/09/16 Ver1.6 M.Sano Add Start
    lv_tok_item_err_type   VARCHAR2(100);   -- メッセージトークン１
    lv_tok_lookup_value    VARCHAR2(100);   -- メッセージトークン２
-- 2009/09/16 Ver1.6 M.Sano Add End
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
  --* -------------------------------------------------------------------------------------------
    IF  ( iv_file_name  IS NULL ) THEN                 -- インタフェースファイル名がNULL 
      -- インタフェースファイル名
      gv_in_file_name    :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_in_file_name
                         );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_in_param_none_err,
                         iv_token_name1        =>  cv_tkn_in_param,
                         iv_token_value1       =>  gv_in_file_name
                         );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --エラーの場合、中断させる。
    IF  ( lv_retcode    <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --* -------------------------------------------------------------------------------------------
    IF  ( iv_run_class  IS NULL ) THEN                 -- 実行区分のパラメタがNULL 
      -- 実行区分
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_in_param_none_err,
                        iv_token_name1        =>  cv_tkn_in_param,
                        iv_token_value1       =>  gv_in_param
                        );
    --* -------------------------------------------------------------------------------------------
    ELSIF (( iv_run_class  =   gv_run_class_name1 )        -- 実行区分：「新規」
    OR     ( iv_run_class  =   gv_run_class_name2 ))       -- 実行区分：「再実施」
    THEN
      NULL;
    ELSE
      -- 実行区分
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode       :=  cv_status_error;
      lv_errmsg        :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_in_param_err,
                       iv_token_name1        =>  cv_tkn_in_param,
                       iv_token_value1       =>  gv_in_param
                       );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --エラーの場合、中断させる。
    IF  ( lv_retcode     <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-1. EDI情報削除期間の取得
    --==================================
    gv_prf_edi_del_date :=  FND_PROFILE.VALUE( cv_prf_edi_del_date );
    -- 
    IF  ( gv_prf_edi_del_date  IS NULL )   THEN
      -- EDI情報削除期間
      gv_prf_edi_del_date0 :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_edi_del_date
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_edi_del_date0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-2. ケース単位コードの取得
    --==================================
    gv_prf_case_code    :=  FND_PROFILE.VALUE( cv_prf_case_code );
    --
    IF  ( gv_prf_case_code  IS NULL )   THEN
      -- ケース単位コード
      gv_prf_case_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_case_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_case_code0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-3. 在庫組織コードの取得
    --==================================
    gv_prf_orga_code    :=  FND_PROFILE.VALUE( cv_prf_orga_code1 );
    --
    IF  ( gv_prf_orga_code     IS NULL )   THEN
      -- 在庫組織コード
      gv_prf_orga_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_orga_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_orga_code0 
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-4. 在庫組織ＩＤの取得
    --==================================
    gv_prf_orga_id      :=  xxcoi_common_pkg.get_organization_id(
                         gv_prf_orga_code
                         );
    --
    IF  ( gv_prf_orga_id       IS NULL )   THEN
      lv_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application1,
                         iv_name               =>  gv_msg_orga_id_err,
                         iv_token_name1        =>  cv_tkn_org_code,
                         iv_token_value1       =>  gv_prf_orga_code
                         );
      RAISE global_api_expt;
    END IF;
    --
-- 2009/09/16 Ver1.6 M.Sano Add Start
    --==================================
    -- 2-5. ダミー品目コードの取得
    --==================================
    BEGIN
      SELECT  msi.segment1                dummy_item_code         -- ダミー品目コード
             ,msi.primary_unit_of_measure primary_unit_of_measure -- 基準単位
      INTO    gt_dummy_item_number
             ,gt_dummy_unit_of_measure
      FROM    fnd_lookup_values     flvv                          -- ルックアップマスタ
             ,mtl_system_items_b    msi                           -- 品目マスタ
      WHERE   flvv.lookup_type        = cv_lookup_type
      AND     flvv.language           = cv_default_language
      AND     flvv.enabled_flag       = cv_y
      AND     flvv.attribute1         = cv_1
      AND     TRUNC( cd_process_date )
      BETWEEN flvv.start_date_active
      AND     NVL( flvv.end_date_active, TRUNC( cd_process_date ) )
      AND     flvv.lookup_code        = msi.segment1              -- ルックアップ.コード=品目マスタ.品目コード
      AND     msi.organization_id     = gv_prf_orga_id            -- 在庫組織ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- マスタチェックエラーを出力
        lv_tok_item_err_type := xxccp_common_pkg.get_msg(
                                    iv_application        =>  cv_application
                                  , iv_name               =>  cv_msg_item_err_type
                                 );
        lv_tok_lookup_value  := xxccp_common_pkg.get_msg(
                                    iv_application        =>  cv_application
                                  , iv_name               =>  cv_msg_lookup_value
                                 );
        lv_errmsg            := xxccp_common_pkg.get_msg(
                                    iv_application        =>  cv_application
                                  , iv_name               =>  cv_msg_mst_notfound
                                  , iv_token_name1        =>  cv_tkn_column_name
                                  , iv_token_value1       =>  lv_tok_item_err_type
                                  , iv_token_name2        =>  cv_tkn_table_name
                                  , iv_token_value2       =>  lv_tok_lookup_value
                                 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2009/09/16 Ver1.6 M.Sano Add End
    --* -------------------------------------------------------------------------------------------
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_invoice_num_add
   * Description      : 伝票別合計変数への追加(A-4)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_add(
    in_line_cnt1  IN NUMBER,       --   LOOP用カウンタ1
    in_line_cnt2  IN NUMBER,       --   LOOP用カウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_add'; -- プログラム名
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
                -- 伝票計）在庫数量合計（当日、バラ）  
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_stk_qty, 0);
                -- 伝票計）在庫数量合計（当日、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_stk_qty, 0);
                -- 伝票計）在庫数量合計（当日、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty  := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty  := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty      := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_cd_stk_qty, 0);
                -- 伝票計）在庫金額（当日）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt             := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_stk_amt, 0);
                -- 伝票計）在庫金額（当月）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt           := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_stk_amt, 0);
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_invoice_num_add;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_invoice_num_req
   * Description      : 伝票別合計変数への再編集(A-4)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_req(
    in_line_cnt    IN NUMBER,       --   LOOP用カウンタ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_req'; -- プログラム名
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
    ln_count  NUMBER  DEFAULT 1;
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
    --==============================================================
    -- 伝票番号毎に集計した伝票計を再編集する。
    --==============================================================
    <<xxcos_edi_inventory_req>>
    FOR  ln_no  IN  1..gn_normal_cnt  LOOP
      IF  ( ln_count > in_line_cnt ) THEN
        NULL;
      ELSE
        -- ヘッダと明細の伝票番号が異なる場合
        IF  ( gt_req_edi_inv_data(ln_no).invoice_number  <> 
              gt_sum_edi_inv_data(ln_count).invoice_number )
        THEN
          --ヘッダデータの添字をカウントアップする
          ln_count  :=  ln_count  +  1;
        END IF;
              -- 伝票計）在庫数量合計（当日、バラ）  
        gt_req_edi_inv_data(ln_no).invoice_day_indv_sum_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_indv_sum_stk_qty, 0);
              -- 伝票計）在庫数量合計（当日、ケース）
        gt_req_edi_inv_data(ln_no).invoice_day_case_sum_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_case_sum_stk_qty, 0);
              -- 伝票計）在庫数量合計（当日、合計）  
        gt_req_edi_inv_data(ln_no).invoice_day_sum_sum_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_sum_sum_stk_qty, 0);
              -- 伝票計）在庫数量合計（当月、バラ）  
        gt_req_edi_inv_data(ln_no).invoice_month_indv_sum_stk_qty  := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_indv_sum_stk_qty, 0);
              -- 伝票計）在庫数量合計（当月、ケース）
        gt_req_edi_inv_data(ln_no).invoice_month_case_sum_stk_qty  := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_case_sum_stk_qty, 0);
              -- 伝票計）在庫数量合計（当月、合計）  
        gt_req_edi_inv_data(ln_no).invoice_month_sum_sum_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_sum_sum_stk_qty, 0);
              -- 伝票計）商流在庫数量（当日、バラ） 
        gt_req_edi_inv_data(ln_no).invoice_day_indv_cd_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_indv_cd_stk_qty, 0);
              -- 伝票計）商流在庫数量（当日、ケース）
        gt_req_edi_inv_data(ln_no).invoice_day_case_cd_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_case_cd_stk_qty, 0);
              -- 伝票計）商流在庫数量（当日、合計）  
        gt_req_edi_inv_data(ln_no).invoice_day_sum_cd_stk_qty      := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_sum_cd_stk_qty, 0);
              -- 伝票計）商流在庫数量（当月、バラ）  
        gt_req_edi_inv_data(ln_no).invoice_month_indv_cd_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_indv_cd_stk_qty, 0);
              -- 伝票計）商流在庫数量（当月、ケース）
        gt_req_edi_inv_data(ln_no).invoice_month_case_cd_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_case_cd_stk_qty, 0);
              -- 伝票計）商流在庫数量（当月、合計）  
        gt_req_edi_inv_data(ln_no).invoice_month_sum_cd_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_sum_cd_stk_qty, 0);
              -- 伝票計）在庫金額（当日）            
        gt_req_edi_inv_data(ln_no).invoice_day_stk_amt             := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_stk_amt, 0);
              -- 伝票計）在庫金額（当月）            
        gt_req_edi_inv_data(ln_no).invoice_month_stk_amt           := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_stk_amt, 0);
      END IF;
-- 
    END LOOP  xxcos_edi_inventory_req;
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_invoice_num_req;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_invoice_num_up
   * Description      : 伝票別合計変数へ数量を加算(A-5)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_up(
    in_line_cnt1   IN NUMBER,       --   LOOP用カウンタ1
    in_line_cnt2   IN NUMBER,       --   LOOP用カウンタ2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_up'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)  ;   -- リターン・コード
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
                -- 伝票計）在庫数量合計（当日、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty, 0)    + 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_stk_qty, 0);
                -- 伝票計）在庫数量合計（当日、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty, 0)    +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_stk_qty, 0);
                -- 伝票計）在庫数量合計（当日、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty  := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty, 0)  +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty  := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty, 0)  + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_stk_qty, 0);
                -- 伝票計）在庫数量合計（当月、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty, 0)   +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当日、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty      := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty, 0)      +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、バラ）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty, 0)   +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、ケース）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty, 0)   + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_cd_stk_qty, 0);
                -- 伝票計）商流在庫数量（当月、合計）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty, 0)    + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_cd_stk_qty, 0);
                -- 伝票計）在庫金額（当日）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt             := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt, 0)  + 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_stk_amt, 0);
                -- 伝票計）在庫金額（当月）
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt           := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt, 0)  +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_stk_amt, 0);
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_invoice_num_up;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_edit
   * Description      : EDI在庫情報変数の編集(A-2)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_edit(
    in_line_cnt     IN NUMBER,       --   LOOP用カウンタ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_edit'; -- プログラム名
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
    --* -------------------------------------------------------------------------------------------
    -- EDI在庫情報テーブルデータ登録用変数
    --* -------------------------------------------------------------------------------------------
                -- 媒体区分
    gt_req_edi_inv_data(in_line_cnt).medium_class   := gt_ediinv_work_data(in_line_cnt).medium_class;
                -- データ種コード
    gt_req_edi_inv_data(in_line_cnt).data_type_code := gt_ediinv_work_data(in_line_cnt).data_type_code;
                -- ファイルＮｏ
    gt_req_edi_inv_data(in_line_cnt).file_no        := gt_ediinv_work_data(in_line_cnt).file_no;
                -- 情報区分
    gt_req_edi_inv_data(in_line_cnt).info_class     := gt_ediinv_work_data(in_line_cnt).info_class;
                -- 処理日
    gt_req_edi_inv_data(in_line_cnt).process_date   := gt_ediinv_work_data(in_line_cnt).process_date;
                -- 処理時刻
    gt_req_edi_inv_data(in_line_cnt).process_time   := gt_ediinv_work_data(in_line_cnt).process_time;
                -- 拠点（部門）コード
    gt_req_edi_inv_data(in_line_cnt).base_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).base_code;
                -- 拠点名（正式名）
    gt_req_edi_inv_data(in_line_cnt).base_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).base_name;
                -- 拠点名（カナ）
    gt_req_edi_inv_data(in_line_cnt).base_name_alt       
                                        :=  gt_ediinv_work_data(in_line_cnt).base_name_alt;
                -- ｅｄｉチェーン店コード 
    gt_req_edi_inv_data(in_line_cnt).edi_chain_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_code;
                -- ｅｄｉチェーン店名（漢字）
    gt_req_edi_inv_data(in_line_cnt).edi_chain_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_name;
                -- ｅｄｉチェーン店名（カナ）
    gt_req_edi_inv_data(in_line_cnt).edi_chain_name_alt 
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_name_alt;
                -- 帳票コード
    gt_req_edi_inv_data(in_line_cnt).report_code    
                                        :=  gt_ediinv_work_data(in_line_cnt).report_code;
                -- 帳票表示名
    gt_req_edi_inv_data(in_line_cnt).report_show_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).report_show_name;
                -- 顧客コード
    gt_req_edi_inv_data(in_line_cnt).customer_code    
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_code;
                -- 顧客名（漢字）
    gt_req_edi_inv_data(in_line_cnt).customer_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_name;
                -- 顧客名（カナ）
    gt_req_edi_inv_data(in_line_cnt).customer_name_alt    
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_name_alt;
                -- 社コード
    gt_req_edi_inv_data(in_line_cnt).company_code     
                                        :=  gt_ediinv_work_data(in_line_cnt).company_code;
                -- 社名（カナ）
    gt_req_edi_inv_data(in_line_cnt).company_name_alt    
                                        :=  gt_ediinv_work_data(in_line_cnt).company_name_alt;
                -- 店コード 
    gt_req_edi_inv_data(in_line_cnt).shop_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).shop_code;
                -- 店名（カナ）
    gt_req_edi_inv_data(in_line_cnt).shop_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).shop_name_alt;
                -- 納入センターコード 
    gt_req_edi_inv_data(in_line_cnt).delivery_center_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_code;
                -- 納入センター名（漢字）
    gt_req_edi_inv_data(in_line_cnt).delivery_center_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_name;
                -- 納入センター名（カナ）
    gt_req_edi_inv_data(in_line_cnt).delivery_center_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_name_alt;
                -- 倉庫コード 
    gt_req_edi_inv_data(in_line_cnt).whse_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_code;
                -- 倉庫名 
    gt_req_edi_inv_data(in_line_cnt).whse_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_name;
                -- 検品担当者名（漢字）
    gt_req_edi_inv_data(in_line_cnt).inspect_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).inspect_charge_name;
                -- 検品担当者名（カナ）
    gt_req_edi_inv_data(in_line_cnt).inspect_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).inspect_charge_name_alt;
                -- 返品担当者名（漢字）
    gt_req_edi_inv_data(in_line_cnt).return_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).return_charge_name;
                -- 返品担当者名（カナ）
    gt_req_edi_inv_data(in_line_cnt).return_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).return_charge_name_alt;
                -- 受領担当者名（漢字）
    gt_req_edi_inv_data(in_line_cnt).receive_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).receive_charge_name;
                -- 受領担当者名（カナ）
    gt_req_edi_inv_data(in_line_cnt).receive_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).receive_charge_name_alt;
                -- 発注日 
    gt_req_edi_inv_data(in_line_cnt).order_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).order_date;
                -- センター納品日
    gt_req_edi_inv_data(in_line_cnt).center_delivery_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_delivery_date;
                -- センター実納品日
    gt_req_edi_inv_data(in_line_cnt).center_result_delivery_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_result_delivery_date;
                -- センター出庫日
    gt_req_edi_inv_data(in_line_cnt).center_shipping_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_shipping_date;
                -- センター実出庫日
    gt_req_edi_inv_data(in_line_cnt).center_result_shipping_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_result_shipping_date;
                -- データ作成日（ｅｄｉデータ中）
    gt_req_edi_inv_data(in_line_cnt).data_creation_date_edi_data      
                                        :=  gt_ediinv_work_data(in_line_cnt).data_creation_date_edi_data;
                -- データ作成時刻（ｅｄｉデータ中）
    gt_req_edi_inv_data(in_line_cnt).data_creation_time_edi_data     
                                        :=  gt_ediinv_work_data(in_line_cnt).data_creation_time_edi_data;
                -- 在庫日付
    gt_req_edi_inv_data(in_line_cnt).stk_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_date;
                -- 提供企業取引先コード区分
    gt_req_edi_inv_data(in_line_cnt).offer_vendor_code_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).offer_vendor_code_class;
                -- 倉庫取引先コード区分
    gt_req_edi_inv_data(in_line_cnt).whse_vendor_code_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_vendor_code_class;
                -- 提供サイクル区分
    gt_req_edi_inv_data(in_line_cnt).offer_cycle_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).offer_cycle_class;
                -- 在庫種類
    gt_req_edi_inv_data(in_line_cnt).stk_type     
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_type;
                -- 日本語区分
    gt_req_edi_inv_data(in_line_cnt).japanese_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).japanese_class;
                -- 倉庫区分
    gt_req_edi_inv_data(in_line_cnt).whse_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_class;
                -- 取引先コード
    gt_req_edi_inv_data(in_line_cnt).vendor_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_code;
                -- 取引先名（漢字）
    gt_req_edi_inv_data(in_line_cnt).vendor_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_name;
                -- 取引先名（カナ）
    gt_req_edi_inv_data(in_line_cnt).vendor_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_name_alt;
                -- チェックデジット有無区分
    gt_req_edi_inv_data(in_line_cnt).check_digit_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).check_digit_class;
                -- 伝票番号
    gt_req_edi_inv_data(in_line_cnt).invoice_number      
                                        :=  gt_ediinv_work_data(in_line_cnt).invoice_number;
                -- チェックデジット
    gt_req_edi_inv_data(in_line_cnt).check_digit      
                                        :=  gt_ediinv_work_data(in_line_cnt).check_digit;
                -- チェーン店固有エリア（ヘッダ）
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_header      
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_header;
                -- 商品コード（伊藤園）
    gt_req_edi_inv_data(in_line_cnt).product_code_itouen     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_code_itouen;
                -- 商品コード（先方）
    gt_req_edi_inv_data(in_line_cnt).product_code_other_party     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_code_other_party;
                -- ｊａｎコード 
    gt_req_edi_inv_data(in_line_cnt).jan_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).jan_code;
                -- ｉｔｆコード 
    gt_req_edi_inv_data(in_line_cnt).itf_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).itf_code;
                -- 商品名（漢字）
    gt_req_edi_inv_data(in_line_cnt).product_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_name;
                -- 商品名（カナ）
    gt_req_edi_inv_data(in_line_cnt).product_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_name_alt;
                -- 商品区分
    gt_req_edi_inv_data(in_line_cnt).prod_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).prod_class;
                -- 適用品質区分
    gt_req_edi_inv_data(in_line_cnt).active_quality_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).active_quality_class;
                -- 入数
    gt_req_edi_inv_data(in_line_cnt).qty_in_case      
                                        :=  gt_ediinv_work_data(in_line_cnt).qty_in_case;
                -- 単位
    gt_req_edi_inv_data(in_line_cnt).uom_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).uom_code;
                -- 一日平均出荷数量
    gt_req_edi_inv_data(in_line_cnt).day_average_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_average_shipping_qty;
                -- 在庫種別コード
    gt_req_edi_inv_data(in_line_cnt).stk_type_code     
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_type_code;
                -- 最終入荷日
    gt_req_edi_inv_data(in_line_cnt).last_arrival_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).last_arrival_date;
                -- 賞味期限
    gt_req_edi_inv_data(in_line_cnt).use_by_date     
                                        :=  gt_ediinv_work_data(in_line_cnt).use_by_date;
                -- 製造日
    gt_req_edi_inv_data(in_line_cnt).product_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).product_date;
                -- 上限在庫（ケース）
    gt_req_edi_inv_data(in_line_cnt).upper_limit_stk_case      
                                        :=  gt_ediinv_work_data(in_line_cnt).upper_limit_stk_case;
                -- 上限在庫（バラ）
    gt_req_edi_inv_data(in_line_cnt).upper_limit_stk_indv     
                                        :=  gt_ediinv_work_data(in_line_cnt).upper_limit_stk_indv;
                -- 発注点（バラ）
    gt_req_edi_inv_data(in_line_cnt).indv_order_point      
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_order_point;
                -- 発注点（ケース）
    gt_req_edi_inv_data(in_line_cnt).case_order_point      
                                        :=  gt_ediinv_work_data(in_line_cnt).case_order_point;
                -- 前月末在庫数量（バラ）
    gt_req_edi_inv_data(in_line_cnt).indv_prev_month_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_prev_month_stk_qty;
                -- 前月末在庫数量（ケース）
    gt_req_edi_inv_data(in_line_cnt).case_prev_month_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).case_prev_month_stk_qty;
                -- 前月在庫数量（合計） 
    gt_req_edi_inv_data(in_line_cnt).sum_prev_month_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).sum_prev_month_stk_qty;
                -- 発注数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_order_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_order_qty;
                -- 発注数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_order_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_order_qty;
                -- 発注数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_order_qty;
                -- 発注数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_order_qty;
                -- 発注数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_order_qty;
                -- 発注数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_order_qty;
                -- 入庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_arrival_qty;
                -- 入庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_arrival_qty;
                -- 入庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_arrival_qty;
                -- 当月入荷回数 
    gt_req_edi_inv_data(in_line_cnt).month_arrival_count      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_arrival_count;
                -- 入庫数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_arrival_qty;
                -- 入庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_arrival_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_arrival_qty;
                -- 入庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_arrival_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_arrival_qty;
                -- 出庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_shipping_qty;
                -- 出庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_shipping_qty;
                -- 出庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_shipping_qty;
                -- 出庫数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_shipping_qty;
                -- 出庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_shipping_qty;
                -- 出庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_shipping_qty;
                -- 破棄、ロス数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_destroy_loss_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_destroy_loss_qty;
                -- 破棄、ロス数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_destroy_loss_qty;
                -- 破棄、ロス数量（当日、合計） 
    gt_req_edi_inv_data(in_line_cnt).day_sum_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_destroy_loss_qty;
                -- 破棄、ロス数量（当月、バラ） 
    gt_req_edi_inv_data(in_line_cnt).month_indv_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_destroy_loss_qty;
                -- 破棄、ロス数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_destroy_loss_qty;
                -- 破棄、ロス数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_destroy_loss_qty;
                -- 不良在庫数量（当日、バラ） 
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_stk_qty;
                -- 不良在庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_stk_qty;
                -- 不良在庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_stk_qty;
                -- 不良在庫数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_stk_qty;
                -- 不良在庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_stk_qty;
                -- 不良在庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_stk_qty;
                -- 不良返品数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_qty;
                -- 不良返品数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_qty;
                -- 不良返品数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_qty;
                -- 不良返品数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_qty;
                -- 不良返品数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_qty;
                -- 不良返品数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_qty;
                -- 不良返品受入（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_rcpt;
                -- 不良返品受入（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_rcpt;
                -- 不良返品受入（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_rcpt      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_rcpt;
                -- 不良返品受入（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_rcpt;
                -- 不良返品受入（当月、ケース） 
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_rcpt;
                -- 不良返品受入（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_rcpt;
                -- 不良返品発送（当日、バラ） 
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_send;
                -- 不良返品発送（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_send;
                -- 不良返品発送（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_send;
                -- 不良返品発送（当月、バラ） 
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_send;
                -- 不良返品発送（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_send;
                -- 不良返品発送（当月、合計） 
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_send;
                -- 良品返品受入（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_quality_return_rcpt;
                -- 良品返品受入（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_quality_return_rcpt;
                -- 良品返品受入（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_quality_return_rcpt;
                -- 良品返品受入（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_quality_return_rcpt;
                -- 良品返品受入（当月、ケース） 
    gt_req_edi_inv_data(in_line_cnt).month_case_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_quality_return_rcpt;
                -- 良品返品受入（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_quality_return_rcpt;
                -- 良品返品発送（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_quality_return_send;
                -- 良品返品発送（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_quality_return_send;
                -- 良品返品発送（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_quality_return_send;
                -- 良品返品発送（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_quality_return_send;
                -- 良品返品発送（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_quality_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_quality_return_send;
                -- 良品返品発送（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_quality_return_send;
                -- 棚卸差異（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_invent_difference;
                -- 棚卸差異（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_invent_difference;
                -- 棚卸差異（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_invent_difference;
                -- 棚卸差異（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_invent_difference      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_invent_difference;
                -- 棚卸差異（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_invent_difference;
                -- 棚卸差異（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_invent_difference;
                -- 在庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_stk_qty;
                -- 在庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_stk_qty;
                -- 在庫数量（当日、合計） 
    gt_req_edi_inv_data(in_line_cnt).day_sum_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_stk_qty;
                -- 在庫数量（当月、バラ） 
    gt_req_edi_inv_data(in_line_cnt).month_indv_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_stk_qty;
                -- 在庫数量（当月、ケース） 
    gt_req_edi_inv_data(in_line_cnt).month_case_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_stk_qty;
                -- 在庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_stk_qty;
                -- 保留在庫数（当日、バラ） 
    gt_req_edi_inv_data(in_line_cnt).day_indv_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_reserved_stk_qty;
                -- 保留在庫数（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_reserved_stk_qty;
                -- 保留在庫数（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_reserved_stk_qty;
                -- 保留在庫数（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_reserved_stk_qty;
                -- 保留在庫数（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_reserved_stk_qty;
                -- 保留在庫数（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_reserved_stk_qty;
                -- 商流在庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_cd_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_cd_stk_qty;
                -- 商流在庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_cd_stk_qty;
                -- 商流在庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_cd_stk_qty;
                -- 商流在庫数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_cd_stk_qty;
                -- 商流在庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_cd_stk_qty;
                -- 商流在庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_cd_stk_qty;
                -- 積送在庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_cargo_stk_qty;
                -- 積送在庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_cargo_stk_qty;
                -- 積送在庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_cargo_stk_qty;
                -- 積送在庫数量（当月、バラ）  
    gt_req_edi_inv_data(in_line_cnt).month_indv_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_cargo_stk_qty;
                -- 積送在庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_cargo_stk_qty;
                -- 積送在庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_cargo_stk_qty;
                -- 調整在庫数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_adjustment_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_adjustment_stk_qty;
                -- 調整在庫数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_adjustment_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_adjustment_stk_qty;
                -- 調整在庫数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_adjustment_stk_qty;
                -- 調整在庫数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_adjustment_stk_qty;
                -- 調整在庫数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_adjustment_stk_qty;
                -- 調整在庫数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_adjustment_stk_qty;
                -- 未出荷数量（当日、バラ） 
    gt_req_edi_inv_data(in_line_cnt).day_indv_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_still_shipping_qty;
                -- 未出荷数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_still_shipping_qty;
                -- 未出荷数量（当日、合計） 
    gt_req_edi_inv_data(in_line_cnt).day_sum_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_still_shipping_qty;
                -- 未出荷数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_still_shipping_qty;
                -- 未出荷数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_still_shipping_qty;
                -- 未出荷数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_still_shipping_qty;
                -- 総在庫数量（バラ） 
    gt_req_edi_inv_data(in_line_cnt).indv_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_all_stk_qty;
                -- 総在庫数量（ケース）
    gt_req_edi_inv_data(in_line_cnt).case_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).case_all_stk_qty;
                -- 総在庫数量（合計） 
    gt_req_edi_inv_data(in_line_cnt).sum_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).sum_all_stk_qty;
                -- 当月引当回数
    gt_req_edi_inv_data(in_line_cnt).month_draw_count      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_draw_count;
                -- 引当可能数量（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_draw_possible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_draw_possible_qty;
                -- 引当可能数量（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_draw_possible_qty;
                -- 引当可能数量（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_draw_possible_qty;
                -- 引当可能数量（当月、バラ）
    gt_req_edi_inv_data(in_line_cnt).month_indv_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_draw_possible_qty;
                -- 引当可能数量（当月、ケース）
    gt_req_edi_inv_data(in_line_cnt).month_case_draw_possible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_draw_possible_qty;
                -- 引当可能数量（当月、合計）
    gt_req_edi_inv_data(in_line_cnt).month_sum_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_draw_possible_qty;
                -- 引当不能数（当日、バラ）
    gt_req_edi_inv_data(in_line_cnt).day_indv_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_draw_impossible_qty;
                -- 引当不能数（当日、ケース）
    gt_req_edi_inv_data(in_line_cnt).day_case_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_draw_impossible_qty;
                -- 引当不能数（当日、合計）
    gt_req_edi_inv_data(in_line_cnt).day_sum_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_draw_impossible_qty;
                -- 在庫金額（当日）
    gt_req_edi_inv_data(in_line_cnt).day_stk_amt      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_stk_amt;
                -- 在庫金額（当月）
    gt_req_edi_inv_data(in_line_cnt).month_stk_amt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_stk_amt;
                -- 備考
    gt_req_edi_inv_data(in_line_cnt).remarks      
                                        :=  gt_ediinv_work_data(in_line_cnt).remarks;
                -- チェーン店固有エリア（明細）
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_line     
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_line;
                -- 正販金額合計
    gt_req_edi_inv_data(in_line_cnt).regular_sell_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).regular_sell_amt_sum;
                -- 割戻し金額合計
    gt_req_edi_inv_data(in_line_cnt).rebate_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).rebate_amt_sum;
                -- 回収容器金額合計
    gt_req_edi_inv_data(in_line_cnt).collect_bottle_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).collect_bottle_amt_sum;
                -- チェーン店固有エリア（フッター）
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_footer     
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_footer;
-- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add Start
    gt_req_edi_inv_data(in_line_cnt).edi_received_date     
                                        :=  gt_ediinv_work_data(in_line_cnt).creation_date;
-- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add End
/* 2011/07/28 Ver1.8 Add Start */
                -- 流通ＢＭＳヘッダデータ
    gt_req_edi_inv_data(in_line_cnt).bms_header_data
                                        := gt_ediinv_work_data(in_line_cnt).bms_header_data;
                -- 流通ＢＭＳ明細データ
    gt_req_edi_inv_data(in_line_cnt).bms_line_data
                                        := gt_ediinv_work_data(in_line_cnt).bms_line_data;
/* 2011/07/28 Ver1.8 Add End   */
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inventory_edit;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : データ妥当性チェック(A-3)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt    IN NUMBER,       --   LOOP用カウンタ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
--
    lt_chain_account_number     hz_cust_accounts.account_number%TYPE;             -- 顧客コード(チェーン店)
    lt_head_edi_item_code_div   xxcmm_cust_accounts.edi_item_code_div%TYPE;       -- EDI連携品目コード区分
    lt_unit_of_measure          mtl_system_items_b.primary_unit_of_measure%TYPE;  -- 単位
    lv_invoice_number_err_flag  VARCHAR2(1) DEFAULT NULL;                         -- 伝票エラーフラグ変数
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
    lv_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- ＥＤＩチェーン店コード
    gt_req_edi_inv_data(in_line_cnt).edi_chain_code := gt_ediinv_work_data(in_line_cnt).edi_chain_code;
    -- 店コード
    gt_req_edi_inv_data(in_line_cnt).shop_code := gt_ediinv_work_data(in_line_cnt).shop_code;
    -- 伝票番号
    gt_req_edi_inv_data(in_line_cnt).invoice_number := gt_ediinv_work_data(in_line_cnt).invoice_number;
    -- 顧客コード
    gt_req_edi_inv_data(in_line_cnt).customer_code  := gt_ediinv_work_data(in_line_cnt).customer_code;
    -- 商品コード（先方）
    gt_req_edi_inv_data(in_line_cnt).product_code_other_party  
                        := gt_ediinv_work_data(in_line_cnt).product_code_other_party;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Add Start
    -- 品目コード
    gt_req_edi_inv_data(in_line_cnt).item_code       := NULL;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Add End
    --==============================================================
    lv_invoice_number_err_flag := NULL;
    --==============================================================
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Del Start
--    --==============================================================
--    -- 店コードチェック
--    --==============================================================
--    IF ( gt_req_edi_inv_data(in_line_cnt).shop_code  IS NULL )  THEN
--      -- 店コード
--      gv_tkn_shop_code    :=  xxccp_common_pkg.get_msg(
--                          iv_application        =>  cv_application,
--                          iv_name               =>  cv_msg_shop_code
--                          );
--      lv_errmsg           :=  xxccp_common_pkg.get_msg(
--                          iv_application        =>  cv_application,
--                          iv_name               =>  gv_msg_in_none_err,
--                          iv_token_name1        =>  cv_tkn_item,
--                          iv_token_value1       =>  gv_tkn_shop_code
--                          );
--      ov_errbuf  :=  lv_errbuf;
--      ov_errmsg  :=  lv_errmsg;
--      lv_retcode :=  cv_status_warn;
--      ov_retcode :=  cv_status_warn;
--      lv_invoice_number_err_flag := cv_inv_num_err_flag;
--      -- 在庫情報ワークID(error)
--      gv_err_ediinv_work_flag  := cv_1;
--    END IF;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Del End
    --
    --==============================================================
    -- 「顧客コード」の妥当性 チェック
    --==============================================================
    IF ( lv_invoice_number_err_flag IS NULL )  THEN
      BEGIN
        SELECT   cust.account_number         account_number   -- 顧客マスタ.顧客コード
         INTO    gt_req_cust_acc_data(in_line_cnt).account_number
         FROM    hz_cust_accounts       cust,                 -- 顧客マスタ
                 xxcmm_cust_accounts    xca                   -- 顧客追加情報
                                      -- 顧客マスタ.顧客ID   =  顧客追加情報.顧客ID
        WHERE    cust.cust_account_id = xca.customer_id        
                                     -- 顧客マスタ.顧客区分  = '10'(顧客) 
          AND    cust.customer_class_code = cv_customer_class_code10      
                                      -- 顧客マスタ.チェーン店コード(EDI) = A-2で抽出したEDIチェーン店コード
          AND    xca.chain_store_code = gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                                      -- 顧客マスタ.店舗コード = A-2で抽出した店コード
          AND    xca.store_code       = gt_req_edi_inv_data(in_line_cnt).shop_code
          AND    rownum= 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- （対象データ無しエラー）
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Add Start
--          --* -------------------------------------------------------------
--          --顧客コード変換エラーメッセージ  gv_msg_cust_num_chg_err
--          --* -------------------------------------------------------------
--          lv_errmsg     :=  xxccp_common_pkg.get_msg(
--                        iv_application        =>  cv_application,
--                        iv_name               =>  gv_msg_cust_num_chg_err,
--                        iv_token_name1        =>  cv_chain_shop_code,
--                        iv_token_name2        =>  cv_shop_code,
--                        iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code,
--                        iv_token_value2       =>  gt_req_edi_inv_data(in_line_cnt).shop_code
--                        );
--          ov_errbuf     :=  lv_errbuf;
--          ov_errmsg     :=  lv_errmsg;
--          ov_retcode    :=  cv_status_warn;
--          lv_invoice_number_err_flag := cv_inv_num_err_flag;
--          -- 在庫情報ワークID(error)
--          gv_err_ediinv_work_flag  := cv_1;
          gt_req_cust_acc_data(in_line_cnt).account_number := NULL;
      END;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Del End
    END IF;
--
    --* -------------------------------------------------------------
    -- 「商品コード」の妥当性チェック
    --* -------------------------------------------------------------
    IF ( lv_invoice_number_err_flag IS NULL )  THEN
      BEGIN
        --* -------------------------------------------------------------
        -- 顧客コード(変換後顧客コード)
        --* -------------------------------------------------------------
        gt_req_edi_inv_data(in_line_cnt).conv_customer_code := gt_req_cust_acc_data(in_line_cnt).account_number;
        --* -------------------------------------------------------------
        --== 「EDI連携品目コード区分」抽出 ==--
        --* -------------------------------------------------------------
        SELECT  xca.edi_item_code_div,    -- 顧客追加情報.EDI連携品目コード区分
                cust.account_number       -- 顧客マスタ.顧客コード
        INTO    lt_head_edi_item_code_div,
                lt_chain_account_number
        FROM    hz_cust_accounts       cust,                 -- 顧客マスタ
                xxcmm_cust_accounts    xca                   -- 顧客追加情報
        WHERE   cust.cust_account_id = xca.customer_id        
                                    -- 顧客マスタ.チェーン店コード(EDI) = A-2で抽出したEDIチェーン店コード
          AND   xca.chain_store_code = gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                                    -- 顧客マスタ.顧客区分 = '18'(チェーン店)
          AND   cust.customer_class_code = cv_customer_class_code18
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod Start
--          --* -------------------------------------------------------------
--          --EDI連携品目コード区分エラーメッセージ  gv_msg_item_code_err
--          --* -------------------------------------------------------------
--          lv_errmsg    :=  xxccp_common_pkg.get_msg(
--                       iv_application        =>  cv_application,
--                       iv_name               =>  gv_msg_item_code_err,
--                       iv_token_name1        =>  cv_chain_shop_code,
--                       iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code
--                       );
--          ov_errbuf  :=  lv_errbuf;
--          ov_errmsg  :=  lv_errmsg;
--          ov_retcode :=  cv_status_warn;
--          lv_invoice_number_err_flag := cv_inv_num_err_flag;
--          --
--          -- 在庫情報ワークID(error)
--          gv_err_ediinv_work_flag  := cv_1;
        NULL;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
      END;
      --* -------------------------------------------------------------
      IF  ( lv_invoice_number_err_flag IS NULL )  THEN
        --* -------------------------------------------------------------
        -- 「EDI連携品目コード区分」が「NULL」または「0：なし」の場合
        --* -------------------------------------------------------------
        IF  (( lt_head_edi_item_code_div IS NULL ) 
        OR   ( lt_head_edi_item_code_div  = 0 ))
        THEN
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod Start
--          --* -------------------------------------------------------------
--          --EDI連携品目コード区分エラーメッセージ  gv_msg_item_code_err
--          --* -------------------------------------------------------------
--          lv_errmsg    :=  xxccp_common_pkg.get_msg(
--                       iv_application        =>  cv_application,
--                       iv_name               =>  gv_msg_item_code_err,
--                       iv_token_name1        =>  cv_chain_shop_code,
--                       iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code
--                       );
--          ov_errbuf    :=  lv_errbuf;
--          ov_errmsg    :=  lv_errmsg;
--          ov_retcode   :=  cv_status_warn;
--          lv_invoice_number_err_flag := cv_inv_num_err_flag;
--          -- 在庫情報ワークID(error)
--          gv_err_ediinv_work_flag  := cv_1;
          NULL;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
        --
        --* -------------------------------------------------------------
        -- 「EDI連携品目コード区分」が「2：JANコード」の場合
        --  品目マスタチェック (3-1)
        --* -------------------------------------------------------------
        ELSIF  ( lt_head_edi_item_code_div  = 2 )  THEN
          BEGIN
            --* -------------------------------------------------------------
            --== 品目マスタデータ抽出 ==--
            --* -------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--            SELECT mtl_item.segment1,                 -- 品目コード
--                   mtl_item.primary_unit_of_measure   -- 単位
--            INTO   gt_req_edi_inv_data(in_line_cnt).item_code,
--                   lt_unit_of_measure
--            FROM   mtl_system_items_b    mtl_item,
--                   ic_item_mst_b         mtl_item1
--            WHERE  mtl_item.segment1        = mtl_item1.item_no
--                                                 -- 商品コード（先方）
--              AND  mtl_item1.attribute21    = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
--                                                 -- 在庫組織ID
--              AND  mtl_item.organization_id = gv_prf_orga_id;
--
            SELECT ims.segment1,
                   ims.primary_unit_of_measure
              INTO gt_req_edi_inv_data(in_line_cnt).item_code,
                   lt_unit_of_measure
              FROM (
                    SELECT msi.segment1,                 -- 品目コード
                           msi.primary_unit_of_measure   -- 基準単位
                      FROM mtl_system_items_b    msi,
                           ic_item_mst_b         iim,
                           xxcmn_item_mst_b      xim
                     WHERE msi.segment1          = iim.item_no
                                                      -- 商品コード２
                      AND  iim.attribute21      = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
                                                      -- 在庫組織ID
                      AND  msi.organization_id  = gv_prf_orga_id
                      AND xim.item_id           = iim.item_id         --OPM品目.品目ID        =OPM品目アドオン.品目ID
                      AND xim.item_id           = xim.parent_item_id  --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
                      AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_ediinv_work_data(in_line_cnt).center_delivery_date, 
                                                                        NVL( gt_ediinv_work_data(in_line_cnt).order_date, 
                                                                             gt_ediinv_work_data(in_line_cnt).data_creation_date_edi_data
                                                                           )
                                                                      )
                    ORDER BY iim.attribute13 DESC
                   ) ims
            WHERE ROWNUM  = 1
            ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
          --
          EXCEPTION
            WHEN  NO_DATA_FOUND THEN
            --* -------------------------------------------------------------
            -- 「EDI連携品目コード区分」が「2：JANコード」の場合で取得不可の場合、
            --  品目マスタチェック (3-2) ケースＪＡＮコードを抽出
            --* -------------------------------------------------------------
            BEGIN
              --* -------------------------------------------------------------
              --== 品目マスタデータ抽出 ==-- 
              --* -------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--              SELECT mtl_item.segment1                  -- 品目コード
--              INTO   gt_req_edi_inv_data(in_line_cnt).item_code
--              FROM   mtl_system_items_b    mtl_item,
--                     ic_item_mst_b         mtl_item1,
--                     xxcmm_system_items_b  xxcmm_sib
--              WHERE  mtl_item.segment1        = mtl_item1.item_no
--                AND  mtl_item.segment1        = xxcmm_sib.item_code
--                                            -- 商品コード（先方）
--                AND  xxcmm_sib.case_jan_code  = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
--                                            -- 在庫組織ID
--                AND  mtl_item.organization_id = gv_prf_orga_id;
              SELECT ims.segment1
                INTO gt_req_edi_inv_data(in_line_cnt).item_code
                FROM (
                      SELECT msi.segment1          segment1             -- 品目コード
                        FROM mtl_system_items_b    msi,
                             ic_item_mst_b         iim,
                             xxcmn_item_mst_b      xim,
                             xxcmm_system_items_b  xsi
                       WHERE msi.segment1        = iim.item_no
                         AND msi.segment1        = xsi.item_code
                                                     -- 商品コード２
                         AND xsi.case_jan_code   = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
                                                     -- 在庫組織ID
                         AND msi.organization_id = gv_prf_orga_id
                         AND xim.item_id         = iim.item_id         --OPM品目.品目ID        =OPM品目アドオン.品目ID
                         AND xim.item_id         = xim.parent_item_id  --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
                         AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_ediinv_work_data(in_line_cnt).center_delivery_date, 
                                                                           NVL( gt_ediinv_work_data(in_line_cnt).order_date, 
                                                                                gt_ediinv_work_data(in_line_cnt).data_creation_date_edi_data
                                                                              )
                                                                         )
                       ORDER BY iim.attribute13 DESC
                     ) ims
              WHERE ROWNUM  = 1
              ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
               --* -------------------------------------------------------------
                --== A-1で抽出したケース単位ｺｰﾄﾞ
                --* -------------------------------------------------------------
                lt_unit_of_measure := gv_prf_case_code;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
-- 2009/09/16 Ver1.6 M.Sano Mod Start
---- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod Start
----              --* -------------------------------------------------------------
----              --* ケースＪＡＮコードの場合でエラーの場合、ダミー品目コードを取得
----              --* -------------------------------------------------------------
----                BEGIN
----                  --* -------------------------------------------------------------
----                  -- JANコード 商品コード変換エラー
----                  --* -------------------------------------------------------------
----                  gv_tkn_jan_code  :=  xxccp_common_pkg.get_msg(
----                                         iv_application        =>  cv_application,
----                                         iv_name               =>  cv_msg_jan_code
----                                         );
----                  --商品コード変換エラーメッセージ  gv_msg_product_code_err
----                  lv_errmsg             :=  xxccp_common_pkg.get_msg(
----                                        iv_application        =>  cv_application,
----                                        iv_name               =>  gv_msg_product_code_err,
----                                        iv_token_name1        =>  cv_prod_code,
----                                        iv_token_name2        =>  cv_prod_type,
----                                        iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
----                                        iv_token_value2       =>  gv_tkn_jan_code
----                                        );
----                  ov_errbuf  :=  lv_errbuf;
----                  ov_errmsg  :=  lv_errmsg;
----                  ov_retcode :=  cv_status_warn;
----                  --
----                  --== ルックアップマスタデータ抽出 ==--
----                  SELECT  flvv.lookup_code        -- コード
----                  INTO   gt_req_edi_inv_data(in_line_cnt).item_code
----                  FROM    fnd_lookup_values_vl  flvv        -- ルックアップマスタ
----                  WHERE   flvv.lookup_type  = cv_lookup_type  -- ルックアップ.タイプ
----                   AND    flvv.enabled_flag       = cv_y                -- 有効
----                   AND    flvv.attribute1         = cv_1
----                  AND (( flvv.start_date_active IS NULL )
----                   OR   ( flvv.start_date_active <= cd_process_date ))
----                   AND (( flvv.end_date_active   IS NULL )
----                   OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
----                   ;
----                --
----                gv_dummy_item_code := gt_req_edi_inv_data(in_line_cnt).item_code;
----                END;
--            --* -------------------------------------------------------------
--/*            WHEN OTHERS THEN
--                --* -------------------------------------------------------------
--                --顧客品目 商品コード変換エラー
--                --* -------------------------------------------------------------
--                gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
--                                       iv_application        =>  cv_application,
--                                       iv_name               =>  cv_msg_mtl_cust_items
--                                       );
--                --商品コード変換エラーメッセージ  gv_msg_product_code_err
--                lv_errmsg             :=  xxccp_common_pkg.get_msg(
--                                      iv_application        =>  cv_application,
--                                      iv_name               =>  gv_msg_product_code_err,
--                                      iv_token_name1        =>  cv_prod_code,
--                                      iv_token_name2        =>  cv_prod_type,
--                                      iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
--                                      iv_token_value2       =>  gv_tkn_mtl_cust_items
--                                      );
--                ov_errbuf  :=  lv_errbuf;
--                ov_errmsg  :=  lv_errmsg;
--                ov_retcode :=  cv_status_warn;
--                lv_invoice_number_err_flag := cv_inv_num_err_flag;
--                -- 在庫情報ワークID(error)
--                gn_error_cnt := gn_error_cnt + 1;
--                gv_err_ediinv_work_flag  := cv_1;
--*/                --
--              NULL;
---- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
              --== ダミー品目をセット ==--
              gt_req_edi_inv_data(in_line_cnt).item_code := gt_dummy_item_number;
              lt_unit_of_measure := gt_dummy_unit_of_measure;
-- 2009/09/16 Ver1.6 M.Sano Mod End
            END;
          END;
          --
        --* -------------------------------------------------------------
        -- 「EDI連携品目コード区分」が「1：顧客品目」の場合
        --  顧客品目マスタチェック (3-2)
        --* -------------------------------------------------------------
        ELSIF  ( lt_head_edi_item_code_div  = 1 )  THEN
          --* -------------------------------------------------------------
          -- 「商品コード２」の妥当性チェック
          --* -------------------------------------------------------------
          BEGIN
            --* -------------------------------------------------------------
            --== 顧客マスタデータ抽出 ==--
            --* -------------------------------------------------------------
            SELECT mtl_item.segment1,              -- 品目コード
                   mtci.attribute1                 -- 単位
            INTO   gt_req_edi_inv_data(in_line_cnt).item_code,
                   lt_unit_of_measure
            FROM   hz_cust_accounts         cust,                  -- 顧客マスタ
                   mtl_customer_item_xrefs  mcix,                  -- 顧客品目相互参照
                   mtl_customer_items       mtci,                  -- 顧客品目
                   mtl_system_items_b       mtl_item,              -- 品目マスタ
                   mtl_parameters           mtl_parm               -- 顧客品目ﾊﾟﾗﾒｰﾀﾏｽﾀ
                                   -- 顧客マスタ.顧客コード = チェーン店の顧客コード
            WHERE  cust.account_number         = lt_chain_account_number
                                   -- 顧客マスタ.顧客区分 = '18'(チェーン店)
              AND  cust.customer_class_code    = cv_customer_class_code18
                                   -- 顧客品目.顧客ID = 顧客マスタ.顧客ID
              AND  mtci.customer_id            = cust.cust_account_id
                                   -- 顧客品目マスタ．顧客品目 ＝ 商品コード（先方）
              AND  mtci.customer_item_number   = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
-- 2009/09/16 Ver1.6 M.Sano Add Start
                                   -- 顧客品目.有効フラグ = 'N'(有効)
              AND  mtci.inactive_flag          = cv_inactive_flag_no
-- 2009/09/16 Ver1.6 M.Sano Add End
                                   -- 顧客品目.顧客品目ID = 顧客品目相互参照.顧客品目ID
              AND  mtci.customer_item_id       = mcix.customer_item_id
              AND  mcix.master_organization_id = mtl_parm.master_organization_id
-- 2009/09/16 Ver1.6 M.Sano Add Start
                                   -- 顧客品目相互参照.有効フラグ = 'N'(有効)
              AND  mcix.inactive_flag          = cv_inactive_flag_no
                                   -- 顧客品目相互参照.ランクが最小
              AND  mcix.preference_number      = (
                     SELECT MIN(mcix_chk.preference_number)
                     FROM   mtl_customer_item_xrefs  mcix_chk
                     WHERE  mcix_chk.customer_item_id       = mcix.customer_item_id
                     AND    mcix_chk.master_organization_id = mcix.master_organization_id
                     AND    mcix_chk.inactive_flag          = cv_inactive_flag_no
                   )
-- 2009/09/16 Ver1.6 M.Sano Add End
                                   -- 在庫組織ID
              AND  mtl_parm.organization_id    = gv_prf_orga_id
                                   -- 顧客品目相互参照.品目ID = 品目マスタ.品目ID
              AND  mtl_item.inventory_item_id  = mcix.inventory_item_id
              AND  mtl_item.organization_id    = mtl_parm.organization_id;
          --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
-- 2009/09/16 Ver1.6 M.Sano Mod Start
---- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod Start
----              --* -------------------------------------------------------------
----              --== ルックアップマスタデータ抽出
----              --* -------------------------------------------------------------
----              BEGIN
----                --== ルックアップマスタデータ抽出 ==--
----                SELECT   flvv.lookup_code        -- コード
----                 INTO    gt_req_edi_inv_data(in_line_cnt).item_code
----                 FROM   fnd_lookup_values_vl  flvv        -- ルックアップマスタ
----                 WHERE  flvv.lookup_type       = cv_lookup_type  -- ルックアップ.タイプ
----                 AND    flvv.enabled_flag       = cv_y                -- 有効
----                 AND    flvv.attribute1         = cv_1
----                 AND (( flvv.start_date_active IS NULL )
----                 OR   ( flvv.start_date_active <= cd_process_date ))
----                 AND (( flvv.end_date_active   IS NULL )
----                 OR   ( flvv.end_date_active   >= cd_process_date ))  -- 業務日付がFROM-TO内
----                 ;
----                gv_dummy_item_code := gt_req_edi_inv_data(in_line_cnt).item_code;
----                --
----                --* -------------------------------------------------------------
----                --顧客品目 商品コード変換エラー
----                --* -------------------------------------------------------------
----                gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
----                                       iv_application        =>  cv_application,
----                                       iv_name               =>  cv_msg_mtl_cust_items
----                                       );
----                --商品コード変換エラーメッセージ  gv_msg_product_code_err
----                lv_errmsg             :=  xxccp_common_pkg.get_msg(
----                                      iv_application        =>  cv_application,
----                                      iv_name               =>  gv_msg_product_code_err,
----                                      iv_token_name1        =>  cv_prod_code,
----                                      iv_token_name2        =>  cv_prod_type,
----                                      iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
----                                      iv_token_value2       =>  gv_tkn_mtl_cust_items
----                                      );
----                ov_errbuf  :=  lv_errbuf;
----                ov_errmsg  :=  lv_errmsg;
----                ov_retcode :=  cv_status_warn;
----                --
----              END;
--            NULL;
---- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
              --== ダミー品目をセット ==--
              gt_req_edi_inv_data(in_line_cnt).item_code := gt_dummy_item_number;
              lt_unit_of_measure := gt_dummy_unit_of_measure;
-- 2009/09/16 Ver1.6 M.Sano Mod End
          END;
        END IF;
      END IF;
    -- * -------------------------------------------------------------
    END IF;
    -- * -------------------------------------------------------------
    -- * リターンコードがワーニングのとき、コードを保存
    -- * -------------------------------------------------------------
    IF ( ov_retcode =  cv_status_warn ) THEN
      gv_status_work :=  cv_status_warn;
--****************************** 2009/06/04 1.4 T.Kitajima MOD START ******************************--
--      gn_warn_cnt    :=  gn_warn_cnt  +  1;
        gn_msg_cnt     :=  gn_msg_cnt  +  1;
--****************************** 2009/06/04 1.4 T.Kitajima MOD  END  ******************************--
      --エラー出力
       FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg
       );
    END IF;
    -- * -------------------------------------------------------------
    --
    IF ( lv_invoice_number_err_flag IS NULL ) THEN
      --データ正常に取得できた場合
      IF  ( ov_retcode =  cv_status_normal ) THEN
        --単位（EBS）の設定
        gt_req_edi_inv_data(in_line_cnt).ebs_uom_code := lt_unit_of_measure;
      END IF;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_inventory_edit
      --  * Description      : EDI在庫情報変数の編集(A-2)(1)
      --* -------------------------------------------------------------
      xxcos_in_edi_inventory_edit(
        in_line_cnt,   --   LOOP用カウンタ2
        lv_errbuf,     --   エラー・メッセージ 
        lv_retcode,    --   リターン・コード
        lv_errmsg      --   ユーザー・エラー・メッセージ
        );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
    ELSIF ( lv_invoice_number_err_flag = cv_inv_num_err_flag ) THEN
      gn_error_cnt := gn_error_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
    END IF;
    --* -------------------------------------------------------------
    --* -------------------------------------------------------------
    --  伝票番号キーブレイク編集
    --* -------------------------------------------------------------
    --* -------------------------------------------------------------
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod start
--    IF  (( gv_inv_invoice_number_key IS NULL )  
--    OR   ( gv_inv_invoice_number_key <> gt_req_edi_inv_data(in_line_cnt).invoice_number ))
--    THEN
    IF  (( gv_inv_invoice_number_key IS NULL )  
    OR   ( gv_inv_invoice_number_key <> gt_req_edi_inv_data(in_line_cnt).shop_code 
                                     || gt_req_edi_inv_data(in_line_cnt).invoice_number ))
    THEN
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
      --
      gn_normal_inventry_cnt     := gn_normal_inventry_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_invoice_num_add
      -- * Description      : 伝票別合計変数への追加(A-4)(1)
      --* -------------------------------------------------------------
      xxcos_in_invoice_num_add(
        gn_normal_inventry_cnt,
        in_line_cnt,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- 伝票番号
      gt_sum_edi_inv_data(gn_normal_inventry_cnt).invoice_number    := 
                                 gt_req_edi_inv_data(in_line_cnt).invoice_number;
--
    ELSE
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_invoice_num_up
      -- * Description      : 伝票別合計変数へ数量を加算(A-5)
      --* -------------------------------------------------------------
      xxcos_in_invoice_num_up(
        gn_normal_inventry_cnt,
        in_line_cnt,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod start
    -- ブレーク用変数を店舗コード+伝票番号に変更
    -- 伝票番号のセット
--    gv_inv_invoice_number_key  := gt_req_edi_inv_data(in_line_cnt).invoice_number;
    gv_inv_invoice_number_key  := gt_req_edi_inv_data(in_line_cnt).shop_code
                               || gt_req_edi_inv_data(in_line_cnt).invoice_number;
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Mod End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inv_wk_update
   * Description      : EDI在庫情報ワークテーブルへの更新(A-7)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inv_wk_update(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inv_wk_update'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    BEGIN
      --* -------------------------------------------------------------
      -- EDI在庫情報ワークテーブル XXCOS_EDI_INVENTORY_WORK UPDATE
      --* -------------------------------------------------------------
      UPDATE xxcos_edi_inventory_work
         SET err_status             =  cv_run_class_name,      -- ステータス
             last_updated_by        =  cn_last_updated_by,      -- 最終更新者
             last_update_date       =  cd_last_update_date,     -- 最終更新日
             last_update_login      =  cn_last_update_login,    -- 最終更新ログイン
             request_id             =  cn_request_id,           -- 要求ID
                                    -- コンカレント・プログラム・アプリケーションID
             program_application_id =  cn_program_application_id, 
             program_id             =  cn_program_id,           -- コンカレント・プログラムID
             program_update_date    =  cd_program_update_date   -- プログラム更新日
      WHERE if_file_name  = iv_file_name;
--
      --コンカレントは異常終了させる為ここでコミットする
      COMMIT;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI在庫情報ワークテーブル
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_update_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inv_work,
                        iv_token_value2       =>  gv_err_ediinv_work_flag
                        );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    --
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
----#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inv_wk_update;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_insert
   * Description      : EDI在庫情報テーブルへのデータ挿入(A-6)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_insert(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_insert'; -- プログラム名
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
    --* -------------------------------------------------------------
    -- * Procedure Name   : xxcos_in_invoice_num_req
    -- * Description      : 伝票別合計変数への再編集(A-4)(2)
    --* -------------------------------------------------------------
    xxcos_in_invoice_num_req(
      gn_normal_inventry_cnt,
      lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      lv_retcode,      -- リターン・コード             --# 固定 #
      lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------
    -- ループ開始：
    --* -------------------------------------------------------------
    <<xxcos_edi_inventory_insert>>
--****************************** 2009/06/04 1.4 T.Kitajima MOD START ******************************--
--    FOR  ln_no  IN  1..gn_normal_cnt  LOOP
    FOR  ln_no  IN  1..gt_req_edi_inv_data.COUNT  LOOP
--****************************** 2009/06/04 1.4 T.Kitajima MOD  END  ******************************--
      --* -------------------------------------------------------------
      --* Description      : EDI在庫情報テーブルへのデータ挿入(A-6)
      --* -------------------------------------------------------------
      INSERT INTO xxcos_edi_inventory
        (
          stk_info_id,                      -- 在庫情報id
          medium_class,                     -- 媒体区分
          data_type_code,                   -- データ種コード
          file_no,                          -- ファイルＮＯ
          info_class,                       -- 情報区分
          process_date,                     -- 処理日
          process_time,                     -- 処理時刻
          base_code,                        -- 拠点（部門）コード
          base_name,                        -- 拠点名（正式名）
          base_name_alt,                    -- 拠点名（カナ）
          edi_chain_code,                   -- ＥＤＩチェーン店コード
          edi_chain_name,                   -- ＥＤＩチェーン店名（漢字）
          edi_chain_name_alt,               -- ＥＤＩチェーン店名（カナ）
          report_code,                      -- 帳票コード
          report_show_name,                 -- 帳票表示名
          customer_code,                    -- 顧客コード
          customer_name,                    -- 顧客名（漢字）
          customer_name_alt,                -- 顧客名（カナ）
          company_code,                     -- 社コード
          company_name_alt,                 -- 社名（カナ）
          shop_code,                        -- 店コード
          shop_name_alt,                    -- 店名（カナ）
          delivery_center_code,             -- 納入センターコード
          delivery_center_name,             -- 納入センター名（漢字）
          delivery_center_name_alt,         -- 納入センター名（カナ）
          whse_code,                        -- 倉庫コード
          whse_name,                        -- 倉庫名
          inspect_charge_name,              -- 検品担当者名（漢字）
          inspect_charge_name_alt,          -- 検品担当者名（カナ）
          return_charge_name,               -- 返品担当者名（漢字）
          return_charge_name_alt,           -- 返品担当者名（カナ）
          receive_charge_name,              -- 受領担当者名（漢字）
          receive_charge_name_alt,          -- 受領担当者名（カナ）
          order_date,                       -- 発注日
          center_delivery_date,             -- センター納品日
          center_result_delivery_date,      -- センター実納品日
          center_shipping_date,             -- センター出庫日
          center_result_shipping_date,      -- センター実出庫日
          data_creation_date_edi_data,      -- データ作成日（ＥＤＩデータ中）
          data_creation_time_edi_data,      -- データ作成時刻（ＥＤＩデータ中）
          stk_date,                         -- 在庫日付
          offer_vendor_code_class,          -- 提供企業取引先コード区分
          whse_vendor_code_class,           -- 倉庫取引先コード区分
          offer_cycle_class,                -- 提供サイクル区分
          stk_type,                         -- 在庫種類
          japanese_class,                   -- 日本語区分
          whse_class,                       -- 倉庫区分
          vendor_code,                      -- 取引先コード
          vendor_name,                      -- 取引先名（漢字）
          vendor_name_alt,                  -- 取引先名（カナ）
          check_digit_class,                -- チェックデジット有無区分
          invoice_number,                   -- 伝票番号
          check_digit,                      -- チェックデジット
          chain_peculiar_area_header,       -- チェーン店固有エリア（ヘッダ）
          product_code_itouen,              -- 商品コード（伊藤園）
          product_code_other_party,         -- 商品コード（先方）
          jan_code,                         -- ＪＡＮコード
          itf_code,                         -- ＩＴＦコード
          product_name,                     -- 商品名（漢字）
          product_name_alt,                 -- 商品名（カナ）
          prod_class,                       -- 商品区分
          active_quality_class,             -- 適用品質区分
          qty_in_case,                      -- 入数
          uom_code,                         -- 単位
          day_average_shipping_qty,         -- 一日平均出荷数量
          stk_type_code,                    -- 在庫種別コード
          last_arrival_date,                -- 最終入荷日
          use_by_date,                      -- 賞味期限
          product_date,                     -- 製造日
          upper_limit_stk_case,             -- 上限在庫（ケース）
          upper_limit_stk_indv,             -- 上限在庫（バラ）
          indv_order_point,                 -- 発注点（バラ）
          case_order_point,                 -- 発注点（ケース）
          indv_prev_month_stk_qty,          -- 前月末在庫数量（バラ）
          case_prev_month_stk_qty,          -- 前月末在庫数量（ケース）
          sum_prev_month_stk_qty,           -- 前月在庫数量（合計）
          day_indv_order_qty,               -- 発注数量（当日、バラ）
          day_case_order_qty,               -- 発注数量（当日、ケース）
          day_sum_order_qty,                -- 発注数量（当日、合計）
          month_indv_order_qty,             -- 発注数量（当月、バラ）
          month_case_order_qty,             -- 発注数量（当月、ケース）
          month_sum_order_qty,              -- 発注数量（当月、合計）
          day_indv_arrival_qty,             -- 入庫数量（当日、バラ）
          day_case_arrival_qty,             -- 入庫数量（当日、ケース）
          day_sum_arrival_qty,              -- 入庫数量（当日、合計）
          month_arrival_count,              -- 当月入荷回数
          month_indv_arrival_qty,           -- 入庫数量（当月、バラ）
          month_case_arrival_qty,           -- 入庫数量（当月、ケース）
          month_sum_arrival_qty,            -- 入庫数量（当月、合計）
          day_indv_shipping_qty,            -- 出庫数量（当日、バラ）
          day_case_shipping_qty,            -- 出庫数量（当日、ケース）
          day_sum_shipping_qty,             -- 出庫数量（当日、合計）
          month_indv_shipping_qty,          -- 出庫数量（当月、バラ）
          month_case_shipping_qty,          -- 出庫数量（当月、ケース）
          month_sum_shipping_qty,           -- 出庫数量（当月、合計）
          day_indv_destroy_loss_qty,        -- 破棄、ロス数量（当日、バラ）
          day_case_destroy_loss_qty,        -- 破棄、ロス数量（当日、ケース）
          day_sum_destroy_loss_qty,         -- 破棄、ロス数量（当日、合計）
          month_indv_destroy_loss_qty,      -- 破棄、ロス数量（当月、バラ）
          month_case_destroy_loss_qty,      -- 破棄、ロス数量（当月、ケース）
          month_sum_destroy_loss_qty,       -- 破棄、ロス数量（当月、合計）
          day_indv_defect_stk_qty,          -- 不良在庫数量（当日、バラ）
          day_case_defect_stk_qty,          -- 不良在庫数量（当日、ケース）
          day_sum_defect_stk_qty,           -- 不良在庫数量（当日、合計）
          month_indv_defect_stk_qty,        -- 不良在庫数量（当月、バラ）
          month_case_defect_stk_qty,        -- 不良在庫数量（当月、ケース）
          month_sum_defect_stk_qty,         -- 不良在庫数量（当月、合計）
          day_indv_defect_return_qty,       -- 不良返品数量（当日、バラ）
          day_case_defect_return_qty,       -- 不良返品数量（当日、ケース）
          day_sum_defect_return_qty,        -- 不良返品数量（当日、合計）
          month_indv_defect_return_qty,     -- 不良返品数量（当月、バラ）
          month_case_defect_return_qty,     -- 不良返品数量（当月、ケース）
          month_sum_defect_return_qty,      -- 不良返品数量（当月、合計）
          day_indv_defect_return_rcpt,      -- 不良返品受入（当日、バラ）
          day_case_defect_return_rcpt,      -- 不良返品受入（当日、ケース）
          day_sum_defect_return_rcpt,       -- 不良返品受入（当日、合計）
          month_indv_defect_return_rcpt,    -- 不良返品受入（当月、バラ）
          month_case_defect_return_rcpt,    -- 不良返品受入（当月、ケース）
          month_sum_defect_return_rcpt,     -- 不良返品受入（当月、合計）
          day_indv_defect_return_send,      -- 不良返品発送（当日、バラ）
          day_case_defect_return_send,      -- 不良返品発送（当日、ケース）
          day_sum_defect_return_send,       -- 不良返品発送（当日、合計）
          month_indv_defect_return_send,    -- 不良返品発送（当月、バラ）
          month_case_defect_return_send,    -- 不良返品発送（当月、ケース）
          month_sum_defect_return_send,     -- 不良返品発送（当月、合計）
          day_indv_quality_return_rcpt,     -- 良品返品受入（当日、バラ）
          day_case_quality_return_rcpt,     -- 良品返品受入（当日、ケース）
          day_sum_quality_return_rcpt,      -- 良品返品受入（当日、合計）
          month_indv_quality_return_rcpt,   -- 良品返品受入（当月、バラ）
          month_case_quality_return_rcpt,   -- 良品返品受入（当月、ケース）
          month_sum_quality_return_rcpt,    -- 良品返品受入（当月、合計）
          day_indv_quality_return_send,     -- 良品返品発送（当日、バラ）
          day_case_quality_return_send,     -- 良品返品発送（当日、ケース）
          day_sum_quality_return_send,      -- 良品返品発送（当日、合計）
          month_indv_quality_return_send,   -- 良品返品発送（当月、バラ）
          month_case_quality_return_send,   -- 良品返品発送（当月、ケース）
          month_sum_quality_return_send,    -- 良品返品発送（当月、合計）
          day_indv_invent_difference,       -- 棚卸差異（当日、バラ）
          day_case_invent_difference,       -- 棚卸差異（当日、ケース）
          day_sum_invent_difference,        -- 棚卸差異（当日、合計）
          month_indv_invent_difference,     -- 棚卸差異（当月、バラ）
          month_case_invent_difference,     -- 棚卸差異（当月、ケース）
          month_sum_invent_difference,      -- 棚卸差異（当月、合計）
          day_indv_stk_qty,                 -- 在庫数量（当日、バラ）
          day_case_stk_qty,                 -- 在庫数量（当日、ケース）
          day_sum_stk_qty,                  -- 在庫数量（当日、合計）
          month_indv_stk_qty,               -- 在庫数量（当月、バラ）
          month_case_stk_qty,               -- 在庫数量（当月、ケース）
          month_sum_stk_qty,                -- 在庫数量（当月、合計）
          day_indv_reserved_stk_qty,        -- 保留在庫数（当日、バラ）
          day_case_reserved_stk_qty,        -- 保留在庫数（当日、ケース）
          day_sum_reserved_stk_qty,         -- 保留在庫数（当日、合計）
          month_indv_reserved_stk_qty,      -- 保留在庫数（当月、バラ）
          month_case_reserved_stk_qty,      -- 保留在庫数（当月、ケース）
          month_sum_reserved_stk_qty,       -- 保留在庫数（当月、合計）
          day_indv_cd_stk_qty,              -- 商流在庫数量（当日、バラ）
          day_case_cd_stk_qty,              -- 商流在庫数量（当日、ケース）
          day_sum_cd_stk_qty,               -- 商流在庫数量（当日、合計）
          month_indv_cd_stk_qty,            -- 商流在庫数量（当月、バラ）
          month_case_cd_stk_qty,            -- 商流在庫数量（当月、ケース）
          month_sum_cd_stk_qty,             -- 商流在庫数量（当月、合計）
          day_indv_cargo_stk_qty,           -- 積送在庫数量（当日、バラ）
          day_case_cargo_stk_qty,           -- 積送在庫数量（当日、ケース）
          day_sum_cargo_stk_qty,            -- 積送在庫数量（当日、合計）
          month_indv_cargo_stk_qty,         -- 積送在庫数量（当月、バラ）
          month_case_cargo_stk_qty,         -- 積送在庫数量（当月、ケース）
          month_sum_cargo_stk_qty,          -- 積送在庫数量（当月、合計）
          day_indv_adjustment_stk_qty,      -- 調整在庫数量（当日、バラ）
          day_case_adjustment_stk_qty,      -- 調整在庫数量（当日、ケース）
          day_sum_adjustment_stk_qty,       -- 調整在庫数量（当日、合計）
          month_indv_adjustment_stk_qty,    -- 調整在庫数量（当月、バラ）
          month_case_adjustment_stk_qty,    -- 調整在庫数量（当月、ケース）
          month_sum_adjustment_stk_qty,     -- 調整在庫数量（当月、合計）
          day_indv_still_shipping_qty,      -- 未出荷数量（当日、バラ）
          day_case_still_shipping_qty,      -- 未出荷数量（当日、ケース）
          day_sum_still_shipping_qty,       -- 未出荷数量（当日、合計）
          month_indv_still_shipping_qty,    -- 未出荷数量（当月、バラ）
          month_case_still_shipping_qty,    -- 未出荷数量（当月、ケース）
          month_sum_still_shipping_qty,     -- 未出荷数量（当月、合計）
          indv_all_stk_qty,                 -- 総在庫数量（バラ）
          case_all_stk_qty,                 -- 総在庫数量（ケース）
          sum_all_stk_qty,                  -- 総在庫数量（合計）
          month_draw_count,                 -- 当月引当回数
          day_indv_draw_possible_qty,       -- 引当可能数量（当日、バラ）
          day_case_draw_possible_qty,       -- 引当可能数量（当日、ケース）
          day_sum_draw_possible_qty,        -- 引当可能数量（当日、合計）
          month_indv_draw_possible_qty,     -- 引当可能数量（当月、バラ）
          month_case_draw_possible_qty,     -- 引当可能数量（当月、ケース）
          month_sum_draw_possible_qty,      -- 引当可能数量（当月、合計）
          day_indv_draw_impossible_qty,     -- 引当不能数（当日、バラ）
          day_case_draw_impossible_qty,     -- 引当不能数（当日、ケース）
          day_sum_draw_impossible_qty,      -- 引当不能数（当日、合計）
          day_stk_amt,                      -- 在庫金額（当日）
          month_stk_amt,                    -- 在庫金額（当月）
          remarks,                          -- 備考
          chain_peculiar_area_line,         -- チェーン店固有エリア（明細）
          invoice_day_indv_sum_stk_qty,     -- 伝票計）在庫数量合計（当日、バラ）
          invoice_day_case_sum_stk_qty,     -- 伝票計）在庫数量合計（当日、ケース）
          invoice_day_sum_sum_stk_qty,      -- 伝票計）在庫数量合計（当日、合計）
          invoice_month_indv_sum_stk_qty,   -- 伝票計）在庫数量合計（当月、バラ）
          invoice_month_case_sum_stk_qty,   -- 伝票計）在庫数量合計（当月、ケース）
          invoice_month_sum_sum_stk_qty,    -- 伝票計）在庫数量合計（当月、合計）
          invoice_day_indv_cd_stk_qty,      -- 伝票計）商流在庫数量（当日、バラ）
          invoice_day_case_cd_stk_qty,      -- 伝票計）商流在庫数量（当日、ケース）
          invoice_day_sum_cd_stk_qty,       -- 伝票計）商流在庫数量（当日、合計）
          invoice_month_indv_cd_stk_qty,    -- 伝票計）商流在庫数量（当月、バラ）
          invoice_month_case_cd_stk_qty,    -- 伝票計）商流在庫数量（当月、ケース）
          invoice_month_sum_cd_stk_qty,     -- 伝票計）商流在庫数量（当月、合計）
          invoice_day_stk_amt,              -- 伝票計）在庫金額（当日）
          invoice_month_stk_amt,            -- 伝票計）在庫金額（当月）
          regular_sell_amt_sum,             -- 正販金額合計
          rebate_amt_sum,                   -- 割戻し金額合計
          collect_bottle_amt_sum,           -- 回収容器金額合計
          chain_peculiar_area_footer,       -- チェーン店固有エリア（フッター）
          conv_customer_code,               -- 顧客コード1
          item_code,                        -- 品目コード
          ebs_uom_code,                     -- 単位コード(EBS)
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date,
/* 2011/07/28 Ver1.8 Mod Start */
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add Start
--          edi_received_date
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add End
          edi_received_date,
/* 2011/07/28 Ver1.8 Mod End   */
/* 2011/07/28 Ver1.8 Add Start */
          bms_header_data,
          bms_line_data
/* 2011/07/28 Ver1.8 Add End   */
        )
      VALUES
        (
          xxcos_edi_inventory_s01.NEXTVAL,                            -- 在庫情報ID
          gt_req_edi_inv_data(ln_no).medium_class,                     -- 媒体区分
          gt_req_edi_inv_data(ln_no).data_type_code,                   -- データ種コード
          gt_req_edi_inv_data(ln_no).file_no,                          -- ファイルＮＯ
          gt_req_edi_inv_data(ln_no).info_class,                       -- 情報区分
          gt_req_edi_inv_data(ln_no).process_date,                     -- 処理日
          gt_req_edi_inv_data(ln_no).process_time,                     -- 処理時刻
          gt_req_edi_inv_data(ln_no).base_code,                        -- 拠点（部門）コード
          gt_req_edi_inv_data(ln_no).base_name,                        -- 拠点名（正式名）
          gt_req_edi_inv_data(ln_no).base_name_alt,                    -- 拠点名（カナ）
          gt_req_edi_inv_data(ln_no).edi_chain_code,                   -- ＥＤＩチェーン店コード
          gt_req_edi_inv_data(ln_no).edi_chain_name,                   -- ＥＤＩチェーン店名（漢字）
          gt_req_edi_inv_data(ln_no).edi_chain_name_alt,               -- ＥＤＩチェーン店名（カナ）
          gt_req_edi_inv_data(ln_no).report_code,                      -- 帳票コード
          gt_req_edi_inv_data(ln_no).report_show_name,                 -- 帳票表示名
          gt_req_edi_inv_data(ln_no).customer_code,                    -- 顧客コード
          gt_req_edi_inv_data(ln_no).customer_name,                    -- 顧客名（漢字）
          gt_req_edi_inv_data(ln_no).customer_name_alt,                -- 顧客名（カナ）
          gt_req_edi_inv_data(ln_no).company_code,                     -- 社コード
          gt_req_edi_inv_data(ln_no).company_name_alt,                 -- 社名（カナ）
          gt_req_edi_inv_data(ln_no).shop_code,                        -- 店コード
          gt_req_edi_inv_data(ln_no).shop_name_alt,                    -- 店名（カナ）
          gt_req_edi_inv_data(ln_no).delivery_center_code,             -- 納入センターコード
          gt_req_edi_inv_data(ln_no).delivery_center_name,             -- 納入センター名（漢字）
          gt_req_edi_inv_data(ln_no).delivery_center_name_alt,         -- 納入センター名（カナ）
          gt_req_edi_inv_data(ln_no).whse_code,                        -- 倉庫コード
          gt_req_edi_inv_data(ln_no).whse_name,                        -- 倉庫名
          gt_req_edi_inv_data(ln_no).inspect_charge_name,              -- 検品担当者名（漢字）
          gt_req_edi_inv_data(ln_no).inspect_charge_name_alt,          -- 検品担当者名（カナ）
          gt_req_edi_inv_data(ln_no).return_charge_name,               -- 返品担当者名（漢字）
          gt_req_edi_inv_data(ln_no).return_charge_name_alt,           -- 返品担当者名（カナ）
          gt_req_edi_inv_data(ln_no).receive_charge_name,              -- 受領担当者名（漢字）
          gt_req_edi_inv_data(ln_no).receive_charge_name_alt,          -- 受領担当者名（カナ）
          gt_req_edi_inv_data(ln_no).order_date,                       -- 発注日
          gt_req_edi_inv_data(ln_no).center_delivery_date,             -- センター納品日
          gt_req_edi_inv_data(ln_no).center_result_delivery_date,      -- センター実納品日
          gt_req_edi_inv_data(ln_no).center_shipping_date,             -- センター出庫日
          gt_req_edi_inv_data(ln_no).center_result_shipping_date,      -- センター実出庫日
          gt_req_edi_inv_data(ln_no).data_creation_date_edi_data,      -- データ作成日（ＥＤＩデータ中）
          gt_req_edi_inv_data(ln_no).data_creation_time_edi_data,      -- データ作成時刻（ＥＤＩデータ中）
          gt_req_edi_inv_data(ln_no).stk_date,                         -- 在庫日付
          gt_req_edi_inv_data(ln_no).offer_vendor_code_class,          -- 提供企業取引先コード区分
          gt_req_edi_inv_data(ln_no).whse_vendor_code_class,           -- 倉庫取引先コード区分
          gt_req_edi_inv_data(ln_no).offer_cycle_class,                -- 提供サイクル区分
          gt_req_edi_inv_data(ln_no).stk_type,                         -- 在庫種類
          gt_req_edi_inv_data(ln_no).japanese_class,                   -- 日本語区分
          gt_req_edi_inv_data(ln_no).whse_class,                       -- 倉庫区分
          gt_req_edi_inv_data(ln_no).vendor_code,                      -- 取引先コード
          gt_req_edi_inv_data(ln_no).vendor_name,                      -- 取引先名（漢字）
          gt_req_edi_inv_data(ln_no).vendor_name_alt,                  -- 取引先名（カナ）
          gt_req_edi_inv_data(ln_no).check_digit_class,                -- チェックデジット有無区分
          gt_req_edi_inv_data(ln_no).invoice_number,                   -- 伝票番号
          gt_req_edi_inv_data(ln_no).check_digit,                      -- チェックデジット
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_header,       -- チェーン店固有エリア（ヘッダ）
          gt_req_edi_inv_data(ln_no).product_code_itouen,              -- 商品コード（伊藤園）
          gt_req_edi_inv_data(ln_no).product_code_other_party,         -- 商品コード（先方）
          gt_req_edi_inv_data(ln_no).jan_code,                         -- ＪＡＮコード
          gt_req_edi_inv_data(ln_no).itf_code,                         -- ＩＴＦコード
          gt_req_edi_inv_data(ln_no).product_name,                     -- 商品名（漢字）
          gt_req_edi_inv_data(ln_no).product_name_alt,                 -- 商品名（カナ）
          gt_req_edi_inv_data(ln_no).prod_class,                       -- 商品区分
          gt_req_edi_inv_data(ln_no).active_quality_class,             -- 適用品質区分
          gt_req_edi_inv_data(ln_no).qty_in_case,                      -- 入数
          gt_req_edi_inv_data(ln_no).uom_code,                         -- 単位
          gt_req_edi_inv_data(ln_no).day_average_shipping_qty,         -- 一日平均出荷数量
          gt_req_edi_inv_data(ln_no).stk_type_code,                    -- 在庫種別コード
          gt_req_edi_inv_data(ln_no).last_arrival_date,                -- 最終入荷日
          gt_req_edi_inv_data(ln_no).use_by_date,                      -- 賞味期限
          gt_req_edi_inv_data(ln_no).product_date,                     -- 製造日
          gt_req_edi_inv_data(ln_no).upper_limit_stk_case,             -- 上限在庫（ケース）
          gt_req_edi_inv_data(ln_no).upper_limit_stk_indv,             -- 上限在庫（バラ）
          gt_req_edi_inv_data(ln_no).indv_order_point,                 -- 発注点（バラ）
          gt_req_edi_inv_data(ln_no).case_order_point,                 -- 発注点（ケース）
          gt_req_edi_inv_data(ln_no).indv_prev_month_stk_qty,          -- 前月末在庫数量（バラ）
          gt_req_edi_inv_data(ln_no).case_prev_month_stk_qty,          -- 前月末在庫数量（ケース）
          gt_req_edi_inv_data(ln_no).sum_prev_month_stk_qty,           -- 前月在庫数量（合計）
          gt_req_edi_inv_data(ln_no).day_indv_order_qty,               -- 発注数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_order_qty,               -- 発注数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_order_qty,                -- 発注数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_order_qty,             -- 発注数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_order_qty,             -- 発注数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_order_qty,              -- 発注数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_arrival_qty,             -- 入庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_arrival_qty,             -- 入庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_arrival_qty,              -- 入庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_arrival_count,              -- 当月入荷回数
          gt_req_edi_inv_data(ln_no).month_indv_arrival_qty,           -- 入庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_arrival_qty,           -- 入庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_arrival_qty,            -- 入庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_shipping_qty,            -- 出庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_shipping_qty,            -- 出庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_shipping_qty,             -- 出庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_shipping_qty,          -- 出庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_shipping_qty,          -- 出庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_shipping_qty,           -- 出庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_destroy_loss_qty,        -- 破棄、ロス数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_destroy_loss_qty,        -- 破棄、ロス数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_destroy_loss_qty,         -- 破棄、ロス数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_destroy_loss_qty,      -- 破棄、ロス数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_destroy_loss_qty,      -- 破棄、ロス数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_destroy_loss_qty,       -- 破棄、ロス数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_defect_stk_qty,          -- 不良在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_defect_stk_qty,          -- 不良在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_defect_stk_qty,           -- 不良在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_defect_stk_qty,        -- 不良在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_defect_stk_qty,        -- 不良在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_defect_stk_qty,         -- 不良在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_qty,       -- 不良返品数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_defect_return_qty,       -- 不良返品数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_qty,        -- 不良返品数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_qty,     -- 不良返品数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_defect_return_qty,     -- 不良返品数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_qty,      -- 不良返品数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_rcpt,      -- 不良返品受入（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_defect_return_rcpt,      -- 不良返品受入（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_rcpt,       -- 不良返品受入（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_rcpt,    -- 不良返品受入（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_defect_return_rcpt,    -- 不良返品受入（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_rcpt,     -- 不良返品受入（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_send,      -- 不良返品発送（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_defect_return_send,      -- 不良返品発送（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_send,       -- 不良返品発送（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_send,    -- 不良返品発送（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_defect_return_send,    -- 不良返品発送（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_send,     -- 不良返品発送（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_quality_return_rcpt,     -- 良品返品受入（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_quality_return_rcpt,     -- 良品返品受入（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_quality_return_rcpt,      -- 良品返品受入（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_quality_return_rcpt,   -- 良品返品受入（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_quality_return_rcpt,   -- 良品返品受入（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_quality_return_rcpt,    -- 良品返品受入（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_quality_return_send,     -- 良品返品発送（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_quality_return_send,     -- 良品返品発送（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_quality_return_send,      -- 良品返品発送（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_quality_return_send,   -- 良品返品発送（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_quality_return_send,   -- 良品返品発送（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_quality_return_send,    -- 良品返品発送（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_invent_difference,       -- 棚卸差異（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_invent_difference,       -- 棚卸差異（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_invent_difference,        -- 棚卸差異（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_invent_difference,     -- 棚卸差異（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_invent_difference,     -- 棚卸差異（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_invent_difference,      -- 棚卸差異（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_stk_qty,                 -- 在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_stk_qty,                 -- 在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_stk_qty,                  -- 在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_stk_qty,               -- 在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_stk_qty,               -- 在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_stk_qty,                -- 在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_reserved_stk_qty,        -- 保留在庫数（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_reserved_stk_qty,        -- 保留在庫数（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_reserved_stk_qty,         -- 保留在庫数（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_reserved_stk_qty,      -- 保留在庫数（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_reserved_stk_qty,      -- 保留在庫数（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_reserved_stk_qty,       -- 保留在庫数（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_cd_stk_qty,              -- 商流在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_cd_stk_qty,              -- 商流在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_cd_stk_qty,               -- 商流在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_cd_stk_qty,            -- 商流在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_cd_stk_qty,            -- 商流在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_cd_stk_qty,             -- 商流在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_cargo_stk_qty,           -- 積送在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_cargo_stk_qty,           -- 積送在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_cargo_stk_qty,            -- 積送在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_cargo_stk_qty,         -- 積送在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_cargo_stk_qty,         -- 積送在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_cargo_stk_qty,          -- 積送在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_adjustment_stk_qty,      -- 調整在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_adjustment_stk_qty,      -- 調整在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_adjustment_stk_qty,       -- 調整在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_adjustment_stk_qty,    -- 調整在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_adjustment_stk_qty,    -- 調整在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_adjustment_stk_qty,     -- 調整在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_still_shipping_qty,      -- 未出荷数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_still_shipping_qty,      -- 未出荷数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_still_shipping_qty,       -- 未出荷数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_still_shipping_qty,    -- 未出荷数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_still_shipping_qty,    -- 未出荷数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_still_shipping_qty,     -- 未出荷数量（当月、合計）
          gt_req_edi_inv_data(ln_no).indv_all_stk_qty,                 -- 総在庫数量（バラ）
          gt_req_edi_inv_data(ln_no).case_all_stk_qty,                 -- 総在庫数量（ケース）
          gt_req_edi_inv_data(ln_no).sum_all_stk_qty,                  -- 総在庫数量（合計）
          gt_req_edi_inv_data(ln_no).month_draw_count,                 -- 当月引当回数
          gt_req_edi_inv_data(ln_no).day_indv_draw_possible_qty,       -- 引当可能数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_draw_possible_qty,       -- 引当可能数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_draw_possible_qty,        -- 引当可能数量（当日、合計）
          gt_req_edi_inv_data(ln_no).month_indv_draw_possible_qty,     -- 引当可能数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).month_case_draw_possible_qty,     -- 引当可能数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).month_sum_draw_possible_qty,      -- 引当可能数量（当月、合計）
          gt_req_edi_inv_data(ln_no).day_indv_draw_impossible_qty,     -- 引当不能数（当日、バラ）
          gt_req_edi_inv_data(ln_no).day_case_draw_impossible_qty,     -- 引当不能数（当日、ケース）
          gt_req_edi_inv_data(ln_no).day_sum_draw_impossible_qty,      -- 引当不能数（当日、合計）
          gt_req_edi_inv_data(ln_no).day_stk_amt,                      -- 在庫金額（当日）
          gt_req_edi_inv_data(ln_no).month_stk_amt,                    -- 在庫金額（当月）
          gt_req_edi_inv_data(ln_no).remarks,                          -- 備考
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_line,         -- チェーン店固有エリア（明細）
          gt_req_edi_inv_data(ln_no).invoice_day_indv_sum_stk_qty,     -- 伝票計）在庫数量合計（当日、バラ）
          gt_req_edi_inv_data(ln_no).invoice_day_case_sum_stk_qty,     -- 伝票計）在庫数量合計（当日、ケース）
          gt_req_edi_inv_data(ln_no).invoice_day_sum_sum_stk_qty,      -- 伝票計）在庫数量合計（当日、合計）
          gt_req_edi_inv_data(ln_no).invoice_month_indv_sum_stk_qty,   -- 伝票計）在庫数量合計（当月、バラ）
          gt_req_edi_inv_data(ln_no).invoice_month_case_sum_stk_qty,   -- 伝票計）在庫数量合計（当月、ケース）
          gt_req_edi_inv_data(ln_no).invoice_month_sum_sum_stk_qty,    -- 伝票計）在庫数量合計（当月、合計）
          gt_req_edi_inv_data(ln_no).invoice_day_indv_cd_stk_qty,      -- 伝票計）商流在庫数量（当日、バラ）
          gt_req_edi_inv_data(ln_no).invoice_day_case_cd_stk_qty,      -- 伝票計）商流在庫数量（当日、ケース）
          gt_req_edi_inv_data(ln_no).invoice_day_sum_cd_stk_qty,       -- 伝票計）商流在庫数量（当日、合計）
          gt_req_edi_inv_data(ln_no).invoice_month_indv_cd_stk_qty,    -- 伝票計）商流在庫数量（当月、バラ）
          gt_req_edi_inv_data(ln_no).invoice_month_case_cd_stk_qty,    -- 伝票計）商流在庫数量（当月、ケース）
          gt_req_edi_inv_data(ln_no).invoice_month_sum_cd_stk_qty,     -- 伝票計）商流在庫数量（当月、合計）
          gt_req_edi_inv_data(ln_no).invoice_day_stk_amt,              -- 伝票計）在庫金額（当日）
          gt_req_edi_inv_data(ln_no).invoice_month_stk_amt,            -- 伝票計）在庫金額（当月）
          gt_req_edi_inv_data(ln_no).regular_sell_amt_sum,             -- 正販金額合計
          gt_req_edi_inv_data(ln_no).rebate_amt_sum,                   -- 割戻し金額合計
          gt_req_edi_inv_data(ln_no).collect_bottle_amt_sum,           -- 回収容器金額合計
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_footer,       -- チェーン店固有エリア（フッター）
          gt_req_edi_inv_data(ln_no).conv_customer_code,               -- 変換後顧客コード
          gt_req_edi_inv_data(ln_no).item_code,                        -- 品目コード
          gt_req_edi_inv_data(ln_no).ebs_uom_code,                     -- 単位コード（EBS）
          cn_created_by,                      -- 作成者
          cd_creation_date,                   -- 作成日
          cn_last_updated_by,                 -- 最終更新者
          cd_last_update_date,                -- 最終更新日
          cn_last_update_login,               -- 最終更新ログイン
          cn_request_id,                      -- 要求ID
          cn_program_application_id,          -- コンカレント・プログラム・アプリケーションID
          cn_program_id,                      -- コンカレント・プログラムID
          cd_program_update_date,             -- プログラム更新日
/* 2011/07/28 Ver1.8 Mod Start */
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add Start
--          gt_req_edi_inv_data(ln_no).edi_received_date                 -- EDI受信日
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakano Add End
          gt_req_edi_inv_data(ln_no).edi_received_date,                -- EDI受信日
/* 2011/07/28 Ver1.8 Mod End   */
/* 2011/07/28 Ver1.8 Add Start */
          gt_req_edi_inv_data(ln_no).bms_header_data,                  -- 流通ＢＭＳヘッダデータ
          gt_req_edi_inv_data(ln_no).bms_line_data                     -- 流通ＢＭＳ明細データ
/* 2011/07/28 Ver1.8 Add End   */
        );
--
    END LOOP  xxcos_edi_inventory_insert;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
    gn_normal_cnt := gt_req_edi_inv_data.COUNT;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inventory_insert;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inv_work_delete
   * Description      : EDI在庫情報ワークテーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inv_work_delete(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inv_work_delete'; -- プログラム名
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
    BEGIN
      DELETE FROM xxcos_edi_inventory_work ediinvwk
       WHERE   ediinvwk.if_file_name     =    iv_file_name       -- インタフェースファイル名
         AND   ediinvwk.err_status       =    iv_run_class       -- ステータス
         AND (( iv_edi_chain_code IS NOT NULL
           AND   ediinvwk.edi_chain_code   =  iv_edi_chain_code )  -- EDIチェーン店コード
           OR ( iv_edi_chain_code IS NULL ));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI在庫情報ワークテーブル
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_delete_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inv_work,
                        iv_token_value2       =>  gv_run_data_type_code
                        );
        lv_errbuf       := SQLERRM;
        RAISE global_api_expt;
    END;
    --
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inv_work_delete ;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_lock
   * Description      : EDI在庫情報テーブルロック(A-8)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_lock(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_lock'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    -- ===============================
    -- EDI在庫情報ＴＢＬの在庫情報削除期間が過ぎたデータ
    -- ===============================
    CURSOR edi_inventory_lock_cur
    IS
      SELECT edi_inv.stk_info_id
      FROM   xxcos_edi_inventory  edi_inv
      WHERE  NVL(edi_inv.center_delivery_date, 
             NVL(edi_inv.order_date, TRUNC(edi_inv.data_creation_date_edi_data))) 
          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
      FOR UPDATE NOWAIT;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- テーブルロック(EDI在庫情報ＴＢＬカーソル)
    --==============================================================
    OPEN  edi_inventory_lock_cur;
    CLOSE edi_inventory_lock_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロックエラー 
    WHEN lock_expt THEN
      gv_tkn_edi_inventory :=  xxccp_common_pkg.get_msg(
                              iv_application        =>  cv_application,
                              iv_name               =>  cv_msg_edi_inventory
                              );
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_lock,
                          iv_token_name1        =>  cv_tkn_table_name,
                          iv_token_name2        =>  gv_tkn_edi_inventory
                 );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( edi_inventory_lock_cur%ISOPEN ) THEN
        CLOSE edi_inventory_lock_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inventory_lock;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_delete
   * Description      : EDI在庫情報テーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_delete(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_delete'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    BEGIN
      --==============================================================
      -- テーブルロック(EDI在庫情報ＴＢＬ)
      --==============================================================
      xxcos_in_edi_inventory_lock(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      --EDI在庫情報ＴＢＬ削除
      DELETE   FROM   xxcos_edi_inventory  edi_inv
        WHERE  NVL(edi_inv.center_delivery_date, 
               NVL(edi_inv.order_date, TRUNC(edi_inv.data_creation_date_edi_data))) 
            < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_inventory :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  cv_msg_edi_inventory
                             );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_delete_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inventory,
                        iv_token_value2       =>  NULL
                        );
        lv_errbuf       := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END xxcos_in_edi_inventory_delete;
--
  /**********************************************************************************
   * Procedure Name   : sel_in_edi_inventory_work
   * Description      : EDI在庫情報ワークテーブルデータ抽出 (A-2)
   *                  :  SQL-LOADERによってEDI在庫情報ワークテーブルに取り込まれたレコードを
   *                     抽出します。同時にレコードロックを行います。
   ***********************************************************************************/
  PROCEDURE sel_in_edi_inventory_work(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sel_in_edi_inventory_work'; -- プログラム名
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
    lv_cur_param1 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ１
    lv_cur_param2 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ２
    lv_cur_param3 VARCHAR2(100) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ３
    lv_cur_param4 VARCHAR2(255) DEFAULT NULL;    -- 抽出カーソル用引渡しパラメタ４
    ln_no         NUMBER        DEFAULT 0;       -- ループカウンター
--
    -- *** ローカル・カーソル ***
  --* -------------------------------------------------------------------------------------------
  -- EDI在庫情報ワークテーブルデータ抽出
    CURSOR get_ediinv_work_data_cur( lv_cur_param1 CHAR, lv_cur_param2 CHAR, lv_cur_param3 CHAR )
    IS
    SELECT  
      ediinvwk.stk_info_work_id               stk_info_work_id,              -- 在庫情報ﾜｰｸid
      ediinvwk.medium_class                   medium_class,                  -- 媒体区分
      ediinvwk.data_type_code                 data_type_code,                -- ﾃﾞｰﾀ種ｺｰﾄﾞ
      ediinvwk.file_no                        file_no,                       -- ﾌｧｲﾙno
      ediinvwk.info_class                     info_class,                    -- 情報区分
      ediinvwk.process_date                   process_date,                  -- 処理日
      ediinvwk.process_time                   process_time,                  -- 処理時刻
      ediinvwk.base_code                      base_code,                     -- 拠点(部門)ｺｰﾄﾞ
      ediinvwk.base_name                      base_name,                     -- 拠点名(正式名)
      ediinvwk.base_name_alt                  base_name_alt,                 -- 拠点名(ｶﾅ)
      ediinvwk.edi_chain_code                 edi_chain_code,                -- ediﾁｪｰﾝ店ｺｰﾄﾞ
      ediinvwk.edi_chain_name                 edi_chain_name,                -- ediﾁｪｰﾝ店名(漢字)
      ediinvwk.edi_chain_name_alt             edi_chain_name_alt,            -- ediﾁｪｰﾝ店名(ｶﾅ)
      ediinvwk.report_code                    report_code,                   -- 帳票ｺｰﾄﾞ
      ediinvwk.report_show_name               report_show_name,              -- 帳票表示名
      ediinvwk.customer_code                  customer_code,                 -- 顧客ｺｰﾄﾞ
      ediinvwk.customer_name                  customer_name,                 -- 顧客名(漢字)
      ediinvwk.customer_name_alt              customer_name_alt,             -- 顧客名(ｶﾅ)
      ediinvwk.company_code                   company_code,                  -- 社ｺｰﾄﾞ
      ediinvwk.company_name_alt               company_name_alt,              -- 社名(ｶﾅ)
      ediinvwk.shop_code                      shop_code,                     -- 店ｺｰﾄﾞ
      ediinvwk.shop_name_alt                  shop_name_alt,                 -- 店名(ｶﾅ)
      ediinvwk.delivery_center_code           delivery_center_code,          -- 納入ｾﾝﾀｰｺｰﾄﾞ
      ediinvwk.delivery_center_name           delivery_center_name,          -- 納入ｾﾝﾀｰ名(漢字)
      ediinvwk.delivery_center_name_alt       delivery_center_name_alt,      -- 納入ｾﾝﾀｰ名(ｶﾅ)
      ediinvwk.whse_code                      whse_code,                     -- 倉庫ｺｰﾄﾞ
      ediinvwk.whse_name                      whse_name,                     -- 倉庫名
      ediinvwk.inspect_charge_name            inspect_charge_name,           -- 検品担当者名(漢字)
      ediinvwk.inspect_charge_name_alt        inspect_charge_name_alt,       -- 検品担当者名(ｶﾅ)
      ediinvwk.return_charge_name             return_charge_name,            -- 返品担当者名(漢字)
      ediinvwk.return_charge_name_alt         return_charge_name_alt,        -- 返品担当者名(ｶﾅ)
      ediinvwk.receive_charge_name            receive_charge_name,           -- 受領担当者名(漢字)
      ediinvwk.receive_charge_name_alt        receive_charge_name_alt,       -- 受領担当者名(ｶﾅ)
      ediinvwk.order_date                     order_date,                    -- 発注日
      ediinvwk.center_delivery_date           center_delivery_date,          -- ｾﾝﾀｰ納品日
      ediinvwk.center_result_delivery_date    center_result_delivery_date,   -- ｾﾝﾀｰ実納品日
      ediinvwk.center_shipping_date           center_shipping_date,          -- ｾﾝﾀｰ出庫日
      ediinvwk.center_result_shipping_date    center_result_shipping_date,   -- ｾﾝﾀｰ実出庫日
      ediinvwk.data_creation_date_edi_data    data_creation_date_edi_data,   -- ﾃﾞｰﾀ作成日(ediﾃﾞｰﾀ中)
      ediinvwk.data_creation_time_edi_data    data_creation_time_edi_data,   -- ﾃﾞｰﾀ作成時刻(ediﾃﾞｰﾀ中)
      ediinvwk.stk_date                       stk_date,                      -- 在庫日付
      ediinvwk.offer_vendor_code_class        offer_vendor_code_class,       -- 提供企業取引先ｺｰﾄﾞ区分
      ediinvwk.whse_vendor_code_class         whse_vendor_code_class,        -- 倉庫取引先ｺｰﾄﾞ区分
      ediinvwk.offer_cycle_class              offer_cycle_class,             -- 提供ｻｲｸﾙ区分
      ediinvwk.stk_type                       stk_type,                      -- 在庫種類
      ediinvwk.japanese_class                 japanese_class,                -- 日本語区分
      ediinvwk.whse_class                     whse_class,                    -- 倉庫区分
      ediinvwk.vendor_code                    vendor_code,                   -- 取引先ｺｰﾄﾞ
      ediinvwk.vendor_name                    vendor_name,                   -- 取引先名(漢字)
      ediinvwk.vendor_name_alt                vendor_name_alt,               -- 取引先名(ｶﾅ)
      ediinvwk.check_digit_class              check_digit_class,             -- ﾁｪｯｸﾃﾞｼﾞｯﾄ有無区分
      ediinvwk.invoice_number                 invoice_number,                -- 伝票番号
      ediinvwk.check_digit                    check_digit,                   -- ﾁｪｯｸﾃﾞｼﾞｯﾄ
      ediinvwk.chain_peculiar_area_header     chain_peculiar_area_header,    -- ﾁｪｰﾝ店固有ｴﾘｱ(ﾍｯﾀﾞ)
      ediinvwk.product_code_itouen            product_code_itouen,           -- 商品ｺｰﾄﾞ(伊藤園)
      ediinvwk.product_code_other_party       product_code_other_party,      -- 商品ｺｰﾄﾞ(先方)
      ediinvwk.jan_code                       jan_code,                      -- janｺｰﾄﾞ
      ediinvwk.itf_code                       itf_code,                      -- itfｺｰﾄﾞ
      ediinvwk.product_name                   product_name,                  -- 商品名(漢字)
      ediinvwk.product_name_alt               product_name_alt,              -- 商品名(ｶﾅ)
      ediinvwk.prod_class                     prod_class,                    -- 商品区分
      ediinvwk.active_quality_class           active_quality_class,          -- 適用品質区分
      ediinvwk.qty_in_case                    qty_in_case,                   -- 入数
      ediinvwk.uom_code                       uom_code,                      -- 単位
      ediinvwk.day_average_shipping_qty       day_average_shipping_qty,      -- 一日平均出荷数量
      ediinvwk.stk_type_code                  stk_type_code,                 -- 在庫種別ｺｰﾄﾞ
      ediinvwk.last_arrival_date              last_arrival_date,             -- 最終入荷日
      ediinvwk.use_by_date                    use_by_date,                   -- 賞味期限
      ediinvwk.product_date                   product_date,                  -- 製造日
      ediinvwk.upper_limit_stk_case           upper_limit_stk_case,          -- 上限在庫(ｹｰｽ)
      ediinvwk.upper_limit_stk_indv           upper_limit_stk_indv,          -- 上限在庫(バラ)
      ediinvwk.indv_order_point               indv_order_point,              -- 発注点(バラ)
      ediinvwk.case_order_point               case_order_point,              -- 発注点(ｹｰｽ)
      ediinvwk.indv_prev_month_stk_qty        indv_prev_month_stk_qty,       -- 前月末在庫数量(バラ)
      ediinvwk.case_prev_month_stk_qty        case_prev_month_stk_qty,       -- 前月末在庫数量(ｹｰｽ)
      ediinvwk.sum_prev_month_stk_qty         sum_prev_month_stk_qty,        -- 前月在庫数量(合計)
      ediinvwk.day_indv_order_qty             day_indv_order_qty,            -- 発注数量(当日,バラ)
      ediinvwk.day_case_order_qty             day_case_order_qty,            -- 発注数量(当日,ｹｰｽ)
      ediinvwk.day_sum_order_qty              day_sum_order_qty,             -- 発注数量(当日,合計)
      ediinvwk.month_indv_order_qty           month_indv_order_qty,          -- 発注数量(当月,バラ)
      ediinvwk.month_case_order_qty           month_case_order_qty,          -- 発注数量(当月,ｹｰｽ)
      ediinvwk.month_sum_order_qty            month_sum_order_qty,           -- 発注数量(当月,合計)
      ediinvwk.day_indv_arrival_qty           day_indv_arrival_qty,          -- 入庫数量(当日,バラ)
      ediinvwk.day_case_arrival_qty           day_case_arrival_qty,          -- 入庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_arrival_qty            day_sum_arrival_qty,           -- 入庫数量(当日,合計)
      ediinvwk.month_arrival_count            month_arrival_count,           -- 当月入荷回数
      ediinvwk.month_indv_arrival_qty         month_indv_arrival_qty,        -- 入庫数量(当月,バラ)
      ediinvwk.month_case_arrival_qty         month_case_arrival_qty,        -- 入庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_arrival_qty          month_sum_arrival_qty,         -- 入庫数量(当月,合計)
      ediinvwk.day_indv_shipping_qty          day_indv_shipping_qty,         -- 出庫数量(当日,バラ)
      ediinvwk.day_case_shipping_qty          day_case_shipping_qty,         -- 出庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_shipping_qty           day_sum_shipping_qty,          -- 出庫数量(当日,合計)
      ediinvwk.month_indv_shipping_qty        month_indv_shipping_qty,       -- 出庫数量(当月,バラ)
      ediinvwk.month_case_shipping_qty        month_case_shipping_qty,       -- 出庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_shipping_qty         month_sum_shipping_qty,        -- 出庫数量(当月,合計)
      ediinvwk.day_indv_destroy_loss_qty      day_indv_destroy_loss_qty,     -- 破棄,ﾛｽ数量(当日,バラ)
      ediinvwk.day_case_destroy_loss_qty      day_case_destroy_loss_qty,     -- 破棄,ﾛｽ数量(当日,ｹｰｽ)
      ediinvwk.day_sum_destroy_loss_qty       day_sum_destroy_loss_qty,      -- 破棄,ﾛｽ数量(当日,合計)
      ediinvwk.month_indv_destroy_loss_qty    month_indv_destroy_loss_qty,   -- 破棄,ﾛｽ数量(当月,バラ)
      ediinvwk.month_case_destroy_loss_qty    month_case_destroy_loss_qty,   -- 破棄,ﾛｽ数量(当月,ｹｰｽ)
      ediinvwk.month_sum_destroy_loss_qty     month_sum_destroy_loss_qty,    -- 破棄,ﾛｽ数量(当月,合計)
      ediinvwk.day_indv_defect_stk_qty        day_indv_defect_stk_qty,       -- 不良在庫数量(当日,バラ)
      ediinvwk.day_case_defect_stk_qty        day_case_defect_stk_qty,       -- 不良在庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_defect_stk_qty         day_sum_defect_stk_qty,        -- 不良在庫数量(当日,合計)
      ediinvwk.month_indv_defect_stk_qty      month_indv_defect_stk_qty,     -- 不良在庫数量(当月,バラ)
      ediinvwk.month_case_defect_stk_qty      month_case_defect_stk_qty,     -- 不良在庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_defect_stk_qty       month_sum_defect_stk_qty,      -- 不良在庫数量(当月,合計)
      ediinvwk.day_indv_defect_return_qty     day_indv_defect_return_qty,    -- 不良返品数量(当日,バラ)
      ediinvwk.day_case_defect_return_qty     day_case_defect_return_qty,    -- 不良返品数量(当日,ｹｰｽ)
      ediinvwk.day_sum_defect_return_qty      day_sum_defect_return_qty,     -- 不良返品数量(当日,合計)
      ediinvwk.month_indv_defect_return_qty   month_indv_defect_return_qty,  -- 不良返品数量(当月,バラ)
      ediinvwk.month_case_defect_return_qty   month_case_defect_return_qty,  -- 不良返品数量(当月,ｹｰｽ)
      ediinvwk.month_sum_defect_return_qty    month_sum_defect_return_qty,   -- 不良返品数量(当月,合計)
      ediinvwk.day_indv_defect_return_rcpt    day_indv_defect_return_rcpt,   -- 不良返品受入(当日,バラ)
      ediinvwk.day_case_defect_return_rcpt    day_case_defect_return_rcpt,   -- 不良返品受入(当日,ｹｰｽ)
      ediinvwk.day_sum_defect_return_rcpt     day_sum_defect_return_rcpt,    -- 不良返品受入(当日,合計)
      ediinvwk.month_indv_defect_return_rcpt  month_indv_defect_return_rcpt, -- 不良返品受入(当月,バラ)
      ediinvwk.month_case_defect_return_rcpt  month_case_defect_return_rcpt, -- 不良返品受入(当月,ｹｰｽ)
      ediinvwk.month_sum_defect_return_rcpt   month_sum_defect_return_rcpt,  -- 不良返品受入(当月,合計)
      ediinvwk.day_indv_defect_return_send    day_indv_defect_return_send,   -- 不良返品発送(当日,バラ)
      ediinvwk.day_case_defect_return_send    day_case_defect_return_send,   -- 不良返品発送(当日,ｹｰｽ)
      ediinvwk.day_sum_defect_return_send     day_sum_defect_return_send,    -- 不良返品発送(当日,合計)
      ediinvwk.month_indv_defect_return_send  month_indv_defect_return_send, -- 不良返品発送(当月,バラ)
      ediinvwk.month_case_defect_return_send  month_case_defect_return_send, -- 不良返品発送(当月,ｹｰｽ)
      ediinvwk.month_sum_defect_return_send   month_sum_defect_return_send,  -- 不良返品発送(当月,合計)
      ediinvwk.day_indv_quality_return_rcpt   day_indv_quality_return_rcpt,  -- 良品返品受入(当日,バラ)
      ediinvwk.day_case_quality_return_rcpt   day_case_quality_return_rcpt,  -- 良品返品受入(当日,ｹｰｽ)
      ediinvwk.day_sum_quality_return_rcpt    day_sum_quality_return_rcpt,   -- 良品返品受入(当日,合計)
      ediinvwk.month_indv_quality_return_rcpt month_indv_quality_return_rcpt, -- 良品返品受入(当月,バラ)
      ediinvwk.month_case_quality_return_rcpt month_case_quality_return_rcpt, -- 良品返品受入(当月,ｹｰｽ)
      ediinvwk.month_sum_quality_return_rcpt  month_sum_quality_return_rcpt,  -- 良品返品受入(当月,合計)
      ediinvwk.day_indv_quality_return_send   day_indv_quality_return_send,   -- 良品返品発送(当日,バラ)
      ediinvwk.day_case_quality_return_send   day_case_quality_return_send,   -- 良品返品発送(当日,ｹｰｽ)
      ediinvwk.day_sum_quality_return_send    day_sum_quality_return_send,    -- 良品返品発送(当日,合計)
      ediinvwk.month_indv_quality_return_send month_indv_quality_return_send, -- 良品返品発送(当月,バラ)
      ediinvwk.month_case_quality_return_send month_case_quality_return_send, -- 良品返品発送(当月,ｹｰｽ)
      ediinvwk.month_sum_quality_return_send  month_sum_quality_return_send,  -- 良品返品発送(当月,合計)
      ediinvwk.day_indv_invent_difference     day_indv_invent_difference,     -- 棚卸差異(当日,バラ)
      ediinvwk.day_case_invent_difference     day_case_invent_difference,     -- 棚卸差異(当日,ｹｰｽ)
      ediinvwk.day_sum_invent_difference      day_sum_invent_difference,      -- 棚卸差異(当日,合計)
      ediinvwk.month_indv_invent_difference   month_indv_invent_difference,   -- 棚卸差異(当月,バラ)
      ediinvwk.month_case_invent_difference   month_case_invent_difference,   -- 棚卸差異(当月,ｹｰｽ)
      ediinvwk.month_sum_invent_difference    month_sum_invent_difference,    -- 棚卸差異(当月,合計)
      ediinvwk.day_indv_stk_qty               day_indv_stk_qty,               -- 在庫数量(当日,バラ)
      ediinvwk.day_case_stk_qty               day_case_stk_qty,               -- 在庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_stk_qty                day_sum_stk_qty,                -- 在庫数量(当日,合計)
      ediinvwk.month_indv_stk_qty             month_indv_stk_qty,             -- 在庫数量(当月,バラ)
      ediinvwk.month_case_stk_qty             month_case_stk_qty,             -- 在庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_stk_qty              month_sum_stk_qty,              -- 在庫数量(当月,合計)
      ediinvwk.day_indv_reserved_stk_qty      day_indv_reserved_stk_qty,      -- 保留在庫数(当日,バラ)
      ediinvwk.day_case_reserved_stk_qty      day_case_reserved_stk_qty,      -- 保留在庫数(当日,ｹｰｽ)
      ediinvwk.day_sum_reserved_stk_qty       day_sum_reserved_stk_qty,       -- 保留在庫数(当日,合計)
      ediinvwk.month_indv_reserved_stk_qty    month_indv_reserved_stk_qty,    -- 保留在庫数(当月,バラ)
      ediinvwk.month_case_reserved_stk_qty    month_case_reserved_stk_qty,    -- 保留在庫数(当月,ｹｰｽ)
      ediinvwk.month_sum_reserved_stk_qty     month_sum_reserved_stk_qty,     -- 保留在庫数(当月,合計)
      ediinvwk.day_indv_cd_stk_qty            day_indv_cd_stk_qty,            -- 商流在庫数量(当日,バラ)
      ediinvwk.day_case_cd_stk_qty            day_case_cd_stk_qty,            -- 商流在庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_cd_stk_qty             day_sum_cd_stk_qty,             -- 商流在庫数量(当日,合計)
      ediinvwk.month_indv_cd_stk_qty          month_indv_cd_stk_qty,          -- 商流在庫数量(当月,バラ)
      ediinvwk.month_case_cd_stk_qty          month_case_cd_stk_qty,          -- 商流在庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_cd_stk_qty           month_sum_cd_stk_qty,           -- 商流在庫数量(当月,合計)
      ediinvwk.day_indv_cargo_stk_qty         day_indv_cargo_stk_qty,         -- 積送在庫数量(当日,バラ)
      ediinvwk.day_case_cargo_stk_qty         day_case_cargo_stk_qty,         -- 積送在庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_cargo_stk_qty          day_sum_cargo_stk_qty,          -- 積送在庫数量(当日,合計)
      ediinvwk.month_indv_cargo_stk_qty       month_indv_cargo_stk_qty,       -- 積送在庫数量(当月,バラ)
      ediinvwk.month_case_cargo_stk_qty       month_case_cargo_stk_qty,       -- 積送在庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_cargo_stk_qty        month_sum_cargo_stk_qty,        -- 積送在庫数量(当月,合計)
      ediinvwk.day_indv_adjustment_stk_qty    day_indv_adjustment_stk_qty,    -- 調整在庫数量(当日,バラ)
      ediinvwk.day_case_adjustment_stk_qty    day_case_adjustment_stk_qty,    -- 調整在庫数量(当日,ｹｰｽ)
      ediinvwk.day_sum_adjustment_stk_qty     day_sum_adjustment_stk_qty,     -- 調整在庫数量(当日,合計)
      ediinvwk.month_indv_adjustment_stk_qty  month_indv_adjustment_stk_qty,  -- 調整在庫数量(当月,バラ)
      ediinvwk.month_case_adjustment_stk_qty  month_case_adjustment_stk_qty,  -- 調整在庫数量(当月,ｹｰｽ)
      ediinvwk.month_sum_adjustment_stk_qty   month_sum_adjustment_stk_qty,   -- 調整在庫数量(当月,合計)
      ediinvwk.day_indv_still_shipping_qty    day_indv_still_shipping_qty,    -- 未出荷数量(当日,バラ)
      ediinvwk.day_case_still_shipping_qty    day_case_still_shipping_qty,    -- 未出荷数量(当日,ｹｰｽ)
      ediinvwk.day_sum_still_shipping_qty     day_sum_still_shipping_qty,     -- 未出荷数量(当日,合計)
      ediinvwk.month_indv_still_shipping_qty  month_indv_still_shipping_qty,  -- 未出荷数量(当月,バラ)
      ediinvwk.month_case_still_shipping_qty  month_case_still_shipping_qty,  -- 未出荷数量(当月,ｹｰｽ)
      ediinvwk.month_sum_still_shipping_qty   month_sum_still_shipping_qty,   -- 未出荷数量(当月,合計)
      ediinvwk.indv_all_stk_qty               indv_all_stk_qty,               -- 総在庫数量(バラ)
      ediinvwk.case_all_stk_qty               case_all_stk_qty,               -- 総在庫数量(ｹｰｽ)
      ediinvwk.sum_all_stk_qty                sum_all_stk_qty,                -- 総在庫数量(合計)
      ediinvwk.month_draw_count               month_draw_count,               -- 当月引当回数
      ediinvwk.day_indv_draw_possible_qty     day_indv_draw_possible_qty,     -- 引当可能数量(当日,バラ)
      ediinvwk.day_case_draw_possible_qty     day_case_draw_possible_qty,     -- 引当可能数量(当日,ｹｰｽ)
      ediinvwk.day_sum_draw_possible_qty      day_sum_draw_possible_qty,      -- 引当可能数量(当日,合計)
      ediinvwk.month_indv_draw_possible_qty   month_indv_draw_possible_qty,   -- 引当可能数量(当月,バラ)
      ediinvwk.month_case_draw_possible_qty   month_case_draw_possible_qty,   -- 引当可能数量(当月,ｹｰｽ)
      ediinvwk.month_sum_draw_possible_qty    month_sum_draw_possible_qty,    -- 引当可能数量(当月,合計)
      ediinvwk.day_indv_draw_impossible_qty   day_indv_draw_impossible_qty,   -- 引当不能数(当日,バラ)
      ediinvwk.day_case_draw_impossible_qty   day_case_draw_impossible_qty,   -- 引当不能数(当日,ｹｰｽ)
      ediinvwk.day_sum_draw_impossible_qty    day_sum_draw_impossible_qty,    -- 引当不能数(当日,合計)
      ediinvwk.day_stk_amt                    day_stk_amt,                    -- 在庫金額(当日)
      ediinvwk.month_stk_amt                  month_stk_amt,                  -- 在庫金額(当月)
      ediinvwk.remarks                        remarks,                        -- 備考
      ediinvwk.chain_peculiar_area_line       chain_peculiar_area_line,       -- ﾁｪｰﾝ店固有ｴﾘｱ(明細)
      ediinvwk.invoice_day_indv_sum_stk_qty   invoice_day_indv_sum_stk_qty,   -- 伝票計)在庫数量合計(当日,バラ)
      ediinvwk.invoice_day_case_sum_stk_qty   invoice_day_case_sum_stk_qty,   -- 伝票計)在庫数量合計(当日,ｹｰｽ)
      ediinvwk.invoice_day_sum_sum_stk_qty    invoice_day_sum_sum_stk_qty,    -- 伝票計)在庫数量合計(当日,合計)
      ediinvwk.invoice_month_indv_sum_stk_qty invoice_month_indv_sum_stk_qty, -- 伝票計)在庫数量合計(当月,バラ)
      ediinvwk.invoice_month_case_sum_stk_qty invoice_month_case_sum_stk_qty, -- 伝票計)在庫数量合計(当月,ｹｰｽ)
      ediinvwk.invoice_month_sum_sum_stk_qty  invoice_month_sum_sum_stk_qty,  -- 伝票計)在庫数量合計(当月,合計)
      ediinvwk.invoice_day_indv_cd_stk_qty    invoice_day_indv_cd_stk_qty,    -- 伝票計)商流在庫数量(当日,バラ)
      ediinvwk.invoice_day_case_cd_stk_qty    invoice_day_case_cd_stk_qty,    -- 伝票計)商流在庫数量(当日,ｹｰｽ)
      ediinvwk.invoice_day_sum_cd_stk_qty     invoice_day_sum_cd_stk_qty,     -- 伝票計)商流在庫数量(当日,合計)
      ediinvwk.invoice_month_indv_cd_stk_qty  invoice_month_indv_cd_stk_qty,  -- 伝票計)商流在庫数量(当月,バラ)
      ediinvwk.invoice_month_case_cd_stk_qty  invoice_month_case_cd_stk_qty,  -- 伝票計)商流在庫数量(当月,ｹｰｽ)
      ediinvwk.invoice_month_sum_cd_stk_qty   invoice_month_sum_cd_stk_qty,   -- 伝票計)商流在庫数量(当月,合計)
      ediinvwk.invoice_day_stk_amt            invoice_day_stk_amt,            -- 伝票計)在庫金額(当日)
      ediinvwk.invoice_month_stk_amt          invoice_month_stk_amt,          -- 伝票計)在庫金額(当月)
      ediinvwk.regular_sell_amt_sum           regular_sell_amt_sum,           -- 正販金額合計
      ediinvwk.rebate_amt_sum                 rebate_amt_sum,                 -- 割戻し金額合計
      ediinvwk.collect_bottle_amt_sum         collect_bottle_amt_sum,         -- 回収容器金額合計
      ediinvwk.chain_peculiar_area_footer     chain_peculiar_area_footer,     -- ﾁｪｰﾝ店固有ｴﾘｱ(ﾌｯﾀ)
      ediinvwk.err_status                     err_status,                     -- ｽﾃｰﾀｽ
/* 2011/07/28 Ver1.8 Mod Start */
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakanao Add Start
--      ediinvwk.creation_date                  creation_date                   -- 作成日
---- Ver1.7  [E_本稼動_01695]  2010/03/04 T.Nakanao Add End
      ediinvwk.creation_date                  creation_date,                  -- 作成日
/* 2011/07/28 Ver1.8 Mod Start */
/* 2011/07/28 Ver1.8 Add Start */
      ediinvwk.bms_header_data                bms_header_data,                -- 流通ＢＭＳヘッダデータ
      ediinvwk.bms_line_data                  bms_line_data                   -- 流通ＢＭＳ明細データ
/* 2011/07/28 Ver1.8 Add End   */
    FROM    xxcos_edi_inventory_work    ediinvwk                            -- EDI在庫情報ワークテーブル
    WHERE   ediinvwk.if_file_name       =    lv_cur_param3                  -- インタフェースファイル名
      AND   ediinvwk.err_status         =    lv_cur_param1                  -- ステータス
      AND (( lv_cur_param2 IS NOT NULL
        AND   ediinvwk.edi_chain_code   =    lv_cur_param2 )              -- EDIチェーン店コード
        OR ( lv_cur_param2 IS NULL ))
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Add start
    ORDER BY ediinvwk.shop_code,                                          -- 店コード
-- Ver1.5  [T1_0022,T1_0023,T1_0024,T1_0042,T1_0201]  2009/06/26 N.Nishimura Add End
             ediinvwk.invoice_number                                      -- ソート条件（伝票番号）
    FOR UPDATE OF
            ediinvwk.stk_info_work_id NOWAIT;
    -- *** ローカル・レコード ***
--
  --* -------------------------------------------------------------------------------------------
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --==============================================================
    -- 実行区分のチェック
    --==============================================================
    -- 
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- 実行区分：「新規」
      lv_cur_param1 := gv_run_class_name1;       -- 抽出カーソル用引渡しパラメタ１
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN   -- 実行区分：「再実施」
      lv_cur_param1 := gv_run_class_name2;       -- 抽出カーソル用引渡しパラメタ１
    END IF;
    --
    lv_cur_param2 := iv_edi_chain_code;          -- 抽出カーソル用引渡しパラメタ３
    lv_cur_param3 := iv_file_name;               -- 抽出カーソル用引渡しパラメタ４
--
    --==============================================================
    -- EDI在庫情報ワークテーブルデータ取得
    --==============================================================
    BEGIN
      -- カーソルOPEN
      OPEN  get_ediinv_work_data_cur( lv_cur_param1, lv_cur_param2, lv_cur_param3 );
      --
      -- バルクフェッチ
      FETCH get_ediinv_work_data_cur BULK COLLECT INTO gt_ediinv_work_data;
      -- 抽出件数セット
      gn_target_cnt := get_ediinv_work_data_cur%ROWCOUNT;
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
--      -- 正常件数 = 抽出件数
--      gn_normal_cnt := gn_target_cnt;
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
      --
      -- カーソルCLOSE
      CLOSE get_ediinv_work_data_cur;
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        IF ( get_ediinv_work_data_cur%ISOPEN ) THEN
          CLOSE get_ediinv_work_data_cur;
        END IF;
        -- EDI在庫情報ワークテーブル
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg           :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  gv_msg_lock,
                            iv_token_name1        =>  cv_tkn_table_name,
                            iv_token_value1       =>  gv_tkn_edi_inv_work
                            );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
      -- その他の抽出エラー
      WHEN OTHERS THEN
        IF ( get_ediinv_work_data_cur%ISOPEN ) THEN
          CLOSE get_ediinv_work_data_cur;
        END IF;
        lv_errbuf  := SQLERRM;
        RAISE global_data_sel_expt;
    END;
    --
    -- 対象データ無し
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_nodata_expt;
    END IF;
    --
    -- ループ開始：
    <<xxcos_in_edi_iinv_set>>
    FOR ln_no IN 1..gn_target_cnt LOOP
      --* -------------------------------------------------------------------------------------------
      --==============================================================
      -- * Procedure Name   : data_check
      -- * Description      : データ妥当性チェック(A-3)
      --==============================================================
      data_check(
        ln_no,
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --
    END LOOP  xxcos_in_edi_iinv_set;
--
    -- 後続処理が不可能なエラーがあった場合
    IF ( gv_err_ediinv_work_flag IS NOT NULL ) THEN
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_inv_wk_update
      -- * Description      : EDI在庫情報ワークテーブルへの更新(A-7)
      -- ***********************************************************************************
      xxcos_in_edi_inv_wk_update(
        iv_file_name,     --   インタフェースファイル名
        iv_edi_chain_code,  -- EDIチェーン店コード
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --
    ELSE
    --* -------------------------------------------------------------------------------------------
    --  顧客情報チェックでエラーが無かった場合。
    --* -------------------------------------------------------------------------------------------
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_inventory_insert
      -- * Description      : EDI在庫情報テーブルへのデータ挿入(A-6)
      -- ***********************************************************************************
      xxcos_in_edi_inventory_insert(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- 対象データなし
    WHEN global_nodata_expt THEN
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_nodata_err
                           );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --正常終了とする
      ov_retcode := cv_status_normal;
    -- データ抽出エラー
    WHEN global_data_sel_expt THEN
      -- EDI在庫情報ワークテーブル
      gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  cv_msg_edi_inv_work
                          );
      lv_errmsg           :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_nodata,
                          iv_token_name1        =>  cv_tkn_table_name1,
                          iv_token_value1       =>  gv_tkn_edi_inv_work,
                          iv_token_name2        =>  cv_tkn_key_data,
                          iv_token_value2       =>  iv_file_name
                          );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#####################################  固定部 END   ##########################################
--
  END sel_in_edi_inventory_work;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「新規」「再実行」
    iv_edi_chain_code IN VARCHAR2,     --   EDIチェーン店コード
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_in_if_file    VARCHAR2(5000);
    lv_in_param      VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
    -- <カーソル名>レコード型
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
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
    gn_msg_cnt    := 0;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    --==============================================================
    -- プログラム初期処理(A-0) (コンカレントプログラム入力項目を出力)
    --==============================================================
    -- インタフェースファイル名（パラメタ出力）
    lv_in_if_file :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  cv_msg_in_file_name1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_file_name
                   );
    --==============================================================
    --==============================================================
    -- 入力パラメータ「 インタフェースファイル名」出力
    --==============================================================
    FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_if_file
    );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_if_file
      );
    --==============================================================
    --==============================================================
    -- プログラム初期処理(A-0) (コンカレントプログラム入力項目を出力)
    --==============================================================
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- 実行区分：「新規」
    ----  IF  ( iv_edi_chain_code  IS NULL ) THEN
        lv_in_param :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_param_out_msg1,
                       iv_token_name1        =>  cv_param1,
                       iv_token_value1       =>  iv_run_class
                       );
    --==============================================================
    --= 実行区分が【新規」の場合、ﾁｪｰﾝ店ｺｰﾄﾞ指定なしのためﾊﾟﾗﾒﾀ表示なし。
    --==============================================================
    ----   ELSE
    ----    lv_errmsg      :=  xxccp_common_pkg.get_msg(
    ----                   iv_application        =>  cv_application,
    ----                   iv_name               =>  gv_msg_param_out_msg2,
    ----                   iv_token_name1        =>  cv_param1,
    ----                   iv_token_name2        =>  cv_param2,
    ----                   iv_token_value1       =>  iv_run_class,
    ----                   iv_token_value2       =>  iv_edi_chain_code
    ----                   );
    ----   END IF;
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
      );
      --==============================================================
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN    -- 実行区分：「再実施」
      lv_in_param :=  xxccp_common_pkg.get_msg(
                     iv_application        =>  cv_application,
                     iv_name               =>  gv_msg_param_out_msg2,
                     iv_token_name1        =>  cv_param1,
                     iv_token_name2        =>  cv_param2,
                     iv_token_value1       =>  iv_run_class,
                     iv_token_value2       =>  iv_edi_chain_code
                     );
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
      );
      --==============================================================
    ELSE              -- 実行区分：「新規」「再実施」 以外
      lv_in_param :=  xxccp_common_pkg.get_msg(
                     iv_application        =>  cv_application,
                     iv_name               =>  gv_msg_param_out_msg2,
                     iv_token_name1        =>  cv_param1,
                     iv_token_name2        =>  cv_param2,
                     iv_token_value1       =>  iv_run_class,
                     iv_token_value2       =>  iv_edi_chain_code
                     );
      --==============================================================
      -- 入力パラメータ「実行区分」「EDIチェーン店コード」出力
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
      );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
    --
    --==============================================================
    -- * Procedure Name   : init
    -- * Description      : 初期処理(A-1)
    -- *                  :  入力パラメータ妥当性チェック
    --==============================================================
    init(
      iv_file_name,       --   インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : sel_in_edi_inventory_work(A-2)
    -- * Description      : EDI在庫情報ワークテーブルデータ抽出 (A-2)
    -- *                  :  SQL-LOADERによってEDI在庫情報ワークテーブルに取り込まれたレコードを
    -- *                     抽出します。同時にレコードロックを行います。
    --==============================================================
    sel_in_edi_inventory_work(
      iv_file_name,       --   インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ステータスがエラーとなるデータがない場合
    --==============================================================
    IF ( gv_err_ediinv_work_flag IS NULL ) THEN
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_inv_work_delete
      -- * Description      : EDI在庫情報ワークテーブルデータ削除(A-9)
      --==============================================================
      xxcos_in_edi_inv_work_delete(
        iv_file_name,       --   インタフェースファイル名
        iv_run_class,       -- 実行区分：「新規」「再実行」
        iv_edi_chain_code,  -- EDIチェーン店コード
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_inventory_delete
      -- * Description      : EDI在庫情報テーブルデータ削除(A-8)
      --==============================================================
      xxcos_in_edi_inventory_delete(
        lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        lv_retcode,      -- リターン・コード             --# 固定 #
        lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- コンカレントステータス、件数の設定
    --==============================================================
--****************************** 2009/05/28 1.3 T.Kitajima MOD START ******************************--
--    IF ( gv_err_ediinv_work_flag IS NOT NULL ) THEN
--      ov_retcode    :=  cv_status_error;  --ステータス：エラー
--      gn_normal_cnt :=  0;                --正常件数：0
--      gn_warn_cnt   :=  0;                --警告件数：0
--    ELSIF ( gv_status_work  =  cv_status_warn ) THEN
--      ov_retcode    :=  gv_status_work;   --ステータス：警告
--    END IF;
    IF ( gv_err_ediinv_work_flag IS NOT NULL ) THEN
      ov_retcode    :=  cv_status_error;  --ステータス：エラー
    ELSIF ( gv_status_work  =  cv_status_warn ) THEN
      ov_retcode    :=  gv_status_work;   --ステータス：警告
    END IF;
--****************************** 2009/05/28 1.3 T.Kitajima MOD START ******************************--
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    errbuf        OUT    VARCHAR2,     --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,     --   エラーコード     #固定#
    iv_file_name      IN VARCHAR2,     --   インタフェースファイル名
    iv_run_class      IN VARCHAR2,     --   実行区分：「0:新規」「1:再実行」
    iv_edi_chain_code IN VARCHAR2      --   EDIチェーン店コード
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- 警告件数メッセージ（商品コードエラー）
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    --==============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==============================================================
    submain(
      iv_file_name,       --   インタフェースファイル名
      iv_run_class,       -- 実行区分：「新規」「再実行」
      iv_edi_chain_code,  -- EDIチェーン店コード
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
----****************************** 2009/05/28 1.3 T.Kitajima MOD START ******************************--
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_normal_cnt :=  0;                --正常件数：0
--      gn_warn_cnt   :=  0;                --警告件数：0
--      gn_error_cnt  :=  1;                --エラー件数：1
--    ELSIF ( gv_status_work  =  cv_status_warn ) THEN
--      gn_normal_cnt :=  gn_normal_cnt - gn_warn_cnt;
--    END IF;
----****************************** 2009/05/28 1.3 T.Kitajima MOD START ******************************--
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
    --==============================================================
    --* Description      : 終了処理(A-11)
    --==============================================================
--****************************** 2009/06/03 1.4 T.Kitajima MOD START ******************************--
--    --対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name,
--                     iv_name         => cv_target_rec_msg,
--                     iv_token_name1  => cv_cnt_token,
--                     iv_token_value1 => TO_CHAR(gn_target_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT,
--       buff   => gv_out_msg
--    );
--    --
--    --成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name,
--                     iv_name         => cv_success_rec_msg,
--                     iv_token_name1  => cv_cnt_token,
--                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT,
--       buff   => gv_out_msg
--    );
--    --
--    --エラー件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name,
--                     iv_name         => cv_error_rec_msg,
--                     iv_token_name1  => cv_cnt_token,
--                     iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT,
--       buff   => gv_out_msg
--    );
--    --
--    --警告件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application,
--                     iv_name         => cv_warn_rec_msg,
--                     iv_token_name1  => cv_cnt_token,
--                     iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT,
--       buff   => gv_out_msg
--    );
--
    IF ( gn_error_cnt != 0 ) THEN
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
    ELSE
      gn_warn_cnt := 0;
    END IF;
    gv_out_msg  := xxccp_common_pkg.get_msg(
                iv_application  => cv_application,
                iv_name         => cv_msg_count,
                iv_token_name1  => cv_tkn_cnt1,
                iv_token_value1 => TO_CHAR(gn_target_cnt),
                iv_token_name2  => cv_tkn_cnt2,
                iv_token_value2 => TO_CHAR(gn_normal_cnt),
                iv_token_name3  => cv_tkn_cnt3,
                iv_token_value3 => TO_CHAR(gn_error_cnt),
                iv_token_name4  => cv_tkn_cnt4,
                iv_token_value4 => TO_CHAR(gn_warn_cnt),
                iv_token_name5  => cv_tkn_cnt5,
                iv_token_value5 => TO_CHAR(gn_msg_cnt)
                );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--****************************** 2009/06/04 1.4 T.Kitajima MOD  END  ******************************--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT,
       buff   => gv_out_msg
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
END XXCOS011A02C;
/
