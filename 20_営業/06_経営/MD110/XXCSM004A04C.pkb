CREATE OR REPLACE PACKAGE BODY XXCSM004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A04C(body)
 * Description      : 顧客マスタから新規獲得した顧客を抽出し、新規獲得ポイント顧客別履歴テーブル
 *                  : にデータを登録します。
 * MD.050           : 新規獲得ポイント集計（新規獲得ポイント集計処理）MD050_CSM_004_A04
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  delete_rec_with_lock   テーブル（レコード単位）のロック処理(A-3)
 *                         データ削除処理(A-4)
 *  make_work_table        ワークテーブルデータ作成／更新処理(A-8)
 *  update_work_table      ワークテープル確定フラグ／新規評価対象区分更新処理(A-11)
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
-- *  insert_hst_table       新規獲得ポイント顧客別履歴テーブル作成処理(A-13)
 *  insert_hst_table       新規獲得ポイント顧客別履歴テーブル作成処理(A-14)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
 *  set_new_point_loop     新規獲得ポイント作成ループ(loop-1)
 *                         顧客情報取得処理(A-5)
 *                         獲得／紹介情報セット処理(A-6)
 *                         ワークテーブルデータチェック処理(A-7)
 *                         ポイント付与判定取得処理(A-9)
 *                         ポイント情報確定判定処理(A-10)
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
-- *                         ポイント按分処理(A-12)
 *                         ポイント２倍処理(A-12)
 *                         ポイント按分処理(A-13)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
 *                            ・make_work_table
 *                            ・insert_hst_table
 *                            ・update_work_table
 *  get_ar_period_loop     データ作成対象期間取得処理(A-2)
 *                            ・delete_rec_with_lock
 *                            ・set_new_point_loop
 *  submain                メイン処理プロシージャ
 *                            ・init
 *                            ・get_ar_period_loop
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・submain
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
-- *                         終了処理(A-14)
 *                         終了処理(A-15)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/27    1.0   n.izumi         新規作成
 *  2009/04/09    1.1   M.Ohtsuki      ［障害T1_0416］業務日付とシステム日付比較の不具合
 *  2009/04/22    1.2   M.Ohtsuki      ［障害T1_0704］コード定義書の不具合
 *  2009/04/22    1.2   M.Ohtsuki      ［障害T1_0713］情報確定判定処理の不具合
 *  2009/07/07    1.3   M.Ohtsuki      ［SCS障害管理番号0000254］部署コード取得条件の不具合
 *  2009/07/14    1.4   M.Ohtsuki      ［SCS障害管理番号0000663］想定外エラー発生時の不具合
 *  2009/07/29    1.5   T.Tsukino      ［SCS障害管理番号0000815］パフォーマンス障害対応
 *  2009/08/17    1.6   T.Tsukino      ［SCS障害管理番号0000870］中止顧客判定期間の不具合追加
 *  2009/11/27    1.7   K.Kubo         ［障害管理番号E_本稼動_00112］獲得/紹介営業員が同一時の不具合
 *  2009/12/07    1.8   T.Tsukino      ［障害管理番号E_本稼動_00335］獲得/紹介営業員が入替え時の不具合/判定日付の変更
 *  2009/12/15    1.9   T.Nakano       ［障害管理番号E_本稼動_00412］業態(小分類)が"27"時の不具合追加
 *  2010/01/19    1.10  S.Karikomi      [障害管理番号E_本稼動_01039] 新規ポイント付与対象変更/獲得ポイント判定の追加/評価対象区分変更
 *  2010/04/19    1.11  S.Karikomi      [障害管理番号E_本稼動_01895] 最低取引期間外、中止理由が"9"時の不具合
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;           -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;             -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;            -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                           -- CREATED_BY
  cd_creation_date          CONSTANT DATE          := SYSDATE;                                      -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                           -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE          := SYSDATE;                                      -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                          -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;                   -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;                      -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;                   -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE          := SYSDATE;                                      -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSM004A04C';                               -- パッケージ名
  --エラーメッセージコード
  cv_err_prof_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                           -- プロファイル取得エラーメッセージ
  cv_err_py4_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00021';                           -- 年度取得エラーメッセージ
  cv_err_emp_msg            CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00023';                           -- 従業員情報取得エラーメッセージ
  cv_err_cust_trn_msg       CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00030';                           -- 新規獲得ポイント顧客別履歴テーブルロックエラーメッセージ
  cv_err_loca_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00033';                           -- 所属拠点不明エラーメッセージ
  cv_err_post_msg           CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00044';                           -- 部署コード取得エラーメッセージ
  cv_err_cnvs_busines_person_msg     CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00046';                  -- 獲得営業員コード未設定エラーメッセージ
--//+ADD START  2010/01/19 E_本稼動_01039 S.Karikomi
  cv_msg_10159              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10159';                           -- ポイント付与条件金額重複エラーメッセージ
--//+ADD END  2010/01/19 E_本稼動_01039 S.Karikomi
  --メッセージコード
  cv_open_period_msg        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00041';                           -- オープン会計期間取得内容メッセージ
  cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                           -- 対象件数メッセージ
  cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                           -- 成功件数メッセージ
  cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                           -- エラー件数メッセージ
  cv_warn_cnt_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                           -- スキップ件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                           -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                           -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                           -- エラー終了全ロールバックメッセージ
  cv_error_stop_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007';                           -- エラー終了一部処理メッセージ
  cv_noparam_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                           -- コンカレント入力パラメータなし
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
  --トークンコード
  cv_empcd_tkn              CONSTANT VARCHAR2(100) := 'JUGYOIN_CD';                                 -- 従業員コード
  cv_prof_name_tkn          CONSTANT VARCHAR2(100) := 'PROF_NAME';                                  -- プロファイル名
  cv_pym_tkn                CONSTANT VARCHAR2(100) := 'YYYYMM';                                     -- オープン中の会計期間（年月）
  cv_py4_tkn                CONSTANT VARCHAR2(100) := 'YYYY';                                       -- 年度算出関数で取得した年度
  cv_gcd_tkn                CONSTANT VARCHAR2(100) := 'GET_CUSTOM_DATE';                            -- 顧客獲得日
  cv_cnt_tkn                CONSTANT VARCHAR2(100) := 'COUNT';                                      -- 処理件数
  cv_dkb_tkn                CONSTANT VARCHAR2(100) := 'DATA_KBN';                                   -- データ区分
  cv_loca_tkn               CONSTANT VARCHAR2(100) := 'KYOTEN_CD';                                  -- 拠点コード
  cv_account_tkn            CONSTANT VARCHAR2(100) := 'KOKYAKU_CD';                                 -- 顧客コード
  --その他
  cv_appl_short_name_csm    CONSTANT VARCHAR2(5)   := 'XXCSM';                                      -- アドオン：経営管理
  cv_appl_short_name_ar     CONSTANT VARCHAR2(2)   := 'AR';                                         -- ARアプリケーション短縮名
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCCP';                                      -- アドオン：共通管理
  cv_point_custom_status    CONSTANT VARCHAR2(30)  := 'XXCSM1_POINT_CUSTOM_STATUS';                 -- 顧客ステータスルックアップタイプ
--//+DEL START 2009/07/07 0000254 M.Ohtsuki
--  cv_post_level_name        CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_POST_LEVEL';               -- ポイント算出用部署階層
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
  cv_set_of_bks_id_name     CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                           -- 会計帳簿ID
--//+ADD START 2009/07/30 0000870 T.Tsukino
  cv_min_deal_period        CONSTANT VARCHAR2(100) := 'XXCSM1_MIN_DEALINGS_PERIOD';                 -- 新規獲得ポイント最低取引期間
--//+ADD END   2009/07/30 0000870 T.Tsukino
  cv_closing_status_o       CONSTANT VARCHAR2(1)   := 'O';                                          -- 会計期間ステータス(オープン)
--//+DEL START 2009/04/27 T1_0713 M.Ohtsuki
--  cv_closing_status_p       CONSTANT VARCHAR2(1)   := 'P';                                          -- 会計期間ステータス(永久クローズ)
--  cv_closing_status_c       CONSTANT VARCHAR2(1)   := 'C';                                          -- 会計期間ステータス(クローズ)
--//+DEL END   2009/04/27 T1_0713 M.Ohtsuki
  cn_new_data               CONSTANT NUMBER        := 1;                                            -- ポイントデータ区分（1：新規獲得ポイント）
  cv_new_point              CONSTANT VARCHAR2(1)   := '1';                                          -- 新規ポイント区分(1：新規）
  cv_lang                   CONSTANT VARCHAR2(10)  := USERENV('LANG');                              -- 言語
  cv_period_start           CONSTANT VARCHAR2(1)   := '1';                                          -- 年度順序（開始）
  cv_period_end             CONSTANT VARCHAR2(2)   := '12';                                         -- 年度順序（終了）
  cv_get                    CONSTANT VARCHAR2(1)   := '0';                                          -- 獲得者データ
  cv_intro                  CONSTANT VARCHAR2(1)   := '1';                                          -- 紹介者データ
  cv_kakutei                CONSTANT VARCHAR2(1)   := '1';                                          -- 確定フラグ確定
  cv_mikakutei              CONSTANT VARCHAR2(1)   := '0';                                          -- 確定フラグ未確定
  cv_intro_ari              CONSTANT VARCHAR2(1)   := '1';                                          -- 紹介者有
  cv_intro_nasi             CONSTANT VARCHAR2(1)   := '0';                                          -- 紹介者無
  cv_cust_work_ari          CONSTANT VARCHAR2(1)   := '1';                                          -- 顧客獲得時ワーク有
  cv_cust_work_nasi         CONSTANT VARCHAR2(1)   := '0';                                          -- 顧客獲得時ワーク無
  cv_sales                  CONSTANT VARCHAR2(2)   := '01';                                         -- 営業職
  cv_other                  CONSTANT VARCHAR2(2)   := '  ';                                         -- 営業職以外
  cv_sts_stop               CONSTANT VARCHAR2(2)   := '90';                                         -- 中止顧客
--//+ADD START 2010/04/19 E_本稼動_01895 S.Karikomi
  cv_stp_reason_niju        CONSTANT VARCHAR2(1)   := '9';                                          -- 中止理由(二重登録)
--//+ADD END 2010/04/19 E_本稼動_01895 S.Karikomi
  cv_grant_ok               CONSTANT VARCHAR2(2)   := '0';                                          -- ポイント付与する
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--  cv_grant_ng               CONSTANT VARCHAR2(2)   := '1';                                          -- ポイント付与しない
  cv_grant_ok_dbl           CONSTANT VARCHAR2(2)   := '1';                                          -- ポイント付与する(2倍)
  cv_grant_ng_stp           CONSTANT VARCHAR2(2)   := '2';                                          -- ポイント付与しない(中止顧客)
  cv_grant_ng_yet           CONSTANT VARCHAR2(2)   := '3';                                          -- ポイント付与しない(未達)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
  cv_point_cond_ari         CONSTANT VARCHAR2(1)   := '1';                                          -- ポイント条件有
  cv_point_cond_nasi        CONSTANT VARCHAR2(1)   := '0';                                          -- ポイント条件無
  cv_jisseki_chk_fuyo       CONSTANT VARCHAR2(1)   := '0';                                          -- 実績判定なし
  cv_jisseki_chk_yo         CONSTANT VARCHAR2(1)   := '1';                                          -- 実績判定あり
  cv_chk_on                 CONSTANT VARCHAR2(1)   := '1';                                          -- チェック条件オン
  cv_cond_all               CONSTANT VARCHAR2(1)   := '1';                                          -- ポイント付与条件1
  cv_cond_any               CONSTANT VARCHAR2(1)   := '2';                                          -- ポイント付与条件2
  cv_cond_sum               CONSTANT VARCHAR2(1)   := '3';                                          -- ポイント付与条件3
--//+UPD START 2009/04/22 T1_0704 M.Ohtsuki
--  cv_business_low_type_s_vd CONSTANT VARCHAR2(2)   := '26';                                         -- 業態（小分類）フルサービス（消化）VD
--  cv_business_low_type_vd   CONSTANT VARCHAR2(2)   := '27';                                         -- 業態（小分類）フルサービスVD
--  cv_business_low_type_n_vd CONSTANT VARCHAR2(2)   := '28';                                         -- 業態（小分類）納品VD
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
  cv_business_low_type_s_vd CONSTANT VARCHAR2(2)   := '24';                                         -- 業態（小分類）フルサービス（消化）VD
  cv_business_low_type_vd   CONSTANT VARCHAR2(2)   := '25';                                         -- 業態（小分類）フルサービスVD
  cv_business_low_type_n_vd CONSTANT VARCHAR2(2)   := '26';                                         -- 業態（小分類）納品VD
--//+UPD END   2009/04/22 T1_0704 M.Ohtsuki
--//+UPD START 2009/12/15 E_本番稼動_00412 T.Nakano
  cv_business_low_type_gvd  CONSTANT VARCHAR2(2)   := '27';                                          -- 業態（小分類）納品VD
--//+UPD END   2009/12/15 E_本番稼動_00412 T.Nakano
  cv_custom_condition_fvd   CONSTANT VARCHAR2(2)   := '01';                                         -- 顧客業態コード フルVD
  cv_custom_condition_nvd   CONSTANT VARCHAR2(2)   := '02';                                         -- 顧客業態コード 納品VD
  cv_custom_condition_gvd   CONSTANT VARCHAR2(2)   := '03';                                         -- 顧客業態コード 一般
  cv_error_on               CONSTANT VARCHAR2(1)   := '1';                                          -- エラーオン
  cv_error_off              CONSTANT VARCHAR2(1)   := '0';                                          -- エラーオフ
  cv_customer_class_cust    CONSTANT VARCHAR2(2)   := '10';                                         -- 顧客区分（顧客）
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                                          -- フラグ'Y'
--//+ADD START 2009/04/27 T1_0713 M.Ohtsuki
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                                          -- フラグ'N'
--//+ADD END   2009/04/27 T1_0713 M.Ohtsuki
  cv_kyousan                CONSTANT VARCHAR2(1)   := '5';                                          -- 売上区分'協賛'
  cv_mihon                  CONSTANT VARCHAR2(1)   := '6';                                          -- 売上区分'見本'
  cv_cm                     CONSTANT VARCHAR2(1)   := '7';                                          -- 売上区分'広告'
  cv_empinfo_upd            CONSTANT VARCHAR2(1)   := '1';                                          -- 発令日＜＝獲得日の状態
--//+ADD START 2010/01/19 E_本稼動_01039 S.Karikomi
  cv_small_classcd          CONSTANT VARCHAR2(100) := 'XXCSM1_SMALL_CLASSCD';                       -- 業態（小分類）参照タイプ名
  cv_point_double_ok        CONSTANT VARCHAR2(1)   := '1';                                          -- ポイントを２倍する
--//+ADD END 2010/01/19 E_本稼動_01039 S.Karikomi
  --デバック用
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  TYPE gt_loc_lv_ttype IS TABLE OF VARCHAR2(10)                                                     -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date           DATE;                                                                   -- 業務日付
--//+ADD START 2009/07/30 0000870 T.Tsukino
  gv_min_deal_period        VARCHAR2(10);                                                           -- 新規獲得ポイント最低取引期間
--//+ADD END   2009/07/30 0000870 T.Tsukino
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--  gv_post_level             VARCHAR2(100);                                                          -- ポイント算出用部署階層
--//+DEL END     2009/07/07 0000254 M.Ohtsuki
  gt_set_of_bks_id          gl_period_statuses.set_of_books_id%TYPE;                                -- 会計帳簿ID
  gt_ar_appl_id             fnd_application.application_id%TYPE;                                    -- ARアプリケーションID
  gv_intro_umu_flg          VARCHAR2(1);                                                            -- 紹介者有無フラグ
--
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  gt_loc_lv_tab             gt_loc_lv_ttype;                                                        -- テーブル型変数の宣言
  ln_loc_lv_cnt             NUMBER;                                                                 -- カウンタ
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  global_lock_expt          EXCEPTION;                                                              -- ロック取得例外
  global_skip_expt          EXCEPTION;                                                              -- 顧客単位スキップ例外

  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT NOCOPY VARCHAR2                                                     -- エラー・メッセージ
   ,ov_retcode              OUT NOCOPY VARCHAR2                                                     -- リターン・コード
   ,ov_errmsg               OUT NOCOPY VARCHAR2                                                     -- ユーザー・エラー・メッセージ
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'init';                                       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_retcode              VARCHAR2(1);                                                            -- リターン・コード
    lv_errbuf               VARCHAR2(4000);                                                         -- エラー・メッセージ
    lv_errmsg               VARCHAR2(4000);                                                         -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    cv_location_level       CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_LEVEL';                    -- ポイント算出用部署階層
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
    -- *** ローカル変数 ***
    lv_tkn_value            VARCHAR2(4000);                                                         -- トークン値
    -- *** ローカル・カーソル **
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    CURSOR get_loc_lv_cur
    IS
          SELECT   flv.lookup_code        lookup_code
          FROM     fnd_lookup_values      flv                                                       -- クイックコード値
          WHERE    flv.lookup_type        = cv_location_level                                       -- ポイント算出用部署階層
            AND    flv.language           = USERENV('LANG')                                         -- 言語('JA')
            AND    flv.enabled_flag       = cv_flg_y                                                -- 使用可能フラグ
            AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                    -- 適用開始日
            AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                    -- 適用終了日
          ORDER BY flv.lookup_code   DESC;                                                          -- ルックアップコード
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
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
    --A-1 初期処理
    --==============================================================
    --==============================================================
    -- ① コンカレント入力パラメータなしメッセージ出力 
    --==============================================================
    gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                                       --アプリケーション短縮名
                       ,iv_name         => cv_noparam_msg                                           --メッセージコード
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => ''           || CHR(10) ||                                                         -- 空行の挿入
                 gv_out_msg   || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
    --ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG                                                                       -- ログ
      ,buff   => ''           || CHR(10) ||                                                         -- 空行の挿入
                 gv_out_msg   || CHR(10) ||
                 ''                                                                                 -- 空行の挿入
    );
