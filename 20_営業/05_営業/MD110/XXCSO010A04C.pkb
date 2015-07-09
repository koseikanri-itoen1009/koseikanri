CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A04C(body)
 * Description      : 自動販売機設置契約情報登録/更新画面、契約書検索画面から
 *                    自動販売機設置契約書を帳票に出力します。
 * MD.050           : MD050_CSO_010_A04_自動販売機設置契約書PDFファイル作成
 *
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_contract_data      データ取得(A-2)
 *  insert_data            ワークテーブル出力(A-3)
 *  act_svf                SVF起動(A-4)
 *  exec_submit_req        覚書出力要求発行処理(A-5)
 *  func_wait_for_request  コンカレント終了待機処理(A-6)
 *  delete_data            ワークテーブルデータ削除(A-7)
 *  submain                メイン処理プロシージャ
 *                           SVF起動APIエラーチェック(A-8)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-03    1.0   Kichi.Cho        新規作成
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF起動API埋め込み
 *  2009-03-06    1.1   Abe.Daisuke     【課題No71】売価別条件、一律条件・容器別条件の画面入力制御の変更対応
 *  2009-03-13    1.1   Mio.Maruyama    【障害052,055,056】抽出条件変更・テーブルサイズ変更
 *  2009-04-27    1.2   Kazuo.Satomura   システムテスト障害対応(T1_0705,T1_0778)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-09-14    1.4   Mio.Maruyama     0001355対応
 *  2009-10-15    1.5   Daisuke.Abe      0001536,0001537対応
 *  2009-11-12    1.6   Kazuo.Satomura   I_E_658対応
 *  2009-11-30    1.7   T.Maruyama       E_本稼動_00193対応
 *  2010-03-02    1.8   K.Hosoi          E_本稼動_01678対応
 *  2010-08-03    1.9   H.Sasaki         E_本稼動_00822対応
 *  2014-02-03    1.10  S.Niki           E_本稼動_11397対応
 *  2015-02-16    1.11  K.Nakatsu        E_本稼動_12565対応
 *  2015-06-25    1.12  Y.Shoji          E_本稼動_13019対応
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04C';      -- パッケージ名
  cv_app_name           CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
  cv_svf_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04';       -- パッケージ名
  -- メッセージコード
  cv_tkn_number_01      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- パラメータNULLエラー
  cv_tkn_number_02      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00416';  -- 契約書番号
  cv_tkn_number_03      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00413';  -- 自動販売機設置契約書IDチェックエラー
  cv_tkn_number_04      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00414';  -- 自動販売機設置契約書情報取得エラー
  cv_tkn_number_05      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00415';  -- 自動販売機設置契約書情報複数存在エラー
  cv_tkn_number_06      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00417';  -- APIエラーメッセージ
  cv_tkn_number_07      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00418';  -- データ追加エラーメッセージ
  cv_tkn_number_08      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00419';  -- データ削除エラーメッセージ
  cv_tkn_number_09      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- パラメータ出力
  cv_tkn_number_10      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ取得エラー
  cv_tkn_number_11      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ロックエラーメッセージ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  START  */
  cv_tkn_number_12      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00736';  -- 覚書前文固定部取得エラーメッセージ
  cv_tkn_number_13      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00737';  -- 発行元所属長コード取得エラーメッセージ
  cv_tkn_number_14      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00738';  -- 設置協賛金発行元区分取得エラーメッセージ
  cv_tkn_number_15      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_16      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00741';  -- コンカレント名称（設置協賛金）
  cv_tkn_number_17      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00742';  -- コンカレント名称（電気代）
  cv_tkn_number_18      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00743';  -- コンカレント名称（紹介手数料）
  cv_tkn_number_19      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00310';  -- コンカレント起動エラーメッセージ
  cv_tkn_number_20      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00744';  -- コンカレント待機時間経過エラーメッセージ
  cv_tkn_number_21      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00745';  -- コンカレント待機正常メッセージ
  cv_tkn_number_22      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00746';  -- コンカレント待機警告メッセージ
  cv_tkn_number_23      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00747';  -- コンカレント待機エラーメッセージ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END    */
--
  -- トークンコード
  cv_tkn_param_nm       CONSTANT VARCHAR2(30) := 'PARAM_NAME';
  cv_tkn_val            CONSTANT VARCHAR2(30) := 'VALUE';
  cv_tkn_con_mng_id     CONSTANT VARCHAR2(30) := 'CONTRACT_MANAGEMENT_ID';
  cv_tkn_contract_num   CONSTANT VARCHAR2(30) := 'CONTRACT_NUMBER';
  cv_tkn_err_msg        CONSTANT VARCHAR2(30) := 'ERR_MSG';
  cv_tkn_tbl            CONSTANT VARCHAR2(30) := 'TABLE';
  cv_tkn_api_nm         CONSTANT VARCHAR2(30) := 'API_NAME';
  cv_tkn_request_id     CONSTANT VARCHAR2(30) := 'REQUEST_ID';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  START  */
  cv_tkn_prof_name      CONSTANT VARCHAR2(30) := 'PROF_NAME';
  cv_tkn_conc           CONSTANT VARCHAR2(30) := 'CONC';
  cv_tkn_concmsg        CONSTANT VARCHAR2(30) := 'CONCMSG';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END    */
--
  -- 日付書式
  cv_flag_1             CONSTANT VARCHAR2(1)  := '1';             -- 処理A-2-1
  cv_flag_2             CONSTANT VARCHAR2(1)  := '2';             -- 処理A-2-2
  -- 有効
  cv_enabled_flag       CONSTANT VARCHAR2(1)  := 'Y';
  -- アクティブ
  cv_active_status      CONSTANT VARCHAR2(1)  := 'A';
  --
/* 2014/02/03 Ver1.10 S.Niki ADD START */
  -- 最大行数
  cn_max_line           CONSTANT NUMBER       := 17;
/* 2014/02/03 Ver1.10 S.Niki ADD END */
-- == 2010/08/03 V1.9 Added START ===============================================================
  cv_lkup_kozatype      CONSTANT VARCHAR2(30) :=  'XXCSO1_KOZA_TYPE';                 --  参照タイプ：口座種別
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                                --  半角スペース
  cv_msg_xxcso_00470    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00470';                 --  データ取得エラー
  cv_msg_xxcso_00604    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00604';                 --  契約書出力日定型メッセージ
  cv_msg_xxcso_00605    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00605';                 --  販売手数料但書（売価別）メッセージ
  cv_msg_xxcso_00606    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00606';                 --  販売手数料但書（容器別）メッセージ
  cv_tkn_xxcso_00470_01 CONSTANT VARCHAR2(30) :=  'ACTION';                           --  APP-XXCSO1-00470のトークン
  cv_tkn_xxcso_00470_02 CONSTANT VARCHAR2(30) :=  'KEY_NAME';                         --  APP-XXCSO1-00470のトークン
  cv_tkn_xxcso_00470_03 CONSTANT VARCHAR2(30) :=  'KEY_ID';                           --  APP-XXCSO1-00470のトークン
  cv_cnst_message       CONSTANT VARCHAR2(10) :=  'メッセージ';                       --  トークン値
  cv_cnst_item_name     CONSTANT VARCHAR2(12) :=  'MESSAGE_NAME';                     --  トークン値
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- SP専決支払区分（設置協賛金）
  cv_is_type_no         CONSTANT VARCHAR2(1)   := '0';                              -- 無
  cv_is_type_yes        CONSTANT VARCHAR2(1)   := '1';                              -- 有
  -- SP専決支払条件（設置協賛金）
  cv_is_pay_type_yearly CONSTANT VARCHAR2(1)   := '1';                              -- 1年払いの場合
  cv_is_pay_type_single CONSTANT VARCHAR2(1)   := '2';                              -- 総額払いの場合
  -- SP専決支払区分（紹介手数料）
  cv_ic_type_no         CONSTANT VARCHAR2(1)   := '0';                              -- 無
  cv_ic_type_yes        CONSTANT VARCHAR2(1)   := '1';                              -- 有
  -- SP専決支払条件（紹介手数料）
  cv_ic_pay_type_single CONSTANT VARCHAR2(1)   := '1';                              -- 売上に応じない一括支払の場合
  cv_ic_pay_type_per_sp CONSTANT VARCHAR2(1)   := '2';                              -- 販売金額に対する％の場合
  cv_ic_pay_type_per_p  CONSTANT VARCHAR2(1)   := '3';                              -- 1本につき何円の場合
  -- SP専決電気代区分
  cv_electric_type_no   CONSTANT VARCHAR2(1)   := '0';                              -- なし
  cv_electric_type_fix  CONSTANT VARCHAR2(1)   := '1';                              -- 定額
  cv_electric_type_var  CONSTANT VARCHAR2(1)   := '2';                              -- 変動
  -- SP専決支払条件（電気代）
  cv_e_pay_type_cont    CONSTANT VARCHAR2(1)   := '1';                              -- 契約先
  cv_e_pay_type_other   CONSTANT VARCHAR2(1)   := '2';                              -- 契約先以外
  -- 前文(クイックコード)
  cv_lkup_preamble_type CONSTANT VARCHAR2(100) := 'XXCSO1_MEMORANDUM_PREAMBLE';     -- 覚書前文
  cv_lkup_preamble_code CONSTANT VARCHAR2(1)   := '1';                              -- 覚書前文コード
  -- 地域管理拠点コード
  cv_lkup_sp_mgr_type   CONSTANT VARCHAR2(100) := 'XXCSO1_SP_MGR_BASE_CD';          -- SP専決管理拠点
  cv_lkup_sp_mgr_memo   CONSTANT VARCHAR2(100) := 'Y';                              -- SP専決管理拠点コードDFF1（覚書使用区分）
  -- ＳＰ専決振込手数料負担区分
  cv_lkup_trns_fee_type CONSTANT VARCHAR2(100) := 'XXCSO1_SP_TRANSFER_FEE_TYPE';
  -- 統轄本部長所属
  cv_lkup_e_vice_org    CONSTANT VARCHAR2(100) := 'XXCSO1_E_VICE_ORG';
  -- 発行元所属長コード
  cv_lkup_org_boss_code CONSTANT VARCHAR2(100) := 'XXCSO1_ORG_BOSS_CODE';
  -- 設置協賛金／紹介手数料
  cv_lkup_is_ic_appv_cls CONSTANT VARCHAR2(100) := 'XXCSO1_IS_IC_APPV_CLASS';
  -- 発行元所属長コード
  cv_e_vice_org_cd      CONSTANT VARCHAR2(1)   := '1';
  -- 設置協賛金発行元区分取得コード
  cv_appv_cls_br_mgr    CONSTANT VARCHAR2(1)   := '1'; -- 支店長
  cv_appv_cls_areamgr   CONSTANT VARCHAR2(1)   := '2'; -- 地区本部長
  -- 覚書出力フラグ
  cn_is_memo_no         CONSTANT NUMBER        := 0;                              -- 覚書（設置協賛金）無し
  cn_is_memo_yes        CONSTANT NUMBER        := 1;                              -- 覚書（設置協賛金）有り
  cn_ic_memo_no         CONSTANT NUMBER        := 0;                              -- 覚書（紹介手数料）無し
  cn_ic_memo_single     CONSTANT NUMBER        := 1;                              -- 覚書（紹介手数料）有り－売上に応じない一括支払の場合
  cn_ic_memo_per_sp     CONSTANT NUMBER        := 2;                              -- 覚書（紹介手数料）有り－販売金額に対する％の場合
  cn_ic_memo_per_p      CONSTANT NUMBER        := 3;                              -- 覚書（紹介手数料）有り－1本につき何円の場合
  cn_e_memo_no          CONSTANT NUMBER        := 0;                              -- 覚書（電気代）無し－電気代なし
  cn_e_memo_cont        CONSTANT NUMBER        := 1;                              -- 覚書（電気代）無し－支払い条件＝契約者
  cn_e_memo_o_fix       CONSTANT NUMBER        := 2;                              -- 覚書（電気代）有り－定額
  cn_e_memo_o_var       CONSTANT NUMBER        := 3;                              -- 覚書（電気代）有り－変動
  -- プロファイル名
  cv_interval           CONSTANT VARCHAR2(30)  := 'XXCSO1_INTERVAL_XXCSO010A04C'; -- XXCSO:待機間隔（覚書出力）
  cv_max_wait           CONSTANT VARCHAR2(30)  := 'XXCSO1_MAX_WAIT_XXCSO010A04C'; -- XXCSO:最大待機時間（覚書出力）
  -- 覚書出力コンカレント名
  cv_xxcso010a06        CONSTANT VARCHAR2(20)  := 'XXCSO010A06C';                 -- 覚書出力
  -- 覚書帳票区分
  cv_memo_inst          CONSTANT VARCHAR2(1)   := '1';
  cv_memo_intro_fix     CONSTANT VARCHAR2(1)   := '2';
  cv_memo_intro_price   CONSTANT VARCHAR2(1)   := '3';
  cv_memo_intro_piece   CONSTANT VARCHAR2(1)   := '4';
  cv_memo_elec_fix      CONSTANT VARCHAR2(1)   := '5';
  cv_memo_elec_change   CONSTANT VARCHAR2(1)   := '6';
  -- コンカレントdevステータス
  cv_dev_status_normal  CONSTANT VARCHAR2(6)   := 'NORMAL';  -- '正常'
  cv_dev_status_warn    CONSTANT VARCHAR2(7)   := 'WARNING'; -- '警告'
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- 自動販売機設置契約書ID
  gt_contract_number    xxcso_contract_managements.contract_number%TYPE;             -- 契約書番号
