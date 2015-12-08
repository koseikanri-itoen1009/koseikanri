CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A06C (body)
 * Description      : 消化ＶＤ掛率作成
 * MD.050           : 消化ＶＤ掛率作成 MD050_COS_004_A06
 * Version          : 1.19
 *
 * Program List
 * -------------------------  ----------------------------------------------------------
 *  Name                        Description
 * -------------------------  ----------------------------------------------------------
 *  init                        初期処理(A-0)
 *  chk_parameter               パラメータチェック(A-1)
 *  lock_hdrs_lns_data          消化VD用消化計算ヘッダ、明細データロック処理(A-2-1)
 *  del_tt_vd_digestion         消化VD消化計算情報の今回データ削除 (A-3)
 *  ini_header                  ヘッダ単位初期化処理 (A-4)
 *  get_cust_trx                AR取引情報取得処理 (A-5)
 *  get_vd_column               VDコラム別取引情報取得処理 (A-7)
 *  ins_vd_digestion_ln         消化VD別用消化計算明細登録処理 (A-9)
 *  upd_vd_column_hdr           VDコラム別取引ヘッダ情報更新処理 (A-11)
 *  ins_vd_digestion_hdr        消化VD別用消化計算ヘッダ登録処理 (A-12)
 *  get_operation_day           稼働日情報取得処理 (A-13)
 *  get_non_operation_day       非稼働日情報取得処理 (A-14)
 *  del_blt_vd_digestion        消化VD消化計算情報の前々回データ削除 (A-15)
 *  calc_due_day                締日算出処理 (A-16)
 *  calc_pre_diges_due_dt       前回消化計算締年月日算出処理 (A-18)
 *  upd_pre_not_digestion_due   前回未計算データ更新処理(A-20)
 *  chk_pre_not_digestion_due   前回未計算データチェック処理(A-21)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   K.Kakishita      新規作成
 *  2009/02/03    1.1   T.Kitajima       [COS_009]警告終了時にメッセージが表示されない
 *  2009/02/04    1.2   K.Kakishita      [COS_012]差額計算時の掛率がマスタ掛率でない
 *  2009/02/04    1.3   K.Kakishita      [COS_018]定期実行の場合、消化計算締め日３の取得ミス
 *  2009/02/06    1.4   K.Kakishita      [COS_037]AR取引タイプマスタの抽出条件に営業単位を追加
 *  2009/02/20    1.5   K.Kakishita      パラメータのログファイル出力対応
 *  2009/03/19    1.6   T.Kitajima       [T1_0098]保管場所抽出条件修正
 *  2009/04/13    1.7   N.Maeda          [T1_0496]VDコラム別取引情報明細の数量使用部
 *                                                  ⇒VDコラム別取引情報明細の補充数へ変更
 *  2009/05/01    1.8   N.Maeda          [T1_0496]リカバリ用パラメータ追加
 *  2009/07/16    1.9   M.Sano           [0000319]DISC品目変更履歴アドオンの定価を取得しない
 *                                       [0000432]PTの考慮
 *  2009/08/04    1.10  N.Maeda          [0000922]PTの考慮
 *  2009/08/05    1.10  N.Maeda          [0000922]レビュー指摘対応
 *  2009/08/06    1.10  N.Maeda          [0000922]再レビュー指摘対応
 *  2010/01/19    1.11  K.Atsushiba      [E_本稼動_00622]消化計算締年月日導出処理修正
 *  2010/01/25    1.12  K.Atsushiba      [E_本稼動_01386]前々回データを削除しなように修正
 *  2010/02/15    1.13  K.Hosoi          [E_本稼動_01394]定期（洗替え）モードの追加。消化VD用
 *                                       消化計算ヘッダ、明細データロック処理の追加。
 *                                       [E_本稼動_01396]未計算のデータが残っていた場合、次の
 *                                       締日であっても計算しないよう修正。
 *                                       [E_本稼動_01397]掛率に対する閾値チェック処理の追加。
 *  2010/03/24    1.14  K.Atsushiba      [E_本稼動_01805]顧客移行対応
 *  2010/04/05    1.15  H.Sasaki         [E_本稼動_01688]集約フラグを追加
 *  2010/05/02    1.16  T.Ishiwata       [E_本稼動_02552]ＰＴ対応
 *  2010/05/06    1.17  M.Sano           [E_本稼動_02565]前回消化計算締年月日が取得できない場合の
 *                                                       考慮漏れ対応
 *  2010/05/07    1.18  M.Sano           [E_本稼動_02575]VDコラム別取引情報の別明細で重複削除される
 *                                                       現象の修正
 *  2015/10/19    1.19  K.Kiriu          [E_本稼動_13355]保管場所エラースキップ対応
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
  global_data_lock_expt     EXCEPTION;                                --ロック取得エラー例外
  global_target_nodata_expt EXCEPTION;                                --対象データ無しエラー例外
  global_get_profile_expt   EXCEPTION;                                --プロファイル取得エラー例外
  global_require_param_expt EXCEPTION;                                --必須入力パラメータ未設定エラー例外
  global_insert_data_expt   EXCEPTION;                                --データ登録エラー例外
  global_update_data_expt   EXCEPTION;                                --データ更新エラー例外
  global_delete_data_expt   EXCEPTION;                                --データ削除エラー例外
  global_select_data_expt   EXCEPTION;                                --データ取得エラー例外
  global_proc_date_err_expt EXCEPTION;                                --業務日付取得エラー例外
  global_call_api_expt      EXCEPTION;                                --API呼出エラー例外
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS004A06C'; -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name      CONSTANT fnd_application.application_short_name%TYPE
                                         := 'XXCOS';                --販物短縮アプリ名
  --販物メッセージ
  ct_msg_lock_err               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00001';     --ロック取得エラーメッセージ
  ct_msg_target_nodata_err      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00003';     --対象データ無しエラー
  ct_msg_get_profile_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00004';     --プロファイル取得エラー
  ct_msg_require_param_err      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00006';     --必須入力パラメータ未設定エラー
  ct_msg_insert_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00010';     --データ登録エラーメッセージ
  ct_msg_update_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00011';     --データ更新エラーメッセージ
  ct_msg_delete_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00012';     --データ削除エラーメッセージ
  ct_msg_select_data_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00013';     --データ取得エラーメッセージ
  ct_msg_process_date_err       CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00014';     --業務日付取得エラー
  ct_msg_call_api_err           CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00017';     --API呼出エラーメッセージ
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_msg_thrshld_chk_err        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14004';     --閾値チェックエラーメッセージ
  ct_msg_lock_error_skip        CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14005';     --ロックエラーメッセージ
  ct_msg_lock_error             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14006';     --ロックエラーメッセージ
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --文字列用
  ct_msg_request                CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00042';     --要求ＩＤ
  ct_msg_org_id                 CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00047';     --MO:営業単位
  ct_msg_get_organization_code  CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00048';     --XXCOI:在庫組織コード
  ct_msg_item_mst               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00050';     --品目マスタ
  ct_msg_subinv_mst             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00052';     --保管場所マスタ
  ct_msg_base_code              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00055';     --拠点コード
  ct_msg_max_date               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00056';     --XXCOS:MAX日付
  ct_msg_min_date               CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00120';     --XXCOS:MIN日付
  ct_msg_diges_calc_delay_day   CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-00140';     --XXCOS:消化VD掛率作成猶予日
  ct_msg_parameter              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11151';     --パラメータ出力メッセージ
  ct_msg_target_count           CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11152';     --対象件数メッセージ
  ct_msg_warning_count          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11153';     --警告件数メッセージ
  ct_msg_reg_any_cls_tblnm      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11154';     --定期随時区分クイックコードマスタ
  ct_msg_get_organization_id    CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11155';     --在庫組織IDの取得
  ct_msg_get_calendar_code      CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11156';     --カレンダコードの取得
  ct_msg_tt_diges_info_tblnm    CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11157';     --消化ＶＤ用消化計算情報（今回データ）
  ct_msg_tt_xvdh_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11158';     --消化ＶＤ用消化計算ヘッダテーブル（今回データ）
  ct_msg_tt_xvdl_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11159';     --消化ＶＤ用消化計算明細テーブル（今回データ）
  ct_msg_blt_diges_info_tblnm   CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11160';     --消化ＶＤ用消化計算情報（前々回データ）
  ct_msg_blt_xvdh_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11161';     --消化ＶＤ用消化計算ヘッダテーブル（前々回データ）
  ct_msg_blt_xvdl_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11162';     --消化ＶＤ用消化計算明細テーブル（前々回データ）
  ct_msg_key_info1              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11163';     --キー情報（消化計算締年月日、顧客コード）
  ct_msg_key_info2              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11164';     --キー情報（拠点コード、在庫組織コード）
  ct_msg_key_info3              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11165';     --キー情報（品目コード、適用日）
  ct_msg_key_info4              CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11166';     --キー情報（受注No(HHT)、枝番）
  ct_msg_xvdh_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11167';     --消化ＶＤ用消化計算ヘッダテーブル
  ct_msg_xvdl_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11168';     --消化ＶＤ用消化計算明細テーブル
  ct_msg_xvch_tblnm             CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11169';     --ＶＤコラム別取引ヘッダテーブル