--
    --==============================================================
    -- ②プロファイル値取得
    --==============================================================
--
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    FND_PROFILE.GET(name => cv_post_level_name
--                   ,val  => gv_post_level);                                                         -- ポイント算出用部署階層
--//+DEL END     2009/07/07 0000254 M.Ohtsuki
    FND_PROFILE.GET(name => cv_set_of_bks_id_name
                   ,val  => gt_set_of_bks_id);                                                      -- 会計帳簿ID
--//+ADD START 2009/07/30 0000870 T.Tsukino
    FND_PROFILE.GET(name => cv_min_deal_period
                   ,val  => gv_min_deal_period);                                                    -- 新規獲得ポイント最低取引期間
--//+ADD END   2009/07/30 0000870 T.Tsukinoi
--//+UPD START   2009/07/07 0000254 M.Ohtsuki
--    IF ( gv_post_level IS NULL) THEN                                                                -- ポイント算出用部署階層の場合
--      lv_tkn_value    := cv_post_level_name;
--    ELSIF ( gt_set_of_bks_id IS NULL) THEN                                                          -- 会計帳簿IDの場合
--      lv_tkn_value    := cv_set_of_bks_id_name;
--    END IF;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    IF ( gt_set_of_bks_id IS NULL) THEN  
      lv_tkn_value    := cv_set_of_bks_id_name;
    END IF;
--//+UPD START   2009/07/07 0000254 M.Ohtsuki
--//+ADD START 2009/07/30 0000870 T.Tsukino
    IF (gv_min_deal_period IS NULL) THEN  
      lv_tkn_value    := cv_min_deal_period;
    END IF;
--//+ADD END   2009/07/30 0000870 T.Tsukino
    IF (lv_tkn_value IS NOT NULL) THEN                                                              -- 取得に失敗した場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_appl_short_name_csm               -- アプリケーション短縮名
                                           ,iv_name         => cv_err_prof_msg                      -- メッセージコード
                                           ,iv_token_name1  => cv_prof_name_tkn                     -- トークンコード1
                                           ,iv_token_value1 => lv_tkn_value                         -- トークン値1
                                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--  --==============================================================
    --③ ARアプリケーションIDの取得
    --==============================================================
    gt_ar_appl_id := xxccp_common_pkg.get_application(
                                            iv_application_name => cv_appl_short_name_ar            -- ARアプリケーションID取得
                                           );                       
    IF (gt_ar_appl_id IS NULL) THEN                                                                 -- 取得に失敗した場合
      RAISE global_process_expt;
    END IF;
--  --==============================================================
    --④ 業務日付の取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;                                          -- 業務日付取得
--
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
--  --==============================================================
    --⑤ 拠点階層の取得
    --==============================================================
    ln_loc_lv_cnt := 0;                                                                             -- 変数の初期化
    <<get_loc_lv_cur_loop>>                                                                         -- 拠点階層取得LOOP
    FOR rec IN get_loc_lv_cur LOOP
      ln_loc_lv_cnt := ln_loc_lv_cnt + 1;
      gt_loc_lv_tab(ln_loc_lv_cnt)   := rec.lookup_code;                                            -- 拠点階層
    END LOOP get_loc_lv_cur_loop;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END init;
  /**********************************************************************************
   * Procedure Name   : delete_rec_with_lock
   * Description      : テーブル（レコード単位）のロック処理(A-3)
   *                  : データ削除処理(A-4)
   ***********************************************************************************/
  PROCEDURE delete_rec_with_lock(
     it_year             IN         xxcsm_new_cust_point_hst.subject_year%TYPE                      -- 対象年度
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ                          --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード                            --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ                --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_rec_with_lock';                     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    CURSOR  delete_data_cur(                                                                        -- 削除データ取得カーソル(ロックあり)
       it_year2 xxcsm_new_cust_point_hst.subject_year%TYPE
    )
    IS
      SELECT xncph.subject_year   subject_year                                                      -- 対象年度
      FROM   xxcsm_new_cust_point_hst  xncph                                                        -- 新規獲得ポイント顧客別履歴テーブル
      WHERE  xncph.subject_year   =  it_year2                                                       -- 対象年度
      AND    xncph.data_kbn       =  cn_new_data                                                    -- 新規獲得ポイント
      FOR UPDATE OF
          xncph.employee_number,
          xncph.subject_year,
          xncph.month_no,
          xncph.account_number,
          xncph.data_kbn
      NOWAIT;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 対象年度の新規獲得ポイント顧客別履歴テーブルのデータをロックします。
    -- ロックが成功した場合、対象データの削除を行います。
    -- ==============================================================
    --データロック取得（新規獲得ポイント顧客別履歴テーブルの年度単位）
    OPEN delete_data_cur(it_year);
    CLOSE delete_data_cur;
--
    --既存データのパージ（データ洗い替えのため）
    DELETE FROM xxcsm_new_cust_point_hst  xncph                                                     -- 新規獲得ポイント顧客別履歴テーブル
    WHERE  xncph.subject_year   =  it_year                                                          -- 対象年度
    AND    xncph.data_kbn       =  cn_new_data                                                      -- 新規獲得ポイントのデータ
    ;
--
  EXCEPTION
    WHEN global_lock_expt THEN                                                                      -- ロックの取得に失敗した場合
      IF (delete_data_cur%ISOPEN) THEN
        CLOSE delete_data_cur;
      END IF;
      ov_retcode := cv_status_error;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- アプリケーション短縮名
                    ,iv_name         => cv_err_cust_trn_msg                                         -- メッセージコード
                    ,iv_token_name1  => cv_py4_tkn                                                  -- 対象年度
                    ,iv_token_value1 => TO_CHAR(it_year)                                            -- トークン値1
                    ,iv_token_name2  => cv_dkb_tkn                                                  -- データ区分
                    ,iv_token_value2 => TO_CHAR(cn_new_data)                                        -- 1：新規獲得ポイント
                    );
      ov_errbuf := lv_errmsg;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_rec_with_lock;
--
  /**********************************************************************************
   * Procedure Name   : make_work_table
   * Description      : ワークテーブルデータ作成処理
   ***********************************************************************************/
  PROCEDURE make_work_table(
     it_get_intro_kbn    IN         xxcsm_wk_new_cust_get_emp.get_intro_kbn%TYPE                    -- 獲得／紹介区分
    ,it_year             IN         xxcsm_wk_new_cust_get_emp.subject_year%TYPE                     -- 対象年度
    ,it_account_number   IN         xxcsm_wk_new_cust_get_emp.account_number%TYPE                   -- 顧客コード
    ,it_employee_number  IN         xxcsm_wk_new_cust_get_emp.employee_number%TYPE                  -- 従業員コード
    ,it_cnvs_date        IN         xxcmm_cust_accounts.cnvs_date%TYPE                              -- 顧客獲得日
    ,it_business_low_type IN         xxcmm_cust_accounts.business_low_type%TYPE                     -- 業態（小分類）コード
    ,iv_cust_work_flg    IN         VARCHAR2                                                        -- 顧客獲得時ワーク有無フラグ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ                          --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード                            --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ                --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'make_work_table';                          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lt_decision_flg   xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                                  -- 確定フラグ
    lt_location_cd    xxcmm_cust_accounts.intro_base_code%TYPE;                                     -- 拠点
    lt_custom_condition_cd  xxcsm_wk_new_cust_get_emp.custom_condition_cd%TYPE;                     -- 顧客業態コード
    lt_post_cd        xxcmm_cust_accounts.intro_base_code%TYPE;                                     -- 部署コード 
    lv_qualificate_cd VARCHAR2(100);                                                                -- 資格コード
    lv_duties_cd      VARCHAR2(100);                                                                -- 職務コード
    lv_job_type_cd    VARCHAR2(100);                                                                -- 職種コード
    lv_new_old_type   VARCHAR2(1);                                                                  -- 新旧フラグ
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    ln_check_cnt         NUMBER;                                                                    -- 部署チェック用カウンタ
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--//+ADD START  2009/12/07 E_本稼動_00335 T.Tsukino
    ln_wk_chk         NUMBER;                                                                       -- ワークテーブル内登録チェック
    lv_cwork_flg      VARCHAR2(1);                                                                  -- IN変数格納用顧客獲得時ワーク有無フラグ
--//+ADD END  2009/12/07 E_本稼動_00335 T.Tsukino
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--//+ADD START  2009/12/07 E_本稼動_00335  T.Tsukino
    -- 入力パラメータの格納
    lv_cwork_flg := iv_cust_work_flg;
--//+ADD END  2009/12/07 E_本稼動_00335  T.Tsukino
--
    -- ==============================================================
    -- A-8.ワークテーブルデータ作成／更新処理
    -- ==============================================================
    -- 1.業態（小分類）から顧客業態コードを算出します。
    IF (it_business_low_type IN (cv_business_low_type_s_vd,cv_business_low_type_vd)) THEN           -- 業態（小分類）がフルVD、フルVD(消化)の場合
      lt_custom_condition_cd := cv_custom_condition_fvd;     -- 顧客業態コード フルVD
--//+UPD START 2009/12/15 E_本番稼動_00412 T.Nakano
    ELSIF (it_business_low_type IN (cv_business_low_type_n_vd,cv_business_low_type_gvd)) THEN       -- 業態（小分類）納品VDの場合
--    ELSIF (it_business_low_type = cv_business_low_type_n_vd) THEN                                   -- 業態（小分類）納品VDの場合
--//+UPD END 2009/12/15 E_本番稼動_00412 T.Nakano
      lt_custom_condition_cd := cv_custom_condition_nvd;     -- 顧客業態コード 納品VD
    ELSE                                                                                            -- その他の業態（小分類）の場合
      lt_custom_condition_cd := cv_custom_condition_gvd;     -- 顧客業態コード 一般
    END IF; 
    -- 2.獲得/紹介従業員より所属拠点を取得します。
    -- ===============================
    -- 所属拠点取得処理 
    -- ===============================
    xxcsm_common_pkg.get_employee_foothold(
       iv_employee_code   => it_employee_number                                                     -- 従業員コード 
      ,id_comparison_date => it_cnvs_date                                                           -- 顧客獲得日
      ,ov_foothold_code   => lt_location_cd                                                         -- 拠点コード
      ,ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ            
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード              
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ  
    );

    -- 所属拠点取得に失敗した場合
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--    IF   (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    IF   (lv_retcode <> cv_status_normal) 
      OR (lt_location_cd IS NULL) THEN                                                              -- 拠点コード
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name_csm                                        -- アプリケーション短縮名
                  ,iv_name         => cv_err_loca_msg                                               -- 所属拠点不明エラー
                  ,iv_token_name1  => cv_empcd_tkn                                                  -- 従業員コードトークン名
                  ,iv_token_value1 => it_employee_number                                            -- 従業員コード
                  ,iv_token_name2  => cv_gcd_tkn                                                    -- 顧客獲得日トークン名
                  ,iv_token_value2 => it_cnvs_date                                                  -- 顧客獲得日
                 );
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END IF;
    -- 3.拠点コード、カスタムプロファイルの階層を基に、xxcsm:部門ビューから部署コードを取得します。
    --   取得できない場合、顧客単位でスキップします。
    BEGIN
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      ln_check_cnt := 0;                                                                            -- 変数の初期化
      lt_post_cd := NULL;                                                                           -- 変数の初期化
      LOOP
        EXIT WHEN ln_check_cnt >= ln_loc_lv_cnt                                                     -- ポイント算出用部署階層の件数分
              OR  lt_post_cd IS NOT NULL;                                                           -- 部署コードが取得できるまで
        ln_check_cnt := ln_check_cnt + 1;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
--//+UPD START  2009/07/07 0000254 M.Ohtsuki
--        SELECT DECODE(gv_post_level,'L6',xlllv.cd_level6 
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
         SELECT DECODE(gt_loc_lv_tab(ln_check_cnt),'L6',xlllv.cd_level6 
--//+UPD END    2009/07/07 0000254 M.Ohtsuki
                                   ,'L5',xlllv.cd_level5 
                                   ,'L4',xlllv.cd_level4 
                                   ,'L3',xlllv.cd_level3 
                                   ,'L2',xlllv.cd_level2 
                                   ,'L1',xlllv.cd_level1 
                                   ,                NULL
                      ) cd_post
          INTO lt_post_cd            
          FROM xxcsm_loc_level_list_v xlllv
         WHERE DECODE(xlllv.location_level ,'L6',xlllv.cd_level6
                                           ,'L5',xlllv.cd_level5
                                           ,'L4',xlllv.cd_level4
                                           ,'L3',xlllv.cd_level3
                                           ,'L2',xlllv.cd_level2
                                           ,'L1',xlllv.cd_level1
                                           ,                NULL
                      ) = lt_location_cd
           AND ROWNUM = 1;
--//+ADD START  2009/07/07 0000254 M.Ohtsuki
      END LOOP;
      IF (lt_post_cd IS NULL) THEN                                                                  -- 部署コードが抽出できなかった場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- アプリケーション短縮名
                    ,iv_name         => cv_err_post_msg                                             -- 部署コード取得エラー
                    ,iv_token_name1  => cv_account_tkn                                              -- 顧客コードトークン名
                    ,iv_token_value1 => it_account_number                                           -- 顧客コード
                    ,iv_token_name2  => cv_loca_tkn                                                 -- 拠点コードトークン名
                    ,iv_token_value2 => lt_location_cd                                              -- 拠点コード
                   );
        lv_errbuf := lv_errmsg;
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      RAISE global_skip_expt;
--//+UPD END    2009/07/14 0000663 M.Ohtsuki
      END IF;
--//+ADD END    2009/07/07 0000254 M.Ohtsuki
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- アプリケーション短縮名
                    ,iv_name         => cv_err_post_msg                                             -- 部署コード取得エラー
                    ,iv_token_name1  => cv_account_tkn                                              -- 顧客コードトークン名
                    ,iv_token_value1 => it_account_number                                           -- 顧客コード
                    ,iv_token_name2  => cv_loca_tkn                                                 -- 拠点コードトークン名
                    ,iv_token_value2 => lt_location_cd                                              -- 拠点コード
                   );
        lv_errbuf := lv_errmsg;
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END;   
    -- 4.対象従業員の資格コード、職務コード、職種コードを取得します。
    xxcsm_common_pkg.get_employee_info(
       iv_employee_code   => it_employee_number                                                     -- 従業員コード 
      ,id_comparison_date => it_cnvs_date                                                           -- 顧客獲得日
      ,ov_capacity_code   => lv_qualificate_cd                                                      -- 資格コード
      ,ov_duty_code       => lv_duties_cd                                                           -- 職務コード
      ,ov_job_code        => lv_job_type_cd                                                         -- 職種コード
      ,ov_new_old_type    => lv_new_old_type                                                        -- 新旧フラグ（1：新、2：旧）
      ,ov_errbuf          => lv_errbuf                                                              -- エラー・メッセージ            
      ,ov_retcode         => lv_retcode                                                             -- リターン・コード              
      ,ov_errmsg          => lv_errmsg                                                              -- ユーザー・エラー・メッセージ  
    );
    -- 資格等の取得に失敗した場合、顧客単位にスキップします。
    IF     (lv_retcode <> cv_status_normal) 
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
        OR (lv_qualificate_cd IS NULL)                                                              -- 資格コード
        OR (lv_job_type_cd    IS NULL)                                                              -- 職種コード
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
        OR (lv_duties_cd IS NULL) THEN                                                              
        lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name_csm                                        -- アプリケーション短縮名
                  ,iv_name         => cv_err_emp_msg                                                -- 従業員情報取得エラー
                  ,iv_token_name1  => cv_account_tkn                                                -- 顧客コードトークン名
                  ,iv_token_value1 => it_account_number                                             -- 顧客コード
                  ,iv_token_name2  => cv_empcd_tkn                                                  -- 従業員コードトークン名
                  ,iv_token_value2 => it_employee_number                                            -- 従業員コード
                  ,iv_token_name3  => cv_gcd_tkn                                                    -- 顧客獲得日トークン名
                  ,iv_token_value3 => it_cnvs_date                                                  -- 顧客獲得日
                 );
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--      RAISE global_process_expt;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      RAISE global_skip_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
    END IF;