-- == 2010/08/03 V1.9 Added START ===============================================================
  gt_contract_date_ptn  fnd_new_messages.message_text%TYPE;                           --  契約書出力日定型
  gt_terms_note_price   fnd_new_messages.message_text%TYPE;                           --  販売手数料但書（売価別）
  gt_terms_note_ves     fnd_new_messages.message_text%TYPE;                           --  販売手数料但書（容器別）
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- 覚書出力要求発行関連
  gn_interval           VARCHAR2(30);
  gn_max_wait           VARCHAR2(30);
  gn_req_cnt            NUMBER;
  gv_retcode            VARCHAR2(1);
  gv_memo_inst          VARCHAR2(1);
  gv_memo_intro         VARCHAR2(1);
  gv_memo_elec          VARCHAR2(1);
  -- 覚書の発行画面出力用名称
  gv_conc_des_inst      VARCHAR2(100);
  gv_conc_des_intro     VARCHAR2(100);
  gv_conc_des_electric  VARCHAR2(100);
  -- 前文固定部
  gv_install_supp_pre   VARCHAR2(300);
  gv_intro_chg_pre1     VARCHAR2(300);
  gv_intro_chg_pre2     VARCHAR2(300);
  gv_electric_pre1      VARCHAR2(300);
  gv_electric_pre2      VARCHAR2(300);
  gv_electric_pre3      VARCHAR2(300);
  gv_electric_pre4      VARCHAR2(300);
  -- 本部長職位
  gt_gen_mgr_pos_code   fnd_lookup_values.attribute1%TYPE;
  -- 統括本部長（副社長）所属拠点（新）
  gt_e_vice_pres_base   fnd_lookup_values.attribute2%TYPE;
  -- 統括本部長（副社長）資格コード（新）
  gt_e_vice_pres_qual   fnd_lookup_values.attribute3%TYPE;
  -- 設置協賛金発行元所属分岐
  gn_is_amt_branch      NUMBER;       -- 支店長（設置協賛金総額上限）
  gn_is_amt_areamgr     NUMBER;       -- 地域営業本部長（設置協賛金総額上限）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 自動販売機設置契約書帳票ワークテーブル データ格納用レコード型定義
  TYPE g_rep_cont_data_rtype IS RECORD(
    install_location              xxcso_rep_auto_sale_cont.install_location%TYPE,              -- 設置ロケーション
    contract_number               xxcso_rep_auto_sale_cont.contract_number%TYPE,               -- 契約書番号
    contract_name                 xxcso_rep_auto_sale_cont.contract_name%TYPE,                 -- 契約者名
    contract_period               xxcso_rep_auto_sale_cont.contract_period%TYPE,               -- 契約期間
    cancellation_offer_code       xxcso_rep_auto_sale_cont.cancellation_offer_code%TYPE,       -- 契約解除申し出
    other_content                 xxcso_rep_auto_sale_cont.other_content%TYPE,                 -- 特約事項
    sales_charge_details_delivery xxcso_rep_auto_sale_cont.sales_charge_details_delivery%TYPE, -- 手数料明細書送付先名
    delivery_address              xxcso_rep_auto_sale_cont.delivery_address%TYPE,              -- 送付先住所
    install_name                  xxcso_rep_auto_sale_cont.install_name%TYPE,                  -- 設置先名
    install_address               xxcso_rep_auto_sale_cont.install_address%TYPE,               -- 設置先住所
    install_date                  xxcso_rep_auto_sale_cont.install_date%TYPE,                  -- 設置日
    bank_name                     xxcso_rep_auto_sale_cont.bank_name%TYPE,                     -- 金融機関名
    blanches_name                 xxcso_rep_auto_sale_cont.blanches_name%TYPE,                 -- 支店名
    account_number                xxcso_rep_auto_sale_cont.account_number%TYPE,                -- 顧客コード
    bank_account_number           xxcso_rep_auto_sale_cont.bank_account_number%TYPE,           -- 口座番号
    bank_account_name_kana        xxcso_rep_auto_sale_cont.bank_account_name_kana%TYPE,        -- 口座名義カナ
    publish_base_code             xxcso_rep_auto_sale_cont.publish_base_code%TYPE,             -- 担当拠点
    publish_base_name             xxcso_rep_auto_sale_cont.publish_base_name%TYPE,             -- 担当拠点名
    contract_effect_date          xxcso_rep_auto_sale_cont.contract_effect_date%TYPE,          -- 契約書発効日
    issue_belonging_address       xxcso_rep_auto_sale_cont.issue_belonging_address%TYPE,       -- 発行元所属住所
    issue_belonging_name          xxcso_rep_auto_sale_cont.issue_belonging_name%TYPE,          -- 発行元所属名
    issue_belonging_boss_position xxcso_rep_auto_sale_cont.issue_belonging_boss_position%TYPE, -- 発行元所属長職位名
    issue_belonging_boss          xxcso_rep_auto_sale_cont.issue_belonging_boss%TYPE,          -- 発行元所属長名
    close_day_code                xxcso_rep_auto_sale_cont.close_day_code%TYPE,                -- 締日
    transfer_month_code           xxcso_rep_auto_sale_cont.transfer_month_code%TYPE,           -- 払い月
    transfer_day_code             xxcso_rep_auto_sale_cont.transfer_day_code%TYPE,             -- 払い日
    exchange_condition            xxcso_rep_auto_sale_cont.exchange_condition%TYPE,            -- 取引条件
    condition_contents_1          xxcso_rep_auto_sale_cont.condition_contents_1%TYPE,          -- 条件内容1
    condition_contents_2          xxcso_rep_auto_sale_cont.condition_contents_2%TYPE,          -- 条件内容2
    condition_contents_3          xxcso_rep_auto_sale_cont.condition_contents_3%TYPE,          -- 条件内容3
    condition_contents_4          xxcso_rep_auto_sale_cont.condition_contents_4%TYPE,          -- 条件内容4
    condition_contents_5          xxcso_rep_auto_sale_cont.condition_contents_5%TYPE,          -- 条件内容5
    condition_contents_6          xxcso_rep_auto_sale_cont.condition_contents_6%TYPE,          -- 条件内容6
    condition_contents_7          xxcso_rep_auto_sale_cont.condition_contents_7%TYPE,          -- 条件内容7
    condition_contents_8          xxcso_rep_auto_sale_cont.condition_contents_8%TYPE,          -- 条件内容8
    condition_contents_9          xxcso_rep_auto_sale_cont.condition_contents_9%TYPE,          -- 条件内容9
    condition_contents_10         xxcso_rep_auto_sale_cont.condition_contents_10%TYPE,         -- 条件内容10
    condition_contents_11         xxcso_rep_auto_sale_cont.condition_contents_11%TYPE,         -- 条件内容11
    condition_contents_12         xxcso_rep_auto_sale_cont.condition_contents_12%TYPE,         -- 条件内容12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
    condition_contents_13         xxcso_rep_auto_sale_cont.condition_contents_13%TYPE,         -- 条件内容13
    condition_contents_14         xxcso_rep_auto_sale_cont.condition_contents_14%TYPE,         -- 条件内容14
    condition_contents_15         xxcso_rep_auto_sale_cont.condition_contents_15%TYPE,         -- 条件内容15
    condition_contents_16         xxcso_rep_auto_sale_cont.condition_contents_16%TYPE,         -- 条件内容16
    condition_contents_17         xxcso_rep_auto_sale_cont.condition_contents_17%TYPE,         -- 条件内容17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
    install_support_amt           xxcso_rep_auto_sale_cont.install_support_amt%TYPE,           -- 設置協賛金
    electricity_information       xxcso_rep_auto_sale_cont.electricity_information%TYPE,       -- 電気代情報
    transfer_commission_info      xxcso_rep_auto_sale_cont.transfer_commission_info%TYPE,      -- 振り込み手数料情報
    electricity_amount            xxcso_sp_decision_headers.electricity_amount%TYPE,           -- 電気代
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    tax_type_name                 xxcso_rep_auto_sale_cont.tax_type_name%TYPE,                 -- 税区分名
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    condition_contents_flag       BOOLEAN,                                              -- 販売手数料情報有無フラグ
    install_support_amt_flag      BOOLEAN,                                              -- 設置協賛金有無フラグ
    electricity_information_flag  BOOLEAN                                              -- 電気代情報有無フラグ
  );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- 覚書帳票ワークテーブル データ格納用レコード型定義
  TYPE g_rep_memo_data_rtype IS RECORD(
    contract_number               xxcso_rep_memorandum.contract_number%TYPE,
    contract_other_custs_id       xxcso_rep_memorandum.contract_other_custs_id%TYPE,
    contract_name                 xxcso_rep_memorandum.contract_name%TYPE,
    contract_effect_date          xxcso_rep_memorandum.contract_effect_date%TYPE,
    install_name                  xxcso_rep_memorandum.install_name%TYPE,
    install_address               xxcso_rep_memorandum.install_address%TYPE,
    tax_type_name                 xxcso_rep_memorandum.tax_type_name%TYPE,
    install_supp_amt              xxcso_rep_memorandum.install_supp_amt%TYPE,
    install_supp_payment_date     xxcso_rep_memorandum.install_supp_payment_date%TYPE,
    install_supp_bk_chg_bearer    xxcso_rep_memorandum.install_supp_bk_chg_bearer%TYPE,
    install_supp_bk_number        xxcso_rep_memorandum.install_supp_bk_number%TYPE,
    install_supp_bk_name          xxcso_rep_memorandum.install_supp_bk_name%TYPE,
    install_supp_branch_number    xxcso_rep_memorandum.install_supp_branch_number%TYPE,
    install_supp_branch_name      xxcso_rep_memorandum.install_supp_branch_name%TYPE,
    install_supp_bk_acct_type     xxcso_rep_memorandum.install_supp_bk_acct_type%TYPE,
    install_supp_bk_acct_number   xxcso_rep_memorandum.install_supp_bk_acct_number%TYPE,
    install_supp_bk_acct_name_alt xxcso_rep_memorandum.install_supp_bk_acct_name_alt%TYPE,
    install_supp_bk_acct_name     xxcso_rep_memorandum.install_supp_bk_acct_name%TYPE,
    install_supp_org_addr         xxcso_rep_memorandum.install_supp_org_addr%TYPE,
    install_supp_org_name         xxcso_rep_memorandum.install_supp_org_name%TYPE,
    install_supp_org_boss_pos     xxcso_rep_memorandum.install_supp_org_boss_pos%TYPE,
    install_supp_org_boss         xxcso_rep_memorandum.install_supp_org_boss%TYPE,
    install_supp_preamble         xxcso_rep_memorandum.install_supp_preamble%TYPE,
    intro_chg_amt                 xxcso_rep_memorandum.intro_chg_amt%TYPE,
    intro_chg_payment_date        xxcso_rep_memorandum.intro_chg_payment_date%TYPE,
    intro_chg_closing_date        xxcso_rep_memorandum.intro_chg_closing_date%TYPE,
    intro_chg_trans_month         xxcso_rep_memorandum.intro_chg_trans_month%TYPE,
    intro_chg_trans_date          xxcso_rep_memorandum.intro_chg_trans_date%TYPE,
    intro_chg_trans_name          xxcso_rep_memorandum.intro_chg_trans_name%TYPE,
    intro_chg_trans_name_alt      xxcso_rep_memorandum.intro_chg_trans_name_alt%TYPE,
    intro_chg_bk_chg_bearer       xxcso_rep_memorandum.intro_chg_bk_chg_bearer%TYPE,
    intro_chg_bk_number           xxcso_rep_memorandum.intro_chg_bk_number%TYPE,
    intro_chg_bk_name             xxcso_rep_memorandum.intro_chg_bk_name%TYPE,
    intro_chg_branch_number       xxcso_rep_memorandum.intro_chg_branch_number%TYPE,
    intro_chg_branch_name         xxcso_rep_memorandum.intro_chg_branch_name%TYPE,
    intro_chg_bk_acct_type        xxcso_rep_memorandum.intro_chg_bk_acct_type%TYPE,
    intro_chg_bk_acct_number      xxcso_rep_memorandum.intro_chg_bk_acct_number%TYPE,
    intro_chg_bk_acct_name_alt    xxcso_rep_memorandum.intro_chg_bk_acct_name_alt%TYPE,
    intro_chg_bk_acct_name        xxcso_rep_memorandum.intro_chg_bk_acct_name%TYPE,
    intro_chg_org_addr            xxcso_rep_memorandum.intro_chg_org_addr%TYPE,
    intro_chg_org_name            xxcso_rep_memorandum.intro_chg_org_name%TYPE,
    intro_chg_org_boss_pos        xxcso_rep_memorandum.intro_chg_org_boss_pos%TYPE,
    intro_chg_org_boss            xxcso_rep_memorandum.intro_chg_org_boss%TYPE,
    intro_chg_preamble            xxcso_rep_memorandum.intro_chg_preamble%TYPE,
    electric_amt                  xxcso_rep_memorandum.electric_amt%TYPE,
    electric_closing_date         xxcso_rep_memorandum.electric_closing_date%TYPE,
    electric_trans_month          xxcso_rep_memorandum.electric_trans_month%TYPE,
    electric_trans_date           xxcso_rep_memorandum.electric_trans_date%TYPE,
    electric_trans_name           xxcso_rep_memorandum.electric_trans_name%TYPE,
    electric_trans_name_alt       xxcso_rep_memorandum.electric_trans_name_alt%TYPE,
    electric_bk_chg_bearer        xxcso_rep_memorandum.electric_bk_chg_bearer%TYPE,
    electric_bk_number            xxcso_rep_memorandum.electric_bk_number%TYPE,
    electric_bk_name              xxcso_rep_memorandum.electric_bk_name%TYPE,
    electric_branch_number        xxcso_rep_memorandum.electric_branch_number%TYPE,
    electric_branch_name          xxcso_rep_memorandum.electric_branch_name%TYPE,
    electric_bk_acct_type         xxcso_rep_memorandum.electric_bk_acct_type%TYPE,
    electric_bk_acct_number       xxcso_rep_memorandum.electric_bk_acct_number%TYPE,
    electric_bk_acct_name_alt     xxcso_rep_memorandum.electric_bk_acct_name_alt%TYPE,
    electric_bk_acct_name         xxcso_rep_memorandum.electric_bk_acct_name%TYPE,
    electric_org_addr             xxcso_rep_memorandum.electric_org_addr%TYPE,
    electric_org_name             xxcso_rep_memorandum.electric_org_name%TYPE,
    electric_org_boss_pos         xxcso_rep_memorandum.electric_org_boss_pos%TYPE,
    electric_org_boss             xxcso_rep_memorandum.electric_org_boss%TYPE,
    electric_preamble             xxcso_rep_memorandum.electric_preamble%TYPE,
    install_supp_memo_flg         NUMBER,
    intro_chg_memo_flg            NUMBER,
    electric_memo_flg             NUMBER
  );
  --覚書出力要求ID
  TYPE g_org_request_rtype IS RECORD(
    request_id                    fnd_concurrent_requests.request_id%TYPE
  );
  TYPE g_org_request_ttype IS TABLE OF g_org_request_rtype INDEX BY PLS_INTEGER;
  g_org_request  g_org_request_ttype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ot_status           OUT NOCOPY VARCHAR2       -- ステータス
    ,ot_cooperate_flag   OUT NOCOPY VARCHAR2       -- マスタ連携フラグ
    ,ov_errbuf           OUT NOCOPY VARCHAR2       -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2       -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル定数 ***
    cv_con_mng_id        CONSTANT VARCHAR2(100)   := '自動販売機設置契約書ID';
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg               VARCHAR2(5000);
-- == 2010/08/03 V1.9 Added START ===============================================================
    lv_err_key          VARCHAR2(30);
-- == 2010/08/03 V1.9 Added END   ===============================================================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===================================================
    -- パラメータ必須チェック(自動販売機設置契約書ID)
    -- ===================================================
    IF (gt_con_mng_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01         -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================
    -- 起動パラメータメッセージ出力
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name            --アプリケーション短縮名
                ,iv_name         => cv_tkn_number_09       --メッセージコード
                ,iv_token_name1  => cv_tkn_param_nm        --トークンコード1
                ,iv_token_value1 => cv_con_mng_id          --トークン値1
                ,iv_token_name2  => cv_tkn_val             --トークンコード2
                ,iv_token_value2 => TO_CHAR(gt_con_mng_id) --トークン値2
              );
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    -- ===================================================
    -- 契約書番号、ステータス、マスタ連携フラグを取得
    -- ===================================================
    BEGIN
      SELECT xcm.contract_number contract_number
            ,xcm.status status
            ,xcm.cooperate_flag cooperate_flag
      INTO   gt_contract_number
            ,ot_status
            ,ot_cooperate_flag
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_management_id = gt_con_mng_id;
--
    -- ===========================
    -- 契約書番号メッセージ出力
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                  -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_02             -- メッセージコード
                ,iv_token_name1  => cv_tkn_contract_num          -- トークンコード1
                ,iv_token_value1 => gt_contract_number           -- トークン値1
              );
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    EXCEPTION
      -- データ抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_con_mng_id          -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(gt_con_mng_id)     -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
-- == 2010/08/03 V1.9 Added START ===============================================================
    BEGIN
      -- ===========================
      -- 契約書出力日定型
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00604;
      --
      SELECT  fnm.message_text      message_text                  --  現行テキストメッセージ
      INTO    gt_contract_date_ptn                                --  契約書出力日定型
      FROM    fnd_new_messages      fnm                           --  メッセージ
            , fnd_application       fa                            --  アプリケーション
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00604
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      -- ===========================
      -- 販売手数料但書（売価別）
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00605;
      --
      SELECT  fnm.message_text      message_text                  --  現行テキストメッセージ
      INTO    gt_terms_note_price                                 --  販売手数料但書（売価別）
      FROM    fnd_new_messages      fnm                           --  メッセージ
            , fnd_application       fa                            --  アプリケーション
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00605
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      -- ===========================
      -- 販売手数料但書（容器別）
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00606;
      --
      SELECT  fnm.message_text      message_text                  --  現行テキストメッセージ
      INTO    gt_terms_note_ves                                   --  販売手数料但書（容器別）
      FROM    fnd_new_messages      fnm                           --  メッセージ
            , fnd_application       fa                            --  アプリケーション
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00606
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_name                -- アプリケーション短縮名
                        , iv_name           =>  cv_msg_xxcso_00470           -- メッセージコード
                        , iv_token_name1    =>  cv_tkn_xxcso_00470_01
                        , iv_token_value1   =>  cv_cnst_message
                        , iv_token_name2    =>  cv_tkn_xxcso_00470_02
                        , iv_token_value2   =>  cv_cnst_item_name
                        , iv_token_name3    =>  cv_tkn_xxcso_00470_03
                        , iv_token_value3   =>  lv_err_key
                      );
        lv_errbuf :=  lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- ===================================================
    -- 前文固定部取得
    -- ===================================================
    BEGIN
      SELECT
        flvv.attribute1 || flvv.attribute2 install_supp_pre    -- 前文固定部（設置協賛金）
       ,flvv.attribute1 || flvv.attribute3 intro_chg_pre1      -- 前文固定部1（紹介手数料）
       ,flvv.attribute1 || flvv.attribute4 intro_chg_pre2      -- 前文固定部2（紹介手数料）
       ,flvv.attribute1 || flvv.attribute5 electric_pre1       -- 前文固定部1（電気代）
       ,flvv.attribute6                    electric_pre2       -- 前文固定部2（電気代）
       ,flvv.attribute7 || flvv.attribute9 electric_pre3       -- 前文固定部3（電気代）
       ,flvv.attribute8 || flvv.attribute9 electric_pre4       -- 前文固定部4（電気代）
      INTO
        gv_install_supp_pre                          -- 前文固定部（設置協賛金）
       ,gv_intro_chg_pre1                            -- 前文固定部1（紹介手数料）
       ,gv_intro_chg_pre2                            -- 前文固定部2（紹介手数料）
       ,gv_electric_pre1                             -- 前文固定部1（電気代）
       ,gv_electric_pre2                             -- 前文固定部2（電気代）
       ,gv_electric_pre3                             -- 前文固定部3（電気代）
       ,gv_electric_pre4                             -- 前文固定部4（電気代）
      FROM  fnd_lookup_values_vl  flvv               -- 参照タイプテーブル
      WHERE flvv.lookup_type  = cv_lkup_preamble_type
      AND   flvv.lookup_code  = cv_lkup_preamble_code
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- アプリケーション短縮名
                        ,iv_name           => cv_tkn_number_12           -- メッセージコード
                        ,iv_token_name1    => cv_tkn_contract_num        -- トークン：CONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- 契約書番号
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ===================================================
    -- 発行元所属長コード取得
    -- ===================================================
    BEGIN
      SELECT
            flvv.attribute1  gen_mgr_pos_code            -- 本部長職位
           ,flvv.attribute2  e_vice_pres_base            -- 統括本部長所属拠点
           ,flvv.attribute3  e_vice_pres_qual            -- 統括本部長資格コード
      INTO
            gt_gen_mgr_pos_code                          -- 本部長職位
           ,gt_e_vice_pres_base                          -- 統括本部長所属拠点
           ,gt_e_vice_pres_qual                          -- 統括本部長資格コード
      FROM  fnd_lookup_values_vl flvv                    -- 参照タイプテーブル
      WHERE flvv.lookup_type  = cv_lkup_org_boss_code
      AND   flvv.lookup_code  = cv_e_vice_org_cd
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- アプリケーション短縮名
                        ,iv_name           => cv_tkn_number_13           -- メッセージコード
                        ,iv_token_name1    => cv_tkn_contract_num        -- トークン：CONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- 契約書番号
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ===================================================
    -- 設置協賛金総額上限取得
    -- ===================================================
    -- 支店長
    BEGIN
      SELECT
        flvv.attribute3  is_amt_branch             -- 支店長（設置協賛金総額上限）
      INTO
        gn_is_amt_branch                           -- 支店長（設置協賛金総額上限）
      FROM  fnd_lookup_values_vl flvv              -- 参照タイプテーブル
      WHERE flvv.lookup_type  = cv_lkup_is_ic_appv_cls
      AND   flvv.lookup_code  = cv_appv_cls_br_mgr
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- アプリケーション短縮名
                        ,iv_name           => cv_tkn_number_14           -- メッセージコード
                        ,iv_token_name1    => cv_tkn_contract_num        -- トークン：CONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- 契約書番号
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 地域営業本部長
    BEGIN
      SELECT
        flvv.attribute3  is_amt_areamgr             -- 地域営業本部長（設置協賛金総額上限）
      INTO
        gn_is_amt_areamgr                           -- 地域営業本部長（設置協賛金総額上限）
      FROM  fnd_lookup_values_vl flvv               -- 参照タイプテーブル
      WHERE flvv.lookup_type  = cv_lkup_is_ic_appv_cls
      AND   flvv.lookup_code  = cv_appv_cls_areamgr
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- アプリケーション短縮名
                        ,iv_name           => cv_tkn_number_14           -- メッセージコード
                        ,iv_token_name1    => cv_tkn_contract_num        -- トークン：CONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- 契約書番号
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ===================================================
    -- プロファイル取得
    -- ===================================================
    -- XXCSO:待機間隔（覚書出力）
    gn_interval := TO_NUMBER(FND_PROFILE.VALUE( cv_interval ));
    -- プロファイル値チェック
    IF ( gn_interval IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_15  -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_name  -- トークンコード1
                     ,iv_token_value1 => cv_interval       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- XXCOS:最大待機時間（覚書出力）
    gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE( cv_max_wait ));
    -- プロファイル値チェック
    IF ( gn_max_wait IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_15  -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_name  -- トークンコード1
                     ,iv_token_value1 => cv_max_wait       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===================================================
    -- 覚書の発行画面出力用名称の取得
    -- ===================================================
    --設置協賛金
    gv_conc_des_inst     := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_16      -- メッセージコード
                              ,iv_token_name1  => cv_tkn_contract_num   -- トークンコード1
                              ,iv_token_value1 => gt_contract_number    -- トークン値1
                            );
    --電気代
    gv_conc_des_electric := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_17      -- メッセージコード
                              ,iv_token_name1  => cv_tkn_contract_num   -- トークンコード1
                              ,iv_token_value1 => gt_contract_number    -- トークン値1
                            );
    --紹介手数料
    gv_conc_des_intro    := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_18      -- メッセージコード
                              ,iv_token_name1  => cv_tkn_contract_num   -- トークンコード1
                              ,iv_token_value1 => gt_contract_number    -- トークン値1
                            );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data
   * Description      : データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
     iv_process_flag       IN         VARCHAR2               -- 処理フラグ
    ,o_rep_cont_data_rec   OUT NOCOPY g_rep_cont_data_rtype  -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,o_rep_memo_data_rec   OUT NOCOPY g_rep_memo_data_rtype  -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf             OUT NOCOPY VARCHAR2               -- エラー・メッセージ            --# 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2               -- リターン・コード              --# 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_contract_data';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 印紙表示フラグ
    cv_stamp_show_1          CONSTANT VARCHAR2(1)   := '1';  -- 表示
    cv_stamp_show_0          CONSTANT VARCHAR2(1)   := '0';  -- 非表示
    -- 設置ロケーション
    cv_i_location_type_2     CONSTANT VARCHAR2(1)   := '2';  -- 屋外
    cv_i_location_type_3     CONSTANT VARCHAR2(1)   := '3';  -- 路面
    -- 電気代区分
    cv_electricity_type_1    CONSTANT VARCHAR2(1)   := '1';
    cv_electricity_type_2    CONSTANT VARCHAR2(1)   := '2';
    -- 振込手数料負担区分
    cv_bank_trans_fee_div_1  CONSTANT VARCHAR2(1)   := 'S';
    cv_bank_trans_fee_div_2  CONSTANT VARCHAR2(1)   := 'I';
    -- 取引条件区分
    cv_cond_b_type_1         CONSTANT VARCHAR2(1)   := '1';  -- 売価別条件
    cv_cond_b_type_2         CONSTANT VARCHAR2(1)   := '2';  -- 売価別条件（寄付金登録用）
    cv_cond_b_type_3         CONSTANT VARCHAR2(1)   := '3';  -- 一律・容器別条件
    cv_cond_b_type_4         CONSTANT VARCHAR2(1)   := '4';  -- 一律・容器別条件（寄付金登録用）
    -- SP専決顧客区分
    cv_sp_d_cust_class_3     CONSTANT VARCHAR2(1)   := '3';  -- ＢＭ１
    -- 送付区分
    cv_delivery_div_1        CONSTANT VARCHAR2(1)   := '1';  -- ＢＭ１
    -- 職位コード
    cv_p_code_002            CONSTANT VARCHAR2(3)   := '002';
    cv_p_code_003            CONSTANT VARCHAR2(3)   := '003';
    -- ＳＰ専決容器別取引条件(クイックコード)
    cv_lkup_container_type   CONSTANT VARCHAR2(100) := 'XXCSO1_SP_RULE_BOTTLE';
    -- 月タイプ(クイックコード)
    cv_lkup_months_type      CONSTANT VARCHAR2(100) := 'XXCSO1_MONTHS_TYPE';
    -- 自動販売機設置契約書契約者部分内容(クイックコード)
    cv_lkup_contract_nm_con  CONSTANT VARCHAR2(100) := 'XXCSO1_CONTRACT_NM_CONTENT';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- SP専決税区分(クイックコード)
    cv_lkup_sp_tax_type      CONSTANT VARCHAR2(100) := 'XXCSO1_SP_TAX_DIVISION';  -- SP専決税区分
    cv_in_tax                CONSTANT VARCHAR2(1)   := '1';                       -- 税込
    cv_ex_tax                CONSTANT VARCHAR2(1)   := '2';                       -- 税抜
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- 以下余白
    cv_cond_conts_space      CONSTANT VARCHAR2(8)   := '以下余白';
    -- 定率
    cv_tei_rate              CONSTANT VARCHAR2(10)  := '定率（額）';
    -- 売価別
    cv_uri_rate              CONSTANT VARCHAR2(6)   := '売価別';
    -- 容器別
    cv_youki_rate            CONSTANT VARCHAR2(6)   := '容器別';
    -- ＳＰ専決明細テーブル
    cv_sp_decision_lines     CONSTANT VARCHAR2(100) := 'ＳＰ専決明細テーブル';
    -- 郵便マーク
    cv_post_mark             CONSTANT VARCHAR2(2)   := '〒';
    /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
    -- ＢＭ支払方法・明細書
    cv_csh_pymnt             CONSTANT VARCHAR2(1)   := '4';  -- 現金支払
    /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
    -- *** ローカル変数 ***
    lv_cond_business_type    VARCHAR2(1);       -- 取引条件区分
    ld_sysdate               DATE;              -- 業務日付
    lv_cond_conts_tmp        xxcso_rep_auto_sale_cont.condition_contents_1%TYPE;    -- 条件内容1
    ln_lines_cnt             NUMBER;            -- 明細件数
    ln_bm1_bm_rate           NUMBER;            -- ＢＭ１ＢＭ率
    ln_bm1_bm_amount         NUMBER;            -- ＢＭ１ＢＭ金額
    lb_bm1_bm_rate           BOOLEAN;           -- ＢＭ１ＢＭ率による定率判断フラグ
    lb_bm1_bm_amount         BOOLEAN;           -- ＢＭ１ＢＭ金額による定率判断フラグ
    lb_bm1_bm                BOOLEAN;           -- 販売手数料有無フラグ(TRUE:有,FALSE:無)
    /* 2009.11.30 T.Maruyama E_本稼動_00193 START */
    ln_work_cnt              NUMBER;            -- 定額判断時件数カウント用
    ln_work_cnt_ritu         NUMBER;            -- 率判断時件数カウント用
    ln_work_cnt_gaku         NUMBER;            -- 額判断時件数カウント用
    /* 2009.11.30 T.Maruyama E_本稼動_00193 END */