--ct_msg_ar_info_tblnm          CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11170';     --AR取引情報
--ct_msg_ar_tax_info_tblnm      CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11171';     --AR取引情報（税金データ）
--ct_msg_vdc_info_tblnm         CONSTANT fnd_new_messages.message_name%TYPE
--                                       := 'APP-XXCOS1-11172';     --VDコラム別取引情報
  ct_msg_operation_day          CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11173';     --販売用稼働日チェック関数（稼働日）
  ct_msg_nonoperation_day       CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-11174';     --販売用稼働日チェック関数（非稼働日）
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_msg_max_thrshld            CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14002';     --XXCOS:最大閾値(消化VD)
  ct_msg_min_thrshld            CONSTANT fnd_new_messages.message_name%TYPE
                                         := 'APP-XXCOS1-14003';     --XXCOS:最小閾値(消化VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --トークン
  cv_tkn_table                  CONSTANT VARCHAR2(100) := 'TABLE';                --テーブル
  cv_tkn_profile                CONSTANT VARCHAR2(100) := 'PROFILE';              --プロファイル
  cv_tkn_table_name             CONSTANT VARCHAR2(100) := 'TABLE_NAME';           --テーブル名称
  cv_tkn_key_data               CONSTANT VARCHAR2(100) := 'KEY_DATA';             --キーデータ
  cv_tkn_in_param               CONSTANT VARCHAR2(100) := 'IN_PARAM';             --キーデータ
  cv_tkn_api_name               CONSTANT VARCHAR2(100) := 'API_NAME';             --ＡＰＩ名称
  cv_tkn_param1                 CONSTANT VARCHAR2(100) := 'PARAM1';               --第１入力パラメータ
  cv_tkn_param2                 CONSTANT VARCHAR2(100) := 'PARAM2';               --第２入力パラメータ
  cv_tkn_param3                 CONSTANT VARCHAR2(100) := 'PARAM3';               --第３入力パラメータ
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
  cv_tkn_param4                 CONSTANT VARCHAR2(100) := 'PARAM4';               --第４入力パラメータ
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
  cv_tkn_count1                 CONSTANT VARCHAR2(100) := 'COUNT1';               --件数１
  cv_tkn_count2                 CONSTANT VARCHAR2(100) := 'COUNT2';               --件数２
  cv_tkn_count3                 CONSTANT VARCHAR2(100) := 'COUNT3';               --件数３
  cv_tkn_diges_due_dt           CONSTANT VARCHAR2(100) := 'DIGES_DUE_DT';         --消化計算締年月日
  cv_tkn_cust_code              CONSTANT VARCHAR2(100) := 'CUST_CODE';            --顧客コード
  cv_tkn_base_code              CONSTANT VARCHAR2(100) := 'BASE_CODE';            --拠点コード
  cv_tkn_organization_code      CONSTANT VARCHAR2(100) := 'ORGANIZATION_CODE';    --在庫組織コード
  cv_tkn_item_code              CONSTANT VARCHAR2(100) := 'ITEM_CODE';            --拠点コード
  cv_tkn_apply_date             CONSTANT VARCHAR2(100) := 'APPLY_DATE';           --適用日
  cv_tkn_order_no_hht           CONSTANT VARCHAR2(100) := 'ORDER_NO_HHT';         --受注No(HHT)
  cv_tkn_digestion_ln_number    CONSTANT VARCHAR2(100) := 'DIGESTION_LN_NUMBER';  --枝番
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  cv_tkn_max_thrshld            CONSTANT VARCHAR2(100) := 'MAX_THRESHOLD';        --最大閾値
  cv_tkn_min_thrshld            CONSTANT VARCHAR2(100) := 'MIN_THRESHOLD';        --最小閾値
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --プロファイル名称
  ct_prof_org_id                CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'ORG_ID';                             --MO:営業単位
  ct_prof_min_date              CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MIN_DATE';                    --XXCOS:MIN日付
  ct_prof_max_date              CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MAX_DATE';                    --XXCOS:MAX日付
  ct_prof_organization_code     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOI1_ORGANIZATION_CODE';           --XXCOI:在庫組織コード
  ct_prof_diges_calc_delay_day  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_DIGESTION_CALC_DELAY_DAY';    --XXCOS:消化VD掛率作成猶予日数
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_prof_max_threshold_vd      CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MAX_THRESHOLD_VD';            --XXCOS:最大閾値(消化VD)
  ct_prof_min_threshold_vd      CONSTANT fnd_profile_options.profile_option_name%TYPE
                                         := 'XXCOS1_MIN_THRESHOLD_VD';            --XXCOS:最小閾値(消化VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --クイックコードタイプ
  ct_qct_regular_any_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_REGULAR_ANY_CLASS';           --定期随時区分マスタ
  ct_qct_customer_trx_type      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_AR_TRX_TYPE_MST_004_A06';     --ＡＲ取引タイプ特定マスタ_004_A06
  ct_qct_hokan_type_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_HOKAN_TYPE_MST_004_A06';      --保管場所分類特定マスタ_004_A06
  ct_qct_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_GYOTAI_SHO_MST_004_A06';      --業態小分類特定マスタ_004_A06
  ct_qct_cus_class_mst          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS1_CUS_CLASS_MST_004_A06';       --顧客区分特定マスタ_004_A06
  --クイックコード
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--  ct_qcc_customer_trx_type1     CONSTANT fnd_lookup_types.lookup_type%TYPE
--                                         := 'XXCOS_004_A06_1%';                   --ＡＲ取引タイプ特定マスタ(通常)
--  ct_qcc_customer_trx_type2     CONSTANT fnd_lookup_types.lookup_type%TYPE
--                                         := 'XXCOS_004_A06_2%';                   --ＡＲ取引タイプ特定マスタ(クレメモ)
-- 2009/07/16 Ver.1.9 M.Sano Del End
-- 2009/07/16 Ver.1.9 M.Sano Add Start
  ct_qcc_customer_trx_type      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06%';                     --ＡＲ取引タイプ特定マスタ
-- 2009/07/16 Ver.1.9 M.Sano Add End
  ct_qcc_hokan_type_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_%';                    --保管場所分類特定マスタ
  ct_qcc_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_%';                    --業態小分類特定マスタ
  ct_qcc_cus_class_mst1         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_1%';                   --顧客区分特定マスタ（拠点）
  ct_qcc_cus_class_mst2         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                         := 'XXCOS_004_A06_2%';                   --顧客区分特定マスタ（顧客）
--
  --定期随時区分
  ct_regular_any_class_any      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '0';                      --随時
  ct_regular_any_class_reg      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '1';                      --定期
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  ct_regular_any_class_rplc     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                         := '2';                      --定期（洗替え）
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --使用可能フラグ定数
  ct_enabled_flag_yes           CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                         := 'Y';                      --使用可能
  --販売実績作成済フラグ
  ct_sr_creation_flag_yes       CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                         := 'Y';                      --作成済
  ct_sr_creation_flag_no        CONSTANT xxcos_vd_digestion_hdrs.sales_result_creation_flag%TYPE
                                         := 'N';                      --未作成
  --存在フラグ
  cv_exists_flag_yes            CONSTANT VARCHAR2(1) := 'Y';          --存在あり
  cv_exists_flag_no             CONSTANT VARCHAR2(1) := 'N';          --存在なし
  --明細タイプ
  ct_line_type_line             CONSTANT ra_customer_trx_lines_all.line_type%TYPE
                                         := 'LINE';                   --LINE
  ct_line_type_tax              CONSTANT ra_customer_trx_lines_all.line_type%TYPE
                                         := 'TAX';                    --TAX
  --完了フラグ
  ct_complete_flag_yes          CONSTANT ra_customer_trx_all.complete_flag%TYPE
                                         := 'Y';                      --完了
  --未計算タイプ
  cv_uncalculate_type_init      CONSTANT VARCHAR2(1) := '0';          --INIT
  cv_uncalculate_type_nof       CONSTANT VARCHAR2(1) := '1';          --NOF
  cv_uncalculate_type_zero      CONSTANT VARCHAR2(1) := '2';          --ZERO
  --未計算区分
  ct_uncalculate_class_fnd      CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '0';                      --データあり
  ct_uncalculate_class_both_nof CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '1';                      --両方NOF
  ct_uncalculate_class_ar_nof   CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '2';                      --AR_NOF
  ct_uncalculate_class_vdc_nof  CONSTANT xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
                                         := '3';                      --VDC_NOF
  --稼働日ステータス
  cn_sales_oprtn_day_normal     CONSTANT NUMBER       := 0;           --稼働日
  cn_sales_oprtn_day_non        CONSTANT NUMBER       := 1;           --非稼働日
  cn_sales_oprtn_day_error      CONSTANT NUMBER       := 2;           --エラー
  --閏年制御用
  cv_month_february             CONSTANT VARCHAR2(2)  := '02';        --２月
  cv_last_day_28                CONSTANT VARCHAR2(2)  := '28';        --２８日
  cv_last_day_29                CONSTANT VARCHAR2(2)  := '29';        --２９日
  cv_last_day_30                CONSTANT VARCHAR2(2)  := '30';        --３０日
  --金額デフォルト
  cn_amount_default             CONSTANT NUMBER       := 0;           --金額
  --1日分
  cn_one_day                    CONSTANT NUMBER       := 1;
  --フォーマット
  cv_fmt_date                   CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';
  --掛率端数処理の位
  cn_rate_fraction_place        CONSTANT NUMBER       := 2;
  --ゼロ埋め
  cv_zero                       CONSTANT VARCHAR2(1)  := '0';
  --適用フラグ
  ct_apply_flag_yes             CONSTANT xxcmm_system_items_b_hst.apply_flag%TYPE
                                                      := 'Y';         --適用済み
-- 2009/07/16 Ver.1.9 M.Sano Add Start
  --言語コード
  ct_lang                       CONSTANT fnd_lookup_values.language%TYPE
                                                      := USERENV('LANG');
-- 2009/07/16 Ver.1.9 M.Sano Add End
--
/* 2010/01/25 Ver1.11 Add Start */
  cv_delete_flag                CONSTANT VARCHAR2(1) := 'D';          -- 削除フラグ
/* 2010/01/25 Ver1.11 Add End */
-- == 2010/04/05 V1.15 Added START ===============================================================
  cv_skip_flag                  CONSTANT VARCHAR2(1)  :=  'S';        --  スキップフラグ
  cv_y                          CONSTANT VARCHAR2(1)  :=  'Y';
  cv_n                          CONSTANT VARCHAR2(1)  :=  'N';
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
-- 2010/03/24 Ver.1.14 Add Start
  cv_dya_fmt_month              CONSTANT VARCHAR2(2) := 'MM';         -- 月
-- 2010/03/24 Ver.1.14 Add End
--
-- 2010/05/02 Ver.1.16 T.Ishiwata Add Start
  --業態小分類27:消化VD
  cv_buz_type27                 CONSTANT VARCHAR2(2)  := '27';
-- 2010/05/02 Ver.1.16 T.Ishiwata Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --消化VD別消化計算ヘッダ用
  TYPE g_xvdh_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_hdrs%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
  --消化VD別消化計算明細用
  TYPE g_xvdl_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_lns%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
  --消化計算締年月日用
  TYPE g_diges_due_dt_ttype
  IS
    TABLE OF
      DATE
    INDEX BY PLS_INTEGER
    ;
  --保管場所マスタチェック用
  TYPE g_subinv_ttype
  IS
    TABLE OF
      mtl_secondary_inventories.secondary_inventory_name%TYPE
    INDEX BY VARCHAR2(10)
    ;
  --品目マスタチェック用
  TYPE g_fixed_price_ttype
  IS
    TABLE OF
      xxcmm_system_items_b_hst.fixed_price%TYPE
    INDEX BY VARCHAR2(40)
    ;
  --前回消化計算締年月日取得用
  TYPE g_pre_diges_due_dt_ttype
  IS
    TABLE OF
      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE
    INDEX BY PLS_INTEGER
    ;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 対象件数
  gn_target_cnt1                        NUMBER;                       -- 対象件数１
  gn_target_cnt2                        NUMBER;                       -- 対象件数２
  gn_target_cnt3                        NUMBER;                       -- 対象件数３
  -- 警告件数
  gn_warn_cnt1                          NUMBER;                       -- スキップ件数１
  gn_warn_cnt2                          NUMBER;                       -- スキップ件数２
  gn_warn_cnt3                          NUMBER;                       -- スキップ件数３
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  gn_thrshld_chk_cnt                    NUMBER;                       -- 閾値チェックエラー件数
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --パラメータ
  gt_regular_any_class                  fnd_lookup_values.lookup_code%TYPE;
                                                                      -- 定期随時区分
  gt_base_code                          hz_cust_accounts.account_number%TYPE;
                                                                      -- 拠点コード
  gt_customer_number                    hz_cust_accounts.account_number%TYPE;
                                                                      -- 顧客コード
  --初期取得
  gd_process_date                       DATE;                         -- 業務日付
  gn_org_id                             NUMBER;                       -- 営業単位
  gd_min_date                           DATE;                         -- MIN日付
  gd_max_date                           DATE;                         -- MAX日付
  gt_organization_code                  mtl_parameters.organization_code%TYPE;
                                                                      -- 在庫組織コード
  gt_organization_id                    mtl_parameters.organization_id%TYPE;
                                                                      -- 在庫組織ID
  gt_calendar_code                      bom_calendars.calendar_code%TYPE;
                                                                      -- カレンダコード
  gn_diges_calc_delay_day               NUMBER;                       -- 消化VD掛率作成猶予日数
  gd_temp_digestion_due_date            DATE;                         -- 仮消化VD締年月日
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  gn_max_threshold                      NUMBER;                       -- 最大閾値(消化VD)
  gn_min_threshold                      NUMBER;                       -- 最小閾値(消化VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  --
  gt_vd_digestion_hdr_id                xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE;
                                                                      -- 消化VD消化計算ヘッダID
  --登録、更新用内部テーブル
  gn_xvch_idx                           NUMBER;
  gn_tt_xvdh_idx                        NUMBER;
  gn_xvdh_idx                           NUMBER;
  gn_xvdl_idx                           NUMBER;
  g_xvch_tab                            g_xvdh_ttype;                 -- VDコラム別取引ヘッダ
  g_tt_xvdh_tab                         g_xvdh_ttype;                 -- 今回データ削除用消化VD別消化計算ヘッダ
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
  g_tt_xvdh_work_tab                    g_xvdh_ttype;                 -- 今回データ削除用消化VD別消化計算ヘッダワーク
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
  g_xvdh_tab                            g_xvdh_ttype;                 -- 消化VD別消化計算ヘッダ
  g_xvdl_tab                            g_xvdl_ttype;                 -- 消化VD別消化計算明細
  g_diges_due_dt_tab                    g_diges_due_dt_ttype;         -- 消化計算締年月日
  --稼働日計算用消化計算締年月日
  gd_calc_digestion_due_date            DATE;
  --チェック用内部テーブル
  g_chk_subinv_tab                      g_subinv_ttype;
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--  g_chk_fixed_price_tab                 g_fixed_price_ttype;
-- 2009/07/16 Ver.1.9 M.Sano End Start
  g_get_pre_diges_due_dt_tab            g_pre_diges_due_dt_ttype;
--
-- == 2010/04/05 V1.15 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : chk_pre_not_digestion_due
   * Description      : 前回未計算データチェック処理(A-21)
   ***********************************************************************************/
  PROCEDURE chk_pre_not_digestion_due(
    iv_customer_code        IN  VARCHAR2,     --  顧客コード
    od_pre_digest_due_date  OUT DATE,         --  前回消化計算締年月日
    ov_errbuf               OUT VARCHAR2,     --  エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --  リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_pre_not_digestion_due'; -- プログラム名
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
    --==================================
    -- 1.パラメータ出力
    --==================================
    od_pre_digest_due_date  :=  NULL;
    --
    IF  (gt_regular_any_class IN(ct_regular_any_class_any, ct_regular_any_class_rplc))  THEN
      -- 随時または、定期（洗替）の場合
      BEGIN
        SELECT    xvdh.pre_digestion_due_date
        INTO      od_pre_digest_due_date
        FROM      xxcos_vd_digestion_hdrs       xvdh
        WHERE     xvdh.customer_number      =   iv_customer_code
        AND       xvdh.summary_data_flag    =   cv_y
        AND       ROWNUM = 1;
        --
        IF (od_pre_digest_due_date IS NULL) THEN
          od_pre_digest_due_date  :=  gd_min_date;
        END IF;
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
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
  END chk_pre_not_digestion_due;
  --
  /**********************************************************************************
   * Procedure Name   : upd_pre_not_digestion_due
   * Description      : 前回未計算データ更新処理(A-20)
   ***********************************************************************************/
  PROCEDURE upd_pre_not_digestion_due(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_pre_not_digestion_due'; -- プログラム名
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
    lv_str_table_name   VARCHAR2(50);
    -- *** ローカル・カーソル ***
    CURSOR  cur_lock_xvdh(iv_customer_number  IN  VARCHAR2)
    IS
      SELECT  xvdh.vd_digestion_hdr_id
      FROM    xxcos_vd_digestion_hdrs     xvdh
      WHERE   xvdh.summary_data_flag    =   cv_y
      AND     xvdh.customer_number      =   iv_customer_number
      FOR UPDATE  NOWAIT;
--
    -- *** ローカル・レコード ***
    rec_lock_xvdh     cur_lock_xvdh%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.パラメータ出力
    --==================================
    <<xvdh_lock_loop>>
    FOR i IN   1 .. g_xvdh_tab.COUNT  LOOP
      --  消化ＶＤ用消化計算ヘッダロック
      OPEN  cur_lock_xvdh(iv_customer_number  =>  g_xvdh_tab(i).customer_number);
      --
      <<xvdh_upd_loop>>
      LOOP
        FETCH cur_lock_xvdh INTO  rec_lock_xvdh;
        EXIT  WHEN  cur_lock_xvdh%NOTFOUND;
        --
        --  集約フラグ更新
        UPDATE  xxcos_vd_digestion_hdrs
        SET     sales_result_creation_flag    =   cv_skip_flag
              , sales_amount                  =   0
              , ar_sales_amount               =   0
              , summary_data_flag             =   cv_n
              , last_updated_by               =   cn_last_updated_by
              , last_update_date              =   cd_last_update_date
              , last_update_login             =   cn_last_update_login
              , request_id                    =   cn_request_id
              , program_application_id        =   cn_program_application_id
              , program_id                    =   cn_program_id
              , program_update_date           =   cd_program_update_date
        WHERE   vd_digestion_hdr_id   =   rec_lock_xvdh.vd_digestion_hdr_id;
      END LOOP  xvdh_upd_loop;
      --
      CLOSE cur_lock_xvdh;
    END LOOP  xvdh_lock_loop;
--
  EXCEPTION
--
    WHEN  global_data_lock_expt THEN
      --  ロックエラーの場合
      IF  (cur_lock_xvdh%ISOPEN)  THEN
        CLOSE cur_lock_xvdh;
      END IF;
      --  テーブル名称取得
      lv_str_table_name :=  xxccp_common_pkg.get_msg(
                                iv_application        => ct_xxcos_appl_short_name
                              , iv_name               => ct_msg_xvdh_tblnm
                            );
      --  エラーメッセージ取得
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                                iv_application    =>  ct_xxcos_appl_short_name
                              , iv_name           =>  ct_msg_lock_error
                              , iv_token_name1    =>  cv_tkn_table
                              , iv_token_value1   =>  lv_str_table_name
                            );
      ov_errmsg         :=  lv_errmsg;
      ov_errbuf         :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode        :=  cv_status_error;
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
      IF  (cur_lock_xvdh%ISOPEN)  THEN
        CLOSE cur_lock_xvdh;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_pre_not_digestion_due;
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_regular_any_class      IN      VARCHAR2,         -- 1.定期随時区分
    iv_base_code              IN      VARCHAR2,         -- 2.拠点コード
    iv_customer_number        IN      VARCHAR2,         -- 3.顧客コード
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2,         -- 4.業務日付
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --==================================
    -- 1.パラメータ出力
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_parameter,
                                   iv_token_name1        => cv_tkn_param1,
                                   iv_token_value1       => iv_regular_any_class,
                                   iv_token_name2        => cv_tkn_param2,
                                   iv_token_value2       => iv_base_code,
                                   iv_token_name3        => cv_tkn_param3,
                                   iv_token_value3       => iv_customer_number,
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
                                   iv_token_name4        => cv_tkn_param4,
                                   iv_token_value4       => iv_process_date
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => lv_errmsg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    --==================================
    -- 2.パラメータ変換
    --==================================
    gt_regular_any_class      := iv_regular_any_class;
    gt_base_code              := iv_base_code;
    gt_customer_number        := iv_customer_number;
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    IF ( iv_process_date IS NOT NULL ) THEN
      gd_process_date           := TRUNC ( TO_DATE ( iv_process_date , cv_fmt_date ) );
    END IF;
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_parameter
   * Description      : パラメータチェック処理(A-1)
   ***********************************************************************************/
  PROCEDURE chk_parameter(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parameter';        -- プログラム名
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
    lv_org_id                     VARCHAR2(5000);
    lv_min_date                   VARCHAR2(5000);
    lv_max_date                   VARCHAR2(5000);
    lt_organization_id            mtl_parameters.organization_id%TYPE;
                                                                      --在庫組織ID
    lt_organization_code          mtl_parameters.organization_code%TYPE;
                                                                      --在庫組織コード
    lv_diges_calc_delay_day       VARCHAR2(5000);                     --消化VD掛率作成猶予日数
    lt_regular_any_class_name     fnd_lookup_values.meaning%TYPE;     --定期随時区分名称
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    lv_max_threshold              VARCHAR2(5000);                     --MAX閾値(VD)
    lv_min_threshold              VARCHAR2(5000);                     --MIN閾値(VD)
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    --エラーメッセージ用
    lv_str_profile_name           VARCHAR2(5000);                     --プロファイル名
    lv_str_api_name               VARCHAR2(5000);                     --関数名
    lv_str_in_param               VARCHAR2(5000);                     --入力パラメータ名
    lv_str_table_name             VARCHAR2(5000);                     --テーブル名
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
    --============================================
    -- 1.業務日付取得
    --============================================
--******************************** 2009/05/01 1.8 N.Maeda MOD START **************************************************
--    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--    --gd_process_date           := TO_DATE( '2009/03/03', 'YYYY/MM/DD' ); --debug
    IF ( gd_process_date IS NULL ) THEN
      gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
    END IF;
--******************************** 2009/05/01 1.8 N.Maeda MOD END   **************************************************
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --============================================
    -- 2.MO:営業単位
    --============================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --============================================
    -- 3.XXCOS:MIN日付
    --============================================
    lv_min_date := FND_PROFILE.VALUE( ct_prof_min_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_min_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_min_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_min_date               := TO_DATE( lv_min_date, cv_fmt_date );
--
    --============================================
    -- 4.XXCOS:MAX日付
    --============================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --============================================
    -- 5.XXCOI:在庫組織コード
    --============================================
    gt_organization_code      := FND_PROFILE.VALUE( ct_prof_organization_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_organization_code IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_organization_code
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --============================================
    -- 6. 在庫組織IDの取得
    --============================================
    gt_organization_id        := xxcoi_common_pkg.get_organization_id(
                                   iv_organization_code          => gt_organization_code
                                 );
    --
    IF ( gt_organization_id IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_organization_id
                                         );                      -- 在庫組織ID取得
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 7. 販売用カレンダコード取得
    --============================================
    lt_organization_id        := gt_organization_id;
    --
    xxcos_common_pkg.get_sales_calendar_code(
      ion_organization_id     => lt_organization_id,             -- 在庫組織ＩＤ
      iov_organization_code   => lt_organization_code,           -- 在庫組織コード
      ov_calendar_code        => gt_calendar_code,               -- カレンダコード
      ov_errbuf               => lv_errbuf,                      -- エラー・メッセージエラー       #固定#
      ov_retcode              => lv_retcode,                     -- リターン・コード               #固定#
      ov_errmsg               => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- カレンダコード取得
      RAISE global_call_api_expt;
    END IF;
    --
    IF ( gt_calendar_code IS NULL ) THEN
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                           iv_application        => ct_xxcos_appl_short_name,
                                           iv_name               => ct_msg_get_calendar_code
                                         );                      -- カレンダコード取得
      RAISE global_call_api_expt;
    END IF;
--
    --============================================
    -- 8.XXCOS:消化VD掛率作成猶予日数の取得
    --============================================
    lv_diges_calc_delay_day   := FND_PROFILE.VALUE( ct_prof_diges_calc_delay_day );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_diges_calc_delay_day IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_diges_calc_delay_day
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_diges_calc_delay_day   := TO_NUMBER( lv_diges_calc_delay_day );
--
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --============================================
    -- 9.XXCOS:最大閾値取得
    --============================================
    lv_max_threshold      := FND_PROFILE.VALUE( ct_prof_max_threshold_vd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_threshold IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_thrshld
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_max_threshold          := TO_NUMBER( lv_max_threshold );
--
    --============================================
    -- 10.XXCOS:最小閾値取得
    --============================================
    lv_min_threshold      := FND_PROFILE.VALUE( ct_prof_min_threshold_vd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_min_threshold IS NULL ) THEN
      --プロファイル名文字列取得
      lv_str_profile_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_min_thrshld
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_min_threshold          := TO_NUMBER( lv_min_threshold );
--
--    --============================================
--    -- 9.定期随時パラメータチェック
--    --============================================
    --============================================
    -- 11.定期随時パラメータチェック
    --============================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    BEGIN
      SELECT
        flv.meaning                     regular_any_class_name
      INTO
        lt_regular_any_class_name
      FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--        fnd_application                 fa,
--        fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
        fnd_lookup_values               flv
      WHERE
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--        fa.application_id               = flt.application_id
--      AND flt.lookup_type               = flv.lookup_type
--      AND fa.application_short_name     = ct_xxcos_appl_short_name
--      AND flt.lookup_type               = ct_qct_regular_any_class
        flv.lookup_type               = ct_qct_regular_any_class
-- 2009/07/16 Ver.1.9 M.Sano Del End
      AND flv.lookup_code               = gt_regular_any_class
      AND gd_process_date               >= flv.start_date_active
      AND gd_process_date               <= NVL( flv.end_date_active, gd_max_date )
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--      AND flv.language                  = USERENV( 'LANG' )
      AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
      AND flv.enabled_flag              = ct_enabled_flag_yes
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_str_table_name     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_reg_any_cls_tblnm
                                 );
        RAISE global_select_data_expt;
    END;
--
    --============================================
    -- 10.定期の場合、仮消化VD締年月日を算出
    --============================================
    IF ( gt_regular_any_class = ct_regular_any_class_reg ) THEN
      gd_temp_digestion_due_date := gd_process_date - gn_diges_calc_delay_day;
    END IF;
--
    --============================================
    -- 11.随時の場合、拠点必須チェック
    --============================================
    IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      IF ( gt_base_code IS NULL ) THEN
        --入力パラメータ名文字列取得
        lv_str_in_param         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_base_code
                                   );
        RAISE global_require_param_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_str_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数エラー例外ハンドラ ***
    WHEN global_call_api_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 必須入力パラメータ未設定例外ハンドラ ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_require_param_err,
                                   iv_token_name1        => cv_tkn_in_param,
                                   iv_token_value1       => lv_str_in_param
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコードマスタ例外ハンドラ ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   #######################################
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
  END chk_parameter;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
  /**********************************************************************************
   * Procedure Name   : lock_hdrs_lns_data
   * Description      : 消化VD用消化計算ヘッダ、明細データロック処理(A-2-1)
   ***********************************************************************************/
  PROCEDURE lock_hdrs_lns_data(
    it_vd_dgstn_hdr_id  IN  xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
    iv_customer_num     IN  VARCHAR2,     --   顧客コード
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ            --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード              --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_hdrs_lns_data'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur(
     it_vd_digestion_hdr_id       xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    )
    IS
      SELECT
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id
      FROM
        xxcos_vd_digestion_hdrs           xvdh,                             --消化VD用消化計算ヘッダテーブル
        xxcos_vd_digestion_lns            xvdl                              --消化VD用消化計算明細テーブル
      WHERE
        xvdh.vd_digestion_hdr_id          = it_vd_digestion_hdr_id
      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id (+)
      AND xvdh.sales_result_creation_flag <> cv_delete_flag
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ローカル・関数 ***
--
    -- *** ローカル・例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.消化VD情報データロック
    --==================================
    BEGIN
      OPEN lock_cur( it_vd_digestion_hdr_id => it_vd_dgstn_hdr_id );
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --テーブル名取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_diges_info_tblnm
                                 );
--
      IF ( gt_regular_any_class = ct_regular_any_class_reg ) 
        OR ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      --パラメータ実行区分が、「定期」または「定期（洗替え）」の場合
        ov_errmsg               := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_lock_error_skip,
                                     iv_token_name1        => cv_tkn_table,
                                     iv_token_value1       => lv_str_table_name,
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => iv_customer_num
                                   );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_warn;
      ELSIF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      --パラメータ実行区分が、「随時」の場合
        ov_errmsg               := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_lock_error,
                                     iv_token_name1        => cv_tkn_table,
                                     iv_token_value1       => lv_str_table_name
                                   );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_error;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END lock_hdrs_lns_data;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
  /**********************************************************************************
   * Procedure Name   : del_tt_vd_digestion
   * Description      : 消化VD用消化計算情報の今回データ削除(A-3)
   ***********************************************************************************/
  PROCEDURE del_tt_vd_digestion(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_tt_vd_digestion'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ローカル・カーソル ***
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    CURSOR lock_cur(
--     it_vd_digestion_hdr_id       xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
--    )
--    IS
--      SELECT
--        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id
--      FROM
--        xxcos_vd_digestion_hdrs           xvdh,                             --消化VD用消化計算ヘッダテーブル
--        xxcos_vd_digestion_lns            xvdl                              --消化VD用消化計算明細テーブル
--      WHERE
--        xvdh.vd_digestion_hdr_id          = it_vd_digestion_hdr_id
--      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id (+)
--/* 2010/01/25 Ver1.11 Add Start */
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
--/* 2010/01/25 Ver1.11 Add Start */
--      FOR UPDATE NOWAIT
--      ;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** ローカル・レコード ***
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    l_lock_rec lock_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** ローカル・関数 ***
--
    -- *** ローカル・例外 ***
/* 2010/01/25 Ver1.11 Add Start */
    update_data_expt            EXCEPTION;
/* 2010/01/25 Ver1.11 Add End */

--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<tt_xvdh_tab_loop>>
    FOR i IN 1..g_tt_xvdh_tab.COUNT LOOP
      ln_idx := i;
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      --==================================
--      -- 1.消化VD情報データロック
--      --==================================
--      BEGIN
--        OPEN lock_cur( it_vd_digestion_hdr_id => g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id );
--        CLOSE lock_cur;
--      EXCEPTION
--        WHEN global_data_lock_expt THEN
--          RAISE global_data_lock_expt;
--      END;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
/* 2010/01/25 Ver1.11 Add Start */
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--      IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
--      -- 随時の場合
      IF ( gt_regular_any_class = ct_regular_any_class_any )
        OR ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      -- 随時又は、定期（洗替え）の場合
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
/* 2010/01/25 Ver1.11 Add End */
      --======================================================
      -- 2.消化VD別消化計算ヘッダテーブル削除
      --======================================================
      BEGIN
        DELETE FROM
          xxcos_vd_digestion_hdrs         xvdh
        WHERE
          xvdh.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --消化VD別消化計算ヘッダテーブル文字列取得
          lv_str_table_name   := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_xvdh_tblnm
                                 );
          --キー情報文字列取得
          lv_str_key_data     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info1,
                                   iv_token_name1        => cv_tkn_diges_due_dt,
                                   iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                              cv_fmt_date
                                                            ),
                                   iv_token_name2        => cv_tkn_cust_code,
                                   iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                 );
          --
          RAISE global_delete_data_expt;
          --
      END;
      --
      --======================================================
      -- 3.消化VD別消化計算明細テーブル削除
      --======================================================
      BEGIN
        DELETE FROM
          xxcos_vd_digestion_lns          xvdl
        WHERE
          xvdl.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --消化VD別消化計算明細テーブル文字列取得
          lv_str_table_name   := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_tt_xvdl_tblnm
                                 );
          --キー情報文字列取得
          lv_str_key_data     := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_key_info1,
                                   iv_token_name1        => cv_tkn_diges_due_dt,
                                   iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                              cv_fmt_date
                                                            ),
                                   iv_token_name2        => cv_tkn_cust_code,
                                   iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                 );
          --
          RAISE global_delete_data_expt;
          --
      END;
/* 2010/01/25 Ver1.11 Add Start */
      ELSE
        -- 定期の場合
        BEGIN
        UPDATE
           xxcos_vd_digestion_hdrs         xvdh
        SET
           xvdh.sales_result_creation_flag      = cv_delete_flag,              -- 販売実績作成済みフラグ
           xvdh.last_updated_by                 = cn_last_updated_by,
           xvdh.last_update_date                = cd_last_update_date,
           xvdh.last_update_login               = cn_last_update_login,
           xvdh.request_id                      = cn_request_id,
           xvdh.program_application_id          = cn_program_application_id,
           xvdh.program_id                      = cn_program_id,
           xvdh.program_update_date             = cd_program_update_date
        WHERE
           xvdh.vd_digestion_hdr_id        =  g_tt_xvdh_tab(ln_idx).vd_digestion_hdr_id
        ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 更新エラーの場合
            --消化VD別消化計算ヘッダテーブル文字列取得
            lv_str_table_name   := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_tt_xvdh_tblnm
                                   );
            --キー情報文字列取得
            lv_str_key_data     := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( g_tt_xvdh_tab(ln_idx).digestion_due_date,
                                                                cv_fmt_date
                                                              ),
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => g_tt_xvdh_tab(ln_idx).customer_number
                                   );
            --
            RAISE update_data_expt;
            --
        END;
      END IF;
/* 2010/01/25 Ver1.11 Add Start */
      --
    END LOOP tt_xvdh_tab_loop;
