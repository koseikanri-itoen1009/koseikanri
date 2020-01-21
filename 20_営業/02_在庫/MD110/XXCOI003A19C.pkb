CREATE OR REPLACE PACKAGE BODY APPS.XXCOI003A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCOI003A19C(body)
 * Description      : 出庫依頼CSVアップロード（営業車）
 * MD.050           : 出庫依頼CSVアップロード（営業車） MD050_COI_003_A19
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                                       (A-1)
 *  get_if_data                  IFデータ取得                                   (A-2)
 *  delete_if_data               IFデータ削除                                   (A-3)
 *  divide_item                  アップロードファイル項目分割                   (A-4)
 *  quantity_check               数量チェック                                   (A-5)
 *  err_check                    エラーチェック                                 (A-5)
 *  cre_inv_transactions         入出庫情報の作成                               (A-6)
 *  cre_lot_transactions         ロット別取引明細の作成、ロット別手持数量の変更 (A-7)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/11/15    1.0   T.Nakano         新規作成
 *  2020/01/16    1.1   H.Sasaki         E_本稼動_15992 受入指摘対応（チェック追加：会計期間、数量0）
 *  2020/01/21    1.2   T.Nakano         E_本稼動_16191 出庫依頼アップロード障害対応
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI003A19C'; -- パッケージ名
--
  ct_language           CONSTANT fnd_lookup_values.language%TYPE  := USERENV('LANG'); -- 言語
--
  cv_csv_delimiter            CONSTANT VARCHAR2(1)  := ',';   -- カンマ
  cv_colon                    CONSTANT VARCHAR2(2)  := '：';  -- コロン
  cv_space                    CONSTANT VARCHAR2(2)  := ' ';   -- 半角スペース
  cv_const_y                  CONSTANT VARCHAR2(1)  := 'Y';   -- 'Y'
  cv_const_n                  CONSTANT VARCHAR2(1)  := 'N';   -- 'N'
--
  cv_subinventory_class_1     CONSTANT VARCHAR2(1)  := '1';   -- 保管場所区分:倉庫
--
  cv_location_type_1          CONSTANT VARCHAR2(1)  := '1';   -- ロケーションタイプ:通常
  cv_location_type_2          CONSTANT VARCHAR2(1)  := '2';   -- ロケーションタイプ:優先
-- V1.2 2020/01/21 T.Nakano MOD START --
  cv_location_type_3          CONSTANT VARCHAR2(1)  := '3';   -- ロケーションタイプ:一時保管
  cv_9                        CONSTANT VARCHAR2(1)  := '9';   -- ロケーションタイプ優先のダミー値
  cv_8                        CONSTANT VARCHAR2(1)  := '8';   -- ロケーションタイプ一時保管のダミー値
-- V1.2 2020/01/21 T.Nakano MOD END ----
  cn_slip_no                  CONSTANT NUMBER       := 1;     -- 伝票番号
  cn_invoice_date             CONSTANT NUMBER       := 2;     -- 伝票日付
  cn_outside_base_code        CONSTANT NUMBER       := 3;     -- 出庫側拠点コード
  cn_outside_subinv_code      CONSTANT NUMBER       := 4;     -- 出庫側保管場所
  cn_inside_base_code         CONSTANT NUMBER       := 5;     -- 入庫側拠点コード
  cn_inside_subinv_code       CONSTANT NUMBER       := 6;     -- 入庫側保管場所
  cn_parent_item_code         CONSTANT NUMBER       := 7;     -- 親品目
  cn_child_item_code          CONSTANT NUMBER       := 8;     -- 子品目
  cn_lot                      CONSTANT NUMBER       := 9;     -- 賞味期限
  cn_difference_summary_code  CONSTANT NUMBER       := 10;    -- 固有記号
  cn_location_code            CONSTANT NUMBER       := 11;    -- ロケーション
  cn_case_qty                 CONSTANT NUMBER       := 12;    -- ケース数
  cn_singly_qty               CONSTANT NUMBER       := 13;    -- バラ数
  cn_check_flg                CONSTANT NUMBER       := 14;    -- チェックフラグ
  cn_c_header                 CONSTANT NUMBER       := 14;    -- CSVファイル項目数（取得対象）
  cn_c_header_all             CONSTANT NUMBER       := 14;    -- CSVファイル項目数（全項目）
--
  cn_zero                     CONSTANT NUMBER       := 0;     -- 0
--
  cv_segment1_1               CONSTANT VARCHAR2(1)  := '1';   -- カテゴリコード
  cv_segment1_2               CONSTANT VARCHAR2(1)  := '2';   -- カテゴリコード
  cv_record_type              CONSTANT VARCHAR2(2)  := '30';  -- レコード種別：入出庫
  cv_invoice_type             CONSTANT VARCHAR2(1)  := '1';   -- 伝票区分：倉庫から営業車へ
  cv_invoice_type2            CONSTANT VARCHAR2(1)  := '9';   -- 伝票区分：他拠点へ出庫
  cv_department_flag          CONSTANT VARCHAR2(2)  := '99';  -- 百貨店フラグ：ダミー
  cv_program_div_2            CONSTANT VARCHAR2(1)  := '2';   -- 入出庫ジャーナル処理区分：拠点間倉替
  cv_program_div_5            CONSTANT VARCHAR2(1)  := '5';   -- 入出庫ジャーナル処理区分：その他入出庫（消化VD補充含む）
  cv_transaction_type_20      CONSTANT VARCHAR2(2)  := '20';  -- 取引タイプコード：倉替
  cv_sign_div_0               CONSTANT VARCHAR2(1)  := '0';   -- 符号区分(0:出庫)
  cv_program_div_0            CONSTANT VARCHAR2(1)  := '0';   -- 入出庫ジャーナル処理区分(0:処理対象外)
  cv_status_1                 CONSTANT VARCHAR2(1)  := '1';   -- 処理ステータス(1:処理済)
  cv_status_0                 CONSTANT VARCHAR2(1)  := '0';   -- 処理ステータス(0:未処理)
  cv_source_code              CONSTANT VARCHAR2(12) := 'XXCOI003A19C';  -- ソースコード
--
  cv_column_name1             CONSTANT VARCHAR2(12) :=  '伝票番号';         -- 必須項目名1
  cv_column_name2             CONSTANT VARCHAR2(12) :=  '伝票日付';         -- 必須項目名2
  cv_column_name3             CONSTANT VARCHAR2(24) :=  '出庫側拠点コード'; -- 必須項目名3
  cv_column_name4             CONSTANT VARCHAR2(21) :=  '出庫側保管場所';   -- 必須項目名4
  cv_column_name5             CONSTANT VARCHAR2(24) :=  '入庫側拠点コード'; -- 必須項目名5
  cv_column_name6             CONSTANT VARCHAR2(21) :=  '入庫側保管場所';   -- 必須項目名6
--
  cv_key_data                 CONSTANT VARCHAR2(12) :=  'CSV行数:';         -- キー情報
--
  cv_api_belogin              CONSTANT VARCHAR2(100) := 'GET_BELONGING_BASE';    -- トークン「APIセット内容」
--
  -- 出力タイプ
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';      -- 出力(ユーザメッセージ用出力先)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';         -- ログ(システム管理者用出力先)
--
  -- 書式マスク
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
--
  -- アプリケーション短縮名
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; -- アドオン：在庫領域
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; -- アドオン：販売領域
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; -- 共通のメッセージ
--
  -- プロファイル
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';     -- 在庫組織コード
  cv_goods_product_cls  CONSTANT VARCHAR2(30)  := 'XXCOI1_GOODS_PRODUCT_CLASS';   -- 商品製品区分カテゴリセット名
--
  -- 参照タイプ
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';       -- ファイルアップロードオブジェクト
  cv_type_bargain_class CONSTANT VARCHAR2(30)  := 'XXCOI1_OTHER_BASE_INOUT_CAR';  -- 他拠点営業車入出庫セキュリティマスタ（出庫依頼用）
--
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- メッセージ名
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';   -- スキップ件数メッセージ
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';   -- 在庫組織コード取得エラーメッセージ
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';   -- 在庫組織ID取得エラーメッセージ
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';   -- 業務日付取得エラーメッセージ
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';   -- ファイル名出力メッセージ
  cv_msg_cos_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';   -- ロックエラー
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';   -- ファイルアップロード名称出力メッセージ
  cv_msg_coi_10149      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10149';   -- 入力パラメータ必須チェックエラー
  cv_msg_coi_10212      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10212';   -- 営業車保管場所の取得エラー
  cv_msg_coi_10206      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10206';   -- 保管場所の取得エラー
  cv_msg_coi_10132      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10132';   -- 品目マスタ取得エラー
  cv_msg_coi_10227      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10227';   -- 品目マスタ存在チェックエラーメッセージ
  cv_msg_coi_10276      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10276';   -- 入庫側保管場所取得エラーメッセージ
  cv_msg_coi_10277      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10277';   -- 入庫側拠点取得エラーメッセージ
  cv_msg_coi_10278      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10278';   -- 出庫側保管場所取得エラーメッセージ
  cv_msg_coi_10279      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10279';   -- 出庫側拠点取得エラーメッセージ
  cv_msg_coi_10294      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10294';   -- 入出庫一時表IDエラーメッセージ
  cv_msg_coi_10295      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10295';   -- 画面入力用ヘッダIDエラーメッセージ
  cv_msg_coi_10701      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10701';   -- HHT入出庫一時表登録エラーメッセージ
  cv_msg_coi_10489      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10489';   -- ロット別取引明細作成エラー
  cv_msg_coi_10490      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10490';   -- ロット別手持数量反映エラー
  cv_msg_cos_11294      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';   -- CSVファイル名取得エラー
  cv_msg_cos_00013      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';   -- データ抽出エラーメッセージ
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';   -- データ削除エラーメッセージ
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';   -- ファイルレコード項目数不一致エラーメッセージ
  cv_msg_coi_10593      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10593';   -- 引当可能数算出エラーメッセージメッセージ
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';   -- コンカレント入力パラメータ
  cv_msg_coi_10284      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10284';   -- デフォルト伝票No取得エラーメッセージ
  cv_msg_coi_10665      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10665';   -- 引当済数超過エラーメッセージ
  cv_msg_coi_10680      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10680';   -- 入数取得エラーメッセージ
  cv_msg_coi_10739      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10739';   -- 入庫側メイン倉庫管理対象外エラー
  cv_msg_coi_10740      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10740';   -- 出庫側倉庫管理対象エラー
  cv_msg_coi_10741      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10741';   -- セキュリティマスタ未登録エラー
  cv_msg_coi_10742      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10742';   -- 数量チェックエラーメッセージ
  cv_msg_coi_10743      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10743';   -- ロット別取引明細データ更新エラーメッセージ
  cv_msg_coi_10744      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10744';   -- 出庫側拠点と入庫側拠点の一致エラー
  cv_msg_coi_10745      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10745';   -- ロット別引当可能数量一時表登録エラーメッセージ
  cv_msg_coi_10746      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10746';   -- ロット別引当可能数量一時表更新エラーメッセージ
  cv_msg_coi_10747      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10747';   -- アップロード件数0件メッセージ
  cv_msg_coi_10748      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10748';   -- 登録伝票番号メッセージ
  cv_msg_coi_10749      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10749';   -- 出庫依頼CSVエラーメッセージ
  cv_msg_coi_00010      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00010';   -- APIエラーメッセージ
--
  cv_tkn_cos_11282      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';   -- ファイルアップロードIF
  cv_tkn_coi_10634      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';   -- ファイルアップロードIF
  cv_tkn_cos_10628      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10628';   -- 子品目コード
  cv_tkn_cos_10496      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10496';   -- 親品目コード
--  V1.1 Added START
  cv_msg_coi_10226      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10226';   -- 総本数換算エラー
  cv_msg_coi_00026      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00026';   -- 在庫会計期間ステータス取得エラー
  cv_msg_coi_10231      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10231';   -- 在庫会計期間チェックエラー
--  V1.1 Added END
--
  -- トークン名
  cv_tkn_pro_tok          CONSTANT VARCHAR2(15) := 'PRO_TOK';         -- プロファイル
  cv_tkn_org_code_tok     CONSTANT VARCHAR2(15) := 'ORG_CODE_TOK';    -- 在庫組織コード
  cv_tkn_format_ptn       CONSTANT VARCHAR2(15) := 'FORMAT_PTN';      -- フォーマットパターン
  cv_tkn_file_name        CONSTANT VARCHAR2(15) := 'FILE_NAME';       -- ファイル名
  cv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';           -- テーブル名
  cv_tkn_file_upld_name   CONSTANT VARCHAR2(15) := 'FILE_UPLD_NAME';  -- ファイルアップロード名称
  cv_tkn_key_data         CONSTANT VARCHAR2(15) := 'KEY_DATA';        -- 特定できるキー内容をコメントをつけてセットします。
  cv_tkn_table_name       CONSTANT VARCHAR2(15) := 'TABLE_NAME';      -- テーブル名
  cv_tkn_param            CONSTANT VARCHAR2(15) := 'PARAM';           -- パラメータ名
  cv_tkn_param2           CONSTANT VARCHAR2(15) := 'PARAM2';          -- パラメータ名2
  cv_tkn_param3           CONSTANT VARCHAR2(15) := 'PARAM3';          -- パラメータ名3
  cv_tkn_param4           CONSTANT VARCHAR2(15) := 'PARAM4';          -- パラメータ名4
  cv_tkn_param5           CONSTANT VARCHAR2(15) := 'PARAM5';          -- パラメータ名5
  cv_tkn_param6           CONSTANT VARCHAR2(15) := 'PARAM6';          -- パラメータ名6
  cv_tkn_param7           CONSTANT VARCHAR2(15) := 'PARAM7';          -- パラメータ名7
  cv_tkn_param8           CONSTANT VARCHAR2(15) := 'PARAM8';          -- パラメータ名8
  cv_tkn_param9           CONSTANT VARCHAR2(15) := 'PARAM9';          -- パラメータ名9
  cv_tkn_dept_code        CONSTANT VARCHAR2(15) := 'DEPT_CODE';       -- 拠点コード
  cv_tkn_whouse_code      CONSTANT VARCHAR2(15) := 'WHOUSE_CODE';     -- 保管場所コード
  cv_tkn_item_code        CONSTANT VARCHAR2(15) := 'ITEM_CODE';       -- 品目コード
  cv_tkn_record_type      CONSTANT VARCHAR2(15) := 'RECORD_TYPE';     -- レコード種別
  cv_tkn_invoice_type     CONSTANT VARCHAR2(15) := 'INVOICE_TYPE';    -- 伝票区分
  cv_tkn_department_flag  CONSTANT VARCHAR2(15) := 'DEPARTMENT_FLAG'; -- 百貨店フラグ
  cv_tkn_base_code        CONSTANT VARCHAR2(15) := 'BASE_CODE';       -- 拠点コード
  cv_tkn_code             CONSTANT VARCHAR2(15) := 'CODE';            -- 入庫側コード
  cv_tkn_transaction_id   CONSTANT VARCHAR2(15) := 'TRANSACTION_ID';  -- 取引ID
  cv_tkn_err_msg          CONSTANT VARCHAR2(15) := 'ERR_MSG';         -- エラーメッセージ
  cv_tkn_data             CONSTANT VARCHAR2(15) := 'DATA';            -- データ
  cv_tkn_file_id          CONSTANT VARCHAR2(15) := 'FILE_ID';         -- ファイルID
  cv_tkn_api_name         CONSTANT VARCHAR2(15) := 'API_NAME';        -- API名