--//+ADD START  2009/12/07 E_本稼動_00335 T.Tsukino
    -- 5.INパラメータの顧客獲得時ワーク有無フラグの判定を、獲得・紹介区分を使用せず実施します。
    IF (lv_cwork_flg = cv_cust_work_nasi) THEN
      ln_wk_chk    := NULL;   -- 変数の初期化
     --
     -- 顧客獲得時従業員ワークテーブルに獲得営業員コードがすでに存在しているか
     -- チェックする。
      SELECT count(1)
      INTO   ln_wk_chk  -- 存在チェックのため、NO_DATA_FOUNDはなし
      FROM   xxcsm_wk_new_cust_get_emp  xwncge
      WHERE  xwncge.subject_year = it_year                                                           -- 対象年度
        AND  xwncge.account_number = it_account_number                                               -- 顧客コード
        AND  xwncge.employee_number = it_employee_number                                             -- 獲得営業員コード
      ;
      --ワークテーブル内に獲得区分でデータが存在した場合、
      --既存のワークテーブル内獲得営業員コードを更新する
      IF (ln_wk_chk >= 1) THEN
        lv_cwork_flg     := cv_cust_work_ari;
      END IF;
    END IF;
--//+ADD END  2009/12/07 E_本稼動_00335  T.Tsukino
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
-- ↓↓↓↓(MD050上の変更)↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    -- 5.顧客獲得時従業員ワークテーブルへ作成／更新を行ないます。
    -- 6.顧客獲得時従業員ワークテーブルへ作成／更新を行ないます。
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
    -- ===============================
    -- 未登録の場合、作成します。
    -- ===============================
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--    IF (iv_cust_work_flg = cv_cust_work_nasi) THEN
    IF (lv_cwork_flg = cv_cust_work_nasi) THEN
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
      INSERT INTO xxcsm_wk_new_cust_get_emp(                                                        -- 顧客獲得時従業員ワークテーブル
        subject_year                                                                                -- 対象年度
       ,account_number                                                                              -- 顧客コード
       ,custom_condition_cd                                                                         -- 顧客業態コード
       ,employee_number                                                                             -- 従業員コード
       ,post_cd                                                                                     -- 部署コード
       ,qualificate_cd                                                                              -- 資格コード
       ,duties_cd                                                                                   -- 職務コード
       ,job_type_cd                                                                                 -- 職種コード
       ,location_cd                                                                                 -- 拠点コード
       ,get_custom_date                                                                             -- 顧客獲得日
       ,decision_flg                                                                                -- 確定フラグ
       ,get_intro_kbn                                                                               -- 獲得・紹介区分
       ,created_by                                                                                  -- 作成者
       ,creation_date                                                                               -- 作成日
       ,last_updated_by                                                                             -- 最終更新者
       ,last_update_date                                                                            -- 最終更新日
       ,last_update_login                                                                           -- 最終更新ログイン
       ,request_id                                                                                  -- 要求ID
       ,program_application_id                                                                      -- コンカレント・プログラムのアプリケーションID
       ,program_id                                                                                  -- コンカレント・プログラムID
       ,program_update_date                                                                         -- プログラムによる更新日
      ) VALUES (
        it_year                                                                                     -- 対象年度   
       ,it_account_number                                                                           -- 顧客コード
       ,lt_custom_condition_cd                                                                      -- 顧客業態コード
       ,it_employee_number                                                                          -- 従業員コード
       ,lt_post_cd                                                                                  -- 部署コード
       ,lv_qualificate_cd                                                                           -- 資格コード
       ,lv_duties_cd                                                                                -- 職務コード
       ,lv_job_type_cd                                                                              -- 職種コード
       ,lt_location_cd                                                                              -- 獲得拠点コード
       ,it_cnvs_date                                                                                -- 顧客獲得日
       ,cv_mikakutei                                                                                -- 確定フラグ
       ,it_get_intro_kbn                                                                            -- 獲得・紹介区分
       ,cn_created_by                                                                               -- 作成者
       ,cd_creation_date                                                                            -- 作成日
       ,cn_last_updated_by                                                                          -- 最終更新者
       ,cd_last_update_date                                                                         -- 最終更新日
       ,cn_last_update_login                                                                        -- 最終更新ログイン
       ,cn_request_id                                                                               -- 要求ID
       ,cn_program_application_id                                                                   -- コンカレント・プログラムのアプリケーションID
       ,cn_program_id                                                                               -- コンカレント・プログラムID
       ,cd_program_update_date                                                                      -- プログラムによる更新日
      );
    -- ===============================
    -- 登録済の場合、更新します。
    -- 発令日＜＝顧客獲得日の間、従業員情報を最新化します。（マスタ不備対応）
    -- 発令日＞顧客獲得日の場合、従業員情報を最新化しません。（獲得日時点の従業員情報を保持する）
    -- ===============================
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--    ELSIF (iv_cust_work_flg = cv_cust_work_ari) THEN
    ELSIF (lv_cwork_flg = cv_cust_work_ari) THEN
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
      UPDATE xxcsm_wk_new_cust_get_emp xwncge                                                       -- 顧客獲得時従業員ワークテーブル
      SET xwncge.custom_condition_cd    =  lt_custom_condition_cd                                   -- 顧客業態コード
         ,xwncge.post_cd                =  DECODE(lv_new_old_type,cv_empinfo_upd,lt_post_cd,xwncge.post_cd)               -- 部署コード
         ,xwncge.qualificate_cd         =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_qualificate_cd,xwncge.qualificate_cd) -- 資格コード
         ,xwncge.duties_cd              =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_duties_cd,xwncge.duties_cd)           -- 職務コード
         ,xwncge.job_type_cd            =  DECODE(lv_new_old_type,cv_empinfo_upd,lv_job_type_cd,xwncge.job_type_cd)       -- 職種コード
         ,xwncge.location_cd            =  DECODE(lv_new_old_type,cv_empinfo_upd,lt_location_cd,xwncge.location_cd)       -- 拠点コード
         ,xwncge.get_custom_date        =  it_cnvs_date                                             -- 顧客獲得日
         ,xwncge.get_intro_kbn          =  it_get_intro_kbn                                         -- 獲得・紹介区分
         ,xwncge.last_updated_by        =  cn_last_updated_by                                       -- 最終更新者
         ,xwncge.last_update_date       =  cd_last_update_date                                      -- 最終更新日
         ,xwncge.last_update_login      =  cn_last_update_login                                     -- 最終更新ログイン
         ,xwncge.request_id             =  cn_request_id                                            -- 要求ID
         ,xwncge.program_application_id =  cn_program_application_id                                -- コンカレント・プログラムのアプリケーションID
         ,xwncge.program_id             =  cn_program_id                                            -- コンカレント・プログラムID
         ,xwncge.program_update_date    =  cd_program_update_date                                   -- プログラムによる更新日
      WHERE xwncge.subject_year = it_year                                                           -- 対象年度
        AND xwncge.account_number = it_account_number                                               -- 顧客コード
        AND xwncge.employee_number = it_employee_number                                             -- 獲得営業員コード
--//+DEL START  2009/12/07 E_本稼動_00335 T.Tsukino
--        AND xwncge.get_intro_kbn = it_get_intro_kbn                                                 -- 獲得／紹介区分
--//+DEL END  2009/12/07 E_本稼動_00335 T.Tsukino
      ;
    END IF;
  EXCEPTION
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
    WHEN global_skip_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_work_table;