--
  EXCEPTION
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--    -- *** 処理対象データロック例外ハンドラ ***
--    WHEN global_data_lock_expt THEN
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
--      --テーブル名取得
--      lv_str_table_name       := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_tt_diges_info_tblnm
--                                 );
----
--      ov_errmsg               := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_lock_err,
--                                   iv_token_name1        => cv_tkn_table,
--                                   iv_token_value1       => lv_str_table_name
--                                 );
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--      ov_retcode := cv_status_error;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
--
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_delete_data_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_delete_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
/* 2010/01/25 Ver1.11 Add Start */
    WHEN update_data_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_update_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2010/01/25 Ver1.11 Add End */
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--      IF ( lock_cur%ISOPEN ) THEN
--        CLOSE lock_cur;
--      END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_tt_vd_digestion;
--
  /**********************************************************************************
   * Procedure Name   : ini_header
   * Description      : ヘッダ単位初期化処理(A-4)
   ***********************************************************************************/
  PROCEDURE ini_header(
    ot_vd_digestion_hdr_id         OUT     xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
                                                                      --  1.消化VD用消化計算ヘッダID
    ov_ar_uncalculate_type         OUT     VARCHAR2,                  --  2.AR未計算区分
    ov_vdc_uncalculate_type        OUT     VARCHAR2,                  --  3.VDコラム別未計算区分
    on_ar_amount                   OUT     NUMBER,                    --  4.売上金額合計
    on_tax_amount                  OUT     NUMBER,                    --  5.消費税額合計
    on_vdc_amount                  OUT     NUMBER,                    --  6.販売金額合計
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ini_header'; -- プログラム名
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
    --==================================
    -- 1.消化VD用消化計算ヘッダIDの取得
    --==================================
    BEGIN
      SELECT
        xxcos_vd_digestion_hdrs_s01.NEXTVAL       vd_digestion_hdr_id
      INTO
        ot_vd_digestion_hdr_id
      FROM
        dual
      ;
    END;
--
    --==================================
    -- 2.各種変数クリア処理
    --==================================
    ov_ar_uncalculate_type    := cv_uncalculate_type_init;
    ov_vdc_uncalculate_type   := cv_uncalculate_type_init;
    on_ar_amount              := cn_amount_default;
    on_tax_amount             := cn_amount_default;
    on_vdc_amount             := cn_amount_default;
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
  END ini_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_trx
   * Description      : AR取引情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_cust_trx(
    it_cust_account_id             IN      xxcos_vd_digestion_hdrs.cust_account_id%TYPE,
                                                                      --  1.顧客ID
    it_customer_number             IN      xxcos_vd_digestion_hdrs.customer_number%TYPE,
                                                                      --  2.顧客コード
    id_start_gl_date               IN      DATE,                      --  3.開始GL記帳日
    id_end_gl_date                 IN      DATE,                      --  4.終了GL記帳日
    ov_ar_uncalculate_type         OUT     VARCHAR2,                  --  5.ARコラム別未計算区分
    on_ar_amount                   OUT     NUMBER,                    --  6.売上金額合計
    on_tax_amount                  OUT     NUMBER,                    --  7.消費税額合計
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx'; -- プログラム名
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
    lv_ar_exists_flag                   VARCHAR2(1);                  --存在フラグ
    ln_ar_amount                        NUMBER;                       --売上金額合計
    ln_tax_amount                       NUMBER;                       --消費税額合計
    ln_work_tax_amount                  NUMBER;                       --ワーク用消費税額
--
    -- *** ローカル・カーソル ***
    -- AR取引情報取得処理(A-5-1)
    CURSOR ar_cur
    IS
      SELECT
-- == 2010/04/05 V1.15 Added START ===============================================================
      /*+
        USE_NL (rcta,rctta)
      */
-- == 2010/04/05 V1.15 Added END ===============================================================
        rctlgda.gl_date                     gl_date,                        --売上計上日
        rctla.extended_amount               extended_amount,                --本体金額
        rctla.customer_trx_line_id          customer_trx_line_id            --取引明細ID
      FROM
        ra_customer_trx_all                 rcta,                           --請求取引情報テーブル
        ra_customer_trx_lines_all           rctla,                          --請求取引明細テーブル
        ra_cust_trx_line_gl_dist_all        rctlgda,                        --請求取引明細会計配分テーブル
        ra_cust_trx_types_all               rctta                           --請求取引タイプマスタ
      WHERE
        rcta.ship_to_customer_id            = it_cust_account_id
      AND rcta.customer_trx_id              = rctla.customer_trx_id
      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
      AND rctla.line_type                   = ct_line_type_line
      AND rcta.complete_flag                = ct_complete_flag_yes
      AND rctlgda.gl_date                   >= id_start_gl_date
      AND rctlgda.gl_date                   <= id_end_gl_date
      AND rcta.org_id                       = gn_org_id
      AND rcta.org_id                       = rctta.org_id
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--              fnd_application               fa,
--              fnd_lookup_types              flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
              fnd_lookup_values             flv
            WHERE
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--              fa.application_id             = flt.application_id
--            AND flt.lookup_type             = flv.lookup_type
--            AND fa.application_short_name   = ct_xxcos_appl_short_name
--            AND flv.lookup_type             = ct_qct_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Del End
              flv.lookup_type             = ct_qct_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type
-- 2009/07/16 Ver.1.9 M.Sano Mod End
            AND flv.meaning                 = rctta.name
            AND rctlgda.gl_date             >= flv.start_date_active
            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--            AND flv.language                = USERENV( 'LANG' )
            AND flv.language                = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- *********** 2009/08/04 N.Maeda 1.10 DEL START *******************--
--            AND ROWNUM                      = 1
-- *********** 2009/08/04 N.Maeda 1.10 DEL  END  *******************--
          )
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--      UNION ALL
--      SELECT
--        rctlgda.gl_date                     gl_date,                        --売上計上日
--        rctla.extended_amount               extended_amount,                --本体金額
--        rctla.customer_trx_line_id          customer_trx_line_id            --取引明細ID
--      FROM
--        ra_customer_trx_all                 rcta,                           --請求取引情報テーブル
--        ra_customer_trx_lines_all           rctla,                          --請求取引明細テーブル
--        ra_cust_trx_line_gl_dist_all        rctlgda,                        --請求取引明細会計配分テーブル
--        ra_cust_trx_types_all               rctta                           --請求取引タイプマスタ
--      WHERE
--        rcta.ship_to_customer_id            = it_cust_account_id
--      AND rcta.customer_trx_id              = rctla.customer_trx_id
--      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--      AND rctla.line_type                   = ct_line_type_line
--      AND rcta.complete_flag                = ct_complete_flag_yes
--      AND rctlgda.gl_date                   >= id_start_gl_date
--      AND rctlgda.gl_date                   <= id_end_gl_date
--      AND rcta.org_id                       = gn_org_id
--      AND rcta.org_id                       = rctta.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Del End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--            AND flv.meaning                 = rctta.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
--      AND rcta.previous_customer_trx_id     IS NULL
--      UNION ALL
--      SELECT
--        rctlgda.gl_date                     gl_date,                        --売上計上日
--        rctla.extended_amount               extended_amount,                --本体金額
--        rctla.customer_trx_line_id          customer_trx_line_id            --取引明細ID
--      FROM
--        ra_customer_trx_all                 rcta,                           --請求取引情報テーブル
--        ra_customer_trx_lines_all           rctla,                          --請求取引明細テーブル
--        ra_cust_trx_line_gl_dist_all        rctlgda,                        --請求取引明細会計配分テーブル
--        ra_cust_trx_types_all               rctta,                          --請求取引タイプマスタ
--        ra_customer_trx_all                 rcta2,                          --請求取引情報テーブル(元)
--        ra_cust_trx_types_all               rctta2                          --請求取引タイプマスタ(元)
--      WHERE
--        rcta.ship_to_customer_id            = it_cust_account_id
--      AND rcta.customer_trx_id              = rctla.customer_trx_id
--      AND rctla.customer_trx_id             = rctlgda.customer_trx_id
--      AND rctla.customer_trx_line_id        = rctlgda.customer_trx_line_id
--      AND rcta.cust_trx_type_id             = rctta.cust_trx_type_id
--      AND rctla.line_type                   = ct_line_type_line
--      AND rcta.complete_flag                = ct_complete_flag_yes
--      AND rctlgda.gl_date                   >= id_start_gl_date
--      AND rctlgda.gl_date                   <= id_end_gl_date
--      AND rcta.org_id                       = gn_org_id
--      AND rcta.org_id                       = rctta.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Del End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type2
--            AND flv.meaning                 = rctta.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
--      AND rcta.previous_customer_trx_id     = rcta2.customer_trx_id
--      AND rcta2.cust_trx_type_id            = rctta2.cust_trx_type_id
--      AND rcta2.org_id                      = rctta2.org_id
--      AND EXISTS(
--            SELECT
--              cv_exists_flag_yes            exists_flag
--            FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----              fnd_application               fa,
----              fnd_lookup_types              flt,
---- 2009/07/16 Ver.1.9 M.Sano Del End
--              fnd_lookup_values             flv
--            WHERE
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----              fa.application_id             = flt.application_id
----            AND flt.lookup_type             = flv.lookup_type
----            AND fa.application_short_name   = ct_xxcos_appl_short_name
----            AND flv.lookup_type             = ct_qct_customer_trx_type
--              flv.lookup_type             = ct_qct_customer_trx_type
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND flv.lookup_code             LIKE ct_qcc_customer_trx_type1
--            AND flv.meaning                 = rctta2.name
--            AND rctlgda.gl_date             >= flv.start_date_active
--            AND rctlgda.gl_date             <= NVL( flv.end_date_active, gd_max_date )
--            AND flv.enabled_flag            = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----            AND flv.language                = USERENV( 'LANG' )
--            AND flv.language                = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--            AND ROWNUM                      = 1
--          )
-- 2009/07/16 Ver.1.9 M.Sano Del End
      ;
    -- AR取引情報 レコード型
    l_ar_rec ar_cur%ROWTYPE;
--
    -- AR取引情報(税金額）取得処理(A-5-2)
    CURSOR tax_cur
    IS
      SELECT
        NVL( SUM ( rctla.extended_amount ), 0 )
                                          tax_amount                       --税金額
      FROM
        ra_customer_trx_lines_all         rctla                            --請求取引明細テーブル
      WHERE
        rctla.line_type                   = ct_line_type_tax
      AND rctla.link_to_cust_trx_line_id  = l_ar_rec.customer_trx_line_id
      GROUP BY
        rctla.link_to_cust_trx_line_id
      ;
    -- AR取引情報(税金額） レコード型
    l_tax_rec tax_cur%ROWTYPE;
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
    -- 初期化
    lv_ar_exists_flag         := cv_exists_flag_no;
    ov_ar_uncalculate_type    := cv_uncalculate_type_init;
    on_ar_amount              := cn_amount_default;
    on_tax_amount             := cn_amount_default;
    ln_ar_amount              := cn_amount_default;
    ln_tax_amount             := cn_amount_default;
    --
    -- ===================================================
    --1.AR取引情報
    -- ===================================================
    <<ar_loop>>
    FOR ar_rec IN ar_cur
    LOOP
      --セット
      l_ar_rec                := ar_rec;
      -- 存在フラグ
      lv_ar_exists_flag       := cv_exists_flag_yes;
      -- ワーク用消費税額
      ln_work_tax_amount      := cn_amount_default;
      -- ===================================================
      --2.AR取引情報(税金額）
      -- ===================================================
      <<tax_loop>>
      FOR tax_rec IN tax_cur
      LOOP
        --
        l_tax_rec             := tax_rec;
        ln_work_tax_amount    := ln_work_tax_amount + l_tax_rec.tax_amount;
        --
      END LOOP tax_loop;
      -- ===================================================
      -- A-6  売上金額集計処理
      -- ===================================================
      ln_ar_amount            := ln_ar_amount + l_ar_rec.extended_amount + ln_work_tax_amount;
      ln_tax_amount           := ln_tax_amount + ln_work_tax_amount;
    --
    END LOOP ar_loop;
    -- ===================================================
    -- AR取引未計算区分セット
    -- AR取引対象件数加算
    -- ===================================================
    IF ( lv_ar_exists_flag = cv_exists_flag_no ) THEN
      ov_ar_uncalculate_type        := cv_uncalculate_type_nof;
    ELSE
      -- 対象件数２
      gn_target_cnt2                := gn_target_cnt2 + 1;
      --
      IF ( ln_ar_amount = cn_amount_default ) THEN
        ov_ar_uncalculate_type      := cv_uncalculate_type_zero;
      END IF;
    END IF;
    -- 返却
    on_ar_amount              := ln_ar_amount;
    on_tax_amount             := ln_tax_amount;
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
  END get_cust_trx;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_column
   * Description      : VDコラム別取引情報取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_vd_column(
    it_cust_account_id        IN      xxcos_vd_digestion_hdrs.cust_account_id%TYPE,
                                                                      --  1.顧客ID
    it_customer_number        IN      xxcos_vd_digestion_hdrs.customer_number%TYPE,
                                                                      --  2.顧客コード
    it_digestion_due_date     IN      xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,
                                                                      --  3.消化計算締年月日
    it_pre_digestion_due_date IN      xxcos_vd_digestion_hdrs.pre_digestion_due_date%TYPE,
                                                                      --  4.前回消化計算締年月日
    it_delivery_base_code     IN      xxcmm_cust_accounts.delivery_base_code%TYPE,
                                                                      --  5.納品拠点コード
    it_vd_digestion_hdr_id    IN      xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
                                                                      --  6.消化VD消化計算ヘッダID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
    it_sales_base_code        IN      xxcos_vd_digestion_hdrs.sales_base_code%TYPE,
                                                                      --  7.売上拠点コード
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
    ov_vdc_uncalculate_type   OUT     VARCHAR2,                       --  8.VDコラム別未計算区分
    on_vdc_amount             OUT     NUMBER,                         --  9.販売金額合計
    ot_delivery_date          OUT     xxcos_vd_column_headers.dlv_date%TYPE,
                                                                      -- 10.納品日（最新データ）
    ot_dlv_time               OUT     xxcos_vd_column_headers.dlv_time%TYPE,
                                                                      -- 11.納品時間（最新データ）
    ot_performance_by_code    OUT     xxcos_vd_column_headers.performance_by_code%TYPE,
                                                                      -- 12.成績者コード（最新データ）
    ot_change_out_time_100    OUT     xxcos_vd_column_headers.change_out_time_100%TYPE,
                                                                      -- 13.つり銭切れ時間100円（最新データ）
    ot_change_out_time_10     OUT     xxcos_vd_column_headers.change_out_time_10%TYPE,
                                                                      -- 14.つり銭切れ時間10円（最新データ）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_vd_column'; -- プログラム名
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
    lv_str_table_name                   VARCHAR2(5000);
    lv_str_key_data                     VARCHAR2(5000);
    --
    lv_vdc_exists_flag                  VARCHAR2(1);                  --存在フラグ
    ln_vdc_amount                       NUMBER;                       --販売金額合計
    ln_idx1                             NUMBER;                       --添字１
    --
    lt_vd_digestion_ln_id               xxcos_vd_digestion_lns.vd_digestion_ln_id%TYPE;
                                                                      --消化VD別消化計算明細ID
--
    -- *** ローカル・カーソル ***
    -- VDコラム別取引情報取得処理(A-7-1)
    CURSOR vdc_cur
    IS
-- == 2010/04/05 V1.15 Modified START ===============================================================
--      SELECT
---- ******************************* 2009/08/06 1.10 N.Maeda ADD START ******************************* --
--        /*+
--          INDEX( xvch XXCOS_VD_COLUMN_HEADERS_N04)
--        */
---- ******************************* 2009/08/06 1.10 N.Maeda ADD  END  ******************************* --
--        xvch.performance_by_code            performance_by_code,           --成績者コード
--        xvch.dlv_date                       dlv_date,                      --納品日
--        xvch.dlv_time                       dlv_time,                      --時間
--        xvcl.inventory_item_id              inventory_item_id,             --品目ID
--        xvcl.item_code_self                 item_code_self,                --品名コード(自社)
--        xvcl.standard_unit                  standard_unit,                 --基準単位
--        xvcl.wholesale_unit_ploce           wholesale_unit_ploce,          --卸単価
----******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
----        xvcl.quantity                       quantity,                      --数量
--        xvcl.replenish_number               replenish_number,              --補充数
----******************************** 2009/04/13 1.7 N.Maeda MOD END   **************************************************
--        xvcl.h_and_c                        h_and_c,                       --H/C
--        xvcl.column_no                      column_no,                     --コラムNo.
--        xvch.order_no_hht                   order_no_hht,                  --受注No.(HHT)
--        xvch.digestion_ln_number            digestion_ln_number,           --枝番
--        xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date,  --消化VD掛率作成済年月日
--        xvch.change_out_time_100            change_out_time_100,           --つり銭切れ時間100円
--        xvch.change_out_time_10             change_out_time_10,            --つり銭切れ時間10円
--        xvcl.sold_out_class                 sold_out_class,                --売切区分
--        xvcl.sold_out_time                  sold_out_time,                 --売切時間
----******************************** 2009/05/01 1.8 N.Maeda ADD START **************************************************
--        xvch.customer_number                customer_number                --顧客コード
----******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
--      FROM
--        xxcos_vd_column_headers             xvch,                          --VDコラム別取引ヘッダテーブル
--        xxcos_vd_column_lines               xvcl                           --VDコラム別取引ヘッダ明細テーブル
--      WHERE
--        xvch.order_no_hht                   = xvcl.order_no_hht
--      AND xvch.digestion_ln_number          = xvcl.digestion_ln_number
----******************************** 2009/05/01 1.8 N.Maeda MOD START **************************************************
----      AND xvch.customer_number              = it_customer_number
---- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--      AND xvch.customer_number              = it_customer_number
----      AND xvch.customer_number              = NVL( it_customer_number , xvch.customer_number )
---- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
----******************************** 2009/05/01 1.8 N.Maeda MOD END   **************************************************
---- 2010/03/24 Ver.1.14 Add Start
--      AND xvch.base_code                    = it_sales_base_code       -- 売上拠点コード
---- 2010/03/24 Ver.1.14 Add End
--      AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL)
--        AND ( xvch.dlv_date <= it_digestion_due_date) )
--        OR ( ( xvch.digestion_vd_rate_maked_date >= it_pre_digestion_due_date )
--        AND ( xvch.digestion_vd_rate_maked_date <= it_digestion_due_date ) ) )
--      ORDER BY
--        xvch.customer_number,                                              --顧客コード
--        xvch.dlv_date                                                      --納品日
--      ;
      SELECT  sub.performance_by_code           performance_by_code                 --  成績者コード
            , sub.dlv_date                      dlv_date                            --  納品日
            , sub.dlv_time                      dlv_time                            --  時間
            , sub.inventory_item_id             inventory_item_id                   --  品目ID
            , sub.item_code_self                item_code_self                      --  品名コード(自社)
            , sub.standard_unit                 standard_unit                       --  基準単位
            , sub.wholesale_unit_ploce          wholesale_unit_ploce                --  卸単価
            , sub.replenish_number              replenish_number                    --  補充数
            , sub.h_and_c                       h_and_c                             --  H/C
            , sub.column_no                     column_no                           --  コラムNo.
            , sub.order_no_hht                  order_no_hht                        --  受注No.(HHT)
            , sub.digestion_ln_number           digestion_ln_number                 --  枝番
            , sub.digestion_vd_rate_maked_date  digestion_vd_rate_maked_date        --  消化VD掛率作成済年月日
            , sub.change_out_time_100           change_out_time_100                 --  つり銭切れ時間100円
            , sub.change_out_time_10            change_out_time_10                  --  つり銭切れ時間10円
            , sub.sold_out_class                sold_out_class                      --  売切区分
            , sub.sold_out_time                 sold_out_time                       --  売切時間
            , sub.customer_number               customer_number                     --  顧客コード
      FROM  (
              SELECT  /*+ INDEX(xvch XXCOS_VD_COLUMN_HEADERS_N04) */
                xvch.performance_by_code            performance_by_code,            --  成績者コード
                xvch.dlv_date                       dlv_date,                       --  納品日
                xvch.dlv_time                       dlv_time,                       --  時間
                xvcl.inventory_item_id              inventory_item_id,              --  品目ID
                xvcl.item_code_self                 item_code_self,                 --  品名コード(自社)
                xvcl.standard_unit                  standard_unit,                  --  基準単位
                xvcl.wholesale_unit_ploce           wholesale_unit_ploce,           --  卸単価
                xvcl.replenish_number               replenish_number,               --  補充数
                xvcl.h_and_c                        h_and_c,                        --  H/C
                xvcl.column_no                      column_no,                      --  コラムNo.
                xvch.order_no_hht                   order_no_hht,                   --  受注No.(HHT)
                xvch.digestion_ln_number            digestion_ln_number,            --  枝番
-- 2010/05/07 Ver1.18 Add Start
                xvcl.line_no_hht                    line_no_hht,                    --  行No.(HHT)
-- 2010/05/07 Ver1.18 Add End
                xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date,   --  消化VD掛率作成済年月日
                xvch.change_out_time_100            change_out_time_100,            --  つり銭切れ時間100円
                xvch.change_out_time_10             change_out_time_10,             --  つり銭切れ時間10円
                xvcl.sold_out_class                 sold_out_class,                 --  売切区分
                xvcl.sold_out_time                  sold_out_time,                  --  売切時間
                xvch.customer_number                customer_number                 --  顧客コード
              FROM
                xxcos_vd_column_headers             xvch,                           --  VDコラム別取引ヘッダテーブル
                xxcos_vd_column_lines               xvcl                            --  VDコラム別取引ヘッダ明細テーブル
              WHERE
                xvch.order_no_hht                   = xvcl.order_no_hht
              AND xvch.digestion_ln_number          = xvcl.digestion_ln_number
              AND xvch.customer_number              = it_customer_number
              AND xvch.base_code                    = it_sales_base_code            -- 売上拠点コード
              AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL)
                AND ( xvch.dlv_date <= it_digestion_due_date) )
                OR ( ( xvch.digestion_vd_rate_maked_date >= it_pre_digestion_due_date )
                AND ( xvch.digestion_vd_rate_maked_date <= it_digestion_due_date ) ) )
              UNION
              SELECT  /*+ INDEX(xvch XXCOS_VD_COLUMN_HEADERS_N04) */
                  xvch.performance_by_code            performance_by_code             --  成績者コード
                , xvch.dlv_date                       dlv_date                        --  納品日
                , xvch.dlv_time                       dlv_time                        --  時間
                , xvcl.inventory_item_id              inventory_item_id               --  品目ID
                , xvcl.item_code_self                 item_code_self                  --  品名コード(自社)
                , xvcl.standard_unit                  standard_unit                   --  基準単位
                , xvcl.wholesale_unit_ploce           wholesale_unit_ploce            --  卸単価
                , xvcl.replenish_number               replenish_number                --  補充数
                , xvcl.h_and_c                        h_and_c                         --  H/C
                , xvcl.column_no                      column_no                       --  コラムNo.
                , xvch.order_no_hht                   order_no_hht                    --  受注No.(HHT)
                , xvch.digestion_ln_number            digestion_ln_number             --  枝番
-- 2010/05/07 Ver1.18 Add Start
                , xvcl.line_no_hht                    line_no_hht                     --  行No.(HHT)
-- 2010/05/07 Ver1.18 Add End
                , xvch.digestion_vd_rate_maked_date   digestion_vd_rate_maked_date    --  消化VD掛率作成済年月日
                , xvch.change_out_time_100            change_out_time_100             --  つり銭切れ時間100円
                , xvch.change_out_time_10             change_out_time_10              --  つり銭切れ時間10円
                , xvcl.sold_out_class                 sold_out_class                  --  売切区分
                , xvcl.sold_out_time                  sold_out_time                   --  売切時間
                , xvch.customer_number                customer_number                 --  顧客コード
              FROM
                  xxcos_vd_column_headers             xvch                            --  VDコラム別取引ヘッダテーブル
                , xxcos_vd_column_lines               xvcl                            --  VDコラム別取引ヘッダ明細テーブル
                , xxcos_vd_digestion_hdrs             xvdh                            --  消化VD用消化計算ヘッダテーブル
              WHERE   xvch.order_no_hht                   =   xvcl.order_no_hht
              AND     xvch.digestion_ln_number            =   xvcl.digestion_ln_number
              AND     xvdh.summary_data_flag              =   cv_y
              AND     xvdh.customer_number                =   it_customer_number
              AND     xvdh.sales_base_code                =   it_sales_base_code            -- 売上拠点コード
              AND     xvch.customer_number                =   xvdh.customer_number
              AND     xvch.base_code                      =   xvdh.sales_base_code
              AND     xvch.digestion_vd_rate_maked_date   =   xvdh.digestion_due_date
            )     sub
      ORDER BY
              sub.customer_number       --  顧客コード
            , sub.dlv_date              --  納品日
      ;
-- == 2010/04/05 V1.15 Modified END   ===============================================================
    -- VDコラム別取引情報 レコード型
    l_vdc_rec vdc_cur%ROWTYPE;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・プロシージャ ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    lv_vdc_exists_flag              := cv_exists_flag_no;
    ov_vdc_uncalculate_type         := cv_uncalculate_type_init;
    on_vdc_amount                   := cn_amount_default;
    ot_delivery_date                := NULL;
    ot_dlv_time                     := NULL;
    ot_performance_by_code          := NULL;
    ot_change_out_time_100          := NULL;
    ot_change_out_time_10           := NULL;
    --
    ln_vdc_amount                   := cn_amount_default;
    ln_idx1                         := 0;
    --
    -- ===================================================
    -- A-8  消化VD用消化計算情報取得処理
    -- ===================================================
    --1.保管場所情報
    IF ( ( g_chk_subinv_tab.COUNT = 0 )
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      OR ( g_chk_subinv_tab.EXISTS( it_delivery_base_code ) = FALSE ) )
      OR ( g_chk_subinv_tab.EXISTS( it_sales_base_code ) = FALSE ) )
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
    THEN
      BEGIN
        SELECT
-- ************** 2009/08/04 N.Maeda 1.10 ADD START ***************************** --
          /*+ INDEX( msi XXCOI_MSI_N02 ) */