--  V1.1 Added START
  cv_tkn_target_date      CONSTANT VARCHAR2(15) := 'TARGET_DATE';     -- 対象日
  cv_tkn_invoice_date     CONSTANT VARCHAR2(15) := 'INVOICE_DATE';    -- 伝票日付
--  V1.1 Added END
--
  -- ダミー値
  cv_dummy_char         CONSTANT VARCHAR2(100) := 'DUMMY99999999';   -- 文字列用ダミー値
  cd_dummy_date         CONSTANT DATE          := TO_DATE( '1900/01/01', 'YYYY/MM/DD' );
                                                                     -- 日付用ダミー値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納用
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;   -- 1次元配列
  g_if_data_tab             g_var_data_ttype;                                     -- 分割用変数
--
  -- ロット情報データ格納用
  TYPE g_lot_info_rtype IS RECORD(
      slip_no                 VARCHAR2(100)                                       -- 伝票番号
     ,invoice_date            xxcoi_lot_transactions.transaction_date%TYPE        -- 伝票日付
     ,csv_no                  NUMBER                                              -- CSVの行数
     ,lot                     xxcoi_lot_transactions.lot%TYPE                     -- ロット（賞味期限）
     ,difference_summary_code xxcoi_lot_transactions.difference_summary_code%TYPE -- 固有記号
     ,location_code           xxcoi_lot_transactions.location_code%TYPE           -- ロケーション
     ,parent_item_id          xxcoi_lot_transactions.parent_item_id%TYPE          -- 親品目ID
     ,parent_item_code        xxcoi_lot_onhand_quantites_v.parent_item_code%TYPE  -- 親品目
     ,child_item_id           xxcoi_lot_transactions.child_item_id%TYPE           -- 子品目ID
     ,child_item_code         xxcoi_lot_onhand_quantites_v.item_code%TYPE         -- 子品目
     ,case_qty                xxcoi_lot_transactions.case_qty%TYPE                -- ケース数
     ,singly_qty              xxcoi_lot_transactions.singly_qty%TYPE              -- バラ数
     ,summary_quantity        xxcoi_lot_transactions.summary_qty%TYPE             -- 取引数量
     ,case_in_quantity        xxcoi_lot_transactions.case_in_qty%TYPE             -- 入数
     ,outside_base_code       xxcoi_lot_transactions.base_code%TYPE               -- 出庫側拠点コード
     ,via_subinv_code         xxcoi_lot_transactions.transfer_subinventory%TYPE   -- 転送先保管場所コード
     ,program_div             xxcoi_hht_ebs_convert_v.program_div%TYPE            -- 入出庫ジャーナル処理区分
     ,consume_vd_flag         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE        -- 消化VD補充対象フラグ
     ,start_subinv_code       xxcoi_lot_transactions.subinventory_code%TYPE       -- 出庫側保管場所コード
     ,transaction_id          xxcoi_lot_transactions.relation_key%TYPE            -- 入出庫一時表ID
     ,inside_warehouse_code   xxcoi_lot_transactions.inside_warehouse_code%TYPE   -- 転送先倉庫
     ,invoice_no              xxcoi_hht_inv_transactions.invoice_no%TYPE          -- 伝票No
    );
  -- ロット情報データレコード配列
  TYPE g_lot_info_ttype IS TABLE OF g_lot_info_rtype INDEX BY BINARY_INTEGER;
--
  -- 入出庫情報データ格納用
  TYPE g_inout_info_rtype IS RECORD(
      slip_no                     VARCHAR2(100)                                             -- 伝票番号
     ,invoice_date                xxcoi_hht_inv_transactions.invoice_date%TYPE              -- 伝票日付
     ,parent_item_id              xxcoi_hht_inv_transactions.inventory_item_id%TYPE         -- 親品目ID
     ,parent_item_code            xxcoi_lot_onhand_quantites_v.parent_item_code%TYPE        -- 親品目
     ,outside_subinv_code         xxcoi_hht_inv_transactions.outside_code%TYPE              -- 出庫側コード
     ,inside_subinv_code          xxcoi_hht_inv_transactions.inside_code%TYPE               -- 入庫側コード
     ,case_qty                    xxcoi_hht_inv_transactions.case_quantity%TYPE             -- ケース数
     ,singly_qty                  xxcoi_hht_inv_transactions.quantity%TYPE                  -- バラ数
     ,case_in_quantity            xxcoi_hht_inv_transactions.case_in_quantity%TYPE          -- 入数
     ,outside_base_code           xxcoi_hht_inv_transactions.base_code%TYPE                 -- 出庫側拠点コード
     ,inside_base_code            xxcoi_hht_inv_transactions.base_code%TYPE                 -- 入庫側拠点コード
     ,chg_start_subinv_code       mtl_secondary_inventories.secondary_inventory_name%TYPE   -- 出庫側保管場所コード（他拠点へ出庫）
     ,chg_via_subinv_code         mtl_secondary_inventories.secondary_inventory_name%TYPE   -- 入庫側保管場所コード（他拠点へ出庫）
     ,chg_start_base_code         mtl_secondary_inventories.attribute7%TYPE                 -- 出庫側拠点コード（他拠点へ出庫）
     ,chg_via_base_code           mtl_secondary_inventories.attribute7%TYPE                 -- 入庫側拠点コード（他拠点へ出庫）
     ,chg_outside_subinv_conv     xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div%TYPE -- 出庫側保管場所変換区分（他拠点へ出庫）
     ,chg_inside_subinv_conv      xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div%TYPE  -- 入庫側保管場所変換区分（他拠点へ出庫）
     ,chg_program_div             xxcoi_hht_ebs_convert_v.program_div%TYPE                  -- 入出庫ジャーナル処理区分（他拠点へ出庫）
     ,chg_consume_vd_flag         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE              -- 消化VD補充対象フラグ（他拠点へ出庫）
     ,chg_item_convert_div        xxcoi_hht_ebs_convert_v.item_convert_div%TYPE             -- 商品振替区分（他拠点へ出庫）
     ,chg_stock_uncheck_list_div  xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE       -- 入庫未確認リスト対象区分（他拠点へ出庫）
     ,chg_stock_balance_list_div  xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE       -- 入庫差異確認リスト対象区分（他拠点へ出庫）
     ,chg_other_base_code         xxcoi_hht_inv_transactions.other_base_code%TYPE           -- 他拠点コード（他拠点へ出庫）
     ,io_start_subinv_code        mtl_secondary_inventories.secondary_inventory_name%TYPE   -- 出庫側保管場所コード（倉庫から営業車へ）
     ,io_via_subinv_code          mtl_secondary_inventories.secondary_inventory_name%TYPE   -- 入庫側保管場所コード（倉庫から営業車へ）
     ,io_start_base_code          mtl_secondary_inventories.attribute7%TYPE                 -- 出庫側拠点コード（倉庫から営業車へ）
     ,io_via_base_code            mtl_secondary_inventories.attribute7%TYPE                 -- 入庫側拠点コード（倉庫から営業車へ）
     ,io_outside_subinv_conv      xxcoi_hht_ebs_convert_v.outside_subinv_code_conv_div%TYPE -- 出庫側保管場所変換区分（倉庫から営業車へ）
     ,io_inside_subinv_conv       xxcoi_hht_ebs_convert_v.inside_subinv_code_conv_div%TYPE  -- 入庫側保管場所変換区分（倉庫から営業車へ）
     ,io_program_div              xxcoi_hht_ebs_convert_v.program_div%TYPE                  -- 入出庫ジャーナル処理区分（倉庫から営業車へ）
     ,io_consume_vd_flag          xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE              -- 消化VD補充対象フラグ（倉庫から営業車へ）
     ,io_item_convert_div         xxcoi_hht_ebs_convert_v.item_convert_div%TYPE             -- 商品振替区分（倉庫から営業車へ）
     ,io_stock_uncheck_list_div   xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE       -- 入庫未確認リスト対象区分（倉庫から営業車へ）
     ,io_stock_balance_list_div   xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE       -- 入庫差異確認リスト対象区分（倉庫から営業車へ）
    );
  -- ロット情報データレコード配列
  TYPE g_inout_info_ttype IS TABLE OF g_inout_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ファイルアップロードIFデータ
  gt_file_line_data_tab     xxccp_common_pkg2.g_file_data_tbl;
  -- ロット情報データ格納配列
  gt_lot_info_tab           g_lot_info_ttype;
  gt_inout_info_tab         g_inout_info_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_inv_org_code       VARCHAR2(100);                              -- 在庫組織コード
  gd_process_date       DATE;                                       -- 業務日付
  gn_inv_org_id         NUMBER;                                     -- 在庫組織ID
  gn_lot_count          NUMBER;                                     -- ロット別取引情報の件数カウント
  gn_inout_count        NUMBER;                                     -- HHT入出庫一時表の件数カウント
  gv_key_data           VARCHAR2(200);                              -- キー情報
  gb_err_flag           BOOLEAN;                                    -- 想定内エラーフラグ
  gb_insert_flg         BOOLEAN;                                    -- 登録フラグ
  gv_check_result       VARCHAR2(1);                                -- チェック結果
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
    ln_dummy                NUMBER; -- ダミー値
    ln_ins_lock_cnt         NUMBER; -- ロック制御テーブル挿入件数
    ln_login_user_id        NUMBER; -- ログインユーザID
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
    ln_dummy          :=  0;                  -- ダミー値
    ln_ins_lock_cnt   :=  0;                  -- ロック制御テーブル登録件数
    ln_login_user_id  :=  fnd_global.user_id; -- ログインユーザID
--
    -- グローバル変数初期化
    gn_inout_count  :=  1;                    -- 入出庫表作成用データレコードの件数
    gn_lot_count    :=  1;                    -- ロット取引作成用データレコードの件数
    gb_insert_flg   :=  TRUE;                 -- 登録フラグ
    gv_check_result :=  cv_const_y;           -- チェック結果
--
    -- 在庫組織コードの取得
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- 取得できない場合
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00005  -- 在庫組織コード取得エラー
                     ,iv_token_name1  =>  cv_tkn_pro_tok
                     ,iv_token_value1 =>  cv_inv_org_code   -- プロファイル：在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 在庫組織IDの取得
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gv_inv_org_code
                     );
    -- 取得できない場合
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00006    -- 在庫組織ID取得エラー
                     ,iv_token_name1  =>  cv_tkn_org_code_tok
                     ,iv_token_value1 =>  gv_inv_org_code     -- 在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_00011 -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント入力パラメータ出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => xxccp_common_pkg.get_msg(
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
      which => FND_FILE.OUTPUT
     ,buff  => xxccp_common_pkg.get_msg(
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
      which =>  FND_FILE.LOG
     ,buff  =>  ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which =>  FND_FILE.OUTPUT
     ,buff  =>  ''
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
    -- ローカル変数初期化
    lt_file_name        := NULL; -- ファイル名
    lt_file_upload_name := NULL; -- ファイルアップロード名称
--
    -- ファイルアップロードIFデータロック
    BEGIN
      SELECT  xfu.file_name   AS file_name      -- ファイル名
      INTO    lt_file_name                      -- ファイル名
      FROM    xxccp_mrp_file_ul_interface  xfu  -- ファイルアップロードIF
      WHERE   xfu.file_id = in_file_id          -- ファイルID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロックが取得できない場合
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_cos
                       ,iv_name         =>  cv_msg_cos_00001  -- ロックエラーメッセージ
                       ,iv_token_name1  =>  cv_tkn_table
                       ,iv_token_value1 =>  cv_tkn_cos_11282  -- ファイルアップロードIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイルアップロード名称情報取得
    BEGIN
      SELECT  flv.meaning   AS file_upload_name -- ファイルアップロード名称
      INTO    lt_file_upload_name               -- ファイルアップロード名称
      FROM    fnd_lookup_values flv             -- クイックコード
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
                       ,iv_token_name1  =>  cv_tkn_key_data
                       ,iv_token_value1 =>  iv_file_format    -- フォーマットパターン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 取得したファイル名、ファイルアップロード名称を出力
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_00028  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_tkn_file_name
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_00028  -- ファイル名出力メッセージ
                   ,iv_token_name1  =>  cv_tkn_file_name
                   ,iv_token_value1 =>  lt_file_name      -- ファイル名
                  )
    );
--
    -- ファイルアップロード名称を出力（ログ）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.LOG
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_10611      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_tkn_file_upld_name
                   ,iv_token_value1 =>  lt_file_upload_name   -- ファイルアップロード名称
                  )
    );
    -- ファイルアップロード名称を出力（出力）
    FND_FILE.PUT_LINE(
      which   =>  FND_FILE.OUTPUT
     ,buff    =>  xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_msg_kbn_coi
                   ,iv_name         =>  cv_msg_coi_10611      -- ファイルアップロード名称出力メッセージ
                   ,iv_token_name1  =>  cv_tkn_file_upld_name
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
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_00013  -- データ抽出エラーメッセージ
                     ,iv_token_name1  =>  cv_tkn_table_name
                     ,iv_token_value1 =>  cv_tkn_cos_11282  -- ファイルアップロードIF
                     ,iv_token_name2  =>  cv_tkn_key_data
                     ,iv_token_value2 =>  NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 抽出行数が2行以上なかった場合
    IF (gt_file_line_data_tab.COUNT < 2) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10747  -- アップロード件数0件メッセージ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_warn_expt;
    END IF;
--
    -- 対象件数を設定（1行目はカラム行のため件数としてカウントしない）
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
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
                       ,iv_token_name1  =>  cv_tkn_table_name
                       ,iv_token_value1 =>  cv_tkn_coi_10634  -- ファイルアップロードIF
                       ,iv_token_name2  =>  cv_tkn_key_data
                       ,iv_token_value2 =>  NULL
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
    -- ローカル変数初期化--
    lv_rec_data  := NULL; -- レコードデータ
--
    -- 項目数チェック
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- 項目数不一致の場合
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cos
                     ,iv_name         =>  cv_msg_cos_11295  -- ファイルレコード項目数不一致エラーメッセージ
                     ,iv_token_name1  =>  cv_tkn_data
                     ,iv_token_value1 =>  lv_rec_data       -- フォーマットパターン
                   );
      ov_errbuf := chr(10) || lv_errmsg;
    END IF;
