CREATE OR REPLACE PACKAGE BODY XXCMM003A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMM003A41C(body)
 * Description      : 顧客関連一括更新
 * MD.050           : 顧客関連一括更新 MD050_CMM_003_A41
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  validate_cust_wrel     顧客関連一括更新用ワークデータ妥当性チェック(A-4)
 *  proc_party_rel_inact   パーティ関連無効化データ更新処理(A-5)
 *  proc_party_rel_active  パーティ関連有効化データ登録処理(A-6)
 *  proc_cust_rel_inact    顧客関連無効化データ更新処理(A-7)
 *  proc_cust_rel_active   顧客関連有効化データ登録処理(A-8)
 *  loop_main              顧客関連一括更新用ワークデータ取得(A-3)
 *  get_if_data            ファイルアップロードI/Fテーブル取得処理(A-2)
 *  proc_comp              終了処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/11/26    1.0   M.Takasaki       新規作成
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
  --*** ロックエラー例外 ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';           -- アプリケーション短縮名
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM003A41C';    -- パッケージ名
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';               -- カンマ
  -- 各種コード値
  cv_file_format_pa      CONSTANT VARCHAR2(3)   := '505';             -- ファイルフォーマット:パーティ関連
  cv_file_format_cu      CONSTANT VARCHAR2(3)   := '506';             -- ファイルフォーマット:顧客関連
  --
  cv_cu_customer         CONSTANT VARCHAR2(2)   := '10';              -- 顧客区分:顧客
  cv_cu_trust_corp       CONSTANT VARCHAR2(2)   := '13';              -- 顧客区分:法人管理先
  cv_cu_ar_manage        CONSTANT VARCHAR2(2)   := '14';              -- 顧客区分:売掛管理先顧客
  --
  cv_rel_bill            CONSTANT VARCHAR2(1)   := '1';               -- 関連分類:請求 コード
  cv_rel_bill_name       CONSTANT VARCHAR2(10)  := '請求関連';        -- 関連分類:請求 名称
  cv_rel_cash            CONSTANT VARCHAR2(1)   := '2';               -- 関連分類:入金 コード
  cv_rel_cash_name       CONSTANT VARCHAR2(10)  := '入金関連';        -- 関連分類:入金 名称
  --
  cv_active_csv          CONSTANT VARCHAR2(1)   := 'Y';               -- 登録ステータス:有効(CSV)
  cv_active_set          CONSTANT VARCHAR2(1)   := 'A';               -- 登録ステータス:有効(設定値)
  cv_inactive_csv        CONSTANT VARCHAR2(1)   := 'N';               -- 登録ステータス:無効(CSV)
  cv_inactive_set        CONSTANT VARCHAR2(1)   := 'I';               -- 登録ステータス:無効(設定値)
  --
  cv_hr_type_org         CONSTANT VARCHAR2(30)  := 'ORGANIZATION';    -- パーティ関連オブジェクトタイプ
  cv_hr_table_name       CONSTANT VARCHAR2(30)  := 'HZ_PARTIES';      -- パーティ関連テーブル名
  cv_hr_rel_type_credit  CONSTANT VARCHAR2(30)  := '与信関連';        -- パーティ関連タイプ
  cv_hr_rel_code_urikake CONSTANT VARCHAR2(30)  := '売掛管理先';      -- パーティ関連コード
  --
  cv_lookup_yes          CONSTANT VARCHAR2(1)   := 'Y';               -- LOOKUP表 YES
  cv_site_use_bill_to    CONSTANT VARCHAR2(10)  := 'BILL_TO';         -- 使用目的:'請求先'
  cv_site_use_ship_to    CONSTANT VARCHAR2(10)  := 'SHIP_TO';         -- 使用目的:'出荷先'
  cv_acc_yes             CONSTANT VARCHAR2(1)   := 'Y';
  cv_acc_no              CONSTANT VARCHAR2(1)   := 'N';
  cv_relationship_type_all    hz_cust_acct_relate.relationship_type%TYPE := 'ALL';
  -- データ項目定義DECODE用
  cv_varchar             CONSTANT VARCHAR2(10)  := 'VARCHAR2';                                          -- 文字列     LOOKUP表
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := '0';                                                 -- 文字列     共通関数用コード
  cv_number              CONSTANT VARCHAR2(10)  := 'NUMBER';                                            -- 数値       LOOKUP表
  cv_number_cd           CONSTANT VARCHAR2(1)   := '1';                                                 -- 数値       共通関数用コード
  cv_date                CONSTANT VARCHAR2(10)  := 'DATE';                                              -- 日付       LOOKUP表
  cv_date_cd             CONSTANT VARCHAR2(1)   := '2';                                                 -- 日付       共通関数用コード
  cv_not_null            CONSTANT VARCHAR2(1)   := '1';                                                 -- 必須フラグ LOOKUP表
  cv_null_ok             CONSTANT VARCHAR2(10)  := 'NULL_OK';                                           -- 任意項目   共通関数用コード
  cv_null_ng             CONSTANT VARCHAR2(10)  := 'NULL_NG';                                           -- 必須項目   共通関数用コード
  -- プロファイル名
  cv_prf_org_id          CONSTANT VARCHAR2(10)  := 'ORG_ID';                                            -- MO:営業単位取得用コード
  cv_prf_item_num_cu     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A41_CUST_REL_NUM';                        -- プロファイル「顧客関連一括更新データ項目数（顧客関連）」
  cv_prf_item_num_pa     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A41_PARTY_REL_NUM';                       -- プロファイル「顧客関連一括更新データ項目数（パーティ関連）」
  --  LOOKUP表
  cv_lookup_file_up_obj  CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';                            -- ファイルアップロードオブジェクト
  cv_lookup_curel_def_pa CONSTANT VARCHAR2(30)  := 'XXCMM1_003A41_PARTY_REL_DEF';                       -- LOOKUP:顧客関連一括更新データ項目定義(パーティ関連)
  cv_lookup_curel_def_cu CONSTANT VARCHAR2(30)  := 'XXCMM1_003A41_CUST_REL_DEF';                        -- LOOKUP:顧客関連一括更新データ項目定義(顧客関連)
  cv_lookup_relate_class CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KANREN_BUNRUI';                          -- LOOKUP:顧客関連一括更新データ項目定義(パーティ関連)
  --  メッセージ
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                                  -- プロファイル取得エラー
  cv_msg_xxcmm_00008     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';                                  -- ロックエラー
  cv_msg_xxcmm_00012     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';                                  -- テーブル削除エラー
  cv_msg_xxcmm_00018     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';                                  -- 業務日付取得エラー
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                                  -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                                  -- CSVファイル名ノート
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                                  -- FILE_IDノート
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                                  -- フォーマットノート
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                                  -- データ項目数エラー
  cv_msg_xxcmm_10323     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10323';                                  -- パラメータNULLエラー
  cv_msg_xxcmm_10324     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10324';                                  -- 取得失敗エラー
  cv_msg_xxcmm_10328     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10328';                                  -- 値チェックエラー
  cv_msg_xxcmm_10330     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10330';                                  -- 参照コード存在チェックエラー
  cv_msg_xxcmm_10335     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10335';                                  -- データ登録エラー
  cv_msg_xxcmm_10337     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10337';                                  -- IFロック取得エラー
  cv_msg_xxcmm_10338     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10338';                                  -- 項目定義エラー
  cv_msg_xxcmm_10347     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10347';                                  -- 顧客マスタチェックエラー
  cv_msg_xxcmm_10348     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10348';                                  -- CSV内容重複エラー
  cv_msg_xxcmm_10349     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10349';                                  -- パーティ関連無効化チェックエラー
  cv_msg_xxcmm_10350     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10350';                                  -- パーティ関連有効化未来日チェックエラー
  cv_msg_xxcmm_10351     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10351';                                  -- パーティ関連有効化チェックエラー
  cv_msg_xxcmm_10352     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10352';                                  -- 顧客関連無効化チェックエラー
  cv_msg_xxcmm_10353     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10353';                                  -- 顧客関連有効化チェックエラー
  cv_msg_xxcmm_10354     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10354';                                  -- 標準APIエラー
  cv_msg_xxcmm_10355     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10355';                                  -- 関連適用日チェックエラー
  -- トークン名
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                            -- ファイルID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                             -- フォーマット
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                         -- プロファイル名
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                        -- ファイルアップロード名称
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                          -- ファイル名
  cv_tkn_param_name      CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                                         -- パラメータ名
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                              -- 値
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                              -- テーブル
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                              -- 件数
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                      -- 行番号
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                              -- 項目
  cv_tkn_cust_class      CONSTANT VARCHAR2(20)  := 'CUST_CLASS';                                         -- 顧客区分
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                                          -- 顧客コード
  cv_tkn_rep_cont        CONSTANT VARCHAR2(20)  := 'REP_CONT';                                           -- 重複内容
  cv_tkn_rel_cust_code   CONSTANT VARCHAR2(20)  := 'REL_CUST_CODE';                                      -- 関連先顧客コード
  cv_tkn_apply_date      CONSTANT VARCHAR2(20)  := 'APPLY_DATE';                                         -- 関連適用日
  cv_tkn_rel_cls_name    CONSTANT VARCHAR2(20)  := 'REL_CLS_NAME';                                       -- 関連分類名称
  cv_tkn_api_step        CONSTANT VARCHAR2(20)  := 'API_STEP';                                           -- API 処理ステップ名
  cv_tkn_api_name        CONSTANT VARCHAR2(20)  := 'API_NAME';                                           -- API 物理名
  cv_tkn_seq_num         CONSTANT VARCHAR2(20)  := 'SEQ_NUM';                                            -- シーケンス番号
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                            -- エラー内容
  cv_tkn_ng_table        CONSTANT VARCHAR2(20)  := 'NG_TABLE';                                           -- ロック取得NGテーブル名
  -- トークン値
  --
  cv_tkv_file_id         CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkv_format          CONSTANT VARCHAR2(30)  := 'フォーマットパターン';
  --
  cv_tkv_prf_item_num_cu CONSTANT VARCHAR2(60)  := 'XXCMM:顧客関連一括更新データ項目数(顧客関連)';       -- プロファイル「顧客関連一括更新データ項目数（顧客関連）」名称
  cv_tkv_prf_item_num_pa CONSTANT VARCHAR2(60)  := 'XXCMM:顧客関連一括更新データ項目数(パーティ関連)';   -- プロファイル「顧客関連一括更新データ項目数（パーティ関連）」名称
  cv_tkv_prf_org_id      CONSTANT VARCHAR2(30)  := 'MO:営業単位';                                        -- MO:営業単位
  --
  cv_tkv_rel_def         CONSTANT VARCHAR2(40)  := '顧客関連一括更新ワーク定義情報';
  cv_tkv_upload_name     CONSTANT VARCHAR2(40)  := 'ファイルアップロード名称';
  cv_tkv_table_xwk_cust  CONSTANT VARCHAR2(40)  := '顧客関連一括更新ワーク';
  cv_tkv_table_file_if   CONSTANT VARCHAR2(40)  := 'ファイルアップロードIF';
  cv_tkv_cu_class_code   CONSTANT VARCHAR2(40)  := '顧客区分';
  cv_tkv_recu_class_code CONSTANT VARCHAR2(40)  := '関連先顧客区分';
  cv_tkv_status          CONSTANT VARCHAR2(40)  := '登録ステータス';
  cv_tkv_relate_class    CONSTANT VARCHAR2(40)  := '顧客関連分類';
  cv_tkv_rep_cont_pa     CONSTANT VARCHAR2(40)  := '関連先顧客,登録ステータス';                          -- CSV重複内容：パーティ関連
  cv_tkv_rep_cont_cu1    CONSTANT VARCHAR2(40)  := '関連先顧客,登録ステータス,顧客関連分類';             -- CSV重複内容：顧客関連1
  cv_tkv_rep_cont_cu2    CONSTANT VARCHAR2(40)  := '関連先顧客,登録ステータス,顧客';                     -- CSV重複内容：顧客関連2
  cv_tkv_lock_party      CONSTANT VARCHAR2(30)  := 'パーティ';                                           -- ロックテーブル
  cv_tkv_lock_party_rel  CONSTANT VARCHAR2(30)  := 'パーティ関連';                                       -- ロックテーブル
  cv_tkv_lock_cust_rel   CONSTANT VARCHAR2(30)  := '顧客関連';                                           -- ロックテーブル
  cv_tkv_lock_cust_site  CONSTANT VARCHAR2(30)  := '顧客サイト';                                         -- ロックテーブル
  cv_tkv_lock_cust_uses  CONSTANT VARCHAR2(30)  := '顧客事業所';                                         -- ロックテーブル
  cv_tkv_apinm_pa_get    CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.get_relationship_rec';         -- 標準API：パーティ関連取得
  cv_tkv_apinm_pa_upload CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.update_relationship';          -- 標準API：パーティ関連更新
  cv_tkv_apinm_pa_create CONSTANT VARCHAR2(60)  := 'hz_relationship_v2pub.create_relationship';          -- 標準API：パーティ関連登録
  cv_tkv_apinm_cu_get    CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.get_cust_acct_relate_rec';     -- 標準API：顧客関連取得
  cv_tkv_apinm_cu_upload CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.update_cust_acct_relate';      -- 標準API：顧客関連更新
  cv_tkv_apinm_cu_create CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.create_cust_acct_relate';      -- 標準API：顧客関連登録
  cv_tkv_apinm_suse_get  CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.get_cust_site_use_rec';   -- 標準API：顧客使用目的レコード取得
  cv_tkv_apinm_suse_upld CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.update_cust_site_use';    -- 標準API：顧客使用目的レコード更新
  cv_tkv_apist_pa_get    CONSTANT VARCHAR2(30)  := 'パーティ関連取得';                                   -- 標準API：パーティ関連取得
  cv_tkv_apist_pa_upload CONSTANT VARCHAR2(30)  := 'パーティ関連更新';                                   -- 標準API：パーティ関連更新
  cv_tkv_apist_pa_create CONSTANT VARCHAR2(30)  := 'パーティ関連登録';                                   -- 標準API：パーティ関連登録
  cv_tkv_apist_cu_get    CONSTANT VARCHAR2(30)  := '顧客関連取得';                                       -- 標準API：顧客関連取得
  cv_tkv_apist_cu_upload CONSTANT VARCHAR2(30)  := '顧客関連更新';                                       -- 標準API：顧客関連更新
  cv_tkv_apist_cu_create CONSTANT VARCHAR2(30)  := '顧客関連登録';                                       -- 標準API：顧客関連登録
  cv_tkv_apist_suse_get  CONSTANT VARCHAR2(30)  := '顧客使用目的取得';                                   -- 標準API：顧客使用目的レコード取得
  cv_tkv_apist_suse_upld CONSTANT VARCHAR2(30)  := '顧客使用目的更新';                                   -- 標準API：顧客使用目的レコード更新
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目定義の情報
  TYPE g_item_def_rtype IS RECORD(
       item_name            VARCHAR2(100)                                                                -- 項目名
     , item_attribute       VARCHAR2(100)                                                                -- 項目属性
     , item_essential       VARCHAR2(100)                                                                -- 必須フラグ
     , int_length           NUMBER                                                                       -- 項目の長さ(整数部分)
     , dec_length           NUMBER                                                                       -- 項目の長さ(小数点以下)
  );
  TYPE g_item_def_ttype  IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;
  --
  -- 有効化・無効化用のキー情報
  TYPE g_keys_in_act_rtype IS RECORD(
       cust_class_code        xxcmm_wk_cust_relate_upload.customer_class_code%TYPE                       -- 関連元 顧客区分
     , cust_code              xxcmm_wk_cust_relate_upload.customer_code%TYPE                             -- 関連元 顧客コード
     , cust_party_id          hz_parties.party_id%TYPE                                                   -- 関連元 パーティID
     , cust_account_id        hz_cust_accounts.cust_account_id%TYPE                                      -- 関連元 顧客アカウントID
     , rel_cust_class_code    xxcmm_wk_cust_relate_upload.rel_customer_class_code%TYPE                   -- 関連先 顧客区分
     , rel_cust_code          xxcmm_wk_cust_relate_upload.rel_customer_code%TYPE                         -- 関連先 顧客コード
     , rel_cust_party_id      hz_parties.party_id%TYPE                                                   -- 関連先 パーティID
     , rel_cust_account_id    hz_cust_accounts.cust_account_id%TYPE                                      -- 関連先 顧客アカウントID
     , relate_class           xxcmm_wk_cust_relate_upload.relate_class%TYPE                              -- 顧客関連分類
     , rel_apply_date         xxcmm_wk_cust_relate_upload.relate_apply_date%TYPE                         -- 関連適用日
     , line_no                xxcmm_wk_cust_relate_upload.line_no%TYPE                                   -- 行番号
  );
  TYPE g_keys_ia_ttype   IS TABLE OF g_keys_in_act_rtype   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                    NUMBER;                            -- パラメータ格納用変数:ファイルID
  gv_format                     VARCHAR2(100);                     -- パラメータ格納用変数:フォーマットパターン
  gd_process_date               DATE;                              -- 業務日付
  gd_system_date                DATE;                              -- システム日付
  gn_item_num                   NUMBER;                            -- 顧客関連一括更新データ項目数
  gv_org_id                     VARCHAR2(50);                      -- MO:営業単位
  gn_inact_cnt                  NUMBER;                            -- 無効化用のキーIndex
  gn_active_cnt                 NUMBER;                            -- 有効化用のキーIndex