-- ************** 2009/08/04 N.Maeda 1.10 ADD  END  ***************************** --
          msi.secondary_inventory_name        secondary_inventory_name       --保管場所
        INTO
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--          g_chk_subinv_tab(it_delivery_base_code)
          g_chk_subinv_tab(it_sales_base_code)
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        FROM
          mtl_secondary_inventories           msi                            --保管場所マスタ
        WHERE
          msi.organization_id                 = gt_organization_id
        AND EXISTS(
              SELECT
                cv_exists_flag_yes            exists_flag
              FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                fnd_application               fa,
--                fnd_lookup_types              flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                fnd_lookup_values             flv
              WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod End
--                fa.application_id             = flt.application_id
--              AND flt.lookup_type             = flv.lookup_type
--              AND fa.application_short_name   = ct_xxcos_appl_short_name
--              AND flv.lookup_type             = ct_qct_hokan_type_mst
                flv.lookup_type             = ct_qct_hokan_type_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
              AND flv.lookup_code             LIKE ct_qcc_hokan_type_mst
              AND flv.meaning                 = msi.attribute13
              AND it_digestion_due_date       >= flv.start_date_active
              AND it_digestion_due_date       <= NVL( flv.end_date_active, gd_max_date )
              AND flv.enabled_flag            = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--              AND flv.language                = USERENV( 'LANG' )
              AND flv.language                = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ***************************** --
--              AND ROWNUM                      = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ***************************** --
            )
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--        AND msi.attribute7                    = it_delivery_base_code
        AND msi.attribute7                    = it_sales_base_code
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        AND it_digestion_due_date             < NVL( msi.disable_date, gd_max_date )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --保管場所マスタ文字列取得
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_subinv_mst
                                     );
          --キー情報文字列取得
          lv_str_key_data         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info2,
                                       iv_token_name1       => cv_tkn_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--                                       iv_token_value1      => it_delivery_base_code,
                                       iv_token_value1      => it_sales_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
                                       iv_token_name2       => cv_tkn_organization_code,
                                       iv_token_value2      => gt_organization_code
                                     );
          RAISE global_select_data_expt;
      END;
    ELSE
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      IF ( g_chk_subinv_tab(it_delivery_base_code) IS NULL ) THEN
      IF ( g_chk_subinv_tab(it_sales_base_code) IS NULL ) THEN
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
        --保管場所マスタ文字列取得
        lv_str_table_name         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_subinv_mst
                                     );
        --キー情報文字列取得
        lv_str_key_data           := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info2,
                                       iv_token_name1       => cv_tkn_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--                                       iv_token_value1      => it_delivery_base_code,
                                       iv_token_value1      => it_sales_base_code,
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
                                       iv_token_name2       => cv_tkn_organization_code,
                                       iv_token_value2      => gt_organization_code
                                     );
        RAISE global_select_data_expt;
      END IF;
    END IF;
    --
    -- ===================================================
    --1.VDコラム別取引情報
    -- ===================================================
    <<get_vdc_loop>>
    FOR vdc_rec IN vdc_cur
    LOOP
      --
      l_vdc_rec                         := vdc_rec;
      --存在フラグ
      lv_vdc_exists_flag                := cv_exists_flag_yes;
      --最新情報セット
      ot_delivery_date                  := l_vdc_rec.dlv_date;
      ot_dlv_time                       := l_vdc_rec.dlv_time;
      ot_performance_by_code            := l_vdc_rec.performance_by_code;
      ot_change_out_time_100            := l_vdc_rec.change_out_time_100;
      ot_change_out_time_10             := l_vdc_rec.change_out_time_10;
      --
      -- ===================================================
      -- A-8  消化VD用消化計算情報取得処理
      -- ===================================================
      --2.品目マスタ情報
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--      IF ( ( g_chk_fixed_price_tab.COUNT = 0 )
--        OR ( g_chk_fixed_price_tab.EXISTS( l_vdc_rec.item_code_self ) = FALSE ) )
--      THEN
--        BEGIN
--          SELECT
--            xsibh.fixed_price                     fixed_price                      --定価
--          INTO
--            g_chk_fixed_price_tab(l_vdc_rec.item_code_self)
--          FROM
--            (
--              SELECT
--                xsibh.fixed_price                 fixed_price                      --定価
--              FROM
--                xxcmm_system_items_b_hst          xsibh                            --品目営業履歴アドオンマスタ
--              WHERE
--                xsibh.item_code                   = l_vdc_rec.item_code_self
--              AND xsibh.apply_date                <= it_digestion_due_date
--              AND xsibh.apply_flag                = ct_apply_flag_yes
--              AND xsibh.fixed_price               IS NOT NULL
--              ORDER BY
--                xsibh.apply_date                  desc
--            ) xsibh
--          WHERE
--            ROWNUM                                = 1
--          ;
--        EXCEPTION
--          WHEN OTHERS THEN
--            --品目マスタ文字列取得
--            lv_str_table_name           := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_item_mst
--                                           );
--            --キー情報文字列取得
--            lv_str_key_data             := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_key_info3,
--                                             iv_token_name1       => cv_tkn_item_code,
--                                             iv_token_value1      => l_vdc_rec.item_code_self,
--                                             iv_token_name2       => cv_tkn_apply_date,
--                                             iv_token_value2      => TO_CHAR( it_digestion_due_date , cv_fmt_date )
--                                           );
--            RAISE global_select_data_expt;
--        END;
--        --
--      ELSE
--        IF ( g_chk_fixed_price_tab(l_vdc_rec.item_code_self) IS NULL ) THEN
--          --品目マスタ文字列取得
--          lv_str_table_name             := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_item_mst
--                                           );
--          --キー情報文字列取得
--          lv_str_key_data               := xxccp_common_pkg.get_msg(
--                                             iv_application       => ct_xxcos_appl_short_name,
--                                             iv_name              => ct_msg_key_info2,
--                                             iv_token_name1       => cv_tkn_item_code,
--                                             iv_token_value1      => l_vdc_rec.item_code_self,
--                                             iv_token_name2       => cv_tkn_apply_date,
--                                             iv_token_value2      => TO_CHAR( it_digestion_due_date , cv_fmt_date )
--                                           );
--          RAISE global_select_data_expt;
--        END IF;
--      END IF;
-- 2009/07/16 Ver.1.9 M.Sano Del End
      -- ===================================================
      -- 消化VD用消化計算明細登録用セット処理
      -- ===================================================
      ln_idx1                           := ln_idx1 + 1;
      gn_xvdl_idx                       := gn_xvdl_idx + 1;
      -- レコードIDの取得
      BEGIN
        SELECT
          xxcos_vd_digestion_lns_s01.NEXTVAL      vd_digestion_ln_id
        INTO
          lt_vd_digestion_ln_id
        FROM
          dual
        ;
      END;
      --
      g_xvdl_tab(gn_xvdl_idx).vd_digestion_ln_id      := lt_vd_digestion_ln_id;
      g_xvdl_tab(gn_xvdl_idx).vd_digestion_hdr_id     := it_vd_digestion_hdr_id;
--******************************** 2009/05/01 1.8 N.Maeda ADD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).customer_number         := it_customer_number;
      g_xvdl_tab(gn_xvdl_idx).customer_number         := l_vdc_rec.customer_number;
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      g_xvdl_tab(gn_xvdl_idx).digestion_due_date      := it_digestion_due_date;
      g_xvdl_tab(gn_xvdl_idx).digestion_ln_number     := ln_idx1;
      g_xvdl_tab(gn_xvdl_idx).item_code               := l_vdc_rec.item_code_self;
      g_xvdl_tab(gn_xvdl_idx).inventory_item_id       := l_vdc_rec.inventory_item_id;
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--      g_xvdl_tab(gn_xvdl_idx).item_price              := g_chk_fixed_price_tab(l_vdc_rec.item_code_self);
      g_xvdl_tab(gn_xvdl_idx).item_price              := NULL;
-- 2009/07/16 Ver.1.9 M.Sano Mod End
      g_xvdl_tab(gn_xvdl_idx).unit_price              := l_vdc_rec.wholesale_unit_ploce;
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).item_sales_amount       := l_vdc_rec.wholesale_unit_ploce
--                                                         * l_vdc_rec.quantity;
      g_xvdl_tab(gn_xvdl_idx).item_sales_amount       := l_vdc_rec.wholesale_unit_ploce
                                                        * l_vdc_rec.replenish_number;
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).uom_code                := l_vdc_rec.standard_unit;
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).sales_quantity          := l_vdc_rec.quantity;
      g_xvdl_tab(gn_xvdl_idx).sales_quantity          := l_vdc_rec.replenish_number;
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).hot_cold_type           := l_vdc_rec.h_and_c;
      g_xvdl_tab(gn_xvdl_idx).column_no               := l_vdc_rec.column_no;
      g_xvdl_tab(gn_xvdl_idx).delivery_base_code      := it_delivery_base_code;
--******************************** 2009/03/19 1.6 T.Kitajima MOD START **************************************************
--      g_xvdl_tab(gn_xvdl_idx).ship_from_subinventory_code
--                                                      := g_chk_subinv_tab(it_delivery_base_code);
      g_xvdl_tab(gn_xvdl_idx).ship_from_subinventory_code
                                                      := g_chk_subinv_tab(it_sales_base_code);
--******************************** 2009/03/19 1.6 T.Kitajima MOD  END  **************************************************
      g_xvdl_tab(gn_xvdl_idx).sold_out_class          := l_vdc_rec.sold_out_class;
      g_xvdl_tab(gn_xvdl_idx).sold_out_time           := l_vdc_rec.sold_out_time;
      --WHOカラム
      g_xvdl_tab(gn_xvdl_idx).created_by              := cn_created_by;
      g_xvdl_tab(gn_xvdl_idx).creation_date           := cd_creation_date;
      g_xvdl_tab(gn_xvdl_idx).last_updated_by         := cn_last_updated_by;
      g_xvdl_tab(gn_xvdl_idx).last_update_date        := cd_last_update_date;
      g_xvdl_tab(gn_xvdl_idx).last_update_login       := cn_last_update_login;
      g_xvdl_tab(gn_xvdl_idx).request_id              := cn_request_id;
      g_xvdl_tab(gn_xvdl_idx).program_application_id  := cn_program_application_id;
      g_xvdl_tab(gn_xvdl_idx).program_id              := cn_program_id;
      g_xvdl_tab(gn_xvdl_idx).program_update_date     := cd_program_update_date;
      --
      -- ===================================================
      -- A-10 チェック用売上金額集計処理
      -- ===================================================
--******************************** 2009/04/13 1.7 N.Maeda MOD START **************************************************
--      ln_vdc_amount := ln_vdc_amount + ( l_vdc_rec.quantity * l_vdc_rec.wholesale_unit_ploce );
      ln_vdc_amount := ln_vdc_amount + ( l_vdc_rec.replenish_number * l_vdc_rec.wholesale_unit_ploce );
--******************************** 2009/04/13 1.7 N.Maeda MOD  END  **************************************************
      --
    END LOOP get_vdc_loop;
    -- ===================================================
    -- VDコラム別取引未計算区分セット
    -- VDコラム別取引対象件数加算
    -- ===================================================
    IF ( lv_vdc_exists_flag = cv_exists_flag_no ) THEN
      ov_vdc_uncalculate_type       := cv_uncalculate_type_nof;
    ELSE
      -- 対象件数３
      gn_target_cnt3                := gn_target_cnt3 + 1;
      --
      IF ( ln_vdc_amount = cn_amount_default ) THEN
        ov_vdc_uncalculate_type     := cv_uncalculate_type_zero;
      END IF;
    END IF;
    -- 返却
    on_vdc_amount              := ln_vdc_amount;
--
  EXCEPTION
    -- *** 保管場所マスタ取得例外ハンドラ ***
    -- *** 品目マスタ取得例外ハンドラ ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
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
  END get_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_digestion_hdrs
   * Description      : 消化VD消化計算ヘッダ登録処理(A-12)
   ***********************************************************************************/
  PROCEDURE ins_vd_digestion_hdrs(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_digestion_hdrs'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
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
    --==================================
    -- 1.消化VD消化計算ヘッダ登録処理
    --==================================
    BEGIN
      FORALL i IN 1..g_xvdh_tab.COUNT
      INSERT INTO
        xxcos_vd_digestion_hdrs
      VALUES
        g_xvdh_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- 正常件数
    gn_normal_cnt := gn_normal_cnt + g_xvdh_tab.COUNT;
--
  EXCEPTION
    -- *** 消化VD消化計算ヘッダテーブル登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      --消化VD用消化計算ヘッダテーブル文字列取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvdh_tblnm
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_vd_digestion_hdrs;
--
  /**********************************************************************************
   * Procedure Name   : ins_vd_digestion_lns
   * Description      : 消化VD消化計算明細登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_vd_digestion_lns(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_vd_digestion_lns'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
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
    --==================================
    -- 1.消化VD消化計算明細登録処理
    --==================================
    BEGIN
      FORALL i IN 1..g_xvdl_tab.COUNT
      INSERT INTO
        xxcos_vd_digestion_lns
      VALUES
        g_xvdl_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
  EXCEPTION
    -- *** 消化VD消化計算明細テーブル登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      --消化VD用消化計算明細テーブル文字列取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvdl_tblnm
                                 );
      --キー情報文字列取得
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_vd_digestion_lns;
--
  /**********************************************************************************
   * Procedure Name   : upd_vd_column_hdr
   * Description      : VDカラム別取引ヘッダ更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE upd_vd_column_hdr(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_vd_column_hdr'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    ln_idx                        NUMBER;
--
    -- *** ローカル・カーソル ***
    -- VDコラム別取引ヘッダテーブル カーソル
    --
    CURSOR xvch_cur(
      it_customer_number          IN    xxcos_vd_digestion_hdrs.customer_number%TYPE,
      id_digestion_due_date       IN    DATE,
      id_pre_digestion_due_date   IN    DATE
-- 2010/03/24 Ver.1.14 Add Start
      ,iv_sales_base_code         IN    xxcos_vd_digestion_hdrs.sales_base_code%TYPE
-- 2010/03/24 Ver.1.14 Add End
    )
    IS
      SELECT
        xvch.order_no_hht                 order_no_hht,                    --受注No.(hht)
        xvch.digestion_ln_number          digestion_ln_number              --枝番
      FROM
        xxcos_vd_column_headers           xvch                             --VDコラム別取引ヘッダテーブル
      WHERE
        xvch.customer_number                    = it_customer_number
-- 2010/03/24 Ver.1.14 Add Start
      AND xvch.base_code                     = iv_sales_base_code
-- 2010/03/24 Ver.1.14 Add End
      AND ( ( ( xvch.digestion_vd_rate_maked_date IS NULL )
        AND ( id_digestion_due_date             >= xvch.dlv_date ) )
        OR ( ( NVL( id_pre_digestion_due_date + cn_one_day, gd_min_date )
                                                <= xvch.digestion_vd_rate_maked_date )
          AND ( id_digestion_due_date           >= xvch.digestion_vd_rate_maked_date ) ) )
      FOR UPDATE NOWAIT;
    -- VDコラム別取引ヘッダテーブル レコード型
    l_xvch_rec xvch_cur%ROWTYPE;
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
    <<xvch_tab_loop>>
    FOR i IN 1..g_xvch_tab.COUNT LOOP
      ln_idx := i;
      --VDコラム別取引ヘッダテーブル
      <<xvch_loop>>
      FOR xvch_rec IN xvch_cur(
                        it_customer_number        => g_xvch_tab(ln_idx).customer_number,
                        id_digestion_due_date     => g_xvch_tab(ln_idx).digestion_due_date,
                        id_pre_digestion_due_date => g_xvch_tab(ln_idx).pre_digestion_due_date
-- 2010/03/24 Ver.1.14 Add Start
                        ,iv_sales_base_code        => g_xvch_tab(ln_idx).sales_base_code
-- 2010/03/24 Ver.1.14 Add End
                      )
      LOOP
        --
        l_xvch_rec := xvch_rec;
        --VDコラム別取引ヘッダテーブル 更新
        BEGIN
          UPDATE
            xxcos_vd_column_headers              xvch
          SET
            xvch.digestion_vd_rate_maked_date    = g_xvch_tab(ln_idx).digestion_due_date,
            xvch.last_updated_by                 = cn_last_updated_by,
            xvch.last_update_date                = cd_last_update_date,
            xvch.last_update_login               = cn_last_update_login,
            xvch.request_id                      = cn_request_id,
            xvch.program_application_id          = cn_program_application_id,
            xvch.program_id                      = cn_program_id,
            xvch.program_update_date             = cd_program_update_date
          WHERE
            xvch.order_no_hht                    = l_xvch_rec.order_no_hht
          AND xvch.digestion_ln_number           = l_xvch_rec.digestion_ln_number
          ;
        EXCEPTION
          WHEN OTHERS THEN
            --VDカラム別取引ヘッダテーブル文字列取得
            lv_str_table_name       := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_xvch_tblnm
                                       );
            --キー情報文字列取得
            lv_str_key_data         := xxccp_common_pkg.get_msg(
                                         iv_application        => ct_xxcos_appl_short_name,
                                         iv_name               => ct_msg_key_info3,
                                         iv_token_name1        => cv_tkn_order_no_hht,
                                         iv_token_value1       => TO_NUMBER( l_xvch_rec.order_no_hht ),
                                         iv_token_name2        => cv_tkn_digestion_ln_number,
                                         iv_token_value2       => TO_NUMBER( l_xvch_rec.digestion_ln_number )
                                       );
            RAISE global_update_data_expt;
        END;
      --
      END LOOP xvch_loop;
    --
    END LOOP xvch_tab_loop;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      --テーブル名取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_xvch_tblnm
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** VDカラム別取引ヘッダテーブル更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_update_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END upd_vd_column_hdr;
  /**********************************************************************************
   * Procedure Name   : get_operation_day
   * Description      : 稼働日情報取得処理 (A-13)
   ***********************************************************************************/
  PROCEDURE get_operation_day(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_operation_day'; -- プログラム名
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
    lv_str_api_name               VARCHAR2(5000);
    --
    ln_idx                        NUMBER;
    ln_sales_oprtn_day            NUMBER;
/* 2010/01/19 Ver1.11 Add Start */
    ln_process_oprtn_flag         NUMBER;    -- 稼動日フラグ(業務日付)
    ld_process_date_work           DATE;     -- 作業用業務日付
/* 2010/01/19 Ver1.11 Add End */
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
    --初期化
    ln_idx                              := g_diges_due_dt_tab.COUNT;
    gd_calc_digestion_due_date          := gd_temp_digestion_due_date;
/* 2010/01/19 Ver1.11 Add Start */
    -- 業務日付の稼動日チェック
    ln_process_oprtn_flag               := xxcos_common_pkg.check_sales_oprtn_day(
                                              id_check_target_date     => gd_process_date,
                                              iv_calendar_code         => gt_calendar_code
                                            );
    --
    -- 業務日付の稼動日判定
    IF ( ln_process_oprtn_flag = cn_sales_oprtn_day_non ) THEN
      -- 非稼動日の場合、直近過去日付の業務日付を取得
      ld_process_date_work   := gd_process_date;
      <<oprtn_process_day_loop>>
      WHILE ( ln_process_oprtn_flag = cn_sales_oprtn_day_non ) LOOP
        ld_process_date_work := ld_process_date_work - 1;
        -- 稼動日チェック
        ln_process_oprtn_flag               := xxcos_common_pkg.check_sales_oprtn_day(
                                                  id_check_target_date     => ld_process_date_work,
                                                  iv_calendar_code         => gt_calendar_code
                                                );
        IF ( ( ln_process_oprtn_flag != cn_sales_oprtn_day_normal )
             AND ( ln_process_oprtn_flag != cn_sales_oprtn_day_non)
           )
        THEN
          -- エラーの場合
          RAISE global_call_api_expt;
        END IF;
      END LOOP oprtn_process_day_loop;
      --
      -- 消化計算締年月日を再設定
      gd_calc_digestion_due_date := ld_process_date_work - gn_diges_calc_delay_day;
    ELSIF ( ln_process_oprtn_flag = cn_sales_oprtn_day_normal ) THEN
      --稼働日の場合
      ld_process_date_work   := gd_process_date;
    ELSE
      --エラーの場合
      RAISE global_call_api_expt;
    END IF;
    --
/* 2010/01/19 Ver1.11 Add End */
    --稼働日チェック
    ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                             id_check_target_date     => gd_calc_digestion_due_date,
                                             iv_calendar_code         => gt_calendar_code
                                           );
    --稼働日判定
    IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
      --稼働日の場合
      ln_idx                            := ln_idx + 1;
      g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
/* 2010/01/19 Ver1.11 Del Start */
--      --==========================================
--      --非稼働日分内部テーブルにセットする。
--      --==========================================
--      --初期化
--      ln_sales_oprtn_day := cn_sales_oprtn_day_non;
--      --
--      <<oprtn_day_loop>>
--      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
--         --前日を求める。
--        gd_calc_digestion_due_date      := gd_calc_digestion_due_date - 1;
--         --稼働日チェック
--        ln_sales_oprtn_day              := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--        --稼働日判定
--        IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--          --稼働日の場合
--          NULL;
--        ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--          --非稼働日の場合
--          ln_idx                        := ln_idx + 1;
--          g_diges_due_dt_tab(ln_idx)    := gd_calc_digestion_due_date;
--        ELSE
--          --エラーの場合
--          RAISE global_call_api_expt;
--        END IF;
--      --
--      END LOOP oprtn_day_loop;
/* 2010/01/19 Ver1.11 Del End */
      --
    ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
      --非稼働日の場合
/* 2010/01/19 Ver1.11 Mod Start */
      --============================================================
      --非稼働日を含め直近過去稼動日までを内部テーブルにセットする。
      --============================================================
      ln_idx                            := ln_idx + 1;
      g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
      --
      <<oprtn_day_loop>>
      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
        -- 前日を求める
        gd_calc_digestion_due_date        := gd_calc_digestion_due_date - 1;
        ln_idx                            := ln_idx + 1;
        g_diges_due_dt_tab(ln_idx)        := gd_calc_digestion_due_date;
        --
        -- 稼動日チェック
        ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
                                                 id_check_target_date     => gd_calc_digestion_due_date,
                                                 iv_calendar_code         => gt_calendar_code
                                               );
        IF ( ( ln_sales_oprtn_day != cn_sales_oprtn_day_normal )
             AND ( ln_sales_oprtn_day != cn_sales_oprtn_day_non)
           )
        THEN
          -- エラーの場合
          RAISE global_call_api_expt;
        END IF;
      END LOOP oprtn_day_loop;
      --
--      NULL;
/* 2010/01/19 Ver1.11 Mod Start */
    ELSE
      --エラーの場合
      RAISE global_call_api_expt;
    END IF;