-- == 2010/08/03 V1.9 Added START ===============================================================
    lv_condition_content_type VARCHAR2(1);      --  全容器一律区分
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    lt_install_supp_amt      xxcso_sp_decision_headers.install_support_amt%TYPE;
    lt_area_mgr_base_cd      xxcmm_hierarchy_dept_all_v.cur_dpt_cd%TYPE;
    lt_a_mgr_boss_org_ad     xxcso_rep_memorandum.intro_chg_org_addr%TYPE;
    lt_a_mgr_boss_org_nm     xxcso_locations_v2.location_name%TYPE;
    lt_a_mgr_boss_pos        xxcso_employees_v2.position_name_new%TYPE;
    lt_a_mgr_boss            xxcso_employees_v2.full_name%TYPE;
    lt_e_vice_pres_org_ad    xxcso_rep_memorandum.install_supp_org_addr%TYPE;
    lt_e_vice_pres_org_nm    fnd_lookup_values_vl.meaning%TYPE;
    lt_e_vice_pres_pos       xxcso_employees_v2.position_name_new%TYPE;
    lt_e_vice_pres           xxcso_employees_v2.full_name%TYPE;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- *** ローカル・カーソル *** 
    CURSOR l_sales_charge_cur
    IS
      SELECT xsdh.sp_decision_header_id sp_decision_header_id        -- ＳＰ専決ヘッダＩＤ
            ,xsdl.sp_decision_line_id sp_decision_line_id           -- ＳＰ専決明細ＩＤ
            ,xcm.close_day_code close_day_code                      -- 締め日
            ,(SELECT flvv_month.meaning                             -- 内容
              FROM   fnd_lookup_values_vl flvv_month                -- 参照タイプテーブル
              WHERE  flvv_month.lookup_type = cv_lkup_months_type
                AND  TRUNC(SYSDATE) BETWEEN TRUNC(flvv_month.start_date_active)
                                    AND TRUNC(NVL(flvv_month.end_date_active, SYSDATE))
                AND  flvv_month.enabled_flag = cv_enabled_flag
                AND  xcm.transfer_month_code = flvv_month.lookup_code
                AND  ROWNUM = 1
              ) transfer_month_code                                 -- 払い月
            ,xcm.transfer_day_code transfer_day_code                -- 払い日
            ,xsdh.condition_business_type condition_business_type   -- 取引条件区分
            ,xsdl.sp_container_type sp_container_type               -- ＳＰ容器区分
            ,xsdl.fixed_price fixed_price                           -- 定価
            ,xsdl.sales_price sales_price                           -- 売価
            ,xsdl.bm1_bm_rate bm1_bm_rate                           -- ＢＭ１ＢＭ率
            ,xsdl.bm1_bm_amount bm1_bm_amount                       -- ＢＭ１ＢＭ金額
-- == 2010/08/03 V1.9 Modified START ===============================================================
--            ,(CASE
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
--                 '販売価格 ' || TO_CHAR(xsdl.sales_price)
--                             || '円のとき、１本につき販売価格の '
--                             || TO_CHAR(xsdl.bm1_bm_rate) || '%を支払う'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                       AND (xsdl.bm1_bm_amount IS NOT NULL AND xsdl.bm1_bm_amount <> '0')) THEN
--                 '販売価格 ' || TO_CHAR(xsdl.sales_price)
--                             || '円のとき、１本につき '
--                             || TO_CHAR(xsdl.bm1_bm_amount) || '円を支払う'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
--                 '販売容器が ' || flvv.meaning
--                               || 'のとき、１本につき売価の '
--                               || TO_CHAR(xsdl.bm1_bm_rate) || '%を支払う'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                       AND (xsdl.bm1_bm_amount IS NOT NULL  AND xsdl.bm1_bm_amount <> '0')) THEN
--                 '販売容器が ' || flvv.meaning
--                               || 'のとき、１本につき '
--                               || TO_CHAR(xsdl.bm1_bm_amount) || '円を支払う'
--              END) condition_contents                               -- 条件内容
            , CASE
                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                        AND (xsdl.bm1_bm_rate IS NOT NULL)
                        AND (xsdl.bm1_bm_rate <> '0')
                      )
                THEN      '販売価格 '
                      ||  TO_CHAR(xsdl.sales_price)
                      ||  '円の商品につき、販売金額に対し、'
                      ||  TO_CHAR(xsdl.bm1_bm_rate)
                      ||  '%とする。'
                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
                        AND (xsdl.bm1_bm_amount IS NOT NULL)
                        AND (xsdl.bm1_bm_amount <> '0')
                      )
                THEN      '販売価格 '
                      ||  TO_CHAR(xsdl.sales_price)
                      ||  '円の商品につき、１本当たり '
                      ||  TO_CHAR(xsdl.bm1_bm_amount)
                      ||  '円とする。'
                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                        AND (xsdl.bm1_bm_rate IS NOT NULL)
                        AND (xsdl.bm1_bm_rate <> '0')
                      )
                THEN      flvv.meaning
                      ||  '商品につき、販売金額に対し、'
                      ||  TO_CHAR(xsdl.bm1_bm_rate)
                      ||  '%とする。'
                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                        AND (xsdl.bm1_bm_amount IS NOT NULL)
                        AND (xsdl.bm1_bm_amount <> '0')
                      )
                THEN      flvv.meaning
                      ||  '商品につき、１本当たり '
                      ||  TO_CHAR(xsdl.bm1_bm_amount)
                      ||  '円とする。'
              END                                 condition_contents                          --  条件内容
            , CASE  WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                            AND (xsdl.bm1_bm_rate IS NOT NULL)
                            AND (xsdl.bm1_bm_rate <> 0)
                            AND (NVL(xsdh.all_container_type, '*') = '1')
                          )
                    THEN    '1'       --  全容器一律（レート）
                    WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                            AND (xsdl.bm1_bm_amount IS NOT NULL)
                            AND (xsdl.bm1_bm_amount <> 0)
                            AND (NVL(xsdh.all_container_type, '*') = '1')
                          )
                    THEN    '2'       --  全容器一律（価格）
                    ELSE    '0'       --  全容器一律以外
              END                                 condition_content_type                      --  全容器一律区分
-- == 2010/08/03 V1.9 Modified END   ===============================================================
       FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
             ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
             ,xxcso_sp_decision_lines    xsdl     -- ＳＰ専決明細テーブル
             ,(SELECT  flv.meaning
                       ,flv.lookup_code
                       /* 2009.04.27 K.Satomura T1_0778対応 START */
                       ,flv.attribute4
                       /* 2009.04.27 K.Satomura T1_0778対応 END */
                 FROM  fnd_lookup_values_vl flv
                WHERE  flv.lookup_type = cv_lkup_container_type
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flv.start_date_active)
                  AND  TRUNC(NVL(flv.end_date_active, ld_sysdate))
                  AND  flv.enabled_flag = cv_enabled_flag
              )  flvv    -- 参照タイプ
       WHERE  xcm.contract_management_id = gt_con_mng_id
         AND  xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
         AND  xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
         AND  xsdh.condition_business_type
                IN (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
       /* 2009.04.27 K.Satomura T1_0778対応 START */
         --AND  xsdl.sp_container_type = flvv.lookup_code(+);
         AND  xsdl.sp_container_type = flvv.lookup_code(+)
       ORDER BY DECODE(xsdh.condition_business_type
                      ,cv_cond_b_type_1 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_2 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_3 ,flvv.attribute4
                      ,cv_cond_b_type_4 ,flvv.attribute4
                      )
       ;
       /* 2009.04.27 K.Satomura T1_0778対応 END */

--
    -- *** ローカル・レコード *** 
    l_sales_charge_rec  l_sales_charge_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);  -- 共通関数により業務日付を格納
--
    -- 処理フラグ
    -- ステータスが作成中の場合、またはステータスが確定済、且つマスタ連携フラグが未連携の場合
    IF (iv_process_flag = cv_flag_1) THEN
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10)
             || '＜＜ 契約関連情報：ステータスが作成中、またはステータスが確定済、且つマスタ連携フラグが未連携 ＞＞'
      );
--
      -- ===========================
      -- 契約関連情報取得（A-2-1-1）
      -- ===========================
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcav.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                              -- 設置ロケーション
              ,xcm.contract_number   contract_number               -- 契約書番号
              /* 2009.09.14 M.Maruyama 0001355対応 START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc   -- 契約先テーブル
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name               -- 契約書名
               ) || flvv_con.attr), 1, 660) contract_name         -- 契約書名
              /* 2009.09.14 M.Maruyama 0001355対応 END */
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--              ,xsdh.contract_year_date contract_period             -- 契約期間
              ,CASE xsdh.contract_year_date
                 WHEN 0 THEN 1
                 ELSE xsdh.contract_year_date
               END contract_period                                   -- 契約期間
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
              ,xcm.cancellation_offer_code cancellation_offer_code -- 契約解除申し出
              ,xsdh.other_content other_content                    -- 特約事項
              ,xd.payment_name sales_charge_details_delivery       -- 支払先名
              /* 2009.10.15 D.Abe 0001536,0001537対応 START */
              --,(NVL2(xd.post_code, cv_post_mark || xd.post_code || ' ', '') || xd.prefectures || xd.city_ward
              ,(NVL2(xd.post_code, cv_post_mark || xd.post_code || ' ', '')
              /* 2009.10.15 D.Abe 0001536,0001537対応 END */
                             || xd.address_1 || xd.address_2) delivery_address  -- 送付先住所
              ,xcm.install_party_name install_name                 -- 設置先顧客名
              ,(NVL2(xcm.install_postal_code, cv_post_mark || xcm.install_postal_code || ' ', '')
                           || xcm.install_state || xcm.install_city
                           || xcm.install_address1 || xcm.install_address2) install_address  -- 設置先住所
              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) install_date                                     -- 設置日
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
              --,xba.bank_name bank_name                             -- 銀行名
              --,xba.branch_name blanches_name                       -- 支店名
              --,xba.bank_account_number bank_account_number         -- 口座番号
              --,xba.bank_account_name_kana bank_account_name_kana   -- 口座名義カナ
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.bank_name)
                ) bank_name                                        -- 銀行名
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.branch_name)
                ) blanches_name                                    -- 支店名
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
-- == 2010/08/03 V1.9 Modified START ===============================================================
--                          , xba.bank_account_number)
                          , flv.bank_acct_type_name || cv_space || xba.bank_account_number)
-- == 2010/08/03 V1.9 Modified END   ===============================================================
                ) bank_account_number                              -- 口座番号
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.bank_account_name_kana)
                ) bank_account_name_kana                          -- 口座名義カナ
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
              ,xcm.install_account_number account_number           -- 設置先顧客コード
              ,xcm.publish_dept_code publish_base_code             -- 担当所属コード
              ,xlv2.location_name publish_base_name                -- 担当拠点名
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
--                ) contract_effect_date                             -- 契約書発効日
              , NVL(SUBSTR(   TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                            , 1
                            , INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1
                    ), gt_contract_date_ptn
                )     contract_effect_date                             -- 契約書発効日
-- == 2010/08/03 V1.9 Modified END   ===============================================================
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '')
                    || xlv2.address_line1) issue_belonging_address      -- 住所
              ,xlv2.location_name issue_belonging_name             -- 発行元所属名
              ,xsdh.install_support_amt install_support_amt        -- 初回設置協賛金
              ,xsdh.electricity_amount electricity_amount          -- 電気代
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(DECODE(xsdh.electricity_type
--                          , cv_electricity_type_1,  '月額 定額 '|| xsdh.electricity_amount || '円'
--                          , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う'
--                          , '')
--                ) electricity_information                          -- 電気代情報
--              ,(DECODE(xd.bank_transfer_fee_charge_div
--                          , cv_bank_trans_fee_div_1,  '振り込み手数料は甲の負担とする'
--                          , cv_bank_trans_fee_div_2, '振り込み手数料は乙の負担とする'
--                          , '振り込み手数料は発生致しません')
--                ) transfer_commission_info                         -- 振り込み手数料情報
              , ( DECODE( xsdh.electricity_type
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--                            , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円（税込）とする。'
                            , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円（'|| flv_tax.tax_type_name ||'）とする。'
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
                            , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う。'
                            , ''
                  )
                )       electricity_information                          -- 電気代情報
              , ( DECODE( xd.bank_transfer_fee_charge_div
                            , cv_bank_trans_fee_div_1, '甲の負担とする。'
                            , cv_bank_trans_fee_div_2, '乙の負担とする。'
                            , '発生致しません。'
                  )
                )       transfer_commission_info                         -- 振り込み手数料情報
