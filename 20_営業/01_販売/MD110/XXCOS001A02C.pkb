CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A02C (body)
 * Description      : 入金データの取込を行う
 * MD.050           : HHT入金データ取込 (MD050_COS_001_A02)
 * Version          : 1.12
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_data_receive   入金ワークテーブルより入金データ抽出(A-1)
 *  payment_data_check     抽出したデータの妥当性チェック(A-2)
 *  error_data_register    エラー発生対象データを登録(A-3)
 *  payment_data_register  入金データを登録(A-4)
 *  payment_work_delete    入金ワークテーブルのレコード削除(A-5)
 *  payment_data_delete    入金テーブルの不要データ削除(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0   S.Miyakoshi       新規作成
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]百貨店HHT区分変更に対応
 *                                       [COS_005]業態小分類における取込対象条件の不具合に対応
 *  2009/02/20    1.2   S.Miyakoshi      パラメータのログファイル出力対応
 *  2009/04/30    1.3   T.Kitajima       [T1_0268]CHAR項目のTRIM対応
 *  2009/05/15    1.4   T.Kitajima       [T1_0639]拠点コード設定変更(売上拠点→入金拠点)
 *  2009/05/19    1.5   N.Maeda          [T1_1011]エラーリスト登録用拠点抽出条件変更
 *  2009/06/19    1.6   T.Kitajima       [T1_1447]パフォーマンス改善対応
 *  2009/07/21    1.7   T.Tominaga       [0000741]パフォーマンス改善対応
 *                                       [0000765]入金拠点コードの取得先変更
 *  2009/07/28    1.8   T.Tominaga       [0000881]拠点名称・顧客名の桁数編集
 *  2009/10/02    1.9   N.Maeda          [0001378]エラーリスト出力桁数編集
 *  2010/02/01    1.10  N.Maeda          [E_本稼動_01353] 入金日-AR会計期間妥当性チェック、出力内容修正
 *  2011/02/23    1.11  Y.Nishino        [E_本稼動_02246] 入金データ登録情報に納品先拠点コードを追加する
 *  2016/03/10    1.12  H.Okada          [E_本稼動_13485] 入金ワークテーブル削除処理以降のエラーメッセージ修正
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;          --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                     --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;          --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                     --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;         --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;  --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;     --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;  --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                     --PROGRAM_UPDATE_DATE
--
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- クイックコード取得エラー
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A02C';      -- パッケージ名
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';             -- アプリケーション名
--
  -- プロファイル
  -- XXCOS:入金データ取込パージ処理日算出基準日数
  cv_prf_purge_date  CONSTANT VARCHAR2(50)  := 'XXCOS1_PAYMENT_PURGE_DATE';
  -- XXCOS:MAX日付
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
--
  -- エラーコード
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データ無しエラー
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX日付
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- 参照コードマスタ
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10051';  -- データ抽出エラーメッセージ
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10052';  -- マスタチェックエラー
  cv_msg_class       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10053';  -- 入金区分エラー
  cv_msg_minus       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10054';  -- マイナス金額エラー
  cv_msg_prd         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10055';  -- 入金日会計期間チェック
  cv_msg_ftr         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10056';  -- 入金日未来日チェック
  cv_msg_colm        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10057';  -- 必須項目エラー
  cv_msg_status      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10058';  -- 顧客ステータスエラー
  cv_msg_base        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10060';  -- 顧客の売上拠点コードエラー
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10061';  -- データ追加エラーメッセージ
  cv_msg_del         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10062';  -- データ削除エラーメッセージ
  cv_msg_busi        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10063';  -- 業態（小分類）エラー
  cv_msg_purge       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10064';  -- 入金データ取込パージ処理日算出基準日
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10065';  -- 業務処理日取得エラー
  cv_msg_pay_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10066';  -- 入金テーブル
  cv_msg_paywk_tab   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10067';  -- 入金ワークテーブル
  cv_msg_err_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10068';  -- HHTエラーリスト帳票ワークテーブル
  cv_msg_base_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10069';  -- 拠点コード
  cv_msg_cus_num     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10070';  -- 顧客コード
  cv_msg_pay_class   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10071';  -- 入金区分
  cv_msg_pay_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10072';  -- 入金日
  cv_msg_pay_amount  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10073';  -- 入金額
  cv_msg_data_name   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10074';  -- 入金データ
  cv_msg_del_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10075';  -- 削除件数
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10076';  -- クイックコード取得エラーメッセージ
  cv_msg_cust_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10077';  -- 顧客ステータス
  cv_msg_busi_low    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10078';  -- 業態（小分類）
  cv_msg_parameter   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
  cv_msg_del_sql     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00221';  -- SQLエラーメッセージ
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
  -- トークン
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル名
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';            -- テーブル列名
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';              -- クイックコードタイプ
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';             -- 件数
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';           -- プロファイル名
  cv_tkn_del_flag    CONSTANT VARCHAR2(1)   := 'N';
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';
  cv_tkn_sqlerr      CONSTANT VARCHAR2(20)  := 'SQL_ERR';           -- SQLエラー
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
--
  cv_general         CONSTANT VARCHAR2(1)   := NULL;                -- 百貨店用HHT区分＝NULL：一般拠点
  cv_depart          CONSTANT VARCHAR2(1)   := '1';                 -- 百貨店用HHT区分＝1：百貨店
--******************************* 2009/07/21 1.7 T.Tominaga ADD START ***************************************
  --言語コード
  ct_lang            CONSTANT fnd_lookup_values.language%TYPE
                                            := USERENV( 'LANG' );
--******************************* 2009/07/21 1.7 T.Tominaga ADD END   ***************************************
--
  -- クイックコードタイプ
  cv_qck_typ_class   CONSTANT VARCHAR2(30)  := 'XXCOS1_RECEIPT_MONEY_CLASS';      -- 入金区分
  cv_qck_typ_busi    CONSTANT VARCHAR2(30)  := 'XXCOS1_GYOTAI_SHO_MST_001_A02';   -- 業態（小分類）
  cv_qck_typ_status  CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_STATUS_MST_001_A02';   -- 顧客ステータス
  cv_qck_typ_cus     CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_CLASS_MST_001_A02';    -- 顧客区分
  cv_qck_typ_a02     CONSTANT VARCHAR2(30)  := 'XXCOS_001_A02_%';
--
  --フォーマット
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE形式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入金ワークテーブルデータ格納用変数
  TYPE g_rec_payment_data IS RECORD
    (
      line_id          xxcos_payment.line_id%TYPE,           -- 明細ID
      base_code        xxcos_payment.base_code%TYPE,         -- 拠点コード
      customer_number  xxcos_payment.customer_number%TYPE,   -- 顧客コード
      payment_amount   xxcos_payment.payment_amount%TYPE,    -- 入金額
      payment_date     xxcos_payment.payment_date%TYPE,      -- 入金日
      payment_class    xxcos_payment.payment_class%TYPE,     -- 入金区分
      hht_invoice_no   xxcos_payment.hht_invoice_no%TYPE     -- HHT伝票No
    );
  TYPE g_tab_payment_data IS TABLE OF g_rec_payment_data INDEX BY PLS_INTEGER;
