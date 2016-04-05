CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A03C (body)
 * Description      : VD納品データ作成
 * MD.050           : VD納品データ作成(MD050_COS_001_A03)
 * Version          : 1.28
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_fiscal_period_from 有効会計期間FROM取得関数(A-6)
 *  proc_data_update       取得元テーブルフラグ更新(A-5)
 *  proc_data_insert_line  販売実績データ登録処理(明細)(A-4-2)
 *  proc_data_insert_head  販売実績データ登録処理(ヘッダ)(A-4-1)
 *  proc_molded            VD納品データ作成成型処理(A-3)
 *  proc_extract           対象データ抽出(A-2)
 *  proc_init              初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0     N.Maeda          新規作成
 *  2009/02/02    1.1     N.Maeda          納品伝票入力画面入力データ対応(非課税時の消費税額にNVL関数による判定追加)
 *  2009/02/03    1.2     N.Maeda          HHT百貨店入力区分の判定条件変更
 *                                         従業員ビューより拠点コード取得を行う際の条件を追加
 *  2009/02/17    1.3     N.Maeda          消費税率取得条件に有効フラグを追加
 *  2009/02/18    1.4     N.Maeda          顧客情報取得時の条件変更(｢duns_number｣⇒｢duns_number_c｣)
 *  2009/02/20    1.5     N.Maeda          パラメータのログファイル出力対応
 *  2009/03/18    1.6     T.Kitajima       [T1_0066] HHT納品データの販売実績連携時における設定項目の不備
 *                                         [T1_0078] 金額の端数計算が正しく行われていない
 *  2009/03/23    1.7     N.Maeda          [T1_0078] 金額の端数処理の修正
 *  2009/04/07    1.8     N.Maeda          [T1_0256] 保管場所取得方法の修正
 *  2009/04/09    1.9     N.Maeda          [T1_0401] 外税、内税(伝票課税)時の売上金額の計算方法修正
 *                                                   外税時の売上金額合計の計算方法修正
 *  2009/04/16    1.10    N.Maeda          [T1_0370_0447_0712] メイン処理部のエラーハンドリング修正
 *                                                             入金拠点コード取得の追加
 *                                                             データ抽出条件の変更
 *  2009/05/12    1.11    N.Maeda          [T1_0890] カード併用額対応
 *  2009/05/12    1.12    N.Maeda          [T1_0818_0819] 取消・訂正区分セット値修正
 *  2009/05/20    1.13    N.Maeda          [T1_0547] 消費税区分｢外税(2)｣時、売上金額算出方法変更
 *                                         [T1_0855] 納品伝票区分取得判定の変更
 *                                         [T1_0982] 保管場所取得エラー時のメッセージ出力項目の追加・修正
 *                                         [T1_1040] 消費税区分｢内税(単価込み)(3)｣時、本体、売上金額算出方法変更
 *                                         [T1_1041] 消費税区分｢内税(伝票課税)(2)｣時、売上金額算出方法変更
 *                                         [T1_1097] 納品日、検収日のチェック処理追加
 *                                         [T1_1121] 本体金額算出時端数処理方法の修正
 *                                         [T1_1122] 端数処理区分切上時の処理修正
 *                                         [T1_0384] 登録件数カウント処理の変更、ログ出力追加
 *                                         [T1_1269] 消費税区分｢内税(単価込み)(3)｣時、税抜き基準単価算出方法変更
 *  2009/06/01    1.14    N.Maeda          [T1_1279] ログ出力件数項目追加、件数修正
 *                                         [T1_1332] 消費税区分:外税、内税(伝票課税)の時の消費税端数処理修正
 *                                         [T1_1333] 消費税区分:内税(単価込み)の時の消費税算出方法修正
 *  2009/07/24    1.15    N.Maeda          [0000831] 顧客付帯情報取得条件変更
 *  2009/07/29            N.Maeda          [0000831] レビュー指摘対応
 *  2009/07/31            N.Maeda          [0000831] レビュー再指摘対応
 *  2009/08/12    1.16    N.Maeda          [0000900] クイックコード取得方法修正
 *                                         [0001010] 従業員ビュー取得条件追加
 *  2009/08/21    1.17    N.Maeda          [0001141] 前月売上拠点の考慮追加
 *  2009/09/03    1.18    N.Maeda          [0001211] 消費税関連項目取得基準日付の修正
 *  2009/10/30    1.19    M.Sano           [0001373] 参照View変更[xxcos_rs_info_v ⇒ xxcos_rs_info2_v]
 *  2010/02/01    1.20    M.Hokkanji       [E_T4_00195] 会計期間情報取得関数パラメータ修正[AR → INV]
 *  2010/05/10    1.21    Y.Kuboshima      [E_本稼動_02625] 営業原価の取得基準日修正[業務日付 → 納品日]
 *  2010/09/09    1.22    H.Sasaki         [E_本稼動_02635] エラー出力の追加（汎用エラーリスト）
 *  2012/02/03    1.23    K.Kiriu          [E_本稼動_08938] 訂正時の消費税額不具合対応
 *  2012/08/06    1.24    T.Makuta         [E_本稼動_09888] PT対応
 *  2012/08/27    1.25    T.Makuta         [E_本稼動_10008] PT対応
 *  2013/10/18    1.26    K.Nakamura       [E_本稼動_10904] 消費税増税対応
 *  2014/01/29    1.27    K.Nakamura       [E_本稼動_11449] 消費税率取得基準日を検収日⇒オリジナル検収日に変更
 *  2016/02/26    1.28    S.Niki           [E_本稼動_13480] 納品書チェックリスト対応
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
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  -- ロックエラー
  lock_err_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
  -- 納品形態区分エラー
  delivered_from_err_expt  EXCEPTION;
  -- 抽出対象なしエラー
  no_data_extract          EXCEPTION;
  -- 抽出エラー
  extract_err_expt         EXCEPTION;
  -- 登録エラー
  insert_err_expt          EXCEPTION;
  -- 更新エラー
  updata_err_expt          EXCEPTION;
-- == 2010/09/09 V1.22 Added START ===============================================================
  global_ins_key_expt       EXCEPTION;                        --  汎用エラーリスト登録例外（submainハンドリング用）
  global_bulk_ins_expt      EXCEPTION;                        --  汎用エラーリスト登録例外
  PRAGMA EXCEPTION_INIT(global_bulk_ins_expt, -24381);
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100):= 'XXCOS001A03C';             -- パッケージ名
  cv_application                 CONSTANT VARCHAR2(5)  := 'XXCOS';                    -- アプリケーション名
  cv_prf_orga_code               CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:在庫組織コード
  cv_prf_max_date                CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';          -- XXCOS:MAX日付
  cv_prf_bks_id                  CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';         -- GL会計帳簿ID
  cv_lookup_type                 CONSTANT VARCHAR2(100) := 'XXCOS1_CONSUMPTION_TAX_CLASS'; -- 消費税区分
  cv_cust_s                      CONSTANT VARCHAR2(2)  := '30';                       -- 顧客
  cv_cust_v                      CONSTANT VARCHAR2(2)  := '40';                       -- 上様
  cv_cost_p                      CONSTANT VARCHAR2(2)  := '50';                       -- 休止
--  cv_consum_code_out_tax         CONSTANT NUMBER  := 1;                          -- 税コード(外税)
--  cv_consum_code_no_tax          CONSTANT NUMBER  := 4;                          -- 税コード(非課税)
  cv_correct_class               CONSTANT NUMBER  := 1;                          -- 取消・訂正区分(訂正)
  cv_cancel_class                CONSTANT NUMBER  := 2;                          -- 取消・訂正区分(取消)
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--  cv_black_flag                  CONSTANT NUMBER  := 1;                          -- 赤・黒フラグ(黒)
--  cv_red_flag                    CONSTANT NUMBER  := 0;                          -- 赤・黒フラグ(赤)
  cv_black_flag                  CONSTANT VARCHAR2(1)  := '1';                   -- 赤・黒フラグ(黒)
  cv_red_flag                    CONSTANT VARCHAR2(1)  := '0';                   -- 赤・黒フラグ(赤)
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
  cv_system_class_fs_vd          CONSTANT VARCHAR2(5)  := '24';                  -- フルサービスVD
  cv_system_class_fs_vd_s        CONSTANT VARCHAR2(5)  := '25';                  -- フルサービス（消化）VD
  cv_customer_type_c             CONSTANT VARCHAR2(5)  := '10';                  -- 顧客区分(顧客)
  cv_customer_type_u             CONSTANT VARCHAR2(5)  := '12';                  -- 顧客区分(上様)
  cv_bace_branch                 CONSTANT VARCHAR2(5)  := '1';
  cv_input_class_fs_vd_at        CONSTANT VARCHAR2(5)  := '5';                   -- フルVD(自動吸上)
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--  cv_head_create_class_vd_d_c    CONSTANT NUMBER  := 3;
  cv_head_create_class_vd_d_c    CONSTANT VARCHAR2(1) := 3;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
--  cv_tax_not_odd                 CONSTANT NUMBER  := 0;                          -- 端数の発生判定用
  cv_forward_flag_no             CONSTANT VARCHAR2(1)  := 'N';                   -- 処理済フラグ(未処理)
  cv_xxcos1_input_class          CONSTANT VARCHAR2(50) := 'XXCOS1_INPUT_CLASS';
  cv_xxcos1_hokan_mst_001_a05    CONSTANT VARCHAR2(50) := 'XXCOS1_HOKAN_TYPE_MST_001_A05';
  cv_xxcos_001_a05_05            CONSTANT VARCHAR2(50) := 'XXCOS_001_A05_05';
  cv_xxcos_001_a05_09            CONSTANT VARCHAR2(50) := 'XXCOS_001_A05_09';
  cv_stand_date                  CONSTANT VARCHAR(25)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_short_day                   CONSTANT VARCHAR(25)  := 'YYYY/MM/DD';
--  cv_short_time                  CONSTANT VARCHAR(25)  := 'HH24:MI:SS';
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
  cv_month_type                  CONSTANT VARCHAR(25)  := 'YYYY/MM';
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
  cv_amount_up                   CONSTANT VARCHAR(5)   := 'UP';
  cv_amount_down                 CONSTANT VARCHAR(5)   := 'DOWN';
  cv_amount_nearest              CONSTANT VARCHAR(10)  := 'NEAREST';
  cv_tkn_ti                      CONSTANT VARCHAR(10)  := ':';
  cv_con_char                    CONSTANT VARCHAR(25)  := ',';
  cv_space_char                  CONSTANT VARCHAR(25)  := ' ';
  cv_line_to_calculate_fees_f_n  CONSTANT VARCHAR(25)  := 'N';
  cv_line_unit_price_mst_flag_n  CONSTANT VARCHAR(25)  := 'N';
  cv_line_inv_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_head_ar_interface_flag_n    CONSTANT VARCHAR(25)  := 'N';
  cv_head_gl_interface_flag_n    CONSTANT VARCHAR(25)  := 'N';
  cv_head_dwh_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_head_edi_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_tkn_yes                     CONSTANT VARCHAR(10)  := 'Y';
--  cv_tkn_ja                      CONSTANT VARCHAR(10)  := 'JA';
  cv_depart_type                 CONSTANT VARCHAR(10)  := '1';
--  cv_depart_car                  CONSTANT VARCHAR(10)  := '2';
  cv_depart_type_k               CONSTANT VARCHAR2(10)  := '2';               -- HHT百貨店入力区分(百貨店_拠点)
  cv_depart_screen_class_base    CONSTANT VARCHAR2(10)  := '0';               -- HHT百貨店画面種別(拠点)
  cv_depart_screen_class_dep     CONSTANT VARCHAR2(10)  := '2';               -- HHT百貨店画面種別(百貨店)
  cv_line_order_invoice_l_num    CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_source_id        CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_invoice_number   CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_connection_num   CONSTANT VARCHAR(10)  := NULL;
  cv_head_edi_send_date          CONSTANT VARCHAR(10)  := NULL;
  cv_tkn_null                    CONSTANT VARCHAR(10)  := NULL;
  cv_key_name_null               CONSTANT VARCHAR(10)  := NULL;
  -- 元データ消費税区分
  cv_non_tax                     CONSTANT VARCHAR(10)  := '0';                -- 非課税
  cv_out_tax                     CONSTANT VARCHAR(10)  := '1';                -- 外税
  cv_ins_slip_tax                CONSTANT VARCHAR(10)  := '2';                -- 内税（伝票課税）
  cv_ins_bid_tax                 CONSTANT VARCHAR(10)  := '3';                -- 内税（単価込み）
  --
  cn_cons_tkn_zero               CONSTANT NUMBER  := 0;                       -- '0'
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
--******************************* 2010/02/01 M.Hokkanji Var1.20 MOD START ************************************
  --AR会計期間区分値
--  cv_fiscal_period_ar           CONSTANT  VARCHAR2(2) := '02';  --AR
  --INV会計期間区分値
  cv_fiscal_period_inv          CONSTANT  VARCHAR2(2) := '01';  --INV
  cv_fiscal_period_tkn_inv      CONSTANT  VARCHAR2(3) := 'INV'; --INV(名称)
--******************************* 2010/02/01 M.Hokkanji Var1.20 MOD END   ************************************
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
--******************************* 2009/08/12 N.Maeda Ver1.16 ADD START ***************************************
  ct_user_lang                  CONSTANT  fnd_lookup_values.language%TYPE :=  USERENV( 'LANG' );
--******************************* 2009/08/12 N.Maeda Ver1.16 ADD END *****************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
  cv_cons_num_01            CONSTANT  VARCHAR2(3)   :=  '_01';
  cv_cons_num_02            CONSTANT  VARCHAR2(3)   :=  '_02';
  cv_status_error_ins       CONSTANT  VARCHAR2(1)   :=  '3';
  cv_no                     CONSTANT  VARCHAR2(1)   :=  'N';
-- == 2010/09/09 V1.22 Added END   ===============================================================
  --エラーコード
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';         -- プロファイル取得エラー
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';         -- XXCOS:MAX日付
  cv_loc_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';         -- ロックエラー
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';         -- 業務処理日取得エラー
  cv_msg_orga        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';         -- 在庫組織ID取得エラー
  cv_msg_orga_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';         -- 在庫組織コード
  cv_msg_gl_books    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';         -- GL会計帳簿
  cv_msg_lock_work   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10037';         -- ヘッダワークテーブル及び明細ワークテーブル
  cv_msg_cus_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';         -- 顧客マスタ
  cv_inv_item_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';         -- 品目マスタ
  cv_location_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00052';         -- 保管場所マスタ
  cv_msg_lookup_mst  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';         -- 参照コードマスタ
-- ************ 2009/09/03 1.18 N.Maeda MOD START ************ --
--  cv_ar_tax_mst      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00067';         -- AR消費税マスタ
  cv_ar_tax_mst      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';         -- 消費税VIEW
-- ************ 2009/09/03 1.18 N.Maeda MOD  END  ************ --
  cv_emp_data_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00068';         -- 従業員情報VIEW
  cv_msg_cus_type    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00074';         -- 顧客区分
  cv_msg_cus_code    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00053';         -- 顧客コード
-- ************ 2009/09/03 1.18 N.Maeda MOD START ************ --
--  cv_msg_lookup_code CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00082';         -- 参照コード
  cv_msg_lookup_code CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00189';         -- 参照コード
-- ************ 2009/09/03 1.18 N.Maeda MOD  END  ************ --
  cv_msg_lookup_type CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';         -- 参照タイプ
  cv_msg_lookup_tax  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00076';         -- 消費税コード（参照コードマスタDFF2)
  cv_msg_item_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';         -- 品目コード
  cv_msg_org_id      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';         -- 在庫組織ID
  cv_msg_bace_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';         -- 拠点コード
  cv_msg_type        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00077';         -- タイプ
  cv_msg_code        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00078';         -- コード
  cv_msg_location_type  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00079';      -- 保管場所区分
  cv_msg_dlv         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';         -- 納品者コード
  cv_msg_lookup_inp  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00081';         -- 参照コード（入力区分）
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';         -- マスタチェックエラー
  cv_msg_no_data     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';         -- 顧客付帯データ取得エラー
  cv_msg_data_count  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10101';         -- 対象件数メッセージ
  cv_msg_ins_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10102';         -- 登録件数メッセージ
  cv_msg_err_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10103';         -- 登録件数メッセージ
  cv_msg_update_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12303'; -- 更新エラー
  cv_msg_delivered_from_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10104'; -- 納品形態区分エラー
  cv_msg_extract_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001'; -- 抽出エラー
-- == 2010/09/09 V1.22 Modified START ===============================================================
--  cv_msg_target_no_data         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00083'; -- 入力対象データなしメッセージ
  cv_msg_target_no_data         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003'; -- 対象データ無しエラーメッセージ
-- == 2010/09/09 V1.22 Modified START ===============================================================
  cv_msg_tab_name_colum_line    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00084'; -- VDコラム別取引情報明細
  cv_msg_tab_name_colum_head    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00085'; -- VDコラム別取引情報ヘッダ
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
  cv_msg_tab_name_colum         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10105'; -- VDコラム別取引情報
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
  cv_msg_tab_xxcos_sal_exp_head CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00086';  -- 販売実績ヘッダ
  cv_msg_tab_xxcos_sal_exp_line CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00087';  -- 販売実績明細
  cv_msg_tab_ins_err            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10351';  -- 登録エラー
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
  cv_past_sale_base_get_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00188';
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
  -- メッセージ出力
--******************************* 2009/06/01 N.Maeda Var1.14 MOD START ***************************************
--  cv_msg_count_he_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';   -- ヘッダ対象件数
--  cv_msg_count_li_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00142';   -- 明細対象件数
  cv_msg_count_he_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00180';   -- ヘッダ対象件数
--  cv_msg_count_li_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00181';   -- 明細対象件数  
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
  cv_msg_count_he_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00143';   -- ヘッダ登録成功件数
--  cv_msg_count_li_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00144';   -- 明細登録成功件数
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
  ct_msg_fiscal_period_err    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00175';   -- 会計期間取得エラー
  ct_msg_dlv_by_code          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';  -- 納品者コード
  ct_msg_keep_in_code         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00176';  -- 預け先コード
  cv_msg_skip_h               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00177';  -- スキップ件数
--  cv_msg_skip_l               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00178';  -- 明細スキップ
  cv_tkn_account_name         CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- 会計期間種別
  cv_tkn_order_number         CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- 受注番号
  cv_tkn_base_date            CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- 基準日
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
  -- トークン
  cv_tkn_tab       CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_table     CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           -- テーブル名
  cv_tkn_table_na  CONSTANT VARCHAR2(20)  := 'TABLE _NAME';
  cv_tkn_profile   CONSTANT VARCHAR2(20)  := 'PROFILE';              -- プロファイル名
  cv_tkn_colmun    CONSTANT VARCHAR2(20)  := 'COLMUN';               -- テーブル列名
  cv_key_data      CONSTANT VARCHAR2(20)  := 'KEY_DATA';             -- 編集されたキー情報
  cv_target_cnt    CONSTANT VARCHAR2(20)  := 'COUNT';                -- 対象件数
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
  cv_cust_code     CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_dlv_date      CONSTANT VARCHAR2(20)  := 'DLV_DATE';
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
-- ************ 2009/09/03 1.18 N.Maeda MOD START ************ --
  cv_msg_order_num_hht    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00191';
  cv_msg_digestion_number CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00192';
-- ************ 2009/09/03 1.18 N.Maeda MOD  END  ************ --
-- == 2010/09/09 V1.22 Added START ===============================================================
  cv_msg_xxcos_00010        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00010';
  cv_msg_xxcos_00053        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00053';
  cv_msg_xxcos_00131        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00131';
  cv_msg_xxcos_00213        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00213';
  cv_msg_xxcos_00216        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00216';
  cv_msg_xxcos_00217        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-00217';
  cv_msg_xxcos_10260        CONSTANT  VARCHAR2(30)  :=  'APP-XXCOS1-10260';
  cv_tkn_invoice_no         CONSTANT  VARCHAR2(30)  :=  'INVOICE_NO';
  cv_tkn_xxcos_10260        CONSTANT  VARCHAR2(30)  :=  'GEN_ERR_OUT_FLAG';
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- VDコラム別取引情報ヘッダデータ格納用変数
  TYPE g_rec_vd_c_head_data IS RECORD
    (
      row_id                       ROWID,                    -- 行ID
      order_no_hht                 xxcos_vd_column_headers.order_no_hht%TYPE,             -- 受注No.（HHT)
      digestion_ln_number          xxcos_vd_column_headers.digestion_ln_number%TYPE,      -- 枝番
      order_no_ebs                 xxcos_vd_column_headers.order_no_ebs%TYPE,             -- 受注No.(EBS)
      base_code                    xxcos_vd_column_headers.base_code%TYPE,                -- 拠点コード
      performance_by_code          xxcos_vd_column_headers.performance_by_code%TYPE,      -- 成績者コード
      dlv_by_code                  xxcos_vd_column_headers.dlv_by_code%TYPE,              -- 納品者コード
      hht_invoice_no               xxcos_vd_column_headers.hht_invoice_no%TYPE,           -- HHT伝票No.
      dlv_date                     xxcos_vd_column_headers.dlv_date%TYPE,                 -- 納品日
      inspect_date                 xxcos_vd_column_headers.inspect_date%TYPE,             -- 検収日
      sales_classification         xxcos_vd_column_headers.sales_classification%TYPE,     -- 売上分類区分
      sales_invoice                xxcos_vd_column_headers.sales_invoice%TYPE,            -- 売上伝票区分
      card_sale_class              xxcos_vd_column_headers.card_sale_class%TYPE,          -- カード売区分
      dlv_time                     xxcos_vd_column_headers.dlv_time%TYPE,                 -- 時間
      change_out_time_100          xxcos_vd_column_headers.change_out_time_100%TYPE,      -- つり銭切れ時間100円
      change_out_time_10           xxcos_vd_column_headers.change_out_time_10%TYPE,       -- つり銭切れ時間10円
      customer_number              xxcos_vd_column_headers.customer_number%TYPE,          -- 顧客コード
      dlv_form                     xxcos_vd_column_headers.dlv_form%TYPE,                 -- 納品形態
      system_class                 xxcos_vd_column_headers.system_class%TYPE,             -- 業態区分
      invoice_type                 xxcos_vd_column_headers.invoice_type%TYPE,             -- 伝票区分
      input_class                  xxcos_vd_column_headers.input_class%TYPE,              -- 入力区分
      consumption_tax_class        xxcos_vd_column_headers.consumption_tax_class%TYPE,    -- 消費税区分
      total_amount                 xxcos_vd_column_headers.total_amount%TYPE,             -- 合計金額
      sale_discount_amount         xxcos_vd_column_headers.sale_discount_amount%TYPE,     -- 売上値引額
      sales_consumption_tax        xxcos_vd_column_headers.sales_consumption_tax%TYPE,    -- 売上消費税額
      tax_include                  xxcos_vd_column_headers.tax_include%TYPE,              -- 税込金額
      keep_in_code                 xxcos_vd_column_headers.keep_in_code%TYPE,             -- 預け先コード
      department_screen_class      xxcos_vd_column_headers.department_screen_class%TYPE,  -- 百貨店画面種別
      digestion_vd_rate_maked_date xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE, -- 消化VD掛率作成済年月日
      red_black_flag               xxcos_vd_column_headers.red_black_flag%TYPE,            -- 赤黒フラグ