/* 2010/01/19 Ver1.11 Mod End */
--
  EXCEPTION
    -- *** 共通関数エラー例外ハンドラ ***
    WHEN global_call_api_expt THEN
      --販売用稼働日チェック共通関数文字列取得
      lv_str_api_name         := xxccp_common_pkg.get_msg(
                                   iv_application           => ct_xxcos_appl_short_name,
                                   iv_name                  => ct_msg_operation_day
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_str_api_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_operation_day;
--
/* 2010/01/19 Ver1.11 Del Start */
--  /**********************************************************************************
--   * Procedure Name   : get_non_operation_day
--   * Description      : 非稼働日情報取得処理 (A-14)
--   ***********************************************************************************/
--  PROCEDURE get_non_operation_day(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_non_operation_day'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    lv_str_api_name               VARCHAR2(5000);
--    --
--    ln_idx                        NUMBER;
--    ln_sales_oprtn_day            NUMBER;
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    --初期化
--    ln_idx                              := g_diges_due_dt_tab.COUNT;
--    --稼働日チェック
--    ln_sales_oprtn_day                  := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--    --稼働日判定
--    IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--      --稼働日の場合
--      NULL;
--    ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--      --非稼働日の場合
--      --==========================================
--      --非稼働日を読み飛ばす。
--      --==========================================
--      --初期化
--      ln_sales_oprtn_day := cn_sales_oprtn_day_non;
--      --
--      <<non_oprtn_day_loop>>
--      WHILE ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) LOOP
--         --前日を求める。
--        gd_calc_digestion_due_date      := gd_calc_digestion_due_date - 1;
--         --稼働日チェック
--        ln_sales_oprtn_day              := xxcos_common_pkg.check_sales_oprtn_day(
--                                             id_check_target_date     => gd_calc_digestion_due_date,
--                                             iv_calendar_code         => gt_calendar_code
--                                           );
--        --稼働日判定
--        IF ( ln_sales_oprtn_day = cn_sales_oprtn_day_normal ) THEN
--          --稼働日の場合
--          ln_idx                        := ln_idx + 1;
--          g_diges_due_dt_tab(ln_idx)    := gd_calc_digestion_due_date;
--        ELSIF ( ln_sales_oprtn_day = cn_sales_oprtn_day_non ) THEN
--          --非稼働日の場合
--          NULL;
--        ELSE
--          --エラーの場合
--          RAISE global_call_api_expt;
--        END IF;
--      --
--      END LOOP non_oprtn_day_loop;
--      --
--    ELSE
--      --エラーの場合
--      RAISE global_call_api_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** 共通関数エラー例外ハンドラ ***
--    WHEN global_call_api_expt THEN
--      --販売用稼働日チェック共通関数文字列取得
--      lv_str_api_name         := xxccp_common_pkg.get_msg(
--                                   iv_application           => ct_xxcos_appl_short_name,
--                                   iv_name                  => ct_msg_operation_day
--                                 );
--      --
--      ov_errmsg               := xxccp_common_pkg.get_msg(
--                                   iv_application        => ct_xxcos_appl_short_name,
--                                   iv_name               => ct_msg_call_api_err,
--                                   iv_token_name1        => cv_tkn_api_name,
--                                   iv_token_value1       => lv_str_api_name
--                                 );
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
--      ov_retcode := cv_status_error;
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END get_non_operation_day;
/* 2010/01/19 Ver1.11 Del End */
--
  /**********************************************************************************
   * Procedure Name   : del_blt_vd_digestion
   * Description      : 消化VD用消化計算情報の前々回データ削除(A-15)
   ***********************************************************************************/
  PROCEDURE del_blt_vd_digestion(
    it_digestion_due_date     IN      xxcos_vd_digestion_hdrs.digestion_due_date%TYPE,
                                                                      --  1.消化計算締年月日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_blt_vd_digestion'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
    --キー項目
    lt_key_customer_number        xxcos_vd_digestion_hdrs.customer_number%TYPE;
--
    -- *** ローカル・カーソル ***
    --======================================================
    -- データ抽出
    --======================================================
    CURSOR blt_cur
    IS
      SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
        /*+
          INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
        */
-- ***************** 2009/08/06 1.10 N.Maeda END START ************************** --
        xvdh.customer_number              customer_number,            -- 顧客コード
        xvdh.digestion_due_date           digestion_due_date,         -- 消化計算締年月日
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id,        -- 消化VD用消化計算ヘッダID
        xvdh.cust_account_id              cust_account_id             -- 顧客ID
      FROM
        xxcos_vd_digestion_hdrs           xvdh                        -- 消化VD用消化計算ヘッダテーブル
      WHERE
        xvdh.digestion_due_date           < it_digestion_due_date
-- == 2010/04/05 V1.15 Modified START ===============================================================
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
      AND xvdh.sales_result_creation_flag NOT IN(cv_skip_flag, cv_delete_flag)
-- == 2010/04/05 V1.15 Modified END   ===============================================================
      AND xvdh.sales_result_creation_flag = ct_sr_creation_flag_yes
      ORDER BY
        xvdh.customer_number              asc,                        -- 顧客コード
        xvdh.digestion_due_date           desc                        -- 消化計算締年月日
      FOR UPDATE NOWAIT
      ;
    --
    --======================================================
    -- 1.消化VD情報データロック
    --======================================================
    CURSOR lock_cur(
      it_vd_digestion_hdr_id            xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE
    )
    IS
      SELECT
        xvdh.vd_digestion_hdr_id          vd_digestion_hdr_id         -- 消化VD用消化計算ヘッダID
      FROM
        xxcos_vd_digestion_hdrs           xvdh,                       -- 消化VD用消化計算ヘッダテーブル
        xxcos_vd_digestion_lns            xvdl                        -- 消化VD用消化計算明細テーブル
      WHERE
          xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
      AND xvdh.vd_digestion_hdr_id        = xvdl.vd_digestion_hdr_id  (+)
-- == 2010/04/05 V1.15 Modified START ===============================================================
--/* 2010/01/25 Ver1.11 Add Start */
--      AND xvdh.sales_result_creation_flag <> cv_delete_flag
--/* 2010/01/25 Ver1.11 Add Start */
      AND xvdh.sales_result_creation_flag NOT IN(cv_skip_flag, cv_delete_flag)
-- == 2010/04/05 V1.15 Modified END   ===============================================================
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    l_blt_rec  blt_cur%ROWTYPE;
--
    l_lock_rec lock_cur%ROWTYPE;
--
    -- *** ローカル・関数 ***
--
    --======================================================
    -- 2.消化VD別消化計算ヘッダテーブル削除
    --======================================================
    PROCEDURE del_vd_digestion_hdrs(
      it_vd_digestion_hdr_id            xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE,
      it_customer_number                xxcos_vd_digestion_hdrs.customer_number%TYPE,
      it_digestion_due_date             xxcos_vd_digestion_hdrs.digestion_due_date%TYPE
    )
    AS
    BEGIN
/* 2010/01/25 Ver1.11 Mod Start */
      UPDATE
        xxcos_vd_digestion_hdrs         xvdh
      SET
        xvdh.sales_result_creation_flag      = cv_delete_flag,              -- 販売実績作成済みフラグ
        xvdh.last_updated_by                 = cn_last_updated_by,
        xvdh.last_update_date                = cd_last_update_date,
        xvdh.last_update_login               = cn_last_update_login,
        xvdh.request_id                      = cn_request_id,
        xvdh.program_application_id          = cn_program_application_id,
        xvdh.program_id                      = cn_program_id,
        xvdh.program_update_date             = cd_program_update_date
      WHERE
        xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
      ;
--      DELETE FROM
--        xxcos_vd_digestion_hdrs         xvdh
--      WHERE
--        xvdh.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
--      ;
/* 2010/01/25 Ver1.11 Mod End */
    EXCEPTION
      WHEN OTHERS THEN
        --消化VD別消化計算ヘッダテーブル文字列取得
        lv_str_table_name       := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_blt_xvdh_tblnm
                                   );
        --キー情報文字列取得
        lv_str_key_data         := xxccp_common_pkg.get_msg(
                                     iv_application        => ct_xxcos_appl_short_name,
                                     iv_name               => ct_msg_key_info1,
                                     iv_token_name1        => cv_tkn_diges_due_dt,
                                     iv_token_value1       => TO_CHAR( it_digestion_due_date, cv_fmt_date ),
                                     iv_token_name2        => cv_tkn_cust_code,
                                     iv_token_value2       => it_customer_number
                                   );
        --
        RAISE global_delete_data_expt;
    --
    END;
--
/* 2010/01/25 Ver1.11 Del Start */
--    --======================================================
--    -- 3.消化VD別消化計算明細テーブル削除
--    --======================================================
--    PROCEDURE del_vd_digestion_lns(
--      it_vd_digestion_hdr_id            xxcos_vd_digestion_lns.vd_digestion_hdr_id%TYPE,
--      it_customer_number                xxcos_vd_digestion_hdrs.customer_number%TYPE,
--      it_digestion_due_date             xxcos_vd_digestion_hdrs.digestion_due_date%TYPE
--    )
--    AS
--    BEGIN
--      DELETE FROM
--        xxcos_vd_digestion_lns          xvdl
--      WHERE
--        xvdl.vd_digestion_hdr_id        = it_vd_digestion_hdr_id
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        --消化VD別消化計算明細テーブル文字列取得
--        lv_str_table_name       := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => ct_msg_blt_xvdl_tblnm
--                                   );
--        --キー情報文字列取得
--        lv_str_key_data         := xxccp_common_pkg.get_msg(
--                                     iv_application        => ct_xxcos_appl_short_name,
--                                     iv_name               => ct_msg_key_info1,
--                                     iv_token_name1        => cv_tkn_diges_due_dt,
--                                     iv_token_value1       => TO_CHAR( it_digestion_due_date, cv_fmt_date ),
--                                     iv_token_name2        => cv_tkn_cust_code,
--                                     iv_token_value2       => it_customer_number
--                                   );
--        --
--        RAISE global_delete_data_expt;
--    --
--    END;
/* 2010/01/25 Ver1.11 Del End */
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- データ抽出
    --==================================
    lt_key_customer_number              := NULL;
    --
    <<blt_loop>>
    FOR blt_rec IN blt_cur LOOP
      --
      l_blt_rec := blt_rec;
      --
      IF ( lt_key_customer_number IS NULL ) THEN
        lt_key_customer_number        := l_blt_rec.customer_number;
      ELSIF ( lt_key_customer_number = l_blt_rec.customer_number ) THEN
        --================================================
        -- 1.消化VD情報データロック
        --================================================
        BEGIN
          OPEN lock_cur( it_vd_digestion_hdr_id => l_blt_rec.vd_digestion_hdr_id );
          CLOSE lock_cur;
        EXCEPTION
          WHEN global_data_lock_expt THEN
            RAISE global_data_lock_expt;
        END;
        --
        --================================================
        -- 2.消化VD別消化計算ヘッダテーブル削除
        --================================================
        del_vd_digestion_hdrs(
          it_vd_digestion_hdr_id      => l_blt_rec.vd_digestion_hdr_id,
          it_customer_number          => l_blt_rec.customer_number,
          it_digestion_due_date       => it_digestion_due_date
        );
/* 2010/01/25 Ver1.11 Del Start */
--        --================================================
--        -- 3.消化VD別消化計算明細テーブル削除
--        --================================================
--        del_vd_digestion_lns(
--          it_vd_digestion_hdr_id      => l_blt_rec.vd_digestion_hdr_id,
--          it_customer_number          => l_blt_rec.customer_number,
--          it_digestion_due_date       => it_digestion_due_date
--        );
/* 2010/01/25 Ver1.11 Del End */
      ELSE
        lt_key_customer_number        := l_blt_rec.customer_number;
      END IF;
    --
    END LOOP blt_loop;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      --テーブル名取得
      lv_str_table_name       := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_blt_diges_info_tblnm
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_lock_err,
                                   iv_token_name1        => cv_tkn_table,
                                   iv_token_value1       => lv_str_table_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
/* 2010/01/25 Ver1.11 Mod Start */
                                   iv_name               => ct_msg_update_data_err,
--                                   iv_name               => ct_msg_delete_data_err,
/* 2010/01/25 Ver1.11 Mod End */
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_blt_vd_digestion;
--
  /**********************************************************************************
   * Procedure Name   : calc_due_day
   * Description      : 締日算出処理(A-16)
   ***********************************************************************************/
  PROCEDURE calc_due_day(
    id_digestion_due_date     IN      DATE,                           --  1.消化計算締年月日
    ov_due_day                OUT     VARCHAR2,                       --  2.締日
    ov_last_day               OUT     VARCHAR2,                       --  3.月末日
    ov_leap_year_due_day      OUT     VARCHAR2,                       --  4.閏年締日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_due_day'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.締日の算出
    --==================================
    ov_due_day                := TO_CHAR( id_digestion_due_date, 'DD' );
    --
    --==================================
    -- 2.月末日の算出
    --==================================
    ov_last_day               := TO_CHAR( LAST_DAY( id_digestion_due_date ), 'DD' );
    --
    --==================================
    -- 1.閏年締日の算出
    --==================================
    IF ( ( TO_CHAR( id_digestion_due_date, 'MM' ) = cv_month_february )
      AND ( ov_last_day = cv_last_day_29 ) )
    THEN
      ov_leap_year_due_day    := cv_last_day_29;
    ELSIF ( ( TO_CHAR( id_digestion_due_date, 'MM' ) = cv_month_february )
      AND ( ov_last_day = cv_last_day_28 ) )
    THEN
      ov_leap_year_due_day    := cv_last_day_28;
    ELSE
      ov_leap_year_due_day    := cv_last_day_29;
    END IF;
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
  END calc_due_day;
--
  /**********************************************************************************
   * Procedure Name   : calc_pre_diges_due_dt
   * Description      : 前回消化計算締年月日算出処理(A-18)
   ***********************************************************************************/
  PROCEDURE calc_pre_diges_due_dt(
    it_cust_account_id        IN      hz_cust_accounts.cust_account_id%TYPE,
                                                                      --  1.顧客ID
    it_customer_number        IN      hz_cust_accounts.account_number%TYPE,
                                                                      --  2.顧客コード
    id_digestion_due_date     IN      DATE,                           --  3.消化計算締年月日
    id_stop_approval_date     IN      DATE,                           --  4.中止決裁日
    od_pre_digestion_due_date OUT     DATE,                           --  5.前回消化計算締年月日
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_pre_diges_due_dt'; -- プログラム名
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
    lv_str_table_name             VARCHAR2(5000);
    lv_str_key_data               VARCHAR2(5000);
--
    ld_pre_digestion_due_date    DATE;
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --
    ld_pre_digestion_due_date          := NULL;
    --
    IF ( ( g_get_pre_diges_due_dt_tab.COUNT = 0 )
      OR ( g_get_pre_diges_due_dt_tab.EXISTS( it_cust_account_id ) = FALSE ) )
    THEN
      --============================================
      -- 1.消化VD別消化計算ヘッダテーブルより
      --   前回消化計算締年月日取得
      --============================================
      BEGIN
        SELECT
-- == 2010/04/05 V1.15 Modified START ===============================================================
          MAX(xvdh.digestion_due_date)                 last_digestion_due_date
--          xvdh.digestion_due_date                 last_digestion_due_date
-- == 2010/04/05 V1.15 Modified END ===============================================================
        INTO
          g_get_pre_diges_due_dt_tab(it_cust_account_id)
        FROM
          (
            -- 消化計算された消化計算締年月日
            SELECT
              xvdh.digestion_due_date             digestion_due_date
            FROM
              xxcos_vd_digestion_hdrs             xvdh
            WHERE
              xvdh.cust_account_id                = it_cust_account_id
            AND xvdh.digestion_due_date           < id_digestion_due_date
-- == 2010/04/05 V1.15 Added START ===============================================================
            AND xvdh.sales_result_creation_flag   NOT IN(cv_skip_flag, cv_n)
-- == 2010/04/05 V1.15 Added END   ===============================================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--            AND xvdh.sales_result_creation_flag   = ct_sr_creation_flag_yes
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            ORDER BY
--              xvdh.digestion_due_date             desc
            UNION
            -- 未計算で集約フラグが立っていな掛率データの消化計算締年月日
            SELECT
              xvdh.digestion_due_date             digestion_due_date
            FROM
              xxcos_vd_digestion_hdrs             xvdh
            WHERE
              xvdh.cust_account_id                = it_cust_account_id
            AND xvdh.digestion_due_date           < id_digestion_due_date
            AND xvdh.sales_result_creation_flag   = cv_n
            AND xvdh.summary_data_flag            = cv_n
-- == 2010/04/05 V1.15 Modified END ===============================================================
          ) xvdh
-- == 2010/04/05 V1.15 Deleted START ===============================================================
--        WHERE
--          ROWNUM                                  = 1
-- == 2010/04/05 V1.15 Deleted END ===============================================================
        ;
-- == 2010/05/06 V1.17 Added START ===================================================================
        -- 取得結果がNULLの場合、 NO_DATA_FOUND例外をスロー
        IF ( g_get_pre_diges_due_dt_tab(it_cust_account_id) IS NULL ) THEN
          RAISE NO_DATA_FOUND;
        END IF;
-- == 2010/05/06 V1.17 Added END ===================================================================
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          g_get_pre_diges_due_dt_tab(it_cust_account_id)    := gd_min_date;
        WHEN OTHERS THEN
          ---消化VD別消化計算ヘッダテーブル文字列取得
          lv_str_table_name       := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_xvdh_tblnm
                                     );
          --キー情報文字列取得
          lv_str_key_data         := xxccp_common_pkg.get_msg(
                                       iv_application       => ct_xxcos_appl_short_name,
                                       iv_name              => ct_msg_key_info1,
                                       iv_token_name1       => cv_tkn_diges_due_dt,
                                       iv_token_value1      => TO_CHAR( id_digestion_due_date, cv_fmt_date ),
                                       iv_token_name2       => cv_tkn_cust_code,
                                       iv_token_value2      => it_customer_number
                                     );
          RAISE global_select_data_expt;
      END;
    END IF;
    --
    --============================================
    -- 前回消化計算締年月日＋１日
    --============================================
    ld_pre_digestion_due_date :=  CASE
                                    WHEN ( g_get_pre_diges_due_dt_tab(it_cust_account_id) = gd_min_date )
                                    THEN
                                      gd_min_date
                                    ELSE
                                      g_get_pre_diges_due_dt_tab(it_cust_account_id) + cn_one_day
                                  END;
    --
    --============================================
    -- 2.中止決裁判定
    --============================================
    IF ( id_stop_approval_date IS NULL ) THEN
      NULL;
    ELSE
      IF ( ( ld_pre_digestion_due_date <= id_stop_approval_date )
        AND ( id_digestion_due_date >= id_stop_approval_date ) )
      THEN
        NULL;
      ELSE
        ld_pre_digestion_due_date       := NULL;
      END IF;
    END IF;
--
    --============================================
    -- 3.返却
    --============================================
    od_pre_digestion_due_date           := CASE
                                             WHEN ( ld_pre_digestion_due_date IS NULL )
                                             THEN
                                               NULL
                                             ELSE
                                               g_get_pre_diges_due_dt_tab(it_cust_account_id)
                                           END;
--
  EXCEPTION
    -- *** 品目マスタ取得例外ハンドラ ***
    WHEN global_select_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_select_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_str_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => lv_str_key_data
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END calc_pre_diges_due_dt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_regular_any_class      IN      VARCHAR2,         -- 1.定期随時区分
    iv_base_code              IN      VARCHAR2,         -- 2.拠点コード
    iv_customer_number        IN      VARCHAR2,         -- 3.顧客コード
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2,        -- 4.業務日付
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    ct_bsinss_lw_tp_svd                 CONSTANT xxcmm_cust_accounts.business_low_type%TYPE  := '27'; -- 業態小分類：27(消化VD)
    cv_uncalc_cls_4                     CONSTANT VARCHAR2(1) := '4';  -- 未計算区分'4'
    cv_yes                              CONSTANT VARCHAR2(1) := 'Y';  -- チェックフラグ'Y'
    cv_no                               CONSTANT VARCHAR2(1) := 'N';  -- チェックフラグ'N'
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- *** ローカル変数 ***
    --データ存在フラグ
    lv_xvdh_exists_flag                 VARCHAR2(1);                  -- 消化VDヘッダ存在フラグ
    lv_cust_exists_flag1                VARCHAR2(1);                  -- 顧客マスタ存在フラグ（1日分）
    lv_cust_exists_flag2                VARCHAR2(1);                  -- 顧客マスタ存在フラグ（複数日分）
    --消化VD別消化計算ヘッダID
    lt_vd_digestion_hdr_id              xxcos_vd_digestion_hdrs.vd_digestion_hdr_id%TYPE;
    --未計算タイプ
    lv_ar_uncalculate_type              VARCHAR2(1);                  -- AR未計算タイプ
    lv_vdc_uncalculate_type             VARCHAR2(1);                  -- VDコラム別未計算タイプ
    --集計
    ln_ar_amount                        NUMBER;                       -- 売上金額合計
    ln_tax_amount                       NUMBER;                       -- 消費税額合計
    ln_vdc_amount                       NUMBER;                       -- 販売金額合計
    --最新データ
    lt_delivery_date                    xxcos_vd_column_headers.dlv_date%TYPE;
                                                                      -- 納品日
    lt_dlv_time                         xxcos_vd_column_headers.dlv_time%TYPE;
                                                                      -- 納品時間
    lt_performance_by_code              xxcos_vd_column_headers.performance_by_code%TYPE;
                                                                      -- 成績者コード
    lt_change_out_time_100              xxcos_vd_column_headers.change_out_time_100%TYPE;
                                                                      -- つり銭切れ時間100円
    lt_change_out_time_10               xxcos_vd_column_headers.change_out_time_10%TYPE;
                                                                      -- つり銭切れ時間10円
    --添字
    ln_idx                              NUMBER;
    --日付（日）
    lv_due_day                          VARCHAR2(2);                  -- 消化計算締年月日
    lv_last_day                         VARCHAR2(2);                  -- 締日
    lv_leap_year_due_day                VARCHAR2(2);                  -- 月末日
    --前回消化計算締年月日
    ld_pre_digestion_due_date           DATE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --ロック取得エラーフラグ
    lv_lock_data_err_flg                VARCHAR2(1);
    --閾値チェックエラーフラグ
    lv_thrshld_chk_err_flg              VARCHAR2(1);
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
-- == 2010/04/05 V1.15 Added START ===============================================================
    ld_pre_digest_due_date              DATE;
-- == 2010/04/05 V1.15 Added END   ===============================================================
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --============================================
    -- 消化VD用消化計算ヘッダ情報取得処理(A-2)
    --============================================
    CURSOR xvdh_cur
    IS
      SELECT
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id,          --消化VD用消化計算ヘッダID
        xvdh.customer_number                      customer_number,              --顧客コード
        xvdh.digestion_due_date                   digestion_due_date,           --消化計算締年月日
        xvdh.sales_base_code                      sales_base_code,              --前月売上拠点コード
        xvdh.cust_account_id                      cust_account_id,              --顧客ID
        xvdh.master_rate                          master_rate,                  --マスタ掛率
        xvdh.cust_gyotai_sho                      cust_gyotai_sho,              --業態小分類
        xvdh.pre_digestion_due_date               pre_digestion_due_date,       --前回消化計算締年月日
        xvdh.delivery_base_code                   delivery_base_code            --納品拠点コード
      FROM
        (
          SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
            /*+
              INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
            */
-- ***************** 2009/08/06 1.10 N.Maeda ADD  END  ************************** --
            xvdh.vd_digestion_hdr_id              vd_digestion_hdr_id,          --消化VD用消化計算ヘッダID
            xvdh.customer_number                  customer_number,              --顧客コード
            xvdh.digestion_due_date               digestion_due_date,           --消化計算締年月日
            xvdh.sales_base_code                  sales_base_code,              --前月売上拠点コード
            xvdh.cust_account_id                  cust_account_id,              --顧客ID
            xvdh.master_rate                      master_rate,                  --マスタ掛率
            xvdh.cust_gyotai_sho                  cust_gyotai_sho,              --業態小分類
            xvdh.pre_digestion_due_date           pre_digestion_due_date,       --前回消化計算締年月日
            xca.delivery_base_code                delivery_base_code            --納品拠点コード
          FROM
            xxcos_vd_digestion_hdrs               xvdh,                         --消化VD用消化計算ヘッダテーブル
            hz_cust_accounts                      hca,                          --顧客マスタ
            xxcmm_cust_accounts                   xca                           --アカウントアドオン
          WHERE
            xvdh.cust_account_id                  = hca.cust_account_id
          AND hca.cust_account_id                 = xca.customer_id
          AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
          AND xvdh.sales_base_code                = NVL( gt_base_code, xvdh.sales_base_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND xvdh.customer_number = gt_customer_number ) )
--          AND xvdh.customer_number                = NVL( gt_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- == 2010/04/05 V1.15 Added START ===============================================================
          AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
          UNION
          SELECT
-- ***************** 2009/08/06 1.10 N.Maeda ADD START ************************** --
            /*+
              INDEX (XVDH XXCOS_VD_DIGESTION_HDRS_N03 )
            */
-- ***************** 2009/08/06 1.10 N.Maeda ADD  END  ************************** --
            xvdh.vd_digestion_hdr_id              vd_digestion_hdr_id,          --消化VD用消化計算ヘッダID
            xvdh.customer_number                  customer_number,              --顧客コード
            xvdh.digestion_due_date               digestion_due_date,           --消化計算締年月日
            xvdh.sales_base_code                  sales_base_code,              --前月売上拠点コード
            xvdh.cust_account_id                  cust_account_id,              --顧客ID
            xvdh.master_rate                      master_rate,                  --マスタ掛率
            xvdh.cust_gyotai_sho                  cust_gyotai_sho,              --業態小分類
            xvdh.pre_digestion_due_date           pre_digestion_due_date,       --前回消化計算締年月日
            xca.delivery_base_code                delivery_base_code            --納品拠点コード
          FROM
            xxcos_vd_digestion_hdrs               xvdh,                         --消化VD用消化計算ヘッダテーブル
            hz_cust_accounts                      hca,                          --顧客マスタ
            xxcmm_cust_accounts                   xca,                          --アカウントアドオン
            hz_cust_accounts                      hca2,                         --顧客マスタ
            xxcmm_cust_accounts                   xca2                          --アカウントアドオン
          WHERE
            xvdh.cust_account_id                  = hca.cust_account_id
          AND hca.cust_account_id                 = xca.customer_id
          AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
          AND xvdh.sales_base_code                = hca2.account_number
          AND hca2.cust_account_id                = xca2.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst1
                AND flv.meaning                   = hca2.customer_class_code
                AND xvdh.digestion_due_date       >= flv.start_date_active
                AND xvdh.digestion_due_date       <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
          AND xca2.management_base_code           = NVL( gt_base_code, xca2.management_base_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND xvdh.customer_number = gt_customer_number ) )
--          AND xvdh.customer_number                = NVL( gt_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- == 2010/04/05 V1.15 Added START ===============================================================
          AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
       ) xvdh
     ORDER BY
       xvdh.digestion_due_date,
       xvdh.customer_number
     ;
    -- 消化VD用消化計算ヘッダ情報 レコード型
    l_xvdh_rec xvdh_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    --============================================
    -- 消化VD用消化計算ヘッダ情報取得処理(定期(洗替え))(A-2)
    --============================================
    CURSOR xvdh_cur2
    IS
      SELECT
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id,          --消化VD用消化計算ヘッダID
        xvdh.customer_number                      customer_number,              --顧客コード
        xvdh.digestion_due_date                   digestion_due_date,           --消化計算締年月日
        xvdh.sales_base_code                      sales_base_code,              --前月売上拠点コード
        xvdh.cust_account_id                      cust_account_id,              --顧客ID
        xvdh.master_rate                          master_rate,                  --マスタ掛率
        xvdh.cust_gyotai_sho                      cust_gyotai_sho,              --業態小分類
        xvdh.pre_digestion_due_date               pre_digestion_due_date,       --前回消化計算締年月日
        xca.delivery_base_code                    delivery_base_code            --納品拠点コード
      FROM
        xxcos_vd_digestion_hdrs               xvdh,                         --消化VD用消化計算ヘッダテーブル
        xxcmm_cust_accounts                   xca                           --アカウントアドオン
      WHERE
        xvdh.cust_account_id                  = xca.customer_id
      AND xvdh.sales_result_creation_flag     = ct_sr_creation_flag_no
      AND xca.business_low_type               = ct_bsinss_lw_tp_svd
-- == 2010/04/05 V1.15 Added START ===============================================================
      AND xvdh.summary_data_flag              <>  cv_y
-- == 2010/04/05 V1.15 Added END   ===============================================================
      ORDER BY
        xvdh.digestion_due_date,
        xvdh.customer_number
    ;
--
    -- 消化VD用消化計算ヘッダ情報 レコード型(定期(洗替え))
    l_xvdh_rec2 xvdh_cur2%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    --============================================
    -- 消化VD用消化計算ヘッダ情報(今回データ）取得
    --============================================
    CURSOR tt_xvdh_cur(
      it_customer_number      xxcos_vd_digestion_hdrs.customer_number%TYPE
    )
    IS
      SELECT
-- ************** 2009/08/06 N.Maeda 1.10 MOD START ********************* --
        /*+ INDEX( XVDH XXCOS_VD_DIGESTION_HDRS_N03) */
-- ************** 2009/08/06 N.Maeda 1.10 MOD  END  ********************* --
        xvdh.vd_digestion_hdr_id                  vd_digestion_hdr_id           --消化VD用消化計算ヘッダID
      FROM
        xxcos_vd_digestion_hdrs                   xvdh                          --消化VD用消化計算ヘッダテーブル
      WHERE
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
         ( ( it_customer_number IS NULL )
        OR ( it_customer_number IS NOT NULL AND it_customer_number = xvdh.customer_number ) )
--          xvdh.customer_number                    = NVL( it_customer_number, xvdh.customer_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
      AND xvdh.sales_result_creation_flag         = ct_sr_creation_flag_no
      ;
    -- 消化VD用消化計算ヘッダ情報 レコード型
    l_tt_xvdh_rec tt_xvdh_cur%ROWTYPE;
--
    --============================================
    -- 顧客マスタ取得処理(A-17)
    --============================================
    CURSOR cust_cur(
      id_digestion_due_date             DATE,                              -- 1.消化計算締年月日
      iv_due_day                        VARCHAR2,                          -- 2.締日
      iv_last_day                       VARCHAR2,                          -- 3.月末日
      iv_leap_year_due_day              VARCHAR2                           -- 4.閏年締日
    )
    IS
      SELECT
        cust.cust_account_id            cust_account_id,              --顧客ID
        cust.customer_number            customer_number,              --顧客コード
        cust.party_id                   party_id,                     --パーティID
        cust.master_rate                master_rate,                  --マスタ掛率
        cust.sale_base_code             sales_base_code,              --前月売上拠点コード
        cust.cust_gyotai_sho            cust_gyotai_sho,              --業態小分類
        cust.delivery_base_code         delivery_base_code,           --納品拠点コード
        cust.stop_approval_date         stop_approval_date,           --中止決裁日
        cust.conclusion_day1            conclusion_day1,              --消化計算締め日１
        cust.conclusion_day2            conclusion_day2,              --消化計算締め日２
        cust.conclusion_day3            conclusion_day3               --消化計算締め日３
      FROM
        (
          SELECT
-- *********** 2009/08/05 N.Maeda 1.10 ADD START *******************--
            /*+ INDEX (xca XXCMM_CUST_ACCOUNTS_N09 ) */
-- *********** 2009/08/05 N.Maeda 1.10 ADD  END  *******************--
            hca.cust_account_id                   cust_account_id,              --顧客ID
            hca.account_number                    customer_number,              --顧客コード
            hca.party_id                          party_id,                     --パーティID
            ( xca.rate * 100 )                    master_rate,                  --マスタ掛率
-- 2010/03/24 Ver.1.14 Mod Start
            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca.sale_base_code
              ELSE  xca.past_sale_base_code
            END
--            NVL( xca.past_sale_base_code, xca.sale_base_code )
-- 2010/03/24 Ver.1.14 Mod End
                                                  sale_base_code,               --売上拠点コード
            xca.business_low_type                 cust_gyotai_sho,              --業態小分類
            xca.delivery_base_code                delivery_base_code,           --納品拠点コード
            xca.stop_approval_date                stop_approval_date,           --中止決裁日
            xca.conclusion_day1                   conclusion_day1,              --消化計算締め日１
            xca.conclusion_day2                   conclusion_day2,              --消化計算締め日２
            xca.conclusion_day3                   conclusion_day3               --消化計算締め日３
          FROM
            hz_cust_accounts                      hca,                          --顧客マスタ
            xxcmm_cust_accounts                   xca                           --アカウントアドオン
          WHERE
            hca.cust_account_id                   = xca.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst2
                AND flv.meaning                   = hca.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--
          AND (
                ( gt_base_code IS NULL )
              OR
                ( gt_base_code IS NOT NULL 
-- == 2010/04/05 V1.15 Modified START ===============================================================
                  AND (  gt_base_code IN ( xca.past_sale_base_code, xca.sale_base_code ) ) )
--                  AND NVL( xca.past_sale_base_code, xca.sale_base_code )
--                = gt_base_code )
-- == 2010/04/05 V1.15 Modified END ===============================================================
              )
--          AND NVL( xca.past_sale_base_code, xca.sale_base_code )
--                                                  = NVL( gt_base_code,
--                                                      NVL( xca.past_sale_base_code,
--                                                        xca.sale_base_code
--                                                      )
--                                                    )
          AND ( ( gt_customer_number IS NULL )
                OR ( gt_customer_number IS NOT NULL
              AND hca.account_number = gt_customer_number )
              )
--          AND hca.account_number                  = NVL( gt_customer_number, hca.account_number )
--
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del Start
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_gyotai_sho_mst
                  flv.lookup_type               = ct_qct_gyotai_sho_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_gyotai_sho_mst
                AND flv.meaning                   = xca.business_low_type
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
          AND iv_due_day                          IN (
                                                       DECODE(
                                                         xca.conclusion_day1,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day1 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day1 ),
                                                           xca.conclusion_day1
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca.conclusion_day2,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day2 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day2 ),
                                                           xca.conclusion_day2
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca.conclusion_day3,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca.conclusion_day3 ) ),
                                                           1, cv_zero || TRIM( xca.conclusion_day3 ),
                                                           xca.conclusion_day3
                                                         )
                                                       )
                                                     )
          UNION
          SELECT