--
    -- 分割ループ
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     =>  gt_file_line_data_tab(in_file_if_loop_cnt)
                                   ,iv_delim    =>  cv_csv_delimiter
                                   ,in_part_num =>  i
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
   * Procedure Name   : quantity_check
   * Description      : 数量チェック(A-5)
   ***********************************************************************************/
  PROCEDURE quantity_check(
    it_child_item_id              IN  mtl_system_items_b.inventory_item_id%TYPE -- 子品目ID
   ,it_parent_item_id             IN  mtl_system_items_b.inventory_item_id%TYPE -- 親品目ID
   ,it_inout_info                 IN  g_inout_info_rtype                        -- ロット情報データレコード
   ,in_reserved_quantity_req      IN  NUMBER                                    -- 引当依頼数
   ,ov_errbuf                     OUT VARCHAR2                                  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                    OUT VARCHAR2                                  -- リターン・コード             --# 固定 #
   ,ov_errmsg                     OUT VARCHAR2)                                 -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'quantity_check'; -- プログラム名
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
    ln_dummy                        NUMBER;         -- ダミー
    ln_case_qty                     NUMBER;         -- ケース数
    ln_singly_qty                   NUMBER;         -- バラ数
    lv_errbuf_pkg                   VARCHAR2(5000); -- エラー・メッセージ（共通関数戻り値用）
    ln_summary_qty                  NUMBER;         -- 取引数量
    ln_reserved_quantity_req        NUMBER;         -- 引当依頼数
    ln_case_in_qty                  NUMBER;         -- ケース入数
    ln_child_item_id                NUMBER;         -- 子品目ID
    ln_parent_item_id               NUMBER;         -- 親品目ID
    lt_primary_uom_code             xxcoi_txn_enable_item_info_v.primary_uom_code%TYPE; -- 基準単位コード
    lv_goods_product_class          VARCHAR2(100);  -- プロファイル：カテゴリセット名
--
    -- *** ローカル・カーソル ***
    -- 親品目に紐づくロット情報の取得カーソル
    CURSOR get_lot_info_cur(
      iv_outside_base_code        xxcoi_lot_onhand_quantites_v.base_code%TYPE
     ,iv_outside_subinv_code      xxcoi_lot_onhand_quantites_v.subinventory_code%TYPE
     ,iv_parent_item_id           mtl_system_items_b.inventory_item_id%TYPE
     ,id_invoice_date             DATE )
    IS
      SELECT  xloq.location_code            AS location_code            -- ロケーションコード
             ,xloq.lot                      AS lot                      -- ロット
             ,xloq.difference_summary_code  AS difference_summary_code  -- 固有記号
             ,xaiciv.parent_item_id         AS parent_item_id           -- 親品目ID
             ,xaiciv.parent_item_code       AS parent_item_code         -- 親品目
             ,xaiciv.child_item_id          AS item_id                  -- 子品目ID
             ,xaiciv.child_item_code        AS item_code                -- 子品目
-- V1.2 2020/01/21 T.Nakano MOD START --
             -- 引き当てる優先順位は、ロケーションタイプが（優先）、（通常・一時保管）となるため、
             -- 優先とそれ以外で設定する数値を分ける
             --,xwlmv.location_type           AS location_type            -- ロケーションタイプ
             ,DECODE(xwlmv.location_type, cv_location_type_2, cv_9, cv_8)
                                            AS location_type            -- ロケーションタイプ
-- V1.2 2020/01/21 T.Nakano MOD END --
-- V1.2 2020/01/21 T.Nakano ADD START --
             ,xnwl.priority                 AS priority                 -- 優先順位
-- V1.2 2020/01/21 T.Nakano ADD END --
             ,xaiciv.primary_uom_code       AS primary_uom_code         -- 基準単位コード
      FROM    (
                SELECT  msib.inventory_item_id      AS child_item_id
                       ,msib.segment1               AS child_item_code
                       ,msib_p.inventory_item_id    AS parent_item_id
                       ,msib_p.segment1             AS parent_item_code
                       ,xteiiv.primary_uom_code     AS primary_uom_code
                FROM    ic_item_mst_b          iimb
                       ,xxcmn_item_mst_b       ximb
                       ,mtl_system_items_b     msib
                       ,xxcmm_system_items_b   xsib
                       ,mtl_system_items_b     msib_p
                       ,ic_item_mst_b          iimb_p
                       ,xxcoi_txn_enable_item_info_v  xteiiv
                       ,mtl_category_sets_tl          mcst
                       ,mtl_category_sets_b           mcsb
                       ,mtl_categories_b              mcb
                       ,mtl_item_categories           mic
                WHERE   msib_p.inventory_item_id  = iv_parent_item_id
                AND     iimb.item_id              = ximb.item_id
                AND     iimb.item_no              = xsib.item_code
                AND     iimb.item_no              = msib.segment1
                AND     msib.organization_id      = gn_inv_org_id
                AND     gd_process_date           BETWEEN ximb.start_date_active AND ximb.end_date_active
                AND     ximb.parent_item_id       = iimb_p.item_id
                AND     iimb_p.item_no            = msib_p.segment1
                AND     msib.organization_id      = msib_p.organization_id
                AND     xsib.item_status          IN ( '30' ,'40' ,'50' )
                AND     mcst.category_set_name    = lv_goods_product_class
                AND     mcst.language             = ct_language
                AND     mcsb.category_set_id      = mcst.category_set_id
                AND     mcb.structure_id          = mcsb.structure_id
                AND     mcb.segment1              IN ( cv_segment1_1, cv_segment1_2 )
                AND     mic.category_id           = mcb.category_id
                AND     mic.inventory_item_id     = xteiiv.inventory_item_id
                AND     mic.organization_id       = xteiiv.organization_id
                AND     TO_CHAR(id_invoice_date, cv_date_format)
                                                  BETWEEN TO_CHAR(xteiiv.start_date_active, cv_date_format)
                                                  AND     TO_CHAR(NVL(xteiiv.end_date_active, id_invoice_date), cv_date_format)
                AND     mic.inventory_item_id     = msib_p.inventory_item_id
              )                               xaiciv  -- 在庫調整情報画面_子品目ビュー_簡易版
             ,xxcoi_lot_onhand_quantites      xloq    -- ロット別手持数量
             ,xxcoi_warehouse_location_mst_v  xwlmv   -- 倉庫ロケーションマスタビュー
-- V1.2 2020/01/21 T.Nakano ADD START --
             ,xxcoi_mst_warehouse_location    xnwl    -- 倉庫ロケーションマスタ
-- V1.2 2020/01/21 T.Nakano ADD END --
      WHERE   xaiciv.child_item_id    = xloq.child_item_id
      AND     xloq.base_code          = iv_outside_base_code
      AND     xloq.subinventory_code  = iv_outside_subinv_code
      AND     xloq.organization_id    = gn_inv_org_id
      AND     xwlmv.organization_id   = xloq.organization_id
      AND     xwlmv.base_code         = xloq.base_code
      AND     xwlmv.subinventory_code = xloq.subinventory_code
      AND     xwlmv.location_code     = xloq.location_code
-- V1.2 2020/01/21 T.Nakano MOD START --
      --AND     xwlmv.location_type     IN (cv_location_type_1, cv_location_type_2)
      AND     xwlmv.location_type     IN (cv_location_type_1, cv_location_type_2, cv_location_type_3)
      AND     xwlmv.warehouse_location_id = xnwl.warehouse_location_id
-- V1.2 2020/01/21 T.Nakano MOD END --
    ;
--
    -- 一時表に格納した引当可能数量の取得カーソル
    CURSOR get_lot_temp_cur(
      iv_child_item_id            mtl_system_items_b.inventory_item_id%TYPE
     ,iv_parent_item_id           mtl_system_items_b.inventory_item_id%TYPE
     ,iv_lot                      xxcoi_lot_onhand_quantites_v.lot%TYPE
     ,iv_difference_summary_code  xxcoi_lot_onhand_quantites_v.difference_summary_code%TYPE
     ,iv_location_code            xxcoi_lot_onhand_quantites_v.location_code%TYPE
     ,iv_subinv_code              mtl_secondary_inventories.secondary_inventory_name%TYPE  )
    IS
      SELECT  xtlr.location_code            AS location_code            -- ロケーションコード
             ,xtlr.lot                      AS lot                      -- ロット
             ,xtlr.difference_summary_code  AS difference_summary_code  -- 固有記号
             ,xtlr.parent_item_id           AS parent_item_id           -- 親品目ID
             ,xtlr.parent_item_code         AS parent_item_code         -- 親品目
             ,xtlr.child_item_id            AS item_id                  -- 子品目ID
             ,xtlr.child_item_code          AS item_code                -- 子品目
             ,xtlr.case_in_qty              AS case_in_qty              -- 入数
             ,xtlr.reserved_quantity        AS reserved_quantity        -- 引当可能数
      FROM    xxcoi_tmp_lot_reserve_qty xtlr    -- ロット別引当可能数量一時表
      WHERE   (   iv_lot    IS NULL
              OR  xtlr.lot  = iv_lot  )
      AND     (   iv_difference_summary_code    IS NULL
              OR  xtlr.difference_summary_code  = iv_difference_summary_code  )
      AND     (   iv_location_code    IS NULL
              OR  xtlr.location_code  = iv_location_code  )
      AND     xtlr.subinventory_code  = iv_subinv_code
      AND     xtlr.child_item_id      = NVL(iv_child_item_id, xtlr.child_item_id)
      AND     xtlr.parent_item_id     = iv_parent_item_id
      AND     xtlr.reserved_quantity  > cn_zero
      ORDER BY  xtlr.location_type  DESC
               ,xtlr.lot            ASC
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,xtlr.priority       ASC
-- V1.2 2020/01/21 T.Nakano ADD END --
    ;
--
    -- *** ローカル・レコード ***
    get_lot_info_rec  get_lot_info_cur%ROWTYPE;
    get_lot_temp_rec  get_lot_temp_cur%ROWTYPE;
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
    lv_goods_product_class    :=  FND_PROFILE.VALUE(cv_goods_product_cls);
    lt_primary_uom_code       :=  NULL;
--
    -- 出庫側保管場所の引当可能ロットの情報を一時表へ格納する
    OPEN get_lot_info_cur(
      iv_outside_base_code    =>  it_inout_info.chg_start_base_code
     ,iv_outside_subinv_code  =>  it_inout_info.chg_start_subinv_code
     ,iv_parent_item_id       =>  it_inout_info.parent_item_id
     ,id_invoice_date         =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
    );
--
    <<get_lot_info_loop>>
    LOOP
      -- レコード読込
      FETCH get_lot_info_cur INTO get_lot_info_rec;
--
      -- レコードが取得できなければループを抜ける
      IF get_lot_info_cur%NOTFOUND THEN
        EXIT;
      END IF;
--
      -- 基準単位コードを保持
      lt_primary_uom_code :=  get_lot_info_rec.primary_uom_code;
--
      BEGIN
--
        -- カーソルから取得した品目、ロット情報でテーブルを検索する
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_tmp_lot_reserve_qty xtlr
        WHERE   xtlr.location_code            = get_lot_info_rec.location_code
        AND     xtlr.lot                      = get_lot_info_rec.lot
        AND     xtlr.difference_summary_code  = get_lot_info_rec.difference_summary_code
        AND     xtlr.child_item_id            = get_lot_info_rec.item_id
        AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 一致するデータが無い（未登録のロット）であれば、一時表にデータを登録する
--
          -- 引当可能数の取得
          -- 変数の初期化
          ln_case_in_qty  :=  0;
          ln_case_qty     :=  0;
          ln_singly_qty   :=  0;
          ln_summary_qty  :=  0;
          lv_errbuf_pkg   :=  NULL;
          lv_retcode      :=  NULL;
          lv_errmsg       :=  NULL;
--
          xxcoi_common_pkg.get_reserved_quantity(
            in_inv_org_id     => gn_inv_org_id                              -- 在庫組織ID
           ,iv_base_code      => it_inout_info.chg_start_base_code          -- 拠点コード
           ,iv_subinv_code    => it_inout_info.chg_start_subinv_code        -- 保管場所コード
           ,iv_loc_code       => get_lot_info_rec.location_code             -- ロケーションコード
           ,in_child_item_id  => get_lot_info_rec.item_id                   -- 子品目ID
           ,iv_lot            => get_lot_info_rec.lot                       -- ロット(賞味期限)
           ,iv_diff_sum_code  => get_lot_info_rec.difference_summary_code   -- 固有記号
           ,on_case_in_qty    => ln_case_in_qty                             -- 入数
           ,on_case_qty       => ln_case_qty                                -- ケース数
           ,on_singly_qty     => ln_singly_qty                              -- バラ数
           ,on_summary_qty    => ln_summary_qty                             -- 取引数量
           ,ov_errbuf         => lv_errbuf_pkg                              -- エラーメッセージ
           ,ov_retcode        => lv_retcode                                 -- リターン・コード(0:正常、2:エラー)
           ,ov_errmsg         => lv_errmsg                                  -- ユーザー・エラーメッセージ
          );
--
          -- リターンコードが'0'（正常）以外の場合はエラー
          IF ( lv_retcode <> cv_status_normal ) THEN
            -- 引当可能数算出エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10593  -- 引当可能数算出エラー
                           ,iv_token_name1  =>  cv_tkn_key_data
                           ,iv_token_value1 =>  gv_key_data || gn_inout_count  -- キー情報
                           ,iv_token_name2  =>  cv_tkn_err_msg
                           ,iv_token_value2 =>  lv_errmsg         -- エラーメッセージ
                         );
            RAISE global_process_expt;
--
          ELSE
            -- 数量が正常に取得できた場合は登録処理を実施
            BEGIN
              INSERT INTO xxcoi_tmp_lot_reserve_qty(
                subinventory_code         -- 保管場所コード
               ,base_code                 -- 拠点コード
               ,parent_item_id            -- 親品目ID
               ,parent_item_code          -- 親品目
               ,child_item_id             -- 子品目ID
               ,child_item_code           -- 子品目
               ,lot                       -- ロット
               ,location_code             -- ロケーションコード
               ,difference_summary_code   -- 固有記号
               ,location_type             -- ロケーションタイプ
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,priority                  -- 優先順位
-- V1.2 2020/01/21 T.Nakano ADD END --
               ,case_in_qty               -- 入数
               ,reserved_quantity)        -- 引当可能数
              VALUES(
                it_inout_info.chg_start_subinv_code           -- 保管場所コード
               ,it_inout_info.chg_start_base_code             -- 拠点コード
               ,get_lot_info_rec.parent_item_id               -- 親品目ID
               ,get_lot_info_rec.parent_item_code             -- 親品目
               ,get_lot_info_rec.item_id                      -- 子品目ID
               ,get_lot_info_rec.item_code                    -- 子品目
               ,get_lot_info_rec.lot                          -- ロット
               ,get_lot_info_rec.location_code                -- ロケーションコード
               ,get_lot_info_rec.difference_summary_code      -- 固有記号
               ,get_lot_info_rec.location_type                -- ロケーションタイプ
-- V1.2 2020/01/21 T.Nakano ADD START --
               ,get_lot_info_rec.priority                     -- 優先順位
-- V1.2 2020/01/21 T.Nakano ADD END --
               ,ln_case_in_qty                                -- 入数
               ,ln_summary_qty                                -- 引当可能数
              )
              ;
            EXCEPTION
              WHEN OTHERS THEN
                -- エラーメッセージの取得
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_coi
                             , iv_name         => cv_msg_coi_10745
                             , iv_token_name1  => cv_tkn_err_msg
                             , iv_token_value1 => SQLERRM
                             );
                RAISE global_process_expt;
            END;
--
          END IF;
--
      END;
--
    END LOOP get_lot_info_loop;
--
    IF ( get_lot_info_cur%ISOPEN ) THEN
      CLOSE get_lot_info_cur;
    END IF;
