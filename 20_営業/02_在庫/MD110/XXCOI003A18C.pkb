CREATE OR REPLACE PACKAGE BODY APPS.XXCOI003A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI003A18C(body)
 * Description      : 拠点間倉替CSVアップロード
 * MD.050           : 拠点間倉替CSVアップロード MD050_COI_003_A18
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                              (A-1)
 *  get_if_data                  IFデータ取得                          (A-2)
 *  divide_item                  アップロードファイル項目分割          (A-3)
 *  validate_item                妥当性チェック＆項目値導出            (A-4)
 *  ins_hht_inv_tran             HHT入出庫一時表登録                   (A-5)
 *  ins_lot_trx_temp             ロット別取引TEMP登録                  (A-6)
 *  delete_if_data               IFデータ削除                          (A-7)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/06/24    1.0   S.Yamashita      新規作成
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
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI003A18C'; -- パッケージ名
--
  cv_csv_delimiter      CONSTANT VARCHAR2(1) := ',';        -- カンマ
  cv_const_y            CONSTANT VARCHAR2(1) := 'Y';        -- 'Y'
  cv_const_n            CONSTANT VARCHAR2(1) := 'N';        -- 'N'
  cv_const_a            CONSTANT VARCHAR2(1) := 'A';        -- 顧客ステータス：'A'（有効）
  cv_const_e            CONSTANT VARCHAR2(1) := 'E';        -- 保管場所変換区分：'E'（預け先拠点）
  cv_const_d            CONSTANT VARCHAR2(1) := 'D';        -- 保管場所変換区分：'D'（他拠点）
  cv_status_0           CONSTANT VARCHAR2(1) := '0';        -- 処理ステータス：'0'（未処理）
  cv_kuragae_div_1      CONSTANT VARCHAR2(1) := '1';        -- 倉替対象可否区分：'1'（倉替可）
  cv_sales_class_1      CONSTANT VARCHAR2(1) := '1';        -- 売上対象区分：'1'（対象）
  cv_subinv_kbn_1       CONSTANT VARCHAR2(1) := '1';        -- 保管場所区分：'1'（倉庫）
  cv_subinv_kbn_4       CONSTANT VARCHAR2(1) := '4';        -- 保管場所区分：'4'（専門店）
  cv_cust_class_code_1  CONSTANT VARCHAR2(1) := '1';        -- 顧客区分：'1'（拠点）
  cv_cust_class_code_10 CONSTANT VARCHAR2(2) := '10';       -- 顧客区分：'10'（顧客）
  cv_cust_status_30     CONSTANT VARCHAR2(2) := '30';       -- 顧客ステータス：'30'（承認済）
  cv_cust_status_40     CONSTANT VARCHAR2(2) := '40';       -- 顧客ステータス：'40'（顧客）
  cv_cust_status_50     CONSTANT VARCHAR2(2) := '50';       -- 顧客ステータス：'50'（休止）
  cv_cust_low_type_21   CONSTANT VARCHAR2(2) := '21';       -- 業態小分類：'21'（インショップ）
  cv_cust_low_type_22   CONSTANT VARCHAR2(2) := '22';       -- 業態小分類：'22'（当社直営）
  cv_dept_hht_div_1     CONSTANT VARCHAR2(1) := '1';        -- 百貨店HHT区分：'1'（百貨店）
  cv_dept_hht_div_2     CONSTANT VARCHAR2(1) := '2';        -- 百貨店HHT区分：'2'（拠点単）
  cv_flag_normal_0      CONSTANT VARCHAR2(1) := '0';        -- エラーフラグ：'0'（正常）
  cv_flag_err_1         CONSTANT VARCHAR2(1) := '1';        -- エラーフラグ：'1'（エラー）
  cv_record_type_30     CONSTANT VARCHAR2(2) := '30';       -- レコード種別：'30'（入出庫）
  cv_invoice_type_9     CONSTANT VARCHAR2(1) := '9';        -- 伝票区分：'9'（他拠点へ出庫）
  cv_invoice_type_4     CONSTANT VARCHAR2(1) := '4';        -- 伝票区分：'4'（倉庫から預け先へ）
  cv_invoice_type_5     CONSTANT VARCHAR2(1) := '5';        -- 伝票区分：'5'（預け先から倉庫へ）
  cv_base_deliv_flag_0  CONSTANT VARCHAR2(1) := '0';        -- 拠点間倉替フラグ：'0'
  cv_department_flag_99 CONSTANT VARCHAR2(2) := '99';       -- 百貨店フラグ：'99'（ダミー）
  cv_department_flag_5  CONSTANT VARCHAR2(1) := '5';        -- 百貨店フラグ：'5'（他拠点→預け先）
  cv_department_flag_6  CONSTANT VARCHAR2(1) := '6';        -- 百貨店フラグ：'6'（預け先→他拠点）
  cv_tran_type_code_20  CONSTANT VARCHAR2(2) := '20';       -- 取引タイプコード：20（倉替）
  cv_inout_code_22      CONSTANT VARCHAR2(2) := '22';       -- 入出庫コード：22（倉替出庫）
  cv_invoice_num_0      CONSTANT VARCHAR2(8) := '00000000'; -- 伝票番号0埋め用
  cv_status_inactive    CONSTANT VARCHAR2(8) := 'Inactive'; -- 品目ステータス：Inactive
--
  cn_unit_price         CONSTANT NUMBER  := 0;      -- 単価:0
--
  cn_c_base_code        CONSTANT NUMBER  := 1;      -- 拠点コード
  cn_c_invoice_date     CONSTANT NUMBER  := 2;      -- 伝票日付
  cn_c_outside_code     CONSTANT NUMBER  := 3;      -- 出庫側コード
  cn_c_inside_code      CONSTANT NUMBER  := 4;      -- 入庫側コード
  cn_c_employee_num     CONSTANT NUMBER  := 5;      -- 営業員コード
  cn_c_item_code        CONSTANT NUMBER  := 6;      -- 品目コード
  cn_c_case_quantity    CONSTANT NUMBER  := 7;      -- ケース数
  cn_c_quantity         CONSTANT NUMBER  := 8;      -- 本数
  cn_c_header_all       CONSTANT NUMBER  := 8;      -- CSVファイル項目数
--
  -- 出力タイプ
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';--出力(ユーザメッセージ用出力先)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';   --ログ(システム管理者用出力先)
--
  -- 書式マスク
  cv_date_format_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
  cv_date_format_ym     CONSTANT VARCHAR2(6)   := 'YYYYMM';      -- 日付書式
--
  -- アプリケーション短縮名
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; --アドオン：在庫領域
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; --アドオン：販売領域
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; --共通のメッセージ
--
  -- プロファイル
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コード
--
  -- 参照タイプ
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ'; -- ファイルアップロードオブジェクト
--
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- メッセージ名
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- 在庫組織コード取得エラーメッセージ
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- 在庫組織ID取得エラーメッセージ
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';  -- 業務日付取得エラーメッセージ
  cv_msg_coi_00026      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00026';  -- 在庫会計期間ステータス取得エラーメッセージ
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- ファイル名出力メッセージ
  cv_msg_coi_10042      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10042';  -- 伝票日付未来日メッセージ
  cv_msg_coi_10092      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10092';  -- 所属拠点取得エラーメッセージ
  cv_msg_coi_10142      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10142';  -- ファイルアップロードIFテーブルロックエラーメッセージ
  cv_msg_coi_10214      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10214';  -- 管轄拠点取得エラー
  cv_msg_coi_10215      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10215';  -- 管轄拠点未設定エラー
  cv_msg_coi_10216      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10216';  -- 顧客ステータスエラー
  cv_msg_coi_10227      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10227';  -- 品目存在チェックエラーメッセージ
  cv_msg_coi_10228      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10228';  -- 品目ステータス有効チェックエラーメッセージ
  cv_msg_coi_10229      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10229';  -- 品目売上対象区分有効チェックエラーメッセージ
  cv_msg_coi_10230      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10230';  -- 基準単位有効チェックエラーメッセージ
  cv_msg_coi_10231      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10231';  -- 在庫会計期間チェックエラーメッセージ
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';  -- コンカレント入力パラメータ
  cv_msg_coi_10267      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10267';  -- 数量整合性エラーメッセージ
  cv_msg_coi_10271      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10271';  -- 所属拠点取得エラーメッセージ
  cv_msg_coi_10272      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10272';  -- 顧客追加情報取得エラーメッセージ
  cv_msg_coi_10318      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10318';  -- 基準単位存在チェックエラーメッセージ
  cv_msg_coi_10420      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10420';  -- 出庫側AFF部門エラーメッセージ
  cv_msg_coi_10421      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10421';  -- 入庫側AFF部門エラーメッセージ
  cv_msg_coi_10426      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10426';  -- 総数量エラーメッセージ
  cv_msg_coi_10508      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10508';  -- 出庫側倉庫管理対象区分取得エラー
  cv_msg_coi_10510      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10510';  -- ロット別取引TEMP作成エラー
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';  -- ファイルアップロード名称出力メッセージ
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';  -- データ削除エラーメッセージ
  cv_msg_coi_10635      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10635';  -- データ抽出エラーメッセージ
  cv_msg_coi_10661      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10661';  -- 必須項目エラー
  cv_msg_coi_10666      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10666';  -- 拠点セキュリティチェックエラーメッセージ（一般拠点）
  cv_msg_coi_10667      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10667';  -- 出庫側保管場所情報取得エラーメッセージ
  cv_msg_coi_10668      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10668';  -- 入庫側保管場所情報取得エラーメッセージ
  cv_msg_coi_10669      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10669';  -- 対象外取引エラーメッセージ
  cv_msg_coi_10670      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10670';  -- CSVアップロード行番号
  cv_msg_coi_10671      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10671';  -- HHT入出庫一時表登録件数
  cv_msg_coi_10672      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10672';  -- ロット別取引TEMP登録件数
  cv_msg_coi_10679      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10679';  -- 所属拠点不一致エラーメッセージ
  cv_msg_coi_10680      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10680';  -- 入数取得エラーメッセージ
  cv_msg_coi_10681      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10681';  -- 百貨店用取引実行エラーメッセージ
  cv_msg_coi_10682      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10682';  -- 出庫側倉替対象可否エラーメッセージ
  cv_msg_coi_10683      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10683';  -- 入庫側倉替対象可否エラーメッセージ
  cv_msg_coi_10684      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10684';  -- 出庫側コード自拠点エラーメッセージ
  cv_msg_coi_10685      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10685';  -- 入庫側コード自拠点エラーメッセージ
  cv_msg_coi_10686      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10686';  -- 出庫側コード（拠点）無効エラーメッセージ
  cv_msg_coi_10687      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10687';  -- 入庫側コード（拠点）無効エラーメッセージ
  cv_msg_coi_10688      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10688';  -- 出庫側管理元拠点不一致エラーメッセージ
  cv_msg_coi_10689      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10689';  -- 入庫側管理元拠点不一致エラーメッセージ
  cv_msg_coi_10690      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10690';  -- 出庫側管轄拠点不一致エラーメッセージ
  cv_msg_coi_10691      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10691';  -- 入庫側管轄拠点不一致エラーメッセージ
  cv_msg_coi_10692      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10692';  -- 業態小分類エラーメッセージ
  cv_msg_coi_10693      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10693';  -- 拠点セキュリティチェックエラーメッセージ（管理元拠点）
  cv_msg_coi_10694      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10694';  -- 拠点セキュリティチェックエラーメッセージ（所属拠点）
  cv_msg_coi_10695      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10695';  -- 出庫側コード（倉庫）存在エラーメッセージ
  cv_msg_coi_10696      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10696';  -- 管理元拠点取得エラーメッセージ
  cv_msg_coi_10697      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10697';  -- 営業員所属拠点取得エラーメッセージ
  cv_msg_coi_10698      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10698';  -- 所属（管理元）拠点不一致エラーメッセージ
  cv_msg_coi_10699      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10699';  -- 伝票日付形式エラーメッセージ
  cv_msg_coi_10707      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10707';  -- 数値形式エラーメッセージ（ケース数）
  cv_msg_coi_10708      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10708';  -- 数値形式エラーメッセージ（本数）
  
