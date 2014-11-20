CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (body)
 * Description      : 受注一覧リスト
 * MD.050           : 受注一覧リスト MD050_COS_009_A01
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック(A-2)
 *  get_data               対象データ取得(A-3)
 *  insert_rpt_wrk_data    帳票ワークテーブル登録(A-4)
 *  update_order_line_data 受注明細出力済み更新（EDI取込のみ）(A-5)
 *  execute_svf            SVF起動(A-6)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   T.TYOU           新規作成
 *  2009/02/12    1.1   T.TYOU           [障害番号：064]保管場所の外部結合条件足りない
 *  2009/02/17    1.2   T.TYOU           get_msgのパッケージ名修正
 *  2009/04/14    1.3   T.Kiriu          [T1_0470]顧客発注番号取得元修正
 *  2009/05/08    1.4   T.Kitajima       [T1_0925]出荷先コード変更
 *  2009/06/19    1.5   N.Nishimura      [T1_1437]データパージ不具合対応
 *  2009/07/13    1.6   K.Kiriu          [0000063]情報区分の課題対応
 *  2009/07/29    1.7   T.Tominaga       [0000271]受注ソースがEDI受注とそれ以外とでカーソルを分ける（EDI受注のみロック）
 *  2009/10/02    1.8   N.Maeda          [0001338]execute_svfの独立トランザクション化
 *  2009/12/28    1.9   K.Kiriui         [E_本稼動_00407]EDI帳票再出力対応
 *                                       [E_本稼動_00409]帳票出力順序変更対応
 *                                       [E_本稼動_00583]伝票区分、分類区分出力対応
 *                                       [E_本稼動_00700]明細金額の端数処理変更対応
 *  2010/01/22    1.9   Y.Kikuchi        [E_本稼動_00408]伝票計出力対応
 *  2010/03/08    1.10  M.Sano           [E_本稼動_01657]数量の参照元変更
 *  2010/03/29    1.11  M.Sano           [E_本稼動_02006]PT対応(その他（CSV/画面）)
 *  2010/04/01    1.12  M.Sano           [E_本稼動_01811]受注ソース「出荷実績依頼」追加対応
 *  2011/04/20    1.13  N.Horigome       [E_本稼動_03310]EDI取込時の受注抽出条件修正対応
 *  2012/01/30    1.14  K.Kiriu          [E_本稼動_08658]EDI出力時の出力数量変更対応
 *  2012/04/18    1.15  Y.Horikawa       [E_本稼動_09441]PT対応
 *  2012/09/13    1.16  K.Taniguchi      [E_本稼動_09939]EDI取込時の受注抽出条件修正対応
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
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id; --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 受注ソース種別取得例外 ***
  global_order_source_get_expt      EXCEPTION;
  --*** 書式チェック例外 ***
  global_format_chk_expt            EXCEPTION;
  --***受注日 日付逆転チェック例外 ***
  global_date_rever_o_chk_expt      EXCEPTION;
  --***出荷予定日 日付逆転チェック例外 ***
  global_date_rever_ss_chk_expt     EXCEPTION;
  --***納品予定日 日付逆転チェック例外 ***
  global_date_rever_so_chk_expt     EXCEPTION;
  --*** 処理対象データ登録例外 ***
  global_data_insert_expt           EXCEPTION;
  --*** 処理対象データ更新例外 ***
  global_data_update_expt           EXCEPTION;
  --*** SVF起動例外 ***
  global_svf_excute_expt            EXCEPTION;
  --*** 対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  --*** 対象データ削除例外 ***
  global_data_delete_expt           EXCEPTION;
/* 2009/12/28 Ver1.9 Add Start */
  --*** 帳票出力区分取得例外 ***
  global_report_output_get_expt     EXCEPTION;
  --*** EDI帳票日付指定なし例外 ***
  global_edi_date_chk_expt          EXCEPTION;
  --*** 受信日 日付逆転チェック例外 ***
  global_date_rever_ocd_chk_expt    EXCEPTION;
  --*** 納品日 日付逆転チェック例外 ***
  global_date_rever_odh_chk_expt    EXCEPTION;
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  --*** 受注ステータス名取得例外 ***
  global_order_status_get_expt      EXCEPTION;
  --*** 受注ソース参照先頭文字取得例外 ***
  global_orig_sys_st_get_expt       EXCEPTION;