--
  -- 入金データ登録用変数
  TYPE g_tab_pay_base_code           IS TABLE OF xxcos_payment.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点コード
  TYPE g_tab_pay_customer_number     IS TABLE OF xxcos_payment.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客コード
  TYPE g_tab_pay_payment_amount      IS TABLE OF xxcos_payment.payment_amount%TYPE
    INDEX BY PLS_INTEGER;   -- 入金額
  TYPE g_tab_pay_payment_date        IS TABLE OF xxcos_payment.payment_date%TYPE
    INDEX BY PLS_INTEGER;   -- 入金日
  TYPE g_tab_pay_payment_class       IS TABLE OF xxcos_payment.payment_class%TYPE
    INDEX BY PLS_INTEGER;   -- 入金区分
  TYPE g_tab_pay_hht_invoice_no      IS TABLE OF xxcos_payment.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT伝票No
-- ************ 2011/02/23 1.11 Y.Nishino ADD START ************ --
  TYPE g_tab_pay_delivery_base_code  IS TABLE OF xxcos_payment.delivery_to_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 納品先拠点コード
-- ************ 2011/02/23 1.11 Y.Nishino ADD END   ************ --
--
  -- エラーデータ格納用変数
  TYPE g_tab_err_base_code           IS TABLE OF xxcos_rep_hht_err_list.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点コード
  TYPE g_tab_err_base_name           IS TABLE OF xxcos_rep_hht_err_list.base_name%TYPE
    INDEX BY PLS_INTEGER;   -- 拠点名称
  TYPE g_tab_err_entry_number        IS TABLE OF xxcos_rep_hht_err_list.entry_number%TYPE
    INDEX BY PLS_INTEGER;   -- 伝票NO
  TYPE g_tab_err_party_num           IS TABLE OF xxcos_rep_hht_err_list.party_num%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客コード
  TYPE g_tab_err_customer_name       IS TABLE OF xxcos_rep_hht_err_list.customer_name%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客名
  TYPE g_tab_err_payment_dlv_date    IS TABLE OF xxcos_rep_hht_err_list.payment_dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- 入金/納品日
  TYPE g_tab_err_payment_class_name  IS TABLE OF xxcos_rep_hht_err_list.payment_class_name%TYPE
    INDEX BY PLS_INTEGER;   -- 入金区分名称
  TYPE g_tab_err_error_message       IS TABLE OF xxcos_rep_hht_err_list.error_message%TYPE
    INDEX BY PLS_INTEGER;   -- エラー内容
--
  -- 訪問・有効実績登録用変数
  TYPE g_tab_resource_id             IS TABLE OF jtf_rs_resource_extns.resource_id%TYPE
    INDEX BY PLS_INTEGER;   -- リソースID
  TYPE g_tab_party_id                IS TABLE OF hz_parties.party_id%TYPE
    INDEX BY PLS_INTEGER;   -- パーティID
  TYPE g_tab_party_name              IS TABLE OF hz_parties.party_name%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客名称
  TYPE g_tab_cus_status              IS TABLE OF hz_parties.duns_number_c%TYPE
    INDEX BY PLS_INTEGER;   -- 顧客ステータス
--
  -- クイックコード格納用
  -- 顧客ステータス格納用変数
  TYPE g_tab_qck_status  IS TABLE OF hz_parties.duns_number_c%TYPE INDEX BY PLS_INTEGER;
  -- 業態（小分類）格納用変数
  TYPE g_tab_qck_busi    IS TABLE OF xxcmm_cust_accounts.business_low_type%TYPE INDEX BY PLS_INTEGER;
  -- 入金区分格納用変数
  TYPE g_rec_pay_class IS RECORD
    (
      payment_class    xxcos_payment.payment_class%TYPE,                  -- 入金区分
      pay_class_name   xxcos_rep_hht_err_list.payment_class_name%TYPE     -- 入金区分名称
    );
  TYPE g_tab_qck_class   IS TABLE OF g_rec_pay_class INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入金テーブル登録データ
  gt_pay_base_code        g_tab_pay_base_code;           -- 拠点コード
  gt_pay_customer_number  g_tab_pay_customer_number;     -- 顧客コード
  gt_pay_payment_amount   g_tab_pay_payment_amount;      -- 入金額
  gt_pay_payment_date     g_tab_pay_payment_date;        -- 入金日
  gt_pay_payment_class    g_tab_pay_payment_class;       -- 入金区分
  gt_pay_hht_invoice_no   g_tab_pay_hht_invoice_no;      -- HHT伝票No
-- ************ 2011/02/23 1.11 Y.Nishino ADD START ************ --
  gt_pay_delivery_to_base_code  g_tab_pay_delivery_base_code;  -- 納品先拠点コード
-- ************ 2011/02/23 1.11 Y.Nishino ADD END   ************ --
  -- HHTエラーリスト帳票ワークテーブル登録データ
  gt_err_base_code        g_tab_err_base_code;           -- 拠点コード
  gt_err_base_name        g_tab_err_base_name;           -- 拠点名称
  gt_err_entry_number     g_tab_err_entry_number;        -- 伝票NO
  gt_err_party_num        g_tab_err_party_num;           -- 顧客コード
  gt_err_cus_name         g_tab_err_customer_name;       -- 顧客名
  gt_err_pay_dlv_date     g_tab_err_payment_dlv_date;    -- 入金/納品日
  gt_err_pay_class_name   g_tab_err_payment_class_name;  -- 入金区分名称
  gt_err_error_message    g_tab_err_error_message;       -- エラー内容
--
  -- 訪問・有効実績登録用変数
  gt_resource_id          g_tab_resource_id;             -- リソースID
  gt_party_id             g_tab_party_id;                -- パーティID
  gt_party_name           g_tab_party_name;              -- 顧客名称
  gt_cus_status           g_tab_cus_status;              -- 顧客ステータス
--
  gt_payment_work_data    g_tab_payment_data;            -- 入金ワークテーブル抽出データ
  gt_qck_status           g_tab_qck_status;              -- 顧客ステータス
  gt_qck_busi             g_tab_qck_busi;                -- 業態（小分類）
  gt_qck_class            g_tab_qck_class;               -- 入金区分
  gn_purge_date           NUMBER;                        -- パージ処理基準日
  gd_process_date         DATE;                          -- 業務処理日
--****************************** 2009/06/19 1.6 T.kitajima ADD START ******************************--
  gd_purge_date           DATE;                          -- パージ用日付
--****************************** 2009/06/19 1.6 T.kitajima ADD  END  ******************************--
  gd_max_date             DATE;                          -- MAX日付
