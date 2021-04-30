CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A01C(body)
 * Description      : 控除マスタCSVアップロード
 * MD.050           : 控除マスタCSVアップロード MD050_COK_024_A01
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                                       (A-1)
 *  get_if_data                  IFデータ取得                                   (A-2)
 *  delete_if_data               IFデータ削除                                   (A-3)
 *  divide_item                  アップロードファイル項目分割                   (A-4)
 *  exclusive_check              控除マスタ排他制御処理                         (A-5)
 *  ins_exclusive_ctl_info       排他制御管理テーブル登録                       (A-5-1)
 *  validity_check               妥当性チェック                                 (A-6)
 *  delete_process               控除マスタ削除                                 (A-7)
 *  up_ins_chk                   削除後チェック                                 (A-8)
 *  ins_up_process               控除マスタ登録･変更処理                        (A-9)
 *  condition_recovery           控除データリカバリコンカレント発行処理         (A-10)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/03/11    1.0   Y.Sasaki         新規作成
 *  2020/09/25    1.0   H.Ishii          追加課題対応
 *  2021/04/06    1.1   H.Futamura       E_本稼動_16026
 *  2021/04/28    1.2   A.AOKI           E_本稼動_16026 問屋マージン修正（円）は0円を許す
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
  gn_chk_cnt       NUMBER;
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
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
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
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCOK024A01C'; -- パッケージ名
--
  ct_language                       CONSTANT fnd_lookup_values.language%TYPE  := USERENV('LANG'); -- 言語
--
  cv_csv_delimiter                  CONSTANT VARCHAR2(1)  := ',';   -- カンマ
  cv_colon                          CONSTANT VARCHAR2(2)  := '：';  -- コロン
  cv_space                          CONSTANT VARCHAR2(2)  := ' ';   -- 半角スペース
  cv_const_y                        CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                        CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
--
  -- 数値
  cn_zero                           CONSTANT NUMBER := 0;   -- 0
  cn_one                            CONSTANT NUMBER := 1;   -- 1
  cn_100                            CONSTANT NUMBER := 100; -- 100
  cn_minus_one                      CONSTANT NUMBER := -1;  -- -1
--
  cn_process_type                   CONSTANT NUMBER := 1;   -- 処理区分
  cn_condition_no                   CONSTANT NUMBER := 2;   -- 控除番号
  cn_corp_code                      CONSTANT NUMBER := 3;   -- 企業コード
  cn_deduction_chain_code           CONSTANT NUMBER := 4;   -- 控除用チェーンコード
  cn_customer_code                  CONSTANT NUMBER := 5;   -- 顧客コード
  cn_data_type                      CONSTANT NUMBER := 6;   -- データ種類
  cn_tax_code                       CONSTANT NUMBER := 7;   -- 税コード
  cn_start_date_active              CONSTANT NUMBER := 8;   -- 開始日
  cn_end_date_active                CONSTANT NUMBER := 9;   -- 終了日
  cn_content                        CONSTANT NUMBER := 10;  -- 内容
  cn_decision_no                    CONSTANT NUMBER := 11;  -- 決裁No
  cn_agreement_no                   CONSTANT NUMBER := 12;  -- 契約番号
  cn_detail_number                  CONSTANT NUMBER := 13;  -- 明細番号
  cn_target_category                CONSTANT NUMBER := 14;  -- 対象区分
  cn_product_class                  CONSTANT NUMBER := 15;  -- 商品区分
  cn_item_code                      CONSTANT NUMBER := 16;  -- 品目コード
  cn_uom_code                       CONSTANT NUMBER := 17;  -- 単位
  cn_shop_pay_1                     CONSTANT NUMBER := 18;  -- 店納(％)_1
  cn_material_rate_1                CONSTANT NUMBER := 19;  -- 料率(％)_1
  cn_demand_en_3                    CONSTANT NUMBER := 20;  -- 請求(円)_3
  cn_shop_pay_en_3                  CONSTANT NUMBER := 21;  -- 店納(円)_3
  cn_wholesale_margin_en_3          CONSTANT NUMBER := 22;  -- 問屋マージン(円)_3
  cn_wholesale_margin_per_3         CONSTANT NUMBER := 23;  -- 問屋マージン(％)_3
  cn_normal_shop_pay_en_4           CONSTANT NUMBER := 24;  -- 通常店納(円)_4
  cn_just_shop_pay_en_4             CONSTANT NUMBER := 25;  -- 今回店納(円)_4
  cn_wholesale_adj_margin_en_4      CONSTANT NUMBER := 26;  -- 問屋マージン修正(円)_4
  cn_wholesale_adj_margin_per_4     CONSTANT NUMBER := 27;  -- 問屋マージン修正(％)_4
  cn_prediction_qty_5_6             CONSTANT NUMBER := 28;  -- 予測数量(本)_5_6
  cn_support_amount_sum_en_5        CONSTANT NUMBER := 29;  -- 協賛金合計(円)_5
  cn_condition_unit_price_en_2_6    CONSTANT NUMBER := 30;  -- 条件単価(円)_6
  cn_target_rate_6                  CONSTANT NUMBER := 31;  -- 対象率(％)_6
-- 2021/04/06 Ver1.1 MOD Start
--  cn_accounting_base                CONSTANT NUMBER := 32;  -- 計上拠点
  cn_accounting_customer_code       CONSTANT NUMBER := 32;  -- 計上顧客
-- 2021/04/06 Ver1.1 MOD End
  cn_deduction_amount               CONSTANT NUMBER := 33;  -- 控除額(本体)
  cn_deduction_tax_amount           CONSTANT NUMBER := 34;  -- 控除税額
  cn_c_header                       CONSTANT NUMBER := 35;  -- CSVファイル項目数（取得対象）
  cn_c_header_all                   CONSTANT NUMBER := 36;  -- CSVファイル項目数（全項目）
--
  cv_process_delete                 CONSTANT VARCHAR2(1)  :=  'D';    -- 処理区分(削除)
  cv_process_update                 CONSTANT VARCHAR2(1)  :=  'U';    -- 処理区分(更新)
  cv_process_insert                 CONSTANT VARCHAR2(1)  :=  'I';    -- 処理区分(登録)
  cv_process_decision               CONSTANT VARCHAR2(1)  :=  'Z';      -- 処理区分(決裁)
  cv_csv_delete                     CONSTANT VARCHAR2(4)  :=  '削除';   -- CSV処理区分(削除)
  cv_csv_update                     CONSTANT VARCHAR2(4)  :=  '修正';   -- CSV処理区分(修正)
  cv_csv_insert                     CONSTANT VARCHAR2(4)  :=  '登録';   -- CSV処理区分(登録)
  cv_csv_decision                   CONSTANT VARCHAR2(4)  :=  '決裁';   -- CSV処理区分(決裁)
--
  cv_condition_type_req             CONSTANT VARCHAR2(3)  :=  '010';  -- 控除タイプ(請求額×料率(％))
  cv_condition_type_sale            CONSTANT VARCHAR2(3)  :=  '020';  -- 控除タイプ(販売数量×金額)
  cv_condition_type_ws_fix          CONSTANT VARCHAR2(3)  :=  '030';  -- 控除タイプ(問屋未収（定額）)
  cv_condition_type_ws_add          CONSTANT VARCHAR2(3)  :=  '040';  -- 控除タイプ(問屋未収（追加）)
  cv_condition_type_spons           CONSTANT VARCHAR2(3)  :=  '050';  -- 控除タイプ(定額協賛金)
  cv_condition_type_pre_spons       CONSTANT VARCHAR2(3)  :=  '060';  -- 控除タイプ(対象数量予測協賛金)
  cv_condition_type_fix_con         CONSTANT VARCHAR2(3)  :=  '070';  -- 控除タイプ(定額控除)
  cv_cust_cls_10                    CONSTANT VARCHAR2(2)  :=  '10';   -- 顧客区分(10)
  cv_cust_accounts_status           CONSTANT VARCHAR2(1)  :=  'A';    -- 顧客ステータス
  cv_parties_status                 CONSTANT VARCHAR2(1)  :=  'A';    -- パーティステータス
  cv_cust_class_base                CONSTANT VARCHAR2(2)  :=  '1';    -- 拠点（顧客区分）
  cv_cust_class_cust                CONSTANT VARCHAR2(2)  :=  '10';   -- 顧客（顧客区分）
--
  cv_uom_hon                        CONSTANT VARCHAR2(3)  :=  '本';   -- 単位（本）
  cv_uom_cs                         CONSTANT VARCHAR2(2)  :=  'CS';   -- 単位（CS）
  cv_uom_bl                         CONSTANT VARCHAR2(2)  :=  'BL';   -- 単位（BL）
--
  cv_shop_pay                       CONSTANT VARCHAR2(6)  :=  '店納'; -- 店納
--
  cv_month_jan                      CONSTANT VARCHAR2(2)  :=  '01';   -- 1月
  cv_month_feb                      CONSTANT VARCHAR2(2)  :=  '02';   -- 2月
  cv_month_mar                      CONSTANT VARCHAR2(2)  :=  '03';   -- 3月
  cv_month_apr                      CONSTANT VARCHAR2(2)  :=  '04';   -- 4月
--
  cv_data_rec_conc                  CONSTANT VARCHAR2(50) := 'XXCOK024A09C';  -- 控除データリカバリコンカレント
--
  -- 出力タイプ
  cv_file_type_out                  CONSTANT VARCHAR2(10) := 'OUTPUT';        -- 出力(ユーザメッセージ用出力先)
  cv_file_type_log                  CONSTANT VARCHAR2(10) := 'LOG';           -- ログ(システム管理者用出力先)
--
  -- 書式マスク
  cv_date_format                    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';    -- 日付書式
  cv_date_year                      CONSTANT VARCHAR2(4)  := 'YYYY';          -- 年
  cv_date_month                     CONSTANT VARCHAR2(2)  := 'MM';            -- 月
--
  -- アプリケーション短縮名
  cv_msg_kbn_cok                    CONSTANT VARCHAR2(5)  := 'XXCOK'; -- アドオン：個別開発
  cv_msg_kbn_cos                    CONSTANT VARCHAR2(5)  := 'XXCOS'; -- アドオン：販売
  cv_msg_kbn_coi                    CONSTANT VARCHAR2(5)  := 'XXCOI'; -- アドオン：在庫
  cv_msg_kbn_csm                    CONSTANT VARCHAR2(5)  := 'XXCSM'; -- アドオン：経営
  cv_msg_kbn_ccp                    CONSTANT VARCHAR2(5)  := 'XXCCP'; -- 共通のメッセージ
--
  -- プロファイル
  cv_set_of_bks_id                  CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- 会計帳簿ID
  cv_item_div_h                     CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';         -- 本社商品区分
  cv_prf_org                        CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:在庫組織コード
  cv_prf_org_id                     CONSTANT VARCHAR2(30) := 'ORG_ID';                    -- 組織ID
--
  -- 参照タイプ
  cv_type_upload_obj                CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';      -- ファイルアップロードオブジェクト
  cv_type_deduction_data            CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- 控除データ種類
  cv_type_chain_code                CONSTANT VARCHAR2(30) := 'XXCMM_CHAIN_CODE';            -- チェーンコード
  cv_type_business_type             CONSTANT VARCHAR2(30) := 'XX03_BUSINESS_TYPE';          -- 企業タイプ
  cv_type_deduction_1_kbn           CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_1_KBN';      -- 請求額×料率（％）区分
  cv_type_dec_pri_base              CONSTANT VARCHAR2(30) := 'XXCOK1_DEC_PRIVILEGE_BASE';   -- 控除マスタ特権拠点
  cv_type_dec_del_dept              CONSTANT VARCHAR2(30) := 'XXCOK1_DEC_DEL_PRI_DEPT';     -- 控除マスタ削除特権部署
  cv_type_deduction_type            CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_TYPE';       -- 控除タイプ
  cv_type_deduction_kbn             CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_KBN';        -- 控除区分
  cv_type_column_digit_chk          CONSTANT VARCHAR2(30) := 'XXCOK1_XXCOK024A01C_DIGIT_CHK'; -- csvアップロード項目桁数チェック
--
  -- 言語コード
  ct_lang                           CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- メッセージ名
  cv_msg_ccp_90000                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_msg_ccp_90001                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_msg_ccp_90002                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_msg_ccp_90003                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
  cv_msg_ccp_00001                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00001';  -- 警告件数メッセージ
--
  cv_msg_cok_00016                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00016';  -- ファイルID出力用メッセージ
  cv_msg_cok_00017                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00017';  -- ファイルパターン出力用メッセージ
  cv_msg_cok_00028                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- 業務日付取得エラー
  cv_msg_cos_00001                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_cos_11294                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11294';  -- CSVファイル名取得エラー
  cv_msg_cok_00006                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00006';  -- ファイル名出力用メッセージ
  cv_msg_cok_00106                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00106';  -- ファイルアップロード名称出力用メッセージ
  cv_msg_cok_00039                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00039';  -- CSVファイルデータなしエラーメッセージ
  cv_msg_cok_00003                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';  -- プロファイル取得エラーメッセージ
  cv_msg_cok_00005                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00005';  -- 従業員取得エラーメッセージ
  cv_msg_cos_00013                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';  -- データ抽出エラーメッセージ
  cv_msg_coi_10633                  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10633';  -- データ削除エラーメッセージ
  cv_msg_cos_11295                  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11295';  -- ファイルレコード項目数不一致エラーメッセージ
  cv_msg_cok_10622                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10622';  -- ワークテーブル登録エラー
  cv_msg_cok_10586                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10586';  -- データ登録エラー
  cv_msg_cok_10587                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10587';  -- データ更新エラー
--
  cv_msg_cok_10596                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10596';  -- 控除マスタCSV特定情報
  cv_msg_cok_10597                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10597';  -- 固定値不正エラー
  cv_msg_cok_10598                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10598';  -- 設定不可エラー
  cv_msg_cok_10599                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10599';  -- 組み合わせエラー
  cv_msg_cok_10600                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10600';  -- マスタ未登録エラー
  cv_msg_cok_10602                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10602';  -- 日付不正エラー
  cv_msg_cok_10604                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10604';  -- 有効期間内操作不可エラー
  cv_msg_cok_10605                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10605';  -- 必須項目未設定エラー(条件)
  cv_msg_cok_10606                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10606';  -- 必須項目未設定エラー
  cv_msg_cok_10607                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10607';  -- 必須項目未設定エラー(選択)
  cv_msg_cok_10608                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10608';  -- 重複エラー
  cv_msg_cok_10609                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10609';  -- 設定値不一致エラー
  cv_msg_cok_10612                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10612';  -- セキュリティエラー
  cv_msg_cok_10613                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10613';  -- 所属拠点セキュリティエラー
  cv_msg_cok_10614                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10614';  -- 排他制御エラー
  cv_msg_cok_10615                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10615';  -- コンカレント呼び出しエラー
  cv_msg_cok_10670                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10670';  -- 控除番号生成エラー
  cv_msg_cok_10671                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10671';  -- 単位不正エラー
  cv_msg_cok_00015                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00015';  -- クイックコード取得エラー
  cv_msg_cok_10623                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10623';  -- シーケンス取得エラー
  cv_msg_cok_00012                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00012';  -- 所属拠点コード取得エラーメッセージ
  cv_msg_cok_00030                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00030';  -- 所属部門コード取得エラーメッセージ
  cv_msg_cok_10676                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10676';  -- 控除番号シーケンスエラー
  cv_msg_cok_10677                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10677';  -- データリカバリコンカレント発行メッセージ
  cv_msg_cok_10678                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10678';  -- 処理区分組み合わせエラー
  cv_msg_cok_10682                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10682';  -- 参照表未設定エラー
  cv_msg_cok_10709                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10709';  -- 項目不備エラーメッセージ
  cv_msg_cok_10703                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10703';  -- 開始日修正可否エラー
  cv_msg_cok_10704                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10704';  -- 終了日修正可否エラー
  cv_msg_cok_10705                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10705';  -- 終了日修正範囲エラー
  cv_msg_cok_10710                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10710';  -- 定額控除マスタ登録エラー
-- 2021/04/06 Ver1.1 ADD Start
  cv_msg_cok_10794                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10794';  -- 子品目エラー
  cv_msg_cok_10795                  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10795';  -- 登録情報
-- 2021/04/06 Ver1.1 ADD End
--
  cv_tkn_coi_10634                  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10634';  -- ファイルアップロードIF
  cv_prf_org_err_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';  -- 在庫組織コード取得エラーメッセージ
  cv_org_id_err_msg                 CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';  -- 在庫組織ID取得エラーメッセージ
--
  -- トークン名
  cv_file_id_tok                    CONSTANT VARCHAR2(20) := 'FILE_ID';           -- ファイルID
  cv_format_tok                     CONSTANT VARCHAR2(20) := 'FORMAT';            -- フォーマット
  cv_table_tok                      CONSTANT VARCHAR2(20) := 'TABLE';             -- テーブル名
  cv_key_data_tok                   CONSTANT VARCHAR2(20) := 'KEY_DATA';          -- 特定できるキー内容をコメントをつけてセットします。
  cv_file_name_tok                  CONSTANT VARCHAR2(20) := 'FILE_NAME';         -- ファイル名
  cv_upload_object_tok              CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';     -- アップロードファイル名
  cv_profile_tok                    CONSTANT VARCHAR2(20) := 'PROFILE';           -- プロファイル名
  cv_empcd_tok                      CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';        -- 従業員コード
  cv_gcd_tok                        CONSTANT VARCHAR2(20) := 'GET_CUSTOM_DATE';   -- 顧客獲得日
  cv_table_name_tok                 CONSTANT VARCHAR2(20) := 'TABLE_NAME';        -- テーブル名
  cv_data_tok                       CONSTANT VARCHAR2(20) := 'DATA';              -- データ
  cv_col_name_tok                   CONSTANT VARCHAR2(20) := 'COLUMN_NAME';       -- 項目名
  cv_col_value_tok                  CONSTANT VARCHAR2(20) := 'COLUMN_VALUE';      -- 項目値
  cv_start_date_tok                 CONSTANT VARCHAR2(20) := 'START_DATE';        -- 開始日
  cv_end_date_tok                   CONSTANT VARCHAR2(20) := 'END_DATE';          -- 終了日
  cv_if_value_tok                   CONSTANT VARCHAR2(20) := 'IF_VALUE';          -- 条件
  cv_line_num_tok                   CONSTANT VARCHAR2(20) := 'LINE_NUM';          -- CSVの行番号
  cv_col_name_2_tok                 CONSTANT VARCHAR2(20) := 'COLUMN_NAME2';      -- 項目名
  cv_pg_name_tok                    CONSTANT VARCHAR2(20) := 'PG_NAME';           -- コンカレント名
  cv_lookup_value_set               CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';  -- 参照表名
  cv_tkn_err_msg                    CONSTANT VARCHAR2(20) := 'ERR_MSG';           -- エラーメッセージ
  cv_tkn_user_id                    CONSTANT VARCHAR2(7)  := 'USER_ID';           -- ユーザーID
  cv_tkn_process_type               CONSTANT VARCHAR2(12) := 'PROCESS_TYPE';      -- 処理区分
  cv_tkn_request_id                 CONSTANT VARCHAR2(10) := 'REQUEST_ID';        -- 要求ＩＤ
  cv_tkn_condition_type             CONSTANT VARCHAR2(14) := 'CONDITION_TYPE';    -- 控除タイプ
  cv_tkn_pro                        CONSTANT VARCHAR2(20) := 'PRO_TOK';           -- プロファイルトークン
  cv_tkn_org                        CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';      -- ORG_CODEトークン
  cv_tkn_code                       CONSTANT VARCHAR2(20) := 'CODE';              -- コード値
  cv_tkn_item                       CONSTANT VARCHAR2(20) := 'ITEM';              -- 項目
  cv_tkn_record_no                  CONSTANT VARCHAR2(20) := 'RECORD_NO';         -- レコードNo
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20) := 'ERRMSG';            -- エラー内容詳細