-- == 2010/08/03 V1.9 Modified END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,flv_tax.tax_type_name                    tax_type_name                 -- 税区分名
              ,xcm.contract_number                      contract_number               -- 契約書番号
              ,xcoc.contract_other_custs_id             contract_other_custs_id       -- 契約先以外ID
              ,xcc.contract_name                        contract_name2                -- 契約者名2
              ,xcm.contract_effect_date                 contract_effect_date2         -- 契約書発効日2
              ,flv_tax.tax_type_name2                   tax_type_name2                -- 税区分名2
              ,CASE xsdh.install_supp_payment_type
                 WHEN cv_is_pay_type_single THEN xsdh.install_supp_amt
                 WHEN cv_is_pay_type_yearly THEN xsdh.install_supp_this_time
                 ELSE NULL
               END                                      install_supp_amt              -- 設置協賛金
              ,xsdh.install_supp_payment_date           install_supp_payment_date     -- 支払期日（設置協賛金）
              ,flv_is_fee.bk_chg_bearer_nm              install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,xcoc.install_supp_bk_number              install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,abb1.bank_name                           install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,xcoc.install_supp_branch_number          install_supp_branch_number    -- 支店番号（設置協賛金）
              ,abb1.bank_branch_name                    install_supp_branch_name      -- 支店名（設置協賛金）
              ,flv_is_koza.bk_acct_type                 install_supp_bk_acct_type     -- 口座種別（設置協賛金）
              ,xcoc.install_supp_bk_acct_number         install_supp_bk_acct_number   -- 口座番号（設置協賛金）
              ,xcoc.install_supp_bk_acct_name_alt       install_supp_bk_acct_name_alt -- 口座名義カナ（設置協賛金）
              ,xcoc.install_supp_bk_acct_name           install_supp_bk_acct_name     -- 口座名義漢字（設置協賛金）
              ,xcc.contract_name || gv_install_supp_pre install_supp_preamble         -- 前文（設置協賛金）
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN xsdh.intro_chg_amt
                 WHEN cv_ic_pay_type_per_sp THEN xsdh.intro_chg_per_sales_price
                 WHEN cv_ic_pay_type_per_p  THEN xsdh.intro_chg_per_piece
                 ELSE NULL
               END                                      intro_chg_amt                 -- 紹介手数料
              ,xsdh.intro_chg_payment_date              intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,xsdh.intro_chg_closing_date              intro_chg_closing_date        -- 締日（紹介手数料）
              ,flv_ic_mon.trans_month_name              intro_chg_trans_month         -- 振込月（紹介手数料）
              ,xsdh.intro_chg_trans_date                intro_chg_trans_date          -- 振込日（紹介手数料）
              ,xsdh.intro_chg_trans_name                intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,xsdh.intro_chg_trans_name_alt            intro_chg_trans_alt           -- 契約先以外名カナ（紹介手数料）
              ,flv_ic_fee.bk_chg_bearer_nm              intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,xcoc.intro_chg_bk_number                 intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,abb2.bank_name                           intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,xcoc.intro_chg_branch_number             intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,abb2.bank_branch_name                    intro_chg_branch_name         -- 支店名（紹介手数料）
              ,flv_ic_koza.bk_acct_type                 intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,xcoc.intro_chg_bk_acct_number            intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,xcoc.intro_chg_bk_acct_name_alt          intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,xcoc.intro_chg_bk_acct_name              intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre1
                 WHEN cv_ic_pay_type_per_sp THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 WHEN cv_ic_pay_type_per_p  THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 ELSE NULL
               END                                      intro_chg_preamble            -- 前文（紹介手数料）
              ,xsdh.electricity_amount                  electric_amt                  -- 電気代2
              ,xsdh.electric_closing_date               electric_closing_date         -- 締日（電気代）
              ,flv_e_mon.trans_month_name               electric_trans_month          -- 振込月（電気代）
              ,xsdh.electric_trans_date                 electric_trans_date           -- 振込日（電気代）
              ,xsdh.electric_trans_name                 electric_trans_name           -- 契約先以外名（電気代）
              ,xsdh.electric_trans_name_alt             electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,flv_e_fee.bk_chg_bearer_nm               electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,xcoc.electric_bk_number                  electric_bk_number            -- 銀行番号（電気代）
              ,abb3.bank_name                           electric_bk_name              -- 金融機関名（電気代）
              ,xcoc.electric_branch_number              electric_branch_number        -- 支店番号（電気代）
              ,abb3.bank_branch_name                    electric_branch_name          -- 支店名（電気代）
              ,flv_e_koza.bk_acct_type                  electric_bk_acct_type         -- 口座種別（電気代）
              ,xcoc.electric_bk_acct_number             electric_bk_acct_number       -- 口座番号（電気代）
              ,xcoc.electric_bk_acct_name_alt           electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,xcoc.electric_bk_acct_name               electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_fix THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"年"MM"月"DD"日"', 'nls_calendar = ''Japanese Imperial''')
                        || gv_electric_pre3
                 WHEN cv_electric_type_var THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"年"MM"月"DD"日"', 'nls_calendar = ''Japanese Imperial''')
                        || gv_electric_pre4
                 ELSE NULL
               END                                      electric_preamble             -- 前文（電気代）
              ,CASE xsdh.install_supp_type
                 WHEN cv_is_type_no  THEN cn_is_memo_no
                 WHEN cv_is_type_yes THEN cn_is_memo_yes
               END                                      install_supp_memo_flg         -- 覚書（設置協賛金）出力フラグ
              ,CASE xsdh.intro_chg_type
                 WHEN cv_ic_type_no  THEN cn_ic_memo_no
                 WHEN cv_ic_type_yes THEN
                   CASE xsdh.intro_chg_payment_type
                     WHEN cv_ic_pay_type_single THEN cn_ic_memo_single
                     WHEN cv_ic_pay_type_per_sp THEN cn_ic_memo_per_sp
                     WHEN cv_ic_pay_type_per_p  THEN cn_ic_memo_per_p
                   END
               END                                      intro_chg_memo_flg            -- 覚書（紹介手数料）出力フラグ
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_no  THEN cn_e_memo_no
                 WHEN cv_electric_type_fix THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_fix
                     ELSE                          cn_e_memo_cont
                   END
                 WHEN cv_electric_type_var THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_var
                     ELSE                          cn_e_memo_cont
                   END
               END                                      electric_memo_flg             -- 覚書（電気代）出力フラグ
              ,xsdh.install_supp_amt                    install_supp_amt2             -- 設置協賛金総額（発行元情報分岐用）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        INTO   o_rep_cont_data_rec.install_location              -- 設置ロケーション
              ,o_rep_cont_data_rec.contract_number               -- 契約書番号
              ,o_rep_cont_data_rec.contract_name                 -- 契約者名
              ,o_rep_cont_data_rec.contract_period               -- 契約期間
              ,o_rep_cont_data_rec.cancellation_offer_code       -- 契約解除申し出
              ,o_rep_cont_data_rec.other_content                 -- 特約事項
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- 手数料明細書送付先名
              ,o_rep_cont_data_rec.delivery_address              -- 送付先住所
              ,o_rep_cont_data_rec.install_name                  -- 設置先名
              ,o_rep_cont_data_rec.install_address               -- 設置先住所
              ,o_rep_cont_data_rec.install_date                  -- 設置日
              ,o_rep_cont_data_rec.bank_name                     -- 金融機関名
              ,o_rep_cont_data_rec.blanches_name                 -- 支店名
              ,o_rep_cont_data_rec.bank_account_number           -- 口座番号
              ,o_rep_cont_data_rec.bank_account_name_kana        -- 口座名義カナ
              ,o_rep_cont_data_rec.account_number                -- 顧客コード
              ,o_rep_cont_data_rec.publish_base_code             -- 担当拠点
              ,o_rep_cont_data_rec.publish_base_name             -- 担当拠点名
              ,o_rep_cont_data_rec.contract_effect_date          -- 契約書発効日
              ,o_rep_cont_data_rec.issue_belonging_address       -- 発行元所属住所
              ,o_rep_cont_data_rec.issue_belonging_name          -- 発行元所属名
              ,o_rep_cont_data_rec.install_support_amt           -- 設置協賛金
              ,o_rep_cont_data_rec.electricity_amount            -- 電気代
              ,o_rep_cont_data_rec.electricity_information       -- 電気代情報
              ,o_rep_cont_data_rec.transfer_commission_info      -- 振り込み手数料情報
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,o_rep_cont_data_rec.tax_type_name                 -- 税区分名
              ,o_rep_memo_data_rec.contract_number               -- 契約書番号
              ,o_rep_memo_data_rec.contract_other_custs_id       -- 契約先以外ID
              ,o_rep_memo_data_rec.contract_name                 -- 契約者名2
              ,o_rep_memo_data_rec.contract_effect_date          -- 契約書発効日2
              ,o_rep_memo_data_rec.tax_type_name                 -- 税区分名2
              ,o_rep_memo_data_rec.install_supp_amt              -- 設置協賛金
              ,o_rep_memo_data_rec.install_supp_payment_date     -- 支払期日（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_branch_number    -- 支店番号（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_branch_name      -- 支店名（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_acct_type     -- 口座種別（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_number   -- 口座番号（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_name_alt -- 口座名義カナ（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_name     -- 口座名義漢字（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_preamble         -- 前文（設置協賛金）
              ,o_rep_memo_data_rec.intro_chg_amt                 -- 紹介手数料
              ,o_rep_memo_data_rec.intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_closing_date        -- 締日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_month         -- 振込月（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_date          -- 振込日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_name_alt      -- 契約先以外名カナ（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_branch_name         -- 支店名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_preamble            -- 前文（紹介手数料）
              ,o_rep_memo_data_rec.electric_amt                  -- 電気代2
              ,o_rep_memo_data_rec.electric_closing_date         -- 締日（電気代）
              ,o_rep_memo_data_rec.electric_trans_month          -- 振込月（電気代）
              ,o_rep_memo_data_rec.electric_trans_date           -- 振込日（電気代）
              ,o_rep_memo_data_rec.electric_trans_name           -- 契約先以外名（電気代）
              ,o_rep_memo_data_rec.electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,o_rep_memo_data_rec.electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,o_rep_memo_data_rec.electric_bk_number            -- 銀行番号（電気代）
              ,o_rep_memo_data_rec.electric_bk_name              -- 金融機関名（電気代）
              ,o_rep_memo_data_rec.electric_branch_number        -- 支店番号（電気代）
              ,o_rep_memo_data_rec.electric_branch_name          -- 支店名（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_type         -- 口座種別（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_number       -- 口座番号（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,o_rep_memo_data_rec.electric_preamble             -- 前文（電気代）
              ,o_rep_memo_data_rec.install_supp_memo_flg         -- 覚書（設置協賛金）出力フラグ
              ,o_rep_memo_data_rec.intro_chg_memo_flg            -- 覚書（紹介手数料）出力フラグ
              ,o_rep_memo_data_rec.electric_memo_flg             -- 覚書（電気代）出力フラグ
              ,lt_install_supp_amt                               -- 設置協賛金総額（発行元情報分岐用）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        FROM   xxcso_cust_accounts_v      xcav     -- 顧客マスタビュー
              ,xxcso_contract_managements xcm      -- 契約管理テーブル
              ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
              ,xxcso_destinations         xd       -- 送付先テーブル
              ,xxcso_bank_accounts        xba      -- 銀行口座アドオンマスタ
              ,xxcso_locations_v2         xlv2     -- 事業所マスタ（最新）ビュー
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- 参照タイプ
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
-- == 2010/08/03 V1.9 Added START ===============================================================
              , ( SELECT  flvv.lookup_code    lookup_code
                        , flvv.meaning        bank_acct_type_name
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_kozatype
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(flvv.start_date_active)
                                              AND     TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                )                         flv       --  口座種別名取得
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_koza -- 口座種別（設置協賛金）
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_koza -- 口座種別（紹介手数料）
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_koza -- 口座種別（電気代）
              ,( SELECT flvv.lookup_code    tax_type
                       ,flvv.meaning        tax_type_name
                       ,flvv.description    tax_type_name2
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_sp_tax_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_tax   -- 税区分名取得
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_fee -- ＳＰ専決振込手数料負担区分（設置協賛金）
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_fee -- ＳＰ専決振込手数料負担区分（紹介手数料）
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_fee -- ＳＰ専決振込手数料負担区分（電気代）
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_mon  -- 振込月（紹介手数料）
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_mon  -- 振込月（電気代）
              ,xxcso_contract_other_custs xcoc      -- 契約先以外テーブル
              ,ap_bank_branches           abb1      -- 銀行支店マスタ1
              ,ap_bank_branches           abb2      -- 銀行支店マスタ2
              ,ap_bank_branches           abb3      -- 銀行支店マスタ3
              ,xxcso_contract_customers   xcc       -- 契約先テーブル
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.install_account_number = xcav.account_number
          AND  xcav.account_status = cv_active_status
          AND  xcav.party_status = cv_active_status
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+) = cv_delivery_div_1
          AND  xd.delivery_id = xba.delivery_id(+)
          AND  xlv2.dept_code = xcm.publish_dept_code
-- == 2010/08/03 V1.9 Added START ===============================================================
        AND     xba.bank_account_type       =   flv.lookup_code(+)
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          AND  xcm.contract_other_custs_id    = xcoc.contract_other_custs_id(+)
          AND  flv_tax.tax_type(+)            = NVL2(xsdh.tax_type, xsdh.tax_type, cv_in_tax)
          AND  abb1.bank_number(+)            = xcoc.install_supp_bk_number
          AND  abb1.bank_num(+)               = xcoc.install_supp_branch_number
          AND  abb2.bank_number(+)            = xcoc.intro_chg_bk_number
          AND  abb2.bank_num(+)               = xcoc.intro_chg_branch_number
          AND  abb3.bank_number(+)            = xcoc.electric_bk_number
          AND  abb3.bank_num(+)               = xcoc.electric_branch_number
          AND  xcc.contract_customer_id       = xcm.contract_customer_id
          AND  flv_is_fee.bk_chg_bearer_cd(+) = xcoc.install_supp_bk_chg_bearer
          AND  flv_ic_fee.bk_chg_bearer_cd(+) = xcoc.intro_chg_bk_chg_bearer
          AND  flv_e_fee.bk_chg_bearer_cd(+)  = xcoc.electric_bk_chg_bearer
          AND  flv_ic_mon.trans_month_code(+) = xsdh.intro_chg_trans_month
          AND  flv_e_mon.trans_month_code(+)  = xsdh.electric_trans_month
          AND  flv_is_koza.bk_acct_type_cd(+) = xcoc.install_supp_bk_acct_type
          AND  flv_ic_koza.bk_acct_type_cd(+) = xcoc.intro_chg_bk_acct_type
          AND  flv_e_koza.bk_acct_type_cd(+)  = xcoc.electric_bk_acct_type
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        ;
--
        /* 2009.11.12 K.Satomura I_E_658対応 START */
        --SELECT  (CASE
        --          WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
        --               xev2.position_name_old
        --          ELSE xev2.position_name_new
        --        END) issue_belonging_boss_position                 -- 発行元所属長職位名
        --        ,xev2.full_name issue_belonging_boss               -- 氏名
        --INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- 発行元所属長職位名
        --        ,o_rep_cont_data_rec.issue_belonging_boss          -- 氏名
        --FROM   xxcso_employees_v2         xev2     -- 従業員マスタ（最新）ビュー
        --WHERE  ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
        --           AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
        --       OR
        --        (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
        --           AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
        --       )
        --AND ROWNUM = 1;
        /* 2009.11.12 K.Satomura I_E_658対応 END */
--
      EXCEPTION
        -- 抽出結果が複数の場合
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_05             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_contract_num          -- トークンコード1
                         ,iv_token_value1 => gt_contract_number           -- トークン値1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- 複数以外のエラーの場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_contract_num          -- トークンコード1
                         ,iv_token_value1 => gt_contract_number           -- トークン値1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    -- ステータスが確定済、且つマスタ連携フラグが連携済の場合
    ELSE
      -- ===========================
      -- 契約関連情報取得（A-2-2-1）
      -- ===========================
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '＜＜ 契約関連情報：ステータスが確定済、且つマスタ連携フラグが連携済 ＞＞'
      );
--
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcasv.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                                  -- 設置ロケーション
              ,xcm.contract_number   contract_number                   -- 契約書番号
              /* 2009.09.14 M.Maruyama 0001355対応 START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc  -- 契約先テーブル
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name                     -- 契約書名
               ) || flvv_con.attr), 1, 660) contract_name              -- 契約書名
              /* 2009.09.14 M.Maruyama 0001355対応 END */
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--              ,xsdh.contract_year_date contract_period             -- 契約期間
              ,CASE xsdh.contract_year_date
                 WHEN 0 THEN 1
                 ELSE xsdh.contract_year_date
               END contract_period                                   -- 契約期間
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
              ,xcm.cancellation_offer_code cancellation_offer_code     -- 契約解除申し出
              ,xsdh.other_content other_content                        -- 特約事項
              /* 2009.10.15 D.Abe 0001536,0001537対応 START */
              --,pv.vendor_name sales_charge_details_delivery            -- 支払先名
              --,NVL2(pvs.zip, cv_post_mark || pvs.zip || ' ', '') || pvs.state || pvs.city
              ,pvs.attribute1 sales_charge_details_delivery            -- 支払先名
              ,NVL2(pvs.zip, cv_post_mark || pvs.zip || ' ', '')
              /* 2009.10.15 D.Abe 0001536,0001537対応 END */
                          || pvs.address_line1 || pvs.address_line2 delivery_address -- 送付先住所
              ,xcasv.party_name install_name                           -- 設置先顧客名
              ,NVL2(xcasv.postal_code, cv_post_mark || xcasv.postal_code || ' ', '') || xcasv.state || xcasv.city
                      || xcasv.address1 || xcasv.address2 install_address -- 設置先住所
              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
                ) install_date                                         -- 設置日
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
              --,xbav.bank_name bank_name                                -- 銀行名
              --,xbav.bank_branch_name blanches_name                     -- 支店名
              --,xbav.bank_account_num bank_account_number               -- 口座番号
              --,xbav.account_holder_name_alt bank_account_name_kana     -- 口座名義カナ
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.bank_name)
                ) bank_name                                            -- 銀行名
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.bank_branch_name)
                ) blanches_name                                        -- 支店名
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
-- == 2010/08/03 V1.9 Modified START ===============================================================
--                          , xbav.bank_account_num)
                          , flv.bank_acct_type_name || cv_space || xbav.bank_account_num)
-- == 2010/08/03 V1.9 Modified END   ===============================================================
                ) bank_account_number                                  -- 口座番号
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.account_holder_name_alt)
                ) bank_account_name_kana                               -- 口座名義カナ
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
              ,xcm.install_account_number account_number               -- 設置先顧客コード
              ,xcm.publish_dept_code publish_base_code                 -- 担当所属コード
              ,xlv2.location_name publish_base_name                    -- 担当拠点名
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
--                ) contract_effect_date                                 -- 契約書発効日
              , NVL(SUBSTR(   TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
                            , 1
                            , INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1
                    ), gt_contract_date_ptn
                )     contract_effect_date                             -- 契約書発効日
-- == 2010/08/03 V1.9 Modified END   ===============================================================
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') 
                  || xlv2.address_line1) issue_belonging_address       -- 住所
              ,xlv2.location_name issue_belonging_name                 -- 発行元所属名
              ,xsdh.install_support_amt install_support_amt            -- 初回設置協賛金
              ,xsdh.electricity_amount electricity_amount              -- 電気代
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,DECODE(xsdh.electricity_type
--                      , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円'
--                      , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う'
--                      , '') electricity_information                   -- 電気代情報
--              ,DECODE(pvs.bank_charge_bearer
--                      , cv_bank_trans_fee_div_1, '振り込み手数料は甲の負担とする'
--                      , cv_bank_trans_fee_div_2, '振り込み手数料は乙の負担とする'
--                      , '振り込み手数料は発生致しません') transfer_commission_info -- 振り込み手数料情報
              , DECODE(xsdh.electricity_type
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--                        , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円（税込）とする。'
                        , cv_electricity_type_1, '月額 定額 '|| xsdh.electricity_amount || '円（'|| flv_tax.tax_type_name ||'）とする。'
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
                        , cv_electricity_type_2, '販売機に関わる電気代は、実費にて乙が支払う。'
                        , ''
                )     electricity_information                     --  電気代情報
              , DECODE(pvs.bank_charge_bearer
                        , cv_bank_trans_fee_div_1, '甲の負担とする。'
                        , cv_bank_trans_fee_div_2, '乙の負担とする。'
                        , '発生致しません。'
                )     transfer_commission_info                    --  振り込み手数料情報
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,flv_tax.tax_type_name                    tax_type_name                 -- 税区分名
              ,xcm.contract_number                      contract_number               -- 契約書番号
              ,xcoc.contract_other_custs_id             contract_other_custs_id       -- 契約先以外ID
              ,xcc.contract_name                        contract_name2                -- 契約者名2
              ,xcm.contract_effect_date                 contract_effect_date2         -- 契約書発効日2
              ,flv_tax.tax_type_name2                   tax_type_name2                -- 税区分名2
              ,CASE xsdh.install_supp_payment_type
                 WHEN cv_is_pay_type_single THEN xsdh.install_supp_amt
                 WHEN cv_is_pay_type_yearly THEN xsdh.install_supp_this_time
                 ELSE NULL
               END                                      install_supp_amt              -- 設置協賛金
              ,xsdh.install_supp_payment_date           install_supp_payment_date     -- 支払期日（設置協賛金）
              ,flv_is_fee.bk_chg_bearer_nm              install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,xcoc.install_supp_bk_number              install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,abb1.bank_name                           install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,xcoc.install_supp_branch_number          install_supp_branch_number    -- 支店番号（設置協賛金）
              ,abb1.bank_branch_name                    install_supp_branch_name      -- 支店名（設置協賛金）
              ,flv_is_koza.bk_acct_type                 install_supp_bk_acct_type     -- 口座種別（設置協賛金）
              ,xcoc.install_supp_bk_acct_number         install_supp_bk_acct_number   -- 口座番号（設置協賛金）
              ,xcoc.install_supp_bk_acct_name_alt       install_supp_bk_acct_name_alt -- 口座名義カナ（設置協賛金）
              ,xcoc.install_supp_bk_acct_name           install_supp_bk_acct_name     -- 口座名義漢字（設置協賛金）
              ,xcc.contract_name || gv_install_supp_pre install_supp_preamble         -- 前文（設置協賛金）
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN xsdh.intro_chg_amt
                 WHEN cv_ic_pay_type_per_sp THEN xsdh.intro_chg_per_sales_price
                 WHEN cv_ic_pay_type_per_p  THEN xsdh.intro_chg_per_piece
                 ELSE NULL
               END                                      intro_chg_amt                 -- 紹介手数料
              ,xsdh.intro_chg_payment_date              intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,xsdh.intro_chg_closing_date              intro_chg_closing_date        -- 締日（紹介手数料）
              ,flv_ic_mon.trans_month_name              intro_chg_trans_month         -- 振込月（紹介手数料）
              ,xsdh.intro_chg_trans_date                intro_chg_trans_date          -- 振込日（紹介手数料）
              ,xsdh.intro_chg_trans_name                intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,xsdh.intro_chg_trans_name_alt            intro_chg_trans_alt           -- 契約先以外名カナ（紹介手数料）
              ,flv_ic_fee.bk_chg_bearer_nm              intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,xcoc.intro_chg_bk_number                 intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,abb2.bank_name                           intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,xcoc.intro_chg_branch_number             intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,abb2.bank_branch_name                    intro_chg_branch_name         -- 支店名（紹介手数料）
              ,flv_ic_koza.bk_acct_type                 intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,xcoc.intro_chg_bk_acct_number            intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,xcoc.intro_chg_bk_acct_name_alt          intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,xcoc.intro_chg_bk_acct_name              intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre1
                 WHEN cv_ic_pay_type_per_sp THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 WHEN cv_ic_pay_type_per_p  THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 ELSE NULL
               END                                      intro_chg_preamble            -- 前文（紹介手数料）
              ,xsdh.electricity_amount                  electric_amt                  -- 電気代2
              ,xsdh.electric_closing_date               electric_closing_date         -- 締日（電気代）
              ,flv_e_mon.trans_month_name               electric_trans_month          -- 振込月（電気代）
              ,xsdh.electric_trans_date                 electric_trans_date           -- 振込日（電気代）
              ,xsdh.electric_trans_name                 electric_trans_name           -- 契約先以外名（電気代）
              ,xsdh.electric_trans_name_alt             electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,flv_e_fee.bk_chg_bearer_nm               electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,xcoc.electric_bk_number                  electric_bk_number            -- 銀行番号（電気代）
              ,abb3.bank_name                           electric_bk_name              -- 金融機関名（電気代）
              ,xcoc.electric_branch_number              electric_branch_number        -- 支店番号（電気代）
              ,abb3.bank_branch_name                    electric_branch_name          -- 支店名（電気代）
              ,flv_e_koza.bk_acct_type                  electric_bk_acct_type         -- 口座種別（電気代）
              ,xcoc.electric_bk_acct_number             electric_bk_acct_number       -- 口座番号（電気代）
              ,xcoc.electric_bk_acct_name_alt           electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,xcoc.electric_bk_acct_name               electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_fix THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"年"MM"月"DD"日"', 'nls_calendar = ''Japanese Imperial''')
                        || gv_electric_pre3
                 WHEN cv_electric_type_var THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"年"MM"月"DD"日"', 'nls_calendar = ''Japanese Imperial''')
                        || gv_electric_pre4
                 ELSE NULL
               END                                      electric_preamble             -- 前文（電気代）
              ,CASE xsdh.install_supp_type
                 WHEN cv_is_type_no  THEN cn_is_memo_no
                 WHEN cv_is_type_yes THEN cn_is_memo_yes
               END                                      install_supp_memo_flg         -- 覚書（設置協賛金）出力フラグ
              ,CASE xsdh.intro_chg_type
                 WHEN cv_ic_type_no  THEN cn_ic_memo_no
                 WHEN cv_ic_type_yes THEN
                   CASE xsdh.intro_chg_payment_type
                     WHEN cv_ic_pay_type_single THEN cn_ic_memo_single
                     WHEN cv_ic_pay_type_per_sp THEN cn_ic_memo_per_sp
                     WHEN cv_ic_pay_type_per_p  THEN cn_ic_memo_per_p
                   END
               END                                      intro_chg_memo_flg            -- 覚書（紹介手数料）出力フラグ
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_no  THEN cn_e_memo_no
                 WHEN cv_electric_type_fix THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_fix
                     ELSE                          cn_e_memo_cont
                   END
                 WHEN cv_electric_type_var THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_var
                     ELSE                          cn_e_memo_cont
                   END
               END                                      electric_memo_flg             -- 覚書（電気代）出力フラグ
              ,xsdh.install_supp_amt                    install_supp_amt2             -- 設置協賛金総額（発行元情報分岐用）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