--
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
  gv_part_comp_err_flag    VARCHAR2(1);                   -- 一部処理（入金データの取込まで完了）後エラーフラグ
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
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
    cv_application_ccp CONSTANT VARCHAR2(5)   := 'XXCCP';                  -- アプリケーション名
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
    --==============================================================
    --「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    --==============================================================
    --「コンカレント入力パラメータなし」メッセージをログ出力
    --==============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
   gv_part_comp_err_flag := cv_tkn_no;  -- 一部処理後エラーフラグの初期化
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : payment_data_receive
   * Description      : 入金ワークテーブルより入金データ抽出(A-1)
   ***********************************************************************************/
  PROCEDURE payment_data_receive(
    on_target_cnt     OUT NUMBER,                --   抽出件数
    ov_errbuf         OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_receive'; -- プログラム名
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
    lv_purge_date    VARCHAR2(5);   -- パージ処理算出基準日
    ld_process_date  DATE;          -- 業務処理日
    lv_max_date      VARCHAR2(50);  -- MAX日付
    lv_tkn           VARCHAR2(50);  -- エラーメッセージ用トークン
    lv_tkn2          VARCHAR2(50);  -- エラーメッセージ用トークン2
    lv_tkn3          VARCHAR2(50);  -- エラーメッセージ用トークン3
--
    -- *** ローカル・カーソル ***
--
    -- 入金ワークテーブルデータ抽出
    CURSOR get_payment_data_cur
    IS
--****************************** 2009/04/30 1.3 T.Kitajima MOD START ******************************--
--      SELECT xpw.line_id          line_id,           -- 明細ID
--             xpw.base_code        base_code,         -- 拠点コード
--             xpw.customer_number  customer_number,   -- 顧客コード
--             xpw.payment_amount   payment_amount,    -- 入金額
--             xpw.payment_date     payment_date,      -- 入金日
--             xpw.payment_class    payment_class,     -- 入金区分
--             xpw.hht_invoice_no   hht_invoice_no     -- HHT伝票No
--      FROM   xxcos_payment_work   xpw                -- 入金ワークテーブル
--      FOR UPDATE NOWAIT;
--
      SELECT xpw.line_id                  line_id,           -- 明細ID
             TRIM( xpw.base_code )        base_code,         -- 拠点コード
             TRIM( xpw.customer_number )  customer_number,   -- 顧客コード
             xpw.payment_amount           payment_amount,    -- 入金額
             xpw.payment_date             payment_date,      -- 入金日
             TRIM( xpw.payment_class  )   payment_class,     -- 入金区分
             TRIM( xpw.hht_invoice_no )   hht_invoice_no     -- HHT伝票No
      FROM   xxcos_payment_work   xpw                -- 入金ワークテーブル
      FOR UPDATE NOWAIT;
--****************************** 2009/04/30 1.3 T.Kitajima MOD  END ******************************--
--
    -- クイックコード：顧客ステータス取得
    CURSOR get_cus_status_cur
    IS
      SELECT  look_val.meaning      meaning
--******************************* 2009/07/21 1.7 T.Tominaga MOD START ***************************************
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     app.application_id    = appl.application_id
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type = cv_qck_typ_status
--      AND     look_val.lookup_code LIKE cv_qck_typ_a02
--      AND     types.lookup_type = types_tl.lookup_type
--      AND     types.security_group_id = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     types_tl.language = USERENV( 'LANG' );
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = ct_lang
      AND     look_val.lookup_type  = cv_qck_typ_status
      AND     look_val.lookup_code LIKE cv_qck_typ_a02
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--******************************* 2009/07/21 1.7 T.Tominaga MOD END   ***************************************
--
    -- クイックコード：業態（小分類）取得
    CURSOR get_gyotai_sho_cur
    IS
      SELECT  look_val.meaning      meaning
--******************************* 2009/07/21 1.7 T.Tominaga MOD START ***************************************
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     app.application_id    = appl.application_id
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type = cv_qck_typ_busi
--      AND     look_val.lookup_code LIKE cv_qck_typ_a02
--      AND     types.lookup_type = types_tl.lookup_type
--      AND     types.security_group_id = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     types_tl.language = USERENV( 'LANG' );
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = ct_lang
      AND     look_val.lookup_type  = cv_qck_typ_busi
      AND     look_val.lookup_code LIKE cv_qck_typ_a02
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--******************************* 2009/07/21 1.7 T.Tominaga MOD END   ***************************************
--
    -- クイックコード：入金区分取得
    CURSOR get_pay_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code,
              look_val.meaning      meaning
--******************************* 2009/07/21 1.7 T.Tominaga MOD START ***************************************
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     app.application_id    = appl.application_id
--      AND     look_val.lookup_type  = cv_qck_typ_class
--      AND     app.application_short_name = cv_application
--      AND     types.lookup_type = types_tl.lookup_type
--      AND     types.security_group_id = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     types_tl.language     = USERENV( 'LANG' )
--      AND     look_val.attribute1   = cv_tkn_yes;
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language     = ct_lang
      AND     look_val.lookup_type  = cv_qck_typ_class
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     look_val.attribute1   = cv_tkn_yes;
--******************************* 2009/07/21 1.7 T.Tominaga MOD END   ***************************************
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
    -- 抽出件数初期化
    on_target_cnt := 0;
--
    --==============================================================
    -- プロファイルの取得
    -- (入金データ取込パージ処理日算出基準日)
    --==============================================================
    lv_purge_date := FND_PROFILE.VALUE( cv_prf_purge_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_purge_date IS NULL ) THEN
      lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, lv_tkn );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gn_purge_date := TO_NUMBER( lv_purge_date );
    END IF;
--
    --==================================
    -- プロファイルの取得(XXCOS:MAX日付)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- プロファイル取得エラーの場合
    IF ( lv_max_date IS NULL ) THEN
      lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, lv_tkn );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==============================================================
    -- 共通関数＜業務処理日取得＞の呼び出し
    --==============================================================
     ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
--****************************** 2009/06/19 1.6 T.kitajima MOD START ******************************--
--      gd_process_date := TRUNC( ld_process_date );
      gd_process_date := ld_process_date;
      gd_purge_date   := gd_process_date - gn_purge_date - ( 1 / 86400 ) ;
--****************************** 2009/06/19 1.6 T.kitajima MOD  END  ******************************--
    END IF;
--
    --==============================================================
    -- クイックコードの取得
    --==============================================================
    -- 顧客ステータス取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_cus_status_cur;
      -- バルクフェッチ
      FETCH get_cus_status_cur BULK COLLECT INTO gt_qck_status;
      -- カーソルCLOSE
      CLOSE get_cus_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：顧客ステータス取得
        IF ( get_cus_status_cur%ISOPEN ) THEN
          CLOSE get_cus_status_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_status );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cust_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- 業態（小分類）取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_gyotai_sho_cur;
      -- バルクフェッチ
      FETCH get_gyotai_sho_cur BULK COLLECT INTO gt_qck_busi;
      -- カーソルCLOSE
      CLOSE get_gyotai_sho_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：業態（小分類）取得
        IF ( get_gyotai_sho_cur%ISOPEN ) THEN
          CLOSE get_gyotai_sho_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_busi );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi_low );
--
        RAISE lookup_types_expt;
    END;
--
    -- 入金区分取得
    BEGIN
      -- カーソルOPEN
      OPEN  get_pay_class_cur;
      -- バルクフェッチ
      FETCH get_pay_class_cur BULK COLLECT INTO gt_qck_class;
      -- カーソルCLOSE
      CLOSE get_pay_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルCLOSE：入金区分取得
        IF ( get_pay_class_cur%ISOPEN ) THEN
          CLOSE get_pay_class_cur;
        END IF;
--
        lv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_class );
        lv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_class );
--
        RAISE lookup_types_expt;
    END;
--
    --==============================================================
    -- 入金ワークテーブルデータ取得
    --==============================================================
    BEGIN
--
      -- カーソルOPEN
      OPEN  get_payment_data_cur;
      -- バルクフェッチ
      FETCH get_payment_data_cur BULK COLLECT INTO gt_payment_work_data;
      -- 抽出件数セット
      on_target_cnt := get_payment_data_cur%ROWCOUNT;
      -- カーソルCLOSE
      CLOSE get_payment_data_cur;
--
    EXCEPTION
--
      -- ロックエラー
      WHEN lock_expt THEN
        lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn );
        lv_errbuf  := lv_errmsg;