--
    -- 一時表に登録したデータを元に引当数量をチェックする
    -- 変数の初期化
    ln_reserved_quantity_req  :=  0;
--
    -- 親品目IDを設定
    ln_parent_item_id :=  it_parent_item_id;
--
    -- 子品目が設定されていれば、子品目IDを設定
    ln_child_item_id  :=  NULL;
    IF it_child_item_id IS NOT NULL THEN
      ln_child_item_id  :=  it_child_item_id;
    END IF;
--
    -- 引当依頼を設定
    ln_reserved_quantity_req  :=  in_reserved_quantity_req;
--
    -- 一時表に格納した引当可能数量の取得
    OPEN get_lot_temp_cur(
      iv_child_item_id            =>  ln_child_item_id
     ,iv_parent_item_id           =>  ln_parent_item_id
     ,iv_lot                      =>  g_if_data_tab(cn_lot)
     ,iv_difference_summary_code  =>  g_if_data_tab(cn_difference_summary_code)
     ,iv_location_code            =>  g_if_data_tab(cn_location_code)
     ,iv_subinv_code              =>  it_inout_info.chg_start_subinv_code
    );
--
    <<get_lot_temp_loop>>
    LOOP
      -- レコード読込
      FETCH get_lot_temp_cur INTO get_lot_temp_rec;
--
      -- レコードが取得できない場合は、引当可能数が不足しているため、数量エラーとする
--
      IF get_lot_temp_cur%NOTFOUND THEN
        IF g_if_data_tab(cn_child_item_code) IS NOT NULL THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10742
                         ,iv_token_name1  =>  cv_tkn_param
                         ,iv_token_value1 =>  cv_tkn_cos_10628
                         ,iv_token_name2  =>  cv_tkn_item_code
                         ,iv_token_value2 =>  g_if_data_tab(cn_child_item_code)
                         ,iv_token_name3  =>  cv_tkn_data
                         ,iv_token_value3 =>  TO_CHAR(ln_reserved_quantity_req) || lt_primary_uom_code
                       );
        ELSE
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10742
                         ,iv_token_name1  =>  cv_tkn_param
                         ,iv_token_value1 =>  cv_tkn_cos_10496
                         ,iv_token_name2  =>  cv_tkn_item_code
                         ,iv_token_value2 =>  g_if_data_tab(cn_parent_item_code)
                         ,iv_token_name3  =>  cv_tkn_data
                         ,iv_token_value3 =>  TO_CHAR(ln_reserved_quantity_req) || lt_primary_uom_code
                       );
        END IF;
--
        RAISE global_process_expt;
      END IF;
--
      -- テーブル型変数にロットの情報を保存する
      gt_lot_info_tab(gn_lot_count).slip_no                   :=  it_inout_info.slip_no;                    -- 伝票番号
      gt_lot_info_tab(gn_lot_count).invoice_date              :=  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format);
                                                                                                            -- 伝票日付
      gt_lot_info_tab(gn_lot_count).csv_no                    :=  gn_inout_count;                           -- CSVの行数
      gt_lot_info_tab(gn_lot_count).lot                       :=  get_lot_temp_rec.lot;                     -- ロット（賞味期限）
      gt_lot_info_tab(gn_lot_count).difference_summary_code   :=  get_lot_temp_rec.difference_summary_code; -- 固有記号
      gt_lot_info_tab(gn_lot_count).location_code             :=  get_lot_temp_rec.location_code;           -- ロケーション
      gt_lot_info_tab(gn_lot_count).parent_item_id            :=  get_lot_temp_rec.parent_item_id;          -- 親品目ID
      gt_lot_info_tab(gn_lot_count).parent_item_code          :=  get_lot_temp_rec.parent_item_code;        -- 親品目
      gt_lot_info_tab(gn_lot_count).child_item_id             :=  get_lot_temp_rec.item_id;                 -- 子品目ID
      gt_lot_info_tab(gn_lot_count).child_item_code           :=  get_lot_temp_rec.item_code;               -- 子品目
      gt_lot_info_tab(gn_lot_count).case_in_quantity          :=  get_lot_temp_rec.case_in_qty;             -- 入数
--
      -- 倉替（CHANGE）
      gt_lot_info_tab(gn_lot_count).outside_base_code         :=  it_inout_info.chg_start_base_code;        -- 出庫側拠点コード（他拠点へ出庫）
      gt_lot_info_tab(gn_lot_count).program_div               :=  it_inout_info.chg_program_div;            -- 入出庫ジャーナル処理区分（他拠点へ出庫）
      gt_lot_info_tab(gn_lot_count).consume_vd_flag           :=  it_inout_info.chg_consume_vd_flag;        -- 消化VD補充対象フラグ（他拠点へ出庫）
      gt_lot_info_tab(gn_lot_count).start_subinv_code         :=  it_inout_info.chg_start_subinv_code;      -- 出庫側保管場所（他拠点へ出庫）
      gt_lot_info_tab(gn_lot_count).via_subinv_code           :=  it_inout_info.chg_via_subinv_code;        -- 入庫側保管場所（他拠点へ出庫）
      gt_lot_info_tab(gn_lot_count).inside_warehouse_code     :=  it_inout_info.io_via_subinv_code;         -- 転送先倉庫
--
      -- 引当可能数が引当したい個数に達しているかをチェック
      IF  ln_reserved_quantity_req  <=  get_lot_temp_rec.reserved_quantity  THEN
        -- ロット別取引明細登録用にケース数とバラ数と取引数量を記録する
--
        -- 入数が0の場合は0除算になるので除算をしない
        IF get_lot_temp_rec.case_in_qty <> cn_zero THEN
          -- ケース数の換算
          gt_lot_info_tab(gn_lot_count).case_qty    :=  ( ln_reserved_quantity_req - MOD( ln_reserved_quantity_req, get_lot_temp_rec.case_in_qty ) ) / get_lot_temp_rec.case_in_qty;
          -- バラ数の換算
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  MOD( ln_reserved_quantity_req, get_lot_temp_rec.case_in_qty );
        ELSE
          -- ケース数の換算
          gt_lot_info_tab(gn_lot_count).case_qty    :=  0;
          -- バラ数の換算
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  ln_reserved_quantity_req;
        END IF;
        -- 取引数量の設定
        gt_lot_info_tab(gn_lot_count).summary_quantity  :=  ln_reserved_quantity_req;
--
        -- 以後のレコードで同一ロットを引き当てる可能性があるため、今回引き当てた個数を一時表の引当可能数から減らす
        BEGIN
--
          UPDATE  xxcoi_tmp_lot_reserve_qty   xtlr
          SET     xtlr.reserved_quantity        = get_lot_temp_rec.reserved_quantity - ln_reserved_quantity_req
          WHERE   xtlr.location_code            = get_lot_temp_rec.location_code
          AND     xtlr.lot                      = get_lot_temp_rec.lot
          AND     xtlr.difference_summary_code  = get_lot_temp_rec.difference_summary_code
          AND     xtlr.child_item_id            = get_lot_temp_rec.item_id
          AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10746
                           ,iv_token_name1  =>  cv_tkn_err_msg
                           ,iv_token_value1 =>  SQLERRM
                         );
            RAISE global_process_expt;
        END;
--
        -- 次のロット情報を作成するためカウントを上げる
        gn_lot_count  :=  gn_lot_count + 1;
--
        -- 引当可能数が足りたため、ループを抜ける
        EXIT;
--
      ELSE
        -- 引当可能数が足りない場合は、そのロットの引当可能数を全て引き当てる
--
        -- 入数が0の場合は0除算になるので除算をしない
        IF get_lot_temp_rec.case_in_qty <> cn_zero THEN
          -- ケース数の換算
          gt_lot_info_tab(gn_lot_count).case_qty    :=  ( get_lot_temp_rec.reserved_quantity - MOD( get_lot_temp_rec.reserved_quantity, get_lot_temp_rec.case_in_qty ) ) / get_lot_temp_rec.case_in_qty;
          -- バラ数の換算
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  MOD( get_lot_temp_rec.reserved_quantity, get_lot_temp_rec.case_in_qty );
        ELSE
          -- ケース数の換算
          gt_lot_info_tab(gn_lot_count).case_qty    :=  0;
          -- バラ数の換算
          gt_lot_info_tab(gn_lot_count).singly_qty  :=  get_lot_temp_rec.reserved_quantity;
        END IF;
        -- 取引数量の設定
        gt_lot_info_tab(gn_lot_count).summary_quantity  :=  get_lot_temp_rec.reserved_quantity;
--
        -- 次のロット情報を作成するためカウントを上げる
        gn_lot_count  :=  gn_lot_count + 1;
--
        -- 引き当てたい個数から、今のロットで引き当てられた個数を引く
        ln_reserved_quantity_req  :=  ln_reserved_quantity_req - get_lot_temp_rec.reserved_quantity;
--
        -- 以後のレコードで同一ロットを引き当てる可能性があるため、今回引き当てた個数を一時表の引当可能数から減らす
        -- ※全て引き当てているため、0になる
        BEGIN
--
          UPDATE  xxcoi_tmp_lot_reserve_qty   xtlr
          SET     xtlr.reserved_quantity        = 0
          WHERE   xtlr.location_code            = get_lot_temp_rec.location_code
          AND     xtlr.lot                      = get_lot_temp_rec.lot
          AND     xtlr.difference_summary_code  = get_lot_temp_rec.difference_summary_code
          AND     xtlr.child_item_id            = get_lot_temp_rec.item_id
          AND     xtlr.subinventory_code        = it_inout_info.chg_start_subinv_code
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_msg_kbn_coi
                           ,iv_name         =>  cv_msg_coi_10746
                           ,iv_token_name1  =>  cv_tkn_err_msg
                           ,iv_token_value1 =>  SQLERRM
                         );
            RAISE global_process_expt;
        END;
--
      END IF;
--
    END LOOP get_lot_temp_loop;
--
    IF ( get_lot_temp_cur%ISOPEN ) THEN
      CLOSE get_lot_temp_cur;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      IF ( get_lot_info_cur%ISOPEN ) THEN
        CLOSE get_lot_info_cur;
      END IF;
--
      IF ( get_lot_temp_cur%ISOPEN ) THEN
        CLOSE get_lot_temp_cur;
      END IF;