--
  /**********************************************************************************
   * Procedure Name   : insert_hst_table
   * Description      : 新規獲得ポイント顧客別履歴テーブル作成処理
   ***********************************************************************************/
  PROCEDURE insert_hst_table(
     it_get_intro_kbn    xxcsm_wk_new_cust_get_emp.get_intro_kbn%TYPE
    ,it_year             xxcsm_wk_new_cust_get_emp.subject_year%TYPE
    ,it_account_number   xxcsm_wk_new_cust_get_emp.account_number%TYPE
    ,it_employee_number  xxcsm_wk_new_cust_get_emp.employee_number%TYPE
    ,it_job_type_cd      xxcsm_wk_new_cust_get_emp.job_type_cd%TYPE
    ,it_business_low_type xxcsm_new_cust_point_hst.business_low_type%TYPE
    ,it_point            xxcsm_new_cust_point_hst.point%TYPE
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ                          --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード                            --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ                --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_hst_table';                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
     -- 紹介者の登録 ★プロシージャー化★
    INSERT INTO xxcsm_new_cust_point_hst(                                                           -- 新規獲得ポイント顧客別履歴テーブル
      subject_year                                                                                  -- 対象年度
     ,year_month                                                                                    -- 年月
     ,month_no                                                                                      -- 月
     ,account_number                                                                                -- 顧客コード
     ,custom_condition_cd                                                                           -- 顧客業態コード
     ,get_custom_date                                                                               -- 顧客獲得日
     ,employee_number                                                                               -- 従業員コード
     ,post_cd                                                                                       -- 部署コード
     ,qualificate_cd                                                                                -- 資格コード
     ,duties_cd                                                                                     -- 職務コード
     ,location_cd                                                                                   -- 拠点コード
     ,point                                                                                         -- ポイント
     ,business_low_type                                                                             -- 業態（小分類）
     ,data_kbn                                                                                      -- データ区分
     ,evaluration_kbn                                                                               -- 新規評価対象区分
     ,get_intro_kbn                                                                                 -- 獲得・紹介区分
     ,created_by                                                                                    -- 作成者
     ,creation_date                                                                                 -- 作成日
     ,last_updated_by                                                                               -- 最終更新者
     ,last_update_date                                                                              -- 最終更新日
     ,last_update_login                                                                             -- 最終更新ログイン
     ,request_id                                                                                    -- 要求ID
     ,program_application_id                                                                        -- コンカレント・プログラムのアプリケーションID
     ,program_id                                                                                    -- コンカレント・プログラムID
     ,program_update_date                                                                           -- プログラムによる更新日
    ) 
    SELECT xwncge.subject_year                                     subject_year                     -- 対象年度
          ,TO_NUMBER(TO_CHAR(xwncge.get_custom_date,'YYYYMM'))     get_custom_yyyymm                -- 年月(顧客獲得日YYYYMM)
          ,TO_NUMBER(TO_CHAR(xwncge.get_custom_date,'MM'))         get_custom_mm                    -- 月(顧客獲得日MM)
          ,xwncge.account_number                                   account_number                   -- 顧客コード
          ,xwncge.custom_condition_cd                              custom_condition_cd              -- 顧客業態コード
          ,xwncge.get_custom_date                                  get_custom_date                  -- 顧客獲得日
          ,xwncge.employee_number                                  employee_number                  -- 従業員コード
          ,xwncge.post_cd                                          post_cd                          -- 部署コード
          ,xwncge.qualificate_cd                                   qualificate_cd                   -- 資格コード
          ,xwncge.duties_cd                                        duties_cd                        -- 職務コード
          ,xwncge.location_cd                                      location_cd                      -- 拠点コード
          ,it_point                                                point                            -- ポイント
          ,it_business_low_type                                    business_low_type                -- 業態（小分類）
          ,cn_new_data                                             new_data                         -- 新規獲得ポイントデータ
          ,xwncge.evaluration_kbn                                  evaluration_kbn                  -- 新規評価対象区分
          ,xwncge.get_intro_kbn                                    get_intro_kbn                    -- 獲得／紹介区分
          ,cn_created_by                                           created_by                       -- 作成者
          ,cd_creation_date                                        creation_date                    -- 作成日
          ,cn_last_updated_by                                      last_updated_by                  -- 最終更新者
          ,cd_last_update_date                                     last_update_date                 -- 最終更新日
          ,cn_last_update_login                                    last_update_login                -- 最終更新ログイン
          ,cn_request_id                                           request_id                       -- 要求ID
          ,cn_program_application_id                               program_application_id           -- コンカレント・プログラムのアプリケーションID
          ,cn_program_id                                           program_id                       -- コンカレント・プログラムID
          ,cd_program_update_date                                  program_update_date              -- プログラムによる更新日
      FROM xxcsm_wk_new_cust_get_emp xwncge                                                         -- 顧客獲得時従業員ワークテーブル
     WHERE xwncge.subject_year = it_year                                                            -- 対象年度
       AND xwncge.account_number = it_account_number                                                -- 顧客コード
       AND xwncge.employee_number = it_employee_number                                              -- 従業員コード
       AND xwncge.get_intro_kbn = it_get_intro_kbn                                                  -- 獲得／紹介区分
       AND xwncge.job_type_cd = DECODE(it_get_intro_kbn,cv_intro,cv_sales,xwncge.job_type_cd)       -- 紹介者の場合、営業職のみ、獲得者の場合、無条件
    ;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_hst_table;
--
  /**********************************************************************************
   * Procedure Name   : update_work_table
   * Description      : ワークテープル確定フラグ／新規評価対象区分更新処理  獲得営業員／紹介従業員の両方を更新する。
   ***********************************************************************************/
  PROCEDURE update_work_table(
     it_year             IN         xxcsm_wk_new_cust_get_emp.subject_year%TYPE
    ,it_account_number   IN         xxcsm_wk_new_cust_get_emp.account_number%TYPE
    ,it_decision_flg     IN         xxcsm_wk_new_cust_get_emp.decision_flg%TYPE
    ,it_evaluration_kbn  IN         xxcsm_wk_new_cust_get_emp.evaluration_kbn%TYPE
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ                          --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード                            --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ                --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'update_work_table';                        -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    UPDATE xxcsm_wk_new_cust_get_emp xwncge                                                         -- 顧客獲得時従業員ワークテーブル
    SET decision_flg           =  it_decision_flg                                                   -- 確定フラグ
       ,evaluration_kbn        =  it_evaluration_kbn                                                -- 新規評価対象区分
       ,last_updated_by        =  cn_last_updated_by                                                -- 最終更新者
       ,last_update_date       =  cd_last_update_date                                               -- 最終更新日
       ,last_update_login      =  cn_last_update_login                                              -- 最終更新ログイン
       ,request_id             =  cn_request_id                                                     -- 要求ID
       ,program_application_id =  cn_program_application_id                                         -- コンカレント・プログラムのアプリケーションID
       ,program_id             =  cn_program_id                                                     -- コンカレント・プログラムID
       ,program_update_date    =  cd_program_update_date                                            -- プログラムによる更新日
    WHERE xwncge.subject_year = it_year                                                             -- 対象年度
      AND xwncge.account_number = it_account_number                                                 -- 顧客コード
    ;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_work_table;
--
  /**********************************************************************************
   * Procedure Name   : set_new_point_loop
   * Description      : 新規獲得ポイント作成ループ
   *                  : 顧客情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE set_new_point_loop(
     it_year             IN         xxcsm_new_cust_point_hst.subject_year%TYPE                      -- 対象年度
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ                          --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード                            --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ                --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_new_point_loop';                       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lt_decision_flg_get      xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- 獲得営業員確定フラグ
    lt_decision_flg_intro    xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- 紹介従業員確定フラグ
    lt_decision_flg_upd      xxcsm_wk_new_cust_get_emp.decision_flg%TYPE;                           -- 更新用確定フラグ
    lv_cust_work_flg         VARCHAR2(1);                                                           -- 顧客獲得時ワーク有無フラグ
    lt_evaluration_kbn       xxcsm_wk_new_cust_get_emp.evaluration_kbn%TYPE;                        -- 更新用新規評価対象区分
    lt_point                 xxcsm_new_cust_point_hst.point%TYPE;                                   -- 獲得ポイント
    lt_custom_condition_cd   xxcsm_mst_grant_point.custom_condition_cd%TYPE;                        -- 顧客業態コード
    lt_grant_condition_point xxcsm_mst_grant_point.grant_condition_point%TYPE;                      -- ポイント付与条件
    lt_post_cd               xxcsm_mst_grant_point.post_cd%TYPE;                                    -- 部署コード
    lt_duties_cd             xxcsm_mst_grant_point.duties_cd%TYPE;                                  -- 職務コード
    lt_1st_month             xxcsm_mst_grant_point.grant_point_target_1st_month%TYPE;               -- ポイント付与条件対象月_当月
    lt_2nd_month             xxcsm_mst_grant_point.grant_point_target_2nd_month%TYPE;               -- ポイント付与条件対象月_翌月
    lt_3rd_month             xxcsm_mst_grant_point.grant_point_target_3rd_month%TYPE;               -- ポイント付与条件対象月_翌々月
    lt_price                 xxcsm_mst_grant_point.grant_point_condition_price%TYPE;                -- ポイント付与条件金額
--//+ADD START 2010/01/19 E_本稼動_01039 S.Karikomi
    lt_min_grant_condition_point xxcsm_mst_grant_point.grant_condition_point%TYPE;                  -- ポイント付与条件(最低金額時)
    lt_max_grant_condition_point xxcsm_mst_grant_point.grant_condition_point%TYPE;                  -- ポイント付与条件(最高金額時)
    lt_min_1st_month             xxcsm_mst_grant_point.grant_point_target_1st_month%TYPE;           -- ポイント付与条件対象月_当月(最低金額時)
    lt_max_1st_month             xxcsm_mst_grant_point.grant_point_target_1st_month%TYPE;           -- ポイント付与条件対象月_当月(最高金額時)
    lt_min_2nd_month             xxcsm_mst_grant_point.grant_point_target_2nd_month%TYPE;           -- ポイント付与条件対象月_翌月(最低金額時)
    lt_max_2nd_month             xxcsm_mst_grant_point.grant_point_target_2nd_month%TYPE;           -- ポイント付与条件対象月_翌月(最高金額時)
    lt_min_3rd_month             xxcsm_mst_grant_point.grant_point_target_3rd_month%TYPE;           -- ポイント付与条件対象月_翌々月(最低金額時)
    lt_max_3rd_month             xxcsm_mst_grant_point.grant_point_target_3rd_month%TYPE;           -- ポイント付与条件対象月_翌々月(最高金額時)
    lt_min_price                 xxcsm_mst_grant_point.grant_point_condition_price%TYPE;            -- ポイント付与条件最低金額
    lt_max_price                 xxcsm_mst_grant_point.grant_point_condition_price%TYPE;            -- ポイント付与条件最高金額
    lv_point_double_flg          VARCHAR2(1);                                                       -- 実績と最高金額との判定用
--//+ADD END 2010/01/19 E_本稼動_01039 S.Karikomi
    lv_point_cond_flg        VARCHAR2(1);                                                           -- ポイント条件有無フラグ
    ln_add_mm                NUMBER(1);                                                             -- 月数
    ln_dummy                 NUMBER;                                                                -- ポイント付与条件最終月判定用
    lv_chk_jisseki_flg       VARCHAR2(1);                                                           -- 販売実績データとの判定用
    lt_amount_1st            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- 本体金額当月計
    lt_amount_2nd            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- 本体金額翌月計
    lt_amount_3rd            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- 本体金額翌々月計
    lt_amount_all            xxcos_sales_exp_lines.pure_amount%TYPE;                                -- 本体金額全月計
    lv_error_flg             VARCHAR2(1);                                                           -- エラーフラグ
    -- *** ローカル・カーソル ***
    CURSOR  set_new_point_cur(                                                                      -- 顧客情報取得カーソル
       it_year xxcsm_new_cust_point_hst.subject_year%TYPE                                           -- 対象年度
      ,it_set_of_bks_id gl_period_statuses.set_of_books_id%TYPE                                     -- 会計帳簿ID
     )
    IS
      SELECT  hca.account_number         account_number                                             -- 顧客コード
             ,hp.duns_number_c           duns_number_c                                              -- 顧客ステータス
             ,xca.business_low_type      business_low_type                                          -- 業態（小分類）
             ,xca.new_point_div          new_point_div                                              -- 新規ポイント区分
             ,xca.new_point              new_point                                                  -- 新規ポイント
             ,xca.intro_business_person  intro_business_person                                      -- 紹介従業員
             ,xca.intro_base_code        intro_base_code                                            -- 紹介拠点
             ,xca.cnvs_date              cnvs_date                                                  -- 顧客獲得日
             ,xca.stop_approval_date     stop_approval_date                                         -- 中止決済日
--//+ADD START 2010/04/19 E_本稼動_01895 S.Karikomi
             ,xca.stop_approval_reason   stop_approval_reason                                       -- 中止理由
--//+ADD END 2010/04/19 E_本稼動_01895 S.Karikomi
             ,xca.cnvs_business_person   cnvs_business_person                                       -- 獲得営業員
             ,xca.cnvs_base_code         cnvs_base_code                                             -- 獲得拠点
             ,xca.start_tran_date        start_tran_date                                            -- 初回取引日
        FROM  hz_cust_accounts hca
             ,hz_parties hp
             ,xxcmm_cust_accounts xca
             ,(SELECT  TRUNC(MIN(start_date)) year_start_date
                      ,TRUNC(MAX(end_date))   year_end_date
               FROM   gl_sets_of_books gsob
                     ,gl_periods       gp
               WHERE  gsob.set_of_books_id = it_set_of_bks_id
               AND    gsob.period_set_name = gp.period_set_name
               AND    gp.period_year       = it_year)   gpv
--//+UPD START 2009/07/29 0000815 T.Tsukino
--       WHERE  TRUNC(xca.cnvs_date) >= gpv.year_start_date                                           -- 顧客獲得日 >= 会計期間開始日
--         AND  TRUNC(xca.cnvs_date) <= gpv.year_end_date                                             -- 顧客獲得日 <= 会計期間終了日
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
       WHERE  xca.cnvs_date >= gpv.year_start_date                                                  -- 顧客獲得日 >= 会計期間開始日
         AND  xca.cnvs_date <= gpv.year_end_date                                                    -- 顧客獲得日 <= 会計期間終了日
--//+UPD END 2009/07/29 0000815 T.Tsukino         
         AND  hca.cust_account_id = xca.customer_id
         AND  hca.party_id = hp.party_id
         AND  xca.new_point_div = cv_new_point                                                      -- 新規ポイント区分が新規
         AND  hca.customer_class_code = cv_customer_class_cust                                      -- 顧客区分（10：顧客）
         AND  hp.duns_number_c IN (
                SELECT  flv.lookup_code    duns_number_c                                            -- 顧客ステータス
                  FROM  fnd_lookup_values  flv                                                      -- クイックコード値
                 WHERE  flv.lookup_type        = cv_point_custom_status                             -- 顧客ステータスルックアップタイプ
                   AND  flv.language           = cv_lang                                            -- 言語('JA')
                   AND  flv.enabled_flag       = cv_flg_y                                           -- 有効フラグ
--//+UPD START 2009/04/09 T1_0416 M.Ohtsuki
--                   AND  flv.start_date_active <= gd_process_date
--                   AND  NVL(flv.end_date_active,SYSDATE)   >= gd_process_date
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                   AND  NVL(flv.start_date_active,gd_process_date) <= gd_process_date
                   AND  NVL(flv.end_date_active,gd_process_date)   >= gd_process_date
--//+UPD END   2009/04/09 T1_0416 M.Ohtsuki
                )
         AND  NVL(xca.new_point,0) <> 0                                                             -- 新規ポイントが未設定または0以外
--//+ADD START 2010/01/19 E_本稼動_01039 S.Karikomi
         AND  xca.business_low_type NOT IN (
                 SELECT  flv.lookup_code        lookup_code
                   FROM  fnd_lookup_values      flv
                  WHERE  flv.lookup_type        = cv_small_classcd                                  -- 業態（小分類）の参照タイプ名
                    AND  flv.enabled_flag       = cv_flg_y                                          -- 使用可能フラグ
                    AND  flv.language           = cv_lang                                           -- 言語('JA')
                    AND  NVL(flv.start_date_active,gd_process_date) <= gd_process_date              -- 適用開始日
                    AND  NVL(flv.end_date_active,gd_process_date)   >= gd_process_date              -- 適用終了日
                )
--//+ADD END 2010/01/19 E_本稼動_01039 S.Karikomi
      ;
--
    CURSOR  set_month_amount_cur(                                                                   -- 販売実績取得カーソル
       it_account_number xxcos_sales_exp_headers.ship_to_customer_code%TYPE                         -- 顧客コード
      ,it_year_month xxcos_sales_exp_headers.delivery_date%TYPE                                     -- 実績年月
     )
    IS
       SELECT NVL(SUM(xseh.pure_amount_sum),0) amount                                               -- 本体金額の合計
         FROM xxcsm_sales_exp_headers_v xseh                                                        -- 販売実績ヘッダビュー
        WHERE xseh.ship_to_customer_code = it_account_number                                        -- 顧客コード
          AND TRUNC(xseh.delivery_date,'MM') = it_year_month                                        -- 納入日１日
          AND NOT EXISTS (SELECT 'X'                                                                -- 区分が5：協賛、6：見本を除く
                            FROM xxcsm_sales_exp_lines_v xsel                                       -- 販売実績明細ビュー
                           WHERE xsel.sales_exp_header_id = xseh.sales_exp_header_id                -- 同一ヘッダIDで明細を判定
                             AND xsel.sales_class IN (cv_kyousan,cv_mihon,cv_cm)                    -- 区分が5：協賛、6：見本、7：広告
                         )
         ;
    set_month_amount_rec set_month_amount_cur%ROWTYPE;                                              -- 販売実績売上計取得レコード
    
--
--//+ADD START 2010/01/19 E_本稼動_01039 S.Karikomi
    CURSOR grant_condition_point_cur(
       it_account_number xxcsm_wk_new_cust_get_emp.account_number%TYPE
      ,it_employee_number xxcsm_wk_new_cust_get_emp.employee_number%TYPE
      ,it_year xxcsm_new_cust_point_hst.subject_year%TYPE                                           -- 対象年度
    )                                                                                               -- ポイント付与条件カーソル
    IS
       SELECT  xmgp.custom_condition_cd              custom_condition_cd                            -- 顧客業態コード
              ,xmgp.grant_condition_point            grant_condition_point                          -- ポイント付与条件
              ,xmgp.post_cd                          post_cd                                        -- 部署コード
              ,xmgp.duties_cd                        duties_cd                                      -- 職務コード
              ,xmgp.grant_point_target_1st_month     target_1st_month                               -- ポイント付与条件対象月_当月
              ,xmgp.grant_point_target_2nd_month     target_2nd_month                               -- ポイント付与条件対象月_翌月
              ,xmgp.grant_point_target_3rd_month     target_3rd_month                               -- ポイント付与条件対象月_翌々月
              ,xmgp.grant_point_condition_price      condition_price                                -- ポイント付与条件金額
         FROM  xxcsm_mst_grant_point xmgp                                                           -- ポイント付与条件マスタ
              ,xxcsm_wk_new_cust_get_emp xwncge                                                     -- 顧客獲得従業員ワークテーブル
        WHERE xmgp.subject_year        = xwncge.subject_year                                        -- 対象年度
          AND xmgp.post_cd             = xwncge.post_cd                                             -- 部署コード
          AND xmgp.duties_cd           = xwncge.duties_cd                                           -- 職務
          AND xmgp.custom_condition_cd = xwncge.custom_condition_cd                                 -- 顧客業態コード
          AND xwncge.account_number    = it_account_number                                          -- 顧客コード
          AND xwncge.employee_number   = it_employee_number                                         -- 獲得営業員
          AND xwncge.get_intro_kbn     = cv_get                                                     -- 獲得紹介区分
          AND xwncge.subject_year      = it_year                                                    -- 対象年度
       ORDER BY
              condition_price                                                                       -- ポイント付与条件金額で昇順にソート
       ;
    grant_condition_point_rec grant_condition_point_cur%ROWTYPE;                                    -- ポイント付与条件取得レコード
--
    repeat_price_expt          EXCEPTION;                                                           -- ポイント付与条件金額重複例外
--//+ADD END 2010/01/19 E_本稼動_01039 S.Karikomi
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- A-5.顧客情報取得処理
    -- ==============================================================
    <<set_new_point_loop>>                                                                          -- 既存データロック取得後、削除LOOP
    FOR set_new_point_rec IN set_new_point_cur(
       it_year                                                                                      -- 対象年度
      ,gt_set_of_bks_id                                                                             -- 会計帳簿ID
        )
    LOOP
      --各種フラグの初期化
      lt_decision_flg_get := NULL;                                                                  -- 獲得営業員確定フラグ
      lt_decision_flg_intro := NULL;                                                                -- 紹介従業員確定フラグ
      lt_decision_flg_upd := NULL;                                                                  -- 更新用確定フラグ
      lv_cust_work_flg    := NULL;                                                                  -- 顧客獲得時ワーク有無フラグ
      lt_evaluration_kbn  := NULL;                                                                  -- 更新用新規評価対象区分
      lt_point            := NULL;                                                                  -- 獲得ポイント
      lt_custom_condition_cd   := NULL;                                                             -- 顧客業態コード
      lt_grant_condition_point := NULL;                                                             -- ポイント付与条件
      lt_post_cd          := NULL;                                                                  -- 部署コード
      lt_duties_cd        := NULL;                                                                  -- 職務コード
      lt_1st_month        := NULL;                                                                  -- ポイント付与条件対象月_当月
      lt_2nd_month        := NULL;                                                                  -- ポイント付与条件対象月_翌月
      lt_3rd_month        := NULL;                                                                  -- ポイント付与条件対象月_翌々月
      lt_price            := NULL;                                                                  -- ポイント付与条件金額
--//+ADD START 2010/01/19 E_本稼動_01039 S.Karikomi
      lt_min_grant_condition_point := NULL;                                                         -- ポイント付与条件(最低金額時)
      lt_max_grant_condition_point := NULL;                                                         -- ポイント付与条件(最高金額時)
      lt_min_1st_month             := NULL;                                                         -- ポイント付与条件対象月_当月(最低金額時)
      lt_max_1st_month             := NULL;                                                         -- ポイント付与条件対象月_当月(最高金額時)
      lt_min_2nd_month             := NULL;                                                         -- ポイント付与条件対象月_翌月(最低金額時)
      lt_max_2nd_month             := NULL;                                                         -- ポイント付与条件対象月_翌月(最高金額時)
      lt_min_3rd_month             := NULL;                                                         -- ポイント付与条件対象月_翌々月(最低金額時)
      lt_max_3rd_month             := NULL;                                                         -- ポイント付与条件対象月_翌々月(最高金額時)
      lt_min_price                 := NULL;                                                         -- ポイント付与条件最低金額
      lt_max_price                 := NULL;                                                         -- ポイント付与条件最高金額
      lv_point_double_flg          := NULL;                                                         -- 実績と最高金額との判定用
--//+ADD END 2010/01/19 E_本稼動_01039 S.Karikomi
      lv_point_cond_flg   := NULL;                                                                  -- ポイント条件有無フラグ
      ln_add_mm           := NULL;                                                                  -- 月数
      ln_dummy            := NULL;                                                                  -- ポイント付与条件最終月判定用
      lv_chk_jisseki_flg  := NULL;                                                                  -- 販売実績データとの判定用
      lt_amount_1st       := 0;                                                                     -- 本体金額当月計
      lt_amount_2nd       := 0;                                                                     -- 本体金額翌月計
      lt_amount_3rd       := 0;                                                                     -- 本体金額翌々月計
      lt_amount_all       := 0;                                                                     -- 本体金額全月計
      lv_error_flg        := cv_error_off;                                                          -- エラーフラグ
      -- ==============================================================
      -- ①対象年度内に獲得した新規顧客データを取得します。
      -- ==============================================================
      -- セーブポイント
      SAVEPOINT set_new_point;
      -- ==============================================================
      -- ②紹介者有無情報設定 
      -- ==============================================================
--//+UPD START 2009/11/27 E_本稼動_00112 K.Kubo
--      IF (set_new_point_rec.intro_business_person IS NULL) THEN                                     -- 紹介従業員が未設定の場合
      IF (set_new_point_rec.intro_business_person IS NULL                                           -- 紹介従業員が未設定
        OR set_new_point_rec.intro_business_person = set_new_point_rec.cnvs_business_person         -- 紹介従業員と獲得従業員が同一
      ) THEN
--//+UPD END   2009/11/27 E_本稼動_00112 K.Kubo
        gv_intro_umu_flg := cv_intro_nasi;                                                          -- 紹介従業員の処理はしない
      ELSE                                                                                          -- 紹介従業員が設定されている場合
        gv_intro_umu_flg := cv_intro_ari;                                                           -- 紹介従業員の処理もする
      END IF;      
     -- ========================================
      -- A-6.獲得/紹介情報セット処理
      -- A-7.ワークテーブルデータチェック処理
      -- A-8.ワークテーブルデータ作成／更新処理
      -- ========================================
      BEGIN    
      -- ==============================================================
      -- 獲得営業員有無情報設定 
      -- ==============================================================
        IF (set_new_point_rec.cnvs_business_person IS NULL) THEN                                    -- 獲得従業員が未設定の場合
          lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_csm                                      -- アプリケーション短縮名
                    ,iv_name         => cv_err_cnvs_busines_person_msg                              -- 獲得従業員が未設定エラー
                    ,iv_token_name1  => cv_account_tkn                                              -- 顧客コードトークン名
                    ,iv_token_value1 => set_new_point_rec.account_number                            -- 顧客コード
                   );
          RAISE global_skip_expt;
        END IF;
        -- ========================================
        -- 獲得営業員の処理を行なう
        -- ========================================
        -- ==============================================================
        -- A-7.ワークテーブルデータチェック処理（獲得営業員の確定状態）
        -- ==============================================================
        BEGIN
          SELECT xwncge.decision_flg                                                                -- 確定フラグ
            INTO lt_decision_flg_get
            FROM xxcsm_wk_new_cust_get_emp xwncge                                                   -- 顧客獲得従業員ワークテーブル
           WHERE xwncge.subject_year = it_year                                                      -- 対象年度
             AND xwncge.account_number = set_new_point_rec.account_number                           -- 顧客コード
             AND xwncge.employee_number = set_new_point_rec.cnvs_business_person                    -- 獲得営業員コード
             AND xwncge.get_intro_kbn = cv_get                                                      -- 獲得営業員のみ
          ;
          lv_cust_work_flg := cv_cust_work_ari;                                                     -- 顧客獲得時ワークあり
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_decision_flg_get := cv_mikakutei;                                                    -- 獲得者未確定
            lv_cust_work_flg := cv_cust_work_nasi;                                                  -- 顧客獲得時ワークなし
        END; 
        -- 獲得営業員が未確定(ワークテーブル無しor未確定状態)ならば、処理を実行する。
        IF  (lt_decision_flg_get = cv_mikakutei) THEN
          -- ==============================================================
          -- A-8.ワークテーブルデータ作成／更新処理
          -- ==============================================================
          make_work_table(
            it_get_intro_kbn    => cv_get                                                           -- 獲得紹介区分
           ,it_year             => it_year                                                          -- 対象年度             
           ,it_account_number   => set_new_point_rec.account_number                                 -- 顧客コード
           ,it_employee_number  => set_new_point_rec.cnvs_business_person                           -- 従業員コード  
           ,it_cnvs_date    => set_new_point_rec.cnvs_date                                          -- 顧客獲得日
           ,it_business_low_type => set_new_point_rec.business_low_type                             -- 業態（小分類）コード
           ,iv_cust_work_flg    => lv_cust_work_flg                                                 -- 顧客獲得時ワーク有無フラグ
           ,ov_errbuf           => lv_errbuf                                                        -- エラー・メッセージ            
           ,ov_retcode          => lv_retcode                                                       -- リターン・コード              
           ,ov_errmsg           => lv_errmsg                                                        -- ユーザー・エラー・メッセージ  
          );
          -- エラーならば、顧客単位で処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--          IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
          IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
            RAISE global_skip_expt;                                                                 -- 次の顧客へ
          END IF;
        END IF;
        -- 紹介従業員が登録されていた場合、紹介従業員の処理を行う。
        IF (gv_intro_umu_flg = cv_intro_ari) THEN
          -- ========================================
          -- 紹介従業員の処理を行う。
          -- ========================================
          -- ==============================================================
          -- A-7.ワークテーブルデータチェック処理（紹介従業員の確定状態）
          -- ==============================================================
          BEGIN
            SELECT xwncge.decision_flg                                                              -- 確定フラグ
              INTO lt_decision_flg_intro
              FROM xxcsm_wk_new_cust_get_emp xwncge                                                 -- 顧客獲得従業員ワークテーブル
             WHERE xwncge.subject_year = it_year                                                    -- 対象年度
               AND xwncge.account_number = set_new_point_rec.account_number                         -- 顧客コード
               AND xwncge.employee_number = set_new_point_rec.intro_business_person                 -- 紹介従業コード
               AND xwncge.get_intro_kbn = cv_intro                                                  -- 紹介従業コードのみ
            ;
            lv_cust_work_flg := cv_cust_work_ari;                                                   -- 顧客獲得時ワークあり
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_decision_flg_intro := cv_mikakutei;                                                -- 紹介者未確定
              lv_cust_work_flg := cv_cust_work_nasi;                                                -- 顧客獲得時ワークなし
          END;
          -- 紹介従業員が未確定ならば、処理を実行する。
          IF  (lt_decision_flg_intro = cv_mikakutei) THEN
            -- ==============================================================
            -- A-8.ワークテーブルデータ作成／更新処理
            -- ==============================================================
            make_work_table(
              it_get_intro_kbn => cv_intro                                                          -- 獲得紹介区分
             ,it_year => it_year                                                                    -- 対象年度             
             ,it_account_number => set_new_point_rec.account_number                                 -- 顧客コード
             ,it_employee_number => set_new_point_rec.intro_business_person                         -- 紹介従業員コード  
             ,it_cnvs_date => set_new_point_rec.cnvs_date                                           -- 顧客獲得日
             ,it_business_low_type => set_new_point_rec.business_low_type                           -- 業態（小分類）コード
             ,iv_cust_work_flg => lv_cust_work_flg                                                  -- 顧客獲得時ワーク有無フラグ
             ,ov_errbuf  => lv_errbuf                                                               -- エラー・メッセージ            
             ,ov_retcode => lv_retcode                                                              -- リターン・コード              
             ,ov_errmsg  => lv_errmsg                                                               -- ユーザー・エラー・メッセージ  
            );
            -- エラーならば、顧客単位で処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki            
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--          IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
          IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;                                                               -- 次の顧客へ
            END IF;
          END IF;                                                                                   -- 紹介従業員が未確定の場合の終了
--
        END IF;                                                                                     -- 紹介従業員ありの場合の終了
--//+ADD START 2009/08/17 0000870 T.Tsukino
        -- 獲得営業員が確定の場合のみ処理を行う。
        IF (lt_decision_flg_get = cv_kakutei) THEN
          -- ========================================
          -- A-9 ポイント付与判定取得処理
          -- ========================================
          -- 1.初回取引日から新規獲得ポイント最低取引期間内に中止顧客なった場合、ポイント付与しない。
          IF (set_new_point_rec.duns_number_c = cv_sts_stop )                                       -- 中止顧客の場合
            AND (TRUNC(set_new_point_rec.stop_approval_date)
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
          -- 1.顧客獲得日から新規獲得ポイント最低取引期間内に中止顧客になった場合、ポイント付与しない。（初回取引日は使用しない）
--              <=  TRUNC(set_new_point_rec.start_tran_date
              <=  TRUNC(set_new_point_rec.cnvs_date
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
                     + TO_NUMBER(gv_min_deal_period))) 
          THEN
            lt_decision_flg_upd := cv_kakutei;                                                      -- 確定フラグを確定とする。
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--            lt_evaluration_kbn  := cv_grant_ng;                                                     -- ポイント付与しない
            lt_evaluration_kbn  := cv_grant_ng_stp;                                                 -- ポイント付与しない(中止顧客)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
            -- ========================================
            -- A-11 ワークテープル確定フラグ／新規評価対象区分更新処理  獲得営業員／紹介従業員の両方を更新する。
            -- ========================================
            update_work_table(
              it_year => it_year                                                                    -- 対象年度
             ,it_account_number => set_new_point_rec.account_number                                 -- 顧客コード
             ,it_decision_flg => lt_decision_flg_upd                                                -- 更新用確定フラグ
             ,it_evaluration_kbn => lt_evaluration_kbn                                              -- 新規評価対象区分
             ,ov_errbuf  => lv_errbuf                                                               -- エラー・メッセージ
             ,ov_retcode => lv_retcode                                                              -- リターン・コード
             ,ov_errmsg  => lv_errmsg                                                               -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、顧客単位で処理をスキップする。
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD START  2010/04/19 E_本稼動_01895 S.Karikomi
          ELSIF (set_new_point_rec.duns_number_c = cv_sts_stop )                                    -- 中止顧客の場合
          -- 2.顧客獲得日から新規獲得ポイント最低取引期間外に中止顧客になり、中止理由が'9'(二重登録)である場合、ポイント付与しない(未達)。
            AND (TRUNC(set_new_point_rec.stop_approval_date)
              >  TRUNC(set_new_point_rec.cnvs_date + TO_NUMBER(gv_min_deal_period))) 
            AND (set_new_point_rec.stop_approval_reason = '9')
          THEN
            lt_decision_flg_upd := cv_kakutei;                                                      -- 確定フラグを確定とする。
            lt_evaluration_kbn  := cv_grant_ng_yet;                                                 -- ポイント付与しない(未達)
            -- ========================================
            -- A-11 ワークテープル確定フラグ／新規評価対象区分更新処理  獲得営業員／紹介従業員の両方を更新する。
            -- ========================================
            update_work_table(
              it_year => it_year                                                                    -- 対象年度
             ,it_account_number => set_new_point_rec.account_number                                 -- 顧客コード
             ,it_decision_flg => lt_decision_flg_upd                                                -- 更新用確定フラグ
             ,it_evaluration_kbn => lt_evaluration_kbn                                              -- 新規評価対象区分
             ,ov_errbuf  => lv_errbuf                                                               -- エラー・メッセージ
             ,ov_retcode => lv_retcode                                                              -- リターン・コード
             ,ov_errmsg  => lv_errmsg                                                               -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、顧客単位で処理をスキップする。
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END  2010/04/19 E_本稼動_01895 S.Karikomi
          END IF;
        END IF;
--//+ADD END   2009/08/17 0000870 T.Tsukino
        -- 獲得営業員が未確定の場合のみ処理を行う。
        IF (lt_decision_flg_get = cv_mikakutei) THEN
          -- ========================================
          -- A-9 ポイント付与判定取得処理
          -- ========================================
          -- 1.初回取引日から新規獲得ポイント最低取引期間内に中止顧客なった場合、ポイント付与しない。
          IF (set_new_point_rec.duns_number_c = cv_sts_stop )                                       -- 中止顧客の場合
--//+UPD START 2009/07/30 0000870 T.Tsukino
--            AND (TRUNC(set_new_point_rec.stop_approval_date) < TRUNC(set_new_point_rec.start_tran_date + 90 )) THEN -- 90日以内に中止顧客となった。
            AND (TRUNC(set_new_point_rec.stop_approval_date)
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--              <=  TRUNC(set_new_point_rec.start_tran_date
          -- 1.顧客獲得日から新規獲得ポイント最低取引期間内に中止顧客になった場合、ポイント付与しない。（初回取引日は使用しない）
              <=  TRUNC(set_new_point_rec.cnvs_date
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
                     + TO_NUMBER(gv_min_deal_period))) 
          THEN
--//+UPD END   2009/07/30 0000870 T.Tsukino
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--            lt_evaluration_kbn  := cv_grant_ng;                                                     -- ポイント付与しない
            lt_evaluration_kbn  := cv_grant_ng_stp;                                                 -- ポイント付与しない(中止顧客)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
          ELSE
          -- 2.ポイント付与条件取得
            BEGIN
              -- ユニークキーでの問い合わせのため、複数件取得エラーは発生しない。
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--              SELECT  xmgp.custom_condition_cd              custom_condition_cd                     -- 顧客業態コード
--                     ,xmgp.grant_condition_point            grant_condition_point                   -- ポイント付与条件
--                     ,xmgp.post_cd                          post_cd                                 -- 部署コード
--                     ,xmgp.duties_cd                        duties_cd                               -- 職務コード
--                     ,xmgp.grant_point_target_1st_month     target_1st_month                        -- ポイント付与条件対象月_当月
--                     ,xmgp.grant_point_target_2nd_month     target_2nd_month                        -- ポイント付与条件対象月_翌月
--                     ,xmgp.grant_point_target_3rd_month     target_3rd_month                        -- ポイント付与条件対象月_翌々月
--                     ,xmgp.grant_point_condition_price      condition_price                         -- ポイント付与条件金額
--                INTO
--                      lt_custom_condition_cd
--                     ,lt_grant_condition_point
--                     ,lt_post_cd
--                     ,lt_duties_cd
--                     ,lt_1st_month
--                     ,lt_2nd_month
--                     ,lt_3rd_month
--                     ,lt_price
--                FROM  xxcsm_mst_grant_point xmgp                                                    -- ポイント付与条件マスタ
--                     ,xxcsm_wk_new_cust_get_emp xwncge                                              -- 顧客獲得従業員ワークテーブル
--               WHERE xmgp.subject_year = xwncge.subject_year                                        -- 対象年度
--                 AND xmgp.post_cd      = xwncge.post_cd                                             -- 部署コード
--                 AND xmgp.duties_cd    = xwncge.duties_cd                                           -- 職務
--                 AND xmgp.custom_condition_cd = xwncge.custom_condition_cd                          -- 顧客業態コード
--                 AND xwncge.account_number = set_new_point_rec.account_number                       -- 顧客コード
--                 AND xwncge.get_intro_kbn  = cv_get                                                 -- 獲得紹介区分
--                 AND xwncge.employee_number = set_new_point_rec.cnvs_business_person                -- 獲得営業員
--                 AND xwncge.subject_year = it_year                                                  -- 対象年度
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
              OPEN grant_condition_point_cur(
                set_new_point_rec.account_number
               ,set_new_point_rec.cnvs_business_person 
               ,it_year
              );
              <<grant_condition_point_loop>>
              LOOP
                FETCH grant_condition_point_cur INTO grant_condition_point_rec;
                EXIT WHEN grant_condition_point_cur%NOTFOUND;
                  lt_price                 := grant_condition_point_rec.condition_price;            -- ポイント付与条件金額
                  lt_custom_condition_cd   := grant_condition_point_rec.custom_condition_cd;        -- 顧客業態コード
                  lt_grant_condition_point := grant_condition_point_rec.grant_condition_point;      -- ポイント付与条件
                  lt_post_cd               := grant_condition_point_rec.post_cd;                    -- 部署コード
                  lt_duties_cd             := grant_condition_point_rec.duties_cd;                  -- 職務コード
                  lt_1st_month             := grant_condition_point_rec.target_1st_month;           -- ポイント付与条件対象月_当月
                  lt_2nd_month             := grant_condition_point_rec.target_2nd_month;           -- ポイント付与条件対象月_翌月
                  lt_3rd_month             := grant_condition_point_rec.target_3rd_month;           -- ポイント付与条件対象月_翌々月
                  IF ( grant_condition_point_cur%ROWCOUNT = 1 ) THEN                                -- １件目取得時
                    lt_min_price                 := lt_price;                                         -- ポイント付与条件最低金額更新
                    lt_min_grant_condition_point := grant_condition_point_rec.grant_condition_point;  -- ポイント付与条件(最低金額時)
                    lt_min_1st_month             := grant_condition_point_rec.target_1st_month;       -- ポイント付与条件対象月_当月(最低金額時)
                    lt_min_2nd_month             := grant_condition_point_rec.target_2nd_month;       -- ポイント付与条件対象月_翌月(最低金額時)
                    lt_min_3rd_month             := grant_condition_point_rec.target_3rd_month;       -- ポイント付与条件対象月_翌々月(最低金額時)
                    lv_point_cond_flg            := cv_point_cond_ari;                                -- ポイント条件あり
                  ELSIF ( grant_condition_point_cur%ROWCOUNT = 2 ) THEN                             -- ２件目取得時
                    IF ( lt_min_price > lt_price ) THEN                                             -- 最低金額＞取得金額
                    --==============================================================
                    --金額でソートしている為、取得金額が最低金額を下回ることは想定外
                    --==============================================================
                      lt_max_price                 := lt_min_price;                                 -- ポイント付与条件最高金額更新
                      lt_max_grant_condition_point := lt_min_grant_condition_point;                 -- ポイント付与条件(最高金額時)
                      lt_max_1st_month             := lt_min_1st_month;                             -- ポイント付与条件対象月_当月(最高金額時)
                      lt_max_2nd_month             := lt_min_2nd_month;                             -- ポイント付与条件対象月_翌月(最高金額時)
                      lt_max_3rd_month             := lt_min_3rd_month;                             -- ポイント付与条件対象月_翌々月(最高金額時)
                      lt_min_price                 := lt_price;                                     -- ポイント付与条件最低金額更新
                      lt_min_grant_condition_point := lt_grant_condition_point;                     -- ポイント付与条件(最低金額時)
                      lt_min_1st_month             := lt_1st_month;                                 -- ポイント付与条件対象月_当月(最低金額時)
                      lt_min_2nd_month             := lt_2nd_month;                                 -- ポイント付与条件対象月_翌月(最低金額時)
                      lt_min_3rd_month             := lt_3rd_month;                                 -- ポイント付与条件対象月_翌々月(最低金額時)
                    ELSIF ( lt_min_price < lt_price ) THEN                                          -- 最低金額＜取得金額
                      lt_max_price                 := lt_price;                                     -- ポイント付与条件最高金額更新
                      lt_max_grant_condition_point := lt_grant_condition_point;                     -- ポイント付与条件(最高金額時)
                      lt_max_1st_month             := lt_1st_month;                                 -- ポイント付与条件対象月_当月(最高金額時)
                      lt_max_2nd_month             := lt_2nd_month;                                 -- ポイント付与条件対象月_翌月(最高金額時)
                      lt_max_3rd_month             := lt_3rd_month;                                 -- ポイント付与条件対象月_翌々月(最高金額時)
                    ELSE                                                                            -- ポイント付与条件金額が重複した場合
                      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_appl_short_name_csm                       -- アプリケーション短縮名
                                   ,iv_name         => cv_msg_10159                                 -- ポイント付与条件金額重複エラー
                                   ,iv_token_name1  => cv_account_tkn                               -- 顧客コードトークン名
                                   ,iv_token_value1 => set_new_point_rec.account_number             -- 顧客コード
                                   );
                      RAISE repeat_price_expt;                                                      -- ポイント付与条件金額重複例外
                    END IF;
                  ELSE                                                                              -- ３件目以降
                    IF ( lt_min_price > lt_price ) THEN                                             -- 最低金額＞取得金額
                    --==============================================================
                    --金額でソートしている為、取得金額が最低金額を下回ることは想定外
                    --==============================================================
                      lt_min_price                 := lt_price;                                     -- ポイント付与条件最低金額更新
                      lt_min_grant_condition_point := lt_grant_condition_point;                     -- ポイント付与条件(最低金額時)
                      lt_min_1st_month             := lt_1st_month;                                 -- ポイント付与条件対象月_当月(最低金額時)
                      lt_min_2nd_month             := lt_2nd_month;                                 -- ポイント付与条件対象月_翌月(最低金額時)
                      lt_min_3rd_month             := lt_3rd_month;                                 -- ポイント付与条件対象月_翌々月(最低金額時)
                    ELSIF ( lt_max_price < lt_price ) THEN                                          -- 最低金額＜取得金額
                      lt_max_price                 := lt_price;                                     -- ポイント付与条件最高金額更新
                      lt_max_grant_condition_point := lt_grant_condition_point;                     -- ポイント付与条件(最高金額時)
                      lt_max_1st_month             := lt_1st_month;                                 -- ポイント付与条件対象月_当月(最高金額時)
                      lt_max_2nd_month             := lt_2nd_month;                                 -- ポイント付与条件対象月_翌月(最高金額時)
                      lt_max_3rd_month             := lt_3rd_month;                                 -- ポイント付与条件対象月_翌々月(最高金額時)
                    ELSE                                                                            -- ポイント付与条件金額が重複した場合
                      lv_errmsg := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_appl_short_name_csm                       -- アプリケーション短縮名
                                   ,iv_name         => cv_msg_10159                                 -- ポイント付与条件金額重複エラー
                                   ,iv_token_name1  => cv_account_tkn                               -- 顧客コードトークン名
                                   ,iv_token_value1 => set_new_point_rec.account_number             -- 顧客コード
                                   );
                      RAISE repeat_price_expt;                                                      -- ポイント付与条件金額重複例外
                    END IF;
                  END IF;
              END LOOP grant_condition_point_loop;
              IF ( grant_condition_point_cur%ROWCOUNT = 0 ) THEN                                    -- 1件も取得できなかった場合
                IF (grant_condition_point_cur%ISOPEN) THEN
                  CLOSE grant_condition_point_cur;
                END IF;
                RAISE NO_DATA_FOUND;
              END IF;
              CLOSE grant_condition_point_cur;
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lt_evaluration_kbn := cv_grant_ok;                                                  -- ポイント付与
                lv_point_cond_flg := cv_point_cond_nasi;                                            -- ポイント条件なし
--//+ADD START  2010/01/19 E_本稼動_01039 S.Karikomi
              WHEN repeat_price_expt THEN
                IF (grant_condition_point_cur%ISOPEN) THEN
                  CLOSE grant_condition_point_cur;
                END IF;
                RAISE global_skip_expt;                                                             -- 顧客単位スキップ例外へ
--//+ADD END  2010/01/19 E_本稼動_01039 S.Karikomi
            END;
            IF  (lv_point_cond_flg = cv_point_cond_ari) THEN                                        -- ポイント条件あり
              --ポイント付与条件最終対象月のAR会計期間がクローズされていない場合、見込みで付与します。 
              -- 初回取引月と条件より最終月＝初回取引月＋月数となる月数を取得する。
              IF lt_3rd_month = cv_chk_on THEN                                                      -- 翌々月が最終月の場合
                ln_add_mm := 2;
              ELSIF lt_2nd_month = cv_chk_on THEN                                                   -- 翌月が最終月の場合
                ln_add_mm := 1;
              ELSIF lt_1st_month = cv_chk_on THEN                                                   -- 当月が最終月の場合
                ln_add_mm := 0;
              END IF;
              -- 最終月がクローズされていないことを判定
              SELECT COUNT(1)
                INTO ln_dummy
                FROM gl_period_statuses gps                                                         -- 会計期間ステータス
               WHERE gps.application_id   = gt_ar_appl_id                                           -- アプリケーションID
                 AND gps.set_of_books_id  = gt_set_of_bks_id                                        -- 会計帳簿ID
--//+UPD START 2009/04/27 T1_0713 M.Ohtsuki
--                 AND gps.closing_status  NOT IN ( cv_closing_status_c,cv_closing_status_p)          -- クローズでない
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                 AND (gps.closing_status = cv_closing_status_o                                      -- オープン
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--                    OR TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),ln_add_mm),'YYYYMM')
                    OR TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),ln_add_mm),'YYYYMM')
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
                    >= TO_CHAR(gd_process_date,'YYYYMM'))                                           -- 未来日
                 AND gps.adjustment_period_flag = cv_flg_n                                          -- 通常の会計期間
--//+UPD END   2009/04/27 T1_0713 M.Ohtsuki
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--                 AND TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),ln_add_mm),'YYYYMM') = TO_CHAR(gps.start_date,'YYYYMM')
                 AND TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),ln_add_mm),'YYYYMM') = TO_CHAR(gps.start_date,'YYYYMM')
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
                ;
              IF ln_dummy >= 1 THEN
                lt_evaluration_kbn := cv_grant_ok;                                                  -- ポイント付与
                lv_chk_jisseki_flg := cv_jisseki_chk_fuyo;                                          -- 見込みで付与（実績判定なし）
              ELSE
                lv_chk_jisseki_flg := cv_jisseki_chk_yo;                                            -- 実績判定へ
              END IF;
              -- 販売実績を基に実績判定を行います。
              IF (lv_chk_jisseki_flg = cv_jisseki_chk_yo)  THEN                                     -- 実績判定
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                -- 当月販売実績の取得
--                IF (lt_1st_month = cv_chk_on) THEN                                                  -- 当月が対象月ならば
--                  OPEN set_month_amount_cur(
--                     set_new_point_rec.account_number
----//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
----                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),0)
----↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--                   ,  ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),0)
----//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
--                  );
--                  FETCH set_month_amount_cur INTO set_month_amount_rec;
--                  IF set_month_amount_cur%NOTFOUND THEN
--                    lt_amount_1st := 0;                                                             -- 当月実績額
--                  ELSE
--                    lt_amount_1st := set_month_amount_rec.amount; 
--                  END IF;
--                  CLOSE set_month_amount_cur;
--                END IF;
--                -- 翌月販売実績の取得
--                IF (lt_2nd_month = cv_chk_on) THEN                                                   -- 翌月が対象月ならば
--                  OPEN set_month_amount_cur(
--                     set_new_point_rec.account_number
----//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
----↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
----                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),1)
--                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),1)
----//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
--                  );
--                  FETCH set_month_amount_cur INTO set_month_amount_rec;
--                  IF set_month_amount_cur%NOTFOUND THEN
--                    lt_amount_2nd := 0;                                                              -- 翌月実績額
--                  ELSE
--                    lt_amount_2nd := set_month_amount_rec.amount;
--                  END IF;
--                  CLOSE set_month_amount_cur;
--                END IF;
--                -- 翌々月販売実績の取得
--                IF (lt_3rd_month = cv_chk_on) THEN                                                   -- 翌々月が対象月ならば
--                  OPEN set_month_amount_cur(
--                     set_new_point_rec.account_number
----//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
----↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
----                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),2)
--                  ,  ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),2)
----//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
--                  );
--                  FETCH set_month_amount_cur INTO set_month_amount_rec;
--                  IF set_month_amount_cur%NOTFOUND THEN
--                    lt_amount_3rd := 0;                                                             -- 翌々月実績額
--                  ELSE
--                    lt_amount_3rd := set_month_amount_rec.amount; 
--                  END IF;
--                  CLOSE set_month_amount_cur;
--                END IF;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                  -- 各月の販売実績を取得
                  OPEN set_month_amount_cur(
                    set_new_point_rec.account_number
                   ,ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),0)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_1st := 0;                                                             -- 当月実績額
                  ELSE
                    lt_amount_1st := set_month_amount_rec.amount;
                  END IF;
                  CLOSE set_month_amount_cur;
                  OPEN set_month_amount_cur(
                    set_new_point_rec.account_number
                   ,ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),1)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_2nd := 0;                                                             -- 翌月実績額
                  ELSE
                    lt_amount_2nd := set_month_amount_rec.amount;
                  END IF;
                  CLOSE set_month_amount_cur;
                  OPEN set_month_amount_cur(
                    set_new_point_rec.account_number
                   ,ADD_MONTHS(TRUNC(set_new_point_rec.cnvs_date,'MM'),2)
                  );
                  FETCH set_month_amount_cur INTO set_month_amount_rec;
                  IF set_month_amount_cur%NOTFOUND THEN
                    lt_amount_3rd := 0;                                                             -- 翌々月実績額
                  ELSE
                    lt_amount_3rd := set_month_amount_rec.amount;
                  END IF;
                  CLOSE set_month_amount_cur;
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                -- ポイント付与条件に対応した判定を行います。
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                IF ( lt_grant_condition_point = cv_cond_all ) THEN                                  -- 対象月全てが条件金額以上
--                  IF    ( lt_1st_month != cv_chk_on                                                 -- 当月が対象月でないか
--                          OR ( (lt_1st_month = cv_chk_on )                                          -- 当月が対象月で
--                                AND (lt_price <= lt_amount_1st)                                     -- 当月実績が条件を満たす場合
--                             )
--                        )
--                    AND ( lt_2nd_month != cv_chk_on                                                 -- 翌月が対象月でないか
--                          OR ( (lt_2nd_month = cv_chk_on )                                          -- 翌月が対象月で
--                                AND (lt_price <= lt_amount_2nd)                                     -- 翌月実績が条件を満たす場合
--                             )
--                        )
--                    AND ( lt_3rd_month != cv_chk_on                                                 -- 翌々月が対象月でないか
--                          OR ( (lt_3rd_month = cv_chk_on )                                          -- 翌々月が対象月で
--                                AND (lt_price <= lt_amount_3rd)                                     -- 翌々月実績が条件を満たす場合
--                             )
--                        )
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                IF ( lt_min_grant_condition_point = cv_cond_all ) THEN                              -- 対象月全てが条件金額以上
                  IF ( lt_min_1st_month != cv_chk_on                                                -- 当月が対象月でないか
                       OR ( ( lt_min_1st_month = cv_chk_on )                                        -- 当月が対象月で
                            AND ( lt_min_price <= lt_amount_1st )                                   -- 当月実績が条件を満たす場合
                          )
                     )
                  AND ( lt_min_2nd_month != cv_chk_on                                               -- 翌月が対象月でないか
                        OR ( ( lt_min_2nd_month = cv_chk_on )                                       -- 翌月が対象月で
                             AND (lt_min_price <= lt_amount_2nd)                                    -- 翌月実績が条件を満たす場合
                           )
                      )
                  AND ( lt_min_3rd_month != cv_chk_on                                               -- 翌々月が対象月でないか
                        OR ( ( lt_min_3rd_month = cv_chk_on )                                       -- 翌々月が対象月で
                             AND (lt_min_price <= lt_amount_3rd)                                    -- 翌々月実績が条件を満たす場合
                           )
                      )
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                  THEN
                    lt_evaluration_kbn := cv_grant_ok;                                              -- ポイント付与
                  ELSE
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                    lt_evaluration_kbn := cv_grant_ng;                                              -- ポイント付与しない
                    lt_evaluration_kbn := cv_grant_ng_yet;                                          -- ポイント付与しない(未達)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                  END IF;
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                ELSIF ( lt_grant_condition_point = cv_cond_any ) THEN                               -- 対象月のどれかが条件金額以上
--                  IF   (  (lt_1st_month = cv_chk_on )                                               -- 当月が対象月で
--                        AND (lt_price <= lt_amount_1st)                                             -- 当月実績が条件を満たす場合
--                       )
--                    OR ( (lt_2nd_month = cv_chk_on )                                                -- 翌月が対象月で
--                        AND (lt_price <= lt_amount_2nd)                                             -- 翌月実績が条件を満たす場合
--                       )
--                    OR ( (lt_3rd_month = cv_chk_on )                                                -- 翌々月が対象月
--                        AND (lt_price <= lt_amount_3rd)                                             -- 翌々月実績が条件を満たす場合
--                       )
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                ELSIF ( lt_min_grant_condition_point = cv_cond_any ) THEN                           -- 対象月のどれかが条件金額以上
                     IF ( ( lt_min_1st_month = cv_chk_on )                                          -- 当月が対象月で
                          AND ( lt_min_price <= lt_amount_1st )                                     -- 当月実績が条件を満たす場合
                        )
                     OR ( ( lt_min_2nd_month = cv_chk_on )                                          -- 翌月が対象月で
                          AND ( lt_min_price <= lt_amount_2nd )                                     -- 翌月実績が条件を満たす場合
                        )
                     OR ( ( lt_min_3rd_month = cv_chk_on )                                          -- 翌々月が対象月
                          AND ( lt_min_price <= lt_amount_3rd )                                     -- 翌々月実績が条件を満たす場合
                        )
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                     THEN
                       lt_evaluration_kbn := cv_grant_ok;                                           -- ポイント付与
                     ELSE
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                    lt_evaluration_kbn := cv_grant_ng;                                              -- ポイント付与しない
                    lt_evaluration_kbn := cv_grant_ng_yet;                                          -- ポイント付与しない(未達)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                  END IF;
                ELSIF ( lt_min_grant_condition_point = cv_cond_sum ) THEN                               -- 対象月合計が条件金額以上
                  --対象月のみ販売実績を集計しているため、全てを合計することで対象月の合計が算出される。
                  lt_amount_all := lt_amount_1st + lt_amount_2nd + lt_amount_3rd;
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                  IF (lt_price <= lt_amount_all) THEN                                               -- 合計金額が条件を満たした場合
                  IF ( lt_min_price <= lt_amount_all ) THEN                                         -- 合計金額が条件を満たした場合
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                    lt_evaluration_kbn := cv_grant_ok;                                              -- ポイント付与
                  ELSE
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--                    lt_evaluration_kbn := cv_grant_ng;                                              -- ポイント付与しない
                    lt_evaluration_kbn := cv_grant_ng_yet;                                          -- ポイント付与しない(未達)
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
                  END IF;
                END IF;                                                                             -- ポイント付与条件別の終了
--//+ADD START  2010/01/19 E_本稼動_01039 S.Karikomi
                IF ( lt_evaluration_kbn = cv_grant_ok )                                             -- ポイント付与の場合
                     AND ( lt_max_price IS NOT NULL )                                               -- ポイント付与条件最高金額あり
                THEN
                  IF ( lt_max_grant_condition_point = cv_cond_all ) THEN                            -- 対象月全てが条件金額以上
                    IF ( lt_max_1st_month != cv_chk_on                                              -- 当月が対象月でないか
                       OR ( ( lt_max_1st_month = cv_chk_on )                                        -- 当月が対象月で
                            AND ( lt_amount_1st >= lt_max_price )                                   -- 当月実績がポイント付与条件最高金額より大きい場合
                          )
                       )
                    AND ( lt_max_2nd_month != cv_chk_on                                             -- 翌月が対象月でないか
                        OR ( ( lt_max_2nd_month = cv_chk_on )                                       -- 翌月が対象月で
                             AND ( lt_amount_2nd >= lt_max_price )                                  -- 翌月実績がポイント付与条件最高金額より大きい場合
                           )
                        )
                    AND ( lt_max_3rd_month != cv_chk_on                                             -- 翌々月が対象月でないか
                        OR ( ( lt_max_3rd_month = cv_chk_on )                                       -- 翌々月が対象月で
                             AND ( lt_amount_3rd >= lt_max_price )                                  -- 翌々月実績がポイント付与条件最高金額より大きい場合
                           )
                        )
                    THEN
                      lv_point_double_flg := cv_point_double_ok;                                    -- 獲得ポイントを２倍
                      lt_evaluration_kbn := cv_grant_ok_dbl;                                        -- ポイント付与(２倍)
                    END IF;
                  ELSIF ( lt_max_grant_condition_point = cv_cond_any ) THEN                         -- 対象月のどれかが条件金額以上                  THEN
                    IF ( ( lt_max_1st_month = cv_chk_on )                                           -- 当月が対象月で
                         AND ( lt_amount_1st >= lt_max_price )                                      -- 当月実績がポイント付与条件最高金額より大きい場合
                       )
                    OR ( ( lt_max_2nd_month = cv_chk_on )                                           -- 翌月が対象月で
                         AND ( lt_amount_2nd >= lt_max_price )                                      -- 翌月実績がポイント付与条件最高金額より大きい場合
                       )
                    OR ( ( lt_max_3rd_month = cv_chk_on )                                           -- 翌々月が対象月
                         AND ( lt_amount_3rd >= lt_max_price )                                      -- 当月実績がポイント付与条件最高金額より大きい場合
                       )
                    THEN
                      lv_point_double_flg := cv_point_double_ok;                                    -- 獲得ポイントを２倍
                      lt_evaluration_kbn := cv_grant_ok_dbl;                                        -- ポイント付与(２倍)
                    END IF;
                  ELSIF ( lt_max_grant_condition_point = cv_cond_sum ) THEN                         -- 対象月合計が条件金額以上
                    --対象月のみ販売実績を集計しているため、全てを合計することで対象月の合計が算出される。
                    lt_amount_all := lt_amount_1st + lt_amount_2nd + lt_amount_3rd;
                    IF ( lt_amount_all >= lt_max_price ) THEN                                       -- 当月実績がポイント付与条件最高金額より大きい場合
                      lv_point_double_flg := cv_point_double_ok;                                    -- 獲得ポイントを２倍
                      lt_evaluration_kbn := cv_grant_ok_dbl;                                        -- ポイント付与(２倍)
                    END IF;
                  END IF;
                END IF;                                                                             -- ポイント２倍条件判定の終了
--//+ADD END  2010/01/19 E_本稼動_01039 S.Karikomi
              END IF;                                                                               -- 実績判定要の終了
            END IF;                                                                                 -- ポイント付与条件ありの終了        
          END IF;                                                                                   -- 中止顧客でないの終了
          -- ========================================
          -- A-10 ポイント情報確定判定処理
          -- ========================================
          IF  (lv_point_cond_flg = cv_point_cond_ari) THEN                                          -- ポイント条件あり
            IF (lv_chk_jisseki_flg = cv_jisseki_chk_yo) THEN                                        -- 実績判定を行なった場合
               lt_decision_flg_upd := cv_kakutei;                                                   -- 確定フラグを確定とする。
            ELSE
               lt_decision_flg_upd := cv_mikakutei;                                                 -- 確定フラグを未確定とする。
            END IF;            
          ELSE
--//+UPD START 2009/04/22 T1_0713 M.Ohtsuki
--            -- ポイント条件無しで、初回取引日から3ヵ月後の会計期間がクローズしているか判定
--            SELECT COUNT(1)
--              INTO ln_dummy
--              FROM gl_period_statuses gps                                                           -- 会計期間ステータス
--             WHERE gps.application_id   = gt_ar_appl_id                                             -- アプリケーションID
--               AND gps.set_of_books_id  = gt_set_of_bks_id                                          -- 会計帳簿ID
--               AND gps.closing_status  IN ( cv_closing_status_c,cv_closing_status_p)                -- クローズしている
--               AND TO_CHAR(ADD_MONTHS(TRUNC(set_new_point_rec.start_tran_date,'MM'),2),'YYYYMM') = TO_CHAR(gps.start_date,'YYYYMM')  -- 翌々月の会計年月を判定
--              ;
--            --初回取引日から3ヵ月後の会計期間がクローズしている場合
--            IF (ln_dummy >= 1) THEN
--              lt_decision_flg_upd := cv_kakutei;                                                    -- 確定フラグを確定とする。
--            --初回取引日から3ヵ月後の会計期間がクローズしていない場合
--            ELSE
--              lt_decision_flg_upd := cv_mikakutei;                                                  -- 確定フラグを未確定とする。
--            END IF;
--          END IF;
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            -- ポイント条件なしで、初回取引日が業務日付の3ヶ月前以前に存在し、ステータスがオープン以外か判定
            SELECT COUNT(1)
              INTO ln_dummy
              FROM gl_period_statuses gps                                                           -- 会計期間ステータス
             WHERE gps.application_id   =  gt_ar_appl_id                                            -- アプリケーションID
               AND gps.set_of_books_id  =  gt_set_of_bks_id                                         -- 会計帳簿ID
               AND gps.closing_status   <>  cv_closing_status_o                                     -- オープン
               AND gps.adjustment_period_flag = cv_flg_n                                            -- 通常の会計期間
--//+UPD START  2009/12/07 E_本稼動_00335 T.Tsukino
--↓↓↓↓↓↓↓ 初回取引日による判定を顧客獲得日に変更↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--               AND TO_CHAR(TRUNC(set_new_point_rec.start_tran_date,'MM'),'YYYYMM')
--                   <= TO_CHAR(ADD_MONTHS(gd_process_date,-3),'YYYYMM')                              -- 初回取引日が業務日付の3ヶ月前以前
--               AND TO_CHAR(TRUNC(set_new_point_rec.start_tran_date,'MM'),'YYYYMM')
--                    = TO_CHAR(gps.start_date,'YYYYMM')                                              -- 初回取引日の会計年月を判定
               AND TO_CHAR(TRUNC(set_new_point_rec.cnvs_date,'MM'),'YYYYMM')
                   <= TO_CHAR(ADD_MONTHS(gd_process_date,-3),'YYYYMM')                              -- 初回取引日が業務日付の3ヶ月前以前
               AND TO_CHAR(TRUNC(set_new_point_rec.cnvs_date,'MM'),'YYYYMM')
                    = TO_CHAR(gps.start_date,'YYYYMM')                                              -- 初回取引日の会計年月を判定
--//+UPD END  2009/12/07 E_本稼動_00335 T.Tsukino
            ;
            --初回取引日の会計期間がオープン以外の場合
            IF(ln_dummy >= 1) THEN
              lt_decision_flg_upd := cv_kakutei;                                                    -- 確定フラグを確定とする。
            --初回取引日の会計期間がオープンの場合
            ELSE
              lt_decision_flg_upd := cv_mikakutei;                                                  -- 確定フラグを未確定とする。
            END IF;
          END IF;
--//+UPD END   2009/04/22 T1_0713 M.Ohtsuki
          -- ========================================
          -- A-11 ワークテープル確定フラグ／新規評価対象区分更新処理  獲得営業員／紹介従業員の両方を更新する。
          -- ========================================
          update_work_table(
            it_year => it_year                                                                      -- 対象年度             
           ,it_account_number => set_new_point_rec.account_number                                   -- 顧客コード
           ,it_decision_flg => lt_decision_flg_upd                                                  -- 更新用確定フラグ
           ,it_evaluration_kbn => lt_evaluration_kbn                                                -- 新規評価対象区分
           ,ov_errbuf  => lv_errbuf                                                                 -- エラー・メッセージ            
           ,ov_retcode => lv_retcode                                                                -- リターン・コード              
           ,ov_errmsg  => lv_errmsg                                                                 -- ユーザー・エラー・メッセージ  
          );
          -- エラーならば、顧客単位で処理をスキップする。
          IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- 次の顧客へ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
          END IF;
        END IF;                                                                                     -- 獲得営業員が未確定の終了
        -- ========================================
--//+UPD START  2010/01/19 E_本稼動_01039 S.Karikomi
--        -- A-12 ポイント按分処理
--        -- A-13 新規獲得ポイント顧客別履歴テーブル作成処理
        -- A-12 ポイント２倍処理
        -- A-13 ポイント按分処理
        -- A-14 新規獲得ポイント顧客別履歴テーブル作成処理
--//+UPD END  2010/01/19 E_本稼動_01039 S.Karikomi
        -- ========================================
        -- 新規ポイントの設定
        lt_point := set_new_point_rec.new_point;
--//+ADD START  2010/01/19 E_本稼動_01039 S.Karikomi
        -- 条件を満たした場合ポイントを２倍
        IF ( lv_point_double_flg = cv_point_double_ok ) THEN
          lt_point := lt_point * 2;
        END IF;
--//+ADD END  2010/01/19 E_本稼動_01039 S.Karikomi
        -- 獲得ポイント按分後、紹介者の登録
        IF  (gv_intro_umu_flg = cv_intro_ari) THEN                                                  -- 紹介者ありの場合
          -- 獲得ポイント按分
          lt_point := lt_point / 2;
          -- 紹介者の登録 
          insert_hst_table(
            it_get_intro_kbn => cv_intro                                                            -- 獲得紹介区分
           ,it_year => it_year                                                                      -- 対象年度             
           ,it_account_number => set_new_point_rec.account_number                                   -- 顧客コード
           ,it_employee_number => set_new_point_rec.intro_business_person                           -- 紹介従業員コード  
           ,it_job_type_cd => cv_sales                                                              -- 職種
           ,it_business_low_type => set_new_point_rec.business_low_type                             -- 業態（小分類）コード
           ,it_point => lt_point                                                                    -- 新規ポイント
           ,ov_errbuf  => lv_errbuf                                                                 -- エラー・メッセージ            
           ,ov_retcode => lv_retcode                                                                -- リターン・コード              
           ,ov_errmsg  => lv_errmsg                                                                 -- ユーザー・エラー・メッセージ  
          );
          -- エラーならば、顧客単位で処理をスキップする。
          IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- 次の顧客へ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
          END IF;
        END IF; 
        -- 獲得者の登録 
        insert_hst_table(
          it_get_intro_kbn => cv_get                                                                -- 獲得紹介区分
         ,it_year => it_year                                                                        -- 対象年度             
         ,it_account_number => set_new_point_rec.account_number                                     -- 顧客コード
         ,it_employee_number => set_new_point_rec.cnvs_business_person                              -- 獲得営業員コード  
         ,it_job_type_cd => cv_other                                                                -- 職種(営業職以外)
         ,it_business_low_type => set_new_point_rec.business_low_type                               -- 業態（小分類）コード
         ,it_point => lt_point                                                                      -- 新規ポイント
         ,ov_errbuf  => lv_errbuf                                                                   -- エラー・メッセージ            
         ,ov_retcode => lv_retcode                                                                  -- リターン・コード              
         ,ov_errmsg  => lv_errmsg                                                                   -- ユーザー・エラー・メッセージ  
        );
        -- エラーならば、顧客単位で処理をスキップする。
        IF (lv_retcode <> cv_status_normal) THEN
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            RAISE global_skip_expt;                                                                 -- 次の顧客へ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            RAISE global_process_expt;
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
        END IF;
--
      EXCEPTION
        WHEN  global_skip_expt then                                                                 -- 処理中にエラー発生
        --  エラー件数の加算
          lv_error_flg := cv_error_on;                                                              -- エラーフラグ設定
          fnd_file.put_line(
            which  => FND_FILE.OUTPUT                                                               -- 出力
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          -- 現在の顧客処理をロールバック
          ROLLBACK TO set_new_point;
      END;
--
      IF (lv_error_flg = cv_error_on) THEN
        --  エラー件数の加算
        gn_error_cnt := gn_error_cnt + 1;
      ELSE
        --  成功件数の加算
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;  
      -- 対象件数の加算
      gn_target_cnt := gn_target_cnt + 1;
    END LOOP set_new_point_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (set_month_amount_cur%ISOPEN) THEN
        CLOSE set_month_amount_cur;
      END IF;
      IF (set_new_point_cur%ISOPEN) THEN
        CLOSE set_new_point_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_new_point_loop;
  /**********************************************************************************
   * Procedure Name   : get_ar_period_loop
   * Description      : データ作成対象期間取得 (A-2)
   ***********************************************************************************/
   PROCEDURE get_ar_period_loop(
     ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ar_period_loop';                       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lt_pre_period_year gl_period_statuses.period_year%TYPE;  -- 年度(会計期間名YYYYMM)
    -- *** カーソル定義 ***
    CURSOR ar_open_period_cur
    IS
      SELECT  DISTINCT gps.period_year          period_year  --年度
             ,TO_CHAR(gps.start_date,'YYYYMM')  year_month   --年月
      FROM   gl_period_statuses gps
      WHERE  gps.application_id   = gt_ar_appl_id
      AND    gps.set_of_books_id  = gt_set_of_bks_id
      AND    gps.closing_status   = cv_closing_status_o
      ORDER BY TO_CHAR(gps.start_date,'YYYYMM')
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
    --キー項目の初期化
    lt_pre_period_year := NULL;
    -- ===============================
    -- AR会計期間OPEN年度の処理LOOP 
    -- ===============================
    <<open_period_loop>>
    FOR ar_open_period_rec IN ar_open_period_cur LOOP
--
      --OPENのAR会計期間ログ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm                                    -- アプリケーション短縮名
                      ,iv_name         => cv_open_period_msg                                        -- メッセージコード
                      ,iv_token_name1  => cv_pym_tkn                                                -- YYYYMM
                      ,iv_token_value1 => ar_open_period_rec.year_month                             -- OPEN会計期間年月(YYYYMM)
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG                                                                     -- ログ
        ,buff   => gv_out_msg
      );
--
      -- 年度単位に処理を実施するため、年度切替のタイミングで内部処理を実行
      IF (lt_pre_period_year IS NULL)
        OR (lt_pre_period_year <> ar_open_period_rec.period_year)
      THEN
        --キーブレイク情報の保持（年度単位）
        lt_pre_period_year := ar_open_period_rec.period_year;
--
        -- ===============================
        -- テーブル（レコード単位）のロック処理(A-3)
        -- データ削除処理(A-4)
        -- ===============================
        delete_rec_with_lock(
           it_year    => ar_open_period_rec.period_year                                             -- 対象年度
          ,ov_errbuf  => lv_errbuf                                                                  -- エラー・メッセージ            
          ,ov_retcode => lv_retcode                                                                 -- リターン・コード              
          ,ov_errmsg  => lv_errmsg                                                                  -- ユーザー・エラー・メッセージ  
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        set_new_point_loop(
           it_year    => ar_open_period_rec.period_year                                             -- 対象年度
          ,ov_errbuf  => lv_errbuf                                                                  -- エラー・メッセージ            
          ,ov_retcode => lv_retcode                                                                 -- リターン・コード              
          ,ov_errmsg  => lv_errmsg                                                                  -- ユーザー・エラー・メッセージ  
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP open_period_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (ar_open_period_cur%ISOPEN) THEN
        CLOSE ar_open_period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_period_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';                                  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
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
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ            
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード              
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ  
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    get_ar_period_loop(
       ov_errbuf  => lv_errbuf                                                                      -- エラー・メッセージ            
      ,ov_retcode => lv_retcode                                                                     -- リターン・コード              
      ,ov_errmsg  => lv_errmsg                                                                      -- ユーザー・エラー・メッセージ  
    );
    IF (lv_retcode <> cv_status_normal) THEN    --★警告があるので修正が必要
      RAISE global_process_expt;
    END IF;
    --処理できなかったデータが存在した場合、警告でステータスを戻す。
    IF (gn_error_cnt >= 1) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2                                                              -- エラー・メッセージ  --# 固定 #
    ,retcode       OUT NOCOPY VARCHAR2 )                                                            -- リターン・コード    --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';                                                 -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し(新規獲得ポイント集計処理)
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf                                                                     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode                                                                    -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg                                                                     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    IF lv_retcode = cv_status_error THEN
      IF lv_errmsg IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                 iv_application  => cv_appl_short_name_csm
                                                ,iv_name         => cv_msg_00111                    -- 想定外エラーメッセージ
                                               );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT                                                                  -- 出力
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG                                                                     -- ログ
        ,buff => lv_errbuf --エラーメッセージ
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
    -- =======================
--//+UPD START 2010/01/19 E_本稼動_01039 S.Karikomi
--    -- A-14.終了処理
    -- A-15.終了処理
--//+UPD END 2010/01/19 E_本稼動_01039 S.Karikomi
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_cnt_msg
                    ,iv_token_name1  => cv_cnt_tkn
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT                                                                    -- 出力
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf,1,4000);
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      retcode := cv_status_error;
      ROLLBACK;
--
--###########################  固定部 END   #######################################################
--
  END main;
END XXCSM004A04C;
/