--
  cv_msg_cos_11293      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';  -- ファイルアップロード名称取得エラーメッセージ
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';  -- ファイルレコード項目数不一致エラーメッセージ
--
  -- メッセージ名(トークン)
  cv_tkn_coi_10502       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10502';  -- 拠点コード
  cv_tkn_coi_10673       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10673';  -- 伝票日付
  cv_tkn_coi_10674       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10674';  -- 出庫側コード
  cv_tkn_coi_10675       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10675';  -- 入庫側コード
  cv_tkn_coi_10676       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10676';  -- 営業員コード
  cv_tkn_coi_10677       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10677';  -- 品目コード
  cv_tkn_coi_10586       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10586';  -- ケース数
  cv_tkn_coi_10678       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10678';  -- 本数
  cv_tkn_coi_10634       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';  -- ファイルアップロードIF
--
  -- トークン名
  cv_tkn_pro_tok         CONSTANT VARCHAR2(100) := 'PRO_TOK';         -- プロファイル名
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';    -- 在庫組織コード
  cv_tkn_file_id         CONSTANT VARCHAR2(100) := 'FILE_ID';         -- ファイルID
  cv_tkn_file_name       CONSTANT VARCHAR2(100) := 'FILE_NAME';       -- ファイル名
  cv_tkn_file_upld_name  CONSTANT VARCHAR2(100) := 'FILE_UPLD_NAME';  -- ファイルアップロード名称
  cv_tkn_format_ptn      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';      -- フォーマットパターン
  cv_tkn_base_code       CONSTANT VARCHAR2(100) := 'BASE_CODE';       -- 拠点コード
  cv_tkn_dept_code       CONSTANT VARCHAR2(100) := 'DEPT_CODE';       -- 拠点コード
  cv_tkn_dept_code1      CONSTANT VARCHAR2(100) := 'DEPT_CODE1';      -- 拠点コード1
  cv_tkn_dept_code2      CONSTANT VARCHAR2(100) := 'DEPT_CODE2';      -- 拠点コード2
  cv_tkn_item_code       CONSTANT VARCHAR2(100) := 'ITEM_CODE';       -- 品目コード
  cv_tkn_item_column     CONSTANT VARCHAR2(100) := 'ITEM_COLUMN';     -- 項目名称
  cv_tkn_primary_uom     CONSTANT VARCHAR2(100) := 'PRIMARY_UOM';     -- 基準単位
  cv_tkn_target_date     CONSTANT VARCHAR2(100) := 'TARGET_DATE';     -- 対象日
  cv_tkn_invoice_date    CONSTANT VARCHAR2(100) := 'INVOICE_DATE';    -- 伝票日付
  cv_tkn_subinv_code     CONSTANT VARCHAR2(100) := 'SUBINV_CODE';     -- 保管場所コード
  cv_tkn_sub_inv_code    CONSTANT VARCHAR2(100) := 'SUB_INV_CODE';    -- 保管場所コード
  cv_tkn_employee_num    CONSTANT VARCHAR2(100) := 'EMPLOYEE_NUM';    -- 営業員コード
  cv_tkn_cust_code       CONSTANT VARCHAR2(100) := 'CUST_CODE';       -- 顧客コード
  cv_tkn_outside_code    CONSTANT VARCHAR2(100) := 'OUTSIDE_CODE';    -- 出庫側コード
  cv_tkn_inside_code     CONSTANT VARCHAR2(100) := 'INSIDE_CODE';     -- 入庫側コード
  cv_tkn_table_name      CONSTANT VARCHAR2(100) := 'TABLE_NAME';      -- テーブル名
  cv_tkn_record_type     CONSTANT VARCHAR2(100) := 'RECORD_TYPE';     -- レコード種別
  cv_tkn_invoice_type    CONSTANT VARCHAR2(100) := 'INVOICE_TYPE';    -- 伝票区分
  cv_tkn_dept_flag       CONSTANT VARCHAR2(100) := 'DEPT_FLAG';       -- 百貨店フラグ
  cv_tkn_invoice_no      CONSTANT VARCHAR2(100) := 'INVOICE_NO';      -- 伝票No
  cv_tkn_column_no       CONSTANT VARCHAR2(100) := 'COLUMN_NO';       -- コラムNo
  cv_tkn_key_data        CONSTANT VARCHAR2(100) := 'KEY_DATA';        -- キーデータ
  cv_tkn_line_num        CONSTANT VARCHAR2(100) := 'LINE_NUM';        -- 行番号
  cv_tkn_err_msg         CONSTANT VARCHAR2(100) := 'ERR_MSG';         -- エラーメッセージ
  cv_tkn_data            CONSTANT VARCHAR2(100) := 'DATA';            -- データ
--
  cv_base_dummy          CONSTANT VARCHAR2(5) := 'DUMMY';             -- ダミー値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納用
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER; -- 1次元配列
  g_if_data_tab             g_var_data_ttype;                                   -- 拠点間倉替データ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_inv_org_code           VARCHAR2(100);   -- 在庫組織コード
  gn_inv_org_id             NUMBER;          -- 在庫組織ID
  gn_hht_inv_tran_cnt       NUMBER;          -- HHT入出庫一時表登録件数
  gn_lot_trx_temp_cnt       NUMBER;          -- ロット別取引TEMP登録件数
  gv_err_flag               VARCHAR2(1);     -- エラーフラグ
  gv_validate_err_flag      VARCHAR2(1);     -- 妥当性エラーフラグ
  gv_line_num               VARCHAR2(5000);  -- CSVアップロード行番号
  gd_process_date           DATE;            -- 業務日付
  gd_invoice_date           DATE;            -- 伝票日付
  gv_belong_base_code       xxcoi_hht_inv_transactions.base_code%TYPE; -- 所属拠点コード
--
  gt_transaction_id         xxcoi_hht_inv_transactions.transaction_id%TYPE;       -- 入出庫一時表ID
  gt_invoice_no             xxcoi_hht_inv_transactions.invoice_no%TYPE;           -- 伝票No
  gt_dept_hht_div           xxcmm_cust_accounts.dept_hht_div%TYPE;                -- 百貨店HHT区分
  gt_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE;            -- 品目ID
  gt_primary_uom_code       mtl_system_items_b.primary_uom_code%TYPE;             -- 基準単位コード
  gt_case_in_qty            xxcoi_hht_inv_transactions.case_in_quantity%TYPE;     -- 入数
  gt_total_qty              xxcoi_hht_inv_transactions.total_quantity%TYPE;       -- 総本数
  gt_invoice_type           xxcoi_hht_inv_transactions.invoice_type%TYPE;         -- 伝票区分
  gt_department_flag        xxcoi_hht_inv_transactions.department_flag%TYPE;      -- 百貨店フラグ
  gt_out_base_code          xxcoi_hht_inv_transactions.base_code%TYPE;            -- 出庫側拠点コード
  gt_in_base_code           xxcoi_hht_inv_transactions.base_code%TYPE;            -- 入庫側拠点コード
  gt_out_subinv_code        xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;  -- 出庫側保管場所コード
  gt_in_subinv_code         xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;   -- 入庫側保管場所コード
  gt_out_warehouse_flag     mtl_secondary_inventories.attribute14%TYPE;           -- 出庫側倉庫管理対象区分
  gt_out_subinv_code_conv   xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- 出庫側保管場所変換区分
  gt_in_subinv_code_conv    xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- 入庫側保管場所変換区分
  gt_out_business_low_type  xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;    -- 出庫側業態小分類
  gt_in_business_low_type   xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;     -- 入庫側業態小分類
  gt_out_cust_code          xxcoi_hht_inv_transactions.outside_cust_code%TYPE;            -- 出庫側顧客コード
  gt_in_cust_code           xxcoi_hht_inv_transactions.inside_cust_code%TYPE;             -- 入庫側顧客コード
  gt_hht_program_div        xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- 入出庫ジャーナル処理区分
  gt_item_convert_div       xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- 商品振替区分
  gt_stock_uncheck_list_div xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- 入庫未確認リスト対象区分
  gt_stock_balance_list_div xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- 入庫差異確認リスト対象区分
  gt_consume_vd_flag        xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- 消化VD補充対象フラグ
--
  -- ファイルアップロードIFデータ
  gt_file_line_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       --   ファイルID
    iv_file_format IN  VARCHAR2,     --   ファイルフォーマット
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- 在庫組織コードの取得
    -- ===============================
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- 取得できない場合
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_00005 -- 在庫組織コード取得エラー
                    ,iv_token_name1   => cv_tkn_pro_tok
                    ,iv_token_value1  => cv_inv_org_code  -- プロファイル：在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 在庫組織IDの取得
    -- ===============================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gv_inv_org_code
                     );
    -- 取得できない場合
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_00006  -- 在庫組織ID取得エラー
                    ,iv_token_name1  => cv_tkn_org_code_tok
                    ,iv_token_value1 => gv_inv_org_code   -- 在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 業務日付の取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_00011 -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 所属拠点コードの取得
    -- ===============================
    gv_belong_base_code := xxcoi_common_pkg.get_base_code(
                             in_user_id     => cn_created_by  -- ユーザーID
                            ,id_target_date => SYSDATE        -- 対象日
                           );
    IF ( gv_belong_base_code IS NULL ) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg( 
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10271  -- 所属拠点取得エラーメッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 百貨店HHT区分の取得
    -- ===============================
    BEGIN
      SELECT xca.dept_hht_div  AS dept_hht_div -- 百貨店HHT区分
      INTO   gt_dept_hht_div -- 百貨店HHT区分
      FROM   hz_cust_accounts       hca -- 顧客マスタ
            ,xxcmm_cust_accounts    xca -- 顧客追加情報
      WHERE  hca.cust_account_id     = xca.customer_id       -- 顧客ID
      AND    hca.customer_class_code = cv_cust_class_code_1  -- 顧客区分(拠点)
      AND    hca.status              = cv_const_a            -- ステータス(有効)
      AND    hca.account_number      = gv_belong_base_code   -- 顧客コード(所属拠点と一致)
      ;
    EXCEPTION
      -- 取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10272    -- 顧客追加情報取得エラーメッセージ
                    ,iv_token_name1  => cv_tkn_base_code
                    ,iv_token_value1 => gv_belong_base_code -- 所属拠点コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    -- コンカレント入力パラメータ出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi
                ,iv_name          => cv_msg_coi_10232    -- コンカレント入力パラメータ
                ,iv_token_name1   => cv_tkn_file_id
                ,iv_token_value1  => TO_CHAR(in_file_id) -- ファイルID
                ,iv_token_name2   => cv_tkn_format_ptn
                ,iv_token_value2  => iv_file_format      -- フォーマットパターン
               )
    );
--
    -- コンカレント入力パラメータ出力(出力)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi
                ,iv_name          => cv_msg_coi_10232    -- コンカレント入力パラメータ
                ,iv_token_name1   => cv_tkn_file_id
                ,iv_token_value1  => TO_CHAR(in_file_id) -- ファイルID
                ,iv_token_name2   => cv_tkn_format_ptn
                ,iv_token_value2  => iv_file_format      -- フォーマットパターン
                )
    );
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
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
    in_file_id     IN  NUMBER,       --   ファイルID
    iv_file_format IN  VARCHAR2,     --   ファイルフォーマット
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;  -- ファイル名
    lt_file_upload_name fnd_lookup_values.description%TYPE;          -- ファイルアップロード名称
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
    -- ローカル変数初期化
    lt_file_name        := NULL; -- ファイル名
    lt_file_upload_name := NULL; -- ファイルアップロード名称