--
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END quantity_check;
--
    /**********************************************************************************
   * Procedure Name   : err_check
   * Description      : エラーチェック(A-5)
   ***********************************************************************************/
  PROCEDURE err_check(
    in_file_if_loop_cnt   IN  NUMBER    --   IFループカウンタ
   ,ov_errbuf             OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_check'; -- プログラム名
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
    ln_dummy                        NUMBER;                                                             -- ダミー
    lt_base_code                    xxcoi_storage_information.base_code%TYPE;                           -- 拠点コード
    lt_inside_warehouse_flag        xxcoi_subinventory_info_v.warehouse_flag%TYPE;                      -- 入庫側倉庫の倉庫管理対象区分
    lt_outside_warehouse_flag       xxcoi_subinventory_info_v.warehouse_flag%TYPE;                      -- 出庫側倉庫の倉庫管理対象区分
    lt_parent_item_code             mtl_system_items_b.segment1%TYPE;                                   -- 親品目
    lt_parent_item_id               mtl_system_items_b.inventory_item_id%TYPE;                          -- 親品目ID
    lt_child_item_id                mtl_system_items_b.inventory_item_id%TYPE;                          -- 子品目ID
    lv_err_column                   VARCHAR2(100);                                                      -- 必須エラーの項目名
    lv_errbuf2                      VARCHAR2(5000);                                                     -- エラー・メッセージ（変換関数戻り値用）
    ln_reserved_quantity_req        NUMBER;                                                             -- 引当依頼数
    ln_parent_case_in_qty           NUMBER;                                                             -- 親のケース入数
    ln_child_case_in_qty            NUMBER;                                                             -- 子のケース入数
    lt_chg_start_subinv_code        xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- 出庫側保管場所コード（他拠点へ出庫）
    lt_chg_via_subinv_code          xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- 入庫側保管場所コード（他拠点へ出庫）
    lt_chg_start_base_code          xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- 出庫側拠点コード（他拠点へ出庫）
    lt_chg_via_base_code            xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- 入庫側拠点コード（他拠点へ出庫）
    lt_chg_outside_subinv_conv      xxcoi.xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- 出庫側保管場所変換区分（他拠点へ出庫）
    lt_chg_inside_subinv_conv       xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- 入庫側保管場所変換区分（他拠点へ出庫）
    lt_chg_program_div              xxcoi.xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- 入出庫ジャーナル処理区分（他拠点へ出庫）
    lt_chg_consume_vd_flag          xxcoi.xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- 消化VD補充対象フラグ（他拠点へ出庫）
    lt_chg_item_convert_div         xxcoi.xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- 商品振替区分（他拠点へ出庫）
    lt_chg_stock_uncheck_list_div   xxcoi.xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- 入庫未確認リスト対象区分（他拠点へ出庫）
    lt_chg_stock_balance_list_div   xxcoi.xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- 入庫差異確認リスト対象区分（他拠点へ出庫）
    lt_io_start_subinv_code         xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- 出庫側保管場所コード（倉庫から営業車へ）
    lt_io_via_subinv_code           xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;           -- 入庫側保管場所コード（倉庫から営業車へ）
    lt_io_start_base_code           xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- 出庫側拠点コード（倉庫から営業車へ）
    lt_io_via_base_code             xxcoi.xxcoi_hht_inv_transactions.outside_base_code%TYPE;            -- 入庫側拠点コード（倉庫から営業車へ）
    lt_io_outside_subinv_conv       xxcoi.xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- 出庫側保管場所変換区分（倉庫から営業車へ）
    lt_io_inside_subinv_conv        xxcoi.xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;  -- 入庫側保管場所変換区分（倉庫から営業車へ）
    lt_io_program_div               xxcoi.xxcoi_hht_inv_transactions.hht_program_div%TYPE;              -- 入出庫ジャーナル処理区分（倉庫から営業車へ）
    lt_io_consume_vd_flag           xxcoi.xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;              -- 消化VD補充対象フラグ（倉庫から営業車へ）
    lt_io_item_convert_div          xxcoi.xxcoi_hht_inv_transactions.item_convert_div%TYPE;             -- 商品振替区分（倉庫から営業車へ）
    lt_io_stock_uncheck_list_div    xxcoi.xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;       -- 入庫未確認リスト対象区分（倉庫から営業車へ）
    lt_io_stock_balance_list_div    xxcoi.xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;       -- 入庫差異確認リスト対象区分（倉庫から営業車へ）
    lt_io_item_convert_div_d        xxcoi_hht_ebs_convert_v.item_convert_div%TYPE;                      -- 商品振替区分
    lt_io_stock_uncheck_list_div_d  xxcoi_hht_ebs_convert_v.stock_uncheck_list_div%TYPE;                -- 入庫未確認リスト対象区分
    lt_io_stock_balance_list_div_d  xxcoi_hht_ebs_convert_v.stock_balance_list_div%TYPE;                -- 入庫差異確認リスト対象区分
    lt_io_consume_vd_flag_d         xxcoi_hht_ebs_convert_v.consume_vd_flag%TYPE;                       -- 消化VD補充対象フラグ
    -- 以下は共通関数の戻り値を受け取るためのダミー変数(登録には使用しない)
    lt_outside_business_low_type    xxcmm_cust_accounts.business_low_type%TYPE;                         -- 出庫側業態小分類
    lt_inside_business_low_type     xxcmm_cust_accounts.business_low_type%TYPE;                         -- 入庫側業態小分類
    lt_outside_cust_code            xxcoi_hht_inv_transactions.outside_code%TYPE;                       -- 出庫側顧客コード
    lt_inside_cust_code             xxcoi_hht_inv_transactions.inside_code%TYPE;                        -- 入庫側顧客コード
    lt_outside_subinv_div           mtl_secondary_inventories.attribute5%TYPE;                          -- 出庫側棚卸対象
    lt_inside_subinv_div            mtl_secondary_inventories.attribute5%TYPE;                          -- 入庫側棚卸対象
--  V1.1 Added START
    lb_org_acct_period_flg          BOOLEAN;                                                            --  在庫会計期間のチェック結果
--  V1.1 Added END
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
    -- ローカル変数の初期化
    lv_errbuf :=  NULL;
--
    -- ============================================
    -- A-4．アップロードファイル項目分割
    -- ============================================
    divide_item(
       in_file_if_loop_cnt -- IFループカウンタ
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- チェックフラグが立っていれば、登録フラグをFALSEに設定する
    IF g_if_data_tab(cn_check_flg) = cv_const_y THEN
      gb_insert_flg  :=  FALSE;
    END IF;
--
    -- 必須項目のチェック
    IF    g_if_data_tab(cn_slip_no)             IS NULL
      OR  g_if_data_tab(cn_invoice_date)        IS NULL
      OR  g_if_data_tab(cn_outside_base_code)   IS NULL
      OR  g_if_data_tab(cn_outside_subinv_code) IS NULL
      OR  g_if_data_tab(cn_inside_base_code)    IS NULL
      OR  g_if_data_tab(cn_inside_subinv_code)  IS NULL
    THEN
      -- 必須項目がNULLの場合
      IF g_if_data_tab(cn_slip_no) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name1;
        ELSE
          lv_err_column :=  cv_column_name1;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_invoice_date) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name2;
        ELSE
          lv_err_column :=  cv_column_name2;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_outside_base_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name3;
        ELSE
          lv_err_column :=  cv_column_name3;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_outside_subinv_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name4;
        ELSE
          lv_err_column :=  cv_column_name4;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_inside_base_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name5;
        ELSE
          lv_err_column :=  cv_column_name5;
        END IF;
      END IF;
--
      IF g_if_data_tab(cn_inside_subinv_code) IS NULL THEN
        IF lv_err_column IS NOT NULL THEN
          lv_err_column := lv_err_column || cv_csv_delimiter || cv_column_name6;
        ELSE
          lv_err_column :=  cv_column_name6;
        END IF;
      END IF;
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10149
                     ,iv_token_name1  =>  cv_tkn_param
                     ,iv_token_value1 =>  lv_err_column
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 出庫側拠点コードと入庫側拠点コードのチェック
    IF g_if_data_tab(cn_outside_base_code) = g_if_data_tab(cn_inside_base_code) THEN
      -- 拠点コードが一致していたらエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10744
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 品目マスタのチェック
    -- 親品目が指定されている場合
    IF g_if_data_tab(cn_parent_item_code) IS NOT NULL THEN
--
      lt_parent_item_code :=  g_if_data_tab(cn_parent_item_code);
--
      BEGIN
--
        ln_parent_case_in_qty :=  0;
--
        SELECT  msib.inventory_item_id
               ,NVL(TO_NUMBER(iimb.attribute11), 0)
        INTO    lt_parent_item_id
               ,ln_parent_case_in_qty
        FROM    mtl_system_items_b  msib
               ,ic_item_mst_b       iimb
        WHERE   msib.organization_id  = gn_inv_org_id
        AND     msib.segment1         = g_if_data_tab(cn_parent_item_code)
        AND     iimb.item_no          = msib.segment1
        ;
--
        -- 入数がNULLか0ならエラー
        IF ln_parent_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_parent_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        ln_reserved_quantity_req  :=  ( NVL(TO_NUMBER(g_if_data_tab(cn_case_qty)), 0) * ln_parent_case_in_qty ) + NVL(TO_NUMBER(g_if_data_tab(cn_singly_qty)), 0);
--
      EXCEPTION
        -- 取得結果が0件の場合
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10227
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_parent_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END;
--
    END IF;
--
    -- 子品目が指定されている場合
    IF g_if_data_tab(cn_child_item_code) IS NOT NULL THEN
--
      BEGIN
--
        ln_parent_case_in_qty :=  0;
        ln_child_case_in_qty  :=  0;
--
        SELECT  msib.inventory_item_id
               ,msib_p.inventory_item_id
               ,msib_p.segment1
               ,NVL(TO_NUMBER(iimb_p.attribute11), 0)
               ,NVL(TO_NUMBER(iimb.attribute11), 0)
        INTO    lt_child_item_id
               ,lt_parent_item_id
               ,lt_parent_item_code
               ,ln_parent_case_in_qty
               ,ln_child_case_in_qty
        FROM    ic_item_mst_b          iimb
               ,mtl_system_items_b     msib
               ,xxcmn_item_mst_b       ximb
               ,xxcmm_system_items_b   xsib
               ,mtl_system_items_b     msib_p
               ,ic_item_mst_b          iimb_p
        WHERE   iimb.item_no          = g_if_data_tab(cn_child_item_code)
        AND     iimb.item_id          = ximb.item_id
        AND     gd_process_date BETWEEN ximb.start_date_active AND ximb.end_date_active
        AND     iimb.item_no          = msib.segment1
        AND     msib.organization_id  = gn_inv_org_id
        AND     iimb.item_no          = xsib.item_code
        AND     xsib.item_status      IN ( '30' ,'40' ,'50' )
        AND     ximb.parent_item_id   = iimb_p.item_id
        AND     iimb_p.item_no        = msib_p.segment1
        AND     msib.organization_id  = msib_p.organization_id
        ;
--
        -- 入数がNULLか0ならエラー
        IF ln_parent_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  lt_parent_item_code
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        IF ln_child_case_in_qty = cn_zero THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10680
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_child_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
        END IF;
--
        ln_reserved_quantity_req  :=  ( NVL(TO_NUMBER(g_if_data_tab(cn_case_qty)), 0) * ln_child_case_in_qty ) + NVL(TO_NUMBER(g_if_data_tab(cn_singly_qty)), 0);
--
      EXCEPTION
        -- 取得結果が0件の場合
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10227
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  g_if_data_tab(cn_child_item_code)
                       );
          lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END;
--
    END IF;
--
--  V1.1 Added START
    --  総数の0チェック（数量0取引の作成不可）
    IF ln_reserved_quantity_req = 0 THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                      , iv_name         =>  cv_msg_coi_10226
                    );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
    --
    lv_errbuf2  :=  NULL;
    --  在庫会計期間のチェック
    IF g_if_data_tab(cn_invoice_date) IS NOT NULL THEN
      xxcoi_common_pkg.org_acct_period_chk(
          in_organization_id  =>  gn_inv_org_id                                               --  在庫組織ID
        , id_target_date      =>  TO_DATE( g_if_data_tab(cn_invoice_date), cv_date_format )   --  伝票日付
        , ob_chk_result       =>  lb_org_acct_period_flg                                      --  チェック結果
        , ov_errbuf           =>  lv_errbuf2
        , ov_retcode          =>  lv_retcode
        , ov_errmsg           =>  lv_errmsg
      );
      --  在庫会計期間ステータスの取得に失敗した場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_00026
                        , iv_token_name1    =>  cv_tkn_target_date
                        , iv_token_value1   =>  g_if_data_tab(cn_invoice_date)
                      );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      ELSIF ( NOT lb_org_acct_period_flg ) THEN
        --  在庫会計期間がクローズの場合
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_msg_kbn_coi
                        , iv_name           =>  cv_msg_coi_10231
                        , iv_token_name1    =>  cv_tkn_invoice_date
                        , iv_token_value1   =>  g_if_data_tab(cn_invoice_date)
                      );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      END IF;
    END IF;
--  V1.1 Added END
--
    -- 出庫側拠点、出庫側保管場所コード、入庫側拠点、入庫側保管場所コードの取得（他拠点へ出庫）
    lv_errbuf2  :=  NULL;