-- ************* Ver.1.28 MOD START *************--
--      cancel_correct_class         xxcos_vd_column_headers.cancel_correct_class%TYPE      --取消・訂正区分
      cancel_correct_class         xxcos_vd_column_headers.cancel_correct_class%TYPE,     --取消・訂正区分
      ttl_sales_amt                xxcos_vd_column_headers.total_sales_amt%TYPE,          -- 総販売金額
      cs_ttl_sales_amt             xxcos_vd_column_headers.cash_total_sales_amt%TYPE,     -- 現金売りトータル販売金額
      pp_ttl_sales_amt             xxcos_vd_column_headers.ppcard_total_sales_amt%TYPE,   -- PPカードトータル販売金額
      id_ttl_sales_amt             xxcos_vd_column_headers.idcard_total_sales_amt%TYPE,   -- IDカードトータル販売金額
      hht_received_flag            xxcos_vd_column_headers.hht_received_flag%TYPE         -- HHT受信フラグ
-- ************* Ver.1.28 MOD END   *************--
    );
  TYPE g_tab_vd_c_head_data IS TABLE OF g_rec_vd_c_head_data INDEX BY PLS_INTEGER;
--
  -- VDコラム別取引明細情報
  TYPE g_rec_vd_c_lines_data IS RECORD
    (
      order_no_hht                xxcos_vd_column_lines.order_no_hht%TYPE,          --受注No.(HHT)
      line_no_hht                 xxcos_vd_column_lines.line_no_hht%TYPE,           --行No.(HHT)
      digestion_ln_number         xxcos_vd_column_lines.digestion_ln_number%TYPE,   --枝番
      order_no_ebs                xxcos_vd_column_lines.order_no_ebs%TYPE,          --受注No.(EBS)
      line_number_ebs             xxcos_vd_column_lines.line_number_ebs%TYPE,       --明細番号(EBS)
      item_code_self              xxcos_vd_column_lines.item_code_self%TYPE,        --品名コード(自社)
      content                     xxcos_vd_column_lines.content%TYPE,               --入数
      inventory_item_id           xxcos_vd_column_lines.inventory_item_id%TYPE,     --品目ID
      standard_unit               xxcos_vd_column_lines.standard_unit%TYPE,         --基準単位
      case_number                 xxcos_vd_column_lines.case_number%TYPE,           --ケース数
      quantity                    xxcos_vd_column_lines.quantity%TYPE,              --数量
      sale_class                  xxcos_vd_column_lines.sale_class%TYPE,            --売上区分
      wholesale_unit_ploce        xxcos_vd_column_lines.wholesale_unit_ploce%TYPE,  --卸単価
      selling_price               xxcos_vd_column_lines.selling_price%TYPE,         --売単価
      column_no                   xxcos_vd_column_lines.column_no%TYPE,             --コラムNo
      h_and_c                     xxcos_vd_column_lines.h_and_c%TYPE,               --H/C
      sold_out_class              xxcos_vd_column_lines.sold_out_class%TYPE,        --売切区分
      sold_out_time               xxcos_vd_column_lines.sold_out_time%TYPE,         --売切時間
      replenish_number            xxcos_vd_column_lines.replenish_number%TYPE,      --補充数
      cash_and_card               xxcos_vd_column_lines.cash_and_card%TYPE          --現金・カード併用額
    );
  TYPE g_tab_vd_c_lines_data IS TABLE OF g_rec_vd_c_lines_data INDEX BY PLS_INTEGER;
--
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
  TYPE g_rec_accumulation_data IS RECORD
    (
     row_id                  ROWID,
     dlv_invoice_number      xxcos_sales_exp_lines.dlv_invoice_number%TYPE,       -- 納品伝票番号
     dlv_invoice_line_number xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE,  -- 納品明細番号
     sales_class             xxcos_sales_exp_lines.sales_class%TYPE,              -- 売上区分
     red_black_flag          xxcos_sales_exp_lines.red_black_flag%TYPE,           -- 赤黒フラグ
     item_code               xxcos_sales_exp_lines.item_code%TYPE,                -- 品目コード
     dlv_qty                 xxcos_sales_exp_lines.dlv_qty%TYPE,                  -- 納品数量
     standard_qty            xxcos_sales_exp_lines.standard_qty%TYPE,             -- 基準数量
     dlv_uom_code            xxcos_sales_exp_lines.dlv_uom_code%TYPE,             -- 納品単位
     standard_uom_code       xxcos_sales_exp_lines.standard_uom_code%TYPE,        -- 基準単位(納品単位)
     dlv_unit_price          xxcos_sales_exp_lines.dlv_unit_price%TYPE,            -- 納品単価
     standard_unit_price     xxcos_sales_exp_lines.standard_unit_price%TYPE,      -- 基準単価(納品単価)
     business_cost           xxcos_sales_exp_lines.business_cost%TYPE,            -- 営業原価
     sale_amount             xxcos_sales_exp_lines.sale_amount%TYPE,              -- 売上金額
     pure_amount             xxcos_sales_exp_lines.pure_amount%TYPE,              -- 本体金額
     tax_amount              xxcos_sales_exp_lines.tax_amount%TYPE,               -- 消費税金額
     cash_and_card           xxcos_sales_exp_lines.cash_and_card%TYPE,            -- 現金・カード併用額
     ship_from_subinventory_code  xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE,      -- 出荷元保管場所
     delivery_base_code      xxcos_sales_exp_lines.delivery_base_code%TYPE,       -- 納品拠点コード
     hot_cold_class          xxcos_sales_exp_lines.hot_cold_class%TYPE,           -- Ｈ＆Ｃ
     column_no               xxcos_sales_exp_lines.column_no%TYPE,                -- コラムNo
     sold_out_class          xxcos_sales_exp_lines.sold_out_class%TYPE,           -- 売切区分
     sold_out_time           xxcos_sales_exp_lines.sold_out_time%TYPE,            -- 売切時間
     to_calculate_fees_flag  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE,   -- 手数料計算インタフェース済フラグ
     unit_price_mst_flag     xxcos_sales_exp_lines.unit_price_mst_flag%TYPE,      -- 単価マスタ作成済フラグ
     inv_interface_flag      xxcos_sales_exp_lines.inv_interface_flag%TYPE,       -- INVインタフェース済フラグ
     order_invoice_line_number     xxcos_sales_exp_lines.order_invoice_line_number%TYPE,  -- 注文明細番号(NULL設定)
     standard_unit_price_excluded  xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE, -- 税抜基準単価
     delivery_pattern_class        xxcos_sales_exp_lines.delivery_pattern_class%TYPE   -- 納品形態区分(導出)
     );
  TYPE g_tab_accumulation_data IS TABLE OF g_rec_accumulation_data INDEX BY PLS_INTEGER;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END ***************************************
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- ヘッダデータ登録用変数
  TYPE g_tab_head_row_id            IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- 販売実績ヘッダID
  TYPE g_tab_head_id                IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- 販売実績ヘッダID
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_sales_exp_headers.order_number%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(EBS)(受注番号)
  TYPE g_tab_head_digestion_ln_number IS TABLE OF xxcos_sales_exp_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;   -- 枝番(受注No(HHT)枝番)
  TYPE g_tab_head_dlv_invoice_class IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_class%TYPE
    INDEX BY PLS_INTEGER;   --納品伝票区分(導出)
  TYPE g_tab_head_cancel_cor_cls    IS TABLE OF xxcos_sales_exp_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   --取消・訂正区分(導出)
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_sales_exp_headers.cust_gyotai_sho%TYPE
    INDEX BY PLS_INTEGER;   --業態区分(業態小分類)
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_sales_exp_headers.delivery_date%TYPE
    INDEX BY PLS_INTEGER;   --納品日
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_sales_exp_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   --検収日
  TYPE g_tab_head_customer_number   IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    INDEX BY PLS_INTEGER;   --顧客【納品先】
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_sales_exp_headers.sale_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --売上金額合計
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_sales_exp_headers.pure_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --合計金額(本体金額合計)
  TYPE g_tab_head_sales_consump_tax IS TABLE OF xxcos_sales_exp_headers.tax_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --消費税金額合計
  TYPE g_tab_head_consump_tax_class IS TABLE OF xxcos_sales_exp_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   --消費税区分(導出)
  TYPE g_tab_head_tax_code          IS TABLE OF xxcos_sales_exp_headers.tax_code%TYPE
    INDEX BY PLS_INTEGER;   --税金コード(導出)
  TYPE g_tab_head_tax_rate          IS TABLE OF xxcos_sales_exp_headers.tax_rate%TYPE
    INDEX BY PLS_INTEGER;   --消費税率(導出)
  TYPE g_tab_head_performance_by_code     IS TABLE OF xxcos_sales_exp_headers.results_employee_code%TYPE
    INDEX BY PLS_INTEGER;   --成績計上者コード
  TYPE g_tab_head_sales_base_code   IS TABLE OF xxcos_sales_exp_headers.sales_base_code%TYPE
    INDEX BY PLS_INTEGER;   --売上拠点コード(導出)
  TYPE g_tab_head_card_sale_class   IS TABLE OF xxcos_sales_exp_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   --カード売り区分
  TYPE g_tab_head_sales_classificat    IS TABLE OF xxcos_sales_exp_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;   --伝票区分
  TYPE g_tab_head_invoice_class     IS TABLE OF xxcos_sales_exp_headers.invoice_classification_code%TYPE
    INDEX BY PLS_INTEGER;   --伝票分類コード
  TYPE g_tab_head_receiv_base_code  IS TABLE OF xxcos_sales_exp_headers.receiv_base_code%TYPE
    INDEX BY PLS_INTEGER;   --入金拠点コード(導出)
  TYPE g_tab_head_change_out_time_100     IS TABLE OF xxcos_sales_exp_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   --つり銭切れ時間100円
  TYPE g_tab_head_change_out_time_10      IS TABLE OF xxcos_sales_exp_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   --つり銭切れ時間10円
  TYPE g_tab_head_hht_dlv_input_date      IS TABLE OF xxcos_sales_exp_headers.hht_dlv_input_date%TYPE
    INDEX BY PLS_INTEGER;   --HHT納品入力日時(成型日時)
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_sales_exp_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   --納品者コード
  TYPE g_tab_head_business_date     IS TABLE OF xxcos_sales_exp_headers.business_date%TYPE
    INDEX BY PLS_INTEGER;   --登録業務日付(初期処理取得)
  TYPE g_tab_head_order_source_id   IS TABLE OF xxcos_sales_exp_headers.order_source_id%TYPE
    INDEX BY PLS_INTEGER;   --受注ソースID(NULL設定)
  TYPE g_tab_head_order_invoice_num IS TABLE OF xxcos_sales_exp_headers.order_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --注文伝票番号(NULL設定)
  TYPE g_tab_head_order_connect_num IS TABLE OF xxcos_sales_exp_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;   --受注関連番号(NULL設定)
  TYPE g_tab_head_ar_interface_flag IS TABLE OF xxcos_sales_exp_headers.ar_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --ARインタフェース済フラグ('N'設定)
  TYPE g_tab_head_gl_interface_flag IS TABLE OF xxcos_sales_exp_headers.gl_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --GLインタフェース済フラグ('N'設定)
  TYPE g_tab_head_dwh_interface_flag IS TABLE OF xxcos_sales_exp_headers.dwh_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --情報システムインタフェース済フラグ('N'設定)
  TYPE g_tab_head_edi_interface_flag IS TABLE OF xxcos_sales_exp_headers.edi_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --EDI送信済みフラグ('N'設定)
  TYPE g_tab_head_edi_send_date      IS TABLE OF xxcos_sales_exp_headers.edi_send_date%TYPE
    INDEX BY PLS_INTEGER;   --EDI送信日時(NULL設定)
  TYPE g_tab_head_create_class       IS TABLE OF xxcos_sales_exp_headers.create_class%TYPE
    INDEX BY PLS_INTEGER;   --作成元区分(｢3｣設定)
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_sales_exp_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(HHT)(受注No(HHT))  
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --HHT伝票No.(HHT伝票No?、納品伝票No?)
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_sales_exp_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   --入力区分
-- ************* Ver.1.28 ADD START *************--
  TYPE g_tab_head_ttl_sales_amt     IS TABLE OF xxcos_sales_exp_headers.total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- 総販売金額
  TYPE g_tab_head_cs_ttl_sales_amt  IS TABLE OF xxcos_sales_exp_headers.cash_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- 現金売りトータル販売金額
  TYPE g_tab_head_pp_ttl_sales_amt  IS TABLE OF xxcos_sales_exp_headers.ppcard_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- PPカードトータル販売金額
  TYPE g_tab_head_id_ttl_sales_amt  IS TABLE OF xxcos_sales_exp_headers.idcard_total_sales_amt%TYPE
    INDEX BY PLS_INTEGER;   -- IDカードトータル販売金額
  TYPE g_tab_head_hht_received_flag IS TABLE OF xxcos_sales_exp_headers.hht_received_flag%TYPE
    INDEX BY PLS_INTEGER;   -- HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
  --明細データ登録用変数
  TYPE g_tab_line_sales_exp_line_id      IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;   --販売実績明細ID
  TYPE g_tab_line_sal_exp_header_id    IS TABLE OF xxcos_sales_exp_lines.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   --販売実績ヘッダID
  TYPE g_tab_line_dlv_invoice_number     IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --納品伝票番号
  TYPE g_tab_line_dlv_invoice_l_num  IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   --納品明細番号
  TYPE g_tab_line_sales_class            IS TABLE OF xxcos_sales_exp_lines.sales_class%TYPE
    INDEX BY PLS_INTEGER;   --売上区分
  TYPE g_tab_line_red_black_flag         IS TABLE OF xxcos_sales_exp_lines.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   --赤黒フラグ
  TYPE g_tab_line_item_code              IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;   --品目コード
  TYPE g_tab_line_dlv_qty                IS TABLE OF xxcos_sales_exp_lines.dlv_qty%TYPE
    INDEX BY PLS_INTEGER;   --納品数量
  TYPE g_tab_line_standard_qty           IS TABLE OF xxcos_sales_exp_lines.standard_qty%TYPE
    INDEX BY PLS_INTEGER;   --基準数量(納品数量)
  TYPE g_tab_line_dlv_uom_code           IS TABLE OF xxcos_sales_exp_lines.dlv_uom_code%TYPE
    INDEX BY PLS_INTEGER;   --納品単位
  TYPE g_tab_line_standard_uom_code      IS TABLE OF xxcos_sales_exp_lines.standard_uom_code%TYPE
    INDEX BY PLS_INTEGER;   --基準単位(納品単位)
  TYPE g_tab_line_dlv_unit_price         IS TABLE OF xxcos_sales_exp_lines.dlv_unit_price%TYPE
    INDEX BY PLS_INTEGER;   --納品単価(納品単価)
  TYPE g_tab_line_standard_unit_price    IS TABLE OF xxcos_sales_exp_lines.standard_unit_price%TYPE
    INDEX BY PLS_INTEGER;   --基準単価
  TYPE g_tab_line_business_cost          IS TABLE OF xxcos_sales_exp_lines.business_cost%TYPE
    INDEX BY PLS_INTEGER;   --営業原価
  TYPE g_tab_line_sale_amount            IS TABLE OF xxcos_sales_exp_lines.sale_amount%TYPE
    INDEX BY PLS_INTEGER;   --売上金額
  TYPE g_tab_line_pure_amount            IS TABLE OF xxcos_sales_exp_lines.pure_amount%TYPE
    INDEX BY PLS_INTEGER;   --本体金額
  TYPE g_tab_line_tax_amount             IS TABLE OF xxcos_sales_exp_lines.tax_amount%TYPE
    INDEX BY PLS_INTEGER;   --消費税金額
  TYPE g_tab_line_cash_and_card          IS TABLE OF xxcos_sales_exp_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   --現金・カード併用額
  TYPE g_tab_line_ship_from_subinv_co    IS TABLE OF xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE
    INDEX BY PLS_INTEGER;   --出荷元保管場所
  TYPE g_tab_line_delivery_base_code     IS TABLE OF xxcos_sales_exp_lines.delivery_base_code%TYPE
    INDEX BY PLS_INTEGER;   --納品拠点コード
  TYPE g_tab_line_hot_cold_class         IS TABLE OF xxcos_sales_exp_lines.hot_cold_class%TYPE
    INDEX BY PLS_INTEGER;   --Ｈ＆Ｃ
  TYPE g_tab_line_column_no              IS TABLE OF xxcos_sales_exp_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   --コラムNo
  TYPE g_tab_line_sold_out_class         IS TABLE OF xxcos_sales_exp_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   --売切区分
  TYPE g_tab_line_sold_out_time          IS TABLE OF xxcos_sales_exp_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   --売切時間
  TYPE g_tab_line_to_cal_fees_flag IS TABLE OF xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
    INDEX BY PLS_INTEGER;   --手数料計算インタフェース済フラグ
  TYPE g_tab_line_unit_price_mst_flag    IS TABLE OF xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
    INDEX BY PLS_INTEGER;   --単価マスタ作成済フラグ
  TYPE g_tab_line_inv_interface_flag     IS TABLE OF xxcos_sales_exp_lines.inv_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --INVインタフェース済フラグ
  TYPE g_tab_line_order_invoice_l_num IS TABLE OF xxcos_sales_exp_lines.order_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   --注文明細番号(NULL設定)
  TYPE g_tab_line_not_tax_amount      IS TABLE OF xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE
    INDEX BY PLS_INTEGER;   --税抜基準単価
  TYPE g_tab_line_delivery_pat_class      IS TABLE OF xxcos_sales_exp_lines.delivery_pattern_class%TYPE
    INDEX BY PLS_INTEGER;   --納品形態区分(導出)
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START *************************************
  TYPE g_tab_msg_war_data     IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END ***************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
  TYPE  g_err_key_ttype IS  TABLE OF xxcos_gen_err_list%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_err_key_msg_tab        g_err_key_ttype;                  --  汎用エラーリスト用keyメッセージ
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
  --ヘッダデータ格納変数
  gt_head_row_id                  g_tab_head_row_id;              -- ヘッダ行ID
  gt_head_id                      g_tab_head_id;                  -- 販売実績ヘッダID
  gt_head_order_no_ebs            g_tab_head_order_no_ebs;        -- 受注番号
  gt_head_digestion_ln_number     g_tab_head_digestion_ln_number; -- 枝番(受注No(HHT)枝番)
  gt_head_dlv_invoice_class       g_tab_head_dlv_invoice_class;   -- 納品伝票区分(導出)
  gt_head_cancel_cor_cls          g_tab_head_cancel_cor_cls;      -- 取消・訂正区分(導出)
  gt_head_system_class            g_tab_head_system_class;        -- 業態区分(業態小分類)
--******************************* 2009/05/20 N.Maeda Var1.14 ADD START ***************************************
  gt_head_open_dlv_date           g_tab_head_dlv_date;             -- 納品日
  gt_head_open_inspect_date       g_tab_head_inspect_date;         -- 検収日(売上計上日)
--******************************* 2009/05/20 N.Maeda Var1.14 ADD END   ***************************************
  gt_head_dlv_date                g_tab_head_dlv_date;            -- オリジナル納品日
  gt_head_inspect_date            g_tab_head_inspect_date;        -- オリジナル検収日(売上計上日)
  gt_head_customer_number         g_tab_head_customer_number;     -- 顧客コード(顧客【納品先】)
  gt_head_tax_include             g_tab_head_tax_include;         -- 税込金額(売上金額合計)
  gt_head_total_amount            g_tab_head_total_amount;        -- 合計金額(本体金額合計)
  gt_head_sales_consump_tax       g_tab_head_sales_consump_tax;   -- 売上消費税額(消費税金額合計)
  gt_head_consump_tax_class       g_tab_head_consump_tax_class;   -- 消費税区分(導出)
  gt_head_tax_code                g_tab_head_tax_code;            -- 税金コード(導出)
  gt_head_tax_rate                g_tab_head_tax_rate;            -- 消費税率(導出)
  gt_head_performance_by_code     g_tab_head_performance_by_code; -- 成績者コード(成績計上者コード)
  gt_head_sales_base_code         g_tab_head_sales_base_code;     -- 売上拠点コード(導出)
  gt_head_card_sale_class         g_tab_head_card_sale_class;     -- カード売り区分
  gt_head_sales_classification    g_tab_head_sales_classificat;   -- 売上分類区分(伝票区分)
  gt_head_invoice_class           g_tab_head_invoice_class;       -- 売上伝票区分(伝票分類コード)
  gt_head_receiv_base_code        g_tab_head_receiv_base_code;    -- 入金拠点コード(導出)
  gt_head_change_out_time_100     g_tab_head_change_out_time_100; -- つり銭切れ時間100円
  gt_head_change_out_time_10      g_tab_head_change_out_time_10;  -- つり銭切れ時間10円
  gt_head_hht_dlv_input_date      g_tab_head_hht_dlv_input_date;  -- HHT納品入力日時(成型日時)
  gt_head_dlv_by_code             g_tab_head_dlv_by_code;         -- 納品者コード
  gt_head_business_date           g_tab_head_business_date;       -- 登録業務日付(初期処理取得)
  gt_head_order_source_id         g_tab_head_order_source_id;      -- 受注ソースID(NULL設定)order_source_id
  gt_head_order_invoice_number    g_tab_head_order_invoice_num; -- 注文伝票番号(NULL設定)
  gt_head_order_connection_num    g_tab_head_order_connect_num; -- 受注関連番号(NULL設定)
  gt_head_ar_interface_flag       g_tab_head_ar_interface_flag;    -- ARインタフェース済フラグ('N'設定)ar_interface_flag
  gt_head_gl_interface_flag       g_tab_head_gl_interface_flag;    -- GLインタフェース済フラグ('N'設定)
  gt_head_dwh_interface_flag      g_tab_head_dwh_interface_flag;   -- 情報システムインタフェース済フラグ('N'設定)
  gt_head_edi_interface_flag      g_tab_head_edi_interface_flag;   -- EDI送信済みフラグ('N'設定)
  gt_head_edi_send_date           g_tab_head_edi_send_date;        -- EDI送信日時(NULL設定)
  gt_head_create_class            g_tab_head_create_class;         -- 作成元区分(｢3｣設定)
  gt_head_order_no_hht            g_tab_head_order_no_hht;      -- 受注No.(HHT)(受注No(HHT))  
  gt_head_hht_invoice_no          g_tab_head_hht_invoice_no;    -- HHT伝票No.(HHT伝票No?、納品伝票No?)
  gt_head_input_class             g_tab_head_input_class;       -- 入力区分
-- ************* Ver.1.28 ADD START *************--
  gt_head_ttl_sales_amt           g_tab_head_ttl_sales_amt;        -- 総販売金額
  gt_head_cs_ttl_sales_amt        g_tab_head_cs_ttl_sales_amt;     -- 現金売りトータル販売金額
  gt_head_pp_ttl_sales_amt        g_tab_head_pp_ttl_sales_amt;     -- PPカードトータル販売金額
  gt_head_id_ttl_sales_amt        g_tab_head_id_ttl_sales_amt;     -- IDカードトータル販売金額
  gt_head_hht_received_flag       g_tab_head_hht_received_flag;    -- HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