--
  --メッセージ文言
  cv_msg_condition_h                CONSTANT VARCHAR2(16) := '控除条件テーブル';
  cv_msg_condition_l                CONSTANT VARCHAR2(16) := '控除詳細テーブル';
  cv_msg_delete                     CONSTANT VARCHAR2(4)  := '削除';
  cv_msg_insert                     CONSTANT VARCHAR2(4)  := '登録';
  cv_msg_update                     CONSTANT VARCHAR2(4)  := '更新';
  cv_msg_decision                   CONSTANT VARCHAR2(4)  := '決裁';
  cv_msg_pro_type                   CONSTANT VARCHAR2(8)  := '処理区分';
  cv_msg_dtl_pro_type               CONSTANT VARCHAR2(12) := '明細処理区分';
  cv_msg_condition_no               CONSTANT VARCHAR2(8)  := '控除番号';
  cv_msg_detail_num                 CONSTANT VARCHAR2(8)  := '明細番号';
  cv_msg_kigyo_code                 CONSTANT VARCHAR2(10) := '企業コード';
  cv_msg_chain_code                 CONSTANT VARCHAR2(20) := '控除用チェーンコード';
  cv_msg_cust_code                  CONSTANT VARCHAR2(10) := '顧客コード';
  cv_msg_data_type                  CONSTANT VARCHAR2(10) := 'データ種類';
  cv_msg_condition_type             CONSTANT VARCHAR2(10) := '控除タイプ';
  cv_msg_condition_cls              CONSTANT VARCHAR2(10) := '控除区分';
  cv_msg_agreement_no               CONSTANT VARCHAR2(8)  := '契約番号';
  cv_msg_item_kbn                   CONSTANT VARCHAR2(8)  := '商品区分';
  cv_msg_target_cate                CONSTANT VARCHAR2(8)  := '対象区分';
  cv_msg_start_date                 CONSTANT VARCHAR2(6)  := '開始日';
  cv_msg_end_date                   CONSTANT VARCHAR2(6)  := '終了日';
  cv_msg_item_code                  CONSTANT VARCHAR2(10) := '品目コード';
  cv_msg_item_mst                   CONSTANT VARCHAR2(10) := '品目マスタ';
  cv_msg_case_in_qty                CONSTANT VARCHAR2(4)  := '入数';
  cv_msg_sup_amt_sum                CONSTANT VARCHAR2(16) := '協賛金合計（円）';
  cv_delimiter                      CONSTANT VARCHAR2(2)  := '、';
  cv_msg_shop_pay                   CONSTANT VARCHAR2(50) := '店納';
  cv_msg_meter_rate                 CONSTANT VARCHAR2(50) := '料率';
  cv_msg_con_u_p_en                 CONSTANT VARCHAR2(50) := '条件単価';
  cv_msg_uom_code                   CONSTANT VARCHAR2(50) := '単位';
  cv_msg_demand_en                  CONSTANT VARCHAR2(50) := '請求';
  cv_msg_who_margin                 CONSTANT VARCHAR2(50) := '問屋マージン';
  cv_msg_normal_sp                  CONSTANT VARCHAR2(50) := '通常店納';
  cv_msg_just_sp                    CONSTANT VARCHAR2(50) := '今回店納';
  cv_msg_prediction                 CONSTANT VARCHAR2(50) := '予測数量';
  cv_msg_tar_rate                   CONSTANT VARCHAR2(50) := '対象率';
-- 2021/04/06 Ver1.1 MOD Start
--  cv_msg_accounting_base            CONSTANT VARCHAR2(50) := '計上拠点';
  cv_msg_account_customer_code      CONSTANT VARCHAR2(50) := '計上顧客';
  cv_msg_content                    CONSTANT VARCHAR2(50) := '内容';
-- 2021/04/06 Ver1.1 MOD End
  cv_msg_con_amout                  CONSTANT VARCHAR2(50) := '控除額（本体）';
  cv_msg_tax_code                   CONSTANT VARCHAR2(50) := '税コード';
  cv_msg_con_tax                    CONSTANT VARCHAR2(50) := '控除税額';
  cv_msg_header                     CONSTANT VARCHAR2(50) := 'ヘッダー';
  cv_msg_line                       CONSTANT VARCHAR2(50) := '明細';
  cv_msg_csv_line                   CONSTANT VARCHAR2(50) := '行目';
-- 2021/04/06 Ver1.1 ADD Start
  cv_msg_child_item_code            CONSTANT VARCHAR2(50) := '子品目';
-- 2021/04/06 Ver1.1 ADD End
--
  cv_msg_parsent                    CONSTANT VARCHAR2(9)  := '（％）';
  cv_msg_yen                        CONSTANT VARCHAR2(9)  := '（円）';
  cv_msg_hon                        CONSTANT VARCHAR2(9)  := '（本）';
  cv_msg_ja_to                      CONSTANT VARCHAR2(3)  := 'と';
  cv_msg_ja_ga                      CONSTANT VARCHAR2(3)  := 'が';
  cv_msg_adj                        CONSTANT VARCHAR2(6)  := '修正';
  cv_msg_tonya                      CONSTANT VARCHAR2(50) := '問屋未収';
  cv_msg_condition_mst              CONSTANT VARCHAR2(20) := '控除マスタデータ';
  cv_msg_lookup_d_kbn               CONSTANT VARCHAR2(20) := '参照表：控除区分';
  cv_msg_lookup_d_type              CONSTANT VARCHAR2(20) := '参照表：控除タイプ';
--
  -- ダミー値
  cv_dummy_char                     CONSTANT VARCHAR2(100)  := 'DUMMY99999999'; -- 文字列用ダミー値
  cd_dummy_date                     CONSTANT DATE           := TO_DATE( '1900/01/01', 'YYYY/MM/DD' );
                                                                                -- 日付用ダミー値(最小)
  cd_max_date                       CONSTANT DATE           := TO_DATE( '9999/12/31', 'YYYY/MM/DD' );
                                                                                -- 日付用ダミー値(最大)
  cv_dummy_base                     CONSTANT VARCHAR2(1)    := 'Z';             -- 拠点コードのダミー値
  cv_dummy_code                     CONSTANT VARCHAR2(2)    := '-1';            -- ダミーコード
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納用
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1次元配列
  g_if_data_tab             g_var_data_ttype;                                     -- 分割用変数
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;                    -- CSVデータ（1行）
  --  エラーメッセージ保持用  インデックスはCSV行番号 チェック番号
  TYPE g_csv_column IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
  TYPE g_check_no   IS TABLE OF g_csv_column    INDEX BY BINARY_INTEGER;
  g_message_list_tab    g_check_no;
--
  -- 項目チェック格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1              fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2              fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3              fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4              fnd_lookup_values.attribute4%TYPE -- 属性
  );
--
  -- テーブルタイプ
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_check_result       VARCHAR2(2);       -- チェック結果
  gv_item_div_h         VARCHAR(20);       -- 本社商品区分
  gv_emp_code           VARCHAR(30);       -- ログインユーザの従業員番号
  gv_user_base          VARCHAR(150);      -- 拠点コード
  gn_skip_cnt           NUMBER;            -- スキップ件数
  gn_privilege_delete   NUMBER;            -- 削除権限（0：権限なし、1：権限あり）
  gn_privilege_up_ins   NUMBER;            -- 登録・更新特権（0：特権なし、1：特権あり）
  gd_process_date       DATE;              -- 業務日付
  gn_set_of_bks_id      NUMBER;            -- 会計帳簿ID
  gn_message_cnt        NUMBER;            -- 最大メッセージ数
  gt_org_code           mtl_parameters.organization_code%TYPE;
                                           -- 在庫組織コード
  gt_org_id             mtl_parameters.organization_id%TYPE;
                                           -- 在庫組織ID
  gt_login_user_id      fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID;
                                           -- ログインユーザのID
  gn_org_id2            NUMBER;            -- 組織ID
  g_chk_item_tab        g_chk_item_ttype;  -- 項目チェック
--
  -- ===============================
  -- ユーザ定義グローバルカーソル
  -- ===============================
  -- 重複チェック用カーソル
  CURSOR g_cond_tmp_cur
    IS
      SELECT  xct.csv_no                          AS csv_no                       --  CSV行数
            , xct.request_id                      AS request_id                   --  要求ID
            , xct.csv_process_type                AS csv_process_type             --  CSV処理区分
            , xct.process_type                    AS process_type                 --  処理区分
            , xct.condition_no                    AS condition_no                 --  控除番号
            , xct.corp_code                       AS corp_code                    --  企業コード
            , xct.deduction_chain_code            AS deduction_chain_code         --  控除用チェーンコード
            , xct.customer_code                   AS customer_code                --  顧客コード
            , xct.data_type                       AS data_type                    --  データ種類
            , xct.start_date_active               AS start_date_active            --  開始日
            , xct.end_date_active                 AS end_date_active              --  終了日
            , xct.content                         AS content                      --  内容
            , xct.decision_no                     AS decision_no                  --  決裁No
            , xct.agreement_no                    AS agreement_no                 --  契約番号
            , xct.process_type_line               AS process_type_line            --  明細処理区分
            , xct.detail_number                   AS detail_number                --  明細番号
            , xct.target_category                 AS target_category              --  対象区分
            , xct.product_class                   AS product_class                --  商品区分
            , xct.product_class_code              AS product_class_code           --  商品区分コード
            , xct.item_code                       AS item_code                    --  品目コード
            , xct.uom_code                        AS uom_code                     --  単位
            , xct.shop_pay_1                      AS shop_pay_1                   --  店納(％)_1
            , xct.material_rate_1                 AS material_rate_1              --  料率(％)_1
            , xct.demand_en_3                     AS demand_en_3                  --  請求(円)_3
            , xct.shop_pay_en_3                   AS shop_pay_en_3                --  店納(円)_3
            , xct.wholesale_margin_en_3           AS wholesale_margin_en_3        --  問屋マージン(円)_3
            , xct.wholesale_margin_per_3          AS wholesale_margin_per_3       --  問屋マージン(％)_3
            , xct.normal_shop_pay_en_4            AS normal_shop_pay_en_4         --  通常店納(円)_4
            , xct.just_shop_pay_en_4              AS just_shop_pay_en_4           --  今回店納(円)_4
            , xct.wholesale_adj_margin_en_4       AS wholesale_adj_margin_en_4    --  問屋マージン修正(円)_4
            , xct.wholesale_adj_margin_per_4      AS wholesale_adj_margin_per_4   --  問屋マージン修正(％)_4
            , xct.prediction_qty_5_6              AS prediction_qty_5_6           --  予測数量(本)_5_6
            , xct.support_amount_sum_en_5         AS support_amount_sum_en_5      --  協賛金合計(円)_5
            , xct.condition_unit_price_en_2_6     AS condition_unit_price_en_2_6  --  条件単価(円)_6
            , xct.target_rate_6                   AS target_rate_6                --  対象率(％)_6
-- 2021/04/06 Ver1.1 MOD Start
--            , xct.accounting_base                 AS accounting_base              --  計上拠点
            , xct.accounting_customer_code        AS accounting_customer_code     --  計上顧客
-- 2021/04/06 Ver1.1 MOD End
            , xct.deduction_amount                AS deduction_amount             --  控除額(本体)
            , xct.tax_code                        AS tax_code                     --  税コード
            , xct.deduction_tax_amount            AS deduction_tax_amount         --  控除税額
            , xct.condition_cls                   AS condition_cls                --  控除区分
            , xct.condition_type                  AS condition_type               --  控除タイプ
            , rowid                               AS row_id
      FROM    xxcok_condition_temp  xct
      WHERE   xct.request_id  = cn_request_id
      ORDER BY  xct.process_type_line
              , xct.process_type
      ;
    g_cond_tmp_rec    g_cond_tmp_cur%ROWTYPE;
--
  -- メインカーソル
  CURSOR g_cond_tmp_chk_cur
    IS
      SELECT  xct.csv_no                          AS csv_no                       --  CSV行数
            , xct.request_id                      AS request_id                   --  要求ID
            , xct.csv_process_type                AS csv_process_type             --  CSV処理区分
            , xct.process_type                    AS process_type                 --  処理区分
            , xct.condition_no                    AS condition_no                 --  控除番号
            , xct.corp_code                       AS corp_code                    --  企業コード
            , xct.deduction_chain_code            AS deduction_chain_code         --  控除用チェーンコード
            , xct.customer_code                   AS customer_code                --  顧客コード
            , xct.data_type                       AS data_type                    --  データ種類
            , xct.start_date_active               AS start_date_active            --  開始日
            , xct.end_date_active                 AS end_date_active              --  終了日
            , xct.content                         AS content                      --  内容
            , xct.decision_no                     AS decision_no                  --  決裁No
            , xct.agreement_no                    AS agreement_no                 --  契約番号
            , xct.process_type_line               AS process_type_line            --  明細処理区分
            , xct.detail_number                   AS detail_number                --  明細番号
            , xct.target_category                 AS target_category              --  対象区分
            , xct.product_class                   AS product_class                --  商品区分
            , xct.product_class_code              AS product_class_code           --  商品区分コード
            , xct.item_code                       AS item_code                    --  品目コード
            , xct.uom_code                        AS uom_code                     --  単位
            , xct.shop_pay_1                      AS shop_pay_1                   --  店納(％)_1
            , xct.material_rate_1                 AS material_rate_1              --  料率(％)_1
            , xct.demand_en_3                     AS demand_en_3                  --  請求(円)_3
            , xct.shop_pay_en_3                   AS shop_pay_en_3                --  店納(円)_3
            , xct.wholesale_margin_en_3           AS wholesale_margin_en_3        --  問屋マージン(円)_3
            , xct.wholesale_margin_per_3          AS wholesale_margin_per_3       --  問屋マージン(％)_3
            , xct.normal_shop_pay_en_4            AS normal_shop_pay_en_4         --  通常店納(円)_4
            , xct.just_shop_pay_en_4              AS just_shop_pay_en_4           --  今回店納(円)_4
            , xct.wholesale_adj_margin_en_4       AS wholesale_adj_margin_en_4    --  問屋マージン修正(円)_4
            , xct.wholesale_adj_margin_per_4      AS wholesale_adj_margin_per_4   --  問屋マージン修正(％)_4
            , xct.prediction_qty_5_6              AS prediction_qty_5_6           --  予測数量(本)_5_6
            , xct.support_amount_sum_en_5         AS support_amount_sum_en_5      --  協賛金合計(円)_5
            , xct.condition_unit_price_en_2_6     AS condition_unit_price_en_2_6  --  条件単価(円)_6
            , xct.target_rate_6                   AS target_rate_6                --  対象率(％)_6
-- 2021/04/06 Ver1.1 MOD Start
--            , xct.accounting_base                 AS accounting_base              --  計上拠点
            , xct.accounting_customer_code        AS accounting_customer_code     --  計上顧客
-- 2021/04/06 Ver1.1 MOD End
            , xct.deduction_amount                AS deduction_amount             --  控除額(本体)
            , xct.tax_code                        AS tax_code                     --  税コード
            , xct.tax_rate                        AS tax_rate                     --  税率
            , xct.deduction_tax_amount            AS deduction_tax_amount         --  控除税額
            , xct.condition_cls                   AS condition_cls                --  控除区分
            , xct.condition_type                  AS condition_type               --  控除タイプ
            , xct.condition_id                    AS condition_id                 --  控除条件ID
            , DECODE( xct.corp_code, NULL, 0, 1 )
              + DECODE( xct.deduction_chain_code, NULL, 0, 1 )
              + DECODE( xct.customer_code, NULL, 0, 1 )
                                                  AS data_count
            , rowid                               AS row_id
      FROM    xxcok_condition_temp  xct
      WHERE   xct.request_id  = cn_request_id
      ORDER BY  xct.condition_no
               ,DECODE(xct.process_type,'N',2,1)
      ;
    g_cond_tmp_chk_rec    g_cond_tmp_chk_cur%ROWTYPE;
--
    -- *** ローカル・カーソル ***
    -- 排他制御管理テーブル登録用カーソル
    CURSOR g_exclusive_ctl_cur
    IS
      SELECT DISTINCT
              xct.condition_no      AS  condition_no
            , xct.request_id        AS  request_id
      FROM    xxcok_condition_temp xct
      WHERE   xct.request_id     = cn_request_id
      AND     xct.condition_no  IS NOT NULL
      ;
    g_exclusive_ctl_rec   g_exclusive_ctl_cur%ROWTYPE;
--

--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER     --   ファイルID
   ,iv_file_format IN  VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf      OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
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
    lb_retcode              BOOLEAN;        -- 判定結果
    lt_file_name            xxccp_mrp_file_ul_interface.file_name%TYPE;
    lt_file_upload_name     fnd_lookup_values.meaning%TYPE;
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
    -- ローカル変数初期化
    lb_retcode          :=  FALSE;
    lt_file_name        :=  NULL;               -- ファイル名
    lt_file_upload_name :=  NULL;               -- ファイルアップロード名称
--
    -- グローバル変数初期化
    gv_check_result :=  cv_const_y;             -- チェック結果
--
    -- フォーマットパターンメッセージ出力(ログ)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00016  -- ファイルID出力メッセージ
                   ,iv_token_name1  =>  cv_file_id_tok
                   ,iv_token_value1 =>  in_file_id        -- ファイルID
                  )
    );
    -- フォーマットパターンメッセージ出力(出力)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00016  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_file_id_tok
                   ,iv_token_value1 =>  in_file_id        -- ファイル名
                  )
    );
    -- フォーマットパターンメッセージ出力(ログ)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00017  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_format_tok
                   ,iv_token_value1 =>  iv_file_format    -- ファイル名
                  )
    );
    -- フォーマットパターンメッセージ出力(出力)
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00017  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_format_tok
                   ,iv_token_value1 =>  iv_file_format    -- ファイル名
                  )
    );
--
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
    --==============================================================
    -- 業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00028 -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ファイルアップロードIFデータロック
    --==============================================================
    BEGIN
      SELECT  xfu.file_name     AS  file_name     -- ファイル名
      INTO    lt_file_name                        -- ファイル名
      FROM    xxccp_mrp_file_ul_interface  xfu    -- ファイルアップロードIF
      WHERE   xfu.file_id = in_file_id            -- ファイルID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロックが取得できない場合
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_cos_00001  -- ロックエラーメッセージ
                       ,iv_token_name1  =>  cv_table_tok
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- ファイルアップロードIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ファイルアップロード名称情報取得
    --==============================================================
    BEGIN
      SELECT  flv.meaning     AS  file_upload_name  -- ファイルアップロード名称
      INTO    lt_file_upload_name                   -- ファイルアップロード名称
      FROM    fnd_lookup_values flv                 -- クイックコード
      WHERE   flv.lookup_type  = cv_type_upload_obj
      AND     flv.lookup_code  = iv_file_format
      AND     flv.enabled_flag = cv_const_y
      AND     flv.language     = ct_lang
      AND     NVL(flv.start_date_active, gd_process_date) <= gd_process_date
      AND     NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
      ;
    EXCEPTION
      -- ファイルアップロード名称が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_11294  -- ファイルアップロード名称取得エラーメッセージ
                       ,iv_token_name1  =>  cv_key_data_tok
                       ,iv_token_value1 =>  iv_file_format    -- フォーマットパターン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 取得したファイル名、ファイルアップロード名称を出力
    --==============================================================
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00006  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_file_name_tok
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
--
    -- ファイルアップロード名称を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- ファイルアップロード名称
                  )
    );
    -- ファイルアップロード名称を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_cok
                   ,iv_name         =>  cv_msg_cok_00106      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_upload_object_tok
                   ,iv_token_value1 =>  lt_file_upload_name   -- ファイルアップロード名称
                  )
    );
--
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
    );