--
  --テーブル形
  g_cust_rel_def_tab            g_item_def_ttype;                  -- テーブル型変数の宣言
  g_inact_keys_tab              g_keys_ia_ttype;                   -- テーブル型変数の宣言(無効化用のキー退避)
  g_act_keys_tab                g_keys_ia_ttype;                   -- テーブル型変数の宣言(有効化用のキー退避)
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    -- 顧客関連一括更新用ワーク 取得
    CURSOR get_wk_cust_rel_cur
    IS
      SELECT xwcup.file_id                  AS file_id                 -- ファイルID
           , xwcup.line_no                  AS line_no                 -- 行番号
           , xwcup.customer_class_code      AS cust_class_code         -- 顧客区分
           , xwcup.customer_code            AS cust_code               -- 顧客コード
           , xwcup.rel_customer_class_code  AS rel_cust_class_code     -- 関連先顧客区分
           , xwcup.rel_customer_code        AS rel_cust_code           -- 関連先顧客コード
           , xwcup.relate_class             AS relate_class            -- 顧客関連分類
           , xwcup.status                   AS status                  -- 登録ステータス
           , xwcup.relate_apply_date        AS rel_apply_date          -- 関連適用日
           , xwcup.created_by               AS created_by              -- WHO:作成者
           , xwcup.creation_date            AS creation_date           -- WHO:作成日
           , xwcup.last_updated_by          AS last_updated_by         -- WHO:最終更新者
           , xwcup.last_update_date         AS last_update_date        -- WHO:最終更新日
           , xwcup.last_update_login        AS last_update_login       -- WHO:最終更新ログイン
           , xwcup.request_id               AS request_id              -- WHO:要求ID
           , xwcup.program_application_id   AS program_application_id  -- WHO:コンカレント・プログラム・アプリケーションID
           , xwcup.program_id               AS program_id              -- WHO:コンカレント・プログラムID
           , xwcup.program_update_date      AS program_update_date     -- WHO:プログラム更新日
        FROM xxcmm_wk_cust_relate_upload xwcup     -- 顧客関連一括更新用ワーク
       WHERE xwcup.request_id = cn_request_id      -- 要求ID
      ORDER BY xwcup.line_no                       -- 行番号
      ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2          -- ファイルID
   ,iv_format     IN  VARCHAR2          -- フォーマットパターン
   ,ov_errbuf     OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_step                   VARCHAR2(10);                                     -- ステップ
    lv_tkn_value              VARCHAR2(100);                                    -- トークン値
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    ln_cnt                    NUMBER;                                           -- カウンタ
    lv_upload_obj             VARCHAR2(100);                                    -- ファイルアップロード名称
    -- ファイルアップロードIFテーブル項目
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- ファイル名格納用
    lt_created_by             xxccp_mrp_file_ul_interface.created_by%TYPE;      -- 作成者格納用
    lt_creation_date          xxccp_mrp_file_ul_interface.creation_date%TYPE;   -- 作成日格納用
    -- INパラメータ出力用
    lv_up_name                VARCHAR2(1000);                                   -- アップロード名称
    lv_file_name              VARCHAR2(1000);                                   -- ファイル名
    lv_file_id                VARCHAR2(1000);                                   -- ファイルID
    lv_file_format            VARCHAR2(1000);                                   -- フォーマット