--
  --明細データ格納変数
  gt_line_sales_exp_line_id       g_tab_line_sales_exp_line_id;      -- 販売実績明細ID
  gt_line_sales_exp_header_id     g_tab_line_sal_exp_header_id;      -- 販売実績ヘッダID  
  gt_line_dlv_invoice_number      g_tab_line_dlv_invoice_number;     -- 納品伝票番号
  gt_line_dlv_invoice_l_num       g_tab_line_dlv_invoice_l_num;      -- 納品明細番号
  gt_line_sales_class             g_tab_line_sales_class;            -- 売上区分
  gt_line_red_black_flag          g_tab_line_red_black_flag;         -- 赤黒フラグ
  gt_line_item_code               g_tab_line_item_code;              -- 品目コード
  gt_line_dlv_qty                 g_tab_line_dlv_qty;                -- 納品数量
  gt_line_standard_qty            g_tab_line_standard_qty;           -- 基準数量
  gt_line_dlv_uom_code            g_tab_line_dlv_uom_code;           -- 納品単位
  gt_line_standard_uom_code       g_tab_line_standard_uom_code;      -- 基準単位
  gt_dlv_unit_price               g_tab_line_dlv_unit_price;         -- 納品単価
  gt_line_standard_unit_price     g_tab_line_standard_unit_price;    -- 基準単価
  gt_line_business_cost           g_tab_line_business_cost;          -- 営業原価
  gt_line_sale_amount             g_tab_line_sale_amount;            -- 売上金額
  gt_line_pure_amount             g_tab_line_pure_amount;            -- 本体金額
  gt_line_tax_amount              g_tab_line_tax_amount;             -- 消費税金額
  gt_line_cash_and_card           g_tab_line_cash_and_card;          -- 現金・カード併用額
  gt_line_ship_from_subinv_co     g_tab_line_ship_from_subinv_co;    -- 出荷元保管場所
  gt_line_delivery_base_code      g_tab_line_delivery_base_code;     -- 納品拠点コード
  gt_line_hot_cold_class          g_tab_line_hot_cold_class;         -- Ｈ＆Ｃ
  gt_line_column_no               g_tab_line_column_no;              -- コラムNo
  gt_line_sold_out_class          g_tab_line_sold_out_class;         -- 売切区分
  gt_line_sold_out_time           g_tab_line_sold_out_time;          -- 売切時間
  gt_line_to_calculate_fees_flag  g_tab_line_to_cal_fees_flag;       -- 手数料計算インタフェース済フラグ
  gt_line_unit_price_mst_flag     g_tab_line_unit_price_mst_flag;    -- 単価マスタ作成済フラグ
  gt_line_inv_interface_flag      g_tab_line_inv_interface_flag;     -- INVインタフェース済フラグ
  gt_line_order_invoice_l_num     g_tab_line_order_invoice_l_num;    -- 注文明細番号(NULL設定)
  gt_line_not_tax_amount          g_tab_line_not_tax_amount;         -- 税抜基準単価
  gt_line_delivery_pat_class      g_tab_line_delivery_pat_class;         -- 納品形態区分(導出)
--
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START *************************************
  gt_accumulation_data            g_tab_accumulation_data;        -- データ格納用
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END ***************************************
  gt_vd_c_headers_data            g_tab_vd_c_head_data;  -- VDコラム別取引情報ヘッダテーブル抽出データ
  gt_vd_c_lines_data              g_tab_vd_c_lines_data; -- VDコラム別取引明細情報テーブル抽出データ
  gt_inp_vd_c_headers_data        g_tab_vd_c_head_data;  -- 入力画面データVDコラム別取引情報ヘッダテーブル抽出データ
  gt_inp_vd_c_lines_data          g_tab_vd_c_lines_data; -- 入力画面データVDコラム別取引明細情報テーブル抽出データ
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START *************************************
  --警告メッセージ出力用
  gt_msg_war_data                 g_tab_msg_war_data;                -- 警告情報(詳細)
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END ***************************************
--******************************* 2009/05/12 N.Maeda Var1.12 ADD START ***************************************
  gt_sales_head_row_id            g_tab_head_row_id;                  -- 販売実績行ID
  gt_set_sales_head_row_id        g_tab_head_row_id;                  -- 更新用販売実績行ID
  gt_set_head_cancel_cor_cls      g_tab_head_cancel_cor_cls;          -- 販売実績更新用-取消・訂正区分
--******************************* 2009/05/12 N.Maeda Var1.12 ADD  END  ***************************************
--
--  gn_consum_amount    NUMBER;
--  gn_head_cnt         NUMBER;                         -- ヘッダ登録件数
  gn_line_cnt         NUMBER;                         -- 明細登録件数
  gn_update_count     NUMBER;                         -- 更新件数
--  gn_amount_data      NUMBER;                         -- 本体金額
--  gn_sales_amount     NUMBER;                         -- 売上金額
--  gt_consum_amount    NUMBER;                         -- 消費税額
--  gn_inp_target_cnt   NUMBER;                         -- 入力画面登録データ取得件数(ヘッダ)
  gn_target_lines_cnt NUMBER;                         -- 明細件数カウント用
--  gn_target_lines_inp_cnt NUMBER;                     -- 入力画面登録データ取得件数(明細)
  gn_orga_id          NUMBER;                         -- 在庫組織ID
  gn_header_ck_no     NUMBER := 1;                    -- ヘッダ登録用変数添え字
  gn_line_ck_no       NUMBER := 1;                    -- 明細登録用変数添え字
  gd_process_date     DATE;                           -- 業務処理日
  gd_input_date       DATE;                           -- HHT納品入力日時
  gd_max_date         DATE;                           -- MAX日付
  gv_orga_code        VARCHAR2(50);                   -- 在庫組織コード
  gv_bks_id           VARCHAR2(50);                   -- 会計帳簿ID
  gv_tkn1             VARCHAR2(5000);                   -- エラーメッセージ用トークン１
  gv_tkn2             VARCHAR2(5000);                   -- エラーメッセージ用トークン２
  gv_tkn3             VARCHAR2(5000);                   -- エラーメッセージ用トークン３
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
  gn_wae_data_num     NUMBER := 0;                       -- 警告データ格納用
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
--******************************* 2009/05/12 N.Maeda Var1.12 ADD START ***************************************
  gn_wae_data_count   NUMBER := 0;                       -- 警告件数カウント
--******************************* 2009/05/12 N.Maeda Var1.12 ADD  END  ***************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
  gv_prm_gen_err_out_flag   VARCHAR2(1);                      --  汎用エラーリスト出力フラグ
  gn_msg_cnt                NUMBER;                           --  汎用エラーリスト用メッセージ件数
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
-- == 2010/09/09 V1.22 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : ins_err_msg
   * Description      : エラー情報登録処理(A-8)
   ***********************************************************************************/
--
  PROCEDURE ins_err_msg(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_err_msg'; -- プログラム名
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
    lv_outmsg       VARCHAR2(5000);   --  エラーメッセージ
    lv_table_name   VARCHAR2(100);    --  テーブル名称
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
    FOR ln_set_cnt  IN  1 .. gn_msg_cnt LOOP
      -- ===============================
      --  キー情報以外の設定
      -- ===============================
      --  汎用エラーリストID
      SELECT  xxcos_gen_err_list_s01.NEXTVAL
      INTO    gt_err_key_msg_tab(ln_set_cnt).gen_err_list_id
      FROM    dual;
      --
      gt_err_key_msg_tab(ln_set_cnt).concurrent_program_name  :=  cv_pkg_name;                  --  コンカレント名
      gt_err_key_msg_tab(ln_set_cnt).business_date            :=  gd_process_date;              --  登録業務日付
      gt_err_key_msg_tab(ln_set_cnt).created_by               :=  cn_created_by;                --  作成者
      gt_err_key_msg_tab(ln_set_cnt).creation_date            :=  SYSDATE;                      --  作成日
      gt_err_key_msg_tab(ln_set_cnt).last_updated_by          :=  cn_last_updated_by;           --  最終更新者
      gt_err_key_msg_tab(ln_set_cnt).last_update_date         :=  SYSDATE;                      --  最終更新日
      gt_err_key_msg_tab(ln_set_cnt).last_update_login        :=  cn_last_update_login;         --  最終更新ログイン
      gt_err_key_msg_tab(ln_set_cnt).request_id               :=  cn_request_id;                --  要求ID
      gt_err_key_msg_tab(ln_set_cnt).program_application_id   :=  cn_program_application_id;    --  コンカレント・プログラム・アプリケーションID
      gt_err_key_msg_tab(ln_set_cnt).program_id               :=  cn_program_id;                --  コンカレント・プログラムID
      gt_err_key_msg_tab(ln_set_cnt).program_update_date      :=  SYSDATE;                      --  プログラム更新日
    END LOOP;
    --
    -- ===============================
    --  汎用エラーリスト登録
    -- ===============================
    FORALL ln_cnt IN 1 .. gn_msg_cnt  SAVE EXCEPTIONS
      INSERT  INTO  xxcos_gen_err_list VALUES gt_err_key_msg_tab(ln_cnt);
--
  EXCEPTION
    -- *** バルクインサート例外処理 ***
    WHEN global_bulk_ins_expt THEN
      gn_error_cnt  :=  SQL%BULK_EXCEPTIONS.COUNT;        --  エラー件数
      ov_retcode    :=  cv_status_error_ins;              --  ステータス（エラー）
      ov_errmsg     :=  NULL;                             --  ユーザー・エラー・メッセージ
      ov_errbuf     :=  NULL;                             --  エラー・メッセージ
      --
      --  テーブル名称
      lv_table_name :=  xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_application
                          , iv_name         =>  cv_msg_xxcos_00213
                        );
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_error_cnt  LOOP
        -- エラーメッセージ生成
        lv_outmsg :=  SUBSTRB(
                        xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_application
                          , iv_name           =>  cv_msg_xxcos_00010
                          , iv_token_name1    =>  cv_tkn_table
                          , iv_token_value1   =>  lv_table_name
                          , iv_token_name2    =>  cv_key_data
                          , iv_token_value2   =>  cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                        ), 1, 5000
                      );
        -- エラーメッセージ出力
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_outmsg
        );
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.LOG
          , buff    =>  lv_outmsg
        );
      END LOOP output_error_loop;
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
  END ins_err_msg;
-- == 2010/09/09 V1.22 Added END   ===============================================================
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
  /************************************************************************
   * Function Name   : get_fiscal_period_from
   * Description     : 有効会計期間FROM取得関数(A-6)
   ************************************************************************/
  PROCEDURE get_fiscal_period_from(
    iv_div                  IN  VARCHAR2,     -- 会計区分
    id_base_date            IN  DATE,         -- 基準日
    od_open_date            OUT DATE,         -- 有効会計期間FROM
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fiscal_period_from'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_status_open      CONSTANT VARCHAR2(5)  := 'OPEN';                     -- ステータス[OPEN]
--
    -- *** ローカル変数 ***
    lv_status    VARCHAR2(6); -- ステータス
    lv_date_from DATE;        -- 会計（FROM）
    lv_date_to   DATE;        -- 会計（TO）
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
    --１．初期処理
    lv_status    := NULL;  -- ステータス
    lv_date_from := NULL;  -- 会計（FROM）
    lv_date_to   := NULL;  -- 会計（TO）
--
    --２．基準日会計期間情報取得
    xxcos_common_pkg.get_account_period(
     iv_account_period         => iv_div,         -- 会計区分
     id_base_date              => id_base_date,   -- 基準日
     ov_status                 => lv_status,      -- ステータス
     od_start_date             => lv_date_from,   -- 会計(FROM)
     od_end_date               => lv_date_to,     -- 会計(TO)
     ov_errbuf                 => lv_errbuf,      -- エラー・メッセージエラー       #固定#
     ov_retcode                => lv_retcode,     -- リターン・コード               #固定#
     ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   #固定#
    );
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --ステータスチェック
    IF ( lv_status = cv_status_open ) THEN
      od_open_date := id_base_date;
      RETURN;
    END IF;
--
    --３．OPEN会計期間情報取得
    xxcos_common_pkg.get_account_period(
     iv_account_period         => iv_div,         -- 会計区分
     id_base_date              => NULL,           -- 基準日
     ov_status                 => lv_status,      -- ステータス
     od_start_date             => lv_date_from,   -- 会計(FROM)
     od_end_date               => lv_date_to,     -- 会計(TO)
     ov_errbuf                 => lv_errbuf,      -- エラー・メッセージエラー       #固定#
     ov_retcode                => lv_retcode,     -- リターン・コード               #固定#
     ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   #固定#
    );
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --会計期間FROM
    od_open_date := lv_date_from;
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
  END get_fiscal_period_from;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END   ***************************************
--
  /**********************************************************************************
   * Procedure Name   : proc_data_update
   * Description      : 取得元テーブルフラグ更新(A-5)
   ***********************************************************************************/
  PROCEDURE proc_data_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ   --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_update'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  --==================
  -- ユーザー定義変数
  --==================
--  lt_update_rowid     ROWID;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --== データ登録 ==--
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
    -- 明細データ作成件数セット
--    gn_update_count := gt_vd_c_headers_data.COUNT;
    gn_update_count := gt_head_row_id.COUNT;
--
--    <<id_loop>>
--    FOR row_count IN 1..gn_update_count LOOP
--      gt_head_row_id( row_count ) := gt_vd_c_headers_data( row_count ).row_id;
--    END LOOP id_loop;
--
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
    BEGIN
--
      FORALL i IN 1..gn_update_count
--
       UPDATE xxcos_vd_column_headers
       SET    forward_flag = cv_tkn_yes,                           --連携済みフラグ
              forward_date = gd_process_date,                      --連携日
              last_updated_by = cn_last_updated_by,                --最終更新者
              last_update_date = cd_last_update_date,              --最終更新日
              last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
              request_id = cn_request_id,                          --要求ID
              program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
              program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日                        
       WHERE  ROWID  =  gt_head_row_id( i );
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_head );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table,gv_tkn1);
        RAISE updata_err_expt;
    END;
--
--******************************* 2009/05/12 N.Maeda Var1.12 ADD START ***************************************
    BEGIN
--
      FORALL i IN 1..gt_set_sales_head_row_id.COUNT
--
       UPDATE xxcos_sales_exp_headers
       SET    cancel_correct_class = gt_set_head_cancel_cor_cls( i ), --取消・訂正区分
              last_updated_by = cn_last_updated_by,                --最終更新者
              last_update_date = cd_last_update_date,              --最終更新日
              last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
              request_id = cn_request_id,                          --要求ID
              program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
              program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
              program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
       WHERE  ROWID  =  gt_set_sales_head_row_id( i );
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table,gv_tkn1);
        RAISE updata_err_expt;
    END;
--******************************* 2009/05/12 N.Maeda Var1.12 ADD  END  ***************************************
--
  EXCEPTION
    WHEN updata_err_expt THEN
      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--####################################  固定部 START ###########################################
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
  END proc_data_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_data_insert_line
   * Description      : 販売実績データ登録処理(明細)(A-4-2)
   ***********************************************************************************/
  PROCEDURE proc_data_insert_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2 )     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_insert_line'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--******************************* 2009/06/01 N.Maeda Var1.14 MOD START ***************************************
    --== データ登録 ==--
--    -- 明細データ作成件数セット
--    gn_line_cnt := gt_line_sales_exp_line_id.COUNT;
--
    BEGIN
--      FORALL i IN 1..gn_line_cnt
      FORALL i IN 1..gt_line_sales_exp_line_id.COUNT
--******************************* 2009/06/01 N.Maeda Var1.14 MOD  END  ***************************************
        INSERT INTO xxcos_sales_exp_lines            --販売実績明細テーブル
                      (
                        sales_exp_line_id,             --1.販売実績明細ID
                        sales_exp_header_id,           --2.販売実績ヘッダID
                        dlv_invoice_number,            --3.納品伝票番号
                        dlv_invoice_line_number,       --4.納品明細番号
                        order_invoice_line_number,     --5.注文明細番号
                        sales_class,                   --6.売上区分
                        red_black_flag,                --7.赤黒フラグ
                        item_code,                     --8.品目コード
                        dlv_qty,                       --9.納品数量
                        standard_qty,                  --10.基準数量
                        dlv_uom_code,                  --11.納品単位
                        standard_uom_code,             --12.基準単位
                        dlv_unit_price,                --13.納品単価
                        standard_unit_price_excluded,  --14.税抜基準単価
                        standard_unit_price,           --15.基準単価
                        business_cost,                 --16.営業原価
                        sale_amount,                   --17.売上金額
                        pure_amount,                   --18.本体金額
                        tax_amount,                    --19.消費税金額
                        cash_and_card,                 --20.現金・カード併用額
                        ship_from_subinventory_code,   --21.出荷元保管場所
                        delivery_base_code,            --22.納品拠点コード
                        hot_cold_class,                --23.Ｈ＆Ｃ
                        column_no,                     --24.コラムNo
                        sold_out_class,                --25.売切区分
                        sold_out_time,                 --26.売切時間
                        delivery_pattern_class,        --27.納品形態区分
                        to_calculate_fees_flag,        --28.手数料計算インタフェース済フラグ
                        unit_price_mst_flag,           --29.単価マスタ作成済フラグ
                        inv_interface_flag,            --30.INVインタフェース済フラグ
                        created_by,                    --31.作成者
                        creation_date,                 --32.作成日
                        last_updated_by,               --33.最終更新者
                        last_update_date,              --34.最終更新日
                        last_update_login,             --35.最終更新ﾛｸﾞｲﾝ
                        request_id,                    --36.要求ID
                        program_application_id,        --37.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        program_id,                    --38.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        program_update_date )          --39.ﾌﾟﾛｸﾞﾗﾑ更新日
                      VALUES(
                        gt_line_sales_exp_line_id( i ),     --1.販売実績明細ID
                        gt_line_sales_exp_header_id( i ),   --2.販売実績ヘッダID
                        gt_line_dlv_invoice_number( i ),    --3.納品伝票番号
                        gt_line_dlv_invoice_l_num( i ),     --4.納品明細番号
                        gt_line_order_invoice_l_num( i ),   --5.注文明細番号
                        gt_line_sales_class( i ),           --6.売上区分
                        gt_line_red_black_flag( i ),        --7.赤黒フラグ
                        gt_line_item_code( i ),             --8.品目コード
                        gt_line_dlv_qty( i ),               --9.納品数量
                        gt_line_standard_qty( i ),          --10.基準数量
                        gt_line_dlv_uom_code( i ),          --11.納品単位
                        gt_line_standard_uom_code( i ),     --12.基準単位
                        gt_dlv_unit_price( i ),             --13.納品単価
                        gt_line_not_tax_amount( i ),        --14.税抜基準単価
                        gt_line_standard_unit_price( i ),   --15.基準単価
                        gt_line_business_cost( i ),         --16.営業原価
                        gt_line_sale_amount( i ),           --17.売上金額
                        gt_line_pure_amount( i ),           --18.本体金額
                        gt_line_tax_amount( i ),            --19.消費税金額
                        gt_line_cash_and_card( i ),         --20.現金・カード併用額
                        gt_line_ship_from_subinv_co( i ),   --21.出荷元保管場所
                        gt_line_delivery_base_code( i ),    --22.納品拠点コード
                        gt_line_hot_cold_class( i ),        --23.Ｈ＆Ｃ
                        gt_line_column_no( i ),             --24.コラムNo
                        gt_line_sold_out_class( i ),        --25.売切区分
                        gt_line_sold_out_time( i ),         --26.売切時間
                        gt_line_delivery_pat_class( i ),    --27.納品形態区分
                        gt_line_to_calculate_fees_flag( i ), --28.手数料計算インタフェース済フラグ
                        gt_line_unit_price_mst_flag( i ),   --29.単価マスタ作成済フラグ
                        gt_line_inv_interface_flag( i ),    --30.INVインタフェース済フラグ
                        cn_created_by,                      --31.作成者
                        cd_creation_date,                   --32.作成日
                        cn_last_updated_by,                 --33.最終更新者
                        cd_last_update_date,                --34.最終更新日
                        cn_last_update_login,               --35.最終更新ﾛｸﾞｲﾝ
                        cn_request_id,                      --36.要求ID
                        cn_program_application_id,          --37.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        cn_program_id,                      --38.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        cd_program_update_date );           --39.ﾌﾟﾛｸﾞﾗﾑ更新日
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/06/01 N.Maeda Var1.14 MOD START ***************************************
        lv_errbuf  := SQLERRM;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD  END  ***************************************
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_line );
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na, gv_tkn1 );
        RAISE insert_err_expt;
    END;
--
--******************************* 2009/06/01 N.Maeda Var1.14 ADD START ***************************************
      -- 明細データ作成件数セット
      gn_line_cnt := SQL%ROWCOUNT;
--******************************* 2009/06/01 N.Maeda Var1.14 ADD  END  ***************************************
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_data_insert_line;
--
  /**********************************************************************************
   * Procedure Name   : proc_data_insert_head
   * Description      : 販売実績データ登録処理(ヘッダ)(A-4-1)
   ***********************************************************************************/
  PROCEDURE proc_data_insert_head(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2 )     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_insert_head'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --== データ登録 ==--
--******************************* 2009/06/01 N.Maeda Var1.14 MOD START ***************************************
--    -- ヘッダデータ作成件数セット
--    gn_normal_cnt := gt_head_id.COUNT;
--
    BEGIN
--      FORALL i IN 1..gn_normal_cnt
      FORALL i IN 1..gt_head_id.COUNT