-- *********** 2009/08/05 N.Maeda 1.10 ADD START *******************--
            /*+ INDEX (xca2 XXCMM_CUST_ACCOUNTS_N09 ) */
-- *********** 2009/08/05 N.Maeda 1.10 ADD  END  *******************--
            hca2.cust_account_id                  cust_account_id,              --顧客ID
            hca2.account_number                   customer_number,              --顧客コード
            hca2.party_id                         party_id,                     --パーティID
            ( xca2.rate * 100 )                   master_rate,                  --マスタ掛率
-- 2010/03/24 Ver.1.14 Mod Start
-- == 2010/04/05 V1.15 Modified START ===============================================================
            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca2.sale_base_code
              ELSE  xca2.past_sale_base_code
            END
--            CASE  TRUNC(id_digestion_due_date,cv_dya_fmt_month)
--              WHEN  TRUNC(gd_process_date,cv_dya_fmt_month) THEN  xca.sale_base_code
--              ELSE  xca.past_sale_base_code
--            END
-- == 2010/04/05 V1.15 Modified END ===============================================================
--            NVL( xca2.past_sale_base_code, xca2.sale_base_code )
-- 2010/03/24 Ver.1.14 Mod End
                                                  sale_base_code,               --売上拠点コード
            xca2.business_low_type                cust_gyotai_sho,              --業態小分類
            xca2.delivery_base_code               delivery_base_code,           --納品拠点コード
            xca2.stop_approval_date               stop_approval_date,           --中止決裁日
            xca2.conclusion_day1                  conclusion_day1,              --消化計算締め日１
            xca2.conclusion_day2                  conclusion_day2,              --消化計算締め日２
            xca2.conclusion_day3                  conclusion_day3               --消化計算締め日３
          FROM
            hz_cust_accounts                      hca,                          --顧客マスタ
            xxcmm_cust_accounts                   xca,                          --アカウントアドオン
            hz_cust_accounts                      hca2,                         --顧客マスタ
            xxcmm_cust_accounts                   xca2                          --アカウントアドオン
          WHERE
            hca.cust_account_id                   = xca.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del End
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst1
                AND flv.meaning                   = hca.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
--
          AND ( ( gt_base_code IS NULL )
            OR ( gt_base_code IS NOT NULL 
              AND xca.management_base_code = gt_base_code ) )
--          AND xca.management_base_code            = NVL( gt_base_code, hca.customer_class_code )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
          AND hca2.cust_account_id                = xca2.customer_id
          AND EXISTS(
                SELECT
                  cv_exists_flag_yes              exists_flag
                FROM
-- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_application                 fa,
--                  fnd_lookup_types                flt,
-- 2009/07/16 Ver.1.9 M.Sano Del Start
                  fnd_lookup_values               flv
                WHERE
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                  fa.application_id               = flt.application_id
--                AND flt.lookup_type               = flv.lookup_type
--                AND fa.application_short_name     = ct_xxcos_appl_short_name
--                AND flv.lookup_type               = ct_qct_cus_class_mst
                  flv.lookup_type               = ct_qct_cus_class_mst
-- 2009/07/16 Ver.1.9 M.Sano Mod End
                AND flv.lookup_code               LIKE ct_qcc_cus_class_mst2
                AND flv.meaning                   = hca2.customer_class_code
                AND id_digestion_due_date         >= flv.start_date_active
                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
                AND flv.enabled_flag              = ct_enabled_flag_yes
-- 2009/07/16 Ver.1.9 M.Sano Mod Start
--                AND flv.language                  = USERENV( 'LANG' )
                AND flv.language                  = ct_lang
-- 2009/07/16 Ver.1.9 M.Sano Mod End
-- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
--                AND ROWNUM                        = 1
-- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
              )
-- == 2010/04/05 V1.15 Modified START ===============================================================
          AND hca.account_number IN ( xca2.past_sale_base_code, xca2.sale_base_code )
--          AND NVL( xca2.past_sale_base_code, xca2.sale_base_code )
--                                                  = hca.account_number
-- == 2010/04/05 V1.15 Modified END ===============================================================
-- ************** 2009/08/04 N.Maeda 1.10 MOD START ********************* --
          AND ( ( gt_customer_number IS NULL )
            OR ( gt_customer_number IS NOT NULL AND gt_customer_number = hca2.account_number ) )
--          AND hca2.account_number                 = NVL( gt_customer_number, hca2.account_number )
-- ************** 2009/08/04 N.Maeda 1.10 MOD  END  ********************* --
-- 2010/05/02 Ver.1.16 T.Ishiwata Mod Start
          AND xca2.business_low_type  =  cv_buz_type27     -- 業態小分類２７のみ
--          AND EXISTS(
--                SELECT
--                  cv_exists_flag_yes              exists_flag
--                FROM
---- 2009/07/16 Ver.1.9 M.Sano Del Start
----                  fnd_application                 fa,
----                  fnd_lookup_types                flt,
---- 2009/07/16 Ver.1.9 M.Sano Del Start
--                  fnd_lookup_values               flv
--                WHERE
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----                  fa.application_id               = flt.application_id
----                AND flt.lookup_type               = flv.lookup_type
----                AND fa.application_short_name     = ct_xxcos_appl_short_name
----                AND flv.lookup_type               = ct_qct_gyotai_sho_mst
--                  flv.lookup_type               = ct_qct_gyotai_sho_mst
---- 2009/07/16 Ver.1.9 M.Sano Mod End
--                AND flv.lookup_code               LIKE ct_qcc_gyotai_sho_mst
--                AND flv.meaning                   = xca2.business_low_type
--                AND id_digestion_due_date         >= flv.start_date_active
--                AND id_digestion_due_date         <= NVL( flv.end_date_active, gd_max_date )
--                AND flv.enabled_flag              = ct_enabled_flag_yes
---- 2009/07/16 Ver.1.9 M.Sano Mod Start
----                AND flv.language                  = USERENV( 'LANG' )
--                AND flv.language                  = ct_lang
---- 2009/07/16 Ver.1.9 M.Sano Mod End
---- ************** 2009/08/04 N.Maeda 1.10 DEL START ********************* --
----                AND ROWNUM                        = 1
---- ************** 2009/08/04 N.Maeda 1.10 DEL  END  ********************* --
--              )
-- 2010/05/02 Ver.1.16 T.Ishiwata Mod End
          AND iv_due_day                          IN (
                                                       DECODE(
                                                         xca2.conclusion_day1,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day1 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day1 ),
                                                           xca2.conclusion_day1
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca2.conclusion_day2,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day2 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day2 ),
                                                           xca2.conclusion_day2
                                                         )
                                                       ),
                                                       DECODE(
                                                         xca2.conclusion_day3,
                                                         cv_last_day_29, iv_leap_year_due_day,
                                                         cv_last_day_30, iv_last_day,
                                                         DECODE(
                                                           LENGTHB( TRIM( xca2.conclusion_day3 ) ),
                                                           1, cv_zero || TRIM( xca2.conclusion_day3 ),
                                                           xca2.conclusion_day3
                                                         )
                                                       )
                                                     )
        ) cust
-- == 2010/04/05 V1.15 Added START ===============================================================
      WHERE NOT EXISTS( SELECT  1
                        FROM    xxcos_vd_digestion_hdrs       xvdh
                        WHERE   xvdh.customer_number      =   cust.customer_number
                        AND     xvdh.digestion_due_date   =   id_digestion_due_date
                        AND     ROWNUM = 1
                )