--
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR     get_cust_rel_def_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- 内容
              ,DECODE(flv.attribute1
                    , cv_varchar ,cv_varchar_cd
                    , cv_number  ,cv_number_cd
                    , cv_date_cd)                  AS item_attribute            -- 項目属性
              ,DECODE(flv.attribute2
                    , cv_not_null, cv_null_ng
                    , cv_null_ok)                  AS item_essential            -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)           AS int_length                -- 項目の長さ(整数部分)
              ,TO_NUMBER(flv.attribute4)           AS dec_length                -- 項目の長さ(小数点以下)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP表
      WHERE  (
               ( -- フォーマットパターン「パーティ関連」の場合
                      gv_format       = cv_file_format_pa  
                 AND flv.lookup_type  = cv_lookup_curel_def_pa
               ) OR
               ( -- フォーマットパターン「顧客関連」の場合
                     gv_format        = cv_file_format_cu 
                 AND flv.lookup_type  = cv_lookup_curel_def_cu
               )
             )
      AND      flv.enabled_flag = cv_lookup_yes                                 -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- 適用終了日
      ORDER BY flv.lookup_code;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;                              -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;                              -- プロファイル取得エラー
    process_date_expt         EXCEPTION;                              -- 業務日付取得失敗エラー
    select_expt               EXCEPTION;                              -- 取得失敗エラー
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
    -- A-1.1 入力パラメータ（FILE_ID、フォーマット）のNULLチェック
    --==============================================================
    lv_step := 'A-1.1';
    -- 入力パラメータ.FILE_IDがNULLの場合
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_tkv_file_id;
      RAISE get_param_expt;
    END IF;
    -- 入力パラメータ.フォーマットがNULLの場合
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_tkv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 プロファイル取得
    --==============================================================
    lv_step := 'A-1.2';
    -- フォーマットパターン「パーティ関連」の場合
    IF ( gv_format = cv_file_format_pa ) THEN
      -- XXCMM:顧客関連一括更新データ項目数（パーティ関連）
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_pa));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_tkv_prf_item_num_pa;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- フォーマットパターン「顧客関連」の場合
    IF ( gv_format = cv_file_format_cu ) THEN
      -- XXCMM:顧客関連一括更新データ項目数（顧客関連）
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_cu));
      -- 取得エラー時
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_tkv_prf_item_num_cu;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    --MO:営業単位 取得
    gv_org_id := FND_PROFILE.VALUE( cv_prf_org_id );
    IF ( gv_org_id IS NULL ) THEN
      lv_tkn_value := cv_tkv_prf_org_id;
      RAISE get_profile_expt;
    END IF;
    --==============================================================
    -- A-1.3 業務日付取得
    --==============================================================
    lv_step := 'A-1.3';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULLチェック
    IF ( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.4 顧客関連一括更新ワーク定義情報の取得
    --==============================================================
    lv_step := 'A-1.4';
    -- カウンター初期化
    ln_cnt := 0;
    -- テーブル定義取得LOOP
    <<rel_def_loop>>
    FOR get_cust_rel_def_rec IN get_cust_rel_def_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_cust_rel_def_tab(ln_cnt).item_name      := get_cust_rel_def_rec.item_name;       -- 項目名
      g_cust_rel_def_tab(ln_cnt).item_attribute := get_cust_rel_def_rec.item_attribute;  -- 項目属性
      g_cust_rel_def_tab(ln_cnt).item_essential := get_cust_rel_def_rec.item_essential;  -- 必須フラグ
      g_cust_rel_def_tab(ln_cnt).int_length     := get_cust_rel_def_rec.int_length;      -- 項目の長さ(整数部分)
      g_cust_rel_def_tab(ln_cnt).dec_length     := get_cust_rel_def_rec.dec_length;      -- 項目の長さ(小数点以下)
    END LOOP rel_def_loop
    ;
    IF ( ln_cnt = 0 ) THEN
      lv_tkn_value := cv_tkv_rel_def;
      RAISE select_expt;
    END IF;
    --
    --==============================================================
    -- A-1.5 ファイルアップロード名称取得
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT flv.meaning      AS meaning
        INTO lv_upload_obj
        FROM fnd_lookup_values_vl flv                                         -- LOOKUP表
       WHERE flv.lookup_type  = cv_lookup_file_up_obj                         -- ファイルアップロードオブジェクト
         AND flv.lookup_code  = gv_format                                     -- ファイルフォーマット
         AND flv.enabled_flag = cv_lookup_yes                                 -- 使用可能フラグ
         AND NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
         AND NVL(flv.end_date_active  , gd_process_date) >= gd_process_date   -- 適用終了日
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_tkv_upload_name;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.6 顧客関連一括更新用ＣＳＶファイル情報取得
    --==============================================================
    lv_step := 'A-1.6';
    SELECT   fui.file_name      AS file_name                                    -- ファイル名
            ,fui.created_by     AS created_by                                   -- 作成者
            ,fui.creation_date  AS creation_date                                -- 作成日
    INTO     lt_csv_file_name
            ,lt_created_by
            ,lt_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                                   -- ファイルアップロードIFテーブル
    WHERE    fui.file_id           = gn_file_id                                 -- ファイルID
      AND    fui.file_content_type = gv_format                                  -- ファイルフォーマット
    FOR UPDATE NOWAIT
    ;
    --
    --==============================================================
    -- A-1.7 INパラメータの出力
    --==============================================================
    lv_step := 'A-1.7';
    -- ファイルアップロード名称
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00021                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name                       -- トークンコード1
                       ,iv_token_value1 => lv_upload_obj                        -- トークン値1
                      );
    -- CSVファイル名
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- CSVファイル名の出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00022                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name                     -- トークンコード1
                       ,iv_token_value1 => lt_csv_file_name                     -- トークン値1
                      );
    -- ファイルID
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00023                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id                       -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- トークン値1
                      );
    -- フォーマットパターン
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format                    -- トークンコード1
                      ,iv_token_value1 => gv_format                             -- トークン値1
                      );
    -- 出力に表示
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    -- ログに表示
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10323            -- メッセージ
                    ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ
                    ,iv_token_name1  => cv_tkn_ng_profile             -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** 業務日付取得失敗エラー ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00018            -- メッセージ
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** 取得失敗エラー ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10324            -- メッセージ
                    ,iv_token_name1  => cv_tkn_value                  -- トークンコード1
                    ,iv_token_value1 => lv_tkn_value                  -- トークン値1
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10337            -- メッセージ
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
     -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
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
   * Procedure Name   : validate_cust_wrel
   * Description      : 顧客関連一括更新用ワークデータ妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE validate_cust_wrel(
    i_cust_rel_rec     IN  get_wk_cust_rel_cur%ROWTYPE,       -- 顧客関連一括更新用ワーク情報
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ                  -- # 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード                    -- # 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        -- # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_cust_wrel'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_un_search  CONSTANT VARCHAR2(1) := '0';                       -- CSVファイル内無効化データ検索:有
    cv_search     CONSTANT VARCHAR2(1) := '1';                       -- CSVファイル内無効化データ検索:無
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);
    lv_step_status            VARCHAR2(1);                           -- STEPチェック
    lv_check_status           VARCHAR2(1);                           -- 妥当性チェックステータス
    ln_chk_cnt                NUMBER;                                -- 存在チェックカウント用
    lv_csv_inact_search       VARCHAR2(1);                           -- CSVファイル内無効化データ検索フラグ
    lv_rel_cls_name           VARCHAR2(10);                          -- 顧客関連分類名称
    lv_char_rel_date          VARCHAR2(10);                          -- YYYY/MM/DD形式の関連適用日
    --
    lt_cust_party_id          hz_parties.party_id%TYPE;              -- 関連元 パーティID
    lt_cust_account_id        hz_cust_accounts.cust_account_id%TYPE; -- 関連元 顧客アカウントID
    lt_rel_cust_party_id      hz_parties.party_id%TYPE;              -- 関連先 パーティID
    lt_rel_cust_account_id    hz_cust_accounts.cust_account_id%TYPE; -- 関連先 顧客アカウントID
    --
    lv_pa_chk_cust_code       VARCHAR2(9);                           -- パーティ関連チェック用 最新有効顧客コード
    ld_pa_chk_start_date      DATE;                                  -- パーティ関連チェック用 最新有効開始日
    ld_pa_chk_end_date        DATE;                                  -- パーティ関連チェック用 最新有効終了日
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- *** 顧客マスタ取得カーソル *** --
    CURSOR get_cust_id_cur (
      p_customer_class_code  IN VARCHAR2,  -- 顧客区分
      p_account_number       IN VARCHAR2   -- 顧客コード
    )IS
      SELECT hca.party_id            AS party_id               -- パーティID
           , hca.cust_account_id     AS cust_account_id        -- 顧客ID
        FROM hz_cust_accounts hca   --標準:顧客マスタ
       WHERE hca.customer_class_code = p_customer_class_code   -- 顧客区分
         AND hca.account_number      = p_account_number        -- 顧客コード
    ;
    --
    -- *** パーティ関連 CSV重複チェック用カーソル *** --
    CURSOR party_rel_csv_repeat_check_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- 顧客関連一括更新ワーク
       WHERE xwcru.request_id              = cn_request_id                      --  要求ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  行番号
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  関連先顧客区分
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  関連先顧客コード
         AND xwcru.status                  = i_cust_rel_rec.status              --  登録ステータス
    ;
    --
    -- *** パーティ関連 無効化データ チェック用カーソル *** --
    CURSOR party_rel_inact_check_cur
    IS
      SELECT MAX(TRUNC( hr.start_date ))  AS start_date
           , MAX(TRUNC( hr.end_date ))    AS end_date
        FROM hz_relationships  hr                           -- パーティ関連
       WHERE -- 関連元顧客情報
             hr.subject_type       = cv_hr_type_org         --  サブジェクトタイプ:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  サブジェクトテーブル名:HZ_PARTIES
         AND hr.subject_id         = lt_cust_party_id       --  サブジェクトID:関連元パーティID
             -- 関連先顧客情報
         AND hr.object_type        = cv_hr_type_org         --  オブジェクトタイプ:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  オブジェクトタイプ:HZ_PARTIES
         AND hr.object_id          = lt_rel_cust_party_id   --  オブジェクトID:関連先パーティID
             --
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  パーティ関連タイプ:与信関連
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  パーティ関連コード:売掛管理先
         AND hr.status             = cv_active_set          --  ステータス:A(有効)
    ;
    --
    -- *** パーティ関連 有効化データ チェック用カーソル *** --
    CURSOR party_rel_active_check_cur
    IS
      SELECT hca.account_number           AS cust_code
           , MAX(TRUNC( hr.start_date ))  AS start_date
           , MAX(TRUNC( hr.end_date ))    AS end_date
        FROM hz_relationships  hr             -- パーティ関連
           , Hz_cust_accounts  hca            -- 関連元顧客マスタ
           , ( -- インラインビュー:最新日付
                SELECT MAX(TRUNC( hr.start_date )) AS max_start_date
                  FROM hz_relationships  hr   -- パーティ関連
                 WHERE -- 関連元顧客情報
                       hr.subject_type       = cv_hr_type_org         --  サブジェクトタイプ:ORGANIZATION
                   AND hr.subject_table_name = cv_hr_table_name       --  サブジェクトテーブル名:HZ_PARTIES
                       -- 関連先顧客情報
                   AND hr.object_type        = cv_hr_type_org         --  オブジェクトタイプ:ORGANIZATION
                   AND hr.object_table_name  = cv_hr_table_name       --  オブジェクトタイプ:HZ_PARTIES
                   AND hr.object_id          = lt_rel_cust_party_id   --  オブジェクトID:関連先パーティID
                       --
                   AND hr.relationship_type  = cv_hr_rel_type_credit  --  パーティ関連タイプ:与信関連
                   AND hr.relationship_code  = cv_hr_rel_code_urikake --  パーティ関連コード:売掛管理先
                   AND hr.status             = cv_active_set          --  ステータス:A(有効)
             ) hr_max
       WHERE -- 関連元顧客情報
             hr.subject_type       = cv_hr_type_org         --  サブジェクトタイプ:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  サブジェクトテーブル名:HZ_PARTIES
         AND hr.subject_id         = hca.party_id           --  サブジェクトID = 関連元顧客マスタ.パーティID
             -- 関連先顧客情報
         AND hr.object_type        = cv_hr_type_org         --  オブジェクトタイプ:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  オブジェクトタイプ:HZ_PARTIES
         AND hr.object_id          = lt_rel_cust_party_id   --  オブジェクトID:関連先パーティID
             --
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  パーティ関連タイプ:与信関連
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  パーティ関連コード:売掛管理先
         AND hr.status             = cv_active_set          --  ステータス:A(有効)
         AND TRUNC( hr.start_date) = hr_max.max_start_date  --  開始日 = 最新開始日
      GROUP BY hca.account_number
    ;
    --
    -- *** 顧客関連共通 CSV重複チェック用カーソル1 *** --
    CURSOR cust_rel_csv_repeat_check1_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- 顧客関連一括更新ワーク
       WHERE xwcru.request_id              = cn_request_id                      --  要求ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  行番号
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  関連先顧客区分
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  関連先顧客コード
         AND xwcru.status                  = i_cust_rel_rec.status              --  登録ステータス
         AND xwcru.relate_class            = i_cust_rel_rec.relate_class        --  顧客関連分類
    ;
    -- *** 顧客関連共通 CSV重複チェック用カーソル2 *** --
    CURSOR cust_rel_csv_repeat_check2_cur
    IS
      SELECT COUNT(1)
        FROM xxcmm_wk_cust_relate_upload xwcru                                  -- 顧客関連一括更新ワーク
       WHERE xwcru.request_id              = cn_request_id                      --  要求ID
         AND xwcru.line_no                <> i_cust_rel_rec.line_no             --  行番号
         AND xwcru.rel_customer_class_code = i_cust_rel_rec.rel_cust_class_code --  関連先顧客区分
         AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       --  関連先顧客コード
         AND xwcru.status                  = i_cust_rel_rec.status              --  登録ステータス
         AND xwcru.customer_class_code     = i_cust_rel_rec.cust_class_code     --  顧客区分
         AND xwcru.customer_code           = i_cust_rel_rec.cust_code           --  顧客コード
    ;
    --
    -- *** 顧客関連 無効化データ チェック用カーソル *** --
    CURSOR cust_rel_inact_check_cur
    IS
      SELECT COUNT(1)
        FROM hz_cust_acct_relate_all hcarel                                     -- 顧客関連マスタ
       WHERE hcarel.org_id                  = gv_org_id                         --  組織ID
         AND hcarel.attribute1              = i_cust_rel_rec.relate_class       --  関連分類
         AND hcarel.status                  = cv_active_set                     --  ステータス:A(有効)
         AND hcarel.related_cust_account_id = lt_rel_cust_account_id            --  関連先顧客ID
         AND hcarel.cust_account_id         = lt_cust_account_id                --  顧客ID
    ;
    --
    -- *** 顧客関連 有効化データ チェック用カーソル *** --
    CURSOR cust_rel_active_check_cur
    IS
      -- 条件1:関連元と関連先で有効な関連分類(請求・入金)
      SELECT hca1.account_number     AS cust_code              -- 関連元顧客コード
           , hca2.account_number     AS rel_cust_code          -- 関連先顧客コード
           , hcarel.attribute1       AS relate_class           -- 顧客関連分類
        FROM hz_cust_accounts hca1          --標準:顧客マスタ 関連元
           , hz_cust_accounts hca2          --標準:顧客マスタ 関連先
           , hz_cust_acct_relate_all hcarel --標準:顧客関連マスタ
       WHERE hcarel.org_id                  = gv_org_id                         --  組織ID
         AND hcarel.attribute1              IN ( cv_rel_bill , cv_rel_cash )    --  関連分類(請求or入金)
         AND hcarel.status                  = cv_active_set                     --  ステータス:A(有効)
         AND hcarel.related_cust_account_id = hca2.cust_account_id              --  関連先顧客ID
         AND hcarel.cust_account_id         = hca1.cust_account_id              --  顧客ID
         AND hca2.account_number            = i_cust_rel_rec.rel_cust_code      --  関連先顧客コード
         AND hca1.account_number            = i_cust_rel_rec.cust_code          --  関連元顧客コード
      UNION ALL
      -- 条件2:関連先に対する有効な関連分類(関連元以外で指定した関連分類)
      SELECT hca1.account_number     AS cust_code              -- 関連元顧客コード
           , hca2.account_number     AS rel_cust_code          -- 関連先顧客コード
           , hcarel.attribute1       AS relate_class           -- 顧客関連分類
        FROM hz_cust_accounts hca1          --標準:顧客マスタ 関連元
           , hz_cust_accounts hca2          --標準:顧客マスタ 関連先
           , hz_cust_acct_relate_all hcarel --標準:顧客関連マスタ
       WHERE hcarel.org_id                  = gv_org_id                         --  組織ID
         AND hcarel.attribute1              = i_cust_rel_rec.relate_class       --  関連分類(請求or入金)
         AND hcarel.status                  = cv_active_set                     --  ステータス:A(有効)
         AND hcarel.related_cust_account_id = hca2.cust_account_id              --  関連先顧客ID
         AND hcarel.cust_account_id         = hca1.cust_account_id              --  顧客ID
         AND hca2.account_number            = i_cust_rel_rec.rel_cust_code      --  関連先顧客コード
         AND hca1.account_number           <> i_cust_rel_rec.cust_code          --  関連元顧客コード
    ;
    TYPE cust_rel_active_rec_ttype IS TABLE OF cust_rel_active_check_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    cust_rel_active_rec_tab  cust_rel_active_rec_ttype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックステータスの初期化
    lv_check_status := cv_status_normal;