-- == 2010/08/03 V1.9 Modified END   ===============================================================
        INTO   o_rep_cont_data_rec.install_location              -- 設置ロケーション
              ,o_rep_cont_data_rec.contract_number               -- 契約書番号
              ,o_rep_cont_data_rec.contract_name                 -- 契約者名
              ,o_rep_cont_data_rec.contract_period               -- 契約期間
              ,o_rep_cont_data_rec.cancellation_offer_code       -- 契約解除申し出
              ,o_rep_cont_data_rec.other_content                 -- 特約事項
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- 手数料明細書送付先名
              ,o_rep_cont_data_rec.delivery_address              -- 送付先住所
              ,o_rep_cont_data_rec.install_name                  -- 設置先名
              ,o_rep_cont_data_rec.install_address               -- 設置先住所
              ,o_rep_cont_data_rec.install_date                  -- 設置日
              ,o_rep_cont_data_rec.bank_name                     -- 金融機関名
              ,o_rep_cont_data_rec.blanches_name                 -- 支店名
              ,o_rep_cont_data_rec.bank_account_number           -- 口座番号
              ,o_rep_cont_data_rec.bank_account_name_kana        -- 口座名義カナ
              ,o_rep_cont_data_rec.account_number                -- 顧客コード
              ,o_rep_cont_data_rec.publish_base_code             -- 担当拠点
              ,o_rep_cont_data_rec.publish_base_name             -- 担当拠点名
              ,o_rep_cont_data_rec.contract_effect_date          -- 契約書発効日
              ,o_rep_cont_data_rec.issue_belonging_address       -- 発行元所属住所
              ,o_rep_cont_data_rec.issue_belonging_name          -- 発行元所属名
              ,o_rep_cont_data_rec.install_support_amt           -- 設置協賛金
              ,o_rep_cont_data_rec.electricity_amount            -- 電気代
              ,o_rep_cont_data_rec.electricity_information       -- 電気代情報
              ,o_rep_cont_data_rec.transfer_commission_info      -- 振り込み手数料情報
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,o_rep_cont_data_rec.tax_type_name                 -- 税区分名
              ,o_rep_memo_data_rec.contract_number               -- 契約書番号
              ,o_rep_memo_data_rec.contract_other_custs_id       -- 契約先以外ID
              ,o_rep_memo_data_rec.contract_name                 -- 契約者名
              ,o_rep_memo_data_rec.contract_effect_date          -- 契約書発効日2
              ,o_rep_memo_data_rec.tax_type_name                 -- 税区分名2
              ,o_rep_memo_data_rec.install_supp_amt              -- 設置協賛金
              ,o_rep_memo_data_rec.install_supp_payment_date     -- 支払期日（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_branch_number    -- 支店番号（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_branch_name      -- 支店名（設置協賛金）
              ,o_rep_memo_data_rec.install_supp_bk_acct_type     -- 口座種別（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_number   -- 口座番号（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_name_alt -- 口座名義カナ（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_bk_acct_name     -- 口座名義漢字（紹介手数料）
              ,o_rep_memo_data_rec.install_supp_preamble         -- 前文（設置協賛金）
              ,o_rep_memo_data_rec.intro_chg_amt                 -- 紹介手数料
              ,o_rep_memo_data_rec.intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_closing_date        -- 締日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_month         -- 振込月（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_date          -- 振込日（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_trans_name_alt      -- 契約先以外名カナ（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_branch_name         -- 支店名（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,o_rep_memo_data_rec.intro_chg_preamble            -- 前文（紹介手数料）
              ,o_rep_memo_data_rec.electric_amt                  -- 電気代2
              ,o_rep_memo_data_rec.electric_closing_date         -- 締日（電気代）
              ,o_rep_memo_data_rec.electric_trans_month          -- 振込月（電気代）
              ,o_rep_memo_data_rec.electric_trans_date           -- 振込日（電気代）
              ,o_rep_memo_data_rec.electric_trans_name           -- 契約先以外名（電気代）
              ,o_rep_memo_data_rec.electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,o_rep_memo_data_rec.electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,o_rep_memo_data_rec.electric_bk_number            -- 銀行番号（電気代）
              ,o_rep_memo_data_rec.electric_bk_name              -- 金融機関名（電気代）
              ,o_rep_memo_data_rec.electric_branch_number        -- 支店番号（電気代）
              ,o_rep_memo_data_rec.electric_branch_name          -- 支店名（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_type         -- 口座種別（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_number       -- 口座番号（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,o_rep_memo_data_rec.electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,o_rep_memo_data_rec.electric_preamble             -- 前文（電気代）
              ,o_rep_memo_data_rec.install_supp_memo_flg         -- 覚書（設置協賛金）出力フラグ
              ,o_rep_memo_data_rec.intro_chg_memo_flg            -- 覚書（紹介手数料）出力フラグ
              ,o_rep_memo_data_rec.electric_memo_flg             -- 覚書（電気代）出力フラグ
              ,lt_install_supp_amt                               -- 設置協賛金総額（発行元情報分岐用）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
              ,xxcso_cust_acct_sites_v    xcasv    -- 顧客マスタサイトビュー
              ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
              --,xxcso_sp_decision_custs    xsdc     -- ＳＰ専決顧客テーブル
              ,xxcso_destinations         xd       -- 送付先テーブル
              /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
              ,xxcso_bank_accts_v         xbav     -- 銀行口座マスタ（最新）ビュー
              ,xxcso_locations_v2         xlv2     -- 事業所マスタ（最新）ビュー
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- 参照タイプ
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active,ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
               /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
               --,po_vendors pv                      -- 仕入先マスタ
               /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
               ,po_vendor_sites pvs                -- 仕入先サイトマスタ
-- == 2010/08/03 V1.9 Added START ===============================================================
              , ( SELECT  flvv.lookup_code    lookup_code
                        , flvv.meaning        bank_acct_type_name
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_kozatype
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(flvv.start_date_active)
                                              AND     TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                )                         flv       --  口座種別名取得
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_koza -- 口座種別（設置協賛金）
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_koza -- 口座種別（紹介手数料）
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_koza -- 口座種別（電気代）
              , ( SELECT  flvv.lookup_code    tax_type
                        , flvv.meaning        tax_type_name
                        , flvv.description    tax_type_name2
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_sp_tax_type
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                              AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
                )                         flv_tax   -- 税区分名取得
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_fee -- ＳＰ専決振込手数料負担区分（設置協賛金）
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_fee -- ＳＰ専決振込手数料負担区分（紹介手数料）
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_fee -- ＳＰ専決振込手数料負担区分（電気代）
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_mon  -- 振込月（紹介手数料）
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_mon  -- 振込月（電気代）
              ,xxcso_contract_other_custs xcoc      -- 契約先以外テーブル
              ,ap_bank_branches           abb1      -- 銀行支店マスタ1
              ,ap_bank_branches           abb2      -- 銀行支店マスタ2
              ,ap_bank_branches           abb3      -- 銀行支店マスタ3
              ,xxcso_contract_customers   xcc       -- 契約先テーブル
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
          --AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
          --AND  xsdc.sp_decision_customer_class = cv_sp_d_cust_class_3
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
          AND  xcm.install_account_id = xcasv.cust_account_id
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
          --AND  xsdc.customer_id = xbav.vendor_id(+)
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
          AND  xlv2.dept_code = xcm.publish_dept_code
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 START */
          AND  xd.supplier_id               = xbav.vendor_id(+)
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+)           = cv_delivery_div_1
          AND  pvs.vendor_id(+)             = xd.supplier_id
-- == 2010/08/03 V1.9 Added START ===============================================================
        AND   xbav.bank_account_type        =   flv.lookup_code(+)
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          AND  xcm.contract_other_custs_id    = xcoc.contract_other_custs_id(+)
          AND  flv_tax.tax_type(+)            = NVL2(xsdh.tax_type, xsdh.tax_type, cv_in_tax)
          AND  abb1.bank_number(+)            = xcoc.install_supp_bk_number
          AND  abb1.bank_num(+)               = xcoc.install_supp_branch_number
          AND  abb2.bank_number(+)            = xcoc.intro_chg_bk_number
          AND  abb2.bank_num(+)               = xcoc.intro_chg_branch_number
          AND  abb3.bank_number(+)            = xcoc.electric_bk_number
          AND  abb3.bank_num(+)               = xcoc.electric_branch_number
          AND  xcc.contract_customer_id       = xcm.contract_customer_id
          AND  flv_is_fee.bk_chg_bearer_cd(+) = xcoc.install_supp_bk_chg_bearer
          AND  flv_ic_fee.bk_chg_bearer_cd(+) = xcoc.intro_chg_bk_chg_bearer
          AND  flv_e_fee.bk_chg_bearer_cd(+)  = xcoc.electric_bk_chg_bearer
          AND  flv_ic_mon.trans_month_code(+) = xsdh.intro_chg_trans_month
          AND  flv_e_mon.trans_month_code(+)  = xsdh.electric_trans_month
          AND  flv_is_koza.bk_acct_type_cd(+) = xcoc.install_supp_bk_acct_type
          AND  flv_ic_koza.bk_acct_type_cd(+) = xcoc.intro_chg_bk_acct_type
          AND  flv_e_koza.bk_acct_type_cd(+)  = xcoc.electric_bk_acct_type
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        ;
          --AND  pv.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num)
          --AND  pvs.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num);
          /* 2010.03.02 K.Hosoi E_本稼動_01678対応 END */
--
        /* 2009.11.12 K.Satomura I_E_658対応 START */
        --SELECT  (CASE
        --          WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
        --               xev2.position_name_old
        --          ELSE xev2.position_name_new
        --        END)  issue_belonging_boss_position                -- 発行元所属長職位名
        --        ,xev2.full_name issue_belonging_boss               -- 氏名
        --INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- 発行元所属長職位名
        --        ,o_rep_cont_data_rec.issue_belonging_boss          -- 氏名
        --FROM    xxcso_employees_v2         xev2     -- 従業員マスタ（最新）ビュー
        --WHERE   ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
        --           AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
        --       OR
        --        (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
        --           AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
        --       )
        --AND ROWNUM = 1;
        /* 2009.11.12 K.Satomura I_E_658対応 END */
--
      EXCEPTION
        -- 抽出結果が複数の場合
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_05           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                         ,iv_token_value1 => gt_contract_number         -- トークン値1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- 複数以外のエラーの場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                         ,iv_token_value1 => gt_contract_number         -- トークン値1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
--
    /* 2009.11.12 K.Satomura I_E_658対応 START */
    -- =================================
    -- 発行元職位名取得
    -- =================================
    BEGIN
      SELECT (
               CASE
                 WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                   xev2.position_name_old
                 ELSE
                   xev2.position_name_new
               END
             ) issue_belonging_boss_position     -- 発行元所属長職位名
            ,xev2.full_name issue_belonging_boss -- 氏名
      INTO   o_rep_cont_data_rec.issue_belonging_boss_position -- 発行元所属長職位名
            ,o_rep_cont_data_rec.issue_belonging_boss          -- 氏名
      FROM   xxcso_employees_v2 xev2 -- 従業員マスタ（最新）ビュー
      WHERE  (
               (
                     TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                 AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                 AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code
               )
             OR
               (
                     TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                 AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                 AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code
               )
             )
      AND    ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        o_rep_cont_data_rec.issue_belonging_boss_position := NULL;
        o_rep_cont_data_rec.issue_belonging_boss          := NULL;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                       ,iv_token_value1 => gt_contract_number         -- トークン値1
                     );
        --
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
        --
    END;
    --
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- 設置先名
    o_rep_memo_data_rec.install_address  := o_rep_cont_data_rec.install_address;
    -- 設置先住所
    o_rep_memo_data_rec.install_name     := o_rep_cont_data_rec.install_name;
    -- 地域管理拠点取得
    BEGIN
      SELECT
        xhda_c.cur_dpt_cd AS area_mgr_base_code   -- 地域管理拠点コード
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
       ,SUBSTR(xhda_a.dpt3_name, 1, LENGTH(xhda_a.dpt3_name) -1 ) AS a_mgr_boss_org_nm  -- 発行元所属名(L3階層の末尾の"計"を除いた名称)
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
      INTO
        lt_area_mgr_base_cd                       -- 地域管理拠点コード
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
       ,lt_a_mgr_boss_org_nm                      -- 発行元所属名(L3階層の末尾の"計"を除いた名称)
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
      FROM xxcmm_hierarchy_dept_all_v xhda_a
      ,(SELECT
          xhda_b.cur_dpt_cd  AS cur_dpt_cd
         ,xhda_b.dpt3_cd     AS dpt3_cd
        FROM xxcmm_hierarchy_dept_all_v xhda_b    -- 全部門階層ビュー
        WHERE EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values   flv
                      WHERE  flv.lookup_type     = cv_lkup_sp_mgr_type
                        AND  flv.language        = 'JA'
                        AND  flv.attribute1      = cv_lkup_sp_mgr_memo
                        AND  ld_sysdate  BETWEEN NVL(flv.start_date_active ,ld_sysdate)
                                             AND NVL(flv.end_date_active   ,ld_sysdate)
                        AND  flv.enabled_flag    = cv_enabled_flag
                        AND  xhda_b.cur_dpt_cd   = flv.lookup_code
                     )
      ) xhda_c
      WHERE xhda_a.dpt3_cd    = xhda_c.dpt3_cd
      AND   xhda_a.cur_dpt_lv = 5
      AND   xhda_a.cur_dpt_cd = o_rep_cont_data_rec.publish_base_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_area_mgr_base_cd  := NULL;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                       ,iv_token_value1 => gt_contract_number         -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
    -- 地域営業本部長情報取得
    IF ( lt_area_mgr_base_cd IS NOT NULL) THEN
      BEGIN
        SELECT NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') || xlv2.address_line1  mgr_boss_org_ad -- 発行元所属住所
/* 2015/06/25 Ver1.12 Y.Shoji DEL START */
--              ,xlv2.location_name                                                         mgr_boss_org_nm -- 発行元所属名
/* 2015/06/25 Ver1.12 Y.Shoji DEL END */
              ,xev2.position_name_new                                                     mgr_boss_pos    -- 発行元所属長職位名
              ,xev2.full_name                                                             mgr_boss        -- 氏名
        INTO   lt_a_mgr_boss_org_ad                                                         -- 発行元所属住所