--
    --==============================================================
    -- 本社商品区分の取得
    --==============================================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    -- 取得できない場合
    IF ( gv_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00003
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_item_div_h   -- プロファイル：本社商品区分
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- プロファイルから会計帳簿ID取得
    --==============================================================
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得できない場合
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00003
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_set_of_bks_id   -- プロファイル：会計帳簿ID
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルより在庫組織コード取得
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- プロファイルが取得できない場合
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --共通関数より在庫組織ID取得
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --プロファイルから組織ID取得
    --==============================================================
    gn_org_id2 :=  TO_NUMBER(fnd_profile.value(cv_prf_org_id));
    IF (gn_org_id2 IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg( 
                      iv_application  => cv_msg_kbn_coi
                    , iv_name         => cv_prf_org_err_msg
                    , iv_token_name1  => cv_tkn_pro
                    , iv_token_value1 => cv_prf_org_id
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ログインユーザの所属拠点を取得
    --==============================================================
    gv_user_base      :=  xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_process_date,
      in_user_id              =>  gt_login_user_id
      );
    IF ( gv_user_base IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_00012
                   , iv_token_name1  => cv_tkn_user_id
                   , iv_token_value1 => gt_login_user_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    --==============================================================
    -- 削除権限のあるユーザーか確認
    --==============================================================
    BEGIN
      SELECT  COUNT(1)      AS  cnt
      INTO    gn_privilege_delete
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type   = cv_type_dec_pri_base
      AND     flv.lookup_code   = gv_user_base
      AND     flv.enabled_flag  = cv_const_y
      AND     flv.language      = ct_language
      AND     gd_process_date BETWEEN flv.start_date_active 
                              AND     NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
    --==============================================================
    -- 特権拠点の所属ユーザか確認
    --==============================================================
    BEGIN
      SELECT  COUNT(1)      AS  cnt
      INTO    gn_privilege_up_ins
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type   = cv_type_dec_pri_base
      AND     flv.lookup_code   = gv_user_base
      AND     flv.enabled_flag  = cv_const_y
      AND     flv.language      = ct_language
      AND     gd_process_date BETWEEN flv.start_date_active 
                              AND     NVL(flv.end_date_active,gd_process_date)
      ;
    END;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
    /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER     --   ファイルID
   ,iv_file_format IN  VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf      OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;        -- ファイル名
    lt_file_upload_name fnd_lookup_values.description%TYPE;                -- ファイルアップロード名称
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
    -- ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- ファイルID
     ,ov_file_data => gt_file_line_data_tab -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラーの場合
    IF lv_retcode <> cv_status_normal THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_cos_00013  -- データ抽出エラーメッセージ
                     ,iv_token_name1  =>  cv_table_name_tok
                     ,iv_token_value1 =>  cv_tkn_coi_10634  -- ファイルアップロードIF
                     ,iv_token_name2  =>  cv_key_data_tok
                     ,iv_token_value2 =>  NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数を設定
    gn_target_cnt := gt_file_line_data_tab.COUNT - 1;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IFデータ削除(A-3)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER     -- ファイルID
   ,ov_errbuf        OUT VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- プログラム名
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
    -- ファイルアップロードIFデータ削除
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- ファイルアップロードIF
      WHERE xfu.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        -- 削除に失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10633  -- データ削除エラーメッセージ
                       ,iv_token_name1  =>  cv_table_name_tok
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- ファイルアップロードIF
                       ,iv_token_name2  =>  cv_key_data_tok
                       ,iv_token_value2 =>  SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- データが見出しのみの場合エラー
    IF gn_target_cnt = cn_zero THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_msg_cok_00039  -- CSVファイルデータなしエラーメッセージ
                     ,iv_token_name1  =>  cv_file_id_tok
                     ,iv_token_value1 =>  in_file_id        -- ファイルID
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : アップロードファイル項目分割(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt   IN  NUMBER    --   IFループカウンタ
   ,ov_errbuf             OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    lv_rec_data         VARCHAR2(32765);  -- レコードデータ
    lv_cast_date_flag   VARCHAR2(1);
    lv_data_type        fnd_lookup_values.lookup_code%TYPE; -- データ種類
    lv_condition_cls    fnd_lookup_values.attribute1%TYPE;  -- 控除区分
    lv_condition_type   fnd_lookup_values.attribute2%TYPE;  -- 控除タイプ
    ln_dummy            NUMBER;
    ln_err_chk          NUMBER;
--
    -- *** ローカル・カーソル ***
    -- 項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- 項目名称
           , flv.attribute1    AS attribute1  -- 項目の長さ
           , flv.attribute2    AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3    AS attribute3  -- 必須フラグ
           , flv.attribute4    AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_type_column_digit_chk
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_const_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数初期化--
    lv_rec_data  := NULL; -- レコードデータ
--
    -- 項目数チェック
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) < ( cn_c_header_all - 1 ) )
    THEN
      -- 項目数不一致の場合
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_11295  -- ファイルレコード項目数不一致エラーメッセージ
                     ,iv_token_name1  =>  cv_data_tok
                     ,iv_token_value1 =>  lv_rec_data       -- フォーマットパターン
                   );
      ov_errbuf := chr(10) || lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 分割ループ
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                              iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                            , iv_delim    =>  cv_csv_delimiter
                            , in_part_num =>  i
                          );
    END LOOP data_split_loop;
--
    IF (g_if_data_tab(cn_process_type) IS NOT NULL ) THEN
      -- 控除区分、控除タイプ取得
      BEGIN
        SELECT  flv.lookup_code     AS  data_type
              , flv.attribute1      AS  condition_class
              , flv.attribute2      AS  condition_type
        INTO    lv_data_type
              , lv_condition_cls
              , lv_condition_type
        FROM    fnd_lookup_values flv
        WHERE   flv.lookup_type       = cv_type_deduction_data
        AND     flv.language          = ct_language
        AND     flv.meaning           = g_if_data_tab(cn_data_type)
        AND     flv.enabled_flag      = cv_const_y
        AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                AND     NVL(flv.end_date_active, gd_process_date)
        ;
--
        -- 控除区分のチェック
        IF  lv_condition_cls IS NOT NULL THEN
          BEGIN
            SELECT  COUNT(1)
            INTO    ln_dummy
            FROM    fnd_lookup_values flv
            WHERE   flv.lookup_type       = cv_type_deduction_kbn
            AND     flv.language          = ct_language
            AND     flv.lookup_code       = lv_condition_cls
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                AND     NVL(flv.end_date_active, gd_process_date)
            ;
          END;
        END IF;
--
        IF  lv_condition_cls IS NULL OR ln_dummy = 0 THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_10682
                         ,iv_token_name1  =>  cv_table_tok
                         ,iv_token_value1 =>  cv_msg_lookup_d_kbn
                         ,iv_token_name2  =>  cv_tkn_code
                         ,iv_token_value2 =>  lv_condition_cls
                         ,iv_token_name3  =>  cv_col_name_tok
                         ,iv_token_value3 =>  cv_msg_data_type
                         ,iv_token_name4  =>  cv_col_value_tok
                         ,iv_token_value4 =>  g_if_data_tab(cn_data_type)
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
        END IF;
        -- 控除タイプのチェック
        IF  lv_condition_type IS NOT NULL THEN
          BEGIN
            SELECT  COUNT(1)
            INTO    ln_dummy
            FROM    fnd_lookup_values flv
            WHERE   flv.lookup_type       = cv_type_deduction_type
            AND     flv.language          = ct_language
            AND     flv.lookup_code       = lv_condition_type
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND     NVL(flv.end_date_active, gd_process_date)
            ;
            END;
        END IF;
--
        IF  lv_condition_cls IS NULL OR ln_dummy = 0 THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_10682
                         ,iv_token_name1  =>  cv_table_tok
                         ,iv_token_value1 =>  cv_msg_lookup_d_type
                         ,iv_token_name2  =>  cv_tkn_code
                         ,iv_token_value2 =>  lv_condition_type
                         ,iv_token_name3  =>  cv_col_name_tok
                         ,iv_token_value3 =>  cv_msg_data_type
                         ,iv_token_name4  =>  cv_col_value_tok
                         ,iv_token_value4 =>  g_if_data_tab(cn_data_type)
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_cok
                         ,iv_name         =>  cv_msg_cok_00015
                         ,iv_token_name1  =>  cv_lookup_value_set
                         ,iv_token_value1 =>  cv_msg_data_type
                       );
          lv_errbuf :=  lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --********************************************************
      --* 桁数チェック処理
      --********************************************************
      -- カーソルオープン
      OPEN chk_item_cur;
      -- データの一括取得
      FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
      -- カーソルクローズ
      CLOSE chk_item_cur;
      -- クイックコードが取得できない場合
      IF ( g_chk_item_tab.COUNT = 0 ) THEN
        -- 参照タイプ取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok            -- アプリケーション短縮名
                       , iv_name         => cv_msg_cok_00015          -- メッセージコード
                       , iv_token_name1  => cv_lookup_value_set       -- トークンコード1
                       , iv_token_value1 => cv_type_column_digit_chk  -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      << item_check_loop >>
      FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
        -- 型桁チェック共通関数呼び出し
        xxccp_common_pkg2.upload_item_check(
          iv_item_name     => g_chk_item_tab(i).meaning    -- 1.項目名称
         ,iv_item_value    => g_if_data_tab(i)             -- 2.項目の値
         ,in_item_len      => g_chk_item_tab(i).attribute1 -- 項目の長さ
         ,in_item_decimal  => g_chk_item_tab(i).attribute2 -- 項目の長さ(小数点以下)
         ,iv_item_nullflg  => g_chk_item_tab(i).attribute3 -- 必須フラグ
         ,iv_item_attr     => g_chk_item_tab(i).attribute4 -- 項目属性
         ,ov_errbuf        => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
         ,ov_retcode       => lv_retcode                   -- リターン・コード             --# 固定 #
         ,ov_errmsg        => lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        --ワーニング
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 項目不備エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cok            -- アプリケーション短縮名
                     , iv_name         => cv_msg_cok_10709          -- メッセージコード
                     , iv_token_name1  => cv_tkn_item               -- トークンコード1
                     , iv_token_value1 => g_chk_item_tab(i).meaning -- トークン値1
                     , iv_token_name2  => cv_tkn_record_no          -- トークンコード2
                     , iv_token_value2 => g_if_data_tab(i)          -- トークン値2
                     , iv_token_name3  => cv_tkn_errmsg             -- トークンコード3
                     , iv_token_value3 => lv_errmsg                 -- トークン値3
                      );
--
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => (in_file_if_loop_cnt-1)||cv_msg_csv_line || lv_errmsg
          );
          gn_chk_cnt := 1;
-- 2021/04/06 Ver1.1 ADD Start
					gn_warn_cnt	:=  gn_warn_cnt + 1;
-- 2021/04/06 Ver1.1 ADD End
--
        --共通関数エラー
        ELSIF ( lv_retcode = cv_status_error ) THEN
          gn_chk_cnt := 1;
        --正常終了
        END IF;
      END LOOP item_check_loop;
--
      IF  gn_chk_cnt = 0 THEN
--
      --********************************************************
      --* ワークテーブル登録処理
      --********************************************************
