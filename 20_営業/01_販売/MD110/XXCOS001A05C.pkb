CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A05C (body)
 * Description      : 出荷確認処理（HHT納品データ）
 * MD.050           : 出荷確認処理(MD050_COS_001_A05)
 * Version          : 1.27
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_ins_gen_err_list  汎用エラーリスト作成(A-13)
 *  set_gen_err_list       汎用エラーリスト出力情報設定(A-12)
 *  get_fiscal_period_from 有効会計期間FROM取得関数(A-10)
 *  proc_inp_molded_hht    販売実績データ(納品伝票入力画面)成型処理(A-9)
 *  proc_flg_update        取得元テーブルフラグ更新(A-10)
 *  proc_om_close          OMクローズ処理(A-7)
 *  proc_insert            販売実績データ登録処理(A-6)
 *  proc_molded_trans      販売実績データ（入出庫）成型処理(A-5)
 *  proc_molded_edi        販売実績データ(EDI)成型処理(A-4)
 *  proc_molded_hht        販売実績データ(HHT)成型処理(A-3)
 *  proc_extract           データ抽出処理(A-2)
 *  proc_init              初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   N.Maeda          新規作成
 *  2009/2/3      1.1   N.Maeda          百貨店入力区分判断条件の変更
 *                                       従業員ビューの拠点取得条件の追加
 *                                       納品伝票入力画面登録データ成型処理(A-9)の追加
 *  2009/02/17    1.2   N.Maeda          消費税率取得条件に有効フラグを追加
 *                                       get_msgのパッケージ名修正
 *  2009/02/18    1.3   N.Maeda          顧客情報取得時の条件変更(｢duns_number｣⇒｢duns_number_c｣)
 *  2009/02/20    1.4   N.Maeda          パラメータのログファイル出力対応
 *  2009/03/18    1.5   T.Kitajima       [T1_0066] HHT納品データの販売実績連携時における設定項目の不備
 *                                       [T1_0078] 金額の端数計算が正しく行われていない
 *  2009/03/23    1.6   N.Maeda          [T1_0078] 金額の端数発生時処理の修正
 *  2009/04/03    1.7   N.Maeda          [T1_0256] HHT百貨店保管場所抽出条件を修正
 *  2009/04/07    1.8   N.Maeda          [T1_0248] HHt百貨店入力区分がnullでない時の判定内容を変更
 *  2009/04/09    1.9   N.Maeda          [T1_0401_427]
 *                                                 外税、内税(伝票課税)時の売上金額の計算方法修正
 *                                                 外税時の売上金額合計の計算方法修正
 *                                                 入出庫データの販売実績(納品数量)設定値に総本数を設定
 *  2009/04/14    1.10  N.Maeda          [T1_0532] ヘッダ消費税金額合計算出値の代入値修正
 *  2009/04/14    1.11  N.Maeda          [T1_0537_0544_558]入出庫データの販売実績(基準数量)設定値に総本数を設定
 *                                                 入出庫データ登録時の納品明細番号をシーケンス取得からヘッダ毎の附番へ変更
 *                                                 百貨店HHT時の保管場所取得方法の変更
 *  2009/04/16    1.12  N.Maeda          [T1_0350_0447_0450_0589_0712]入金拠点コード取得、販売実績入金拠点コードへの登録の追加
 *                                                 入出庫データヘッダカウント件数出力追加
 *                                                 納品伝票入力画面登録データ抽出条件変更
 *                                                 トランザクション制御修正
 *                                                 対象データ抽出条件の変更
 *  2009/05/12    1.13  N.Maeda          [T1_0768] 納品伝票画面登録データのOM受注クローズ処理追加
 *  2009/05/13    1.14  N.Maeda          [T1_0969_1005] 入出庫データの顧客マスタ取得情報の変更、出荷拠点コードの設定項目変更
 *                                                      見本時納品伝票区分取得項目変更
 *  2009/05/18    1.15  N.Maeda          [T1_0853] 取消・訂正区分設定方法変更
 *                                       [T1_0547] 消費税区分:2の時ヘッダ売上合計金額設定値修正
 *                                       [T1_0855] 納品伝票区分取得条件変更
 *                                       [T1_1041] 消費税区分:1ヘッダ売上合計金額設定値修正
 *                                       [T1_1091] 会計期間オープン確認処理追加
 *                                       [T1_1121] 消費税端数処理の修正
 *                                       [T1_1122] 切上端数処理の修正
 *                                       [T1_1040] 消費税区分:3ヘッダ売上、本体金額合計設定値修正
 *                                       [T1_0982] ログスキップ件数追加、保管場所エラー時出力キーデータ追加
 *                                       [T1_0384] 登録エラー時出力内容修正
 *                                       [T1_1053] T1_0768修正不備-インデックスのカウントアップ処理を追加
 *                                       [T1_1269] 消費税区分:3税抜基準単価算出方法修正
 *  2009/06/01    1.16  N.Maeda          [T1_1279] 件数ログ出力項目変更
 *                                       [T1_1332] 消費税区分:外税、内税(伝票課税)の時の消費税端数処理修正
 *  2009/06/23    1.17  N.Maeda          [T1_1438] 排他制御処理修正
 *  2009/08/06    1.18  N.Maeda          [0000424] PT考慮
 *  2009/08/10    1.18  N.Maeda          [0000424] レビュー指摘対応
 *  2009/08/12    1.19  N.Maeda          [0001010] 従業員情報取得条件追加
 *  2009/08/21    1.20  N.Maeda          [0001141] 前月売上拠点の考慮追加
 *  2009/09/04    1.21  N.Maeda          [0001211] 消費税関連項目取得基準日修正
 *  2009/10/13    1.22  N.Maeda          [0001381] 受注明細の販売実績連携済みフラグ追加対応
 *  2009/10/30    1.23  M.Sano           [0001373] 参照View変更[xxcos_rs_info_v ⇒ xxcos_rs_info2_v]
 *  2009/12/08    1.24  M.Fujinuma       [E_本稼動_00224]値引のみのヘッダーデータに対応
 *  2009/12/21    1.24  N.Maeda          [E_本稼動_00224] 値引きヘッダー納品画面登録情報対応
 *  2010/02/02    1.25  Y.Kuboshima      [E_T4_00195] 会計カレンダをAR ⇒ INVに修正
 *  2010/03/01    1.26  N.Maeda          [E_本稼動_01601] 受注取込納品伝票入力画面以外からのデータに対して
 *                                                 INVカレンダのチェック処理追加
 *                                       [E_本稼動_01764] 入出庫データ(見本)取込時、ヘッダ作成ブレイク条件追加
 *  2010/09/02    1.27  K.Kiriu          [E_本稼動_02635] 汎用エラーリスト出力対応
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
  -- 対象データ抽出エラー
  data_extract_err_expt    EXCEPTION;
  -- 抽出対象なしエラー
  no_data_extract          EXCEPTION;
  -- 納品形態区分エラー
  delivered_from_err_expt  EXCEPTION;
  -- データ登録エラー
  insert_err_expt          EXCEPTION;
  -- 更新エラー
  updata_err_expt          EXCEPTION;
  -- クーローズ処理エラー
  no_complet_expt          EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOS001A05C';         -- パッケージ名
  cv_application              CONSTANT VARCHAR2(5)   := 'XXCOS';                -- アプリケーション名
  cv_application_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';                -- アプリケーション名
  cv_prf_orga_code            CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_disc_item_code           CONSTANT VARCHAR2(50)  := 'XXCOS1_DISCOUNT_ITEM_CODE'; -- 値引き品目コード
  cv_org_id                   CONSTANT VARCHAR2(10)  := 'ORG_ID';               -- MO:営業単位取得用コード
  cv_prf_max_date             CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';      -- XXCOS:MAX日付
  cv_prf_bks_id               CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';     -- GL会計帳簿ID
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  --パラメータ出力
  cv_msg_param                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10260';     -- パラメータ出力
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
  -- エラーコード
  cv_loc_err                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';     -- ロックエラー
  cv_msg_extract_err          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001';     -- 抽出エラー
  cv_msg_pro                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';     -- プロファイル取得エラー
  cv_msg_target_no_data       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';     -- 入力対象データなしメッセージ
  cv_msg_max_date             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';     -- XXCOS:MAX日付
  cv_msg_orga                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';     -- 在庫組織ID取得エラー
  cv_msg_date                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';     -- 業務処理日取得エラー
  cv_msg_orga_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';     -- 在庫組織コード
  cv_msg_no_data              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';     -- マスタデータ取得エラー
  cv_msg_delivered_from_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10104';     -- 納品形態区分エラー
  cv_msg_tab_ins_err          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10351';     -- 登録エラー
  cv_msg_update_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';     -- 更新エラー
  cv_msg_close_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10252';     -- OM受注クローズエラー
  cv_msg_b_k_ping             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10253';     -- 記帳エラー
  -- 文字列取得用コード(テーブル名)
  cv_msg_selse_unit           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';     -- 営業単位
  cv_msg_disc_item            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00090';     -- 売上値引き品目コード
  cv_msg_dlv_head             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10031';     -- 納品ヘッダテーブル
  cv_msg_dlv_line             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10032';     -- 納品明細テーブル
  cv_msg_transactions         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00093';     -- HHT入出庫一時表
  cv_msg_cus_mst              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';     -- 顧客マスタ
  cv_msg_lookup_mst           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- 参照コードマスタ
-- ************ 2009/09/04 1.21 N.Maeda MOD START ************ --
--  cv_ar_tax_mst      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00067';            -- AR消費税マスタ
  cv_ar_tax_mst      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';              -- 消費税VIEW
-- ************ 2009/09/04 1.21 N.Maeda MOD  END  ************ --
  cv_inv_item_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';     -- 品目マスタ
  cv_location_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00052';     -- 保管場所マスタ
  cv_emp_data_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00068';     -- 従業員情報VIEW
  cv_om_order                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00128';     -- OM受注情報
  cv_msg_tab_xxcos_sal_exp_head CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00086';    -- 販売実績ヘッダ
  cv_msg_tab_xxcos_sal_exp_line CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00087';    -- 販売実績明細
  cv_msg_dlv_tab              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00172';     -- 納品テーブル
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  cv_msg_tab_xxcos_gen_err_list CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00213';    -- 汎用エラーリスト
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
  -- 文字列取得用コード(カラム名)
  cv_msg_cus_type             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00074';     -- 顧客区分
  cv_msg_cus_code             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00053';     -- 顧客コード
-- ************ 2009/09/04 1.21 N.Maeda MOD START ************ --
--  cv_msg_lookup_code CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00082';            -- 参照コード
  cv_msg_lookup_code CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00189';              -- 参照コード
-- ************ 2009/09/04 1.21 N.Maeda MOD  END  ************ --
  cv_msg_lookup_type          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';     -- 参照タイプ
  cv_msg_lookup_tax           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00076';     -- 消費税コード（参照コードマスタDFF2)
  cv_msg_item_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';     -- 品目コード
  cv_msg_base_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';     -- 拠点コード
  cv_msg_org_id               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';     -- 在庫組織ID
  cv_msg_type                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00077';     -- タイプ
  cv_msg_code                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00078';     -- コード
  cv_msg_location_type        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00079';     -- 保管場所区分
  cv_msg_dlv                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';     -- 納品者コード
  cv_msg_lookup_inp           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00081';     -- 参照コード（入力区分）
  cv_msg_lookup_rec_type      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00135';     -- 参照コード（レコード種別）
  cv_msg_gl_books             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';     -- GL会計帳簿
  cv_order_no                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00129';     -- 受注番号
  cv_order_s_name             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10251';     -- EDI受注
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  cv_msg_invoice_no           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00131';     -- 伝票番号
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
--******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
  cv_data_loc                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00184';     -- 対象データロック中
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END   ***************************************
-- ************ 2009/09/04 1.21 N.Maeda MOD START ************ --
  cv_msg_order_num_hht    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00191';
  cv_msg_digestion_number CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00192';
-- ************ 2009/09/04 1.21 N.Maeda MOD  END  ************ --
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  -- 汎用エラーリスト出力用キー項目
  ct_msg_xxcos_00216          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00216';     --キー項目（受注番号、基準日、伝票番号、顧客コード）
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
  -- 文字列取得用コード(共通API名称)
  cv_close_api                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11532';     -- 受注クローズAPI
  -- メッセージ出力
  cv_msg_count_he_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';     -- 納品ヘッダ対象件数
--  cv_msg_count_li_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00142';     -- 納品明細対象件数
  cv_msg_count_he_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00143';     -- 販売実績ヘッダ登録成功件数
--  cv_msg_count_li_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00144';     -- 販売実績明細登録成功件数
--******************************* 2009/06/01 N.Maeda Var1.16 ADD START ***************************************
--  cv_msg_disc_count           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00179';   -- 値引明細件
--  cv_msg_truns_count          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00182';   -- 入出庫一時表カウント
  cv_msg_truns_create_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00183';     -- 入出庫一時表ヘッダ生成カウント
--******************************* 2009/05/01 N.Maeda Var1.16 ADD END   ***************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  cv_past_sale_base_get_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00188';
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
-- ************ 2009/10/13 N.Maeda ADD START *********** --
  cv_order_line_all_name        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10254';
  cv_order_lock_err             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10255';
  cv_bookd_out_msg              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10256';
  cv_bookd_err_msg              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10257';
-- ************ 2009/10/13 N.Maeda ADD  END  *********** --
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
  cv_msg_invoice_date_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10259';
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--  ct_msg_fiscal_period_err    CONSTANT fnd_new_messages.message_name%TYPE
--                                       :=  'APP-XXCOS1-00175';               -- 会計期間取得エラー
  ct_msg_fiscal_period_err      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00217'; -- 会計期間取得エラー
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
  ct_msg_dlv_by_code          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';  -- 納品者コード
  ct_msg_keep_in_code         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00176';  -- 預け先コード
  cv_msg_skip_h               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00177';  -- ヘッダスキップ件数
  cv_msg_skip_l               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00178';  -- 明細スキップ
  cv_tkn_account_name         CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- 会計期間種別
  cv_tkn_order_number         CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- 受注番号
  cv_tkn_base_date            CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- 基準日
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
  -- トークン
  cv_tkn_profile              CONSTANT VARCHAR2(20)  := 'PROFILE';              -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                -- テーブル名
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           -- トークン'TABLE_NAME'
  cv_tkn_table_na             CONSTANT VARCHAR2(20)  := 'TABLE _NAME';          -- トークン'TABLE _NAME'
  cv_key_data                 CONSTANT VARCHAR2(20)  := 'KEY_DATA';             -- トークン'KEY_DATA'
  cv_tkn_api_name             CONSTANT VARCHAR2(20)  := 'API_NAME';             -- 共通関数名
  cv_err_msg                  CONSTANT VARCHAR2(20)  := 'ERR_MSG';              -- 共通関数エラーメッセージ
  cv_count_num                CONSTANT VARCHAR2(20)  := 'COUNT';                -- カウント数
  cv_line_number              CONSTANT VARCHAR2(20)  := 'LINE_NUMBER';          -- 明細番号
--******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
  cv_tkn_gen_err_out_flag     CONSTANT VARCHAR2(20)  := 'GEN_ERR_OUT_FLAG';     -- 汎用エラーリスト出力フラグ
  cv_digestion_ln_number      CONSTANT VARCHAR2(20)  := 'DIGESTION_LN_NUMBER';  -- 枝番
  cv_invoice_no               CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- HHT伝票番号
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END   ***************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  cv_cust_code     CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_dlv_date      CONSTANT VARCHAR2(20)  := 'DLV_DATE';
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
-- ************ 2009/10/13 N.Maeda ADD START *********** --
  cv_order_number_ebs       CONSTANT VARCHAR2(20) := 'ORDER_NUMBER_EBS';
  cv_bookd_data             CONSTANT VARCHAR2(20) := 'BOOKD_DATA';
-- ************ 2009/10/13 N.Maeda ADD  END  *********** --
  -- データ取得用固定値
--  cn_cust_s                   CONSTANT NUMBER  := 30;                           -- 顧客
--  cn_cust_v                   CONSTANT NUMBER  := 40;                           -- 上様
--  cn_cost_p                   CONSTANT NUMBER  := 50;                           -- 休止
  cv_cust_s                   CONSTANT VARCHAR2(2)  := '30';                    -- 顧客
  cv_cust_v                   CONSTANT VARCHAR2(2)  := '40';                    -- 上様
  cv_cost_p                   CONSTANT VARCHAR2(2)  := '50';                    -- 休止
  cn_api_ver_num              CONSTANT NUMBER  := 1.0;                          -- 受注標準APIバージョン(1.0)
  cv_fs_vd_s                  CONSTANT VARCHAR2(10)  := '24';                   -- 業態区分(フルサービス(消化)VD)
  cv_fs_vd                    CONSTANT VARCHAR2(10)  := '25';                   -- 業態区分(フルサービスVD)
  cv_input_delivery           CONSTANT VARCHAR2(10)  := '1';                    -- 入力区分(納品入力)
  cv_input_return             CONSTANT VARCHAR2(10)  := '2';                    -- 入力区分(返品入力)
  cv_input_vd_return          CONSTANT VARCHAR2(10)  := '4';                    -- 入力区分(自販機返品)
  cv_input_fs_vd_return       CONSTANT VARCHAR2(10)  := '5';                    -- 入力区分(フルVD納品･自動吸上)
  cv_untreated_flg            CONSTANT VARCHAR2(1)  := '0';                    -- 販売実績連携済みフラグ(未処理)
--  cv_order_no_ebs_hht         CONSTANT VARCHAR2(10)  := '0';                    -- 受注No（EBS）(HHT伝票)
  cv_record_type_sample       CONSTANT VARCHAR2(10)  := '40';                   -- レコード種別(見本)
  cv_customer_type_c          CONSTANT VARCHAR2(10)  := '10';                   -- 顧客区分(顧客)
  cv_customer_type_u          CONSTANT VARCHAR2(10)  := '12';                   -- 顧客区分(上様)
--  cv_consum_code_out_tax      CONSTANT VARCHAR2(10)  := '0';                    -- 税コード(外税)
--  cv_consum_code_no_tax       CONSTANT VARCHAR2(10)  := '3';                    -- 税コード(非課税)
  cv_depart_screen_class_base CONSTANT VARCHAR2(10)  := '0';                    -- HHT百貨店画面種別(拠点)
  cv_depart_screen_class_dep  CONSTANT VARCHAR2(10)  := '2';                    -- HHT百貨店画面種別(百貨店)
  cv_bace_branch              CONSTANT VARCHAR2(10)  := '1';                    -- 顧客区分(拠点)
  cv_depart_type              CONSTANT VARCHAR2(10)  := '1';                    -- HHT百貨店入力区分(百貨店)
  cv_depart_type_k            CONSTANT VARCHAR2(10)  := '2';                    -- HHT百貨店入力区分(百貨店_拠点)
  cv_input_class_eos          CONSTANT VARCHAR2(10)  := '1';                    -- 納品入力・EOS伝票入力
  cv_input_class_rt           CONSTANT VARCHAR2(10)  := '2';                    -- 返品入力
  cv_input_class_vd           CONSTANT VARCHAR2(10)  := '3';                    -- 自販機売上
  cv_input_class_vd_rt        CONSTANT VARCHAR2(10)  := '4';                    -- 自販機返品
  cv_sales_st_class           CONSTANT VARCHAR2(10)  := '1';                    -- 売上区分(通常)
  cv_sales_class              CONSTANT VARCHAR2(10)  := '6';                    -- 売上区分(見本)
  cv_forward_flag_alr         CONSTANT VARCHAR2(10)  := '2';                    -- 連携済みフラグ(連携済み)
  cv_standard_qty             CONSTANT VARCHAR2(10)  := '0';                    -- 基準数量(0)
  cv_standard_unit_price      CONSTANT VARCHAR2(10)  := '0';                    -- 基準単価(0)
  cv_sale_amount              CONSTANT VARCHAR2(10)  := '0';                    -- 売上金額(0)
  cv_pure_amount              CONSTANT VARCHAR2(10)  := '0';                    -- 本体金額(0)
  cv_tax_amount               CONSTANT VARCHAR2(10)  := '0';                    -- 消費税金額(0)
  cv_cash_and_card            CONSTANT VARCHAR2(10)  := '0';                    -- 現金・カード併用額(0)
  cv_not_tax_amount           CONSTANT VARCHAR2(10)  := '0';                    -- 税抜基準単価(0)
  cv_sample_if_flag           CONSTANT VARCHAR2(1)   := 'N';                    -- 見本転送済みフラグ(未転送)
  -- 元データ消費税区分
  cv_non_tax                  CONSTANT VARCHAR(10)  := '0';                     -- 非課税
  cv_out_tax                  CONSTANT VARCHAR(10)  := '1';                     -- 外税
  cv_ins_slip_tax             CONSTANT VARCHAR(10)  := '2';                     -- 内税（伝票課税）
  cv_ins_bid_tax              CONSTANT VARCHAR(10)  := '3';                     -- 内税（単価込み）
  --
  cn_cons_tkn_zero            CONSTANT NUMBER  := 0;                            -- '0'
  cv_xxcos1_cust_site_use_code CONSTANT VARCHAR2(50)  := 'XXCOS1_CUST_SITE_USE_CODE'; -- 使用区分特定マスタ
  cv_xxcos_001_ship           CONSTANT VARCHAR2(50)  := 'XXCOS_001_SHIP';             -- 請求先
  cv_lookup_type              CONSTANT VARCHAR2(50)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';  -- 消費税区分
  cv_xxcos1_cons_tax_no       CONSTANT VARCHAR2(50)  := 'XXCOS1_CONS_TAX_NO_APPLICABLE'; -- 消費税区分(対象外)
  cv_xxcos1_hokan_mst_001_a05 CONSTANT VARCHAR2(50)  := 'XXCOS1_HOKAN_TYPE_MST_001_A05'; -- 保管場所分類特定マスタ
  cv_xxcos_001_a05_01         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_01';            -- 通常拠点
  cv_xxcos_001_a05_05         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_05';            -- 営業車
  cv_xxcos_001_a05_09         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_09';            -- 百貨店預け先
  cv_xxcos1_input_class       CONSTANT VARCHAR2(50)  := 'XXCOS1_INPUT_CLASS';          -- 入力区分
  cv_xxcoi1_hht_inv_data_div  CONSTANT VARCHAR2(50)  := 'XXCOI1_HHT_INV_DATA_DIV';     -- 入出庫T-レコード種別
--
  cv_tkn_oeol                 CONSTANT VARCHAR2(10) := 'OEOL';                         -- クローズ関数用定数
  cv_xxcos_r_standard_line    CONSTANT VARCHAR2(50) := 'XXCOS_R_STANDARD_LINE:BLOCK';  -- クローズ関数用定数
  cv_status_booked            CONSTANT VARCHAR2(10) := 'BOOKED';                -- ヘッダステータス(記帳済み) 
  cv_status_type_can          CONSTANT VARCHAR2(10) := 'CANCELLED';             -- ステータス(キャンセル)
  cv_status_type_clo          CONSTANT VARCHAR2(10) := 'CLOSE';                 -- ステータス(クローズ)
--  cv_tkn_ja                   CONSTANT VARCHAR2(10) := 'JA';                    -- トークン'JA'
  cv_tkn_yes                  CONSTANT VARCHAR2(10)  := 'Y';                    -- トークン'Y'
  cv_tkn_no                   CONSTANT VARCHAR2(10)  := 'N';                    -- トークン'N'
  -- その他トークン
  cv_con_char                 CONSTANT VARCHAR2(5)  := ',';                     -- カンマ
  cv_space_char               CONSTANT VARCHAR2(5)  := ' ';                     -- スペース
  cv_key_name_null            CONSTANT VARCHAR2(5)  := NULL;                    -- キーネーム「NULL」
  cv_tkn_null                 CONSTANT VARCHAR2(5)  := NULL;                    -- トークン｢NULL｣
  cv_tkn_n                    CONSTANT VARCHAR2(5)  := 'N';                     -- トークン｢N｣
  cv_stand_date               CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS'; -- 日時形式
  cv_short_day                CONSTANT VARCHAR2(25) := 'YYYY/MM/DD';            -- 日付形式
  cv_short_time               CONSTANT VARCHAR2(25) := 'HH24:MI:SS';            -- 時間形式
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  cv_month_type                  CONSTANT VARCHAR(25)  := 'YYYY/MM';
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
  cv_tkn_ti                   CONSTANT VARCHAR(10)  := ':';                     -- コロン
  cv_amount_up                CONSTANT VARCHAR(5)   := 'UP';                    -- 消費税_端数(切上)
  cv_amount_down              CONSTANT VARCHAR(5)   := 'DOWN';                  -- 消費税_端数(切捨て)
  cv_amount_nearest           CONSTANT VARCHAR(10)  := 'NEAREST';               -- 消費税_端数(四捨五入)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--  cn_red_black_flag_stand     CONSTANT NUMBER  := 0;                            -- 赤黒フラグ(通常)
  cv_red_black_flag_stand     CONSTANT VARCHAR(1)  := '1';                            -- 赤黒フラグ(通常)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
  cv_stand_class              CONSTANT VARCHAR(10)  := NULL;                    -- 取消・訂正区分(通常)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--  cv_red_black_flag_correct   CONSTANT VARCHAR(10)  := '1';                     -- 赤黒フラグ(訂正)
  cv_red_black_flag_correct   CONSTANT VARCHAR(10)  := '0';                     -- 赤黒フラグ(訂正)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
  cn_correct_class            CONSTANT NUMBER  := 1;                            -- 取消・訂正区分(訂正)
  cn_cancel_class             CONSTANT NUMBER  := 2;                            -- 取消・訂正区分(取消)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--  cv_black_flag               CONSTANT NUMBER  := '1';                      -- 赤・黒フラグ(黒)
--  cv_red_flag                 CONSTANT NUMBER  := '0';                      -- 赤・黒フラグ(赤)
  cv_black_flag               CONSTANT VARCHAR(1)  := '1';                      -- 赤・黒フラグ(黒)
  cv_red_flag                 CONSTANT VARCHAR(1)  := '0';                      -- 赤・黒フラグ(赤)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
  cn_tkn_zero                 CONSTANT NUMBER  := 0;                            -- トークン｢0｣
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--  cn_tkn_shipping_chk         CONSTANT NUMBER  := 4;                            -- 作業区分(出荷確認処理)
  cv_tkn_shipping_chk         CONSTANT VARCHAR(2)  := '4';                            -- 作業区分(出荷確認処理)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
  cn_disc_standard_qty        CONSTANT NUMBER  := 0;                            -- 値引基準数量
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  --AR会計期間区分値
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD START ***********************************
--  cv_fiscal_period_ar         CONSTANT  VARCHAR2(2) := '02';     --AR
  cv_fiscal_period_inv        CONSTANT  VARCHAR2(2) := '01';     --INV
  cv_fiscal_period_tkn_inv    CONSTANT  VARCHAR2(3) := 'INV';    --INV
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD END *************************************
  gn_wae_data_count           NUMBER := 0;                       -- 警告件数カウント
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
-- ********** 2009/08/06 1.18 N.Maeda ADD START ***************** --
  ct_user_lang                CONSTANT  fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- ********** 2009/08/06 1.18 N.Maeda ADD  END  ***************** --
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  --汎用エラーリスト用
  cv_msg_branch_num_01        CONSTANT  VARCHAR2(2) := '01';  --メッセージ名枝番：01
  cv_msg_branch_num_02        CONSTANT  VARCHAR2(2) := '02';  --メッセージ名枝番：02
  cv_msg_branch_num_03        CONSTANT  VARCHAR2(2) := '03';  --メッセージ名枝番：03
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 納品ヘッダデータ格納用変数
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START *************************************
  TYPE g_rec_dlv_head_data IS RECORD
    (
     row_id                       ROWID,                                          -- 行ID
     order_no_hht                 xxcos_dlv_headers.order_no_hht%TYPE,            -- 受注No.(HHT)
     digestion_ln_number          xxcos_dlv_headers.digestion_ln_number%TYPE,     -- 枝番
--     order_no_ebs                 xxcos_dlv_headers.order_no_ebs%TYPE,            -- 受注No.（EBS）
--     base_code                    xxcos_dlv_headers.base_code%TYPE,               -- 拠点コード
--     performance_by_code          xxcos_dlv_headers.dlv_by_code%TYPE,             -- 成績者コード
--     dlv_by_code                  xxcos_dlv_headers.hht_invoice_no%TYPE,          -- 納品者コード
     hht_invoice_no               xxcos_dlv_headers.hht_invoice_no%TYPE          -- HHT伝票No.
--     dlv_date                     xxcos_dlv_headers.dlv_date%TYPE,                -- 納品日
--     inspect_date                 xxcos_dlv_headers.inspect_date%TYPE,            -- 検収日
--     sales_classification         xxcos_dlv_headers.sales_classification%TYPE,    -- 売上分類区分
--     sales_invoice                xxcos_dlv_headers.sales_invoice%TYPE,           -- 売上伝票区分
--     card_sale_class              xxcos_dlv_headers.card_sale_class%TYPE,         -- カード売り区分
--     dlv_time                     xxcos_dlv_headers.dlv_time%TYPE,                -- 時間
--     customer_number              xxcos_dlv_headers.customer_number%TYPE         -- 顧客コード
--     change_out_time_100          xxcos_dlv_headers.change_out_time_100%TYPE,     -- つり銭切れ時間100円
--     change_out_time_10           xxcos_dlv_headers.change_out_time_10%TYPE,      -- つり銭切れ時間10円
--     system_class                 xxcos_dlv_headers.system_class%TYPE,            -- 業態区分
--     input_class                  xxcos_dlv_headers.input_class%TYPE,             -- 入力区分
--     consumption_tax_class        xxcos_dlv_headers.consumption_tax_class%TYPE,   -- 消費税区分
--     total_amount                 xxcos_dlv_headers.total_amount%TYPE,            -- 合計金額
--     sale_discount_amount         xxcos_dlv_headers.sale_discount_amount%TYPE,    -- 売上値引額
--     sales_consumption_tax        xxcos_dlv_headers.sales_consumption_tax%TYPE,   -- 売上消費税額
--     tax_include                  xxcos_dlv_headers.tax_include%TYPE,             -- 税込金額
--     keep_in_code                 xxcos_dlv_headers.keep_in_code%TYPE,            -- 預け先コード
--     department_screen_class      xxcos_dlv_headers.department_screen_class%TYPE, -- 百貨店画面種別
--     red_black_flag               xxcos_dlv_headers.red_black_flag%TYPE,          -- 赤黒フラグ
--     stock_forward_flag           xxcos_dlv_headers.stock_forward_flag%TYPE,      -- 入出庫転送フラグ
--     stock_forward_date           xxcos_dlv_headers.stock_forward_date%TYPE,      -- 入出庫転送済日付
--     results_forward_flag         xxcos_dlv_headers.results_forward_flag%TYPE,    -- 販売実績連携済フラグ
--     results_forward_date         xxcos_dlv_headers.results_forward_date%TYPE,    -- 販売実績連携済日付
--     cancel_correct_class         xxcos_dlv_headers.cancel_correct_class%TYPE     -- 取消・訂正区分
    );
  TYPE g_tab_dlv_head_data IS TABLE OF g_rec_dlv_head_data INDEX BY PLS_INTEGER;
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END ***************************************
--
--******************************* 2009/06/23 N.Maeda Var1.17 DEL START *************************************
--  -- 納品明細情報格納用変数
--  TYPE g_rec_dlv_lines_data IS RECORD
--    (
--     order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE,                     -- 受注No.（HHT）
--     line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE,                      -- 行No.（HHT）
--     digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE,              -- 枝番
--     order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE,                     -- 受注No.（EBS）
--     line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE,                  -- 明細番号（EBS）
--     item_code_self        xxcos_dlv_lines.item_code_self%TYPE,                   -- 品名コード（自社）
--     content               xxcos_dlv_lines.content%TYPE,                          -- 入数
--     inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE,                -- 品目ID
--     standard_unit         xxcos_dlv_lines.standard_unit%TYPE,                    -- 基準単位
--     case_number           xxcos_dlv_lines.case_number%TYPE,                      -- ケース数
--     quantity              xxcos_dlv_lines.quantity%TYPE,                         -- 数量
--     sale_class            xxcos_dlv_lines.sale_class%TYPE,                       -- 売上区分
--     wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE,             -- 卸単価
--     selling_price         xxcos_dlv_lines.selling_price%TYPE,                    -- 売単価
--     column_no             xxcos_dlv_lines.column_no%TYPE,                        -- コラムNo.
--     h_and_c               xxcos_dlv_lines.h_and_c%TYPE,                          -- H/C
--     sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE,                   -- 売切区分
--     sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE,                    -- 売切時間
--     replenish_number      xxcos_dlv_lines.replenish_number%TYPE,                 -- 補充数
--     cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE                     -- 現金・カード併用額
--     );
--  TYPE g_tab_dlv_lines_data IS TABLE OF g_rec_dlv_lines_data INDEX BY PLS_INTEGER;
--******************************* 2009/06/23 N.Maeda Var1.17 DEL  END ***************************************
--
  -- HHT入出庫一時テーブルヘッダ使用変数
  TYPE g_rec_inv_trans_head IS RECORD
    (
     employee_num          xxcoi_hht_inv_transactions.employee_num%TYPE,                  -- 営業員コード
     invoice_no            xxcoi_hht_inv_transactions.invoice_no%TYPE,                    -- 伝票№
     invoice_type          xxcoi_hht_inv_transactions.invoice_type%TYPE,                  -- 伝票区分
     inside_code           xxcoi_hht_inv_transactions.inside_code%TYPE,                   -- 入庫側コード
     invoice_date          xxcoi_hht_inv_transactions.invoice_date%TYPE,                  -- 伝票日付
     record_type           xxcoi_hht_inv_transactions.record_type%TYPE,                   -- レコード種別
     inside_cust_code      xxcoi_hht_inv_transactions.inside_cust_code%TYPE,              -- 入庫側顧客コード
     inside_business_low_type  xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,  -- 入庫側業態区分
     column_no             xxcoi_hht_inv_transactions.column_no%TYPE
    );
  TYPE g_tab_inv_trans_head IS TABLE OF g_rec_inv_trans_head INDEX BY PLS_INTEGER;
--
  --HHT入出庫一時テーブル格納用変数
  TYPE g_rec_inv_transactions_data IS RECORD
    (
     row_id                           ROWID,                                                     -- 行ID
     transaction_id                   xxcoi_hht_inv_transactions.transaction_id%TYPE,            -- 入出庫一時表ID
     interface_id                     xxcoi_hht_inv_transactions.interface_id%TYPE,              -- インターフェースID
     form_header_id                   xxcoi_hht_inv_transactions.form_header_id%TYPE,            -- 画面入力用ヘッダID
     base_code                        xxcoi_hht_inv_transactions.base_code%TYPE,                 -- 拠点コード
     record_type                      xxcoi_hht_inv_transactions.record_type%TYPE,               -- レコード種別
     employee_num                     xxcoi_hht_inv_transactions.employee_num%TYPE,              -- 営業員コード
     invoice_no                       xxcoi_hht_inv_transactions.invoice_no%TYPE,                -- 伝票№
     item_code                        xxcoi_hht_inv_transactions.item_code%TYPE,                 -- 品目コード
     case_quantity                    xxcoi_hht_inv_transactions.case_quantity%TYPE,             -- ケース数
     case_in_quantity                 xxcoi_hht_inv_transactions.case_in_quantity%TYPE,          -- 入数
     quantity                         xxcoi_hht_inv_transactions.quantity%TYPE,                  -- 本数
     invoice_type                     xxcoi_hht_inv_transactions.invoice_type%TYPE,              -- 伝票区分
     base_delivery_flag               xxcoi_hht_inv_transactions.base_delivery_flag%TYPE,        -- 拠点間倉替フラグ
     outside_code                     xxcoi_hht_inv_transactions.outside_code%TYPE,              -- 出庫側コード
     inside_code                      xxcoi_hht_inv_transactions.inside_code%TYPE,               -- 入庫側コード
     invoice_date                     xxcoi_hht_inv_transactions.invoice_date%TYPE,              -- 伝票日付
     column_no                        xxcoi_hht_inv_transactions.column_no%TYPE,                 -- コラム№
     unit_price                       xxcoi_hht_inv_transactions.unit_price%TYPE,                -- 単価
     hot_cold_div                     xxcoi_hht_inv_transactions.hot_cold_div%TYPE,              -- H/C
     department_flag                  xxcoi_hht_inv_transactions.department_flag%TYPE,           -- 百貨店フラグ
     interface_date                   xxcoi_hht_inv_transactions.interface_date%TYPE,            -- 受信日時
     other_base_code                  xxcoi_hht_inv_transactions.other_base_code%TYPE,           -- 他拠点コード
     outside_subinv_code              xxcoi_hht_inv_transactions.outside_subinv_code%TYPE,       -- 出庫側保管場所
     inside_subinv_code               xxcoi_hht_inv_transactions.inside_subinv_code%TYPE,        -- 入庫側保管場所
     outside_base_code                xxcoi_hht_inv_transactions.outside_base_code%TYPE,         -- 出庫側拠点
     inside_base_code                 xxcoi_hht_inv_transactions.inside_base_code%TYPE,          -- 入庫側拠点
     total_quantity                   xxcoi_hht_inv_transactions.total_quantity%TYPE,            -- 総本数
     inventory_item_id                xxcoi_hht_inv_transactions.inventory_item_id%TYPE,         -- 品目ID
     primary_uom_code                 xxcoi_hht_inv_transactions.primary_uom_code%TYPE,          -- 基準単位
     outside_subinv_code_conv_div     xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE,-- 出庫側保管場所変換
     inside_subinv_code_conv_div      xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE, -- 入庫側保管場所変換
     outside_business_low_type        xxcoi_hht_inv_transactions.outside_business_low_type%TYPE, -- 出庫側業態区分
     inside_business_low_type         xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,  -- 入庫側業態区分
     outside_cust_code                xxcoi_hht_inv_transactions.outside_cust_code%TYPE,     -- 出庫側顧客コード
     inside_cust_code                 xxcoi_hht_inv_transactions.inside_cust_code%TYPE,      -- 入庫側顧客コード
     hht_program_div                  xxcoi_hht_inv_transactions.hht_program_div%TYPE,       -- 入出庫ジャーナル処理区分
     consume_vd_flag                  xxcoi_hht_inv_transactions.consume_vd_flag%TYPE,       -- 消化VD補充対象フラグ
     item_convert_div                 xxcoi_hht_inv_transactions.item_convert_div%TYPE,      -- 商品振替区分
     stock_uncheck_list_div           xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE,-- 入庫未確認リスト対象区分
     stock_balance_list_div           xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE,-- 入庫差異確認リスト対象
     status                           xxcoi_hht_inv_transactions.status%TYPE,                -- 処理ステータス
     column_if_flag                   xxcoi_hht_inv_transactions.column_if_flag%TYPE,        -- コラム別転送済フラグ
     column_if_date                   xxcoi_hht_inv_transactions.column_if_date%TYPE,        -- コラム別転送日
     sample_if_flag                   xxcoi_hht_inv_transactions.sample_if_flag%TYPE,        -- 見本転送済フラグ
     sample_if_date                   xxcoi_hht_inv_transactions.sample_if_date%TYPE,        -- 見本転送日
     output_flag                      xxcoi_hht_inv_transactions.output_flag%TYPE            -- 出力済フラグ
     );
  TYPE g_tab_inv_transactions_data IS TABLE OF g_rec_inv_transactions_data INDEX BY PLS_INTEGER;
--
  TYPE g_rec_oe_order_data IS RECORD
    (
     order_number         oe_order_headers_all.order_number%TYPE,       -- 受注番号
     header_id            oe_order_headers_all.header_id%TYPE,          -- 受注ヘッダID
     head_flow_status_code  oe_order_headers_all.flow_status_code%TYPE, -- ヘッダステータス
     order_source_id      oe_order_headers_all.order_source_id%TYPE,    -- 受注ソースID
     cust_po_number       oe_order_headers_all.cust_po_number%TYPE,     -- 顧客発注
     line_id              oe_order_lines_all.line_id%TYPE,              -- 受注明細ID
     line_flow_status_code  oe_order_lines_all.flow_status_code%TYPE    -- 明細ステータス
-- **************** 2009/10/13 1.22 N.Maeda ADD START **************** --
     ,row_id               ROWID                                        -- 行ID
-- **************** 2009/10/13 1.22 N.Maeda ADD  END  **************** --
     );
  TYPE g_tab_oe_order_data IS TABLE OF g_rec_oe_order_data INDEX BY PLS_INTEGER;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
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
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  -- 汎用エラーリスト
  TYPE g_gen_err_list_ttype IS TABLE OF xxcos_gen_err_list%ROWTYPE INDEX BY BINARY_INTEGER;
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- ヘッダデータ登録用変数
  TYPE g_tab_dlv_hht_head_row_id    IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- HHT行ID
  TYPE g_tab_dlv_edi_head_row_id    IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- EDI行ID
  TYPE g_tab_dlv_tran_head_row_id   IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- 入出庫一時表行ID
  TYPE g_tab_head_id                IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- 販売実績ヘッダID
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_sales_exp_headers.order_number%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(EBS)(受注番号)
  TYPE g_tab_head_digestion_ln_number IS TABLE OF xxcos_sales_exp_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;   -- 枝番(受注No(HHT)枝番)
  TYPE g_tab_head_dlv_invoice_class IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_class%TYPE
    INDEX BY PLS_INTEGER;   -- 納品伝票区分(導出)
  TYPE g_tab_head_cancel_cor_cls    IS TABLE OF xxcos_sales_exp_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   -- 取消・訂正区分(導出)
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_sales_exp_headers.cust_gyotai_sho%TYPE
    INDEX BY PLS_INTEGER;   -- 業態区分(業態小分類)
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_sales_exp_headers.delivery_date%TYPE
    INDEX BY PLS_INTEGER;   -- 納品日
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_sales_exp_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- 検収日
  TYPE g_tab_head_customer_number   IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客【納品先】
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_sales_exp_headers.sale_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- 売上金額合計
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_sales_exp_headers.pure_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- 合計金額(本体金額合計)
  TYPE g_tab_head_sales_consump_tax IS TABLE OF xxcos_sales_exp_headers.tax_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税金額合計
  TYPE g_tab_head_consump_tax_class IS TABLE OF xxcos_sales_exp_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税区分(導出)
  TYPE g_tab_head_tax_code          IS TABLE OF xxcos_sales_exp_headers.tax_code%TYPE
    INDEX BY PLS_INTEGER;   -- 税金コード(導出)
  TYPE g_tab_head_tax_rate          IS TABLE OF xxcos_sales_exp_headers.tax_rate%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税率(導出)
  TYPE g_tab_head_performance_by_code     IS TABLE OF xxcos_sales_exp_headers.results_employee_code%TYPE
    INDEX BY PLS_INTEGER;   -- 成績計上者コード
  TYPE g_tab_head_sales_base_code   IS TABLE OF xxcos_sales_exp_headers.sales_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 売上拠点コード(導出)
  TYPE g_tab_head_card_sale_class   IS TABLE OF xxcos_sales_exp_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- カード売り区分
  TYPE g_tab_head_sales_classificat IS TABLE OF xxcos_sales_exp_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;   -- 伝票区分
  TYPE g_tab_head_invoice_class     IS TABLE OF xxcos_sales_exp_headers.invoice_classification_code%TYPE
    INDEX BY PLS_INTEGER;   -- 伝票分類コード
  TYPE g_tab_head_receiv_base_code  IS TABLE OF xxcos_sales_exp_headers.receiv_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 入金拠点コード(導出)
  TYPE g_tab_head_change_out_time_100     IS TABLE OF xxcos_sales_exp_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   -- つり銭切れ時間100円
  TYPE g_tab_head_change_out_time_10 IS TABLE OF xxcos_sales_exp_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   -- つり銭切れ時間10円
  TYPE g_tab_head_hht_dlv_input_date IS TABLE OF xxcos_sales_exp_headers.hht_dlv_input_date%TYPE
    INDEX BY PLS_INTEGER;   -- HHT納品入力日時(成型日時)
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_sales_exp_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品者コード
  TYPE g_tab_head_business_date     IS TABLE OF xxcos_sales_exp_headers.business_date%TYPE
    INDEX BY PLS_INTEGER;   -- 登録業務日付(初期処理取得)
  TYPE g_tab_head_order_source_id   IS TABLE OF xxcos_sales_exp_headers.order_source_id%TYPE
    INDEX BY PLS_INTEGER;   -- 受注ソースID(NULL設定)
  TYPE g_tab_head_order_invoice_num IS TABLE OF xxcos_sales_exp_headers.order_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- 注文伝票番号(NULL設定)
  TYPE g_tab_head_order_connect_num IS TABLE OF xxcos_sales_exp_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;   -- 受注関連番号(NULL設定)
  TYPE g_tab_head_ar_interface_flag IS TABLE OF xxcos_sales_exp_headers.ar_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- ARインタフェース済フラグ('N'設定)
  TYPE g_tab_head_gl_interface_flag IS TABLE OF xxcos_sales_exp_headers.gl_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- GLインタフェース済フラグ('N'設定)
  TYPE g_tab_head_dwh_interface_flag IS TABLE OF xxcos_sales_exp_headers.dwh_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- 情報システムインタフェース済フラグ('N'設定)
  TYPE g_tab_head_edi_interface_flag IS TABLE OF xxcos_sales_exp_headers.edi_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- EDI送信済みフラグ('N'設定)
  TYPE g_tab_head_edi_send_date     IS TABLE OF xxcos_sales_exp_headers.edi_send_date%TYPE
    INDEX BY PLS_INTEGER;   -- EDI送信日時(NULL設定)
  TYPE g_tab_head_create_class      IS TABLE OF xxcos_sales_exp_headers.create_class%TYPE
    INDEX BY PLS_INTEGER;   -- 作成元区分(｢3｣設定)
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_sales_exp_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- 受注No.(HHT)(受注No(HHT))  
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- HHT伝票No.(HHT伝票No、納品伝票No)
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_sales_exp_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- 入力区分
--
  --明細データ登録用変数
  TYPE g_tab_line_sales_exp_line_id IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;   -- 販売実績明細ID
  TYPE g_tab_line_sal_exp_header_id IS TABLE OF xxcos_sales_exp_lines.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- 販売実績ヘッダID
  TYPE g_tab_line_dlv_invoice_number IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- 納品伝票番号
  TYPE g_tab_line_dlv_invoice_l_num  IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   -- 納品明細番号
  TYPE g_tab_line_sales_class        IS TABLE OF xxcos_sales_exp_lines.sales_class%TYPE
    INDEX BY PLS_INTEGER;   -- 売上区分
  TYPE g_tab_line_red_black_flag     IS TABLE OF xxcos_sales_exp_lines.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   -- 赤黒フラグ
  TYPE g_tab_line_item_code          IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;   -- 品目コード
  TYPE g_tab_line_dlv_qty            IS TABLE OF xxcos_sales_exp_lines.dlv_qty%TYPE
    INDEX BY PLS_INTEGER;   -- 納品数量
  TYPE g_tab_line_standard_qty       IS TABLE OF xxcos_sales_exp_lines.standard_qty%TYPE
    INDEX BY PLS_INTEGER;   -- 基準数量
  TYPE g_tab_line_dlv_uom_code       IS TABLE OF xxcos_sales_exp_lines.dlv_uom_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品単位
  TYPE g_tab_line_standard_uom_code  IS TABLE OF xxcos_sales_exp_lines.standard_uom_code%TYPE
    INDEX BY PLS_INTEGER;   -- 基準単位(納品単位)
  TYPE g_tab_line_dlv_unit_price     IS TABLE OF xxcos_sales_exp_lines.dlv_unit_price%TYPE
    INDEX BY PLS_INTEGER;   -- 納品単価
  TYPE g_tab_line_standard_unit_price IS TABLE OF xxcos_sales_exp_lines.standard_unit_price%TYPE
    INDEX BY PLS_INTEGER;   -- 基準単価(納品単価)
  TYPE g_tab_line_business_cost     IS TABLE OF xxcos_sales_exp_lines.business_cost%TYPE
    INDEX BY PLS_INTEGER;   -- 営業原価
  TYPE g_tab_line_sale_amount       IS TABLE OF xxcos_sales_exp_lines.sale_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 売上金額
  TYPE g_tab_line_pure_amount       IS TABLE OF xxcos_sales_exp_lines.pure_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 本体金額
  TYPE g_tab_line_tax_amount        IS TABLE OF xxcos_sales_exp_lines.tax_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 消費税金額
  TYPE g_tab_line_cash_and_card     IS TABLE OF xxcos_sales_exp_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   -- 現金・カード併用額
  TYPE g_tab_line_ship_from_subinv_co IS TABLE OF xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE
    INDEX BY PLS_INTEGER;   -- 出荷元保管場所
  TYPE g_tab_line_delivery_base_code IS TABLE OF xxcos_sales_exp_lines.delivery_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品拠点コード
  TYPE g_tab_line_hot_cold_class     IS TABLE OF xxcos_sales_exp_lines.hot_cold_class%TYPE
    INDEX BY PLS_INTEGER;   -- Ｈ＆Ｃ
  TYPE g_tab_line_column_no          IS TABLE OF xxcos_sales_exp_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- コラムNo
  TYPE g_tab_line_sold_out_class     IS TABLE OF xxcos_sales_exp_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   -- 売切区分
  TYPE g_tab_line_sold_out_time      IS TABLE OF xxcos_sales_exp_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   -- 売切時間
  TYPE g_tab_line_to_cal_fees_flag IS TABLE OF xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
    INDEX BY PLS_INTEGER;   -- 手数料計算インタフェース済フラグ
  TYPE g_tab_line_unit_price_mst_flag    IS TABLE OF xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
    INDEX BY PLS_INTEGER;   -- 単価マスタ作成済フラグ
  TYPE g_tab_line_inv_interface_flag IS TABLE OF xxcos_sales_exp_lines.inv_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- INVインタフェース済フラグ
  TYPE g_tab_line_order_invoice_l_num IS TABLE OF xxcos_sales_exp_lines.order_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   -- 注文明細番号(NULL設定)
  TYPE g_tab_line_not_tax_amount      IS TABLE OF xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE
    INDEX BY PLS_INTEGER;   -- 税抜基準単価
  TYPE g_tab_line_delivery_pat_class  IS TABLE OF xxcos_sales_exp_lines.delivery_pattern_class%TYPE
    INDEX BY PLS_INTEGER;   -- 納品形態区分(導出)
--
  --OM受注情報
  TYPE g_tab_oe_order_number  IS TABLE OF oe_order_headers_all.order_number%TYPE
  INDEX BY PLS_INTEGER;   -- 受注番号
  TYPE g_tab_oe_header_id     IS TABLE OF oe_order_headers_all.header_id%TYPE
  INDEX BY PLS_INTEGER;   -- 受注ヘッダID
  TYPE g_tab_oe_he_flow_status_code  IS TABLE OF oe_order_headers_all.flow_status_code%TYPE
  INDEX BY PLS_INTEGER;   -- ヘッダステータス
  TYPE g_tab_oe_order_source_id  IS TABLE OF oe_order_headers_all.order_source_id%TYPE
  INDEX BY PLS_INTEGER;   -- 受注ソースID
  TYPE g_tab_oe_cust_po_number   IS TABLE OF oe_order_headers_all.cust_po_number%TYPE
  INDEX BY PLS_INTEGER;   -- 顧客発注ID
  TYPE g_tab_oe_line_id       IS TABLE OF oe_order_lines_all.line_id%TYPE
  INDEX BY PLS_INTEGER;   -- 受注明細ID
  TYPE g_tab_oe_li_flow_status_code   IS TABLE OF oe_order_lines_all.flow_status_code%TYPE
  INDEX BY PLS_INTEGER;   -- 明細ステータス
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
  TYPE g_tab_oe_line_row_id    IS TABLE OF ROWID
  INDEX BY PLS_INTEGER;   -- 受注明細行ID
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  TYPE g_tab_msg_war_data     IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--
  gt_dlv_hht_headers_data         g_tab_dlv_head_data;            -- 納品ヘッダ(HHT)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL START *************************************
--  gt_dlv_hht_lines_data           g_tab_dlv_lines_data;           -- 納品明細情報(HHT)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL  END ***************************************
  gt_inp_dlv_hht_headers_data     g_tab_dlv_head_data;            -- 納品伝票入力画面登録データ(ヘッダ)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL START *************************************
--  gt_inp_dlv_hht_lines_data       g_tab_dlv_lines_data;           -- 納品伝票入力画面登録データ(明細)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL  END ***************************************
  gt_dlv_edi_headers_data         g_tab_dlv_head_data;            -- 納品ヘッダ(EDI)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL START *************************************
--  gt_dlv_edi_lines_data           g_tab_dlv_lines_data;           -- 納品明細情報(EDI)テーブル抽出データ
--******************************* 2009/06/23 N.Maeda Var1.17 DEL  END ***************************************
  gt_inv_trans_head               g_tab_inv_trans_head;           -- ヘッダ登録用HHT入出庫一時テーブル抽出データ
  gt_inv_transactions_data        g_tab_inv_transactions_data;    -- HHT入出庫一時テーブル抽出データ
  gt_oe_order_all                 g_tab_oe_order_data;            -- OM受注テーブル抽出データ
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
  gt_inp_oe_order_all             g_tab_oe_order_data;            -- 納品伝票入力画面登録OM受注テーブル抽出データ
--******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  gt_accumulation_data            g_tab_accumulation_data;        -- データ格納用
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  g_gen_err_list_tab              g_gen_err_list_ttype;           -- 汎用エラーリスト
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
--
  --ヘッダデータ格納変数
  gt_dlv_hht_head_row_id          g_tab_dlv_hht_head_row_id;       -- ヘッダ行ID(HHT)
  gt_inp_dlv_hht_head_row_id      g_tab_dlv_hht_head_row_id;       -- ヘッダ行ID(納品伝票入力画面データ)
  gt_dlv_edi_head_row_id          g_tab_dlv_edi_head_row_id;       -- ヘッダ行ID(EDI)
  gt_dlv_tran_head_row_id         g_tab_dlv_tran_head_row_id;      -- 入出庫一時表行ID
  gt_head_id                      g_tab_head_id;                   -- 販売実績ヘッダID
  gt_head_order_no_ebs            g_tab_head_order_no_ebs;         -- 受注番号
  gt_head_digestion_ln_number     g_tab_head_digestion_ln_number;  -- 枝番(受注No(HHT)枝番)
  gt_head_dlv_invoice_class       g_tab_head_dlv_invoice_class;    -- 納品伝票区分(導出)
  gt_head_cancel_cor_cls          g_tab_head_cancel_cor_cls;       -- 取消・訂正区分(導出)
  gt_head_system_class            g_tab_head_system_class;         -- 業態区分(業態小分類)
  gt_head_dlv_date                g_tab_head_dlv_date;             -- オリジナル納品日
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  gt_head_open_dlv_date           g_tab_head_dlv_date;             -- 納品日
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
  gt_head_inspect_date            g_tab_head_inspect_date;         -- オリジナル検収日(売上計上日)
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  gt_head_open_inspect_date       g_tab_head_inspect_date;         -- 検収日(売上計上日)
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
  gt_head_customer_number         g_tab_head_customer_number;      -- 顧客コード(顧客【納品先】)
  gt_head_tax_include             g_tab_head_tax_include;          -- 税込金額(売上金額合計)
  gt_head_total_amount            g_tab_head_total_amount;         -- 合計金額(本体金額合計)
  gt_head_sales_consump_tax       g_tab_head_sales_consump_tax;    -- 売上消費税額(消費税金額合計)
  gt_head_consump_tax_class       g_tab_head_consump_tax_class;    -- 消費税区分(導出)
  gt_head_tax_code                g_tab_head_tax_code;             -- 税金コード(導出)
  gt_head_tax_rate                g_tab_head_tax_rate;             -- 消費税率(導出)
  gt_head_performance_by_code     g_tab_head_performance_by_code;  -- 成績者コード(成績計上者コード)
  gt_head_sales_base_code         g_tab_head_sales_base_code;      -- 売上拠点コード(導出)
  gt_head_card_sale_class         g_tab_head_card_sale_class;      -- カード売り区分
  gt_head_sales_classification    g_tab_head_sales_classificat;    -- 売上分類区分(伝票区分)
  gt_head_invoice_class           g_tab_head_invoice_class;        -- 売上伝票区分(伝票分類コード)
  gt_head_receiv_base_code        g_tab_head_receiv_base_code;     -- 入金拠点コード(導出)
  gt_head_change_out_time_100     g_tab_head_change_out_time_100;  -- つり銭切れ時間100円
  gt_head_change_out_time_10      g_tab_head_change_out_time_10;   -- つり銭切れ時間10円
  gt_head_hht_dlv_input_date      g_tab_head_hht_dlv_input_date;   -- HHT納品入力日時(成型日時)
  gt_head_dlv_by_code             g_tab_head_dlv_by_code;          -- 納品者コード
  gt_head_business_date           g_tab_head_business_date;        -- 登録業務日付(初期処理取得)
  gt_head_order_source_id         g_tab_head_order_source_id;      -- 受注ソースID(NULL設定)order_source_id
  gt_head_order_invoice_number    g_tab_head_order_invoice_num;    -- 注文伝票番号(NULL設定)
  gt_head_order_connection_num    g_tab_head_order_connect_num;    -- 受注関連番号(NULL設定)
  gt_head_ar_interface_flag       g_tab_head_ar_interface_flag;    -- ARインタフェース済フラグ('N'設定)ar_interface_flag
  gt_head_gl_interface_flag       g_tab_head_gl_interface_flag;    -- GLインタフェース済フラグ('N'設定)
  gt_head_dwh_interface_flag      g_tab_head_dwh_interface_flag;   -- 情報システムインタフェース済フラグ('N'設定)
  gt_head_edi_interface_flag      g_tab_head_edi_interface_flag;   -- EDI送信済みフラグ('N'設定)
  gt_head_edi_send_date           g_tab_head_edi_send_date;        -- EDI送信日時(NULL設定)
  gt_head_create_class            g_tab_head_create_class;         -- 作成元区分(｢3｣設定)
  gt_head_order_no_hht            g_tab_head_order_no_hht;         -- 受注No.(HHT)(受注No(HHT))  
  gt_head_hht_invoice_no          g_tab_head_hht_invoice_no;       -- HHT伝票No.(HHT伝票No?、納品伝票No?)
  gt_head_input_class             g_tab_head_input_class;          -- 入力区分
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
  gt_line_delivery_pat_class      g_tab_line_delivery_pat_class;     -- 納品形態区分
--
  --OM受注情報格納変数
  gt_oe_order_number              g_tab_oe_order_number;             -- 受注番号
  gt_oe_header_id                 g_tab_oe_header_id;                -- 受注ヘッダID
  gt_oe_he_flow_status_code       g_tab_oe_he_flow_status_code;      -- ステータス
  gt_oe_order_source_id           g_tab_oe_order_source_id;          -- 受注ソースID
  gt_oe_cust_po_number            g_tab_oe_cust_po_number;           -- 顧客発注
  gt_oe_line_id                   g_tab_oe_line_id;                  -- 受注明細ID
  gt_oe_li_flow_status_code       g_tab_oe_li_flow_status_code;      -- ステータス
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
  gt_oe_line_row_id               g_tab_oe_line_row_id;              -- 受注明細行ID
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  --警告メッセージ出力用
  gt_msg_war_data                 g_tab_msg_war_data;                -- 警告情報(詳細)
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
-- ************ 2009/10/13 1.22 N.Maeda MOD START *********** --
  gt_msg_bookd                    g_tab_msg_war_data;                -- 記帳メッセージ
-- ************ 2009/10/13 1.22 N.Maeda MOD  END  *********** --
--
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  gt_sales_head_row_id            g_tab_dlv_hht_head_row_id;              --更新対象販売実績行ID
  gt_set_sales_head_row_id        g_tab_dlv_hht_head_row_id;              --販売実績更新行ID
  gt_set_head_cancel_cor_cls      g_tab_head_cancel_cor_cls;          --販売実績更新行取消・訂正区分
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
--
  gn_head_data_no                 NUMBER := 1;                       -- 実績ヘッダ登録用カウント
  gn_line_data_no                 NUMBER := 1;                       -- 実績明細登録用カウント
  gn_target_edi_cnt               NUMBER := 0;                       -- 納品ヘッダ(EDI)カウント用
  gn_line_cnt                     NUMBER := 0;                       -- 納品明細(HHT)カウント用
  gn_line_edi_cnt                 NUMBER := 0;                       -- 納品明細(edi)カウント用
  gn_om_data_cnt                  NUMBER := 0;                       -- OM受注データ件数カウント用
  gn_transaction_head_cnt         NUMBER := 0;                       -- ヘッダ用HHT入出庫一時テーブルカウント用
  gn_transaction_cnt              NUMBER := 0;                       -- HHT入出庫一時テーブルカウント用
  gn_inp_target_cnt               NUMBER := 0;                       -- 入力画面登録データ(ヘッダ)カウント用
  gn_inp_line_cnt                 NUMBER := 0;                       -- 入力画面登録データ(明細)カウント用
  gn_consum_amount                NUMBER;                            -- 消費税額
  gn_line_ins_cnt                 NUMBER := 0;                       -- 明細登録件数
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
  gn_wae_data_num                 NUMBER := 0;                       -- 警告データ格納用
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
  gn_orga_id                      NUMBER;                            -- 在庫組織ID
  gv_orga_code                    VARCHAR2(50);                      -- 在庫組織コード
  gv_salse_unit                   VARCHAR2(50);                      -- MO:営業単位
  gd_input_date                   DATE;                              -- HHT納品入力日時
  gd_process_date                 DATE;                              -- 業務処理日
  gd_max_date                     DATE;                              -- MAX日付
  gv_disc_item                    VARCHAR2(50);                      -- 値引き品目コード
  gv_bks_id                       VARCHAR2(50);                      -- 会計帳簿ID
  gv_tkn1                         VARCHAR2(5000);                    -- エラーメッセージ用トークン１
  gv_tkn2                         VARCHAR2(5000);                    -- エラーメッセージ用トークン２
  gv_tkn3                         VARCHAR2(5000);                    -- エラーメッセージ用トークン３
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
  gn_cnt_om_order                 NUMBER :=  1;                      -- OM受注情報格納数
--******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  gn_set_sales_exp_count          NUMBER :=0 ;            -- 更新販売実績件数カウント
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
--******************************* 2009/06/01 N.Maeda Var1.15 ADD START ***************************************
  gn_disc_count                   NUMBER := 0;                       -- 値引明細件数カウント
--******************************* 2009/05/01 N.Maeda Var1.15 ADD END   ***************************************
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
  gn_close_warn_flag              NUMBER := 0;
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
  gv_gen_err_out_flag             VARCHAR2(1);                       -- パラメータ汎用エラーリスト出力フラグ
  gn_gen_err_count                NUMBER := 0;                       -- 汎用エラー出力件数
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_gen_err_list
   * Description      : 汎用エラーリスト作成(A-13)
   ***********************************************************************************/
  PROCEDURE proc_ins_gen_err_list(
      ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode  OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'proc_ins_gen_err_list'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  #####################
    lv_errbuf   VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラー・メッセージ
--#####################  固定ローカル変数宣言部 END    #####################
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
--#####################  固定ステータス初期化部 START  #####################
    ov_retcode  := cv_status_normal;
--#####################  固定ステータス初期化部 END    #####################
--
    BEGIN
--
      --汎用エラーリスト作成
      FORALL i IN 1..g_gen_err_list_tab.COUNT
      INSERT INTO xxcos_gen_err_list VALUES g_gen_err_list_tab( i );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf  := SQLERRM;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_gen_err_list);
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na,gv_tkn1 );
        RAISE insert_err_expt;
    END;
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN insert_err_expt THEN
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START  #################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--
  END proc_ins_gen_err_list;
--
  /**********************************************************************************
   * Procedure Name   : set_gen_err_list
   * Description      : 汎用エラーリスト出力情報設定(A-12)
   ***********************************************************************************/
  PROCEDURE set_gen_err_list(
    it_base_code                IN  xxcos_gen_err_list.base_code%TYPE,     -- 納品拠点コード
    it_message_name             IN  xxcos_gen_err_list.message_name%TYPE,  -- エラーメッセージ名
    it_message_text             IN  xxcos_gen_err_list.message_text%TYPE,  -- エラーメッセージ
    iv_output_msg_name_branch   IN  VARCHAR2 DEFAULT NULL,                 -- エラーメッセージ名枝番
    iv_output_msg_application   IN  VARCHAR2 DEFAULT NULL,                 -- アプリケーション短縮名
    iv_output_msg_name          IN  VARCHAR2 DEFAULT NULL,                 -- メッセージコード
    iv_output_msg_token_name1   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード1
    iv_output_msg_token_value1  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値1
    iv_output_msg_token_name2   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード2
    iv_output_msg_token_value2  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値2
    iv_output_msg_token_name3   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード3
    iv_output_msg_token_value3  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値4
    iv_output_msg_token_name4   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード4
    iv_output_msg_token_value4  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値4
    iv_output_msg_token_name5   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード5
    iv_output_msg_token_value5  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値5
    iv_output_msg_token_name6   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード6
    iv_output_msg_token_value6  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値6
    iv_output_msg_token_name7   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード7
    iv_output_msg_token_value7  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値7
    iv_output_msg_token_name8   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード8
    iv_output_msg_token_value8  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値8
    iv_output_msg_token_name9   IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード9
    iv_output_msg_token_value9  IN  VARCHAR2 DEFAULT NULL,                 -- トークン値9
    iv_output_msg_token_name10  IN  VARCHAR2 DEFAULT NULL,                 -- トークンコード10
    iv_output_msg_token_value10 IN  VARCHAR2 DEFAULT NULL,                 -- トークン値10
    ov_errbuf                   OUT VARCHAR2,                              -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,                              -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2                               -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100)  := 'set_gen_err_list';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START  #####################
    lv_errbuf   VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);    -- リターン・コード
    lv_errmsg   VARCHAR2(5000); -- ユーザー・エラー・メッセージ
--#####################  固定ローカル変数宣言部 END    #####################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_under_bar CONSTANT VARCHAR2(1) := '_';
--
    -- *** ローカル変数 ***
    lv_out_name xxcos_gen_err_list.message_name%TYPE; -- 汎用エラーリストエラーメッセージ名
    lv_out_msg  xxcos_gen_err_list.message_text%TYPE; -- 汎用エラーリストエラーメッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--#####################  固定ステータス初期化部 START  #####################
    ov_retcode  := cv_status_normal;
--#####################  固定ステータス初期化部 END    #####################
--
    -- 汎用エラーリスト出力フラグが'Y'(日中最終起動時)のときのみ作成
    IF ( gv_gen_err_out_flag = cv_tkn_yes ) THEN
--
      -- 枝番がある場合はメッセージ名を編集
      IF ( iv_output_msg_name_branch IS NOT NULL ) THEN
        lv_out_name := it_message_name || lv_under_bar || iv_output_msg_name_branch;
      ELSE
        lv_out_name := it_message_name;
      END IF;
--
      -- メッセージコードがある場合はメッセージを編集する
      IF ( iv_output_msg_name IS NOT NULL ) THEN
         lv_out_msg  := xxccp_common_pkg.get_msg(
                            iv_application   => iv_output_msg_application
                          , iv_name          => iv_output_msg_name
                          , iv_token_name1   => iv_output_msg_token_name1
                          , iv_token_value1  => iv_output_msg_token_value1
                          , iv_token_name2   => iv_output_msg_token_name2
                          , iv_token_value2  => iv_output_msg_token_value2
                          , iv_token_name3   => iv_output_msg_token_name3
                          , iv_token_value3  => iv_output_msg_token_value3
                          , iv_token_name4   => iv_output_msg_token_name4
                          , iv_token_value4  => iv_output_msg_token_value4
                          , iv_token_name5   => iv_output_msg_token_name5
                          , iv_token_value5  => iv_output_msg_token_value5
                          , iv_token_name6   => iv_output_msg_token_name6
                          , iv_token_value6  => iv_output_msg_token_value6
                          , iv_token_name7   => iv_output_msg_token_name7
                          , iv_token_value7  => iv_output_msg_token_value7
                          , iv_token_name8   => iv_output_msg_token_name8
                          , iv_token_value8  => iv_output_msg_token_value8
                          , iv_token_name9   => iv_output_msg_token_name9
                          , iv_token_value9  => iv_output_msg_token_value9
                          , iv_token_name10  => iv_output_msg_token_name10
                          , iv_token_value10 => iv_output_msg_token_value10
                        );
      --トークンの編集が必要ない場合
      ELSE
        lv_out_msg := it_message_text;
      END IF;
--
      -- 汎用エラー出力件数をインクリメント
      gn_gen_err_count  := gn_gen_err_count + 1;
--
      --シーケンスより汎用エラーリストIDを取得
      SELECT  xxcos_gen_err_list_s01.nextval  gen_err_list_id
      INTO    g_gen_err_list_tab( gn_gen_err_count ).gen_err_list_id
      FROM    DUAL
      ;
--
      --レコード型の配列にデータを格納する
      g_gen_err_list_tab( gn_gen_err_count ).base_code                := it_base_code;              -- 納品拠点コード
      g_gen_err_list_tab( gn_gen_err_count ).concurrent_program_name  := cv_pkg_name;               -- コンカレント名
      g_gen_err_list_tab( gn_gen_err_count ).business_date            := gd_process_date;           -- 登録業務日付
      g_gen_err_list_tab( gn_gen_err_count ).message_name             := lv_out_name;               -- エラーメッセージ名
      g_gen_err_list_tab( gn_gen_err_count ).message_text             := lv_out_msg;                -- エラーメッセージ
      g_gen_err_list_tab( gn_gen_err_count ).created_by               := cn_created_by;             -- 作成者
      g_gen_err_list_tab( gn_gen_err_count ).creation_date            := cd_creation_date;          -- 作成日
      g_gen_err_list_tab( gn_gen_err_count ).last_updated_by          := cn_last_updated_by;        -- 最終更新者
      g_gen_err_list_tab( gn_gen_err_count ).last_update_date         := cd_last_update_date;       -- 最終更新日
      g_gen_err_list_tab( gn_gen_err_count ).last_update_login        := cn_last_update_login;      -- 最終更新ログイン
      g_gen_err_list_tab( gn_gen_err_count ).request_id               := cn_request_id;             -- 要求ID
      g_gen_err_list_tab( gn_gen_err_count ).program_application_id   := cn_program_application_id; -- コンカレント・プログラム・アプリケーションID
      g_gen_err_list_tab( gn_gen_err_count ).program_id               := cn_program_id;             -- コンカレント・プログラムID
      g_gen_err_list_tab( gn_gen_err_count ).program_update_date      := cd_program_update_date;    -- プログラム更新日
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START  #################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM  , 1, 5000 );
      ov_retcode := cv_status_error;
--
  END set_gen_err_list;
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  /************************************************************************
   * Function Name   : get_fiscal_period_from
   * Description     : 有効会計期間FROM取得関数(A-4-1)
   ************************************************************************/
  PROCEDURE get_fiscal_period_from(
    iv_div                  IN  VARCHAR2,     -- 会計区分
    id_base_date            IN  DATE,         -- 基準日
    od_open_date            OUT DATE,         -- 有効会計期間FROM
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
--
  /***********************************************************************************
   * Procedure Name   : proc_flg_update
   * Description      : 取得元テーブルフラグ更新(A-10)
   ***********************************************************************************/
  PROCEDURE proc_flg_update(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_flg_update'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_hht_count        NUMBER;       -- 納品ヘッダ(HHT)カウント用
    ln_edi_count        NUMBER;       -- 納品ヘッダ(EDI)カウント用
    ln_transact_count   NUMBER;       -- 入出庫一時表カウント用
    ln_inp_transact_count   NUMBER;   -- 納品伝票入力画面データカウント用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--    -- 登録件数セット
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    ln_hht_count      := gt_dlv_hht_headers_data.COUNT;
--    ln_edi_count      := gt_dlv_edi_headers_data.COUNT;
--    ln_transact_count := gt_inv_transactions_data.COUNT;
--    ln_inp_transact_count := gt_inp_dlv_hht_headers_data.COUNT;
    ln_hht_count      := gt_dlv_hht_head_row_id.COUNT;
    ln_transact_count := gt_dlv_tran_head_row_id.COUNT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
----
--    <<hht_id_loop>>
--    FOR hht_row_count IN 1..ln_hht_count LOOP
--      gt_dlv_hht_head_row_id( hht_row_count ) := gt_dlv_hht_headers_data( hht_row_count ).row_id;
--    END LOOP hht_id_loop;
----
--    <<inp_id_loop>>
--    FOR inp_row_count IN 1..ln_inp_transact_count LOOP
--      gt_inp_dlv_hht_head_row_id( inp_row_count ) := gt_inp_dlv_hht_headers_data( inp_row_count ).row_id;
--    END LOOP inp_id_loop;
----
--    <<edi_id_loop>>
--    FOR edi_row_count IN 1..ln_edi_count LOOP
--      gt_dlv_edi_head_row_id( edi_row_count ) := gt_dlv_edi_headers_data( edi_row_count ).row_id;
--    END LOOP edi_id_loop;
----
--    <<trans_id_loop>>
--    FOR trans_row_count IN 1..ln_transact_count LOOP
--      gt_dlv_tran_head_row_id( trans_row_count ) := gt_inv_transactions_data( trans_row_count ).row_id;
--    END LOOP trans_id_loop;
----
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
    BEGIN
--
      -- ============================
      -- 納品ヘッダ（HHT）フラグ更新
      -- ============================
      FORALL i IN 1..ln_hht_count
--
        UPDATE xxcos_dlv_headers
        SET    results_forward_flag = cv_forward_flag_alr,          --連携済みフラグ
               results_forward_date = gd_process_date,              --連携日
               last_updated_by = cn_last_updated_by,                --最終更新者
               last_update_date = cd_last_update_date,              --最終更新日
               last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
               request_id = cn_request_id,                          --要求ID
               program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE  ROWID  =  gt_dlv_hht_head_row_id( i );
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
        lv_errbuf  := SUBSTRB(SQLERRM,1,5000);
        RAISE updata_err_expt;
    END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    BEGIN
--
--      -- ============================
--      -- 納品ヘッダ（納品伝票入力画面登録データ）フラグ更新
--      -- ============================
--
--      FORALL i IN 1..ln_inp_transact_count
--
--        UPDATE xxcos_dlv_headers
--        SET    results_forward_flag = cv_forward_flag_alr,          --連携済みフラグ
--               results_forward_date = gd_process_date,              --連携日
--               last_updated_by = cn_last_updated_by,                --最終更新者
--               last_update_date = cd_last_update_date,              --最終更新日
--               last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
--               request_id = cn_request_id,                          --要求ID
--               program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--               program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--               program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
--        WHERE  ROWID  =  gt_inp_dlv_hht_head_row_id( i );
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
--        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
--                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
--        RAISE updata_err_expt;
--    END;
--
--    BEGIN
--      -- ============================
--      -- 納品ヘッダ（EDI）フラグ更新
--      -- ============================
--      FORALL i IN 1..ln_edi_count
--
--        UPDATE xxcos_dlv_headers
--        SET    results_forward_flag = cv_forward_flag_alr,          --連携済みフラグ
--               results_forward_date = gd_process_date,              --連携日
--               last_updated_by = cn_last_updated_by,                --最終更新者
--               last_update_date = cd_last_update_date,              --最終更新日
--               last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
--               request_id = cn_request_id,                          --要求ID
--               program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
--               program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
--               program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
--        WHERE  ROWID  =  gt_dlv_edi_head_row_id( i );
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
--        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
--                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
--        RAISE updata_err_expt;
--    END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
    BEGIN
      -- ============================
      -- 入出庫一時表フラグ更新
      -- ============================
      FORALL i IN 1..ln_transact_count
--
        UPDATE xxcoi_hht_inv_transactions
        SET    sample_if_flag = cv_tkn_yes,                         --連携済みフラグ
               sample_if_date = gd_process_date,                    --連携日
               last_updated_by = cn_last_updated_by,                --最終更新者
               last_update_date = cd_last_update_date,              --最終更新日
               last_update_login = cn_last_update_login,            --最終更新ﾛｸﾞｲﾝ
               request_id = cn_request_id,                          --要求ID
               program_application_id = cn_program_application_id,  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               program_id = cn_program_id,                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               program_update_date = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE  ROWID  =  gt_dlv_tran_head_row_id( i );
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
        lv_errbuf    := SUBSTRB(SQLERRM,1,5000);
        RAISE updata_err_expt;
    END;
--
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
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
                                                cv_tkn_table_name , gv_tkn1,cv_key_data , cv_tkn_null);
        lv_errbuf    := SUBSTRB(SQLERRM,1,5000);
        RAISE updata_err_expt;
    END;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD  END  ***************************************
-- **************** 2009/10/13 1.22 N.Maeda ADD START **************** --
    IF ( gt_oe_line_row_id.COUNT > 0 ) THEN
      BEGIN
        FORALL o IN 1..gt_oe_line_row_id.COUNT
--
          UPDATE oe_order_lines_all
          SET    global_attribute5        = cv_tkn_yes                 --販売実績連携済
          WHERE   ROWID                   = gt_oe_line_row_id( o );
      EXCEPTION
        WHEN OTHERS THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_order_line_all_name );
          gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                  cv_tkn_table_name , gv_tkn1, cv_key_data, cv_tkn_null);
          lv_errbuf    := SUBSTRB(SQLERRM,1,5000);
          RAISE updata_err_expt;
      END;
    END IF;
-- **************** 2009/10/13 1.22 N.Maeda ADD  END  **************** --

  EXCEPTION
    WHEN updata_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
-- **************** 2009/10/13 1.22 N.Maeda MOD START **************** --
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
-- **************** 2009/10/13 1.22 N.Maeda MOD  END  **************** --
      ov_retcode := cv_status_error;                                       --# 任意 #
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
  END proc_flg_update;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_om_close
   * Description      : OMクローズ処理(A-7)
   ***********************************************************************************/
  PROCEDURE proc_om_close(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_om_close'; -- プログラム名
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
    lt_order_number          oe_order_headers_all.order_number%TYPE;          -- 受注番号
    lt_header_id             oe_order_headers_all.header_id%TYPE;             -- 受注ヘッダID
    lt_he_flow_status_code   oe_order_headers_all.flow_status_code%TYPE;      -- ヘッダステータス
    lt_order_source_id       oe_order_headers_all.order_source_id%TYPE;       -- 受注ソースID
    lt_cust_po_number        oe_order_headers_all.cust_po_number%TYPE;        -- 顧客発注
    lt_line_id               oe_order_lines_all.line_id%TYPE;                 -- 受注明細ID
    lt_li_flow_status_code   oe_order_lines_all.flow_status_code%TYPE;        -- 明細ステータス
    ln_data_cnt              NUMBER;                                          -- データ件数確認用
    lv_api_msg_data          VARCHAR2(5000);                                  -- 共通APIメッセージ
    lv_key_name1             VARCHAR2(500);                                   -- キーデータ名称1
    lv_key_name2             VARCHAR2(500);                                   -- キーデータ名称2
    lv_key_data1             VARCHAR2(500);                                   -- キーデータ1
    lv_key_data2             VARCHAR2(500);                                   -- キーデータ2
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
    lt_br_header_id          oe_order_headers_all.header_id%TYPE;
    lv_bookd_out_msg         VARCHAR2(2000);
    ln_bookd_msg             NUMBER := 0;
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
--
    -- 受注API用引数
    lv_return_status              VARCHAR2(1) ;                         -- APIの処理ステータス
    ln_msg_count                  NUMBER;                               -- APIのエラーメッセージ件数
    lv_msg_data                   VARCHAR2(2000) ;                      -- APIのエラーメッセージ
    lv_msg_buf                    VARCHAR2(2000);                       -- APIメッセージ統合用
    -- 受注API用配列
    lt_order_line_tbl             oe_order_pub.line_tbl_type;
    lt_header_rec                 oe_order_pub.header_rec_type;
    lt_header_val_rec             oe_order_pub.header_val_rec_type;
    lt_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
    lt_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type;
    lt_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type;
    lt_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type;
    lt_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type;
    lt_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
    lt_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type;
    lt_line_val_tbl               oe_order_pub.line_val_tbl_type;
    lt_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
    lt_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type;
    lt_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type;
    lt_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type;
    lt_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type;
    lt_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
    lt_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type;
    lt_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type;
    lt_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type;
    lt_action_request_tbl         oe_order_pub.request_tbl_type;
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
    -- データ登録件数確認
    ln_data_cnt := gt_oe_order_number.COUNT;
    -- 
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
--    lt_action_request_tbl(1).entity_code := OE_GLOBALS.G_ENTITY_HEADER;
--    lt_action_request_tbl(1).request_type := OE_GLOBALS.G_BOOK_ORDER;
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
--
    <<om_close_loop>>
    FOR cnt_order IN 1..ln_data_cnt LOOP
--
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
      OE_MSG_PUB.INITIALIZE;
      lt_action_request_tbl(1) := OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code := OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).request_type := OE_GLOBALS.G_BOOK_ORDER;
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
      lt_order_number         := gt_oe_order_number( cnt_order );           -- 受注番号
      lt_header_id            := gt_oe_header_id( cnt_order );              -- 受注ヘッダID
      lt_he_flow_status_code  := gt_oe_he_flow_status_code( cnt_order );    -- ステータス
      lt_order_source_id      := gt_oe_order_source_id( cnt_order );        -- 受注ソースID
      lt_cust_po_number       := gt_oe_cust_po_number( cnt_order );         -- 顧客発注
      lt_line_id              := gt_oe_line_id( cnt_order );                -- 受注明細ID
      lt_li_flow_status_code  := gt_oe_li_flow_status_code( cnt_order );    -- ステータス
--
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
      IF ( lt_br_header_id IS NULL) OR ( lt_header_id <> lt_br_header_id ) THEN
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
          -- ヘッダステータスが「記帳済み」以外の場合
        IF ( lt_he_flow_status_code <> cv_status_booked ) THEN
--
          -- 共通関数用変数の初期化
          ln_msg_count     := 0;                                         -- 共通APIエラー件数
          lv_return_status := NULL;                                      -- 共通APIステータス
          lv_msg_data      := NULL;                                      -- 共通APIメッセージ
          -- 記帳済み更新対象「受注ヘッダID」設定
          lt_action_request_tbl(1).entity_id := lt_header_id;
--
          -- 記帳済み更新処理
          oe_order_pub.process_order(
            p_api_version_number      => cn_api_ver_num,
            x_return_status           => lv_return_status,
            x_msg_count               => ln_msg_count,
            x_msg_data                => lv_msg_data,
            p_header_rec              => lt_header_rec,
            p_line_tbl                => lt_order_line_tbl,
            p_action_request_tbl      => lt_action_request_tbl,
            x_header_rec              => lt_header_rec,
            x_header_val_rec          => lt_header_val_rec,
            x_header_adj_tbl          => lt_header_adj_tbl,
            x_header_adj_val_tbl      => lt_header_adj_val_tbl,
            x_header_price_att_tbl    => lt_header_price_att_tbl,
            x_header_adj_att_tbl      => lt_header_adj_att_tbl,
            x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl,
            x_header_scredit_tbl      => lt_header_scredit_tbl,
            x_header_scredit_val_tbl  => lt_header_scredit_val_tbl,
            x_line_tbl                => lt_order_line_tbl,
            x_line_val_tbl            => lt_line_val_tbl,
            x_line_adj_tbl            => lt_line_adj_tbl,
            x_line_adj_val_tbl        => lt_line_adj_val_tbl,
            x_line_price_att_tbl      => lt_line_price_att_tbl,
            x_line_adj_att_tbl        => lt_line_adj_att_tbl,
            x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl,
            x_line_scredit_tbl        => lt_line_scredit_tbl,
            x_line_scredit_val_tbl    => lt_line_scredit_val_tbl,
            x_lot_serial_tbl          => lt_lot_serial_tbl,
            x_lot_serial_val_tbl      => lt_lot_serial_val_tbl,
            x_action_request_tbl      => lt_action_request_tbl
            );
          IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            IF (ln_msg_count > 0 ) THEN
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
--              -- メッセージ件数が0より大きい場合エラーメッセージを出力
--              <<message_loop>>
--              FOR cnt IN 1..ln_msg_count LOOP
--                lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
--                                             p_encoded   => 'F');
--                lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
--              END LOOP message_loop;
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
--
            --メッセージ生成
            lv_errmsg := xxccp_common_pkg.get_msg(
                           cv_application, cv_msg_b_k_ping,
                           cv_line_number, lt_order_number
                           );
--              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
          END IF;
-- ************ 2009/10/13 1.22 N.Maeda MOD START *********** --
          lv_bookd_out_msg := NULL;
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt
                                       , p_encoded => 'F');
            lv_bookd_out_msg := SUBSTRB(lv_bookd_out_msg || lv_msg_buf,1,2000);
          END LOOP message_loop;
--
          ln_bookd_msg := ln_bookd_msg + 1;
          gt_msg_bookd(ln_bookd_msg) := xxccp_common_pkg.get_msg(
                                              iv_application   => cv_application,       --アプリケーション短縮名
                                              iv_name          => cv_bookd_out_msg,     --メッセージコード
                                              iv_token_name1   => cv_tkn_order_number,
                                              iv_token_value1  => lt_order_number,
                                              iv_token_name2   => cv_bookd_data,
                                              iv_token_value2  => SUBSTRB(lv_bookd_out_msg,1,200));
-- ************ 2009/10/13 1.22 N.Maeda MOD  END  *********** --
--
        END IF;
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
        lt_br_header_id := lt_header_id;
      END IF;
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
--
      -- 明細クローズ処理
      BEGIN
        wf_engine.completeactivity(
          cv_tkn_oeol , lt_line_id , cv_xxcos_r_standard_line , cv_tkn_null );
      EXCEPTION
        WHEN OTHERS THEN
-- ************ 2009/10/13 1.22 N.Maeda MOD START *********** --
          lv_errbuf := SQLERRM;
--          RAISE no_complet_expt;
          ln_bookd_msg := ln_bookd_msg + 1;
          gn_close_warn_flag  := 1;
          gt_msg_bookd(ln_bookd_msg) := xxccp_common_pkg.get_msg(
                                          cv_application, cv_bookd_err_msg,
                                          cv_line_number, lt_line_id );
-- ************ 2009/10/13 1.22 N.Maeda MOD  END  *********** --
      END;
--
    END LOOP om_close_loop;
--
  EXCEPTION
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
--    WHEN no_complet_expt THEN
--      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_close_api );
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       cv_application, cv_msg_close_err,
--                       cv_tkn_api_name, gv_tkn1,
--                       cv_line_number, lt_line_id );
----      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;                                            --# 任意 #
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
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
  END proc_om_close;
--
  /**********************************************************************************
   * Procedure Name   : proc_insert
   * Description      : 販売実績データ登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_insert(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_insert'; -- プログラム名
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
    --== データ登録件数 ==--
--******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
--    -- ヘッダデータ作成件数セット
--    gn_normal_cnt := gt_head_id.COUNT;
--    -- 明細データ作成件数セット
--    gn_line_ins_cnt := gt_line_sales_exp_line_id.COUNT;
--
    -- =================
    -- ヘッダデータ登録
    -- =================
    BEGIN
--      FORALL i IN 1..gn_normal_cnt
      FORALL i IN 1..gt_head_id.COUNT
--******************************* 2009/05/18 N.Maeda Var1.15 MOD  END  ***************************************
        INSERT INTO xxcos_sales_exp_headers          --販売実績ヘッダテーブル
                      (
                        sales_exp_header_id,                -- 1.販売実績ヘッダID
                        dlv_invoice_number,                 -- 2.納品伝票番号
                        order_invoice_number,               -- 3.注文伝票番号
                        order_number,                       -- 4.受注番号
                        order_no_hht,                       -- 5.受注No(HHT)
                        digestion_ln_number,                -- 6.受注No(HHT)枝番
                        order_connection_number,            -- 7.受注関連番号
                        dlv_invoice_class,                  -- 8.納品伝票区分
                        cancel_correct_class,               -- 9.取消・訂正区分
                        input_class,                        -- 10.入力区分
                        cust_gyotai_sho,                    -- 11.業態小分類
                        delivery_date,                      -- 12.納品日
                        orig_delivery_date,                 -- 13.オリジナル納品日
                        inspect_date,                       -- 14.検収日
                        orig_inspect_date,                  -- 15.オリジナル検収日
                        ship_to_customer_code,              -- 16.顧客【納品先】
                        sale_amount_sum,                    -- 17.売上金額合計
                        pure_amount_sum,                    -- 18.本体金額合計
                        tax_amount_sum,                     -- 19.消費税金額合計
                        consumption_tax_class,              -- 20.消費税区分
                        tax_code,                           -- 21.税金コード
                        tax_rate,                           -- 22.消費税率
                        results_employee_code,              -- 23.成績計上者コード
                        sales_base_code,                    -- 24.売上拠点コード
                        receiv_base_code,                   -- 25.入金拠点コード
                        order_source_id,                    -- 26.受注ソースID
                        card_sale_class,                    -- 27.カード売り区分
                        invoice_class,                      -- 28.伝票区分
                        invoice_classification_code,        -- 29.伝票分類コード
                        change_out_time_100,                -- 30.つり銭切れ時間100円
                        change_out_time_10,                 -- 31.つり銭切れ時間10円
                        ar_interface_flag,                  -- 32.ARインタフェース済フラグ
                        gl_interface_flag,                  -- 33.Gインタフェース済フラグ
                        dwh_interface_flag,                 -- 34.情報システムインタフェース済フラグ
                        edi_interface_flag,                 -- 35.EDI送信済みフラグ
                        edi_send_date,                      -- 36.EDI送信日時
                        hht_dlv_input_date,                 -- 37.HHT納品入力日時
                        dlv_by_code,                        -- 38.納品者コード
                        create_class,                       -- 39.作成元区分
                        business_date,                      -- 40.登録業務日付
                        created_by,                         -- 41.作成者
                        creation_date,                      -- 42.作成日
                        last_updated_by,                    -- 43.最終更新者
                        last_update_date,                   -- 44.最終更新日
                        last_update_login,                  -- 45.最終更新ﾛｸﾞｲﾝ
                        request_id,                         -- 46.要求ID
                        program_application_id,             -- 47.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        program_id,                         -- 48.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        program_update_date )               -- 49.ﾌﾟﾛｸﾞﾗﾑ更新日
                      VALUES(
                        gt_head_id( i ),                    -- 1.販売実績ヘッダID
                        gt_head_hht_invoice_no( i ),        -- 2.HHT伝票番号
                        gt_head_order_invoice_number( i ),  -- 3.注文伝票番号
                        gt_head_order_no_ebs( i ),          -- 4.受注番号
                        gt_head_order_no_hht( i ),          -- 5.受注No(HHT)
                        gt_head_digestion_ln_number( i ),   -- 6.受注No(HHT)枝番
                        gt_head_order_connection_num( i ),  -- 7.受注関連番号
                        gt_head_dlv_invoice_class( i ),     -- 8.納品伝票区分
                        gt_head_cancel_cor_cls( i ),        -- 9.取消・訂正区分
                        gt_head_input_class( i ),           -- 10.入力区分
                        gt_head_system_class( i ),          -- 11.業態小分類
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
                        gt_head_open_dlv_date( i ),              -- 12.納品日
--                        gt_head_dlv_date( i ),              -- 12.納品日
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
                        gt_head_dlv_date( i ),              -- 13.オリジナル納品日
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
                        gt_head_open_inspect_date( i ),          -- 14.検収日(売上計上日)
--                        gt_head_inspect_date( i ),          -- 14.検収日(売上計上日)
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
                        gt_head_inspect_date( i ),          -- 15.オリジナル検収日
                        gt_head_customer_number( i ),       -- 16.顧客【納品先】
                        gt_head_tax_include( i ),           -- 17.売上金額合計
                        gt_head_total_amount( i ),          -- 18.本体金額合計
                        gt_head_sales_consump_tax( i ),     -- 19.消費税金額合計
                        gt_head_consump_tax_class( i ),     -- 20.消費税区分
                        gt_head_tax_code( i ),              -- 21.税金コード
                        gt_head_tax_rate( i ),              -- 22.消費税率
                        gt_head_performance_by_code( i ),   -- 23.成績計上者コード
                        gt_head_sales_base_code( i ),       -- 24.売上拠点コード
                        gt_head_receiv_base_code( i ),      -- 25.入金拠点コード
                        gt_head_order_source_id( i ),       -- 26.受注ソースID
                        gt_head_card_sale_class( i ),       -- 27.カード売り区分
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
                        gt_head_sales_classification( i ),  -- 28.伝票区分
                        gt_head_invoice_class( i ),         -- 29.伝票分類コード
--                        gt_head_invoice_class( i ),         -- 28.売上伝票区分(伝票分類コード)
--                        gt_head_sales_classification( i ),  -- 29.売上分類区分(伝票区分)
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                        gt_head_change_out_time_100( i ),   -- 30.つり銭切れ時間100円
                        gt_head_change_out_time_10( i ),    -- 31.つり銭切れ時間10円
                        gt_head_ar_interface_flag( i ),     -- 32.ARインタフェース済フラグ
                        gt_head_gl_interface_flag( i ),     -- 33.GLインタフェース済フラグ
                        gt_head_dwh_interface_flag( i ),    -- 34.情報システムインタフェース済フラグ
                        gt_head_edi_interface_flag( i ),    -- 35.EDI送信済みフラグ
                        gt_head_edi_send_date( i ),         -- 36.EDI送信日時
                        gt_head_hht_dlv_input_date( i ),    -- 37.HHT納品入力日時
                        gt_head_dlv_by_code( i ),           -- 38.納品者コード
                        gt_head_create_class( i ),          -- 39.作成元区分
                        gt_head_business_date( i ),         -- 40.登録業務日付
                        cn_created_by,                      -- 41.作成者
                        cd_creation_date,                   -- 42.作成日
                        cn_last_updated_by,                 -- 43.最終更新者
                        cd_last_update_date,                -- 44.最終更新日
                        cn_last_update_login,               -- 45.最終更新ﾛｸﾞｲﾝ
                        cn_request_id,                      -- 46.要求ID
                        cn_program_application_id,          -- 47.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        cn_program_id,                      -- 48.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        cd_program_update_date );           -- 49.ﾌﾟﾛｸﾞﾗﾑ更新日
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
        lv_errbuf  := SQLERRM;
--******************************* 2009/05/18 N.Maeda Var1.15 MOD  END  ***************************************
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head);
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na,gv_tkn1 );
        RAISE insert_err_expt;
        RAISE;
    END;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
      -- 明細データ作成件数セット
      gn_normal_cnt := SQL%ROWCOUNT;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD  END  ***************************************
--
    -- ===============================
    -- 明細データ登録
    -- ===============================
    BEGIN
--******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
--      FORALL i IN 1..gn_line_ins_cnt
      FORALL i IN 1..gt_line_sales_exp_line_id.COUNT
--******************************* 2009/05/18 N.Maeda Var1.15 MOD  END  ***************************************
        INSERT INTO xxcos_sales_exp_lines            -- 販売実績明細テーブル
                      (
                        sales_exp_line_id,                  -- 1.販売実績明細ID
                        sales_exp_header_id,                -- 2.販売実績ヘッダID
                        dlv_invoice_number,                 -- 3.納品伝票番号
                        dlv_invoice_line_number,            -- 4.納品明細番号
                        order_invoice_line_number,          -- 5.注文明細番号
                        sales_class,                        -- 6.売上区分
                        red_black_flag,                     -- 7.赤黒フラグ
                        item_code,                          -- 8.品目コード
                        dlv_qty,                            -- 9.納品数量
                        standard_qty,                       -- 10.基準数量
                        dlv_uom_code,                       -- 11.納品単位
                        standard_uom_code,                  -- 12.基準単位
                        dlv_unit_price,                     -- 13.納品単価
                        standard_unit_price_excluded,       -- 14.税抜基準単価
                        standard_unit_price,                -- 15.基準単価
                        business_cost,                      -- 16.営業原価
                        sale_amount,                        -- 17.売上金額
                        pure_amount,                        -- 18.本体金額
                        tax_amount,                         -- 19.消費税金額
                        cash_and_card,                      -- 20.現金・カード併用額
                        ship_from_subinventory_code,        -- 21.出荷元保管場所
                        delivery_base_code,                 -- 22.納品拠点コード
                        hot_cold_class,                     -- 23.Ｈ＆Ｃ
                        column_no,                          -- 24.コラムNo
                        sold_out_class,                     -- 25.売切区分
                        sold_out_time,                      -- 26.売切時間
                        delivery_pattern_class,             -- 27.納品形態区分
                        to_calculate_fees_flag,             -- 28.手数料計算インタフェース済フラグ
                        unit_price_mst_flag,                -- 29.単価マスタ作成済フラグ
                        inv_interface_flag,                 -- 30.INVインタフェース済フラグ
                        created_by,                         -- 31.作成者
                        creation_date,                      -- 32.作成日
                        last_updated_by,                    -- 33.最終更新者
                        last_update_date,                   -- 34.最終更新日
                        last_update_login,                  -- 35.最終更新ﾛｸﾞｲﾝ
                        request_id,                         -- 36.要求ID
                        program_application_id,             -- 37.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        program_id,                         -- 38.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        program_update_date )               -- 39.ﾌﾟﾛｸﾞﾗﾑ更新日
                      VALUES(
                        gt_line_sales_exp_line_id( i ),     -- 1.販売実績明細ID
                        gt_line_sales_exp_header_id( i ),   -- 2.販売実績ヘッダID
                        gt_line_dlv_invoice_number( i ),    -- 3.納品伝票番号
                        gt_line_dlv_invoice_l_num( i ),     -- 4.納品明細番号
                        gt_line_order_invoice_l_num( i ),   -- 5.注文明細番号
                        gt_line_sales_class( i ),           -- 6.売上区分
                        gt_line_red_black_flag( i ),        -- 7.赤黒フラグ
                        gt_line_item_code( i ),             -- 8.品目コード
                        gt_line_dlv_qty( i ),               -- 9.納品数量
                        gt_line_standard_qty( i ),          -- 10.基準数量
                        gt_line_dlv_uom_code( i ),          -- 11.納品単位
                        gt_line_standard_uom_code( i ),     -- 12.基準単位
                        gt_dlv_unit_price( i ),             -- 13.納品単価
                        gt_line_not_tax_amount( i ),        -- 14.税抜基準単価
                        gt_line_standard_unit_price( i ),   -- 15.基準単価
                        gt_line_business_cost( i ),         -- 16.営業原価
                        gt_line_sale_amount( i ),           -- 17.売上金額
                        gt_line_pure_amount( i ),           -- 18.本体金額
                        gt_line_tax_amount( i ),            -- 19.消費税金額
                        gt_line_cash_and_card( i ),         -- 20.現金・カード併用額
                        gt_line_ship_from_subinv_co( i ),   -- 21.出荷元保管場所
                        gt_line_delivery_base_code( i ),    -- 22.納品拠点コード
                        gt_line_hot_cold_class( i ),        -- 23.Ｈ＆Ｃ
                        gt_line_column_no( i ),             -- 24.コラムNo
                        gt_line_sold_out_class( i ),        -- 25.売切区分
                        gt_line_sold_out_time( i ),         -- 26.売切時間
                        gt_line_delivery_pat_class( i ),    -- 27.納品形態区分
                        gt_line_to_calculate_fees_flag( i ), -- 28.手数料計算インタフェース済フラグ
                        gt_line_unit_price_mst_flag( i ),   -- 29.単価マスタ作成済フラグ
                        gt_line_inv_interface_flag( i ),    -- 30.INVインタフェース済フラグ
                        cn_created_by,                      -- 31.作成者
                        cd_creation_date,                   -- 32.作成日
                        cn_last_updated_by,                 -- 33.最終更新者
                        cd_last_update_date,                -- 34.最終更新日
                        cn_last_update_login,               -- 35.最終更新ﾛｸﾞｲﾝ
                        cn_request_id,                      -- 36.要求ID
                        cn_program_application_id,          -- 37.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
                        cn_program_id,                      -- 38.ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
                        cd_program_update_date );           -- 39.ﾌﾟﾛｸﾞﾗﾑ更新日
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
        lv_errbuf  := SQLERRM;
--******************************* 2009/05/18 N.Maeda Var1.15 MOD  END  ***************************************
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_line );
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na, gv_tkn1 );
        RAISE insert_err_expt;
        RAISE;
    END;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
      -- 明細データ作成件数セット
      gn_line_ins_cnt := SQL%ROWCOUNT;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD  END  ***************************************
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--
--#####################################  固定部 END   ##########################################
--
  END proc_insert;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_trans
   * Description      : 販売実績データ（入出庫）成型処理(A-5)
   ***********************************************************************************/
  PROCEDURE proc_molded_trans(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded_trans'; -- プログラム名
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
    lt_head_employee_num              xxcoi_hht_inv_transactions.employee_num%TYPE;              -- 営業員コード
    lt_head_invoice_no                xxcoi_hht_inv_transactions.invoice_no%TYPE;                -- 伝票.No
    lt_head_invoice_type              xxcoi_hht_inv_transactions.invoice_type%TYPE;              -- 伝票区分
    lt_head_inside_code               xxcoi_hht_inv_transactions.inside_code%TYPE;               -- 入庫側コード
    lt_head_invoice_date              xxcoi_hht_inv_transactions.invoice_date%TYPE;              -- 伝票日付
    lt_head_record_type               xxcoi_hht_inv_transactions.record_type%TYPE;               -- レコード種別
    lt_head_inside_cust_code          xxcoi_hht_inv_transactions.inside_cust_code%TYPE;          -- 入庫側顧客コード
    lt_head_inside_business_low_t     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;  -- 入庫側業態区分
--
    lt_transaction_id                 xxcoi_hht_inv_transactions.transaction_id%TYPE;            -- 入出庫一時表ID
    lt_interface_id                   xxcoi_hht_inv_transactions.interface_id%TYPE;              -- インターフェースID
    lt_form_header_id                 xxcoi_hht_inv_transactions.form_header_id%TYPE;            -- 画面入力用ヘッダID
    lt_base_code                      xxcoi_hht_inv_transactions.base_code%TYPE;                 -- 拠点コード
    lt_record_type                    xxcoi_hht_inv_transactions.record_type%TYPE;               -- レコード種別
    lt_employee_num                   xxcoi_hht_inv_transactions.employee_num%TYPE;              -- 営業員コード
    lt_invoice_no                     xxcoi_hht_inv_transactions.invoice_no%TYPE;                -- 伝票№
    lt_item_code                      xxcoi_hht_inv_transactions.item_code%TYPE;                 -- 品目コード
    lt_case_quantity                  xxcoi_hht_inv_transactions.case_quantity%TYPE;             -- ケース数
    lt_case_in_quantity               xxcoi_hht_inv_transactions.case_in_quantity%TYPE;          -- 入数
    lt_quantity                       xxcoi_hht_inv_transactions.quantity%TYPE;                  -- 本数
    lt_invoice_type                   xxcoi_hht_inv_transactions.invoice_type%TYPE;              -- 伝票区分
    lt_base_delivery_flag             xxcoi_hht_inv_transactions.base_delivery_flag%TYPE;        -- 拠点間倉替フラグ
    lt_outside_code                   xxcoi_hht_inv_transactions.outside_code%TYPE;              -- 出庫側コード
    lt_inside_code                    xxcoi_hht_inv_transactions.inside_code%TYPE;               -- 入庫側コード
    lt_invoice_date                   xxcoi_hht_inv_transactions.invoice_date%TYPE;              -- 伝票日付
    lt_column_no                      xxcoi_hht_inv_transactions.column_no%TYPE;                 -- コラム№
    lt_unit_price                     xxcoi_hht_inv_transactions.unit_price%TYPE;                -- 単価
    lt_hot_cold_div                   xxcoi_hht_inv_transactions.hot_cold_div%TYPE;              -- H/C
    lt_department_flag                xxcoi_hht_inv_transactions.department_flag%TYPE;           -- 百貨店フラグ
    lt_interface_date                 xxcoi_hht_inv_transactions.interface_date%TYPE;            -- 受信日時
    lt_other_base_code                xxcoi_hht_inv_transactions.other_base_code%TYPE;           -- 他拠点コード
    lt_outside_subinv_code            xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;       -- 出庫側保管場所
    lt_inside_subinv_code             xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;        -- 入庫側保管場所
    lt_outside_base_code              xxcoi_hht_inv_transactions.outside_base_code%TYPE;         -- 出庫側拠点
    lt_inside_base_code               xxcoi_hht_inv_transactions.inside_base_code%TYPE;          -- 入庫側拠点
    lt_total_quantity                 xxcoi_hht_inv_transactions.total_quantity%TYPE;            -- 総本数
    lt_inventory_item_id              xxcoi_hht_inv_transactions.inventory_item_id%TYPE;         -- 品目ID
    lt_primary_uom_code               xxcoi_hht_inv_transactions.primary_uom_code%TYPE;          -- 基準単位
    lt_outside_subinv_code_co_div     xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- 出庫側保管場所変換
    lt_inside_subinv_code_conv_div    xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;-- 入庫側保管場所変換
    lt_outside_business_low_type      xxcoi_hht_inv_transactions.outside_business_low_type%TYPE; -- 出庫側業態区分
    lt_inside_business_low_type       xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;  -- 入庫側業態区分
    lt_outside_cust_code              xxcoi_hht_inv_transactions.outside_cust_code%TYPE;         -- 出庫側顧客コード
    lt_inside_cust_code               xxcoi_hht_inv_transactions.inside_cust_code%TYPE;          -- 入庫側顧客コード
    lt_hht_program_div                xxcoi_hht_inv_transactions.hht_program_div%TYPE;       -- 入出庫ジャーナル処理区分
    lt_consume_vd_flag                xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;           -- 消化VD補充対象フラグ
    lt_item_convert_div               xxcoi_hht_inv_transactions.item_convert_div%TYPE;          -- 商品振替区分
    lt_stock_uncheck_list_div         xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;-- 入庫未確認リスト対象
    lt_stock_balance_list_div         xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;-- 入庫差異確認リスト対象
    lt_status                         xxcoi_hht_inv_transactions.status%TYPE;                    -- 処理ステータス
    lt_column_if_flag                 xxcoi_hht_inv_transactions.column_if_flag%TYPE;            -- コラム別転送済フラグ
    lt_column_if_date                 xxcoi_hht_inv_transactions.column_if_date%TYPE;            -- コラム別転送日
    lt_sample_if_flag                 xxcoi_hht_inv_transactions.sample_if_flag%TYPE;            -- 見本転送済フラグ
    lt_sample_if_date                 xxcoi_hht_inv_transactions.sample_if_date%TYPE;            -- 見本転送日
    lt_output_flag                    xxcoi_hht_inv_transactions.output_flag%TYPE;               -- 出力済フラグ
    lt_old_sales_cost                 ic_item_mst_b.attribute7%TYPE;                             -- 旧営業原価
    lt_new_sales_cost                 ic_item_mst_b.attribute8%TYPE;                             -- 新営業原価
    lt_st_sales_cost                  ic_item_mst_b.attribute9%TYPE;                             -- 営業原価適用開始日
    lt_stand_unit                     mtl_system_items_b.primary_unit_of_measure%TYPE;           -- 基準単位
    lt_inc_num                        xxcmm_system_items_b.inc_num%TYPE;                         -- 内訳入数
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
--    lt_tax_odd                        xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;           -- 税金-端数処理
-- ************** 2009/05/13 1.13 N.Maeda DEL  END  ****************************************************************
    lt_sale_base_code                 xxcmm_cust_accounts.sale_base_code%TYPE;                   -- 売上拠点コード
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- 入金拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
-- ************** 2009/05/13 1.13 N.Maeda DEL  END  ****************************************************************
    lt_dlv_base_code                  xxcos_rs_info_v.base_code%TYPE;                            -- 拠点コード
    lt_ins_invoice_type               fnd_lookup_values.attribute1%TYPE;                         -- 納品伝票区分
    lt_cust_gyotai_sho                xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;              -- 取消・訂正区分
    lt_red_black_flag                 xxcos_sales_exp_lines.red_black_flag%TYPE;                 -- 赤黒フラグ
    lt_sales_cost                     ic_item_mst_b.attribute7%TYPE;                             -- 営業原価
    lt_no_tax_code                    fnd_lookup_values.meaning%TYPE;                            -- 消費税コード(対象外)
    lv_delivery_type                  VARCHAR2(100);                                             -- 納品形態区分
    lv_key_name1                      VARCHAR2(500);                                             -- キーデータ名称1
    lv_key_name2                      VARCHAR2(500);                                             -- キーデータ名称2
    lv_key_data1                      VARCHAR2(500);                                             -- キーデータ1
    lv_key_data2                      VARCHAR2(500);                                             -- キーデータ2
    ln_actual_id                      NUMBER;                                                    -- ヘッダID
    ln_sales_exp_line_id              NUMBER;                                                    -- 明細ID
    ln_invoice_line_num               NUMBER;                                                    -- 納品明細番号
    ln_line_no                        NUMBER :=  1;                                              -- 明細チェック済番号
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                         ROWID;                                           -- 更新用行ID
    lv_state_flg                      VARCHAR2(1);                                     -- データ警告確認フラグ
    ln_line_data_count                NUMBER;                                          -- 明細件数(ヘッダ単位)
    ln_tran_rowid_num                 NUMBER := 0;                                     -- ステータス更新用
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
    lt_normal_class                   fnd_lookup_values.attribute1%TYPE;               -- 納品伝票区分(通常)
    lt_correct_class                  fnd_lookup_values.attribute1%TYPE;               -- 納品伝票区分(取消・訂正)
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  lt_mon_sale_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_past_sale_base_code               xxcmm_cust_accounts.past_sale_base_code%TYPE;
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
  lt_open_dlv_date                     xxcos_dlv_headers.dlv_date%TYPE;                 -- オープン済み納品日
  lt_open_inspect_date                 xxcos_dlv_headers.inspect_date%TYPE;             -- オープン済み検収日
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =================
    -- 消費税コード取得
    -- =================
    BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
      SELECT  look_val.meaning      --消費税コード(対象外)
      INTO    lt_no_tax_code
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = ct_user_lang
      AND     gd_process_date       >= look_val.start_date_active
      AND     gd_process_date       <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     look_val.lookup_type  = cv_xxcos1_cons_tax_no
      AND     look_val.lookup_code  = cv_xxcos_001_a05_01;
--
--      SELECT  look_val.meaning      --消費税コード(対象外)
--      INTO    lt_no_tax_code
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     gd_process_date      >= look_val.start_date_active
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     app.application_short_name = cv_application
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     look_val.lookup_type = cv_xxcos1_cons_tax_no
--      AND     look_val.lookup_code = cv_xxcos_001_a05_01;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
          --キー編集処理
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
          lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
          lv_key_data2 := cv_xxcos_001_a05_01;
        RAISE no_data_extract;
    END;
--
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
    --===============================================================
    --納品伝票区分取得
    --===============================================================
    BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
      SELECT  look_val.attribute4,  -- 通常時(納品伝票区分)
              look_val.attribute5   -- 訂正・取消時(納品伝票区分)
      INTO    lt_normal_class,
              lt_correct_class
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = ct_user_lang
      AND     gd_process_date      >= look_val.start_date_active
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     look_val.lookup_type  = cv_xxcos1_input_class
      AND     look_val.lookup_code  = cv_input_delivery;
--
--      SELECT  look_val.attribute4,  -- 通常時(納品伝票区分)
--              look_val.attribute5   -- 訂正・取消時(納品伝票区分)
--      INTO    lt_normal_class,
--              lt_correct_class
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     gd_process_date      >= look_val.start_date_active
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     app.application_short_name = cv_application
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     look_val.lookup_type = cv_xxcos1_input_class
--      AND     look_val.lookup_code = cv_input_delivery;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ログ出力
        lv_key_name1 :=xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
        lv_key_name2 := NULL;
        lv_key_data1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
        lv_key_data2 := NULL;
      RAISE no_data_extract;
    END;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
--
    <<trans_head_loop>>
    FOR trans_head_no IN 1..gn_transaction_head_cnt LOOP
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- 明細件数カウント(初期化)
      ln_line_data_count              := 0;
      -- データ警告確認フラグ(初期化)
      lv_state_flg                    := cv_status_normal;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      lt_head_employee_num        := gt_inv_trans_head( trans_head_no ).employee_num;          -- 営業員コード
      lt_head_invoice_no          := gt_inv_trans_head( trans_head_no ).invoice_no;            -- 伝票No.
      lt_head_invoice_type        := gt_inv_trans_head( trans_head_no ).invoice_type;          -- 伝票区分
      lt_head_inside_code         := gt_inv_trans_head( trans_head_no ).inside_code;           -- 入庫側コード
      lt_head_invoice_date        := gt_inv_trans_head( trans_head_no ).invoice_date;          -- 伝票日付
      lt_head_record_type         := gt_inv_trans_head( trans_head_no ).record_type;           -- レコード種別
      lt_head_inside_cust_code    := gt_inv_trans_head( trans_head_no ).inside_cust_code;      -- 入庫側顧客コード
      lt_head_inside_business_low_t := gt_inv_trans_head( trans_head_no ).inside_business_low_type; -- 入庫側業態区分
--
--
      --納品明細番号の初期化
      ln_invoice_line_num := 0;
--
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
        --==================================
        -- 1.伝票日付チェック
        --==================================
        get_fiscal_period_from(
            iv_div        => cv_fiscal_period_inv            -- 会計区分
          , id_base_date  => lt_head_invoice_date            -- 基準日            =  伝票日付
          , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
          , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
          , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
          , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_invoice_date_err,    --メッセージコード
                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
                                                iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
                                                iv_token_name2   => cv_invoice_no,               --トークンコード2
                                                iv_token_value2  => lt_head_invoice_no,
                                                iv_token_name3   => cv_tkn_base_date,
                                                iv_token_value3  => TO_CHAR( lt_head_invoice_date,cv_stand_date ) );
        ELSE
          lt_open_inspect_date := lt_open_dlv_date;
        END IF;
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--      --================================
--      --販売実績ヘッダID(シーケンス取得)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
      -- ===============================
      -- 顧客マスタ付帯情報の導出
      -- ===============================
      BEGIN
-- ***************** 2009/08/21 1.20 N.Maeda MOD START ******************** --
        SELECT   xca.sale_base_code        sale_base_code        -- 売上拠点コード
                ,xca.past_sale_base_code   past_sale_base_code   -- 前月売上拠点コード
        INTO    lt_mon_sale_base_code
                ,lt_past_sale_base_code
        FROM    hz_cust_accounts hca,     -- 顧客マスタ
                xxcmm_cust_accounts xca   -- 顧客追加情報
        WHERE   hca.cust_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_head_inside_cust_code );
--
        IF ( TO_CHAR( gd_process_date , cv_month_type ) = TO_CHAR( lt_head_invoice_date , cv_month_type  ) ) THEN  -- 同一月の場合当月売上拠点
          lt_sale_base_code := lt_mon_sale_base_code;
        ELSE                                                                        -- その他前月売上拠点
          IF ( lt_past_sale_base_code IS NULL ) THEN
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,            --アプリケーション短縮名
                                                iv_name          => cv_past_sale_base_get_err, --メッセージコード
                                                iv_token_name1   => cv_cust_code,              --トークン(顧客コード)
                                                iv_token_value1  => lt_head_inside_cust_code,        --トークン値1
                                                iv_token_name2   => cv_dlv_date,               --トークンコード2(納品日)
                                                iv_token_value2  => TO_CHAR( lt_head_invoice_date,cv_short_day ) );         --トークン値2
          ELSE
            lt_sale_base_code := lt_past_sale_base_code;
          END IF;
        END IF;
---- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
--        SELECT  xca.sale_base_code            -- 売上拠点コード
----                --hca.tax_rounding_rule --税金-端数処理
---- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
----                xch.cash_receiv_base_code,  -- 入金拠点コード
---- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
----                xch.bill_tax_round_rule     -- 税金-端数処理(サイト)
--        INTO    lt_sale_base_code
---- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
----                lt_cash_receiv_base_code,
---- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
----                lt_tax_odd
--        FROM    hz_cust_accounts hca,      -- 顧客マスタ
--                xxcmm_cust_accounts xca   -- 顧客追加情報
----                xxcos_cust_hierarchy_v xch -- 顧客階層ビュー
--        WHERE   hca.cust_account_id = xca.customer_id
----        AND     xch.ship_account_id = hca.cust_account_id
----        AND     xch.ship_account_id = xca.customer_id
--        AND     hca.account_number = TO_CHAR( lt_head_inside_cust_code );
----        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
----        AND     hca.party_id IN ( SELECT  hpt.party_id
----                                  FROM    hz_parties hpt
----                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
---- ************** 2009/05/13 1.13 N.Maeda MOD  END  ****************************************************************
-- ***************** 2009/08/21 1.20 N.Maeda MOD  END  ******************** --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ログ出力
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --キー編集処理
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_head_inside_cust_code;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- 項目名称１
            iv_data_value1 => ( lt_head_inside_cust_code ),         -- データの値１
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- 項目名称１
--            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- 項目名称２
--            iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- データの値１
--            iv_data_value2 => lt_head_inside_cust_code,       -- データの値２
            ov_key_info    => gv_tkn2,              -- キー情報
            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
            ov_retcode     => lv_retcode,           -- リターン・コード
            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      -- ================================
      -- HHT納品入力日時の成型処理
      -- ================================
      lt_head_invoice_date := TRUNC(lt_head_invoice_date);
--
--******************************* 2009/05/13 N.Maeda Var1.14 DEL START ***************************************
--      BEGIN
--        SELECT  look_val.attribute1   -- 通常時(納品伝票区分(販売実績入力区分))
--        INTO    lt_ins_invoice_type
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
--        AND     app.application_short_name = cv_application_coi
--        AND     look_val.enabled_flag = cv_tkn_yes
--        AND     look_val.lookup_type = cv_xxcoi1_hht_inv_data_div
--        AND     look_val.lookup_code = lt_head_record_type;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- ログ出力          
--          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
--          --キー編集表変数設定
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
----          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_rec_type );
----          lv_key_name2 := NULL;
----          lv_key_data1 := lt_head_record_type;
----          lv_key_data2 := NULL;
----        RAISE no_data_extract;
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          xxcos_common_pkg.makeup_key_info(
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_rec_type ), -- 項目名称１
--            iv_data_value1 => lt_head_record_type,         -- データの値１
--            ov_key_info    => gv_tkn2,              -- キー情報
--            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--            ov_retcode     => lv_retcode,           -- リターン・コード
--            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --アプリケーション短縮名
--                                                iv_name          => cv_msg_no_data,    --メッセージコード
--                                                iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                iv_token_value1  => gv_tkn1,           --トークン値1
--                                                iv_token_name2   => cv_key_data,       --トークンコード2
--                                                iv_token_value2  => gv_tkn2 );         --トークン値2
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--      END;
--******************************* 2009/05/13 N.Maeda Var1.14 DEL END *****************************************
--
      -- 明細データ取得
      <<trans_loop>>
      FOR line_no IN ln_line_no..gn_transaction_cnt LOOP
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
        lt_row_id                       :=  gt_inv_transactions_data( line_no ).row_id;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
        lt_transaction_id               :=  gt_inv_transactions_data( line_no ).transaction_id;    -- 入出庫一時表ID
        lt_interface_id                 :=  gt_inv_transactions_data( line_no ).interface_id;      -- IF-ID
        lt_form_header_id               :=  gt_inv_transactions_data( line_no ).form_header_id;    -- 画面入力用ヘッダID
        lt_base_code                    :=  gt_inv_transactions_data( line_no ).base_code;         -- 拠点コード
        lt_record_type                  :=  gt_inv_transactions_data( line_no ).record_type;       -- レコード種別
        lt_employee_num                 :=  gt_inv_transactions_data( line_no ).employee_num;      -- 営業員コード
        lt_invoice_no                   :=  gt_inv_transactions_data( line_no ).invoice_no;        -- 伝票№
        lt_item_code                    :=  gt_inv_transactions_data( line_no ).item_code;         -- 品目コード
        lt_case_quantity                :=  gt_inv_transactions_data( line_no ).case_quantity;     -- ケース数
        lt_case_in_quantity             :=  gt_inv_transactions_data( line_no ).case_in_quantity;  -- 入数
        lt_quantity                     :=  gt_inv_transactions_data( line_no ).quantity;          -- 本数
        lt_invoice_type                 :=  gt_inv_transactions_data( line_no ).invoice_type;      -- 伝票区分
        lt_base_delivery_flag           :=  gt_inv_transactions_data( line_no ).base_delivery_flag;-- 拠点間倉替フラグ
        lt_outside_code                 :=  gt_inv_transactions_data( line_no ).outside_code;      -- 出庫側コード
        lt_inside_code                  :=  gt_inv_transactions_data( line_no ).inside_code;       -- 入庫側コード
        lt_invoice_date                 :=  gt_inv_transactions_data( line_no ).invoice_date;      -- 伝票日付
        lt_column_no                    :=  gt_inv_transactions_data( line_no ).column_no;         -- コラム№
        lt_unit_price                   :=  gt_inv_transactions_data( line_no ).unit_price;        -- 単価
        lt_hot_cold_div                 :=  gt_inv_transactions_data( line_no ).hot_cold_div;      -- H/C
        lt_department_flag              :=  gt_inv_transactions_data( line_no ).department_flag;   -- 百貨店フラグ
        lt_interface_date               :=  gt_inv_transactions_data( line_no ).interface_date;    -- 受信日時
        lt_other_base_code              :=  gt_inv_transactions_data( line_no ).other_base_code;   -- 他拠点コード
        lt_outside_subinv_code          :=  gt_inv_transactions_data( line_no ).outside_subinv_code;-- 出庫側保管場所
        lt_inside_subinv_code           :=  gt_inv_transactions_data( line_no ).inside_subinv_code; -- 入庫側保管場所
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
--        lt_outside_base_code            :=  gt_inv_transactions_data( line_no ).outside_base_code; -- 出庫側拠点
        lt_dlv_base_code                :=  gt_inv_transactions_data( line_no ).outside_base_code; -- 出庫側拠点
-- ************** 2009/05/13 1.13 N.Maeda MOD  END  ****************************************************************
        lt_inside_base_code             :=  gt_inv_transactions_data( line_no ).inside_base_code;  -- 入庫側拠点
        lt_total_quantity               :=  gt_inv_transactions_data( line_no ).total_quantity;    -- 総本数
        lt_inventory_item_id            :=  gt_inv_transactions_data( line_no ).inventory_item_id; -- 品目ID
        lt_primary_uom_code             :=  gt_inv_transactions_data( line_no ).primary_uom_code;  -- 基準単位
        lt_outside_subinv_code_co_div   :=  gt_inv_transactions_data( line_no ).outside_subinv_code_conv_div;
        lt_inside_subinv_code_conv_div  :=  gt_inv_transactions_data( line_no ).inside_subinv_code_conv_div;
        lt_outside_business_low_type    :=  gt_inv_transactions_data( line_no ).outside_business_low_type;
        lt_inside_business_low_type     :=  gt_inv_transactions_data( line_no ).inside_business_low_type;
        lt_outside_cust_code            :=  gt_inv_transactions_data( line_no ).outside_cust_code; -- 出庫側顧客コード
        lt_inside_cust_code             :=  gt_inv_transactions_data( line_no ).inside_cust_code;  -- 入庫側顧客コード
        lt_hht_program_div              :=  gt_inv_transactions_data( line_no ).hht_program_div;
        lt_consume_vd_flag              :=  gt_inv_transactions_data( line_no ).consume_vd_flag; -- 消化VD補充対象フラグ
        lt_item_convert_div             :=  gt_inv_transactions_data( line_no ).item_convert_div;  -- 商品振替区分
        lt_stock_uncheck_list_div       :=  gt_inv_transactions_data( line_no ).stock_uncheck_list_div;
        lt_stock_balance_list_div       :=  gt_inv_transactions_data( line_no ).stock_balance_list_div;
        lt_status                       :=  gt_inv_transactions_data( line_no ).status;            -- 処理ステータス
        lt_column_if_flag               :=  gt_inv_transactions_data( line_no ).column_if_flag;  -- コラム別転送済フラグ
        lt_column_if_date               :=  gt_inv_transactions_data( line_no ).column_if_date;  -- コラム別転送日
        lt_sample_if_flag               :=  gt_inv_transactions_data( line_no ).sample_if_flag;  -- 見本転送済フラグ
        lt_sample_if_date               :=  gt_inv_transactions_data( line_no ).sample_if_date;  -- 見本転送日
        lt_output_flag                  :=  gt_inv_transactions_data( line_no ).output_flag;     -- 出力済フラグ
--
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
--        EXIT WHEN(lt_head_invoice_no <> lt_invoice_no);
        EXIT WHEN ( (lt_head_invoice_no <> lt_invoice_no) OR ( lt_head_inside_cust_code <> lt_inside_cust_code ) );
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
--
        --納品明細番号のカウント
        ln_invoice_line_num := ln_invoice_line_num + 1;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- 登録用明細ID取得
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--
--
        -- ==================
        -- 納品形態区分の導出
        -- ==================
        xxcos_common_pkg.get_delivered_from( lt_outside_subinv_code,
                                             lt_base_code, 
                                             lt_base_code, 
                                             gv_orga_code,
                                             gn_orga_id, 
                                             lv_delivery_type,
                                             lv_errbuf, 
                                             lv_retcode, 
                                             lv_errmsg );
        IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          RAISE delivered_from_err_expt;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
        END IF;
--
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
--      -- ===================
--      -- 納品拠点の導出
--      -- ===================
--      BEGIN
--        SELECT rin_v.base_code  --拠点コード
--        INTO lt_dlv_base_code
--        FROM xxcos_rs_info_v rin_v   --従業員情報view
--        WHERE rin_v.employee_number = lt_employee_num
--/*--==============2009/2/3-START=========================--*/
--        AND   NVL( rin_v.effective_start_date, lt_head_invoice_date ) <= lt_head_invoice_date
--        AND   NVL( rin_v.effective_end_date, lt_head_invoice_date ) >= lt_head_invoice_date;
--/*--==============2009/2/3-END=========================--*/
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            -- ログ出力
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
--            --キー編集用変数設定
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
----            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
----            lv_key_name2 := NULL;
----            lv_key_data1 := lt_employee_num;
----            lv_key_data2 := NULL;
----          RAISE no_data_extract;
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          xxcos_common_pkg.makeup_key_info(
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- 項目名称１
--            iv_data_value1 => lt_employee_num,         -- データの値１
--            ov_key_info    => gv_tkn2,              -- キー情報
--            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--            ov_retcode     => lv_retcode,           -- リターン・コード
--            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --アプリケーション短縮名
--                                                iv_name          => cv_msg_no_data,    --メッセージコード
--                                                iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                iv_token_value1  => gv_tkn1,           --トークン値1
--                                                iv_token_name2   => cv_key_data,       --トークンコード2
--                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--      END;
-- ************** 2009/05/13 1.13 N.Maeda DEL  END ****************************************************************
--
        -- ====================================
        -- 営業原価の導出(販売実績明細(コラム))
        -- ====================================
        BEGIN
          SELECT ic_item.attribute7,               -- 旧営業原価
                 ic_item.attribute8,               -- 新営業原価
                 ic_item.attribute9,               -- 営業原価適用開始日
                 mtl_item.primary_unit_of_measure, -- 基準単位
                 cmm_item.inc_num                  -- 内訳入数
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit,
                 lt_inc_num
          FROM   mtl_system_items_b    mtl_item,    -- 品目
                 ic_item_mst_b         ic_item,     -- OPM品目
                 xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = lt_item_code
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-end==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --キー編集処理
            -- ログ出力
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_item_code;
--            lv_key_data2 := gn_orga_id;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- 項目名称１
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- 項目名称２
            iv_data_value1 => lt_item_code,         -- データの値１
            iv_data_value2 => gn_orga_id,           -- データの値２
            ov_key_info    => gv_tkn2,              -- キー情報
            ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
            ov_retcode     => lv_retcode,           -- リターン・コード
            ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_msg_no_data,    --メッセージコード
                                                iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                iv_token_value1  => gv_tkn1,           --トークン値1
                                                iv_token_name2   => cv_key_data,       --トークンコード2
                                                iv_token_value2  => gv_tkn2 );         --トークン値2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
        END;
--
        -- ===================================
        -- 営業原価判定
        -- ===================================
        IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_head_invoice_date ) THEN
          lt_sales_cost := lt_old_sales_cost;
        ELSE
          lt_sales_cost := lt_new_sales_cost;
        END IF;
--
--
        --
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
          -- ========================
          -- 赤黒フラグ判定
          -- ========================
          IF ( lt_total_quantity < 0 ) THEN
            lt_red_black_flag := cv_red_black_flag_correct;
            -- 取消・訂正
            lt_cust_gyotai_sho := cn_correct_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
            lt_ins_invoice_type := lt_correct_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
          ELSE
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--            lt_red_black_flag := cn_red_black_flag_stand;
            lt_red_black_flag := cv_red_black_flag_stand;
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
            -- 正常
            lt_cust_gyotai_sho := cv_stand_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
            lt_ins_invoice_type := lt_normal_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--        -- =============================================
--        -- 販売実績明細（入出庫）変数へのセット
--        -- ============================================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;    -- 販売実績明細ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;            -- 販売実績ヘッダID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_invoice_no;           -- 納品伝票番号
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_invoice_line_num;     -- 納品明細番号
--        gt_line_sales_class( gn_line_data_no )             := cv_sales_class;          -- 売上区分
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;       -- 赤黒フラグ
--        gt_line_item_code( gn_line_data_no )               := lt_item_code;            -- 品目コード
--        gt_line_standard_qty( gn_line_data_no )            := lt_total_quantity;       -- 基準数量
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;           -- 基準単位
--        gt_line_standard_unit_price( gn_line_data_no )     := cv_standard_unit_price;  -- 基準単価
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
--        gt_line_sale_amount( gn_line_data_no )             := cv_sale_amount;          -- 売上金額
--        gt_line_pure_amount( gn_line_data_no )             := cv_pure_amount;          -- 本体金額
--        gt_line_tax_amount( gn_line_data_no )              := cv_tax_amount;           -- 消費税金額
--        gt_line_cash_and_card( gn_line_data_no )           := cv_cash_and_card;        -- 現金・カード併用額
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_outside_subinv_code;  -- 出荷元保管場所
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;        -- 納品拠点コード
--        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;             -- Ｈ＆Ｃ
--        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;             -- コラムNo
--        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;             -- 売切区分
--        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;             -- 売切時間
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                -- 手数料計算-IF済フラグ
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                -- 単価マスタ作成済フラグ
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                -- INVインタフェース済フラグ
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;             -- 注文明細番号(NULL設定)
--        gt_line_not_tax_amount( gn_line_data_no )          := cv_not_tax_amount;       -- 税抜基準単価
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;        -- 納品形態区分
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_total_quantity;       -- 納品数量
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;           -- 納品単位
--        gt_dlv_unit_price( gn_line_data_no )               := cv_standard_unit_price;  -- 納品単価
--        gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- 一時格納用
          -- ===================
          gt_accumulation_data(ln_line_data_count).row_id                     := lt_row_id;               -- 行ID
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_invoice_no;           -- 納品伝票番号
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_invoice_line_num;     -- 納品明細番号
          gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_class;          -- 売上区分
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;       -- 赤黒フラグ
          gt_accumulation_data(ln_line_data_count).item_code                  := lt_item_code;            -- 品目コード
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_total_quantity;       -- 納品数量
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_total_quantity;       -- 基準数量
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;           -- 納品単位
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;           -- 基準単位
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := cv_standard_unit_price;  -- 納品単価
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := cv_standard_unit_price;  -- 基準単価
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
          gt_accumulation_data(ln_line_data_count).sale_amount                := cv_sale_amount;          -- 売上金額
          gt_accumulation_data(ln_line_data_count).pure_amount                := cv_pure_amount;          -- 本体金額
          gt_accumulation_data(ln_line_data_count).tax_amount                 := cv_tax_amount;           -- 消費税金額
          gt_accumulation_data(ln_line_data_count).cash_and_card              := cv_cash_and_card;        -- 現金・カード併用額
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_outside_subinv_code; -- 出荷元保管場所
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;        -- 納品拠点コード
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;             -- Ｈ＆Ｃ
          gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;             -- コラムNo
          gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;             -- 売切区分
          gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;             -- 売切時間
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                -- 手数料計算インタフェース済フラグ
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                -- 単価マスタ作成済フラグ
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                -- INVインタフェース済フラグ
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;             -- 注文明細番号(NULL設定)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := cv_not_tax_amount;     -- 税抜基準単価
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;        -- 納品形態区分(導出)
--******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
        ELSE
          gn_wae_data_count := gn_wae_data_count + 1;
--******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
        END IF;
        ln_line_no := ln_line_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--
      END LOOP trans_loop;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
        --================================
        --販売実績ヘッダID(シーケンス取得)
        --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        -- =========================================
        -- ヘッダ情報格納処理
        -- =========================================
        gt_head_id( gn_head_data_no )                      := ln_actual_id;               -- 販売実績ヘッダID
        gt_head_order_no_ebs( gn_head_data_no )            := cv_tkn_null;                -- 受注番号
        gt_head_hht_invoice_no( gn_head_data_no )          := lt_head_invoice_no;         -- 納品伝票番号
        gt_head_order_no_hht( gn_head_data_no )            := cv_tkn_null;                -- 受注No(HHT)
        gt_head_digestion_ln_number( gn_head_data_no )     := cv_tkn_null;                -- 枝番(受注No(HHT)枝番)
        gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;        -- 納品伝票区分(導出)
        gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cust_gyotai_sho;         -- 取消・訂正区分
        gt_head_system_class( gn_head_data_no )            := lt_head_inside_business_low_t;  -- 業態区分(業態小分類)
        gt_head_dlv_date( gn_head_data_no )                := lt_head_invoice_date;       -- 納品日
        gt_head_inspect_date( gn_head_data_no )            := lt_head_invoice_date;       -- 検収日(売上計上日)
        gt_head_customer_number( gn_head_data_no )         := lt_head_inside_cust_code;   -- 顧客【納品先】
        gt_head_tax_include( gn_head_data_no )             := cn_tkn_zero;                -- 売上金額合計
        gt_head_total_amount( gn_head_data_no )            := cn_tkn_zero;                -- 本体金額合計
        gt_head_sales_consump_tax( gn_head_data_no )       := cn_tkn_zero;                -- 消費税金額合計(半導出)
        gt_head_consump_tax_class( gn_head_data_no )       := cv_tkn_null;                -- 消費税区分(導出)
        gt_head_tax_code( gn_head_data_no )                := lt_no_tax_code;             -- 税金コード(導出)
        gt_head_tax_rate( gn_head_data_no )                := cn_tkn_zero;                -- 消費税率(導出)
        gt_head_performance_by_code( gn_head_data_no )     := lt_head_employee_num;       -- 成績計上者コード
        gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;          -- 売上拠点コード(導出)
        gt_head_card_sale_class( gn_head_data_no )         := cv_tkn_null;                -- カード売り区分
--      gt_head_sales_classification( gn_head_data_no )    := lt_head_invoice_type;       -- 伝票区分
--      gt_head_invoice_class( gn_head_data_no )           := cv_tkn_null;                -- 伝票分類コード
        gt_head_sales_classification( gn_head_data_no )    := cv_tkn_null;                -- 伝票区分
        gt_head_invoice_class( gn_head_data_no )           := lt_head_invoice_type;       -- 伝票分類コード
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- 入金拠点コード(導出)
--        gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- 入金拠点コード(導出)
        gt_head_receiv_base_code( gn_head_data_no )        := cv_tkn_null;                -- 入金拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
        gt_head_change_out_time_100( gn_head_data_no )     := cv_tkn_null;                -- つり銭切れ時間100円
        gt_head_change_out_time_10( gn_head_data_no )      := cv_tkn_null;                -- つり銭切れ時間10円
        gt_head_hht_dlv_input_date( gn_head_data_no )      := lt_head_invoice_date;       -- HHT納品入力日時(成型日時)
        gt_head_dlv_by_code( gn_head_data_no )             := lt_head_employee_num;       -- 納品者コード
        gt_head_business_date( gn_head_data_no )           := gd_process_date;            -- 登録業務日付(初期処理取得)
        gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                -- 受注ソースID(NULL設定)
        gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                -- 注文伝票番号(NULL設定)
        gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                -- 受注関連番号(NULL設定)
        gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- AR-IF済フラグ('N')
        gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- GL-IF済フラグ('N')
        gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- 情報システム-IF済フラグ('N')
        gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- EDI送信済みフラグ('N'設定)
        gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                -- EDI送信日時(NULL設定)
-- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
--        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;        -- 作成元区分(｢4｣設定)
        gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;        -- 作成元区分(｢4｣設定)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_input_class( gn_head_data_no )             := cv_tkn_null;                -- 入力区分
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
----******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
--        gt_head_open_dlv_date( gn_head_data_no )           := lt_head_invoice_date;
--        gt_head_open_inspect_date( gn_head_data_no )       := lt_head_invoice_date;
----******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
        gt_head_open_dlv_date( gn_head_data_no )           := lt_open_dlv_date;
        gt_head_open_inspect_date( gn_head_data_no )       := lt_open_inspect_date;
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
        gn_head_data_no := gn_head_data_no + 1;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          ln_tran_rowid_num := ln_tran_rowid_num + 1;
--
          -- ===================
          -- 登録用明細ID取得
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
          gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- 納品伝票番号
          gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- 納品明細番号
          gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- 売上区分
          gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- 赤黒フラグ
          gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- 品目コード
          gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- 基準数量
          gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- 基準単位
          gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- 基準単価
          gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- 営業原価
          gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- 売上金額
          gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- 本体金額
          gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- 消費税金額
          gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- 現金・カード併用額
          gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- 出荷元保管場所
          gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- 納品拠点コード
          gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- Ｈ＆Ｃ
          gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- コラムNo
          gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- 売切区分
          gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- 売切時間
          gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- 手数料計算IF済フラグ
          gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- 単価マスタ作成済フラグ
          gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INVインタフェース済フラグ
          gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- 注文明細番号
          gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- 税抜基準単価
          gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- 納品形態区分
          gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- 納品数量
          gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- 納品単位
          gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- 納品単価
          gn_line_data_no := gn_line_data_no + 1;
          --
          gt_dlv_tran_head_row_id(ln_tran_rowid_num)               := gt_accumulation_data(in_data_num).row_id;
        END LOOP line_set_loop;
--******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
      ELSE
        gn_wae_data_count := gn_wae_data_count + ln_line_data_count;
        gn_warn_cnt       := gn_warn_cnt + 1;
--******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    END LOOP trans_head_loop;
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
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 # 
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_trans;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_edi
   * Description      : 販売実績データ（EDI）成型処理(A-4)
   ***********************************************************************************/
  PROCEDURE proc_molded_edi(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded_edi'; -- プログラム名
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
    --納品ヘッダ格納用変数
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- 枝番
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- 受注No.（EBS）
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- 拠点コード
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- 成績者コード
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- 納品者コード
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT伝票No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- 納品日
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- 検収日
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- 売上分類区分
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- 売上伝票区分
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- カード売り区分
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- 時間
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- 顧客コード
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- つり銭切れ時間100円
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- つり銭切れ時間10円
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- 業態区分
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- 入力区分
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- 消費税区分
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- 合計金額
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- 売上値引額
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- 売上消費税額
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- 税込金額
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- 預け先コード
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- 百貨店画面種別
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- 入出庫転送フラグ
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- 入出庫転送済日付
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- 販売実績連携済フラグ
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- 販売実績連携済日付
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- 取消・訂正区分
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- 赤黒フラグ
    --納品明細格納用変数
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- 受注No.（HHT）
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- 行No.（HHT）
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- 枝番
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- 受注No.（EBS）
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- 明細番号（EBS）
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- 品名コード（自社）
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- 入数
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- 品目ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- 基準単位
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- ケース数
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- 数量
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- 売上区分
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- 卸単価
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- 売単価
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- コラムNo.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- 売切区分
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- 売切時間
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- 補充数
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- 現金・カード併用額
    --OM受注情報格納用
    lt_om_order_number           oe_order_headers_all.order_number%TYPE;          -- 受注番号
    lt_om_header_id              oe_order_headers_all.header_id%TYPE;             -- 受注ヘッダID
    lt_om_he_flow_status_code       oe_order_headers_all.flow_status_code%TYPE;      -- ステータス
    lt_om_order_source_id        oe_order_headers_all.order_source_id%TYPE;       -- 受注ソースID
    lt_om_cust_po_number         oe_order_headers_all.cust_po_number%TYPE;        -- 顧客発注
    lt_om_line_id                oe_order_lines_all.line_id%TYPE;                 -- 受注明細ID
    lt_om_li_flow_status_code       oe_order_lines_all.flow_status_code%TYPE;        -- ステータス
    -- その他
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- 拠点コード
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- 旧営業原価
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- 新営業原価
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- 営業原価適用開始日
    lt_tax_odd                   hz_cust_accounts.tax_rounding_rule%TYPE;         -- 税金-端数処理
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- 消費税コード
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- 販売実績連携時の消費税区分
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- 消費税率
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- 基準単位
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; -- 税抜基準単価
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- 保管場所区分(営業車)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- 保管場所区分(百貨店)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所コード
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- 納品伝票区分
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT百貨店入力区分
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- 内訳入数
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- 売上拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- 入金拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- 営業原価
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 売上金額合計
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 本体金額合計
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 消費税金額合計
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--税抜基準単価
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- 基準単価
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- 売上金額
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- 本体金額
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- 消費税金額
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- 登録用基準数量(納品数量)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- 登録用売上金額
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- 登録用本体金額
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- 登録用消費税金額
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 登録用売上金額合計
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 登録用本体金額合計
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 登録用消費税金額合計
    ln_tax_data                  NUMBER;                                          -- 税込額算出用
    ln_line_no                   NUMBER :=  1;                                    -- 明細チェック済番号
    ln_cnt_om_order              NUMBER :=  1;                                    -- OM受注情報格納数
    ln_all_tax_amount            NUMBER :=  0;                                    -- 消費税金額合計値
    ln_max_tax_data              NUMBER :=  0;                                    -- 明細最大消費税額
    ln_max_invoice_num           NUMBER;                                          -- 値引明細用納品明細番号
    ln_actual_id                 NUMBER;                                          -- 販売実績ヘッダID
--    ln_sales_amount              NUMBER;                                          -- 売上金額
--    ln_consum_amount             NUMBER;                                          -- 消費税金額
--    ln_tax_odd                   NUMBER;                                          -- 消費税端数
--    ln_up_odd                    NUMBER;                                          -- 端数切り上げ数値
--    ]ln_amount_data               NUMBER;                                          -- 本体金額
--    lt_lin_sale_amount           NUMBER;                                          -- 売上金額
    ln_sales_exp_line_id         NUMBER;                                          -- 明細ID
    ln_discount_tax              NUMBER;                                          -- 値引消費税額
    ln_max_no_data               NUMBER;                                          -- ヘッダ最大消費税明細行番号
    ld_input_date                DATE;                                            -- HHT納品入力日時
    lv_delivery_type             VARCHAR2(100);                                   -- 納品形態区分
    lv_edi_order_name            VARCHAR2(100);                                   -- EDI受注
    lv_key_name1                 VARCHAR2(500);                                   -- キーデータ名称1
    lv_key_name2                 VARCHAR2(500);                                   -- キーデータ名称2
    lv_key_data1                 VARCHAR2(500);                                   -- キーデータ1
    lv_key_data2                 VARCHAR2(500);                                   -- キーデータ2
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
    ln_amount                    NUMBER;                                          -- 作業用金額変数
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- 更新用行ID
    lv_state_flg                 VARCHAR2(1);                                     -- データ警告確認フラグ
    ln_line_data_count           NUMBER;                                          -- 明細件数(ヘッダ単位)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT百貨店区分エラーフラグ
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
    ln_line_pure_amount_sum      NUMBER;                                          -- 明細合計本体金額
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--******************** 2009/05/18 N.Maeda Var1.15 START ******************************************
  lt_max_cancel_correct_class     xxcos_vd_column_headers.cancel_correct_class%TYPE;    -- 最新取消・訂正区分
  lt_min_digestion_ln_number      xxcos_vd_column_headers.digestion_ln_number%TYPE;     -- 枝番最小値
  ln_sales_exp_count              NUMBER :=0 ;                                          -- 更新対象販売実績件数カウント
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
  lt_order_no_hht_err             xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
  lt_order_no_hht_ok              xxcos_dlv_headers.order_no_hht%TYPE;
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  ***************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  lt_mon_sale_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_past_sale_base_code               xxcmm_cust_accounts.past_sale_base_code%TYPE;
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
  lt_open_dlv_date                xxcos_dlv_headers.dlv_date%TYPE;                 -- オープン済み納品日
  lt_open_inspect_date            xxcos_dlv_headers.inspect_date%TYPE;             -- オープン済み検収日
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--
    -- *** ローカル・カーソル ***
--******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
  -- ロック取得カーソル
  CURSOR get_lock_cur
  IS
    SELECT 'Y'
    FROM   xxcos_dlv_headers dhs
          ,xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--    WHERE  dhs.order_no_hht = dls.order_no_hht
--    AND    dhs.digestion_ln_number = dls.digestion_ln_number
    WHERE  dhs.order_no_hht = dls.order_no_hht(+)
    AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
    AND    dhs.order_no_hht = lt_order_no_hht
  FOR UPDATE OF dhs.order_no_hht,dls.digestion_ln_number
  NOWAIT;
--
  -- 明細情報取得カーソル
  CURSOR get_lines_cur
  IS
    SELECT dls.order_no_hht,          -- 受注No.（HHT）
           dls.line_no_hht,           -- 行No.（HHT）
           dls.digestion_ln_number,   -- 枝番
           dls.order_no_ebs,          -- 受注No.（EBS）
           dls.line_number_ebs,       -- 明細番号（EBS）
           dls.item_code_self,        -- 品名コード（自社）
           dls.content,               -- 入数
           dls.inventory_item_id,     -- 品目ID
           dls.standard_unit,         -- 基準単位
           dls.case_number,           -- ケース数
           dls.quantity,              -- 数量
           dls.sale_class,            -- 売上区分
           dls.wholesale_unit_ploce,  -- 卸単価
           dls.selling_price,         -- 売単価
           dls.column_no,             -- コラムNo.
           dls.h_and_c,               -- H/C
           dls.sold_out_class,        -- 売切区分
           dls.sold_out_time,         -- 売切時間
           dls.replenish_number,      -- 補充数
           dls.cash_and_card          -- 現金・カード併用額
    FROM   xxcos_dlv_lines dls              -- 納品明細
    WHERE  dls.order_no_hht        = lt_order_no_hht
    AND    dls.digestion_ln_number = lt_digestion_ln_number;
--
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
  CURSOR get_sales_exp_cur
    IS
      SELECT xseh.ROWID
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.order_no_hht = lt_order_no_hht
  FOR UPDATE NOWAIT;
--
--******************** 2009/05/18 N.Maeda Var1.15 ADD START ******************************************
    -- OM受注データ取得カーソル
    CURSOR get_oe_order_cur
    IS
      SELECT ooh.order_number      order_number,            -- 受注番号
             ooh.header_id         header_id,               -- 受注ヘッダID
             ooh.flow_status_code  head_flow_status_code,   -- ステータス
             ooh.order_source_id   order_source_id,         -- 受注ソースID
             ooh.cust_po_number    cust_po_number,          -- 顧客発注
             ool.line_id           line_id,                 -- 受注明細ID
             ool.flow_status_code  line_flow_status_code    -- ステータス
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
             ,ool.rowid            row_id                   -- 行ID
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
      FROM   oe_order_headers_all ooh,                      -- OM受注ヘッダ
             oe_order_lines_all ool,                        -- OM受注明細テーブル
             oe_order_sources oos                           -- オーダーソース
      WHERE  ooh.header_id = ool.header_id
      AND    ooh.order_source_id = oos.order_source_id
      AND    ool.order_source_id = oos.order_source_id
      AND    ooh.org_id = TO_NUMBER ( gv_salse_unit )
      AND    ooh.order_number = lt_order_no_ebs
      AND    ool.flow_status_code NOT IN ( cv_status_type_can , cv_status_type_clo )
      AND    oos.name = lv_edi_order_name
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
      AND    ool.global_attribute5 IS NULL
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
      ORDER BY ooh.order_number,ool.line_id
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
      FOR UPDATE OF  ool.global_attribute5
      NOWAIT
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- EDI受注名称取得
    lv_edi_order_name := xxccp_common_pkg.get_msg( cv_application, cv_order_s_name );
    -- ループ開始：ヘッダ部
    <<header_loop>>
    FOR ck_no IN 1..gn_target_edi_cnt LOOP
--
      --明細番号の初期化
--      ln_sales_exp_line_id            := 0;
      --積上消費税の初期化
      ln_all_tax_amount               := 0;
      --最大消費税額の初期化
      ln_max_tax_data                 := 0;
      -- 最大明細番号
      ln_max_no_data                  := 0;
      -- 最大行No
      ln_max_invoice_num              := 0;
      --積上営業原価合計
--      ln_all_sales_cost               := 0;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
      -- 明細合計本体金額
      ln_line_pure_amount_sum         := 0;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- 明細件数カウント(初期化)
      ln_line_data_count              := 0;
      -- データ警告確認フラグ(初期化)
      lv_state_flg                    := cv_status_normal;
      -- HHT百貨店区分エラー(初期化)
      lv_dept_hht_div_flg             := cv_status_normal;
--
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
--      lt_row_id                    := gt_dlv_edi_headers_data( ck_no ).row_id;                   -- 行ID
----******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := gt_dlv_edi_headers_data( ck_no ).order_no_hht;             -- 受注No.(HHT)
      lt_digestion_ln_number       := gt_dlv_edi_headers_data( ck_no ).digestion_ln_number;      -- 枝番
--      lt_order_no_ebs              := gt_dlv_edi_headers_data( ck_no ).order_no_ebs;             -- 受注No.（EBS）
--      lt_base_code                 := gt_dlv_edi_headers_data( ck_no ).base_code;                -- 拠点コード
--      lt_performance_by_code       := gt_dlv_edi_headers_data( ck_no ).performance_by_code;      -- 成績者コード
--      lt_dlv_by_code               := gt_dlv_edi_headers_data( ck_no ).dlv_by_code;              -- 納品者コード
      lt_hht_invoice_no            := gt_dlv_edi_headers_data( ck_no ).hht_invoice_no;           -- HHT伝票No.
--      lt_dlv_date                  := gt_dlv_edi_headers_data( ck_no ).dlv_date;                 -- 納品日
--      lt_inspect_date              := gt_dlv_edi_headers_data( ck_no ).inspect_date;             -- 検収日
--      lt_sales_classification      := gt_dlv_edi_headers_data( ck_no ).sales_classification;     -- 売上分類区分
--      lt_sales_invoice             := gt_dlv_edi_headers_data( ck_no ).sales_invoice;            -- 売上伝票区分
--      lt_card_sale_class           := gt_dlv_edi_headers_data( ck_no ).card_sale_class;          -- カード売り区分
--      lt_dlv_time                  := gt_dlv_edi_headers_data( ck_no ).dlv_time;                 -- 時間
--      lt_customer_number           := gt_dlv_edi_headers_data( ck_no ).customer_number;          -- 顧客コード
--      lt_change_out_time_100       := gt_dlv_edi_headers_data( ck_no ).change_out_time_100;      -- つり銭切れ時間100円
--      lt_change_out_time_10        := gt_dlv_edi_headers_data( ck_no ).change_out_time_10;       -- つり銭切れ時間10円
--      lt_system_class              := gt_dlv_edi_headers_data( ck_no ).system_class;             -- 業態区分
--      lt_input_class               := gt_dlv_edi_headers_data( ck_no ).input_class;              -- 入力区分
--      lt_consumption_tax_class     := gt_dlv_edi_headers_data( ck_no ).consumption_tax_class;    -- 消費税区分
--      lt_total_amount              := gt_dlv_edi_headers_data( ck_no ).total_amount;             -- 合計金額
--      lt_sale_discount_amount      := gt_dlv_edi_headers_data( ck_no ).sale_discount_amount;     -- 売上値引額
--      lt_sales_consumption_tax     := gt_dlv_edi_headers_data( ck_no ).sales_consumption_tax;    -- 売上消費税額
--      lt_tax_include               := gt_dlv_edi_headers_data( ck_no ).tax_include;              -- 税込金額
--      lt_keep_in_code              := gt_dlv_edi_headers_data( ck_no ).keep_in_code;             -- 預け先コード
--      lt_department_screen_class   := gt_dlv_edi_headers_data( ck_no ).department_screen_class;  -- 百貨店画面種別
--      lt_red_black_flag            := gt_dlv_edi_headers_data( ck_no ).red_black_flag;           -- 赤黒フラグ
--      lt_stock_forward_flag        := gt_dlv_edi_headers_data( ck_no ).stock_forward_flag;       -- 入出庫転送フラグ
--      lt_stock_forward_date        := gt_dlv_edi_headers_data( ck_no ).stock_forward_date;       -- 入出庫転送済日付
--      lt_results_forward_flag      := gt_dlv_edi_headers_data( ck_no ).results_forward_flag;     -- 販売実績連携済フラグ
--      lt_results_forward_date      := gt_dlv_edi_headers_data( ck_no ).results_forward_date;     -- 販売実績連携済日付
--      lt_cancel_correct_class      := gt_dlv_edi_headers_data( ck_no ).cancel_correct_class;     -- 取消・訂正区分
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
       BEGIN
--
         IF ( lt_order_no_hht_err <> lt_order_no_hht ) OR ( lt_order_no_hht_err IS NULL ) THEN
--
           IF ( lt_order_no_hht_ok <> lt_order_no_hht ) OR ( lt_order_no_hht_ok IS NULL ) THEN
             -- ロック取得
             OPEN  get_lock_cur;
             CLOSE get_lock_cur;
           END IF;
--
         -- 納品ヘッダ情報取得
         SELECT dhs.ROWID                    -- 行ID
               ,dhs.order_no_ebs             -- 受注No.（EBS）
               ,dhs.base_code                -- 拠点コード
               ,dhs.performance_by_code      -- 成績者コード
               ,dhs.dlv_by_code              -- 納品者コード
               ,dhs.dlv_date                 -- 納品日
               ,dhs.inspect_date             -- 検収日
               ,dhs.sales_classification     -- 売上分類区分
               ,dhs.sales_invoice            -- 売上伝票区分
               ,dhs.card_sale_class          -- カード売り区分
               ,dhs.dlv_time                 -- 時間
               ,dhs.customer_number          -- 顧客コード
               ,dhs.change_out_time_100      -- つり銭切れ時間100円
               ,dhs.change_out_time_10       -- つり銭切れ時間10円
               ,dhs.system_class             -- 業態区分
               ,dhs.input_class              -- 入力区分
               ,dhs.consumption_tax_class    -- 消費税区分
               ,dhs.total_amount             -- 合計金額
               ,dhs.sale_discount_amount     -- 売上値引額
               ,dhs.sales_consumption_tax    -- 売上消費税額
               ,dhs.tax_include              -- 税込金額
               ,dhs.keep_in_code             -- 預け先コード
               ,dhs.department_screen_class  -- 百貨店画面種別
               ,dhs.red_black_flag           -- 赤・黒フラグ
               ,dhs.stock_forward_flag       -- 入出庫転送フラグ
               ,dhs.stock_forward_date       -- 入出庫転送済日付
               ,dhs.results_forward_flag     -- 販売実績連携済フラグ
               ,dhs.results_forward_date     -- 販売実績連携済日付
               ,dhs.cancel_correct_class     -- 取消・訂正区分
         INTO   lt_row_id
               ,lt_order_no_ebs
               ,lt_base_code
               ,lt_performance_by_code
               ,lt_dlv_by_code
               ,lt_dlv_date
               ,lt_inspect_date
               ,lt_sales_classification
               ,lt_sales_invoice
               ,lt_card_sale_class
               ,lt_dlv_time
               ,lt_customer_number
               ,lt_change_out_time_100
               ,lt_change_out_time_10
               ,lt_system_class
               ,lt_input_class
               ,lt_consumption_tax_class
               ,lt_total_amount
               ,lt_sale_discount_amount
               ,lt_sales_consumption_tax
               ,lt_tax_include
               ,lt_keep_in_code
               ,lt_department_screen_class
               ,lt_red_black_flag
               ,lt_stock_forward_flag
               ,lt_stock_forward_date
               ,lt_results_forward_flag
               ,lt_results_forward_date
               ,lt_cancel_correct_class
         FROM   xxcos_dlv_headers dhs            -- 納品ヘッダ
         WHERE  dhs.order_no_hht        = lt_order_no_hht
         AND    dhs.digestion_ln_number = lt_digestion_ln_number
         AND    dhs.hht_invoice_no      = lt_hht_invoice_no
         ORDER BY dhs.order_no_hht,dhs.hht_invoice_no;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --      --================================
    --      --販売実績ヘッダID(シーケンス取得)
    --      --================================
    --      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
    --      INTO ln_actual_id
    --      FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
    --
--
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
        --==================================
        -- 1.納品日算出
        --==================================
        get_fiscal_period_from(
            iv_div        => cv_fiscal_period_inv            -- 会計区分
          , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
          , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
          , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
          , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
          , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
                                                iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                iv_token_value2  => lt_order_no_hht,
                                                iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
                                                iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ),
                                                iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                iv_token_name5   => cv_cust_code,                --トークンコード5
                                                iv_token_value5  => lt_customer_number           --トークン値5
                                              );
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
        END IF;
--
        --==================================
        -- 2.売上計上日算出
        --==================================
        get_fiscal_period_from(
            iv_div        => cv_fiscal_period_inv                 -- 会計区分
          , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
          , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
          , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
          , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
          , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
                                                iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                iv_token_value2  => lt_order_no_hht,
                                                iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
                                                iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ),
                                                iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                iv_token_name5   => cv_cust_code,                --トークンコード5
                                                iv_token_value5  => lt_customer_number           --トークン値5
                                              );
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
          --汎用エラーリスト出力情報設定(A-12)
          set_gen_err_list(
             it_base_code                => lt_base_code                              --拠点コード
           , it_message_name             => ct_msg_fiscal_period_err                  --エラーメッセージ名
           , it_message_text             => NULL                                      --エラーメッセージ
           , iv_output_msg_name_branch   => NULL                                      --エラーメッセージ名枝番
           , iv_output_msg_application   => cv_application                            --アプリケーション名
           , iv_output_msg_name          => ct_msg_xxcos_00216                        --メッセージコード
           , iv_output_msg_token_name1   => cv_tkn_order_number                       --トークンコード1
           , iv_output_msg_token_value1  => TO_CHAR( lt_order_no_hht )                --トークン値1：受注番号
           , iv_output_msg_token_name2   => cv_tkn_base_date                          --トークンコード2
           , iv_output_msg_token_value2  => TO_CHAR( lt_inspect_date,cv_stand_date )  --トークン値2：基準日
           , iv_output_msg_token_name3   => cv_invoice_no                             --トークンコード3
           , iv_output_msg_token_value3  => lt_hht_invoice_no                         --トークン値3：HHT伝票番号
           , iv_output_msg_token_name4   => cv_cust_code                              --トークンコード4
           , iv_output_msg_token_value4  => lt_customer_number                        --トークン値4：顧客コード
           , ov_errbuf                   => lv_errbuf
           , ov_retcode                  => lv_retcode
           , ov_errmsg                   => lv_errmsg
          );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
        END IF;
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--
          --=========================
          --顧客マスタ付帯情報の導出
          --=========================
          BEGIN
-- ****************** 2009/08/10 1.18 N.Maeda MOD START **************************************************************--
-- ***************** 2009/08/21 1.20 N.Maeda MOD START ******************** --
            SELECT  /*+ leading(xch) */
                    xca.sale_base_code         sale_base_code        -- 売上拠点コード
                    ,xch.cash_receiv_base_code cash_receiv_base_code -- 入金拠点コード
                    ,xch.bill_tax_round_rule   bill_tax_round_rule   -- 税金-端数処理(サイト)
                    ,xca.past_sale_base_code   past_sale_base_code   -- 前月売上拠点コード
            INTO    lt_mon_sale_base_code
                    ,lt_cash_receiv_base_code
                    ,lt_tax_odd
                    ,lt_past_sale_base_code
            FROM    hz_cust_accounts        hca    -- 顧客マスタ
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
--
--            SELECT  /*+
--                      USE_NL(xch.cust_hier.cash_hcar_3)
--                      USE_NL(xch.cust_hier.bill_hasa_3)
--                      USE_NL(xch.cust_hier.bill_hasa_4)
--                    */
--                    xch.ship_sale_base_code,         -- 売上拠点コード
--                    xch.cash_receiv_base_code,  -- 入金拠点コード
--                    xch.bill_tax_round_rule     -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--                    lt_cash_receiv_base_code,
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,       -- 顧客マスタ
--                    xxcos_cust_hierarchy_v xch  -- 顧客階層ビュー
--            WHERE   xch.ship_account_id = hca.cust_account_id
--            AND     hca.account_number  = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
-- ***************** 2009/08/21 1.20 N.Maeda MOD  END  ******************** --
--            SELECT  xca.sale_base_code, --売上拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    xch.cash_receiv_base_code,  --入金拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    --hca.tax_rounding_rule --税金-端数処理
--                    xch.bill_tax_round_rule -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    lt_cash_receiv_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,  --顧客マスタ
--                    xxcmm_cust_accounts xca, --顧客追加情報
--                    xxcos_cust_hierarchy_v xch -- 顧客階層ビュー
--            WHERE   hca.cust_account_id = xca.customer_id
--            AND     xch.ship_account_id = hca.cust_account_id
--            AND     xch.ship_account_id = xca.customer_id
--            AND     hca.account_number = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
---- ********* 2009/08/06 1.18 N.Maeda MOD START **************************** --
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
----            AND     hca.party_id IN ( SELECT  hpt.party_id
----                                      FROM    hz_parties hpt
----                                      WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
---- ********* 2009/08/06 1.18 N.Maeda MOD  END  **************************** --
-- ****************** 2009/08/10 1.18 N.Maeda MOD  END  **************************************************************--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --キー編集処理
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
                iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- データの値１
                iv_data_value2 => lt_customer_number,       -- データの値２
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
-- ********* 2009/09/04 1.21 N.Maeda DEL START **************** --
--          --========================
--          --消費税コードの導出(HHT)
--          --========================
--          BEGIN
---- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
--            SELECT  look_val.attribute2,  --消費税コード
--                    look_val.attribute3   --販売実績連携時の消費税区分
--            INTO    lt_consum_code,
--                    lt_consum_type
--            FROM    fnd_lookup_values     look_val
--            WHERE   look_val.language     = ct_user_lang
--            AND     gd_process_date      >= look_val.start_date_active
--            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--            AND     look_val.enabled_flag = cv_tkn_yes
--            AND     look_val.lookup_type  = cv_lookup_type
--            AND     look_val.lookup_code  = lt_consumption_tax_class;
----
----            SELECT  look_val.attribute2,  --消費税コード
----                    look_val.attribute3   --販売実績連携時の消費税区分
----            INTO    lt_consum_code,
----                    lt_consum_type
----            FROM    fnd_lookup_values     look_val,
----                    fnd_lookup_types_tl   types_tl,
----                    fnd_lookup_types      types,
----                    fnd_application_tl    appl,
----                    fnd_application       app
----            WHERE   appl.application_id   = types.application_id
----            AND     app.application_id    = appl.application_id
----            AND     types_tl.lookup_type  = look_val.lookup_type
----            AND     types.lookup_type     = types_tl.lookup_type
----            AND     types.security_group_id   = types_tl.security_group_id
----            AND     types.view_application_id = types_tl.view_application_id
----            AND     types_tl.language = USERENV( 'LANG' )
----            AND     look_val.language = USERENV( 'LANG' )
----            AND     appl.language     = USERENV( 'LANG' )
----            AND     app.application_short_name = cv_application
----            AND     gd_process_date      >= look_val.start_date_active
----            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
----            AND     look_val.enabled_flag = cv_tkn_yes
----            AND     look_val.lookup_type = cv_lookup_type
----            AND     look_val.lookup_code = lt_consumption_tax_class;
---- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ログ出力
--              gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
--              --キー編集処理
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--    --          lv_key_data1 := lt_consumption_tax_class;
--    --          lv_key_data2 := cv_lookup_type;
--    --          RAISE no_data_extract;
--              lv_state_flg    := cv_status_warn;
--              gn_wae_data_num := gn_wae_data_num + 1 ;
--              xxcos_common_pkg.makeup_key_info(
--                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称１
--                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- 項目名称２
--                iv_data_value1 => lt_consumption_tax_class,         -- データの値１
--                iv_data_value2 => cv_lookup_type,       -- データの値２
--                ov_key_info    => gv_tkn2,              -- キー情報
--                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                ov_retcode     => lv_retcode,           -- リターン・コード
--                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                    iv_application   => cv_application,    --アプリケーション短縮名
--                                                    iv_name          => cv_msg_no_data,    --メッセージコード
--                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                    iv_token_value1  => gv_tkn1,           --トークン値1
--                                                    iv_token_name2   => cv_key_data,       --トークンコード2
--                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--          END;
-- ********* 2009/09/04 1.21 N.Maeda DEL  END  **************** --
--
          --====================
          --消費税マスタ情報取得
          --====================
          BEGIN
-- ********* 2009/09/04 1.21 N.Maeda MOD START **************** --
            SELECT  xtv.tax_rate             -- 消費税率
                   ,xtv.tax_class                -- 販売実績連携消費税区分
                   ,xtv.tax_code             -- 税金コード
            INTO    lt_tax_consum
                   ,lt_consum_type
                   ,lt_consum_code
            FROM   xxcos_tax_v   xtv         -- 消費税view
            WHERE  xtv.hht_tax_class    = lt_consumption_tax_class
            AND    xtv.set_of_books_id  = TO_NUMBER( gv_bks_id )
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
--            AND    NVL( xtv.start_date_active, lt_inspect_date )  <= lt_inspect_date
--            AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_inspect_date;
            AND    NVL( xtv.start_date_active, lt_open_inspect_date )  <= lt_open_inspect_date
            AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_open_inspect_date;
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
--
--            SELECT avtab.tax_rate           -- 消費税率
--            INTO   lt_tax_consum 
--            FROM   ar_vat_tax_all_b avtab   -- AR消費税マスタ
--            WHERE  avtab.tax_code = lt_consum_code
--            AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
--            AND    NVL( avtab.start_date, lt_inspect_date )  <= lt_inspect_date
--            AND    NVL( avtab.end_date, gd_max_date ) >= lt_inspect_date
--    /*--==============2009/2/4-START=========================--*/
--            AND    NVL( avtab.start_date, gd_process_date )  <= gd_process_date
--            AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
--    /*--==============2009/2/4-end==========================--*/
--    /*--==============2009/2/17-START=========================--*/
--            AND    avtab.enabled_flag = cv_tkn_yes;
--    /*--==============2009/2/17--END==========================--*/
-- ********* 2009/09/04 1.21 N.Maeda MOD  END  **************** --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
              --キー編集処理
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
    --          lv_key_name2 := NULL;
    --          lv_key_data1 := lt_consum_code;
    --          lv_key_data2 := NULL;
    --          RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
-- ********* 2009/09/04 1.21 N.Maeda MOD START **************** --
--              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- 項目名称１
--              iv_data_value1 => lt_consum_code,         -- データの値１
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_order_num_hht ), -- 項目名称１
                iv_data_value1 => lt_order_no_hht,
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_digestion_number ), -- 項目名称
                iv_data_value2 => lt_digestion_ln_number,
                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称
                iv_data_value3 => lt_consumption_tax_class,
-- ********* 2009/09/04 1.21 N.Maeda MOD  END  **************** --
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
          -- 消費税率算出
          ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
          -- =========================
          -- HHT納品入力日時の成型処理
          -- =========================
          ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                                  SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
    --
          -- ==================================
          -- 出荷元保管場所の導出
          -- ==================================
    --
          --出荷元保管場所の導出
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
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
              --キー編集処理
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
    --          lv_key_data1 := lt_base_code;
    --          lv_key_data2 := cv_bace_branch;
    --        RAISE no_data_extract;
              lv_dept_hht_div_flg := cv_status_warn;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
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
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    /*--==============2009/2/3-START=========================--*/
    --      IF ( lv_depart_code = cv_depart_car ) THEN
            IF ( lv_depart_code IS NULL )
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    /*--==============2009/2/3-end==========================--*/
              --参照コードマスタ：営業車の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
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
--                SELECT  look_val.meaning      --保管場所分類コード
--                INTO    lt_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_05;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
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
                FROM   mtl_secondary_inventories msi    --保管場所マスタ
                WHERE  msi.attribute7 = lt_base_code
                AND    msi.attribute13 = lt_location_type_code
                AND    msi.attribute3 = lt_dlv_by_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
                  --キー編集処理用変数
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_05;
    --            RAISE no_data_extract;
                  lv_state_flg    := cv_status_warn;
                  gn_wae_data_num := gn_wae_data_num + 1 ;
                  xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                    iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                  iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_dlv_by_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称4
                  iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  iv_data_value1 => lt_base_code,         -- データの値１
    --              iv_data_value2 => cv_xxcos_001_a05_05,       -- データの値２
                  iv_data_value2 => lt_location_type_code,       -- データの値２
                  iv_data_value3 => lt_dlv_by_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_data_value4 => lt_hht_invoice_no,         -- データの値4
                    iv_data_value5 => lt_customer_number,        -- データの値5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    ov_key_info    => gv_tkn2,              -- キー情報
                    ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                    ov_retcode     => lv_retcode,           -- リターン・コード
                    ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                  gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                        iv_application   => cv_application,    --アプリケーション短縮名
                                                        iv_name          => cv_msg_no_data,    --メッセージコード
                                                        iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                        iv_token_value1  => gv_tkn1,           --トークン値1
                                                        iv_token_name2   => cv_key_data,       --トークンコード2
                                                        iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  --汎用エラーリスト出力情報設定(A-12)
                  set_gen_err_list(
                     it_base_code                => lt_base_code           --拠点コード
                   , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                   , it_message_text             => gv_tkn2                --エラーメッセージ
                   , iv_output_msg_name_branch   => cv_msg_branch_num_01   --メッセージ名枝番
                   , ov_errbuf                   => lv_errbuf
                   , ov_retcode                  => lv_retcode
                   , ov_errmsg                   => lv_errmsg
                  );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
    /*--==============2009/2/3-START=========================--*/
    --      ELSIF ( lv_depart_code = cv_depart_type ) THEN
    --      ELSIF ( lv_depart_code IS NOT NULL ) THEN
            ELSIF ( lv_depart_code = cv_depart_type ) 
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    /*--==============2009/2/3-END==========================--*/
              --参照コードマスタ：百貨店の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  look_val.meaning    --保管場所分類コード
                INTO    lt_depart_location_type_code
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_hokan_mst_001_a05
                AND     look_val.lookup_code  = cv_xxcos_001_a05_09;
--
--                SELECT  look_val.meaning    --保管場所分類コード
--                INTO    lt_depart_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_09;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
              --キー編集処理
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
                SELECT msi.secondary_inventory_name           -- 保管場所名称
                INTO   lt_secondary_inventory_name
                FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
                       mtl_parameters mp                      -- 組織パラメータ
                WHERE  msi.organization_id=mp.organization_id
                AND    mp.organization_code = gv_orga_code
                AND    msi.attribute4       = lt_keep_in_code
                AND    msi.attribute13      = lt_depart_location_type_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
                  --キー編集処理用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_09;
    --            RAISE no_data_extract;
                  lv_state_flg    := cv_status_warn;
                  gn_wae_data_num := gn_wae_data_num + 1 ;
                  xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                    iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_keep_in_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),   -- 項目名称4
                    iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ),  -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    iv_data_value1 => lt_base_code,         -- データの値１
    --                iv_data_value2 => cv_xxcos_001_a05_09,       -- データの値２
                    iv_data_value2 => lt_depart_location_type_code,       -- データの値２
                    iv_data_value3 => lt_keep_in_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_data_value4 => lt_hht_invoice_no,                  -- データの値4
                    iv_data_value5 => lt_customer_number,                 -- データの値5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    ov_key_info    => gv_tkn2,              -- キー情報
                    ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                    ov_retcode     => lv_retcode,           -- リターン・コード
                    ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                  gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                        iv_application   => cv_application,    --アプリケーション短縮名
                                                        iv_name          => cv_msg_no_data,    --メッセージコード
                                                        iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                        iv_token_value1  => gv_tkn1,           --トークン値1
                                                        iv_token_name2   => cv_key_data,       --トークンコード2
                                                        iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  --汎用エラーリスト出力情報設定(A-12)
                  set_gen_err_list(
                     it_base_code                => lt_base_code           --拠点コード
                   , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                   , it_message_text             => gv_tkn2                --エラーメッセージ
                   , iv_output_msg_name_branch   => cv_msg_branch_num_02   --メッセージ名枝番
                   , ov_errbuf                   => lv_errbuf
                   , ov_retcode                  => lv_retcode
                   , ov_errmsg                   => lv_errmsg
                  );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --
          -- ==================
          -- 納品形態区分の導出
          -- ==================
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
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        RAISE delivered_from_err_expt;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,
                                                    iv_name          => cv_msg_delivered_from_err );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
          END IF;
    --
          -- ===================
          -- 納品拠点の導出
          -- ===================
          BEGIN
--************* 2009/08/12 N.Maeda Var1.19 MOD START ***************************************
            SELECT rin_v.base_code  base_code -- 拠点コード
            INTO   lt_dlv_base_code
--************* 2009/10/30 M.Sano  Var1.23 MOD START ***************************************
--            FROM   xxcos_rs_info_v  rin_v        -- 従業員情報view
            FROM   xxcos_rs_info2_v rin_v        -- 従業員情報view
--************* 2009/10/30 M.Sano  Var1.23 MOD  END  ***************************************
            WHERE  rin_v.employee_number = lt_dlv_by_code
            AND    NVL( rin_v.effective_start_date     , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.effective_end_date       , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.per_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.per_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.paa_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.paa_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            ;
--
--            SELECT rin_v.base_code  --拠点コード
--            INTO lt_dlv_base_code
--            FROM xxcos_rs_info_v rin_v   --従業員情報view
--            WHERE rin_v.employee_number = lt_dlv_by_code
--    /*--==============2009/2/3-START=========================--*/
--            AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
--            AND   NVL( rin_v.effective_end_date, lt_dlv_date ) >= lt_dlv_date;
--    /*--==============2009/2/3-END=========================--*/
--************* 2009/08/12 N.Maeda Var1.19 MOD  END  ***************************************
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
              --キー編集用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
    --            lv_key_name2 := NULL;
    --            lv_key_data1 := lt_dlv_by_code;
    --            lv_key_data2 := NULL;
    --        RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- 項目名称１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称２
                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                iv_data_value1 => lt_dlv_by_code,         -- データの値１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                iv_data_value2 => lt_hht_invoice_no,      -- データの値２
                iv_data_value3 => lt_customer_number,     -- データの値３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
              --汎用エラーリスト出力情報設定(A-12)
              set_gen_err_list(
                 it_base_code                => lt_base_code           --拠点コード
               , it_message_name             => cv_msg_no_data         --エラーメッセージ名
               , it_message_text             => gv_tkn2                --エラーメッセージ
               , iv_output_msg_name_branch   => cv_msg_branch_num_03   --メッセージ名枝番
               , ov_errbuf                   => lv_errbuf
               , ov_retcode                  => lv_retcode
               , ov_errmsg                   => lv_errmsg
              );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
          END;
    --
          -- =====================
          -- 納品伝票入力区分の導出
          -- =====================
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --        -- 入力区分が｢納品入力・EOS伝票入力｣or｢自販機売上｣or｢返品入力｣or｢自販機返品｣かつ赤黒フラグが赤の時
    --        IF ( ( ( lt_input_class = cv_input_class_eos ) OR ( lt_input_class = cv_input_class_vd ) 
    --             OR  ( lt_input_class = cv_input_class_rt ) OR ( lt_input_class = cv_input_class_vd_rt ) ) 
    --           AND ( lt_red_black_flag =  cv_red_flag ) ) THEN
              BEGIN
    --            SELECT  look_val.attribute5  -- 訂正・取消時(納品伝票区分(販売実績入力区分))
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  DECODE( lt_digestion_ln_number, 
                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
                INTO    lt_ins_invoice_type
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_input_class
                AND     look_val.lookup_code  = lt_input_class;
--
--                SELECT  DECODE( lt_digestion_ln_number, 
--                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
--                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
--                INTO    lt_ins_invoice_type
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_input_class
--                AND     look_val.lookup_code = lt_input_class;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
                  --キー編集表変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
    --              lv_key_name2 := NULL;
    --              lv_key_data1 := lt_input_class;
    --              lv_key_data2 := NULL;
    --            RAISE no_data_extract;
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
                                                        iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                        iv_token_value1  => gv_tkn1,           --トークン値1
                                                        iv_token_name2   => cv_key_data,       --トークンコード2
                                                        iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
              END;
    ----
    --        --入力区分がその他の場合
    --        ELSE
    --          BEGIN
    --            SELECT  look_val.attribute4   -- 通常時(納品伝票区分(販売実績入力区分))
    --            INTO    lt_ins_invoice_type
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
    --            AND     look_val.lookup_type = cv_xxcos1_input_class
    --            AND     look_val.lookup_code = lt_input_class;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力          
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
    --              --キー編集表変数設定
    ----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    ----              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
    ----              lv_key_name2 := NULL;
    ----              lv_key_data1 := lt_input_class;
    ----              lv_key_data2 := NULL;
    ----            RAISE no_data_extract;
    --              lv_state_flg    := cv_status_warn;
    --              gn_wae_data_num := gn_wae_data_num + 1 ;
    --              xxcos_common_pkg.makeup_key_info(
    --                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- 項目名称１
    --                iv_data_value1 => lt_input_class,         -- データの値１
    --                ov_key_info    => gv_tkn2,              -- キー情報
    --                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
    --                ov_retcode     => lv_retcode,           -- リターン・コード
    --                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
    --              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
    --                                                    iv_application   => cv_application,    --アプリケーション短縮名
    --                                                    iv_name          => cv_msg_no_data,    --メッセージコード
    --                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
    --                                                    iv_token_value1  => gv_tkn1,           --トークン値1
    --                                                    iv_token_name2   => cv_key_data,       --トークンコード2
    --                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    ----******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
    --          END;
    --        END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
-- **************** 2009/10/13 1.22 N.Maeda ADD START **************** --
          BEGIN
            OPEN  get_oe_order_cur;
            -- バルクフェッチ
            FETCH get_oe_order_cur BULK COLLECT INTO gt_oe_order_all;
            -- 抽出件数セット
            gn_om_data_cnt := get_oe_order_cur%ROWCOUNT;
            -- カーソルCLOSE
            CLOSE get_oe_order_cur;
          EXCEPTION
            WHEN lock_err_expt THEN
              IF( get_oe_order_cur%ISOPEN ) THEN
                CLOSE get_oe_order_cur;
              END IF;
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              gn_om_data_cnt  := 0;
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,            --アプリケーション短縮名
                                                    iv_name          => cv_order_lock_err,         --メッセージコード
                                                    iv_token_name1   => cv_tkn_order_number,       --トークンコード2
                                                    iv_token_value1  => lt_order_no_hht,
                                                    iv_token_name2   => cv_order_number_ebs,
                                                    iv_token_value2  => lt_order_no_ebs,
                                                    iv_token_name3   => cv_invoice_no,
                                                    iv_token_value3  => lt_hht_invoice_no);
            WHEN OTHERS THEN
              IF( get_oe_order_cur%ISOPEN ) THEN
                CLOSE get_oe_order_cur;
              END IF;
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
              --キー編集表変数設定
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- 項目名称１
                iv_data_value1 => lt_order_no_ebs,         -- データの値１
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
          END;
-- **************** 2009/10/13 1.22 N.Maeda MOD  END  **************** --
--
          --明細データ取得
          <<line_loop>>
  --******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
          FOR get_lines_rec IN get_lines_cur LOOP
            lt_lin_order_no_hht          := get_lines_rec.order_no_hht;          -- 受注No.（HHT）
            lt_lin_line_no_hht           := get_lines_rec.line_no_hht;           -- 行No.（HHT）
            lt_lin_digestion_ln_number   := get_lines_rec.digestion_ln_number;   -- 枝番
            lt_lin_order_no_ebs          := get_lines_rec.order_no_ebs;          -- 受注No.（EBS）
            lt_lin_line_number_ebs       := get_lines_rec.line_number_ebs;       -- 明細番号（EBS）
            lt_lin_item_code_self        := get_lines_rec.item_code_self;        -- 品名コード（自社）
            lt_lin_content               := get_lines_rec.content;               -- 入数
            lt_lin_inventory_item_id     := get_lines_rec.inventory_item_id;     -- 品目ID
            lt_lin_standard_unit         := get_lines_rec.standard_unit;         -- 基準単位
            lt_lin_case_number           := get_lines_rec.case_number;           -- ケース数
            lt_lin_quantity              := get_lines_rec.quantity;              -- 数量
            lt_lin_sale_class            := get_lines_rec.sale_class;            -- 売上区分
            lt_lin_wholesale_unit_ploce  := get_lines_rec.wholesale_unit_ploce;  -- 卸単価
            lt_lin_selling_price         := get_lines_rec.selling_price;         -- 売単価
            lt_lin_column_no             := get_lines_rec.column_no;             -- コラムNo.
            lt_lin_h_and_c               := get_lines_rec.h_and_c;               -- H/C
            lt_lin_sold_out_class        := get_lines_rec.sold_out_class;        -- 売切区分
            lt_lin_sold_out_time         := get_lines_rec.sold_out_time;         -- 売切時間
            lt_lin_replenish_number      := get_lines_rec.replenish_number;      -- 補充数
            lt_lin_cash_and_card         := get_lines_rec.cash_and_card;         -- 現金・カード併用額
  --        FOR line_no IN ln_line_no..gn_line_edi_cnt LOOP
  --          lt_lin_order_no_hht          := gt_dlv_edi_lines_data( line_no ).order_no_hht;          -- 受注No.（HHT）
  --          lt_lin_line_no_hht           := gt_dlv_edi_lines_data( line_no ).line_no_hht;           -- 行No.（HHT）
  --          lt_lin_digestion_ln_number   := gt_dlv_edi_lines_data( line_no ).digestion_ln_number;   -- 枝番
  --          lt_lin_order_no_ebs          := gt_dlv_edi_lines_data( line_no ).order_no_ebs;          -- 受注No.（EBS）
  --          lt_lin_line_number_ebs       := gt_dlv_edi_lines_data( line_no ).line_number_ebs;       -- 明細番号（EBS）
  --          lt_lin_item_code_self        := gt_dlv_edi_lines_data( line_no ).item_code_self;        -- 品名コード（自社）
  --          lt_lin_content               := gt_dlv_edi_lines_data( line_no ).content;               -- 入数
  --          lt_lin_inventory_item_id     := gt_dlv_edi_lines_data( line_no ).inventory_item_id;     -- 品目ID
  --          lt_lin_standard_unit         := gt_dlv_edi_lines_data( line_no ).standard_unit;         -- 基準単位
  --          lt_lin_case_number           := gt_dlv_edi_lines_data( line_no ).case_number;           -- ケース数
  --          lt_lin_quantity              := gt_dlv_edi_lines_data( line_no ).quantity;              -- 数量
  --          lt_lin_sale_class            := gt_dlv_edi_lines_data( line_no ).sale_class;            -- 売上区分
  --          lt_lin_wholesale_unit_ploce  := gt_dlv_edi_lines_data( line_no ).wholesale_unit_ploce;  -- 卸単価
  --          lt_lin_selling_price         := gt_dlv_edi_lines_data( line_no ).selling_price;         -- 売単価
  --          lt_lin_column_no             := gt_dlv_edi_lines_data( line_no ).column_no;             -- コラムNo.
  --          lt_lin_h_and_c               := gt_dlv_edi_lines_data( line_no ).h_and_c;               -- H/C
  --          lt_lin_sold_out_class        := gt_dlv_edi_lines_data( line_no ).sold_out_class;        -- 売切区分
  --          lt_lin_sold_out_time         := gt_dlv_edi_lines_data( line_no ).sold_out_time;         -- 売切時間
  --          lt_lin_replenish_number      := gt_dlv_edi_lines_data( line_no ).replenish_number;      -- 補充数
  --          lt_lin_cash_and_card         := gt_dlv_edi_lines_data( line_no ).cash_and_card;         -- 現金・カード併用額
  --  --
  --          EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
  --******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
            --====================================
            --営業原価の導出(販売実績明細(コラム))
            --====================================
            BEGIN
              SELECT ic_item.attribute7,               -- 旧営業原価
                     ic_item.attribute8,               -- 新営業原価
                     ic_item.attribute9,               -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure, -- 基準単位
                     cmm_item.inc_num                  -- 内訳入数
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit,
                     lt_inc_num
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = lt_lin_item_code_self
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
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
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
                  iv_data_value1 => lt_lin_item_code_self,         -- データの値１
                  iv_data_value2 => gn_orga_id,           -- データの値２
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
            END;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
              -- ===================================
              -- 営業原価判定
              -- ===================================
              IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
                lt_sales_cost := lt_old_sales_cost;
              ELSE
                lt_sales_cost := lt_new_sales_cost;
              END IF;
    --
              -- ============
              -- 明細金額算出
              -- ============
              -- 基準単価
              lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
    --
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
                lt_tax_amount            := cn_cons_tkn_zero;
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount := ln_amount;
                END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount     := ROUND( ( lt_pure_amount * ( ln_tax_data - 1 ) ));
    --            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount   := ln_amount;
                END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount          := ROUND( ( lt_pure_amount * ( ln_tax_data - 1) ) );
    --            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ---                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce / ln_tax_data;
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
                lt_stand_unit_price_excl :=  ROUND( ( (lt_lin_wholesale_unit_ploce /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --            -- 本体金額
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
    ----          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
    ----            IF ( lt_tax_odd = cv_amount_up ) THEN
    ----              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
    ----            -- 切捨て
    ----            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----              lt_pure_amount := TRUNC( lt_pure_amount );
    ----            -- 四捨五入
    ----            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----              lt_pure_amount := ROUND( lt_pure_amount );
    ----            END IF;
    ----          END IF;
    --            ln_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_pure_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_pure_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_pure_amount   := ln_amount;
    --            END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --            -- 消費税金額
    --            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                         - lt_pure_amount );
                -- 消費税金額
                ln_amount           := ( ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) 
                                           /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
              END IF;
    --
              --対照データが非課税でないときのとき
              IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
                --消費税合計積上げ
                ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
                --明細別最大消費税算出
                IF ( ABS( ln_max_tax_data ) < ABS( lt_tax_amount ) ) THEN
                  ln_max_tax_data := lt_tax_amount;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --              ln_max_no_data  := gn_line_data_no;
                  ln_max_no_data  := ln_line_data_count;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
                END IF;
              END IF;
    --
              -- 最大明細行No取得
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
                IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
                  ln_max_invoice_num := lt_lin_line_no_hht;
                END IF;
              END IF;
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
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
              END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        --====================
    --        --明細データの変数挿入
    --        --====================
    --        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
    --        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- 納品明細番号
    --        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- 売上区分
    --        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- 品目コード
    --        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
    --        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- 現金・カード併用額
    --        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- Ｈ＆Ｃ
    --        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- コラムNo
    --        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- 売切区分
    --        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- 売切時間
    --        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算-IF済フラグ
    --        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF済フラグ
    --        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --        gn_line_data_no := gn_line_data_no + 1;
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
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
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
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- 納品形態区分(導出)
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
            ELSE
              gn_wae_data_count := gn_wae_data_count + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
          ln_line_no := ln_line_no + 1;
    --
          END LOOP line_loop;
          -- 値引きが発生している場合
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
            -- =======================================
            -- 値引金額明細生成(A-8)
            -- =======================================
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
    --
            -- =================================
            -- 営業原価、基準単位を導出
            -- =================================
            BEGIN
              SELECT ic_item.attribute7,              -- 旧営業原価
                     ic_item.attribute8,              -- 新営業原価
                     ic_item.attribute9,              -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure -- 基準単位
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = gv_disc_item
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
                lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
                lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
                lv_key_data1 := gv_disc_item;
                lv_key_data2 := gn_orga_id;
                RAISE no_data_extract;
            END;
            -- ===================================
            -- 営業原価判定
            -- ===================================
            IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
              lt_sales_cost := lt_old_sales_cost;
            ELSE
              lt_sales_cost := lt_new_sales_cost;
            END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --/*--==============2009/2/3-START=========================--*/
    --        IF ( lv_depart_code = cv_depart_car ) THEN
    --        IF ( lv_depart_code IS NULL ) 
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    --/*--==============2009/2/3-END==========================--*/
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name     -- 保管場所コード
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi    --保管場所マスタ
    --            WHERE  msi.attribute7 = lt_base_code
    --            AND    msi.attribute13 = lt_location_type_code;
    --            AND    msi.attribute3 = lt_dlv_by_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --              --キー編集処理用変数
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --              lv_key_data1 := lt_base_code;
    --              lv_key_data2 := cv_xxcos_001_a05_05;
    --            RAISE no_data_extract;
    --          END;
    --
    --/*--==============2009/2/3-START=========================--*/
    ----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
    ----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
    --        ELSIF ( lv_depart_code = cv_depart_type ) 
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    --/*--==============2009/2/3-END==========================--*/
    --          --参照コードマスタ：百貨店の保管場所分類コード取得
    --
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name           -- 保管場所名称
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
    --                   mtl_parameters mp                      -- 組織パラメータ
    --            WHERE  msi.organization_id=mp.organization_id
    --            AND    mp.organization_code = gv_orga_code
    --            AND    msi.attribute4       = lt_keep_in_code
    --            AND    msi.attribute13      = lt_depart_location_type_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --              --キー編集処理用変数設定
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --              lv_key_data1 := lt_base_code;
    --              lv_key_data2 := cv_xxcos_001_a05_09;
    --            RAISE no_data_extract;
    --          END;
    --
    --        END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
              -- ================
              -- 金額算出処理
              -- ================
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := lt_sale_discount_amount;
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
                lt_tax_amount            := cn_cons_tkn_zero;
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_sale_amount           := ( lt_sale_discount_amount );
    --            ln_amount           := ( lt_sale_discount_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount := ln_amount;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount          := ROUND( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1 ;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := ( lt_sale_discount_amount  );
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --         lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_sale_amount           := lt_sale_discount_amount;
    --            ln_amount           := ( lt_sale_discount_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount := ln_amount;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount          := ROUND( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_stand_unit_price_excl :=  ROUND( ( (lt_sale_discount_amount /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --            lt_stand_unit_price_excl := ( lt_sale_discount_amount / ln_tax_data);
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
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := lt_sale_discount_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --            -- 本体金額
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data );
    ----          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
    ----            IF ( lt_tax_odd = cv_amount_up ) THEN
    ----              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
    ----            -- 切捨て
    ----            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----              lt_pure_amount := TRUNC( lt_pure_amount );
    ----            -- 四捨五入
    ----            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----              lt_pure_amount := ROUND( lt_pure_amount );
    ----            END IF;
    ----          END IF;
    --            ln_amount           := ( lt_sale_discount_amount / ln_tax_data );
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
    ----************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --            -- 消費税金額
    --            lt_tax_amount            := TRUNC( lt_sale_amount - lt_pure_amount );
                ln_amount           := ( ( lt_sale_discount_amount /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_discount_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
              END IF;
    --
              -- 値引用納品明細番号設定
              ln_max_invoice_num := ln_max_invoice_num + 1;
              -- 登録用値引金額設定
              lt_sale_amount := ( lt_sale_amount * ( -1 ) );
              lt_pure_amount := ( lt_pure_amount * ( -1 ) );
              lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
              -- 赤・黒の金額換算
              --黒の時
              IF ( lt_red_black_flag = cv_black_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := cn_disc_standard_qty;
                -- 売上金額
                lt_set_sale_amount := lt_sale_amount;
                -- 本体金額
                lt_set_pure_amount := lt_pure_amount;
                -- 消費税金額
                lt_set_tax_amount := lt_tax_amount;
              -- 赤の時
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
                -- 売上金額
                lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
                -- 本体金額
                lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
                -- 消費税金額
                lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
              END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START   ***************************************
    --        -- =========================================
    --        -- 値引き明細データセット
    --        -- =========================================
    --        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID

    --        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- 納品明細番号
    --        gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- 売上区分
    --        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --        gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- 品目コード
    --        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- 営業原価
    --        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --        gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- 現金・カード併用額
    --        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- Ｈ＆Ｃ
    --        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- コラムNo
    --        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- 売切区分
    --        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- 売切時間
    --        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算IF済フラグ
    --        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INVインタフェース済フラグ
    --        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --        gn_line_data_no := gn_line_data_no + 1;
              -- ===================
              -- 一時格納用
              -- ===================
              gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- 納品伝票番号
              gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- 納品明細番号
              gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- 売上区分
              gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- 赤黒フラグ
              gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- 品目コード
              gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- 納品数量
              gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- 基準数量
              gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- 納品単位
              gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- 基準単位
              gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- 納品単価
              gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- 基準単価
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
              gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- 売上金額
              gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- 本体金額
              gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- 消費税金額
              gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- 現金・カード併用額
              gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- 出荷元保管場所
              gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- 納品拠点コード
              gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- Ｈ＆Ｃ
              gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- コラムNo
              gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- 売切区分
              gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- 売切時間
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- 納品形態区分(導出)
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
    --******************************* 2009/06/01 N.Maeda Var1.15 ADD START ***************************************
              gn_disc_count    := gn_disc_count + 1;                       -- 値引明細件数カウント
    --******************************* 2009/05/01 N.Maeda Var1.15 ADD END   ***************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
          END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
            -- ==================
            -- ヘッダ登録用金額算出
            -- ==================
            IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- 非課税
    --
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
    --          -- 売上金額合計
    --          lt_sale_amount_sum := lt_total_amount;
    --          -- 本体金額合計
    --          lt_pure_amount_sum := lt_total_amount;
    --          -- 消費税金額合計
    --          lt_tax_amount_sum  := lt_sales_consumption_tax;
              -- 売上金額合計
              lt_sale_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
              -- 本体金額合計
              lt_pure_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
              -- 消費税金額合計
              lt_tax_amount_sum  := lt_sales_consumption_tax;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
            ELSE
             --値引発生時
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                  -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_tax_include * ln_tax_data );
    --              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --                END IF;
    --              END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                  lt_sale_amount_sum := ( lt_tax_include );
    --              ln_amount := ( lt_tax_include );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_sale_amount_sum := ln_amount;
    --              END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_tax_include;
                  -- 消費税金額合計
                  ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      lt_tax_amount_sum := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      lt_tax_amount_sum := ROUND( ln_amount );
                    END IF;
                  ELSE
                    lt_tax_amount_sum   := ln_amount;
                  END IF;
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                  -- 売上金額合計
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              lt_sale_amount_sum := lt_tax_include;
                  lt_sale_amount_sum := lt_tax_include - lt_sales_consumption_tax;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                  -- 消費税金額合計
                  lt_tax_amount_sum  := lt_sales_consumption_tax;
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              -- 売上金額合計
    --              lt_sale_amount_sum := lt_tax_include;
                  -- 本体金額合計
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_tax_include / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_tax_include / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
    ----************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 値引消費税算出
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            ln_discount_tax    := ( lt_sale_discount_amount / ln_tax_data );
    ----            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                ln_discount_tax := TRUNC( ln_discount_tax );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                 ln_discount_tax:= ROUND( ln_discount_tax );
    ----              END IF;
    ----            END IF;
                  ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      ln_discount_tax :=  TRUNC( ln_amount ) - 1;
                    END IF;
    --                  ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      ln_discount_tax := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                       ln_discount_tax:= ROUND( ln_amount );
                    END IF;
                  ELSE
                    ln_discount_tax:= ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 消費税金額合計
                  lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
                  -- 本体金額合計
                  lt_pure_amount_sum := ln_line_pure_amount_sum;
                  -- 売上金額合計
                  lt_sale_amount_sum := lt_pure_amount_sum + lt_tax_amount_sum;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
                END IF;
              --値引未発生時金額算出
              ELSE
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --           lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
                  ln_amount := ( lt_total_amount );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount_sum :=  TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      lt_sale_amount_sum := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      lt_sale_amount_sum := ROUND( ln_amount );
                    END IF;
                  ELSE
                    lt_sale_amount_sum := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
                  ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN            
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              ln_amount := ( lt_total_amount * ln_tax_data );
                  lt_sale_amount_sum := lt_total_amount;
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_sale_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_sale_amount_sum := ln_amount;
    --              END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
    --************************** 2009/05/18 1.15 N.Maeda MOD START ************************************
    --              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
                  lt_tax_amount_sum  := lt_sales_consumption_tax;
    --************************** 2009/05/18 1.15 N.Maeda MOD  END  ************************************
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              -- 売上金額合計
    --              lt_sale_amount_sum := lt_total_amount;
                  -- 本体金額合計
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_total_amount / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
                  lt_pure_amount_sum := ln_line_pure_amount_sum;
                  -- 売上金額合計
                  lt_sale_amount_sum := ln_line_pure_amount_sum + ln_all_tax_amount;
    ----************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 消費税金額合計
                  lt_tax_amount_sum  := ln_all_tax_amount;
    --
                END IF;
              END IF;
            END IF;
    --
            --非課税以外のとき
            IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
              --================================================
              --ヘッダ売上消費税額と明細売上消費税額比較判断処理
              --================================================
              -- 値引明細がnull以外の時
              IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
              AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
                ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
              END IF;
              IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
                -- 外税 OR 内税(伝票課税の時)
                IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
                  IF ( lt_red_black_flag = cv_black_flag ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
    --                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                  ELSIF ( lt_red_black_flag = cv_red_flag) THEN
    --                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
    --                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
    --******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
                  END IF;
                END IF;
              END IF;
            END IF;
    --
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
--            BEGIN
--              OPEN  get_oe_order_cur;
--              -- バルクフェッチ
--              FETCH get_oe_order_cur BULK COLLECT INTO gt_oe_order_all;
--              -- 抽出件数セット
--              gn_om_data_cnt := get_oe_order_cur%ROWCOUNT;
--              -- カーソルCLOSE
--              CLOSE get_oe_order_cur;
--            EXCEPTION
--              WHEN OTHERS THEN
--                IF( get_oe_order_cur%ISOPEN ) THEN
--                  CLOSE get_oe_order_cur;
--                END IF;
--                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
--                --キー編集表変数設定
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_order_no );
--    --            lv_key_name2 := NULL;
--    --            lv_key_data1 := lt_order_no_ebs;
--    --            lv_key_data2 := NULL;
--    --          RAISE no_data_extract;
--                lv_state_flg    := cv_status_warn;
--                gn_wae_data_num := gn_wae_data_num + 1 ;
--                xxcos_common_pkg.makeup_key_info(
--                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- 項目名称１
--                  iv_data_value1 => lt_order_no_ebs,         -- データの値１
--                  ov_key_info    => gv_tkn2,              -- キー情報
--                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                  ov_retcode     => lv_retcode,           -- リターン・コード
--                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                      iv_application   => cv_application,    --アプリケーション短縮名
--                                                      iv_name          => cv_msg_no_data,    --メッセージコード
--                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                      iv_token_value1  => gv_tkn1,           --トークン値1
--                                                      iv_token_name2   => cv_key_data,       --トークンコード2
--                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--            END;
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        IF ( gn_om_data_cnt > 0 ) THEN
            IF ( gn_om_data_cnt > 0 ) AND ( lv_state_flg <> cv_status_warn )THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
              <<om_order_loop>>
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          FOR om_data_no IN ln_cnt_om_order..gn_om_data_cnt LOOP
              FOR om_data_no IN 1..gn_om_data_cnt LOOP
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
                -- ====================================
                -- OM受注情報格納
                -- ====================================
    --******************************* 2009/05/12 N.Maeda Var1.13 MOD START *************************************
    --            gt_oe_order_number( ln_cnt_om_order )      := gt_oe_order_all( om_data_no ).order_number;
    --            gt_oe_header_id( ln_cnt_om_order )         := gt_oe_order_all( om_data_no ).header_id;
    --            gt_oe_he_flow_status_code( ln_cnt_om_order )  := gt_oe_order_all( om_data_no ).head_flow_status_code;
    --            gt_oe_order_source_id( ln_cnt_om_order )   := gt_oe_order_all( om_data_no ).order_source_id;
    --            gt_oe_cust_po_number( ln_cnt_om_order )    := gt_oe_order_all( om_data_no ).cust_po_number;
    --            gt_oe_line_id( ln_cnt_om_order )           := gt_oe_order_all( om_data_no ).line_id;
    --            gt_oe_li_flow_status_code( ln_cnt_om_order )  := gt_oe_order_all( om_data_no ).line_flow_status_code;
    --            ln_cnt_om_order := ln_cnt_om_order + 1;
                gt_oe_order_number( gn_cnt_om_order )      := gt_oe_order_all( om_data_no ).order_number;
                gt_oe_header_id( gn_cnt_om_order )         := gt_oe_order_all( om_data_no ).header_id;
                gt_oe_he_flow_status_code( gn_cnt_om_order )  := gt_oe_order_all( om_data_no ).head_flow_status_code;
                gt_oe_order_source_id( gn_cnt_om_order )   := gt_oe_order_all( om_data_no ).order_source_id;
                gt_oe_cust_po_number( gn_cnt_om_order )    := gt_oe_order_all( om_data_no ).cust_po_number;
                gt_oe_line_id( gn_cnt_om_order )           := gt_oe_order_all( om_data_no ).line_id;
                gt_oe_li_flow_status_code( gn_cnt_om_order )  := gt_oe_order_all( om_data_no ).line_flow_status_code;
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
                gt_oe_line_row_id( gn_cnt_om_order )       := gt_oe_order_all( om_data_no ).row_id;
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
                gn_cnt_om_order := gn_cnt_om_order + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
    --******************************* 2009/05/12 N.Maeda Var1.13 MOD  END ***************************************
              END LOOP om_order_loop;
            END IF;
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
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
            BEGIN
              SELECT  dhs.cancel_correct_class
              INTO    lt_max_cancel_correct_class
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE  dhs.order_no_hht = dls.order_no_hht
--              AND    dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE  dhs.order_no_hht = dls.order_no_hht(+)
              AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND    dhs.input_class  = cv_input_delivery
              AND    dhs.results_forward_flag = cv_untreated_flg
              AND    dhs.order_no_ebs <> cn_tkn_zero
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND    dhs.program_application_id IS NOT NULL
--              AND    dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND    dhs.order_no_hht        = lt_order_no_hht
              AND    dhs.digestion_ln_number = ( SELECT  MAX( dhs.digestion_ln_number)
                                                  FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                                                          xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--                                                  WHERE   dhs.order_no_hht = dls.order_no_hht
--                                                  AND     dhs.digestion_ln_number = dls.digestion_ln_number
                                                  WHERE   dhs.order_no_hht = dls.order_no_hht(+)
                                                  AND     dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
                                                  AND     dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
                                                  AND     dhs.input_class  = cv_input_delivery
                                                  AND     dhs.results_forward_flag = cv_untreated_flg
                                                  AND     dhs.order_no_ebs <> cn_tkn_zero
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--                                                  AND     dhs.program_application_id IS NOT NULL
--                                                  AND     dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
                                                  AND     dhs.order_no_hht        = lt_order_no_hht )
              GROUP BY dhs.cancel_correct_class;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
    --
            BEGIN
              SELECT  MIN(dhs.digestion_ln_number)
              INTO    lt_min_digestion_ln_number
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE  dhs.order_no_hht = dls.order_no_hht
--              AND    dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE  dhs.order_no_hht = dls.order_no_hht(+)
              AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND    dhs.input_class  = cv_input_delivery
              AND    dhs.results_forward_flag = cv_untreated_flg
              AND    dhs.order_no_ebs <> cn_tkn_zero
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND    dhs.program_application_id IS NOT NULL
--              AND    dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND     dhs.order_no_hht        = lt_order_no_hht;
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
                  lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
                  RAISE;
              END;
    --
              IF ( ln_sales_exp_count <> 0 ) THEN
                <<sales_exp_update_loop>>
                FOR u in 1..ln_sales_exp_count LOOP
                  gn_set_sales_exp_count := gn_set_sales_exp_count + 1;
                  gt_set_sales_head_row_id( gn_set_sales_exp_count )   := gt_sales_head_row_id(u);
                  gt_set_head_cancel_cor_cls( gn_set_sales_exp_count ) := lt_max_cancel_correct_class;
                END LOOP sales_exp_update_loop;
              END IF;
            END IF;
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          --================================
          --販売実績ヘッダID(シーケンス取得)
          --================================
            SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
            INTO ln_actual_id
            FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --
            --==========================
            -- ヘッダデータの変数挿入
            --==========================
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
            gt_head_id( gn_head_data_no )                      := ln_actual_id;               -- 販売実績ヘッダID
            gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;            -- 受注番号
            gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;          -- 納品伝票番号
    --      gt_head_delivery_pat_class( gn_head_data_no )      := lv_delivery_type;           -- 納品形態区分
            gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;            -- 受注No(HHT)
            gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;     -- 受注No(HHT)枝番
            gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;        -- 納品伝票区分(導出)
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --      gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;    -- 取消・訂正区分
            gt_head_cancel_cor_cls( gn_head_data_no )          := lt_max_cancel_correct_class;  --  取消・訂正区分
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END   ***************************************
            gt_head_system_class( gn_head_data_no )            := lt_system_class;            -- 業態区分(業態小分類)
            gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                -- オリジナル納品日
            gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;            -- オリジナル検収日(売上計上日)
            gt_head_customer_number( gn_head_data_no )         := lt_customer_number;         -- 顧客【納品先】
            gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;     -- 売上金額合計
            gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;     -- 本体金額合計
            gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;      -- 消費税金額合計(半導出)
            gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;             -- 消費税区分(導出)
            gt_head_tax_code( gn_head_data_no )                := lt_consum_code;             -- 税金コード(導出)
            gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;              -- 消費税率(導出)
            gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;     -- 成績計上者コード
            gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;          -- 売上拠点コード(導出)
            gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;         -- カード売り区分
    --      gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;    -- 伝票区分
    --      gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;           -- 伝票分類コード
            gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;    -- 伝票区分
            gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;           -- 伝票分類コード
    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    --      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- 入金拠点コード(導出)
            gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- 入金拠点コード(導出)
    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
            gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;     -- つり銭切れ時間100円
            gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;      -- つり銭切れ時間10円
            gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;              -- HHT納品入力日時(成型日時)
            gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;             -- 納品者コード
            gt_head_business_date( gn_head_data_no )           := gd_process_date;            -- 登録業務日付(初期処理取得)
            gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                -- 受注ソースID(NULL設定)
            gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                -- 注文伝票番号
            gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                -- 受注関連番号(NULL設定)
            gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- AR-IF済フラグ('N')
            gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- GL-IF済フラグ('N')
            gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- 情報システム-IF済フラグ('N')
            gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- EDI送信済みフラグ('N'設定)
            gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                -- EDI送信日時(NULL設定)
    -- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
    --        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;        -- 作成元区分(｢4｣設定)
            gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;        -- 作成元区分(｢4｣設定)
    -- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
            gt_head_input_class( gn_head_data_no )             := lt_input_class;             -- 入力区分
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
            gt_head_open_dlv_date( gn_head_data_no )           := lt_open_dlv_date;
            gt_head_open_inspect_date( gn_head_data_no )       := lt_open_inspect_date;
--    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
--            gt_head_open_dlv_date( gn_head_data_no )           := lt_dlv_date;
--            gt_head_open_inspect_date( gn_head_data_no )       := lt_inspect_date;
--    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
            gn_head_data_no := gn_head_data_no + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
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
              gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
              gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
              gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- 納品伝票番号
              gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- 納品明細番号
              gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- 売上区分
              gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- 赤黒フラグ
              gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- 品目コード
              gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- 基準数量
              gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- 基準単位
              gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- 基準単価
              gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- 営業原価
              gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- 売上金額
              gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- 本体金額
              gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- 消費税金額
              gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- 現金・カード併用額
              gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- 出荷元保管場所
              gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- 納品拠点コード
              gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- Ｈ＆Ｃ
              gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- コラムNo
              gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- 売切区分
              gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- 売切時間
              gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- 手数料計算IF済フラグ
              gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- 単価マスタ作成済フラグ
              gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INVインタフェース済フラグ
              gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- 注文明細番号
              gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- 税抜基準単価
              gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- 納品形態区分
              gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- 納品数量
              gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- 納品単位
              gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- 納品単価
              gn_line_data_no := gn_line_data_no + 1;
            END LOOP line_set_loop;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          ELSE
            gn_wae_data_count := gn_wae_data_count + ln_line_data_count;
            gn_warn_cnt       := gn_warn_cnt + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
----******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
        ELSE
          gn_warn_cnt := gn_warn_cnt + 1 ;
        END IF;
--
      EXCEPTION
        WHEN lock_err_expt THEN
          IF( get_lines_cur%ISOPEN ) THEN
            CLOSE get_lines_cur;
          END IF;
          IF( get_lock_cur%ISOPEN ) THEN
            CLOSE get_lock_cur;
          END IF;
          lt_order_no_hht_err := lt_order_no_hht;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gn_warn_cnt     := gn_warn_cnt + 1;
--
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,            --アプリケーション短縮名
                                                iv_name          => cv_data_loc,               --メッセージコード
                                                iv_token_name1   => cv_tkn_order_number,       --トークンコード2
                                                iv_token_value1  => lt_order_no_hht,
                                                iv_token_name2   => cv_invoice_no,
                                                iv_token_value2  => lt_hht_invoice_no);
      END;
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END   ***************************************
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
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_edi;
--
  /**********************************************************************************
   * Procedure Name   : proc_inp_molded_hht
   * Description      : 販売実績データ(納品伝票入力画面)成型処理(A-9)
   ***********************************************************************************/
  PROCEDURE proc_inp_molded_hht(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_inp_molded_hht'; -- プログラム名
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
    --納品ヘッダ(HHT)格納用変数
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- 枝番
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- 受注No.（EBS）
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- 拠点コード
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- 成績者コード
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- 納品者コード
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT伝票No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- 納品日
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- 検収日
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- 売上分類区分
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- 売上伝票区分
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- カード売り区分
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- 時間
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- 顧客コード
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- つり銭切れ時間100円
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- つり銭切れ時間10円
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- 業態区分
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- 入力区分
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- 消費税区分
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- 合計金額
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- 売上値引額
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- 売上消費税額
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- 税込金額
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- 預け先コード
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- 百貨店画面種別
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- 入出庫転送フラグ
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- 入出庫転送済日付
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- 販売実績連携済フラグ
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- 販売実績連携済日付
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- 取消・訂正区分
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- 赤黒フラグ
    --納品明細(HHT)格納用変数
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- 受注No.（HHT）
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- 行No.（HHT）
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- 枝番
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- 受注No.（EBS）
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- 明細番号（EBS）
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- 品名コード（自社）
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- 入数
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- 品目ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- 基準単位
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- ケース数
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- 数量
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- 売上区分
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- 卸単価
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- 売単価
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- コラムNo.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- 売切区分
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- 売切時間
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- 補充数
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- 現金・カード併用額
    -- その他
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- 拠点コード
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- 旧営業原価
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- 新営業原価
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- 営業原価適用開始日
--
    ln_line_no                   NUMBER :=  1;                                    -- 明細チェック済番号
    ln_all_tax_amount            NUMBER :=  0;                                    -- 消費税金額合計値
    ln_max_tax_data              NUMBER :=  0;                                    -- 明細最大消費税額
    ln_actual_id                 NUMBER;                                          -- 販売実績ヘッダID
--    ln_sales_amount              NUMBER;                                          -- 売上金額
--    ln_consum_amount             NUMBER;                                          -- 消費税金額
--    ln_tax_odd                   NUMBER;                                          -- 消費税端数
--    ln_up_odd                    NUMBER;                                          -- 端数切り上げ数値
--    ln_amount_data               NUMBER;                                          -- 本体金額
--    lt_lin_sale_amount           NUMBER;                                          -- 売上金額
    ln_sales_exp_line_id         NUMBER;                                          -- 明細ID
    ln_max_invoice_num           NUMBER;                                          -- 値引明細用納品明細番号
    ld_input_date                DATE;                                            -- HHT納品入力日時
    lt_tax_odd                   xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; -- 税金-端数処理
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- 消費税コード
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- 販売実績連携時の消費税区分
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- 消費税率
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- 基準単位
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --税抜基準単価
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- 保管場所分類コード(営業車)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- 保管場所分類コード(百貨店)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所コード
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- 納品伝票区分
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT百貨店入力区分
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- 内訳入数
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- 売上拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- 入金拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- 営業原価
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 売上金額合計
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 本体金額合計
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 消費税金額合計
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--税抜基準単価
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- 基準単価
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- 売上金額
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- 本体金額
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- 消費税金額
--    lt_cust_acct_site_id         hz_cust_acct_sites_all.cust_acct_site_id%TYPE;   -- 顧客サイトID
--    lt_site_use_code             fnd_lookup_values.meaning%TYPE;                  -- 使用区分
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- 登録用基準数量(納品数量)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- 登録用売上金額
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- 登録用本体金額
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- 登録用消費税金額
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 登録用売上金額合計
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 登録用本体金額合計
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 登録用消費税金額合計
    ln_discount_tax              NUMBER;                                          -- 値引消費税額
    ln_tax_data                  NUMBER;                                          -- 税込額算出用
    ln_max_no_data               NUMBER;                                          -- ヘッダ最大消費税明細行番号
    lv_delivery_type             VARCHAR2(100);                                   -- 納品形態区分
    lv_key_name1                 VARCHAR2(500);                                   -- キーデータ名称1
    lv_key_name2                 VARCHAR2(500);                                   -- キーデータ名称2
    lv_key_data1                 VARCHAR2(500);                                   -- キーデータ1
    lv_key_data2                 VARCHAR2(500);                                   -- キーデータ2
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
    ln_amount                    NUMBER;                                          -- 作業用金額変数
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- 更新用行ID
    lv_state_flg                 VARCHAR2(1);                                     -- データ警告確認フラグ
    ln_line_data_count           NUMBER;                                          -- 明細件数(ヘッダ単位)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT百貨店区分エラーフラグ
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START ***************************************
    lv_edi_order_name            VARCHAR2(100);                                   -- EDI受注
--******************************* 2009/05/13 N.Maeda Var1.13 ADD  END  ***************************************
--******************** 2009/05/18 N.Maeda Var1.15 START ******************************************
  lt_max_cancel_correct_class     xxcos_vd_column_headers.cancel_correct_class%TYPE;    -- 最新取消・訂正区分
  lt_min_digestion_ln_number      xxcos_vd_column_headers.digestion_ln_number%TYPE;     -- 枝番最小値
  ln_sales_exp_count              NUMBER :=0 ;                                          -- 更新対象販売実績件数カウント
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
  lt_open_dlv_date                xxcos_dlv_headers.dlv_date%TYPE;                 -- オープン済み納品日
  lt_open_inspect_date            xxcos_dlv_headers.inspect_date%TYPE;             -- オープン済み検収日
  ln_line_pure_amount_sum         NUMBER;                                          -- 明細合計本体金額
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
  lt_order_no_hht_err             xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
  lt_order_no_hht_ok              xxcos_dlv_headers.order_no_hht%TYPE;
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  ***************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  lt_mon_sale_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_past_sale_base_code               xxcmm_cust_accounts.past_sale_base_code%TYPE;
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
--
    -- *** ローカル・カーソル ***
  CURSOR get_sales_exp_cur
    IS
      SELECT xseh.ROWID
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.order_no_hht = lt_order_no_hht
  FOR UPDATE NOWAIT;
--******************** 2009/05/18 N.Maeda Var1.15 ADD START ******************************************
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START ***************************************
--   --****** ユーザー定義ローカルカーソル ********--
--******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
--
  -- ロック取得カーソル
  CURSOR get_lock_cur
  IS
    SELECT 'Y'
    FROM   xxcos_dlv_headers dhs
          ,xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--    WHERE  dhs.order_no_hht = dls.order_no_hht
--    AND    dhs.digestion_ln_number = dls.digestion_ln_number
    WHERE  dhs.order_no_hht = dls.order_no_hht(+)
    AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
    AND    dhs.order_no_hht = lt_order_no_hht
  FOR UPDATE OF dhs.order_no_hht,dls.digestion_ln_number
  NOWAIT;
--
--
  -- 明細情報取得カーソル
  CURSOR get_lines_cur
  IS
    SELECT dls.order_no_hht,          -- 受注No.（HHT）
           dls.line_no_hht,           -- 行No.（HHT）
           dls.digestion_ln_number,   -- 枝番
           dls.order_no_ebs,          -- 受注No.（EBS）
           dls.line_number_ebs,       -- 明細番号（EBS）
           dls.item_code_self,        -- 品名コード（自社）
           dls.content,               -- 入数
           dls.inventory_item_id,     -- 品目ID
           dls.standard_unit,         -- 基準単位
           dls.case_number,           -- ケース数
           dls.quantity,              -- 数量
           dls.sale_class,            -- 売上区分
           dls.wholesale_unit_ploce,  -- 卸単価
           dls.selling_price,         -- 売単価
           dls.column_no,             -- コラムNo.
           dls.h_and_c,               -- H/C
           dls.sold_out_class,        -- 売切区分
           dls.sold_out_time,         -- 売切時間
           dls.replenish_number,      -- 補充数
           dls.cash_and_card          -- 現金・カード併用額
    FROM   xxcos_dlv_lines dls              -- 納品明細
    WHERE  dls.order_no_hht        = lt_order_no_hht
    AND    dls.digestion_ln_number = lt_digestion_ln_number;
--
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    -- OM受注データ取得カーソル
    CURSOR get_oe_order_cur
    IS
      SELECT ooh.order_number      order_number,            -- 受注番号
             ooh.header_id         header_id,               -- 受注ヘッダID
             ooh.flow_status_code  head_flow_status_code,   -- ステータス
             ooh.order_source_id   order_source_id,         -- 受注ソースID
             ooh.cust_po_number    cust_po_number,          -- 顧客発注
             ool.line_id           line_id,                 -- 受注明細ID
             ool.flow_status_code  line_flow_status_code    -- ステータス
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
             ,ool.rowid            row_id                   -- 行ID
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
      FROM   oe_order_headers_all ooh,                      -- OM受注ヘッダ
             oe_order_lines_all ool,                        -- OM受注明細テーブル
             oe_order_sources oos                           -- オーダーソース
      WHERE  ooh.header_id = ool.header_id
      AND    ooh.order_source_id = oos.order_source_id
      AND    ool.order_source_id = oos.order_source_id
      AND    ooh.org_id = TO_NUMBER ( gv_salse_unit )
      AND    ooh.order_number = lt_order_no_ebs
      AND    ool.flow_status_code NOT IN ( cv_status_type_can , cv_status_type_clo )
      AND    oos.name = lv_edi_order_name
-- ************ 2009/10/13 N.Maeda ADD START *********** --
      AND    ool.global_attribute5 IS NULL
-- ************ 2009/10/13 N.Maeda ADD  END  *********** --
      ORDER BY ooh.order_number,ool.line_id
-- ************ 2009/10/13 N.Maeda ADD START *********** --
      FOR UPDATE OF  ool.global_attribute5
      NOWAIT
-- ************ 2009/10/13 N.Maeda ADD  END  *********** --
      ;
--******************************* 2009/05/13 N.Maeda Var1.13 ADD  END  ***************************************
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START ***************************************
    -- EDI受注名称取得
    lv_edi_order_name := xxccp_common_pkg.get_msg( cv_application, cv_order_s_name );
--******************************* 2009/05/13 N.Maeda Var1.13 ADD  END  ***************************************
    -- ループ開始：ヘッダ部
    <<header_loop>>
    FOR ck_no IN 1..gn_inp_target_cnt LOOP
--
      -- 明細番号の初期化
      ln_sales_exp_line_id            := 0;
      -- 積上消費税の初期化
      ln_all_tax_amount               := 0;
      -- 最大消費税額の初期化
      ln_max_tax_data                 := 0;
      -- 最大行No
      ln_max_invoice_num              := 0;
      -- 最大明細番号
      ln_max_no_data                  := 0;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
      -- 明細合計本体金額
      ln_line_pure_amount_sum         := 0;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- 明細件数カウント(初期化)
      ln_line_data_count              := 0;
      -- データ警告確認フラグ(初期化)
      lv_state_flg                    := cv_status_normal;
      -- HHT百貨店区分エラー(初期化)
      lv_dept_hht_div_flg             := cv_status_normal;
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
      lt_row_id                    := gt_inp_dlv_hht_headers_data( ck_no ).row_id;                   -- 行ID
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := gt_inp_dlv_hht_headers_data( ck_no ).order_no_hht;    -- 受注No.(HHT)
--      lt_order_no_hht              := TRUNC( gt_inp_dlv_hht_headers_data( ck_no ).order_no_hht );    -- 受注No.(HHT)
      lt_digestion_ln_number       := gt_inp_dlv_hht_headers_data( ck_no ).digestion_ln_number;      -- 枝番
--      lt_order_no_ebs              := gt_inp_dlv_hht_headers_data( ck_no ).order_no_ebs;             -- 受注No.（EBS）
--      lt_base_code                 := gt_inp_dlv_hht_headers_data( ck_no ).base_code;                -- 拠点コード
--      lt_performance_by_code       := gt_inp_dlv_hht_headers_data( ck_no ).performance_by_code;      -- 成績者コード
--      lt_dlv_by_code               := gt_inp_dlv_hht_headers_data( ck_no ).dlv_by_code;              -- 納品者コード
      lt_hht_invoice_no            := gt_inp_dlv_hht_headers_data( ck_no ).hht_invoice_no;           -- HHT伝票No.
--      lt_dlv_date                  := gt_inp_dlv_hht_headers_data( ck_no ).dlv_date;                 -- 納品日
--      lt_inspect_date              := gt_inp_dlv_hht_headers_data( ck_no ).inspect_date;             -- 検収日
--      lt_sales_classification      := gt_inp_dlv_hht_headers_data( ck_no ).sales_classification;     -- 売上分類区分
--      lt_sales_invoice             := gt_inp_dlv_hht_headers_data( ck_no ).sales_invoice;            -- 売上伝票区分
--      lt_card_sale_class           := gt_inp_dlv_hht_headers_data( ck_no ).card_sale_class;          -- カード売り区分
--      lt_dlv_time                  := gt_inp_dlv_hht_headers_data( ck_no ).dlv_time;                 -- 時間
--      lt_customer_number           := gt_inp_dlv_hht_headers_data( ck_no ).customer_number;          -- 顧客コード
--      lt_change_out_time_100       := gt_inp_dlv_hht_headers_data( ck_no ).change_out_time_100;      -- つり銭切れ時間100円
--      lt_change_out_time_10        := gt_inp_dlv_hht_headers_data( ck_no ).change_out_time_10;       -- つり銭切れ時間10円
--      lt_system_class              := gt_inp_dlv_hht_headers_data( ck_no ).system_class;             -- 業態区分
--      lt_input_class               := gt_inp_dlv_hht_headers_data( ck_no ).input_class;              -- 入力区分
--      lt_consumption_tax_class     := gt_inp_dlv_hht_headers_data( ck_no ).consumption_tax_class;    -- 消費税区分
--      lt_total_amount              := gt_inp_dlv_hht_headers_data( ck_no ).total_amount;             -- 合計金額
--      lt_sale_discount_amount      := gt_inp_dlv_hht_headers_data( ck_no ).sale_discount_amount;     -- 売上値引額
--      lt_sales_consumption_tax     := gt_inp_dlv_hht_headers_data( ck_no ).sales_consumption_tax;    -- 売上消費税額
--      lt_tax_include               := gt_inp_dlv_hht_headers_data( ck_no ).tax_include;              -- 税込金額
--      lt_keep_in_code              := gt_inp_dlv_hht_headers_data( ck_no ).keep_in_code;             -- 預け先コード
--      lt_department_screen_class   := gt_inp_dlv_hht_headers_data( ck_no ).department_screen_class;  -- 百貨店画面種別
--      lt_red_black_flag            := gt_inp_dlv_hht_headers_data( ck_no ).red_black_flag;           -- 赤黒フラグ
--      lt_stock_forward_flag        := gt_inp_dlv_hht_headers_data( ck_no ).stock_forward_flag;       -- 入出庫転送フラグ
--      lt_stock_forward_date        := gt_inp_dlv_hht_headers_data( ck_no ).stock_forward_date;       -- 入出庫転送済日付
--      lt_results_forward_flag      := gt_inp_dlv_hht_headers_data( ck_no ).results_forward_flag;     -- 販売実績連携済フラグ
--      lt_results_forward_date      := gt_inp_dlv_hht_headers_data( ck_no ).results_forward_date;     -- 販売実績連携済日付
--      lt_cancel_correct_class      := gt_inp_dlv_hht_headers_data( ck_no ).cancel_correct_class;     -- 取消・訂正区分
      BEGIN
--
         IF ( lt_order_no_hht_err <> lt_order_no_hht ) OR ( lt_order_no_hht_err IS NULL ) THEN
--
           IF ( lt_order_no_hht_ok <> lt_order_no_hht ) OR ( lt_order_no_hht_ok IS NULL ) THEN
             -- ロック取得
             OPEN  get_lock_cur;
             CLOSE get_lock_cur;
           END IF;
--
           --ロック取得済み受注No.（HHT）
           lt_order_no_hht_ok := lt_order_no_hht;
--
          -- 納品ヘッダ情報取得
          SELECT dhs.ROWID                    -- 行ID
               ,dhs.order_no_ebs             -- 受注No.（EBS）
               ,dhs.base_code                -- 拠点コード
               ,dhs.performance_by_code      -- 成績者コード
               ,dhs.dlv_by_code              -- 納品者コード
               ,dhs.dlv_date                 -- 納品日
               ,dhs.inspect_date             -- 検収日
               ,dhs.sales_classification     -- 売上分類区分
               ,dhs.sales_invoice            -- 売上伝票区分
               ,dhs.card_sale_class          -- カード売り区分
               ,dhs.dlv_time                 -- 時間
               ,dhs.customer_number          -- 顧客コード
               ,dhs.change_out_time_100      -- つり銭切れ時間100円
               ,dhs.change_out_time_10       -- つり銭切れ時間10円
               ,dhs.system_class             -- 業態区分
               ,dhs.input_class              -- 入力区分
               ,dhs.consumption_tax_class    -- 消費税区分
               ,dhs.total_amount             -- 合計金額
               ,dhs.sale_discount_amount     -- 売上値引額
               ,dhs.sales_consumption_tax    -- 売上消費税額
               ,dhs.tax_include              -- 税込金額
               ,dhs.keep_in_code             -- 預け先コード
               ,dhs.department_screen_class  -- 百貨店画面種別
               ,dhs.red_black_flag           -- 赤・黒フラグ
               ,dhs.stock_forward_flag       -- 入出庫転送フラグ
               ,dhs.stock_forward_date       -- 入出庫転送済日付
               ,dhs.results_forward_flag     -- 販売実績連携済フラグ
               ,dhs.results_forward_date     -- 販売実績連携済日付
               ,dhs.cancel_correct_class     -- 取消・訂正区分
         INTO   lt_row_id
               ,lt_order_no_ebs
               ,lt_base_code
               ,lt_performance_by_code
               ,lt_dlv_by_code
               ,lt_dlv_date
               ,lt_inspect_date
               ,lt_sales_classification
               ,lt_sales_invoice
               ,lt_card_sale_class
               ,lt_dlv_time
               ,lt_customer_number
               ,lt_change_out_time_100
               ,lt_change_out_time_10
               ,lt_system_class
               ,lt_input_class
               ,lt_consumption_tax_class
               ,lt_total_amount
               ,lt_sale_discount_amount
               ,lt_sales_consumption_tax
               ,lt_tax_include
               ,lt_keep_in_code
               ,lt_department_screen_class
               ,lt_red_black_flag
               ,lt_stock_forward_flag
               ,lt_stock_forward_date
               ,lt_results_forward_flag
               ,lt_results_forward_date
               ,lt_cancel_correct_class
         FROM   xxcos_dlv_headers dhs            -- 納品ヘッダ
         WHERE  dhs.order_no_hht        = lt_order_no_hht
         AND    dhs.digestion_ln_number = lt_digestion_ln_number
         AND    dhs.hht_invoice_no      = lt_hht_invoice_no
         ORDER BY dhs.order_no_hht,dhs.hht_invoice_no;
    --******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --      --================================
    --      --販売実績ヘッダID(シーケンス取得)
    --      --================================
    --      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
    --      INTO ln_actual_id
    --      FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
--
--******************************* 2009/09/04 1.21 N.Maeda ADD START ***************************************
        --==================================
        -- 1.納品日算出
        --==================================
        get_fiscal_period_from(
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD START ***********************************
--            iv_div        => cv_fiscal_period_ar             -- 会計区分
            iv_div        => cv_fiscal_period_inv            -- 会計区分
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD END *************************************
          , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
          , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
          , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
          , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
          , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD START ***********************************
--                                                iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
                                                iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD END *************************************
                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                iv_token_value2  => lt_order_no_hht,
                                                iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
                                                iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ),
                                                iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                iv_token_name5   => cv_cust_code,                --トークンコード5
                                                iv_token_value5  => lt_customer_number           --トークン値5
                                              );
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
        END IF;
--
--
        --==================================
        -- 2.売上計上日算出
        --==================================
        get_fiscal_period_from(
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD START ***********************************
--            iv_div        => cv_fiscal_period_ar                  -- 会計区分
            iv_div        => cv_fiscal_period_inv                 -- 会計区分
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD END *************************************
          , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
          , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
          , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
          , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
          , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
        );
        IF ( lv_retcode != cv_status_normal ) THEN
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD START ***********************************
--                                                iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
                                                iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
--******************************* 2010/02/02 Y.Kuboshima Var1.25 MOD END *************************************
                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                iv_token_value2  => lt_order_no_hht,
                                                iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
                                                iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ),
                                                iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                iv_token_name5   => cv_cust_code,                --トークンコード5
                                                iv_token_value5  => lt_customer_number           --トークン値5
                                              );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
          --汎用エラーリスト出力情報設定(A-12)
          set_gen_err_list(
             it_base_code                => lt_base_code                              --拠点コード
           , it_message_name             => ct_msg_fiscal_period_err                  --エラーメッセージ名
           , it_message_text             => NULL                                      --エラーメッセージ
           , iv_output_msg_name_branch   => NULL                                      --エラーメッセージ名枝番
           , iv_output_msg_application   => cv_application                            --アプリケーション名
           , iv_output_msg_name          => ct_msg_xxcos_00216                        --メッセージコード
           , iv_output_msg_token_name1   => cv_tkn_order_number                       --トークンコード1
           , iv_output_msg_token_value1  => TO_CHAR( lt_order_no_hht )                --トークン値1：受注番号
           , iv_output_msg_token_name2   => cv_tkn_base_date                          --トークンコード2
           , iv_output_msg_token_value2  => TO_CHAR( lt_inspect_date,cv_stand_date )  --トークン値2：基準日
           , iv_output_msg_token_name3   => cv_invoice_no                             --トークンコード3
           , iv_output_msg_token_value3  => lt_hht_invoice_no                         --トークン値3：HHT伝票番号
           , iv_output_msg_token_name4   => cv_cust_code                              --トークンコード4
           , iv_output_msg_token_value4  => lt_customer_number                        --トークン値4：顧客コード
           , ov_errbuf                   => lv_errbuf
           , ov_retcode                  => lv_retcode
           , ov_errmsg                   => lv_errmsg
          );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
        END IF;
--******************************* 2009/09/04 1.21 N.Maeda ADD END *****************************************
          --=========================
          --顧客マスタ付帯情報の導出
          --=========================
          BEGIN
-- ****************** 2009/08/10 1.18 N.Maeda MOD START **************************************************************--
-- ***************** 2009/08/21 1.20 N.Maeda MOD START ******************** --
            SELECT  /*+ leading(xch) */
                    xca.sale_base_code         sale_base_code        -- 売上拠点コード
                    ,xch.cash_receiv_base_code cash_receiv_base_code -- 入金拠点コード
                    ,xch.bill_tax_round_rule   bill_tax_round_rule   -- 税金-端数処理(サイト)
                    ,xca.past_sale_base_code   past_sale_base_code   -- 前月売上拠点コード
            INTO    lt_mon_sale_base_code
                    ,lt_cash_receiv_base_code
                    ,lt_tax_odd
                    ,lt_past_sale_base_code
            FROM    hz_cust_accounts        hca    -- 顧客マスタ
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
--            SELECT  /*+
--                      USE_NL(xch.cust_hier.cash_hcar_3)
--                      USE_NL(xch.cust_hier.bill_hasa_3)
--                      USE_NL(xch.cust_hier.bill_hasa_4)
--                    */
--                    xch.ship_sale_base_code,         -- 売上拠点コード
--                    xch.cash_receiv_base_code,  -- 入金拠点コード
--                    xch.bill_tax_round_rule     -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--                    lt_cash_receiv_base_code,
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,       -- 顧客マスタ
--                    xxcos_cust_hierarchy_v xch  -- 顧客階層ビュー
--            WHERE   xch.ship_account_id = hca.cust_account_id
--            AND     hca.account_number  = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
-- ***************** 2009/08/21 1.20 N.Maeda MOD  END  ******************** --
--            SELECT  xca.sale_base_code, --売上拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    xch.cash_receiv_base_code,  --入金拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    --hca.tax_rounding_rule --税金-端数処理
--                    xch.bill_tax_round_rule -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    lt_cash_receiv_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,  --顧客マスタ
--                    xxcmm_cust_accounts xca, --顧客追加情報
--                    xxcos_cust_hierarchy_v xch -- 顧客階層ビュー
--            WHERE   hca.cust_account_id = xca.customer_id
--            AND     xch.ship_account_id = hca.cust_account_id
--            AND     xch.ship_account_id = xca.customer_id
--            AND     hca.account_number = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
---- ********* 2009/08/06 1.18 N.Maeda MOD START **************************** --
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
----            AND     hca.party_id IN ( SELECT  hpt.party_id
----                                      FROM    hz_parties hpt
----                                      WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
---- ********* 2009/08/06 1.18 N.Maeda MOD  END  **************************** --
-- ****************** 2009/08/10 1.18 N.Maeda MOD  END  **************************************************************--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
              --キー編集処理
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
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
                iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- データの値１
                iv_data_value2 => lt_customer_number,       -- データの値２
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
    --
-- ********** 2009/09/04 1.21 N.Maeda DEL START ***************** --
--          -- ========================
--          -- 消費税コードの導出(HHT)
--          -- ========================
--          BEGIN
---- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
--            SELECT  look_val.attribute2,  --消費税コード
--                    look_val.attribute3   --販売実績連携時の消費税区分
--            INTO    lt_consum_code,
--                    lt_consum_type
--            FROM    fnd_lookup_values     look_val
--            WHERE   look_val.language     = ct_user_lang
--            AND     gd_process_date      >= look_val.start_date_active
--            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--            AND     look_val.enabled_flag = cv_tkn_yes
--            AND     look_val.lookup_type  = cv_lookup_type
--            AND     look_val.lookup_code  = lt_consumption_tax_class;
----
----            SELECT  look_val.attribute2,  --消費税コード
----                    look_val.attribute3   --販売実績連携時の消費税区分
----            INTO    lt_consum_code,
----                    lt_consum_type
----            FROM    fnd_lookup_values     look_val,
----                    fnd_lookup_types_tl   types_tl,
----                    fnd_lookup_types      types,
----                    fnd_application_tl    appl,
----                    fnd_application       app
----            WHERE   appl.application_id   = types.application_id
----            AND     app.application_id    = appl.application_id
----            AND     types_tl.lookup_type  = look_val.lookup_type
----            AND     types.lookup_type     = types_tl.lookup_type
----            AND     types.security_group_id   = types_tl.security_group_id
----            AND     types.view_application_id = types_tl.view_application_id
----            AND     types_tl.language = USERENV( 'LANG' )
----            AND     look_val.language = USERENV( 'LANG' )
----            AND     appl.language     = USERENV( 'LANG' )
----            AND     app.application_short_name = cv_application
----            AND     gd_process_date      >= look_val.start_date_active
----            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
----            AND     look_val.enabled_flag = cv_tkn_yes
----            AND     look_val.lookup_type = cv_lookup_type
----            AND     look_val.lookup_code = lt_consumption_tax_class;
---- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ログ出力          
--              gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
--              --キー編集処理
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--    --          lv_key_data1 := lt_consumption_tax_class;
--    --          lv_key_data2 := cv_lookup_type;
--    --          RAISE no_data_extract;
--              lv_state_flg    := cv_status_warn;
--              gn_wae_data_num := gn_wae_data_num + 1 ;
--              xxcos_common_pkg.makeup_key_info(
--                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称１
--                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- 項目名称２
--                iv_data_value1 => lt_consumption_tax_class,         -- データの値１
--                iv_data_value2 => cv_lookup_type,       -- データの値２
--                ov_key_info    => gv_tkn2,              -- キー情報
--                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                ov_retcode     => lv_retcode,           -- リターン・コード
--                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                    iv_application   => cv_application,    --アプリケーション短縮名
--                                                    iv_name          => cv_msg_no_data,    --メッセージコード
--                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                    iv_token_value1  => gv_tkn1,           --トークン値1
--                                                    iv_token_name2   => cv_key_data,       --トークンコード2
--                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--          END;
-- ********** 2009/09/04 1.21 N.Maeda DEL  END  ***************** --
--
            --====================
            --消費税マスタ情報取得
            --====================
          BEGIN
-- ********** 2009/09/04 1.21 N.Maeda MOD START ***************** --
            SELECT  xtv.tax_rate             -- 消費税率
                   ,xtv.tax_class                -- 販売実績連携消費税区分
                   ,xtv.tax_code             -- 税金コード
            INTO    lt_tax_consum
                   ,lt_consum_type
                   ,lt_consum_code
            FROM   xxcos_tax_v   xtv         -- 消費税view
            WHERE  xtv.hht_tax_class    = lt_consumption_tax_class
            AND    xtv.set_of_books_id  = TO_NUMBER( gv_bks_id )
            AND    NVL( xtv.start_date_active, lt_open_inspect_date )  <= lt_open_inspect_date
            AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_open_inspect_date;
--
--              SELECT avtab.tax_rate           -- 消費税率
--              INTO   lt_tax_consum 
--              FROM   ar_vat_tax_all_b avtab   -- AR消費税マスタ
--              WHERE  avtab.tax_code = lt_consum_code
--              AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
--      /*--==============2009/2/4-START=========================--*/
--              AND    NVL( avtab.start_date, gd_process_date ) <= gd_process_date
--              AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
--      /*--==============2009/2/4-END==========================--*/
--      /*--==============2009/2/17-START=========================--*/
--              AND    avtab.enabled_flag = cv_tkn_yes;
--      /*--==============2009/2/17--END==========================--*/
-- ********** 2009/09/04 1.21 N.Maeda MOD  END  ***************** --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
              --キー編集処理
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
    --          lv_key_name2 := NULL;
    --          lv_key_data1 := lt_consum_code;
    --          lv_key_data2 := NULL;
    --          RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
-- ********** 2009/09/04 1.21 N.Maeda MOD START ***************** --
--                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- 項目名称１
--                  iv_data_value1 => lt_consum_code,         -- データの値１
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_order_num_hht ), -- 項目名称１
                iv_data_value1 => lt_order_no_hht,
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_digestion_number ), -- 項目名称
                iv_data_value2 => lt_digestion_ln_number,
                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称
                iv_data_value3 => lt_consumption_tax_class,
-- ********** 2009/09/04 1.21 N.Maeda MOD  END  ***************** --
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
          -- 消費税率算出
          ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
          -- =========================
          -- HHT納品入力日時の成型処理
          -- =========================
          ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                                  SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
    --
          -- ==================================
          -- 出荷元保管場所の導出
          -- ==================================
    --
          --出荷元保管場所の導出
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
              -- ログ出力          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
              --キー編集処理
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
    --          lv_key_data1 := lt_base_code;
    --          lv_key_data2 := cv_bace_branch;
    --        RAISE no_data_extract;
              lv_dept_hht_div_flg := cv_status_warn;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
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
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    /*--==============2009/2/3-START=========================--*/
    --      IF ( lv_depart_code = cv_depart_car ) THEN
            IF ( lv_depart_code IS NULL )
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    /*--==============2009/2/3-END==========================--*/
              --参照コードマスタ：営業車の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
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
--                SELECT  look_val.meaning      --保管場所分類コード
--                INTO    lt_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_05;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
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
                FROM   mtl_secondary_inventories msi    --保管場所マスタ
                WHERE  msi.attribute7 = lt_base_code
                AND    msi.attribute13 = lt_location_type_code
                AND    msi.attribute3 = lt_dlv_by_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
                  --キー編集処理用変数
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_05;
    --            RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                  iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                  iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_dlv_by_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称4
                  iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  iv_data_value1 => lt_base_code,         -- データの値１
    --              iv_data_value2 => cv_xxcos_001_a05_05,       -- データの値２
                  iv_data_value2 => lt_location_type_code,       -- データの値２
                  iv_data_value3 => lt_dlv_by_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_data_value4 => lt_hht_invoice_no,           -- データの値４
                  iv_data_value5 => lt_customer_number,          -- データの値５
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                --汎用エラーリスト出力情報設定(A-12)
                set_gen_err_list(
                   it_base_code                => lt_base_code           --拠点コード
                 , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                 , it_message_text             => gv_tkn2                --エラーメッセージ
                 , iv_output_msg_name_branch   => cv_msg_branch_num_01   --メッセージ名枝番
                 , ov_errbuf                   => lv_errbuf
                 , ov_retcode                  => lv_retcode
                 , ov_errmsg                   => lv_errmsg
                );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
    /*--==============2009/2/3-START=========================--*/
    --      ELSIF ( lv_depart_code = cv_depart_type ) THEN
    --      ELSIF ( lv_depart_code IS NOT NULL ) THEN
            ELSIF ( lv_depart_code = cv_depart_type ) 
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    /*--==============2009/2/3-END==========================--*/
              --参照コードマスタ：百貨店の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  look_val.meaning    --保管場所分類コード
                INTO    lt_depart_location_type_code
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_hokan_mst_001_a05
                AND     look_val.lookup_code  = cv_xxcos_001_a05_09;
--
--                SELECT  look_val.meaning    --保管場所分類コード
--                INTO    lt_depart_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_09;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  --キー編集処理
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
                SELECT msi.secondary_inventory_name           -- 保管場所名称
                INTO   lt_secondary_inventory_name
                FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
                       mtl_parameters mp                      -- 組織パラメータ
                WHERE  msi.organization_id=mp.organization_id
                AND    mp.organization_code = gv_orga_code
                AND    msi.attribute4       = lt_keep_in_code
                AND    msi.attribute13      = lt_depart_location_type_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
                  --キー編集処理用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_09;
    --            RAISE no_data_extract;
                  lv_state_flg    := cv_status_warn;
                  gn_wae_data_num := gn_wae_data_num + 1 ;
                  xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                    iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_keep_in_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),   -- 項目名称4
                    iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ),  -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    iv_data_value1 => lt_base_code,         -- データの値１
    --                iv_data_value2 => cv_xxcos_001_a05_09,       -- データの値２
                    iv_data_value2 => lt_depart_location_type_code,       -- データの値２
                    iv_data_value3 => lt_keep_in_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_data_value4 => lt_hht_invoice_no,                  -- データの値4
                    iv_data_value5 => lt_customer_number,                 -- データの値5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    ov_key_info    => gv_tkn2,              -- キー情報
                    ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                    ov_retcode     => lv_retcode,           -- リターン・コード
                    ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                  gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  --汎用エラーリスト出力情報設定(A-12)
                  set_gen_err_list(
                     it_base_code                => lt_base_code           --拠点コード
                   , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                   , it_message_text             => gv_tkn2                --エラーメッセージ
                   , iv_output_msg_name_branch   => cv_msg_branch_num_02   --メッセージ名枝番
                   , ov_errbuf                   => lv_errbuf
                   , ov_retcode                  => lv_retcode
                   , ov_errmsg                   => lv_errmsg
                  );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --
          -- =============
          -- 納品形態区分の導出
          -- =============
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
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        RAISE delivered_from_err_expt;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,
                                                    iv_name          => cv_msg_delivered_from_err );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END IF;
    --
          -- ===================
          -- 納品拠点の導出
          -- ===================
          BEGIN
--************* 2009/08/12 N.Maeda Var1.19 MOD START ***************************************
            SELECT rin_v.base_code  base_code -- 拠点コード
            INTO   lt_dlv_base_code
--************* 2009/10/30 M.Sano  Var1.23 MOD START ***************************************
--            FROM   xxcos_rs_info_v  rin_v        -- 従業員情報view
            FROM   xxcos_rs_info2_v rin_v        -- 従業員情報view
--************* 2009/10/30 M.Sano  Var1.23 MOD  END  ***************************************
            WHERE  rin_v.employee_number = lt_dlv_by_code
            AND    NVL( rin_v.effective_start_date     , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.effective_end_date       , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.per_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.per_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.paa_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.paa_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            ;
--            SELECT rin_v.base_code  --拠点コード
--            INTO lt_dlv_base_code
--            FROM xxcos_rs_info_v rin_v   --従業員情報view
--            WHERE rin_v.employee_number = lt_dlv_by_code
--    /*--==============2009/2/3-START=========================--*/
--            AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
--            AND   NVL( rin_v.effective_end_date, lt_dlv_date )  >= lt_dlv_date;
--    /*--==============2009/2/3-END=========================--*/
--************* 2009/08/12 N.Maeda Var1.19 MOD  END  ***************************************
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- ログ出力          
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
                --キー編集用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
    --            lv_key_name2 := NULL;
    --            lv_key_data1 := lt_dlv_by_code;
    --            lv_key_data2 := NULL;
    --         RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- 項目名称１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称２
                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  iv_data_value1 => lt_dlv_by_code,         -- データの値１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_data_value2 => lt_hht_invoice_no,      -- データの値２
                  iv_data_value3 => lt_customer_number,     -- データの値３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                --汎用エラーリスト出力情報設定(A-12)
                set_gen_err_list(
                   it_base_code                => lt_base_code           --拠点コード
                 , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                 , it_message_text             => gv_tkn2                --エラーメッセージ
                 , iv_output_msg_name_branch   => cv_msg_branch_num_03   --メッセージ名枝番
                 , ov_errbuf                   => lv_errbuf
                 , ov_retcode                  => lv_retcode
                 , ov_errmsg                   => lv_errmsg
                );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
          END;
    --
            -- =====================
            -- 納品伝票入力区分の導出
            -- =====================
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  DECODE( lt_digestion_ln_number, 
                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
                INTO    lt_ins_invoice_type
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_input_class
                AND     look_val.lookup_code  = lt_input_class;
--
--    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
--    --            SELECT  DECODE( lt_cancel_correct_class, 
--    --                            cv_stand_class, look_val.attribute4,    -- 取消・訂正区分が｢NULL｣(通常時)(販売実績入力区分)
--    --                            cn_correct_class, look_val.attribute5,  -- 取消・訂正区分が｢1｣(訂正)(販売実績入力区分)
--    --                            cn_cancel_class, look_val.attribute5)   -- 取消・訂正区分が｢2｣(取消)(販売実績入力区分)
--                SELECT  DECODE( lt_digestion_ln_number, 
--                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
--                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
--    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--                INTO    lt_ins_invoice_type
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_input_class
--                AND     look_val.lookup_code = lt_input_class;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
                  --キー編集表変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
    --              lv_key_name2 := NULL;
    --              lv_key_data1 := lt_input_class;
    --              lv_key_data2 := NULL;
    --            RAISE no_data_extract;
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
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
              END;
    --
--******************************* 2009/09/04 1.21 N.Maeda DEL START ***************************************
--    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
--        --==================================
--        -- 1.納品日算出
--        --==================================
--        get_fiscal_period_from(
--            iv_div        => cv_fiscal_period_ar             -- 会計区分
--          , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
--          , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
--          , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
--          , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
--          , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
--        );
--        IF ( lv_retcode != cv_status_normal ) THEN
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --アプリケーション短縮名
--                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--                                                iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                                iv_token_value2  => lt_order_no_hht,
--                                                iv_token_name3   => cv_tkn_base_date,
--                                                iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
--        END IF;
--    --
--    --
--        --==================================
--        -- 2.売上計上日算出
--        --==================================
--        get_fiscal_period_from(
--            iv_div        => cv_fiscal_period_ar                  -- 会計区分
--          , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
--          , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
--          , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
--          , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
--          , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
--        );
--        IF ( lv_retcode != cv_status_normal ) THEN
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --アプリケーション短縮名
--                                                iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
--                                                iv_token_name1   => cv_tkn_account_name,         --トークンコード1
--                                                iv_token_value1  => cv_fiscal_period_ar,         --トークン値1
--                                                iv_token_name2   => cv_tkn_order_number,         --トークンコード2
--                                                iv_token_value2  => lt_order_no_hht,
--                                                iv_token_name3   => cv_tkn_base_date,
--                                                iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
--        END IF;
--    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--******************************* 2009/09/04 1.21 N.Maeda DEL END *****************************************
    --
-- ************ 2009/10/13 1.22 N.Maeda ADD START *********** --
          IF ( NVL( lt_order_no_ebs, 0 ) <> 0 ) AND ( lt_red_black_flag = cv_black_flag)
-- ************ 2009/10/13 N.Maeda MOD START *********** --
--            AND ( lt_digestion_ln_number = 1 ) THEN
            AND ( lt_digestion_ln_number = 0 ) THEN
-- ************ 2009/10/13 N.Maeda MOD  END  *********** --
            BEGIN
              OPEN  get_oe_order_cur;
              -- バルクフェッチ
              FETCH get_oe_order_cur BULK COLLECT INTO gt_inp_oe_order_all;
              -- 抽出件数セット
              gn_om_data_cnt := gn_om_data_cnt + get_oe_order_cur%ROWCOUNT;
              -- カーソルCLOSE
              CLOSE get_oe_order_cur;
            EXCEPTION
              WHEN lock_err_expt THEN
                IF( get_oe_order_cur%ISOPEN ) THEN
                  CLOSE get_oe_order_cur;
                END IF;
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                gn_om_data_cnt  := 0;
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,            --アプリケーション短縮名
                                                    iv_name          => cv_order_lock_err,         --メッセージコード
                                                    iv_token_name1   => cv_tkn_order_number,       --トークンコード2
                                                    iv_token_value1  => lt_order_no_hht,
                                                    iv_token_name2   => cv_order_number_ebs,
                                                    iv_token_value2  => lt_order_no_ebs,
                                                    iv_token_name3   => cv_invoice_no,
                                                    iv_token_value3  => lt_hht_invoice_no);
              WHEN OTHERS THEN
                IF( get_oe_order_cur%ISOPEN ) THEN
                  CLOSE get_oe_order_cur;
                END IF;
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
                --キー編集表変数設定
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- 項目名称１
                  iv_data_value1 => lt_order_no_ebs,         -- データの値１
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
            END;
    --
          END IF;
-- ************ 2009/10/13 1.22 N.Maeda ADD  END  *********** --
          --明細データ取得
          <<line_loop>>
  --******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
          FOR get_lines_rec IN get_lines_cur LOOP
            lt_lin_order_no_hht          := TRUNC( get_lines_rec.order_no_hht );          -- 受注No.（HHT）
            lt_lin_line_no_hht           := get_lines_rec.line_no_hht;           -- 行No.（HHT）
            lt_lin_digestion_ln_number   := get_lines_rec.digestion_ln_number;   -- 枝番
            lt_lin_order_no_ebs          := get_lines_rec.order_no_ebs;          -- 受注No.（EBS）
            lt_lin_line_number_ebs       := get_lines_rec.line_number_ebs;       -- 明細番号（EBS）
            lt_lin_item_code_self        := get_lines_rec.item_code_self;        -- 品名コード（自社）
            lt_lin_content               := get_lines_rec.content;               -- 入数
            lt_lin_inventory_item_id     := get_lines_rec.inventory_item_id;     -- 品目ID
            lt_lin_standard_unit         := get_lines_rec.standard_unit;         -- 基準単位
            lt_lin_case_number           := get_lines_rec.case_number;           -- ケース数
            lt_lin_quantity              := get_lines_rec.quantity;              -- 数量
            lt_lin_sale_class            := get_lines_rec.sale_class;            -- 売上区分
            lt_lin_wholesale_unit_ploce  := get_lines_rec.wholesale_unit_ploce;  -- 卸単価
            lt_lin_selling_price         := get_lines_rec.selling_price;         -- 売単価
            lt_lin_column_no             := get_lines_rec.column_no;             -- コラムNo.
            lt_lin_h_and_c               := get_lines_rec.h_and_c;               -- H/C
            lt_lin_sold_out_class        := get_lines_rec.sold_out_class;        -- 売切区分
            lt_lin_sold_out_time         := get_lines_rec.sold_out_time;         -- 売切時間
            lt_lin_replenish_number      := get_lines_rec.replenish_number;      -- 補充数
            lt_lin_cash_and_card         := get_lines_rec.cash_and_card;         -- 現金・カード併用額
  --        FOR line_no IN ln_line_no..gn_inp_line_cnt LOOP
  --          lt_lin_order_no_hht          := TRUNC( gt_inp_dlv_hht_lines_data( line_no ).order_no_hht );          -- 受注No.（HHT）
  --          lt_lin_line_no_hht           := gt_inp_dlv_hht_lines_data( line_no ).line_no_hht;           -- 行No.（HHT）
  --          lt_lin_digestion_ln_number   := gt_inp_dlv_hht_lines_data( line_no ).digestion_ln_number;   -- 枝番
  --          lt_lin_order_no_ebs          := gt_inp_dlv_hht_lines_data( line_no ).order_no_ebs;          -- 受注No.（EBS）
  --          lt_lin_line_number_ebs       := gt_inp_dlv_hht_lines_data( line_no ).line_number_ebs;       -- 明細番号（EBS）
  --          lt_lin_item_code_self        := gt_inp_dlv_hht_lines_data( line_no ).item_code_self;        -- 品名コード（自社）
  --          lt_lin_content               := gt_inp_dlv_hht_lines_data( line_no ).content;               -- 入数
  --          lt_lin_inventory_item_id     := gt_inp_dlv_hht_lines_data( line_no ).inventory_item_id;     -- 品目ID
  --          lt_lin_standard_unit         := gt_inp_dlv_hht_lines_data( line_no ).standard_unit;         -- 基準単位
  --          lt_lin_case_number           := gt_inp_dlv_hht_lines_data( line_no ).case_number;           -- ケース数
  --          lt_lin_quantity              := gt_inp_dlv_hht_lines_data( line_no ).quantity;              -- 数量
  --          lt_lin_sale_class            := gt_inp_dlv_hht_lines_data( line_no ).sale_class;            -- 売上区分
  --          lt_lin_wholesale_unit_ploce  := gt_inp_dlv_hht_lines_data( line_no ).wholesale_unit_ploce;  -- 卸単価
  --          lt_lin_selling_price         := gt_inp_dlv_hht_lines_data( line_no ).selling_price;         -- 売単価
  --          lt_lin_column_no             := gt_inp_dlv_hht_lines_data( line_no ).column_no;             -- コラムNo.
  --          lt_lin_h_and_c               := gt_inp_dlv_hht_lines_data( line_no ).h_and_c;               -- H/C
  --          lt_lin_sold_out_class        := gt_inp_dlv_hht_lines_data( line_no ).sold_out_class;        -- 売切区分
  --          lt_lin_sold_out_time         := gt_inp_dlv_hht_lines_data( line_no ).sold_out_time;         -- 売切時間
  --          lt_lin_replenish_number      := gt_inp_dlv_hht_lines_data( line_no ).replenish_number;      -- 補充数
  --          lt_lin_cash_and_card         := gt_inp_dlv_hht_lines_data( line_no ).cash_and_card;         -- 現金・カード併用額
  --  --
  --          EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
  --******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
            --====================================
            --営業原価の導出(販売実績明細(コラム))
            --====================================
            BEGIN
              SELECT ic_item.attribute7,              -- 旧営業原価
                     ic_item.attribute8,              -- 新営業原価
                     ic_item.attribute9,              -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure,     -- 基準単位
                     cmm_item.inc_num                  -- 内訳入数
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit,
                     lt_inc_num
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = lt_lin_item_code_self
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
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
    --            lv_key_data1 := lt_lin_item_code_self;
    --            lv_key_data2 := gn_orga_id;
    --            RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- 項目名称１
                  iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- 項目名称２
                  iv_data_value1 => lt_lin_item_code_self,         -- データの値１
                  iv_data_value2 => gn_orga_id,       -- データの値２
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
            END;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
              -- ===================================
              -- 営業原価判定
              -- ===================================
              IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
                lt_sales_cost := lt_old_sales_cost;
              ELSE
                lt_sales_cost := lt_new_sales_cost;
              END IF;
    --
              -- ============
              -- 明細金額算出
              -- ============
              -- 基準単価
              lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
    --
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
                lt_tax_amount            := cn_cons_tkn_zero;
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                        * ln_tax_data );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC(lt_lin_wholesale_unit_ploce * lt_lin_replenish_number) ;
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount := ln_amount;
                END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount     := ROUND(( lt_pure_amount * ( ln_tax_data - 1 ) ));
    --            ln_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount :=  TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                        * ln_tax_data );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount := ln_amount;
                END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount     := ROUND(( lt_pure_amount * ( ln_tax_data - 1 ) ));
    --            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
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
                lt_stand_unit_price_excl :=  ROUND( ( (lt_lin_wholesale_unit_ploce /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 本体金額
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
    ----          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
    ----            IF ( lt_tax_odd = cv_amount_up ) THEN
    ----              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
    ----            -- 切捨て
    ----            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----              lt_pure_amount := TRUNC( lt_pure_amount );
    ----            -- 四捨五入
    ----            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----              lt_pure_amount := ROUND( lt_pure_amount );
    ----            END IF;
    ----          END IF;
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
    --              lt_pure_amount   := ln_amount;
    --            END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --            -- 消費税金額
    --            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                         - lt_pure_amount );
                -- 消費税金額
                ln_amount           := ( ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) 
                                           /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
              END IF;
    --
              -- 非課税時以外
              IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
                -- 消費税合計積上げ
                  ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
                -- 明細最大消費税取得
                IF ( ABS( ln_max_tax_data ) < ABS( lt_tax_amount ) ) THEN
                  ln_max_tax_data := lt_tax_amount;
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
                 -- ln_max_no_data  := gn_line_data_no;
                  ln_max_no_data  := ln_line_data_count;
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
                END IF;
              END IF;
    --
              -- 明細最大行No確認
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
                IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
                  ln_max_invoice_num := lt_lin_line_no_hht;
                END IF;
              END IF;
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
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
              END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        --====================
    --        --明細データの変数挿入
    --        --====================
    --        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
    --        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- 納品明細番号
    --        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- 売上区分
    --        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- 品目コード
    --        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- 営業原価
    --        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- 現金・カード併用額
    --        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- Ｈ＆Ｃ
    --        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- コラムNo
    --        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- 売切区分
    --        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- 売切時間
    --        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算-IF済フラグ
    --        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF済フラグ
    --        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --        gn_line_data_no := gn_line_data_no + 1;
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
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
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
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- 納品形態区分(導出)
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
            ELSE
              gn_wae_data_count := gn_wae_data_count + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
            ln_line_no := ln_line_no + 1;
    --
          END LOOP line_loop;
    --
          -- =======================================
          -- 値引金額明細生成(A-8)
          -- =======================================
          -- 値引きが発生している場合
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
    --
            -- =================================
            -- 営業原価、基準単位を導出
            -- =================================
            BEGIN
              SELECT ic_item.attribute7,              -- 旧営業原価
                     ic_item.attribute8,              -- 新営業原価
                     ic_item.attribute9,              -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure -- 基準単位
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = gv_disc_item
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
                lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
                lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
                lv_key_data1 := gv_disc_item;
                lv_key_data2 := gn_orga_id;
                RAISE no_data_extract;
            END;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
              -- ===================================
              -- 営業原価判定
              -- ===================================
              IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
                lt_sales_cost := lt_old_sales_cost;
              ELSE
                lt_sales_cost := lt_new_sales_cost;
              END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --/*--==============2009/2/3-START=========================--*/
    ----        IF ( lv_depart_code = cv_depart_car ) THEN
    --        IF ( lv_depart_code IS NULL )
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    --/*--==============2009/2/3-END==========================--*/
    ----
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name     -- 保管場所コード
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi    --保管場所マスタ
    --            WHERE  msi.attribute7 = lt_base_code
    --            AND    msi.attribute13 = lt_location_type_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力          
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --              --キー編集処理用変数
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --              lv_key_data1 := lt_base_code;
    --              lv_key_data2 := cv_xxcos_001_a05_05;
    --            RAISE no_data_extract;
    --          END;
    ----
    --/*--==============2009/2/3-START=========================--*/
    ----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
    ----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
    --        ELSIF ( lv_depart_code = cv_depart_type ) 
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    --/*--==============2009/2/3-END==========================--*/
    ----
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name           -- 保管場所名称
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
    --                   mtl_parameters mp                      -- 組織パラメータ
    --            WHERE  msi.organization_id=mp.organization_id
    --            AND    mp.organization_code = gv_orga_code
    --            AND    msi.attribute4       = lt_keep_in_code
    --            AND    msi.attribute13      = lt_depart_location_type_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --              --キー編集処理用変数設定
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --              lv_key_data1 := lt_base_code;
    --              lv_key_data2 := cv_xxcos_001_a05_09;
    --            RAISE no_data_extract;
    --          END;
    ----
    --        END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
              -- ================
              -- 金額算出処理
              -- ================
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := lt_sale_discount_amount;
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
                lt_tax_amount            := ( lt_sale_amount - lt_pure_amount );
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_sale_amount           := lt_sale_discount_amount;
    --            ln_amount           := lt_sale_discount_amount;
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount := TRUNC( ln_amount );
    --             -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount            := ROUND( lt_sale_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := ( lt_sale_discount_amount );
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_standard_unit_price   := ( lt_sale_discount_amount * ln_tax_data );
    --          IF ( lt_standard_unit_price <> TRUNC( lt_standard_unit_price ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_standard_unit_price := ( TRUNC( lt_standard_unit_price ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_standard_unit_price := TRUNC( lt_standard_unit_price );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_standard_unit_price := ROUND( lt_standard_unit_price );
    --            END IF;
    --          END IF;
    --          ln_amount   := ( lt_sale_discount_amount * ln_tax_data );
    --          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_standard_unit_price := ( TRUNC( ln_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_standard_unit_price := TRUNC( ln_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_standard_unit_price := ROUND( ln_amount );
    --            END IF;
    --          END IF;
                lt_sale_amount := ( lt_sale_discount_amount );
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := lt_sale_discount_amount;
                -- 消費税金額
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount            := ROUND( lt_sale_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_stand_unit_price_excl :=  ROUND( ( (lt_sale_discount_amount /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --            lt_stand_unit_price_excl := ( lt_sale_discount_amount / ln_tax_data );
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
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := lt_sale_discount_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --            -- 本体金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data);
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
    --            ln_amount           := ( lt_sale_discount_amount / ln_tax_data);
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
    --              lt_pure_amount   := ln_amount;
    --            END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 消費税金額
    --            lt_tax_amount            := TRUNC( lt_sale_amount - lt_pure_amount );
                ln_amount           := ( ( lt_sale_discount_amount /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_discount_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
              END IF;
    --
              -- 値引用納品明細番号設定
              ln_max_invoice_num := ln_max_invoice_num + 1;
              -- 登録用値引金額設定
              lt_sale_amount := ( lt_sale_amount * ( -1 ) );
              lt_pure_amount := ( lt_pure_amount * ( -1 ) );
              lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
              -- 赤・黒の金額換算
              --黒の時
              IF ( lt_red_black_flag = cv_black_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := cn_disc_standard_qty;
                -- 売上金額
                lt_set_sale_amount := lt_sale_amount;
                -- 本体金額
                lt_set_pure_amount := lt_pure_amount;
                -- 消費税金額
                lt_set_tax_amount := lt_tax_amount;
              -- 赤の時
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
                -- 売上金額
                lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
                -- 本体金額
                lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
                -- 消費税金額
                lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
              END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        -- =========================================
    --        -- 値引き明細データセット
    --        -- =========================================
    --        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
    --        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- 納品明細番号
    --        gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- 売上区分
    --        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --        gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- 品目コード
    --        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- 営業原価
    --        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --        gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- 現金・カード併用額
    --        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- Ｈ＆Ｃ
    --        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- コラムNo
    --        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- 売切区分
    --        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- 売切時間
    --        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算IF済フラグ
    --        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INVインタフェース済フラグ
    --        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --        gn_line_data_no := gn_line_data_no + 1;
    --
              -- ===================
              -- 一時格納用
              -- ===================
              gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- 納品伝票番号
              gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- 納品明細番号
              gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- 売上区分
              gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- 赤黒フラグ
              gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- 品目コード
              gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- 納品数量
              gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- 基準数量
              gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- 納品単位
              gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- 基準単位
              gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- 納品単価
              gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- 基準単価
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
              gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- 売上金額
              gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- 本体金額
              gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- 消費税金額
              gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- 現金・カード併用額
              gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- 出荷元保管場所
              gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- 納品拠点コード
              gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- Ｈ＆Ｃ
              gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- コラムNo
              gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- 売切区分
              gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- 売切時間
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- 納品形態区分(導出)
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
    --******************************* 2009/06/01 N.Maeda Var1.15 ADD START ***************************************
              gn_disc_count    := gn_disc_count + 1;                       -- 値引明細件数カウント
    --******************************* 2009/05/01 N.Maeda Var1.15 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --
          END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
    --
            -- ==================
            -- ヘッダ登録用金額算出
            -- ==================
            IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- 非課税
    --
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
    --          -- 売上金額合計
    --          lt_sale_amount_sum := lt_total_amount;
    --          -- 本体金額合計
    --          lt_pure_amount_sum := lt_total_amount;
              -- 売上金額合計
              lt_sale_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
              -- 本体金額合計
              lt_pure_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
              -- 消費税金額合計
              lt_tax_amount_sum  := NVL( lt_sales_consumption_tax, cn_cons_tkn_zero );
            ELSE
             --値引発生時
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                  -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
    --              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --                END IF;
    --              END IF;
                    ln_amount := lt_tax_include;
                    IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                      IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                        IF ( SIGN (ln_amount) <> -1 ) THEN
                          lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                        ELSE
                          lt_sale_amount_sum := TRUNC( ln_amount ) - 1;
                        END IF;
    --                    lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                      -- 切捨て
                      ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                        lt_sale_amount_sum := TRUNC( ln_amount );
                      -- 四捨五入
                      ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                        lt_sale_amount_sum := ROUND( ln_amount );
                      END IF;
                    ELSE
                      lt_sale_amount_sum := ln_amount;
                    END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                    lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                    -- 消費税金額合計
                    ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                    IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                      IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                        IF ( SIGN (ln_amount) <> -1 ) THEN
                          lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                        ELSE
                          lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                        END IF;
    --                    lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
    --            ln_amount := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount_sum   := ln_amount;
    --            END IF;
-- ************ 2009/12/21 1.24 N.Maeda ADD START ************ --
                  -- 明細データが値引き明細のみであった場合
                  IF ( ln_line_data_count = 1 ) THEN
                    -- 売上金額合計
                    lt_sale_amount_sum := -(lt_sale_discount_amount);
                    -- 本体金額合計
                    lt_pure_amount_sum := -(lt_sale_discount_amount);
                    -- 消費税金額合計
                    lt_tax_amount_sum  := lt_tax_amount;
                  ELSE
-- ************ 2009/12/21 1.24 N.Maeda ADD  END  ************ --
      --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
      --              lt_sale_amount_sum := lt_tax_include;
                    lt_sale_amount_sum := lt_tax_include - lt_sales_consumption_tax;
      --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
      --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                    -- 本体金額合計
                    lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                    -- 消費税金額合計
                    lt_tax_amount_sum  := lt_sales_consumption_tax;
-- ************ 2009/12/21 1.24 N.Maeda ADD START ************ --
                  END IF;
-- ************ 2009/12/21 1.24 N.Maeda ADD  END  ************ --
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              -- 売上金額合計
    --              lt_sale_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                  -- 本体金額合計
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_tax_include / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_tax_include / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum:= ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 値引消費税算出
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            ln_discount_tax    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
    --            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                ln_discount_tax := TRUNC( ln_discount_tax );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                 ln_discount_tax:= ROUND( ln_discount_tax );
    --              END IF;
    --            END IF;
                  ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        ln_discount_tax := TRUNC( ln_amount ) - 1;
                      END IF;
    --                    ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      ln_discount_tax := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      ln_discount_tax := ROUND( ln_amount );
                    END IF;
                  ELSE
                    ln_discount_tax   := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 消費税金額合計
                  lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
                  -- 本体金額合計
                  lt_pure_amount_sum := ln_line_pure_amount_sum;
                  -- 売上金額合計
                  lt_sale_amount_sum := lt_pure_amount_sum + lt_tax_amount_sum;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
                END IF;
              --値引未発生時金額算出
              ELSE
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                  -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
                  ln_amount := lt_total_amount;
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        lt_sale_amount_sum := TRUNC( ln_amount ) - 1;
                      END IF;
    --                    lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      lt_sale_amount_sum := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      lt_sale_amount_sum := ROUND( ln_amount );
                    END IF;
                  ELSE
                    lt_sale_amount_sum   := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
                  ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                      END IF;
    --                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                  lt_sale_amount_sum := lt_total_amount;
    --              ln_amount := ( lt_total_amount * ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_sale_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_sale_amount_sum   := ln_amount;
    --              END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
    --************************** 2009/05/18 1.15 N.Maeda MOD START ************************************
    --              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
                  lt_tax_amount_sum  := lt_sales_consumption_tax;
    --************************** 2009/05/18 1.15 N.Maeda MOD  END  ************************************
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              -- 売上金額合計
    --              lt_sale_amount_sum := lt_total_amount;
                  -- 本体金額合計
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_total_amount / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
                  lt_pure_amount_sum := ln_line_pure_amount_sum;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 消費税金額合計
                  lt_tax_amount_sum  := ln_all_tax_amount;
                  -- 売上金額合計
                  lt_sale_amount_sum := lt_pure_amount_sum + lt_tax_amount_sum;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
                END IF;
              END IF;
            END IF;
    --
            --非課税以外の時
            IF (lt_consumption_tax_class <> cv_non_tax) THEN
              -- ================================================
              -- ヘッダ売上消費税額と明細売上消費税額比較判断処理
              -- ================================================
              -- 値引明細がnull以外の時
              IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
              AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
                ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
              END IF;
              IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
                -- 外税 OR 内税(伝票課税の時)
                IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
                  IF ( lt_red_black_flag = cv_black_flag) THEN
    --                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                  ELSIF ( lt_red_black_flag = cv_red_flag) THEN
    --                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
    --                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
                  END IF;
                END IF;
              END IF;
            END IF;
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
    --
    --******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
            IF ( NVL( lt_order_no_ebs, 0 ) <> 0 ) AND ( lt_red_black_flag = cv_black_flag)
-- ************ 2009/10/13 N.Maeda MOD START *********** --
--            AND ( lt_digestion_ln_number = 1 ) THEN
            AND ( lt_digestion_ln_number = 0 ) THEN
-- ************ 2009/10/13 N.Maeda MOD  END  *********** --
-- ************ 2009/10/13 N.Maeda DEL START *********** --
--              BEGIN
--                OPEN  get_oe_order_cur;
--                -- バルクフェッチ
--                FETCH get_oe_order_cur BULK COLLECT INTO gt_inp_oe_order_all;
--                -- 抽出件数セット
--                gn_om_data_cnt := gn_om_data_cnt + get_oe_order_cur%ROWCOUNT;
--                -- カーソルCLOSE
--                CLOSE get_oe_order_cur;
--              EXCEPTION
--                WHEN OTHERS THEN
--                  IF( get_oe_order_cur%ISOPEN ) THEN
--                    CLOSE get_oe_order_cur;
--                  END IF;
--                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
--                  --キー編集表変数設定
--                  lv_state_flg    := cv_status_warn;
--                  gn_wae_data_num := gn_wae_data_num + 1 ;
--                  xxcos_common_pkg.makeup_key_info(
--                    iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- 項目名称１
--                    iv_data_value1 => lt_order_no_ebs,         -- データの値１
--                    ov_key_info    => gv_tkn2,              -- キー情報
--                    ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                    ov_retcode     => lv_retcode,           -- リターン・コード
--                    ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--                  gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                        iv_application   => cv_application,    --アプリケーション短縮名
--                                                        iv_name          => cv_msg_no_data,    --メッセージコード
--                                                        iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                        iv_token_value1  => gv_tkn1,           --トークン値1
--                                                        iv_token_name2   => cv_key_data,       --トークンコード2
--                                                        iv_token_value2  => gv_tkn2 );         --トークン値2
--              END;
-- ************ 2009/10/13 N.Maeda DEL  END  *********** --
    --
              IF ( gt_inp_oe_order_all.COUNT > 0 ) AND ( lv_state_flg <> cv_status_warn )THEN
                <<om_order_loop>>
                FOR om_data_no IN 1..gt_inp_oe_order_all.COUNT LOOP
                  -- ====================================
                  -- OM受注情報格納
                  -- ====================================
                  gt_oe_order_number( gn_cnt_om_order )      := gt_inp_oe_order_all( om_data_no ).order_number;
                  gt_oe_header_id( gn_cnt_om_order )         := gt_inp_oe_order_all( om_data_no ).header_id;
                  gt_oe_he_flow_status_code( gn_cnt_om_order )  := gt_inp_oe_order_all( om_data_no ).head_flow_status_code;
                  gt_oe_order_source_id( gn_cnt_om_order )   := gt_inp_oe_order_all( om_data_no ).order_source_id;
                  gt_oe_cust_po_number( gn_cnt_om_order )    := gt_inp_oe_order_all( om_data_no ).cust_po_number;
                  gt_oe_line_id( gn_cnt_om_order )           := gt_inp_oe_order_all( om_data_no ).line_id;
                  gt_oe_li_flow_status_code( gn_cnt_om_order )  := gt_inp_oe_order_all( om_data_no ).line_flow_status_code;
-- ************ 2009/10/13 1.22 N.Maeda DEL START *********** --
                  gt_oe_line_row_id( gn_cnt_om_order )       := gt_inp_oe_order_all( om_data_no ).row_id;
-- ************ 2009/10/13 1.22 N.Maeda DEL  END  *********** --
                  gn_cnt_om_order := gn_cnt_om_order + 1;
                END LOOP om_order_loop;
              END IF;
            END IF;
    --      END IF;
    --******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
            BEGIN
              SELECT  dhs.cancel_correct_class
              INTO    lt_max_cancel_correct_class
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE  dhs.order_no_hht = dls.order_no_hht
--              AND    dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE  dhs.order_no_hht = dls.order_no_hht(+)
              AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
              AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
                OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
                  AND ( dhs.input_class  = cv_input_delivery ) ) )
              AND    dhs.results_forward_flag = cv_untreated_flg
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND    dhs.program_application_id IS NULL
--              AND    dls.program_application_id IS NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND    dhs.order_no_hht        = lt_order_no_hht
              AND    dhs.digestion_ln_number = ( SELECT  MAX( dhs.digestion_ln_number)
                                                  FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                                                          xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--                                                  WHERE  dhs.order_no_hht = dls.order_no_hht
--                                                  AND    dhs.digestion_ln_number = dls.digestion_ln_number
                                                  WHERE  dhs.order_no_hht = dls.order_no_hht(+)
                                                  AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
                                                  AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
                                                  AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
                                                    AND dhs.input_class
                                                          NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
                                                  OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
                                                    AND ( dhs.input_class  = cv_input_delivery ) ) )
                                                  AND    dhs.results_forward_flag = cv_untreated_flg
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--                                                  AND    dhs.program_application_id IS NULL
--                                                  AND    dls.program_application_id IS NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
                                                  AND     dhs.order_no_hht        = lt_order_no_hht )
              GROUP BY dhs.cancel_correct_class;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
    --
            BEGIN
              SELECT  MIN(dhs.digestion_ln_number)
              INTO    lt_min_digestion_ln_number
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE  dhs.order_no_hht = dls.order_no_hht
--              AND    dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE  dhs.order_no_hht = dls.order_no_hht(+)
              AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
              AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
                OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
                  AND ( dhs.input_class  = cv_input_delivery ) ) )
              AND    dhs.results_forward_flag = cv_untreated_flg
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND    dhs.program_application_id IS NULL
--              AND    dls.program_application_id IS NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND     dhs.order_no_hht        = lt_order_no_hht;
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
                  lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
                  RAISE;
              END;
    --
              IF ( ln_sales_exp_count <> 0 ) THEN
                <<sales_exp_update_loop>>
                FOR u in 1..ln_sales_exp_count LOOP
                  gn_set_sales_exp_count := gn_set_sales_exp_count + 1;
                  gt_set_sales_head_row_id( gn_set_sales_exp_count )   := gt_sales_head_row_id(u);
                  gt_set_head_cancel_cor_cls( gn_set_sales_exp_count ) := lt_max_cancel_correct_class;
                END LOOP sales_exp_update_loop;
              END IF;
            END IF;
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            --================================
            --販売実績ヘッダID(シーケンス取得)
            --================================
            SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
            INTO ln_actual_id
            FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --
            --==========================
            -- ヘッダデータの変数挿入
            --==========================
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
            gt_head_id( gn_head_data_no )                      := ln_actual_id;                 -- 販売実績ヘッダID
            gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;              -- 受注番号
            gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;            -- 納品伝票番号
            gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;              -- 受注No(HHT)
            gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;       -- 枝番(受注No(HHT)枝番)
            gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;          -- 納品伝票区分(導出)
            gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;      -- 取消・訂正区分
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --      gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;      -- 取消・訂正区分
            gt_head_cancel_cor_cls( gn_head_data_no )          := lt_max_cancel_correct_class;  --  取消・訂正区分
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END   ***************************************
            gt_head_system_class( gn_head_data_no )            := lt_system_class;              -- 業態区分(業態小分類)
            gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                  -- 納品日
            gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;              -- 検収日(売上計上日)
            gt_head_customer_number( gn_head_data_no )         := lt_customer_number;           -- 顧客【納品先
            gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;       -- 売上金額合計
            gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;       -- 本体金額合計
            gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;        -- 消費税金額合計(半導出)
            gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;               -- 消費税区分(導出)
            gt_head_tax_code( gn_head_data_no )                := lt_consum_code;               -- 税金コード(導出)
            gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;                -- 消費税率(導出)
            gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;       -- 成績計上者コード
            gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;            -- 売上拠点コード(導出)
            gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;           -- カード売り区分
    --        gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;      -- 伝票区分
    --        gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;             -- 伝票分類コード
            gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;             -- 伝票区分
            gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;      -- 伝票分類コード
    -- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
    --        gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- 入金拠点コード(導出)
            gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- 入金拠点コード(導出)
    -- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
            gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;       -- つり銭切れ時間100円
            gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;        -- つり銭切れ時間10円
            gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;                -- HHT納品入力日時(成型日時)
            gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;               -- 納品者コード
            gt_head_business_date( gn_head_data_no )           := gd_process_date;              -- 登録業務日付(初期処理取得)
            gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                  -- 受注ソースID(NULL設定)
            gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                  -- 注文伝票番号(NULL設定)
            gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                  -- 受注関連番号(NULL設定)
            gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- AR-IF済フラグ('N')
            gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- GL-IF済フラグ('N')
            gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- 情報システムIF済フラグ('N')
            gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- EDI送信済みフラグ('N'設定)
            gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                  -- EDI送信日時(NULL設定)
    -- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
    --        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;          -- 作成元区分(｢4｣設定)
            gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;          -- 作成元区分(｢4｣設定)
    -- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
            gt_head_input_class( gn_head_data_no )             := lt_input_class;               -- 入力区分
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
            gt_head_open_dlv_date( gn_head_data_no )           := lt_open_dlv_date;
            gt_head_open_inspect_date( gn_head_data_no )       := lt_open_inspect_date;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
            gn_head_data_no := gn_head_data_no + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
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
              gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
              gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
              gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- 納品伝票番号
              gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- 納品明細番号
              gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- 売上区分
              gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- 赤黒フラグ
              gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- 品目コード
              gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- 基準数量
              gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- 基準単位
              gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- 基準単価
              gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- 営業原価
              gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- 売上金額
              gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- 本体金額
              gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- 消費税金額
              gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- 現金・カード併用額
              gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- 出荷元保管場所
              gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- 納品拠点コード
              gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- Ｈ＆Ｃ
              gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- コラムNo
              gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- 売切区分
              gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- 売切時間
              gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- 手数料計算IF済フラグ
              gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- 単価マスタ作成済フラグ
              gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INVインタフェース済フラグ
              gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- 注文明細番号
              gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- 税抜基準単価
              gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- 納品形態区分
              gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- 納品数量
              gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- 納品単位
              gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- 納品単価
              gn_line_data_no := gn_line_data_no + 1;
            END LOOP line_set_loop;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          ELSE
            gn_wae_data_count := gn_wae_data_count + ln_line_data_count;
            gn_warn_cnt       := gn_warn_cnt + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
----******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
        ELSE
          gn_warn_cnt := gn_warn_cnt + 1 ;
        END IF;
--
      EXCEPTION
        WHEN lock_err_expt THEN
          IF( get_lines_cur%ISOPEN ) THEN
            CLOSE get_lines_cur;
          END IF;
          IF( get_lock_cur%ISOPEN ) THEN
            CLOSE get_lock_cur;
          END IF;
          lt_order_no_hht_err := lt_order_no_hht;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gn_warn_cnt     := gn_warn_cnt + 1;
--
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_data_loc,    --メッセージコード
                                                iv_token_name1   => cv_tkn_order_number,       --トークンコード2
                                                iv_token_value1  => lt_order_no_hht,
                                                iv_token_name2   => cv_invoice_no,
                                                iv_token_value2  => lt_hht_invoice_no);
      END;
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END   ***************************************
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --キー編集関数
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, lv_key_data1, lv_key_name2, lv_key_data2,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         gv_tkn2, lv_errbuf, lv_retcode, lv_errmsg);  
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
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
  END proc_inp_molded_hht;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_hht
   * Description      : 販売実績データ(HHT)成型処理(A-3)
   ***********************************************************************************/
  PROCEDURE proc_molded_hht(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    --納品ヘッダ(HHT)格納用変数
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- 枝番
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- 受注No.（EBS）
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- 拠点コード
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- 成績者コード
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- 納品者コード
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT伝票No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- 納品日
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- 検収日
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- 売上分類区分
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- 売上伝票区分
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- カード売り区分
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- 時間
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- 顧客コード
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- つり銭切れ時間100円
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- つり銭切れ時間10円
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- 業態区分
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- 入力区分
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- 消費税区分
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- 合計金額
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- 売上値引額
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- 売上消費税額
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- 税込金額
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- 預け先コード
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- 百貨店画面種別
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- 入出庫転送フラグ
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- 入出庫転送済日付
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- 販売実績連携済フラグ
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- 販売実績連携済日付
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- 取消・訂正区分
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- 赤黒フラグ
    --納品明細(HHT)格納用変数
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- 受注No.（HHT）
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- 行No.（HHT）
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- 枝番
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- 受注No.（EBS）
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- 明細番号（EBS）
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- 品名コード（自社）
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- 入数
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- 品目ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- 基準単位
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- ケース数
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- 数量
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- 売上区分
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- 卸単価
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- 売単価
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- コラムNo.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- 売切区分
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- 売切時間
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- 補充数
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- 現金・カード併用額
    -- その他
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- 拠点コード
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- 旧営業原価
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- 新営業原価
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- 営業原価適用開始日
--
    ln_line_no                   NUMBER :=  1;                                    -- 明細チェック済番号
    ln_all_tax_amount            NUMBER :=  0;                                    -- 消費税金額合計値
    ln_max_tax_data              NUMBER :=  0;                                    -- 明細最大消費税額
    ln_actual_id                 NUMBER;                                          -- 販売実績ヘッダID
--    ln_sales_amount              NUMBER;                                          -- 売上金額
--    ln_consum_amount             NUMBER;                                          -- 消費税金額
--    ln_tax_odd                   NUMBER;                                          -- 消費税端数
--    ln_up_odd                    NUMBER;                                          -- 端数切り上げ数値
--    ln_amount_data               NUMBER;                                          -- 本体金額
--    lt_lin_sale_amount           NUMBER;                                          -- 売上金額
    ln_sales_exp_line_id         NUMBER;                                          -- 明細ID
    ln_max_invoice_num           NUMBER;                                          -- 値引明細用納品明細番号
    ld_input_date                DATE;                                            -- HHT納品入力日時
    lt_tax_odd                   xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; -- 税金-端数処理
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- 消費税コード
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- 販売実績連携時の消費税区分
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- 消費税率
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- 基準単位
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --税抜基準単価
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- 保管場所分類コード(営業車)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- 保管場所分類コード(百貨店)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- 保管場所コード
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- 納品伝票区分
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT百貨店入力区分
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- 内訳入数
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- 売上拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code     xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;  -- 入金拠点コード
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- 営業原価
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 売上金額合計
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 本体金額合計
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 消費税金額合計
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--税抜基準単価
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- 基準単価
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- 売上金額
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- 本体金額
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- 消費税金額
--    lt_cust_acct_site_id         hz_cust_acct_sites_all.cust_acct_site_id%TYPE;   -- 顧客サイトID
--    lt_site_use_code             fnd_lookup_values.meaning%TYPE;                  -- 使用区分
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- 登録用基準数量(納品数量)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- 登録用売上金額
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- 登録用本体金額
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- 登録用消費税金額
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- 登録用売上金額合計
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- 登録用本体金額合計
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- 登録用消費税金額合計
    ln_discount_tax              NUMBER;                                          -- 値引消費税額
    ln_tax_data                  NUMBER;                                          -- 税込額算出用
    ln_max_no_data               NUMBER;                                          -- ヘッダ最大消費税明細行番号
    lv_delivery_type             VARCHAR2(100);                                   -- 納品形態区分
    lv_key_name1                 VARCHAR2(500);                                   -- キーデータ名称1
    lv_key_name2                 VARCHAR2(500);                                   -- キーデータ名称2
    lv_key_data1                 VARCHAR2(500);                                   -- キーデータ1
    lv_key_data2                 VARCHAR2(500);                                   -- キーデータ2
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- 更新用行ID
    lv_state_flg                 VARCHAR2(1);                                     -- データ警告確認フラグ
    ln_line_data_count           NUMBER;                                          -- 明細件数(ヘッダ単位)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT百貨店区分エラーフラグ
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
    ln_amount                    NUMBER;                                          -- 作業用金額変数
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
    ln_line_pure_amount_sum      NUMBER;                                          -- 明細合計本体金額
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--
--******************** 2009/05/18 N.Maeda Var1.15 START ******************************************
  lt_max_cancel_correct_class     xxcos_vd_column_headers.cancel_correct_class%TYPE;    -- 最新取消・訂正区分
  lt_min_digestion_ln_number      xxcos_vd_column_headers.digestion_ln_number%TYPE;     -- 枝番最小値
  ln_sales_exp_count              NUMBER :=0 ;                                          -- 更新対象販売実績件数カウント
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
  lt_order_no_hht_err             xxcos_dlv_headers.order_no_hht%TYPE;             -- 受注No.(HHT)
  lt_order_no_hht_ok              xxcos_dlv_headers.order_no_hht%TYPE;
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  ***************************************
-- ************* 2009/08/21 1.20 N.Maeda ADD START *************--
  lt_mon_sale_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_past_sale_base_code               xxcmm_cust_accounts.past_sale_base_code%TYPE;
-- ************* 2009/08/21 1.20 N.Maeda ADD  END  *************--
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
  lt_open_dlv_date                xxcos_dlv_headers.dlv_date%TYPE;                 -- オープン済み納品日
  lt_open_inspect_date            xxcos_dlv_headers.inspect_date%TYPE;             -- オープン済み検収日
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
--
    -- *** ローカル・カーソル ***
--******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
  -- ロック取得カーソル
  CURSOR get_lock_cur
  IS
    SELECT 'Y'
    FROM   xxcos_dlv_headers dhs
          ,xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--    WHERE  dhs.order_no_hht = dls.order_no_hht
--    AND    dhs.digestion_ln_number = dls.digestion_ln_number
    WHERE  dhs.order_no_hht = dls.order_no_hht(+)
    AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
    AND    dhs.order_no_hht = lt_order_no_hht
  FOR UPDATE OF dhs.order_no_hht,dls.digestion_ln_number
  NOWAIT;
--
  -- 明細情報取得カーソル
  CURSOR get_lines_cur
  IS
    SELECT dls.order_no_hht,          -- 受注No.（HHT）
           dls.line_no_hht,           -- 行No.（HHT）
           dls.digestion_ln_number,   -- 枝番
           dls.order_no_ebs,          -- 受注No.（EBS）
           dls.line_number_ebs,       -- 明細番号（EBS）
           dls.item_code_self,        -- 品名コード（自社）
           dls.content,               -- 入数
           dls.inventory_item_id,     -- 品目ID
           dls.standard_unit,         -- 基準単位
           dls.case_number,           -- ケース数
           dls.quantity,              -- 数量
           dls.sale_class,            -- 売上区分
           dls.wholesale_unit_ploce,  -- 卸単価
           dls.selling_price,         -- 売単価
           dls.column_no,             -- コラムNo.
           dls.h_and_c,               -- H/C
           dls.sold_out_class,        -- 売切区分
           dls.sold_out_time,         -- 売切時間
           dls.replenish_number,      -- 補充数
           dls.cash_and_card          -- 現金・カード併用額
    FROM   xxcos_dlv_lines dls              -- 納品明細
    WHERE  dls.order_no_hht        = lt_order_no_hht
    AND    dls.digestion_ln_number = lt_digestion_ln_number;
--
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
  CURSOR get_sales_exp_cur
    IS
      SELECT xseh.ROWID
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.order_no_hht = lt_order_no_hht
  FOR UPDATE NOWAIT;
--******************** 2009/05/18 N.Maeda Var1.15 ADD START ******************************************
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ループ開始：ヘッダ部
    <<header_loop>> 
    FOR ck_no IN 1..gn_target_cnt LOOP
--
      -- 明細番号の初期化
     ln_sales_exp_line_id            := 0;
      -- 積上消費税の初期化
      ln_all_tax_amount               := 0;
      -- 最大消費税額の初期化
      ln_max_tax_data                 := 0;
      -- 最大行No
      ln_max_invoice_num              := 0;
      -- 最大明細番号
      ln_max_no_data                  := 0;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- 明細件数カウント(初期化)
      ln_line_data_count              := 0;
      -- データ警告確認フラグ(初期化)
      lv_state_flg                    := cv_status_normal;
      -- HHT百貨店区分エラー(初期化)
      lv_dept_hht_div_flg             := cv_status_normal;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
      -- 明細合計本体金額
      ln_line_pure_amount_sum           := 0;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
--
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
----******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
--      lt_row_id                    := gt_dlv_hht_headers_data( ck_no ).row_id;                   -- 行ID
----******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := gt_dlv_hht_headers_data( ck_no ).order_no_hht;             -- 受注No.(HHT)
      lt_digestion_ln_number       := gt_dlv_hht_headers_data( ck_no ).digestion_ln_number;      -- 枝番
--      lt_order_no_ebs              := gt_dlv_hht_headers_data( ck_no ).order_no_ebs;             -- 受注No.（EBS）
--      lt_base_code                 := gt_dlv_hht_headers_data( ck_no ).base_code;                -- 拠点コード
--      lt_performance_by_code       := gt_dlv_hht_headers_data( ck_no ).performance_by_code;      -- 成績者コード
--      lt_dlv_by_code               := gt_dlv_hht_headers_data( ck_no ).dlv_by_code;              -- 納品者コード
      lt_hht_invoice_no            := gt_dlv_hht_headers_data( ck_no ).hht_invoice_no;           -- HHT伝票No.
--      lt_dlv_date                  := gt_dlv_hht_headers_data( ck_no ).dlv_date;                 -- 納品日
--      lt_inspect_date              := gt_dlv_hht_headers_data( ck_no ).inspect_date;             -- 検収日
--      lt_sales_classification      := gt_dlv_hht_headers_data( ck_no ).sales_classification;     -- 売上分類区分
--      lt_sales_invoice             := gt_dlv_hht_headers_data( ck_no ).sales_invoice;            -- 売上伝票区分
--      lt_card_sale_class           := gt_dlv_hht_headers_data( ck_no ).card_sale_class;          -- カード売り区分
--      lt_dlv_time                  := gt_dlv_hht_headers_data( ck_no ).dlv_time;                 -- 時間
--      lt_customer_number           := gt_dlv_hht_headers_data( ck_no ).customer_number;          -- 顧客コード
--      lt_change_out_time_100       := gt_dlv_hht_headers_data( ck_no ).change_out_time_100;      -- つり銭切れ時間100円
--      lt_change_out_time_10        := gt_dlv_hht_headers_data( ck_no ).change_out_time_10;       -- つり銭切れ時間10円
--      lt_system_class              := gt_dlv_hht_headers_data( ck_no ).system_class;             -- 業態区分
--      lt_input_class               := gt_dlv_hht_headers_data( ck_no ).input_class;              -- 入力区分
--      lt_consumption_tax_class     := gt_dlv_hht_headers_data( ck_no ).consumption_tax_class;    -- 消費税区分
--      lt_total_amount              := gt_dlv_hht_headers_data( ck_no ).total_amount;             -- 合計金額
--      lt_sale_discount_amount      := gt_dlv_hht_headers_data( ck_no ).sale_discount_amount;     -- 売上値引額
--      lt_sales_consumption_tax     := gt_dlv_hht_headers_data( ck_no ).sales_consumption_tax;    -- 売上消費税額
--      lt_tax_include               := gt_dlv_hht_headers_data( ck_no ).tax_include;              -- 税込金額
--      lt_keep_in_code              := gt_dlv_hht_headers_data( ck_no ).keep_in_code;             -- 預け先コード
--      lt_department_screen_class   := gt_dlv_hht_headers_data( ck_no ).department_screen_class;  -- 百貨店画面種別
--      lt_red_black_flag            := gt_dlv_hht_headers_data( ck_no ).red_black_flag;           -- 赤黒フラグ
--      lt_stock_forward_flag        := gt_dlv_hht_headers_data( ck_no ).stock_forward_flag;       -- 入出庫転送フラグ
--      lt_stock_forward_date        := gt_dlv_hht_headers_data( ck_no ).stock_forward_date;       -- 入出庫転送済日付
--      lt_results_forward_flag      := gt_dlv_hht_headers_data( ck_no ).results_forward_flag;     -- 販売実績連携済フラグ
--      lt_results_forward_date      := gt_dlv_hht_headers_data( ck_no ).results_forward_date;     -- 販売実績連携済日付
--      lt_cancel_correct_class      := gt_dlv_hht_headers_data( ck_no ).cancel_correct_class;     -- 取消・訂正区分
      BEGIN
--
        IF ( lt_order_no_hht_err <> lt_order_no_hht ) OR ( lt_order_no_hht_err IS NULL ) THEN
--
          IF ( lt_order_no_hht_ok <> lt_order_no_hht ) OR ( lt_order_no_hht_ok IS NULL ) THEN
            -- ロック取得
            OPEN  get_lock_cur;
            CLOSE get_lock_cur;
          END IF;
--
           --ロック取得済み受注No.（HHT）
          lt_order_no_hht_ok := lt_order_no_hht;
--
           -- 納品ヘッダ情報取得
           SELECT dhs.ROWID                    -- 行ID
                 ,dhs.order_no_ebs             -- 受注No.（EBS）
                 ,dhs.base_code                -- 拠点コード
                 ,dhs.performance_by_code      -- 成績者コード
                 ,dhs.dlv_by_code              -- 納品者コード
                 ,dhs.dlv_date                 -- 納品日
                 ,dhs.inspect_date             -- 検収日
                 ,dhs.sales_classification     -- 売上分類区分
                 ,dhs.sales_invoice            -- 売上伝票区分
                 ,dhs.card_sale_class          -- カード売り区分
                 ,dhs.dlv_time                 -- 時間
                 ,dhs.customer_number          -- 顧客コード
                 ,dhs.change_out_time_100      -- つり銭切れ時間100円
                 ,dhs.change_out_time_10       -- つり銭切れ時間10円
                 ,dhs.system_class             -- 業態区分
                 ,dhs.input_class              -- 入力区分
                 ,dhs.consumption_tax_class    -- 消費税区分
                 ,dhs.total_amount             -- 合計金額
                 ,dhs.sale_discount_amount     -- 売上値引額
                 ,dhs.sales_consumption_tax    -- 売上消費税額
                 ,dhs.tax_include              -- 税込金額
                 ,dhs.keep_in_code             -- 預け先コード
                 ,dhs.department_screen_class  -- 百貨店画面種別
                 ,dhs.red_black_flag           -- 赤・黒フラグ
                 ,dhs.stock_forward_flag       -- 入出庫転送フラグ
                 ,dhs.stock_forward_date       -- 入出庫転送済日付
                 ,dhs.results_forward_flag     -- 販売実績連携済フラグ
                 ,dhs.results_forward_date     -- 販売実績連携済日付
                 ,dhs.cancel_correct_class     -- 取消・訂正区分
           INTO   lt_row_id
                 ,lt_order_no_ebs
                 ,lt_base_code
                 ,lt_performance_by_code
                 ,lt_dlv_by_code
                 ,lt_dlv_date
                 ,lt_inspect_date
                 ,lt_sales_classification
                 ,lt_sales_invoice
                 ,lt_card_sale_class
                 ,lt_dlv_time
                 ,lt_customer_number
                 ,lt_change_out_time_100
                 ,lt_change_out_time_10
                 ,lt_system_class
                 ,lt_input_class
                 ,lt_consumption_tax_class
                 ,lt_total_amount
                 ,lt_sale_discount_amount
                 ,lt_sales_consumption_tax
                 ,lt_tax_include
                 ,lt_keep_in_code
                 ,lt_department_screen_class
                 ,lt_red_black_flag
                 ,lt_stock_forward_flag
                 ,lt_stock_forward_date
                 ,lt_results_forward_flag
                 ,lt_results_forward_date
                 ,lt_cancel_correct_class
           FROM   xxcos_dlv_headers dhs            -- 納品ヘッダ
           WHERE  dhs.order_no_hht        = lt_order_no_hht
           AND    dhs.digestion_ln_number = lt_digestion_ln_number
           AND    dhs.hht_invoice_no      = lt_hht_invoice_no
           ORDER BY dhs.order_no_hht,dhs.hht_invoice_no;
  --******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --      --================================
    --      --販売実績ヘッダID(シーケンス取得)
    --      --================================
    --      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
    --      INTO ln_actual_id
    --      FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
--******************************* 2010/03/01 1.26 N.Maeda ADD START ***************************************
          --==================================
          -- 1.納品日算出
          --==================================
          get_fiscal_period_from(
              iv_div        => cv_fiscal_period_inv            -- 会計区分
            , id_base_date  => lt_dlv_date                     -- 基準日            =  オリジナル納品日
            , od_open_date  => lt_open_dlv_date                -- 有効会計期間FROM  => 納品日
            , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
            , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
            , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
          );
          IF ( lv_retcode != cv_status_normal ) THEN
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_account_name,         --トークンコード1
                                                  iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
                                                  iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                  iv_token_value2  => lt_order_no_hht,
                                                  iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                  iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ) );
                                                  iv_token_value3  => TO_CHAR( lt_dlv_date,cv_stand_date ),
                                                  iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                  iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                  iv_token_name5   => cv_cust_code,                --トークンコード5
                                                  iv_token_value5  => lt_customer_number           --トークン値5
                                                );
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
          END IF;
--
          --==================================
          -- 2.売上計上日算出
          --==================================
          get_fiscal_period_from(
              iv_div        => cv_fiscal_period_inv                 -- 会計区分
            , id_base_date  => lt_inspect_date                      -- 基準日           =  オリジナル検収日
            , od_open_date  => lt_open_inspect_date                 -- 有効会計期間FROM => 検収日
            , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
            , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
            , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
          );
          IF ( lv_retcode != cv_status_normal ) THEN
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --アプリケーション短縮名
                                                  iv_name          => ct_msg_fiscal_period_err,    --メッセージコード
                                                  iv_token_name1   => cv_tkn_account_name,         --トークンコード1
                                                  iv_token_value1  => cv_fiscal_period_tkn_inv,    --トークン値1
                                                  iv_token_name2   => cv_tkn_order_number,         --トークンコード2
                                                  iv_token_value2  => lt_order_no_hht,
                                                  iv_token_name3   => cv_tkn_base_date,
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--                                                  iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ) );
                                                  iv_token_value3  => TO_CHAR( lt_inspect_date,cv_stand_date ),
                                                  iv_token_name4   => cv_invoice_no,               --トークンコード4
                                                  iv_token_value4  => lt_hht_invoice_no,           --トークン値4
                                                  iv_token_name5   => cv_cust_code,                --トークンコード5
                                                  iv_token_value5  => lt_customer_number           --トークン値5
                                                );
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END   *************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
            --汎用エラーリスト出力情報設定(A-12)
            set_gen_err_list(
               it_base_code                => lt_base_code                              --拠点コード
             , it_message_name             => ct_msg_fiscal_period_err                  --エラーメッセージ名
             , it_message_text             => NULL                                      --エラーメッセージ
             , iv_output_msg_name_branch   => NULL                                      --エラーメッセージ名枝番
             , iv_output_msg_application   => cv_application                            --アプリケーション名
             , iv_output_msg_name          => ct_msg_xxcos_00216                        --メッセージコード
             , iv_output_msg_token_name1   => cv_tkn_order_number                       --トークンコード1
             , iv_output_msg_token_value1  => TO_CHAR( lt_order_no_hht )                --トークン値1：受注番号
             , iv_output_msg_token_name2   => cv_tkn_base_date                          --トークンコード2
             , iv_output_msg_token_value2  => TO_CHAR( lt_inspect_date,cv_stand_date )  --トークン値2：基準日
             , iv_output_msg_token_name3   => cv_invoice_no                             --トークンコード3
             , iv_output_msg_token_value3  => lt_hht_invoice_no                         --トークン値3：HHT伝票番号
             , iv_output_msg_token_name4   => cv_cust_code                              --トークンコード4
             , iv_output_msg_token_value4  => lt_customer_number                        --トークン値4：顧客コード
             , ov_errbuf                   => lv_errbuf
             , ov_retcode                  => lv_retcode
             , ov_errmsg                   => lv_errmsg
            );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
          END IF;
--******************************* 2010/03/01 1.26 N.Maeda ADD  END  ***************************************
          --=========================
          --顧客マスタ付帯情報の導出
          --=========================
          BEGIN
-- ****************** 2009/08/10 1.18 N.Maeda MOD START **************************************************************--
-- ************* 2009/08/21 1.20 N.Maeda MOD START *************--
            SELECT  /*+ leading(xch) */
                    xca.sale_base_code         sale_base_code        -- 売上拠点コード
                   ,xch.cash_receiv_base_code cash_receiv_base_code -- 入金拠点コード
                   ,xch.bill_tax_round_rule   bill_tax_round_rule   -- 税金-端数処理(サイト)
                   ,xca.past_sale_base_code   past_sale_base_code   -- 前月売上拠点コード
            INTO    lt_mon_sale_base_code
                   ,lt_cash_receiv_base_code
                   ,lt_tax_odd
                   ,lt_past_sale_base_code
            FROM    hz_cust_accounts        hca    -- 顧客マスタ
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
--
--            SELECT  /*+
--                      USE_NL(xch.cust_hier.cash_hcar_3)
--                      USE_NL(xch.cust_hier.bill_hasa_3)
--                      USE_NL(xch.cust_hier.bill_hasa_4)
--                    */
--                    xch.ship_sale_base_code,         -- 売上拠点コード
--                    xch.cash_receiv_base_code,  -- 入金拠点コード
--                    xch.bill_tax_round_rule     -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--                    lt_cash_receiv_base_code,
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,       -- 顧客マスタ
--                    xxcos_cust_hierarchy_v xch  -- 顧客階層ビュー
--            WHERE   xch.ship_account_id = hca.cust_account_id
--            AND     hca.account_number  = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
-- ************* 2009/08/21 1.20 N.Maeda MOD  END  *************--
---- ********* 2009/08/06 1.18 N.Maeda ADD START **************************** --
--            SELECT
--                  /*+
--                    use_nl(xch.cust_hier.cash_hcar_3)
--                    use_nl(xch.cust_hier.bill_hasa_3)
--                    use_nl(xch.cust_hier.bill_hasa_4)
--                  */
---- ********* 2009/08/06 1.18 N.Maeda ADD  END  **************************** --
--                    xca.sale_base_code, --売上拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    xch.cash_receiv_base_code,  --入金拠点コード
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    --hca.tax_rounding_rule --税金-端数処理
--                    xch.bill_tax_round_rule -- 税金-端数処理(サイト)
--            INTO    lt_sale_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                    lt_cash_receiv_base_code,
--    -- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                    lt_tax_odd
--            FROM    hz_cust_accounts hca,  --顧客マスタ
--                    xxcmm_cust_accounts xca, --顧客追加情報
--                    xxcos_cust_hierarchy_v xch -- 顧客階層ビュー
--            WHERE   hca.cust_account_id = xca.customer_id
--            AND     xch.ship_account_id = hca.cust_account_id
--            AND     xch.ship_account_id = xca.customer_id
--            AND     hca.account_number = TO_CHAR( lt_customer_number )
--            AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
---- ********* 2009/08/06 1.18 N.Maeda MOD START **************************** --
--            AND     EXISTS
--                    ( SELECT 'Y'
--                      FROM   hz_parties hpt
--                      WHERE  hpt.party_id = hca.party_id
--                      AND    ( ( hpt.duns_number_c = cv_cust_s )
--                        OR     ( hpt.duns_number_c = cv_cust_v )
--                        OR     ( hpt.duns_number_c = cv_cost_p ) )
--                     );
----            AND     hca.party_id IN ( SELECT  hpt.party_id
----                                      FROM    hz_parties hpt
----                                      WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
---- ********* 2009/08/06 1.18 N.Maeda MOD  END  **************************** --
-- ****************** 2009/08/10 1.18 N.Maeda MOD  END  **************************************************************--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --キー編集処理
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
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
-- ********** 2009/09/04 1.21 N.Maeda DEL START ***************** --
--          -- ========================
--          -- 消費税コードの導出(HHT)
--          -- ========================
--          BEGIN
---- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
--            SELECT  look_val.attribute2,  --消費税コード
--                    look_val.attribute3   --販売実績連携時の消費税区分
--            INTO    lt_consum_code,
--                    lt_consum_type
--            FROM    fnd_lookup_values     look_val
--            WHERE   look_val.language     = ct_user_lang
--            AND     gd_process_date      >= look_val.start_date_active
--            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--            AND     look_val.enabled_flag = cv_tkn_yes
--            AND     look_val.lookup_type  = cv_lookup_type
--            AND     look_val.lookup_code  = lt_consumption_tax_class;
----
----            SELECT  look_val.attribute2,  --消費税コード
----                    look_val.attribute3   --販売実績連携時の消費税区分
----            INTO    lt_consum_code,
----                    lt_consum_type
----            FROM    fnd_lookup_values     look_val,
----                    fnd_lookup_types_tl   types_tl,
----                    fnd_lookup_types      types,
----                    fnd_application_tl    appl,
----                    fnd_application       app
----            WHERE   appl.application_id   = types.application_id
----            AND     app.application_id    = appl.application_id
----            AND     types_tl.lookup_type  = look_val.lookup_type
----            AND     types.lookup_type     = types_tl.lookup_type
----            AND     types.security_group_id   = types_tl.security_group_id
----            AND     types.view_application_id = types_tl.view_application_id
----            AND     types_tl.language = USERENV( 'LANG' )
----            AND     look_val.language = USERENV( 'LANG' )
----            AND     appl.language     = USERENV( 'LANG' )
----            AND     app.application_short_name = cv_application
----            AND     gd_process_date      >= look_val.start_date_active
----            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
----            AND     look_val.enabled_flag = cv_tkn_yes
----            AND     look_val.lookup_type = cv_lookup_type
----            AND     look_val.lookup_code = lt_consumption_tax_class;
---- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ログ出力          
--              gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              --キー編集処理
--    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--    --          lv_key_data1 := lt_consumption_tax_class;
--    --          lv_key_data2 := cv_lookup_type;
--    --          RAISE no_data_extract;
--              lv_state_flg    := cv_status_warn;
--              gn_wae_data_num := gn_wae_data_num + 1 ;
--              xxcos_common_pkg.makeup_key_info(
--                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称１
--                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- 項目名称２
--                iv_data_value1 => lt_consumption_tax_class,         -- データの値１
--                iv_data_value2 => cv_lookup_type,                   -- データの値２
--                ov_key_info    => gv_tkn2,              -- キー情報
--                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
--                ov_retcode     => lv_retcode,           -- リターン・コード
--                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
--              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                    iv_application   => cv_application,    --アプリケーション短縮名
--                                                    iv_name          => cv_msg_no_data,    --メッセージコード
--                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
--                                                    iv_token_value1  => gv_tkn1,           --トークン値1
--                                                    iv_token_name2   => cv_key_data,       --トークンコード2
--                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
--    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--          END;
-- ********** 2009/09/04 1.21 N.Maeda DEL  END  ***************** --
--
          --====================
          --消費税マスタ情報取得
          --====================
          BEGIN
-- ********* 2009/09/03 1.21 N.Maeda MOD START **************** --
            SELECT  xtv.tax_rate             -- 消費税率
                   ,xtv.tax_class                -- 販売実績連携消費税区分
                   ,xtv.tax_code             -- 税金コード
            INTO    lt_tax_consum
                   ,lt_consum_type
                   ,lt_consum_code
            FROM   xxcos_tax_v   xtv         -- 消費税view
            WHERE  xtv.hht_tax_class    = lt_consumption_tax_class
            AND    xtv.set_of_books_id  = TO_NUMBER( gv_bks_id )
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
--            AND    NVL( xtv.start_date_active, lt_inspect_date )  <= lt_inspect_date
--            AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_inspect_date;
            AND    NVL( xtv.start_date_active, lt_open_inspect_date )  <= lt_open_inspect_date
            AND    NVL( xtv.end_date_active, gd_max_date ) >= lt_open_inspect_date;
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
--
--            SELECT avtab.tax_rate           -- 消費税率
--            INTO   lt_tax_consum 
--            FROM   ar_vat_tax_all_b avtab   -- AR消費税マスタ
--            WHERE  avtab.tax_code = lt_consum_code
--            AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
--      /*--==============2009/2/4-START=========================--*/
--              AND    NVL( avtab.start_date, gd_process_date ) <= gd_process_date
--              AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
--      /*--==============2009/2/4-END==========================--*/
--    /*--==============2009/2/17-START=========================--*/
--            AND    avtab.enabled_flag = cv_tkn_yes;
--    /*--==============2009/2/17--END==========================--*/
-- ********* 2009/09/03 1.21 N.Maeda MOD  END  **************** --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ログ出力          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --キー編集処理
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
    --          lv_key_name2 := NULL;
    --          lv_key_data1 := lt_consum_code;
    --          lv_key_data2 := NULL;
    --          RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
-- ********** 2009/09/04 1.21 N.Maeda MOD START ***************** --
--                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- 項目名称１
--                  iv_data_value1 => lt_consum_code,         -- データの値１
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_order_num_hht ), -- 項目名称１
                iv_data_value1 => lt_order_no_hht,
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_digestion_number ), -- 項目名称
                iv_data_value2 => lt_digestion_ln_number,
                iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- 項目名称
                iv_data_value3 => lt_consumption_tax_class,
-- ********** 2009/09/04 1.21 N.Maeda MOD  END  ***************** --
                ov_key_info    => gv_tkn2,              -- キー情報
                ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                ov_retcode     => lv_retcode,           -- リターン・コード
                ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
            -- 消費税率算出
            ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
          -- =========================
          -- HHT納品入力日時の成型処理
          -- =========================
          ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                                  SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
    --
          -- ==================================
          -- 出荷元保管場所の導出
          -- ==================================
    --
          --出荷元保管場所の導出
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
              -- ログ出力
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --キー編集処理
    --          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
    --          lv_key_data1 := lt_base_code;
    --          lv_key_data2 := cv_bace_branch;
    --        RAISE no_data_extract;
              lv_dept_hht_div_flg := cv_status_warn;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
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
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    /*--==============2009/2/3-START=========================--*/
    --      IF ( lv_depart_code = cv_depart_car ) THEN
            IF ( lv_depart_code IS NULL )
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    /*--==============2009/2/3-END==========================--*/
              --参照コードマスタ：営業車の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
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
--                SELECT  look_val.meaning      --保管場所分類コード
--                INTO    lt_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_05;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
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
                FROM   mtl_secondary_inventories msi    --保管場所マスタ
                WHERE  msi.attribute7 = lt_base_code
                AND    msi.attribute13 = lt_location_type_code
                AND    msi.attribute3 = lt_dlv_by_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
                  --キー編集処理用変数
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_05;
    --            RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                  iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                  iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_dlv_by_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称4
                  iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  iv_data_value1 => lt_base_code,         -- データの値１
    --              iv_data_value2 => cv_xxcos_001_a05_05,       -- データの値２
                  iv_data_value2 => lt_location_type_code,       -- データの値２
                  iv_data_value3 => lt_dlv_by_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_data_value4 => lt_hht_invoice_no,           -- データの値４
                  iv_data_value5 => lt_customer_number,          -- データの値５
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                --汎用エラーリスト出力情報設定(A-12)
                set_gen_err_list(
                   it_base_code                => lt_base_code           --拠点コード
                 , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                 , it_message_text             => gv_tkn2                --エラーメッセージ
                 , iv_output_msg_name_branch   => cv_msg_branch_num_01   --メッセージ名枝番
                 , ov_errbuf                   => lv_errbuf
                 , ov_retcode                  => lv_retcode
                 , ov_errmsg                   => lv_errmsg
                );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
    /*--==============2009/2/3-START=========================--*/
            ELSIF ( lv_depart_code = cv_depart_type ) 
              OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    --        ELSIF ( lv_depart_code IS NOT NULL ) THEN
    /*--==============2009/2/3-END==========================--*/
              --参照コードマスタ：百貨店の保管場所分類コード取得
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  look_val.meaning    --保管場所分類コード
                INTO    lt_depart_location_type_code
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_hokan_mst_001_a05
                AND     look_val.lookup_code  = cv_xxcos_001_a05_09;
--
--                SELECT  look_val.meaning    --保管場所分類コード
--                INTO    lt_depart_location_type_code
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
--                AND     look_val.lookup_code = cv_xxcos_001_a05_09;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
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
                SELECT msi.secondary_inventory_name           -- 保管場所名称
                INTO   lt_secondary_inventory_name
                FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
                       mtl_parameters mp                      -- 組織パラメータ
                WHERE  msi.organization_id=mp.organization_id
                AND    mp.organization_code = gv_orga_code
                AND    msi.attribute4       = lt_keep_in_code
                AND    msi.attribute13      = lt_depart_location_type_code;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
                  --キー編集処理用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_09;
    --            RAISE no_data_extract;
                  lv_state_flg    := cv_status_warn;
                  gn_wae_data_num := gn_wae_data_num + 1 ;
                  xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- 項目名称１
                    iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- 項目名称２
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, ct_msg_keep_in_code ), -- 項目名称3
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_item_name4  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),   -- 項目名称4
                    iv_item_name5  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ),  -- 項目名称5
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    iv_data_value1 => lt_base_code,         -- データの値１
    --                iv_data_value2 => cv_xxcos_001_a05_09,       -- データの値２
                    iv_data_value2 => lt_depart_location_type_code,       -- データの値２
                    iv_data_value3 => lt_keep_in_code,
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                    iv_data_value4 => lt_hht_invoice_no,                  -- データの値４
                    iv_data_value5 => lt_customer_number,                 -- データの値５
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                    ov_key_info    => gv_tkn2,              -- キー情報
                    ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                    ov_retcode     => lv_retcode,           -- リターン・コード
                    ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                  gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                      iv_application   => cv_application,    --アプリケーション短縮名
                                                      iv_name          => cv_msg_no_data,    --メッセージコード
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  --汎用エラーリスト出力情報設定(A-12)
                  set_gen_err_list(
                     it_base_code                => lt_base_code           --拠点コード
                   , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                   , it_message_text             => gv_tkn2                --エラーメッセージ
                   , iv_output_msg_name_branch   => cv_msg_branch_num_02   --メッセージ名枝番
                   , ov_errbuf                   => lv_errbuf
                   , ov_retcode                  => lv_retcode
                   , ov_errmsg                   => lv_errmsg
                  );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
              END;
    --
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --
          -- =============
          -- 納品形態区分の導出
          -- =============
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
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        RAISE delivered_from_err_expt;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,
                                                    iv_name          => cv_msg_delivered_from_err );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END IF;
    --
          -- ===================
          -- 納品拠点の導出
          -- ===================
          BEGIN
--************* 2009/08/12 N.Maeda Var1.19 MOD START ***************************************
            SELECT rin_v.base_code  base_code -- 拠点コード
            INTO   lt_dlv_base_code
--************* 2009/10/30 M.Sano  Var1.23 MOD START ***************************************
--            FROM   xxcos_rs_info_v  rin_v        -- 従業員情報view
            FROM   xxcos_rs_info2_v rin_v        -- 従業員情報view
--************* 2009/10/30 M.Sano  Var1.23 MOD  START ***************************************
            WHERE  rin_v.employee_number = lt_dlv_by_code
            AND    NVL( rin_v.effective_start_date     , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.effective_end_date       , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.per_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.per_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            AND    NVL( rin_v.paa_effective_start_date , lt_dlv_date )  <= lt_dlv_date
            AND    NVL( rin_v.paa_effective_end_date   , lt_dlv_date )  >= lt_dlv_date
            ;
--
--            SELECT rin_v.base_code  --拠点コード
--            INTO lt_dlv_base_code
--            FROM xxcos_rs_info_v rin_v   --従業員情報view
--            WHERE rin_v.employee_number = lt_dlv_by_code
--    /*--==============2009/2/3-START=========================--*/
--            AND   NVL( rin_v.effective_start_date, lt_dlv_date) <= lt_dlv_date
--            AND   NVL( rin_v.effective_end_date, lt_dlv_date)  >= lt_dlv_date;
--    /*--==============2009/2/3-END=========================--*/
--************* 2009/08/12 N.Maeda Var1.19 MOD  END  ***************************************
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- ログ出力
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
                --キー編集用変数設定
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
    --            lv_key_name2 := NULL;
    --            lv_key_data1 := lt_dlv_by_code;
    --            lv_key_data2 := NULL;
    --          RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- 項目名称１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_invoice_no ),  -- 項目名称２
                  iv_item_name3  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code    ), -- 項目名称３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  iv_data_value1 => lt_dlv_by_code,         -- データの値１
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                  iv_data_value2 => lt_hht_invoice_no,      -- データの値２
                  iv_data_value3 => lt_customer_number,     -- データの値３
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
                --汎用エラーリスト出力情報設定(A-12)
                set_gen_err_list(
                   it_base_code                => lt_base_code           --拠点コード
                 , it_message_name             => cv_msg_no_data         --エラーメッセージ名
                 , it_message_text             => gv_tkn2                --エラーメッセージ
                 , iv_output_msg_name_branch   => cv_msg_branch_num_03   --メッセージ名枝番
                 , ov_errbuf                   => lv_errbuf
                 , ov_retcode                  => lv_retcode
                 , ov_errmsg                   => lv_errmsg
                );
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
          END;
    --
            -- =====================
            -- 納品伝票入力区分の導出
            -- =====================
              BEGIN
-- ********** 2009/08/06 1.18 N.Maeda MOD START ***************** --
                SELECT  DECODE( lt_digestion_ln_number, 
                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
                INTO    lt_ins_invoice_type
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.language     = ct_user_lang
                AND     gd_process_date      >= look_val.start_date_active
                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                AND     look_val.enabled_flag = cv_tkn_yes
                AND     look_val.lookup_type  = cv_xxcos1_input_class
                AND     look_val.lookup_code  = lt_input_class;
--
--    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
--    --            SELECT  DECODE( lt_cancel_correct_class, 
--    --                            cv_stand_class, look_val.attribute4,    -- 取消・訂正区分が｢NULL｣(通常時)(販売実績入力区分)
--    --                            cn_correct_class, look_val.attribute5,  -- 取消・訂正区分が｢1｣(訂正)(販売実績入力区分)
--    --                            cn_cancel_class, look_val.attribute5)   -- 取消・訂正区分が｢2｣(取消)(販売実績入力区分)
--                SELECT  DECODE( lt_digestion_ln_number, 
--                                cn_cons_tkn_zero, look_val.attribute4,    -- 通常時(販売実績入力区分)
--                                look_val.attribute5)                      -- 取消・訂正(販売実績入力区分)
--    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
--                INTO    lt_ins_invoice_type
--                FROM    fnd_lookup_values     look_val,
--                        fnd_lookup_types_tl   types_tl,
--                        fnd_lookup_types      types,
--                        fnd_application_tl    appl,
--                        fnd_application       app
--                WHERE   appl.application_id   = types.application_id
--                AND     app.application_id    = appl.application_id
--                AND     types_tl.lookup_type  = look_val.lookup_type
--                AND     types.lookup_type     = types_tl.lookup_type
--                AND     types.security_group_id   = types_tl.security_group_id
--                AND     types.view_application_id = types_tl.view_application_id
--                AND     types_tl.language = USERENV( 'LANG' )
--                AND     look_val.language = USERENV( 'LANG' )
--                AND     appl.language     = USERENV( 'LANG' )
--                AND     gd_process_date      >= look_val.start_date_active
--                AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                AND     app.application_short_name = cv_application
--                AND     look_val.enabled_flag = cv_tkn_yes
--                AND     look_val.lookup_type = cv_xxcos1_input_class
--                AND     look_val.lookup_code = lt_input_class;
-- ********** 2009/08/06 1.18 N.Maeda MOD  END  ***************** --
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- ログ出力          
                  gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
                  --キー編集表変数設定
    --              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
    --              lv_key_name2 := NULL;
    --              lv_key_data1 := lt_input_class;
    --              lv_key_data2 := NULL;
    --            RAISE no_data_extract;
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
                                                      iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                      iv_token_value1  => gv_tkn1,           --トークン値1
                                                      iv_token_name2   => cv_key_data,       --トークンコード2
                                                      iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
              END;
    --
          --明細データ取得
          <<line_loop>>
  --******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
          FOR get_lines_rec IN get_lines_cur LOOP
            lt_lin_order_no_hht          := get_lines_rec.order_no_hht;          -- 受注No.（HHT）
            lt_lin_line_no_hht           := get_lines_rec.line_no_hht;           -- 行No.（HHT）
            lt_lin_digestion_ln_number   := get_lines_rec.digestion_ln_number;   -- 枝番
            lt_lin_order_no_ebs          := get_lines_rec.order_no_ebs;          -- 受注No.（EBS）
            lt_lin_line_number_ebs       := get_lines_rec.line_number_ebs;       -- 明細番号（EBS）
            lt_lin_item_code_self        := get_lines_rec.item_code_self;        -- 品名コード（自社）
            lt_lin_content               := get_lines_rec.content;               -- 入数
            lt_lin_inventory_item_id     := get_lines_rec.inventory_item_id;     -- 品目ID
            lt_lin_standard_unit         := get_lines_rec.standard_unit;         -- 基準単位
            lt_lin_case_number           := get_lines_rec.case_number;           -- ケース数
            lt_lin_quantity              := get_lines_rec.quantity;              -- 数量
            lt_lin_sale_class            := get_lines_rec.sale_class;            -- 売上区分
            lt_lin_wholesale_unit_ploce  := get_lines_rec.wholesale_unit_ploce;  -- 卸単価
            lt_lin_selling_price         := get_lines_rec.selling_price;         -- 売単価
            lt_lin_column_no             := get_lines_rec.column_no;             -- コラムNo.
            lt_lin_h_and_c               := get_lines_rec.h_and_c;               -- H/C
            lt_lin_sold_out_class        := get_lines_rec.sold_out_class;        -- 売切区分
            lt_lin_sold_out_time         := get_lines_rec.sold_out_time;         -- 売切時間
            lt_lin_replenish_number      := get_lines_rec.replenish_number;      -- 補充数
            lt_lin_cash_and_card         := get_lines_rec.cash_and_card;         -- 現金・カード併用額
  --        FOR line_no IN ln_line_no..gn_line_cnt LOOP
  --          lt_lin_order_no_hht          := gt_dlv_hht_lines_data( line_no ).order_no_hht;          -- 受注No.（HHT）
  --          lt_lin_line_no_hht           := gt_dlv_hht_lines_data( line_no ).line_no_hht;           -- 行No.（HHT）
  --          lt_lin_digestion_ln_number   := gt_dlv_hht_lines_data( line_no ).digestion_ln_number;   -- 枝番
  --          lt_lin_order_no_ebs          := gt_dlv_hht_lines_data( line_no ).order_no_ebs;          -- 受注No.（EBS）
  --          lt_lin_line_number_ebs       := gt_dlv_hht_lines_data( line_no ).line_number_ebs;       -- 明細番号（EBS）
  --          lt_lin_item_code_self        := gt_dlv_hht_lines_data( line_no ).item_code_self;        -- 品名コード（自社）
  --          lt_lin_content               := gt_dlv_hht_lines_data( line_no ).content;               -- 入数
  --          lt_lin_inventory_item_id     := gt_dlv_hht_lines_data( line_no ).inventory_item_id;     -- 品目ID
  --          lt_lin_standard_unit         := gt_dlv_hht_lines_data( line_no ).standard_unit;         -- 基準単位
  --          lt_lin_case_number           := gt_dlv_hht_lines_data( line_no ).case_number;           -- ケース数
  --          lt_lin_quantity              := gt_dlv_hht_lines_data( line_no ).quantity;              -- 数量
  --          lt_lin_sale_class            := gt_dlv_hht_lines_data( line_no ).sale_class;            -- 売上区分
  --          lt_lin_wholesale_unit_ploce  := gt_dlv_hht_lines_data( line_no ).wholesale_unit_ploce;  -- 卸単価
  --          lt_lin_selling_price         := gt_dlv_hht_lines_data( line_no ).selling_price;         -- 売単価
  --          lt_lin_column_no             := gt_dlv_hht_lines_data( line_no ).column_no;             -- コラムNo.
  --          lt_lin_h_and_c               := gt_dlv_hht_lines_data( line_no ).h_and_c;               -- H/C
  --          lt_lin_sold_out_class        := gt_dlv_hht_lines_data( line_no ).sold_out_class;        -- 売切区分
  --          lt_lin_sold_out_time         := gt_dlv_hht_lines_data( line_no ).sold_out_time;         -- 売切時間
  --          lt_lin_replenish_number      := gt_dlv_hht_lines_data( line_no ).replenish_number;      -- 補充数
  --          lt_lin_cash_and_card         := gt_dlv_hht_lines_data( line_no ).cash_and_card;         -- 現金・カード併用額
  --  --
  --          EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
  --******************************* 2009/06/23 N.Maeda Var1.17 ADD END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
    --
            --====================================
            --営業原価の導出(販売実績明細(コラム))
            --====================================
            BEGIN
              SELECT ic_item.attribute7,              -- 旧営業原価
                     ic_item.attribute8,              -- 新営業原価
                     ic_item.attribute9,              -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure,     -- 基準単位
                     cmm_item.inc_num                  -- 内訳入数
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit,
                     lt_inc_num
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = lt_lin_item_code_self
              AND  mtl_item.segment1 = ic_item.item_no
              AND  mtl_item.segment1 = cmm_item.item_code
              AND  cmm_item.item_id  = ic_item.item_id
    /*--==============2009/2/4-START=========================--*/
              AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
              AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
    /*--==============2009/2/4-END==========================--*/
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- ログ出力
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
    --            lv_key_data1 := lt_lin_item_code_self;
    --            lv_key_data2 := gn_orga_id;
    --            RAISE no_data_extract;
                lv_state_flg    := cv_status_warn;
                gn_wae_data_num := gn_wae_data_num + 1 ;
                xxcos_common_pkg.makeup_key_info(
                  iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- 項目名称１
                  iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- 項目名称２
                  iv_data_value1 => lt_lin_item_code_self,         -- データの値１
                  iv_data_value2 => gn_orga_id,       -- データの値２
                  ov_key_info    => gv_tkn2,              -- キー情報
                  ov_errbuf      => lv_errbuf,            -- エラー・メッセージエラー
                  ov_retcode     => lv_retcode,           -- リターン・コード
                  ov_errmsg      => lv_errmsg);            -- ユーザー・エラー・メッセージ
                gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --アプリケーション短縮名
                                                    iv_name          => cv_msg_no_data,    --メッセージコード
                                                    iv_token_name1   => cv_tkn_table_name, --トークンコード1
                                                    iv_token_value1  => gv_tkn1,           --トークン値1
                                                    iv_token_name2   => cv_key_data,       --トークンコード2
                                                    iv_token_value2  => gv_tkn2 );         --トークン値2
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
            END;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
              -- ===================================
              -- 営業原価判定
              -- ===================================
              IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
                lt_sales_cost := lt_old_sales_cost;
              ELSE
                lt_sales_cost := lt_new_sales_cost;
              END IF;
    --
              -- ============
              -- 明細金額算出
              -- ============
              -- 基準単価
              lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
    --
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
                lt_tax_amount            := cn_cons_tkn_zero;
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                        * ln_tax_data );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := ( TRUNC( ln_amount ) - 1 );
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount   := ln_amount;
                END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_tax_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_tax_amount := TRUNC( lt_tax_amount );
    --          -- 四捨五入
    --          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --            lt_tax_amount := ROUND( lt_tax_amount );
    --          END IF;
    --        END IF;
    --        ln_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
              lt_tax_amount        := ROUND(lt_pure_amount * ( ln_tax_data - 1 ));
    --            ln_amount            := lt_pure_amount * ( ln_tax_data - 1 );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
              -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                        * ln_tax_data );
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
                ln_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_sale_amount := ( TRUNC( ln_amount ) - 1 );
                    END IF;
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                  -- 切捨て
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount := TRUNC( ln_amount );
                  -- 四捨五入
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount   := ln_amount;
                END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
               -- 税抜基準単価
                lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 消費税金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
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
    --          ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                lt_tax_amount        := ROUND(lt_pure_amount * ( ln_tax_data - 1 ));
    --            ln_amount            := lt_pure_amount * ( ln_tax_data - 1 );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
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
                lt_stand_unit_price_excl :=  ROUND( ( (lt_lin_wholesale_unit_ploce /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 本体金額
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
    ----          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
    ----            IF ( lt_tax_odd = cv_amount_up ) THEN
    ----              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
    ----            -- 切捨て
    ----            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----              lt_pure_amount := TRUNC( lt_pure_amount );
    ----            -- 四捨五入
    ----            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----              lt_pure_amount := ROUND( lt_pure_amount );
    ----            END IF;
    ----          END IF;
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
    --              lt_pure_amount   := ln_amount;
    --            END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --            -- 消費税金額
    --            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
    --                                         - lt_pure_amount );
                -- 消費税金額
                ln_amount           := ( ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) 
                                           /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
              END IF;
    --
              -- 非課税時以外
              IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
                -- 消費税合計積上げ
                  ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
                -- 明細最大消費税取得
                IF ( ABS( ln_max_tax_data ) < ABS( lt_tax_amount ) ) THEN
                  ln_max_tax_data := lt_tax_amount;
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --              ln_max_no_data  := gn_line_data_no;
                  ln_max_no_data  := ln_line_data_count;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
                END IF;
              END IF;
    --
              -- 明細最大行No確認
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
                IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
                  ln_max_invoice_num := lt_lin_line_no_hht;
                END IF;
              END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
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
              END IF;
            --====================
            --明細データの変数挿入
            --====================
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
    --        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- 納品明細番号
    --        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- 売上区分
    --        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- 品目コード
    --        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- 営業原価
    --        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- 現金・カード併用額
    --        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- Ｈ＆Ｃ
    --        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- コラムNo
    --        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- 売切区分
    --        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- 売切時間
    --        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算-IF済フラグ
    --        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF済フラグ
    --        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --        gn_line_data_no := gn_line_data_no + 1;
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
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
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
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- 納品形態区分(導出)
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
            ELSE
              gn_wae_data_count := gn_wae_data_count + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
            ln_line_no := ln_line_no + 1;
    --
          END LOOP line_loop;
    --
          -- =======================================
          -- 値引金額明細生成(A-8)
          -- =======================================
          -- 値引きが発生している場合
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --        -- ===================
    --        -- 登録用明細ID取得
    --        -- ===================
    --        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
    --        INTO   ln_sales_exp_line_id
    --        FROM   DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
            -- =================================
            -- 営業原価、基準単位を導出
            -- =================================
            BEGIN
              SELECT ic_item.attribute7,              -- 旧営業原価
                     ic_item.attribute8,              -- 新営業原価
                     ic_item.attribute9,              -- 営業原価適用開始日
                     mtl_item.primary_unit_of_measure -- 基準単位
              INTO   lt_old_sales_cost,
                     lt_new_sales_cost,
                     lt_st_sales_cost,
                     lt_stand_unit
              FROM   mtl_system_items_b    mtl_item,    -- 品目
                     ic_item_mst_b         ic_item,     -- OPM品目
                     xxcmm_system_items_b  cmm_item     -- Disc品目アドオン
              WHERE  mtl_item.organization_id   = gn_orga_id
              AND  mtl_item.segment1 = gv_disc_item
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
                lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
                lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
                lv_key_data1 := gv_disc_item;
                lv_key_data2 := gn_orga_id;
                RAISE no_data_extract;
            END;
            -- ===================================
            -- 営業原価判定
            -- ===================================
            IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
              lt_sales_cost := lt_old_sales_cost;
            ELSE
              lt_sales_cost := lt_new_sales_cost;
            END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
    --/*--==============2009/2/3-START=========================--*/
    ----        IF ( lv_depart_code = cv_depart_car ) THEN
    --        IF ( lv_depart_code IS NULL )
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
    --/*--==============2009/2/3-END==========================--*/
    ----
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name     -- 保管場所コード
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi    --保管場所マスタ
    --            WHERE  msi.attribute7 = lt_base_code
    --            AND    msi.attribute13 = lt_location_type_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力          
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --            --キー編集処理用変数
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_05;
    --          RAISE no_data_extract;
    --          END;
    --
    --/*--==============2009/2/3-START=========================--*/
    ----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
    ----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
    --        ELSIF ( lv_depart_code = cv_depart_type ) 
    --          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
    --/*--==============2009/2/3-END==========================--*/
    ----
    --          --保管場所マスタデータ取得
    --          BEGIN
    --            SELECT msi.secondary_inventory_name           -- 保管場所名称
    --            INTO   lt_secondary_inventory_name
    --            FROM   mtl_secondary_inventories msi,         -- 保管場所マスタ
    --                   mtl_parameters mp                      -- 組織パラメータ
    --            WHERE  msi.organization_id=mp.organization_id
    --            AND    mp.organization_code = gv_orga_code
    --            AND    msi.attribute4       = lt_keep_in_code
    --            AND    msi.attribute13      = lt_depart_location_type_code;
    --          EXCEPTION
    --            WHEN NO_DATA_FOUND THEN
    --              -- ログ出力
    --              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
    --              --キー編集処理用変数設定
    --            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
    --            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
    --            lv_key_data1 := lt_base_code;
    --            lv_key_data2 := cv_xxcos_001_a05_09;
    --          RAISE no_data_extract;
    --          END;
    --
    --        END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
              -- ================
              -- 金額算出処理
              -- ================
              IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- 非課税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_sale_discount_amount );
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_sale_discount_amount );
                -- 消費税金額
                lt_tax_amount            := cn_cons_tkn_zero;
    --
              ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_sale_amount           := lt_sale_discount_amount;
    --            ln_amount           := lt_sale_discount_amount;
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount := TRUNC( ln_amount );
    --             -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************

    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_sale_discount_amount );
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                -- 消費税金額
                lt_tax_amount        := ROUND( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- 内税（伝票課税）
    --
                -- 税抜基準単価
                lt_stand_unit_price_excl := lt_sale_discount_amount;
                -- 基準単価
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_standard_unit_price   := ( lt_sale_discount_amount * ln_tax_data );
    --          IF ( lt_standard_unit_price <> TRUNC( lt_standard_unit_price ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_standard_unit_price := ( TRUNC( lt_standard_unit_price ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_standard_unit_price := TRUNC( lt_standard_unit_price );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_standard_unit_price := ROUND( lt_standard_unit_price );
    --            END IF;
    --          END IF;
    --          ln_amount   := ( lt_sale_discount_amount * ln_tax_data );
    --          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_standard_unit_price := ( TRUNC( ln_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_standard_unit_price := TRUNC( ln_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_standard_unit_price := ROUND( ln_amount );
    --            END IF;
    --          END IF;
                lt_standard_unit_price := ( lt_sale_discount_amount );
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- 売上金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
    --          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
    --            IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
    --            -- 切捨て
    --            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --              lt_sale_amount := TRUNC( lt_sale_amount );
    --            -- 四捨五入
    --            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --              lt_sale_amount := ROUND( lt_sale_amount );
    --            END IF;
    --          END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_sale_amount           := lt_sale_discount_amount;
    --            ln_amount           := lt_sale_discount_amount;
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_sale_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 本体金額
                lt_pure_amount           := TRUNC( lt_sale_discount_amount );
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
                -- 消費税金額
                lt_tax_amount        := ROUND( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
    --            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --                IF ( SIGN (ln_amount) <> -1 ) THEN
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --                ELSE
    --                  lt_tax_amount := TRUNC( ln_amount ) - 1;
    --                END IF;
    ----                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    ----******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_tax_amount := TRUNC( ln_amount );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_tax_amount := ROUND( ln_amount );
    --              END IF;
    --            ELSE
    --              lt_tax_amount   := ln_amount;
    --            END IF;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
    --
              ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                -- 税抜基準単価
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                lt_stand_unit_price_excl :=  ROUND( ( (lt_sale_discount_amount /( 100 + lt_tax_consum ) ) * 100 ) , 2 );
    --            lt_stand_unit_price_excl := ( lt_sale_discount_amount / ln_tax_data );
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
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 基準単価
                lt_standard_unit_price   := lt_sale_discount_amount;
                -- 売上金額
                lt_sale_amount           := TRUNC( lt_sale_discount_amount );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --            -- 本体金額
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data);
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
    --            ln_amount           := ( lt_sale_discount_amount / ln_tax_data);
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
    --              lt_pure_amount   := ln_amount;
    --            END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- 消費税金額
    --            lt_tax_amount            := TRUNC( lt_sale_amount - lt_pure_amount );
                ln_amount           := ( ( lt_sale_discount_amount /  ( ln_tax_data * 100 ) )  * lt_tax_consum );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                    IF ( SIGN (ln_amount) <> -1 ) THEN
                      lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
                    ELSE
                      lt_tax_amount := TRUNC( ln_amount ) - 1;
                    END IF;
    --                  lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
                -- 本体金額
                lt_pure_amount := lt_sale_discount_amount - lt_tax_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
              END IF;
    --
              -- 値引用納品明細番号設定
              ln_max_invoice_num := ln_max_invoice_num + 1;
              -- 登録用値引金額設定
              lt_sale_amount := ( lt_sale_amount * ( -1 ) );
              lt_pure_amount := ( lt_pure_amount * ( -1 ) );
              lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
              -- 明細合計本体金額
              ln_line_pure_amount_sum  := ln_line_pure_amount_sum + lt_pure_amount;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END *****************************************
              -- 赤・黒の金額換算
              --黒の時
              IF ( lt_red_black_flag = cv_black_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := cn_disc_standard_qty;
                -- 売上金額
                lt_set_sale_amount := lt_sale_amount;
                -- 本体金額
                lt_set_pure_amount := lt_pure_amount;
                -- 消費税金額
                lt_set_tax_amount := lt_tax_amount;
              -- 赤の時
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
                -- 基準数量(納品数量)
                lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
                -- 売上金額
                lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
                -- 本体金額
                lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
                -- 消費税金額
                lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
              END IF;
              -- =========================================
              -- 値引き明細データセット
              -- =========================================
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
              ln_line_data_count := ln_line_data_count + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
    --          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
    --          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
    --          gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- 納品伝票番号
    --          gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- 納品明細番号
    --          gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- 売上区分
    --          gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- 赤黒フラグ
    --          gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- 品目コード
    --          gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- 基準数量
    --          gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- 基準単位
    --          gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- 基準単価
    --          gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- 営業原価
    --          gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- 売上金額
    --          gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- 本体金額
    --          gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- 消費税金額
    --          gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- 現金・カード併用額
    --          gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- 出荷元保管場所
    --          gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- 納品拠点コード
    --          gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- Ｈ＆Ｃ
    --          gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- コラムNo
    --          gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- 売切区分
    --          gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- 売切時間
    --          gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- 手数料計算IF済フラグ
    --          gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- 単価マスタ作成済フラグ
    --          gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INVインタフェース済フラグ
    --          gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- 注文明細番号(NULL設定)
    --          gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- 税抜基準単価
    --          gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- 納品形態区分
    --          gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- 納品数量
    --          gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- 納品単位
    --          gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- 納品単価
    --          gn_line_data_no := gn_line_data_no + 1;
              -- ===================
              -- 一時格納用
              -- ===================
              gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- 納品伝票番号
              gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- 納品明細番号
              gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- 売上区分
              gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- 赤黒フラグ
              gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- 品目コード
              gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- 納品数量
              gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- 基準数量
              gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- 納品単位
              gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- 基準単位
              gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- 納品単価
              gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- 基準単価
              gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- 営業原価
              gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- 売上金額
              gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- 本体金額
              gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- 消費税金額
              gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- 現金・カード併用額
              gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- 出荷元保管場所
              gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- 納品拠点コード
              gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- Ｈ＆Ｃ
              gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- コラムNo
              gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- 売切区分
              gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- 売切時間
              gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- 手数料計算インタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- 単価マスタ作成済フラグ
              gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INVインタフェース済フラグ
              gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- 注文明細番号(NULL設定)
              gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- 税抜基準単価
              gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- 納品形態区分(導出)
    --******************************* 2009/06/01 N.Maeda Var1.15 ADD START ***************************************
              gn_disc_count    := gn_disc_count + 1;                       -- 値引明細件数カウント
    --******************************* 2009/05/01 N.Maeda Var1.15 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --
          END IF;
    --
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
          IF ( lv_state_flg <> cv_status_warn ) THEN
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --
            -- ==================
            -- ヘッダ登録用金額算出
            -- ==================
            IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- 非課税
    --
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD START ***************************************
              -- 売上金額合計
              lt_sale_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
              -- 本体金額合計
              lt_pure_amount_sum := lt_total_amount - NVL(lt_sale_discount_amount,0);
              -- 消費税金額合計
              lt_tax_amount_sum  := lt_sales_consumption_tax;
    --          -- 売上金額合計
    --          lt_sale_amount_sum := lt_total_amount;
    --          -- 本体金額合計
    --          lt_pure_amount_sum := lt_total_amount;
    --          -- 消費税金額合計
    --          lt_tax_amount_sum  := lt_sales_consumption_tax;
    --******************************* 2009/06/01 N.Maeda Var1.16 MOD END   ***************************************
            ELSE
             --値引発生時
              IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                  -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_tax_include * ln_tax_data );
    --              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --                END IF;
    --              END IF;
                  ln_amount := lt_tax_include;
                    IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                      IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                        IF ( SIGN (ln_amount) <> -1 ) THEN
                          lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                        ELSE
                          lt_sale_amount_sum := TRUNC( ln_amount ) - 1;
                        END IF;
    --                    lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                      -- 切捨て
                      ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                        lt_sale_amount_sum := TRUNC( ln_amount );
                      -- 四捨五入
                      ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                        lt_sale_amount_sum := ROUND( ln_amount );
                      END IF;
                    ELSE
                      lt_sale_amount_sum := ln_amount;
                    END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                    -- 本体金額合計
                    lt_pure_amount_sum := lt_tax_include;
                    -- 消費税金額合計
                    ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                    IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                      IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                        IF ( SIGN (ln_amount) <> -1 ) THEN
                          lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                        ELSE
                          lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                        END IF;
    --                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --************************** 2009/05/18 1.15 N.Maeda MOD START ************************************
                  -- 売上金額合計
    --              lt_sale_amount_sum := lt_tax_include;
                  lt_sale_amount_sum := lt_tax_include - lt_sales_consumption_tax;
    --************************** 2009/05/18 1.15 N.Maeda MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                  -- 消費税金額合計
                  lt_tax_amount_sum  := lt_sales_consumption_tax;
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
                  -- 本体金額合計
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_tax_include / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_tax_include / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum:= ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 値引消費税算出
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            ln_discount_tax    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
    --            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                ln_discount_tax := TRUNC( ln_discount_tax );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                 ln_discount_tax:= ROUND( ln_discount_tax );
    --              END IF;
    --            END IF;
                  ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        ln_discount_tax := TRUNC( ln_amount ) - 1;
                      END IF;
    --                  ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      ln_discount_tax := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      ln_discount_tax := ROUND( ln_amount );
                    END IF;
                  ELSE
                    ln_discount_tax   := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 消費税金額合計
                  lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
                  -- 本体金額合計
                  lt_pure_amount_sum := ln_line_pure_amount_sum;
                  -- 売上金額合計
                  lt_sale_amount_sum := lt_pure_amount_sum + lt_tax_amount_sum;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
    --
                END IF;
              --値引未発生時金額算出
              ELSE
    --
                IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- 外税
    --
                  -- 売上金額合計
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
                  ln_amount := lt_total_amount;
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        lt_sale_amount_sum := TRUNC( ln_amount ) - 1;
                      END IF;
    --                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      lt_sale_amount_sum := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      lt_sale_amount_sum := ROUND( ln_amount );
                    END IF;
                  ELSE
                    lt_sale_amount_sum   := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
                  ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        lt_tax_amount_sum := TRUNC( ln_amount ) - 1;
                      END IF;
    --                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
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
    --************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    --            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
    --            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
    --              IF ( lt_tax_odd = cv_amount_up ) THEN
    --              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
    --              -- 切捨て
    --              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
    --              -- 四捨五入
    --              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
    --              END IF;
    --            END IF;
    --************************** 2009/05/18 1.15 N.Maeda MOD START ************************************
    --              ln_amount := ( lt_total_amount * ln_tax_data );
                  ln_amount := lt_total_amount;
    --************************** 2009/05/18 1.15 N.Maeda MOD  END  ************************************
                  IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                    IF ( lt_tax_odd = cv_amount_up ) THEN
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
                      IF ( SIGN (ln_amount) <> -1 ) THEN
                        lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                      ELSE
                        lt_sale_amount_sum := TRUNC( ln_amount ) - 1 ;
                      END IF;
    --                    lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                    -- 切捨て
                    ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                      lt_sale_amount_sum := TRUNC( ln_amount );
                    -- 四捨五入
                    ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                      lt_sale_amount_sum := ROUND( ln_amount );
                    END IF;
                  ELSE
                    lt_sale_amount_sum   := ln_amount;
                  END IF;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                  -- 本体金額合計
                  lt_pure_amount_sum := lt_total_amount;
                  -- 消費税金額合計
    --************************** 2009/05/18 1.15 N.Maeda MOD START ************************************
    --              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
                  lt_tax_amount_sum  := lt_sales_consumption_tax;
    --************************** 2009/05/18 1.15 N.Maeda MOD  END  ************************************
    --
                ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- 内税（単価込み）
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --              -- 売上金額合計
    --              lt_sale_amount_sum := lt_total_amount;
    --              -- 本体金額合計
    ----************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
    ----            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
    ----            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
    ----              IF ( lt_tax_odd = cv_amount_up ) THEN
    ----                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
    ----              -- 切捨て
    ----              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    ----                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
    ----              -- 四捨五入
    ----              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    ----                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
    ----              END IF;
    ----            END IF;
    --              ln_amount := ( lt_total_amount / ln_tax_data );
    --              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
    --                IF ( lt_tax_odd = cv_amount_up ) THEN
    --                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
    --                -- 切捨て
    --                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
    --                  lt_pure_amount_sum := TRUNC( ln_amount );
    --                -- 四捨五入
    --                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
    --                  lt_pure_amount_sum := ROUND( ln_amount );
    --                END IF;
    --              ELSE
    --                lt_pure_amount_sum   := ln_amount;
    --              END IF;
                lt_pure_amount_sum := ln_line_pure_amount_sum;
                -- 売上金額合計
                lt_sale_amount_sum := ln_line_pure_amount_sum + ln_all_tax_amount;
    --************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
                -- 消費税金額合計
                lt_tax_amount_sum  := ln_all_tax_amount;
    --
                END IF;
              END IF;
            END IF;
    --
            --非課税以外の時
            IF (lt_consumption_tax_class <> cv_non_tax) THEN
              -- ================================================
              -- ヘッダ売上消費税額と明細売上消費税額比較判断処理
              -- ================================================
    --          -- 値引明細がnull以外の時
              IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
              AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
                ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
              END IF;
              IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
                -- 外税 OR 内税(伝票課税の時)
                IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
                  IF ( lt_red_black_flag = cv_black_flag) THEN
    --                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                  ELSIF ( lt_red_black_flag = cv_red_flag) THEN
    --                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
    --                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                    gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                  END IF;
    --******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
                END IF;
              END IF;
            END IF;
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
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
            BEGIN
              SELECT  dhs.cancel_correct_class
              INTO    lt_max_cancel_correct_class
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE   dhs.order_no_hht = dls.order_no_hht
--              AND     dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE   dhs.order_no_hht = dls.order_no_hht(+)
              AND     dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND     dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND     dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
              AND     dhs.results_forward_flag = cv_untreated_flg
              AND     dhs.order_no_ebs = cn_tkn_zero 
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND     dhs.program_application_id IS NOT NULL
--              AND     dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND     dhs.order_no_hht        = lt_order_no_hht
              AND     dhs.digestion_ln_number = ( SELECT  MAX( dhs.digestion_ln_number)
                                                  FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                                                          xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--                                                  WHERE   dhs.order_no_hht = dls.order_no_hht
--                                                  AND     dhs.digestion_ln_number = dls.digestion_ln_number
                                                  WHERE   dhs.order_no_hht = dls.order_no_hht(+)
                                                  AND     dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
                                                  AND     dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
                                                  AND     dhs.input_class
                                                            NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
                                                  AND     dhs.results_forward_flag = cv_untreated_flg
                                                  AND     dhs.order_no_ebs = cn_tkn_zero 
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--                                                  AND     dhs.program_application_id IS NOT NULL
--                                                  AND     dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
                                                  AND     dhs.order_no_hht        = lt_order_no_hht )
              GROUP BY dhs.cancel_correct_class;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
    --
            BEGIN
              SELECT  MIN(dhs.digestion_ln_number)
              INTO    lt_min_digestion_ln_number
              FROM    xxcos_dlv_headers dhs,            -- 納品ヘッダ
                      xxcos_dlv_lines dls
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--              WHERE   dhs.order_no_hht = dls.order_no_hht
--              AND     dhs.digestion_ln_number = dls.digestion_ln_number
              WHERE   dhs.order_no_hht = dls.order_no_hht(+)
              AND     dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
              AND     dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
              AND     dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
              AND     dhs.results_forward_flag = cv_untreated_flg
              AND     dhs.order_no_ebs = cn_tkn_zero 
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--              AND     dhs.program_application_id IS NOT NULL
--              AND     dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
              AND     dhs.order_no_hht        = lt_order_no_hht;
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
                  lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
                  RAISE;
              END;
    --
              IF ( ln_sales_exp_count <> 0 ) THEN
                <<sales_exp_update_loop>>
                FOR u in 1..ln_sales_exp_count LOOP
                  gn_set_sales_exp_count := gn_set_sales_exp_count + 1;
                  gt_set_sales_head_row_id( gn_set_sales_exp_count )   := gt_sales_head_row_id(u);
                  gt_set_head_cancel_cor_cls( gn_set_sales_exp_count ) := lt_max_cancel_correct_class;
                END LOOP sales_exp_update_loop;
              END IF;
            END IF;
    --
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            --================================
            --販売実績ヘッダID(シーケンス取得)
            --================================
            SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
            INTO ln_actual_id
            FROM DUAL;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    --
            --==========================
            -- ヘッダデータの変数挿入
            --==========================
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
            gt_head_id( gn_head_data_no )                      := ln_actual_id;                 -- 販売実績ヘッダID
            gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;              -- 受注番号
            gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;            -- 納品伝票番号
            gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;              -- 受注No(HHT)
            gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;       -- 枝番(受注No(HHT)枝番)
            gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;          -- 納品伝票区分(導出)
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
    --        gt_head_cancel_cor_cls( gn_head_data_no )        := lt_cancel_correct_class;      -- 取消・訂正区分
            gt_head_cancel_cor_cls( gn_head_data_no )          := lt_max_cancel_correct_class;  --  取消・訂正区分
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END   ***************************************
            gt_head_system_class( gn_head_data_no )            := lt_system_class;              -- 業態区分(業態小分類)
            gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                  -- オリジナル納品日
            gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;              -- オリジナル検収日(売上計上日)
            gt_head_customer_number( gn_head_data_no )         := lt_customer_number;           -- 顧客【納品先
            gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;       -- 売上金額合計
            gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;       -- 本体金額合計
            gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;        -- 消費税金額合計(半導出)
            gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;               -- 消費税区分(導出)
            gt_head_tax_code( gn_head_data_no )                := lt_consum_code;               -- 税金コード(導出)
            gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;                -- 消費税率(導出)
            gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;       -- 成績計上者コード
            gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;            -- 売上拠点コード(導出)
            gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;           -- カード売り区分
    --      gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;      -- 伝票区分
    --      gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;             -- 伝票分類コード
            gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;             -- 伝票区分
            gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;      -- 伝票分類コード
    -- ************** 2009/04/16 1.12 N.Maeda MO START ****************************************************************
    --      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- 入金拠点コード(導出)
            gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- 入金拠点コード(導出)
    -- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
            gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;       -- つり銭切れ時間100円
            gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;        -- つり銭切れ時間10円
            gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;                -- HHT納品入力日時(成型日時)
            gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;               -- 納品者コード
            gt_head_business_date( gn_head_data_no )           := gd_process_date;              -- 登録業務日付(初期処理取得)
            gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                  -- 受注ソースID(NULL設定)
            gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                  -- 注文伝票番号(NULL設定)
            gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                  -- 受注関連番号(NULL設定)
            gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- AR-IF済フラグ('N')
            gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- GL-IF済フラグ('N')
            gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- 情報システムIF済フラグ('N')
            gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- EDI送信済みフラグ('N'設定)
            gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                  -- EDI送信日時(NULL設定)
    -- ************** 2009/04/16 1.12 N.Maeda MO START ****************************************************************
    --        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;          -- 作成元区分(｢4｣設定)
            gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;          -- 作成元区分(｢4｣設定)
    -- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
            gt_head_input_class( gn_head_data_no )             := lt_input_class;               -- 入力区分
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
--            gt_head_open_dlv_date( gn_head_data_no )           := lt_dlv_date;
--            gt_head_open_inspect_date( gn_head_data_no )       := lt_inspect_date;
            gt_head_open_dlv_date( gn_head_data_no )           := lt_open_dlv_date;
            gt_head_open_inspect_date( gn_head_data_no )       := lt_open_inspect_date;
    --******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
            gn_head_data_no := gn_head_data_no + 1;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
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
              gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- 販売実績明細ID
              gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- 販売実績ヘッダID
              gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- 納品伝票番号
              gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- 納品明細番号
              gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- 売上区分
              gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- 赤黒フラグ
              gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- 品目コード
              gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- 基準数量
              gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- 基準単位
              gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- 基準単価
              gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- 営業原価
              gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- 売上金額
              gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- 本体金額
              gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- 消費税金額
              gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- 現金・カード併用額
              gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- 出荷元保管場所
              gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- 納品拠点コード
              gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- Ｈ＆Ｃ
              gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- コラムNo
              gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- 売切区分
              gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- 売切時間
              gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- 手数料計算IF済フラグ
              gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;  -- 単価マスタ作成済フラグ
              gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;-- INVインタフェース済フラグ
              gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- 注文明細番号
              gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- 税抜基準単価
              gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- 納品形態区分
              gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- 納品数量
              gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- 納品単位
              gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- 納品単価
              gn_line_data_no := gn_line_data_no + 1;
            END LOOP line_set_loop;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          ELSE
            gn_wae_data_count := gn_wae_data_count + ln_line_data_count;
            gn_warn_cnt       := gn_warn_cnt + 1;
    --******************************* 2009/05/18 N.Maeda Var1.15 MOD END *****************************************
          END IF;
    --******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
----******************************* 2009/06/23 N.Maeda Var1.17 ADD START ***************************************
        ELSE
          gn_warn_cnt := gn_warn_cnt + 1 ;
        END IF;
--
      EXCEPTION
        WHEN lock_err_expt THEN
          IF( get_lines_cur%ISOPEN ) THEN
            CLOSE get_lines_cur;
          END IF;
          IF( get_lock_cur%ISOPEN ) THEN
            CLOSE get_lock_cur;
          END IF;
          lt_order_no_hht_err := lt_order_no_hht;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gn_warn_cnt     := gn_warn_cnt + 1;
--
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --アプリケーション短縮名
                                                iv_name          => cv_data_loc,    --メッセージコード
                                                iv_token_name1   => cv_tkn_order_number,       --トークンコード2
                                                iv_token_value1  => lt_order_no_hht,
                                                iv_token_name2   => cv_invoice_no,
                                                iv_token_value2  => lt_hht_invoice_no);
      END;
--******************************* 2009/06/23 N.Maeda Var1.17 ADD END   ***************************************
--
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --キー編集関数
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, lv_key_data1, lv_key_name2, lv_key_data2,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         gv_tkn2, lv_errbuf, lv_retcode, lv_errmsg);  
      --メッセージ生成
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 # 
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# 任意 #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_hht;
--
  /**********************************************************************************
   * Procedure Name   : proc_extract
   * Description      : 対象データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE proc_extract(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_extract'; -- プログラム名
    --
    -- ===============================
    -- ユーザー定義変数
    -- ===============================
    lv_no_data_msg VARCHAR2(5000);
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
    -- 納品ヘッダ(HHT)
    CURSOR dlv_head_hht_cur
    IS
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
      SELECT 
-- ****************** 2009/08/10 1.18 N.Maeda ADD START **************************************************************--
             /*+
               index ( DHS XXCOS_DLV_HEADERS_N04 )
               index ( DLS XXCOS_DLV_LINES_PK )
             */
-- ****************** 2009/08/10 1.18 N.Maeda ADD  END  **************************************************************--
             DISTINCT
             dhs.ROWID                      -- 行ID
             ,dhs.order_no_hht              -- 受注No.(HHT)
             ,dhs.digestion_ln_number       -- 枝番
             ,dhs.hht_invoice_no            -- HHT伝票No.
      FROM   xxcos_dlv_headers dhs            -- 納品ヘッダ
             ,xxcos_dlv_lines dls             -- 納品明細
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      WHERE  dhs.order_no_hht = dls.order_no_hht(+)
      AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs = cn_tkn_zero 
      AND    dhs.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--      AND    dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
--      GROUP BY dhs.ROWID                      -- 行ID
--              ,dhs.order_no_hht              -- 受注No.(HHT)
--              ,dhs.digestion_ln_number       -- 枝番
--              ,dhs.hht_invoice_no            -- HHT伝票No.
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--
--      SELECT dhs.ROWID,                    -- 行ID
--             dhs.order_no_hht,             -- 受注No.(HHT)
--             dhs.digestion_ln_number,      -- 枝番
--             dhs.order_no_ebs,             -- 受注No.（EBS）
--             dhs.base_code,                -- 拠点コード
--             dhs.performance_by_code,      -- 成績者コード
--             dhs.dlv_by_code,              -- 納品者コード
--             dhs.hht_invoice_no,           -- HHT伝票No.
--             dhs.dlv_date,                 -- 納品日
--             dhs.inspect_date,             -- 検収日
--             dhs.sales_classification,     -- 売上分類区分
--             dhs.sales_invoice,            -- 売上伝票区分
--             dhs.card_sale_class,          -- カード売り区分
--             dhs.dlv_time,                 -- 時間
--             dhs.customer_number,          -- 顧客コード
--             dhs.change_out_time_100,      -- つり銭切れ時間100円
--             dhs.change_out_time_10,       -- つり銭切れ時間10円
--             dhs.system_class,             -- 業態区分
--             dhs.input_class,              -- 入力区分
--             dhs.consumption_tax_class,    -- 消費税区分
--             dhs.total_amount,             -- 合計金額
--             dhs.sale_discount_amount,     -- 売上値引額
--             dhs.sales_consumption_tax,    -- 売上消費税額
--             dhs.tax_include,              -- 税込金額
--             dhs.keep_in_code,             -- 預け先コード
--             dhs.department_screen_class,  -- 百貨店画面種別
--             dhs.red_black_flag,           -- 赤・黒フラグ
--             dhs.stock_forward_flag,       -- 入出庫転送フラグ
--             dhs.stock_forward_date,       -- 入出庫転送済日付
--             dhs.results_forward_flag,     -- 販売実績連携済フラグ
--             dhs.results_forward_date,     -- 販売実績連携済日付
--             dhs.cancel_correct_class      -- 取消・訂正区分
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,
--             xxcos_dlv_lines dls
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.order_no_ebs = cn_tkn_zero 
--      AND    dhs.program_application_id IS NOT NULL
--      AND    dls.program_application_id  IS NOT NULL
--      GROUP BY dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
--                      dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
--                      dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
--                      dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
--                      dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
--                      dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,dhs.tax_include,
--                      dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,dhs.stock_forward_flag,
--                      dhs.stock_forward_date,dhs.results_forward_flag,dhs.results_forward_date,dhs.cancel_correct_class
----      FROM   xxcos_dlv_headers dhs           --納品ヘッダ
----      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
----                                  FROM   xxcos_dlv_lines dls              --納品明細
----                                  WHERE  dls.program_application_id IS NOT NULL )
----      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
----                                         FROM   xxcos_dlv_lines dls              --納品明細
----                                         WHERE  dls.program_application_id IS NOT NULL )
----      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
----      AND    dhs.results_forward_flag = cn_tkn_zero
------      AND    dhs.order_no_ebs IS NULL 
----      AND    dhs.order_no_ebs = cn_tkn_zero 
----      AND    dhs.program_application_id IS NOT NULL --通常データ
--      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
----    FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 MOD END   ***************************************
--
----******************************* 2009/06/23 N.Maeda Var1.17 DEL START ***************************************
--    --納品明細(HHT)
--    CURSOR dlv_line_hht_cur
--    IS
--      SELECT dls.order_no_hht,          -- 受注No.（HHT）
--             dls.line_no_hht,           -- 行No.（HHT）
--             dls.digestion_ln_number,   -- 枝番
--             dls.order_no_ebs,          -- 受注No.（EBS）
--             dls.line_number_ebs,       -- 明細番号（EBS）
--             dls.item_code_self,        -- 品名コード（自社）
--             dls.content,               -- 入数
--             dls.inventory_item_id,     -- 品目ID
--             dls.standard_unit,         -- 基準単位
--             dls.case_number,           -- ケース数
--             dls.quantity,              -- 数量
--             dls.sale_class,            -- 売上区分
--             dls.wholesale_unit_ploce,  -- 卸単価
--             dls.selling_price,         -- 売単価
--             dls.column_no,             -- コラムNo.
--             dls.h_and_c,               -- H/C
--             dls.sold_out_class,        -- 売切区分
--             dls.sold_out_time,         -- 売切時間
--             dls.replenish_number,      -- 補充数
--             dls.cash_and_card          -- 現金・カード併用額
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,
--             xxcos_dlv_lines dls
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.order_no_ebs = cn_tkn_zero
--      AND    dhs.program_application_id IS NOT NULL
--      AND    dls.program_application_id  IS NOT NULL
----      FROM   xxcos_dlv_lines dls           -- 納品明細
----      WHERE  dls.order_no_hht IN ( SELECT  dhs.order_no_hht
----                                   FROM    xxcos_dlv_headers dhs
----                                   WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----                                   AND    dhs.input_class  
----                                            NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
----                                   AND    dhs.results_forward_flag = cn_tkn_zero
----                                   --AND    dhs.order_no_ebs IS NULL 
----                                   AND    dhs.order_no_ebs = cn_tkn_zero
----                                   AND    dhs.program_application_id IS NOT NULL)
----      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
----                                          FROM    xxcos_dlv_headers dhs
----                                          WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----                                          AND    dhs.input_class  
----                                                   NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
----                                          AND    dhs.results_forward_flag = cn_tkn_zero
----                                          --AND    dhs.order_no_ebs IS NULL
----                                          AND    dhs.order_no_ebs = cn_tkn_zero
----                                          AND    dhs.program_application_id IS NOT NULL)
----      AND    dls.program_application_id IS NOT NULL --通常データ
--      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
--    FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 DEL END   ***************************************
--
    -- 納品ヘッダ(受注画面入力データ)
    CURSOR dlv_inp_head_hht_cur
    IS
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
      SELECT
-- ****************** 2009/08/10 1.18 N.Maeda ADD START **************************************************************--
             /*+
               index ( dhs XXCOS_DLV_HEADERS_N02 )
               index ( dls XXCOS_DLV_LINES_PK )
             */
-- ****************** 2009/08/10 1.18 N.Maeda ADD  END  **************************************************************--
             DISTINCT
             dhs.ROWID                       -- 行ID
             ,dhs.order_no_hht               -- 受注No.(HHT)
             ,dhs.digestion_ln_number        -- 枝番
             ,dhs.hht_invoice_no             -- HHT伝票No.
      FROM   xxcos_dlv_headers dhs,           --納品ヘッダ
             xxcos_dlv_lines dls              --納品明細
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      WHERE  dhs.order_no_hht = dls.order_no_hht(+)
      AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
          AND ( dhs.input_class  = cv_input_delivery ) ) )
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.program_application_id IS NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--      AND    dls.program_application_id IS NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
--      GROUP BY dhs.ROWID                       -- 行ID
--              ,dhs.order_no_hht               -- 受注No.(HHT)
--              ,dhs.digestion_ln_number        -- 枝番
--              ,dhs.hht_invoice_no             -- HHT伝票No.
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--      SELECT dhs.ROWID,                    -- 行ID
--             dhs.order_no_hht,             -- 受注No.(HHT)
--             dhs.digestion_ln_number,      -- 枝番
--             dhs.order_no_ebs,             -- 受注No.（EBS）
--             dhs.base_code,                -- 拠点コード
--             dhs.performance_by_code,      -- 成績者コード
--             dhs.dlv_by_code,              -- 納品者コード
--             dhs.hht_invoice_no,           -- HHT伝票No.
--             dhs.dlv_date,                 -- 納品日
--             dhs.inspect_date,             -- 検収日
--             dhs.sales_classification,     -- 売上分類区分
--             dhs.sales_invoice,            -- 売上伝票区分
--             dhs.card_sale_class,          -- カード売り区分
--             dhs.dlv_time,                 -- 時間
--             dhs.customer_number,          -- 顧客コード
--             dhs.change_out_time_100,      -- つり銭切れ時間100円
--             dhs.change_out_time_10,       -- つり銭切れ時間10円
--             dhs.system_class,             -- 業態区分
--             dhs.input_class,              -- 入力区分
--             dhs.consumption_tax_class,    -- 消費税区分
--             dhs.total_amount,             -- 合計金額
--             dhs.sale_discount_amount,     -- 売上値引額
--             dhs.sales_consumption_tax,    -- 売上消費税額
--             dhs.tax_include,              -- 税込金額
--             dhs.keep_in_code,             -- 預け先コード
--             dhs.department_screen_class,  -- 百貨店画面種別
--             dhs.red_black_flag,           -- 赤・黒フラグ
--             dhs.stock_forward_flag,       -- 入出庫転送フラグ
--             dhs.stock_forward_date,       -- 入出庫転送済日付
--             dhs.results_forward_flag,     -- 販売実績連携済フラグ
--             dhs.results_forward_date,     -- 販売実績連携済日付
--             dhs.cancel_correct_class      -- 取消・訂正区分
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,           --納品ヘッダ
--             xxcos_dlv_lines dls              --納品明細
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
--          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
--        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
--          AND ( dhs.input_class  = cv_input_delivery ) ) )
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.program_application_id IS NULL
--      AND    dls.program_application_id IS NULL
--      GROUP BY  dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
--                dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
--                dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
--                dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
--                dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
--                dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,dhs.tax_include,
--                dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,dhs.stock_forward_flag,
--                dhs.stock_forward_date,dhs.results_forward_flag,dhs.results_forward_date,dhs.cancel_correct_class
----      FROM   xxcos_dlv_headers dhs           --納品ヘッダ
----      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
----                                  FROM   xxcos_dlv_lines dls              --納品明細
----                                  WHERE  dls.program_application_id IS NULL )
----      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
----                                         FROM   xxcos_dlv_lines dls              --納品明細
----                                         WHERE  dls.program_application_id IS NULL )
------ ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
------      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
------      AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
------          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
------        OR ( ( dhs.order_no_ebs <> cn_tkn_zero ) 
------          AND ( dhs.input_class  = cv_input_delivery ) ) )
----      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
----          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
----          AND ( dhs.input_class  = cv_input_delivery ) ) )
------ ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
----      AND    dhs.results_forward_flag = cn_tkn_zero
----      AND    dhs.program_application_id IS NULL --通常データ
--      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
----    FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 MOD END   ***************************************
--
----******************************* 2009/06/23 N.Maeda Var1.17 DEL START ***************************************
--    --納品明細(受注画面入力データ)
--    CURSOR dlv_inp_line_hht_cur
--    IS
--      SELECT dls.order_no_hht,          -- 受注No.（HHT）
--             dls.line_no_hht,           -- 行No.（HHT）
--             dls.digestion_ln_number,   -- 枝番
--             dls.order_no_ebs,          -- 受注No.（EBS）
--             dls.line_number_ebs,       -- 明細番号（EBS）
--             dls.item_code_self,        -- 品名コード（自社）
--             dls.content,               -- 入数
--             dls.inventory_item_id,     -- 品目ID
--             dls.standard_unit,         -- 基準単位
--             dls.case_number,           -- ケース数
--             dls.quantity,              -- 数量
--             dls.sale_class,            -- 売上区分
--             dls.wholesale_unit_ploce,  -- 卸単価
--             dls.selling_price,         -- 売単価
--             dls.column_no,             -- コラムNo.
--             dls.h_and_c,               -- H/C
--             dls.sold_out_class,        -- 売切区分
--             dls.sold_out_time,         -- 売切時間
--             dls.replenish_number,      -- 補充数
--             dls.cash_and_card          -- 現金・カード併用額
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,     --納品ヘッダ
--             xxcos_dlv_lines dls        -- 納品明細
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
--          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
--        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
--          AND ( dhs.input_class  = cv_input_delivery ) ) )
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.program_application_id IS NULL
--      AND    dls.program_application_id IS NULL
----      FROM   xxcos_dlv_lines dls           -- 納品明細
----      WHERE  dls.order_no_hht IN ( SELECT  dhs.order_no_hht
----                                   FROM    xxcos_dlv_headers dhs
----                                   WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
------ ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
------                                   AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
------                                       AND dhs.input_class  
------                                             NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
------                                     OR ( ( dhs.order_no_ebs <> cn_tkn_zero )
------                                       AND ( dhs.input_class  = cv_input_delivery ) ) ) 
----                                   AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
----                                       AND dhs.input_class  
----                                             NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----                                     OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero )
----                                       AND ( dhs.input_class  = cv_input_delivery ) ) ) 
---- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
----                                   AND    dhs.program_application_id IS NULL
----                                   AND    dhs.results_forward_flag = cn_tkn_zero )
----      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
----                                          FROM    xxcos_dlv_headers dhs
----                                          WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
------ ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
------                                          AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
------                                              AND dhs.input_class  
------                                                  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
------                                            OR ( ( dhs.order_no_ebs <> cn_tkn_zero )
------                                              AND ( dhs.input_class  = cv_input_delivery ) ) )
----                                          AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
----                                              AND dhs.input_class  
----                                                  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----                                            OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero )
----                                              AND ( dhs.input_class  = cv_input_delivery ) ) )
------ ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
----                                              AND    dhs.program_application_id IS NULL 
----                                              AND    dhs.results_forward_flag = cn_tkn_zero )
----      AND    dls.program_application_id IS NULL --受注画面入力データ
--      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
--    FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 DEL END   ***************************************
--
    -- 納品ヘッダ(EDI)
    CURSOR dlv_head_edi_cur
    IS
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START ***************************************
      SELECT 
-- ****************** 2009/08/10 1.18 N.Maeda ADD START **************************************************************--
             /*+
               index ( dhs XXCOS_DLV_HEADERS_N02 )
               index ( dls XXCOS_DLV_LINES_PK )
             */
-- ****************** 2009/08/10 1.18 N.Maeda ADD  END  **************************************************************--
             DISTINCT
             dhs.ROWID                     -- 行ID
             ,dhs.order_no_hht             -- 受注No.(HHT)
             ,dhs.digestion_ln_number      -- 枝番
             ,dhs.hht_invoice_no           -- HHT伝票No.
      FROM   xxcos_dlv_headers dhs,           --納品ヘッダ
             xxcos_dlv_lines dls              -- 納品明細
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD START ***************************************
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      WHERE  dhs.order_no_hht = dls.order_no_hht(+)
      AND    dhs.digestion_ln_number = dls.digestion_ln_number(+)
--******************************* 2009/12/08 M.Fujinuma Var1.24 MOD END ***************************************
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  = cv_input_delivery
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs <> cn_tkn_zero
      AND    dhs.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL START ***************************************
--      AND    dls.program_application_id IS NOT NULL
--******************************* 2009/12/08 M.Fujinuma Var1.24 DEL END ***************************************
--      GROUP BY dhs.ROWID                     -- 行ID
--              ,dhs.order_no_hht             -- 受注No.(HHT)
--              ,dhs.digestion_ln_number      -- 枝番
--              ,dhs.hht_invoice_no           -- HHT伝票No.
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--      SELECT dhs.ROWID,                    -- 行ID
--             dhs.order_no_hht,             -- 受注No.(HHT)
--             dhs.digestion_ln_number,      -- 枝番
--             dhs.order_no_ebs,             -- 受注No.（EBS）
--             dhs.base_code,                -- 拠点コード
--             dhs.performance_by_code,      -- 成績者コード
--             dhs.dlv_by_code,              -- 納品者コード
--             dhs.hht_invoice_no,           -- HHT伝票No.
--             dhs.dlv_date,                 -- 納品日
--             dhs.inspect_date,             -- 検収日
--             dhs.sales_classification,     -- 売上分類区分
--             dhs.sales_invoice,            -- 売上伝票区分
--             dhs.card_sale_class,          -- カード売り区分
--             dhs.dlv_time,                 -- 時間
--             dhs.customer_number,          -- 顧客コード
--             dhs.change_out_time_100,      -- つり銭切れ時間100円
--             dhs.change_out_time_10,       -- つり銭切れ時間10円
--             dhs.system_class,             -- 業態区分
--             dhs.input_class,              -- 入力区分
--             dhs.consumption_tax_class,    -- 消費税区分
--             dhs.total_amount,             -- 合計金額
--             dhs.sale_discount_amount,     -- 売上値引額
--             dhs.sales_consumption_tax,    -- 売上消費税額
--             dhs.tax_include,              -- 税込金額
--             dhs.keep_in_code,             -- 預け先コード
--             dhs.department_screen_class,  -- 百貨店画面種別
--             dhs.red_black_flag,           -- 赤・黒フラグ
--             dhs.stock_forward_flag,       -- 入出庫転送フラグ
--             dhs.stock_forward_date,       -- 入出庫転送済日付
--             dhs.results_forward_flag,     -- 販売実績連携済フラグ
--             dhs.results_forward_date,     -- 販売実績連携済日付
--             dhs.cancel_correct_class      -- 取消・訂正区分
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,           --納品ヘッダ
--             xxcos_dlv_lines dls              -- 納品明細
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  = cv_input_delivery
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.order_no_ebs <> cn_tkn_zero
--      AND    dhs.program_application_id IS NOT NULL
--      AND    dls.program_application_id IS NOT NULL
----      GROUP BY dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
----               dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
----               dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
----               dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
----               dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
----               dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,
----               dhs.tax_include,dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,
----               dhs.stock_forward_flag,dhs.stock_forward_date,dhs.results_forward_flag,
----               dhs.results_forward_date,dhs.cancel_correct_class
------      FROM   xxcos_dlv_headers dhs           --納品ヘッダ
------      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
------                                  FROM   xxcos_dlv_lines dls              --納品明細
------                                  WHERE   dls.program_application_id IS NOT NULL )
------      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
------                                         FROM   xxcos_dlv_lines dls              --納品明細
------                                         WHERE  dls.program_application_id IS NOT NULL )
------      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
------      AND    dhs.input_class  = cv_input_delivery
------      AND    dhs.results_forward_flag = cn_tkn_zero
------      AND    dhs.order_no_ebs <> cn_tkn_zero
------      AND    dhs.program_application_id IS NOT NULL
----      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
------    FOR UPDATE NOWAIT;
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 MOD END   ***************************************
--
----******************************* 2009/06/23 N.Maeda Var1.17 DEL START ***************************************
--    --納品明細(EDI)
--    CURSOR dlv_line_edi_cur
--    IS
--      SELECT dls.order_no_hht,          -- 受注No.（HHT）
--             dls.line_no_hht,           -- 行No.（HHT）
--             dls.digestion_ln_number,   -- 枝番
--             dls.order_no_ebs,          -- 受注No.（EBS）
--             dls.line_number_ebs,       -- 明細番号（EBS）
--             dls.item_code_self,        -- 品名コード（自社）
--             dls.content,               -- 入数
--             dls.inventory_item_id,     -- 品目ID
--             dls.standard_unit,         -- 基準単位
--             dls.case_number,           -- ケース数
--             dls.quantity,              -- 数量
--             dls.sale_class,            -- 売上区分
--             dls.wholesale_unit_ploce,  -- 卸単価
--             dls.selling_price,         -- 売単価
--             dls.column_no,             -- コラムNo.
--             dls.h_and_c,               -- H/C
--             dls.sold_out_class,        -- 売切区分
--             dls.sold_out_time,         -- 売切時間
--             dls.replenish_number,      -- 補充数
--             dls.cash_and_card          -- 現金・カード併用額
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--      FROM   xxcos_dlv_headers dhs,           --納品ヘッダ
--             xxcos_dlv_lines dls              -- 納品明細
--      WHERE  dhs.order_no_hht = dls.order_no_hht
--      AND    dhs.digestion_ln_number = dls.digestion_ln_number
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  = cv_input_delivery
----      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.results_forward_flag = cv_untreated_flg
--      AND    dhs.order_no_ebs <> cn_tkn_zero
--      AND    dhs.program_application_id IS NOT NULL
--      AND    dls.program_application_id IS NOT NULL
----      FROM   xxcos_dlv_lines dls        -- 納品明細
----      WHERE  dls.order_no_hht IN ( SELECT dhs.order_no_hht
----                                   FROM   xxcos_dlv_headers dhs        -- 納品ヘッダ
----                                   WHERE  dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----                                   AND    dhs.input_class  = cv_input_delivery
----                                   AND    dhs.results_forward_flag = cn_tkn_zero
----                                   AND    dhs.order_no_ebs <> cn_tkn_zero
----                                   AND    dhs.program_application_id IS NOT NULL )
----      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
----                                          FROM   xxcos_dlv_headers dhs        -- 納品ヘッダ
----                                          WHERE  dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----                                          AND    dhs.input_class  = cv_input_delivery
----                                          AND    dhs.results_forward_flag = cn_tkn_zero
----                                          AND    dhs.order_no_ebs <> cn_tkn_zero
----                                          AND    dhs.program_application_id IS NOT NULL )
----      AND    dls.program_application_id IS NOT NULL 
--      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
--    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--******************************* 2009/06/23 N.Maeda Var1.17 DEL END   ***************************************
--
    --HHT入出庫一時ヘッダ用抽出
    CURSOR transaction_head_cur
    IS
      SELECT
-- ****************** 2009/08/10 1.18 N.Maeda ADD START **************************************************************--
             /*+
               INDEX ( HIT XXCOI_HHT_INV_TRANSACTIONS_N07 )
             */
-- ****************** 2009/08/10 1.18 N.Maeda ADD  END  **************************************************************--
               hit.employee_num,                    -- 営業員コード
               hit.invoice_no,                      -- 伝票№
               hit.invoice_type,                    -- 伝票区分
               hit.inside_code,                     -- 入庫側コード
               hit.invoice_date,                    -- 伝票日付
               hit.record_type,                     -- レコード種別
               hit.inside_cust_code,                -- 入庫側顧客コード
               hit.inside_business_low_type,        -- 入庫側業態区分
               hit.column_no                        -- コラムNo.
      FROM     xxcoi_hht_inv_transactions hit         -- HHT入出庫一時表
      WHERE    hit.record_type = cv_record_type_sample
      AND      hit.sample_if_flag = cv_sample_if_flag
      GROUP BY hit.employee_num, hit.invoice_no, hit.invoice_type,
               hit.inside_code, hit.invoice_date, hit.record_type,
               hit.inside_cust_code, hit.inside_business_low_type,
               hit.column_no
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
--      ORDER BY hit.invoice_no, hit.column_no;
      ORDER BY hit.inside_cust_code, hit.invoice_no, hit.column_no;
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
--
    --HHT入出庫一時テーブル
    CURSOR transaction_cur
    IS
      SELECT 
-- ****************** 2009/08/10 1.18 N.Maeda ADD START **************************************************************--
             /*+
               INDEX ( HIT XXCOI_HHT_INV_TRANSACTIONS_N07 )
             */
-- ****************** 2009/08/10 1.18 N.Maeda ADD  END  **************************************************************--
             hit.ROWID,                           -- 行ID
             hit.transaction_id,                  -- 入出庫一時表ID
             hit.interface_id,                    -- インターフェースID
             hit.form_header_id,                  -- 画面入力用ヘッダID
             hit.base_code,                       -- 拠点コード
             hit.record_type,                     -- レコード種別
             hit.employee_num,                    -- 営業員コード
             hit.invoice_no,                      -- 伝票№
             hit.item_code,                       -- 品目コード（品名コード）
             hit.case_quantity,                   -- ケース数
             hit.case_in_quantity,                -- 入数
             hit.quantity,                        -- 本数
             hit.invoice_type,                    -- 伝票区分
             hit.base_delivery_flag,              -- 拠点間倉替フラグ
             hit.outside_code,                    -- 出庫側コード
             hit.inside_code,                     -- 入庫側コード
             hit.invoice_date,                    -- 伝票日付
             hit.column_no,                       -- コラム№
             hit.unit_price,                      -- 単価
             hit.hot_cold_div,                    -- H/C
             hit.department_flag,                 -- 百貨店フラグ
             hit.interface_date,                  -- 受信日時
             hit.other_base_code,                 -- 他拠点コード
             hit.outside_subinv_code,             -- 出庫側保管場所
             hit.inside_subinv_code,              -- 入庫側保管場所
             hit.outside_base_code,               -- 出庫側拠点
             hit.inside_base_code,                -- 入庫側拠点
             hit.total_quantity,                  -- 総本数
             hit.inventory_item_id,               -- 品目ID
             hit.primary_uom_code,                -- 基準単位
             hit.outside_subinv_code_conv_div,    -- 出庫側保管場所変換区分
             hit.inside_subinv_code_conv_div,     -- 入庫側保管場所変換区分
             hit.outside_business_low_type,       -- 出庫側業態区分
             hit.inside_business_low_type,        -- 入庫側業態区分
             hit.outside_cust_code,               -- 出庫側顧客コード
             hit.inside_cust_code,                -- 入庫側顧客コード
             hit.hht_program_div,                 -- 入出庫ジャーナル処理区分
             hit.consume_vd_flag,                 -- 消化VD補充対象フラグ
             hit.item_convert_div,                -- 商品振替区分
             hit.stock_uncheck_list_div,          -- 入庫未確認リスト対象区分
             hit.stock_balance_list_div,          -- 入庫差異確認リスト対象区分
             hit.status,                          -- 処理ステータス
             hit.column_if_flag,                  -- コラム別転送済フラグ
             hit.column_if_date,                  -- コラム別転送日
             hit.sample_if_flag,                  -- 見本転送済フラグ
             hit.sample_if_date,                  -- 見本転送日
             hit.output_flag                      -- 出力済フラグ
      FROM   xxcoi_hht_inv_transactions hit         -- HHT入出庫一時表
      WHERE  hit.record_type = cv_record_type_sample
      AND    hit.sample_if_flag = cv_sample_if_flag
--******************************* 2010/03/01 1.26 N.Maeda MOD START ***************************************
--      ORDER BY hit.invoice_no,hit.column_no
      ORDER BY hit.inside_cust_code, hit.invoice_no,hit.column_no
--******************************* 2010/03/01 1.26 N.Maeda MOD  END  ***************************************
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
    BEGIN
--
      -- ========================
      -- 納品ヘッダ(HHT)情報取得
      -- ========================
      -- カーソルOPEN
      OPEN  dlv_head_hht_cur;
      -- バルクフェッチ
      FETCH dlv_head_hht_cur BULK COLLECT INTO gt_dlv_hht_headers_data;
      -- 抽出件数セット
      gn_target_cnt := dlv_head_hht_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE dlv_head_hht_cur;
--
      -- ==============================
      -- 納品画面入力データ納品ヘッダ(HHT)情報取得
      -- ==============================
      -- カーソルOPEN
      OPEN  dlv_inp_head_hht_cur;
      -- バルクフェッチ
      FETCH dlv_inp_head_hht_cur BULK COLLECT INTO gt_inp_dlv_hht_headers_data;
      -- 抽出件数セット
      gn_inp_target_cnt := dlv_inp_head_hht_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE dlv_inp_head_hht_cur;
--
      -- ==============================
      -- 納品ヘッダ(EDI)情報取得
      -- ==============================
      -- カーソルOPEN
      OPEN  dlv_head_edi_cur;
      -- バルクフェッチ
      FETCH dlv_head_edi_cur BULK COLLECT INTO gt_dlv_edi_headers_data;
      -- 抽出件数セット
      gn_target_edi_cnt := dlv_head_edi_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE dlv_head_edi_cur;
--
    EXCEPTION
----******************************* 2009/06/23 N.Maeda Var1.17 DEL START ***************************************
--      WHEN lock_err_expt THEN
--        IF( dlv_head_hht_cur%ISOPEN ) THEN
--          CLOSE dlv_head_hht_cur;
--        END IF;
--        IF( dlv_head_edi_cur%ISOPEN ) THEN
--          CLOSE dlv_head_edi_cur;
--        END IF;
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
--        RAISE;
--******************************* 2009/06/23 N.Maeda Var1.17 DEL END   ***************************************
      WHEN OTHERS THEN
        IF( dlv_head_hht_cur%ISOPEN ) THEN
          CLOSE dlv_head_hht_cur;
        END IF;
        IF( dlv_inp_head_hht_cur%ISOPEN ) THEN
          CLOSE dlv_inp_head_hht_cur;
        END IF;
        IF( dlv_head_edi_cur%ISOPEN ) THEN
          CLOSE dlv_head_edi_cur;
        END IF;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
        RAISE data_extract_err_expt;
    END;
--
----******************************* 2009/06/23 N.Maeda Var1.17 DEL START ***************************************
--    BEGIN
--
--      -- ========================
--      -- 納品明細(HHT)情報取得
--      -- ========================
--      -- カーソルOPEN
--      OPEN  dlv_line_hht_cur;
--      -- バルクフェッチ
--      FETCH dlv_line_hht_cur BULK COLLECT INTO gt_dlv_hht_lines_data;
--      -- 抽出件数セット
--      gn_line_cnt := dlv_line_hht_cur%ROWCOUNT;
--      -- カーソルCLOSE
--      CLOSE dlv_line_hht_cur;
----
--      -- ===========================
--      -- 納品画面入力データ納品明細(HHT)情報取得
--      -- ===========================
--      -- カーソルOPEN
--      OPEN  dlv_inp_line_hht_cur;
--      -- バルクフェッチ
--      FETCH dlv_inp_line_hht_cur BULK COLLECT INTO gt_inp_dlv_hht_lines_data;
--      -- 抽出件数セット
--      gn_inp_line_cnt := dlv_inp_line_hht_cur%ROWCOUNT;
--      -- カーソルCLOSE
--      CLOSE dlv_inp_line_hht_cur;
----
--      -- ===========================
--      -- 納品明細(EDI)情報取得
--      -- ===========================
--      -- カーソルOPEN
--      OPEN  dlv_line_edi_cur;
--      -- バルクフェッチ
--      FETCH dlv_line_edi_cur BULK COLLECT INTO gt_dlv_edi_lines_data;
--      -- 抽出件数セット
--      gn_line_edi_cnt := dlv_line_edi_cur%ROWCOUNT;
--      -- カーソルCLOSE
--      CLOSE dlv_line_edi_cur;
----
--    EXCEPTION
--      WHEN lock_err_expt THEN
--        IF( dlv_line_hht_cur%ISOPEN ) THEN
--          CLOSE dlv_line_hht_cur;
--        END IF;
--        IF( dlv_line_edi_cur%ISOPEN ) THEN
--          CLOSE dlv_line_edi_cur;
--        END IF;
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
--        RAISE;
--      WHEN OTHERS THEN
--        IF( dlv_line_hht_cur%ISOPEN ) THEN
--          CLOSE dlv_line_hht_cur;
--        END IF;
--        IF( dlv_line_edi_cur%ISOPEN ) THEN
--          CLOSE dlv_line_edi_cur;
--        END IF;
--        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
--        RAISE data_extract_err_expt;
--    END;
--******************************* 2009/06/23 N.Maeda Var1.17 DEL END   ***************************************
--
    BEGIN
      -- =====================================
      -- ヘッダ用HHT入出庫一時テーブル情報取得
      -- =====================================
      OPEN  transaction_head_cur;
      -- バルクフェッチ
      FETCH transaction_head_cur BULK COLLECT INTO gt_inv_trans_head;
      -- 抽出件数セット
      gn_transaction_head_cnt := transaction_head_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE transaction_head_cur;
--
      -- =====================================
      -- HHT入出庫一時テーブル情報取得
      -- =====================================
      -- カーソルOPEN
      OPEN  transaction_cur;
      -- バルクフェッチ
      FETCH transaction_cur BULK COLLECT INTO gt_inv_transactions_data;
      -- 抽出件数セット
      gn_transaction_cnt := transaction_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE transaction_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( transaction_head_cur%ISOPEN ) THEN
          CLOSE transaction_head_cur;
        END IF;
        IF( transaction_cur%ISOPEN ) THEN
          CLOSE transaction_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( transaction_head_cur%ISOPEN ) THEN
          CLOSE transaction_head_cur;
        END IF;
        IF( transaction_cur%ISOPEN ) THEN
          CLOSE transaction_cur;
        END IF;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
        RAISE data_extract_err_expt;
    END;
--
    -- 対照データが存在しない場合
    IF ( (gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) = 0 ) THEN
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
    WHEN data_extract_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END proc_extract;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
    iv_err_output_flag IN VARCHAR2, --エラーリスト出力フラグ
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ====================================================
    -- ユーザー定義変数
    -- ====================================================
    --
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
    lv_param_msg     VARCHAR2(5000);    --パラメーター出力用
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
    lv_max_date      VARCHAR2(50);      -- MAX日付
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
    --==============================================================
    --コンカレントの共通の初期出力
    --==============================================================
    --パラメータ出力メッセージ取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application           --アプリケーション
                     ,iv_name         => cv_msg_param             --パラメーター出力
                     ,iv_token_name1  => cv_tkn_gen_err_out_flag  --トークンコード１
                     ,iv_token_value1 => iv_err_output_flag       --汎用エラーリスト出力フラグ
                    );
    --パラメータをメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --パラメータをログに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --パラメータをグローバル変数に格納
    gv_gen_err_out_flag := iv_err_output_flag;
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END   *************************************
  --==================
  -- 在庫組織IDの取得
  --==================
  --在庫組織コード取得
  gv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
  --プロファイルエラー
  IF ( gv_orga_code IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
  --在庫組織ID取得
  gn_orga_id := xxcoi_common_pkg.get_organization_id( gv_orga_code );
--
  -- 在庫組織ID取得エラーの場合
  IF ( gn_orga_id IS NULL ) THEN
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --======================
  -- MO:営業単位取得
  --======================
  gv_salse_unit := FND_PROFILE.VALUE( cv_org_id );
--
  IF ( gv_salse_unit IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application,cv_msg_selse_unit );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --=======================
  -- 売上値引品目コード取得
  --=======================
  gv_disc_item := FND_PROFILE.VALUE( cv_disc_item_code );
--
  IF ( gv_disc_item IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application,cv_msg_disc_item );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --=======================
  -- 業務日付取得
  --=======================
  gd_process_date := xxccp_common_pkg2.get_process_date;
--
  -- 業務処理日取得エラーの場合
  IF ( gd_process_date IS NULL ) THEN
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
--    lv_errbuf := lv_errmsg;
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
      gd_max_date := TO_DATE( lv_max_date, cv_short_day );--
--
    END IF;
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

  EXCEPTION
--#####################################  固定部 START ##########################################
    WHEN global_api_expt THEN                             --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
    iv_err_output_flag IN VARCHAR2, --エラーリスト出力フラグ
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_inp_target_cnt :=0;
    gn_inp_line_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    proc_init(
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
      iv_err_output_flag, --エラーリスト出力フラグ
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- データ抽出処理(A-2)
    -- ===============================
    proc_extract(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START *************************************
--    IF ( gn_target_cnt <> 0 ) AND ( gn_line_cnt <> 0 ) THEN
    IF ( gn_target_cnt <> 0 )THEN
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  *************************************
--
      -- ================================
      -- 販売実績データ(HHT)成型処理(A-3)
      -- ================================
      proc_molded_hht(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ   --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START *************************************
--    IF ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) THEN
    IF ( gn_inp_target_cnt <> 0 ) THEN
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  *************************************
      -- ================================
      -- 販売実績データ(納品伝票入力画面)成型処理(A-9)
      -- ================================
      proc_inp_molded_hht(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ   --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/06/23 N.Maeda Var1.17 MOD START *************************************
--    IF ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) THEN
    IF ( gn_target_edi_cnt <> 0 ) THEN
--******************************* 2009/06/23 N.Maeda Var1.17 MOD  END  *************************************
      -- ================================
      -- 販売実績データ(EDI)成型処理(A-4)
      -- ================================
      proc_molded_edi(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( gn_transaction_cnt <> 0 ) THEN
      -- ======================================
      --  販売実績データ（入出庫）成型処理(A-5)
      -- ======================================
      proc_molded_trans(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/05/18 N.Maeda Var1.15 MOD START ***************************************
--    IF ( ( gn_target_cnt <> 0 ) AND ( gn_line_cnt <> 0 ) ) 
--      OR ( ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) )
--      OR ( ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) )
--      OR ( gn_transaction_cnt <> 0 ) 
--      OR ( ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) )THEN
      IF ( gt_line_sales_exp_line_id.COUNT <> 0 ) AND ( gt_head_id.COUNT <> 0 ) THEN
--******************************* 2009/05/18 N.Maeda Var1.15 MOD  END  ***************************************
      -- =======================================
      -- 販売実績データ登録処理(A-6)
      -- =======================================
      proc_insert(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/05/12 N.Maeda Var1.13 MOD START ***************************************
--    IF ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) THEN
    IF ( gt_oe_order_number.COUNT <> 0 ) THEN
--******************************* 2009/05/12 N.Maeda Var1.13 MOD  END  ***************************************
      -- =======================================
      -- OMクローズ処理(A-7)
      -- =======================================
      proc_om_close(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( ( gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) > 0 ) THEN
      -- ======================================
      -- 取得元テーブルフラグ更新(A-10)
      -- ======================================
      proc_flg_update(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/04/16 N.Maeda Var1. ADD START ***************************************
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
    IF ( g_gen_err_list_tab.COUNT > 0 ) THEN
      -- ===============================
      -- 汎用エラーリスト作成(A-13)
      -- ===============================
      proc_ins_gen_err_list(
        ov_errbuf   => lv_errbuf,  -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode, -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
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
--******************************* 2009/04/16 N.Maeda Var1. ADD END   ***************************************
-- ************ 2009/10/13 1.22 N.Maeda MOD START *********** --
    IF ( gt_msg_bookd.COUNT > 0 ) THEN                -- 記帳メッセージ
      <<bookd_num_loop>>
      FOR bookd_num IN 1..gt_msg_bookd.COUNT LOOP
        --メッセージ生成
        lv_errmsg := gt_msg_bookd(bookd_num);
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
      END LOOP bookd_num_loop;
    END IF;
-- ************ 2009/10/13 1.22 N.Maeda MOD  END  *********** --
    IF ( lv_retcode <> cv_status_error ) 
    AND ( ( gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) = 0 ) THEN
      ov_retcode := cv_status_warn;
--      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errbuf;
    END IF;
-- ************ 2009/10/13 1.22 N.Maeda MOD START *********** --
    IF ( gn_close_warn_flag <> 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
-- ************ 2009/10/13 1.22 N.Maeda MOD  END  *********** --
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD START *************************************
--    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_gen_err_out_flag IN  VARCHAR2       --エラーリスト出力フラグ
--******************************* 2010/09/02 K.Kiriu Var1.27 MOD END ***************************************
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD START *************************************
--       lv_errbuf   -- エラー・メッセージ           --# 固定 #
       iv_gen_err_out_flag                         --エラーリスト出力フラグ
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
--******************************* 2010/09/02 K.Kiriu Var1.27 ADD END ***************************************
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
    IF ( lv_retcode = cv_status_error) THEN
      -- エラー時登録件数初期化
      gn_normal_cnt := 0;
      gn_line_ins_cnt   := 0;
    END IF;
--******************************* 2009/05/18 N.Maeda Var1.15 ADD  END  ***************************************
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF (lv_retcode != cv_status_normal) THEN
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
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt + gn_target_edi_cnt + gn_inp_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--******************************* 2009/06/01 N.Maeda Var1.15 DEL START ***************************************
--    --明細対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_count_li_target
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_line_cnt + gn_line_edi_cnt + gn_inp_line_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
    --
--******************************* 2009/05/01 N.Maeda Var1.15 DEL END   ***************************************
--******************************* 2009/06/01 N.Maeda Var1.15 ADD START ***************************************
--******************************* 2009/06/01 N.Maeda Var1.15 DEL START ***************************************
--    --入出庫一時表データ件数
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_truns_count
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_transaction_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--******************************* 2009/05/01 N.Maeda Var1.15 DEL END   ***************************************
    --入出庫一時表ヘッダ生成
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_truns_create_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_transaction_head_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--******************************* 2009/06/01 N.Maeda Var1.15 DEL START ***************************************
--    --値引明細件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_disc_count
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_disc_count )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--******************************* 2009/05/01 N.Maeda Var1.15 DEL END   ***************************************
--******************************* 2009/05/01 N.Maeda Var1.15 ADD END   ***************************************
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
--******************************* 2009/06/01 N.Maeda Var1.15 DEL START ***************************************
--    --明細成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_count_li_update
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR( gn_line_ins_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--******************************* 2009/05/01 N.Maeda Var1.15 DEL END   ***************************************
    --
--******************************* 2009/05/18 N.Maeda Var1.15 ADD START ***************************************
    --スキップ件数
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
--******************************* 2009/06/01 N.Maeda Var1.15 DEL START ***************************************
--    --明細スキップ件数
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
--    --
--******************************* 2009/05/01 N.Maeda Var1.15 DEL END   ***************************************
--******************************* 2009/05/18 N.Maeda Var1.15 ADD END   ***************************************
    --エラー件数出力
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1 ;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
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
    IF (retcode = cv_status_error) THEN
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
END XXCOS001A05C;
/