--******************************* 2009/06/01 N.Maeda Var1.14 MOD  END  ***************************************
        INSERT INTO xxcos_sales_exp_headers          --販売実績ヘッダテーブル
                      (
                        sales_exp_header_id,           --1.販売実績ヘッダID
                        dlv_invoice_number,            --2.納品伝票番号
                        order_invoice_number,          --3.注文伝票番号
                        order_number,                  --4.受注番号
                        order_no_hht,                  --5.受注No(HHT)
                        digestion_ln_number,           --6.受注No(HHT)枝番
                        order_connection_number,       --7.受注関連番号
                        dlv_invoice_class,             --8.納品伝票区分
                        cancel_correct_class,          --9.取消・訂正区分
                        input_class,                   --10.入力区分
                        cust_gyotai_sho,               --11.業態小分類
                        delivery_date,                 --12.納品日
                        orig_delivery_date,            --13.オリジナル納品日
                        inspect_date,                  --14.検収日
                        orig_inspect_date,             --15.オリジナル検収日
                        ship_to_customer_code,         --16.顧客【納品先】
                        sale_amount_sum,               --17.売上金額合計
                        pure_amount_sum,               --18.本体金額合計
                        tax_amount_sum,                --19.消費税金額合計
                        consumption_tax_class,         --20.消費税区分
                        tax_code,                      --21.税金コード
                        tax_rate,                      --22.消費税率
                        results_employee_code,         --23.成績計上者コード
                        sales_base_code,               --24.売上拠点コード
                        receiv_base_code,              --25.入金拠点コード
                        order_source_id,               --26.受注ソースID
                        card_sale_class,               --27.カード売り区分
                        invoice_class,                 --28.伝票区分
                        invoice_classification_code,   --29.伝票分類コード
                        change_out_time_100,           --30.つり銭切れ時間100円
                        change_out_time_10,            --31.つり銭切れ時間10円
                        ar_interface_flag,             --32.ARインタフェース済フラグ
                        gl_interface_flag,             --33.Gインタフェース済フラグ
                        dwh_interface_flag,            --34.情報システムインタフェース済フラグ
                        edi_interface_flag,            --35.EDI送信済みフラグ
                        edi_send_date,                 --36.EDI送信日時
                        hht_dlv_input_date,            --37.HHT納品入力日時
                        dlv_by_code,                   --38.納品者コード
                        create_class,                  --39.作成元区分
                        business_date,                 --40.登録業務日付
-- ************* Ver.1.28 ADD START *************--
                        total_sales_amt,               --41.総販売金額
                        cash_total_sales_amt,          --42.現金売りトータル販売金額
                        ppcard_total_sales_amt,        --43.PPカードトータル販売金額
                        idcard_total_sales_amt,        --44.IDカードトータル販売金額
                        hht_received_flag,             --45.HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
                        created_by,                    --46.作成者
                        creation_date,                 --47.作成日
                        last_updated_by,               --48.最終更新者
                        last_update_date,              --49.最終更新日
                        last_update_login,             --50.最終更新ﾛｸﾞｲﾝ
                        request_id,                    --51.要求ID
                        program_application_id,        --52.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        program_id,                    --53.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        program_update_date )          --54.ﾌﾟﾛｸﾞﾗﾑ更新日
                      VALUES(
                        gt_head_id( i ),                    --1.販売実績ヘッダID
                        gt_head_hht_invoice_no( i ),        --2.HHT伝票番号
                        gt_head_order_invoice_number( i ),  --3.注文伝票番号
                        gt_head_order_no_ebs( i ),          --4.受注番号
                        gt_head_order_no_hht( i ),          --5.受注No(HHT)
                        gt_head_digestion_ln_number( i ),   --6.受注No(HHT)枝番
                        gt_head_order_connection_num( i ),  --7.受注関連番号
                        gt_head_dlv_invoice_class( i ),     --8.納品伝票区分
                        gt_head_cancel_cor_cls( i ),        --9.取消・訂正区分
                        gt_head_input_class( i ),           --10.入力区分
                        gt_head_system_class( i ),          --11.業態小分類
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
                        gt_head_open_dlv_date( i ),         -- 12.納品日
--                        gt_head_dlv_date( i ),              -- 12.納品日
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
                        gt_head_dlv_date( i ),              --13.オリジナル納品日
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
                        gt_head_open_inspect_date( i ),     -- 14.検収日(売上計上日)
--                        gt_head_inspect_date( i ),          -- 14.検収日(売上計上日)
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
                        gt_head_inspect_date( i ),          --15.オリジナル検収日
                        gt_head_customer_number( i ),       --16.顧客【納品先】
                        gt_head_tax_include( i ),           --17.売上金額合計
                        gt_head_total_amount( i ),          --18.本体金額合計
                        gt_head_sales_consump_tax( i ),     --19.消費税金額合計
                        gt_head_consump_tax_class( i ),     --20.消費税区分
                        gt_head_tax_code( i ),              --21.税金コード
                        gt_head_tax_rate( i ),              --22.消費税率
                        gt_head_performance_by_code( i ),   --23.成績計上者コード
                        gt_head_sales_base_code( i ),       --24.売上拠点コード
                        gt_head_receiv_base_code( i ),      --25.入金拠点コード
                        gt_head_order_source_id( i ),       --26.受注ソースID
                        gt_head_card_sale_class( i ),       --27.カード売り区分
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
                        gt_head_sales_classification( i ),  --28.伝票区分
                        gt_head_invoice_class( i ),         --29.伝票分類コード
--                        gt_head_invoice_class( i ),         --28.売上伝票区分(伝票分類コード)
--                        gt_head_sales_classification( i ),  --29.売上分類区分(伝票区分)
--************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
                        gt_head_change_out_time_100( i ),   --30.つり銭切れ時間100円
                        gt_head_change_out_time_10( i ),    --31.つり銭切れ時間10円
                        gt_head_ar_interface_flag( i ),     --32.ARインタフェース済フラグ
                        gt_head_gl_interface_flag( i ),     --33.GLインタフェース済フラグ
                        gt_head_dwh_interface_flag( i ),    --34.情報システムインタフェース済フラグ
                        gt_head_edi_interface_flag( i ),    --35.EDI送信済みフラグ
                        gt_head_edi_send_date( i ),         --36.EDI送信日時
                        gt_head_hht_dlv_input_date( i ),    --37.HHT納品入力日時
                        gt_head_dlv_by_code( i ),           --38.納品者コード
                        gt_head_create_class( i ),          --39.作成元区分
                        gt_head_business_date( i ),         --40.登録業務日付
-- ************* Ver.1.28 ADD START *************--
                        gt_head_ttl_sales_amt( i ),         --41.総販売金額
                        gt_head_cs_ttl_sales_amt( i ),      --42.現金売りトータル販売金額
                        gt_head_pp_ttl_sales_amt( i ),      --43.PPカードトータル販売金額
                        gt_head_id_ttl_sales_amt( i ),      --44.IDカードトータル販売金額
                        gt_head_hht_received_flag( i ),     --45.HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
                        cn_created_by,                 --46.作成者
                        cd_creation_date,              --47.作成日
                        cn_last_updated_by,            --48.最終更新者
                        cd_last_update_date,           --49.最終更新日
                        cn_last_update_login,          --50.最終更新ﾛｸﾞｲﾝ
                        cn_request_id,                 --51.要求ID
                        cn_program_application_id,     --52.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        cn_program_id,                 --53.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        cd_program_update_date );      --54.ﾌﾟﾛｸﾞﾗﾑ更新日
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/06/01 N.Maeda Var1.14 MOD START ***************************************
        lv_errbuf  := SQLERRM;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD  END  ***************************************
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head);
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na,gv_tkn1 );
        RAISE insert_err_expt;
    END;
--
--******************************* 2009/06/01 N.Maeda Var1.14 ADD START ***************************************
      -- 明細データ作成件数セット
      gn_normal_cnt := SQL%ROWCOUNT;
--******************************* 2009/06/01 N.Maeda Var1.14 ADD  END  ***************************************
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_data_insert_head;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded
   * Description      : VD納品データ作成成型処理(A-3)
   ***********************************************************************************/
  PROCEDURE proc_molded(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  --==================
  -- ユーザー定義変数
  --==================
--
  --ヘッダ情報格納変数
  lt_order_no_hht                 xxcos_vd_column_headers.order_no_hht%TYPE;           --受注No.(HHT)
  lt_digestion_ln_number          xxcos_vd_column_headers.digestion_ln_number%TYPE;    --枝番
  lt_order_no_ebs                 xxcos_vd_column_headers.order_no_ebs%TYPE;           --受注No.(EBS)
  lt_base_code                    xxcos_vd_column_headers.base_code%TYPE;              --拠点コード
  lt_performance_by_code          xxcos_vd_column_headers.performance_by_code%TYPE;    --成績者コード
  lt_dlv_by_code                  xxcos_vd_column_headers.dlv_by_code%TYPE;            --納品者コード
  lt_hht_invoice_no               xxcos_vd_column_headers.hht_invoice_no%TYPE;         --HHT伝票No.
  lt_dlv_date                     xxcos_vd_column_headers.dlv_date%TYPE;               --納品日
  lt_inspect_date                 xxcos_vd_column_headers.inspect_date%TYPE;           --検収日
  lt_sales_classification         xxcos_vd_column_headers.sales_classification%TYPE;   --売上分類区分
  lt_sales_invoice                xxcos_vd_column_headers.sales_invoice%TYPE;          --売上伝票区分
  lt_card_sale_class              xxcos_vd_column_headers.card_sale_class%TYPE;        --カード売区分
  lt_dlv_time                     xxcos_vd_column_headers.dlv_time%TYPE;               --時間
  lt_change_out_time_100          xxcos_vd_column_headers.change_out_time_100%TYPE;    --つり銭切れ時間100円
  lt_change_out_time_10           xxcos_vd_column_headers.change_out_time_10%TYPE;     --つり銭切れ時間10円
  lt_customer_number              xxcos_vd_column_headers.customer_number%TYPE;        --顧客コード
  lt_dlv_form                     xxcos_vd_column_headers.dlv_form%TYPE;               --納品形態
  lt_system_class                 xxcos_vd_column_headers.system_class%TYPE;           --業態区分
  lt_invoice_type                 xxcos_vd_column_headers.invoice_type%TYPE;           --伝票区分
  lt_input_class                  xxcos_vd_column_headers.input_class%TYPE;            --入力区分
  lt_consumption_tax_class        xxcos_vd_column_headers.consumption_tax_class%TYPE;  --消費税区分
  lt_total_amount                 xxcos_vd_column_headers.total_amount%TYPE;           --合計金額
  lt_sale_discount_amount         xxcos_vd_column_headers.sale_discount_amount%TYPE;   --売上値引額
  lt_sales_consumption_tax        xxcos_vd_column_headers.sales_consumption_tax%TYPE;  --売上消費税額
  lt_tax_include                  xxcos_vd_column_headers.tax_include%TYPE;            --税込金額
  lt_keep_in_code                 xxcos_vd_column_headers.keep_in_code%TYPE;           --預け先コード
  lt_department_screen_class      xxcos_vd_column_headers.department_screen_class%TYPE; --百貨店画面種別
  lt_digestion_rate_maked_date xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE; --消化VD掛率作成済年月日
  lt_red_black_flag               xxcos_vd_column_headers.red_black_flag%TYPE;         --赤黒フラグ
  lt_cancel_correct_class         xxcos_vd_column_headers.cancel_correct_class%TYPE;    --取消・訂正区分
  lt_sale_amount_sum              xxcos_sales_exp_headers.sale_amount_sum%TYPE;        -- 売上金額合計
  lt_pure_amount_sum              xxcos_sales_exp_headers.pure_amount_sum%TYPE;        -- 本体金額合計
  lt_tax_amount_sum               xxcos_sales_exp_headers.tax_amount_sum%TYPE;         -- 消費税金額合計
-- ************** 2009/04/16 1.10 N.Maeda ADD START ****************************************************************
  lt_cash_receiv_base_code        xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;   -- 入金拠点コード
-- ************** 2009/04/16 1.10 N.Maeda ADD  END  ****************************************************************
-- ************* Ver.1.28 ADD START *************--
  lt_ttl_sales_amt                xxcos_vd_column_headers.total_sales_amt%TYPE;        -- 総販売金額
  lt_cs_ttl_sales_amt             xxcos_vd_column_headers.cash_total_sales_amt%TYPE;   -- 現金売りトータル販売金額
  lt_pp_ttl_sales_amt             xxcos_vd_column_headers.ppcard_total_sales_amt%TYPE; -- PPカードトータル販売金額
  lt_id_ttl_sales_amt             xxcos_vd_column_headers.idcard_total_sales_amt%TYPE; -- IDカードトータル販売金額
  lt_hht_received_flag            xxcos_vd_column_headers.hht_received_flag%TYPE;      -- HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
--
  --明細情報格納変数
  lt_lin_order_no_hht             xxcos_vd_column_lines.order_no_hht%TYPE;             --受注No.(HHT)
  lt_lin_line_no_hht              xxcos_vd_column_lines.line_no_hht%TYPE;              --行No.(HHT)
  lt_lin_digestion_ln_number      xxcos_vd_column_lines.digestion_ln_number%TYPE;      --枝番
  lt_lin_order_no_ebs             xxcos_vd_column_lines.order_no_ebs%TYPE;             --受注No.(EBS)
  lt_lin_line_number_ebs          xxcos_vd_column_lines.line_number_ebs%TYPE;          --明細番号(EBS)
  lt_lin_item_code_self           xxcos_vd_column_lines.item_code_self%TYPE;           --品名コード(自社)
  lt_lin_content                  xxcos_vd_column_lines.content%TYPE;                  --入数
  lt_lin_inventory_item_id        xxcos_vd_column_lines.inventory_item_id%TYPE;        --品目ID
  lt_lin_standard_unit            xxcos_vd_column_lines.standard_unit%TYPE;            --基準単位
  lt_lin_case_number              xxcos_vd_column_lines.case_number%TYPE;              --ケース数
  lt_lin_quantity                 xxcos_vd_column_lines.quantity%TYPE;                 --数量
  lt_lin_sale_class               xxcos_vd_column_lines.sale_class%TYPE;               --売上区分
  lt_lin_wholesale_unit_ploce     xxcos_vd_column_lines.wholesale_unit_ploce%TYPE;     --卸単価
  lt_lin_selling_price            xxcos_vd_column_lines.selling_price%TYPE;            --売単価
  lt_lin_column_no                xxcos_vd_column_lines.column_no%TYPE;                --コラムNo
  lt_lin_h_and_c                  xxcos_vd_column_lines.h_and_c%TYPE;                  --H/C
  lt_lin_sold_out_class           xxcos_vd_column_lines.sold_out_class%TYPE;           --売切区分
  lt_lin_sold_out_time            xxcos_vd_column_lines.sold_out_time%TYPE;            --売切時間
  lt_lin_replenish_number         xxcos_vd_column_lines.replenish_number%TYPE;         --補充数
  lt_lin_cash_and_card            xxcos_vd_column_lines.cash_and_card%TYPE;            --現金・カード併用額
  --
  lt_sale_base_code               xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_tax_odd                      xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;
  lt_secondary_inventory_name     mtl_secondary_inventories.secondary_inventory_name%TYPE;
  lt_stand_unit                   mtl_system_items_b.primary_unit_of_measure%TYPE;
  lt_consum_code                  fnd_lookup_values.attribute2%TYPE;
  lt_consum_type                  fnd_lookup_values.attribute3%TYPE;
  lt_ins_invoice_type             fnd_lookup_values.attribute4%TYPE;
  lt_location_type_code           fnd_lookup_values.meaning%TYPE;
  lt_depart_location_type_code    fnd_lookup_values.meaning%TYPE;
--  lt_ins_line_invoice_type        fnd_lookup_values.attribute4%TYPE;
--  lt_lin_standard_amount          xxcos_vd_column_lines.standard_unit%TYPE;            --基準単価変数格納用
--  lt_lin_not_tax_amount           xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --税抜基準単価
--  ln_tax_amount                   xxcos_sales_exp_lines.tax_amount%TYPE;
  lt_tax_consum                   ar_vat_tax_all_b.tax_rate%TYPE;
  lt_dlv_base_code                xxcos_rs_info_v.base_code%TYPE;
  lt_sales_cost                   ic_item_mst_b.attribute7%TYPE;
  lv_depart_code                  xxcmm_cust_accounts.dept_hht_div%TYPE;
  lt_old_sales_cost               ic_item_mst_b.attribute7%TYPE;
  lt_new_sales_cost               ic_item_mst_b.attribute8%TYPE;
  lt_st_sales_cost                ic_item_mst_b.attribute9%TYPE;
  lt_stand_unit_price_excl        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--税抜基準単価
  lt_standard_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE;    -- 基準単価
  lt_sale_amount                  xxcos_sales_exp_lines.sale_amount%TYPE;            -- 売上金額
  lt_pure_amount                  xxcos_sales_exp_lines.pure_amount%TYPE;            -- 本体金額
  lt_tax_amount                   xxcos_sales_exp_lines.tax_amount%TYPE;             -- 消費税金額
  --
  lt_set_replenish_number         xxcos_sales_exp_lines.standard_qty%TYPE;           -- 登録用基準数量(納品数量)
  lt_set_sale_amount              xxcos_sales_exp_lines.sale_amount%TYPE;            -- 登録用売上金額
  lt_set_pure_amount              xxcos_sales_exp_lines.pure_amount%TYPE;            -- 登録用本体金額
  lt_set_tax_amount               xxcos_sales_exp_lines.tax_amount%TYPE;             -- 登録用消費税金額
  lt_set_sale_amount_sum          xxcos_sales_exp_headers.sale_amount_sum%TYPE;      -- 登録用売上金額合計
  lt_set_pure_amount_sum          xxcos_sales_exp_headers.pure_amount_sum%TYPE;      -- 登録用本体金額合計
  lt_set_tax_amount_sum           xxcos_sales_exp_headers.tax_amount_sum%TYPE;       -- 登録用消費税金額合計
--  lt_lin_sale_amount              NUMBER;                                            -- 売上金額
  ln_actual_id                    NUMBER;                                            -- 販売実績ヘッダID
  ln_sales_exp_line_id            NUMBER;                                            -- 明細ID
--  ln_tax_Odd                      NUMBER;
--  ln_up_odd                       NUMBER;
--************************** 2009/03/18 1.6 T.kitajima ADD START ************************************
  ln_amount                       NUMBER;                                            -- 作業用金額変数1
--************************** 2009/03/18 1.6 T.kitajima ADD  END  ************************************
--************************** 2009/03/23 1.7 N.Maeda    ADD START ************************************
  ln_sal_amount_data              NUMBER;                                            -- 作業用金額変数2
--************************** 2009/03/23 1.7 N.Maeda    ADD  END  ************************************
  ln_header_ck_no                 NUMBER  :=  1;                                     -- ヘッダチェック済番号
  ln_line_cnt                     NUMBER  :=  1;                                     -- 明細チェック済番号
  ln_all_tax_amount               NUMBER  :=  0;                                     -- 消費税金額合計値
  ln_max_tax_data                 NUMBER  :=  0;                                     -- 明細最大消費税額
  ln_max_no_data                  NUMBER;                                            -- ヘッダ最大消費税明細行番号
  ln_tax_data                     NUMBER;
  lv_delivery_type                VARCHAR2(500);                                     -- 納品形態区分
  lv_key_name1                    VARCHAR2(500);
  lv_key_name2                    VARCHAR2(500);
  lv_key_data1                    VARCHAR2(500);
  lv_key_data2                    VARCHAR2(500);
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
  lt_row_id                       ROWID;                                           -- 更新用行ID
  lv_state_flg                    VARCHAR2(1);                                     -- データ警告確認フラグ
  ln_line_data_count              NUMBER;                                          -- 明細件数(ヘッダ単位)
  lv_dept_hht_div_flg             VARCHAR2(1);                                     -- HHT百貨店区分エラーフラグ
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
--
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
  ln_line_pure_amount_sum         NUMBER;                                          -- 明細本体金額合計
  lt_open_dlv_date                xxcos_dlv_headers.dlv_date%TYPE;                 -- オープン済み納品日
  lt_open_inspect_date            xxcos_dlv_headers.inspect_date%TYPE;             -- オープン済み検収日
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
--
--******************** 2009/05/12 Var1.12  N.Maeda ADD START ******************************************
  lt_max_cancel_correct_class     xxcos_vd_column_headers.cancel_correct_class%TYPE;    -- 最新取消・訂正区分
  lt_min_digestion_ln_number      xxcos_vd_column_headers.digestion_ln_number%TYPE;     -- 枝番最小値
  ln_sales_exp_count              NUMBER :=0 ;                                          -- 更新対象販売実績件数カウント
  ln_set_sales_exp_count          NUMBER :=0 ;                                          -- 更新販売実績件数カウント
--
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
  lt_mon_sale_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_past_sale_base_code               xxcmm_cust_accounts.past_sale_base_code%TYPE;
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
-- ************* 2013/10/18 1.26 K.Nakamura ADD START *************--
  ld_tax_date                     DATE; -- 消費税取得基準日
-- ************* 2013/10/18 1.26 K.Nakamura ADD  END  *************--
    -- *** ローカル・カーソル ***
  CURSOR get_sales_exp_cur
    IS
      SELECT xseh.ROWID
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.order_no_hht = lt_order_no_hht
  FOR UPDATE NOWAIT;
--******************** 2009/05/12 Var1.12  N.Maeda ADD START ******************************************
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- ループ開始：ヘッダ部
    <<header_loop>>
    FOR ck_no IN 1..gn_target_cnt LOOP
--
-- ************* 2013/10/18 1.26 K.Nakamura ADD START *************--
      -- 消費税取得基準日の初期化
      ld_tax_date                     := NULL;
-- ************* 2013/10/18 1.26 K.Nakamura ADD  END  *************--
      --積上消費税の初期化
      ln_all_tax_amount               := 0;
      --最大消費税額の初期化
      ln_max_tax_data                 := 0;
      -- 最大明細番号
      ln_max_no_data                  := 0;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
      -- 明細本体金額合計
      ln_line_pure_amount_sum         := 0;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
      -- 明細件数カウント(初期化)
      ln_line_data_count              := 0;
      -- データ警告確認フラグ(初期化)
      lv_state_flg                    := cv_status_normal;
      -- HHT百貨店区分エラー(初期化)
      lv_dept_hht_div_flg             := cv_status_normal;
      --ヘッダ項目の代入
      lt_row_id                       := gt_vd_c_headers_data( ck_no ).row_id;            -- 行ID
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
      lt_order_no_hht                 := gt_vd_c_headers_data(ck_no).order_no_hht;           --受注No.(HHT)
      lt_digestion_ln_number          := gt_vd_c_headers_data(ck_no).digestion_ln_number;    --枝番
      lt_order_no_ebs                 := gt_vd_c_headers_data(ck_no).order_no_ebs;           --受注No.(EBS)
      lt_base_code                    := gt_vd_c_headers_data(ck_no).base_code;              --拠点コード
      lt_performance_by_code          := gt_vd_c_headers_data(ck_no).performance_by_code;    --成績者コード
      lt_dlv_by_code                  := gt_vd_c_headers_data(ck_no).dlv_by_code;            --納品者コード
      lt_hht_invoice_no               := gt_vd_c_headers_data(ck_no).hht_invoice_no;         --HHT伝票No.
      lt_dlv_date                     := gt_vd_c_headers_data(ck_no).dlv_date;               --納品日
      lt_inspect_date                 := gt_vd_c_headers_data(ck_no).inspect_date;           --検収日
      lt_sales_classification         := gt_vd_c_headers_data(ck_no).sales_classification;   --売上分類区分
      lt_sales_invoice                := gt_vd_c_headers_data(ck_no).sales_invoice;          --売上伝票区分
      lt_card_sale_class              := gt_vd_c_headers_data(ck_no).card_sale_class;        --カード売区分
      lt_dlv_time                     := gt_vd_c_headers_data(ck_no).dlv_time;               --時間
      lt_change_out_time_100          := gt_vd_c_headers_data(ck_no).change_out_time_100;    --つり銭切れ時間100円
      lt_change_out_time_10           := gt_vd_c_headers_data(ck_no).change_out_time_10;     --つり銭切れ時間10円
      lt_customer_number              := gt_vd_c_headers_data(ck_no).customer_number;        --顧客コード
      lt_dlv_form                     := gt_vd_c_headers_data(ck_no).dlv_form;               --納品形態
      lt_system_class                 := gt_vd_c_headers_data(ck_no).system_class;           --業態区分
      lt_invoice_type                 := gt_vd_c_headers_data(ck_no).invoice_type;           --伝票区分
      lt_input_class                  := gt_vd_c_headers_data(ck_no).input_class;            --入力区分
      lt_consumption_tax_class        := gt_vd_c_headers_data(ck_no).consumption_tax_class;  --消費税区分
      lt_total_amount                 := gt_vd_c_headers_data(ck_no).total_amount;           --合計金額
      lt_sale_discount_amount         := gt_vd_c_headers_data(ck_no).sale_discount_amount;   --売上値引額
      lt_sales_consumption_tax        := gt_vd_c_headers_data(ck_no).sales_consumption_tax;  --売上消費税額
      lt_tax_include                  := gt_vd_c_headers_data(ck_no).tax_include;            --税込金額
      lt_keep_in_code                 := gt_vd_c_headers_data(ck_no).keep_in_code;           --預け先コード
      lt_department_screen_class      := gt_vd_c_headers_data(ck_no).department_screen_class; --百貨店画面種別
      lt_digestion_rate_maked_date    := gt_vd_c_headers_data(ck_no).digestion_vd_rate_maked_date; --消化VD掛率作成済年月日
      lt_red_black_flag               := gt_vd_c_headers_data(ck_no).red_black_flag;         --赤黒フラグ
      lt_cancel_correct_class         := gt_vd_c_headers_data(ck_no).cancel_correct_class;   --取消・訂正区分
-- ************* Ver.1.28 ADD START *************--
      lt_ttl_sales_amt                := gt_vd_c_headers_data(ck_no).ttl_sales_amt;          --総販売金額
      lt_cs_ttl_sales_amt             := gt_vd_c_headers_data(ck_no).cs_ttl_sales_amt;       --現金売りトータル販売金額
      lt_pp_ttl_sales_amt             := gt_vd_c_headers_data(ck_no).pp_ttl_sales_amt;       --PPカードトータル販売金額
      lt_id_ttl_sales_amt             := gt_vd_c_headers_data(ck_no).id_ttl_sales_amt;       --IDカードトータル販売金額
      lt_hht_received_flag            := gt_vd_c_headers_data(ck_no).hht_received_flag;      --HHT受信フラグ
-- ************* Ver.1.28 ADD END   *************--
--
-- ****************** 2009/09/03 1.18 N.Maeda ADD START ************** --
      --==================================
      -- 1.納品日算出
      --==================================
      get_fiscal_period_from(
-- ************************************* 2010/02/01 1.20 M.Hokkanji MOD START ************************************
--          iv_div        => cv_fiscal_period_ar                  -- 会計区分
          iv_div        => cv_fiscal_period_inv                 -- 会計区分
-- ************************************* 2010/02/01 1.20 M.Hokkanji MOD END   ************************************
        , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
        , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
        , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
        , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
        , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        lv_state_flg    := cv_status_warn;
        gn_wae_data_num := gn_wae_data_num + 1 ;
-- == 2010/09/09 V1.22 Modified START ===============================================================
--        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                              iv_application   => cv_application,    --アプリケーション短縮名
--                                              iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                              iv_token_name1   => cv_tkn_account_name,         --トークンコード1
---- ************************************* 2010/02/01 1.20 M.Hokkanji MOD START *************************************
----                                              iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                              iv_token_value1  => cv_fiscal_period_tkn_inv,        --トークン値(INV)
---- ************************************* 2010/02/01 1.20 M.Hokkanji MOD END   *************************************
--                                              iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                              iv_token_value2  => lt_order_no_hht,
--                                              iv_token_name3   => cv_tkn_base_date,
--                                              iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application    =>  cv_application                          --  アプリケーション短縮名
                                              , iv_name           =>  cv_msg_xxcos_00217                      --  メッセージコード
                                              , iv_token_name1    =>  cv_tkn_account_name
                                              , iv_token_value1   =>  cv_fiscal_period_tkn_inv                --  INV
                                              , iv_token_name2    =>  cv_tkn_order_number
                                              , iv_token_value2   =>  lt_order_no_hht                         --  受注No.(HHT)
                                              , iv_token_name3    =>  cv_tkn_base_date
                                              , iv_token_value3   =>  TO_CHAR( lt_dlv_date, cv_stand_date )   --  納品日
                                              , iv_token_name4    =>  cv_tkn_invoice_no
                                              , iv_token_value4   =>  lt_hht_invoice_no                       --  HHT伝票No.
                                              , iv_token_name5    =>  cv_cust_code
                                              , iv_token_value5   =>  lt_customer_number                      --  顧客コード
                                            );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
      END IF;
--
--
      --==================================
      -- 2.売上計上日算出
      --==================================
      get_fiscal_period_from(
-- ************************************* 2010/02/01 1.20 M.Hokkanji MOD START ************************************
--          iv_div        => cv_fiscal_period_ar                  -- 会計区分
          iv_div        => cv_fiscal_period_inv                 -- 会計区分
-- ************************************* 2010/02/01 1.20 M.Hokkanji MOD END   ************************************
        , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
        , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
        , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
        , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
        , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        lv_state_flg    := cv_status_warn;
        gn_wae_data_num := gn_wae_data_num + 1 ;
-- == 2010/09/09 V1.22 Modified START ===============================================================
--        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                              iv_application   => cv_application,    --アプリケーション短縮名
--                                              iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                              iv_token_name1   => cv_tkn_account_name,         --トークンコード1
---- ************************************* 2010/02/01 1.20 M.Hokkanji MOD START *************************************
----                                              iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                              iv_token_value1  => cv_fiscal_period_tkn_inv,      --トークン値(INV)
---- ************************************* 2010/02/01 1.20 M.Hokkanji MOD END   *************************************
--                                              iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                              iv_token_value2  => lt_order_no_hht,
--                                              iv_token_name3   => cv_tkn_base_date,
--                                              iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application    =>  cv_application                              --  アプリケーション短縮名
                                              , iv_name           =>  cv_msg_xxcos_00217                          --  メッセージコード
                                              , iv_token_name1    =>  cv_tkn_account_name
                                              , iv_token_value1   =>  cv_fiscal_period_tkn_inv                    --  INV
                                              , iv_token_name2    =>  cv_tkn_order_number
                                              , iv_token_value2   =>  lt_order_no_hht                             --  受注No.(HHT)
                                              , iv_token_name3    =>  cv_tkn_base_date
                                              , iv_token_value3   =>  TO_CHAR( lt_inspect_date, cv_stand_date )   --  納品日
                                              , iv_token_name4    =>  cv_tkn_invoice_no
                                              , iv_token_value4   =>  lt_hht_invoice_no                           --  HHT伝票No.
                                              , iv_token_name5    =>  cv_cust_code
                                              , iv_token_value5   =>  lt_customer_number                          --  顧客コード
                                            );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
-- == 2010/09/09 V1.22 Added START ===============================================================
        IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
          --  汎用エラーリスト出力要の場合
          gn_msg_cnt  :=  gn_msg_cnt + 1;
          --  汎用エラーリスト用キー情報
          --  納品拠点
          gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_base_code;
          --  エラーメッセージ名
          gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_msg_xxcos_00217;
          --  キーメッセージ
          gt_err_key_msg_tab(gn_msg_cnt).message_text
                          :=  SUBSTRB(
                                xxccp_common_pkg.get_msg(
                                    iv_application    =>  cv_application
                                  , iv_name           =>  cv_msg_xxcos_00216
                                  , iv_token_name1    =>  cv_tkn_order_number
                                  , iv_token_value1   =>  lt_order_no_hht                             --  受注No.(HHT)
                                  , iv_token_name2    =>  cv_tkn_base_date
                                  , iv_token_value2   =>  TO_CHAR( lt_inspect_date, cv_stand_date )   --  納品日
                                  , iv_token_name3    =>  cv_tkn_invoice_no
                                  , iv_token_value3   =>  lt_hht_invoice_no                           --  HHT伝票No.
                                  , iv_token_name4    =>  cv_cust_code
                                  , iv_token_value4   =>  lt_customer_number                          --  顧客コード
                                ), 1, 2000
                              );
        END IF;
-- == 2010/09/09 V1.22 Added END   ===============================================================
      END IF;
-- ****************** 2009/09/03 1.18 N.Maeda ADD  END  ************** --
--
--******************************* 2009/04/16 N.Maeda Var1.10 DEL START ***************************************
--      --================================
--      --販売実績ヘッダID(シーケンス取得)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.10 DEL END *****************************************
      --=========================
      --顧客マスタ付帯情報の導出
      --=========================
      BEGIN
-- ************** 2009/07/31 1.15 N.Maeda MOD START ****************************************************************
--
        SELECT  /*+ leading(xch) */
                xca.sale_base_code         sale_base_code        -- 売上拠点コード
                ,xch.cash_receiv_base_code cash_receiv_base_code -- 入金拠点コード
                ,xch.bill_tax_round_rule   bill_tax_round_rule   -- 税金-端数処理(サイト)
-- ************* 2009/08/21 1.17 N.Maeda MOD START *************--
                ,xca.past_sale_base_code   past_sale_base_code
--        INTO    lt_sale_base_code
        INTO    lt_mon_sale_base_code
-- ************* 2009/08/21 1.17 N.Maeda MOD  END  *************--
                ,lt_cash_receiv_base_code
                ,lt_tax_odd
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
                ,lt_past_sale_base_code
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
        FROM    hz_cust_accounts       hca    -- 顧客マスタ
                ,xxcmm_cust_accounts    xca   -- 顧客追加情報
                ,xxcos_cust_hierarchy_v xch   -- 顧客階層ビュー
                ,hz_parties             hpt   -- パーティーマスタ
        WHERE   hca.cust_account_id     =  xca.customer_id
        AND     xch.ship_account_number =  xca.customer_code
        AND     hca.account_number      =  lt_customer_number
        AND     hca.party_id            =  hpt.party_id
        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
        AND     hpt.duns_number_c       IN ( cv_cust_s , cv_cust_v , cv_cost_p );
--
-- ************* 2009/08/21 1.17 N.Maeda ADD START *************--
        IF ( TO_CHAR( gd_process_date , cv_month_type ) = TO_CHAR( lt_dlv_date , cv_month_type  ) ) THEN  -- 同一月の場合当月売上拠点
          lt_sale_base_code := lt_mon_sale_base_code;
        ELSE                                                                        -- その他前月売上拠点
          IF ( lt_past_sale_base_code IS NULL ) THEN
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,            --アプリケーション短縮名
                                                iv_name          => cv_past_sale_base_get_err, --メッセージコード
                                                iv_token_name1   => cv_cust_code,              --トークン(顧客コード)
                                                iv_token_value1  => lt_customer_number,        --トークン値1
                                                iv_token_name2   => cv_dlv_date,               --トークンコード2(納品日)
                                                iv_token_value2  => TO_CHAR( lt_dlv_date,cv_short_day ) );         --トークン値2
          ELSE
            lt_sale_base_code := lt_past_sale_base_code;
          END IF;
        END IF;