--
      -- ワークテーブルにデータを格納する
      BEGIN
        INSERT INTO xxcok_condition_temp(
          csv_no                          -- CSV行数
        , request_id                      -- 要求ID
        , csv_process_type                -- CSV処理区分
        , process_type                    -- 処理区分
        , condition_no                    -- 控除番号
        , corp_code                       -- 企業コード
        , deduction_chain_code            -- チェーン店コード
        , customer_code                   -- 顧客コード
        , data_type                       -- データ種類
        , start_date_active               -- 開始日
        , end_date_active                 -- 終了日
        , content                         -- 内容
        , decision_no                     -- 決裁No
        , agreement_no                    -- 契約番号
        , process_type_line               -- 明細処理区分
        , detail_number                   -- 明細番号
        , target_category                 -- 対象区分
        , product_class                   -- 商品区分
        , item_code                       -- 品目コード
        , uom_code                        -- 単位
        , shop_pay_1                      -- 店納(％)_1
        , material_rate_1                 -- 料率(％)_1
        , demand_en_3                     -- 請求(円)_3
        , shop_pay_en_3                   -- 店納(円)_3
        , wholesale_margin_en_3           -- 問屋マージン(円)_3
        , wholesale_margin_per_3          -- 問屋マージン(％)_3
        , normal_shop_pay_en_4            -- 通常店納(円)_4
        , just_shop_pay_en_4              -- 今回店納(円)_4
        , wholesale_adj_margin_en_4       -- 問屋マージン修正(円)_4
        , wholesale_adj_margin_per_4      -- 問屋マージン修正(％)_4
        , prediction_qty_5_6              -- 予測数量(本)_5_6
        , support_amount_sum_en_5         -- 協賛金合計(円)_5
        , condition_unit_price_en_2_6     -- 条件単価(円)_2_6
        , target_rate_6                   -- 対象率(％)_6
-- 2021/04/06 Ver1.1 MOD Start
--        , accounting_base                 -- 計上拠点
        , accounting_customer_code        -- 計上顧客
-- 2021/04/06 Ver1.1 MOD End
        , deduction_amount                -- 控除額(本体)
        , tax_code                        -- 税コード
        , deduction_tax_amount            -- 控除税額
        , condition_cls                   -- 控除区分
        , condition_type                  -- 控除タイプ
        , created_by                      -- 作成者
        , creation_date                   -- 作成日
        , last_updated_by                 -- 最終更新者
        , last_update_date                -- 最終更新日
        , last_update_login               -- 最終更新ログイン
        , program_application_id          -- コンカレント・プログラム・アプリケーションID
        , program_id                      -- コンカレント・プログラムID
        , program_update_date             -- プログラム更新日
        )VALUES(
          in_file_if_loop_cnt                                                     -- CSV行数
        , cn_request_id                                                           -- 要求ID
        , g_if_data_tab(cn_process_type)                                          -- CSV処理区分
        , CASE
            -- CSV処理区分が「新規」で控除番号が未設定の場合「I」を設定
            WHEN g_if_data_tab(cn_process_type) = cv_csv_insert AND g_if_data_tab(cn_condition_no) IS NULL THEN
              cv_process_insert
            -- CSV処理区分が「修正」の場合「U」を設定
            WHEN g_if_data_tab(cn_process_type) = cv_csv_update THEN
              cv_process_update
            -- CSV処理区分が「決裁」の場合「Z」を設定
            WHEN g_if_data_tab(cn_process_type) = cv_csv_decision THEN
              cv_process_decision
            -- 上記以外の場合「N」を設定
            ELSE
              cv_const_n
          END
        , g_if_data_tab(cn_condition_no)                                          -- 控除番号
        , g_if_data_tab(cn_corp_code)                                             -- 企業コード
        , g_if_data_tab(cn_deduction_chain_code)                                  -- チェーン店コード
        , g_if_data_tab(cn_customer_code)                                         -- 顧客コード
        , lv_data_type                                                            -- データ種類
        , g_if_data_tab(cn_start_date_active)                                     -- 開始日
        , g_if_data_tab(cn_end_date_active)                                       -- 終了日
        , g_if_data_tab(cn_content)                                               -- 内容
        , g_if_data_tab(cn_decision_no)                                           -- 決裁No
        , g_if_data_tab(cn_agreement_no)                                          -- 契約番号
        , CASE
            -- CSV処理区分が「新規」の場合「I」を設定
            WHEN g_if_data_tab(cn_process_type) = cv_csv_insert THEN
              cv_process_insert
            -- CSV処理区分が「削除」の場合「D」を設定
            WHEN g_if_data_tab(cn_process_type) = cv_csv_delete THEN
              cv_process_delete
            -- 上記以外の場合「N」を設定
            ELSE
              cv_const_n
          END                                                                     -- 明細処理区分
        , g_if_data_tab(cn_detail_number)                                         -- 明細番号
        , g_if_data_tab(cn_target_category)                                       -- 対象区分
        , g_if_data_tab(cn_product_class)                                         -- 商品区分
        , g_if_data_tab(cn_item_code)                                             -- 品目コード
        , g_if_data_tab(cn_uom_code)                                              -- 単位
        , TO_NUMBER(g_if_data_tab(cn_shop_pay_1))                                 -- 店納(％)_1
        , TO_NUMBER(g_if_data_tab(cn_material_rate_1))                            -- 料率(％)_1
        , TO_NUMBER(g_if_data_tab(cn_demand_en_3))                                -- 請求(円)_3
        , TO_NUMBER(g_if_data_tab(cn_shop_pay_en_3))                              -- 店納(円)_3
        , TO_NUMBER(g_if_data_tab(cn_wholesale_margin_en_3))                      -- 問屋マージン(円)_3
        , TO_NUMBER(g_if_data_tab(cn_wholesale_margin_per_3))                     -- 問屋マージン(％)_3
        , TO_NUMBER(g_if_data_tab(cn_normal_shop_pay_en_4))                       -- 通常店納(円)_4
        , TO_NUMBER(g_if_data_tab(cn_just_shop_pay_en_4))                         -- 今回店納(円)_4
        , TO_NUMBER(g_if_data_tab(cn_wholesale_adj_margin_en_4))                  -- 問屋マージン修正(円)_4
        , TO_NUMBER(g_if_data_tab(cn_wholesale_adj_margin_per_4))                 -- 問屋マージン修正(％)_4
        , TO_NUMBER(g_if_data_tab(cn_prediction_qty_5_6))                         -- 予測数量(本)_5_6
        , TO_NUMBER(g_if_data_tab(cn_support_amount_sum_en_5))                    -- 協賛金合計(円)_5
        , TO_NUMBER(g_if_data_tab(cn_condition_unit_price_en_2_6))                -- 条件単価(円)_2_6
        , TO_NUMBER(g_if_data_tab(cn_target_rate_6))                              -- 対象率(％)_6
-- 2021/04/06 Ver1.1 MOD Start
--        , g_if_data_tab(cn_accounting_base)                                       -- 計上拠点
        , g_if_data_tab(cn_accounting_customer_code)                              -- 計上顧客
-- 2021/04/06 Ver1.1 MOD End
        , TO_NUMBER(g_if_data_tab(cn_deduction_amount))                           -- 控除額(本体)
        , TO_NUMBER(g_if_data_tab(cn_tax_code))                                   -- 税コード
        , TO_NUMBER(g_if_data_tab(cn_deduction_tax_amount))                       -- 控除税額
        , lv_condition_cls                                                        -- 控除区分
        , lv_condition_type                                                       -- 控除タイプ
        , cn_created_by                                                           -- 作成者
        , cd_creation_date                                                        -- 作成日
        , cn_last_updated_by                                                      -- 最終更新者
        , cd_last_update_date                                                     -- 最終更新日
        , cn_last_update_login                                                    -- 最終更新ログイン
        , cn_program_application_id                                               -- コンカレント・プログラム・アプリケーションID
        , cn_program_id                                                           -- コンカレント・プログラムID
        , cd_program_update_date                                                  -- プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージの取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10622
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      ELSE
        ov_retcode := cv_status_warn;
      END IF;
    --
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END divide_item;
--
    /**********************************************************************************
   * Procedure Name   : ins_exclusive_ctl_info
   * Description      : 排他制御管理テーブル登録(A-5-1)
   ***********************************************************************************/
  PROCEDURE ins_exclusive_ctl_info(
    ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_exclusive_ctl_info'; -- プログラム名
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
    PRAGMA AUTONOMOUS_TRANSACTION;  -- 自立型宣言
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
    INSERT INTO xxcok_exclusive_ctl_info(
      condition_no
    , request_id                                -- 要求ID
    )VALUES(
      g_exclusive_ctl_rec.condition_no  -- 控除番号
    , g_exclusive_ctl_rec.request_id    -- 要求ID
    );
    
    COMMIT;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10622
           , iv_token_name1  => cv_tkn_err_msg
           , iv_token_value1 => SQLERRM
           );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_exclusive_ctl_info;
--
    /**********************************************************************************
   * Procedure Name   : exclusive_check
   * Description      : 控除マスタ排他制御処理(A-5)
   ***********************************************************************************/
  PROCEDURE exclusive_check(
    ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exclusive_check'; -- プログラム名
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
    cv_msg_exclusive_ctl    CONSTANT VARCHAR2(20)  := '排他制御管理テーブル';
--
    -- *** ローカル変数 ***
    ln_count       NUMBER;
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
    -- ローカル変数初期化
    ln_count  :=  0;
--
    -- データがロックされていないか確認
    BEGIN
      SELECT
        COUNT(1)      AS  cnt
      INTO ln_count
      FROM
          xxcok_exclusive_ctl_info  xeci
        , xxcok_condition_temp      xct
      WHERE xct.condition_no  =   xeci.condition_no
      ;
    END;
--
    IF ln_count = 0 THEN
--
      --********************************************************
      --* 排他制御管理テーブル登録処理
      --********************************************************
      -- カーソルオープン
      OPEN g_exclusive_ctl_cur;
--
      LOOP
        FETCH g_exclusive_ctl_cur INTO g_exclusive_ctl_rec;
        EXIT WHEN g_exclusive_ctl_cur%NOTFOUND;
--
          -- ============================================
          -- A-5-1．排他制御管理テーブル登録
          -- ============================================
          ins_exclusive_ctl_info(
              ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
            , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
            , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
          );
      END LOOP;
      -- カーソルクローズ
      CLOSE g_exclusive_ctl_cur;
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                   , iv_name         => cv_msg_cok_10614
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      RAISE global_process_expt;
--
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END exclusive_check;
--
    /**********************************************************************************
   * Procedure Name   : validity_check
   * Description      : 妥当性チェック(A-6)
   ***********************************************************************************/
  PROCEDURE validity_check(
      ov_errbuf       OUT VARCHAR2                    -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2                    -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2)                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validity_check'; -- プログラム名
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
    lv_token_name             VARCHAR2(1000); -- トークン名
    lv_token_value            VARCHAR2(100);  -- トークン値
    lv_base_code_h            VARCHAR2(10);   -- 担当拠点
    lv_cast_date_flag         VARCHAR2(1);    -- 日付整合性フラグ
    ln_dummy                  NUMBER;         -- ダミー一時格納変数
    ln_dummy_condition_no     NUMBER;         -- ダミー控除番号
    ld_start_date             DATE;           -- 開始日
    ld_end_date               DATE;           -- 終了日
    ln_tax_rate               NUMBER;         -- 税率
    ln_tax_rate_1             NUMBER;         -- 税率(控除条件取得用)
    ld_before_start_date      DATE;           -- 修正前開始日
    ld_before_end_date        DATE;           -- 修正前終了日
    lt_prev_condition_no1     xxcok_condition_temp.condition_no%TYPE;         -- 前回処理控除番号
    lt_prev_condition_no2     xxcok_condition_temp.condition_no%TYPE;         -- 前回処理控除番号
    lt_exists_header          xxcok_condition_temp.condition_no%TYPE;         -- 控除条件ID
    lt_exists_line            xxcok_condition_temp.detail_number%TYPE;        -- 控除詳細ID
    lt_max_detail_number      xxcok_condition_temp.detail_number%TYPE;        -- 最大明細番号
    lt_set_detail_number      xxcok_condition_temp.detail_number%TYPE;        -- 明細番号
    lt_master_start_date      xxcok_condition_header.start_date_active%TYPE;  -- マスタ開始日
    lt_business_low_type      xxcmm_cust_accounts.business_low_type%TYPE;     -- 業態小分類
    ln_cnt                    NUMBER;
    lt_product_class_code     mtl_categories_vl.segment1%TYPE;                -- 商品区分コード
    lt_target_category        xxcok_condition_temp.target_category%TYPE;      -- 対象区分
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
    -- ローカル変数初期化(ループ内)
    lv_errbuf             :=  NULL;
    lv_base_code_h        :=  cv_dummy_base;
    lv_token_name         :=  NULL;
    ln_dummy              :=  NULL;
    ln_dummy_condition_no :=  0;
    lt_prev_condition_no1 :=  NULL;
    g_message_list_tab.DELETE;
--
    --  ******************************************
    --  ダミー控除番号採番
    --  ******************************************
--
    DECLARE
      -- 控除タイプ070用
      CURSOR  dummy_con_1_cur
      IS
        SELECT DISTINCT 
                xct.corp_code                   AS corp_code                -- 企業コード
              , xct.deduction_chain_code        AS deduction_chain_code     -- チェーン店コード
              , xct.customer_code               AS customer_code            -- 顧客コード
              , xct.data_type                   AS data_type                -- データ種類
              , xct.tax_code                    AS tax_code                 -- 消費税コード
              , xct.start_date_active           AS start_date_active        -- 開始日
              , xct.end_date_active             AS end_date_active          -- 終了日
              , xct.content                     AS content                  -- 内容
              , xct.decision_no                 AS decision_no              -- 決裁No
              , xct.agreement_no                AS agreement_no             -- 契約番号
        FROM    xxcok_condition_temp    xct
        WHERE   xct.process_type      =   cv_process_insert
        AND     xct.condition_type    =   cv_condition_type_fix_con
        ;
      dummy_con_1_rec   dummy_con_1_cur%ROWTYPE;
      -- 控除タイプ070以外用
      CURSOR  dummy_con_2_cur
      IS
        SELECT  DISTINCT
                xct.corp_code                   AS corp_code                -- 企業コード
              , xct.deduction_chain_code        AS deduction_chain_code     -- チェーン店コード
              , xct.customer_code               AS customer_code            -- 顧客コード
              , xct.data_type                   AS data_type                -- データ種類
              , xct.tax_code                    AS tax_code                 -- 消費税コード
              , xct.start_date_active           AS start_date_active        -- 開始日
              , xct.end_date_active             AS end_date_active          -- 終了日
              , xct.content                     AS content                  -- 内容
              , xct.decision_no                 AS decision_no              -- 決裁No
              , xct.agreement_no                AS agreement_no             -- 契約番号
        FROM    xxcok_condition_temp    xct
        WHERE   xct.process_type      =   cv_process_insert
        AND     xct.condition_type    <> cv_condition_type_fix_con
        ;
      dummy_con_2_rec   dummy_con_2_cur%ROWTYPE;
--
    BEGIN
      -- 控除タイプが070の場合
      FOR dummy_con_1_rec IN dummy_con_1_cur LOOP
        ln_dummy_condition_no :=  ln_dummy_condition_no - 1;
        UPDATE  xxcok_condition_temp xct
        SET     xct.condition_no    =   TO_CHAR(ln_dummy_condition_no)
        WHERE   NVL(xct.corp_code, cv_dummy_code)               =   NVL(dummy_con_1_rec.corp_code, cv_dummy_code)
        AND     NVL(xct.deduction_chain_code, cv_dummy_code)    =   NVL(dummy_con_1_rec.deduction_chain_code, cv_dummy_code)
        AND     NVL(xct.customer_code, cv_dummy_code)           =   NVL(dummy_con_1_rec.customer_code, cv_dummy_code)
        AND     xct.data_type                                   =   dummy_con_1_rec.data_type
        AND     xct.tax_code                                    =   dummy_con_1_rec.tax_code
        AND     xct.start_date_active                           =   dummy_con_1_rec.start_date_active
        AND     xct.end_date_active                             =   dummy_con_1_rec.end_date_active
        AND     NVL(xct.content, cv_dummy_code)                 =   NVL(dummy_con_1_rec.content, cv_dummy_code)
        AND     NVL(xct.decision_no, cv_dummy_code)             =   NVL(dummy_con_1_rec.decision_no, cv_dummy_code)
        AND     NVL(xct.agreement_no, cv_dummy_code)            =   NVL(dummy_con_1_rec.agreement_no, cv_dummy_code)
        AND     xct.process_type                                =   cv_process_insert
        AND     xct.request_id                                  =   cn_request_id
        ;
--
      END LOOP;
      -- 控除タイプが070以外の場合
      FOR dummy_con_2_rec IN dummy_con_2_cur LOOP
--
          ln_dummy_condition_no :=  ln_dummy_condition_no - 1;
--
        UPDATE  xxcok_condition_temp xct
        SET     condition_no  =   TO_CHAR(ln_dummy_condition_no)
        WHERE   NVL(xct.corp_code, cv_dummy_code)               =   NVL(dummy_con_2_rec.corp_code, cv_dummy_code)
        AND     NVL(xct.deduction_chain_code, cv_dummy_code)    =   NVL(dummy_con_2_rec.deduction_chain_code, cv_dummy_code)
        AND     NVL(xct.customer_code, cv_dummy_code)           =   NVL(dummy_con_2_rec.customer_code, cv_dummy_code)
        AND     NVL(xct.tax_code, cv_dummy_code)                =   NVL(dummy_con_2_rec.tax_code, cv_dummy_code)
        AND     xct.data_type                                   =   dummy_con_2_rec.data_type
        AND     xct.start_date_active                           =   dummy_con_2_rec.start_date_active
        AND     xct.end_date_active                             =   dummy_con_2_rec.end_date_active
        AND     NVL(xct.content, cv_dummy_code)                 =   NVL(dummy_con_2_rec.content, cv_dummy_code)
        AND     NVL(xct.decision_no, cv_dummy_code)             =   NVL(dummy_con_2_rec.decision_no, cv_dummy_code)
        AND     NVL(xct.agreement_no, cv_dummy_code)            =   NVL(dummy_con_2_rec.agreement_no, cv_dummy_code)
        AND     xct.process_type                                =   cv_process_insert
        AND     xct.request_id                                  =   cn_request_id
        ;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
    <<g_cond_tmp_chk_loop>>
    FOR g_cond_tmp_chk_rec IN g_cond_tmp_chk_cur LOOP
--
      --  メッセージインデックス初期化
      ln_cnt  :=  0;
--
      --  CSV処理区分が登録,削除,修正,決裁 以外の場合
      IF  NVL(g_cond_tmp_chk_rec.csv_process_type, cv_const_n ) NOT IN ( cv_csv_delete, cv_csv_update, cv_csv_insert, cv_csv_decision, cv_const_n ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10597
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_pro_type
           , iv_token_name2  => cv_col_value_tok
           , iv_token_value2 => g_cond_tmp_chk_rec.csv_process_type
        );
        ln_cnt  :=  ln_cnt + 1;
        g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
      END IF;
--
      IF ( ln_cnt <> 0 ) THEN
        --  メッセージありの場合
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
      --  ******************************************
      --  マスタデータ取得
      --  ******************************************
      --  NULL/NULLの場合、以降全てスキップ
      IF g_cond_tmp_chk_rec.process_type = cv_const_n AND g_cond_tmp_chk_rec.process_type_line = cv_const_n THEN
        gn_skip_cnt := gn_skip_cnt + 1;
        CONTINUE g_cond_tmp_chk_loop;
      ELSE
        --  初期化
        lv_cast_date_flag :=  cv_const_y;
        lt_exists_header  :=  NULL;
        lt_exists_line    :=  NULL;
        lt_max_detail_number  :=  0;
        ln_tax_rate           :=  0;              -- 税率
        ln_tax_rate_1         :=  0;              -- 税率(控除条件取得用)
        ld_before_start_date  :=  NULL;           -- 修正前開始日
        ld_before_end_date    :=  NULL;           -- 修正前終了日
        --
        -- 処理区分がU（変更）、または明細処理区分がD（削除）の場合、変更前開始日、変更前終了日を取得
        IF g_cond_tmp_chk_rec.process_type_line IN( cv_process_delete )
          OR g_cond_tmp_chk_rec.process_type IN  (cv_process_update,cv_process_decision) THEN
          BEGIN
            SELECT xch.start_date_active    -- 開始日
                  ,xch.end_date_active      -- 終了日
            INTO   ld_before_start_date
                  ,ld_before_end_date
            FROM   xxcok_condition_header xch
            WHERE  xch.condition_no    = g_cond_tmp_chk_rec.condition_no  -- 控除No
            AND    xch.enabled_flag_h  = cv_const_y                   -- 有効フラグ
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ld_before_start_date := NULL;
              ld_before_end_date   := NULL;
          END;
        END IF;
--
        --  控除マスタ（ヘッダ）データを取得する
        --  処理区分が'I'(登録)以外 且つ 1データ目 又は 控除番号が変更された場合
        IF    ( g_cond_tmp_chk_rec.process_type <> cv_process_insert
          AND ( lt_prev_condition_no1 IS NULL
            OR  lt_prev_condition_no1 <> g_cond_tmp_chk_rec.condition_no ) )
        THEN
          BEGIN
            --
            SELECT  xch.condition_id          AS  condition_id
                  , NVL( (  SELECT MAX( sub.detail_number )     AS  max_detail_number
                            FROM xxcok_condition_lines sub
                            WHERE sub.condition_no = xch.condition_no ), 0 )
                                              AS  max_detail_number
                  , xch.start_date_active     AS  start_date_active
            INTO    lt_exists_header
                  , lt_max_detail_number
                  , lt_master_start_date
            FROM    xxcok_condition_header    xch
            WHERE   xch.condition_no      =   g_cond_tmp_chk_rec.condition_no
            AND     xch.enabled_flag_h    =   cv_const_y
            ;
            --
            IF ( lt_exists_header IS NOT NULL ) THEN
              --  控除条件IDが取得された場合、TEMPに保持（明細挿入時に使用）:同一控除番号に一律設定
              UPDATE  xxcok_condition_temp    xct
              SET     xct.condition_id    =   lt_exists_header
              WHERE   xct.condition_no    =   g_cond_tmp_chk_rec.condition_no
              ;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_exists_header  :=  NULL;
              lt_max_detail_number  :=  0;
          END;
          --
        END IF;
--
        --  控除マスタ（明細）データを取得する
        --  処理区分が'I'(登録)以外 且つ 明細処理区分が'I'(登録)以外の場合
        IF    ( g_cond_tmp_chk_rec.process_type <> cv_process_insert
          AND ( g_cond_tmp_chk_rec.process_type_line <> cv_process_insert ) )
        THEN
          BEGIN
            --
            SELECT  xcl.condition_line_id     AS  condition_line_id
            INTO    lt_exists_line
            FROM    xxcok_condition_lines     xcl
            WHERE   xcl.condition_no      =   g_cond_tmp_chk_rec.condition_no
            AND     xcl.detail_number     =   g_cond_tmp_chk_rec.detail_number
            AND     xcl.enabled_flag_l    =   cv_const_y
            ;
            --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_exists_line    :=  NULL;
          END;
          --
        END IF;
--
        --  明細番号採番
        --  明細INSERTの場合のみ採番
        IF  ( g_cond_tmp_chk_rec.process_type_line = cv_process_insert) THEN
          IF  (    lt_prev_condition_no1 IS NULL
                OR lt_prev_condition_no1 <> g_cond_tmp_chk_rec.condition_no ) THEN
            --  1データ目 or 控除番号が変わった場合
            --  明細番号の初期値設定
            lt_prev_condition_no1   :=  g_cond_tmp_chk_rec.condition_no;
            --
            IF ( g_cond_tmp_chk_rec.process_type = cv_process_insert ) THEN
              --  ヘッダINSERTの場合、明細初期値は 1
              lt_set_detail_number  :=  1;
            ELSE
              --  ヘッダINSERT以外の場合、マスタに設定済みの明細番号+1
              lt_set_detail_number  :=  lt_max_detail_number + 1;
            END IF;
          ELSE
            --  同一控除番号の場合、明細番号を加算
            lt_set_detail_number  :=  lt_set_detail_number + 1;
          END IF;
          --  明細番号設定
          g_cond_tmp_chk_rec.detail_number  :=  lt_set_detail_number;
        END IF;
--
        --  ******************************************
        --  共通チェック
        --  ******************************************
        --  ★明細が削除の場合
        IF  g_cond_tmp_chk_rec.process_type_line = cv_process_delete THEN
--
          -- 修正前開始日が業務日付到来後の場合
          IF ld_before_start_date <= gd_process_date THEN
            -- 特定拠点の所属者でない場合NG
            IF  gn_privilege_delete = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10612
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
--
        BEGIN
          --  1データ目 or 控除番号が変わった場合
          IF  (    lt_prev_condition_no2 IS NULL
                OR lt_prev_condition_no2 <> g_cond_tmp_chk_rec.condition_no ) THEN
            --  控除番号を保持
            lt_prev_condition_no2 :=  g_cond_tmp_chk_rec.condition_no;
            --  ヘッダの処理区分が更新の場合
--
-- 2021/04/06 Ver1.1 DEL Start
--            -- ⑦
--            IF  g_cond_tmp_chk_rec.condition_type = cv_condition_type_fix_con THEN
--              --  有効な明細情報が2行以上ある場合
--              SELECT  COUNT(1) AS cnt
--              INTO    ln_dummy
--              FROM    xxcok_condition_temp xct
--              WHERE   xct.condition_no                                  =   g_cond_tmp_chk_rec.condition_no
--              AND     xct.request_id                                    =   cn_request_id
--              ;
--              IF ln_dummy >= 2 THEN
--                lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cok
--                   , iv_name         => cv_msg_cok_10608
--                   , iv_token_name1  => cv_col_name_tok
--                   , iv_token_value1 => cv_msg_condition_no
--                   );
--                  ln_cnt  :=  ln_cnt + 1;
--                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--              END IF;
--            END IF;
-- 2021/04/06 Ver1.1 DEL End
--
          END IF;
--
        END;
--
        BEGIN
          -- 8-1.★企業コードでチェック
          IF  g_cond_tmp_chk_rec.corp_code IS NOT NULL THEN
            lv_token_name :=  cv_msg_kigyo_code;
            lv_token_value  := g_cond_tmp_chk_rec.corp_code;
--
            SELECT  ffv.attribute2      AS  base_code   -- 本部担当拠点
            INTO    lv_base_code_h
            FROM    fnd_flex_value_sets ffvs
                  , fnd_flex_values     ffv
                  , fnd_flex_values_tl  ffvt
            WHERE ffvs.flex_value_set_id    = ffv.flex_value_set_id
            AND   ffv.flex_value_id         = ffvt.flex_value_id
            AND   ffvs.flex_value_set_name  = cv_type_business_type
            AND   ffvt.language             = ct_language
            AND   ffv.summary_flag          = cv_const_n
            AND   ffv.flex_value            = g_cond_tmp_chk_rec.corp_code
            ;
--
          END IF;
--
          -- 8-2.★控除用チェーンコードでチェック
          IF g_cond_tmp_chk_rec.deduction_chain_code IS NOT NULL THEN
--
            lv_token_name :=  cv_msg_chain_code;
            lv_token_value  := g_cond_tmp_chk_rec.deduction_chain_code;
--
            SELECT  flv.attribute3      AS  base_code   -- 本部担当拠点
            INTO    lv_base_code_h
            FROM    fnd_lookup_values flv
            WHERE   flv.language          = ct_language
            AND     flv.lookup_type       = cv_type_chain_code
            AND     flv.lookup_code       = g_cond_tmp_chk_rec.deduction_chain_code
            AND     flv.enabled_flag      = cv_const_y
            AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                    AND     NVL(flv.end_date_active, gd_process_date)
            ;
--
          END IF;
--
          -- 8-3.★顧客コードでチェック
          IF g_cond_tmp_chk_rec.customer_code IS NOT NULL THEN
--
            lv_token_name :=  cv_msg_cust_code;
            lv_token_value  := g_cond_tmp_chk_rec.customer_code;
--
            SELECT  xca.sale_base_code      AS  base_code           --  売上担当拠点
                  , xca.business_low_type   AS  business_low_type   --  業態小分類
            INTO    lv_base_code_h
                  , lt_business_low_type
            FROM    hz_cust_accounts          hca
                  , xxcmm.xxcmm_cust_accounts xca
            WHERE   hca.cust_account_id =  xca.customer_id
            AND     hca.status              = cv_cust_accounts_status
            AND     hca.customer_class_code = cv_cust_class_cust
            AND     hca.account_number      = g_cond_tmp_chk_rec.customer_code
            ;
          END IF;
--
          -- 8-4.★取得した担当拠点とログインユーザの所属拠点が異なっていればエラー
          IF gn_privilege_up_ins = 0
            AND gv_user_base <> lv_base_code_h
            AND lv_token_name IS NOT NULL THEN
--
            lv_errmsg   := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10613
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => lv_token_name
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => lv_token_value
                           );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
--
          -- 8-5.★フルVD、フルVD消化、現金取引顧客、百貨店、専門店の顧客を指定している
          IF    g_cond_tmp_chk_rec.customer_code IS NOT NULL 
            AND lt_business_low_type IN( '20','21','22','24','25' ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10597
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_cust_code
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.customer_code
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
--
          --  ★明細が削除の場合
          IF    g_cond_tmp_chk_rec.process_type_line = cv_process_delete THEN
            --  マスタの開始日が業務日付到来前の場合
            IF ld_before_start_date > gd_process_date THEN
              -- 8-7.担当拠点とログインユーザの所属拠点が異なっている場合
              IF gn_privilege_up_ins = 0
                AND gv_user_base <> lv_base_code_h
                AND lv_token_name IS NOT NULL THEN
--
                -- 特定拠点の所属者でない場合NG
                IF  gn_privilege_delete = 0 THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10612
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
                END IF;
              END IF;
            END IF;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 8-6.★企業、チェーン、顧客がマスタに存在しない
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => lv_token_name
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => lv_token_value
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END;
--
        --  ******************************************
        --  ヘッダチェック
        --  ******************************************
        --  ★処理区分組み合わせ
        --  控除番号存在チェック
        --  CSV処理区分が修正,削除,決裁の場合
        IF    g_cond_tmp_chk_rec.csv_process_type IN ( cv_csv_update, cv_csv_delete, cv_csv_decision ) THEN
          --  11.控除番号が指定されていない場合
          IF  g_cond_tmp_chk_rec.condition_no     IS  NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cok
                            , iv_name         => cv_msg_cok_10605
                            , iv_token_name1  => cv_if_value_tok
                            , iv_token_value1 => cv_msg_pro_type || cv_msg_ja_ga || cv_msg_update || cv_delimiter || cv_msg_delete || cv_delimiter || cv_msg_decision
                            , iv_token_name2  => cv_col_name_tok
                            , iv_token_value2 => cv_msg_condition_no
                            );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          ELSE
--
            -- 10.マスタに有効なデータが存在しない場合
            SELECT COUNT(1)    AS  dummy
            INTO   ln_dummy
            FROM   xxcok_condition_header  xch -- 控除条件
            WHERE  xch.condition_no   = g_cond_tmp_chk_rec.condition_no  -- 控除番号
            AND    xch.enabled_flag_h = cv_const_y                       -- 有効フラグ
            ;