--
        -- カーソルCLOSE：入金ワークテーブルデータ取得
        IF ( get_payment_data_cur%ISOPEN ) THEN
          CLOSE get_payment_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- エラー処理（データ抽出エラー）
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
--
        -- カーソルCLOSE：入金ワークテーブルデータ取得
        IF ( get_payment_data_cur%ISOPEN ) THEN
          CLOSE get_payment_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    -- クイックコード取得エラー
    WHEN lookup_types_expt THEN
      lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  lv_tkn,
                                                                                cv_tkn_type,   lv_tkn2,
                                                                                cv_tkn_colmun, lv_tkn3 );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END payment_data_receive;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_check
   * Description      : 抽出したデータの妥当性チェック(A-2)
   ***********************************************************************************/
  PROCEDURE payment_data_check(
    on_target_cnt    IN  NUMBER,                --   抽出件数
    ov_errbuf        OUT VARCHAR2,              --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,              --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_check'; -- プログラム名
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
    cv_default   CONSTANT VARCHAR2(1) := '0';
    cv_hit       CONSTANT VARCHAR2(1) := '1';
    cv_month     CONSTANT VARCHAR2(5) := 'MONTH';
    cv_ar_class  CONSTANT VARCHAR2(2) := '02';
    cv_open      CONSTANT VARCHAR2(4) := 'OPEN';
--
    -- *** ローカル変数 ***
    lt_line_id          xxcos_payment.line_id%TYPE;                     -- 明細ID
    lt_base_code        xxcos_payment.base_code%TYPE;                   -- 拠点コード
    lt_customer_number  xxcos_payment.customer_number%TYPE;             -- 顧客コード
    lt_payment_amount   xxcos_payment.payment_amount%TYPE;              -- 入金額
    lt_payment_date     xxcos_payment.payment_date%TYPE;                -- 入金日
    lt_payment_class    xxcos_payment.payment_class%TYPE;               -- 入金区分
    lt_hht_invoice_no   xxcos_payment.hht_invoice_no%TYPE;              -- HHT伝票No
    lt_base_name        xxcos_rep_hht_err_list.base_name%TYPE;          -- 拠点名称
    lt_customer_name    xxcos_rep_hht_err_list.customer_name%TYPE;      -- 顧客名
    lt_pay_class_name   xxcos_rep_hht_err_list.payment_class_name%TYPE; -- 入金区分名称
    lt_error_message    xxcos_rep_hht_err_list.error_message%TYPE;      -- エラー内容
    lv_err_flag         VARCHAR2(1)  DEFAULT  '0';                      -- エラーフラグ
--****************************** 2009/05/15 1.4 T.Kitajima MOD START ******************************--
--    lt_sale_base        xxcmm_cust_accounts.sale_base_code%TYPE;        -- 売上拠点コード
--    lt_past_sale_base   xxcmm_cust_accounts.past_sale_base_code%TYPE;   -- 前月売上拠点コード
    lt_receiv_base      xxcmm_cust_accounts.receiv_base_code%TYPE;      -- 入金拠点コード
--****************************** 2009/05/15 1.4 T.Kitajima MOD  END  ******************************--
    lt_cus_status       hz_parties.duns_number_c%TYPE;                  -- 顧客ステータス
    lt_bus_low_type     xxcmm_cust_accounts.business_low_type%TYPE;     -- 業態（小分類）
    ln_err_no           NUMBER  DEFAULT  '1';                           -- エラー配列ナンバー
    ln_ok_no            NUMBER  DEFAULT  '1';                           -- 正常値配列ナンバー
    lv_tkn              VARCHAR2(50);                                   -- エラーメッセージ用トークン
    lv_status           VARCHAR2(5);                                    -- AR会計期間チェック：ステータスの種類
    ln_from_date        DATE;                                           -- AR会計期間チェック：会計（FROM）
    ln_to_date          DATE;                                           -- AR会計期間チェック：会計（TO）
    lt_resource_id      jtf_rs_resource_extns.resource_id%TYPE;         -- リソースID
    lt_party_id         hz_parties.party_id%TYPE;                       -- パーティID
    lt_hht_class        xxcmm_cust_accounts.dept_hht_div%TYPE;          -- 百貨店用HHT区分
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
    -- ループ開始
    FOR ck_no IN 1..on_target_cnt LOOP
--
      -- エラーフラグ初期化
      lv_err_flag := cv_default;
--
      -- データ取得
      lt_line_id         := gt_payment_work_data(ck_no).line_id;                -- 明細ID
      lt_base_code       := gt_payment_work_data(ck_no).base_code;              -- 拠点コード
      lt_customer_number := gt_payment_work_data(ck_no).customer_number;        -- 顧客コード
      lt_payment_amount  := gt_payment_work_data(ck_no).payment_amount;         -- 入金額
      lt_payment_date    := TRUNC( gt_payment_work_data(ck_no).payment_date );  -- 入金日
      lt_payment_class   := gt_payment_work_data(ck_no).payment_class;          -- 入金区分
      lt_hht_invoice_no  := gt_payment_work_data(ck_no).hht_invoice_no;         -- HHT伝票No
      lt_base_name       := NULL;                                               -- 拠点名称を初期化
      lt_customer_name   := NULL;                                               -- 顧客名を初期化
      lt_pay_class_name  := NULL;                                               -- 入金区分名称を初期化
--
      --==============================================================
      -- 入金区分の妥当性チェック
      --==============================================================
      --== 必須項目チェック：入金区分 ==--
      IF ( lt_payment_class IS NULL ) THEN
        -- ログ出力
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_class );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--        gt_err_base_code(ln_err_no)        :=  lt_base_code;                -- 拠点コード
        gt_err_base_name(ln_err_no)        :=  lt_base_name;                -- 拠点名称
--        gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;           -- 伝票NO
--        gt_err_party_num(ln_err_no)        :=  lt_customer_number;          -- 顧客コード
        gt_err_cus_name(ln_err_no)         :=  lt_customer_name;            -- 顧客名
        gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
        gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
        gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
        gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
        gt_err_pay_class_name(ln_err_no)   :=  NULL;                         -- 入金区分名称
        gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      ELSE
        -- 入金区分妥当性チェック
        FOR k IN 1..gt_qck_class.COUNT LOOP
          lt_pay_class_name := gt_qck_class(k).pay_class_name;  -- 入金区分名称取得
          EXIT WHEN gt_qck_class(k).payment_class = lt_payment_class;
          IF ( k = gt_qck_class.COUNT ) THEN
            -- 入金区分名称取得不可
            lt_pay_class_name := NULL;
            -- ログ出力
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_class );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--            gt_err_base_code(ln_err_no)        :=  lt_base_code;                   -- 拠点コード
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                   -- 拠点名称
--            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;              -- 伝票NO
--            gt_err_party_num(ln_err_no)        :=  lt_customer_number;             -- 顧客コード
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;               -- 顧客名
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;                -- 入金/納品日
--            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;             -- 入金区分名称
            gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
            gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
            gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
            gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );    -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
        END LOOP;
      END IF;
--
      --==============================================================
      -- 拠点コード、顧客コードの妥当性チェック
      --==============================================================
      BEGIN
        --== 必須項目チェック：拠点コード、顧客コード、入金日 ==--
        IF ( ( lt_base_code IS NULL ) OR ( lt_customer_number IS NULL ) OR ( lt_payment_date IS NULL ) ) THEN