-- ************* 2009/08/21 1.17 N.Maeda ADD  END  *************--
--
--        SELECT  xca.sale_base_code, --売上拠点コード
---- ************** 2009/04/16 1.10 N.Maeda ADD START ****************************************************************
--                xch.cash_receiv_base_code,  --入金拠点コード
---- ************** 2009/04/16 1.10 N.Maeda ADD  END  ****************************************************************
--                xch.bill_tax_round_rule -- 税金-端数処理(サイト)
--        INTO    lt_sale_base_code,
---- ************** 2009/04/16 1.10 N.Maeda ADD START ****************************************************************
--                lt_cash_receiv_base_code,
---- ************** 2009/04/16 1.10 N.Maeda ADD  END  ****************************************************************
--                lt_tax_odd
--        FROM    hz_cust_accounts hca,      -- 顧客マスタ
--                xxcmm_cust_accounts xca,   -- 顧客追加情報
--                xxcos_cust_hierarchy_v xch -- 顧客階層ビュー
--        WHERE   hca.cust_account_id = xca.customer_id
---- ************** 2009/07/24 1.15 N.Maeda MOD START ****************************************************************
----        AND     xch.ship_account_id = hca.cust_account_id
----        AND     xch.ship_account_id = xca.customer_id
--        AND     xch.ship_account_number = xca.customer_code
---- ************** 2009/07/24 1.15 N.Maeda ADD  END  ****************************************************************
--        AND     hca.account_number = TO_CHAR( lt_customer_number )
--        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
--        AND     hca.party_id IN ( SELECT  hpt.party_id
--                                  FROM    hz_parties hpt
--                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
-- ************** 2009/07/31 1.15 N.Maeda MOD  END  ****************************************************************
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --キー編集処理
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_customer_number;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- 項目名称１
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- 項目名称２
            iv_data_value1 => (cv_customer_type_c||cv_con_char||cv_customer_type_u),         -- データの値１
            iv_data_value2 => lt_customer_number,   -- データの値２
            ov_key_info    => gv_tkn2,              -- キー情報
            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
            ov_retcode     => lv_retcode,           -- リターン・コード
            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table, --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
      END;
--
-- ****************** 2009/09/03 1.18 N.Maeda DEL START ************** --
--      --========================
--      --消費税コードの導出
--      --========================
--      BEGIN
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD START ***************************************
--        SELECT  look_val.attribute2,  --消費税コード
--                look_val.attribute3   --販売実績連携時の消費税区分
--        INTO    lt_consum_code,
--                lt_consum_type
--        FROM    fnd_lookup_values     look_val
--        WHERE   look_val.language = ct_user_lang
--        AND     gd_process_date      >= look_val.start_date_active
--        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--        AND     look_val.enabled_flag = cv_tkn_yes
--        AND     look_val.lookup_type = cv_lookup_type
--        AND     look_val.lookup_code = lt_consumption_tax_class;
----
----        SELECT  look_val.attribute2,  --消費税コード
----                look_val.attribute3   --販売実績連携時の消費税区分
----        INTO    lt_consum_code,
----                lt_consum_type
----        FROM    fnd_lookup_values     look_val,  --クイックコード
----                fnd_lookup_types_tl   types_tl,  --
----                fnd_lookup_types      types,     --
----                fnd_application_tl    appl,      --
----                fnd_application       app        --
----        WHERE   appl.application_id   = types.application_id
----        AND     app.application_id    = appl.application_id
----        AND     types_tl.lookup_type  = look_val.lookup_type
----        AND     types.lookup_type     = types_tl.lookup_type
----        AND     types.security_group_id   = types_tl.security_group_id
----        AND     types.view_application_id = types_tl.view_application_id
----        AND     types_tl.language = USERENV( 'LANG' )
----        AND     look_val.language = USERENV( 'LANG' )
----        AND     appl.language     = USERENV( 'LANG' )
----        AND     app.application_short_name = cv_application
----        AND     gd_process_date      >= look_val.start_date_active
----        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
----        AND     look_val.enabled_flag = cv_tkn_yes
----        AND     look_val.lookup_type = cv_lookup_type
----        AND     look_val.lookup_code = lt_consumption_tax_class;
----******************************* 2009/08/12 N.Maeda Ver1.16 MOD END *****************************************
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- ログ出力
--          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
--          --キー編集処理
----******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
----          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
----          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
----          lv_key_data1 := lt_consumption_tax_class;
----          lv_key_data2 := cv_lookup_type;
----          RAISE no_data_extract;
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          xxcos_common_pkg.makeup_key_info(
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称１
--            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- 項目名称２
--            iv_data_value1 => lt_consumption_tax_class,         -- データの値１
--            iv_data_value2 => cv_lookup_type,   -- データの値２
--            ov_key_info    => gv_tkn2,              -- キー情報
--            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--            ov_retcode     => lv_retcode,           -- リターン・コード
--            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --アプリケーション短縮名
--                                                iv_name          => cv_msg_no_data,    --メッセージコード
--                                                iv_token_name1   => cv_tkn_table, --トークンコード1
--                                                iv_token_value1  => gv_tkn1,           --トークン値1
--                                                iv_token_name2   => cv_key_data,       --トークンコード2
--                                                iv_token_value2  => gv_tkn2 );         --トークン値2
----******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
--      END;
-- ****************** 2009/09/03 1.18 N.Maeda DEL  END  ************** --
--
      --====================
      --消費税マスタ情報取得
      --====================
-- ************* 2013/10/18 1.26 K.Nakamura ADD START *************--
      -- 内税（伝票課税）の場合
      IF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
        -- 納品日
-- ************* 2014/01/29 1.27 K.Nakamura ADD START *************--
--        ld_tax_date := lt_open_dlv_date;
        ld_tax_date := lt_dlv_date;
-- ************* 2014/01/29 1.27 K.Nakamura ADD END   *************--
      ELSE
        -- 検収日
-- ************* 2014/01/29 1.27 K.Nakamura ADD START *************--
--        ld_tax_date := lt_open_inspect_date;
        ld_tax_date := lt_inspect_date;
-- ************* 2014/01/29 1.27 K.Nakamura ADD END   *************--
      END IF;
-- ************* 2013/10/18 1.26 K.Nakamura ADD  END  *************--
      BEGIN
-- ****************** 2009/09/03 1.18 N.Maeda MOD START ************** --
        SELECT  xtv.tax_rate             -- 消費税率
               ,xtv.tax_class                -- 販売実績連携消費税区分
               ,xtv.tax_code             -- 税金コード
        INTO    lt_tax_consum
               ,lt_consum_type
               ,lt_consum_code
        FROM   xxcos_tax_v   xtv         -- 消費税view
        WHERE  xtv.hht_tax_class    = lt_consumption_tax_class
        AND    xtv.set_of_books_id  = TO_NUMBER( gv_bks_id )
-- ************* 2013/10/18 1.26 K.Nakamura MOD START *************--
--        AND    NVL( xtv.start_date_active, lt_open_inspect_date )  <= lt_open_inspect_date
--        AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_open_inspect_date;
        AND    NVL( xtv.start_date_active, ld_tax_date ) <= ld_tax_date
        AND    NVL( xtv.end_date_active, gd_max_date )   >= ld_tax_date;
-- ************* 2013/10/18 1.26 K.Nakamura MOD  END  *************--
--
--        SELECT avtab.tax_rate           -- 消費税率
--        INTO   lt_tax_consum 
--        FROM   ar_vat_tax_all_b avtab   -- AR消費税マスタ
--        WHERE  avtab.tax_code = lt_consum_code
--        AND    avtab.set_of_books_id = TO_NUMBER(gv_bks_id)
--/*--==============2009/2/4-START=========================--*/
--        AND    NVL( avtab.start_date, gd_process_date )  <= gd_process_date
--        AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
--/*--==============2009/2/4--END==========================--*/
--/*--==============2009/2/17-START=========================--*/
--        AND    avtab.enabled_flag = cv_tkn_yes;
--/*--==============2009/2/17--END==========================--*/
-- ****************** 2009/09/03 1.18 N.Maeda MOD  END  ************** --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ログ出力          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
          --キー編集処理
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
--          lv_key_name2 := NULL;
--          lv_key_data1 := lt_consum_code;
--          lv_key_data2 := NULL;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
-- ****************** 2009/09/03 1.18 N.Maeda MOD START ************** --
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- 項目名称１
--            iv_data_value1 => lt_consum_code,         -- データの値１
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_order_num_hht ), -- 項目名称１
            iv_data_value1 => lt_order_no_hht,
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_digestion_number ), -- 項目名称
            iv_data_value2 => lt_digestion_ln_number,
            iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称
            iv_data_value3 => lt_consumption_tax_class,
-- ****************** 2009/09/03 1.18 N.Maeda MOD  END  ************** --
            ov_key_info    => gv_tkn2,              -- キー情報
            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
            ov_retcode     => lv_retcode,           -- リターン・コード
            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table,      --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
      END;
      --HHT納品入力日時形成
      gd_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                              SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
      -- 消費税率算出
      ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
      --==========================
      --出荷元保管場所の導出
      --==========================
      BEGIN
        SELECT xca.dept_hht_div   -- HHT百貨店入力区分
        INTO   lv_depart_code
        FROM   hz_cust_accounts hca,  -- 顧客マスタ
               xxcmm_cust_accounts xca  -- 顧客追加情報
        WHERE  hca.cust_account_id = xca.customer_id
        AND    hca.account_number = lt_base_code
        AND    hca.customer_class_code = cv_bace_branch;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --キー編集処理
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_data1 := lt_base_code;
--          lv_key_data2 := cv_bace_branch;
--        RAISE no_data_extract;
          lv_dept_hht_div_flg := cv_status_warn;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code ), -- 項目名称１
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- 項目名称２
            iv_data_value1 => lt_base_code,         -- データの値１
            iv_data_value2 => cv_bace_branch,       -- データの値２
            ov_key_info    => gv_tkn2,              -- キー情報
            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
            ov_retcode     => lv_retcode,           -- リターン・コード
            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table, --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
      END;
--
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
      IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
/*--==============2009/2/3-START=========================--*/
--      IF ( lv_depart_code = cv_depart_car ) THEN
        IF ( lv_depart_code IS NULL ) 
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
/*--==============2009/2/3-END===========================--*/
          --参照コードマスタ：営業車の保管場所分類コード取得
          BEGIN
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD START ***************************************
            SELECT  look_val.meaning      --保管場所分類コード
            INTO    lt_location_type_code
            FROM    fnd_lookup_values     look_val
            WHERE   look_val.language     = ct_user_lang
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type  = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code  = cv_xxcos_001_a05_05;
--
--            SELECT  look_val.meaning      --保管場所分類コード
--            INTO    lt_location_type_code
--            FROM    fnd_lookup_values     look_val,
--                    fnd_lookup_types_tl   types_tl,
--                    fnd_lookup_types      types,
--                    fnd_application_tl    appl,
--                    fnd_application       app
--            WHERE   appl.application_id   = types.application_id
--            AND     app.application_id    = appl.application_id
--            AND     types_tl.lookup_type  = look_val.lookup_type
--            AND     types.lookup_type     = types_tl.lookup_type
--            AND     types.security_group_id   = types_tl.security_group_id
--            AND     types.view_application_id = types_tl.view_application_id
--            AND     types_tl.language = USERENV( 'LANG' )
--            AND     look_val.language = USERENV( 'LANG' )
--            AND     appl.language     = USERENV( 'LANG' )
--            AND     gd_process_date      >= look_val.start_date_active
--            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--            AND     app.application_short_name = cv_application
--            AND     look_val.enabled_flag = cv_tkn_yes
--            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--            AND     look_val.lookup_code = cv_xxcos_001_a05_05;
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD END *****************************************
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --キー編集処理用変数
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_05;
            RAISE no_data_extract;
          END;
--
        --保管場所マスタデータ取得
        BEGIN
          SELECT msi.secondary_inventory_name     -- 保管場所コード
          INTO   lt_secondary_inventory_name
          FROM   mtl_secondary_inventories msi    -- 保管場所マスタ
          WHERE  msi.attribute7 = lt_base_code
          AND    msi.attribute13 = lt_location_type_code
          AND    msi.attribute3 = lt_dlv_by_code;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ログ出力          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
            --キー編集処理用変数
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_05;
--          RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
-- == 2010/09/09 V1.22 Modified START ===============================================================
--            xxcos_common_pkg.makeup_key_info(
--              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code ),     -- 項目名称１
--              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
----******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
--              iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_dlv_by_code ), -- 項目名称3
--              iv_data_value1 => lt_base_code,         -- データの値１
----              iv_data_value2 => cv_xxcos_001_a05_05,       -- データの値２
--              iv_data_value2 => lt_location_type_code,       -- データの値２
--              iv_data_value3 => lt_dlv_by_code,
----******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
----******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
--              ov_key_info    => gv_tkn2,              -- キー情報
--              ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--              ov_retcode     => lv_retcode,           -- リターン・コード
--              ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
            xxcos_common_pkg.makeup_key_info(
                iv_item_name1     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code )      --  項目名称１
              , iv_item_name2     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type )  --  項目名称２
              , iv_item_name3     =>  xxccp_common_pkg.get_msg( cv_application, ct_msg_dlv_by_code )    --  項目名称３
              , iv_item_name4     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00131 )    --  項目名称４
              , iv_item_name5     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00053 )    --  項目名称５
              , iv_data_value1    =>  lt_base_code                    --  拠点コード
              , iv_data_value2    =>  lt_location_type_code           --  保管場所分類
              , iv_data_value3    =>  lt_dlv_by_code                  --  納品者コード
              , iv_data_value4    =>  lt_hht_invoice_no               --  HHT伝票No.
              , iv_data_value5    =>  lt_customer_number              --  顧客コード
              , ov_key_info       =>  gv_tkn2                         --  キー情報
              , ov_errbuf         =>  lv_errbuf                       --  エラー・メッセージエラー
              , ov_retcode        =>  lv_retcode                      --  リターン・コード
              , ov_errmsg         =>  lv_errmsg                       --  ユーザー・エラー・メッセージ
            );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => cv_msg_no_data,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_table,      --トークンコード1
                                                  iv_token_value1  => gv_tkn1,           --トークン値1
                                                  iv_token_name2   => cv_key_data,       --トークンコード2
                                                  iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
            IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
              --  汎用エラーリスト出力要の場合
              gn_msg_cnt  :=  gn_msg_cnt + 1;
              --  汎用エラーリスト用キー情報
              --  納品拠点
              gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_base_code;
              --  エラーメッセージ名
              gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_msg_no_data || cv_cons_num_01;
              --  キーメッセージ
              gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(gv_tkn2, 1, 2000);
            END IF;