--
    --==============================================================
    -- A-4.1 顧客区分チェック
    --==============================================================
    lv_step := 'A-4.1';
    lv_step_status := cv_status_normal;
    -- フォーマットパターン「パーティ関連」･･･ 顧客区分が「13:法人顧客」
    -- フォーマットパターン「顧客関連」    ･･･ 顧客区分が「14:売掛管理先顧客」
    IF ( ( gv_format = cv_file_format_pa AND i_cust_rel_rec.cust_class_code <> cv_cu_trust_corp )
      OR ( gv_format = cv_file_format_cu AND i_cust_rel_rec.cust_class_code <> cv_cu_ar_manage  ) )
      THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- 値チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm               -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10328               -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                     -- トークンコード1
                      ,iv_token_value1 => cv_tkv_cu_class_code             -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                     -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.cust_class_code   -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no             -- トークンコード3
                      ,iv_token_value3 => i_cust_rel_rec.line_no           -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.2 顧客コード存在チェック
    --==============================================================
    IF ( lv_step_status = cv_status_normal ) THEN
      lv_step := 'A-4.2';
      -- パラメータカーソルより取得
      OPEN get_cust_id_cur(
          i_cust_rel_rec.cust_class_code
        , i_cust_rel_rec.cust_code
      );
      FETCH get_cust_id_cur INTO lt_cust_party_id, lt_cust_account_id;
      CLOSE get_cust_id_cur;
      -- 取得できなかった場合、エラー
      IF lt_cust_party_id IS NULL THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- 顧客マスタ存在チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10347             -- メッセージコード
                      ,iv_token_name1  => cv_tkn_cust_class              -- トークンコード1
                      ,iv_token_value1 => i_cust_rel_rec.cust_class_code -- トークン値1
                      ,iv_token_name2  => cv_tkn_cust_code               -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.cust_code       -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no           -- トークンコード3
                      ,iv_token_value3 => i_cust_rel_rec.line_no         -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.3 関連先顧客区分チェック
    --==============================================================
    lv_step := 'A-4.3';
    lv_step_status := cv_status_normal;
    -- フォーマットパターン「パーティ関連」･･･ 関連先顧客区分が「10:顧客」「14:売掛管理先顧客」のいずれかであること
    -- フォーマットパターン「顧客関連」    ･･･ 関連先顧客区分が「10:顧客」であること
    IF ( ( gv_format = cv_file_format_pa AND i_cust_rel_rec.rel_cust_class_code NOT IN ( cv_cu_customer , cv_cu_ar_manage ) )
      OR ( gv_format = cv_file_format_cu AND i_cust_rel_rec.rel_cust_class_code <> cv_cu_customer ) )
      THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- 値チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10328                   -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                         -- トークンコード1
                      ,iv_token_value1 => cv_tkv_recu_class_code               -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                         -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.rel_cust_class_code   -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                 -- トークンコード3
                      ,iv_token_value3 => i_cust_rel_rec.line_no               -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.4 関連先顧客コード存在チェック
    --==============================================================
    IF ( lv_step_status = cv_status_normal ) THEN
      lv_step := 'A-4.4';
      -- パラメータカーソルより取得
      OPEN get_cust_id_cur(
          i_cust_rel_rec.rel_cust_class_code
        , i_cust_rel_rec.rel_cust_code
      );
      FETCH get_cust_id_cur INTO lt_rel_cust_party_id, lt_rel_cust_account_id;
      CLOSE get_cust_id_cur;
      -- 取得できなかった場合、エラー
      IF lt_rel_cust_party_id IS NULL THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        -- 顧客マスタ存在チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                 -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10347                 -- メッセージコード
                      ,iv_token_name1  => cv_tkn_cust_class                  -- トークンコード1
                      ,iv_token_value1 => i_cust_rel_rec.rel_cust_class_code -- トークン値1
                      ,iv_token_name2  => cv_tkn_cust_code                   -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.rel_cust_code       -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no               -- トークンコード3
                      ,iv_token_value3 => i_cust_rel_rec.line_no             -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.5 登録ステータスチェック
    --==============================================================
    -- 登録ステータスが「Y:有効化」「N:無効化」のいずれかであること
    lv_step := 'A-4.5';
    lv_step_status := cv_status_normal;
    IF ( i_cust_rel_rec.status NOT IN ( cv_active_csv , cv_inactive_csv ) ) THEN
      lv_step_status  := cv_status_error;
      lv_check_status := cv_status_error;
      -- 値チェックエラー
      gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10328                   -- メッセージコード
                    ,iv_token_name1  => cv_tkn_input                         -- トークンコード1
                    ,iv_token_value1 => cv_tkv_status                        -- トークン値1
                    ,iv_token_name2  => cv_tkn_value                         -- トークンコード2
                    ,iv_token_value2 => i_cust_rel_rec.status                -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_line_no                 -- トークンコード3
                    ,iv_token_value3 => i_cust_rel_rec.line_no               -- トークン値3
                   );
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg);
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg);
    END IF;
    --
    --==============================================================
    -- A-4.6 関連適用日チェック
    --==============================================================
    -- フォーマットパターンが「パーティ関連」の場合、
    -- 関連適用日が業務日付より未来日付ではないこと
    IF ( gv_format = cv_file_format_pa ) THEN
      lv_step := 'A-4.6';
      lv_step_status := cv_status_normal;
      lv_char_rel_date := TO_CHAR(i_cust_rel_rec.rel_apply_date , 'YYYY/MM/DD');
      -- 関連適用日が業務日付より未来日付の場合
      IF ( TRUNC( i_cust_rel_rec.rel_apply_date ) > TRUNC( gd_process_date ) ) THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        --関連適用日チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10355                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_apply_date                     -- トークンコード1
                      ,iv_token_value1 => lv_char_rel_date                      -- トークン値1
                      ,iv_token_name2  => cv_tkn_input_line_no                  -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.line_no                -- トークン値2
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.7 顧客関連分類の存在チェック
    --==============================================================
    -- フォーマットパターンが「顧客関連」の場合、
    -- 顧客関連分類が参照コードマスタ上に存在すること
    IF ( gv_format = cv_file_format_cu ) THEN
      lv_step := 'A-4.7';
      lv_step_status := cv_status_normal;
      -- Lookup表の存在チェック
      SELECT COUNT(1)
        INTO ln_chk_cnt
        FROM fnd_lookup_values_vl flv                                             -- LOOKUP表
       WHERE flv.lookup_type        = cv_lookup_relate_class                      -- 顧客関連分類
         AND flv.lookup_code        = i_cust_rel_rec.relate_class                 -- CSV.顧客関連分類
         AND flv.enabled_flag       = cv_lookup_yes                               -- 使用可能フラグ
         AND NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
         AND NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date     -- 適用終了日
      ;
      -- 取得結果判定
      IF (ln_chk_cnt = 0) THEN
        lv_step_status  := cv_status_error;
        lv_check_status := cv_status_error;
        --参照コード存在チェックエラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_10330                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- トークンコード1
                      ,iv_token_value1 => cv_tkv_relate_class                   -- トークン値1
                      ,iv_token_name2  => cv_tkn_value                          -- トークンコード2
                      ,iv_token_value2 => i_cust_rel_rec.relate_class           -- トークン値2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                      ,iv_token_value3 => i_cust_rel_rec.line_no                -- トークン値3
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END IF;
    --
    --==============================================================
    -- A-4.8 パーティ関連のチェック処理
    --==============================================================
    -- フォーマットパターンが「パーティ関連」の場合
    IF ( ( gv_format       = cv_file_format_pa ) AND 
         ( lv_check_status = cv_status_normal  ) )
      THEN
        -- ***  A-4.8.1 CSVファイル内重複チェック  *** --
        lv_step := 'A-4.8.1';
        lv_step_status := cv_status_normal;
        lv_char_rel_date := TO_CHAR(i_cust_rel_rec.rel_apply_date , 'YYYY/MM/DD');
        -- CSV内重複チェック
        OPEN party_rel_csv_repeat_check_cur;
        FETCH party_rel_csv_repeat_check_cur INTO ln_chk_cnt;
        CLOSE party_rel_csv_repeat_check_cur;
        -- 取得結果判定
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --顧客関連一括更新CSV内容重複エラー 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10348                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- トークンコード1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- トークン値1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- トークンコード2
                        ,iv_token_value2 => cv_tkv_rep_cont_pa                    -- トークン値2
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --
        -- ***  A-4.8.2 無効化データチェック  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_inactive_csv  ) )
          THEN
            lv_step := 'A-4.8.2';
            -- 関連元・関連先間の最新有効パーティ関連 取得
            OPEN party_rel_inact_check_cur;
            FETCH party_rel_inact_check_cur INTO ld_pa_chk_start_date , ld_pa_chk_end_date;
            CLOSE party_rel_inact_check_cur;
            -- 取得結果判定
            IF ( ( ld_pa_chk_start_date IS NULL ) OR
                 ( NOT( i_cust_rel_rec.rel_apply_date BETWEEN ld_pa_chk_start_date AND ld_pa_chk_end_date ) ) )
              THEN
                lv_step_status  := cv_status_error;
                lv_check_status := cv_status_error;
                --パーティ関連無効化データチェックエラー 
                gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                              ,iv_name         => cv_msg_xxcmm_10349                    -- メッセージコード
                              ,iv_token_name1  => cv_tkn_cust_code                      -- トークンコード1
                              ,iv_token_value1 => i_cust_rel_rec.cust_code              -- トークン値1
                              ,iv_token_name2  => cv_tkn_rel_cust_code                  -- トークンコード2
                              ,iv_token_value2 => i_cust_rel_rec.rel_cust_code          -- トークン値2
                              ,iv_token_name3  => cv_tkn_apply_date                     -- トークンコード3
                              ,iv_token_value3 => lv_char_rel_date                      -- トークン値3
                              ,iv_token_name4  => cv_tkn_input_line_no                  -- トークンコード4
                              ,iv_token_value4 => i_cust_rel_rec.line_no                -- トークン値4
                             );
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg);
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
            END IF;
        END IF;
        --
        -- ***  A-4.8.3 有効化データチェック  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_active_csv    ) )
          THEN
            lv_step := 'A-4.8.3';
            lv_csv_inact_search := cv_un_search;
            -- 関連先に対する最新の有効パーティ関連 取得
            OPEN party_rel_active_check_cur;
            FETCH party_rel_active_check_cur INTO lv_pa_chk_cust_code , ld_pa_chk_start_date , ld_pa_chk_end_date;
            CLOSE party_rel_active_check_cur;
            -- 取得結果判定
            IF ( lv_pa_chk_cust_code IS NULL ) THEN
              -- 有効なパーティ関連無し → ＣＳＶ検索不要でOK
              lv_csv_inact_search := cv_un_search;
            ELSE
              -- 有効なパーティ関連有り
              IF ( ( ld_pa_chk_start_date < i_cust_rel_rec.rel_apply_date ) AND
                   ( ld_pa_chk_end_date   < i_cust_rel_rec.rel_apply_date ) )
                THEN
                  -- 開始日・終了日 ＜ 関連適用日   → ＣＳＶ検索不要でOK
                  lv_csv_inact_search := cv_un_search;
              ELSIF ( (i_cust_rel_rec.rel_apply_date >  ld_pa_chk_start_date ) AND
                      (i_cust_rel_rec.rel_apply_date <= ld_pa_chk_end_date   ) )
                THEN
                  -- 開始日 ＜ 関連適用日 ≦ 終了日 → ＣＳＶ検索要
                  lv_csv_inact_search := cv_search;
              ELSE
                --  関連適用日 ≦ 開始日  → ＣＳＶ検索不要でNG
                lv_step_status  := cv_status_error;
                lv_check_status := cv_status_error;
                --パーティ関連有効化データチェック未来日エラー 
                gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_name_xxcmm              -- アプリケーション短縮名
                              ,iv_name         => cv_msg_xxcmm_10350              -- メッセージコード
                              ,iv_token_name1  => cv_tkn_cust_code                -- トークンコード1
                              ,iv_token_value1 => i_cust_rel_rec.cust_code        -- トークン値1
                              ,iv_token_name2  => cv_tkn_apply_date               -- トークンコード2
                              ,iv_token_value2 => lv_char_rel_date                -- トークン値2
                              ,iv_token_name3  => cv_tkn_input_line_no            -- トークンコード3
                              ,iv_token_value3 => i_cust_rel_rec.line_no          -- トークン値3
                              ,iv_token_name4  => cv_tkn_rel_cust_code            -- トークンコード4
                              ,iv_token_value4 => lv_pa_chk_cust_code             -- トークン値4
                             );
                -- メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg);
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
            END IF;
            --
            -- ***  A-4.8.4 ＣＳＶファイル内無効化データ検索  *** --
            IF (( lv_step_status      = cv_status_normal ) AND
                ( lv_csv_inact_search = cv_search        ) )
               THEN
                 lv_step := 'A-4.8.4';
                 --
                 SELECT COUNT(1)
                   INTO ln_chk_cnt
                   FROM xxcmm_wk_cust_relate_upload xwcru                                  -- 顧客関連一括更新ワーク
                  WHERE xwcru.request_id              = cn_request_id                      -- 要求ID
                    AND xwcru.status                  = cv_inactive_csv                    -- 登録ステータス:N
                    AND xwcru.customer_code           = lv_pa_chk_cust_code                -- 関連元顧客コード
                    AND xwcru.rel_customer_code       = i_cust_rel_rec.rel_cust_code       -- 関連先顧客コード
                    AND xwcru.relate_apply_date       < i_cust_rel_rec.rel_apply_date      -- 関連適用日
                 ;
                 -- 取得結果判定
                 IF (ln_chk_cnt = 0) THEN
                   lv_step_status  := cv_status_error;
                   lv_check_status := cv_status_error;
                   --パーティ関連有効化データチェックエラー 
                   gv_out_msg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                                 ,iv_name         => cv_msg_xxcmm_10351                    -- メッセージコード
                                 ,iv_token_name1  => cv_tkn_cust_code                      -- トークンコード1
                                 ,iv_token_value1 => i_cust_rel_rec.cust_code              -- トークン値1
                                 ,iv_token_name2  => cv_tkn_apply_date                     -- トークンコード2
                                 ,iv_token_value2 => lv_char_rel_date                      -- トークン値2
                                 ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                                 ,iv_token_value3 => i_cust_rel_rec.line_no                -- トークン値3
                                 ,iv_token_name4  => cv_tkn_rel_cust_code                  -- トークンコード4
                                 ,iv_token_value4 => lv_pa_chk_cust_code                   -- トークン値4
                                );
                   -- メッセージ出力
                   FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg);
                   --
                   FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg);
                 END IF;
            END IF;
        END IF;
    END IF;
    --
    --==============================================================
    -- A-4.9 顧客関連のチェック処理
    --==============================================================
    -- フォーマットパターン「顧客関連」の場合
    IF ( ( gv_format       = cv_file_format_cu ) AND
         ( lv_check_status = cv_status_normal  ) )
      THEN
        -- ***  A-4.9.1 CSVファイル内重複チェック  *** --
        lv_step := 'A-4.9.1';
        lv_step_status := cv_status_normal;
        -- CSV内重複チェック1
        OPEN cust_rel_csv_repeat_check1_cur;
        FETCH cust_rel_csv_repeat_check1_cur INTO ln_chk_cnt;
        CLOSE cust_rel_csv_repeat_check1_cur;
        -- 取得結果判定
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --顧客関連一括更新CSV内容重複エラー 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10348                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- トークンコード1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- トークン値1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- トークンコード2
                        ,iv_token_value2 => cv_tkv_rep_cont_cu1                   -- トークン値2
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        -- CSV内重複チェック2
        OPEN cust_rel_csv_repeat_check2_cur;
        FETCH cust_rel_csv_repeat_check2_cur INTO ln_chk_cnt;
        CLOSE cust_rel_csv_repeat_check2_cur;
        -- 取得結果判定
        IF (ln_chk_cnt > 0) THEN
          lv_step_status  := cv_status_error;
          lv_check_status := cv_status_error;
          --顧客関連一括更新CSV内容重複エラー 
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_10348                    -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- トークンコード1
                        ,iv_token_value1 => i_cust_rel_rec.line_no                -- トークン値1
                        ,iv_token_name2  => cv_tkn_rep_cont                       -- トークンコード2
                        ,iv_token_value2 => cv_tkv_rep_cont_cu2                   -- トークン値2
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --
        -- ***  A-4.9.2 無効化データチェック  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_inactive_csv  ) )
          THEN
            lv_step := 'A-4.9.2';
            -- 関連元・関連先間の有効な顧客関連 取得
            OPEN cust_rel_inact_check_cur;
            FETCH cust_rel_inact_check_cur INTO ln_chk_cnt;
            CLOSE cust_rel_inact_check_cur;
            -- 取得結果判定
            IF (ln_chk_cnt = 0) THEN
              lv_step_status  := cv_status_error;
              lv_check_status := cv_status_error;
              -- 関連分類毎にメッセージトークンを設定
              IF ( i_cust_rel_rec.relate_class = cv_rel_bill ) THEN
                 lv_rel_cls_name := cv_rel_bill_name;
              ELSE
                 lv_rel_cls_name := cv_rel_cash_name;
              END IF;
              -- 顧客関連無効化データチェックエラー
              gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                            ,iv_name         => cv_msg_xxcmm_10352                    -- メッセージコード
                            ,iv_token_name1  => cv_tkn_cust_code                      -- トークンコード1
                            ,iv_token_value1 => i_cust_rel_rec.cust_code              -- トークン値1
                            ,iv_token_name2  => cv_tkn_rel_cust_code                  -- トークンコード2
                            ,iv_token_value2 => i_cust_rel_rec.rel_cust_code          -- トークン値2
                            ,iv_token_name3  => cv_tkn_rel_cls_name                   -- トークンコード3
                            ,iv_token_value3 => lv_rel_cls_name                       -- トークン値3
                            ,iv_token_name4  => cv_tkn_input_line_no                  -- トークンコード4
                            ,iv_token_value4 => i_cust_rel_rec.line_no                -- トークン値4
                           );
              -- メッセージ出力
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg);
              --
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
        END IF;
        --
        -- ***  A-4.9.3 有効化データチェック  *** --
        IF ( ( lv_step_status        = cv_status_normal ) AND
             ( i_cust_rel_rec.status = cv_active_csv    ) )
          THEN
            lv_step := 'A-4.9.3';
            -- 現在有効な顧客関連分類を取得
            OPEN cust_rel_active_check_cur;
            FETCH cust_rel_active_check_cur BULK COLLECT INTO cust_rel_active_rec_tab;
            CLOSE cust_rel_active_check_cur;
            --
            -- 既に有効な情報がある場合のみ、ＣＳＶファイルの中から無効化データを検索
            <<csv_inact_loop>>
            FOR ln_cnt IN 1..cust_rel_active_rec_tab.COUNT LOOP
               -- ***  A-4.9.4 ＣＳＶファイル内無効化データ検索  *** --
               lv_step := 'A-4.9.4';
               --
               SELECT COUNT(1)
                 INTO ln_chk_cnt
                 FROM xxcmm_wk_cust_relate_upload xwcru                                         -- 顧客関連一括更新ワーク
                WHERE xwcru.request_id          = cn_request_id                                 -- 要求ID
                  AND xwcru.status              = cv_inactive_csv                               -- 登録ステータス:N
                  AND xwcru.customer_code       = cust_rel_active_rec_tab(ln_cnt).cust_code     -- 関連元顧客コード
                  AND xwcru.rel_customer_code   = cust_rel_active_rec_tab(ln_cnt).rel_cust_code -- 関連先顧客コード
                  AND xwcru.relate_class        = cust_rel_active_rec_tab(ln_cnt).relate_class  -- 顧客関連
               ;
               -- 取得結果判定
               IF (ln_chk_cnt = 0) THEN
                 lv_step_status  := cv_status_error;
                 lv_check_status := cv_status_error;
                 IF ( cust_rel_active_rec_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
                    lv_rel_cls_name := cv_rel_bill_name;
                 ELSE
                    lv_rel_cls_name := cv_rel_cash_name;
                 END IF;
                 -- 顧客関連有効化データチェックエラー 
                 gv_out_msg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                               ,iv_name         => cv_msg_xxcmm_10353                    -- メッセージコード
                               ,iv_token_name1  => cv_tkn_rel_cust_code                  -- トークンコード1
                               ,iv_token_value1 => i_cust_rel_rec.rel_cust_code          -- トークン値1
                               ,iv_token_name2  => cv_tkn_rel_cls_name                   -- トークンコード2
                               ,iv_token_value2 => lv_rel_cls_name                       -- トークン値2
                               ,iv_token_name3  => cv_tkn_input_line_no                  -- トークンコード3
                               ,iv_token_value3 => i_cust_rel_rec.line_no                -- トークン値3
                               ,iv_token_name4  => cv_tkn_cust_code                      -- トークンコード4
                               ,iv_token_value4 => cust_rel_active_rec_tab(ln_cnt).cust_code -- トークン値4
                              );
                 -- メッセージ出力
                 FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT
                   ,buff   => gv_out_msg);
                 --
                 FND_FILE.PUT_LINE(
                    which  => FND_FILE.LOG
                   ,buff   => gv_out_msg);
               END IF;
            END LOOP csv_inact_loop;
        END IF;
    END IF;
    --
    -- 全てのエラーチェックがOKの場合のみ、登録ステータス毎に値を退避。
    IF ( lv_check_status = cv_status_normal ) THEN
      -- 登録ステータスに応じて値を退避
      IF ( i_cust_rel_rec.status = cv_active_csv ) THEN
        -- 有効化データの退避
        gn_active_cnt := gn_active_cnt + 1;
        -- 関連元情報
        g_act_keys_tab(gn_active_cnt).cust_class_code      := i_cust_rel_rec.cust_class_code;
        g_act_keys_tab(gn_active_cnt).cust_code            := i_cust_rel_rec.cust_code;
        g_act_keys_tab(gn_active_cnt).cust_party_id        := lt_cust_party_id;
        g_act_keys_tab(gn_active_cnt).cust_account_id      := lt_cust_account_id;
        -- 関連先情報
        g_act_keys_tab(gn_active_cnt).rel_cust_class_code  := i_cust_rel_rec.rel_cust_class_code;
        g_act_keys_tab(gn_active_cnt).rel_cust_code        := i_cust_rel_rec.rel_cust_code;
        g_act_keys_tab(gn_active_cnt).rel_cust_party_id    := lt_rel_cust_party_id;
        g_act_keys_tab(gn_active_cnt).rel_cust_account_id  := lt_rel_cust_account_id;
        --
        g_act_keys_tab(gn_active_cnt).relate_class         := i_cust_rel_rec.relate_class;
        g_act_keys_tab(gn_active_cnt).rel_apply_date       := i_cust_rel_rec.rel_apply_date;
        g_act_keys_tab(gn_active_cnt).line_no              := i_cust_rel_rec.line_no;
      ELSE
        -- 無効化データの退避
        gn_inact_cnt  := gn_inact_cnt + 1;
        -- 関連元情報
        g_inact_keys_tab(gn_inact_cnt).cust_class_code     := i_cust_rel_rec.cust_class_code;
        g_inact_keys_tab(gn_inact_cnt).cust_code           := i_cust_rel_rec.cust_code;
        g_inact_keys_tab(gn_inact_cnt).cust_party_id       := lt_cust_party_id;
        g_inact_keys_tab(gn_inact_cnt).cust_account_id     := lt_cust_account_id;
        -- 関連先情報
        g_inact_keys_tab(gn_inact_cnt).rel_cust_class_code := i_cust_rel_rec.rel_cust_class_code;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_code       := i_cust_rel_rec.rel_cust_code;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_party_id   := lt_rel_cust_party_id;
        g_inact_keys_tab(gn_inact_cnt).rel_cust_account_id := lt_rel_cust_account_id;
        --
        g_inact_keys_tab(gn_inact_cnt).relate_class        := i_cust_rel_rec.relate_class;
        g_inact_keys_tab(gn_inact_cnt).rel_apply_date      := i_cust_rel_rec.rel_apply_date;
        g_inact_keys_tab(gn_inact_cnt).line_no             := i_cust_rel_rec.line_no;
      END IF;
    END IF;
    --
    ov_retcode := lv_check_status;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_cust_wrel;