--
            -- 0件だった場合、マスタ未登録エラー
            IF ln_dummy = 0 OR (ld_before_start_date IS NULL AND  ld_before_end_date IS NULL )THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10600
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_condition_no
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_no
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
--
        -- 10.CSV処理区分が登録で控除番号が指定されている場合
        ELSIF g_cond_tmp_chk_rec.csv_process_type  =   cv_csv_insert 
          AND g_cond_tmp_chk_rec.condition_no     IS  NOT NULL
          AND TO_NUMBER(g_cond_tmp_chk_rec.condition_no) >  0  THEN
--
          SELECT COUNT(1)    AS  dummy
          INTO   ln_dummy
          FROM   xxcok_condition_header  xch -- 控除条件
          WHERE  xch.condition_no   = g_cond_tmp_chk_rec.condition_no  -- 控除番号
          AND    xch.enabled_flag_h = cv_const_y                       -- 有効フラグ
          ;
--
          -- 0件だった場合、マスタ未登録エラー
          IF ln_dummy = 0 THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        --  ★ヘッダ、明細の何れかが更新の場合、マスタデータの開始日以降の場合NG
        IF  ( (     g_cond_tmp_chk_rec.process_type = cv_process_update 
                OR g_cond_tmp_chk_rec.process_type_line = cv_process_update )
              AND
              ( lt_master_start_date <= TRUNC(gd_process_date) )
            )
        THEN
          IF  (ld_before_start_date = TO_DATE(g_cond_tmp_chk_rec.start_date_active,cv_date_format)
          AND  ld_before_end_date = TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10604
                         , iv_token_name1  => cv_tkn_process_type
                         , iv_token_value1 => cv_msg_update
                         );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        --  12.★企業コード、チェーン店コード、顧客コードが1つも指定されていない
        IF (    g_cond_tmp_chk_rec.data_count = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10607
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code || cv_delimiter || cv_msg_chain_code || cv_delimiter ||
                                  cv_msg_cust_code
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        --  13.★企業コード、チェーン店コード、顧客コードのうち2つ以上が指定されている
        ELSIF ( g_cond_tmp_chk_rec.data_count <> 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10599
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code || cv_delimiter || cv_msg_chain_code || cv_delimiter ||
                                  cv_msg_cust_code
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        --  14.★控除タイプが③④で企業コードが設定されている（チェーン、顧客が未設定）
        ELSIF (     g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.corp_code IS NOT NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10598
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_kigyo_code
             );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
        --  15.★控除タイプが③④で税コードが設定されている
        ELSIF (     g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.tax_code IS NOT NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10598
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_tax_code
             );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
        --  16.★控除タイプが⑦で税コードが設定されていない
        ELSIF (     g_cond_tmp_chk_rec.condition_type = cv_condition_type_fix_con
                AND g_cond_tmp_chk_rec.tax_code IS NULL )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cok
                       , iv_name         => cv_msg_cok_10606
                       , iv_token_name1  => cv_col_name_tok
                       , iv_token_value1 => cv_msg_tax_code
                       );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
--
        --  17.★控除タイプが③④以外で税コードが設定されていて、税コードがマスタに存在しない場合
        IF (     g_cond_tmp_chk_rec.condition_type NOT IN( cv_condition_type_ws_fix, cv_condition_type_ws_add)
                AND g_cond_tmp_chk_rec.tax_code IS NOT NULL )  THEN
          BEGIN
            SELECT  tax_rate       AS  tax_rate
            INTO    ln_tax_rate
            FROM    ar_vat_tax_all_b avtab
            WHERE   avtab.tax_code        = g_cond_tmp_chk_rec.tax_code
            AND     avtab.set_of_books_id = gn_set_of_bks_id
            AND     avtab.org_id          = gn_org_id2
            AND     avtab.enabled_flag    = cv_const_y
            AND     TO_DATE( g_cond_tmp_chk_rec.start_date_active, cv_date_format )
                        BETWEEN TRUNC( avtab.start_date ) AND TRUNC( NVL( avtab.end_date, cd_max_date) )
            AND     TO_DATE( g_cond_tmp_chk_rec.end_date_active, cv_date_format )
                        BETWEEN TRUNC( avtab.start_date ) AND TRUNC( NVL( avtab.end_date, cd_max_date ) )
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10600
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_tax_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.tax_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END;
        ELSIF ( g_cond_tmp_chk_rec.tax_code IS NULL )  THEN
          ln_tax_rate := NULL;
        END IF;
            ld_start_date :=  TO_DATE( g_cond_tmp_chk_rec.start_date_active ,cv_date_format);
            ld_end_date   :=  TO_DATE( g_cond_tmp_chk_rec.end_date_active ,cv_date_format);
--
        --  18.★開始日が終了日よりも未来日（同日は可）
        IF ( ld_start_date > ld_end_date AND lv_cast_date_flag = cv_const_y )  THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10602
             , iv_token_name1  => cv_start_date_tok
             , iv_token_value1 => g_cond_tmp_chk_rec.start_date_active
             , iv_token_name2  => cv_end_date_tok
             , iv_token_value2 => g_cond_tmp_chk_rec.end_date_active
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
--
        --  処理区分が更新の場合
        IF (    g_cond_tmp_chk_rec.csv_process_type = cv_csv_update ) THEN
--
          -- 19.★修正前開始日が業務日付より前かつ開始日を修正する場合
          IF (ld_before_start_date != TO_DATE(g_cond_tmp_chk_rec.start_date_active,cv_date_format)) THEN
             IF (ld_before_start_date <= gd_process_date) THEN
               lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_msg_kbn_cok
                  , iv_name         => cv_msg_cok_10703
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
--
          --  20.★修正前終了日が業務日付よりも前かつ終了日を修正する場合
          IF (ld_before_end_date != TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
             IF (ld_before_end_date < gd_process_date) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10704
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
--
          --  21.★終了日が業務日付より過去日の場合
          IF (ld_before_end_date != TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format)) THEN
            IF (TO_DATE(g_cond_tmp_chk_rec.end_date_active,cv_date_format) < gd_process_date) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10705
               );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
             END IF; 
          END IF;
        END IF;
--
        -- 22.明細処理区分がD（削除）の場合
        IF  g_cond_tmp_chk_rec.process_type_line  = cv_process_delete THEN
          -- 明細番号が未設定の場合
          IF  g_cond_tmp_chk_rec.detail_number IS NULL THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cok
                          , iv_name         => cv_msg_cok_10605
                          , iv_token_name1  => cv_if_value_tok
                          , iv_token_value1 => cv_msg_dtl_pro_type || cv_msg_ja_ga || cv_msg_delete
                          , iv_token_name2  => cv_col_name_tok
                          , iv_token_value2 => cv_msg_detail_num
                          );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
          -- 23.DB上に該当する明細番号が存在するか確認
          ELSE
            SELECT COUNT(1)    AS  dummy
            INTO   ln_dummy
            FROM   xxcok_condition_lines  xcl -- 控除詳細
            WHERE  xcl.condition_no   = g_cond_tmp_chk_rec.condition_no   -- 控除番号
            AND    xcl.detail_number  = g_cond_tmp_chk_rec.detail_number  -- 明細番号
            AND    xcl.enabled_flag_l = cv_const_y                        -- 有効フラグ
            ;
---- 0件だった場合、マスタ未登録エラー
            IF ln_dummy = 0 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cok
                            , iv_name         => cv_msg_cok_10600
                            , iv_token_name1  => cv_col_name_tok
                            , iv_token_value1 => cv_msg_condition_no || cv_delimiter || cv_msg_detail_num
                            , iv_token_name2  => cv_col_value_tok
                            , iv_token_value2 => g_cond_tmp_chk_rec.condition_no || cv_delimiter || 
                                                 g_cond_tmp_chk_rec.detail_number
                            );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
--
        IF (  g_cond_tmp_chk_rec.process_type_line NOT IN (cv_process_delete, cv_const_n) ) THEN
          --  ******************************************
          --  ①請求額×料率（％）
          --  ******************************************
          IF ( g_cond_tmp_chk_rec.condition_type  = cv_condition_type_req )  THEN
--
            -- 25.品目コードと商品区分の両方が未設定の場合エラー
            IF    g_cond_tmp_chk_rec.item_code      IS NULL
              AND g_cond_tmp_chk_rec.product_class  IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_delimiter || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
            -- 26.品目コードと商品区分の両方が指定されている場合エラー
            IF    g_cond_tmp_chk_rec.item_code      IS NOT NULL
              AND g_cond_tmp_chk_rec.product_class  IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_msg_ja_to || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
            -- 27.品目コードがマスタに存在しない場合エラー -- ★★
            IF  g_cond_tmp_chk_rec.item_code  IS NOT NULL THEN
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 27.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
            END IF;
--
              -- 28-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 28-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 29.商品区分が品目カテゴリに登録されていない場合エラー
            IF g_cond_tmp_chk_rec.product_class IS NOT NULL THEN
              BEGIN
                SELECT  mcv.segment1
                INTO    lt_product_class_code
                FROM    mtl_category_sets_vl mcsv -- 品目カテゴリセットビュー
                      , mtl_categories_vl    mcv  -- 品目カテゴリビュー
                WHERE   mcsv.category_set_name  =   gv_item_div_h         -- カテゴリセット名 XXCOS:本社商品区分
                AND     mcsv.structure_id       =   mcv.structure_id
                AND     mcv.description         =   g_cond_tmp_chk_rec.product_class
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                                , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_kbn
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.product_class
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
              -- 30-1.商品区分重複チェック：明細の処理区分が登録で、同一控除番号、同一商品区分のデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.product_class  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.product_class        = g_cond_tmp_chk_rec.product_class     -- 商品区分
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 30-2.商品区分重複チェック：明細の処理区分が登録で、同一控除番号、同一商品区分のデータの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.product_class        = lt_product_class_code                -- 商品区分
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 31.対象区分が未設定の場合エラー
            IF g_cond_tmp_chk_rec.target_category IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_target_cate
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 32.対象区分が参照表に存在しない場合エラー
            ELSE
              BEGIN
                SELECT  flv.lookup_code     AS  target_category
                INTO    lt_target_category
                FROM    fnd_lookup_values   flv
                WHERE   flv.language          = ct_language
                AND     flv.lookup_type       = cv_type_deduction_1_kbn
                AND     flv.meaning           = g_cond_tmp_chk_rec.target_category
                AND     flv.enabled_flag      = cv_const_y
                AND     gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_target_cate
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.target_category
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
            -- 33.対象区分が「店納」で、店納(％)が未設定の場合エラー
            IF    g_cond_tmp_chk_rec.target_category  = cv_shop_pay
              AND g_cond_tmp_chk_rec.shop_pay_1       IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10605
                           , iv_token_name1  => cv_if_value_tok
                           , iv_token_value1 => cv_msg_target_cate || cv_msg_ja_ga || cv_msg_shop_pay
                           , iv_token_name2  => cv_col_name_tok
                           , iv_token_value2 => cv_msg_shop_pay || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 34.店納(％)の値が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.shop_pay_1 <= 0 
              OR TRUNC(g_cond_tmp_chk_rec.shop_pay_1, 2) <> g_cond_tmp_chk_rec.shop_pay_1  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.shop_pay_1
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 35.料率(％)が未設定の場合エラー
            IF g_cond_tmp_chk_rec.material_rate_1  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_meter_rate || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 36.料率(％)の値が0または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.material_rate_1 = 0 
              OR TRUNC(g_cond_tmp_chk_rec.material_rate_1, 2) <> g_cond_tmp_chk_rec.material_rate_1  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_meter_rate || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.material_rate_1
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          --  ***************************************
          --  ②販売数量×金額
          --  ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_sale  THEN
--
            -- 37.品目コードと商品区分の両方が未設定の場合エラー
            IF    g_cond_tmp_chk_rec.item_code      IS NULL
              AND g_cond_tmp_chk_rec.product_class  IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_delimiter || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 38.品目コードと商品区分の両方が指定されている場合エラー
            IF    g_cond_tmp_chk_rec.item_code      IS NOT NULL
              AND g_cond_tmp_chk_rec.product_class  IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code || cv_msg_ja_to || cv_msg_item_kbn
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 39.品目コードがマスタに存在しない場合エラー -- ★★
            IF  g_cond_tmp_chk_rec.item_code  IS NOT NULL THEN
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 39.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
            END IF;
--
            -- 40-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 40-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 41.商品区分が品目カテゴリに登録されていない場合エラー
            IF g_cond_tmp_chk_rec.product_class IS NOT NULL THEN
--
              BEGIN
                SELECT  mcv.segment1
                INTO    lt_product_class_code
                FROM    mtl_category_sets_vl mcsv -- 品目カテゴリセットビュー
                      , mtl_categories_vl    mcv  -- 品目カテゴリビュー
                WHERE   mcsv.category_set_name  =   gv_item_div_h         -- カテゴリセット名 XXCOS:本社商品区分
                AND     mcsv.structure_id       =   mcv.structure_id
                AND     mcv.description         =   g_cond_tmp_chk_rec.product_class
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                                , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_kbn
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.product_class
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
              -- 42-1.商品区分重複チェック：明細の処理区分が登録で、同一控除番号、同一商品区分のデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.product_class  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.product_class        = g_cond_tmp_chk_rec.product_class     -- 商品区分
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 42-2.商品区分重複チェック：明細の処理区分が登録で、同一控除番号、同一商品区分のデータの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.product_class        = lt_product_class_code                -- 商品区分
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_kbn
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 43.条件単価（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 44.条件単価（円）が0またはマイナス値または小数点が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6 = 0 
              OR  TRUNC(g_cond_tmp_chk_rec.condition_unit_price_en_2_6, 2)  <>  g_cond_tmp_chk_rec.condition_unit_price_en_2_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_unit_price_en_2_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * ③問屋未収（定額）のチェック
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_ws_fix  THEN
--
            -- 45.品目コードが未設定の場合エラー
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 46.品目コードがマスタに存在しない場合エラー -- ★★
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 46.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 48.品目コードに紐付く、単位換算が取得できない場合エラー
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => g_cond_tmp_chk_rec.uom_code
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 47-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10608
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 47-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 49.単位が未設定の場合エラー
            IF g_cond_tmp_chk_rec.uom_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_uom_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            ELSE
              -- 50.単位が「本」「CS」「BL」以外の場合エラー
              IF g_cond_tmp_chk_rec.uom_code  NOT IN (cv_uom_hon, cv_uom_cs, cv_uom_bl) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10597
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_uom_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.uom_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 51.請求（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.demand_en_3 IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_demand_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 52.店納（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.shop_pay_en_3 IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 53.問屋マージン（円）と問屋マージン(％)の両方が未設定の場合エラー
            IF    g_cond_tmp_chk_rec.wholesale_margin_en_3  IS NULL
              AND g_cond_tmp_chk_rec.wholesale_margin_per_3 IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_delimiter ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 54.問屋マージン（円）と問屋マージン(％)の両方が設定されている場合エラー
            IF    g_cond_tmp_chk_rec.wholesale_margin_en_3    IS NOT NULL
              AND g_cond_tmp_chk_rec.wholesale_margin_per_3   IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_msg_ja_to ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.請求（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.demand_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.demand_en_3 ,2)  <>  g_cond_tmp_chk_rec.demand_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_demand_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.demand_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.店納（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.shop_pay_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.shop_pay_en_3 ,2)  <>  g_cond_tmp_chk_rec.shop_pay_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_shop_pay || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.shop_pay_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.問屋マージン（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.wholesale_margin_en_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_margin_en_3 ,2)  <>  g_cond_tmp_chk_rec.wholesale_margin_en_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_margin_en_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 55.問屋マージン(％)が0またはマイナス値を超える場合エラー
            IF g_cond_tmp_chk_rec.wholesale_margin_per_3 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_margin_per_3 ,2)  <>  g_cond_tmp_chk_rec.wholesale_margin_per_3 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_margin_per_3
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * ④問屋未収（追加）のチェック
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_ws_add  THEN
--
            -- 56.品目コードが未設定の場合エラー -- ★★
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 57.品目コードがマスタに存在しない場合エラー
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 57.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 59.品目コードに紐付く、単位換算が取得できない場合エラー
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => g_cond_tmp_chk_rec.uom_code
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 58-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 58-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 60.単位が未設定の場合エラー
            IF g_cond_tmp_chk_rec.uom_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_uom_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            ELSE
              -- 61.単位が「本」「CS」「BL」以外の場合エラー
              IF g_cond_tmp_chk_rec.uom_code  NOT IN (cv_uom_hon, cv_uom_cs, cv_uom_bl) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10597
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_uom_code
                             , iv_token_name2  => cv_col_value_tok
                             , iv_token_value2 => g_cond_tmp_chk_rec.uom_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 62.通常店納（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.normal_shop_pay_en_4  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_normal_sp || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 63.今回店納（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.just_shop_pay_en_4  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_just_sp || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 64.問屋マージン修正（円）と問屋マージン修正(％)の両方が未設定の場合エラー
            IF    g_cond_tmp_chk_rec.wholesale_adj_margin_en_4    IS NULL
              AND g_cond_tmp_chk_rec.wholesale_adj_margin_per_4   IS NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10607
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_yen || cv_delimiter ||
                                                cv_msg_who_margin || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 65.問屋マージン修正（円）と問屋マージン修正(％)の両方が設定されている場合エラー
            IF    g_cond_tmp_chk_rec.wholesale_adj_margin_en_4    IS NOT NULL
              AND g_cond_tmp_chk_rec.wholesale_adj_margin_per_4   IS NOT NULL
            THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10599
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_yen ||
                                                cv_delimiter || cv_msg_who_margin || cv_msg_adj || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 66.通常店納（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.normal_shop_pay_en_4 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.normal_shop_pay_en_4 ,2)  <>  g_cond_tmp_chk_rec.normal_shop_pay_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_normal_sp || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.normal_shop_pay_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 66.今回店納（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.just_shop_pay_en_4 <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.just_shop_pay_en_4 ,2)  <>  g_cond_tmp_chk_rec.just_shop_pay_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_just_sp || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.just_shop_pay_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
-- 2021/04/28 Ver1.2 MOD Start
--            -- 66.問屋マージン修正（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            -- 66.問屋マージン修正（円）がマイナス値または小数桁が2桁を超える場合エラー

--            IF g_cond_tmp_chk_rec.wholesale_adj_margin_en_4  <= 0
            IF g_cond_tmp_chk_rec.wholesale_adj_margin_en_4  < 0
-- 2021/04/28 Ver1.2 MOD End
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 ,2)  <>  g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
-- 2021/04/28 Ver1.2 MOD Start
--            -- 66.問屋マージン修正(％)が0またはマイナス値または小数桁が2桁を超える場合エラー
            -- 66.問屋マージン修正(％)がマイナス値または小数桁が2桁を超える場合エラー
--            IF g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 <= 0
            IF g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 < 0
-- 2021/04/28 Ver1.2 MOD End
              OR  TRUNC(g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 ,2)  <>  g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_who_margin || cv_msg_adj || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * ⑤定額協賛金のチェック
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_spons  THEN
--
            -- 67.品目コードが未設定の場合エラー
            IF g_cond_tmp_chk_rec.item_code  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 68.品目コードがマスタに存在しない場合エラー -- ★★
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 68.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 70.品目コードに紐付く、単位換算が取得できない場合エラー
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => cv_uom_hon
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 69-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 69-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 71.予測数量（本）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 72.協賛金合計（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.support_amount_sum_en_5  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_sup_amt_sum
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 73.予測数量（本）が0またはマイナス値または小数桁がある場合エラー
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.prediction_qty_5_6)  <>  g_cond_tmp_chk_rec.prediction_qty_5_6  THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.prediction_qty_5_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 74.協賛金合計（円）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.support_amount_sum_en_5  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.support_amount_sum_en_5  ,2)  <>  g_cond_tmp_chk_rec.support_amount_sum_en_5 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_sup_amt_sum
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.support_amount_sum_en_5
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * ⑥対象数量予測協賛金のチェック
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_pre_spons  THEN
--
            -- 75.品目コードが未設定の場合エラー
            IF g_cond_tmp_chk_rec.item_code IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_item_code
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
            -- 76.品目コードがマスタに存在しない場合エラー -- ★★
            ELSE
              BEGIN
                SELECT  1       AS  dummy
                INTO    ln_dummy
                FROM    mtl_system_items_b  msib
                WHERE   msib.segment1         = g_cond_tmp_chk_rec.item_code
                AND     msib.organization_id  = gt_org_id
                ;
