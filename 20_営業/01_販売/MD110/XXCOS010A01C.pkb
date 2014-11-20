CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A01C (body)
 * Description      : 受注データ取込機能
 * MD.050           : 受注データ取込(MD050_COS_010_A01)
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_param_check       入力パラメータ妥当性チェック(A-1)
 *  proc_init              初期処理(A-2)
 *  proc_get_edi_work      EDI受注情報ワークテーブルデータ抽出(A-3)
 *  proc_set_edi_errors    EDIエラー情報変数格納(A-5-1)
 *  proc_data_validate     データ妥当性チェック(A-4)
 *  proc_set_edi_work      EDI受注情報ワーク変数格納(A-5)
 *  proc_set_edi_status    EDIステータス更新用変数格納(A-6)
 *  proc_get_edi_headers   EDIヘッダ情報テーブルデータ抽出(A-7)
 *  proc_set_ins_headers   EDIヘッダ情報インサート用変数格納(A-8)
 *  proc_set_upd_headers   EDIヘッダ情報アップデート用変数格納(A-9)
 *  proc_get_edi_lines     EDI明細情報テーブルデータ抽出(A-10)
 *  proc_set_ins_lines     EDI明細情報インサート用変数格納(A-11)
 *  proc_set_upd_lines     EDI明細情報アップデート用変数格納(A-12)
 *  proc_calc_inv_total    伝票毎の合計値を算出(A-13)
 *  proc_set_inv_total     EDIヘッダ情報用変数に伝票計を設定(A-14)
 *  proc_ins_edi_headers   EDIヘッダ情報テーブルデータ追加(A-15)
 *  proc_upd_edi_headers   EDIヘッダ情報テーブルデータ更新(A-16)
 *  proc_ins_edi_lines     EDI明細情報テーブルデータ追加(A-17)
 *  proc_upd_edi_lines     EDI明細情報テーブルデータ更新(A-18)
 *  proc_del_edi_errors    EDIエラー情報テーブルデータ削除(A-19-1)
 *  proc_ins_edi_errors    EDIエラー情報テーブルデータ追加(A-19)
 *  proc_upd_edi_work      EDI受注情報ワークテーブルステータス更新(A-20)
 *  proc_del_edi_work      EDI受注情報ワークテーブルデータ削除(A-21)
 *  proc_del_edi_head_line EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-22)
 *  proc_end               終了処理(A-23)
 *  proc_loop_main         メインループプロシージャ
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   M.Yamaki         新規作成
 *  2009/02/05    1.1   M.Yamaki         [COS_025]同一データ検索条件バグの対応
 *                                       [COS_026]顧客マスタ（顧客区分:10）の顧客ステータスに対応
 *                                       [COS_063]顧客ステータスに対応
 *  2009/02/24    1.2   T.Nakamura       [COS_133]メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/26    1.3   M.Yamaki         [COS_140]正常件数、警告件数の対応
 *  2009/05/08    1.4   T.Kitajima       [T1_0780]価格表未設定リカバリー対応
 *  2009/05/19    1.5   T.Kitajima       [T1_0242]品目取得時、OPM品目マスタ.発売（製造）開始日条件追加
 *                                       [T1_0243]品目取得時、子品目対象外条件追加
 *  2009/06/29    1.6   M.Sano           [T1_0022],[T1_0023],[T1_0024],[T1_0042],[T1_0201]
 *                                       情報区分による必須チェックの実行制御、ブレイクキー変更対応
 *  2009/07/16    1.7   M.Sano           [0000345]店舗納品日出力不正対応
 *  2009/07/22    1.8   M.Sano           [0000644]端数処理対応
 *                                       [0000436]PT対応
 *  2009/07/24    1.8   N.Maeda          [0000644](伝票計)原価金額積上処理追加
 *  2009/08/06    1.8   M.Sano           [0000644]レビュー指摘対応
 *  2009/09/02    1.9   M.Sano           [0001067]PT追加対応
 *  2009/10/02    1.10  M.Sano           [0001156]顧客品目抽出条件追加
 *  2009/11/19    1.11  M.Sano           [I_E_688]ブレイクキーにチェーン店コードを追加
 *  2009/11/25    1.12  K.Atsushiba      [E_本稼動_00098]ブレイクキーに店舗納品日追加、ブレイク条件にNULL考慮
 *                                       顧客チェックにOTHERS例外追加
 *  2009/11/29    1.13  N.Maeda          [E_本稼動_00185] 重複データ検索時条件修正
 *  2009/12/28    1.14  M.Sano           [E_本稼動_00738]
 *                                       ・必須チェック外のレコード作成時の受注連携済フラグのセット値変更
 *                                       ・項目「通過在庫型区分」の追加
 *  2010/01/19    1.15  M.Sano           [E_本稼動_01154][E_本稼動_01156][E_本稼動_01159][E_本稼動_01162][E_本稼動_01551]
 *                                       ・入力パラメータ「チェーン店コード」追加
 *                                       ・EDIエラー情報に列の追加対応
 *                                        (エラーメッセージコード・EDI品目名・EDI受信日・エラーリスト出力済フラグ)
 *                                       ・EDIヘッダ情報に列の追加対応 (EDI受信日)
 *                                       ・妥当性チェックの追加・修正（必須・担当営業員・受注関連明細番号)
 *                                       ・受注エラーリスト出力用の品目エラーメッセージの変更
 *                                       ・EDIエラー情報のパージ処理追加
 *                                       ・情報区分「04」時はチェック処理を実施
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数
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
  lock_expt                 EXCEPTION;       -- ロックエラー
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCOS010A01C';              -- パッケージ名
  --
  cv_application         CONSTANT VARCHAR2(5)   := 'XXCOS';                     -- アプリケーション名
  cv_application_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';                     -- アドオン：販物・在庫領域
  -- プロファイル
  cv_prf_purge_term      CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI情報削除期間
  cv_prf_case_uom        CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:ケース単位コード
  cv_prf_organization_cd CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_prf_org_unit        CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- MO:営業単位
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_prf_err_purge_term  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ERRMSG_PARGE_TERM';
                                                                                -- XXCOS:EDIエラー情報保持期間
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- エラーコード
  cv_msg_param_required  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';          -- 必須入力パラメータ未設定エラーメッセージ
  cv_msg_param_invalid   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';          -- 入力パラメータ不正エラーメッセージ
  cv_msg_profile         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';          -- プロファイル取得エラーメッセージ
  cv_msg_organization_id CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';          -- 在庫組織ID取得エラーメッセージ
  cv_msg_mst_notfound    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';          -- マスタチェックエラーメッセージ
  cv_msg_getdata         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';          -- データ抽出エラーメッセージ
  cv_msg_nodata          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';          -- 対象データなしメッセージ
  cv_msg_required        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00015';          -- 必須未入力エラーメッセージ
  cv_msg_cust_conv       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00020';          -- 顧客コード変換エラーメッセージ
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
  cv_msg_many_cust_conv  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00197';          -- 顧客コード変換エラーメッセージ
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
  cv_msg_price_list      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00022';          -- 価格表未設定エラーメッセージ
  cv_msg_edi_item        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';          -- EDI連携品目コード区分エラーメッセージ
  cv_msg_item_conv       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00024';          -- 商品コード変換エラーメッセージ
  cv_msg_price_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00123';          -- 単価取得エラーメッセージ
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_salesrep_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11963';          -- 担当営業員取得エラーメッセージ
  cv_msg_line_no_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11964';          -- 行No重複エラーメッセージ
-- 2010/01/19 Ver.1.15 M.Sano add End
  cv_msg_insert          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';          -- データ登録エラーメッセージ
  cv_msg_update          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';          -- データ更新エラーメッセージ
  cv_msg_delete          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';          -- データ削除エラーメッセージ
  cv_msg_duplicate       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00025';          -- 重複登録エラーメッセージ
  cv_msg_lock            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';          -- ロックエラーメッセージ
  cv_msg_targetcnt       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';          -- 対象件数メッセージ
  cv_msg_successcnt      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';          -- 成功件数メッセージ
  cv_msg_errorcnt        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';          -- エラー件数メッセージ
  cv_msg_item_cnt        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00039';          -- 商品コードエラー件数メッセージ
  cv_msg_normal          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';          -- 正常終了メッセージ
  cv_msg_warning         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';          -- 警告終了メッセージ
  cv_msg_error           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';          -- エラー終了全ロールバックメッセージ
  cv_msg_lookup_value    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';          -- クイックコード
  cv_msg_org_unit        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';          -- MO:営業単位
  cv_msg_organization_cd CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';          -- XXCOI:在庫組織コード
  cv_msg_case_uom_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';          -- XXCOS:ケース単位コード
  cv_msg_edi_wk_tbl      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00113';          -- EDI受注情報ワークテーブル
  cv_msg_head_tbl        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';          -- EDIヘッダ情報テーブル
  cv_msg_line_tbl        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00115';          -- EDI明細情報テーブル
  cv_msg_err_tbl         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00116';          -- EDIエラー情報テーブル
  cv_msg_param_info      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11951';          -- パラメータ出力メッセージ
  cv_msg_edi_exe         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11952';          -- 実行区分
  cv_msg_purge_term      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11953';          -- XXCOS:EDI情報削除期間
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_err_purge_term  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11962';          -- XXCOS:EDIエラー情報削除期間
-- 2010/01/19 Ver.1.15 M.Sano add End
  cv_msg_shop_code       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11954';          -- 店コード
  cv_msg_line_no         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11955';          -- 行番号
  cv_msg_order_qty       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11956';          -- 発注数量（合計、バラ）
  cv_msg_prod_type_jan   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11957';          -- JANコード
  cv_msg_prod_type_cust  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11958';          -- 顧客品目
  cv_msg_item_err_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11959';          -- EDI品目エラータイプ
  cv_msg_file_name       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11960';          -- インタフェースファイル名
  cv_msg_creation_class  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11961';          -- 作成元区分
  cv_msg_rep_required    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00149';          -- エラーリスト用：必須項目未入力エラー
  cv_msg_rep_cust_conv   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00150';          -- エラーリスト用：顧客コード変換エラー
  cv_msg_rep_cust_stop   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00151';          -- エラーリスト用：顧客中止申請エラー
  cv_msg_rep_price_list  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00152';          -- エラーリスト用：価格表未設定エラー
  cv_msg_rep_edi_item    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00153';          -- エラーリスト用：EDI連携品目コード区分エラー
  cv_msg_rep_item_conv   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00154';          -- エラーリスト用：商品コード変換エラー
  cv_msg_rep_duplicate   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00155';          -- エラーリスト用：重複登録エラー
  cv_msg_rep_price_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00156';          -- エラーリスト用：単価取得エラー
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_rep_salesrep    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00198';          -- エラーリスト用：担当営業員取得エラー
  cv_msg_rep_line_no     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00199';          -- エラーリスト用：行No重複エラー
  cv_msg_rep_no_shop_cd  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00200';          -- エラーリスト用：必須項目(店コード)未入力エラー
  cv_msg_rep_no_line_no  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00201';          -- エラーリスト用：必須項目(行No)未入力エラー
  cv_msg_rep_no_quantity CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00202';          -- エラーリスト用：必須項目(本数)未入力エラー
  cv_msg_rep_cust_item   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00203';          -- エラーリスト用：顧客品目変換エラー
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- トークン
  cv_tkn_in_param        CONSTANT VARCHAR2(20)  := 'IN_PARAM';                  -- 入力パラメータ
  cv_tkn_profile         CONSTANT VARCHAR2(20)  := 'PROFILE';                   -- プロファイル
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';              -- 在庫組織コード
  cv_tkn_item            CONSTANT VARCHAR2(20)  := 'ITEM';                      -- 必須入力項目
  cv_tkn_prod_code       CONSTANT VARCHAR2(20)  := 'PROD_CODE';                 -- 商品コード２
  cv_tkn_prod_type       CONSTANT VARCHAR2(20)  := 'PROD_TYPE';                 -- 顧客品目またはJANコード
  cv_tkn_chain_shop_code CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';           -- EDIチェーン店コード
  cv_tkn_shop_code       CONSTANT VARCHAR2(20)  := 'SHOP_CODE';                 -- 店コード
  cv_tkn_order_no        CONSTANT VARCHAR2(20)  := 'ORDER_NO';                  -- 伝票番号
  cv_tkn_store_deliv_dt  CONSTANT VARCHAR2(20)  := 'STORE_DELIVERY_DATE';       -- 店舗納品日
  cv_tkn_line_no         CONSTANT VARCHAR2(20)  := 'LINE_NO';                   -- 行番号
  cv_tkn_table_name      CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                -- テーブル名
  cv_tkn_key_data        CONSTANT VARCHAR2(20)  := 'KEY_DATA';                  -- キー情報
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                     -- テーブル名
  cv_tkn_column          CONSTANT VARCHAR2(20)  := 'COLMUN';                    -- カラム名
  cv_tkn_param1          CONSTANT VARCHAR2(20)  := 'PARAME1';                   -- パラメータ１
  cv_tkn_param2          CONSTANT VARCHAR2(20)  := 'PARAME2';                   -- パラメータ２
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_tkn_param3          CONSTANT VARCHAR2(20)  := 'PARAM3';                    -- パラメータ３
  cv_tkn_new_line_no     CONSTANT VARCHAR2(20)  := 'NEW_LINE_NO';               -- 行番号(採番後)
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                 -- (変換後)顧客コード
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- クイックコードタイプ
  cv_qck_edi_exe         CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';       -- 実行区分
  cv_qck_creation_class  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';   -- EDI作成元区分
  cv_qck_edi_err_type    CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';  -- EDI品目エラータイプ
-- 2009/12/28 M.Sano Ver.1.14 add Start
  cv_order_class         CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ORDER_CLASS';    -- 受注データ(受注納品確定区分11,12,24)
-- 2009/12/28 M.Sano Ver.1.14 add End
  -- その他定数
  cv_exe_type_new        CONSTANT VARCHAR2(10)  := '0';                         -- 実行区分：新規
  cv_exe_type_retry      CONSTANT VARCHAR2(10)  := '1';                         -- 実行区分：再実施
  cv_edi_status_new      CONSTANT VARCHAR2(10)  := '0';                         -- EDIステータス：新規
  cv_edi_status_warning  CONSTANT VARCHAR2(10)  := '1';                         -- EDIステータス：警告
  cv_edi_status_normal   CONSTANT VARCHAR2(10)  := '2';                         -- EDIステータス：正常
  cv_edi_status_error    CONSTANT VARCHAR2(10)  := '9';                         -- EDIステータス：エラー
  cv_data_type_code      CONSTANT VARCHAR2(10)  := '11';                        -- データ種コード：EDI受注
  cv_creation_class      CONSTANT VARCHAR2(10)  := '10';                        -- 作成元区分：受注
  cv_cust_class_base     CONSTANT VARCHAR2(10)  := '1';                         -- 顧客区分（拠点）
  cv_cust_class_cust     CONSTANT VARCHAR2(10)  := '10';                        -- 顧客区分（顧客）
  cv_cust_class_chain    CONSTANT VARCHAR2(10)  := '18';                        -- 顧客区分（チェーン店）
  cv_cust_site_use_code  CONSTANT VARCHAR2(10)  := 'SHIP_TO';                   -- 顧客使用目的：出荷先
  cv_cust_status_30      CONSTANT VARCHAR2(10)  := '30';                        -- 顧客ステータス：30（承認済）
  cv_cust_status_40      CONSTANT VARCHAR2(10)  := '40';                        -- 顧客ステータス：40（顧客）
  cv_cust_status_99      CONSTANT VARCHAR2(10)  := '99';                        -- 顧客ステータス：99（対象外）
  cv_item_code_div_jan   CONSTANT VARCHAR2(10)  := '2';                         -- EDI連携品目コード区分：JANコード
  cv_item_code_div_cust  CONSTANT VARCHAR2(10)  := '1';                         -- EDI連携品目コード区分：顧客品目
  cv_cust_order_flag     CONSTANT VARCHAR2(10)  := 'Y';                         -- 顧客受注可能フラグ
  cv_sales_class         CONSTANT VARCHAR2(10)  := '1';                         -- 売上対象区分売上
  cv_error_item_type_1   CONSTANT VARCHAR2(10)  := '1';                         -- 品目エラータイプ１
  cv_error_item_type_2   CONSTANT VARCHAR2(10)  := '2';                         -- 品目エラータイプ２
  cv_error_item_type_3   CONSTANT VARCHAR2(10)  := '3';                         -- 品目エラータイプ３
  cv_error_delete_flag   CONSTANT VARCHAR2(10)  := 'Y';                         -- EDIエラー削除フラグ
  cv_cust_item_def_level CONSTANT VARCHAR2(10)  := '1';                         -- 顧客マスタ：定義レベル
  cv_order_forward_flag  CONSTANT VARCHAR2(10)  := 'N';                         -- 受注連携済フラグ：デフォルト
-- 2009/12/28 M.Sano Ver.1.14 add Start
  cv_order_forward_no    CONSTANT VARCHAR2(10)  := 'S';                         -- 受注連携済フラグ：連携対象外
-- 2009/12/28 M.Sano Ver.1.14 add End
  cv_edi_delivery_flag   CONSTANT VARCHAR2(10)  := 'N';                         -- EDI納品予定送信済フラグ：デフォルト
  cv_hht_delivery_flag   CONSTANT VARCHAR2(10)  := 'N';                         -- HHT納品予定連携済フラグ：デフォルト
  cv_cust_status_active  CONSTANT VARCHAR2(10)  := 'A';                         -- 顧客マスタステータス：A（有効）
  cv_enabled             CONSTANT VARCHAR2(10)  := 'Y';                         -- 有効フラグ
  cv_default_language    CONSTANT VARCHAR2(10)  := USERENV('LANG');             -- 標準言語タイプ
--****************************** 2009/05/19 1.5 T.Kitajima ADD START  ******************************--
  cv_format_yyyymmdds    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                -- 日付フォーマット
--****************************** 2009/05/19 1.5 T.Kitajima ADD  END  ******************************--
-- 2009/06/29 M.Sano Ver.1.6 add Start
  cv_info_class_01       CONSTANT VARCHAR2(10)  := '01';                        -- 情報区分:01
  cv_info_class_02       CONSTANT VARCHAR2(10)  := '02';                        -- 情報区分:02
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_info_class_04       CONSTANT VARCHAR2(10)  := '04';                        -- 情報区分:04
-- 2010/01/19 Ver.1.15 M.Sano add End
  cn_check_record_yes    CONSTANT NUMBER        := 1;                           -- 対象レコードのチェック：有
  cn_check_record_no     CONSTANT NUMBER        := 0;                           -- 対象レコードのチェック：無
-- 2009/06/29 M.Sano Ver.1.6 mod End
-- 2009/10/02 Ver1.10 M.Sano Add Start
  cv_inactive_flag_no    CONSTANT VARCHAR2(1)   := 'N';                         -- 顧客品目･相互参照.有効フラグ：有効
-- 2009/10/02 Ver1.10 M.Sano Add End
-- 2010/01/19 Ver1.15 M.Sano Add Start
  cv_err_out_flag_new    CONSTANT VARCHAR2(2)   := 'N0';                        -- エラーリスト出力済フラグ：未出力(新規)
  cv_err_out_flag_retry  CONSTANT VARCHAR2(2)   := 'N1';                        -- エラーリスト出力済フラグ：未出力(再実施)
  cv_err_out_flag_yes    CONSTANT VARCHAR2(2)   := 'Y';                         -- エラーリスト出力済フラグ：出力済
  cv_edi_create_class    CONSTANT VARCHAR2(2)   := '01';                        -- エラーリスト種別：受注
  ct_order_date_def      CONSTANT DATE          := SYSDATE;                     -- 営業担当チェック用日付NULL時のデフォルト値
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- EDI受注情報ワークテーブルカーソル
  CURSOR edi_order_work_cur(
    iv_file_name       VARCHAR2,             -- インタフェースファイル名
    iv_data_type_code  VARCHAR2,             -- データ種コード
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_status          VARCHAR2              -- ステータス
    iv_status          VARCHAR2,             -- ステータス
    iv_edi_chain_code  VARCHAR2              -- EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Mod End
  )
  IS
    SELECT  edi.order_info_work_id           order_info_work_id,                -- 受注情報ワークID
            edi.medium_class                 medium_class,                      -- 媒体区分
            edi.data_type_code               data_type_code,                    -- データ種コード
            edi.file_no                      file_no,                           -- ファイルＮｏ
            edi.info_class                   info_class,                        -- 情報区分
            edi.process_date                 process_date,                      -- 処理日
            edi.process_time                 process_time,                      -- 処理時刻
            edi.base_code                    base_code,                         -- 拠点（部門）コード
            edi.base_name                    base_name,                         -- 拠点名（正式名）
            edi.base_name_alt                base_name_alt,                     -- 拠点名（カナ）
            edi.edi_chain_code               edi_chain_code,                    -- ＥＤＩチェーン店コード
            edi.edi_chain_name               edi_chain_name,                    -- ＥＤＩチェーン店名（漢字）
            edi.edi_chain_name_alt           edi_chain_name_alt,                -- ＥＤＩチェーン店名（カナ）
            edi.chain_code                   chain_code,                        -- チェーン店コード
            edi.chain_name                   chain_name,                        -- チェーン店名（漢字）
            edi.chain_name_alt               chain_name_alt,                    -- チェーン店名（カナ）
            edi.report_code                  report_code,                       -- 帳票コード
            edi.report_show_name             report_show_name,                  -- 帳票表示名
            edi.customer_code                customer_code,                     -- 顧客コード
            edi.customer_name                customer_name,                     -- 顧客名（漢字）
            edi.customer_name_alt            customer_name_alt,                 -- 顧客名（カナ）
            edi.company_code                 company_code,                      -- 社コード
            edi.company_name                 company_name,                      -- 社名（漢字）
            edi.company_name_alt             company_name_alt,                  -- 社名（カナ）
            edi.shop_code                    shop_code,                         -- 店コード
            edi.shop_name                    shop_name,                         -- 店名（漢字）
            edi.shop_name_alt                shop_name_alt,                     -- 店名（カナ）
            edi.delivery_center_code         delivery_center_code,              -- 納入センターコード
            edi.delivery_center_name         delivery_center_name,              -- 納入センター名（漢字）
            edi.delivery_center_name_alt     delivery_center_name_alt,          -- 納入センター名（カナ）
            edi.order_date                   order_date,                        -- 発注日
            edi.center_delivery_date         center_delivery_date,              -- センター納品日
            edi.result_delivery_date         result_delivery_date,              -- 実納品日
            edi.shop_delivery_date           shop_delivery_date,                -- 店舗納品日
            edi.data_creation_date_edi_data  data_creation_date_edi_data,       -- データ作成日（ＥＤＩデータ中）
            edi.data_creation_time_edi_data  data_creation_time_edi_data,       -- データ作成時刻（ＥＤＩデータ中）
            edi.invoice_class                invoice_class,                     -- 伝票区分
            edi.small_classification_code    small_classification_code,         -- 小分類コード
            edi.small_classification_name    small_classification_name,         -- 小分類名
            edi.middle_classification_code   middle_classification_code,        -- 中分類コード
            edi.middle_classification_name   middle_classification_name,        -- 中分類名
            edi.big_classification_code      big_classification_code,           -- 大分類コード
            edi.big_classification_name      big_classification_name,           -- 大分類名
            edi.other_party_department_code  other_party_department_code,       -- 相手先部門コード
            edi.other_party_order_number     other_party_order_number,          -- 相手先発注番号
            edi.check_digit_class            check_digit_class,                 -- チェックデジット有無区分
            edi.invoice_number               invoice_number,                    -- 伝票番号
            edi.check_digit                  check_digit,                       -- チェックデジット
            edi.close_date                   close_date,                        -- 月限
            edi.order_no_ebs                 order_no_ebs,                      -- 受注Ｎｏ（ＥＢＳ）
            edi.ar_sale_class                ar_sale_class,                     -- 特売区分
            edi.delivery_classe              delivery_classe,                   -- 配送区分
            edi.opportunity_no               opportunity_no,                    -- 便Ｎｏ
            edi.contact_to                   contact_to,                        -- 連絡先
            edi.route_sales                  route_sales,                       -- ルートセールス
            edi.corporate_code               corporate_code,                    -- 法人コード
            edi.maker_name                   maker_name,                        -- メーカー名
            edi.area_code                    area_code,                         -- 地区コード
            edi.area_name                    area_name,                         -- 地区名（漢字）
            edi.area_name_alt                area_name_alt,                     -- 地区名（カナ）
            edi.vendor_code                  vendor_code,                       -- 取引先コード
            edi.vendor_name                  vendor_name,                       -- 取引先名（漢字）
            edi.vendor_name1_alt             vendor_name1_alt,                  -- 取引先名１（カナ）
            edi.vendor_name2_alt             vendor_name2_alt,                  -- 取引先名２（カナ）
            edi.vendor_tel                   vendor_tel,                        -- 取引先ＴＥＬ
            edi.vendor_charge                vendor_charge,                     -- 取引先担当者
            edi.vendor_address               vendor_address,                    -- 取引先住所（漢字）
            edi.deliver_to_code_itouen       deliver_to_code_itouen,            -- 届け先コード（伊藤園）
            edi.deliver_to_code_chain        deliver_to_code_chain,             -- 届け先コード（チェーン店）
            edi.deliver_to                   deliver_to,                        -- 届け先（漢字）
            edi.deliver_to1_alt              deliver_to1_alt,                   -- 届け先１（カナ）
            edi.deliver_to2_alt              deliver_to2_alt,                   -- 届け先２（カナ）
            edi.deliver_to_address           deliver_to_address,                -- 届け先住所（漢字）
            edi.deliver_to_address_alt       deliver_to_address_alt,            -- 届け先住所（カナ）
            edi.deliver_to_tel               deliver_to_tel,                    -- 届け先ＴＥＬ
            edi.balance_accounts_code        balance_accounts_code,             -- 帳合先コード
            edi.balance_accounts_company_code balance_accounts_company_code,    -- 帳合先社コード
            edi.balance_accounts_shop_code   balance_accounts_shop_code,        -- 帳合先店コード
            edi.balance_accounts_name        balance_accounts_name,             -- 帳合先名（漢字）
            edi.balance_accounts_name_alt    balance_accounts_name_alt,         -- 帳合先名（カナ）
            edi.balance_accounts_address     balance_accounts_address,          -- 帳合先住所（漢字）
            edi.balance_accounts_address_alt balance_accounts_address_alt,      -- 帳合先住所（カナ）
            edi.balance_accounts_tel         balance_accounts_tel,              -- 帳合先ＴＥＬ
            edi.order_possible_date          order_possible_date,               -- 受注可能日
            edi.permission_possible_date     permission_possible_date,          -- 許容可能日
            edi.forward_month                forward_month,                     -- 先限年月日
            edi.payment_settlement_date      payment_settlement_date,           -- 支払決済日
            edi.handbill_start_date_active   handbill_start_date_active,        -- チラシ開始日
            edi.billing_due_date             billing_due_date,                  -- 請求締日
            edi.shipping_time                shipping_time,                     -- 出荷時刻
            edi.delivery_schedule_time       delivery_schedule_time,            -- 納品予定時間
            edi.order_time                   order_time,                        -- 発注時間
            edi.general_date_item1           general_date_item1,                -- 汎用日付項目１
            edi.general_date_item2           general_date_item2,                -- 汎用日付項目２
            edi.general_date_item3           general_date_item3,                -- 汎用日付項目３
            edi.general_date_item4           general_date_item4,                -- 汎用日付項目４
            edi.general_date_item5           general_date_item5,                -- 汎用日付項目５
            edi.arrival_shipping_class       arrival_shipping_class,            -- 入出荷区分
            edi.vendor_class                 vendor_class,                      -- 取引先区分
            edi.invoice_detailed_class       invoice_detailed_class,            -- 伝票内訳区分
            edi.unit_price_use_class         unit_price_use_class,              -- 単価使用区分
            edi.sub_distribution_center_code sub_distribution_center_code,      -- サブ物流センターコード
            edi.sub_distribution_center_name sub_distribution_center_name,      -- サブ物流センターコード名
            edi.center_delivery_method       center_delivery_method,            -- センター納品方法
            edi.center_use_class             center_use_class,                  -- センター利用区分
            edi.center_whse_class            center_whse_class,                 -- センター倉庫区分
            edi.center_area_class            center_area_class,                 -- センター地域区分
            edi.center_arrival_class         center_arrival_class,              -- センター入荷区分
            edi.depot_class                  depot_class,                       -- デポ区分
            edi.tcdc_class                   tcdc_class,                        -- ＴＣＤＣ区分
            edi.upc_flag                     upc_flag,                          -- ＵＰＣフラグ
            edi.simultaneously_class         simultaneously_class,              -- 一斉区分
            edi.business_id                  business_id,                       -- 業務ＩＤ
            edi.whse_directly_class          whse_directly_class,               -- 倉直区分
            edi.premium_rebate_class         premium_rebate_class,              -- 景品割戻区分
            edi.item_type                    item_type,                         -- 項目種別
            edi.cloth_house_food_class       cloth_house_food_class,            -- 衣家食区分
            edi.mix_class                    mix_class,                         -- 混在区分
            edi.stk_class                    stk_class,                         -- 在庫区分
            edi.last_modify_site_class       last_modify_site_class,            -- 最終修正場所区分
            edi.report_class                 report_class,                      -- 帳票区分
            edi.addition_plan_class          addition_plan_class,               -- 追加・計画区分
            edi.registration_class           registration_class,                -- 登録区分
            edi.specific_class               specific_class,                    -- 特定区分
            edi.dealings_class               dealings_class,                    -- 取引区分
            edi.order_class                  order_class,                       -- 発注区分
            edi.sum_line_class               sum_line_class,                    -- 集計明細区分
            edi.shipping_guidance_class      shipping_guidance_class,           -- 出荷案内以外区分
            edi.shipping_class               shipping_class,                    -- 出荷区分
            edi.product_code_use_class       product_code_use_class,            -- 商品コード使用区分
            edi.cargo_item_class             cargo_item_class,                  -- 積送品区分
            edi.ta_class                     ta_class,                          -- Ｔ／Ａ区分
            edi.plan_code                    plan_code,                         -- 企画コード
            edi.category_code                category_code,                     -- カテゴリーコード
            edi.category_class               category_class,                    -- カテゴリー区分
            edi.carrier_means                carrier_means,                     -- 運送手段
            edi.counter_code                 counter_code,                      -- 売場コード
            edi.move_sign                    move_sign,                         -- 移動サイン
            edi.eos_handwriting_class        eos_handwriting_class,             -- ＥＯＳ・手書区分
            edi.delivery_to_section_code     delivery_to_section_code,          -- 納品先課コード
            edi.invoice_detailed             invoice_detailed,                  -- 伝票内訳
            edi.attach_qty                   attach_qty,                        -- 添付数
            edi.other_party_floor            other_party_floor,                 -- フロア
            edi.text_no                      text_no,                           -- ＴＥＸＴＮｏ
            edi.in_store_code                in_store_code,                     -- インストアコード
            edi.tag_data                     tag_data,                          -- タグ
            edi.competition_code             competition_code,                  -- 競合
            edi.billing_chair                billing_chair,                     -- 請求口座
            edi.chain_store_code             chain_store_code,                  -- チェーンストアーコード
            edi.chain_store_short_name       chain_store_short_name,            -- チェーンストアーコード略式名称
            edi.direct_delivery_rcpt_fee     direct_delivery_rcpt_fee,          -- 直配送／引取料
            edi.bill_info                    bill_info,                         -- 手形情報
            edi.description                  description,                       -- 摘要
            edi.interior_code                interior_code,                     -- 内部コード
            edi.order_info_delivery_category order_info_delivery_category,      -- 発注情報　納品カテゴリー
            edi.purchase_type                purchase_type,                     -- 仕入形態
            edi.delivery_to_name_alt         delivery_to_name_alt,              -- 納品場所名（カナ）
            edi.shop_opened_site             shop_opened_site,                  -- 店出場所
            edi.counter_name                 counter_name,                      -- 売場名
            edi.extension_number             extension_number,                  -- 内線番号
            edi.charge_name                  charge_name,                       -- 担当者名
            edi.price_tag                    price_tag,                         -- 値札
            edi.tax_type                     tax_type,                          -- 税種
            edi.consumption_tax_class        consumption_tax_class,             -- 消費税区分
            edi.brand_class                  brand_class,                       -- ＢＲ
            edi.id_code                      id_code,                           -- ＩＤコード
            edi.department_code              department_code,                   -- 百貨店コード
            edi.department_name              department_name,                   -- 百貨店名
            edi.item_type_number             item_type_number,                  -- 品別番号
            edi.description_department       description_department,            -- 摘要（百貨店）
            edi.price_tag_method             price_tag_method,                  -- 値札方法
            edi.reason_column                reason_column,                     -- 自由欄
            edi.a_column_header              a_column_header,                   -- Ａ欄ヘッダ
            edi.d_column_header              d_column_header,                   -- Ｄ欄ヘッダ
            edi.brand_code                   brand_code,                        -- ブランドコード
            edi.line_code                    line_code,                         -- ラインコード
            edi.class_code                   class_code,                        -- クラスコード
            edi.a1_column                    a1_column,                         -- Ａ－１欄
            edi.b1_column                    b1_column,                         -- Ｂ－１欄
            edi.c1_column                    c1_column,                         -- Ｃ－１欄
            edi.d1_column                    d1_column,                         -- Ｄ－１欄
            edi.e1_column                    e1_column,                         -- Ｅ－１欄
            edi.a2_column                    a2_column,                         -- Ａ－２欄
            edi.b2_column                    b2_column,                         -- Ｂ－２欄
            edi.c2_column                    c2_column,                         -- Ｃ－２欄
            edi.d2_column                    d2_column,                         -- Ｄ－２欄
            edi.e2_column                    e2_column,                         -- Ｅ－２欄
            edi.a3_column                    a3_column,                         -- Ａ－３欄
            edi.b3_column                    b3_column,                         -- Ｂ－３欄
            edi.c3_column                    c3_column,                         -- Ｃ－３欄
            edi.d3_column                    d3_column,                         -- Ｄ－３欄
            edi.e3_column                    e3_column,                         -- Ｅ－３欄
            edi.f1_column                    f1_column,                         -- Ｆ－１欄
            edi.g1_column                    g1_column,                         -- Ｇ－１欄
            edi.h1_column                    h1_column,                         -- Ｈ－１欄
            edi.i1_column                    i1_column,                         -- Ｉ－１欄
            edi.j1_column                    j1_column,                         -- Ｊ－１欄
            edi.k1_column                    k1_column,                         -- Ｋ－１欄
            edi.l1_column                    l1_column,                         -- Ｌ－１欄
            edi.f2_column                    f2_column,                         -- Ｆ－２欄
            edi.g2_column                    g2_column,                         -- Ｇ－２欄
            edi.h2_column                    h2_column,                         -- Ｈ－２欄
            edi.i2_column                    i2_column,                         -- Ｉ－２欄
            edi.j2_column                    j2_column,                         -- Ｊ－２欄
            edi.k2_column                    k2_column,                         -- Ｋ－２欄
            edi.l2_column                    l2_column,                         -- Ｌ－２欄
            edi.f3_column                    f3_column,                         -- Ｆ－３欄
            edi.g3_column                    g3_column,                         -- Ｇ－３欄
            edi.h3_column                    h3_column,                         -- Ｈ－３欄
            edi.i3_column                    i3_column,                         -- Ｉ－３欄
            edi.j3_column                    j3_column,                         -- Ｊ－３欄
            edi.k3_column                    k3_column,                         -- Ｋ－３欄
            edi.l3_column                    l3_column,                         -- Ｌ－３欄
            edi.chain_peculiar_area_header   chain_peculiar_area_header,        -- チェーン店固有エリア（ヘッダー）
            edi.order_connection_number      order_connection_number,           -- 受注関連番号
            edi.line_no                      line_no,                           -- 行Ｎｏ
            edi.stockout_class               stockout_class,                    -- 欠品区分
            edi.stockout_reason              stockout_reason,                   -- 欠品理由
            edi.product_code_itouen          product_code_itouen,               -- 商品コード（伊藤園）
            edi.product_code1                product_code1,                     -- 商品コード１
            edi.product_code2                product_code2,                     -- 商品コード２
            edi.jan_code                     jan_code,                          -- ＪＡＮコード
            edi.itf_code                     itf_code,                          -- ＩＴＦコード
            edi.extension_itf_code           extension_itf_code,                -- 内箱ＩＴＦコード
            edi.case_product_code            case_product_code,                 -- ケース商品コード
            edi.ball_product_code            ball_product_code,                 -- ボール商品コード
            edi.product_code_item_type       product_code_item_type,            -- 商品コード品種
            edi.prod_class                   prod_class,                        -- 商品区分
            edi.product_name                 product_name,                      -- 商品名（漢字）
            edi.product_name1_alt            product_name1_alt,                 -- 商品名１（カナ）
            edi.product_name2_alt            product_name2_alt,                 -- 商品名２（カナ）
            edi.item_standard1               item_standard1,                    -- 規格１
            edi.item_standard2               item_standard2,                    -- 規格２
            edi.qty_in_case                  qty_in_case,                       -- 入数
            edi.num_of_cases                 num_of_cases,                      -- ケース入数
            edi.num_of_ball                  num_of_ball,                       -- ボール入数
            edi.item_color                   item_color,                        -- 色
            edi.item_size                    item_size,                         -- サイズ
            edi.expiration_date              expiration_date,                   -- 賞味期限日
            edi.product_date                 product_date,                      -- 製造日
            edi.order_uom_qty                order_uom_qty,                     -- 発注単位数
            edi.shipping_uom_qty             shipping_uom_qty,                  -- 出荷単位数
            edi.packing_uom_qty              packing_uom_qty,                   -- 梱包単位数
            edi.deal_code                    deal_code,                         -- 引合
            edi.deal_class                   deal_class,                        -- 引合区分
            edi.collation_code               collation_code,                    -- 照合
            edi.uom_code                     uom_code,                          -- 単位
            edi.unit_price_class             unit_price_class,                  -- 単価区分
            edi.parent_packing_number        parent_packing_number,             -- 親梱包番号
            edi.packing_number               packing_number,                    -- 梱包番号
            edi.product_group_code           product_group_code,                -- 商品群コード
            edi.case_dismantle_flag          case_dismantle_flag,               -- ケース解体不可フラグ
            edi.case_class                   case_class,                        -- ケース区分
            edi.indv_order_qty               indv_order_qty,                    -- 発注数量（バラ）
            edi.case_order_qty               case_order_qty,                    -- 発注数量（ケース）
            edi.ball_order_qty               ball_order_qty,                    -- 発注数量（ボール）
            edi.sum_order_qty                sum_order_qty,                     -- 発注数量（合計、バラ）
            edi.indv_shipping_qty            indv_shipping_qty,                 -- 出荷数量（バラ）
            edi.case_shipping_qty            case_shipping_qty,                 -- 出荷数量（ケース）
            edi.ball_shipping_qty            ball_shipping_qty,                 -- 出荷数量（ボール）
            edi.pallet_shipping_qty          pallet_shipping_qty,               -- 出荷数量（パレット）
            edi.sum_shipping_qty             sum_shipping_qty,                  -- 出荷数量（合計、バラ）
            edi.indv_stockout_qty            indv_stockout_qty,                 -- 欠品数量（バラ）
            edi.case_stockout_qty            case_stockout_qty,                 -- 欠品数量（ケース）
            edi.ball_stockout_qty            ball_stockout_qty,                 -- 欠品数量（ボール）
            edi.sum_stockout_qty             sum_stockout_qty,                  -- 欠品数量（合計、バラ）
            edi.case_qty                     case_qty,                          -- ケース個口数
            edi.fold_container_indv_qty      fold_container_indv_qty,           -- オリコン（バラ）個口数
            edi.order_unit_price             order_unit_price,                  -- 原単価（発注）
            edi.shipping_unit_price          shipping_unit_price,               -- 原単価（出荷）
            edi.order_cost_amt               order_cost_amt,                    -- 原価金額（発注）
-- 2009/07/22 Ver.1.8 M.Sano Mod Start
--            edi.shipping_cost_amt            shipping_cost_amt,                 -- 原価金額（出荷）
--            edi.stockout_cost_amt            stockout_cost_amt,                 -- 原価金額（欠品）
            TRUNC(edi.shipping_cost_amt)     shipping_cost_amt,                 -- 原価金額（出荷）
            TRUNC(edi.stockout_cost_amt)     stockout_cost_amt,                 -- 原価金額（欠品）
-- 2009/07/22 Ver.1.8 M.Sano Mod End
            edi.selling_price                selling_price,                     -- 売単価
            edi.order_price_amt              order_price_amt,                   -- 売価金額（発注）
            edi.shipping_price_amt           shipping_price_amt,                -- 売価金額（出荷）
            edi.stockout_price_amt           stockout_price_amt,                -- 売価金額（欠品）
            edi.a_column_department          a_column_department,               -- Ａ欄（百貨店）
            edi.d_column_department          d_column_department,               -- Ｄ欄（百貨店）
            edi.standard_info_depth          standard_info_depth,               -- 規格情報・奥行き
            edi.standard_info_height         standard_info_height,              -- 規格情報・高さ
            edi.standard_info_width          standard_info_width,               -- 規格情報・幅
            edi.standard_info_weight         standard_info_weight,              -- 規格情報・重量
            edi.general_succeeded_item1      general_succeeded_item1,           -- 汎用引継ぎ項目１
            edi.general_succeeded_item2      general_succeeded_item2,           -- 汎用引継ぎ項目２
            edi.general_succeeded_item3      general_succeeded_item3,           -- 汎用引継ぎ項目３
            edi.general_succeeded_item4      general_succeeded_item4,           -- 汎用引継ぎ項目４
            edi.general_succeeded_item5      general_succeeded_item5,           -- 汎用引継ぎ項目５
            edi.general_succeeded_item6      general_succeeded_item6,           -- 汎用引継ぎ項目６
            edi.general_succeeded_item7      general_succeeded_item7,           -- 汎用引継ぎ項目７
            edi.general_succeeded_item8      general_succeeded_item8,           -- 汎用引継ぎ項目８
            edi.general_succeeded_item9      general_succeeded_item9,           -- 汎用引継ぎ項目９
            edi.general_succeeded_item10     general_succeeded_item10,          -- 汎用引継ぎ項目１０
            edi.general_add_item1            general_add_item1,                 -- 汎用付加項目１
            edi.general_add_item2            general_add_item2,                 -- 汎用付加項目２
            edi.general_add_item3            general_add_item3,                 -- 汎用付加項目３
            edi.general_add_item4            general_add_item4,                 -- 汎用付加項目４
            edi.general_add_item5            general_add_item5,                 -- 汎用付加項目５
            edi.general_add_item6            general_add_item6,                 -- 汎用付加項目６
            edi.general_add_item7            general_add_item7,                 -- 汎用付加項目７
            edi.general_add_item8            general_add_item8,                 -- 汎用付加項目８
            edi.general_add_item9            general_add_item9,                 -- 汎用付加項目９
            edi.general_add_item10           general_add_item10,                -- 汎用付加項目１０
            edi.chain_peculiar_area_line     chain_peculiar_area_line,          -- チェーン店固有エリア（明細）
            edi.invoice_indv_order_qty       invoice_indv_order_qty,            -- （伝票計）発注数量（バラ）
            edi.invoice_case_order_qty       invoice_case_order_qty,            -- （伝票計）発注数量（ケース）
            edi.invoice_ball_order_qty       invoice_ball_order_qty,            -- （伝票計）発注数量（ボール）
            edi.invoice_sum_order_qty        invoice_sum_order_qty,             -- （伝票計）発注数量（合計、バラ）
            edi.invoice_indv_shipping_qty    invoice_indv_shipping_qty,         -- （伝票計）出荷数量（バラ）
            edi.invoice_case_shipping_qty    invoice_case_shipping_qty,         -- （伝票計）出荷数量（ケース）
            edi.invoice_ball_shipping_qty    invoice_ball_shipping_qty,         -- （伝票計）出荷数量（ボール）
            edi.invoice_pallet_shipping_qty  invoice_pallet_shipping_qty,       -- （伝票計）出荷数量（パレット）
            edi.invoice_sum_shipping_qty     invoice_sum_shipping_qty,          -- （伝票計）出荷数量（合計、バラ）
            edi.invoice_indv_stockout_qty    invoice_indv_stockout_qty,         -- （伝票計）欠品数量（バラ）
            edi.invoice_case_stockout_qty    invoice_case_stockout_qty,         -- （伝票計）欠品数量（ケース）
            edi.invoice_ball_stockout_qty    invoice_ball_stockout_qty,         -- （伝票計）欠品数量（ボール）
            edi.invoice_sum_stockout_qty     invoice_sum_stockout_qty,          -- （伝票計）欠品数量（合計、バラ）
            edi.invoice_case_qty             invoice_case_qty,                  -- （伝票計）ケース個口数
            edi.invoice_fold_container_qty   invoice_fold_container_qty,        -- （伝票計）オリコン（バラ）個口数
            edi.invoice_order_cost_amt       invoice_order_cost_amt,            -- （伝票計）原価金額（発注）
            edi.invoice_shipping_cost_amt    invoice_shipping_cost_amt,         -- （伝票計）原価金額（出荷）
            edi.invoice_stockout_cost_amt    invoice_stockout_cost_amt,         -- （伝票計）原価金額（欠品）
            edi.invoice_order_price_amt      invoice_order_price_amt,           -- （伝票計）売価金額（発注）
            edi.invoice_shipping_price_amt   invoice_shipping_price_amt,        -- （伝票計）売価金額（出荷）
            edi.invoice_stockout_price_amt   invoice_stockout_price_amt,        -- （伝票計）売価金額（欠品）
            edi.total_indv_order_qty         total_indv_order_qty,              -- （総合計）発注数量（バラ）
            edi.total_case_order_qty         total_case_order_qty,              -- （総合計）発注数量（ケース）
            edi.total_ball_order_qty         total_ball_order_qty,              -- （総合計）発注数量（ボール）
            edi.total_sum_order_qty          total_sum_order_qty,               -- （総合計）発注数量（合計、バラ）
            edi.total_indv_shipping_qty      total_indv_shipping_qty,           -- （総合計）出荷数量（バラ）
            edi.total_case_shipping_qty      total_case_shipping_qty,           -- （総合計）出荷数量（ケース）
            edi.total_ball_shipping_qty      total_ball_shipping_qty,           -- （総合計）出荷数量（ボール）
            edi.total_pallet_shipping_qty    total_pallet_shipping_qty,         -- （総合計）出荷数量（パレット）
            edi.total_sum_shipping_qty       total_sum_shipping_qty,            -- （総合計）出荷数量（合計、バラ）
            edi.total_indv_stockout_qty      total_indv_stockout_qty,           -- （総合計）欠品数量（バラ）
            edi.total_case_stockout_qty      total_case_stockout_qty,           -- （総合計）欠品数量（ケース）
            edi.total_ball_stockout_qty      total_ball_stockout_qty,           -- （総合計）欠品数量（ボール）
            edi.total_sum_stockout_qty       total_sum_stockout_qty,            -- （総合計）欠品数量（合計、バラ）
            edi.total_case_qty               total_case_qty,                    -- （総合計）ケース個口数
            edi.total_fold_container_qty     total_fold_container_qty,          -- （総合計）オリコン（バラ）個口数
            edi.total_order_cost_amt         total_order_cost_amt,              -- （総合計）原価金額（発注）
            edi.total_shipping_cost_amt      total_shipping_cost_amt,           -- （総合計）原価金額（出荷）
            edi.total_stockout_cost_amt      total_stockout_cost_amt,           -- （総合計）原価金額（欠品）
            edi.total_order_price_amt        total_order_price_amt,             -- （総合計）売価金額（発注）
            edi.total_shipping_price_amt     total_shipping_price_amt,          -- （総合計）売価金額（出荷）
            edi.total_stockout_price_amt     total_stockout_price_amt,          -- （総合計）売価金額（欠品）
            edi.total_line_qty               total_line_qty,                    -- トータル行数
            edi.total_invoice_qty            total_invoice_qty,                 -- トータル伝票枚数
            edi.chain_peculiar_area_footer   chain_peculiar_area_footer,        -- チェーン店固有エリア（フッター）
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--            edi.err_status                   err_status                         -- ステータス
            edi.err_status                   err_status,                        -- ステータス
            edi.creation_date                creation_date                      -- 作成日
-- 2010/01/19 Ver1.15 M.Sano Mod End
    FROM    xxcos_edi_order_work             edi
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    WHERE   edi.if_file_name                 = iv_file_name                     -- インタフェースファイル名
    WHERE (   iv_file_name IS NULL
           OR edi.if_file_name               = iv_file_name )                   -- インタフェースファイル名
    AND   (   iv_edi_chain_code IS NULL
           OR edi.edi_chain_code             = iv_edi_chain_code )              -- EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Mod End
    AND     edi.data_type_code               = iv_data_type_code                -- データ種コード
    AND     edi.err_status                   = iv_status                        -- ステータス
    ORDER BY
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
            shop_delivery_date,
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
-- 2009/11/19 M.Sano Ver.1.11 add Start
            edi_chain_code,
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/06/29 M.Sano Ver.1.6 add Start
            shop_code,
-- 2009/06/29 M.Sano Ver.1.6 add End
            invoice_number,
            line_no
    FOR UPDATE NOWAIT;
--
  -- 伝票別発注数量合計 レコードタイプ定義
  TYPE g_inv_total_rtype IS RECORD
    (
      indv_order_qty                         NUMBER,                            -- 発注数量（バラ）
      case_order_qty                         NUMBER,                            -- 発注数量（ケース）
      ball_order_qty                         NUMBER,                            -- 発注数量（ボール）
      sum_order_qty                          NUMBER,                            -- 発注数量（合計、バラ）
      order_cost_amt                         NUMBER,                            -- 原価金額(発注)
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
      shipping_cost_amt                      NUMBER,                            -- 原価金額（出荷）
      stockout_cost_amt                      NUMBER                             -- 原価金額（欠品）
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    );
--
  -- EDI受注情報ワークテーブル レコードタイプ定義
  TYPE g_edi_work_rtype IS RECORD
    (
      order_info_work_id                     xxcos_edi_order_work.order_info_work_id%TYPE,               -- 受注情報ワークID
      medium_class                           xxcos_edi_order_work.medium_class%TYPE,                     -- 媒体区分
      data_type_code                         xxcos_edi_order_work.data_type_code%TYPE,                   -- データ種コード
      file_no                                xxcos_edi_order_work.file_no%TYPE,                          -- ファイルＮｏ
      info_class                             xxcos_edi_order_work.info_class%TYPE,                       -- 情報区分
      process_date                           xxcos_edi_order_work.process_date%TYPE,                     -- 処理日
      process_time                           xxcos_edi_order_work.process_time%TYPE,                     -- 処理時刻
      base_code                              xxcos_edi_order_work.base_code%TYPE,                        -- 拠点（部門）コード
      base_name                              xxcos_edi_order_work.base_name%TYPE,                        -- 拠点名（正式名）
      base_name_alt                          xxcos_edi_order_work.base_name_alt%TYPE,                    -- 拠点名（カナ）
      edi_chain_code                         xxcos_edi_order_work.edi_chain_code%TYPE,                   -- ＥＤＩチェーン店コード
      edi_chain_name                         xxcos_edi_order_work.edi_chain_name%TYPE,                   -- ＥＤＩチェーン店名（漢字）
      edi_chain_name_alt                     xxcos_edi_order_work.edi_chain_name_alt%TYPE,               -- ＥＤＩチェーン店名（カナ）
      chain_code                             xxcos_edi_order_work.chain_code%TYPE,                       -- チェーン店コード
      chain_name                             xxcos_edi_order_work.chain_name%TYPE,                       -- チェーン店名（漢字）
      chain_name_alt                         xxcos_edi_order_work.chain_name_alt%TYPE,                   -- チェーン店名（カナ）
      report_code                            xxcos_edi_order_work.report_code%TYPE,                      -- 帳票コード
      report_show_name                       xxcos_edi_order_work.report_show_name%TYPE,                 -- 帳票表示名
      customer_code                          xxcos_edi_order_work.customer_code%TYPE,                    -- 顧客コード
      customer_name                          xxcos_edi_order_work.customer_name%TYPE,                    -- 顧客名（漢字）
      customer_name_alt                      xxcos_edi_order_work.customer_name_alt%TYPE,                -- 顧客名（カナ）
      company_code                           xxcos_edi_order_work.company_code%TYPE,                     -- 社コード
      company_name                           xxcos_edi_order_work.company_name%TYPE,                     -- 社名（漢字）
      company_name_alt                       xxcos_edi_order_work.company_name_alt%TYPE,                 -- 社名（カナ）
      shop_code                              xxcos_edi_order_work.shop_code%TYPE,                        -- 店コード
      shop_name                              xxcos_edi_order_work.shop_name%TYPE,                        -- 店名（漢字）
      shop_name_alt                          xxcos_edi_order_work.shop_name_alt%TYPE,                    -- 店名（カナ）
      delivery_center_code                   xxcos_edi_order_work.delivery_center_code%TYPE,             -- 納入センターコード
      delivery_center_name                   xxcos_edi_order_work.delivery_center_name%TYPE,             -- 納入センター名（漢字）
      delivery_center_name_alt               xxcos_edi_order_work.delivery_center_name_alt%TYPE,         -- 納入センター名（カナ）
      order_date                             xxcos_edi_order_work.order_date%TYPE,                       -- 発注日
      center_delivery_date                   xxcos_edi_order_work.center_delivery_date%TYPE,             -- センター納品日
      result_delivery_date                   xxcos_edi_order_work.result_delivery_date%TYPE,             -- 実納品日
      shop_delivery_date                     xxcos_edi_order_work.shop_delivery_date%TYPE,               -- 店舗納品日
      data_creation_date_edi_data            xxcos_edi_order_work.data_creation_date_edi_data%TYPE,      -- データ作成日（ＥＤＩデータ中）
      data_creation_time_edi_data            xxcos_edi_order_work.data_creation_time_edi_data%TYPE,      -- データ作成時刻（ＥＤＩデータ中）
      invoice_class                          xxcos_edi_order_work.invoice_class%TYPE,                    -- 伝票区分
      small_classification_code              xxcos_edi_order_work.small_classification_code%TYPE,        -- 小分類コード
      small_classification_name              xxcos_edi_order_work.small_classification_name%TYPE,        -- 小分類名
      middle_classification_code             xxcos_edi_order_work.middle_classification_code%TYPE,       -- 中分類コード
      middle_classification_name             xxcos_edi_order_work.middle_classification_name%TYPE,       -- 中分類名
      big_classification_code                xxcos_edi_order_work.big_classification_code%TYPE,          -- 大分類コード
      big_classification_name                xxcos_edi_order_work.big_classification_name%TYPE,          -- 大分類名
      other_party_department_code            xxcos_edi_order_work.other_party_department_code%TYPE,      -- 相手先部門コード
      other_party_order_number               xxcos_edi_order_work.other_party_order_number%TYPE,         -- 相手先発注番号
      check_digit_class                      xxcos_edi_order_work.check_digit_class%TYPE,                -- チェックデジット有無区分
      invoice_number                         xxcos_edi_order_work.invoice_number%TYPE,                   -- 伝票番号
      check_digit                            xxcos_edi_order_work.check_digit%TYPE,                      -- チェックデジット
      close_date                             xxcos_edi_order_work.close_date%TYPE,                       -- 月限
      order_no_ebs                           xxcos_edi_order_work.order_no_ebs%TYPE,                     -- 受注Ｎｏ（ＥＢＳ）
      ar_sale_class                          xxcos_edi_order_work.ar_sale_class%TYPE,                    -- 特売区分
      delivery_classe                        xxcos_edi_order_work.delivery_classe%TYPE,                  -- 配送区分
      opportunity_no                         xxcos_edi_order_work.opportunity_no%TYPE,                   -- 便Ｎｏ
      contact_to                             xxcos_edi_order_work.contact_to%TYPE,                       -- 連絡先
      route_sales                            xxcos_edi_order_work.route_sales%TYPE,                      -- ルートセールス
      corporate_code                         xxcos_edi_order_work.corporate_code%TYPE,                   -- 法人コード
      maker_name                             xxcos_edi_order_work.maker_name%TYPE,                       -- メーカー名
      area_code                              xxcos_edi_order_work.area_code%TYPE,                        -- 地区コード
      area_name                              xxcos_edi_order_work.area_name%TYPE,                        -- 地区名（漢字）
      area_name_alt                          xxcos_edi_order_work.area_name_alt%TYPE,                    -- 地区名（カナ）
      vendor_code                            xxcos_edi_order_work.vendor_code%TYPE,                      -- 取引先コード
      vendor_name                            xxcos_edi_order_work.vendor_name%TYPE,                      -- 取引先名（漢字）
      vendor_name1_alt                       xxcos_edi_order_work.vendor_name1_alt%TYPE,                 -- 取引先名１（カナ）
      vendor_name2_alt                       xxcos_edi_order_work.vendor_name2_alt%TYPE,                 -- 取引先名２（カナ）
      vendor_tel                             xxcos_edi_order_work.vendor_tel%TYPE,                       -- 取引先ＴＥＬ
      vendor_charge                          xxcos_edi_order_work.vendor_charge%TYPE,                    -- 取引先担当者
      vendor_address                         xxcos_edi_order_work.vendor_address%TYPE,                   -- 取引先住所（漢字）
      deliver_to_code_itouen                 xxcos_edi_order_work.deliver_to_code_itouen%TYPE,           -- 届け先コード（伊藤園）
      deliver_to_code_chain                  xxcos_edi_order_work.deliver_to_code_chain%TYPE,            -- 届け先コード（チェーン店）
      deliver_to                             xxcos_edi_order_work.deliver_to%TYPE,                       -- 届け先（漢字）
      deliver_to1_alt                        xxcos_edi_order_work.deliver_to1_alt%TYPE,                  -- 届け先１（カナ）
      deliver_to2_alt                        xxcos_edi_order_work.deliver_to2_alt%TYPE,                  -- 届け先２（カナ）
      deliver_to_address                     xxcos_edi_order_work.deliver_to_address%TYPE,               -- 届け先住所（漢字）
      deliver_to_address_alt                 xxcos_edi_order_work.deliver_to_address_alt%TYPE,           -- 届け先住所（カナ）
      deliver_to_tel                         xxcos_edi_order_work.deliver_to_tel%TYPE,                   -- 届け先ＴＥＬ
      balance_accounts_code                  xxcos_edi_order_work.balance_accounts_code%TYPE,            -- 帳合先コード
      balance_accounts_company_code          xxcos_edi_order_work.balance_accounts_company_code%TYPE,    -- 帳合先社コード
      balance_accounts_shop_code             xxcos_edi_order_work.balance_accounts_shop_code%TYPE,       -- 帳合先店コード
      balance_accounts_name                  xxcos_edi_order_work.balance_accounts_name%TYPE,            -- 帳合先名（漢字）
      balance_accounts_name_alt              xxcos_edi_order_work.balance_accounts_name_alt%TYPE,        -- 帳合先名（カナ）
      balance_accounts_address               xxcos_edi_order_work.balance_accounts_address%TYPE,         -- 帳合先住所（漢字）
      balance_accounts_address_alt           xxcos_edi_order_work.balance_accounts_address_alt%TYPE,     -- 帳合先住所（カナ）
      balance_accounts_tel                   xxcos_edi_order_work.balance_accounts_tel%TYPE,             -- 帳合先ＴＥＬ
      order_possible_date                    xxcos_edi_order_work.order_possible_date%TYPE,              -- 受注可能日
      permission_possible_date               xxcos_edi_order_work.permission_possible_date%TYPE,         -- 許容可能日
      forward_month                          xxcos_edi_order_work.forward_month%TYPE,                    -- 先限年月日
      payment_settlement_date                xxcos_edi_order_work.payment_settlement_date%TYPE,          -- 支払決済日
      handbill_start_date_active             xxcos_edi_order_work.handbill_start_date_active%TYPE,       -- チラシ開始日
      billing_due_date                       xxcos_edi_order_work.billing_due_date%TYPE,                 -- 請求締日
      shipping_time                          xxcos_edi_order_work.shipping_time%TYPE,                    -- 出荷時刻
      delivery_schedule_time                 xxcos_edi_order_work.delivery_schedule_time%TYPE,           -- 納品予定時間
      order_time                             xxcos_edi_order_work.order_time%TYPE,                       -- 発注時間
      general_date_item1                     xxcos_edi_order_work.general_date_item1%TYPE,               -- 汎用日付項目１
      general_date_item2                     xxcos_edi_order_work.general_date_item2%TYPE,               -- 汎用日付項目２
      general_date_item3                     xxcos_edi_order_work.general_date_item3%TYPE,               -- 汎用日付項目３
      general_date_item4                     xxcos_edi_order_work.general_date_item4%TYPE,               -- 汎用日付項目４
      general_date_item5                     xxcos_edi_order_work.general_date_item5%TYPE,               -- 汎用日付項目５
      arrival_shipping_class                 xxcos_edi_order_work.arrival_shipping_class%TYPE,           -- 入出荷区分
      vendor_class                           xxcos_edi_order_work.vendor_class%TYPE,                     -- 取引先区分
      invoice_detailed_class                 xxcos_edi_order_work.invoice_detailed_class%TYPE,           -- 伝票内訳区分
      unit_price_use_class                   xxcos_edi_order_work.unit_price_use_class%TYPE,             -- 単価使用区分
      sub_distribution_center_code           xxcos_edi_order_work.sub_distribution_center_code%TYPE,     -- サブ物流センターコード
      sub_distribution_center_name           xxcos_edi_order_work.sub_distribution_center_name%TYPE,     -- サブ物流センターコード名
      center_delivery_method                 xxcos_edi_order_work.center_delivery_method%TYPE,           -- センター納品方法
      center_use_class                       xxcos_edi_order_work.center_use_class%TYPE,                 -- センター利用区分
      center_whse_class                      xxcos_edi_order_work.center_whse_class%TYPE,                -- センター倉庫区分
      center_area_class                      xxcos_edi_order_work.center_area_class%TYPE,                -- センター地域区分
      center_arrival_class                   xxcos_edi_order_work.center_arrival_class%TYPE,             -- センター入荷区分
      depot_class                            xxcos_edi_order_work.depot_class%TYPE,                      -- デポ区分
      tcdc_class                             xxcos_edi_order_work.tcdc_class%TYPE,                       -- ＴＣＤＣ区分
      upc_flag                               xxcos_edi_order_work.upc_flag%TYPE,                         -- ＵＰＣフラグ
      simultaneously_class                   xxcos_edi_order_work.simultaneously_class%TYPE,             -- 一斉区分
      business_id                            xxcos_edi_order_work.business_id%TYPE,                      -- 業務ＩＤ
      whse_directly_class                    xxcos_edi_order_work.whse_directly_class%TYPE,              -- 倉直区分
      premium_rebate_class                   xxcos_edi_order_work.premium_rebate_class%TYPE,             -- 景品割戻区分
      item_type                              xxcos_edi_order_work.item_type%TYPE,                        -- 項目種別
      cloth_house_food_class                 xxcos_edi_order_work.cloth_house_food_class%TYPE,           -- 衣家食区分
      mix_class                              xxcos_edi_order_work.mix_class%TYPE,                        -- 混在区分
      stk_class                              xxcos_edi_order_work.stk_class%TYPE,                        -- 在庫区分
      last_modify_site_class                 xxcos_edi_order_work.last_modify_site_class%TYPE,           -- 最終修正場所区分
      report_class                           xxcos_edi_order_work.report_class%TYPE,                     -- 帳票区分
      addition_plan_class                    xxcos_edi_order_work.addition_plan_class%TYPE,              -- 追加・計画区分
      registration_class                     xxcos_edi_order_work.registration_class%TYPE,               -- 登録区分
      specific_class                         xxcos_edi_order_work.specific_class%TYPE,                   -- 特定区分
      dealings_class                         xxcos_edi_order_work.dealings_class%TYPE,                   -- 取引区分
      order_class                            xxcos_edi_order_work.order_class%TYPE,                      -- 発注区分
      sum_line_class                         xxcos_edi_order_work.sum_line_class%TYPE,                   -- 集計明細区分
      shipping_guidance_class                xxcos_edi_order_work.shipping_guidance_class%TYPE,          -- 出荷案内以外区分
      shipping_class                         xxcos_edi_order_work.shipping_class%TYPE,                   -- 出荷区分
      product_code_use_class                 xxcos_edi_order_work.product_code_use_class%TYPE,           -- 商品コード使用区分
      cargo_item_class                       xxcos_edi_order_work.cargo_item_class%TYPE,                 -- 積送品区分
      ta_class                               xxcos_edi_order_work.ta_class%TYPE,                         -- Ｔ／Ａ区分
      plan_code                              xxcos_edi_order_work.plan_code%TYPE,                        -- 企画コード
      category_code                          xxcos_edi_order_work.category_code%TYPE,                    -- カテゴリーコード
      category_class                         xxcos_edi_order_work.category_class%TYPE,                   -- カテゴリー区分
      carrier_means                          xxcos_edi_order_work.carrier_means%TYPE,                    -- 運送手段
      counter_code                           xxcos_edi_order_work.counter_code%TYPE,                     -- 売場コード
      move_sign                              xxcos_edi_order_work.move_sign%TYPE,                        -- 移動サイン
      eos_handwriting_class                  xxcos_edi_order_work.eos_handwriting_class%TYPE,            -- ＥＯＳ・手書区分
      delivery_to_section_code               xxcos_edi_order_work.delivery_to_section_code%TYPE,         -- 納品先課コード
      invoice_detailed                       xxcos_edi_order_work.invoice_detailed%TYPE,                 -- 伝票内訳
      attach_qty                             xxcos_edi_order_work.attach_qty%TYPE,                       -- 添付数
      other_party_floor                      xxcos_edi_order_work.other_party_floor%TYPE,                -- フロア
      text_no                                xxcos_edi_order_work.text_no%TYPE,                          -- ＴＥＸＴＮｏ
      in_store_code                          xxcos_edi_order_work.in_store_code%TYPE,                    -- インストアコード
      tag_data                               xxcos_edi_order_work.tag_data%TYPE,                         -- タグ
      competition_code                       xxcos_edi_order_work.competition_code%TYPE,                 -- 競合
      billing_chair                          xxcos_edi_order_work.billing_chair%TYPE,                    -- 請求口座
      chain_store_code                       xxcos_edi_order_work.chain_store_code%TYPE,                 -- チェーンストアーコード
      chain_store_short_name                 xxcos_edi_order_work.chain_store_short_name%TYPE,           -- チェーンストアーコード略式名称
      direct_delivery_rcpt_fee               xxcos_edi_order_work.direct_delivery_rcpt_fee%TYPE,         -- 直配送／引取料
      bill_info                              xxcos_edi_order_work.bill_info%TYPE,                        -- 手形情報
      description                            xxcos_edi_order_work.description%TYPE,                      -- 摘要
      interior_code                          xxcos_edi_order_work.interior_code%TYPE,                    -- 内部コード
      order_info_delivery_category           xxcos_edi_order_work.order_info_delivery_category%TYPE,     -- 発注情報　納品カテゴリー
      purchase_type                          xxcos_edi_order_work.purchase_type%TYPE,                    -- 仕入形態
      delivery_to_name_alt                   xxcos_edi_order_work.delivery_to_name_alt%TYPE,             -- 納品場所名（カナ）
      shop_opened_site                       xxcos_edi_order_work.shop_opened_site%TYPE,                 -- 店出場所
      counter_name                           xxcos_edi_order_work.counter_name%TYPE,                     -- 売場名
      extension_number                       xxcos_edi_order_work.extension_number%TYPE,                 -- 内線番号
      charge_name                            xxcos_edi_order_work.charge_name%TYPE,                      -- 担当者名
      price_tag                              xxcos_edi_order_work.price_tag%TYPE,                        -- 値札
      tax_type                               xxcos_edi_order_work.tax_type%TYPE,                         -- 税種
      consumption_tax_class                  xxcos_edi_order_work.consumption_tax_class%TYPE,            -- 消費税区分
      brand_class                            xxcos_edi_order_work.brand_class%TYPE,                      -- ＢＲ
      id_code                                xxcos_edi_order_work.id_code%TYPE,                          -- ＩＤコード
      department_code                        xxcos_edi_order_work.department_code%TYPE,                  -- 百貨店コード
      department_name                        xxcos_edi_order_work.department_name%TYPE,                  -- 百貨店名
      item_type_number                       xxcos_edi_order_work.item_type_number%TYPE,                 -- 品別番号
      description_department                 xxcos_edi_order_work.description_department%TYPE,           -- 摘要（百貨店）
      price_tag_method                       xxcos_edi_order_work.price_tag_method%TYPE,                 -- 値札方法
      reason_column                          xxcos_edi_order_work.reason_column%TYPE,                    -- 自由欄
      a_column_header                        xxcos_edi_order_work.a_column_header%TYPE,                  -- Ａ欄ヘッダ
      d_column_header                        xxcos_edi_order_work.d_column_header%TYPE,                  -- Ｄ欄ヘッダ
      brand_code                             xxcos_edi_order_work.brand_code%TYPE,                       -- ブランドコード
      line_code                              xxcos_edi_order_work.line_code%TYPE,                        -- ラインコード
      class_code                             xxcos_edi_order_work.class_code%TYPE,                       -- クラスコード
      a1_column                              xxcos_edi_order_work.a1_column%TYPE,                        -- Ａ－１欄
      b1_column                              xxcos_edi_order_work.b1_column%TYPE,                        -- Ｂ－１欄
      c1_column                              xxcos_edi_order_work.c1_column%TYPE,                        -- Ｃ－１欄
      d1_column                              xxcos_edi_order_work.d1_column%TYPE,                        -- Ｄ－１欄
      e1_column                              xxcos_edi_order_work.e1_column%TYPE,                        -- Ｅ－１欄
      a2_column                              xxcos_edi_order_work.a2_column%TYPE,                        -- Ａ－２欄
      b2_column                              xxcos_edi_order_work.b2_column%TYPE,                        -- Ｂ－２欄
      c2_column                              xxcos_edi_order_work.c2_column%TYPE,                        -- Ｃ－２欄
      d2_column                              xxcos_edi_order_work.d2_column%TYPE,                        -- Ｄ－２欄
      e2_column                              xxcos_edi_order_work.e2_column%TYPE,                        -- Ｅ－２欄
      a3_column                              xxcos_edi_order_work.a3_column%TYPE,                        -- Ａ－３欄
      b3_column                              xxcos_edi_order_work.b3_column%TYPE,                        -- Ｂ－３欄
      c3_column                              xxcos_edi_order_work.c3_column%TYPE,                        -- Ｃ－３欄
      d3_column                              xxcos_edi_order_work.d3_column%TYPE,                        -- Ｄ－３欄
      e3_column                              xxcos_edi_order_work.e3_column%TYPE,                        -- Ｅ－３欄
      f1_column                              xxcos_edi_order_work.f1_column%TYPE,                        -- Ｆ－１欄
      g1_column                              xxcos_edi_order_work.g1_column%TYPE,                        -- Ｇ－１欄
      h1_column                              xxcos_edi_order_work.h1_column%TYPE,                        -- Ｈ－１欄
      i1_column                              xxcos_edi_order_work.i1_column%TYPE,                        -- Ｉ－１欄
      j1_column                              xxcos_edi_order_work.j1_column%TYPE,                        -- Ｊ－１欄
      k1_column                              xxcos_edi_order_work.k1_column%TYPE,                        -- Ｋ－１欄
      l1_column                              xxcos_edi_order_work.l1_column%TYPE,                        -- Ｌ－１欄
      f2_column                              xxcos_edi_order_work.f2_column%TYPE,                        -- Ｆ－２欄
      g2_column                              xxcos_edi_order_work.g2_column%TYPE,                        -- Ｇ－２欄
      h2_column                              xxcos_edi_order_work.h2_column%TYPE,                        -- Ｈ－２欄
      i2_column                              xxcos_edi_order_work.i2_column%TYPE,                        -- Ｉ－２欄
      j2_column                              xxcos_edi_order_work.j2_column%TYPE,                        -- Ｊ－２欄
      k2_column                              xxcos_edi_order_work.k2_column%TYPE,                        -- Ｋ－２欄
      l2_column                              xxcos_edi_order_work.l2_column%TYPE,                        -- Ｌ－２欄
      f3_column                              xxcos_edi_order_work.f3_column%TYPE,                        -- Ｆ－３欄
      g3_column                              xxcos_edi_order_work.g3_column%TYPE,                        -- Ｇ－３欄
      h3_column                              xxcos_edi_order_work.h3_column%TYPE,                        -- Ｈ－３欄
      i3_column                              xxcos_edi_order_work.i3_column%TYPE,                        -- Ｉ－３欄
      j3_column                              xxcos_edi_order_work.j3_column%TYPE,                        -- Ｊ－３欄
      k3_column                              xxcos_edi_order_work.k3_column%TYPE,                        -- Ｋ－３欄
      l3_column                              xxcos_edi_order_work.l3_column%TYPE,                        -- Ｌ－３欄
      chain_peculiar_area_header             xxcos_edi_order_work.chain_peculiar_area_header%TYPE,       -- チェーン店固有エリア（ヘッダー）
      order_connection_number                xxcos_edi_order_work.order_connection_number%TYPE,          -- 受注関連番号
      line_no                                xxcos_edi_order_work.line_no%TYPE,                          -- 行Ｎｏ
      stockout_class                         xxcos_edi_order_work.stockout_class%TYPE,                   -- 欠品区分
      stockout_reason                        xxcos_edi_order_work.stockout_reason%TYPE,                  -- 欠品理由
      product_code_itouen                    xxcos_edi_order_work.product_code_itouen%TYPE,              -- 商品コード（伊藤園）
      product_code1                          xxcos_edi_order_work.product_code1%TYPE,                    -- 商品コード１
      product_code2                          xxcos_edi_order_work.product_code2%TYPE,                    -- 商品コード２
      jan_code                               xxcos_edi_order_work.jan_code%TYPE,                         -- ＪＡＮコード
      itf_code                               xxcos_edi_order_work.itf_code%TYPE,                         -- ＩＴＦコード
      extension_itf_code                     xxcos_edi_order_work.extension_itf_code%TYPE,               -- 内箱ＩＴＦコード
      case_product_code                      xxcos_edi_order_work.case_product_code%TYPE,                -- ケース商品コード
      ball_product_code                      xxcos_edi_order_work.ball_product_code%TYPE,                -- ボール商品コード
      product_code_item_type                 xxcos_edi_order_work.product_code_item_type%TYPE,           -- 商品コード品種
      prod_class                             xxcos_edi_order_work.prod_class%TYPE,                       -- 商品区分
      product_name                           xxcos_edi_order_work.product_name%TYPE,                     -- 商品名（漢字）
      product_name1_alt                      xxcos_edi_order_work.product_name1_alt%TYPE,                -- 商品名１（カナ）
      product_name2_alt                      xxcos_edi_order_work.product_name2_alt%TYPE,                -- 商品名２（カナ）
      item_standard1                         xxcos_edi_order_work.item_standard1%TYPE,                   -- 規格１
      item_standard2                         xxcos_edi_order_work.item_standard2%TYPE,                   -- 規格２
      qty_in_case                            xxcos_edi_order_work.qty_in_case%TYPE,                      -- 入数
      num_of_cases                           xxcos_edi_order_work.num_of_cases%TYPE,                     -- ケース入数
      num_of_ball                            xxcos_edi_order_work.num_of_ball%TYPE,                      -- ボール入数
      item_color                             xxcos_edi_order_work.item_color%TYPE,                       -- 色
      item_size                              xxcos_edi_order_work.item_size%TYPE,                        -- サイズ
      expiration_date                        xxcos_edi_order_work.expiration_date%TYPE,                  -- 賞味期限日
      product_date                           xxcos_edi_order_work.product_date%TYPE,                     -- 製造日
      order_uom_qty                          xxcos_edi_order_work.order_uom_qty%TYPE,                    -- 発注単位数
      shipping_uom_qty                       xxcos_edi_order_work.shipping_uom_qty%TYPE,                 -- 出荷単位数
      packing_uom_qty                        xxcos_edi_order_work.packing_uom_qty%TYPE,                  -- 梱包単位数
      deal_code                              xxcos_edi_order_work.deal_code%TYPE,                        -- 引合
      deal_class                             xxcos_edi_order_work.deal_class%TYPE,                       -- 引合区分
      collation_code                         xxcos_edi_order_work.collation_code%TYPE,                   -- 照合
      uom_code                               xxcos_edi_order_work.uom_code%TYPE,                         -- 単位
      unit_price_class                       xxcos_edi_order_work.unit_price_class%TYPE,                 -- 単価区分
      parent_packing_number                  xxcos_edi_order_work.parent_packing_number%TYPE,            -- 親梱包番号
      packing_number                         xxcos_edi_order_work.packing_number%TYPE,                   -- 梱包番号
      product_group_code                     xxcos_edi_order_work.product_group_code%TYPE,               -- 商品群コード
      case_dismantle_flag                    xxcos_edi_order_work.case_dismantle_flag%TYPE,              -- ケース解体不可フラグ
      case_class                             xxcos_edi_order_work.case_class%TYPE,                       -- ケース区分
      indv_order_qty                         xxcos_edi_order_work.indv_order_qty%TYPE,                   -- 発注数量（バラ）
      case_order_qty                         xxcos_edi_order_work.case_order_qty%TYPE,                   -- 発注数量（ケース）
      ball_order_qty                         xxcos_edi_order_work.ball_order_qty%TYPE,                   -- 発注数量（ボール）
      sum_order_qty                          xxcos_edi_order_work.sum_order_qty%TYPE,                    -- 発注数量（合計、バラ）
      indv_shipping_qty                      xxcos_edi_order_work.indv_shipping_qty%TYPE,                -- 出荷数量（バラ）
      case_shipping_qty                      xxcos_edi_order_work.case_shipping_qty%TYPE,                -- 出荷数量（ケース）
      ball_shipping_qty                      xxcos_edi_order_work.ball_shipping_qty%TYPE,                -- 出荷数量（ボール）
      pallet_shipping_qty                    xxcos_edi_order_work.pallet_shipping_qty%TYPE,              -- 出荷数量（パレット）
      sum_shipping_qty                       xxcos_edi_order_work.sum_shipping_qty%TYPE,                 -- 出荷数量（合計、バラ）
      indv_stockout_qty                      xxcos_edi_order_work.indv_stockout_qty%TYPE,                -- 欠品数量（バラ）
      case_stockout_qty                      xxcos_edi_order_work.case_stockout_qty%TYPE,                -- 欠品数量（ケース）
      ball_stockout_qty                      xxcos_edi_order_work.ball_stockout_qty%TYPE,                -- 欠品数量（ボール）
      sum_stockout_qty                       xxcos_edi_order_work.sum_stockout_qty%TYPE,                 -- 欠品数量（合計、バラ）
      case_qty                               xxcos_edi_order_work.case_qty%TYPE,                         -- ケース個口数
      fold_container_indv_qty                xxcos_edi_order_work.fold_container_indv_qty%TYPE,          -- オリコン（バラ）個口数
      order_unit_price                       xxcos_edi_order_work.order_unit_price%TYPE,                 -- 原単価（発注）
      shipping_unit_price                    xxcos_edi_order_work.shipping_unit_price%TYPE,              -- 原単価（出荷）
      order_cost_amt                         xxcos_edi_order_work.order_cost_amt%TYPE,                   -- 原価金額（発注）
      shipping_cost_amt                      xxcos_edi_order_work.shipping_cost_amt%TYPE,                -- 原価金額（出荷）
      stockout_cost_amt                      xxcos_edi_order_work.stockout_cost_amt%TYPE,                -- 原価金額（欠品）
      selling_price                          xxcos_edi_order_work.selling_price%TYPE,                    -- 売単価
      order_price_amt                        xxcos_edi_order_work.order_price_amt%TYPE,                  -- 売価金額（発注）
      shipping_price_amt                     xxcos_edi_order_work.shipping_price_amt%TYPE,               -- 売価金額（出荷）
      stockout_price_amt                     xxcos_edi_order_work.stockout_price_amt%TYPE,               -- 売価金額（欠品）
      a_column_department                    xxcos_edi_order_work.a_column_department%TYPE,              -- Ａ欄（百貨店）
      d_column_department                    xxcos_edi_order_work.d_column_department%TYPE,              -- Ｄ欄（百貨店）
      standard_info_depth                    xxcos_edi_order_work.standard_info_depth%TYPE,              -- 規格情報・奥行き
      standard_info_height                   xxcos_edi_order_work.standard_info_height%TYPE,             -- 規格情報・高さ
      standard_info_width                    xxcos_edi_order_work.standard_info_width%TYPE,              -- 規格情報・幅
      standard_info_weight                   xxcos_edi_order_work.standard_info_weight%TYPE,             -- 規格情報・重量
      general_succeeded_item1                xxcos_edi_order_work.general_succeeded_item1%TYPE,          -- 汎用引継ぎ項目１
      general_succeeded_item2                xxcos_edi_order_work.general_succeeded_item2%TYPE,          -- 汎用引継ぎ項目２
      general_succeeded_item3                xxcos_edi_order_work.general_succeeded_item3%TYPE,          -- 汎用引継ぎ項目３
      general_succeeded_item4                xxcos_edi_order_work.general_succeeded_item4%TYPE,          -- 汎用引継ぎ項目４
      general_succeeded_item5                xxcos_edi_order_work.general_succeeded_item5%TYPE,          -- 汎用引継ぎ項目５
      general_succeeded_item6                xxcos_edi_order_work.general_succeeded_item6%TYPE,          -- 汎用引継ぎ項目６
      general_succeeded_item7                xxcos_edi_order_work.general_succeeded_item7%TYPE,          -- 汎用引継ぎ項目７
      general_succeeded_item8                xxcos_edi_order_work.general_succeeded_item8%TYPE,          -- 汎用引継ぎ項目８
      general_succeeded_item9                xxcos_edi_order_work.general_succeeded_item9%TYPE,          -- 汎用引継ぎ項目９
      general_succeeded_item10               xxcos_edi_order_work.general_succeeded_item10%TYPE,         -- 汎用引継ぎ項目１０
      general_add_item1                      xxcos_edi_order_work.general_add_item1%TYPE,                -- 汎用付加項目１
      general_add_item2                      xxcos_edi_order_work.general_add_item2%TYPE,                -- 汎用付加項目２
      general_add_item3                      xxcos_edi_order_work.general_add_item3%TYPE,                -- 汎用付加項目３
      general_add_item4                      xxcos_edi_order_work.general_add_item4%TYPE,                -- 汎用付加項目４
      general_add_item5                      xxcos_edi_order_work.general_add_item5%TYPE,                -- 汎用付加項目５
      general_add_item6                      xxcos_edi_order_work.general_add_item6%TYPE,                -- 汎用付加項目６
      general_add_item7                      xxcos_edi_order_work.general_add_item7%TYPE,                -- 汎用付加項目７
      general_add_item8                      xxcos_edi_order_work.general_add_item8%TYPE,                -- 汎用付加項目８
      general_add_item9                      xxcos_edi_order_work.general_add_item9%TYPE,                -- 汎用付加項目９
      general_add_item10                     xxcos_edi_order_work.general_add_item10%TYPE,               -- 汎用付加項目１０
      chain_peculiar_area_line               xxcos_edi_order_work.chain_peculiar_area_line%TYPE,         -- チェーン店固有エリア（明細）
      invoice_indv_order_qty                 xxcos_edi_order_work.invoice_indv_order_qty%TYPE,           -- （伝票計）発注数量（バラ）
      invoice_case_order_qty                 xxcos_edi_order_work.invoice_case_order_qty%TYPE,           -- （伝票計）発注数量（ケース）
      invoice_ball_order_qty                 xxcos_edi_order_work.invoice_ball_order_qty%TYPE,           -- （伝票計）発注数量（ボール）
      invoice_sum_order_qty                  xxcos_edi_order_work.invoice_sum_order_qty%TYPE,            -- （伝票計）発注数量（合計、バラ）
      invoice_indv_shipping_qty              xxcos_edi_order_work.invoice_indv_shipping_qty%TYPE,        -- （伝票計）出荷数量（バラ）
      invoice_case_shipping_qty              xxcos_edi_order_work.invoice_case_shipping_qty%TYPE,        -- （伝票計）出荷数量（ケース）
      invoice_ball_shipping_qty              xxcos_edi_order_work.invoice_ball_shipping_qty%TYPE,        -- （伝票計）出荷数量（ボール）
      invoice_pallet_shipping_qty            xxcos_edi_order_work.invoice_pallet_shipping_qty%TYPE,      -- （伝票計）出荷数量（パレット）
      invoice_sum_shipping_qty               xxcos_edi_order_work.invoice_sum_shipping_qty%TYPE,         -- （伝票計）出荷数量（合計、バラ）
      invoice_indv_stockout_qty              xxcos_edi_order_work.invoice_indv_stockout_qty%TYPE,        -- （伝票計）欠品数量（バラ）
      invoice_case_stockout_qty              xxcos_edi_order_work.invoice_case_stockout_qty%TYPE,        -- （伝票計）欠品数量（ケース）
      invoice_ball_stockout_qty              xxcos_edi_order_work.invoice_ball_stockout_qty%TYPE,        -- （伝票計）欠品数量（ボール）
      invoice_sum_stockout_qty               xxcos_edi_order_work.invoice_sum_stockout_qty%TYPE,         -- （伝票計）欠品数量（合計、バラ）
      invoice_case_qty                       xxcos_edi_order_work.invoice_case_qty%TYPE,                 -- （伝票計）ケース個口数
      invoice_fold_container_qty             xxcos_edi_order_work.invoice_fold_container_qty%TYPE,       -- （伝票計）オリコン（バラ）個口数
      invoice_order_cost_amt                 xxcos_edi_order_work.invoice_order_cost_amt%TYPE,           -- （伝票計）原価金額（発注）
      invoice_shipping_cost_amt              xxcos_edi_order_work.invoice_shipping_cost_amt%TYPE,        -- （伝票計）原価金額（出荷）
      invoice_stockout_cost_amt              xxcos_edi_order_work.invoice_stockout_cost_amt%TYPE,        -- （伝票計）原価金額（欠品）
      invoice_order_price_amt                xxcos_edi_order_work.invoice_order_price_amt%TYPE,          -- （伝票計）売価金額（発注）
      invoice_shipping_price_amt             xxcos_edi_order_work.invoice_shipping_price_amt%TYPE,       -- （伝票計）売価金額（出荷）
      invoice_stockout_price_amt             xxcos_edi_order_work.invoice_stockout_price_amt%TYPE,       -- （伝票計）売価金額（欠品）
      total_indv_order_qty                   xxcos_edi_order_work.total_indv_order_qty%TYPE,             -- （総合計）発注数量（バラ）
      total_case_order_qty                   xxcos_edi_order_work.total_case_order_qty%TYPE,             -- （総合計）発注数量（ケース）
      total_ball_order_qty                   xxcos_edi_order_work.total_ball_order_qty%TYPE,             -- （総合計）発注数量（ボール）
      total_sum_order_qty                    xxcos_edi_order_work.total_sum_order_qty%TYPE,              -- （総合計）発注数量（合計、バラ）
      total_indv_shipping_qty                xxcos_edi_order_work.total_indv_shipping_qty%TYPE,          -- （総合計）出荷数量（バラ）
      total_case_shipping_qty                xxcos_edi_order_work.total_case_shipping_qty%TYPE,          -- （総合計）出荷数量（ケース）
      total_ball_shipping_qty                xxcos_edi_order_work.total_ball_shipping_qty%TYPE,          -- （総合計）出荷数量（ボール）
      total_pallet_shipping_qty              xxcos_edi_order_work.total_pallet_shipping_qty%TYPE,        -- （総合計）出荷数量（パレット）
      total_sum_shipping_qty                 xxcos_edi_order_work.total_sum_shipping_qty%TYPE,           -- （総合計）出荷数量（合計、バラ）
      total_indv_stockout_qty                xxcos_edi_order_work.total_indv_stockout_qty%TYPE,          -- （総合計）欠品数量（バラ）
      total_case_stockout_qty                xxcos_edi_order_work.total_case_stockout_qty%TYPE,          -- （総合計）欠品数量（ケース）
      total_ball_stockout_qty                xxcos_edi_order_work.total_ball_stockout_qty%TYPE,          -- （総合計）欠品数量（ボール）
      total_sum_stockout_qty                 xxcos_edi_order_work.total_sum_stockout_qty%TYPE,           -- （総合計）欠品数量（合計、バラ）
      total_case_qty                         xxcos_edi_order_work.total_case_qty%TYPE,                   -- （総合計）ケース個口数
      total_fold_container_qty               xxcos_edi_order_work.total_fold_container_qty%TYPE,         -- （総合計）オリコン（バラ）個口数
      total_order_cost_amt                   xxcos_edi_order_work.total_order_cost_amt%TYPE,             -- （総合計）原価金額（発注）
      total_shipping_cost_amt                xxcos_edi_order_work.total_shipping_cost_amt%TYPE,          -- （総合計）原価金額（出荷）
      total_stockout_cost_amt                xxcos_edi_order_work.total_stockout_cost_amt%TYPE,          -- （総合計）原価金額（欠品）
      total_order_price_amt                  xxcos_edi_order_work.total_order_price_amt%TYPE,            -- （総合計）売価金額（発注）
      total_shipping_price_amt               xxcos_edi_order_work.total_shipping_price_amt%TYPE,         -- （総合計）売価金額（出荷）
      total_stockout_price_amt               xxcos_edi_order_work.total_stockout_price_amt%TYPE,         -- （総合計）売価金額（欠品）
      total_line_qty                         xxcos_edi_order_work.total_line_qty%TYPE,                   -- トータル行数
      total_invoice_qty                      xxcos_edi_order_work.total_invoice_qty%TYPE,                -- トータル伝票枚数
      chain_peculiar_area_footer             xxcos_edi_order_work.chain_peculiar_area_footer%TYPE,       -- チェーン店固有エリア（フッター）
      err_status                             xxcos_edi_order_work.err_status%TYPE,                       -- ステータス
-- 2010/01/19 Ver1.15 M.Sano Mod Start
      creation_date                          xxcos_edi_order_work.creation_date%TYPE,                    -- 作成日
-- 2010/01/19 Ver1.15 M.Sano Mod End
      -- 以降、EDI受注情報ワークテーブル以外のカラム
      conv_customer_code                     xxcos_edi_headers.conv_customer_code%TYPE,                  -- 変換後顧客コード
      price_list_header_id                   xxcos_edi_headers.price_list_header_id%TYPE,                -- 価格表ヘッダID
      item_code                              xxcos_edi_lines.item_code%TYPE,                             -- 品目コード
      line_uom                               xxcos_edi_lines.line_uom%TYPE,                              -- 明細単位
-- 2009/12/28 M.Sano Ver.1.14 add Start
      order_forward_flag                     xxcos_edi_headers.order_forward_flag%TYPE,                  -- 受注連携済フラグ
      tsukagatazaiko_div                     xxcos_edi_headers.tsukagatazaiko_div%TYPE,                  -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
      order_connection_line_number           xxcos_edi_lines.order_connection_line_number%TYPE,          -- 受注関連明細番号
-- 2010/01/19 Ver.1.15 M.Sano add End
      check_status                           xxcos_edi_order_work.err_status%TYPE                        -- チェックステータス
    );
--
  -- EDI受注情報ワークテーブル テーブルタイプ定義
  TYPE g_edi_order_work_ttype                IS TABLE OF edi_order_work_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
  TYPE g_edi_work_ttype                      IS TABLE OF g_edi_work_rtype;
-- EDIステータス更新定義
  TYPE g_order_info_work_id_ttype            IS TABLE OF xxcos_edi_order_work.order_info_work_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI受注情報ワークID
  TYPE g_edi_err_status_ttype                IS TABLE OF xxcos_edi_order_work.err_status%TYPE
    INDEX BY PLS_INTEGER;     -- ステータス
--
  -- EDIヘッダ情報テーブル テーブルタイプ定義
  TYPE g_edi_headers_ttype                   IS TABLE OF xxcos_edi_headers%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDIヘッダ情報テーブル
--
  -- EDIヘッダ情報テーブル テーブルタイプ定義
  TYPE g_edi_header_info_id_ttype            IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDIヘッダ情報ID
  TYPE g_medium_class_ttype                  IS TABLE OF xxcos_edi_headers.medium_class%TYPE
    INDEX BY PLS_INTEGER;     -- 媒体区分
  TYPE g_data_type_code_ttype                IS TABLE OF xxcos_edi_headers.data_type_code%TYPE
    INDEX BY PLS_INTEGER;     -- データ種コード
  TYPE g_file_no_ttype                       IS TABLE OF xxcos_edi_headers.file_no%TYPE
    INDEX BY PLS_INTEGER;     -- ファイルＮｏ
  TYPE g_info_class_ttype                    IS TABLE OF xxcos_edi_headers.info_class%TYPE
    INDEX BY PLS_INTEGER;     -- 情報区分
  TYPE g_process_date_ttype                  IS TABLE OF xxcos_edi_headers.process_date%TYPE
    INDEX BY PLS_INTEGER;     -- 処理日
  TYPE g_process_time_ttype                  IS TABLE OF xxcos_edi_headers.process_time%TYPE
    INDEX BY PLS_INTEGER;     -- 処理時刻
  TYPE g_base_code_ttype                     IS TABLE OF xxcos_edi_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;     -- 拠点（部門）コード
  TYPE g_base_name_ttype                     IS TABLE OF xxcos_edi_headers.base_name%TYPE
    INDEX BY PLS_INTEGER;     -- 拠点名（正式名）
  TYPE g_base_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.base_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 拠点名（カナ）
  TYPE g_edi_chain_code_ttype                IS TABLE OF xxcos_edi_headers.edi_chain_code%TYPE
    INDEX BY PLS_INTEGER;     -- ＥＤＩチェーン店コード
  TYPE g_edi_chain_name_ttype                IS TABLE OF xxcos_edi_headers.edi_chain_name%TYPE
    INDEX BY PLS_INTEGER;     -- ＥＤＩチェーン店名（漢字）
  TYPE g_edi_chain_name_alt_ttype            IS TABLE OF xxcos_edi_headers.edi_chain_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ＥＤＩチェーン店名（カナ）
  TYPE g_chain_code_ttype                    IS TABLE OF xxcos_edi_headers.chain_code%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店コード
  TYPE g_chain_name_ttype                    IS TABLE OF xxcos_edi_headers.chain_name%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店名（漢字）
  TYPE g_chain_name_alt_ttype                IS TABLE OF xxcos_edi_headers.chain_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店名（カナ）
  TYPE g_report_code_ttype                   IS TABLE OF xxcos_edi_headers.report_code%TYPE
    INDEX BY PLS_INTEGER;     -- 帳票コード
  TYPE g_report_show_name_ttype              IS TABLE OF xxcos_edi_headers.report_show_name%TYPE
    INDEX BY PLS_INTEGER;     -- 帳票表示名
  TYPE g_customer_code_ttype                 IS TABLE OF xxcos_edi_headers.customer_code%TYPE
    INDEX BY PLS_INTEGER;     -- 顧客コード
  TYPE g_customer_name_ttype                 IS TABLE OF xxcos_edi_headers.customer_name%TYPE
    INDEX BY PLS_INTEGER;     -- 顧客名（漢字）
  TYPE g_customer_name_alt_ttype             IS TABLE OF xxcos_edi_headers.customer_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 顧客名（カナ）
  TYPE g_company_code_ttype                  IS TABLE OF xxcos_edi_headers.company_code%TYPE
    INDEX BY PLS_INTEGER;     -- 社コード
  TYPE g_company_name_ttype                  IS TABLE OF xxcos_edi_headers.company_name%TYPE
    INDEX BY PLS_INTEGER;     -- 社名（漢字）
  TYPE g_company_name_alt_ttype              IS TABLE OF xxcos_edi_headers.company_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 社名（カナ）
  TYPE g_shop_code_ttype                     IS TABLE OF xxcos_edi_headers.shop_code%TYPE
    INDEX BY PLS_INTEGER;     -- 店コード
  TYPE g_shop_name_ttype                     IS TABLE OF xxcos_edi_headers.shop_name%TYPE
    INDEX BY PLS_INTEGER;     -- 店名（漢字）
  TYPE g_shop_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.shop_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 店名（カナ）
  TYPE g_delivery_center_cd_ttype            IS TABLE OF xxcos_edi_headers.delivery_center_code%TYPE
    INDEX BY PLS_INTEGER;     -- 納入センターコード
  TYPE g_delivery_center_nm_ttype            IS TABLE OF xxcos_edi_headers.delivery_center_name%TYPE
    INDEX BY PLS_INTEGER;     -- 納入センター名（漢字）
  TYPE g_delivery_center_nm_alt_ttype        IS TABLE OF xxcos_edi_headers.delivery_center_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 納入センター名（カナ）
  TYPE g_order_date_ttype                    IS TABLE OF xxcos_edi_headers.order_date%TYPE
    INDEX BY PLS_INTEGER;     -- 発注日
  TYPE g_center_delivery_date_ttype          IS TABLE OF xxcos_edi_headers.center_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- センター納品日
  TYPE g_result_delivery_date_ttype          IS TABLE OF xxcos_edi_headers.result_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- 実納品日
  TYPE g_shop_delivery_date_ttype            IS TABLE OF xxcos_edi_headers.shop_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- 店舗納品日
  TYPE g_data_creation_date_edi_ttype        IS TABLE OF xxcos_edi_headers.data_creation_date_edi_data%TYPE
    INDEX BY PLS_INTEGER;     -- データ作成日（ＥＤＩデータ中）
  TYPE g_data_creation_time_edi_ttype        IS TABLE OF xxcos_edi_headers.data_creation_time_edi_data%TYPE
    INDEX BY PLS_INTEGER;     -- データ作成時刻（ＥＤＩデータ中）
  TYPE g_invoice_class_ttype                 IS TABLE OF xxcos_edi_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;     -- 伝票区分
  TYPE g_small_class_code_ttype              IS TABLE OF xxcos_edi_headers.small_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- 小分類コード
  TYPE g_small_class_name_ttype              IS TABLE OF xxcos_edi_headers.small_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- 小分類名
  TYPE g_middle_class_code_ttype             IS TABLE OF xxcos_edi_headers.middle_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- 中分類コード
  TYPE g_middle_class_name_ttype             IS TABLE OF xxcos_edi_headers.middle_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- 中分類名
  TYPE g_big_class_code_ttype                IS TABLE OF xxcos_edi_headers.big_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- 大分類コード
  TYPE g_big_class_name_ttype                IS TABLE OF xxcos_edi_headers.big_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- 大分類名
  TYPE g_other_party_depart_cd_ttype         IS TABLE OF xxcos_edi_headers.other_party_department_code%TYPE
    INDEX BY PLS_INTEGER;     -- 相手先部門コード
  TYPE g_other_party_order_num_ttype         IS TABLE OF xxcos_edi_headers.other_party_order_number%TYPE
    INDEX BY PLS_INTEGER;     -- 相手先発注番号
  TYPE g_check_digit_class_ttype             IS TABLE OF xxcos_edi_headers.check_digit_class%TYPE
    INDEX BY PLS_INTEGER;     -- チェックデジット有無区分
  TYPE g_invoice_number_ttype                IS TABLE OF xxcos_edi_headers.invoice_number%TYPE
    INDEX BY PLS_INTEGER;     -- 伝票番号
  TYPE g_check_digit_ttype                   IS TABLE OF xxcos_edi_headers.check_digit%TYPE
    INDEX BY PLS_INTEGER;     -- チェックデジット
  TYPE g_close_date_ttype                    IS TABLE OF xxcos_edi_headers.close_date%TYPE
    INDEX BY PLS_INTEGER;     -- 月限
  TYPE g_order_no_ebs_ttype                  IS TABLE OF xxcos_edi_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;     -- 受注Ｎｏ（ＥＢＳ）
  TYPE g_ar_sale_class_ttype                 IS TABLE OF xxcos_edi_headers.ar_sale_class%TYPE
    INDEX BY PLS_INTEGER;     -- 特売区分
  TYPE g_delivery_classe_ttype               IS TABLE OF xxcos_edi_headers.delivery_classe%TYPE
    INDEX BY PLS_INTEGER;     -- 配送区分
  TYPE g_opportunity_no_ttype                IS TABLE OF xxcos_edi_headers.opportunity_no%TYPE
    INDEX BY PLS_INTEGER;     -- 便Ｎｏ
  TYPE g_contact_to_ttype                    IS TABLE OF xxcos_edi_headers.contact_to%TYPE
    INDEX BY PLS_INTEGER;     -- 連絡先
  TYPE g_route_sales_ttype                   IS TABLE OF xxcos_edi_headers.route_sales%TYPE
    INDEX BY PLS_INTEGER;     -- ルートセールス
  TYPE g_corporate_code_ttype                IS TABLE OF xxcos_edi_headers.corporate_code%TYPE
    INDEX BY PLS_INTEGER;     -- 法人コード
  TYPE g_maker_name_ttype                    IS TABLE OF xxcos_edi_headers.maker_name%TYPE
    INDEX BY PLS_INTEGER;     -- メーカー名
  TYPE g_area_code_ttype                     IS TABLE OF xxcos_edi_headers.area_code%TYPE
    INDEX BY PLS_INTEGER;     -- 地区コード
  TYPE g_area_name_ttype                     IS TABLE OF xxcos_edi_headers.area_name%TYPE
    INDEX BY PLS_INTEGER;     -- 地区名（漢字）
  TYPE g_area_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.area_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 地区名（カナ）
  TYPE g_vendor_code_ttype                   IS TABLE OF xxcos_edi_headers.vendor_code%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先コード
  TYPE g_vendor_name_ttype                   IS TABLE OF xxcos_edi_headers.vendor_name%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先名（漢字）
  TYPE g_vendor_name1_alt_ttype              IS TABLE OF xxcos_edi_headers.vendor_name1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先名１（カナ）
  TYPE g_vendor_name2_alt_ttype              IS TABLE OF xxcos_edi_headers.vendor_name2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先名２（カナ）
  TYPE g_vendor_tel_ttype                    IS TABLE OF xxcos_edi_headers.vendor_tel%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先ＴＥＬ
  TYPE g_vendor_charge_ttype                 IS TABLE OF xxcos_edi_headers.vendor_charge%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先担当者
  TYPE g_vendor_address_ttype                IS TABLE OF xxcos_edi_headers.vendor_address%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先住所（漢字）
  TYPE g_deliver_to_code_itouen_ttype        IS TABLE OF xxcos_edi_headers.deliver_to_code_itouen%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先コード（伊藤園）
  TYPE g_deliver_to_code_chain_ttype         IS TABLE OF xxcos_edi_headers.deliver_to_code_chain%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先コード（チェーン店）
  TYPE g_deliver_to_ttype                    IS TABLE OF xxcos_edi_headers.deliver_to%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先（漢字）
  TYPE g_deliver_to1_alt_ttype               IS TABLE OF xxcos_edi_headers.deliver_to1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先１（カナ）
  TYPE g_deliver_to2_alt_ttype               IS TABLE OF xxcos_edi_headers.deliver_to2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先２（カナ）
  TYPE g_deliver_to_address_ttype            IS TABLE OF xxcos_edi_headers.deliver_to_address%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先住所（漢字）
  TYPE g_deliver_to_address_alt_ttype        IS TABLE OF xxcos_edi_headers.deliver_to_address_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先住所（カナ）
  TYPE g_deliver_to_tel_ttype                IS TABLE OF xxcos_edi_headers.deliver_to_tel%TYPE
    INDEX BY PLS_INTEGER;     -- 届け先ＴＥＬ
  TYPE g_balance_acct_cd_ttype               IS TABLE OF xxcos_edi_headers.balance_accounts_code%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先コード
  TYPE g_balance_acct_comp_cd_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_company_code%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先社コード
  TYPE g_balance_acct_shop_cd_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_shop_code%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先店コード
  TYPE g_balance_acct_nm_ttype               IS TABLE OF xxcos_edi_headers.balance_accounts_name%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先名（漢字）
  TYPE g_balance_acct_nm_alt_ttype           IS TABLE OF xxcos_edi_headers.balance_accounts_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先名（カナ）
  TYPE g_balance_acct_address_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_address%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先住所（漢字）
  TYPE g_balance_acct_addr_alt_ttype         IS TABLE OF xxcos_edi_headers.balance_accounts_address_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先住所（カナ）
  TYPE g_balance_acct_tel_ttype              IS TABLE OF xxcos_edi_headers.balance_accounts_tel%TYPE
    INDEX BY PLS_INTEGER;     -- 帳合先ＴＥＬ
  TYPE g_order_possible_date_ttype           IS TABLE OF xxcos_edi_headers.order_possible_date%TYPE
    INDEX BY PLS_INTEGER;     -- 受注可能日
  TYPE g_permit_possible_date_ttype          IS TABLE OF xxcos_edi_headers.permission_possible_date%TYPE
    INDEX BY PLS_INTEGER;     -- 許容可能日
  TYPE g_forward_month_ttype                 IS TABLE OF xxcos_edi_headers.forward_month%TYPE
    INDEX BY PLS_INTEGER;     -- 先限年月日
  TYPE g_payment_settle_date_ttype           IS TABLE OF xxcos_edi_headers.payment_settlement_date%TYPE
    INDEX BY PLS_INTEGER;     -- 支払決済日
  TYPE g_handbill_st_date_act_ttype          IS TABLE OF xxcos_edi_headers.handbill_start_date_active%TYPE
    INDEX BY PLS_INTEGER;     -- チラシ開始日
  TYPE g_billing_due_date_ttype              IS TABLE OF xxcos_edi_headers.billing_due_date%TYPE
    INDEX BY PLS_INTEGER;     -- 請求締日
  TYPE g_shipping_time_ttype                 IS TABLE OF xxcos_edi_headers.shipping_time%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷時刻
  TYPE g_delivery_schedule_time_ttype        IS TABLE OF xxcos_edi_headers.delivery_schedule_time%TYPE
    INDEX BY PLS_INTEGER;     -- 納品予定時間
  TYPE g_order_time_ttype                    IS TABLE OF xxcos_edi_headers.order_time%TYPE
    INDEX BY PLS_INTEGER;     -- 発注時間
  TYPE g_general_date_item1_ttype            IS TABLE OF xxcos_edi_headers.general_date_item1%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用日付項目１
  TYPE g_general_date_item2_ttype            IS TABLE OF xxcos_edi_headers.general_date_item2%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用日付項目２
  TYPE g_general_date_item3_ttype            IS TABLE OF xxcos_edi_headers.general_date_item3%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用日付項目３
  TYPE g_general_date_item4_ttype            IS TABLE OF xxcos_edi_headers.general_date_item4%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用日付項目４
  TYPE g_general_date_item5_ttype            IS TABLE OF xxcos_edi_headers.general_date_item5%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用日付項目５
  TYPE g_arrival_shipping_class_ttype        IS TABLE OF xxcos_edi_headers.arrival_shipping_class%TYPE
    INDEX BY PLS_INTEGER;     -- 入出荷区分
  TYPE g_vendor_class_ttype                  IS TABLE OF xxcos_edi_headers.vendor_class%TYPE
    INDEX BY PLS_INTEGER;     -- 取引先区分
  TYPE g_invoice_detailed_class_ttype        IS TABLE OF xxcos_edi_headers.invoice_detailed_class%TYPE
    INDEX BY PLS_INTEGER;     -- 伝票内訳区分
  TYPE g_unit_price_use_class_ttype          IS TABLE OF xxcos_edi_headers.unit_price_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- 単価使用区分
  TYPE g_sub_dist_center_cd_ttype            IS TABLE OF xxcos_edi_headers.sub_distribution_center_code%TYPE
    INDEX BY PLS_INTEGER;     -- サブ物流センターコード
  TYPE g_sub_dist_center_nm_ttype            IS TABLE OF xxcos_edi_headers.sub_distribution_center_name%TYPE
    INDEX BY PLS_INTEGER;     -- サブ物流センターコード名
  TYPE g_center_delivery_method_ttype        IS TABLE OF xxcos_edi_headers.center_delivery_method%TYPE
    INDEX BY PLS_INTEGER;     -- センター納品方法
  TYPE g_center_use_class_ttype              IS TABLE OF xxcos_edi_headers.center_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- センター利用区分
  TYPE g_center_whse_class_ttype             IS TABLE OF xxcos_edi_headers.center_whse_class%TYPE
    INDEX BY PLS_INTEGER;     -- センター倉庫区分
  TYPE g_center_area_class_ttype             IS TABLE OF xxcos_edi_headers.center_area_class%TYPE
    INDEX BY PLS_INTEGER;     -- センター地域区分
  TYPE g_center_arrival_class_ttype          IS TABLE OF xxcos_edi_headers.center_arrival_class%TYPE
    INDEX BY PLS_INTEGER;     -- センター入荷区分
  TYPE g_depot_class_ttype                   IS TABLE OF xxcos_edi_headers.depot_class%TYPE
    INDEX BY PLS_INTEGER;     -- デポ区分
  TYPE g_tcdc_class_ttype                    IS TABLE OF xxcos_edi_headers.tcdc_class%TYPE
    INDEX BY PLS_INTEGER;     -- ＴＣＤＣ区分
  TYPE g_upc_flag_ttype                      IS TABLE OF xxcos_edi_headers.upc_flag%TYPE
    INDEX BY PLS_INTEGER;     -- ＵＰＣフラグ
  TYPE g_simultaneously_class_ttype          IS TABLE OF xxcos_edi_headers.simultaneously_class%TYPE
    INDEX BY PLS_INTEGER;     -- 一斉区分
  TYPE g_business_id_ttype                   IS TABLE OF xxcos_edi_headers.business_id%TYPE
    INDEX BY PLS_INTEGER;     -- 業務ＩＤ
  TYPE g_whse_directly_class_ttype           IS TABLE OF xxcos_edi_headers.whse_directly_class%TYPE
    INDEX BY PLS_INTEGER;     -- 倉直区分
  TYPE g_premium_rebate_class_ttype          IS TABLE OF xxcos_edi_headers.premium_rebate_class%TYPE
    INDEX BY PLS_INTEGER;     -- 景品割戻区分
  TYPE g_item_type_ttype                     IS TABLE OF xxcos_edi_headers.item_type%TYPE
    INDEX BY PLS_INTEGER;     -- 項目種別
  TYPE g_cloth_house_food_class_ttype        IS TABLE OF xxcos_edi_headers.cloth_house_food_class%TYPE
    INDEX BY PLS_INTEGER;     -- 衣家食区分
  TYPE g_mix_class_ttype                     IS TABLE OF xxcos_edi_headers.mix_class%TYPE
    INDEX BY PLS_INTEGER;     -- 混在区分
  TYPE g_stk_class_ttype                     IS TABLE OF xxcos_edi_headers.stk_class%TYPE
    INDEX BY PLS_INTEGER;     -- 在庫区分
  TYPE g_last_modify_site_class_ttype        IS TABLE OF xxcos_edi_headers.last_modify_site_class%TYPE
    INDEX BY PLS_INTEGER;     -- 最終修正場所区分
  TYPE g_report_class_ttype                  IS TABLE OF xxcos_edi_headers.report_class%TYPE
    INDEX BY PLS_INTEGER;     -- 帳票区分
  TYPE g_addition_plan_class_ttype           IS TABLE OF xxcos_edi_headers.addition_plan_class%TYPE
    INDEX BY PLS_INTEGER;     -- 追加・計画区分
  TYPE g_registration_class_ttype            IS TABLE OF xxcos_edi_headers.registration_class%TYPE
    INDEX BY PLS_INTEGER;     -- 登録区分
  TYPE g_specific_class_ttype                IS TABLE OF xxcos_edi_headers.specific_class%TYPE
    INDEX BY PLS_INTEGER;     -- 特定区分
  TYPE g_dealings_class_ttype                IS TABLE OF xxcos_edi_headers.dealings_class%TYPE
    INDEX BY PLS_INTEGER;     -- 取引区分
  TYPE g_order_class_ttype                   IS TABLE OF xxcos_edi_headers.order_class%TYPE
    INDEX BY PLS_INTEGER;     -- 発注区分
  TYPE g_sum_line_class_ttype                IS TABLE OF xxcos_edi_headers.sum_line_class%TYPE
    INDEX BY PLS_INTEGER;     -- 集計明細区分
  TYPE g_shipping_guide_class_ttype          IS TABLE OF xxcos_edi_headers.shipping_guidance_class%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷案内以外区分
  TYPE g_shipping_class_ttype                IS TABLE OF xxcos_edi_headers.shipping_class%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷区分
  TYPE g_product_code_use_class_ttype        IS TABLE OF xxcos_edi_headers.product_code_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- 商品コード使用区分
  TYPE g_cargo_item_class_ttype              IS TABLE OF xxcos_edi_headers.cargo_item_class%TYPE
    INDEX BY PLS_INTEGER;     -- 積送品区分
  TYPE g_ta_class_ttype                      IS TABLE OF xxcos_edi_headers.ta_class%TYPE
    INDEX BY PLS_INTEGER;     -- Ｔ／Ａ区分
  TYPE g_plan_code_ttype                     IS TABLE OF xxcos_edi_headers.plan_code%TYPE
    INDEX BY PLS_INTEGER;     -- 企画コード
  TYPE g_category_code_ttype                 IS TABLE OF xxcos_edi_headers.category_code%TYPE
    INDEX BY PLS_INTEGER;     -- カテゴリーコード
  TYPE g_category_class_ttype                IS TABLE OF xxcos_edi_headers.category_class%TYPE
    INDEX BY PLS_INTEGER;     -- カテゴリー区分
  TYPE g_carrier_means_ttype                 IS TABLE OF xxcos_edi_headers.carrier_means%TYPE
    INDEX BY PLS_INTEGER;     -- 運送手段
  TYPE g_counter_code_ttype                  IS TABLE OF xxcos_edi_headers.counter_code%TYPE
    INDEX BY PLS_INTEGER;     -- 売場コード
  TYPE g_move_sign_ttype                     IS TABLE OF xxcos_edi_headers.move_sign%TYPE
    INDEX BY PLS_INTEGER;     -- 移動サイン
  TYPE g_eos_handwriting_class_ttype         IS TABLE OF xxcos_edi_headers.eos_handwriting_class%TYPE
    INDEX BY PLS_INTEGER;     -- ＥＯＳ・手書区分
  TYPE g_delivery_to_section_cd_ttype        IS TABLE OF xxcos_edi_headers.delivery_to_section_code%TYPE
    INDEX BY PLS_INTEGER;     -- 納品先課コード
  TYPE g_invoice_detailed_ttype              IS TABLE OF xxcos_edi_headers.invoice_detailed%TYPE
    INDEX BY PLS_INTEGER;     -- 伝票内訳
  TYPE g_attach_qty_ttype                    IS TABLE OF xxcos_edi_headers.attach_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 添付数
  TYPE g_other_party_floor_ttype             IS TABLE OF xxcos_edi_headers.other_party_floor%TYPE
    INDEX BY PLS_INTEGER;     -- フロア
  TYPE g_text_no_ttype                       IS TABLE OF xxcos_edi_headers.text_no%TYPE
    INDEX BY PLS_INTEGER;     -- ＴＥＸＴＮｏ
  TYPE g_in_store_code_ttype                 IS TABLE OF xxcos_edi_headers.in_store_code%TYPE
    INDEX BY PLS_INTEGER;     -- インストアコード
  TYPE g_tag_data_ttype                      IS TABLE OF xxcos_edi_headers.tag_data%TYPE
    INDEX BY PLS_INTEGER;     -- タグ
  TYPE g_competition_code_ttype              IS TABLE OF xxcos_edi_headers.competition_code%TYPE
    INDEX BY PLS_INTEGER;     -- 競合
  TYPE g_billing_chair_ttype                 IS TABLE OF xxcos_edi_headers.billing_chair%TYPE
    INDEX BY PLS_INTEGER;     -- 請求口座
  TYPE g_chain_store_code_ttype              IS TABLE OF xxcos_edi_headers.chain_store_code%TYPE
    INDEX BY PLS_INTEGER;     -- チェーンストアーコード
  TYPE g_chain_store_short_name_ttype        IS TABLE OF xxcos_edi_headers.chain_store_short_name%TYPE
    INDEX BY PLS_INTEGER;     -- チェーンストアーコード略式名称
  TYPE g_direct_delive_rcpt_fee_ttype        IS TABLE OF xxcos_edi_headers.direct_delivery_rcpt_fee%TYPE
    INDEX BY PLS_INTEGER;     -- 直配送／引取料
  TYPE g_bill_info_ttype                     IS TABLE OF xxcos_edi_headers.bill_info%TYPE
    INDEX BY PLS_INTEGER;     -- 手形情報
  TYPE g_description_ttype                   IS TABLE OF xxcos_edi_headers.description%TYPE
    INDEX BY PLS_INTEGER;     -- 摘要
  TYPE g_interior_code_ttype                 IS TABLE OF xxcos_edi_headers.interior_code%TYPE
    INDEX BY PLS_INTEGER;     -- 内部コード
  TYPE g_order_info_delive_cat_ttype         IS TABLE OF xxcos_edi_headers.order_info_delivery_category%TYPE
    INDEX BY PLS_INTEGER;     -- 発注情報　納品カテゴリー
  TYPE g_purchase_type_ttype                 IS TABLE OF xxcos_edi_headers.purchase_type%TYPE
    INDEX BY PLS_INTEGER;     -- 仕入形態
  TYPE g_delivery_to_name_alt_ttype          IS TABLE OF xxcos_edi_headers.delivery_to_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 納品場所名（カナ）
  TYPE g_shop_opened_site_ttype              IS TABLE OF xxcos_edi_headers.shop_opened_site%TYPE
    INDEX BY PLS_INTEGER;     -- 店出場所
  TYPE g_counter_name_ttype                  IS TABLE OF xxcos_edi_headers.counter_name%TYPE
    INDEX BY PLS_INTEGER;     -- 売場名
  TYPE g_extension_number_ttype              IS TABLE OF xxcos_edi_headers.extension_number%TYPE
    INDEX BY PLS_INTEGER;     -- 内線番号
  TYPE g_charge_name_ttype                   IS TABLE OF xxcos_edi_headers.charge_name%TYPE
    INDEX BY PLS_INTEGER;     -- 担当者名
  TYPE g_price_tag_ttype                     IS TABLE OF xxcos_edi_headers.price_tag%TYPE
    INDEX BY PLS_INTEGER;     -- 値札
  TYPE g_tax_type_ttype                      IS TABLE OF xxcos_edi_headers.tax_type%TYPE
    INDEX BY PLS_INTEGER;     -- 税種
  TYPE g_consumption_tax_class_ttype         IS TABLE OF xxcos_edi_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;     -- 消費税区分
  TYPE g_brand_class_ttype                   IS TABLE OF xxcos_edi_headers.brand_class%TYPE
    INDEX BY PLS_INTEGER;     -- ＢＲ
  TYPE g_id_code_ttype                       IS TABLE OF xxcos_edi_headers.id_code%TYPE
    INDEX BY PLS_INTEGER;     -- ＩＤコード
  TYPE g_department_code_ttype               IS TABLE OF xxcos_edi_headers.department_code%TYPE
    INDEX BY PLS_INTEGER;     -- 百貨店コード
  TYPE g_department_name_ttype               IS TABLE OF xxcos_edi_headers.department_name%TYPE
    INDEX BY PLS_INTEGER;     -- 百貨店名
  TYPE g_item_type_number_ttype              IS TABLE OF xxcos_edi_headers.item_type_number%TYPE
    INDEX BY PLS_INTEGER;     -- 品別番号
  TYPE g_description_department_ttype        IS TABLE OF xxcos_edi_headers.description_department%TYPE
    INDEX BY PLS_INTEGER;     -- 摘要（百貨店）
  TYPE g_price_tag_method_ttype              IS TABLE OF xxcos_edi_headers.price_tag_method%TYPE
    INDEX BY PLS_INTEGER;     -- 値札方法
  TYPE g_reason_column_ttype                 IS TABLE OF xxcos_edi_headers.reason_column%TYPE
    INDEX BY PLS_INTEGER;     -- 自由欄
  TYPE g_a_column_header_ttype               IS TABLE OF xxcos_edi_headers.a_column_header%TYPE
    INDEX BY PLS_INTEGER;     -- Ａ欄ヘッダ
  TYPE g_d_column_header_ttype               IS TABLE OF xxcos_edi_headers.d_column_header%TYPE
    INDEX BY PLS_INTEGER;     -- Ｄ欄ヘッダ
  TYPE g_brand_code_ttype                    IS TABLE OF xxcos_edi_headers.brand_code%TYPE
    INDEX BY PLS_INTEGER;     -- ブランドコード
  TYPE g_line_code_ttype                     IS TABLE OF xxcos_edi_headers.line_code%TYPE
    INDEX BY PLS_INTEGER;     -- ラインコード
  TYPE g_class_code_ttype                    IS TABLE OF xxcos_edi_headers.class_code%TYPE
    INDEX BY PLS_INTEGER;     -- クラスコード
  TYPE g_a1_column_ttype                     IS TABLE OF xxcos_edi_headers.a1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ａ－１欄
  TYPE g_b1_column_ttype                     IS TABLE OF xxcos_edi_headers.b1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｂ－１欄
  TYPE g_c1_column_ttype                     IS TABLE OF xxcos_edi_headers.c1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｃ－１欄
  TYPE g_d1_column_ttype                     IS TABLE OF xxcos_edi_headers.d1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｄ－１欄
  TYPE g_e1_column_ttype                     IS TABLE OF xxcos_edi_headers.e1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｅ－１欄
  TYPE g_a2_column_ttype                     IS TABLE OF xxcos_edi_headers.a2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ａ－２欄
  TYPE g_b2_column_ttype                     IS TABLE OF xxcos_edi_headers.b2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｂ－２欄
  TYPE g_c2_column_ttype                     IS TABLE OF xxcos_edi_headers.c2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｃ－２欄
  TYPE g_d2_column_ttype                     IS TABLE OF xxcos_edi_headers.d2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｄ－２欄
  TYPE g_e2_column_ttype                     IS TABLE OF xxcos_edi_headers.e2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｅ－２欄
  TYPE g_a3_column_ttype                     IS TABLE OF xxcos_edi_headers.a3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ａ－３欄
  TYPE g_b3_column_ttype                     IS TABLE OF xxcos_edi_headers.b3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｂ－３欄
  TYPE g_c3_column_ttype                     IS TABLE OF xxcos_edi_headers.c3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｃ－３欄
  TYPE g_d3_column_ttype                     IS TABLE OF xxcos_edi_headers.d3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｄ－３欄
  TYPE g_e3_column_ttype                     IS TABLE OF xxcos_edi_headers.e3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｅ－３欄
  TYPE g_f1_column_ttype                     IS TABLE OF xxcos_edi_headers.f1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｆ－１欄
  TYPE g_g1_column_ttype                     IS TABLE OF xxcos_edi_headers.g1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｇ－１欄
  TYPE g_h1_column_ttype                     IS TABLE OF xxcos_edi_headers.h1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｈ－１欄
  TYPE g_i1_column_ttype                     IS TABLE OF xxcos_edi_headers.i1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｉ－１欄
  TYPE g_j1_column_ttype                     IS TABLE OF xxcos_edi_headers.j1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｊ－１欄
  TYPE g_k1_column_ttype                     IS TABLE OF xxcos_edi_headers.k1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｋ－１欄
  TYPE g_l1_column_ttype                     IS TABLE OF xxcos_edi_headers.l1_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｌ－１欄
  TYPE g_f2_column_ttype                     IS TABLE OF xxcos_edi_headers.f2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｆ－２欄
  TYPE g_g2_column_ttype                     IS TABLE OF xxcos_edi_headers.g2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｇ－２欄
  TYPE g_h2_column_ttype                     IS TABLE OF xxcos_edi_headers.h2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｈ－２欄
  TYPE g_i2_column_ttype                     IS TABLE OF xxcos_edi_headers.i2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｉ－２欄
  TYPE g_j2_column_ttype                     IS TABLE OF xxcos_edi_headers.j2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｊ－２欄
  TYPE g_k2_column_ttype                     IS TABLE OF xxcos_edi_headers.k2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｋ－２欄
  TYPE g_l2_column_ttype                     IS TABLE OF xxcos_edi_headers.l2_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｌ－２欄
  TYPE g_f3_column_ttype                     IS TABLE OF xxcos_edi_headers.f3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｆ－３欄
  TYPE g_g3_column_ttype                     IS TABLE OF xxcos_edi_headers.g3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｇ－３欄
  TYPE g_h3_column_ttype                     IS TABLE OF xxcos_edi_headers.h3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｈ－３欄
  TYPE g_i3_column_ttype                     IS TABLE OF xxcos_edi_headers.i3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｉ－３欄
  TYPE g_j3_column_ttype                     IS TABLE OF xxcos_edi_headers.j3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｊ－３欄
  TYPE g_k3_column_ttype                     IS TABLE OF xxcos_edi_headers.k3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｋ－３欄
  TYPE g_l3_column_ttype                     IS TABLE OF xxcos_edi_headers.l3_column%TYPE
    INDEX BY PLS_INTEGER;     -- Ｌ－３欄
  TYPE g_chain_pecul_area_head_ttype         IS TABLE OF xxcos_edi_headers.chain_peculiar_area_header%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店固有エリア（ヘッダー）
  TYPE g_order_connection_num_ttype          IS TABLE OF xxcos_edi_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;     -- 受注関連番号
  TYPE g_inv_indv_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）発注数量（バラ）
  TYPE g_inv_case_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）発注数量（ケース）
  TYPE g_inv_ball_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）発注数量（ボール）
  TYPE g_inv_sum_order_qty_ttype             IS TABLE OF xxcos_edi_headers.invoice_sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）発注数量（合計、バラ）
  TYPE g_inv_indv_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）出荷数量（バラ）
  TYPE g_inv_case_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）出荷数量（ケース）
  TYPE g_inv_ball_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）出荷数量（ボール）
  TYPE g_inv_plt_shipping_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）出荷数量（パレット）
  TYPE g_inv_sum_shipping_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）出荷数量（合計、バラ）
  TYPE g_inv_indv_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）欠品数量（バラ）
  TYPE g_inv_case_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）欠品数量（ケース）
  TYPE g_inv_ball_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）欠品数量（ボール）
  TYPE g_inv_sum_stockout_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）欠品数量（合計、バラ）
  TYPE g_inv_case_qty_ttype                  IS TABLE OF xxcos_edi_headers.invoice_case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）ケース個口数
  TYPE g_inv_fold_container_qty_ttype        IS TABLE OF xxcos_edi_headers.invoice_fold_container_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）オリコン（バラ）個口数
  TYPE g_inv_order_cost_amt_ttype            IS TABLE OF xxcos_edi_headers.invoice_order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）原価金額（発注）
  TYPE g_inv_shipping_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.invoice_shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）原価金額（出荷）
  TYPE g_inv_stockout_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.invoice_stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）原価金額（欠品）
  TYPE g_inv_order_price_amt_ttype           IS TABLE OF xxcos_edi_headers.invoice_order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）売価金額（発注）
  TYPE g_inv_shipping_price_amt_ttype        IS TABLE OF xxcos_edi_headers.invoice_shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）売価金額（出荷）
  TYPE g_inv_stockout_price_amt_ttype        IS TABLE OF xxcos_edi_headers.invoice_stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （伝票計）売価金額（欠品）
  TYPE g_total_indv_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）発注数量（バラ）
  TYPE g_total_case_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）発注数量（ケース）
  TYPE g_total_ball_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）発注数量（ボール）
  TYPE g_total_sum_order_qty_ttype           IS TABLE OF xxcos_edi_headers.total_sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）発注数量（合計、バラ）
  TYPE g_total_indv_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）出荷数量（バラ）
  TYPE g_total_case_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）出荷数量（ケース）
  TYPE g_total_ball_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）出荷数量（ボール）
  TYPE g_total_pallet_ship_qty_ttype         IS TABLE OF xxcos_edi_headers.total_pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）出荷数量（パレット）
  TYPE g_total_sum_ship_qty_ttype            IS TABLE OF xxcos_edi_headers.total_sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）出荷数量（合計、バラ）
  TYPE g_total_indv_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）欠品数量（バラ）
  TYPE g_total_case_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）欠品数量（ケース）
  TYPE g_total_ball_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）欠品数量（ボール）
  TYPE g_total_sum_stkout_qty_ttype          IS TABLE OF xxcos_edi_headers.total_sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）欠品数量（合計、バラ）
  TYPE g_total_case_qty_ttype                IS TABLE OF xxcos_edi_headers.total_case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）ケース個口数
  TYPE g_total_fold_contain_qty_ttype        IS TABLE OF xxcos_edi_headers.total_fold_container_qty%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）オリコン（バラ）個口数
  TYPE g_total_order_cost_amt_ttype          IS TABLE OF xxcos_edi_headers.total_order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）原価金額（発注）
  TYPE g_total_ship_cost_amt_ttype           IS TABLE OF xxcos_edi_headers.total_shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）原価金額（出荷）
  TYPE g_total_stkout_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.total_stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）原価金額（欠品）
  TYPE g_total_order_price_amt_ttype         IS TABLE OF xxcos_edi_headers.total_order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）売価金額（発注）
  TYPE g_total_ship_price_amt_ttype          IS TABLE OF xxcos_edi_headers.total_shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）売価金額（出荷）
  TYPE g_total_stock_price_amt_ttype         IS TABLE OF xxcos_edi_headers.total_stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- （総合計）売価金額（欠品）
  TYPE g_total_line_qty_ttype                IS TABLE OF xxcos_edi_headers.total_line_qty%TYPE
    INDEX BY PLS_INTEGER;     -- トータル行数
  TYPE g_total_invoice_qty_ttype             IS TABLE OF xxcos_edi_headers.total_invoice_qty%TYPE
    INDEX BY PLS_INTEGER;     -- トータル伝票枚数
  TYPE g_chain_pecul_area_foot_ttype         IS TABLE OF xxcos_edi_headers.chain_peculiar_area_footer%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店固有エリア（フッター）
  TYPE g_conv_customer_code_ttype            IS TABLE OF xxcos_edi_headers.conv_customer_code%TYPE
    INDEX BY PLS_INTEGER;     -- 変換後顧客コード
  TYPE g_order_forward_flag_ttype            IS TABLE OF xxcos_edi_headers.order_forward_flag%TYPE
    INDEX BY PLS_INTEGER;     -- 受注連携済フラグ
  TYPE g_creation_class_ttype                IS TABLE OF xxcos_edi_headers.creation_class%TYPE
    INDEX BY PLS_INTEGER;     -- 作成元区分
  TYPE g_edi_delivery_sche_flag_ttype        IS TABLE OF xxcos_edi_headers.edi_delivery_schedule_flag%TYPE
    INDEX BY PLS_INTEGER;     -- EDI納品予定送信済フラグ
  TYPE g_price_list_header_id_ttype          IS TABLE OF xxcos_edi_headers.price_list_header_id%TYPE
    INDEX BY PLS_INTEGER;     -- 価格表ヘッダID
-- 2009/12/28 M.Sano Ver.1.14 add Start
  TYPE g_tsukagatazaiko_div_ttype            IS TABLE OF xxcos_edi_headers.tsukagatazaiko_div%TYPE
    INDEX BY PLS_INTEGER;     -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
  TYPE g_edi_received_date_ttype             IS TABLE OF xxcos_edi_headers.edi_received_date%TYPE
    INDEX BY PLS_INTEGER;     -- EDI受信日
-- 2010/01/19 Ver.1.15 M.Sano add End
--
  -- EDI明細情報テーブル テーブルタイプ定義
  TYPE g_edi_lines_ttype                     IS TABLE OF xxcos_edi_lines%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDIヘッダ情報テーブル
--
  -- EDI明細情報テーブル テーブルタイプ定義
  TYPE g_edi_line_info_id_ttype              IS TABLE OF xxcos_edi_lines.edi_line_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI明細情報ID
  TYPE g_edi_line_head_info_id_ttype         IS TABLE OF xxcos_edi_lines.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDIヘッダ情報ID
  TYPE g_line_no_ttype                       IS TABLE OF xxcos_edi_lines.line_no%TYPE
    INDEX BY PLS_INTEGER;     -- 行Ｎｏ
  TYPE g_stockout_class_ttype                IS TABLE OF xxcos_edi_lines.stockout_class%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品区分
  TYPE g_stockout_reason_ttype               IS TABLE OF xxcos_edi_lines.stockout_reason%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品理由
  TYPE g_product_code_itouen_ttype           IS TABLE OF xxcos_edi_lines.product_code_itouen%TYPE
    INDEX BY PLS_INTEGER;     -- 商品コード（伊藤園）
  TYPE g_product_code1_ttype                 IS TABLE OF xxcos_edi_lines.product_code1%TYPE
    INDEX BY PLS_INTEGER;     -- 商品コード１
  TYPE g_product_code2_ttype                 IS TABLE OF xxcos_edi_lines.product_code2%TYPE
    INDEX BY PLS_INTEGER;     -- 商品コード２
  TYPE g_jan_code_ttype                      IS TABLE OF xxcos_edi_lines.jan_code%TYPE
    INDEX BY PLS_INTEGER;     -- ＪＡＮコード
  TYPE g_itf_code_ttype                      IS TABLE OF xxcos_edi_lines.itf_code%TYPE
    INDEX BY PLS_INTEGER;     -- ＩＴＦコード
  TYPE g_extension_itf_code_ttype            IS TABLE OF xxcos_edi_lines.extension_itf_code%TYPE
    INDEX BY PLS_INTEGER;     -- 内箱ＩＴＦコード
  TYPE g_case_product_code_ttype             IS TABLE OF xxcos_edi_lines.case_product_code%TYPE
    INDEX BY PLS_INTEGER;     -- ケース商品コード
  TYPE g_ball_product_code_ttype             IS TABLE OF xxcos_edi_lines.ball_product_code%TYPE
    INDEX BY PLS_INTEGER;     -- ボール商品コード
  TYPE g_product_code_item_type_ttype        IS TABLE OF xxcos_edi_lines.product_code_item_type%TYPE
    INDEX BY PLS_INTEGER;     -- 商品コード品種
  TYPE g_prod_class_ttype                    IS TABLE OF xxcos_edi_lines.prod_class%TYPE
    INDEX BY PLS_INTEGER;     -- 商品区分
  TYPE g_product_name_ttype                  IS TABLE OF xxcos_edi_lines.product_name%TYPE
    INDEX BY PLS_INTEGER;     -- 商品名（漢字）
  TYPE g_product_name1_alt_ttype             IS TABLE OF xxcos_edi_lines.product_name1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 商品名１（カナ）
  TYPE g_product_name2_alt_ttype             IS TABLE OF xxcos_edi_lines.product_name2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- 商品名２（カナ）
  TYPE g_item_standard1_ttype                IS TABLE OF xxcos_edi_lines.item_standard1%TYPE
    INDEX BY PLS_INTEGER;     -- 規格１
  TYPE g_item_standard2_ttype                IS TABLE OF xxcos_edi_lines.item_standard2%TYPE
    INDEX BY PLS_INTEGER;     -- 規格２
  TYPE g_qty_in_case_ttype                   IS TABLE OF xxcos_edi_lines.qty_in_case%TYPE
    INDEX BY PLS_INTEGER;     -- 入数
  TYPE g_num_of_cases_ttype                  IS TABLE OF xxcos_edi_lines.num_of_cases%TYPE
    INDEX BY PLS_INTEGER;     -- ケース入数
  TYPE g_num_of_ball_ttype                   IS TABLE OF xxcos_edi_lines.num_of_ball%TYPE
    INDEX BY PLS_INTEGER;     -- ボール入数
  TYPE g_item_color_ttype                    IS TABLE OF xxcos_edi_lines.item_color%TYPE
    INDEX BY PLS_INTEGER;     -- 色
  TYPE g_item_size_ttype                     IS TABLE OF xxcos_edi_lines.item_size%TYPE
    INDEX BY PLS_INTEGER;     -- サイズ
  TYPE g_expiration_date_ttype               IS TABLE OF xxcos_edi_lines.expiration_date%TYPE
    INDEX BY PLS_INTEGER;     -- 賞味期限日
  TYPE g_product_date_ttype                  IS TABLE OF xxcos_edi_lines.product_date%TYPE
    INDEX BY PLS_INTEGER;     -- 製造日
  TYPE g_order_uom_qty_ttype                 IS TABLE OF xxcos_edi_lines.order_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 発注単位数
  TYPE g_shipping_uom_qty_ttype              IS TABLE OF xxcos_edi_lines.shipping_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷単位数
  TYPE g_packing_uom_qty_ttype               IS TABLE OF xxcos_edi_lines.packing_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 梱包単位数
  TYPE g_deal_code_ttype                     IS TABLE OF xxcos_edi_lines.deal_code%TYPE
    INDEX BY PLS_INTEGER;     -- 引合
  TYPE g_deal_class_ttype                    IS TABLE OF xxcos_edi_lines.deal_class%TYPE
    INDEX BY PLS_INTEGER;     -- 引合区分
  TYPE g_collation_code_ttype                IS TABLE OF xxcos_edi_lines.collation_code%TYPE
    INDEX BY PLS_INTEGER;     -- 照合
  TYPE g_uom_code_ttype                      IS TABLE OF xxcos_edi_lines.uom_code%TYPE
    INDEX BY PLS_INTEGER;     -- 単位
  TYPE g_unit_price_class_ttype              IS TABLE OF xxcos_edi_lines.unit_price_class%TYPE
    INDEX BY PLS_INTEGER;     -- 単価区分
  TYPE g_parent_packing_number_ttype         IS TABLE OF xxcos_edi_lines.parent_packing_number%TYPE
    INDEX BY PLS_INTEGER;     -- 親梱包番号
  TYPE g_packing_number_ttype                IS TABLE OF xxcos_edi_lines.packing_number%TYPE
    INDEX BY PLS_INTEGER;     -- 梱包番号
  TYPE g_product_group_code_ttype            IS TABLE OF xxcos_edi_lines.product_group_code%TYPE
    INDEX BY PLS_INTEGER;     -- 商品群コード
  TYPE g_case_dismantle_flag_ttype           IS TABLE OF xxcos_edi_lines.case_dismantle_flag%TYPE
    INDEX BY PLS_INTEGER;     -- ケース解体不可フラグ
  TYPE g_case_class_ttype                    IS TABLE OF xxcos_edi_lines.case_class%TYPE
    INDEX BY PLS_INTEGER;     -- ケース区分
  TYPE g_indv_order_qty_ttype                IS TABLE OF xxcos_edi_lines.indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 発注数量（バラ）
  TYPE g_case_order_qty_ttype                IS TABLE OF xxcos_edi_lines.case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 発注数量（ケース）
  TYPE g_ball_order_qty_ttype                IS TABLE OF xxcos_edi_lines.ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 発注数量（ボール）
  TYPE g_sum_order_qty_ttype                 IS TABLE OF xxcos_edi_lines.sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 発注数量（合計、バラ）
  TYPE g_indv_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷数量（バラ）
  TYPE g_case_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷数量（ケース）
  TYPE g_ball_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷数量（ボール）
  TYPE g_pallet_shipping_qty_ttype           IS TABLE OF xxcos_edi_lines.pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷数量（パレット）
  TYPE g_sum_shipping_qty_ttype              IS TABLE OF xxcos_edi_lines.sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 出荷数量（合計、バラ）
  TYPE g_indv_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品数量（バラ）
  TYPE g_case_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品数量（ケース）
  TYPE g_ball_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品数量（ボール）
  TYPE g_sum_stockout_qty_ttype              IS TABLE OF xxcos_edi_lines.sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- 欠品数量（合計、バラ）
  TYPE g_case_qty_ttype                      IS TABLE OF xxcos_edi_lines.case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ケース個口数
  TYPE g_fold_contain_indv_qty_ttype         IS TABLE OF xxcos_edi_lines.fold_container_indv_qty%TYPE
    INDEX BY PLS_INTEGER;     -- オリコン（バラ）個口数
  TYPE g_order_unit_price_ttype              IS TABLE OF xxcos_edi_lines.order_unit_price%TYPE
    INDEX BY PLS_INTEGER;     -- 原単価（発注）
  TYPE g_shipping_unit_price_ttype           IS TABLE OF xxcos_edi_lines.shipping_unit_price%TYPE
    INDEX BY PLS_INTEGER;     -- 原単価（出荷）
  TYPE g_order_cost_amt_ttype                IS TABLE OF xxcos_edi_lines.order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 原価金額（発注）
  TYPE g_shipping_cost_amt_ttype             IS TABLE OF xxcos_edi_lines.shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 原価金額（出荷）
  TYPE g_stockout_cost_amt_ttype             IS TABLE OF xxcos_edi_lines.stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 原価金額（欠品）
  TYPE g_selling_price_ttype                 IS TABLE OF xxcos_edi_lines.selling_price%TYPE
    INDEX BY PLS_INTEGER;     -- 売単価
  TYPE g_order_price_amt_ttype               IS TABLE OF xxcos_edi_lines.order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 売価金額（発注）
  TYPE g_shipping_price_amt_ttype            IS TABLE OF xxcos_edi_lines.shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 売価金額（出荷）
  TYPE g_stockout_price_amt_ttype            IS TABLE OF xxcos_edi_lines.stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- 売価金額（欠品）
  TYPE g_a_column_department_ttype           IS TABLE OF xxcos_edi_lines.a_column_department%TYPE
    INDEX BY PLS_INTEGER;     -- Ａ欄（百貨店）
  TYPE g_d_column_department_ttype           IS TABLE OF xxcos_edi_lines.d_column_department%TYPE
    INDEX BY PLS_INTEGER;     -- Ｄ欄（百貨店）
  TYPE g_standard_info_depth_ttype           IS TABLE OF xxcos_edi_lines.standard_info_depth%TYPE
    INDEX BY PLS_INTEGER;     -- 規格情報・奥行き
  TYPE g_standard_info_height_ttype          IS TABLE OF xxcos_edi_lines.standard_info_height%TYPE
    INDEX BY PLS_INTEGER;     -- 規格情報・高さ
  TYPE g_standard_info_width_ttype           IS TABLE OF xxcos_edi_lines.standard_info_width%TYPE
    INDEX BY PLS_INTEGER;     -- 規格情報・幅
  TYPE g_standard_info_weight_ttype          IS TABLE OF xxcos_edi_lines.standard_info_weight%TYPE
    INDEX BY PLS_INTEGER;     -- 規格情報・重量
  TYPE g_general_succeed_item1_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item1%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目１
  TYPE g_general_succeed_item2_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item2%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目２
  TYPE g_general_succeed_item3_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item3%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目３
  TYPE g_general_succeed_item4_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item4%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目４
  TYPE g_general_succeed_item5_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item5%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目５
  TYPE g_general_succeed_item6_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item6%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目６
  TYPE g_general_succeed_item7_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item7%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目７
  TYPE g_general_succeed_item8_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item8%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目８
  TYPE g_general_succeed_item9_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item9%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目９
  TYPE g_general_succeed_item10_ttype        IS TABLE OF xxcos_edi_lines.general_succeeded_item10%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用引継ぎ項目１０
  TYPE g_general_add_item1_ttype             IS TABLE OF xxcos_edi_lines.general_add_item1%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目１
  TYPE g_general_add_item2_ttype             IS TABLE OF xxcos_edi_lines.general_add_item2%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目２
  TYPE g_general_add_item3_ttype             IS TABLE OF xxcos_edi_lines.general_add_item3%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目３
  TYPE g_general_add_item4_ttype             IS TABLE OF xxcos_edi_lines.general_add_item4%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目４
  TYPE g_general_add_item5_ttype             IS TABLE OF xxcos_edi_lines.general_add_item5%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目５
  TYPE g_general_add_item6_ttype             IS TABLE OF xxcos_edi_lines.general_add_item6%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目６
  TYPE g_general_add_item7_ttype             IS TABLE OF xxcos_edi_lines.general_add_item7%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目７
  TYPE g_general_add_item8_ttype             IS TABLE OF xxcos_edi_lines.general_add_item8%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目８
  TYPE g_general_add_item9_ttype             IS TABLE OF xxcos_edi_lines.general_add_item9%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目９
  TYPE g_general_add_item10_ttype            IS TABLE OF xxcos_edi_lines.general_add_item10%TYPE
    INDEX BY PLS_INTEGER;     -- 汎用付加項目１０
  TYPE g_chain_pecul_area_line_ttype         IS TABLE OF xxcos_edi_lines.chain_peculiar_area_line%TYPE
    INDEX BY PLS_INTEGER;     -- チェーン店固有エリア（明細）
  TYPE g_item_code_ttype                     IS TABLE OF xxcos_edi_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;     -- 品目コード
  TYPE g_line_uom_ttype                      IS TABLE OF xxcos_edi_lines.line_uom%TYPE
    INDEX BY PLS_INTEGER;     -- 明細単位
  TYPE g_hht_delivery_sche_flag_ttype        IS TABLE OF xxcos_edi_lines.hht_delivery_schedule_flag%TYPE
    INDEX BY PLS_INTEGER;     -- HHT納品予定連携済フラグ
  TYPE g_order_connect_line_num_ttype        IS TABLE OF xxcos_edi_lines.order_connection_line_number%TYPE
    INDEX BY PLS_INTEGER;     -- 受注関連明細番号
--
  -- EDIエラー情報テーブル テーブルタイプ定義
  TYPE g_edi_errors_ttype                    IS TABLE OF xxcos_edi_errors%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDIエラー情報テーブル
--
  -- EDI品目エラータイプ定義
  TYPE g_edi_item_err_type_ttype             IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(1);
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
  -- 通過在庫型区分タイプ定義
  TYPE g_lookup_tsukagata_div_ttype     IS TABLE OF xxcmm_cust_accounts.tsukagatazaiko_div%TYPE
    INDEX BY xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;
--
-- 2009/12/28 M.Sano Ver.1.14 add End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_purge_term                              fnd_profile_option_values.profile_option_value%TYPE;   -- EDI情報削除期間
-- 2010/01/19 Ver.1.15 M.Sano add Start
  gv_err_purge_term                          fnd_profile_option_values.profile_option_value%TYPE;   -- EDIエラー情報保持期間
-- 2010/01/19 Ver.1.15 M.Sano add End
  gv_case_uom_code                           fnd_profile_option_values.profile_option_value%TYPE;   -- ケース単位コード
  gn_organization_id                         NUMBER;                                                -- 在庫組織ID
  gn_org_unit_id                             NUMBER;                                                -- 営業単位
  gv_creation_class                          fnd_lookup_values.meaning%TYPE;                        -- 作成元区分
--
  -- 伝票エラーフラグ変数
  gn_invoice_err_flag                        NUMBER(1) := 0;
-- 2009/06/29 M.Sano Ver.1.6 add Start
  -- 処理対象レコードのチェック処理判定フラグ変数
  gn_check_record_flag                       NUMBER(1); 
-- 2009/06/29 M.Sano Ver.1.6 add End

--
  -- EDI受注情報ワークテーブル用変数（カーソルレコード型）
  gt_edi_order_work                          g_edi_order_work_ttype;
--
  -- EDI受注情報ワークテーブル用変数
  gt_order_info_work_id                      g_order_info_work_id_ttype;
  gt_edi_err_status                          g_edi_err_status_ttype;
--
  -- 伝票別合計変数
  gt_inv_total                               g_inv_total_rtype;
--
  -- EDI受注情報ワークテーブル変数
  gt_edi_work                                g_edi_work_ttype;
--
  -- EDIヘッダ情報インサート用変数
  gt_edi_headers                             g_edi_headers_ttype;               -- EDIヘッダ情報テーブル
--
  -- EDIヘッダ情報アップデート用変数
  gt_upd_edi_header_info_id                  g_edi_header_info_id_ttype;        -- EDIヘッダ情報ID
  gt_upd_medium_class                        g_medium_class_ttype;              -- 媒体区分
  gt_upd_data_type_code                      g_data_type_code_ttype;            -- データ種コード
  gt_upd_file_no                             g_file_no_ttype;                   -- ファイルＮｏ
  gt_upd_info_class                          g_info_class_ttype;                -- 情報区分
  gt_upd_process_date                        g_process_date_ttype;              -- 処理日
  gt_upd_process_time                        g_process_time_ttype;              -- 処理時刻
  gt_upd_base_code                           g_base_code_ttype;                 -- 拠点（部門）コード
  gt_upd_base_name                           g_base_name_ttype;                 -- 拠点名（正式名）
  gt_upd_base_name_alt                       g_base_name_alt_ttype;             -- 拠点名（カナ）
  gt_upd_edi_chain_code                      g_edi_chain_code_ttype;            -- ＥＤＩチェーン店コード
  gt_upd_edi_chain_name                      g_edi_chain_name_ttype;            -- ＥＤＩチェーン店名（漢字）
  gt_upd_edi_chain_name_alt                  g_edi_chain_name_alt_ttype;        -- ＥＤＩチェーン店名（カナ）
  gt_upd_chain_code                          g_chain_code_ttype;                -- チェーン店コード
  gt_upd_chain_name                          g_chain_name_ttype;                -- チェーン店名（漢字）
  gt_upd_chain_name_alt                      g_chain_name_alt_ttype;            -- チェーン店名（カナ）
  gt_upd_report_code                         g_report_code_ttype;               -- 帳票コード
  gt_upd_report_show_name                    g_report_show_name_ttype;          -- 帳票表示名
  gt_upd_customer_code                       g_customer_code_ttype;             -- 顧客コード
  gt_upd_customer_name                       g_customer_name_ttype;             -- 顧客名（漢字）
  gt_upd_customer_name_alt                   g_customer_name_alt_ttype;         -- 顧客名（カナ）
  gt_upd_company_code                        g_company_code_ttype;              -- 社コード
  gt_upd_company_name                        g_company_name_ttype;              -- 社名（漢字）
  gt_upd_company_name_alt                    g_company_name_alt_ttype;          -- 社名（カナ）
  gt_upd_shop_code                           g_shop_code_ttype;                 -- 店コード
  gt_upd_shop_name                           g_shop_name_ttype;                 -- 店名（漢字）
  gt_upd_shop_name_alt                       g_shop_name_alt_ttype;             -- 店名（カナ）
  gt_upd_delivery_cent_cd                    g_delivery_center_cd_ttype;        -- 納入センターコード
  gt_upd_delivery_cent_nm                    g_delivery_center_nm_ttype;        -- 納入センター名（漢字）
  gt_upd_delivery_cent_nm_alt                g_delivery_center_nm_alt_ttype;    -- 納入センター名（カナ）
  gt_upd_order_date                          g_order_date_ttype;                -- 発注日
  gt_upd_center_delivery_date                g_center_delivery_date_ttype;      -- センター納品日
  gt_upd_result_delivery_date                g_result_delivery_date_ttype;      -- 実納品日
  gt_upd_shop_delivery_date                  g_shop_delivery_date_ttype;        -- 店舗納品日
  gt_upd_data_creation_date_edi              g_data_creation_date_edi_ttype;    -- データ作成日（ＥＤＩデータ中）
  gt_upd_data_creation_time_edi              g_data_creation_time_edi_ttype;    -- データ作成時刻（ＥＤＩデータ中）
  gt_upd_invoice_class                       g_invoice_class_ttype;             -- 伝票区分
  gt_upd_small_class_cd                      g_small_class_code_ttype;          -- 小分類コード
  gt_upd_small_class_nm                      g_small_class_name_ttype;          -- 小分類名
  gt_upd_middle_class_cd                     g_middle_class_code_ttype;         -- 中分類コード
  gt_upd_middle_class_nm                     g_middle_class_name_ttype;         -- 中分類名
  gt_upd_big_class_cd                        g_big_class_code_ttype;            -- 大分類コード
  gt_upd_big_class_nm                        g_big_class_name_ttype;            -- 大分類名
  gt_upd_other_party_depart_cd               g_other_party_depart_cd_ttype;     -- 相手先部門コード
  gt_upd_other_party_order_num               g_other_party_order_num_ttype;     -- 相手先発注番号
  gt_upd_check_digit_class                   g_check_digit_class_ttype;         -- チェックデジット有無区分
  gt_upd_invoice_number                      g_invoice_number_ttype;            -- 伝票番号
  gt_upd_check_digit                         g_check_digit_ttype;               -- チェックデジット
  gt_upd_close_date                          g_close_date_ttype;                -- 月限
  gt_upd_order_no_ebs                        g_order_no_ebs_ttype;              -- 受注Ｎｏ（ＥＢＳ）
  gt_upd_ar_sale_class                       g_ar_sale_class_ttype;             -- 特売区分
  gt_upd_delivery_classe                     g_delivery_classe_ttype;           -- 配送区分
  gt_upd_opportunity_no                      g_opportunity_no_ttype;            -- 便Ｎｏ
  gt_upd_contact_to                          g_contact_to_ttype;                -- 連絡先
  gt_upd_route_sales                         g_route_sales_ttype;               -- ルートセールス
  gt_upd_corporate_code                      g_corporate_code_ttype;            -- 法人コード
  gt_upd_maker_name                          g_maker_name_ttype;                -- メーカー名
  gt_upd_area_code                           g_area_code_ttype;                 -- 地区コード
  gt_upd_area_name                           g_area_name_ttype;                 -- 地区名（漢字）
  gt_upd_area_name_alt                       g_area_name_alt_ttype;             -- 地区名（カナ）
  gt_upd_vendor_code                         g_vendor_code_ttype;               -- 取引先コード
  gt_upd_vendor_name                         g_vendor_name_ttype;               -- 取引先名（漢字）
  gt_upd_vendor_name1_alt                    g_vendor_name1_alt_ttype;          -- 取引先名１（カナ）
  gt_upd_vendor_name2_alt                    g_vendor_name2_alt_ttype;          -- 取引先名２（カナ）
  gt_upd_vendor_tel                          g_vendor_tel_ttype;                -- 取引先ＴＥＬ
  gt_upd_vendor_charge                       g_vendor_charge_ttype;             -- 取引先担当者
  gt_upd_vendor_address                      g_vendor_address_ttype;            -- 取引先住所（漢字）
  gt_upd_deliver_to_code_itouen              g_deliver_to_code_itouen_ttype;    -- 届け先コード（伊藤園）
  gt_upd_deliver_to_code_chain               g_deliver_to_code_chain_ttype;     -- 届け先コード（チェーン店）
  gt_upd_deliver_to                          g_deliver_to_ttype;                -- 届け先（漢字）
  gt_upd_deliver_to1_alt                     g_deliver_to1_alt_ttype;           -- 届け先１（カナ）
  gt_upd_deliver_to2_alt                     g_deliver_to2_alt_ttype;           -- 届け先２（カナ）
  gt_upd_deliver_to_address                  g_deliver_to_address_ttype;        -- 届け先住所（漢字）
  gt_upd_deliver_to_address_alt              g_deliver_to_address_alt_ttype;    -- 届け先住所（カナ）
  gt_upd_deliver_to_tel                      g_deliver_to_tel_ttype;            -- 届け先ＴＥＬ
  gt_upd_balance_acct_cd                     g_balance_acct_cd_ttype;           -- 帳合先コード
  gt_upd_balance_acct_company_cd             g_balance_acct_comp_cd_ttype;      -- 帳合先社コード
  gt_upd_balance_acct_shop_cd                g_balance_acct_shop_cd_ttype;      -- 帳合先店コード
  gt_upd_balance_acct_nm                     g_balance_acct_nm_ttype;           -- 帳合先名（漢字）
  gt_upd_balance_acct_nm_alt                 g_balance_acct_nm_alt_ttype;       -- 帳合先名（カナ）
  gt_upd_balance_acct_addr                   g_balance_acct_address_ttype;      -- 帳合先住所（漢字）
  gt_upd_balance_acct_addr_alt               g_balance_acct_addr_alt_ttype;     -- 帳合先住所（カナ）
  gt_upd_balance_acct_tel                    g_balance_acct_tel_ttype;          -- 帳合先ＴＥＬ
  gt_upd_order_possible_date                 g_order_possible_date_ttype;       -- 受注可能日
  gt_upd_permit_possible_date                g_permit_possible_date_ttype;      -- 許容可能日
  gt_upd_forward_month                       g_forward_month_ttype;             -- 先限年月日
  gt_upd_payment_settlement_date             g_payment_settle_date_ttype;       -- 支払決済日
  gt_upd_handbill_start_date_act             g_handbill_st_date_act_ttype;      -- チラシ開始日
  gt_upd_billing_due_date                    g_billing_due_date_ttype;          -- 請求締日
  gt_upd_shipping_time                       g_shipping_time_ttype;             -- 出荷時刻
  gt_upd_delivery_schedule_time              g_delivery_schedule_time_ttype;    -- 納品予定時間
  gt_upd_order_time                          g_order_time_ttype;                -- 発注時間
  gt_upd_general_date_item1                  g_general_date_item1_ttype;        -- 汎用日付項目１
  gt_upd_general_date_item2                  g_general_date_item2_ttype;        -- 汎用日付項目２
  gt_upd_general_date_item3                  g_general_date_item3_ttype;        -- 汎用日付項目３
  gt_upd_general_date_item4                  g_general_date_item4_ttype;        -- 汎用日付項目４
  gt_upd_general_date_item5                  g_general_date_item5_ttype;        -- 汎用日付項目５
  gt_upd_arrival_shipping_class              g_arrival_shipping_class_ttype;    -- 入出荷区分
  gt_upd_vendor_class                        g_vendor_class_ttype;              -- 取引先区分
  gt_upd_invoice_detailed_class              g_invoice_detailed_class_ttype;    -- 伝票内訳区分
  gt_upd_unit_price_use_class                g_unit_price_use_class_ttype;      -- 単価使用区分
  gt_upd_sub_dist_center_cd                  g_sub_dist_center_cd_ttype;        -- サブ物流センターコード
  gt_upd_sub_dist_center_nm                  g_sub_dist_center_nm_ttype;        -- サブ物流センターコード名
  gt_upd_center_delivery_method              g_center_delivery_method_ttype;    -- センター納品方法
  gt_upd_center_use_class                    g_center_use_class_ttype;          -- センター利用区分
  gt_upd_center_whse_class                   g_center_whse_class_ttype;         -- センター倉庫区分
  gt_upd_center_area_class                   g_center_area_class_ttype;         -- センター地域区分
  gt_upd_center_arrival_class                g_center_arrival_class_ttype;      -- センター入荷区分
  gt_upd_depot_class                         g_depot_class_ttype;               -- デポ区分
  gt_upd_tcdc_class                          g_tcdc_class_ttype;                -- ＴＣＤＣ区分
  gt_upd_upc_flag                            g_upc_flag_ttype;                  -- ＵＰＣフラグ
  gt_upd_simultaneously_class                g_simultaneously_class_ttype;      -- 一斉区分
  gt_upd_business_id                         g_business_id_ttype;               -- 業務ＩＤ
  gt_upd_whse_directly_class                 g_whse_directly_class_ttype;       -- 倉直区分
  gt_upd_premium_rebate_class                g_premium_rebate_class_ttype;      -- 景品割戻区分
  gt_upd_item_type                           g_item_type_ttype;                 -- 項目種別
  gt_upd_cloth_house_food_class              g_cloth_house_food_class_ttype;    -- 衣家食区分
  gt_upd_mix_class                           g_mix_class_ttype;                 -- 混在区分
  gt_upd_stk_class                           g_stk_class_ttype;                 -- 在庫区分
  gt_upd_last_modify_site_class              g_last_modify_site_class_ttype;    -- 最終修正場所区分
  gt_upd_report_class                        g_report_class_ttype;              -- 帳票区分
  gt_upd_addition_plan_class                 g_addition_plan_class_ttype;       -- 追加・計画区分
  gt_upd_registration_class                  g_registration_class_ttype;        -- 登録区分
  gt_upd_specific_class                      g_specific_class_ttype;            -- 特定区分
  gt_upd_dealings_class                      g_dealings_class_ttype;            -- 取引区分
  gt_upd_order_class                         g_order_class_ttype;               -- 発注区分
  gt_upd_sum_line_class                      g_sum_line_class_ttype;            -- 集計明細区分
  gt_upd_shipping_guidance_class             g_shipping_guide_class_ttype;      -- 出荷案内以外区分
  gt_upd_shipping_class                      g_shipping_class_ttype;            -- 出荷区分
  gt_upd_product_code_use_class              g_product_code_use_class_ttype;    -- 商品コード使用区分
  gt_upd_cargo_item_class                    g_cargo_item_class_ttype;          -- 積送品区分
  gt_upd_ta_class                            g_ta_class_ttype;                  -- Ｔ／Ａ区分
  gt_upd_plan_code                           g_plan_code_ttype;                 -- 企画コード
  gt_upd_category_code                       g_category_code_ttype;             -- カテゴリーコード
  gt_upd_category_class                      g_category_class_ttype;            -- カテゴリー区分
  gt_upd_carrier_means                       g_carrier_means_ttype;             -- 運送手段
  gt_upd_counter_code                        g_counter_code_ttype;              -- 売場コード
  gt_upd_move_sign                           g_move_sign_ttype;                 -- 移動サイン
  gt_upd_eos_handwriting_class               g_eos_handwriting_class_ttype;     -- ＥＯＳ・手書区分
  gt_upd_delivery_to_sect_cd                 g_delivery_to_section_cd_ttype;    -- 納品先課コード
  gt_upd_invoice_detailed                    g_invoice_detailed_ttype;          -- 伝票内訳
  gt_upd_attach_qty                          g_attach_qty_ttype;                -- 添付数
  gt_upd_other_party_floor                   g_other_party_floor_ttype;         -- フロア
  gt_upd_text_no                             g_text_no_ttype;                   -- ＴＥＸＴＮｏ
  gt_upd_in_store_code                       g_in_store_code_ttype;             -- インストアコード
  gt_upd_tag_data                            g_tag_data_ttype;                  -- タグ
  gt_upd_competition_code                    g_competition_code_ttype;          -- 競合
  gt_upd_billing_chair                       g_billing_chair_ttype;             -- 請求口座
  gt_upd_chain_store_code                    g_chain_store_code_ttype;          -- チェーンストアーコード
  gt_upd_chain_store_short_name              g_chain_store_short_name_ttype;    -- チェーンストアーコード略式名称
  gt_upd_dirct_delivery_rcpt_fee             g_direct_delive_rcpt_fee_ttype;    -- 直配送／引取料
  gt_upd_bill_info                           g_bill_info_ttype;                 -- 手形情報
  gt_upd_description                         g_description_ttype;               -- 摘要
  gt_upd_interior_code                       g_interior_code_ttype;             -- 内部コード
  gt_upd_order_info_delivery_cat             g_order_info_delive_cat_ttype;     -- 発注情報　納品カテゴリー
  gt_upd_purchase_type                       g_purchase_type_ttype;             -- 仕入形態
  gt_upd_delivery_to_name_alt                g_delivery_to_name_alt_ttype;      -- 納品場所名（カナ）
  gt_upd_shop_opened_site                    g_shop_opened_site_ttype;          -- 店出場所
  gt_upd_counter_name                        g_counter_name_ttype;              -- 売場名
  gt_upd_extension_number                    g_extension_number_ttype;          -- 内線番号
  gt_upd_charge_name                         g_charge_name_ttype;               -- 担当者名
  gt_upd_price_tag                           g_price_tag_ttype;                 -- 値札
  gt_upd_tax_type                            g_tax_type_ttype;                  -- 税種
  gt_upd_consumption_tax_class               g_consumption_tax_class_ttype;     -- 消費税区分
  gt_upd_brand_class                         g_brand_class_ttype;               -- ＢＲ
  gt_upd_id_code                             g_id_code_ttype;                   -- ＩＤコード
  gt_upd_department_code                     g_department_code_ttype;           -- 百貨店コード
  gt_upd_department_name                     g_department_name_ttype;           -- 百貨店名
  gt_upd_item_type_number                    g_item_type_number_ttype;          -- 品別番号
  gt_upd_description_department              g_description_department_ttype;    -- 摘要（百貨店）
  gt_upd_price_tag_method                    g_price_tag_method_ttype;          -- 値札方法
  gt_upd_reason_column                       g_reason_column_ttype;             -- 自由欄
  gt_upd_a_column_header                     g_a_column_header_ttype;           -- Ａ欄ヘッダ
  gt_upd_d_column_header                     g_d_column_header_ttype;           -- Ｄ欄ヘッダ
  gt_upd_brand_code                          g_brand_code_ttype;                -- ブランドコード
  gt_upd_line_code                           g_line_code_ttype;                 -- ラインコード
  gt_upd_class_code                          g_class_code_ttype;                -- クラスコード
  gt_upd_a1_column                           g_a1_column_ttype;                 -- Ａ－１欄
  gt_upd_b1_column                           g_b1_column_ttype;                 -- Ｂ－１欄
  gt_upd_c1_column                           g_c1_column_ttype;                 -- Ｃ－１欄
  gt_upd_d1_column                           g_d1_column_ttype;                 -- Ｄ－１欄
  gt_upd_e1_column                           g_e1_column_ttype;                 -- Ｅ－１欄
  gt_upd_a2_column                           g_a2_column_ttype;                 -- Ａ－２欄
  gt_upd_b2_column                           g_b2_column_ttype;                 -- Ｂ－２欄
  gt_upd_c2_column                           g_c2_column_ttype;                 -- Ｃ－２欄
  gt_upd_d2_column                           g_d2_column_ttype;                 -- Ｄ－２欄
  gt_upd_e2_column                           g_e2_column_ttype;                 -- Ｅ－２欄
  gt_upd_a3_column                           g_a3_column_ttype;                 -- Ａ－３欄
  gt_upd_b3_column                           g_b3_column_ttype;                 -- Ｂ－３欄
  gt_upd_c3_column                           g_c3_column_ttype;                 -- Ｃ－３欄
  gt_upd_d3_column                           g_d3_column_ttype;                 -- Ｄ－３欄
  gt_upd_e3_column                           g_e3_column_ttype;                 -- Ｅ－３欄
  gt_upd_f1_column                           g_f1_column_ttype;                 -- Ｆ－１欄
  gt_upd_g1_column                           g_g1_column_ttype;                 -- Ｇ－１欄
  gt_upd_h1_column                           g_h1_column_ttype;                 -- Ｈ－１欄
  gt_upd_i1_column                           g_i1_column_ttype;                 -- Ｉ－１欄
  gt_upd_j1_column                           g_j1_column_ttype;                 -- Ｊ－１欄
  gt_upd_k1_column                           g_k1_column_ttype;                 -- Ｋ－１欄
  gt_upd_l1_column                           g_l1_column_ttype;                 -- Ｌ－１欄
  gt_upd_f2_column                           g_f2_column_ttype;                 -- Ｆ－２欄
  gt_upd_g2_column                           g_g2_column_ttype;                 -- Ｇ－２欄
  gt_upd_h2_column                           g_h2_column_ttype;                 -- Ｈ－２欄
  gt_upd_i2_column                           g_i2_column_ttype;                 -- Ｉ－２欄
  gt_upd_j2_column                           g_j2_column_ttype;                 -- Ｊ－２欄
  gt_upd_k2_column                           g_k2_column_ttype;                 -- Ｋ－２欄
  gt_upd_l2_column                           g_l2_column_ttype;                 -- Ｌ－２欄
  gt_upd_f3_column                           g_f3_column_ttype;                 -- Ｆ－３欄
  gt_upd_g3_column                           g_g3_column_ttype;                 -- Ｇ－３欄
  gt_upd_h3_column                           g_h3_column_ttype;                 -- Ｈ－３欄
  gt_upd_i3_column                           g_i3_column_ttype;                 -- Ｉ－３欄
  gt_upd_j3_column                           g_j3_column_ttype;                 -- Ｊ－３欄
  gt_upd_k3_column                           g_k3_column_ttype;                 -- Ｋ－３欄
  gt_upd_l3_column                           g_l3_column_ttype;                 -- Ｌ－３欄
  gt_upd_chain_pecul_area_head               g_chain_pecul_area_head_ttype;     -- チェーン店固有エリア（ヘッダー）
  gt_upd_order_connection_num                g_order_connection_num_ttype;      -- 受注関連番号
  gt_upd_inv_indv_order_qty                  g_inv_indv_order_qty_ttype;        -- （伝票計）発注数量（バラ）
  gt_upd_inv_case_order_qty                  g_inv_case_order_qty_ttype;        -- （伝票計）発注数量（ケース）
  gt_upd_inv_ball_order_qty                  g_inv_ball_order_qty_ttype;        -- （伝票計）発注数量（ボール）
  gt_upd_inv_sum_order_qty                   g_inv_sum_order_qty_ttype;         -- （伝票計）発注数量（合計、バラ）
  gt_upd_inv_indv_shipping_qty               g_inv_indv_shipping_qty_ttype;     -- （伝票計）出荷数量（バラ）
  gt_upd_inv_case_shipping_qty               g_inv_case_shipping_qty_ttype;     -- （伝票計）出荷数量（ケース）
  gt_upd_inv_ball_shipping_qty               g_inv_ball_shipping_qty_ttype;     -- （伝票計）出荷数量（ボール）
  gt_upd_inv_pallet_shipping_qty             g_inv_plt_shipping_qty_ttype;      -- （伝票計）出荷数量（パレット）
  gt_upd_inv_sum_shipping_qty                g_inv_sum_shipping_qty_ttype;      -- （伝票計）出荷数量（合計、バラ）
  gt_upd_inv_indv_stockout_qty               g_inv_indv_stockout_qty_ttype;     -- （伝票計）欠品数量（バラ）
  gt_upd_inv_case_stockout_qty               g_inv_case_stockout_qty_ttype;     -- （伝票計）欠品数量（ケース）
  gt_upd_inv_ball_stockout_qty               g_inv_ball_stockout_qty_ttype;     -- （伝票計）欠品数量（ボール）
  gt_upd_inv_sum_stockout_qty                g_inv_sum_stockout_qty_ttype;      -- （伝票計）欠品数量（合計、バラ）
  gt_upd_inv_case_qty                        g_inv_case_qty_ttype;              -- （伝票計）ケース個口数
  gt_upd_inv_fold_container_qty              g_inv_fold_container_qty_ttype;    -- （伝票計）オリコン（バラ）個口数
  gt_upd_inv_order_cost_amt                  g_inv_order_cost_amt_ttype;        -- （伝票計）原価金額（発注）
  gt_upd_inv_shipping_cost_amt               g_inv_shipping_cost_amt_ttype;     -- （伝票計）原価金額（出荷）
  gt_upd_inv_stockout_cost_amt               g_inv_stockout_cost_amt_ttype;     -- （伝票計）原価金額（欠品）
  gt_upd_inv_order_price_amt                 g_inv_order_price_amt_ttype;       -- （伝票計）売価金額（発注）
  gt_upd_inv_shipping_price_amt              g_inv_shipping_price_amt_ttype;    -- （伝票計）売価金額（出荷）
  gt_upd_inv_stockout_price_amt              g_inv_stockout_price_amt_ttype;    -- （伝票計）売価金額（欠品）
  gt_upd_total_indv_order_qty                g_total_indv_order_qty_ttype;      -- （総合計）発注数量（バラ）
  gt_upd_total_case_order_qty                g_total_case_order_qty_ttype;      -- （総合計）発注数量（ケース）
  gt_upd_total_ball_order_qty                g_total_ball_order_qty_ttype;      -- （総合計）発注数量（ボール）
  gt_upd_total_sum_order_qty                 g_total_sum_order_qty_ttype;       -- （総合計）発注数量（合計、バラ）
  gt_upd_total_indv_ship_qty                 g_total_indv_ship_qty_ttype;       -- （総合計）出荷数量（バラ）
  gt_upd_total_case_ship_qty                 g_total_case_ship_qty_ttype;       -- （総合計）出荷数量（ケース）
  gt_upd_total_ball_ship_qty                 g_total_ball_ship_qty_ttype;       -- （総合計）出荷数量（ボール）
  gt_upd_total_pallet_ship_qty               g_total_pallet_ship_qty_ttype;     -- （総合計）出荷数量（パレット）
  gt_upd_total_sum_ship_qty                  g_total_sum_ship_qty_ttype;        -- （総合計）出荷数量（合計、バラ）
  gt_upd_total_indv_stockout_qty             g_total_indv_stkout_qty_ttype;     -- （総合計）欠品数量（バラ）
  gt_upd_total_case_stockout_qty             g_total_case_stkout_qty_ttype;     -- （総合計）欠品数量（ケース）
  gt_upd_total_ball_stockout_qty             g_total_ball_stkout_qty_ttype;     -- （総合計）欠品数量（ボール）
  gt_upd_total_sum_stockout_qty              g_total_sum_stkout_qty_ttype;      -- （総合計）欠品数量（合計、バラ）
  gt_upd_total_case_qty                      g_total_case_qty_ttype;            -- （総合計）ケース個口数
  gt_upd_total_fold_contain_qty              g_total_fold_contain_qty_ttype;    -- （総合計）オリコン（バラ）個口数
  gt_upd_total_order_cost_amt                g_total_order_cost_amt_ttype;      -- （総合計）原価金額（発注）
  gt_upd_total_shipping_cost_amt             g_total_ship_cost_amt_ttype;       -- （総合計）原価金額（出荷）
  gt_upd_total_stockout_cost_amt             g_total_stkout_cost_amt_ttype;     -- （総合計）原価金額（欠品）
  gt_upd_total_order_price_amt               g_total_order_price_amt_ttype;     -- （総合計）売価金額（発注）
  gt_upd_total_ship_price_amt                g_total_ship_price_amt_ttype;      -- （総合計）売価金額（出荷）
  gt_upd_total_stock_price_amt               g_total_stock_price_amt_ttype;     -- （総合計）売価金額（欠品）
  gt_upd_total_line_qty                      g_total_line_qty_ttype;            -- トータル行数
  gt_upd_total_invoice_qty                   g_total_invoice_qty_ttype;         -- トータル伝票枚数
  gt_upd_chain_pecul_area_foot               g_chain_pecul_area_foot_ttype;     -- チェーン店固有エリア（フッター）
  gt_upd_conv_customer_code                  g_conv_customer_code_ttype;        -- 変換後顧客コード
  gt_upd_order_forward_flag                  g_order_forward_flag_ttype;        -- 受注連携済フラグ
  gt_upd_creation_class                      g_creation_class_ttype;            -- 作成元区分
  gt_upd_edi_delivery_sche_flag              g_edi_delivery_sche_flag_ttype;    -- EDI納品予定送信済フラグ
  gt_upd_price_list_header_id                g_price_list_header_id_ttype;      -- 価格表ヘッダID
-- 2009/12/28 M.Sano Ver.1.14 add Start
  gt_upd_tsukagatazaiko_div                  g_tsukagatazaiko_div_ttype;        -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  --  EDI明細情報インサート用変数
  gt_edi_lines                               g_edi_lines_ttype;                 -- EDI明細情報テーブル
--
  -- EDI明細情報アップデート用変数
  gt_upd_edi_line_info_id                    g_edi_line_info_id_ttype;          -- EDI明細情報ID
  gt_upd_edi_line_header_info_id             g_edi_line_head_info_id_ttype;     -- EDIヘッダ情報ID
  gt_upd_line_no                             g_line_no_ttype;                   -- 行Ｎｏ
  gt_upd_stockout_class                      g_stockout_class_ttype;            -- 欠品区分
  gt_upd_stockout_reason                     g_stockout_reason_ttype;           -- 欠品理由
  gt_upd_product_code_itouen                 g_product_code_itouen_ttype;       -- 商品コード（伊藤園）
  gt_upd_product_code1                       g_product_code1_ttype;             -- 商品コード１
  gt_upd_product_code2                       g_product_code2_ttype;             -- 商品コード２
  gt_upd_jan_code                            g_jan_code_ttype;                  -- ＪＡＮコード
  gt_upd_itf_code                            g_itf_code_ttype;                  -- ＩＴＦコード
  gt_upd_extension_itf_code                  g_extension_itf_code_ttype;        -- 内箱ＩＴＦコード
  gt_upd_case_product_code                   g_case_product_code_ttype;         -- ケース商品コード
  gt_upd_ball_product_code                   g_ball_product_code_ttype;         -- ボール商品コード
  gt_upd_product_code_item_type              g_product_code_item_type_ttype;    -- 商品コード品種
  gt_upd_prod_class                          g_prod_class_ttype;                -- 商品区分
  gt_upd_product_name                        g_product_name_ttype;              -- 商品名（漢字）
  gt_upd_product_name1_alt                   g_product_name1_alt_ttype;         -- 商品名１（カナ）
  gt_upd_product_name2_alt                   g_product_name2_alt_ttype;         -- 商品名２（カナ）
  gt_upd_item_standard1                      g_item_standard1_ttype;            -- 規格１
  gt_upd_item_standard2                      g_item_standard2_ttype;            -- 規格２
  gt_upd_qty_in_case                         g_qty_in_case_ttype;               -- 入数
  gt_upd_num_of_cases                        g_num_of_cases_ttype;              -- ケース入数
  gt_upd_num_of_ball                         g_num_of_ball_ttype;               -- ボール入数
  gt_upd_item_color                          g_item_color_ttype;                -- 色
  gt_upd_item_size                           g_item_size_ttype;                 -- サイズ
  gt_upd_expiration_date                     g_expiration_date_ttype;           -- 賞味期限日
  gt_upd_product_date                        g_product_date_ttype;              -- 製造日
  gt_upd_order_uom_qty                       g_order_uom_qty_ttype;             -- 発注単位数
  gt_upd_shipping_uom_qty                    g_shipping_uom_qty_ttype;          -- 出荷単位数
  gt_upd_packing_uom_qty                     g_packing_uom_qty_ttype;           -- 梱包単位数
  gt_upd_deal_code                           g_deal_code_ttype;                 -- 引合
  gt_upd_deal_class                          g_deal_class_ttype;                -- 引合区分
  gt_upd_collation_code                      g_collation_code_ttype;            -- 照合
  gt_upd_uom_code                            g_uom_code_ttype;                  -- 単位
  gt_upd_unit_price_class                    g_unit_price_class_ttype;          -- 単価区分
  gt_upd_parent_packing_number               g_parent_packing_number_ttype;     -- 親梱包番号
  gt_upd_packing_number                      g_packing_number_ttype;            -- 梱包番号
  gt_upd_product_group_code                  g_product_group_code_ttype;        -- 商品群コード
  gt_upd_case_dismantle_flag                 g_case_dismantle_flag_ttype;       -- ケース解体不可フラグ
  gt_upd_case_class                          g_case_class_ttype;                -- ケース区分
  gt_upd_indv_order_qty                      g_indv_order_qty_ttype;            -- 発注数量（バラ）
  gt_upd_case_order_qty                      g_case_order_qty_ttype;            -- 発注数量（ケース）
  gt_upd_ball_order_qty                      g_ball_order_qty_ttype;            -- 発注数量（ボール）
  gt_upd_sum_order_qty                       g_sum_order_qty_ttype;             -- 発注数量（合計、バラ）
  gt_upd_indv_shipping_qty                   g_indv_shipping_qty_ttype;         -- 出荷数量（バラ）
  gt_upd_case_shipping_qty                   g_case_shipping_qty_ttype;         -- 出荷数量（ケース）
  gt_upd_ball_shipping_qty                   g_ball_shipping_qty_ttype;         -- 出荷数量（ボール）
  gt_upd_pallet_shipping_qty                 g_pallet_shipping_qty_ttype;       -- 出荷数量（パレット）
  gt_upd_sum_shipping_qty                    g_sum_shipping_qty_ttype;          -- 出荷数量（合計、バラ）
  gt_upd_indv_stockout_qty                   g_indv_stockout_qty_ttype;         -- 欠品数量（バラ）
  gt_upd_case_stockout_qty                   g_case_stockout_qty_ttype;         -- 欠品数量（ケース）
  gt_upd_ball_stockout_qty                   g_ball_stockout_qty_ttype;         -- 欠品数量（ボール）
  gt_upd_sum_stockout_qty                    g_sum_stockout_qty_ttype;          -- 欠品数量（合計、バラ）
  gt_upd_case_qty                            g_case_qty_ttype;                  -- ケース個口数
  gt_upd_fold_container_indv_qty             g_fold_contain_indv_qty_ttype;     -- オリコン（バラ）個口数
  gt_upd_order_unit_price                    g_order_unit_price_ttype;          -- 原単価（発注）
  gt_upd_shipping_unit_price                 g_shipping_unit_price_ttype;       -- 原単価（出荷）
  gt_upd_order_cost_amt                      g_order_cost_amt_ttype;            -- 原価金額（発注）
  gt_upd_shipping_cost_amt                   g_shipping_cost_amt_ttype;         -- 原価金額（出荷）
  gt_upd_stockout_cost_amt                   g_stockout_cost_amt_ttype;         -- 原価金額（欠品）
  gt_upd_selling_price                       g_selling_price_ttype;             -- 売単価
  gt_upd_order_price_amt                     g_order_price_amt_ttype;           -- 売価金額（発注）
  gt_upd_shipping_price_amt                  g_shipping_price_amt_ttype;        -- 売価金額（出荷）
  gt_upd_stockout_price_amt                  g_stockout_price_amt_ttype;        -- 売価金額（欠品）
  gt_upd_a_column_department                 g_a_column_department_ttype;       -- Ａ欄（百貨店）
  gt_upd_d_column_department                 g_d_column_department_ttype;       -- Ｄ欄（百貨店）
  gt_upd_standard_info_depth                 g_standard_info_depth_ttype;       -- 規格情報・奥行き
  gt_upd_standard_info_height                g_standard_info_height_ttype;      -- 規格情報・高さ
  gt_upd_standard_info_width                 g_standard_info_width_ttype;       -- 規格情報・幅
  gt_upd_standard_info_weight                g_standard_info_weight_ttype;      -- 規格情報・重量
  gt_upd_general_succeed_item1               g_general_succeed_item1_ttype;     -- 汎用引継ぎ項目１
  gt_upd_general_succeed_item2               g_general_succeed_item2_ttype;     -- 汎用引継ぎ項目２
  gt_upd_general_succeed_item3               g_general_succeed_item3_ttype;     -- 汎用引継ぎ項目３
  gt_upd_general_succeed_item4               g_general_succeed_item4_ttype;     -- 汎用引継ぎ項目４
  gt_upd_general_succeed_item5               g_general_succeed_item5_ttype;     -- 汎用引継ぎ項目５
  gt_upd_general_succeed_item6               g_general_succeed_item6_ttype;     -- 汎用引継ぎ項目６
  gt_upd_general_succeed_item7               g_general_succeed_item7_ttype;     -- 汎用引継ぎ項目７
  gt_upd_general_succeed_item8               g_general_succeed_item8_ttype;     -- 汎用引継ぎ項目８
  gt_upd_general_succeed_item9               g_general_succeed_item9_ttype;     -- 汎用引継ぎ項目９
  gt_upd_general_succeed_item10              g_general_succeed_item10_ttype;    -- 汎用引継ぎ項目１０
  gt_upd_general_add_item1                   g_general_add_item1_ttype;         -- 汎用付加項目１
  gt_upd_general_add_item2                   g_general_add_item2_ttype;         -- 汎用付加項目２
  gt_upd_general_add_item3                   g_general_add_item3_ttype;         -- 汎用付加項目３
  gt_upd_general_add_item4                   g_general_add_item4_ttype;         -- 汎用付加項目４
  gt_upd_general_add_item5                   g_general_add_item5_ttype;         -- 汎用付加項目５
  gt_upd_general_add_item6                   g_general_add_item6_ttype;         -- 汎用付加項目６
  gt_upd_general_add_item7                   g_general_add_item7_ttype;         -- 汎用付加項目７
  gt_upd_general_add_item8                   g_general_add_item8_ttype;         -- 汎用付加項目８
  gt_upd_general_add_item9                   g_general_add_item9_ttype;         -- 汎用付加項目９
  gt_upd_general_add_item10                  g_general_add_item10_ttype;        -- 汎用付加項目１０
  gt_upd_chain_pecul_area_line               g_chain_pecul_area_line_ttype;     -- チェーン店固有エリア（明細）
  gt_upd_item_code                           g_item_code_ttype;                 -- 品目コード
  gt_upd_line_uom                            g_line_uom_ttype;                  -- 明細単位
  gt_upd_hht_delivery_sche_flag              g_hht_delivery_sche_flag_ttype;    -- HHT納品予定連携済フラグ
  gt_upd_order_connect_line_num              g_order_connect_line_num_ttype;    -- 受注関連明細番号
--
  -- EDIエラー情報用変数
  gt_edi_errors                              g_edi_errors_ttype;                -- EDIエラー情報テーブル
--
  -- EDI品目エラータイプ変数
  gt_edi_item_err_type                       g_edi_item_err_type_ttype;
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
  -- 通過在庫型区分タイプ変数
  gt_lookup_tsukagata_divs                   g_lookup_tsukagata_div_ttype;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : メッセージ、ログ出力
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
    iv_program      IN  VARCHAR2,            -- プログラム名
    iv_message      IN  VARCHAR2)            -- ユーザー・エラーメッセージ
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ログメッセージ生成
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ログ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_param_check
   * Description      : 入力パラメータ妥当性チェック(A-1)
   ***********************************************************************************/
  PROCEDURE proc_param_check(
-- 2010/01/19 Ver1.15 M.Sano Add Start
--    iv_filename   IN  VARCHAR2,              -- インタフェースファイル名
--    iv_exe_type   IN  VARCHAR2,              -- 実行区分
    iv_filename       IN  VARCHAR2,          -- インタフェースファイル名
    iv_exe_type       IN  VARCHAR2,          -- 実行区分
    iv_edi_chain_code IN  VARCHAR2,          -- EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Add End
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_param_check'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    ln_count   NUMBER(1);       -- レコードカウント
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
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
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- 「パラメータ出力メッセージ」を出力
    --==============================================================
    lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,
                                            cv_msg_param_info,
                                            cv_tkn_param1,
                                            iv_filename,
                                            cv_tkn_param2,
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--                                            iv_exe_type
                                            iv_exe_type,
                                            cv_tkn_param3,
                                            iv_edi_chain_code
-- 2010/01/19 Ver1.15 M.Sano Mod End
                                          );
    lv_errbuf  := lv_errmsg;
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => lv_errbuf
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
--
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    -- インタフェースファイル名が未入力の場合
--    IF ( iv_filename IS NULL ) THEN
    -- IFファイルとEDIチェーン店をどちらか指定する必要がある為、IFファイルとEDIチェーン店の必須チェックを実施
    -- ・ いずれかが設定 ⇒ 後続の処理を実施
    -- ・ 両方ともNULL   ⇒ 必須パラメータ未設定エラー(IFファイル)
    IF ( iv_filename IS NULL AND iv_edi_chain_code IS NULL ) THEN
-- 2010/01/19 Ver1.15 M.Sano Mod End
      -- 必須パラメータ未設定エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_file_name );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_required, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 実行区分パラメータが未入力の場合
    IF ( iv_exe_type IS NULL ) THEN
      -- 必須パラメータ未設定エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_exe );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_required, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- クイックコードから実行区分パラメータを取得
    SELECT  count(*)
    INTO    ln_count
    FROM    fnd_lookup_values           lup_values
    WHERE   lup_values.language         = cv_default_language
    AND     lup_values.enabled_flag     = cv_enabled
    AND     lup_values.lookup_type      = cv_qck_edi_exe
    AND     lup_values.lookup_code      = iv_exe_type
    AND     TRUNC( SYSDATE )
    BETWEEN lup_values.start_date_active
    AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
    -- クイックコードに未登録の場合
    IF ( ln_count = 0 ) THEN
      -- パラメータ不正(パラメータ未登録)エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_exe );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_invalid, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
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
  END proc_param_check;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-2)
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
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- EDI作成元区分カーソル
    CURSOR edi_create_class_cur
    IS
      SELECT  lup_values.meaning        creation_class                -- 作成元区分コード
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_qck_creation_class       -- EDI作成元区分
      AND     lup_values.lookup_code    = cv_creation_class           -- 作成元区分：受注
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
    -- EDI品目エラータイプカーソル
    CURSOR edi_item_err_type_cur
    IS
      SELECT  lup_values.lookup_code    dummy_item_code,              -- ダミー品目コード
              lup_values.attribute1     item_err_type                 -- 品目エラータイプ
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_qck_edi_err_type         -- EDI品目エラータイプ
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
    -- 受注作成対象の通過在庫型区分カーソル
    CURSOR tsukagatazaiko_div_cur
    IS
      SELECT  lup_values.meaning        tsukagatazaiko_div            -- 通過在庫型区分
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_order_class              -- 受注納品確定区分・受注
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
-- 2009/12/28 M.Sano Ver.1.14 add End
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_organization_cd   fnd_profile_option_values.profile_option_value%TYPE := NULL;     -- 在庫組織コード
    lt_create_class_rec  edi_create_class_cur%ROWTYPE;                -- EDI作成元区分カーソル レコード変数
    l_err_type_rec       edi_item_err_type_cur%ROWTYPE;               -- EDI品目エラータイプカーソル レコード変数
-- 2009/12/28 M.Sano Ver.1.14 add Start
    lt_tsukagata_div_rec tsukagatazaiko_div_cur%ROWTYPE;              --受注作成対象の通過在庫型区分カーソル レコード変数
-- 2009/12/28 M.Sano Ver.1.14 add End
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
    -- 変数初期化
    gv_purge_term      := NULL;
    gv_case_uom_code   := NULL;
    gn_organization_id := NULL;
    gn_org_unit_id     := NULL;
    gv_creation_class  := NULL;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:EDI情報削除期間)
    --==============================================================
    gv_purge_term := FND_PROFILE.VALUE( cv_prf_purge_term );
--
    -- プロファイルが取得できなかった場合
    IF ( gv_purge_term IS NULL ) THEN
      -- プロファイル（ケース単位コード）取得エラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge_term );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:ケース単位コード)
    --==============================================================
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom );
--
    -- プロファイルが取得できなかった場合
    IF ( gv_case_uom_code IS NULL ) THEN
      -- プロファイル（ケース単位コード）取得エラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_case_uom_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    lv_organization_cd := FND_PROFILE.VALUE( cv_prf_organization_cd );
--
    -- プロファイルが取得できなかった場合
    IF ( lv_organization_cd IS NULL ) THEN
      -- プロファイル（在庫組織コード）取得エラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_organization_cd );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    IF ( lv_organization_cd IS NOT NULL ) THEN
--
      -- 在庫組織ID取得
      gn_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_cd );
--
      -- 在庫組織IDが取得できなかった場合
      IF ( gn_organization_id IS NULL ) THEN
        -- 在庫組織ID取得エラーを出力
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application_coi, cv_msg_organization_id, cv_tkn_org_code_tok, lv_organization_cd );
        lv_errbuf := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
      END IF;
--
    END IF;
--
    --==============================================================
    -- プロファイルの取得(MO:営業単位)
    --==============================================================
    gn_org_unit_id := FND_PROFILE.VALUE( cv_prf_org_unit );
--
    -- プロファイルが取得できなかった場合
    IF ( gn_org_unit_id IS NULL ) THEN
      -- プロファイル（営業単位）取得エラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_unit );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    --==============================================================
    -- プロファイルの取得(XXCOS:EDIエラー情報削除期間)
    --==============================================================
    gv_err_purge_term := FND_PROFILE.VALUE( cv_prf_err_purge_term );
--
    -- プロファイルが取得できなかった場合
    IF ( gv_err_purge_term IS NULL ) THEN
      -- プロファイル（XXCOS:EDIエラー情報削除期間)取得エラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_purge_term );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
    --==============================================================
    -- EDI作成元区分取得
    --==============================================================
    <<loop_set_creation_class>>
    FOR lt_create_class_rec IN edi_create_class_cur LOOP
      gv_creation_class := lt_create_class_rec.creation_class;
    END LOOP;
--
    -- 作成元区分が取得できなかった場合
    IF ( gv_creation_class IS NULL ) THEN
      -- マスタチェックエラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_creation_class );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst_notfound, cv_tkn_column, lv_tkn1, cv_tkn_table, lv_tkn2 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- EDI品目エラータイプ取得
    --==============================================================
    gt_edi_item_err_type.DELETE;
--
    <<loop_set_edi_err_type>>
    FOR l_err_type_rec IN edi_item_err_type_cur LOOP
      gt_edi_item_err_type(l_err_type_rec.item_err_type) := l_err_type_rec.dummy_item_code;
    END LOOP;
--
    -- EDI品目エラータイプが取得できなかった場合
    IF ( gt_edi_item_err_type.COUNT = 0 ) THEN
      -- マスタチェックエラーを出力
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_err_type );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst_notfound, cv_tkn_column, lv_tkn1, cv_tkn_table, lv_tkn2 );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
-- 2009/12/28 M.Sano Ver.1.14 add Start
--
    --==============================================================
    -- 受注作成対象の通過在庫型区分取得
    --==============================================================
    gt_lookup_tsukagata_divs.DELETE;
--
    <<loop_set_edi_err_type>>
    FOR lt_tsukagata_div_rec IN tsukagatazaiko_div_cur LOOP
      gt_lookup_tsukagata_divs(lt_tsukagata_div_rec.tsukagatazaiko_div) := lt_tsukagata_div_rec.tsukagatazaiko_div;
    END LOOP;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  EXCEPTION
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
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_work
   * Description      : EDI受注情報ワークテーブルデータ抽出(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_work(
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_filename   IN  VARCHAR2,            -- インタフェースファイル名
--    iv_exe_type   IN  VARCHAR2,            -- 実行区分
    iv_filename       IN  VARCHAR2,        -- インタフェースファイル名
    iv_exe_type       IN  VARCHAR2,        -- 実行区分
    iv_edi_chain_code IN  VARCHAR2,        -- EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Mod End
    on_target_cnt OUT NOCOPY NUMBER,       -- 対象データ件数
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_status            xxcos_edi_order_work.err_status%TYPE;        -- ステータス
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
    -- OUTパラメータ初期化
    on_target_cnt := 0;
--
    -- 実行区分が「新規」の場合、「新規」データを処理対象とする
    IF ( iv_exe_type = cv_exe_type_new ) THEN
      lv_status := cv_edi_status_new;
--
    -- 実行区分が「再実施」の場合、「警告」データを処理対象とする
    ELSE
      lv_status := cv_edi_status_warning;
--
    END IF;
--
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    -- カーソルオープン
--    OPEN edi_order_work_cur( iv_filename, cv_data_type_code, lv_status );
    -- カーソルオープン
    OPEN edi_order_work_cur( iv_filename, cv_data_type_code, lv_status, iv_edi_chain_code );
-- 2010/01/19 Ver1.15 M.Sano Mod End
    -- バルクフェッチ
    FETCH edi_order_work_cur BULK COLLECT INTO gt_edi_order_work;
    -- 抽出件数セット
    on_target_cnt := edi_order_work_cur%ROWCOUNT;
    -- カーソルクローズ
    CLOSE edi_order_work_cur;
--
    -- 対象データが存在しない場合
    IF ( on_target_cnt = 0 ) THEN
      -- 対象データなしを出力
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    END IF;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- EDI受注情報ワークテーブルロックエラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_order_work_cur%ISOPEN ) THEN
        CLOSE edi_order_work_cur;
      END IF;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- EDI受注情報ワークテーブルデータ抽出エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_getdata, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_order_work_cur%ISOPEN ) THEN
        CLOSE edi_order_work_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_errors
   * Description      : EDIエラー変数格納(A-5-1)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_errors(
    it_edi_work          IN g_edi_work_rtype,     -- EDI受注情報ワークレコード
    iv_dummy_item        IN VARCHAR2,             -- ダミー品目コード
    iv_delete_flag       IN VARCHAR2,             -- 削除フラグ
    iv_message_id        IN VARCHAR2              -- メッセージID
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_errors'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2010/01/19 Ver1.15 M.Sano Add Start
    cv_brank             VARCHAR2(1) := '';
    cv_err_item_yes      VARCHAR2(1) := 'Y';
    cv_err_item_no       VARCHAR2(1) := 'N';
-- 2010/01/19 Ver1.15 M.Sano Add End
--
    -- *** ローカル変数 ***
    ln_idx               NUMBER;
    ln_seq               NUMBER;
-- 2010/01/19 Ver1.15 M.Sano Add Start
    lv_error_type        VARCHAR2(1);
    lv_err_item_flag     VARCHAR2(1);
    lt_err_list_out_flag xxcos_edi_errors.err_list_out_flag%TYPE;
    lt_item_code         ic_item_mst_b.item_no%TYPE;
    lt_item_name         xxcmn_item_mst_b.item_short_name%TYPE;
    ld_delivery_date     DATE;                                    -- 納品予定日
-- 2010/01/19 Ver1.15 M.Sano Add End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    ln_idx := gt_edi_errors.COUNT + 1;
--
    -- EDIエラー情報IDをシーケンスから取得する
    BEGIN
      SELECT  xxcos_edi_errors_s01.NEXTVAL
      INTO    ln_seq
      FROM    dual;
    END;
--
    -- メッセージIDからメッセージを取得
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, iv_message_id );
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- ・行No重複エラーの場合、トークンに行Noを取得する為、再度メッセージを取得
    IF ( iv_message_id = cv_msg_rep_line_no ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                     , iv_message_id
                     , cv_tkn_line_no
                     , it_edi_work.order_connection_line_number
                   );
    END IF;
--
    -- EDIエラー情報の項目算出
    -- ・EDIエラー情報にセットするエラーリスト出力済フラグを取得する。
    --   (新規取込の場合 ⇒ エラーリスト出力済フラグに「N0」）
    --   (再実施の場合   ⇒ エラーリスト出力済フラグに「N1」）
    IF ( it_edi_work.err_status = cv_edi_status_new ) THEN
      lt_err_list_out_flag := cv_err_out_flag_new;
    ELSE
      lt_err_list_out_flag := cv_err_out_flag_retry;
    END IF;
--
    -- ・対象品目がエラー品目かどうか判定する。
    lv_err_item_flag := cv_err_item_no;
    lv_error_type    := gt_edi_item_err_type.FIRST;
    lt_item_code     := NVL(iv_dummy_item, it_edi_work.item_code);
    WHILE ( lv_error_type IS NOT NULL AND lt_item_code IS NOT NULL ) LOOP
      IF ( gt_edi_item_err_type(lv_error_type) = lt_item_code ) THEN
        lv_err_item_flag := cv_err_item_yes;
      END IF;
      lv_error_type := gt_edi_item_err_type.NEXT(lv_error_type);
    END LOOP;
--
    -- ・EDI品目名称を抽出する。
    --   1. エラー品目    で商品名２（カナ）又は、規格2がNULL以外 ⇒ EDI品目名称に「商品名２（カナ） + 規格2」
    IF ( lv_err_item_flag = cv_err_item_yes
      AND ( it_edi_work.product_name2_alt IS NOT NULL OR it_edi_work.item_standard2 IS NOT NULL )
    ) THEN
      lt_item_name := NVL(it_edi_work.product_name2_alt, cv_brank)
                   || NVL(it_edi_work.item_standard2, cv_brank);
    --   2. エラー品目    で商品名１（カナ）又は、規格1がNULL以外 ⇒ EDI品目名称に「商品名１（カナ） + 規格1」
    ELSIF ( lv_err_item_flag = cv_err_item_yes
      AND ( it_edi_work.product_name1_alt IS NOT NULL OR it_edi_work.item_standard1 IS NOT NULL )
    ) THEN
      lt_item_name := NVL(it_edi_work.product_name1_alt, cv_brank)
                   || NVL(it_edi_work.item_standard1, cv_brank);
    --   3. エラー品目以外で品目コードがNULL以外                  ⇒ EDI品目名称に「OPM品目マスタ.品目名称」
    ELSIF ( lv_err_item_flag = cv_err_item_no AND lt_item_code IS NOT NULL  ) THEN
      --[要求日を取得]
      ld_delivery_date := NVL( it_edi_work.shop_delivery_date, 
                            NVL( it_edi_work.center_delivery_date, 
                                 NVL( it_edi_work.order_date, 
                                      it_edi_work.data_creation_date_edi_data
                                    )
                               )
                          );
      --[品目名称を取得]
      BEGIN
        SELECT ximb.item_short_name item_name           -- 品目名称
        INTO   lt_item_name
        FROM   ic_item_mst_b      iimb                  -- OPM品目マスタ
             , xxcmn_item_mst_b   ximb                  -- OPM品目マスタアドオン
        WHERE  iimb.item_no    = lt_item_code
        AND    ximb.item_id    = iimb.item_id
        AND    ld_delivery_date
                 BETWEEN NVL(TRUNC(ximb.start_date_active), ld_delivery_date)
                 AND     NVL(TRUNC(ximb.end_date_active),   ld_delivery_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_item_name := NULL;
      END;
    --   4. 上記以外                                              ⇒ EDI品目名称に「NULL」
    ELSE
      lt_item_name := NULL;
    END IF;
--
    -- EDIエラー情報に作成するデータを作成用配列に格納
-- 2010/01/19 Ver1.15 M.Sano Mod End
    gt_edi_errors(ln_idx).edi_err_id                   := ln_seq;                                        -- EDIエラーID
    gt_edi_errors(ln_idx).edi_create_class             := gv_creation_class;                             -- EDI作成元区分：受注
    gt_edi_errors(ln_idx).chain_code                   := it_edi_work.edi_chain_code;                    -- EDIチェーン店コード
-- 2009/07/16 Ver.1.7 M.Sano Mod Start
--    gt_edi_errors(ln_idx).dlv_date                     := it_edi_work.center_delivery_date;              -- 店舗納品日
    gt_edi_errors(ln_idx).dlv_date                     := it_edi_work.shop_delivery_date;                -- 店舗納品日
-- 2009/07/16 Ver.1.7 M.Sano Mod End
    gt_edi_errors(ln_idx).invoice_number               := it_edi_work.invoice_number;                    -- 伝票番号
    gt_edi_errors(ln_idx).shop_code                    := it_edi_work.shop_code;                         -- 店舗コード
    gt_edi_errors(ln_idx).line_no                      := it_edi_work.line_no;                           -- 行番号
    gt_edi_errors(ln_idx).edi_item_code                := it_edi_work.product_code2;                     -- 商品コード２
    gt_edi_errors(ln_idx).item_code                    := NVL(iv_dummy_item, it_edi_work.item_code);     -- 品目コード
    gt_edi_errors(ln_idx).quantity                     := it_edi_work.sum_order_qty;                     -- 受注数量（合計、バラ）
    gt_edi_errors(ln_idx).unit_price                   := it_edi_work.order_unit_price;                  -- 原単価（発注）
    gt_edi_errors(ln_idx).delete_flag                  := iv_delete_flag;                                -- 削除フラグ
    gt_edi_errors(ln_idx).work_id                      := it_edi_work.order_info_work_id;                -- EDI受注情報ワークID
    gt_edi_errors(ln_idx).status                       := cv_edi_status_warning;                         -- ステータス：警告
    gt_edi_errors(ln_idx).err_message                  := SUBSTRB(lv_errmsg, 1, 40);                     -- エラーメッセージ（40ﾊﾞｲﾄ分）
-- 2010/01/19 Ver1.15 M.Sano Add Start
    gt_edi_errors(ln_idx).err_message_code             := iv_message_id;                                 -- メッセージID
    gt_edi_errors(ln_idx).edi_received_date            := it_edi_work.creation_date;                     -- EDI受信日
    gt_edi_errors(ln_idx).err_list_out_flag            := lt_err_list_out_flag;                          -- 受注エラーリスト出力済フラグ
    gt_edi_errors(ln_idx).edi_item_name                := SUBSTRB(lt_item_name, 1, 20);                  -- EDI品目名称
-- 2010/01/19 Ver1.15 M.Sano Add End
    gt_edi_errors(ln_idx).created_by                   := cn_created_by;                                 -- 作成者
    gt_edi_errors(ln_idx).creation_date                := cd_creation_date;                              -- 作成日
    gt_edi_errors(ln_idx).last_updated_by              := cn_last_updated_by;                            -- 最終更新者
    gt_edi_errors(ln_idx).last_update_date             := cd_last_update_date;                           -- 最終更新日
    gt_edi_errors(ln_idx).last_update_login            := cn_last_update_login;                          -- 最終更新ログイン
    gt_edi_errors(ln_idx).request_id                   := cn_request_id;                                 -- 要求ID
    gt_edi_errors(ln_idx).program_application_id       := cn_program_application_id;                     -- コンカレント・プログラム・アプリケーションID
    gt_edi_errors(ln_idx).program_id                   := cn_program_id;                                 -- コンカレント・プログラムID
    gt_edi_errors(ln_idx).program_update_date          := cd_program_update_date;                        -- プログラム更新日
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
--
--#####################################  固定部 END   ##########################################
  END proc_set_edi_errors;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate
   * Description      : データ妥当性チェック抽出(A-4)
   ***********************************************************************************/
  PROCEDURE proc_data_validate(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル定数 ***
-- 2010/01/19 M.Sano Ver.1.15 add Start
    cv_line_no_dupli_yes   CONSTANT VARCHAR2(1) := 'Y';                         -- 行No重複エラー:Yes
    cv_line_no_dupli_no    CONSTANT VARCHAR2(1) := 'N';                         -- 行No重複エラー:No
-- 2010/01/19 M.Sano Ver.1.15 add End
--
    -- *** ローカル変数 ***
    -- 顧客情報定義
    TYPE l_cust_info_rtype IS RECORD
      (
        conv_cust_code        hz_cust_accounts.account_number%TYPE,             -- 顧客コード
-- 2009/12/28 M.Sano Ver.1.14 add Start
        tsukagatazaiko_div    xxcmm_cust_accounts.tsukagatazaiko_div%TYPE,      -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
        price_list_id         hz_cust_site_uses_all.price_list_id%TYPE          -- 価格表ID
      );
--
    -- 品目情報定義
    TYPE l_item_info_rtype IS RECORD
      (
        item_id               ic_item_mst_b.item_id%TYPE,                       -- 品目ID
        item_no               ic_item_mst_b.item_no%TYPE,                       -- 品名コード
        cust_order_flag       mtl_system_items_b.customer_order_enabled_flag%TYPE,
                                                                                -- 顧客受注可能フラグ
        sales_class           ic_item_mst_b.attribute26%TYPE,                   -- 売上対象区分
        unit                  mtl_system_items_b.primary_unit_of_measure%TYPE,  -- 単位
        unit_price            NUMBER                                            -- 単価
      );
--
    lt_cust_info_rec          l_cust_info_rtype;                                -- 顧客情報変数
    lt_item_info_rec          l_item_info_rtype;                                -- 品目情報変数
    lv_edi_item_code_div      xxcmm_cust_accounts.edi_item_code_div%TYPE;       -- EDI連携品目コード区分
    lv_check_status           xxcos_edi_order_work.err_status%TYPE;             -- EDIエラーステータス
    ln_idx                    NUMBER;
-- 2010/01/19 M.Sano Ver.1.15 add Start
    ln_new_line_no            NUMBER;                                           -- 行No(再採番用)
    lt_salesrep_id            jtf_rs_salesreps.salesrep_id%TYPE;                -- 営業担当ID
-- 2010/01/19 M.Sano Ver.1.15 add End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・プロシジャ ***
--
    -- -------------------------------
    -- 全データのステータスを警告にする
    -- -------------------------------
    PROCEDURE set_check_status_all(
      iv_err_status      IN VARCHAR2
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'set_check_status_all'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ローカル変数 ***
      ln_idx             NUMBER;
    BEGIN
--
      -- 伝票単位の全明細のステータスを設定する
      <<loop_set_edi_status>>
      FOR ln_idx IN 1..gt_edi_work.COUNT LOOP
        -- ステータスを設定
        gt_edi_work(ln_idx).check_status := iv_err_status;
      END LOOP;
--
    EXCEPTION
      -- 例外が発生した場合
      WHEN OTHERS THEN
        NULL;
--
    END;
--
    -- -------------------------------
    -- 必須入力チェック
    -- -------------------------------
    FUNCTION check_required(
      it_edi_work        IN g_edi_work_ttype                -- IN：EDI受注情報ワークデータ
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'check_required'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ローカル変数 ***
      ln_idx             NUMBER;
      ln_result          NUMBER;
    BEGIN
--
      -- リターンコード初期化
      ln_result := 0;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--      -- 店コードが未入力の場合
--      IF ( it_edi_work(it_edi_work.first).shop_code IS NULL ) THEN
      -- 該当レコードがチェック対象、且つ、店コードが未入力の場合
      IF ( (  gn_check_record_flag = cn_check_record_yes )
      AND  ( it_edi_work(it_edi_work.first).shop_code IS NULL ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
        -- 必須項目（店コード）未入力エラーを出力
        lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_shop_code );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- EDIエラー情報追加
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--        proc_set_edi_errors( it_edi_work(it_edi_work.first), NULL, NULL, cv_msg_rep_required );
        proc_set_edi_errors( it_edi_work(it_edi_work.first), NULL, cv_error_delete_flag, cv_msg_rep_no_shop_cd );
-- 2010/01/19 Ver.1.15 M.Sano mod End
        -- エラー設定
        ln_result := 1;
      END IF;
--
      <<loop_check_edi_required>>
      FOR ln_idx IN 1..it_edi_work.COUNT LOOP
--
        -- 行Noが未入力の場合
        IF ( NVL( it_edi_work(ln_idx).line_no, 0 ) = 0 ) THEN
          -- 必須項目（行番号）未入力エラーを出力
          lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_no );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- EDIエラー情報追加
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--          proc_set_edi_errors( it_edi_work(ln_idx), NULL, NULL, cv_msg_rep_required );
          proc_set_edi_errors( it_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_no_line_no );
-- 2010/01/19 Ver.1.15 M.Sano mod End
          -- エラー設定
          ln_result := 1;
        END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        -- 該当レコードがチェック対象、且つ、発注数量（合計、バラ）が未入力の場合
--        IF ( NVL( it_edi_work(ln_idx).sum_order_qty, 0) = 0 ) THEN
        -- 該当レコードがチェック対象、且つ、発注数量（合計、バラ）が未入力の場合
        IF ( ( gn_check_record_flag = cn_check_record_yes )
        AND  ( NVL( it_edi_work(ln_idx).sum_order_qty, 0) = 0 ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
          -- 必須項目（発注数量）未入力エラーを出力
          lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_order_qty );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- EDIエラー情報追加
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--          proc_set_edi_errors( it_edi_work(ln_idx), NULL, NULL, cv_msg_rep_required );
          proc_set_edi_errors( it_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_no_quantity );
-- 2010/01/19 Ver.1.15 M.Sano mod End
          -- エラー設定
          ln_result := 1;
        END IF;
--
      END LOOP;
--
      RETURN ln_result;
--
    EXCEPTION
      -- 例外が発生した場合
      WHEN OTHERS THEN
        RETURN 1;
--
    END;
--
    -- -------------------------------
    -- 顧客情報チェック
    -- -------------------------------
    PROCEDURE customer_conv_check(
      it_edi_work        IN  g_edi_work_rtype,              -- IN：EDI受注情報ワークレコード
      ot_cust_info_rec   OUT NOCOPY l_cust_info_rtype,      -- OUT：顧客情報
      ov_check_status    OUT NOCOPY VARCHAR2                -- OUT：チェックステータス
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'customer_conv_check'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      -- OUTパラメータ(顧客情報)初期化
      ov_check_status                 := cv_edi_status_normal;
      ot_cust_info_rec.conv_cust_code := NULL;
      ot_cust_info_rec.price_list_id  := NULL;
--
      SELECT  accounts.account_number,                                          -- 顧客コード
-- 2009/12/28 M.Sano Ver.1.14 add Start
              addon.tsukagatazaiko_div,                                         -- 通過在庫型区分(EDI)
-- 2009/12/28 M.Sano Ver.1.14 add End
              uses.price_list_id                                                -- 価格表ID
      INTO    ot_cust_info_rec.conv_cust_code,
-- 2009/12/28 M.Sano Ver.1.14 add Start
              ot_cust_info_rec.tsukagatazaiko_div,
-- 2009/12/28 M.Sano Ver.1.14 add End
              ot_cust_info_rec.price_list_id
      FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
              xxcmm_cust_accounts            addon,                             -- 顧客アドオン
              hz_cust_acct_sites_all         sites,                             -- 顧客所在地
              hz_cust_site_uses_all          uses,                              -- 顧客使用目的
              hz_parties                     party                              -- パーティマスタ
      WHERE   accounts.cust_account_id       = sites.cust_account_id
      AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
      AND     accounts.cust_account_id       = addon.customer_id
      AND     accounts.status                = cv_cust_status_active            -- ステータス：A（有効）
      AND     accounts.customer_class_code   = cv_cust_class_cust               -- 顧客区分：10（顧客）
      AND     accounts.party_id              = party.party_id
      AND     party.duns_number_c            IN ( cv_cust_status_30,            -- 顧客ステータス：30（承認済）
                                                  cv_cust_status_40 )           -- 顧客ステータス：40（顧客）
      AND     addon.chain_store_code         = it_edi_work.edi_chain_code       -- EDIチェーン店コード
      AND     addon.store_code               = it_edi_work.shop_code            -- 店コード
      AND     sites.org_id                   = gn_org_unit_id                   -- 営業単位
      AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
      AND     uses.org_id                    = gn_org_unit_id;                  -- 営業単位
--
    EXCEPTION
      -- データが存在しない場合
      WHEN NO_DATA_FOUND THEN
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        -- 顧客コード変換エラーを出力
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
--                                               cv_msg_cust_conv,
--                                               cv_tkn_chain_shop_code,
--                                               it_edi_work.edi_chain_code,
--                                               cv_tkn_shop_code,
--                                               it_edi_work.shop_code
--                                             );
--        lv_errbuf := lv_errmsg;
--        -- ログ出力
--        proc_msg_output( cv_prg_name, lv_errbuf );
--        -- 警告ステータス設定
--        ov_check_status := cv_edi_status_warning;
--        -- EDIエラー情報追加
--        proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
--        -- 伝票エラーフラグ設定
--        gn_invoice_err_flag := 1;
        -- チェック処理対象の場合はエラー
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- 顧客コード変換エラーを出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_cust_conv,
                                                 cv_tkn_chain_shop_code,
                                                 it_edi_work.edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 it_edi_work.shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 警告ステータス設定
          ov_check_status := cv_edi_status_warning;
          -- EDIエラー情報追加
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- 伝票エラーフラグ設定
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
      WHEN TOO_MANY_ROWS THEN
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- 顧客コード変換エラーを出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_many_cust_conv,
                                                 cv_tkn_chain_shop_code,
                                                 it_edi_work.edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 it_edi_work.shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 警告ステータス設定
          ov_check_status := cv_edi_status_warning;
          -- EDIエラー情報追加
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- 伝票エラーフラグ設定
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
      WHEN OTHERS THEN
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- 警告ステータス設定
          ov_check_status := cv_edi_status_warning;
          -- EDIエラー情報追加
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- 伝票エラーフラグ設定
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        -- ログ出力
        proc_msg_output( cv_prg_name, ov_errbuf );
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
--
    END;
--
    -- -------------------------------
    -- EDI連携品目コード区分取得
    -- -------------------------------
    PROCEDURE get_edi_item_code_div(
      iv_edi_chain_code        IN  VARCHAR2,           -- IN：EDIチェーン店コード
      ov_edi_item_code_div     OUT NOCOPY VARCHAR2     -- OUT：EDI連携品目コード区分
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_item_code_div'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
      -- OUTパラメータ初期化
      ov_edi_item_code_div := NULL;
--
      SELECT  addon.edi_item_code_div                                 -- EDI連携品目コード区分
      INTO    ov_edi_item_code_div
      FROM    hz_cust_accounts               accounts,                -- 顧客マスタ
              xxcmm_cust_accounts            addon,                   -- 顧客アドオン
              hz_parties                     party                    -- パーティマスタ
      WHERE   accounts.cust_account_id       = addon.customer_id
      AND     accounts.party_id              = party.party_id
      AND     addon.edi_chain_code           = iv_edi_chain_code      -- EDIチェーン店コード
      AND     accounts.customer_class_code   = cv_cust_class_chain    -- 顧客区分：18(チェーン店)
      AND     accounts.status                = cv_cust_status_active  -- ステータス：A（有効）
      AND     party.duns_number_c            = cv_cust_status_99;     -- 顧客ステータス：99（対象外）
--
    EXCEPTION
      -- データが存在しない場合、呼出元でエラー処理を実施する
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    -- -------------------------------
    -- 営業担当ID取得
    -- -------------------------------
    PROCEDURE get_salesrep_id(
      it_customer_code         IN  hz_cust_accounts.account_number%TYPE, -- IN ：顧客コード
      id_date                  IN  DATE,                                 -- IN ：受注日付
      ot_salesrep_id           OUT jtf_rs_salesreps.salesrep_id%TYPE     -- OUT：営業担当ID
    )
    IS
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_salesrep_id'; -- プログラム名
      
    BEGIN
      SELECT jrs.salesrep_id                                                    -- 営業担当ID
      INTO   ot_salesrep_id
      FROM   hz_cust_accounts          hca                                      -- 顧客マスタ
            ,hz_organization_profiles  hop                                      -- 組織プロファイル
            ,ego_resource_agv          era                                      -- 組織プロファイル拡張
            ,jtf_rs_salesreps          jrs                                      -- 営業担当
      WHERE  hca.account_number          = it_customer_code                     -- [抽出]顧客コード
      AND    hop.party_id                = hca.party_id                         -- [結合]パーティID
      AND    era.organization_profile_id = hop.organization_profile_id          -- [結合]組織プロファイルID
      AND    hop.effective_end_date      IS NULL                                -- [抽出]組織プロファイル.有効終了日：NULL
      AND    jrs.salesrep_number         = era.resource_no                      -- [結合]営業担当No
      AND    jrs.org_id                  = gn_org_unit_id                       -- [抽出]営業単位ID
      AND    TRUNC(era.resource_s_date)              <= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(NVL(era.resource_e_date, NVL(id_date, ct_order_date_def) ) )
                                                     >= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(jrs.start_date_active)            <= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(NVL(jrs.end_date_active, NVL(id_date, ct_order_date_def) ) )
                                                     >= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    ROWNUM = 1
      ;
    EXCEPTION
      -- データが存在しない場合、呼出元でエラー処理を実施する
      WHEN NO_DATA_FOUND THEN
        ot_salesrep_id := NULL;
    END;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
    -- -------------------------------
    -- JANコード情報取得
    -- -------------------------------
    FUNCTION get_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      iv_product_code2      IN  VARCHAR2,         -- IN：商品コード２
      it_edi_work           IN  g_edi_work_rtype, -- IN：EDI受注情報ワークレコード
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
      on_item_id            OUT NOCOPY NUMBER,    -- OUT：品目ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT：品目コード
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT：顧客受注可能フラグ
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT：売上対象区分
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT：単位
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_jan_code_item'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      SELECT  disc_item.inventory_item_id,                       -- 品目ID
--              opm_item.item_no,                                  -- 品名コード
--              disc_item.customer_order_enabled_flag,             -- 顧客受注可能フラグ
--              opm_item.attribute26,                              -- 売上対象区分
--              disc_item.primary_unit_of_measure                  -- 単位
--      INTO    on_item_id,
--              ov_item_code,
--              ov_cust_order_flag,
--              ov_sales_class,
--              ov_unit
--      FROM    ic_item_mst_b             opm_item,                -- ＯＰＭ品目
--              mtl_system_items_b        disc_item                -- Disc品目
--      WHERE   opm_item.attribute21      = iv_product_code2       -- 商品コード２
--      AND     opm_item.item_no          = disc_item.segment1     -- 品目コード
--      AND     disc_item.organization_id = gn_organization_id;    -- 在庫組織ID
--
      SELECT ims.inventory_item_id,
             ims.item_no,
             ims.customer_order_enabled_flag,
             ims.attribute26,
             ims.primary_unit_of_measure
        INTO on_item_id,
             ov_item_code,
             ov_cust_order_flag,
             ov_sales_class,
             ov_unit
        FROM (
              SELECT msi.inventory_item_id           inventory_item_id,           --品目ID
                     iim.item_no                     item_no,                     --品名コード
                     msi.customer_order_enabled_flag customer_order_enabled_flag, --顧客受注可能フラグ
                     iim.attribute26                 attribute26,                 --売上対象区分
                     msi.primary_unit_of_measure     primary_unit_of_measure      --単位
                FROM ic_item_mst_b                   iim,                         --OPM品目
                     xxcmn_item_mst_b                xim,                         --OPM品目アドオン
                     mtl_system_items_b              msi                          --Disc品目
               WHERE iim.attribute21      = it_edi_work.product_code2             --商品コード２
                 AND iim.item_no          = msi.segment1                          --品目コード
                 AND msi.organization_id  = gn_organization_id                    --在庫組織ID
                 AND xim.item_id          = iim.item_id                           --OPM品目.品目ID        =OPM品目アドオン.品目ID
                 AND xim.item_id          = xim.parent_item_id                    --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
                 --OPM品目マスタ.発売（製造）開始日.(ATTRIBUTE13) <= 
                 --NVL( 店舗納品日, NVL( センター納品日, NVL( 発注日, データ作成日（EDIデータ中）) ) )
                 AND TO_DATE(iim.attribute13,cv_format_yyyymmdds) <=
                                                NVL( it_edi_work.shop_delivery_date, 
                                                     NVL( it_edi_work.center_delivery_date, 
                                                          NVL( it_edi_work.order_date, 
                                                               it_edi_work.data_creation_date_edi_data
                                                             )
                                                        )
                                                   )
              ORDER BY iim.attribute13 DESC
             ) ims
       WHERE ROWNUM  = 1
       ;
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  固定例外処理部 START   ####################################
--
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** 共通関数OTHERS例外ハンドラ ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ログ出力
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  固定部 END   ##########################################
    END;
--
    -- -------------------------------
    -- ケースJANコード情報取得
    -- -------------------------------
    FUNCTION get_case_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      iv_product_code2      IN  VARCHAR2,         -- IN：商品コード２
      it_edi_work           IN  g_edi_work_rtype, -- IN：EDI受注情報ワークレコード
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
      on_item_id            OUT NOCOPY NUMBER,    -- OUT：品目ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT：品目コード
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT：顧客受注可能フラグ
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT：売上対象区分
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT：単位
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_case_jan_code_item'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      SELECT  disc_item.inventory_item_id,                       -- 品目ID
--              opm_item.item_no,                                  -- 品名コード
--              disc_item.customer_order_enabled_flag,             -- 顧客受注可能フラグ
--              opm_item.attribute26,                              -- 売上対象区分
--              gv_case_uom_code                                   -- 単位
--      INTO    on_item_id,
--              ov_item_code,
--              ov_cust_order_flag,
--              ov_sales_class,
--              ov_unit
--      FROM    ic_item_mst_b             opm_item,                -- ＯＰＭ品目
--              mtl_system_items_b        disc_item,               -- Disc品目
--              xxcmm_system_items_b      item_addon               -- Disc品目アドオン
--      WHERE   item_addon.case_jan_code  = iv_product_code2       -- 商品コード２
--      AND     item_addon.item_code      = disc_item.segment1
--      AND     disc_item.segment1        = opm_item.item_no
--      AND     disc_item.organization_id = gn_organization_id;
--
      SELECT ims.inventory_item_id,
             ims.item_no,
             ims.customer_order_enabled_flag,
             ims.attribute26,
             gv_case_uom_code                                                     --単位
        INTO on_item_id,
             ov_item_code,
             ov_cust_order_flag,
             ov_sales_class,
             ov_unit
        FROM (
              SELECT msi.inventory_item_id           inventory_item_id,           --品目ID
                     iim.item_no                     item_no,                     --品名コード
                     msi.customer_order_enabled_flag customer_order_enabled_flag, --顧客受注可能フラグ
                     iim.attribute26                 attribute26                  --売上対象区分
                FROM ic_item_mst_b                   iim,                         --OPM品目
                     xxcmn_item_mst_b                xim,                         --OPM品目アドオン
                     mtl_system_items_b              msi,                         --Disc品目
                     xxcmm_system_items_b            xsi                          --Disc品目アドオン
               WHERE xsi.case_jan_code    = it_edi_work.product_code2             --商品コード２
                 AND xsi.item_code        = msi.segment1
                 AND msi.segment1         = iim.item_no
                 AND msi.organization_id  = gn_organization_id
                 AND xim.item_id          = iim.item_id                           --OPM品目.品目ID        =OPM品目アドオン.品目ID
                 AND xim.item_id          = xim.parent_item_id                    --OPM品目アドオン.品目ID=OPM品目アドオン.親品目ID
                 --OPM品目マスタ.発売（製造）開始日.(ATTRIBUTE13) <= 
                 --NVL( 店舗納品日, NVL( センター納品日, NVL( 発注日, データ作成日（EDIデータ中）) ) )
                 AND TO_DATE(iim.attribute13,cv_format_yyyymmdds) <=
                                                NVL( it_edi_work.shop_delivery_date, 
                                                     NVL( it_edi_work.center_delivery_date, 
                                                          NVL( it_edi_work.order_date, 
                                                               it_edi_work.data_creation_date_edi_data
                                                             )
                                                        )
                                                   )
              ORDER BY iim.attribute13 DESC
            ) ims
       WHERE ROWNUM  = 1
       ;
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  固定例外処理部 START   ####################################
--
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** 共通関数OTHERS例外ハンドラ ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ログ出力
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  固定部 END   ##########################################
    END;
--
    -- -------------------------------
    -- 顧客品目情報取得
    -- -------------------------------
    FUNCTION get_cust_item(
      iv_edi_chain_code     IN  VARCHAR2,         -- IN：EDIチェーン店コード
      iv_product_code2      IN  VARCHAR2,         -- IN：商品コード２
      on_item_id            OUT NOCOPY NUMBER,    -- OUT：品目ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT：品目コード
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT：顧客受注可能フラグ
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT：売上対象区分
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT：単位
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_item'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      SELECT  cust_xref.inventory_item_id,                       -- 品目ID
              opm_item.item_no,                                  -- 品名コード
              disc_item.customer_order_enabled_flag,             -- 顧客受注可能フラグ
              opm_item.attribute26,                              -- 売上対象区分
              cust_item.attribute1                               -- 単位
      INTO    on_item_id,
              ov_item_code,
              ov_cust_order_flag,
              ov_sales_class,
              ov_unit
      FROM    mtl_customer_items        cust_item,               -- 顧客品目
              mtl_customer_item_xrefs   cust_xref,               -- 顧客品目相互参照
              hz_cust_accounts          cust_chain_shop,         -- EDIチェーン店マスタ
              xxcmm_cust_accounts       cust_chain_addon,        -- 顧客追加情報
              hz_parties                cust_chain_party,        -- パーティマスタ
              ic_item_mst_b             opm_item,                -- ＯＰＭ品目
              mtl_system_items_b        disc_item,               -- Disc品目
              mtl_parameters            params                   -- パラメータ
      WHERE   cust_item.customer_item_id          = cust_xref.customer_item_id
      AND     cust_item.customer_id               = cust_chain_shop.cust_account_id
      AND     cust_chain_addon.edi_chain_code     = iv_edi_chain_code
      AND     cust_chain_shop.cust_account_id     = cust_chain_addon.customer_id
      AND     cust_chain_shop.party_id            = cust_chain_party.party_id
      AND     cust_chain_shop.customer_class_code = cv_cust_class_chain              -- 顧客区分：18(チェーン店)
      AND     cust_chain_party.duns_number_c      = cv_cust_status_99                -- 顧客ステータス：99（対象外）
      AND     cust_xref.inventory_item_id         = disc_item.inventory_item_id
      AND     params.organization_id              = gn_organization_id               -- 在庫組織ID
      AND     cust_xref.master_organization_id    = params.master_organization_id    -- マスタ組織ID
-- 2009/10/02 M.Sano Ver.1.10 add Start
      AND     cust_xref.inactive_flag             = cv_inactive_flag_no              -- 有効フラグ：N
      AND     cust_xref.preference_number         = (
                SELECT MIN(cust_xref_ck.preference_number)
                FROM   mtl_customer_item_xrefs  cust_xref_ck
                WHERE  cust_xref_ck.customer_item_id       = cust_xref.customer_item_id
                AND    cust_xref_ck.master_organization_id = cust_xref.master_organization_id
                AND    cust_xref_ck.inactive_flag          = cv_inactive_flag_no
              )                                                                      -- 最小のランク
      AND     cust_item.inactive_flag             = cv_inactive_flag_no              -- 有効フラグ：N
-- 2009/10/02 M.Sano Ver.1.10 add End
      AND     cust_item.customer_item_number      = iv_product_code2                 -- 商品コード２
      AND     cust_item.item_definition_level     = cv_cust_item_def_level           -- 定義レベル
      AND     disc_item.segment1                  = opm_item.item_no                 -- 品目コード
      AND     disc_item.organization_id           = gn_organization_id;              -- 在庫組織ID
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  固定例外処理部 START   ####################################
--
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** 共通関数OTHERS例外ハンドラ ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ログ出力
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  固定部 END   ##########################################
    END;
--
    -- -------------------------------
    -- DISC品目情報取得
    -- -------------------------------
    PROCEDURE get_disc_item_info(
      iv_item_no            IN  VARCHAR2,         -- IN：品目コード
      on_item_id            OUT NOCOPY NUMBER,    -- OUT：品目ID
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT：単位
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disc_item_info'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      SELECT  disc_item.inventory_item_id,                       -- 品目ID
              disc_item.primary_unit_of_measure                  -- 単位
      INTO    on_item_id,
              ov_unit
      FROM    mtl_system_items_b        disc_item                -- Disc品目
      WHERE   disc_item.segment1        = iv_item_no             -- 品目コード
      AND     disc_item.organization_id = gn_organization_id;    -- 在庫組織ID
--
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
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
        -- ログ出力
        proc_msg_output( cv_prg_name, ov_errbuf );
--
--#####################################  固定部 END   ##########################################
    END;
--
    -- -------------------------------
    -- 品目情報チェック
    -- -------------------------------
    PROCEDURE item_code_check(
      iv_edi_item_code_div    IN  VARCHAR2,                      -- IN：EDI連携品目コード区分
      it_edi_work             IN  g_edi_work_rtype,              -- IN：EDI受注情報ワークレコード
      ot_item_info_rec        OUT NOCOPY l_item_info_rtype,      -- OUT：品目情報
      ov_check_status         OUT NOCOPY VARCHAR2                -- OUT：チェックステータス
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- 固定ローカル定数
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'item_code_check'; -- プログラム名
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ローカル変数 ***
      lv_error_type           VARCHAR2(1);
      lv_msg_prod_type        VARCHAR2(50);
      lv_dummy_item           xxcos_edi_lines.item_code%TYPE;
      ln_rowcount             NUMBER := 0;
--
    BEGIN
--
      -- OUTパラメータ(品目情報)初期化
      ov_check_status                  := cv_edi_status_normal;
      ot_item_info_rec.item_id         := 0;
      ot_item_info_rec.item_no         := NULL;
      ot_item_info_rec.cust_order_flag := NULL;
      ot_item_info_rec.sales_class     := NULL;
      ot_item_info_rec.unit            := NULL;
      ot_item_info_rec.unit_price      := 0;
--
      -- EDI連携品目コード区分が「JANコード」の場合
      IF ( iv_edi_item_code_div = cv_item_code_div_jan ) THEN
--
        -- 品目タイプ：JANコード
        lv_msg_prod_type := cv_msg_prod_type_jan;
--
        -- JANコード情報取得
        ln_rowcount := get_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--                         it_edi_work.product_code2,
                         it_edi_work,
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
                         ot_item_info_rec.item_id,
                         ot_item_info_rec.item_no,
                         ot_item_info_rec.cust_order_flag,
                         ot_item_info_rec.sales_class,
                         ot_item_info_rec.unit
                       );
--
        -- データが取得できなかった場合
        IF ( ln_rowcount = 0 ) THEN
--
          -- ケースJANコード情報取得
          ln_rowcount := get_case_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--                           it_edi_work.product_code2,
                           it_edi_work,
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
                           ot_item_info_rec.item_id,
                           ot_item_info_rec.item_no,
                           ot_item_info_rec.cust_order_flag,
                           ot_item_info_rec.sales_class,
                           ot_item_info_rec.unit
                         );
--
        END IF;
--
      -- EDI連携品目コード区分が「顧客品目」の場合
      ELSIF ( iv_edi_item_code_div = cv_item_code_div_cust ) THEN
--
        -- 品目タイプ：顧客品目
        lv_msg_prod_type := cv_msg_prod_type_cust;
--
        -- 顧客品目情報取得
        ln_rowcount := get_cust_item(
                         it_edi_work.edi_chain_code,
                         it_edi_work.product_code2,
                         ot_item_info_rec.item_id,
                         ot_item_info_rec.item_no,
                         ot_item_info_rec.cust_order_flag,
                         ot_item_info_rec.sales_class,
                         ot_item_info_rec.unit
                       );
--
      END IF;
--
      -- EDIダミー品目、EDI品目エラータイプを初期化
      lv_error_type := NULL;
      lv_dummy_item := NULL;
--
      -- 該当データなし
      IF ( ln_rowcount = 0 ) THEN
        -- 品目エラータイプ１を設定
        lv_error_type := cv_error_item_type_1;
--
      -- 顧客受注可能フラグ≠'Y'の場合
      ELSIF (( ot_item_info_rec.cust_order_flag IS NULL )
         OR ( ot_item_info_rec.cust_order_flag != cv_cust_order_flag )) THEN
        -- 品目エラータイプ２を設定
        lv_error_type := cv_error_item_type_2;
--
      -- 売上対象区分≠１の場合
      ELSIF (( ot_item_info_rec.sales_class IS NULL )
         OR ( ot_item_info_rec.sales_class != cv_sales_class )) THEN
        -- 品目エラータイプ３を設定
        lv_error_type := cv_error_item_type_3;
--
      END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--      -- EDI品目エラーの場合
--      IF ( lv_error_type IS NOT NULL ) THEN
      -- チェック処理有りでEDI品目エラーの場合、エラー処理を行なう。
      IF ( ( gn_check_record_flag = cn_check_record_yes )
      AND  ( lv_error_type IS NOT NULL ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
        -- 商品コード変換エラーを出力
        lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, lv_msg_prod_type );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                               cv_msg_item_conv,
                                               cv_tkn_prod_code,
                                               it_edi_work.product_code2,
                                               cv_tkn_prod_type,
                                               lv_tkn1
                                             );
        lv_errbuf := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 警告ステータス設定
        ov_check_status := cv_edi_status_warning;
--
        -- ダミー品目コードを取得
        IF ( gt_edi_item_err_type.EXISTS( lv_error_type ) ) THEN
          lv_dummy_item := gt_edi_item_err_type( lv_error_type );
        END IF;
--
        -- 品目コードにダミー品目を設定する
        ot_item_info_rec.item_no := lv_dummy_item;
--
        -- DISC品目情報を取得
        get_disc_item_info( ot_item_info_rec.item_no,
                            ot_item_info_rec.item_id,
                            ot_item_info_rec.unit );
--
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--        -- EDIエラー情報追加
--        proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_item_conv );
        -- EDIエラー情報追加
        -- ・JANコード ⇒ 「商品コード変換エラー」 顧客品目 ⇒ 「顧客品目変換エラー」
        IF ( iv_edi_item_code_div = cv_item_code_div_jan ) THEN
          proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_item_conv );
        ELSIF ( iv_edi_item_code_div = cv_item_code_div_cust ) THEN
          proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_cust_item );
        END IF;
-- 2010/01/19 Ver.1.15 M.Sano mod End
--
        -- エラー件数インクリメント
        gn_warn_cnt := gn_warn_cnt + 1;
--
      END IF;
--
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
    -- EDI受注情報ワークデータが未設定の場合は処理終了
    IF ( gt_edi_work.COUNT = 0 ) THEN
      RETURN;
    END IF;
--
    -- 正常ステータス設定
    gt_edi_work(gt_edi_work.first).check_status := cv_edi_status_normal;
--
    -- 伝票エラーフラグ初期化
    gn_invoice_err_flag := 0;
-- 2010/01/19 Ver.1.15 M.Sano add Start
    -- 最終行の行Noを取得する。
    ln_new_line_no := gt_edi_work( gt_edi_work.last ).line_no;
-- 2010/01/19 Ver.1.15 M.Sano add End
-- 2009/06/29 M.Sano Ver.1.6 add Start
--
    -- チェック対象の有無を取得する。
    IF ( ( gt_edi_work(gt_edi_work.first).info_class IS NULL )
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_01 )
-- 2010/01/19 Ver.1.15 M.Sano add Start
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_04 )
-- 2010/01/19 Ver.1.15 M.Sano add End
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_02 ) ) THEN
      gn_check_record_flag := cn_check_record_yes;
    ELSE
      gn_check_record_flag := cn_check_record_no;
    END IF;
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
--
    ----------------------------------------
    -- 顧客コード変換チェック
    ----------------------------------------
    -- 店コードがNULL以外の場合
    IF ( gt_edi_work(gt_edi_work.first).shop_code IS NOT NULL ) THEN
      --チェーン店・店コードから顧客情報を取得する。
      customer_conv_check(
        gt_edi_work(gt_edi_work.first),        -- IN：EDI受注情報ワークデータ
        lt_cust_info_rec,                      -- OUT：顧客情報
        lv_check_status                        -- OUT：チェックステータス
      );
--
      -- エラーチェック
      -- ・エラー時、全データのステータスを警告に変更後、チェック処理終了
      IF ( lv_check_status != cv_edi_status_normal ) THEN
        set_check_status_all( lv_check_status );
        ov_retcode := cv_status_warn;
        RETURN;
      END IF;
    END IF;
-- 2010/01/19 Ver.1.15 M.Sano add end
--
    ----------------------------------------
    -- 必須入力チェック
    ----------------------------------------
    IF ( check_required( gt_edi_work )  != 0 ) THEN
      -- 全データに警告ステータスを設定
      set_check_status_all( cv_edi_status_warning );
      -- 伝票エラーフラグ設定
      gn_invoice_err_flag := 1;
      -- チェック処理終了
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano del Start
--    -- 顧客コード変換チェック
--    customer_conv_check(
--      gt_edi_work(gt_edi_work.first),        -- IN：EDI受注情報ワークデータ
--      lt_cust_info_rec,                      -- OUT：顧客情報
--      lv_check_status                        -- OUT：チェックステータス
--    );
----
--    -- ステータスが正常以外は、ステータスを設定
--    IF ( lv_check_status != cv_edi_status_normal ) THEN
--      -- 全データにステータスを設定
--      set_check_status_all( lv_check_status );
--      -- チェック処理終了
--      ov_retcode := cv_status_warn;
--      RETURN;
--    END IF;
-- 2010/01/19 Ver.1.15 M.Sano del end
--
    -- EDI連携品目コード区分を取得
    get_edi_item_code_div(
      gt_edi_work(gt_edi_work.first).edi_chain_code,
      lv_edi_item_code_div
    );
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--    -- EDI連携品目コード区分が「0:なし」の場合
--    IF ( NVL( lv_edi_item_code_div, 0 ) = 0 ) THEN
    -- チェック対象でEDI連携品目コード区分が「0:なし」の場合
    IF ( ( gn_check_record_flag = cn_check_record_yes )
    AND  ( NVL( lv_edi_item_code_div, 0 ) = 0 ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
      -- EDI連携品目コード区分エラーを出力
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_edi_item,
                                             cv_tkn_chain_shop_code,
                                             gt_edi_work(gt_edi_work.first).edi_chain_code
                                           );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- 全データに警告ステータスを設定
      set_check_status_all( cv_edi_status_warning );
      -- EDIエラー情報追加
      proc_set_edi_errors( gt_edi_work(gt_edi_work.first), NULL, NULL, cv_msg_rep_edi_item );
      -- 伝票エラーフラグ設定
      gn_invoice_err_flag := 1;
      -- チェック処理終了
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    ----------------------------------------
    -- 営業担当員存在チェック
    ----------------------------------------
    get_salesrep_id(
      lt_cust_info_rec.conv_cust_code,            -- IN ：顧客コード
      gt_edi_work(gt_edi_work.first).order_date,  -- IN ：受注日
      lt_salesrep_id                              -- OUT：営業担当員ID
    );
    IF ( lt_salesrep_id IS NULL AND gn_check_record_flag = cn_check_record_yes )THEN
      -- 営業担当員取得エラーを出力
      lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                     , cv_msg_salesrep_err
                     , cv_tkn_chain_shop_code
                     , gt_edi_work(gt_edi_work.first).edi_chain_code
                     , cv_tkn_shop_code
                     , gt_edi_work(gt_edi_work.first).shop_code
                     , cv_tkn_cust_code
                     , lt_cust_info_rec.conv_cust_code
                     , cv_tkn_order_no
                     , gt_edi_work(gt_edi_work.first).invoice_number
                     , cv_tkn_store_deliv_dt
                     , TO_CHAR( gt_edi_work(gt_edi_work.first).shop_delivery_date
                              , cv_format_yyyymmdds )
                   );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- 全データに警告ステータスを設定
      set_check_status_all( cv_edi_status_warning );
      -- EDIエラー情報追加
      proc_set_edi_errors( gt_edi_work(gt_edi_work.first), NULL, NULL, cv_msg_rep_salesrep );
      -- 伝票エラーフラグ設定
      gn_invoice_err_flag := 1;
      -- チェック処理終了
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
-- 2010/01/19 Ver.1.15 M.Sano add End
    -- 同一伝票内の全明細のチェック
    <<loop_edi_lines_check>>
    FOR ln_Idx IN 1..gt_edi_work.COUNT LOOP
--
      -- 正常ステータス設定
      gt_edi_work(ln_idx).check_status := cv_edi_status_normal;
--
      ----------------------------------------
      -- 商品コード変換チェック
      ----------------------------------------
      item_code_check(
        lv_edi_item_code_div,                -- IN：EDI連携品目コード区分
        gt_edi_work(ln_idx),                 -- IN：EDI受注情報ワークデータ
        lt_item_info_rec,                    -- OUT：顧客情報
        lv_check_status                      -- OUT：チェックステータス
      );
--
      -- ステータスが正常以外は、ステータスを設定
      IF ( lv_check_status != cv_edi_status_normal ) THEN
        gt_edi_work(ln_idx).check_status := lv_check_status;
      END IF;
--
      -- 品目コードを設定
      gt_edi_work(ln_idx).item_code := lt_item_info_rec.item_no;
--
      -- 明細単位を設定
      gt_edi_work(ln_idx).line_uom := lt_item_info_rec.unit;
--
      -- 変換後顧客コードを設定
      gt_edi_work(ln_idx).conv_customer_code := lt_cust_info_rec.conv_cust_code;
-- 2009/12/28 M.Sano Ver.1.14 add Start
--
      -- 通過在庫型区分を設定
      gt_edi_work(ln_idx).tsukagatazaiko_div := lt_cust_info_rec.tsukagatazaiko_div;
--
      -- 受注連携済フラグを設定
      IF (  gt_lookup_tsukagata_divs.EXISTS(lt_cust_info_rec.tsukagatazaiko_div)
-- 2010/01/19 Ver.1.15 M.Sano add Start
--        AND gn_check_record_flag = cn_check_record_yes
          AND (   gt_edi_work(gt_edi_work.first).info_class IS NULL
               OR gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_01
               OR gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_02 )
-- 2010/01/19 Ver.1.15 M.Sano add End
      ) THEN
        gt_edi_work(gt_edi_work.first).order_forward_flag := cv_order_forward_flag;
      ELSE
        gt_edi_work(gt_edi_work.first).order_forward_flag := cv_order_forward_no;
      END IF;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
      ----------------------------------------
      -- 単価情報を設定
      -- ※原単価（発注）が未設定の場合は、価格表の単価を設定する
      ----------------------------------------
      -- 原単価（発注）が未設定の場合
      IF ( NVL( gt_edi_work(ln_idx).order_unit_price, 0 ) = 0 ) THEN
--
        -- 価格表ヘッダIDが設定されている場合
        IF ( lt_cust_info_rec.price_list_id IS NOT NULL ) THEN
--
          -- 共通関数により単価を取得
          lt_item_info_rec.unit_price := xxcos_common2_pkg.get_unit_price(
                                           lt_item_info_rec.item_id,
                                           lt_cust_info_rec.price_list_id,
                                           lt_item_info_rec.unit
                                         );
--
          -- 単価が取得できた場合
          IF ( lt_item_info_rec.unit_price > 0 ) THEN
--
            -- 取得した単価を設定
            gt_edi_work(ln_idx).order_unit_price := lt_item_info_rec.unit_price;
            -- 価格表ヘッダIDを設定（１レコード目）
            gt_edi_work(gt_edi_work.first).price_list_header_id := lt_cust_info_rec.price_list_id;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--          ELSE
          -- 上記以外で、チェック対象の場合はエラー
          ELSIF (gn_check_record_flag = cn_check_record_yes) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
            -- 単価が取得できなかった（共通関数でエラー）場合
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_price_err );
            lv_errbuf := lv_errmsg;
            -- ログ出力
            proc_msg_output( cv_prg_name, lv_errbuf );
            -- 警告ステータス設定
            gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
            -- EDIエラー情報追加
            proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_price_err );
            -- エラー件数インクリメント
            gn_warn_cnt := gn_warn_cnt + 1;
--
          END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        ELSE
        -- 上記以外で、チェック対象の場合はエラー
        ELSIF (gn_check_record_flag = cn_check_record_yes) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
          -- 価格表未設定エラーを出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_price_list,
                                                 cv_tkn_chain_shop_code,
                                                 gt_edi_work(ln_idx).edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 gt_edi_work(ln_idx).shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 警告ステータス設定
          gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
          -- EDIエラー情報追加
          proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_price_list );
          -- エラー件数インクリメント
          gn_warn_cnt := gn_warn_cnt + 1;
--
        END IF;
--
      END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
      ----------------------------------------
      -- 行No重複チェック
      ----------------------------------------
      -- 1レコード目以外で前レコードと同一の行Noの場合
      IF ( ln_idx <> 1 AND gt_edi_work(ln_idx - 1).line_no = gt_edi_work(ln_idx).line_no ) THEN
        -- 受注関連明細番号に行Noの最大値+1を設定する。
        ln_new_line_no := ln_new_line_no + 1;
        gt_edi_work(ln_idx).order_connection_line_number := ln_new_line_no;
        -- チェック対象の場合、行No重複エラー
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- 行No重複エラーを出力
          lv_errmsg := xxccp_common_pkg.get_msg(
                           cv_application
                         , cv_msg_line_no_err
                         , cv_tkn_new_line_no
                         , gt_edi_work(ln_idx).order_connection_line_number
                         , cv_tkn_chain_shop_code
                         , gt_edi_work(ln_idx).edi_chain_code
                         , cv_tkn_shop_code
                         , gt_edi_work(ln_idx).shop_code
                         , cv_tkn_order_no
                         , gt_edi_work(ln_idx).invoice_number
                         , cv_tkn_store_deliv_dt
                         , TO_CHAR( gt_edi_work(ln_idx).shop_delivery_date, cv_format_yyyymmdds )
                         , cv_tkn_line_no
                         , gt_edi_work(ln_idx).line_no
                       );
          lv_errbuf := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 警告ステータス設定
          gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
          -- EDIエラー情報追加
          proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_line_no );
          -- エラー件数インクリメント
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
      ELSE
        -- 受注関連明細番号に行Noを設定する。
        gt_edi_work(ln_idx).order_connection_line_number := gt_edi_work(ln_idx).line_no;
      END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
      -- 原価金額(発注)を再計算【発注数量(合計、バラ)×原単価(発注)】
-- 2009/08/06 Ver.1.8 M.Sano Mod Start
--      gt_edi_work(ln_idx).order_cost_amt := NVL( gt_edi_work(ln_idx).sum_order_qty, 0 )
--                                          * NVL( gt_edi_work(ln_idx).order_unit_price, 0 );
      IF ( NVL(gt_edi_work(ln_idx).order_cost_amt, 0) = 0 ) THEN
        gt_edi_work(ln_idx).order_cost_amt := TRUNC(NVL( gt_edi_work(ln_idx).sum_order_qty, 0 )
                                                    * NVL( gt_edi_work(ln_idx).order_unit_price, 0 ));
      END IF;
-- 2009/08/06 Ver.1.8 M.Sano Mod End
--
      -- 伝票エラーフラグがエラーになっている場合
      IF ( gn_invoice_err_flag = 1 ) THEN
        -- 警告ステータス設定
        gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
      END IF;
--
      -- いずれかのチェックでエラーになっている場合
      IF ( gt_edi_work(ln_idx).check_status != cv_edi_status_normal ) THEN
        -- 終了ステータスに警告を設定
        lv_retcode := cv_status_warn;
      END IF;
--
    END LOOP;
--
    -- 終了ステータス設定
    ov_retcode := lv_retcode;
--
  EXCEPTION
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
      -- ログ出力
      proc_msg_output( cv_prg_name, ov_errbuf );
--
--#####################################  固定部 END   ##########################################
--
  END proc_data_validate;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_work
   * Description      : EDI受注情報ワーク変数に設定する(A-5)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_work(
    it_edi_work   IN  edi_order_work_cur%ROWTYPE,      -- EDI受注情報ワークデータ
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    gt_edi_work.EXTEND;
    ln_idx := gt_edi_work.COUNT;
--
    gt_edi_work(ln_idx).order_info_work_id             := it_edi_work.order_info_work_id;                -- 受注情報ワークID
    gt_edi_work(ln_idx).medium_class                   := it_edi_work.medium_class;                      -- 媒体区分
    gt_edi_work(ln_idx).data_type_code                 := it_edi_work.data_type_code;                    -- データ種コード
    gt_edi_work(ln_idx).file_no                        := it_edi_work.file_no;                           -- ファイルＮｏ
    gt_edi_work(ln_idx).info_class                     := it_edi_work.info_class;                        -- 情報区分
    gt_edi_work(ln_idx).process_date                   := it_edi_work.process_date;                      -- 処理日
    gt_edi_work(ln_idx).process_time                   := it_edi_work.process_time;                      -- 処理時刻
    gt_edi_work(ln_idx).base_code                      := it_edi_work.base_code;                         -- 拠点（部門）コード
    gt_edi_work(ln_idx).base_name                      := it_edi_work.base_name;                         -- 拠点名（正式名）
    gt_edi_work(ln_idx).base_name_alt                  := it_edi_work.base_name_alt;                     -- 拠点名（カナ）
    gt_edi_work(ln_idx).edi_chain_code                 := it_edi_work.edi_chain_code;                    -- ＥＤＩチェーン店コード
    gt_edi_work(ln_idx).edi_chain_name                 := it_edi_work.edi_chain_name;                    -- ＥＤＩチェーン店名（漢字）
    gt_edi_work(ln_idx).edi_chain_name_alt             := it_edi_work.edi_chain_name_alt;                -- ＥＤＩチェーン店名（カナ）
    gt_edi_work(ln_idx).chain_code                     := it_edi_work.chain_code;                        -- チェーン店コード
    gt_edi_work(ln_idx).chain_name                     := it_edi_work.chain_name;                        -- チェーン店名（漢字）
    gt_edi_work(ln_idx).chain_name_alt                 := it_edi_work.chain_name_alt;                    -- チェーン店名（カナ）
    gt_edi_work(ln_idx).report_code                    := it_edi_work.report_code;                       -- 帳票コード
    gt_edi_work(ln_idx).report_show_name               := it_edi_work.report_show_name;                  -- 帳票表示名
    gt_edi_work(ln_idx).customer_code                  := it_edi_work.customer_code;                     -- 顧客コード
    gt_edi_work(ln_idx).customer_name                  := it_edi_work.customer_name;                     -- 顧客名（漢字）
    gt_edi_work(ln_idx).customer_name_alt              := it_edi_work.customer_name_alt;                 -- 顧客名（カナ）
    gt_edi_work(ln_idx).company_code                   := it_edi_work.company_code;                      -- 社コード
    gt_edi_work(ln_idx).company_name                   := it_edi_work.company_name;                      -- 社名（漢字）
    gt_edi_work(ln_idx).company_name_alt               := it_edi_work.company_name_alt;                  -- 社名（カナ）
    gt_edi_work(ln_idx).shop_code                      := it_edi_work.shop_code;                         -- 店コード
    gt_edi_work(ln_idx).shop_name                      := it_edi_work.shop_name;                         -- 店名（漢字）
    gt_edi_work(ln_idx).shop_name_alt                  := it_edi_work.shop_name_alt;                     -- 店名（カナ）
    gt_edi_work(ln_idx).delivery_center_code           := it_edi_work.delivery_center_code;              -- 納入センターコード
    gt_edi_work(ln_idx).delivery_center_name           := it_edi_work.delivery_center_name;              -- 納入センター名（漢字）
    gt_edi_work(ln_idx).delivery_center_name_alt       := it_edi_work.delivery_center_name_alt;          -- 納入センター名（カナ）
    gt_edi_work(ln_idx).order_date                     := it_edi_work.order_date;                        -- 発注日
    gt_edi_work(ln_idx).center_delivery_date           := it_edi_work.center_delivery_date;              -- センター納品日
    gt_edi_work(ln_idx).result_delivery_date           := it_edi_work.result_delivery_date;              -- 実納品日
    gt_edi_work(ln_idx).shop_delivery_date             := it_edi_work.shop_delivery_date;                -- 店舗納品日
    gt_edi_work(ln_idx).data_creation_date_edi_data    := it_edi_work.data_creation_date_edi_data;       -- データ作成日（ＥＤＩデータ中）
    gt_edi_work(ln_idx).data_creation_time_edi_data    := it_edi_work.data_creation_time_edi_data;       -- データ作成時刻（ＥＤＩデータ中）
    gt_edi_work(ln_idx).invoice_class                  := it_edi_work.invoice_class;                     -- 伝票区分
    gt_edi_work(ln_idx).small_classification_code      := it_edi_work.small_classification_code;         -- 小分類コード
    gt_edi_work(ln_idx).small_classification_name      := it_edi_work.small_classification_name;         -- 小分類名
    gt_edi_work(ln_idx).middle_classification_code     := it_edi_work.middle_classification_code;        -- 中分類コード
    gt_edi_work(ln_idx).middle_classification_name     := it_edi_work.middle_classification_name;        -- 中分類名
    gt_edi_work(ln_idx).big_classification_code        := it_edi_work.big_classification_code;           -- 大分類コード
    gt_edi_work(ln_idx).big_classification_name        := it_edi_work.big_classification_name;           -- 大分類名
    gt_edi_work(ln_idx).other_party_department_code    := it_edi_work.other_party_department_code;       -- 相手先部門コード
    gt_edi_work(ln_idx).other_party_order_number       := it_edi_work.other_party_order_number;          -- 相手先発注番号
    gt_edi_work(ln_idx).check_digit_class              := it_edi_work.check_digit_class;                 -- チェックデジット有無区分
    gt_edi_work(ln_idx).invoice_number                 := it_edi_work.invoice_number;                    -- 伝票番号
    gt_edi_work(ln_idx).check_digit                    := it_edi_work.check_digit;                       -- チェックデジット
    gt_edi_work(ln_idx).close_date                     := it_edi_work.close_date;                        -- 月限
    gt_edi_work(ln_idx).order_no_ebs                   := it_edi_work.order_no_ebs;                      -- 受注Ｎｏ（ＥＢＳ）
    gt_edi_work(ln_idx).ar_sale_class                  := it_edi_work.ar_sale_class;                     -- 特売区分
    gt_edi_work(ln_idx).delivery_classe                := it_edi_work.delivery_classe;                   -- 配送区分
    gt_edi_work(ln_idx).opportunity_no                 := it_edi_work.opportunity_no;                    -- 便Ｎｏ
    gt_edi_work(ln_idx).contact_to                     := it_edi_work.contact_to;                        -- 連絡先
    gt_edi_work(ln_idx).route_sales                    := it_edi_work.route_sales;                       -- ルートセールス
    gt_edi_work(ln_idx).corporate_code                 := it_edi_work.corporate_code;                    -- 法人コード
    gt_edi_work(ln_idx).maker_name                     := it_edi_work.maker_name;                        -- メーカー名
    gt_edi_work(ln_idx).area_code                      := it_edi_work.area_code;                         -- 地区コード
    gt_edi_work(ln_idx).area_name                      := it_edi_work.area_name;                         -- 地区名（漢字）
    gt_edi_work(ln_idx).area_name_alt                  := it_edi_work.area_name_alt;                     -- 地区名（カナ）
    gt_edi_work(ln_idx).vendor_code                    := it_edi_work.vendor_code;                       -- 取引先コード
    gt_edi_work(ln_idx).vendor_name                    := it_edi_work.vendor_name;                       -- 取引先名（漢字）
    gt_edi_work(ln_idx).vendor_name1_alt               := it_edi_work.vendor_name1_alt;                  -- 取引先名１（カナ）
    gt_edi_work(ln_idx).vendor_name2_alt               := it_edi_work.vendor_name2_alt;                  -- 取引先名２（カナ）
    gt_edi_work(ln_idx).vendor_tel                     := it_edi_work.vendor_tel;                        -- 取引先ＴＥＬ
    gt_edi_work(ln_idx).vendor_charge                  := it_edi_work.vendor_charge;                     -- 取引先担当者
    gt_edi_work(ln_idx).vendor_address                 := it_edi_work.vendor_address;                    -- 取引先住所（漢字）
    gt_edi_work(ln_idx).deliver_to_code_itouen         := it_edi_work.deliver_to_code_itouen;            -- 届け先コード（伊藤園）
    gt_edi_work(ln_idx).deliver_to_code_chain          := it_edi_work.deliver_to_code_chain;             -- 届け先コード（チェーン店）
    gt_edi_work(ln_idx).deliver_to                     := it_edi_work.deliver_to;                        -- 届け先（漢字）
    gt_edi_work(ln_idx).deliver_to1_alt                := it_edi_work.deliver_to1_alt;                   -- 届け先１（カナ）
    gt_edi_work(ln_idx).deliver_to2_alt                := it_edi_work.deliver_to2_alt;                   -- 届け先２（カナ）
    gt_edi_work(ln_idx).deliver_to_address             := it_edi_work.deliver_to_address;                -- 届け先住所（漢字）
    gt_edi_work(ln_idx).deliver_to_address_alt         := it_edi_work.deliver_to_address_alt;            -- 届け先住所（カナ）
    gt_edi_work(ln_idx).deliver_to_tel                 := it_edi_work.deliver_to_tel;                    -- 届け先ＴＥＬ
    gt_edi_work(ln_idx).balance_accounts_code          := it_edi_work.balance_accounts_code;             -- 帳合先コード
    gt_edi_work(ln_idx).balance_accounts_company_code  := it_edi_work.balance_accounts_company_code;     -- 帳合先社コード
    gt_edi_work(ln_idx).balance_accounts_shop_code     := it_edi_work.balance_accounts_shop_code;        -- 帳合先店コード
    gt_edi_work(ln_idx).balance_accounts_name          := it_edi_work.balance_accounts_name;             -- 帳合先名（漢字）
    gt_edi_work(ln_idx).balance_accounts_name_alt      := it_edi_work.balance_accounts_name_alt;         -- 帳合先名（カナ）
    gt_edi_work(ln_idx).balance_accounts_address       := it_edi_work.balance_accounts_address;          -- 帳合先住所（漢字）
    gt_edi_work(ln_idx).balance_accounts_address_alt   := it_edi_work.balance_accounts_address_alt;      -- 帳合先住所（カナ）
    gt_edi_work(ln_idx).balance_accounts_tel           := it_edi_work.balance_accounts_tel;              -- 帳合先ＴＥＬ
    gt_edi_work(ln_idx).order_possible_date            := it_edi_work.order_possible_date;               -- 受注可能日
    gt_edi_work(ln_idx).permission_possible_date       := it_edi_work.permission_possible_date;          -- 許容可能日
    gt_edi_work(ln_idx).forward_month                  := it_edi_work.forward_month;                     -- 先限年月日
    gt_edi_work(ln_idx).payment_settlement_date        := it_edi_work.payment_settlement_date;           -- 支払決済日
    gt_edi_work(ln_idx).handbill_start_date_active     := it_edi_work.handbill_start_date_active;        -- チラシ開始日
    gt_edi_work(ln_idx).billing_due_date               := it_edi_work.billing_due_date;                  -- 請求締日
    gt_edi_work(ln_idx).shipping_time                  := it_edi_work.shipping_time;                     -- 出荷時刻
    gt_edi_work(ln_idx).delivery_schedule_time         := it_edi_work.delivery_schedule_time;            -- 納品予定時間
    gt_edi_work(ln_idx).order_time                     := it_edi_work.order_time;                        -- 発注時間
    gt_edi_work(ln_idx).general_date_item1             := it_edi_work.general_date_item1;                -- 汎用日付項目１
    gt_edi_work(ln_idx).general_date_item2             := it_edi_work.general_date_item2;                -- 汎用日付項目２
    gt_edi_work(ln_idx).general_date_item3             := it_edi_work.general_date_item3;                -- 汎用日付項目３
    gt_edi_work(ln_idx).general_date_item4             := it_edi_work.general_date_item4;                -- 汎用日付項目４
    gt_edi_work(ln_idx).general_date_item5             := it_edi_work.general_date_item5;                -- 汎用日付項目５
    gt_edi_work(ln_idx).arrival_shipping_class         := it_edi_work.arrival_shipping_class;            -- 入出荷区分
    gt_edi_work(ln_idx).vendor_class                   := it_edi_work.vendor_class;                      -- 取引先区分
    gt_edi_work(ln_idx).invoice_detailed_class         := it_edi_work.invoice_detailed_class;            -- 伝票内訳区分
    gt_edi_work(ln_idx).unit_price_use_class           := it_edi_work.unit_price_use_class;              -- 単価使用区分
    gt_edi_work(ln_idx).sub_distribution_center_code   := it_edi_work.sub_distribution_center_code;      -- サブ物流センターコード
    gt_edi_work(ln_idx).sub_distribution_center_name   := it_edi_work.sub_distribution_center_name;      -- サブ物流センターコード名
    gt_edi_work(ln_idx).center_delivery_method         := it_edi_work.center_delivery_method;            -- センター納品方法
    gt_edi_work(ln_idx).center_use_class               := it_edi_work.center_use_class;                  -- センター利用区分
    gt_edi_work(ln_idx).center_whse_class              := it_edi_work.center_whse_class;                 -- センター倉庫区分
    gt_edi_work(ln_idx).center_area_class              := it_edi_work.center_area_class;                 -- センター地域区分
    gt_edi_work(ln_idx).center_arrival_class           := it_edi_work.center_arrival_class;              -- センター入荷区分
    gt_edi_work(ln_idx).depot_class                    := it_edi_work.depot_class;                       -- デポ区分
    gt_edi_work(ln_idx).tcdc_class                     := it_edi_work.tcdc_class;                        -- ＴＣＤＣ区分
    gt_edi_work(ln_idx).upc_flag                       := it_edi_work.upc_flag;                          -- ＵＰＣフラグ
    gt_edi_work(ln_idx).simultaneously_class           := it_edi_work.simultaneously_class;              -- 一斉区分
    gt_edi_work(ln_idx).business_id                    := it_edi_work.business_id;                       -- 業務ＩＤ
    gt_edi_work(ln_idx).whse_directly_class            := it_edi_work.whse_directly_class;               -- 倉直区分
    gt_edi_work(ln_idx).premium_rebate_class           := it_edi_work.premium_rebate_class;              -- 景品割戻区分
    gt_edi_work(ln_idx).item_type                      := it_edi_work.item_type;                         -- 項目種別
    gt_edi_work(ln_idx).cloth_house_food_class         := it_edi_work.cloth_house_food_class;            -- 衣家食区分
    gt_edi_work(ln_idx).mix_class                      := it_edi_work.mix_class;                         -- 混在区分
    gt_edi_work(ln_idx).stk_class                      := it_edi_work.stk_class;                         -- 在庫区分
    gt_edi_work(ln_idx).last_modify_site_class         := it_edi_work.last_modify_site_class;            -- 最終修正場所区分
    gt_edi_work(ln_idx).report_class                   := it_edi_work.report_class;                      -- 帳票区分
    gt_edi_work(ln_idx).addition_plan_class            := it_edi_work.addition_plan_class;               -- 追加・計画区分
    gt_edi_work(ln_idx).registration_class             := it_edi_work.registration_class;                -- 登録区分
    gt_edi_work(ln_idx).specific_class                 := it_edi_work.specific_class;                    -- 特定区分
    gt_edi_work(ln_idx).dealings_class                 := it_edi_work.dealings_class;                    -- 取引区分
    gt_edi_work(ln_idx).order_class                    := it_edi_work.order_class;                       -- 発注区分
    gt_edi_work(ln_idx).sum_line_class                 := it_edi_work.sum_line_class;                    -- 集計明細区分
    gt_edi_work(ln_idx).shipping_guidance_class        := it_edi_work.shipping_guidance_class;           -- 出荷案内以外区分
    gt_edi_work(ln_idx).shipping_class                 := it_edi_work.shipping_class;                    -- 出荷区分
    gt_edi_work(ln_idx).product_code_use_class         := it_edi_work.product_code_use_class;            -- 商品コード使用区分
    gt_edi_work(ln_idx).cargo_item_class               := it_edi_work.cargo_item_class;                  -- 積送品区分
    gt_edi_work(ln_idx).ta_class                       := it_edi_work.ta_class;                          -- Ｔ／Ａ区分
    gt_edi_work(ln_idx).plan_code                      := it_edi_work.plan_code;                         -- 企画コード
    gt_edi_work(ln_idx).category_code                  := it_edi_work.category_code;                     -- カテゴリーコード
    gt_edi_work(ln_idx).category_class                 := it_edi_work.category_class;                    -- カテゴリー区分
    gt_edi_work(ln_idx).carrier_means                  := it_edi_work.carrier_means;                     -- 運送手段
    gt_edi_work(ln_idx).counter_code                   := it_edi_work.counter_code;                      -- 売場コード
    gt_edi_work(ln_idx).move_sign                      := it_edi_work.move_sign;                         -- 移動サイン
    gt_edi_work(ln_idx).eos_handwriting_class          := it_edi_work.eos_handwriting_class;             -- ＥＯＳ・手書区分
    gt_edi_work(ln_idx).delivery_to_section_code       := it_edi_work.delivery_to_section_code;          -- 納品先課コード
    gt_edi_work(ln_idx).invoice_detailed               := it_edi_work.invoice_detailed;                  -- 伝票内訳
    gt_edi_work(ln_idx).attach_qty                     := it_edi_work.attach_qty;                        -- 添付数
    gt_edi_work(ln_idx).other_party_floor              := it_edi_work.other_party_floor;                 -- フロア
    gt_edi_work(ln_idx).text_no                        := it_edi_work.text_no;                           -- ＴＥＸＴＮｏ
    gt_edi_work(ln_idx).in_store_code                  := it_edi_work.in_store_code;                     -- インストアコード
    gt_edi_work(ln_idx).tag_data                       := it_edi_work.tag_data;                          -- タグ
    gt_edi_work(ln_idx).competition_code               := it_edi_work.competition_code;                  -- 競合
    gt_edi_work(ln_idx).billing_chair                  := it_edi_work.billing_chair;                     -- 請求口座
    gt_edi_work(ln_idx).chain_store_code               := it_edi_work.chain_store_code;                  -- チェーンストアーコード
    gt_edi_work(ln_idx).chain_store_short_name         := it_edi_work.chain_store_short_name;            -- チェーンストアーコード略式名称
    gt_edi_work(ln_idx).direct_delivery_rcpt_fee       := it_edi_work.direct_delivery_rcpt_fee;          -- 直配送／引取料
    gt_edi_work(ln_idx).bill_info                      := it_edi_work.bill_info;                         -- 手形情報
    gt_edi_work(ln_idx).description                    := it_edi_work.description;                       -- 摘要
    gt_edi_work(ln_idx).interior_code                  := it_edi_work.interior_code;                     -- 内部コード
    gt_edi_work(ln_idx).order_info_delivery_category   := it_edi_work.order_info_delivery_category;      -- 発注情報　納品カテゴリー
    gt_edi_work(ln_idx).purchase_type                  := it_edi_work.purchase_type;                     -- 仕入形態
    gt_edi_work(ln_idx).delivery_to_name_alt           := it_edi_work.delivery_to_name_alt;              -- 納品場所名（カナ）
    gt_edi_work(ln_idx).shop_opened_site               := it_edi_work.shop_opened_site;                  -- 店出場所
    gt_edi_work(ln_idx).counter_name                   := it_edi_work.counter_name;                      -- 売場名
    gt_edi_work(ln_idx).extension_number               := it_edi_work.extension_number;                  -- 内線番号
    gt_edi_work(ln_idx).charge_name                    := it_edi_work.charge_name;                       -- 担当者名
    gt_edi_work(ln_idx).price_tag                      := it_edi_work.price_tag;                         -- 値札
    gt_edi_work(ln_idx).tax_type                       := it_edi_work.tax_type;                          -- 税種
    gt_edi_work(ln_idx).consumption_tax_class          := it_edi_work.consumption_tax_class;             -- 消費税区分
    gt_edi_work(ln_idx).brand_class                    := it_edi_work.brand_class;                       -- ＢＲ
    gt_edi_work(ln_idx).id_code                        := it_edi_work.id_code;                           -- ＩＤコード
    gt_edi_work(ln_idx).department_code                := it_edi_work.department_code;                   -- 百貨店コード
    gt_edi_work(ln_idx).department_name                := it_edi_work.department_name;                   -- 百貨店名
    gt_edi_work(ln_idx).item_type_number               := it_edi_work.item_type_number;                  -- 品別番号
    gt_edi_work(ln_idx).description_department         := it_edi_work.description_department;            -- 摘要（百貨店）
    gt_edi_work(ln_idx).price_tag_method               := it_edi_work.price_tag_method;                  -- 値札方法
    gt_edi_work(ln_idx).reason_column                  := it_edi_work.reason_column;                     -- 自由欄
    gt_edi_work(ln_idx).a_column_header                := it_edi_work.a_column_header;                   -- Ａ欄ヘッダ
    gt_edi_work(ln_idx).d_column_header                := it_edi_work.d_column_header;                   -- Ｄ欄ヘッダ
    gt_edi_work(ln_idx).brand_code                     := it_edi_work.brand_code;                        -- ブランドコード
    gt_edi_work(ln_idx).line_code                      := it_edi_work.line_code;                         -- ラインコード
    gt_edi_work(ln_idx).class_code                     := it_edi_work.class_code;                        -- クラスコード
    gt_edi_work(ln_idx).a1_column                      := it_edi_work.a1_column;                         -- Ａ－１欄
    gt_edi_work(ln_idx).b1_column                      := it_edi_work.b1_column;                         -- Ｂ－１欄
    gt_edi_work(ln_idx).c1_column                      := it_edi_work.c1_column;                         -- Ｃ－１欄
    gt_edi_work(ln_idx).d1_column                      := it_edi_work.d1_column;                         -- Ｄ－１欄
    gt_edi_work(ln_idx).e1_column                      := it_edi_work.e1_column;                         -- Ｅ－１欄
    gt_edi_work(ln_idx).a2_column                      := it_edi_work.a2_column;                         -- Ａ－２欄
    gt_edi_work(ln_idx).b2_column                      := it_edi_work.b2_column;                         -- Ｂ－２欄
    gt_edi_work(ln_idx).c2_column                      := it_edi_work.c2_column;                         -- Ｃ－２欄
    gt_edi_work(ln_idx).d2_column                      := it_edi_work.d2_column;                         -- Ｄ－２欄
    gt_edi_work(ln_idx).e2_column                      := it_edi_work.e2_column;                         -- Ｅ－２欄
    gt_edi_work(ln_idx).a3_column                      := it_edi_work.a3_column;                         -- Ａ－３欄
    gt_edi_work(ln_idx).b3_column                      := it_edi_work.b3_column;                         -- Ｂ－３欄
    gt_edi_work(ln_idx).c3_column                      := it_edi_work.c3_column;                         -- Ｃ－３欄
    gt_edi_work(ln_idx).d3_column                      := it_edi_work.d3_column;                         -- Ｄ－３欄
    gt_edi_work(ln_idx).e3_column                      := it_edi_work.e3_column;                         -- Ｅ－３欄
    gt_edi_work(ln_idx).f1_column                      := it_edi_work.f1_column;                         -- Ｆ－１欄
    gt_edi_work(ln_idx).g1_column                      := it_edi_work.g1_column;                         -- Ｇ－１欄
    gt_edi_work(ln_idx).h1_column                      := it_edi_work.h1_column;                         -- Ｈ－１欄
    gt_edi_work(ln_idx).i1_column                      := it_edi_work.i1_column;                         -- Ｉ－１欄
    gt_edi_work(ln_idx).j1_column                      := it_edi_work.j1_column;                         -- Ｊ－１欄
    gt_edi_work(ln_idx).k1_column                      := it_edi_work.k1_column;                         -- Ｋ－１欄
    gt_edi_work(ln_idx).l1_column                      := it_edi_work.l1_column;                         -- Ｌ－１欄
    gt_edi_work(ln_idx).f2_column                      := it_edi_work.f2_column;                         -- Ｆ－２欄
    gt_edi_work(ln_idx).g2_column                      := it_edi_work.g2_column;                         -- Ｇ－２欄
    gt_edi_work(ln_idx).h2_column                      := it_edi_work.h2_column;                         -- Ｈ－２欄
    gt_edi_work(ln_idx).i2_column                      := it_edi_work.i2_column;                         -- Ｉ－２欄
    gt_edi_work(ln_idx).j2_column                      := it_edi_work.j2_column;                         -- Ｊ－２欄
    gt_edi_work(ln_idx).k2_column                      := it_edi_work.k2_column;                         -- Ｋ－２欄
    gt_edi_work(ln_idx).l2_column                      := it_edi_work.l2_column;                         -- Ｌ－２欄
    gt_edi_work(ln_idx).f3_column                      := it_edi_work.f3_column;                         -- Ｆ－３欄
    gt_edi_work(ln_idx).g3_column                      := it_edi_work.g3_column;                         -- Ｇ－３欄
    gt_edi_work(ln_idx).h3_column                      := it_edi_work.h3_column;                         -- Ｈ－３欄
    gt_edi_work(ln_idx).i3_column                      := it_edi_work.i3_column;                         -- Ｉ－３欄
    gt_edi_work(ln_idx).j3_column                      := it_edi_work.j3_column;                         -- Ｊ－３欄
    gt_edi_work(ln_idx).k3_column                      := it_edi_work.k3_column;                         -- Ｋ－３欄
    gt_edi_work(ln_idx).l3_column                      := it_edi_work.l3_column;                         -- Ｌ－３欄
    gt_edi_work(ln_idx).chain_peculiar_area_header     := it_edi_work.chain_peculiar_area_header;        -- チェーン店固有エリア（ヘッダー）
    gt_edi_work(ln_idx).order_connection_number        := it_edi_work.order_connection_number;           -- 受注関連番号
    gt_edi_work(ln_idx).line_no                        := it_edi_work.line_no;                           -- 行Ｎｏ
    gt_edi_work(ln_idx).stockout_class                 := it_edi_work.stockout_class;                    -- 欠品区分
    gt_edi_work(ln_idx).stockout_reason                := it_edi_work.stockout_reason;                   -- 欠品理由
    gt_edi_work(ln_idx).product_code_itouen            := it_edi_work.product_code_itouen;               -- 商品コード（伊藤園）
    gt_edi_work(ln_idx).product_code1                  := it_edi_work.product_code1;                     -- 商品コード１
    gt_edi_work(ln_idx).product_code2                  := it_edi_work.product_code2;                     -- 商品コード２
    gt_edi_work(ln_idx).jan_code                       := it_edi_work.jan_code;                          -- ＪＡＮコード
    gt_edi_work(ln_idx).itf_code                       := it_edi_work.itf_code;                          -- ＩＴＦコード
    gt_edi_work(ln_idx).extension_itf_code             := it_edi_work.extension_itf_code;                -- 内箱ＩＴＦコード
    gt_edi_work(ln_idx).case_product_code              := it_edi_work.case_product_code;                 -- ケース商品コード
    gt_edi_work(ln_idx).ball_product_code              := it_edi_work.ball_product_code;                 -- ボール商品コード
    gt_edi_work(ln_idx).product_code_item_type         := it_edi_work.product_code_item_type;            -- 商品コード品種
    gt_edi_work(ln_idx).prod_class                     := it_edi_work.prod_class;                        -- 商品区分
    gt_edi_work(ln_idx).product_name                   := it_edi_work.product_name;                      -- 商品名（漢字）
    gt_edi_work(ln_idx).product_name1_alt              := it_edi_work.product_name1_alt;                 -- 商品名１（カナ）
    gt_edi_work(ln_idx).product_name2_alt              := it_edi_work.product_name2_alt;                 -- 商品名２（カナ）
    gt_edi_work(ln_idx).item_standard1                 := it_edi_work.item_standard1;                    -- 規格１
    gt_edi_work(ln_idx).item_standard2                 := it_edi_work.item_standard2;                    -- 規格２
    gt_edi_work(ln_idx).qty_in_case                    := it_edi_work.qty_in_case;                       -- 入数
    gt_edi_work(ln_idx).num_of_cases                   := it_edi_work.num_of_cases;                      -- ケース入数
    gt_edi_work(ln_idx).num_of_ball                    := it_edi_work.num_of_ball;                       -- ボール入数
    gt_edi_work(ln_idx).item_color                     := it_edi_work.item_color;                        -- 色
    gt_edi_work(ln_idx).item_size                      := it_edi_work.item_size;                         -- サイズ
    gt_edi_work(ln_idx).expiration_date                := it_edi_work.expiration_date;                   -- 賞味期限日
    gt_edi_work(ln_idx).product_date                   := it_edi_work.product_date;                      -- 製造日
    gt_edi_work(ln_idx).order_uom_qty                  := it_edi_work.order_uom_qty;                     -- 発注単位数
    gt_edi_work(ln_idx).shipping_uom_qty               := it_edi_work.shipping_uom_qty;                  -- 出荷単位数
    gt_edi_work(ln_idx).packing_uom_qty                := it_edi_work.packing_uom_qty;                   -- 梱包単位数
    gt_edi_work(ln_idx).deal_code                      := it_edi_work.deal_code;                         -- 引合
    gt_edi_work(ln_idx).deal_class                     := it_edi_work.deal_class;                        -- 引合区分
    gt_edi_work(ln_idx).collation_code                 := it_edi_work.collation_code;                    -- 照合
    gt_edi_work(ln_idx).uom_code                       := it_edi_work.uom_code;                          -- 単位
    gt_edi_work(ln_idx).unit_price_class               := it_edi_work.unit_price_class;                  -- 単価区分
    gt_edi_work(ln_idx).parent_packing_number          := it_edi_work.parent_packing_number;             -- 親梱包番号
    gt_edi_work(ln_idx).packing_number                 := it_edi_work.packing_number;                    -- 梱包番号
    gt_edi_work(ln_idx).product_group_code             := it_edi_work.product_group_code;                -- 商品群コード
    gt_edi_work(ln_idx).case_dismantle_flag            := it_edi_work.case_dismantle_flag;               -- ケース解体不可フラグ
    gt_edi_work(ln_idx).case_class                     := it_edi_work.case_class;                        -- ケース区分
    gt_edi_work(ln_idx).indv_order_qty                 := it_edi_work.indv_order_qty;                    -- 発注数量（バラ）
    gt_edi_work(ln_idx).case_order_qty                 := it_edi_work.case_order_qty;                    -- 発注数量（ケース）
    gt_edi_work(ln_idx).ball_order_qty                 := it_edi_work.ball_order_qty;                    -- 発注数量（ボール）
    gt_edi_work(ln_idx).sum_order_qty                  := it_edi_work.sum_order_qty;                     -- 発注数量（合計、バラ）
    gt_edi_work(ln_idx).indv_shipping_qty              := it_edi_work.indv_shipping_qty;                 -- 出荷数量（バラ）
    gt_edi_work(ln_idx).case_shipping_qty              := it_edi_work.case_shipping_qty;                 -- 出荷数量（ケース）
    gt_edi_work(ln_idx).ball_shipping_qty              := it_edi_work.ball_shipping_qty;                 -- 出荷数量（ボール）
    gt_edi_work(ln_idx).pallet_shipping_qty            := it_edi_work.pallet_shipping_qty;               -- 出荷数量（パレット）
    gt_edi_work(ln_idx).sum_shipping_qty               := it_edi_work.sum_shipping_qty;                  -- 出荷数量（合計、バラ）
    gt_edi_work(ln_idx).indv_stockout_qty              := it_edi_work.indv_stockout_qty;                 -- 欠品数量（バラ）
    gt_edi_work(ln_idx).case_stockout_qty              := it_edi_work.case_stockout_qty;                 -- 欠品数量（ケース）
    gt_edi_work(ln_idx).ball_stockout_qty              := it_edi_work.ball_stockout_qty;                 -- 欠品数量（ボール）
    gt_edi_work(ln_idx).sum_stockout_qty               := it_edi_work.sum_stockout_qty;                  -- 欠品数量（合計、バラ）
    gt_edi_work(ln_idx).case_qty                       := it_edi_work.case_qty;                          -- ケース個口数
    gt_edi_work(ln_idx).fold_container_indv_qty        := it_edi_work.fold_container_indv_qty;           -- オリコン（バラ）個口数
    gt_edi_work(ln_idx).order_unit_price               := it_edi_work.order_unit_price;                  -- 原単価（発注）
    gt_edi_work(ln_idx).shipping_unit_price            := it_edi_work.shipping_unit_price;               -- 原単価（出荷）
    gt_edi_work(ln_idx).order_cost_amt                 := it_edi_work.order_cost_amt;                    -- 原価金額（発注）
    gt_edi_work(ln_idx).shipping_cost_amt              := it_edi_work.shipping_cost_amt;                 -- 原価金額（出荷）
    gt_edi_work(ln_idx).stockout_cost_amt              := it_edi_work.stockout_cost_amt;                 -- 原価金額（欠品）
    gt_edi_work(ln_idx).selling_price                  := it_edi_work.selling_price;                     -- 売単価
    gt_edi_work(ln_idx).order_price_amt                := it_edi_work.order_price_amt;                   -- 売価金額（発注）
    gt_edi_work(ln_idx).shipping_price_amt             := it_edi_work.shipping_price_amt;                -- 売価金額（出荷）
    gt_edi_work(ln_idx).stockout_price_amt             := it_edi_work.stockout_price_amt;                -- 売価金額（欠品）
    gt_edi_work(ln_idx).a_column_department            := it_edi_work.a_column_department;               -- Ａ欄（百貨店）
    gt_edi_work(ln_idx).d_column_department            := it_edi_work.d_column_department;               -- Ｄ欄（百貨店）
    gt_edi_work(ln_idx).standard_info_depth            := it_edi_work.standard_info_depth;               -- 規格情報・奥行き
    gt_edi_work(ln_idx).standard_info_height           := it_edi_work.standard_info_height;              -- 規格情報・高さ
    gt_edi_work(ln_idx).standard_info_width            := it_edi_work.standard_info_width;               -- 規格情報・幅
    gt_edi_work(ln_idx).standard_info_weight           := it_edi_work.standard_info_weight;              -- 規格情報・重量
    gt_edi_work(ln_idx).general_succeeded_item1        := it_edi_work.general_succeeded_item1;           -- 汎用引継ぎ項目１
    gt_edi_work(ln_idx).general_succeeded_item2        := it_edi_work.general_succeeded_item2;           -- 汎用引継ぎ項目２
    gt_edi_work(ln_idx).general_succeeded_item3        := it_edi_work.general_succeeded_item3;           -- 汎用引継ぎ項目３
    gt_edi_work(ln_idx).general_succeeded_item4        := it_edi_work.general_succeeded_item4;           -- 汎用引継ぎ項目４
    gt_edi_work(ln_idx).general_succeeded_item5        := it_edi_work.general_succeeded_item5;           -- 汎用引継ぎ項目５
    gt_edi_work(ln_idx).general_succeeded_item6        := it_edi_work.general_succeeded_item6;           -- 汎用引継ぎ項目６
    gt_edi_work(ln_idx).general_succeeded_item7        := it_edi_work.general_succeeded_item7;           -- 汎用引継ぎ項目７
    gt_edi_work(ln_idx).general_succeeded_item8        := it_edi_work.general_succeeded_item8;           -- 汎用引継ぎ項目８
    gt_edi_work(ln_idx).general_succeeded_item9        := it_edi_work.general_succeeded_item9;           -- 汎用引継ぎ項目９
    gt_edi_work(ln_idx).general_succeeded_item10       := it_edi_work.general_succeeded_item10;          -- 汎用引継ぎ項目１０
    gt_edi_work(ln_idx).general_add_item1              := it_edi_work.general_add_item1;                 -- 汎用付加項目１
    gt_edi_work(ln_idx).general_add_item2              := it_edi_work.general_add_item2;                 -- 汎用付加項目２
    gt_edi_work(ln_idx).general_add_item3              := it_edi_work.general_add_item3;                 -- 汎用付加項目３
    gt_edi_work(ln_idx).general_add_item4              := it_edi_work.general_add_item4;                 -- 汎用付加項目４
    gt_edi_work(ln_idx).general_add_item5              := it_edi_work.general_add_item5;                 -- 汎用付加項目５
    gt_edi_work(ln_idx).general_add_item6              := it_edi_work.general_add_item6;                 -- 汎用付加項目６
    gt_edi_work(ln_idx).general_add_item7              := it_edi_work.general_add_item7;                 -- 汎用付加項目７
    gt_edi_work(ln_idx).general_add_item8              := it_edi_work.general_add_item8;                 -- 汎用付加項目８
    gt_edi_work(ln_idx).general_add_item9              := it_edi_work.general_add_item9;                 -- 汎用付加項目９
    gt_edi_work(ln_idx).general_add_item10             := it_edi_work.general_add_item10;                -- 汎用付加項目１０
    gt_edi_work(ln_idx).chain_peculiar_area_line       := it_edi_work.chain_peculiar_area_line;          -- チェーン店固有エリア（明細）
    gt_edi_work(ln_idx).invoice_indv_order_qty         := it_edi_work.invoice_indv_order_qty;            -- （伝票計）発注数量（バラ）
    gt_edi_work(ln_idx).invoice_case_order_qty         := it_edi_work.invoice_case_order_qty;            -- （伝票計）発注数量（ケース）
    gt_edi_work(ln_idx).invoice_ball_order_qty         := it_edi_work.invoice_ball_order_qty;            -- （伝票計）発注数量（ボール）
    gt_edi_work(ln_idx).invoice_sum_order_qty          := it_edi_work.invoice_sum_order_qty;             -- （伝票計）発注数量（合計、バラ）
    gt_edi_work(ln_idx).invoice_indv_shipping_qty      := it_edi_work.invoice_indv_shipping_qty;         -- （伝票計）出荷数量（バラ）
    gt_edi_work(ln_idx).invoice_case_shipping_qty      := it_edi_work.invoice_case_shipping_qty;         -- （伝票計）出荷数量（ケース）
    gt_edi_work(ln_idx).invoice_ball_shipping_qty      := it_edi_work.invoice_ball_shipping_qty;         -- （伝票計）出荷数量（ボール）
    gt_edi_work(ln_idx).invoice_pallet_shipping_qty    := it_edi_work.invoice_pallet_shipping_qty;       -- （伝票計）出荷数量（パレット）
    gt_edi_work(ln_idx).invoice_sum_shipping_qty       := it_edi_work.invoice_sum_shipping_qty;          -- （伝票計）出荷数量（合計、バラ）
    gt_edi_work(ln_idx).invoice_indv_stockout_qty      := it_edi_work.invoice_indv_stockout_qty;         -- （伝票計）欠品数量（バラ）
    gt_edi_work(ln_idx).invoice_case_stockout_qty      := it_edi_work.invoice_case_stockout_qty;         -- （伝票計）欠品数量（ケース）
    gt_edi_work(ln_idx).invoice_ball_stockout_qty      := it_edi_work.invoice_ball_stockout_qty;         -- （伝票計）欠品数量（ボール）
    gt_edi_work(ln_idx).invoice_sum_stockout_qty       := it_edi_work.invoice_sum_stockout_qty;          -- （伝票計）欠品数量（合計、バラ）
    gt_edi_work(ln_idx).invoice_case_qty               := it_edi_work.invoice_case_qty;                  -- （伝票計）ケース個口数
    gt_edi_work(ln_idx).invoice_fold_container_qty     := it_edi_work.invoice_fold_container_qty;        -- （伝票計）オリコン（バラ）個口数
    gt_edi_work(ln_idx).invoice_order_cost_amt         := it_edi_work.invoice_order_cost_amt;            -- （伝票計）原価金額（発注）
    gt_edi_work(ln_idx).invoice_shipping_cost_amt      := it_edi_work.invoice_shipping_cost_amt;         -- （伝票計）原価金額（出荷）
    gt_edi_work(ln_idx).invoice_stockout_cost_amt      := it_edi_work.invoice_stockout_cost_amt;         -- （伝票計）原価金額（欠品）
    gt_edi_work(ln_idx).invoice_order_price_amt        := it_edi_work.invoice_order_price_amt;           -- （伝票計）売価金額（発注）
    gt_edi_work(ln_idx).invoice_shipping_price_amt     := it_edi_work.invoice_shipping_price_amt;        -- （伝票計）売価金額（出荷）
    gt_edi_work(ln_idx).invoice_stockout_price_amt     := it_edi_work.invoice_stockout_price_amt;        -- （伝票計）売価金額（欠品）
    gt_edi_work(ln_idx).total_indv_order_qty           := it_edi_work.total_indv_order_qty;              -- （総合計）発注数量（バラ）
    gt_edi_work(ln_idx).total_case_order_qty           := it_edi_work.total_case_order_qty;              -- （総合計）発注数量（ケース）
    gt_edi_work(ln_idx).total_ball_order_qty           := it_edi_work.total_ball_order_qty;              -- （総合計）発注数量（ボール）
    gt_edi_work(ln_idx).total_sum_order_qty            := it_edi_work.total_sum_order_qty;               -- （総合計）発注数量（合計、バラ）
    gt_edi_work(ln_idx).total_indv_shipping_qty        := it_edi_work.total_indv_shipping_qty;           -- （総合計）出荷数量（バラ）
    gt_edi_work(ln_idx).total_case_shipping_qty        := it_edi_work.total_case_shipping_qty;           -- （総合計）出荷数量（ケース）
    gt_edi_work(ln_idx).total_ball_shipping_qty        := it_edi_work.total_ball_shipping_qty;           -- （総合計）出荷数量（ボール）
    gt_edi_work(ln_idx).total_pallet_shipping_qty      := it_edi_work.total_pallet_shipping_qty;         -- （総合計）出荷数量（パレット）
    gt_edi_work(ln_idx).total_sum_shipping_qty         := it_edi_work.total_sum_shipping_qty;            -- （総合計）出荷数量（合計、バラ）
    gt_edi_work(ln_idx).total_indv_stockout_qty        := it_edi_work.total_indv_stockout_qty;           -- （総合計）欠品数量（バラ）
    gt_edi_work(ln_idx).total_case_stockout_qty        := it_edi_work.total_case_stockout_qty;           -- （総合計）欠品数量（ケース）
    gt_edi_work(ln_idx).total_ball_stockout_qty        := it_edi_work.total_ball_stockout_qty;           -- （総合計）欠品数量（ボール）
    gt_edi_work(ln_idx).total_sum_stockout_qty         := it_edi_work.total_sum_stockout_qty;            -- （総合計）欠品数量（合計、バラ）
    gt_edi_work(ln_idx).total_case_qty                 := it_edi_work.total_case_qty;                    -- （総合計）ケース個口数
    gt_edi_work(ln_idx).total_fold_container_qty       := it_edi_work.total_fold_container_qty;          -- （総合計）オリコン（バラ）個口数
    gt_edi_work(ln_idx).total_order_cost_amt           := it_edi_work.total_order_cost_amt;              -- （総合計）原価金額（発注）
    gt_edi_work(ln_idx).total_shipping_cost_amt        := it_edi_work.total_shipping_cost_amt;           -- （総合計）原価金額（出荷）
    gt_edi_work(ln_idx).total_stockout_cost_amt        := it_edi_work.total_stockout_cost_amt;           -- （総合計）原価金額（欠品）
    gt_edi_work(ln_idx).total_order_price_amt          := it_edi_work.total_order_price_amt;             -- （総合計）売価金額（発注）
    gt_edi_work(ln_idx).total_shipping_price_amt       := it_edi_work.total_shipping_price_amt;          -- （総合計）売価金額（出荷）
    gt_edi_work(ln_idx).total_stockout_price_amt       := it_edi_work.total_stockout_price_amt;          -- （総合計）売価金額（欠品）
    gt_edi_work(ln_idx).total_line_qty                 := it_edi_work.total_line_qty;                    -- トータル行数
    gt_edi_work(ln_idx).total_invoice_qty              := it_edi_work.total_invoice_qty;                 -- トータル伝票枚数
    gt_edi_work(ln_idx).chain_peculiar_area_footer     := it_edi_work.chain_peculiar_area_footer;        -- チェーン店固有エリア（フッター）
    gt_edi_work(ln_idx).err_status                     := it_edi_work.err_status;                        -- ステータス
-- 2010/01/19 Ver.1.15 M.Sano add Start
    gt_edi_work(ln_idx).creation_date                  := it_edi_work.creation_date;                     -- 作成日
-- 2010/01/19 Ver.1.15 M.Sano add End
    gt_edi_work(ln_idx).conv_customer_code             := NULL;                                          -- 変換後顧客コード
    gt_edi_work(ln_idx).price_list_header_id           := NULL;                                          -- 価格表ヘッダID
    gt_edi_work(ln_idx).item_code                      := NULL;                                          -- 品目コード
    gt_edi_work(ln_idx).line_uom                       := NULL;                                          -- 明細単位
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_edi_work(ln_idx).tsukagatazaiko_div             := NULL;                                          -- 通過在庫型区分
    gt_edi_work(ln_idx).order_forward_flag             := NULL;                                          -- 受注連携済フラグ
-- 2009/12/28 M.Sano Ver.1.14 add End
    gt_edi_work(ln_idx).check_status                   := cv_edi_status_normal;                          -- チェックステータス
--
  EXCEPTION
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
  END proc_set_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_status
   * Description      : EDIステータス更新用変数格納(A-6)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_status(
    in_order_info_work_id IN NUMBER,       -- EDI受注ワークID
    iv_err_status         IN VARCHAR2,     -- ステータス
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_status'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    ln_idx := gt_order_info_work_id.COUNT + 1;
--
    -- EDI受注情報ワークID、ステータスを保持する
    gt_order_info_work_id(ln_idx)       := in_order_info_work_id;
    gt_edi_err_status(ln_idx)           := iv_err_status;
--
  EXCEPTION
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
  END proc_set_edi_status;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_headers
   * Description      : EDIヘッダ情報テーブルデータ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_headers(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI受注情報ワークレコード
    on_edi_header_info_id OUT NOCOPY NUMBER, -- EDIヘッダ情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
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
    -- OUTパラメータ初期化
    on_edi_header_info_id := NULL;
--
    --EDIヘッダ情報データ抽出
    SELECT  head.edi_header_info_id
    INTO    on_edi_header_info_id
    FROM    xxcos_edi_headers           head
    WHERE   head.data_type_code         = it_edi_work.data_type_code                 -- データ種コード：受注
    AND     head.edi_chain_code         = it_edi_work.edi_chain_code                 -- EDIチェーン店コード
    AND     head.invoice_number         = it_edi_work.invoice_number                 -- 伝票番号
    AND     ( ( head.shop_delivery_date IS NULL AND it_edi_work.shop_delivery_date IS NULL )
            OR ( head.shop_delivery_date = it_edi_work.shop_delivery_date ) )        -- 店舗納品日
    AND     ( ( head.center_delivery_date IS NULL AND it_edi_work.center_delivery_date IS NULL )
            OR ( head.center_delivery_date = it_edi_work.center_delivery_date ) )    -- センター納品日
    AND     ( ( head.order_date IS NULL AND it_edi_work.order_date IS NULL  )
            OR ( head.order_date = it_edi_work.order_date ) )                        -- 発注日
-- ************ 2009/11/29 1.13 N.Maeda MOD START ************ --
    AND     ( ( head.data_creation_date_edi_data IS NULL AND it_edi_work.data_creation_date_edi_data IS NULL)
            OR ( TRUNC( head.data_creation_date_edi_data ) = TRUNC( it_edi_work.data_creation_date_edi_data ) ) )
--    AND     TRUNC( head.data_creation_date_edi_data ) = TRUNC( it_edi_work.data_creation_date_edi_data ) -- データ作成日（ＥＤＩデータ中）
-- ************ 2009/11/29 1.13 N.Maeda MOD START ************ --
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--    AND     head.shop_code              = it_edi_work.shop_code;                      -- 店コード
    AND     head.shop_code              = it_edi_work.shop_code                      -- 店コード
    AND     (  ( head.info_class IS NULL AND it_edi_work.info_class IS NULL )
            OR ( head.info_class        = it_edi_work.info_class ) )
    ;                    -- 情報区分
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** 対象データなし例外ハンドラ ***
      NULL;
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
  END proc_get_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_ins_headers
   * Description      : EDIヘッダ情報インサート用変数格納(A-8)
   ***********************************************************************************/
  PROCEDURE proc_set_ins_headers(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI受注情報ワークレコード
    on_edi_header_info_id OUT NOCOPY NUMBER, -- EDIヘッダ情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_ins_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
    ln_seq_1   NUMBER;
    ln_seq_2   NUMBER;
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
    -- OUTパラメータ初期化
    on_edi_header_info_id := NULL;
--
    ln_idx := gt_edi_headers.COUNT + 1;
--
    -- EDIヘッダ情報IDをシーケンスから取得する
    BEGIN
      SELECT xxcos_edi_headers_s01.NEXTVAL
      INTO   ln_seq_1
      FROM   dual;
--
      -- 取得したシーケンスをOUTパラメータで返す
      on_edi_header_info_id := ln_seq_1;
    END;
--
    -- 受注関連番号をシーケンスから取得する
    BEGIN
      SELECT xxcos_edi_headers_s02.NEXTVAL
      INTO   ln_seq_2
      FROM   dual;
    END;
--
    gt_edi_headers(ln_idx).edi_header_info_id               := ln_seq_1;                                      -- EDIヘッダ情報ID
    gt_edi_headers(ln_idx).medium_class                     := it_edi_work.medium_class;                      -- 媒体区分
    gt_edi_headers(ln_idx).data_type_code                   := it_edi_work.data_type_code;                    -- データ種コード
    gt_edi_headers(ln_idx).file_no                          := it_edi_work.file_no;                           -- ファイルＮｏ
    gt_edi_headers(ln_idx).info_class                       := it_edi_work.info_class;                        -- 情報区分
    gt_edi_headers(ln_idx).process_date                     := it_edi_work.process_date;                      -- 処理日
    gt_edi_headers(ln_idx).process_time                     := it_edi_work.process_time;                      -- 処理時刻
    gt_edi_headers(ln_idx).base_code                        := it_edi_work.base_code;                         -- 拠点（部門）コード
    gt_edi_headers(ln_idx).base_name                        := it_edi_work.base_name;                         -- 拠点名（正式名）
    gt_edi_headers(ln_idx).base_name_alt                    := it_edi_work.base_name_alt;                     -- 拠点名（カナ）
    gt_edi_headers(ln_idx).edi_chain_code                   := it_edi_work.edi_chain_code;                    -- ＥＤＩチェーン店コード
    gt_edi_headers(ln_idx).edi_chain_name                   := it_edi_work.edi_chain_name;                    -- ＥＤＩチェーン店名（漢字）
    gt_edi_headers(ln_idx).edi_chain_name_alt               := it_edi_work.edi_chain_name_alt;                -- ＥＤＩチェーン店名（カナ）
    gt_edi_headers(ln_idx).chain_code                       := it_edi_work.chain_code;                        -- チェーン店コード
    gt_edi_headers(ln_idx).chain_name                       := it_edi_work.chain_name;                        -- チェーン店名（漢字）
    gt_edi_headers(ln_idx).chain_name_alt                   := it_edi_work.chain_name_alt;                    -- チェーン店名（カナ）
    gt_edi_headers(ln_idx).report_code                      := it_edi_work.report_code;                       -- 帳票コード
    gt_edi_headers(ln_idx).report_show_name                 := it_edi_work.report_show_name;                  -- 帳票表示名
    gt_edi_headers(ln_idx).customer_code                    := it_edi_work.customer_code;                     -- 顧客コード
    gt_edi_headers(ln_idx).customer_name                    := it_edi_work.customer_name;                     -- 顧客名（漢字）
    gt_edi_headers(ln_idx).customer_name_alt                := it_edi_work.customer_name_alt;                 -- 顧客名（カナ）
    gt_edi_headers(ln_idx).company_code                     := it_edi_work.company_code;                      -- 社コード
    gt_edi_headers(ln_idx).company_name                     := it_edi_work.company_name;                      -- 社名（漢字）
    gt_edi_headers(ln_idx).company_name_alt                 := it_edi_work.company_name_alt;                  -- 社名（カナ）
    gt_edi_headers(ln_idx).shop_code                        := it_edi_work.shop_code;                         -- 店コード
    gt_edi_headers(ln_idx).shop_name                        := it_edi_work.shop_name;                         -- 店名（漢字）
    gt_edi_headers(ln_idx).shop_name_alt                    := it_edi_work.shop_name_alt;                     -- 店名（カナ）
    gt_edi_headers(ln_idx).delivery_center_code             := it_edi_work.delivery_center_code;              -- 納入センターコード
    gt_edi_headers(ln_idx).delivery_center_name             := it_edi_work.delivery_center_name;              -- 納入センター名（漢字）
    gt_edi_headers(ln_idx).delivery_center_name_alt         := it_edi_work.delivery_center_name_alt;          -- 納入センター名（カナ）
    gt_edi_headers(ln_idx).order_date                       := it_edi_work.order_date;                        -- 発注日
    gt_edi_headers(ln_idx).center_delivery_date             := it_edi_work.center_delivery_date;              -- センター納品日
    gt_edi_headers(ln_idx).result_delivery_date             := it_edi_work.result_delivery_date;              -- 実納品日
    gt_edi_headers(ln_idx).shop_delivery_date               := it_edi_work.shop_delivery_date;                -- 店舗納品日
    gt_edi_headers(ln_idx).data_creation_date_edi_data      := it_edi_work.data_creation_date_edi_data;       -- データ作成日（ＥＤＩデータ中）
    gt_edi_headers(ln_idx).data_creation_time_edi_data      := it_edi_work.data_creation_time_edi_data;       -- データ作成時刻（ＥＤＩデータ中）
    gt_edi_headers(ln_idx).invoice_class                    := it_edi_work.invoice_class;                     -- 伝票区分
    gt_edi_headers(ln_idx).small_classification_code        := it_edi_work.small_classification_code;         -- 小分類コード
    gt_edi_headers(ln_idx).small_classification_name        := it_edi_work.small_classification_name;         -- 小分類名
    gt_edi_headers(ln_idx).middle_classification_code       := it_edi_work.middle_classification_code;        -- 中分類コード
    gt_edi_headers(ln_idx).middle_classification_name       := it_edi_work.middle_classification_name;        -- 中分類名
    gt_edi_headers(ln_idx).big_classification_code          := it_edi_work.big_classification_code;           -- 大分類コード
    gt_edi_headers(ln_idx).big_classification_name          := it_edi_work.big_classification_name;           -- 大分類名
    gt_edi_headers(ln_idx).other_party_department_code      := it_edi_work.other_party_department_code;       -- 相手先部門コード
    gt_edi_headers(ln_idx).other_party_order_number         := it_edi_work.other_party_order_number;          -- 相手先発注番号
    gt_edi_headers(ln_idx).check_digit_class                := it_edi_work.check_digit_class;                 -- チェックデジット有無区分
    gt_edi_headers(ln_idx).invoice_number                   := it_edi_work.invoice_number;                    -- 伝票番号
    gt_edi_headers(ln_idx).check_digit                      := it_edi_work.check_digit;                       -- チェックデジット
    gt_edi_headers(ln_idx).close_date                       := it_edi_work.close_date;                        -- 月限
    gt_edi_headers(ln_idx).order_no_ebs                     := it_edi_work.order_no_ebs;                      -- 受注Ｎｏ（ＥＢＳ）
    gt_edi_headers(ln_idx).ar_sale_class                    := it_edi_work.ar_sale_class;                     -- 特売区分
    gt_edi_headers(ln_idx).delivery_classe                  := it_edi_work.delivery_classe;                   -- 配送区分
    gt_edi_headers(ln_idx).opportunity_no                   := it_edi_work.opportunity_no;                    -- 便Ｎｏ
    gt_edi_headers(ln_idx).contact_to                       := it_edi_work.contact_to;                        -- 連絡先
    gt_edi_headers(ln_idx).route_sales                      := it_edi_work.route_sales;                       -- ルートセールス
    gt_edi_headers(ln_idx).corporate_code                   := it_edi_work.corporate_code;                    -- 法人コード
    gt_edi_headers(ln_idx).maker_name                       := it_edi_work.maker_name;                        -- メーカー名
    gt_edi_headers(ln_idx).area_code                        := it_edi_work.area_code;                         -- 地区コード
    gt_edi_headers(ln_idx).area_name                        := it_edi_work.area_name;                         -- 地区名（漢字）
    gt_edi_headers(ln_idx).area_name_alt                    := it_edi_work.area_name_alt;                     -- 地区名（カナ）
    gt_edi_headers(ln_idx).vendor_code                      := it_edi_work.vendor_code;                       -- 取引先コード
    gt_edi_headers(ln_idx).vendor_name                      := it_edi_work.vendor_name;                       -- 取引先名（漢字）
    gt_edi_headers(ln_idx).vendor_name1_alt                 := it_edi_work.vendor_name1_alt;                  -- 取引先名１（カナ）
    gt_edi_headers(ln_idx).vendor_name2_alt                 := it_edi_work.vendor_name2_alt;                  -- 取引先名２（カナ）
    gt_edi_headers(ln_idx).vendor_tel                       := it_edi_work.vendor_tel;                        -- 取引先ＴＥＬ
    gt_edi_headers(ln_idx).vendor_charge                    := it_edi_work.vendor_charge;                     -- 取引先担当者
    gt_edi_headers(ln_idx).vendor_address                   := it_edi_work.vendor_address;                    -- 取引先住所（漢字）
    gt_edi_headers(ln_idx).deliver_to_code_itouen           := it_edi_work.deliver_to_code_itouen;            -- 届け先コード（伊藤園）
    gt_edi_headers(ln_idx).deliver_to_code_chain            := it_edi_work.deliver_to_code_chain;             -- 届け先コード（チェーン店）
    gt_edi_headers(ln_idx).deliver_to                       := it_edi_work.deliver_to;                        -- 届け先（漢字）
    gt_edi_headers(ln_idx).deliver_to1_alt                  := it_edi_work.deliver_to1_alt;                   -- 届け先１（カナ）
    gt_edi_headers(ln_idx).deliver_to2_alt                  := it_edi_work.deliver_to2_alt;                   -- 届け先２（カナ）
    gt_edi_headers(ln_idx).deliver_to_address               := it_edi_work.deliver_to_address;                -- 届け先住所（漢字）
    gt_edi_headers(ln_idx).deliver_to_address_alt           := it_edi_work.deliver_to_address_alt;            -- 届け先住所（カナ）
    gt_edi_headers(ln_idx).deliver_to_tel                   := it_edi_work.deliver_to_tel;                    -- 届け先ＴＥＬ
    gt_edi_headers(ln_idx).balance_accounts_code            := it_edi_work.balance_accounts_code;             -- 帳合先コード
    gt_edi_headers(ln_idx).balance_accounts_company_code    := it_edi_work.balance_accounts_company_code;     -- 帳合先社コード
    gt_edi_headers(ln_idx).balance_accounts_shop_code       := it_edi_work.balance_accounts_shop_code;        -- 帳合先店コード
    gt_edi_headers(ln_idx).balance_accounts_name            := it_edi_work.balance_accounts_name;             -- 帳合先名（漢字）
    gt_edi_headers(ln_idx).balance_accounts_name_alt        := it_edi_work.balance_accounts_name_alt;         -- 帳合先名（カナ）
    gt_edi_headers(ln_idx).balance_accounts_address         := it_edi_work.balance_accounts_address;          -- 帳合先住所（漢字）
    gt_edi_headers(ln_idx).balance_accounts_address_alt     := it_edi_work.balance_accounts_address_alt;      -- 帳合先住所（カナ）
    gt_edi_headers(ln_idx).balance_accounts_tel             := it_edi_work.balance_accounts_tel;              -- 帳合先ＴＥＬ
    gt_edi_headers(ln_idx).order_possible_date              := it_edi_work.order_possible_date;               -- 受注可能日
    gt_edi_headers(ln_idx).permission_possible_date         := it_edi_work.permission_possible_date;          -- 許容可能日
    gt_edi_headers(ln_idx).forward_month                    := it_edi_work.forward_month;                     -- 先限年月日
    gt_edi_headers(ln_idx).payment_settlement_date          := it_edi_work.payment_settlement_date;           -- 支払決済日
    gt_edi_headers(ln_idx).handbill_start_date_active       := it_edi_work.handbill_start_date_active;        -- チラシ開始日
    gt_edi_headers(ln_idx).billing_due_date                 := it_edi_work.billing_due_date;                  -- 請求締日
    gt_edi_headers(ln_idx).shipping_time                    := it_edi_work.shipping_time;                     -- 出荷時刻
    gt_edi_headers(ln_idx).delivery_schedule_time           := it_edi_work.delivery_schedule_time;            -- 納品予定時間
    gt_edi_headers(ln_idx).order_time                       := it_edi_work.order_time;                        -- 発注時間
    gt_edi_headers(ln_idx).general_date_item1               := it_edi_work.general_date_item1;                -- 汎用日付項目１
    gt_edi_headers(ln_idx).general_date_item2               := it_edi_work.general_date_item2;                -- 汎用日付項目２
    gt_edi_headers(ln_idx).general_date_item3               := it_edi_work.general_date_item3;                -- 汎用日付項目３
    gt_edi_headers(ln_idx).general_date_item4               := it_edi_work.general_date_item4;                -- 汎用日付項目４
    gt_edi_headers(ln_idx).general_date_item5               := it_edi_work.general_date_item5;                -- 汎用日付項目５
    gt_edi_headers(ln_idx).arrival_shipping_class           := it_edi_work.arrival_shipping_class;            -- 入出荷区分
    gt_edi_headers(ln_idx).vendor_class                     := it_edi_work.vendor_class;                      -- 取引先区分
    gt_edi_headers(ln_idx).invoice_detailed_class           := it_edi_work.invoice_detailed_class;            -- 伝票内訳区分
    gt_edi_headers(ln_idx).unit_price_use_class             := it_edi_work.unit_price_use_class;              -- 単価使用区分
    gt_edi_headers(ln_idx).sub_distribution_center_code     := it_edi_work.sub_distribution_center_code;      -- サブ物流センターコード
    gt_edi_headers(ln_idx).sub_distribution_center_name     := it_edi_work.sub_distribution_center_name;      -- サブ物流センターコード名
    gt_edi_headers(ln_idx).center_delivery_method           := it_edi_work.center_delivery_method;            -- センター納品方法
    gt_edi_headers(ln_idx).center_use_class                 := it_edi_work.center_use_class;                  -- センター利用区分
    gt_edi_headers(ln_idx).center_whse_class                := it_edi_work.center_whse_class;                 -- センター倉庫区分
    gt_edi_headers(ln_idx).center_area_class                := it_edi_work.center_area_class;                 -- センター地域区分
    gt_edi_headers(ln_idx).center_arrival_class             := it_edi_work.center_arrival_class;              -- センター入荷区分
    gt_edi_headers(ln_idx).depot_class                      := it_edi_work.depot_class;                       -- デポ区分
    gt_edi_headers(ln_idx).tcdc_class                       := it_edi_work.tcdc_class;                        -- ＴＣＤＣ区分
    gt_edi_headers(ln_idx).upc_flag                         := it_edi_work.upc_flag;                          -- ＵＰＣフラグ
    gt_edi_headers(ln_idx).simultaneously_class             := it_edi_work.simultaneously_class;              -- 一斉区分
    gt_edi_headers(ln_idx).business_id                      := it_edi_work.business_id;                       -- 業務ＩＤ
    gt_edi_headers(ln_idx).whse_directly_class              := it_edi_work.whse_directly_class;               -- 倉直区分
    gt_edi_headers(ln_idx).premium_rebate_class             := it_edi_work.premium_rebate_class;              -- 景品割戻区分
    gt_edi_headers(ln_idx).item_type                        := it_edi_work.item_type;                         -- 項目種別
    gt_edi_headers(ln_idx).cloth_house_food_class           := it_edi_work.cloth_house_food_class;            -- 衣家食区分
    gt_edi_headers(ln_idx).mix_class                        := it_edi_work.mix_class;                         -- 混在区分
    gt_edi_headers(ln_idx).stk_class                        := it_edi_work.stk_class;                         -- 在庫区分
    gt_edi_headers(ln_idx).last_modify_site_class           := it_edi_work.last_modify_site_class;            -- 最終修正場所区分
    gt_edi_headers(ln_idx).report_class                     := it_edi_work.report_class;                      -- 帳票区分
    gt_edi_headers(ln_idx).addition_plan_class              := it_edi_work.addition_plan_class;               -- 追加・計画区分
    gt_edi_headers(ln_idx).registration_class               := it_edi_work.registration_class;                -- 登録区分
    gt_edi_headers(ln_idx).specific_class                   := it_edi_work.specific_class;                    -- 特定区分
    gt_edi_headers(ln_idx).dealings_class                   := it_edi_work.dealings_class;                    -- 取引区分
    gt_edi_headers(ln_idx).order_class                      := it_edi_work.order_class;                       -- 発注区分
    gt_edi_headers(ln_idx).sum_line_class                   := it_edi_work.sum_line_class;                    -- 集計明細区分
    gt_edi_headers(ln_idx).shipping_guidance_class          := it_edi_work.shipping_guidance_class;           -- 出荷案内以外区分
    gt_edi_headers(ln_idx).shipping_class                   := it_edi_work.shipping_class;                    -- 出荷区分
    gt_edi_headers(ln_idx).product_code_use_class           := it_edi_work.product_code_use_class;            -- 商品コード使用区分
    gt_edi_headers(ln_idx).cargo_item_class                 := it_edi_work.cargo_item_class;                  -- 積送品区分
    gt_edi_headers(ln_idx).ta_class                         := it_edi_work.ta_class;                          -- Ｔ／Ａ区分
    gt_edi_headers(ln_idx).plan_code                        := it_edi_work.plan_code;                         -- 企画コード
    gt_edi_headers(ln_idx).category_code                    := it_edi_work.category_code;                     -- カテゴリーコード
    gt_edi_headers(ln_idx).category_class                   := it_edi_work.category_class;                    -- カテゴリー区分
    gt_edi_headers(ln_idx).carrier_means                    := it_edi_work.carrier_means;                     -- 運送手段
    gt_edi_headers(ln_idx).counter_code                     := it_edi_work.counter_code;                      -- 売場コード
    gt_edi_headers(ln_idx).move_sign                        := it_edi_work.move_sign;                         -- 移動サイン
    gt_edi_headers(ln_idx).eos_handwriting_class            := it_edi_work.eos_handwriting_class;             -- ＥＯＳ・手書区分
    gt_edi_headers(ln_idx).delivery_to_section_code         := it_edi_work.delivery_to_section_code;          -- 納品先課コード
    gt_edi_headers(ln_idx).invoice_detailed                 := it_edi_work.invoice_detailed;                  -- 伝票内訳
    gt_edi_headers(ln_idx).attach_qty                       := it_edi_work.attach_qty;                        -- 添付数
    gt_edi_headers(ln_idx).other_party_floor                := it_edi_work.other_party_floor;                 -- フロア
    gt_edi_headers(ln_idx).text_no                          := it_edi_work.text_no;                           -- ＴＥＸＴＮｏ
    gt_edi_headers(ln_idx).in_store_code                    := it_edi_work.in_store_code;                     -- インストアコード
    gt_edi_headers(ln_idx).tag_data                         := it_edi_work.tag_data;                          -- タグ
    gt_edi_headers(ln_idx).competition_code                 := it_edi_work.competition_code;                  -- 競合
    gt_edi_headers(ln_idx).billing_chair                    := it_edi_work.billing_chair;                     -- 請求口座
    gt_edi_headers(ln_idx).chain_store_code                 := it_edi_work.chain_store_code;                  -- チェーンストアーコード
    gt_edi_headers(ln_idx).chain_store_short_name           := it_edi_work.chain_store_short_name;            -- チェーンストアーコード略式名称
    gt_edi_headers(ln_idx).direct_delivery_rcpt_fee         := it_edi_work.direct_delivery_rcpt_fee;          -- 直配送／引取料
    gt_edi_headers(ln_idx).bill_info                        := it_edi_work.bill_info;                         -- 手形情報
    gt_edi_headers(ln_idx).description                      := it_edi_work.description;                       -- 摘要
    gt_edi_headers(ln_idx).interior_code                    := it_edi_work.interior_code;                     -- 内部コード
    gt_edi_headers(ln_idx).order_info_delivery_category     := it_edi_work.order_info_delivery_category;      -- 発注情報　納品カテゴリー
    gt_edi_headers(ln_idx).purchase_type                    := it_edi_work.purchase_type;                     -- 仕入形態
    gt_edi_headers(ln_idx).delivery_to_name_alt             := it_edi_work.delivery_to_name_alt;              -- 納品場所名（カナ）
    gt_edi_headers(ln_idx).shop_opened_site                 := it_edi_work.shop_opened_site;                  -- 店出場所
    gt_edi_headers(ln_idx).counter_name                     := it_edi_work.counter_name;                      -- 売場名
    gt_edi_headers(ln_idx).extension_number                 := it_edi_work.extension_number;                  -- 内線番号
    gt_edi_headers(ln_idx).charge_name                      := it_edi_work.charge_name;                       -- 担当者名
    gt_edi_headers(ln_idx).price_tag                        := it_edi_work.price_tag;                         -- 値札
    gt_edi_headers(ln_idx).tax_type                         := it_edi_work.tax_type;                          -- 税種
    gt_edi_headers(ln_idx).consumption_tax_class            := it_edi_work.consumption_tax_class;             -- 消費税区分
    gt_edi_headers(ln_idx).brand_class                      := it_edi_work.brand_class;                       -- ＢＲ
    gt_edi_headers(ln_idx).id_code                          := it_edi_work.id_code;                           -- ＩＤコード
    gt_edi_headers(ln_idx).department_code                  := it_edi_work.department_code;                   -- 百貨店コード
    gt_edi_headers(ln_idx).department_name                  := it_edi_work.department_name;                   -- 百貨店名
    gt_edi_headers(ln_idx).item_type_number                 := it_edi_work.item_type_number;                  -- 品別番号
    gt_edi_headers(ln_idx).description_department           := it_edi_work.description_department;            -- 摘要（百貨店）
    gt_edi_headers(ln_idx).price_tag_method                 := it_edi_work.price_tag_method;                  -- 値札方法
    gt_edi_headers(ln_idx).reason_column                    := it_edi_work.reason_column;                     -- 自由欄
    gt_edi_headers(ln_idx).a_column_header                  := it_edi_work.a_column_header;                   -- Ａ欄ヘッダ
    gt_edi_headers(ln_idx).d_column_header                  := it_edi_work.d_column_header;                   -- Ｄ欄ヘッダ
    gt_edi_headers(ln_idx).brand_code                       := it_edi_work.brand_code;                        -- ブランドコード
    gt_edi_headers(ln_idx).line_code                        := it_edi_work.line_code;                         -- ラインコード
    gt_edi_headers(ln_idx).class_code                       := it_edi_work.class_code;                        -- クラスコード
    gt_edi_headers(ln_idx).a1_column                        := it_edi_work.a1_column;                         -- Ａ－１欄
    gt_edi_headers(ln_idx).b1_column                        := it_edi_work.b1_column;                         -- Ｂ－１欄
    gt_edi_headers(ln_idx).c1_column                        := it_edi_work.c1_column;                         -- Ｃ－１欄
    gt_edi_headers(ln_idx).d1_column                        := it_edi_work.d1_column;                         -- Ｄ－１欄
    gt_edi_headers(ln_idx).e1_column                        := it_edi_work.e1_column;                         -- Ｅ－１欄
    gt_edi_headers(ln_idx).a2_column                        := it_edi_work.a2_column;                         -- Ａ－２欄
    gt_edi_headers(ln_idx).b2_column                        := it_edi_work.b2_column;                         -- Ｂ－２欄
    gt_edi_headers(ln_idx).c2_column                        := it_edi_work.c2_column;                         -- Ｃ－２欄
    gt_edi_headers(ln_idx).d2_column                        := it_edi_work.d2_column;                         -- Ｄ－２欄
    gt_edi_headers(ln_idx).e2_column                        := it_edi_work.e2_column;                         -- Ｅ－２欄
    gt_edi_headers(ln_idx).a3_column                        := it_edi_work.a3_column;                         -- Ａ－３欄
    gt_edi_headers(ln_idx).b3_column                        := it_edi_work.b3_column;                         -- Ｂ－３欄
    gt_edi_headers(ln_idx).c3_column                        := it_edi_work.c3_column;                         -- Ｃ－３欄
    gt_edi_headers(ln_idx).d3_column                        := it_edi_work.d3_column;                         -- Ｄ－３欄
    gt_edi_headers(ln_idx).e3_column                        := it_edi_work.e3_column;                         -- Ｅ－３欄
    gt_edi_headers(ln_idx).f1_column                        := it_edi_work.f1_column;                         -- Ｆ－１欄
    gt_edi_headers(ln_idx).g1_column                        := it_edi_work.g1_column;                         -- Ｇ－１欄
    gt_edi_headers(ln_idx).h1_column                        := it_edi_work.h1_column;                         -- Ｈ－１欄
    gt_edi_headers(ln_idx).i1_column                        := it_edi_work.i1_column;                         -- Ｉ－１欄
    gt_edi_headers(ln_idx).j1_column                        := it_edi_work.j1_column;                         -- Ｊ－１欄
    gt_edi_headers(ln_idx).k1_column                        := it_edi_work.k1_column;                         -- Ｋ－１欄
    gt_edi_headers(ln_idx).l1_column                        := it_edi_work.l1_column;                         -- Ｌ－１欄
    gt_edi_headers(ln_idx).f2_column                        := it_edi_work.f2_column;                         -- Ｆ－２欄
    gt_edi_headers(ln_idx).g2_column                        := it_edi_work.g2_column;                         -- Ｇ－２欄
    gt_edi_headers(ln_idx).h2_column                        := it_edi_work.h2_column;                         -- Ｈ－２欄
    gt_edi_headers(ln_idx).i2_column                        := it_edi_work.i2_column;                         -- Ｉ－２欄
    gt_edi_headers(ln_idx).j2_column                        := it_edi_work.j2_column;                         -- Ｊ－２欄
    gt_edi_headers(ln_idx).k2_column                        := it_edi_work.k2_column;                         -- Ｋ－２欄
    gt_edi_headers(ln_idx).l2_column                        := it_edi_work.l2_column;                         -- Ｌ－２欄
    gt_edi_headers(ln_idx).f3_column                        := it_edi_work.f3_column;                         -- Ｆ－３欄
    gt_edi_headers(ln_idx).g3_column                        := it_edi_work.g3_column;                         -- Ｇ－３欄
    gt_edi_headers(ln_idx).h3_column                        := it_edi_work.h3_column;                         -- Ｈ－３欄
    gt_edi_headers(ln_idx).i3_column                        := it_edi_work.i3_column;                         -- Ｉ－３欄
    gt_edi_headers(ln_idx).j3_column                        := it_edi_work.j3_column;                         -- Ｊ－３欄
    gt_edi_headers(ln_idx).k3_column                        := it_edi_work.k3_column;                         -- Ｋ－３欄
    gt_edi_headers(ln_idx).l3_column                        := it_edi_work.l3_column;                         -- Ｌ－３欄
    gt_edi_headers(ln_idx).chain_peculiar_area_header       := it_edi_work.chain_peculiar_area_header;        -- チェーン店固有エリア（ヘッダー）
    gt_edi_headers(ln_idx).order_connection_number          := ln_seq_2;                                      -- 受注関連番号
    gt_edi_headers(ln_idx).invoice_indv_order_qty           := it_edi_work.invoice_indv_order_qty;            -- （伝票計）発注数量（バラ）
    gt_edi_headers(ln_idx).invoice_case_order_qty           := it_edi_work.invoice_case_order_qty;            -- （伝票計）発注数量（ケース）
    gt_edi_headers(ln_idx).invoice_ball_order_qty           := it_edi_work.invoice_ball_order_qty;            -- （伝票計）発注数量（ボール）
    gt_edi_headers(ln_idx).invoice_sum_order_qty            := it_edi_work.invoice_sum_order_qty;             -- （伝票計）発注数量（合計、バラ）
    gt_edi_headers(ln_idx).invoice_indv_shipping_qty        := it_edi_work.invoice_indv_shipping_qty;         -- （伝票計）出荷数量（バラ）
    gt_edi_headers(ln_idx).invoice_case_shipping_qty        := it_edi_work.invoice_case_shipping_qty;         -- （伝票計）出荷数量（ケース）
    gt_edi_headers(ln_idx).invoice_ball_shipping_qty        := it_edi_work.invoice_ball_shipping_qty;         -- （伝票計）出荷数量（ボール）
    gt_edi_headers(ln_idx).invoice_pallet_shipping_qty      := it_edi_work.invoice_pallet_shipping_qty;       -- （伝票計）出荷数量（パレット）
    gt_edi_headers(ln_idx).invoice_sum_shipping_qty         := it_edi_work.invoice_sum_shipping_qty;          -- （伝票計）出荷数量（合計、バラ）
    gt_edi_headers(ln_idx).invoice_indv_stockout_qty        := it_edi_work.invoice_indv_stockout_qty;         -- （伝票計）欠品数量（バラ）
    gt_edi_headers(ln_idx).invoice_case_stockout_qty        := it_edi_work.invoice_case_stockout_qty;         -- （伝票計）欠品数量（ケース）
    gt_edi_headers(ln_idx).invoice_ball_stockout_qty        := it_edi_work.invoice_ball_stockout_qty;         -- （伝票計）欠品数量（ボール）
    gt_edi_headers(ln_idx).invoice_sum_stockout_qty         := it_edi_work.invoice_sum_stockout_qty;          -- （伝票計）欠品数量（合計、バラ）
    gt_edi_headers(ln_idx).invoice_case_qty                 := it_edi_work.invoice_case_qty;                  -- （伝票計）ケース個口数
    gt_edi_headers(ln_idx).invoice_fold_container_qty       := it_edi_work.invoice_fold_container_qty;        -- （伝票計）オリコン（バラ）個口数
    gt_edi_headers(ln_idx).invoice_order_cost_amt           := it_edi_work.invoice_order_cost_amt;            -- （伝票計）原価金額（発注）
    gt_edi_headers(ln_idx).invoice_shipping_cost_amt        := it_edi_work.invoice_shipping_cost_amt;         -- （伝票計）原価金額（出荷）
    gt_edi_headers(ln_idx).invoice_stockout_cost_amt        := it_edi_work.invoice_stockout_cost_amt;         -- （伝票計）原価金額（欠品）
    gt_edi_headers(ln_idx).invoice_order_price_amt          := it_edi_work.invoice_order_price_amt;           -- （伝票計）売価金額（発注）
    gt_edi_headers(ln_idx).invoice_shipping_price_amt       := it_edi_work.invoice_shipping_price_amt;        -- （伝票計）売価金額（出荷）
    gt_edi_headers(ln_idx).invoice_stockout_price_amt       := it_edi_work.invoice_stockout_price_amt;        -- （伝票計）売価金額（欠品）
    gt_edi_headers(ln_idx).total_indv_order_qty             := it_edi_work.total_indv_order_qty;              -- （総合計）発注数量（バラ）
    gt_edi_headers(ln_idx).total_case_order_qty             := it_edi_work.total_case_order_qty;              -- （総合計）発注数量（ケース）
    gt_edi_headers(ln_idx).total_ball_order_qty             := it_edi_work.total_ball_order_qty;              -- （総合計）発注数量（ボール）
    gt_edi_headers(ln_idx).total_sum_order_qty              := it_edi_work.total_sum_order_qty;               -- （総合計）発注数量（合計、バラ）
    gt_edi_headers(ln_idx).total_indv_shipping_qty          := it_edi_work.total_indv_shipping_qty;           -- （総合計）出荷数量（バラ）
    gt_edi_headers(ln_idx).total_case_shipping_qty          := it_edi_work.total_case_shipping_qty;           -- （総合計）出荷数量（ケース）
    gt_edi_headers(ln_idx).total_ball_shipping_qty          := it_edi_work.total_ball_shipping_qty;           -- （総合計）出荷数量（ボール）
    gt_edi_headers(ln_idx).total_pallet_shipping_qty        := it_edi_work.total_pallet_shipping_qty;         -- （総合計）出荷数量（パレット）
    gt_edi_headers(ln_idx).total_sum_shipping_qty           := it_edi_work.total_sum_shipping_qty;            -- （総合計）出荷数量（合計、バラ）
    gt_edi_headers(ln_idx).total_indv_stockout_qty          := it_edi_work.total_indv_stockout_qty;           -- （総合計）欠品数量（バラ）
    gt_edi_headers(ln_idx).total_case_stockout_qty          := it_edi_work.total_case_stockout_qty;           -- （総合計）欠品数量（ケース）
    gt_edi_headers(ln_idx).total_ball_stockout_qty          := it_edi_work.total_ball_stockout_qty;           -- （総合計）欠品数量（ボール）
    gt_edi_headers(ln_idx).total_sum_stockout_qty           := it_edi_work.total_sum_stockout_qty;            -- （総合計）欠品数量（合計、バラ）
    gt_edi_headers(ln_idx).total_case_qty                   := it_edi_work.total_case_qty;                    -- （総合計）ケース個口数
    gt_edi_headers(ln_idx).total_fold_container_qty         := it_edi_work.total_fold_container_qty;          -- （総合計）オリコン（バラ）個口数
    gt_edi_headers(ln_idx).total_order_cost_amt             := it_edi_work.total_order_cost_amt;              -- （総合計）原価金額（発注）
    gt_edi_headers(ln_idx).total_shipping_cost_amt          := it_edi_work.total_shipping_cost_amt;           -- （総合計）原価金額（出荷）
    gt_edi_headers(ln_idx).total_stockout_cost_amt          := it_edi_work.total_stockout_cost_amt;           -- （総合計）原価金額（欠品）
    gt_edi_headers(ln_idx).total_order_price_amt            := it_edi_work.total_order_price_amt;             -- （総合計）売価金額（発注）
    gt_edi_headers(ln_idx).total_shipping_price_amt         := it_edi_work.total_shipping_price_amt;          -- （総合計）売価金額（出荷）
    gt_edi_headers(ln_idx).total_stockout_price_amt         := it_edi_work.total_stockout_price_amt;          -- （総合計）売価金額（欠品）
    gt_edi_headers(ln_idx).total_line_qty                   := it_edi_work.total_line_qty;                    -- トータル行数
    gt_edi_headers(ln_idx).total_invoice_qty                := it_edi_work.total_invoice_qty;                 -- トータル伝票枚数
    gt_edi_headers(ln_idx).chain_peculiar_area_footer       := it_edi_work.chain_peculiar_area_footer;        -- チェーン店固有エリア（フッター）
    gt_edi_headers(ln_idx).conv_customer_code               := it_edi_work.conv_customer_code;                -- 変換後顧客コード
-- 2009/12/28 M.Sano Ver.1.14 mod Start
--    gt_edi_headers(ln_idx).order_forward_flag               := cv_order_forward_flag;                         -- 受注連携済フラグ
    gt_edi_headers(ln_idx).order_forward_flag               := it_edi_work.order_forward_flag;                -- 受注連携済フラグ
-- 2009/12/28 M.Sano Ver.1.14 mod End
    gt_edi_headers(ln_idx).creation_class                   := gv_creation_class;                             -- 作成元区分：受注
    gt_edi_headers(ln_idx).edi_delivery_schedule_flag       := cv_edi_delivery_flag;                          -- EDI納品予定送信済フラグ
    gt_edi_headers(ln_idx).price_list_header_id             := it_edi_work.price_list_header_id;              -- 価格表ヘッダID
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_edi_headers(ln_idx).tsukagatazaiko_div               := it_edi_work.tsukagatazaiko_div;                -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver1.15 M.Sano Add Start
    gt_edi_headers(ln_idx).edi_received_date                := it_edi_work.creation_date;                     -- EDI受信日
-- 2010/01/19 Ver1.15 M.Sano Add End
    gt_edi_headers(ln_idx).created_by                       := cn_created_by;                                 -- 作成者
    gt_edi_headers(ln_idx).creation_date                    := cd_creation_date;                              -- 作成日
    gt_edi_headers(ln_idx).last_updated_by                  := cn_last_updated_by;                            -- 最終更新者
    gt_edi_headers(ln_idx).last_update_date                 := cd_last_update_date;                           -- 最終更新日
    gt_edi_headers(ln_idx).last_update_login                := cn_last_update_login;                          -- 最終更新ログイン
    gt_edi_headers(ln_idx).request_id                       := cn_request_id;                                 -- 要求ID
    gt_edi_headers(ln_idx).program_application_id           := cn_program_application_id;                     -- コンカレント・プログラム・アプリケーションID
    gt_edi_headers(ln_idx).program_id                       := cn_program_id;                                 -- コンカレント・プログラムID
    gt_edi_headers(ln_idx).program_update_date              := cd_program_update_date;                        -- プログラム更新日
--
  EXCEPTION
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
  END proc_set_ins_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_upd_headers
   * Description      : EDIヘッダ情報アップデート用変数格納(A-9)
   ***********************************************************************************/
  PROCEDURE proc_set_upd_headers(
    it_edi_work   IN  g_edi_work_rtype,    -- EDI受注情報ワークレコード
    in_edi_header_info_id IN NUMBER,       -- EDIヘッダ情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_upd_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    ln_idx := gt_upd_edi_header_info_id.COUNT + 1;
--
    gt_upd_edi_header_info_id(ln_idx)                  := in_edi_header_info_id;                         -- EDIヘッダ情報ID
    gt_upd_medium_class(ln_idx)                        := it_edi_work.medium_class;                      -- 媒体区分
    gt_upd_data_type_code(ln_idx)                      := it_edi_work.data_type_code;                    -- データ種コード
    gt_upd_file_no(ln_idx)                             := it_edi_work.file_no;                           -- ファイルＮｏ
    gt_upd_info_class(ln_idx)                          := it_edi_work.info_class;                        -- 情報区分
    gt_upd_process_date(ln_idx)                        := it_edi_work.process_date;                      -- 処理日
    gt_upd_process_time(ln_idx)                        := it_edi_work.process_time;                      -- 処理時刻
    gt_upd_base_code(ln_idx)                           := it_edi_work.base_code;                         -- 拠点（部門）コード
    gt_upd_base_name(ln_idx)                           := it_edi_work.base_name;                         -- 拠点名（正式名）
    gt_upd_base_name_alt(ln_idx)                       := it_edi_work.base_name_alt;                     -- 拠点名（カナ）
    gt_upd_edi_chain_code(ln_idx)                      := it_edi_work.edi_chain_code;                    -- ＥＤＩチェーン店コード
    gt_upd_edi_chain_name(ln_idx)                      := it_edi_work.edi_chain_name;                    -- ＥＤＩチェーン店名（漢字）
    gt_upd_edi_chain_name_alt(ln_idx)                  := it_edi_work.edi_chain_name_alt;                -- ＥＤＩチェーン店名（カナ）
    gt_upd_chain_code(ln_idx)                          := it_edi_work.chain_code;                        -- チェーン店コード
    gt_upd_chain_name(ln_idx)                          := it_edi_work.chain_name;                        -- チェーン店名（漢字）
    gt_upd_chain_name_alt(ln_idx)                      := it_edi_work.chain_name_alt;                    -- チェーン店名（カナ）
    gt_upd_report_code(ln_idx)                         := it_edi_work.report_code;                       -- 帳票コード
    gt_upd_report_show_name(ln_idx)                    := it_edi_work.report_show_name;                  -- 帳票表示名
    gt_upd_customer_code(ln_idx)                       := it_edi_work.customer_code;                     -- 顧客コード
    gt_upd_customer_name(ln_idx)                       := it_edi_work.customer_name;                     -- 顧客名（漢字）
    gt_upd_customer_name_alt(ln_idx)                   := it_edi_work.customer_name_alt;                 -- 顧客名（カナ）
    gt_upd_company_code(ln_idx)                        := it_edi_work.company_code;                      -- 社コード
    gt_upd_company_name(ln_idx)                        := it_edi_work.company_name;                      -- 社名（漢字）
    gt_upd_company_name_alt(ln_idx)                    := it_edi_work.company_name_alt;                  -- 社名（カナ）
    gt_upd_shop_code(ln_idx)                           := it_edi_work.shop_code;                         -- 店コード
    gt_upd_shop_name(ln_idx)                           := it_edi_work.shop_name;                         -- 店名（漢字）
    gt_upd_shop_name_alt(ln_idx)                       := it_edi_work.shop_name_alt;                     -- 店名（カナ）
    gt_upd_delivery_cent_cd(ln_idx)                    := it_edi_work.delivery_center_code;              -- 納入センターコード
    gt_upd_delivery_cent_nm(ln_idx)                    := it_edi_work.delivery_center_name;              -- 納入センター名（漢字）
    gt_upd_delivery_cent_nm_alt(ln_idx)                := it_edi_work.delivery_center_name_alt;          -- 納入センター名（カナ）
    gt_upd_order_date(ln_idx)                          := it_edi_work.order_date;                        -- 発注日
    gt_upd_center_delivery_date(ln_idx)                := it_edi_work.center_delivery_date;              -- センター納品日
    gt_upd_result_delivery_date(ln_idx)                := it_edi_work.result_delivery_date;              -- 実納品日
    gt_upd_shop_delivery_date(ln_idx)                  := it_edi_work.shop_delivery_date;                -- 店舗納品日
    gt_upd_data_creation_date_edi(ln_idx)              := it_edi_work.data_creation_date_edi_data;       -- データ作成日（ＥＤＩデータ中）
    gt_upd_data_creation_time_edi(ln_idx)              := it_edi_work.data_creation_time_edi_data;       -- データ作成時刻（ＥＤＩデータ中）
    gt_upd_invoice_class(ln_idx)                       := it_edi_work.invoice_class;                     -- 伝票区分
    gt_upd_small_class_cd(ln_idx)                      := it_edi_work.small_classification_code;         -- 小分類コード
    gt_upd_small_class_nm(ln_idx)                      := it_edi_work.small_classification_name;         -- 小分類名
    gt_upd_middle_class_cd(ln_idx)                     := it_edi_work.middle_classification_code;        -- 中分類コード
    gt_upd_middle_class_nm(ln_idx)                     := it_edi_work.middle_classification_name;        -- 中分類名
    gt_upd_big_class_cd(ln_idx)                        := it_edi_work.big_classification_code;           -- 大分類コード
    gt_upd_big_class_nm(ln_idx)                        := it_edi_work.big_classification_name;           -- 大分類名
    gt_upd_other_party_depart_cd(ln_idx)               := it_edi_work.other_party_department_code;       -- 相手先部門コード
    gt_upd_other_party_order_num(ln_idx)               := it_edi_work.other_party_order_number;          -- 相手先発注番号
    gt_upd_check_digit_class(ln_idx)                   := it_edi_work.check_digit_class;                 -- チェックデジット有無区分
    gt_upd_invoice_number(ln_idx)                      := it_edi_work.invoice_number;                    -- 伝票番号
    gt_upd_check_digit(ln_idx)                         := it_edi_work.check_digit;                       -- チェックデジット
    gt_upd_close_date(ln_idx)                          := it_edi_work.close_date;                        -- 月限
    gt_upd_order_no_ebs(ln_idx)                        := it_edi_work.order_no_ebs;                      -- 受注Ｎｏ（ＥＢＳ）
    gt_upd_ar_sale_class(ln_idx)                       := it_edi_work.ar_sale_class;                     -- 特売区分
    gt_upd_delivery_classe(ln_idx)                     := it_edi_work.delivery_classe;                   -- 配送区分
    gt_upd_opportunity_no(ln_idx)                      := it_edi_work.opportunity_no;                    -- 便Ｎｏ
    gt_upd_contact_to(ln_idx)                          := it_edi_work.contact_to;                        -- 連絡先
    gt_upd_route_sales(ln_idx)                         := it_edi_work.route_sales;                       -- ルートセールス
    gt_upd_corporate_code(ln_idx)                      := it_edi_work.corporate_code;                    -- 法人コード
    gt_upd_maker_name(ln_idx)                          := it_edi_work.maker_name;                        -- メーカー名
    gt_upd_area_code(ln_idx)                           := it_edi_work.area_code;                         -- 地区コード
    gt_upd_area_name(ln_idx)                           := it_edi_work.area_name;                         -- 地区名（漢字）
    gt_upd_area_name_alt(ln_idx)                       := it_edi_work.area_name_alt;                     -- 地区名（カナ）
    gt_upd_vendor_code(ln_idx)                         := it_edi_work.vendor_code;                       -- 取引先コード
    gt_upd_vendor_name(ln_idx)                         := it_edi_work.vendor_name;                       -- 取引先名（漢字）
    gt_upd_vendor_name1_alt(ln_idx)                    := it_edi_work.vendor_name1_alt;                  -- 取引先名１（カナ）
    gt_upd_vendor_name2_alt(ln_idx)                    := it_edi_work.vendor_name2_alt;                  -- 取引先名２（カナ）
    gt_upd_vendor_tel(ln_idx)                          := it_edi_work.vendor_tel;                        -- 取引先ＴＥＬ
    gt_upd_vendor_charge(ln_idx)                       := it_edi_work.vendor_charge;                     -- 取引先担当者
    gt_upd_vendor_address(ln_idx)                      := it_edi_work.vendor_address;                    -- 取引先住所（漢字）
    gt_upd_deliver_to_code_itouen(ln_idx)              := it_edi_work.deliver_to_code_itouen;            -- 届け先コード（伊藤園）
    gt_upd_deliver_to_code_chain(ln_idx)               := it_edi_work.deliver_to_code_chain;             -- 届け先コード（チェーン店）
    gt_upd_deliver_to(ln_idx)                          := it_edi_work.deliver_to;                        -- 届け先（漢字）
    gt_upd_deliver_to1_alt(ln_idx)                     := it_edi_work.deliver_to1_alt;                   -- 届け先１（カナ）
    gt_upd_deliver_to2_alt(ln_idx)                     := it_edi_work.deliver_to2_alt;                   -- 届け先２（カナ）
    gt_upd_deliver_to_address(ln_idx)                  := it_edi_work.deliver_to_address;                -- 届け先住所（漢字）
    gt_upd_deliver_to_address_alt(ln_idx)              := it_edi_work.deliver_to_address_alt;            -- 届け先住所（カナ）
    gt_upd_deliver_to_tel(ln_idx)                      := it_edi_work.deliver_to_tel;                    -- 届け先ＴＥＬ
    gt_upd_balance_acct_cd(ln_idx)                     := it_edi_work.balance_accounts_code;             -- 帳合先コード
    gt_upd_balance_acct_company_cd(ln_idx)             := it_edi_work.balance_accounts_company_code;     -- 帳合先社コード
    gt_upd_balance_acct_shop_cd(ln_idx)                := it_edi_work.balance_accounts_shop_code;        -- 帳合先店コード
    gt_upd_balance_acct_nm(ln_idx)                     := it_edi_work.balance_accounts_name;             -- 帳合先名（漢字）
    gt_upd_balance_acct_nm_alt(ln_idx)                 := it_edi_work.balance_accounts_name_alt;         -- 帳合先名（カナ）
    gt_upd_balance_acct_addr(ln_idx)                   := it_edi_work.balance_accounts_address;          -- 帳合先住所（漢字）
    gt_upd_balance_acct_addr_alt(ln_idx)               := it_edi_work.balance_accounts_address_alt;      -- 帳合先住所（カナ）
    gt_upd_balance_acct_tel(ln_idx)                    := it_edi_work.balance_accounts_tel;              -- 帳合先ＴＥＬ
    gt_upd_order_possible_date(ln_idx)                 := it_edi_work.order_possible_date;               -- 受注可能日
    gt_upd_permit_possible_date(ln_idx)                := it_edi_work.permission_possible_date;          -- 許容可能日
    gt_upd_forward_month(ln_idx)                       := it_edi_work.forward_month;                     -- 先限年月日
    gt_upd_payment_settlement_date(ln_idx)             := it_edi_work.payment_settlement_date;           -- 支払決済日
    gt_upd_handbill_start_date_act(ln_idx)             := it_edi_work.handbill_start_date_active;        -- チラシ開始日
    gt_upd_billing_due_date(ln_idx)                    := it_edi_work.billing_due_date;                  -- 請求締日
    gt_upd_shipping_time(ln_idx)                       := it_edi_work.shipping_time;                     -- 出荷時刻
    gt_upd_delivery_schedule_time(ln_idx)              := it_edi_work.delivery_schedule_time;            -- 納品予定時間
    gt_upd_order_time(ln_idx)                          := it_edi_work.order_time;                        -- 発注時間
    gt_upd_general_date_item1(ln_idx)                  := it_edi_work.general_date_item1;                -- 汎用日付項目１
    gt_upd_general_date_item2(ln_idx)                  := it_edi_work.general_date_item2;                -- 汎用日付項目２
    gt_upd_general_date_item3(ln_idx)                  := it_edi_work.general_date_item3;                -- 汎用日付項目３
    gt_upd_general_date_item4(ln_idx)                  := it_edi_work.general_date_item4;                -- 汎用日付項目４
    gt_upd_general_date_item5(ln_idx)                  := it_edi_work.general_date_item5;                -- 汎用日付項目５
    gt_upd_arrival_shipping_class(ln_idx)              := it_edi_work.arrival_shipping_class;            -- 入出荷区分
    gt_upd_vendor_class(ln_idx)                        := it_edi_work.vendor_class;                      -- 取引先区分
    gt_upd_invoice_detailed_class(ln_idx)              := it_edi_work.invoice_detailed_class;            -- 伝票内訳区分
    gt_upd_unit_price_use_class(ln_idx)                := it_edi_work.unit_price_use_class;              -- 単価使用区分
    gt_upd_sub_dist_center_cd(ln_idx)                  := it_edi_work.sub_distribution_center_code;      -- サブ物流センターコード
    gt_upd_sub_dist_center_nm(ln_idx)                  := it_edi_work.sub_distribution_center_name;      -- サブ物流センターコード名
    gt_upd_center_delivery_method(ln_idx)              := it_edi_work.center_delivery_method;            -- センター納品方法
    gt_upd_center_use_class(ln_idx)                    := it_edi_work.center_use_class;                  -- センター利用区分
    gt_upd_center_whse_class(ln_idx)                   := it_edi_work.center_whse_class;                 -- センター倉庫区分
    gt_upd_center_area_class(ln_idx)                   := it_edi_work.center_area_class;                 -- センター地域区分
    gt_upd_center_arrival_class(ln_idx)                := it_edi_work.center_arrival_class;              -- センター入荷区分
    gt_upd_depot_class(ln_idx)                         := it_edi_work.depot_class;                       -- デポ区分
    gt_upd_tcdc_class(ln_idx)                          := it_edi_work.tcdc_class;                        -- ＴＣＤＣ区分
    gt_upd_upc_flag(ln_idx)                            := it_edi_work.upc_flag;                          -- ＵＰＣフラグ
    gt_upd_simultaneously_class(ln_idx)                := it_edi_work.simultaneously_class;              -- 一斉区分
    gt_upd_business_id(ln_idx)                         := it_edi_work.business_id;                       -- 業務ＩＤ
    gt_upd_whse_directly_class(ln_idx)                 := it_edi_work.whse_directly_class;               -- 倉直区分
    gt_upd_premium_rebate_class(ln_idx)                := it_edi_work.premium_rebate_class;              -- 景品割戻区分
    gt_upd_item_type(ln_idx)                           := it_edi_work.item_type;                         -- 項目種別
    gt_upd_cloth_house_food_class(ln_idx)              := it_edi_work.cloth_house_food_class;            -- 衣家食区分
    gt_upd_mix_class(ln_idx)                           := it_edi_work.mix_class;                         -- 混在区分
    gt_upd_stk_class(ln_idx)                           := it_edi_work.stk_class;                         -- 在庫区分
    gt_upd_last_modify_site_class(ln_idx)              := it_edi_work.last_modify_site_class;            -- 最終修正場所区分
    gt_upd_report_class(ln_idx)                        := it_edi_work.report_class;                      -- 帳票区分
    gt_upd_addition_plan_class(ln_idx)                 := it_edi_work.addition_plan_class;               -- 追加・計画区分
    gt_upd_registration_class(ln_idx)                  := it_edi_work.registration_class;                -- 登録区分
    gt_upd_specific_class(ln_idx)                      := it_edi_work.specific_class;                    -- 特定区分
    gt_upd_dealings_class(ln_idx)                      := it_edi_work.dealings_class;                    -- 取引区分
    gt_upd_order_class(ln_idx)                         := it_edi_work.order_class;                       -- 発注区分
    gt_upd_sum_line_class(ln_idx)                      := it_edi_work.sum_line_class;                    -- 集計明細区分
    gt_upd_shipping_guidance_class(ln_idx)             := it_edi_work.shipping_guidance_class;           -- 出荷案内以外区分
    gt_upd_shipping_class(ln_idx)                      := it_edi_work.shipping_class;                    -- 出荷区分
    gt_upd_product_code_use_class(ln_idx)              := it_edi_work.product_code_use_class;            -- 商品コード使用区分
    gt_upd_cargo_item_class(ln_idx)                    := it_edi_work.cargo_item_class;                  -- 積送品区分
    gt_upd_ta_class(ln_idx)                            := it_edi_work.ta_class;                          -- Ｔ／Ａ区分
    gt_upd_plan_code(ln_idx)                           := it_edi_work.plan_code;                         -- 企画コード
    gt_upd_category_code(ln_idx)                       := it_edi_work.category_code;                     -- カテゴリーコード
    gt_upd_category_class(ln_idx)                      := it_edi_work.category_class;                    -- カテゴリー区分
    gt_upd_carrier_means(ln_idx)                       := it_edi_work.carrier_means;                     -- 運送手段
    gt_upd_counter_code(ln_idx)                        := it_edi_work.counter_code;                      -- 売場コード
    gt_upd_move_sign(ln_idx)                           := it_edi_work.move_sign;                         -- 移動サイン
    gt_upd_eos_handwriting_class(ln_idx)               := it_edi_work.eos_handwriting_class;             -- ＥＯＳ・手書区分
    gt_upd_delivery_to_sect_cd(ln_idx)                 := it_edi_work.delivery_to_section_code;          -- 納品先課コード
    gt_upd_invoice_detailed(ln_idx)                    := it_edi_work.invoice_detailed;                  -- 伝票内訳
    gt_upd_attach_qty(ln_idx)                          := it_edi_work.attach_qty;                        -- 添付数
    gt_upd_other_party_floor(ln_idx)                   := it_edi_work.other_party_floor;                 -- フロア
    gt_upd_text_no(ln_idx)                             := it_edi_work.text_no;                           -- ＴＥＸＴＮｏ
    gt_upd_in_store_code(ln_idx)                       := it_edi_work.in_store_code;                     -- インストアコード
    gt_upd_tag_data(ln_idx)                            := it_edi_work.tag_data;                          -- タグ
    gt_upd_competition_code(ln_idx)                    := it_edi_work.competition_code;                  -- 競合
    gt_upd_billing_chair(ln_idx)                       := it_edi_work.billing_chair;                     -- 請求口座
    gt_upd_chain_store_code(ln_idx)                    := it_edi_work.chain_store_code;                  -- チェーンストアーコード
    gt_upd_chain_store_short_name(ln_idx)              := it_edi_work.chain_store_short_name;            -- チェーンストアーコード略式名称
    gt_upd_dirct_delivery_rcpt_fee(ln_idx)             := it_edi_work.direct_delivery_rcpt_fee;          -- 直配送／引取料
    gt_upd_bill_info(ln_idx)                           := it_edi_work.bill_info;                         -- 手形情報
    gt_upd_description(ln_idx)                         := it_edi_work.description;                       -- 摘要
    gt_upd_interior_code(ln_idx)                       := it_edi_work.interior_code;                     -- 内部コード
    gt_upd_order_info_delivery_cat(ln_idx)             := it_edi_work.order_info_delivery_category;      -- 発注情報　納品カテゴリー
    gt_upd_purchase_type(ln_idx)                       := it_edi_work.purchase_type;                     -- 仕入形態
    gt_upd_delivery_to_name_alt(ln_idx)                := it_edi_work.delivery_to_name_alt;              -- 納品場所名（カナ）
    gt_upd_shop_opened_site(ln_idx)                    := it_edi_work.shop_opened_site;                  -- 店出場所
    gt_upd_counter_name(ln_idx)                        := it_edi_work.counter_name;                      -- 売場名
    gt_upd_extension_number(ln_idx)                    := it_edi_work.extension_number;                  -- 内線番号
    gt_upd_charge_name(ln_idx)                         := it_edi_work.charge_name;                       -- 担当者名
    gt_upd_price_tag(ln_idx)                           := it_edi_work.price_tag;                         -- 値札
    gt_upd_tax_type(ln_idx)                            := it_edi_work.tax_type;                          -- 税種
    gt_upd_consumption_tax_class(ln_idx)               := it_edi_work.consumption_tax_class;             -- 消費税区分
    gt_upd_brand_class(ln_idx)                         := it_edi_work.brand_class;                       -- ＢＲ
    gt_upd_id_code(ln_idx)                             := it_edi_work.id_code;                           -- ＩＤコード
    gt_upd_department_code(ln_idx)                     := it_edi_work.department_code;                   -- 百貨店コード
    gt_upd_department_name(ln_idx)                     := it_edi_work.department_name;                   -- 百貨店名
    gt_upd_item_type_number(ln_idx)                    := it_edi_work.item_type_number;                  -- 品別番号
    gt_upd_description_department(ln_idx)              := it_edi_work.description_department;            -- 摘要（百貨店）
    gt_upd_price_tag_method(ln_idx)                    := it_edi_work.price_tag_method;                  -- 値札方法
    gt_upd_reason_column(ln_idx)                       := it_edi_work.reason_column;                     -- 自由欄
    gt_upd_a_column_header(ln_idx)                     := it_edi_work.a_column_header;                   -- Ａ欄ヘッダ
    gt_upd_d_column_header(ln_idx)                     := it_edi_work.d_column_header;                   -- Ｄ欄ヘッダ
    gt_upd_brand_code(ln_idx)                          := it_edi_work.brand_code;                        -- ブランドコード
    gt_upd_line_code(ln_idx)                           := it_edi_work.line_code;                         -- ラインコード
    gt_upd_class_code(ln_idx)                          := it_edi_work.class_code;                        -- クラスコード
    gt_upd_a1_column(ln_idx)                           := it_edi_work.a1_column;                         -- Ａ－１欄
    gt_upd_b1_column(ln_idx)                           := it_edi_work.b1_column;                         -- Ｂ－１欄
    gt_upd_c1_column(ln_idx)                           := it_edi_work.c1_column;                         -- Ｃ－１欄
    gt_upd_d1_column(ln_idx)                           := it_edi_work.d1_column;                         -- Ｄ－１欄
    gt_upd_e1_column(ln_idx)                           := it_edi_work.e1_column;                         -- Ｅ－１欄
    gt_upd_a2_column(ln_idx)                           := it_edi_work.a2_column;                         -- Ａ－２欄
    gt_upd_b2_column(ln_idx)                           := it_edi_work.b2_column;                         -- Ｂ－２欄
    gt_upd_c2_column(ln_idx)                           := it_edi_work.c2_column;                         -- Ｃ－２欄
    gt_upd_d2_column(ln_idx)                           := it_edi_work.d2_column;                         -- Ｄ－２欄
    gt_upd_e2_column(ln_idx)                           := it_edi_work.e2_column;                         -- Ｅ－２欄
    gt_upd_a3_column(ln_idx)                           := it_edi_work.a3_column;                         -- Ａ－３欄
    gt_upd_b3_column(ln_idx)                           := it_edi_work.b3_column;                         -- Ｂ－３欄
    gt_upd_c3_column(ln_idx)                           := it_edi_work.c3_column;                         -- Ｃ－３欄
    gt_upd_d3_column(ln_idx)                           := it_edi_work.d3_column;                         -- Ｄ－３欄
    gt_upd_e3_column(ln_idx)                           := it_edi_work.e3_column;                         -- Ｅ－３欄
    gt_upd_f1_column(ln_idx)                           := it_edi_work.f1_column;                         -- Ｆ－１欄
    gt_upd_g1_column(ln_idx)                           := it_edi_work.g1_column;                         -- Ｇ－１欄
    gt_upd_h1_column(ln_idx)                           := it_edi_work.h1_column;                         -- Ｈ－１欄
    gt_upd_i1_column(ln_idx)                           := it_edi_work.i1_column;                         -- Ｉ－１欄
    gt_upd_j1_column(ln_idx)                           := it_edi_work.j1_column;                         -- Ｊ－１欄
    gt_upd_k1_column(ln_idx)                           := it_edi_work.k1_column;                         -- Ｋ－１欄
    gt_upd_l1_column(ln_idx)                           := it_edi_work.l1_column;                         -- Ｌ－１欄
    gt_upd_f2_column(ln_idx)                           := it_edi_work.f2_column;                         -- Ｆ－２欄
    gt_upd_g2_column(ln_idx)                           := it_edi_work.g2_column;                         -- Ｇ－２欄
    gt_upd_h2_column(ln_idx)                           := it_edi_work.h2_column;                         -- Ｈ－２欄
    gt_upd_i2_column(ln_idx)                           := it_edi_work.i2_column;                         -- Ｉ－２欄
    gt_upd_j2_column(ln_idx)                           := it_edi_work.j2_column;                         -- Ｊ－２欄
    gt_upd_k2_column(ln_idx)                           := it_edi_work.k2_column;                         -- Ｋ－２欄
    gt_upd_l2_column(ln_idx)                           := it_edi_work.l2_column;                         -- Ｌ－２欄
    gt_upd_f3_column(ln_idx)                           := it_edi_work.f3_column;                         -- Ｆ－３欄
    gt_upd_g3_column(ln_idx)                           := it_edi_work.g3_column;                         -- Ｇ－３欄
    gt_upd_h3_column(ln_idx)                           := it_edi_work.h3_column;                         -- Ｈ－３欄
    gt_upd_i3_column(ln_idx)                           := it_edi_work.i3_column;                         -- Ｉ－３欄
    gt_upd_j3_column(ln_idx)                           := it_edi_work.j3_column;                         -- Ｊ－３欄
    gt_upd_k3_column(ln_idx)                           := it_edi_work.k3_column;                         -- Ｋ－３欄
    gt_upd_l3_column(ln_idx)                           := it_edi_work.l3_column;                         -- Ｌ－３欄
    gt_upd_chain_pecul_area_head(ln_idx)               := it_edi_work.chain_peculiar_area_header;        -- チェーン店固有エリア（ヘッダー）
--  gt_upd_order_connection_num(ln_idx)                := NULL;                                          -- 受注関連番号
    gt_upd_inv_indv_order_qty(ln_idx)                  := it_edi_work.invoice_indv_order_qty;            -- （伝票計）発注数量（バラ）
    gt_upd_inv_case_order_qty(ln_idx)                  := it_edi_work.invoice_case_order_qty;            -- （伝票計）発注数量（ケース）
    gt_upd_inv_ball_order_qty(ln_idx)                  := it_edi_work.invoice_ball_order_qty;            -- （伝票計）発注数量（ボール）
    gt_upd_inv_sum_order_qty(ln_idx)                   := it_edi_work.invoice_sum_order_qty;             -- （伝票計）発注数量（合計、バラ）
    gt_upd_inv_indv_shipping_qty(ln_idx)               := it_edi_work.invoice_indv_shipping_qty;         -- （伝票計）出荷数量（バラ）
    gt_upd_inv_case_shipping_qty(ln_idx)               := it_edi_work.invoice_case_shipping_qty;         -- （伝票計）出荷数量（ケース）
    gt_upd_inv_ball_shipping_qty(ln_idx)               := it_edi_work.invoice_ball_shipping_qty;         -- （伝票計）出荷数量（ボール）
    gt_upd_inv_pallet_shipping_qty(ln_idx)             := it_edi_work.invoice_pallet_shipping_qty;       -- （伝票計）出荷数量（パレット）
    gt_upd_inv_sum_shipping_qty(ln_idx)                := it_edi_work.invoice_sum_shipping_qty;          -- （伝票計）出荷数量（合計、バラ）
    gt_upd_inv_indv_stockout_qty(ln_idx)               := it_edi_work.invoice_indv_stockout_qty;         -- （伝票計）欠品数量（バラ）
    gt_upd_inv_case_stockout_qty(ln_idx)               := it_edi_work.invoice_case_stockout_qty;         -- （伝票計）欠品数量（ケース）
    gt_upd_inv_ball_stockout_qty(ln_idx)               := it_edi_work.invoice_ball_stockout_qty;         -- （伝票計）欠品数量（ボール）
    gt_upd_inv_sum_stockout_qty(ln_idx)                := it_edi_work.invoice_sum_stockout_qty;          -- （伝票計）欠品数量（合計、バラ）
    gt_upd_inv_case_qty(ln_idx)                        := it_edi_work.invoice_case_qty;                  -- （伝票計）ケース個口数
    gt_upd_inv_fold_container_qty(ln_idx)              := it_edi_work.invoice_fold_container_qty;        -- （伝票計）オリコン（バラ）個口数
    gt_upd_inv_order_cost_amt(ln_idx)                  := it_edi_work.invoice_order_cost_amt;            -- （伝票計）原価金額（発注）
    gt_upd_inv_shipping_cost_amt(ln_idx)               := it_edi_work.invoice_shipping_cost_amt;         -- （伝票計）原価金額（出荷）
    gt_upd_inv_stockout_cost_amt(ln_idx)               := it_edi_work.invoice_stockout_cost_amt;         -- （伝票計）原価金額（欠品）
    gt_upd_inv_order_price_amt(ln_idx)                 := it_edi_work.invoice_order_price_amt;           -- （伝票計）売価金額（発注）
    gt_upd_inv_shipping_price_amt(ln_idx)              := it_edi_work.invoice_shipping_price_amt;        -- （伝票計）売価金額（出荷）
    gt_upd_inv_stockout_price_amt(ln_idx)              := it_edi_work.invoice_stockout_price_amt;        -- （伝票計）売価金額（欠品）
    gt_upd_total_indv_order_qty(ln_idx)                := it_edi_work.total_indv_order_qty;              -- （総合計）発注数量（バラ）
    gt_upd_total_case_order_qty(ln_idx)                := it_edi_work.total_case_order_qty;              -- （総合計）発注数量（ケース）
    gt_upd_total_ball_order_qty(ln_idx)                := it_edi_work.total_ball_order_qty;              -- （総合計）発注数量（ボール）
    gt_upd_total_sum_order_qty(ln_idx)                 := it_edi_work.total_sum_order_qty;               -- （総合計）発注数量（合計、バラ）
    gt_upd_total_indv_ship_qty(ln_idx)                 := it_edi_work.total_indv_shipping_qty;           -- （総合計）出荷数量（バラ）
    gt_upd_total_case_ship_qty(ln_idx)                 := it_edi_work.total_case_shipping_qty;           -- （総合計）出荷数量（ケース）
    gt_upd_total_ball_ship_qty(ln_idx)                 := it_edi_work.total_ball_shipping_qty;           -- （総合計）出荷数量（ボール）
    gt_upd_total_pallet_ship_qty(ln_idx)               := it_edi_work.total_pallet_shipping_qty;         -- （総合計）出荷数量（パレット）
    gt_upd_total_sum_ship_qty(ln_idx)                  := it_edi_work.total_sum_shipping_qty;            -- （総合計）出荷数量（合計、バラ）
    gt_upd_total_indv_stockout_qty(ln_idx)             := it_edi_work.total_indv_stockout_qty;           -- （総合計）欠品数量（バラ）
    gt_upd_total_case_stockout_qty(ln_idx)             := it_edi_work.total_case_stockout_qty;           -- （総合計）欠品数量（ケース）
    gt_upd_total_ball_stockout_qty(ln_idx)             := it_edi_work.total_ball_stockout_qty;           -- （総合計）欠品数量（ボール）
    gt_upd_total_sum_stockout_qty(ln_idx)              := it_edi_work.total_sum_stockout_qty;            -- （総合計）欠品数量（合計、バラ）
    gt_upd_total_case_qty(ln_idx)                      := it_edi_work.total_case_qty;                    -- （総合計）ケース個口数
    gt_upd_total_fold_contain_qty(ln_idx)              := it_edi_work.total_fold_container_qty;          -- （総合計）オリコン（バラ）個口数
    gt_upd_total_order_cost_amt(ln_idx)                := it_edi_work.total_order_cost_amt;              -- （総合計）原価金額（発注）
    gt_upd_total_shipping_cost_amt(ln_idx)             := it_edi_work.total_shipping_cost_amt;           -- （総合計）原価金額（出荷）
    gt_upd_total_stockout_cost_amt(ln_idx)             := it_edi_work.total_stockout_cost_amt;           -- （総合計）原価金額（欠品）
    gt_upd_total_order_price_amt(ln_idx)               := it_edi_work.total_order_price_amt;             -- （総合計）売価金額（発注）
    gt_upd_total_ship_price_amt(ln_idx)                := it_edi_work.total_shipping_price_amt;          -- （総合計）売価金額（出荷）
    gt_upd_total_stock_price_amt(ln_idx)               := it_edi_work.total_stockout_price_amt;          -- （総合計）売価金額（欠品）
    gt_upd_total_line_qty(ln_idx)                      := it_edi_work.total_line_qty;                    -- トータル行数
    gt_upd_total_invoice_qty(ln_idx)                   := it_edi_work.total_invoice_qty;                 -- トータル伝票枚数
    gt_upd_chain_pecul_area_foot(ln_idx)               := it_edi_work.chain_peculiar_area_footer;        -- チェーン店固有エリア（フッター）
    gt_upd_conv_customer_code(ln_idx)                  := it_edi_work.conv_customer_code;                -- 変換後顧客コード
--  gt_upd_order_forward_flag(ln_idx)                  := cv_order_forward_flag;                         -- 受注連携済フラグ
--  gt_upd_creation_class(ln_idx)                      := cv_creation_class                              -- 作成元区分
--  gt_upd_edi_delivery_sche_flag(ln_idx)              := cv_edi_delivery_flag;                          -- EDI納品予定送信済フラグ
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_upd_tsukagatazaiko_div(ln_idx)                  := it_edi_work.tsukagatazaiko_div;                -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
    gt_upd_price_list_header_id(ln_idx)                := it_edi_work.price_list_header_id;              -- 価格表ヘッダID
--
  EXCEPTION
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
  END proc_set_upd_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_lines
   * Description      : EDI明細情報テーブルデータ抽出(A-10)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_lines(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI受注情報ワークレコード
    in_edi_header_info_id IN  NUMBER,        -- EDIヘッダ情報ID
    on_edi_line_info_id   OUT NOCOPY NUMBER, -- EDI明細情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
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
    -- OUTパラメータ初期化
    on_edi_line_info_id   := NULL;
--
    --EDI明細情報データ抽出
    SELECT  line.edi_line_info_id
    INTO    on_edi_line_info_id
    FROM    xxcos_edi_lines             line
    WHERE   line.edi_header_info_id     = in_edi_header_info_id            -- EDIヘッダ情報ID
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    AND     line.line_no                = it_edi_work.line_no;             -- 行番号
    AND     line.order_connection_line_number = it_edi_work.order_connection_line_number; -- 受注関連明細番号
-- 2010/01/19 Ver1.15 M.Sano Mod End
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** 対象データなし例外ハンドラ ***
      NULL;
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
  END proc_get_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_ins_lines
   * Description      : EDI明細情報テーブルインサート用変数格納(A-11)
   ***********************************************************************************/
  PROCEDURE proc_set_ins_lines(
    it_edi_work    IN  g_edi_work_rtype,     -- EDI受注情報ワークレコード
    in_edi_head_id IN  NUMBER,               -- EDIヘッダ情報ID
    on_edi_line_id OUT NOCOPY NUMBER,        -- EDI明細情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_ins_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
    ln_seq     NUMBER;
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
    -- OUTパラメータ初期化
    on_edi_line_id := NULL;
--
    ln_idx := gt_edi_lines.COUNT + 1;
--
    -- EDI明細情報IDをシーケンスから取得する
    BEGIN
      SELECT xxcos_edi_lines_s01.NEXTVAL
      INTO   ln_seq
      FROM   dual;
    END;
--
    -- 取得したシーケンスをOUTパラメータで返す
    on_edi_line_id := ln_seq;
--
    gt_edi_lines(ln_idx).edi_line_info_id              := ln_seq;                                        -- EDI明細情報ID
    gt_edi_lines(ln_idx).edi_header_info_id            := in_edi_head_id;                                -- EDIヘッダ情報ID
    gt_edi_lines(ln_idx).line_no                       := it_edi_work.line_no;                           -- 行Ｎｏ
    gt_edi_lines(ln_idx).stockout_class                := it_edi_work.stockout_class;                    -- 欠品区分
    gt_edi_lines(ln_idx).stockout_reason               := it_edi_work.stockout_reason;                   -- 欠品理由
    gt_edi_lines(ln_idx).product_code_itouen           := it_edi_work.product_code_itouen;               -- 商品コード（伊藤園）
    gt_edi_lines(ln_idx).product_code1                 := it_edi_work.product_code1;                     -- 商品コード１
    gt_edi_lines(ln_idx).product_code2                 := it_edi_work.product_code2;                     -- 商品コード２
    gt_edi_lines(ln_idx).jan_code                      := it_edi_work.jan_code;                          -- ＪＡＮコード
    gt_edi_lines(ln_idx).itf_code                      := it_edi_work.itf_code;                          -- ＩＴＦコード
    gt_edi_lines(ln_idx).extension_itf_code            := it_edi_work.extension_itf_code;                -- 内箱ＩＴＦコード
    gt_edi_lines(ln_idx).case_product_code             := it_edi_work.case_product_code;                 -- ケース商品コード
    gt_edi_lines(ln_idx).ball_product_code             := it_edi_work.ball_product_code;                 -- ボール商品コード
    gt_edi_lines(ln_idx).product_code_item_type        := it_edi_work.product_code_item_type;            -- 商品コード品種
    gt_edi_lines(ln_idx).prod_class                    := it_edi_work.prod_class;                        -- 商品区分
    gt_edi_lines(ln_idx).product_name                  := it_edi_work.product_name;                      -- 商品名（漢字）
    gt_edi_lines(ln_idx).product_name1_alt             := it_edi_work.product_name1_alt;                 -- 商品名１（カナ）
    gt_edi_lines(ln_idx).product_name2_alt             := it_edi_work.product_name2_alt;                 -- 商品名２（カナ）
    gt_edi_lines(ln_idx).item_standard1                := it_edi_work.item_standard1;                    -- 規格１
    gt_edi_lines(ln_idx).item_standard2                := it_edi_work.item_standard2;                    -- 規格２
    gt_edi_lines(ln_idx).qty_in_case                   := it_edi_work.qty_in_case;                       -- 入数
    gt_edi_lines(ln_idx).num_of_cases                  := it_edi_work.num_of_cases;                      -- ケース入数
    gt_edi_lines(ln_idx).num_of_ball                   := it_edi_work.num_of_ball;                       -- ボール入数
    gt_edi_lines(ln_idx).item_color                    := it_edi_work.item_color;                        -- 色
    gt_edi_lines(ln_idx).item_size                     := it_edi_work.item_size;                         -- サイズ
    gt_edi_lines(ln_idx).expiration_date               := it_edi_work.expiration_date;                   -- 賞味期限日
    gt_edi_lines(ln_idx).product_date                  := it_edi_work.product_date;                      -- 製造日
    gt_edi_lines(ln_idx).order_uom_qty                 := it_edi_work.order_uom_qty;                     -- 発注単位数
    gt_edi_lines(ln_idx).shipping_uom_qty              := it_edi_work.shipping_uom_qty;                  -- 出荷単位数
    gt_edi_lines(ln_idx).packing_uom_qty               := it_edi_work.packing_uom_qty;                   -- 梱包単位数
    gt_edi_lines(ln_idx).deal_code                     := it_edi_work.deal_code;                         -- 引合
    gt_edi_lines(ln_idx).deal_class                    := it_edi_work.deal_class;                        -- 引合区分
    gt_edi_lines(ln_idx).collation_code                := it_edi_work.collation_code;                    -- 照合
    gt_edi_lines(ln_idx).uom_code                      := it_edi_work.uom_code;                          -- 単位
    gt_edi_lines(ln_idx).unit_price_class              := it_edi_work.unit_price_class;                  -- 単価区分
    gt_edi_lines(ln_idx).parent_packing_number         := it_edi_work.parent_packing_number;             -- 親梱包番号
    gt_edi_lines(ln_idx).packing_number                := it_edi_work.packing_number;                    -- 梱包番号
    gt_edi_lines(ln_idx).product_group_code            := it_edi_work.product_group_code;                -- 商品群コード
    gt_edi_lines(ln_idx).case_dismantle_flag           := it_edi_work.case_dismantle_flag;               -- ケース解体不可フラグ
    gt_edi_lines(ln_idx).case_class                    := it_edi_work.case_class;                        -- ケース区分
    gt_edi_lines(ln_idx).indv_order_qty                := it_edi_work.indv_order_qty;                    -- 発注数量（バラ）
    gt_edi_lines(ln_idx).case_order_qty                := it_edi_work.case_order_qty;                    -- 発注数量（ケース）
    gt_edi_lines(ln_idx).ball_order_qty                := it_edi_work.ball_order_qty;                    -- 発注数量（ボール）
    gt_edi_lines(ln_idx).sum_order_qty                 := it_edi_work.sum_order_qty;                     -- 発注数量（合計、バラ）
    gt_edi_lines(ln_idx).indv_shipping_qty             := it_edi_work.indv_shipping_qty;                 -- 出荷数量（バラ）
    gt_edi_lines(ln_idx).case_shipping_qty             := it_edi_work.case_shipping_qty;                 -- 出荷数量（ケース）
    gt_edi_lines(ln_idx).ball_shipping_qty             := it_edi_work.ball_shipping_qty;                 -- 出荷数量（ボール）
    gt_edi_lines(ln_idx).pallet_shipping_qty           := it_edi_work.pallet_shipping_qty;               -- 出荷数量（パレット）
    gt_edi_lines(ln_idx).sum_shipping_qty              := it_edi_work.sum_shipping_qty;                  -- 出荷数量（合計、バラ）
    gt_edi_lines(ln_idx).indv_stockout_qty             := it_edi_work.indv_stockout_qty;                 -- 欠品数量（バラ）
    gt_edi_lines(ln_idx).case_stockout_qty             := it_edi_work.case_stockout_qty;                 -- 欠品数量（ケース）
    gt_edi_lines(ln_idx).ball_stockout_qty             := it_edi_work.ball_stockout_qty;                 -- 欠品数量（ボール）
    gt_edi_lines(ln_idx).sum_stockout_qty              := it_edi_work.sum_stockout_qty;                  -- 欠品数量（合計、バラ）
    gt_edi_lines(ln_idx).case_qty                      := it_edi_work.case_qty;                          -- ケース個口数
    gt_edi_lines(ln_idx).fold_container_indv_qty       := it_edi_work.fold_container_indv_qty;           -- オリコン（バラ）個口数
    gt_edi_lines(ln_idx).order_unit_price              := it_edi_work.order_unit_price;                  -- 原単価（発注）
    gt_edi_lines(ln_idx).shipping_unit_price           := it_edi_work.shipping_unit_price;               -- 原単価（出荷）
    gt_edi_lines(ln_idx).order_cost_amt                := it_edi_work.order_cost_amt;                    -- 原価金額（発注）
    gt_edi_lines(ln_idx).shipping_cost_amt             := it_edi_work.shipping_cost_amt;                 -- 原価金額（出荷）
    gt_edi_lines(ln_idx).stockout_cost_amt             := it_edi_work.stockout_cost_amt;                 -- 原価金額（欠品）
    gt_edi_lines(ln_idx).selling_price                 := it_edi_work.selling_price;                     -- 売単価
    gt_edi_lines(ln_idx).order_price_amt               := it_edi_work.order_price_amt;                   -- 売価金額（発注）
    gt_edi_lines(ln_idx).shipping_price_amt            := it_edi_work.shipping_price_amt;                -- 売価金額（出荷）
    gt_edi_lines(ln_idx).stockout_price_amt            := it_edi_work.stockout_price_amt;                -- 売価金額（欠品）
    gt_edi_lines(ln_idx).a_column_department           := it_edi_work.a_column_department;               -- Ａ欄（百貨店）
    gt_edi_lines(ln_idx).d_column_department           := it_edi_work.d_column_department;               -- Ｄ欄（百貨店）
    gt_edi_lines(ln_idx).standard_info_depth           := it_edi_work.standard_info_depth;               -- 規格情報・奥行き
    gt_edi_lines(ln_idx).standard_info_height          := it_edi_work.standard_info_height;              -- 規格情報・高さ
    gt_edi_lines(ln_idx).standard_info_width           := it_edi_work.standard_info_width;               -- 規格情報・幅
    gt_edi_lines(ln_idx).standard_info_weight          := it_edi_work.standard_info_weight;              -- 規格情報・重量
    gt_edi_lines(ln_idx).general_succeeded_item1       := it_edi_work.general_succeeded_item1;           -- 汎用引継ぎ項目１
    gt_edi_lines(ln_idx).general_succeeded_item2       := it_edi_work.general_succeeded_item2;           -- 汎用引継ぎ項目２
    gt_edi_lines(ln_idx).general_succeeded_item3       := it_edi_work.general_succeeded_item3;           -- 汎用引継ぎ項目３
    gt_edi_lines(ln_idx).general_succeeded_item4       := it_edi_work.general_succeeded_item4;           -- 汎用引継ぎ項目４
    gt_edi_lines(ln_idx).general_succeeded_item5       := it_edi_work.general_succeeded_item5;           -- 汎用引継ぎ項目５
    gt_edi_lines(ln_idx).general_succeeded_item6       := it_edi_work.general_succeeded_item6;           -- 汎用引継ぎ項目６
    gt_edi_lines(ln_idx).general_succeeded_item7       := it_edi_work.general_succeeded_item7;           -- 汎用引継ぎ項目７
    gt_edi_lines(ln_idx).general_succeeded_item8       := it_edi_work.general_succeeded_item8;           -- 汎用引継ぎ項目８
    gt_edi_lines(ln_idx).general_succeeded_item9       := it_edi_work.general_succeeded_item9;           -- 汎用引継ぎ項目９
    gt_edi_lines(ln_idx).general_succeeded_item10      := it_edi_work.general_succeeded_item10;          -- 汎用引継ぎ項目１０
    gt_edi_lines(ln_idx).general_add_item1             := it_edi_work.general_add_item1;                 -- 汎用付加項目１
    gt_edi_lines(ln_idx).general_add_item2             := it_edi_work.general_add_item2;                 -- 汎用付加項目２
    gt_edi_lines(ln_idx).general_add_item3             := it_edi_work.general_add_item3;                 -- 汎用付加項目３
    gt_edi_lines(ln_idx).general_add_item4             := it_edi_work.general_add_item4;                 -- 汎用付加項目４
    gt_edi_lines(ln_idx).general_add_item5             := it_edi_work.general_add_item5;                 -- 汎用付加項目５
    gt_edi_lines(ln_idx).general_add_item6             := it_edi_work.general_add_item6;                 -- 汎用付加項目６
    gt_edi_lines(ln_idx).general_add_item7             := it_edi_work.general_add_item7;                 -- 汎用付加項目７
    gt_edi_lines(ln_idx).general_add_item8             := it_edi_work.general_add_item8;                 -- 汎用付加項目８
    gt_edi_lines(ln_idx).general_add_item9             := it_edi_work.general_add_item9;                 -- 汎用付加項目９
    gt_edi_lines(ln_idx).general_add_item10            := it_edi_work.general_add_item10;                -- 汎用付加項目１０
    gt_edi_lines(ln_idx).chain_peculiar_area_line      := it_edi_work.chain_peculiar_area_line;          -- チェーン店固有エリア（明細）
    gt_edi_lines(ln_idx).item_code                     := it_edi_work.item_code;                         -- 品目コード
    gt_edi_lines(ln_idx).line_uom                      := it_edi_work.line_uom;                          -- 明細単位
    gt_edi_lines(ln_idx).hht_delivery_schedule_flag    := cv_hht_delivery_flag;                          -- HHT納品予定連携済フラグ
-- 2010/01/19 Ver.1.15 M.Sano add Start
--    gt_edi_lines(ln_idx).order_connection_line_number  := it_edi_work.line_no;                           -- 受注関連明細番号
    gt_edi_lines(ln_idx).order_connection_line_number  := it_edi_work.order_connection_line_number;      -- 受注関連明細番号
-- 2010/01/19 Ver.1.15 M.Sano add End
--****************************** 2009/05/08 1.4 T.Kitajima ADD START ******************************--
    gt_edi_lines(ln_idx).taking_unit_price             := it_edi_work.order_unit_price;                  -- 取込時原単価（発注）
--****************************** 2009/05/08 1.4 T.Kitajima ADD  END  ******************************--
    gt_edi_lines(ln_idx).created_by                    := cn_created_by;                                 -- 作成者
    gt_edi_lines(ln_idx).creation_date                 := cd_creation_date;                              -- 作成日
    gt_edi_lines(ln_idx).last_updated_by               := cn_last_updated_by;                            -- 最終更新者
    gt_edi_lines(ln_idx).last_update_date              := cd_last_update_date;                           -- 最終更新日
    gt_edi_lines(ln_idx).last_update_login             := cn_last_update_login;                          -- 最終更新ログイン
    gt_edi_lines(ln_idx).request_id                    := cn_request_id;                                 -- 要求ID
    gt_edi_lines(ln_idx).program_application_id        := cn_program_application_id;                     -- コンカレント・プログラム・アプリケーションID
    gt_edi_lines(ln_idx).program_id                    := cn_program_id;                                 -- コンカレント・プログラムID
    gt_edi_lines(ln_idx).program_update_date           := cd_program_update_date;                        -- プログラム更新日
--
  EXCEPTION
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
  END proc_set_ins_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_upd_lines
   * Description      : EDI明細情報テーブルアップデート用変数格納(A-12)
   ***********************************************************************************/
  PROCEDURE proc_set_upd_lines(
    it_edi_work    IN g_edi_work_rtype,      -- EDI受注情報ワークレコード
    in_edi_head_id IN NUMBER,                -- EDIヘッダ情報ID
    in_edi_line_id IN NUMBER,                -- EDI明細情報ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_upd_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    ln_idx := gt_upd_edi_line_info_id.COUNT + 1;
--
    gt_upd_edi_line_info_id(ln_idx)                    := in_edi_line_id;                                -- EDI明細情報ID
    gt_upd_edi_line_header_info_id(ln_idx)             := in_edi_head_id;                                -- EDIヘッダ情報ID
    gt_upd_line_no(ln_idx)                             := it_edi_work.line_no;                           -- 行Ｎｏ
    gt_upd_stockout_class(ln_idx)                      := it_edi_work.stockout_class;                    -- 欠品区分
    gt_upd_stockout_reason(ln_idx)                     := it_edi_work.stockout_reason;                   -- 欠品理由
    gt_upd_product_code_itouen(ln_idx)                 := it_edi_work.product_code_itouen;               -- 商品コード（伊藤園）
    gt_upd_product_code1(ln_idx)                       := it_edi_work.product_code1;                     -- 商品コード１
    gt_upd_product_code2(ln_idx)                       := it_edi_work.product_code2;                     -- 商品コード２
    gt_upd_jan_code(ln_idx)                            := it_edi_work.jan_code;                          -- ＪＡＮコード
    gt_upd_itf_code(ln_idx)                            := it_edi_work.itf_code;                          -- ＩＴＦコード
    gt_upd_extension_itf_code(ln_idx)                  := it_edi_work.extension_itf_code;                -- 内箱ＩＴＦコード
    gt_upd_case_product_code(ln_idx)                   := it_edi_work.case_product_code;                 -- ケース商品コード
    gt_upd_ball_product_code(ln_idx)                   := it_edi_work.ball_product_code;                 -- ボール商品コード
    gt_upd_product_code_item_type(ln_idx)              := it_edi_work.product_code_item_type;            -- 商品コード品種
    gt_upd_prod_class(ln_idx)                          := it_edi_work.prod_class;                        -- 商品区分
    gt_upd_product_name(ln_idx)                        := it_edi_work.product_name;                      -- 商品名（漢字）
    gt_upd_product_name1_alt(ln_idx)                   := it_edi_work.product_name1_alt;                 -- 商品名１（カナ）
    gt_upd_product_name2_alt(ln_idx)                   := it_edi_work.product_name2_alt;                 -- 商品名２（カナ）
    gt_upd_item_standard1(ln_idx)                      := it_edi_work.item_standard1;                    -- 規格１
    gt_upd_item_standard2(ln_idx)                      := it_edi_work.item_standard2;                    -- 規格２
    gt_upd_qty_in_case(ln_idx)                         := it_edi_work.qty_in_case;                       -- 入数
    gt_upd_num_of_cases(ln_idx)                        := it_edi_work.num_of_cases;                      -- ケース入数
    gt_upd_num_of_ball(ln_idx)                         := it_edi_work.num_of_ball;                       -- ボール入数
    gt_upd_item_color(ln_idx)                          := it_edi_work.item_color;                        -- 色
    gt_upd_item_size(ln_idx)                           := it_edi_work.item_size;                         -- サイズ
    gt_upd_expiration_date(ln_idx)                     := it_edi_work.expiration_date;                   -- 賞味期限日
    gt_upd_product_date(ln_idx)                        := it_edi_work.product_date;                      -- 製造日
    gt_upd_order_uom_qty(ln_idx)                       := it_edi_work.order_uom_qty;                     -- 発注単位数
    gt_upd_shipping_uom_qty(ln_idx)                    := it_edi_work.shipping_uom_qty;                  -- 出荷単位数
    gt_upd_packing_uom_qty(ln_idx)                     := it_edi_work.packing_uom_qty;                   -- 梱包単位数
    gt_upd_deal_code(ln_idx)                           := it_edi_work.deal_code;                         -- 引合
    gt_upd_deal_class(ln_idx)                          := it_edi_work.deal_class;                        -- 引合区分
    gt_upd_collation_code(ln_idx)                      := it_edi_work.collation_code;                    -- 照合
    gt_upd_uom_code(ln_idx)                            := it_edi_work.uom_code;                          -- 単位
    gt_upd_unit_price_class(ln_idx)                    := it_edi_work.unit_price_class;                  -- 単価区分
    gt_upd_parent_packing_number(ln_idx)               := it_edi_work.parent_packing_number;             -- 親梱包番号
    gt_upd_packing_number(ln_idx)                      := it_edi_work.packing_number;                    -- 梱包番号
    gt_upd_product_group_code(ln_idx)                  := it_edi_work.product_group_code;                -- 商品群コード
    gt_upd_case_dismantle_flag(ln_idx)                 := it_edi_work.case_dismantle_flag;               -- ケース解体不可フラグ
    gt_upd_case_class(ln_idx)                          := it_edi_work.case_class;                        -- ケース区分
    gt_upd_indv_order_qty(ln_idx)                      := it_edi_work.indv_order_qty;                    -- 発注数量（バラ）
    gt_upd_case_order_qty(ln_idx)                      := it_edi_work.case_order_qty;                    -- 発注数量（ケース）
    gt_upd_ball_order_qty(ln_idx)                      := it_edi_work.ball_order_qty;                    -- 発注数量（ボール）
    gt_upd_sum_order_qty(ln_idx)                       := it_edi_work.sum_order_qty;                     -- 発注数量（合計、バラ）
    gt_upd_indv_shipping_qty(ln_idx)                   := it_edi_work.indv_shipping_qty;                 -- 出荷数量（バラ）
    gt_upd_case_shipping_qty(ln_idx)                   := it_edi_work.case_shipping_qty;                 -- 出荷数量（ケース）
    gt_upd_ball_shipping_qty(ln_idx)                   := it_edi_work.ball_shipping_qty;                 -- 出荷数量（ボール）
    gt_upd_pallet_shipping_qty(ln_idx)                 := it_edi_work.pallet_shipping_qty;               -- 出荷数量（パレット）
    gt_upd_sum_shipping_qty(ln_idx)                    := it_edi_work.sum_shipping_qty;                  -- 出荷数量（合計、バラ）
    gt_upd_indv_stockout_qty(ln_idx)                   := it_edi_work.indv_stockout_qty;                 -- 欠品数量（バラ）
    gt_upd_case_stockout_qty(ln_idx)                   := it_edi_work.case_stockout_qty;                 -- 欠品数量（ケース）
    gt_upd_ball_stockout_qty(ln_idx)                   := it_edi_work.ball_stockout_qty;                 -- 欠品数量（ボール）
    gt_upd_sum_stockout_qty(ln_idx)                    := it_edi_work.sum_stockout_qty;                  -- 欠品数量（合計、バラ）
    gt_upd_case_qty(ln_idx)                            := it_edi_work.case_qty;                          -- ケース個口数
    gt_upd_fold_container_indv_qty(ln_idx)             := it_edi_work.fold_container_indv_qty;           -- オリコン（バラ）個口数
    gt_upd_order_unit_price(ln_idx)                    := it_edi_work.order_unit_price;                  -- 原単価（発注）
    gt_upd_shipping_unit_price(ln_idx)                 := it_edi_work.shipping_unit_price;               -- 原単価（出荷）
    gt_upd_order_cost_amt(ln_idx)                      := it_edi_work.order_cost_amt;                    -- 原価金額（発注）
    gt_upd_shipping_cost_amt(ln_idx)                   := it_edi_work.shipping_cost_amt;                 -- 原価金額（出荷）
    gt_upd_stockout_cost_amt(ln_idx)                   := it_edi_work.stockout_cost_amt;                 -- 原価金額（欠品）
    gt_upd_selling_price(ln_idx)                       := it_edi_work.selling_price;                     -- 売単価
    gt_upd_order_price_amt(ln_idx)                     := it_edi_work.order_price_amt;                   -- 売価金額（発注）
    gt_upd_shipping_price_amt(ln_idx)                  := it_edi_work.shipping_price_amt;                -- 売価金額（出荷）
    gt_upd_stockout_price_amt(ln_idx)                  := it_edi_work.stockout_price_amt;                -- 売価金額（欠品）
    gt_upd_a_column_department(ln_idx)                 := it_edi_work.a_column_department;               -- Ａ欄（百貨店）
    gt_upd_d_column_department(ln_idx)                 := it_edi_work.d_column_department;               -- Ｄ欄（百貨店）
    gt_upd_standard_info_depth(ln_idx)                 := it_edi_work.standard_info_depth;               -- 規格情報・奥行き
    gt_upd_standard_info_height(ln_idx)                := it_edi_work.standard_info_height;              -- 規格情報・高さ
    gt_upd_standard_info_width(ln_idx)                 := it_edi_work.standard_info_width;               -- 規格情報・幅
    gt_upd_standard_info_weight(ln_idx)                := it_edi_work.standard_info_weight;              -- 規格情報・重量
    gt_upd_general_succeed_item1(ln_idx)               := it_edi_work.general_succeeded_item1;           -- 汎用引継ぎ項目１
    gt_upd_general_succeed_item2(ln_idx)               := it_edi_work.general_succeeded_item2;           -- 汎用引継ぎ項目２
    gt_upd_general_succeed_item3(ln_idx)               := it_edi_work.general_succeeded_item3;           -- 汎用引継ぎ項目３
    gt_upd_general_succeed_item4(ln_idx)               := it_edi_work.general_succeeded_item4;           -- 汎用引継ぎ項目４
    gt_upd_general_succeed_item5(ln_idx)               := it_edi_work.general_succeeded_item5;           -- 汎用引継ぎ項目５
    gt_upd_general_succeed_item6(ln_idx)               := it_edi_work.general_succeeded_item6;           -- 汎用引継ぎ項目６
    gt_upd_general_succeed_item7(ln_idx)               := it_edi_work.general_succeeded_item7;           -- 汎用引継ぎ項目７
    gt_upd_general_succeed_item8(ln_idx)               := it_edi_work.general_succeeded_item8;           -- 汎用引継ぎ項目８
    gt_upd_general_succeed_item9(ln_idx)               := it_edi_work.general_succeeded_item9;           -- 汎用引継ぎ項目９
    gt_upd_general_succeed_item10(ln_idx)              := it_edi_work.general_succeeded_item10;          -- 汎用引継ぎ項目１０
    gt_upd_general_add_item1(ln_idx)                   := it_edi_work.general_add_item1;                 -- 汎用付加項目１
    gt_upd_general_add_item2(ln_idx)                   := it_edi_work.general_add_item2;                 -- 汎用付加項目２
    gt_upd_general_add_item3(ln_idx)                   := it_edi_work.general_add_item3;                 -- 汎用付加項目３
    gt_upd_general_add_item4(ln_idx)                   := it_edi_work.general_add_item4;                 -- 汎用付加項目４
    gt_upd_general_add_item5(ln_idx)                   := it_edi_work.general_add_item5;                 -- 汎用付加項目５
    gt_upd_general_add_item6(ln_idx)                   := it_edi_work.general_add_item6;                 -- 汎用付加項目６
    gt_upd_general_add_item7(ln_idx)                   := it_edi_work.general_add_item7;                 -- 汎用付加項目７
    gt_upd_general_add_item8(ln_idx)                   := it_edi_work.general_add_item8;                 -- 汎用付加項目８
    gt_upd_general_add_item9(ln_idx)                   := it_edi_work.general_add_item9;                 -- 汎用付加項目９
    gt_upd_general_add_item10(ln_idx)                  := it_edi_work.general_add_item10;                -- 汎用付加項目１０
    gt_upd_chain_pecul_area_line(ln_idx)               := it_edi_work.chain_peculiar_area_line;          -- チェーン店固有エリア（明細）
    gt_upd_item_code(ln_idx)                           := it_edi_work.item_code;                         -- 品目コード
    gt_upd_line_uom(ln_idx)                            := it_edi_work.line_uom;                          -- 明細単位
    gt_upd_hht_delivery_sche_flag(ln_idx)              := cv_hht_delivery_flag;                          -- HHT納品予定連携済フラグ
-- 2010/01/19 Ver.1.15 M.Sano add Start
--    gt_upd_order_connect_line_num(ln_idx)              := it_edi_work.line_no;                           -- 受注関連明細番号
    gt_upd_order_connect_line_num(ln_idx)              := it_edi_work.order_connection_line_number;      -- 受注関連明細番号
-- 2010/01/19 Ver.1.15 M.Sano add End
--
  EXCEPTION
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
  END proc_set_upd_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_calc_inv_total
   * Description      : 伝票毎の合計値を算出(A-13)
   ***********************************************************************************/
  PROCEDURE proc_calc_inv_total(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI受注情報ワークレコード
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_calc_inv_total'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
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
    -- 各合計値に加算
    gt_inv_total.indv_order_qty := gt_inv_total.indv_order_qty + NVL( it_edi_work.indv_order_qty, 0 );   -- 発注数量（バラ）
    gt_inv_total.case_order_qty := gt_inv_total.case_order_qty + NVL( it_edi_work.case_order_qty, 0 );   -- 発注数量（ケース）
    gt_inv_total.ball_order_qty := gt_inv_total.ball_order_qty + NVL( it_edi_work.ball_order_qty, 0 );   -- 発注数量（ボール）
    gt_inv_total.sum_order_qty  := gt_inv_total.sum_order_qty  + NVL( it_edi_work.sum_order_qty, 0 );    -- 発注数量（合計、バラ）
    gt_inv_total.order_cost_amt := gt_inv_total.order_cost_amt + NVL( it_edi_work.order_cost_amt, 0 );   -- 原価金額（発注）
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
    gt_inv_total.shipping_cost_amt := gt_inv_total.shipping_cost_amt + NVL( it_edi_work.shipping_cost_amt , 0 ); -- 原価金額（出荷）
    gt_inv_total.stockout_cost_amt := gt_inv_total.stockout_cost_amt + NVL( it_edi_work.stockout_cost_amt , 0 ); -- 原価金額（欠品）
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    
--
  EXCEPTION
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
  END proc_calc_inv_total;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_inv_total
   * Description      : EDIヘッダ情報用変数に伝票計を設定(A-14)
   ***********************************************************************************/
  PROCEDURE proc_set_inv_total(
    in_edi_head_ins_flag IN NUMBER,          -- EDIヘッダ情報インサートフラグ
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_inv_total'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    -- EDIヘッダ情報がインサートの場合
    IF ( in_edi_head_ins_flag = 1 ) THEN
      -- EDIヘッダ情報インサート変数に発注数量合計値を設定
      ln_idx := gt_edi_headers.COUNT;
      gt_edi_headers(ln_idx).invoice_indv_order_qty    := gt_inv_total.indv_order_qty;         -- 発注数量（バラ）
      gt_edi_headers(ln_idx).invoice_case_order_qty    := gt_inv_total.case_order_qty;         -- 発注数量（ケース）
      gt_edi_headers(ln_idx).invoice_ball_order_qty    := gt_inv_total.ball_order_qty;         -- 発注数量（ボール）
      gt_edi_headers(ln_idx).invoice_sum_order_qty     := gt_inv_total.sum_order_qty;          -- 発注数量（合計、バラ）
      gt_edi_headers(ln_idx).invoice_order_cost_amt    := gt_inv_total.order_cost_amt;         -- 原価金額（発注）
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
      gt_edi_headers(ln_idx).invoice_shipping_cost_amt := gt_inv_total.shipping_cost_amt;      -- 原価金額（出荷）
      gt_edi_headers(ln_idx).invoice_stockout_cost_amt := gt_inv_total.stockout_cost_amt;      -- 原価金額（欠品）
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    END IF;
--
  EXCEPTION
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
  END proc_set_inv_total;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_headers
   * Description      : EDIヘッダ情報テーブルデータ追加(A-15)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     INTEGER;
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
    -- EDIヘッダ情報データ追加処理
    FORALL ln_idx IN 1..gt_edi_headers.COUNT
      INSERT INTO xxcos_edi_headers
        VALUES gt_edi_headers(ln_idx);
--
  EXCEPTION
    -- *** キー重複例外ハンドラ ***
    WHEN DUP_VAL_ON_INDEX THEN
      -- データ登録エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
      -- データ登録エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_ins_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_headers
   * Description      : EDIヘッダ情報テーブルデータ更新(A-16)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_headers'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     INTEGER;
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
    -- EDIヘッダ情報データ更新処理
    FORALL ln_idx IN 1..gt_upd_edi_header_info_id.COUNT
      UPDATE  xxcos_edi_headers
      SET     medium_class                        = gt_upd_medium_class(ln_idx),               -- 媒体区分
              data_type_code                      = gt_upd_data_type_code(ln_idx),             -- データ種コード
              file_no                             = gt_upd_file_no(ln_idx),                    -- ファイルＮｏ
              info_class                          = gt_upd_info_class(ln_idx),                 -- 情報区分
              process_date                        = gt_upd_process_date(ln_idx),               -- 処理日
              process_time                        = gt_upd_process_time(ln_idx),               -- 処理時刻
              base_code                           = gt_upd_base_code(ln_idx),                  -- 拠点（部門）コード
              base_name                           = gt_upd_base_name(ln_idx),                  -- 拠点名（正式名）
              base_name_alt                       = gt_upd_base_name_alt(ln_idx),              -- 拠点名（カナ）
              edi_chain_code                      = gt_upd_edi_chain_code(ln_idx),             -- ＥＤＩチェーン店コード
              edi_chain_name                      = gt_upd_edi_chain_name(ln_idx),             -- ＥＤＩチェーン店名（漢字）
              edi_chain_name_alt                  = gt_upd_edi_chain_name_alt(ln_idx),         -- ＥＤＩチェーン店名（カナ）
              chain_code                          = gt_upd_chain_code(ln_idx),                 -- チェーン店コード
              chain_name                          = gt_upd_chain_name(ln_idx),                 -- チェーン店名（漢字）
              chain_name_alt                      = gt_upd_chain_name_alt(ln_idx),             -- チェーン店名（カナ）
              report_code                         = gt_upd_report_code(ln_idx),                -- 帳票コード
              report_show_name                    = gt_upd_report_show_name(ln_idx),           -- 帳票表示名
              customer_code                       = gt_upd_customer_code(ln_idx),              -- 顧客コード
              customer_name                       = gt_upd_customer_name(ln_idx),              -- 顧客名（漢字）
              customer_name_alt                   = gt_upd_customer_name_alt(ln_idx),          -- 顧客名（カナ）
              company_code                        = gt_upd_company_code(ln_idx),               -- 社コード
              company_name                        = gt_upd_company_name(ln_idx),               -- 社名（漢字）
              company_name_alt                    = gt_upd_company_name_alt(ln_idx),           -- 社名（カナ）
              shop_code                           = gt_upd_shop_code(ln_idx),                  -- 店コード
              shop_name                           = gt_upd_shop_name(ln_idx),                  -- 店名（漢字）
              shop_name_alt                       = gt_upd_shop_name_alt(ln_idx),              -- 店名（カナ）
              delivery_center_code                = gt_upd_delivery_cent_cd(ln_idx),           -- 納入センターコード
              delivery_center_name                = gt_upd_delivery_cent_nm(ln_idx),           -- 納入センター名（漢字）
              delivery_center_name_alt            = gt_upd_delivery_cent_nm_alt(ln_idx),       -- 納入センター名（カナ）
              order_date                          = gt_upd_order_date(ln_idx),                 -- 発注日
              center_delivery_date                = gt_upd_center_delivery_date(ln_idx),       -- センター納品日
              result_delivery_date                = gt_upd_result_delivery_date(ln_idx),       -- 実納品日
              shop_delivery_date                  = gt_upd_shop_delivery_date(ln_idx),         -- 店舗納品日
              data_creation_date_edi_data         = gt_upd_data_creation_date_edi(ln_idx),     -- データ作成日（ＥＤＩデータ中）
              data_creation_time_edi_data         = gt_upd_data_creation_time_edi(ln_idx),     -- データ作成時刻（ＥＤＩデータ中）
              invoice_class                       = gt_upd_invoice_class(ln_idx),              -- 伝票区分
              small_classification_code           = gt_upd_small_class_cd(ln_idx),             -- 小分類コード
              small_classification_name           = gt_upd_small_class_nm(ln_idx),             -- 小分類名
              middle_classification_code          = gt_upd_middle_class_cd(ln_idx),            -- 中分類コード
              middle_classification_name          = gt_upd_middle_class_nm(ln_idx),            -- 中分類名
              big_classification_code             = gt_upd_big_class_cd(ln_idx),               -- 大分類コード
              big_classification_name             = gt_upd_big_class_nm(ln_idx),               -- 大分類名
              other_party_department_code         = gt_upd_other_party_depart_cd(ln_idx),      -- 相手先部門コード
              other_party_order_number            = gt_upd_other_party_order_num(ln_idx),      -- 相手先発注番号
              check_digit_class                   = gt_upd_check_digit_class(ln_idx),          -- チェックデジット有無区分
              invoice_number                      = gt_upd_invoice_number(ln_idx),             -- 伝票番号
              check_digit                         = gt_upd_check_digit(ln_idx),                -- チェックデジット
              close_date                          = gt_upd_close_date(ln_idx),                 -- 月限
              order_no_ebs                        = gt_upd_order_no_ebs(ln_idx),               -- 受注Ｎｏ（ＥＢＳ）
              ar_sale_class                       = gt_upd_ar_sale_class(ln_idx),              -- 特売区分
              delivery_classe                     = gt_upd_delivery_classe(ln_idx),            -- 配送区分
              opportunity_no                      = gt_upd_opportunity_no(ln_idx),             -- 便Ｎｏ
              contact_to                          = gt_upd_contact_to(ln_idx),                 -- 連絡先
              route_sales                         = gt_upd_route_sales(ln_idx),                -- ルートセールス
              corporate_code                      = gt_upd_corporate_code(ln_idx),             -- 法人コード
              maker_name                          = gt_upd_maker_name(ln_idx),                 -- メーカー名
              area_code                           = gt_upd_area_code(ln_idx),                  -- 地区コード
              area_name                           = gt_upd_area_name(ln_idx),                  -- 地区名（漢字）
              area_name_alt                       = gt_upd_area_name_alt(ln_idx),              -- 地区名（カナ）
              vendor_code                         = gt_upd_vendor_code(ln_idx),                -- 取引先コード
              vendor_name                         = gt_upd_vendor_name(ln_idx),                -- 取引先名（漢字）
              vendor_name1_alt                    = gt_upd_vendor_name1_alt(ln_idx),           -- 取引先名１（カナ）
              vendor_name2_alt                    = gt_upd_vendor_name2_alt(ln_idx),           -- 取引先名２（カナ）
              vendor_tel                          = gt_upd_vendor_tel(ln_idx),                 -- 取引先ＴＥＬ
              vendor_charge                       = gt_upd_vendor_charge(ln_idx),              -- 取引先担当者
              vendor_address                      = gt_upd_vendor_address(ln_idx),             -- 取引先住所（漢字）
              deliver_to_code_itouen              = gt_upd_deliver_to_code_itouen(ln_idx),     -- 届け先コード（伊藤園）
              deliver_to_code_chain               = gt_upd_deliver_to_code_chain(ln_idx),      -- 届け先コード（チェーン店）
              deliver_to                          = gt_upd_deliver_to(ln_idx),                 -- 届け先（漢字）
              deliver_to1_alt                     = gt_upd_deliver_to1_alt(ln_idx),            -- 届け先１（カナ）
              deliver_to2_alt                     = gt_upd_deliver_to2_alt(ln_idx),            -- 届け先２（カナ）
              deliver_to_address                  = gt_upd_deliver_to_address(ln_idx),         -- 届け先住所（漢字）
              deliver_to_address_alt              = gt_upd_deliver_to_address_alt(ln_idx),     -- 届け先住所（カナ）
              deliver_to_tel                      = gt_upd_deliver_to_tel(ln_idx),             -- 届け先ＴＥＬ
              balance_accounts_code               = gt_upd_balance_acct_cd(ln_idx),            -- 帳合先コード
              balance_accounts_company_code       = gt_upd_balance_acct_company_cd(ln_idx),    -- 帳合先社コード
              balance_accounts_shop_code          = gt_upd_balance_acct_shop_cd(ln_idx),       -- 帳合先店コード
              balance_accounts_name               = gt_upd_balance_acct_nm(ln_idx),            -- 帳合先名（漢字）
              balance_accounts_name_alt           = gt_upd_balance_acct_nm_alt(ln_idx),        -- 帳合先名（カナ）
              balance_accounts_address            = gt_upd_balance_acct_addr(ln_idx),          -- 帳合先住所（漢字）
              balance_accounts_address_alt        = gt_upd_balance_acct_addr_alt(ln_idx),      -- 帳合先住所（カナ）
              balance_accounts_tel                = gt_upd_balance_acct_tel(ln_idx),           -- 帳合先ＴＥＬ
              order_possible_date                 = gt_upd_order_possible_date(ln_idx),        -- 受注可能日
              permission_possible_date            = gt_upd_permit_possible_date(ln_idx),       -- 許容可能日
              forward_month                       = gt_upd_forward_month(ln_idx),              -- 先限年月日
              payment_settlement_date             = gt_upd_payment_settlement_date(ln_idx),    -- 支払決済日
              handbill_start_date_active          = gt_upd_handbill_start_date_act(ln_idx),    -- チラシ開始日
              billing_due_date                    = gt_upd_billing_due_date(ln_idx),           -- 請求締日
              shipping_time                       = gt_upd_shipping_time(ln_idx),              -- 出荷時刻
              delivery_schedule_time              = gt_upd_delivery_schedule_time(ln_idx),     -- 納品予定時間
              order_time                          = gt_upd_order_time(ln_idx),                 -- 発注時間
              general_date_item1                  = gt_upd_general_date_item1(ln_idx),         -- 汎用日付項目１
              general_date_item2                  = gt_upd_general_date_item2(ln_idx),         -- 汎用日付項目２
              general_date_item3                  = gt_upd_general_date_item3(ln_idx),         -- 汎用日付項目３
              general_date_item4                  = gt_upd_general_date_item4(ln_idx),         -- 汎用日付項目４
              general_date_item5                  = gt_upd_general_date_item5(ln_idx),         -- 汎用日付項目５
              arrival_shipping_class              = gt_upd_arrival_shipping_class(ln_idx),     -- 入出荷区分
              vendor_class                        = gt_upd_vendor_class(ln_idx),               -- 取引先区分
              invoice_detailed_class              = gt_upd_invoice_detailed_class(ln_idx),     -- 伝票内訳区分
              unit_price_use_class                = gt_upd_unit_price_use_class(ln_idx),       -- 単価使用区分
              sub_distribution_center_code        = gt_upd_sub_dist_center_cd(ln_idx),         -- サブ物流センターコード
              sub_distribution_center_name        = gt_upd_sub_dist_center_nm(ln_idx),         -- サブ物流センターコード名
              center_delivery_method              = gt_upd_center_delivery_method(ln_idx),     -- センター納品方法
              center_use_class                    = gt_upd_center_use_class(ln_idx),           -- センター利用区分
              center_whse_class                   = gt_upd_center_whse_class(ln_idx),          -- センター倉庫区分
              center_area_class                   = gt_upd_center_area_class(ln_idx),          -- センター地域区分
              center_arrival_class                = gt_upd_center_arrival_class(ln_idx),       -- センター入荷区分
              depot_class                         = gt_upd_depot_class(ln_idx),                -- デポ区分
              tcdc_class                          = gt_upd_tcdc_class(ln_idx),                 -- ＴＣＤＣ区分
              upc_flag                            = gt_upd_upc_flag(ln_idx),                   -- ＵＰＣフラグ
              simultaneously_class                = gt_upd_simultaneously_class(ln_idx),       -- 一斉区分
              business_id                         = gt_upd_business_id(ln_idx),                -- 業務ＩＤ
              whse_directly_class                 = gt_upd_whse_directly_class(ln_idx),        -- 倉直区分
              premium_rebate_class                = gt_upd_premium_rebate_class(ln_idx),       -- 景品割戻区分
              item_type                           = gt_upd_item_type(ln_idx),                  -- 項目種別
              cloth_house_food_class              = gt_upd_cloth_house_food_class(ln_idx),     -- 衣家食区分
              mix_class                           = gt_upd_mix_class(ln_idx),                  -- 混在区分
              stk_class                           = gt_upd_stk_class(ln_idx),                  -- 在庫区分
              last_modify_site_class              = gt_upd_last_modify_site_class(ln_idx),     -- 最終修正場所区分
              report_class                        = gt_upd_report_class(ln_idx),               -- 帳票区分
              addition_plan_class                 = gt_upd_addition_plan_class(ln_idx),        -- 追加・計画区分
              registration_class                  = gt_upd_registration_class(ln_idx),         -- 登録区分
              specific_class                      = gt_upd_specific_class(ln_idx),             -- 特定区分
              dealings_class                      = gt_upd_dealings_class(ln_idx),             -- 取引区分
              order_class                         = gt_upd_order_class(ln_idx),                -- 発注区分
              sum_line_class                      = gt_upd_sum_line_class(ln_idx),             -- 集計明細区分
              shipping_guidance_class             = gt_upd_shipping_guidance_class(ln_idx),    -- 出荷案内以外区分
              shipping_class                      = gt_upd_shipping_class(ln_idx),             -- 出荷区分
              product_code_use_class              = gt_upd_product_code_use_class(ln_idx),     -- 商品コード使用区分
              cargo_item_class                    = gt_upd_cargo_item_class(ln_idx),           -- 積送品区分
              ta_class                            = gt_upd_ta_class(ln_idx),                   -- Ｔ／Ａ区分
              plan_code                           = gt_upd_plan_code(ln_idx),                  -- 企画コード
              category_code                       = gt_upd_category_code(ln_idx),              -- カテゴリーコード
              category_class                      = gt_upd_category_class(ln_idx),             -- カテゴリー区分
              carrier_means                       = gt_upd_carrier_means(ln_idx),              -- 運送手段
              counter_code                        = gt_upd_counter_code(ln_idx),               -- 売場コード
              move_sign                           = gt_upd_move_sign(ln_idx),                  -- 移動サイン
              eos_handwriting_class               = gt_upd_eos_handwriting_class(ln_idx),      -- ＥＯＳ・手書区分
              delivery_to_section_code            = gt_upd_delivery_to_sect_cd(ln_idx),        -- 納品先課コード
              invoice_detailed                    = gt_upd_invoice_detailed(ln_idx),           -- 伝票内訳
              attach_qty                          = gt_upd_attach_qty(ln_idx),                 -- 添付数
              other_party_floor                   = gt_upd_other_party_floor(ln_idx),          -- フロア
              text_no                             = gt_upd_text_no(ln_idx),                    -- ＴＥＸＴＮｏ
              in_store_code                       = gt_upd_in_store_code(ln_idx),              -- インストアコード
              tag_data                            = gt_upd_tag_data(ln_idx),                   -- タグ
              competition_code                    = gt_upd_competition_code(ln_idx),           -- 競合
              billing_chair                       = gt_upd_billing_chair(ln_idx),              -- 請求口座
              chain_store_code                    = gt_upd_chain_store_code(ln_idx),           -- チェーンストアーコード
              chain_store_short_name              = gt_upd_chain_store_short_name(ln_idx),     -- チェーンストアーコード略式名称
              direct_delivery_rcpt_fee            = gt_upd_dirct_delivery_rcpt_fee(ln_idx),    -- 直配送／引取料
              bill_info                           = gt_upd_bill_info(ln_idx),                  -- 手形情報
              description                         = gt_upd_description(ln_idx),                -- 摘要
              interior_code                       = gt_upd_interior_code(ln_idx),              -- 内部コード
              order_info_delivery_category        = gt_upd_order_info_delivery_cat(ln_idx),    -- 発注情報　納品カテゴリー
              purchase_type                       = gt_upd_purchase_type(ln_idx),              -- 仕入形態
              delivery_to_name_alt                = gt_upd_delivery_to_name_alt(ln_idx),       -- 納品場所名（カナ）
              shop_opened_site                    = gt_upd_shop_opened_site(ln_idx),           -- 店出場所
              counter_name                        = gt_upd_counter_name(ln_idx),               -- 売場名
              extension_number                    = gt_upd_extension_number(ln_idx),           -- 内線番号
              charge_name                         = gt_upd_charge_name(ln_idx),                -- 担当者名
              price_tag                           = gt_upd_price_tag(ln_idx),                  -- 値札
              tax_type                            = gt_upd_tax_type(ln_idx),                   -- 税種
              consumption_tax_class               = gt_upd_consumption_tax_class(ln_idx),      -- 消費税区分
              brand_class                         = gt_upd_brand_class(ln_idx),                -- ＢＲ
              id_code                             = gt_upd_id_code(ln_idx),                    -- ＩＤコード
              department_code                     = gt_upd_department_code(ln_idx),            -- 百貨店コード
              department_name                     = gt_upd_department_name(ln_idx),            -- 百貨店名
              item_type_number                    = gt_upd_item_type_number(ln_idx),           -- 品別番号
              description_department              = gt_upd_description_department(ln_idx),     -- 摘要（百貨店）
              price_tag_method                    = gt_upd_price_tag_method(ln_idx),           -- 値札方法
              reason_column                       = gt_upd_reason_column(ln_idx),              -- 自由欄
              a_column_header                     = gt_upd_a_column_header(ln_idx),            -- Ａ欄ヘッダ
              d_column_header                     = gt_upd_d_column_header(ln_idx),            -- Ｄ欄ヘッダ
              brand_code                          = gt_upd_brand_code(ln_idx),                 -- ブランドコード
              line_code                           = gt_upd_line_code(ln_idx),                  -- ラインコード
              class_code                          = gt_upd_class_code(ln_idx),                 -- クラスコード
              a1_column                           = gt_upd_a1_column(ln_idx),                  -- Ａ－１欄
              b1_column                           = gt_upd_b1_column(ln_idx),                  -- Ｂ－１欄
              c1_column                           = gt_upd_c1_column(ln_idx),                  -- Ｃ－１欄
              d1_column                           = gt_upd_d1_column(ln_idx),                  -- Ｄ－１欄
              e1_column                           = gt_upd_e1_column(ln_idx),                  -- Ｅ－１欄
              a2_column                           = gt_upd_a2_column(ln_idx),                  -- Ａ－２欄
              b2_column                           = gt_upd_b2_column(ln_idx),                  -- Ｂ－２欄
              c2_column                           = gt_upd_c2_column(ln_idx),                  -- Ｃ－２欄
              d2_column                           = gt_upd_d2_column(ln_idx),                  -- Ｄ－２欄
              e2_column                           = gt_upd_e2_column(ln_idx),                  -- Ｅ－２欄
              a3_column                           = gt_upd_a3_column(ln_idx),                  -- Ａ－３欄
              b3_column                           = gt_upd_b3_column(ln_idx),                  -- Ｂ－３欄
              c3_column                           = gt_upd_c3_column(ln_idx),                  -- Ｃ－３欄
              d3_column                           = gt_upd_d3_column(ln_idx),                  -- Ｄ－３欄
              e3_column                           = gt_upd_e3_column(ln_idx),                  -- Ｅ－３欄
              f1_column                           = gt_upd_f1_column(ln_idx),                  -- Ｆ－１欄
              g1_column                           = gt_upd_g1_column(ln_idx),                  -- Ｇ－１欄
              h1_column                           = gt_upd_h1_column(ln_idx),                  -- Ｈ－１欄
              i1_column                           = gt_upd_i1_column(ln_idx),                  -- Ｉ－１欄
              j1_column                           = gt_upd_j1_column(ln_idx),                  -- Ｊ－１欄
              k1_column                           = gt_upd_k1_column(ln_idx),                  -- Ｋ－１欄
              l1_column                           = gt_upd_l1_column(ln_idx),                  -- Ｌ－１欄
              f2_column                           = gt_upd_f2_column(ln_idx),                  -- Ｆ－２欄
              g2_column                           = gt_upd_g2_column(ln_idx),                  -- Ｇ－２欄
              h2_column                           = gt_upd_h2_column(ln_idx),                  -- Ｈ－２欄
              i2_column                           = gt_upd_i2_column(ln_idx),                  -- Ｉ－２欄
              j2_column                           = gt_upd_j2_column(ln_idx),                  -- Ｊ－２欄
              k2_column                           = gt_upd_k2_column(ln_idx),                  -- Ｋ－２欄
              l2_column                           = gt_upd_l2_column(ln_idx),                  -- Ｌ－２欄
              f3_column                           = gt_upd_f3_column(ln_idx),                  -- Ｆ－３欄
              g3_column                           = gt_upd_g3_column(ln_idx),                  -- Ｇ－３欄
              h3_column                           = gt_upd_h3_column(ln_idx),                  -- Ｈ－３欄
              i3_column                           = gt_upd_i3_column(ln_idx),                  -- Ｉ－３欄
              j3_column                           = gt_upd_j3_column(ln_idx),                  -- Ｊ－３欄
              k3_column                           = gt_upd_k3_column(ln_idx),                  -- Ｋ－３欄
              l3_column                           = gt_upd_l3_column(ln_idx),                  -- Ｌ－３欄
              chain_peculiar_area_header          = gt_upd_chain_pecul_area_head(ln_idx),      -- チェーン店固有エリア（ヘッダー）
--            order_connection_number             = gt_upd_order_connection_num(ln_idx),       -- 受注関連番号
--            invoice_indv_order_qty              = invoice_indv_order_qty + gt_upd_inv_indv_order_qty(ln_idx),         -- （伝票計）発注数量（バラ）
--            invoice_case_order_qty              = invoice_case_order_qty + gt_upd_inv_case_order_qty(ln_idx),         -- （伝票計）発注数量（ケース）
--            invoice_ball_order_qty              = invoice_ball_order_qty + gt_upd_inv_ball_order_qty(ln_idx),         -- （伝票計）発注数量（ボール）
--            invoice_sum_order_qty               = invoice_sum_order_qty + gt_upd_inv_sum_order_qty(ln_idx),           -- （伝票計）発注数量（合計、バラ）
              invoice_indv_shipping_qty           = gt_upd_inv_indv_shipping_qty(ln_idx),      -- （伝票計）出荷数量（バラ）
              invoice_case_shipping_qty           = gt_upd_inv_case_shipping_qty(ln_idx),      -- （伝票計）出荷数量（ケース）
              invoice_ball_shipping_qty           = gt_upd_inv_ball_shipping_qty(ln_idx),      -- （伝票計）出荷数量（ボール）
              invoice_pallet_shipping_qty         = gt_upd_inv_pallet_shipping_qty(ln_idx),    -- （伝票計）出荷数量（パレット）
              invoice_sum_shipping_qty            = gt_upd_inv_sum_shipping_qty(ln_idx),       -- （伝票計）出荷数量（合計、バラ）
              invoice_indv_stockout_qty           = gt_upd_inv_indv_stockout_qty(ln_idx),      -- （伝票計）欠品数量（バラ）
              invoice_case_stockout_qty           = gt_upd_inv_case_stockout_qty(ln_idx),      -- （伝票計）欠品数量（ケース）
              invoice_ball_stockout_qty           = gt_upd_inv_ball_stockout_qty(ln_idx),      -- （伝票計）欠品数量（ボール）
              invoice_sum_stockout_qty            = gt_upd_inv_sum_stockout_qty(ln_idx),       -- （伝票計）欠品数量（合計、バラ）
              invoice_case_qty                    = gt_upd_inv_case_qty(ln_idx),               -- （伝票計）ケース個口数
              invoice_fold_container_qty          = gt_upd_inv_fold_container_qty(ln_idx),     -- （伝票計）オリコン（バラ）個口数
--            invoice_order_cost_amt              = gt_upd_inv_order_cost_amt(ln_idx),         -- （伝票計）原価金額（発注）
              invoice_shipping_cost_amt           = gt_upd_inv_shipping_cost_amt(ln_idx),      -- （伝票計）原価金額（出荷）
              invoice_stockout_cost_amt           = gt_upd_inv_stockout_cost_amt(ln_idx),      -- （伝票計）原価金額（欠品）
              invoice_order_price_amt             = gt_upd_inv_order_price_amt(ln_idx),        -- （伝票計）売価金額（発注）
              invoice_shipping_price_amt          = gt_upd_inv_shipping_price_amt(ln_idx),     -- （伝票計）売価金額（出荷）
              invoice_stockout_price_amt          = gt_upd_inv_stockout_price_amt(ln_idx),     -- （伝票計）売価金額（欠品）
              total_indv_order_qty                = gt_upd_total_indv_order_qty(ln_idx),       -- （総合計）発注数量（バラ）
              total_case_order_qty                = gt_upd_total_case_order_qty(ln_idx),       -- （総合計）発注数量（ケース）
              total_ball_order_qty                = gt_upd_total_ball_order_qty(ln_idx),       -- （総合計）発注数量（ボール）
              total_sum_order_qty                 = gt_upd_total_sum_order_qty(ln_idx),        -- （総合計）発注数量（合計、バラ）
              total_indv_shipping_qty             = gt_upd_total_indv_ship_qty(ln_idx),        -- （総合計）出荷数量（バラ）
              total_case_shipping_qty             = gt_upd_total_case_ship_qty(ln_idx),        -- （総合計）出荷数量（ケース）
              total_ball_shipping_qty             = gt_upd_total_ball_ship_qty(ln_idx),        -- （総合計）出荷数量（ボール）
              total_pallet_shipping_qty           = gt_upd_total_pallet_ship_qty(ln_idx),      -- （総合計）出荷数量（パレット）
              total_sum_shipping_qty              = gt_upd_total_sum_ship_qty(ln_idx),         -- （総合計）出荷数量（合計、バラ）
              total_indv_stockout_qty             = gt_upd_total_indv_stockout_qty(ln_idx),    -- （総合計）欠品数量（バラ）
              total_case_stockout_qty             = gt_upd_total_case_stockout_qty(ln_idx),    -- （総合計）欠品数量（ケース）
              total_ball_stockout_qty             = gt_upd_total_ball_stockout_qty(ln_idx),    -- （総合計）欠品数量（ボール）
              total_sum_stockout_qty              = gt_upd_total_sum_stockout_qty(ln_idx),     -- （総合計）欠品数量（合計、バラ）
              total_case_qty                      = gt_upd_total_case_qty(ln_idx),             -- （総合計）ケース個口数
              total_fold_container_qty            = gt_upd_total_fold_contain_qty(ln_idx),     -- （総合計）オリコン（バラ）個口数
              total_order_cost_amt                = gt_upd_total_order_cost_amt(ln_idx),       -- （総合計）原価金額（発注）
              total_shipping_cost_amt             = gt_upd_total_shipping_cost_amt(ln_idx),    -- （総合計）原価金額（出荷）
              total_stockout_cost_amt             = gt_upd_total_stockout_cost_amt(ln_idx),    -- （総合計）原価金額（欠品）
              total_order_price_amt               = gt_upd_total_order_price_amt(ln_idx),      -- （総合計）売価金額（発注）
              total_shipping_price_amt            = gt_upd_total_ship_price_amt(ln_idx),       -- （総合計）売価金額（出荷）
              total_stockout_price_amt            = gt_upd_total_stock_price_amt(ln_idx),      -- （総合計）売価金額（欠品）
              total_line_qty                      = gt_upd_total_line_qty(ln_idx),             -- トータル行数
              total_invoice_qty                   = gt_upd_total_invoice_qty(ln_idx),          -- トータル伝票枚数
              chain_peculiar_area_footer          = gt_upd_chain_pecul_area_foot(ln_idx),      -- チェーン店固有エリア（フッター）
              conv_customer_code                  = gt_upd_conv_customer_code(ln_idx),         -- 変換後顧客コード
--            order_forward_flag                  = gt_upd_order_forward_flag(ln_idx),         -- 受注連携済フラグ
--            creation_class                      = gt_upd_creation_class(ln_idx),             -- 作成元区分
--            edi_delivery_schedule_flag          = gt_upd_edi_delivery_sche_flag(ln_idx),     -- EDI納品予定送信済フラグ
              price_list_header_id                = NVL( gt_upd_price_list_header_id(ln_idx), price_list_header_id ),
                                                                                               -- 価格表ヘッダID
-- 2009/12/28 M.Sano Ver.1.14 add Start
              tsukagatazaiko_div                  = gt_upd_tsukagatazaiko_div(ln_idx),             -- 通過在庫型区分
-- 2009/12/28 M.Sano Ver.1.14 add End
              last_updated_by                     = cn_last_updated_by,                        -- 最終更新者
              last_update_date                    = cd_last_update_date,                       -- 最終更新日
              last_update_login                   = cn_last_update_login,                      -- 最終更新ログイン
              request_id                          = cn_request_id,                             -- 要求ID
              program_application_id              = cn_program_application_id,                 -- コンカレント・プログラム・アプリケーションID
              program_id                          = cn_program_id,                             -- コンカレント・プログラムID
              program_update_date                 = cd_program_update_date                     -- プログラム更新日
      WHERE   edi_header_info_id                  = gt_upd_edi_header_info_id(ln_idx);
--
  EXCEPTION
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
      -- データ更新エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_lines
   * Description      : EDI明細情報テーブルデータ追加(A-17)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_lines(
    on_normal_cnt OUT NUMBER,                -- 正常件数
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    -- OUTパラメータ初期化
    on_normal_cnt := 0;
--
    -- EDI明細情報データ追加処理
    FORALL ln_idx IN 1..gt_edi_lines.COUNT
      INSERT INTO xxcos_edi_lines
        VALUES gt_edi_lines(ln_idx);
--
    -- 登録件数を設定
    on_normal_cnt := gt_edi_lines.COUNT;
--
  EXCEPTION
    -- *** キー重複例外ハンドラ ***
    WHEN DUP_VAL_ON_INDEX THEN
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
      -- データ登録エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_ins_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_lines
   * Description      : EDI明細情報テーブルデータ更新(A-18)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_lines(
    on_normal_cnt OUT NUMBER,                -- 正常件数
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_lines'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     INTEGER;
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
    -- OUTパラメータ初期化
    on_normal_cnt := 0;
--
    -- EDI明細情報データ更新処理
    FORALL ln_idx IN 1..gt_upd_edi_line_info_id.COUNT
      UPDATE  xxcos_edi_lines
      SET     stockout_class                 = gt_upd_stockout_class(ln_idx),              -- 欠品区分
              stockout_reason                = gt_upd_stockout_reason(ln_idx),             -- 欠品理由
              product_code_itouen            = gt_upd_product_code_itouen(ln_idx),         -- 商品コード（伊藤園）
              product_code1                  = gt_upd_product_code1(ln_idx),               -- 商品コード１
              product_code2                  = gt_upd_product_code2(ln_idx),               -- 商品コード２
              jan_code                       = gt_upd_jan_code(ln_idx),                    -- ＪＡＮコード
              itf_code                       = gt_upd_itf_code(ln_idx),                    -- ＩＴＦコード
              extension_itf_code             = gt_upd_extension_itf_code(ln_idx),          -- 内箱ＩＴＦコード
              case_product_code              = gt_upd_case_product_code(ln_idx),           -- ケース商品コード
              ball_product_code              = gt_upd_ball_product_code(ln_idx),           -- ボール商品コード
              product_code_item_type         = gt_upd_product_code_item_type(ln_idx),      -- 商品コード品種
              prod_class                     = gt_upd_prod_class(ln_idx),                  -- 商品区分
              product_name                   = gt_upd_product_name(ln_idx),                -- 商品名（漢字）
              product_name1_alt              = gt_upd_product_name1_alt(ln_idx),           -- 商品名１（カナ）
              product_name2_alt              = gt_upd_product_name2_alt(ln_idx),           -- 商品名２（カナ）
              item_standard1                 = gt_upd_item_standard1(ln_idx),              -- 規格１
              item_standard2                 = gt_upd_item_standard2(ln_idx),              -- 規格２
              qty_in_case                    = gt_upd_qty_in_case(ln_idx),                 -- 入数
              num_of_cases                   = gt_upd_num_of_cases(ln_idx),                -- ケース入数
              num_of_ball                    = gt_upd_num_of_ball(ln_idx),                 -- ボール入数
              item_color                     = gt_upd_item_color(ln_idx),                  -- 色
              item_size                      = gt_upd_item_size(ln_idx),                   -- サイズ
              expiration_date                = gt_upd_expiration_date(ln_idx),             -- 賞味期限日
              product_date                   = gt_upd_product_date(ln_idx),                -- 製造日
              order_uom_qty                  = gt_upd_order_uom_qty(ln_idx),               -- 発注単位数
              shipping_uom_qty               = gt_upd_shipping_uom_qty(ln_idx),            -- 出荷単位数
              packing_uom_qty                = gt_upd_packing_uom_qty(ln_idx),             -- 梱包単位数
              deal_code                      = gt_upd_deal_code(ln_idx),                   -- 引合
              deal_class                     = gt_upd_deal_class(ln_idx),                  -- 引合区分
              collation_code                 = gt_upd_collation_code(ln_idx),              -- 照合
              uom_code                       = gt_upd_uom_code(ln_idx),                    -- 単位
              unit_price_class               = gt_upd_unit_price_class(ln_idx),            -- 単価区分
              parent_packing_number          = gt_upd_parent_packing_number(ln_idx),       -- 親梱包番号
              packing_number                 = gt_upd_packing_number(ln_idx),              -- 梱包番号
              product_group_code             = gt_upd_product_group_code(ln_idx),          -- 商品群コード
              case_dismantle_flag            = gt_upd_case_dismantle_flag(ln_idx),         -- ケース解体不可フラグ
              case_class                     = gt_upd_case_class(ln_idx),                  -- ケース区分
              indv_order_qty                 = gt_upd_indv_order_qty(ln_idx),              -- 発注数量（バラ）
              case_order_qty                 = gt_upd_case_order_qty(ln_idx),              -- 発注数量（ケース）
              ball_order_qty                 = gt_upd_ball_order_qty(ln_idx),              -- 発注数量（ボール）
              sum_order_qty                  = gt_upd_sum_order_qty(ln_idx),               -- 発注数量（合計、バラ）
              indv_shipping_qty              = gt_upd_indv_shipping_qty(ln_idx),           -- 出荷数量（バラ）
              case_shipping_qty              = gt_upd_case_shipping_qty(ln_idx),           -- 出荷数量（ケース）
              ball_shipping_qty              = gt_upd_ball_shipping_qty(ln_idx),           -- 出荷数量（ボール）
              pallet_shipping_qty            = gt_upd_pallet_shipping_qty(ln_idx),         -- 出荷数量（パレット）
              sum_shipping_qty               = gt_upd_sum_shipping_qty(ln_idx),            -- 出荷数量（合計、バラ）
              indv_stockout_qty              = gt_upd_indv_stockout_qty(ln_idx),           -- 欠品数量（バラ）
              case_stockout_qty              = gt_upd_case_stockout_qty(ln_idx),           -- 欠品数量（ケース）
              ball_stockout_qty              = gt_upd_ball_stockout_qty(ln_idx),           -- 欠品数量（ボール）
              sum_stockout_qty               = gt_upd_sum_stockout_qty(ln_idx),            -- 欠品数量（合計、バラ）
              case_qty                       = gt_upd_case_qty(ln_idx),                    -- ケース個口数
              fold_container_indv_qty        = gt_upd_fold_container_indv_qty(ln_idx),     -- オリコン（バラ）個口数
              order_unit_price               = gt_upd_order_unit_price(ln_idx),            -- 原単価（発注）
              shipping_unit_price            = gt_upd_shipping_unit_price(ln_idx),         -- 原単価（出荷）
              order_cost_amt                 = gt_upd_order_cost_amt(ln_idx),              -- 原価金額（発注）
              shipping_cost_amt              = gt_upd_shipping_cost_amt(ln_idx),           -- 原価金額（出荷）
              stockout_cost_amt              = gt_upd_stockout_cost_amt(ln_idx),           -- 原価金額（欠品）
              selling_price                  = gt_upd_selling_price(ln_idx),               -- 売単価
              order_price_amt                = gt_upd_order_price_amt(ln_idx),             -- 売価金額（発注）
              shipping_price_amt             = gt_upd_shipping_price_amt(ln_idx),          -- 売価金額（出荷）
              stockout_price_amt             = gt_upd_stockout_price_amt(ln_idx),          -- 売価金額（欠品）
              a_column_department            = gt_upd_a_column_department(ln_idx),         -- Ａ欄（百貨店）
              d_column_department            = gt_upd_d_column_department(ln_idx),         -- Ｄ欄（百貨店）
              standard_info_depth            = gt_upd_standard_info_depth(ln_idx),         -- 規格情報・奥行き
              standard_info_height           = gt_upd_standard_info_height(ln_idx),        -- 規格情報・高さ
              standard_info_width            = gt_upd_standard_info_width(ln_idx),         -- 規格情報・幅
              standard_info_weight           = gt_upd_standard_info_weight(ln_idx),        -- 規格情報・重量
              general_succeeded_item1        = gt_upd_general_succeed_item1(ln_idx),       -- 汎用引継ぎ項目１
              general_succeeded_item2        = gt_upd_general_succeed_item2(ln_idx),       -- 汎用引継ぎ項目２
              general_succeeded_item3        = gt_upd_general_succeed_item3(ln_idx),       -- 汎用引継ぎ項目３
              general_succeeded_item4        = gt_upd_general_succeed_item4(ln_idx),       -- 汎用引継ぎ項目４
              general_succeeded_item5        = gt_upd_general_succeed_item5(ln_idx),       -- 汎用引継ぎ項目５
              general_succeeded_item6        = gt_upd_general_succeed_item6(ln_idx),       -- 汎用引継ぎ項目６
              general_succeeded_item7        = gt_upd_general_succeed_item7(ln_idx),       -- 汎用引継ぎ項目７
              general_succeeded_item8        = gt_upd_general_succeed_item8(ln_idx),       -- 汎用引継ぎ項目８
              general_succeeded_item9        = gt_upd_general_succeed_item9(ln_idx),       -- 汎用引継ぎ項目９
              general_succeeded_item10       = gt_upd_general_succeed_item10(ln_idx),      -- 汎用引継ぎ項目１０
              general_add_item1              = gt_upd_general_add_item1(ln_idx),           -- 汎用付加項目１
              general_add_item2              = gt_upd_general_add_item2(ln_idx),           -- 汎用付加項目２
              general_add_item3              = gt_upd_general_add_item3(ln_idx),           -- 汎用付加項目３
              general_add_item4              = gt_upd_general_add_item4(ln_idx),           -- 汎用付加項目４
              general_add_item5              = gt_upd_general_add_item5(ln_idx),           -- 汎用付加項目５
              general_add_item6              = gt_upd_general_add_item6(ln_idx),           -- 汎用付加項目６
              general_add_item7              = gt_upd_general_add_item7(ln_idx),           -- 汎用付加項目７
              general_add_item8              = gt_upd_general_add_item8(ln_idx),           -- 汎用付加項目８
              general_add_item9              = gt_upd_general_add_item9(ln_idx),           -- 汎用付加項目９
              general_add_item10             = gt_upd_general_add_item10(ln_idx),          -- 汎用付加項目１０
              chain_peculiar_area_line       = gt_upd_chain_pecul_area_line(ln_idx),       -- チェーン店固有エリア（明細）
              item_code                      = gt_upd_item_code(ln_idx),                   -- 品目コード
              line_uom                       = gt_upd_line_uom(ln_idx),                    -- 明細単位
              order_connection_line_number   = gt_upd_order_connect_line_num(ln_idx),      -- 受注関連明細番号
              last_updated_by                = cn_last_updated_by,                         -- 最終更新者
              last_update_date               = cd_last_update_date,                        -- 最終更新日
              last_update_login              = cn_last_update_login,                       -- 最終更新ログイン
              request_id                     = cn_request_id,                              -- 要求ID
              program_application_id         = cn_program_application_id,                  -- コンカレント・プログラム・アプリケーションID
              program_id                     = cn_program_id,                              -- コンカレント・プログラムID
              program_update_date            = cd_program_update_date                      -- プログラム更新日
      WHERE   edi_line_info_id               = gt_upd_edi_line_info_id(ln_idx)             -- EDI明細情報ID
      AND     edi_header_info_id             = gt_upd_edi_line_header_info_id(ln_idx);     -- EDIヘッダ情報ID
--
    -- 更新件数を設定
    on_normal_cnt := gt_upd_edi_line_info_id.COUNT;
--
  EXCEPTION
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
      -- データ更新エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_edi_lines;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_errors
   * Description      : EDIエラー情報テーブルデータ削除(A-19-1)
   ***********************************************************************************/
  PROCEDURE proc_del_edi_errors(
    iv_exe_type   IN  VARCHAR2,              -- 実行区分
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_errors'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx               NUMBER;
    ld_purge_date        DATE;
    lt_work_id           xxcos_edi_errors.work_id%TYPE;
--
    -- *** ローカル・カーソル ***
    -- EDI情報削除対象カーソル(EDIヘッダID)
    CURSOR edi_errors_lock1_cur (
      it_work_id     xxcos_edi_errors.work_id%TYPE
    )
    IS
      SELECT  xee.edi_err_id                       -- EDIエラーID
      FROM    xxcos_edi_errors  xee                -- EDIエラーテーブル
      WHERE   xee.work_id = it_work_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    IF ( iv_exe_type = cv_exe_type_retry ) THEN
      -- EDI情報削除対象のEDIエラー情報テーブルのロックを取得する。
      <<work_id_lock_loop>>
      FOR ln_idx IN 1..gt_order_info_work_id.COUNT LOOP
        lt_work_id := gt_order_info_work_id(ln_idx);
        OPEN edi_errors_lock1_cur(lt_work_id);
        CLOSE edi_errors_lock1_cur;
      END LOOP work_id_lock_loop;
--
      -- 対象データを削除
      FORALL ln_idx IN 1..gt_order_info_work_id.COUNT
        DELETE
        FROM   xxcos_edi_errors xee
        WHERE  xee.work_id = gt_order_info_work_id(ln_idx)
        ;
    END IF;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- ロックエラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_errors_lock1_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock1_cur;
      END IF;
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
      -- データ削除エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_errors_lock1_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock1_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END proc_del_edi_errors;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_errors
   * Description      : EDIエラー情報テーブルデータ追加(A-19)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_errors(
    on_warn_cnt   OUT NOCOPY NUMBER,         -- 警告件数
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_errors'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx     NUMBER;
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
    -- OUTパラメータ初期化
    on_warn_cnt := 0;
--
    -- EDIエラー情報データ追加処理
    FORALL ln_idx IN 1..gt_edi_errors.COUNT
      INSERT INTO xxcos_edi_errors
        VALUES gt_edi_errors(ln_idx);
--
    -- 警告件数を設定
    on_warn_cnt := gt_edi_errors.COUNT;
--
  EXCEPTION
    -- *** キー重複例外ハンドラ ***
    WHEN DUP_VAL_ON_INDEX THEN
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
      -- データ登録エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_ins_edi_errors;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_work
   * Description      : EDI受注情報ワークテーブルステータス更新(A-20)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_work(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx          NUMBER;
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
    -- EDI受注情報ワークテーブルのステータスを一括更新する
    FORALL ln_idx IN 1..gt_order_info_work_id.COUNT
      UPDATE  xxcos_edi_order_work                                              -- EDI受注情報ワークテーブル
      SET     err_status                = gt_edi_err_status(ln_idx),            -- ステータス
              last_updated_by           = cn_last_updated_by,                   -- 最終更新者
              last_update_date          = cd_last_update_date,                  -- 最終更新日
              last_update_login         = cn_last_update_login,                 -- 最終更新ログイン
              request_id                = cn_request_id,                        -- 要求ID
              program_application_id    = cn_program_application_id,            -- コンカレント・プログラム・アプリケーションID
              program_id                = cn_program_id,                        -- コンカレント・プログラムID
              program_update_date       = cd_program_update_date                -- プログラム更新日
      WHERE   order_info_work_id        = gt_order_info_work_id(ln_idx);        -- EDI受注情報ワークID
--
  EXCEPTION
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
      -- データ更新エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_upd_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_work
   * Description      : EDI受注情報ワークテーブルデータ削除(A-21)
   ***********************************************************************************/
  PROCEDURE proc_del_edi_work(
    iv_filename   IN  VARCHAR2,              -- インタフェースファイル名
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_edi_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx          NUMBER;
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
    -- EDI受注情報ワークテーブルデータ削除（正常データのみ）
    DELETE
    FROM    xxcos_edi_order_work                            -- EDI受注情報ワークテーブル
    WHERE   if_file_name     = iv_filename                  -- インタフェースファイル名
    AND     data_type_code   = cv_data_type_code            -- データ種コード：受注
    AND     err_status       = cv_edi_status_normal;        -- ステータスが「正常」
--
  EXCEPTION
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
      -- データ削除エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#####################################  固定部 END   ##########################################
--
  END proc_del_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_head_line
   * Description      : EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-22)
   *                    EDI情報削除期間を経過しているデータを削除する
   ***********************************************************************************/
  PROCEDURE proc_del_edi_head_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_edi_head_line'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(100);   -- メッセージトークン１
    lv_tkn2    VARCHAR2(100);   -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_purge_date        DATE;
--
    -- *** ローカル・カーソル ***
--
    -- EDI情報削除対象カーソル
    CURSOR edi_head_line_cur(
      id_purge_date DATE                                         -- EDI情報削除基準日
    )
    IS
-- 2009/09/02 Ver1.9 M.Sano Mod Start
--      SELECT  head.edi_header_info_id,                           -- EDIヘッダ情報ID
      SELECT  /*+ 
                LEADING( head )
                USE_NL( line )
                INDEX( head xxcos_edi_headers_n06)
                INDEX( line xxcos_edi_lines_n01)
               */
              head.edi_header_info_id,                           -- EDIヘッダ情報ID
-- 2009/09/02 Ver1.9 M.Sano Mod End
              line.edi_line_info_id                              -- EDI明細情報ID
      FROM    xxcos_edi_lines           line,                    -- EDI明細情報テーブル
              xxcos_edi_headers         head                     -- EDIヘッダ情報テーブル
      WHERE   head.data_type_code       = cv_data_type_code      -- データ種コード：EDI受注
      AND     head.edi_header_info_id   = line.edi_header_info_id
      AND     NVL( head.shop_delivery_date,                      -- 店舗納品日
                NVL( head.center_delivery_date,                  -- センター納品日
                  NVL( head.order_date,                          -- 発注日
                    TRUNC( head.data_creation_date_edi_data )    -- データ作成日（ＥＤＩデータ中）
                  )
                )
              )                         < id_purge_date
      FOR UPDATE NOWAIT;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- EDI情報削除対象カーソル(EDI受信日)
    CURSOR edi_errors_lock2_cur (
      id_purge_date DATE
    )
    IS
      SELECT  xee.edi_err_id                          -- EDIエラーID
      FROM    xxcos_edi_errors  xee                   -- EDIエラーテーブル
      WHERE   xee.creation_date     < id_purge_date       -- 作成日がパージ対象日以前
      AND     xee.edi_create_class  = cv_edi_create_class -- エラーリスト種別：受注
      FOR UPDATE NOWAIT;
--
-- 2010/01/19 Ver1.15 M.Sano Add End
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
    -- EDI情報削除基準日を取得
    SELECT  TRUNC( SYSDATE - TO_NUMBER( gv_purge_term ) )
    INTO    ld_purge_date
    FROM    dual;
--
    -- ロックカーソルオープン
    OPEN edi_head_line_cur(ld_purge_date);
--
    -- EDI明細情報テーブルデータ削除
-- 2009/09/02 Ver1.9 M.Sano Add Start
--    DELETE
--    FROM    xxcos_edi_lines
--    WHERE   edi_line_info_id IN (
--              SELECT  edi_line_info_id                                -- EDI明細情報ID
    DELETE /*+ INDEX ( line_d xxcos_edi_lines_pk ) */
    FROM    xxcos_edi_lines line_m
    WHERE   line_m.edi_line_info_id IN (
              SELECT  
                  /*+ LEADING( head )
                      USE_NL( line )
                      INDEX( head xxcos_edi_headers_n06)
                      INDEX( line xxcos_edi_lines_n01)   */
                      edi_line_info_id                                -- EDI明細情報ID
-- 2009/09/02 Ver1.9 M.Sano Mod END
              FROM    xxcos_edi_lines         line,                   -- EDI明細情報テーブル
                      xxcos_edi_headers       head                    -- EDIヘッダ情報テーブル
              WHERE   head.data_type_code     = cv_data_type_code     -- データ種コード：EDI受注
              AND     head.edi_header_info_id = line.edi_header_info_id
              AND     NVL( head.shop_delivery_date,                   -- 店舗納品日
                        NVL( head.center_delivery_date,               -- センター納品日
                          NVL( head.order_date,                       -- 発注日
                            TRUNC( head.data_creation_date_edi_data ) -- データ作成日（ＥＤＩデータ中）
                          )
                        )
                      )                       < ld_purge_date
            );
--
    -- EDIヘッダ情報テーブルデータ削除
    DELETE
    FROM    xxcos_edi_headers                 head                    -- EDIヘッダ情報テーブル
    WHERE   head.data_type_code               = cv_data_type_code     -- データ種コード：EDI受注
    AND     NVL( head.shop_delivery_date,                             -- 店舗納品日
              NVL( head.center_delivery_date,                         -- センター納品日
                NVL( head.order_date,                                 -- 発注日
                  TRUNC( head.data_creation_date_edi_data )           -- データ作成日（ＥＤＩデータ中）
                )
              )
            )                                 < ld_purge_date;
--
    -- ロックカーソルクローズ
    CLOSE edi_head_line_cur;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- EDI情報削除基準日を取得
    SELECT  TRUNC( SYSDATE - TO_NUMBER( gv_err_purge_term ) )
    INTO    ld_purge_date
    FROM    dual;
--
    -- EDI情報削除対象のEDIエラー情報テーブルのロックを取得する。
    OPEN edi_errors_lock2_cur(ld_purge_date);
    CLOSE edi_errors_lock2_cur;
--
    -- 対象データを削除
    DELETE
    FROM   xxcos_edi_errors xee
    WHERE  xee.creation_date    < ld_purge_date       -- 作成日がパージ対象日以前
    AND    xee.edi_create_class = cv_edi_create_class -- エラーリスト種別：受注
    ;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- ロックエラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
-- 2010/01/19 Ver1.15 M.Sano Del Start
--      ov_retcode := cv_status_error;
-- 2010/01/19 Ver1.15 M.Sano Del End
--
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_head_line_cur%ISOPEN ) THEN
        CLOSE edi_head_line_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add Start
      IF ( edi_errors_lock2_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock2_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
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
      -- データ削除エラーを出力
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      -- カーソルがオープンしている場合はクローズする
      IF ( edi_head_line_cur%ISOPEN ) THEN
        CLOSE edi_head_line_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add Start
      IF ( edi_errors_lock2_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock2_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
--#####################################  固定部 END   ##########################################
--
  END proc_del_edi_head_line;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_loop_main
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE proc_loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_loop_main'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_tkn1    VARCHAR2(20);    -- メッセージトークン１
    lv_tkn2    VARCHAR2(20);    -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_idx                    NUMBER;
    ln_cnt                    NUMBER;
    ln_edi_head_id            NUMBER := NULL;          -- EDIヘッダ情報ID
    ln_edi_line_id            NUMBER := NULL;          -- EDI明細情報ID
    lv_invoice_number         xxcos_edi_order_work.invoice_number%TYPE := NULL;
    ln_edi_head_ins_flag      NUMBER(1) := 0;          -- EDIヘッダ情報登録フラグ
    ln_head_duplicate_err     NUMBER := 0;             -- ヘッダ重複エラーフラグ
    ln_line_duplicate_err     NUMBER := 0;             -- 明細重複エラーフラグ
-- 2009/06/29 M.Sano Ver.1.6 add Start
    lv_shop_code              xxcos_edi_order_work.shop_code%TYPE      := NULL;  -- 店コード
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2009/11/19 M.Sano Ver.1.11 add Start
    lv_edi_chain_code         xxcos_edi_order_work.edi_chain_code%TYPE := NULL;  -- EDIチェーン店コード
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
    lt_shop_delivery_date     xxcos_edi_order_work.shop_delivery_date%TYPE := NULL;  -- 店舗納品日
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
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
    -- EDI受注情報ワークテーブルデータをループ
    <<loop_edi_order_work>>
    FOR ln_idx IN 1..gt_edi_order_work.COUNT LOOP
--
      -- 伝票番号を保持する
      lv_invoice_number := gt_edi_order_work(ln_idx).invoice_number;
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- 店コードを保持する
      lv_shop_code      := gt_edi_order_work(ln_idx).shop_code;
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2009/11/19 M.Sano Ver.1.11 add Start
      -- EDIチェーン店コードを保持する
      lv_edi_chain_code := gt_edi_order_work(ln_idx).edi_chain_code;
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
      -- 店舗納品日を保持する
      lt_shop_delivery_date := gt_edi_order_work(ln_idx).shop_delivery_date;
-- 2009/11/25 K.Atsushiba Ver.1.12 Add END
--
      -- ============================================
      -- EDI受注情報ワーク変数格納(A-5)
      -- ============================================
      proc_set_edi_work(
        gt_edi_order_work(ln_idx),
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      -- データ取得に失敗した場合、処理中止
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/11/25 K.Atsushiba Ver.1.12 Mod Start
--      -- 伝票番号が変わったら
--      IF ( ( ln_idx = gt_edi_order_work.COUNT )
---- 2009/11/19 M.Sano Ver.1.11 add Start
--      OR ( lv_edi_chain_code != gt_edi_order_work(ln_idx + 1).edi_chain_code )
---- 2009/11/19 M.Sano Ver.1.11 add End
---- 2009/06/29 M.Sano Ver.1.6 add Start
--      OR ( lv_shop_code      != gt_edi_order_work(ln_idx + 1).shop_code )
---- 2009/06/29 M.Sano Ver.1.6 add End
--      OR ( lv_invoice_number != gt_edi_order_work(ln_idx + 1).invoice_number ) ) THEN
--
      -- EDIヘッダキーチェック
      IF ( ( ln_idx != gt_edi_order_work.COUNT )
           AND
           ( ( lv_edi_chain_code = gt_edi_order_work(ln_idx + 1).edi_chain_code )
             AND
             ( lv_invoice_number = gt_edi_order_work(ln_idx + 1).invoice_number )
             AND
             ( ( ( lv_shop_code IS NULL ) AND ( gt_edi_order_work(ln_idx + 1).shop_code IS NULL ) )
               OR
               ( lv_shop_code = gt_edi_order_work(ln_idx + 1).shop_code )
             )
             AND
             ( ( ( lt_shop_delivery_date IS NULL ) AND ( gt_edi_order_work(ln_idx + 1).shop_delivery_date IS NULL ) )
               OR
               ( lt_shop_delivery_date = gt_edi_order_work(ln_idx + 1).shop_delivery_date )
             )
           )
      ) THEN
        -- EDIヘッダが同じ場合
        NULL;
      ELSE
        -- EDIヘッダが変わった場合
-- 2009/11/25 K.Atsushiba Ver.1.12 Mod End
        -- 伝票エラーフラグ初期化
        gn_invoice_err_flag := 0;
        -- ヘッダ重複エラーフラグ初期化
        ln_head_duplicate_err := 0;
--
        -- ============================================
        -- データ妥当性チェック(A-4)
        -- ============================================
        proc_data_validate(
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
--
        -- エラーが発生している場合
        IF ( lv_retcode != cv_status_normal ) THEN
          -- 終了ステータス設定
          ov_retcode := lv_retcode;
        END IF;
--
        -- 伝票エラーが発生していない場合
        IF ( gn_invoice_err_flag = 0 ) THEN
--
          -- EDIヘッダ、明細IDを初期化
          ln_edi_head_id := NULL;
          ln_edi_line_id := NULL;
          ln_edi_head_ins_flag := 0;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--          -- ============================================
--          -- EDIヘッダ情報テーブルデータ抽出(A-7)
--          -- ============================================
--          proc_get_edi_headers(
--            gt_edi_work(gt_edi_work.first),
--            ln_edi_head_id,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
----
--          -- A-7でエラーが発生した場合、処理中止
--          IF ( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
          IF ( gn_check_record_flag = cn_check_record_yes ) THEN
            -- ============================================
            -- EDIヘッダ情報テーブルデータ抽出(A-7)
            -- ============================================
            proc_get_edi_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
  --
            -- A-7でエラーが発生した場合、処理中止
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSE
            ln_edi_head_id := NULL;
          END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
          -- EDIヘッダ情報が存在しない場合
          IF ( ln_edi_head_id IS NULL ) THEN
--
            -- ============================================
            -- EDIヘッダ情報インサート用変数格納(A-8)
            -- ============================================
            proc_set_ins_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            -- A-8で例外が発生した場合、処理中止
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- EDIヘッダ情報インサート済
            ln_edi_head_ins_flag := 1;
--
          -- 当該データが警告ステータスの場合、EDIヘッダ情報をアップデートする
          ELSIF ( gt_edi_work(gt_edi_work.first).err_status = cv_edi_status_warning ) THEN
--
            -- ============================================
            -- EDIヘッダ情報アップデート用変数格納(A-9)
            -- ============================================
            proc_set_upd_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            -- A-9で例外が発生した場合、処理中止
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ステータスが警告以外の場合
          ELSE
--
            -- ヘッダ重複エラーを設定
            ln_head_duplicate_err := 1;
            -- 終了ステータスに警告を設定
            ov_retcode := cv_status_warn;
--
          END IF;
--
          -- 伝票明細合計を初期化
          gt_inv_total.indv_order_qty := 0;
          gt_inv_total.case_order_qty := 0;
          gt_inv_total.ball_order_qty := 0;
          gt_inv_total.sum_order_qty  := 0;
          gt_inv_total.order_cost_amt := 0;
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
          gt_inv_total.shipping_cost_amt := 0;
          gt_inv_total.stockout_cost_amt := 0;
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
--
          <<loop_set_edi_lines>>
          FOR ln_Idx IN 1..gt_edi_work.COUNT LOOP
--
            -- 明細重複エラーフラグ初期化
            ln_line_duplicate_err := 0;
--
            -- 伝票エラー、ヘッダ重複エラーが発生していない場合
            IF (( gn_invoice_err_flag = 0 ) AND ( ln_head_duplicate_err = 0 )) THEN
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--              -- ============================================
--              -- EDI明細情報テーブルデータ抽出(A-10)
--              -- ============================================
--              proc_get_edi_lines(
--                gt_edi_work(ln_Idx),
--                ln_edi_head_id,
--                ln_edi_line_id,
--                lv_errbuf,
--                lv_retcode,
--                lv_errmsg
--              );
----
--              -- A-10でエラーが発生した場合、処理中止
--              IF ( lv_retcode = cv_status_error ) THEN
--                RAISE global_process_expt;
--              END IF;
              IF ( gn_check_record_flag = cn_check_record_yes ) THEN
                -- ============================================
                -- EDI明細情報テーブルデータ抽出(A-10)
                -- ============================================
                proc_get_edi_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-10でエラーが発生した場合、処理中止
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
              ELSE
                ln_edi_line_id := NULL;
              END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
              -- EDI明細情報が存在しない場合
              IF ( ln_edi_line_id IS NULL ) THEN
--
                -- ============================================
                -- EDI明細情報インサート用変数格納(A-11)
                -- ============================================
                proc_set_ins_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-11でエラーが発生した場合、処理中止
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
--
              -- 当該データが警告ステータスの場合、EDI明細情報をアップデートする
              ELSIF ( gt_edi_work(ln_Idx).err_status = cv_edi_status_warning ) THEN
--
                -- ============================================
                -- EDI明細情報アップデート用変数格納(A-12)
                -- ============================================
                proc_set_upd_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-12でエラーが発生した場合、処理中止
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
--
              -- ステータスが警告以外の場合
              ELSE
--
                -- 明細重複エラーを設定
                ln_line_duplicate_err := 1;
                -- 終了ステータスに警告を設定
                ov_retcode := cv_status_warn;
--
              END IF;
--
              -- ============================================
              -- 伝票毎の合計値を算出(A-13)
              -- ============================================
              proc_calc_inv_total(
                gt_edi_work(ln_Idx),
                lv_errbuf,
                lv_retcode,
                lv_errmsg
              );
--
              -- A-13でエラーが発生した場合、処理中止
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF;
--
            -- ヘッダ重複エラー、明細重複エラーが発生した場合は、エラーメッセージを出力
            IF (( ln_head_duplicate_err = 1 ) OR ( ln_line_duplicate_err = 1 )) THEN
--
              -- 重複登録エラーを出力
              lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,
                                                      cv_msg_duplicate,
                                                      cv_tkn_chain_shop_code,
                                                      gt_edi_work(ln_Idx).edi_chain_code,
                                                      cv_tkn_order_no,
                                                      gt_edi_work(ln_Idx).invoice_number,
                                                      cv_tkn_store_deliv_dt,
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--                                                      gt_edi_work(ln_Idx).shop_delivery_date,
                                                      TO_CHAR(gt_edi_work(ln_Idx).shop_delivery_date,
                                                              cv_format_yyyymmdds),
-- 2010/01/19 Ver.1.15 M.Sano mod End
                                                      cv_tkn_shop_code,
                                                      gt_edi_work(ln_Idx).shop_code,
                                                      cv_tkn_line_no,
                                                      gt_edi_work(ln_Idx).line_no );
              lv_errbuf  := lv_errmsg;
              -- ログ出力
              proc_msg_output( cv_prg_name, lv_errbuf );
              -- 警告ステータス設定
              gt_edi_work(ln_Idx).check_status := cv_edi_status_warning;
              -- EDIエラー情報追加
              proc_set_edi_errors( gt_edi_work(ln_Idx), NULL, cv_error_delete_flag, cv_msg_rep_duplicate );
--
            END IF;
--
          END LOOP;
--
          -- ============================================
          -- EDIヘッダ情報用変数に伝票計を設定(A-14)
          -- ============================================
          proc_set_inv_total(
            ln_edi_head_ins_flag,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
          );
--
          -- A-14でエラーが発生した場合、処理中止
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- 伝票エラーが発生している場合
        ELSE
--
          -- スキップ件数に伝票明細数を加算
          gn_skip_cnt := gn_skip_cnt + gt_edi_work.COUNT;
--
        END IF;
--
        -- ============================================
        -- EDIステータス更新用変数格納(A-6)
        -- ============================================
        -- 伝票単位の全明細のステータスを保持する
        <<loop_set_edi_status>>
        FOR ln_cnt IN 1..gt_edi_work.COUNT LOOP
          -- ステータスを保持
          proc_set_edi_status(
            gt_edi_work(ln_cnt).order_info_work_id,
            gt_edi_work(ln_cnt).check_status,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
          );
--
          -- A-6でエラーが発生した場合、処理中止
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP;
--
        -- EDI納品返品情報ワーク変数をクリア
        gt_edi_work.DELETE;
--
      END IF;
--
    END LOOP;
--
  EXCEPTION
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
  END proc_loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- 2010/01/19 Ver1.15 M.Sano Add Start
--    iv_filename   IN  VARCHAR2,              --   インタフェースファイル名
--    iv_exetype    IN  VARCHAR2,              --   実行区分（0：新規、1：再実施）
    iv_filename       IN  VARCHAR2,              --   インタフェースファイル名
    iv_exetype        IN  VARCHAR2,              --   実行区分（0：新規、1：再実施）
    iv_edi_chain_code IN  VARCHAR2,              --   EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Add End
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_tkn1    VARCHAR2(20);    -- メッセージトークン１
    lv_tkn2    VARCHAR2(20);    -- メッセージトークン２
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_invoice_number         xxcos_edi_order_work.invoice_number%TYPE := NULL;
    ln_ins_normal_cnt         NUMBER := 0;             -- 正常件数（登録用）
    ln_upd_normal_cnt         NUMBER := 0;             -- 正常件数（更新用）
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
    gn_skip_cnt   := 0;
    gt_edi_work   := g_edi_work_ttype();
    gt_edi_order_work.DELETE;
    gt_order_info_work_id.DELETE;
    gt_edi_headers.DELETE;
    gt_edi_lines.DELETE;
    gt_edi_errors.DELETE;
    gt_upd_edi_header_info_id.DELETE;
    gt_upd_edi_line_info_id.DELETE;
--
    -- ============================================
    -- 入力パラメータ妥当性チェック(A-1)
    -- ============================================
    proc_param_check(
      iv_filename,
      iv_exetype,
-- 2010/01/19 Ver1.15 M.Sano Add Start
      iv_edi_chain_code,
-- 2010/01/19 Ver1.15 M.Sano Add End
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- チェックエラーの場合、処理中止
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- 初期処理(A-2)
    -- ============================================
    proc_init(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラー発生の場合、処理中止
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_retcode := lv_retcode;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI受注情報ワークテーブルデータ抽出(A-3)
    -- ============================================
    proc_get_edi_work(
      iv_filename,
      iv_exetype,
-- 2010/01/19 Ver1.15 M.Sano Add Start
      iv_edi_chain_code,
-- 2010/01/19 Ver1.15 M.Sano Add End
      gn_target_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーの場合、処理中止
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- ループメイン処理
    -- ============================================
    proc_loop_main(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- 警告が発生している場合は、ステータスを保持する
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
--
    -- エラーが発生した場合は処理中止
    ELSIF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    --EDIヘッダ情報テーブルデータ追加(A-15)
    -- ============================================
    proc_ins_edi_headers(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDIヘッダ情報テーブルデータ更新(A-16)
    -- ============================================
    proc_upd_edi_headers(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI明細情報テーブルデータ追加(A-17)
    -- ============================================
    proc_ins_edi_lines(
      ln_ins_normal_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI明細情報テーブルデータ更新(A-18)
    -- ============================================
    proc_upd_edi_lines(
      ln_upd_normal_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- 正常件数を設定
    gn_normal_cnt := ln_ins_normal_cnt + ln_upd_normal_cnt;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- ============================================
    -- EDIエラー情報テーブルデータ削除(A-18-1)
    -- ============================================
    proc_del_edi_errors(
      iv_exetype,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
    -- ============================================
    -- EDIエラー情報テーブルデータ追加(A-19)
    -- ============================================
    proc_ins_edi_errors(
      gn_warn_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI受注情報ワークテーブルステータス更新(A-20)
    -- ============================================
    proc_upd_edi_work(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI受注情報ワークテーブルデータ削除(A-21)
    -- ============================================
    proc_del_edi_work(
      iv_filename,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ここまで正常ならばコミット
    COMMIT;
--
    -- ============================================
    -- EDIヘッダ情報テーブル、EDI明細情報テーブルデータ削除(A-22)
    -- ============================================
    proc_del_edi_head_line(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- エラーが発生した場合は処理中止
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,              --   リターン・コード    --# 固定 #
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_file_name  IN  VARCHAR2,              --   インタフェースファイル名
--    iv_exetype    IN  VARCHAR2               --   実行区分（0：新規、1：再実施）
    iv_file_name      IN  VARCHAR2 DEFAULT NULL,    --   インタフェースファイル名
    iv_exetype        IN  VARCHAR2 DEFAULT NULL,    --   実行区分（0：新規、1：再実施）
    iv_edi_chain_code IN  VARCHAR2 DEFAULT NULL     --   EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Mod End
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
       ov_retcode => lv_retcode
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
       iv_file_name -- インタフェースファイル名
      ,iv_exetype   -- 実行区分
-- 2010/01/19 Ver1.15 M.Sano Add Start
      ,iv_edi_chain_code  -- EDIチェーン店コード
-- 2010/01/19 Ver1.15 M.Sano Add End
      ,lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode   -- リターン・コード             --# 固定 #
      ,lv_errmsg    -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数設定
      gn_error_cnt := 1;
--
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
    -- 警告終了時
    ELSIF (lv_retcode = cv_status_warn) THEN
--
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
    END IF;
--
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告(商品エラー)件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
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
END XXCOS010A01C;
/