--
    xxcoi_common_pkg.convert_subinv_code(
      iv_record_type                =>  cv_record_type                        -- レコード種別
     ,iv_invoice_type               =>  cv_invoice_type2                      -- 伝票区分
     ,iv_department_flag            =>  cv_department_flag                    -- 百貨店フラグ
     ,iv_base_code                  =>  g_if_data_tab(cn_outside_base_code)   -- 拠点コード
     ,iv_outside_code               =>  g_if_data_tab(cn_outside_subinv_code) -- 出庫側コード
     ,iv_inside_code                =>  g_if_data_tab(cn_inside_base_code)    -- 入庫側コード
     ,id_transaction_date           =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
                                                                              -- 取引日
     ,in_organization_id            =>  gn_inv_org_id                         -- 在庫組織ID
     ,iv_hht_form_flag              =>  cv_const_y                            -- HHT取引入力画面フラグ
     ,ov_outside_subinv_code        =>  lt_chg_start_subinv_code              -- 出庫側保管場所コード
     ,ov_inside_subinv_code         =>  lt_chg_via_subinv_code                -- 入庫側保管場所コード
     ,ov_outside_base_code          =>  lt_chg_start_base_code                -- 出庫側拠点コード
     ,ov_inside_base_code           =>  lt_chg_via_base_code                  -- 入庫側拠点コード
     ,ov_outside_subinv_code_conv   =>  lt_chg_outside_subinv_conv            -- 出庫側保管場所変換区分
     ,ov_inside_subinv_code_conv    =>  lt_chg_inside_subinv_conv             -- 入庫側保管場所変換区分
     ,ov_outside_business_low_type  =>  lt_outside_business_low_type          -- 出庫側業態小分類(使用しない)
     ,ov_inside_business_low_type   =>  lt_inside_business_low_type           -- 入庫側業態小分類(使用しない)
     ,ov_outside_cust_code          =>  lt_outside_cust_code                  -- 出庫側顧客コード(使用しない)
     ,ov_inside_cust_code           =>  lt_inside_cust_code                   -- 入庫側顧客コード(使用しない)
     ,ov_hht_program_div            =>  lt_chg_program_div                    -- 入出庫ジャーナル処理区分
     ,ov_item_convert_div           =>  lt_chg_item_convert_div               -- 商品振替区分
     ,ov_stock_uncheck_list_div     =>  lt_chg_stock_uncheck_list_div         -- 入庫未確認リスト対象区分
     ,ov_stock_balance_list_div     =>  lt_chg_stock_balance_list_div         -- 入庫差異確認リスト対象区分
     ,ov_consume_vd_flag            =>  lt_chg_consume_vd_flag                -- 消化VD補充対象フラグ
     ,ov_outside_subinv_div         =>  lt_outside_subinv_div                 -- 出庫側棚卸対象(使用しない)
     ,ov_inside_subinv_div          =>  lt_inside_subinv_div                  -- 入庫側棚卸対象(使用しない)
     ,ov_retcode                    =>  lv_retcode                            -- リターン・コード(1:正常、2:エラー)
     ,ov_errbuf                     =>  lv_errbuf2                            -- エラーメッセージ
     ,ov_errmsg                     =>  lv_errmsg                             -- ユーザー・エラーメッセージ
    );
    -- 出庫側保管場所がNULLの場合
    IF ( lt_chg_start_subinv_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                   , iv_name         => cv_msg_coi_10278
                   , iv_token_name1  => cv_tkn_record_type
                   , iv_token_value1 => cv_record_type
                   , iv_token_name2  => cv_tkn_invoice_type
                   , iv_token_value2 => cv_invoice_type2
                   , iv_token_name3  => cv_tkn_department_flag
                   , iv_token_value3 => cv_department_flag
                   , iv_token_name4  => cv_tkn_base_code
                   , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                   , iv_token_name5  => cv_tkn_code
                   , iv_token_value5 => g_if_data_tab(cn_outside_subinv_code)
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 出庫側拠点がNULLの場合
    ELSIF ( lt_chg_start_base_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10279
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_outside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 入庫側保管場所がNULLの場合
    ELSIF ( lt_chg_via_subinv_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10276
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 入庫側拠点がNULLの場合
    ELSIF ( lt_chg_via_base_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10277
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type2
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => g_if_data_tab(cn_outside_base_code)
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 出庫側拠点、出庫側保管場所コード、入庫側拠点、入庫側保管場所コードの取得(倉庫から営業車へ)
    lv_errbuf2  :=  NULL;
--
    xxcoi_common_pkg.convert_subinv_code(
      iv_record_type                =>  cv_record_type                        -- レコード種別
     ,iv_invoice_type               =>  cv_invoice_type                       -- 伝票区分
     ,iv_department_flag            =>  cv_department_flag                    -- 百貨店フラグ
     ,iv_base_code                  =>  lt_chg_via_base_code                  -- 拠点コード
     ,iv_outside_code               =>  SUBSTR(lt_chg_via_subinv_code, -2)    -- 出庫側コード
     ,iv_inside_code                =>  g_if_data_tab(cn_inside_subinv_code)  -- 入庫側コード
     ,id_transaction_date           =>  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
                                                                              -- 取引日
     ,in_organization_id            =>  gn_inv_org_id                         -- 在庫組織ID
     ,iv_hht_form_flag              =>  cv_const_y                            -- HHT取引入力画面フラグ
     ,ov_outside_subinv_code        =>  lt_io_start_subinv_code               -- 出庫側保管場所コード
     ,ov_inside_subinv_code         =>  lt_io_via_subinv_code                 -- 入庫側保管場所コード
     ,ov_outside_base_code          =>  lt_io_start_base_code                 -- 出庫側拠点コード
     ,ov_inside_base_code           =>  lt_io_via_base_code                   -- 入庫側拠点コード
     ,ov_outside_subinv_code_conv   =>  lt_io_outside_subinv_conv             -- 出庫側保管場所変換区分
     ,ov_inside_subinv_code_conv    =>  lt_io_inside_subinv_conv              -- 入庫側保管場所変換区分
     ,ov_outside_business_low_type  =>  lt_outside_business_low_type          -- 出庫側業態小分類(使用しない)
     ,ov_inside_business_low_type   =>  lt_inside_business_low_type           -- 入庫側業態小分類(使用しない)
     ,ov_outside_cust_code          =>  lt_outside_cust_code                  -- 出庫側顧客コード(使用しない)
     ,ov_inside_cust_code           =>  lt_inside_cust_code                   -- 入庫側顧客コード(使用しない)
     ,ov_hht_program_div            =>  lt_io_program_div                     -- 入出庫ジャーナル処理区分
     ,ov_item_convert_div           =>  lt_io_item_convert_div                -- 商品振替区分
     ,ov_stock_uncheck_list_div     =>  lt_io_stock_uncheck_list_div          -- 入庫未確認リスト対象区分
     ,ov_stock_balance_list_div     =>  lt_io_stock_balance_list_div          -- 入庫差異確認リスト対象区分
     ,ov_consume_vd_flag            =>  lt_io_consume_vd_flag                 -- 消化VD補充対象フラグ
     ,ov_outside_subinv_div         =>  lt_outside_subinv_div                 -- 出庫側棚卸対象(使用しない)
     ,ov_inside_subinv_div          =>  lt_inside_subinv_div                  -- 入庫側棚卸対象(使用しない)
     ,ov_retcode                    =>  lv_retcode                            -- リターン・コード(1:正常、2:エラー)
     ,ov_errbuf                     =>  lv_errbuf2                            -- エラーメッセージ
     ,ov_errmsg                     =>  lv_errmsg                             -- ユーザー・エラーメッセージ
    );
    -- 出庫側保管場所がNULLの場合
    IF ( lt_io_start_subinv_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                   , iv_name         => cv_msg_coi_10278
                   , iv_token_name1  => cv_tkn_record_type
                   , iv_token_value1 => cv_record_type
                   , iv_token_name2  => cv_tkn_invoice_type
                   , iv_token_value2 => cv_invoice_type
                   , iv_token_name3  => cv_tkn_department_flag
                   , iv_token_value3 => cv_department_flag
                   , iv_token_name4  => cv_tkn_base_code
                   , iv_token_value4 => lt_chg_via_base_code
                   , iv_token_name5  => cv_tkn_code
                   , iv_token_value5 => SUBSTR(lt_chg_via_subinv_code, -2)
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 出庫側拠点がNULLの場合
    ELSIF ( lt_io_start_base_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10279
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => SUBSTR(lt_chg_via_subinv_code, -2)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 入庫側保管場所がNULLの場合
    ELSIF ( lt_io_via_subinv_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10276
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    -- 入庫側拠点がNULLの場合
    ELSIF ( lt_io_via_base_code IS NULL ) THEN
      -- エラーメッセージの取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10277
                     , iv_token_name1  => cv_tkn_record_type
                     , iv_token_value1 => cv_record_type
                     , iv_token_name2  => cv_tkn_invoice_type
                     , iv_token_value2 => cv_invoice_type
                     , iv_token_name3  => cv_tkn_department_flag
                     , iv_token_value3 => cv_department_flag
                     , iv_token_name4  => cv_tkn_base_code
                     , iv_token_value4 => lt_chg_via_base_code
                     , iv_token_name5  => cv_tkn_code
                     , iv_token_value5 => g_if_data_tab(cn_inside_subinv_code)
                     );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 他拠点営業車入出庫セキュリティマスタ（出庫依頼用）の確認
--
    -- ===============================
    -- ログインユーザの所属拠点を取得
    -- ===============================
    xxcoi_common_pkg.get_belonging_base(
        in_user_id     => cn_created_by     -- 1.ユーザーID
      , id_target_date => cd_creation_date  -- 2.対象日
      , ov_base_code   => lt_base_code      -- 3.拠点コード
      , ov_errbuf      => lv_errbuf2        -- 4.エラー・メッセージ
      , ov_retcode     => lv_retcode        -- 5.リターン・コード
      , ov_errmsg      => lv_errmsg         -- 6.ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_00010
                     , iv_token_name1  => cv_tkn_api_name
                     , iv_token_value1 => cv_api_belogin
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
      lt_base_code  :=  NULL;
    END IF;
--
    BEGIN
      SELECT  1
      INTO    ln_dummy
      FROM    fnd_lookup_values   flv   -- クイックコード
            , xxcoi_base_info2_v  xbiv
      WHERE   flv.lookup_type               =   cv_type_bargain_class
      AND     SUBSTR(flv.lookup_code, 1, 4) =   g_if_data_tab(cn_outside_base_code)
      AND     SUBSTR(flv.meaning, 1, 4)     =   g_if_data_tab(cn_inside_base_code)
      AND     flv.enabled_flag              =   cv_const_y
      AND     flv.language                  =   ct_lang
      AND     NVL(flv.start_date_active, TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)) <= TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
      AND     NVL(flv.end_date_active, TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format))   >= TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format)
      AND     xbiv.focus_base_code          =   lt_base_code
      AND     SUBSTR(flv.lookup_code, 1, 4) =   xbiv.base_code
      ;
    EXCEPTION
      -- 取得結果が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10741
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- 入庫側保管場所のチェック
    -- メイン倉庫の倉庫管理対象区分を取得
    BEGIN
      SELECT  xsiv.warehouse_flag
      INTO    lt_inside_warehouse_flag
      FROM    xxcoi_subinventory_info_v  xsiv
      WHERE   xsiv.organization_id      = gn_inv_org_id
      AND     xsiv.subinventory_code    = lt_chg_via_subinv_code
      AND     xsiv.management_base_code = g_if_data_tab(cn_inside_base_code)
      AND     TRUNC( NVL(xsiv.disable_date , SYSDATE+1 ) ) > TRUNC(SYSDATE)
      AND     xsiv.main_store_class     = cv_const_y
      ;
    EXCEPTION
      -- 取得結果が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10206
                       ,iv_token_name1  =>  cv_tkn_dept_code
                       ,iv_token_value1 =>  lt_chg_via_base_code
                       ,iv_token_name2  =>  cv_tkn_whouse_code
                       ,iv_token_value2 =>  lt_chg_via_subinv_code
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- 倉庫管理対象区分が「対象」ならエラー
    IF NVL(lt_inside_warehouse_flag, cv_const_n) = cv_const_y  THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10739
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 出庫側保管場所のチェック
    -- 出庫側保管場所の倉庫管理対象区分を取得
    BEGIN
      SELECT  xsiv.warehouse_flag
      INTO    lt_outside_warehouse_flag
      FROM    xxcoi_subinventory_info_v  xsiv
      WHERE   xsiv.organization_id      = gn_inv_org_id
      AND     xsiv.subinventory_code    = lt_chg_start_subinv_code
      AND     TRUNC( NVL(xsiv.disable_date, SYSDATE+1 ) )  >  TRUNC( SYSDATE )
      AND     xsiv.subinventory_class   = cv_subinventory_class_1
      ;
    EXCEPTION
      -- 取得結果が0件の場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_msg_kbn_coi
                       ,iv_name         =>  cv_msg_coi_10206
                       ,iv_token_name1  =>  cv_tkn_dept_code
                       ,iv_token_value1 =>  lt_chg_start_base_code
                       ,iv_token_name2  =>  cv_tkn_whouse_code
                       ,iv_token_value2 =>  lt_chg_start_subinv_code
                     );
        lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END;
--
    -- 倉庫管理対象区分が「対象」でないならエラー
    IF NVL(lt_outside_warehouse_flag, cv_const_n)  <>  cv_const_y  THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10740
                   );
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 入出庫一時表登録用のデータを記録する
    gt_inout_info_tab(gn_inout_count).slip_no                     :=  g_if_data_tab(cn_slip_no);                        -- 伝票番号
    gt_inout_info_tab(gn_inout_count).invoice_date                :=  TO_DATE(g_if_data_tab(cn_invoice_date), cv_date_format);
                                                                                                                        -- 伝票日付
    gt_inout_info_tab(gn_inout_count).outside_subinv_code         :=  g_if_data_tab(cn_outside_subinv_code);            -- 出庫側コード
    gt_inout_info_tab(gn_inout_count).inside_subinv_code          :=  g_if_data_tab(cn_inside_subinv_code);             -- 入庫側コード
--
    -- 入数が0の場合は0除算になるので除算をしない
    IF ln_parent_case_in_qty <> cn_zero THEN
      -- ケース数
      gt_inout_info_tab(gn_inout_count).case_qty                    :=  ( ln_reserved_quantity_req - MOD( ln_reserved_quantity_req, ln_parent_case_in_qty ) ) / ln_parent_case_in_qty;
      -- バラ数
      gt_inout_info_tab(gn_inout_count).singly_qty                  :=  MOD( ln_reserved_quantity_req, ln_parent_case_in_qty );
    ELSE
      -- ケース数
      gt_inout_info_tab(gn_inout_count).case_qty                    :=  0;
      -- バラ数
      gt_inout_info_tab(gn_inout_count).singly_qty                  :=  ln_reserved_quantity_req;
    END IF;
    gt_inout_info_tab(gn_inout_count).case_in_quantity            :=  ln_parent_case_in_qty;                            -- 入数
    gt_inout_info_tab(gn_inout_count).parent_item_id              :=  lt_parent_item_id;                                -- 親品目ID
    gt_inout_info_tab(gn_inout_count).parent_item_code            :=  lt_parent_item_code;                              -- 親品目
    gt_inout_info_tab(gn_inout_count).outside_base_code           :=  g_if_data_tab(cn_outside_base_code);              -- 出庫側拠点コード
    gt_inout_info_tab(gn_inout_count).inside_base_code            :=  g_if_data_tab(cn_inside_base_code);               -- 入庫側拠点コード
--
    -- 倉替（CHANGE）
    gt_inout_info_tab(gn_inout_count).chg_start_subinv_code       :=  lt_chg_start_subinv_code;                         -- 出庫側保管場所（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_via_subinv_code         :=  lt_chg_via_subinv_code;                           -- 入庫側保管場所（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_start_base_code         :=  lt_chg_start_base_code;                           -- 出庫側拠点（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_via_base_code           :=  lt_chg_via_base_code;                             -- 入庫側拠点（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_outside_subinv_conv     :=  lt_chg_outside_subinv_conv;                       -- 出庫側保管場所変換区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_inside_subinv_conv      :=  lt_chg_inside_subinv_conv;                        -- 入庫側保管場所変換区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_program_div             :=  lt_chg_program_div;                               -- 入出庫ジャーナル処理区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_consume_vd_flag         :=  lt_chg_consume_vd_flag;                           -- 消化VD補充対象フラグ（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_item_convert_div        :=  lt_chg_item_convert_div;                          -- 商品振替区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_stock_uncheck_list_div  :=  lt_chg_stock_uncheck_list_div;                    -- 入庫未確認リスト対象区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_stock_balance_list_div  :=  lt_chg_stock_balance_list_div;                    -- 入庫差異確認リスト対象区分（他拠点へ出庫）
    gt_inout_info_tab(gn_inout_count).chg_other_base_code         :=  lt_chg_via_base_code;                             -- 他拠点コード（他拠点へ出庫）
--
    -- 入出庫（IN/OUT）
    gt_inout_info_tab(gn_inout_count).io_start_subinv_code        :=  lt_io_start_subinv_code;                          -- 出庫側保管場所（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_via_subinv_code          :=  lt_io_via_subinv_code;                            -- 入庫側保管場所（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_start_base_code          :=  lt_io_start_base_code;                            -- 出庫側拠点（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_via_base_code            :=  lt_io_via_base_code;                              -- 入庫側拠点（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_outside_subinv_conv      :=  lt_io_outside_subinv_conv;                        -- 出庫側保管場所変換区分（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_inside_subinv_conv       :=  lt_io_inside_subinv_conv;                         -- 入庫側保管場所変換区分（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_program_div              :=  lt_io_program_div;                                -- 入出庫ジャーナル処理区分（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_consume_vd_flag          :=  lt_io_consume_vd_flag;                            -- 消化VD補充対象フラグ（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_item_convert_div         :=  lt_io_item_convert_div;                           -- 商品振替区分（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_stock_uncheck_list_div   :=  lt_io_stock_uncheck_list_div;                     -- 入庫未確認リスト対象区分（倉庫から営業車へ）
    gt_inout_info_tab(gn_inout_count).io_stock_balance_list_div   :=  lt_io_stock_balance_list_div;                     -- 入庫差異確認リスト対象区分（倉庫から営業車へ）
--
    lv_errbuf2  :=  NULL;
    -- 数量のチェックの呼び出し
    quantity_check(
        it_child_item_id          =>  lt_child_item_id                  -- 子品目ID
       ,it_parent_item_id         =>  lt_parent_item_id                 -- 親品目ID
       ,it_inout_info             =>  gt_inout_info_tab(gn_inout_count) -- ロット情報データレコード
       ,in_reserved_quantity_req  =>  ln_reserved_quantity_req          -- 引当依頼数
       ,ov_errbuf                 =>  lv_errbuf2                        -- エラー・メッセージ
       ,ov_retcode                =>  lv_retcode                        -- リターン・コード
       ,ov_errmsg                 =>  lv_errmsg                         -- ユーザー・エラー・メッセージ
    );
--
    -- リターンコードが'0'（正常）以外の場合はエラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := SUBSTRB(lv_errbuf || chr(10) || lv_errmsg, 1, 5000);
    END IF;
--
    -- 次の入出庫表を作成するため、カウントをあげる
    gn_inout_count :=  gn_inout_count + 1;
--
    -- エラー件数の設定
    IF ( lv_errbuf IS NOT NULL ) THEN
      -- エラーが発生している場合、エラー件数をカウント
      gn_error_cnt := gn_error_cnt + 1;
      -- チェック結果をNGにする。
      gv_check_result :=  cv_const_n;
      -- エラーメッセージを出力に表示する。
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_coi
                     ,iv_name         =>  cv_msg_coi_10749
                     ,iv_token_name1  =>  cv_tkn_param
                     ,iv_token_value1 =>  in_file_if_loop_cnt
                     ,iv_token_name2  =>  cv_tkn_param2
                     ,iv_token_value2 =>  g_if_data_tab(cn_slip_no)
                     ,iv_token_name3  =>  cv_tkn_param3
                     ,iv_token_value3 =>  g_if_data_tab(cn_invoice_date)
                     ,iv_token_name4  =>  cv_tkn_param4
                     ,iv_token_value4 =>  g_if_data_tab(cn_outside_base_code)
                     ,iv_token_name5  =>  cv_tkn_param5
                     ,iv_token_value5 =>  g_if_data_tab(cn_outside_subinv_code)
                     ,iv_token_name6  =>  cv_tkn_param6
                     ,iv_token_value6 =>  g_if_data_tab(cn_inside_base_code)
                     ,iv_token_name7  =>  cv_tkn_param7
                     ,iv_token_value7 =>  g_if_data_tab(cn_inside_subinv_code)
                     ,iv_token_name8  =>  cv_tkn_param8
                     ,iv_token_value8 =>  g_if_data_tab(cn_parent_item_code)
                     ,iv_token_name9  =>  cv_tkn_param9
                     ,iv_token_value9 =>  g_if_data_tab(cn_child_item_code)
                   );
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => chr(10) || lv_errmsg || lv_errbuf --ユーザー・エラーメッセージ
      );
--
    -- 成功件数の設定
    ELSE
      -- エラーが無い場合は、成功件数としてカウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END err_check;