--
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cok
                               , iv_name         => cv_msg_cok_10600
                               , iv_token_name1  => cv_col_name_tok
                               , iv_token_value1 => cv_msg_item_code
                               , iv_token_name2  => cv_col_value_tok
                               , iv_token_value2 => g_cond_tmp_chk_rec.item_code
                               );
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
--
-- 2021/04/06 Ver1.1 ADD Start
              -- 76.1.品目コードが子品目の場合エラー
              SELECT COUNT(1) AS  dummy
              INTO   ln_dummy
              FROM   mtl_system_items_b  msib
                   , ic_item_mst_b       iimb
                   , xxcmn_item_mst_b    ximb
              WHERE  msib.segment1        = iimb.item_no
              AND    iimb.item_id         = ximb.item_id
              AND    msib.segment1        = g_cond_tmp_chk_rec.item_code
              AND    msib.organization_id = gt_org_id
              AND    gd_process_date BETWEEN NVL(ximb.start_date_active, gd_process_date)
                AND    NVL(ximb.end_date_active, gd_process_date)
              AND    ximb.item_id         != ximb.parent_item_id
              ;
              IF ln_dummy > 0 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10794
                              , iv_token_name1  => cv_col_name_tok
                              , iv_token_value1 => cv_msg_child_item_code
                              , iv_token_name2  => cv_col_name_2_tok
                              , iv_token_value2 => cv_msg_item_code
                              , iv_token_name3  => cv_col_value_tok
                              , iv_token_value3 => g_cond_tmp_chk_rec.item_code
                              );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
-- 2021/04/06 Ver1.1 ADD End
--
              -- 78.品目コードに紐付く、単位換算が取得できない場合エラー
              ln_dummy  :=  xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code    => g_cond_tmp_chk_rec.item_code
                              , iv_uom_code     => cv_uom_hon
                              , in_quantity     => 0
                            )
                            ;
              IF ln_dummy IS NULL THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_msg_kbn_cok
                                  , iv_name        => cv_msg_cok_10671
                                 );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
              -- 77-1.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードのデータで明細の処理区分が同一の場合
            IF    g_cond_tmp_chk_rec.item_code  IS NOT NULL
              AND g_cond_tmp_chk_rec.process_type_line = cv_process_insert THEN
--
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_temp  xct
              WHERE   xct.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xct.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xct.process_type_line    = g_cond_tmp_chk_rec.process_type_line -- 明細処理区分
              ;
--
              -- 2件以上取得した場合、品目重複エラー
              IF ln_dummy > 1 THEN
--
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
--
              -- 77-2.品目コード重複チェック：明細の処理区分が登録で、同一控除番号、同一品目コードの場合
              SELECT  COUNT(1)    AS  dummy
              INTO    ln_dummy
              FROM    xxcok_condition_lines  xcl
              WHERE   xcl.condition_no         = g_cond_tmp_chk_rec.condition_no      -- 控除番号
              AND     xcl.item_code            = g_cond_tmp_chk_rec.item_code         -- 品目コード
              AND     xcl.enabled_flag_l       = cv_const_y                           -- 有効フラグ
              ;
--
              -- 1件以上取得した場合、品目重複エラー
              IF ln_dummy >= 1 THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cok
                             , iv_name         => cv_msg_cok_10608
                             , iv_token_name1  => cv_col_name_tok
                             , iv_token_value1 => cv_msg_item_code
                             );
                ln_cnt  :=  ln_cnt + 1;
                g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END IF;
            END IF;
--
            -- 79.予測数量（本）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 80.条件単価（円）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 81.対象率(％)が未設定の場合エラー
            IF g_cond_tmp_chk_rec.target_rate_6  IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_tar_rate || cv_msg_parsent
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 82.予測数量（本）が0または小数桁がある場合エラー
            IF g_cond_tmp_chk_rec.prediction_qty_5_6  <= 0
              OR  TRUNC(g_cond_tmp_chk_rec.prediction_qty_5_6)  <>  g_cond_tmp_chk_rec.prediction_qty_5_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_prediction || cv_msg_hon
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.prediction_qty_5_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 83.条件単価（円）が0またはマイナス値の場合エラー
            IF g_cond_tmp_chk_rec.condition_unit_price_en_2_6  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.condition_unit_price_en_2_6  ,2)  <>  g_cond_tmp_chk_rec.condition_unit_price_en_2_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_u_p_en || cv_msg_yen
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.condition_unit_price_en_2_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 83.対象率(％)が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.target_rate_6  <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.target_rate_6  ,2)  <>  g_cond_tmp_chk_rec.target_rate_6 THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_tar_rate || cv_msg_parsent
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.target_rate_6
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
          -- ***************************************
          -- * ⑦定額控除のチェック
          -- ***************************************
          IF g_cond_tmp_chk_rec.condition_type  = cv_condition_type_fix_con  THEN
--
-- 2021/04/06 Ver1.1 MOD Start
--            -- 84.計上拠点が未設定の場合エラー
--            IF g_cond_tmp_chk_rec.accounting_base IS NULL THEN
            -- 84.計上顧客が未設定の場合エラー
            IF g_cond_tmp_chk_rec.accounting_customer_code IS NULL THEN
-- 2021/04/06 Ver1.1 MOD End
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
-- 2021/04/06 Ver1.1 MOD Start
--                           , iv_token_value1 => cv_msg_accounting_base
                           , iv_token_value1 => cv_msg_account_customer_code
-- 2021/04/06 Ver1.1 MOD End
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--
-- 2021/04/06 Ver1.1 MOD Start
--            -- 89.計上拠点がマスタに存在しない場合エラー
            -- 89.計上顧客がマスタに存在しない場合エラー
-- 2021/04/06 Ver1.1 MOD End
            ELSE
              BEGIN
                SELECT 1      AS  dummy
                INTO   ln_dummy
                FROM   hz_cust_accounts                  base_hzca      --顧客マスタ
-- 2021/04/06 Ver1.1 MOD Start
--                WHERE  base_hzca.account_number      = g_cond_tmp_chk_rec.accounting_base
--                AND    base_hzca.customer_class_code = cv_cust_class_base
                WHERE  base_hzca.account_number      = g_cond_tmp_chk_rec.accounting_customer_code
                AND    base_hzca.customer_class_code = cv_cust_class_cust
-- 2021/04/06 Ver1.1 MOD End
                AND    base_hzca.status              = cv_cust_accounts_status
                ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10600
                              , iv_token_name1  => cv_col_name_tok
-- 2021/04/06 Ver1.1 MOD Start
--                              , iv_token_value1 => cv_msg_accounting_base
--                              , iv_token_name2  => cv_col_value_tok
--                              , iv_token_value2 => g_cond_tmp_chk_rec.accounting_base
                              , iv_token_value1 => cv_msg_account_customer_code
                              , iv_token_name2  => cv_col_value_tok
                              , iv_token_value2 => g_cond_tmp_chk_rec.accounting_customer_code
                              );
-- 2021/04/06 Ver1.1 MOD End
                  ln_cnt  :=  ln_cnt + 1;
                  g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
              END;
            END IF;
--
            --85.控除額（本体）が未設定の場合エラー
            IF g_cond_tmp_chk_rec.deduction_amount IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_amout
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 86.控除税額が未設定の場合エラー
            IF g_cond_tmp_chk_rec.deduction_tax_amount IS NULL THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10606
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_tax
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 87.控除額（本体）が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.deduction_amount <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.deduction_amount ,2)  <>  g_cond_tmp_chk_rec.deduction_amount THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_amout
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.deduction_amount
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
            -- 87.控除税額が0またはマイナス値または小数桁が2桁を超える場合エラー
            IF g_cond_tmp_chk_rec.deduction_tax_amount <= 0 
              OR  TRUNC(g_cond_tmp_chk_rec.deduction_tax_amount ,2)  <>  g_cond_tmp_chk_rec.deduction_tax_amount THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10597
                           , iv_token_name1  => cv_col_name_tok
                           , iv_token_value1 => cv_msg_con_tax
                           , iv_token_name2  => cv_col_value_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.deduction_tax_amount
                           );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_chk_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- 税率取得
      BEGIN
        SELECT xch.tax_rate  tax_rate
        INTO   ln_tax_rate_1
        FROM   xxcok_condition_header  xch
        WHERE  xch.condition_no = g_cond_tmp_chk_rec.condition_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_tax_rate_1 := NULL;
      END;
--
      --  90.控除番号、対象区分、商品区分、税率の更新
      UPDATE  xxcok_condition_temp  xct
      SET     xct.detail_number        =   CASE WHEN xct.process_type_line = cv_process_insert THEN g_cond_tmp_chk_rec.detail_number ELSE xct.detail_number END
            , xct.product_class_code   =   CASE WHEN xct.product_class IS NOT NULL THEN lt_product_class_code ELSE NULL END
            , xct.target_category      =   CASE WHEN xct.target_category  IS NOT NULL THEN  lt_target_category  ELSE NULL END
            , xct.tax_rate             =   CASE
                                              WHEN NVL(g_cond_tmp_chk_rec.csv_process_type, cv_const_n ) IN (cv_csv_update,cv_csv_insert)
                                              AND g_cond_tmp_chk_rec.condition_type                NOT IN (cv_condition_type_ws_fix,cv_condition_type_ws_add) THEN
                                                ln_tax_rate
                                             ELSE 
                                                ln_tax_rate_1
                                           END
      WHERE   xct.ROWID                =   g_cond_tmp_chk_rec.row_id
      ;
--
      IF ( ln_cnt <> 0 ) THEN
        --  メッセージありの場合
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
    END LOOP g_cond_tmp_chk_loop;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END validity_check;
--
    /**********************************************************************************
   * Procedure Name   : up_ins_chk
   * Description      : 削除後チェック(A-8)
   ***********************************************************************************/
  PROCEDURE up_ins_chk(
    ov_errbuf         OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2)                 -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'up_ins_chk'; -- プログラム名
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
    -- ダミー値
    ln_dummy                      NUMBER;       -- ダミー値
--
    -- チェック用一時保持変数
    ln_exists_header              NUMBER;
    ln_exists_line                NUMBER;
--
    -- メッセージカウンタ
    ln_cnt                        NUMBER;
--
    -- *** ローカル・カーソル ***
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
    g_message_list_tab.DELETE;
--
    --  メッセージインデックス初期化
    ln_cnt  :=  0;
--
    <<up_ins_chk_loop>>
    FOR g_cond_tmp_rec IN g_cond_tmp_cur LOOP
      IF g_cond_tmp_rec.process_type_line  IN ( cv_process_delete) THEN
        -- 業務日付到来後に削除を行う場合
        IF ( TO_DATE(g_cond_tmp_rec.start_date_active,cv_date_format) <= gd_process_date ) THEN
          -- 控除タイプが「⑤定額協賛金」の場合
          IF  g_cond_tmp_rec.condition_type     =  cv_condition_type_spons THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10678
               , iv_token_name1  => cv_tkn_condition_type
               , iv_token_value1 => g_cond_tmp_rec.condition_type
            );
--
            ln_cnt  :=  ln_cnt + 1;

            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        CONTINUE up_ins_chk_loop;
      END IF;
--
      -- 業務日付到来後に登録を行う場合
      IF ( TO_DATE(g_cond_tmp_rec.start_date_active,cv_date_format) <= gd_process_date ) THEN
        -- 処理区分が「登録」以外、明細処理区分が「登録」、且つ控除タイプが「⑤定額協賛金」の場合
        IF  g_cond_tmp_rec.condition_type     =  cv_condition_type_spons
        AND NVL(g_cond_tmp_rec.process_type, cv_const_n )      !=  cv_process_insert
        AND NVL(g_cond_tmp_rec.process_type_line, cv_const_n )  =  cv_process_insert THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10678
             , iv_token_name1  => cv_tkn_condition_type
             , iv_token_value1 => g_cond_tmp_rec.condition_type
          );
--
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  ************************************************
      --  UPDATE対象の存在チェック（マスタ）
      --  ************************************************
      ln_exists_header  :=  0;
      ln_exists_line    :=  0;
      --  先の削除処理で消される可能性があるため、削除後にチェック
      IF ( g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n ) ) THEN
        --  ヘッダの処理区分が U or NULL の場合、控除番号が一致する有効なマスタが存在するか
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_exists_header
        FROM    xxcok_condition_header    xch
        WHERE   xch.condition_no    =   g_cond_tmp_rec.condition_no
        AND     xch.enabled_flag_h  =   cv_const_y
        ;
      END IF;
      --
      --  ⑦
      IF ( g_cond_tmp_rec.condition_type =  cv_condition_type_fix_con ) THEN
        -- 処理区分が修正またはNULL（対象外）
        IF  g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n ) THEN
--
          --  ヘッダがU or NULLの場合、有効なヘッダが存在しない
          IF  ln_exists_header = 0  THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
      --  ①or②or③or④or⑤or⑥
      IF ( g_cond_tmp_rec.condition_type IN( cv_condition_type_req ,cv_condition_type_sale ,cv_condition_type_ws_fix
                                            , cv_condition_type_ws_add, cv_condition_type_spons, cv_condition_type_pre_spons ) ) THEN
        --  ヘッダがU or NULLの場合、有効なヘッダが存在しない
        IF  ( g_cond_tmp_rec.process_type IN( cv_process_update, cv_const_n )
          AND ln_exists_header  =   0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10600
                         , iv_token_name1  => cv_col_name_tok
                         , iv_token_value1 => cv_msg_condition_no
                         , iv_token_name2  => cv_col_value_tok
                         , iv_token_value2 => g_cond_tmp_rec.condition_no
                         );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  **************************************
      --   重複チェック
      --  **************************************
--
      -- ①
      IF ( g_cond_tmp_rec.condition_type = cv_condition_type_req ) THEN
        -- 対象区分の不一致チェック
--
        IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
          --  CSV内重複(キー項目検索)
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
          AND     xct.target_category                             <>  g_cond_tmp_rec.target_category
          AND     xct.request_id                                  =   cn_request_id
          AND     xct.process_type                                =   cv_process_insert
          AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
          ;
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.condition_type = cv_condition_type_req ) THEN
        -- 対象区分の不一致チェック