-- == 2010/09/09 V1.22 Added END   ===============================================================
          END;
--
/*--==============2009/2/3-START=========================--*/
--      ELSIF ( lv_depart_code = cv_depart_type ) THEN
--      ELSIF ( lv_depart_code IS NOT NULL ) THEN
        ELSIF ( lv_depart_code = cv_depart_type ) 
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
/*--==============2009/2/3-END=========================--*/
          --参照コードマスタ：百貨店の保管場所分類コード取得
          BEGIN
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD START ***************************************
            SELECT  look_val.meaning    --保管場所分類コード
            INTO    lt_depart_location_type_code
            FROM    fnd_lookup_values     look_val
            WHERE   look_val.language = ct_user_lang
            AND     gd_process_date   >= look_val.start_date_active
            AND     gd_process_date   <= NVL(look_val.end_date_active, gd_max_date)
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_09;
--
--            SELECT  look_val.meaning    --保管場所分類コード
--            INTO    lt_depart_location_type_code
--            FROM    fnd_lookup_values     look_val,
--                    fnd_lookup_types_tl   types_tl,
--                    fnd_lookup_types      types,
--                    fnd_application_tl    appl,
--                    fnd_application       app
--            WHERE   appl.application_id   = types.application_id
--            AND     app.application_id    = appl.application_id
--            AND     types_tl.lookup_type  = look_val.lookup_type
--            AND     types.lookup_type     = types_tl.lookup_type
--            AND     types.security_group_id   = types_tl.security_group_id
--            AND     types.view_application_id = types_tl.view_application_id
--            AND     types_tl.language = USERENV( 'LANG' )
--            AND     look_val.language = USERENV( 'LANG' )
--            AND     appl.language     = USERENV( 'LANG' )
--            AND     gd_process_date   >= look_val.start_date_active
--            AND     gd_process_date   <= NVL(look_val.end_date_active, gd_max_date)
--            AND     app.application_short_name = cv_application
--            AND     look_val.enabled_flag = cv_tkn_yes
--            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--            AND     look_val.lookup_code = cv_xxcos_001_a05_09;
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD END *****************************************
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --キー編集処理用変数設定
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_09;
            RAISE no_data_extract;
          END;
--
          --保管場所マスタデータ取得
          BEGIN
            SELECT msi.secondary_inventory_name     -- 保管場所コード
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi    -- 保管場所マスタ
            WHERE  msi.attribute7 = lt_base_code
            AND    msi.attribute13 = lt_depart_location_type_code
            AND    msi.attribute4 = lt_keep_in_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --キー編集処理用変数設定
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
--              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--              lv_key_data1 := lt_base_code;
--              lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
-- == 2010/09/09 V1.22 Modified START ===============================================================
--              xxcos_common_pkg.makeup_key_info(
--                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code ), -- 項目名称１
--                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
----******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_keep_in_code ), -- 項目名称3
--                iv_data_value1 => lt_base_code,         -- データの値１
----                iv_data_value2 => cv_xxcos_001_a05_09,       -- データの値２
--                iv_data_value2 => lt_depart_location_type_code,       -- データの値２
--                iv_data_value3 => lt_keep_in_code,
----******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
--                ov_key_info    => gv_tkn2,              -- キー情報
--                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                ov_retcode     => lv_retcode,           -- リターン・コード
--                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              xxcos_common_pkg.makeup_key_info(
                  iv_item_name1     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code )      --  項目名称１
                , iv_item_name2     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type )  --  項目名称２
                , iv_item_name3     =>  xxccp_common_pkg.get_msg( cv_application, ct_msg_keep_in_code )   --  項目名称３
                , iv_item_name4     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00131 )    --  項目名称４
                , iv_item_name5     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00053 )    --  項目名称５
                , iv_data_value1    =>  lt_base_code                    --  拠点コード
                , iv_data_value2    =>  lt_depart_location_type_code    --  保管場所分類
                , iv_data_value3    =>  lt_keep_in_code                 --  預け先コード
                , iv_data_value4    =>  lt_hht_invoice_no               --  HHT伝票No.
                , iv_data_value5    =>  lt_customer_number              --  顧客コード
                , ov_key_info       =>  gv_tkn2                         --  キー情報
                , ov_errbuf         =>  lv_errbuf                       --  エラー・メッセージエラー
                , ov_retcode        =>  lv_retcode                      --  リターン・コード
                , ov_errmsg         =>  lv_errmsg                       --  ユーザー・エラー・メッセージ
              );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => cv_msg_no_data,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_table, --トークンコード1
                                                  iv_token_value1  => gv_tkn1,           --トークン値1
                                                  iv_token_name2   => cv_key_data,       --トークンコード2
                                                  iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
              IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
                --  汎用エラーリスト出力要の場合
                gn_msg_cnt  :=  gn_msg_cnt + 1;
                --  汎用エラーリスト用キー情報
                --  納品拠点
                gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_base_code;
                --  エラーメッセージ名
                gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_msg_no_data || cv_cons_num_01;
                --  キーメッセージ
                gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(gv_tkn2, 1, 2000);
              END IF;
-- == 2010/09/09 V1.22 Added END   ===============================================================
          END;
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
--
      --=============
      -- 納品形態区分取得
      --=============
      xxcos_common_pkg.get_delivered_from( lt_secondary_inventory_name,
                                           lt_base_code, 
                                           lt_base_code, 
                                           gv_orga_code,
                                           gn_orga_id, 
                                           lv_delivery_type,
                                           lv_errbuf, 
                                           lv_retcode, 
                                           lv_errmsg );
      IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Ver1.10 MOD START ***************************************
--        RAISE delivered_from_err_expt;
        lv_state_flg    := cv_status_warn;
        gn_wae_data_num := gn_wae_data_num + 1 ;
        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Ver1.10 MOD END *****************************************
      END IF;
      --====================
      --納品拠点の導出(明細)
      --====================
      BEGIN
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD START ***************************************
        SELECT rin_v.base_code  base_code    -- 拠点コード
        INTO   lt_dlv_base_code
--******************************* 2009/10/30 M.Sano  Ver1.19 MOD START ***************************************
--        FROM   xxcos_rs_info_v  rin_v        -- 従業員情報view
        FROM   xxcos_rs_info2_v rin_v
--******************************* 2009/10/30 M.Sano  Ver1.19 MOD END *****************************************
        WHERE  rin_v.employee_number = lt_dlv_by_code
        AND    NVL( rin_v.effective_start_date     , lt_dlv_date )  <= lt_dlv_date
        AND    NVL( rin_v.effective_end_date       , lt_dlv_date )  >= lt_dlv_date
        AND    NVL( rin_v.per_effective_start_date , lt_dlv_date )  <= lt_dlv_date
        AND    NVL( rin_v.per_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
        AND    NVL( rin_v.paa_effective_start_date , lt_dlv_date )  <= lt_dlv_date
        AND    NVL( rin_v.paa_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
        ;
--
--        SELECT rin_v.base_code  --拠点コード
--        INTO lt_dlv_base_code
--        FROM xxcos_rs_info_v rin_v   --従業員情報view
--        WHERE rin_v.employee_number = lt_dlv_by_code
--/*--==============2009/2/3-START=========================--*/
--        AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
--        AND   NVL( rin_v.effective_end_date, lt_dlv_date ) >= lt_dlv_date;
--/*--==============2009/2/3-END=========================--*/
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD END *****************************************
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- ログ出力          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
            --キー編集用変数設定
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_dlv_by_code;
--            lv_key_data2 := NULL;
--          RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
-- == 2010/09/09 V1.22 Modified START ===============================================================
--            xxcos_common_pkg.makeup_key_info(
--              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- 項目名称１
--              iv_data_value1 => lt_dlv_by_code,         -- データの値１
--              ov_key_info    => gv_tkn2,              -- キー情報
--              ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--              ov_retcode     => lv_retcode,           -- リターン・コード
--              ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
            xxcos_common_pkg.makeup_key_info(
                iv_item_name1     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv )            --  項目名称１
              , iv_item_name2     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00131 )    --  項目名称２
              , iv_item_name3     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcos_00053 )    --  項目名称３
              , iv_data_value1    =>  lt_dlv_by_code                  --  納品者コード
              , iv_data_value2    =>  lt_hht_invoice_no               --  HHT伝票No.
              , iv_data_value3    =>  lt_customer_number              --  顧客コード
              , ov_key_info       =>  gv_tkn2                         --  キー情報
              , ov_errbuf         =>  lv_errbuf                       --  エラー・メッセージエラー
              , ov_retcode        =>  lv_retcode                      --  リターン・コード
              , ov_errmsg         =>  lv_errmsg                       --  ユーザー・エラー・メッセージ
            );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table, --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
            IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
              --  汎用エラーリスト出力要の場合
              gn_msg_cnt  :=  gn_msg_cnt + 1;
              --  汎用エラーリスト用キー情報
              --  納品拠点
              gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_base_code;
              --  エラーメッセージ名
              gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_msg_no_data || cv_cons_num_02;
              --  キーメッセージ
              gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(gv_tkn2, 1, 2000);
            END IF;
-- == 2010/09/09 V1.22 Added END   ===============================================================
      END;
--
--******************************* 2009/04/16 N.Maeda Var1.10 DEL START ***************************************
--      --=========================
--      --納品伝票入力区分の導出(明細)
--      --=========================
--      BEGIN
--        SELECT  look_val.attribute4     -- 納品伝票区分(販売実績入力区分)
--        INTO    lt_ins_line_invoice_type
--        FROM    fnd_lookup_values     look_val,
--                fnd_lookup_types_tl   types_tl,
--                fnd_lookup_types      types,
--                fnd_application_tl    appl,
--                fnd_application       app
--        WHERE   appl.application_id   = types.application_id
--        AND     app.application_id    = appl.application_id
--        AND     types_tl.lookup_type  = look_val.lookup_type
--        AND     types.lookup_type     = types_tl.lookup_type
--        AND     types.security_group_id   = types_tl.security_group_id
--        AND     types.view_application_id = types_tl.view_application_id
--        AND     types_tl.language = USERENV( 'LANG' )
--        AND     look_val.language = USERENV( 'LANG' )
--        AND     appl.language     = USERENV( 'LANG' )
--        AND     gd_process_date      >= look_val.start_date_active
--        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--        AND     app.application_short_name = cv_application
--        AND     look_val.enabled_flag = cv_tkn_yes
--        AND     look_val.lookup_type = cv_xxcos1_input_class
--        AND     look_val.lookup_code = lt_input_class;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            -- ログ出力          
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
--            --キー編集表変数設定
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_input_class;
--            lv_key_data2 := NULL;
--          RAISE no_data_extract;
--      END;
--******************************* 2009/04/16 N.Maeda Var1.10 DEL END *****************************************
--
        --==========================
        --納品伝票入力区分の導出(ヘッダ)
        --==========================
      BEGIN
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD START ***************************************
          SELECT  DECODE( lt_digestion_ln_number,
                         cn_cons_tkn_zero, look_val.attribute4,        -- 通常時(納品伝票区分(販売実績入力区分))
                         look_val.attribute5)                          -- 取消・訂正(納品伝票区分(販売実績入力区分))
          INTO    lt_ins_invoice_type
          FROM    fnd_lookup_values     look_val
          WHERE   look_val.language     = ct_user_lang
          AND     gd_process_date      >= look_val.start_date_active
          AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
          AND     look_val.enabled_flag = cv_tkn_yes
          AND     look_val.lookup_type  = cv_xxcos1_input_class
          AND     look_val.lookup_code  = lt_input_class;
--
----******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
----          SELECT  DECODE(lt_cancel_correct_class, 
----                         cv_tkn_null, look_val.attribute4,        -- 通常時(納品伝票区分(販売実績入力区分))
----                         cv_correct_class, look_val.attribute5,   -- 取消時(納品伝票区分(販売実績入力区分))
----                         cv_cancel_class, look_val.attribute5)    -- 訂正(納品伝票区分(販売実績入力区分))
--          SELECT  DECODE( lt_digestion_ln_number,
--                         cn_cons_tkn_zero, look_val.attribute4,        -- 通常時(納品伝票区分(販売実績入力区分))
--                         look_val.attribute5)                          -- 取消・訂正(納品伝票区分(販売実績入力区分))
----******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--          INTO    lt_ins_invoice_type
--          FROM    fnd_lookup_values     look_val,
--                  fnd_lookup_types_tl   types_tl,
--                  fnd_lookup_types      types,
--                  fnd_application_tl    appl,
--                  fnd_application       app
--          WHERE   appl.application_id   = types.application_id
--          AND     app.application_id    = appl.application_id
--          AND     types_tl.lookup_type  = look_val.lookup_type
--          AND     types.lookup_type     = types_tl.lookup_type
--          AND     types.security_group_id   = types_tl.security_group_id
--          AND     types.view_application_id = types_tl.view_application_id
--          AND     types_tl.language = USERENV( 'LANG' )
--          AND     look_val.language = USERENV( 'LANG' )
--          AND     appl.language     = USERENV( 'LANG' )
--          AND     gd_process_date      >= look_val.start_date_active
--          AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--          AND     app.application_short_name = cv_application
--          AND     look_val.enabled_flag = cv_tkn_yes
--          AND     look_val.lookup_type = cv_xxcos1_input_class
--          AND     look_val.lookup_code = lt_input_class;
--******************************* 2009/08/12 N.Maeda Ver1.16 MOD END *****************************************
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
            --キー編集表変数設定
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_input_class;
--            lv_key_data2 := NULL;
--          RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- 項目名称１
              iv_data_value1 => lt_input_class,         -- データの値１
              ov_key_info    => gv_tkn2,              -- キー情報
              ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
              ov_retcode     => lv_retcode,           -- リターン・コード
              ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => cv_msg_no_data,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_table, --トークンコード1
                                                  iv_token_value1  => gv_tkn1,           --トークン値1
                                                  iv_token_name2   => cv_key_data,       --トークンコード2
                                                  iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/21 N.Maeda Var1.10 MOD END *****************************************
        END;
--
-- ****************** 2009/09/03 1.18 N.Maeda DEL START ************** --
----******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
--    --==================================
--    -- 1.納品日算出
--    --==================================
--    get_fiscal_period_from(
--        iv_div        => cv_fiscal_period_ar             -- 会計区分
--      , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
--      , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
--      , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
--      , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
--      , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
--    );
--    IF ( lv_retcode != cv_status_normal ) THEN
--      lv_state_flg    := cv_status_warn;
--      gn_wae_data_num := gn_wae_data_num + 1 ;
--      gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                            iv_application   => cv_application,    --アプリケーション短縮名
--                                            iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                            iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--                                            iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                            iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                            iv_token_value2  => lt_order_no_hht,
--                                            iv_token_name3   => cv_tkn_base_date,
--                                            iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
--    END IF;
----
----
--    --==================================
--    -- 2.売上計上日算出
--    --==================================
--    get_fiscal_period_from(
--        iv_div        => cv_fiscal_period_ar                  -- 会計区分
--      , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
--      , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
--      , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
--      , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
--      , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
--    );
--    IF ( lv_retcode != cv_status_normal ) THEN
--      lv_state_flg    := cv_status_warn;
--      gn_wae_data_num := gn_wae_data_num + 1 ;
--      gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                            iv_application   => cv_application,    --アプリケーション短縮名
--                                            iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                            iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--                                            iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                            iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                            iv_token_value2  => lt_order_no_hht,
--                                            iv_token_name3   => cv_tkn_base_date,
--                                            iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
--    END IF;
----******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
-- ****************** 2009/09/03 1.18 N.Maeda DEL  END  ************** --
--
      <<line_loop>>
      FOR ln_line_no IN ln_line_cnt..gn_target_lines_cnt LOOP                                   --明細番号
        lt_lin_order_no_hht     :=  gt_vd_c_lines_data( ln_line_no ).order_no_hht;              --受注No.(HHT)
        lt_lin_line_no_hht      :=  gt_vd_c_lines_data( ln_line_no ).line_no_hht;               --行No.(HHT)
        lt_lin_digestion_ln_number :=  gt_vd_c_lines_data( ln_line_no ).digestion_ln_number;    --枝番
        lt_lin_order_no_ebs     :=  gt_vd_c_lines_data( ln_line_no ).order_no_ebs;              --受注No.(EBS)
        lt_lin_line_number_ebs  :=  gt_vd_c_lines_data( ln_line_no ).line_number_ebs;           --明細番号(EBS)
        lt_lin_item_code_self   :=  gt_vd_c_lines_data( ln_line_no ).item_code_self;            --品名コード(自社)
        lt_lin_content          :=  gt_vd_c_lines_data( ln_line_no ).content;                   --入数
        lt_lin_inventory_item_id :=  gt_vd_c_lines_data( ln_line_no ).inventory_item_id;        --品目ID
        lt_lin_standard_unit    :=  gt_vd_c_lines_data( ln_line_no ).standard_unit;             --基準単位
        lt_lin_case_number      :=  gt_vd_c_lines_data( ln_line_no ).case_number;               --ケース数
        lt_lin_quantity         :=  gt_vd_c_lines_data( ln_line_no ).quantity;                  --数量
        lt_lin_sale_class       :=  gt_vd_c_lines_data( ln_line_no ).sale_class;                --売上区分
        lt_lin_wholesale_unit_ploce :=  gt_vd_c_lines_data( ln_line_no ).wholesale_unit_ploce;  --卸単価
        lt_lin_selling_price    :=  gt_vd_c_lines_data( ln_line_no ).selling_price;             --売単価
        lt_lin_column_no        :=  gt_vd_c_lines_data( ln_line_no ).column_no;                 --コラムNo
        lt_lin_h_and_c          :=  gt_vd_c_lines_data( ln_line_no ).h_and_c;                   --H/C
        lt_lin_sold_out_class   :=  gt_vd_c_lines_data( ln_line_no ).sold_out_class;            --売切区分
        lt_lin_sold_out_time    :=  gt_vd_c_lines_data( ln_line_no ).sold_out_time;             --売切時間
        lt_lin_replenish_number :=  gt_vd_c_lines_data( ln_line_no ).replenish_number;          --補充数
        lt_lin_cash_and_card    :=  gt_vd_c_lines_data( ln_line_no ).cash_and_card;             --現金・カード併用額
--
        EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
--
        IF ( lt_lin_case_number IS NULL ) THEN
          lt_lin_case_number := 0;
        END IF;
--
        --====================================
        --営業原価の導出(販売実績明細(コラム))
        --====================================
        BEGIN
          SELECT ic_item.attribute7,              -- 旧営業原価
                 ic_item.attribute8,              -- 新営業原価
                 ic_item.attribute9,              -- 営業原価適用開始日
                 mtl_item.primary_unit_of_measure     -- 基準単位
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit
          FROM   mtl_system_items_b    mtl_item,    -- 品目
                 ic_item_mst_b         ic_item,     -- OPM品目
                 xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1          = lt_lin_item_code_self
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --キー編集処理
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_lin_item_code_self;
--            lv_key_data2 := gn_orga_id;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- 項目名称１
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ),    -- 項目名称２
              iv_data_value1 => lt_lin_item_code_self,-- データの値１
              iv_data_value2 => gn_orga_id,           -- データの値２
              ov_key_info    => gv_tkn2,              -- キー情報
              ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
              ov_retcode     => lv_retcode,           -- リターン・コード
              ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => cv_msg_no_data,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_table, --トークンコード1
                                                  iv_token_value1  => gv_tkn1,           --トークン値1
                                                  iv_token_name2   => cv_key_data,       --トークンコード2
                                                  iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/21 N.Maeda Var1.10 MOD END *****************************************
        END;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
          ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
--
          -- 営業原価判断
-- ****************************** 2010/05/10 1.21 Y.Kuboshima MOD START **************************************
--          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > gd_process_date ) THEN
          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
-- ****************************** 2010/05/10 1.21 Y.Kuboshima MOD END   **************************************
            lt_sales_cost := lt_old_sales_cost;
          ELSE
            lt_sales_cost := lt_new_sales_cost;
          END IF;
--
--******************************* 2009/04/21 N.Maeda Var1.10 DEL START ***************************************
--        -- ===================
--        -- 登録用明細ID取得
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/21 N.Maeda Var1.10 DEL END *****************************************
--
          -- 基準単価
          lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
--************************** 2009/03/23 1.6 N.Maeda MOD START ************************************
--        -- 売上金額
--        lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--************************** 2009/03/23 1.6 N.Maeda MOD END ************************************
--
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
--
            -- 税抜基準単価
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- 本体金額
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- 消費税金額
            lt_tax_amount            := cn_cons_tkn_zero;
--************************** 2009/03/23 1.6 N.Maeda MOD START ************************************
            -- 売上金額
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--************************** 2009/03/23 1.6 N.Maeda MOD END ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
--
            -- 税抜基準単価
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- 本体金額
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- 消費税金額
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
--          lt_tax_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
            lt_tax_amount          := ROUND( lt_pure_amount *( ln_tax_data - 1 ));