/* 2015/06/25 Ver1.12 Y.Shoji DEL START */
--              ,lt_a_mgr_boss_org_nm                                                         -- 発行元所属名
/* 2015/06/25 Ver1.12 Y.Shoji DEL END */
              ,lt_a_mgr_boss_pos                                                            -- 発行元所属長職位名
              ,lt_a_mgr_boss                                                                -- 氏名
        FROM   per_all_people_f        papf                                                 -- 従業員マスタ
              ,per_all_assignments_f   paaf                                                 -- アサイメントマスタ
              ,per_periods_of_service  ppos                                                 -- 従業員サービス期間マスタ
              ,xxcso_employees_v2      xev2                                                 -- 従業員マスタ（最新）ビュ
              ,xxcso_locations_v2      xlv2                                                 -- 事業所マスタ（最新）ビュー
        WHERE  papf.person_id             = paaf.person_id
        AND    paaf.period_of_service_id  = ppos.period_of_service_id
        AND    papf.effective_start_date  = ppos.date_start
        AND    papf.effective_start_date <= ld_sysdate
        AND    papf.effective_end_date   >= ld_sysdate
        AND    paaf.effective_start_date <= ld_sysdate
        AND    paaf.effective_end_date   >= ld_sysdate
        AND    ppos.actual_termination_date IS NULL
        AND    papf.attribute11           = gt_gen_mgr_pos_code
        AND    EXISTS (SELECT 'X'
                       FROM   fnd_lookup_values  flv
                       WHERE  flv.lookup_type  = cv_lkup_sp_mgr_type
                       AND    flv.language     = 'JA'
                       AND    flv.attribute1   = cv_lkup_sp_mgr_memo
                       AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flv.start_date_active ,ld_sysdate))
                                                  AND     TRUNC(NVL(flv.end_date_active   ,ld_sysdate))
                       AND    flv.enabled_flag = cv_enabled_flag
                       AND    flv.lookup_code  = paaf.ass_attribute5
                      )
        AND    paaf.ass_attribute5  = lt_area_mgr_base_cd
        AND    xev2.employee_number = papf.employee_number
        AND    xlv2.dept_code       = lt_area_mgr_base_cd;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_04           -- メッセージコード
                         ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                         ,iv_token_value1 => gt_contract_number         -- トークン値1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
    -- 統括本部長（副社長）情報取得
    BEGIN
      SELECT NVL2(flv_e_vice_org.zip, cv_post_mark || flv_e_vice_org.zip || ' ', '')
               || flv_e_vice_org.address_line1                                  vice_pres_org_ad  -- 発行元所属住所
            ,flv_e_vice_org.location_name                                       vice_pres_org_nm  -- 発行元所属名
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--            ,xev2.position_name_new                                             vice_pres_pos     -- 発行元所属長職位名
            ,flv_e_vice_org.position_name_new                                   vice_pres_pos     -- 発行元所属長職位名
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
            ,xev2.full_name                                                     vice_pres         -- 氏名
      INTO   lt_e_vice_pres_org_ad                                                        -- 発行元所属住所
            ,lt_e_vice_pres_org_nm                                                        -- 発行元所属名
            ,lt_e_vice_pres_pos                                                           -- 発行元所属長職位名
            ,lt_e_vice_pres                                                               -- 氏名
      FROM   xxcso_employees_v2 xev2                                                      -- 従業員マスタ（最新）ビュ
            ,(SELECT  flvv.lookup_code        dept_code
                     ,flvv.meaning            location_name
                     ,flvv.attribute1         zip
                     ,flvv.attribute2         address_line1
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
                     ,flvv.description        position_name_new        -- 発行元所属長職位名
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
                FROM  fnd_lookup_values_vl    flvv
                WHERE flvv.lookup_type      = cv_lkup_e_vice_org
                 AND  flvv.enabled_flag     = cv_enabled_flag
                 AND  TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                          AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
             ) flv_e_vice_org                                                             -- 統轄本部長所属
      WHERE xev2.work_base_code_new         = gt_e_vice_pres_base
      AND   xev2.qualify_code_new           = gt_e_vice_pres_qual
      AND   flv_e_vice_org.dept_code        = gt_e_vice_pres_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_contract_num        -- トークンコード1
                       ,iv_token_value1 => gt_contract_number         -- トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
    -- 発行元所属長職位、発行元所属長情報（設置協賛金）
    IF (lt_install_supp_amt < gn_is_amt_branch) THEN
      o_rep_memo_data_rec.install_supp_org_addr     := o_rep_cont_data_rec.issue_belonging_address;
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--      o_rep_memo_data_rec.install_supp_org_name     := o_rep_cont_data_rec.issue_belonging_name;
      -- 全角スペース6文字による印字位置の調整
      o_rep_memo_data_rec.install_supp_org_name     := LPAD('　', 12, '　') || o_rep_cont_data_rec.issue_belonging_name;
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
      o_rep_memo_data_rec.install_supp_org_boss_pos := o_rep_cont_data_rec.issue_belonging_boss_position;
      o_rep_memo_data_rec.install_supp_org_boss     := o_rep_cont_data_rec.issue_belonging_boss;
    ELSIF (lt_install_supp_amt < gn_is_amt_areamgr) THEN
      o_rep_memo_data_rec.install_supp_org_addr     := lt_a_mgr_boss_org_ad;
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--      o_rep_memo_data_rec.install_supp_org_name     := lt_a_mgr_boss_org_nm;
      -- 全角スペース6文字による印字位置の調整
      o_rep_memo_data_rec.install_supp_org_name     := LPAD('　', 12, '　') || lt_a_mgr_boss_org_nm;
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
      o_rep_memo_data_rec.install_supp_org_boss_pos := lt_a_mgr_boss_pos;
      o_rep_memo_data_rec.install_supp_org_boss     := lt_a_mgr_boss;
    ELSE
      o_rep_memo_data_rec.install_supp_org_addr     := lt_e_vice_pres_org_ad;
      o_rep_memo_data_rec.install_supp_org_name     := lt_e_vice_pres_org_nm;
      o_rep_memo_data_rec.install_supp_org_boss_pos := lt_e_vice_pres_pos;
      o_rep_memo_data_rec.install_supp_org_boss     := lt_e_vice_pres;
    END IF;
    -- 発行元所属長職位、発行元所属長情報（紹介手数料）
    o_rep_memo_data_rec.intro_chg_org_addr          := lt_a_mgr_boss_org_ad;
    o_rep_memo_data_rec.intro_chg_org_name          := lt_a_mgr_boss_org_nm;
    o_rep_memo_data_rec.intro_chg_org_boss_pos      := lt_a_mgr_boss_pos;
    o_rep_memo_data_rec.intro_chg_org_boss          := lt_a_mgr_boss;
    -- 発行元所属長職位、発行元所属長情報（電気代）
    o_rep_memo_data_rec.electric_org_addr           := o_rep_cont_data_rec.issue_belonging_address;
    o_rep_memo_data_rec.electric_org_name           := o_rep_cont_data_rec.issue_belonging_name;
    o_rep_memo_data_rec.electric_org_boss_pos       := o_rep_cont_data_rec.issue_belonging_boss_position;
    o_rep_memo_data_rec.electric_org_boss           := o_rep_cont_data_rec.issue_belonging_boss;
    --
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    /* 2009.11.12 K.Satomura I_E_658対応 END */
    -- =================================
    -- 販売手数料情報取得（A-2-1,2 -2）
    -- =================================
    BEGIN
--
      -- 変数初期化
      ln_lines_cnt             := 0;               -- 明細件数
      ln_bm1_bm_rate           := 0;               -- ＢＭ１ＢＭ率
      ln_bm1_bm_amount         := 0;               -- ＢＭ１ＢＭ金額
-- == 2010/08/03 V1.9 Added START ===============================================================
--      lb_bm1_bm_rate           := TRUE;            -- ＢＭ１ＢＭ率による定率判断フラグ
--      lb_bm1_bm_amount         := TRUE;            -- ＢＭ１ＢＭ金額による定率判断フラグ
      lb_bm1_bm_rate           := FALSE;           -- ＢＭ１ＢＭ率による定率判断フラグ
      lb_bm1_bm_amount         := FALSE;           -- ＢＭ１ＢＭ金額による定率判断フラグ
-- == 2010/08/03 V1.9 Added END   ===============================================================
      lb_bm1_bm                := FALSE;           -- 販売手数料有無フラグ(TRUE:有,FALSE:無)
--
      -- ＳＰ専決明細カーソルオープン
      OPEN l_sales_charge_cur;
--
      <<sales_charge_loop>>
      LOOP
        FETCH l_sales_charge_cur INTO l_sales_charge_rec;
--
        EXIT WHEN l_sales_charge_cur%NOTFOUND
          OR l_sales_charge_cur%ROWCOUNT = 0;