--
          -- 拠点コードがNULLの場合
          IF ( lt_base_code IS NULL ) THEN
            -- ログ出力
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
            gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
            gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
            gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
            gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
          -- 顧客コードがNULLの場合
          IF ( lt_customer_number IS NULL ) THEN
            -- ログ出力
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_num );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
            gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
            gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
            gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
            gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
          -- 入金日がNULLの場合
          IF ( lt_payment_date IS NULL ) THEN
            -- ログ出力
            lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_date );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--            gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
            gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--            gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--            gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
            gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
            gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--            gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
            gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
            gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
            gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
            gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
            gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
            ln_err_no := ln_err_no + 1;
            -- エラーフラグ更新
            lv_err_flag := cv_hit;
          END IF;
--
        ELSE
          --== 顧客マスタデータ抽出 ==--
--****************************** 2009/07/28 1.8 T.Tominaga MOD START ******************************--
--          SELECT parties.party_name           party_name,           -- 顧客名称
          SELECT SUBSTRB(parties.party_name, 1, 40)  party_name,    -- 顧客名称
--****************************** 2009/07/28 1.8 T.Tominaga MOD END   ******************************--
                 parties.party_id             party_id,             -- パーティID
--****************************** 2009/05/15 1.4 T.Kitajima MOD START ******************************--
--                 custadd.sale_base_code       sale_base_code,       -- 売上拠点コード
--                 custadd.past_sale_base_code  past_sale_base,       -- 前月売上拠点コード
--****************************** 2009/07/21 1.7 T.Tominaga MOD START ******************************--
--                 custadd.receiv_base_code     receiv_base_code,       -- 入金拠点コード
--****************************** 2009/05/15 1.4 T.Kitajima MOD  END  ******************************--
                 xch.cash_receiv_base_code    receiv_base_code,     --入金拠点コード
--****************************** 2009/07/21 1.7 T.Tominaga MOD  END  ******************************--
                 parties.duns_number_c        customer_status,      -- 顧客ステータス
                 custadd.business_low_type    business_low_type,    -- 業態（小分類）
--****************************** 2009/07/28 1.8 T.Tominaga MOD START ******************************--
--                 base.account_name            account_name,         -- 拠点名称
                 SUBSTRB(base.account_name, 1, 30)  account_name,   -- 拠点名称
--****************************** 2009/07/28 1.8 T.Tominaga MOD END   ******************************--
                 baseadd.dept_hht_div         dept_hht_div,         -- 百貨店用HHT区分
                 salesreps.resource_id        resource_id           -- リソースID
          INTO   lt_customer_name,
                 lt_party_id,
--****************************** 2009/05/15 1.4 T.Kitajima MOD START ******************************--
--                 lt_sale_base,
--                 lt_past_sale_base,
                 lt_receiv_base,
--****************************** 2009/05/15 1.4 T.Kitajima MOD  END  ******************************--
                 lt_cus_status,
                 lt_bus_low_type,
                 lt_base_name,
                 lt_hht_class,
                 lt_resource_id
          FROM   hz_cust_accounts     cust,                    -- 顧客マスタ
                 hz_cust_accounts     base,                    -- 拠点マスタ
                 hz_parties           parties,                 -- パーティ
                 xxcmm_cust_accounts  custadd,                 -- 顧客追加情報_顧客
                 xxcmm_cust_accounts  baseadd,                 -- 顧客追加情報_拠点
--******************************* 2009/07/21 1.7 T.Tominaga ADD START ***************************************
                 xxcfr_cust_hierarchy_v xch,                   -- 顧客階層ビュー
--******************************* 2009/07/21 1.7 T.Tominaga ADD END   ***************************************
                 xxcos_salesreps_v    salesreps,               -- 担当営業員view
--******************************* 2009/07/21 1.7 T.Tominaga DEL START ***************************************
--                 (
--                   SELECT  look_val.meaning      cus
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type = cv_qck_typ_cus
--                   AND     look_val.lookup_code LIKE cv_qck_typ_a02
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute1   = cv_tkn_yes
--                 ) cus_class,    -- 顧客区分（'10'(顧客) , '12'(上様)）
--******************************* 2009/07/21 1.7 T.Tominaga DEL END   ***************************************
                 (
                   SELECT  look_val.meaning      base
--******************************* 2009/07/21 1.7 T.Tominaga MOD START ***************************************
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type = cv_qck_typ_cus
--                   AND     look_val.lookup_code LIKE cv_qck_typ_a02
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute2   = cv_tkn_yes
                   FROM    fnd_lookup_values     look_val
                   WHERE   look_val.language     = ct_lang
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.lookup_code LIKE cv_qck_typ_a02
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute2   = cv_tkn_yes
--******************************* 2009/07/21 1.7 T.Tominaga MOD END   ***************************************
                 ) base_class    -- 顧客区分（'1'(拠点)）
          WHERE  cust.cust_account_id     = custadd.customer_id    -- 顧客マスタ.顧客ID = 顧客追加情報_顧客.顧客ID
--******************************* 2009/07/21 1.7 T.Tominaga MOD START ***************************************
--            AND  cust.customer_class_code = cus_class.cus          -- 顧客マスタ.顧客区分 = '10'(顧客) or '12'(上様)
            AND  cust.cust_account_id     = xch.ship_account_id    -- 顧客マスタ.顧客ID = 顧客階層ビュー.出荷先顧客ID
--******************************* 2009/07/21 1.7 T.Tominaga MOD END   ***************************************
            AND  cust.account_number      = lt_customer_number     -- 顧客マスタ.顧客コード = 抽出した顧客コード
            AND  cust.party_id            = parties.party_id       -- 顧客マスタ.パーティID=パーティ.パーティID
--****************************** 2009/05/19 1.5 N.Maeda MOD START ******************************--
            AND  lt_base_code   = base.account_number                -- 抽出した拠点コード=拠点マスタ.顧客コード
--            AND  custadd.sale_base_code   = base.account_number    -- 顧客追加情報_顧客.売上拠点=拠点マスタ.顧客コード
--****************************** 2009/05/19 1.5 N.Maedaa MOD  END  ******************************--
            AND  base.cust_account_id     = baseadd.customer_id    -- 拠点マスタ.顧客ID=顧客追加情報_拠点.顧客ID
            AND  base.customer_class_code = base_class.base        -- 拠点マスタ.顧客区分 = '1'(拠点)
            AND  (
                    salesreps.account_number = lt_customer_number  -- 担当営業員view.顧客番号 = 抽出した顧客コード
                  AND                                              -- 入金日の適用範囲
                    lt_payment_date >= NVL(salesreps.effective_start_date, gd_process_date)
                  AND
                    lt_payment_date <= NVL(salesreps.effective_end_date, gd_max_date)
                 )
          ;
--
          --== 顧客ステータスチェック ==--
          FOR i IN 1..gt_qck_status.COUNT LOOP
            EXIT WHEN gt_qck_status(i) = lt_cus_status;
            IF ( i = gt_qck_status.COUNT ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_status );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--              gt_err_base_code(ln_err_no)        :=  lt_base_code;               -- 拠点コード
              gt_err_base_name(ln_err_no)        :=  lt_base_name;               -- 拠点名称
--              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;          -- 伝票NO
--              gt_err_party_num(ln_err_no)        :=  lt_customer_number;         -- 顧客コード
              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;           -- 顧客名
              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;            -- 入金/納品日