/* 2010/04/01 Ver1.12 Add End   */
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- パッケージ名
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- コンカレント名
  --帳票出力関連
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- 帳票ＩＤ
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A01S.xml';     -- フォーム様式ファイル名
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A01S.vrq';     -- クエリー様式ファイル名
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- 出力区分(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- 拡張子(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- 販物領域短縮アプリ名
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- 共通領域短縮アプリ名
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                -- 在庫領域短縮アプリ名
  --メッセージ
  cv_str_profile_nm         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00047';    -- MO:営業単位
  cv_msg_format_check_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- 日付書式チェックエラーメッセージ
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- データ登録エラーメッセージ
  cv_msg_update_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00011';    -- データ更新エラーメッセージ
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- 明細0件エラーメッセージ
  cv_msg_select_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00013';    -- データ抽出エラーメッセージ
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ロック取得エラーメッセージ
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- データ削除エラーメッセージ
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- APIエラーメッセージ
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00005';    -- 在庫組織コード取得エラーメッセージ
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00006';    -- 在庫組織ID取得エラーメッセージ
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11801';    -- パラメータ出力メッセージ
  cv_msg_parameter1         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11812';    -- パラメータ出力メッセージ(EDI用)（新規）
  cv_msg_order_source       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11811';    -- 受注ソース取得エラーメッセージ
/* 2009/12/28 Ver1.9 Add Start */
  cv_msg_rep_out_type_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11813';    -- 帳票出力区分取得エラーメッセージ
  cv_msg_parameter2         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11814';    -- パラメータ出力メッセージ(EDI用)（再出力）
  cv_msg_edi_date_err       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11819';    -- EDI帳票日付指定なしエラー
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_msg_order_status_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11823';    -- 受注ステータス名称取得エラー
  cv_msg_orig_sys_st_err    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11824';    -- 受注ソース参照先頭文字取得エラー
/* 2010/04/01 Ver1.12 Add End   */
  --トークン名
  cv_tkn_nm_account              CONSTANT  VARCHAR2(100) :=  'ACCOUNT_NAME';   --会計期間種別名称
  cv_tkn_nm_para_date            CONSTANT  VARCHAR2(100) :=  'PARA_DATE';      --受注日(FROM)または受注日(TO)
  cv_tkn_nm_order_source         CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_ID';              --   受注ソース
  cv_tkn_nm_base_code            CONSTANT  VARCHAR2(100) :=  'DELIVERY_BASE_CODE';           --   納品拠点コード
  cv_tkn_nm_date_from            CONSTANT  VARCHAR2(100) :=  'DATE_FROM';                    --   (FROM)
  cv_tkn_nm_date_to              CONSTANT  VARCHAR2(100) :=  'DATE_TO';                      --   (TO)
  cv_tkn_nm_ordered_date_f_t     CONSTANT  VARCHAR2(100) :=  'ORDERED_DATE_FROM_TO';         --   受注日(FROM),(TO)
  cv_tkn_nm_s_ship_date_f_t      CONSTANT  VARCHAR2(100) :=  'SCHEDULE_SHIP_DATE_FROM_TO';   --   出荷予定日(FROM),(TO)
  cv_tkn_nm_s_ordered_date_f_t   CONSTANT  VARCHAR2(100) :=  'SCHEDULE_ORDERED_DATE_FROM_TO';--   納品予定日(FROM),(TO)
  cv_tkn_nm_entered_by_code      CONSTANT  VARCHAR2(100) :=  'ENTERED_BY_CODE';             --   入力者コード
  cv_tkn_nm_ship_to_code         CONSTANT  VARCHAR2(100) :=  'SHIP_TO_CODE';                --   出荷先コード
  cv_tkn_nm_subinventory         CONSTANT  VARCHAR2(100) :=  'SUBINVENTORY';                --   保管場所
  cv_tkn_nm_order_numbe          CONSTANT  VARCHAR2(100) :=  'ORDER_NUMBER';                --   受注番号 
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --テーブル名称
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';               --テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --キーデータ
  cv_tkn_nm_api_name             CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API名称
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             --プロファイル名(販売領域)
  cv_tkn_nm_profile2             CONSTANT  VARCHAR2(100) :=  'PRO_TOK';             --プロファイル名(在庫領域)
  cv_tkn_nm_org_cd               CONSTANT  VARCHAR2(100) :=  'ORG_CODE_TOK';        --在庫組織コード
  cv_tkn_nm_acc_type             CONSTANT  VARCHAR2(100) :=  'TYPE';                --会計期間区分参照タイプ
/* 2009/12/28 Ver1.9 Add Start */
  cv_tkn_nm_rep_out_type        CONSTANT  VARCHAR2(100)  :=  'REPORT_OUTPUT_TYPE';          --帳票出力区分
  cv_tkn_nm_chain_code          CONSTANT  VARCHAR2(100)  :=  'CHAIN_CODE';                  --チェーン店コード
  cv_tkn_nm_order_c_date_f_t    CONSTANT  VARCHAR2(100)  :=  'ORDER_CREATION_DATE_FROM_TO'; --受信日(FROM),(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_tkn_nm_order_source_name    CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_NAME';   --受注ソース名
  cv_tkn_nm_order_status         CONSTANT  VARCHAR2(100) :=  'ORDER_STATUS';        --ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
  cv_tkn_output_quantity_type    CONSTANT  VARCHAR2(100) :=  'OUTPUT_QUANTITY_TYPE'; --出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
  --トークン値
  cv_msg_vl_order_date_from      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11802';    --受注日(FROM)
  cv_msg_vl_order_date_to        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11803';    --受注日(TO)
  cv_msg_vl_s_ship_date_from     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11804';    --出荷予定日(FROM)
  cv_msg_vl_s_ship_date_to       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11805';    --出荷予定日(TO)
  cv_msg_vl_s_order_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11806';    --納品予定日(FROM)
  cv_msg_vl_s_order_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11807';    --納品予定日(TO)
  cv_msg_vl_table_name1          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11808';    --受注一覧リスト帳票ワークテーブル
  cv_msg_vl_table_name2          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11809';    --受注テーブル
  cv_msg_vl_table_name3          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11810';    --受注明細テーブル
  cv_msg_vl_api_name             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API名称
  cv_msg_vl_key_request_id       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --要求ID
  cv_msg_vl_min_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN日付
  cv_msg_vl_max_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX日付
/* 2009/12/28 Ver1.9 Add Start */
  cv_msg_vl_order_c_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11815';    --受信日(FROM)
  cv_msg_vl_order_c_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11816';    --受信日(TO)
  cv_msg_vl_order_date_h_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11817';    --納品日(FROM)
  cv_msg_vl_order_date_h_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11818';    --納品日(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_msg_vl_order_source_edi     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11820';    --EDI取込
  cv_msg_vl_order_source_clik    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11821';    --クイック受注入力
  cv_msg_vl_order_source_ship    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11822';    --出荷実績依頼
/* 2010/04/01 Ver1.12 Add End   */
  --受注明細ステータス
  ct_ln_status_closed       CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --クローズ
  ct_ln_status_cancelled    CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --取消
  --日付フォーマット
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';              --YYYYMMDD型
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD型
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';               --YYYY/MM型
  cv_yyyymmddhhmiss         CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD HH24:mi:ss'; --YYYYMMDDHHMISS型
  --クイックコード参照用
  --使用可能フラグ定数
  cv_emp                    CONSTANT  VARCHAR2(100) := 'EMP';                  -- EMP
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                   --使用可能
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );     --言語
  cv_return                 CONSTANT  VARCHAR2(100) :=  'RETURN';              --マイナスタイプ
  cv_type_ost_009_a01       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_TYPE_009_A01';
                                                                               --受注ソース種別
/* 2009/12/28 Ver1.9 Add Start */
  cv_type_rot               CONSTANT  VARCHAR2(100) :=  'XXCOS1_REPORT_OUTPUT_TYPE';
                                                                               --帳票出力区分
/* 2010/04/01 Ver1.12 Add Start */
  cv_type_orig_sys_st       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ORDER_HEADERS_008_A06';
                                                                               --受注ソース参照先頭文字 
  cv_type_status_name       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_STATUS_009_A01';
                                                                               --受注一覧リスト対象ステータス
/* 2010/04/01 Ver1.12 Add End   */
  cv_code_rot_1             CONSTANT  VARCHAR2(100) :=  '1';                   --'1'(新規)
/* 2009/12/28 Ver1.9 Add End   */
  cv_code_ost_009_a01       CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A01%';      --受注ソースのクイックコード
  cv_diff_y                 CONSTANT  VARCHAR2(100) :=  'Y';                   --Y
/* 2010/04/01 Ver1.12 Add Start */
  ct_lookup_code_ship       CONSTANT  fnd_lookup_values.lookup_code%TYPE       --「受注ソース参照先頭文字」の
                                                    :=  '10';                  --クイックコード(出荷実績依頼)
  ct_lookup_code_clik       CONSTANT  fnd_lookup_values.lookup_code%TYPE       --「受注ソース参照先頭文字」の
                                                    :=  '20';                  --クイックコード(クイック受注)
/* 2010/04/01 Ver1.12 Add End   */
  --プロファイル関連
  cv_prof_org               CONSTANT  VARCHAR2(100) :=  'XXCOI1_ORGANIZATION_CODE';
                                                                               -- プロファイル名(在庫組織コード)
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- プロファイル名(MIN日付)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- プロファイル名(MAX日付)
  --MO:営業単位
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
/* 2009/07/13 Ver1.6 Add Start */
  --情報区分
  cv_target_order_01        CONSTANT  VARCHAR2(100) :=  '01';                  -- 受注作成対象01
/* 2009/07/13 Ver1.6 Add End   */
/* 2009/12/28 Ver1.9 Add Start */
  --帳票内条件判定
  cv_re_output_flag         CONSTANT  VARCHAR2(1)   := '1';                    -- EDI帳票再出力
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
  cn_record_type_detail     CONSTANT  NUMBER        := 1;                      -- レコードタイプ：明細
  cn_record_type_denpyokei  CONSTANT  NUMBER        := 2;                      -- レコードタイプ：伝票計
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
/* 2012/01/30 Ver1.14 Add Start */
  --出力数量区分
  cv_edi_quantity_type      CONSTANT  VARCHAR2(1)   := '1';                    -- 出力数量区分：EDI
  cv_oe_quantity_type       CONSTANT  VARCHAR2(1)   := '2';                    -- 出力数量区分：OE(画面)
/* 2012/01/30 Ver1.14 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  --その他定数
  cv_exists_yes             CONSTANT  VARCHAR2(1)   := 'Y';                    -- 存在チェック出力用
  cv_multi                  CONSTANT  VARCHAR2(1)   := '%';                    -- クイックの摘要の部分検索用
/* 2010/04/01 Ver1.12 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --受注明細テーブル型
  TYPE g_lines_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  --受注一覧リスト帳票ワークテーブル型
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_order_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_report_data_tab           g_rpt_data_ttype;                                  --帳票データコレクション
  gt_oola_rowid_tab           g_lines_rowid_ttype;                               --明細ROWID
  gt_org_id                   mtl_parameters.organization_id%TYPE;               --在庫組織ID
  gd_proc_date                DATE;                                              --業務日付
  gd_min_date                 DATE;                                              --MIN日付
  gd_max_date                 DATE;                                              --MAX日付
  gn_org_id                   NUMBER;                                            --営業単位
  gv_order_source_edi_chk     oe_order_sources.name%TYPE;                        --受注ソース（EDI取込）
  gv_order_source_clik_chk    oe_order_sources.name%TYPE;                        --受注ソース（クイック受注入力）
/* 2010/04/01 Ver1.12 Add Start */
  gv_order_source_ship_chk    oe_order_sources.name%TYPE;                        --受注ソース（出荷実績依頼）
  gt_orig_sys_st_value        fnd_lookup_values.meaning%TYPE DEFAULT '';         --外部システム受注番号先頭文字
/* 2010/04/01 Ver1.12 Add End   */
/* 2009/12/28 Ver1.9 Add Start */
  gt_report_output_type_n     fnd_lookup_values.meaning%TYPE;                    --出力区分（新規）
/* 2009/12/28 Ver1.9 Add End   */
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source                 IN     VARCHAR2,         --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,         --   納品拠点コード
    iv_ordered_date_from            IN     VARCHAR2,         --   受注日(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   受注日(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   出荷予定日(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   出荷予定日(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   納品予定日(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   納品予定日(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   入力者コード
    iv_ship_to_code                 IN     VARCHAR2,         --   出荷先コード
    iv_subinventory                 IN     VARCHAR2,         --   保管場所
    iv_order_number                 IN     VARCHAR2,         --   受注番号
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,         --   出力区分
    iv_chain_code                   IN     VARCHAR2,         --   チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,         --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   納品日(ヘッダ)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   納品日(ヘッダ)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,         --   受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,         --   出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
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
/* 2012/01/30 Ver1.14 Add Start */
    lt_output_quantity_type fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_OUTPUT_QUANTITY_TYPE';  --受注一覧用出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
--
    -- *** ローカル変数 ***
    lv_para_msg      VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lt_org_cd        mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
    lv_date_item     VARCHAR2(100);                          -- MIN日付/MAX日付
    lv_profile_name  VARCHAR2(100);                          -- 営業単位
/* 2010/04/01 Ver1.12 Add Start */
    lv_token_value1        VARCHAR2(100);                          -- エラーメッセージに出力するトークン値
    lt_order_status_name   fnd_lookup_values.description%TYPE;     -- 受注ステータス名称
/* 2010/04/01 Ver1.12 Add End   */
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
    -- 1.MO:営業単位
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_profile_nm
      );
      --プロファイル名文字列取得
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 2.在庫組織コード取得処理
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile2,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.在庫組織ID取得処理
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
    -- 4.業務日付取得処理
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
    -- 5.MIN日付取得処理
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
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.MAX日付取得処理
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
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 7.受注ソース種別取得の前処理
    --========================================
    BEGIN
      --EDI取込 受注ソースの名称を取得
      SELECT  look_val.description        order_source_edi
      INTO    gv_order_source_edi_chk
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute2         = cv_diff_y               --EDI取込
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
--
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
--      AND     look_val.lookup_type        = cv_type_ost_009_a01
--      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--      AND     look_val.attribute2         = cv_diff_y               --EDI取込
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
-- ******** 2009/10/02 1.8 N.Maeda MOD END ******** --
/* 2010/04/01 Ver1.12 Add Start */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_edi
        );
        RAISE global_order_source_get_expt;
    END;
--
    BEGIN
/* 2010/04/01 Ver1.12 Add End   */
      --クイック受注入力 受注ソースの名称を取得
      SELECT  look_val.description        order_source_clik
      INTO    gv_order_source_clik_chk
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute4         = cv_diff_y               --クイック受注入力
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
--
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
--      AND     look_val.lookup_type        = cv_type_ost_009_a01
--      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--      AND     look_val.attribute4         = cv_diff_y               --クイック受注入力
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
-- ******** 2009/10/02 1.8 N.Maeda MOD END ******** --
/* 2010/04/01 Ver1.12 Add Start */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_clik
        );
        RAISE global_order_source_get_expt;
    END;
--
    BEGIN
      --出荷実績依頼 受注ソースの名称を取得
      SELECT  look_val.description        order_source_clik
      INTO    gv_order_source_ship_chk
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute6         = cv_diff_y               --クイック受注入力
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
/* 2010/04/01 Ver1.12 Add End   */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
/* 2010/04/01 Ver1.12 Add Start */
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_ship
        );
/* 2010/04/01 Ver1.12 Add End   */
        RAISE global_order_source_get_expt;
    END;
--
/* 2009/12/28 Ver1.9 Add Start */
    --========================================
    -- 8.EDI帳票の場合の前処理
    --========================================
    IF ( iv_order_source = gv_order_source_edi_chk) THEN      --（EDI用）
      BEGIN
        --抽出条件の為、出力区分の新規を取得
        SELECT look_val.meaning
        INTO   gt_report_output_type_n
        FROM   fnd_lookup_values  look_val
        WHERE  look_val.language      =  cv_lang
        AND    look_val.lookup_type   =  cv_type_rot
        AND    look_val.lookup_code   =  cv_code_rot_1
        AND    gd_proc_date           >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date           <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag  =  ct_enabled_flg_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE global_report_output_get_expt;
      END;
    END IF;
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
--
    --========================================
    -- 9.外部システム受注番号先頭文字取得処理
    --========================================
    BEGIN
      IF (    iv_order_source = gv_order_source_clik_chk) THEN
        -- 「受注ソース参照先頭文字」の取得（クイック受注入力）
        SELECT look_val.meaning
        INTO   gt_orig_sys_st_value
        FROM   fnd_lookup_values           look_val
        WHERE  look_val.lookup_type        = cv_type_orig_sys_st
        AND    look_val.language           = cv_lang
        AND    gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag       = ct_enabled_flg_y
        AND    look_val.lookup_code        = ct_lookup_code_clik
        ;
      ELSIF ( iv_order_source = gv_order_source_ship_chk) THEN
        -- 「受注ソース参照先頭文字」の取得（出荷実績依頼）
        SELECT look_val.meaning
        INTO   gt_orig_sys_st_value
        FROM   fnd_lookup_values           look_val
        WHERE  look_val.lookup_type        = cv_type_orig_sys_st
        AND    look_val.language           = cv_lang
        AND    gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag       = ct_enabled_flg_y
        AND    look_val.lookup_code        = ct_lookup_code_ship
        ;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  iv_order_source
        );
        RAISE global_orig_sys_st_get_expt;
    END;
--
/* 2010/04/01 Ver1.12 Add End   */
    --========================================
    -- 10.パラメータ出力処理
    --========================================
    IF ( iv_order_source <> gv_order_source_edi_chk) THEN      --その他用（CSV/画面）
/* 2010/04/01 Ver1.12 Mod Start */
      -- 受注ステータスの名称取得
      IF ( iv_order_status IS NOT NULL ) THEN
        BEGIN
          --受注ステータス名の取得
          SELECT
              look_val.description
          INTO
              lt_order_status_name
          FROM
              fnd_lookup_values  look_val
          WHERE
          -- 参照タイプ固定条件(タイプ：受注一覧リスト対象ステータス)
              look_val.language      =  cv_lang
          AND look_val.lookup_type   =  cv_type_status_name
          AND gd_proc_date           >= NVL( look_val.start_date_active, gd_min_date )
          AND gd_proc_date           <= NVL( look_val.end_date_active, gd_max_date )
          AND look_val.enabled_flag  =  ct_enabled_flg_y
          -- 内容と入力パラメータ.受注ステータスが同一のもの
          AND look_val.meaning       =  iv_order_status
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE global_order_status_get_expt;
        END;
      END IF;
      -- パラメータの表示
/* 2010/04/01 Ver1.12 Mod End   */
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_ordered_date_f_t,
        iv_token_value3       =>  iv_ordered_date_from || ',' || iv_ordered_date_to,
        iv_token_name4        =>  cv_tkn_nm_s_ship_date_f_t,
        iv_token_value4       =>  iv_schedule_ship_date_from || ',' || iv_schedule_ship_date_to,
        iv_token_name5        =>  cv_tkn_nm_s_ordered_date_f_t,
        iv_token_value5       =>  iv_schedule_ordered_date_from || ',' || iv_schedule_ordered_date_to,
        iv_token_name6        =>  cv_tkn_nm_entered_by_code,
        iv_token_value6       =>  iv_entered_by_code,
        iv_token_name7        =>  cv_tkn_nm_ship_to_code,
        iv_token_value7       =>  iv_ship_to_code,
        iv_token_name8        =>  cv_tkn_nm_subinventory,
        iv_token_value8       =>  iv_subinventory,
        iv_token_name9        =>  cv_tkn_nm_order_numbe,
/* 2010/04/01 Ver1.12 Mod Start */
--        iv_token_value9       =>  iv_order_number
        iv_token_value9       =>  iv_order_number,
        iv_token_name10       =>  cv_tkn_nm_order_status,
        iv_token_value10      =>  lt_order_status_name
/* 2010/04/01 Ver1.12 Mod End   */
      );
/* 2009/12/28 Ver1.9 Mod Start */
--    ELSE                                                      --EDI用
    ELSIF ( iv_output_type = gt_report_output_type_n ) THEN   --EDI（新規）
/* 2009/12/28 Ver1.9 Mod End   */
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter1,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
/* 2009/12/28 Ver1.9 Mod Start */
--        iv_token_value2       =>  iv_delivery_base_code
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
/* 2012/01/30 Ver1.14 Mod Start */
--        iv_token_value3       =>  iv_output_type
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_output_quantity_type,
        iv_token_value4       =>  xxcos_common_pkg.get_specific_master(
                                    lt_output_quantity_type
                                   ,iv_output_quantity_type
                                  )
/* 2012/01/30 Ver1.14 Mod End   */
/* 2009/12/28 Ver1.9 Mod End   */
      );
/* 2009/12/28 Ver1.9 Add Start */
    ELSE
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter2,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_nm_chain_code,
        iv_token_value4       =>  iv_chain_code,
        iv_token_name5        =>  cv_tkn_nm_order_c_date_f_t,
        iv_token_value5       =>  iv_order_creation_date_from || ',' || iv_order_creation_date_to,
        iv_token_name6        =>  cv_tkn_nm_s_ordered_date_f_t,
/* 2012/01/30 Ver1.14 Mod Start */
--        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to
        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to,
        iv_token_name7        =>  cv_tkn_output_quantity_type,
        iv_token_value7       =>  xxcos_common_pkg.get_specific_master(
                                    lt_output_quantity_type
                                   ,iv_output_quantity_type
                                  )
/* 2012/01/30 Ver1.14 Mod End   */
      );
/* 2009/12/28 Ver1.9 Add End   */
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
--
  EXCEPTION
    -- *** 受注ソース種別取得例外ハンドラ ***
    WHEN global_order_source_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
/* 2010/04/01 Ver1.12 Mod Start */
--        iv_name               =>  cv_msg_order_source
        iv_name               =>  cv_msg_order_source,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
/* 2010/04/01 Ver1.12 Mod End   */
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add Start */
    -- *** 帳票出力区分取得例外ハンドラ ***
    WHEN global_report_output_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_rep_out_type_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add End   */