--
        -- ＢＭ１ＢＭ率、金額、取引条件区分、締め日、払い月、払い日
        IF (ln_lines_cnt = 0) THEN
          -- 取引条件区分
          lv_cond_business_type := l_sales_charge_rec.condition_business_type;
          -- 売上別
          IF (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_uri_rate;
          -- 容器別
          ELSIF (lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_youki_rate;
          END IF;
          --
-- == 2010/08/03 V1.9 Added START ===============================================================
          lv_condition_content_type :=  l_sales_charge_rec.condition_content_type;        --  全容器一律区分
-- == 2010/08/03 V1.9 Added END   ===============================================================
--
          /* 2009.11.30 T.Maruyama E_本稼動_00193 START */
          ---- ＢＭ１ＢＭ率、金額
          --IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
          --  lb_bm1_bm_rate := FALSE;
          --ELSE
          --  ln_bm1_bm_rate := l_sales_charge_rec.bm1_bm_rate;
          --END IF;
          --IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
          --  lb_bm1_bm_amount := FALSE;
          --ELSE
          --  ln_bm1_bm_amount := l_sales_charge_rec.bm1_bm_amount;
          --END IF;
          /* 2009.11.30 T.Maruyama E_本稼動_00193 END */
--
          -- 締め日
          o_rep_cont_data_rec.close_day_code := l_sales_charge_rec.close_day_code;
          -- 払い月
          o_rep_cont_data_rec.transfer_month_code := l_sales_charge_rec.transfer_month_code;
          -- 払い日
          o_rep_cont_data_rec.transfer_day_code := l_sales_charge_rec.transfer_day_code;
        ELSE
          /* 2009.11.30 T.Maruyama E_本稼動_00193 START */
          NULL;
          ---- ＢＭ１ＢＭ率
          --IF (lb_bm1_bm_rate = TRUE) THEN
          --  IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
          --    lb_bm1_bm_rate := FALSE;
          --  ELSIF (ln_bm1_bm_rate <> l_sales_charge_rec.bm1_bm_rate) THEN
          ----    lb_bm1_bm_rate := FALSE;
          --  END IF;
          --END IF;
          ---- ＢＭ１ＢＭ金額
          --IF (lb_bm1_bm_amount = TRUE) THEN
          --  IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
          --    lb_bm1_bm_amount := FALSE;
          --  ELSIF (ln_bm1_bm_amount <> l_sales_charge_rec.bm1_bm_amount) THEN
          --    lb_bm1_bm_amount := FALSE;
          --  END IF;
          --END IF;
          /* 2009.11.30 T.Maruyama E_本稼動_00193 END */
        END IF;
         
        
        -- 販売手数料有無チェック
        IF ((l_sales_charge_rec.bm1_bm_rate IS NOT NULL AND
              l_sales_charge_rec.bm1_bm_rate <> '0') OR
             (l_sales_charge_rec.bm1_bm_amount IS  NOT NULL AND
              l_sales_charge_rec.bm1_bm_amount <> '0')
            ) THEN
          -- 条件内容セット
          IF (o_rep_cont_data_rec.condition_contents_1 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_1 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_2 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_3 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_4 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_5 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_6 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_7 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_8 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_9 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_10 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_11 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_12 := l_sales_charge_rec.condition_contents;
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          ELSIF (o_rep_cont_data_rec.condition_contents_13 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_13 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_14 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_14 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_15 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_15 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_16 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_16 := l_sales_charge_rec.condition_contents;
          ELSIF (o_rep_cont_data_rec.condition_contents_17 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_17 := l_sales_charge_rec.condition_contents;
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          END IF;
          lb_bm1_bm := TRUE;
--
          -- 件数計算
          ln_lines_cnt := ln_lines_cnt + 1;
        ELSIF (lb_bm1_bm = TRUE) THEN
          lb_bm1_bm := TRUE;
        ELSE
          lb_bm1_bm := FALSE;
        END IF;
--
      END LOOP sales_charge_loop;
--
      -- カーソル・クローズ
      CLOSE l_sales_charge_cur;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '販売手数料情報件数：' || ln_lines_cnt || '件'
      );
--
-- == 2010/08/03 V1.9 Modified START ===============================================================
--      -- 明細件数が1件を超える場合
--      IF (ln_lines_cnt > 1) THEN
      IF  (     (     ln_lines_cnt  >  1
                  OR  lv_condition_content_type <> '0'
                )
            AND lv_cond_business_type IN(cv_cond_b_type_3, cv_cond_b_type_4)
          )
      THEN
        --  明細２件以上または、全容器一律、且つ取引条件「容器別」の場合
-- == 2010/08/03 V1.9 Modified END   ===============================================================
--
        /* 2009.11.30 T.Maruyama E_本稼動_00193 START */
        -- ＢＭ１ＢＭ率 定率判断
        -- ZEROおよびNULLでない値の種類数
        -- 0件･･･該当無しのため定額でない
        -- 1件･･･定額
        -- 2件以上･･･複数条件のため定額でない
        ln_work_cnt := 0;
        ln_work_cnt_ritu := 0;
        SELECT count(*)
        INTO   ln_work_cnt
        FROM   (
                 SELECT distinct xsdl.bm1_bm_rate
                 FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
                       ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
                       ,xxcso_sp_decision_lines    xsdl     -- ＳＰ専決明細テーブル
                 WHERE  xcm.contract_management_id = gt_con_mng_id
                 AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
                 AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
                 AND    xsdh.condition_business_type  IN 
                        (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
                 AND    (    (xsdl.bm1_bm_rate IS NOT NULL) 
                         AND (xsdl.bm1_bm_rate <> 0) )
        );
--
        ln_work_cnt_ritu := ln_work_cnt;
--
        IF ln_work_cnt = 1 THEN
          lb_bm1_bm_rate := TRUE;
          --率の値を取得
          SELECT distinct xsdl.bm1_bm_rate
          INTO   ln_bm1_bm_rate
          FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
                ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
                ,xxcso_sp_decision_lines    xsdl     -- ＳＰ専決明細テーブル
          WHERE  xcm.contract_management_id = gt_con_mng_id
          AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
          AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
          AND    xsdh.condition_business_type  IN 
                 (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
          AND    (    (xsdl.bm1_bm_rate IS NOT NULL) 
                  AND (xsdl.bm1_bm_rate <> 0) );
        ELSE
          lb_bm1_bm_rate := FALSE;
        END IF;
--
        -- ＢＭ１ＢＭ金額 定率判断
        ln_work_cnt := 0;
        ln_work_cnt_gaku := 0;
        SELECT count(*)
        INTO   ln_work_cnt
        FROM   (
                 SELECT distinct xsdl.bm1_bm_amount
                 FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
                       ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
                       ,xxcso_sp_decision_lines    xsdl     -- ＳＰ専決明細テーブル
                 WHERE  xcm.contract_management_id = gt_con_mng_id
                 AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
                 AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
                 AND    xsdh.condition_business_type  IN 
                        (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
                 AND    (    (xsdl.bm1_bm_amount IS NOT NULL) 
                         AND (xsdl.bm1_bm_amount <> 0) )
        );
--
        ln_work_cnt_gaku := ln_work_cnt;
--
        IF ln_work_cnt = 1 THEN
          lb_bm1_bm_amount := TRUE;
          --金額の値を取得
          SELECT distinct xsdl.bm1_bm_amount
          INTO   ln_bm1_bm_amount
          FROM   xxcso_contract_managements xcm      -- 契約管理テーブル
                ,xxcso_sp_decision_headers  xsdh     -- ＳＰ専決ヘッダテーブル
                ,xxcso_sp_decision_lines    xsdl     -- ＳＰ専決明細テーブル
          WHERE  xcm.contract_management_id = gt_con_mng_id
          AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
          AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
          AND    xsdh.condition_business_type  IN 
                 (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
          AND    (    (xsdl.bm1_bm_amount IS NOT NULL) 
                  AND (xsdl.bm1_bm_amount <> 0) );
        ELSE
          lb_bm1_bm_amount := FALSE;
        END IF;
        
        --率もしくは額のどちらかだけが１種類の場合だけ定率とする
        IF ((ln_work_cnt_ritu = 1) AND (ln_work_cnt_gaku = 0))
        OR ((ln_work_cnt_ritu = 0) AND (ln_work_cnt_gaku = 1)) THEN
          NULL;
        ELSE
          lb_bm1_bm_rate := FALSE;
          lb_bm1_bm_amount := FALSE;
        END IF;
        /* 2009.11.30 T.Maruyama E_本稼動_00193 END */
        
        
-- == 2010/08/03 V1.9 Modified START ===============================================================
--        -- 容器別、定率の場合
--        IF ((lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--               AND (lb_bm1_bm_rate OR lb_bm1_bm_amount)) THEN
        IF  (     lb_bm1_bm_rate
              OR  lb_bm1_bm_amount
              OR  lv_condition_content_type <> '0'
            )
        THEN
          --  全容器一律、または、定率
-- == 2010/08/03 V1.9 Modified END   ===============================================================
          -- ＢＭ１ＢＭ率
-- == 2010/08/03 V1.9 Modified START ===============================================================
--          IF (lb_bm1_bm_rate) THEN
--            lv_cond_conts_tmp := '販売金額につき、１本 ' || ln_bm1_bm_rate || '%を支払う';
--          -- ＢＭ１ＢＭ金額
--          ELSE
--            lv_cond_conts_tmp := '販売金額につき、１本 ' || ln_bm1_bm_amount || '円を支払う';
--          END IF;
          IF  (     lb_bm1_bm_rate
                OR  lv_condition_content_type = '1'
              )
          THEN
            lv_cond_conts_tmp := '販売金額に対し、' || ln_bm1_bm_rate || '%とする。';
          -- ＢＭ１ＢＭ金額
          ELSE
            lv_cond_conts_tmp := '販売数量に対し、１本当たり ' || ln_bm1_bm_amount || '円とする。';
          END IF;
-- == 2010/08/03 V1.9 Modified END   ===============================================================
          -- 取引条件（定率）
          o_rep_cont_data_rec.exchange_condition := cv_tei_rate;
          -- 条件内容セット
          o_rep_cont_data_rec.condition_contents_1 := lv_cond_conts_tmp;
          o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;   -- 以下余白
          o_rep_cont_data_rec.condition_contents_3 := NULL;
          o_rep_cont_data_rec.condition_contents_4 := NULL;
          o_rep_cont_data_rec.condition_contents_5 := NULL;
          o_rep_cont_data_rec.condition_contents_6 := NULL;
          o_rep_cont_data_rec.condition_contents_7 := NULL;
          o_rep_cont_data_rec.condition_contents_8 := NULL;
          o_rep_cont_data_rec.condition_contents_9 := NULL;
          o_rep_cont_data_rec.condition_contents_10 := NULL;
          o_rep_cont_data_rec.condition_contents_11 := NULL;
          o_rep_cont_data_rec.condition_contents_12 := NULL;
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          o_rep_cont_data_rec.condition_contents_13 := NULL;
          o_rep_cont_data_rec.condition_contents_14 := NULL;
          o_rep_cont_data_rec.condition_contents_15 := NULL;
          o_rep_cont_data_rec.condition_contents_16 := NULL;
          o_rep_cont_data_rec.condition_contents_17 := NULL;
/* 2014/02/03 Ver1.10 S.Niki ADD END */
--
-- == 2010/08/03 V1.9 Modified START ===============================================================
          -- ログ出力
--          fnd_file.put_line(
--             which  => FND_FILE.LOG
--            ,buff   => '' || CHR(10) || '販売手数料情報が容器別、定率です。'
--          );
          IF  (lv_condition_content_type <> '0')  THEN
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => '' || CHR(10) || '販売手数料情報が容器別、全容器一律です。'
            );
          ELSE
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => '' || CHR(10) || '販売手数料情報が容器別、定率です。'
            );
          END IF;
-- == 2010/08/03 V1.9 Modified END   ===============================================================
--
-- == 2010/08/03 V1.9 Deleted START ===============================================================
--        ELSE
--          -- 条件内容が12件に満たない場合、最終行に「以下余白」をセット
--          IF (ln_lines_cnt < 12) THEN
--          -- 条件内容セット
--            IF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_3 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_4 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_5 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_6 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_7 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_8 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_9 := cv_cond_conts_space;    -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_10 := cv_cond_conts_space;   -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_11 := cv_cond_conts_space;   -- 以下余白
--            ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_12 := cv_cond_conts_space;   -- 以下余白
--            END IF;
--          END IF;
-- == 2010/08/03 V1.9 Deleted END   ===============================================================
        END IF;
        --
      END IF;
-- == 2010/08/03 V1.9 Added START ===============================================================
/* 2014/02/03 Ver1.10 S.Niki MOD START */
--      --  条件内容が12件に満たない場合、販売手数料但書と「以下余白」をセット
--      IF  (ln_lines_cnt < 12) THEN
      --  条件内容が最大行に満たない場合、販売手数料但書と「以下余白」をセット
      IF  (ln_lines_cnt < cn_max_line) THEN
/* 2014/02/03 Ver1.10 S.Niki MOD END */
        IF    (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
          --  売上別
          IF    (o_rep_cont_data_rec.condition_contents_2   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_2  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_3  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_3   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_3  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_4  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_4   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_4  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_5  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_5   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_5  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_6  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_6   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_6  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_7  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_7   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_7  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_8  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_8   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_8  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_9  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_9   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_9  :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_10 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_10  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_10 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_11 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_11  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_11 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_12 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_12  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_12 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
/* 2014/02/03 Ver1.10 S.Niki ADD START */
            o_rep_cont_data_rec.condition_contents_13 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_13  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_13 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_14 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_14  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_14 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_15 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_15  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_15 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_16 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_16  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_16 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
            o_rep_cont_data_rec.condition_contents_17 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_17  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_17 :=  gt_terms_note_price;      --  販売手数料但書（売価別）
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          END IF;
          --
        ELSIF (     lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)
                AND lv_condition_content_type = '0'
                AND NOT(lb_bm1_bm_rate)
                AND NOT(lb_bm1_bm_amount)
              )
        THEN
          --  容器別（全容器一律以外、かつ、定率以外）
          IF    (o_rep_cont_data_rec.condition_contents_2   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_2  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_3  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_3   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_3  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_4  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_4   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_4  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_5  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_5   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_5  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_6  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_6   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_6  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_7  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_7   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_7  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_8  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_8   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_8  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_9  :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_9   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_9  :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_10 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_10  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_10 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_11 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_11  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_11 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_12 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_12  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_12 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
/* 2014/02/03 Ver1.10 S.Niki ADD START */
            o_rep_cont_data_rec.condition_contents_13 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_13  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_13 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_14 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_14  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_14 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_15 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_15  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_15 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_16 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_16  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_16 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
            o_rep_cont_data_rec.condition_contents_17 :=  cv_cond_conts_space;      --  以下余白
          ELSIF (o_rep_cont_data_rec.condition_contents_17  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_17 :=  gt_terms_note_ves;        --  販売手数料但書（容器別）
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          END IF;
        END IF;
      END IF;
-- == 2010/08/03 V1.9 Added END   ===============================================================
--
      -- 販売手数料有無の設定
        o_rep_cont_data_rec.condition_contents_flag := lb_bm1_bm;
      -- 設置協賛金有り
      /* 2009.04.27 K.Satomura T1_0705対応 START */
      --IF (o_rep_cont_data_rec.install_support_amt IS NOT NULL) THEN
      IF ((o_rep_cont_data_rec.install_support_amt IS NOT NULL)
        AND (o_rep_cont_data_rec.install_support_amt <> 0))
      THEN
      /* 2009.04.27 K.Satomura T1_0705対応 END */
        o_rep_cont_data_rec.install_support_amt_flag := TRUE;
      -- 設置協賛金無し
      ELSE
        o_rep_cont_data_rec.install_support_amt_flag := FALSE;
      END IF;
      -- 電気代情報有り
      IF (o_rep_cont_data_rec.electricity_amount IS NOT NULL) THEN
        o_rep_cont_data_rec.electricity_information_flag := TRUE;
      -- 電気代情報無し
      ELSE
        o_rep_cont_data_rec.electricity_information_flag := FALSE;
      END IF;
--
    EXCEPTION
      -- 抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        -- カーソル・クローズ
        IF (l_sales_charge_cur%ISOPEN) THEN
          CLOSE l_sales_charge_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                   -- トークンコード1
                       ,iv_token_value1 => cv_sp_decision_lines         -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg               -- トークンコード2
                       ,iv_token_value2 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : ワークテーブルに登録(A-3)
   ***********************************************************************************/
  PROCEDURE insert_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,i_rep_memo_data_rec    IN         g_rep_memo_data_rtype  -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_data';     -- プログラム名
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
    cv_tbl_nm            CONSTANT VARCHAR2(100) := '自動販売機設置契約書帳票ワークテーブル';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    cv_memo_tbl_nm       CONSTANT VARCHAR2(100) := '覚書帳票ワークテーブル';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- ワークテーブルに登録
      INSERT INTO xxcso_rep_auto_sale_cont
        (  install_location                 -- 設置ロケーション
          ,contract_number                  -- 契約書番号
          ,contract_name                    -- 契約者名
          ,contract_period                  -- 契約期間
          ,cancellation_offer_code          -- 契約解除申し出
          ,other_content                    -- 特約事項
          ,sales_charge_details_delivery    -- 手数料明細書送付先名
          ,delivery_address                 -- 送付先住所
          ,install_name                     -- 設置先名
          ,install_address                  -- 設置先住所
          ,install_date                     -- 設置日
          ,bank_name                        -- 金融機関名
          ,blanches_name                    -- 支店名
          ,account_number                   -- 顧客コード
          ,bank_account_number              -- 口座番号
          ,bank_account_name_kana           -- 口座名義カナ
          ,publish_base_code                -- 担当拠点
          ,publish_base_name                -- 担当拠点名
          ,contract_effect_date             -- 契約書発効日
          ,issue_belonging_address          -- 発行元所属住所
          ,issue_belonging_name             -- 発行元所属名
          ,issue_belonging_boss_position    -- 発行元所属長職位名
          ,issue_belonging_boss             -- 発行元所属長名
          ,close_day_code                   -- 締日
          ,transfer_month_code              -- 払い月
          ,transfer_day_code                -- 払い日
          ,exchange_condition               -- 取引条件
          ,condition_contents_1             -- 条件内容1
          ,condition_contents_2             -- 条件内容2
          ,condition_contents_3             -- 条件内容3
          ,condition_contents_4             -- 条件内容4
          ,condition_contents_5             -- 条件内容5
          ,condition_contents_6             -- 条件内容6
          ,condition_contents_7             -- 条件内容7
          ,condition_contents_8             -- 条件内容8
          ,condition_contents_9             -- 条件内容9
          ,condition_contents_10            -- 条件内容10
          ,condition_contents_11            -- 条件内容11
          ,condition_contents_12            -- 条件内容12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          ,condition_contents_13            -- 条件内容13
          ,condition_contents_14            -- 条件内容14
          ,condition_contents_15            -- 条件内容15
          ,condition_contents_16            -- 条件内容16
          ,condition_contents_17            -- 条件内容17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          ,install_support_amt              -- 設置協賛金
          ,electricity_information          -- 電気代情報
          ,transfer_commission_info         -- 振り込み手数料情報
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          ,tax_type_name                    -- 税区分名
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
          ,created_by                       -- 作成者
          ,creation_date                    -- 作成日
          ,last_updated_by                  -- 最終更新者
          ,last_update_date                 -- 最終更新日
          ,last_update_login                -- 最終更新ログイン
          ,request_id                       -- 要求id
          ,program_application_id           -- アプリケーションid
          ,program_id                       -- プログラムid
          ,program_update_date              -- プログラム更新日
        )
      VALUES
        (  i_rep_cont_data_rec.install_location                 -- 設置ロケーション
          ,i_rep_cont_data_rec.contract_number                  -- 契約書番号
          ,i_rep_cont_data_rec.contract_name                    -- 契約者名
          ,i_rep_cont_data_rec.contract_period                  -- 契約期間
          ,i_rep_cont_data_rec.cancellation_offer_code          -- 契約解除申し出
          ,i_rep_cont_data_rec.other_content                    -- 特約事項
          ,i_rep_cont_data_rec.sales_charge_details_delivery    -- 手数料明細書送付先名
          ,i_rep_cont_data_rec.delivery_address                 -- 送付先住所
          ,i_rep_cont_data_rec.install_name                     -- 設置先名
          ,i_rep_cont_data_rec.install_address                  -- 設置先住所
          ,i_rep_cont_data_rec.install_date                     -- 設置日
          ,i_rep_cont_data_rec.bank_name                        -- 金融機関名
          ,i_rep_cont_data_rec.blanches_name                    -- 支店名
          ,i_rep_cont_data_rec.account_number                   -- 顧客コード
          ,i_rep_cont_data_rec.bank_account_number              -- 口座番号
          ,i_rep_cont_data_rec.bank_account_name_kana           -- 口座名義カナ
          ,i_rep_cont_data_rec.publish_base_code                -- 担当拠点
          ,i_rep_cont_data_rec.publish_base_name                -- 担当拠点名
          ,i_rep_cont_data_rec.contract_effect_date             -- 契約書発効日
          ,i_rep_cont_data_rec.issue_belonging_address          -- 発行元所属住所
          ,i_rep_cont_data_rec.issue_belonging_name             -- 発行元所属名
          ,i_rep_cont_data_rec.issue_belonging_boss_position    -- 発行元所属長職位名
          ,i_rep_cont_data_rec.issue_belonging_boss             -- 発行元所属長名
          ,i_rep_cont_data_rec.close_day_code                   -- 締日
          ,i_rep_cont_data_rec.transfer_month_code              -- 払い月
          ,i_rep_cont_data_rec.transfer_day_code                -- 払い日
          ,i_rep_cont_data_rec.exchange_condition               -- 取引条件
          ,i_rep_cont_data_rec.condition_contents_1             -- 条件内容1
          ,i_rep_cont_data_rec.condition_contents_2             -- 条件内容2
          ,i_rep_cont_data_rec.condition_contents_3             -- 条件内容3
          ,i_rep_cont_data_rec.condition_contents_4             -- 条件内容4
          ,i_rep_cont_data_rec.condition_contents_5             -- 条件内容5
          ,i_rep_cont_data_rec.condition_contents_6             -- 条件内容6
          ,i_rep_cont_data_rec.condition_contents_7             -- 条件内容7
          ,i_rep_cont_data_rec.condition_contents_8             -- 条件内容8
          ,i_rep_cont_data_rec.condition_contents_9             -- 条件内容9
          ,i_rep_cont_data_rec.condition_contents_10            -- 条件内容10
          ,i_rep_cont_data_rec.condition_contents_11            -- 条件内容11
          ,i_rep_cont_data_rec.condition_contents_12            -- 条件内容12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          ,i_rep_cont_data_rec.condition_contents_13            -- 条件内容13
          ,i_rep_cont_data_rec.condition_contents_14            -- 条件内容14
          ,i_rep_cont_data_rec.condition_contents_15            -- 条件内容15
          ,i_rep_cont_data_rec.condition_contents_16            -- 条件内容16
          ,i_rep_cont_data_rec.condition_contents_17            -- 条件内容17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          ,i_rep_cont_data_rec.install_support_amt              -- 設置協賛金
          ,i_rep_cont_data_rec.electricity_information          -- 電気代情報
          ,i_rep_cont_data_rec.transfer_commission_info         -- 振り込み手数料情報
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          ,i_rep_cont_data_rec.tax_type_name                    -- 税区分名
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
          ,cn_created_by                                        -- 作成者
          ,cd_creation_date                                     -- 作成日
          ,cn_last_updated_by                                   -- 最終更新者
          ,cd_last_update_date                                  -- 最終更新日
          ,cn_last_update_login                                 -- 最終更新ログイン
          ,cn_request_id                                        -- 要求ＩＤ
          ,cn_program_application_id                            -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝ
          ,cn_program_id                                        -- ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑＩＤ
          ,cd_program_update_date                               -- ﾌﾟﾛｸﾞﾗﾑ更新日
        );
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '契約書データをワークテーブルに登録しました。'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                          --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_07                     --メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                 ,iv_token_value1 => cv_tbl_nm                            --トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                 ,iv_token_value2 => SQLERRM                              --トークン値2
                 ,iv_token_name3  => cv_tkn_contract_num                  --トークンコード3
                 ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --トークン値3
                 ,iv_token_name4  => cv_tkn_request_id                    --トークンコード3
                 ,iv_token_value4 => cn_request_id                        --トークン値3
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- 覚書帳票ワークテーブル出力
    BEGIN
      -- ワークテーブルに登録
      INSERT INTO xxcso_rep_memorandum(
               contract_number               -- 契約書番号
              ,contract_other_custs_id       -- 契約先以外ID
              ,contract_name                 -- 契約者名
              ,contract_effect_date          -- 契約書発効日
              ,install_name                  -- 設置先名
              ,install_address               -- 設置先住所
              ,tax_type_name                 -- 税区分名
              ,install_supp_amt              -- 設置協賛金
              ,install_supp_payment_date     -- 支払期日（設置協賛金）
              ,install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,install_supp_branch_number    -- 支店番号（設置協賛金）
              ,install_supp_branch_name      -- 支店名（設置協賛金）
              ,install_supp_bk_acct_type     -- 口座種別（設置協賛金）
              ,install_supp_bk_acct_number   -- 口座番号（設置協賛金）
              ,install_supp_bk_acct_name_alt -- 口座名義カナ（設置協賛金）
              ,install_supp_bk_acct_name     -- 口座名義漢字（設置協賛金）
              ,install_supp_org_addr         -- 発行元所属住所（設置協賛金）
              ,install_supp_org_name         -- 発行元所属名（設置協賛金）
              ,install_supp_org_boss_pos     -- 発行元所属長職位名（設置協賛金）
              ,install_supp_org_boss         -- 発行元所属長名（設置協賛金）
              ,install_supp_preamble         -- 前文（設置協賛金）
              ,intro_chg_amt                 -- 紹介手数料
              ,intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,intro_chg_closing_date        -- 締日（紹介手数料）
              ,intro_chg_trans_month         -- 振込月（紹介手数料）
              ,intro_chg_trans_date          -- 振込日（紹介手数料）
              ,intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,intro_chg_trans_name_alt      -- 契約先以外名カナ（紹介手数料）
              ,intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,intro_chg_branch_name         -- 支店名（紹介手数料）
              ,intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,intro_chg_org_addr            -- 発行元所属住所（紹介手数料）
              ,intro_chg_org_name            -- 発行元所属名（紹介手数料）
              ,intro_chg_org_boss_pos        -- 発行元所属長職位名（紹介手数料）
              ,intro_chg_org_boss            -- 発行元所属長名（紹介手数料）
              ,intro_chg_preamble            -- 前文（紹介手数料）
              ,electric_amt                  -- 電気代
              ,electric_closing_date         -- 締日（電気代）
              ,electric_trans_month          -- 振込月（電気代）
              ,electric_trans_date           -- 振込日（電気代）
              ,electric_trans_name           -- 契約先以外名（電気代）
              ,electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,electric_bk_number            -- 銀行番号（電気代）
              ,electric_bk_name              -- 金融機関名（電気代）
              ,electric_branch_number        -- 支店番号（電気代）
              ,electric_branch_name          -- 支店名（電気代）
              ,electric_bk_acct_type         -- 口座種別（電気代）
              ,electric_bk_acct_number       -- 口座番号（電気代）
              ,electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,electric_org_addr             -- 発行元所属住所（電気代）
              ,electric_org_name             -- 発行元所属名（電気代）
              ,electric_org_boss_pos         -- 発行元所属長職位名（電気代）
              ,electric_org_boss             -- 発行元所属長名（電気代）
              ,electric_preamble             -- 前文（電気代）
              ,created_by                    -- 作成者
              ,creation_date                 -- 作成日
              ,last_updated_by               -- 最終更新者
              ,last_update_date              -- 最終更新日
              ,last_update_login             -- 最終更新ログイン
              ,request_id                    -- 要求ID
              ,program_application_id        -- コンカレントプログラムアプリケーションID
              ,program_id                    -- コンカレントプログラムID
              ,program_update_date           -- プログラム更新日
      ) VALUES (
               i_rep_memo_data_rec.contract_number               -- 契約書番号
              ,i_rep_memo_data_rec.contract_other_custs_id       -- 契約先以外ID
              ,i_rep_memo_data_rec.contract_name                 -- 契約者名
              ,i_rep_memo_data_rec.contract_effect_date          -- 契約書発効日
              ,i_rep_memo_data_rec.install_name                  -- 設置先名
              ,i_rep_memo_data_rec.install_address               -- 設置先住所
              ,i_rep_memo_data_rec.tax_type_name                 -- 税区分名
              ,i_rep_memo_data_rec.install_supp_amt              -- 設置協賛金
              ,i_rep_memo_data_rec.install_supp_payment_date     -- 支払期日（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_chg_bearer    -- 振込手数料負担（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_number        -- 銀行番号（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_name          -- 金融機関名（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_branch_number    -- 支店番号（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_branch_name      -- 支店名（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_acct_type     -- 口座種別（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_acct_number   -- 口座番号（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_acct_name_alt -- 口座名義カナ（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_bk_acct_name     -- 口座名義漢字（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_org_addr         -- 発行元所属住所（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_org_name         -- 発行元所属名（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_org_boss_pos     -- 発行元所属長職位名（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_org_boss         -- 発行元所属長名（設置協賛金）
              ,i_rep_memo_data_rec.install_supp_preamble         -- 前文（設置協賛金）
              ,i_rep_memo_data_rec.intro_chg_amt                 -- 紹介手数料
              ,i_rep_memo_data_rec.intro_chg_payment_date        -- 支払期日（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_closing_date        -- 締日（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_trans_month         -- 振込月（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_trans_date          -- 振込日（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_trans_name          -- 契約先以外名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_trans_name_alt      -- 契約先以外名カナ（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- 振込手数料負担（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_number           -- 銀行番号（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_name             -- 金融機関名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_branch_number       -- 支店番号（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_branch_name         -- 支店名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_acct_type        -- 口座種別（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_acct_number      -- 口座番号（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- 口座名義カナ（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_bk_acct_name        -- 口座名義漢字（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_org_addr            -- 発行元所属住所（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_org_name            -- 発行元所属名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_org_boss_pos        -- 発行元所属長職位名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_org_boss            -- 発行元所属長名（紹介手数料）
              ,i_rep_memo_data_rec.intro_chg_preamble            -- 前文（紹介手数料）
              ,i_rep_memo_data_rec.electric_amt                  -- 電気代
              ,i_rep_memo_data_rec.electric_closing_date         -- 締日（電気代）
              ,i_rep_memo_data_rec.electric_trans_month          -- 振込月（電気代）
              ,i_rep_memo_data_rec.electric_trans_date           -- 振込日（電気代）
              ,i_rep_memo_data_rec.electric_trans_name           -- 契約先以外名（電気代）
              ,i_rep_memo_data_rec.electric_trans_name_alt       -- 契約先以外名カナ（電気代）
              ,i_rep_memo_data_rec.electric_bk_chg_bearer        -- 振込手数料負担（電気代）
              ,i_rep_memo_data_rec.electric_bk_number            -- 銀行番号（電気代）
              ,i_rep_memo_data_rec.electric_bk_name              -- 金融機関名（電気代）
              ,i_rep_memo_data_rec.electric_branch_number        -- 支店番号（電気代）
              ,i_rep_memo_data_rec.electric_branch_name          -- 支店名（電気代）
              ,i_rep_memo_data_rec.electric_bk_acct_type         -- 口座種別（電気代）
              ,i_rep_memo_data_rec.electric_bk_acct_number       -- 口座番号（電気代）
              ,i_rep_memo_data_rec.electric_bk_acct_name_alt     -- 口座名義カナ（電気代）
              ,i_rep_memo_data_rec.electric_bk_acct_name         -- 口座名義漢字（電気代）
              ,i_rep_memo_data_rec.electric_org_addr             -- 発行元所属住所（電気代）
              ,i_rep_memo_data_rec.electric_org_name             -- 発行元所属名（電気代）
              ,i_rep_memo_data_rec.electric_org_boss_pos         -- 発行元所属長職位名（電気代）
              ,i_rep_memo_data_rec.electric_org_boss             -- 発行元所属長名（電気代）
              ,i_rep_memo_data_rec.electric_preamble             -- 前文（電気代）
              ,cn_created_by                                     -- 作成者
              ,cd_creation_date                                  -- 作成日
              ,cn_last_updated_by                                -- 最終更新者
              ,cd_last_update_date                               -- 最終更新日
              ,cn_last_update_login                              -- 最終更新ログイン
              ,cn_request_id                                     -- 要求ID
              ,cn_program_application_id                         -- コンカレントプログラムアプリケーションID
              ,cn_program_id                                     -- コンカレントプログラムID
              ,cd_program_update_date                            -- プログラム更新日
      );
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '覚書データをワークテーブルに登録しました。'
      );
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                          --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_07                     --メッセージコード
                 ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                 ,iv_token_value1 => cv_memo_tbl_nm                       --トークン値1
                 ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                 ,iv_token_value2 => SQLERRM                              --トークン値2
                 ,iv_token_name3  => cv_tkn_contract_num                  --トークンコード3
                 ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --トークン値3
                 ,iv_token_name4  => cv_tkn_request_id                    --トークンコード3
                 ,iv_token_value4 => cn_request_id                        --トークン値3
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  EXCEPTION
--
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-4)
   ***********************************************************************************/
  PROCEDURE act_svf(
     iv_svf_form_nm         IN  VARCHAR2                 -- フォーム様式ファイル名
    ,iv_svf_query_nm        IN  VARCHAR2                 -- クエリー様式ファイル名
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- プログラム名
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
    cv_tkn_api_nm_svf  CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- SVF起動処理 
    -- ======================
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                       || TO_CHAR (cd_creation_date, 'YYYYMMDD')
                       || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => lv_file_id            -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => iv_svf_form_nm        -- フォーム様式ファイル名
     ,iv_vrq_file     => iv_svf_query_nm       -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_06        --メッセージコード
                 ,iv_token_name1  => cv_tkn_api_nm           --トークンコード1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --トークン値1
                );
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--      lv_errbuf := lv_errmsg || SQLERRM;
--      RAISE global_api_expt;
--    END IF;
--
--      -- ログ出力
--      fnd_file.put_line(
--         which  => FND_FILE.LOG
--        ,buff   => '' || CHR(10) || '自動販売機設置契約書PDFを出力しました。'
--      );
      lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      -- ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    ELSE
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '自動販売機設置契約書PDFを出力しました。'
      );
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END act_svf;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
--
  /**********************************************************************************
   * Procedure Name   : exec_submit_req
   * Description      : 覚書出力要求発行処理(A-5)
   ***********************************************************************************/
  PROCEDURE exec_submit_req(
    iv_report_type              IN  VARCHAR2, -- 帳票区分
    iv_conc_description         IN  VARCHAR2, -- コンカレント摘要
    iv_contract_number          IN  VARCHAR2, -- 契約書番号
    in_req_cnt                  IN  NUMBER,   -- 要求発行数
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_submit_req'; -- プログラム名
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_momo_conc  CONSTANT VARCHAR2(8)   := '覚書出力';        -- エラーメッセージトークン
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    --==============================================================
    -- コンカレント発行
    --==============================================================
    g_org_request(in_req_cnt).request_id := fnd_request.submit_request(
                                               application => cv_app_name            -- アプリケーション短縮名
                                              ,program     => cv_xxcso010a06         -- コンカレントプログラム名
                                              ,description => iv_conc_description    -- 摘要
                                              ,start_time  => NULL                   -- 開始時間
                                              ,sub_request => FALSE                  -- サブ要求
                                              ,argument1   => iv_report_type         -- 帳票区分
                                              ,argument2   => iv_contract_number     -- 契約書番号
                                              ,argument3   => TO_CHAR(cn_request_id) -- 発行元要求ID
                      );
    -- 正常以外の場合
    IF ( g_org_request(in_req_cnt).request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name        -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_19   -- メッセージコード
                     , iv_token_name1  => cv_tkn_conc        -- トークンコード１
                     , iv_token_value1 => cv_momo_conc       -- 覚書出力
                     , iv_token_name2  => cv_tkn_concmsg     -- トークンコード２
                     , iv_token_value2 => TO_CHAR(g_org_request(in_req_cnt).request_id) -- 戻り値
                   );
      lv_errbuf := lv_errmsg;
      -- ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --１行改行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 親コンカレント用リターンコード
      gv_retcode := cv_status_error;
    END IF;
--
    -- コミット発行
    COMMIT;
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
  END exec_submit_req;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : コンカレント終了待機処理(A-6)
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    ig_org_request_id           IN  g_org_request_ttype,   -- 要求ID
    ov_errbuf                   OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)              -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- プログラム名
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_momo_conc  CONSTANT VARCHAR2(8)   := '覚書出力';              -- エラーメッセージトークン
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
    -- *** ローカル変数 ***
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<wait_req>>
    FOR i IN ig_org_request_id.FIRST..ig_org_request_id.LAST LOOP
      -- 正常に発行できたもののみ
      IF ( ig_org_request_id(i).request_id <> 0 ) THEN
        --==============================================================
        -- コンカレント要求待機
        --==============================================================
        lb_wait_request := fnd_concurrent.wait_for_request(
                              request_id => ig_org_request_id(i).request_id -- 要求ID
                             ,interval   => gn_interval                     -- コンカレント監視間隔
                             ,max_wait   => gn_max_wait                     -- コンカレント監視最大時間
                             ,phase      => lv_phase                        -- 要求フェーズ
                             ,status     => lv_status                       -- 要求ステータス
                             ,dev_phase  => lv_dev_phase                    -- 要求フェーズコード
                             ,dev_status => lv_dev_status                   -- 要求ステータスコード
                             ,message    => lv_message                      -- 完了メッセージ
                           );
        -- 戻り値がFALSEの場合
        IF ( lb_wait_request = FALSE ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_tkn_number_20
                         ,iv_token_name1  => cv_tkn_conc
                         ,iv_token_value1 => cv_momo_conc
                         ,iv_token_name2  => cv_tkn_request_id
                         ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                       );
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          -- 親コンカレント用リターンコード
          gv_retcode := cv_status_error;
        ELSE
          -- 正常終了メッセージ出力
          IF ( lv_dev_status = cv_dev_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_tkn_number_21
                           ,iv_token_name1  => cv_tkn_conc
                           ,iv_token_value1 => cv_momo_conc
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
          -- 警告終了メッセージ出力
          ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_tkn_number_22
                           ,iv_token_name1  => cv_tkn_conc
                           ,iv_token_value1 => cv_momo_conc
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
            -- 親コンカレント用リターンコード（既にエラーの場合はそのまま）
            IF ( gv_retcode = cv_status_normal ) THEN
              gv_retcode := cv_status_warn;
            END IF;
          -- エラー終了メッセージ出力
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                           , iv_name         => cv_tkn_number_23
                           , iv_token_name1  => cv_tkn_conc
                           , iv_token_value1 => cv_momo_conc
                           , iv_token_name2  => cv_tkn_request_id
                           , iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
            -- 親コンカレント用リターンコード
            gv_retcode := cv_status_error;
          END IF;
        END IF;
        -- ログ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
    END LOOP wait_req;
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
  END func_wait_for_request;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ワークテーブルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,i_rep_memo_data_rec    IN         g_rep_memo_data_rtype  -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_data';     -- プログラム名
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
    cv_tbl_nm         CONSTANT VARCHAR2(100) := '自動販売機設置契約書帳票ワークテーブル';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    cv_memo_tbl_nm    CONSTANT VARCHAR2(100) := '覚書帳票ワークテーブル';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- *** ローカル変数 ***
    lt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- 自動販売機設置契約書ID
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    lt_reqest_id          xxcso_rep_memorandum.request_id%TYPE;                        -- 要求ID（ロック用ダミー）
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- ロックの確認
    -- ==========================
    BEGIN
--
      SELECT xrasc.request_id  request_id
      INTO   lt_con_mng_id
      FROM   xxcso_rep_auto_sale_cont xrasc         -- 自動販売機設置契約書帳票ワークテーブル
      WHERE  xrasc.request_id = cn_request_id
        AND  ROWNUM = 1
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_11        --メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl              --トークンコード1
                   ,iv_token_value1 => cv_tbl_nm               --トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg          --トークンコード2
                   ,iv_token_value2 => SQLERRM                 --トークン値2
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ==========================
    -- ワークテーブルデータ削除
    -- ==========================
    BEGIN
--
      DELETE FROM xxcso_rep_auto_sale_cont xrasc -- 自動販売機設置契約書帳票ワークテーブル
      WHERE xrasc.request_id = cn_request_id;
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || 'ワークテーブルの契約書データを削除しました。'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_08                     --メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                   ,iv_token_value1 => cv_tbl_nm                            --トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                   ,iv_token_value2 => SQLERRM                              --トークン値2
                   ,iv_token_name3  => cv_tkn_contract_num                  --トークンコード3
                   ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --トークン値3
                   ,iv_token_name4  => cv_tkn_request_id                    --トークンコード3
                   ,iv_token_value4 => cn_request_id                        --トークン値3
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- ==========================
    -- 覚書帳票ワークテーブル ロックの確認
    -- ==========================
    BEGIN
      SELECT xrm.request_id  request_id
      INTO   lt_reqest_id
      FROM   xxcso_rep_memorandum xrm                                       -- 覚書帳票ワークテーブル
      WHERE  xrm.request_id = cn_request_id
      AND    ROWNUM = 1
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_11                     --メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                   ,iv_token_value1 => cv_memo_tbl_nm                       --トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                   ,iv_token_value2 => SQLERRM                              --トークン値2
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ==========================
    -- 覚書帳票ワークテーブルデータ 削除
    -- ==========================
    BEGIN
      DELETE FROM xxcso_rep_memorandum xrm                                  -- 覚書帳票ワークテーブル
      WHERE xrm.request_id = cn_request_id;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || 'ワークテーブルの覚書データを削除しました。'
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_08                     --メッセージコード
                   ,iv_token_name1  => cv_tkn_tbl                           --トークンコード1
                   ,iv_token_value1 => cv_memo_tbl_nm                       --トークン値1
                   ,iv_token_name2  => cv_tkn_err_msg                       --トークンコード2
                   ,iv_token_value2 => SQLERRM                              --トークン値2
                   ,iv_token_name3  => cv_tkn_contract_num                  --トークンコード3
                   ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --トークン値3
                   ,iv_token_name4  => cv_tkn_request_id                    --トークンコード3
                   ,iv_token_value4 => cn_request_id                        --トークン値3
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  EXCEPTION
--
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    cv_status_0           CONSTANT VARCHAR2(1) := '0';  -- 作成中
    cv_status_1           CONSTANT VARCHAR2(1) := '1';  -- 確定済
    cv_cooperate_flag_0   CONSTANT VARCHAR2(1) := '0';  -- 未連携
    cv_cooperate_flag_1   CONSTANT VARCHAR2(1) := '1';  -- 連携済
--
    -- *** ローカル変数 ***
    lv_process_flag       VARCHAR2(1);                                     -- 処理フラグ
    lt_status             xxcso_contract_managements.status%TYPE;          -- ステータス
    lt_cooperate_flag     xxcso_contract_managements.cooperate_flag%TYPE;  -- マスタ連携フラグ
    lv_svf_form_nm        VARCHAR2(20);                                    -- フォーム様式ファイル名
    lv_svf_query_nm       VARCHAR2(20);                                    -- クエリー様式ファイル名
    -- SVF起動API戻り値格納用
    lv_errbuf_svf         VARCHAR2(5000);                                  -- エラー・メッセージ
    lv_retcode_svf        VARCHAR2(1);                                     -- リターン・コード
    lv_errmsg_svf         VARCHAR2(5000);                                  -- ユーザー・エラー・メッセージ
--
    -- *** ローカル・レコード ***
    l_rep_cont_data_rec   g_rep_cont_data_rtype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    l_rep_memo_data_rec   g_rep_memo_data_rtype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- *** ローカル例外 ***
    init_expt   EXCEPTION;  -- 初期処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- 覚書帳票関連変数初期化
    gn_req_cnt    := 0;
    gv_memo_inst  := NULL;
    gv_memo_intro := NULL;
    gv_memo_elec  := NULL;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD END   */
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
      ot_status         => lt_status           -- ステータス
     ,ot_cooperate_flag => lt_cooperate_flag   -- マスタ連携フラグ
     ,ov_errbuf         => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode        => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE init_expt;
    END IF;
    -- 初期処理成功の場合、対象件数カウント
    gn_target_cnt := gn_target_cnt + 1;
--
    -- ==============================================================================================
    -- 処理フラグ = 1 ステータスが作成中の場合、またはステータスが確定済、且つマスタ連携フラグが未連携の場合
    -- 処理フラグ = 2 ステータスがステータスが確定済、且つマスタ連携フラグが連携済の場合
    --===============================================================================================
    IF ((lt_status = cv_status_0)
        OR ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_0))) THEN
      lv_process_flag := cv_flag_1;
    ELSIF ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_1)) THEN
      lv_process_flag := cv_flag_2;
    END IF;
--
    -- ========================================
    -- A-2.データ取得
    -- ========================================
    get_contract_data(
      iv_process_flag     => lv_process_flag      -- 処理フラグ
     ,o_rep_cont_data_rec => l_rep_cont_data_rec  -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
     ,o_rep_memo_data_rec => l_rep_memo_data_rec  -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
     ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ            --# 固定 #
     ,ov_retcode          => lv_retcode           -- リターン・コード              --# 固定 #
     ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.ワークテーブルに登録
    -- ========================================
    insert_data(
      i_rep_cont_data_rec    => l_rep_cont_data_rec    -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
     ,i_rep_memo_data_rec    => l_rep_memo_data_rec    -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
     ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
     ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
     ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================================================
    -- フォーム様式ファイル名、クエリー様式ファイル名
    -- 帳票出力パターン（８種類）
    --===============================================================================================
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--      ,buff   => '' || CHR(10) || '<< 帳票出力パターン >>'
      ,buff   => '' || CHR(10) || '<< 自動販売機設置契約帳票出力パターン >>'
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
    );
--
    -- ① 販売手数料有り、且つ設置協賛金有り、且つ電気代有りの場合
    IF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S01.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S01.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '① 販売手数料有り、且つ設置協賛金有り、且つ電気代有り'
      );
--
    -- ② 販売手数料有り、且つ設置協賛金有り、且つ電気代無しの場合
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
--          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
--          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
            AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S02.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S02.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '② 販売手数料有り、且つ設置協賛金有り、且つ電気代無し'
      );
--
    -- ③ 販売手数料有り、且つ設置協賛金無し、且つ電気代有りの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S03.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S03.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '③ 販売手数料有り、且つ設置協賛金無し、且つ電気代有り'
      );
--
    -- ④ 販売手数料有り、且つ設置協賛金無し、且つ電気代無しの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
--          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S04.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S04.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '④ 販売手数料有り、且つ設置協賛金無し、且つ電気代無し'
      );
--
    -- ⑤ 販売手数料無し、且つ設置協賛金有り、且つ電気代有りの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S05.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S05.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '⑤ 販売手数料無し、且つ設置協賛金有り、且つ電気代有り'
      );