--              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;          -- 入金区分名称
              gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
              gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
              gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
              gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
              gt_err_error_message(ln_err_no)    :=  SUBSTRB(lv_errmsg, 1, 60);  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
--****************************** 2009/05/15 1.4 T.Kitajima DEL START ******************************--
--          --== 売上拠点コードチェック ==--
--          -- 売上拠点コードと前月売上拠点コードの使用判定
--          IF ( TRUNC( lt_payment_date, cv_month ) < TRUNC( gd_process_date, cv_month ) ) THEN
--            lt_sale_base := NVL( lt_past_sale_base, lt_sale_base );
--          END IF;
--****************************** 2009/05/15 1.4 T.Kitajima DEL  END  ******************************--
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
          -- 一般拠点の場合
--      IF ( lt_hht_class = cv_general ) THEN
--****************************** 2009/05/15 1.4 T.Kitajima DEL START ******************************--
--          IF ( lt_hht_class IS NULL ) THEN
--            -- 売上拠点コード妥当性チェック
--            IF ( lt_sale_base != lt_base_code ) THEN
--              -- ログ出力
--              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
--              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--              ov_retcode := cv_status_warn;
--              -- エラー変数へ格納
--              gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
--              gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--              gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
--              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
--              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
--              gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
--              ln_err_no := ln_err_no + 1;
--              -- エラーフラグ更新
--              lv_err_flag := cv_hit;
--            END IF;
--          END IF;
--****************************** 2009/05/15 1.4 T.Kitajima DEL  END  ******************************--
--
          --== 業態（小分類）チェック ==--
          FOR j IN 1..gt_qck_busi.COUNT LOOP
--          EXIT WHEN gt_qck_busi(j) = lt_bus_low_type;
--          IF ( j = gt_qck_busi.COUNT ) THEN
            IF ( gt_qck_busi(j) = lt_bus_low_type ) THEN
              -- ログ出力
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--              gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
              gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--              gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--              gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
              gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
              gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--              gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
              gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
              gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
              gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
              gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
              gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
              ln_err_no := ln_err_no + 1;
              -- エラーフラグ更新
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
  /*-----2009/02/03-----END-------------------------------------------------------------------------------*/
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
          gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
          gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
          gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
          gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
      END;
--
      --==============================================================
      -- 入金日の妥当性チェック
      --==============================================================
      IF ( lt_payment_date IS NOT NULL ) THEN
        --== AR会計期間チェック ==--
        -- 共通関数＜会計期間情報取得＞
        xxcos_common_pkg.get_account_period(
          cv_ar_class         -- 02:AR
         ,lt_payment_date     -- 入金日
         ,lv_status           -- ステータス(OPEN or CLOSE)
         ,ln_from_date        -- 会計（FROM）
         ,ln_to_date          -- 会計（TO）
         ,lv_errbuf           -- エラー・メッセージ
         ,lv_retcode          -- リターン・コード
         ,lv_errmsg           -- ユーザー・エラー・メッセージ
          );
--
-- ******** 2010/02/01 1.10 N.Maeda MOD START ******** --
--        --エラーチェック
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_api_expt;
--        END IF;
--
        -- AR会計期間範囲外の場合
--        IF ( lv_status != cv_open ) THEN
        IF ( lv_status != cv_open )
          OR ( lv_retcode = cv_status_error ) THEN
-- ******** 2010/02/01 1.10 N.Maeda MOD  END  ******** --
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_prd );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
          gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
          gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
          gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
          gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
-- ******** 2010/02/01 1.10 N.Maeda MOD START ******** --
          lv_retcode := NULL;
-- ******** 2010/02/01 1.10 N.Maeda MOD  END  ******** --
        END IF;
--
        --== 未来日チェック ==--
        IF ( lt_payment_date > gd_process_date ) THEN
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_ftr );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
          gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
          gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
          gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
          gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
        END IF;
      END IF;
--
      --==============================================================
      -- 入金額の妥当性チェック
      --==============================================================
      --== 必須項目チェック：入金額 ==--
      IF ( lt_payment_amount IS NULL ) THEN
        -- ログ出力
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_amount );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm, cv_tkn_colmun, lv_tkn );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--        gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
        gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--        gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--        gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
        gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
        gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--        gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
        gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
        gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
        gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
        gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
        gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
        ln_err_no := ln_err_no + 1;
        -- エラーフラグ更新
        lv_err_flag := cv_hit;
      ELSE
        -- マイナス金額、及び0円チェック
        IF ( lt_payment_amount <= 0 ) THEN
          -- ログ出力
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_minus );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- エラー変数へ格納
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
--          gt_err_base_code(ln_err_no)        :=  lt_base_code;                 -- 拠点コード
          gt_err_base_name(ln_err_no)        :=  lt_base_name;                 -- 拠点名称
--          gt_err_entry_number(ln_err_no)     :=  lt_hht_invoice_no;            -- 伝票NO
--          gt_err_party_num(ln_err_no)        :=  lt_customer_number;           -- 顧客コード
          gt_err_cus_name(ln_err_no)         :=  lt_customer_name;             -- 顧客名
          gt_err_pay_dlv_date(ln_err_no)     :=  lt_payment_date;              -- 入金/納品日
--          gt_err_pay_class_name(ln_err_no)   :=  lt_pay_class_name;            -- 入金区分名称
          gt_err_base_code(ln_err_no)        :=  SUBSTRB(lt_base_code,1,4);       -- 拠点コード
          gt_err_entry_number(ln_err_no)     :=  SUBSTRB(lt_hht_invoice_no,1,12); -- 伝票NO
          gt_err_party_num(ln_err_no)        :=  SUBSTRB(lt_customer_number,1,9); -- 顧客コード
          gt_err_pay_class_name(ln_err_no)   :=  SUBSTRB(lt_pay_class_name,1,12); -- 入金区分名称
-- ********** 2009/10/02 1.9 N.Maeda MOD START ********** --
          gt_err_error_message(ln_err_no)    :=  SUBSTRB( lv_errmsg, 1, 60 );  -- エラー内容
          ln_err_no := ln_err_no + 1;
          -- エラーフラグ更新
          lv_err_flag := cv_hit;
        END IF;
      END IF;
--
      --==============================================================
      -- 入金データを変数へ格納
      --==============================================================
      IF ( lv_err_flag = cv_default ) THEN
--****************************** 2009/05/15 1.4 T.Kitajima MOD START ******************************--
--        gt_pay_base_code(ln_ok_no)        :=  lt_sale_base;          -- 拠点コード
        gt_pay_base_code(ln_ok_no)        :=  lt_receiv_base;        -- 拠点コード
--****************************** 2009/05/15 1.4 T.Kitajima MOD  END  ******************************--
        gt_pay_customer_number(ln_ok_no)  :=  lt_customer_number;    -- 顧客コード
        gt_pay_payment_amount(ln_ok_no)   :=  lt_payment_amount;     -- 入金額
        gt_pay_payment_date(ln_ok_no)     :=  lt_payment_date;       -- 入金日
        gt_pay_payment_class(ln_ok_no)    :=  lt_payment_class;      -- 入金区分
        gt_pay_hht_invoice_no(ln_ok_no)   :=  lt_hht_invoice_no;     -- HHT伝票No
        gt_resource_id(ln_ok_no)          :=  lt_resource_id;        -- リソースID
        gt_party_id(ln_ok_no)             :=  lt_party_id;           -- パーティID
        gt_party_name(ln_ok_no)           :=  lt_customer_name;      -- 顧客名称
        gt_cus_status(ln_ok_no)           :=  lt_cus_status;         -- 顧客ステータス