--
    /**********************************************************************************
   * Procedure Name   : cre_inv_transactions
   * Description      : 入出庫情報の作成(A-6)
   ***********************************************************************************/
  PROCEDURE cre_inv_transactions(
    ov_errbuf             OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_inv_transactions'; -- プログラム名
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
    ln_count                  NUMBER;         -- カウント用変数
    ln_count2                 NUMBER;         -- カウント用変数2
    lv_chg_slip_no            VARCHAR2(100);  -- 伝票番号(倉替)
    lv_io_slip_no             VARCHAR2(100);  -- 伝票番号(入出庫)
    lv_output_slip_no         VARCHAR2(100);  -- 伝票番号(出力確認用)
    ld_interface_date         DATE;           -- 受信日時
    ln_transaction_id         NUMBER;         -- 入出庫一時表ID
    lv_status                 VARCHAR2(1);    -- 処理ステータス
    lt_primary_uom_code       xxcoi_txn_enable_item_info_v.primary_uom_code%TYPE; -- 基準単位コード
    lv_goods_product_class    VARCHAR2(100);                                      -- プロファイル：カテゴリセット名
    lv_chg_invoice_no         xxcoi_hht_inv_transactions.invoice_no%TYPE;         -- 伝票No(倉替)
    lv_io_invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE;         -- 伝票No(入出庫)
    lv_message_slip           VARCHAR2(5000); -- 帳票No出力メッセージ
    lb_err_flg                BOOLEAN;        -- エラー判定
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
    -- ローカル変数初期化
    lv_goods_product_class  :=  FND_PROFILE.VALUE(cv_goods_product_cls);
    ln_count                :=  1;
    ld_interface_date       :=  SYSDATE;
    lv_errbuf               :=  NULL;
    lv_chg_invoice_no       :=  NULL;
    lv_io_invoice_no        :=  NULL;
    lv_chg_slip_no          :=  ' ';
    lv_io_slip_no           :=  ' ';
    lv_output_slip_no       :=  ' ';
--
    <<inv_transactions_loop>>
    LOOP
--
      -- カウントがレコード型変数に登録した件数の最大値に達していたらループを抜ける
      IF ln_count = gn_inout_count THEN
        EXIT;
      END IF;
--
      -- 入出庫一時表IDの取得
      BEGIN
--
        SELECT  xxcoi.xxcoi_hht_inv_transactions_s01.nextval
        INTO    ln_transaction_id
        FROM    dual
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- エラーメッセージの取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10294
                       );
          RAISE global_process_expt;
      END;
--
      -- 伝票No取得（すでに、同一伝票番号で伝票Noを発行している場合は新たに採番しない）
      IF gt_inout_info_tab(ln_count).slip_no <> lv_chg_slip_no THEN
--
        lv_chg_invoice_no :=  NULL;
--
        BEGIN
--
          SELECT  'E' || LTRIM(TO_CHAR(xxcoi.xxcoi_invoice_no_s01.nextval,'00000000'))
          INTO    lv_chg_invoice_no
          FROM    dual
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- エラーメッセージの取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10284
                         );
            RAISE global_process_expt;
        END;
--
        lv_chg_slip_no  :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      -- ロット情報に必要な情報を保持する
      ln_count2 :=  1;
      <<lot_info_loop>>
      LOOP
--
        -- 出庫情報と一致するロット情報にデータを登録する
        -- (伝票番号では、複数行に同一の番号が存在するため、CSVの行数で同一レコードを判断する)
        IF gt_lot_info_tab(ln_count2).csv_no = ln_count THEN
--
          gt_lot_info_tab(ln_count2).transaction_id :=  ln_transaction_id;
          gt_lot_info_tab(ln_count2).invoice_no     :=  lv_chg_invoice_no;
--
        END IF;
--
        ln_count2 :=  ln_count2 + 1;
--
        IF ln_count2 = gn_lot_count THEN
          EXIT;
        END IF;
--
      END LOOP lot_info_loop;
--
      -- 基準単位コードの取得
      BEGIN
        SELECT  xteiiv.primary_uom_code
        INTO    lt_primary_uom_code
        FROM    xxcoi_txn_enable_item_info_v  xteiiv
               ,mtl_category_sets_tl          mcst
               ,mtl_category_sets_b           mcsb
               ,mtl_categories_b              mcb
               ,mtl_item_categories           mic
        WHERE   mcst.category_set_name  = lv_goods_product_class
        AND     mcst.language           = ct_language
        AND     mcsb.category_set_id    = mcst.category_set_id
        AND     mcb.structure_id        = mcsb.structure_id
        AND     mcb.segment1            IN ( cv_segment1_1, cv_segment1_2 )
        AND     mic.category_id         = mcb.category_id
        AND     mic.inventory_item_id   = xteiiv.inventory_item_id
        AND     mic.organization_id     = xteiiv.organization_id
        AND     TO_CHAR(gt_inout_info_tab(ln_count).invoice_date, cv_date_format)
                                        BETWEEN TO_CHAR(xteiiv.start_date_active, cv_date_format)
                                        AND     TO_CHAR(NVL(xteiiv.end_date_active, gt_inout_info_tab(ln_count).invoice_date), cv_date_format)
        AND     mic.inventory_item_id   = gt_inout_info_tab(ln_count).parent_item_id
        ;
--
      EXCEPTION
        -- 取得結果が0件の場合
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10132
                         ,iv_token_name1  =>  cv_tkn_item_code
                         ,iv_token_value1 =>  gt_inout_info_tab(ln_count).parent_item_code
                       );
          RAISE global_process_expt;
      END;
--
      -- 入出庫ジャーナル処理区分の値により、処理ステータスを設定
      IF gt_inout_info_tab(ln_count).chg_program_div = cv_program_div_0 THEN
        lv_status :=  cv_status_1;
      ELSE
        lv_status :=  cv_status_0;
      END IF;
--
      BEGIN
        -- HHT入出庫一時表への登録(他拠点へ出庫)
        INSERT INTO xxcoi_hht_inv_transactions(
          transaction_id                        -- 入出庫一時表ID
         ,interface_id                          -- インターフェースID
         ,form_header_id                        -- 画面入力用ヘッダID
         ,base_code                             -- 拠点コード
         ,record_type                           -- レコード種別
         ,employee_num                          -- 営業員コード
         ,invoice_no                            -- 伝票№
         ,item_code                             -- 品目コード（品名コード）
         ,case_quantity                         -- ケース数
         ,case_in_quantity                      -- 入数
         ,quantity                              -- 本数
         ,invoice_type                          -- 伝票区分
         ,base_delivery_flag                    -- 拠点間倉替フラグ
         ,outside_code                          -- 出庫側コード
         ,inside_code                           -- 入庫側コード
         ,invoice_date                          -- 伝票日付
         ,column_no                             -- コラム№
         ,unit_price                            -- 単価
         ,hot_cold_div                          -- H/C
         ,department_flag                       -- 百貨店フラグ
         ,interface_date                        -- 受信日時
         ,other_base_code                       -- 他拠点コード
         ,outside_subinv_code                   -- 出庫側保管場所
         ,inside_subinv_code                    -- 入庫側保管場所
         ,outside_base_code                     -- 出庫側拠点
         ,inside_base_code                      -- 入庫側拠点
         ,total_quantity                        -- 総本数
         ,inventory_item_id                     -- 品目ID
         ,primary_uom_code                      -- 基準単位
         ,outside_subinv_code_conv_div          -- 出庫側保管場所変換区分
         ,inside_subinv_code_conv_div           -- 入庫側保管場所変換区分
         ,outside_business_low_type             -- 出庫側業態区分
         ,inside_business_low_type              -- 入庫側業態区分
         ,outside_cust_code                     -- 出庫側顧客コード
         ,inside_cust_code                      -- 入庫側顧客コード
         ,hht_program_div                       -- 入出庫ジャーナル処理区分
         ,consume_vd_flag                       -- 消化VD補充対象フラグ
         ,item_convert_div                      -- 商品振替区分
         ,stock_uncheck_list_div                -- 入庫未確認リスト対象区分
         ,stock_balance_list_div                -- 入庫差異確認リスト対象区分
         ,status                                -- 処理ステータス
         ,column_if_flag                        -- コラム別転送済フラグ
         ,column_if_date                        -- コラム別転送日
         ,sample_if_flag                        -- 見本転送済フラグ
         ,sample_if_date                        -- 見本転送日
         ,output_flag                           -- 出力済フラグ
         ,last_update_date                      -- 最終更新日
         ,last_updated_by                       -- 最終更新者
         ,creation_date                         -- 作成日
         ,created_by                            -- 作成者
         ,last_update_login                     -- 最終更新ユーザ
         ,request_id                            -- 要求ID
         ,program_application_id                -- プログラムアプリケーションID
         ,program_id                            -- プログラムID
         ,program_update_date)                  -- プログラム更新日
        VALUES(
          ln_transaction_id                                       -- 入出庫一時表ID
         ,NULL                                                    -- インターフェースID
         ,NULL                                                    -- 画面入力用ヘッダID
         ,gt_inout_info_tab(ln_count).outside_base_code           -- 拠点コード
         ,cv_record_type                                          -- レコード種別
         ,NULL                                                    -- 営業員コード
         ,lv_chg_invoice_no                                       -- 伝票№
         ,gt_inout_info_tab(ln_count).parent_item_code            -- 品目コード（品名コード）
         ,gt_inout_info_tab(ln_count).case_qty                    -- ケース数
         ,gt_inout_info_tab(ln_count).case_in_quantity            -- 入数
         ,gt_inout_info_tab(ln_count).singly_qty                  -- 本数
         ,cv_invoice_type2                                        -- 伝票区分
         ,cn_zero                                                 -- 拠点間倉替フラグ
         ,gt_inout_info_tab(ln_count).outside_subinv_code         -- 出庫側コード
         ,gt_inout_info_tab(ln_count).inside_base_code            -- 入庫側コード
         ,gt_inout_info_tab(ln_count).invoice_date                -- 伝票日付
         ,NULL                                                    -- コラム№
         ,0                                                       -- 単価
         ,NULL                                                    -- H/C
         ,cv_department_flag                                      -- 百貨店フラグ
         ,ld_interface_date                                       -- 受信日時
         ,gt_inout_info_tab(ln_count).chg_other_base_code         -- 他拠点コード
         ,gt_inout_info_tab(ln_count).chg_start_subinv_code       -- 出庫側保管場所
         ,gt_inout_info_tab(ln_count).chg_via_subinv_code         -- 入庫側保管場所
         ,gt_inout_info_tab(ln_count).chg_start_base_code         -- 出庫側拠点
         ,gt_inout_info_tab(ln_count).chg_via_base_code           -- 入庫側拠点
         ,(gt_inout_info_tab(ln_count).case_in_quantity * gt_inout_info_tab(ln_count).case_qty) + gt_inout_info_tab(ln_count).singly_qty
                                                                  -- 総本数
         ,gt_inout_info_tab(ln_count).parent_item_id              -- 品目ID
         ,lt_primary_uom_code                                     -- 基準単位
         ,gt_inout_info_tab(ln_count).chg_outside_subinv_conv     -- 出庫側保管場所変換区分
         ,gt_inout_info_tab(ln_count).chg_inside_subinv_conv      -- 入庫側保管場所変換区分
         ,NULL                                                    -- 出庫側業態区分
         ,NULL                                                    -- 入庫側業態区分
         ,NULL                                                    -- 出庫側顧客コード
         ,NULL                                                    -- 入庫側顧客コード
         ,gt_inout_info_tab(ln_count).chg_program_div             -- 入出庫ジャーナル処理区分
         ,gt_inout_info_tab(ln_count).chg_consume_vd_flag         -- 消化VD補充対象フラグ
         ,gt_inout_info_tab(ln_count).chg_item_convert_div        -- 商品振替区分
         ,gt_inout_info_tab(ln_count).chg_stock_uncheck_list_div  -- 入庫未確認リスト対象区分
         ,gt_inout_info_tab(ln_count).chg_stock_balance_list_div  -- 入庫差異確認リスト対象区分
         ,lv_status                                               -- 処理ステータス（未処理）
         ,cv_const_n                                              -- コラム別転送済フラグ（未転送）
         ,NULL                                                    -- コラム別転送日
         ,cv_const_n                                              -- 見本転送済フラグ（未転送）
         ,NULL                                                    -- 見本転送日
         ,cv_const_n                                              -- 出力済フラグ（未出力）
         ,cd_last_update_date                                     -- 最終更新日
         ,cn_last_updated_by                                      -- 最終更新者
         ,cd_creation_date                                        -- 作成日
         ,cn_created_by                                           -- 作成者
         ,cn_last_update_login                                    -- 最終更新ログイン
         ,cn_request_id                                           -- 要求ID
         ,cn_program_application_id                               -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id                                           -- コンカレント・プログラムID
         ,cd_program_update_date                                  -- プログラム更新日
        )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージの取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                       , iv_name         => cv_msg_coi_10701
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          RAISE global_process_expt;
      END;
--
      -- 入出庫一時表IDの取得
      BEGIN
        ln_transaction_id :=  NULL;
--
        SELECT  xxcoi.xxcoi_hht_inv_transactions_s01.nextval
        INTO    ln_transaction_id
        FROM    dual
        ;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- エラーメッセージの取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10294
                       );
          RAISE global_process_expt;
      END;
--
      -- 伝票No取得（すでに、同一伝票番号で伝票Noを発行している場合は新たに採番しない）
      IF gt_inout_info_tab(ln_count).slip_no <> lv_io_slip_no THEN
--
        lv_io_invoice_no :=  NULL;
--
        BEGIN
--
          SELECT  'E' || LTRIM(TO_CHAR(xxcoi.xxcoi_invoice_no_s01.nextval,'00000000'))
          INTO    lv_io_invoice_no
          FROM    dual
          ;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- エラーメッセージの取得
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10284
                         );
            RAISE global_process_expt;
        END;
--
        lv_io_slip_no :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      -- 入出庫ジャーナル処理区分の値により、処理ステータスを設定
      IF gt_inout_info_tab(ln_count).io_program_div = cv_program_div_0 THEN
        lv_status :=  cv_status_1;
      ELSE
        lv_status :=  cv_status_0;
      END IF;