--
/* 2010/04/01 Ver1.12 Add Start */
    -- *** 受注ステータス名取得例外ハンドラ ***
    WHEN global_order_status_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_order_status_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 受注ソース参照先頭文字取得例外ハンドラ ***
    WHEN global_orig_sys_st_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_orig_sys_st_err,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
/* 2010/04/01 Ver1.12 Add End   */
--#################################  固定例外処理部 START   ####################################
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_ordered_date_from            IN     VARCHAR2,     --   受注日(FROM)
    iv_ordered_date_to              IN     VARCHAR2,     --   受注日(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,     --   出荷予定日(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,     --   出荷予定日(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,     --   納品予定日(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,     --   納品予定日(TO)
/* 2009/12/28 Ver1.9 Add Start */
    iv_order_creation_date_from     IN     VARCHAR2,     --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,     --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,     --   納品日(ヘッダ)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,     --   納品日(ヘッダ)(TO)
    iv_order_source                 IN     VARCHAR2,     --   受注ソース
    iv_output_type                  IN     VARCHAR2,     -- 出力区分
/* 2009/12/28 Ver1.9 Add End   */
    od_ordered_date_from            OUT    DATE,         --   受注日(FROM)_チェックOK
    od_ordered_date_to              OUT    DATE,         --   受注日(TO)_チェックOK
    od_schedule_ship_date_from      OUT    DATE,         --   出荷予定日(FROM)_チェックOK
    od_schedule_ship_date_to        OUT    DATE,         --   出荷予定日(TO)_チェックOK
    od_schedule_ordered_date_from   OUT    DATE,         --   納品予定日(FROM)_チェックOK
    od_schedule_ordered_date_to     OUT    DATE,         --   納品予定日(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add Start */
    od_order_creation_date_from     OUT    DATE,         --   受信日(FROM)_チェックOK
    od_order_creation_date_to       OUT    DATE,         --   受信日(TO)_チェックOK
    od_ordered_date_h_from          OUT    DATE,         --   納品日(ヘッダ)(FROM)_チェックOK
    od_ordered_date_h_to            OUT    DATE,         --   納品日(ヘッダ)(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add End   */
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    lv_check_item                    VARCHAR2(100);      --受注日(FROM)又は受注日(TO)文言
    lv_check_item1                   VARCHAR2(100);      --受注日(FROM)文言
    lv_check_item2                   VARCHAR2(100);      --受注日(TO)文言
    ld_ordered_date_from             DATE;               -- 受注日(FROM)
    ld_ordered_date_to               DATE;               -- 受注日(TO)
    ld_schedule_ship_date_from       DATE;               -- 出荷予定日(FROM)
    ld_schedule_ship_date_to         DATE;               -- 出荷予定日(TO)
    ld_schedule_ordered_date_from    DATE;               -- 納品予定日(FROM)
    ld_schedule_ordered_date_to      DATE;               -- 納品予定日(TO)
/* 2009/12/28 Ver1.9 Add Start */
    ld_order_creation_date_from      DATE;               -- 受信日(FROM)_チェックOK
    ld_order_creation_date_to        DATE;               -- 受信日(TO)_チェックOK
    ld_ordered_date_h_from           DATE;               -- 納品日(ヘッダ)(FROM)_チェックOK
    ld_ordered_date_h_to             DATE;               -- 納品日(ヘッダ)(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add End   */
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
    --受注日(FROM)必須チェック
    IF ( ( iv_ordered_date_from IS NULL ) AND ( iv_ordered_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_order_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --受注日(TO)必須チェック
    IF ( ( iv_ordered_date_from IS NOT NULL ) AND ( iv_ordered_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_order_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --受注日(FROM)、受注日(TO)両方入力された場合
    IF ( ( iv_ordered_date_from IS NOT NULL ) AND ( iv_ordered_date_to IS NOT NULL ) ) THEN
      --受注日(FROM)書式チェック
      ld_ordered_date_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_from, cv_yyyy_mm_dd );
      IF ( ld_ordered_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --受注日(TO)書式チェック
      ld_ordered_date_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_to, cv_yyyy_mm_dd );
      IF ( ld_ordered_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --受注日(FROM)／-受注日(TO)日付逆転チェック
      IF ( ld_ordered_date_from > ld_ordered_date_to ) THEN
        RAISE global_date_rever_o_chk_expt;
      END IF;
    END IF;
--
    --出荷予定日(FROM)必須チェック
    IF ( ( iv_schedule_ship_date_from IS NULL ) AND ( iv_schedule_ship_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_ship_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --出荷予定日(TO)必須チェック
    IF ( ( iv_schedule_ship_date_from IS NOT NULL ) AND ( iv_schedule_ship_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_ship_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --出荷予定日(FROM)、出荷予定日(TO)両方入力された場合
    IF ( ( iv_schedule_ship_date_from IS NOT NULL ) AND ( iv_schedule_ship_date_to IS NOT NULL ) ) THEN
      --出荷予定日(FROM)書式チェック
      ld_schedule_ship_date_from := FND_DATE.STRING_TO_DATE( iv_schedule_ship_date_from, cv_yyyy_mm_dd );
      IF ( ld_schedule_ship_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_ship_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --出荷予定日(TO)書式チェック
      ld_schedule_ship_date_to := FND_DATE.STRING_TO_DATE( iv_schedule_ship_date_to, cv_yyyy_mm_dd );
      IF ( ld_schedule_ship_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_ship_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --出荷予定日(FROM)／--出荷予定日(TO)日付逆転チェック
      IF ( ld_schedule_ship_date_from > ld_schedule_ship_date_to ) THEN
        RAISE global_date_rever_ss_chk_expt;
      END IF;
    END IF;
--
    --納品予定日(FROM)必須チェック
    IF ( ( iv_schedule_ordered_date_from IS NULL ) AND ( iv_schedule_ordered_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_order_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --納品予定日(TO)必須チェック
    IF ( ( iv_schedule_ordered_date_from IS NOT NULL ) AND ( iv_schedule_ordered_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_order_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --納品予定日(FROM)、納品予定日(TO)両方入力された場合
    IF ( ( iv_schedule_ordered_date_from IS NOT NULL ) AND ( iv_schedule_ordered_date_to IS NOT NULL ) ) THEN
      --納品予定日(FROM)書式チェック
      ld_schedule_ordered_date_from := FND_DATE.STRING_TO_DATE( iv_schedule_ordered_date_from, cv_yyyy_mm_dd );
      IF ( ld_schedule_ordered_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_order_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --納品予定日(TO)書式チェック
      ld_schedule_ordered_date_to := FND_DATE.STRING_TO_DATE( iv_schedule_ordered_date_to, cv_yyyy_mm_dd );
      IF ( ld_schedule_ordered_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_order_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --納品予定日(FROM)／--納品予定日(TO)日付逆転チェック
      IF ( ld_schedule_ordered_date_from > ld_schedule_ordered_date_to ) THEN
        RAISE global_date_rever_so_chk_expt;
      END IF;
    END IF;
/* 2009/12/28 Ver1.9 Add Start */
    --EDI帳票再出力時の日付チェック
    IF ( iv_order_source = gv_order_source_edi_chk ) AND ( iv_output_type <> gt_report_output_type_n ) THEN
--
      --受信日、納品日のいづれの入力チェック
      IF ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NULL )
        AND ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NULL )
      THEN
        RAISE global_edi_date_chk_expt;
      END IF;
--
      --受信日(FROM)必須チェック
      IF ( ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --受信日(TO)必須チェック
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --受信日(FROM)、受信日(TO)両方入力された場合
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        --受信日(FROM)書式チェック
        ld_order_creation_date_from := FND_DATE.STRING_TO_DATE( iv_order_creation_date_from, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --受信日(TO)書式チェック
        ld_order_creation_date_to := FND_DATE.STRING_TO_DATE( iv_order_creation_date_to, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_to
          );
          RAISE global_format_chk_expt;
        END IF;
--
        --受信日(FROM)／--受信日(TO)日付逆転チェック
        IF ( ld_order_creation_date_from > ld_order_creation_date_to ) THEN
          RAISE global_date_rever_ocd_chk_expt;
        END IF;
      END IF;
--
      --納品日(FROM)必須チェック
      IF ( ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --納品日(TO)必須チェック
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --納品日(FROM)、納品日(TO)両方入力された場合
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        --納品日(FROM)書式チェック
        ld_ordered_date_h_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_from, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --納品日(TO)書式チェック
        ld_ordered_date_h_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_to, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_to
          );
          RAISE global_format_chk_expt;
        END IF;
--
        --納品日(FROM)／--納品日(TO)日付逆転チェック
        IF ( ld_ordered_date_h_from > ld_ordered_date_h_to ) THEN
          RAISE global_date_rever_odh_chk_expt;
        END IF;
      END IF;
--
    END IF;
/* 2009/12/28 Ver1.9 Add End   */
--
--
    --チェックOK
    od_ordered_date_from          := ld_ordered_date_from;
    od_ordered_date_to            := ld_ordered_date_to;
    od_schedule_ship_date_from    := ld_schedule_ship_date_from;
    od_schedule_ship_date_to      := ld_schedule_ship_date_to;
    od_schedule_ordered_date_from := ld_schedule_ordered_date_from;
    od_schedule_ordered_date_to   := ld_schedule_ordered_date_to;
/* 2009/12/28 Ver1.9 Add Start */
    od_order_creation_date_from   := ld_order_creation_date_from;
    od_order_creation_date_to     := ld_order_creation_date_to;
    od_ordered_date_h_from        := ld_ordered_date_h_from;
    od_ordered_date_h_to          := ld_ordered_date_h_to;
/* 2009/12/28 Ver1.9 Add End   */
--
  EXCEPTION
    -- *** 書式チェック例外ハンドラ ***
    WHEN global_format_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_format_check_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***受注日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_o_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***出荷予定日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_ss_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_ship_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_ship_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***納品予定日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_so_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_order_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_order_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add Start */
    -- ***EDI帳票日付指定なし例外ハンドラ ***
    WHEN global_edi_date_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_edi_date_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***受信日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_ocd_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***納品日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_odh_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add End  */
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_order_source                 IN     VARCHAR2,     --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,     --   納品拠点コード
    ld_ordered_date_from            IN     DATE,         --   受注日(FROM)
    ld_ordered_date_to              IN     DATE,         --   受注日(TO)
    ld_schedule_ship_date_from      IN     DATE,         --   出荷予定日(FROM)
    ld_schedule_ship_date_to        IN     DATE,         --   出荷予定日(TO)
    ld_schedule_ordered_date_from   IN     DATE,         --   納品予定日(FROM)
    ld_schedule_ordered_date_to     IN     DATE,         --   納品予定日(TO)
    iv_entered_by_code              IN     VARCHAR2,     --   入力者コード
    iv_ship_to_code                 IN     VARCHAR2,     --   出荷先コード
    iv_subinventory                 IN     VARCHAR2,     --   保管場所
    iv_order_number                 IN     VARCHAR2,     --   受注番号
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,     --   出力区分
    iv_chain_code                   IN     VARCHAR2,     --   チェーン店コード
    id_order_creation_date_from     IN     DATE,         --   受信日(FROM)
    id_order_creation_date_to       IN     DATE,         --   受信日(TO)
    id_ordered_date_h_from          IN     DATE,         --   納品日(ヘッダ)(FROM)
    id_ordered_date_h_to            IN     DATE,         --   納品日(ヘッダ)(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,     --   受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,     --   出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_tkn_vl_table_name      VARCHAR2(100);                          --テーブル名称(文言)
    ln_idx                    NUMBER;                                 --メインループカウント
    lt_record_id              xxcos_rep_order_list.record_id%TYPE;    --レコードID
--
    -- *** ローカル・カーソル ***
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    CURSOR data_edi_or_not_cur
    -- 受注ソースタイプ：EDI取込の場合
    CURSOR data_edi_cur
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
    IS
      SELECT
/* 2009/12/28 Ver1.9 Add Start */
        /*+
-- 2012/04/18 Ver1.15 Mod Start
--            LEADING(xca)
--            USE_NL(xca xca_c hca hca_c ooha oos jrs jrre papf1)
            LEADING(xca hca hp xca_c hca_c hp_c xeh ooha oos jrs jrre papf1 ppt1 fu papf ppt)
            USE_NL(xca hca hp xca_c hca_c hp_c xeh ooha oos jrs jrre papf1 ppt1 fu papf ppt)
-- 2012/04/18 Ver1.15 Mod End
        */
/* 2009/12/28 Ver1.9 Add End   */
        oola.rowid                             AS row_id                     -- rowid
        ,ooha.order_source_id                  AS order_source_id            -- 受注ソース
        ,oos.name                              AS order_source               -- 受注ソース
        ,papf.employee_number                  AS entered_by_code            -- 入力者コード
        ,papf.per_information18 || ' ' || papf.per_information19
                                               AS entered_by_name            -- 入力者名
--****************************** 2009/05/08 1.4 T.Kitajima MOD START ******************************--
--        ,oola.ship_to_org_id                   AS deliver_from_code          -- 出荷先コード
        ,hca.account_number                   AS deliver_from_code           -- 出荷先コード
--****************************** 2009/05/08 1.4 T.Kitajima MOD START ******************************--
        ,hp.party_name                         AS deliver_to_name            -- 顧客名称
        ,ooha.order_number                     AS order_number               -- 受注番号
        ,oola.line_number                      AS line_number                -- 明細番号
-- 2009/04/14 Mod Start
--        ,oola.cust_po_number                   AS party_order_number         -- 顧客発注番号
        ,ooha.cust_po_number                   AS party_order_number         -- 顧客発注番号
-- 2009/04/14 Mod End
        ,oola.schedule_ship_date               AS shipped_date               -- 出荷日
        ,oola.request_date                     AS dlv_date                   -- 納品日
        ,oola.ordered_item                     AS order_item_no              -- 受注品番号
        ,ximb.item_short_name                  AS order_item_name            -- 受注品目名
        ,otta.order_category_code              AS order_category_code        -- カテゴリ
/* 2010/03/08 Ver1.10 Add Start */
--        ,oola.ordered_quantity                 AS quantity                   -- 数量
/* 2012/01/30 Ver1.14 Mod Start */
--        ,NVL( ( SELECT xel.sum_order_qty
--                FROM   xxcos_edi_lines        xel
--                WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
--                AND    xel.order_connection_line_number
--                                              = oola.orig_sys_line_ref )
--             , oola.ordered_quantity )         AS quantity                   -- 数量
        ,CASE
           --出力数量区分が"1"(EDIの数量)の場合
           WHEN iv_output_quantity_type = cv_edi_quantity_type THEN
             NVL( ( SELECT xel.sum_order_qty
                    FROM   xxcos_edi_lines        xel
                    WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
                    AND    xel.order_connection_line_number
                                              = oola.orig_sys_line_ref )
               , oola.ordered_quantity )
           --出力数量区分が"2"(受注画面の数量)の場合
           WHEN iv_output_quantity_type = cv_oe_quantity_type  THEN
             oola.ordered_quantity
         END                                   AS quantity                   -- 数量
/* 2012/01/30 Ver1.14 Mod End   */
/* 2010/03/08 Ver1.10 Add End   */
        ,oola.order_quantity_uom               AS uom_code                   -- 受注単位
        ,oola.unit_selling_price               AS dlv_unit_price             -- 販売単価
        ,oola.subinventory                     AS locat_code                 -- 保管場所コード
        ,msi.description                       AS locat_name                 -- 保管場所名称
        ,ooha.shipping_instructions            AS shipping_instructions      -- 出荷指示
        ,ooha.attribute19                      AS order_no                   -- オーダーNo.
        ,jrre.source_number                    AS base_employee_num          -- 営業担当コード
        ,papf1.per_information18 || ' ' || papf1.per_information19
                                               AS base_employee_name         -- 営業担当名
/* 2009/12/28 Ver1.9 Add Start */
        ,ooha.attribute5                       AS invoice_class              -- 伝票区分
        ,ooha.attribute20                      AS classification_class       -- 分類区分
        ,iv_output_type                        AS report_output_type         -- 出力区分
        ,DECODE( iv_output_type
                ,gt_report_output_type_n, NULL
                ,cv_re_output_flag
         )                                     AS edi_re_output_flag         -- EDI再出力フラグ
        ,xca.chain_store_code                  AS chain_code                 -- チェーン店コード
        ,hp_c.party_name                       AS chain_name                 -- チェーン店名称
        ,id_order_creation_date_from           AS order_creation_date_from   -- 受信日(FROM)(パラメータ)
        ,id_order_creation_date_to             AS order_creation_date_to     -- 受信日(TO)(パラメータ)
        ,id_ordered_date_h_from                AS dlv_date_header_from       -- 納品日(FROM)(パラメータ)
        ,id_ordered_date_h_to                  AS dlv_date_header_to         -- 納品日(TO)(パラメータ)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
        ,ooha.request_date                     AS dlv_date_header            --納品日(ヘッダ)
/* 2010/01/22 Ver1.9 Add End   E_本稼動_00408対応 */
      FROM
        oe_order_headers_all       ooha    -- 受注ヘッダ
        ,oe_order_lines_all        oola    -- 受注明細
        ,oe_order_sources          oos     -- 受注ソース
        ,hz_cust_accounts          hca     -- 顧客マスタ
        ,xxcmm_cust_accounts       xca     -- 顧客アドオン
        ,hz_parties                hp      -- パーティマスタ
        ,mtl_secondary_inventories msi     -- 保管場所マスタ
        ,mtl_system_items_b        msib    -- DISC品目
        ,ic_item_mst_b             iimb    -- OPM品目
        --,xxcmm_system_items_b      xsib    -- DISC品目アドオン
        ,xxcmn_item_mst_b          ximb    -- OPM品目アドオン
        ,fnd_user                  fu      -- ユーザマスタ
        ,per_all_people_f          papf    -- 従業員マスタ
        ,per_person_types          ppt     -- 従業員タイプマスタ
        ,jtf_rs_resource_extns     jrre    -- リソースマスタ
        ,jtf_rs_salesreps          jrs     -- jtf_rs_salesreps
        ,per_all_people_f          papf1   -- 従業員マスタ1
        ,per_person_types          ppt1    -- 従業員タイプマスタ1
        ,oe_transaction_types_all  otta    -- 受注明細摘要用取引タイプALL
        ,oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
/* 2009/12/28 Ver1.8 Add Start */
        ,hz_cust_accounts          hca_c   -- 顧客マスタ(チェーン店)
        ,xxcmm_cust_accounts       xca_c   -- 顧客アドオン(チェーン店)
        ,hz_parties                hp_c    -- パーティマスタ(チェーン店)
/* 2009/12/28 Ver1.8 Add End   */
/* 2010/03/08 Ver1.10 Add Start */
        ,xxcos_edi_headers         xeh     -- EDIヘッダ情報
/* 2010/03/08 Ver1.10 Add End   */
      WHERE
      -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
      ooha.header_id                        = oola.header_id
      -- 組織ID
      AND ooha.org_id                       = gn_org_id
      -- 受注ヘッダ.ソースID＝受注ソース.ソースID
      AND ooha.order_source_id              = oos.order_source_id
      -- 受注ソース名称（EDI受注、問屋CSV、国際CSV、Online）
      AND oos.name IN ( 
        SELECT  look_val.attribute1
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
        FROM    fnd_lookup_values           look_val
        WHERE   look_val.language           = cv_lang
        AND     look_val.lookup_type        = cv_type_ost_009_a01
        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND     look_val.enabled_flag       = ct_enabled_flg_y
        --受注ソース（EDI取込・CSV取込・クイック受注入力）
        AND     look_val.description        = iv_order_source
--
--        FROM    fnd_lookup_values           look_val,
--                fnd_lookup_types_tl         types_tl,
--                fnd_lookup_types            types,
--                fnd_application_tl          appl,
--                fnd_application             app
--        WHERE   appl.application_id         = types.application_id
--        AND     app.application_id          = appl.application_id
--        AND     types_tl.lookup_type        = look_val.lookup_type
--        AND     types.lookup_type           = types_tl.lookup_type
--        AND     types.security_group_id     = types_tl.security_group_id
--        AND     types.view_application_id   = types_tl.view_application_id
--        AND     types_tl.language           = cv_lang
--        AND     look_val.language           = cv_lang
--        AND     appl.language               = cv_lang
--        AND     app.application_short_name  = cv_xxcos_short_name
--        AND     look_val.lookup_type        = cv_type_ost_009_a01
--        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--        AND     look_val.enabled_flag       = ct_enabled_flg_y
--        --受注ソース（EDI取込・CSV取込・クイック受注入力）
--        AND     look_val.description        = iv_order_source
-- ******** 2009/10/02 1.8 N.Maeda MOD END  ******** --
      )
      --受注ヘッダ.顧客ID = 顧客マスタ.顧客ID
      AND ooha.sold_to_org_id               = hca.cust_account_id
      --顧客マスタ.顧客ID =顧客マスタアドオン.顧客ID
      AND hca.cust_account_id               = xca.customer_id
      --顧客マスタアドオン.納品拠点コード=パラメータ.拠点コード
      AND xca.delivery_base_code            = iv_delivery_base_code
      --顧客マスタ.パーティID = パーティマスタ.パーティID
      AND hca.party_id                      = hp.party_id 
      --ユーザマスタ.ユーザID=受注ヘッダ.最終更新者
      AND fu.user_id                        = ooha.last_updated_by
      --ユーザマスタ.従業員ID=従業員マスタ.従業員ID
      AND fu.employee_id                    = papf.person_id
      AND gd_proc_date                      >= NVL( papf.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf.effective_end_date, gd_max_date )
      AND ppt.business_group_id             = cn_per_business_group_id
      AND ppt.system_person_type            = cv_emp
      AND ppt.active_flag                   = ct_enabled_flg_y
      AND papf.person_type_id               = ppt.person_type_id
      --受注ヘッダ.営業担当ID=jtf_rs_salesreps.salesrep_id
      AND ooha.salesrep_id                  = jrs.salesrep_id
      --jtf_rs_salesreps.リソースID=リソースマスタ.リソースID
      AND jrs.resource_id                   = jrre.resource_id
      --リソースマスタ.ソース番号=従業員マスタ.従業員ID
      AND jrre.source_id                    = papf1.person_id
      AND gd_proc_date                      >= NVL( papf1.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf1.effective_end_date, gd_max_date )
      AND ppt1.business_group_id            = cn_per_business_group_id
      AND ppt1.system_person_type           = cv_emp
      AND ppt1.active_flag                  = ct_enabled_flg_y
      AND papf1.person_type_id              = ppt1.person_type_id
      -- 受注明細.保管場所=保管場所マスタ.保管場所コード
      AND oola.subinventory                 = msi.secondary_inventory_name(+)
      -- 受注明細.出荷元組織ID = 保管場所マスタ.組織ID
      AND oola.ship_from_org_id             = msi.organization_id(+)
      --受注明細.品目ID= 品目マスタ.品目ID
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND msib.organization_id              = gt_org_id
      AND msib.segment1                     = iimb.item_no
      AND iimb.item_id                      = ximb.item_id
      --AND msib.segment1                   = xsib.item_code
      --AND iimb.item_id                    = xsib.item_id
      AND gd_proc_date                      >= NVL( ximb.start_date_active, gd_min_date )
      AND gd_proc_date                      <= NVL( ximb.end_date_active, gd_max_date )
      --受注明細.明細タイプ＝受注タイプ.タイプ
      AND oola.line_type_id                 = otttl.transaction_type_id
      --受注タイプ.タイプ＝受注タイプALL.タイプ
      AND otttl.transaction_type_id         = otta.transaction_type_id
      --言語：JA
      AND otttl.language                    = cv_lang
/* 2009/12/28 Ver1.9 Add Start */
      -- 受注明細.受注日の年月≧業務日付－１の年月
      AND TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
        >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
/* 2012/09/13 1.16 Del Start */
--      -- 受注明細.ステータス≠取消
--      AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
/* 2012/09/13 1.16 Del End */
      --顧客マスタアドオン.チェーン店コード＝顧客マスタアドオン(チェーン店).チェーン店コード(EDI)【親レコード用】
      AND xca.chain_store_code              = xca_c.edi_chain_code
      --顧客マスタアドオン(チェーン店).顧客ID＝顧客マスタ(チェーン店).顧客ID
      AND xca_c.customer_id                 = hca_c.cust_account_id
      --顧客マスタ(チェーン店).パーティID＝パーティマスタ(チェーン店).パーティID
      AND hca_c.party_id                    = hp_c.party_id
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/03/08 Ver1.10 Add Start */
      --EDIヘッダ.受注関連番号＝受注ヘッダ.外部システム受注番号
      AND xeh.order_connection_number       = ooha.orig_sys_document_ref
/* 2010/03/08 Ver1.10 Add End   */
-- 2012/04/18 Ver1.15 Add Start
      AND xeh.conv_customer_code            = hca.account_number
-- 2012/04/18 Ver1.15 Add End
      AND ( 
/* 2009/12/28 Ver1.9 Mod Start */
--        --EDI取込の場合
--        ( iv_order_source                   = gv_order_source_edi_chk
--          --受注一覧出力日 IS NULL
--          AND oola.global_attribute1 IS NULL
--          -- 受注明細.受注日の年月≧業務日付－１の年月
--          AND TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
--            >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
--          -- 受注明細.ステータス≠取消
--          AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
        --新規出力の場合
        ( iv_output_type = gt_report_output_type_n
          --受注一覧出力日 IS NULL
          AND oola.global_attribute1 IS NULL
/* 2009/12/28 Ver1.9 Mod End */
        )
/* 2009/12/28 Ver1.9 Add  Start */
        OR
        --再出力の場合
        ( iv_output_type <> gt_report_output_type_n
          --受注一覧出力日 IS NOT NULL
          AND oola.global_attribute1 IS NOT NULL
          --顧客マスタ.チェーン店コード＝パラメータ.チェーン店コード
          AND (  iv_chain_code IS NULL
              OR xca.chain_store_code = iv_chain_code
              )
          AND (
            --パラメータ受信日がNLLL
            (
              id_order_creation_date_from IS NULL
              AND id_order_creation_date_to IS NULL
            )
            --パラメータ受信日に設定あり
            OR (
              --受注ヘッダ.作成日≧パラメータ.受信日（FROM）
              TRUNC( ooha.creation_date )     >= 
                  TRUNC( id_order_creation_date_from )
              --受注ヘッダ.作成日≦パラメータ.受信日（TO）
              AND TRUNC( ooha.creation_date ) <= TRUNC( id_order_creation_date_to )
            )
          )
          AND (
            --パラメータ納品日がNLLL
            (
              id_ordered_date_h_from IS NULL
              AND id_ordered_date_h_to IS NULL
            )
            --パラメータ納品日に設定あり
            OR (
              --受注ヘッダ.納品予定日≧パラメータ.納品日（FROM）
              TRUNC( ooha.request_date )     >= 
                  TRUNC( id_ordered_date_h_from )
              --受注ヘッダ.納品日予定日≦パラメータ.納品日（TO）
              AND TRUNC( ooha.request_date ) <= TRUNC( id_ordered_date_h_to )
            )
          )
        )
/* 2009/12/28 Ver1.9 Add  End   */
--****************************** 2009/07/29 1.7 T.Tominaga DEL START ******************************--
--        --CSV/その他の場合
--        OR ( 
--          iv_order_source <> gv_order_source_edi_chk 
--          -- 受注明細.ステータス≠ｸﾛｰｽﾞor取消
--          AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
--          AND (
--            --受注ヘッダとパラメータの受注日両方NULLの場合 退避する
--            ooha.ordered_date IS NULL
--            AND ld_ordered_date_from IS NULL
--            AND ld_ordered_date_to IS NULL
--            OR (
--              --受注ヘッダ.受注日≧パラメータ.受注日（FROM）
--              TRUNC( ooha.ordered_date )           >= NVL( ld_ordered_date_from, TRUNC( ooha.ordered_date ) )
--              --受注ヘッダ.受注日≦パラメータ.受注日（TO）
--              AND TRUNC( ooha.ordered_date )       <= NVL( ld_ordered_date_to, TRUNC( ooha.ordered_date ) )
--            )
--          )
--          AND (
--            --受注明細とパラメータの予定出荷日両方NULLの場合 退避する
--            oola.schedule_ship_date IS NULL
--            AND ld_schedule_ship_date_from IS NULL
--            AND ld_schedule_ship_date_to IS NULL
--            OR (
--              --受注明細.予定出荷日≧パラメータ.出荷予定日（FROM）
--              TRUNC( oola.schedule_ship_date )     >= 
--                  NVL( ld_schedule_ship_date_from, TRUNC( oola.schedule_ship_date ) )
--              --受注明細.予定出荷日≦パラメータ.出荷予定日（TO）
--              AND TRUNC( oola.schedule_ship_date ) <= NVL( ld_schedule_ship_date_to, TRUNC( oola.schedule_ship_date ) )
--            )
--          )
--          AND (
--            --受注明細とパラメータの要求日両方NULLの場合 退避する
--            oola.request_date IS NULL
--            AND ld_schedule_ordered_date_from IS NULL
--            AND ld_schedule_ordered_date_to IS NULL
--            OR (
--              --受注明細.要求日≧パラメータ.納品予定日（FROM）
--              TRUNC( oola.request_date )           >= NVL( ld_schedule_ordered_date_from, TRUNC( oola.request_date ) )
--              --受注明細.要求日≦パラメータ.納品予定日（TO）
--              AND TRUNC( oola.request_date )       <= NVL( ld_schedule_ordered_date_to, TRUNC( oola.request_date ) )
--            )
--          )
--          --従業員マスタ.従業員番号＝パラメータ.入力者
--          AND papf.employee_number             = NVL( iv_entered_by_code, papf.employee_number )
--          --顧客マスタ.顧客コード＝パラメータ.出荷先
--          AND hca.account_number               = NVL( iv_ship_to_code, hca.account_number )
--          AND (
--            --受注明細とパラメータの保管場所両方NULLの場合 退避する
--            oola.subinventory IS NULL
--            AND iv_subinventory IS NULL
--            OR (
--              --受注明細.保管場所＝パラメータ.保管場所
--              oola.subinventory                = NVL( iv_subinventory, oola.subinventory )
--            )
--          )
--          --受注ヘッダ.受注番号=パラメータ.受注番号
--          AND ooha.order_number                = NVL( iv_order_number, ooha.order_number )
--        )
--****************************** 2009/07/29 1.7 T.Tominaga DEL END   ******************************--
      )
/* 2009/07/13 Ver1.6 Add Start */
      --情報区分 = NULL OR 01
      AND (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
/* 2009/07/13 Ver1.6 Add End   */
/* 2011/04/20 Ver1.13 Add Start */
      --受注明細IDがNULL
      AND oola.global_attribute3 IS NULL
/* 2011/04/20 Ver1.13 Add End   */
      ORDER BY
/* 2009/12/28 Ver1.9 Mod Start */
--        ooha.header_id     --受注ヘッダ.ヘッダID
--        ,oola.line_id      --受注明細.明細ID
        xca.chain_store_code  --チェーン店コード
        ,xca.store_code       --店舗コード
        ,ooha.request_date    --納品日(ヘッダ)
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
        ,ooha.cust_po_number  --顧客発注番号
/* 2010/01/22 Ver1.9 Add End   E_本稼動_00408対応 */
        ,ooha.order_number    --受注番号
        ,oola.line_number     --受注明細番号
/* 2009/12/28 Ver1.9 Mod End   */
      FOR UPDATE OF
        ooha.header_id     --受注ヘッダ.ヘッダID
        ,oola.line_id      --受注明細.明細ID
      NOWAIT
      ;
--
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
    -- 受注ソースタイプ：その他（CSV/画面）の場合
    CURSOR data_edi_not_cur
    IS
      SELECT
/* 2010/03/29 Ver1.11 Add Start */
        /*+
           LEADING(xca)
           USE_NL(xca hca ooha oos jrs jrre papf1)
-- 2010/04/01 Ver1.12 Add Start
           INDEX(ooha oe_order_headers_n2)
-- 2010/04/01 Ver1.12 Add End
         */
/* 2010/03/29 Ver1.11 Add End   */
        oola.rowid                             AS row_id                     -- rowid
        ,ooha.order_source_id                  AS order_source_id            -- 受注ソース
        ,oos.name                              AS order_source               -- 受注ソース
        ,papf.employee_number                  AS entered_by_code            -- 入力者コード
        ,papf.per_information18 || ' ' || papf.per_information19
                                               AS entered_by_name            -- 入力者名
        ,hca.account_number                    AS deliver_from_code          -- 出荷先コード
        ,hp.party_name                         AS deliver_to_name            -- 顧客名称
        ,ooha.order_number                     AS order_number               -- 受注番号
        ,oola.line_number                      AS line_number                -- 明細番号
        ,ooha.cust_po_number                   AS party_order_number         -- 顧客発注番号
        ,oola.schedule_ship_date               AS shipped_date               -- 出荷日
        ,oola.request_date                     AS dlv_date                   -- 納品日
        ,oola.ordered_item                     AS order_item_no              -- 受注品番号
        ,ximb.item_short_name                  AS order_item_name            -- 受注品目名
        ,otta.order_category_code              AS order_category_code        -- カテゴリ
        ,oola.ordered_quantity                 AS quantity                   -- 数量
        ,oola.order_quantity_uom               AS uom_code                   -- 受注単位
        ,oola.unit_selling_price               AS dlv_unit_price             -- 販売単価
        ,oola.subinventory                     AS locat_code                 -- 保管場所コード
        ,msi.description                       AS locat_name                 -- 保管場所名称
        ,ooha.shipping_instructions            AS shipping_instructions      -- 出荷指示
        ,ooha.attribute19                      AS order_no                   -- オーダーNo.
        ,jrre.source_number                    AS base_employee_num          -- 営業担当コード
        ,papf1.per_information18 || ' ' || papf1.per_information19
                                               AS base_employee_name         -- 営業担当名
/* 2009/12/28 Ver1.9 Add Start */
        ,ooha.attribute5                       AS invoice_class              -- 伝票区分
        ,ooha.attribute20                      AS classification_class       -- 分類区分
        ,NULL                                  AS report_output_type         -- 出力区分
        ,NULL                                  AS edi_re_output_flag         -- EDI再出力フラグ
        ,NULL                                  AS chain_code                 -- チェーン店コード
        ,NULL                                  AS chain_name                 -- チェーン店名称
        ,NULL                                  AS order_creation_date_from   -- 受信日(FROM)(パラメータ)
        ,NULL                                  AS order_creation_date_to     -- 受信日(TO)(パラメータ)
        ,NULL                                  AS dlv_date_header_from       -- 納品日(FROM)(パラメータ)
        ,NULL                                  AS dlv_date_header_to         -- 納品日(TO)(パラメータ)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
        ,ooha.request_date                     AS dlv_date_header            --納品日(ヘッダ)
/* 2010/01/22 Ver1.9 Add End   E_本稼動_00408対応 */
      FROM
        oe_order_headers_all       ooha    -- 受注ヘッダ
        ,oe_order_lines_all        oola    -- 受注明細
        ,oe_order_sources          oos     -- 受注ソース
        ,hz_cust_accounts          hca     -- 顧客マスタ
        ,xxcmm_cust_accounts       xca     -- 顧客アドオン
        ,hz_parties                hp      -- パーティマスタ
        ,mtl_secondary_inventories msi     -- 保管場所マスタ
        ,mtl_system_items_b        msib    -- DISC品目
        ,ic_item_mst_b             iimb    -- OPM品目
        ,xxcmn_item_mst_b          ximb    -- OPM品目アドオン
        ,fnd_user                  fu      -- ユーザマスタ
        ,per_all_people_f          papf    -- 従業員マスタ
        ,per_person_types          ppt     -- 従業員タイプマスタ
        ,jtf_rs_resource_extns     jrre    -- リソースマスタ
        ,jtf_rs_salesreps          jrs     -- jtf_rs_salesreps
        ,per_all_people_f          papf1   -- 従業員マスタ1
        ,per_person_types          ppt1    -- 従業員タイプマスタ1
        ,oe_transaction_types_all  otta    -- 受注明細摘要用取引タイプALL
        ,oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
      WHERE
      -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
      ooha.header_id                        = oola.header_id
      -- 組織ID
      AND ooha.org_id                       = gn_org_id
      -- 受注ヘッダ.ソースID＝受注ソース.ソースID
      AND ooha.order_source_id              = oos.order_source_id
      -- 受注ソース名称（EDI受注、問屋CSV、国際CSV、Online）
      AND oos.name IN ( 
        SELECT  look_val.attribute1
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
        FROM    fnd_lookup_values           look_val
        WHERE   look_val.language           = cv_lang
        AND     look_val.lookup_type        = cv_type_ost_009_a01
        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND     look_val.enabled_flag       = ct_enabled_flg_y
        --受注ソース（EDI取込・CSV取込・クイック受注入力・出荷依頼実績）
        AND     look_val.description        = iv_order_source
--
--        FROM    fnd_lookup_values           look_val,
--                fnd_lookup_types_tl         types_tl,
--                fnd_lookup_types            types,
--                fnd_application_tl          appl,
--                fnd_application             app
--        WHERE   appl.application_id         = types.application_id
--        AND     app.application_id          = appl.application_id
--        AND     types_tl.lookup_type        = look_val.lookup_type
--        AND     types.lookup_type           = types_tl.lookup_type
--        AND     types.security_group_id     = types_tl.security_group_id
--        AND     types.view_application_id   = types_tl.view_application_id
--        AND     types_tl.language           = cv_lang
--        AND     look_val.language           = cv_lang
--        AND     appl.language               = cv_lang
--        AND     app.application_short_name  = cv_xxcos_short_name
--        AND     look_val.lookup_type        = cv_type_ost_009_a01
--        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--        AND     look_val.enabled_flag       = ct_enabled_flg_y
--        --受注ソース（EDI取込・CSV取込・クイック受注入力）
--        AND     look_val.description        = iv_order_source
-- ******** 2009/10/02 1.8 N.Maeda MOD END  ******** --
      )
/* 2010/04/01 Ver1.12 Add Start */
      AND ooha.orig_sys_document_ref     LIKE gt_orig_sys_st_value || cv_multi
/* 2010/04/01 Ver1.12 Add End   */
      --受注ヘッダ.顧客ID = 顧客マスタ.顧客ID
      AND ooha.sold_to_org_id               = hca.cust_account_id
      --顧客マスタ.顧客ID =顧客マスタアドオン.顧客ID
      AND hca.cust_account_id               = xca.customer_id
      --顧客マスタアドオン.納品拠点コード=パラメータ.拠点コード
      AND xca.delivery_base_code            = iv_delivery_base_code
      --顧客マスタ.パーティID = パーティマスタ.パーティID
      AND hca.party_id                      = hp.party_id 
      --ユーザマスタ.ユーザID=受注ヘッダ.最終更新者
      AND fu.user_id                        = ooha.last_updated_by
      --ユーザマスタ.従業員ID=従業員マスタ.従業員ID
      AND fu.employee_id                    = papf.person_id
      AND gd_proc_date                      >= NVL( papf.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf.effective_end_date, gd_max_date )
      AND ppt.business_group_id             = cn_per_business_group_id
      AND ppt.system_person_type            = cv_emp
      AND ppt.active_flag                   = ct_enabled_flg_y
      AND papf.person_type_id               = ppt.person_type_id
      --受注ヘッダ.営業担当ID=jtf_rs_salesreps.salesrep_id
      AND ooha.salesrep_id                  = jrs.salesrep_id
      --jtf_rs_salesreps.リソースID=リソースマスタ.リソースID
      AND jrs.resource_id                   = jrre.resource_id
      --リソースマスタ.ソース番号=従業員マスタ.従業員ID
      AND jrre.source_id                    = papf1.person_id
      AND gd_proc_date                      >= NVL( papf1.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf1.effective_end_date, gd_max_date )
      AND ppt1.business_group_id            = cn_per_business_group_id
      AND ppt1.system_person_type           = cv_emp
      AND ppt1.active_flag                  = ct_enabled_flg_y
      AND papf1.person_type_id              = ppt1.person_type_id
      -- 受注明細.保管場所=保管場所マスタ.保管場所コード
      AND oola.subinventory                 = msi.secondary_inventory_name(+)
      -- 受注明細.出荷元組織ID = 保管場所マスタ.組織ID
      AND oola.ship_from_org_id             = msi.organization_id(+)
      --受注明細.品目ID= 品目マスタ.品目ID
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND msib.organization_id              = gt_org_id
      AND msib.segment1                     = iimb.item_no
      AND iimb.item_id                      = ximb.item_id
      AND gd_proc_date                      >= NVL( ximb.start_date_active, gd_min_date )
      AND gd_proc_date                      <= NVL( ximb.end_date_active, gd_max_date )
      --受注明細.明細タイプ＝受注タイプ.タイプ
      AND oola.line_type_id                 = otttl.transaction_type_id
      --受注タイプ.タイプ＝受注タイプALL.タイプ
      AND otttl.transaction_type_id         = otta.transaction_type_id
      --言語：JA
      AND otttl.language                    = cv_lang
      AND ( 
        --その他（CSV/画面）の場合
        ( 
          iv_order_source <> gv_order_source_edi_chk 
          -- 受注明細.ステータス≠ｸﾛｰｽﾞor取消
          AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2010/03/29 Ver1.11 Add Start */
          -- 受注ヘッダ.ステータス≠ｸﾛｰｽﾞor取消
          AND ooha.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2010/03/29 Ver1.11 Add End   */
          AND (
            --受注ヘッダとパラメータの受注日両方NULLの場合 退避する
            ooha.ordered_date IS NULL
            AND ld_ordered_date_from IS NULL
            AND ld_ordered_date_to IS NULL
            OR (
              --受注ヘッダ.受注日≧パラメータ.受注日（FROM）
              TRUNC( ooha.ordered_date )           >= NVL( ld_ordered_date_from, TRUNC( ooha.ordered_date ) )
              --受注ヘッダ.受注日≦パラメータ.受注日（TO）
              AND TRUNC( ooha.ordered_date )       <= NVL( ld_ordered_date_to, TRUNC( ooha.ordered_date ) )
            )
          )
          AND (
            --受注明細とパラメータの予定出荷日両方NULLの場合 退避する
            oola.schedule_ship_date IS NULL
            AND ld_schedule_ship_date_from IS NULL
            AND ld_schedule_ship_date_to IS NULL
            OR (
              --受注明細.予定出荷日≧パラメータ.出荷予定日（FROM）
              TRUNC( oola.schedule_ship_date )     >= 
                  NVL( ld_schedule_ship_date_from, TRUNC( oola.schedule_ship_date ) )
              --受注明細.予定出荷日≦パラメータ.出荷予定日（TO）
              AND TRUNC( oola.schedule_ship_date ) <= NVL( ld_schedule_ship_date_to, TRUNC( oola.schedule_ship_date ) )
            )
          )
          AND (
            --受注明細とパラメータの要求日両方NULLの場合 退避する
            oola.request_date IS NULL
            AND ld_schedule_ordered_date_from IS NULL
            AND ld_schedule_ordered_date_to IS NULL
            OR (
              --受注明細.要求日≧パラメータ.納品予定日（FROM）
              TRUNC( oola.request_date )           >= NVL( ld_schedule_ordered_date_from, TRUNC( oola.request_date ) )
              --受注明細.要求日≦パラメータ.納品予定日（TO）
              AND TRUNC( oola.request_date )       <= NVL( ld_schedule_ordered_date_to, TRUNC( oola.request_date ) )
            )
          )
          --従業員マスタ.従業員番号＝パラメータ.入力者
/* 2009/12/28 Ver1.9 Mod Start */
--          AND papf.employee_number             = NVL( iv_entered_by_code, papf.employee_number )
          AND (
            iv_entered_by_code IS NULL
            OR iv_entered_by_code = papf.employee_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
          --顧客マスタ.顧客コード＝パラメータ.出荷先
/* 2009/12/28 Ver1.9 Mod Start */
--          AND hca.account_number               = NVL( iv_ship_to_code, hca.account_number )
          AND (
            iv_ship_to_code IS NULL
            OR iv_ship_to_code = hca.account_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
          AND (
            --受注明細とパラメータの保管場所両方NULLの場合 退避する
            oola.subinventory IS NULL
            AND iv_subinventory IS NULL
            OR (
              --受注明細.保管場所＝パラメータ.保管場所
              oola.subinventory                = NVL( iv_subinventory, oola.subinventory )
            )
          )
          --受注ヘッダ.受注番号=パラメータ.受注番号
/* 2009/12/28 Ver1.9 Mod Start */
--          AND ooha.order_number                = NVL( iv_order_number, ooha.order_number )
          AND ( 
            iv_order_number IS NULL
            OR iv_order_number = ooha.order_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
/* 2010/04/01 Ver1.12 Add Start */
          --受注明細.ステータス=パラメータ.ステータス
          AND (
             iv_order_status IS NULL
            OR oola.flow_status_code = iv_order_status
          )
/* 2010/04/01 Ver1.12 Add End   */
        )
      )
      --情報区分 = NULL OR 01
      AND (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
      ORDER BY
/* 2009/12/28 Ver1.9 Mod Start */
--        ooha.header_id     --受注ヘッダ.ヘッダID
--        ,oola.line_id      --受注明細.明細ID
        DECODE(  iv_order_source
               , gv_order_source_clik_chk, papf.employee_number  --クイック受注
/* 2010/04/01 Ver1.12 Add Start */
               , gv_order_source_ship_chk, papf.employee_number  --出荷実績依頼
/* 2010/04/01 Ver1.12 Add End   */
               , NULL                                            --CSV
        )                     --入力者
        ,hca.account_number   --出荷先
/* 2010/04/01 Ver1.12 Mod Start */
--/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
--        ,ooha.cust_po_number         --顧客発注番号
--        ,TRUNC(oola.request_date)    --納品日
--/* 2010/01/22 Ver1.9 Add End   E_本稼動_00408対応 */
        ,TRUNC(oola.request_date)    --納品日
        ,ooha.cust_po_number         --顧客発注番号
/* 2010/04/01 Ver1.12 Mod End   */
        ,ooha.order_number    --受注番号
        ,oola.line_number     --受注明細番号
/* 2009/12/28 Ver1.9 Mod End   */
      ;
--****************************** 2009/07/29 1.7 T.Tominaga ADD END   ******************************--
--
    -- *** ローカル・レコード ***
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    l_data_edi_or_not_rec                data_edi_or_not_cur%ROWTYPE;
    l_data_edi_or_not_rec                data_edi_cur%ROWTYPE;
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
    ln_denpyokei_order_amount     NUMBER;
    ln_rowid_idx                  NUMBER;
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --ループカウント初期化
    ln_idx          := 0;
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
    ln_rowid_idx    := 0;
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
--
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    FOR l_data_edi_or_not_rec IN data_edi_or_not_cur LOOP
    -- EDI取込
    IF iv_order_source = gv_order_source_edi_chk THEN
      OPEN data_edi_cur;
    -- その他（CSV/画面）
    ELSE
      OPEN data_edi_not_cur;
    END IF;
--
    <<loop_get_data>>
    LOOP
--
      --
      --対象データ取得
      IF iv_order_source = gv_order_source_edi_chk THEN
        FETCH data_edi_cur INTO l_data_edi_or_not_rec;
        EXIT WHEN data_edi_cur%NOTFOUND;
      -- その他（CSV/画面）
      ELSE
        FETCH data_edi_not_cur INTO l_data_edi_or_not_rec;
        EXIT WHEN data_edi_not_cur%NOTFOUND;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
      -- 伝票計レコード作成
      IF ( ln_idx > 0 ) THEN
          -- 伝票計集計キーが変わった時、伝票計レコードの挿入
          IF
             -- EDI出力
             ( ( iv_order_source = gv_order_source_edi_chk )
               AND
               (  ( NVL( l_data_edi_or_not_rec.deliver_from_code  ,' ') <> NVL( g_report_data_tab(ln_idx).deliver_from_code  ,' ') )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date_header ,cv_yyyymmdd ) ,' ')
                                             <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date_header ,cv_yyyymmdd ) ,' ') )
               OR ( NVL( l_data_edi_or_not_rec.party_order_number ,' ') <> NVL( g_report_data_tab(ln_idx).party_order_number ,' ') )
               )
             )
             OR
/* 2010/04/01 Ver1.12 Mod Start */
--             -- その他（画面）出力
--             ( ( iv_order_source = gv_order_source_clik_chk )
             -- その他（画面・出荷実績依頼）出力
             ( ( iv_order_source IN ( gv_order_source_clik_chk , gv_order_source_ship_chk ) )
/* 2010/04/01 Ver1.12 Mod End   */
               AND
               (  ( SUBSTRB( l_data_edi_or_not_rec.entered_by_code, 1, 5 )
                                                             <> g_report_data_tab(ln_idx).entered_by_code    )
               OR ( l_data_edi_or_not_rec.deliver_from_code  <> g_report_data_tab(ln_idx).deliver_from_code  )
               OR ( l_data_edi_or_not_rec.party_order_number <> g_report_data_tab(ln_idx).party_order_number )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date ,cv_yyyymmdd ) ,' ')
                                                    <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date ,cv_yyyymmdd ) ,' ') )
               )
             )
             OR
             -- その他（CSV）出力
/* 2010/04/01 Ver1.12 Mod Start */
--             ( ( iv_order_source NOT IN ( gv_order_source_edi_chk ,gv_order_source_clik_chk ) )
             ( ( iv_order_source NOT IN ( gv_order_source_edi_chk ,gv_order_source_clik_chk, gv_order_source_ship_chk ) )
/* 2010/04/01 Ver1.12 Mod End   */
               AND
               (  ( l_data_edi_or_not_rec.deliver_from_code  <> g_report_data_tab(ln_idx).deliver_from_code  )
               OR ( l_data_edi_or_not_rec.party_order_number <> g_report_data_tab(ln_idx).party_order_number )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date ,cv_yyyymmdd ) ,' ')
                                                    <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date ,cv_yyyymmdd ) ,' ') )
               )
             )
          THEN
            -- レコードIDの取得
            SELECT xxcos_rep_order_list_s01.NEXTVAL redord_id
            INTO   lt_record_id
            FROM   dual
            ;
            ln_idx := ln_idx + 1;
--
            -- SVFにてグループサプレス処理を行っており、
            -- サプレス対象項目に同一値を格納必要がある為、
            -- 前レコードを伝票計レコードに格納する。
            g_report_data_tab(ln_idx) := g_report_data_tab(ln_idx - 1);
--
            -- 伝票計専用項目の設定
            g_report_data_tab(ln_idx).record_id          := lt_record_id;                                         --レコードID
            g_report_data_tab(ln_idx).record_type        := cn_record_type_denpyokei;                             --レコードタイプ：伝票計
            g_report_data_tab(ln_idx).order_amount_total := ln_denpyokei_order_amount;                            --受注金額合計（伝票計）
--
            -- 伝票計金額を初期化
            ln_denpyokei_order_amount := 0;
          END IF;
      ELSE
          -- 伝票計金額を初期化
          ln_denpyokei_order_amount := 0;
      END IF;
--
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
--
      -- レコードIDの取得
      BEGIN
        SELECT xxcos_rep_order_list_s01.NEXTVAL     redord_id
        INTO   lt_record_id
        FROM   dual;
      END;
      --
      ln_idx := ln_idx + 1;
/* 2010/01/22 Ver1.9 Mod End E_本稼動_00408対応 */
      ln_rowid_idx := ln_rowid_idx + 1;
      --
      --受注明細を更新するため、ROWIDを退避する。
--      gt_oola_rowid_tab(ln_idx)                        := l_data_edi_or_not_rec.row_id;                --ROWID
      gt_oola_rowid_tab(ln_rowid_idx)                  := l_data_edi_or_not_rec.row_id;                --ROWID
/* 2010/01/22 Ver1.9 Mod End E_本稼動_00408対応 */
      --
      g_report_data_tab(ln_idx).record_id              := lt_record_id;                                --レコードID
      g_report_data_tab(ln_idx).order_source           := iv_order_source;                             --受注ソース
/* 2010/04/01 Ver1.12 Mod Start */
--      IF ( iv_order_source = gv_order_source_clik_chk ) THEN    --受注ソース：クイック受注入力の場合
      IF (   iv_order_source = gv_order_source_clik_chk
          OR iv_order_source = gv_order_source_ship_chk ) THEN    --受注ソース：クイック受注入力・出荷実績依頼の場合
/* 2010/04/01 Ver1.12 Mod End   */
        g_report_data_tab(ln_idx).entered_by_code      := SUBSTRB( l_data_edi_or_not_rec.entered_by_code, 1, 5 );
                                                                                                       --入力者コード
        g_report_data_tab(ln_idx).entered_by_name      := SUBSTRB( l_data_edi_or_not_rec.entered_by_name, 1, 40 );
                                                                                                       --入力者名
      ELSE
        g_report_data_tab(ln_idx).entered_by_code      := NULL;                                        --入力者コード
        g_report_data_tab(ln_idx).entered_by_name      := NULL;                                        --入力者名
      END IF;
      g_report_data_tab(ln_idx).order_number           := l_data_edi_or_not_rec.order_number;          --受注番号
      g_report_data_tab(ln_idx).party_order_number     := SUBSTRB( l_data_edi_or_not_rec.party_order_number, 1, 12 );
                                                                                                       --顧客発注番号
      g_report_data_tab(ln_idx).line_number            := l_data_edi_or_not_rec.line_number;           --明細番号
      g_report_data_tab(ln_idx).order_no               := SUBSTRB( l_data_edi_or_not_rec.order_no, 1, 16 );
                                                                                                       --オーダーNo.
      g_report_data_tab(ln_idx).shipped_date           := l_data_edi_or_not_rec.shipped_date;          --出荷日
      g_report_data_tab(ln_idx).dlv_date               := l_data_edi_or_not_rec.dlv_date;              --納品日
      g_report_data_tab(ln_idx).order_item_no          := SUBSTRB( l_data_edi_or_not_rec.order_item_no, 1, 7 );
                                                                                                       --受注品番号
      g_report_data_tab(ln_idx).order_item_name        := SUBSTRB( l_data_edi_or_not_rec.order_item_name, 1, 20 );
                                                                                                       --受注品名
      IF ( l_data_edi_or_not_rec.order_category_code = cv_return ) THEN 
        g_report_data_tab(ln_idx).quantity             := l_data_edi_or_not_rec.quantity * ( -1 );     --数量
      ELSE
        g_report_data_tab(ln_idx).quantity             := l_data_edi_or_not_rec.quantity;              --数量
      END IF;
      g_report_data_tab(ln_idx).uom_code               := l_data_edi_or_not_rec.uom_code;              --単位
      g_report_data_tab(ln_idx).dlv_unit_price         := l_data_edi_or_not_rec.dlv_unit_price;        --納品単価
/* 2009/12/28 Ver1.9 Mod Start */
--      g_report_data_tab(ln_idx).order_amount           := ROUND( g_report_data_tab(ln_idx).quantity * 
      g_report_data_tab(ln_idx).order_amount           := TRUNC( g_report_data_tab(ln_idx).quantity * 
/* 2009/12/28 Ver1.9 Mod End   */
                                                          l_data_edi_or_not_rec.dlv_unit_price );      --受注金額
      g_report_data_tab(ln_idx).locat_code             := l_data_edi_or_not_rec.locat_code;            --保管場所コード
      g_report_data_tab(ln_idx).locat_name             := SUBSTRB( l_data_edi_or_not_rec.locat_name, 1, 10 );
                                                                                                       --保管場所名称
      g_report_data_tab(ln_idx).shipping_instructions  := SUBSTRB( l_data_edi_or_not_rec.shipping_instructions, 1, 26 );                                                                                                       --出荷指示
      g_report_data_tab(ln_idx).base_employee_num      := SUBSTRB( l_data_edi_or_not_rec.base_employee_num, 1, 5 );
                                                                                                       --担当営業コード
      g_report_data_tab(ln_idx).base_employee_name     := SUBSTRB( l_data_edi_or_not_rec.base_employee_name, 1, 12 );
                                                                                                       --担当営業名称
      g_report_data_tab(ln_idx).deliver_from_code      := SUBSTRB( l_data_edi_or_not_rec.deliver_from_code, 1, 9 );
                                                                                                       --出荷先コード
      g_report_data_tab(ln_idx).deliver_to_name        := SUBSTRB( l_data_edi_or_not_rec.deliver_to_name, 1, 38 );
                                                                                                       --出荷先名称
/* 2009/12/28 Ver1.9 Add Start */
      g_report_data_tab(ln_idx).invoice_class          := l_data_edi_or_not_rec.invoice_class;         --伝票区分
      g_report_data_tab(ln_idx).classification_class   := l_data_edi_or_not_rec.classification_class;  --分類区分
      g_report_data_tab(ln_idx).report_output_type     := l_data_edi_or_not_rec.report_output_type;    --出力区分
      g_report_data_tab(ln_idx).edi_re_output_flag     := l_data_edi_or_not_rec.edi_re_output_flag;    --EDI再出力フラグ
      g_report_data_tab(ln_idx).chain_code             := l_data_edi_or_not_rec.chain_code;            --チェーン店コード
      g_report_data_tab(ln_idx).chain_name             := l_data_edi_or_not_rec.chain_name;            --チェーン店名称
      g_report_data_tab(ln_idx).order_creation_date_from := l_data_edi_or_not_rec.order_creation_date_from; --受信日(FROM)
      g_report_data_tab(ln_idx).order_creation_date_to := l_data_edi_or_not_rec.order_creation_date_to;     --受信日(TO)
      g_report_data_tab(ln_idx).dlv_date_header_from   := l_data_edi_or_not_rec.dlv_date_header_from;       --納品日(FROM)
      g_report_data_tab(ln_idx).dlv_date_header_to     := l_data_edi_or_not_rec.dlv_date_header_to;         --納品日(TO)
/* 2009/12/28 Ver1.9 Add End   */
      g_report_data_tab(ln_idx).created_by             := cn_created_by;                               --作成者
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;                            --作成日
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;                          --最終更新者
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;                         --最終更新日
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;                        --最終更新ﾛｸﾞｲﾝ
      g_report_data_tab(ln_idx).request_id             := cn_request_id;                               --要求ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;                   
                                                                                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;                               
                                                                                          --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;                      --ﾌﾟﾛｸﾞﾗﾑ更新日
      --
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
      g_report_data_tab(ln_idx).record_type            := cn_record_type_detail;                       --レコードタイプ：明細行
      g_report_data_tab(ln_idx).order_amount_total     := NULL;                                        --受注金額合計（伝票計）
      g_report_data_tab(ln_idx).dlv_date_header        := l_data_edi_or_not_rec.dlv_date_header;       --納品日(ヘッダ)
      -- 伝票計金額を加算
      ln_denpyokei_order_amount := ln_denpyokei_order_amount + g_report_data_tab(ln_idx).order_amount;
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
--
    END LOOP loop_get_data;
--
/* 2010/01/22 Ver1.9 Add Start E_本稼動_00408対応 */
    IF ( ln_idx > 0 ) THEN
      -- レコードIDの取得
      SELECT xxcos_rep_order_list_s01.NEXTVAL redord_id
      INTO   lt_record_id
      FROM   dual
      ;
      ln_idx := ln_idx + 1;
  
      -- SVFにてグループサプレス処理を行っており、
      -- サプレス対象項目に同一値を格納必要がある為、
      -- 前レコードを伝票計レコードに格納する。
      g_report_data_tab(ln_idx) := g_report_data_tab(ln_idx - 1);
  
      -- 伝票計専用項目の設定
      g_report_data_tab(ln_idx).record_id         := lt_record_id;                                         --レコードID
      g_report_data_tab(ln_idx).record_type       := cn_record_type_denpyokei;                             --レコードタイプ：伝票計
      g_report_data_tab(ln_idx).order_amount_total := ln_denpyokei_order_amount;                            --受注金額合計（伝票計）
    END IF;
/* 2010/01/22 Ver1.9 Add End E_本稼動_00408対応 */
--
    --処理件数カウント
    gn_target_cnt := g_report_data_tab.COUNT;
--
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
    -- EDI取込
    IF iv_order_source = gv_order_source_edi_chk THEN
      CLOSE data_edi_cur;
    -- その他（CSV/画面）
    ELSE
      CLOSE data_edi_not_cur;
    END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
--
  EXCEPTION
--
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      -- EDI取込
      IF iv_order_source = gv_order_source_edi_chk THEN
        IF ( data_edi_cur%ISOPEN ) THEN
          CLOSE data_edi_cur;
        END IF;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD END   ******************************--
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name2
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      -- EDI取込
      IF iv_order_source = gv_order_source_edi_chk THEN
        IF ( data_edi_cur%ISOPEN ) THEN
          CLOSE data_edi_cur;
        END IF;
      -- その他（CSV/画面）
      ELSE
        IF ( data_edi_not_cur%ISOPEN ) THEN
          CLOSE data_edi_not_cur;
        END IF;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : 帳票ワークテーブル登録(A-4)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- プログラム名
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --対象テーブル名
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
    --帳票ワークテーブル登録処理
    BEGIN
      FORALL ln_cnt IN g_report_data_tab.FIRST .. g_report_data_tab.LAST
        INSERT INTO  xxcos_rep_order_list
        VALUES       g_report_data_tab(ln_cnt);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
    --正常件数取得
    gn_normal_cnt := g_report_data_tab.COUNT;
--
  EXCEPTION
    --*** 処理対象データ登録例外 ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line_data
   * Description      : 受注明細出力済み更新（EDI取込のみ）(A-5)
   ***********************************************************************************/
  PROCEDURE update_order_line_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line_data'; -- プログラム名
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --対象テーブル名
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
    --受注明細テーブル更新処理
    BEGIN
      FORALL ln_cnt IN gt_oola_rowid_tab.FIRST .. gt_oola_rowid_tab.LAST
        UPDATE 
          oe_order_lines_all      oola
        SET
          oola.global_attribute1      = TO_CHAR( SYSDATE, cv_yyyymmddhhmiss ), -- 受注一覧出力日→システム日付
          oola.last_updated_by        = cn_last_updated_by,                    -- 最終更新者
          oola.last_update_date       = cd_last_update_date,                   -- 最終更新日
          oola.last_update_login      = cn_last_update_login,                  -- 最終更新ログイン
          oola.request_id             = cn_request_id,                         -- 要求ID
          oola.program_application_id = cn_program_application_id,             -- コンカレント・プログラム・アプリID
          oola.program_id             = cn_program_id,                         -- コンカレント・プログラムID
          oola.program_update_date    = cd_program_update_date                 -- プログラム更新日
        WHERE
          oola.rowid                  = gt_oola_rowid_tab( ln_cnt );           -- 受注明細ROWID
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_update_expt;
    END;
--
  EXCEPTION
    --*** 処理対象データ更新例外 ***
    WHEN global_data_update_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name3
      );
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
  END update_order_line_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF起動(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
-- ********* 2009/10/02 N.Maeda 1.8 ADD START ********* --
    PRAGMA AUTONOMOUS_TRANSACTION; -- 独立トランザクション
-- ********* 2009/10/02 N.Maeda 1.8 ADD  END  ********* --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg       VARCHAR2(5000);   --明細0件用メッセージ
    lv_file_name        VARCHAR2(100);    --出力ファイル名
    lv_tkn_vl_api_name  VARCHAR2(100);    --API名
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --明細0件用メッセージ取得
    lv_nodata_msg           :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_no_data_err
    );
--
    --出力ファイル名編集
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF起動
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              =>  lv_retcode,
      ov_errbuf               =>  lv_errbuf,
      ov_errmsg               =>  lv_errmsg,
      iv_conc_name            =>  cv_conc_name,
      iv_file_name            =>  lv_file_name,
      iv_file_id              =>  cv_report_id,
      iv_output_mode          =>  cv_output_mode,
      iv_frm_file             =>  cv_frm_file,
      iv_vrq_file             =>  cv_vrq_file,
      iv_org_id               =>  NULL,
      iv_user_name            =>  NULL,
      iv_resp_name            =>  NULL,
      iv_doc_name             =>  NULL,
      iv_printer_name         =>  NULL,
      iv_request_id           =>  TO_CHAR( cn_request_id ),
      iv_nodata_msg           =>  lv_nodata_msg,
      iv_svf_param1           =>  NULL,
      iv_svf_param2           =>  NULL,
      iv_svf_param3           =>  NULL,
      iv_svf_param4           =>  NULL,
      iv_svf_param5           =>  NULL,
      iv_svf_param6           =>  NULL,
      iv_svf_param7           =>  NULL,
      iv_svf_param8           =>  NULL,
      iv_svf_param9           =>  NULL,
      iv_svf_param10          =>  NULL,
      iv_svf_param11          =>  NULL,
      iv_svf_param12          =>  NULL,
      iv_svf_param13          =>  NULL,
      iv_svf_param14          =>  NULL,
      iv_svf_param15          =>  NULL
    );
    --SVF起動失敗
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF起動例外 ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name      :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_api_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_api_err,
        iv_token_name1        =>  cv_tkn_nm_api_name,
        iv_token_value1       =>  lv_tkn_vl_api_name
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info               VARCHAR2(5000);     --キー情報
    lv_tkn_vl_key_request_id  VARCHAR2(100);      --要求IDの文言
    lv_tkn_vl_table_name      VARCHAR2(100);      --対象テーブル名
--
    -- *** ローカル・カーソル ***
    CURSOR lock_cur
    IS
      SELECT xrol.record_id rec_id
      FROM   xxcos_rep_order_list xrol           --受注一覧リスト帳票ワークテーブル
      WHERE  xrol.request_id = cn_request_id     --要求ID
      FOR UPDATE NOWAIT
      ;
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
    --対象データロック
    BEGIN
      -- ロック用カーソルオープン
      OPEN lock_cur;
      -- ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      --対象データロック例外
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --対象データ削除
    BEGIN
      DELETE FROM 
        xxcos_rep_order_list xrol               --受注一覧リスト帳票ワークテーブル
      WHERE xrol.request_id = cn_request_id     --要求ID
      ;
    EXCEPTION
      --対象データ削除失敗
      WHEN OTHERS THEN
        lv_tkn_vl_key_request_id  :=  xxccp_common_pkg.get_msg(
          iv_application          =>  cv_xxcos_short_name,
          iv_name                 =>  cv_msg_vl_key_request_id
        );
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1         =>  lv_tkn_vl_key_request_id,   --要求IDの文言
          iv_data_value1        =>  TO_CHAR( cn_request_id ),   --要求ID
          ov_key_info           =>  lv_key_info,                --編集されたキー情報
          ov_errbuf             =>  lv_errbuf,                  --エラーメッセージ
          ov_retcode            =>  lv_retcode,                 --リターンコード
          ov_errmsg             =>  lv_errmsg                   --ユーザ・エラー・メッセージ
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          RAISE global_data_delete_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
--
  EXCEPTION
    -- *** 処理対象データロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      -- カーソルオープン時、クローズへ
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 処理対象データ削除例外ハンドラ ***
    WHEN global_data_delete_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_delete_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  lv_key_info
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source                 IN     VARCHAR2,         --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,         --   納品拠点コード
    iv_ordered_date_from            IN     VARCHAR2,         --   受注日(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   受注日(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   出荷予定日(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   出荷予定日(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   納品予定日(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   納品予定日(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   入力者コード
    iv_ship_to_code                 IN     VARCHAR2,         --   出荷先コード
    iv_subinventory                 IN     VARCHAR2,         --   保管場所
    iv_order_number                 IN     VARCHAR2,         --   受注番号
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,         --   出力区分
    iv_chain_code                   IN     VARCHAR2,         --   チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,         --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   納品日(ヘッダ)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   納品日(ヘッダ)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,         --   受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,         --   出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    ld_ordered_date_from             DATE;   -- 受注日(FROM)_チェックOK
    ld_ordered_date_to               DATE;   -- 受注日(TO)_チェックOK
    ld_schedule_ship_date_from       DATE;   -- 出荷予定日(FROM)_チェックOK
    ld_schedule_ship_date_to         DATE;   -- 出荷予定日(TO)_チェックOK
    ld_schedule_ordered_date_from    DATE;   -- 納品予定日(FROM)_チェックOK
    ld_schedule_ordered_date_to      DATE;   -- 納品予定日(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add Start */
    ld_order_creation_date_from      DATE;   -- 受信日(FROM)_チェックOK
    ld_order_creation_date_to        DATE;   -- 受信日(TO)_チェックOK
    ld_ordered_date_h_from           DATE;   -- 納品日(ヘッダ)(FROM)_チェックOK
    ld_ordered_date_h_to             DATE;   -- 納品日(ヘッダ)(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add End   */
--2009/06/19  Ver1.5 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
--2009/06/19  Ver1.5 T1_1437  Add end
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    lv_update_errbuf                  VARCHAR2(5000);
    lv_update_retcode                 VARCHAR2(1);
    lv_update_errmsg                  VARCHAR2(5000);
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
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
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
      iv_order_source,              -- 受注ソース
      iv_delivery_base_code,        -- 納品拠点コード
      iv_ordered_date_from,         -- 受注日(FROM)
      iv_ordered_date_to,           -- 受注日(TO)
      iv_schedule_ship_date_from,   -- 出荷予定日(FROM)
      iv_schedule_ship_date_to,     -- 出荷予定日(TO)
      iv_schedule_ordered_date_from,-- 納品予定日(FROM)
      iv_schedule_ordered_date_to,  -- 納品予定日(TO)
      iv_entered_by_code,           -- 入力者コード
      iv_ship_to_code,              -- 出荷先コード
      iv_subinventory,              -- 保管場所
      iv_order_number,              -- 受注番号
/* 2009/12/28 Ver1.9 Add Start */
      iv_output_type,               -- 出力区分
      iv_chain_code,                -- チェーン店コード
      iv_order_creation_date_from,  -- 受信日(FROM)
      iv_order_creation_date_to,    -- 受信日(TO)
      iv_ordered_date_h_from,       -- 納品日(ヘッダ)(FROM)
      iv_ordered_date_h_to,         -- 納品日(ヘッダ)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
      iv_order_status,              -- 受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      iv_output_quantity_type,      -- 出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  パラメータチェック
    -- ===============================
    check_parameter(
      iv_ordered_date_from,         -- 受注日(FROM)
      iv_ordered_date_to,           -- 受注日(TO)
      iv_schedule_ship_date_from,   -- 出荷予定日(FROM)
      iv_schedule_ship_date_to,     -- 出荷予定日(TO)
      iv_schedule_ordered_date_from,-- 納品予定日(FROM)
      iv_schedule_ordered_date_to,  -- 納品予定日(TO)
/* 2009/12/28 Ver1.9 Add Start */
      iv_order_creation_date_from,  -- 受信日(FROM)
      iv_order_creation_date_to,    -- 受信日(TO)
      iv_ordered_date_h_from,       -- 納品日(ヘッダ)(FROM)
      iv_ordered_date_h_to,         -- 納品日(ヘッダ)(TO)
      iv_order_source,              -- 受注ソース
      iv_output_type,               -- 出力区分
/* 2009/12/28 Ver1.9 Add End   */
      ld_ordered_date_from,         -- 受注日(FROM)_チェックOK
      ld_ordered_date_to,           -- 受注日(TO)_チェックOK
      ld_schedule_ship_date_from,   -- 出荷予定日(FROM)_チェックOK
      ld_schedule_ship_date_to,     -- 出荷予定日(TO)_チェックOK
      ld_schedule_ordered_date_from,-- 納品予定日(FROM)_チェックOK
      ld_schedule_ordered_date_to,  -- 納品予定日(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add Start */
      ld_order_creation_date_from,  -- 受信日(FROM)_チェックOK
      ld_order_creation_date_to,    -- 受信日(TO)_チェックOK
      ld_ordered_date_h_from,       -- 納品日(ヘッダ)(FROM)_チェックOK
      ld_ordered_date_h_to,         -- 納品日(ヘッダ)(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add End   */
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  対象データ取得
    -- ===============================
    get_data(
      iv_order_source,              -- 受注ソース
      iv_delivery_base_code,        -- 納品拠点コード
      ld_ordered_date_from,         -- 受注日(FROM)_チェックOK
      ld_ordered_date_to,           -- 受注日(TO)_チェックOK
      ld_schedule_ship_date_from,   -- 出荷予定日(FROM)_チェックOK
      ld_schedule_ship_date_to,     -- 出荷予定日(TO)_チェックOK
      ld_schedule_ordered_date_from,-- 納品予定日(FROM)_チェックOK
      ld_schedule_ordered_date_to,  -- 納品予定日(TO)_チェックOK
      iv_entered_by_code,           -- 入力者コード
      iv_ship_to_code,              -- 出荷先コード
      iv_subinventory,              -- 保管場所
      iv_order_number,              -- 受注番号
/* 2009/12/28 Ver1.9 Add Start */
      iv_output_type,               -- 出力区分
      iv_chain_code,                -- チェーン店コード
      ld_order_creation_date_from,  -- 受信日(FROM)_チェックOK
      ld_order_creation_date_to,    -- 受信日(TO)_チェックOK
      ld_ordered_date_h_from,       -- 納品日(ヘッダ)(FROM)_チェックOK
      ld_ordered_date_h_to,         -- 納品日(ヘッダ)(TO)_チェックOK
/* 2009/12/28 Ver1.9 Add To    */
/* 2010/04/01 Ver1.12 Add Start */
      iv_order_status,              -- 受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      iv_output_quantity_type,      -- 出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  帳票ワークテーブル登録
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    COMMIT;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
--
    -- ===============================
    -- A-5  受注明細出力済み更新（EDI取込新規のみ）
    -- ===============================
/* 2009/12/28 Ver1.9 Mod Start */
--    IF ( iv_order_source = gv_order_source_edi_chk ) THEN 
    IF ( iv_order_source = gv_order_source_edi_chk ) 
      AND ( iv_output_type = gt_report_output_type_n ) THEN
/* 2009/12/28 Ver1.9 Mod End   */
      update_order_line_data(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
-- ************ 2009/10/02 1.8 N.Maeda DEL START ************--
--      IF ( lv_retcode = cv_status_normal ) THEN
--        NULL;
--      ELSE
--        --帳票ワークテーブルに登録された件数をクリア
--        gn_normal_cnt := 0;
--        RAISE global_process_expt;
--      END IF;
-- ************ 2009/10/02 1.8 N.Maeda DEL  END  ************--
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
      lv_update_errbuf  := lv_errbuf;
      lv_update_retcode := lv_retcode;
      lv_update_errmsg  := lv_errmsg;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
--
-- ************ 2009/10/02 1.8 N.Maeda DEL START ************--
--    --コメット処理（以上の処理が正常の場合）
--    COMMIT;
-- ************ 2009/10/02 1.8 N.Maeda DEL  END  ************--
--
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_update_retcode = cv_status_normal ) THEN
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
      -- ===============================
      -- A-6  SVF起動
      -- ===============================
      execute_svf(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
-- 2009/06/19  Ver1.5 T1_1437  Mod start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
      --
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_retcode <> cv_status_normal ) THEN
      ROLLBACK;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
      --エラーでもワークテーブルを削除する為、エラー情報を保持
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
-- 2009/06/19  Ver1.5 T1_1437  Mod End
--
    -- ===============================
    -- A-7  帳票ワークテーブル削除
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/19  Ver1.5 T1_1437  Add start
    --エラーの場合、ロールバックするのでここでコミット
    COMMIT;
--
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_update_retcode = cv_status_error ) THEN
      lv_errbuf   := lv_update_errbuf;
      lv_retcode  := lv_update_retcode;
      lv_errmsg   := lv_update_errmsg;
      RAISE global_process_expt;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
-- 2009/06/19  Ver1.5 T1_1437  Add End
--
    --明細0件時ステータス制御処理
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
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
    errbuf                          OUT    VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,         --   リターン・コード    --# 固定 #
    iv_order_source                 IN     VARCHAR2,         --   受注ソース
    iv_delivery_base_code           IN     VARCHAR2,         --   納品拠点コード
    iv_ordered_date_from            IN     VARCHAR2,         --   受注日(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   受注日(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   出荷予定日(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   出荷予定日(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   納品予定日(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   納品予定日(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   入力者コード
    iv_ship_to_code                 IN     VARCHAR2,         --   出荷先コード
    iv_subinventory                 IN     VARCHAR2,         --   保管場所
/* 2009/12/28 Ver1.9 Mod Start */
--    iv_order_number                 IN     VARCHAR2          --   受注番号
    iv_order_number                 IN     VARCHAR2,         --   受注番号
    iv_output_type                  IN     VARCHAR2,         --   出力区分
    iv_chain_code                   IN     VARCHAR2,         --   チェーン店コード
    iv_order_creation_date_from     IN     VARCHAR2,         --   受信日(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   受信日(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   納品日(ヘッダ)(FROM)
/* 2010/04/01 Ver1.12 Mod Start */
--    iv_ordered_date_h_to            IN     VARCHAR2          --   納品日(ヘッダ)(TO)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   納品日(ヘッダ)(TO)
/* 2012/01/30 Ver1.14 Mod Start */
--    iv_order_status                 IN     VARCHAR2          --   受注ステータス
    iv_order_status                 IN     VARCHAR2,         --   受注ステータス
    iv_output_quantity_type         IN     VARCHAR2          --   出力数量区分
/* 2012/01/30 Ver1.14 Mod End   */
/* 2010/04/01 Ver1.12 Mod End   */
/* 2009/12/28 Ver1.9 Mod End   */
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
       iv_which   => cv_log_header_log
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
       iv_order_source                 -- 受注ソース
      ,iv_delivery_base_code           -- 納品拠点コード
      ,iv_ordered_date_from            -- 受注日(FROM)
      ,iv_ordered_date_to              -- 受注日(TO)
      ,iv_schedule_ship_date_from      -- 出荷予定日(FROM)
      ,iv_schedule_ship_date_to        -- 出荷予定日(TO)
      ,iv_schedule_ordered_date_from   -- 納品予定日(FROM)
      ,iv_schedule_ordered_date_to     -- 納品予定日(TO)
      ,iv_entered_by_code              -- 入力者コード
      ,iv_ship_to_code                 -- 出荷先コード
      ,iv_subinventory                 -- 保管場所
      ,iv_order_number                 -- 受注番号
/* 2009/12/28 Ver1.9 Add Start */
      ,iv_output_type                  -- 出力区分
      ,iv_chain_code                   -- チェーン店コード
      ,iv_order_creation_date_from     -- 受信日(FROM)
      ,iv_order_creation_date_to       -- 受信日(TO)
      ,iv_ordered_date_h_from          -- 納品日(ヘッダ)(FROM)
      ,iv_ordered_date_h_to            -- 納品日(ヘッダ)(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
      ,iv_order_status                 -- 受注ステータス
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      ,iv_output_quantity_type         -- 出力数量区分
/* 2012/01/30 Ver1.14 Add End   */
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCOS009A01R;
/