-- ************ 2011/02/23 1.11 Y.Nishino ADD START ************ --
        gt_pay_delivery_to_base_code(ln_ok_no)  :=  lt_base_code;    -- 納品先拠点コード
-- ************ 2011/02/23 1.11 Y.Nishino ADD END   ************ --
        ln_ok_no := ln_ok_no + 1;
      END IF;
--
    END LOOP;
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
  END payment_data_check;
--
  /**********************************************************************************
   * Procedure Name   : error_data_register
   * Description      : エラー発生対象データを登録(A-3)
   ***********************************************************************************/
  PROCEDURE error_data_register(
    on_warn_cnt      OUT NUMBER,              --   警告件数
    ov_errbuf        OUT VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_data_register'; -- プログラム名
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
-- ******* 2009/10/02 1.9 N.Maeda MOD START ******* --
--    lv_data_name  VARCHAR2(10);   -- データ名称
    lv_data_name  xxcos_rep_hht_err_list.data_name%TYPE;   -- データ名称
-- ******* 2009/10/02 1.9 N.Maeda MOD  END  ******* --
    lv_tkn        VARCHAR2(50);   -- エラーメッセージ用トークン
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
    -- 警告件数初期化
    on_warn_cnt := 0;
--
    --==============================================================
    -- HHTエラーリスト帳票ワークテーブルへエラーデータ登録
    --==============================================================
    -- データ名称取得
    lv_data_name := SUBSTRB( xxccp_common_pkg.get_msg( cv_application, cv_msg_data_name ),1,20);
--
    -- エラー件数セット
    on_warn_cnt := gt_err_base_code.COUNT;
--
    BEGIN
--
      -- エラーデータ登録
      FORALL i IN 1..on_warn_cnt
        INSERT INTO xxcos_rep_hht_err_list
          (
            record_id,
            base_code,
            base_name,
            origin_shipment,
            data_name,
            order_no_hht,
            invoice_invent_date,
            entry_number,
            line_no,
            order_no_ebs,
            party_num,
            customer_name,
            payment_dlv_date,
            payment_class_name,
            performance_by_code,
            item_code,
            error_message,
            report_group_id,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            xxcos_rep_hht_err_list_s01.NEXTVAL,          -- レコードID
            gt_err_base_code(i),                         -- 拠点コード
            gt_err_base_name(i),                         -- 拠点名称
            NULL,                                        -- 出庫側コード
            lv_data_name,                                -- データ名称
            NULL,                                        -- 受注NO（HHT）
            NULL,                                        -- 伝票/棚卸日
            gt_err_entry_number(i),                      -- 伝票NO
            NULL,                                        -- 行NO
            NULL,                                        -- 受注NO（EBS）
            gt_err_party_num(i),                         -- 顧客コード
            gt_err_cus_name(i),                          -- 顧客名
            gt_err_pay_dlv_date(i),                      -- 入金/納品日
            gt_err_pay_class_name(i),                    -- 入金区分名称
            NULL,                                        -- 成績者コード
            NULL,                                        -- 品目コード
            gt_err_error_message(i),                     -- エラー内容
            NULL,                                        -- 帳票用グループID
            cn_created_by,                               -- 作成者
            cd_creation_date,                            -- 作成日
            cn_last_updated_by,                          -- 最終更新者
            cd_last_update_date,                         -- 最終更新日
            cn_last_update_login,                        -- 最終更新ログイン
            cn_request_id,                               -- 要求ID
            cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                               -- コンカレント・プログラムID
            cd_program_update_date                       -- プログラム更新日
          );
--
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
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
  END error_data_register;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_register
   * Description      : 入金データを登録(A-4)
   ***********************************************************************************/
  PROCEDURE payment_data_register(
    on_normal_cnt    OUT NUMBER,              --   入金データ作成件数
    ov_errbuf        OUT VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_register'; -- プログラム名
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
    cv_input_class  VARCHAR2(1) DEFAULT '0';  -- 入力区分
    cv_entry_class  VARCHAR2(1) DEFAULT '4';  -- 訪問有効情報登録：DFF12（登録区分）
--
    -- *** ローカル変数 ***
    ln_pay_cnt      NUMBER;         -- 入金データ作成件数
    lv_tkn          VARCHAR2(50);   -- エラーメッセージ用トークン
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
    -- 入金データ作成件数初期化
    on_normal_cnt := 0;
--
    --==============================================================
    -- 入金テーブルへ入金データ登録
    --==============================================================
    -- 共通関数＜訪問有効情報登録＞
    FOR i IN 1..gt_party_id.COUNT LOOP
--
      xxcos_task_pkg.task_entry(
        lv_errbuf                 -- エラー・メッセージ
       ,lv_retcode                -- リターン・コード
       ,lv_errmsg                 -- ユーザー・エラー・メッセージ
       ,gt_resource_id(i)         -- リソースID
       ,gt_party_id(i)            -- パーティID
       ,gt_party_name(i)          -- パーティ名称（顧客名称）
       ,gt_pay_payment_date(i)    -- 訪問日時 ＝ 入金日
       ,NULL                      -- 詳細内容
       ,0                         -- 売上金額
       ,cv_input_class            -- 入力区分
       ,cv_entry_class            -- DFF12（登録区分）＝ 4
       ,gt_pay_hht_invoice_no(i)  -- DFF13（登録元ソース番号）＝ HHT伝票No
       ,gt_cus_status(i)          -- DFF14（顧客ステータス）
      );
--
      --エラーチェック
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP;
--
    BEGIN
--
      -- 入金データ登録
      ln_pay_cnt := gt_pay_base_code.COUNT;
      FORALL i IN 1..ln_pay_cnt
        INSERT INTO xxcos_payment
          (
            line_id,
            base_code,
            customer_number,
            payment_amount,
            payment_date,
            payment_class,
            hht_invoice_no,
            delete_flag,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
-- ************ 2011/02/23 1.11 Y.Nishino ADD START ************ --
           ,delivery_to_base_code  --納品先拠点コード
-- ************ 2011/02/23 1.11 Y.Nishino ADD END   ************ --
          )
        VALUES
          (
            xxcos_payment_s01.NEXTVAL,                   -- 明細ID
            gt_pay_base_code(i),                         -- 拠点コード
            gt_pay_customer_number(i),                   -- 顧客コード
            gt_pay_payment_amount(i),                    -- 入金額
            gt_pay_payment_date(i),                      -- 入金日
            gt_pay_payment_class(i),                     -- 入金区分
            gt_pay_hht_invoice_no(i),                    -- HHT伝票No
            cv_tkn_del_flag,                             -- 削除フラグ
            cn_created_by,                               -- 作成者
            cd_creation_date,                            -- 作成日
            cn_last_updated_by,                          -- 最終更新者
            cd_last_update_date,                         -- 最終更新日
            cn_last_update_login,                        -- 最終更新ログイン
            cn_request_id,                               -- 要求ID
            cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
            cn_program_id,                               -- コンカレント・プログラムID
            cd_program_update_date                       -- プログラム更新日
-- ************ 2011/02/23 1.11 Y.Nishino ADD START ************ --
           ,gt_pay_delivery_to_base_code(i)              -- 納品先拠点コード
-- ************ 2011/02/23 1.11 Y.Nishino ADD END   ************ --
          );
--
      -- 入金データ作成件数セット
      on_normal_cnt := ln_pay_cnt;
--
    EXCEPTION
--
      -- エラー処理（データ追加エラー）
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
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
  END payment_data_register;
--
  /**********************************************************************************
   * Procedure Name   : payment_work_delete
   * Description      : 入金ワークテーブルのレコード削除(A-5)
   ***********************************************************************************/
  PROCEDURE payment_work_delete(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_work_delete'; -- プログラム名
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
    lv_tkn      VARCHAR2(50);   -- エラーメッセージ用トークン
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
    --==============================================================
    -- 入金ワークテーブルのレコード削除
    --==============================================================
    BEGIN
--
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_payment_work';
--
    EXCEPTION
--
      -- エラー処理（データ削除エラー）
      WHEN OTHERS THEN
/* 2016.03.10 H.Okada E_本稼働_13485対応 MOD START */
--        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_paywk_tab );
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, lv_tkn );
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_del_sql    --メッセージコード
                        ,iv_token_name1  => cv_tkn_table
                        ,iv_token_value1 => cv_msg_paywk_tab  -- テーブル名
                        ,iv_token_name2  => cv_tkn_sqlerr
                        ,iv_token_value2 => SQLERRM           -- SQLERRM
                      ),1,5000);