-- == 2010/04/05 V1.15 Added END   ===============================================================
      ORDER BY
        cust.customer_number
      ;
    -- 顧客マスタ レコード型
    l_cust_rec cust_cur%ROWTYPE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    -- *** ローカル例外 ***
    skip_error_expt     EXCEPTION;
    thrshld_chk_expt    EXCEPTION;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- *** ローカル・関数 ***
    --==================================
    --未計算区分取得
    --==================================
    FUNCTION get_uncalculate_class(
      iv_ar_uncalculate_type            VARCHAR2,
      iv_vdc_uncalculate_type           VARCHAR2
    )
    RETURN   xxcos_vd_digestion_hdrs.uncalculate_class%TYPE
    IS
      lt_uncalculate_flag     xxcos_vd_digestion_hdrs.uncalculate_class%TYPE;
    BEGIN
      IF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_both_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type <> cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_ar_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_zero )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_init ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_ar_nof;
      ELSIF ( ( iv_ar_uncalculate_type <> cv_uncalculate_type_nof )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_nof ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_vdc_nof;
      ELSIF ( ( iv_ar_uncalculate_type = cv_uncalculate_type_init )
        AND ( iv_vdc_uncalculate_type = cv_uncalculate_type_zero ) )
      THEN
        lt_uncalculate_flag   := ct_uncalculate_class_vdc_nof;
      ELSE
        lt_uncalculate_flag   := ct_uncalculate_class_fnd;
      END IF;
      --
      RETURN lt_uncalculate_flag;
    END;
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
    gn_target_cnt := 0;                 --未使用
    gn_normal_cnt := 0;                 --ヘッダ単位の件数で使用
    gn_error_cnt  := 0;                 --未使用
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--    gn_warn_cnt   := 0;                 --未使用
    gn_warn_cnt   := 0;                 --ロック取得失敗でスキップ件数
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
    --対象件数
    gn_target_cnt1 := 0;                --顧客マスタ対象件数
    gn_target_cnt2 := 0;                --AR取引対象件数
    gn_target_cnt3 := 0;                --VDコラム別取引対象件数
    --警告件数
    gn_warn_cnt1 := 0;                  --両方NOF
    gn_warn_cnt2 := 0;                  --AR取引NOF
    gn_warn_cnt3 := 0;                  --VDコラム別取引NOF
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --閾値チェックエラー件数
    gn_thrshld_chk_cnt := 0;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
    -- ===================================================
    -- A-0  初期処理
    -- ===================================================
    init(
      iv_regular_any_class    => iv_regular_any_class,       -- 1.定期随時区分
      iv_base_code            => iv_base_code,               -- 2.拠点コード
      iv_customer_number      => iv_customer_number,         -- 3.顧客コード
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
      iv_process_date         => iv_process_date,            -- 4.業務日付
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      ov_errbuf               => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              => lv_retcode,                 -- リターン・コード
      ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- A-1  パラメータチェック
    -- ===================================================
    chk_parameter(
      ov_errbuf               => lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              => lv_retcode,                 -- リターン・コード
      ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===================================================
    -- 定期随時の判定
    -- ===================================================
    IF ( gt_regular_any_class = ct_regular_any_class_any ) THEN
      -- パラメータの定期随時区分が「随時」の場合
      -- 内部テーブル初期化
      g_xvch_tab.DELETE;
      g_tt_xvdh_tab.DELETE;
      g_xvdh_tab.DELETE;
      g_xvdl_tab.DELETE;
      gn_xvch_idx    := 0;
      gn_tt_xvdh_idx := 0;
      gn_xvdh_idx    := 0;
      gn_xvdl_idx    := 0;
      --
      -- ===================================================
      -- A-2  消化VD用消化計算ヘッダ取得処理
      -- ===================================================
      l_xvdh_rec                        := NULL;
      lv_xvdh_exists_flag               := cv_exists_flag_no;
      --
      <<get_xvdh_loop>>
      FOR xvdh_rec IN xvdh_cur LOOP
        --
        l_xvdh_rec                      := xvdh_rec;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        -- 閾値チェックエラーフラグの初期化
        lv_thrshld_chk_err_flg          := cv_no;
        --
        -- ===================================================
        -- 消化VD用消化計算ヘッダ、明細データロック処理(A-2-1)
        -- ===================================================
        lock_hdrs_lns_data(
          it_vd_dgstn_hdr_id                => l_xvdh_rec.vd_digestion_hdr_id,
          iv_customer_num                   => NULL,
          ov_errbuf                         => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                        => lv_retcode,                -- リターン・コード
          ov_errmsg                         => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        -- ===================================================
        -- 消化VD用消化計算ヘッダ対象件数加算
        -- ===================================================
        gn_target_cnt1                  := gn_target_cnt1 + 1;
        --
        lv_xvdh_exists_flag             := cv_exists_flag_yes;
        -- ===================================================
        -- 今回データセット
        -- ===================================================
        gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                        := l_xvdh_rec.vd_digestion_hdr_id;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
                                        := l_xvdh_rec.customer_number;
        g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
                                        := l_xvdh_rec.digestion_due_date;
-- 2010/03/24 Ver.1.14 Add Start
        g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
                                        := l_xvdh_rec.sales_base_code;
-- 2010/03/24 Ver.1.14 Add End
        --
        -- ===================================================
        -- VDコラム別取引ヘッダデータセット
        -- ===================================================
        gn_xvch_idx                     := gn_xvch_idx + 1;
        g_xvch_tab(gn_xvch_idx).customer_number
                                        := l_xvdh_rec.customer_number;
        g_xvch_tab(gn_xvch_idx).digestion_due_date
                                        := l_xvdh_rec.digestion_due_date;
        g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                        := NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date );
-- 2010/03/24 Ver.1.14 Add Start
        g_xvch_tab(gn_xvch_idx).sales_base_code
                                        := l_xvdh_rec.sales_base_code;
-- 2010/03/24 Ver.1.14 Add End
        --
        -- ===================================================
        -- A-4  ヘッダ単位初期化処理
        -- ===================================================
        ini_header(
          ot_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  1.消化VD用消化計算ヘッダID
          ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  2.AR未計算区分
          ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  3.VDコラム別未計算区分
          on_ar_amount                  => ln_ar_amount,                      --  4.売上金額合計
          on_tax_amount                 => ln_tax_amount,                     --  5.消費税額合計
          on_vdc_amount                 => ln_vdc_amount,                     --  6.販売金額合計
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-21 前回未計算データチェック処理
        -- ===================================================
        chk_pre_not_digestion_due(
            iv_customer_code          =>    l_xvdh_rec.customer_number
          , od_pre_digest_due_date    =>    ld_pre_digest_due_date
          , ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
        -- ===================================================
        -- A-5  AR取引情報取得処理
        -- ===================================================
        -- 初期化
        lv_ar_uncalculate_type          := cv_uncalculate_type_init;
        --
        get_cust_trx(
          it_cust_account_id            => l_xvdh_rec.cust_account_id,        --  1.顧客ID
          it_customer_number            => l_xvdh_rec.customer_number,        --  2.顧客コード
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          id_start_gl_date              => NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date ),
          id_start_gl_date              => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                              --  3.開始GL記帳日
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          id_end_gl_date                => l_xvdh_rec.digestion_due_date,     --  4.終了GL記帳日
          ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  5.AR取引未計算区分
          on_ar_amount                  => ln_ar_amount,                      --  6.売上金額合計
          on_tax_amount                 => ln_tax_amount,                     --  7.消費税額合計
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-7  VDコラム別取引情報取得処理
        -- ===================================================
        -- 初期化
        lv_vdc_uncalculate_type         := cv_uncalculate_type_init;
        lt_delivery_date                := NULL;                 -- 納品日
        lt_dlv_time                     := NULL;                 -- 納品時間
        lt_performance_by_code          := NULL;                 -- 成績者コード
        lt_change_out_time_100          := NULL;                 -- つり銭切れ時間100円
        lt_change_out_time_10           := NULL;                 -- つり銭切れ時間10円
        --
        get_vd_column(
          it_cust_account_id            => l_xvdh_rec.cust_account_id,        --  1.顧客ID
          it_customer_number            => l_xvdh_rec.customer_number,        --  2.顧客コード
          it_digestion_due_date         => l_xvdh_rec.digestion_due_date,     --  3.消化計算締年月日
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          it_pre_digestion_due_date     => NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date ),
          it_pre_digestion_due_date     => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                              --  4.前回消化計算締年月日
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          it_delivery_base_code         => l_xvdh_rec.delivery_base_code,     --  5.納品拠点コード
          it_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  6.消化VD消化計算ヘッダID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
          it_sales_base_code            => l_xvdh_rec.sales_base_code,        --  7.売上拠点コード
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
          ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  8.VDコラム別取引未計算フラグ
          on_vdc_amount                 => ln_vdc_amount,                     --  9.販売金額合計
          ot_delivery_date              => lt_delivery_date,                  -- 10.納品日（最新データ）
          ot_dlv_time                   => lt_dlv_time,                       -- 11.納品時間（最新データ）
          ot_performance_by_code        => lt_performance_by_code,            -- 12.成績者コード（最新データ）
          ot_change_out_time_100        => lt_change_out_time_100,            -- 13.つり銭切れ時間100円（最新データ）
          ot_change_out_time_10         => lt_change_out_time_10,             -- 14.つり銭切れ時間10円（最新データ）
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- 消化VD用消化計算ヘッダ登録用セット処理
        -- ===================================================
        gn_xvdh_idx := gn_xvdh_idx + 1;
        --消化VD用消化計算ヘッダID
        g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id         := lt_vd_digestion_hdr_id;
        --顧客コード
        g_xvdh_tab(gn_xvdh_idx).customer_number             := l_xvdh_rec.customer_number;
        --消化計算締年月日
        g_xvdh_tab(gn_xvdh_idx).digestion_due_date          := l_xvdh_rec.digestion_due_date;
        --売上拠点コード
        g_xvdh_tab(gn_xvdh_idx).sales_base_code             := l_xvdh_rec.sales_base_code;
        --顧客ＩＤ
        g_xvdh_tab(gn_xvdh_idx).cust_account_id             := l_xvdh_rec.cust_account_id;
        --消化計算実行日
        g_xvdh_tab(gn_xvdh_idx).digestion_exe_date          := gd_process_date;
        --売上金額
        g_xvdh_tab(gn_xvdh_idx).ar_sales_amount             := ROUND( ln_ar_amount );
        --販売金額
        g_xvdh_tab(gn_xvdh_idx).sales_amount                := ROUND( ln_vdc_amount );
        --消化計算掛率
        IF ( ( ln_ar_amount = cn_amount_default )
          OR ( ln_vdc_amount = cn_amount_default ) )
        THEN
          g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := 0;
        ELSE
          g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := ROUND(
                                                                 ln_ar_amount / ln_vdc_amount * 100,
                                                                 cn_rate_fraction_place
                                                               );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          -- 算出した掛率に対する閾値のチェック
          IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
            OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
            --
            lv_thrshld_chk_err_flg := cv_yes;
            gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
          END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        END IF;
        --マスタ掛率
        g_xvdh_tab(gn_xvdh_idx).master_rate                 := l_xvdh_rec.master_rate;
        --差額
        g_xvdh_tab(gn_xvdh_idx).balance_amount              := ROUND(
                                                                 ln_ar_amount - ( ln_vdc_amount *
                                                                 g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                 cn_rate_fraction_place
                                                               );
        --業態小分類
        g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho             := l_xvdh_rec.cust_gyotai_sho;
        --消費税額
        g_xvdh_tab(gn_xvdh_idx).tax_amount                  := ln_tax_amount;
        --納品日
        g_xvdh_tab(gn_xvdh_idx).delivery_date               := lt_delivery_date;
        --時間
        g_xvdh_tab(gn_xvdh_idx).dlv_time                    := lt_dlv_time;
        --成績者コード
        g_xvdh_tab(gn_xvdh_idx).performance_by_code         := lt_performance_by_code;
        --販売実績登録日
        g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date  := NULL;
        --販売実績作成済フラグ
        g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag  := ct_sr_creation_flag_no;
        --前回消化計算締年月日
-- == 2010/04/05 V1.15 Modified START ===============================================================
--        g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := l_xvdh_rec.pre_digestion_due_date;
        g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := NVL(ld_pre_digest_due_date, l_xvdh_rec.pre_digestion_due_date);
-- == 2010/04/05 V1.15 Modified END   ===============================================================
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
          g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
        ELSE
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
          --未計算区分(ローカル関数使用）
          g_xvdh_tab(gn_xvdh_idx).uncalculate_class           := get_uncalculate_class(
                                                                   iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                   iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                 );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        --つり銭切れ時間100円
        g_xvdh_tab(gn_xvdh_idx).change_out_time_100         := lt_change_out_time_100;
        --つり銭切れ時間10円
        g_xvdh_tab(gn_xvdh_idx).change_out_time_10          := lt_change_out_time_10;
        --WHOカラム
        g_xvdh_tab(gn_xvdh_idx).created_by                  := cn_created_by;
        g_xvdh_tab(gn_xvdh_idx).creation_date               := cd_creation_date;
        g_xvdh_tab(gn_xvdh_idx).last_updated_by             := cn_last_updated_by;
        g_xvdh_tab(gn_xvdh_idx).last_update_date            := cd_last_update_date;
        g_xvdh_tab(gn_xvdh_idx).last_update_login           := cn_last_update_login;
        g_xvdh_tab(gn_xvdh_idx).request_id                  := cn_request_id;
        g_xvdh_tab(gn_xvdh_idx).program_application_id      := cn_program_application_id;
        g_xvdh_tab(gn_xvdh_idx).program_id                  := cn_program_id;
        g_xvdh_tab(gn_xvdh_idx).program_update_date         := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
        g_xvdh_tab(gn_xvdh_idx).summary_data_flag           :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
        -- ===================================================
        -- 警告件数用カウント
        -- ===================================================
        IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
          gn_warn_cnt1                  := gn_warn_cnt1 + 1;
        ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
          gn_warn_cnt2                  := gn_warn_cnt2 + 1;
        ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
          gn_warn_cnt3                  := gn_warn_cnt3 + 1;
        END IF;
        --
      END LOOP get_xvdh_loop;
      --
      IF ( lv_xvdh_exists_flag = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      ELSE
        -- ===================================================
        -- A-3  消化VD用消化計算情報の今回データ削除
        -- ===================================================
        del_tt_vd_digestion(
          ov_errbuf                       => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                      => lv_retcode,                -- リターン・コード
          ov_errmsg                       => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-11 VDコラム別取引ヘッダ更新処理
        -- ===================================================
        upd_vd_column_hdr(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-12 消化VD用消化計算ヘッダ登録処理
        -- ===================================================
        ins_vd_digestion_hdrs(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-10 消化VD用消化計算明細登録処理
        -- ===================================================
        ins_vd_digestion_lns(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-20 前回未計算データ更新処理
        -- ===================================================
        upd_pre_not_digestion_due(
            ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
      END IF;
      --
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    ELSIF ( gt_regular_any_class = ct_regular_any_class_rplc ) THEN
      -- パラメータの定期随時区分が「定期（洗替え）」の場合
      -- 内部テーブル初期化
      g_xvch_tab.DELETE;
      g_tt_xvdh_tab.DELETE;
      g_xvdh_tab.DELETE;
      g_xvdl_tab.DELETE;
      gn_xvch_idx    := 0;
      gn_tt_xvdh_idx := 0;
      gn_xvdh_idx    := 0;
      gn_xvdl_idx    := 0;
      --
      -- ===================================================
      -- A-2  消化VD用消化計算ヘッダ取得処理
      -- ===================================================
      l_xvdh_rec2                       := NULL;
      lv_xvdh_exists_flag               := cv_exists_flag_no;
      --
      <<get_xvdh_loop2>>
      FOR xvdh_rec2 IN xvdh_cur2 LOOP
        --
        BEGIN
          --
          l_xvdh_rec2                     := xvdh_rec2;
          -- 閾値チェックエラーフラグの初期化
          lv_thrshld_chk_err_flg          := cv_no;
          --
          -- ===================================================
          -- 消化VD用消化計算ヘッダ対象件数加算
          -- ===================================================
          gn_target_cnt1                  := gn_target_cnt1 + 1;
          --
          lv_xvdh_exists_flag             := cv_exists_flag_yes;
          -- ===================================================
          -- 消化VD用消化計算ヘッダ、明細データロック処理(A-2-1)
          -- ===================================================
          lock_hdrs_lns_data(
            it_vd_dgstn_hdr_id                => l_xvdh_rec2.vd_digestion_hdr_id,
            iv_customer_num                   => l_xvdh_rec2.customer_number,
            ov_errbuf                         => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                        => lv_retcode,                -- リターン・コード
            ov_errmsg                         => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE skip_error_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Del Start
--          --
--          -- ===================================================
--          -- 今回データセット
--          -- ===================================================
--          gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
--                                          := l_xvdh_rec2.vd_digestion_hdr_id;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
--                                          := l_xvdh_rec2.customer_number;
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
--                                          := l_xvdh_rec2.digestion_due_date;
---- 2010/03/24 Ver.1.14 Add Start
--          g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
--                                          := l_xvdh_rec2.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
--          --
--          -- ===================================================
--          -- VDコラム別取引ヘッダデータセット
--          -- ===================================================
--          gn_xvch_idx                     := gn_xvch_idx + 1;
--          g_xvch_tab(gn_xvch_idx).customer_number
--                                          := l_xvdh_rec2.customer_number;
--          g_xvch_tab(gn_xvch_idx).digestion_due_date
--                                          := l_xvdh_rec2.digestion_due_date;
--          g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
--                                          := NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date );
---- 2010/03/24 Ver.1.14 Add Start
--          g_xvch_tab(gn_xvch_idx).sales_base_code
--                                          := l_xvdh_rec2.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
-- 2015/10/19 Ver.1.19 K.Kiriu Del End
          --
          -- ===================================================
          -- A-4  ヘッダ単位初期化処理
          -- ===================================================
          ini_header(
            ot_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  1.消化VD用消化計算ヘッダID
            ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  2.AR未計算区分
            ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  3.VDコラム別未計算区分
            on_ar_amount                  => ln_ar_amount,                      --  4.売上金額合計
            on_tax_amount                 => ln_tax_amount,                     --  5.消費税額合計
            on_vdc_amount                 => ln_vdc_amount,                     --  6.販売金額合計
            ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                    => lv_retcode,                -- リターン・コード
            ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added START ===============================================================
          -- ===================================================
          -- A-21 前回未計算データチェック処理
          -- ===================================================
          chk_pre_not_digestion_due(
              iv_customer_code          =>    l_xvdh_rec2.customer_number
            , od_pre_digest_due_date    =>    ld_pre_digest_due_date
            , ov_errbuf                 =>    lv_errbuf
            , ov_retcode                =>    lv_retcode
            , ov_errmsg                 =>    lv_errmsg
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added END   ===============================================================
          -- ===================================================
          -- A-5  AR取引情報取得処理
          -- ===================================================
          -- 初期化
          lv_ar_uncalculate_type          := cv_uncalculate_type_init;
          --
          get_cust_trx(
            it_cust_account_id            => l_xvdh_rec2.cust_account_id,        --  1.顧客ID
            it_customer_number            => l_xvdh_rec2.customer_number,        --  2.顧客コード
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            id_start_gl_date              => NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date ),
            id_start_gl_date              => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                                --  3.開始GL記帳日
-- == 2010/04/05 V1.15 Modified END   ===============================================================
            id_end_gl_date                => l_xvdh_rec2.digestion_due_date,     --  4.終了GL記帳日
            ov_ar_uncalculate_type        => lv_ar_uncalculate_type,            --  5.AR取引未計算区分
            on_ar_amount                  => ln_ar_amount,                      --  6.売上金額合計
            on_tax_amount                 => ln_tax_amount,                     --  7.消費税額合計
            ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                    => lv_retcode,                -- リターン・コード
            ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-7  VDコラム別取引情報取得処理
          -- ===================================================
          -- 初期化
          lv_vdc_uncalculate_type         := cv_uncalculate_type_init;
          lt_delivery_date                := NULL;                 -- 納品日
          lt_dlv_time                     := NULL;                 -- 納品時間
          lt_performance_by_code          := NULL;                 -- 成績者コード
          lt_change_out_time_100          := NULL;                 -- つり銭切れ時間100円
          lt_change_out_time_10           := NULL;                 -- つり銭切れ時間10円
          --
          get_vd_column(
            it_cust_account_id            => l_xvdh_rec2.cust_account_id,        --  1.顧客ID
            it_customer_number            => l_xvdh_rec2.customer_number,        --  2.顧客コード
            it_digestion_due_date         => l_xvdh_rec2.digestion_due_date,     --  3.消化計算締年月日
-- == 2010/04/05 V1.15 Modified START ===============================================================
--            it_pre_digestion_due_date     => NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date ),
            it_pre_digestion_due_date     => NVL(ld_pre_digest_due_date + cn_one_day, NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date )),
                                                                                --  4.前回消化計算締年月日
-- == 2010/04/05 V1.15 Modified END   ===============================================================
            it_delivery_base_code         => l_xvdh_rec2.delivery_base_code,     --  5.納品拠点コード
            it_vd_digestion_hdr_id        => lt_vd_digestion_hdr_id,            --  6.消化VD消化計算ヘッダID
            it_sales_base_code            => l_xvdh_rec2.sales_base_code,        --  7.売上拠点コード
            ov_vdc_uncalculate_type       => lv_vdc_uncalculate_type,           --  8.VDコラム別取引未計算フラグ
            on_vdc_amount                 => ln_vdc_amount,                     --  9.販売金額合計
            ot_delivery_date              => lt_delivery_date,                  -- 10.納品日（最新データ）
            ot_dlv_time                   => lt_dlv_time,                       -- 11.納品時間（最新データ）
            ot_performance_by_code        => lt_performance_by_code,            -- 12.成績者コード（最新データ）
            ot_change_out_time_100        => lt_change_out_time_100,            -- 13.つり銭切れ時間100円（最新データ）
            ot_change_out_time_10         => lt_change_out_time_10,             -- 14.つり銭切れ時間10円（最新データ）
            ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                    => lv_retcode,                -- リターン・コード
            ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--          IF ( lv_retcode <> cv_status_normal ) THEN
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE skip_error_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
            RAISE global_process_expt;
          END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Add Start
          --
          -- ===================================================
          -- 今回データセット
          -- ===================================================
          gn_tt_xvdh_idx                  := gn_tt_xvdh_idx + 1;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                          := l_xvdh_rec2.vd_digestion_hdr_id;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
                                          := l_xvdh_rec2.customer_number;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
                                          := l_xvdh_rec2.digestion_due_date;
          g_tt_xvdh_tab(gn_tt_xvdh_idx).sales_base_code
                                          := l_xvdh_rec2.sales_base_code;
          --
          -- ===================================================
          -- VDコラム別取引ヘッダデータセット
          -- ===================================================
          gn_xvch_idx                     := gn_xvch_idx + 1;
          g_xvch_tab(gn_xvch_idx).customer_number
                                          := l_xvdh_rec2.customer_number;
          g_xvch_tab(gn_xvch_idx).digestion_due_date
                                          := l_xvdh_rec2.digestion_due_date;
          g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                          := NVL( l_xvdh_rec2.pre_digestion_due_date + cn_one_day, gd_min_date );
          g_xvch_tab(gn_xvch_idx).sales_base_code
                                          := l_xvdh_rec2.sales_base_code;
-- 2015/10/19 Ver.1.19 K.Kiriu Add End
          --
          -- ===================================================
          -- 消化VD用消化計算ヘッダ登録用セット処理
          -- ===================================================
          gn_xvdh_idx := gn_xvdh_idx + 1;
          --消化VD用消化計算ヘッダID
          g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id         := lt_vd_digestion_hdr_id;
          --顧客コード
          g_xvdh_tab(gn_xvdh_idx).customer_number             := l_xvdh_rec2.customer_number;
          --消化計算締年月日
          g_xvdh_tab(gn_xvdh_idx).digestion_due_date          := l_xvdh_rec2.digestion_due_date;
          --売上拠点コード
          g_xvdh_tab(gn_xvdh_idx).sales_base_code             := l_xvdh_rec2.sales_base_code;
          --顧客ＩＤ
          g_xvdh_tab(gn_xvdh_idx).cust_account_id             := l_xvdh_rec2.cust_account_id;
          --消化計算実行日
          g_xvdh_tab(gn_xvdh_idx).digestion_exe_date          := gd_process_date;
          --売上金額
          g_xvdh_tab(gn_xvdh_idx).ar_sales_amount             := ROUND( ln_ar_amount );
          --販売金額
          g_xvdh_tab(gn_xvdh_idx).sales_amount                := ROUND( ln_vdc_amount );
          --消化計算掛率
          IF ( ( ln_ar_amount = cn_amount_default )
            OR ( ln_vdc_amount = cn_amount_default ) )
          THEN
            g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := 0;
          ELSE
            g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate       := ROUND(
                                                                   ln_ar_amount / ln_vdc_amount * 100,
                                                                   cn_rate_fraction_place
                                                                 );
            -- 算出した掛率に対する閾値のチェック
            IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
              OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
              --
              lv_thrshld_chk_err_flg := cv_yes;
              gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
            END IF;
          END IF;
          --マスタ掛率
          g_xvdh_tab(gn_xvdh_idx).master_rate                 := l_xvdh_rec2.master_rate;
          --差額
          g_xvdh_tab(gn_xvdh_idx).balance_amount              := ROUND(
                                                                   ln_ar_amount - ( ln_vdc_amount *
                                                                   g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                   cn_rate_fraction_place
                                                                 );
          --業態小分類
          g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho             := l_xvdh_rec2.cust_gyotai_sho;
          --消費税額
          g_xvdh_tab(gn_xvdh_idx).tax_amount                  := ln_tax_amount;
          --納品日
          g_xvdh_tab(gn_xvdh_idx).delivery_date               := lt_delivery_date;
          --時間
          g_xvdh_tab(gn_xvdh_idx).dlv_time                    := lt_dlv_time;
          --成績者コード
          g_xvdh_tab(gn_xvdh_idx).performance_by_code         := lt_performance_by_code;
          --販売実績登録日
          g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date  := NULL;
          --販売実績作成済フラグ
          g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag  := ct_sr_creation_flag_no;
          --前回消化計算締年月日
-- == 2010/04/05 V1.15 Modified START ===============================================================
--          g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := l_xvdh_rec2.pre_digestion_due_date;
          g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date      := NVL(ld_pre_digest_due_date, l_xvdh_rec2.pre_digestion_due_date);
-- == 2010/04/05 V1.15 Modified END   ===============================================================
          IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
            g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
          ELSE
            --未計算区分(ローカル関数使用）
            g_xvdh_tab(gn_xvdh_idx).uncalculate_class           := get_uncalculate_class(
                                                                     iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                     iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                   );
          END IF;
          --つり銭切れ時間100円
          g_xvdh_tab(gn_xvdh_idx).change_out_time_100         := lt_change_out_time_100;
          --つり銭切れ時間10円
          g_xvdh_tab(gn_xvdh_idx).change_out_time_10          := lt_change_out_time_10;
          --WHOカラム
          g_xvdh_tab(gn_xvdh_idx).created_by                  := cn_created_by;
          g_xvdh_tab(gn_xvdh_idx).creation_date               := cd_creation_date;
          g_xvdh_tab(gn_xvdh_idx).last_updated_by             := cn_last_updated_by;
          g_xvdh_tab(gn_xvdh_idx).last_update_date            := cd_last_update_date;
          g_xvdh_tab(gn_xvdh_idx).last_update_login           := cn_last_update_login;
          g_xvdh_tab(gn_xvdh_idx).request_id                  := cn_request_id;
          g_xvdh_tab(gn_xvdh_idx).program_application_id      := cn_program_application_id;
          g_xvdh_tab(gn_xvdh_idx).program_id                  := cn_program_id;
          g_xvdh_tab(gn_xvdh_idx).program_update_date         := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
          g_xvdh_tab(gn_xvdh_idx).summary_data_flag           :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
          -- ===================================================
          -- 警告件数用カウント
          -- ===================================================
          IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
            gn_warn_cnt1                  := gn_warn_cnt1 + 1;
          ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
            gn_warn_cnt2                  := gn_warn_cnt2 + 1;
          ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
            gn_warn_cnt3                  := gn_warn_cnt3 + 1;
          END IF;
          --
        EXCEPTION
          WHEN skip_error_expt THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
            --
            --メッセージ出力
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf --エラーメッセージ
            );
            --
          WHEN global_process_expt THEN
            RAISE global_process_expt;
        END;
      END LOOP get_xvdh_loop2;
      --
      IF ( lv_xvdh_exists_flag = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      ELSE
        -- ===================================================
        -- A-3  消化VD用消化計算情報の今回データ削除
        -- ===================================================
        del_tt_vd_digestion(
          ov_errbuf                       => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                      => lv_retcode,                -- リターン・コード
          ov_errmsg                       => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-11 VDコラム別取引ヘッダ更新処理
        -- ===================================================
        upd_vd_column_hdr(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-12 消化VD用消化計算ヘッダ登録処理
        -- ===================================================
        ins_vd_digestion_hdrs(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-10 消化VD用消化計算明細登録処理
        -- ===================================================
        ins_vd_digestion_lns(
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added START ===============================================================
        -- ===================================================
        -- A-20 前回未計算データ更新処理
        -- ===================================================
        upd_pre_not_digestion_due(
            ov_errbuf                 =>    lv_errbuf
          , ov_retcode                =>    lv_retcode
          , ov_errmsg                 =>    lv_errmsg
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
-- == 2010/04/05 V1.15 Added END   ===============================================================
      END IF;
      --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    ELSE
      --パラメータの定期随時区分が「定期」の場合
      lv_cust_exists_flag2              := cv_exists_flag_no;
      -- ===================================================
      -- A-13 稼働日情報取得処理
      -- ===================================================
      get_operation_day(
        ov_errbuf                       => lv_errbuf,                 -- エラー・メッセージ
        ov_retcode                      => lv_retcode,                -- リターン・コード
        ov_errmsg                       => lv_errmsg                  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --
/* 2010/01/19 Ver1.11 Del Start */
--      -- ===================================================
--      -- A-14 非稼働日情報取得処理
--      -- ===================================================
--      get_non_operation_day(
--        ov_errbuf                       => lv_errbuf,                 -- エラー・メッセージ
--        ov_retcode                      => lv_retcode,                -- リターン・コード
--        ov_errmsg                       => lv_errmsg                  -- ユーザー・エラー・メッセージ
--      );
--      --
--      IF ( lv_retcode <> cv_status_normal ) THEN
--        RAISE global_process_expt;
--      END IF;
/* 2010/01/19 Ver1.11 Del End */
      --
      IF ( g_diges_due_dt_tab.COUNT > 0 ) THEN
        -- ===================================================
        -- A-15 消化VD別用消化計算情報の前々回データ削除処理
        -- ===================================================
        ln_idx                          := g_diges_due_dt_tab.COUNT;
        --
        del_blt_vd_digestion(
          it_digestion_due_date         => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.消化計算締年月日
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      -- ===================================================
      -- 定期実行締日ループ
      -- ===================================================
      <<calc_due_loop>>
      FOR i IN 1.. g_diges_due_dt_tab.COUNT LOOP
        ln_idx                := g_diges_due_dt_tab.COUNT - ( i - 1 );
        --
        lv_cust_exists_flag1  := cv_exists_flag_no;
        --内部テーブル初期化
        g_xvch_tab.DELETE;
        g_tt_xvdh_tab.DELETE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
        g_tt_xvdh_work_tab.DELETE;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
        g_xvdh_tab.DELETE;
        g_xvdl_tab.DELETE;
        gn_xvch_idx           := 0;
        gn_tt_xvdh_idx        := 0;
        gn_xvdh_idx           := 0;
        gn_xvdl_idx           := 0;
        --
        -- ===================================================
        -- A-16 締日算出処理
        -- ===================================================
        calc_due_day(
          id_digestion_due_date         => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.消化計算締年月日
          ov_due_day                    => lv_due_day,                -- 2.締日
          ov_last_day                   => lv_last_day,               -- 3.月末日
          ov_leap_year_due_day          => lv_leap_year_due_day,      -- 4.閏年締日
          ov_errbuf                     => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode                    => lv_retcode,                -- リターン・コード
          ov_errmsg                     => lv_errmsg                  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================================
        -- A-17 顧客マスタ取得処理
        -- ===================================================
        <<cust_loop>>
        FOR cust_rec IN cust_cur(
                          id_digestion_due_date   => g_diges_due_dt_tab(ln_idx),
                                                                      -- 1.消化計算締年月日
                          iv_due_day              => lv_due_day,      -- 2.締日
                          iv_last_day             => lv_last_day,     -- 3.月末日
                          iv_leap_year_due_day    => lv_leap_year_due_day
                                                                      -- 4.閏年締日
                        )
        LOOP
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          BEGIN
            -- 閾値チェックエラーフラグの初期化
            lv_thrshld_chk_err_flg        := cv_no;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
            --
            l_cust_rec                    := cust_rec;
            --
            -- ===================================================
            -- A-18 前回消化計算締年月日算出処理
            -- ===================================================
            calc_pre_diges_due_dt(
              it_cust_account_id          => l_cust_rec.cust_account_id,
                                                                        --  1.顧客ID
              it_customer_number          => l_cust_rec.customer_number,
                                                                        --  2.顧客コード
              id_digestion_due_date       => g_diges_due_dt_tab(ln_idx),
                                                                        --  3.消化計算締年月日
              id_stop_approval_date       => l_cust_rec.stop_approval_date,
                                                                        --  4.中止決裁日
              od_pre_digestion_due_date   => ld_pre_digestion_due_date,
                                                                        --  5.前回消化計算締年月日
              ov_errbuf                   => lv_errbuf,                 -- エラー・メッセージ
              ov_retcode                  => lv_retcode,                -- リターン・コード
              ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
            );
            --
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
            --
            IF ( ld_pre_digestion_due_date IS NULL ) THEN
              NULL;
            ELSE
              -- ===================================================
              -- 顧客マスタ対象件数加算
              -- ===================================================
              gn_target_cnt1              := gn_target_cnt1 + 1;
              --
              lv_cust_exists_flag1        := cv_exists_flag_yes;
              lv_cust_exists_flag2        := cv_exists_flag_yes;
              -- ===================================================
              -- 販売実績情報未作成のデータを抽出
              -- ===================================================
              <<tt_xvdh_loop>>
              FOR tt_xvdh_rec IN tt_xvdh_cur(
                                   it_customer_number         => l_cust_rec.customer_number
                                 )
              LOOP
                --
                l_tt_xvdh_rec             := tt_xvdh_rec;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
                -- ロック取得エラーフラグの初期化
                lv_lock_data_err_flg      := cv_no;
                --
                -- ===================================================
                -- 消化VD用消化計算ヘッダ、明細データロック処理(A-2-1)
                -- ===================================================
                lock_hdrs_lns_data(
                  it_vd_dgstn_hdr_id                => l_tt_xvdh_rec.vd_digestion_hdr_id,
                  iv_customer_num                   => l_cust_rec.customer_number,
                  ov_errbuf                         => lv_errbuf,                 -- エラー・メッセージ
                  ov_retcode                        => lv_retcode,                -- リターン・コード
                  ov_errmsg                         => lv_errmsg                  -- ユーザー・エラー・メッセージ
                );
                --
                IF ( lv_retcode = cv_status_warn ) THEN
                  lv_lock_data_err_flg := cv_yes;
                  EXIT;
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
                --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
-- 2010/02/15 Ver.1.13 K.Hosoi Mod Start
--                -- 今回データセット
--                gn_tt_xvdh_idx            := gn_tt_xvdh_idx + 1;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
--                                          := l_tt_xvdh_rec.vd_digestion_hdr_id;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).customer_number
--                                          := l_cust_rec.customer_number;
--                g_tt_xvdh_tab(gn_tt_xvdh_idx).digestion_due_date
--                                          := g_diges_due_dt_tab(ln_idx);
                -- 今回データをワーク変数にセット
                gn_tt_xvdh_idx         := gn_tt_xvdh_idx + 1;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).vd_digestion_hdr_id
                                          := l_tt_xvdh_rec.vd_digestion_hdr_id;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).customer_number
                                          := l_cust_rec.customer_number;
                g_tt_xvdh_work_tab(gn_tt_xvdh_idx).digestion_due_date
                                          := g_diges_due_dt_tab(ln_idx);
-- 2010/02/15 Ver.1.13 K.Hosoi Mod End
              END LOOP tt_xvdh_loop;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              IF ( lv_lock_data_err_flg = cv_yes ) THEN
                RAISE skip_error_expt;
              END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Del Start
--              -- ===================================================
--              -- 今回データセット
--              -- ===================================================
--              <<tt_xvdh_loop2>>
--              FOR ln_wk_idx IN 1..g_tt_xvdh_work_tab.COUNT LOOP
--                -- 今回データセット
--                g_tt_xvdh_tab(ln_wk_idx).vd_digestion_hdr_id
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).vd_digestion_hdr_id;
--                g_tt_xvdh_tab(ln_wk_idx).customer_number
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).customer_number;
--                g_tt_xvdh_tab(ln_wk_idx).digestion_due_date
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).digestion_due_date;
---- 2010/03/24 Ver.1.14 Add Start
--                g_tt_xvdh_tab(ln_wk_idx).sales_base_code
--                                          := g_tt_xvdh_work_tab(ln_wk_idx).sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
--              --
--              END LOOP tt_xvdh_loop2;
---- 2010/02/15 Ver.1.13 K.Hosoi Add End
--              --
--              -- ===================================================
--              -- VDコラム別取引ヘッダデータセット
--              -- ===================================================
--              gn_xvch_idx                 := gn_xvch_idx + 1;
--              g_xvch_tab(gn_xvch_idx).customer_number
--                                          := l_cust_rec.customer_number;
--              g_xvch_tab(gn_xvch_idx).digestion_due_date
--                                          := g_diges_due_dt_tab(ln_idx);
--              g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
--                                          := CASE
--                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
--                                               THEN ld_pre_digestion_due_date
--                                               ELSE ld_pre_digestion_due_date + cn_one_day
--                                             END;
---- 2010/03/24 Ver.1.14 Add Start
--              g_xvch_tab(gn_xvch_idx).sales_base_code
--                                          := l_cust_rec.sales_base_code;
---- 2010/03/24 Ver.1.14 Add End
-- 2015/10/19 Ver.1.19 K.Kiriu Del End
              --
              -- ===================================================
              -- A-4  ヘッダ単位初期化処理
              -- ===================================================
              ini_header(
                ot_vd_digestion_hdr_id    => lt_vd_digestion_hdr_id,        --  1.消化VD用消化計算ヘッダID
                ov_ar_uncalculate_type    => lv_ar_uncalculate_type,        --  2.AR未計算区分
                ov_vdc_uncalculate_type   => lv_vdc_uncalculate_type,       --  3.VDコラム別未計算区分
                on_ar_amount              => ln_ar_amount,                  --  4.売上金額合計
                on_tax_amount             => ln_tax_amount,                 --  5.消費税額合計
                on_vdc_amount             => ln_vdc_amount,                 --  6.販売金額合計
                ov_errbuf                 => lv_errbuf,               -- エラー・メッセージ
                ov_retcode                => lv_retcode,              -- リターン・コード
                ov_errmsg                 => lv_errmsg                -- ユーザー・エラー・メッセージ
              );
              --
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
              --
              -- ===================================================
              -- A-5  AR取引情報取得処理
              -- ===================================================
              -- 初期化
              lv_ar_uncalculate_type      := cv_uncalculate_type_init;
              --
              get_cust_trx(
                it_cust_account_id        => l_cust_rec.cust_account_id,    --  1.顧客ID
                it_customer_number        => l_cust_rec.customer_number,    --  2.顧客コード
                id_start_gl_date          => CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END,                           --  3.開始GL記帳日
                id_end_gl_date            => g_diges_due_dt_tab(ln_idx),    --  4.終了GL記帳日
                ov_ar_uncalculate_type    => lv_ar_uncalculate_type,        --  5.AR未計算区分
                on_ar_amount              => ln_ar_amount,                  --  6.売上金額合計
                on_tax_amount             => ln_tax_amount,                 --  7.消費税額合計
                ov_errbuf                 => lv_errbuf,               -- エラー・メッセージ
                ov_retcode                => lv_retcode,              -- リターン・コード
                ov_errmsg                 => lv_errmsg                -- ユーザー・エラー・メッセージ
              );
              --
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
              --
              -- ===================================================
              -- A-7  VDコラム別取引情報取得処理
              -- ===================================================
              -- 初期化
              lv_vdc_uncalculate_type     := cv_uncalculate_type_init;
              lt_delivery_date            := NULL;                    -- 納品日
              lt_dlv_time                 := NULL;                    -- 納品時間
              lt_performance_by_code      := NULL;                    -- 成績者コード
              lt_change_out_time_100      := NULL;                    -- つり銭切れ時間100円
              lt_change_out_time_10       := NULL;                    -- つり銭切れ時間10円
              --
              get_vd_column(
                it_cust_account_id        => l_cust_rec.cust_account_id,    --  1.顧客ID
                it_customer_number        => l_cust_rec.customer_number,    --  2.顧客コード
                it_digestion_due_date     => g_diges_due_dt_tab(ln_idx),    --  3.消化計算締年月日
                it_pre_digestion_due_date => CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END,                           --  4.前回消化計算締年月日
                it_delivery_base_code     => l_cust_rec.delivery_base_code, --  5.納品拠点コード
                it_vd_digestion_hdr_id    => lt_vd_digestion_hdr_id,        --  6.消化VD消化計算ヘッダID
--******************************** 2009/03/19 1.6 T.Kitajima ADD START **************************************************
                it_sales_base_code            => l_cust_rec.sales_base_code,--  7.売上拠点コード
--******************************** 2009/03/19 1.6 T.Kitajima ADD  END  **************************************************
                ov_vdc_uncalculate_type   => lv_vdc_uncalculate_type,       --  8.VDコラム別取引未計算区分
                on_vdc_amount             => ln_vdc_amount,                 --  9.販売金額合計
                ot_delivery_date          => lt_delivery_date,              -- 10.納品日（最新データ）
                ot_dlv_time               => lt_dlv_time,                   -- 11.納品時間（最新データ）
                ot_performance_by_code    => lt_performance_by_code,        -- 12.成績者コード（最新データ）
                ot_change_out_time_100    => lt_change_out_time_100,        -- 13.つり銭切れ時間100円（最新データ）
                ot_change_out_time_10     => lt_change_out_time_10,         -- 14.つり銭切れ時間10円（最新データ）
                ov_errbuf                 => lv_errbuf,               -- エラー・メッセージ
                ov_retcode                => lv_retcode,              -- リターン・コード
                ov_errmsg                 => lv_errmsg                -- ユーザー・エラー・メッセージ
              );
              --
-- 2015/10/19 Ver.1.19 K.Kiriu Mod Start
--              IF ( lv_retcode <> cv_status_normal ) THEN
              IF ( lv_retcode = cv_status_warn ) THEN
                RAISE skip_error_expt;
              ELSIF ( lv_retcode = cv_status_error ) THEN
-- 2015/10/19 Ver.1.19 K.Kiriu Mod End
                RAISE global_process_expt;
              END IF;
-- 2015/10/19 Ver.1.19 K.Kiriu Add Start
              -- ===================================================
              -- 今回データセット
              -- ===================================================
              <<tt_xvdh_loop2>>
              FOR ln_wk_idx IN 1..g_tt_xvdh_work_tab.COUNT LOOP
                -- 今回データセット
                g_tt_xvdh_tab(ln_wk_idx).vd_digestion_hdr_id
                                          := g_tt_xvdh_work_tab(ln_wk_idx).vd_digestion_hdr_id;
                g_tt_xvdh_tab(ln_wk_idx).customer_number
                                          := g_tt_xvdh_work_tab(ln_wk_idx).customer_number;
                g_tt_xvdh_tab(ln_wk_idx).digestion_due_date
                                          := g_tt_xvdh_work_tab(ln_wk_idx).digestion_due_date;
                g_tt_xvdh_tab(ln_wk_idx).sales_base_code
                                          := g_tt_xvdh_work_tab(ln_wk_idx).sales_base_code;
              --
              END LOOP tt_xvdh_loop2;
              --
              -- ===================================================
              -- VDコラム別取引ヘッダデータセット
              -- ===================================================
              gn_xvch_idx                 := gn_xvch_idx + 1;
              g_xvch_tab(gn_xvch_idx).customer_number
                                          := l_cust_rec.customer_number;
              g_xvch_tab(gn_xvch_idx).digestion_due_date
                                          := g_diges_due_dt_tab(ln_idx);
              g_xvch_tab(gn_xvch_idx).pre_digestion_due_date
                                          := CASE
                                               WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                               THEN ld_pre_digestion_due_date
                                               ELSE ld_pre_digestion_due_date + cn_one_day
                                             END;
              g_xvch_tab(gn_xvch_idx).sales_base_code
                                          := l_cust_rec.sales_base_code;
-- 2015/10/19 Ver.1.19 K.Kiriu Add End
              --
              -- ===================================================
              -- 消化VD用消化計算ヘッダ登録用セット処理
              -- ===================================================
              gn_xvdh_idx := gn_xvdh_idx + 1;
              --消化VD用消化計算ヘッダID
              g_xvdh_tab(gn_xvdh_idx).vd_digestion_hdr_id     := lt_vd_digestion_hdr_id;
              --顧客コード
              g_xvdh_tab(gn_xvdh_idx).customer_number         := l_cust_rec.customer_number;
              --消化計算締年月日
              g_xvdh_tab(gn_xvdh_idx).digestion_due_date      := g_diges_due_dt_tab(ln_idx);
              --売上拠点コード
              g_xvdh_tab(gn_xvdh_idx).sales_base_code         := l_cust_rec.sales_base_code;
              --顧客ＩＤ
              g_xvdh_tab(gn_xvdh_idx).cust_account_id         := l_cust_rec.cust_account_id;
              --消化計算実行日
              g_xvdh_tab(gn_xvdh_idx).digestion_exe_date      := gd_process_date;
              --売上金額
              g_xvdh_tab(gn_xvdh_idx).ar_sales_amount         := ln_ar_amount;
              --販売金額
              g_xvdh_tab(gn_xvdh_idx).sales_amount            := ln_vdc_amount;
              --消化計算掛率
              IF ( ( ln_ar_amount = cn_amount_default )
                OR ( ln_vdc_amount = cn_amount_default ) )
              THEN
                g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate   := 0;
              ELSE
                g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate   := ROUND(
                                                                   ln_ar_amount / ln_vdc_amount * 100,
                                                                   cn_rate_fraction_place
                                                                 );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
                -- 算出した掛率に対する閾値のチェック
                IF ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate < gn_min_threshold)
                  OR ( g_xvdh_tab(gn_xvdh_idx).digestion_calc_rate > gn_max_threshold) THEN
                  --
                  lv_thrshld_chk_err_flg := cv_yes;
                  gn_thrshld_chk_cnt     := gn_thrshld_chk_cnt + 1;
                END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
              END IF;
              --マスタ掛率
              g_xvdh_tab(gn_xvdh_idx).master_rate             := l_cust_rec.master_rate;
              --差額
              g_xvdh_tab(gn_xvdh_idx).balance_amount          := ROUND(
                                                                   ln_ar_amount - ( ln_vdc_amount *
                                                                   g_xvdh_tab(gn_xvdh_idx).master_rate / 100 ),
                                                                   cn_rate_fraction_place
                                                                 );
              --業態小分類
              g_xvdh_tab(gn_xvdh_idx).cust_gyotai_sho         := l_cust_rec.cust_gyotai_sho;
              --消費税額
              g_xvdh_tab(gn_xvdh_idx).tax_amount              := ln_tax_amount;
              --納品日
              g_xvdh_tab(gn_xvdh_idx).delivery_date           := lt_delivery_date;
              --時間
              g_xvdh_tab(gn_xvdh_idx).dlv_time                := lt_dlv_time;
              --成績者コード
              g_xvdh_tab(gn_xvdh_idx).performance_by_code     := lt_performance_by_code;
              --販売実績登録日
              g_xvdh_tab(gn_xvdh_idx).sales_result_creation_date
                                                              := NULL;
              --販売実績作成済フラグ
              g_xvdh_tab(gn_xvdh_idx).sales_result_creation_flag
                                                              := ct_sr_creation_flag_no;
              --前回消化計算締年月日
              g_xvdh_tab(gn_xvdh_idx).pre_digestion_due_date
                                                              := CASE
                                                                   WHEN ( ld_pre_digestion_due_date = gd_min_date )
                                                                   THEN
                                                                     NULL
                                                                   ELSE
                                                                     ld_pre_digestion_due_date
                                                                 END;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              IF ( lv_thrshld_chk_err_flg = cv_yes ) THEN
                g_xvdh_tab(gn_xvdh_idx).uncalculate_class := cv_uncalc_cls_4;
              ELSE
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
                --未計算区分(ローカル関数使用）
                g_xvdh_tab(gn_xvdh_idx).uncalculate_class       := get_uncalculate_class(
                                                                     iv_ar_uncalculate_type   => lv_ar_uncalculate_type,
                                                                     iv_vdc_uncalculate_type  => lv_vdc_uncalculate_type
                                                                   );
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
              END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
              --つり銭切れ時間100円
              g_xvdh_tab(gn_xvdh_idx).change_out_time_100     := lt_change_out_time_100;
              --つり銭切れ時間10円
              g_xvdh_tab(gn_xvdh_idx).change_out_time_10      := lt_change_out_time_10;
              --WHOカラム
              g_xvdh_tab(gn_xvdh_idx).created_by              := cn_created_by;
              g_xvdh_tab(gn_xvdh_idx).creation_date           := cd_creation_date;
              g_xvdh_tab(gn_xvdh_idx).last_updated_by         := cn_last_updated_by;
              g_xvdh_tab(gn_xvdh_idx).last_update_date        := cd_last_update_date;
              g_xvdh_tab(gn_xvdh_idx).last_update_login       := cn_last_update_login;
              g_xvdh_tab(gn_xvdh_idx).request_id              := cn_request_id;
              g_xvdh_tab(gn_xvdh_idx).program_application_id  := cn_program_application_id;
              g_xvdh_tab(gn_xvdh_idx).program_id              := cn_program_id;
              g_xvdh_tab(gn_xvdh_idx).program_update_date     := cd_program_update_date;
-- == 2010/04/05 V1.15 Added START ===============================================================
              g_xvdh_tab(gn_xvdh_idx).summary_data_flag       :=  cv_n;
-- == 2010/04/05 V1.15 Added END   ===============================================================
              -- ===================================================
              --  警告件数用カウント
              -- ===================================================
              IF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_both_nof ) THEN
                gn_warn_cnt1              := gn_warn_cnt1 + 1;
              ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_ar_nof ) THEN
                gn_warn_cnt2              := gn_warn_cnt2 + 1;
              ELSIF ( g_xvdh_tab(gn_xvdh_idx).uncalculate_class = ct_uncalculate_class_vdc_nof ) THEN
                gn_warn_cnt3              := gn_warn_cnt3 + 1;
              END IF;
            --
            END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
          EXCEPTION
            WHEN skip_error_expt THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
              --
              IF ( tt_xvdh_cur%ISOPEN ) THEN
                CLOSE tt_xvdh_cur;
              END IF;
              --メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg --ユーザー・エラーメッセージ
              );
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errbuf --エラーメッセージ
              );
              --
            WHEN global_process_expt THEN
              IF ( tt_xvdh_cur%ISOPEN ) THEN
                CLOSE tt_xvdh_cur;
              END IF;
              RAISE global_process_expt;
          END;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
          --
        END LOOP cust_loop;
        --
        IF ( lv_cust_exists_flag1 = cv_exists_flag_yes ) THEN
-- 2010/02/15 Ver.1.13 K.Hosoi Del Start
--          -- ===================================================
--          -- A-3  消化VD用消化計算情報の今回データ削除
--          -- ===================================================
--          del_tt_vd_digestion(
--            ov_errbuf                   => lv_errbuf,                 -- エラー・メッセージ
--            ov_retcode                  => lv_retcode,                -- リターン・コード
--            ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
--          );
--          --
--          IF ( lv_retcode <> cv_status_normal ) THEN
--            RAISE global_process_expt;
--          END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Del End
          --
          -- ===================================================
          -- A-11 VDコラム別取引ヘッダ更新処理
          -- ===================================================
          upd_vd_column_hdr(
            ov_errbuf                   => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                  => lv_retcode,                -- リターン・コード
            ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-12 消化VD用消化計算ヘッダ登録処理
          -- ===================================================
          ins_vd_digestion_hdrs(
            ov_errbuf                   => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                  => lv_retcode,                -- リターン・コード
            ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
          -- ===================================================
          -- A-10 消化VD用消化計算明細登録処理
          -- ===================================================
          ins_vd_digestion_lns(
            ov_errbuf                   => lv_errbuf,                 -- エラー・メッセージ
            ov_retcode                  => lv_retcode,                -- リターン・コード
            ov_errmsg                   => lv_errmsg                  -- ユーザー・エラー・メッセージ
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added START ===============================================================
          -- ===================================================
          -- A-20 前回未計算データ更新処理
          -- ===================================================
          upd_pre_not_digestion_due(
              ov_errbuf                 =>    lv_errbuf
            , ov_retcode                =>    lv_retcode
            , ov_errmsg                 =>    lv_errmsg
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          --
-- == 2010/04/05 V1.15 Added END   ===============================================================
        END IF;
        --
      END LOOP calc_due_loop;
      --
      IF ( lv_cust_exists_flag2 = cv_exists_flag_no ) THEN
        RAISE global_target_nodata_expt;
      END IF;
    END IF;
--
    COMMIT;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    IF ( gn_thrshld_chk_cnt > 0) THEN
      RAISE thrshld_chk_expt;
    END IF;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
--
  EXCEPTION
    -- *** 対象データ無し例外ハンドラ ***
    WHEN global_target_nodata_expt THEN
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_target_nodata_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
--
    -- *** 閾値チェック有り例外ハンドラ ***
    WHEN thrshld_chk_expt THEN
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_thrshld_chk_err,
                                   iv_token_name1        => cv_tkn_max_thrshld,
                                   iv_token_value1       => TO_CHAR(gn_max_threshold),
                                   iv_token_name2        => cv_tkn_min_thrshld,
                                   iv_token_value2       => TO_CHAR(gn_min_threshold)
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
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
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_regular_any_class      IN      VARCHAR2,         -- 1.定期随時区分
    iv_base_code              IN      VARCHAR2,         -- 1.拠点コード
    iv_customer_number        IN      VARCHAR2,          -- 2.顧客コード
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
    iv_process_date           IN      VARCHAR2
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';      -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';         -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_regular_any_class                -- 1.定期随時区分
      ,iv_base_code                        -- 2.拠点コード
      ,iv_customer_number                  -- 3.顧客コード
--******************************** 2009/04/01 1.8 N.Maeda ADD START **************************************************
      ,iv_process_date                     -- 4.業務日付
--******************************** 2009/05/01 1.8 N.Maeda ADD END   **************************************************
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_target_count
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt1 )
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR( gn_target_cnt2 )
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR( gn_target_cnt3 )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- 2010/02/15 Ver.1.13 K.Hosoi Add Start
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- 2010/02/15 Ver.1.13 K.Hosoi Add End
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application  => ct_xxcos_appl_short_name
                  ,iv_name         => ct_msg_warning_count
                  ,iv_token_name1  => cv_tkn_count1
                  ,iv_token_value1 => TO_CHAR( gn_warn_cnt1 )
                  ,iv_token_name2  => cv_tkn_count2
                  ,iv_token_value2 => TO_CHAR( gn_warn_cnt2 )
                  ,iv_token_name3  => cv_tkn_count3
                  ,iv_token_value3 => TO_CHAR( gn_warn_cnt3 )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
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
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
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
END XXCOS004A06C;
/