--
        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
          --  マスタ重複(控除番号検索）
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_header    xch
                , xxcok_condition_lines     xcl
          WHERE   xch.condition_no       =  xcl.condition_no                   -- 控除番号
          AND     xcl.target_category   <>  g_cond_tmp_rec.target_category     -- 対象区分
          AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- 控除番号
          AND     xcl.enabled_flag_l     =  cv_const_y                         -- 有効フラグ
          AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- 明細番号
          ;
--
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10608
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
--
        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
          --  CSV側で異なる行がないかチェック
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
          AND     xct.target_category    <>  g_cond_tmp_rec.target_category
          AND     xct.request_id          =  cn_request_id
          AND     xct.process_type_line   =  cv_process_insert
          AND     xct.rowid              <>  g_cond_tmp_rec.row_id
          ;
--
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_target_cate
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
--
      -- ①、②の場合
      IF ( g_cond_tmp_rec.condition_type IN ( cv_condition_type_req, cv_condition_type_sale ) ) THEN
        --  商品区分の重複をチェック

        IF  ( g_cond_tmp_rec.product_class IS NOT NULL
              AND
              g_cond_tmp_rec.process_type_line = cv_process_insert
            )
        THEN
          IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
            --  CSV内重複(キー項目検索)
            ln_dummy  :=  0;
            SELECT  COUNT(1)      AS  cnt
            INTO    ln_dummy
            FROM    xxcok_condition_temp    xct
            WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
            AND     xct.product_class_code                          =   g_cond_tmp_rec.product_class_code
            AND     xct.request_id                                  =   cn_request_id
            AND     xct.process_type                                =   cv_process_insert
            AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
            ;
            IF ( ln_dummy <> 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10608
               , iv_token_name1  => cv_col_name_tok
               , iv_token_value1 => cv_msg_item_kbn
               );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  マスタ重複(控除番号検索）
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_header    xch
              , xxcok_condition_lines     xcl
        WHERE   xch.condition_no       =  xcl.condition_no                   -- 控除番号
        AND     xcl.product_class      =  g_cond_tmp_rec.product_class       -- 商品区分
        AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- 控除番号
        AND     xcl.enabled_flag_l     =  cv_const_y                         -- 有効フラグ
        AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- 明細番号
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10608
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  CSV側で異なる行がないかチェック
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_temp    xct
        WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
        AND     xct.product_class       =  g_cond_tmp_rec.product_class
        AND     xct.request_id          =  cn_request_id
        AND     xct.process_type_line   =  cv_process_insert
        AND     xct.rowid              <>  g_cond_tmp_rec.row_id
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10609
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      --  ①or②or③or④or⑤or⑥
      IF ( g_cond_tmp_rec.condition_type IN( cv_condition_type_req, cv_condition_type_sale, cv_condition_type_ws_fix
                                        , cv_condition_type_ws_add, cv_condition_type_spons, cv_condition_type_pre_spons ) ) THEN
        --  品目コードの重複をチェック
        IF  ( g_cond_tmp_rec.item_code IS NOT NULL
            )
        THEN
          IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
            --  CSV内重複(キー項目検索)
            ln_dummy  :=  0;
            SELECT  COUNT(1)      AS  cnt
            INTO    ln_dummy
            FROM    xxcok_condition_temp    xct
            WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
            AND     xct.item_code                                   =   g_cond_tmp_rec.item_code
            AND     xct.request_id                                  =   cn_request_id
            AND     xct.process_type                                =   cv_process_insert
            AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
            ;
--
            IF ( ln_dummy <> 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_msg_kbn_cok
               , iv_name         => cv_msg_cok_10608
               , iv_token_name1  => cv_col_name_tok
               , iv_token_value1 => cv_msg_item_code
               );
              ln_cnt  :=  ln_cnt + 1;
              g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  マスタ重複(控除番号検索）
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_header    xch
              , xxcok_condition_lines     xcl
        WHERE   xch.condition_no       =  xcl.condition_no                   -- 控除番号
        AND     xcl.item_code          =  g_cond_tmp_rec.item_code           -- 品目コード
        AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- 控除番号
        AND     xcl.enabled_flag_l     =  cv_const_y                         -- 有効フラグ
        AND     xcl.detail_number     <>  g_cond_tmp_rec.detail_number       -- 明細番号
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10608
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
        --  CSV側で異なる行がないかチェック
        ln_dummy  :=  0;
        SELECT  COUNT(1)      AS  cnt
        INTO    ln_dummy
        FROM    xxcok_condition_temp    xct
        WHERE   xct.condition_no        =  g_cond_tmp_rec.condition_no
        AND     xct.item_code           =  g_cond_tmp_rec.item_code
        AND     xct.request_id          =  cn_request_id
        AND     xct.process_type_line   =  cv_process_insert
        AND     xct.rowid              <>  g_cond_tmp_rec.row_id
        ;
--
        IF ( ln_dummy <> 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
             iv_application  => cv_msg_kbn_cok
           , iv_name         => cv_msg_cok_10609
           , iv_token_name1  => cv_col_name_tok
           , iv_token_value1 => cv_msg_target_cate
           );
          ln_cnt  :=  ln_cnt + 1;
          g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
        END IF;
      END IF;
--
      -- ⑤の場合
      IF  g_cond_tmp_rec.condition_type =  cv_condition_type_spons  THEN
        -- 定額協賛金合計の不一致チェック
        IF ( g_cond_tmp_rec.process_type = cv_process_insert ) THEN
--
          --  CSV内重複(キー項目検索)
          ln_dummy  :=  0;
          SELECT  COUNT(1)      AS  cnt
          INTO    ln_dummy
          FROM    xxcok_condition_temp    xct
          WHERE   xct.condition_no                                =   g_cond_tmp_rec.condition_no
          AND     xct.support_amount_sum_en_5                     <>  g_cond_tmp_rec.support_amount_sum_en_5
          AND     xct.request_id                                  =   cn_request_id
          AND     xct.process_type                                =   cv_process_insert
          AND     xct.rowid                                       <>  g_cond_tmp_rec.row_id
          ;
          IF ( ln_dummy <> 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_msg_kbn_cok
             , iv_name         => cv_msg_cok_10609
             , iv_token_name1  => cv_col_name_tok
             , iv_token_value1 => cv_msg_sup_amt_sum
             );
            ln_cnt  :=  ln_cnt + 1;
            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
          END IF;
        END IF;
      END IF;
      --
-- 2021/04/06 Ver1.1 DEL Start
--      IF  g_cond_tmp_rec.condition_type =  cv_condition_type_fix_con  THEN
----
--        IF ( g_cond_tmp_rec.process_type_line = cv_process_insert ) THEN
--          --  マスタ重複(控除番号検索）
--          ln_dummy  :=  0;
--          SELECT  COUNT(1)      AS  cnt
--          INTO    ln_dummy
--          FROM    xxcok_condition_header    xch
--                , xxcok_condition_lines     xcl
--          WHERE   xch.condition_no       =  xcl.condition_no                   -- 控除番号
--          AND     xcl.condition_no       =  g_cond_tmp_rec.condition_no        -- 控除番号
--          AND     xcl.enabled_flag_l     =  cv_const_y                         -- 有効フラグ
--          ;
----
--          IF ( ln_dummy <> 0 ) THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--               iv_application  => cv_msg_kbn_cok
--             , iv_name         => cv_msg_cok_10710
--             );
--            ln_cnt  :=  ln_cnt + 1;
--            g_message_list_tab( g_cond_tmp_rec.csv_no )( ln_cnt )  :=  lv_errmsg;
--          END IF;
--        END IF;
--      END IF;
-- 2021/04/06 Ver1.1 DEL End
--
      IF ( ln_cnt <> 0 ) THEN
        --  メッセージありの場合
        gv_check_result :=  'N';
        IF ( gn_message_cnt = 0 OR gn_message_cnt < ln_cnt ) THEN
          gn_message_cnt  :=  ln_cnt;
        END IF;
        gn_warn_cnt     :=  gn_warn_cnt + 1;
        ov_retcode      :=  cv_status_warn;
      END IF;
    END LOOP up_ins_chk_loop;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END up_ins_chk;
--
    /**********************************************************************************
   * Procedure Name   : ins_up_process
   * Description      : 控除マスタ登録･変更処理(A-9)
   ***********************************************************************************/
  PROCEDURE up_ins_process(
    ov_errbuf         OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2)                 -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'up_ins_process'; -- プログラム名
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
    lt_condition_id               xxcok_condition_header.condition_id%TYPE;
    lt_condition_no               xxcok_condition_header.condition_no%TYPE;
    lt_condition_line_id          xxcok_condition_lines.condition_line_id%TYPE;
    lt_uom_code                   xxcok_condition_lines.uom_code%TYPE;
    lt_compensation_en_3          xxcok_condition_lines.compensation_en_3%TYPE;
    lt_wholesale_margin_en_3      xxcok_condition_lines.wholesale_margin_en_3%TYPE;
    lt_wholesale_margin_per_3     xxcok_condition_lines.wholesale_margin_per_3%TYPE;
    lt_accrued_en_3               xxcok_condition_lines.accrued_en_3%TYPE;
    lt_just_condition_en_4        xxcok_condition_lines.just_condition_en_4%TYPE;
    lt_wholesale_adj_margin_en_4  xxcok_condition_lines.wholesale_adj_margin_en_4%TYPE;
    lt_wholesale_adj_margin_per_4 xxcok_condition_lines.wholesale_adj_margin_per_4%TYPE;
    lt_accrued_en_4               xxcok_condition_lines.accrued_en_4%TYPE;
    lt_deduction_unit_price_en_6  xxcok_condition_lines.deduction_unit_price_en_6%TYPE;
    ln_prediction_qty_sum         NUMBER;                                                     -- 予測数量合計
    lt_ratio_per                  xxcok_condition_lines.ratio_per_5%TYPE;                     -- 比率
    lt_amount_prorated_en         xxcok_condition_lines.amount_prorated_en_5%TYPE;            -- 金額按分
    lt_cond_unit_price_en         xxcok_condition_lines.condition_unit_price_en_5%TYPE;       -- 条件単価
-- 2021/04/06 Ver1.1 ADD Start
    lv_condition_no_out           VARCHAR2(1000);
    lv_agreement_no_out           VARCHAR2(1000);
    lv_data_type_out              VARCHAR2(1000);
    lv_content_out                VARCHAR2(1000);
-- 2021/04/06 Ver1.1 ADD End
--
    -- 前回処理のキー項目
    lt_prev_condition_no          xxcok_condition_temp.condition_no%TYPE;        -- 控除番号
--
    ld_start_date                 DATE;
    ld_end_date                   DATE;
--
    -- 控除番号生成用
    lt_sql_str                    VARCHAR2(100);
    lv_process_year               VARCHAR2(4);
    --
    -- *** ローカル・カーソル ***
    -- 控除マスタの取得カーソル(再計算用)
    --  今回処理で明細が、登録・更新・削除された控除番号を取得
    CURSOR target_condition_cur
    IS
      SELECT  DISTINCT  xcl.condition_no
      FROM    xxcok_condition_lines   xcl
      WHERE   xcl.request_id      =   cn_request_id
      ;
    target_condition_rec    target_condition_cur%ROWTYPE;
    --
    CURSOR get_cond_cur (lt_condition_no IN VARCHAR2)
    IS
      SELECT  xcl.ROWID                       AS  row_id
            , xcl.prediction_qty_5            AS  prediction_qty_5
            , xcl.support_amount_sum_en_5     AS  support_amount_sum_en_5
      FROM  xxcok_condition_lines   xcl
      WHERE   xcl.condition_no    = lt_condition_no
      AND     xcl.enabled_flag_l  = cv_const_y
      ORDER BY  xcl.detail_number
    ;
    get_cond_rec  get_cond_cur%ROWTYPE;
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
    -- ローカル変数初期化
    lt_condition_id       :=  NULL;
    lt_condition_no       :=  NULL;
    lt_prev_condition_no  :=  cv_space;
--
    --  年度を取得
    lv_process_year   :=  CASE  WHEN  TO_CHAR( gd_process_date, cv_date_month ) IN( cv_month_jan, cv_month_feb, cv_month_mar, cv_month_apr )
                                  THEN  TO_CHAR( TO_NUMBER( TO_CHAR( gd_process_date, cv_date_year ) ) - 1 )
                                  ELSE  TO_CHAR( gd_process_date, cv_date_year )
                          END;
--
    <<get_cond_tm_loop3>>
    FOR g_cond_tmp_chk_rec IN g_cond_tmp_chk_cur LOOP
      --
      --  CSVの開始日、終了日を型変換して保持
      ld_start_date   :=  TO_DATE(g_cond_tmp_chk_rec.start_date_active, cv_date_format);
      ld_end_date     :=  TO_DATE(g_cond_tmp_chk_rec.end_date_active, cv_date_format);
--
      --  ************************************************
      --  控除情報テーブルの変更
      --  ************************************************
      --  ヘッダ処理は同一控除番号ごとに１回のみ処理する(初回は必ず処理する)
      IF (  lt_prev_condition_no <> g_cond_tmp_chk_rec.condition_no ) THEN
        --  処理済控除番号を保持(INSERTの場合はダミー控除番号で判断されるため、新規で採番した控除番号を考慮する必要はない）
        lt_prev_condition_no :=  g_cond_tmp_chk_rec.condition_no;
        lt_condition_id   :=  g_cond_tmp_chk_rec.condition_id;
        lt_condition_no   :=  g_cond_tmp_chk_rec.condition_no;
        --
        -- 処理区分が更新の場合
        IF ( g_cond_tmp_chk_rec.process_type = cv_process_update ) THEN
          --
          --  ************************************************
          --  ヘッダの更新
          --  ************************************************
          BEGIN
            UPDATE  xxcok_condition_header xch
            SET     xch.corp_code                 =   g_cond_tmp_chk_rec.corp_code                                    --  企業コード
                  , xch.deduction_chain_code      =   g_cond_tmp_chk_rec.deduction_chain_code                         --  チェーン店コード
                  , xch.customer_code             =   g_cond_tmp_chk_rec.customer_code                                --  顧客コード
                  , xch.data_type                 =   g_cond_tmp_chk_rec.data_type                                    --  データ種類
                  , xch.tax_code                  =   g_cond_tmp_chk_rec.tax_code                                     --  税コード
                  , xch.tax_rate                  =   g_cond_tmp_chk_rec.tax_rate                                     --  税率
                  , xch.start_date_active         =   ld_start_date                                                   --  開始日
                  , xch.end_date_active           =   ld_end_date                                                     --  終了日
                  , xch.header_recovery_flag      =   g_cond_tmp_chk_rec.process_type                                 --  リカバリ対象フラグ
                  , xch.last_updated_by           =   cn_last_updated_by
                  , xch.last_update_date          =   cd_last_update_date
                  , xch.last_update_login         =   cn_last_update_login
                  , xch.request_id                =   cn_request_id
                  , xch.program_application_id    =   cn_program_application_id
                  , xch.program_id                =   cn_program_id
                  , xch.program_update_date       =   cd_program_update_date
            WHERE   xch.condition_no              =   g_cond_tmp_chk_rec.condition_no
            ;
            IF ( ld_start_date  <= gd_process_date ) THEN
              --  ヘッダが更新されたことに伴う、明細のリカバリ対象フラグを変更
              UPDATE  xxcok_condition_lines  xcl
              SET     xcl.line_recovery_flag        = CASE  WHEN  ld_start_date  <= gd_process_date
                                                        THEN  g_cond_tmp_chk_rec.process_type
                                                        ELSE  cv_const_n
                                                      END                                           --  リカバリ対象フラグ
                    , xcl.last_updated_by           =   cn_last_updated_by
                    , xcl.last_update_date          =   cd_last_update_date
                    , xcl.last_update_login         =   cn_last_update_login
                    , xcl.request_id                =   cn_request_id
                    , xcl.program_application_id    =   cn_program_application_id
                    , xcl.program_id                =   cn_program_id
                    , xcl.program_update_date       =   cd_program_update_date
              WHERE   xcl.condition_no    = g_cond_tmp_chk_rec.condition_no
              AND     xcl.enabled_flag_l  = cv_const_y
              ;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10587
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_h
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
          END;
        -- 処理区分が決裁の場合
        ELSIF ( g_cond_tmp_chk_rec.process_type = cv_process_decision ) THEN
          --
          --  ************************************************
          --  ヘッダの更新
          --  ************************************************
          BEGIN
            UPDATE  xxcok_condition_header
            SET     content                   =   g_cond_tmp_chk_rec.content                                      --  内容
                  , decision_no               =   g_cond_tmp_chk_rec.decision_no                                  --  決裁No
                  , header_recovery_flag      =   'Z'                                                             --  リカバリ対象フラグ
                  , agreement_no              =   g_cond_tmp_chk_rec.agreement_no                                 --  契約番号
                  , last_updated_by           =   cn_last_updated_by
                  , last_update_date          =   cd_last_update_date
                  , last_update_login         =   cn_last_update_login
                  , request_id                =   cn_request_id
                  , program_application_id    =   cn_program_application_id
                  , program_id                =   cn_program_id
                  , program_update_date       =   cd_program_update_date
            WHERE   condition_no              =   g_cond_tmp_chk_rec.condition_no
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10587
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_h
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
          END;
        ELSIF ( g_cond_tmp_chk_rec.process_type   = cv_process_insert ) THEN
          --  処理区分が挿入の場合
          --  ***************************************
          --  ヘッダ情報生成
          --  ***************************************
          --  lt_condition_id, lt_condition_noは控除詳細（明細）にも使用する
          --  控除条件IDの取得
          --  控除番号を発行
          SELECT  xxcok.xxcok_condition_header_s01.nextval      AS  condition_id
          INTO    lt_condition_id
          FROM    dual
          ;
          --  控除番号生成（年度ごとに異なるシーケンスを使用する）
          DECLARE
            lt_sql_str      VARCHAR2(100);
            --
            TYPE  cur_type  IS  REF CURSOR;
            condition_no_cur  cur_type;
            --
            TYPE  rec_type  IS RECORD(
              condition_no        xxcok_condition_header.condition_no%TYPE
            );
            condition_no_rec  rec_type;
          BEGIN
            lt_sql_str  :=    'SELECT XXCOK.XXCOK_CONDITION_NO_' || lv_process_year || '_S01.NEXTVAL  AS  condition_no FROM DUAL';
            OPEN  condition_no_cur FOR lt_sql_str;
            FETCH condition_no_cur INTO condition_no_rec;
            CLOSE condition_no_cur;
            --
            IF ( LENGTHB( condition_no_rec.condition_no ) > 8 ) THEN
              lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_msg_kbn_cok
                              , iv_name         => cv_msg_cok_10676
                            );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
            ELSE
              lt_condition_no               :=  lv_process_year || LPAD( condition_no_rec.condition_no, 8, '0' );
              condition_no_rec.condition_no :=  lt_condition_no;
            END IF;
            --
            --  生成した控除番号をロック
            INSERT INTO xxcok_exclusive_ctl_info(
                condition_no
              , request_id
            ) VALUES (
                lt_condition_no
              , cn_request_id
            );
          END;
          --
          --  ***************************************
          --  ヘッダの挿入
          --  ***************************************
          BEGIN
            INSERT INTO xxcok_condition_header(
                condition_id                --  控除条件ID
              , condition_no                --  控除番号
              , enabled_flag_h              --  有効フラグ
              , corp_code                   --  企業コード
              , deduction_chain_code        --  チェーン店コード
              , customer_code               --  顧客コード
              , data_type                   --  データ種類
              , tax_code                    --  税コード
              , tax_rate                    --  税率
              , start_date_active           --  開始日
              , end_date_active             --  終了日
              , content                     --  内容
              , decision_no                 --  決裁No
              , agreement_no                --  契約番号
              , header_recovery_flag        --  リカバリ対象フラグ
              , created_by                  --  作成者
              , creation_date               --  作成日
              , last_updated_by             --  最終更新者
              , last_update_date            --  最終更新日
              , last_update_login           --  最終更新ログイン
              , request_id                  --  要求ID
              , program_application_id      --  コンカレント・プログラム・アプリケーションID
              , program_id                  --  コンカレント・プログラムID
              , program_update_date         --  プログラム更新日
            )VALUES(
                lt_condition_id                                                       -- 控除条件ID
              , lt_condition_no                                                       -- 控除番号
              , cv_const_y                                                            -- 有効フラグ
              , g_cond_tmp_chk_rec.corp_code                                          -- 企業コード
              , g_cond_tmp_chk_rec.deduction_chain_code                               -- チェーン店コード
              , g_cond_tmp_chk_rec.customer_code                                      -- 顧客コード
              , g_cond_tmp_chk_rec.data_type                                          -- データ種類
              , g_cond_tmp_chk_rec.tax_code                                           -- 税コード
              , g_cond_tmp_chk_rec.tax_rate                                           -- 税率
              , ld_start_date                                                         -- 開始日
              , ld_end_date                                                           -- 終了日
              , g_cond_tmp_chk_rec.content                                            -- 内容
              , g_cond_tmp_chk_rec.decision_no                                        -- 決裁No
              , g_cond_tmp_chk_rec.agreement_no                                       -- 契約番号
              , g_cond_tmp_chk_rec.process_type                                       -- リカバリ対象フラグ
              , cn_created_by                                                         -- 作成者
              , cd_creation_date                                                      -- 作成日
              , cn_last_updated_by                                                    -- 最終更新者
              , cd_last_update_date                                                   -- 最終更新日
              , cn_last_update_login                                                  -- 最終更新ログイン
              , cn_request_id                                                         -- 要求ID
              , cn_program_application_id                                             -- コンカレント・プログラム・アプリケーションID
              , cn_program_id                                                         -- コンカレント・プログラムID
              , cd_program_update_date                                                -- プログラム更新日
            )
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- エラーメッセージの取得
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cok
                           , iv_name         => cv_msg_cok_10586
                           , iv_token_name1  => cv_table_name_tok
                           , iv_token_value1 => cv_msg_condition_h
                           , iv_token_name2  => cv_key_data_tok
                           , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                           );
              lv_errbuf :=  lv_errmsg;
              RAISE global_process_expt;
          END;
-- 2021/04/06 Ver1.1 ADD Start
-- ヘッダに挿入する場合「控除番号」「契約番号」「データ種類」「内容」を出力する
          --控除番号
          lv_condition_no_out  := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_condition_no
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => lt_condition_no
                                  );
          --契約番号
          lv_agreement_no_out  := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_agreement_no
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.agreement_no
                                  );
          --データ種類
          lv_data_type_out     := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_data_type
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.data_type
                                  );
          --内容
          lv_content_out       := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_msg_kbn_cok
                                  , iv_name         => cv_msg_cok_10795
                                  , iv_token_name1  => cv_col_name_tok
                                  , iv_token_value1 => cv_msg_content
                                  , iv_token_name2  => cv_col_value_tok
                                  , iv_token_value2 => g_cond_tmp_chk_rec.content
                                  );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
          , buff   => ''                   || CHR(10) ||
                      lv_condition_no_out  || CHR(10) ||
                      lv_agreement_no_out  || CHR(10) ||
                      lv_data_type_out     || CHR(10) ||
                      lv_content_out       || CHR(10)
          );
-- 2021/04/06 Ver1.1 ADD End
        END IF;
      END IF;