--            ln_amount            := ROUND( lt_pure_amount *( ln_tax_data - 1 ));
--            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
----******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
--                IF ( SIGN( ln_amount ) <> -1 ) THEN
--                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
--                ELSE
--                  lt_tax_amount := ( TRUNC( ln_amount ) - 1 );
--                END IF;
----                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
----******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_tax_amount := TRUNC( ln_amount );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_tax_amount := ROUND( ln_amount );
--              END IF;
--            ELSE
--              lt_tax_amount := ln_amount;
--            END IF;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
--************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
--************************** 2009/03/23 1.7 N.Maeda MOD START ************************************
            -- 売上金額
            lt_sale_amount    := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--            ln_sal_amount_data    := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--            IF ( ln_sal_amount_data <> TRUNC( ln_sal_amount_data ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_sale_amount := ( TRUNC( ln_sal_amount_data ) + 1 );
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount := TRUNC( ln_sal_amount_data );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount := ROUND( ln_sal_amount_data );
--              END IF;
--            ELSE
--              lt_sale_amount := ln_sal_amount_data;
--            END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--************************** 2009/03/23 1.7 N.Maeda MOD END ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
--
            -- 税抜基準単価
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- 本体金額
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- 消費税金額
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
--          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
            lt_tax_amount          := ROUND( ( lt_pure_amount * ( ln_tax_data - 1)));
--            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
----******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
--                IF ( SIGN( ln_amount ) <> -1 ) THEN
--                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
--                ELSE
--                  lt_tax_amount := ( TRUNC( ln_amount ) - 1 );
--                END IF;
----                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
----******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_tax_amount := TRUNC( ln_amount );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_tax_amount := ROUND( ln_amount );
--              END IF;
--            ELSE
--              lt_tax_amount := ln_amount;
--            END IF;
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
--************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
--************************** 2009/03/23 1.7 N.Maeda MOD START ************************************
            -- 売上金額
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
            lt_sale_amount    := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--            ln_sal_amount_data    := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--            IF ( ln_sal_amount_data <> TRUNC( ln_sal_amount_data ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_sale_amount := ( TRUNC( ln_sal_amount_data ) + 1 );
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount := TRUNC( ln_sal_amount_data );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount := ROUND( ln_sal_amount_data );
--              END IF;
--            ELSE
--              lt_sale_amount := ln_sal_amount_data;
--            END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--************************** 2009/03/23 1.7 N.Maeda MOD END ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
--
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
            -- 税抜基準単価
            lt_stand_unit_price_excl :=  ROUND( ( (lt_lin_wholesale_unit_ploce /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
--            lt_stand_unit_price_excl := ( lt_lin_wholesale_unit_ploce / ln_tax_data );
--            IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
--              END IF;
--            END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
            -- 本体金額
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) 
                                       - ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
                IF ( SIGN( ln_amount ) <> -1 ) THEN
                  lt_pure_amount := TRUNC(( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - ( TRUNC( ln_amount ) + 1 ));
                ELSE
                  lt_pure_amount := TRUNC(( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - ( TRUNC( ln_amount ) - 1 ));
                END IF;
--                lt_pure_amount := TRUNC(( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - ( TRUNC( ln_amount ) + 1 ));
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
              -- 切捨て
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - TRUNC( ln_amount ));
              -- 四捨五入
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - ROUND( ln_amount ));
              END IF;
            ELSE
              lt_pure_amount := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) - ln_amount);
            END IF;
--            ln_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
--            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
--              -- 切捨て
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount := TRUNC( ln_amount );
--              -- 四捨五入
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_pure_amount := ROUND( ln_amount );
--              END IF;
--            ELSE
--              lt_pure_amount := ln_amount;
--            END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
            -- 消費税金額
--            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
--                                         - lt_pure_amount );
--
            ln_amount           := ( ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) 
                                       /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                IF ( SIGN (ln_amount) <> -1 ) THEN
                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                ELSE
                  lt_tax_amount := TRUNC( ln_amount ) - 1;
                END IF;
              -- 切捨て
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- 四捨五入
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--
--******************************* 2009/06/01 N.Maeda Var1.14 MOD END *****************************************
--************************** 2009/03/23 1.6 N.Maeda MOD START ************************************
            -- 売上金額
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--************************** 2009/03/23 1.6 N.Maeda MOD END ************************************
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
            -- 明細本体金額合計
            ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
--
          END IF;
--
          --対照データが非課税でないときのとき
          IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
            --消費税合計積上げ
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
            --明細別最大消費税算出
            IF ( ln_max_tax_data < lt_tax_amount ) THEN
              ln_max_tax_data := lt_tax_amount;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
 --             ln_max_no_data  := gn_line_ck_no;
              ln_max_no_data  := ln_line_data_count;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD  END  ***************************************
            END IF;
          END IF;
--
          -- 赤・黒の金額換算
          --黒の時
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- 基準数量(納品数量)
            lt_set_replenish_number := lt_lin_replenish_number;
            -- 売上金額
            lt_set_sale_amount := lt_sale_amount;
            -- 本体金額
            lt_set_pure_amount := lt_pure_amount;
            -- 消費税金額
            lt_set_tax_amount := lt_tax_amount;
          -- 赤の時
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- 基準数量(納品数量)
            lt_set_replenish_number := ( lt_lin_replenish_number * ( -1 ) );
            -- 売上金額
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- 本体金額
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- 消費税金額
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
--******************************* 2009/05/12 N.Maeda Var1.11 MOD START ***************************************
            lt_lin_cash_and_card := ( lt_lin_cash_and_card * ( -1 ) );
--******************************* 2009/05/12 N.Maeda Var1.11 MOD  END  ***************************************
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
          --====================
          --明細データの変数挿入
          --====================
--        gt_line_sales_exp_line_id( gn_line_ck_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
--        gt_line_sales_exp_header_id( gn_line_ck_no )     := ln_actual_id;                 -- 販売実績ヘッダID
--        gt_line_dlv_invoice_number( gn_line_ck_no )      := lt_hht_invoice_no;            -- 納品伝票番号
--        gt_line_dlv_invoice_l_num( gn_line_ck_no )       := lt_lin_line_no_hht;           -- 納品明細番号
--        gt_line_sales_class( gn_line_ck_no )             := lt_lin_sale_class;            -- 売上区分
--        gt_line_red_black_flag( gn_line_ck_no )          := lt_red_black_flag;            -- 赤黒フラグ
--        gt_line_item_code( gn_line_ck_no )               := lt_lin_item_code_self;        -- 品目コード
--        gt_line_standard_qty( gn_line_ck_no )            := lt_set_replenish_number;      -- 基準数量--
--        gt_line_standard_uom_code( gn_line_ck_no )       := lt_stand_unit;                -- 基準単位
--        gt_line_standard_unit_price( gn_line_ck_no )     := lt_standard_unit_price;       -- 基準単価
--        gt_line_business_cost( gn_line_ck_no )           := lt_sales_cost;                -- 営業原価
--        gt_line_sale_amount( gn_line_ck_no )             := lt_set_sale_amount;           -- 売上金額--
--        gt_line_pure_amount( gn_line_ck_no )             := lt_set_pure_amount;           -- 本体金額--
--        gt_line_tax_amount( gn_line_ck_no )              := lt_set_tax_amount;            -- 消費税金額--
--        gt_line_cash_and_card( gn_line_ck_no )           := lt_lin_cash_and_card;         -- 現金・カード併用額
--        gt_line_ship_from_subinv_co( gn_line_ck_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
--        gt_line_delivery_base_code( gn_line_ck_no )      := lt_dlv_base_code;             -- 納品拠点コード
--        gt_line_hot_cold_class( gn_line_ck_no )          := lt_lin_h_and_c;               -- Ｈ＆Ｃ
--        gt_line_column_no( gn_line_ck_no )               := lt_lin_column_no;             -- コラムNo
--        gt_line_sold_out_class( gn_line_ck_no )          := lt_lin_sold_out_class;        -- 売切区分
--        gt_line_sold_out_time( gn_line_ck_no )           := lt_lin_sold_out_time;         -- 売切時間
--        gt_line_to_calculate_fees_flag( gn_line_ck_no )  := cv_line_to_calculate_fees_f_n;-- 手数料計算インタフェース済フラグ
--        gt_line_unit_price_mst_flag( gn_line_ck_no )     := cv_line_unit_price_mst_flag_n;-- 単価マスタ作成済フラグ
--        gt_line_inv_interface_flag( gn_line_ck_no )      := cv_line_inv_interface_flag_n; -- INVインタフェース済フラグ
--        gt_line_order_invoice_l_num( gn_line_ck_no )     := cv_line_order_invoice_l_num;  -- 注文明細番号(NULL設定)
--        gt_line_not_tax_amount( gn_line_ck_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
--        gt_line_delivery_pat_class( gn_line_ck_no )      := lv_delivery_type;             -- 納品形態区分
--        gt_line_dlv_qty( gn_line_ck_no )                 := lt_set_replenish_number;      -- 納品数量--
--        gt_line_dlv_uom_code( gn_line_ck_no )            := lt_stand_unit;                -- 納品単位
--        gt_dlv_unit_price( gn_line_ck_no )               := lt_standard_unit_price;       -- 納品単価
--        gn_line_ck_no := gn_line_ck_no + 1; 
          -- ===================
          -- 一時格納用
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- 納品伝票番号
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := lt_lin_line_no_hht;            -- 納品明細番号
          gt_accumulation_data(ln_line_data_count).sales_class                := lt_lin_sale_class;             -- 売上区分
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- 赤黒フラグ
          gt_accumulation_data(ln_line_data_count).item_code                  := lt_lin_item_code_self;         -- 品目コード
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- 納品数量
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- 基準数量
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- 納品単位
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- 基準単位
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- 納品単価
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- 基準単価
          gt_accumulation_data(ln_line_data_count).business_cost              := lt_sales_cost;-- 営業原価
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- 売上金額
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- 本体金額
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- 消費税金額
          gt_accumulation_data(ln_line_data_count).cash_and_card              := lt_lin_cash_and_card;          -- 現金・カード併用額
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- 出荷元保管場所
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- 納品拠点コード
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := lt_lin_h_and_c;                -- Ｈ＆Ｃ
          gt_accumulation_data(ln_line_data_count).column_no                  := lt_lin_column_no;              -- コラムNo
          gt_accumulation_data(ln_line_data_count).sold_out_class             := lt_lin_sold_out_class;         -- 売切区分
          gt_accumulation_data(ln_line_data_count).sold_out_time              := lt_lin_sold_out_time;          -- 売切時間
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_line_to_calculate_fees_f_n; -- 手数料計算インタフェース済フラグ
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_line_unit_price_mst_flag_n; -- 単価マスタ作成済フラグ
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_line_inv_interface_flag_n;  -- INVインタフェース済フラグ
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_line_order_invoice_l_num;   -- 注文明細番号(NULL設定)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- 納品形態区分(導出)
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
        ELSE
          gn_wae_data_count := gn_wae_data_count + 1;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
        ln_line_cnt := ln_line_cnt + 1;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END *****************************************
--
      END LOOP line_loop;
--
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END *****************************************
        -- ==================
        -- ヘッダ登録用金額算出
        -- ==================
        IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- 非課税
--
          -- 売上金額合計
          lt_sale_amount_sum := lt_total_amount;
          -- 本体金額合計
          lt_pure_amount_sum := lt_total_amount;
          -- 消費税金額合計
          lt_tax_amount_sum  := NVL( lt_sales_consumption_tax, cn_cons_tkn_zero );
--
        ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
--
            -- 売上金額合計
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
--        lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--        IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--          IF ( lt_tax_odd = cv_amount_up ) THEN
--          lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--          -- 切捨て
--          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--            lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--          -- 四捨五入
--          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--            lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--          END IF;
--        END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
          lt_sale_amount_sum := lt_total_amount;
--          ln_amount := lt_total_amount;
--          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--            lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount_sum := TRUNC( ln_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount_sum := ROUND( ln_amount );
--            END IF;
--          ELSE
--            lt_sale_amount_sum := ln_amount;
--          END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
          -- 本体金額合計
          lt_pure_amount_sum := lt_total_amount;
          -- 消費税金額合計
          ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
            IF ( lt_tax_odd = cv_amount_up ) THEN
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
              IF ( SIGN( ln_amount ) <> -1 ) THEN
                lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
              ELSE
                lt_tax_amount_sum := ( TRUNC( ln_amount ) - 1 );
              END IF;
--              lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
            -- 切捨て
            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_tax_amount_sum := TRUNC( ln_amount );
            -- 四捨五入
            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_tax_amount_sum := ROUND( ln_amount );
            END IF;
          ELSE
            lt_tax_amount_sum := ln_amount;
          END IF;
--
        ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
--
          -- 売上金額合計
--************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
--        lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--        IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--          IF ( lt_tax_odd = cv_amount_up ) THEN
--          lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--          -- 切捨て
--          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--            lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--          -- 四捨五入
--          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--            lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--          END IF;
--        END IF;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
--          ln_amount := ( lt_total_amount * ln_tax_data );
--          ln_amount := lt_total_amount;
          lt_sale_amount_sum := lt_total_amount;
--          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--            lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--            lt_sale_amount_sum := TRUNC( ln_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount_sum := ROUND( ln_amount );
--            END IF;
--          ELSE
--            lt_sale_amount_sum := ln_amount;
--          END IF;
----************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
          -- 本体金額合計
          lt_pure_amount_sum := lt_total_amount;
          -- 消費税金額合計
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
--          lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
          lt_tax_amount_sum  := lt_sales_consumption_tax;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
--
        ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
--
          -- 売上金額合計
          lt_sale_amount_sum := ln_line_pure_amount_sum + ln_all_tax_amount;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD START ***************************************
          -- 本体金額合計
----************************** 2009/03/18 1.6 T.kitajima MOD START ************************************
----       lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
----        IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
----          IF ( lt_tax_odd = cv_amount_up ) THEN
----            lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
----          -- 切捨て
----          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
----            lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
----          -- 四捨五入
----          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
----            lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
----          END IF;
----        END IF;
--          ln_amount := ( lt_total_amount / ln_tax_data );
--          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
--            -- 切捨て
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount_sum := TRUNC( ln_amount );
--            -- 四捨五入
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount_sum:= ROUND( ln_amount );
--            END IF;
--          ELSE
--            lt_pure_amount_sum := ln_amount;
--          END IF;
----************************** 2009/03/18 1.6 T.kitajima MOD  END  ************************************
          -- 本体金額合計
          lt_pure_amount_sum := ln_line_pure_amount_sum;
--******************************* 2009/05/20 N.Maeda Var1.13 MOD END *****************************************
          -- 消費税金額合計
          lt_tax_amount_sum  := ln_all_tax_amount;
--
        END IF;
--
        --非課税以外のとき
        IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
--
          --================================================
          --ヘッダ売上消費税額と明細売上消費税額比較判断処理
          --================================================
          IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
            -- 外税 OR 内税(伝票課税)の時
            IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
/* 2012/02/03 Ver1.23 Mod Start */
----******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
----              gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
--              gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
----******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
              --赤黒フラグが"黒"の場合
              IF ( lt_red_black_flag = cv_black_flag ) THEN
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
              --赤黒フラグが"赤"の場合
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
              END IF;
/* 2012/02/03 Ver1.23 Mod End   */
            END IF;
          END IF;
        END IF;
--
--******************************* 2009/05/12 N.Maeda Var1.12 ADD START ***************************************
        BEGIN
          SELECT vch.cancel_correct_class            -- 取消・訂正区分(最大値)
          INTO   lt_max_cancel_correct_class
          FROM   xxcos_vd_column_headers vch,        -- VDコラム別取引情報ヘッダ情報
                 xxcos_vd_column_lines vcl           -- VDコラム別取引情報明細
          WHERE  vch.order_no_hht = vcl.order_no_hht
          AND    vch.digestion_ln_number = vcl.digestion_ln_number
          AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
          AND    vch.input_class   =  cv_input_class_fs_vd_at
          AND    vch.forward_flag  =  cv_forward_flag_no
          AND    vch.order_no_hht  =  lt_order_no_hht
          AND    vch.cancel_correct_class IS NOT NULL
          AND    vch.digestion_ln_number  = ( SELECT
                                                MAX( vch.digestion_ln_number )
                                              FROM   xxcos_vd_column_headers vch,        -- VDコラム別取引情報ヘッダ情報
                                                     xxcos_vd_column_lines vcl           -- VDコラム別取引情報明細
                                              WHERE  vch.order_no_hht = vcl.order_no_hht
                                              AND    vch.digestion_ln_number = vcl.digestion_ln_number
                                              AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
                                              AND    vch.input_class   =  cv_input_class_fs_vd_at
                                              AND    vch.forward_flag  =  cv_forward_flag_no
                                              AND    vch.order_no_hht  =  lt_order_no_hht )
          GROUP BY vch.cancel_correct_class;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        BEGIN
          SELECT MIN(vch.digestion_ln_number)            -- 枝番(最小値)
          INTO   lt_min_digestion_ln_number
          FROM   xxcos_vd_column_headers vch,        -- VDコラム別取引情報ヘッダ情報
                 xxcos_vd_column_lines vcl           -- VDコラム別取引情報明細
          WHERE  vch.order_no_hht = vcl.order_no_hht
          AND    vch.digestion_ln_number = vcl.digestion_ln_number
          AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
          AND    vch.input_class   =  cv_input_class_fs_vd_at
          AND    vch.forward_flag  =  cv_forward_flag_no
          AND    vch.order_no_hht  =  lt_order_no_hht;
--          GROUP BY vch.ROWID;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        IF ( lt_min_digestion_ln_number IS NOT NULL ) AND ( lt_min_digestion_ln_number <> '0' ) THEN
          BEGIN
            -- カーソルOPEN
            OPEN  get_sales_exp_cur;
            -- バルクフェッチ
            FETCH get_sales_exp_cur BULK COLLECT INTO gt_sales_head_row_id;
            ln_sales_exp_count := get_sales_exp_cur%ROWCOUNT;
            -- カーソルCLOSE
            CLOSE get_sales_exp_cur;
--
          EXCEPTION
            WHEN lock_err_expt THEN
              IF( get_sales_exp_cur%ISOPEN ) THEN
                CLOSE get_sales_exp_cur;
              END IF;
              gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head );
              lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_tab, gv_tkn1 );
              RAISE;
          END;
--
          IF ( ln_sales_exp_count <> 0 ) THEN
            <<sales_exp_update_loop>>
            FOR u in 1..ln_sales_exp_count LOOP
              ln_set_sales_exp_count := ln_set_sales_exp_count + 1;
              gt_set_sales_head_row_id( ln_set_sales_exp_count )   := gt_sales_head_row_id(u);
              gt_set_head_cancel_cor_cls( ln_set_sales_exp_count ) := lt_max_cancel_correct_class;
            END LOOP sales_exp_update_loop;
          END IF;
        END IF;
--******************************* 2009/05/12 N.Maeda Var1.12 ADD  END  ***************************************
--
        -- 赤・黒の金額換算
        --黒の時
        IF ( lt_red_black_flag = cv_black_flag) THEN
          -- 売上金額合計
          lt_set_sale_amount_sum := lt_sale_amount_sum;
          -- 本体金額合計
          lt_set_pure_amount_sum := lt_pure_amount_sum;
          -- 消費税金額合計
          lt_set_tax_amount_sum := lt_tax_amount_sum;
        -- 赤の時
        ELSIF ( lt_red_black_flag = cv_red_flag) THEN
          -- 売上金額合計
          lt_set_sale_amount_sum := ( lt_sale_amount_sum * ( -1 ) );
          -- 本体金額合計
          lt_set_pure_amount_sum := ( lt_pure_amount_sum * ( -1 ) );
          -- 消費税金額合計
          lt_set_tax_amount_sum := ( lt_tax_amount_sum * ( -1 ) );
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
        --================================
        --販売実績ヘッダID(シーケンス取得)
        --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
--
        --==========================
        -- ヘッダデータの変数挿入
        --==========================
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
        gt_head_row_id( gn_header_ck_no )                  := lt_row_id;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
        gt_head_id( gn_header_ck_no )                      := ln_actual_id;                 -- 販売実績ヘッダID
        gt_head_order_no_ebs( gn_header_ck_no )            := lt_order_no_ebs;              -- 受注No.(EBS)(受注番号)
        gt_head_hht_invoice_no( gn_header_ck_no )          := lt_hht_invoice_no;            -- 納品伝票番号
        gt_head_order_no_hht( gn_header_ck_no )            := lt_order_no_hht;              -- 受注No(HHT)
        gt_head_digestion_ln_number( gn_header_ck_no )     := lt_digestion_ln_number;       -- 枝番(受注No(HHT)枝番)
        gt_head_dlv_invoice_class( gn_header_ck_no )       := lt_ins_invoice_type;          -- 納品伝票区分(導出)
--******************************* 2009/05/12 N.Maeda Var1.12 MOD START ***************************************
--        gt_head_cancel_cor_cls( gn_header_ck_no )          := lt_ins_invoice_type;          -- 取消・訂正区分(導出)
        gt_head_cancel_cor_cls( gn_header_ck_no )          := lt_max_cancel_correct_class;  -- 取消・訂正区分(導出)
--******************************* 2009/05/12 N.Maeda Var1.12 MOD  END  ***************************************
        gt_head_system_class( gn_header_ck_no )            := lt_system_class;              -- 業態区分(業態小分類)
        gt_head_dlv_date( gn_header_ck_no )                := lt_dlv_date;                  -- 納品日
        gt_head_inspect_date( gn_header_ck_no )            := lt_inspect_date;              -- 検収日(売上計上日)
        gt_head_customer_number( gn_header_ck_no )         := lt_customer_number;           -- 顧客コード(顧客【納品先】)
        gt_head_tax_include( gn_header_ck_no )             := lt_set_sale_amount_sum;           -- 売上金額合計--
        gt_head_total_amount( gn_header_ck_no )            := lt_set_pure_amount_sum;           -- 本体金額合計--
        gt_head_sales_consump_tax( gn_header_ck_no )       := lt_set_tax_amount_sum;            -- 消費税金額合計--
        gt_head_consump_tax_class( gn_header_ck_no )       := lt_consum_type;               -- 消費税区分(導出)
        gt_head_tax_code( gn_header_ck_no )                := lt_consum_code;               -- 税金コード(導出)
        gt_head_tax_rate( gn_header_ck_no )                := lt_tax_consum;                -- 消費税率(導出)
        gt_head_performance_by_code( gn_header_ck_no )     := lt_performance_by_code;       -- 成績者コード(成績計上者コード)
        gt_head_sales_base_code( gn_header_ck_no )         := lt_sale_base_code;            -- 売上拠点コード(導出)
        gt_head_card_sale_class( gn_header_ck_no )         := lt_card_sale_class;           -- カード売り区分
--      gt_head_sales_classification( gn_header_ck_no )    := lt_sales_classification;    -- 売上分類区分(伝票区分)
--      gt_head_invoice_class( gn_header_ck_no )           := lt_sales_invoice;           -- 売上伝票区分(伝票分類コード)
        gt_head_sales_classification( gn_header_ck_no )    := lt_sales_invoice;             -- 売上分類区分(伝票区分)
        gt_head_invoice_class( gn_header_ck_no )           := lt_sales_classification;      -- 売上伝票区分(伝票分類コード)
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--      gt_head_receiv_base_code( gn_header_ck_no )        := lt_sale_base_code;            -- 入金拠点コード(導出)
        gt_head_receiv_base_code( gn_header_ck_no )        := lt_cash_receiv_base_code;     -- 入金拠点コード(導出)
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
        gt_head_change_out_time_100( gn_header_ck_no )     := lt_change_out_time_100;       -- つり銭切れ時間100円
        gt_head_change_out_time_10( gn_header_ck_no )      := lt_change_out_time_10;        -- つり銭切れ時間10円
        gt_head_hht_dlv_input_date( gn_header_ck_no )      := gd_input_date;                -- HHT納品入力日時(成型日時)
        gt_head_dlv_by_code( gn_header_ck_no )             := lt_dlv_by_code;               -- 納品者コード
        gt_head_business_date( gn_header_ck_no )           := gd_process_date;              -- 登録業務日付(初期処理取得)
        gt_head_order_source_id( gn_header_ck_no )         := cv_head_order_source_id;      -- 受注ソースID(NULL設定)
        gt_head_order_invoice_number( gn_header_ck_no )    := cv_head_order_invoice_number; -- 注文伝票番号(NULL設定)
        gt_head_order_connection_num( gn_header_ck_no )    := cv_head_order_connection_num; -- 受注関連番号(NULL設定)
        gt_head_ar_interface_flag( gn_header_ck_no )       := cv_head_ar_interface_flag_n;  -- ARインタフェース済フラグ('N'設定)
        gt_head_gl_interface_flag( gn_header_ck_no )       := cv_head_gl_interface_flag_n;  -- GLインタフェース済フラグ('N'設定)
        gt_head_dwh_interface_flag( gn_header_ck_no )      := cv_head_dwh_interface_flag_n; -- 情報システムインタフェース済フラグ('N'設定)
        gt_head_edi_interface_flag( gn_header_ck_no )      := cv_head_edi_interface_flag_n; -- EDI送信済みフラグ('N'設定)
        gt_head_edi_send_date( gn_header_ck_no )           := cv_head_edi_send_date;        -- EDI送信日時(NULL設定)
        gt_head_create_class( gn_header_ck_no )            := cv_head_create_class_vd_d_c;  -- 作成元区分(｢3｣設定)
        gt_head_input_class( gn_header_ck_no )             := lt_input_class;               -- 入力区分
--******************************* 2009/06/01 N.Maeda Var1.14 ADD START ***************************************
        gt_head_open_dlv_date( gn_header_ck_no )           := lt_open_dlv_date;
        gt_head_open_inspect_date( gn_header_ck_no )       := lt_open_inspect_date;
--******************************* 2009/06/01 N.Maeda Var1.14 ADD END   ***************************************
-- Ver.1.28 ADD Start
        gt_head_ttl_sales_amt( gn_header_ck_no )           := lt_ttl_sales_amt;             -- 総販売金額
        gt_head_cs_ttl_sales_amt( gn_header_ck_no )        := lt_cs_ttl_sales_amt;          -- 現金売りトータル販売金額
        gt_head_pp_ttl_sales_amt( gn_header_ck_no )        := lt_pp_ttl_sales_amt;          -- PPカードトータル販売金額
        gt_head_id_ttl_sales_amt( gn_header_ck_no )        := lt_id_ttl_sales_amt;          -- IDカードトータル販売金額
        gt_head_hht_received_flag( gn_header_ck_no )       := lt_hht_received_flag;         -- HHT受信フラグ
-- Ver.1.28 ADD End
        gn_header_ck_no := gn_header_ck_no + 1;
        ln_header_ck_no := ln_header_ck_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          -- ===================
          -- 登録用明細ID取得
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_ck_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
          gt_line_sales_exp_header_id( gn_line_ck_no )     := ln_actual_id;                 -- 販売実績ヘッダID
          gt_line_dlv_invoice_number( gn_line_ck_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- 納品伝票番号
          gt_line_dlv_invoice_l_num( gn_line_ck_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- 納品明細番号
          gt_line_sales_class( gn_line_ck_no )             := gt_accumulation_data(in_data_num).sales_class;           -- 売上区分
          gt_line_red_black_flag( gn_line_ck_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- 赤黒フラグ
          gt_line_item_code( gn_line_ck_no )               := gt_accumulation_data(in_data_num).item_code;             -- 品目コード
          gt_line_standard_qty( gn_line_ck_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- 基準数量
          gt_line_standard_uom_code( gn_line_ck_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- 基準単位
          gt_line_standard_unit_price( gn_line_ck_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- 基準単価
          gt_line_business_cost( gn_line_ck_no )           := gt_accumulation_data(in_data_num).business_cost;         -- 営業原価
          gt_line_sale_amount( gn_line_ck_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- 売上金額
          gt_line_pure_amount( gn_line_ck_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- 本体金額
          gt_line_tax_amount( gn_line_ck_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- 消費税金額
          gt_line_cash_and_card( gn_line_ck_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- 現金・カード併用額
          gt_line_ship_from_subinv_co( gn_line_ck_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- 出荷元保管場所
          gt_line_delivery_base_code( gn_line_ck_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- 納品拠点コード
          gt_line_hot_cold_class( gn_line_ck_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- Ｈ＆Ｃ
          gt_line_column_no( gn_line_ck_no )               := gt_accumulation_data(in_data_num).column_no;             -- コラムNo
          gt_line_sold_out_class( gn_line_ck_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- 売切区分
          gt_line_sold_out_time( gn_line_ck_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- 売切時間
          gt_line_to_calculate_fees_flag( gn_line_ck_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- 手数料計算IF済フラグ
          gt_line_unit_price_mst_flag( gn_line_ck_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- 単価マスタ作成済フラグ
          gt_line_inv_interface_flag( gn_line_ck_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INVインタフェース済フラグ
          gt_line_order_invoice_l_num( gn_line_ck_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- 注文明細番号
          gt_line_not_tax_amount( gn_line_ck_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- 税抜基準単価
          gt_line_delivery_pat_class( gn_line_ck_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- 納品形態区分
          gt_line_dlv_qty( gn_line_ck_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- 納品数量
          gt_line_dlv_uom_code( gn_line_ck_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- 納品単位
          gt_dlv_unit_price( gn_line_ck_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- 納品単価
          gn_line_ck_no := gn_line_ck_no + 1;
        END LOOP line_set_loop;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD START ***************************************
      ELSE
        gn_warn_cnt := gn_warn_cnt + 1;
        gn_wae_data_count := gn_wae_data_count + ln_line_data_count;
--******************************* 2009/05/20 N.Maeda Var1.13 ADD END *****************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
--
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --キー編集関数
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, 
                                         lv_key_data1,
                                         lv_key_name2,
                                         lv_key_data2,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         gv_tkn2,
                                         lv_errbuf,
                                         lv_retcode,
                                         lv_errmsg);
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
--******************************* 2009/04/16 N.Maeda Var1.10 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--******************************* 2009/04/16 N.Maeda Var1.10 DEL END   ***************************************
--#################################  固定例外処理部 START   ####################################
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
  END proc_molded;
--
  /**********************************************************************************
   * Procedure Name   : proc_extract
   * Description      : 対象データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE proc_extract(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_extract'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    --===============================
    -- ユーザ定義ローカル変数
    --===============================
    lv_no_data_msg   VARCHAR2(500);
    lv_err_tab_name  VARCHAR2(500);
--
    -- *** ローカル・カーソル ***
--
  -- VDコラム別取引情報ヘッダ情報
  CURSOR get_header_data_cur
  IS
---- ****************************** 2012/08/06 T.Makuta Var1.24 MOD START ***************************************
----SELECT vch.ROWID,                         -- 行ID
---- ****************************** 2012/08/27 T.Makuta Var1.25 MOD START ***************************************
----SELECT /*+ INDEX(vch XXCOS_VD_COLUMN_HEADERS_N01 */
    SELECT /*+ LEADING(VCH) INDEX(vch XXCOS_VD_COLUMN_HEADERS_N01 */
---- ****************************** 2012/08/27 T.Makuta Var1.25 MOD START ***************************************
           vch.ROWID,                         -- 行ID
---- ****************************** 2012/08/06 T.Makuta Var1.24 MOD END   ***************************************
           vch.order_no_hht,                  -- 受注No.(HHT)
           vch.digestion_ln_number,           -- 枝番
           vch.order_no_ebs,                  -- 受注No.(EBS)
           vch.base_code,                     -- 拠点コード
           vch.performance_by_code,           -- 成績者コード
           vch.dlv_by_code,                   -- 納品者コード
           vch.hht_invoice_no,                -- HHT伝票No. 
           vch.dlv_date,                      -- 納品日
           vch.inspect_date,                  -- 検収日
           vch.sales_classification,          -- 売上分類区分
           vch.sales_invoice,                 -- 売上伝票区分
           vch.card_sale_class,               -- カード売区分
           vch.dlv_time,                      -- 時間
           vch.change_out_time_100,           -- つり銭切れ時間100円
           vch.change_out_time_10,            -- つり銭切れ時間10円
           vch.customer_number,               -- 顧客コード
           vch.dlv_form,                      -- 納品形態
           vch.system_class,                  -- 業態区分
           vch.invoice_type,                  -- 伝票区分
           vch.input_class,                   -- 入力区分
           vch.consumption_tax_class,         -- 消費税区分
           ABS ( vch.total_amount ),          -- 合計金額
           ABS ( vch.sale_discount_amount ),  -- 売上値引額
           ABS ( vch.sales_consumption_tax ), -- 売上消費税額
           ABS ( vch.tax_include ),           -- 税込金額
           vch.keep_in_code,                  -- 預け先コード
           vch.department_screen_class,       -- 百貨店画面種別
           vch.digestion_vd_rate_maked_date,  -- 消化VD掛率作成済年月日
           vch.red_black_flag,                -- 赤黒フラグ
-- Ver.1.28 MOD Start
--           vch.cancel_correct_class           -- 取消・訂正区分
           vch.cancel_correct_class,          -- 取消・訂正区分
           vch.total_sales_amt         AS ttl_sales_amt,      -- 総販売金額
           vch.cash_total_sales_amt    AS cs_ttl_sales_amt,   -- 現金売りトータル販売金額
           vch.ppcard_total_sales_amt  AS pp_ttl_sales_amt,   -- PPカードトータル販売金額
           vch.idcard_total_sales_amt  AS id_ttl_sales_amt,   -- IDカードトータル販売金額
           vch.hht_received_flag       AS hht_received_flag   -- HHT受信フラグ
-- Ver.1.28 MOD End
---- ****************************** 2009/07/29 N.Maeda Var1.15 MOD START ***************************************
    FROM   xxcos_vd_column_headers vch        -- VDコラム別取引情報ヘッダ情報
    WHERE  vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
    AND    vch.input_class   =  cv_input_class_fs_vd_at
    AND    vch.forward_flag  =  cv_forward_flag_no
    AND    EXISTS
            (
              SELECT 'Y'
              FROM   xxcos_vd_column_lines vcl -- VDコラム別取引情報明細情報
              WHERE  vch.order_no_hht = vcl.order_no_hht
              AND    vch.digestion_ln_number = vcl.digestion_ln_number
---- ****************************** 2012/08/06 T.Makuta Var1.24 ADD START ***************************************
              AND    ROWNUM = 1
---- ****************************** 2012/08/06 T.Makuta Var1.24 ADD END   ***************************************
            )
    ORDER BY vch.order_no_hht,vch.digestion_ln_number;
----******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--    FROM   xxcos_vd_column_headers vch,        -- VDコラム別取引情報ヘッダ情報
--           xxcos_vd_column_lines vcl
--    WHERE  vch.order_no_hht = vcl.order_no_hht
--    AND    vch.digestion_ln_number = vcl.digestion_ln_number
--    AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
--    AND    vch.input_class   =  cv_input_class_fs_vd_at
--    AND    vch.forward_flag  =  cv_forward_flag_no
--    GROUP BY vch.ROWID,vch.order_no_hht,vch.digestion_ln_number,vch.order_no_ebs,vch.base_code,
--             vch.performance_by_code,vch.dlv_by_code,vch.hht_invoice_no,vch.dlv_date,
--             vch.inspect_date,vch.sales_classification,vch.sales_invoice,vch.card_sale_class,
--             vch.dlv_time,vch.change_out_time_100,vch.change_out_time_10,vch.customer_number,
--             vch.dlv_form,vch.system_class,vch.invoice_type,vch.input_class,vch.consumption_tax_class,
--             vch.total_amount,vch.sale_discount_amount,vch.sales_consumption_tax,vch.tax_include,
--             vch.keep_in_code,vch.department_screen_class,vch.digestion_vd_rate_maked_date,vch.red_black_flag,
--             vch.cancel_correct_class
--    ORDER BY vch.order_no_hht,vch.digestion_ln_number;
----    FROM   xxcos_vd_column_headers vch        -- VDコラム別取引情報ヘッダ情報
----    WHERE  vch.order_no_hht IN ( SELECT vcl.order_no_hht
----                                 FROM   xxcos_vd_column_lines vcl )
----    AND    vch.digestion_ln_number IN ( SELECT vcl.digestion_ln_number
----                                        FROM   xxcos_vd_column_lines vcl)
----    AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
----    AND    vch.input_class   =  cv_input_class_fs_vd_at
----    AND    vch.forward_flag  =  cv_forward_flag_no
----    ORDER BY vch.order_no_hht,vch.digestion_ln_number
----  FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
-- ****************************** 2009/07/29 N.Maeda Var1.15 MOD START ***************************************
--
  -- VDコラム別取引明細情報
  CURSOR get_lines_data_cur
  IS
    SELECT 
--******************************* 2009/08/12 N.Maeda Ver1.16 ADD START ***************************************
           /*+
            leading(vch)
            use_nl(vcl)
            INDEX ( vch XXCOS_VD_COLUMN_HEADERS_N01 )
            INDEX ( vcl XXCOS_VD_COLUMN_LINES_N01 )
           */
--******************************* 2009/08/12 N.Maeda Ver1.16 ADD END *****************************************
           vcl.order_no_hht,                  -- 受注No.(HHT)
           vcl.line_no_hht,                   -- 行No.(HHT)
           vcl.digestion_ln_number,           -- 枝番
           vcl.order_no_ebs,                  -- 受注No.(EBS)
           vcl.line_number_ebs,               -- 明細番号(EBS)
           vcl.item_code_self,                -- 品名コード(自社)
           vcl.content,                       -- 入数
           vcl.inventory_item_id,             -- 品目ID
           vcl.standard_unit,                 -- 基準単位
           vcl.case_number,                   -- ケース数
           vcl.quantity,                      -- 数量
           vcl.sale_class,                    -- 売上区分
           vcl.wholesale_unit_ploce,          -- 卸単価
           vcl.selling_price,                 -- 売単価
           vcl.column_no,                     -- コラムNo
           vcl.h_and_c,                       -- H/C
           vcl.sold_out_class,                -- 売切区分
           vcl.sold_out_time,                 -- 売切時間
           ABS ( vcl.replenish_number ),      -- 補充数
           vcl.cash_and_card                  -- 現金・カード併用額
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
    FROM   xxcos_vd_column_headers vch,        -- VDコラム別取引情報ヘッダ情報
           xxcos_vd_column_lines vcl
    WHERE  vch.order_no_hht = vcl.order_no_hht
    AND    vch.digestion_ln_number = vcl.digestion_ln_number
    AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
    AND    vch.input_class   =  cv_input_class_fs_vd_at
    AND    vch.forward_flag  =  cv_forward_flag_no
--    FROM   xxcos_vd_column_lines vcl          -- VDコラム別取引明細情報
--    WHERE  vcl.order_no_hht IN ( SELECT vch.order_no_hht
--                                FROM   xxcos_vd_column_headers vch
--                                WHERE  vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
--                                AND    vch.input_class   =  cv_input_class_fs_vd_at
--                                AND    vch.forward_flag  =  cv_forward_flag_no )
--    AND    vcl.digestion_ln_number IN ( SELECT vch.digestion_ln_number
--                                       FROM   xxcos_vd_column_headers vch
--                                       WHERE  vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
--                                       AND    vch.input_class   =  cv_input_class_fs_vd_at
--                                       AND    vch.forward_flag  =  cv_forward_flag_no )
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
    ORDER BY vcl.order_no_hht,vcL.digestion_ln_number,vcl.line_no_hht
  FOR UPDATE NOWAIT;
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
    --==============================================================
    -- VDコラム別取引情報ヘッダ情報取得
    --==============================================================
    BEGIN
      -- 非入力画面登録データ取得
      -- カーソルOPEN
      OPEN  get_header_data_cur;
      -- バルクフェッチ
      FETCH get_header_data_cur BULK COLLECT INTO gt_vd_c_headers_data;
      -- 抽出件数セット
      gn_target_cnt := get_header_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_header_data_cur;
--
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( get_header_data_cur%ISOPEN ) THEN
          CLOSE get_header_data_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_head );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_tab, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( get_header_data_cur%ISOPEN ) THEN
          CLOSE get_header_data_cur;
        END IF;
        lv_err_tab_name := xxccp_common_pkg.get_msg ( cv_application, cv_msg_tab_name_colum_head );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err,
                                             cv_tkn_tab, lv_err_tab_name );
        RAISE extract_err_expt;
    END;
    
--
    --==============================================================
    -- VDコラム別取引明細情報取得
    --==============================================================
    BEGIN
      -- カーソルOPEN
      OPEN  get_lines_data_cur;
      -- バルクフェッチ
      FETCH get_lines_data_cur BULK COLLECT INTO gt_vd_c_lines_data;
      -- 抽出件数セット
      gn_target_lines_cnt := get_lines_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_lines_data_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN

        IF( get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_line );
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum );
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_tab, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF(get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
        lv_err_tab_name := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_line );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err,
                                             cv_tkn_tab, lv_err_tab_name);
        RAISE extract_err_expt;
    END;
--
    -- 対照データが存在しない場合
    IF ( ov_retcode <> cv_status_error ) AND ( gn_target_cnt = 0 ) OR ( gn_target_lines_cnt = 0 )THEN
      lv_no_data_msg := xxccp_common_pkg.get_msg ( cv_application, cv_msg_target_no_data );
      ov_errmsg := lv_no_data_msg;
      ov_errbuf := lv_no_data_msg;
--      lv_errbuf := lv_no_data_msg;
    END IF;
--
  EXCEPTION
    -- ロック取得エラー
    WHEN lock_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- 抽出エラー
    WHEN extract_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--##############################################################################################
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( get_header_data_cur %ISOPEN ) THEN
          CLOSE get_header_data_cur;
      END IF;
      IF ( get_lines_data_cur%ISOPEN ) THEN
        CLOSE get_lines_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( get_header_data_cur %ISOPEN ) THEN
          CLOSE get_header_data_cur;
      END IF;
      IF ( get_lines_data_cur%ISOPEN ) THEN
        CLOSE get_lines_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_extract;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    lv_max_date      VARCHAR2(50);      -- MAX日付
-- == 2010/09/09 V1.22 Added START ===============================================================
    lv_para_msg     VARCHAR2(100);      --  パラメータ出力
-- == 2010/09/09 V1.22 Added END   ===============================================================
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
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    gv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
    --プロファイルエラー
    IF (gv_orga_code IS NULL) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 共通関数＜在庫組織ID取得＞の呼び出し
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( gv_orga_code );
--
    -- 在庫組織ID取得エラーの場合
    IF ( gn_orga_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 業務処理日取得
    --==============================================================
     gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_process_date := TRUNC( gd_process_date );
--
    --==================================
    -- プロファイルの取得(XXCOS:MAX日付)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_short_day );
    END IF;
--
    --====================================
    -- プロファイルの取得(会計帳簿ID)
    --====================================
    gv_bks_id := FND_PROFILE.VALUE( cv_prf_bks_id ); 
--
    IF ( gv_bks_id IS NULL) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_gl_books);
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- == 2010/09/09 V1.22 Added START ===============================================================
    --==================================
    -- パラメータ出力
    --==================================
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                       , iv_name          =>  cv_msg_xxcos_10260
                       , iv_token_name1   =>  cv_tkn_xxcos_10260
                       , iv_token_value1  =>  gv_prm_gen_err_out_flag
                     );
--
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_para_msg
    );
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- == 2010/09/09 V1.22 Modified START ===============================================================
--    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
      iv_gen_err_out_flag   IN  VARCHAR2            --  汎用エラーリスト出力フラグ
    , ov_errbuf             OUT NOCOPY VARCHAR2     --  エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT NOCOPY VARCHAR2     --  リターン・コード             --# 固定 #
    , ov_errmsg             OUT NOCOPY VARCHAR2     --  ユーザー・エラー・メッセージ --# 固定 #
  )
-- == 2010/09/09 V1.22 Modified END   ===============================================================
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_target_lines_cnt := 0;
    gn_line_cnt   := 0;
-- == 2010/09/09 V1.22 Added START ===============================================================
    gn_msg_cnt                :=  0;                                --  汎用エラーリスト出力件数
    gv_prm_gen_err_out_flag   :=  iv_gen_err_out_flag;              --  汎用エラーリスト出力フラグ
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
    -- ===============================
    -- proc_init(初期処理)
    -- ===============================
    proc_init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- ================================
    -- proc_extract(対象データ抽出)
    -- ================================
    proc_extract(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- 対照データが存在する場合
    IF (gn_target_cnt <> 0) AND (gn_target_lines_cnt <> 0) THEN
        -- ================================
        -- proc_molded(VD納品データ作成成型処理)
        -- ================================
        proc_molded(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--      END IF;
--
      IF ( gt_line_sales_exp_line_id.COUNT <> 0) AND ( gt_head_id.COUNT <> 0 ) THEN
        -- ================================
        -- proc_data_insert_head(販売実績データ登録処理(ヘッダ))
        -- ================================
        proc_data_insert_head(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================
        -- proc_data_insert_line(販売実績データ登録処理(明細))
        -- ================================
        proc_data_insert_line(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================
        -- proc_data_update(取得元テーブルフラグ更新)
        -- ================================
        proc_data_update(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.10 ADD START ***************************************
    IF ( gn_wae_data_num <> 0 ) THEN
      ov_retcode := cv_status_warn;
      <<war_msg_loop>>
      FOR war_num IN 1..gn_wae_data_num LOOP
        --メッセージ生成
        lv_errmsg := gt_msg_war_data(war_num);
        lv_errbuf := lv_errmsg;
        --メッセージ出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg);
        --ログ出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
              --空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
          );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => ''
          );
      END LOOP war_msg_loop;
    END IF;
--******************************* 2009/04/16 N.Maeda Var1.10 ADD END   ***************************************
-- == 2010/09/09 V1.22 Added START ===============================================================
      IF (gn_msg_cnt <> 0) THEN
        --  汎用エラーリスト出力対象有りの場合
        --  ===============================
        --    A-8.エラー情報登録処理
        --  ===============================
        ins_err_msg(
            ov_errbuf       =>  lv_errbuf     -- エラー・メッセージ           --# 固定 #
          , ov_retcode      =>  lv_retcode    -- リターン・コード             --# 固定 #
          , ov_errmsg       =>  lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error_ins) THEN
          -- INSERT時エラー
          RAISE global_ins_key_expt;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
    ELSIF ( lv_retcode <> cv_status_error) 
      AND ( gn_target_cnt = 0 ) 
      AND ( gn_target_lines_cnt = 0 )THEN
      ov_retcode := cv_status_warn;
--      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errbuf;
    END IF;
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
-- == 2010/09/09 V1.22 Added START ===============================================================
    --*** エラーリスト追加例外ハンドラ ***
    WHEN global_ins_key_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
-- == 2010/09/09 V1.22 Added END   ===============================================================
--
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
-- == 2010/09/09 V1.22 Added START ===============================================================
  , iv_gen_err_out_flag   IN  VARCHAR2      --  汎用エラーリスト出力フラグ
-- == 2010/09/09 V1.22 Added END   ===============================================================
  )
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
-- == 2010/09/09 V1.22 Modified START ===============================================================
--    submain(
--       lv_errbuf   -- エラー・メッセージ           --# 固定 #
--      ,lv_retcode  -- リターン・コード             --# 固定 #
--      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
--    );
    submain(
        iv_gen_err_out_flag   =>  NVL(iv_gen_err_out_flag, cv_no)         --  汎用エラーリスト出力フラグ
      , ov_errbuf             =>  lv_errbuf                               -- エラー・メッセージ           --# 固定 #
      , ov_retcode            =>  lv_retcode                              -- リターン・コード             --# 固定 #
      , ov_errmsg             =>  lv_errmsg                               -- ユーザー・エラー・メッセージ --# 固定 #
    );
-- == 2010/09/09 V1.22 Modified END   ===============================================================
--
--******************************* 2009/06/01 N.Maeda Var1.14 ADD START ***************************************
    IF ( lv_retcode = cv_status_error) THEN
      -- エラー時登録件数初期化
      gn_normal_cnt := 0;
      gn_line_cnt   := 0;
    END IF;
--******************************* 2009/06/01 N.Maeda Var1.14 ADD  END  ***************************************
--
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF (lv_retcode <> cv_status_normal) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      IF ( lv_retcode <> cv_status_warn ) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => ''
          );
      END IF;
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
    --ヘッダ対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_target
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
--    --明細対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_count_li_target
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_target_lines_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
    --ヘッダ成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_update
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
--    --明細成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_count_li_update
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_line_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
--******************************* 2009/06/01 N.Maeda Var1.14 ADD START ***************************************
    --ヘッダスキップ件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_skip_h
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --明細スキップ件数
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_skip_l
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_wae_data_count)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--******************************* 2009/06/01 N.Maeda Var1.14 DEL END *****************************************
    --
--******************************* 2009/06/01 N.Maeda Var1.14 ADD END   ***************************************
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
END XXCOS001A03C;
/