--
    -- ⑥ 販売手数料無し、且つ設置協賛金有り、且つ電気代無しの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
--          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S06.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S06.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '⑥ 販売手数料無し、且つ設置協賛金有り、且つ電気代無し'
      );
--
    -- ⑦ 販売手数料無し、且つ設置協賛金無し、且つ電気代有りの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S07.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S07.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '⑦ 販売手数料無し、且つ設置協賛金無し、且つ電気代有り'
      );
--
    -- ⑧ 販売手数料無し、且つ設置協賛金無し、且つ電気代無しの場合
    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
--          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)) THEN
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
      -- フォーム様式ファイル名
      lv_svf_form_nm  := cv_svf_name || 'S08.xml';
      -- クエリー様式ファイル名
      lv_svf_query_nm := cv_svf_name || 'S08.vrq';
--
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '⑧ 販売手数料無し、且つ設置協賛金無し、且つ電気代無し'
      );
--
    END IF;
--
    -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'フォーム様式：' || lv_svf_form_nm || '、クエリー様式：' || lv_svf_query_nm
    );
--
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- 覚書（設置協賛金）
    IF ( l_rep_memo_data_rec.install_supp_memo_flg = cn_is_memo_yes ) THEN
      gv_memo_inst  := cv_memo_inst;
    END IF;
    -- 覚書（紹介手数料）
    IF    ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_single ) THEN
      gv_memo_intro := cv_memo_intro_fix;
    ELSIF ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_per_sp ) THEN
      gv_memo_intro := cv_memo_intro_price;
    ELSIF ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_per_p ) THEN
      gv_memo_intro := cv_memo_intro_piece;
    END IF;
    -- 覚書（電気代）
    IF    (l_rep_memo_data_rec.electric_memo_flg   = cn_e_memo_o_fix ) THEN
      gv_memo_elec := cv_memo_elec_fix;
    ELSIF (l_rep_memo_data_rec.electric_memo_flg   = cn_e_memo_o_var ) THEN
      gv_memo_elec := cv_memo_elec_change;
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- ========================================
    -- A-4.SVF起動
    -- ========================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '<< 自動販売機設置契約帳票 - SVF起動 >>'
    );
    -- 契約書帳票出力
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    act_svf(
       iv_svf_form_nm  => lv_svf_form_nm
      ,iv_svf_query_nm => lv_svf_query_nm
      ,ov_errbuf       => lv_errbuf_svf                 -- エラー・メッセージ            --# 固定 #
      ,ov_retcode      => lv_retcode_svf                -- リターン・コード              --# 固定 #
      ,ov_errmsg       => lv_errmsg_svf                 -- ユーザー・エラー・メッセージ  --# 固定 #
    );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ------------------------------
    -- 覚書帳票（設置協賛金）出力
    ------------------------------
    IF ( gv_memo_inst IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< 覚書帳票（設置協賛金） - SVF起動 >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --覚書発行(
      exec_submit_req(
         iv_report_type       => gv_memo_inst                         --帳票区分
        ,iv_conc_description  => gv_conc_des_inst                     --コンカレント摘要
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  --契約書番号
        ,in_req_cnt           => gn_req_cnt                           --実行コンカレント数
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
    ------------------------------
    --覚書帳票（紹介手数料）出力
    ------------------------------
    IF ( gv_memo_intro IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< 覚書帳票（紹介手数料） - SVF起動 >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --覚書発行
      exec_submit_req(
         iv_report_type       => gv_memo_intro                        -- 帳票区分
        ,iv_conc_description  => gv_conc_des_intro                    -- コンカレント摘要
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  -- 契約書番号
        ,in_req_cnt           => gn_req_cnt                           -- 実行コンカレント数
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );    END IF;
    ------------------------------
    --覚書帳票（電気代）出力
    ------------------------------
    IF ( gv_memo_elec IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< 覚書帳票（電気代） - SVF起動 >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --覚書発行(
      exec_submit_req(
         iv_report_type       => gv_memo_elec                         -- 帳票区分
        ,iv_conc_description  => gv_conc_des_electric                 -- コンカレント摘要
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  -- 契約書番号
        ,in_req_cnt           => gn_req_cnt
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
    ------------------------------
    -- 覚書出力コンカレント待機
    ------------------------------
    IF ( g_org_request.COUNT <> 0 ) THEN
      --発行した覚書出力を待機する
      func_wait_for_request(
         ig_org_request_id    => g_org_request
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- ========================================
    -- A-7.ワークテーブルデータ削除
    -- ========================================
    delete_data(
       i_rep_cont_data_rec  => l_rep_cont_data_rec      -- 契約書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
      ,i_rep_memo_data_rec  => l_rep_memo_data_rec      -- 覚書データ
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
      ,ov_errbuf            => lv_errbuf                -- エラー・メッセージ            --# 固定 #
      ,ov_retcode           => lv_retcode               -- リターン・コード              --# 固定 #
      ,ov_errmsg            => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-8.SVF起動APIエラーチェック
    -- ========================================
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--    IF (lv_retcode_svf = cv_status_error) THEN
--      lv_errmsg := lv_errmsg_svf;
--      lv_errbuf := lv_errbuf_svf;
--      RAISE global_process_expt;
--    END IF;
--
--    -- 成功件数カウント
--    gn_normal_cnt := gn_normal_cnt + 1;
    IF ( gv_retcode <> cv_status_normal ) THEN
      -- SVF関数の戻り値を設定
      ov_retcode := gv_retcode;
    ELSE
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
--
  EXCEPTION
    -- *** 初期処理例外ハンドラ ***
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 処理部例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf               OUT NOCOPY VARCHAR2    -- エラー・メッセージ  --# 固定 #
    ,retcode              OUT NOCOPY VARCHAR2    -- リターン・コード    --# 固定 #
    ,in_contract_mng_id   IN         NUMBER      -- 自動販売機設置契約書ID
  )
--
-- ###########################  固定部 START   ###########################
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
-- ###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  固定部 END   #############################
--
    -- *** 入力パラメータをセット(自動販売機設置契約書ID)
    gt_con_mng_id := in_contract_mng_id;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => '' || CHR(10) ||lv_errmsg                  -- ユーザー・エラーメッセージ
--       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => '' || CHR(10)
                   ||cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf    -- エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-9.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''               -- 空行
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO010A04C;
/