--
      --  ************************************************
      --  控除詳細テーブルの変更
      --  ************************************************
      --  ************************************************
      --  控除詳細テーブルの設定値計算
      --  ************************************************
      --  単位：控除タイプ「030(問屋未収（定額）)」「040(問屋未収（追加）)」の場合はCSVの値を使用
      --        上記以外の場合は「本」固定
      lt_uom_code :=  CASE  WHEN  g_cond_tmp_chk_rec.condition_type IN( cv_condition_type_ws_fix, cv_condition_type_ws_add )
                        THEN  g_cond_tmp_chk_rec.uom_code
                        ELSE  cv_uom_hon
                      END;
      --  控除タイプ「030(問屋未収（定額）)」の場合、補填(円)、問屋マージン(円)、問屋マージン(％)、未収計３(円)を計算
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_ws_fix ) THEN
        lt_compensation_en_3            :=  g_cond_tmp_chk_rec.demand_en_3 - g_cond_tmp_chk_rec.shop_pay_en_3;
        lt_wholesale_margin_en_3        :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_margin_en_3 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_margin_en_3
                                              ELSE  g_cond_tmp_chk_rec.shop_pay_en_3 * (g_cond_tmp_chk_rec.wholesale_margin_per_3 / cn_100)
                                            END;
        lt_wholesale_margin_per_3       :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_margin_per_3 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_margin_per_3
                                              ELSE (g_cond_tmp_chk_rec.wholesale_margin_en_3 / g_cond_tmp_chk_rec.shop_pay_en_3) * cn_100
                                            END;
        lt_accrued_en_3                 :=  lt_compensation_en_3 + lt_wholesale_margin_en_3;
        --  すべて計算後に四捨五入
        lt_compensation_en_3            :=  ROUND( lt_compensation_en_3, 2 );
        lt_wholesale_margin_en_3        :=  ROUND( lt_wholesale_margin_en_3, 2 );
        lt_wholesale_margin_per_3       :=  ROUND( lt_wholesale_margin_per_3, 2 );
        lt_accrued_en_3                 :=  ROUND( lt_accrued_en_3, 2 );
      ELSE
        lt_compensation_en_3            :=  NULL;
        lt_wholesale_margin_en_3        :=  NULL;
        lt_wholesale_margin_per_3       :=  NULL;
        lt_accrued_en_3                 :=  NULL;
      END IF;
      --  控除タイプ「040(問屋未収（追加）)」の場合、今回条件(円)、問屋マージン修正(円)、問屋マージン修正(％)、未収計４(円)を計算
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_ws_add ) THEN
        lt_just_condition_en_4          :=  g_cond_tmp_chk_rec.normal_shop_pay_en_4 - g_cond_tmp_chk_rec.just_shop_pay_en_4;
        lt_wholesale_adj_margin_en_4    :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_adj_margin_en_4 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
                                              ELSE  ( lt_just_condition_en_4 * (g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 / cn_100))
                                            END;
        lt_wholesale_adj_margin_per_4   :=  CASE  WHEN g_cond_tmp_chk_rec.wholesale_adj_margin_per_4 IS NOT NULL
                                              THEN  g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
                                              ELSE  ( ( lt_wholesale_adj_margin_en_4 ) / lt_just_condition_en_4) * cn_100
                                            END;
        lt_accrued_en_4                 :=  lt_just_condition_en_4 - lt_wholesale_adj_margin_en_4;
        --  すべて計算後に四捨五入
        lt_just_condition_en_4          :=  ROUND( lt_just_condition_en_4, 2 );
        lt_wholesale_adj_margin_en_4    :=  ROUND( lt_wholesale_adj_margin_en_4, 2 );
        lt_wholesale_adj_margin_per_4   :=  ROUND( lt_wholesale_adj_margin_per_4, 2 );
        lt_accrued_en_4                 :=  ROUND( lt_accrued_en_4, 2 );
      ELSE
        lt_just_condition_en_4          :=  NULL;
        lt_wholesale_adj_margin_en_4    :=  NULL;
        lt_wholesale_adj_margin_per_4   :=  NULL;
        lt_accrued_en_4                 :=  NULL;
      END IF;
      --  控除タイプ「060(対象数量予測協賛金)」の場合、控除単価(円)を計算
      IF ( g_cond_tmp_chk_rec.condition_type = cv_condition_type_pre_spons ) THEN
        lt_deduction_unit_price_en_6    :=  ROUND(g_cond_tmp_chk_rec.condition_unit_price_en_2_6 * (g_cond_tmp_chk_rec.target_rate_6 / cn_100), 2);
      ELSE
        lt_deduction_unit_price_en_6    :=  NULL;
      END IF;
      --
      IF ( g_cond_tmp_chk_rec.process_type_line = cv_process_insert ) THEN
        --  控除詳細ID取得
        SELECT  xxcok.xxcok_condition_lines_s01.nextval     AS  condition_line_id
        INTO    lt_condition_line_id
        FROM    dual
        ;
        --
        --  ************************************************
        --  明細の挿入
        --  ************************************************
        BEGIN
          INSERT INTO xxcok_condition_lines(
              CONDITION_LINE_ID
            , CONDITION_ID
            , CONDITION_NO
            , DETAIL_NUMBER
            , ENABLED_FLAG_L
            , TARGET_CATEGORY
            , PRODUCT_CLASS
            , ITEM_CODE
            , UOM_CODE
            , LINE_RECOVERY_FLAG
            , SHOP_PAY_1
            , MATERIAL_RATE_1
            , CONDITION_UNIT_PRICE_EN_2
            , DEMAND_EN_3
            , SHOP_PAY_EN_3
            , COMPENSATION_EN_3
            , WHOLESALE_MARGIN_EN_3
            , WHOLESALE_MARGIN_PER_3
            , ACCRUED_EN_3
            , NORMAL_SHOP_PAY_EN_4
            , JUST_SHOP_PAY_EN_4
            , JUST_CONDITION_EN_4
            , WHOLESALE_ADJ_MARGIN_EN_4
            , WHOLESALE_ADJ_MARGIN_PER_4
            , ACCRUED_EN_4
            , PREDICTION_QTY_5
            , RATIO_PER_5
            , AMOUNT_PRORATED_EN_5
            , CONDITION_UNIT_PRICE_EN_5
            , SUPPORT_AMOUNT_SUM_EN_5
            , PREDICTION_QTY_6
            , CONDITION_UNIT_PRICE_EN_6
            , TARGET_RATE_6
            , DEDUCTION_UNIT_PRICE_EN_6
-- 2021/04/06 Ver1.1 MOD Start
--            , ACCOUNTING_BASE
            , ACCOUNTING_CUSTOMER_CODE
-- 2021/04/06 Ver1.1 MOD End
            , DEDUCTION_AMOUNT
            , DEDUCTION_TAX_AMOUNT
            , DL_WHOLESALE_MARGIN_EN
            , DL_WHOLESALE_MARGIN_PER
            , DL_WHOLESALE_ADJ_MARGIN_EN
            , DL_WHOLESALE_ADJ_MARGIN_PER
            , CREATED_BY
            , CREATION_DATE
            , LAST_UPDATED_BY
            , LAST_UPDATE_DATE
            , LAST_UPDATE_LOGIN
            , REQUEST_ID
            , PROGRAM_APPLICATION_ID
            , PROGRAM_ID
            , PROGRAM_UPDATE_DATE
          )VALUES(
              lt_condition_line_id
            , lt_condition_id
            , lt_condition_no
            , g_cond_tmp_chk_rec.detail_number
            , cv_const_y
            , g_cond_tmp_chk_rec.target_category
            , g_cond_tmp_chk_rec.product_class_code
            , g_cond_tmp_chk_rec.item_code
            , lt_uom_code
            , g_cond_tmp_chk_rec.process_type_line
            , g_cond_tmp_chk_rec.shop_pay_1
            , g_cond_tmp_chk_rec.material_rate_1
            , g_cond_tmp_chk_rec.condition_unit_price_en_2_6
            , g_cond_tmp_chk_rec.demand_en_3
            , g_cond_tmp_chk_rec.shop_pay_en_3
            , lt_compensation_en_3
            , lt_wholesale_margin_en_3
            , lt_wholesale_margin_per_3
            , lt_accrued_en_3
            , g_cond_tmp_chk_rec.normal_shop_pay_en_4
            , g_cond_tmp_chk_rec.just_shop_pay_en_4
            , lt_just_condition_en_4
            , lt_wholesale_adj_margin_en_4
            , lt_wholesale_adj_margin_per_4
            , lt_accrued_en_4
            , g_cond_tmp_chk_rec.prediction_qty_5_6
            , NULL
            , NULL
            , NULL
            , g_cond_tmp_chk_rec.support_amount_sum_en_5
            , g_cond_tmp_chk_rec.prediction_qty_5_6
            , g_cond_tmp_chk_rec.condition_unit_price_en_2_6
            , g_cond_tmp_chk_rec.target_rate_6
            , lt_deduction_unit_price_en_6
-- 2021/04/06 Ver1.1 MOD Start
--            , g_cond_tmp_chk_rec.accounting_base
            , g_cond_tmp_chk_rec.accounting_customer_code
-- 2021/04/06 Ver1.1 MOD End
            , g_cond_tmp_chk_rec.deduction_amount
            , g_cond_tmp_chk_rec.deduction_tax_amount
            , g_cond_tmp_chk_rec.wholesale_margin_en_3
            , g_cond_tmp_chk_rec.wholesale_margin_per_3
            , g_cond_tmp_chk_rec.wholesale_adj_margin_en_4
            , g_cond_tmp_chk_rec.wholesale_adj_margin_per_4
            , cn_created_by
            , cd_creation_date
            , cn_last_updated_by
            , cd_last_update_date
            , cn_last_update_login
            , cn_request_id
            , cn_program_application_id
            , cn_program_id
            , cd_program_update_date
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- エラーメッセージの取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cok
                         , iv_name         => cv_msg_cok_10586
                         , iv_token_name1  => cv_table_name_tok
                         , iv_token_value1 => cv_msg_condition_l
                         , iv_token_name2  => cv_key_data_tok
                         , iv_token_value2 => g_cond_tmp_chk_rec.csv_no || cv_msg_csv_line
                         );
            lv_errbuf :=  lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ヘッダ情報のWHOカラムを更新
        UPDATE  xxcok_condition_header xch
        SET     xch.last_updated_by           =   cn_last_updated_by
              , xch.last_update_date          =   cd_last_update_date
              , xch.last_update_login         =   cn_last_update_login
              , xch.request_id                =   cn_request_id
              , xch.program_application_id    =   cn_program_application_id
              , xch.program_id                =   cn_program_id
              , xch.program_update_date       =   cd_program_update_date
        WHERE   xch.condition_no       = lt_condition_no
        ;
      END IF;
      --
    END LOOP  get_cond_tm_loop3;
    --
    --  ******************************************************
    --  控除タイプ「050(定額協賛金)」の再計算
    --  ******************************************************
    --  比率（％）、金額按分（円）、条件単価（％）を再計算を控除番号ごとに再計算
    <<upd_005_loop>>
    FOR target_condition_rec IN target_condition_cur LOOP
      BEGIN
        SELECT  SUM(prediction_qty_5)     AS  prediction_qty_sum     -- 予測数量合計
        INTO    ln_prediction_qty_sum
        FROM    xxcok_condition_lines   xcl
        WHERE   xcl.condition_no    =   target_condition_rec.condition_no
        AND     xcl.enabled_flag_l  =   cv_const_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --  全明細削除の場合のみNO_DATA_FOUNDになる
          CONTINUE  upd_005_loop;
      END;
      --
      <<get_cond_tm_loop4>>
      FOR get_cond_rec IN get_cond_cur(target_condition_rec.condition_no) LOOP
        -- 再計算処理
        lt_ratio_per  :=  (get_cond_rec.prediction_qty_5 / ln_prediction_qty_sum) * cn_100;    -- 比率（％）
        lt_amount_prorated_en :=  get_cond_rec.support_amount_sum_en_5 *  (lt_ratio_per / cn_100);     -- 金額按分（円）
        lt_cond_unit_price_en :=  lt_amount_prorated_en / get_cond_rec.prediction_qty_5;    -- 条件単価（円）
--
        -- 再計算した値で更新
        UPDATE  xxcok_condition_lines xcl
        SET     xcl.ratio_per_5               = ROUND(lt_ratio_per, 2)
              , xcl.amount_prorated_en_5      = ROUND(lt_amount_prorated_en, 2)
              , xcl.condition_unit_price_en_5 = ROUND(lt_cond_unit_price_en, 2)
        WHERE   xcl.ROWID   =   get_cond_rec.row_id
        ;
      END LOOP get_cond_tm_loop4;
--
    END LOOP upd_005_loop;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END up_ins_process;
--
    /**********************************************************************************
   * Procedure Name   : condition_data
   * Description      : 控除マスタ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_process(
    ov_errbuf         OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2                  -- リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2)                 -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_process'; -- プログラム名
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
    lv_condition_no               VARCHAR2(10);
    ln_counter                    NUMBER;
    ln_max_index                  NUMBER;
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
    -- ローカル変数初期化
    lv_condition_no      :=  cv_space;
    ln_counter           :=  0;
    ln_max_index         :=  0;
--
    --  ************************************************
    --  控除マスタ削除処理
    --  ************************************************
--
    --  明細削除    TEMPで明細削除となっている控除番号、明細番号と一致する控除明細を全て無効化
    --      または、TEMPでヘッダ削除となっている控除番号と一致する控除明細を全て無効化
    UPDATE  xxcok_condition_lines     xcl
    SET     xcl.enabled_flag_l          =   cv_const_n
          , xcl.line_recovery_flag      =   cv_process_delete
          , xcl.last_updated_by         =   fnd_global.user_id
          , xcl.last_update_date        =   cd_last_update_date
          , xcl.last_update_login       =   cn_last_update_login
          , xcl.request_id              =   cn_request_id
          , xcl.program_application_id  =   cn_program_application_id
          , xcl.program_id              =   cn_program_id
          , xcl.program_update_date     =   cd_program_update_date
    WHERE ( EXISTS( SELECT  1     AS  dummy
                    FROM    xxcok_condition_temp    xct
                    WHERE   xct.condition_no        =   xcl.condition_no
                    AND     xct.detail_number       =   xcl.detail_number
                    AND     xct.request_id          =   cn_request_id
                    AND     xct.process_type_line   =   cv_process_delete
            )
          )
    ;
--
    --
    UPDATE  xxcok_condition_header    xch
    SET     xch.last_updated_by         =   fnd_global.user_id
          , xch.last_update_date        =   cd_last_update_date
          , xch.last_update_login       =   cn_last_update_login
          , xch.request_id              =   cn_request_id
          , xch.program_application_id  =   cn_program_application_id
          , xch.program_id              =   cn_program_id
          , xch.program_update_date     =   cd_program_update_date
    WHERE  EXISTS( SELECT  1     AS  dummy
                   FROM    xxcok_condition_lines    xcl
                          ,xxcok_condition_temp     xct
                   WHERE   xct.condition_no        =   xcl.condition_no
                   AND     xct.detail_number       =   xcl.detail_number
                   AND     xcl.condition_no        =   xch.condition_no
                   AND     xct.process_type_line   =   cv_process_delete
                  )
    ;
--
    --  ヘッダ削除  TEMPでヘッダ削除となっている控除番号と一致する控除ヘッダを全て無効化
    UPDATE  xxcok_condition_header    xch
    SET     xch.enabled_flag_h          =   cv_const_n
          , xch.header_recovery_flag    =   cv_process_delete
          , xch.last_updated_by         =   fnd_global.user_id
          , xch.last_update_date        =   cd_last_update_date
          , xch.last_update_login       =   cn_last_update_login
          , xch.request_id              =   cn_request_id
          , xch.program_application_id  =   cn_program_application_id
          , xch.program_id              =   cn_program_id
          , xch.program_update_date     =   cd_program_update_date
    WHERE  EXISTS( SELECT  1     AS  dummy
                   FROM    xxcok_condition_temp     xct
                   WHERE   xct.condition_no  =  xch.condition_no
                   AND     NOT EXISTS( SELECT  1     AS  dummy
                                       FROM    xxcok_condition_lines    xcl
                                       WHERE   xcl.condition_no   =   xct.condition_no
                                       AND     xcl.enabled_flag_l =   cv_const_y
                                       )
                   )
    ;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_process;
--
    /**********************************************************************************
   * Procedure Name   : condition_recovery
   * Description      : 控除データリカバリコンカレント発行処理(A-10)
   ***********************************************************************************/
  PROCEDURE condition_recovery(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode  OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'condition_recovery'; -- プログラム名
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
    cv_recover_name     CONSTANT VARCHAR2(30) := '控除データリカバリコンカレント';
--
    -- *** ローカル変数 ***
    lv_out_msg      VARCHAR2(1000);
    ln_request_id   NUMBER;
    lb_retcode      BOOLEAN;
--
    -- *** ローカル・カーソル ***
--
    submit_conc_expt EXCEPTION;
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
    -- ローカル変数初期化
    lb_retcode := false;
--
    -- 「控除データリカバリ」コンカレント発行
    ln_request_id := fnd_request.submit_request(
      application   => cv_msg_kbn_cok
     ,program       => cv_data_rec_conc -- 控除データリカバリ指定
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => cn_request_id    -- 要求ID
    );
    -- 正常以外の場合
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- コンカレント発行を確定させるためコミット
    COMMIT;
--
    -- コンカレント発行メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10677
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => ln_request_id
                    )
    );
    -- コンカレント発行メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10677
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => ln_request_id
                    )
    );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- コンカレント発行例外ハンドラ
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cok
                    ,iv_name         => cv_msg_cok_10615
                    ,iv_token_name1  => cv_pg_name_tok
                    ,iv_token_value1 => cv_recover_name
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- メッセージ
                      ,in_new_line   => cn_one           -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END condition_recovery;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER     --   ファイルID
   ,iv_file_format  IN   VARCHAR2   --   ファイルフォーマット
   ,ov_errbuf       OUT  VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT  VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT  VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    gn_chk_cnt           := 0; 
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_error_cnt         := 0; -- エラー件数
    gn_warn_cnt          := 0; -- スキップ件数
    gn_skip_cnt          := 0; -- スキップ件数
    gn_message_cnt       := 0; -- 最大メッセージ数
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
        in_file_id        =>  in_file_id          --  ファイルID
      , iv_file_format    =>  iv_file_format      --  ファイルフォーマット
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．IFデータ取得
    -- ============================================
    get_if_data(
        in_file_id        =>  in_file_id          --  ファイルID
      , iv_file_format    =>  iv_file_format      --  ファイルフォーマット
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．IFデータ削除
    -- ============================================
    delete_if_data(
        in_file_id        =>  in_file_id          --  ファイルID
      , ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．アップロードファイル項目分割(TMPテーブル作成)
    -- ============================================
    <<file_if_loop>>
    --１行目はカラム行の為、２行目から処理する
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      divide_item(
          in_file_if_loop_cnt =>  ln_file_if_loop_cnt   --  I/Fループカウンタ
        , ov_errbuf           =>  lv_errbuf             --  エラー・メッセージ           --# 固定 #
        , ov_retcode          =>  lv_retcode            --  リターン・コード             --# 固定 #
        , ov_errmsg           =>  lv_errmsg             --  ユーザー・エラー・メッセージ --# 固定 #
      );
    END LOOP file_if_loop;
--
-- 2021/04/06 Ver1.1 MOD Start
    IF gn_warn_cnt > 0 THEN
      RAISE global_api_warn_expt;
    END IF;
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      RAISE global_process_expt;
--    END IF;
-- 2021/04/06 Ver1.1 MOD End
--
    -- ============================================
    -- A-5．控除マスタ排他制御処理
    -- ============================================
    exclusive_check(
        ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6．妥当性チェック
    -- ============================================
    validity_check(
        ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
      , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
      , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  (lv_retcode = cv_status_warn)  THEN
      ov_retcode := lv_retcode;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7.控除マスタ削除
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      delete_process(
          ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================
    --  A-8.削除後チェック
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      up_ins_chk(
          ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
    END IF;
--
    IF (lv_retcode = cv_status_warn) THEN
      ROLLBACK;
--
      DELETE FROM xxcok_exclusive_ctl_info xeci
      WHERE  xeci.request_id = cn_request_id
      ;
--
      COMMIT;
      ov_retcode := lv_retcode;
    ELSIF lv_retcode <> cv_status_normal THEN
      ROLLBACK;
--
      DELETE FROM xxcok_exclusive_ctl_info xeci
      WHERE  xeci.request_id = cn_request_id
      ;
--
      COMMIT;
--
      RAISE global_process_expt;
    END IF;
    -- ============================================
    --  A-9.控除マスタ登録・更新処理
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      up_ins_process(
          ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF lv_retcode <> cv_status_normal THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================
    -- A-10．控除データリカバリコンカレント発行処理
    -- ============================================
    IF ( gv_check_result = 'Y' ) THEN
      COMMIT;   --  控除マスタの変更を確定
      --
      condition_recovery(
          ov_errbuf         =>  lv_errbuf           --  エラー・メッセージ           --# 固定 #
        , ov_retcode        =>  lv_retcode          --  リターン・コード             --# 固定 #
        , ov_errmsg         =>  lv_errmsg           --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF lv_retcode <> cv_status_normal THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- ============================================
    -- チェック結果のメッセージ出力
    -- ============================================
    IF ( gv_check_result = 'N' ) THEN
      --  チェックエラーが発生している場合、メッセージを出力して、ROLLBACK
      FOR cnv_no IN 2 .. gt_file_line_data_tab.COUNT LOOP
        --  該当CSV行番号にメッセージが設定されている場合
        IF ( g_message_list_tab.EXISTS( cnv_no ) ) THEN
          --  メッセージヘッダー  控除マスタCSV特定情報
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cok
                        , iv_name         => cv_msg_cok_10596
                        , iv_token_name1  => cv_line_num_tok
                        , iv_token_value1 => TO_CHAR(cnv_no)
                       )
          );
          FOR column_no IN 1 .. gn_message_cnt LOOP
            IF ( g_message_list_tab( cnv_no ).EXISTS( column_no ) ) THEN
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => g_message_list_tab( cnv_no )( column_no )
              );
            END IF;
          END LOOP;
        END IF;
      END LOOP;
      --
      ROLLBACK;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( g_cond_tmp_cur%ISOPEN ) THEN
        CLOSE g_cond_tmp_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( g_cond_tmp_cur%ISOPEN ) THEN
        CLOSE g_cond_tmp_cur;
      END IF;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2 --   エラーメッセージ #固定#
   ,retcode          OUT   VARCHAR2 --   エラーコード     #固定#
   ,iv_file_id       IN    VARCHAR2 --   1.ファイルID(必須)
   ,iv_file_format   IN    VARCHAR2 --   2.ファイルフォーマット(必須)
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg   CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg  CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg    CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg     CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_const_normal_msg CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg         CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg        CONSTANT VARCHAR2(100)  :=  'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token        CONSTANT VARCHAR2(10)   :=  'COUNT';            -- 件数メッセージ用トークン名
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
      ov_retcode  =>  lv_retcode
     ,ov_errbuf   =>  lv_errbuf
     ,ov_errmsg   =>  lv_errmsg
     ,iv_which    =>  cv_file_type_out
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
       TO_NUMBER(iv_file_id)  -- 1.ファイルID
      ,iv_file_format         -- 2.ファイルフォーマット
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (  lv_retcode = cv_status_normal
       OR lv_retcode = cv_status_warn 
       OR lv_retcode = cv_status_error ) THEN
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 正常終了以外の場合、ロールバックを発行
      ROLLBACK;
    END IF;
--
    -- 共通のログメッセージの出力
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    -- 想定内エラーの場合
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt  - gn_skip_cnt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      gn_normal_cnt := 0; -- 成功件数
    -- 想定外エラーの場合
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 1; -- エラー件数
      gn_warn_cnt   := 0; -- 警告件数
      gn_normal_cnt := 0; -- スキップ件数
    END IF;
--
    -- ===============================================================
    -- 共通のログメッセージの出力
    -- ===============================================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_00001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --終了メッセージの設定、出力
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_const_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOK024A01C;
/