--
  /**********************************************************************************
   * Procedure Name   : proc_party_rel_inact
   * Description      : パーティ関連無効化データ更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE proc_party_rel_inact(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_rel_inact'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- パーティ関連 更新用
    lt_relationship_id        hz_relationships.relationship_id%TYPE;            -- リレーションシップID
    lt_prel_obj_v_number      hz_relationships.object_version_number%TYPE;      -- オブジェクトバージョン番号
    lt_party_obj_v_number     hz_parties.object_version_number%TYPE;            -- オブジェクトバージョン番号
    -- 標準API呼出用
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                    -- 初期メッセージ
    l_relationship_rec        hz_relationship_v2pub.relationship_rec_type;      -- パーティ関連更新用レコード
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- パーティ関連情報 取得カーソル
    CURSOR party_relate_cur(
      p_cust_party_id      NUMBER ,  -- 関連元顧客 パーテイID
      p_rel_cust_party_id  NUMBER ,  -- 関連先顧客 パーティID
      p_rel_apply_date     DATE      -- 関連適用日
    )IS
      SELECT hr.relationship_id       AS relationship_id
           , hr.object_version_number AS prel_obj_v_number
           , hp.object_version_number AS party_obj_v_number
        FROM hz_relationships  hr                           -- パーティ関連
           , hz_parties  hp                                 -- パーティ
       WHERE -- 関連元顧客情報
             hr.subject_type       = cv_hr_type_org         --  サブジェクトタイプ:ORGANIZATION
         AND hr.subject_table_name = cv_hr_table_name       --  サブジェクトテーブル名:HZ_PARTIES
         AND hr.subject_id         = p_cust_party_id        --  サブジェクトID:関連元パーティID
             -- 関連先顧客情報
         AND hr.object_type        = cv_hr_type_org         --  オブジェクトタイプ:ORGANIZATION
         AND hr.object_table_name  = cv_hr_table_name       --  オブジェクトタイプ:HZ_PARTIES
         AND hr.object_id          = p_rel_cust_party_id    --  オブジェクトID:関連先パーティID
             --
         AND hr.party_id           = hp.party_id            --  パーティID
         AND hr.relationship_type  = cv_hr_rel_type_credit  --  パーティ関連タイプ:与信関連
         AND hr.relationship_code  = cv_hr_rel_code_urikake --  パーティ関連コード:売掛管理先
         AND hr.status             = cv_active_set          --  ステータス:A(有効)
         AND hr.start_date        <= p_rel_apply_date       --  開始日
         AND hr.end_date          >= p_rel_apply_date       --  終了日
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカルユーザー定義例外 ***
    v2pub_err_expt                 EXCEPTION;               -- 標準APIエラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 無効化データ全てを更新
    <<party_inact_loop>>
    FOR ln_cnt IN 1..g_inact_keys_tab.COUNT LOOP
      --==============================================================
      -- A-5.1 パーティ関連 情報取得＆ロック
      --==============================================================
      lv_step := 'A-5.1';
      BEGIN 
        -- 無効化のキーを元に取得
        OPEN party_relate_cur(
          g_inact_keys_tab(ln_cnt).cust_party_id ,
          g_inact_keys_tab(ln_cnt).rel_cust_party_id ,
          g_inact_keys_tab(ln_cnt).rel_apply_date
        );
        FETCH party_relate_cur INTO lt_relationship_id, lt_prel_obj_v_number, lt_party_obj_v_number;
        CLOSE party_relate_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_lock_table := cv_tkv_lock_party_rel || cv_msg_comma || cv_tkv_lock_party;
          RAISE global_check_lock_expt;
      END;
      --
      --==============================================================
      -- A-5.2 パーティ関連 更新用レコード取得
      --==============================================================
      lv_step := 'A-5.2';
      -- 標準API:パーティ関連取得
      hz_relationship_v2pub.get_relationship_rec(
        p_init_msg_list               =>  lv_init_msg_list         -- 1.初期メッセージリスト
       ,p_relationship_id             =>  lt_relationship_id       -- 2.リレーションシップID
       ,x_rel_rec                     =>  l_relationship_rec
       ,x_return_status               =>  lv_return_status
       ,x_msg_count                   =>  ln_msg_count
       ,x_msg_data                    =>  lv_msg_data
      );
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        lv_api_name := cv_tkv_apinm_pa_get;
        lv_api_step := cv_tkv_apist_pa_get;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      --==============================================================
      -- A-5.3 パーティ関連 更新用レコード編集＆更新
      --==============================================================
      lv_step := 'A-5.3';
      -- 値の編集
      l_relationship_rec.subject_type        := cv_hr_type_org;                     -- 'ORGANIZATION'
      l_relationship_rec.subject_table_name  := cv_hr_table_name;                   -- 'HZ_PARTIES'
      l_relationship_rec.object_type         := cv_hr_type_org;                     -- 'ORGANIZATION'
      l_relationship_rec.object_table_name   := cv_hr_table_name;                   -- 'HZ_PARTIES'
      l_relationship_rec.relationship_code   := cv_hr_rel_code_urikake;             -- '売掛管理先'
      l_relationship_rec.relationship_type   := cv_hr_rel_type_credit;              -- '与信関連'
      l_relationship_rec.status              := cv_active_set;                      -- 登録ステータス:'A'(有効)
      l_relationship_rec.end_date            := g_inact_keys_tab(ln_cnt).rel_apply_date;      -- 終了日
      l_relationship_rec.comments            := g_inact_keys_tab(ln_cnt).rel_cust_class_code || '_' || 
                                                g_inact_keys_tab(ln_cnt).rel_cust_code; -- 注釈
      --
      -- 標準API:パーティ関連更新
      hz_relationship_v2pub.update_relationship(
        p_init_msg_list               => lv_init_msg_list        -- 1.初期メッセージリスト
       ,p_relationship_rec            => l_relationship_rec      -- 2.パーティ関連更新用レコード
       ,p_object_version_number       => lt_prel_obj_v_number    -- 3.パーティ関連オブジェクトバージョン番号
       ,p_party_object_version_number => lt_party_obj_v_number   -- 4.パーティオブジェクトバージョン番号
       ,x_return_status               => lv_return_status
       ,x_msg_count                   => ln_msg_count
       ,x_msg_data                    => lv_msg_data
      );
      --
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_pa_upload;
        lv_api_step := cv_tkv_apist_pa_upload;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
    END LOOP party_inact_loop;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm      -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00008      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_ng_table         -- トークンコード1
                     ,iv_token_value1 => lv_lock_table           -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      --
    -- *** 標準API 例外ハンドラ ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm       -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10354       -- メッセージ
                    ,iv_token_name1  => cv_tkn_api_step          -- トークンコード1
                    ,iv_token_value1 => lv_api_step              -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name          -- トークンコード2
                    ,iv_token_value2 => lv_api_name              -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num           -- トークンコード3
                    ,iv_token_value3 => ln_line_no               -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg            -- トークンコード4
                    ,iv_token_value4 => SQLERRM                  -- トークン値4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_party_rel_inact;
--
  /**********************************************************************************
   * Procedure Name   : proc_party_rel_active
   * Description      : パーティ関連有効化データ登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_party_rel_active(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_rel_active'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    ln_line_no                NUMBER;
    -- 標準API呼出用
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                    -- 初期メッセージ
    l_relationship_rec        hz_relationship_v2pub.relationship_rec_type;      -- パーティ関連登録用レコード
    lt_relationship_id        hz_relationships.relationship_id%TYPE;            -- リレーションシップID
    lt_party_id               hz_parties.party_id%TYPE;
    lt_party_number           hz_parties.party_number%TYPE;
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- *** ローカルユーザー定義例外 ***
    v2pub_err_expt                 EXCEPTION;               -- 標準APIエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 有効化データ全てを更新
    <<party_active_loop>>
    FOR ln_cnt IN 1..g_act_keys_tab.COUNT LOOP
      --==============================================================
      -- A-6.1 パーティ関連 登録用レコード編集＆登録
      --==============================================================
      lv_step := 'A-6.1';
      -- 関連元情報
      l_relationship_rec.subject_id          := g_act_keys_tab(ln_cnt).cust_party_id;     -- パーティＩＤ
      l_relationship_rec.subject_type        := cv_hr_type_org;                           -- 'ORGANIZATION'
      l_relationship_rec.subject_table_name  := cv_hr_table_name;                         -- 'HZ_PARTIES'
      -- 関連先情報
      l_relationship_rec.object_id           := g_act_keys_tab(ln_cnt).rel_cust_party_id; -- パーティＩＤ
      l_relationship_rec.object_type         := cv_hr_type_org;                           -- 'ORGANIZATION'
      l_relationship_rec.object_table_name   := cv_hr_table_name;                         -- 'HZ_PARTIES'
      --
      l_relationship_rec.relationship_code   := cv_hr_rel_code_urikake;                   -- '売掛管理先'
      l_relationship_rec.relationship_type   := cv_hr_rel_type_credit;                    -- '与信関連'
      l_relationship_rec.status              := cv_active_set;                            -- 登録ステータス:'A'(有効)
      l_relationship_rec.start_date          := g_act_keys_tab(ln_cnt).rel_apply_date;    -- 開始日
      l_relationship_rec.end_date            := NULL;                                     -- 終了日
      l_relationship_rec.comments            := g_act_keys_tab(ln_cnt).rel_cust_class_code || '_' || 
                                                g_act_keys_tab(ln_cnt).rel_cust_code;     -- 注釈
      l_relationship_rec.created_by_module   := cv_pkg_name;                              -- WHOカラム.プログラムID
      --
      -- 標準API:パーティ関連登録
      hz_relationship_v2pub.create_relationship(
        p_init_msg_list               => lv_init_msg_list        -- 1.初期メッセージリスト
       ,p_relationship_rec            => l_relationship_rec      -- 2.パーティ関連更新用レコード
       ,x_relationship_id             => lt_relationship_id
       ,x_party_id                    => lt_party_id
       ,x_party_number                => lt_party_number
       ,x_return_status               => lv_return_status
       ,x_msg_count                   => ln_msg_count
       ,x_msg_data                    => lv_msg_data
      );
      --
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_pa_create;
        lv_api_step := cv_tkv_apist_pa_create;
        ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
    END LOOP party_active_loop;
--
  EXCEPTION
    -- *** 標準API 例外ハンドラ ***
    WHEN v2pub_err_expt THEN                   --*** <例外コメント> ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10354            -- メッセージ
                    ,iv_token_name1  => cv_tkn_api_step               -- トークンコード1
                    ,iv_token_value1 => lv_api_step                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_name                   -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => ln_line_no                    -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- トークンコード4
                    ,iv_token_value4 => SQLERRM                       -- トークン値4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_party_rel_active;
--
  /**********************************************************************************
   * Procedure Name   : proc_cust_rel_inact
   * Description      : 顧客関連無効化データ更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE proc_cust_rel_inact(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_rel_inact'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- 顧客関連 更新用
    l_cust_rel_rowid          ROWID;                                                -- ROWID
    lt_cust_rel_obj_v_number  hz_cust_acct_relate_all.object_version_number%TYPE;   -- オブジェクトバージョン番号
    -- 顧客使用目的 更新用
    lt_ship_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;               -- 顧客事業所(関連先) 出荷先.使用目的ID
    lt_ship_suse_obj_v_number hz_cust_site_uses_all.object_version_number%TYPE;     -- 顧客事業所(関連先) 出荷先.オブジェクトバージョン番号
    lt_bill_site_use_id       hz_cust_site_uses_all.site_use_id%TYPE;               -- 顧客事業所(関連先) 請求先.使用目的ID
    -- 標準API呼出用
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                        -- 初期メッセージ
    l_cust_acct_relate_rec    hz_cust_account_v2pub.cust_acct_relate_rec_type;      -- 顧客関連更新用レコード
    l_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;    -- 顧客使用目的取得用レコード
    l_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;  -- 顧客プロファイル取得用レコード
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --
    -- 顧客関連情報 取得カーソル
    CURSOR customer_relate_cur(
      p_cust_account_id       NUMBER ,    -- 関連元顧客 顧客ID
      p_rel_cust_account_id   NUMBER ,    -- 関連先顧客 顧客ID
      p_relate_class          VARCHAR2    -- 関連分類
    )IS
      SELECT hcarel.rowid                    AS row_id                  -- ROWID
           , hcarel.object_version_number    AS object_version_number   -- オブジェクトバージョンNo
        FROM hz_cust_acct_relate_all         hcarel                     -- 顧客関連
       WHERE hcarel.org_id                  = gv_org_id                 -- 組織ID
         AND hcarel.attribute1              = p_relate_class            -- 関連分類
         AND hcarel.status                  = cv_active_set             -- ステータス:A(有効)
         AND hcarel.related_cust_account_id = p_rel_cust_account_id     -- 関連先顧客ID
         AND hcarel.cust_account_id         = p_cust_account_id         -- 顧客ID
      FOR UPDATE NOWAIT
      ;
    --
    -- *** 請求先出荷先事業所情報 取得カーソル *** --
    CURSOR get_inact_site_uses_cur(
      p_rel_cust_account_id   NUMBER      -- 関連先顧客 顧客ID
    )IS
      SELECT hcsua_rel_ship.site_use_id           AS ship_site_use_id             -- 顧客事業所(関連先) 出荷先.使用目的ＩＤ
           , hcsua_rel_ship.object_version_number AS ship_obj_ver_number          -- 顧客事業所(関連先) 出荷先.オブジェクトバージョンNo
           , hcsua_rel_bill.site_use_id           AS bill_site_use_id             -- 顧客事業所(関連先) 請求先.使用目的ＩＤ
        FROM hz_cust_acct_sites_all          hcasa_rel_ship                       -- 関連先 出荷先:顧客サイト
           , hz_cust_site_uses_all           hcsua_rel_ship                       -- 関連先 出荷先:顧客事業所
           , hz_cust_acct_sites_all          hcasa_rel_bill                       -- 関連先 請求先:顧客サイト
           , hz_cust_site_uses_all           hcsua_rel_bill                       -- 関連先 請求先:顧客事業所
       WHERE -- 出荷先取得
             hcasa_rel_ship.cust_account_id    = p_rel_cust_account_id            -- 顧客アカウントＩＤ
         AND hcasa_rel_ship.org_id             = gv_org_id                        -- 組織ＩＤ
         AND hcasa_rel_ship.cust_acct_site_id  = hcsua_rel_ship.cust_acct_site_id -- 顧客サイトＩＤ
         AND hcsua_rel_ship.site_use_code      = cv_site_use_ship_to              -- 使用目的:'出荷先'
             -- 請求先取得
         AND hcasa_rel_bill.cust_account_id    = p_rel_cust_account_id            -- 顧客アカウントＩＤ
         AND hcasa_rel_bill.org_id             = gv_org_id                        -- 組織ＩＤ
         AND hcasa_rel_bill.cust_acct_site_id  = hcsua_rel_bill.cust_acct_site_id -- 顧客サイトＩＤ
         AND hcsua_rel_bill.site_use_code      = cv_site_use_bill_to              -- 使用目的:'請求先'
             --
         AND hcasa_rel_ship.cust_account_id    = hcasa_rel_bill.cust_account_id
         AND ROWNUM                            = 1
      FOR UPDATE NOWAIT
      ;
    -- *** ローカルユーザー定義例外 ***
    v2pub_err_expt                 EXCEPTION;               -- 標準APIエラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 無効化データ全てを更新
    <<custrel_inact_loop>>
    FOR ln_cnt IN 1..g_inact_keys_tab.COUNT LOOP
      --==============================================================
      -- A-7.1 顧客関連 情報取得＆ロック
      --==============================================================
      lv_step := 'A-7.1';
      -- 無効化のキーを元に取得
      BEGIN
        OPEN customer_relate_cur(
          g_inact_keys_tab(ln_cnt).cust_account_id ,
          g_inact_keys_tab(ln_cnt).rel_cust_account_id , 
          g_inact_keys_tab(ln_cnt).relate_class
        );
        FETCH customer_relate_cur INTO l_cust_rel_rowid, lt_cust_rel_obj_v_number;
        CLOSE customer_relate_cur;
      EXCEPTION
        WHEN OTHERS THEN
          lv_lock_table := cv_tkv_lock_cust_rel;
          RAISE global_check_lock_expt;
      END;
      --
      --==============================================================
      -- A-7.2 顧客関連 更新用レコード取得
      --==============================================================
      lv_step := 'A-7.2';
      -- 標準API:顧客関連取得
      hz_cust_account_v2pub.get_cust_acct_relate_rec(
        p_init_msg_list            =>  lv_init_msg_list                             -- 1.初期メッセージリスト
       ,p_cust_account_id          =>  g_inact_keys_tab(ln_cnt).cust_account_id     -- 2.顧客ID
       ,p_related_cust_account_id  =>  g_inact_keys_tab(ln_cnt).rel_cust_account_id -- 3.関連顧客ID
       ,p_rowid                    =>  l_cust_rel_rowid                             -- 4.ROWID
       ,x_cust_acct_relate_rec     =>  l_cust_acct_relate_rec
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        lv_api_name := cv_tkv_apinm_cu_get;
        lv_api_step := cv_tkv_apist_cu_get;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      --==============================================================
      -- A-7.3 顧客関連 更新用レコード編集＆更新
      --==============================================================
      lv_step := 'A-7.3';
      l_cust_acct_relate_rec.relationship_type         := cv_relationship_type_all;              -- 関連顧客タイプ
      l_cust_acct_relate_rec.attribute1                := g_inact_keys_tab(ln_cnt).relate_class; -- DFF1(関連分類)
      l_cust_acct_relate_rec.customer_reciprocal_flag  := cv_acc_no;                             -- 相互関連有効:'N'(無効)
      l_cust_acct_relate_rec.status                    := cv_inactive_set;                       -- ステータス:'I'(無効)
      l_cust_acct_relate_rec.bill_to_flag              := cv_acc_yes;                            -- 使用目的(請求先):'Y'(有効)
      l_cust_acct_relate_rec.ship_to_flag              := cv_acc_yes;                            -- 使用目的(出荷先):'Y'(有効)
      --
      -- 標準API:顧客関連更新
      hz_cust_account_v2pub.update_cust_acct_relate(
        p_init_msg_list            =>  lv_init_msg_list            -- 1.初期メッセージリスト
       ,p_cust_acct_relate_rec     =>  l_cust_acct_relate_rec      -- 2.顧客関連更新用レコード
       ,p_object_version_number    =>  lt_cust_rel_obj_v_number    -- 3.オブジェクトバージョン番号
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_cu_upload;
        lv_api_step := cv_tkv_apist_cu_upload;
        ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      -- 関連分類が「請求」の場合、請求先事業所を更新
      IF ( g_inact_keys_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
         --==============================================================
         -- A-7.4.1 出荷先事業所 情報取得＆ロック
         --==============================================================
         lv_step := 'A-7.4.1';
         -- 無効化のキーを元に取得
         BEGIN
           OPEN get_inact_site_uses_cur(
             g_inact_keys_tab(ln_cnt).rel_cust_account_id
           );
           FETCH get_inact_site_uses_cur INTO lt_ship_site_use_id , lt_ship_suse_obj_v_number , lt_bill_site_use_id;
           CLOSE get_inact_site_uses_cur;
         EXCEPTION
           WHEN OTHERS THEN
             lv_lock_table := cv_tkv_lock_cust_rel || cv_msg_comma || cv_tkv_lock_cust_site || cv_msg_comma || cv_tkv_lock_cust_uses;
             RAISE global_check_lock_expt;
         END;
         --
         --==============================================================
         -- A-7.4.2 出荷先事業所 更新用レコード取得
         --==============================================================
         lv_step := 'A-7.4.2';
         -- 標準API:顧客使用目的 取得
         hz_cust_account_site_v2pub.get_cust_site_use_rec(
           p_init_msg_list            =>  lv_init_msg_list          -- 1.初期メッセージリスト
          ,p_site_use_id              =>  lt_ship_site_use_id       -- 2.関連先_使用目的ＩＤ
          ,x_cust_site_use_rec        =>  l_cust_site_use_rec
          ,x_customer_profile_rec     =>  l_customer_profile_rec
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --ステータス確認
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_get;
           lv_api_step := cv_tkv_apist_suse_get;
           ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
         --
         --==============================================================
         -- A-7.4.3 出荷先事業所 更新用レコード編集＆更新
         --==============================================================
         lv_step := 'A-7.4.3';
         l_cust_site_use_rec.bill_to_site_use_id := lt_bill_site_use_id;
         --
         -- 標準API:顧客使用目的 更新
         hz_cust_account_site_v2pub.update_cust_site_use(
           p_init_msg_list            =>  lv_init_msg_list            -- 1.初期メッセージリスト
          ,p_cust_site_use_rec        =>  l_cust_site_use_rec         -- 2.顧客使用目的（出荷先）更新用レコード
          ,p_object_version_number    =>  lt_ship_suse_obj_v_number   -- 3.関連先_オブジェクトバージョンNo
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --ステータス確認
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_upld;
           lv_api_step := cv_tkv_apist_suse_upld;
           ln_line_no  := g_inact_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
      END IF;
    END LOOP custrel_inact_loop;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00008          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_ng_table             -- トークンコード1
                     ,iv_token_value1 => lv_lock_table               -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --
    -- *** 標準API 例外ハンドラ ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10354            -- メッセージ
                    ,iv_token_name1  => cv_tkn_api_step               -- トークンコード1
                    ,iv_token_value1 => lv_api_step                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_name                   -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => ln_line_no                    -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- トークンコード4
                    ,iv_token_value4 => SQLERRM                       -- トークン値4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_cust_rel_inact;
--
  /**********************************************************************************
   * Procedure Name   : proc_cust_rel_active
   * Description      : 顧客関連有効化データ登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE proc_cust_rel_active(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_rel_active'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);
    lv_api_name               VARCHAR2(60);
    lv_api_step               VARCHAR2(30);
    lv_lock_table             VARCHAR2(60);
    ln_line_no                NUMBER;
    -- 顧客使用目的 更新用
    lt_site_use_id            hz_cust_site_uses_all.site_use_id%TYPE;               -- 顧客事業所(関連元).使用目的ID
    lt_suse_obj_v_number      hz_cust_site_uses_all.object_version_number%TYPE;     -- 顧客事業所(関連元).オブジェクトバージョン番号
    lt_rel_site_use_id        hz_cust_site_uses_all.site_use_id%TYPE;               -- 顧客事業所(関連先).使用目的ID
    lt_rel_suse_obj_v_number  hz_cust_site_uses_all.object_version_number%TYPE;     -- 顧客事業所(関連先).オブジェクトバージョン番号
    -- 標準API呼出用
    lv_init_msg_list          VARCHAR2(1) := FND_API.G_TRUE;                        -- 初期メッセージ
    l_cust_acct_relate_rec    hz_cust_account_v2pub.cust_acct_relate_rec_type;      -- 顧客関連登録用レコード
    l_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;    -- 顧客使用目的取得用レコード
    l_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;  -- 顧客プロファイル取得用レコード
    lv_return_status          VARCHAR2(200);
    ln_msg_count              NUMBER;
    lv_msg_data               VARCHAR2(2000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 請求先出荷先事業所情報 取得
    CURSOR get_act_site_uses_cur(
      p_cust_account_id       NUMBER ,    -- 関連元顧客 顧客ID
      p_rel_cust_account_id   NUMBER      -- 関連先顧客 顧客ID
    )IS
      SELECT hcsua.site_use_id               AS site_use_id               -- 顧客事業所(関連元).使用目的ＩＤ
           , hcsua.object_version_number     AS obj_ver_number            -- 顧客事業所(関連元).オブジェクトバージョンNo
           , hcsua_rel.site_use_id           AS rel_site_use_id           -- 顧客事業所(関連先).使用目的ＩＤ
           , hcsua_rel.object_version_number AS rel_obj_ver_number        -- 顧客事業所(関連先).オブジェクトバージョンNo
        FROM hz_cust_acct_relate_all         hcara                        -- 顧客関連
           , hz_cust_acct_sites_all          hcasa                        -- 関連元 顧客サイト
           , hz_cust_acct_sites_all          hcasa_rel                    -- 関連先 顧客サイト
           , hz_cust_site_uses_all           hcsua                        -- 関連元 顧客事業所
           , hz_cust_site_uses_all           hcsua_rel                    -- 関連先 顧客事業所
       WHERE -- 関連元情報
             hcara.cust_account_id         = p_cust_account_id            -- 顧客アカウントＩＤ
         AND hcara.cust_account_id         = hcasa.cust_account_id        -- 顧客アカウントＩＤ
         AND hcasa.org_id                  = gv_org_id                    -- 組織ＩＤ
         AND hcasa.cust_acct_site_id       = hcsua.cust_acct_site_id      -- 顧客サイトＩＤ
         AND hcsua.site_use_code           = cv_site_use_bill_to          -- 使用目的:'請求先'
            -- 関連先情報
         AND hcara.related_cust_account_id = p_rel_cust_account_id        -- 顧客関連_アカウントＩＤ
         AND hcara.related_cust_account_id = hcasa_rel.cust_account_id    -- 顧客アカウントＩＤ
         AND hcasa_rel.org_id              = gv_org_id                    -- 組織ＩＤ
         AND hcasa_rel.cust_acct_site_id   = hcsua_rel.cust_acct_site_id  -- 顧客サイトＩＤ
         AND hcsua_rel.site_use_code       = cv_site_use_ship_to          -- 使用目的:'出荷先'
         AND ROWNUM                        = 1
      FOR UPDATE NOWAIT
      ;
    -- *** ローカルユーザー定義例外 ***
    v2pub_err_expt                 EXCEPTION;               -- 標準APIエラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 有効化データ全てを更新
    <<custrel_active_loop>>
    FOR ln_cnt IN 1..g_act_keys_tab.COUNT LOOP
      --==============================================================
      -- A-8.1 顧客関連 登録用レコード編集＆登録
      --==============================================================
      lv_step := 'A-8.1';
      l_cust_acct_relate_rec.cust_account_id           := g_act_keys_tab(ln_cnt).cust_account_id;     -- 顧客アカウントID
      l_cust_acct_relate_rec.related_cust_account_id   := g_act_keys_tab(ln_cnt).rel_cust_account_id; -- 関連顧客アカウントID
      l_cust_acct_relate_rec.relationship_type         := cv_relationship_type_all;                   -- 関連顧客タイプ
      l_cust_acct_relate_rec.attribute1                := g_act_keys_tab(ln_cnt).relate_class;        -- DFF1(関連分類)
      l_cust_acct_relate_rec.customer_reciprocal_flag  := cv_acc_no;                                  -- 相互関連有効:'N'(無効)
      l_cust_acct_relate_rec.status                    := cv_active_set;                              -- ステータス:'A'(有効)
      l_cust_acct_relate_rec.bill_to_flag              := cv_acc_yes;                                 -- 使用目的(請求先):'Y'(有効)
      l_cust_acct_relate_rec.ship_to_flag              := cv_acc_yes;                                 -- 使用目的(出荷先):'Y'(有効)
      l_cust_acct_relate_rec.created_by_module         := cv_pkg_name;                                -- WHOカラム.プログラムID
      --
      -- 標準API:顧客関連登録
      hz_cust_account_v2pub.create_cust_acct_relate(
        p_init_msg_list            =>  lv_init_msg_list             -- 1.初期メッセージリスト
       ,p_cust_acct_relate_rec     =>  l_cust_acct_relate_rec       -- 2.顧客関連登録用レコード
       ,x_return_status            =>  lv_return_status
       ,x_msg_count                =>  ln_msg_count
       ,x_msg_data                 =>  lv_msg_data
      );
      --ステータス確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
        lv_api_name := cv_tkv_apinm_cu_create;
        lv_api_step := cv_tkv_apist_cu_create;
        ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
        RAISE v2pub_err_expt;
      END IF;
      --
      -- 関連分類が「請求」の場合、請求先事業所を更新
      IF ( g_act_keys_tab(ln_cnt).relate_class = cv_rel_bill ) THEN
         --==============================================================
         -- A-8.2.1 出荷先事業所 情報取得＆ロック
         --==============================================================
         lv_step := 'A-8.2.1';
         -- 有効化のキーを元に取得
         BEGIN
           OPEN get_act_site_uses_cur(
             g_act_keys_tab(ln_cnt).cust_account_id ,
             g_act_keys_tab(ln_cnt).rel_cust_account_id
           );
           FETCH get_act_site_uses_cur INTO lt_site_use_id , lt_suse_obj_v_number , lt_rel_site_use_id , lt_rel_suse_obj_v_number;
           CLOSE get_act_site_uses_cur;
         EXCEPTION
           WHEN OTHERS THEN
             lv_lock_table := cv_tkv_lock_cust_rel || cv_msg_comma || cv_tkv_lock_cust_site || cv_msg_comma || cv_tkv_lock_cust_uses;
             RAISE global_check_lock_expt;
         END;
         --
         --==============================================================
         -- A-8.2.2 出荷先事業所 更新用レコード取得
         --==============================================================
         lv_step := 'A-8.2.2';
         -- 標準API:顧客使用目的 取得
         hz_cust_account_site_v2pub.get_cust_site_use_rec(
           p_init_msg_list            =>  lv_init_msg_list          -- 1.初期メッセージリスト
          ,p_site_use_id              =>  lt_rel_site_use_id        -- 2.関連先_使用目的ＩＤ
          ,x_cust_site_use_rec        =>  l_cust_site_use_rec
          ,x_customer_profile_rec     =>  l_customer_profile_rec
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --ステータス確認
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_get;
           lv_api_step := cv_tkv_apist_suse_get;
           ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
         --
         --==============================================================
         -- A-8.2.3 出荷先事業所 更新用レコード編集＆更新
         --==============================================================
         lv_step := 'A-8.2.3';
         l_cust_site_use_rec.bill_to_site_use_id := lt_site_use_id;
         --
         -- 標準API:顧客使用目的 更新
         hz_cust_account_site_v2pub.update_cust_site_use(
           p_init_msg_list            =>  lv_init_msg_list            -- 1.初期メッセージリスト
          ,p_cust_site_use_rec        =>  l_cust_site_use_rec         -- 2.顧客使用目的（出荷先）更新用レコード
          ,p_object_version_number    =>  lt_rel_suse_obj_v_number    -- 3.関連先_オブジェクトバージョンNo
          ,x_return_status            =>  lv_return_status
          ,x_msg_count                =>  ln_msg_count
          ,x_msg_data                 =>  lv_msg_data
         );
         --ステータス確認
         IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN 
           lv_api_name := cv_tkv_apinm_suse_upld;
           lv_api_step := cv_tkv_apist_suse_upld;
           ln_line_no  := g_act_keys_tab(ln_cnt).line_no;
           RAISE v2pub_err_expt;
         END IF;
      END IF;
    END LOOP custrel_active_loop;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00008          -- メッセージコード
                     ,iv_token_name1  => cv_tkn_ng_table             -- トークンコード1
                     ,iv_token_value1 => lv_lock_table               -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      --
    -- *** 標準API 例外ハンドラ ***
    WHEN v2pub_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_10354            -- メッセージ
                    ,iv_token_name1  => cv_tkn_api_step               -- トークンコード1
                    ,iv_token_value1 => lv_api_step                   -- トークン値1
                    ,iv_token_name2  => cv_tkn_api_name               -- トークンコード2
                    ,iv_token_value2 => lv_api_name                   -- トークン値2
                    ,iv_token_name3  => cv_tkn_seq_num                -- トークンコード3
                    ,iv_token_value3 => ln_line_no                    -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- トークンコード4
                    ,iv_token_value4 => SQLERRM                       -- トークン値4
                   );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_cust_rel_active;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 顧客関連一括更新用ワークデータ取得(A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);                         -- ステップ
    lv_check_status           VARCHAR2(1);                          -- ステータス
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_check_status := cv_status_normal;
    --
    --==============================================================
    -- LOOP B:顧客関連レコードLOOP START
    --==============================================================
    <<main_loop>>
    FOR get_wk_cust_rel_rec IN get_wk_cust_rel_cur LOOP
      --==============================================================
      -- A-4  データ妥当性チェック
      --==============================================================
      lv_step := 'A-4';
      validate_cust_wrel(
        i_cust_rel_rec     => get_wk_cust_rel_rec      -- 顧客一括登録ワーク情報
       ,ov_errbuf          => lv_errbuf                -- エラー・メッセージ
       ,ov_retcode         => lv_retcode               -- リターン・コード
       ,ov_errmsg          => lv_errmsg                -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 正常件数加算
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- データ妥当性チェックエラーの場合、エラーステータス退避
        lv_check_status := cv_status_error;
        -- エラー件数加算
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --
    END LOOP main_loop;
    --==============================================================
    -- LOOP B:顧客関連レコードLOOP END
    --==============================================================
    -- 妥当性、登録エラーの場合、エラーをセット
    IF ( lv_check_status = cv_status_error ) THEN
       ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードI/Fテーブル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカル ユーザー定義型 ***
    TYPE l_check_data_ttype  IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_step_status            VARCHAR2(1);                            -- STEPチェック
    ln_line_cnt               NUMBER;                                 -- 行カウンタ
    ln_column_cnt             NUMBER;                                 -- 項目数カウンタ
    ln_ins_cnt                NUMBER;                                 -- 登録件数カウンタ
    ln_item_num               NUMBER;                                 -- 項目数
    lv_tkn_value              VARCHAR2(100);                          -- トークン値
--
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- IFテーブル取得用
    l_wk_item_tab             l_check_data_ttype;                     -- テーブル型変数を宣言(項目分割)
    -- *** ローカルユーザー定義例外 ***
    get_if_data_expt               EXCEPTION;                         -- データ項目数エラー
    wk_cust_rel_ins_expt           EXCEPTION;                         -- データ登録エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --初期化
    ln_ins_cnt := 0;
    --
    --==============================================================
    -- A-2.1 ファイルアップロードIFテーブル取得
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id                 -- ファイルID
     ,ov_file_data => l_if_data_tab              -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                 -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- LOOP A:レコードLOOP START ※1行目はヘッダ情報の為、2行目以降を取得
    --==============================================================
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
      ln_ins_cnt := ln_ins_cnt + 1;
      --==============================================================
      -- A-2.2 項目数のチェック
      --==============================================================
      lv_step := 'A-2.2';
      -- データ項目数を格納
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt) )
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        lv_tkn_value := TO_CHAR(ln_item_num);
        RAISE get_if_data_expt;
      END IF;
      --==============================================================
      -- A-2.3  項目の分割＆チェック
      --==============================================================
      lv_step := 'A-2.3';
      lv_step_status := cv_status_normal;
      <<get_column_loop>>
      FOR ln_column_cnt IN 1..gn_item_num LOOP
        -- 変数に項目の値を格納
        l_wk_item_tab(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(        -- デリミタ文字変換共通関数
                                          iv_char     => l_if_data_tab(ln_line_cnt)   -- 分割元文字列
                                         ,iv_delim    => cv_msg_comma                 -- デリミタ
                                         ,in_part_num => ln_column_cnt                -- 取得対象の項目Index
                                        );
        -- 項目のチェック
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_cust_rel_def_tab(ln_column_cnt).item_name         -- 項目名称
         ,iv_item_value   => l_wk_item_tab(ln_column_cnt)                        -- 項目の値
         ,in_item_len     => g_cust_rel_def_tab(ln_column_cnt).int_length        -- 項目の長さ(整数部分)
         ,in_item_decimal => g_cust_rel_def_tab(ln_column_cnt).dec_length        -- 項目の長さ(小数点以下)
         ,iv_item_nullflg => g_cust_rel_def_tab(ln_column_cnt).item_essential    -- 必須フラグ
         ,iv_item_attr    => g_cust_rel_def_tab(ln_column_cnt).item_attribute    -- 項目の属性
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- 項目チェック結果が正常以外の場合
        IF ( lv_retcode <> cv_status_normal ) THEN 
          lv_step_status := cv_status_error;
          -- 値チェックエラー
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_10338          -- メッセージ
                      ,iv_token_name1   =>  cv_tkn_input_line_no        -- トークンコード1
                      ,iv_token_value1  =>  TO_CHAR( ln_ins_cnt )       -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_errmsg               -- トークンコード2
                      ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- トークン値2
                       );
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
      END LOOP get_column_loop;
      -- 戻り値更新
      IF ( lv_step_status = cv_status_error ) THEN
         ov_retcode := cv_status_error;
      END IF;
      --==============================================================
      -- A-2.4   顧客関連一括更新用ワークテーブルへ登録
      --==============================================================
      IF ( lv_step_status = cv_status_normal ) THEN 
        lv_step := 'A-2.4';
        BEGIN
          -- フォーマットパターン「パーティ関連」の場合
          IF ( gv_format = cv_file_format_pa ) THEN
              INSERT INTO xxcmm_wk_cust_relate_upload(
                 file_id                                -- ファイルID
                ,line_no                                -- 行番号
                ,customer_class_code                    -- 顧客区分
                ,customer_code                          -- 顧客コード
                ,rel_customer_class_code                -- 関連先顧客区分
                ,rel_customer_code                      -- 関連先顧客コード
                ,relate_class                           -- 顧客関連分類
                ,status                                 -- 登録ステータス
                ,relate_apply_date                      -- 関連適用日
                ,created_by                             -- WHO:作成者
                ,creation_date                          -- WHO:作成日
                ,last_updated_by                        -- WHO:最終更新者
                ,last_update_date                       -- WHO:最終更新日
                ,last_update_login                      -- WHO:最終更新ログイン
                ,request_id                             -- WHO:要求ID
                ,program_application_id                 -- WHO:コンカレント・プログラム・アプリケーションID
                ,program_id                             -- WHO:コンカレント・プログラムID
                ,program_update_date                    -- WHO:プログラム更新日
              ) VALUES (
                gn_file_id                              -- ファイルID
               ,ln_ins_cnt                              -- ファイルSEQ
               ,l_wk_item_tab(1)                        -- 顧客区分
               ,l_wk_item_tab(2)                        -- 顧客コード
               ,l_wk_item_tab(3)                        -- 関連先顧客区分
               ,l_wk_item_tab(4)                        -- 関連先顧客コード
               ,NULL                                    -- 顧客関連分類
               ,l_wk_item_tab(5)                        -- 登録ステータス
               ,TO_DATE(l_wk_item_tab(6),'YYYY/MM/DD')  -- 関連適用日
               ,cn_created_by                           -- WHO:作成者
               ,cd_creation_date                        -- WHO:作成日
               ,cn_last_updated_by                      -- WHO:最終更新者
               ,cd_last_update_date                     -- WHO:最終更新日
               ,cn_last_update_login                    -- WHO:最終更新ログイン
               ,cn_request_id                           -- WHO:要求ID
               ,cn_program_application_id               -- WHO:コンカレント・プログラム・アプリケーションID
               ,cn_program_id                           -- WHO:コンカレント・プログラムID
               ,cd_program_update_date                  -- WHO:プログラムによる更新日
              );
          END IF;
          -- フォーマットパターン「顧客関連」の場合
          IF ( gv_format = cv_file_format_cu ) THEN
              INSERT INTO xxcmm_wk_cust_relate_upload(
                 file_id                                -- ファイルID
                ,line_no                                -- 行番号
                ,customer_class_code                    -- 顧客区分
                ,customer_code                          -- 顧客コード
                ,rel_customer_class_code                -- 関連先顧客区分
                ,rel_customer_code                      -- 関連先顧客コード
                ,relate_class                           -- 顧客関連分類
                ,status                                 -- 登録ステータス
                ,relate_apply_date                      -- 関連適用日
                ,created_by                             -- WHO:作成者
                ,creation_date                          -- WHO:作成日
                ,last_updated_by                        -- WHO:最終更新者
                ,last_update_date                       -- WHO:最終更新日
                ,last_update_login                      -- WHO:最終更新ログイン
                ,request_id                             -- WHO:要求ID
                ,program_application_id                 -- WHO:コンカレント・プログラム・アプリケーションID
                ,program_id                             -- WHO:コンカレント・プログラムID
                ,program_update_date                    -- WHO:プログラム更新日
              ) VALUES (
                gn_file_id                              -- ファイルID
               ,ln_ins_cnt                              -- ファイルSEQ
               ,l_wk_item_tab(1)                        -- 顧客区分
               ,l_wk_item_tab(2)                        -- 顧客コード
               ,l_wk_item_tab(3)                        -- 関連先顧客区分
               ,l_wk_item_tab(4)                        -- 関連先顧客コード
               ,l_wk_item_tab(5)                        -- 顧客関連分類
               ,l_wk_item_tab(6)                        -- 登録ステータス
               ,NULL                                    -- 関連適用日
               ,cn_created_by                           -- WHO:作成者
               ,cd_creation_date                        -- WHO:作成日
               ,cn_last_updated_by                      -- WHO:最終更新者
               ,cd_last_update_date                     -- WHO:最終更新日
               ,cn_last_update_login                    -- WHO:最終更新ログイン
               ,cn_request_id                           -- WHO:要求ID
               ,cn_program_application_id               -- WHO:コンカレント・プログラム・アプリケーションID
               ,cn_program_id                           -- WHO:コンカレント・プログラムID
               ,cd_program_update_date                  -- WHO:プログラムによる更新日
              );
          END IF;
        EXCEPTION
          -- *** データ登録例外ハンドラ ***
          WHEN OTHERS THEN
            lv_tkn_value := TO_CHAR( ln_ins_cnt );
            RAISE wk_cust_rel_ins_expt;
        END;
      END IF;
    END LOOP ins_wk_loop;
    --
    --==============================================================
    -- LOOP A:レコードLOOP END
    --==============================================================
    -- 処理対象件数を格納(ヘッダ件数を除く)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
--
  EXCEPTION
    -- *** データ項目数エラー例外ハンドラ ***
    WHEN get_if_data_expt THEN                   --*** <例外コメント> ***
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00028            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_tkv_table_xwk_cust         -- トークン値1
                    ,iv_token_name2  => cv_tkn_count                  -- トークンコード2
                    ,iv_token_value2 => lv_tkn_value                  -- トークン値2
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ登録エラーハンドラ ****
    WHEN wk_cust_rel_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm           -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_10335           -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                     ,iv_token_value1 => cv_tkv_table_xwk_cust        -- トークン値1
                     ,iv_token_name2  => cv_tkn_input_line_no         -- トークンコード2
                     ,iv_token_value2 => lv_tkn_value                 -- トークン値2
                     ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード4
                     ,iv_token_value3 => SQLERRM                      -- トークン値4
                    );
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理(A-9)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_check_status           VARCHAR2(1);                            -- チェックステータス
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- チェックステータスの初期化
    lv_check_status := cv_status_normal;
    --
    --==============================================================
    -- A-9.1 顧客関連一括更新データ削除
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_cust_relate_upload xwcru
       WHERE xwcru.request_id = cn_request_id    --要求ID
      ;
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- データ削除エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00012          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- トークンコード1
                      ,iv_token_value1 => cv_tkv_table_xwk_cust       -- トークン値1
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
    --==============================================================
    -- A-9.2 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      lv_step := 'A-9.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- データ削除エラー
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00012          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- トークンコード1
                      ,iv_token_value1 => cv_tkv_table_file_if        -- トークン値1
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2      -- 1.ファイルID
   ,iv_format     IN  VARCHAR2      -- 2.フォーマットパターン
   ,ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                           -- ステップ
    --
    -- *** ローカルユーザー定義例外 ***
    sub_proc_expt             EXCEPTION;                              -- サブプログラムエラー
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
    gn_inact_cnt  := 0;
    gn_active_cnt := 0;
--
    --==============================================================
    -- A-1.  初期処理
    --==============================================================
    lv_step := 'A-1';
    init(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマットパターン
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 異常件数設定
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  ファイルアップロードIFデータ取得
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_dataをコール
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 異常件数設定
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-3  顧客関連一括更新用ワークデータ取得
    --  A-4  顧客関連一括更新用ワークデータ妥当性チェック
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 異常件数の設定は無し(A-4の中で異常件数のカウントがされる為)
      RAISE sub_proc_expt;
    END IF;
--    
    -- フォーマットパターンがパーティ関連の場合
    IF ( gv_format = cv_file_format_pa ) THEN
      --==============================================================
      -- A-5  パーティ関連無効化データ更新処理
      --==============================================================
      lv_step := 'A-5'; 
      proc_party_rel_inact(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 異常件数設定
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
      --==============================================================
      -- A-6  パーティ関連有効化データ登録処理
      --==============================================================
      lv_step := 'A-6'; 
      proc_party_rel_active(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 異常件数設定
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
    END IF;
--
    -- フォーマットパターンが顧客関連の場合
    IF ( gv_format = cv_file_format_cu ) THEN
      --==============================================================
      -- A-7  顧客関連無効化データ更新処理
      --==============================================================
      lv_step := 'A-7'; 
      proc_cust_rel_inact(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 異常件数設定
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
      --==============================================================
      -- A-8  顧客関連有効化データ登録処理
      --==============================================================
      lv_step := 'A-8'; 
      proc_cust_rel_active(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 異常件数設定
        gn_error_cnt := 1;
        RAISE sub_proc_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- A-7  終了処理
    --==============================================================
    lv_step := 'A-9';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 異常件数設定
      gn_error_cnt := 1;
      RAISE sub_proc_expt;
    END IF;
--
  EXCEPTION
    -- *** サブプログラムエラー ****
    WHEN sub_proc_expt THEN
      gn_normal_cnt := 0;           -- エラー発生時は正常件数=0件で返します。
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf                  OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode                 OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_file_id              IN  VARCHAR2      --   ファイルID
   ,iv_format               IN  VARCHAR2      --   フォーマットパターン
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
      iv_file_id            => iv_file_id               -- ファイルID
     ,iv_format             => iv_format                -- フォーマットパターン
     ,ov_errbuf             => lv_errbuf                -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode               -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
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
    --
    -- エラーがあれば正常件数＝0件で返します
    IF ( gn_error_cnt > 0 ) THEN
      gn_normal_cnt := 0;
    END IF;
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
    --終了ステータスが正常以外の場合はROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
      ROLLBACK;
    ELSE
      -- COMMIT発行
      COMMIT;
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
END XXCMM003A41C;
/