--
    -- ===============================
    -- ファイルアップロードIFデータロック
    -- ===============================
    BEGIN
      SELECT  xfu.file_name AS file_name -- ファイル名
        INTO  lt_file_name -- ファイル名
        FROM  xxccp_mrp_file_ul_interface  xfu -- ファイルアップロードIF
       WHERE  xfu.file_id = in_file_id -- ファイルID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロックが取得できない場合
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi
                      ,iv_name          => cv_msg_coi_10142 -- ファイルアップロードIFテーブルロックエラーメッセージ
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- ファイルアップロード名称情報取得
    -- ===============================
    BEGIN
      SELECT  flv.meaning AS file_upload_name -- ファイルアップロード名称
        INTO  lt_file_upload_name -- ファイルアップロード名称
        FROM  fnd_lookup_values flv -- クイックコード
       WHERE  flv.lookup_type  = cv_type_upload_obj  -- タイプ
         AND  flv.lookup_code  = iv_file_format      -- コード
         AND  flv.enabled_flag = cv_const_y          -- 有効フラグ(Y)
         AND  flv.language     = ct_lang             -- 言語
         AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date  -- 有効開始日
         AND  NVL(flv.end_date_active, gd_process_date)   >= gd_process_date  -- 有効終了日
      ;
    EXCEPTION
      -- ファイルアップロード名称が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos
                      ,iv_name          => cv_msg_cos_11293 -- ファイルアップロード名称取得エラーメッセージ
                      ,iv_token_name1   => cv_tkn_key_data
                      ,iv_token_value1  => iv_file_format   -- フォーマットパターン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 取得したファイル名、ファイルアップロード名称を出力
    -- ===============================
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_00028 -- ファイル名出力メッセージ
                 ,iv_token_name1   => cv_tkn_file_name
                 ,iv_token_value1  => lt_file_name     -- ファイル名
                )
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
     ,buff    => xxccp_common_pkg.get_msg(
                   iv_application   => cv_msg_kbn_coi
                  ,iv_name          => cv_msg_coi_00028 -- ファイル名出力メッセージ
                  ,iv_token_name1   => cv_tkn_file_name
                  ,iv_token_value1  => lt_file_name     -- ファイル名
                 )
    );
--
    -- ファイルアップロード名称を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10611    -- ファイルアップロード名称出力メッセージ
                 ,iv_token_name1   => cv_tkn_file_upld_name
                 ,iv_token_value1  => lt_file_upload_name -- ファイルアップロード名称
                )
    );
    -- ファイルアップロード名称を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi
                 ,iv_name          => cv_msg_coi_10611    -- ファイルアップロード名称出力メッセージ
                 ,iv_token_name1   => cv_tkn_file_upld_name
                 ,iv_token_value1  => lt_file_upload_name -- ファイルアップロード名称
                )
    );
--
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- ===============================
    -- ファイルアップロードIFデータを取得
    -- ===============================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- ファイルID
     ,ov_file_data => gt_file_line_data_tab -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラー、または抽出行数が1行以上なかった場合
    IF ( (lv_retcode <> cv_status_normal)
      OR (gt_file_line_data_tab.COUNT < 1) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10635 -- データ抽出エラーメッセージ
                    ,iv_token_name1   => cv_tkn_table_name
                    ,iv_token_value1  => cv_tkn_coi_10634 -- ファイルアップロードIF
                    ,iv_token_name2   => cv_tkn_key_data
                    ,iv_token_value2  => NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象件数を設定
    -- ===============================
    gn_target_cnt := gt_file_line_data_tab.COUNT;
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
   * Procedure Name   : divide_item
   * Description      : アップロードファイル項目分割(A-3)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt    IN  NUMBER,   --   IFループカウンタ
    ov_errbuf              OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_rec_data     VARCHAR2(32765); -- レコードデータ
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
    -- ===============================
    -- ローカル変数初期化
    -- ===============================
    lv_rec_data  := NULL; -- レコードデータ
--
    -- ===============================
    -- 項目数チェック
    -- ===============================
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- 項目数不一致の場合
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10670 -- CSVアップロード行番号
                    ,iv_token_name1   => cv_tkn_line_num
                    ,iv_token_value1  => in_file_if_loop_cnt -- ループカウンタ
                   ) ||
                   xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos
                    ,iv_name          => cv_msg_cos_11295 -- ファイルレコード項目数不一致エラーメッセージ
                    ,iv_token_name1   => cv_tkn_data
                    ,iv_token_value1  => lv_rec_data      -- 拠点間倉替データ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 分割ループ
    -- ===============================
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header_all LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     => gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    => cv_csv_delimiter
                                   ,in_part_num => i
                                  );
    END LOOP data_split_loop;
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
   * Procedure Name   : validate_item
   * Description      : 妥当性チェック＆項目値導出(A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    in_if_loop_cnt IN  NUMBER,   -- IFループカウンタ
    ov_errbuf      OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item'; -- プログラム名
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
    cv_baracya_type_0      VARCHAR2(1)  := '0';            -- バラ茶区分:0（その他）
    cv_num_format_case     VARCHAR2(9)  := 'FM9999999';    -- 数値書式（ケース数）
    cv_num_format_qty      VARCHAR2(12) := 'FM9999990.00'; -- 数値書式（本数）
    
--
    -- *** ローカル変数 ***
    ln_select_count        NUMBER;  -- 抽出件数
    lt_item_status         mtl_system_items_b.inventory_item_status_code%TYPE;    -- 品目ステータス
    lt_cust_order_flg      mtl_system_items_b.customer_order_enabled_flag%TYPE;   -- 顧客受注可能フラグ
    lt_transaction_enable  mtl_system_items_b.mtl_transactions_enabled_flag%TYPE; -- 取引可能
    lt_stock_enabled_flg   mtl_system_items_b.stock_enabled_flag%TYPE;            -- 在庫保有可能フラグ
    lt_return_enable       mtl_system_items_b.returnable_flag%TYPE;               -- 返品可能
    lt_sales_class         ic_item_mst_b.attribute26%TYPE;                        -- 売上対象区分
    lt_baracha_div         xxcmm_system_items_b.baracha_div%TYPE;                 -- バラ茶区分
    ld_disable_date        DATE;                                                  -- 無効日
    lb_org_acct_period_flg BOOLEAN;                                               -- 会計期間オープンフラグ
    lv_emp_base_code       per_all_assignments_f.ass_attribute5%TYPE;             -- 所属拠点コード
    lv_result_aff_out      VARCHAR2(1);                                           -- AFF部門有効チェック結果（出庫側）
    lv_result_aff_in       VARCHAR2(1);                                           -- AFF部門有効チェック結果（入庫側）
    lt_start_date_active   fnd_flex_values.start_date_active%TYPE;                -- AFF部門適用開始日
    lt_in_warehouse_flag   mtl_secondary_inventories.attribute14%TYPE;            -- 入庫側倉庫管理対象区分
    lt_outside_subinv_div  mtl_secondary_inventories.attribute5%TYPE;             -- 出庫側棚卸対象
    lt_inside_subinv_div   mtl_secondary_inventories.attribute5%TYPE;             -- 入庫側棚卸対象
    lt_out_subinv_kbn      mtl_secondary_inventories.attribute1%TYPE;             -- 出庫側保管場所区分
    lt_in_subinv_kbn       mtl_secondary_inventories.attribute1%TYPE;             -- 入庫側保管場所区分
    lt_out_cust_code       mtl_secondary_inventories.attribute4%TYPE;             -- 出庫側顧客コード
    lt_in_cust_code        mtl_secondary_inventories.attribute4%TYPE;             -- 入庫側顧客コード
    lt_cust_base_code      xxcmm_cust_accounts.sale_base_code%TYPE;               -- 管轄拠点コード
    lt_cust_status         hz_parties.duns_number_c%TYPE;                         -- 顧客ステータス
    lt_cust_low_type       xxcmm_cust_accounts.business_low_type%TYPE;            -- 業態小分類
    lt_cust_mng_base_code  xxcmm_cust_accounts.management_base_code%TYPE;         -- 管理元拠点
    lt_emp_mng_base_code   xxcmm_cust_accounts.management_base_code%TYPE;         -- 管理元拠点（営業員）
    lv_kuragae_div         hz_cust_accounts.attribute6%TYPE;                      -- 倉替対象可否区分
    lv_out_err_flag        VARCHAR2(1);  -- 出庫側エラーフラグ
    lv_in_err_flag         VARCHAR2(1);  -- 入庫側エラーフラグ
    ln_number_check_case   NUMBER;  -- 数値チェック用変数（ケース数）
    ln_number_check_qty    NUMBER;  -- 数値チェック用変数（本数）
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
    -- ===============================
    -- ローカル変数初期化
    -- ===============================
    ln_select_count        := 0;      -- 抽出件数
    lt_item_status         := NULL;   -- 品目ステータス
    lt_cust_order_flg      := NULL;   -- 顧客受注可能フラグ
    lt_transaction_enable  := NULL;   -- 取引可能
    lt_stock_enabled_flg   := NULL;   -- 在庫保有可能フラグ
    lt_return_enable       := NULL;   -- 返品可能
    lt_sales_class         := NULL;   -- 売上対象区分
    lt_baracha_div         := NULL;   -- バラ茶区分
    ld_disable_date        := NULL;   -- 無効日
    lb_org_acct_period_flg := FALSE;  -- 会計期間オープンフラグ
    lv_emp_base_code       := NULL;   -- 所属拠点コード
    lv_result_aff_out      := NULL;   -- AFF部門有効チェック結果（出庫側）
    lv_result_aff_in       := NULL;   -- AFF部門有効チェック結果（入庫側）
    lt_start_date_active   := NULL;   -- AFF部門適用開始日
    lt_in_warehouse_flag   := NULL;   -- 入庫側倉庫管理対象区分
    lt_outside_subinv_div  := NULL;   -- 出庫側棚卸対象
    lt_inside_subinv_div   := NULL;   -- 入庫側棚卸対象
    lt_out_subinv_kbn      := NULL;   -- 出庫側保管場所区分
    lt_in_subinv_kbn       := NULL;   -- 入庫側保管場所区分
    lt_out_cust_code       := NULL;   -- 出庫側顧客コード
    lt_in_cust_code        := NULL;   -- 入庫側顧客コード
    lt_cust_base_code      := NULL;   -- 管轄拠点コード
    lt_cust_status         := NULL;   -- 顧客ステータス
    lt_cust_low_type       := NULL;   -- 業態小分類
    lt_cust_mng_base_code  := NULL;   -- 管理元拠点
    lt_emp_mng_base_code   := NULL;   -- 管理元拠点（営業員）
    lv_kuragae_div         := NULL;   -- 倉替対象可否区分
    lv_out_err_flag        := cv_flag_normal_0; -- 出庫側エラーフラグ
    lv_in_err_flag         := cv_flag_normal_0; -- 入庫側エラーフラグ
    ln_number_check_case   := NULL;   -- 数値チェック用変数（ケース数）
    ln_number_check_qty    := NULL;   -- 数値チェック用変数（本数）
--
    -- ===============================
    -- CSVアップロード行番号を取得
    -- ===============================
    gv_line_num := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi
                    ,iv_name          => cv_msg_coi_10670 -- CSVアップロード行番号
                    ,iv_token_name1   => cv_tkn_line_num
                    ,iv_token_value1  => in_if_loop_cnt   -- ループカウンタ
                   );