/* 2016.03.10 H.Okada E_本稼働_13485対応 MOD END */
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
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
  END payment_work_delete;
--
  /**********************************************************************************
   * Procedure Name   : payment_data_delete
   * Description      : 入金テーブルの不要データ削除(A-6)
   ***********************************************************************************/
  PROCEDURE payment_data_delete(
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'payment_data_delete'; -- プログラム名
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
    ln_delete_cnt  NUMBER;         -- 削除件数
    lv_tkn         VARCHAR2(50);   -- エラーメッセージ用トークン
--
    -- *** ローカル・カーソル ***
    -- 入金テーブルロック
    CURSOR lock_cur
    IS
      SELECT pay.delete_flag  delete_flag
      FROM   xxcos_payment    pay                -- 入金テーブル
      WHERE  pay.delete_flag = cv_tkn_yes
--****************************** 2009/06/19 1.6 T.Kitajima MOD START ******************************--
--      AND    TRUNC( pay.creation_date ) < ( gd_process_date - gn_purge_date )
      AND    pay.creation_date  <= gd_purge_date
      FOR UPDATE NOWAIT;
--****************************** 2009/06/19 1.6 T.Kitajima MOD  END  ******************************--

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
    --==============================================================
    -- テーブルロック
    --==============================================================
    OPEN  lock_cur;
    CLOSE lock_cur;
--
    --==============================================================
    -- 入金テーブルの不要データ削除
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_payment
      WHERE xxcos_payment.delete_flag = cv_tkn_yes
--****************************** 2009/06/19 1.6 T.Kitajima MOD START ******************************--
--        AND TRUNC( xxcos_payment.creation_date ) < ( gd_process_date - gn_purge_date );
        AND xxcos_payment.creation_date  <= gd_purge_date
      ;
--****************************** 2009/06/19 1.6 T.Kitajima MOD  END  ******************************--
--
      ln_delete_cnt := SQL%ROWCOUNT;    -- 削除件数
--
    EXCEPTION
--
      -- エラー処理（データ削除エラー）
      WHEN OTHERS THEN
        lv_tkn    := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, lv_tkn );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- 削除件数出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_count, cv_tkn_count, TO_CHAR( ln_delete_cnt ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      lv_tkn     := xxccp_common_pkg.get_msg( cv_application, cv_msg_pay_tab );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END payment_data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
--
    -- *** ローカル変数 ***
    lv_tkn        VARCHAR2(50);   -- エラーメッセージ用トークン
    ln_error_cnt  NUMBER;         -- 警告件数
    ln_normal_cnt NUMBER;         -- 入金データ作成件数
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-0)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
      ov_errmsg   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 入金ワークテーブルより入金データ抽出 (A-1)
    -- ============================================
    payment_data_receive(
      gn_target_cnt,          -- 対象件数
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
--
    -- 警告処理（対象データ無しエラー）
    ELSIF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
--
    END IF;
--
    --== 対象データが1件以上ある場合、A-2からA-5の処理を行います。 ==--
    IF ( gn_target_cnt >= 1 ) THEN
--
      -- ============================================
      -- 抽出したデータの妥当性チェック (A-2)
      -- ============================================
      payment_data_check(
        gn_target_cnt,          -- 対象件数
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_errbuf   :=  lv_errbuf;
        ov_retcode  :=  lv_retcode;
        ov_errmsg   :=  lv_errmsg;
      END IF;
--
      --エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- エラー発生対象データを登録 (A-3)
      -- ============================================
      -- A-2のチェックでエラーとなったデータに対して以下の処理を行います。
      IF ( gt_err_base_code IS NOT NULL ) THEN
        error_data_register(
          ln_error_cnt,           -- 警告件数
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        --エラー処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ============================================
      -- 入金データを登録 (A-4)
      -- ============================================
      -- A-2のチェックでエラーとならなかったデータに対して以下の処理を行う。
      IF ( gt_pay_base_code IS NOT NULL ) THEN
        payment_data_register(
          ln_normal_cnt,          -- 入金データ作成件数
          lv_errbuf,              -- エラー・メッセージ           --# 固定 #
          lv_retcode,             -- リターン・コード             --# 固定 #
          lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
        --エラー処理
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
      COMMIT;  --TRUNCATE前に明示的にコミット
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
      -- ============================================
      -- 入金ワークテーブルのレコード削除 (A-5)
      -- ============================================
      payment_work_delete(
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
      --エラー処理
      IF ( lv_retcode = cv_status_error ) THEN
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
        gv_part_comp_err_flag := cv_tkn_yes; -- 一部処理（入金の取込）完了後エラー
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
        RAISE global_process_expt;
      END IF;
--
      -- コミット
      COMMIT;
--
      -- 件数セット
      gn_error_cnt  := ln_error_cnt;    -- 警告件数
      gn_normal_cnt := ln_normal_cnt;   -- 入金データ作成件数
--
    END IF;
--
    -- ============================================
    -- 入金テーブルの不要データ削除 (A-6)
    -- ============================================
    payment_data_delete(
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    --エラー処理
    IF ( lv_retcode = cv_status_error ) THEN
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
      gv_part_comp_err_flag := cv_tkn_yes; -- 一部処理（入金の取込）完了後エラー
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
      RAISE global_process_expt;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
  )
--
--###########################  固定部 START   #####################################################
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
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
    cv_error_msg2      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-10079'; -- 一部処理後エラー終了メッセージ
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #######################################################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
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
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
    --エラー件数出力
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
    -- 入金ワークテーブルの削除以降でエラーの場合は、出力するエラーメッセージを変更する
    IF ( gv_part_comp_err_flag = cv_tkn_yes ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_error_msg2
                     );
    -- 正常終了・警告終了・通常のエラー
    ELSE
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
    --
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => lv_message_code
                     );
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD START */
    END IF;
/* 2016.03.10 H.Okada E_本稼働_13485対応 ADD END */
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
END XXCOS001A02C;
/