--
      BEGIN
        -- HHT入出庫一時表への登録(倉庫から営業車へ)
        INSERT INTO xxcoi_hht_inv_transactions(
          transaction_id                        -- 入出庫一時表ID
         ,interface_id                          -- インターフェースID
         ,form_header_id                        -- 画面入力用ヘッダID
         ,base_code                             -- 拠点コード
         ,record_type                           -- レコード種別
         ,employee_num                          -- 営業員コード
         ,invoice_no                            -- 伝票№
         ,item_code                             -- 品目コード（品名コード）
         ,case_quantity                         -- ケース数
         ,case_in_quantity                      -- 入数
         ,quantity                              -- 本数
         ,invoice_type                          -- 伝票区分
         ,base_delivery_flag                    -- 拠点間倉替フラグ
         ,outside_code                          -- 出庫側コード
         ,inside_code                           -- 入庫側コード
         ,invoice_date                          -- 伝票日付
         ,column_no                             -- コラム№
         ,unit_price                            -- 単価
         ,hot_cold_div                          -- H/C
         ,department_flag                       -- 百貨店フラグ
         ,interface_date                        -- 受信日時
         ,other_base_code                       -- 他拠点コード
         ,outside_subinv_code                   -- 出庫側保管場所
         ,inside_subinv_code                    -- 入庫側保管場所
         ,outside_base_code                     -- 出庫側拠点
         ,inside_base_code                      -- 入庫側拠点
         ,total_quantity                        -- 総本数
         ,inventory_item_id                     -- 品目ID
         ,primary_uom_code                      -- 基準単位
         ,outside_subinv_code_conv_div          -- 出庫側保管場所変換区分
         ,inside_subinv_code_conv_div           -- 入庫側保管場所変換区分
         ,outside_business_low_type             -- 出庫側業態区分
         ,inside_business_low_type              -- 入庫側業態区分
         ,outside_cust_code                     -- 出庫側顧客コード
         ,inside_cust_code                      -- 入庫側顧客コード
         ,hht_program_div                       -- 入出庫ジャーナル処理区分
         ,consume_vd_flag                       -- 消化VD補充対象フラグ
         ,item_convert_div                      -- 商品振替区分
         ,stock_uncheck_list_div                -- 入庫未確認リスト対象区分
         ,stock_balance_list_div                -- 入庫差異確認リスト対象区分
         ,status                                -- 処理ステータス
         ,column_if_flag                        -- コラム別転送済フラグ
         ,column_if_date                        -- コラム別転送日
         ,sample_if_flag                        -- 見本転送済フラグ
         ,sample_if_date                        -- 見本転送日
         ,output_flag                           -- 出力済フラグ
         ,last_update_date                      -- 最終更新日
         ,last_updated_by                       -- 最終更新者
         ,creation_date                         -- 作成日
         ,created_by                            -- 作成者
         ,last_update_login                     -- 最終更新ユーザ
         ,request_id                            -- 要求ID
         ,program_application_id                -- プログラムアプリケーションID
         ,program_id                            -- プログラムID
         ,program_update_date)                  -- プログラム更新日
        VALUES(
          ln_transaction_id                                     -- 入出庫一時表ID
         ,NULL                                                  -- インターフェースID
         ,NULL                                                  -- 画面入力用ヘッダID
         ,gt_inout_info_tab(ln_count).inside_base_code          -- 拠点コード
         ,cv_record_type                                        -- レコード種別
         ,NULL                                                  -- 営業員コード
         ,lv_io_invoice_no                                      -- 伝票№
         ,gt_inout_info_tab(ln_count).parent_item_code          -- 品目コード（品名コード）
         ,gt_inout_info_tab(ln_count).case_qty                  -- ケース数
         ,gt_inout_info_tab(ln_count).case_in_quantity          -- 入数
         ,gt_inout_info_tab(ln_count).singly_qty                -- 本数
         ,cv_invoice_type                                       -- 伝票区分
         ,cn_zero                                               -- 拠点間倉替フラグ
         ,SUBSTR(gt_inout_info_tab(ln_count).io_start_subinv_code, -2)
                                                                -- 出庫側コード
         ,gt_inout_info_tab(ln_count).inside_subinv_code        -- 入庫側コード
         ,gt_inout_info_tab(ln_count).invoice_date              -- 伝票日付
         ,NULL                                                  -- コラム№
         ,0                                                     -- 単価
         ,NULL                                                  -- H/C
         ,cv_department_flag                                    -- 百貨店フラグ
         ,ld_interface_date                                     -- 受信日時
         ,NULL                                                  -- 他拠点コード
         ,gt_inout_info_tab(ln_count).io_start_subinv_code      -- 出庫側保管場所
         ,gt_inout_info_tab(ln_count).io_via_subinv_code        -- 入庫側保管場所
         ,gt_inout_info_tab(ln_count).io_start_base_code        -- 出庫側拠点
         ,gt_inout_info_tab(ln_count).io_via_base_code          -- 入庫側拠点
         ,(gt_inout_info_tab(ln_count).case_in_quantity * gt_inout_info_tab(ln_count).case_qty) + gt_inout_info_tab(ln_count).singly_qty
                                                                -- 総本数
         ,gt_inout_info_tab(ln_count).parent_item_id            -- 品目ID
         ,lt_primary_uom_code                                   -- 基準単位
         ,gt_inout_info_tab(ln_count).io_outside_subinv_conv    -- 出庫側保管場所変換区分
         ,gt_inout_info_tab(ln_count).io_inside_subinv_conv     -- 入庫側保管場所変換区分
         ,NULL                                                  -- 出庫側業態区分
         ,NULL                                                  -- 入庫側業態区分
         ,NULL                                                  -- 出庫側顧客コード
         ,NULL                                                  -- 入庫側顧客コード
         ,gt_inout_info_tab(ln_count).io_program_div            -- 入出庫ジャーナル処理区分
         ,gt_inout_info_tab(ln_count).io_consume_vd_flag        -- 消化VD補充対象フラグ
         ,gt_inout_info_tab(ln_count).io_item_convert_div       -- 商品振替区分
         ,gt_inout_info_tab(ln_count).io_stock_uncheck_list_div -- 入庫未確認リスト対象区分
         ,gt_inout_info_tab(ln_count).io_stock_balance_list_div -- 入庫差異確認リスト対象区分
         ,lv_status                                             -- 処理ステータス（未処理）
         ,cv_const_n                                            -- コラム別転送済フラグ（未転送）
         ,NULL                                                  -- コラム別転送日
         ,cv_const_n                                            -- 見本転送済フラグ（未転送）
         ,NULL                                                  -- 見本転送日
         ,cv_const_n                                            -- 出力済フラグ（未出力）
         ,cd_last_update_date                                   -- 最終更新日
         ,cn_last_updated_by                                    -- 最終更新者
         ,cd_creation_date                                      -- 作成日
         ,cn_created_by                                         -- 作成者
         ,cn_last_update_login                                  -- 最終更新ログイン
         ,cn_request_id                                         -- 要求ID
         ,cn_program_application_id                             -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id                                         -- コンカレント・プログラムID
         ,cd_program_update_date                                -- プログラム更新日
        )
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- エラーメッセージの取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_coi
                       , iv_name         => cv_msg_coi_10701
                       , iv_token_name1  => cv_tkn_err_msg
                       , iv_token_value1 => SQLERRM
                       );
          RAISE global_process_expt;
      END;
--
      -- 伝票Noの出力（すでに、同一伝票番号で出力している場合はスキップ）
      IF gt_inout_info_tab(ln_count).slip_no <> lv_output_slip_no THEN
--
        lv_message_slip :=  xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10748
                         , iv_token_name1  => cv_tkn_param
                         , iv_token_value1 => gt_inout_info_tab(ln_count).slip_no
                         , iv_token_name2  => cv_tkn_param2
                         , iv_token_value2 => lv_chg_invoice_no
                         , iv_token_name3  => cv_tkn_param3
                         , iv_token_value3 => lv_io_invoice_no
                       );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
          ,buff   => lv_message_slip
        );
--
        lv_output_slip_no :=  gt_inout_info_tab(ln_count).slip_no;
--
      END IF;
--
      ln_count  :=  ln_count + 1;
--
    END LOOP inv_transactions_loop;
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
  END cre_inv_transactions;
--
    /**********************************************************************************
   * Procedure Name   : cre_lot_transactions
   * Description      : ロット別取引明細の作成、ロット別手持数量の変更(A-7)
   ***********************************************************************************/
  PROCEDURE cre_lot_transactions(
    ov_errbuf             OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2  --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cre_lot_transactions'; -- プログラム名
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
    ln_count            NUMBER;                                     -- カウント用変数
    ln_count2           NUMBER;                                     -- カウント用変数2
    lv_transaction_type VARCHAR2(2);                                -- 取引タイプ
    lt_trx_id           xxcoi_lot_transactions.transaction_id%TYPE; -- ロット別取引ID
    lb_err_flg          BOOLEAN;                                    -- エラー判定
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
    -- ローカル変数初期化
    ln_count  :=  1;
    lv_errbuf :=  NULL;
--
    <<lot_info_loop>>
    LOOP
--
      -- カウントがレコード型変数に登録した件数の最大値に達していたらループを抜ける
      IF ln_count = gn_lot_count THEN
        EXIT;
      END IF;
--
      -- 「他拠点へ出庫」データの作成
--
      -- ロット別取引明細作成
      -- 共通関数：ロット別取引明細作成
      xxcoi_common_pkg.cre_lot_trx(
          in_trx_set_id            => NULL                                                      -- 取引セットID
         ,iv_parent_item_code      => gt_lot_info_tab(ln_count).parent_item_code                -- 親品目コード
         ,iv_child_item_code       => gt_lot_info_tab(ln_count).child_item_code                 -- 子品目コード
         ,iv_lot                   => gt_lot_info_tab(ln_count).lot                             -- ロット(賞味期限)
         ,iv_diff_sum_code         => gt_lot_info_tab(ln_count).difference_summary_code         -- 固有記号
         ,iv_trx_type_code         => cv_transaction_type_20                                    -- 取引タイプコード
         ,id_trx_date              => gt_lot_info_tab(ln_count).invoice_date                    -- 取引日
         ,iv_slip_num              => gt_lot_info_tab(ln_count).invoice_no                      -- 伝票No
         ,in_case_in_qty           => gt_lot_info_tab(ln_count).case_in_quantity                -- 入数
         ,in_case_qty              => gt_lot_info_tab(ln_count).case_qty * (-1)                 -- ケース数
         ,in_singly_qty            => gt_lot_info_tab(ln_count).singly_qty * (-1)               -- バラ数
         ,in_summary_qty           => gt_lot_info_tab(ln_count).summary_quantity * (-1)         -- 取引数量
         ,iv_base_code             => gt_lot_info_tab(ln_count).outside_base_code               -- 拠点コード
         ,iv_subinv_code           => gt_lot_info_tab(ln_count).start_subinv_code               -- 保管場所コード
         ,iv_loc_code              => gt_lot_info_tab(ln_count).location_code                   -- ロケーションコード
         ,iv_tran_subinv_code      => gt_lot_info_tab(ln_count).via_subinv_code                 -- 転送先保管場所コード
         ,iv_tran_loc_code         => NULL                                                      -- 転送先ロケーションコード
         ,iv_sign_div              => cv_sign_div_0                                             -- 符号区分
         ,iv_source_code           => cv_source_code                                            -- ソースコード
         ,iv_relation_key          => gt_lot_info_tab(ln_count).transaction_id                  -- 紐付けキー
         ,iv_reason                => NULL                                                      -- 事由
         ,iv_reserve_trx_type_code => NULL                                                      -- 引当時取引タイプコード
         ,on_trx_id                => lt_trx_id                                                 -- ロット別取引ID
         ,ov_errbuf                => lv_errbuf                                                 -- エラーメッセージ
         ,ov_retcode               => lv_retcode                                                -- リターン・コード(0:正常、2:エラー)
         ,ov_errmsg                => lv_errmsg                                                 -- ユーザー・エラーメッセージ
      );
      -- 戻り値のリターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- エラーメッセージの取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10489
                     , iv_token_name1  => cv_tkn_err_msg
                     , iv_token_value1 => lv_errmsg
                     );
        RAISE global_process_expt;
      END IF;
--
      -- 転送先倉庫を更新
      BEGIN
--
        UPDATE  xxcoi_lot_transactions
        SET     inside_warehouse_code = gt_lot_info_tab(ln_count).inside_warehouse_code
        WHERE   transaction_id    = lt_trx_id
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_msg_kbn_coi
                         ,iv_name         =>  cv_msg_coi_10743
                         ,iv_token_name1  =>  cv_tkn_transaction_id
                         ,iv_token_value1 =>  lt_trx_id
                       );
          RAISE global_process_expt;
      END;
--
      -- 共通関数：ロット別手持数量反映
      xxcoi_common_pkg.ins_upd_del_lot_onhand(
          in_inv_org_id       => gn_inv_org_id                                      -- 在庫組織ID
         ,iv_base_code        => gt_lot_info_tab(ln_count).outside_base_code        -- 拠点コード
         ,iv_subinv_code      => gt_lot_info_tab(ln_count).start_subinv_code        -- 保管場所コード
         ,iv_loc_code         => gt_lot_info_tab(ln_count).location_code            -- ロケーションコード
         ,in_child_item_id    => gt_lot_info_tab(ln_count).child_item_id            -- 子品目ID
         ,iv_lot              => gt_lot_info_tab(ln_count).lot                      -- ロット(賞味期限)
         ,iv_diff_sum_code    => gt_lot_info_tab(ln_count).difference_summary_code  -- 固有記号
         ,in_case_in_qty      => gt_lot_info_tab(ln_count).case_in_quantity         -- 入数
         ,in_case_qty         => gt_lot_info_tab(ln_count).case_qty * (-1)          -- ケース数
         ,in_singly_qty       => gt_lot_info_tab(ln_count).singly_qty * (-1)        -- バラ数
         ,in_summary_qty      => ((gt_lot_info_tab(ln_count).case_in_quantity * NVL(gt_lot_info_tab(ln_count).case_qty, 0)) + NVL(gt_lot_info_tab(ln_count).singly_qty, 0)) * (-1)
                                                                                    -- 取引数量
         ,ov_errbuf           => lv_errbuf                                          -- エラーメッセージ
         ,ov_retcode          => lv_retcode                                         -- リターン・コード(0:正常、2:エラー)
         ,ov_errmsg           => lv_errmsg                                          -- ユーザー・エラーメッセージ
      );
      -- 戻り値のリターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- エラーメッセージの取得
        
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                     , iv_name         => cv_msg_coi_10490
                     , iv_token_name1  => cv_tkn_err_msg
                     , iv_token_value1 => lv_errmsg
                     );
        RAISE global_process_expt;
      END IF;
--
      ln_count  :=  ln_count + 1;
--
    END LOOP lot_info_loop;
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
  END cre_lot_transactions;
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
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_error_cnt         := 0; -- エラー件数
    gn_warn_cnt          := 0; -- スキップ件数
    gv_key_data          := cv_key_data;  -- キー情報
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
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_api_warn_expt;
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．IFデータ削除
    -- ============================================
    delete_if_data(
       in_file_id        -- ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      -- 正常終了の場合はコミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロードIFループ
    <<file_if_loop>>
    --１行目はカラム行の為、２行目から処理する
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
--
      -- A-4.の処理は、エラーチェックの中から呼ぶ
      -- ============================================
      -- A-5．エラーチェック
      -- ============================================
      err_check(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP file_if_loop;
--
    -- 登録フラグがTRUEで、エラーが一件も無い場合のみ、以下の登録処理を実施
    IF gb_insert_flg  AND gv_check_result = cv_const_y THEN
      -- ============================================
      -- A-6．入出庫情報の作成
      -- ============================================
      cre_inv_transactions(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-7．ロット別取引明細の作成、ロット別手持数量の変更
      -- ============================================
      cre_lot_transactions(
         lv_errbuf         -- エラー・メッセージ           --# 固定 #
        ,lv_retcode        -- リターン・コード             --# 固定 #
        ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- エラーレコードが存在する場合
    IF ( gn_error_cnt <> 0 ) THEN
      gb_err_flag := TRUE; -- 想定内エラーフラグ:TRUE
      ov_retcode := cv_status_error; -- 終了ステータス：異常終了
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
    IF (  lv_retcode = cv_status_error
       OR lv_retcode = cv_status_warn ) THEN
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
    IF ( gb_err_flag = TRUE ) THEN
      gn_normal_cnt := 0; -- 成功件数
      gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt ); -- スキップ件数
    -- 想定外エラーの場合
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 1; -- エラー件数
      gn_warn_cnt   := 0; -- スキップ件数
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
END XXCOI003A19C;
/