--
    -- ==============================
    -- 必須チェック
    -- ==============================
    -- 拠点コード
    IF ( g_if_data_tab(cn_c_base_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10502 -- 拠点コード
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- 伝票日付
    IF ( g_if_data_tab(cn_c_invoice_date) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10673 -- 伝票日付
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- 出庫側コード
    IF ( g_if_data_tab(cn_c_outside_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10674 -- 出庫側コード
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- 入庫側コード
    IF ( g_if_data_tab(cn_c_inside_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10675 -- 入庫側コード
                     );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- 品目コード
    IF ( g_if_data_tab(cn_c_item_code) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10677 -- 品目コード
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- ケース数
    IF ( g_if_data_tab(cn_c_case_quantity) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10586 -- ケース数
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- 本数
    IF ( g_if_data_tab(cn_c_quantity) IS NULL ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application   => cv_msg_kbn_coi
                       ,iv_name          => cv_msg_coi_10661 -- 必須項目エラー
                       ,iv_token_name1   => cv_tkn_item_column
                       ,iv_token_value1  => cv_tkn_coi_10678 -- 本数
                      );
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gv_err_flag := cv_flag_err_1;
    END IF;
--
    -- ===============================
    -- 拠点セキュリティチェック
    -- ===============================
    -- 拠点コードがNULLでない場合のみチェック
    IF ( g_if_data_tab(cn_c_base_code) IS NOT NULL ) THEN
      -- 百貨店HHT区分がNULLの場合
      IF ( gt_dept_hht_div IS NULL ) THEN
        SELECT COUNT(1) AS select_count -- 抽出件数
        INTO   ln_select_count -- 抽出件数
        FROM   xxcos_login_base_info_v xlbiv -- ログインユーザ自拠点ビュー
        WHERE  xlbiv.base_code = g_if_data_tab(cn_c_base_code)  -- 拠点コード
        ;
--
        -- 抽出件数が0件の場合はエラー
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10666  -- 拠点セキュリティチェックエラーメッセージ（一般拠点）
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- 拠点コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
--
      -- 百貨店HHT区分が'1'（拠点複）の場合
      ELSIF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
        SELECT COUNT(1)  AS select_count -- 抽出件数
        INTO   ln_select_count -- 抽出件数
        FROM   hz_cust_accounts       hca -- 顧客マスタ
              ,xxcmm_cust_accounts    xca -- 顧客追加情報
        WHERE  hca.cust_account_id      = xca.customer_id        -- 顧客ID
        AND    hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
        AND    hca.status               = cv_const_a             -- ステータス(有効)
        AND    hca.account_number       = gv_belong_base_code    -- 顧客コード(所属拠点と一致)
        AND    xca.management_base_code = g_if_data_tab(cn_c_base_code) -- 管理元拠点コード(拠点コードと一致)
        ;
--
        -- 抽出件数が0件の場合はエラー
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10693  -- 拠点セキュリティチェックエラーメッセージ（管理元拠点）
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- 拠点コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
--
      -- 百貨店HHT区分が上記以外の場合
      ELSE
        SELECT COUNT(1)  AS select_count -- 抽出件数
        INTO   ln_select_count -- 抽出件数
        FROM   hz_cust_accounts       hca -- 顧客マスタ
        WHERE  hca.customer_class_code = cv_cust_class_code_1  -- 顧客区分(拠点)
        AND    hca.status              = cv_const_a            -- ステータス(有効)
        AND    hca.account_number      = gv_belong_base_code           -- 顧客コード（所属拠点と一致）
        AND    hca.account_number      = g_if_data_tab(cn_c_base_code) -- 顧客コード（拠点コードと一致）
        ;
--
        -- 抽出件数が0件の場合はエラー
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10694  -- 拠点セキュリティチェックエラーメッセージ（所属拠点）
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)  -- 拠点コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- 品目妥当性チェック
    -- ===============================
    -- 品目コードがNULLでない場合はチェック
    IF ( g_if_data_tab(cn_c_item_code) IS NOT NULL ) THEN
      BEGIN
        -- 品目情報取得
        SELECT msib.inventory_item_status_code    AS inventory_item_status_code      -- 品目ステータス
              ,msib.customer_order_enabled_flag   AS customer_order_enabled_flag     -- 顧客受注可能フラグ
              ,msib.mtl_transactions_enabled_flag AS mtl_transactions_enabled_flag   -- 取引可能
              ,msib.stock_enabled_flag            AS stock_enabled_flag              -- 在庫保有可能フラグ
              ,msib.returnable_flag               AS returnable_flag                 -- 返品可能
              ,iimb.attribute26                   AS sales_class                     -- 売上対象区分
              ,msib.inventory_item_id             AS inventory_item_id               -- 品目ID
              ,msib.primary_uom_code              AS primary_uom_code                -- 基準単位コード
              ,TO_NUMBER(iimb.attribute11)        AS case_in_qty                     -- 入数
              ,NVL(xsib.baracha_div,cv_baracya_type_0) AS baracha_div                -- バラ茶区分
        INTO   lt_item_status            -- 品目ステータス
              ,lt_cust_order_flg         -- 顧客受注可能フラグ
              ,lt_transaction_enable     -- 取引可能
              ,lt_stock_enabled_flg      -- 在庫保有可能フラグ
              ,lt_return_enable          -- 返品可能
              ,lt_sales_class            -- 売上対象区分
              ,gt_inventory_item_id      -- 品目ID
              ,gt_primary_uom_code       -- 基準単位コード
              ,gt_case_in_qty            -- 入数
              ,lt_baracha_div            -- バラ茶区分
        FROM   mtl_system_items_b msib   -- Disc品目マスタ
              ,ic_item_mst_b      iimb   -- OPM品目マスタ
              ,xxcmm_system_items_b xsib -- Disc品目アドオンマスタ
        WHERE  msib.segment1          = g_if_data_tab(cn_c_item_code) -- 品目コード
        AND    msib.organization_id   = gn_inv_org_id  -- 在庫組織ID
        AND    iimb.item_no           = msib.segment1  -- 品目コード
        AND    iimb.item_no           = xsib.item_code -- 品目コード
        ;
      EXCEPTION
        -- 品目情報が取得できない場合
        WHEN NO_DATA_FOUND THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10227 -- 品目存在チェックエラーメッセージ
                         ,iv_token_name1   => cv_tkn_item_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- 品目コード
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END;
--
      -- 品目情報が取得できた場合
      IF ( gt_inventory_item_id IS NOT NULL ) THEN
        -- 入数がNULLまたは0以下の場合
        IF( (gt_case_in_qty IS NULL)
          OR ((gt_case_in_qty IS NOT NULL) AND (gt_case_in_qty <= 0) ))
        THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10680 -- 入数取得エラーメッセージ
                           ,iv_token_name1   => cv_tkn_item_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- 品目コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- 品目ステータスが有効でない場合
        IF ( lt_item_status = cv_status_inactive   -- 品目ステータス
          OR  lt_cust_order_flg     <> cv_const_y  -- 顧客受注可能フラグ
          OR  lt_transaction_enable <> cv_const_y  -- 取引可能
          OR  lt_stock_enabled_flg  <> cv_const_y  -- 在庫保有可能フラグ
          OR  lt_return_enable      <> cv_const_y  -- 返品可能
        )
        THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10228 -- 品目ステータス有効チェックエラーメッセージ
                           ,iv_token_name1   => cv_tkn_item_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- 品目コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- 売上対象区分のチェック
        IF ( (lt_sales_class <> cv_sales_class_1)
          OR (lt_sales_class IS NULL) )
        THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10229 -- 品目売上対象区分有効チェックエラーメッセージ
                             ,iv_token_name1   => cv_tkn_item_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_item_code)  -- 品目コード
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- 基準単位の妥当性チェック
        -- 基準単位の無効日取得
        xxcoi_common_pkg.get_uom_disable_info(
           iv_unit_code          => gt_primary_uom_code   -- 基準単位コード
          ,od_disable_date       => ld_disable_date       -- 無効日
          ,ov_errbuf             => lv_errbuf             -- エラー・メッセージ
          ,ov_retcode            => lv_retcode            -- リターン・コード
          ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ
        );
        -- 無効日が取得できなかった場合
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10318    -- 基準単位存在チェックエラーメッセージ
                           ,iv_token_name1   => cv_tkn_primary_uom
                           ,iv_token_value1  => gt_primary_uom_code -- 基準単位コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
        -- 基準単位が有効でない場合
        IF ( TRUNC( NVL( ld_disable_date, SYSDATE+1 ) ) <= TRUNC( SYSDATE ) ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10230    -- 基準単位有効チェックエラーメッセージ
                           ,iv_token_name1   => cv_tkn_primary_uom
                           ,iv_token_value1  => gt_primary_uom_code -- 基準単位コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- ケース数、本数が設定されている場合はチェック
    IF ( g_if_data_tab(cn_c_case_quantity) IS NOT NULL
      AND  g_if_data_tab(cn_c_quantity)    IS NOT NULL )
    THEN
      -- ===============================
      -- 数値形式チェック
      -- ===============================
      -- ケース数
      BEGIN
        ln_number_check_case := TO_NUMBER(g_if_data_tab(cn_c_case_quantity),cv_num_format_case);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10707  -- 数値形式エラーメッセージ（ケース数）
                        );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
      END;
--
      -- 本数
      BEGIN
        ln_number_check_qty := TO_NUMBER(g_if_data_tab(cn_c_quantity),cv_num_format_qty);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10708  -- 数値形式エラーメッセージ（本数）
                        );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
      END;
--
      -- 数値形式エラー（本数）が発生していない場合
      IF ( ln_number_check_qty IS NOT NULL ) THEN
        -- ===============================
        -- 小数点チェック
        -- ===============================
        -- 品目のバラ茶区分が「0（その他）」の場合
        IF ( lt_baracha_div = cv_baracya_type_0 ) THEN
          -- 小数点以下に数値が指定された場合はエラー
          IF ( MOD( ln_number_check_qty , 1) <> 0 ) THEN
            ln_number_check_qty := NULL;
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10267  -- 数量整合性エラーメッセージ
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
          END IF;
        END IF;
--
        -- 数値エラーが発生していない場合
        IF ( ln_number_check_case IS NOT NULL
          AND ln_number_check_qty IS NOT NULL )
        THEN
          -- ===============================
          -- 総本数チェック
          -- ===============================
          -- 総本数を計算
          gt_total_qty := (gt_case_in_qty * ln_number_check_case)
                            + ln_number_check_qty;
          -- 総本数が0の場合はエラー
          IF ( gt_total_qty = 0 ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10426  -- 総数量エラーメッセージ
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
          END IF;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- 伝票日付チェック
    -- ===============================
    -- 伝票日付がNULLでない場合はチェック
    IF ( g_if_data_tab(cn_c_invoice_date) IS NOT NULL) THEN
      -- フォーマットチェック
      BEGIN
        gd_invoice_date :=  TO_DATE(g_if_data_tab(cn_c_invoice_date),cv_date_format_ymd);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10699  -- 伝票日付形式エラーメッセージ
                           ,iv_token_name1   => cv_tkn_invoice_date
                           ,iv_token_value1  => g_if_data_tab(cn_c_invoice_date) --伝票日付
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
          -- 以降のチェックでエラーとならないよう業務日付を設定
          gd_invoice_date := gd_process_date;
      END;
--
      -- 未来日チェック
      IF ( gd_invoice_date > gd_process_date ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10042  -- 伝票日付未来日メッセージ
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      ELSE
        -- 在庫会計期間チェック
        -- 会計期間を取得
        xxcoi_common_pkg.org_acct_period_chk(
           in_organization_id => gn_inv_org_id                     -- 在庫組織ID
          ,id_target_date     => gd_invoice_date                   -- 伝票日付
          ,ob_chk_result      => lb_org_acct_period_flg            -- チェック結果
          ,ov_errbuf          => lv_errbuf
          ,ov_retcode         => lv_retcode
          ,ov_errmsg          => lv_errmsg
        );
        -- 在庫会計期間ステータスの取得に失敗した場合
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_00026    -- 在庫会計期間ステータス取得エラーメッセージ
                           ,iv_token_name1   => cv_tkn_target_date
                           ,iv_token_value1  => TO_CHAR(gd_invoice_date,cv_date_format_ymd)     -- 伝票日付
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
--
        -- 在庫会計期間がクローズの場合
        IF ( lb_org_acct_period_flg = FALSE ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10231    -- 在庫会計期間チェックエラーメッセージ
                           ,iv_token_name1   => cv_tkn_invoice_date
                           ,iv_token_value1  => TO_CHAR(gd_invoice_date,cv_date_format_ymd) --伝票日付
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
        END IF;
      END IF;
    END IF;
--
    -- ===============================
    -- 営業員拠点チェック
    -- ===============================
    -- 営業員コードがNULLでない場合はチェック
    IF ( g_if_data_tab(cn_c_employee_num) IS NOT NULL ) THEN
      xxcoi_common_pkg.get_belonging_base2(
         in_employee_code  => g_if_data_tab(cn_c_employee_num)   -- 営業員コード
        ,id_target_date    => gd_invoice_date                    -- 伝票日付
        ,ov_base_code      => lv_emp_base_code                   -- 所属拠点コード
        ,ov_errbuf         => lv_errbuf
        ,ov_retcode        => lv_retcode
        ,ov_errmsg         => lv_errmsg
      );
      -- 所属拠点コードの取得に失敗した場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10697    -- 営業員所属拠点取得エラーメッセージ
                         ,iv_token_name1   => cv_tkn_employee_num
                         ,iv_token_value1  => g_if_data_tab(cn_c_employee_num)  --営業員コード
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END IF;
--
      -- 所属拠点の管理元拠点を取得
      BEGIN
        SELECT xca.management_base_code  AS cust_mng_base_code  -- 管理元拠点コード
        INTO   lt_emp_mng_base_code  -- 管理元拠点コード
        FROM   hz_cust_accounts       hca -- 顧客マスタ
              ,xxcmm_cust_accounts    xca -- 顧客追加情報
        WHERE  hca.cust_account_id      = xca.customer_id        -- 顧客ID
        AND    hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
        AND    hca.status               = cv_const_a             -- ステータス(有効)
        AND    hca.account_number       = lv_emp_base_code       -- 顧客コード(営業員の所属拠点と一致)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
      -- 拠点コードと営業員の所属拠点コードまたは管理元拠点コードが不一致の場合
      IF ( g_if_data_tab(cn_c_base_code) <> lv_emp_base_code
        AND g_if_data_tab(cn_c_base_code) <> NVL(lt_emp_mng_base_code,cv_base_dummy)) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10698  -- 所属（管理元）拠点不一致エラーメッセージ
                         ,iv_token_name1   => cv_tkn_dept_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- 拠点コード
                         ,iv_token_name2   => cv_tkn_dept_code1
                         ,iv_token_value2  => lv_emp_base_code              -- 所属拠点コード
                         ,iv_token_name3   => cv_tkn_dept_code2
                         ,iv_token_value3  => lt_emp_mng_base_code          -- 管理元拠点コード
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- 入出庫コードチェック
    -- ===============================
    -- 拠点コード、出庫側（入庫側）コードがNULLでない場合はチェック
    IF ( g_if_data_tab(cn_c_base_code)     IS NOT NULL
      AND g_if_data_tab(cn_c_outside_code) IS NOT NULL 
      AND g_if_data_tab(cn_c_inside_code)  IS NOT NULL )
    THEN
      -- ===============================
      -- 倉庫から他拠点の場合
      -- ===============================
      IF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 2
        AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 4 )
      THEN
--
        -- ===============================
        -- 出庫側コード妥当性チェック
        -- ===============================
        -- 変数初期化
        ln_select_count := 0;
--
        -- 出庫側保管場所情報を取得
        SELECT COUNT(1)  AS select_count -- 抽出件数
        INTO  ln_select_count -- 抽出件数
        FROM  xxcoi_subinventory_info_v xsiv -- 保管場所情報ビュー
        WHERE xsiv.subinventory_class IN (cv_subinv_kbn_1,cv_subinv_kbn_4) -- 保管場所区分(1:倉庫または4:専門店)
        AND   gd_process_date <= NVL(xsiv.disable_date-1,gd_process_date)  -- 無効日
        AND   xsiv.store_code = g_if_data_tab(cn_c_outside_code)           -- 倉庫コード(出庫側コードと一致)
        AND   xsiv.base_code  IN (SELECT hca.account_number  AS base_code -- 拠点コード
                                  FROM   hz_cust_accounts       hca -- 顧客マスタ
                                        ,xxcmm_cust_accounts    xca -- 顧客追加情報
                                  WHERE  hca.cust_account_id      = xca.customer_id        -- 顧客ID
                                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
                                  AND    hca.status               = cv_const_a             -- ステータス(有効)
                                  AND    (hca.account_number       = g_if_data_tab(cn_c_base_code) -- 顧客コード
                                           OR xca.management_base_code = g_if_data_tab(cn_c_base_code)) -- 管理元拠点コード
                                  )
        ;
--
        -- 抽出件数が0件の場合はエラー
        IF ( ln_select_count = 0 ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10695  -- 出庫側コード（倉庫）存在エラーメッセージ
                           ,iv_token_name1   => cv_tkn_outside_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
          lv_out_err_flag := cv_flag_err_1;
        END IF;
--
        -- ===============================
        -- 入庫側コード妥当性チェック
        -- ===============================
        -- 拠点間倉替データ. 拠点コードと入庫側コードが一致する場合
        IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_inside_code) ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10685  -- 入庫側コード自拠点エラーメッセージ
                           ,iv_token_name1   => cv_tkn_dept_code
                           ,iv_token_value1  => g_if_data_tab(cn_c_base_code)   -- 拠点コード
                           ,iv_token_name2   => cv_tkn_inside_code
                           ,iv_token_value2  => g_if_data_tab(cn_c_inside_code) -- 入庫側コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
          lv_in_err_flag := cv_flag_err_1;
--
        -- エラーが発生しなかった場合
        ELSE
          -- 変数初期化
          ln_select_count := 0;
--
          -- 入庫側拠点情報を取得
          SELECT COUNT(1)  AS select_count -- 抽出件数
          INTO   ln_select_count -- 抽出件数
          FROM   hz_cust_accounts  hca -- 顧客マスタ
          WHERE  hca.customer_class_code = cv_cust_class_code_1 -- 顧客区分(拠点)
          AND    hca.attribute6          = cv_kuragae_div_1     -- 倉替対象可否区分(Y:倉替可)
          AND    hca.status              = cv_const_a           -- ステータス(有効)
          AND    hca.account_number      = g_if_data_tab(cn_c_inside_code)  -- 顧客コード(入庫側コードと一致)
          ;
--
          -- 抽出件数が0件の場合はエラー
          IF ( ln_select_count = 0 ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10687  -- 入庫側コード（拠点）無効エラーメッセージ
                             ,iv_token_name1   => cv_tkn_inside_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
            lv_in_err_flag := cv_flag_err_1;
          END IF;
        END IF;
--
        -- ===============================
        -- 項目値の設定
        -- ===============================
        -- エラーが発生しなかった場合
        IF ( lv_out_err_flag = cv_flag_normal_0 
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_9;     -- 伝票区分：'9'（他拠点へ出庫）
          gt_department_flag := cv_department_flag_99; -- 百貨店フラグ：'99'（ダミー）
        END IF;
--
      -- ===============================
      -- 他拠点から預け先の場合
      -- ===============================
      ELSIF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 4
           AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 9 )
      THEN
--
        -- ===============================
        -- 実行ユーザセキュリティチェック
        -- ===============================
        IF ( gt_dept_hht_div IS NULL ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10681  -- 百貨店用取引実行エラーメッセージ
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
          lv_out_err_flag := cv_flag_err_1;
--
        -- エラーが発生しなかった場合は後続のチェックを行う
        ELSE
          -- ===============================
          -- 出庫側コード妥当性チェック
          -- ===============================
          -- 拠点間倉替データ. 拠点コードと出庫側コードが一致する場合
          IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_outside_code) ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10684  -- 出庫側コード自拠点エラーメッセージ
                             ,iv_token_name1   => cv_tkn_dept_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_base_code)   -- 拠点コード
                             ,iv_token_name2   => cv_tkn_outside_code
                             ,iv_token_value2  => g_if_data_tab(cn_c_outside_code) -- 出庫側コード
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
            lv_out_err_flag := cv_flag_err_1;
--
          -- エラーが発生しなかった場合
          ELSE
            -- 変数初期化
            ln_select_count := 0;
--
            -- 出庫側拠点情報を取得
            SELECT COUNT(1)  AS select_count -- 抽出件数
            INTO   ln_select_count -- 抽出件数
            FROM   hz_cust_accounts  hca -- 顧客マスタ
            WHERE  hca.customer_class_code = cv_cust_class_code_1 -- 顧客区分
            AND    hca.attribute6          = cv_kuragae_div_1     -- 倉替対象可否区分
            AND    hca.status              = cv_const_a           -- ステータス
            AND    hca.account_number      = g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
            ;
--
            -- 抽出件数が0件の場合はエラー
            IF ( ln_select_count = 0 ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10686  -- 出庫側コード（拠点）無効エラーメッセージ
                               ,iv_token_name1   => cv_tkn_outside_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
            END IF;
          END IF;
--
          -- ===============================
          -- 入庫側コード妥当性チェック
          -- ===============================
          -- 管轄拠点の取得
          BEGIN
            SELECT CASE WHEN 
                          TO_CHAR(gd_invoice_date, cv_date_format_ym)
                            = TO_CHAR(gd_process_date, cv_date_format_ym)
                        THEN
                          xca.sale_base_code
                        ELSE
                          xca.past_sale_base_code
                        END                        AS base_code     -- 管轄拠点コード
                  ,hp.duns_number_c                AS cust_status   -- 顧客ステータス
                  ,xca.business_low_type           AS cust_low_type -- 業態小分類
            INTO   lt_cust_base_code -- 管轄拠点コード
                  ,lt_cust_status    -- 顧客ステータス
                  ,lt_cust_low_type  -- 業態小分類
            FROM   hz_cust_accounts    hca -- 顧客マスタ
                  ,xxcmm_cust_accounts xca -- 顧客追加情報
                  ,hz_parties          hp  -- パーティマスタ
            WHERE  hca.cust_account_id     = xca.customer_id       -- 顧客ID
            AND    hca.party_id            = hp.party_id           -- パーティID
            AND    hca.customer_class_code = cv_cust_class_code_10 -- 顧客区分(顧客)
            AND    hca.status              = cv_const_a            -- ステータス(有効)
            AND    hca.account_number      = g_if_data_tab(cn_c_inside_code) -- 顧客コード(入庫側コードと一致)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 取得できない場合はエラー
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10214  -- 管轄拠点取得エラー
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
          END;
--
          -- 管轄拠点が取得できた場合は後続チェックを行う
          IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
            -- 管轄拠点がNULLの場合はエラー
            IF ( lt_cust_base_code IS NULL ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10215  -- 管轄拠点未設定エラー
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
            ELSE
--
              -- 顧客ステータスが'30'(承認済)、'40'(顧客)、'50'（休止）以外の場合はエラー
              IF ( lt_cust_status <> cv_cust_status_30
                AND lt_cust_status <> cv_cust_status_40 
                AND lt_cust_status <> cv_cust_status_50 )
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10216  -- 顧客ステータスエラー
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                                );
                -- エラーメッセージを出力
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- エラーフラグを更新
                gv_err_flag := cv_flag_err_1;
                lv_in_err_flag := cv_flag_err_1;
              END IF;
--
              -- 業態小分類が'21'(インショップ)、'22'(当社直営)以外の場合はエラー
              IF ( lt_cust_low_type <> cv_cust_low_type_21
                AND lt_cust_low_type <> cv_cust_low_type_22)
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10692  -- 業態小分類エラーメッセージ
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                                );
                -- エラーメッセージを出力
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- エラーフラグを更新
                gv_err_flag := cv_flag_err_1;
                lv_in_err_flag := cv_flag_err_1;
              END IF;
--
              -- A-1で取得した百貨店HHT区分が’1’の場合
              IF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
                -- 管轄拠点情報を取得
                BEGIN
                  SELECT xca.management_base_code  AS cust_mng_base_code  -- 管理元拠点コード
                        ,hca.attribute6            AS kuragae_div         -- 倉替対象可否区分
                  INTO   lt_cust_mng_base_code  -- 管理元拠点コード
                        ,lv_kuragae_div         -- 倉替対象可否区分
                  FROM   hz_cust_accounts       hca -- 顧客マスタ
                        ,xxcmm_cust_accounts    xca -- 顧客追加情報
                  WHERE  hca.cust_account_id      = xca.customer_id        -- 顧客ID
                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
                  AND    hca.status               = cv_const_a             -- ステータス(有効)
                  AND    hca.account_number       = lt_cust_base_code      -- 顧客コード(管轄拠点と一致)
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10696  -- 管理元拠点取得エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_cust_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                END;
--
                -- 管轄拠点情報が取得できた場合
                IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
                  -- 拠点間倉替データ.拠点コードと管理元拠点コードが一致しない場合
                  IF ( g_if_data_tab(cn_c_base_code) <> lt_cust_mng_base_code ) THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10689  -- 入庫側管理元拠点不一致エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- 拠点コード
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_mng_base_code         -- 管理元拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
--
                  -- 倉替対象区分が'1'以外の場合
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10683  -- 入庫側倉替対象可否エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_inside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code) -- 入庫側コード
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
--
              -- A-1で取得した百貨店HHT区分が’2’の場合
              ELSE
                -- 管轄拠点情報を取得
                BEGIN
                  SELECT hca.attribute6  AS kuragae_div  -- 倉替対象可否区分
                  INTO   lv_kuragae_div  -- 倉替対象可否区分
                  FROM   hz_cust_accounts  hca -- 顧客マスタ
                  WHERE  hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
                  AND    hca.status               = cv_const_a             -- ステータス(有効)
                  AND    hca.account_number       = lt_cust_base_code      -- 顧客コード（管轄拠点と一致）
                  AND    hca.account_number       = g_if_data_tab(cn_c_base_code) -- 顧客コード（拠点コードと一致）
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10691  -- 入庫側管轄拠点不一致エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- 拠点コード
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_base_code             -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                END;
--
                -- 管轄拠点情報が取得できた場合
                IF ( lv_in_err_flag = cv_flag_normal_0 ) THEN
                  -- 倉替対象区分が'1'以外の場合
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10683  -- 入庫側倉替対象可否エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_inside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_inside_code) -- 入庫側コード
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_in_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
        -- ===============================
        -- 項目値の設定
        -- ===============================
        -- エラーが発生しなかった場合
        IF ( lv_out_err_flag = cv_flag_normal_0
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_4;    -- 伝票区分：'4'（倉庫から預け先）
          gt_department_flag := cv_department_flag_5; -- 百貨店フラグ：'5'（他拠点から預け先）
        END IF;
--
      -- ===============================
      -- 預け先から他拠点の場合
      -- ===============================
      ELSIF ( LENGTH(g_if_data_tab(cn_c_outside_code)) = 9
           AND LENGTH(g_if_data_tab(cn_c_inside_code)) = 4 )
      THEN
        -- ===============================
        -- 実行ユーザセキュリティチェック
        -- ===============================
        IF ( gt_dept_hht_div IS NULL ) THEN
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10681  -- 百貨店用取引実行エラーメッセージ
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
          lv_in_err_flag  := cv_flag_err_1;
--
        -- エラーが発生しなかった場合は後続のチェックを行う
        ELSE
          -- ===============================
          -- 入庫側コード妥当性チェック
          -- ===============================
          -- 拠点間倉替データ. 拠点コードと入庫側コードが一致する場合
          IF ( g_if_data_tab(cn_c_base_code) = g_if_data_tab(cn_c_inside_code) ) THEN
            lv_errmsg := gv_line_num
                         || xxccp_common_pkg.get_msg(
                              iv_application   => cv_msg_kbn_coi
                             ,iv_name          => cv_msg_coi_10685  -- 入庫側コード自拠点エラーメッセージ
                             ,iv_token_name1   => cv_tkn_dept_code
                             ,iv_token_value1  => g_if_data_tab(cn_c_base_code)    -- 拠点コード
                             ,iv_token_name2   => cv_tkn_inside_code
                             ,iv_token_value2  => g_if_data_tab(cn_c_inside_code) -- 入庫側コード
                            );
            -- エラーメッセージを出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- エラーフラグを更新
            gv_err_flag := cv_flag_err_1;
            lv_in_err_flag := cv_flag_err_1;
--
          -- エラーが発生しなかった場合
          ELSE
            -- 変数初期化
            ln_select_count := 0;
--
            -- 入庫側拠点情報を取得
            SELECT COUNT(1)  AS select_count -- 抽出件数
            INTO   ln_select_count -- 抽出件数
            FROM   hz_cust_accounts  hca -- 顧客マスタ
            WHERE  hca.customer_class_code = cv_cust_class_code_1 -- 顧客区分
            AND    hca.attribute6          = cv_kuragae_div_1     -- 倉替対象可否区分
            AND    hca.status              = cv_const_a           -- ステータス
            AND    hca.account_number      = g_if_data_tab(cn_c_inside_code)  -- 顧客コード
            ;
--
            -- 抽出件数が0件の場合はエラー
            IF ( ln_select_count = 0 ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10687  -- 入庫側コード（拠点）無効エラーメッセージ
                               ,iv_token_name1   => cv_tkn_inside_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_in_err_flag := cv_flag_err_1;
            END IF;
          END IF;
--
          -- ===============================
          -- 出庫側コード妥当性チェック
          -- ===============================
          -- 管轄拠点の取得
          BEGIN
            SELECT CASE WHEN
                          TO_CHAR( gd_invoice_date, cv_date_format_ym)
                            = TO_CHAR(gd_process_date, cv_date_format_ym)
                        THEN
                          xca.sale_base_code
                        ELSE
                          xca.past_sale_base_code
                        END                        AS base_code     -- 管轄拠点コード
                  ,hp.duns_number_c                AS cust_status   -- 顧客ステータス
                  ,xca.business_low_type           AS cust_low_type -- 業態小分類
            INTO   lt_cust_base_code -- 管轄拠点コード
                  ,lt_cust_status    -- 顧客ステータス
                  ,lt_cust_low_type  -- 業態小分類
            FROM   hz_cust_accounts    hca -- 顧客マスタ
                  ,xxcmm_cust_accounts xca -- 顧客追加情報
                  ,hz_parties          hp  -- パーティマスタ
            WHERE  hca.cust_account_id     = xca.customer_id       -- 顧客ID
            AND    hca.party_id            = hp.party_id           -- パーティID
            AND    hca.customer_class_code = cv_cust_class_code_10 -- 顧客区分(顧客)
            AND    hca.status              = cv_const_a            -- ステータス(有効)
            AND    hca.account_number      = g_if_data_tab(cn_c_outside_code) -- 顧客コード(出庫側コードと一致)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 取得できない場合はエラー
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10214  -- 管轄拠点取得エラー
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
          END;
--
          -- 管轄拠点情報が取得できたは後続チェックを行う
          IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
            -- 管轄拠点がNULLの場合はエラー
            IF ( lt_cust_base_code IS NULL ) THEN
              lv_errmsg := gv_line_num
                           || xxccp_common_pkg.get_msg(
                                iv_application   => cv_msg_kbn_coi
                               ,iv_name          => cv_msg_coi_10215  -- 管轄拠点未設定エラー
                               ,iv_token_name1   => cv_tkn_cust_code
                               ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                              );
              -- エラーメッセージを出力
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT,
                buff  => lv_errmsg
              );
              -- エラーフラグを更新
              gv_err_flag := cv_flag_err_1;
              lv_out_err_flag := cv_flag_err_1;
            ELSE
--
              -- 顧客ステータスが'30'(承認済)、'40'(顧客)、'50'（休止）以外の場合はエラー
              IF ( lt_cust_status <> cv_cust_status_30
                AND lt_cust_status <> cv_cust_status_40 
                AND lt_cust_status <> cv_cust_status_50 )
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10216  -- 顧客ステータスエラー
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                                );
                -- エラーメッセージを出力
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- エラーフラグを更新
                gv_err_flag := cv_flag_err_1;
                lv_out_err_flag := cv_flag_err_1;
              END IF;
--
              -- 業態小分類が'21'(インショップ)、'22'(当社直営)以外の場合はエラー
              IF ( lt_cust_low_type <> cv_cust_low_type_21
                AND lt_cust_low_type <> cv_cust_low_type_22)
              THEN
                lv_errmsg := gv_line_num
                             || xxccp_common_pkg.get_msg(
                                  iv_application   => cv_msg_kbn_coi
                                 ,iv_name          => cv_msg_coi_10692  -- 業態小分類エラーメッセージ
                                 ,iv_token_name1   => cv_tkn_cust_code
                                 ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                                );
                -- エラーメッセージを出力
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT,
                  buff  => lv_errmsg
                );
                -- エラーフラグを更新
                gv_err_flag := cv_flag_err_1;
                lv_out_err_flag := cv_flag_err_1;
              END IF;
--
              -- A-1で取得した百貨店HHT区分が’1’の場合
              IF ( gt_dept_hht_div = cv_dept_hht_div_1 ) THEN
                -- 管轄拠点情報を取得
                BEGIN
                  SELECT xca.management_base_code  AS cust_mng_base_code  -- 管理元拠点コード
                        ,hca.attribute6            AS kuragae_div         -- 倉替対象可否区分
                  INTO   lt_cust_mng_base_code  -- 管理元拠点コード
                        ,lv_kuragae_div         -- 倉替対象可否区分
                  FROM   hz_cust_accounts       hca -- 顧客マスタ
                        ,xxcmm_cust_accounts    xca -- 顧客追加情報
                  WHERE  hca.cust_account_id      = xca.customer_id        -- 顧客ID
                  AND    hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
                  AND    hca.status               = cv_const_a             -- ステータス(有効)
                  AND    hca.account_number       = lt_cust_base_code      -- 顧客コード(管轄拠点と一致)
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10696  -- 管理元拠点取得エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_cust_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code)  -- 出庫側コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                END;
--
                -- 管轄拠点情報が取得できた場合
                IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
                  -- 拠点間倉替データ.拠点コードと管理元拠点コードが一致しない場合
                  IF ( g_if_data_tab(cn_c_base_code) <> lt_cust_mng_base_code ) THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10688  -- 出庫側管理元拠点不一致エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- 拠点コード
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_mng_base_code         -- 管理元拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
--
                  -- 倉替対象区分が'1'以外の場合
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10682  -- 出庫側倉替対象可否エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_outside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- 出庫側コード
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code                -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
--
              -- A-1で取得した百貨店HHT区分が’2’の場合
              ELSE
                -- 管轄拠点情報を取得
                BEGIN
                  SELECT hca.attribute6  AS kuragae_div  -- 倉替対象可否区分
                  INTO   lv_kuragae_div  -- 倉替対象可否区分
                  FROM   hz_cust_accounts  hca -- 顧客マスタ
                  WHERE  hca.customer_class_code  = cv_cust_class_code_1   -- 顧客区分(拠点)
                  AND    hca.status               = cv_const_a             -- ステータス(有効)
                  AND    hca.account_number       = lt_cust_base_code      -- 顧客コード（管轄拠点と一致）
                  AND    hca.account_number       = g_if_data_tab(cn_c_base_code) -- 顧客コード（拠点コードと一致）
                  ;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10690  -- 出庫側管轄拠点不一致エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_dept_code1
                                     ,iv_token_value1  => g_if_data_tab(cn_c_base_code) -- 拠点コード
                                     ,iv_token_name2   => cv_tkn_dept_code2
                                     ,iv_token_value2  => lt_cust_base_code             -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                END;
--
                -- 管轄拠点情報が取得できた場合
                IF ( lv_out_err_flag = cv_flag_normal_0 ) THEN
                  -- 倉替対象区分が'1'以外の場合
                  IF ( lv_kuragae_div <> cv_kuragae_div_1
                    OR lv_kuragae_div IS NULL )
                  THEN
                    lv_errmsg := gv_line_num
                                 || xxccp_common_pkg.get_msg(
                                      iv_application   => cv_msg_kbn_coi
                                     ,iv_name          => cv_msg_coi_10682  -- 出庫側倉替対象可否エラーメッセージ
                                     ,iv_token_name1   => cv_tkn_outside_code
                                     ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- 出庫側コード
                                     ,iv_token_name2   => cv_tkn_dept_code
                                     ,iv_token_value2  => lt_cust_base_code               -- 管轄拠点コード
                                    );
                    -- エラーメッセージを出力
                    FND_FILE.PUT_LINE(
                      which => FND_FILE.OUTPUT,
                      buff  => lv_errmsg
                    );
                    -- エラーフラグを更新
                    gv_err_flag := cv_flag_err_1;
                    lv_out_err_flag := cv_flag_err_1;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
        -- ===============================
        -- 項目値の設定
        -- ===============================
        -- エラーが発生しなかった場合
        IF ( lv_out_err_flag = cv_flag_normal_0 
          AND lv_in_err_flag = cv_flag_normal_0 ) THEN
          gt_invoice_type    := cv_invoice_type_5;    -- 伝票区分：'5'（預け先から倉庫）
          gt_department_flag := cv_department_flag_6; -- 百貨店フラグ：'6'（預け先→他拠点）
        END IF;
--
      -- ===============================
      -- その他の取引の場合
      -- ===============================
      ELSE
        -- 対象外取引エラー
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10669    -- 対象外取引エラーメッセージ
                         ,iv_token_name1   => cv_tkn_outside_code
                         ,iv_token_value1  => g_if_data_tab(cn_c_outside_code) -- 出庫側コード
                         ,iv_token_name2   => cv_tkn_inside_code
                         ,iv_token_value2  => g_if_data_tab(cn_c_inside_code)  -- 入庫側コード
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
        lv_out_err_flag := cv_flag_err_1;
        lv_in_err_flag  := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- 保管場所情報取得
    -- ===============================
    -- これまでのチェックででエラーが発生しなかった場合
    IF ( gv_err_flag = cv_flag_normal_0 ) THEN
      -- 共通関数「HHT保管場所コード変換」呼び出し
      xxcoi_common_pkg.convert_subinv_code(
        ov_errbuf                      => lv_errbuf                               -- エラーメッセージ
       ,ov_retcode                     => lv_retcode                              -- リターン・コード(0:正常、1:エラー)
       ,ov_errmsg                      => lv_errmsg                               -- ユーザー・エラーメッセージ
       ,iv_record_type                 => cv_record_type_30                       -- レコード種別
       ,iv_invoice_type                => gt_invoice_type                         -- 伝票区分
       ,iv_department_flag             => gt_department_flag                      -- 百貨店フラグ
       ,iv_base_code                   => g_if_data_tab(cn_c_base_code)           -- 拠点コード
       ,iv_outside_code                => g_if_data_tab(cn_c_outside_code)        -- 出庫側コード
       ,iv_inside_code                 => g_if_data_tab(cn_c_inside_code)         -- 入庫側コード
       ,id_transaction_date            => gd_invoice_date                         -- 取引日
       ,in_organization_id             => gn_inv_org_id                           -- 在庫組織ID
       ,iv_hht_form_flag               => NULL                                    -- HHT取引入力画面フラグ
       ,ov_outside_subinv_code         => gt_out_subinv_code                      -- 出庫側保管場所コード
       ,ov_inside_subinv_code          => gt_in_subinv_code                       -- 入庫側保管場所コード
       ,ov_outside_base_code           => gt_out_base_code                        -- 出庫側拠点コード
       ,ov_inside_base_code            => gt_in_base_code                         -- 入庫側拠点コード
       ,ov_outside_subinv_code_conv    => gt_out_subinv_code_conv                 -- 出庫側保管場所変換区分
       ,ov_inside_subinv_code_conv     => gt_in_subinv_code_conv                  -- 入庫側保管場所変換区分
       ,ov_outside_business_low_type   => gt_out_business_low_type                -- 出庫側業態小分類
       ,ov_inside_business_low_type    => gt_in_business_low_type                 -- 入庫側業態小分類
       ,ov_outside_cust_code           => gt_out_cust_code                        -- 出庫側顧客コード
       ,ov_inside_cust_code            => gt_in_cust_code                         -- 入庫側顧客コード
       ,ov_hht_program_div             => gt_hht_program_div                      -- 入出庫ジャーナル処理区分
       ,ov_item_convert_div            => gt_item_convert_div                     -- 商品振替区分
       ,ov_stock_uncheck_list_div      => gt_stock_uncheck_list_div               -- 入庫未確認リスト対象区分
       ,ov_stock_balance_list_div      => gt_stock_balance_list_div               -- 入庫差異確認リスト対象区分
       ,ov_consume_vd_flag             => gt_consume_vd_flag                      -- 消化VD補充対象フラグ
       ,ov_outside_subinv_div          => lt_outside_subinv_div                   -- 出庫側棚卸対象
       ,ov_inside_subinv_div           => lt_inside_subinv_div                    -- 入庫側棚卸対象
      );
--
      -- エラーの場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- キー情報にユーザー・エラーメッセージを追加して出力
        lv_errmsg := gv_line_num
                     || lv_errmsg;
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- AFF部門有効チェック
    -- ===============================
    -- 出庫側保管場所コードのAFF部門有効チェック
    IF ( gt_out_subinv_code IS NOT NULL ) THEN
      lv_result_aff_out := xxcoi_common_pkg.chk_aff_active(
        in_organization_id => gn_inv_org_id                      -- 在庫組織ID
       ,iv_base_code       => NULL                               -- 拠点コード
       ,iv_subinv_code     => gt_out_subinv_code                 -- 出庫側保管場所コード
       ,id_target_date     => gd_invoice_date                    -- 対象日
      );
      -- チェック結果がNGの場合
      IF ( lv_result_aff_out = cv_const_n ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10420  -- 出庫側AFF部門エラーメッセージ
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- 入庫側保管場所コードのAFF部門有効チェック
    IF ( gt_in_subinv_code IS NOT NULL ) THEN
      lv_result_aff_in := xxcoi_common_pkg.chk_aff_active(
        in_organization_id => gn_inv_org_id                      -- 在庫組織ID
       ,iv_base_code       => NULL                               -- 拠点コード
       ,iv_subinv_code     => gt_in_subinv_code                  -- 入庫側保管場所コード
       ,id_target_date     => gd_invoice_date                    -- 対象日
      );
      -- チェック結果がNGの場合
      IF ( lv_result_aff_in = cv_const_n ) THEN
        lv_errmsg := gv_line_num
                     || xxccp_common_pkg.get_msg(
                          iv_application   => cv_msg_kbn_coi
                         ,iv_name          => cv_msg_coi_10421  -- 入庫側AFF部門エラーメッセージ
                        );
        -- エラーメッセージを出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- エラーフラグを更新
        gv_err_flag := cv_flag_err_1;
      END IF;
    END IF;
--
    -- ===============================
    -- 倉庫管理対象区分取得
    -- ===============================
    -- 出庫側保管場所の倉庫管理対象区分を取得します
    IF ( gt_out_subinv_code IS NOT NULL ) THEN
      BEGIN
        SELECT msi.attribute14 AS warehouse_flag -- 倉庫管理対象区分
        INTO   gt_out_warehouse_flag -- 出庫側倉庫管理対象区分
        FROM   mtl_secondary_inventories msi -- 保管場所マスタ
        WHERE  gd_invoice_date <= NVL(msi.disable_date - 1, gd_invoice_date) -- 無効日
        AND    msi.organization_id          = gn_inv_org_id      -- 在庫組織ID
        AND    msi.secondary_inventory_name = gt_out_subinv_code -- 保管場所コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得できない場合
          lv_errmsg := gv_line_num
                       || xxccp_common_pkg.get_msg(
                            iv_application   => cv_msg_kbn_coi
                           ,iv_name          => cv_msg_coi_10508   -- 出庫側倉庫管理対象区分取得エラー
                           ,iv_token_name1   => cv_tkn_sub_inv_code
                           ,iv_token_value1  => gt_out_subinv_code -- 出庫側保管場所コード
                          );
          -- エラーメッセージを出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- エラーフラグを更新
          gv_err_flag := cv_flag_err_1;
      END;
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_hht_inv_tran
   * Description      : HHT入出庫一時表登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_hht_inv_tran(
    in_if_loop_cnt IN  NUMBER,      -- IFループカウンタ
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_hht_inv_tran'; -- プログラム名
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
    -- ===============================
    -- シーケンス値を取得
    -- ===============================
    SELECT  xxcoi_hht_inv_transactions_s01.NEXTVAL -- 入出庫一時表IDシーケンス
    INTO    gt_transaction_id -- 入出庫一時表ID
    FROM    DUAL;
--
    SELECT  xxcoi_invoice_no_s01.NEXTVAL -- 伝票番号シーケンス
    INTO    gt_invoice_no -- 伝票番号
    FROM    DUAL;
--
    -- 伝票番号を編集
    gt_invoice_no := cv_const_e || LTRIM(TO_CHAR(gt_invoice_no,cv_invoice_num_0));
--
    -- ===============================
    -- HHT入出庫一時表へ登録
    -- ===============================
    INSERT INTO xxcoi_hht_inv_transactions(
      transaction_id                              -- 入出庫一時表ID
     ,interface_id                                -- インターフェースID
     ,form_header_id                              -- 画面入力用ヘッダID
     ,base_code                                   -- 拠点コード
     ,record_type                                 -- レコード種別
     ,employee_num                                -- 営業員コード
     ,invoice_no                                  -- 伝票№
     ,item_code                                   -- 品目コード（品名コード）
     ,case_quantity                               -- ケース数
     ,case_in_quantity                            -- 入数
     ,quantity                                    -- 本数
     ,invoice_type                                -- 伝票区分
     ,base_delivery_flag                          -- 拠点間倉替フラグ
     ,outside_code                                -- 出庫側コード
     ,inside_code                                 -- 入庫側コード
     ,invoice_date                                -- 伝票日付
     ,column_no                                   -- コラム№
     ,unit_price                                  -- 単価
     ,hot_cold_div                                -- H/C
     ,department_flag                             -- 百貨店フラグ
     ,interface_date                              -- 受信日時
     ,other_base_code                             -- 他拠点コード
     ,outside_subinv_code                         -- 出庫側保管場所
     ,inside_subinv_code                          -- 入庫側保管場所
     ,outside_base_code                           -- 出庫側拠点
     ,inside_base_code                            -- 入庫側拠点
     ,total_quantity                              -- 総本数
     ,inventory_item_id                           -- 品目ID
     ,primary_uom_code                            -- 基準単位
     ,outside_subinv_code_conv_div                -- 出庫側保管場所変換区分
     ,inside_subinv_code_conv_div                 -- 入庫側保管場所変換区分
     ,outside_business_low_type                   -- 出庫側業態区分
     ,inside_business_low_type                    -- 入庫側業態区分
     ,outside_cust_code                           -- 出庫側顧客コード
     ,inside_cust_code                            -- 入庫側顧客コード
     ,hht_program_div                             -- 入出庫ジャーナル処理区分
     ,consume_vd_flag                             -- 消化VD補充対象フラグ
     ,item_convert_div                            -- 商品振替区分
     ,stock_uncheck_list_div                      -- 入庫未確認リスト対象区分
     ,stock_balance_list_div                      -- 入庫差異確認リスト対象区分
     ,status                                      -- 処理ステータス
     ,column_if_flag                              -- コラム別転送済フラグ
     ,column_if_date                              -- コラム別転送日
     ,sample_if_flag                              -- 見本転送済フラグ
     ,sample_if_date                              -- 見本転送日
     ,output_flag                                 -- 出力済フラグ
     ,last_update_date                            -- 最終更新日
     ,last_updated_by                             -- 最終更新者
     ,creation_date                               -- 作成日
     ,created_by                                  -- 作成者
     ,last_update_login                           -- 最終更新ユーザ
     ,request_id                                  -- 要求ID
     ,program_application_id                      -- プログラムアプリケーションID
     ,program_id                                  -- プログラムID
     ,program_update_date                         -- プログラム更新日
    )
    VALUES(
      gt_transaction_id                                                -- 入出庫一時表ID
     ,in_if_loop_cnt                                                   -- インターフェースID
     ,NULL                                                             -- 画面入力用ヘッダID
     ,g_if_data_tab(cn_c_base_code)                                    -- 拠点コード
     ,cv_record_type_30                                                -- レコード種別
     ,g_if_data_tab(cn_c_employee_num)                                 -- 営業員コード
     ,gt_invoice_no                                                    -- 伝票№
     ,g_if_data_tab(cn_c_item_code)                                    -- 品目コード（品名コード）
     ,g_if_data_tab(cn_c_case_quantity)                                -- ケース数
     ,gt_case_in_qty                                                   -- 入数
     ,g_if_data_tab(cn_c_quantity)                                     -- 本数
     ,gt_invoice_type                                                  -- 伝票区分
     ,cv_base_deliv_flag_0                                             -- 拠点間倉替フラグ
     ,g_if_data_tab(cn_c_outside_code)                                 -- 出庫側コード
     ,g_if_data_tab(cn_c_inside_code)                                  -- 入庫側コード
     ,gd_invoice_date                                                  -- 伝票日付
     ,NULL                                                             -- コラム№
     ,cn_unit_price                                                    -- 単価
     ,NULL                                                             -- H/C
     ,gt_department_flag                                               -- 百貨店フラグ
     ,SYSDATE                                                          -- 受信日時
     ,DECODE(gt_out_subinv_code_conv,cv_const_e,gt_out_base_code
                                               ,gt_in_base_code)       -- 他拠点コード
     ,gt_out_subinv_code                                               -- 出庫側保管場所
     ,gt_in_subinv_code                                                -- 入庫側保管場所
     ,gt_out_base_code                                                 -- 出庫側拠点
     ,gt_in_base_code                                                  -- 入庫側拠点
     ,gt_total_qty                                                     -- 総本数
     ,gt_inventory_item_id                                             -- 品目ID
     ,gt_primary_uom_code                                              -- 基準単位
     ,gt_out_subinv_code_conv                                          -- 出庫側保管場所変換区分
     ,gt_in_subinv_code_conv                                           -- 入庫側保管場所変換区分
     ,gt_out_business_low_type                                         -- 出庫側業態区分
     ,gt_in_business_low_type                                          -- 入庫側業態区分
     ,gt_out_cust_code                                                 -- 出庫側顧客コード
     ,gt_in_cust_code                                                  -- 入庫側顧客コード
     ,gt_hht_program_div                                               -- 入出庫ジャーナル処理区分
     ,gt_consume_vd_flag                                               -- 消化VD補充対象フラグ
     ,gt_item_convert_div                                              -- 商品振替区分
     ,gt_stock_uncheck_list_div                                        -- 入庫未確認リスト対象区分
     ,gt_stock_balance_list_div                                        -- 入庫差異確認リスト対象区分
     ,cv_status_0                                                      -- 処理ステータス
     ,cv_const_n                                                       -- コラム別転送済フラグ
     ,NULL                                                             -- コラム別転送日
     ,cv_const_n                                                       -- 見本転送済フラグ
     ,NULL                                                             -- 見本転送日
     ,cv_const_n                                                       -- 出力済フラグ
     ,SYSDATE                                                          -- 最終更新日
     ,cn_last_updated_by                                               -- 最終更新者
     ,SYSDATE                                                          -- 作成日
     ,cn_created_by                                                    -- 作成者
     ,cn_last_update_login                                             -- 最終更新ユーザ
     ,cn_request_id                                                    -- 要求ID
     ,cn_program_application_id                                        -- プログラムアプリケーションID
     ,cn_program_id                                                    -- プログラムID
     ,cd_program_update_date                                           -- プログラム更新日
    );
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_hht_inv_tran;
--
  /**********************************************************************************
   * Procedure Name   : ins_lot_trx_temp
   * Description      : ロット別取引TEMP登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_lot_trx_temp(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lot_trx_temp'; -- プログラム名
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
    lt_lot_trx_id  xxcoi_lot_transactions_temp.transaction_id%TYPE; -- ロット別TEMP取引ID
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
    -- ローカル変数初期化
    lt_lot_trx_id := NULL;
--
    -- ===============================
    -- ロット別取引TEMP作成
    -- ===============================
    xxcoi_common_pkg.cre_lot_trx_temp(
      in_trx_set_id       => NULL                                      -- 取引セットID
     ,iv_parent_item_code => g_if_data_tab(cn_c_item_code)             -- 親品目コード
     ,iv_child_item_code  => NULL                                      -- 子品目コード
     ,iv_lot              => NULL                                      -- ロット(賞味期限)
     ,iv_diff_sum_code    => NULL                                      -- 固有記号
     ,iv_trx_type_code    => cv_tran_type_code_20                      -- 取引タイプコード
     ,id_trx_date         => gd_invoice_date                           -- 取引日
     ,iv_slip_num         => gt_invoice_no                             -- 伝票No
     ,in_case_in_qty      => gt_case_in_qty                            -- 入数
     ,in_case_qty         => g_if_data_tab(cn_c_case_quantity)         -- ケース数
     ,in_singly_qty       => g_if_data_tab(cn_c_quantity)              -- バラ数
     ,in_summary_qty      => gt_total_qty                              -- 取引数量
     ,iv_base_code        => g_if_data_tab(cn_c_base_code)             -- 拠点コード
     ,iv_subinv_code      => gt_out_subinv_code                        -- 保管場所コード
     ,iv_tran_subinv_code => gt_in_subinv_code                         -- 転送先保管場所コード
     ,iv_tran_loc_code    => NULL                                      -- 転送先ロケーションコード
     ,iv_inout_code       => cv_inout_code_22                          -- 入出庫コード
     ,iv_source_code      => cv_pkg_name                               -- ソースコード
     ,iv_relation_key     => gt_transaction_id                         -- 紐付けキー
     ,on_trx_id           => lt_lot_trx_id                             -- ロット別TEMP取引ID
     ,ov_errbuf           => lv_errbuf                                 -- エラーメッセージ
     ,ov_retcode          => lv_retcode                                -- リターン・コード(0:正常、2:エラー)
     ,ov_errmsg           => lv_errmsg                                 -- ユーザー・エラーメッセージ
    );
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := gv_line_num
                   || xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_coi
                       ,iv_name         => cv_msg_coi_10510   -- ロット別取引TEMP作成エラー
                       ,iv_token_name1  => cv_tkn_base_code
                       ,iv_token_value1 => g_if_data_tab(cn_c_base_code) -- 拠点コード
                       ,iv_token_name2  => cv_tkn_record_type
                       ,iv_token_value2 => cv_record_type_30             -- レコード種別
                       ,iv_token_name3  => cv_tkn_invoice_type
                       ,iv_token_value3 => gt_invoice_type               -- 伝票区分
                       ,iv_token_name4  => cv_tkn_dept_flag
                       ,iv_token_value4 => gt_department_flag            -- 百貨店フラグ
                       ,iv_token_name5  => cv_tkn_invoice_no
                       ,iv_token_value5 => gt_invoice_no                 -- 伝票番号
                       ,iv_token_name6  => cv_tkn_column_no
                       ,iv_token_value6 => NULL                          -- コラムNo
                       ,iv_token_name7  => cv_tkn_item_code
                       ,iv_token_value7 => g_if_data_tab(cn_c_item_code) -- 品目コード
                      );
--
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lot_trx_temp;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IFデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER,       --   ファイルID
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
      WHERE xfu.file_id = in_file_id; -- ファイルID
    EXCEPTION
      WHEN OTHERS THEN
      -- 削除に失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10633, -- データ削除エラーメッセージ
                       iv_token_name1   => cv_tkn_table_name,
                       iv_token_value1  => cv_tkn_coi_10634, -- ファイルアップロードIF
                       iv_token_name2   => cv_tkn_key_data,
                       iv_token_value2  => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       --   ファイルID
    iv_file_format  IN   VARCHAR2,     --   ファイルフォーマット
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ループ時のカウント
    ln_file_if_loop_cnt  NUMBER; -- ファイルIFループカウンタ
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
    gn_target_cnt        := 0;    -- 対象件数
    gn_hht_inv_tran_cnt  := 0;    -- HHT入出庫一時表登録件数
    gn_lot_trx_temp_cnt  := 0;    -- ロット別取引TEMP登録件数
    gn_error_cnt         := 0;    -- エラー件数
    gn_warn_cnt          := 0;    -- スキップ件数
    gv_inv_org_code      := NULL; -- 在庫組織コード
    gn_inv_org_id        := NULL; -- 在庫組織ID
    gv_belong_base_code  := NULL; -- 所属拠点コード
    gt_dept_hht_div      := NULL; -- 百貨店HHT区分
    gd_process_date      := NULL; -- 業務日付
    gv_line_num          := NULL; -- CSVアップロード行番号
    gv_validate_err_flag := cv_flag_normal_0; -- 妥当性エラーフラグ
--
    -- ローカル変数の初期化
    ln_file_if_loop_cnt := 0; -- ファイルIFループカウンタ
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．IFデータ取得
    -- ============================================
    get_if_data(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロードIFループ
    <<file_if_loop>>
    FOR ln_file_if_loop_cnt IN 1 .. gt_file_line_data_tab.COUNT LOOP
      -- グローバル変数初期化
      gd_invoice_date           := NULL;  -- 伝票日付
      gt_inventory_item_id      := NULL;  -- 品目ID
      gt_primary_uom_code       := NULL;  -- 基準単位コード
      gt_case_in_qty            := NULL;  -- 入数
      gt_total_qty              := NULL;  -- 総本数
      gt_invoice_type           := NULL;  -- 伝票区分
      gt_department_flag        := NULL;  -- 百貨店フラグ
      gt_out_base_code          := NULL;  -- 出庫側拠点コード
      gt_in_base_code           := NULL;  -- 入庫側拠点コード
      gt_out_warehouse_flag     := NULL;  -- 出庫側倉庫管理対象区分
      gt_out_subinv_code_conv   := NULL;  -- 出庫側保管場所変換区分
      gt_in_subinv_code_conv    := NULL;  -- 入庫側保管場所変換区分
      gt_out_business_low_type  := NULL;  -- 出庫側業態小分類
      gt_in_business_low_type   := NULL;  -- 入庫側業態小分類
      gt_out_cust_code          := NULL;  -- 出庫側顧客コード
      gt_in_cust_code           := NULL;  -- 入庫側顧客コード
      gt_hht_program_div        := NULL;  -- 入出庫ジャーナル処理区分
      gt_item_convert_div       := NULL;  -- 商品振替区分
      gt_stock_uncheck_list_div := NULL;  -- 入庫未確認リスト対象区分
      gt_stock_balance_list_div := NULL;  -- 入庫差異確認リスト対象区分
      gt_consume_vd_flag        := NULL;  -- 消化VD補充対象フラグ
      gt_transaction_id         := NULL;  -- 入出庫一時表ID
      gt_invoice_no             := NULL;  -- 伝票No
      gv_err_flag               := cv_flag_normal_0;  -- エラーフラグ
--
      -- ============================================
      -- A-3．アップロードファイル項目分割
      -- ============================================
      divide_item(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-4．妥当性チェック＆項目値導出
      -- ============================================
      validate_item(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 妥当性エラーの場合はエラー件数をカウント
      IF ( gv_err_flag = cv_flag_err_1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
      -- 妥当性エラーが発生していない場合はテーブル登録処理を実行
        -- ============================================
        -- A-5．HHT入出庫一時表登録
        -- ============================================
        ins_hht_inv_tran(
           ln_file_if_loop_cnt -- IFループカウンタ
          ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode          -- リターン・コード             --# 固定 #
          ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        ELSE
          -- 正常終了の場合はHHT入出庫一時表登録件数をカウント
          gn_hht_inv_tran_cnt := gn_hht_inv_tran_cnt + 1;
        END IF;
--
        -- 出庫側保管場所が倉庫管理対象の場合
        IF ( gt_out_warehouse_flag = cv_const_y ) THEN
          -- ============================================
          -- A-6．ロット別取引TEMP登録
          -- ============================================
          ins_lot_trx_temp(
             lv_errbuf           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode          -- リターン・コード             --# 固定 #
            ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          ELSE
            -- 正常終了の場合はロット別取引TEMP登録件数をカウント
            gn_lot_trx_temp_cnt := gn_lot_trx_temp_cnt + 1;
          END IF;
        END IF;
      END IF;
--
    END LOOP file_if_loop;
--
    -- エラーレコードが存在する場合
    IF ( gn_error_cnt <> 0 ) THEN
      gv_validate_err_flag := cv_flag_err_1; -- 妥当性エラーフラグ:Y
      ov_retcode := cv_status_error; -- 終了ステータス:エラー
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_file_id       IN    VARCHAR2,        --   1.ファイルID(必須)
    iv_file_format   IN    VARCHAR2         --   2.ファイルフォーマット(必須)
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
    cv_prg_name_del    CONSTANT VARCHAR2(100) := 'delete_if_data';   -- プログラム名(IFデータ削除)
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_retcode_if_del  VARCHAR2(1);     -- リターン・コード（IFデータ削除）
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
      ,iv_which   => cv_file_type_out
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
       TO_NUMBER(iv_file_id) -- 1.ファイルID
      ,iv_file_format        -- 2.ファイルフォーマット
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 正常終了以外の場合、ロールバックを発行
      ROLLBACK;
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- ============================================
    -- A-7．IFデータ削除
    -- ============================================
    -- 正常終了/異常終了に関わらず削除
    delete_if_data(
       TO_NUMBER(iv_file_id) -- ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode_if_del -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 削除に失敗した場合
    IF ( lv_retcode_if_del <> cv_status_normal ) THEN
      -- 削除エラーメッセージを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- A-6までの処理が正常終了の場合
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ロールバック
        ROLLBACK;
        -- 終了ステータスをエラーに設定
        lv_retcode := cv_status_error;
      END IF;
    ELSE
      -- 削除が成功した場合はコミット
      COMMIT;
    END IF;
--
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
    -- 共通のログメッセージの出力
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    -- 妥当性エラーの場合
    IF ( gv_validate_err_flag = cv_flag_err_1 ) THEN
      gn_hht_inv_tran_cnt := 0; -- HHT入出庫一時表登録件数
      gn_lot_trx_temp_cnt := 0; -- ロット別取引TEMP登録件数
      gn_warn_cnt         := ( gn_target_cnt - gn_error_cnt ); -- スキップ件数
    -- その他エラーの場合
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt       := 0; -- 対象件数
      gn_hht_inv_tran_cnt := 0; -- HHT入出庫一時表登録件数
      gn_lot_trx_temp_cnt := 0; -- ロット別取引TEMP登録件数
      gn_error_cnt        := 1; -- エラー件数
      gn_warn_cnt         := 0; -- スキップ件数
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
    --HHT入出庫一時表登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10671
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_hht_inv_tran_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --ロット別取引TEMP登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10672
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_lot_trx_temp_cnt)
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
      lv_message_code := cv_normal_msg;
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
END XXCOI003A18C;
/
